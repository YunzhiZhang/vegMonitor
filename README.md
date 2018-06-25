# Investigating vegetation cover changes in Dharamshala Tehsil, Indian Northwestern Himalayas, from 2013-2017

This is a project which summarizes remote sensing data processing techniques in order to extract key vegetation data and indications about vegetation changes.

## Background and Objectives

The study area of this project is [Dharamshala Tehsil](https://en.wikipedia.org/wiki/Dharamshala), located in the Indian state of Himachal Pradesh. This region is famous for its natural and cultural beauty. Intense tourism and development in recent years has allegedly led to a large loss of local forest cover. In order to conduct an independent investigation of these changes, we suggest here a set of methodologies based on public remote-sensing data.

The end of goal of this project is to generate vegetation cover classification images of the study area from 2013-2017. With this images, we aim to develop a change detection technique that would indicate to us regions undergoing significant vegetation loss. These regions would then be flagged for further investigation. 

## Guide to Methodologies (Ubuntu Linux OS)

### Bulk Filter Remote Sensing Data using Google Earth Engine

Firstly, we need to download relevant remote-sensing data for our purpose. The Google Earth Engine (GEE) provides an efficient means of bulk filtering data before finally downloading it. Here, we choose to download the Landsat 8 Surface Reflectance data. 

For simplicity, first navigate to a desired directory and clone this git repository onto your workspace:

`$ git clone https://github.com/AtreyaSh/vegMonitor.git`

1. To start this process, a Google account is necessary. Next, one needs to sign up for GEE. If this is not done as yet, navigate to the following site to sign up:

   https://earthengine.google.com/

2. After signing up for GEE, log into your account within GEE and navigate to the central code editor. Create a new repository and name it accordingly. 

3. Next, we need to upload certain assets required for our analysis. Within the GEE code editor, navigate to the `Assets` tab and select `NEW` and `Table upload`. Select all the files corresponding to the generic file path `vegMonitor/GEE_Inputs/DL_PL_KN_Dissolve_WGS84` with the endings `.cpg, .dbf, .prj, .sbn, .sbx, .shp, .shp.xml, .shx `. Let this asset be named `DL_PL_KN_Dissolve_WGS84`. Import this asset into the code editor with the variable name `table`.

4. Select all the files corresponding to the generic file path `vegMonitor/GEE_Inputs/DL_PL_KN_Dissolve_UTM43N` with the endings `.cpg, .dbf, .prj, .sbn, .sbx, .shp, .shp.xml, .shx `. Let this asset be named `DL_PL_KN_Dissolve_UTM43N`. Import this asset into the code editor with the variable name `table2`.

5. We now have the important variables imported. Now, copy and paste the code from the `GEEBulkFilter.js` file into the GEE code editor. With this, we are good to go. 

6. Run the script and the corresponding data will be sent to your Google Drive for downloading!

