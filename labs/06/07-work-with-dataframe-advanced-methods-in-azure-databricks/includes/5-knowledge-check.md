Now that you've completed all the notebooks in Azure Databricks, check your knowledge by answering the following questions.

## quiz title: Knowledge check
## Multiple Choice
Which method for renaming a DataFrame's column is incorrect?
() df.select(col("timestamp").alias("dateCaptured")){{This is a valid renaming method.}}
() df.withColumnRenamed("timestamp", "dateCaptured"){{This is a valid renaming method.}}
(x) df.alias("timestamp", "dateCaptured"){{The DataFrame does not contain an alias method for a column.}}
() df.toDF("dateCaptured"){{This is a valid renaming method.}}

## Multiple Choice
How do you convert a string column to a timestamp?
(x) First, convert the string value to a Unix time stamp, then cast it to a timestamp data type{{Correct. Your code would be similar to the following - df.withColumn("dateCaptured", unix_timestamp( col("dateCaptured"), "yyyy-MM-dd'T'HH:mm:ss").cast("timestamp") )}}
() You can directly cast the string value to a timestamp data type, using the Column's cast() method{{These steps are incorrect. You must first convert the string to a Unix time stamp, which is a Java Epoch. Then you can cast it to a timestamp data type.}}

## Multiple Choice
You need to find the average of sales transactions by storefront. Which of the following aggregates would you use?
() df.select(col("storefront")).avg("completedTransactions"){{This syntax is incorrect.}}
() df.groupBy(col("storefront")).avg(col("completedTransactions")){{This syntax is incorrect. You would receive an error that Column is not iterable.}}
() df.select(col("storefront")).average("completedTransactions"){{This syntax is incorrect.}}
(x) df.groupBy(col("storefront")).avg("completedTransactions"){{Correct. The syntax shown groups the data by the storefront Column, then calculates the average value of completed sales transactions.}}
