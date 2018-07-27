imgList <- list.files(paste(getwd(), "/input/climg", sep=""), pattern = ".tif$", full.names = TRUE)
baseShapefile <- "./input/shp/Sum_UTM43N_4U_Classes.shp"
bands = c(1:7)
responseCol = NULL
predShapefile = "./input/shp/DL_Lower_UTM43N.shp"
undersample = NULL
ntry = 1000
genLogs = NULL
writePath = NULL
format = NULL

source("vegClassification.R", encoding = "UTF-8")

vegClassify(imgList, baseShapefile, responseCol, predShapefile, bands, undersample, ntry, genLogs, writePath, format)

### Issues ###

## Priority

# work on making nicer genlogs
# undersample credit to Ali Santacruz

# test function see how it works
# add readme or package type functions
# add documentation about format types
# print band number in varImp log for clarity

## Extra

# make R-base API for python API, might be counterintuitive but might work