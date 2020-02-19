
# data processing with an eye to ANC-level map visualization


library(tidyverse)

#path <- getwd()
wd <- unlist(strsplit(getwd(), "/"))
wd <- wd[length(wd)]
prefix <- ifelse(wd=="scripts", "../", "")


# this doesn't need to be only 2018, could grab the 4-year dataset instead
data <- read.csv(paste(prefix, "cleaned_data/2012_2018_ancElection_contest.csv", sep=""),
                 sep=",", header=TRUE)

check <- data %>% group_by(year) %>% tally()
print(check)

# wrangle variables
data$write_in_winner <- grepl("write", tolower(data$winner))
data <- data %>% mutate(uncontested = explicit_candidates == 1, 
                        empty = explicit_candidates == 0, w_over_cand = write_in_winner & !empty)

# collapse to ANC
sum <- data %>% group_by(ward, year, anc) %>% summarize(num_candidates = mean(explicit_candidates), 
                            votes = mean(winner_votes), vote_norm = mean(winner_votes / smd_anc_votes),
                            engagement = mean(smd_anc_votes / smd_ballots),
                            prop_uncontested = mean(uncontested), prop_empty = mean(empty))
sum %>% print(n=nrow(.))


write.table(sum,
            file=paste(prefix, "cleaned_data/2012_2018_ancElection_anc.csv", sep=""),
            append=FALSE, quote=FALSE, sep=",", row.names=FALSE, col.names=TRUE)


