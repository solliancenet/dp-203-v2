# Module 2 - Designing and Implementing the Serving Layer

This module teaches how to design and implement data stores in a modern data warehouse to optimize analytical workloads. The student will learn how to design a multidimensional schema to store fact and dimension data. Then the student will learn how to populate slowly changing dimensions through incremental data loading from Azure Data Factory.

In this module, the student will be able to:

- Design a star schema for analytical workloads (OLAP)
- Populate slowly changing dimensions with Azure Data Factory and mapping data flows

## Lab

### Implementing a Star Schema

(See Word doc)

### Implementing a Snowflake Schema

(See Word doc)

### Implementing a Time Dimension Table

(See Word doc)

### Designing a Slowly Changing Dimension in Azure Data Factory using the SQL Server Temporal Table

Adapt from: <https://visualbi.com/blogs/microsoft/azure/designing-slowly-changing-dimension-scd-azure-data-factory-using-sql-server-temporal-tables/#:~:text=Designing%20a%20Slowly%20Changing%20Dimension%20%28SCD%29%20in%20Azure,Azure%20Data%20Factory.%20...%207%20Retention%20Policy.%20>

- Create a SQL temporal table
- Create a stored procedure with a SQL MERGE statement to update the dimension table
- Create a copy activity in ADF to execute the stored procedure

### Updating slowly changing dimensions with ADF mapping data flows

Adapt from: <https://www.mssqltips.com/sqlservertip/6074/azure-data-factory-mapping-data-flow-for-datawarehouse-etl/>

- ADF's template gallery has two templates for slowly changing dimensions that can be used as a starter. Change to output to a dedicated SQL pool instead of Azure SQL DB
