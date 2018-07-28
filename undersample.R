# credit for this function goes to Ali Santacruz: https://github.com/amsantac

undersample_ds <- function(x, classCol, nsamples_class){
  for (k in 1:length(unique(x[, classCol]))){
    class.k <- unique(x[, classCol])[k]
    if((sum(x[, classCol] == class.k) - nsamples_class) != 0){
      x <- x[-sample(which(x[, classCol] == class.k),
                     sum(x[, classCol] == class.k) - nsamples_class), ]
    }
  }
  return(x)
}