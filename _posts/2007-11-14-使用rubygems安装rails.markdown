---
layout: post
title:  "使用rubygems安装rails"
date:   2007-11-14 14:36:00
categories: tech
---

以前一直是使用`sudo apt-get install rails`来安装rails的，最近下载了redmine的源代码，想在自己机子上配置使用，但是在使用`rake db:migrate`创建数据库的时候报出`require 'action_web_service'`的错误，查了一下怀疑是安装rails的时候没有安装`actionwebservice`包的缘故，于是决定使用rubygems重新安装一下rails。使用`sudo apt-get install rubygems`虽然提示需要下载相应的安装包，但是下载时只有`404`错误。查了一下，听说ubuntu是不提供rubygems的apt-get安装的，原因好像是为了防止冲突。只能自己下载rubygems的包安装。把rubygems和rails都安装完后，再次配置redmine，一次就成功了。以此确定是因为用apt-get安装rails的问题，所以还是建议使用rubygems来安装rails，毕竟这是官方推荐的安装方式。现在把安装步骤写下来。

使用apt-get安装ruby的方法跟平常一样，在此不再赘述。首先从[http://rubyforge.org/projects/rubygems](http://rubyforge.org/projects/rubygems/)下载rubygems的安装包，当前最新版本是0.9.4。

<pre class="console">
$ tar xzvf rubygems-0.9.4.tgz
$ cd rubygems-0.9.4
$ sudo ruby setup.rb
$ sudo gem update --system
</pre>

使用如上命令安装并更新rubygems。然后使用如下命令来安装rails及其依赖：

<pre class="console">
$ sudo gem install rails -y
</pre>

会依次显示安装了`actioncontroller`，`activerecord`等包，正常退出则说明安装成功了，可以运行一下`rails`命令来测试一下。
