# Database Description

This is a HealthCare Sample Database representing CDHealthcare, a healthcare company, consisting of three tables: `Members`, `Providers`, and `Member_Provider`.

## Table `Members`

All members who have been active at CDHealthcare, with each member being assigned a unique ID.

| Column        | Type           | Description  |
| :------: | :------:|  :--------- |
| id      | integer | Unique member id |
| name      | text      |  member name |
| city | text      |    City in which the member lives |
| birth_date | text      |    member's birth date |
| health_risk_score | real      |    A risk score is assigned to each member <br> by the Centers for Medicare and Medicaid Services, <br> with higher scores indicating a greater risk level for the member. |



## Table `Providers`
All providers who have a contract with CDHealthcare, and each provider has been assigned a unique ID.

| Column        | Type           | Descr  |
| ------------- |:-------------:| :-----|
| id      | integer | Unique provider id |
| name      | text      |  provider name |
| city | text      |    City in which the provider practices |
| is_pcp | integer      |  If the provider is a Primary Care Provider (PCP),<br>  the value is 1; otherwise, it is 0.|

## Table `Member_Provider`
This table includes information about the CDHealthcare plan, the relationships between members and their Primary Care Providers (PCPs), and the start and end dates of these relationships, with each relationship being assigned a unique ID. 
At the end of the calendar year, or if the member changes providers or plans, the member can choose to report the average copay they paid for visits to their current provider and/or rate their provider on a scale of 1 to 5.


| Column        | Type           | Descr  |
| ------------- |:-------------:| :-----|
| id      | integer | Unique member&pcp relationship id |
| member_id      | integer | Unique member id |
| provider_id      | integer | Unique provider id |
| plan_id      | integer | CDHealthcare plan in which the member is enrolled.<br> Members can choose between Plan 0 (Core) or Plan 1 (Prime). |
| start_date      | text      |  start date of the member&pcp relationship |
| end_date      | text      |  end date of the member&pcp relationship |
| average_copay      | text      |  member report the average copay they paid for visits to their current provider. |
| pcp_rating      | real      |   member rate their provider (scale of 1 to 5) |
