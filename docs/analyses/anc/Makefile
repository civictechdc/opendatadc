

# Visualization

visualization/election_contest.html: scripts/election_contest.R raw_data
	Rscript -e "library(rmarkdown); render(knitr::spin('scripts/election_contest.R', format='Rmd', knit=FALSE), output_dir='visualization')"
#	Rscript -e "library(rmarkdown); render('scripts/election_contest.R')"
 
maps/anc-mapping/anc_map.html: cleaned_data/2018_ancElection_anc.csv cleaned_data/2012_2018_imputedTurnout_anc.csv maps/anc-mapping/exploration.ipynb
	jupyter nbconvert --to notebook --inplace --execute maps/anc-mapping/exploration.ipynb



# Data processing
process: cleaned_data/2018_ancElection_anc.csv cleaned_data/2018_ancElection_commissioners_contest.csv cleaned_data/2012_2018_imputedTurnout_anc.csv cleaned_data/2012_2018_ancElection_candidate.csv

cleaned_data/2018_ancElection_anc.csv: cleaned_data/2018_ancElection_commissioners_contest.csv scripts/election_anc.R
	Rscript scripts/election_anc.R

cleaned_data/2018_ancElection_commissioners_contest.csv: cleaned_data/2012_2018_ancElection_contest.csv scripts/merge_incumbents.R raw_data/2019_commissioners.csv
	Rscript scripts/merge_incumbents.R


cleaned_data/2012_2018_imputedTurnout_anc.csv: cleaned_data/2012_2018_ballots_precinct.csv scripts/impute_turnout.R cleaned_data/2012_2018_ancElection_contest.csv
	Rscript scripts/impute_turnout.R

cleaned_data/2012_2018_ballots_precinct.csv: cleaned_data/2012_2018_ancElection_candidate.csv

cleaned_data/2012_2018_ancElection_contest.csv: cleaned_data/2012_2018_ancElection_candidate.csv

cleaned_data/2012_2018_ancElection_candidate.csv: scripts/election_contest.R raw_data
	Rscript scripts/election_contest.R



# Raw data

raw_data: raw_data/2012.csv raw_data/2014.csv raw_data/2016.csv raw_data/2018.csv

raw_data/2012.csv:
	curl -o raw_data/2012.csv https://electionresults.dcboe.org/Downloads/Reports/November_6_2012_General_and_Special_Election_Certified_Results.csv

raw_data/2014.csv:
	curl -o raw_data/2014.csv https://electionresults.dcboe.org/Downloads/Reports/November_4_2014_General_Election_Certified_Results.csv

raw_data/2016.csv:
	curl -o raw_data/2016.csv https://electionresults.dcboe.org/Downloads/Reports/November_8_2016_General_Election_Certified_Results.csv

raw_data/2018.csv:
	curl -o raw_data/2018.csv https://electionresults.dcboe.org/Downloads/Reports/November_6_2018_General_Election_Certified_Results.csv

# raw_data/2019_commissioners.csv comes via Ilya's web scraping (formerly called 'current_anc_membership.csv')

# utilities

#clean: clean_viz
#	rm cleaned_data/election_history_R.csv
#	rm cleaned_data/precinct_totals.csv
#	rm cleaned_data/anc_turnout.csv
#	rm scripts/*~

clean_viz:
	rm scripts/election_contest.Rmd
	rm visualization/election_contest.html

FORCE:
