---
layout: post
title:  "Lazy CEK Machine"
date:   2011-07-28 12:00:00
categories: tech
---

In the [CEK Machine]({% post_url 2011-07-23-CEK-Machine %}), though the substitution for an identifier is delayed, it doesn't mean it is a lazy machine. As described in [Eager and Lazy Evaluation]({% post_url 2011-05-14-Eager-and-Lazy-Evaluation %}), a lazy evaluation strategy doesn't evaluate an argument before applying it to a function. However, in the [CEK machine]({% post_url 2011-07-23-CEK-Machine %}), it always evaluates the argument to a value, so it is still a call-by-value machine. If you are careful enough, you may already notice whenever an environment is created, the expression in its closure is always a value. The real power of environment is working with lazy evaluation. So in this post, I am going to implement the call-by-name and call-by-need strategies for the CEK machine.

### Call by Name

It is quite easy to implement the call-by-name strategy based on the current call-by-value one. Since the machine no longer evaluates the argument before applying it to a function, the reduction rules related to applications should be modified(For a primitive operator, the operands are needed at the moment it is evaluated, so it stays unchanged.). In the call-by-value machine, when the control string is an application, first an `ArgKK` continuation is handled, then a `FunKK` continuation is handled. Now, the two steps, 2.1 and 2.2, should be combined into one, and the FunKK continuation type is removed.

> 2) If the control string is a value(abstraction or constant), check the type of continuation:   
>
> > 2.1) If it is ArgKK, pop up the continuation, create a new environment that maps the function parameter to current closure, and set the function body and the new environment as the current expression and environment respectively;

However, the machine may need to evaluate the same argument many times now. Take expression `(lambda x  + x x) ((lambda y y) 1)` as an example, `x` is mapped to `((lambda y y) 1)` after reducing the outer application. Then, when evaluating `+ x x`, `((lambda y y) 1)` is evaluated twice. The reason is that a parameter may be used several times in a function body, and whenever it is needed, the original argument it maps to should be evaluated. What if remember the result of the argument for the first time it is evaluated, so it doesn't bother to re-compute it later? I will talk this in next section.

### Call by Need

The idea is quite straightforward. Remember the value for a closure, so next time the closure is needed, the value is retrieved directly. Considering the same example `(lambda x + x x) ((lambda y y) 1)`, when the first `x` in `+ x x` is needed, `((lambda y y) 1)` is evaluated and the result is `1`. After this, the environment which maps `x` to `((lambda y y) 1)` is updated so `x` is mapped to `1`. When the second `x` is needed, `1` is retrieved from the environment and no extra evaluation is performed.

However, the implementation is not that simple. When evaluating `((lambda y y) 1)`, I can't simply put it as the control string of current machine, because this may destroy the machine state and the machine can't go back to previous state after it is evaluated. Instead, a separate evaluation process should be performed on it. This is kind of a sub-machine, whose evaluation logic is the same, but it relies on some states from the parent machine, such as environments because the expression itself may contain free variables. In current `evaluate()` function, it initializes the machine state at the beginning and clean it up at the end. It was designed like this because no sub-machine was ever needed before. I am going to refactor it so it is fed with a machine state and focuses on the reduction logic, instead of managing the lifecycle of the machine state. One advantage is an expression can be put into a particular context for evaluation. It is more flexible. The interface is changed to:

{% highlight c linenos %}
// file: eval.c
static int _evaluate(State *state);

TreeNode * evaluate(TreeNode *expr) {
    Environment *globalEnv = buildGlobalEnvironment();
    State *state = cek_newState();
    state->closure = cek_newClosure(expr,globalEnv);

    TreeNode* result = NULL;
    if(_evaluate(state)) {
        // The result control string may contain free variables, need to 
        // substitute them using the environment for it.
        TreeNode *tmp = resolveFreeVariables(state->closure->expr,state->closure->env);
        if(tmp!=NULL) {
            // actually, tmp and state->closure->expr are the same expression
            result = tmp;
            state->closure->expr = NULL;
        }
    }
    cek_cleanup(state);
    return result;
}
{% endhighlight %}

And the code for looking up an identifier is:

{% highlight c linenos %}
// file: eval.c
static Closure* lookupVariable(const char *name, Environment *env) {
    if(env==NULL) return NULL;
    if(strcmp(name,env->name)==0) {
        Closure *closure = env->closure;
        if(closure->env!=NULL) {
            // evaluates the expression in its environment
            State *state = cek_newState();
            state->closure = cek_newClosure(duplicateTree(closure->expr),cek_newEnvironment("",cek_newClosure(NULL,NULL),closure->env));

            if(_evaluate(state)) {
                deleteTree(closure->expr);
                cek_deleteClosure(closure);
                // save the evaluated result
                env->closure = cek_newClosure(state->closure->expr,state->closure->env);
                state->closure->expr = NULL;
            }
            cek_cleanup(state);
        }
        return env->closure;
    }
    return lookupVariable(name,env->parent);
}
{% endhighlight %}

### More Words about Closure and Environment

Another design improvement I want to mention is the **global environment**. Currently, if the control string is an identifier, the machine first tries to look it up in the environments and if not found it tries to resolve it from the builtin and standard libraries. Since a library maps identifiers to expressions, it is just like an environment. So the identifier lookup can be treated universally by introducing a global environment, which contains all the identifiers and functions provided by the evaluator. It is the root environment for all environments that are created during the evaluation and it is initialized when the machine is started. Thus, to handle a control string which is an identifier, the machine only needs to look it up in the environments. If it is a builtin or standard function, the machine can finally find it in the global environment.

A closure is an expression associated with an environment. The environment is where the expression is defined rather than it is evaluated. Let's consider the reduction steps of expression `(lambda x  (lambda y (lambda x + x y) 2) x) 1`.

<pre class="console">
(lambda x (lambda y (lambda x + x y) 2) x) 1
=> (lambda y (lambda x + x y) 2) x)                    A = {x=>(1,G), G}
=> (lambda x + x y) 2                                  B = {y=>(x,A), A}
=> + x y                                               C = {x=>(2,B), B}
=> + 2 y                                               C = {x=>(2,B), B}
=> + 2 1                                               C = {x=>(2,B), B}  *
=> 3
</pre>

The result is 3 rather than 4, because at step (*), `y` is mapped to `x`, and `x` is looked up in environment A, where it is defined, but not the latest environment C where is evaluated.

You can get the source code in branches call-by-name and call-by-need via [github](https://github.com/magic003/lambda_calculus_evaluator).
