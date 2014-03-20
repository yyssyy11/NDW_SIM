#! /usr/bin/python
#coding=utf-8

import sys
import os, subprocess 
import string
import time
#import sim_ndw
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
				#print head_set
				line = '\t' + ' '.join(head_set) + '\n'
				#continue
		head_new.write(line)
	os.rename("Ndw_new.h","Ndw.h")

name = "TIMER_PERIOD_REPO"
val = [5,10,20,50,100,150,200]

cs_name = "CS_STALE_COUNT"
cs_val = [0,1,2,3,4,5]

pit_name = "PIT_STALE_COUNT"
pit_val = [0,1,2,3,4,5]

ISOTIMEFORMAT='%Y-%m-%d %X'

def time_sim():
	res_file = open("time_sim_result.txt", "w")
	res_file.write('\ntime_sim_result.txt\n'+time.strftime(ISOTIMEFORMAT, time.localtime(time.time()))+'\n\n')
	res_file.write("发送间隔（ms）	发送请求数量	收到回应数量	丢包率		接收时延（大致/ms）" + '\n')
	print ("发送间隔（ms）	发送请求数量	收到回应数量	丢包率		接收时延（大致/ms）" + '\n')
	for i in range(len(val)):
		set_fun(name, val[i])
		os.system('make micaz sim > /dev/null 2>&1')
		res_file.write(str(val[i]) + '\t\t\t\t')
		
		#sim_ndw.sim()
		os.system('python sim_ndw.py')
		print (str(val[i]) + '\t\t\t\t'),
		tongji_item = sim_tongji.tongji()
		res_file.write(tongji_item + '\n')

def cs_sim():
	res_file = open("cs_sim_result.txt", "w")
	res_file.write('\ncs_sim_result.txt\n'+time.strftime(ISOTIMEFORMAT, time.localtime(time.time()))+'\n\n')
	res_file.write("CS缓存时间（s）	发送请求数量	收到回应数量	丢包率		接收时延（大致/ms）" + '\n')
	print ("CS缓存时间（s）	发送请求数量	收到回应数量	丢包率		接收时延（大致/ms）" + '\n')
	for i in range(len(cs_val)):
		set_fun(cs_name, cs_val[i])
		os.system('make micaz sim > /dev/null 2>&1')
		res_file.write(str(cs_val[i]) + '\t\t\t\t')
		
		#sim_ndw.sim()
		os.system('python sim_ndw.py')
		print (str(cs_val[i]) + '\t\t\t\t'),
		tongji_item = sim_tongji.tongji()
		res_file.write(tongji_item + '\n')

def pit_sim():
	res_file = open("pit_sim_result.txt", "w")
	res_file.write('\npit_sim_result.txt\n'+time.strftime(ISOTIMEFORMAT, time.localtime(time.time()))+'\n\n')
	res_file.write("PIT缓存时间（s）	发送请求数量	收到回应数量	丢包率		接收时延（大致/ms）" + '\n')
	print ("PIT缓存时间（s）	发送请求数量	收到回应数量	丢包率		接收时延（大致/ms）" + '\n')
	for i in range(len(pit_val)):
		set_fun(pit_name, pit_val[i])
		os.system('make micaz sim > /dev/null 2>&1')
		res_file.write(str(pit_val[i]) + '\t\t\t\t')
		
		#sim_ndw.sim()
		os.system('python sim_ndw.py')
		print (str(pit_val[i]) + '\t\t\t\t'),
		tongji_item = sim_tongji.tongji()
		res_file.write(tongji_item + '\n')


if __name__ == '__main__':
	#time_sim()
	#cs_sim()
	pit_sim()


	print "----------ALL END--------------"