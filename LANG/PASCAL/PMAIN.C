/*  Pascal grammar
 *
 */

#include <stdio.h>
#ifdef __STDC__
#include <stdlib.h>
#else
#include <malloc.h>
#endif
#include "stdpccts.h"

#define SymStrTable		10000
#define HashSize		10001

struct _pre {
	char *symbol;
	int token;
};

struct _pre predef[] = {
	/* keywords */
	{ "and", And },
	{ "array", Array },
	{ "begin", Begin },
	{ "case", Case },
	{ "const", Const },
	{ "div", Div },
	{ "do", Do },
	{ "downto", Downto },
	{ "else", Else },
	{ "end", End },
	{ "file", File },
	{ "for", For },
	{ "forward", Forward },
	{ "function", Function },
	{ "goto", Goto },
	{ "if", If },
	{ "in", In },
	{ "label", Label },
	{ "mod", Mod },
	{ "nil", Nil },
	{ "not", Not },
	{ "of", Of },
	{ "or", Or },
	{ "packed", Packed },
	{ "procedure", Procedure },
	{ "program", Program },
	{ "record", Record },
	{ "repeat", Repeat },
	{ "set", Set },
	{ "then", Then },
	{ "to", To },
	{ "type", Type },
	{ "until", Until },
	{ "var", Var },
	{ "while", While },
	{ "with", With },

	 /* Predefined Constants */
	{ "maxint", ConstID },
	{ "true", ConstID },
	{ "false", ConstID },

	 /* Predefined Types */
	 {"real", TypeID},
	 {"boolean", TypeID},
	 {"char", TypeID},
	 {"integer", TypeID},
	 {"text", TypeID},

	 /* Predefined Functions */
	 { "odd", FuncID },
	 { "eoln", FuncID },
	 { "eof", FuncID },
	 { "abs", FuncID },
	 { "sqr", FuncID },
	 { "sin", FuncID },
	 { "cos", FuncID },
	 { "arctan", FuncID },
	 { "ln", FuncID },
	 { "exp", FuncID },
	 { "sqrt", FuncID },
	 { "ord", FuncID },
	 { "chr", FuncID },
	 { "pred", FuncID },
	 { "succ", FuncID },
	 { "round", FuncID },
	 { "trunc", FuncID },

	 /* Predefined Procedures */
	 { "put", ProcID },
	 { "get", ProcID },
	 { "reset", ProcID },
	 { "rewrite", ProcID },
	 { "new", ProcID },
	 { "dispose", ProcID },
	 { "read", ProcID },
	 { "readln", ProcID },
	 { "write", ProcID },
	 { "writeln", ProcID },
	 { "page", ProcID },

	 {NULL, 0}
};

main(argc, argv)
int argc;
char *argv[];
{
	Sym *p;
	FILE *f;
	
/*	if ( argc==1 ) {fprintf(stderr, "Usage: pas filename\n"); return;} */
	if ( argc==1 ){
		f = stdin;
	}else{
		f = fopen(argv[1], "r");
	}
	if ( f==NULL ) {fprintf(stderr, "Can't Open '%s'\n", argv[1]); return;}

	zzs_init(HashSize, SymStrTable);
	LoadSymTable();

	ANTLR(program(), f);		/* Parse program from stdin */
	/*statsym();*/
	/*print_trax();*/		/* list out the last rules applied */
	exit(0);
}

LoadSymTable()
{
	struct _pre *p = &(predef[0]);
	Sym *sym;

	while ( p->symbol != NULL )
	{
		sym = zzs_newadd(p->symbol);
		sym->token = p->token;
		p++;
	}
}

/* converts a list of entries in symbol table into something else */
addlist(list, token, level)
Sym *list;
int token, level;
{
	register Sym *p, *q;

	for (p=list; p!=NULL; p=q)
	{
		q = make_special_entry(token,p);
		q->level = level;
		q = p->link;
		/* unlink things */
		p->link = NULL;
	}
}

Sym *make_special_entry(token, p)
int token;
Sym *p;
{
	if (p){
		switch(p->token){
		case UTypeID:
		case VarID:
		case ProcID:
		case ProgID:
		case FuncID:
		case ConstID:
			/* need to make new entry for this scope */
			p = zzs_newadd(p->symbol);
		case WORD:
		/* in this case can just use the symbol entry already made */
			p->token = token;
			break;
		default:
			fprintf(stderr,"Tried to redefine reserved word %s\n",
				p->symbol);
			break;
		}
	}
	return p;
}
