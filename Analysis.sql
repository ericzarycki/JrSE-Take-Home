-- Reference: For handling Date Values since Postgres messed up the Date/Time Values on Import
SELECT "Planned_Start_DT" at TIME ZONE 'UTC'
FROM "ProjectPlanning" pp ;

SELECT * 
FROM "ProjectPlanning" pp 

-- Exploratory Data Analysis

-- How many acitivties are there? 1,350
SELECT COUNT(DISTINCT "Activity_ID" )
FROM "ProjectPlanning" pp 

-- How many WBS_CDs are there? 360

SELECT COUNT(DISTINCT "WBS_CD" )
FROM "ProjectPlanning" pp 

--
SELECT "Primary_Constraint",
COUNT(DISTINCT "Activity_ID")
FROM "ProjectPlanning" pp
WHERE "Primary_Constraint" IS NOT NULL
GROUP BY "Primary_Constraint" 
ORDER BY 2 DESC

-- 
SELECT DISTINCT "Sec_Constraint" 
FROM "ProjectPlanning" pp 

-- Activity Status
SELECT "Activity_Status",
COUNT(*)
FROM "ProjectPlanning" pp 
GROUP BY "Activity_Status" 

-- Count of Activities with 100 % Complete
SELECT COUNT(DISTINCT "Activity_ID"),
"Activity_Complete_PCNT" 
FROM "ProjectPlanning" pp 
WHERE "Activity_Complete_PCNT" = '100'
GROUP BY "Activity_Complete_PCNT" 


-- Float
--How many activities have a total float of 0? --228 -16% of activities have a total float of 0
SELECT
  COUNT(DISTINCT CASE WHEN "Total_Float" = 0 THEN "Activity_ID" END) AS Float_0,
  COUNT(DISTINCT CASE WHEN "Total_Float" BETWEEN 1 AND 5 THEN "Activity_ID" END) AS Float_1_5,
  COUNT(DISTINCT CASE WHEN "Total_Float" BETWEEN 6 AND 10 THEN "Activity_ID" END) AS Float_6_10,
  COUNT(DISTINCT CASE WHEN "Total_Float" > 10 THEN "Activity_ID" END) AS Float_Over_10
FROM "ProjectPlanning" pp
WHERE "Total_Float" IS NOT NULL;


-- What is the scope of the data?
-- Minimum Feb 19, 2020
-- Maximum October 9th, 2021
SELECT
  MIN("Planned_Start_DT" AT TIME ZONE 'UTC') AS min_planned_start,
  MAX("Planned_Start_DT" AT TIME ZONE 'UTC') AS max_planned_start,
  MIN("Actual_Start_DT" AT TIME ZONE 'UTC') AS min_actual_start,
  MAX("Actual_Start_DT" AT TIME ZONE 'UTC') AS max_actual_start,
  MIN("Planned_Finish_DT" AT TIME ZONE 'UTC') AS min_planned_finish,
  MAX("Planned_Finish_DT" AT TIME ZONE 'UTC') AS max_planned_finish,
  MIN("Actual_Finish_DT" AT TIME ZONE 'UTC') AS min_actual_finish,
  MAX("Actual_Finish_DT" AT TIME ZONE 'UTC') AS max_actual_finish
FROM "ProjectPlanning" pp;

-- What % of activities start on time?
with cte as (
SELECT "Activity_ID" 
, "Activity_Name" 
,  "Planned_Start_DT" AT TIME ZONE 'UTC' AS planned_start_local
,  "Actual_Start_DT" AT TIME ZONE 'UTC' AS actual_start_local
,  "Planned_Finish_DT" AT TIME ZONE 'UTC' AS planned_finish_local
,  "Actual_Finish_DT" AT TIME ZONE 'UTC' AS actual_finish_local
,  DATE_PART('day', "Actual_Start_DT" - "Planned_Start_DT") AS start_delay_days
,  DATE_PART('day', "Actual_Finish_DT" - "Planned_Finish_DT") AS finish_delay_days
,    CASE 
        WHEN "Actual_Start_DT" IS NULL THEN 'No Data'
        WHEN DATE_PART('day', "Actual_Start_DT" - "Planned_Start_DT") < 0 THEN 'Early'
        WHEN DATE_PART('day', "Actual_Start_DT" - "Planned_Start_DT") = 0 THEN 'On Time'
        ELSE 'Delayed'
    END AS start_delay_category
,    CASE 
        WHEN "Actual_Finish_DT" IS NULL THEN 'No Data'
        WHEN DATE_PART('day', "Actual_Finish_DT" - "Planned_Finish_DT") < 0 THEN 'Early'
        WHEN DATE_PART('day', "Actual_Finish_DT" - "Planned_Finish_DT") = 0 THEN 'On Time'
        ELSE 'Delayed'
    END AS finish_delay_category
FROM "ProjectPlanning" pp 
)
SELECT *
FROM cte
WHERE start_delay_category = 'Delayed'

--
SELECT start_delay_category,
COUNT(*)
FROM cte
GROUP BY start_delay_category 
ORDER BY 2 DESC
-- 85 % of activities have an early start
-- 12% start on time
-- 2% are delayed

-- What % of activties finish on time?
with cte as (
SELECT "Activity_ID" 
, "Activity_Name" 
, "WBS_CD"
, "Resources"
,  "Planned_Start_DT" AT TIME ZONE 'UTC' AS planned_start_local
,  "Actual_Start_DT" AT TIME ZONE 'UTC' AS actual_start_local
,  "Planned_Finish_DT" AT TIME ZONE 'UTC' AS planned_finish_local
,  "Actual_Finish_DT" AT TIME ZONE 'UTC' AS actual_finish_local
,  DATE_PART('day', "Actual_Start_DT" - "Planned_Start_DT") AS start_delay_days
,  DATE_PART('day', "Actual_Finish_DT" - "Planned_Finish_DT") AS finish_delay_days
,    CASE 
        WHEN "Actual_Start_DT" IS NULL THEN 'No Data'
        WHEN DATE_PART('day', "Actual_Start_DT" - "Planned_Start_DT") < 0 THEN 'Early'
        WHEN DATE_PART('day', "Actual_Start_DT" - "Planned_Start_DT") = 0 THEN 'On Time'
        ELSE 'Delayed'
    END AS start_delay_category
,    CASE 
        WHEN "Actual_Finish_DT" IS NULL THEN 'No Data'
        WHEN DATE_PART('day', "Actual_Finish_DT"::date - "Planned_Finish_DT") < 0 THEN 'Early'
        WHEN DATE_PART('day', "Actual_Finish_DT" - "Planned_Finish_DT") = 0 THEN 'On Time'
        ELSE 'Delayed'
    END AS finish_delay_category
FROM "ProjectPlanning" pp 
)
SELECT *
FROM cte
WHERE finish_delay_category = 'Delayed'


SELECT finish_delay_category,
COUNT(*)
FROM cte
GROUP BY finish_delay_category 
ORDER BY 2 DESC
-- 65% of activities finish early
-- 17.6% finish on time
-- 17.6 are delayed


-- Budgeted Labor Units Analysis
with cte as (
SELECT "Activity_ID",
"WBS_CD",
"Resources",
SUM("Budgeted_Labor_Units") as SUM_BLU
FROM "ProjectPlanning" pp 
GROUP BY "Activity_ID",
"WBS_CD",
"Resources"
)
SELECT DISTINCT "Resources",
SUM(SUM_BLU)
FROM cte
GROUP BY "Resources"

-- Activities

SELECT COUNT(DISTINCT "Activity_ID"),
"Resources"
FROM "ProjectPlanning" pp 
WHERE "Resources" IS NOT NULL
GROUP BY "Resources"
ORDER BY 1 DESC
