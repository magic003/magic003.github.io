---
layout: post
title:  "kubuntu下配置Android SDK"
date:   2008-06-11 23:32:00
categories: tech
---

Android不需要安装配置，就跟Eclipse一样，只要java环境配置好了，解压了就可以直接使用了。这里的配置只是在kubuntu中配置一下`PATH`，从而能够在任何目录下调用Android提供的工具。

1. 到[下载页面](http://code.google.com/android/download.html)下载Android SDK，解压下载到的zip文件。

2. 将解压后的目录移动到想要安装的地方，例如：
    <pre class="console">
sudo mv android-sdk_* /opt/android</pre>

3. Android目录下的`tools`文件夹存放着常用的工具，将`tools`文件夹添加到`PATH`中。修改`~/.bashrc`文件，添加如下行：
    {% highlight sh %}
export ANDROID_HOME=/opt/android
export PATH=$PATH:$ANDROID_HOME/tools{% endhighlight %}

4. 重启console，输入`emulator`命令，如能运行Android的模拟器表明配置成功。
