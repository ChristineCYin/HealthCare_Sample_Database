
# How many total entries are in the provider directory?
SELECT
  COUNT(*) AS total_entries_provider
FROM
  cd_healthcare.providers;


# How many specialists (non-PCPs) are in the directory?
SELECT
  COUNT(id) AS total_non_PCPs
FROM
  cd_healthcare.providers
WHERE
  is_pcp = 0;


# In which states does this healthcare company provide care, according to this data?
SELECT
  DISTINCT SPLIT_PART(city, ', ', 2) AS states
FROM
  cd_healthcare.providers
ORDER BY
  1;


# How many providers are in each state?
SELECT
  SPLIT_PART(city, ', ', 2) AS states,
  COUNT(id) AS total_providers
FROM
  cd_healthcare.providers
GROUP BY
  1
ORDER BY
  1;


# How many total entries are in the member directory?
SELECT
  COUNT(*) AS total_member
FROM
  cd_healthcare.members;


# In which states do members live?
SELECT
  DISTINCT SPLIT_PART(city, ', ', 2) AS states
FROM
  cd_healthcare.members
ORDER BY
  1;


# How many members are in each state?
SELECT
  SPLIT_PART(city, ', ', 2) AS states,
  COUNT(id) AS total_members
FROM
  cd_healthcare.members
GROUP BY
  1
ORDER BY
  1;

#################################################################################################################################
# PCP Customer Service Analysis:
# The operations team is interested in interviewing the top five PCPs who provide the best customer service to their patients.  #
# Conduct an analysis to identify the top five PCPs.                                                                            #
#################################################################################################################################
[Presentation Here](https://github.com/ChristineCYin/Healthcare_Data_Analysis/blob/main/Best%20PCP.pdf)

## Slide 3 - Overview of Active Member ##
# How many active memebers (who have a PCP) in each individual month in 2018
-- The first step is to convert the start and end dates of the member_provider table to the date data type
-- Join provider table to determine if a member has a PCP
WITH converted_date_spans AS (
  SELECT
    -- member_pcp_span's table
    mp.id,
    mp.member_id,
    mp.provider_id,
    mp.plan_id,
    -- Use LEFT, SUBSTR and RIGHT to pull a 2 number of characters and converted to date
    (
      20 || LEFT(mp.start_date, 2) || '-' || SUBSTR(mp.start_date, 3, 2) || '-' || RIGHT(mp.start_date, 2)
    ) :: date AS converted_start_date,
    -- Use 9999/01/01 for an indefinite end date
    CASE
      WHEN mp.end_date = '999999' THEN '9999-01-01' :: date
      ELSE (
        20 || LEFT(mp.end_date, 2) || '-' || SUBSTR(mp.end_date, 3, 2) || '-' || RIGHT(mp.end_date, 2)
      ) :: date
    END AS converted_end_date,
    mp.average_copay,
    mp.pcp_rating,
    -- provider's table
    p.is_pcp AS provider_is_pcp
  FROM
    cd_healthcare.member_provider mp
    LEFT JOIN cd_healthcare.providers p ON mp.provider_id = p.id
) 
-- The second step is to generate a bucket table so I can count for each month based on the duration
-- This step is also locked in 2018. A better approach would be to create a bucket table, save it once and use it forever, 
-- but for now, a temp table will do.
,
monthBucket AS (
  SELECT
    date_trunc('month', dd) :: CHAR(7) AS bucketName,
    date_trunc('day', dd) :: date AS bucketFirstDay,
    (
      date_trunc('month', dd) + '1 month' :: INTERVAL - '1 day' :: INTERVAL
    ) AS bucketLastDay
  FROM
    generate_series (
      '2018-01-01' :: timestamp,
      '2018-12-01' :: timestamp,
      '1 month' :: INTERVAL
    ) dd
) 
-- The last step is to calculate the total number of members who have a PCP in each monthly bucket
SELECT
  bucketName,
  (
    (
      SELECT
        COUNT(member_id)
      FROM
        converted_date_pcp_spans
      WHERE
        converted_start_date <= bucketLastDay
        AND provider_is_pcp = 1
    ) -(
      SELECT
        COUNT(member_id)
      FROM
        converted_date_pcp_spans
      WHERE
        converted_end_date < bucketFirstDay
        AND provider_is_pcp = 1
    )
  ) AS membersCount
FROM
  monthBucket
ORDER BY
  bucketFirstDay 


## Rest of the slides ##
-- Create temp tables of all tables for the rest of the analysis (Timestamp data type converted; city and states separated)
WITH converted_all AS (
  SELECT
    mp.id AS spans_id,
    mp.member_id,
    mp.provider_id,
    mp.plan_id,
    (
      20 || LEFT(mp.start_date, 2) || '-' || SUBSTR(mp.start_date, 3, 2) || '-' || RIGHT(mp.start_date, 2)
    ) :: date AS converted_start_date,
    CASE
      WHEN mp.end_date = '999999' THEN '9999-01-01' :: date
      ELSE (
        20 || LEFT(mp.end_date, 2) || '-' || SUBSTR(mp.end_date, 3, 2) || '-' || RIGHT(mp.end_date, 2)
      ) :: date
    END AS converted_end_date,
    mp.average_copay,
    mp.pcp_rating,
    p.name AS provider_name,
    SPLIT_PART(p.city, ', ', 1) AS provider_city,
    SPLIT_PART(p.city, ', ', 2) AS provider_states,
    m.name AS member_name,
    SPLIT_PART(m.city, ', ', 1) AS member_city,
    SPLIT_PART(m.city, ', ', 2) AS member_states,
    m.birth_date,
    m.health_risk_score
  FROM
    cd_healthcare.member_provider mp
    LEFT JOIN cd_healthcare.providers p ON mp.provider_id = p.id
    LEFT JOIN cd_healthcare.members m ON mp.member_id = m.id
) 


## Slide 4 - Distribution of Current Active Member by State ##
-- currently (as of 12/31/18) 
SELECT
  provider_states,
  COUNT(DISTINCT provider_id) AS total_provider,
  COUNT(DISTINCT member_id) AS total_memeber
FROM
  converted_all
WHERE
  converted_end_date > '2018-12-01' :: date
  AND provider_id IS NOT NULL
GROUP BY
  1
ORDER BY
  1 


## Slide 6 - Rating By States ##
SELECT
  provider_states,
  SUM(
    CASE
      WHEN pcp_rating = 5 THEN 1
      ELSE 0
    END
  ) AS Total_five_rating,
  COUNT(pcp_rating) AS total_give_rating,
  COUNT(DISTINCT member_id) - COUNT(pcp_rating) AS total_not_give_rating,
  COUNT(DISTINCT member_id) AS Total_member,
  SUM(
    CASE
      WHEN pcp_rating = 5 THEN 1
      ELSE 0
    END
  ) * 100.0 / COUNT(pcp_rating) AS CSAT,
  AVG(pcp_rating) AS avg_rating
FROM
  converted_all
WHERE
  converted_end_date > '2018-12-01' :: date
  AND provider_id IS NOT NULL
GROUP BY
  1
ORDER BY
  CSAT DESC 
  

## Slide 7 - CSAT by Provider ##
-- Top 5 CSAT of each states by provider
SELECT
  *
FROM
  (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY provider_states
        ORDER BY
          CSAT DESC
      ) AS ROW
    FROM
      (
        SELECT
          provider_id,
          provider_states,
          SUM(
            CASE
              WHEN pcp_rating = 5 THEN 1
              ELSE 0
            END
          ) AS Total_five_rating,
          COUNT(pcp_rating) AS total_give_rating,
          COUNT(DISTINCT member_id) AS Total_member,
          SUM(
            CASE
              WHEN pcp_rating = 5 THEN 1
              ELSE 0
            END
          ) * 100.0 / COUNT(pcp_rating) AS CSAT,
          AVG(pcp_rating) AS avg_rating
        FROM
          converted_all
        WHERE
          converted_end_date > '2018-12-01' :: date
          AND provider_id IS NOT NULL
        GROUP BY
          1,
          2
        ORDER BY
          2,
          6 DESC
      ) A
  ) B
WHERE
  ROW <= 5


