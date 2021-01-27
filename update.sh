#!/bin/sh
function UpdateApp(){
	for a in $(opkg print-architecture | awk '{print $2}'); do
		case "$a" in
			all|noarch)
				;;
			aarch64_armv8-a|arm_arm1176jzf-s_vfp|arm_arm926ej-s|arm_cortex-a15_neon-vfpv4|arm_cortex-a5|arm_cortex-a53_neon-vfpv4|arm_cortex-a7_neon-vfpv4|arm_cortex-a8_vfpv3|arm_cortex-a9|arm_cortex-a9_neon|arm_cortex-a9_vfpv3|arm_fa526|arm_mpcore|arm_mpcore_vfp|arm_xscale|armeb_xscale)
				ARCH="arm"
				;;
			i386_pentium|i386_pentium4)
				ARCH="32"
				;;
			ar71xx|mips_24kc|mips_mips32|mips64_octeon)
				ARCH="mips"
				;;
			mipsel_24kc|mipsel_24kec_dsp|mipsel_74kc|mipsel_mips32|mipsel_1004kc_dsp)
				ARCH="mipsle"
				;;
			x86_64)
				ARCH="64"
				;;
			*)
				exit 0
				;;
		esac
	done
}

function download_binary(){
	logfile="/tmp/ssrplus.log"
	v2ray_remote_name=$(uci get shadowsocksr.@global[0].v2ray_remote_name 2>/dev/null)
	v2ray_path=$(uci get shadowsocksr.@global[0].v2ray_path 2>/dev/null)
	[ ! -d "$v2ray_path" ] && mkdir -p $v2ray_path
	v2ray_main_down_url=$(uci get shadowsocksr.@global[0].v2ray_main_down_url 2>/dev/null)
	available=$(df $v2ray_path -k | sed -n 2p | awk '{print $4}')
	if [ $available -ge 6384 ]; then
	echo "$(date "+%Y-%m-%d %H:%M:%S") 开始下载v2ray/xray二进制文件......" >> ${logfile}
	[ ! -d "/tmp/v2raydownlad" ] && mkdir -p /tmp/v2raydownlad
	bin_dir="/tmp/v2raydownlad"
	rm -rf $bin_dir/v2ray*.zip
	echo "$(date "+%Y-%m-%d %H:%M:%S") 当前下载目录为$bin_dir" >> ${logfile}
	UpdateApp
	cd $bin_dir
	v2down_url=$v2ray_main_down_url/"$v2ray_remote_name"-"$ARCH".zip
	echo "$(date "+%Y-%m-%d %H:%M:%S") 正在下载v2ray/xray可执行文件......" >> ${logfile}
	local a=0
		while [ ! -f $bin_dir/"$v2ray_remote_name"-"$ARCH"*.zip ]; do
		[ $a = 6 ] && exit
		wget-ssl --tries 5 --timeout 20 --no-check-certificate $v2down_url
		sleep 2
		let "a = a + 1"
	done
	
	if [ -e $bin_dir/"$v2ray_remote_name"-"$ARCH"*.zip ]; then
	echo "$(date "+%Y-%m-%d %H:%M:%S") 成功下载v2ray/xray可执行文件" >> ${logfile}
	echo "$(date "+%Y-%m-%d %H:%M:%S") 当前安装目录为$v2ray_path..." >> ${logfile}
	echo "$(date "+%Y-%m-%d %H:%M:%S") 即将安装v2ray/xray可执行文件，即将关闭SSR，删除旧版v2ray，解压新版v2ray" >> ${logfile}
	/etc/init.d/shadowsocksr disable
	/etc/init.d/shadowsocksr stop
	[ -e $v2ray_path/v2ray ] && rm -rf $v2ray_path/v2* && rm -rf $v2ray_path/geo*
	[ -e $v2ray_path/xray ] && rm -rf $v2ray_path/xra* && rm -rf $v2ray_path/geo*
	unzip -o "$v2ray_remote_name"-"$ARCH"*.zip -d $bin_dir/v2ray-ver-neo-linux-"$ARCH"/ > /dev/null 2>&1
	echo "$(date "+%Y-%m-%d %H:%M:%S") 解压新版v2ray/xray完成，即将移动新版程序到安装目录" >> ${logfile}
	mv $bin_dir/v2ray-ver-neo-linux-"$ARCH"/v2ray $v2ray_path
	mv $bin_dir/v2ray-ver-neo-linux-"$ARCH"/xray $v2ray_path
	mv $bin_dir/v2ray-ver-neo-linux-"$ARCH"/v2ctl $v2ray_path
	mv $bin_dir/v2ray-ver-neo-linux-"$ARCH"/geoip.dat $v2ray_path
	mv $bin_dir/v2ray-ver-neo-linux-"$ARCH"/geosite.dat $v2ray_path
	echo "$(date "+%Y-%m-%d %H:%M:%S") 移动新版程序到安装目录完成，删除解压下载的临时文件，并赋予v2ray/xray权限" >> ${logfile}
	rm -rf $bin_dir/v2ray-ver-neo-linux-"$ARCH"
	rm -rf $bin_dir/v2ray*.zip
	rm -rf $bin_dir/xray*.zip
	if [ -e "$v2ray_path/v2ray" ] || [ -e "$v2ray_path/xray" ]; then
	chmod 0777 $v2ray_path/v2ray
	chmod 0777 $v2ray_path/xray
	chmod 0777 $v2ray_path/v2ctl
	ln -s $v2ray_path/v2ray $v2ray_path/xray
	echo -e "${latest_ver}" > /usr/share/v2ray/local_ver
	echo "$(date "+%Y-%m-%d %H:%M:%S") 成功安装v2ray/xray：$latest_ver，正在重启进程，重启失败请到客户端选项点击保存应用" >> ${logfile}
	/etc/init.d/shadowsocksr enable
fi
else
	echo "$(date "+%Y-%m-%d %H:%M:%S") 下载v2ray/xray二进制文件失败，请重试！" >> ${logfile}
fi
else
	echo "$(date "+%Y-%m-%d %H:%M:%S") 当前安装目录为$v2ray_path,安装路径剩余空间不足请修改路径！" >> ${logfile}
fi
}

function check_latest_version(){
	v2ray_main_tag_url=$(uci get shadowsocksr.@global[0].v2ray_main_tag_url 2>/dev/null)
	latest_ver="$(wget --no-check-certificate -qO- $v2ray_main_tag_url | grep 'name' | cut -d\" -f4 | head -1)"
	[ -z "${latest_ver}" ] && echo -e "\nFailed to check latest version, please try again later." >>/tmp/ssrplus.log && exit 1
	v2ray_version_dir="/usr/share/v2ray/"
	[ ! -d "$v2ray_version_dir" ] && mkdir -p $v2ray_version_dir
	if [ ! -e "/usr/share/v2ray/local_ver" ]; then
		echo -e "Local version: NOT FOUND, cloud version: ${latest_ver}." >>/tmp/ssrplus.log
		download_binary
	else
		if [ "$(cat /usr/share/v2ray/local_ver)" != "${latest_ver}" ]; then
			echo -e "Local version: $(cat /usr/share/v2ray/local_ver 2>/dev/null), cloud version: ${latest_ver}." >>/tmp/ssrplus.log
			download_binary
		else
			echo -e "\nLocal version: $(cat /usr/share/v2ray/local_ver 2>/dev/null), cloud version: ${latest_ver}." >>/tmp/ssrplus.log
			echo -e "You're already using the latest version." >>/tmp/ssrplus.log
			[ "${luci_update}" == "n" ] && /etc/init.d/shadowsocksr restart
			exit 3
		fi
	fi
}

function check_core_if_already_running(){
	running_tasks="$(ps |grep "v2ray" |grep "v2ray_update.sh" |grep "update_core" |grep -v "grep" |awk '{print $1}' |wc -l)"
	[ "${running_tasks}" -gt "2" ] && { echo -e "\nA task is already running." >> "/tmp/ssrplus.log"; exit 2; }
}

function main(){
	check_core_if_already_running
	check_latest_version
}

luci_update="n"
	[ "$1" == "luci_update" ] && luci_update="y"
	main
