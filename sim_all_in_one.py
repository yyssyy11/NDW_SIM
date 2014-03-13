#! /usr/bin/python

import sys
import os
import string
import sim_ndw
import sim_tongji




def set_fun(name, val):
	head = open("Ndw.h", "r")
	head_new = open("Ndw_new.h", "w")
	for line in head:
		head_set = line.split()
		if(len(head_set) > 0 ):
			if(head_set[0] == name):
				#print head_set
				head_set[2] = str(val) + ","
				print head_set
				line = '\t' + ' '.join(head_set) + '\n'
				#continue
		head_new.write(line)
	os.rename("Ndw_new.h","Ndw.h")

name = "TIMER_PERIOD_REPO"
val = [5,10,20,50,100,150,200]

for i in range(1):
	set_fun(name, val[i])



print "-------------END----------------"