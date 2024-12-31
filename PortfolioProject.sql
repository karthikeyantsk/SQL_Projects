
--select all datas order by date and location
SELECT * FROM PortfolioProject..CovidDeaths11
ORDER BY 3,4

--select all datas order by date and location on another table
SELECT * FROM PortfolioProject..CovidVaccinations11
ORDER BY 3,4

--select specific datas
SELECT LOCATION,DATE,TOTAL_CASES,TOTAL_DEATHS,POPULATION 
FROM PortfolioProject..CovidDeaths11

--calculate percentage of total cases and total deaths
SELECT LOCATION,DATE,TOTAL_CASES,TOTAL_DEATHS,(TOTAL_DEATHS/TOTAL_CASES)*100 
FROM PortfolioProject..CovidDeaths11
ORDER BY 1,2

--likelihood of dying in USA or specific countries
SELECT LOCATION,DATE,TOTAL_CASES,TOTAL_DEATHS,(TOTAL_DEATHS/TOTAL_CASES)*100 
FROM PortfolioProject..CovidDeaths11
WHERE LOCATION LIKE '%STATES%'
ORDER BY 1,2

--total cases vs populations 
--shows what % of covid comparing popls
SELECT LOCATION,DATE,TOTAL_CASES,POPULATION,(TOTAL_CASES/POPULATION)*100 AS POP_PERCENT
FROM PortfolioProject..CovidDeaths11
--WHERE LOCATION LIKE '%STATES%'
WHERE DATE LIKE '%2020%'
ORDER BY 1,2

--calculate the highest infected rate and percentage using population
SELECT LOCATION,POPULATION,MAX(TOTAL_CASES) AS HIGHEST_INFECTED_RATE,MAX(TOTAL_CASES/POPULATION)*100 AS HIGHEST_INFECTED_PERCENT
FROM PortfolioProject..CovidDeaths11
GROUP BY LOCATION,POPULATION
ORDER BY HIGHEST_INFECTED_PERCENT DESC

--the above the same --own 
SELECT LOCATION,POPULATION,MAX(TOTAL_DEATHS) AS HIGHEST_DEATH ,(MAX(TOTAL_DEATHS/POPULATION))*100 AS HIGHEST_DEATH_RATE
FROM PortfolioProject..CovidDeaths11
GROUP BY LOCATION,POPULATION
ORDER BY HIGHEST_DEATH_RATE DESC

--select total continent of detah rate
--break things by continent
--showing death count per population
SELECT CONTINENT,MAX(CAST(TOTAL_DEATHS AS INT)) AS TOTAL_DEATH_RATE
FROM PortfolioProject..CovidDeaths11
WHERE CONTINENT IS NOT NULL
GROUP BY CONTINENT
ORDER BY TOTAL_DEATH_RATE DESC

--global numbers of new cases using continent,population
SELECT CONTINENT,POPULATION,SUM(NEW_CASES)AS TOTAL_CASES,SUM(CAST(NEW_DEATHS AS INT)) AS TOTAL_DEATHS,SUM(CAST(NEW_DEATHS AS INT))/SUM(NEW_CASES)*100 AS DEATH_PERCENTAGE
FROM PortfolioProject..CovidDeaths11
WHERE CONTINENT IS NOT NULL
GROUP BY POPULATION,CONTINENT
ORDER BY 1,2

--GLOBAL NUMBERS OF NEW CASES
SELECT SUM(NEW_CASES)AS TOTAL_CASES,SUM(CAST(NEW_DEATHS AS INT)) AS TOTAL_DEATHS,SUM(CAST(NEW_DEATHS AS INT))/SUM(NEW_CASES)*100 AS DEATH_PERCENTAGE
FROM PortfolioProject..CovidDeaths11
WHERE CONTINENT IS NOT NULL
ORDER BY 1,2




--SELECT 2ND TABLE
SELECT * FROM PortfolioProject..CovidVaccinations11
ORDER BY 3,4

--join two tables--total pops vaccinated
SELECT * FROM PortfolioProject..CovidDeaths11 DE
JOIN PortfolioProject..CovidVaccinations11 VA
ON DE.LOCATION =VA.LOCATION
AND DE.DATE=VA.DATE


--OWN--
SELECT CONTINENT,LOCATION,DATE,NEW_VACCINATIONS,SUM(CAST(NEW_VACCINATIONS AS INT)) OVER(PARTITION BY LOCATION ORDER BY LOCATION)AS TOTAL 
FROM PortfolioProject..CovidVaccinations11 
WHERE NEW_VACCINATIONS IS NOT NULL AND CONTINENT IS NOT NULL
ORDER BY 1


--USING CTE FOR EXPRESSING PERCENT POPULATION VACCINATED
WITH POPVSVAC 
(CONTINENT,LOCATION,DATE,POPULATION,NEW_VACCINATIONS,PEOPLE_VACCINATED,VACCINE_PERCENT)  
AS(
SELECT DE.CONTINENT,DE.LOCATION,DE.DATE,DE.POPULATION,VA.NEW_VACCINATIONS,
SUM(CAST(NEW_VACCINATIONS AS INT))OVER (PARTITION BY DE.LOCATION ORDER BY DE.LOCATION ASC) AS PEOPLE_VACCINATED,
(PEOPLE_VACCINATED/POPULATION)*100 AS VACCINE_PERCENT
FROM PortfolioProject..CovidDeaths11 DE
JOIN PortfolioProject..CovidVaccinations11 VA
ON DE.LOCATION=VA.LOCATION AND DE.DATE=VA.DATE
WHERE DE.CONTINENT IS NOT NULL 
--ORDER BY 1,2
)

SELECT * FROM 
POPVSVAC



--USING TEMP_TABLE TO CALCULATE THE SAME.
DROP TABLE IF EXISTS #POP_VACCINE_PERCENT
CREATE TABLE #POP_VACCINE_PERCENT
(
CONTINENT NVARCHAR(255),
LOCATION NVARCHAR(255),
DATE DATETIME,
POPULATION NUMERIC,
NEW_VACCINATIONS NUMERIC,
PEOPLE_VACCINATED NUMERIC,
--VACCINE_PERCENT NUMERIC
)

INSERT INTO #POP_VACCINE_PERCENT (CONTINENT, LOCATION, DATE, POPULATION, NEW_VACCINATIONS, PEOPLE_VACCINATED)
SELECT DE.CONTINENT,
DE.LOCATION,
--changed this for datetime dt using gpt
TRY_CONVERT(DATETIME, DE.DATE) AS DATE,
DE.POPULATION,
VA.NEW_VACCINATIONS,
--changed the below stmt for date not accessing in datetime datatype.
SUM(CAST(COALESCE(VA.NEW_VACCINATIONS, 0) AS INT)) 
        OVER (PARTITION BY DE.LOCATION ORDER BY TRY_CONVERT(DATETIME, DE.DATE) ASC) AS PEOPLE_VACCINATED
FROM PortfolioProject..CovidDeaths11 DE
JOIN PortfolioProject..CovidVaccinations11 VA
ON DE.LOCATION=VA.LOCATION AND DE.DATE=VA.DATE
WHERE DE.CONTINENT IS NOT NULL 
 AND ISDATE(DE.DATE) = 1; -- Exclude invalid dates...this also using gpt

SELECT *,(PEOPLE_VACCINATED/POPULATION)*100 AS VACCINE_PERCENT 
FROM #POP_VACCINE_PERCENT


--creating views as percent pop vaccinated
CREATE VIEW PERCENTPOPVACCINATED AS
SELECT DE.CONTINENT,
DE.LOCATION,
--changed this for datetime dt using gpt
TRY_CONVERT(DATETIME, DE.DATE) AS DATE,
DE.POPULATION,
VA.NEW_VACCINATIONS,
--changed the below stmt for date not accessing in datetime datatype.
SUM(CAST(COALESCE(VA.NEW_VACCINATIONS, 0) AS INT)) 
        OVER (PARTITION BY DE.LOCATION ORDER BY TRY_CONVERT(DATETIME, DE.DATE) ASC) AS PEOPLE_VACCINATED
FROM PortfolioProject..CovidDeaths11 DE
JOIN PortfolioProject..CovidVaccinations11 VA
ON DE.LOCATION=VA.LOCATION AND DE.DATE=VA.DATE
WHERE DE.CONTINENT IS NOT NULL 
 AND ISDATE(DE.DATE) = 1;

 SELECT * FROM  PERCENTPOPVACCINATED