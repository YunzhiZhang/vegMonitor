# Load libraries needed, install if not present

if(!require(raster)) install.packages("raster")
library(raster)

if(!require(rgdal)) install.packages("rgdal")
library(rgdal)

if(!require(caret)) install.packages("caret")
library(caret)

# change all namingg conventions to make them consistent

# Developing vegetation classification function, can possibly rename later for more generic purposes

vegClassify <- function(imgStack, baseShapefile, responseCol, predShapefile, undersample, ntry, varImp, genLogs, writePath) {
  
  if(is.null(imgStack)){
    stop("please indicate a path for imgStack with the corresponding filetype")
  } else {
    s <- stack(imgStack)
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
    warning("no prediction shapefile path with .shp provided, carrying on")
  } else {
    dLower  <- shapefile(predShapefile)
    pred <- TRUE 
  }
  
  if(is.null(undersample)){
    undersample <- TRUE
    warning(paste("no undersample supplied, defaulting to ", undersample, sep = ""))
  }
  
  if(is.null(ntry)){
    ntry <- 1000
    warning(paste("no ntree supplied, defaulting to ", ntry, sep = ""))
  }
  
  if(is.null(varImp)){
    varImp <- TRUE
    warning(paste("no varImp supplied, defaulting to ", varImp, sep = ""))
  }
  
  if(is.null(genLogs)){
    genLogs <- TRUE
    warning(paste("no genLogs supplied, defaulting to ", genLogs, sep = ""))
  }
  
  if(is.null(writePath)){
    writePath = paste(getwd(), "/vegClassification/", sep = "")
    warning(paste("no write path supplied, defaulting to ", writePath, sep=""))
    
    if(!file.exists("./vegClassification")){
      dir.create("./vegClassification")
    }
  }
  
  training_image <- imgStack
  
  # To make band names shorter and create a smaller prediction image
  names(training_image) <- c(paste0("B", 1:length(names(training_image)), coll = ""))
  
  if(pred==TRUE){
    prediction_image <- mask(training_image, dLower)
  }
  
  # Extract values of raster pixels based on vegetation class polygons
  image_dfall = data.frame(matrix(vector(), nrow = 0, ncol = length(names(training_image)) + 1))
  for (i in 1:length(unique(shape_pointData[[responseCol]]))){
    category <- unique(shape_pointData[[responseCol]])[i]
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
  
  # To create data partition for training and test dataset
  image_inBuild <- createDataPartition(y = image_dfall$class, p = 0.7, list = FALSE)
  image_train <- image_dfall[image_inBuild,] #training data
  image_train <- image_train[complete.cases(image_train), ]
  image_valid <- image_dfall[-image_inBuild,] #test data, a.k.a validation data
  image_valid <- image_valid[complete.cases(image_valid), ]
  
  if(undersample == TRUE){
    # To undersample training dataset for balanced training data
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
  
  # Building the model with data partition
  
  ###
  imagemod_rf_1k <- train(as.factor(class) ~ B1 + B2 + B3 + B4 + B5 + B6 + B7, method = "rf", data = training_bc, ntree = ntry, importance = varImp)
  ###
  
  # Save the trained model, naming convention to change somehow
  ###
  saveRDS(imagemod_rf_1k, names(training_image)[1])
  ###
  
  # Shows paramters like accuracy and kappa coefficient for internal OOB data
  imagemod_rf_1k
  
  if(varImp==TRUE){
    # View the variable importance of the RF model
    varImp(imagemod_rf_1k)[1]  
  }

  # Prediction on test dataset based on trained model
  imagepred_valid_1k <- predict(imagemod_rf_1k, image_valid)
  
  # Confusion matrix of trained model on test dataset; provides accuracy
  confusionMatrix1 <- confusionMatrix(imagepred_valid_1k,image_valid$class)$overall[1]
  
  # Confusion matrix of trained model on test dataset; provides kappa coefficient
  confusionMatrix3 <- confusionMatrix(imagepred_valid_1k, image_valid$class)$overall[2]
  
  # Confusion matrix of trained model on test dataset; provides user's accuracy by class
  confusionMatrix2 <- confusionMatrix(imagepred_valid_1k, image_valid$class)$byClass[,1]
  
  # Apply the RF model to predict the entire image
  if(pred == TRUE){
    beginCluster()
    preds_rf2_1k <- clusterR(prediction_image, raster::predict, args = list(model = imagemod_rf_1k))
    endCluster()
  } else {
    beginCluster()
    preds_rf2_1k <- clusterR(training_image, raster::predict, args = list(model = imagemod_rf_1k))
    endCluster()
  }

  # Save predicted image
  ###
  writeRaster(preds_rf2_1k, file.path(writePath, names(s[[j]])[1]), format = "GTiff", overwrite = TRUE)
  ###
}