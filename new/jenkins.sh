#!/bin/bash
#--------------------------------------------------------------------------------
# 脚本说明：
# 1、实现功能：
#     1）、指定打包项目的Build号,Version版本号,Bundle Identifier,Display Name
#		  说明:
#			  -只有当配置此类信息之后才会回更新Info.plist中的信息
#			  -Build号如果没有配置,默认为打包时间,格式：年月日时分
#			  -Version版本号如果没有配置,默认自动递增1
#     2）、导出xcarchive文件
#		  说明:
#			  -路径:xcodebuild/201806030104/build/xxxx.xcarchive
#     3）、多target打包
#		  说明:
#			  -通过命令xcodebuild -list -json 截取字符获取project_name,targets,schemes,build_configurations
#			  -多target时提示选择target,单target时直接打包不选择
#			  -当配置了scheme和configuration就直接进行打包不选择性打包,否之就是多target选择
#     4）、打包生成ipa文件
#		  说明:
#			  -路径:xcodebuild/201806030104/archive/xxxx.ipa
#     5）、支持project和workspace打包
#		  说明:
#			  -根据根目录是否包含Podfile判断是否为project或workspace
#     6）、ipa上传至App Store,必须配置app_store_account和app_store_password
#		  说明:
#			  -只有当configuration=Release和upload_app=true时ipa才会上传到App Store
# 2、使用方式：
#     1）、将xcodebuild-shell文件，放到跟所要打包的项目的根目录同级别的目录下
#     2）、cd至xcodebuild-shell，运行脚本./xcodebuild-shell.sh
#     3）、完成打包后，生成的目标文件在如下目录：
#         xcodebuild 											        (打包相关资源的根目录)
#  				   |___201806030104								        (打包时间,格式：年月日时分)
#         						  |___archive 						    (导出的.ipa文件)
# 								  |___ExportOptions.plist 			    (脚本生成的ExportOptions文件)
#								  |___log 							    (打包日志)
# 								  |___build 							(编译路径)
#									      |___Debug/Release-iphoneos	(Debug或Release编译文件)
#			 						      |___xxxx.xcarchive			(导出的.xcarchive文件)
#
#
# 3、注意:
#     1）、本脚本签名必须为自动签名模式
#     2）、如果需要配置不同证书,不同账号的时候,必须关闭xcode的自动签名
#		  再添加如下参数
# 		  CODE_SIGN_IDENTITY="iPhone Developer: zhang heng (P89Z2CXVDZ)" 
# 		  PROVISIONING_PROFILE="XC Wildcard (Y4CQMPSC2J.*)"
# 		  PROVISIONING_PROFILE="342c8bbf-3ae1-463c-82a1-903c04b05ee9"
#--------------------------------------------------------------------------------


###############配置###############
app_store_account="" 						#App Store账号
app_store_password="" 						#App Store密码
scheme="KwaiUp" 							#打包的scheme
configuration=${APP_BUILD_CONFIG} 			#编译的方式,Release,Debug,Adhoc
app_display_name=${APP_NAME}				#应用的名字
app_bundle_identifier=""					#应用的Bundle ID
app_version=${APP_VERSION}					#应用的version号
app_build="" 								#应用的build号,默认为打包时间201806030104,格式：年月日时分
upload_app=${UPLOAD_TO_APPSTORE}			#是否上传App Store
app_online=$APP_ONLINE						#是否线上环境
app_review_time=$APP_REVIEW_TIME            #审核到期时间
#################################




###############定义变量###############
current_date=`date +%Y%m%d%H%M`
project_path=$WORKSPACE
xcodebuild_path="${JENKINS_HOME}/workspace/apks/iOS/${app_uaid}/${BUILD_DATE}/${BUILD_TIME}/"
build_path="${xcodebuild_path}/build"
archive_path="${xcodebuild_path}/archive"
exportOptions_plist=${xcodebuild_path}/ExportOptions.plist
for file_name in `ls`;
do
if [[ ${file_name} == "Podfile" ]]; then
	cocoapods_contain=true
	break
else
	cocoapods_contain=false
fi
done
###############定义方法###############
#创建文件夹
function create_directory()
{
	if [[ ! -d "$xcodebuild_path" ]];then
		mkdir -p "$xcodebuild_path"
	fi
	if [[ ! -d "$build_path" ]]; then
		mkdir -p "$build_path"
	fi
	if [[ ! -d "$archive_path" ]]; then
		mkdir -p "$archive_path" 
	fi
}
#修改plist信息
function plistbuddy_modify_information()
{
	app_jenkins_conifg_path="${project_path}/${scheme}/jenkins-config.plist"

	target_infoplist_path="${project_path}/${scheme}/Info.plist"
	# 获取默认display name值
	app_display_name_default=$(/usr/libexec/PlistBuddy -c "print CFBundleDisplayName " ${target_infoplist_path})
	# 获取默认bundle identifier
	app_bundle_identifier_default=$(/usr/libexec/PlistBuddy -c "print CFBundleIdentifier " ${target_infoplist_path})
	# 获取默认version值
	app_version_default=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" ${target_infoplist_path})
	# 获取默认build值
	app_build_default=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${target_infoplist_path})


	if [[ $app_display_name ]]; then
		/usr/libexec/Plistbuddy -c "Set CFBundleDisplayName $app_display_name" "${target_infoplist_path}"
	fi


	if [[ $app_bundle_identifier ]]; then
		/usr/libexec/Plistbuddy -c "Set CFBundleIdentifier $app_bundle_identifier" "${target_infoplist_path}"
	fi


	if [[ $app_version ]]; then
		/usr/libexec/Plistbuddy -c "Set CFBundleShortVersionString $app_version" "${target_infoplist_path}"
	else
		version_number=`echo $app_version_default | sed 's/\.*//g'`
		num=$(($version_number +1)) 
		app_version=`echo $num | sed 's/./&\./g'| sed 's/.$//'`
		/usr/libexec/Plistbuddy -c "Set CFBundleShortVersionString $app_version" "${target_infoplist_path}"
	fi


	if [[ $app_build ]]; then
		/usr/libexec/Plistbuddy -c "Set CFBundleVersion $app_build" "${target_infoplist_path}"
	else
		/usr/libexec/Plistbuddy -c "Set CFBundleVersion $current_date" "${target_infoplist_path}"
	fi


	/usr/libexec/Plistbuddy -c "Set jenkins_on_line $app_online" "${app_jenkins_conifg_path}"

	/usr/libexec/Plistbuddy -c "Set jenkins_review_time $app_review_time" "${app_jenkins_conifg_path}"

	# 获取display name值
	app_display_name_last=$(/usr/libexec/PlistBuddy -c "print CFBundleDisplayName " ${target_infoplist_path})
	# 获取bundle identifier
	app_bundle_identifier_last=$(/usr/libexec/PlistBuddy -c "print CFBundleIdentifier " ${target_infoplist_path})
	# 获取version值
	app_version_last=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" ${target_infoplist_path})
	# 获取build值
	app_build_last=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${target_infoplist_path})
	# 获取jinkins配置线上或线下值
	app_on_line_last=$(/usr/libexec/PlistBuddy -c "print jenkins_on_line" ${app_jenkins_conifg_path})
	# 获取jinkins配置审核时间值
	app_review_time_last=$(/usr/libexec/PlistBuddy -c "print jenkins_review_time" ${app_jenkins_conifg_path})

}
#获取xcodebuild_list信息.通过截取字符串或得project_name,targets,schemes,build_configurations
function xcodebuild_list()
{
	#获取工程名字xcodebuild_list_info 去除全部逗号,引号
	xcodebuild_list_info=`xcodebuild -list -json | sed 's/\"*\,*//g'`

	#获取工程名字
	project_name_str=${xcodebuild_list_info##*"name :"}
	project_name_space=${project_name_str%%"}"*}
	project_name=`echo $project_name_space | sed 's/ //g'`

	#获取全部targets
	targets_str=${xcodebuild_list_info##*"targets : ["}
	targets=${targets_str%%"]"*}
	targets_arr=($targets)

	#获取全部schemes
	scheme_str=${xcodebuild_list_info##*"schemes : ["}
	schemes=${scheme_str%%"]"*}
	scheme_arr=($schemes)

	#获取全部build_configurations  然后再添加Adhoc
	build_configurations_str=${xcodebuild_list_info##*"configurations : ["}
	build_configurations="${build_configurations_str%%"]"*} Adhoc"
	build_configurations_arr=($build_configurations)
}
#选择打包配置
function xcodebuild_config_input()
{
	targets_num=${#targets_arr[@]}
	schemes_num=${#scheme_arr[@]}
	build_configurations_num=${#build_configurations_arr[@]}
	if [[ ${targets_num} = 1 && ${schemes_num} = 1 ]]; then
		#targets和scheme只有一个时直接取target和scheme
		target=${targets_arr[0]}
		scheme=${scheme_arr[0]}
	else
		echo -e "\033[36m=== 请选择 app scheme ===\033[0m" 
		for((i=0; i<${#scheme_arr[@]}; i++))  
		do  
    	scheme=${scheme_arr[${i}]}
    	echo -e	"\033[36m$(($i+1)) $scheme \033[0m"
		done  
		#输入选择打包scheme
		while : 
		do
			read -p "请选择你需要打包的scheme:" selcted_scheme
			if [[ ${selcted_scheme}>${schemes_num} || ${selcted_scheme} <1 ]]; then
				echo -e	"\033[31m--------------------------\033[0m"
				echo -e	"\033[31m你的输入错误... \033[0m"
				echo -e	"\033[31m--------------------------\033[0m"
			else
				break
			fi
		done
		target=${targets_arr[$(($selcted_scheme-1))]}
		scheme=${scheme_arr[$(($selcted_scheme-1))]}
	fi

	echo -e "\033[36m=== 请选择 app build configuration ===\033[0m"
	for((i=0; i<${build_configurations_num}; i++))  
	do  
    	build_configuration=${build_configurations_arr[${i}]}
    	echo -e	"\033[36m$(($i+1)) $build_configuration \033[0m"
	done

	#输入选择打包方式
	while : 
	do
		read -p "请选择你需要打包的configuration:" selcted_configuration
		if [[ ${selcted_configuration}>${build_configurations_num} || ${selcted_configuration} <1 ]]; then
			echo -e	"\033[31m--------------------------\033[0m"
			echo -e	"\033[31m你的输入错误... \033[0m"
			echo -e	"\033[31m--------------------------\033[0m"
		else
			break
		fi
	done
	configuration=${build_configurations_arr[$(($selcted_configuration-1))]}
}
#打包project项目
function xcodebuild_project()
{
	echo -e	"\033[36m=== BUILD TARGET ${scheme} OF PROJECT ${project_name} WITH CONFIGURATION ${configuration} ===\033[0m"
	echo -e	"\033[36m=== 打包中...\033[0m"
	xcodebuild clean -project "${project_name}.xcodeproj" -scheme "${scheme}" -configuration "${configuration}"

	xcodebuild -project "${project_name}.xcodeproj" -scheme "${scheme}" -configuration "${configuration}" CONFIGURATION_BUILD_DIR="${build_path}/${build_direct_name}" 

	xcodebuild archive -project "${project_name}.xcodeproj" -scheme "${scheme}" -configuration "${configuration}" -archivePath "${build_path}/${scheme}.xcarchive"

	xcodebuild_exportOptions_plist

	xcodebuild -exportArchive -archivePath "${build_path}/${scheme}.xcarchive" -exportPath "${archive_path}" -exportOptionsPlist "${exportOptions_plist}" 
}
 #打包workspace项目
function xcodebuild_workspace()
{
	
	xcodebuild clean -workspace "${project_name}.xcworkspace" -scheme "${scheme}" -configuration "${configuration}" 

	xcodebuild -workspace "${project_name}.xcworkspace" -scheme "${scheme}" -configuration "${configuration}" CONFIGURATION_BUILD_DIR="${build_path}/${build_direct_name}" 

	xcodebuild archive -workspace "${project_name}.xcworkspace" -scheme "${scheme}" -configuration "${configuration}" -archivePath "${build_path}/${scheme}.xcarchive" 

	xcodebuild_exportOptions_plist

	xcodebuild -exportArchive -archivePath "${build_path}/${scheme}.xcarchive" -exportPath "${archive_path}" -exportOptionsPlist "${exportOptions_plist}" 
}	
#创建exportOptions.plist文件
function xcodebuild_exportOptions_plist()
{
	if [[ ${configuration} = "Debug" ]]; then
		app_method="development"
	elif [[ ${configuration} = "Release" ]]; then
		app_method="app-store"
	elif [[ ${configuration} = "Adhoc"  ]]; then
		app_method="ad-hoc"
	else
		app_method="enterprise"
	fi
cat << EOF > $exportOptions_plist
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
</dict>
</plist>
EOF
}
#上传包体到App Store
function upload_ipa_to_app_store
{
	echo -e	"\033[36m=== Upload Ipa ${scheme}.ipa To App Store ===\033[0m"
	if [[ ! ${app_store_account} || ! ${app_store_password} ]]; then
		echo -e "\033[31m=== 没有App Store账户信息 请配置\033[0m"
		exit
	fi 
	altool_path="/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"
	echo -e	"\033[36m=== validate app from app store account\033[0m"
	"${altool_path}" --validate-app -f ${archive_path}/${scheme}.ipa -u ${app_store_account} -p ${app_store_password} -t ios 
	
	echo -e	"\033[36m=== uploading... \033[0m"
	"${altool_path}" --upload-app -f ${archive_path}/${scheme}.ipa -u ${app_store_account} -p ${app_store_password} -t ios 
	
}
###############脚本开始执行###############
create_directory
xcodebuild_list
if [[ ! $configuration || ! $scheme ]]; then
	xcodebuild_config_input
fi
plistbuddy_modify_information
if [[ ${configuration} = "Debug" ]]; then
	build_direct_name="Debug-iphoneos"
else
	build_direct_name="Release-iphoneos"
fi



echo -e	"\033[36m=== BUILD TARGET ${scheme} OF PROJECT ${project_name} WITH CONFIGURATION ${configuration} ===\033[0m"
echo -e	"\033[36m=== app_display_name:${app_display_name_last} \033[0m"
echo -e	"\033[36m=== app_bundle_identifier:${app_bundle_identifier_last} \033[0m"
echo -e	"\033[36m=== app_version:${app_version_last} \033[0m"
echo -e	"\033[36m=== app_build:${app_build_last} \033[0m"
echo -e	"\033[36m=== app_online:${app_on_line_last} \033[0m"
echo -e	"\033[36m=== app_review_time:${app_review_time_last} \033[0m"


echo -e	"\033[36m=== 打包中...\033[0m"
if $cocoapods_contain; then
	export LANG=en_US.UTF-8
	export LANGUAGE=en_US.UTF-8
 	export LC_ALL=en_US.UTF-8
	pod install --verbose --no-repo-update 
	xcodebuild_workspace
else
	xcodebuild_project
fi
if [ $? = 0 ]; then
	echo -e "\033[36m=== 打包 完成 ===\033[0m"
	echo -e "\033[36m=== ${archive_path}\033[0m"
else
	echo -e "\033[31m=== 打包 失败 ===\033[0m"
	exit
fi




if [[ ${configuration} == "Release" && ${upload_app} == true ]]; then
	upload_ipa_to_app_store
	if [ $? = 0 ]; then
		echo -e "\033[36m=== 上传ipa 到 App Store 完成 ===\033[0m"
	else
		echo -e "\033[31m=== 上传ipa 到 App Store 失败 ===\033[0m"
		exit
	fi
fi

