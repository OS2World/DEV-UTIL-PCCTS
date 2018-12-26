/*
 * ANSI C recognizer
 *
 * Gives some error messages for semantics, but this grammar
 * checks mostly syntax.  We make no claim that it rigorously follows
 * the ANSI C standard, but it's a good start.
 *
 * Type trees are constructed and maintained in the symbol table.
 * Expression trees are constructed and then thrown away.  The
 * user can presumably do something more useful with them.
 *
 * Requires PCCTS Version 1.00
 *
 * Terence Parr
 * July 1991
 */

#header <<
	#define D_TextSize 20
	#include "charbuf.h"
	#include "type.h"
	#include "sym.h"
	#include "proto.h"
	#include <string.h>
>>

#parser "C"

#token "[\ \t]+"	<< zzskip(); >>
#token "\n"			<< zzline++; zzskip(); >>

#token "#line [\ \t]+ [0-9]+ ~[\n]*\n"
					<< zzline = atoi(zzlextext+5); zzskip(); >>
#token "# [\ \t]+ [0-9]+ ~[\n]*\n"
					<< zzline = atoi(zzlextext+1); zzskip(); >>

#token "\""			<< zzmode(STRINGS); zzmore(); >>
#token "'"			<< zzmode(CHARACTERS); zzmore(); >>

/* these tokens are used as node types, but not referenced in grammar */
#token Var
#token Func
#token FuncCall
#token Label
#token PostInc
#token PostDec
#token StructPtrRef
#token StructRef
#token AggrTag

#lexclass STRINGS
#token STRING "\""	<< zzmode(START); >>
#token "\\\""		<< zzmore(); >>
#token "\\n"		<< zzreplchar('\n'); zzmore(); >>
#token "\\r"		<< zzreplchar('\r'); zzmore(); >>
#token "\\t"		<< zzreplchar('\t'); zzmore(); >>
#token "\\[1-9][0-9]*"
					<< zzreplchar((char)strtol(zzbegexpr,NULL,10)); zzmore(); >>
#token "\\0[0-7]*"	<< zzreplchar((char)strtol(zzbegexpr,NULL,8)); zzmore(); >>
#token "\\0x[0-9]+"	<< zzreplchar((char)strtol(zzbegexpr,NULL,16)); zzmore(); >>
#token "\\~[\n\r]"	<< zzmore(); >>
#token "[\n\r]"		<< zzline++; zzmore(); /* print warning about \n in str */>>
#token "~[\"\n\r\\]+"<< zzmore(); >>

#lexclass CHARACTERS
#token CHARACTER	"'" << zzmode(START); >>
#token "\\'"		<< zzmore(); >>
#token "\\n"		<< zzreplchar('\n'); zzmore(); >>
#token "\\r"		<< zzreplchar('\r'); zzmore(); >>
#token "\\t"		<< zzreplchar('\t'); zzmore(); >>
#token "\\[1-9][0-9]*"
					<< zzreplchar((char)strtol(zzbegexpr,NULL,10)); zzmore(); >>
#token "\\0[0-7]*"	<< zzreplchar((char)strtol(zzbegexpr,NULL,8)); zzmore(); >>
#token "\\0x[0-9]+"	<< zzreplchar((char)strtol(zzbegexpr,NULL,16)); zzmore(); >>
#token "\\~[\n\r]"	<< zzmore(); >>
#token "[\n\r]"		<< zzline++; zzmore(); /* print warning about \n in str */>>
#token "~[\'\n\r\\]"<< zzmore(); >>

#lexclass START

#token OCT_NUM "[0][0-7]*"
#token L_OCT_NUM "[0][0-7]*[Ll]"
#token INT_NUM "[1-9][0-9]*"
#token L_INT_NUM "[1-9][0-9]*[Ll]"
#token HEX_NUM "[0][Xx][0-9A-Fa-f]+"
#token L_HEX_NUM "[0][Xx][0-9A-Fa-f]+[Ll]"
#token FNUM "([1-9][0-9]*{.[0-9]*} | {[0]}.[0-9]+) {[Ee]{[\+\-]}[0-9]+}"
#token PreInc "\+\+"
#token PreDec "\-\-"
#token LPAREN "\("
#token LBRACK "\["
#token SizeOf "sizeof"

globals!:	<<AST *base, *t; Sym *p;
			  zzs_scope(&Globals);>>

			(	<<;>>
				<<Params=NULL;>> decl[GLOBAL]
			|	<<Params=NULL;>>
				<<base = #[BaseTypeQ,scNone,0,tInt,NULL];>>
				declarator[base]
				<<handleSymbol(scNone, $1.text, #1, NULL, GLOBAL);
				  t = defineArgs(#1, &Params);
				>>
				func_def[t]
				<<english( #(#[SymQ,$1.text,#2], #1) );>>
				<<Proto($1.text, #1);
				  ProtoBoth($1.text, #1);
				  p = zzs_rmscope(&Params);
				  pScope(p, "parameters\n");
				>>
			)*

			<<p = zzs_rmscope(&Globals);
			  pScope(p, "globals\n");
			  ProtoVars(p);>>
			"@"
		;

/* d e c l  --  recognize a declaration or definition.
 *
 * We handle typedefs in a bizarre way.  WORD's are converted
 * to TypeName's inside the lexical action for token WORD.  So,
 * because of the lookahead, we need to get a TypeName into
 * the symbol table before the lookahead can get a reference
 * to this. e.g. "typedef int I; I i;"  We actually add the typedef
 * name to the symbol table when we see its definition in
 * rule declaration and friends.  Aggregate tags are handled in a
 * similar fashion by adding them to the symbol table as they
 * are declared.
 *
 * functions definitions always have a FunctionQ node at the root
 * of the declarator since anything in front would make a pointer to
 * a function or whatever.  e.g. int *f(); --> () * int --> "function
 * returning pointer to integer."  Or, int (*f)() --> * () int -->
 * "pointer to function returning integer."  The first is a function
 * symbol, the 2nd is a variable.
 */
decl![int level]
		:	<<int sc=scNone, t=tInt, cv=cvNone, typ;
			  AST *base, *d, *init=NULL, *tr;
			  char *w;
			  Sym *n=NULL, *p;>>
			(	(sclass[&sc] | typeq[&cv])+
				(	type[&t]		<<base = #[BaseTypeQ,cv,sc,t,$1.text];>>
				|	aggr[sc,cv]		<<base = #1;>>
				|	enum_def		<<base = #1;>>
				|					<<base = #[BaseTypeQ,cv,sc,tInt,NULL];>>
				)
			|	type[&t]			<<base = #[BaseTypeQ,cvNone,scNone,t,$1.text];>>
			|	aggr[scNone,cvNone]	<<base = #1;>>
			|	enum_def			<<base = #1;>>
			)
			(	declarator[base]	<<d=#1; w=$1.text;>>
				(	{ <<init=NULL;>> "=" initialize <<init=#2;>> }
					<<if ( d->nodeType == FunctionQ ) {
						sc |= scExtern;
						bottom(d)->data.t.sc |= scExtern;
					  }
					  handleSymbol(sc, w, d, init, $level);>>
					(	<<english( #(#[SymQ,w,init], d) );>>
						","
						declarator[base]
						{ <<init=NULL;>> "=" initialize <<init=#2;>> }
						<<english( #(#[SymQ,$2.text,init], #2) );>>
						<<if ( #2->nodeType == FunctionQ ) {
							sc |= scExtern;
							bottom(#2)->data.t.sc |= scExtern;
						  }
						  handleSymbol(sc, $2.text, #2, init, $level);>>
					)*
					<<
					if ( base->data.t.type==tStruct ||
						 base->data.t.type==tUnion ||
						 base->data.t.type==tEnum )
					{
						if ( base->data.t.name != NULL )
						{
							p = zzs_get(base->data.t.name);
							if ( p!=NULL ) p->level = $level;
						}
					}
					>>
					";"
				|	<<
						handleSymbol(sc, w, d, init, $level);
						tr = defineArgs(d, &Params);
					>>
					func_def[tr]
					<<english( #(#[SymQ,w,#1], d) );>>
					<<Proto(w, d);
					  ProtoBoth(w, d);
					  p = zzs_rmscope(&Params);
			  		  pScope(p, "block\n");
					>>
				)
			|	";"
				<<english( base );>>
				<<if ( base->data.t.type==tStruct ||
					   base->data.t.type==tUnion ||
					   base->data.t.type==tEnum )
				  {
					p = zzs_get(base->data.t.name);
					if ( p!=NULL ) p->level = $level;
				  }
				  else
					error("missing declarator");
				>>
			)
		;

sclass![int *sc]
		:	"auto"				<<*$sc |= scAuto;>>
		|	"static"			<<*$sc |= scStatic;>>
		|	"register"			<<*$sc |= scRegister;>>
		|	"extern"			<<*$sc |= scExtern;>>
		|	"typedef"			<<*$sc |= scTypedef;>>
		;

typeq![int *cv]
		:	"const"				<<*$cv |= cvConst;>>
		|	"volatile"			<<*$cv |= cvVolatile;>>
		;

type![int *t]
		:	t1[t]				<<$type = $1;>>
		;

t1![int *type]
		:	(	"unsigned"		<<*$type = tUnsigned;>>
			|	"signed"		<<*$type = tSigned;>>
			)
			(	"char"			<<*$type |= tChar;>>
			|	{ "short"		<<*$type |= tShort;>>
				| "long"		<<*$type |= tLong;>>
				}
				{ "int"			<<*$type |= tInt;>>
				}
			)
		|	(	"short"			<<*$type = tShort;>>
				{ "int" 		<<*$type |= tInt;>>
				}
			|	"long"			<<*$type = tLong;>>
				{ "int"			<<*$type |= tInt;>>
				| "float"		<<*$type |= tFloat;>>
				| "double"		<<*$type |= tDouble;>>
				}
			)
		|	"void"				<<*$type = tVoid;>>
		|	"char"				<<*$type = tChar;>>
		|	"int"				<<*$type = tInt;>>
		|	"float"				<<*$type = tFloat;>>
		|	"double"			<<*$type = tDouble;>>
		|	TypeName			<<*$type = tTypeName; $t1 = $1;>>
		;

/* D e c l a r a t o r */

/*
 * Build a declarator by appending the base to the bottom of the type-tree
 * matched in dcltor1.  We pass the storage class to dcltor1 in case
 * we have a typedef on our hands which needs to be added to the symbol
 * table ASAP.
 */
declarator![AST *base]
		:	dcltor1[bottom($base)] <<#(bottom(#1), $base);
								  	 #0 = (#1==NULL)?$base:#1;
									 $declarator = $1;>>
		;

/*
 * Match *D1 or D2.  Build type-trees for PointerQ (pointer qualifier)
 * via:
 *
 * #0 = 	D1
 *			|
 *			v
 *			*
 *
 * where D? is dcltor? in this grammar.
 */
dcltor1![AST *base]
		:	<<AST *t; int cv=0;>>
			"\*"
			{	"const"			<<cv=cvConst;>>
			|	"volatile"		<<cv=cvVolatile;>>
			}					<<t = #[PointerQ,cv];>>
			dcltor1[$base]		<<#(bottom(#3), t); #0=(#3==NULL)?t:#3;
								  $dcltor1 = $3;>>
		|	dcltor2[$base]		<<#0 = #1; $dcltor1 = $1;>>
		;

/*
 * For WORD D3 we return the following
 *
 * $$ =		WORD recognized.
 * #0 =  	D3					(array or func modifier)
 *
 * For ( D1 ) we return
 *
 * $$ =		WORD recognized in D1.
 * #0 =		D1					(put stuff in (..) above [] or ())
 *			|
 *			v
 *			D3
 *
 * For instance, (*f)() yields
 *
 * $$ =		f
 * #0 =		*					(pointer to)
 *			|
 *			v
 *		   ( )					(a function)
 *
 * If storage class is scTypedef, we need to add it to the symbol table.
 */
dcltor2![AST *base]				/* pass in storage class for typedefs */
		:	<<AST *t; Sym *n;>>
			WORD				<<if ( $base->data.t.sc&scTypedef )
									addsym(TypeName,$1.text,0,NULL,NULL);
								>>
			dcltor3				<<#0 = #2; $dcltor2 = $1;>>
		|	"\(" dcltor1[$base] "\)" <<$dcltor2 = $2;>> 
			dcltor3				<<#(bottom(#2), #4); #0=(#2==NULL)?#4:#2;>>
		;

/*
 * return #0 = [expr] or = [nodimension]
 * or ( ) --> arg1 --> ... --> argn for a function
 *
 * multiple [1][2][3] yields
 *
 * #0 =	   [1]					(an 1-element array of)
 *			|
 *			v
 *		   [2]					(2-element arrays of)
 *			|
 *			v
 *		   [3]					(3-element arrays)
 *			
 */
dcltor3!:	"\[" expr1 "\]" dcltor3	<<#0 = #( #[ArrayQ,#2], #4 );>>
		|	"\[" "\]" dcltor3		<<#0 = #( #[ArrayQ,NULL], #3 );>>
		|	"\(" args "\)"			<<#0 = #(NULL, #[FunctionQ], #2);>>
		|							<<#0 = NULL;>>
		;

/*
 * match a list of arguments.
 *
 * The arguments are siblings of the FunctionQ node in the type
 * tree.  e.g.
 *
 *	[FunctionQ]-->[arg1]--> ... -->[argn]
 *		 			|				 |
 *		 			v				 v
 *				 [type1]		  [type1]
 */
args!	:	<<AST *t;>>
			arg					<<t=#1;>>
			(	"," arg			<<t = #(NULL, t, #2);>>
			)*
			{	"," "..."		<<t=#(NULL,t,#[BaseTypeQ,0,0,tEllipsis,NULL]);>>
			}
			<<#0 = t;>>
		|
		;

arg!	:	typename			<<#0 = #1;>>
		|	WORD				<<#0 = #[SymQ,$1.text,NULL];>>
		;

/*
 * match a typename -- (used in type-casting and function prototypes).
 * Type-trees look the same as those for decl.  But, a symbol is
 * optional here because they can be used in argument lists.
 */
typename!:	<<int sc=0, cv, t=tInt; AST *base, *tr=NULL;>>
			(	("register" <<sc = scRegister;>> | typeq[&cv])+
				{	type[&t]	<<base = #[BaseTypeQ,cv,sc,t,$1.text];>>
				|	aggr[scNone,cv]	<<base = #1;>>
				}
			|	type[&t]		<<base = #[BaseTypeQ,0,0,t,$1.text];>>
			|	aggr[scNone,cvNone]	<<base = #1;>>
			)
			tdecl[base]			<<if ($2.text[0]!='\0') tr=#[SymQ,$2.text,NULL];
								  #0=#(tr, #2);>>
		;

/* A g g r e g a t e s */

/*
 * match an enum definition; yield following tree:
 *
 * [BaseTypeQ] --> [elem1] --> ... --> [elemn] 
 */
enum_def!:	<<AST *base;>>
			"enum" WORD			<<base=#[BaseTypeQ,0,0,tEnum,$2.text];>>
			enum_lst			<<#0 = #(NULL, base, #3);>>
		;

/*
 * match a list of enumeration elements.
 *
 * The symbols are siblings of each other:
 *
 * [elem1] --> ... --> [elemn] 
 *
 * If an element has an initialization, store a pointer to it in the
 * AST node.
 */
enum_lst!:	<<AST *list, *init=NULL;>>
			"\{"
			WORD
			{	"=" expr1		<<init = #2;>>
			}					<<list = #[SymQ,$2.text, init];>>
			(	","
				WORD
				{				<<init=NULL;>>
					"=" expr1	<<init=#2;>>
				}				<<list = #(NULL,list,#[SymQ,$2.text, init]);>>
			)*
			"\}"
								<<#0 = list;>>
		|						<<#0 = NULL;>>
		;

/*
 * Match a struct/union def.
 * Return a tree like this:
 * 
 *	[BaseTypeQ]-->[fld1]--> ... -->[fldn]
 *		 			|				 |
 *		 			v				 v
 *				 [type1]		  [type1]
 *
 * BUG: Allows two structs to have same name
 */
aggr![int sc, int cv]
		:	<<AST *tr, *base; int t; Sym *typ;>>
			(	"struct"		<<t=tStruct;>>
			|	"union"			<<t=tUnion;>>
			)					<<base = #[BaseTypeQ,$cv,$sc,t,NULL];>>
			(	(	WORD		<<base->data.t.name = mystrdup($1.text);>>
				|	TypeName	<<base->data.t.name = mystrdup($1.text);>>
				)
				( ag[base]		<<#0 = #(NULL, base, #1);
								  addsym(AggrTag, base->data.t.name,
										 0, base, NULL);
								>>
				|				<<#0 = base;>>
				)
			|	ag[base]		<<#0 = #(NULL, base, #1);>>
			)
		;

/*
 * match a field list for a struct/union
 *
 * The fields are siblings of each other:
 *
 *  [fld1] --> ... --> [fldn] 
 *	  |				     |
 *	  v				     v
 * [type1]		      [type1]
 *
 */
ag![AST *base]
		:	<<AST *t=NULL;>>
			"\{" fdef[$base]	<<#0=t=#2;>>
			(	fdef[$base]		<<#(NULL, t, #1); t = #1;>>
			)*
			"\}"
		;

/*
 * Match one field definition; make the following tree
 *
 * [FieldQ]
 *	   |
 *	   v
 *  [type1]
 */
fdef![AST *base]
		:	<<int t=tInt; AST *f, *g;>>
			(	type[&t]		<<base = #[BaseTypeQ,0,0,t,$1.text];>>
			|	aggr[scNone,cvNone]	<<base = #1;>>
			)
			field[$base]		<<f = #(#[FieldQ,$2.text], #2);>>
			(	"," field[$base]<<g = #(#[FieldQ,$2.text], #2);
								  f = #(NULL, f, g);>>
			)*
			";"
			<<#0 = f;>>
		;

/* bitfields are recognized, but not handled 'cause not too many people
 * use them
 */
field![AST *base]
		:	declarator[$base] { ":" expr1 } <<#0=#1; $field = $1;>>
		|	":" expr1
		;

/* T y p e  N a m e */

tdecl![AST *base]
		:	tdecl1				<<#(bottom(#1), $base);
								  #0 = (#1==NULL)?$base:#1; $tdecl=$1;>>
		;

tdecl1! :	<<AST *t; int cv=0;>>
			"\*"
			{	"const"			<<cv=cvConst;>>
			|	"volatile"		<<cv=cvVolatile;>>
			}					<<t = #[PointerQ,cv];>>
			tdecl1				<<#(bottom(#3), t); #0=(#3==NULL)?t:#3;
								  $tdecl1 = $3;>>
		|	tdecl2				<<#0 = #1; $tdecl1 = $1;>>
		;

tdecl2!	:	<<AST *t=NULL; $tdecl2.text[0] = '\0';>>
			"\(" tdecl1 "\)"	<<$tdecl2 = $2;>>
			tdecl3				<<#(bottom(#2), #4); #0=(#2==NULL)?#4:#2;>>
		|	WORD tdecl3			<<$tdecl2 = $1; #0 = #2;>>
		|	tdecl3				<<#0 = #1;>>
		;

tdecl3!	:	"\[" expr1 "\]" tdecl3<<#0 = #( #[ArrayQ,#2], #4 );>>
		|	"\[" "\]"     tdecl3<<#0 = #( #[ArrayQ,NULL], #3 );>>
		|	"\(" args "\)"		<<#0 = #( NULL, #[FunctionQ], #2 );>>
		|
		;


/* I n i t  e x p r e s s i o n s */


initialize
		:	init2
		|	expr0
		;

/* Build an initialization expression-tree of the form:
 *
 * Single-dimensioned array or structure:
 *
 *	"{"
 *	 |
 *	 v
 *	[exp1] --> ... --> [expn]
 *
 * Nested structure or multi-dim array:
 *
 *	"{"
 *	 |
 *	 v
 *	"{" --> ... --> "{"
 *	 |				...
 *	 v				...
 *	[exp1] --> ... --> [expn]
 */
init2	:	"\{"^ init3 ( ","! init3 )* {","!} "\}"!
		;

init3	:	init2
		|	expr1
		;
