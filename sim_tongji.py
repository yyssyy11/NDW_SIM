#! /usr/bin/python

import re
import string


def cal_line_time_ms(s):
	s_sink_time = s[2].split(":")
	sink_time = string.atoi(s_sink_time[0])*3600 + string.atoi(s_sink_time[1])*60 + string.atof(s_sink_time[2])
	sink_time = sink_time *1000
	return int(sink_time)


count = 0
send_num = 0
recv_num = 0
time_delay_ms = 0.0


wenben = open("log.txt", "r")
send_list = [0 for y in range(20000)]
recv_list = [0 for y in range(20000)]

for line in wenben:
	s = line.split()
	if (len(s) > 3):
		if (s[3] == "SINK" and s[4] == "sink_send"):
			seq = string.atoi(s[8])
			time = cal_line_time_ms(s)
			send_list[seq] = time
		if (s[3] == "SINK" and s[4] == "sink_recv"):
			seq = string.atoi(s[8])
			time = cal_line_time_ms(s)
			recv_list[seq] = time

for count in range(1,20000):
	if (send_list[count] != 0):
		send_num = send_num + 1
		#print "send list [%d]" % count, send_list[count]
		if (recv_list[count] != 0):
			recv_num = recv_num + 1
			time_delay_temp = recv_list[count] - send_list[count];
			time_delay_ms = (time_delay_ms*(recv_num-1) + time_delay_temp)/recv_num
			#print "recv list [%d]" % count, recv_list[count],
			#print "time delay [%d]" % count, time_delay_temp,
			#print "td average [%d]" % recv_num, time_delay_ms


packet_loss_rate = 1 - float(recv_num)/float(send_num)

print "%d\t\t\t%d\t\t\t%.5f\t%.5f" % (send_num, recv_num, packet_loss_rate, time_delay_ms)

#print send_num, recv_num, "%.5f" % packet_loss_rate, "%.5f" % time_delay_ms
