# Healthcare-analytics-mysql
SQL – Data Analysis – Healthcare Patient Experience

This project performs SQL-based data analysis on a healthcare patient experience dataset published by the Centers for Medicare & Medicaid Services (CMS). The dataset captures standardized survey responses that reflect how patients rate different aspects of hospital care across U.S. states.

# Dataset source:
https://data.cms.gov/provider-data/dataset/84jm-wiui

The SQL queries executed on this database provide comprehensive insights into state-level performance, survey measure trends, data coverage, and reporting gaps. The findings support comparative analysis across regions and help identify strengths, weaknesses, and consistency patterns in patient experience reporting.


# 1.⁠ ⁠Data Overview & Basic Statistics
	- The dataset was explored to understand overall data volume, reporting periods, and completeness.
	- Queries included total record counts, numeric versus non-numeric response coverage, and date range validation.
	- Initial checks ensured data integrity before analytical modeling.

  


# 2.⁠ ⁠Survey Measures & Patient Experience Scores
	- Analysis focused on survey measures representing different dimensions of patient experience.
	- National average scores were calculated for each measure to identify high- and low-performing aspects of care.
	- This analysis highlights which experience measures consistently perform well and which require improvement.



# 3.⁠ ⁠State-Level Performance Analysis
	-	Average patient experience scores were computed for each state using numeric survey responses.
	-	States were ranked to identify top- and bottom-performing regions.
	-	This enables comparison of patient experience outcomes across geographic areas.



# 4.⁠ ⁠Ranking & Comparative Analysis
	-	Window functions were used to rank states within each survey measure.
	-	Top and bottom performers per measure were identified.
	-	Comparative gaps between measures were analyzed to understand variation across states.



# 5.⁠ ⁠Best and Worst Measure per State
	-	For each state, the highest- and lowest-scoring survey measures were identified.
	-	This helps reveal localized strengths and areas requiring targeted quality improvement.



# 6.⁠ ⁠Variability & Consistency Analysis
	-	Standard deviation calculations were applied to assess performance consistency within each state.
	-	States with stable versus highly variable patient experience scores were identified.
	-	This analysis moves beyond averages to evaluate reliability of performance.



# 7.⁠ ⁠Data Quality & Missingness Analysis
	-	“Not Available” responses were analyzed by state and by measure.
	-	Measures with high missingness rates were identified.
	-	This supports evaluation of reporting completeness and data reliability.



# Dataset Columns – Description

# Each column in the dataset represents a specific attribute related to patient experience reporting at the state level, making it suitable for healthcare analytics and performance evaluation tasks. Here's an explanation of each column in the dataset. 

	 1.	State: Represents the U.S. state or territory for which survey results are reported.
	 2.	Measure ID: A unique identifier assigned to each patient experience survey measure.
	 3.	Survey Question: Describes the specific patient experience question being measured.
	 4.	Answer Description: Indicates the response category associated with the survey question.
	 5.	Answer Percent: The percentage value representing patient responses for a given measure and state. This field may contain numeric values or “Not Available.”
	 6.	Footnote: Provides additional context or reporting notes related to the data.
	 7.	Start Date: The beginning date of the reporting period for the survey results.
	 8.	End Date: The ending date of the reporting period for the survey results.



# Summary

This project demonstrates the use of SQL for healthcare analytics by transforming survey-based patient experience data into a structured analytical model. Through dimensional modeling and advanced SQL queries, the analysis uncovers performance trends, regional comparisons, variability patterns, and data quality insights at the state level.







