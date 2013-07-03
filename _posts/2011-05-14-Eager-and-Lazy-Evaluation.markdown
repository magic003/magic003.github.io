---
layout: post
title:  "Eager and Lazy Evaluation"
date:   2011-05-14 10:05:00
categories: tech
---

In the post that [solves the partially reduced problem](2011-04-16-Solving-Partially-Reduced-Problem), we talked about a defective evaluation and a robust one. Though they are quite different, there is one principle that is kept by both of them: evaluating the argument expression before applying it to the function. This is called **eager evaluation**. In our evaluator, the argument won't be applied to the function until it is evaluated to a value. Many programming languages use this eager evaluation strategy, such as C, Java and Scheme. Most programming languages have a *if-statement*: `if condition then-clause else else-clause`. When condition is true, the `then-clause` is executed; otherwise, the `else-clause` is excecuted. At any time, only one of them will be executed. In our evaluator, we use the boolean encoding, which is a function that accepts two parameters, to simulate such *if-statement*. However, it has a different semantic. Since we use eager evaluation, both arguments will be evaluated before applying to the function. Though only one argument is needed, still both are evaluated. This is the problem of implementing `if-statement` using pure functions in an eager evaluation manner(that's why Scheme provide if as a special form instead of a pure function). To solve this, we need the **lazy evaluation**. That is, the argument expression is not evaluated unless it is actually needed in the evaluation of the function body.

These two evaluation strategies will be discussed in detail in the following sections and we will show how to implement them by revising our current evaluator as well.

### Eager Evaluation

As stated above, in eager evaluation, the argument to a function is always evaluated completely before applied to the function. Regarding to whether evaluating the body of a function, it can be further divided to applicative order and call by value.

#### Applicative Order

Though our defective evaluator has "partially reduced problem", we can add a tiny fix to make it work. Since the problem only happens after evaluating the application expression, we can decide whether to keep evaluating after the beta-reduction by checking its result: if it is primitive expression, or it is an application expression and its left child is an abstraction expression, which means the result is reducible, we will continue evaluating the result. Here is the code:

{% highlight c linenos %}
// file: eval.c
TreeNode * evaluate(TreeNode *expr) {
    TreeNode* result = expr;
    if(expr!=NULL) {
        switch(expr->kind) {
            case IdK:
            case ConstK:
                return expr;
            case AbsK:
                expr->children[1] = evaluate(expr->children[1]);
                return expr;
            case AppK:
                expr->children[0] = evaluate(expr->children[0]);
                expr->children[1] = evaluate(expr->children[1]);
                if(expr->children[0]->kind==IdK) {
                    // expand tree node for builtin functions
                    BuiltinFun* fun = lookupBuiltinFun(expr->children[0]->name);
                    if(fun!=NULL) {
                        expr->children[0] = (fun->expandFun)();
                    }
                }
                result = betaReduction(expr);
                // beta-reduction may result in primitive operations
                if(result->kind==PrimiK ||
                    (result->kind==AppK && result->children[0]->kind==AbsK)) {
                    result = evaluate(result);
                }
                return result;
            case PrimiK:
                expr->children[0] = evaluate(expr->children[0]);
                expr->children[1] = evaluate(expr->children[1]);
                // only perform primitive operation if operands are constants
                if(expr->children[0]->kind==ConstK
                    && expr->children[1]->kind==ConstK) {
                    result = evalPrimitive(expr);
                }
                return result;
            default:
                fprintf(errOut,"Unkown expression kind.\n");
        }
    }
    return expr;
}
{% endhighlight %}

In this fixed evaluator, the body of an abstraction expression is evaluated first, and arguments are evaluated from left to right(our syntax gurantees this). We call this **applicative order**(or leftmost innermost). As discussed in the post "[Solving Partially Reduced Problem]({% post_url 2011-04-16-Solving-Partially-Reduced-Problem %})", this strategy can not reduce some expressions though they could be, such as `(lambda x 7) (lambda x (lambda y y y) (lambda y y y))`. Since the body of an abstraction is evaluated first, it will go into an infinite loop when evaluating the body of the argument, though it is never used in the function `(lambda x 7)`.

#### Call by Value

The robust evaluation strategy we use is very common in modern programming languages. Unlike applicative order, it never evaluates the body of an abstraction expression. This is called `call-by-value` evaluation, because every argument must be reduced to a value before calling the function. Obviously, this call-by-value strategy can evaluate the expression referred at the end of last section, because it doesn't evaluate the body of an abstraction expression, but it still has the similar problem. Take `(lambda x 7) ((lambda y y y) (lambda y y y))` as an example, this time we have an application expression as the argument, which cannot be reduced to a value. Apparently, call-by-value evaluation won't compute a value for such cases.

### Lazy Evaluation

From the failed cases in the previous section, we learned that there are cases that argument expressions are never used in the function, so it is not necessary to evaluate them before applying to the function. Why don't we just pass them to the function and evaluate them only when we actually need them? **Lazy evaluation** is such a strategy that doesn't evaluate arguments until they are actually needed in the evaluation of the function body.

#### Normal Order

Normal order(or leftmost outermost) is the counterpart of applicative order in lazy evaluation. Though it doesn't evaluate arguments, it still evaluates the body of a function first, because its goal is to reduce the expression as much as possible. When implementing the evaluator, the right child of the application expression is not evaluated, and it is used directly to substitute the free occurences of the parameter in the body of the function. So if the argument is not used in the function, it will be ignored and never evaluated. Here is the full listing of code:

{% highlight c linenos %}
// file: eval.c
TreeNode * evaluate(TreeNode *expr) {
    TreeNode* result = expr;
    if(expr!=NULL) {
        switch(expr->kind) {
            case IdK:
            case ConstK:
                return expr;
            case AbsK:
                expr->children[1] = evaluate(expr->children[1]);
                return expr;
            case AppK:
                expr->children[0] = evaluate(expr->children[0]);
                if(expr->children[0]->kind==IdK) {
                    // expand tree node for builtin functions
                    BuiltinFun* fun = lookupBuiltinFun(expr->children[0]->name);
                    if(fun!=NULL) {
                        expr->children[0] = (fun->expandFun)();
                    }
                }
                result = betaReduction(expr);
                // beta-reduction may result in primitive operations
                if(result->kind==PrimiK ||
                    (result->kind==AppK && result->children[0]->kind==AbsK)) {
                    result = evaluate(result);
                }
                return result;
            case PrimiK:
                expr->children[0] = evaluate(expr->children[0]);
                expr->children[1] = evaluate(expr->children[1]);
                // only perform primitive operation if operands are constants
                if(expr->children[0]->kind==ConstK
                    && expr->children[1]->kind==ConstK) {
                    result = evalPrimitive(expr);
                }
                return result;
            default:
                fprintf(errOut,"Unkown expression kind.\n");
        }
    }
    return expr;
}
{% endhighlight %}

This strategy can evaluates more expressions than those eager ones, including the two failed expressions referred before. You could try them out.

#### Call by Name

In contrast to normal order, **call-by-name** doesn't evaluate the body of functions. The name of parameter is bound to the argument expression. So as normal order evaluation, every occurence of the parameter in the body of a function is substituted by the argument without evaluation. We implement this evaluator based on the robust evaluation, and only a tiny modification is needed to achieve such a call-by-name evaluator:

{% highlight c linenos %}
// file: eval.c
TreeNode * evaluate(TreeNode *expr) {
    TreeNode* result = expr;
    if(expr!=NULL) {
        switch(expr->kind) {
            case IdK:
            case ConstK:
            case AbsK:
                return expr;
            case AppK:
                expr->children[0] = evaluate(expr->children[0]);
                if(expr->children[0]->kind==IdK) {
                    // expand tree node for builtin functions
                    BuiltinFun* fun = lookupBuiltinFun(expr->children[0]->name);
                    if(fun!=NULL) {
                        expr->children[0] = (fun->expandFun)();
                    } else {
                        fprintf(errOut, "Error: %s is not a builtin function.\n", expr->children[0]->name);
                        return expr;
                    }
                }
                return evaluate(betaReduction(expr));
            case PrimiK:
                expr->children[0] = evaluate(expr->children[0]);
                expr->children[1] = evaluate(expr->children[1]);
                // only perform primitive operation if operands are constants
                if(expr->children[0]->kind==ConstK
                    && expr->children[1]->kind==ConstK) {
                    result = evalPrimitive(expr);
                } else {
                    fprintf(errOut, "Error: %s can only be applied on constants.\n", expr->name);
                }
                return result;
            default:
                fprintf(errOut,"Unkown expression kind.\n");
        }
    }
    return expr;
}
{% endhighlight %}

An imperfect part of call-by-name strategy is that if an argument is used several times in the function, it is re-evaluated each time. So it is often slower than call-by-value. Take `(lambda x + x x) (+ 1 2)` as an example, the parameter `x` is used twice in the function body, so we need to evaluate `(+ 1 2)` twice, while it is evaluated once in the call-by-value evaluation.

### Call by Need

To solve the performance problem of call-by-name, we can save the result of each argument when first time evaluated, and when it is used again, we don't need to evaluate it any more. **Call-by-need** is a memoized version of call-by-name, when the argument is evaluated, the result is stored for subsequent uses. It produces the same result as call-by-name. To implement it, some data structure, such as symbol table, are needed to store the values. Another challenge is arguments are not evaluated in the contexts where they are define. To do this correctly when they are needed, the context in which the argument expression is defined should be attached to it. This requires another important concept called environment and I'd like to implement it in the future.

Now, we have various evalutors with different evaluation strategies in our toolbox. In the future, if I don't emphasize a particular evaluator, that means we are talking about the call-by-value evaluation. Otherwise, I will specify which evaluation strategy we are talking about.

This post only mentioned some common evaluation strategies. For a complete list, please refer to [Evaluation strategy](http://en.wikipedia.org/wiki/Evaluation_strategy). Remember you can still reach the full list of code from [here](https://github.com/magic003/lambda_calculus_evaluator).
