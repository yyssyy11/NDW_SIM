#! /usr/bin/python
#
# basic sim script
#
#

from random import *
from TOSSIM import *
from tinyos.tossim.TossimApp import *
import sys

def sim():
  

  n = NescApp()
  t = Tossim(n.variables.variables())
  r = t.radio()

  ff = open("log.txt", "w")

  topo = open("topo.txt", "r")


  for line in topo:
    s = line.split()
    if (len(s) > 0):
      if (s[0] == "gain"):
        r.add(int(s[1]), int(s[2]), float(s[3]))


  noise = open("meyer-heavy.txt", "r")
  for line in noise:
    s = line.strip()
    if s:
      val = int(s)
      for i in range(27):
        t.getNode(i).addNoiseTraceReading(val)

  
  for i in range (1,27):
    #print "Creating noise model for ",i;
    t.getNode(i).createNoiseModel()
    t.getNode(i).bootAtTime(i * 11512170000 + 235423990)

  t.getNode(0).createNoiseModel()
  #print "Creating noise model for 0";
  t.getNode(0).bootAtTime(i * 11512170000 + 235423990)


  m = t.getNode(0)
  v = m.getVariable("NdwC.energy_count")

  #t.addChannel("SINK", sys.stdout)
  #t.addChannel("BOOT", sys.stdout)
  #t.addChannel("BEACON", sys.stdout)
  #t.addChannel("PIT", sys.stdout)
  #t.addChannel("FIB", sys.stdout)
  #t.addChannel("CS", sys.stdout)
  #t.addChannel("DATA", sys.stdout)
  #t.addChannel("REPO", sys.stdout)

  t.addChannel("SINK", ff)
  t.addChannel("BOOT", ff)
  #t.addChannel("BEACON", ff)
  #t.addChannel("PIT", ff)
  #t.addChannel("FIB", ff)
  #t.addChannel("CS", ff)
  #t.addChannel("DATA", ff)
  t.addChannel("REPO", ff)
  #t.addChannel("ENERGY", ff)

  #t.runNextEvent()

  #while v.getData() > 3:
  #  t.runNextEvent()

  #print "Runing simuliation..."

  #m1 = t.getNode(1)
  #v1 = m1.getVariable("NdwC.energy_count")

  for i in range(0, 100000):
    t.runNextEvent()

  while v.getData() < 10000:
    t.runNextEvent()


  ff.close()

  print "----------SIM END----------"

if __name__ == '__main__':
  sim()