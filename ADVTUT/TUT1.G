#header <<#include "charbuf.h">>

#token "[\t\ ]+"    << zzskip(); >>                /* Ignore White */
#token "\n"         << zzline++; zzskip(); >>
#token STRING "\"(~[\0-\0x1f\"\\]|(\\~[\0-\0x1f]))*\"" <<;>>

<< main() { ANTLR(p(), stdin); } >>

p       :   ( func | "var" def ";" )*
            "@"
        ;

def     :   WORD
        ;

func    :   WORD "\(" { def } "\)"
            "\{"
                ( "var" def ";" )*
                ( statement )*
            "\}"
        ;

statement
        :   expr ";"
        |   "\{" ( statement )* "\}"
        |   "if" "\(" expr "\)" statement {"else" statement}
        |   "while" "\(" expr "\)" statement
        |   "return" expr ";"
        |   "print" expr ";"
        ;

expr    :   WORD "=" expr
        |   expr0
        ;

expr0   :   expr1 ( ("==" | "!=") expr1 )*
        ;

expr1   :   expr2 ( ("\+" | "\-") expr2 )*
        ;

expr2   :   expr3 ( ( "\*" | "/" ) expr3 )*
        ;

expr3   :   {"\-" } expr4
        ;

expr4   :   STRING
        |   WORD { "\(" { expr } "\)" }
        |   "\(" expr "\)"
        ;

#token WORD "[a-zA-Z]+"
