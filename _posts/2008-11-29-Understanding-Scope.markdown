---
layout: post
title:  "Understanding Scope"
date:   2008-11-29 13:40:00
categories: tech
---

Scope是Programming Languages中的重要概念。我的第一门Programming Language是C++，记得当时买的参考书专门用了一章的篇幅来讲解scope，罗嗦了一大堆，当时搞清楚了，事后很快就忘记了。后来学习Java，PHP和Ruby等语言，都有scope的概念，不过都大同小异。掌握了scope的内涵，任何语言的scope都不难学习。

### What is Scope?
Wikipedia上对scope的定义是[\[1\]][1]：

> In computer programming, **scope** is an enclosing context where values and expressions are associated.

首先，scope是一个"enclosing context"，它是一个上下文环境，并且是封闭的。其次，在这个环境中，"values and expressions are associated"，也就是说在这个环境里，expression被绑定到特定的值，但是出了这个环境，该expression就不再绑定到这个值了。

有一个笑话，话说南京人把三轮电动摩的称作“马自达”，这种车体积小巧，马力不大，开起来噪音很大，而且外壳也不是很牢固。在乡下开开还可以，要是在城里主干道上行驶，不仅危险系数很高，而且还会影响市容。所以在金陵饭店门口挂了个牌子：马自达不得入内。于是外地开着马自达来南京的商人，看到牌子都被吓跑了。

同样是“马自达”这个词（expression），在全国这个scope中指汽车马自达（value），而在南京scope中就变成了三轮摩的（value）。古语有云：“橘生淮南则为橘，生于淮北则为枳”，也是这个意思。由此可见，无论是expression还是其他事物，都应该放在特定的scope和环境中进行评价，很有哲学意味吧。

有些语言提供了namespace的机制，比如C++中的`using namespace`和ruby中`module`。Namespace也是一个scope，只不过它用了一个标识符来表示这个scope。这样，在谈论expression时，就可以指定在哪个scope中确定其值。比如上面的笑话中，在“马自达”前加上“南京话中的”这个状语，就不会引起误会了。

### Why Scope?
在计算机发展的早期，内存大小和CPU的计算能力都很有限，程序通常也很小，数据被存放在一个地方，程序的任何部分都可以访问数据。但是，随着计算机的发展，程序变得越来越庞大，有很多部分组成，也需要很多程序员共同开发而成。这样，把程序不同部分需要的数据混合在一个地方就会造成混乱。比如程序的不同部分中用到相同的变量名，但是它们表示的是不同的数据，这样就很难确定程序的不同部分是否使用了正确的数据。

所以，就需要引入scope的特性，这样就能控制程序的不同部分访问它们各自的数据。通常，scope有两个作用。(1) define the visibility[\[1\]][1]：定义变量在特定的scope中才可见。这样，默认地，程序的某个部分只能访问该部分中的数据，而不会访问其他部分的数据。最常见的情况是在程序的不同部分可以定义相同名称的变量，它们指向不同的数据，而不会引起命名的冲突。(2) reach of information hiding[\[1\]][1]：得到隐藏的信息。比如使用namespace来访问其他scope中的数据。

### Lexical Scoping
根据scope的定义，scope是expression和value关联的地方，那么，是根据什么原则把expression和特定的value关联到一起的呢？有两种scope类型：lexical scoping和dynamic scoping。先来说说lexical scoping。

Lexical Scoping（又称Static Scoping）有很多定义[\[5\]][5]，但从其名称可知，lexical scoping只与程序语句的组织有关，而与程序运行时无关。变量只在其定义的block中可见，离开此block变量就不存在了。因此，在编译的时候就可确定变量绑定的地址，即可通过分析程序本身来确定变量的绑定，而无须运行程序。Lexical scoping意味着[\[4\]][4]：

> * an identifier at a particular place in a program always refers to the same variable location — where “always” means “every time that the containing expression is executed”, and that
> * the variable location to which it refers can be determined by static examination of the source code context in which that identifier appears, without having to consider the flow of execution through the program as a whole.

现代的Programming Languages大多使用lexical scoping，比如C，C++，Java，Ruby，PHP，Scheme等。

如下用C写的代码：

{% highlight c linenos %}
int x=0;
int f() { return x;}
int g() { int x=1; return f();}
{% endhighlight %}

or in Scheme：

{% highlight scheme linenos %}
(define x 0)
(define (f) x)
(define (g)
    (let ((x 1))
    (f)))
{% endhighlight %}

函数`g`的返回值为`0`，因为在定义函数`f`的时候，`x`绑定到全局的`x`，即`0`，所以无论什么时候运行`f`，结果都是`0`，所以`g`的结果也为`0`。

对于不支持High Order Procedure的语言（如C），实现lexical scoping只需使用一个symbol table记录变量的scope和memory address，从中查询变量即可，这是很高效的，因为每个变量的位置在编译时就确定了。而对于支持High Order Procedure的语言（如Scheme），则需要为每个函数保存其定义时依赖的环境（函数及其定义的环境组成了一个Closure）[\[6\]][6]。

使用lexical scoping有助于代码的模块化，也有助于程序员根据绑定来推出变量的值，减少错误的发生。这也是现代Programming Languages大多使用lexical scoping的原因。

### Dynamic Scoping
Dynamic Scoping无法在编译时确定变量的绑定，需要在程序的运行过程中才能确定。在运行过程中，每个变量都有一个对应的`stack`来保存绑定。例如，每次变量`x`被定义的时候，都会向`x`对应的`stack X`中push最新的绑定，当`x`离开当前scope后，就`pop stack X`。访问`x`的值时，每次获得的都是栈顶的绑定。

早期的Lisp语言都是使用dynamic scoping的，后来都渐渐加入了lexical scoping特性。现在Emacs Lisp仍然使用dynamic scoping。而Perl和Common Lisp则允许变量定义时指定其scope类型。

这时，在上面的例子中，函数的返回值为`1`。因为在g的函数体内定义了`x=1`，这时就向`x`的`Stack`中push了`x＝1`的绑定，这时再调用函数`f`，`f`返回的`x`则是从栈顶取出来的绑定，即`x=1`。在这个例子中，函数`f`的返回值不再是确定的，它依赖于被调用时`x`的值。

Dynamic scoping比较容易实现。在寻找某个变量的值时，可以遍历activation record，直到找到为止，这种方法叫作deep binding。还有一种效率更高的方法，如上描述，为每个变量维护一个绑定的stack，每次只需对栈顶元素进行操作即可，这种方法叫作shallow binding。如下图所示：

![shallow binding](https://lh5.googleusercontent.com/-zml9yDz0EJM/STEgv7WksHI/AAAAAAAAApc/_vgHUZRr_Es/s226/dynamic.png)

Dynamic scoping可以给程序带来很大的灵活性，在实现函数的时候不需要去推理变量的绑定，而只需专注于系统的当前状态。利用这种好处需要有良好的文档支持。但是它的缺点也很明显，首先它不利于模块化，设想一下如果使用dynamic scoping，那么现在那么多的java framework都可能无法正确运行。其次，由于无法知晓运行时的环境，会给程序带来意想不到的危险。因此，现代programming language几乎都不使用dynamic scoping。

Scope的一个重要作用是解决命名冲突。设想一个极端的情况，程序中所有变量都不重名，那么无论使用lexical scoping还是dynamic scoping，运行结果都是一样的。由此可见，两者的差别在于对重名变量的绑定方式的不同。从本质上讲，对于每个标识符，两者都需要维护一个stack来决定当前使用的绑定，而lexical scoping是在编译的时候维护这个stack，而dynamic scoping则是在运行时维护。

### Conclusion
Scope是决定expression与value关联的上下文环境。使用Scope可以解决命名冲突，定义变量可见性，以及获取隐藏的信息。Lexical scoping和dynamic scoping是scope的两种类型。

[1]: http://en.wikipedia.org/wiki/Scope_%28programming%29 "Scope (programming)" on Wikipedia.org
[2]: http://phobos.ramapo.edu/%7Eamruth/grants/problets/courseware/scope/home.html "Scope in Programming Languages"
[3]: http://en.wikiversity.org/wiki/Introduction_to_Programming/Scope "Introduction to Programming/Scope"
[4]: http://www.gnu.org/software/guile/manual/html_node/Lexical-Scope.html "Lexical Scope" on GNU.org
[5]: http://lua-users.org/lists/lua-l/2001-08/msg00320.html "Lexical scope definition"
[6]: http://mitpress.mit.edu/sicp/full-text/book/book.html "Structure and Interpretation of Computer Programs"
