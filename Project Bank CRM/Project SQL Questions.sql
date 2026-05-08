-- Q1 Find the total number of customers in the database.
use bank_crm;
SELECT COUNT(CustomerId) AS Total_Customers
FROM customerinfo;

-- Q2 Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. (SQL)
SELECT 
	ci.CustomerId, ci.Surname, ci.EstimatedSalary
FROM 
	customerinfo ci
JOIN bank_churn bc ON ci.CustomerId = bc.CustomerId
WHERE 
	MONTH(ci.Bank_DOJ) IN (10, 11, 12) -- For the last quarter (October, November, December)
ORDER BY 
	ci.EstimatedSalary DESC
LIMIT 5;

-- Q3 Calculate the average number of products used by customers who have a credit card.

Select
	count(*) as Total_Customers,
	round(AVG(NumOfproducts),2) as Avg_Products
FROM 
	customerinfo ci
JOIN bank_churn bc ON ci.CustomerId = bc.CustomerId
where
	bc.HasCrCard = 'credit card holder';
	
-- Q5 Compare the average credit score of customers who have exited and those who remains.
use bank_crm;
Select
	exited as Customer_Type,
	FLOOR(avg(CreditScore)) as Avg_Credit_Score
from
	bank_churn
group by 1;

-- Q6 Which gender has a higher average estimated salary, and how does it relate to the number of active accounts?
SELECT 
    ci.Gender,
    round(AVG(CASE WHEN bc.IsActiveMember = 'Active Member' THEN ci.EstimatedSalary ELSE null END),2) AS Avg_Salary,
    SUM(CASE WHEN bc.IsActiveMember = 'Active Member' THEN 1 ELSE 0 END) AS Active_Accounts  
FROM 
    customerinfo ci
JOIN 
    bank_churn bc ON ci.CustomerId = bc.CustomerId
GROUP BY 
    ci.Gender  
ORDER BY 
    Avg_Salary DESC;
    
-- Q7 Segment the customers based on their credit score and identify the segment with the highest exit rate.

Select
	count(CustomerId) as Customer_count,
	(Case when CreditScore > 800 then 'Excellent Score'
				when CreditScore >700 and CreditScore <=800 then 'Good Score'
				when CreditScore >500 and CreditScore <=700 then 'Fair Score'
				when CreditScore <= 500 then 'Poor Score'
    end) as Credit_score,
    sum(case when Exited = 'Exit' then 1 else null end) as Exit_count
from
	bank_churn
group by 2
Order by Exit_Count desc;

-- Q8 Find out which geographic region has the highest number of active customers with a tenure greater than 5 years.

Select
	ci.Country,
    count(bc.IsActiveMember) as Active_Members
FROM 
	customerinfo ci
JOIN bank_churn bc ON ci.CustomerId = bc.CustomerId
Where
	bc.IsActiveMember = 'Active Member'
    and
    Tenure > 5
group by 1
Limit 1;
-- Q11 Examine the trend of customers joining over time and identify any seasonal patterns (yearly or monthly). Prepare the data through SQL and then visualize it.
use bank_crm;
SELECT
    YEAR(Bank_DOJ) AS Joining_year,
    MONTH(Bank_DOJ) AS Joining_mon,
    COUNT(CustomerId) AS Employees_Joined
FROM
    customerinfo
GROUP BY
    Joining_year, Joining_mon
ORDER BY
    Joining_year ASC, Joining_mon ASC;

--    Handling of all the months in case of 0 joining in a month

-- WITH MonthReference AS (
--     SELECT y.Year, m.Month
--     FROM (SELECT DISTINCT YEAR(Bank_DOJ) AS Year FROM customerinfo) y
--     CROSS JOIN (SELECT 1 AS Month UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
--                 SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL 
--                 SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL 
--                 SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12) m
-- )
-- SELECT 
--     mr.Year, 
--     mr.Month, 
--     COALESCE(COUNT(c.CustomerId), 0) AS CustomerCount
-- FROM MonthReference mr
-- LEFT JOIN customerinfo c 
--     ON YEAR(c.Bank_DOJ) = mr.Year AND MONTH(c.Bank_DOJ) = mr.Month
-- GROUP BY mr.Year, mr.Month
-- ORDER BY mr.Year, mr.Month;  
-- use bank_crm;

-- Q 15 Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. 
-- Also, rank the gender according to the average value. (SQL)

Select
    Country,
    Gender,
    round(avg(EstimatedSalary),2) as Avg_Salary,
    dense_rank() over (partition by Country order by avg(EstimatedSalary) desc) as rnk
from
	customerinfo
group by
		Gender, Country;
-- Q16 Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).

Select
	
	Case
		when age between 18 and 30 then "18-30"
		when age between 31 and 50 then "31-50"
		when age >50 then "50+"
		end as Age_group,
    round(avg(Tenure),2) as Avg_Tenure
FROM 
    customerinfo ci
JOIN 
    bank_churn bc ON ci.CustomerId = bc.CustomerId
where
	Exited ="Exit"
group by
Age_group;

-- Q19 Rank each bucket of credit score as per the number of customers who have churned the bank
use bank_crm;
with cte as
(Select
	(Case when CreditScore > 800 then 'Excellent Score'
				when CreditScore >700 and CreditScore <=800 then 'Good Score'
				when CreditScore >500 and CreditScore <=700 then 'Fair Score'
				when CreditScore <= 500 then 'Poor Score'
    end) as Credit_score,
    sum(case when Exited = 'Exit' then 1 else null end) as Exit_count
from
	bank_churn
group by 1
Order by Exit_Count desc
)
 select
	*,
    row_number() over (order by Exit_count desc) as rnk
from
	cte;
    
-- Q20 According to the age buckets find the number of customers who have a credit card. 
-- Also retrieve those buckets that have lesser than average number of credit cards per bucket.

With calc as
(Select
	
	Case
		when age between 18 and 30 then "18-30"
		when age between 31 and 50 then "31-50"
		when age >50 then "50+"
		end as Age_group,
    count(HasCrCard) as No_of_cc_holder
FROM 
    customerinfo ci
JOIN 
    bank_churn bc ON ci.CustomerId = bc.CustomerId
where
	HasCrCard = 'Credit Card Holder'
group by
Age_group
)
Select
	*
from
	calc
where
	No_of_cc_holder < (select avg(No_of_cc_holder) from calc)
order by Age_group;
-- Q21 Rank the Locations as per the number of people who have churned the bank and average balance of the customers.
with calc as(
Select
	Country,
    count(case when Exited = "Exit" then 1 else null end )as Churned_Customers,
    round(avg(balance),2) as Avg_Balance
FROM 
    customerinfo ci
JOIN 
    bank_churn bc ON ci.CustomerId = bc.CustomerId
group by
	1
order by
	Avg_Balance desc
)
Select
	*,
    row_number() over( order by Churned_Customers desc, Avg_Balance desc) as rnk
from
	calc;
-- Q22 As we can see that the “CustomerInfo” table has the CustomerID and Surname, 
-- now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname,
-- come up with a column where the format is “CustomerID_Surname”.

   
ALTER TABLE CustomerInfo
ADD COLUMN CustomerID_Surname VARCHAR(255);
SET SQL_SAFE_UPDATES = 0;
UPDATE CustomerInfo
SET CustomerID_Surname = CONCAT(CustomerID, '_', Surname);
    
-- Q23 Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.

SELECT 
    CustomerId,
    CreditScore,
    Tenure,
    Balance,
    NumOfProducts,
    HasCrCard,
    IsActiveMember,
    Exited,
    CASE 
        WHEN CustomerId IN (SELECT CustomerId FROM bank_Churn)
        THEN 'Exit'
        ELSE 'Retain'
    END AS ExitCategory
FROM Bank_Churn;
use bankcrm;

SELECT 
    bc.CustomerId,
    bc.CreditScore,
    bc.Tenure,
    bc.Balance,
    bc.NumOfProducts,
    bc.HasCrCard,
    bc.IsActiveMember,
    bc.Exited,
    (SELECT ec.ExitCategory
     FROM ExitCustomer ec
     WHERE ec.ExitID = bc.Exited) AS ExitCategory
FROM 
    Bank_Churn bc;
    
-- Q25 Write the query to get the customer IDs, their last name, and whether they are active or not for the customers whose surname ends with “on”.
use bank_crm;
Select
	ci.CustomerId,
    Surname,
    IsActiveMember as Status
FROM 
    customerinfo ci
JOIN 
    bank_churn bc ON ci.CustomerId = bc.CustomerId
where
		Surname like '%on'
    and 
		IsActiveMember = 'Active Member'
Order by
	CustomerId asc;
    
-- Q26 Can you observe any data disrupency in the Customer’s data? As a hint it’s present in the IsActiveMember and Exited columns.
-- One more point to consider is that the data in the Exited Column is absolutely correct and accurate.
 
UPDATE Bank_Churn
SET IsActiveMember = 'Inactive Member'
WHERE Exited = 'Exit' AND IsActiveMember = 'Active Member';


-- ------- SUBJECTIVE QUESTIONS---------------
-- Q9. Utilize SQL queries to segment customers based on demographics and account details.

SELECT
    c.CustomerId,
    c.Gender,
    c.Age,
    c.Country,
    a.CreditScore,
    a.Balance,
    a.NumOfProducts,
    a.IsActiveMember,
    a.Exited,
    c.EstimatedSalary,

    -- Age Segmentation
    CASE 
        WHEN c.Age <= 25 THEN '18-25'
        WHEN c.Age <= 35 THEN '26-35'
        WHEN c.Age <= 45 THEN '36-45'
        WHEN c.Age <= 60 THEN '46-60'
        ELSE '60+'
    END AS Age_Group,

    -- Balance Segmentation
    CASE 
        WHEN a.Balance = 0 THEN 'Zero Balance'
        WHEN a.Balance <= 5000 THEN 'Low Balance'
        WHEN a.Balance <= 15000 THEN 'Medium Balance'
        ELSE 'High Balance'
    END AS Balance_Group,

    -- Product Holding Group
    CASE 
        WHEN a.NumOfProducts < 2 THEN 'Less than 2 Products'
        WHEN a.NumOfProducts >= 2 THEN 'More than 2 Products'
        ELSE 'Other'
    END AS Product_Holding_Group,

    -- Salary Group
    CASE
        WHEN c.EstimatedSalary <= 5000 THEN '<5k'
        WHEN c.EstimatedSalary <= 10000 THEN '5k-10k'
        WHEN c.EstimatedSalary <= 15000 THEN '10k-15k'
        WHEN c.EstimatedSalary <= 20000 THEN '15k-20k'
        ELSE '20k+'
    END AS Salary_Group,

    -- Activity Status
    CASE 
        WHEN a.IsActiveMember = 1 THEN 'Active'
        ELSE 'Inactive'
    END AS Activity_Status

FROM
    customerinfo c
JOIN 
    Bank_Churn a ON c.CustomerId = a.CustomerId
