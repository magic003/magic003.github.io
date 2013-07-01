---
layout: post
title:  "Tiny Extension to Ruby YAML"
date:   2010-01-28 21:41:00
categories: tech
---

I am using Ruby's YAML library to dump objects to yaml document. The built in library dumps all fields, but in my program I only need to serialize part of them. So I need a way to set some fields to be transient.

I searched the web, and found Xavier's [yaml_helper](http://rhnh.net/2006/06/25/yaml-tutorial). It can solve my problem, but not exactly what I want. It uses class attribute "persistent" to indicating the fields to be serialized. In my suitation, there are many fields in the object, and only two or three are transient. So I prefer the "transient" class attribute.

After reading the source code of [yaml_helper](http://github.com/xaviershay/sandbox/tree/master/yaml_helper/) and Ruby's YAML library, I decided to write my own. Now, you can check it from [here](http://github.com/magic003/yaml_ext). It is no more than 100 lines code with most copied from [yaml_helper](http://github.com/xaviershay/sandbox/tree/master/yaml_helper/), and realy a tiny tiny extension.

