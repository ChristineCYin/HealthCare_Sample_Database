# Healthcare_Data_Analysis

I am Data Analyst working at CDHealthcare. I have been tasked with recommending three Primary Care Providers (PCPs) with good customer service for interviews by the operations team to improve our customer experience.

The following table are provided

1. 
- Table name: Members
- Desciption: All CDHealthcare members

| Column        | Type           | Descr  |
| ------------- |:-------------:| -----:|
| id      | integer | member id |
| name      | text      |  member name |
| city | text      |    City which the member lives |

2. 
- Table name: Providers
- Desciption: All CDHealthcare providers

| Column        | Type           | Descr  |
| ------------- |:-------------:| -----:|
| id      | integer | provider id |
| name      | text      |  provider name |
| city | text      |    City which the provider practices |
| is_pcp | integer      |  primary care provider (1); otherwise (0)|

3. 
- Table name: Member_Provider
- Desciption: Linkage between member and provider

| Column        | Type           | Descr  |
| ------------- |:-------------:| -----:|
| id      | integer | link id |
| member_id      | integer | member id |
| provider_id      | integer | provider id |
| plan_id      | integer | core(0); prime(1) |
| start_date      | text      |  start date of the member-pcp relationship |
| end_date      | text      |  end date of the member-pcp relationship |
| pcp_rating      | real      |  member rate their provider |
