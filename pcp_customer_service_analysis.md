# PCP Customer Service Analysis:
The operations team is interested in interviewing the top five PCPs who provide the best customer service to their patients. 
Conduct an analysis to identify the top five PCPs and provide recommendations.

## For every individual month in 2018, how many members have a PCP?

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
```
![image](https://user-images.githubusercontent.com/28497315/233472438-9ca3fabd-b7d0-4135-8dba-b143d4d225c9.png)

## Distribution of Current Active Member by State
- currently (as of 12/31/18) 

``` mysql
SELECT provider_states,
       COUNT(DISTINCT provider_id) AS total_provider,
       COUNT(DISTINCT member_id) AS total_memeber
FROM converted_all
WHERE converted_end_date > '2018-12-01' :: date
  AND provider_id IS NOT NULL
GROUP BY 1
ORDER BY 1;
```
![image](https://user-images.githubusercontent.com/28497315/233473592-7b1ab939-0256-4274-afca-4476fd556872.png)

![image](https://user-images.githubusercontent.com/28497315/233473665-ca4277e1-4045-425c-bcc1-4dd7b7addb18.png)
![image](https://user-images.githubusercontent.com/28497315/233474233-5e3a966f-6f6b-485d-8f4f-24e7abb50115.png)

- The total number of members in each state is very similar(left graph), but the total number of providers has some notable differences in some states (right graph, for example: Idaho has 2.4 times as many providers as Alaska). 
- This can create a difference in customer experience, an issue to keep in mind in this program.

## Customer satisfaction (CSAT)
- Customer satisfaction (CSAT) is a measure of how happy your customers are.
- At the end of a calendar year, or when the member changes providers or plans, the member can optionally rate their provider (the provider on this span) on a scale of 1 to 5.
- How to calculate Customer satisfaction (CSAT):
[`Number of positive responses (rating = 5)` / `Number of total responses`] x 100 = `CSAT(%)`

### Rating By States
``` mysql
SELECT provider_states,
    SUM(CASE WHEN pcp_rating = 5
             THEN 1 
             ELSE 0
             END) AS Total_five_rating,
    COUNT(pcp_rating) AS total_give_rating,
    COUNT(DISTINCT member_id) - COUNT(pcp_rating) AS total_not_give_rating,
    COUNT(DISTINCT member_id) AS Total_member,
    SUM(CASE WHEN pcp_rating = 5 
             THEN 1
             ELSE 0
             END) * 100.0 / COUNT(pcp_rating) AS CSAT,
    AVG(pcp_rating) AS avg_rating
FROM converted_all
WHERE converted_end_date > '2018-12-01'::date
  AND provider_id IS NOT NULL
GROUP BY 1
ORDER BY CSAT DESC;
```
![image](https://user-images.githubusercontent.com/28497315/233478366-d1fa450c-25fe-45d9-a974-78abcbf8ae3a.png)

![image](https://user-images.githubusercontent.com/28497315/233478399-001e06e9-1c24-42e7-8c1f-3215afb2c680.png)
![image](https://user-images.githubusercontent.com/28497315/233478448-07c33a90-b78e-45e9-954f-eeb043c82e08.png)

- While leaving a comment is optional, we still have a 30% in average response rate, with little variation across states. 
- The highest CSAT rating is ID(Idaho) of 15.2, followed by FL(Florida) and AK(Alaska). 

### CSAT by Provider
Top 5 CSAT of each states by provider
 
``` mysql
SELECT *
FROM
  (SELECT *,
          ROW_NUMBER() OVER (PARTITION BY provider_states ORDER BY CSAT DESC) AS ROW
    FROM
      (SELECT provider_id,
              provider_states,
              SUM(CASE WHEN pcp_rating = 5 
                       THEN 1
                       ELSE 0
                       END) AS Total_five_rating,
              COUNT(pcp_rating) AS total_give_rating,
              COUNT(DISTINCT member_id) AS Total_member,
              SUM(CASE WHEN pcp_rating = 5 
                       THEN 1
                       ELSE 0
                       END) * 100.0 / COUNT(pcp_rating) AS CSAT,
              AVG(pcp_rating) AS avg_rating
        FROM converted_all
        WHERE converted_end_date > '2018-12-01'::date
          AND provider_id IS NOT NULL
        GROUP BY 1,2
        ORDER BY 2, 6 DESC
      ) A
  ) B
WHERE ROW <= 5
```

![image](https://user-images.githubusercontent.com/28497315/233479754-5bae072a-2398-472e-8621-1778658bf113.png)

![image](https://user-images.githubusercontent.com/28497315/233480015-063cdc20-93d6-4937-b939-9570622d6de0.png)


- Idaho do ranks first in the state rankings with more providers, however, We can see that its score for each provides is relatively scattered, the gap between the first and the last is still very large. 
- Alaska performed more consistently despite having relatively few providers, ranking third among the states.

## Recommendations
- Which three PCPs would you recommend?

![image](https://user-images.githubusercontent.com/28497315/233480092-fb87f77e-c41e-491e-b334-fcdcd5bd4a67.png)

  - I recommend interviewing the top 3 CSAT providers and understanding why they have a high CSAT. 2 providers from ID and 1 provider from FL. (especially provider ID 1730452909, 14 out of 30 people gave this provider a 5 star rating!)
- Further Exploration for v2:
  - Member retention rate, how long has this member been with this provider?
    -  how long the member has been with the provider, it can also indicate how satisfied the member is with the provider.
  - What is the impact of having a more average number of providers for each states?


