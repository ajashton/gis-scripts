#!/usr/bin/env bash
set -e -u

# tif2geo.sh
# A wrapper for gdal_translate that will save you some typing/copying/pasting.
# It converts a plain tif to a geotif using the geographic extent of a 
# specified reference file. Useful after editing geotifs with applications
# such as GIMP, ImageMagick, etc.

# TODO:
# Implement custom output file?

# Specify locations of executables here if they are not in $PATH
GDALINFO=gdalinfo
GDAL_TRANSLATE=gdal_translate

# Default values:
COMPRESS=1

function usage() {
  echo "$0"
  echo "Uses gdalinfo and gdal_translate to copy geographic information"
  echo "into a plain TIFF file."
  echo ""
  echo "Usage: $0 -r reference file -f input_file -s srs_string [-u]"
  echo "-u creates an uncompress output file. LZW compression is used by default."
  exit
}

function set_srs() {
  # TODO: We really could autodetect this...
  case $1 in
    osm|goog|google|900913) INPUT_SRS="+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs";;
    wgs84|4326) INPUT_SRS="+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs";;
    ?) INPUT_SRS="$1";;
  esac
}

while getopts "f:h:o:r:s:u" ARG; do
  case $ARG in
    f)  INPUT_FILE="$OPTARG";;
    h)  usage; exit;;
    r)  REFERENCE_FILE="$OPTARG";;
    s)  set_srs "$OPTARG";;
    u)  COMPRESS=0;;
    [?])  usage; exit;;
  esac
done

TEMP_FILE="${INPUT_FILE}.TIF2GEO_TMP"

# Extract Upper Left and Lower Right coordinates from gdalinfo output
UL="`$GDALINFO $REFERENCE_FILE | awk '/Upper Left/ {print $4,$5}' | sed 's/[\,\)]//g'`"
LR="`$GDALINFO $REFERENCE_FILE | awk '/Lower Right/ {print $4,$5}' | sed 's/[\,\)]//g'`"

if [ $COMPRESS == 1 ]; then
  COMPRESS_OPT="-co compress=lzw"
fi

mv "$INPUT_FILE" "$TEMP_FILE"
$GDAL_TRANSLATE $COMPRESS_OPT -a_ullr $UL $LR -a_srs "$INPUT_SRS" "$TEMP_FILE" "$INPUT_FILE"
rm "$TEMP_FILE"