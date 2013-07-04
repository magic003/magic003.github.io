---
layout: post
title:  "Textual Machine"
date:   2011-05-22 12:30:00
categories: tech
---

For a complex expression, such as a recursive function using Y, we may go through dozens of reduction steps until getting to the final result. Currently, our evaluator only gives the final result. However, these intermediate steps are really useful for analysis and troubleshooting sometimes. Just like the manual reductions we did in [last post]({% post_url 2011-05-16-Recursion-and-Y-Combinator %}), we can check whether the evaluator follows the reduction rules by examining the intermediate steps. So in this post, I am going to refactor the implementation of the evaluator so that it is able to print the intermediate reduction steps.

### Recursive Way

An essential task of the evaluator is to find the redex to be reduced next. In our current implementation, we find it in a recursive way. That is, to find a redex in an expression, we try to find it in its child expressions first. If not found, we check if the expression itself is a redex. In this process, the `evaluate` function may call itself for some subexpressions. This keeps the code simple and clean. However, it also puts us in a dilemma that we cannot get the whole picture of the evaluation process. In each function invocation, we are only aware of the expression or subexpression which is under evaluation, but we don't know its role(as a function or an argument) in the original expression, what its parent expression is and so on. All the information is called **evaluation context**. Actually, we do have it in the sequence of C function calls. In the runtime environment of C, the function invocations are stored in a stack, and for each one, there is a stack frame for it, which keeps data for arguments, results and temporary values. So the expression we are currently evaluating is stored in the top stack frame, and its parent is stored in a previous one, and so on. The evaluation context is hidden in the list of stack frames, but we don't have an easy way to get them in C.

A potential solution is to use a global variable pointing to the root of the expression tree and print it after each evaluation step. However, this method may not work for all cases. Take `(lambda x + x x) 1` as an example, after a beta-reduction, the original tree is deleted with a new tree returned as the result, so the global variable becomes a dangling pointer. Even if this could meet our requirement for printing intermediate evaluation steps, we still cannot get more evaluation context information. So I am going to implement the evaluation algorithm in a different way to make the information easy accessible.

### Iterative Way

The problem for recursive way is the evaluation context is saved across many stack frames and only that in the top one is accessible. So a solution we can easily thought of is keeping all the evaluation context information in the same stack frame. We need to get rid of the recursive calls and use an iterative way. To find the redex, we need to traverse the expression tree, and all the work is done in a single `evaluate` function call. Since everything is in the same stack frame now, we are allowed to get anything about the evaluation context.

Based on the call-by-value evaluation strategy, we can derive the following rules to find a redex:

> 1) An identifier, constant or abstraction expression is not a redex;   
> 2) If the expression is an application or primitive application, check its child expressions from left to right, if anyone is not a value, find the redex in it. Otherwise, pick the expression as a redex.

Since the leftmost expression and the argument expression is evaluated first, we need a post-order traversal of the expression tree to find the redex and evaluate it. After each step, a new expression is got and it is closer to the final result. The same post-order traversal will be performed on the expression again and again, until a value is returned. For the case that an expression can never reduce to a value, the evaluator will run forever. For another case that something is wrong in the expression, an error message will be printed and the evaluator will returns `NULL`. The error handling mechanism will be added in the future so values will be returned for erroneous expressions as well. Here is the code for this iterative way:

{% highlight c linenos %}
// file: eval.c
TreeNode * evaluate(TreeNode *expr) {
    TreeNode* state = expr;
    TreeNode** previous = NULL;
    TreeNode* current = NULL;
    while(state!=NULL && !isValue(state)) {
        previous = &state;
        current = state;
        while(current!=NULL) {
            if(!isValue(current->children[0])) {
                previous = &current->children[0];
                current = current->children[0];
            }else if(!isValue(current->children[1])) {
                previous = &current->children[1];
                current = current->children[1];
            }else { // reduce the current node
                if(current->kind==AppK) {   // applications
                    if(current->children[0]->kind==ConstK) {
                        fprintf(errOut, "Error: cannot apply a constant to any argument.\n");
                        fprintf(errOut, "\t\t");
                        printExpression(current,errOut);
                        deleteTree(state);
                        return NULL;
                    }else if(current->children[0]->kind==IdK) {
                        // find function from builtin and standard library
                        TreeNode* fun = resolveFunction(current->children[0]->name);
                        if(fun==NULL) {
                            fprintf(errOut, "Error: %s is not a predefined function.\n", current->children[0]->name);
                            deleteTree(state);
                            return NULL;
                        }
                        deleteTree(current->children[0]);
                        current->children[0] = fun;
                        break;
                    }
                    current=betaReduction(current);
                    *previous = current;
                    break;
                }else if(current->kind==PrimiK) {  // primitive application
                    // only perform primitive operation if operands are constants
                    if(current->children[0]->kind==ConstK
                        && current->children[1]->kind==ConstK) {
                        TreeNode* tmp  = evalPrimitive(current);
                        deleteTree(current);
                        current = tmp;
                        *previous = current;
                        break;
                    } else {
                        fprintf(errOut, "Error: %s can only be applied on constants.\n", current->name);
                        deleteTree(state);
                        return NULL;
                    }
                }else {
                    fprintf(errOut,"Error: Cannot evaluate unkown expression kind.\n");
                    deleteTree(state);
                    return NULL;
                }
            }
        }
        #ifdef DEBUG
        // print intermediate steps
        if(!isValue(state)) {
            fprintf(out,"-> ");
            printExpression(state,out);
            fprintf(out,"\n");
        }
        #endif
    }
    return state;
}
{% endhighlight %}

In the code, variable `state` keeps the intermediate expression during the evaluation, so it is used to print the intermediate steps. Variable `current` points to the subexpression we are currently working with, and `previous` is a pointer to the `current` pointer, so after a beta-reduction or primitive evaluation is performed on the `current` subexpression, we can make the parent of `current` point to the new expression by changing the value of `previous`. The `state` and `previous` variable save part of the evaluation context information, and if others are needed, such as parent expression of the redex, they can be added easily. There are two loops in the code. The outer one runs until the evaluation result is a value, and the inner one implements the post-order traversal to find and evaluate the redex. The `isValue()` function tests if an expression is a value, which is identifier, constant or abstraction for now. The `resolveFunction()` function finds a predefined function from libraries in the order of builtin library and standard library. After each step, the intermediate expression is printed if the `DEBUG` flag is set.

Let's try a simple example:

<pre class="console">
$ ./main
Welcome to Lambda Calculus Evaluator.
Press Ctrl+C to quit.

> (lambda x * 2 x) ((lambda x x) 3)
-> (lambda x * 2 x) 3
-> * 2 3
-> (lambda x (lambda y x `*` y)) 2 3
-> (lambda y 2 `*` y) 3
-> 2 `*` 3
-> 6
</pre>

### Textual Machine

In a real computer, a set of registers is used to keep the computation states, such as PC, and a list of instructions like ADD and MOV can be performed on the state to transform the machine to a new state. Our evaluator can be considered as a machine too. In contrast, the state is the expression, and the instructions are the reductions that transform expressions to expressions. We call this a **textual machine**, because expressions are represented as texts. This is the first textual machine we have implemented, and to improve it, a few more will be introduced in later posts.
