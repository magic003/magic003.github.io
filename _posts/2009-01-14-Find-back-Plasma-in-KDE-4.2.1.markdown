---
layout: post
title:  "Find back Plasma in KDE 4.2.1"
date:   2009-03-14 11:39:00
categories: tech
---

Last week, I upgraded my Kubuntu to KDE 4.2.1 from repository [http://ppa.launchpad.net/kubuntu-members-kde4/ubuntu](http://ppa.launchpad.net/kubuntu-members-kde4/ubuntu). I was happy with that, because it is much faster than 4.2.0. After that I did some customization to the plasma desktop, adding widgets, changing theme and background, removing panel and so on. At last, I wanted to reconfig it, so I deleted all the files under `~/.kde` to bring me a brand new desktop. Now, the terrible things happened. After I restarted KDE, the plasma didn't startup successfully, with a popup message: "Plasma workspace crashed...". All I could see is a white screen, no desktop, no task bar, no panels. Luckily, I can still use `ALT+F2` to run programs, such as Konsole, Firefox, Dolphin and etc.

I searched the web, somebody said that you just need to remove the plasmarc and plasma-appletsrc files under `~/.kde/share/config` directory, and restart KDE. I tried, but there were no such files at all. I think that's because Plasma failed during the startup process, so those two configuration files had not been created yet.

Just now, I found this thread: [KDE 4.2.1 Plasma Crashes](http://kubuntuforums.net/forums/index.php?topic=3102117.15). It seems that they have the same problem with me. Someone says that the problem can be solved by removing file `/usr/share/kubuntu-default-settings/kde4-profile/default/share/config/plasma-appletsrc`. I tried, and it works for me. The plasmarc and plasma-appletsrc files are created under `~/.kde/share/config` now. Great, I get back my Plasma.

Before removing the file, I read it and found that it pointed to a wrong background image path, and contained applets which don't exist now. And after restart plasma, there is no newly created file plasma-appletsrc under `/usr/share/kubuntu-default-settings/kde4-profile/default/share/config/`. So I guess this file is not used by KDE 4.2.1. Maybe it was used by KDE 4.1 or 4.0 before.
