# Module 2 - Designing and Implementing the Serving Layer

This module teaches how to design and implement data stores in a modern data warehouse to optimize analytical workloads. The student will learn how to design a multidimensional schema to store fact and dimension data. Then the student will learn how to populate slowly changing dimensions through incremental data loading from Azure Data Factory.

In this module, the student will be able to:

- Design a star schema for analytical workloads (OLAP)
- Populate slowly changing dimensions with Azure Data Factory and mapping data flows

## Lab

### Implementing a Star Schema

Star schema is a mature modeling approach widely adopted by relational data warehouses. It requires modelers to classify their model tables as either dimension or fact.

**Dimension tables** describe business entities—the things you model. Entities can include products, people, places, and concepts including time itself. The most consistent table you'll find in a star schema is a date dimension table. A dimension table contains a key column (or columns) that acts as a unique identifier, and descriptive columns.

**Fact tables** store observations or events, and can be sales orders, stock balances, exchange rates, temperatures, etc. A fact table contains dimension key columns that relate to dimension tables, and numeric measure columns. The dimension key columns determine the dimensionality of a fact table, while the dimension key values determine the granularity of a fact table. For example, consider a fact table designed to store sale targets that has two dimension key columns `Date` and `ProductKey`. It's easy to understand that the table has two dimensions. The granularity, however, can't be determined without considering the dimension key values. In this example, consider that the values stored in the Date column are the first day of each month. In this case, the granularity is at month-product level.

Generally, dimension tables contain a relatively small number of rows. Fact tables, on the other hand, can contain a very large number of rows and continue to grow over time.

Below is an example star schema, where the fact table is in the middle, surrounded by dimension tables:

![Example star schema.](media/star-schema.png "Star schema")

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
