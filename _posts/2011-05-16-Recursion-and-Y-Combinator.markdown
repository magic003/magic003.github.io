---
layout: post
title:  "Recursion and Y Combinator"
date:   2011-05-16 11:34:00
categories: tech
---

Today, I will talk about an important concept: recursion. It means a function could call itself inside its body. With recursion, many difficult problems can be solved in an easily understood way. A good case in point is the problem of [Tower of Hanoi](http://en.wikipedia.org/wiki/Tower_of_Hanoi). In this post, a much simpler problem is used to demonstrate the concept of recursion and how we implement it in our evaluator.

Till now, our evaluator is capable of doing basic arithmetics, but that's not enough for a real programming language. Let's consider this problem: how to compute the factorial of n? For `3`, we can compute it using `(* 3 (* 2 1))`; For `4`, it is `(* 4 (* 3 (* 2 1)))`. However, for `n`, we cannot write out the expression, because `n` is unknown when we are defining the function. By observing factorial `3` and `4`, we can easily find out that factorial `4` is the multiplication of integer `4` and factorial `3`. We can derive a recursive solution like this: to compute factorial of `n`, we can multiply `n` by factorial of `n-1`; to compute factorial of `n-1`, we can multiply `n-1` by factorial of `n-2`; and so on. Until we meet factorial `1`, whose result we know is `1`. This is called the **base case**, where the recursion is stopped at. Start with this strategy, we can compute the factorial of `n` without writing out the whole expression, because the recursion will take care of it for us.

### Recursion

Based on the idea described before, we can define the factorial function recursively as follows:

> `factorial  := (lambda n (= n 1) 1 (* n (factorial (- n 1))))`

We use the "`:=`" symbol to assign a name to a function to assist explanation and it has nothing to do with our lambda calculus evaluator. The = function checks the equality of two integers and returns a boolean value. This is not a correct expression because lambda calculus doesn't allow a function to refer to itself. Moreover, we are not able to write out such an expression, because when defining a function we need itself inside the body. Though we don't have the function when we are defining it, it will be available later. Thus, instead of referring to itself, the `factorial` function could have us supply a factorial function t as an argument. Using this strategy, the function we define is no longer a factorial function, but a factorial maker function: it takes some factorial function and produce a factorial function. The `mkfactorial` function is defined as:

> `mkfactorial := (lambda t (lambda n (= n 1) 1 (* n (t (- n 1)))))`

This is a legal expression in our lambda calculus evaluator, but it still sounds strange. We are defining a factorial function, but we rely on another factorial function. Obviously, we still don't have a factorial function. Think again, what if we change the definition of `mkfactorial` to which requires a maker function as an argument instead of a factorial functioin? We assume the `mkfactorial` function apply on a maker function t would produce a factorial function, and for every occurrence of a factorial function in the body we use (t t), because applying a maker function to itself produces a factorial function. We redefine the function as follows:

> `mkfactorial' := (lambda t (lambda n (= n 1) 1 (* n ((t t) (- n 1)))))`

And we could get `factorial` function by applying `mkfactorial'` to itself:

> `factorial := mkfactorial' mkfactorial'`

To examine whether the solution works, we are going to reduce `factorial 3` and `factorial n`. To save space, I will use the names for the functions defind above during the reduction and only expand them when necessary. Remember, when evaluated in our evaluator, only the expanded expressions are kept. For `factorial 3`:

<pre class="console">
factorial 3
= mkfactorial' mkfactorial' 3
= (lambda t (lambda n (= n 1) 1 (* n ((t t) (- n 1))))) mkfactorial' 3
=> (lambda n (= n 1) 1 (* n ((mkfactorial' mkfactorial') (- n 1)))) 3
=> (= 3 1) 1 (* 3 ((mkfactorial' mkfactorial') (- 3 1)))
=> (* 3 ((mkfactorial' mkfactorial') 2))
= (* 3 ((lambda t (lambda n (= n 1) 1 (* n ((t t) (- n 1))))) mkfactorial' 2))
=> (* 3 ((lambda n (= n 1) 1 (* n ((mkfactorial' mkfactorial') (- n 1)))) 2))
=> (* 3 ((= 2 1) 1 (* 2 ((mkfactorial' mkfactorial') (- 2 1)))))
=> (* 3 (* 2 ((mkfactorial' mkfactorial') 1)))
= (* 3 (* 2((lambda t (lambda n (= n 1) 1 (* n ((t t) (- n 1))))) mkfactorial' 1)))
=> (* 3 (* 2 ((lambda n (= n 1) 1 (* n ((mkfactorial' mkfactorial') (- n 1)))) 1)))
=> (* 3 (* 2 ((= 1 1) 1 (* 1 ((mkfactorial' mkfactorial') (- 1 1))))))
=> (* 3 (* 2 1))
=> 6
</pre>

And `factorial n`:

<pre class="console">
factorial n
= mkfactorial' mkfactorial' n
= (lambda t (lambda n (= n 1) 1 (* n ((t t) (- n 1))))) mkfactorial' n
=> (lambda n (= n 1) 1 (* n ((mkfactorial' mkfactorial') (- n 1)))) n
=> (= n 1) 1 (* n ((mkfactorial' mkfactorial') (- n 1)))
=> (* n ((mkfactorial' mkfactorial') (- n 1))
</pre>

The meaning of `(mkfactorial' mkfactorial') (- n 1)` is factorial of `n-1`, and the result is what we want for factorial of `n`.

### Y Combinator

Using the technique in the last section, we can construct the expressions for recursive functions from scratch. For each function, we always need to go through the following process: writing a function that refers to itself, changing it to a maker function, revising the maker function to make it accepts another makers function, and finally applying the maker function to itself. This is boring and clumsy. The significant part that makes each recursive function different is the maker function. Can we abstract this process into a function and the only thing we need to provide is a maker function?

The function we are eager to have is one that accepts a maker function and produces a recursive function. A maker function consists of two parts: a base case and a recursive case. The recursive stops when reaching the base case. Let's call the target function `mk`, and it is defined as:

> `mk := (lambda t t (mk t))`

Since argument `t` is a maker function, apply t to a recursive function, which we can make from `(mk t)` here, would again produce a recursive function, which is the result of `mk`. This is how we come up the definition of `mk`. Still, it is an illegal expression because mk refers to itself. Using the same technique as before, we can derive the maker function:

> `mkmk' := (lambda k (lambda t t ((k k) t)))`

and the `mk` function:

> `mk := mkmk' mkmk'`

We omitted the `mkmk` function. Now, we can define the `factorial` function as `(mk mkfactorial)`. Let's check its behavior:

<pre class="console">
factorial
= mk mkfactorial
= (lambda k (lambda t t ((k k) t))) mkmk' mkfactorial
=> (lambda t t ((mkmk' mkmk') t)) mkfactorial
=> mkfactorial ((mkmk' mkmk') mkfactorial)
= mkfactorial (mk mkfactorial)
</pre>

According to the definition of `mk`, `(mk mkfactorial)` makes a `factorial` function, so the last step above is a `factorial` function. This is what we want.

With this `mk` function, we can define other recursive functions by providing a maker function. If we want to compute the sum of `1...n`, we can define the function as follows:

> `sum := mk (lambda t (lambda n (= n 1) 1 (+ n (t (- n 1)))))`

In lambda calculus, `mk` is just one of such kind of functions. The more famous one is called `Y`:

> `Y := (lambda f (lambda x f (x x)) (lambda x f (x x)))`

Sometimes, when we are talking about **Y combinator**, it doesn't just mean the `Y` function, but a collection of functions like `Y` and `mk`.

### Standard Library

The Y combinator is very useful for defining recursive functions. However, it is very inconvenient to write out the long expression every time we need it. So I would like to implement it as a predefined function in our evaluator, and we only need to call the `Y` function to use it. Unfortunately, the definition above cannot be used directly in our evaluator. Let's take a look at the reason:

<pre class="console">
Y g
= (lambda f (lambda x f (x x)) (lambda x f (x x))) g
=> (lambda x g (x x)) (lambda x g (x x))
=> g ((lambda x g (x x)) (lambda x g (x x)))
</pre>

In an eager evaluator, it won't progress in last step above, because the underlined part is an infinite loop and it can't be evaluated to a value. Since the argument is evaluated before applied to the function, g is never called in our current evaluator. This problem doesn't exist in a lazy evaluator. To solve this, we can change the underlined part to an abstraction expression. Do you still remember the η-conversion(that means `λx. f x => f`)? We can use the inverse-η conversion to change each application in `Y` into an abstraction.


<pre class="console">
Y := (lambda f
        (lambda a
            (lambda x f (lambda g (x x) g))
            (lambda x f (lambda g (x x) g)) a))
</pre>

Let's try to apply this new `Y` on `mkfactorial`:

<pre class="console">
Y mkfactorial
= (lambda f (lambda a (lambda x f (lambda g (x x) g)) (lambda x f (lambda g (x x) g)) a)) mkfactorial
=> (lambda a (lambda x mkfactorial (lambda g (x x) g)) (lambda x mkfactorial (lambda g (x x) g)) a)
=> (lambda x mkfactorial (lambda g (x x) g)) (lambda x mkfactorial (lambda g (x x) g))
=> mkfactorial (lambda g ((lambda x mkfactorial (lambda g (x x) g)) (lambda x mkfactorial (lambda g (x x) g))) g)
</pre>

Look at the last step, the underlined part is a function now, so we can apply it to the `mkfactorial` function. To save space, let's mark the underlined part as symbol `T`:

<pre class="console">
=> (lambda t (lambda n (= n 1) 1 (* n (t (- n 1))))) T
=> (lambda n (= n 1) 1 (* n (T (- n 1))))
</pre>

This is the recursive function we finally get. Let's apply it on integer `1`:

<pre class="console">
Y mkfactorial 1
=> (= 1 1) 1 (* 1 (T (- 1 1)))
=> (lambda x (lambda y x)) 1 (* 1 (T (- 1 1)))
=> (lambda y 1) (* 1 (T (- 1 1)))
</pre>

In a lazy evaluator, the result 1 is returned from last step. While in our current eager evaluator, we won't get the expected result because of our implementation of *if-statement* using booleans. Currently, the boolean value is encoded using a function that cosumes two arguments. The `(= 1 1)` expression is evaluated to `(lambda x (lambda y x))`. Though the underlined part is never used in the function, we still have to evaluated it, and we will go into an infinite loop when doing so. From this example, we can conclude that Y combinator doesn't work in an eager evaluator which implements the **if-statement** as a pure function. To solve this, one way is using a lazy evaluation strategy. Another way is treating **if-statement** as a special form like Scheme. We choose the first option here, so all the things we talk later are implemented in our call-by-name evaluator.(If you use the second option, the `Y` function defined before will work without further modifications.)

Before adding `Y` function into our evaluator, I'd like to say a few words about builtin library and standard library. Till now, all the predefined functions in our evaluator are builtin functions, such as `+`, `-`, `>` and `=`. All the functions require the support of primitive operators by the evaluator. We cannot implement them using pure lambda calculus expression. While for standard functions, they are implemented as lambda calculus expressions. Without the builtin library, some features of the evaluator are lost, but without the standard library, programmers can still achieve the same effect by implementing the standard functions themselves using basic expressions. So the standard library is not mandatory and usually for programmer's convenience. The `Y` function is for such purpose, so we define it in the standard library.

The standard library is implemented in `stdlib.h` and `stdlib.c` files. It is similar to the implementation of builtin functions, so I won't duplicate the code here. The tricky part is that the `yyparse()` method is used to parse the expressions for standard functions into tree structure, so it could be used by the evaluator. The simple version of `Y` function is used because it works in our call-by-name evaluator. The `evaluate` function is also updated to search functions by name in the standard library. Please refer to [source code](https://github.com/magic003/lambda_calculus_evaluator) for more information.

Some other functions, such as `not`, `or` and `and`, are added into the standard library in the same way. As an ending, let's try the`factorial`, `sum` and a more complex `fibnacci` function in our evaluator:

<pre class="console">
$ ./main
Welcome to Lambda Calculus Evaluator.
Press Ctrl+C to quit. 

# factorial 3
> Y (lambda t (lambda n (= n 1) 1 (* n (t (- n 1))))) 3
-> 6

# sum 4
> Y (lambda t (lambda n (= n 1) 1 (+ n (t (- n 1))))) 4
-> 10

# fibnacci 7
> Y (lambda t (lambda n (or (= n 1) (= n 2)) 1 (+ (t (- n 1)) (t (- n 2))))) 7
-> 13
</pre>
