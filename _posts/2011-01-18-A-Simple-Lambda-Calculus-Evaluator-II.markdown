---
layout: post
title:  "A Simple Lambda Calculus Evaluator - II"
date:   2011-01-18 08:19:00
categories: tech
---

This is the second part of a [series]({% post_url 2011-01-17-A-Simple-Lambda-Calculus-Evaluator-I %}) of posts. In this post, I am going to define the concrete syntax for lambda calculus and generate the scanner and parser using Lex and Yacc(actually, they are Flex and Bison on my machine). Source code is available [here](https://github.com/magic003/lambda_calculus_evaluator).

### Concrete Syntax

I am trying to keep this lambda calculus evaluator really simple and pure. So before bringing you the concrete syntax, I'd like to set some restrictions on the implementation:

> * Variable can only be a single lower case character from the alphabet, a...z.
> * Since natural numbers and booleans can be modeled in lambda calculus, no constant definition is provided in the syntax.
> * Every function is anonymous and only one argument is allowed.
> * All application expressions are left associative.

However, we can get rid of these restrictions very easily by extending the syntax. Derived from the formal definition of lambda calculus, we have following concrete syntax:

<pre class="console">
Expression := identifier |
             (lambda identifier Expression) |
             Expression Expression
</pre>

The first branch defines the variables. The second one defines the abstraction, and the third defines the application. The applications are not enclosed in parentheses, and they will be applied from left to right, so this syntax doesn't support the definitions of natural numbers. Just leave as it is, and we can extend it later.

### Flex & Bison

The scanner and parser can be written by hand, or generated by compiler generating tools. The later method is used in this evaluator. Lex is a program that generates scanner, and it is commonly used with Yacc, which is parser generator. In this lambda calculus evaluator, the open source versions, Flex and Bison, are used. For more information, please refer to this [page](http://dinosaur.compilertools.net/).

### Scanner

The syntax is so simple that only two tokens are defined. The token `LAMBDA` is for keyword "lambda", and the `ID` is for variables. Here is a code snippet of the Flex definition:

<pre class="console">
// file: scanner.l

lambda        "lambda"
identifier    [a-z]
whitespace    [ \t]+
newline       [\r\n]+

%%

{lambda}        {return LAMBDA;}
{identifier}    {return ID;}

{whitespace}    ;
{newline}       ;

.               {return yytext[0];}

%% 
</pre>

Flex will work with Bison, so the token values of `LAMBDA` and `ID` are defined in the Bison definition file. For unmatched character, the ASCII code value will be returned as its token value, so '`(`' and '`)`' can be matched in the bison rules. We will see that in the next section.

### Parser

#### Grammar rules

The BNF grammar is used to describe the syntax in Bison. The above concrete syntax can be simple written as:

<pre class="console">
expression    : ID
              | '(' LAMBDA ID expression ')'
              | expression expression
              ;
</pre>

However, this may cause a reduce/shift conflict for Bison. The parser may be confused by whether do a reduce action or shift, when dealing with the third branch "expression : expression expression". The default action taken by Bison is shift. So the applications will be right associative rather than left associative. We need to revise the syntax to make it left associative:

<pre class="console">
// file: parser.y

expression_list    : expression_list expression
                   | expression
                   ;

expression         : ID
                   | '(' LAMBDA ID expression_list ')'
                   ;
</pre>

#### Tree structure

Before adding the semantic actions for each grammar rule, I'd like to introduce the tree structure constructed after parsing. Our goal is to translate the lambda calculus expressions into a single root tree, which will be passed as an input to the evaluation process. According to the concrete syntax, we have three kinds of expressions: identifier, abstraction and application. Here is the definition:

{% highlight c linenos %}
// file: globals.h

/* expression types */
typedef enum { IdK, AbsK, AppK } ExprKind;
{% endhighlight %}

For the identifier node, only the name need to be saved in the node. For abstraction node, we need to save two child nodes, one for the identifier and the other for the expression. For application node, we also need to save two child nodes, one for the first expression and the other for the second. So we have the tree node definition as follows:

{% highlight c linenos%}
// file: globals.h

#define MAXCHILDREN 2
/* tree nodes */
typedef struct treeNode {
    ExprKind kind;
    char * name;    // only for IdK
    struct treeNode * children[MAXCHILDREN];
} TreeNode;
{% endhighlight %}

Every lambda calculus expression can be represented in such a tree structure. Take `(lambda x x)` a as an example, the syntax tree would look like:

<pre class="console">
Syntax tree:
         AppK
          /\
         /  \
      AbsK  IdK("a")
       /\
      /  \
IdK("x") IdK("x")
</pre>

In Bison, each semantic action returns a value and the default value is int. In order to construct the syntax tree, we need to set the type to TreeNode. This is a code snippet of the declaration section, with token definitions for the scanner:

<pre class="console">
// file: parser.y

%{
...

#define YYSTYPE TreeNode *

extern YYSTYPE tree;
%}

%token  LAMBDA
%token  ID

%start expression_list

%%
</pre>

The `tree` variable will point to the root node of the resulting syntax tree.

#### Constructing syntax tree

Now, we are going to add some C statements in the semantic actions to construct the syntax tree. It is really simple and intuitive. Here is the full list of code:

<pre class="console">
// file: parser.y

%%

expression_list : expression_list expression
                    {
                        $$ = newTreeNode(AppK);
                        $$->children[0] = $1;
                        $$->children[1] = $2;
                        tree = $$;
                    }
                |
                 expression
                    {
                        tree = $1;
                    }
                ;

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
                ;

%%
</pre>

For that last rule, we add a semantic action inside the rule, as a result a temporary node which represents the ID expression will be created by Bison. So the index number should be `4` and `5` instead of `3` and `4` in the last semantic action, which may confuse beginners of Bison. The `newTreeNode(ExprKind kind)` function is a utility to create a tree node of type `kind` in the heap.

After this scan and parse step, a syntax tree represents the lambda calculus expressions is ready for evaluation. In the [next]({% post_url 2011-01-19-A-Simple-Lambda-Calculus-Evaluator-III %}) post, I will show you the evaluation part of this simple lambda calculus evaluator.
