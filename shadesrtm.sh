#!/bin/bash
set -e -u

## This script is intended more as documentation of the SRTM -> Hillshade tiles
## process rather than something that useful out-of-the-box. You should 
## READ THROUGH THIS COMPLETELY BEFORE USING THIS SCRIPT to make sure you 
## understand what it is going to do - there are practically no safeguards in
## place and many assumptions are made. USE AT YOUR OWN RISK.

## NOTES:
##   * It is safe to ignore 'unknown field' warnings from convert & mogrify - 
##     this happens because these programs don't understand spatial data.

## Required programs:
##    gdal >=1.7.0
##    imagemagick (tested with 6.5.x)
##    tif2geo.sh - download at 
##      <http://github.com/ajashton/gis-scripts/blob/master/tif2geo.sh>

## See <http://www.gdal.org/gdaldem.html#gdaldem_color_relief> for more on what
## a color ramp file should look like.
COLOR_RAMP="/home/aj/devseed/maps/_raster/afcount_winter.ramp"

## The ramp I use for slope is:
##   90 0 0 0
##   0 255 255 255
SLOPE_RAMP="/home/aj/devseed/maps/_raster/slope.ramp"

TIF2GEO="$HOME/bin/tif2geo.sh"

## prepare subdirectories for output files
mkdir -p {slope,slope_render,hillshade,color,merged}

for SRTM in $@; do 
  ## '-s 111120' is the proper scale for data in metres.
  echo -n "Calculating slope [$SRTM]: "
  gdaldem slope -s 111120 $SRTM slope/$SRTM
  ## the output of 'gdaldem slope' is not directly useful - we need to apply 
  ## colors to the values. A 0° slope will be white, a 90° slope will be black.
  echo -n "Rendering slope [$SRTM]: "
  gdaldem color-relief slope/$SRTM $SLOPE_RAMP slope_render/$SRTM
  
  echo -n "Generating hillshade [$SRTM]: "
  gdaldem hillshade -s 111120 $SRTM hillshade/$SRTM
  mogrify -fill "#b5b5b5" -opaque "#000" hillshade/$SRTM
  
  echo -n "Generating color-relief [$SRTM]: "
  gdaldem color-relief $SRTM $COLOR_RAMP color/$SRTM
  
  ## merge everything with imagemagick
  echo -n "Merging $SRTM..."
  convert color/$SRTM \
    -compose soft-light hillshade/$SRTM -composite \
    -compose multiply slope_render/$SRTM -composite \
    -crop 5999x5999+1+1 merged/$SRTM
    
## For just slope & hillshade:
#  convert slope_render/$SRTM \
#    -compose overlay hillshade/$SRTM -composite \
#    -crop 5999x5999+1+1 merged/$SRTM

  ## IM destroys geo data - restore with this script I wrote. See:
  ## <http://github.com/ajashton/gis-scripts/blob/master/tif2geo.sh>
  echo -n "Restoring spatial data [$SRTM]: "
  $TIF2GEO -s 4326 -r $SRTM -f merged/$SRTM
done

## Make one big tiff
echo -n "Stitching single output file..."
gdal_merge.py -o terrain-merged-4326.tif merged/srtm_*.tif

## Reproject for gdal2tiles. '-wm' is memory cache in MB
echo -n "Reprojecting output file..."
gdalwarp -wm 512 -t_srs "EPSG:3785" -r lanczos terrain-merged-4326.tif terrain-merged-3785.tif

## render tiles, eg:
#gdal2tiles.py -z 5-11 -r lanczos terrain-merged-3785.tif
