### Taking a brief glance at the database:
``` mysql
-- Returns random sample of 10 rows from cd_healthcare.members
  SELECT * FROM cd_healthcare.members 
  ORDER BY RANDOM( )
  LIMIT 10;
```
![image.png](attachment:image.png)

``` mysql
-- Returns random sample of 10 row from cd_healthcare.providers
  SELECT * FROM cd_healthcare.providers 
  ORDER BY RANDOM( )
  LIMIT 10;
```
![image-2.png](attachment:image-2.png)

``` mysql
-- Returns random sample of 10 row from cd_healthcare.member_provider
  SELECT * FROM cd_healthcare.member_pcp_spans 
  ORDER BY RANDOM( )
  LIMIT 10;
```
![image-4.png](attachment:image-4.png)

[Field Descriptions](https://github.com/ChristineCYin/HealthCare_Sample_Database/blob/main/Field%20Descriptions.md)

### How many total entries are in the provider directory?
``` mysql
SELECT
  COUNT(*) AS total_entries_provider
FROM
  cd_healthcare.providers;
```
![image.png](attachment:image.png) 

###  How many specialists (non-PCPs) are in the directory?
``` mysql
SELECT
  COUNT(id) AS total_non_PCPs
FROM
  cd_healthcare.providers
WHERE
  is_pcp = 0;
```

###  In which states does this healthcare company provide care, according to this data?
``` mysql
SELECT
  DISTINCT SPLIT_PART(city, ', ', 2) AS states
FROM
  cd_healthcare.providers
ORDER BY
  1;
```

### How many providers are in each state?
``` mysql
SELECT
  SPLIT_PART(city, ', ', 2) AS states,
  COUNT(id) AS total_providers
FROM
  cd_healthcare.providers
GROUP BY
  1
ORDER BY
  1;
```

###  How many total entries are in the member directory?
``` mysql
SELECT
  COUNT(*) AS total_member
FROM
  cd_healthcare.members;
```

###  In which states do members live?
``` mysql
SELECT
  DISTINCT SPLIT_PART(city, ', ', 2) AS states
FROM
  cd_healthcare.members
ORDER BY
  1;
```

### How many members are in each state?
``` mysql
SELECT
  SPLIT_PART(city, ', ', 2) AS states,
  COUNT(id) AS total_members
FROM
  cd_healthcare.members
GROUP BY
  1
ORDER BY
  1;
```


```python

```
