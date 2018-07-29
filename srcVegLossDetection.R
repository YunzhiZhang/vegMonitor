imgVector <- list.files("/home/shankar/Desktop/Git/Archive/backup/gitVegMonitor/vegClassification", pattern = ".tif$", full.names = TRUE)[-c(7,8,20,29,30)]
grouping = list(c(1:6), c(7:14), c(15:21), c(22:26))
test = NULL
pval = NULL
directions = NULL
genLogs = NULL
writePath = NULL
format = NULL

source("vegLossDetection.R", encoding = "UTF-8")

vegLossDetection(imgVector, grouping, test, pval, directions, genLogs, writePath, format)