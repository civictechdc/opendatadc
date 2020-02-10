
# import order of plyr & tidyverse v important!!!
# I think plyr & dplyr overlap, and you want dplyr to override
library(plyr)
library(tidyverse)
library(magrittr) # those assignment pipes
library(qualV)
library(stringr)

path <- getwd()

elections <- read.csv(file=paste(path, "/cleaned_data/election_history_R.csv", sep=""), sep=",",header=TRUE, stringsAsFactors=FALSE)

cat('elections\n')
head(as_tibble(elections))
print(nrow(elections))

contribs <- read.csv(file=paste(path, "/raw_data/campaignfinancialcontributions.csv", sep=""), sep=",", header=TRUE, stringsAsFactors=FALSE)

cat('contribs\n')
head(as_tibble(contribs))
print(nrow(contribs))

expends <- read.csv(file=paste(path, "/raw_data/campaignfinancialexpenditures.csv", sep=""), sep=",", header=TRUE, stringsAsFactors=FALSE)

cat('expends\n')
head(as_tibble(expends))
print(nrow(expends))


# both of these have: CANDIDATENAME; AMOUNT
# ugh are they not candidate-level??? contrib-lvl??

# some candidate names are empty...

#expends.empty <- expends %>% filter(CANDIDATENAME == "")
#cat('\n\nexpends.empty\n')
#head(expends.empty)
# empties in 'expends' are useless; toss




# ok, select & summarize shartmo

# pull out year first
expends$year <- substr(expends$TRANSACTIONDATE, 1, 4)



expends %<>% group_by(CANDIDATENAME, year) %>%
                summarize(amount = sum(AMOUNT)) %>%
		rename(candidate_name = CANDIDATENAME) %>%
		filter(candidate_name != "")

cat('\n\nexpends, collapsed\n')
head(as_tibble(expends), n=15)

#head(unique(expends$candidate_name))



# check contribs data for empty cand names
#contribs.empty <- filter(contribs, CANDIDATENAME == "")
#cat('\n\ncontribs.empty:\n')
#head(contribs.empty)
#cat('\nhow many\n')
#print(nrow(contribs.empty))
# this is 5000 in 65000
# that's gonna be a meh from me dawg
#head(unique(contribs.empty$COMMITTEENAME), n=20)
# don't see any useful names...


cat('\n\ncontribs, collapsed\n')
contribs$year <- substr(contribs$DATEOFRECEIPT, 1, 4)
#head(contribs$year)
# for semantic comparability; we also have a handy 'election_year' jawn here


# treating 'year' hackishly here for now
# ignoring election_year, for consistency's sake...
# how did Travis do this??
contribs %<>% group_by(CANDIDATENAME, year) %>%
                 summarize(amount = sum(AMOUNT)) %>%
		 filter(CANDIDATENAME != "") %>%
		 rename(candidate_name = CANDIDATENAME)
#		     election_year = ELECTIONYEAR)

head(contribs, n=15)


# find indices of expends, contribs with decent matches w/ election winner names
# by year?
# or just name-year pairs?


election.names <- elections %>% select(winner, year) %>%
                            rename(candidate_name = winner)


#LCS(unlist(strsplit(x[1], split="")), unlist(strsplit(x[2], split="")))$QSI

# compare candidate_name - year pairs
line.match <- function(election, campaign){

    #cat('\n\n3\n')
    
    if (election$year-2 < campaign$year & campaign$year < election$year + 1){
        return(LCS(unlist(strsplit(election$candidate_name, split="")), unlist(strsplit(campaign$candidate_name, split="")))$QSI)
        #return(eval.match(election$candidate_name, campaign$candidate_name))
    } else return(0)


}

linenum = 0

# compare one line of campaign finance data to all election data
# just stop at first match atmo...
find.election.match <- function(election.df, campaign.line){

    linenum <<- linenum + 1
    cat(paste("\ncf line", toString(linenum), '\n'))
    
    for(i in seq(nrow(election.df))){
        #cat(paste("\nelec line", toString(i), '\n'))

        if (line.match(election.df[i,], campaign.line) > .5) {
            cat("\nmatch\n")
            return(i)
        }
    }

    return(0)

}

# return vector of matching election indices (or 0) for each
#   campaign finance index
df.match <- function(election, campaign){

    #cat('\n\n1\n')
    match_indices = aaply(campaign, .margins=1,
          .fun=function(x){find.election.match(election, x)}, .expand=FALSE)

}

cat('\n\nDone\n')


# filter!!!
# keep track of the election-data indices in the contribs dataset...
contribs$election.match = df.match(election.names, contribs)
contribs.filtered <- contribs[contribs$election.match > 0,]

head(contribs.filtered, n=20)

# now how do we merge?? the names may not match...
# hold $election.match in both?

# non-matches were coded as 0 indices...
election.match.indices <- contribs$election.match[contribs$election.match > 0]


election.matches <- election.names[election.match.indices,]
election.matches$election.match <- election.match.indices

head(election.matches, n=20)

contribs.joined <- inner_join(contribs.filtered, election.matches, by = c("election.match"))

# did we fuck up the indexing??
contribs.join.check <- anti_join(contribs.filtered, election.matches, by = c("election.match"))
cat("\nany non-matches?\n")
head(contribs.join.check)

# did any match??
head(as.data.frame(contribs.joined), n=40)
# lol NOPE
# well Judi Jones 2015...











# Helper methods I was writing when I couldn't import qualV...

# length of longest common subsequence
llcs_recur <- function(s1, s2) {

    #cat('\n\n5\n')
    #print(s1)
    #print(s2)
    if (nchar(s1) == 0 | nchar(s2) == 0){
        #cat('\n5.1\n')
        return(0)
    } else if (str_sub(s1, -1, -1) == str_sub(s2, -1, -1)){
        #cat('\n5.2\n')
        return(1 + llcs(str_sub(s1, 1, -2), str_sub(s2, 1, -2)))
    } else {
        #cat('\n5.3\n')
        return(max(
	        llcs(str_sub(s1, 1, -2), str_sub(s2, 1, -1)),
		llcs(str_sub(s1, 1, -1), str_sub(s2, 1, -2))))
    }


}


llcs <- function(s1, s2){

    # create matrix
    m <- array(dim=c(length(s1), length(s2)))

    # iterate thruuu
    for (i in seq(length(s1))){
        for (j in seq(length(s2))){
            if (i==0 & j==0){
                
            }
        }
    }

}


# wrapper computing proportional match size
eval.match <- function(s1, s2){

    #cat('\n\n4\n')

    maxlen = max(nchar(s1), nchar(s2))
    
    if(maxlen == 0) return(0)
    else return(llcs(s1, s2) / maxlen)


    
#    return(tryCatch(llcs(s1, s2) / max(nchar(s1), nchar(s2)),
#                      error=function(){0}))
}
