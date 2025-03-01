show databases;

use classicmodels;
-- Q1: SELECT clause with WHERE, AND, DISTINCT, Wild Card (LIKE)

-- Fetch employee details for Sales Rep reporting to employee 1102
SELECT employeeNumber, firstName, lastName 
FROM employees
WHERE jobTitle = 'Sales Rep' AND reportsTo = 1102;

-- Show unique product lines containing 'cars' at the end
SELECT DISTINCT productLine 
FROM products
WHERE productLine LIKE '%cars';

-- Q2: CASE STATEMENTS for Segmentation
SELECT customerNumber, customerName,
    CASE 
        WHEN country IN ('USA', 'Canada') THEN 'North America'
        WHEN country IN ('UK', 'France', 'Germany') THEN 'Europe'
        ELSE 'Other'
    END AS CustomerSegment
FROM Customers;


-- Q3: Group By with Aggregation functions and Having clause

-- 1. Top 10 products (by productCode) with the highest total order quantity
SELECT productCode, SUM(quantityOrdered) AS totalQuantity
FROM orderdetails
GROUP BY productCode
ORDER BY totalQuantity DESC
LIMIT 10;

-- 2. Payment frequency by month with count > 20
SELECT MONTHNAME(paymentDate) AS monthName, COUNT(*) AS paymentCount
FROM payments
GROUP BY monthName
HAVING paymentCount > 20
ORDER BY paymentCount DESC;

-- Q4: Constraints - Creating Customers_Orders Database
CREATE DATABASE Customers_Orders;
USE Customers_Orders;

CREATE TABLE Customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone_number VARCHAR(20)
);

CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10,2) CHECK (total_amount > 0),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);


-- Q5: JOINS - Top 5 countries by order count
	SELECT c.country, COUNT(o.orderNumber) AS order_count
	FROM Customers c
	JOIN Orders o ON c.customerNumber = o.customerNumber
	GROUP BY c.country
	ORDER BY order_count DESC
	LIMIT 5;

-- Q6: SELF JOIN - Employee and Managers
CREATE TABLE project (
    EmployeeID INT AUTO_INCREMENT PRIMARY KEY,
    FullName VARCHAR(50) NOT NULL,
    Gender ENUM('Male', 'Female') NOT NULL,
    ManagerID INT
);

 

INSERT INTO project (EmployeeID, FullName, Gender, ManagerID) VALUES
(1, 'Pranaya', 'Male', 3),
(2, 'Priyanka', 'Female', 1),
(3, 'Preety', 'Female', NULL),
(4, 'Anurag', 'Male', 1),
(5, 'Sambit', 'Male', 1),
(6, 'Rajesh', 'Male', 3),
(7, 'Hina', 'Female', 3);

SELECT m.FullName AS `Manager Name`, e.FullName AS `Emp Name`
FROM project e
JOIN project m ON e.ManagerID = m.EmployeeID
ORDER BY `Manager Name`, `Emp Name`;


-- Q7: DDL Commands: Create, Alter, Rename
drop table Facility;
-- Create table Facility
CREATE TABLE Facility (
    Facility_ID INT ,
    Name VARCHAR(100),
    State VARCHAR(100),
    Country VARCHAR(100)
);

-- Alter the table to add primary key and auto increment (if not already added)
ALTER TABLE Facility MODIFY Facility_ID INT AUTO_INCREMENT PRIMARY KEY;

-- Add City column after Name with NOT NULL constraint
ALTER TABLE Facility ADD COLUMN City VARCHAR(100) NOT NULL AFTER Name;

desc facility;

-- Q8: Views
CREATE VIEW product_category_sales AS
SELECT p.productLine, 
       SUM(od.quantityOrdered * od.priceEach) AS total_sales,
       COUNT(DISTINCT o.orderNumber) AS number_of_orders
FROM Products p
JOIN OrderDetails od ON p.productCode = od.productCode
JOIN Orders o ON od.orderNumber = o.orderNumber
JOIN ProductLines pl ON p.productLine = pl.productLine
GROUP BY p.productLine;

select * from product_category_sales;

-- Q9: Stored Procedures
DELIMITER //
CREATE PROCEDURE Get_country_payments(IN input_year INT, IN input_country VARCHAR(50))
BEGIN
    SELECT YEAR(paymentDate) AS year, country, 
           ROUND(SUM(amount) / 1000, 0) AS total_amount_K 
    FROM Payments p
    JOIN Customers c ON p.customerNumber = c.customerNumber
    WHERE YEAR(paymentDate) = input_year AND country = input_country
    GROUP BY year, country;
END //
DELIMITER ;
CALL Get_country_payments(2003, 'France');



-- Q10: Window Functions
-- Rank customers based on order frequency
SELECT c.customerName, 
       COUNT(o.orderNumber) AS order_count,  
       RANK() OVER (ORDER BY COUNT(o.orderNumber) DESC) AS order_frequency_rnk
FROM Orders o
JOIN Customers c ON o.customerNumber = c.customerNumber
GROUP BY c.customerNumber, c.customerName; 


-- Year-wise, month-wise count of orders and YoY % change
WITH MonthlyOrders AS (
    SELECT 
        YEAR(orderDate) AS year, 
        MONTH(orderDate) AS month_num,
        MONTHNAME(orderDate) AS month,
        COUNT(orderNumber) AS total_orders
    FROM Orders
    GROUP BY YEAR(orderDate), MONTH(orderDate), MONTHNAME(orderDate)
)
SELECT 
    year, 
    month,
    total_orders,
   
    CASE 
        WHEN LAG(total_orders) OVER (PARTITION BY year ORDER BY month_num) IS NULL THEN 'N/A'
        ELSE CONCAT(ROUND((total_orders - LAG(total_orders) OVER (PARTITION BY year ORDER BY month_num)) / 
                          LAG(total_orders) OVER (PARTITION BY year ORDER BY month_num) * 100, 0), '%')
    END AS YoY_Change
FROM MonthlyOrders
ORDER BY year, month_num;

-- Q11: Subqueries
SELECT productLine, COUNT(*) AS Total
FROM Products
WHERE buyPrice > (SELECT AVG(buyPrice) FROM Products)
GROUP BY productLine;

-- Q12: Error Handling
CREATE TABLE Emp_EH (
    EmpID INT AUTO_INCREMENT PRIMARY KEY,
    EmpName VARCHAR(50) NOT NULL,
    EmailAddress VARCHAR(255) UNIQUE NOT NULL
);
DELIMITER //
CREATE PROCEDURE Insert_EmpEH(IN empName VARCHAR(50), IN email VARCHAR(255))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Error message when any SQL exception occurs
        SELECT 'Error occurred' AS ErrorMessage;
    END;
    
    -- Insert statement
    INSERT INTO Emp_EH (EmpName, EmailAddress) VALUES (empName, email);
END //
DELIMITER ;
CALL Insert_EmpEH('John Doe', 'john.doe@example.com');
CALL Insert_EmpEH('Jane Doe', 'john.doe@example.com');
SELECT * FROM Emp_EH;

-- Q13: Triggers
CREATE TABLE Emp_BIT (
    Name VARCHAR(50),
    Occupation VARCHAR(50),
    Working_date DATE,
    Working_hours INT
);

INSERT INTO Emp_BIT VALUES
('Robin', 'Scientist', '2020-10-04', 12),  
('Warner', 'Engineer', '2020-10-04', 10),  
('Peter', 'Actor', '2020-10-04', 13),  
('Marco', 'Doctor', '2020-10-04', 14),  
('Brayden', 'Teacher', '2020-10-04', 12),  
('Antonio', 'Business', '2020-10-04', 11);

DELIMITER //
CREATE TRIGGER before_insert_working_hours
BEFORE INSERT ON Emp_BIT
FOR EACH ROW
BEGIN
    IF NEW.Working_hours < 0 THEN
        SET NEW.Working_hours = ABS(NEW.Working_hours);
    END IF;
END //
DELIMITER ;

INSERT INTO Emp_BIT (Name, Occupation, Working_date, Working_hours) 
VALUES ('Sophia', 'Designer', '2024-02-28', -8);

SELECT * FROM Emp_BIT WHERE Name = 'Sophia';






	


