EXECUTE AS USER = 'asa.sql.highperf'

IF OBJECT_ID(N'[wwi_perf].[Sale_Heap]', N'U') IS NOT NULL   
DROP TABLE [wwi_perf].[Sale_Heap]  

-- CREATE TABLE [wwi_perf].[Sale_Heap]
-- WITH
-- (
-- 	DISTRIBUTION = ROUND_ROBIN,
-- 	HEAP
-- )
-- AS
-- SELECT
-- 	*
-- FROM	
-- 	[wwi].[SaleSmall]
-- WHERE
-- 	TransactionDateId >= 20190101
-- OPTION  (LABEL  = 'CTAS : Sale_Heap')

CREATE TABLE [wwi_perf].[Sale_Heap]
( 
	[TransactionId] [uniqueidentifier]  NOT NULL,
	[CustomerId] [int]  NOT NULL,
	[ProductId] [smallint]  NOT NULL,
	[Quantity] [tinyint]  NOT NULL,
	[Price] [decimal](9,2)  NOT NULL,
	[TotalAmount] [decimal](9,2)  NOT NULL,
	[TransactionDateId] [int]  NOT NULL,
	[ProfitAmount] [decimal](9,2)  NOT NULL,
	[Hour] [tinyint]  NOT NULL,
	[Minute] [tinyint]  NOT NULL,
	[StoreId] [smallint]  NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)