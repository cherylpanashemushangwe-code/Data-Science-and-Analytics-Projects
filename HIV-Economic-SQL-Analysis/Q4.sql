LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/HIV_Project.csv'
INTO TABLE HIV_Project
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(Country, Year, People_with_HIV, HIV_Death, Women_with_HIV_older_than_15,
 P_woment_with_HIV_ARVs_PMTCT, HIV_p_women_babies_tested_HIV_within_2_months, Population);