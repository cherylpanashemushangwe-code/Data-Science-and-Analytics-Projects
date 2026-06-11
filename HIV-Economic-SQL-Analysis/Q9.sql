CREATE TABLE HIV_Total_Central_America AS
SELECT
    h.Country,
    h.Year,
    h.People_with_HIV,
    h.HIV_Death,
    h.Women_with_HIV_older_than_15,
    h.P_woment_with_HIV_ARVs_PMTCT,
    h.HIV_p_women_babies_tested_HIV_within_2_months,
    h.Population,
    p.`GDP per capita (current US$)` AS GDP_per_capita_USD,
    p.`Unemployment rate` AS Unemployment_rate
FROM
    HIV_Project h
JOIN
    population_gdp_unemployment_rate p
ON
    h.Country = p.Country
    AND h.Population = p.Population
    AND h.Year = p.Year;
