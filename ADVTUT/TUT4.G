#header <<#include "sym.h"
          #include "charbuf.h"
          #define AST_FIELDS int token, level, offset; char str[D_TextSize];
          #define zzcr_ast(ast,attr,tok,text) create_ast(ast,attr,tok,text)
          #define DONT_CARE         0
          #define SIDE_EFFECTS      1
          #define VALUE             2
        >>


#token "[\t\ ]+"    << zzskip(); >>                /* Ignore White */
#token "\n"         << zzline++; zzskip(); >>
#token STRING "\"(~[\0-\0x1f\"\\]|(\\~[\0-\0x1f]))*\"" <<;>>

/* Not actual terminals, just node identifiers */
#token DefineFunc
#token SLIST


/* Define tokens for code generation */
#token DefineVar    "var"
#token Mul          "\*"
#token Div          "/"
#token Add          "\+"
#token Sub          "\-"
#token Equal        "=="
#token NotEqual     "!="
#token If           "if"
#token While        "while"
#token Return       "return"
#token Print        "print"
#token Assign       "="		<<;>>

<<
#define HashTableSize       999
#define StringTableSize     5000
#define GLOBAL              0
#define PARAMETER           1
#define LOCAL               2

static Sym *globals = NULL; /* global scope for symbols */
static int current_local_var_offset=0;

create_ast(ast,attr,tok,text)
AST *ast;
Attrib *attr;
int tok;
char *text;
{
    Sym *s;

    ast->token = tok;
    if ( tok == VAR )
    {
        s = zzs_get(text);
        ast->level = s->level;
        ast->offset = s->offset;
    }
    if ( tok == STRING || tok == VAR || tok == FUNC ) strcpy(ast->str, text);
}


AST *
zzmk_ast(node, token, str)
AST *node;
int token;
char *str;
{
    Sym *s;

    node->token = token;
    if ( token == VAR )
    {
        s = zzs_get(str);
        node->level = s->level;
        node->offset = s->offset;
    }
    if ( token == STRING || token == VAR || token == FUNC )
        strcpy(node->str, str);
    return node;
}


lisp(tree)
AST *tree;
{
    while ( tree!= NULL )
    {
        if ( tree->down != NULL ) printf(" (");
        if ( tree->token == STRING ||
             tree->token == VAR ||
             tree->token == FUNC ) printf(" %s", tree->str);
        else printf(" %s", zztokens[tree->token]);
        lisp(tree->down);
        if ( tree->down != NULL ) printf(" )");
        tree = tree->right;
    }
}


main()
{
    AST *root=NULL;

    zzs_init(HashTableSize, StringTableSize);
    ANTLR(p(&root), stdin);
}


pScope(p)
Sym *p;
{
    for (; p!=NULL; p=p->scope)
    {
        printf("\tlevel %d | %-12s | %-15s\n",
            p->level,
            zztokens[p->token],
            p->symbol);
    }
}
>>


p!      :   <<Sym *p; AST *v;>>
            (   func
            |   "var" def[&globals, GLOBAL] ";"
                <<v = #(#[DefineVar], #2);
				  gen(v,DONT_CARE); printf("\n"); zzfree_ast(v);
/*				  lisp(v); printf("\n"); zzfree_ast(v);*/
                >>
            )*
            <<p = zzs_rmscope(&globals);>>
            "@"
        ;


def[Sym **scope, int level]
        :   <<Sym *var;>>
            (   WORD
                <<zzs_scope($scope);
                  var = zzs_newadd($1.text);
                  var->level = $level;
                  var->token = VAR;
                  var->offset = current_local_var_offset++;
                >>
            |   VAR
                <<var = zzs_get($1.text);
                  if ( $level != var->level )
                  {
                    zzs_scope($scope);
                    var = zzs_newadd($1.text);
                    var->level = $level;
                    var->token = VAR;
                    var->offset = current_local_var_offset++;
                  }
                  else printf("redefined variable ignored: %s\n", $1.text);
                >>
            )
        ;


func!   :   <<Sym *locals=NULL, *var, *p; AST *f,*parm=NULL,*v=NULL,*s=NULL;
              current_local_var_offset = 0;>>
            WORD
            <<zzs_scope(&globals);
              var = zzs_newadd($1.text);
              var->level = GLOBAL;
              var->token = FUNC;
            >>
            "\(" (  def[&locals, PARAMETER] <<parm=#1;>>
                 |  <<current_local_var_offset = 1;>>
                 )
            "\)"
            "\{"
                ( "var" def[&locals, LOCAL]
                  <<if ( v==NULL ) v = #2; else v = #(NULL,v,#2);>>
                  ";"
                )*
                ( statement
                  <<if ( s==NULL ) s = #1; else s = #(NULL,s,#1);>>
                )*
            "\}"
            <<s = #(#[SLIST], s);
              v = #(#[DefineVar], v);
              parm = #(#[DefineVar], parm);
              f = #(#[DefineFunc], #[FUNC,$1.text], parm, v, s);
              gen(f,DONT_CARE); printf("\n"); zzfree_ast(f);
/*              lisp(f); printf("\n"); zzfree_ast(f);*/
              p = zzs_rmscope(&locals);>>
        ;


statement!: <<AST *s=NULL, *el=NULL;>>
            expr ";"                            <<#0 = #1;>>
        |   "\{"
                ( statement
                  <<if ( s==NULL ) s = #1; else s = #(NULL,s,#1);>>
                )*
            "\}"                                <<#0 = #(#[SLIST], s);>>
        |   "if" "\(" expr "\)" statement
            {"else" statement <<el=#2;>>}       <<#0 = #(#[If], #3, #5, el);>>
        |   "while" "\(" expr "\)" statement    <<#0 = #(#[While], #3, #5);>>
        |   "return" expr ";"                   <<#0 = #(#[Return], #2);>>
        |   "print" expr ";"                    <<#0 = #(#[Print], #2);>>
        ;


expr    :   VAR "="^ expr
        |   expr0
        ;


expr0   :   expr1 ( (   "=="^
                    |   "!="^
                    )
                    expr1
                  )*
        ;


expr1   :   expr2 ( (   "\+"^
                    |   "\-"^
                    )
                    expr2
                  )*
        ;


expr2   :   expr3 ( (   "\*"^
                    |   "/"^
                    )
                    expr3
                  )*
        ;


expr3   :   { "\-"^ } expr4
        ;


expr4!  :   <<AST *f=NULL, *arg=NULL;>>
            STRING          <<#0 = #[STRING, $1.text];>>
        |   VAR             <<#0 = #[VAR, $1.text];>>
        |   (   FUNC        <<f  = #[FUNC, $1.text];>>
            |   WORD        <<f  = #[FUNC, $1.text];>>
            )
            "\(" { expr <<arg=#1;>> } "\)"
            <<#0 = #(f, arg);>>
        |   "\(" expr "\)"  <<#0 = #2;>>
        ;


#token WORD "[a-zA-Z]+"
    <<{
        Sym *p = zzs_get(LATEXT(1));
        if ( p != NULL ) NLA = p->token;
    }>>
