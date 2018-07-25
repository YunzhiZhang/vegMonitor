Reviewing GEE Output Data
=========================

Now we will navigate to the data exported by our GEE Script. We now have 31 Landsat 8 SR Images. These images have been clipped to a certain general boundary. We would like to reduce this boundary to all altitudes below 3,000 m a.m.s.l. Furthermore, we would also like to replace all 0 values in the images produced with `NA` values.

First, we need to load/install some necessary packages.

``` r
if (!require("raster")) install.packages("raster")
library("raster")

if (!require("rgdal")) install.packages("rgdal")
library("rgdal")
```

Now we have loaded necessary packages. Let's move on to the actual process of cleaning the images.

``` r
rlist<-list.files(paste(getwd(),"/GEE_Output", sep =""), pattern="tif$", full.names = TRUE) 
s <- lapply(rlist, stack)
polygonLower <- readOGR(paste(getwd(), "/GEE_Input", sep=''), "DL_PL_KN_Lower_UTM43N")

for(i in 1:length(s)){
  image <- s[[i]]
  image[image[] == 0] <- NA
  imageMasked <- mask(image, polygonLower)
  writeRaster(imageMasked, file.path(paste(getwd(), "/Cleaned_Images", sep = ''), 
                                     names(s[[i]])[1]), format = "GTiff")
}
```

Manual Check and Refinements
============================

After doing this, out images are saved in the `/Cleaned_Images` directory. Now we can visualize these images to manually check for any possible issues. The following 5 images were ascertained to be defective and not suitable for further analysis. This is due to the presence of objects such as haze, and possibly inaccurate atmospheric correction. Their corresponding file names were: `LC81470382014047_6.tif`, `LC81470382014111_7.tif`, `LC81470382015258_19.tif`, `LC81470382017023_28.tif`, `LC81470382017055_29.tif`.

![](/img/Defective_Images.png)

Summary
=======

These files were excluded from further analysis and the remaining suitable images were defined by the following list of raster stacks. With the new defintion of `s`, we can now move forward with the next post-analyses.

``` r
rlist<-list.files(paste(getwd(),"/Cleaned_Images", sep =""), pattern="tif$", full.names = TRUE)
s <- lapply(rlist, stack)
s <- s[-c(7,8,20,29,30)]
```

We will be using this definition of `s` for further analyses; since it encompasses the final high quality images. The table below shows a brief summary of the cleaned images and their characteristics.
