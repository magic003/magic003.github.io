---
layout: post
title:  "使用GAppProxy翻墙"
date:   2009-12-04 21:22:00
categories: tech
---

自前日搞定Opera mini翻墙{% post_url 2009-12-02-我还活着 %}后，今天又尝试了使用[GAppProxy](http://code.google.com/p/gappproxy/)翻墙的方法。它的原理非常简单，就是在Google App Engine（GAE）上搭建一个代理服务器。

按照gappproxy网站上的使用方法，在本机安装一个代理的客户端。关键在于找到一个搭建在GAE上可用的代理服务器，可以使用网友提供的，也可以自己申请搭建。建议自己搭建，这样不需要与别人共享流量，参考：[用Google App Engine做个人代理服务器](http://hi.baidu.com/bdhoffmann/blog/item/db383603b37756703812bbc8.html)。项目中需要运行python脚本，这对于Linux用户尤为方便。

代理服务器和客户端都安装完成后，就可以使用了。为了使用方便，可以为Firefox安装AutoProxy插件，并选择GAppProxy作为默认代理，这样在浏览被屏蔽掉的网站时，就会自动使用代理了。

这种翻墙方式与Opera mini相比，不需要在手机模拟器中浏览网站，更加方便，效果也更好。
