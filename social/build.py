#!/usr/bin/python3
import json
import os
import qrcode
import re
import requests
import shutil
import subprocess
import sys
import time

print(sys.argv)
env = sys.argv[1]
version = sys.argv[2]
build_number = sys.argv[3]
branch = sys.argv[4]
groupName = sys.argv[5]
isBuildChannel = sys.argv[6]
flutterSdk = sys.argv[7]

# flutter build path
appPath = "build/ios/iphoneos/Runner.app"
buffPath = "build/ios/iphoneos/Buff.app"
apkPath = "build/app/outputs/flutter-apk/app-android-release.apk"
dateTime = time.strftime("%Y-%m-%d_%H:%M:%S")
outPutPath = "build/all/" + dateTime
destAppPath = f"{outPutPath}/Buff-{dateTime}.ipa"
destApkPath = f"{outPutPath}/Buff-{dateTime}.apk"

webPath = "/Users/ci/Desktop/package"
httpsUrl = "https://192.168.112.40:8001"
httpUrl = "http://192.168.112.40:8000"
logDay = 5

# 飞书 token
feishu_token = ''

def negation_bool(b):
    b = bool(1 - b)
    return b

# 去掉armv7 symbol files 解决问题：ITMS-90381: Too many symbol files
def fixPodFileSetting():
    os.system('fvm flutter pub get') # 先初始化podfile
    file = open("ios/Podfile", "r+")
    podFileContent = file.read()
    #
    index = podFileContent.find('target.build_configurations.each')
    if index == -1 :
        offset = podFileContent.find('flutter_additional_ios_build_settings(target)') + len('flutter_additional_ios_build_settings(target)')
        endStr = podFileContent[offset:len(podFileContent)]
        file.seek(offset)
        setting = """\n      target.build_configurations.each do |config|
        config.build_settings['ENABLE_BITCODE'] = 'NO'
        config.build_settings['ARCHS'] = 'arm64'
    end"""
        file.write(setting)
        file.write(endStr)
    file.close()

# 修改版本号
def change_yaml_version():
    print('修改版本号')
    file = open("pubspec.yaml", "r")
    content = file.read()
    file.close()
    # 处理数据
    arr = content.split()
    index = arr.index('version:')
    currentVersion = arr[index+1]
    content = content.replace(currentVersion,f'{version}+{build_number}',1)
    # 修改数据
    file = open("pubspec.yaml", "w")
    file.write(content)
    file.close()

# 清除缓存
def clear_cache():
    print('清除缓存')
    os.system('rm ios/Flutter/Flutter.podspec')
    os.system('fvm flutter clean')
    if os.path.exists(appPath):
        shutil.rmtree(appPath)
    if os.path.exists(apkPath):
        os.unlink(apkPath)

# 初始化
def init():
    print('初始化')
    if negation_bool(os.path.exists("build")) :
        os.mkdir("build")
    if negation_bool(os.path.exists("build/all")) :
        os.mkdir("build/all")
    os.mkdir(outPutPath)
    destWebPath = f"{webPath}/{dateTime}"
    if negation_bool(os.path.exists(destWebPath)):
        os.mkdir(destWebPath)

# build iOS
def buildIOS():
    print('🍺🍺🍺🍺===iOS开始打包===🍺🍺🍺🍺')
    # os.system('pod repo update');
    # if env == 'dev':
    #     print('开发环境开始打包')
    #     os.system('flutter build ios -t lib/main_dev.dart --release')
    # elif env == 'test':
    #     print('测试环境开始打包')
    #     os.system('flutter build ios -t lib/main_test.dart --release')
    # else:
    #     print('生产环境开始打包')
    #     os.system('flutter build ios -t lib/main_prod.dart --release')

    os.system('fvm flutter build ios -t lib/main_dog.dart --release')
    if os.path.exists(appPath) or os.path.exists(buffPath) :
        print('fvm flutter build ios success')
        os.chdir('ios')
        os.system('fastlane make')
        if os.path.exists("build/ios.ipa"):
            shutil.move("build/ios.ipa",f"../{destAppPath}")
        else:
            print('生成ipa失败')
        os.chdir('..')
    else:
        print('打包失败')

    # 清空fastlane缓存
    if os.path.exists("ios/build"):
        shutil.rmtree("ios/build")

def buildAndroid():
    print('🍺🍺🍺🍺===android开始打包===🍺🍺🍺🍺')
    # if env == 'dev':
    #     print('开发环境开始打包')
    #     os.system('flutter build apk -t lib/main_dev.dart --target-platform=android-arm64 --flavor android --release')
    # elif env == 'test':
    #     print('测试环境开始打包')
    #     os.system('flutter build apk -t lib/main_test.dart --target-platform=android-arm64 --flavor android --release')
    # else:
    #     print('生产环境开始打包')
    #     os.system('flutter build apk -t lib/main_prod.dart --target-platform=android-arm64 --flavor android --release')
    os.system('fvm flutter build apk -t lib/main_dog.dart --flavor android --target-platform=android-arm64 --release')

    if os.path.exists(apkPath):
        print('apk 打包成功')
        shutil.move(apkPath,destApkPath)
    else:
        print('apk 打包失败')

# 获取飞书的token
def getToken():
    global feishu_token
    if len(feishu_token) > 0:
        return feishu_token
    tokenRes = requests.post("https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal/",
                             data=json.dumps({'app_id': "cli_9e62c8e53639100d", "app_secret": "xPM1CNYeqoDsXfDLFNvXygWZ58UYaiqL"}),
                             headers={"Content-Type": "application/json"})
    if tokenRes.status_code != 200 or tokenRes.json()['code'] != 0:
        feishu_token = ''
        return feishu_token
    feishu_token = tokenRes.json()['tenant_access_token']
    return feishu_token

# 上传图片到飞书
def uploadImage(image_path):
    # 获取 token
    token = getToken()
    if len(token) == 0:
        return ''
    token = f'Bearer {token}'
    with open(image_path, 'rb') as f:
        image = f.read()
    resp = requests.post(
        url='https://open.feishu.cn/open-apis/image/v4/put/',
        headers={'Authorization': token},
        files={
            "image": image
        },
        data={
            "image_type": "message"
        },
        stream=True)
    resp.raise_for_status()
    content = resp.json()
    print(content)
    if content.get("code") == 0:
        data = content['data']
        image_key = data['image_key']
        return image_key
    else:
        raise Exception("Call Api Error, errorCode is %s" % content["code"])

# 发生文本信息
def sendMessage(content) :
    # 获取 token
    token = getToken()
    if len(token) == 0:
        return ''
    # 获取群列表
    token = f'Bearer {token}'
    listRes = requests.get('https://open.feishu.cn/open-apis/chat/v4/list?page_size=100',
                           headers={"Authorization": token})
    if listRes.status_code != 200 or listRes.json()['code'] != 0:
        return
    # 发送消息
    data = listRes.json()['data']
    groups = data['groups']
    for group in groups:
        if groupName != "" and groupName != group['name'] :
            continue
        chatId = group['chat_id']
        sendRes = requests.post("https://open.feishu.cn/open-apis/message/v4/send/",
                                data=json.dumps({'chat_id': chatId, "msg_type": "text", "content": {"text": content}}),
                                headers={"Content-Type": "application/json","Authorization": token})
        if sendRes.status_code != 200 or sendRes.json()['code'] != 0:
            print('飞书消息发送失败')

# 发生富文本信息
def sendSuccessMessage(title,content,appUrl,appDevelopmentUrl,apkUrl,appImageKey,apkImageKey,log) :
    # 获取 token
    token = getToken()
    if len(token) == 0:
        return ''
    # 获取群列表
    token = f'Bearer {token}'
    listRes = requests.get('https://open.feishu.cn/open-apis/chat/v4/list?page_size=100',
                           headers={"Authorization": token})
    if listRes.status_code != 200 or listRes.json()['code'] != 0:
        return
    # 发送消息
    data = listRes.json()['data']
    groups = data['groups']
    for group in groups:
        if group['name'] != 'Social':
            if groupName != "" and groupName != group['name'] :
                continue
            chatId = group['chat_id']
            sendRes = requests.post("https://open.feishu.cn/open-apis/message/v4/send/",
                                    data=json.dumps(
                                        {
                                            'chat_id': chatId,
                                            "msg_type": "post",
                                            "content": {
                                                "post": {
                                                    "zh_cn": {
                                                        "title": title,
                                                        "content": [
                                                            [{"tag": "text", "text":content}],
                                                            [{"tag": "text", "text":'iOS:'},{"tag": "a","text": "安装地址","href": appUrl},],
                                                            [{"tag": "text", "text":'iOS包:'},{"tag": "a","text": "下载地址","href": appDevelopmentUrl}],
                                                            [{"tag":"img","image_key":appImageKey}],
                                                            [{"tag": "text", "text":'android:'},{"tag": "a","text": "下载地址","href": apkUrl}],
                                                            [{"tag":"img","image_key":apkImageKey}],
                                                            [{"tag": "text", "text": "日志:\n" + log }]
                                                        ]
                                                    }
                                                }
                                            }
                                        }),
                                    headers={"Content-Type": "application/json","Authorization": token})
            if sendRes.status_code != 200 or sendRes.json()['code'] != 0:
                print('飞书消息发送失败')
            print(sendRes.json())

def writeIpaHtml():
    content = f"""<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <title>buff</title>
        </head>
        <body>
            <h1 style="font-size:80pt">如果点击无法下载安装，请复制超链接到浏览器中打开<h1/>
            <h1 style="font-size:100pt">
                <a title="iPhone" href="itms-services://?action=download-manifest&url={httpsUrl}/{dateTime}/ipa.plist">Iphone Download</a>
            <h1/>
        </body>
    </html>"""
    file = open(f"{webPath}/{dateTime}/ipa.html", "w")
    file.write(content)
    file.close()

def writeIpaPlist():
    content = f"""<?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>items</key>
        <array>
            <dict>
                <key>assets</key>
                <array>
                    <dict>
                        <key>kind</key>
                        <string>software-package</string>
                        <key>url</key>
                        <string>{httpsUrl}/{dateTime}/Buff-{dateTime}.ipa</string>
                    </dict>
                </array>
                <key>metadata</key>
                <dict>
                    <key>bundle-identifier</key>
                    <string>com.idreamsky.buff</string>
                    <key>bundle-version</key>
                    <string>{version}</string>
                    <key>kind</key>
                    <string>software</string>
                    <key>title</key>
                    <string>buff</string>
                </dict>
            </dict>
        </array>
    </dict>
    </plist>"""
    file = open(f"{webPath}/{dateTime}/ipa.plist", "w")
    file.write(content)
    file.close()

def filterList(value):
    return negation_bool(value.startswith('Merge') or value.startswith('合并分支') or len(value) < 5)

def getLastCommit():
    if os.path.exists("log.txt"):
        file = open("log.txt", "r")
        content = file.readline()
        file.close()
        logRes = content.split(' | ')
        if len(logRes) >= 2 and re.match(r'^\w+$', logRes[0]):
            return logRes[0]
        else:
            return None
    else:
        return None

def getLog():
    logTypes = {}
    lastCommit = getLastCommit()
    print('lastCommit：', lastCommit)
    query = [
        'git',
        'log',
        '--since=5 days ago',
        '--no-merges',
        '--pretty=format:%H | %ci | %s | [%an]'
    ]
    if lastCommit is not None:
        query = [
            'git',
            'log',
            lastCommit + '..HEAD',
            '--no-merges',
            '--pretty=format:%H | %ci | %s | [%an]'
        ]
    data_string = subprocess.check_output(query).decode()
    file = open("log.txt", "w+")
    file.write(data_string)
    for log in data_string.split('\n'):
        logRes = log.split(' | ', 3)
        if len(logRes) < 2:
            continue
        log = logRes[2]
        splitRes = log.split(':')
        if len(splitRes) < 2:
            continue
        logType = splitRes[0]
        logText = splitRes[1]
        logType = logType if not logType.startswith('fix') else 'fix'
        logs = logTypes.get(logType)
        if logs is None:
            logTypes.update({logType: [logText]})
        else:
            logs.append(logText)
    tempList = []
    for (k, v) in logTypes.items():
        tempList.extend([k])
        tempList.extend(v)

    return '(nothing update)' if len(tempList) == 0 else '\n'.join(tempList)


def uploadApp():
    if os.path.exists(destAppPath) and os.path.exists(destApkPath) :
        # sendMessage('构建成功')
        # /Users/lionel.hong/Desktop/node/web/public
        destWebPath = f"{webPath}/{dateTime}"
        shutil.move(destAppPath,destWebPath)
        shutil.move(destApkPath,destWebPath)
        writeIpaHtml()
        writeIpaPlist()

        # 生成二维码 和 上传图片
        appUrl = f'{httpUrl}/{dateTime}/ipa.html'
        ipaUrl = f'{httpUrl}/{dateTime}/Buff-{dateTime}.ipa'
        apkUrl = f'{httpUrl}/{dateTime}/Buff-{dateTime}.apk'
        img = qrcode.make(data=appUrl)
        img.save('app.jpg')
        img = qrcode.make(data=apkUrl)
        img.save('apk.jpg')
        appUrlKey = uploadImage("app.jpg")
        apkUrlKey = uploadImage("apk.jpg")
        log = getLog()

        content = f"""构建分支: {branch}
版本号: {version}+{build_number}"""
        # 构建的环境: {env}
        # 安卓包下载地址: {serverBaseUrl}/{dateTime}/Buff-{dateTime}.apk
        # iOS包下载地址: {serverBaseUrl}/{dateTime}/ipa.html
        sendSuccessMessage('🍺🍺🍺构建成功🍺🍺🍺',content,appUrl,ipaUrl,apkUrl,appUrlKey,apkUrlKey,log)
    else:
        sendMessage('💣💣💣构建失败💣💣💣')

def blue():
    if groupName != "权限大作战":
        return
    ipaUrl = f'{httpUrl}/{dateTime}/Buff-{dateTime}.ipa'
    url='https://devops.uu.cc:443/ms/process/api/external/pipelines/719eec7da980474787400c08c1321680/build'
    v = f'{version}+{build_number}'
    data = {
        "dldir": ipaUrl,
        "version": v,
        'branch': branch, 
        'flutterSdk': flutterSdk,
        'isBuildChannel': isBuildChannel
    }
    requests.post(url, json=data)

def updateApkDownloadUrl():
    apkUrl = f'{httpUrl}/{dateTime}/Buff-{dateTime}.apk'
    data = {
        'version': version,
        'build_number': build_number,
        'branch': branch,
        'url': apkUrl
    }
    json_str = json.dumps(data)
    file = open(f"{webPath}/api/url.json", "w")
    file.write(json_str)
    file.close()
    # 调研测试远程脚本
    os.system("curl -X POST https://devops.uu.cc:443/ms/process/api/external/pipelines/eee4668ccb964529aea54ec32e9b0548/build -H \"Content-Type: application/json\" -d \"{}\"");


def buildChannelApk():
    # 构建32位包
    os.system('fvm flutter build apk --flavor android --release')
    path = 'build/app/outputs/flutter-apk/app-android-release.apk'
    destWebPath = f"{webPath}/{dateTime}/Buff-android-32.apk"
    if os.path.exists(path):
        shutil.move(path,destWebPath)
    else:
        print('apk 打包失败')
    # 构建渠道包
    channels = ['android','OP0S0N00666', 'BG0S0N00666', 'HW0S0N00666', 'MZ0S0N00666' ,'XM0S0N00662', 'TX0S0N70666']
    for channel in channels:
        os.system(f'fvm flutter build apk --flavor {channel} --release')
        path = f'build/app/outputs/flutter-apk/app-{channel}-release.apk'
        destWebPath = f"{webPath}/{dateTime}/Buff-{channel}.apk"
        if os.path.exists(path):
            shutil.move(path,destWebPath)
        else:
            print('apk 打包失败')


# 发渠道包消息
def sendChannelApkMessage() :
    # 获取 token
    token = getToken()
    if len(token) == 0:
        return ''
    # 获取群列表
    token = f'Bearer {token}'
    listRes = requests.get('https://open.feishu.cn/open-apis/chat/v4/list?page_size=100',
                           headers={"Authorization": token})
    if listRes.status_code != 200 or listRes.json()['code'] != 0:
        return

    content = f"""构建分支: {branch}
版本号: {version}+{build_number}"""

    # 发送消息
    data = listRes.json()['data']
    groups = data['groups']
    for group in groups:
        if group['name'] != 'Social':
            if groupName != "" and groupName != group['name'] :
                continue
            chatId = group['chat_id']
            sendRes = requests.post("https://open.feishu.cn/open-apis/message/v4/send/",
                                    data=json.dumps(
                                        {
                                            'chat_id': chatId,
                                            "msg_type": "post",
                                            "content": {
                                                "post": {
                                                    "zh_cn": {
                                                        "title": "渠道包",
                                                        "content": [
                                                            [{"tag": "text", "text":content}],
                                                            [{"tag": "text", "text":'模拟器+32位包:'},{"tag": "a","text": "下载地址","href": f'{httpUrl}/{dateTime}/Buff-android-32.apk'},],
                                                            [{"tag": "text", "text":'官网:'},{"tag": "a","text": "下载地址","href": f'{httpUrl}/{dateTime}/Buff-android.apk'},],
                                                            [{"tag": "text", "text":'oppo:'},{"tag": "a","text": "下载地址","href": f'{httpUrl}/{dateTime}/Buff-OP0S0N00666.apk'},],
                                                            [{"tag": "text", "text":'步步高:'},{"tag": "a","text": "下载地址","href": f'{httpUrl}/{dateTime}/Buff-BG0S0N00666.apk'},],
                                                            [{"tag": "text", "text":'华为:'},{"tag": "a","text": "下载地址","href": f'{httpUrl}/{dateTime}/Buff-HW0S0N00666.apk'},],
                                                            [{"tag": "text", "text":'魅族:'},{"tag": "a","text": "下载地址","href": f'{httpUrl}/{dateTime}/Buff-MZ0S0N00666.apk'},],
                                                            [{"tag": "text", "text":'小米:'},{"tag": "a","text": "下载地址","href": f'{httpUrl}/{dateTime}/Buff-XM0S0N00662.apk'},],
                                                            [{"tag": "text", "text":'腾讯:'},{"tag": "a","text": "下载地址","href": f'{httpUrl}/{dateTime}/Buff-TX0S0N70666.apk'},],
                                                        ]
                                                    }
                                                }
                                            }
                                        }),
                                    headers={"Content-Type": "application/json","Authorization": token})
            if sendRes.status_code != 200 or sendRes.json()['code'] != 0:
                print('飞书消息发送失败')
            print(sendRes.json())

print('开始构建项目...')
print(f'构建项目环境:{env} 版本号: {version}')

# flutter 版本切换
os.system(f"fvm use {flutterSdk} --force")
os.system(f"fvm flutter --version")
# 修改版本号
change_yaml_version()
# 清除缓存
clear_cache()
# 修正删除32位符号表
# fixPodFileSetting()
# 初始化
init()

if isBuildChannel == 'false' :
    # 构建iOS
    buildIOS()
    # 构建android
    buildAndroid()
    # 提交App
    uploadApp()
    # 蓝盾
    blue()
    # 提供给测试的接口文件
    updateApkDownloadUrl()
else :
    # 构建渠道包
    buildChannelApk()
    sendChannelApkMessage()