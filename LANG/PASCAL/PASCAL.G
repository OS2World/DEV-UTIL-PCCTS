/*
 * File: pascal.g
 *
 * P a s c a l  G r a m m a r
 *
 * Some of the grammar could be more readable if it were spread out.  However,
 * to show the concise nature of ANTLR, I am squishing it (show off).
 * Theoretically, it would be possible to put the entire grammar into one
 * rule with lots-o-parenthesis and duplicate subrules.
 *
 * This grammar is considered Public Domain and is distributed as is.
 *
 * Terence Parr 1990
 * Purdue University
 * January 1990
 *
 * Modified by Will Cohen 12/17/90
 * Fixed {..} , (..)* bug in expressions, 11-92
 */
#header <<

#include "sym.h"
#include "pascal.h"
extern Sym *CurSym;

>>

<<
Sym *CurSym;
static int level = 0;
>>

/* made special tokens for key words to simplify lexical analyser */
#token And
#token Array
#token Begin
#token Case
#token Const
#token Div
#token Do
#token Downto
#token Else
#token End
#token File
#token For
#token Forward
#token Function
#token Goto
#token If
#token In
#token Label
#token Mod
#token Nil
#token Not
#token Of
#token Or
#token Packed
#token Procedure
#token Program
#token Record
#token Repeat
#token Set
#token Then
#token To
#token Type
#token Until
#token Var
#token While
#token With

/* things to specify identifiers */
#token TypeID
#token UTypeID
#token VarID
#token ProcID
#token ProgID
#token FuncID
#token ConstID

/* white space */
#token "[\t\ ]"			<< zzskip(); >>
#token "[\n\r]"			<< zzline++; zzskip(); >>

/* signal start of a comment */
#token "\{"			<< zzmode(COMMENT); zzskip();>>
#token "\(\*"			<< zzmode(COMMENT); zzskip();>>

/* G r o s s  S y n t a x  C o n t r o l */


program	:	<<Sym *globals=NULL, *p;>>
		Program nonReserved	
		<<make_special_entry(ProgID,$2);
		  printf("program %s level %d:\n\n", $2->symbol, level);
	 	  zzs_scope(&globals);
		>>
		"\(" idList "\)"	<<addlist($4,VarID,level);>>
		";"
		block "."
		<<
		  p = zzs_rmscope(&globals);
		  printf("global (level %d) symbols:", level);
		  for (; p != NULL; p=p->scope)
			printf(" %s", p->symbol);
		  printf("\n\n");
		>>
		"@"
	;

block	:	<<Sym **oldscope = zzs_scope(NULL); >>
		decl 
		( routine <<zzs_scope(oldscope);>> )*
		Begin
			slist
		End
	;

routine	: <<int tok; Sym *p,*locals=NULL;>>
		( Procedure <<tok=ProcID;>> | Function <<tok=FuncID;>>)
		nonReserved << $2 = make_special_entry(tok,$2);>>
		<<zzs_scope(&locals); level++; >>
		{"\(" parmGroup (";" parmGroup)* "\)"}
		{ ":" (TypeID | UTypeID) }
		";"
		block ";"
		<<
		  p = zzs_rmscope(&locals);
		  printf("subprogram %s level %d:\n", $2->symbol, --level);
		  printf("local (level %d) symbols:", level+1);
		  for (; p != NULL; p=p->scope) printf(" %s", p->symbol);
		  printf("\n\n");
		>>
	;

parmGroup : {Var} idList ":" (TypeID | UTypeID) <<addlist($2,VarID,level);>> ;

slist	: label ( ";" label )* ;

label	: {UINT ":"} statement ;

statement	: (var | FuncID ) ":=" expr
		| ProcID { "\(" expr ("," expr)* "\)" }
		| Begin slist End

		| If expr Then statement { Else statement}
		| Case expr Of
			(constant ("," constant)* ":" statement ";")*
			End
		| While expr Do statement
		| Repeat slist Until expr
		| For VarID ":=" expr ( To| Downto ) expr Do statement
		| With var ( "," var )* Do statement
		| Goto UINT
		| /* empty statement */
		;


/* D e c l a r a t i o n  S e c t i o n */


decl	: ( LABEL UINT ( "," UINT )* ";")*
		{ Const nonReserved "=" constant
			<<make_special_entry(ConstID,$2);>>
			";"
			( nonReserved "=" constant
				<<make_special_entry(ConstID,$1);>>
				";"
			)*
		}
		{ Type nonReserved "=" type
			<<make_special_entry(UTypeID,$2);>>
			";"
			( nonReserved "=" type
				<<make_special_entry(UTypeID,$1);>>
				";"
			)*
		}
		{ Var idList ":" type ";"	<<addlist($2,VarID,level);>>
			( idList ":" type ";"	<<addlist($1,VarID,level);>>
			)*
		}
	;

/* tokens than can be redefined in a new scope */
nonReserved	: UTypeID	<< $0 = $1; >>
		| VarID		<< $0 = $1; >>
		| ProcID	<< $0 = $1; >>
		| ProgID	<< $0 = $1; >>
		| FuncID	<< $0 = $1; >>
		| ConstID	<< $0 = $1; >>
		| WORD		<< $0 = $1; >>
		;

simpleType	: (TypeID | UTypeID)
		| "\(" wordList <<addlist($2,ConstID,level);>> "\)"
		| constant ".." constant
		;

type		: simpleType
		/* since pointers to types can be defined before actual type*/
		| "^" (TypeID | nonReserved)
		| {Packed} structType
		;

structType	: Array "\[" simpleType ("," simpleType)* "\]" Of type
		| File Of type
		| Set Of simpleType
		| Record fixedPart {";"} (fixedPart {";"} )* {variantPart} End
		;

fixedPart	: idList ":" type
		;

variantPart	: Case {WORD ":"}
			(TypeID | UTypeID) Of variant {";"} (variant {";"})*
		;

variant		: constant ( "," constant )* ":"
			"\(" fixedPart {";"} (fixedPart {";"})* 
			{variantPart} "\)"
		;

/* Use 'link' field of symbol rec to link elements together into idlist */
idList	: <<Sym *list=NULL;>>	/* Return list of id's */
		nonReserved		<< $1->link = list; list = $1; >>
		( "," nonReserved	<< $2->link = list; list = $2; >>
		)*
		<<$0 = list;>>
	;

wordList: <<Sym *list=NULL;>>			/* Return list of words */
		WORD		<<$1->link = list; list=$1;>>
		( "," WORD	<<$2->link = list; list=$2;>>
		)*
				<<$0 = list;>>
	;

constant : {"\+"|"\-"} (ConstID | UINT { "." UINT {"E" {"\+"|"\-"} UINT}})
	| Nil
	| LITERAL
	;

uconstant : ConstID
	/* floating point number */
	| UINT { "." UINT {"E" {"\+"|"\-"} UINT}}
	| Nil
	| LITERAL
	;
			

/* E x p r e s s i o n  S e c t i o n */


expr	: simpleExpr (("="|"\<"|"\>"|"\<\>"|"\<="|"\>="| In ) simpleExpr)* ;

simpleExpr	: {"\+"|"\-"} term (("\+"|"\-"| Or ) term)* ;

term	: factor (("\*"|"/"| Div | Mod | And ) factor)* ;

factor	: uconstant
	| var
	| FuncID { "\(" expr ("," expr)* "\)" }
	| "\(" expr "\)"
	| Not factor
	| "\[" {expr {".." expr}} ("," expr {".." expr})* "\]"
	;

var	: VarID ref
	| WORD ref	<</* NOTE error if not defined before use */>>
	;

ref	: "\[" expr ("," expr)* "\]" ref
	| "^" ref
	| "." (WORD <</*NOTE error*/>>|VarID) ref
	|
	;

#token LITERAL "' ~[\0-\31']* '"
#token UINT "[0-9]+"
#token WORD "[a-zA-Z] [a-zA-Z0-9]*"
		<<
		{
			register Sym *p;

			p = zzs_get(zzlextext);
			if ( p == NULL ){
				p = zzs_newadd(zzlextext);
				p->token = WORD;
			}else{ 
				NLA = p->token;
			}
			CurSym = p;
		}
		>>

/* special automaton to skip over comments */
#lexclass COMMENT
/* ends of comments */
#token "\*\)"			<< zzmode(START); zzskip(); >>
#token "\}"			<< zzmode(START); zzskip(); >>

#token "[\n\r]"			<< zzline++; zzskip(); >>

#token "\*"			<< zzskip(); >>
#token "~[\*\}\n\r]+"		<< zzskip(); >>

