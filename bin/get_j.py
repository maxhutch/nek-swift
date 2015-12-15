#!/home/maxhutch/anaconda3/bin/python

from sys import argv, exit
from os.path import exists, join

tdir = argv[1]
name = argv[2]

if not exists(tdir):
  print("0")
  exit()

j = 10
while j > -1:
  fname = tdir + "/{:}-{:}.output".format(name, j)
  if exists(fname):
    with open(fname, "r") as f:
      lines = f.readlines()
    for line in lines:
      if "total elapsed time" in line:
        print("{:d}".format(j+1))
        exit()
  j = j - 1

print("{:d}".format(j+1))
  
