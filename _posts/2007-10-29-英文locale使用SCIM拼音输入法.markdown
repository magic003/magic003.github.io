---
layout: post
title:  "英文locale使用SCIM拼音输入法"
date:   2007-10-29 01:05:00
categories: tech
---

本文介绍在kubuntu的英文locale下如何安装配置SCIM输入法。

首先，使用如下命令安装SCIM输入法及相关组件：

<pre class="console">
sudo apt-get install scim scim-modules-socket scim-pinyin scim-gtk2-immodule im-switch libapt-pkg-perl
</pre>

然后配置在英文locale下使用SCIM，在`home`目录下执行：

<pre class="console">
mkdir .xinput.d
ln -s /etc/X11/xinit/xinput.d/scim en_US
</pre>

完成之后重启XWindow即可使用SCIM了。

前两天不知道为何，SCIM的拼音输入法莫名其妙丢失了，在网上搜了一下，可能是拼音字库损坏了，只需删除`.scim/pinyin`目录即可，在`home`目录下执行：

<pre class="console">
rm -r .scim/pinyin
</pre>
