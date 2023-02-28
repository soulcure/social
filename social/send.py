import requests
import json
import sys

# 飞书 token
feishu_token = ''

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

# 发生文本信息
def sendMessage(groupName,content) :
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
        if group['name'] == groupName:
            chatId = group['chat_id']
            sendRes = requests.post("https://open.feishu.cn/open-apis/message/v4/send/",
                data=json.dumps({'chat_id': chatId, "msg_type": "text", "content": {"text": content}}),
                headers={"Content-Type": "application/json","Authorization": token})
            if sendRes.status_code != 200 or sendRes.json()['code'] != 0:
                print('飞书消息发送失败')


sendMessage(sys.argv[1],sys.argv[2])