imgVector <- list.files(paste(getwd(), "/input/climg", sep=""), pattern = ".tif$", full.names = TRUE)[c(1,2)]
baseShapefile <- "./input/shp/Sum_UTM43N_4U_Classes.shp"
bands = NULL
responseCol = NULL
predShapefile = "./input/shp/DL_Lower_UTM43N.shp"
undersample = NULL
predImg = NULL
ntry = NULL
genLogs = NULL
writePath = NULL
format = NULL

source("vegClassification.R", encoding = "UTF-8")

vegClassify(imgVector, baseShapefile, bands, responseCol, predShapefile, undersample, predImg, ntry, genLogs, writePath, format)