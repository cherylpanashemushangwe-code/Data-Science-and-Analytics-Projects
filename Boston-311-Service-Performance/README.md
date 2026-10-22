# Boston 311 Service Request Performance Analysis (2015 to 2019)

A team project for ALY6015 Intermediate Analytics at Northeastern University. We analyzed five years of Boston 311 requests to see how demand and closure speed changed over time, and whether the way a resident submits a request affects how quickly the city closes it.

**Team:** Krithika Krishna Murthy, Cheryl Mushangwe, Wenjun Chen, Vanessa Mutimaamba

## Questions

1. How did request volume, closure time, and timely closure change from 2015 to 2019?
2. Is the submission channel (mobile app vs phone, web, and other channels) associated with timely closure?
3. Which request characteristics predict faster or slower closure?

## Data

City of Boston 311 Service Requests, Boston Open Data Portal, one CSV per year from 2015 to 2019. The combined dataset has 1,199,625 requests. The raw files are not stored here because of their size. Download them from https://data.boston.gov/dataset/311-service-requests and place them in a folder named `Intermediate Analytics` next to the scripts.

## Key definitions

* **Closure days:** days between the open date and the closed date
* **Timely closure:** 1 if a request closed within 7 days, otherwise 0
* **Mobile request:** submitted through the Citizens Connect app

## Findings

* Mean closure time was 38.79 days, but the median was only 0.77 days. Most requests close within a day, and a small number of very long cases (some open for more than 2,000 days) pull the average up.
* 71.86% of requests closed within 7 days.
* Volume rose every year from 2015 to 2018, then dipped slightly in 2019. Average closure days climbed from 27.75 in 2015 to a peak of 49.92 in 2017, then improved to 35.36 by 2019.
* Mobile requests closed on time 79.5% of the time, compared with 69.1% for other channels (chi square = 15,531.83, df = 1, p < 0.001).
* Logistic regression showed that later years and mobile submission were both associated with higher odds of timely closure. LASSO pointed the same way.
* Dorchester and Roxbury had the most requests, and Public Works handled the largest share.

## Recommendations

* Focus improvement work on the request types and departments with the longest delays
* Streamline workflows for complex service categories
* Encourage mobile reporting, which closes faster
* Monitor neighborhoods with persistent delays

## Files

* `boston311_final_analysis.R` builds the features, descriptive tables, charts, chi square test, logistic regression, and LASSO model used in the presentation
* `boston311_secondary_analysis.R` runs supporting analysis, including a logistic regression with subject and neighborhood controls
* `Boston311_Presentation.pptx` is the final presentation

## Tools

R (dplyr, lubridate, ggplot2, broom, gt, glmnet)
