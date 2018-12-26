#header <<#include "sym.h"
          #include "charbuf.h"
        >>

#token "[\t\ ]+"    << zzskip(); >>                /* Ignore White */
#token "\n"         << zzline++; zzskip(); >>
#token STRING "\"(~[\0-\0x1f\"\\]|(\\~[\0-\0x1f]))*\"" <<;>>

<<
#define HashTableSize       999
#define StringTableSize     5000
#define GLOBAL              0
#define PARAMETER           1
#define LOCAL               2

static Sym *globals = NULL; /* global scope for symbols */

main()
{
    zzs_init(HashTableSize, StringTableSize);
    ANTLR(p(), stdin);
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

p       :   <<Sym *p;>>
            ( func | "var" def[&globals, GLOBAL] ";" )*
            <<p = zzs_rmscope(&globals);
              printf("Globals:\n");
              pScope(p);
            >>
            "@"
        ;


def[Sym **scope, int level]
        :   <<Sym *var;>>
            (   WORD
                <<zzs_scope($scope);
                  var = zzs_newadd($1.text);
                  var->level = $level;
                  var->token = VAR;
                >>
            |   VAR
                <<var = zzs_get($1.text);
                  if ( $level != var->level )
                  {
                    zzs_scope($scope);
                    var = zzs_newadd($1.text);
                    var->level = $level;
                    var->token = VAR;
                  }
                  else printf("redefined variable ignored: %s\n", $1.text);
                >>
            )
        ;


func    :   <<Sym *locals=NULL, *var, *p;>>
            WORD
            <<zzs_scope(&globals);
              var = zzs_newadd($1.text);
              var->level = GLOBAL;
              var->token = FUNC;
            >>
            "\(" { def[&locals, PARAMETER] } "\)"
            "\{"
                ( "var" def[&locals, LOCAL] ";" )*
                ( statement )*
            "\}"
            <<p = zzs_rmscope(&locals);
              printf("Locals for %s:\n", $1.text);
              pScope(p);
            >>
        ;


statement
        :   expr ";"
        |   "\{" ( statement )* "\}"
        |   "if" "\(" expr "\)" statement {"else" statement}
        |   "while" "\(" expr "\)" statement
        |   "return" expr ";"
        |   "print" expr ";"
        ;


expr    :   VAR "=" expr
        |   expr1
        ;

expr0   :   expr1 ( ("=="|"!=") expr1)*
        ;

expr1   :   expr2 ( ("\+"|"\-") expr2)*
        ;

expr2   :   expr3 ( ("\*"|"/") expr3)*
        ;

expr3   :   {"\-"} expr4
        ;

expr4   :   STRING
        |   ( FUNC | WORD ) "\(" { expr } "\)"
        |   "\(" expr "\)"
        ;


#token WORD "[a-zA-Z]+"
    <<{
        Sym *p = zzs_get(LATEXT(1));
        if ( p != NULL ) NLA = p->token;
    }>>
