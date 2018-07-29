pairing <- function(grouping){
  aggGrouping <- list()
  for(i in 1:(length(grouping)-1)){
    aggGrouping[[i]] <- c(grouping[[i]], grouping[[i+1]]) 
  }
  return(aggGrouping)
}