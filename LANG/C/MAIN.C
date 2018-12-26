/*
 * proto
 *
 * function/variable prototyper.  Can dump just the symbols or
 * symbols and types.  Can also dump out the symbol table for each
 * scope (global, parameter, block-local).  Generates either K&R or
 * ANSI function prototypes.
 *
 * Terence Parr
 * Purdue University
 * July 1991
 * PCCTS Version 1.00
 */
#include <stdio.h>
#include <malloc.h>
#ifdef __STDC__
#include <stdarg.h>
#else
#include <varargs.h>
#endif
#include "stdpccts.h"

#define HashTableSize	999
#define StringTableSize	10000

AST *root = NULL;
Sym *Globals = NULL;
Sym *Params = NULL;
static int GenANSI = 0;
static int GenVARS = 0;
static int GenFUNCS = 0;
static int JustSymbols = 0;
static int GenKR_ANSI = 0;
static int DumpScopes = 0;
int PrintEngl = 0;
static FILE *f;

char *decodeType();


		/* C m d - L i n e  O p t i o n  S t r u c t  &  F u n c s */

typedef struct {
			char *option;
			int  arg;
			void (*process)();
			char *descr;
		} Opt;

static void pANSI() { GenANSI = 1; }
static void pVARS() { GenVARS = 1; }
static void pFUNC() { GenFUNCS = 1; }
static void pBoth() { GenKR_ANSI = 1; }
static void pNAME() { JustSymbols = 1; }
static void pSYM()  { DumpScopes = 1; }
static void pENGL() { PrintEngl = 1; }

static void pFILE(s)
char *s;
{
	f = fopen(s, "r");
	if ( f == NULL )
	{
		fprintf(stderr, "file does not exist: %s\n", s);
		help();
		exit(-1);
	}
}

Opt options[] = {
    { "-ansi", 0, pANSI,"Generate ANSI argument prototypes"},
    { "-func", 0, pFUNC,"Generate extern defs for visible functions (default)"},
    { "-both", 0, pBoth,"Generate K&R/ANSI func headers for all functions"},
    { "-var", 0,  pVARS,"Generate extern defs for visible variables (default)"},
    { "-name", 0, pNAME,"Generate visible symbols w/o types"},
    { "-sym", 0,  pSYM, "Dump symbols for each scope"},
    { "-engl", 0, pENGL,"Print english translation"},
	{ "*",   0,   pFILE, 	"" },	/* anything else is a file */
	{ NULL, 0,    NULL, NULL }
};

main(argc, argv)
int argc;
char **argv;
{
	f = stdin;
	if ( argc != 1 ) ProcessArgs(argc-1, &(argv[1]), options);

	zzs_init(HashTableSize, StringTableSize);
	ANTLR(globals(&root), f);
	zzs_done();

	fclose( f ) ;
}

pScope(p, s)
Sym *p;
char *s;
{
	if ( p == NULL || !DumpScopes ) return;
	printf("%s", s);
	for (; p!=NULL; p=p->scope)
	{
		printf("Level %02d | %-12s | %-15s",
			p->level,
			zztokens[p->token],
			p->symbol);
		if ( p->token == Var ||
			 p->token == Func ||
			 p->token == TypeName )
		{
			pType( p->type, NULL );
		}
		printf("\n");
	}
}

/*
 * handleSymbol()
 *
 * Description		process the installation of symbols into the symbol
 *					table.  We handle:
 *						extern decls followed by the actual
 *							definitions.  
 *						typedefs
 *						function decls/defs (external and definition)
 *						old-style argument definitions
 *
 * Parameters
 *		sc			storage class of symbol
 *		symbol		symbol to handle
 *		type		type of symbol
 *		init		initialization expression-tree
 *		level		level number (scope)
 *
 * Returns
 *		nothing
 */
handleSymbol(sc, symbol, type, init, level)
int sc;
char *symbol;
AST *type, *init;
int level;
{
	AST *base;
	Sym *n;

	/* T y p e d e f
	 *
	 * typedefs are added immediately in rule declarator and friends
	 * so we simply set the level and type here
	 */
	if ( sc&scTypedef )
	{
		n = zzs_get(symbol);
		n->level = level;
		n->type = type;
		return;
	}

	n = zzs_get(symbol);

	/* F u n c t i o n
	 *
	 * The first extern func declaration is added to the symbol table
	 * any subsequent extern decls are ignored.  When an actual definition
	 * is seen, we set the 'defined' field in symbol table.
	 * If the function has not been seen before, add it to the symbol
	 * table.  Set the defined flag if not scExtern.
	 */
	if ( type->nodeType == FunctionQ )
	{
		if ( n!=NULL )							/* then defined already */
		{
			if ( !n->defined )					/* was extern, now define */
			{
				if ( !(sc&scExtern) )			/* do we have a def or decl */
				{
					n = addsym(Func, symbol, level, type, init);
					n->defined = 1;
				}
				return;
			}
			error1("function redefinition", symbol);
		}
		n = addsym(Func, symbol, level, type, init);
		if ( !(sc&scExtern) )					/* do we have a def or decl */
		{
			n->defined = 1;
		}
		return;
	}

	/* V a r i a b l e
	 *
	 * If var has been seen before, check for redefinition.  If declared
	 * before and this is a definition, set 'defined' flag.  Ignore decls
	 * after first one.
	 *
	 * If level is parameter, we are adding old-style parameters.  The
	 * args rule will have added the symbols to the symbol table.
	 */
	if ( n != NULL )				/* have we seen it before? */
	{
		if ( level == PARAMETER )	/* set type of parameter */
		{
			if ( n->defined ) error1("redefinition of parameter", symbol);
			n->type = type;
			n->defined = 1;
			return;
		}
		/* if not a variable, we must make new variable entry in sym tab */
		if ( n->token != Var )
		{
			n = addsym(Var, symbol, level, type, init);
			if ( !(sc&scExtern) ) n->defined = 1;
			return;
		}
		if ( !n->defined )			/* was it defined? */
		{
			if ( !(sc&scExtern) )	/* is this a def? */
			{
				base = bottom(n->type);
				base->data.t.sc &= ~scExtern;
				n->defined = 1;
			}
			return;
		}
		if ( sc&scExtern )			/* redefinition? */
			error1("redefinition of variable", symbol);
		return;
	}
	if ( level == PARAMETER )		/* no parameter for this def */
	{
		error1("extraneous parameter declaration ignored", symbol);
		return;
	}
	n = addsym(Var, symbol, level, type, init);
	if ( !(sc&scExtern) ) n->defined = 1;
}

/*
 * Given a list of all 'extern' scope variables, dump an 'extern' def
 * for just the variables that are visible outside the file (non-static).
 */
ProtoVars(globals)
Sym *globals;
{
	Sym *p = globals;
	AST *base;

	if ( globals == NULL || !GenVARS ) return;
	for (; p!=NULL; p=p->scope)
	{
		if ( p->token == Var )
		{
			base = bottom(p->type);
			if ( base == NULL ) continue;
			if ( base->nodeType!=BaseTypeQ ) continue;
			if ( !(base->data.t.sc&scStatic) &&
				 !(base->data.t.sc&scExtern) )
			{
				if ( JustSymbols ) printf("%s\n", p->symbol);
				else
				{
					printf("extern");
					pType(p->type, p->symbol);
					printf(";\n");
				}
			}
		}
	}
}

Proto(symbol, type)
char *symbol;
AST *type;
{
	if ( type == NULL || !GenFUNCS ) return;
	if ( bottom(type)->data.t.sc&scStatic ) return;
	if ( JustSymbols ) {printf("%s\n", symbol); return;}
	printf("extern");
	pType( zzchild(type), NULL ); /* dump return type ignoring first () */
	printf(" %s(", symbol);
	if ( GenANSI )
	{
		AST *a;

		if ( zzsibling(type)!=NULL )
		{
			for (a=zzsibling(type); a!=NULL; a = zzsibling(a))
			{
				if ( a->nodeType == SymQ )
				{
					if ( zzchild(a)!=NULL )
						pType(zzchild(a), NULL);
					else
					{
						Sym *n = zzs_get(a->data.s.name);
						printf(" %s", a->data.s.name);
					}
				}
				else pType(a, NULL);	/* assume ,... here */
				if ( zzsibling(a) != NULL ) printf(",");
			}
		}
		else
			printf(" void");
	}
	printf(" );\n");
}

/* Generate prototypes (w/o extern) that compile under both K&R and ANSI */
ProtoBoth(symbol, type)
char *symbol;
AST *type;
{
	AST *a;

	if ( type == NULL || !GenKR_ANSI ) return;
/*	if ( bottom(type)->data.t.sc&scStatic ) return; <-- do statics also */
	pType( zzchild(type), NULL ); /* dump return type ignoring first () */
	printf("\n#ifdef __STDC__\n");
	printf("%s(", symbol);

	if ( zzsibling(type)!=NULL )
	{
		for (a=zzsibling(type); a!=NULL; a = zzsibling(a))
		{
			if ( a->nodeType == SymQ )
			{
				if ( zzchild(a)!=NULL )
				{
					pType(zzchild(a), a->data.s.name);
				}
				else
				{
					Sym *n = zzs_get(a->data.s.name);	/* look up arg for type */
					if ( n==NULL )
						fprintf(stderr, "symbol table error: can't find parameter\n");
					else
					{
						pType(n->type, n->symbol);
					}
				}
			}
			else pType(a, NULL);	/* assume ,... here */
			if ( zzsibling(a) != NULL ) printf(",");
		}
	}
	else
		printf(" void");

	printf(" )\n");

	printf("#else\n");

	printf("%s(", symbol);
	if ( zzsibling(type)!=NULL )
	{
		for (a=zzsibling(type); a!=NULL; a = zzsibling(a))
		{
			if ( a->nodeType == SymQ )
			{
				printf(" %s", a->data.s.name);
			}
			if ( zzsibling(a) != NULL && !(zzsibling(a)->nodeType == BaseTypeQ &&
				 zzsibling(a)->data.t.type == tEllipsis) )
				printf(",");
		}
		printf(" )\n");
		for (a=zzsibling(type); a!=NULL; a = zzsibling(a))
		{
			if ( a->nodeType == SymQ )
			{
				if ( zzchild(a)!=NULL )
				{
					pType(zzchild(a), a->data.s.name);
				}
				else
				{
					Sym *n = zzs_get(a->data.s.name);	/* look up arg for type */
					if ( n==NULL )
						fprintf(stderr, "symbol table error: can't find parameter\n");
					else
					{
						pType(n->type, n->symbol);
					}
				}
				printf(";\n");
			}
		}
	}
	else
		printf(" )\n");


	printf("#endif\n\n");
}

pArgs( args, comma )
Sym *args;
int comma;
{
	if ( args == NULL ) return;
	pArgs( args->scope, 1 );	/* print the next one first, then this one */
	pType( args->type, NULL );
	if ( comma ) printf(",");
}

pType(p, symbol)
AST *p;
char *symbol;
{
	char temp[500], out[500], *s;

	temp[0] = out[0] = '\0';
	if ( symbol != NULL ) strcpy(out, symbol);
	while ( p!=NULL )
	{
		switch ( p->nodeType )
		{
			case BaseTypeQ :
				s = decodeType(&p->data.t);
				if ( out[0] == '\0' ) sprintf(temp, "%s", s);
				else sprintf(temp, "%s %s", s, out);
				strcpy(out, temp);
				break;
			case PointerQ :
				temp[0] = '\0';
				if ( p->down->nodeType == ArrayQ ||
					 p->down->nodeType == FunctionQ )
				{
					strcpy(temp, "(");
				}
				if ( p->data.p.cv&cvConst )
					strcat(temp, "* constant");
				else if ( p->data.p.cv&cvVolatile )
					strcat(temp, "* volatile");
				else
					strcat(temp, "*");
				strcat(temp, out);
				if ( p->down->nodeType == ArrayQ ||
					 p->down->nodeType == FunctionQ )
				{
					strcat(temp, ")");
				}
				strcpy(out, temp);
				break;
			case ArrayQ :
				strcat(out, "[]");
				break;
			case FunctionQ :
				strcat(out, "()");
				break;
			default :
				fprintf(stderr, "pType: illegal nodetype\n");
				exit(-1);
		}
		p = p->down;
	}
	printf("%s", out);
}

char *
decodeType(base)
qBaseType *base;
{
	static char temp[255], temp2[255];

	temp[0]=temp2[0]='\0';
	if ( base->sc&scAuto )		strcat(temp," auto");
	if ( base->sc&scRegister )	strcat(temp," register");
	if ( base->sc&scStatic )	strcat(temp," static");
	if ( base->sc&scExtern )	strcat(temp," extern");

	if ( base->cv&cvConst )		strcat(temp," constant");
	if ( base->cv&cvVolatile )	strcat(temp," volatile");

	if ( base->type&tSigned )	strcat(temp," signed");
	if ( base->type&tUnsigned)	strcat(temp," unsigned");
	if ( base->type&tShort )	strcat(temp," short");
	if ( base->type&tLong )		strcat(temp," long");
	if ( base->type&tDouble )	strcat(temp," double");
	if ( base->type&tInt )		strcat(temp," int");
	if ( base->type&tFloat )	strcat(temp," float");
	if ( base->type&tChar )		strcat(temp," char");
	if ( base->type&tVoid )		strcat(temp," void");
	if ( base->type&tEllipsis)	strcat(temp," ...");
	if ( base->type&tUnion )
	{
		sprintf(temp2, " union %s",base->name!=NULL?base->name:"");
		strcat(temp, temp2);
	}
	if ( base->type&tStruct)
	{
		sprintf(temp2, " struct %s",base->name!=NULL?base->name:"");
		strcat(temp, temp2);
	}
	if ( base->type&tEnum )
	{
		sprintf(temp2, " union %s",base->name!=NULL?base->name:"");
		strcat(temp, temp2);
	}
	if ( base->type&tTypeName)
	{
		sprintf(temp2, " %s",base->name);
		strcat(temp, temp2);
	}
	return temp;
}

/* Constructor for AST nodes
 * First parameter is always pointer to newly-created AST node
 * Second is the AST node type which will tell us what follows
 * on the stack.
 */

#ifdef __STDC__
AST *zzmk_ast(AST *t, int nt, ...)
#else
AST *zzmk_ast(va_alist)
va_dcl
#endif
{
#ifndef __STDC__
	int nt;
	AST *t;
#endif
	va_list ap;

#ifdef __STDC__
	va_start(ap, nt);
#else
	va_start(ap);
	t = va_arg(ap, AST *);
	nt = va_arg(ap, int);
#endif

	t->nodeType = nt;
	switch ( t->nodeType )
	{
		case BaseTypeQ :
			t->data.t.cv = va_arg(ap, int);
			t->data.t.sc = va_arg(ap, int);
			t->data.t.type = va_arg(ap, int);
			t->data.t.name = mystrdup( va_arg(ap, char *) );
			break;
		case PointerQ :
			t->data.p.cv = va_arg(ap, int);
			break;
		case ArrayQ :
			t->data.a.dim = va_arg(ap, AST *);
			break;
		case FunctionQ :
			break;
		case FieldQ :
			t->data.fi.name = mystrdup( va_arg(ap, char *) );
			break;
		case SymQ :
			t->data.s.name = mystrdup( va_arg(ap, char *) );
			t->data.s.init = va_arg(ap, AST *);
			break;
		case ENode :
			t->data.e.token = va_arg(ap, int);
			break;
		default :
			fprintf(stderr, "zzmk_ast: illegal nodetype\n");
			exit(-1);
	}

	va_end(ap);
	return t;
}

void
fatal(s)
char *s;
{
	error(s);
	exit(-1);
}

void
error(s)
char *s;
{
	fprintf(stderr, "line %d, error: %s\n", zzline, s);
}

void
warn(s)
char *s;
{
	fprintf(stderr, "line %d, warning: %s\n", zzline, s);
}

void
error1(s, s2)
char *s, *s2;
{
	fprintf(stderr, "line %d, error: %s: %s\n", zzline, s, s2);
}

void
warn1(s, s2)
char *s, *s2;
{
	fprintf(stderr, "line %d, warning: %s: %s\n", zzline, s, s2);
}

/* scan the declarator tree for the FunctionQ node.  If there
 * are any arguments, add them to the symbol table for parameters
 * using the scope passed in.
 *
 * The arguments are siblings of the FunctionQ node in the type
 * tree.  e.g.
 *
 *		...
 *		 |
 *		 v
 *	[FunctionQ]-->[arg1]--> ... -->[argn]
 *		 |			|				 |
 *		 v			v				 v
 *		...		 [type1]		  [type1]
 *
 * Check for inconsistent definitions.
 *
 * Return a pointer to the first argument (NULL if there is none)
 * Also, return NULL if new-style arguments are found since
 * we won't need to check them later.
 */
AST *
defineArgs(a, scope)
AST *a;
Sym **scope;
{
	Sym **save = zzs_scope( NULL );
	AST *b, *args;
	int which = 0;	/* 1 implies old-style, 2 implies new-style defs */

	while ( a != NULL )
	{
		if ( a->nodeType == FunctionQ ) break;
		a = zzchild( a );
	}
	if ( a == NULL )		/* no parameters */
	{
		return NULL;
	}

	zzs_scope( scope );
	for (a=args=zzsibling(a); a != NULL; a = zzsibling(a))
	{
		if ( a->nodeType != SymQ )
		{
			if ( a->nodeType != BaseTypeQ ||
				 (a->nodeType == BaseTypeQ&&a->data.t.type != tVoid &&
				  a->nodeType == BaseTypeQ&&a->data.t.type != tEllipsis) )
				error("how about a name with that type?");
		}
		else if ( zzchild(a) != NULL )
		{
			for (b=zzchild(a); b!=NULL; b=zzchild(b))
			{
				if ( b->nodeType == BaseTypeQ )		/* type & symbol */
				{
					if ( which == 1 )
						error("mixed old- and new-style parameter definitions");
					else {
						which = 2;	/* new-style definition */
						addsym(Var,
							   a->data.s.name,
							   PARAMETER,
							   zzchild(a),
							   NULL);
						args = NULL;
					}
					break;
				}
			}
		}
		else			/* old-style parameter */
		{
			if ( which == 2 )
				error("mixed old- and new-style parameter definitions");
			which = 1;
			/* add parameter to symbol table.  Type is set later */
			addsym(Var, a->data.s.name, PARAMETER, NULL, NULL);
		}
	}
	zzs_scope( save );

	return args;
}

/* Given a list of arguments from a function argument list, check to
 * see that they are all in the symbol tables as parameters.
 */
checkArgs(args)
AST *args;
{
	AST *a, *type;
	Sym *p;

	for (a=args; a!=NULL; a=zzsibling(a))	/* for each argument */
	{
		if ( a->data.s.name == NULL ) continue;
		p = zzs_get( a->data.s.name );
		if ( p != NULL && !p->defined )
			{
				warn1("you forgot to define parameter", a->data.s.name);
				type = zzastnew();
				zzmk_ast(type,BaseTypeQ,0,0,tInt,NULL);
				addsym(Var, a->data.s.name, PARAMETER, type, NULL);
			}
	}
}

Sym *
addsym(tok, symbol, level, type, init)
int tok;
char *symbol;
int level;
AST *type, *init;
{
	Sym *p = zzs_newadd(symbol);

	if ( p == NULL ) return NULL;
	p->token = tok;
	p->level = level;
	p->type = type;
	p->init = init;
	return p;
}

AST *bottom(t)
AST *t;
{
	if ( t==NULL ) return NULL;
	if ( t->down != NULL ) return bottom(t->down);
	return t;
}

char *
mystrdup(s)
char *s;
{
	char *p;
	if ( s == NULL ) return NULL;
	p = malloc(strlen(s)+1);
	if ( p == NULL ) return NULL;
	strcpy(p, s);
	return p;
}

help()
{
	Opt *p = options;
	fprintf(stderr, "proto [options] file.c\n");
	while ( *(p->option) != '*' )
	{
		fprintf(stderr, "\t%s %s\t%s\n",
						p->option,
						(p->arg)?"___":"   ",
						p->descr);
		p++;
	}
}

ProcessArgs(argc, argv, options)
int argc;
char **argv;
Opt *options;
{
	Opt *p;

	if ( argv==NULL ) return;
	while ( argc-- > 0 )
	{
		p = options;
		while ( p->option != NULL )
		{
			if ( strcmp(p->option, "*") == 0 ||
				 strcmp(p->option, *argv) == 0 )
			{
				if ( p->arg )
				{
					(*p->process)( *argv, *(argv+1) );
					argv++;
					argc--;
				}
				else
					(*p->process)( *argv );
				break;
			}
			p++;
		}
		argv++;
	}
}

