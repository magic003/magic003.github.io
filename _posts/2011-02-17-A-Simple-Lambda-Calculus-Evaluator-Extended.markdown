---
layout: post
title:  "A Simple Lambda Calculus Evaluator - Extended"
date:   2011-02-17 11:10:00
categories: tech
---

In the last three [posts]({% post_url 2011-01-17-A-Simple-Lambda-Calculus-Evaluator-I %}), I implemented a very simple lambda calculus evaluator. However, it still has some syntax restrictions. In this post, I am going to show you how to extend the syntax to get rid of the restrictions. The following two restrictions will be removed:

> * Add syntax support for parentheses around expressions, so natural numbers and fixed points can be represented.
> * Variables are allowed to contain underscores and multiple letters, including both lower and upper cases.    


### Parentheses

Without parentheses, the expressions are evaluated from left to right without exceptions. This prevents us representing the natural numbers and fixed points, which needs to evaluate expressions on the right before left ones. So after adding parentheses, we can support the syntax for them.

Adding parentheses is really straightforward. Only one new rule for the expression needs to be added:

<pre class="console">
// file: parser.y

%%
// the expression_list rule is ignored

expression      : ID    
                    {
                        $$ = newTreeNode(IdK);
                        $$->name = stringCopy(yytext);
                    }
                | '(' LAMBDA ID 
                    {
                        $$ = newTreeNode(IdK);
                        $$->name = stringCopy(yytext);
                    } 
                    expression_list ')'
                    {
                        $$ = newTreeNode(AbsK);
                        $$->children[0] = $4;
                        $$->children[1] = $5;
                    }
                | '(' expression_list ')'
                    {
                        $$ = $2;
                    }
                   ;
</pre>

That's all we need to do. Now, let's try some expressions:

$ ./main
Welcome to Lambda Calculus Evaluator.
Press Ctrl+C to quit.

<pre class="console">
> (u ((lambda x x) v))
-> u v

> (lambda f (lambda x f (f x)))
-> (lambda f (lambda x f (f x)))

> (lambda g (lambda x g (x x)) (lambda x g (x x))) g
-> g ((lambda x g (x x)) (lambda x g (x x)))
</pre>

Note: to print the expression corretly, the `printExpression()` method should print parentheses around the right part of an application expresion if itself is an application expression.

### Variables

It is common to have identifiers consist of multiple letters in many programming languages. To implement this extension is even more simple. We only need to change the definition for token `identifier` in file `scanner.l`:

<pre class="console">
// file: scanner.l

// ...
identifier    [A-Za-z_]+
// ...

%%
</pre>

When performing alpha conversion on an expression, a new variable name is chosen. Though the old algorithm for picking a new name is still working for multiple-letter variables, we will use a new safer one. The algorithm is simple: appending underscores(`_`) to the old variable.

Here is the code snippet for alpha-conversion:

{% highlight c linenos %}
TreeNode * alphaConversion(TreeNode *expr) {

    VarSet* set = FV(expr->children[1]);
    char *name = NULL;
    int len = strlen(expr->children[0]->name);
    int attempts = 0;
    // pick a new name
    do {
        if(name!=NULL) free(name);  // free the last attempt
        attempts++;
        name = malloc(len+attempts);
        strcpy(name,expr->children[0]->name);
        int a;
        // append '_' to the original name
        for(a=0;a<attempts;a++) { 
            strcat(name,"_");
        }
    } while(strcmp(name,expr->children[0]->name)==0 || contains(set,name)==1);

    TreeNode *var = newTreeNode(IdK);
    var->name = name;
    TreeNode *result = substitute(expr->children[1], expr->children[0], var);

    expr->children[1] = result;
    expr->children[0] = var;
    return expr;
}
{% endhighlight %}

Let's try some expressions:

<pre class="console">
$ ./main
Welcome to Lambda Calculus Evaluator.
Press Ctrl+C to quit.

> X
-> X

> var
-> var

> a_
-> a_

> (lambda name name)
-> (lambda name name)

> say hello
-> say hello
</pre>

All the source code could be checked out [here](https://github.com/magic003/lambda_calculus_evaluator).
