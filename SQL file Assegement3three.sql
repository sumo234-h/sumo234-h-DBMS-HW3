CREATE DATABASE global_energy;

USE global_energy;


-- ALL the table 
-- All the table with PK and FK 

CREATE TABLE countries (
    countrycode VARCHAR(3) PRIMARY KEY,
    countryname VARCHAR(100),
    continent VARCHAR(50)
); 

CREATE TABLE operators (
    operatorid INT PRIMARY KEY,
    operatorname VARCHAR(100),
    headquarterscountry VARCHAR(3),
    FOREIGN KEY (headquarterscountry)
        REFERENCES countries(countrycode)
);

CREATE TABLE fuel_types (
    fuelid INT PRIMARY KEY,
    fuelcategory VARCHAR(50),
    fuelname VARCHAR(50)
);

CREATE TABLE power_plants (
    plantid INT PRIMARY KEY,
    plantname VARCHAR(100),
    countrycode VARCHAR(3),
    operatorid INT,
    fuelid INT,
    capacitymw INT,
    commissionyear INT,
    FOREIGN KEY (countrycode)
        REFERENCES countries(countrycode),
       FOREIGN KEY (operatorid)
        REFERENCES operators(operatorid),
    FOREIGN KEY (fuelid)
        REFERENCES fuel_types(fuelid)
);



CREATE TABLE generation_records (
    plantid INT,
    year INT,
    generationgwh DECIMAL(12,2),
    PRIMARY KEY (plantid, year),
    FOREIGN KEY (plantid)
        REFERENCES power_plants(plantid)
);


CREATE TABLE emission_metrics (
      plantid INT,
       year INT,
    co2emissionstonnes DECIMAL(15,2),
    PRIMARY KEY (plantid, year),
    FOREIGN KEY (plantid)
        REFERENCES power_plants(plantid)
);

-- end of the table 

-- Query 1
-- Displays each power plant with its country, operator, fuel type,
-- capacity, and commission year, sorted from highest to lowest capacity.
SELECT
      power_plants.plantname,
    countries.countryname,
    operators.operatorname,
    fuel_types.fuelcategory,
      fuel_types.fuelname,
    power_plants.capacitymw,
    power_plants.commissionyear
  FROM power_plants
   JOIN countries
       ON power_plants.countrycode = countries.countrycode
   JOIN operators
    ON power_plants.operatorid = operators.operatorid
   JOIN fuel_types
    ON power_plants.fuelid = fuel_types.fuelid
    ORDER BY power_plants.capacitymw DESC;


-- Query 2
-- Displays each power plant's generation for the year 2024,
-- sorted from highest to lowest generation.
  SELECT
       power_plants.plantname,
    power_plants.countrycode,
       generation_records.year,
         generation_records.generationgwh
    FROM power_plants
    JOIN generation_records
    ON power_plants.plantid = generation_records.plantid
WHERE generation_records.year = 2024
     ORDER BY generation_records.generationgwh DESC;


-- Query 3
-- Displays each power plant's generation and CO2 emissions for 2024,
-- sorted from lowest to highest CO2 emissions.
SELECT
      power_plants.plantname,
       power_plants.countrycode,
    generation_records.year,
      generation_records.generationgwh,
      emission_metrics.co2emissionstonnes
  FROM power_plants
  JOIN generation_records
      ON power_plants.plantid = generation_records.plantid
   JOIN emission_metrics
      ON power_plants.plantid = emission_metrics.plantid
      AND generation_records.year = emission_metrics.year
   WHERE generation_records.year = 2024
   ORDER BY emission_metrics.co2emissionstonnes ASC;


-- Query 4
-- Uses a CTE to calculate the total power generation for each operator
-- and sorts the results from highest to lowest total generation.
WITH operator_generation AS (
    SELECT
           power_plants.operatorid,
          SUM(generation_records.generationgwh) AS total_generation
       FROM power_plants
       JOIN generation_records
           ON power_plants.plantid = generation_records.plantid
    GROUP BY power_plants.operatorid
)

SELECT
    operators.operatorname,
    operators.headquarterscountry,
    operator_generation.total_generation
FROM operators
JOIN operator_generation
    ON operators.operatorid = operator_generation.operatorid
ORDER BY operator_generation.total_generation DESC; 


-- Query 5
-- Uses two CTEs to calculate total generation and total CO2 emissions
-- for each country, sorted from highest to lowest total generation.
WITH country_generation AS (
    SELECT
        power_plants.countrycode,
        SUM(generation_records.generationgwh) AS total_generation
    FROM power_plants
    JOIN generation_records
        ON power_plants.plantid = generation_records.plantid
    GROUP BY power_plants.countrycode
),

country_emissions AS (
    SELECT
        power_plants.countrycode,
        SUM(emission_metrics.co2emissionstonnes) AS total_emissions
    FROM power_plants
    JOIN emission_metrics
        ON power_plants.plantid = emission_metrics.plantid
    GROUP BY power_plants.countrycode
)

SELECT
    countries.countryname,
    country_generation.total_generation,
    country_emissions.total_emissions
FROM countries
JOIN country_generation
    ON countries.countrycode = country_generation.countrycode
JOIN country_emissions
    ON countries.countrycode = country_emissions.countrycode
ORDER BY country_generation.total_generation DESC;

