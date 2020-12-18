Now that you've completed all of the notebooks in Azure Databricks, check your knowledge by answering the following questions.

## quiz title: Knowledge check
## Multiple Choice
When you do a write stream command, what does the `outputMode("append")` option do?
() The append mode allows records to be updated and changed in place{{The append mode allows records to be added to the output sink. Using the update mode will allow updated records to be changed in place.}}
(x) The append outputMode allows records to be added to the output sink{{The outputMode "append" option informs the write stream to add only new records to the output sink. The "complete" option is to rewrite the full output - applicable to aggregations operations. Finally, the "update" option is for updating changed records in place.}}

## Multiple Choice
In Spark Structured Streaming, what method should you use to read streaming data into a DataFrame?
(x) spark.readStream{{You use the `spark.readStream` method to start reading data from a streaming query into a DataFrame.}}
() spark.read{{You use the `spark.readStream` method to start reading data from a streaming query into a DataFrame. `spark.read` is used for batch and interactive queries.}}

## Multiple Choice
What happens if you do not specify `option("checkpointLocation", pointer-to-checkpoint directory)`?
() You will not be able to create more than one streaming query that uses the same streaming source, since they will conflict{{Incorrect.}}
(x) When the streaming job stops, you lose all state around your streaming job and upon restart, you start from scratch{{Setting the `checkpointLocation` is required for many sinks used in Structured Streaming. For those sinks where this setting is optional, keep in mind that when you do not set this value, you risk losing your place in the stream.}}
