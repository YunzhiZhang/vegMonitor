### load libraries ###

if(!require(raster)) install.packages("raster")
library(raster)

if(!require(rgdal)) install.packages("rgdal")
library(rgdal)

if(!require(snow)) install.packages("snow")
library(snow)

if(!require(MASS)) install.packages("MASS")
library(MASS)

if(!require(igraph)) install.packages("igraph")
library(igraph)

### main function ###

vegLossDetection <- function(imgVector, grouping, coarse, test, pval, directions, genLogs, writePath, format){
  
  ### check dependencies ###
  
  if(is.null(imgVector)){
    stop("please specify a vector containing absolute string paths with endings for images")
  }
  
  if(is.null(grouping)){
    stop("please specify a list of vectors containing the indices of images to be grouped")
  } else if(!is.list(grouping)){
    stop("please input grouping as a list of vectors")
  }
  
  if(is.null(test)){
    test <- "generic.change"
    warning(paste0("no input for test detected, defaulting to ", test))
  }
  
  if(is.null(coarse)){
    coarse <- TRUE
    warning(paste0("no input for coarse provided, defaulting to ", coarse))
  }
  
  if(is.null(pval)){
    pval <- 0.05
    warning(paste0("no input for pval detected, defaulting to ", pval))
  }
  
  if(is.null(directions)){
    directions <- 8
    warning(paste0("no input for directions detected, defaulting to ", directions))
  }
  
  if(is.null(genLogs)){
    genLogs <- TRUE
    warning(paste("no genLogs supplied, defaulting to ", genLogs, sep = ""))
  }
  
  if(is.null(writePath)){
    writePath = paste(getwd(), "/output/vegClassification", sep = "")
    warning(paste("no writePath supplied, defaulting to ", writePath, sep=""))
    
    if(!file.exists(writePath)){
      warning(paste(writePath, " does not exist, creating directory instead...", sep=""))
      dir.create(writePath)
    }
    
  } else if (substr(writePath, nchar(writePath), nchar(writePath)) == "/") {
    writePath <- substr(writePath, 1, nchar(writePath)-1)
    if (!file.exists(writePath)) {
      stop(paste("the directory ", writePath, " does not exist", sep=""))
    }
  } else if (!file.exists(writePath)) {
    stop(paste("the directory ", writePath, " does not exist", sep=""))
  }
  
  if(is.null(format)){
    format <- "GTiff"
    warning(paste("no format provided, defaulting to ", format, sep=""))
  }
  
  source("./aux/pairing.R", encoding = "UTF-8")
  source("./aux/subtract.R", encoding = "UTF-8")
  
  ### body ###

  g <- lapply(grouping, function(x) return(stack(imgVector[x])))
  gNA <- lapply(g, is.na)
  
  # clean individual images for cleaner median calculation, remove large NA stacks
  
  for(i in 1:length(g)){
    for(j in 1:length(names(g[[i]]))){
      g[[i]][[j]][gNA[[i]][[j]] > length(names(g[[i]]))/2] <- NA
    }
  }
  
  f <- lapply(pairing(g), function(x) return(stack(x)))
  
  # generate medians of individual groups and stack consecutive medians, subtract medians to get buffers

  gM <- lapply(g, function(x) return(calc(x, fun=median, na.rm=T)))
  fM <- lapply(pairing(gM), function(x) return(stack(x)))
  diff <- lapply(fM, function(x) return(calc(x, fun=subtract)))
  
  # limiting search spaces for diff based on coarse option and test type
  
  if(test=="generic.change"){
    test="two.sided"
    if(coarse==TRUE){
      for(i in 1:length(diff)){
        diff[[i]][diff[[i]] < 1 && diff[[i]] > -1] <- NA
      }
    } else{
      for(i in 1:length(diff)){
        diff[[i]][diff[[i]] < 0.5 && diff[[i]] > -0.5] <- NA
      }
    }
  } else if(test=="increase") {
    test="less"
    if(coarse==TRUE){
      for(i in 1:length(diff)){
        diff[[i]][diff[[i]] < 1] <- NA
      }
    } else{
      for(i in 1:length(diff)){
        diff[[i]][diff[[i]] < 0.5] <- NA
      }
    }
  } else if(test=="decrease"){
    test="greater"
    if(coarse==TRUE){
      for(i in 1:length(diff)){
        diff[[i]][diff[[i]] > -1] <- NA
      }
    } else{
      for(i in 1:length(diff)){
        diff[[i]][diff[[i]] > -0.5] <- NA
      }
    }
  }
  
  ### still under development ###
  
  # Applying U-test on buffer stack
  buffer <- stack(buffer1, buffer2, buffer3)

  # apply custom-U test here
  
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
}

# extra buffer for personal project, no need to include in generic function
# this helps with the coniferous/broad-leaved issue

buffer1 <- tsMD_2013_2014; buffer1[tsM2014[] <= 2] <- NA
buffer2 <- tsMD_2014_2015; buffer2[tsM2015[] <= 2] <- NA
buffer3 <- tsMD_2015_2016; buffer3[tsM2016[] <= 2] <- NA