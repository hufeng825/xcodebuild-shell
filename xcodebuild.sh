#!/bin/bash


###############设置需编译的项目配置名称###############
app_build_config="Release" #编译的方式,有Release,Debug，自定义的AdHoc等
app_display_name="自定义的"
app_version="0.1.1"
app_team_ID="Y4CQMPSC2J"




project_path=$(cd `dirname $0`; pwd)
# cd ${project_path}
for file_name in `ls`;
do
if [[ ${file_name} == "Podfile" ]]; then
	cocoapods_contain=true
	break
else
	cocoapods_contain=false
fi
done

if $cocoapods_contain; then
	# app文件名称
	project_file_name=$(basename ./*.xcworkspace)
else
	# app文件名称
	project_file_name=$(basename ./*.xcodeproj)
fi

# 通过app文件名获得工程target名字
app_target_name=$(echo $project_file_name | awk -F. '{print $1}')
#app文件中Info.plist文件路径
app_infoplist_path="${project_path}/${app_target_name}/Info.plist"
# 获取display name值
app_display_name_default=$(/usr/libexec/PlistBuddy -c "print CFBundleDisplayName " ${app_infoplist_path})
# 获取version值
app_version_default=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" ${app_infoplist_path})
# 获取build值
app_build_default=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${app_infoplist_path})
# 当前时间
current_date=`date +%Y%m%d%H%M`


#--------------------------------------------
# 修改app_display_name
#--------------------------------------------
echo ""
echo ""
echo ""
echo -e "\033[33m********************************************************\033[0m"
echo -e "\033[33m***************** app_display_name操作 *****************\033[0m"
echo -e "\033[33m********************************************************\033[0m"
if [[ ${app_display_name_default} != ${app_display_name} ]]; then
echo ""
echo -e "\033[32m- app_display_name默认值 = ${app_display_name_default}\033[0m"
echo ""
/usr/libexec/Plistbuddy -c "Set CFBundleDisplayName $app_display_name" "${app_infoplist_path}"
Project_display_name=$(/usr/libexec/PlistBuddy -c "print CFBundleDisplayName" ${app_infoplist_path})
echo ""
echo -e "\033[31m- app_display_name改变后 = ${Project_display_name}\033[0m"
echo ""
else
Project_display_name=$app_display_name_default
echo ""
echo -e "\033[32m- app_display_name 未修改\033[0m"
echo ""
fi

#--------------------------------------------
# 修改app_version版本号
#--------------------------------------------
echo ""
echo ""
echo ""
echo -e "\033[36m********************************************************\033[0m"
echo -e "\033[36m******************   app_version操作   *****************\033[0m"
echo -e "\033[36m********************************************************\033[0m"
if [[ ${app_version_default} != ${app_version} ]]; then
echo ""
echo -e "\033[32m- app_version默认值 = ${app_version_default}\033[0m"
echo ""
/usr/libexec/Plistbuddy -c "Set CFBundleShortVersionString $app_version" "${app_infoplist_path}"
Project_version=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" ${app_infoplist_path})
echo ""
echo -e "\033[31m- app_version改变后 = ${Project_version}\033[0m"
echo ""
else
Project_version=$app_version_default
echo ""
echo -e "\033[32m- app_version 未修改\033[0m"
echo ""
fi

#--------------------------------------------
# 修改app_build号
#--------------------------------------------
echo ""
echo ""
echo ""
echo -e "\033[37m********************************************************\033[0m"
echo -e "\033[37m*********************  app_build操作  ******************\033[0m"
echo -e "\033[37m********************************************************\033[0m"
if [[ ${app_build_default} != ${current_date} ]]; then
echo ""	
echo -e "\033[32m- app_build_default默认值 = ${app_build_default}\033[0m"
echo ""
/usr/libexec/Plistbuddy -c "Set CFBundleVersion $current_date" "${app_infoplist_path}"
Project_build=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${app_infoplist_path})
echo ""
echo -e "\033[31m- app_build改变后 = ${Project_build}\033[0m"
echo ""
else
Project_build=$app_build_default
echo ""
echo -e "\033[32m- app_build 未修改\033[0m"
echo ""
fi

#--------------------------------------------
# 定义路径
#--------------------------------------------
rm -rf ./xcodebuild
xcodebuild_path="${project_path}/xcodebuild"
mkdir -p $xcodebuild_path
build_path="${xcodebuild_path}/build"
mkdir -p $build_path
archive_path="${xcodebuild_path}/archive"
mkdir -p $archive_path
log_path="${xcodebuild_path}/log"
if [ $app_build_config = Debug ];then
	app_method=development
	app_direct_name=Debug-iphoneos
fi
if [ $app_build_config = Release ];then
	app_method=app-store
	app_direct_name=Release-iphoneos
fi


#--------------------------------------------
# 打包操作
#--------------------------------------------
if $cocoapods_contain; then

	export LC_ALL="en_US.UTF-8"
	pod install --verbose --no-repo-update >> $log_path

	workspace_name=${project_path}/${app_target_name}.xcworkspace


	############################## xcodebuild clean ##############################	
	xcodebuild clean -workspace ${app_target_name}.xcworkspace \
	-scheme ${app_target_name} \
	-configuration ${app_build_config} \
	>>$log_path
	if [ $? = 0 ]; then
		echo -e "\033[32m************* xcodebuild clean 完成 **************\033[0m"
		echo -e ""
	else
		echo -e "\033[31m************* xcodebuild clean 失败 **************\033[0m"
		echo -e ""
	exit;
	fi


	##############################xcodebuild 编译##############################
	xcodebuild -workspace ${workspace_name} \
	-scheme ${app_target_name} \
	-configuration ${app_build_config} \
	CONFIGURATION_BUILD_DIR=${build_path}/${app_direct_name} \
	>> $log_path

	if [ $? = 0 ]; then
		echo -e "\033[32m************* xcodebuild 编译 完成 **************\033[0m"
		echo -e ""
	else
		echo -e "\033[31m************* xcodebuild 编译 失败 **************\033[0m"
		echo -e ""
	exit;
	fi


	##############################导出xcarchive文件##############################
	xcodebuild archive -workspace ${workspace_name} \
	-scheme ${app_target_name} \
	-configuration ${app_build_config}\
	-archivePath ${build_path}/${app_target_name}.xcarchive \
	>> $log_path

	if [ $? = 0 ]; then
		echo -e "\033[32m************* 导出xcarchive文件 完成 **************\033[0m"
		echo -e ""
	else
		echo -e "\033[31m************* 导出xcarchive文件 失败 **************\033[0m"
		echo -e ""
	exit;
	fi
	
else
	workspace_name=${project_path}/${app_target_name}.xcodeproj


	############################## xcodebuild clean ##############################	
	xcodebuild clean -project ${app_target_name}.xcodeproj \
	-scheme ${app_target_name} \
	-configuration ${app_build_config} \
	>>$log_path

	if [ $? = 0 ]; then
		echo -e "\033[32m************* xcodebuild clean 完成 **************\033[0m"
		echo -e ""
	else
		echo -e "\033[31m************* xcodebuild clean 失败 **************\033[0m"
		echo -e ""
	exit;
	fi

	
	##############################xcodebuild 编译##############################
	xcodebuild -project ${workspace_name} \
	-scheme ${app_target_name} \
	-configuration ${app_build_config} \
	CONFIGURATION_BUILD_DIR=${build_path}/${app_direct_name}\
	>> $log_path

	if [ $? = 0 ]; then
		echo -e "\033[32m************* xcodebuild 编译 完成 **************\033[0m"
		echo -e ""
	else
		echo -e "\033[31m************* xcodebuild 编译 失败 **************\033[0m"
		echo -e ""
	exit;
	fi

	##############################导出xcarchive文件##############################
	xcodebuild archive -project ${workspace_name} \
	-scheme ${app_target_name} \
	-configuration ${app_build_config} \
	-archivePath ${build_path}/${app_target_name}.xcarchive \
	>> $log_path

	if [ $? = 0 ]; then
		echo -e "\033[32m************* 导出xcarchive文件 完成 **************\033[0m"
		echo -e ""
	else
		echo -e "\033[31m************* 导出xcarchive文件 失败 **************\033[0m"
		echo -e ""
	exit;
	fi
fi


##############################生成ExportOptionsPlist文件##############################
exportOptionsPlist=${xcodebuild_path}/ExportOptions.plist
cat << EOF > $exportOptionsPlist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>compileBitcode</key>
		<false/>
		<key>method</key>
		<string>$app_method</string>
		<key>signingStyle</key>
		<string>automatic</string>
		<key>teamID</key>
		<string>$app_team_ID</string>
	</dict>
</plist>
EOF

if [ $? = 0 ]; then
	echo -e "\033[32m************* 生成ExportOptionsPlist文件 成功 **************\033[0m"
else
	echo -e "\033[31m************* 生成ExportOptionsPlist文件 失败 **************\033[0m"
exit;
fi


##############################导出 ipa 文件##############################
xcodebuild -exportArchive -archivePath ${build_path}/${app_target_name}.xcarchive \
		   -exportPath ${archive_path} \
		   -exportOptionsPlist ${exportOptionsPlist} \
		   >> $log_path
if [ $? = 0 ]; then
	echo -e "\033[32m************* 导出 ipa 文件 完成 **************\033[0m"
	echo -e ""
else
	echo -e "\033[31m************* 导出 ipa 文件 失败 **************\033[0m"
	echo -e ""
exit;
fi
