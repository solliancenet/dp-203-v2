USE master
GO

-- Create the AWDataWarehouse database
CREATE DATABASE AWDataWarehouse
GO

-- Create dimension tables
USE AWDataWarehouse
GO

-- Reseller
CREATE TABLE [dbo].[DimReseller](
	[ResellerKey] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY NONCLUSTERED,
	[ResellerAlternateKey] [nvarchar](15) NOT NULL,
	[Phone] [nvarchar](25) NULL,
	[BusinessType] [varchar](20) NULL,
	[ResellerName] [nvarchar](50) NOT NULL,
	[NumberEmployees] [int] NULL,
	[AddressLine1] [nvarchar](60) NULL,
	[AddressLine2] [nvarchar](60) NULL,
	[City] [nvarchar](30) NULL,
	[StateProvinceName] [nvarchar](50) NULL,
	[CountryRegionCode] [nvarchar](3) NULL,
	[CountryRegionName] [nvarchar](50) NULL,
	[PostalCode] [nvarchar](15) NULL,
	[YearOpened] [int] NULL
)
GO

CREATE TABLE [dbo].[DimEmployee](
	[EmployeeKey] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY NONCLUSTERED,
	[EmployeeAlternateKey] [nvarchar](15) NOT NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[EmailAddress] [nvarchar](50) NULL,
	[Title] [nvarchar](50) NULL,
	[HireDate] [date] NOT NULL,
	[Deleted] bit NOT NULL DEFAULT 0
)
GO

-- Product
CREATE TABLE [dbo].[DimProduct](
	[ProductKey] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY NONCLUSTERED,
	[ProductAlternateKey] [nvarchar](25) NOT NULL,
	[ProductName] [nvarchar](50) NOT NULL,
	[ProductSubcategoryName] [nvarchar](50) NOT NULL,
	[ProductCategoryName] [nvarchar](50) NOT NULL,
	[StandardCost] [money] NULL,
	[Color] [nvarchar](15) NULL,
	[ListPrice] [money] NULL,
	[Size] [nvarchar](50) NULL,
	[Weight] [float] NULL,
	[Description] [nvarchar](400) NULL
)

GO

-- Create Fact Tables
CREATE TABLE [dbo].[FactResellerSales](
	[ProductKey] [int] NOT NULL REFERENCES [dbo].[DimProduct] ([ProductKey]),
	[ResellerKey] [int] NOT NULL REFERENCES [dbo].[DimReseller] ([ResellerKey]),
	[EmployeeKey] int NOT NULL REFERENCES [dbo].[DimEmployee] ([EmployeeKey]),
	[SalesOrderNumber] [nvarchar](20) NOT NULL,
	[SalesOrderLineNumber] [tinyint] NOT NULL,
	[OrderQuantity] [smallint] NULL,
	[UnitPrice] [money] NULL,
	[SalesAmount] [money] NULL,
	[OrderDate] [datetime] NULL,
	[ShipDate] [datetime] NULL,
	[PaymentType] [nvarchar](15) NULL,
	 CONSTRAINT [PK_FactResellerSales] PRIMARY KEY NONCLUSTERED 
	(
		[ProductKey] ASC,
		[ResellerKey] ASC,
		[EmployeeKey] ASC,
		[SalesOrderNumber] ASC,
		[SalesOrderLineNumber] ASC
	)
) 

GO

