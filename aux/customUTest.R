customUTest <- function(img, diff, n1, n2){
  extract <- extract(buffer[[i]], c(1:length(buffer[[i]])))
  cellno <- which(!is.na(extract) == TRUE)
  
  for(k in 1:length(cellno)){
    e1 <- as.vector(extract(x[[1:n1]], c(cellno[k])))
    e1 <- e1[!is.na(e1)]
    e2 <- as.vector(extract(x[[(n1+1):n2]], c(cellno[k])))
    e2 <- e2[!is.na(e2)]
    p <- wilcox.test(e1, e2, alternative = "less")$p.value
    buffer[[i]][cellno[k]] <- p
  }
  return(buffer[[i]])
}