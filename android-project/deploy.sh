#!/bin/bash
#参数个数判断
if [ $# -ne 3 ]
  then
    echo "USAGE:$0 branch buildDir"
    exit 1
fi
IP=`ifconfig en1|grep inet|grep netmask|awk -F ' ' '{print $2}'`
##########参数设置############################
param=$1
#代码分支名称
branch=${param%-*}
#编译类型：Debug Beta Release
buildType=${param#*-}
#代码目录 编译目录 apk目录
basePath=/Users/oker/Desktop/android-project
tmp=$2
projectPath=$basePath/${tmp%-*}
buildDir=${tmp#*-}
buildPath=$projectPath/$buildDir
#apkPath=$buildPath/build/outputs/apk
#编译日期和时间
date=`date +%Y%m%d`
hour=`date +%H%M`
#apk名称
apkName=$buildDir-localtest.apk
#初始版本号
verNum="V1.0"
site=$3
echo "######## $buildType"
#设置编译版本，跟编译类型对应：Test Beta Release
if [ "${buildType:0-7:7}" = "Release" ]
    then
        apkName=$buildDir-${site}-release.apk
        version="release"
elif [ "$buildType" = "assembleProguardBeta" ]
    then
        apkName=$buildDir-proguardBeta.apk 
        version="beta"
elif [ "${buildType:0-5:5}" = "Debug" ]
    then
        apkName=$buildDir-${site}-debug.apk
        version="debug"
fi
echo "代码分支:$branch"
echo "编译目录:$buildDir"
echo "apkName:$apkName"
apkPath=$buildPath/build/outputs/apk/$site/$version
#更新代码
function updateCode(){
  cd $projectPath
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
  #切换分支，更新代码
  git checkout $branch
    if [ $? -ne 0 ]
      then
        echo "切换分支${branch}失败"
        exit 1
    fi
  git clean -f
  #更新代码
  git fetch --all
  git reset --hard origin/$branch
  git pull

   if [ $? -ne 0 ]
      then
        echo "更新分支${branch}失败"
        exit 1
    fi

  #更新node
  if [ $buildDir = “OKCoin” ]
    then
      npm install
  fi
}

#verCode和verName的校验
function checkVersion(){
  #进入应用目录
  cd $buildPath
  rm -rf $projectPath/OKx/build
  rm -rf $buildPath/build
  #检查versionCode和versionName是否匹配
  verCode=`cat gradle.properties|grep 'MODULE_VERSION_CODE'|awk -F '=' '{print $2}'|sed 's/^[ \t]*//g'|sed 's/[ \t]*$//g'`
  verName=`cat gradle.properties|grep 'MODULE_VERSION_NAME'|awk -F '=' '{print $2}'|sed 's/^[ \t]*//g'|sed 's/[ \t]*$//g'`
  #版本信息文件目录路径
  versionInfoDirPath="$basePath/versionInfo/$buildDir"
  versionInfoFilePath="$versionInfoDirPath/versioninfo"
  #如果目录不存在，则新建目录
  if [ ! -d $versionInfoDirPath ]
    then
      mkdir -p $versionInfoDirPath
  fi
  #如果文件不存在，则新建文件
  if [ ! -f $versionInfoFilePath ]
    then
      echo "verCode,verName" >>$versionInfoFilePath
      echo "$verCode,$verName" >>$versionInfoFilePath
  fi

  result=`grep "${verCode}" $versionInfoFilePath`
  if [ -n "$result" ]
    then
      echo "verCode exists"
      name=`echo $result|awk -F ',' '{print $2}'`
      if [ "$verName" = "$name" ]
        then
          echo "verCode和verName校验通过"
      else
        echo "verCode和verName校验没有通过"
        echo "本次版本的verCode和verName是:$verCode,$verName"
        echo "上个版本的verCode和verName是:$verCode,$name"
        exit 1
      fi
  else
    echo "verCode no exists"
    name=`grep "$verName" $versionInfoFilePath`
    if [ -z "$name" ]
      then
        code=`sed -n '$p' $versionInfoFilePath|awk -F ',' '{print $1}'`
        if [ $verCode -gt $code ]
          then
            echo "verCode和verName校验通过"
            echo "$verCode,$verName" >> $versionInfoFilePath
        else
          echo "verCode和verName校验没有通过,vercode比上个版本小"
          echo "本次版本的verCode是:$verCode"
          echo "上个版本的verCode是:$code"
          exit 1
        fi
    else
      echo "verCode和verName校验没有通过"
      echo "本次版本的verCode和verName是:$verCode,$verName"
      echo "上个版本的verCode和verName是:$name"
      exit 1
    fi
  fi
}

#编译出apk
function compile(){
  cd $projectPath
  sh ./gradlew clean
  sh ./gradlew cleanBuildCache

  cd $buildPath
  #获取版本号
  verNum="V`grep 'MODULE_VERSION_NAME' gradle.properties|awk -F ' = ' '{print $2}'`"
  echo "##########$buildType ############"

  sh ../gradlew $buildType | tee build.log.1
  if [ `grep "BUILD SUCCESSFUL" build.log.1 |wc -l` -gt 0 ]
    then
        echo "$buildDir $buildType Success"
        rm -rf build.log.1
  else
    echo "$buildDir $buildType Failed"
    rm -rf build.log.1
    exit 1
  fi
}

######拷贝apk到Apache服务器#######
function upload(){
  cd $apkPath
  #编译release版本，将apk命名为haoyouqian-v1.3.3.apk
  if [ "$version" = "Release" ]
    then
      if [ "$branch" = "google" ]
	      then
	        releaseName=${buildDir}-${verNum}-Google.apk
          mv $apkName $releaseName
          apkName=$releaseName
	        version="Release-Google"
	    else
	      releaseName=${buildDir}-${verNum}.apk
        mv $apkName $releaseName
        apkName=$releaseName
      fi
  fi
  #ssh publish@192.168.0.9 "mkdir -p /var/www/html/android/$buildDir/$verNum/$version/$date/$hour"
  #rsync $apkName 192.168.0.9:/var/www/html/android/$buildDir/$verNum/$version/$date/$hour/
  mkdir -p /Library/WebServer/Documents/android/$buildDir/$verNum/$version/$date/$hour
  cp -fr $apkName /Library/WebServer/Documents/android/$buildDir/$verNum/$version/$date/$hour
  if [ $? -ne 0 ]
    then
      echo "$apkName上传服务器失败"
      exit 1
  else
    echo "$apkName已经上传到服务器"
  fi
  
}
######调用Python生成二维码#######
######发送邮件####################
function sendMail(){
  cd $basePath
  echo `pwd`
  #APK路径，生产二维码用
  url="http://${IP}/android/$buildDir/$verNum/$version/$date/$hour/$apkName"
  #参数说明：
  #参数1：邮件标题
  #参数2：apk路径
  #参数3：编译类型release or test
  #参数4：app名称：好有钱 or OKCoin or OKLink
  python sendmail.py "Android ${buildDir} ${verNum}.${version}.apk build in `date +%Y%m%d%H%M`" "$url" "$version" "${buildDir}"|tee mail.log
  echo "Android ${buildDir} ${verNum}.${version}.apk build in `date +%Y%m%d%H%M`" "$url" "$version" "${buildDir}"
  if [ `grep "Send Mail Success" mail.log |wc -l` -gt 0 ]
    then
      rm -rf android.png
      rm -rf mail.log
      exit 0
  else
    echo "邮件发送失败"
    rm -rf android.png
    rm -rf mail.log
    exit 1
  fi
}

updateCode     #更新代码
#checkVersion   #校验verCode和verName
compile        #编译
upload         #上传服务器
sendMail       #生成二维码并发送邮件
