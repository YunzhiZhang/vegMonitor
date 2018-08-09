imgVector <- list.files(paste(getwd(), "/input/climg", sep=""), pattern = ".tif$", full.names = TRUE)
baseShapefile <- "./input/shp/Sum_UTM43N_4U_Classes.shp"
predShapefile = "./input/shp/DL_Lower_UTM43N.shp"
ntry = 1000

source("vegClassification.R", encoding = "UTF-8")

vegClassify(imgVector, baseShapefile, predShapefile = predShapefile, ntry = ntry)