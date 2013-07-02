---
layout: post
title:  "A Simple Lambda Calculus Evaluator - III"
date:   2011-01-19 18:19:00
categories: tech
---

In the [previous](/tech/2011/01/18/A-Simple-Lambda-Calculus-Evaluator-II.html) post, we translated the lambda calculus expressions into a syntax tree using some compiler generate tools. Now, we are about to evaluate it by traversing the syntax tree. First, I will introduce the evaluation algorithm in this post. Then, the implementation is presented along with some code snippet. Finally, an interactive interface which combines all the parts together is implemented. The full source code can be checkout [here](https://github.com/magic003/lambda_calculus_evaluator).

### Evaluation Algorithm

For the evaluation algorithm, we have a syntax tree as the input, and as a result we are also going to output a syntax tree which is evaluated from the original one.

Let's consider the simple case first, an identifier node which doesn't have any child node, the node should evaluate to itself because no reduction can be applied to it. For the abstraction node, which has an identifier child node and another expression child node, which it is a syntax tree itself. The expression child node will be evaluated first and the resulting node will be set as the expression child node. The other part will stay the same. For an application node, which has two expression child nodes, both of them will be evaluated first and replaced by the resulting nodes. Finally according to the semantic of lambda application, a beta-reduction should be performed on the application node because the beta-reduction captures the idea of function application.

From the analysis above, we can work out a recursive algorithm which does a deep-first traversal on the syntax tree and evaluates the syntax tree in a bottom-up manner. Here is the psuedocode:

<pre class="console">
evaluate(tree):
    if tree is identifier node:
        return tree;
    else if tree is abstraction node:
        tree->right = evaluate(tree->right);
        return tree;
    else if tree is application node:
        tree->left = evaluate(tree->left);
        tree->right = evaluate(tree->right);
        tree = betaReduction(tree);
        return tree;
</pre>

Now, the problem is reduced to the beta-reduction of a lambda calculus expression. In the [first post](/tech/2011/01/17/A-Simple-Lambda-Calculus-Evaluator-I.html), we learned that the beta-reduction can be simple defined in terms of substitution, so again our problem is reduced to implement the substitution algorithm of expressions. We can simply derive a recursive algorithm from the substitution rules defined in the [first post](/tech/2011/01/17/A-Simple-Lambda-Calculus-Evaluator-I.html):

<pre class="console">
substitute(tree, var, sub):
    if tree is identifier node:
        if tree.name equals var.name:
            return sub;
        else:
            return tree;
    else if tree is application node:
        tree->left = substitute(tree->left, var, sub);
        tree->right = substitute(tree->right, var, sub);
        return tree;
    else if tree is abstraction node:
        if tree.name not equals var.name:
            if tree->left is a free variable in sub:
                tree = alpahReduction(tree);
            tree->right = substitute(tree->right, var, sub);
        return tree;
</pre>

Pay attention to the abstraction node case, we check the conditions in the last rule. If the condition is not met, an alpha-reduction is applied to the syntax tree before doing substitution.

There are two remaining problems: alpha-conversion and free variables. The definition of free variables in the [first post](/tech/2011/01/17/A-Simple-Lambda-Calculus-Evaluator-I.html) is very straightforward, so I won't duplicate the algorithm here. With regard to alpha-conversion, the process consists of the following steps:

> 1. Find the set of free variables of the expression child node;
> 2. Pick a new identifier name which is different from the old one and not in the free variable set in step 1;
> 3. Substitute all free occurrences of the identifier in expression child node with the new identifier;
> 4. Replace the old identifier node with the new one.

In step 3, the substitute procedure above will be used. All the algorithms used for this evaluator has been presented, now we are going to write the codes.

### Implementation

It's time to implement the evaluator. The code snippet of different algorithms will be shown in this section. To emphasize the most important part, the error handling and memory release stuff is ignored.

First and foremost, let's see the function that finds the free variable set of an expression.

{% highlight c linenos %}
static VarSet * FV(TreeNode *expr) {
    VarSet* set = NULL;
    VarSet* set1 = NULL;
    VarSet* set2 = NULL;
    switch(expr->kind) {
        case IdK:
            set = newVarSet();
            addVar(set,expr->name);
            break;
        case AbsK:
            set = FV(expr->children[1]);
            deleteVar(set,expr->children[0]->name);
            break;
        case AppK:
            set = newVarSet();
            set1 = FV(expr->children[0]);
            set2 = FV(expr->children[1]);
            unionVarSet(set,set1,set2);
            break;
        default:
            fprintf(errOut,"Unknown expression type.\n");
    }
    return set;
}
{% endhighlight %}

The `VarSet` is a data structure that represents a set of variables. It uses an inner hashtable to store the variables. The functions, `newVarSet`, `addVar`, `deleteVar`, `unionVarSet`, are very intuitive by their names. Refer to file `varset.c` for information about the `VarSet` implementation.

The code snippet for alpha-conversion is like:

{% highlight c linenos %}
TreeNode * alphaConversion(TreeNode *expr) {
    VarSet* set = FV(expr->children[1]);
    char * name = strdup(expr->children[0]->name);
    // pick a new name
    while(strcmp(name,expr->children[0]->name)==0 ||  contains(set,name)==1) {
        char lastchar = name[strlen(name)-1];
        name[strlen(name)-1] = 'a' + (lastchar+1-'a')%('z'-'a'+1);
    }
    TreeNode *var = newTreeNode(IdK);
    var->name = name;
    TreeNode *result = substitute(expr->children[1], expr->children[0], var);

    expr->children[1] = result;
    expr->children[0] = var;
    return expr;
}
{% endhighlight %}

The method for picking a new variable name is: replace the last character of the variable by a letter comes after it in the alphabet. This works for most cases though it may failed if all the attempted names are used up.

Here comes the most important function, `substitute`, which is used by both alpha-conversion and beta-reduction:

{% highlight c linenos %}
static TreeNode *substitute(TreeNode *expr, TreeNode *var, TreeNode *sub) {
    const char * parname = NULL;
    TreeNode * result = NULL;
    switch(expr->kind) {
        case IdK:
            if(strcmp(expr->name,var->name)==0) {
                return sub;
            }else {
                return expr;
            }
        case AbsK:
            parname = expr->children[0]->name;
            if(strcmp(parname,var->name)!=0) {
                VarSet* set = FV(sub);
                while(contains(set,parname)) {  // do alpha conversion
                    expr = alphaConversion(expr);
                    parname = expr->children[0]->name;
                }
                result = substitute(expr->children[1],var,sub);
                expr->children[1] = result;
            }
            return expr;
        case AppK:
            result = substitute(expr->children[0],var,sub);
            expr->children[0] = result;
            result = substitute(expr->children[1],var,sub);
            expr->children[1] = result;
            return expr;
        default:
            fprintf(errOut,"Unknown expression type.\n");
    }
    return expr;
}
{% endhighlight %}

It recursively applies itself to the child nodes of the expression.

Now, we can deal with the beta-reduction:

{% highlight c linenos %}
TreeNode * betaReduction(TreeNode *expr) {
    TreeNode* left = expr->children[0];
    if(left->kind==IdK || left->kind==AppK) {
        return expr;
    }else if(left->kind==AbsK) {
        TreeNode* result = substitute(left->children[1],left->children[0],expr->children[1]);
        return result;
    }
    return expr;
}
{% endhighlight %}

Finally, all the build blocks are ready. We can implement the main evaluation function:

{% highlight c linenos %}
TreeNode * evaluate(TreeNode *expr) {
    if(expr!=NULL) {
        switch(expr->kind) {
            case IdK:
                return expr;
            case AbsK:
                expr->children[1] = evaluate(expr->children[1]);
                return expr;
            case AppK:
                expr->children[0] = evaluate(expr->children[0]);
                expr->children[1] = evaluate(expr->children[1]);
                return betaReduction(expr);
            default:
                fprintf(errOut,"Unkown expression kind.\n");
        }
    }
    return expr;
}
{% endhighlight %}

### Evaluator Driver

Different parts, including scanner, parser and evaluator, has been implemented separately. We need a driver method to combine them all, and it should provides an interactive interface which reads a lambda calculus expression from user input and output the evaluated expression in a human-readable format.

Here is the code:

{% highlight c linenos %}
FILE* in;
FILE* out;
FILE* errOut;

TreeNode * tree = NULL;    // used in the parser

#define BUFF_SIZE 255

int main(int argc, char* argv[]) {
    in = stdin;
    out = stdout;
    errOut = stderr;

    char buff[BUFF_SIZE];

    fprintf(out,"Welcome to Lambda Calculus Evaluator.\n");
    fprintf(out,"Press Ctrl+C to quit.\n\n");
    while(1) {
        fprintf(out,"> ");
        fgets(buff,BUFF_SIZE-1,in);
        yy_scan_string(buff);
        yyparse();

        tree = evaluate(tree);
        fprintf(out,"-> ");
        printExpression(tree);
        deleteTreeNode(tree);
        tree=NULL;
        yy_delete_buffer();
        buff[0] = EOF;
        fprintf(out,"\n\n");
    }
    return 0;
}
{% endhighlight %}

We set the standard input as the input and standard output as the output. The library function `fgets()` is used to read the user input. We use `yy_scan_string()` to feed the user input to the parser, so the parser will read input from this buffer rather than the standard input. The `yyparse()` function is the interface exposed by Yacc to run the parser. The `printExpression()` function is a utility that prints the expression in a human-readable format.

Let's try some expressions:

<pre class="console">
$ ./main
Welcome to Lambda Calculus Evaluator.
Press Ctrl+C to quit.

> a
-> a

> (lambda x (lambda y y) a)
-> (lambda x a)

> (lambda x x) a
-> a
</pre>

### Conclusion

This [series](/tech/2011/01/17/A-Simple-Lambda-Calculus-Evaluator-I.html) of post introduces how to write a very simple evaluator for lambda calculus. It covers the topics about scanner, parser and evaluator. In order to keep it really pure, there are some limitations of the syntax, such as not constant support, cannot place parentheses around expressions to change the evaluation order from left to right. However, it is rather easy to support those features by extending the syntax. We can do it in the future.

### References

1. [Lambda Calculus](http://en.wikipedia.org/wiki/Lambda_calculus) on Wikipedia.

2. [The LEX & YACC Page](http://dinosaur.compilertools.net/).

3. A [lecture notes](http://www.cs.uiowa.edu/%7Ehzhang/c123/Lecture5.pdf) about lambda calculus, including a lambda calculus evaluator.
