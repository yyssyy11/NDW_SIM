#! /usr/bin/python

import sys
import os
import sim_tongji
import sim_ndw


os.system('make micaz sim')
print "-----------------------------"
sim_ndw.sim()
sim_tongji.tongji()




print "-------------END----------------"