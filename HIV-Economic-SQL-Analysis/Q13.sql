SELECT 
    Country,
    SUM(People_with_HIV) AS Total_People_with_HIV,
    SUM(HIV_Death) AS Total_HIV_Deaths,
    SUM(Population) AS Total_Population,
    
    ROUND((SUM(People_with_HIV) / SUM(Population)) * 100, 2) AS HIV_Pop_Percent,
    ROUND((SUM(HIV_Death) / SUM(Population)) * 100, 2) AS HIV_Death_Percent
FROM 
    HIV_Project
WHERE 
    People_with_HIV IS NOT NULL
    AND HIV_Death IS NOT NULL
    AND Population IS NOT NULL
GROUP BY 
    Country
ORDER BY 
    HIV_Pop_Percent DESC;
