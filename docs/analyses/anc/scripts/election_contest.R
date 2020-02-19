
#' ---
#' title: "Collapsing ANC Election Data to Contest Level"
#' output: html_document
#' ---


#' [Reformat and collate years]

#+ setup, warning=FALSE, message=FALSE, echo=FALSE, results='hide'
knitr::opts_chunk$set(echo=FALSE, results='hide')

# Cleaning DC election data from 2012-2018
# collapses and reshapes data such that each SMD election is an observation


library(tidyverse)
library(magrittr)

#path <- getwd()
wd <- unlist(strsplit(getwd(), "/"))
wd <- wd[length(wd)]
prefix <- ifelse(wd == "scripts", "../", "")
    

years <- c("2012", "2014", "2016", "2018")

all.data <- NULL
all.regs <- NULL

for(year in years){
	
    # for running snippets and ignoring the loop:
    # year <- 2012

    # read in data
    #data <- read.table(file=paste(path, "/raw_data/", year, ".csv", sep=""), header=TRUE, sep=",")
    # rmarkdown and Rscript treat the working dir differently :(
    data <- read.table(file=paste(prefix, "raw_data/", year, ".csv", sep=""), header=TRUE, sep=",")
        
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
    keepers <- c(keepers, grep("total", tolower(data$contest_name)))
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
    # some names have commas, which will not read in properly
    data$candidate <- str_remove(data$candidate, ",")



    # hang onto registration & ballot data to wrangle elsewhere!
    #   (after fixing ANC names; before reshaping & tossing reg data)
    year.regs <- data %>% select(precinct, ward, anc, contest_name,
                                 registered_voters, ballots, year)
    # collapse away from candidate lvl
    year.regs %<>% group_by(precinct, ward, anc) %>%
                    summarize(registered_voters = unique(registered_voters),
                              ballots = unique(ballots),
                              year = unique(year))	      
    if(is.null(all.regs)) all.regs <- year.regs
    else all.regs <- bind_rows(all.regs, year.regs)

    #### TODO






    print(paste("year done", year, "(rows/cols)", sep=" "))
    print(dim(data))

    # If this is the first iteration, initialize with header
    if(is.null(all.data)) all.data <- data[0,]

    # append to other years, tidystyle
    all.data <- bind_rows(all.data, data)

}

### Export I

# spit out precinct-level registration and ballot counts
write.table(all.regs,
            file=paste(prefix, "cleaned_data/2012_2018_ballots_precinct.csv", sep=""),
            append=FALSE, quote=FALSE, sep=",", row.names=FALSE, col.names=TRUE)



# rename
data <- all.data


#### Collapsing / Reshaping

## Preparatory work

#' ### Collapsing
#+ collapse

# assert that no precincts cross wards
# why? for aggregating totals from precinct to ward to make sense?
prec_ward <- data %>% group_by(precinct) %>% summarize(x = var(ward))
stopifnot(identical(unique(prec_ward$x), 0))


# before collapsing away precincts, we need to aggregate up precinct-level vote/ballot totals
#   because I don't think precincts line up neatly with SMDs
# Not sure they line up with ANC either, so right now we aggregate to ward
ward_totals <- data %>% group_by(precinct, year) %>%
               summarize(ballots = unique(ballots), ward = unique(ward),
                         anc_votes = sum(votes))

ward_totals <- ward_totals %>% group_by(ward, year) %>%
                   summarize(ward_ballots = sum(ballots), ward_anc_votes = sum(anc_votes))
	
# drop from election data
data <- select(data, -ballots, -registered_voters)
# merge
#data <- inner_join(data, ward_totals, c("ward", "year"))

# ^^^^ NOTE a couple things are wrong with ward-level data right now so we don't merge it in

# pause to analyze ward_check
#ward_test <- data$ward_check == data$ward
ward_test <- data %>% filter(ward_check != ward)



#' How many SMDs are recorded as crossing wards?

#+ smd_ward, echo=TRUE, results='show'

head(ward_test)
unique(ward_test$contest_name)

#' for now, don't drop wonky guys. how should we treat this?  
#' is it all ANC... 3G, which is partly in ward 4?  
#' indeed, we see ANC 3G SMDs 1-4 are in ward 4, which agrees with maps  
#' also seeing 6D04... which is accurate but ignorable -- looks like it includes a section of hain's point that's in ward 2.  

#+ echo=TRUE, results='show'

group_by(ward_test, contest_name, year) %>% summarize(votes = sum(votes))

#' this is seeing the vacuous part of 6D04, cool
#+
#' #### Where will it trip us up to have ward not constant w/in ANC?
#' - not in this file, I think?
#' - probably when we collapse down to ANC-level later
#' - ward is still constant w/in contest  
#' so: let's delete 6D04 x ward 2  
#' note you will have to fix election_anc.R

#+ echo=TRUE, results='show'

data %<>% filter(!(contest_name=="6D04" & ward==2))


#+

# old cleaning code when we fixed anc 3G vvvvvvvvvvvvv
# delete anomalous ward data (SMDs crossing wards) for collapsing (defaulting to ANC identifier)
#   because we want ward to be constant within SMD
# first, take out ward-lvl data for affected obs
#data$ward_ballots[!ward_test] <- NA
#data$ward_anc_votes[!ward_test] <- NA
# then coerce ward to fit with ANC
#data$ward <- data$ward_check
#data <- select(data, -ward_check)
#					^^^^^^^^^^^^^^

#' check 3G03 before collapse

#+ echo=TRUE, results='show'

data %>% filter(contest_name=="3G03") %>% head(n=10)

#' shucks, ok 3G03 is legitimately split across wards  
#' looking at the 2013 map it is mostly in ward 4  
#' so let's set it to ward 4

#+ echo=TRUE, results='show'

data %<>% mutate(ward=ifelse(contest_name=="3G03", '4', ward))
data %>% filter(contest_name=="3G03") %>% head(n=10)

#+
## Collapse #1 (candidate)

# propogate up NAs in ballots using max(), we don't need that data at each ANC
data.cand <- data %>% group_by(contest_name, candidate, year) %>%
                 summarize(votes = sum(votes),
                           anc=unique(anc), ward=unique(ward), 
                           #ward_ballots=max(ward_ballots), ward_anc_votes=max(ward_anc_votes),
                           smd=unique(smd))

# finding which SMD is split across wards...
#+ eval=FALSE
data.cand %>% filter(nchar(ward) > 1) %T>% head(n=20)
# OK, 3G03 is the culprit. look into it above?

#+

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
over.under %<>% spread(candidate, votes)

# accommodate years w/o over/under data by adding the reshaped columns manually
# should be spurious now
#if(nrow(over.under) == 0) {
#    over.under$"over votes" <- integer(0)
#    over.under$"under votes" <- integer(0)
#}

# rename; keep
over.under <- over.under %>%
             rename(over_votes = "over votes", under_votes = "under votes") %>%
             select(contest_name, over_votes, under_votes, year)
# pull back in
data.cand <- left_join(data.cand, over.under, by=c("contest_name", "year"))




#' ### Peek at Candidate-Level Data

#+ cand_lvl, echo=TRUE, results='show'

glimpse(data.cand)
summary(data.cand)

#+ tidy



### Tidy things up

# sort for easier sanity checking
data.cand <- data.cand[order(data.cand$year, data.cand$contest_name),]

# sort columns so they actually make sense
sorted_names <- c("contest_name", "year", "ward", "anc", "smd")
# tack on any leftovers on the end so you're not dropping
sorted_names <- c(sorted_names, setdiff(colnames(data.cand), sorted_names))
data.cand %<>% select(sorted_names)


### Export II

write.table(data.cand,
            file=paste(prefix, "cleaned_data/2012_2018_ancElection_candidate.csv",
                       sep=""),
            append=FALSE, quote=FALSE, sep=",", row.names=FALSE, col.names=TRUE)


### Collapse to Contest-Lvl

# keep: SMD ANC votes, ward ANC votes, # official candidates, winner name, winner %, write-in %
#   ward totals (2), anc/ward/smd/yr, 
data.cont <- data.cand %>% group_by(contest_name, year) %>%
                        summarize(smd_anc_votes = sum(votes), 
                                  explicit_candidates = n() - 1,
                                  over_votes = unique(over_votes),
                                  under_votes = unique(under_votes),
                                  anc=unique(anc), smd=unique(smd),
                                  ward=unique(ward), winner=candidate[which.max(votes)],
                                  winner_votes=max(votes),
                                  write_in_votes=votes[grep("write.*in",tolower(candidate))])

# now we can make use of over/under if they exist
data.cont %<>% mutate(smd_ballots = smd_anc_votes + over_votes + under_votes)


#' ### Peek at contest-level data
#+ contest_level, echo=TRUE, results='show'

glimpse(data.cont)
summary(data.cont)

#+

### Export III

# sort
sorted_names <- c("contest_name", "year", "ward", "anc", "smd", "smd_ballots", "smd_anc_votes",
        "explicit_candidates", "winner", "winner_votes", "write_in_votes")
sorted_names <- c(sorted_names, setdiff(colnames(data.cont), sorted_names))
data.cont %<>% select(sorted_names)


write.table(data.cont,
            file=paste(prefix, "cleaned_data/2012_2018_ancElection_contest.csv",
                       sep=""), append=FALSE, quote=FALSE, sep=",", row.names=FALSE,
            col.names=TRUE)


