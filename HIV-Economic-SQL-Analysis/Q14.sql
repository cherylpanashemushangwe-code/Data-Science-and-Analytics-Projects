SELECT 
    Year,
    SUM(People_with_HIV) AS Total_People_with_HIV,
    ROUND(AVG(`Unemployment_rate`), 2) AS Avg_Unemployment_Rate
FROM 
    hiv_total_central_america
WHERE 
    People_with_HIV IS NOT NULL 
    AND `Unemployment_rate` IS NOT NULL
GROUP BY 
    Year
ORDER BY 
    Year ASC;
