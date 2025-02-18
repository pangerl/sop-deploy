#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import sys
import json
import urllib2
import smtplib
from email.mime.text import MIMEText

reload(sys)
sys.setdefaultencoding('utf8')

notify_channel_funcs = {
  "email":"email",
  "wecom_proxy":"wecom_proxy"
}

PROXY = '172.18.0.17:9255'

mail_host = "smtp.exmail.qq.com"
mail_port = 465
mail_user = "notify@wshoto.com"
mail_pass = "dAGYHXE8g42kphPd"
mail_from = "notify@wshoto.com"

class Sender(object):
    @classmethod
    def send_email(cls, payload):
        if mail_user == "ulricqin" and mail_pass == "password":
            print("invalid smtp configuration")
            return

        users = payload.get('event').get("notify_users_obj")

        emails = {}
        for u in users:
            if u.get("email"):
                emails[u.get("email")] = 1

        if not emails:
            return

        recipients = emails.keys()
        mail_body = payload.get('tpls').get("email.tpl", "email.tpl not found")
        message = MIMEText(mail_body, 'html', 'utf-8')
        message['From'] = mail_from
        message['To'] = ", ".join(recipients)
        message["Subject"] = payload.get('tpls').get("subject.tpl", "subject.tpl not found")

        try:
            smtp = smtplib.SMTP_SSL(mail_host, mail_port)
            smtp.login(mail_user, mail_pass)
            smtp.sendmail(mail_from, recipients, message.as_string())
            smtp.close()
        except smtplib.SMTPException, error:
            print(error)

    @classmethod
    def send_wecom_proxy(cls, payload):
        users = payload.get('event').get("notify_users_obj")

        tokens = {}
        
        for u in users:
            contacts = u.get("contacts")
            if contacts.get("wecom_robot_token", ""):
                tokens[contacts.get("wecom_robot_token", "")] = 1

        proxy_handler = urllib2.ProxyHandler({'https': PROXY})
        opener = urllib2.build_opener(proxy_handler, urllib2.HTTPHandler)
        method = "POST"

        for t in tokens:
            url = "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key={}".format(t)
            body = {
                "msgtype": "markdown",
                "markdown": {
                    "content": payload.get('tpls').get("wecom", "wecom not found")
                }
            }
            request = urllib2.Request(url, data=json.dumps(body))
            request.add_header("Content-Type",'application/json;charset=utf-8')
            request.get_method = lambda: method
            try:
                connection = opener.open(request)
                print(connection.read())
            except urllib2.HTTPError, error:
                print(error)


def main():
    payload = json.load(sys.stdin)
    with open(".payload", 'w') as f:
        f.write(json.dumps(payload, indent=4))
    for ch in payload.get('event').get('notify_channels'):
        send_func_name = "send_{}".format(notify_channel_funcs.get(ch.strip()))
        if not hasattr(Sender, send_func_name):
            print("function: {} not found", send_func_name)
            continue
        send_func = getattr(Sender, send_func_name)
        send_func(payload)

def hello():
    print("hello nightingale")

if __name__ == "__main__":
    if len(sys.argv) == 1:
        main()
    elif sys.argv[1] == "hello":
        hello()
    else:
        print("I am confused")