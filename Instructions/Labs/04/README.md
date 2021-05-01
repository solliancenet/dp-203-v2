# Module 4 - Run interactive queries using serverless SQL pools

In this module, students will learn how to work with files stored in the data lake and external file sources, through T-SQL statements executed by a serverless SQL pool in Azure Synapse Analytics. Students will query Parquet files stored in a data lake, as well as CSV files stored in an external data store. Next, they will create Azure Active Directory security groups and enforce access to files in the data lake through Role-Based Access Control (RBAC) and Access Control Lists (ACLs).

In this module, the student will be able to:

- Query Parquet data with serverless SQL pools
- Create external tables for Parquet and CSV files
- Create views with serverless SQL pools
- Secure access to data in a data lake when using serverless SQL pools
- Configure data lake security using Role-Based Access Control (RBAC) and Access Control Lists (ACLs)

## Lab details

- [Module 4 - Run interactive queries using serverless SQL pools](#module-4---run-interactive-queries-using-serverless-sql-pools)
  - [Lab details](#lab-details)
  - [Lab setup and pre-requisites](#lab-setup-and-pre-requisites)
  - [Exercise 1: Querying a Data Lake Store using serverless SQL pools in Azure Synapse Analytics](#exercise-1-querying-a-data-lake-store-using-serverless-sql-pools-in-azure-synapse-analytics)
    - [Task 1: Query sales Parquet data with serverless SQL pools](#task-1-query-sales-parquet-data-with-serverless-sql-pools)
    - [Task 2: Create an external table for 2019 sales data](#task-2-create-an-external-table-for-2019-sales-data)
    - [Task 3: Create an external table for CSV files](#task-3-create-an-external-table-for-csv-files)
    - [Task 4: Create a view with a serverless SQL pool](#task-4-create-a-view-with-a-serverless-sql-pool)
  - [Exercise 2: Securing access to data through using a serverless SQL pool in Azure Synapse Analytics](#exercise-2-securing-access-to-data-through-using-a-serverless-sql-pool-in-azure-synapse-analytics)
    - [Task 1: Create Azure Active Directory security groups](#task-1-create-azure-active-directory-security-groups)
    - [Task 2: Add group members](#task-2-add-group-members)
    - [Task 3: Configure data lake security - Role-Based Access Control (RBAC)](#task-3-configure-data-lake-security---role-based-access-control-rbac)
    - [Task 4: Configure data lake security - Access Control Lists (ACLs)](#task-4-configure-data-lake-security---access-control-lists-acls)
    - [Task 5: Test permissions](#task-5-test-permissions)

Tailwind Trader's Data Engineers want a way to explore the data lake, transform and prepare data, and simplify their data transformation pipelines. In addition, they want their Data Analysts to explore data in the lake and Spark external tables created by Data Scientists or Data Engineers, using familiar T-SQL language or their favorite tools, which can connect to SQL endpoints.

## Lab setup and pre-requisites

> **Note:** Only complete the `Lab setup and pre-requisites` steps if you are **not** using a hosted lab environment, and are instead using your own Azure subscription. Otherwise, skip ahead to Exercise 1.

You must have permissions to create new Azure Active Directory security groups and assign members to them.

**Complete the [lab setup instructions](https://github.com/solliancenet/microsoft-data-engineering-ilt-deploy/blob/main/setup/04/README.md)** for this module.

Note, the following modules share this same environment:

- [Module 4](labs/04/README.md)
- [Module 5](labs/05/README.md)
- [Module 7](labs/07/README.md)
- [Module 8](labs/08/README.md)
- [Module 9](labs/09/README.md)
- [Module 10](labs/10/README.md)
- [Module 11](labs/11/README.md)
- [Module 12](labs/12/README.md)
- [Module 13](labs/13/README.md)
- [Module 16](labs/16/README.md)

## Exercise 1: Querying a Data Lake Store using serverless SQL pools in Azure Synapse Analytics

Understanding data through data exploration is one of the core challenges faced today by data engineers and data scientists as well. Depending on the underlying structure of the data as well as the specific requirements of the exploration process, different data processing engines will offer varying degrees of performance, complexity, and flexibility.

In Azure Synapse Analytics, you can use either SQL, Apache Spark for Synapse, or both. Which service you use mostly depends on your personal preference and expertise. When conducting data engineering tasks, both options can be equally valid in many cases. However, there are certain situations where harnessing the power of Apache Spark can help you overcome problems with the source data. This is because in a Synapse Notebook, you can import from a large number of free libraries that add functionality to your environment when working with data. There are other situations where it is much more convenient and faster using serveless SQL pool to explore the data, or to expose data in the data lake through a SQL view that can be accessed from external tools, like Power BI.

In this exercise, you will explore the data lake using both options.

### Task 1: Query sales Parquet data with serverless SQL pools

When you query Parquet files using serverless SQL pools, you can explore the data with T-SQL syntax.

1. Open Synapse Studio (<https://web.azuresynapse.net/>), and then navigate to the **Data** hub.

    ![The Data menu item is highlighted.](media/data-hub.png "Data hub")

2. Select the **Linked** tab **(1)** and expand **Azure Data Lake Storage Gen2**. Expand the `asaworkspaceXX` primary ADLS Gen2 account **(2)** and select the **`wwi-02`** container **(3)**. Navigate to the `sale-small/Year=2016/Quarter=Q4/Month=12/Day=20161231` folder **(4)**. Right-click on the `sale-small-20161231-snappy.parquet` file **(5)**, select **New SQL script (6)**, then **Select TOP 100 rows (7)**.

    ![The Data hub is displayed with the options highlighted.](media/data-hub-parquet-select-rows.png "Select TOP 100 rows")

3. Ensure **Built-in** is selected **(1)** in the `Connect to` dropdown list above the query window, then run the query **(2)**. Data is loaded by the serverless SQL endpoint and processed as if was coming from any regular relational database.

    ![The Built-in connection is highlighted.](media/built-in-selected.png "SQL Built-in")

    The cell output shows the query results from the Parquet file.

    ![The cell output is displayed.](media/sql-on-demand-output.png "SQL output")

4. Modify the SQL query to perform aggregates and grouping operations to better understand the data. Replace the query with the following, making sure that the file path in `OPENROWSET` matches the current file path:

    ```sql
    SELECT
        TransactionDate, ProductId,
            CAST(SUM(ProfitAmount) AS decimal(18,2)) AS [(sum) Profit],
            CAST(AVG(ProfitAmount) AS decimal(18,2)) AS [(avg) Profit],
            SUM(Quantity) AS [(sum) Quantity]
    FROM
        OPENROWSET(
            BULK 'https://asadatalakeSUFFIX.dfs.core.windows.net/wwi-02/sale-small/Year=2016/Quarter=Q4/Month=12/Day=20161231/sale-small-20161231-snappy.parquet',
            FORMAT='PARQUET'
        ) AS [r] GROUP BY r.TransactionDate, r.ProductId;
    ```

    ![The T-SQL query above is displayed within the query window.](media/sql-serverless-aggregates.png "Query window")

5. Let's move on from this single file from 2016 and transition to a newer data set. We want to figure out how many records are contained within the Parquet files for all 2019 data. This information is important for planning how we optimize for importing the data into Azure Synapse Analytics. To do this, we'll replace the query with the following (be sure to update the name of your data lake in the BULK statement, by replacing `[asadatalakeSUFFIX]`):

    ```sql
    SELECT
        COUNT(*)
    FROM
        OPENROWSET(
            BULK 'https://asadatalakeSUFFIX.dfs.core.windows.net/wwi-02/sale-small/Year=2019/*/*/*/*',
            FORMAT='PARQUET'
        ) AS [r];
    ```

    > Notice how we updated the path to include all Parquet files in all subfolders of `sale-small/Year=2019`.

    The output should be **339507246** records.

### Task 2: Create an external table for 2019 sales data

Rather than creating a script with `OPENROWSET` and a path to the root 2019 folder every time we want to query the Parquet files, we can create an external table.

1. In Synapse Studio, navigate to the **Data** hub.

    ![The Data menu item is highlighted.](media/data-hub.png "Data hub")

2. Select the **Linked** tab **(1)** and expand **Azure Data Lake Storage Gen2**. Expand the `asaworkspaceXX` primary ADLS Gen2 account **(2)** and select the **`wwi-02`** container **(3)**. Navigate to the `sale-small/Year=2019/Quarter=Q1/Month=1/Day=20190101` folder **(4)**. Right-click on the `sale-small-20190101-snappy.parquet` file **(5)**, select **New SQL script (6)**, then **Create external table (7)**.

    ![The create external link is highlighted.](media/create-external-table.png "Create external table")

3. Make sure **`Built-in`** is selected for the **SQL pool (1)**. Under **Select a database**, select **+ New** and enter `demo` **(2)**. For **External table name**, enter `All2019Sales` **(3)**. Under **Create external table**, select **Using SQL script (4)**, then select **Create (5)**.

    ![The create external table form is displayed.](media/create-external-table-form.png "Create external table")

    > **Note**: Make sure the script is connected to the serverless SQL pool (`Built-in`) **(1)** and the database is set to `demo` **(2)**.

    ![The Built-in pool and demo database are selected.](media/built-in-and-demo.png "Script toolbar")

    The generated script contains the following components:

    - **1)** The script begins with creating the `SynapseParquetFormat` external file format with a `FORMAT_TYPE` of `PARQUET`.
    - **2)** Next, the external data source is created, pointing to the `wwi-02` container of the data lake storage account.
    - **3)** The CREATE EXTERNAL TABLE `WITH` statement specifies the file location and refers to the new external file format and data source created above.
    - **4)** Finally, we select the top 100 results from the `2019Sales` external table.

    ![The SQL script is displayed.](media/create-external-table-script.png "Create external table script")

4. Replace the `LOCATION` value in the `CREATE EXTERNAL TABLE` statement with **`sale-small/Year=2019/*/*/*/*.parquet`**.

    ![The Location value is highlighted.](media/create-external-table-location.png "Create external table")

5. **Run** the script.

    ![The Run button is highlighted.](media/create-external-table-run.png "Run")

    After running the script, we can see the output of the SELECT query against the `All2019Sales` external table. This displays the first 100 records from the Parquet files located in the `YEAR=2019` folder.

    ![The query output is displayed.](media/create-external-table-output.png "Query output")

### Task 3: Create an external table for CSV files

Tailwind Traders found an open data source for country population data that they want to use. They do not want to merely copy the data since it is regularly updated with projected populations in future years.

You decide to create an external table that connects to the external data source.

1. Replace the SQL script with the following:

    ```sql
    IF NOT EXISTS (SELECT * FROM sys.symmetric_keys) BEGIN
        declare @pasword nvarchar(400) = CAST(newid() as VARCHAR(400));
        EXEC('CREATE MASTER KEY ENCRYPTION BY PASSWORD = ''' + @pasword + '''')
    END

    CREATE DATABASE SCOPED CREDENTIAL [sqlondemand]
    WITH IDENTITY='SHARED ACCESS SIGNATURE',  
    SECRET = 'sv=2018-03-28&ss=bf&srt=sco&sp=rl&st=2019-10-14T12%3A10%3A25Z&se=2061-12-31T12%3A10%3A00Z&sig=KlSU2ullCscyTS0An0nozEpo4tO5JAgGBvw%2FJX2lguw%3D'
    GO

    -- Create external data source secured using credential
    CREATE EXTERNAL DATA SOURCE SqlOnDemandDemo WITH (
        LOCATION = 'https://sqlondemandstorage.blob.core.windows.net',
        CREDENTIAL = sqlondemand
    );
    GO

    CREATE EXTERNAL FILE FORMAT QuotedCsvWithHeader
    WITH (  
        FORMAT_TYPE = DELIMITEDTEXT,
        FORMAT_OPTIONS (
            FIELD_TERMINATOR = ',',
            STRING_DELIMITER = '"',
            FIRST_ROW = 2
        )
    );
    GO

    CREATE EXTERNAL TABLE [population]
    (
        [country_code] VARCHAR (5) COLLATE Latin1_General_BIN2,
        [country_name] VARCHAR (100) COLLATE Latin1_General_BIN2,
        [year] smallint,
        [population] bigint
    )
    WITH (
        LOCATION = 'csv/population/population.csv',
        DATA_SOURCE = SqlOnDemandDemo,
        FILE_FORMAT = QuotedCsvWithHeader
    );
    GO
    ```

    At the top of the script, we create a `MASTER KEY` with a random password **(1)**. Next, we create a database-scoped credential for the containers in the external storage account **(2)**, using a shared access signature (SAS) for delegated access. This credential is used when we create the `SqlOnDemandDemo` external data source **(3)** that points to the location of the external storage account that contains the population data:

    ![The script is displayed.](media/script1.png "Create master key and credential")

    > Database-scoped credentials are used when any principal calls the OPENROWSET function with a DATA_SOURCE or selects data from an external table that doesn't access public files. The database scoped credential doesn't need to match the name of storage account because it will be explicitly used in the DATA SOURCE that defines the storage location.

    In the next part of the script, we create an external file format called `QuotedCsvWithHeader`. Creating an external file format is a prerequisite for creating an External Table. By creating an External File Format, you specify the actual layout of the data referenced by an external table. Here we specify the CSV field terminator, string delimiter, and set the `FIRST_ROW` value to 2 since the file contains a header row:

    ![The script is displayed.](media/script2.png "Create external file format")

    Finally, at the bottom of the script, we create an external table named `population`. The `WITH` clause specifies the relative location of the CSV file, points to the data source created above, as well as the `QuotedCsvWithHeader` file format:

    ![The script is displayed.](media/script3.png "Create external table")

2. **Run** the script.

    ![The run button is highlighted.](media/sql-run.png "Run")

    Please note that there are no data results for this query.

3. Replace the SQL script with the following to select from the population external table, filtered by 2019 data where the population is greater than 100 million:

    ```sql
    SELECT [country_code]
        ,[country_name]
        ,[year]
        ,[population]
    FROM [dbo].[population]
    WHERE [year] = 2019 and population > 100000000
    ```

4. **Run** the script.

    ![The run button is highlighted.](media/sql-run.png "Run")

5. In the query results, select the **Chart** view, then configure it as follows:

    - **Chart type**: Select `Bar`.
    - **Category column**: Select `country_name`.
    - **Legend (series) columns**: Select `population`.
    - **Legend position**: Select `center - bottom`.

    ![The chart is displayed.](media/population-chart.png "Population chart")

### Task 4: Create a view with a serverless SQL pool

Let's create a view to wrap a SQL query. Views allow you to reuse queries and are needed if you want to use tools, such as Power BI, in conjunction with serverless SQL pools.

1. In Synapse Studio, navigate to the **Data** hub.

    ![The Data menu item is highlighted.](media/data-hub.png "Data hub")

2. Select the **Linked** tab **(1)** and expand **Azure Data Lake Storage Gen2**. Expand the `asaworkspaceXX` primary ADLS Gen2 account **(2)** and select the **`wwi-02`** container **(3)**. Navigate to the `customer-info` folder **(4)**. Right-click on the `customerinfo.csv` file **(5)**, select **New SQL script (6)**, then **Select TOP 100 rows (7)**.

    ![The Data hub is displayed with the options highlighted.](media/customerinfo-select-rows.png "Select TOP 100 rows")

3. Select **Run** to execute the script **(1)**. Notice that the first row of the CSV file is the column header row **(2)**.

    ![The CSV results are displayed.](media/select-customerinfo.png "customerinfo.csv file")

4. Update the script with the following and **make sure you replace YOUR_DATALAKE_NAME (1)** (your primary data lake storage account) in the OPENROWSET BULK path with the value in the in the previous select statement. Set the **Use database** value to **`demo` (2)** (use the refresh button to the right if needed):

    ```sql
    CREATE VIEW CustomerInfo AS
        SELECT * 
    FROM OPENROWSET(
            BULK 'https://YOUR_DATALAKE_NAME.dfs.core.windows.net/wwi-02/customer-info/customerinfo.csv',
            FORMAT = 'CSV',
            PARSER_VERSION='2.0',
            FIRSTROW=2
        )
    WITH (
        [UserName] VARCHAR (50),
        [Gender] VARCHAR (10),
        [Phone] VARCHAR (50),
        [Email] VARCHAR (100),
        [CreditCard] VARCHAR (50)
    ) AS [r];
    GO

    SELECT * FROM CustomerInfo;
    GO
    ```

    ![The script is displayed.](media/create-view-script.png "Create view script")

5. Select **Run** to execute the script.

    ![The run button is highlighted.](media/sql-run.png "Run")

    We just created the view to wrap the SQL query that selects data from the CSV file, then selected rows from the view:

    ![The query results are displayed.](media/create-view-script-results.png "Query results")

    Notice that the first row no longer contains the column headers. This is because we used the `FIRSTROW=2` setting in the `OPENROWSET` statement when we created the view.

6. Within the **Data** hub, select the **Workspace** tab **(1)**. Select the actions ellipses **(...)** to the right of the Databases group **(2)**, then select **Refresh (3)**.

    ![The refresh button is highlighted.](media/refresh-databases.png "Refresh databases")

7. Expand the `demo` SQL database.

    ![The demo database is displayed.](media/demo-database.png "Demo database")

    The database contains the following objects that we created in our earlier steps:

    - **1) External tables**: `All2019Sales` and `population`.
    - **2) External data sources**: `SqlOnDemandDemo` and `wwi-02_asadatalakeinadayXXX_dfs_core_windows_net`.
    - **3) External file formats**: `QuotedCsvWithHeader` and `SynapseParquetFormat`.
    - **4) Views**: `CustomerInfo`. 

## Exercise 2: Securing access to data through using a serverless SQL pool in Azure Synapse Analytics

Tailwind Traders wants to enforce that any kind of modifications to sales data can happen in the current year only, while allowing all authorized users to query the entirety of data. They have a small group of admins who can modify historic data if needed.

- Tailwind Traders should create a security group in AAD, for example called `tailwind-history-owners`, with the intent that all users who belong to this group will have permissions to modify data from previous years.
- The `tailwind-history-owners` security group needs to be assigned to the Azure Storage built-in RBAC role `Storage Blob Data Owner` for the Azure Storage account containing the data lake. This allows AAD user and service principals that are added to this role to have the ability to modify all data from previous years.
- They need to add the user security principals who will have have permissions to modify all historical data to the `tailwind-history-owners` security group.
- Tailwind Traders should create another security group in AAD, for example called `tailwind-readers`, with the intent that all users who belong to this group will have permissions to read all contents of the file system (`prod` in this case), including all historical data.
- The `tailwind-readers` security group needs to be assigned to the Azure Storage built-in RBAC role `Storage Blob Data Reader` for the Azure Storage account containing the data lake. This allows AAD user and service principals that are added to this security group to have the ability to read all data in the file system, but not to modify it.
- Tailwind Traders should create another security group in AAD, for example called `tailwind-2020-writers`, with the intent that all users who belong to this group will have permissions to modify data only from the year 2020.
- They would create a another security group, for example called `tailwind-current-writers`, with the intent that only security groups would be added to this group. This group will have permissions to modify data only from the current year, set using ACLs.
- They need to add the `tailwind-readers` security group to the `tailwind-current-writers` security group.
- At the start of the year 2020, Tailwind Traders would add `tailwind-current-writers` to the `tailwind-2020-writers` security group.
- At the start of the year 2020, on the `2020` folder, Tailwind Traders would set the read, write and execute ACL permissions for the `tailwind-2020-writers` security group.
- At the start of the year 2021, to revoke write access to the 2020 data they would remove the `tailwind-current-writers` security group from the `tailwind-2020-writers` group. Members of `tailwind-readers` would continue to be able to read the contents of the file system because they have been granted read and execute (list) permissions not by the ACLs but by the RBAC built in role at the level of the file system.
- This approach takes into account that current changes to ACLs do not inherit permissions, so removing the write permission would require writing code that traverses all of its content removing the permission at each folder and file object.
- This approach is relatively fast. RBAC role assignments may take up to five minutes to propagate, regardless of the volume of data being secured.

### Task 1: Create Azure Active Directory security groups

In this segment, we will create security groups as described above. However, our data set ends in 2019, so we will create a `tailwind-2019-writers` group instead of 2021.

1. Switch back to the Azure portal (<https://portal.azure.com>) in a different browser tab, leaving Synapse Studio open.

2. Select the Azure menu **(1)**, then select **Azure Active Directory (2)**.

    ![The menu item is highlighted.](media/azure-ad-menu.png "Azure Active Directory")

3. Select **Groups** in the left-hand menu.

    ![Groups is highlighted.](media/aad-groups-link.png "Azure Active Directory")

4. Select **+ New group**.

    ![New group button.](media/new-group.png "New group")

5. Select `Security` from **Group type**. Enter `tailwind-history-owners-<suffix>` (where `<suffix>` is a unique value, such as your initials followed by two or more numbers) for the **Group name**, then select **Create**.

    ![The form is configured as described.](media/new-group-history-owners.png "New Group")

6. Select **+ New group**.

    ![New group button.](media/new-group.png "New group")

7. Select `Security` from **Group type**. Enter `tailwind-readers-<suffix>` (where `<suffix>` is a unique value, such as your initials followed by two or more numbers) for the **Group name**, then select **Create**.

    ![The form is configured as described.](media/new-group-readers.png "New Group")

8. Select **+ New group**.

    ![New group button.](media/new-group.png "New group")

9. Select `Security` from **Group type**. Enter `tailwind-current-writers-<suffix>` (where `<suffix>` is a unique value, such as your initials followed by two or more numbers) for the **Group name**, then select **Create**.

    ![The form is configured as described.](media/new-group-current-writers.png "New Group")

10. Select **+ New group**.

    ![New group button.](media/new-group.png "New group")

11. Select `Security` from **Group type**. Enter `tailwind-2019-writers-<suffix>` (where `<suffix>` is a unique value, such as your initials followed by two or more numbers) for the **Group name**, then select **Create**.

    ![The form is configured as described.](media/new-group-2019-writers.png "New Group")

### Task 2: Add group members

To test out the permissions, we will add our own account to the `tailwind-readers-<suffix>` group.

1. Open the newly created **`tailwind-readers-<suffix>`** group.

2. Select **Members (1)** on the left, then select **+ Add members (2)**.

    ![The group is displayed and add members is highlighted.](media/tailwind-readers.png "tailwind-readers group")

3. Add your user account that you are signed into for the lab, then select **Select**.

    ![The form is displayed.](media/add-members.png "Add members")

4. Open the **`tailwind-2019-writers-<suffix>`** group.

5. Select **Members (1)** on the left, then select **+ Add members (2)**.

    ![The group is displayed and add members is highlighted.](media/tailwind-2019-writers.png "tailwind-2019-writers group")

6. Search for `tailwind`, select the **`tailwind-current-writers-<suffix>`** group, then select **Select**.

    ![The form is displayed as described.](media/add-members-writers.png "Add members")

7. Select **Overview** in the left-hand menu, then **copy** the **Object Id**.

    ![The group is displayed and the Object Id is highlighted.](media/tailwind-2019-writers-overview.png "tailwind-2019-writers group")

    > **Note**: Save the **Object Id** value to Notepad or similar text editor. This will be used in a later step when you assign access control in the storage account.

### Task 3: Configure data lake security - Role-Based Access Control (RBAC)

1. Open the Azure resource group for this lab, which contains the Synapse Analytics workspace.

2. Open the default data lake storage account.

    ![The storage account is selected.](media/resource-group-storage-account.png "Resource group")

3. Select **Access Control (IAM)** in the left-hand menu.

    ![Access Control is selected.](media/storage-access-control.png "Access Control")

4. Select the **Role assignments** tab.

    ![Role assignments is selected.](media/role-assignments-tab.png "Role assignments")

5. Select **+ Add**, then **Add role assignment**.

    ![Add role assignment is highlighted.](media/add-role-assignment.png "Add role assignment")

6. For **Role**, select **`Storage Blob Data Reader`**. Search for **`tailwind-readers`** and select `tailwind-readers-<suffix>` from the results, then select **Save**.

    ![The form is displayed as described.](media/add-tailwind-readers.png "Add role assignment")

    Since our user account is added to this group, we will have read access to all files in the blob containers of this account. Tailwind Traders will need to add all users to the `tailwind-readers-<suffix>` security group.

7. Select **+ Add**, then **Add role assignment**.

    ![Add role assignment is highlighted.](media/add-role-assignment.png "Add role assignment")

8. For **Role**, select **`Storage Blob Data Owner`**. Search for **`tailwind`** and select **`tailwind-history-owners-<suffix>`** from the results, then select **Save**.

    ![The form is displayed as described.](media/add-tailwind-history-owners.png "Add role assignment")

    The `tailwind-history-owners-<suffix>` security group is now assigned to the Azure Storage built-in RBAC role `Storage Blob Data Owner` for the Azure Storage account containing the data lake. This allows Azure AD user and service principals that are added to this role to have the ability to modify all data.

    Tailwind Traders needs to add the user security principals who will have have permissions to modify all historical data to the `tailwind-history-owners-<suffix>` security group.

9. In the **Access Control (IAM)** list for the storage account, select your Azure user account under the **Storage Blob Data Owner** role **(1)**, then select **Remove (2)**.

    ![The Access Control settings are displayed.](media/storage-access-control-updated.png "Access Control updated")

    Notice that the `tailwind-history-owners-<suffix>` group is assigned to the **Storage Blob Data Owner** group **(3)**, and `tailwind-readers-<suffix>` is assigned to the **Storage Blob Data Reader** group **(4)**.

    > **Note**: You may need to navigate back to the resource group, then come back to this screen to see all of the new role assignments.

### Task 4: Configure data lake security - Access Control Lists (ACLs)

1. Select **Storage Explorer (preview)** on the left-hand menu **(1)**. Expand CONTAINERS and select the **wwi-02** container **(2)**. Open the **sale-small** folder **(3)**, right-click on the **Year=2019** folder **(4)**, then select **Manage Access.. (5)**.

    ![The 2019 folder is highlighted and Manage Access is selected.](media/manage-access-2019.png "Storage Explorer")

2. Paste the **Object Id** value you copied from the **`tailwind-2019-writers-<suffix>`** security group into the **Add user, group, or service principal** text box, then select **Add**.

    ![The Object Id value is pasted in the field.](media/manage-access-2019-object-id.png "Manage Access")

3. Now you should see that the `tailwind-2019-writers-<suffix>` group is selected in the Manage Access dialog **(1)**. Check the **Access** and **Default** check boxes and the **Read**, **Write**, and **Execute** checkboxes for each **(2)**, then select **Save**.

    ![The permissions are configured as described.](media/manage-access-2019-permissions.png "Manage Access")

    Now the security ACLs have been set to allow any users added to the `tailwind-current-<suffix>` security group to write to the `Year=2019` folder, by way of the `tailwind-2019-writers-<suffix>` group. These users can only manage current (2019 in this case) sales files.

    At the start of the following year, to revoke write access to the 2019 data they would remove the `tailwind-current-writers-<suffix>` security group from the `tailwind-2019-writers-<suffix>` group. Members of `tailwind-readers-<suffix>` would continue to be able to read the contents of the file system because they have been granted read and execute (list) permissions not by the ACLs but by the RBAC built in role at the level of the file system.

    Notice that we configured both the _access_ ACLs and _default_ ACLs in this configuration.

    *Access* ACLs control access to an object. Files and directories both have access ACLs.

    *Default* ACLs are templates of ACLs associated with a directory that determine the access ACLs for any child items that are created under that directory. Files do not have default ACLs.

    Both access ACLs and default ACLs have the same structure.

### Task 5: Test permissions

1. In Synapse Studio, navigate to the **Data** hub.

    ![The Data menu item is highlighted.](media/data-hub.png "Data hub")

2. Select the **Linked** tab **(1)** and expand **Azure Data Lake Storage Gen2**. Expand the `asaworkspaceXX` primary ADLS Gen2 account **(2)** and select the **`wwi-02`** container **(3)**. Navigate to the `sale-small/Year=2016/Quarter=Q4/Month=12/Day=20161231` folder **(4)**. Right-click on the `sale-small-20161231-snappy.parquet` file **(5)**, select **New SQL script (6)**, then **Select TOP 100 rows (7)**.

    ![The Data hub is displayed with the options highlighted.](media/data-hub-parquet-select-rows.png "Select TOP 100 rows")

3. Ensure **Built-in** is selected **(1)** in the `Connect to` dropdown list above the query window, then run the query **(2)**. Data is loaded by the serverless SQL pool endpoint and processed as if was coming from any regular relational database.

    ![The Built-in connection is highlighted.](media/built-in-selected.png "Built-in SQL pool")

    The cell output shows the query results from the Parquet file.

    ![The cell output is displayed.](media/sql-on-demand-output.png "SQL output")

    The read permissions to the Parquet file assigned to us through the `tailwind-readers-<suffix>` security group, which then is granted RBAC permissions on the storage account through the **Storage Blob Data Reader** role assignment, is what enabled us to view the file contents.

    However, since we removed our account from the **Storage Blob Data Owner** role, and we did not add our account to the `tailwind-history-owners-<suffix>` security group, what if we try to write to this directory?

    Let's give it a try.

4. In the **Data** hub, once again select the **Linked** tab **(1)** and expand **Azure Data Lake Storage Gen2**. Expand the `asaworkspaceXX` primary ADLS Gen2 account **(2)** and select the **`wwi-02`** container **(3)**. Navigate to the `sale-small/Year=2016/Quarter=Q4/Month=12/Day=20161231` folder **(4)**. Right-click on the `sale-small-20161231-snappy.parquet` file **(5)**, select **New Notebook (6)**, then select **Load to DataFrame (7)**.

    ![The Data hub is displayed with the options highlighted.](media/data-hub-parquet-new-notebook.png "New notebook")

5. Attach your Spark pool to the notebook.

    ![The Spark pool is highlighted.](media/notebook-attach-spark-pool.png "Attach Spark pool")

6. In the notebook, select **+**, then **</> Code cell** underneath Cell 1 to add a new code cell.

    ![The new code cell button is highlighted.](media/new-code-cell.png "New code cell")

7. Enter the following in the new cell, then **copy the Parquet path from cell 1** and paste the value to replace `REPLACE_WITH_PATH` **(1)**. Rename the Parquet file by adding `-test` to the end of the file name **(2)**:

    ```python
    df.write.parquet('REPLACE_WITH_PATH')
    ```

    ![The notebook is displayed with the new cell.](media/new-cell.png "New cell")

8. Select **Run all** in the toolbar to run both cells. After a few minutes when the Spark pool starts and the cells run, you should see the file data in the output from cell 1 **(1)**. However, you should see a **403 error** in the output of cell 2 **(2)**.

    ![The error is displayed in Cell 2's output.](media/notebook-error.png "Notebook error")

    As expected, we do not have write permissions. The error returned by cell 2 is, `This request is not authorized to perform this operation using this permission.`, with a status code of 403.

9. Leave the notebook open and switch back to the Azure portal (<https://portal.azure.com>) in another tab.

10. Select the Azure menu **(1)**, then select **Azure Active Directory (2)**.

    ![The menu item is highlighted.](media/azure-ad-menu.png "Azure Active Directory")

11. Select **Groups** in the left-hand menu.

    ![Groups is highlighted.](media/aad-groups-link.png "Azure Active Directory")

12. Type **`tailwind`** in the search box **(1)**, then select **`tailwind-history-owners-<suffix>`** in the results **(2)**.

    ![The tailwind groups are displayed.](media/tailwind-groups.png "All groups")

13. Select **Members (1)** on the left, then select **+ Add members (2)**.

    ![The group is displayed and add members is highlighted.](media/tailwind-history-owners.png "tailwind-history-owners group")

14. Add your user account that you are signed into for the lab, then select **Select**.

    ![The form is displayed.](media/add-members.png "Add members")

15. Switch back to the open Synapse Notebook in Synapse Studio, then **Run** cell 2 once more **(1)**. You should see a status of **Succeeded (2)** after a few moments.

    ![Cell 2 succeeded.](media/notebook-succeeded.png "Notebook")

    The cell succeeded this time because we added our account to the `tailwind-history-owners-<suffix>` group, which is assigned the **Storage Blob Data Owner** role.

    > **Note**: If you encounter the same error this time, **stop the Spark session** on the notebook, then select **Publish all**, then Publish. After publishing your changes, select your user profile on the top-right corner of the page and **log out**. **Close the browser tab** after logout is successful, then re-launch Synapse Studio (<https://web.azuresynapse.net/>), re-open the notebook, then re-run the cell. This may be needed because you must refresh the security token for the auth changes to take place.

    Now let's verify that the file was written to the data lake.

16. Navigate back to the `sale-small/Year=2016/Quarter=Q4/Month=12/Day=20161231` folder. You should now see a folder for the new `sale-small-20161231-snappy-test.parquet` file we wrote from the notebook **(1)**. If you don't see it listed here, select **... More** in the toolbar **(2)**, then select **Refresh (3)**.

    ![The test Parquet file is displayed.](media/test-parquet-file.png "Test parquet file")
