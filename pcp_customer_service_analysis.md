## PCP Customer Service Analysis:
The operations team is interested in interviewing the top five PCPs who provide the best customer service to their patients. 
Conduct an analysis to identify the top five PCPs and provide recommendations.

### For every individual month in 2018, how many members have a PCP?

#### Data Cleaning
Convert the date to a timestamp data type for more efficient analysis

``` mysql
WITH converted_date_pcp_spans AS (
  SELECT mp.id,
         mp.member_id, 
         mp.provider_id, 
         mp.plan_id,
         -- Use LEFT, SUBSTR and RIGHT to pull a 2 number of characters and converted to date
         (20||LEFT(mp.start_date, 2) || '-' ||SUBSTR(mp.start_date, 3, 2) || '-' ||RIGHT(mp.start_date, 2) )::date AS converted_start_date,
         -- Use 9999/01/01 for an indefinite end date
         CASE WHEN mp.end_date = '999999'
              THEN '9999-01-01'::date
              ELSE (20||LEFT(mp.end_date, 2) || '-' ||SUBSTR(mp.end_date, 3, 2) || '-' ||RIGHT(mp.end_date, 2) )::date 
              END AS converted_end_date,
         mp.average_copay, 
         mp.pcp_rating, 
         p.is_pcp AS provider_is_pcp,
         SPLIT_PART(p.city, ', ', 2) AS provider_states
  FROM cd_healthcare.member_provider mp
    LEFT JOIN cd_healthcare.providers p ON mp.provider_id = p.id
)
-- continue
```
![image](https://user-images.githubusercontent.com/28497315/233461750-8b163fce-49a3-4959-87c0-19b3abbdc5f5.png)

#### Generate a bucket table so I can count for each month based on the duration
This step is also locked in 2018. A better approach would be to create a bucket table, save it once and use it forever, 
but for now, a temp table will do.

##### `FROM` `GENERATE_SERIES`

``` mysql
  SELECT *
  FROM GENERATE_SERIES ('2018-01-01'::timestamp,'2018-12-01'::timestamp, '1 month'::interval) dd
``` 
![image](https://user-images.githubusercontent.com/28497315/233464026-155187f5-49c5-4ebd-8a8c-6db4b06f2405.png)

##### Clean the format of the monthBucket table
``` mysql
-- continue
, monthBucket AS (
    SELECT DATE_TRUNC('month', dd)::CHAR(7) AS bucketName, 
           DATE_TRUNC('day', dd)::date AS bucketFirstDay, 
           (DATE_TRUNC('month', dd) + '1 month'::interval - '1 day'::interval) AS bucketLastDay
    FROM generate_series ('2018-01-01'::timestamp,'2018-12-01'::timestamp, '1 month'::interval) dd
)
-- continue
```
![image](https://user-images.githubusercontent.com/28497315/233464342-8e1e47c4-08d8-4110-99cb-6ed442a13c36.png)

#### Calculate the total number of members with PCP based on the month bucket
``` mysql
-- continue
SELECT bucketName, 
        ((
          SELECT COUNT(member_id) 
          FROM converted_date_pcp_spans 
          WHERE converted_start_date <= bucketLastDay 
          AND provider_is_pcp =1
          )-(
          SELECT COUNT(member_id)
          FROM converted_date_pcp_spans
          WHERE converted_end_date < bucketFirstDay 
          AND provider_is_pcp =1
          )) AS membersCount
FROM monthBucket
ORDER BY bucketFirstDay
)
-- end
```
![image](https://user-images.githubusercontent.com/28497315/233465481-b9a89898-cb14-4bd1-a519-9636621529d8.png)

### Overview of Active Member

![image](https://user-images.githubusercontent.com/28497315/233466816-f8622837-e0a2-4546-8dca-a994a09aebad.png)
- In 2018, the CDHealthcare’s overall growth is good, and it is growing steadily every month
- As of December 2018, we have a total of 8663 active members. We will base our analysis on these members. 

### Create temp tables of all tables for the rest of the analysis 
- Timestamp data type converted
- City and states separated
``` mysql
WITH converted_all AS (
  SELECT mp.id AS spans_id,
         mp.member_id,
         mp.provider_id,
         mp.plan_id,
         (20 || LEFT(mp.start_date, 2) || '-' || SUBSTR(mp.start_date, 3, 2) || '-' || RIGHT(mp.start_date, 2))::date AS converted_start_date,
         CASE WHEN mp.end_date = '999999' 
             THEN '9999-01-01' :: date
             ELSE (20 || LEFT(mp.end_date, 2) || '-' || SUBSTR(mp.end_date, 3, 2) || '-' || RIGHT(mp.end_date, 2))::date
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
  FROM cd_healthcare.member_provider mp
    LEFT JOIN cd_healthcare.providers p ON mp.provider_id = p.id
    LEFT JOIN cd_healthcare.members m ON mp.member_id = m.id
) 

![image](https://user-images.githubusercontent.com/28497315/233472438-9ca3fabd-b7d0-4135-8dba-b143d4d225c9.png)
