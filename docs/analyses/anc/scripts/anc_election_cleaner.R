
library(tidyverse)


path <- getwd()
years <- c("2012", "2014", "2016", "2018")

all.data <- NULL

for(year in years){
	
	# for running snippets and ignoring the loop:
	# year <- 2018
	
	# read in data
	data <- read.table(file=paste(path, "/data/", year, ".csv", sep=""), header=TRUE, sep=",")
		
	print(paste("starting year", year))
	print(colnames(data))	
	
	### Wrangle column name inconsistencies
	
	# first, reassign colnames as lowercase
	colnames(data) <- tolower(colnames(data))
	
	# fix names
	data <- rename(data, contest_name = matches("contest_?name"), precinct = matches("precinct"),
	                ward = matches("ward"))
	
	# drop
	data <- select(data, -matches("election"), -matches("contest_?(id|number)"), -matches("party"))
	head(data)
	
		
	# add year
	data$year <- rep(year, dim(data)[1])
	
	print("dropped irrelevant columns (rows/cols)")
	print(dim(data))
	
	
	### Drop non-ANC obs
	# I kind of like this section and don't know if it needs tidyverse pithifying
	
	reg <- "[[:digit:]][[:upper:]][[:digit:]]{2}"
	#print(str(data$contest_name))
	#print(grep(reg, data$contest_name, fixed=FALSE))
	
	# keep ANC obs and vote / registration totals (by precinct)
	keepers <- grep(reg, data$contest_name)
	keepers <- c(keepers, grep("total", lower(data$contest_name)))
	data <- data[keepers,]
	
	print("dropped non-ANC obs (rows/cols)")
	print(dim(data))
	
	##### Reshape precinct-level totals to columns
	
	# Filter and reshape
	totals <- data[grep("- TOTAL", data$contest_name),] %>% select(contest_name, precinct, votes)
	totals <- spread(totals, contest_name, votes)
	totals <- rename(totals, registered_voters = matches("REGISTER"), ballots = matches("BALLOT"))
	
	# take totals out of data
	data <- data[-grep("- TOTAL", data$contest_name),]
	
	# merge
	data <- inner_join(data, totals, by="precinct")
	# this mostly seems to work
	# I'm seeing observations for ward 2 precinct 129 anc 6D04. weird. is in original data?
	# yes. test for this! could indicate data issues!
	
	
	# reformat contest name to be just 6B04 e.g.
	data$contest_name <- regmatches(data$contest_name, regexpr(reg, data$contest_name))
	
	# break out to ANC and smd fields (and ward to check the above anomaly)
	data$anc <- regmatches(data$contest_name, regexpr("[[:alpha:]]", data$contest_name))
	data$smd <- regmatches(data$contest_name, regexpr("[[:digit:]]{2}$", data$contest_name))
	data$ward_check <- regmatches(data$contest_name, regexpr("^[[:digit:]]", data$contest_name))
	
	# some years have whitespace in candidate names
	data$candidate <- strwrap(data$candidate)


    #### Collapsing / Reshaping
    
	## Preperatory work
	
	# assert that no precincts cross wards
	# why? for aggregating totals from precinct to ward to make sense?
	prec_ward <- data %>% group_by(precinct) %>% summarize(x = var(ward))
	stopifnot(identical(unique(prec_ward$x), 0))
	
	# before collapsing away precincts, we need to aggregate up precinct-level vote/ballot totals
    #   because I don't think precincts line up neatly with SMDs
    # Not sure they line up with ANC either, so right now we aggregate to ward
	ward_totals <- data %>% group_by(precinct) %>% summarize(ballots = unique(ballots), ward = unique(ward), anc_votes = sum(votes))
	ward_totals <- ward_totals %>% group_by(ward) %>% summarize(ward_ballots = sum(ballots), ward_anc_votes = sum(anc_votes))
	
	# drop from election data
	data <- select(data, -ballots, -registered_voters)
	# merge
	data <- inner_join(data, ward_totals, "ward")
	

    # pause to analyze ward_check
	ward_test <- data$ward_check == data$ward
	print("How many SMDs are recorded as a different ward?")
	print(summary(!ward_test))

	# delete anomalous ward data (SMDs crossing wards) for collapsing (defaulting to ANC identifier)
	#   because we want ward to be constant within SMD
	# first, take out ward-lvl data for affected obs
	data$ward_ballots[!ward_test] <- NA
	data$ward_anc_votes[!ward_test] <- NA
	# then coerce ward to fit with ANC
	data$ward <- data$ward_check
	data <- select(data, -ward_check)
	

    ## Collapse #1 (candidate)
	
    # propogate up NAs in ballots using max(), we don't need that data at each ANC
	data.cand <- data %>% group_by(contest_name, candidate) %>% summarize(votes = sum(votes),
	        anc=unique(anc), ward=unique(ward), year=unique(year), 
	        ward_ballots=max(ward_ballots), ward_anc_votes=max(ward_anc_votes),
	        smd=unique(smd))

    # Deal with over/under votes, which are entered as candidates in 2014-18
    # Filter, reshape, & merge so we have over/under as variables
    ind <- grep("^(over|under) ?votes$", tolower(data.cand$candidate))
    not_ind <- setdiff(seq(nrow(data.cand)), ind)
    over.under <- data.cand[ind,]
    # drop
    data.cand <- data.cand[not_ind,]
    # generalize strings
    over.under$candidate <- tolower(over.under$candidate)
    # reshape
    over.under <- over.under %>% spread(candidate, votes)
    # accommodate years w/o over/under data by adding the reshaped columns manually
    if(nrow(over.under) == 0) {
    	over.under$"over votes" <- integer(0)
    	over.under$"under votes" <- integer(0)
    }
    # rename; keep
    over.under <- over.under %>% rename(over_votes = "over votes", under_votes = "under votes") %>%
            select(contest_name, over_votes, under_votes)
    # pull back in
    data.cand <- left_join(data.cand, over.under, by="contest_name")
    	

    ## Collapse #2 (contest)

	# keep: SMD ANC votes, ward ANC votes, # official candidates, winner name, winner %, write-in %
	#   ward totals (2), anc/ward/smd/yr, 
	data.cont <- data.cand %>% group_by(contest_name) %>% summarize(smd_anc_votes = sum(votes), 
	        explicit_candidates = n() - 1, ward_ballots = unique(ward_ballots), 
	        over_votes = unique(over_votes), under_votes = unique(under_votes),
	        ward_anc_votes = unique(ward_anc_votes), anc=unique(anc), smd=unique(smd), year=unique(year),
	        ward=unique(ward), winner=candidate[which.max(votes)], winner_votes=max(votes),
	        write_in_votes=votes[grep("write.*in",tolower(candidate))])
	
    # now we can make use of over/under if they exist
    data.cont$smd_ballots <- data.cont$smd_anc_votes + data.cont$over_votes + data.cont$under_votes
	
	
	print(paste("year done", year, "(rows/cols)", sep=" "))
	print(dim(data.cont))
	
	# If this is the first iteration, initialize with header
	if(is.null(all.data)) all.data <- data.cont[0,]

	# append to other years, tidystyle
	all.data <- bind_rows(all.data, data.cont)
		
}

# sort for easier sanity checking
all.data <- all.data[order(all.data$year, all.data$contest_name),]


write.table(all.data, file=paste(path, "/data/", "allyears", "_collapsed.csv", sep=""), append=FALSE, quote=FALSE, sep=",", row.names=FALSE, col.names=TRUE)



