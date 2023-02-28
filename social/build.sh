echo '开始构建项目...'

appPath="build/ios/iphoneos/Runner.app"
ipaPath="ios/build/ios.ipa"
payloadPath="build/ios/iphoneos/Payload"
zipPath="build/ios/iphoneos/Payload.zip"
dateTime=`date +%Y%m%d-%T`
apkPath="build/app/outputs/apk/release/app-release.apk"

outPutPath="build/all/$dateTime"

if [ ! -d "build/all" ]; then 
  mkdir "build/all"
fi 
if [ ! -d "$outPutPath" ]; then 
  mkdir "$outPutPath"
fi 

#开始打包iOS
echo '🍺🍺🍺🍺===打包iOS===🍺🍺🍺🍺'

# 判断文件是否存在
echo '正在清除原文件'
if [ -d "$appPath" ]; then 
  rm -r "$appPath"
fi 
if [ -d "$ipaPath" ]; then 
  rm -r "$ipaPath"
fi
if [ -d "$zipPath" ]; then 
  rm -r "$zipPath"
fi
if [ -d "$payloadPath" ]; then 
  rm -r "$payloadPath"
fi

# iOS打包
if [[ "$1" == "dev" ]]; then
  echo '开发环境开始打包'
  flutter build ios -t lib/main.dart --release
elif [[ "$1" == "test" ]]; then
  echo '测试环境开始打包'
  flutter build ios -t lib/main.dart --release
else
  echo '生产环境开始打包'
  flutter build ios --release
fi

if [ -d "$appPath" ]; then
  echo 'build ios 成功'
  echo '正在生成ipa包'
   cd 'ios'
   fastlane make
   if [ -f "build/ios.ipa" ]; then
     mv "build/ios.ipa" "../$outPutPath/Buff-$dateTime.ipa"
     echo "生成ipa成功 路径:../$outPutPath"
   else
     echo '生成ipa失败'
   fi
   cd ..
else
  echo '打包失败'
fi

# 清空iOS缓存
rm -rf "ios/build"

echo '🍺🍺🍺🍺===打包android===🍺🍺🍺🍺'
# 判断文件是否存在
echo '正在清除原文件'
if [ -f "$apkPath" ]; then 
  rm "$apkPath"
fi

# 安卓打包

if [[ "$1" == "dev" ]]; then
  echo '开发环境开始打包'
  flutter build apk -t lib/main.dart --target-platform=android-arm64
elif [[ "$1" == "test" ]]; then
  echo '测试环境开始打包'
  flutter build apk -t lib/main.dart --target-platform=android-arm64
else
  echo '生产环境开始打包'
  flutter build apk --target-platform=android-arm64
fi
 
if [ -f "$apkPath" ]; then 
  echo 'build akp 成功'
  mv "$apkPath" "$outPutPath/Buff-[$dateTime].apk"
else
  echo 'apk 打包失败'
fi 

open "$outPutPath"
echo "\033[36;1m打包总用时: ${SECONDS}s \033[0m"




echo '构建成功'
