#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_SH=$(find ./target/linux/mediatek/filogic/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
MTWIFI_SH="./package/mtk/applications/mtwifi-cfg/files/mtwifi.sh"
# AP3000M 双频默认 SSID（与 AP3000M-EEPROM/98-ap3000m-wifi 保持一致）
AP3000M_SSID_2G="Airpi-AP3000M-2.4G"
AP3000M_SSID_5G="Airpi-AP3000M-5G"
if [ -f "$MTWIFI_SH" ]; then
	# 修改 MTK 闭源 Wi-Fi 驱动栈的默认名称和密码
	sed -i "s/ImmortalWrt-[[:alnum:].-]*/$WRT_SSID/g; s/encryption=none/encryption=psk2+ccmp/g" "$MTWIFI_SH"
	sed -i "/set wireless.default_\${dev}.encryption=psk2+ccmp/a\\					set wireless.default_\${dev}.key='$WRT_WORD'" "$MTWIFI_SH"
elif [ -f "$WIFI_SH" ]; then
	#修改WIFI名称（AP3000M 用机型前缀，脚本通常再拼 -2.4G/-5G）
	if [[ "${WRT_CONFIG:-}" == *AP3000M* ]]; then
		sed -i "s/BASE_SSID='.*'/BASE_SSID='Airpi-AP3000M'/g" $WIFI_SH
	else
		sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
	fi
	#修改WIFI密码
	sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
	#修改WIFI名称
	if [[ "${WRT_CONFIG:-}" == *AP3000M* ]]; then
		# 开源 mt76：按 band 分别设置 2.4G / 5G SSID
		sed -i "s/ssid='\${defaults?.ssid || \"ImmortalWrt\"}'/ssid='\${defaults?.ssid || (band_name == \"2g\" ? \"$AP3000M_SSID_2G\" : band_name == \"5g\" ? \"$AP3000M_SSID_5G\" : \"Airpi-AP3000M\")}'/g" "$WIFI_UC"
		sed -i "s/ssid='\${defaults?.ssid || \"OpenWrt\"}'/ssid='\${defaults?.ssid || (band_name == \"2g\" ? \"$AP3000M_SSID_2G\" : band_name == \"5g\" ? \"$AP3000M_SSID_5G\" : \"Airpi-AP3000M\")}'/g" "$WIFI_UC"
	else
		sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	fi
	#修改WIFI加密方式
	sed -i "s/encryption='none'/encryption='psk2'/g" $WIFI_UC
	#修改WIFI密码
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE
#修改默认时区为北京时间
sed -i "s/timezone='GMT0'/timezone='CST-8'/g" $CFG_FILE
sed -i "s/zonename='UTC'/zonename='Asia\/Shanghai'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#引入私有扩展配置
if [ -f "$GITHUB_WORKSPACE/Config/PRIVATE.txt" ]; then
	echo "Applying private configurations from PRIVATE.txt..."
	cat $GITHUB_WORKSPACE/Config/PRIVATE.txt >> ./.config
fi

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi
