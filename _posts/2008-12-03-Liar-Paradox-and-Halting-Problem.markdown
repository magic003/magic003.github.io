---
layout: post
title:  "Liar Paradox and Halting Problem"
date:   2008-12-03 22:11:00
categories: tech
---

### Liar Paradox
首先来看一下什么是liar paradox。Liar paradox的雏形来自于一个叫作Epimenides的克里特人，他说：“所有克里特人都是说谎者。”这常常被认为等同于liar paradox，其实不然，因为如果他说的是真话，那么他就在说谎；如果他在说谎，说明至少还有一个克里特人说的是真话，这并不矛盾。最早的liar paradox版本是由生活在公元前4世纪希腊的麦加拉学派（Megarian）哲学家Eubulides提出的。他说：

> A man says that he is lying. Is what he says true or false?

如果他说的是真的，那么他在说谎；如果他说的假的，那么他没在说谎。

后来又出现了一些liar paradox的变种，比较有名的有：

> This sentence is false.

下面的悖论又名"Jourdain's Card Paradox"：有一张卡片，一面写着：

> The sentence on the other side of this card is true.

而在卡的另一面却写着：

> The sentence on the other side of this card is false.


### Halting Problem
Halting Problem是计算理论中的经典问题。它的意思，简而言之就是：对于一段程序和有限的输入，决定其是终止还是永久运行。说白了就是设计一个算法来判断一段程序是否会进入死循环。Alan Turing在1936年证明了不存在这样的算法。

在SICP课程的最后一讲[\[4\]][4]中，为了说明不是任何事物都是可计算的，使用了这样一个例子来证明不存在halting problem的算法。

首先，假设存在这样的算法，则存在函数`(halts? p)`：

{% highlight scheme %}
(halts? p)
=> #t if (p) terminates
=> #f if (p) does not terminates
{% endhighlight %}

现在有如下程序：

{% highlight scheme %}
(define (contradict-halts)
(if (halts? contradict-halts)
        (loop-forever)
                    #t))

(contradict-halts)
=> ???????
{% endhighlight %}

很容易，我们可以定义`(loop-forever)`为：

{% highlight scheme %}
(define (loop-forever)
        ((lambda (x) (x x))
                (lambda (x) (x x))))
{% endhighlight %}

这就是著名的Y combinator。

这里使用的就是liar paradox的精髓，如果这段程序会终止，则让它无限循环；如果程序不终止，则让它返回`#t`。

[1]: http://en.wikipedia.org/wiki/Liar_paradox "Liar paradox" on Wikipedia.org
[2]: http://www.paradoxes.co.uk/ "Some paradox"
[3]: http://en.wikipedia.org/wiki/Halting_problem "Halting problem" on Wikipedia.org
[4]: http://groups.csail.mit.edu/mac/classes/6.001/abelson-sussman-lectures/ "Video courses of SICP"
