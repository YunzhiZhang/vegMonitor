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

vegClassify <- function(imgList, baseShapefile, responseCol, predShapefile, bands, undersample, ntry, genLogs, writePath, format) {
  
  ### check dependencies ###
  
  if(is.null(imgList)){
    stop("please indicate a list of images with absolute path names and endings")
  } else {
    s <- lapply(imgList, stack)
  }
  
  if(is.null(baseShapefile)){
    stop("please indicate the path of the base shapefile with .shp ending")
  } else shape_pointData <- shapefile(baseShapefile)
  
  if(is.null(responseCol)){
    responseCol = "OBJECTID"
    warning(paste("no responseCol supplied, defaulting to ", responseCol, sep = ""))
  }
  
  if(is.null(predShapefile)){
    pred <- FALSE
    warning("no prediction shapefile path with .shp provided, carrying on...")
  } else {
    dLower <- shapefile(predShapefile)
    pred <- TRUE 
  }
  
  if(is.null(bands)){
    stop("please specify a vector containing the bands that should be used for training")
  }
  
  if(is.null(undersample)){
    undersample <- TRUE
    warning(paste("no undersample supplied, defaulting to ", undersample, sep = ""))
  }
  
  if(is.null(ntry)){
    ntry <- 500
    warning(paste("no ntree supplied, defaulting to ", ntry, sep = ""))
  }
  
  if(is.null(genLogs)){
    genLogs <- TRUE
    warning(paste("no genLogs supplied, defaulting to ", genLogs, sep = ""))
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
    if (!file.exists(writePath)) {
      stop(paste("the directory ", writePath, " does not exist"))
    }
  } else if (!file.exists(writePath)) {
    stop(paste("the directory ", writePath, " does not exist"))
  }
  
  if(is.null(format)){
    format <- "GTiff"
    warning(paste("no format provided, defaulting to ", format, sep=""))
  }
  
  ### main loop ###
  
  start <- proc.time()
  pb.overall <- txtProgressBar(min = 0, max = length(s), initial = 0, char = "=",
                               width = options()$width, style = 3, file = "")
  
  for(i in 1:length(s)){
    
    training_image <- s[[i]]
    
    names(training_image) <- c(paste0("B", 1:length(names(training_image)), coll = ""))
    
    if(pred==TRUE){
      prediction_image <- mask(training_image, dLower)
    }
    
    image_dfall = data.frame(matrix(vector(), nrow = 0, ncol = length(names(training_image)) + 1))
    for (j in 1:length(unique(shape_pointData[[responseCol]]))){
      category <- unique(shape_pointData[[responseCol]])[j]
      categorymap <- shape_pointData[shape_pointData[[responseCol]] == category,]
      dataSet <- extract(training_image, categorymap)
      dataSet <- dataSet[!unlist(lapply(dataSet, is.null))]
      
      if(is(shape_pointData, "SpatialPointsDataFrame")){
        dataSet <- cbind(dataSet, class = as.numeric(category))
        image_dfall <- rbind(image_dfall, dataSet)
      }
      
      if(is(shape_pointData, "SpatialPolygonsDataFrame")){
        dataSet <- lapply(dataSet, function(x){cbind(x, class = as.numeric(rep(category, nrow(x))))})
        df <- do.call("rbind", dataSet)
        image_dfall <- rbind(image_dfall, df)
      }
    }
    
    image_inBuild <- createDataPartition(y = image_dfall$class, p = 0.7, list = FALSE)
    image_train <- image_dfall[image_inBuild,]
    image_train <- image_train[complete.cases(image_train), ]
    image_valid <- image_dfall[-image_inBuild,]
    image_valid <- image_valid[complete.cases(image_valid), ]
    
    if(undersample == TRUE){
      undersample_ds <- function(x, classCol, nsamples_class){
        for (k in 1:length(unique(x[, classCol]))){
          class.k <- unique(x[, classCol])[k]
          if((sum(x[, classCol] == class.k) - nsamples_class) != 0){
            x <- x[-sample(which(x[, classCol] == class.k),
                           sum(x[, classCol] == class.k) - nsamples_class), ]
          }
        }
        return(x)
      }
      
      training_bc <- undersample_ds(image_train, "class", min(table(image_train$class)))
    } else training_bc <- image_train
    
    image_rf <- train(training_bc[,bands], as.factor(training_bc[,ncol(training_bc)]), method = "rf", ntree = ntry, importance = genLogs)
    
    if(genLogs==TRUE){
      
      tmpVarImp[[i]] <- rbind(as.character(i), varImp(image_rf)$importance)
      tmpResults[[i]] <- cbind(image_rf$results[which(image_rf$results[,3] == max(image_rf$results[,3])),],nrow(training_bc))
      names(tmpResults[[i]])[length(names(tmpResults[[i]]))] <- "trainingPixels"
      
      imagepred_valid <- predict(image_rf, image_valid)
      Accuracy <- confusionMatrix(imagepred_valid,as.factor(image_valid$class))$overall[1]
      Kappa <- confusionMatrix(imagepred_valid, as.factor(image_valid$class))$overall[2]
      byClass <- do.call("cbind", lapply(confusionMatrix(imagepred_valid, as.factor(image_valid$class))$byClass[,1], function(x) return(x)))
      
      tmpPred[[i]] <- cbind(Accuracy, Kappa, byClass, nrow(image_valid))
      colnames(tmpPred[[i]])[length(colnames(tmpPred[[i]]))] <- "testPixels"
      row.names(tmpPred[[i]]) <- NULL
    }
    
    if(pred == TRUE){
      beginCluster()
      pred_rf <- clusterR(prediction_image, raster::predict, args = list(model = image_rf))
      endCluster()
    } else {
      beginCluster()
      pred_rf <- clusterR(training_image, raster::predict, args = list(model = image_rf))
      endCluster()
    }
    
    saveRDS(image_rf, paste(writePath, "/", strsplit(names(s[[i]])[1], "[.]")[[1]][1], ".rds", sep = ""))
    writeRaster(pred_rf, file.path(writePath, strsplit(names(s[[i]])[1], "[.]")[[1]][1]), format = format, overwrite = TRUE)
    
    Sys.sleep(1/100)
    setTxtProgressBar(pb.overall, i, title = NULL, label = NULL)
  }
  
  if(genLogs==TRUE){
    tmpVarImp <- do.call("rbind", lapply(tmpVarImp, function(x) return(x)))
    tmpResults <- do.call("rbind", lapply(tmpResults, function(x) return(x)))
    tmpPred <- do.call("rbind", lapply(tmpPred, function(x) return(x)))
    
    write.csv(tmpVarImp, file.path(writePath,"log_VarImp.csv"), row.names = FALSE)
    write.csv(tmpResults, file.path(writePath,"log_Results.csv"), row.names = FALSE)
    write.csv(tmpPred, file.path(writePath,"log_Pred.csv"), row.names = FALSE)
  }
  
  end <- proc.time()
  close(pb.overall)
  print(end-start)
  return(0)
}
