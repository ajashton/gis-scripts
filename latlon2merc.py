#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Converts a latlon coordinate or bounding box to web mercator, moving/cropping
# it to within the web mercator 'square world' if necessary.
#
# Example usage: latlon2merc.py -180 -90 180 90

import sys
from mapnik import Box2d, Coord, Projection, ProjTransform

latlon = Projection('+proj=latlong +datum=WGS84')
merc = Projection('+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs')

max_4326 = 85.0511287798066
max_3785 = 20037508.3427892

transform = ProjTransform(latlon, merc)

if len(sys.argv) == 3:
    ll = transform.forward(Coord(float(sys.argv[1]), float(sys.argv[2])))
    if (ll.y > max_3785):
        print(' '.join([str(ll.x), str(max_3785)]))
    elif (ll.y < -max_3785):
        print(' '.join([str(ll.x), str(-max_3785)]))
    else:
        print(' '.join([str(ll.x), str(ll.y)]))

elif len(sys.argv) == 5:
    minx, miny, maxx, maxy = (
        float(sys.argv[1]),
        float(sys.argv[2]),
        float(sys.argv[3]),
        float(sys.argv[4])
    )

    if (miny < -max_4326):
        miny = -max_4326

    if (maxy > max_4326):
        maxy = max_4326

    bbox = transform.forward(Box2d(minx, miny, maxx, maxy))
    print(' '.join([
        str(bbox.minx),
        str(bbox.miny),
        str(bbox.maxx),
        str(bbox.maxy)
    ]))

else:
    print("Error: Incorrect number of arguments")
