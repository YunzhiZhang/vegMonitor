# Set up working directory
setwd("<working directory>")

# Libraries needed
library(rgdal)
library(raster)
library(snow)
library(MASS)
library(igraph)

# Import and variables definition
rlist<-list.files(path="<source directory>", pattern="tif$", full.names = TRUE)
s<- stack(rlist)
s1 <- stack(rlist[1:14])
s2 <- stack(rlist[7:21])
s3 <- stack(rlist[15:26])
s2013 <- stack(rlist[1:6])
s2014 <- stack(rlist[7:14])
s2015 <- stack(rlist[15:21])
s2016 <- stack(rlist[22:26])
nacount <- sum(is.na(s))
nacount2013 <- sum(is.na(s2013))
nacount2014 <- sum(is.na(s2014))
nacount2015 <- sum(is.na(s2015))
nacount2016 <- sum(is.na(s2016))

Overall median generation
for(i in 1:length(names(s)))
{
s[[i]][nacount[] >= 14] <- NA
}

beginCluster()
tsSortM <- calc(s, fun=median, na.rm = T)
endCluster()

# Annual median, median difference and buffer generation
for(i in 1:length(names(s2013)))
{
s2013[[i]][nacount2013[] >= 4] <- NA
}
for(i in 1:length(names(s2014)))
{
s2014[[i]][nacount2014[] >= 5] <- NA
}
for(i in 1:length(names(s2015)))
{
s2015[[i]][nacount2015[] >= 4] <- NA
}
for(i in 1:length(names(s2016)))
{
s2016[[i]][nacount2016[] >= 3] <- NA
}

beginCluster()
tsM2013 <- calc(s2013, fun=median, na.rm = T)
tsM2014 <- calc(s2014, fun=median, na.rm = T)
tsM2015 <- calc(s2015, fun=median, na.rm = T)
tsM2016 <- calc(s2016, fun=median, na.rm = T)
mstack1 <- stack(tsM2013, tsM2014)
mstack2 <- stack(tsM2014, tsM2015)
mstack3 <- stack(tsM2015, tsM2016)
subtract <- function(x){
d = x[[2]]-x[[1]]
return(d)
}
tsMD_2013_2014 <- calc(mstack1, fun=subtract)
tsMD_2014_2015 <- calc(mstack2, fun=subtract)
tsMD_2015_2016 <- calc(mstack3, fun=subtract)
endCluster()

buffer1 <- tsMD_2013_2014; buffer1[tsM2014[] <= 2] <- NA
buffer2 <- tsMD_2014_2015; buffer2[tsM2015[] <= 2] <- NA
buffer3 <- tsMD_2015_2016; buffer3[tsM2016[] <= 2] <- NA

buffer1[buffer1[] < 1] <- NA
buffer2[buffer2[] < 1] <- NA
buffer3[buffer3[] < 1] <- NA

# Cleaning up groups for U-test
for(i in 1:6)
{
s1[[i]][nacount2013[] >= 4] <- NA
}
for(j in 7:14)
{
s1[[j]][nacount2014[] >= 5] <- NA
}
for(i in 1:8)
{
s2[[i]][nacount2014[] >= 5] <- NA
}
for(j in 9:15)
{
s2[[j]][nacount2015[] >= 4] <- NA
}
for(i in 1:7)
{
s3[[i]][nacount2015[] >= 4] <- NA
}
for(j in 8:12)
{
s3[[i]][nacount2016[] >= 3] <- NA
}

# Applying U-test on buffer stack
buffer <- stack(buffer1, buffer2, buffer3)
customUTest <- function(x, i, n1, n2){
extract <- extract(buffer[[i]], c(1:length(buffer[[i]])))
cellno <- which(!is.na(extract) == TRUE)
pb <- txtProgressBar(min = 0, max = length(cellno), initial = 0, char = "=",
width = NA, title, label, style = 3, file = "")

for(k in 1:length(cellno)){
e1 <- as.vector(extract(x[[1:n1]], c(cellno[k])))
e1 <- e1[!is.na(e1)]
e2 <- as.vector(extract(x[[(n1+1):n2]], c(cellno[k])))
e2 <- e2[!is.na(e2)]
p <- wilcox.test(e1, e2, alternative = "less")$p.value
buffer[[i]][cellno[k]] <- p
Sys.sleep(0.1)
setTxtProgressBar(pb, k, title = NULL, label = NULL)
}
return(buffer[[i]])
close(pb)
}

beginCluster()
test2013_2014 <- customUTest(s1, i=1, n1=6, n2 = 14)
test2014_2015 <- customUTest(s2, i=2, n1=8, n2 = 15)
test2015_2016 <- customUTest(s3, i=3, n1=7, n2 = 12)
endCluster()

# Filter p-value to obtain raw pixels
test2013_2014_Raw <- test2013_2014; test2013_2014_Raw [test2013_2014_Raw[] > 0.05] <- NA
test2014_2015_Raw <- test2014_2015; test2014_2015_Raw[test2014_2015_Raw[] > 0.05] <- NA
test2015_2016_Raw <- test2015_2016; test2015_2016_Raw[test2015_2016_Raw[] > 0.05] <- NA

# Filter raw pixels to obtain clump pixels
test_Clump <- stack(test2013_2014_Raw, test2014_2015_Raw, test2015_2016_Raw)

for(i in 1:3){
testClump <- clump(test_Clump[[i]], directions=8, gaps = TRUE)
clumpFreq <- freq(testClump)
clumpFreq <- as.data.frame(clumpFreq)
excludeID <- clumpFreq$value[which(clumpFreq$count==1)]
test_Clump[[i]][testClump %in% excludeID] <- NA
}

test2013_2014_Clump <- test_Clump[[1]]
test2014_2015_Clump <- test_Clump[[2]]
test2015_2016_Clump <- test_Clump[[3]]
