


#' ---
#' title: "Imputing turnout at ANC-level using precinct data"
#' output: html_document
#' ---

#+ setup, warning=FALSE, message=FALSE, echo=FALSE, results='hide'

library(tidyverse)
library(sf)
library(lwgeom)
library(magrittr)
# for some reason we need to get magrittr explicitly to get fancy pipes

knitr::opts_chunk$set(echo=FALSE, results='hide')

#path <- getwd()
wd <- unlist(strsplit(getwd(), "/"))
wd <- wd[length(wd)]
prefix <- ifelse(wd=="scripts", "../", "")


# read in data on voter registrations and ballots cast by precinct/anc/year
regs <- read.csv(paste(prefix, "cleaned_data/2012_2018_ballots_precinct.csv", sep=""),
         header=TRUE, sep=",")


#' ### Look at registration/ballot data
#+ echo=FALSE, results='show'

print(as_tibble(regs[order(regs$precinct),]))
# ah, this has double observations...
# OH! it just has double 2012 obs, which was cuz sloppy processing in election_cleaner.R

# Make table of # ANCs corresponding to each precinct
regs %<>% mutate(anc.full = paste(as.character(ward), as.character(anc), sep=""))
count <- regs %>% group_by(precinct) %>% summarize(ancs = length(unique(anc.full)))

# print some stuff

#' How many ANCs does each precinct lie in?
#+ results='show'
print(count)

#' How many precincts cross N ANC's?
#+ results='show'
print(count %>% group_by(ancs) %>% summarize(precincts = length(unique(precinct))))


#' ### Check how many precincts cross ANC boundaries
#+

# Merge data on 'duplicitous' precincts w/ registration data
#   and collapse from contest-level to ANC x precinct x year
collapsed <- count %>%
        mutate(duplicitous = (ancs > 1)) %>%
	inner_join(regs, by=c("precinct")) %>%
	rename(voters = registered_voters) %>%
	select(anc.full, precinct, year, duplicitous, voters, ballots)


#	group_by(anc.full, precinct, year) %>%
#       summarize(
#            duplicitous = unique(duplicitous),
#            voters = unique(registered_voters),
#            ballots = unique(ballots))
# this collapse should be obviated by the fixed input data...

#' Precinct-level registration data with 'duplicitous' added
#+ results='show'
print(collapsed)


# how many ANCs have duplicitous pcts?
count.anc <- collapsed %>% group_by(anc.full) %>%
            mutate(count.tot = length(unique(precinct))) %>%
            filter(duplicitous) %>%
            group_by(anc.full) %>%
            summarize(count.dup = length(unique(precinct)),
	            count.tot = unique(count.tot))

#' How many ANCs have duplicitous precincts?
#+ results='show'
print(count.anc)

#' Use ward 1 as sanity check  
#' from ward 1 map, we know:  
#' 39 -> 1A, 1D, 1C (trivially)  
#' 36 1A 1B  
#' 37 is 1B + 1 block of 1A  
#'   
#' Test ward 1 precinct overlaps! (in voting data)  
#' expect:  
#' 36 1A 1B  
#' 39 1A 1D (1C)  
#' 37 1A 1B  
#+ results='show'
ward1 <- regs %>% filter(ward == 1 & year == 2012) %>%
            group_by(precinct) %>%
	    summarize(ancs = reduce(unique(anc.full), paste))
print(ward1)

#' so at this point we could just toss precincts crossing ANCs (and lose around 40% of the data)  
#' or we could average them or something  
#' or we could give them weighted averages based on GIS data....  
#'   

#' ### Shapefiles
#+ echo=TRUE
# read in shapefiles
precinct_shapes <- st_read(paste(prefix, "raw_data/precinct_shapes_2012/Voting_Precinct__2012.shp", sep=""))
anc_shapes <- st_read(paste(prefix, "raw_data/anc_2013/Advisory_Neighborhood_Commissions_from_2013.shp", sep=""))

#print(anc_shapes)


#' compute intersections between ANC & precinct shapes
#+ echo=TRUE
# compute shape overlaps
overlap <- st_intersection(anc_shapes, precinct_shapes) %>%
        mutate(over.area = st_area(.) %>% as.numeric()) %>%
	rename(.anc = NAME, .precinct = NAME.1) %>%
	select(.anc, .precinct, over.area)


# parse ANC & precinct identifiers better
overlap %<>%
        mutate(anc.full =
	    regmatches(.anc, regexpr("[[:digit:]][[:alpha:]]$", .anc))) %>%
	mutate(precinct =
	    regmatches(.precinct, regexpr("[[:digit:]]+", .precinct)))
overlap %<>% select(anc.full, precinct, over.area)
#+ results='show'
head(overlap)

#'   
#' How many entries do we get in the overlap dataset?
#+ results='show'
print(nrow(overlap))
#' How many did we start with in the election data grouped by anc x pct?
#+ results='show'
print(nrow(collapsed) / 4)





#' these aren't wildly off, so it's clearly only including shapes with intersections -- it just might be counting some trivial ones  
#'   
#' how many of the intersections in 'overlap' are nontrivial?  
#+ results='show'
print(nrow(overlap[overlap$over.area > 10,]))

#' what are the units? it's like 7-digit numbers... sq meters, feet, lat/lon minutes???
#+ results='show'
hist(overlap$over.area, breaks=200)
# broken...


# well... we could start by restricting it to ones noted in 'collapsed'

# how do we test??
# plot shapes
#   plot questionable (small) overlaps
# cross-ref 'overlap' with 'collapsed'

# note there are different types of geometries in the 'overlap' set
# in the originals it's just polygons
# in 'overlap' -- polygon, multipolygon, geometrycollection (point; linestr...)


# 0. get relative areas of precincts in diff ANCs

#' compute relative areas of intersections w/r/t precincts  
#+ echo=TRUE
# get precinct total areas
precinct.areas <- precinct_shapes %>%
            mutate(area = st_area(.) %>% as.numeric(),
                precinct = regmatches(NAME, regexpr("[[:digit:]]+", NAME)))
precinct.areas <- tibble(precinct=precinct.areas$precinct,
                            prec.area=precinct.areas$area)

# merge with overlap areas
overlap %<>% inner_join(precinct.areas, by=c("precinct"))

#print(overlap)

# compute relative area of ANCxprec as [area of overlap] / [precinct area]
overlap %<>% mutate(rel.area = over.area / prec.area)


#+ results='show'
head(overlap)
hist(overlap$rel.area, breaks=100)


# Test vs. ward 1 map
#' Test ward 1 precinct overlaps! (geo data)  
#' Expect:  
#' 36 1A 1B  
#' 39 1A 1D (1C)  
#' 37 1A 1B  
#+ results='show'
ward1 <- overlap[regexpr("1", overlap$anc.full) > 0,] %>%
               filter(rel.area > .01) %>%
               group_by(precinct) %>%
	       summarize(ancs = reduce(unique(anc.full), paste),
	           min.area = min(over.area)) %>%
	       filter(regexpr(" ", ancs)>0)
print(ward1)

#' Matches election data at 1% relative area cutoff (to toss noise)  
#+

#' ### Cross-reference with reg data
#+ echo=TRUE, results='show'
overlap %<>% mutate(precinct = as.integer(precinct))
crossref <- full_join(overlap, collapsed, by=c("anc.full", "precinct"))


print(crossref)
# everything's double here. why?
# collapsed is double...

# who's left hanging?
# rel.area represents 'overlap'; duplicitous reps 'collapsed'
# what do we expect?
#   hopefully nobody left hanging from 'collapsed'

#' Any precinct-ANC combos from voting data missing from GIS data?
#+ results='show'
hanging.vote <- crossref %>% filter(is.na(rel.area), year==2012)
print(nrow(hanging.vote))
print(hanging.vote)
#' with no rel.area filtering, we get 3 missing, one of which is 'duplicitous'   
#' why would we get non-duplicitous hanging??? funny.  

#'  ************************** Look into this ^^  *************************  
#' the non-duplicitous ones are 4G which is the extension of 3G into ward 4!! just coded inconsistently I believe.  
#' The other one is 2D  

#' Are any precinct-ANC combos from GIS data missing from voting data?
#+ results='show'
hanging.gis <- crossref %>% filter(is.na(duplicitous))
print(nrow(hanging.gis))
#print(hanging.gis)
#' there's 5 (when we drop at 10% rel.area):  
#' 2A prec 6; 3G prec 51; 7B prec 107; 3G prec 52; 6D prec 129  


# what does relative area look like cond. on 'duplicitous'?
#crossref %>% filter(duplicitous, is.numeric(rel.area)) %>% hist(as.numeric(rel.area), breaks=100)
# ^^ not working


#' ### Compute turnout, weighting ambiguous precincts by goegraphic overlap
#+ echo=TRUE, results='show'

# drop hanging gis data
crossref %<>% filter(!is.na(duplicitous))

# fix hanging vote data, first dropping duplicitous prec's w/ missing GIS
crossref %<>% filter(!(is.na(rel.area) & duplicitous))
crossref %<>% mutate(rel.area = ifelse(is.na(rel.area), 1, rel.area))


# gotta... recompute 'duplicitous' I think?
crossref %<>% group_by(precinct, year) %>%
                mutate(duplicitous = length(unique(anc.full))>1)
# and then make sure nonduplicitous obs have area 1
print("how many non-duplicitous precincts have rel.area  < 1?")
print(nrow(crossref %>% filter(!duplicitous & rel.area < 1)))
# eeeek 350 fail this! of 850
#hist(crossref$rel.area[!crossref$duplicitous], breaks=50)
# but it doesn't look bad bad
# this will probably be because of dropping trivial overlaps

# force non-duplicitous to 1
# tho ideally we'd like to fix all dropped areas...
# ah! could normalize sums!
# at ANC level
# so then all we need is to have rel.area numbers for all obs
#   which we do per above!
# ah wait no I'm confused -- should think abt pct or anc??
#   we convert area to ballots based on precinct totals
#   so to avoid losing ballots we should renormalize @ pct lvl
#   we might simply calculate rel.area without precinct.area, & after dropping

crossref %<>% group_by(precinct, year) %>%
                mutate(norm.area = over.area / sum(over.area)) 
cat("\n\nHow big a chance is norm.area vs. rel.area??\n(fivenum of diff)\n")
print(fivenum(crossref$norm.area - crossref$rel.area))
cat("\n\n")

# do the thing!
crossref %<>% mutate(voters = voters * norm.area, ballots = ballots * norm.area)


# aggregate up to ANC
reg.fixed <- crossref %>% group_by(anc.full, year) %>%
               summarize(voters = round(sum(voters)),
	           ballots = round(sum(ballots)),
		   duplicitous = sum(duplicitous))


# drop geo data 
reg.fixed <- tibble(anc.full = reg.fixed$anc.full, year=reg.fixed$year,
                   voters=reg.fixed$voters, ballots=reg.fixed$ballots,
		   duplicitous=reg.fixed$duplicitous)

# get turnout
reg.fixed %<>% mutate(turnout = ballots / voters)

print(reg.fixed)

write.table(reg.fixed, file=paste(prefix, "cleaned_data/2012_2018_imputedTurnout_anc.csv", sep=""), sep=",", append=FALSE, quote=FALSE, row.names=FALSE, col.names=TRUE)




#+
#' ### Recompute turnout by dropping ANC-crossing precincts
#+ echo=TRUE

reg.fixed.drop <- collapsed %>% filter(!duplicitous) %>%
                    group_by(anc.full, year) %>%
		    summarize(voters = round(sum(voters)),
		           ballots = round(sum(ballots)))

reg.fixed.drop %<>% mutate(turnout = ballots / voters)

#write.table(reg.fixed.drop, file=paste(prefix, "cleaned_data/2012_2018_imputedTurnoutDrop_anc.csv", sep=""), sep=",", append=FALSE, quote=FALSE, row.names=FALSE, col.names=TRUE)












#+


# Try to exit before test code if we're running a straight Rscript...
if(sys.nframe() == 0L){
    quit(save='no')
}


#' ## Testing Imputed Turnout

#' We would like to have voter turnout data at the ANC level as another variable to contextualize engagement in ANC elections, but we only have # registered voters at precinct-level, which doesn't align nicely with ANCs (though for 2014 and later, we have # ballots cast at ANC-level, which we'll use to test).

#' ## Merge together dropping and apportioning turnout estimates with election data

#+ merge, results='show'

reg.fixed.drop %<>% select(anc.full, year, turnout) %>%
                    rename(turnout.drop = turnout)


reg.fixed %<>% full_join(reg.fixed.drop, by=c("anc.full", "year"))


cat("\nCheck turnout-turnout merge\n\n")
tmp <- reg.fixed %>% filter(is.na(turnout) | is.na(turnout.drop))
print(tmp)

# Do a final test of match with election ballot data!

election.data <- read.csv(file="../cleaned_data/2012_2018_ancElection_contest.csv", sep=",", header=TRUE)

election.data %<>% mutate(anc.full = paste(ward,anc,sep="")) %>%
                  group_by(anc.full, year) %>%
                  summarize(actual.ballots = sum(smd_ballots)) %>%
		  select(anc.full, year, actual.ballots)

ballot.check <- reg.fixed %>%
                  inner_join(election.data, by=c("anc.full", "year")) %>%
                  mutate(error = ballots - actual.ballots,
		      rel.error = error / actual.ballots)

# merge is good
print("Who's missing from the election data?")
merge.e <- anti_join(reg.fixed, election.data, by=c("anc.full", "year"))
print(merge.e)

print("Who's missing from the turnout data?")
merge.t <- anti_join(election.data, reg.fixed, by=c("anc.full", "year"))
print(merge.t)


#' OH the reason I was seeing a bunch of NAs below is cuz missing 2012 data! so it's not so bad. what we are missing is 4G (from election data, cuz it's 3G) and 2F 3B 3F from turnout data. weird!  

#' don't forget to full_join the two turnouts!!


#' # Compare estimated ballots with post-2012 actual ballots

#+ check, results='show'
w = ggplot(ballot.check, aes(rel.error)) + geom_histogram(binwidth=.05) +
                labs(title="Distribution of Relative Error in Estimating Ballots")
show(w)
print("hmm. a number of obs off by more than 1000. sharks.")


print("How Bad is It????")
print("(fivenum of diff)")
print(fivenum(ballot.check$error))
print("(diff in fivenums)")
print(fivenum(ballot.check$ballots) - fivenum(ballot.check$actual.ballots))



#' ## Make some plots

#+ plots, results='show'
# Make a Plot
x <- ggplot(ballot.check) +
            geom_point(aes(actual.ballots, ballots,
	                colour=factor(duplicitous))) +
	    labs(title="How well does our estimate correspond to recorded ballots?")
show(x)
# doesn't look so bad here, but outliers are notable

# which ones are off??
cat("\nWhich ANCs have significant relative error in est. ballots?\n\n")
print(filter(ballot.check, abs(rel.error)>.25))
# I could keep some stuff like duplicitous count in reg.fixed...
# 3G, 2F, 2A 2018 are real farcked
# they aren't super small
# nor overly duplicitous
# do they have widely varying population densities?

# tag error outliers
ballot.check %<>% mutate(outlier = abs(rel.error)>.25)

y <- ggplot(ballot.check) + geom_point(aes(ballots, turnout, colour=factor(outlier))) +
                labs(title="How does estimated turnout relate to estimated ballots?")
show(y)
# what to make of this?? some ANCs have very low turnout, but only when they have few... ballots... aha. IV should be registrations maybe?

z <- ggplot(ballot.check) + geom_point(aes(turnout, turnout.drop, colour=factor(outlier))) +
                labs(title="How close are our two measures of turnout?")
show(z)
# looks tight. perhaps three outliers...
ballot.check %<>% mutate(turnout.diff = turnout - turnout.drop)
ballot.check <- ballot.check[order(ballot.check$turnout.diff),] 
cat("\nWhich ANCs have the greatest discrepancy between turnout and turnout.drop?\n\n")
print(head(ballot.check))
# ********* Q: are these the same as outliers in plot above??


