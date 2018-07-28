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

vegClassify(imgVector, baseShapefile, responseCol, predShapefile, bands, undersample, predImg, ntry, genLogs, writePath, format)

### Issues ###

## Priority

# add readme or package type functions

## Extra

# make R-base API for python API, might be counterintuitive but might work