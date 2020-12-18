Now that you've completed all the notebooks in Azure Databricks, check your knowledge by answering the following questions.

## quiz title: Knowledge check
## Multiple Choice
Which DataFrame method do you use to create a temporary view?
() createTempView(){{This method name is incorrect.}}
() createTempViewDF(){{This method name is incorrect.}}
(x) createOrReplaceTempView(){{Correct. You use this method to create temporary views in DataFrames.}}

## Multiple Choice
How do you create a DataFrame object?
(x) Introduce a variable name and equate it to something like myDataFrameDF ={{Correct. This approach is the correct way to create DataFrame objects.}}
() Use the createDataFrame() function{{There's no such method for creating a DataFrame.}}
() Use the DF.create() syntax{{This syntax is incorrect, and this approach isn't the right way to create DataFrame objects.}}

## Multiple Choice
How do you cache data into the memory of the local executor for instant access?
() .save().inMemory(){{This syntax is incorrect.}}
() .inMemory().save(){{This syntax is incorrect.}}
(x) .cache(){{Correct. The cache() method is an alias for persist(). Calling this moves data into the memory of the local executor.}}

## Multiple Choice
What is the Python syntax for defining a DataFrame in Spark from an existing Parquet file in DBFS?
() IPGeocodeDF = parquet.read("dbfs:/mnt/training/ip-geocode.parquet"){{This syntax is incorrect.}}
(x) IPGeocodeDF = spark.read.parquet("dbfs:/mnt/training/ip-geocode.parquet"){{This syntax is correct.}}
() IPGeocodeDF = spark.parquet.read("dbfs:/mnt/training/ip-geocode.parquet"){{This syntax is incorrect.}}
