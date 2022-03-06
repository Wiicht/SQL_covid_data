-- Source of data set: https://ourworldindata.org/covid-deaths
-- Luca Brandt
-- Date: 04.03.2022


SELECT *
FROM Covid_project..covid_data
ORDER BY 3,4

SELECT	location,
		date, 
		total_cases,
		new_cases,
		total_deaths,
		population
FROM Covid_project..covid_data
order by 1,2 


-- lets see in which continent were most cases procentage wise
SELECT	location,
		MAX(total_cases) / MAX(population) procentage_cases
FROM Covid_project..covid_data
WHERE location IN ('Europe', 'Asia', 'North America', 'Australia', 'South America', 'Africa')
GROUP BY location
ORDER BY procentage_cases DESC 


-- Procentage of how many times people in the world were infected with covid 19
SELECT	ROUND(MAX(total_cases) / MAX(population),4) * 100 proecentage_infection_world
FROM Covid_project..covid_data


-- Total Cases per country --
SELECT	DISTINCT location,
		MAX(total_cases)/1000000 total_cases_in_mio
FROM Covid_project..covid_data
WHERE location NOT IN ('Asia', 'Europe','World', 'European Union', 'North America', 'High income', 'Upper middle income', 'Lower middle income', 'South America')
GROUP BY location
ORDER BY 2 DESC



-- total cases vs total deaths per country
WITH t1 AS (
SELECT	location,
		MAX(total_cases) tot_cases, 
		MAX(CAST(total_deaths AS BIGINT)) tot_deaths
FROM Covid_project..covid_data
WHERE total_cases IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY location )

SELECT	location, 
		tot_deaths / tot_cases * 100 procentage_deaths
FROM t1
ORDER BY 2 DESC


-- Date and it's country with most new cases
SELECT location,
		date, 
		total_cases,
		new_cases,
		total_deaths,
		population
FROM Covid_project..covid_data
WHERE new_cases = (		
					SELECT MAX(new_cases)
					FROM Covid_project..covid_data
					WHERE location NOT IN ('Asia', 'Europe','World', 'European Union', 'North America', 'High income', 'Upper middle income', 'Lower middle income', 'South America')
					-- OR: WHERE continent IS NOT NULL
					)


-- the total deaths due to covid per country
SELECT location, MAX(CAST(total_deaths AS BIGINT)) total_deaths_per_country
FROM Covid_project..covid_data
WHERE location NOT IN ('Asia', 'Europe','World', 'European Union', 'North America', 'High income', 'Upper middle income', 'Lower middle income', 'South America')
GROUP BY location  
ORDER BY total_deaths_per_country desc 


-- the total deaths due to covid overall
WITH t1 AS (
SELECT location, MAX(CAST(total_deaths AS BIGINT)) total_deaths_per_country
FROM Covid_project..covid_data
WHERE location NOT IN ('Asia', 'Europe','World', 'European Union', 'North America', 'High income', 'Upper middle income', 'Lower middle income', 'South America')
GROUP BY location )
SELECT SUM(CAST(total_deaths_per_country AS INT)) total_deaths
FROM t1


SELECT	location, 
		date, 
		population,
		new_vaccinations
FROM Covid_project..covid_data



--------------
-- FInd in which country were most vaccinations given
WITH x1 AS (
SELECT	continent,
		location loc, 
		CONVERT(date, date) date,
		population / 1000000 populatin_mio,
		new_vaccinations,
		SUM(CAST(new_vaccinations AS BIGINT)) OVER(PARTITION BY location ORDER BY location, CONVERT(date, date)) running_vaccs
FROM Covid_project..covid_data
WHERE continent IS NOT NULL AND new_vaccinations IS NOT NULL 
--ORDER BY 2,3
)
SELECT loc, MAX(running_vaccs) maxi
FROM x1
GROUP BY loc
ORDER BY 2 DESC



-- Now vaccination rate. Where most vaccines were given per population.
WITH x1 AS (
SELECT	continent,
		location loc, 
		CONVERT(date, date) date,
		population population_country,
		new_vaccinations,
		SUM(CAST(new_vaccinations AS BIGINT)) OVER(PARTITION BY location ORDER BY location, CONVERT(date, date)) running_vaccs
FROM Covid_project..covid_data
WHERE continent IS NOT NULL AND new_vaccinations IS NOT NULL 
--ORDER BY 2,3
)
SELECT loc, (MAX(running_vaccs) / MAX(population_country)) vaccs_given
FROM x1
GROUP BY loc
ORDER BY 2 DESC
--> (in Cuba it is 2.7 vaccines per individual on average for instance)


SELECT	*
FROM Covid_project..covid_data



-- lets find the procentage of smokers per country
WITH x2 AS (
SELECT	location,
		MAX((TRY_CONVERT(float,female_smokers) + TRY_CONVERT(float,male_smokers)) / 2) total_smokers,
		MAX(population) population_country
FROM Covid_project..covid_data
WHERE location IS NOT NULL AND male_smokers IS NOT NULL AND female_smokers IS NOT NULL
GROUP BY location )

SELECT	location, 
		TRY_CONVERT(float,total_smokers) / TRY_CONVERT(float,population_country) procentage_smokers
FROM x2
ORDER BY procentage_smokers DESC



-- total death procentage country
SELECT TOP 10 location, procentage_deaths_per_country
FROM (
SELECT location, MAX(CAST(total_deaths AS BIGINT)) / MAX(population) *100 procentage_deaths_per_country
FROM Covid_project..covid_data
WHERE location NOT IN ('Asia', 'Europe','World', 'European Union', 'North America', 'High income', 'Upper middle income', 'Lower middle income', 'South America')
GROUP BY location  
ORDER BY procentage_deaths_per_country DESC OFFSET 0 ROWS
 ) highest_procentage_smokers



-- Let's see how many countries appear in the top 10 most smoked countires and also top 10 highest death rates per country
SELECT *
FROM (
SELECT TOP 10 location,
				MAX((TRY_CONVERT(float,female_smokers) + TRY_CONVERT(float,male_smokers)) / 2) total_smokers,
				MAX(population) population_country,
				ROW_NUMBER() OVER(ORDER BY 	MAX((TRY_CONVERT(float,female_smokers) + TRY_CONVERT(float,male_smokers)) / 2) DESC) row_n
FROM Covid_project..covid_data
WHERE location IS NOT NULL AND male_smokers IS NOT NULL AND female_smokers IS NOT NULL
GROUP BY location )x3
WHERE location IN (
				SELECT TOP 10 location
				FROM (
				SELECT location, MAX(CAST(total_deaths AS BIGINT)) / MAX(population) *100 procentage_deaths_per_country
				FROM Covid_project..covid_data
				WHERE location NOT IN ('Asia', 'Europe','World', 'European Union', 'North America', 'High income', 'Upper middle income', 'Lower middle income', 'South America')
				GROUP BY location  
				ORDER BY procentage_deaths_per_country DESC OFFSET 0 ROWS
				 ) highest_procentage_smokers
)
--> only 2 out of the 10 most smoked countires are in the top 10 huhest death rates. There might be a correlation


