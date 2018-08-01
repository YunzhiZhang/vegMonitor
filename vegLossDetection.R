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

vegLossDetection <- function(imgVector = NULL, grouping = NULL, coarse = NULL, test = NULL, pval = NULL, clumps = NULL, directions = NULL, genLogs = NULL, writePath = NULL, format = NULL){
  
  ### check dependencies ###
  
  if(is.null(imgVector)){
    stop("please specify a vector containing absolute string paths with endings for images")
  }
  
  if(is.null(grouping)){
    stop("please specify a list of vectors containing the indices of images to be grouped")
  } else if(!is.list(grouping)){
    stop("please input grouping as a list of vectors")
  }
  
  if(is.null(coarse)){
    coarse <- TRUE
    warning(paste0("no input for coarse provided, defaulting to ", coarse))
  }
  
  if(is.null(test)){
    test <- "generic.change"
    warning(paste0("no input for test detected, defaulting to ", test))
  }
  
  
  if(is.null(pval)){
    pval <- 0.05
    warning(paste0("no input for pval detected, defaulting to ", pval))
  }
  
  if(is.null(clumps)){
    clumps <- TRUE
    warning(paste0("no input for clumps detected, defaulting to ", clumps))
  }
  
  if(is.null(directions) & clumps == TRUE){
    directions <- 8
    warning(paste0("no input for directions detected, defaulting to ", directions))
  } else if(!is.null(directions) & clumps == FALSE){
    rm(directions)
    warning(paste0("no directions input since clumps is ", clumps))
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
  source("./aux/customUTest.R", encoding= "UTF-8")
  
  ### body ###
  
  p <- list()
  g <- lapply(grouping, function(x) return(stack(imgVector[x])))
  f <- lapply(pairing(grouping), function(x) return(stack(imgVector[x])))
  gNA <- lapply(g, function(x) sum(is.na(x)))
  
  # clean individual images for cleaner median calculation, remove large NA stacks
  
  for(i in 1:length(g)){
    g[[i]][gNA[[i]][] > length(names(g[[i]]))/2] <- NA
  }
  
  for(i in 1:length(f)){
    f[[i]][gNA[[i]][] > length(names(g[[i]]))/2 | gNA[[i+1]][] > length(names(g[[i+1]]))/2] <- NA
  }
  
  # generate medians of individual groups and stack consecutive medians, subtract medians to get buffers
  
  beginCluster()
  gM <- lapply(g, function(x) return(calc(x, fun=median, na.rm=T)))
  fM <- lapply(pairing(gM), function(x) return(stack(x)))
  diff <- lapply(fM, function(x) return(calc(x, fun=subtract)))
  endCluster()
  
  # limiting search spaces for diff based on coarse option and test type
  
  if(test=="generic.change"){
    testW="two.sided"
    if(coarse==TRUE){
      for(i in 1:length(diff)){
        diff[[i]][diff[[i]][] < 1 & diff[[i]][] > -1] <- NA
      }
    } else{
      for(i in 1:length(diff)){
        diff[[i]][diff[[i]][] < 0.5 & diff[[i]][] > -0.5] <- NA
      }
    }
  } else if(test=="increase") {
    testW="less"
    if(coarse==TRUE){
      for(i in 1:length(diff)){
        diff[[i]][diff[[i]][] < 1] <- NA
      }
    } else{
      for(i in 1:length(diff)){
        diff[[i]][diff[[i]][] < 0.5] <- NA
      }
    }
  } else if(test=="decrease"){
    testW="greater"
    if(coarse==TRUE){
      for(i in 1:length(diff)){
        diff[[i]][diff[[i]][] > -1] <- NA
      }
    } else{
      for(i in 1:length(diff)){
        diff[[i]][diff[[i]][] > -0.5] <- NA
      }
    }
  }
  
  # custom U-test and filter results
  
  for(i in 1:length(f)){
    p[[i]] <- customUTest(f[[i]], diff[[i]], length(grouping[[i]]), (length(grouping[[i]]) + length(grouping[[i+1]])), testW)
    p[[i]][p[[i]][] > pval] <- NA
  }
  
  # clumping of pixels
  
  if(clumps == TRUE){
    c <- p
    clumpsR <- lapply(c, function(x) return(clump(x, directions=directions, gaps = TRUE)))
    clumpFreq <- lapply(clumpsR, function(x) return(as.data.frame(freq(x))))
    excludeID <- lapply(clumpFreq, function(x) return(x$value[which(x$count==1)]))
    
    for(i in 1:length(c)){
      c[[i]][clumps[[i]] %in% excludeID[[i]]] <- NA
    }
  }
  
  # generate logs of results
  
  if(genLogs==TRUE){
    logs <- data.frame(matrix(ncol=8))
    names(logs) <- c("coarse", "test", "pval", "clumps", "directions", "diffPixels", "pPixels", "cPixels")
    for(i in 1:length(diff)){
      logs[i,1] <- coarse
      logs[i,2] <- test
      logs[i,3] <- pval
      logs[i,4] <- clumps
      logs[i,6] <- length(which(!is.na(diff[[i]][])))
      logs[i,7] <- length(which(!is.na(p[[i]][])))
      if(clumps==TRUE){
        logs[i,5] <- directions
        logs[i,8] <- length(which(!is.na(c[[i]][])))
      } else {
        logs[i,5] <- NA
        logs[i,8] <- NA
      }
      row.names(logs)[i] <- paste0(i, "_", i+1)
    }
    write.csv(logs, file.path(writePath, "logs.csv"), row.names = TRUE)
  }
  
  # write results
  
  for(i in 1:length(p)){
    writeRaster(p[[i]], file.path(writePath, paste0("manW_", i, "_", i+1)), format = format, overwrite = TRUE)
    if(clumps == TRUE){
      writeRaster(c[[i]], file.path(writePath, paste0("manW_clump_", i, "_", i+1)), format = format, overwrite = TRUE)
    }
  }
  
  return(0)
}