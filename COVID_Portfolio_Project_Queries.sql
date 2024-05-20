-- Check data

-- TOTAL CASES VS TOTAL DEATHS
-- Shows likelihood of dying if you contract COVID-19 in your country
SELECT 
location,
date,
total_cases,
total_deaths,
(total_deaths/total_cases)*100 AS covid_death_percentage
FROM CovidDeaths
WHERE location LIKE 'Singapore'
AND DATETRUNC(MONTH, date) <= '2021-04-01'
ORDER BY 1,2


-- TOTAL CASES VS TOTAL POPULATION
SELECT 
location,
date,
population,
total_cases,
(total_cases/population)*100 AS covid_cases_percentage
FROM CovidDeaths
WHERE location LIKE 'Singapore'
AND DATETRUNC(MONTH, date) <= '2021-04-01'
ORDER BY 1,2


-- COUNTRIES WITH HIGHEST INFECTION RATES RELATIVE TO POPULATION
SELECT 
location,
population,
MAX(total_cases) AS highest_infection_count,
MAX((total_cases/population))*100 AS highest_infection_percentage
FROM CovidDeaths
WHERE DATETRUNC(MONTH, date) <= '2021-04-01'
GROUP BY location, population
ORDER BY 4 DESC


-- COUNTRIES WITH HIGHEST DEATH RATES
SELECT 
location,
MAX(total_deaths) AS total_deaths_by_country
FROM CovidDeaths
WHERE DATETRUNC(MONTH, date) <= '2021-04-01'
AND continent IS NOT NULL -- removes where location is an entire continent (we only want countries)
GROUP BY location
ORDER BY 2 DESC

-- if the data type is not an int or float and you cannot do calculations on them, just use eg. CAST(total_deaths AS INT) or CAST(total_deaths AS FLOAT)


-- TOTAL DEATH COUNT BY CONTINENT 
SELECT
location,
MAX(total_deaths) AS total_deaths_by_continent
FROM CovidDeaths
WHERE DATETRUNC(MONTH, date) <= '2021-04-01'
AND continent IS NULL -- due to how the data is tabulated in Excel
AND location NOT IN ('World', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY 2 DESC -- accurate query


-- CONTINENT WITH HIGHEST DEATH COUNT PER POPULATION
SELECT
continent,
MAX(total_deaths) AS total_deaths_by_continent
FROM CovidDeaths
WHERE DATETRUNC(MONTH, date) <= '2021-04-01'
AND continent IS NOT NULL 
GROUP BY continent
ORDER BY 2 DESC 


-- GLOBAL NUMBERS (WEEKLY) 
SELECT 
date,
SUM(new_cases) AS total_cases,
SUM(new_deaths) AS total_deaths,
SUM(new_deaths)/SUM(new_cases) * 100 AS weekly_global_death_percentage
FROM CovidDeaths
WHERE DATETRUNC(MONTH, date) <= '2021-04-01'
AND new_cases != 0
AND new_deaths != 0
AND location IS NOT NULL
AND location NOT IN ('World', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
AND continent IS NOT NULL
GROUP BY date
ORDER BY 1


-- DEATH RATES BY INCOME CLASSIFICATION
SELECT
location,
MAX(total_deaths) AS total_deaths_by_income_class
FROM CovidDeaths
WHERE DATETRUNC(MONTH, date) <= '2021-04-01'
AND continent IS NULL 
AND location IN ('World', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY 2 DESC


-- VACCINATIONS TABLE 

-- TOTAL POPULATION VS VACCINATION
SELECT
deaths.continent,
deaths.location,
deaths.date,
deaths.population,
vax.new_vaccinations,		-- new vaccinations daily
SUM(new_vaccinations) OVER(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_vax_count
FROM CovidDeaths deaths
JOIN CovidVaccinations vax
	ON deaths.location = vax.location
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL
AND deaths.location IS NOT NULL
AND deaths.location NOT IN ('World', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
AND deaths.location = 'Albania'
AND DATETRUNC(MONTH, deaths.date) <= '2021-04-01'
ORDER BY 2,3

-- using CTE (similar to BQ but the format is different)
WITH pop_vs_vax (continent, location, date, population, new_vaccinations, rolling_vaccination_count) 
AS (
SELECT
deaths.continent,
deaths.location,
deaths.date,
deaths.population,
vax.new_vaccinations,		-- new vaccinations daily
SUM(new_vaccinations) OVER(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_vaccination_count
FROM CovidDeaths deaths
JOIN CovidVaccinations vax
	ON deaths.location = vax.location
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL
AND deaths.location IS NOT NULL
AND deaths.location NOT IN ('World', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
AND deaths.location = 'Albania'
AND DATETRUNC(MONTH, deaths.date) <= '2021-04-01'
--ORDER BY 2,3
)

SELECT *, (rolling_vaccination_count/population)*100 AS vaccinated_percentage
FROM pop_vs_vax


-- using Temp Table

DROP TABLE IF EXISTS #vaccinated_percentage
CREATE TABLE #vaccinated_percentage
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccination_count numeric
)

INSERT INTO #vaccinated_percentage 
SELECT
deaths.continent,
deaths.location,
deaths.date,
deaths.population,
vax.new_vaccinations,		-- new vaccinations daily
SUM(new_vaccinations) OVER(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_vaccination_count
FROM CovidDeaths deaths
JOIN CovidVaccinations vax
	ON deaths.location = vax.location
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL
AND deaths.location IS NOT NULL
AND deaths.location NOT IN ('World', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
--AND deaths.location = 'Albania'
AND DATETRUNC(MONTH, deaths.date) <= '2021-04-01'
ORDER BY 2,3

SELECT *, (rolling_vaccination_count/population)*100 AS vaccinated_percentage
FROM #vaccinated_percentage


-- CREATING VIEWS (to store data for later visualisations)

CREATE VIEW vaccinated_population_percentage AS 
SELECT
deaths.continent,
deaths.location,
deaths.date,
deaths.population,
vax.new_vaccinations,		-- new vaccinations daily
SUM(new_vaccinations) OVER(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_vaccination_count
FROM CovidDeaths deaths
JOIN CovidVaccinations vax
	ON deaths.location = vax.location
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL
AND deaths.location IS NOT NULL
AND deaths.location NOT IN ('World', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
AND DATETRUNC(MONTH, deaths.date) <= '2021-04-01'

SELECT *
FROM vaccinated_population_percentage
