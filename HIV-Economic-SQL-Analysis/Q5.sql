UPDATE HIV_Project
SET
  Year = NULLIF(TRIM(Year), ''),
  People_with_HIV = NULLIF(TRIM(People_with_HIV), ''),
  HIV_Death = NULLIF(TRIM(HIV_Death), ''),
  Women_with_HIV_older_than_15 = NULLIF(TRIM(Women_with_HIV_older_than_15), ''),
  P_woment_with_HIV_ARVs_PMTCT = NULLIF(TRIM(P_woment_with_HIV_ARVs_PMTCT), ''),
  HIV_p_women_babies_tested_HIV_within_2_months = NULLIF(TRIM(HIV_p_women_babies_tested_HIV_within_2_months), ''),
  Population = NULLIF(TRIM(Population), '');