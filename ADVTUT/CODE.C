/*
 * Simple code generator for PCCTS 1.00 tutorial
 *
 * Terence Parr
 * Purdue University
 * Electrical Engineering
 * March 19, 1992
 */
#include <stdio.h>
#include "sym.h"
#include "charbuf.h"
#define AST_FIELDS int token, level, offset; char str[D_TextSize];
#define zzcr_ast(ast,attr,tok,text) create_ast(ast,attr,tok,text)
#include "antlr.h"
#include "ast.h"
#include "tokens.h"
#include "dlgdef.h"
#include "mode.h"
#define GLOBAL              0
#define PARAMETER           1
#define LOCAL               2

static int LabelNum=0, GenHeader=0;

#define DONT_CARE			0
#define SIDE_EFFECTS		1
#define VALUE				2

gen(t,emode)
AST *t;
int emode;	/* evaluation mode member { SIDE_EFFECTS, VALUE, DONT_CARE } */
{
	AST *func, *arg, *locals, *slist, *a, *opnd1, *opnd2, *lhs, *rhs;
	int n;

	if ( t == NULL ) return;
	if ( !GenHeader ) { printf("#include \"sc.h\"\n"); GenHeader=1; }

	switch ( t->token )
	{
	case DefineFunc :
		func = zzchild(t);
		arg = zzchild( zzsibling(func) );
		locals = zzchild( zzsibling( zzsibling(func) ) );
		slist = zzsibling( zzsibling( zzsibling(func) ) );
		if ( strcmp(func->str, "main") == 0 )
			printf("_%s()\n{\n\tBEGIN;\n", func->str);
		else
			printf("%s()\n{\n\tBEGIN;\n", func->str);
		for (a=locals; a!=NULL; a = zzsibling(a)) printf("\tLOCAL;\n");
		gen( slist, DONT_CARE );
		printf("\tEND;\n}\n");
		break;
	case SLIST :
		for (a=zzchild(t); a!=NULL; a = zzsibling(a))
		{
			gen( a, EvalMode(a->token) );
			if ( a->token == Assign ) printf("\tPOP;\n");
		}
		break;
	case DefineVar :
		printf("SCVAR %s;\n", zzchild(t)->str);
		break;
	case Mul :
	case Div :
	case Add :
	case Sub :
	case Equal :
	case NotEqual :
		opnd1 = zzchild(t);
		opnd2 = zzsibling( opnd1 );
		gen( opnd1, emode );
		gen( opnd2, emode );
		if ( emode == SIDE_EFFECTS ) break;
		switch ( t->token )
		{
		case Mul : printf("\tMUL;\n"); break;
		case Div : printf("\tDIV;\n"); break;
		case Add : printf("\tADD;\n"); break;
		case Sub : if ( opnd2==NULL ) printf("\tNEG;\n");
				   else printf("\tSUB;\n");
				   break;
		case Equal : printf("\tEQ;\n"); break;
		case NotEqual : printf("\tNEQ;\n"); break;
		}
		break;
	case If :
		a = zzchild(t);
		gen( a, VALUE );				/* gen code for expr */
		n = LabelNum++;
		printf("\tBRF(iflabel%d);\n", n);
		a = zzsibling(a);
		gen( a, EvalMode(a->token) );	/* gen code for statement */
		printf("iflabel%d: ;\n", n);
		break;
	case While :
		a = zzchild(t);
		n = LabelNum++;
		printf("wbegin%d: ;\n", n);
		gen( a, VALUE );				/* gen code for expr */
		printf("\tBRF(wend%d);\n", n);
		a = zzsibling(a);
		gen( a, EvalMode(a->token) );	/* gen code for statement */
		printf("\tBR(wbegin%d);\n", n);
		printf("wend%d: ;\n", n);
		break;
	case Return :
		gen( zzchild(t), VALUE );
		printf("\tRETURN;\n");
		break;
	case Print :
		gen( zzchild(t), VALUE );
		printf("\tPRINT;\n");
		break;
	case Assign :
		lhs = zzchild(t);
		rhs = zzsibling( lhs );
		gen( rhs, emode );
		printf("\tDUP;\n");
		if ( lhs->level == GLOBAL ) printf("\tSTORE(%s);\n", lhs->str);
		else printf("\tLSTORE(%d);\n", lhs->offset);
		break;
	case VAR :
		if ( emode == SIDE_EFFECTS ) break;
		if ( t->level == GLOBAL ) printf("\tPUSH(%s);\n", t->str);
		else printf("\tLPUSH(%d);\n", t->offset);
		break;
	case FUNC :
		gen( zzchild(t), VALUE );
		printf("\tCALL(%s);\n", t->str);
		break;
	case STRING :
		if ( emode == SIDE_EFFECTS ) break;
		printf("\tSPUSH(%s);\n", t->str);
		break;
	default :
		printf("Don't know how to handle: %s\n", zztokens[t->token]);
		break;
	}
}

EvalMode( tok )
int tok;
{
	if ( tok == Assign || tok == If || tok == While ||
		 tok == Print || tok == Return ) return VALUE;
	else return SIDE_EFFECTS;
}
