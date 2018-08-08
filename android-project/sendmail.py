#!/usr/bin/env python
import os, smtplib, mimetypes ,sys,qrcode,Image
from email.mime.text import MIMEText  
from email.mime.image import MIMEImage  
from email.mime.multipart import MIMEMultipart  
MAIL_LIST_HYQ = ['anran.hu@okcoin.com','hui.you@okcoin.com','feng.shi@okcoin.com','qiankun.nie@okcoin.com','jiawen.song@okcoin.com','rongyao.zheng@okcoin.com','guangya.sun@okcoin.com']
MAIL_LIST_QA = ['xiao.gong@okcoin.com','hui.you@okcoin.com','anran.hu@okcoin.com']
MAIL_LIST_OKCOIN = ['yangyang@okcoin.com','hui.you@okcoin.com','anran.hu@okcoin.com','xiao.gong@okcoin.com','pusu.liu@okcoin.com','fangfang.zhang@okcoin.com','tao.dong@okcoin.com','pengxin.wang@okcoin.com','fan.yang@okcoin.com','xiaokang.yang@okcoin.com']
MAIL_LIST_OKLINK = ['liying.li@okcoin.com','jingze.zhang@okcoin.com','fangfang.zhang@okcoin.com','xiaokang.yang@okcoin.com']
MAIL_LIST_HUZHU = ['xiao.gong@okcoin.com','yazhou.chai@okcoin.com','anran.hu@okcoin.com','hui.you@okcoin.com','junjie.wang@okcoin.com','jinheng.yang@okcoin.com','hanqiang.li@okcoin.com','yongjun.xie@okcoin.com']
MAIL_LIST_BFMETAL = MAIL_LIST_OKCOIN
#MAIL_LIST_BFMETAL = ['hui.you@okcoin.com']
MAIL_HOST = "smtp.exmail.qq.com"
MAIL_USER = "redmine@okcoin.com" 
#MAIL_PASS = "Redmine@ok123"
MAIL_PASS = "V5Fxa5nS08a5C0DD"
MAIL_POSTFIX = "exmail.qq.com"
MAIL_FROM = MAIL_USER + "<"+MAIL_USER + "@" + MAIL_POSTFIX + ">"
HYQ_APP = "haoyouqian"
OKCOIN_APP = "OKCoin"
OKLINK_APP = "oklink"
HUZHU_APP = "huzhu"
BUILDTYPE = "Release"
GOOGLE="Release-Google"
BFMETAL_APP = "app"
 
def send_mail(subject, content, mailList, filename = None):  
    try:  
        message = MIMEMultipart()  
        #message.attach(MIMEText(content)) 
        message.attach(MIMEText('<b>APK URL:</b>'+content+'<br><img src="cid:image">','html','utf-8')) 
        message["Subject"] = subject  
        message["From"] = MAIL_FROM
        #if no release only mailt to QA
        message["To"] = ";".join(mailList)
        if filename != None and os.path.exists(filename):  
            ctype, encoding = mimetypes.guess_type(filename)  
            if ctype is None or encoding is not None:  
                ctype = "application/octet-stream" 
            maintype, subtype = ctype.split("/", 1)  
            attachment = MIMEImage((lambda f: (f.read(), f.close()))(open(filename, "rb"))[0], _subtype = subtype)  
            #attachment.add_header("Content-Disposition", "attachment", filename = filename)  
            attachment.add_header("Content-ID", "<image>")
            message.attach(attachment)  
 
        smtp = smtplib.SMTP()  
        smtp.connect(MAIL_HOST)  
        smtp.login(MAIL_USER, MAIL_PASS)  
        smtp.sendmail(MAIL_FROM, mailList, message.as_string())  
        smtp.quit()  
 
        return True 
    except Exception, errmsg:  
        print "Send mail failed to: %s" % errmsg  
        return False 

def qrcodeImage(url):
    qr = qrcode.QRCode(version=1,
                       error_correction=qrcode.constants.ERROR_CORRECT_L,
                       box_size=10,
                       border=4)
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image().resize((300,300),Image.ANTIALIAS)
    img.save("android.png") 

def mailList(buildType,appName):
    mailList = [""]
    if appName == HYQ_APP:
        if buildType == BUILDTYPE or buildType == GOOGLE:
            mailList = MAIL_LIST_HYQ
        else:
            mailList = MAIL_LIST_QA
    elif appName == OKCOIN_APP:
        if buildType == BUILDTYPE or buildType == GOOGLE:
            mailList = MAIL_LIST_OKCOIN
        else:
            #mailList = MAIL_LIST_QA
            mailList = MAIL_LIST_OKCOIN
    elif appName == OKLINK_APP:
        if buildType == BUILDTYPE or buildType == GOOGLE:
            mailList = MAIL_LIST_OKLINK
        else:
            mailList = MAIL_LIST_QA
    elif appName == HUZHU_APP:
        if buildType == BUILDTYPE or buildType == GOOGLE:
            mailList = MAIL_LIST_HUZHU
        else:
            #mailList = MAIL_LIST_QA
            mailList = MAIL_LIST_HUZHU
    elif appName == BFMETAL_APP:
        mailList = MAIL_LIST_BFMETAL
    return mailList
 
if __name__ == "__main__":
    if len(sys.argv) < 2:
        usage()
        sys.exit(1)
 
    subject = sys.argv[1] #
    content = sys.argv[2] #url
    buildType = sys.argv[3] #
    appName = sys.argv[4] #
    qrcodeImage(content) 
    mailList = mailList(buildType,appName)
    if send_mail(subject,content,mailList,"android.png"):  
        print "Send Mail Success" 
    else:  
        print "Send Mail Fail"
