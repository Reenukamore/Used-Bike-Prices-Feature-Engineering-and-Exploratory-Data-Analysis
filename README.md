# Used Bike Prices – Feature Engineering and Exploratory Data Analysis

## Project Overview

This project focuses on analyzing used bike data to uncover pricing patterns, performance insights, and market trends. It combines feature engineering, advanced SQL queries, and PL/SQL programming to evaluate factors such as mileage, power, price, brand, and location. The goal is to identify best-value bikes, detect outliers, and understand depreciation and investment potential in the used bike market.

## Dataset Description

The dataset includes the following columns:
- model_name: Name of the bike model  
- model_year: Manufacturing year  
- kms_driven: Total kilometers driven  
- owner: Ownership category (first, second, etc.)  
- location: City or region of sale  
- mileage: Fuel efficiency  
- power: Engine power  
- price: Selling price  
- cc: Engine capacity  
- brand: Bike brand  

## Tech Stack
- Oracle SQL  
- PL/SQL  
- Excel (Data Cleaning & Preprocessing)  

## Project Workflow

### Data Cleaning (Excel)
- Cleaned and preprocessed raw data  
- Removed null and inconsistent values  
- Standardized formats for mileage, price, and power  
- Ensured data consistency and integrity  

### Data Analysis (SQL - Oracle)
- Imported cleaned dataset into Oracle  
- Performed advanced SQL queries for feature engineering and insights  

## SQL Query Descriptions

1. Identified top bikes offering highest performance per price (best deals).  
2. Analyzed brand-wise average price and listing count.  
3. Studied price depreciation based on ownership and manufacturing year.  
4. Identified top locations with highest average bike prices.  
5. Detected overpriced bikes using statistical outlier analysis.  
6. Created a combined value score using mileage, power, and price.  
7. Analyzed year-over-year price trends for major brands.  
8. Compared pricing between bikes with and without ABS feature.  
9. Identified top-performing bike models per location.  
10. Calculated investment score to find high-value bikes with low usage and recent models.  

## PL/SQL Scripts

### PL/SQL Script Descriptions

1. Procedure to display count of bikes grouped by model year using cursor.  
2. Function to calculate the age of a bike based on its model year.  
3. Function to categorize bikes into price segments (Budget to Luxury).  

## Dashoard  

## Conclusion

This project demonstrates strong skills in SQL analytics, feature engineering, and PL/SQL programming. It provides valuable insights into the used bike market, helping buyers make informed decisions and sellers optimize pricing strategies.
