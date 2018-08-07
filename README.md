# vegMonitor 

## Investigating losses in vegetation cover using remote sensing data and the Random Forests algorithm

This is a project which summarizes remote sensing data processing techniques in order to extract key vegetation data and indications about vegetation changes.

## Case study and objectives

The study area of this project is [Dharamshala Tehsil](https://en.wikipedia.org/wiki/Dharamshala), located in the Indian state of Himachal Pradesh. This region is famous for its natural and cultural beauty. Intense tourism and development in recent years has allegedly led to a large loss of local forest cover. In order to conduct an independent investigation of these changes, we suggest here a set of methodologies based on public remote-sensing data.

The end of goal of this project is to generate vegetation cover classification images of the study area from 2013-2017. With this images, we aim to develop a change detection technique that would indicate to us regions undergoing significant vegetation loss. These regions would then be flagged for further investigation.

## Guide to methodologies for Ubuntu 16.04

### 1. Pre-processing remote sensing data using Google Earth Engine

Firstly, we need to download relevant remote-sensing data for our purpose. The traditional means of going about this process would be to navigate to various data providers such as the USGS's [Earth-Explorer](https://earthexplorer.usgs.gov/) interface. Although this is a very interactive and comfortable interface, it does present us with some key limitations. For one, we are limited to how much we can query and filter large data before downloading it. This would mean we would need to download many GB's of data, only to use a few MB at the end. Next, we are also limited with how much data we can query at once. For example, the USGS Earth-Explorer interface only hosts certain datasets and perhaps not all the relevant ones. In order to access other datasets, we would need to navigate to another interface altogether. 

In order to overcome these issues, we propose using the Google Earth Engine (GEE). The Google Earth Engine is essentially a Javascript-based API hosted on Google's infrastructure. This API allows us to query a large volume of Earth observation datasets and to pre-process them before downloading. This provides an efficient means of data-processing for our needs. Here, we choose to download the Landsat 8 Surface Reflectance data. 

For a detailed look on how to acquire and pre-process remote sensing data, please refer to the following GitHub repository: https://github.com/AtreyaSh/geeBulkFilter

### 2. Supervised vegetation classification using field data and the Random Forests algorithm

The random forests algorithm is an effective supervised classification technique developed in Breiman (2001): https://en.wikipedia.org/wiki/Random_forest

Here, we use the random forests algorithm with field data to classify vegetation using Landsat 8 Surface Reflectance data.

`vegClassification.R` is a generic R-script containing a useful `vegClassify` function: https://github.com/AtreyaSh/vegMonitor/blob/master/vegClassification.R

```r
vegClassify(imgVector, baseShapefile, bands = NULL, responseCol = NULL, predShapefile = NULL,
            undersample = NULL, predImg = NULL, ntry = NULL, genLogs = NULL, writePath = NULL, format = NULL)
```

**Arguments**

Mandatory:

1. `imgVector` is a vector containing the absolute string paths with endings (eg. "/path/to/folder/xyz.tif") of multi-band images that are to be processed.

2. `baseShapefile` is a string path with ".shp" ending that contains polygons or point data for training the random forest model. In this case, the shapefile contains data collected during field work.

Optional:

3. `bands` is a numerical vector containing the necessary bands used for training. Defaults to all bands in the image.

4. `responseCol` is a string that points the algorithm to the feature in `baseShapefile` that is needed for training. Defaults to "OBJECTID".

5. `predShapefile` is a string path with ".shp" ending that contains polygon(s) which will mask the training image. Resulting masked image can be used for prediction. Will be ignored if no input provided.

6. `undersample` is a boolean which conducts undersampling on the training and testing data to create balanced training and testing datasets. Defaults to "TRUE".

7. `predImg` is a boolean which uses trained random forest model to predict either the entire training image or a subset of it depending on `predShapefile`. Defaults to "TRUE".

8. `ntry` is a numerical value and represents the number of trees created in the random forests model. Defaults to "500".

9. `genLogs` is a boolean which results in logs of training, testing and variable importance to be created and written into `writePath`. Defaults to "TRUE".

10. `writePath` is a path directory which points the function on which directory to write the results of the function. Defaults to "./output/vegClassification".

11. `format` is a string which points how the resulting predicted raster should be written. Defaults to "GTiff".

    Other possibilities for `format` are listed here: https://www.rdocumentation.org/packages/raster/versions/2.6-7/topics/writeRaster

**Sample output**

Vegetation classification images produced using `vegClassify` are visualized below. This visualization was conducted using the `levelplot` function in the CRAN `rasterVis` package.

Note: 1 represents confierous forests, 2 represents broad-leaved forests, 3 represents cropland, shrubs and grasslands, and 4 represents non-vegetated areas

<img src="/rimg/results_test.png" width="650">

### 3. Vegetation loss detection using a custom-rasterized Mann-Whitney technique

In order to conduct vegetation loss detection, we use a rasterized Mann-Whitney change detection technique. The Mann-Whitney U test is a non-parametric statistical test for independent data samples and is particularly used for ordinal data.

`vegLossDetection.R` is a generic R-script containing a useful `vegLossDetection` function: https://github.com/AtreyaSh/vegMonitor/blob/master/vegLossDetection.R

```r
vegLossDetection(imgVector, grouping, coarse = NULL, test = NULL, pval = NULL,
                 clumps = NULL, directions = NULL, genLogs = NULL, writePath = NULL, format = NULL)
```

**Arguments**

Mandatory:

1. `imgVector` is a vector containing the absolute string paths with endings (eg. "/path/to/folder/xyz.tif") of classification images that are to be processed.

2. `grouping` is a list containing vector indices that separates `imgVector` into groups.

Optional:

3. `coarse` is a boolean which creates a smaller search space for significant change pixels. Defaults to "TRUE".

4. `test` refers to the type of statistical test for investigating changes. Possibilites are "generic.change", "increase", "decrease". Defaults to "generic.change".

5. `pval` refers to the p-value required for a signficant change detection. Defaults to 0.05.

6. `clumps` is a boolean which conducts further processing on significant change pixels to identify pixels which are clumped together in groups containing more than 1 pixel.

7. `directions` is a numerical value which refers to the directions which are considered adjacent for `clumps`. Only relevant when `clumps = TRUE`. Possibilities are 4 and 8. Defaults to 8 if `clumps = TRUE`.

8. `genLogs` is a boolean which results in logs of results to be created and written into `writePath`. Defaults to "TRUE".

9. `writePath` is a path directory which points the function on wich directory to write the results of the function. Defaults to "./output/vegClassification".

10. `format` is a string which points how the resulting predicted raster should be written. Defaults to "GTiff".

    Other possibilities for `format` are listed here: https://www.rdocumentation.org/packages/raster/versions/2.6-7/topics/writeRaster

**Sample output**

The visualization below shows red clumped pixels produced through `vegLossDetection` with the condition of `clumps=TRUE`.

The red pixels indicate regions which underwent significant vegetation loss. This visualization was created using the layout function of ArcMap version 10.3.

<img src="/rimg/dest.jpg" width="650">
