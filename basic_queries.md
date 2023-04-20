### Taking a brief glance at the database:
``` mysql
-- Returns random sample of 10 rows from cd_healthcare.members
  SELECT * 
  FROM cd_healthcare.members 
  ORDER BY RANDOM( )
  LIMIT 10;
```
![image](https://user-images.githubusercontent.com/28497315/233213337-1a67b4dc-cccc-46f3-925a-3edb041eeb92.png)

``` mysql
-- Returns random sample of 10 row from cd_healthcare.providers
  SELECT * 
  FROM cd_healthcare.providers 
  ORDER BY RANDOM( )
  LIMIT 10;
```
![image](https://user-images.githubusercontent.com/28497315/233213403-cbd40cd2-c5a1-4979-b815-18d860b8b1ea.png)

``` mysql
-- Returns random sample of 10 row from cd_healthcare.member_provider
  SELECT * 
  FROM cd_healthcare.member_provider 
  ORDER BY RANDOM( )
  LIMIT 10;
```
![image](https://user-images.githubusercontent.com/28497315/233213563-89f5bc4b-2c67-4d78-8640-fc9f6df11c6f.png)

For more information, [Field Descriptions](https://github.com/ChristineCYin/HealthCare_Sample_Database/blob/main/Field%20Descriptions.md)

### How many total entries are in the provider directory?
``` mysql
SELECT COUNT(*) AS total_entries_provider
FROM cd_healthcare.providers;
```
![image](https://user-images.githubusercontent.com/28497315/233212052-3b056add-d2d1-4063-a7bc-21d6a2d677d7.png) 

###  How many specialists (non-PCPs) are in the directory?
``` mysql
SELECT COUNT(id) AS total_non_PCPs
FROM cd_healthcare.providers
WHERE is_pcp = 0;
```
![image](https://user-images.githubusercontent.com/28497315/233214679-cc41f167-6cea-451e-ab40-b2678da96e5b.png)

###  In which states does this healthcare company provide care, according to this data?
``` mysql
SELECT DISTINCT SPLIT_PART(city, ', ', 2) AS states
FROM cd_healthcare.providers
ORDER BY 1;
```
![image](https://user-images.githubusercontent.com/28497315/233214748-0db25695-9322-4cc1-a005-c49c960833bf.png)

### How many providers are in each state?
``` mysql
SELECT SPLIT_PART(city, ', ', 2) AS states,
       COUNT(id) AS total_providers
FROM cd_healthcare.providers
GROUP BY 1
ORDER BY 1;
```
![image](https://user-images.githubusercontent.com/28497315/233216111-fad309c3-ce2a-4aa5-977c-8a6026d42ba3.png)

###  How many total entries are in the member directory?
``` mysql
SELECT COUNT(*) AS total_member
FROM cd_healthcare.members;
```
![image](https://user-images.githubusercontent.com/28497315/233216186-3d082b30-e3dd-4240-9b37-4ae6e505702e.png)

###  In which states do members live?
``` mysql
SELECT DISTINCT SPLIT_PART(city, ', ', 2) AS states
FROM cd_healthcare.members
ORDER BY 1;
```
![image](https://user-images.githubusercontent.com/28497315/233216299-7aec84f9-0bde-44a2-a8da-1d7d3cbd1356.png)

### How many members are in each state?
``` mysql
SELECT SPLIT_PART(city, ', ', 2) AS states,
       COUNT(id) AS total_members
FROM cd_healthcare.members
GROUP BY 1
ORDER BY 1;
```
![image](https://user-images.githubusercontent.com/28497315/233216418-caf72174-fc47-44d0-87c9-0f4cdbae2c27.png)
