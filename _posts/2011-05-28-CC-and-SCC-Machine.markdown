---
layout: post
title:  "CC and SCC Machine"
date:   2011-05-28 09:28:00
categories: tech
---

An obvious inefficiency of our first [textual machine]({% post_url 2011-05-22-Textual-Machine %}) is the repeated traversal of the expression tree to find the redex. After each reduction step, it starts over again from the root node. We really don't have to do this, because the next redex is often the reduction result of current redex, or at least, closes to the current one. Let's consider the evaluation of the following expression:

<pre class="console">
(+ ((lambda x (lambda y y) x) 1) 1)
=> (+ ((lambda y y) 1) 1)
=> (+ 1 1)
=> 2
</pre>

The redex for each step is underlined. In the first two steps, the redex for next step is just the evaluation result of the current redex. And in the third step, the next redex is the parent expression of the result of previous step. Actually, we can identify the next redex by checking the result of current one or its parent for every expression. Suppose the evaluation result of a redex is an application, if either of its children is not a value, the non-value child expression will be the next redex. Otherwise, the result itself will be the next one. Suppose the result is a value, its parent or the other child will probably be the next redex. We didn't do this kind of checking in the textual machine, because we only had the complete expression as our machine state, and the machine were not aware of the result and its parent. Though this could be obtained in the implementation, from the model view, the machine does only know the complete expression. So in this post, two new machines using the strategy will be defined to improve the efficiency.

### CC Machine

According to the discussion above, if the textual machine knows the redex and its parent, it can easily decide what the next redex is, rather than traversing the entire expression tree again. To keep it running until getting the final result, not just the parent of the redex, but also the parent's parent should be recorded. The redex is the machine currently interested in, and it is called **control string**. Except the redex, the other part of the expression is called evaluation **context**, from which all the parents can be obtained. The two elements are paired together to form the machine's state. So this machine is called **CC machine**. Combining the control string and context yields the complete expression, which is the state of the previous machine. I'd like to call the complete expression as **program**. Initially, the program is the control string, and the context is empty. The termination condition of this machine is when the control string is a value and context is empty. Here is the reduction rules for this machine:

> 1) If the control string is a value(identifier, constant or abstraction), remove its parent from the context, and set the parent as control string;   
> 2) If the control string is an application or primitive, and at least one of its children is not a value, put itself into the context and set the non-value child as control string;   
> 3) If the control string is an application or primitive, and both of its children are values, perform reductions on it and set the result as control string.

To find the first redex, we still need to traverse the expression tree, but the traversed nodes should be remembered in the context. Since only the parent of control string is interested for each step, and from each traversed parent, we can navigate to any part of the program, I use a FILO(First-In-Last-Out) list of the traversed nodes to represent the context(Actually, we don't need such kind of data structure if a pointer to parent node is added to each node, but this requires changes to the parser, so I don't choose this option). From the implementation view, the machines perform evaluations by popping and pushing control string into or from the context to find the redex. Here is the definition for machine state and the context:

{% highlight c linenos %}
// file: cc_machine.h
/* Use a LIFO list to represent the context. */
typedef struct contextStruct {
    TreeNode * expr;
    struct contextStruct * next;
} Context;

/* Machine state is a pair of control string and the context. */
typedef struct stateStruct {
    TreeNode * controlStr;
    Context * context;
} State;
{% endhighlight %}

From the reductions rules, we can easily derive the actions on context:

> 1) If the control string is a value, pop the head node from the list and set the node as control string;   
> 2) If the control string is an application or primitive, and at least one of its children is not a value, push it into the head of the list and set the non-value child as control string;   
> 3) If the control string is an application or primitive, and both of its children are values, perform reductions on it and set the result as control string and no action for context.   

Here is the listing of code:

{% highlight c linenos %}
// file: eval.c
TreeNode * evaluate(TreeNode *expr) {
    State * state = cc_newState();
    state->controlStr = expr;

    Context * ctx = NULL;
    while(!cc_canTerminate(state)) {
        if(isValue(state->controlStr)) {
            // pop an expression from the context
            state->controlStr = state->context->expr;
            ctx = state->context;
            state->context = state->context->next;
            cc_deleteContext(ctx);
            ctx = NULL;
        }else {
            if(!isValue(state->controlStr->children[0])
                || !isValue(state->controlStr->children[1])) {
                // push the current expression into context
                ctx = cc_newContext();
                ctx->expr = state->controlStr;
                ctx->next = state->context;
                state->context = ctx;
                if(!isValue(state->controlStr->children[0])) {
                    state->controlStr = state->controlStr->children[0];
                }else {
                    state->controlStr = state->controlStr->children[1];
                }
            } else { // evaluate control string
                if(state->controlStr->kind==AppK) {
                    if(state->controlStr->children[0]->kind==ConstK) {
                        fprintf(errOut, "Error: cannot apply a constant to any argument.\n");
                        fprintf(errOut, "\t\t");
                        printExpression(state->controlStr,errOut);
                        cc_cleanup(state);
                        return NULL;
                    }else if(state->controlStr->children[0]->kind==IdK) {
                        // find function from builtin and standard library
                        TreeNode* fun = resolveFunction(state->controlStr->children[0]->name);
                        if(fun==NULL) {
                            fprintf(errOut, "Error: %s is not a predefined function.\n", state->controlStr->children[0]->name);
                            cc_cleanup(state);
                            return NULL;
                        }
                        deleteTree(state->controlStr->children[0]);
                        state->controlStr->children[0] = fun;
                    } else {
                        TreeNode *tmp = betaReduction(state->controlStr);
                        if(state->context!=NULL) {
                            if(state->context->expr->children[0]==state->controlStr) {
                                state->context->expr->children[0] = tmp;
                            }else {
                                state->context->expr->children[1] = tmp;
                            }
                        }
                        state->controlStr = tmp;
                    }
                }else if(state->controlStr->kind==PrimiK) {
                    // only perform primitive operation if operands are constants
                    if(state->controlStr->children[0]->kind==ConstK
                        && state->controlStr->children[1]->kind==ConstK) {
                        TreeNode* tmp  = evalPrimitive(state->controlStr);
                        if(state->context!=NULL) {
                            if(state->context->expr->children[0]==state->controlStr) {
                                state->context->expr->children[0] = tmp;
                            } else {
                                state->context->expr->children[1] = tmp;
                            }
                        }
                        deleteTree(state->controlStr);
                        state->controlStr = tmp;
                    } else {
                        fprintf(errOut, "Error: %s can only be applied on constants.\n", state->controlStr->name);
                        cc_cleanup(state);
                        return NULL;
                    }
                }else {
                    fprintf(errOut,"Error: Cannot evaluate unkown expression kind.\n");
                    cc_cleanup(state);
                    return NULL;

                }
            }
        }
        #ifdef DEBUG
        // print intermediate steps
        if(!cc_canTerminate(state)) {
            fprintf(out,"-> ");
            printExpression(cc_getProgram(state),out);
            fprintf(out,"\n");
        }
        #endif
    }

    TreeNode* result = state->controlStr;
    cc_deleteState(state);
    return result;
}
{% endhighlight %}

Let's try it:

<pre class="console">
$ ./main
Welcome to Lambda Calculus Evaluator.
Press Ctrl+C to quit.

> (lambda x x) (lambda y y) 1
-> (lambda x x) (lambda y y) 1
-> (lambda y y) 1
-> (lambda y y) 1
-> 1
</pre>

### SCC Machine

Examining the reduction steps at the end of the last section, step 2 and 3 are the same. That's because after step 2, the control string is `(lambda y y)` and the context is the parent of it. Based on the rules, the machine pops the parent and set it as control string. The machine state is changed but not actual reduction is performed on the program, so the program for both steps are the same. After that, beta-reduction is performed on the control string. Actually, we only have two possible actions after step 2: performing beta-reduction or primitive evaluation on the parent node or setting the other child as control string. We can simplify the process by checking the parent node so those two steps can be combined into one. Rule 1) of the CC machine is now revised to:

> 1') If the control string is a value and the other child of its parent is a value too, remove its parent from the context, perform reductions to it and set the result as control string. Otherwise, set the other child as control string.

The code needs only simple changes, so I won't duplicate it here. Here is the evaluation steps for the same expression, and the duplicated step is gone:

<pre class="console">
$ ./main
Welcome to Lambda Calculus Evaluator.
Press Ctrl+C to quit.

> (lambda x x) (lambda y y) 1
-> (lambda x x) (lambda y y) 1
-> (lambda y y) 1
-> 1
</pre>

Compared to CC machine, SCC machile always has less steps. All the code is available at [here](https://github.com/magic003/lambda_calculus_evaluator).
