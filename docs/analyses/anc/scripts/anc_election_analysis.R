

# analyzing ANC election data 2012-2018. Not considering any other datasets yet.


library(tidyverse)

# load data
path <- getwd()  # lacks trailing slash

#print(path)

election.data <- read.csv(file=paste(path, "/cleaned_data/election_history_R.csv", sep=""), 
                          header=TRUE, sep=",")

head(election.data)

# check counts; expect 296 obs per year
check <- election.data %>% group_by(year) %>% tally()
#print(check)
check2 <- election.data %>% group_by(year, ward) %>% tally()
#print(check2)


# ideas-----
# vote proportions across space
# candidates across space
# esp. uncontested and no candidates
# did a write-in ever beat a candidate??
# dist. of winning vote #s

election.data$write_in_winner <- grepl("write", tolower(election.data$winner))
election.data <- election.data %>% mutate(uncontested = explicit_candidates == 1, 
                        empty = explicit_candidates == 0, w_over_cand = write_in_winner & !empty)

sum <- election.data %>% group_by(ward, year) %>% summarize(cand = mean(explicit_candidates), 
                            votes = mean(winner_votes), vote_norm = mean(winner_votes / smd_ballots),
                            engagement = mean(smd_anc_votes / smd_ballots))
sum %>% print(n=nrow(.))
# note we should normalize 'votes' somehow
# proportion of smd ballots?



# how many times did write-ins beat filed candidates??
write.in <- election.data %>% group_by(ward, year, w_over_cand) %>% tally()
write.in <- write.in[write.in$w_over_cand == TRUE,]
write.in %>% print(n=nrow(.))

# just the total
print(election.data %>% group_by(w_over_cand) %>% tally())

# there are 66 elections where a write in beats a cand!!
# but none in 2012. hmmmm
# investigate:
usurpers <- election.data[election.data$w_over_cond,]
# grab from the original data!
# or, even easier, grab from merged data!
usurpers <- select(w, contest_name, year)
merged <- read.csv(paste(path, "/cleaned_data/2018_elections_commissioners.csv", sep=""), header=TRUE,
                           stringsAsFactors=FALSE)
usurpers_merged <- inner_join(merged, usurpers, by=c("contest_name", "year"))
# this only gives 2018 data, but it looks like 90% of write-in usurpers took office




# make some plots

# 2-lvl bar plot of voter engagement by ward, year

s <- as.data.frame(sum)


y <- ggplot(s, aes(ward, engagement)) + geom_point(stat="avg")
# what the actual fuck. this doesn't work if I call it on its own (produces blank graph)
#   but if I save it and then evalue it it works

g <- ggplot() + geom_point(data=s, mapping=aes(ward, engagement))
# this works too if I save + evaluate

y <- ggplot(s, aes(ward, engagement)) + geom_point(aes(colour=factor(year)))


##### Examples

ggplot(mpg, aes(class, hwy)) + geom_col(x=0, y=0)

g <- ggplot(mpg, aes(class))
# Number of cars in each class:
g + geom_bar()
# Total engine displacement of each class
g + geom_bar(aes(weight = displ))



# To show (e.g.) means, you need geom_col()
df <- data.frame(trt = c("a", "b", "c"), outcome = c(2.3, 1.9, 3.2))
ggplot(df, aes(trt, outcome)) +
  geom_col()
# But geom_point() displays exactly the same information and doesn't
# require the y-axis to touch zero.
ggplot(df, aes(trt, outcome)) +
  geom_point()

##### /Examples


# ditto candidates

y <- ggplot(s, aes(ward, cand)) + geom_point(aes(colour=factor(year)))


# maybe votes / vote_norm?

y <- ggplot(s, aes(ward, votes)) + geom_point(aes(colour=factor(year)))
y <- ggplot(s, aes(ward, vote_norm)) + geom_point(aes(colour=factor(year)))


# distribution of votes, vote_norm, candidates

# proportion of write-in candidates who were real








# more ideas
# did # candidates increase over time??
# how does votes relate to candidates?
#   1 vs. more than one; 1 vs. 0...







