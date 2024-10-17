USE AdventureWorks2019
GO

/* QUESTION 1 */

SELECT [Production].[Product].ProductID, [Production].[Product].Name, 
	   [Production].[Product].Color, [Production].[Product].ListPrice, 
	   [Production].[Product].Size
FROM [Production].[Product]
WHERE NOT EXISTS 
	(SELECT *
	FROM [Sales].[SalesOrderDetail]
	WHERE [Production].[Product].ProductID=[Sales].[SalesOrderDetail].ProductID)
ORDER BY [Production].[Product].ProductID


/* QUESTION 2 */

SELECT TBL1.CustomerID, COALESCE(PP.LastName, 'Unknown') AS LastName, 
	   COALESCE(PP.FirstName, 'Unknown') AS FirstName
FROM [Person].[Person] PP RIGHT JOIN 
	 (SELECT C.CustomerID
	 FROM [Sales].[Customer] C LEFT JOIN [Sales].[SalesOrderHeader] SOH
	 ON C.CustomerID=SOH.CustomerID
	 WHERE SOH.SalesOrderID IS NULL) TBL1
	 ON PP.BusinessEntityID=TBL1.CustomerID
ORDER BY TBL1.CustomerID ASC


/* QUESTION 3 */

SELECT [Sales].[Customer].CustomerID, [Person].[Person].FirstName, 
	   [Person].[Person].LastName, new.CNT AS CountOfOrders
FROM [Sales].[Customer] JOIN [Person].[Person]
ON [Sales].[Customer].PersonID=[Person].[Person].BusinessEntityID
JOIN
	(SELECT TOP 10 [Sales].[SalesOrderHeader].CustomerID,COUNT(*) CNT
	FROM [Sales].[SalesOrderHeader]
	GROUP BY [Sales].[SalesOrderHeader].CustomerID
	ORDER BY CNT DESC) new
ON [Sales].[Customer].CustomerID=new.[CustomerID]


/* QUESTION 4 */

SELECT PP.FirstName, PP.LastName, E.JobTitle, E.HireDate, 
	   COUNT(*) OVER (PARTITION BY E.JobTitle) AS CountOfTitle
FROM [Person].[Person] PP JOIN [HumanResources].[Employee] E
ON PP.BusinessEntityID=E.BusinessEntityID
ORDER BY E.JobTitle


/* QUESTION 5 */

WITH LastOrder 
AS
(SELECT tbl1.SalesOrderID, tbL1.CustomerID, tbl1.OrderDate AS LastOrder
FROM 
	(SELECT [Sales].[SalesOrderHeader].SalesOrderID AS SalesOrderID, 
			[Sales].[SalesOrderHeader].CustomerID AS CustomerID, 
			[Sales].[SalesOrderHeader].OrderDate AS OrderDate,
			ROW_NUMBER() OVER (PARTITION BY [Sales].[SalesOrderHeader].CustomerID 
						 ORDER BY [Sales].[SalesOrderHeader].OrderDate DESC) AS num
	FROM [Sales].[SalesOrderHeader]) tbl1
WHERE tbl1.num=1)

SELECT LO.SalesOrderID, LO.CustomerID, PP.LastName, PP.FirstName, LO.LastOrder,
	   tbl3.PreviousOrder
FROM LastOrder LO LEFT JOIN 
	(SELECT tbl2.SalesOrderID, tbl2.CustomerID, tbl2.OrderDate AS PreviousOrder
	 FROM 
	(SELECT [Sales].[SalesOrderHeader].SalesOrderID AS SalesOrderID, 
			[Sales].[SalesOrderHeader].CustomerID AS CustomerID, 
			[Sales].[SalesOrderHeader].OrderDate AS OrderDate,
			ROW_NUMBER() OVER (PARTITION BY [Sales].[SalesOrderHeader].CustomerID 
						 ORDER BY [Sales].[SalesOrderHeader].OrderDate DESC) AS num
	 FROM [Sales].[SalesOrderHeader]) tbl2
WHERE tbl2.num=2) tbl3
ON LO.CustomerID=tbl3.CustomerID
JOIN [Sales].[Customer] SC
ON SC.CustomerID=LO.CustomerID
JOIN [Person].[Person] PP
ON PP.BusinessEntityID=SC.PersonID
ORDER BY PP.LastName


/* QUESTION 6 */

SELECT tbl1.Year, tbl1.SalesOrderID, tbl1.LastName, tbl1.FirstName, 
	   FORMAT(tbl3.MAXTOTAL,'###,###.#') AS Total
FROM
	(SELECT YEAR(SOH.OrderDate) AS Year, SOH.SalesOrderID AS SalesOrderID, 
			PP.LastName AS LastName, PP.FirstName AS FirstName, 
			SUM(SOD.UnitPrice*(1-SOD.UnitPriceDiscount)*SOD.OrderQty) AS Total
	FROM [Sales].[SalesOrderHeader] SOH JOIN [Sales].[SalesOrderDetail] SOD
	ON SOH.SalesOrderID=SOD.SalesOrderID
	JOIN [Sales].[Customer] SC
	ON SC.CustomerID=SOH.CustomerID
	JOIN [Person].[Person] PP
	ON SC.PersonID=PP.BusinessEntityID
	GROUP BY YEAR(SOH.OrderDate), SOH.SalesOrderID, PP.LastName, PP.FirstName) tbl1
JOIN
	(SELECT tbl.Year, MAX(Total) AS MAXTOTAL
	FROM
		(SELECT YEAR(SOH.OrderDate) AS Year, SOH.SalesOrderID AS SalesOrderID, 
				PP.LastName AS LastName, PP.FirstName AS FirstName, 
				SUM(SOD.UnitPrice*(1-SOD.UnitPriceDiscount)*SOD.OrderQty) AS Total
		FROM [Sales].[SalesOrderHeader] SOH JOIN [Sales].[SalesOrderDetail] SOD
		ON SOH.SalesOrderID=SOD.SalesOrderID
		JOIN [Sales].[Customer] SC
		ON SC.CustomerID=SOH.CustomerID
		JOIN [Person].[Person] PP
		ON SC.PersonID=PP.BusinessEntityID
		GROUP BY YEAR(SOH.OrderDate), SOH.SalesOrderID, PP.LastName, PP.FirstName) tbl
	GROUP BY tbl.Year) tbl3 
ON tbl1.Year=tbl3.Year AND tbl1.Total=tbl3.MAXTOTAL


/* QUESTION 7 */

SELECT Month, [2011], [2012], [2013], [2014]
FROM 
	(SELECT [Sales].[SalesOrderHeader].SalesOrderID, 
			MONTH([Sales].[SalesOrderHeader].OrderDate) AS Month,
			YEAR([Sales].[SalesOrderHeader].OrderDate) AS Year
	FROM [Sales].[SalesOrderHeader]) AS O 
PIVOT (COUNT(O.SalesOrderID) FOR Year IN ([2011], [2012], [2013], [2014]))NEW
ORDER BY Month



/* QUESTION 8 */

SELECT [Year], [Month], Sum_Price, CumSum
FROM
	(SELECT [Year], [Month] [Right_Order], CAST([Month] AS VARCHAR) AS [Month],
			tbl1.Sum_Price, SUM(tbl1.Sum_Price) OVER (PARTITION BY [Year] ORDER BY [Month]
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumSum
	FROM
		(SELECT YEAR(SOH.OrderDate) AS [Year], MONTH(SOH.OrderDate) AS [Month], 
			   ROUND(SUM(SOD.UnitPrice*(1-SOD.UnitPriceDiscount)),2,0) AS Sum_Price
		FROM [Sales].[SalesOrderHeader] SOH JOIN [Sales].[SalesOrderDetail] SOD
		ON SOH.SalesOrderID=SOD.SalesOrderID
		GROUP BY YEAR(SOH.OrderDate), MONTH(SOH.OrderDate)) tbl1
UNION
	SELECT YEAR(SOH.OrderDate) AS [Year], 13 [Right_Order], 
		   'grand_total' [Month], NULL Sum_Price,  
		   ROUND(SUM(SOD.UnitPrice*(1-SOD.UnitPriceDiscount)),2,0) AS CumSum
	FROM [Sales].[SalesOrderHeader] SOH JOIN [Sales].[SalesOrderDetail] SOD
	ON SOH.SalesOrderID=SOD.SalesOrderID
	GROUP BY  YEAR(SOH.OrderDate) 
 )tbl2
ORDER BY [Year],[Right_Order]


/* QUESTION YES 9 */

WITH EmpByLengthOfWork
AS
(SELECT D.Name AS DepartmentName, E.BusinessEntityID AS "Employee'sId",
		PP.FirstName+' '+PP.LastName AS "Employee'sFullName", HireDate,
		DATEDIFF(MONTH,HireDate,getdate()) AS Seniority,
		DENSE_RANK() OVER (PARTITION BY D.Name ORDER BY HireDate) rg
FROM [Person].[Person] PP JOIN [HumanResources].[Employee] E
  ON PP.BusinessEntityID=E.BusinessEntityID
  JOIN [HumanResources].[EmployeeDepartmentHistory] EDH
  ON EDH.BusinessEntityID=e.BusinessEntityID
  JOIN [HumanResources].[Department] D
  ON D.DepartmentID=EDH.DepartmentID)

Select DepartmentName, "Employee'sId", "Employee'sFullName", HireDate, Seniority,
LAG("Employee'sFullName",1) OVER (PARTITION BY DepartmentName ORDER BY rg) PreviousEmpName,
LAG(HireDate,1) OVER (PARTITION BY DepartmentName ORDER BY rg ) PreviousEmpHDate,
DATEDIFF(DAY,LAG(HireDate,1) OVER (PARTITION BY DepartmentName ORDER BY rg ),HireDate) DiffDays
FROM EmpByLengthOfWork
ORDER BY DepartmentName, rg DESC











