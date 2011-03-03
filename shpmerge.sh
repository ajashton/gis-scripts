#!/bin/bash
set -e -u

# shpmerge.sh <outfile> <infile> ...

OUTFILE="$1"
shift

for INFILE in "$@"; do 
  if test -e "$OUTFILE"; then
    echo -n "Merging $INFILE ... "
    ogr2ogr -f "ESRI Shapefile" -update -append \
      "$OUTFILE" "$INFILE" -nln `basename $OUTFILE .shp` && \
      echo "OK" || exit 1
  else 
    echo -n "Creating $OUTFILE from $INFILE ... "
    ogr2ogr -f "ESRI Shapefile" "$OUTFILE" "$INFILE" && \
      echo "OK" || exit 1
  fi
done

echo "DONE!"
