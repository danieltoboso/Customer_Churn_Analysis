--2 Data cleaning and transformation
--Checking for irregularities.

--Changin column names we will need to join 2 tables later on.

ALTER TABLE zipcode_population
RENAME COLUMN "Zip Code" to zip_code

ALTER TABLE customer_churn
RENAME COLUMN "Zip Code" to zip_code

ALTER TABLE customer_churn
RENAME COLUMN "Customer ID" to Customer_ID

ALTER TABLE customer_churn
RENAME COLUMN "Number of Dependents" to Number_of_dependents

ALTER TABLE customer_churn
RENAME COLUMN "Tenure in Months" to Tenure_in_months

ALTER TABLE customer_churn
RENAME COLUMN "Total Revenue" to Total_Revenue

ALTER TABLE customer_churn
RENAME COLUMN "Customer Status" to Customer_Status

ALTER TABLE customer_churn
RENAME COLUMN "Churn Category" to Churn_Category

ALTER TABLE customer_churn
RENAME COLUMN "Churn Reason" to Churn_Reason

ALTER TABLE customer_churn
RENAME COLUMN "Multiple Lines" to Multiple_Lines

ALTER TABLE customer_churn
RENAME COLUMN "Internet Service" to Internet_Service

ALTER TABLE customer_churn
RENAME COLUMN "Internet Type" to Internet_Type

ALTER TABLE customer_churn
RENAME COLUMN "Online Backup" to Online_Backup

ALTER TABLE customer_churn
RENAME COLUMN "Device Protection Plan" to Device_Protection_Plan

ALTER TABLE customer_churn
RENAME COLUMN "Premium Tech Support" to Premium_Tech_Support

ALTER TABLE customer_churn
RENAME COLUMN "Streaming TV" to Streaming_TV

ALTER TABLE customer_churn
RENAME COLUMN "Streaming Movies" to Streaming_Movies

ALTER TABLE customer_churn
RENAME COLUMN "Streaming Music" to Streaming_Music

ALTER TABLE customer_churn
RENAME COLUMN "Unlimited Data" to Unlimited_Data

ALTER TABLE customer_churn
RENAME COLUMN "Payment Method" to Payment_Method

--Checking entries in the 'gender' column that are not 'Male' or 'Female'.

SELECT 
  * 
FROM 
  customer_churn 
WHERE 
  gender NOT IN ('Female', 'Male');

--Checking entries in the 'Customer Status' column that are not 'Stayed', 'Churned', or 'Joined'. 

SELECT 
  * 
FROM 
  customer_churn 
WHERE 
  Customer_Status NOT IN ('Stayed', 'Churned', 'Joined');

--Cheking for possible duplicates.

SELECT 
  Customer_ID, 
  count(Customer_ID) as count 
FROM 
  customer_churn 
GROUP BY 
  Customer_ID 
HAVING 
  count(Customer_ID) > 1; 

--Checking for nulls. 

SELECT 
  Customer_ID
FROM 
  customer_churn 
WHERE Customer_ID IS NULL;

--Removing the columns we don't need.

ALTER TABLE customer_churn
DROP COLUMN Latitude,
DROP COLUMN Longitude;

--3. Exploratory data analysis
--3.1 What is the overall churn rate in Q2 2022? 

SELECT 
  Customer_Status, 
  count(Customer_ID) as Num_customers,
  round((SUM(Total_Revenue) * 100.0) / SUM(SUM(Total_Revenue)) OVER(), 1) as Revenue_percent
FROM 
  customer_churn 
GROUP BY 
  Customer_Status  
  
--3.2 What are the demographics of customers who churned?
  
SELECT 
			Married,
			SUM(CASE WHEN Gender LIKE 'Male' THEN 1 ELSE 0 END) AS Male,
			SUM(CASE WHEN Gender LIKE 'Female' THEN 1 ELSE 0 END) AS Female,
			round(count( Gender) *100.0 / sum(count(Gender)) OVER(),1) AS Percentage
FROM customer_churn
WHERE Customer_Status = 'Churned'
GROUP BY Married
HAVING SUM(CASE WHEN Gender LIKE 'Male' THEN 1 ELSE 0 END) IS NOT NULL
        AND SUM(CASE WHEN Gender LIKE 'Female' THEN 1 ELSE 0 END) IS NOT NULL
ORDER BY Married DESC;

--Number of dependents base on clasification:

SELECT sum(Number_of_dependents) as total_dependents_num,
				 sum(CASE WHEN Number_of_dependents = 0 THEN 1 ELSE NULL END) as _0_,
				 sum(CASE WHEN Number_of_dependents = 1 THEN 1 ELSE NULL END) as _1_,
				 sum(CASE WHEN Number_of_dependents BETWEEN 2 and 3 THEN 1 ELSE NULL END) as _2_or_3,
				 sum(CASE WHEN Number_of_dependents > 3 THEN 1 ELSE NULL END) as more_than_3
FROM customer_churn
WHERE Customer_Status = "Churned" 
UNION 
SELECT sum(Number_of_dependents) as total_dependents_num,
				 sum(CASE WHEN Number_of_dependents = 0 THEN 1 ELSE NULL END) as _0_,
				 sum(CASE WHEN Number_of_dependents = 1 THEN 1 ELSE NULL END) as _1_,
				 sum(CASE WHEN Number_of_dependents BETWEEN 2 and 3 THEN 1 ELSE NULL END) as _2_or_3,
				 sum(CASE WHEN Number_of_dependents > 3 THEN 1 ELSE NULL END) as more_than_3
FROM customer_churn
WHERE Customer_Status = "Stayed"; 

--Dependents/No dependents percentages.

SELECT
				CASE WHEN Number_of_Dependents > 0 THEN 'Dependents'
				ELSE 'No Dependents'
				END AS Dependents,
				ROUND(COUNT(Customer_ID) *100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Percentage
FROM customer_churn
WHERE Customer_Status = 'Churned'
GROUP BY Dependents
ORDER BY Percentage DESC;

--Checking age percentages.

SELECT 
    ROUND(AVG(CASE WHEN Customer_Status = 'Churned' THEN age END), 2) AS avg_age_churned,
    ROUND(AVG(CASE WHEN Customer_Status = 'Stayed' THEN age END), 2) AS avg_age_stayed
FROM customer_churn
WHERE Customer_Status IN ('Churned', 'Stayed');

--AVG age Genders (M/F).

SELECT 
    ROUND(AVG(CASE WHEN Customer_Status = 'Churned' AND Gender = 'Female' THEN age END), 2) AS Female_Avg_Age,
	ROUND(AVG(CASE WHEN Customer_Status = 'Churned' AND Gender = 'Male' THEN age END), 2) AS Male_Avg_Age
FROM customer_churn
WHERE Customer_Status IN ('Churned', 'Stayed');

--Gender average.

SELECT Gender,
				count(Gender) as Total,
				round(count( Gender) *100.0 / sum(count(Gender)) OVER(),1) AS Percentage
FROM customer_churn
WHERE Customer_Status = 'Churned'
GROUP by Gender
ORDER by Percentage DESC;

--Population patterns.

SELECT 
				round(avg(Population) , 2) as avg_population,
				round((sum(Population) * 100) / 
				sum(sum(Population)) OVER (), 2) as total_population,
				count(z.zip_code) as total_zip_codes,
				CASE WHEN Population <= 15000 THEN "low_population"
				WHEN Population BETWEEN 15001 AND 49999 THEN "medium_population"
				WHEN Population >= 50000 THEN "hight population"
				END as type 
FROM zipcode_population z
JOIN customer_churn c ON z.zip_code = c.zip_code
WHERE  Customer_Status = 'Churned'
GROUP by type
ORDER by total_zip_codes DESC;

--Ranking top 10 cities with highes chunk rate.

WITH churned_customers AS (
    SELECT City,
        COUNT(Customer_ID) AS Customers_churned
    FROM customer_churn
    WHERE Customer_Status = 'Churned'
    GROUP BY City
    HAVING COUNT(Customer_ID) > 20 
),
total_customers AS (
										SELECT City,
										count(customer_id) as Total_Customers
										FROM customer_churn
										GROUP by City
										)
SELECT c.City,
    c.Customers_churned,
    t.Total_customers,
   round(count(CASE WHEN  Customer_Status = 'Churned' THEN Customer_ID ELSE NULL END)* 100.0 / count(Customer_ID)) AS Churn_rate
FROM  customer_churn cc
JOIN churned_customers c ON c.City = cc.City
JOIN total_customers t ON t.City = c.City
GROUP BY c.City
ORDER BY Churn_rate DESC
LIMIT 10;

 --3.3 What are the key reasons or factors contributing to churn?
 
SELECT Churn_Category, Churn_Reason, 
				 count(Churn_Reason)  as Times_Elected,
				  round(sum("Total_revenue"), 2) as Churned_revenue,
				  round((sum(Customer_ID) * 100) / sum(sum(Customer_ID)) OVER(), 1) as Customer_Chur_Percent
FROM customer_churn
WHERE Customer_Status = 'Churned'
GROUP by  Churn_Category
ORDER by Times_elected DESC;

--Reasons:

SELECT Churn_Reason, Churn_Category, 
				 count(Churn_Reason)  as Times_Elected
FROM customer_churn
WHERE Customer_Status = 'Churned'
GROUP by  Churn_Reason
ORDER by Times_elected DESC
LIMIT 10;
 
 --3.4 How do customer tenure affect churn?
 
 --Avg_Tenure
 SELECT round(avg(Tenure_in_months) ,2) as Avg_Tenure FROM customer_churn;
 
 --Class Tenure_in_months and percent
SELECT 
				count(Tenure_in_months) as Total,
				round((sum(Customer_ID) * 100) / sum(sum(Customer_ID)) OVER(), 1) as Percent,
				CASE WHEN Tenure_in_months <
           (
               SELECT avg(Tenure_in_months) FROM customer_churn
           ) THEN
               'New Customers'
           ELSE
               'Long-term Customers'
       END as Class
FROM customer_churn
WHERE Customer_Status = 'Churned'
GROUP by Class
ORDER by Percent DESC;

--Contracts.

 SELECT 
				Contract,
				count(Contract) as Customers_churned,
				round(count( Contract) *100.0 / sum(count(Contract)) OVER(),1) AS Percentage
FROM customer_churn
WHERE Customer_Status = 'Churned'
GROUP by Contract;

--Payment methods.

SELECT Payment_Method,
				round(count( Payment_Method) *100.0 / sum(count(Payment_Method)) OVER(),1) AS Percentage
FROM customer_churn
WHERE Customer_Status = 'Churned'
GROUP by Payment_Method;

--3.5 What is the impact of service usage on churn?
 
--Internet_Type percentages.

SELECT  
				Internet_Type,
				count(Customer_ID) as Customers_churned,
				round(count(Customer_ID) *100.0 / sum(count(Customer_ID)) OVER(),1) AS Percentage
FROM customer_churn
WHERE Internet_Type IS NOT NULL AND Customer_Status  = 'Churned'
GROUP by Internet_Type
ORDER by Customers_churned DESC;

--Streming_Movies percent.

SELECT  
				Streaming_Movies,
				count(Customer_ID) as Customers_churned,
				round(count(Customer_ID) *100.0 / sum(count(Customer_ID)) OVER(),1) AS Percentage
FROM customer_churn
WHERE Streaming_Movies IS NOT NULL AND Customer_Status  = 'Churned'
GROUP by Streaming_Movies
ORDER by Customers_churned DESC;

----Streaming_Music percent.

SELECT  
				Streaming_Music,
				count(Customer_ID) as Customers_churned,
				round(count(Customer_ID) *100.0 / sum(count(Customer_ID)) OVER(),1) AS Percentage
FROM customer_churn
WHERE Streaming_Music IS NOT NULL AND Customer_Status  = 'Churned'
GROUP by Streaming_Music
ORDER by Customers_churned DESC;

----Streaming_TV percent.

SELECT  
				Streaming_TV,
				count(Customer_ID) as Customers_churned,
				round(count(Customer_ID) *100.0 / sum(count(Customer_ID)) OVER(),1) AS Percentage
FROM customer_churn
WHERE Streaming_TV IS NOT NULL AND Customer_Status  = 'Churned'
GROUP by Streaming_TV
ORDER by Customers_churned DESC;
 
 --Online security percent.

SELECT  
				Online_Security,
				count(Customer_ID) as Customers_churned,
				round(count(Online_Security) *100.0 / sum(count(Online_Security)) OVER(),1) AS Percentage
FROM customer_churn
WHERE Online_Security IS NOT NULL AND Customer_Status  = 'Churned'
GROUP by Online_Security
ORDER by Customers_churned DESC;

--Online backup percent.

SELECT  
				Online_Backup,
				count(Customer_ID) as Customers_churned,
				round(count(Online_Backup) *100.0 / sum(count(Online_Backup)) OVER(),1) AS Percentage
FROM customer_churn
WHERE Online_Backup IS NOT NULL AND Customer_Status  = 'Churned'
GROUP by Online_Backup
ORDER by Customers_churned DESC;

--Device_Protection_Plan percent.

SELECT  
				Device_Protection_Plan,
				count(Customer_ID) as Customers_churned,
				round(count(Device_Protection_Plan) *100.0 / sum(count(Device_Protection_Plan)) OVER(),1) AS Percentage
FROM customer_churn
WHERE Device_Protection_Plan IS NOT NULL AND Customer_Status  = 'Churned'
GROUP by Device_Protection_Plan
ORDER by Customers_churned DESC;

--Unlimited data percent.

SELECT  
				Unlimited_Data,
				count(Customer_ID) as Customers_churned,
				round(count( Unlimited_Data) *100.0 / sum(count(Unlimited_Data)) OVER(),1) AS Percentage
FROM customer_churn
WHERE Unlimited_Data IS NOT NULL AND Customer_Status  = 'Churned'
GROUP by Unlimited_Data
ORDER by Customers_churned DESC;

--3.6 How do offers impact the churn decision?


SELECT Offer,
				  count(Customer_ID) as Customers_Number,
				  round(count( Offer) *100.0 / sum(count(Offer)) OVER(),1) AS Percentage
FROM customer_churn
WHERE Customer_Status = 'Churned'
GROUP by Offer
ORDER by Customers_Number DESC;
 



