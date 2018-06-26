Clean GEE Output Data
================

Reviewing GEE Output Data
=========================

Now we will navigate to the data exported by our GEE Script. We now have 31 Landsat 8 SR Images. These images have been clipped to a certain general boundary. We would like to reduce this boundary to all altitudes below 3,000 m a.m.s.l. Furthermore, we would also like to replace all 0 values in the images produced with `NA` values.

``` r
if (!require("raster")) install.packages("raster")
library("raster")

if (!require("rgdal")) install.packages("rgdal")
library("rgdal")

if (!require("Cairo")) install.packages("Cairo")
library("Cairo")
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

After doing this, out images are saved in the `/Cleaned_Images` directory. Now we can visualize these images to manually check for any possible issues.

``` r
rlist<-list.files(paste(getwd(),"/Cleaned_Images", sep =""), pattern="tif$", full.names = TRUE) 
s <- lapply(rlist, brick)

e <- extent(605000, 655000, 3537500, 3580000)
mat <- rbind(c(1,0,2,0,3,0,4,0,5,0),c(0,0,0,0,0,0,0,0,0,0), 
                    c(6,0,7,0,8,0,9,0,10,0),c(0,0,0,0,0,0,0,0,0,0),
                    c(11,0,12,0,13,0,14,0,15,0),c(0,0,0,0,0,0,0,0,0,0),
                    c(16,0,17,0,18,0,19,0,20,0),c(0,0,0,0,0,0,0,0,0,0),
                    c(21,0,22,0,23,0,24,0,25,0),c(0,0,0,0,0,0,0,0,0,0),
                    c(26,0,27,0,28,0,29,0,30,0),c(0,0,0,0,0,0,0,0,0,0),
                    c(31,0,0,0,0,0,0,0,0,0),c(0,0,0,0,0,0,0,0,0,0))

png(file="Cairo_PNG_72_dpi2.png",
    type="cairo",
    units="px",
    width=2000,
    height=3000,
    pointsize=20,
    res=150)

layout(mat)
par(oma = c(0,8,2,0))

for(i in 1:1){
plotRGB(s[[i]], r = 4, g = 3, b = 2, stretch = "lin", axes=T, ext = e)
axis(side=1,cex.axis=1, lwd = 1.5)
axis(side=2,cex.axis=1, lwd = 1.5)
box(lwd = 1.5)
title(main="xyz")
}

dev.off()
```

\[Still under development...\]
