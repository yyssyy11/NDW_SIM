#! /usr/bin/python

import sys

head = open("Ndw.h", "")
for line in head:
  head_set = line.split()
  if(head_set[0] == "TIMER_PERIOD_REPO"):
    print head_set


print "-------------END----------------"