#!/usr/bin/env python
# -*- coding: utf-8 -*-

# WARNING: 
# You should definitely test this in a sandbox first to make sure it does what
# you think it should. Use at your own risk.

'''
tms-prune.py: removes extra tiles from a TMS tileset

Notes:

  For now we assume that "extra" means outside of the web-mercator bounding-box
  for the whole earth. Given a directory structure of /z/x/y.ext, files/folders
  that do not fit the following rule are unnecessary:

    z >= 0 and z <= 18 and x < 2**z and y < 2**z

  For now, we are ignoring files and folders whose name is not a number. In the
  future we may want an option to delete these as well.
  
  This script is also pretty slow. As it is, it checks nearly every file in a
  layer to see if it's needed or not. This could be sped up by only searching
  for extra files that are likely to be present, with a full search being
  optional.
'''

import os, sys
from shutil import rmtree
from optparse import OptionParser

def is_tms_zlevel(z):
  '''
    Returns the directory as an integer if it is a valid TMS z-value.
    Returns -1 if the directory is a number, but not a valid TMS z-value.
    Returns -2 if the directory is not a number.
  '''
  try:
    int(z)
  except ValueError:
    return -2
  z = int(z)
  if z >= 0 and z <= 18:
    return z
  else:
    return -1

def delete(path):
  ''' Delete a file or directory, or just print the path if --list '''
  if os.path.isdir(path):
    path_type = "directory"
  elif os.path.isfile(path):
    path_type = "file"
  else:
    # then what is it?
    return 0
  if options.list_only:
    print path
  else:
    if path_type == "directory":
      rmtree(path)
    if path_type == "file":
      os.remove(path)

def prune_layer(layer):
  print "Pruning %s" % (layer)
  count = 0
  msg = ""
  for z in os.listdir(layer):
    if is_tms_zlevel(z) < 0:
      continue
    z_dir = os.path.join(layer, z)
    max_xy = 2**int(z)-1
    for x in os.listdir(z_dir):
      x_dir = os.path.join(z_dir, x)
      if not os.path.isdir(x_dir):
        continue
      try:
        if int(x) > max_xy:
          count = count + len([name for name in os.listdir(x_dir) if os.path.isfile(name)])
          delete(x_dir)
          for c in msg: sys.stdout.write(chr(8))
          msg = "%s out-of-bounds tiles deleted" % (count)
          sys.stdout.write(msg)
        else:
          for y in os.listdir(x_dir):
            y_path = os.path.join(x_dir, y)
            # Drop the file extension
            y_val = os.path.splitext(y)[0]
            try:
              if int(y_val) > max_xy:
                count = count + 1
                delete(y_path)
                for c in msg: sys.stdout.write(chr(8))
                msg = "%s out-of-bounds tiles deleted" % (count)
                sys.stdout.write(msg)
            except ValueError:
              pass
      except ValueError:
        pass
  sys.stdout.write(chr(10))

def main(layers):
  for layer in layers:
    if not os.path.isdir(layer):
      # @TODO: Proper error handling?
      print "Warning: %s is not a directory." % (layer)
    else:
      prune_layer(layer)

if __name__ == '__main__':
  usage = "usage: %prog LAYERS..."
  
  parser = OptionParser(usage=usage)
  
  parser.add_option("-l", "--list",
    action="store_true", dest="list_only", default=False,
    help="Don't remove any files, just print a list")
  
  (options, args) = parser.parse_args()
  
  if len(args) < 1:
    # We need at least one layer to prune
    parser.error('No TMS layer specified')
  main(args)
