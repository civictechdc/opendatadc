

library(tidyverse)
library(sf)
library(lwgeom)
library(magrittr)
# for some reason we need to get magrittr explicitly to get fancy pipes

path <- getwd()

# read in data on voter registrations and ballots cast by precinct/anc/year
regs <- read.csv(paste(path, "/cleaned_data/precinct_totals.csv", sep=""),
         header=TRUE, sep=",")

print(as_tibble(regs[order(regs$precinct),]))
# ah, this has double observations...
# OH! it just has double 2012 obs, which was cuz sloppy processing in election_cleaner.R

# Make table of # ANCs corresponding to each precinct
regs %<>% mutate(anc.full = paste(as.character(ward), as.character(anc), sep=""))
count <- regs %>% group_by(precinct) %>% summarize(ancs = length(unique(anc.full)))

# print some stuff
print("How many ANCs does each precinct lie in?")
print(count)
print("How many precincts cross N ANCs?")
print(count %>% group_by(ancs) %>% summarize(precincts = length(unique(precinct))))


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

print("Registration data @ precinct x ANC x year lvl")
print(collapsed)


# how many ANCs have duplicitous pcts?
count.anc <- collapsed %>% group_by(anc.full) %>%
            mutate(count.tot = length(unique(precinct))) %>%
            filter(duplicitous) %>%
            group_by(anc.full) %>%
            summarize(count.dup = length(unique(precinct)),
	            count.tot = unique(count.tot))
print("How many ancs have duplicitous precincts?")
print(count.anc)

# from ward 1 map, we know: 39 -> 1A, 1D, 1C (trivially)
# 36 1A 1B
# 37 is 1B + 1 block of 1A

cat("\n\ntest ward 1 precinct overlaps! (voting data)\n")
cat("expect: \n36 1A 1B\n39 1A 1D (1C)\n37 1A 1B\n")
ward1 <- regs %>% filter(ward == 1 & year == 2012) %>%
            group_by(precinct) %>%
	    summarize(ancs = reduce(unique(anc.full), paste))
print(ward1)
cat("\n\n\n")

# so at this point we could just toss precincts crossing ANCs (and lose around 40% of the data)
# or we could average them or something
# or we could give them weighted averages based on GIS data

# read in shapefiles
precinct_shapes <- st_read(paste(path, "/raw_data/precinct_shapes_2012/Voting_Precinct__2012.shp", sep=""))
anc_shapes <- st_read(paste(path, "/raw_data/anc_2013/Advisory_Neighborhood_Commissions_from_2013.shp", sep=""))

#print(anc_shapes)

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

#print(overlap)

print("how many entries do we get in the overlap dataset?")
print(nrow(overlap))
print("how many did we start with in the election data grouped by anc x pct?")
print(nrow(collapsed) / 4)





# these aren't far off, so it's clealy only including shapes with intersections -- it just might be counting some trivial ones

#print("how many of the intersections in 'overlap' are nontrivial?")
#print(nrow(overlap[overlap$area > 10,]))

# what are the units? it's like 7-digit numbers... sq meters, feet, lat/lon minutes???

#hist(overlap$area, breaks=200)

# well... we could start by restricting it to ones noted in 'collapsed'

# how do we test??
# plot shapes
#   plot questionable (small) overlaps
# cross-ref 'overlap' with 'collapsed'

# note there are different types of geometries in the 'overlap' set
# in the originals it's just polygons
# in 'overlap' -- polygon, multipolygon, geometrycollection (point; linestr...)


# 0. get relative areas of precincts in diff ANCs

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

#print(overlap)
#hist(overlap$rel.area, breaks=100)



#hist(overlap$rel.area, breaks=100)
# Test vs. ward 1 map
cat("\ntest ward 1 precinct overlaps! (geo data)\n")
cat("expect: \n36 1A 1B\n39 1A 1D (1C)\n37 1A 1B\n")
ward1 <- overlap[regexpr("1", overlap$anc.full) > 0,] %>%
               filter(rel.area > .01) %>%
               group_by(precinct) %>%
	       summarize(ancs = reduce(unique(anc.full), paste),
	           min.area = min(over.area)) %>%
	       filter(regexpr(" ", ancs)>0)
print(ward1)
cat("\nMatches election data at 1% relative area cutoff (to toss noise)\n")
cat("\n\n\n")



# 1. cross-reference with reg data

overlap %<>% mutate(precinct = as.integer(precinct))
crossref <- full_join(overlap, collapsed, by=c("anc.full", "precinct"))


print(crossref)
# everything's double here. why?
# collapsed is double...

# who's left hanging?
# rel.area represents 'overlap'; duplicitous reps 'collapsed'
# what do we expect?
#   hopefully nobody left hanging from 'collapsed'
print("Any precinct-ANC combos from voting data missing from GIS data?")
hanging.vote <- crossref %>% filter(is.na(rel.area), year==2012)
print(nrow(hanging.vote))
print(hanging.vote)
cat("\n\n\n")
# with no rel.area filtering, we get 3 missing, one of which is 'duplicitous'
#   why would we get non-duplicitous hanging??? funny.

#  ************************** Look into this ^^  *************************
# the non-duplicitous ones are 4G which is the extension of 3G into ward 4!! so coded inconsistently I believe.
# The other one is 2D

print("Are any precinct-ANC combos from GIS data missing from voting data?")
hanging.gis <- crossref %>% filter(is.na(duplicitous))
print(nrow(hanging.gis))
#print(hanging.gis)
# there's 5 (when we drop at 10% rel.area):
# 2A prec 6; 3G prec 51; 7B prec 107; 3G prec 52; 6D prec 129


# what does relative area look like cond. on 'duplicitous'?
#crossref %>% filter(duplicitous, is.numeric(rel.area)) %>% hist(as.numeric(rel.area), breaks=100)
# ^^ not working


# 2. Make some numbers!

# 2a. Naive way -- drop crossing precincts

# 2b. Fancy way -- proportional to relative area

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

write.table(reg.fixed, file=paste(path, "/cleaned_data/anc_turnout.csv", sep=""), sep=",", append=FALSE, quote=FALSE, row.names=FALSE, col.names=TRUE)





# circle back to 2a. Dropping Style

reg.fixed.drop <- collapsed %>% filter(!duplicitous) %>%
                    group_by(anc.full, year) %>%
		    summarize(voters = round(sum(voters)),
		           ballots = round(sum(ballots)))

reg.fixed.drop %<>% mutate(turnout = ballots / voters)

write.table(reg.fixed.drop, file=paste(path, "/cleaned_data/anc_turnout_drop.csv", sep=""), sep=",", append=FALSE, quote=FALSE, row.names=FALSE, col.names=TRUE)

