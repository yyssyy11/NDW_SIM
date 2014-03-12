NDW_SIM
=======

把NDN的思想用在传感器网络WSN中，进行相应简化和路由的设计，在TinyOS系统上变成实现；使用TOSSIM仿真TinyOS程序。

-------------------------------
安装TinyOS开发环境，然后在程序目录下执行
make micaz sim
编译生成仿真文件

sim_ndw.py		用于执行仿真文件和记录结果到log.txt。
sim_tongji.py	用于统计log的结果，丢包率和时延等。

另外两个脚本也是为了方便设置仿真条件和实验结果的，正在完善。