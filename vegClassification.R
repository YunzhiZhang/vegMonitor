### load libraries ###

if(!require(raster)) install.packages("raster")
library(raster)

if(!require(rgdal)) install.packages("rgdal")
library(rgdal)

if(!require(caret)) install.packages("caret")
library(caret)

if(!require(snow)) install.packages("snow")
library(snow)

if(!require(randomForest)) install.packages("randomForest")
library(randomForest)

if(!require(e1071)) install.packages("e1071")
library(e1071)

## function ###

vegClassify <- function(imgVector, baseShapefile, bands = NULL, responseCol = "OBJECTID", predShapefile = NULL, undersample = TRUE, predImg = TRUE, ntry = 500, genLogs = TRUE, writePath = NULL, format = NULL) {
  
  ### check dependencies ###
  
  if(!is.vector(imgVector)){
    stop("please specify imgVector as a vector")
  } else if (is.vector(imgVector)){
    s <- lapply(imgVector, stack)
  }
  
  if (!is.vector(bands)){
    stop("bands must be specified as a vector")
  } else if (is.vector(bands)){
    allBands <- FALSE
  }
  
  if(is.null(predShapefile)){
    pred <- FALSE
    warning("no prediction shapefile path with .shp provided, carrying on...")
  } else {
    dLower <- shapefile(predShapefile)
    pred <- TRUE
  }
  
  if(!is.logical(undersample)){
    stop("undersample must be logical")
  }
  
  if(!is.logical(predImg)){
    stop("predImg must be logical")
  }
  
  if(!is.numeric(ntry) | length(ntry) > 1){
    stop("ntry must be numeric and have a length of 1")
  }
  
  if(!is.logical(genLogs)){
    stop("genLogs must be logical")
  }
  
  if(genLogs==TRUE){
    tmpVarImp <- list()
    tmpResults <- list()
    tmpPred <- list()
  }
  
  if(is.null(writePath)){
    writePath = paste(getwd(), "/output/vegClassification", sep = "")
    warning(paste("no writePath supplied, defaulting to ", writePath, sep=""))
  } else if (substr(writePath, nchar(writePath), nchar(writePath)) == "/") {
    writePath <- substr(writePath, 1, nchar(writePath)-1)
  }
  
  if(!file.exists(writePath)){
    stop(paste("the directory ", writePath, " does not exist, check working directory...", sep=""))
  }
  
  if(is.null(format)){
    format <- "GTiff"
    warning(paste("no format provided, defaulting to ", format, sep=""))
  }
  
  source("./aux/undersample.R", encoding = "UTF-8")
  
  ### main loop ###
  
  start <- proc.time()
  pb.overall <- txtProgressBar(min = 0, max = length(s), initial = 0, char = "=",
                               width = options()$width, style = 3, file = "")
  
  shape_pointData <- shapefile(baseShapefile)
  
  for(i in 1:length(s)){
    
    training_image <- s[[i]]
    
    names(training_image) <- c(paste0("B", 1:length(names(training_image)), coll = ""))
    
    if(allBands == TRUE){
      bands <- c(1:length(names(training_image)))
    }
    
    training_image <- training_image[[bands]]
    
    image_dfall = data.frame(matrix(vector(), nrow = 0, ncol = length(names(training_image)) + 1))
    for (j in 1:length(unique(shape_pointData[[responseCol]]))){
      category <- unique(shape_pointData[[responseCol]])[j]
      categorymap <- shape_pointData[shape_pointData[[responseCol]] == category,]
      dataSet <- extract(training_image, categorymap)
      dataSet <- dataSet[!unlist(lapply(dataSet, is.null))]
      
      if(length(bands)==1){
        dataSet[[1]] <- as.matrix(dataSet[[1]])
        colnames(dataSet[[1]]) <- names(training_image)
      }
      
      if(is(shape_pointData, "SpatialPointsDataFrame")){
        dataSet <- cbind(dataSet, class = as.numeric(category))
        image_dfall <- rbind(image_dfall, dataSet)
      }
      
      if(is(shape_pointData, "SpatialPolygonsDataFrame")){
        dataSet <- lapply(dataSet, function(x){cbind(x, class = as.numeric(rep(category, nrow(x))))})
        df <- do.call("rbind", dataSet)
        image_dfall <- rbind(image_dfall, df)
      }
      
      image_dfall <- image_dfall[complete.cases(image_dfall),]
    }
    
    image_inBuild <- createDataPartition(y = image_dfall$class, p = 0.7, list = FALSE)
    image_train <- image_dfall[image_inBuild,]
    image_valid <- image_dfall[-image_inBuild,]
    
    if(undersample == TRUE){
      image_train <- undersample_ds(image_train, "class", min(table(image_train$class)))
      image_valid <- undersample_ds(image_valid, "class", min(table(image_valid$class)))
    }
    
    image_rf <- train(image_train[,c(1:(ncol(image_train)-1)), drop=FALSE], as.factor(image_train[,ncol(image_train)]), method = "rf", ntree = ntry, importance = genLogs)
    saveRDS(image_rf, paste(writePath, "/", strsplit(names(s[[i]])[1], "[.]")[[1]][1], ".rds", sep = ""))
    
    if(genLogs==TRUE){
      tmpVarImp[[i]] <- varImp(image_rf)$importance
      rownames(tmpVarImp[[i]]) <- paste(strsplit(names(s[[i]])[1], "[.]")[[1]][1], ".", rownames(varImp(image_rf)$importance), sep="") 
      
      tmpResults[[i]] <- cbind(undersample, ntry, image_rf$results[which(image_rf$results[,3] == max(image_rf$results[,3])),], nrow(image_train))
      names(tmpResults[[i]])[1:2] <- c("undersample", "ntry")
      names(tmpResults[[i]])[length(names(tmpResults[[i]]))] <- "trainingPixels"
      rownames(tmpResults[[i]]) <- strsplit(names(s[[i]])[1], "[.]")[[1]][1]
      
      imagepred_valid <- predict(image_rf, image_valid)
      Accuracy <- confusionMatrix(imagepred_valid,as.factor(image_valid$class))$overall[1]
      Kappa <- confusionMatrix(imagepred_valid, as.factor(image_valid$class))$overall[2]
      byClass <- do.call("cbind", lapply(confusionMatrix(imagepred_valid, as.factor(image_valid$class))$byClass[,1], function(x) return(x)))
      
      tmpPred[[i]] <- cbind(undersample, Accuracy, Kappa, byClass, nrow(image_valid))
      colnames(tmpPred[[i]])[1] <- "undersample"
      colnames(tmpPred[[i]])[length(colnames(tmpPred[[i]]))] <- "testPixels"
      rownames(tmpPred[[i]]) <- strsplit(names(s[[i]])[1], "[.]")[[1]][1]
    }
    
    if(predImg == TRUE){
      if(pred == TRUE){
      prediction_image <- mask(training_image, dLower)
      beginCluster()
      pred_rf <- clusterR(prediction_image, raster::predict, args = list(model = image_rf))
      endCluster()
    } else if (pred == FALSE){
      beginCluster()
      pred_rf <- clusterR(training_image, raster::predict, args = list(model = image_rf))
      endCluster()
    }
      writeRaster(pred_rf, file.path(writePath, strsplit(names(s[[i]])[1], "[.]")[[1]][1]), format = format, overwrite = TRUE)
    }
    
    Sys.sleep(1/100)
    setTxtProgressBar(pb.overall, i, title = NULL, label = NULL)
  }
  
  if(genLogs==TRUE){
    tmpVarImp <- do.call("rbind", lapply(tmpVarImp, function(x) return(x)))
    tmpResults <- do.call("rbind", lapply(tmpResults, function(x) return(x)))
    tmpPred <- do.call("rbind", lapply(tmpPred, function(x) return(x)))
    
    write.csv(tmpVarImp, file.path(writePath,"log_VarImp.csv"), row.names = TRUE)
    write.csv(tmpResults, file.path(writePath,"log_Results.csv"), row.names = TRUE)
    write.csv(tmpPred, file.path(writePath,"log_Pred.csv"), row.names = TRUE)
  }
  
  end <- proc.time()
  close(pb.overall)
  print(end-start)
  return(0)
}
