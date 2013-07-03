---
layout: post
title:  "Constants and Builtin Functions"
date:   2011-04-06 11:05:00
categories: tech
---

In last series of posts "[A Simple Lambda Calculus Evaluator]({% post_url 2011-01-17-A-Simple-Lambda-Calculus-Evaluator-I %})", we implemented a very simple evaluator for pure lambda calculus. Though it performs reductions to lambda calculus expressions, it is still far from a real programming language. In this series of posts, I would like to add some important features to make it evolve towards a real programming language, including constants and builtin functions, a new evaluation strategy, recursion and text machines. Since this series is inspired by the paper "Programming Languages and Lambda Calculi", I will follow the terms defined in it.

Natural numbers could be encoded using basic lambda calculus. However, this is not very convenient. In this post, constants and builtin functions will be added to the evaluator as in many real programming languages, though it destroys the purity.

### Constants

First, we will add the most common constants, integer, to our evaluator. To make the evaluator recognize integer values, both positive and negative, the regular expression and rules are added to file `scanner.l`:

<pre class="console">
// file: scanner.l

lambda    "lambda"
integer   [+-]?[0-9]+
// others remain as before

%%
/* reserved words */
{lambda}        {return LAMBDA;}

/* constants */
{integer}       {return INT;}

// others remain as before
%%
</pre>

And the token definition in `parser.y`:

<pre class="console">
// file: parser.y

%token  INT

%%
</pre>

A new expression type named `ConstK` should be added for constants. The tree node structure should also be updated to hold the integer value. I will not display the code here. The parsing rule is very straightforward: create a tree node of type `ConstK`, and save the value in it.

<pre class="console">
// file: parser.y

expression      : ID    
                    {
                        $$ = newTreeNode(IdK);
                        $$->name = stringCopy(yytext);
                    }
                | INT
                    {
                        $$ = newTreeNode(ConstK);
                        $$->value = atoi(yytext);
                    }
                | // other rules are ignored here
</pre>

Now, we need to update our two main algorithms, `FV` and `substitute`, for this new expression. For `FV`, since it is not a variable, the result should be an empty set. For `substitute`, we don't do any substitution and just return the constant:

> `c[x := N] = c, if c is a constant`

It's time to update our implementation. The `FV()` function will be updated to:

{% highlight c linenos %}
// file: eval.c

static VarSet * FV(TreeNode *expr) {
    VarSet* set = NULL;
    VarSet* set1 = NULL;
    VarSet* set2 = NULL;
    switch(expr->kind) {
        case IdK:
            set = newVarSet();
            addVar(set,expr->name);
            break;
        case ConstK:
            set = newVarSet();
            break;
        // ...
    }
    return set;
}
{% endhighlight %}

And for `substitute()`, we just return the constant expression:

{% highlight c linenos %}
// file: eval.c

static TreeNode *substitute(TreeNode *expr, TreeNode *var, TreeNode *sub) {
    // ...
    switch(expr->kind) {
        case IdK:
            // ...
        case ConstK:
            return expr;
        // ...
    }
    return expr;
}
{% endhighlight %}

Finally, if a constant expression is evaluated, itself should be returned:

{% highlight c linenos %}
// file: eval.c

TreeNode * evaluate(TreeNode *expr) {
    if(expr!=NULL) {
        switch(expr->kind) {
            case IdK:
            case ConstK:
                return expr;
            // ...
        }
    }
    return expr;
}
{% endhighlight %}

We have finished adding constant to our lambda calculus evaluator, nice and easy. And don't forget to update the `printExpression()` function to print constants to user.

### Builtin Functions

We have constants now, but it is still useless because we can't do computation on them. We are going to add two sets of operators: arithmetic operators and comparison operators. The arithmetic operator set includes six basic ones: plus(+), minus(-), times(*), over(/), modulo(%) and power(^). And the comparison operator set includes less than(\<), equal(\=), greater than(\>), less than or equal(<=), not equal(!=) and greater than or equal(>=). Each of them is a binary operator, and we could simple add a primitive operator for each one which takes two arguments. However, this is not a good idea. In our current lambda calculus model, every function can only be applied on one argument. If we add the primitive operators directly to the evaluator, it would make our model inconsistent. Our goal is to make these operators behave as a normal function so programmers aren't required to distinguish whether this is a function or primitive operator.

As stated in the past post, any function that takes two arguments can be treated as a function that takes one argument and returns another function that takes one argument. So we can apply the same method to the operators. Our solution is: when an operator is encountered, expand it as a function that takes one argument and returns another function, which take one argument and returns the result of applying the corresponding operator to those arguments. Take `+` as an example:

{% highlight scheme %}
+    => (lambda x (lambda y x `+` y))
{% endhighlight %}

The ``+``(enclosed with backticks) stands for primitive plus. We still have primitive operators internally, but the programmer doesn't need to be aware of it. I'd like to call the operator before expanding as **builtin function**, and the binary operator as **primitive operator**. The builtin function looks the same as others functions defined by the programmer.

Now, let's implement the builtin functions.

#### Arithmetic Functions

First, we should make our scanner recognize the operator symbols. Since an operator symbol represents a builtin function, we will treat it as an identifier - identifier for a function :). The identifier definition in `scanner.l` is changed to:

<pre class="console">
// file: scanner.l

// ...
identifier  [A-Za-z_]+|[+\-*/%^<=>]
// ...

%%
</pre>

Now, the arithmetic builtin functions are analyzed as `IdK` tokens. Nothing should be updated for the parser and we get a tree node of type `IdK` for each builtin function.

The evaluation logic needs to be rework for builtin functions. When evaluating an application expression, the left child tree node should be expanded if it is a builtin function. So the `evaluate()` function is revised to:

{% highlight c linenos %}
// file: eval.c

TreeNode * evaluate(TreeNode *expr) {
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
                    BuiltinFun* fun = lookupBuiltinFun(expr->children[0]->name);
                    if(fun!=NULL) {
                        expr->children[0] = (fun->expandFun)();
                    }
                }
                return betaReduction(expr);
            default:
                fprintf(errOut,"Unkown expression kind.\n");
        }
    }
    return expr;
}
{% endhighlight %}

We examine the left child tree node and replace it with the expanded tree if it is of `IdK` type and is a builtin function. The `lookupBuiltinFun()` and other definitions related to builtin functions are all defined in file `builtin.c`. For each builtin function, we provide a corresponding expand function which returns the expanded tree for it. To save space, I won't duplicate the codes here. Take `+` as an example, it will be expanded as follows:

`+ => (lambda x (lambda y x `+` y))`:

<pre class="console">
      AbsK
       /\
      /  \
IdK("x") AbsK
          /\
         /  \
    IdK("y") ?
</pre>

We haven't add the primitive node yet! It is a tree node and we need to add a new expression type `PrimiK` for it.

{% highlight c linenos %}
// file: globals.h

/* expression types */
typedef enum { IdK, ConstK, AbsK, AppK, PrimiK } ExprKind;
{% endhighlight %}

We could reuse the current tree node structure to represent a primitive operator: set operator name as the node name and keep the left hand side operand in the first child node and right operand in the second one. So the "?" place in the above tree can be replaced with:

`x `+` y`:

<pre class="console">
    PrimiK("+")
       /\
      /  \
IdK("x") IdK("y")
</pre>

This `PrimiK` expression is hidden from the programmer, so no `FV()` or `substitute()` could be applied on it. When evaluating a `PrimiK` expression, we only perform primitive operation if both operands are reduced to constants, because it doesn't make sense to do arithmetic on variables or functions.

{% highlight c linenos %}
// file: eval.c
reeNode * evaluate(TreeNode *expr) {
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
                    BuiltinFun* fun = lookupBuiltinFun(expr->children[0]->name);
                    if(fun!=NULL) {
                        expr->children[0] = (fun->expandFun)();
                    }
                }
                return betaReduction(expr);
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

The primitive evaluation is implemented in file `primitive.c`. For each arithmetic operator, a tree node of type `PrimiK` is required as input, a tree node of type `ConstK` is returned after applying the operator to its operands. For `+`, we have:

{% highlight c linenos %}
// file: primitive.c
static TreeNode* plus(TreeNode* node) {
    TreeNode* result = newTreeNode(ConstK);
    result->value = node->children[0]->value + node->children[1]->value;
    return result;
}
{% endhighlight %}

The `printExpression()` should also be updated to print `PrimiK` expressions. Now, let's try it.

<pre class="console">
$ ./main
Welcome to Lambda Calculus Evaluator.
Press Ctrl+C to quit.

> + 1 2
-> 1 `+` 2
</pre>

Unfortunately, the final answer doesn't show up. The result is an expression of `PrimiK` type. That's because after applying the second argument `2` to the inner function of `+`, we end up with the `PrimiK` expression, and it is returned without further evaluation. I call this a "partially reduced problem" because the returned expression is a **redex**, which means it can be reduced. Actually, this is a defect of our evaluator and it doesn't just happen for the current case. However, I will postpone the detail discussion to next post, and for now I am going to add a fix for our special case. Evaluate the expression if it is a `PrimiK` expression.

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
                    BuiltinFun* fun = lookupBuiltinFun(expr->children[0]->name);
                    if(fun!=NULL) {
                        expr->children[0] = (fun->expandFun)();
                    }
                }
                result = betaReduction(expr);
                // beta-reduction may result in primitive operations
                if(result->kind==PrimiK) {
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

Let's try it again:

<pre class="console">
$ ./main
Welcome to Lambda Calculus Evaluator.
Press Ctrl+C to quit.

> + 1 2
-> 3
</pre>

#### Comparison Functions

Adding comparison functions is very similar to that of arithmetic functions. The only difference is the primitive evaluation method. For arithmetic functions, the return value should be a constant expression. For our current implementation, it is an integer. However, comparison functions should return a boolean value. Though we don't support builtin boolean values, we could use the method in post [I]({% post_url 2011-01-17-A-Simple-Lambda-Calculus-Evaluator-I %}) to define booleans:

> `TRUE   := (λx. (λy. x))`   
> `FALSE  := (λx. (λy. y))`

So the primitive evaluation for comparison functions will return an abstraction expression. And we can use it to construct an _if_-like expression.

<pre class="console">
$ ./main
Welcome to Lambda Calculus Evaluator.
Press Ctrl+C to quit.

> < 1 2
-> (lambda x (lambda y x))

> (< -1 0) 0 1
-> 0
</pre>

Now, our evaluator can work as a simple calculator. Try more expressions and have fun. In the next post, we are going to solve the "partially reduced problem".

The full listing of code could be found [here](https://github.com/magic003/lambda_calculus_evaluator).
