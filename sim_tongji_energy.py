#! /usr/bin/python

import re
import string


def tongji():

	count = 0
	energy_aver = 0;


	wenben = open("log(energy).txt", "r")

	energy_ar = []
	for i in range(27):
		energy_ar.append(i)

	for line in wenben:
		s = line.split()
		if (len(s) > 1):
			i = string.atoi(s[1])
			energy_ar[i] = 10000 - string.atoi(s[3])
			#print "energy_ar[%d] : " % i,energy_ar[i]

	energy_aver = energy_ar[0]
	for i in range(1,27):
		energy_aver = (energy_aver*i + energy_ar[i])/(i+1)
		print energy_aver

	print energy_aver
	return str(energy_aver)





if __name__ == '__main__':
	tongji()