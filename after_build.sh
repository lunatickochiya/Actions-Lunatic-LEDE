#!/bin/bash
#=================================================
# this script is from https://github.com/HiGarfield  
# Writed By lunatickochiya
# QQ group :286754582  https://jq.qq.com/?_wv=1027&k=5QgVYsC   
#=================================================

#cd openwrt
mkdir out
mkdir kernelipks
mkdir ipks
rm -rf build_dir/target* build_dir/toolchain* staging_dir/target* staging_dir/toolchain*
cp -u -f bin/targets/*/*/packages/* kernelipks/
cp -u -f bin/targets/*/*/*-*-squashfs-sysupgrade.bin out/
cp -u -f -r bin/packages/* ipks/
zip -qq -r kernelipks.zip kernelipks
zip -qq -r out.zip out
zip -qq -r ipks.zip ipks
# Enter your commands here, e.g.
echo "Copy Success!"
