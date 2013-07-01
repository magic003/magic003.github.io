---
layout: post
title:  "Personal Wiki"
date:   2009-02-07 13:16:00
categories: tech
---

我这人有两个毛病：记性差和喜新厌旧。明明当时记得很清楚的事情，过了3、4天就忘得差不多了。但是又对新事物特别感兴趣，比如技术，看到新的技术，就会放下手头的东西去研究新的，导致我的很多知识都是浅尝辄止，而且时间一长，连基本的都忘记了，等下次需要用的时候，又得从头学起。这时又只能到处去找文档和教程。所以决定使用Wiki作为个人知识库，在学习时把有用的资料记录下来，以便日后需要时能够很容易地找回来。

这是一个仅供自己使用的Wiki，所以安装在本机上即可，至于多用户、版本控制等与协作相关的功能都不是必需的，只要满足如下条件即可：

1. 尽可能的lightweight，使用文件作为存储，不需要数据库和web server
2. 中文支持当然是必需的，并且必须支持Linux平台
3. Open source，最好是使用我熟悉的语言写的，以便能自己进行修改
4. 能方便地进行定制，修改布局，风格等
5. 能方便地进行备份和迁移

首先推荐一个网站：[WikiMatrix](http://www.wikimatrix.org/)，通过输入一些要求，它就会根据这些要求推荐一些Wiki系统，并给出对它们进行比较的结果。经过一些筛选，最后确定3个候选的Wiki：

* [Wiki on a Stick](http://sourceforge.net/projects/stickwiki)：它只有一个html页面，使用JavaScript+CSS+HTML完成。所有的内容都保存在一个文件中，由JavaScript来切换显示的内容。这个创意很Cool，小巧且容易移动，可以将其存放在邮箱或U盘中。它的界面风格也很简洁，正是我喜欢的类型。但是它现在仍处于Beta阶段，如其页面上的提示：这是Beta版本，不建议用来保存关键数据。再看看最近一次更新也已经是一年半前的了，track中也没什么activity，项目似乎处于停滞阶段。而且，我也没看到Wiki on a Stick有成熟的user community，所以我最后没有选择它。
* [TiddlyWiki](http://www.tiddlywiki.com/)：TiddlyWiki与Wiki on a Stick如出一辙，在切换内容的时候加入了一些animation的效果，使界面看起来更“Web 2.0”一点。Journal是Wiki on a Stick没有的功能，用来记录某一天做的事情。TiddlyWiki现在的版本是2.4.3，应该算比较稳定了。最重要的是，它有很优秀的文档和user community，还有很多基于TiddlyWiki的变种，这使我最终选择了它。但是有两点我不是很喜欢，首先是它默认的风格，其次是在切换内容的方式，它并不是先隐藏之前的内容再显示新的内容，而是将新的内容放在页面顶端，经过多次切换后，页面就会上下跳动，让人很不舒服。这两点都是可以修改的，以后要研究一下。
* [doxWiki](http://doxwiki.sourceforge.net/)：这也是一个很小巧的Wiki，用Perl写的，同时自带了一个用Perl写的server，使用之前需要运行该server。它有一些不错的功能，比如导出html文件。

更多关于以上三个Wiki的比较，请看这篇文章：[Personal wikis: Three small, simple alternatives](http://www.linux.com/articles/56658)。

除了搭建在本机的Wiki，还存在着一些提供Wiki服务的网站，可以在上面创建自己的Wiki页面。对我来说，这样的好处是可以在家里和公司访问Wiki。但是也有一些缺点，比如访问速度不快，受制于服务提供商的一些政策，没有网络的时候无法访问，所以我还是选择自己安装Wiki。在筛选的过程中找到了几个免费的不错的Wiki hosting网站：

* [Wiki Spot](http://wikispot.org/)：二级域名，简洁现代的界面，多种主题……都是我的最爱，只是Wiki Spot的目的旨在建立Wiki community，它要求每个Wiki的主题必须能够形成一定的用户群，这与我的目的不符，所以只得作罢。
* [@Wiki](http://atwiki.com/)：除去基本功能，提供了很多主题，页面操作也很简单明了，不过不支持二级域名。
* [Intodit](http://www.intodit.com/)：二级域名，主题比较少，不同主题布局都是一样的，只是颜色不同而已。不是很喜欢它的button风格，在firefox中很难看。可定制的部分不是很多，不喜欢自带的那几个tab页。

先花点时间研究一下TiddlyWiki，如果你有更好的选择，欢迎推荐给我。
