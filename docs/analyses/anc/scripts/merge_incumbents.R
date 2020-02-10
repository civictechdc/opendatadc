

library(tidyverse)
library(qualV)

path = getwd()

election.data <- read.csv(paste(path, "/cleaned_data/election_history_R.csv", sep=""), 
                        sep=",", header=TRUE, stringsAsFactors=FALSE)

election.data <- filter(election.data, year==2018)

commissioner.data <- read.csv(paste(path, "/cleaned_data/2019_commissioners.csv", sep=""), 
                         sep=",", header=TRUE, stringsAsFactors=FALSE)
colnames(commissioner.data) <- tolower(colnames(commissioner.data))
commissioner.data <- commissioner.data %>% rename(contest_name=smd, commissioner_name=name) %>%
                        select(contest_name, commissioner_name)



merged <- full_join(election.data, commissioner.data, by="contest_name")

# remove "chairperson" from commissioner names 
merged <- merged %>% mutate(commissioner_name = trimws(sub("Chairperson", "", commissioner_name)))

# we also have to remove any commas in names because that will break the next import
merged <- merged %>% mutate(commissioner_name = sub(",", "", commissioner_name))

# Discern matches
matched <- merged %>% mutate(perfect_match = tolower(trimws(winner)) == tolower(commissioner_name))

# qualV::LCS isn't vectorized, so:
# create 2xnrow array of char arrays
# feed it to apply
# pull a numeric vector out the other end
winner_commissioner = array(dim=c(2, nrow(matched)))
winner_commissioner[1,] <- matched$winner
winner_commissioner[2,] <- matched$commissioner_name

matched$match_quality <- apply(winner_commissioner, c(2), 
                                 function(x) LCS(unlist(strsplit(x[1], split="")), 
                                                 unlist(strsplit(x[2], split="")))$QSI)
# dawg yes
matched$rough_match <- matched$match_quality > .5

unmatching <- matched %>% filter(!rough_match)


matched <- matched %>% mutate(write_in = grepl("write", tolower(winner)), 
                                vacant = grepl("vacant", tolower(commissioner_name)))
matched <- matched %>% mutate(switcharoo = !(write_in | vacant | rough_match))
# what could be going on here? recording issues? switching proximate SMDs? actual switches?

# what do we want to pull out of this?
# identify: write-ins which were real candidates
#   registered candidates who didn't assume seats
#   prop. vacant seats

matched <- matched %>% mutate(substantive_write_in = write_in & !vacant, 
                          absent = !write_in & vacant, empty = write_in & vacant)
table(matched$rough_match)
table(matched$substantive_write_in)
table(matched$absent)
table(matched$switcharoo)
table(matched$empty)

# clean up
matched <- matched %>% select(-write_in, -perfect_match, -match_quality) %>% rename(match = rough_match)

# check rough matching real quick
#rough_matches <- matched %>% filter(rough_match & !perfect_match) %>% 
#                                     select(contest_name, year, winner, commissioner_name)
# perfecto

# write

write.table(matched, file=paste(path, "/cleaned_data/2018_elections_commissioners.csv", sep=""), 
             append=FALSE, quote=FALSE, sep=",", row.names=FALSE, col.names=TRUE)


