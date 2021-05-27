# Module 6 - Data exploration and transformation in Azure Databricks

This module teaches how to use various Apache Spark DataFrame methods to explore and transform data in Azure Databricks. The student will learn how to perform standard DataFrame methods to explore and transform data. They will also learn how to perform more advanced tasks, such as removing duplicate data, manipulate date/time values, rename columns, and aggregate data.

In this module the student will be able to:

- Use DataFrames in Azure Databricks to explore and filter data
- Cache a DataFrame for faster subsequent queries
- Remove duplicate data
- Manipulate date/time values
- Remove and rename DataFrame columns
- Aggregate data stored in a DataFrame

## Lab details

- [Module 6 - Data exploration and transformation in Azure Databricks](#module-6---data-exploration-and-transformation-in-azure-databricks)
  - [Lab details](#lab-details)
  - [Lab 1 - Working with DataFrames](#lab-1---working-with-dataframes)
    - [Before the hands-on lab](#before-the-hands-on-lab)
      - [Task 1 - Create and configure the Azure Databricks workspace](#task-1---create-and-configure-the-azure-databricks-workspace)
    - [Exercise 1: Complete the lab notebook](#exercise-1-complete-the-lab-notebook)
      - [Task 1: Clone the Databricks archive](#task-1-clone-the-databricks-archive)
      - [Task 2: Complete the Describe a DataFrame notebook](#task-2-complete-the-describe-a-dataframe-notebook)
    - [Exercise 2: Complete the Working with DataFrames notebook](#exercise-2-complete-the-working-with-dataframes-notebook)
    - [Exercise 3: Complete the Display Function notebook](#exercise-3-complete-the-display-function-notebook)
    - [Exercise 4: Complete the Distinct Articles exercise notebook](#exercise-4-complete-the-distinct-articles-exercise-notebook)
  - [Lab 2 - Working with DataFrames advanced methods](#lab-2---working-with-dataframes-advanced-methods)
    - [Exercise 1: Run and complete the lab notebook](#exercise-1-run-and-complete-the-lab-notebook)
      - [Task 1: Clone the Databricks archive](#task-1-clone-the-databricks-archive-1)
      - [Task 2: Complete the Date and Time Manipulation notebook](#task-2-complete-the-date-and-time-manipulation-notebook)
    - [Exercise 2: Complete the Use Aggregate Functions notebook](#exercise-2-complete-the-use-aggregate-functions-notebook)
    - [Exercise 3: Complete the De-Duping Data exercise notebook](#exercise-3-complete-the-de-duping-data-exercise-notebook)

## Lab 1 - Working with DataFrames

Your data processing in Azure Databricks is accomplished by defining DataFrames to read and process the Data. This lab will introduce how to read your data using Azure Databricks DataFrames. You need to complete the exercises within Databricks Notebooks. To begin, you need to have access to an Azure Databricks workspace. If you do not have a workspace available, follow the instructions below. Otherwise, you can skip ahead to the `Clone the Databricks archive` step.

### Before the hands-on lab

> **Note:** Only complete the `Before the hands-on lab` steps if you are **not** using a hosted lab environment, and are instead using your own Azure subscription. Otherwise, skip ahead to Exercise 1.

Before stepping through the exercises in this lab, make sure you have access to an Azure Databricks workspace with an available cluster. Perform the tasks below to configure the workspace.

#### Task 1 - Create and configure the Azure Databricks workspace

Follow the [lab 06 setup instructions](https://github.com/solliancenet/microsoft-data-engineering-ilt-deploy/blob/main/setup/06/lab-01-setup.md) to create and configure the workspace.

### Exercise 1: Complete the lab notebook

#### Task 1: Clone the Databricks archive

1. If you do not currently have your Azure Databricks workspace open: in the Azure portal, navigate to your deployed Azure Databricks workspace and select **Launch Workspace**.
1. In the left pane, select **Workspace** > **Users**, and select your username (the entry with the house icon).
1. In the pane that appears, select the arrow next to your name, and select **Import**.

    ![The menu option to import the archive](media/import-archive.png)

1. In the **Import Notebooks** dialog box, select the URL and paste in the following URL:

 ```
  https://github.com/solliancenet/microsoft-learning-paths-databricks-notebooks/blob/master/data-engineering/DBC/04-Working-With-Dataframes.dbc?raw=true
 ```

1. Select **Import**.
1. Select the **04-Working-With-Dataframes** folder that appears.

#### Task 2: Complete the Describe a DataFrame notebook

Open the **1.Describe-a-dataframe** notebook. Make sure you attach your cluster to the notebook before following the instructions and running the cells within.

Within the notebook, you will:

- Develop familiarity with the `DataFrame` APIs
- Learn the classes...
  - `SparkSession`
  - `DataFrame` (aka `Dataset[Row]`)
- Learn the action...
  - `count()`

After you've completed the notebook, return to this screen, and continue to the next step.

### Exercise 2: Complete the Working with DataFrames notebook

In your Azure Databricks workspace, open the **04-Working-With-Dataframes** folder that you imported within your user folder.

Open the **2.Use-common-dataframe-methods** notebook. Make sure you attach your cluster to the notebook before following the instructions and running the cells within.

Within the notebook, you will:

- Develop familiarity with the `DataFrame` APIs
- Use common DataFrame methods for performance
- Explore the Spark API documentation

After you've completed the notebook, return to this screen, and continue to the next step.

### Exercise 3: Complete the Display Function notebook

In your Azure Databricks workspace, open the **04-Working-With-Dataframes** folder that you imported within your user folder.

Open the **3.Display-function** notebook. Make sure you attach your cluster to the notebook before following the instructions and running the cells within.

Within the notebook, you will:

- Learn the transformations...
  - `limit(..)`
  - `select(..)`
  - `drop(..)`
  - `distinct()`
  - `dropDuplicates(..)`
- Learn the actions...
  - `show(..)`
  - `display(..)`

After you've completed the notebook, return to this screen, and continue to the next step.

### Exercise 4: Complete the Distinct Articles exercise notebook

In your Azure Databricks workspace, open the **04-Working-With-Dataframes** folder that you imported within your user folder.

Open the **4.Exercise: Distinct Articles** notebook. Make sure you attach your cluster to the notebook before following the instructions and running the cells within.

In this exercise, you read Parquet files, apply necessary transformations, perform a total count of records, then verify that all the data was correctly loaded. As a bonus, try defining a schema that matches the data and update the read operation to use the schema.

> Note: You will find a corresponding notebook within the `Solutions` subfolder. This contains completed cells for the exercise. Refer to the notebook if you get stuck or simply want to see the solution.

After you've completed the notebook, return to this screen, and continue to the next lab.

## Lab 2 - Working with DataFrames advanced methods

This lab builds on the Azure Databricks DataFrames concepts learned in the previous lab above by exploring some advanced methods data engineers can use to read, write, and transform data using DataFrames.

### Exercise 1: Run and complete the lab notebook

#### Task 1: Clone the Databricks archive

1. If you do not currently have your Azure Databricks workspace open: in the Azure portal, navigate to your deployed Azure Databricks workspace and select **Launch Workspace**.
1. In the left pane, select **Workspace** > **Users**, and select your username (the entry with the house icon).
1. In the pane that appears, select the arrow next to your name, and select **Import**.

    ![The menu option to import the archive](media/import-archive.png)

1. In the **Import Notebooks** dialog box, select the URL and paste in the following URL:

 ```
  https://github.com/solliancenet/microsoft-learning-paths-databricks-notebooks/blob/master/data-engineering/DBC/07-Dataframe-Advanced-Methods.dbc?raw=true
 ```

1. Select **Import**.
1. Select the **07-Dataframe-Advanced-Methods** folder that appears.

#### Task 2: Complete the Date and Time Manipulation notebook

Open the **1.DateTime-Manipulation** notebook. Make sure you attach your cluster to the notebook before following the instructions and running the cells within.

Within the notebook, you will:

- Explore more of the `...sql.functions` operations
  - Date & time functions

After you've completed the notebook, return to this screen, and continue to the next step.

### Exercise 2: Complete the Use Aggregate Functions notebook

In your Azure Databricks workspace, open the **07-Dataframe-Advanced-Methods** folder that you imported within your user folder.

Open the **2.Use-Aggregate-Functions** notebook. Make sure you attach your cluster to the notebook before following the instructions and running the cells within.

Within the notebook, you will learn various aggregate functions.

After you've completed the notebook, return to this screen, and continue to the next step.

### Exercise 3: Complete the De-Duping Data exercise notebook

In your Azure Databricks workspace, open the **07-Dataframe-Advanced-Methods** folder that you imported within your user folder.

Open the **3.Exercise-Deduplication-of-Data** notebook. Make sure you attach your cluster to the notebook before following the instructions and running the cells within.

The goal of this exercise is to put into practice some of what you have learned about using DataFrames, including renaming columns. The instructions are provided within the notebook, along with empty cells for you to do your work. At the bottom of the notebook are additional cells that will help verify that your work is accurate.

> Note: You will find a corresponding notebook within the `Solutions` subfolder. This contains completed cells for the exercise. Refer to the notebook if you get stuck or simply want to see the solution.
