---
layout: post
title:  "kubuntu下使用openvpn访问blogspot"
date:   2009-06-27 20:11:00
categories: tech
---

blogspot被封了好久，过去一段时间一直使用web proxy来访问（当然，仅仅是浏览的话，使用google reader的https链接就可以了），虽然浏览日志没有太多不便，但是想要发布文章还是存在一点问题，所以好久没写文章了。

今天找了两个VPN：[alonweb](http://alonweb.com/)和[UltraVPN](https://www.ultravpn.fr/)。试用了一下，速度还不错。据说后者最近有点问题，不是太稳定。两个都是免费不限流量的，而且都有windows的安装包，用起来十分方便。虽然没有提供Linux的安装包，但是它们都是基于openvpn的，所以在Linux下稍作配置即可使用。

首先需要安装openvpn，在ubuntu的源里面就有：

<pre class="console">
$ sudo apt-get install openvpn
</pre>

接着，需要去它们的网站上注册，注册的用户名和密码在连接VPN的时候需要提供。此外还需要下载配置文件和认证证书，alonweb的可以直接去官方网站下载：[Get Started!](http://alonweb.com/node/3)。UltraVPN的可以在这里下载：[ultravpn.conf](https://files.getdropbox.com/u/456306/ultravpn.conf)和[ultravpn.crt](https://files.getdropbox.com/u/456306/ultravpn.crt)。

最后，运行openvpn就可以了，切记一定要使用root用户运行：

<pre class="console">
$ sudo openvpn --config alonweb.conf --ca alonweb.crt
</pre>

输入用户名和密码，最后出现"Initialization Sequence Completed"表明成功了，这时使用ifconfig可以看到tun0连接。现在，就可以自由访问internet了。

下面是两篇参考的文章：

* [使用UltraVPN突破封锁访问Blogspot（免费VPN代理](http://dreamkeeper.com.cn/2009/05/vpn-proxy.html)
* [alonweb, 适合Linux的免费vpn](http://tuxfans.com/2009/05/24/257/)
