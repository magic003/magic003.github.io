---
layout: post
title:  "CK Machine"
date:   2011-06-11 04:33:00
categories: tech
---

In [CC and SCC machines]({% post_url 2011-05-28-CC-and-SCC-Machine %}), context expands and shrinks when traversing the expression tree in postorder. The nodes in the bottom of the tree are always evaluated before the upper ones. From another perspective, treating the expression as a text string, it is evaluated from innermost to outermost. In the case that the control string is an application, a new innermost application is pushed into the context. In the case that the control string is a value, the innermost application in the context is popped up and the machine decides what to do next by inspecting its shape. I used a first-in last-out list to save the contexts, because the reduction steps only depend on the innermost application, that is the latest context, but not on the rest of the data structure. Compared to the recursive implementation, this iterative evaluator doesn't accumulate runtime stack frames, but this data structure works as an explicit stack in the single runtime stack frame. If the control string is an application, a new "stack frame" is pushed. If it is a value, the top "stack frame" is popped up. Using the control string and information in the popped up "stack frame", the machine decides subsequent actions, performing a reduction or pushing the "stack frame" back. Here is the code snippet making the decision in SCC machine:

{% highlight c linenos %}
// File: eval.c line 92-106 

// control string is the right child
if(state->controlStr==state->context->expr->children[1]) {
    // pop an expression from the context
    state->controlStr = state->context->expr;
    ctx = state->context;
    state->context = state->context->next;
    cc_deleteContext(ctx);
    ctx = NULL;
    if(!performReduction(state)) {
        return NULL;
    }
} else {
    state->controlStr = state->context->expr->children[1];
}
{% endhighlight %}

If the control string is the left child of the innermost application, which means it is the function part, the next action is to evaluate the argument. If it is the right child, which means it is the argument, the next action is to perform reduction on the innermost application. I have to inspect such relationship between the control string and innermost application because I didn't store it in the context, although it is available when the context was created. Look at the following code snippet:

{% highlight c linenos %}
// File: eval.c line 115-119

if(!isValue(state->controlStr->children[0])) {
    state->controlStr = state->controlStr->children[0];
}else {
    state->controlStr = state->controlStr->children[1];
}
{% endhighlight %}

The shape of the application was clearly known when setting the control string. At this phase, the machine was able to determine the actions once control string is evaluated. If the actions are saved in the newly created context, when popped up later the saved actions can be performed directly without inspecting the shape of the application. For ease of implementation, I will tag each context indicating what to do next when it is popped up. This tagged context is called **continuation**. The definition is:

{% highlight c linenos %}
// File: ck_machine.h
/* Kind of each continuation. */
typedef enum {
    FunKK, ArgKK, OprKK, OpdKK
} ContinuationKind;

/* Use a LIFO list to represent the continuation. */
typedef struct continuationStruct {
    ContinuationKind tag;
    TreeNode * expr;
    struct continuationStruct * next;
} Continuation;
{% endhighlight %}

The innermost application is kept in a continuation as `expr`. Four actions are defined, with the first two for applications and the other two for primitive applications. If its is `FunKK`, the next action is to perform reduction on the application; If it is `ArgKK`, the next action is to evaluate the argument expression; If it is `OprKK`, the next action is to evaluate the primitive application; If it is `OpdKK`, the next action is to evaluate the next argument of the primitive application.

### CK Machine

Now, the state of the textual machine is changed to a pair of control string and continuation, and this machine is called a **CK machine**. The reduction rules are similar to that of CC/SCC machine, except for manipulations on continuations:

> 1) If the control string is a value(identifier, constant or abstraction), check the type of continuation:   
>
> > 1\.1) If it is `FunKK` or `OprKK`, pop up the continuation, set the expression in it as control string, and perform reductions;   
> > 1\.2) If it is `ArgKK`, set the continuation to `FunKK`, and set the argument expression as control string;   
> > 1\.3) If it is `OpdKK`, set the continuation to `OprKK`, and set the next argument expression as control string;   
>
> 2) If the control string is an application, create and push a continuation of type `ArgKK`, and set the abstraction expression as control string;   
> 3) If the control string is an primitive, create and push a continuation of type `OpdKK`, and set the first argument as control string.

The primitive application only supports two arguments till now, so the next argument just means the second argument. Here is the code implementing the reduction rules:

{% highlight c linenos %}
// File: eval.c
TreeNode * evaluate(TreeNode *expr) {
    State * state = ck_newState();
    state->controlStr = expr;

    Continuation * ctn = NULL;
    while(!ck_canTerminate(state)) {
        if(isValue(state->controlStr)) {
            switch(state->continuation->tag) {
                case FunKK: // pop up the continuation
                case OprKK:
                    state->controlStr = state->continuation->expr;
                    ctn = state->continuation;
                    state->continuation = ctn->next;
                    ck_deleteContinuation(ctn);
                    ctn = NULL;
                    if(!performReduction(state)) {
                        return NULL;
                    }
                    break;
                case ArgKK: // change continuation to FunKK
                    state->continuation->tag = FunKK;
                    state->controlStr = state->continuation->expr->children[1];
                    break;
                case OpdKK: // change to OprKK
                    state->continuation->tag = OprKK;
                    state->controlStr = state->continuation->expr->children[1];
                    break;
                default:
                    fprintf(errOut,"Error: Unknown continuation tag.\n");
                    ck_cleanup(state);
                    return NULL;

            }
        }else {
            if(state->controlStr->kind==AppK) { // push an ArgKK continuation
                ctn = ck_newContinuation(ArgKK);
            }else if(state->controlStr->kind==PrimiK) { // push OpdKK continuation
                ctn = ck_newContinuation(OpdKK);
            }
            ctn->expr = state->controlStr;
            ctn->next = state->continuation;
            state->continuation = ctn;
            state->controlStr = state->controlStr->children[0];
            ctn = NULL;
        }
        #ifdef DEBUG
        // print intermediate steps
        if(!ck_canTerminate(state)) {
            fprintf(out,"-> ");
            printExpression(ck_getProgram(state),out);
            fprintf(out,"\n");
        }
        #endif
    }

    TreeNode* result = state->controlStr;
    ck_deleteState(state);
    return result;
}
{% endhighlight %}

The implementation is quite simple but I want to add some words about the CC/SCC and CK machine. From the code and reduction rules, the CK machine looks quite similar to that of CC/SCC machine, and there is only a tiny difference, a tag, in the data structure for context and continuation. However, the ideas behind them are really distinct. For a context, it stores the innermost application expression, which can be thought as **data**. While for a continuation, besides such data, it also keeps the information for actions, which can be thought as **code**. In the above implementation, the continuation is attached with a tag, but for other implementations, functions or programs may be attached to make it more usable and flexible. Furthermore, the programmer can even provide a program as actions to continuations explicitly. Another significant difference is: with context, the applications can only be evaluated serially from innermost to outermost, because the relationship of the innermost application and control string is necessary to decide what the next action is. With continuation, this is not required because action is saved in the continuation, and each continuation itself can decide the next action. So in some circumstances, several continuations can be skipped and another continuation can be picked to continue the evaluation. This is essential to control flow and error handling. For example, if an error happens in an application, the machine should go to the function that handles the error, instead of evaluating the next expression in current application. I will go back to this topic in later posts.
