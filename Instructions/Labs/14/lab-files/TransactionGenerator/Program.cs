using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Azure.EventHubs;
using Newtonsoft.Json;
using System.Threading.Tasks.Dataflow;
using Microsoft.Extensions.Configuration;
using Polly;
using Polly.Bulkhead;
using TransactionGenerator.OutputHelpers;

namespace TransactionGenerator
{
    internal class Program
    {
        private static IConfigurationRoot _configuration;

        private static readonly object LockObject = new object();
        // AutoResetEvent to signal when to exit the application.
        private static readonly AutoResetEvent WaitHandle = new AutoResetEvent(false);
        // Track Event Hub statistics.
        // At any time, requests pending = made - succeeded - failed.
        private static long _totalMessages = 0;
        private static long _eventHubRequestsMade = 0;
        private static long _eventHubRequestsSucceeded = 0;
        private static long _eventHubRequestsFailed = 0;
        private static long _eventHubRequestsSucceededInBatch = 0;
        private static long _eventHubElapsedTime = 0;
        private static long _eventHubTotalElapsedTime = 0;

        private static readonly Statistic[] LatestStatistics = new Statistic[0];

        // Place Event Hub calls into bulkhead to prevent thread starvation caused by failing or waiting calls.
        // Let any number (int.MaxValue) of calls _queue for an execution slot in the bulkhead to allow the generator to send as many calls as possible.
        private const int MaxParallelization = 100000;
        private static readonly AsyncBulkheadPolicy BulkheadForEventHubCalls = Policy.BulkheadAsync(MaxParallelization, int.MaxValue);

        // Send data to Event Hub:
        private static async Task SendData(int randomSeed, EventHubClient eventHubClient, int waittime,
            CancellationToken externalCancellationToken, IProgress<Progress> progress)
        {
            if (waittime > 0)
            {
                var span = TimeSpan.FromMilliseconds(waittime);
                await Task.Delay(span, externalCancellationToken);
            }

            if (externalCancellationToken == null) throw new ArgumentNullException(nameof(externalCancellationToken));
            if (progress == null) throw new ArgumentNullException(nameof(progress));

            // Perform garbage collection prior to timing for statistics.
            GC.Collect();
            GC.WaitForPendingFinalizers();

            var internalCancellationTokenSource = new CancellationTokenSource();
            var combinedToken = CancellationTokenSource.CreateLinkedTokenSource(externalCancellationToken, internalCancellationTokenSource.Token).Token;
            var random = new Random(randomSeed);
            var tasks = new List<Task>();
            var messages = new ConcurrentQueue<ColoredMessage>();
            var eventHubsTimer = new Stopwatch();

            // Ensure none of what follows runs synchronously.
            await Task.FromResult(true).ConfigureAwait(false);

            // Continue while cancellation is not requested.
            while (!combinedToken.IsCancellationRequested)
            {
                if (externalCancellationToken.IsCancellationRequested)
                {
                    return;
                }

                _totalMessages++;
                var thisRequest = _totalMessages;

                var carEvent = TelemetryGenerator.GenerateMessage();

                #region Write to Event Hub
                _eventHubRequestsMade++;
                tasks.Add(BulkheadForEventHubCalls.ExecuteAsync(async ct =>
                {
                    try
                    {
                        var eventData = new EventData(Encoding.UTF8.GetBytes(carEvent.GetData()));
                        eventHubsTimer.Start();

                        // Send to Event Hub:
                        await eventHubClient.SendAsync(eventData: eventData,
                                partitionKey: carEvent.region).ConfigureAwait(false);

                        eventHubsTimer.Stop();
                        _eventHubElapsedTime = eventHubsTimer.ElapsedMilliseconds;

                        // Increment the count of number of Event Hub requests that succeeded.
                        _eventHubRequestsSucceededInBatch++;
                    }
                    catch (Exception e)
                    {
                        if (!ct.IsCancellationRequested) messages.Enqueue(new ColoredMessage($"Event Hubs request {thisRequest} eventually failed with: {e.Message}", Color.Red));

                        _eventHubRequestsFailed++;
                    }
                }, combinedToken)
                    .ContinueWith((t, k) =>
                    {
                        if (t.IsFaulted) messages.Enqueue(new ColoredMessage($"Request to Event Hubs failed with: {t.Exception?.Flatten().InnerExceptions.First().Message}", Color.Red));

                        _eventHubRequestsFailed++;
                    }, thisRequest, TaskContinuationOptions.NotOnRanToCompletion)
                );
                #endregion Write to Event Hub

                if (_totalMessages % 500 == 0)
                {
                    eventHubsTimer.Stop();
                    _eventHubTotalElapsedTime += _eventHubElapsedTime;
                    _eventHubRequestsSucceeded += _eventHubRequestsSucceededInBatch;

                    // Random delay every 500 messages that are sent.
                    //await Task.Delay(random.Next(100, 1000), externalCancellationToken).ConfigureAwait(false);
                    await Task.Delay(random.Next(1000, 3000), externalCancellationToken);

                    // The obvious and recommended method for sending a lot of data is to do so in batches. This method can
                    // multiply the amount of data sent with each request by hundreds or thousands.

                    // Output statistics. Be on the lookout for the following:
                    //  - Inserted line shows successful inserts in this batch and throughput for writes/second.
                    //  - Processing time: Processing time for the past 250 requested inserts.
                    //  - Total elapsed time: Running total of time taken to process all documents.
                    //  - Succeeded shows number of accumulative successful inserts to the service.
                    //  - Pending are items in the bulkhead queue. This amount will continue to grow if the service is unable to keep up with demand.
                    //  - Accumulative failed requests that encountered an exception.
                    messages.Enqueue(new ColoredMessage(string.Empty));
                    messages.Enqueue(new ColoredMessage($"Event Hub: sent {_eventHubRequestsSucceededInBatch:00} events this batch @ {(_eventHubRequestsSucceededInBatch / (_eventHubElapsedTime * .001)):0.00} writes/s ", Color.White));
                    messages.Enqueue(new ColoredMessage($"Event Hub: total events sent {_eventHubRequestsMade:00} ", Color.Green));
                    messages.Enqueue(new ColoredMessage($"Event Hub: processing time {_eventHubElapsedTime} ms", Color.Magenta));
                    messages.Enqueue(new ColoredMessage($"Event Hub: total elapsed time {(_eventHubTotalElapsedTime * .001):0.00} seconds", Color.Magenta));
                    //messages.Enqueue(new ColoredMessage($"Event Hub: total succeeded {_eventHubRequestsSucceeded:00} ", Color.Green));
                    //messages.Enqueue(new ColoredMessage($"Event Hub: total pending {_eventHubRequestsMade - _eventHubRequestsSucceeded - _eventHubRequestsFailed:00} ", Color.Yellow));
                    messages.Enqueue(new ColoredMessage($"Event Hub: total failed {_eventHubRequestsFailed:00}", Color.Red));

                    eventHubsTimer.Restart();
                    _eventHubElapsedTime = 0;
                    _eventHubRequestsSucceededInBatch = 0;

                    // Output all messages available right now, in one go.
                    progress.Report(ProgressWithMessages(ConsumeAsEnumerable(messages)));
                }

                // Add short delay to prevent pumping too many events too fast.
                await Task.Delay(random.Next(5, 15), externalCancellationToken).ConfigureAwait(false);
            }

            messages.Enqueue(new ColoredMessage("Data generation complete", Color.Magenta));
            progress.Report(ProgressWithMessages(ConsumeAsEnumerable(messages)));

            BulkheadForEventHubCalls.Dispose();
            eventHubsTimer.Stop();
        }

        /// <summary>
        /// Extracts properties from either the appsettings.json file or system environment variables.
        /// </summary>
        /// <returns>
        /// EventHubConnectionString: Connection string to Event Hub for sending data.
        /// MillisecondsToRun: The maximum amount of time to allow the generator to run before stopping transmission of data. The default value is 600. Data will also stop transmitting after the included Untagged_Transactions.csv file's data has been sent.
        /// MillisecondsToLead: The amount of time to wait before sending payment transaction data. Default value is 0.
        /// </returns>
        private static (string EventHubConnectionString,
            int MillisecondsToRun,
            int MillisecondsToLead) ParseArguments()
        {
            try
            {
                // The Configuration object will extract values either from the machine's environment variables, or the appsettings.json file.
                var eventHubConnectionString = _configuration["EVENT_HUB_CONNECTION_STRING"];
                var numberOfMillisecondsToRun = (int.TryParse(_configuration["SECONDS_TO_RUN"], out var outputSecondToRun) ? outputSecondToRun : 0) * 1000;
                var numberOfMillisecondsToLead = (int.TryParse(_configuration["SECONDS_TO_LEAD"], out var outputSecondsToLead) ? outputSecondsToLead : 0) * 1000;

                if (string.IsNullOrWhiteSpace(eventHubConnectionString))
                {
                    throw new ArgumentException("EVENT_HUB_CONNECTION_STRING must be provided");
                }

                return (eventHubConnectionString, numberOfMillisecondsToRun, numberOfMillisecondsToLead);
            }
            catch (Exception e)
            {
                WriteLineInColor(e.Message, ConsoleColor.Red);
                Console.ReadLine();
                throw;
            }
        }

        public static void Main(string[] args)
        {
            // Setup configuration to either read from the appsettings.json file (if present) or environment variables.
            var builder = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
                .AddEnvironmentVariables();

            _configuration = builder.Build();

            var arguments = ParseArguments();
            // Set an optional timeout for the generator.
            var cancellationSource = arguments.MillisecondsToRun == 0 ? new CancellationTokenSource() : new CancellationTokenSource(arguments.MillisecondsToRun);
            var cancellationToken = cancellationSource.Token;
            var statistics = new Statistic[0];

            var numberOfMillisecondsToLead = arguments.MillisecondsToLead;

            var taskWaitTime = 0;

            if (numberOfMillisecondsToLead > 0)
            {
                taskWaitTime = numberOfMillisecondsToLead;
            }

            var progress = new Progress<Progress>();
            progress.ProgressChanged += (sender, progressArgs) =>
            {
                foreach (var message in progressArgs.Messages)
                {
                    WriteLineInColor(message.Message, message.Color.ToConsoleColor());
                }
                statistics = progressArgs.Statistics;
            };

            WriteLineInColor("Vehicle Telemetry Generator", ConsoleColor.White);
            Console.WriteLine("======");
            WriteLineInColor("Press Ctrl+C or Ctrl+Break to cancel.", ConsoleColor.Cyan);
            Console.WriteLine("Statistics for generated vehicle telemetry data will be updated for every 500 sent");
            Console.WriteLine(string.Empty);

            ThreadPool.SetMinThreads(100, 100);

            // Handle Control+C or Control+Break.
            Console.CancelKeyPress += (o, e) =>
            {
                WriteLineInColor("Stopped generator. No more events are being sent.", ConsoleColor.Yellow);
                cancellationSource.Cancel();

                // Allow the main thread to continue and exit...
                WaitHandle.Set();

                OutputStatistics(statistics);
            };

            // Initialize the telemetry generator:
            TelemetryGenerator.Init();

            // Create an Event Hub Client from a connection string, using the EventHubConnectionString value.
            var eventHubClient = EventHubClient.CreateFromConnectionString(
                arguments.EventHubConnectionString
            );

            // Start sending data to Event Hub.
            SendData(100, eventHubClient, taskWaitTime, cancellationToken, progress).Wait();

            cancellationSource.Cancel();
            Console.WriteLine();
            WriteLineInColor("Done sending generated vehicle telemetry data", ConsoleColor.Cyan);
            Console.WriteLine();
            Console.WriteLine();

            OutputStatistics(statistics);

            // Keep the console open.
            Console.ReadLine();
            WaitHandle.WaitOne();
        }

        private static void OutputStatistics(Statistic[] statistics)
        {
            if (!statistics.Any()) return;
            // Output statistics.
            var longestDescription = statistics.Max(s => s.Description.Length);
            foreach (var stat in statistics)
            {
                WriteLineInColor(stat.Description.PadRight(longestDescription) + ": " + stat.Value, stat.Color.ToConsoleColor());
            }
        }

        public static Progress ProgressWithMessage(string message)
        {
            return new Progress(LatestStatistics, new ColoredMessage(message, Color.Default));
        }

        public static Progress ProgressWithMessage(string message, Color color)
        {
            return new Progress(LatestStatistics, new ColoredMessage(message, color));
        }

        public static Progress ProgressWithMessages(IEnumerable<ColoredMessage> messages)
        {
            return new Progress(LatestStatistics, messages);
        }

        public static void WriteLineInColor(string msg, ConsoleColor color)
        {
            lock (LockObject)
            {
                Console.ForegroundColor = color;
                Console.WriteLine(msg);
                Console.ResetColor();
            }
        }

        public static IEnumerable<T> ConsumeAsEnumerable<T>(ConcurrentQueue<T> concurrentQueue)
        {
            while (concurrentQueue.TryDequeue(out T got))
            {
                yield return got;
            }
        }
    }
}