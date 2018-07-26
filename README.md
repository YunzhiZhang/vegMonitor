# vegMonitor 

## Investigating losses in vegetation cover using remote sensing data and the random forests algorithm

This is a project which summarizes remote sensing data processing techniques in order to extract key vegetation data and indications about vegetation changes.

## Case study and objectives

The study area of this project is [Dharamshala Tehsil](https://en.wikipedia.org/wiki/Dharamshala), located in the Indian state of Himachal Pradesh. This region is famous for its natural and cultural beauty. Intense tourism and development in recent years has allegedly led to a large loss of local forest cover. In order to conduct an independent investigation of these changes, we suggest here a set of methodologies based on public remote-sensing data.

The end of goal of this project is to generate vegetation cover classification images of the study area from 2013-2017. With this images, we aim to develop a change detection technique that would indicate to us regions undergoing significant vegetation loss. These regions would then be flagged for further investigation.

## Guide to methodologies for Ubuntu 16.04

### 1. Pre-processing remote sensing data using Google Earth Engine

Firstly, we need to download relevant remote-sensing data for our purpose. The traditional means of going about this process would be to navigate to various data providers such as the USGS's [Earth-Explorer](https://earthexplorer.usgs.gov/) interface. Although this is a very interactive and comfortable interface, it does present us with some key limitations. For one, we are limited to how much we can query and filter large data before downloading it. This would mean we would need to download many GB's of data, only to use a few MB at the end. Next, we are also limited with how much data we can query at once. For example, the USGS Earth-Explorer interface only hosts certain datasets and perhaps not all the relevant ones. In order to access other datasets, we would need to navigate to another interface altogether. 

In order to overcome these issues, we propose using the Google Earth Engine (GEE). The Google Earth Engine is essentially a Javascript-based API hosted on Google's infrastructure. This API allows us to query a large volume of Earth observation datasets and to pre-process them before downloading. This provides an efficient means of data-processing for our needs. Here, we choose to download the Landsat 8 Surface Reflectance data. 

For a detailed look on how to acquire and pre-process remote sensing data, please refer to the following GitHub repository: https://github.com/AtreyaSh/geeBulkFilter

### 2. Supervised vegetation classification using field data and the random forests algorithm

[Still under development...]

### 3. Vegetation loss detection using a custom-rasterized Mann-Whitney technique

[Still under development...]
