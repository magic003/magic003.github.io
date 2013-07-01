---
layout: post
title:  "Hello Android"
date:   2008-06-13 16:15:00
categories: tech
---

安装完了Android SDK，现在来开发个`Hello World`试试。不想用Eclipse这种重型的IDE，就使用Android提供的Python脚本和Ant来构建。

### 创建项目
Android提供了`activityCreator.py`这个Python脚本用来创建项目，运行：

<pre class="console">
activityCreator.py --out HelloAndroid com.android.hello.HelloAndroid</pre>

其中，`--out HelloAndroid`指定输出的目录， `com.android.hello.HelloAndroid` 指定继承了`Activity`的类。执行完如上命令后，将得到如下目录结构：

<pre class="console">
|--- HelloAndroid/
    |--- AndroidManifest.xml # Android应用程序的描述文件
    |--- bin/    # 存放编译打包后的二进制文件的地方
    |--- build.xml    # Ant脚本
    |--- res/    # 存放外部资源的地方
    |--- src/    # 存放源文件的地方
</pre>

<p/>

### 编译构建
在`HelloAndroid`目录下运行`ant`命令来编译构建项目。编译后，在`src/com/android/hello`下自动创建了`R.java`文件，这是保存一些resources信息的文件。同时，在`bin`目录下也生成了`HelloAndroid.apk`等文件，该文件包含了应用程序，是模拟器执行的对象。

### 部署运行
程序打包完之后需要部署到模拟器上才能运行。这里使用`adb`来部署。首先启动emulator，启动完成之后，运行如下命令来完成部署：

<pre class="console">
adb install bin/HelloAndroid.apk
</pre>

部署完成之后，可以在模拟器中的所有程序中找到`HelloAndroid`，运行之即可。

### 删除程序
测试完成之后，可以从模拟器中删除`HelloAndroid`程序，这里使用`adb shell`来完成。首先还是保证emulator已经启动，然后依次运行如下命令来删除程序：

<pre class="console">
adb shell
cd data/app/
rm HelloAndroid.apk
</pre>

发现`adb shell`是个好东西，就跟linux的shell程序一样，可以看到模拟器中的文件系统。
