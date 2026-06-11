SELECT
    Year,
    SUM(People_with_HIV) AS Total_People_with_HIV,
    ROUND(AVG(GDP_per_capita_USD), 2) AS Avg_GDP
FROM
    hiv_total_central_america
WHERE
    People_with_HIV IS NOT NULL
    AND GDP_per_capita_USD IS NOT NULL
GROUP BY
    Year
ORDER BY
    Year;