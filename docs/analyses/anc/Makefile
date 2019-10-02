

# Analysis/Vis

maps/anc-mapping/anc_map.html: cleaned_data/election_data_for_map.csv cleaned_data/anc_turnout.csv maps/anc-mapping/exploration.ipynb
	jupyter nbconvert --to notebook --inplace --execute maps/anc-mapping/exploration.ipynb


# Data processing

cleaned_data/election_data_for_anc_map.csv: cleaned_data/election_history_R.csv map_prep.R
	Rscript scripts/map_prep.R

cleaned_data/2018_elections_commissioners.csv: cleaned_data/election_history_R.csv merge_incumbents.R cleaned_data/current_anc_membership.csv
	Rscript scripts/merge_incumbents.R
# current_anc_membership.csv comes from Ilya's web scraping

cleaned_data/anc_turnout.csv: cleaned_data/precinct_totals.csv scripts/precinct_registration.R cleaned_data/election_history_R.csv
	Rscript scripts/precinct_registration.R

cleaned_data/precinct_totals.csv: cleaned_data/election_history_R.csv

cleaned_data/election_history_R.csv: scripts/anc_election_cleaner.R raw_data/2012.csv raw_data/2014.csv raw_data/2016.csv raw_data/2018.csv
	Rscript scripts/anc_election_cleaner.R



# Raw data

raw_data/2012.csv:
	curl -o raw_data/2012.csv https://electionresults.dcboe.org/Downloads/Reports/November_6_2012_General_and_Special_Election_Certified_Results.csv

raw_data/2014.csv:
	curl -o raw_data/2014.csv https://electionresults.dcboe.org/Downloads/Reports/November_4_2014_General_Election_Certified_Results.csv

raw_data/2016.csv:
	curl -o raw_data/2016.csv https://electionresults.dcboe.org/Downloads/Reports/November_8_2016_General_Election_Certified_Results.csv

raw_data/2018.csv:
	curl -o raw_data/2018.csv https://electionresults.dcboe.org/Downloads/Reports/November_6_2018_General_Election_Certified_Results.csv


# utilities

#clean: clean_viz
#	rm cleaned_data/election_history_R.csv
#	rm cleaned_data/precinct_totals.csv
#	rm cleaned_data/anc_turnout.csv
#	rm scripts/*~

clean_viz:
	rm -f visualization/*.md
	rm -f visualization/*.html
	rm -rf visualization/*cache
	rm -rf visualization/*files
	rm -f visualization/*~

FORCE:
