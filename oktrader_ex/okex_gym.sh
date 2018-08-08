#!/bin/bash
#开始时间
SECONDS=0
#判断参数个数
if [ $# -ne 2 ]
  then
    echo "USAGE:$0 branch buildType"
    exit 1
fi

#编译分支
branch=$1

#指定要打包的配置名(编译类型)
#configuration="Release"
#configuration="Debug"
#Test---
#Debug----
#Release---
#编译类型
configuration=$2

#设置环境变量
PATH=$PATH:/usr/local/bin
export "$PATH"
#假设脚本放置在与项目相同的路径下
project_path=$(pwd)
#取当前时间字符串添加到文件结尾
date=$(date +%Y%m%d)
hour=$(date +%H%M)

#指定项目的scheme名称
scheme="OKTradeEX_iPhone"
#指定打包所使用的输出方式，目前支持app-store, package, ad-hoc, enterprise, development, 和developer-id，即xcodebuild的method参数
export_method='development'

#指定项目地址
workspace_path="$project_path/OKTradeEX_iPhone.xcworkspace"
#指定输出路径,如果路径不存在则创建
output_path="/Users/oker/Desktop/OKEX_archive/$date/$hour"
if [ -d "$output_path" ]
  then
    echo "$output_path"
else
  mkdir -p $output_path
fi

#指定输出归档文件地址
archive_path="$output_path/OKEX.xcarchive"
#指定输出ipa地址
ipa_path="$output_path/OKEX.ipa"
#指定输出ipa名称
ipa_name="OKEX.ipa"
#获取执行命令时的commit message
#commit_msg="$1"

#ipa名称
ipa_path="$output_path/OKEX.ipa"
#蒲公英中的API Key和User Key
#u_key="1329742d1fee22b06d316f0a665a4344"
#api_key="67cc4e064ed415008fc0e63a9640c7b8"
#fir token
#fir_token = "3420dc430203c4d6eda9ed36eac2168e"
#项目名称，跟sendmail中对应
project_name="OKEX"
#编译类型
buildType=$configuration



#输出设定的变量值
echo "===workspace path: ${workspace_path}==="
echo "===archive path: ${archive_path}==="
echo "===ipa path: ${ipa_path}==="
echo "===export method: ${export_method}==="
#echo "===commit msg: $1==="

#更新代码
function updateCode(){
  #检查分支是否包含最新master代码
  if [ $branch != "master" ]
    then
      git fetch
      result=`git log --oneline origin/master ^origin/$branch|wc -l`
      if [ $result -ne 0 ]
        then
          echo "Error: ${branch} 不包含master最新代码"
          exit 1
      fi
  fi

  #更新代码
  git pull
  git checkout $branch
  if [ $? -ne 0 ]
    then 
      echo "切换分支${branch}失败"
      exit 1
  fi
  #git clean
  git fetch --all
  git reset --hard origin/$branch
  git pull
  if [ $? -ne 0 ]
    then 
      echo "更新分支${branch}失败"
      exit 1
  fi
  #更新依赖文件
  #pod repo update
  #pod update
  #pod update --no-repo-update
# git submodule update --init --recursive
}

#编译代码
function compileCode(){
  #rm -rf /Users/okcoin/Desktop/project.pbxproj
  #mv /Users/okcoin/Desktop/okinsure/OKInsure.xcodeproj/project.pbxproj /Users/okcoin/Desktop
  #设置安全证书
  security -v unlock-keychain -p "oker" "/Users/oker/Library/Keychains/login.keychain"
  #先清空前一次build
  gym --workspace ${workspace_path} --scheme ${scheme} --clean --configuration ${configuration} --archive_path ${archive_path} --export_method ${export_method} --output_directory ${output_path} --output_name ${ipa_name}|tee build.log.1
  #判断是否编译成功
  if [ $(grep "Successfully exported and signed the ipa file" build.log.1|wc -l) -gt 0 ]
    then
      echo "Build Success"
      rm -rf build.log.1
  else
    echo "Build Failed"
    rm -rf build.log.1
    exit 1
  fi
}

#上传编译文件到蒲公英
#function upload()
#{
  #上传ipa到服务器
#  rsync ${output_path}/$ipa_name publish@192.168.0.9:~/ios-project|tee rsync.log.1
#  if [ `grep "error" rsync.log.1 |wc -l` -gt 0 ]
#    then
#        echo "$apkName上传服务器失败"
#        rm -rf rsync.log.1
#        exit 1
#  else
#    echo "$apkName已经上传到服务器"
#    rm -rf rsync.log.1
#  fi
#}

#function upload()
#{
#    url=http://www.pgyer.com/apiv1/app/upload
#    response=`curl -F "file=@$ipa_path" -F "uKey=${u_key}" -F "_api_key=${api_key}" ${url}`
#    echo ${response}|tee response.json
#    #判断是否上传成功
#    if [ `grep "appVersion" response.json |wc -l` -gt 0 ]
#    then
#        echo "上传蒲公英成功"
#    else
#        echo "上传蒲公英失败"
#        exit 1
#    fi
#
#}

#生成安装二维码并发送邮件
function sendMail()
{
    #获取版本号
    ver=`cat response.json |grep 'appKey'|awk -F "," '{print $9}'|awk -F ":" '{print $2}'|awk -F '"' '{print $2}'`
    aKey=`cat response.json |grep 'appKey'|awk -F "," '{print $3}'|awk -F ":" '{print $3}'|awk -F '"' '{print $2}'`

    #删除日志和ipa文件
    rm -rf response.json
    rm -rf $ipa_path

    #生成二维码并发送邮件
    #url="https://www.pgyer.com/apiv1/app/install?_api_key=67cc4e064ed415008fc0e63a9640c7b8&aKey=$aKey"
    url="https://www.pgyer.com/apiv1/app/install?_api_key=${api_key}&aKey=$aKey"
    echo "IOS ${project_name} V${ver} $buildType build in `date +%Y%m%d%H%M` $url ${project_name}"
    python sendmail.py "IOS ${project_name} V${ver} ${buildType} build in `date +%Y%m%d%H%M`" "$url" "${project_name}"|tee mail.log
    if [ `grep "Send Mail Success" mail.log |wc -l` -gt 0 ]
        then
            rm -rf ios.png
            rm -rf mail.log
            exit 0
    else
        echo "邮件发送失败"
        rm -rf ios.png
        rm -rf mail.log
        exit 1
    fi
}

updateCode    #更新代码
compileCode   #编译代码
#upload        #上传ipa到蒲公英
#sendMail      #生成安装二维码并发送邮件

#输出总用时
echo "===Finished. Total time: ${SECONDS}s==="
exit 0
