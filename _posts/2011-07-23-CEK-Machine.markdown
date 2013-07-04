---
layout: post
title:  "CEK Machine"
date:   2011-07-23 12:50:00
categories: tech
---

In the textual machines I mentioned in [previous]({% post_url 2011-05-28-CC-and-SCC-Machine %}) posts, when reducing an application, without exception, everyone requires the substitution of an argument in place of all the occurences of an identifier in the abstraction body. The machine traverses the expression tree during substitution, and if the result is not a value, it needs to re-traverse it again to evaluate it. Take `(lambda x + x x) 1` as an example, `+ x x` is traversed to replace `x` with `1`. After that, we get result `+ 1 1`. To evaluate it, the expression `+ 1 1` is traversed again. It is inefficient to traverse an expression twice. We cannot get rid of this if we stick on the substitution when reducing an application. We can, however, remember the identifier and the argument at the moment and delay the substitution until it is actually needed.

To represent this delay substitution, a component that maps an identifier to an expression is needed. It is called an **environment**. Every expression in the machine is replaced by a pair, whose first part is an expression probably with free variables in it and the other part is an environment. It is called a **closure**. Of course, the environment could not map identifiers to expressions, because the machine never works on a single expression. It should map identifiers to closures. And the continuation also contains a closure. Now, the machine state changes to a control string, an environment and a continuation, so it is called a **CEK machine**. Here is the data structures introduced for environment and closure:

{% highlight c linenos %}
// file: cek_machine.h
struct envStruct {
    char *name;
    struct closureStruct *closure;
    struct envStruct *parent;
};

struct closureStruct {
    TreeNode *expr;
    struct envStruct *env;
};

typedef struct continuationStruct {
    ContinuationKind tag;
    Closure * closure;
    struct continuationStruct * next;
} Continuation;
{% endhighlight %}

Conceptually, an environment can contain several identifier-closure mappings. However, in the definition above an environment only has one such mapping. Since mappings are created when reducing applications and an abstraction only has one parameter, I keep one mapping in a standalone environment and arrange them hierarchically. When looking up for the mapped closure of an identifier, first try it in its associated environment, and if failed, try it in the parent one.

### CEK Machine

There is no significant change to continuation actions. Some new actions, like creating a closure, deleting a closure, creating an environment, looking up in an environment, are very common in the reduction steps. By the way, an identifier is no long a value because it may be mapped to an expression, which can be further reduced. Here are the reduction rules:

> 1) If the control string is an identifier, look up the mapped closure in the environment, and set the expression and environment of the closure as current expression and environment respectively;   
> 2) If the control string is a value(abstraction or constant), check the type of continuation:   
>
> > 2.1) If it is `FunKK`, pop up the continuation, create a new environment that maps the function parameter to current closure, and set the function body and the new environment as the current expression and environment respectively;   
> > 2.2) If it is `ArgKK`, set the continuation as `FunKK`, and switch the current expression and environment with these in the closure of continuation respectively;   
> > 2.3) If it is `OprKK`, pop up the continuation, evaluate the primitive expression, and set the result as the current expression and set the current environment to null;   
> > 2.4) If it is `OpdKK`, set next argument expression and its environment as current expression and environment respectively;
>
> 3) If the control string is an application, create and push a continuation of type `ArgKK`, whose closure consists of the argument expression and current environment, and set the abstractioin expression as current expression, with current environment unchanged;   
> 4) If the control string is a primitive, create and push a continuation of type `OpdKK`, whose closure consists of the primitive expression and current environment, and set the first argument expression as current expression, with current environment unchanged.   

Though implementation is straightforward according to the reduction rules, the code is getting complicated, so I am not duplicate it here. You can still access it on [github](https://github.com/magic003/lambda_calculus_evaluator).

A drawback of the CEK machine is no intermediate expression can be obtained after each step. What a pity! The machine always delays the substitution and expression is not actually reduced after each step. It does less work at the expense of losing immediate effects.
