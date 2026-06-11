SELECT 
    Country,
    Year,
    People_with_HIV,
    Population,
    ROUND(People_with_HIV / Population, 6) AS HIV_Ratio
FROM 
    hiv_total_central_america
WHERE 
    People_with_HIV IS NOT NULL 
    AND Population IS NOT NULL;
