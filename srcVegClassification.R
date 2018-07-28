imgVector <- list.files(paste(getwd(), "/input/climg", sep=""), pattern = ".tif$", full.names = TRUE)[c(1,2)]
baseShapefile <- "./input/shp/Sum_UTM43N_4U_Classes.shp"
bands = c(1:7)
responseCol = NULL
predShapefile = "./input/shp/DL_Lower_UTM43N.shp"
undersample = NULL
predImg = NULL
ntry = 500
genLogs = NULL
writePath = NULL
format = NULL

source("vegClassification.R", encoding = "UTF-8")

vegClassify(imgVector, baseShapefile, responseCol, predShapefile, bands, undersample, predImg, ntry, genLogs, writePath, format)

### Issues ###

## Priority

# work on making nicer genlogs
# add readme or package type functions
# add documentation about format types

## Extra

# make R-base API for python API, might be counterintuitive but might work