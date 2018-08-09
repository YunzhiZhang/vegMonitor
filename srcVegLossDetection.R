imgVector <- list.files(paste0(getwd(), "/output/vegClassification"), pattern = ".tif$", full.names = TRUE)
grouping = list(c(1:6), c(7:14), c(15:21), c(22:26))
test = "increase"

source("vegLossDetection.R", encoding = "UTF-8")

vegLossDetection(imgVector, grouping, test = test)

# extra buffer for personal project, no need to include in generic function
# this helps with the coniferous/broad-leaved issue
# 
# buffer1 <- tsMD_2013_2014; buffer1[tsM2014[] <= 2] <- NA
# buffer2 <- tsMD_2014_2015; buffer2[tsM2015[] <= 2] <- NA
# buffer3 <- tsMD_2015_2016; buffer3[tsM2016[] <= 2] <- NA