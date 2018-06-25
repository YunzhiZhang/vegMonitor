// Corresponding Google Earth Engine Editor code to query an ImageCollection, filter it, and later export

// Variables "table" and "table2" were manually imported into GEE via functions on the API
// "table" represents the study area (plus) polygon in the WGS84 CRS
// "table2" represents the study area (plus) in the UTM 43N projection

// Functions to calculate hillshade
function radians(img) {
return img.toFloat().multiply(Math.PI).divide(180);
}

function hillshade(az, ze, slope, aspect) {
var azimuth = radians(ee.Image(az));
var zenith = radians(ee.Image(ze));
return azimuth.subtract(aspect).cos()
.multiply(slope.sin())
.multiply(zenith.sin())
.add(
zenith.cos().multiply(slope.cos()));
}

// Filtering Landast 8 SR ImageCollection
var collection = ee.ImageCollection('LANDSAT/LC8_SR')
.filter(ee.Filter.eq('WRS_PATH', 147))
.filter(ee.Filter.eq('WRS_ROW', 38))
.filterDate('2011-01-01', '2017-05-01')
.filter(ee.Filter.lte('CLOUD_COVER', 10))
.map(function(image) {
return image.clipToCollection(table2);
})
.map(function(image){
var clear = image.select('cfmask').eq(0);
clear = clear.updateMask(clear);
return image.updateMask(clear);
})
.map(function(image){
var imageClipped = image3.clip(table);
var azimuthImage = image.metadata('solar_azimuth_angle');
var zenithImage = image.metadata('solar_zenith_angle');
var terrain = ee.Algorithms.Terrain(imageClipped);
var slope = radians(terrain.select('slope'));
var aspect = radians(terrain.select('aspect'));
var hillshadeExp = hillshade(azimuthImage, zenithImage, slope, aspect);
var hillshadeExpFilter = hillshadeExp.select(0).gt(0.01);
hillshadeExpFilter = hillshadeExpFilter.updateMask(hillshadeExpFilter);
var noList = ee.List([]);
var float = image.projection().transform().split(', ');
for(var i = 6; i <= 12; i += 2){
var no = ee.Number.parse(ee.String(float.get(i)).replace(']', '').replace(']', ''));
no = no.toFloat();
noList = noList.add(no);
}
var noList2 = noList.insert(1, 0).insert(3, 0);
var hillshadeExpFilterRP = hillshadeExpFilter.reproject('EPSG:32643', noList2);
return image.updateMask(hillshadeExpFilterRP);
})
.select(['B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7']);

// Function/command to bulk export filtered ImageCollection
var ExportCol = function(col, folder, scale,
nimg, maxPixels, region) {
nimg = nimg || 31;
scale = scale || 30;
maxPixels = maxPixels || 1e10;
var colList = col.toList(nimg);
var n = colList.size().getInfo();
for (var i = 0; i < n; i++) {
var img = ee.Image(colList.get(i));
var id = img.id().getInfo();
region = table2;
Export.image.toDrive({
image:img,
description: id + '_' + i,
folder: folder,
region: region,
scale: scale,
maxPixels: maxPixels,
});
}
};

ExportCol(collection, "Landsat_Export", 30);
