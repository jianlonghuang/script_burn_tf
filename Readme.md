## Readme

make_format-nvdla-rootfs.sh --- 此脚本用于对外部发布， 用于帮助客户生成启动 tf 卡。

hifive-unleashed-vfat.part      --- linux 内核等, ./work/

rootfs.ext4  --- rootfs 文件系统烧录文件, ./work/buildroot_rootfs/images/

u-boot.bin  ---  u-boot 烧录镜像, ./work/HiFive_U-Boot/



运行环境： ubuntu， 需要安装 sudo apt-get install gdisk parted gparted

使用例子: 

`sudo ./make_format-nvdla-rootfs.sh /dev/sdb`



使用注意事项：

1. tf 卡容量推荐为 32G或以上

2. tf 卡需要使用 *GPT* 分区模式， 注意不能是 dos 分区模式。可以在 ubuntu 下使用 gdisk 或者用 gparted 更改。

3. 需要用 sudo 执行脚本，**切记 tf 卡的设备名要对，弄错很严重，后果自负**

4. 如果使用时遇到错误，多执行几次即可

   

