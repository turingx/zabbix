#!/usr/bin/env python
# -*- coding: utf-8 -*-
#此脚本执行将之前shll脚本获取到的图像以附件方式发送到指定邮箱，同时正文直接引用附件，将图形在正文中显示

#导入email相关的库
from email import encoders
from email.header import Header
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
from email.utils import parseaddr, formataddr

import smtplib
import os,sys

#定义一个函数，用来接收传入的邮件地址
def _format_addr(s):
    name, addr = parseaddr(s)
    return formataddr(( \
        Header(name, 'utf-8').encode(), \
        addr.encode('utf-8') if isinstance(addr, unicode) else addr))


#邮件名称、密码、smtp服务器地址
from_addr = "test@163.com"
password = "test"
to_addr = ["ceshi@163.com"，"ceshi@qq.com"，"ceshi@sina.com"]
smtp_server = "smtp.163.com"



msg = MIMEMultipart()
msg['From'] = _format_addr(u'<%s>' % from_addr)
msg['To'] = _format_addr(to_addr)
msg['Subject'] = Header(u'zabbix', 'utf-8').encode()



# add file:

startdir = '/tmp/graph'
count = 0
htmlcode = ''
#变量之前shell获取图片的路径，，然后读取图片，将图片传入html文件的邮件中
for dirpath , dirnames , filenames in os.walk(startdir):
    for filename in filenames:
        if os.path.splitext(filename)[1] in ['.png','.jpg']:
            filepath = os.path.join(dirpath,filename)
            
            # add MIMEText:
            htmlcode = '<p><img src="cid:{}"></p>'.format(count)
            msg.attach(MIMEText('<html><body><h1> {} </h1>'.format(filename) +
                htmlcode + '</body></html>', 'html', 'utf-8'))
            
           # print(filepath)
           # print(htmlcode)
            with open(filepath, 'rb') as f:
                mime = MIMEBase('image', 'png', filename=filename)
                mime.add_header('Content-Disposition', 'attachment', filename=filename)
                mime.add_header('Content-ID', '<{}>'.format(count))
                mime.add_header('X-Attachment-Id', '{}'.format(count))
                mime.set_payload(f.read())
                encoders.encode_base64(mime)
                msg.attach(mime)
                count += 1

#连接smtp服务器，
server = smtplib.SMTP(smtp_server, 25)
#server.set_debuglevel(1)
#通过账号密码登录服务器，发送邮件
server.login(from_addr, password)
server.sendmail(from_addr, to_addr, msg.as_string())
server.quit()
