#!/bin/bash




# function xcodebuild_xcodeproj()
# {
# 	echo "123";
# }
# function xcodebuild_xcworkspace()
# {
# 	echo $1
# 	echo $2
# 	echo $3
# 	echo $4
# }
# 打印错误信息
function exitWithMessage(){
    echo -e "--------------------------------"
    echo "${1}"
    echo -e "--------------------------------"
    exit ${2}
}
# xcodebuild_xcworkspace "15615" "2" "3" "4" "5"
# 
# echo -e "\033[32m************* 导出 ipa 文件 完成 **************\033[0m"
# echo -n "Enter your name:"                   # 参数-n的作用是不换行，echo默认换行
# read  name                                   # 把键盘输入放入变量name
# echo "hello $name,welcome to my program"     # 显示输入信息
# exitWithMessage "nonini" 0
# echo -e "\033[32m************* 选择打包方式 **************\033[0m"
# echo -e	"\033[32m* 1 release (默认)\033[0m"
# echo -e	"\033[32m* 2 ad-hoc\033[0m"
# echo -e	"\033[32m* 3 debug\033[0m"



function xcodebuild_list_targets
{
	targets_str=${xcodebuild_list_info##*"targets : ["}
	targets=${targets_str%%"]"*}
	targets_arr=($targets)
	echo -e "\033[32m************* 请选择target **************\033[0m"
	#遍历数组  
	for((i=0; i<${#targets_arr[@]}; i++))  
	do  
    	target=${targets_arr[${i}]}
    	echo -e	"\033[32m* $(($i+1)).$target \033[0m"
	done  
}

function xcodebuild_list_schemes
{
	scheme_str=${xcodebuild_list_info##*"schemes : ["}
	schemes=${scheme_str%%"]"*}
	scheme_arr=($schemes)
	echo -e "\033[32m************* 请选择scheme **************\033[0m"
	#遍历数组  
	for((i=0; i<${#scheme_arr[@]}; i++))  
	do  
    	scheme=${scheme_arr[${i}]}
    	echo -e	"\033[32m* $(($i+1)).$scheme \033[0m"
	done  
}

function xcodebuild_list_build_configurations
{
	build_configurations_str=${xcodebuild_list_info##*"configurations : ["}
	build_configurations="${build_configurations_str%%"]"*} Adhoc"
	build_configurations_arr=($build_configurations)
	echo -e "\033[32m************* 请选择configuration **************\033[0m"
	for((i=0; i<${#build_configurations_arr[@]}; i++))  
	do  
    	build_configuration=${build_configurations_arr[${i}]}
    	echo -e	"\033[32m* $(($i+1)).$build_configuration \033[0m"
	done  
}

function xcodebuild_list_project_name
{
	project_name_str=${xcodebuild_list_info##*"name :"}
	project_name_space=${project_name_str%%"}"*}
	project_name=`echo $project_name_space | sed 's/ //g'`
}


xcodebuild_list_info=`xcodebuild -list -json | sed 's/\"*\,*//g'`
xcodebuild_list_project_name

targets_arr=()
xcodebuild_list_targets
read -p "请选择你需要打包的target:" selcted_target
targets_num=${#targets_arr[@]}
if [[ ${selcted_target}>${targets_num} || ${selcted_target} <1 ]]; then
	exitWithMessage "输入错误"
fi
target=${targets_arr[$(($selcted_target-1))]}


scheme_arr=()
xcodebuild_list_schemes
read -p "请选择你需要打包的scheme:" selcted_scheme
schemes_num=${#scheme_arr[@]}
if [[ ${selcted_scheme}>${schemes_num} || ${selcted_scheme} <1 ]]; then
	exitWithMessage "输入错误..."
fi
scheme=${scheme_arr[$(($selcted_scheme-1))]}


build_configurations_arr=()
xcodebuild_list_build_configurations
read -p "请选择你需要打包的configuration:" selcted_configuration
build_configurations_num=${#build_configurations_arr[@]}
if [[ ${selcted_configuration}>${build_configurations_num} || ${selcted_configuration} <1 ]]; then
	exitWithMessage "输入错误..."
fi
configuration=${build_configurations_arr[$(($selcted_configuration-1))]}


echo -e	"\033[31m project_name:${project_name} \033[0m"
echo -e	"\033[31m target:${target} \033[0m"
echo -e	"\033[31m configuration:${configuration} \033[0m"
echo -e	"\033[31m scheme:${scheme} \033[0m"
read -p "请确认信息是否正确 (y/n)" correct
if [[ $correct!=y || $correct!=n ]]; then
	exitWithMessage "输入错误..."
fi

