# Investigating vegetation cover changes in Dharamshala Tehsil, Indian Northwestern Himalayas, from 2013-2017

This is a project which summarizes remote sensing data processing techniques in order to extract key vegetation data and indications about vegetation changes.

## Background and Objectives

The study area of this project is [Dharamshala Tehsil](https://en.wikipedia.org/wiki/Dharamshala), located in the Indian state of Himachal Pradesh. This region is famous for its natural and cultural beauty. Intense tourism and development in recent years has allegedly led to a large loss of local forest cover. In order to conduct an independent investigation of these changes, we suggest here a set of methodologies based on public remote-sensing data.

The end of goal of this project is to generate vegetation cover classification images of the study area from 2013-2017. With this images, we aim to develop a change detection technique that would indicate to us regions undergoing significant vegetation loss. These regions would then be flagged for further investigation. 

## Guide to Methodologies (Ubuntu Linux OS)

### 1. Bulk Filter Remote Sensing Data using Google Earth Engine

Firstly, we need to download relevant remote-sensing data for our purpose. The traditional means of going about this process would be to navigate to various data pproviders such as the USGS's [Earth-Explorer](https://earthexplorer.usgs.gov/) interface. Although this is a very interactive and comfortable interface, it does present us with some key limitations. For one, we are limited to how much we can query and filter large data before downloading it. This would mean we would need to download many GB's of data, only to use a few MB at the end. Next, we are also limited with how much data we can query at once. For example, the USGS Earth-Explorer interface only hosts ceratin datasets and perhaps not all the relevant ones. In order to access other datasets, we would need to navigate to another interface altogether. 

In order to overcome these issues, we propose using the Google Earth Engine (GEE). The Google Earth Engine is essentially a Javascript-based API hosted on Google's infrastructure. This API allows us to query a large volume of Earth observation datasets and to pre-process them before downloading. This provides an efficient means of data-processing for our needs. Here, we choose to download the Landsat 8 Surface Reflectance data. 

For simplicity, first navigate to a desired directory and clone this git repository onto your workspace:

`$ git clone https://github.com/AtreyaSh/vegMonitor.git`

1. To start this process, a Google account is necessary. Next, one needs to sign up for GEE. If this is not done as yet, navigate to the following site to sign up:

   https://earthengine.google.com/

2. After signing up for GEE, log into your account within GEE and navigate to the central code editor. Create a new repository and name it accordingly. 

3. Next, we need to upload certain assets required for our analysis. Within the GEE code editor, navigate to the `Assets` tab and select `NEW` and `Table upload`. Select all the files corresponding to the generic file path `vegMonitor/GEE_Input/DL_PL_KN_Dissolve_WGS84` with the endings `.cpg, .dbf, .prj, .sbn, .sbx, .shp, .shp.xml, .shx `. Let this asset be named `DL_PL_KN_Dissolve_WGS84`. Import this asset into the code editor with the variable name `table`.

4. Select all the files corresponding to the generic file path `vegMonitor/GEE_Input/DL_PL_KN_Dissolve_UTM43N` with the endings `.cpg, .dbf, .prj, .sbn, .sbx, .shp, .shp.xml, .shx `. Let this asset be named `DL_PL_KN_Dissolve_UTM43N`. Import this asset into the code editor with the variable name `table2`.

5. We now have the important variables imported. Now, copy and paste the code from the `GEEBulkFilter.js` file into the GEE code editor. With this, we are good to go. 

6. Run the script and the corresponding data will be sent to your Google Drive for downloading!

**What does the `GEEBulkFilter.js` script do?**

1. Queries Landsat 8 Surface Reflectance Imagery for the WRS Row/Path 147/38 in the time period from 2011-01-01 to 2017-05-01.

2. Chooses images with a mean cloud score of less than 10.

3. Clips the images to a desired shapefile.

4. Removes clouds, cloud-shadows, water and snow from the images to provide clear images for analysis.

5. Removes pixels which experience significant terrain-related shadows. This is done by calculating hillshade and setting a threshold for significant shadows.

6. Exports resulting images into your Google Drive.

**Results of running `GEEBukFilter.js`**

This script results in 31 Landsat 8 SR images from 2013-2017 being downloaded into Google Drive. These images can be found in the `vegMonitor/GEE_Output` directory. 

### 2. Cleaning GEE Data

For this section, please refer to the markdown file `GEEDataClean.md` with the following [link](GEEDataClean.md).

### 3. Vegetation Classification and Change Detection

[Still under development...]
