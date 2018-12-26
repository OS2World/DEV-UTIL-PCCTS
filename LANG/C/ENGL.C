#include <stdio.h>
#include <malloc.h>
#ifdef __STDC__
#include <stdarg.h>
#else
#include <varargs.h>
#endif
#include "stdpccts.h"

static void decodeType();

void show(tree)
AST *tree;
{
	if ( tree == NULL ) return;
	if ( tree->nodeType == ENode ) {
		printf(" %s", zztokens[tree->data.e.token]);
	} else {
		english( tree );
	}
}

void before() { printf(" ("); }
void after()  { printf(" )\n"); fflush(stdout); }

english(tree)
AST *tree;
{
	extern int PrintEngl;

	if ( !PrintEngl ) return;
	if ( tree==NULL ) return;
	if ( tree->nodeType == SymQ )
	{
		printf("%s is", tree->data.s.name);
		if ( (bottom(tree)->data.t.sc&scTypedef)!=0 )
			printf(" equivalent to");
		else
		{
			if ( (bottom(tree)->data.t.sc&scExtern)!=0 )
				printf(" globally visible and defined to be");
		}
		engl(tree->down, 0);
		if ( tree->data.s.init!=NULL ) {
			printf(" initialized to");
			doExpr(tree->data.s.init);
		}
		printf("\n\n");
		return;
	}
	printf("type is");
	engl(tree, 0);
	printf("\n\n");
}

static void
decodeType(base, plural)
qBaseType *base;
int plural;
{
	if ( base->sc&scAuto )	printf(" auto");
	if ( base->sc&scRegister )printf(" register");
	if ( base->sc&scStatic )	printf(" static");
	if ( base->sc&scExtern )	;
	if ( base->sc&scTypedef )	;

	if ( base->cv&cvConst )	printf(plural?" constant":" a constant");
	if ( base->cv&cvVolatile )printf(plural?" volatile":" a volatile");

	if ( base->type&tSigned )	printf(" signed");
	if ( base->type&tUnsigned)printf(" unsigned");
	if ( base->type&tShort )	printf(" short");
	if ( base->type&tLong )	printf(" long");
	if ( base->type&tDouble )	printf(plural?" doubles":" double");
	if ( base->type&tInt ) 	printf(plural?" ints":" int");
	if ( base->type&tFloat )	printf(plural?" floats":" float");
	if ( base->type&tChar )	printf(plural?" chars":" char");
	if ( base->type&tVoid )	printf(plural?" objects of unspecified type":
										  " an object of unspecified type");
	if ( base->type&tEllipsis)printf(" ...");
	if ( base->type&tUnion )	printf(" union");
	if ( base->type&tStruct )	printf(plural?" structs":" a struct");
	if ( base->type&tEnum )	printf(" an enumerated type");
	if ( base->type&tTypeName) printf(" a type called %s", base->name);
}

engl(tree, plural)
AST *tree;
int plural;
{
	AST *a;

	if ( tree == NULL ) return;
	switch ( tree->nodeType )
	{
		case SymQ :
			printf(" symbol %s is", tree->data.s.name);
			break;
		case BaseTypeQ :
			decodeType(&(tree->data.t), plural);
			if ( (tree->data.t.type&tStruct)!=0 ||
				 (tree->data.t.type&tEnum)!=0 ||
				 (tree->data.t.type&tUnion)!=0 )
			{
				if ( tree->data.t.name!=NULL )
					printf(" called %s",tree->data.t.name);
				if ( tree->right != NULL ) printf(" containing\n");
				for (a=tree->right; a!=NULL; a=a->right)
					{engl(a,0); putchar('\n');}
			}
			break;
		case PointerQ :
			if ( tree->data.p.cv&cvConst )
				printf(plural?" pointers to constant objects defined as":
							  " a pointer to a constant object defined as");
			else if ( tree->data.p.cv&cvVolatile )
				printf(plural?" pointers to volatile objects defined as":
							  " a pointer to a volatile object defined as");
			else
				printf(plural?" pointers to":" a pointer to");
			break;
		case ArrayQ :
			if ( tree->data.a.dim == NULL ) {
				if (plural) printf(" undimensioned arrays of");
				else printf(" an undimensioned array of");
			}
			else {
				putchar(' ');
				if ( !plural ) printf("a ");
				doExpr(tree->data.a.dim);
				if (plural) printf("-element arrays of");
				else printf("-element array of");
			}
			plural = 1;
			break;
		case FunctionQ :
			if ( tree->right!=NULL )
			{
				printf(plural?" functions with args\n":
							  " a function with args\n");
				for (a=tree->right; a!=NULL; a=a->right)
					{engl(a, 0); putchar('\n');}
				printf(" returning");
			}
			else
				printf(plural?" functions returning": " a function returning");
			break;
		case FieldQ :
			printf(" field %s which is", tree->data.fi.name);
			break;
		case ENode :
			doExpr(tree);
		default :
			fprintf(stderr, "illegal AST node type\n");
			break;
	}
	engl(tree->down, plural);
}

doExpr(tree)
AST *tree;
{
	if ( tree == NULL ) return;
	if ( tree->nodeType == ENode ) {
		zzpre_ast(tree, show, before, after);
	} else {
		english( tree );
	}
}
