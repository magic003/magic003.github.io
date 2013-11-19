---
layout: post
title:  "Full-text search engine for Pocket"
date:   2013-11-19 22:05:00
categories: life
---

四个月前关闭了Linktuned，发现平时偶尔还是会有搜索保存过的链接的需求。我现在只使用Pocket保存链接，所以想找一个对保存在Pocket中的链接提供全文搜索的应用。在google里搜索了一圈未果，倒是在Pocket的论坛上看到有部分用户提出了这样的要求。于是利用国庆后的两个星期，写了一个仅支持Pocket的“Linktuned”。代码是完全重写的，使用了轻量级的框架和工具，也没有太过考虑扩展性和功能的完备性。简而言之，就是花最少的功夫做最基本的功能。

[SearchPocket](http://www.searchpocket.info)上线一个多月了，只有9个用户，并且都是注册之后再也没有回来的。再一次说明这样的应用就是个鸡肋，并不是刚性需求。我自己倒是过个三五天会去搜以下，找回以前保存过的一些技术类文章。另一方面，这个应用的使用成本还是偏高。用户通常使用google进行搜索，如果他们想在SearchPocket中试下运气，还需要打开SearchPocket，重新输入关键字。所以，我正在考虑提供一个浏览器插件，当用户在google页面进行搜索的时候，会自动发送请求到SearchPocket，并把结果嵌入在google搜索结果的旁边。不知道这样会不会提高用户使用SearchPocket的机率。
