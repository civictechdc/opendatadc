

path <- getwd()
years <- c("2012", "2014", "2016", "2018")

all.data <- NULL

for(year in years){
	
	# read in data
	data <- read.table(file=paste(path, "/data/", year, ".csv", sep=""), header=TRUE, sep=",")
	
	# If this is the first iteration, initialize
	if(is.null(all.data)) all.data <- data[0,]
	
	print(paste("start year", year))
	print(colnames(data))	
	
	### Wrangle column name inconsistencies
	
	# first, reassign colnames as lowercase
	colnames(data) <- tolower(colnames(data))
	# find index of contest name
	cn.index <- grep("contest_?name", colnames(data))
	# R is 1-indexed
	# this is just for the benefit of the 2018 file which omits the underscore
	colnames(data)[cn.index] <- "contest_name"
	colnames(data)[grep("precinct", colnames(data))] <- "precinct"
	# ward, candidate, votes should already be fine
	# whoops, fix ward for 2018's sake
	colnames(data)[grep("ward", colnames(data))] <- "ward"
	
	
	### Drop irrelevant columns
	
	# things we wanna drop:
	c <- colnames(data)
	drop.indices <- c(grep("election", c), grep("contest_?(id|number)", c), grep("party", c))
	# note we don't drop precinct because SMDs may cross precincts
	colnames(data)[drop.indices] <- "drop"
	data[grep("drop", colnames(data))] <- NULL
	# got an extra line there bro
	colnames(data)
	
	# add year
	data$year <- rep(year, dim(data)[1])
	# can also do this with cbind(data, year) after creating vector year
	
	print("dropped irrelevant columns")
	print(dim(data))
	
	
	### Drop non-ANC obs
	
	reg <- "[[:digit:]][[:upper:]][[:digit:]]{2}"
	print(str(data$contest_name))
	print(grep(reg, data$contest_name, fixed=FALSE))
	data <- data[grep(reg, data$contest_name),]
	
	print("dropped non-ANC obs")
	print(dim(data))
	
	# reformat contest name to be just 6B04 e.g.
	data$contest_name <- regmatches(data$contest_name, regexpr(reg, data$contest_name))
	
	
	# break out to ANC and smd fields (already have ward)
	data$anc <- regmatches(data$contest_name, regexpr("[[:alpha:]]", data$contest_name))
	data$smd <- regmatches(data$contest_name, regexpr("[[:digit:]]{2}$", data$contest_name))
	
	
	
	
	#### Collapse
	# Want to collapse down to contest level, right now just collapsing to candidate
	
	smd.list <- unique(data$contest_name)
	
	# ooh when I try grabbing a SMD it seems like obs are dublicated. why??
	# ah. SMDs may cross precincts. so keep precinct above!
	
	# gotta sort before we get into this...
	# cause will assume candidates are sorted when reshaping
	data <- data[order(data$contest_name, data$candidate),]
	
	# initialze new data.frame with same column names
	wide.data <- data[0,]
	
	# loop over unique SMDs, collapsing over precincts down to candidate level
	for(smd in smd.list){
		# find the smd
		smd <- data[data$contest_name == smd,]
		# handle multiple precincts
		precincts <- unique(smd$precinct)
		smd.new <- NULL
	    for(pre in precincts){
	    	smd.pre <- smd[smd$precinct == pre,]
	    	if (is.null(smd.new)){
	    		smd.new <- smd.pre
	    	} else{
	    		# assert smd.new and smd.pre have same # obs
	    		if(dim(smd.new)[1] != dim(smd.pre)[1]){
	    			stop(simpleError(paste("Precinct data w/in SMD ", str(pre), " differ in dimension!", sep="")))
	    		}
	    		smd.new$votes <- smd.new$votes + smd.pre$votes
	    	}
	    }
	    
	    # boo runtime
	    wide.data <- rbind(wide.data, smd.new)
	}
	
	# precinct is no longer meaningful
	wide.data$precinct <- NULL
	
	# some years have whitespace in candidate names
	wide.data$candidate <- strwrap(wide.data$candidate)
	
	print("year done")
	print(dim(wide.data))
		
	# append to other years
	all.data <- rbind(all.data, wide.data)
		
}

# sort for easier sanity checking
all.data <- all.data[order(all.data$year, all.data$contest_name, all.data$candidate),]


write.table(all.data, file=paste(path, "/data/", "allyears", "_filtered.csv", sep=""), append=FALSE, quote=FALSE, sep=",", row.names=FALSE, col.names=TRUE)



