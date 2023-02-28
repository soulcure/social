#!/bin/bash

# 参数1：文件URL 参数2：目标地址
download_file () {
    url=$1
    file_name=$2
    agent="Mozilla/5.0 (Windows NT 6.1) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.47 Safari/536.11Mozilla/5.0 (Windows NT 6.1) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.47 Safari/536.11"
    #file_name=`echo ${url} | awk -F '?' '{print $1}' | awk -F '/' '{print $NF}'`
    if [ ! -f ${file_name} ];then
        curl ${url} -A "${agent}" -o ${file_name} --progress-bar
    fi
}

download_and_replace_resource () {
    resource_url=$1
    resource_dir=$2
    file_name=$3
    download_file ${resource_url} ${file_name}
    if [ -f ${file_name} ]; then
      rm -rf ${resource_dir}
      unzip -o -d ${resource_dir} ${file_name}
      rm ${file_name}
    fi
}

# 下载ios文件
resource_ios_url="https://artifact-dl-devops.uu.cc/generic-local/bk-custom/buff/resouce/1.6.60/unity_ios_resource_1.6.60_2220.zip"
unity_export_ios="ios/unityExport"
file_name_ios="ios/unity_ios_resource.zip"
download_and_replace_resource ${resource_ios_url} ${unity_export_ios} ${file_name_ios}

# 下载android文件
resource_android_url="https://artifact-dl-devops.uu.cc/generic-local/bk-custom/buff/resouce/1.6.60/unity_android_resource_1.6.60_2220.zip"
unity_export_android="android/unityExport"
file_name_android="android/unity_android_resource.zip"
download_and_replace_resource ${resource_android_url} ${unity_export_android} ${file_name_android}