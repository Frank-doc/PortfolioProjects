SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT *
FROM PortfolioProject..CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT continent, Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths, which shows likelihood of dying after getting covid in your country.
SELECT continent, Location, date, total_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states'
AND continent IS NOT NULL
ORDER BY 1,2


--Looking at Total Cases vs Population. Shows what percentage of population has gotten covid.
SELECT continent, Location, date, Population, total_cases, (CAST(total_cases AS float)/CAST(Population AS float))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states'
AND continent IS NOT NULL
ORDER BY 1,2

--Looking at countries with highest infection rates compared to population.
SELECT continent, Location, population, MAX(CONVERT(float, total_cases)) AS HighestInfectionCount, MAX(CONVERT(float, total_cases)/CONVERT(float, population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, Location, population
ORDER BY PercentPopulationInfected DESC

-- Showing countries with the highest death count per population
SELECT continent, Location, MAX(CONVERT(int, total_deaths)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, Location
ORDER BY TotalDeathCount DESC

-- LET'S BREAK THINGS DOWN BY CONTINENT. Showing the continents with the highest death counts.
SELECT location, MAX(CONVERT(int, total_deaths)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) AS GlobalNewCases
, SUM(CAST(total_cases AS int)) AS GlobalTotalCases
, SUM(CAST(new_deaths AS int)) AS GlobalNewDeaths
, SUM(CAST(total_deaths AS int)) AS GlobalTotalDeaths
, (SUM(CAST(total_deaths AS float))/SUM(CAST(total_cases AS float)))*100 AS GlobalDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population,  vac.new_people_vaccinated_smoothed, SUM(CAST(vac.new_people_vaccinated_smoothed AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS TotalPeopleVaccinated
--, (TotalPeopleVaccinated/population)*100  #This will not work because we cannot reference an alias we just created in the same table
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--USE CTE
WITH PopvsVac(continent, location, date, population, new_people_vaccinated_smoothed, TotalPeopleVaccinated)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population,  vac.new_people_vaccinated_smoothed, SUM(CAST(vac.new_people_vaccinated_smoothed AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS TotalPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (TotalPeopleVaccinated/population)*100 AS PeopleVaccinatedPercent
FROM PopvsVac

--Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar (255), 
location nvarchar (255), 
date datetime, 
population numeric, 
new_people_vaccinated numeric, 
TotalPeopleVaccinated numeric
)
	
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population,  vac.new_people_vaccinated_smoothed, SUM(CAST(vac.new_people_vaccinated_smoothed AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS TotalPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT *, (TotalPeopleVaccinated/population)*100 AS PeopleVaccinatedPercent
FROM #PercentPopulationVaccinated

--Creating Views to store data for later visualizations
CREATE VIEW PopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population,  vac.new_people_vaccinated_smoothed, SUM(CAST(vac.new_people_vaccinated_smoothed AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS TotalPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

CREATE VIEW PercentPopulationVaccinated AS
WITH PopvsVac(continent, location, date, population, new_people_vaccinated_smoothed, TotalPeopleVaccinated)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population,  vac.new_people_vaccinated_smoothed, SUM(CAST(vac.new_people_vaccinated_smoothed AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS TotalPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (TotalPeopleVaccinated/population)*100 AS PeopleVaccinatedPercent
FROM PopvsVac

CREATE VIEW GlobalNumbers AS
SELECT date, SUM(new_cases) AS GlobalNewCases
, SUM(CAST(total_cases AS int)) AS GlobalTotalCases
, SUM(CAST(new_deaths AS int)) AS GlobalNewDeaths
, SUM(CAST(total_deaths AS int)) AS GlobalTotalDeaths
, (SUM(CAST(total_deaths AS float))/SUM(CAST(total_cases AS float)))*100 AS GlobalDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date

CREATE VIEW PercentPopulationInfected AS
SELECT continent, Location, population, MAX(CONVERT(float, total_cases)) AS HighestInfectionCount, MAX(CONVERT(float, total_cases)/CONVERT(float, population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, Location, population

CREATE VIEW DeathTotals AS
SELECT continent, Location, MAX(CONVERT(int, total_deaths)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, Location

CREATE VIEW DeathPercentages AS
SELECT continent, Location, date, total_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
