SELECT 
    Country,
    ROUND(SUM(People_with_HIV) / SUM(Population), 6) AS HIV_Ratio,
    ROUND((SUM(People_with_HIV) / SUM(Population)) * 100, 2) AS HIV_Percent
FROM 
    HIV_Project
WHERE 
    People_with_HIV IS NOT NULL 
    AND Population IS NOT NULL
GROUP BY 
    Country
ORDER BY 
    HIV_Ratio DESC;
