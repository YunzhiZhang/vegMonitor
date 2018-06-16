# Set working directory
setwd("<working directory>")

# Load libraries needed, assuming they are installed
library(rgdal)
library(raster)
library(caret)
library(snow)

# Import training images and stack them training RF model
rlist<-list.files(path="<source directory>", pattern="tif$", full.names = TRUE)
s<-lapply(rlist, stack)

# Import shapefile containing vegetation polygons in native resolution
shape_pointData <- shapefile("<file destination>")
responseCol <- "OBJECTID"

# Import polygon for masking prediction image(s)
dLower <- shapefile("<file destination>")

# Start of for-loop for processing RF model on images
for (j in 1:length(s)){

training_image <- s[[j]]

# To make band names shorter and create a smaller prediction image
names(training_image) <- c(paste0("B", 1:7, coll = ""))
prediction_image <- mask(training_image, dLower)

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

# Building the model with data partition, all bands, 1000 trees and variable importance tracking
imagemod_rf_1k <- train(as.factor(class) ~ B1 + B2 + B3 + B4 + B5 + B6 + B7, method = "rf", data = training_bc, ntree = 1000, importance = TRUE)

# Save the trained model
saveRDS(imagemod_rf_1k, names(s[[j]])[1])

# Shows paramters like accuracy and kappa coefficient for internal OOB data
imagemod_rf_1k

# View the variable importance of the RF model
varImp(imagemod_rf_1k)[1]

# Prediction on test dataset based on trained model
imagepred_valid_1k <- predict(imagemod_rf_1k, image_valid)

# Confusion matrix of trained model on test dataset; provides accuracy
confusionMatrix1 <- confusionMatrix(imagepred_valid_1k,image_valid$class)$overall[1]

# Confusion matrix of trained model on test dataset; provides kappa coefficient
confusionMatrix3 <- confusionMatrix(imagepred_valid_1k, image_valid$class)$overall[2]

# Confusion matrix of trained model on test dataset; provides user's accuracy by class
confusionMatrix2 <- confusionMatrix(imagepred_valid_1k, image_valid$class)$byClass[,1]

# Apply the RF model to predict the entire image
beginCluster()
preds_rf2_1k <- clusterR(prediction_image, raster::predict, args = list(model = imagemod_rf_1k))
endCluster()

# Save predicted image
writeRaster(preds_rf2_1k, file.path("<target directory>", names(s[[j]])[1]), format = "GTiff", overwrite = TRUE)
}
