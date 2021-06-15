# Module 2 - Design and Implement the serving layer

This module teaches how to design and implement data stores in a modern data warehouse to optimize analytical workloads. The student will learn how to design a multidimensional schema to store fact and dimension data. Then the student will learn how to populate slowly changing dimensions through incremental data loading from Azure Data Factory.

In this module, the student will be able to:

- Design a star schema for analytical workloads (OLAP)
- Populate slowly changing dimensions with Azure Data Factory and mapping data flows

## Lab details

- [Module 2 - Design and Implement the serving layer](#module-2---design-and-implement-the-serving-layer)
  - [Lab details](#lab-details)
    - [Lab setup and pre-requisites](#lab-setup-and-pre-requisites)
  - [Exercise 0: Start the dedicated SQL pool](#exercise-0-start-the-dedicated-sql-pool)
  - [Exercise 1: Implementing a Star Schema](#exercise-1-implementing-a-star-schema)
    - [Task 1: Create star schema in SQL database](#task-1-create-star-schema-in-sql-database)
  - [Exercise 2: Implementing a Snowflake Schema](#exercise-2-implementing-a-snowflake-schema)
    - [Task 1: Create product snowflake schema in SQL database](#task-1-create-product-snowflake-schema-in-sql-database)
    - [Task 2: Create reseller snowflake schema in SQL database](#task-2-create-reseller-snowflake-schema-in-sql-database)
  - [Exercise 3: Implementing a Time Dimension Table](#exercise-3-implementing-a-time-dimension-table)
    - [Task 1: Create time dimension table](#task-1-create-time-dimension-table)
    - [Task 2: Populate the time dimension table](#task-2-populate-the-time-dimension-table)
    - [Task 3: Load data into other tables](#task-3-load-data-into-other-tables)
    - [Task 4: Query data](#task-4-query-data)
  - [Exercise 4: Implementing a Star Schema in Synapse Analytics](#exercise-4-implementing-a-star-schema-in-synapse-analytics)
    - [Task 1: Create star schema in Synapse dedicated SQL](#task-1-create-star-schema-in-synapse-dedicated-sql)
    - [Task 2: Load data into Synapse tables](#task-2-load-data-into-synapse-tables)
    - [Task 3: Query data from Synapse](#task-3-query-data-from-synapse)
  - [Exercise 5: Updating slowly changing dimensions with mapping data flows](#exercise-5-updating-slowly-changing-dimensions-with-mapping-data-flows)
    - [Task 1: Create the Azure SQL Database linked service](#task-1-create-the-azure-sql-database-linked-service)
    - [Task 2: Create a mapping data flow](#task-2-create-a-mapping-data-flow)
    - [Task 3: Create a pipeline and run the data flow](#task-3-create-a-pipeline-and-run-the-data-flow)
    - [Task 4: View inserted data](#task-4-view-inserted-data)
    - [Task 5: Update a source customer record](#task-5-update-a-source-customer-record)
    - [Task 6: Re-run mapping data flow](#task-6-re-run-mapping-data-flow)
    - [Task 7: Verify record updated](#task-7-verify-record-updated)
  - [Exercise 6: Cleanup](#exercise-6-cleanup)
    - [Task 1: Pause the dedicated SQL pool](#task-1-pause-the-dedicated-sql-pool)

### Lab setup and pre-requisites

> **Note:** Only complete the `Lab setup and pre-requisites` steps if you are **not** using a hosted lab environment, and are instead using your own Azure subscription. Otherwise, skip ahead to Exercise 0.

1. If you have not already, follow the [lab setup instructions](https://github.com/solliancenet/microsoft-data-engineering-ilt-deploy/blob/main/setup/02/README.md) for this module.

2. Install [Azure Data Studio](https://docs.microsoft.com/sql/azure-data-studio/download-azure-data-studio?view=sql-server-ver15) on your computer or lab virtual machine.

## Exercise 0: Start the dedicated SQL pool

This lab uses the dedicated SQL pool. As a first step, make sure it is not paused. If so, start it by following these instructions:

1. Open Synapse Studio (<https://web.azuresynapse.net/>).

2. Select the **Manage** hub.

    ![The manage hub is highlighted.](media/manage-hub.png "Manage hub")

3. Select **SQL pools** in the left-hand menu **(1)**. If the dedicated SQL pool is paused, hover over the name of the pool and select **Resume (2)**.

    ![The resume button is highlighted on the dedicated SQL pool.](media/resume-dedicated-sql-pool.png "Resume")

4. When prompted, select **Resume**. It will take a minute or two to resume the pool.

    ![The resume button is highlighted.](media/resume-dedicated-sql-pool-confirm.png "Resume")

> **Continue to the next exercise** while the dedicated SQL pool resumes.

## Exercise 1: Implementing a Star Schema

Star schema is a mature modeling approach widely adopted by relational data warehouses. It requires modelers to classify their model tables as either dimension or fact.

**Dimension tables** describe business entities—the things you model. Entities can include products, people, places, and concepts including time itself. The most consistent table you'll find in a star schema is a date dimension table. A dimension table contains a key column (or columns) that acts as a unique identifier, and descriptive columns.

Dimension tables contain attribute data that might change but usually changes infrequently. For example, a customer's name and address are stored in a dimension table and updated only when the customer's profile changes. To minimize the size of a large fact table, the customer's name and address don't need to be in every row of a fact table. Instead, the fact table and the dimension table can share a customer ID. A query can join the two tables to associate a customer's profile and transactions.

**Fact tables** store observations or events, and can be sales orders, stock balances, exchange rates, temperatures, etc. A fact table contains dimension key columns that relate to dimension tables, and numeric measure columns. The dimension key columns determine the dimensionality of a fact table, while the dimension key values determine the granularity of a fact table. For example, consider a fact table designed to store sale targets that has two dimension key columns `Date` and `ProductKey`. It's easy to understand that the table has two dimensions. The granularity, however, can't be determined without considering the dimension key values. In this example, consider that the values stored in the Date column are the first day of each month. In this case, the granularity is at month-product level.

Generally, dimension tables contain a relatively small number of rows. Fact tables, on the other hand, can contain a very large number of rows and continue to grow over time.

Below is an example star schema, where the fact table is in the middle, surrounded by dimension tables:

![Example star schema.](media/star-schema.png "Star schema")

### Task 1: Create star schema in SQL database

In this task, you create a star schema in SQL database, using foreign key constraints. The first step is to create the base dimension and fact tables.

1. Sign in to the Azure portal (<https://portal.azure.com>).

2. Open the resource group for this lab, then select the **SourceDB** SQL database.

    ![The SourceDB database is highlighted.](media/rg-sourcedb.png "SourceDB SQL database")

3. Copy the **Server name** value on the Overview pane.

    ![The SourceDB server name value is highlighted.](media/sourcedb-server-name.png "Server name")

4. Open Azure Data Studio.

5. Select **Servers** on the left-hand menu, then click **Add Connection**.

    ![The add connection button is highlighted in Azure Data Studio.](media/ads-add-connection-button.png "Add Connection")

6. In the Connection Details form, provide the following information:

    - **Server**: Paste the SourceDB server name value here.
    - **Authentication type**: Select `SQL Login`.
    - **User name**: Enter `sqladmin`.
    - **Password**: Enter the password you supplied when deploying the lab environment, or which was provided to you as part of your hosted lab environment.
    - **Remember password**: Checked.
    - **Database**: Select `SourceDB`.

    ![The connection details are completed as described.](media/ads-add-connection.png "Connection Details")

7. Select **Connect**.

8. Select **Servers** in the left-hand menu, then right-click the SQL server you added at the beginning of the lab. Select **New Query**.

    ![The New Query link is highlighted.](media/ads-new-query.png "New Query")

9. Paste the following into the query window to create the dimension and fact tables:

    ```sql
    CREATE TABLE [dbo].[DimReseller](
        [ResellerKey] [int] IDENTITY(1,1) NOT NULL,
        [GeographyKey] [int] NULL,
        [ResellerAlternateKey] [nvarchar](15) NULL,
        [Phone] [nvarchar](25) NULL,
        [BusinessType] [varchar](20) NOT NULL,
        [ResellerName] [nvarchar](50) NOT NULL,
        [NumberEmployees] [int] NULL,
        [OrderFrequency] [char](1) NULL,
        [OrderMonth] [tinyint] NULL,
        [FirstOrderYear] [int] NULL,
        [LastOrderYear] [int] NULL,
        [ProductLine] [nvarchar](50) NULL,
        [AddressLine1] [nvarchar](60) NULL,
        [AddressLine2] [nvarchar](60) NULL,
        [AnnualSales] [money] NULL,
        [BankName] [nvarchar](50) NULL,
        [MinPaymentType] [tinyint] NULL,
        [MinPaymentAmount] [money] NULL,
        [AnnualRevenue] [money] NULL,
        [YearOpened] [int] NULL
    );
    GO

    CREATE TABLE [dbo].[DimEmployee](
        [EmployeeKey] [int] IDENTITY(1,1) NOT NULL,
        [ParentEmployeeKey] [int] NULL,
        [EmployeeNationalIDAlternateKey] [nvarchar](15) NULL,
        [ParentEmployeeNationalIDAlternateKey] [nvarchar](15) NULL,
        [SalesTerritoryKey] [int] NULL,
        [FirstName] [nvarchar](50) NOT NULL,
        [LastName] [nvarchar](50) NOT NULL,
        [MiddleName] [nvarchar](50) NULL,
        [NameStyle] [bit] NOT NULL,
        [Title] [nvarchar](50) NULL,
        [HireDate] [date] NULL,
        [BirthDate] [date] NULL,
        [LoginID] [nvarchar](256) NULL,
        [EmailAddress] [nvarchar](50) NULL,
        [Phone] [nvarchar](25) NULL,
        [MaritalStatus] [nchar](1) NULL,
        [EmergencyContactName] [nvarchar](50) NULL,
        [EmergencyContactPhone] [nvarchar](25) NULL,
        [SalariedFlag] [bit] NULL,
        [Gender] [nchar](1) NULL,
        [PayFrequency] [tinyint] NULL,
        [BaseRate] [money] NULL,
        [VacationHours] [smallint] NULL,
        [SickLeaveHours] [smallint] NULL,
        [CurrentFlag] [bit] NOT NULL,
        [SalesPersonFlag] [bit] NOT NULL,
        [DepartmentName] [nvarchar](50) NULL,
        [StartDate] [date] NULL,
        [EndDate] [date] NULL,
        [Status] [nvarchar](50) NULL,
	    [EmployeePhoto] [varbinary](max) NULL
    );
    GO

    CREATE TABLE [dbo].[DimProduct](
        [ProductKey] [int] IDENTITY(1,1) NOT NULL,
        [ProductAlternateKey] [nvarchar](25) NULL,
        [ProductSubcategoryKey] [int] NULL,
        [WeightUnitMeasureCode] [nchar](3) NULL,
        [SizeUnitMeasureCode] [nchar](3) NULL,
        [EnglishProductName] [nvarchar](50) NOT NULL,
        [SpanishProductName] [nvarchar](50) NOT NULL,
        [FrenchProductName] [nvarchar](50) NOT NULL,
        [StandardCost] [money] NULL,
        [FinishedGoodsFlag] [bit] NOT NULL,
        [Color] [nvarchar](15) NOT NULL,
        [SafetyStockLevel] [smallint] NULL,
        [ReorderPoint] [smallint] NULL,
        [ListPrice] [money] NULL,
        [Size] [nvarchar](50) NULL,
        [SizeRange] [nvarchar](50) NULL,
        [Weight] [float] NULL,
        [DaysToManufacture] [int] NULL,
        [ProductLine] [nchar](2) NULL,
        [DealerPrice] [money] NULL,
        [Class] [nchar](2) NULL,
        [Style] [nchar](2) NULL,
        [ModelName] [nvarchar](50) NULL,
        [LargePhoto] [varbinary](max) NULL,
        [EnglishDescription] [nvarchar](400) NULL,
        [FrenchDescription] [nvarchar](400) NULL,
        [ChineseDescription] [nvarchar](400) NULL,
        [ArabicDescription] [nvarchar](400) NULL,
        [HebrewDescription] [nvarchar](400) NULL,
        [ThaiDescription] [nvarchar](400) NULL,
        [GermanDescription] [nvarchar](400) NULL,
        [JapaneseDescription] [nvarchar](400) NULL,
        [TurkishDescription] [nvarchar](400) NULL,
        [StartDate] [datetime] NULL,
        [EndDate] [datetime] NULL,
        [Status] [nvarchar](7) NULL
    );
    GO

    CREATE TABLE [dbo].[FactResellerSales](
        [ProductKey] [int] NOT NULL,
        [OrderDateKey] [int] NOT NULL,
        [DueDateKey] [int] NOT NULL,
        [ShipDateKey] [int] NOT NULL,
        [ResellerKey] [int] NOT NULL,
        [EmployeeKey] [int] NOT NULL,
        [PromotionKey] [int] NOT NULL,
        [CurrencyKey] [int] NOT NULL,
        [SalesTerritoryKey] [int] NOT NULL,
        [SalesOrderNumber] [nvarchar](20) NOT NULL,
        [SalesOrderLineNumber] [tinyint] NOT NULL,
        [RevisionNumber] [tinyint] NULL,
        [OrderQuantity] [smallint] NULL,
        [UnitPrice] [money] NULL,
        [ExtendedAmount] [money] NULL,
        [UnitPriceDiscountPct] [float] NULL,
        [DiscountAmount] [float] NULL,
        [ProductStandardCost] [money] NULL,
        [TotalProductCost] [money] NULL,
        [SalesAmount] [money] NULL,
        [TaxAmt] [money] NULL,
        [Freight] [money] NULL,
        [CarrierTrackingNumber] [nvarchar](25) NULL,
        [CustomerPONumber] [nvarchar](25) NULL,
        [OrderDate] [datetime] NULL,
        [DueDate] [datetime] NULL,
        [ShipDate] [datetime] NULL
    );
    GO
    ```

10. Select **Run** or hit `F5` to execute the query.

    ![The query and Run button are highlighted.](media/execute-setup-query.png "Execute query")

    Now we have three dimension tables and a fact table. Together, these tables represent a star schema:

    ![The four tables are displayed.](media/star-schema-no-relationships.png "Star schema: no relationships")

    However, since we are using a SQL database, we can add foreign key relationships and constraints to define relationships and enforce the table values.

11. Replace **and execute** the query with the following to create the `DimReseller` primary key and constraints:

    ```sql
    -- Create DimReseller PK
    ALTER TABLE [dbo].[DimReseller] WITH CHECK ADD 
        CONSTRAINT [PK_DimReseller_ResellerKey] PRIMARY KEY CLUSTERED 
        (
            [ResellerKey]
        )  ON [PRIMARY];
    GO

    -- Create DimReseller unique constraint
    ALTER TABLE [dbo].[DimReseller] ADD  CONSTRAINT [AK_DimReseller_ResellerAlternateKey] UNIQUE NONCLUSTERED 
    (
        [ResellerAlternateKey] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    GO
    ```

12. Replace **and execute** the query with the following to create the `DimEmployee` primary key:

    ```sql
    -- Create DimEmployee PK
    ALTER TABLE [dbo].[DimEmployee] WITH CHECK ADD 
        CONSTRAINT [PK_DimEmployee_EmployeeKey] PRIMARY KEY CLUSTERED 
        (
        [EmployeeKey]
        )  ON [PRIMARY];
    GO
    ```

13. Replace **and execute** the query with the following to create the `DimProduct` primary key and constraints:

    ```sql
    -- Create DimProduct PK
    ALTER TABLE [dbo].[DimProduct] WITH CHECK ADD 
        CONSTRAINT [PK_DimProduct_ProductKey] PRIMARY KEY CLUSTERED 
        (
            [ProductKey]
        )  ON [PRIMARY];
    GO

    -- Create DimProduct unique constraint
    ALTER TABLE [dbo].[DimProduct] ADD  CONSTRAINT [AK_DimProduct_ProductAlternateKey_StartDate] UNIQUE NONCLUSTERED 
    (
        [ProductAlternateKey] ASC,
        [StartDate] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    GO
    ```

    > Now we can create the relationships between our fact and dimension tables, clearly defining the star schema.

14. Replace **and execute** the query with the following to create the `FactResellerSales` primary key and foreign key relationships:

    ```sql
    -- Create FactResellerSales PK
    ALTER TABLE [dbo].[FactResellerSales] WITH CHECK ADD 
        CONSTRAINT [PK_FactResellerSales_SalesOrderNumber_SalesOrderLineNumber] PRIMARY KEY CLUSTERED 
        (
            [SalesOrderNumber], [SalesOrderLineNumber]
        )  ON [PRIMARY];
    GO

    -- Create foreign key relationships to the dimension tables
    ALTER TABLE [dbo].[FactResellerSales] ADD
        CONSTRAINT [FK_FactResellerSales_DimEmployee] FOREIGN KEY([EmployeeKey])
                REFERENCES [dbo].[DimEmployee] ([EmployeeKey]),
        CONSTRAINT [FK_FactResellerSales_DimProduct] FOREIGN KEY([ProductKey])
                REFERENCES [dbo].[DimProduct] ([ProductKey]),
        CONSTRAINT [FK_FactResellerSales_DimReseller] FOREIGN KEY([ResellerKey])
                REFERENCES [dbo].[DimReseller] ([ResellerKey]);
    GO
    ```

    Our star schema now has relationships defined between the fact table and dimension tables. If you arrange the tables in a diagram, using a tool such as SQL Server Management studio, you can clearly see the relationships:

    ![The star schema is displayed with relationship keys.](media/star-schema-relationships.png "Star schema with relationships")

## Exercise 2: Implementing a Snowflake Schema

A **snowflake schema** is a set of normalized tables for a single business entity. For example, Adventure Works classifies products by category and subcategory. Categories are assigned to subcategories, and products are in turn assigned to subcategories. In the Adventure Works relational data warehouse, the product dimension is normalized and stored in three related tables: `DimProductCategory`, `DimProductSubcategory`, and `DimProduct`.

The snowflake schema is a variation of the star schema. You add normalized dimension tables to a star schema to create a snowflake pattern. In the following diagram, you see the yellow dimension tables surrounding the blue fact table. Notice that many of the dimension tables relate to one another in order to normalize the business entities:

![Sample snowflake schema.](media/snowflake-schema.png "Snowflake schema")

### Task 1: Create product snowflake schema in SQL database

In this task, you add two new dimension tables: `DimProductCategory` and `DimProductSubcategory`. You create a relationship between these two tables and the `DimProduct` table to create a normalized product dimension, known as a snowflake dimension. Doing so updates the star schema to include the normalized product dimension, transforming it into a snowflake schema.

1. Open Azure Data Explorer.

2. Select **Servers** in the left-hand menu, then right-click the SQL server you added at the beginning of the lab. Select **New Query**.

    ![The New Query link is highlighted.](media/ads-new-query.png "New Query")

3. Paste **and execute** the following into the query window to create the new dimension tables:

    ```sql
    CREATE TABLE [dbo].[DimProductCategory](
        [ProductCategoryKey] [int] IDENTITY(1,1) NOT NULL,
        [ProductCategoryAlternateKey] [int] NULL,
        [EnglishProductCategoryName] [nvarchar](50) NOT NULL,
        [SpanishProductCategoryName] [nvarchar](50) NOT NULL,
        [FrenchProductCategoryName] [nvarchar](50) NOT NULL
    );
    GO

    CREATE TABLE [dbo].[DimProductSubcategory](
        [ProductSubcategoryKey] [int] IDENTITY(1,1) NOT NULL,
        [ProductSubcategoryAlternateKey] [int] NULL,
        [EnglishProductSubcategoryName] [nvarchar](50) NOT NULL,
        [SpanishProductSubcategoryName] [nvarchar](50) NOT NULL,
        [FrenchProductSubcategoryName] [nvarchar](50) NOT NULL,
        [ProductCategoryKey] [int] NULL
    );
    GO
    ```

4. Replace **and execute** the query with the following to create the `DimProductCategory` and `DimProductSubcategory` primary keys and constraints:

    ```sql
    -- Create DimProductCategory PK
    ALTER TABLE [dbo].[DimProductCategory] WITH CHECK ADD 
        CONSTRAINT [PK_DimProductCategory_ProductCategoryKey] PRIMARY KEY CLUSTERED 
        (
            [ProductCategoryKey]
        )  ON [PRIMARY];
    GO

    -- Create DimProductSubcategory PK
    ALTER TABLE [dbo].[DimProductSubcategory] WITH CHECK ADD 
        CONSTRAINT [PK_DimProductSubcategory_ProductSubcategoryKey] PRIMARY KEY CLUSTERED 
        (
            [ProductSubcategoryKey]
        )  ON [PRIMARY];
    GO

    -- Create DimProductCategory unique constraint
    ALTER TABLE [dbo].[DimProductCategory] ADD  CONSTRAINT [AK_DimProductCategory_ProductCategoryAlternateKey] UNIQUE NONCLUSTERED 
    (
        [ProductCategoryAlternateKey] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    GO

    -- Create DimProductSubcategory unique constraint
    ALTER TABLE [dbo].[DimProductSubcategory] ADD  CONSTRAINT [AK_DimProductSubcategory_ProductSubcategoryAlternateKey] UNIQUE NONCLUSTERED 
    (
        [ProductSubcategoryAlternateKey] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    GO
    ```

5. Replace **and execute** the query with the following to create foreign key relationships between `DimProduct` and `DimProductSubcategory`, and `DimProductSubcategory` and `DimProductCategory`:

    ```sql
    -- Create foreign key relationship between DimProduct and DimProductSubcategory
    ALTER TABLE [dbo].[DimProduct] ADD 
        CONSTRAINT [FK_DimProduct_DimProductSubcategory] FOREIGN KEY 
        (
            [ProductSubcategoryKey]
        ) REFERENCES [dbo].[DimProductSubcategory] ([ProductSubcategoryKey]);
    GO

    -- Create foreign key relationship between DimProductSubcategory and DimProductCategory
    ALTER TABLE [dbo].[DimProductSubcategory] ADD 
        CONSTRAINT [FK_DimProductSubcategory_DimProductCategory] FOREIGN KEY 
        (
            [ProductCategoryKey]
        ) REFERENCES [dbo].[DimProductCategory] ([ProductCategoryKey]);
    GO
    ```

    You have created a snowflake dimension by normalizing the three product tables into a single business entity, or product dimension:

    ![The three product tables are displayed.](media/snowflake-dimension-product-tables.png "Product snowflake dimension")

    When we add the other tables into the diagram, we can see that the star schema is now transformed into a snowflake schema by normalizing the product tables. If you arrange the tables in a diagram, using a tool such as SQL Server Management studio, you can clearly see the relationships:

    ![The snowflake schema is shown.](media/snowflake-schema-completed.png "Snowflake schema")

### Task 2: Create reseller snowflake schema in SQL database

In this task, you add two new dimension tables: `DimCustomer` and `DimGeography`. You create a relationship between these two tables and the `DimReseller` table to create a normalized reseller dimension, or snowflake dimension.

1. Paste **and execute** the following into the query window to create the new dimension tables:

    ```sql
    CREATE TABLE [dbo].[DimCustomer](
        [CustomerKey] [int] IDENTITY(1,1) NOT NULL,
        [GeographyKey] [int] NULL,
        [CustomerAlternateKey] [nvarchar](15) NOT NULL,
        [Title] [nvarchar](8) NULL,
        [FirstName] [nvarchar](50) NULL,
        [MiddleName] [nvarchar](50) NULL,
        [LastName] [nvarchar](50) NULL,
        [NameStyle] [bit] NULL,
        [BirthDate] [date] NULL,
        [MaritalStatus] [nchar](1) NULL,
        [Suffix] [nvarchar](10) NULL,
        [Gender] [nvarchar](1) NULL,
        [EmailAddress] [nvarchar](50) NULL,
        [YearlyIncome] [money] NULL,
        [TotalChildren] [tinyint] NULL,
        [NumberChildrenAtHome] [tinyint] NULL,
        [EnglishEducation] [nvarchar](40) NULL,
        [SpanishEducation] [nvarchar](40) NULL,
        [FrenchEducation] [nvarchar](40) NULL,
        [EnglishOccupation] [nvarchar](100) NULL,
        [SpanishOccupation] [nvarchar](100) NULL,
        [FrenchOccupation] [nvarchar](100) NULL,
        [HouseOwnerFlag] [nchar](1) NULL,
        [NumberCarsOwned] [tinyint] NULL,
        [AddressLine1] [nvarchar](120) NULL,
        [AddressLine2] [nvarchar](120) NULL,
        [Phone] [nvarchar](20) NULL,
        [DateFirstPurchase] [date] NULL,
        [CommuteDistance] [nvarchar](15) NULL
    );
    GO

    CREATE TABLE [dbo].[DimGeography](
        [GeographyKey] [int] IDENTITY(1,1) NOT NULL,
        [City] [nvarchar](30) NULL,
        [StateProvinceCode] [nvarchar](3) NULL,
        [StateProvinceName] [nvarchar](50) NULL,
        [CountryRegionCode] [nvarchar](3) NULL,
        [EnglishCountryRegionName] [nvarchar](50) NULL,
        [SpanishCountryRegionName] [nvarchar](50) NULL,
        [FrenchCountryRegionName] [nvarchar](50) NULL,
        [PostalCode] [nvarchar](15) NULL,
        [SalesTerritoryKey] [int] NULL,
        [IpAddressLocator] [nvarchar](15) NULL
    );
    GO
    ```

2. Replace **and execute** the query with the following to create the `DimCustomer` and `DimGeography` primary keys and a unique non-clustered index on the `DimCustomer` table:

    ```sql
    -- Create DimCustomer PK
    ALTER TABLE [dbo].[DimCustomer] WITH CHECK ADD 
        CONSTRAINT [PK_DimCustomer_CustomerKey] PRIMARY KEY CLUSTERED
        (
            [CustomerKey]
        )  ON [PRIMARY];
    GO

    -- Create DimGeography PK
    ALTER TABLE [dbo].[DimGeography] WITH CHECK ADD 
        CONSTRAINT [PK_DimGeography_GeographyKey] PRIMARY KEY CLUSTERED 
        (
        [GeographyKey]
        )  ON [PRIMARY];
    GO

    -- Create DimCustomer index
    CREATE UNIQUE NONCLUSTERED INDEX [IX_DimCustomer_CustomerAlternateKey] ON [dbo].[DimCustomer]([CustomerAlternateKey]) ON [PRIMARY];
    GO
    ```

3. Replace **and execute** the query with the following to create foreign key relationships between `DimReseller` and `DimGeography`, and `DimGeography` and `DimCustomer`:

    ```sql
    -- Create foreign key relationship between DimReseller and DimGeography
    ALTER TABLE [dbo].[DimReseller] ADD
        CONSTRAINT [FK_DimReseller_DimGeography] FOREIGN KEY
        (
            [GeographyKey]
        ) REFERENCES [dbo].[DimGeography] ([GeographyKey]);
    GO

    -- Create foreign key relationship between DimCustomer and DimGeography
    ALTER TABLE [dbo].[DimCustomer] ADD
        CONSTRAINT [FK_DimCustomer_DimGeography] FOREIGN KEY
        (
            [GeographyKey]
        )
        REFERENCES [dbo].[DimGeography] ([GeographyKey])
    GO
    ```

    You now have a new snowflake dimension that normalizes reseller data with geography and customer dimensions.

    ![The reseller snowflake dimension is displayed.](media/snowflake-dimension-reseller.png "Reseller snowflake dimension")

    Now let us look at how these new tables add another level of detail to our snowflake schema:

    ![The finalized snowflake schema.](media/snowflake-schema-final.png "Snowflake schema")

## Exercise 3: Implementing a Time Dimension Table

A time dimension table is one of the most consistently used dimension tables. This type of table enables consistent granularity for temporal analysis and reporting and usually contains temporal hierarchies, such as `Year` > `Quarter` > `Month` > `Day`.

Time dimension tables can contain business-specific attributes that are useful references for reporting and filters, such as fiscal periods and public holidays.

This is the schema of the time dimension table that you will create:

| Column | Data Type |
| --- | --- |
| DateKey | `int` |
| DateAltKey | `datetime` |
| CalendarYear | `int` |
| CalendarQuarter | `int` |
| MonthOfYear | `int` |
| MonthName | `nvarchar(15)` |
| DayOfMonth | `int` |
| DayOfWeek | `int` |
| DayName | `nvarchar(15)` |
| FiscalYear | `int` |
| FiscalQuarter | `int` |

### Task 1: Create time dimension table

In this task, you add the time dimension table and create foreign key relationships to the `FactRetailerSales` table.

1. Paste **and execute** the following into the query window to create the new time dimension table:

    ```sql
    CREATE TABLE DimDate
        (DateKey int NOT NULL,
        DateAltKey datetime NOT NULL,
        CalendarYear int NOT NULL,
        CalendarQuarter int NOT NULL,
        MonthOfYear int NOT NULL,
        [MonthName] nvarchar(15) NOT NULL,
        [DayOfMonth] int NOT NULL,
        [DayOfWeek] int NOT NULL,
        [DayName] nvarchar(15) NOT NULL,
        FiscalYear int NOT NULL,
        FiscalQuarter int NOT NULL)
    GO
    ```

2. Replace **and execute** the query with the following to create the primary key and a unique non-clustered index on the `DimDate` table:

    ```sql
    -- Create DimDate PK
    ALTER TABLE [dbo].[DimDate] WITH CHECK ADD 
        CONSTRAINT [PK_DimDate_DateKey] PRIMARY KEY CLUSTERED 
        (
            [DateKey]
        )  ON [PRIMARY];
    GO

    -- Create unique non-clustered index
    CREATE UNIQUE NONCLUSTERED INDEX [AK_DimDate_DateAltKey] ON [dbo].[DimDate]([DateAltKey]) ON [PRIMARY];
    GO
    ```

3. Replace **and execute** the query with the following to create foreign key relationships between `FactRetailerSales` and `DimDate`:

    ```sql
    ALTER TABLE [dbo].[FactResellerSales] ADD
        CONSTRAINT [FK_FactResellerSales_DimDate] FOREIGN KEY([OrderDateKey])
                REFERENCES [dbo].[DimDate] ([DateKey]),
        CONSTRAINT [FK_FactResellerSales_DimDate1] FOREIGN KEY([DueDateKey])
                REFERENCES [dbo].[DimDate] ([DateKey]),
        CONSTRAINT [FK_FactResellerSales_DimDate2] FOREIGN KEY([ShipDateKey])
                REFERENCES [dbo].[DimDate] ([DateKey]);
    GO
    ```

    > Notice how the three fields refer to the primary key of the `DimDate` table.

    Now our snowflake schema is updated to contain the time dimension table:

    ![The time dimension table is highlighted in the snowflake schema.](media/snowflake-schema-time-dimension.png "Time dimension added to snowflake schema")

### Task 2: Populate the time dimension table

You can populate time dimension tables in one of many ways, including T-SQL scripts using date/time functions, Microsoft Excel functions, importing from a flat file, or auto-generation by BI (business intelligence) tools. In this task, you populate the time dimension table using T-SQL, comparing generation methods along the way.

1. Paste **and execute** the following into the query window to create the new time dimension table:

    ```sql
    DECLARE @StartDate datetime
    DECLARE @EndDate datetime
    SET @StartDate = '01/01/2005'
    SET @EndDate = getdate() 
    DECLARE @LoopDate datetime
    SET @LoopDate = @StartDate
    WHILE @LoopDate <= @EndDate
    BEGIN
    INSERT INTO dbo.DimDate VALUES
        (
            CAST(CONVERT(VARCHAR(8), @LoopDate, 112) AS int) , -- date key
            @LoopDate, -- date alt key
            Year(@LoopDate), -- calendar year
            datepart(qq, @LoopDate), -- calendar quarter
            Month(@LoopDate), -- month number of year
            datename(mm, @LoopDate), -- month name
            Day(@LoopDate),  -- day number of month
            datepart(dw, @LoopDate), -- day number of week
            datename(dw, @LoopDate), -- day name of week
            CASE
                WHEN Month(@LoopDate) < 7 THEN Year(@LoopDate)
                ELSE Year(@Loopdate) + 1
            END, -- Fiscal year (assuming fiscal year runs from Jul to June)
            CASE
                WHEN Month(@LoopDate) IN (1, 2, 3) THEN 3
                WHEN Month(@LoopDate) IN (4, 5, 6) THEN 4
                WHEN Month(@LoopDate) IN (7, 8, 9) THEN 1
                WHEN Month(@LoopDate) IN (10, 11, 12) THEN 2
            END -- fiscal quarter 
        )  		  
        SET @LoopDate = DateAdd(dd, 1, @LoopDate)
    END
    ```

    > In our environment, it took about **18 seconds** to insert the generated rows.

    This query loops from a start date of January 1, 2005 until the current date, calculating and inserting values into the table for each day.

2. Replace **and execute** the query with the following to view the time dimension table data:

    ```sql
    SELECT * FROM dbo.DimDate
    ```

    You should see an output similar to:

    ![The time dimension table output is displayed.](media/time-dimension-table-output.png "Time dimension table output")

3. Here is another way you can loop through dates to populate the table, this time setting both a start and end date. Replace **and execute** the query with the following to loop through dates within a given window (January 1, 1900 - December 31, 2050) and display the output:

    ```sql
    DECLARE @BeginDate datetime
    DECLARE @EndDate datetime

    SET @BeginDate = '1/1/1900'
    SET @EndDate = '12/31/2050'

    CREATE TABLE #Dates ([date] datetime)

    WHILE @BeginDate <= @EndDate
    BEGIN
    INSERT #Dates
    VALUES
    (@BeginDate)

    SET @BeginDate = @BeginDate + 1
    END
    SELECT * FROM #Dates
    DROP TABLE #Dates
    ```

    > In our environment, it took about **4** seconds to insert the generated rows.

    This method works fine, but it has a lot to clean up, executes slowly, and has a lot of code when we factor adding in the other fields. Plus, it uses looping, which is not considered a best practice when inserting data using T-SQL.

4. Replace **and execute** the query with the following to improve the previous method with a [CTE](https://docs.microsoft.com/sql/t-sql/queries/with-common-table-expression-transact-sql?view=sql-server-ver15) (common table expression) statement:

    ```sql
    WITH mycte AS
    (
        SELECT cast('1900-01-01' as datetime) DateValue
        UNION ALL
        SELECT DateValue + 1
        FROM mycte 
        WHERE DateValue + 1 < '2050-12-31'
    )

    SELECT DateValue
    FROM mycte
    OPTION (MAXRECURSION 0)
    ```

    > In our environment, it took **less than one second** to execute the CTE query.

### Task 3: Load data into other tables

In this task, you load the dimension and fact tables with data from a public data source.

1. Paste **and execute** the following into the query window to create a master key encryption, database scoped credential, and external data source that accesses the public blob storage account that contains the source data:

    ```sql
    IF NOT EXISTS (SELECT * FROM sys.symmetric_keys) BEGIN
        declare @pasword nvarchar(400) = CAST(newid() as VARCHAR(400));
        EXEC('CREATE MASTER KEY ENCRYPTION BY PASSWORD = ''' + @pasword + '''')
    END

    CREATE DATABASE SCOPED CREDENTIAL [dataengineering]
    WITH IDENTITY='SHARED ACCESS SIGNATURE',  
    SECRET = 'sv=2019-10-10&st=2021-02-01T01%3A23%3A35Z&se=2030-02-02T01%3A23%3A00Z&sr=c&sp=rl&sig=HuizuG29h8FOrEJwIsCm5wfPFc16N1Z2K3IPVoOrrhM%3D'
    GO

    -- Create external data source secured using credential
    CREATE EXTERNAL DATA SOURCE PublicDataSource WITH (
        TYPE = BLOB_STORAGE,
        LOCATION = 'https://solliancepublicdata.blob.core.windows.net/dataengineering',
        CREDENTIAL = dataengineering
    );
    GO
    ```

2. Replace **and execute** the query with the following to insert data into the fact and dimension tables:

    ```sql
    BULK INSERT[dbo].[DimGeography] FROM 'dp-203/awdata/DimGeography.csv'
    WITH (
        DATA_SOURCE='PublicDataSource',
        CHECK_CONSTRAINTS,
        DATAFILETYPE='widechar',
        FIELDTERMINATOR='|',
        ROWTERMINATOR='\n',
        KEEPIDENTITY,
        TABLOCK
    );
    GO

    BULK INSERT[dbo].[DimCustomer] FROM 'dp-203/awdata/DimCustomer.csv'
    WITH (
        DATA_SOURCE='PublicDataSource',
        CHECK_CONSTRAINTS,
        DATAFILETYPE='widechar',
        FIELDTERMINATOR='|',
        ROWTERMINATOR='\n',
        KEEPIDENTITY,
        TABLOCK
    );
    GO

    BULK INSERT[dbo].[DimReseller] FROM 'dp-203/awdata/DimReseller.csv'
    WITH (
        DATA_SOURCE='PublicDataSource',
        CHECK_CONSTRAINTS,
        DATAFILETYPE='widechar',
        FIELDTERMINATOR='|',
        ROWTERMINATOR='\n',
        KEEPIDENTITY,
        TABLOCK
    );
    GO

    BULK INSERT[dbo].[DimEmployee] FROM 'dp-203/awdata/DimEmployee.csv'
    WITH (
        DATA_SOURCE='PublicDataSource',
        CHECK_CONSTRAINTS,
        DATAFILETYPE='widechar',
        FIELDTERMINATOR='|',
        ROWTERMINATOR='\n',
        KEEPIDENTITY,
        TABLOCK
    );
    GO

    BULK INSERT[dbo].[DimProductCategory] FROM 'dp-203/awdata/DimProductCategory.csv'
    WITH (
        DATA_SOURCE='PublicDataSource',
        CHECK_CONSTRAINTS,
        DATAFILETYPE='widechar',
        FIELDTERMINATOR='|',
        ROWTERMINATOR='\n',
        KEEPIDENTITY,
        TABLOCK
    );
    GO

    BULK INSERT[dbo].[DimProductSubcategory] FROM 'dp-203/awdata/DimProductSubcategory.csv'
    WITH (
        DATA_SOURCE='PublicDataSource',
        CHECK_CONSTRAINTS,
        DATAFILETYPE='widechar',
        FIELDTERMINATOR='|',
        ROWTERMINATOR='\n',
        KEEPIDENTITY,
        TABLOCK
    );
    GO

    BULK INSERT[dbo].[DimProduct] FROM 'dp-203/awdata/DimProduct.csv'
    WITH (
        DATA_SOURCE='PublicDataSource',
        CHECK_CONSTRAINTS,
        DATAFILETYPE='widechar',
        FIELDTERMINATOR='|',
        ROWTERMINATOR='\n',
        KEEPIDENTITY,
        TABLOCK
    );
    GO

    BULK INSERT[dbo].[FactResellerSales] FROM 'dp-203/awdata/FactResellerSales.csv'
    WITH (
        DATA_SOURCE='PublicDataSource',
        CHECK_CONSTRAINTS,
        DATAFILETYPE='widechar',
        FIELDTERMINATOR='|',
        ROWTERMINATOR='\n',
        KEEPIDENTITY,
        TABLOCK
    );
    GO
    ```

### Task 4: Query data

1. Paste **and execute** the following query to retrieve reseller sales data from the snowflake schema at the reseller, product, and month granularity:

    ```sql
    SELECT
            pc.[EnglishProductCategoryName]
            ,Coalesce(p.[ModelName], p.[EnglishProductName]) AS [Model]
            ,CASE
                WHEN e.[BaseRate] < 25 THEN 'Low'
                WHEN e.[BaseRate] > 40 THEN 'High'
                ELSE 'Moderate'
            END AS [EmployeeIncomeGroup]
            ,g.City AS ResellerCity
            ,g.StateProvinceName AS StateProvince
            ,r.[AnnualSales] AS ResellerAnnualSales
            ,d.[CalendarYear]
            ,d.[FiscalYear]
            ,d.[MonthOfYear] AS [Month]
            ,f.[SalesOrderNumber] AS [OrderNumber]
            ,f.SalesOrderLineNumber AS LineNumber
            ,f.OrderQuantity AS Quantity
            ,f.ExtendedAmount AS Amount  
        FROM
            [dbo].[FactResellerSales] f
        INNER JOIN [dbo].[DimReseller] r
            ON f.ResellerKey = r.ResellerKey
        INNER JOIN [dbo].[DimGeography] g
            ON r.GeographyKey = g.GeographyKey
        INNER JOIN [dbo].[DimEmployee] e
            ON f.EmployeeKey = e.EmployeeKey
        INNER JOIN [dbo].[DimDate] d
            ON f.[OrderDateKey] = d.[DateKey]
        INNER JOIN [dbo].[DimProduct] p
            ON f.[ProductKey] = p.[ProductKey]
        INNER JOIN [dbo].[DimProductSubcategory] psc
            ON p.[ProductSubcategoryKey] = psc.[ProductSubcategoryKey]
        INNER JOIN [dbo].[DimProductCategory] pc
            ON psc.[ProductCategoryKey] = pc.[ProductCategoryKey]
        ORDER BY Amount DESC
    ```

    You should see an output similar to the following:

    ![The reseller query results are displayed.](media/reseller-query-results.png "Reseller query results")

2. Replace **and execute** the query with the following to limit the results to October sales between the 2012 and 2013 fiscal years:

    ```sql
    SELECT
            pc.[EnglishProductCategoryName]
            ,Coalesce(p.[ModelName], p.[EnglishProductName]) AS [Model]
            ,CASE
                WHEN e.[BaseRate] < 25 THEN 'Low'
                WHEN e.[BaseRate] > 40 THEN 'High'
                ELSE 'Moderate'
            END AS [EmployeeIncomeGroup]
            ,g.City AS ResellerCity
            ,g.StateProvinceName AS StateProvince
            ,r.[AnnualSales] AS ResellerAnnualSales
            ,d.[CalendarYear]
            ,d.[FiscalYear]
            ,d.[MonthOfYear] AS [Month]
            ,f.[SalesOrderNumber] AS [OrderNumber]
            ,f.SalesOrderLineNumber AS LineNumber
            ,f.OrderQuantity AS Quantity
            ,f.ExtendedAmount AS Amount  
        FROM
            [dbo].[FactResellerSales] f
        INNER JOIN [dbo].[DimReseller] r
            ON f.ResellerKey = r.ResellerKey
        INNER JOIN [dbo].[DimGeography] g
            ON r.GeographyKey = g.GeographyKey
        INNER JOIN [dbo].[DimEmployee] e
            ON f.EmployeeKey = e.EmployeeKey
        INNER JOIN [dbo].[DimDate] d
            ON f.[OrderDateKey] = d.[DateKey]
        INNER JOIN [dbo].[DimProduct] p
            ON f.[ProductKey] = p.[ProductKey]
        INNER JOIN [dbo].[DimProductSubcategory] psc
            ON p.[ProductSubcategoryKey] = psc.[ProductSubcategoryKey]
        INNER JOIN [dbo].[DimProductCategory] pc
            ON psc.[ProductCategoryKey] = pc.[ProductCategoryKey]
        WHERE d.[MonthOfYear] = 10 AND d.[FiscalYear] IN (2012, 2013)
        ORDER BY d.[FiscalYear]
    ```

    You should see an output similar to the following:

    ![The query results are displayed in a table.](media/reseller-query-results-date-filter.png "Reseller query results with date filter")

    > Notice how using the **time dimension table** makes filtering by specific date parts and logical dates (such as fiscal year) easier and more performant than calculating date functions on the fly.

## Exercise 4: Implementing a Star Schema in Synapse Analytics

For larger data sets you may implement your data warehouse in Azure Synapse instead of SQL Server. Star schema models are still a best practice for modeling data in Synapse dedicated SQL pools. You may notice some differences with creating tables in Synapse Analytics vs. SQL database, but the same data modeling principles apply.

 When you create a star schema or snowflake schema in Synapse, it requires some changes to your table creation scripts. In Synapse, you do not have foreign keys and unique value constraints like you do in SQL Server. Since these rules are not enforced at the database layer, the jobs used to load data are more responsible to maintain data integrity. You still have the option to use clustered indexes, but for most dimension tables in Synapse you will benefit from using a clustered columnstore index (CCI).

Since Synapse Analytics is a [massively parallel processing](https://docs.microsoft.com/azure/architecture/data-guide/relational-data/data-warehousing#data-warehousing-in-azure) (MPP) system, you must consider how data is distributed in your table design, as opposed to symmetric multiprocessing (SMP) systems, such as OLTP databases like Azure SQL Database. The table category often determines which option to choose for distributing the table.

| Table category | Recommended distribution option |
|:---------------|:--------------------|
| Fact           | Use hash-distribution with clustered columnstore index. Performance improves when two hash tables are joined on the same distribution column. |
| Dimension      | Use replicated for smaller tables. If tables are too large to store on each Compute node, use hash-distributed. |
| Staging        | Use round-robin for the staging table. The load with CTAS is fast. Once the data is in the staging table, use INSERT...SELECT to move the data to production tables. |

In the case of the dimension tables in this exercise, the amount of data stored per table falls well within the criteria for using a replicated distribution.

### Task 1: Create star schema in Synapse dedicated SQL

In this task, you create a star schema in Azure Synapse dedicated pool. The first step is to create the base dimension and fact tables.

1. Sign in to the Azure portal (<https://portal.azure.com>).

2. Open the resource group for this lab, then select the **Synapse workspace**.

    ![The workspace is highlighted in the resource group.](media/rg-synapse-workspace.png "Synapse workspace")

3. In your Synapse workspace Overview blade, select the **Open** link within `Open Synapse Studio`.

    ![The Open link is highlighted.](media/open-synapse-studio.png "Open Synapse Studio")

4. In Synapse Studio, navigate to the **Data** hub.

    ![Data hub.](media/data-hub.png "Data hub")

5. Select the **Workspace** tab **(1)**, expand Databases, then right-click on **SQLPool01 (2)**. Select **New SQL script (3)**, then select **Empty script (4)**.

    ![The data hub is displayed with the context menus to create a new SQL script.](media/new-sql-script.png "New SQL script")

6. Paste the following script into the empty script window, then select **Run** or hit `F5` to execute the query. You may notice some changes have been made to the original SQL star schema create script. A few notable changes are:
    - Distribution setting has been added to each table
    - Clustered columnstore index is used for most tables.
    - HASH function is used for Fact table distribution since it will be a larger table that should be distributed across nodes.
    - A few fields are using varbinary data types that cannot be included in a clustered columnstore index in Azure Synapse. As a simple solution, a clustered index was used instead.
    
    ```sql
    CREATE TABLE dbo.[DimCustomer](
        [CustomerID] [int] NOT NULL,
        [Title] [nvarchar](8) NULL,
        [FirstName] [nvarchar](50) NOT NULL,
        [MiddleName] [nvarchar](50) NULL,
        [LastName] [nvarchar](50) NOT NULL,
        [Suffix] [nvarchar](10) NULL,
        [CompanyName] [nvarchar](128) NULL,
        [SalesPerson] [nvarchar](256) NULL,
        [EmailAddress] [nvarchar](50) NULL,
        [Phone] [nvarchar](25) NULL,
        [InsertedDate] [datetime] NOT NULL,
        [ModifiedDate] [datetime] NOT NULL,
        [HashKey] [char](66)
    )
    WITH
    (
        DISTRIBUTION = REPLICATE,
        CLUSTERED COLUMNSTORE INDEX
    );
    GO
    
    CREATE TABLE [dbo].[FactResellerSales](
        [ProductKey] [int] NOT NULL,
        [OrderDateKey] [int] NOT NULL,
        [DueDateKey] [int] NOT NULL,
        [ShipDateKey] [int] NOT NULL,
        [ResellerKey] [int] NOT NULL,
        [EmployeeKey] [int] NOT NULL,
        [PromotionKey] [int] NOT NULL,
        [CurrencyKey] [int] NOT NULL,
        [SalesTerritoryKey] [int] NOT NULL,
        [SalesOrderNumber] [nvarchar](20) NOT NULL,
        [SalesOrderLineNumber] [tinyint] NOT NULL,
        [RevisionNumber] [tinyint] NULL,
        [OrderQuantity] [smallint] NULL,
        [UnitPrice] [money] NULL,
        [ExtendedAmount] [money] NULL,
        [UnitPriceDiscountPct] [float] NULL,
        [DiscountAmount] [float] NULL,
        [ProductStandardCost] [money] NULL,
        [TotalProductCost] [money] NULL,
        [SalesAmount] [money] NULL,
        [TaxAmt] [money] NULL,
        [Freight] [money] NULL,
        [CarrierTrackingNumber] [nvarchar](25) NULL,
        [CustomerPONumber] [nvarchar](25) NULL,
        [OrderDate] [datetime] NULL,
        [DueDate] [datetime] NULL,
        [ShipDate] [datetime] NULL
    )
    WITH
    (
        DISTRIBUTION = HASH([SalesOrderNumber]),
        CLUSTERED COLUMNSTORE INDEX
    );
    GO

    CREATE TABLE [dbo].[DimDate]
    ( 
        [DateKey] [int]  NOT NULL,
        [DateAltKey] [datetime]  NOT NULL,
        [CalendarYear] [int]  NOT NULL,
        [CalendarQuarter] [int]  NOT NULL,
        [MonthOfYear] [int]  NOT NULL,
        [MonthName] [nvarchar](15)  NOT NULL,
        [DayOfMonth] [int]  NOT NULL,
        [DayOfWeek] [int]  NOT NULL,
        [DayName] [nvarchar](15)  NOT NULL,
        [FiscalYear] [int]  NOT NULL,
        [FiscalQuarter] [int]  NOT NULL
    )
    WITH
    (
        DISTRIBUTION = REPLICATE,
        CLUSTERED COLUMNSTORE INDEX
    );
    GO

    CREATE TABLE [dbo].[DimReseller](
        [ResellerKey] [int] NOT NULL,
        [GeographyKey] [int] NULL,
        [ResellerAlternateKey] [nvarchar](15) NULL,
        [Phone] [nvarchar](25) NULL,
        [BusinessType] [varchar](20) NOT NULL,
        [ResellerName] [nvarchar](50) NOT NULL,
        [NumberEmployees] [int] NULL,
        [OrderFrequency] [char](1) NULL,
        [OrderMonth] [tinyint] NULL,
        [FirstOrderYear] [int] NULL,
        [LastOrderYear] [int] NULL,
        [ProductLine] [nvarchar](50) NULL,
        [AddressLine1] [nvarchar](60) NULL,
        [AddressLine2] [nvarchar](60) NULL,
        [AnnualSales] [money] NULL,
        [BankName] [nvarchar](50) NULL,
        [MinPaymentType] [tinyint] NULL,
        [MinPaymentAmount] [money] NULL,
        [AnnualRevenue] [money] NULL,
        [YearOpened] [int] NULL
    )
    WITH
    (
        DISTRIBUTION = REPLICATE,
        CLUSTERED COLUMNSTORE INDEX
    );
    GO
    
    CREATE TABLE [dbo].[DimEmployee](
        [EmployeeKey] [int] NOT NULL,
        [ParentEmployeeKey] [int] NULL,
        [EmployeeNationalIDAlternateKey] [nvarchar](15) NULL,
        [ParentEmployeeNationalIDAlternateKey] [nvarchar](15) NULL,
        [SalesTerritoryKey] [int] NULL,
        [FirstName] [nvarchar](50) NOT NULL,
        [LastName] [nvarchar](50) NOT NULL,
        [MiddleName] [nvarchar](50) NULL,
        [NameStyle] [bit] NOT NULL,
        [Title] [nvarchar](50) NULL,
        [HireDate] [date] NULL,
        [BirthDate] [date] NULL,
        [LoginID] [nvarchar](256) NULL,
        [EmailAddress] [nvarchar](50) NULL,
        [Phone] [nvarchar](25) NULL,
        [MaritalStatus] [nchar](1) NULL,
        [EmergencyContactName] [nvarchar](50) NULL,
        [EmergencyContactPhone] [nvarchar](25) NULL,
        [SalariedFlag] [bit] NULL,
        [Gender] [nchar](1) NULL,
        [PayFrequency] [tinyint] NULL,
        [BaseRate] [money] NULL,
        [VacationHours] [smallint] NULL,
        [SickLeaveHours] [smallint] NULL,
        [CurrentFlag] [bit] NOT NULL,
        [SalesPersonFlag] [bit] NOT NULL,
        [DepartmentName] [nvarchar](50) NULL,
        [StartDate] [date] NULL,
        [EndDate] [date] NULL,
        [Status] [nvarchar](50) NULL,
        [EmployeePhoto] [varbinary](max) NULL
    )
    WITH
    (
        DISTRIBUTION = REPLICATE,
        CLUSTERED INDEX (EmployeeKey)
    );
    GO
    
    CREATE TABLE [dbo].[DimProduct](
        [ProductKey] [int] NOT NULL,
        [ProductAlternateKey] [nvarchar](25) NULL,
        [ProductSubcategoryKey] [int] NULL,
        [WeightUnitMeasureCode] [nchar](3) NULL,
        [SizeUnitMeasureCode] [nchar](3) NULL,
        [EnglishProductName] [nvarchar](50) NOT NULL,
        [SpanishProductName] [nvarchar](50) NULL,
        [FrenchProductName] [nvarchar](50) NULL,
        [StandardCost] [money] NULL,
        [FinishedGoodsFlag] [bit] NOT NULL,
        [Color] [nvarchar](15) NOT NULL,
        [SafetyStockLevel] [smallint] NULL,
        [ReorderPoint] [smallint] NULL,
        [ListPrice] [money] NULL,
        [Size] [nvarchar](50) NULL,
        [SizeRange] [nvarchar](50) NULL,
        [Weight] [float] NULL,
        [DaysToManufacture] [int] NULL,
        [ProductLine] [nchar](2) NULL,
        [DealerPrice] [money] NULL,
        [Class] [nchar](2) NULL,
        [Style] [nchar](2) NULL,
        [ModelName] [nvarchar](50) NULL,
        [LargePhoto] [varbinary](max) NULL,
        [EnglishDescription] [nvarchar](400) NULL,
        [FrenchDescription] [nvarchar](400) NULL,
        [ChineseDescription] [nvarchar](400) NULL,
        [ArabicDescription] [nvarchar](400) NULL,
        [HebrewDescription] [nvarchar](400) NULL,
        [ThaiDescription] [nvarchar](400) NULL,
        [GermanDescription] [nvarchar](400) NULL,
        [JapaneseDescription] [nvarchar](400) NULL,
        [TurkishDescription] [nvarchar](400) NULL,
        [StartDate] [datetime] NULL,
        [EndDate] [datetime] NULL,
        [Status] [nvarchar](7) NULL    
    )
    WITH
    (
        DISTRIBUTION = REPLICATE,
        CLUSTERED INDEX (ProductKey)
    );
    GO

    CREATE TABLE [dbo].[DimGeography](
        [GeographyKey] [int] NOT NULL,
        [City] [nvarchar](30) NULL,
        [StateProvinceCode] [nvarchar](3) NULL,
        [StateProvinceName] [nvarchar](50) NULL,
        [CountryRegionCode] [nvarchar](3) NULL,
        [EnglishCountryRegionName] [nvarchar](50) NULL,
        [SpanishCountryRegionName] [nvarchar](50) NULL,
        [FrenchCountryRegionName] [nvarchar](50) NULL,
        [PostalCode] [nvarchar](15) NULL,
        [SalesTerritoryKey] [int] NULL,
        [IpAddressLocator] [nvarchar](15) NULL
    )
    WITH
    (
        DISTRIBUTION = REPLICATE,
        CLUSTERED COLUMNSTORE INDEX
    );
    GO
    ```
    You will find `Run` in the top left corner of the script window.
    ![The script and Run button are both highlighted.](media/synapse-create-table-script.png "Create table script")

### Task 2: Load data into Synapse tables

In this task, you load the Synapse dimension and fact tables with data from a public data source. There are two ways to load this data from Azure Storage files using T-SQL: the COPY command or selecting from external tables using Polybase. For this task you will use COPY since it is a simple and flexible syntax for loading delimited data from Azure Storage. If the source were a private storage account you would include a CREDENTIAL option to authorize the COPY command to read the data, but for this example that is not required.

1. Paste **and execute** the query with the following to insert data into the fact and dimension tables:

    ```sql
    COPY INTO [dbo].[DimProduct]
    FROM 'https://solliancepublicdata.blob.core.windows.net/dataengineering/dp-203/awdata/DimProduct.csv'
    WITH (
        FILE_TYPE='CSV',
        FIELDTERMINATOR='|',
        FIELDQUOTE='',
        ROWTERMINATOR='\n',
        ENCODING = 'UTF16'
    );
    GO

    COPY INTO [dbo].[DimReseller]
    FROM 'https://solliancepublicdata.blob.core.windows.net/dataengineering/dp-203/awdata/DimReseller.csv'
    WITH (
        FILE_TYPE='CSV',
        FIELDTERMINATOR='|',
        FIELDQUOTE='',
        ROWTERMINATOR='\n',
        ENCODING = 'UTF16'
    );
    GO

    COPY INTO [dbo].[DimEmployee]
    FROM 'https://solliancepublicdata.blob.core.windows.net/dataengineering/dp-203/awdata/DimEmployee.csv'
    WITH (
        FILE_TYPE='CSV',
        FIELDTERMINATOR='|',
        FIELDQUOTE='',
        ROWTERMINATOR='\n',
        ENCODING = 'UTF16'
    );
    GO

    COPY INTO [dbo].[DimGeography]
    FROM 'https://solliancepublicdata.blob.core.windows.net/dataengineering/dp-203/awdata/DimGeography.csv'
    WITH (
        FILE_TYPE='CSV',
        FIELDTERMINATOR='|',
        FIELDQUOTE='',
        ROWTERMINATOR='\n',
        ENCODING = 'UTF16'
    );
    GO

    COPY INTO [dbo].[FactResellerSales]
    FROM 'https://solliancepublicdata.blob.core.windows.net/dataengineering/dp-203/awdata/FactResellerSales.csv'
    WITH (
        FILE_TYPE='CSV',
        FIELDTERMINATOR='|',
        FIELDQUOTE='',
        ROWTERMINATOR='\n',
        ENCODING = 'UTF16'
    );
    GO
    ```

2. To populate the time dimension table in Azure Synapse, it is fastest to load the data from a delimited file since the looping method used to create the time data runs slowly. To populate this important time dimension, paste **and execute** the following in the query window:

    ```sql
    COPY INTO [dbo].[DimDate]
    FROM 'https://solliancepublicdata.blob.core.windows.net/dataengineering/dp-203/awdata/DimDate.csv'
    WITH (
        FILE_TYPE='CSV',
        FIELDTERMINATOR='|',
        FIELDQUOTE='',
        ROWTERMINATOR='0x0a',
        ENCODING = 'UTF16'
    );
    GO
    ```

### Task 3: Query data from Synapse

1. Paste **and execute** the following query to retrieve reseller sales data from the Synapse star schema at the reseller location, product, and month granularity:

    ```sql
    SELECT
        Coalesce(p.[ModelName], p.[EnglishProductName]) AS [Model]
        ,g.City AS ResellerCity
        ,g.StateProvinceName AS StateProvince
        ,d.[CalendarYear]
        ,d.[FiscalYear]
        ,d.[MonthOfYear] AS [Month]
        ,sum(f.OrderQuantity) AS Quantity
        ,sum(f.ExtendedAmount) AS Amount
        ,approx_count_distinct(f.SalesOrderNumber) AS UniqueOrders  
    FROM
        [dbo].[FactResellerSales] f
    INNER JOIN [dbo].[DimReseller] r
        ON f.ResellerKey = r.ResellerKey
    INNER JOIN [dbo].[DimGeography] g
        ON r.GeographyKey = g.GeographyKey
    INNER JOIN [dbo].[DimDate] d
        ON f.[OrderDateKey] = d.[DateKey]
    INNER JOIN [dbo].[DimProduct] p
        ON f.[ProductKey] = p.[ProductKey]
    GROUP BY
        Coalesce(p.[ModelName], p.[EnglishProductName])
        ,g.City
        ,g.StateProvinceName
        ,d.[CalendarYear]
        ,d.[FiscalYear]
        ,d.[MonthOfYear]
    ORDER BY Amount DESC
    ```

    You should see an output similar to the following:

    ![The reseller query results are displayed.](media/reseller-query-results-synapse.png "Reseller query results")

2. Replace **and execute** the query with the following to limit the results to October sales between the 2012 and 2013 fiscal years:

    ```sql
    SELECT
        Coalesce(p.[ModelName], p.[EnglishProductName]) AS [Model]
        ,g.City AS ResellerCity
        ,g.StateProvinceName AS StateProvince
        ,d.[CalendarYear]
        ,d.[FiscalYear]
        ,d.[MonthOfYear] AS [Month]
        ,sum(f.OrderQuantity) AS Quantity
        ,sum(f.ExtendedAmount) AS Amount
        ,approx_count_distinct(f.SalesOrderNumber) AS UniqueOrders  
    FROM
        [dbo].[FactResellerSales] f
    INNER JOIN [dbo].[DimReseller] r
        ON f.ResellerKey = r.ResellerKey
    INNER JOIN [dbo].[DimGeography] g
        ON r.GeographyKey = g.GeographyKey
    INNER JOIN [dbo].[DimDate] d
        ON f.[OrderDateKey] = d.[DateKey]
    INNER JOIN [dbo].[DimProduct] p
        ON f.[ProductKey] = p.[ProductKey]
    WHERE d.[MonthOfYear] = 10 AND d.[FiscalYear] IN (2012, 2013)
    GROUP BY
        Coalesce(p.[ModelName], p.[EnglishProductName])
        ,g.City
        ,g.StateProvinceName
        ,d.[CalendarYear]
        ,d.[FiscalYear]
        ,d.[MonthOfYear]
    ORDER BY d.[FiscalYear]
    ```

    You should see an output similar to the following:

    ![The query results are displayed in a table.](media/reseller-query-results-date-filter-synapse.png "Reseller query results with date filter")

    > Notice how using the **time dimension table** makes filtering by specific date parts and logical dates (such as fiscal year) easier and more performant than calculating date functions on the fly.

## Exercise 5: Updating slowly changing dimensions with mapping data flows

A **slowly changing dimension** (SCD) is one that appropriately manages change of dimension members over time. It applies when business entity values change over time, and in an ad hoc manner. A good example of a slowly changing dimension is a customer dimension, specifically its contact detail columns like email address and phone number. In contrast, some dimensions are considered to be rapidly changing when a dimension attribute changes often, like a stock's market price. The common design approach in these instances is to store rapidly changing attribute values in a fact table measure.

Star schema design theory refers to two common SCD types: Type 1 and Type 2. A dimension-type table could be Type 1 or Type 2, or support both types simultaneously for different columns.

**Type 1 SCD**

A **Type 1 SCD** always reflects the latest values, and when changes in source data are detected, the dimension table data is overwritten. This design approach is common for columns that store supplementary values, like the email address or phone number of a customer. When a customer email address or phone number changes, the dimension table updates the customer row with the new values. It's as if the customer always had this contact information.

**Type 2 SCD**

A **Type 2 SCD** supports versioning of dimension members. If the source system doesn't store versions, then it's usually the data warehouse load process that detects changes, and appropriately manages the change in a dimension table. In this case, the dimension table must use a surrogate key to provide a unique reference to a version of the dimension member. It also includes columns that define the date range validity of the version (for example, `StartDate` and `EndDate`) and possibly a flag column (for example, `IsCurrent`) to easily filter by current dimension members.

For example, Adventure Works assigns salespeople to a sales region. When a salesperson relocates region, a new version of the salesperson must be created to ensure that historical facts remain associated with the former region. To support accurate historic analysis of sales by salesperson, the dimension table must store versions of salespeople and their associated region(s). The table should also include start and end date values to define the time validity. Current versions may define an empty end date (or 12/31/9999), which indicates that the row is the current version. The table must also define a surrogate key because the business key (in this instance, employee ID) won't be unique.

It's important to understand that when the source data doesn't store versions, you must use an intermediate system (like a data warehouse) to detect and store changes. The table load process must preserve existing data and detect changes. When a change is detected, the table load process must expire the current version. It records these changes by updating the `EndDate` value and inserting a new version with the `StartDate` value commencing from the previous `EndDate` value. Also, related facts must use a time-based lookup to retrieve the dimension key value relevant to the fact date.

In this exercise, you create a Type 1 SCD with Azure SQL Database as the source, and your Synapse dedicated SQL pool as the destination.

### Task 1: Create the Azure SQL Database linked service

Linked services in Synapse Analytics enables you to manage connections to external resources. In this task, you create a linked service for the Azure SQL Database used as the data source for the `DimCustomer` dimension table.

1. In Synapse Studio, navigate to the **Manage** hub.

    ![Manage hub.](media/manage-hub.png "Manage hub")

2. Select **Linked services** on the left, then select **+ New**.

    ![The New button is highlighted.](media/linked-services-new.png "Linked services")

3. Select **Azure SQL Database**, then select **Continue**.

    ![Azure SQL Database is selected.](media/new-linked-service-sql.png "New linked service")

4. Complete the new linked service form as follows:

    - **Name**: Enter `AzureSqlDatabaseSource`
    - **Account selection method**: Select `From Azure subscription`
    - **Azure subscription**: Select the Azure subscription used for this lab
    - **Server name**: Select the Azure SQL Server named `dp203sqlSUFFIX` (where SUFFIX is your unique suffix)
    - **Database name**: Select `SourceDB`
    - **Authentication type**: Select `SQL authentication`
    - **Username**: Enter `sqladmin`
    - **Password**: Enter the password you provided during the environment setup, or that was given to you if this is a hosted lab environment (also used at the beginning of this lab)

    ![The form is completed as described.](media/new-linked-service-sql-form.png "New linked service form")

5. Select **Create**.

### Task 2: Create a mapping data flow

Mapping Data flows are pipeline activities that provide a visual way of specifying how to transform data, through a code-free experience. This feature offers data cleansing, transformation, aggregation, conversion, joins, data copy operations, etc.

In this task, you create a mapping data flow to create a Type 1 SCD.

1. Navigate to the **Develop** hub.

    ![Develop hub.](media/develop-hub.png "Develop hub")

2. Select **+**, then select **Data flow**.

    ![The plus button and data flow menu item are highlighted.](media/new-data-flow.png "New data flow")

3. In the properties pane of the new data flow, enter `UpdateCustomerDimension` in the **Name** field **(1)**, then select the **Properties** button **(2)** to hide the properties pane.

    ![The data flow properties pane is displayed.](media/data-flow-properties.png "Properties")

4. Select **Data flow debug** to enable the debugger. This will allow us to preview data transformations and debug the data flow before executing it in a pipeline.

    ![The Data Flow debug button is highlighted.](media/data-flow-turn-on-debug.png "Data flow debug")

5. Select **OK** in the dialog that appears to turn on the data flow debug.

    ![The OK button is highlighted.](media/data-flow-turn-on-debug-dialog.png "Turn on data flow debug")

    The debug cluster will start in a few minutes. In the meantime, you can continue with the next step.

6. Select **Add Source** on the canvas.

    ![The Add Source button is highlighted on the data flow canvas.](media/data-flow-add-source.png "Add Source")

7. Under `Source settings`, configure the following properties:

    - **Output stream name**: Enter `SourceDB`
    - **Source type**: Select `Dataset`
    - **Options**: Check `Allow schema drift` and leave the other options unchecked
    - **Sampling**: Select `Disable`
    - **Dataset**: Select **+ New** to create a new dataset

    ![The New button is highlighted next to Dataset.](media/data-flow-source-new-dataset.png "Source settings")

8. In the new integration dataset dialog, select **Azure SQL Database**, then select **Continue**.

    ![Azure SQL Database and the Continue button are highlighted.](media/data-flow-new-integration-dataset-sql.png "New integration dataset")

9. In the dataset properties, configure the following:

    - **Name**: Enter `SourceCustomer`
    - **Linked service**: Select `AzureSqlDatabaseSource`
    - **Table name**: Select `SalesLT.Customer`

    ![The form is configured as described.](media/data-flow-new-integration-dataset-sql-form.png "Set properties")

10. Select **OK** to create the dataset.

11. The `SourceCustomer` dataset should now appear and be selected as the dataset for the source settings.

    ![The new dataset is selected in the source settings.](media/data-flow-source-dataset.png "Source settings: Dataset selected")

12. Select **+** to the right of the `SourceDB` source on the canvas, then select **Derived Column**.

    ![The plus button and derived column menu item are both highlighted.](media/data-flow-new-derived-column.png "New Derived Column")

13. Under `Derived column's settings`, configure the following properties:

    - **Output stream name**: Enter `CreateCustomerHash`
    - **Incoming stream**: Select `SourceDB`
    - **Columns**: Enter the following:

    | Column | Expression | Description |
    | --- | --- | --- |
    | Type in `HashKey` | `sha2(256, iifNull(Title,'') +FirstName +iifNull(MiddleName,'') +LastName +iifNull(Suffix,'') +iifNull(CompanyName,'') +iifNull(SalesPerson,'') +iifNull(EmailAddress,'') +iifNull(Phone,''))` | Creates a SHA256 hash of the table values. We use this to detect row changes by comparing the hash of the incoming records to the hash value of the destination records, matching on the `CustomerID` value. The `iifNull` function replaces null values with empty strings. Otherwise, the has values tend to duplicate when null entries are present. |

    ![The form is configured as described.](media/data-flow-derived-column-settings.png "Derived column settings")

14. Click in the **Expression** text box, then select **Open expression builder**.

    ![The open expression builder link is highlighted.](media/data-flow-derived-column-expression-builder-link.png "Open expression builder")

15. Select **Refresh** next to `Data preview` to preview the output of the `HashKey` column, which uses the `sha2` function you added. you should see that each hash value is unique.

    ![The data preview is displayed.](media/data-flow-derived-column-expression-builder.png "Visual expression builder")

16. Select **Save and finish** to close the expression builder.

17. Select **Add Source** on the canvas underneath the `SourceDB` source. We need to add the `DimCustomer` table located in the Synapse dedicated SQL pool to use when comparing the existence of records and for comparing hashes.

    ![The Add Source button is highlighted on the canvas.](media/data-flow-add-source-synapse.png "Add Source")

18. Under `Source settings`, configure the following properties:

    - **Output stream name**: Enter `SynapseDimCustomer`
    - **Source type**: Select `Dataset`
    - **Options**: Check `Allow schema drift` and leave the other options unchecked
    - **Sampling**: Select `Disable`
    - **Dataset**: Select **+ New** to create a new dataset

    ![The New button is highlighted next to Dataset.](media/data-flow-source-new-dataset2.png "Source settings")

19. In the new integration dataset dialog, select **Azure Synapse Analytics**, then select **Continue**.

    ![Azure Synapse Analytics and the Continue button are highlighted.](media/data-flow-new-integration-dataset-synapse.png "New integration dataset")

20. In the dataset properties, configure the following:

    - **Name**: Enter `DimCustomer`
    - **Linked service**: Select the Synapse workspace linked service
    - **Table name**: Select the **Refresh button** next to the dropdown

    ![The form is configured as described and the refresh button is highlighted.](media/data-flow-new-integration-dataset-synapse-refresh.png "Refresh")

21. In the **Value** field, enter `SQLPool01`, then select **OK**.

    ![The SQLPool01 parameter is highlighted.](media/data-flow-new-integration-dataset-synapse-parameter.png "Please provide actual value of the parameters to list tables")

22. Select `dbo.DimCustomer` under **Table name**, select `From connection/store` under **Import schema**, then select **OK** to create the dataset.

    ![The form is completed as described.](media/data-flow-new-integration-dataset-synapse-form.png "Table name selected")

23. The `DimCustomer` dataset should now appear and be selected as the dataset for the source settings.

    ![The new dataset is selected in the source settings.](media/data-flow-source-dataset2.png "Source settings: Dataset selected")

24. Select **Open** next to the `DimCustomer` dataset that you added.

    ![The open button is highlighted next to the new dataset.](media/data-flow-source-dataset2-open.png "Open dataset")

25. Enter `SQLPool01` in the **Value** field next to `DBName`.

    ![The value field is highlighted.](media/dimcustomer-dataset.png "DimCustomer dataset")

26. Switch back to your data flow. *Do not* close the `DimCustomer` dataset. Select **+** to the right of the `CreateCustomerHash` derived column on the canvas, then select **Exists**.

    ![The plus button and exists menu item are both highlighted.](media/data-flow-new-exists.png "New Exists")

27. Under `Exists settings`, configure the following properties:

    - **Output stream name**: Enter `Exists`
    - **Left stream**: Select `CreateCustomerHash`
    - **Right stream**: Select `SynapseDimCustomer`
    - **Exist type**: Select `Doesn't exist`
    - **Exists conditions**: Set the following for Left and Right:

    | Left: CreateCustomerHash's column | Right: SynapseDimCustomer's column |
    | --- | --- |
    | `HashKey` | `HashKey` |

    ![The form is configured as described.](media/data-flow-exists-form.png "Exists settings")

28. Select **+** to the right of `Exists` on the canvas, then select **Lookup**.

    ![The plus button and lookup menu item are both highlighted.](media/data-flow-new-lookup.png "New Lookup")

29. Under `Lookup settings`, configure the following properties:

    - **Output stream name**: Enter `LookupCustomerID`
    - **Primary stream**: Select `Exists`
    - **Lookup stream**: Select `SynapseDimCustomer`
    - **Match multiple rows**: Unchecked
    - **Match on**: Select `Any row`
    - **Lookup conditions**: Set the following for Left and Right:

    | Left: Exists's column | Right: SynapseDimCustomer's column |
    | --- | --- |
    | `CustomerID` | `CustomerID` |

    ![The form is configured as described.](media/data-flow-lookup-form.png "Lookup settings")

30. Select **+** to the right of `LookupCustomerID` on the canvas, then select **Derived Column**.

    ![The plus button and derived column menu item are both highlighted.](media/data-flow-new-derived-column2.png "New Derived Column")

31. Under `Derived column's settings`, configure the following properties:

    - **Output stream name**: Enter `SetDates`
    - **Incoming stream**: Select `LookupCustomerID`
    - **Columns**: Enter the following:

    | Column | Expression | Description |
    | --- | --- | --- |
    | Select `InsertedDate` | `iif(isNull(InsertedDate), currentTimestamp(), {InsertedDate})` | If the `InsertedDate` value is null, insert the current timestamp. Otherwise, use the `InsertedDate` value. |
    | Select `ModifiedDate` | `currentTimestamp()` | Always update the `ModifiedDate` value with the current timestamp. |

    ![The form is configured as described.](media/data-flow-derived-column-settings2.png "Derived column settings")

    > **Note**: To insert the second column, select **+ Add** above the Columns list, then select **Add column**.

32. Select **+** to the right of the `SetDates` derived column step on the canvas, then select **Alter Row**.

    ![The plus button and alter row menu item are both highlighted.](media/data-flow-new-alter-row.png "New Alter Row")

33. Under `Alter row settings`, configure the following properties:

    - **Output stream name**: Enter `AllowUpserts`
    - **Incoming stream**: Select `SetDates`
    - **Alter row conditions**: Enter the following:

    | Condition | Expression | Description |
    | --- | --- | --- |
    | Select `Upsert if` | `true()` | Set the condition to `true()` on the `Upsert if` condition to allow upserts. This ensures that all data that passes through the steps in the mapping data flow will be inserted or updated into the sink. |

    ![The form is configured as described.](media/data-flow-alter-row-settings.png "Alter row settings")

34. Select **+** to the right of the `AllowUpserts` alter row step on the canvas, then select **Sink**.

    ![The plus button and sink menu item are both highlighted.](media/data-flow-new-sink.png "New Sink")

35. Under `Sink`, configure the following properties:

    - **Output stream name**: Enter `Sink`
    - **Incoming stream**: Select `AllowUpserts`
    - **Sink type**: Select `Dataset`
    - **Dataset**: Select `DimCustomer`
    - **Options**: Check `Allow schema drift` and uncheck `Validate schema`

    ![The form is configured as described.](media/data-flow-sink-form.png "Sink form")

36. Select the **Settings** tab and configure the following properties:

    - **Update method**: Check `Allow upsert` and uncheck all other options
    - **Key columns**: Select `List of columns`, then select `CustomerID` in the list
    - **Table action**: Select `None`
    - **Enable staging**: Unchecked

    ![The sink settings are configured as described.](media/data-flow-sink-settings.png "Sink settings")

37. Select the **Mapping** tab, then uncheck **Auto mapping**. Configure the input columns mapping as outlined below:

    | Input columns | Output columns |
    | --- | --- |
    | `SourceDB@CustomerID` | `CustomerID` |
    | `SourceDB@Title` | `Title` |
    | `SourceDB@FirstName` | `FirstName` |
    | `SourceDB@MiddleName` | `MiddleName` |
    | `SourceDB@LastName` | `LastName` |
    | `SourceDB@Suffix` | `Suffix` |
    | `SourceDB@CompanyName` | `CompanyName` |
    | `SourceDB@SalesPerson` | `SalesPerson` |
    | `SourceDB@EmailAddress` | `EmailAddress` |
    | `SourceDB@Phone` | `Phone` |
    | `InsertedDate` | `InsertedDate` |
    | `ModifiedDate` | `ModifiedDate` |
    | `CreateCustomerHash@HashKey` | `HashKey` |

    ![Mapping settings are configured as described.](media/data-flow-sink-mapping.png "Mapping")

38. The completed mapping flow should look like the following. Select **Publish all** to save your changes.

    ![The completed data flow is displayed and Publish all is highlighted.](media/data-flow-publish-all.png "Completed data flow - Publish all")

39. Select **Publish**.

    ![The publish button is highlighted.](media/publish-all.png "Publish all")

### Task 3: Create a pipeline and run the data flow

In this task, you create a new Synapse integration pipeline to execute the mapping data flow, then run it to upsert customer records.

1. Navigate to the **Integrate** hub.

    ![Integrate hub.](media/integrate-hub.png "Integrate hub")

2. Select **+**, then select **Pipeline**.

    ![The new pipeline menu option is highlighted.](media/new-pipeline.png "New pipeline")

3. In the properties pane of the new pipeline, enter `RunUpdateCustomerDimension` in the **Name** field **(1)**, then select the **Properties** button **(2)** to hide the properties pane.

    ![The pipeline properties pane is displayed.](media/pipeline-properties.png "Properties")

4. Under the Activities pane to the left of the design canvas, expand `Move & transform`, then drag and drop the **Data flow** activity onto the canvas.

    ![The data flow has an arrow from the activities pane to the canvas on the right.](media/pipeline-add-data-flow.png "Add data flow activity")

5. Under the `General` tab, enter **UpdateCustomerDimension** for the name.

    ![The name is entered as described.](media/pipeline-dataflow-general.png "General")

6. Under the `Settings` tab, select the **UpdateCustomerDimension** data flow.

    ![The settings are configured as described.](media/pipeline-dataflow-settings.png "Data flow settings")

6. Select **Publish all**, then select **Publish** in the dialog that appears.

    ![The publish all button is displayed.](media/publish-all-button.png "Publish all button")

7. After publishing completes, select **Add trigger** above the pipeline canvas, then select **Trigger now**.

    ![The add trigger button and trigger now menu item are both highlighted.](media/pipeline-trigger.png "Pipeline trigger")

8. Navigate to the **Monitor** hub.

    ![Monitor hub.](media/monitor-hub.png "Monitor hub")

9. Select **Pipeline runs** in the left-hand menu **(1)** and wait for the pipeline run to successfully complete **(2)**. You may have to select **Refresh (3)** several times until the pipeline run completes.

    ![The pipeline run successfully completed.](media/pipeline-runs.png "Pipeline runs")

### Task 4: View inserted data

1. Navigate to the **Data** hub.

    ![Data hub.](media/data-hub.png "Data hub")

2. Select the **Workspace** tab **(1)**, expand Databases, then right-click on **SQLPool01 (2)**. Select **New SQL script (3)**, then select **Empty script (4)**.

    ![The data hub is displayed with the context menus to create a new SQL script.](media/new-sql-script.png "New SQL script")

3. Paste the following in the query window, then select **Run** or hit F5 to execute the script and view the results:

    ```sql
    SELECT * FROM DimCustomer
    ```

    ![The script is displayed with the customer table output.](media/first-customer-script-run.png "Customer list output")

### Task 5: Update a source customer record

1. Open Azure Data Studio, or switch back to it if still open.

2. Select **Servers** in the left-hand menu, then right-click the SQL server you added at the beginning of the lab. Select **New Query**.

    ![The New Query link is highlighted.](media/ads-new-query2.png "New Query")

3. Paste the following into the query window to view the customer with a `CustomerID` of 10:

    ```sql
    SELECT * FROM [SalesLT].[Customer] WHERE CustomerID = 10
    ```

4. Select **Run** or hit `F5` to execute the query.

    ![The output is shown and the last name value is highlighted.](media/customer-query-garza.png "Customer query output")

    The customer for Ms. Kathleen M. Garza is displayed. Let's change the customer's last name.

5. Replace **and execute** the query with the following to update the customer's last name:

    ```sql
    UPDATE [SalesLT].[Customer] SET LastName = 'Smith' WHERE CustomerID = 10
    SELECT * FROM [SalesLT].[Customer] WHERE CustomerID = 10
    ```

    ![The customer's last name was changed to Smith.](media/customer-record-updated.png "Customer record updated")

### Task 6: Re-run mapping data flow

1. Switch back to Synapse Studio.

2. Navigate to the **Integrate** hub.

    ![Integrate hub.](media/integrate-hub.png "Integrate hub")

3. Select the **RunUpdateCustomerDimension** pipeline.

    ![The pipeline is selected.](media/select-pipeline.png "Pipeline selected")

4. Select **Add trigger** above the pipeline canvas, then select **Trigger now**.

    ![The add trigger button and trigger now menu item are both highlighted.](media/pipeline-trigger.png "Pipeline trigger")

5. Select **OK** in the `Pipeline run` dialog to trigger the pipeline.

    ![The OK button is highlighted.](media/pipeline-run.png "Pipeline run")

6. Navigate to the **Monitor** hub.

    ![Monitor hub.](media/monitor-hub.png "Monitor hub")

7. Select **Pipeline runs** in the left-hand menu **(1)** and wait for the pipeline run to successfully complete **(2)**. You may have to select **Refresh (3)** several times until the pipeline run completes.

    ![The pipeline run successfully completed.](media/pipeline-runs2.png "Pipeline runs")

### Task 7: Verify record updated

1. Navigate to the **Data** hub.

    ![Data hub.](media/data-hub.png "Data hub")

2. Select the **Workspace** tab **(1)**, expand Databases, then right-click on **SQLPool01 (2)**. Select **New SQL script (3)**, then select **Empty script (4)**.

    ![The data hub is displayed with the context menus to create a new SQL script.](media/new-sql-script.png "New SQL script")

3. Paste the following in the query window, then select **Run** or hit F5 to execute the script and view the results:

    ```sql
    SELECT * FROM DimCustomer WHERE CustomerID = 10
    ```

    ![The script is displayed with the updated customer table output.](media/second-customer-script-run.png "Updated customer output")

    As we can see, the customer record successfully updated to modify the `LastName` value to match the source record.

## Exercise 6: Cleanup

Complete these steps to free up resources you no longer need.

### Task 1: Pause the dedicated SQL pool

1. Open Synapse Studio (<https://web.azuresynapse.net/>).

2. Select the **Manage** hub.

    ![The manage hub is highlighted.](media/manage-hub.png "Manage hub")

3. Select **SQL pools** in the left-hand menu **(1)**. Hover over the name of the dedicated SQL pool and select **Pause (2)**.

    ![The pause button is highlighted on the dedicated SQL pool.](media/pause-dedicated-sql-pool.png "Pause")

4. When prompted, select **Pause**.

    ![The pause button is highlighted.](media/pause-dedicated-sql-pool-confirm.png "Pause")
