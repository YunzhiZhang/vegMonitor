customUTest <- function(x, y, n1, n2, test){
  extract <- extract(y, c(1:length(y)))
  cellno <- which(!is.na(extract) == TRUE)
  
  pb.overall <- txtProgressBar(min = 0, max = length(cellno), initial = 0, char = "=",
                               width = options()$width, style = 3, file = "")
  
  for(k in 1:length(cellno)){
    e1 <- as.vector(extract(x[[1:n1]], c(cellno[k])))
    e1 <- e1[!is.na(e1)]
    e2 <- as.vector(extract(x[[(n1+1):n2]], c(cellno[k])))
    e2 <- e2[!is.na(e2)]
    if(length(e1) > 0 & length(e2) > 0){
      p <- wilcox.test(e1, e2, alternative = test)$p.value
      y[cellno[k]] <- p
    } else y[cellno[k]] <- NA 
    
    Sys.sleep(1/100)
    setTxtProgressBar(pb.overall, k, title = NULL, label = NULL)
  }
  close(pb.overall)
  return(y)
}