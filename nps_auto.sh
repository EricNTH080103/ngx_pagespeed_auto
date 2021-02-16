#!/bin/bash
Green_font="\033[32m" && Yellow_font="\033[33m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
NGX_DIR=/www/server/nginx
NPS_VESION=1.13.35.2-stable

echo -e "${Green_font}
# This script will automatically install NGX_PAGESPEED Module on your nginx server.
# EricNTH080103/ngx_pagespeed_auto
# Reference: madlifer/ngx_pagespeed_auto
${Font_suffix}"

download_ngx_pagespeed(){
	cd ${NGX_DIR}/src
	wget https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VESION}.zip
	unzip v${NPS_VESION}.zip
	rm v${NPS_VESION}.zip
	NPS_DIR=$(find . -name "*pagespeed-ngx-${NPS_VESION}" -type d)
	mv $NPS_DIR ngx_pagespeed
	cd ngx_pagespeed
	NPS_RELEASE_NUMBER=${NPS_VESION/beta/}
	NPS_RELEASE_NUMBER=${NPS_VESION/stable/}
	PSPL_URL=https://dl.google.com/dl/page-speed/psol/${NPS_RELEASE_NUMBER}.tar.gz
	[ -e scripts/format_binary_url.sh ]
	PSPL_URL=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
	wget ${PSPL_URL}
	tar -xzvf $(basename ${PSPL_URL})
	rm $(basename ${PSPL_URL})
}

install_ngx_pagespeed(){
	cd ${NGX_DIR}/src
	NGX_CONF=`/usr/bin/nginx -V 2>&1 >/dev/null | grep 'configure' --color | awk -F':' '{print $2;}'`
	NGX_CONF="--add-module=${NGX_DIR}/src/ngx_pagespeed $NGX_CONF"
	./configure $NGX_CONF
	make
	make install
}

check_system() {
    if grep -Eqii "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
        PM='yum'
    elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
        DISTRO='RHEL'
        PM='yum'
    elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
        DISTRO='Aliyun'
        PM='yum'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='Debian'
        PM='apt'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='Ubuntu'
        PM='sudo'
    else
        DISTRO='unknow'
    fi
}

install_basic(){
	case ${PM} in
		yum)
			yum -y install sudo
			yum -y update 
			sudo yum -y install gcc-c++ pcre-devel zlib-devel make unzip libuuid-devel
		;;
		apt)
			apt -y install sudo
			sudo apt -y update
			sudo apt-get -y install build-essential zlib1g-dev libpcre3 libpcre3-dev unzip uuid-dev
		;;
		sudo)
			sudo apt -y update
			sudo apt-get -y install build-essential zlib1g-dev libpcre3 libpcre3-dev unzip uuid-dev
		;;
		*)
			echo -e "${Error} ��֧������ϵͳ !"
		;;
	esac
	echo -e "${Info} ģ��������װ��� !"
}

check_root(){
	[[ "`id -u`" != "0" ]] && echo -e "${Error} ���Ƚ���root�˻� !"
}

check_gcc(){
	gcc --version  && echo -e "${Info} ����ȷ��gcc�汾>=4.8! �������ⰴ����ȷ�ϣ�"
	read aNum
}

restart_ngx(){
	service nginx restart
	echo -e "${Info} ������Nginx!"
}

temp_swap_add(){
	sudo dd if=/dev/zero of=/swapfile bs=64M count=16
	sudo mkswap /swapfile
	sudo swapon /swapfile
	echo -e "${Info} ��ʱ����Swap�Խ���������ڴ治�����!"	
}

temp_swap_del(){
	sudo swapoff /swapfile
	sudo rm /swapfile
	echo -e "${Info} ɾ����ʱ���ӵ�swap�ռ�!"	
}

setup(){
	check_root
	check_system
	check_gcc
	install_basic
	temp_swap_add
	echo -e "${Info} ��װǰ��������ɣ�!"	
}

install(){
	download_ngx_pagespeed
	install_ngx_pagespeed
	temp_swap_del
	restart_ngx
	echo -e "${Info} ngx_pagespeed ģ�鰲װ���!"	
}

status(){
	NGX_CONF=`/usr/bin/nginx -V 2>&1 >/dev/null`
	echo $NGX_CONF | grep -q pagespeed
    if [ $? = 0 ]; then
        echo -e "${Info} Pagespeed�������� !"
    else
    	echo -e "${Error} Pagespeedû������ !"
    fi
}
echo -e "${Info} =====���ð�װ����====="
setup
echo -e "${Info} =====��ʼ���밲װ====="
install
echo -e "${Info} =====�������״̬====="
status