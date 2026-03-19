CREATE TABLE bikes (
    bike_num      NUMBER PRIMARY KEY,
    model_name    VARCHAR2(200),
    model_year    NUMBER,
    kms_driven    NUMBER,
    owner         VARCHAR2(50),
    location      VARCHAR2(100),
    mileage       VARCHAR2(30),
    power         NUMBER(8,2),
    price         NUMBER
);

select * from Bikes;

--Query 1: Top 10 Highest-Value Bikes (Power per Rupee Spent) – Best Deals
SELECT *
FROM (
    SELECT 
        bike_num, 
        model_name, 
        model_year, 
        kms_driven, 
        owner, 
        price, 
        power,
        ROUND(power / (price / 100000), 2) AS bhp_per_lakh
    FROM bikes
    WHERE price IS NOT NULL AND price != 0
    ORDER BY bhp_per_lakh DESC
)
WHERE ROWNUM <= 10;
--Impact: Instantly shows which bikes give maximum performance for the money.
--Query 2: Brand-wise Average Price & Count (Dynamic Brand Extraction)

WITH brand_extract AS (
    SELECT 
        CASE 
            WHEN model_name LIKE 'Royal Enfield%' THEN 'Royal Enfield'
            WHEN model_name LIKE 'Harley-Davidson%' THEN 'Harley-Davidson'
            WHEN model_name LIKE 'Ducati%' THEN 'Ducati'
            ELSE REGEXP_SUBSTR(model_name, '^[^ ]+') 
        END AS brand,
        price, model_year
    FROM bikes
)
SELECT 
    brand,
    COUNT(*) AS count,
    ROUND(AVG(price), 0) AS avg_price,
    ROUND(AVG(price) / 1000, 0) AS avg_price_k
FROM brand_extract
GROUP BY brand
ORDER BY avg_price DESC;
--Impact: Identifies premium brands (Royal Enfield, Ducati) for targeted marketing.
--Query 3: Average Price by Owner Type + Year (Market Depreciation Insight)
SELECT 
    owner,
    model_year,
    COUNT(*) AS bikes,
    ROUND(AVG(price), 0) AS avg_price,
    ROUND(AVG(kms_driven), 0) AS avg_kms
FROM bikes
GROUP BY owner, model_year
ORDER BY owner, model_year DESC;
--Impact: Shows how much price drops with each owner – useful for negotiation strategy.
--Query 4: Top 5 Locations with Highest Average Price (Hot Markets)
SELECT *
FROM (
    SELECT 
        location,
        COUNT(*) AS listings,
        ROUND(AVG(price), 0) AS avg_price,
        RANK() OVER (ORDER BY AVG(price) DESC) AS rank
    FROM bikes
    GROUP BY location
)
WHERE ROWNUM <= 5;
--Impact: Pinpoints cities where sellers can list higher prices.
--Query 5: Outlier Detection – Bikes Priced > 2 Std Dev Above Mean (Using Analytic Functions)
WITH stats AS (
    SELECT 
        AVG(price) AS mean_price,
        STDDEV(price) AS std_price
    FROM bikes
)
SELECT 
    bike_num, model_name, price,
    ROUND((price - mean_price)/std_price, 2) AS z_score
FROM bikes, stats
WHERE price > mean_price + 2 * std_price
ORDER BY price DESC;
--Impact: Flags overpriced bikes that need price correction.
--Query 6: Mileage-Adjusted Value Ranking (Clean Numeric Mileage with REGEXP)
SELECT *
FROM (
    SELECT 
        bike_num, 
        model_name, 
        mileage,
        numeric_mileage,
        price,
        ROUND(power / (price / 100000), 2) * numeric_mileage AS value_score
    FROM (
        SELECT 
            bike_num, 
            model_name, 
            mileage,
            price,
            power,
            TO_NUMBER(REGEXP_SUBSTR(mileage, '\d+\.?\d*')) AS numeric_mileage
        FROM bikes
        WHERE REGEXP_LIKE(mileage, '\d')
          AND price IS NOT NULL 
          AND price != 0
    )
    ORDER BY value_score DESC
)
WHERE ROWNUM <= 10;
--Impact: Combines mileage + power + price in one powerful metric.
--Query 7: Year-over-Year Price Trend for Top 3 Brands (Using LAG)
WITH yearly AS (
    SELECT 
        CASE WHEN model_name LIKE 'Royal Enfield%' THEN 'Royal Enfield'
             WHEN model_name LIKE 'Bajaj%' THEN 'Bajaj'
             WHEN model_name LIKE 'Honda%' THEN 'Honda'
             ELSE 'Other' END AS brand,
        model_year,
        AVG(price) AS avg_price
    FROM bikes
    GROUP BY 
        CASE WHEN model_name LIKE 'Royal Enfield%' THEN 'Royal Enfield'
             WHEN model_name LIKE 'Bajaj%' THEN 'Bajaj'
             WHEN model_name LIKE 'Honda%' THEN 'Honda'
             ELSE 'Other' END,
        model_year
)
SELECT 
    brand, model_year, avg_price,
    ROUND(avg_price - LAG(avg_price) OVER (PARTITION BY brand ORDER BY model_year), 0) AS yoy_change
FROM yearly
WHERE brand IN ('Royal Enfield','Bajaj','Honda')
ORDER BY brand, model_year;
--Impact: Shows real appreciation/depreciation trends.
--Query 8: PIVOT – Average Price by Owner Type & ABS Feature
SELECT * FROM (
    SELECT 
        owner,
        CASE WHEN model_name LIKE '%ABS%' THEN 'With ABS' ELSE 'No ABS' END AS abs_feature,
        price
    FROM bikes
)
PIVOT (
    AVG(price) FOR abs_feature IN ('With ABS' AS with_abs, 'No ABS' AS no_abs)
)
ORDER BY owner;
--Impact: Instantly compares premium (ABS) vs non-ABS pricing.
--Query 9: Top 3 Models per Location using LISTAGG + RANK
WITH ranked AS (
    SELECT 
        location,
        model_name,
        ROUND(AVG(price), 0) AS avg_price,
        RANK() OVER (PARTITION BY location ORDER BY AVG(price) DESC) AS rnk
    FROM bikes
    GROUP BY location, model_name
)
SELECT 
    location,
    LISTAGG(model_name || ' (?' || avg_price || ')', ', ') 
        WITHIN GROUP (ORDER BY rnk) AS top_models
FROM ranked
WHERE rnk <= 3
GROUP BY location
ORDER BY location;
--Impact: Ready-to-use marketing report per city.
--Query 10: Best Investment Bikes (Low Kms + High Power + Recent Year) – Composite Score
SELECT *
FROM (
    SELECT 
        bike_num, 
        model_name, 
        model_year, 
        kms_driven, 
        power, 
        price,
        ROUND((power * model_year) / (kms_driven * price / 100000), 2) AS investment_score
    FROM bikes
    WHERE kms_driven < 50000 
      AND model_year >= 2018
      AND kms_driven IS NOT NULL 
      AND kms_driven != 0
      AND price IS NOT NULL 
      AND price != 0
    ORDER BY investment_score DESC
)
WHERE ROWNUM <= 15;
--Impact: Identifies future collector/value-retention bikes.

-------------------------------------------------------
------------------------------------------------------
set SERVEROUTPUT ON;
-- Simple procedure that shows how many bikes exist for each model year
CREATE OR REPLACE PROCEDURE show_bike_count_by_year
AS
    -- Declare variables
    v_year          NUMBER;
    v_count         NUMBER;
    
    -- Declare cursor (a pointer to query results)
    CURSOR c_years IS
        SELECT model_year, COUNT(*) as bike_count
        FROM bikes
        GROUP BY model_year
        ORDER BY model_year DESC;
        
BEGIN
    -- Header
    DBMS_OUTPUT.PUT_LINE('Bike count by model year');
    DBMS_OUTPUT.PUT_LINE('-----------------------------');
    DBMS_OUTPUT.PUT_LINE('Year     Count');
    DBMS_OUTPUT.PUT_LINE('-----------------------------');
    
    -- Loop through each row from the cursor
    FOR rec IN c_years LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(rec.model_year, 8) || rec.bike_count);
    END LOOP;
    
    -- Final message
    DBMS_OUTPUT.PUT_LINE('-----------------------------');
    DBMS_OUTPUT.PUT_LINE('End of report');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END show_bike_count_by_year;
/

-- How to run it:
BEGIN
    show_bike_count_by_year;
END;
/

--------------------------------------------------------------------------
-- Function that returns how old the bike is (simple calculation)
CREATE OR REPLACE FUNCTION get_bike_age(p_model_year IN NUMBER)
RETURN NUMBER
IS
    v_current_year   CONSTANT NUMBER := 2025;   -- we pretend current year is 2025
    v_age            NUMBER;
BEGIN
    -- Basic calculation
    v_age := v_current_year - p_model_year;
    
    -- Safety: don't return negative age
    IF v_age < 0 THEN
        v_age := 0;
    END IF;
    
    RETURN v_age;
END get_bike_age;
/

-- Easy ways to test the function:

-- Test 1: single value
SELECT get_bike_age(2019) AS age FROM dual;

-- Test 2: use in real query
SELECT *
FROM (
    SELECT 
        bike_num,
        model_name,
        model_year,
        get_bike_age(model_year) AS bike_age_years
    FROM bikes
    WHERE model_year IS NOT NULL
    ORDER BY get_bike_age(model_year)
)
WHERE ROWNUM <= 10;

----------------------------------------------------------------------

-- Simple function that classifies bike price into categories
CREATE OR REPLACE FUNCTION get_price_category(p_price IN NUMBER)
RETURN VARCHAR2
IS
    v_category  VARCHAR2(30);
BEGIN
    -- Check for invalid/zero/negative price
    IF p_price IS NULL OR p_price <= 0 THEN
        RETURN 'Invalid Price';
    END IF;

    -- Simple IF-ELSIF logic (very beginner-friendly)
    IF p_price <= 40000 THEN
        v_category := 'Budget';
    ELSIF p_price <= 80000 THEN
        v_category := 'Entry Level';
    ELSIF p_price <= 150000 THEN
        v_category := 'Mid-range';
    ELSIF p_price <= 300000 THEN
        v_category := 'Premium';
    ELSE
        v_category := 'Luxury / Superbike';
    END IF;

    RETURN v_category;
END get_price_category;
/

-- ????????????????????????????????????????????????
-- Ways to test / use the function (run any of these)
-- ????????????????????????????????????????????????

-- Test 1: Single value
SELECT get_price_category(35000) FROM dual;     -- ? Budget

SELECT get_price_category(120000) FROM dual;    -- ? Mid-range

SELECT get_price_category(450000) FROM dual;    -- ? Luxury / Superbike

-- Test 2: Use it inside a real SELECT query
SELECT *
FROM (
    SELECT 
        bike_num,
        model_name,
        price,
        get_price_category(price) AS price_category
    FROM bikes
    WHERE price > 0
    ORDER BY price DESC
)
WHERE ROWNUM <= 12;

-- Test 3: See how many bikes in each category
SELECT 
    get_price_category(price) AS category,
    COUNT(*) AS bike_count,
    ROUND(AVG(price), 0) AS average_price
FROM bikes
WHERE price > 0
GROUP BY get_price_category(price)
ORDER BY average_price;

----------------------------------------------------------------------------
