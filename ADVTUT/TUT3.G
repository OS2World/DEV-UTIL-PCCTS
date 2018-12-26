#header <<#include "sym.h"
          #include "charbuf.h"
        >>

#token "[\t\ ]+"  << zzskip(); >>                /* Ignore White */
#token "\n"       << zzline++; zzskip(); >>
#token STRING     "\"(~[\0-\0x1f\"\\]|(\\~[\0-\0x1f]))*\"" <<;>>


<<
#define HashTableSize       999
#define StringTableSize     5000
#define GLOBAL              0
#define PARAMETER           1
#define LOCAL               2

static Sym *globals = NULL; /* global scope for symbols */
static int current_local_var_offset, LabelNum=0;


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


p       :   <<Sym *p; printf("#include \"sc.h\"\n"); >>
            ( func | "var" def[&globals, GLOBAL] ";" )*
            <<  p = zzs_rmscope(&globals); >>
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
                  switch(var->level) {
                        case GLOBAL: printf("SCVAR %s;\n", $1.text); break;
                        case  LOCAL : printf("\tLOCAL;\n"); break;
                  }
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

                    switch(var-> level) {
                        case GLOBAL: printf("\tSCVAR %s;\n",$1.text);break;
                        case  LOCAL : printf("\tLOCAL;\n"); break;
                    }
                  }
                  else printf("redefined variable ignored: %s\n",$1.text);
                >>
            )
        ;


func :  <<Sym *locals=NULL, *var, *p; current_local_var_offset = 0;>>
            WORD
            <<zzs_scope(&globals);
              var = zzs_newadd($1.text);
              var->level = GLOBAL;
              var->token = FUNC;

              if (strcmp("main",$1.text)) { printf("%s()\n",$1.text); }
              else printf("_main()\n");
            >>
            "\(" (  def[&locals, PARAMETER]
                 |  <<current_local_var_offset = 1;>>
                 )
            "\)"
            "\{" << printf("{\n\tBEGIN;\n"); >>
                ( "var" def[&locals, LOCAL] ";" )*
                ( statement )*
            "\}" << printf("\tEND;\n}\n"); >>
            <<  p = zzs_rmscope(&locals); >>
        ;


statement : expr ";"            <<printf("\tPOP;\n");>>
        |   "\{" ( statement )* "\}"
        | "if" "\(" expr "\)"   << printf("\tBRF(iflabel%d);\n",LabelNum); >>
                statement       << printf("iflabel%d: ;\n",LabelNum++);>>
            {"else" statement}
        |
            "while"             << printf("wbegin%d: ;\n", LabelNum); >>
            "\(" expr "\)"      << printf("\tBRF(wend%d);\n",LabelNum); >>
            statement           << printf("\tBR(wbegin%d);\n", LabelNum); >>
                                << printf("wend%d: ;\n",LabelNum); >>
                                << LabelNum++; >>
        |   "return" expr ";"   << printf("\tRETURN;\n"); >>
        |   "print" expr ";"    << printf("\tPRINT;\n"); >>
        ;


expr    :   <<Sym *s;>>
            VAR "=" expr        << printf("\tDUP;\n"); >>
            <<s = zzs_get($1.text);
              if ( s->level != GLOBAL )
                printf("\tLSTORE(%d);\n", s->offset);
              else printf("\tSTORE(%s);\n", s->symbol);
            >>
        |   expr0
        ;

expr0   :   <<char *op;>>
            expr1 ( (   "==" <<op="EQ";>>
                    |   "!=" <<op="NEQ";>>
                    )
                    expr1
                    <<printf("\t%s;\n", op);>>
                  )*
        ;


expr1   :   <<char *op;>>
            expr2 ( (   "\+" <<op="ADD";>>
                    |   "\-" <<op="SUB";>>
                    )
                    expr2
                    <<printf("\t%s;\n", op);>>
                  )*
        ;

expr2   :   <<char *op;>>
            expr3 ( (   "\*" <<op="MUL";>>
                    |   "/"  <<op="DIV";>>
                    )
                    expr3
                    <<printf("\t%s;\n", op);>>
                  )*
        ;


expr3   :   <<char *op=NULL;>>
            {"\-" <<op="NEG";>>} expr4
            <<if ( op!=NULL ) printf("\t%s;\n", op);>>
        ;

expr4   :   <<Sym *s; int arg;>>
            STRING   << printf("\tSPUSH(%s);\n", $1.text); >>
        |   VAR     << s = zzs_get($1.text);
                       if ( s->level != GLOBAL )
                            printf("\tLPUSH(%d);\n", s->offset);
                       else printf("\tPUSH(%s);\n", s->symbol);
                    >>
        |   (   FUNC    <<$0=$1;>>
            |   WORD    <<$0=$1;>>
            )
            "\(" { <<arg=0;>> expr <<arg=1;>> } "\)"
            <<if ( !arg ) printf("\tSPUSH(\"\");\n");
              printf("\tCALL(%s);\n", $1.text);>>
        |   "\(" expr "\)"
    ;


#token WORD "[a-zA-Z]+"
    <<{
        Sym *p = zzs_get(zzlextext);
        if ( p != NULL ) NLA = p->token;
    }>>
