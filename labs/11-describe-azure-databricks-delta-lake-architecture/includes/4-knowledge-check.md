Now that you've completed all the notebooks in Azure Databricks, check your knowledge by answering these questions.

## quiz title: Knowledge check
## Multiple Choice
What is a lambda architecture and what does it try to solve?
() An architecture that defines a data processing pipeline whereby microservices act as compute resources for efficient large-scale data processing{{Incorrect. A lambda architecture does not define the type of compute used for data processing.}}
(x) An architecture that splits incoming data into two paths - a batch path and a streaming path. This architecture helps address the need to provide real-time processing in addition to slower batch computations.{{Correct. The lambda architecture is a big data processing architecture that combines both batch- and real-time processing methods.}}
() An architecture that employs the latest Scala runtimes in one or more Databricks clusters to provide the most efficient data processing platform available today{{Incorrect. The lambda architecture does not define the type of compute nor specific versions of runtime libraries for data processing.}}

## Multiple Choice
How does Delta Lake improve upon the traditional lambda architecture?
(x) At each stage, Delta Lake enriches data through a unified pipeline that allows us to combine batch and streaming workflows through a shared filestore with ACID compliant transactions{{Correct. By considering the business logic at all steps of the ETL pipeline, you can ensure that storage and compute costs are optimized by reducing unnecessary duplication of data and limiting ad hoc querying against full historic data. Each stage can be configured as a batch or streaming job, and ACID transactions ensure that processing succeeds or fails completely.}}
() Delta Lake improves data processing efficiency through built-in utilities such as OPTIMIZE and VACUUM. In addition, it allows you to upsert data and work with each version of your data through Time Travel operations.{{Incorrect. Although these statements are true, they do not address how Delta Lake improves upon the lambda architecture.}}

## Multiple Choice
Which of these statements about bronze tables is true?
() Bronze tables are stored on cheaper disks than silver or gold, allowing you to optimize costs based on relative storage value{{Incorrect. The bronze, silver, or gold designation does not pertain to monetary value.}}
() Bronze tables are exclusively for storing job and cluster logs collected during data processing{{Incorrect. There are no rules about what type of data can be stored in bronze tables.}}
(x) Bronze tables contain raw data ingested from various sources (JSON files, RDBMS data,  IoT data, etc.){{Correct. The bronze, silver, and gold designations identify the amount of processing performed on the data within those tables.}}

## Multiple Choice
How do you view the list of active streams?
(x) Invoke **spark.streams.active**{{That's the correct syntax to view the list of active streams.}}
() Invoke **spark.streams.show**{{The syntax isn't correct for this operation.}}
() Invoke **spark.view.active**{{The syntax isn't correct for this operation.}}

## Multiple Choice
How do you specify the location of a checkpoint directory when defining a Delta Lake streaming query?
() .writeStream.format("delta").checkpoint("location", checkpointPath) ...{{The syntax isn't correct for this operation.}}
(x) .writeStream.format("delta").option("checkpointLocation", checkpointPath) ...{{That's the correct syntax to specify the checkpoint directory on a Delta Lake streaming query.}}
() .writeStream.format("parquet").option("checkpointLocation", checkpointPath) ...{{Incorrect. You must specify delta as the format for a Delta Lake streaming query.}}
