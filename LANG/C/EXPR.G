/* "," should group left-to-right; build a tree with all expr0's as siblings;
 *
 *		expr0 --> ... --> expr0
 */
expr    :       expr0
                (       ","!
                        expr0
                )*
        ;

/* asgnop should group right-to-left; yield
 *
 *		asgnop
 *		  |
 *		  v
 *		expr1 --> expr0
 */
expr0   :       expr1
                {       (       "="^
                        |       "\+="^
                        |       "\-="^
                        |       "\*="^
                        |       "/="^
                        |       "\%="^
                        |       "\>\>="^
                        |       "\<\<="^
                        |       "&="^
                        |       "^="^
                        |       "\|="^
                        )
                        expr0
                }
        ;

/*	   "?"
 *		|
 *		v
 *	  expr2 --> expr2 --> expr2
 */
expr1   :       expr2
                {       "?"^
                        expr2
                        ":"!
                        expr2
                }
        ;

/*	  "||"
 *		|
 *		v
 *	  expr3 --> expr3
 */
expr2   :       expr3
                (       "\|\|"^
                        expr3
                )*
        ;

/*	  "&&"
 *		|
 *		v
 *	  expr4 --> expr4
 */
expr3   :       expr4
                (       "&&"^
                        expr4
                )*
        ;

/*	   "|"
 *		|
 *		v
 *	  expr5 --> expr5
 */
expr4   :       expr5
                (       "\|"^
                        expr5
                )*
        ;

/*	   "^"
 *		|
 *		v
 *	  expr6 --> expr6
 */
expr5   :       expr6
                (       "^"^
                        expr6
                )*
        ;

/*	   "&"
 *		|
 *		v
 *	  expr7 --> expr7
 */
expr6   :       expr7
                (       "&"^
                        expr7
                )*
        ;

/*	 equ_op
 *		|
 *		v
 *	  expr8 --> expr8
 */
expr7   :       expr8
                (       ( "=="^
                        | "!="^
                        )
                        expr8
                )*
        ;

/*	inequ_op
 *		|
 *		v
 *	  expr9 --> expr9
 */
expr8   :       expr9
                (       ( "\<"^
                        | "\>"^
                        | "\>="^
                        | "\<="^
                        )
                        expr9
                )*
        ;

/*	shift_op
 *		|
 *		v
 *	  expr10 --> expr10
 */
expr9   :       expr10
                (       ( "\>\>"^
                        | "\<\<"^
                        )
                        expr10
                )*
        ;

/*	   aop
 *		|
 *		v
 *	  expr11 --> expr11
 */
expr10  :   expr11
            (   ( "\+"^
                | "\-"^
                )
                expr11
            )*
        ;

/*	   mop
 *		|
 *		v
 *	  expr12 --> expr12
 *
 */
expr11  :   cast
            (   ( "\*"^
                | "/"^
                | "\%"^
                )
                cast
            )*
		;

/*	   "("
 *		|
 *		v
 *	  type --> expr12
 */
cast	:	"\("^ typename "\)"! cast
		|	expr12
        ;

/*	 unary_op
 *		|
 *		v
 *	   "("
 *		|
 *		v
 *	 typename
 *		|
 *		v
 *	  expr12
 *
 * Or,
 *
 * PreInc_or_PreDec
 *		|
 *		v
 *	  expr12
 *
 * Or,
 *
 *	 "sizeof"		"sizeof"
 *		|			   |
 *		v			   v
 *	  expr12		  "("
 *					   |
 *					   v
 *					 expr12
 */
expr12!	:   <<AST *t=NULL;>>
			unary_op
			{ "\(" typename "\)" <<t = #( #[ENode, LPAREN], #2);>> }
			expr12
			<<#0 = #( #(#1, t), #3 );>>
        |   PreInc expr12	<<#0 = #( #[ENode, PreInc], #2 );>>
        |   PreDec expr12	<<#0 = #( #[ENode, PreDec], #2 );>>
        |   "sizeof"
            (   "\(" typename	<<t = #( #[ENode, LPAREN], #2);>>
            	"\)"
            |   expr12			<<t = #1;>>
            )
			<<#0 = #( #[ENode, SizeOf], t );>>
        |   expr13
								<<#0 = #1;>>
        ;

/*
 * Put a post dec or inc as root of expr13.
 *
 * For WORD expr14 we build:
 *
 *		WORD
 *		 |
 *		 v
 *		expr14
 *
 * For WORD or expr followed by (...) expr14 we build:
 *
 *	  FuncCall
 *		 |
 *		 v
 *	expr_or_WORD --> expr		(sibling is argument list)
 *		 |
 *		 v
 *		expr14
 */
expr13!	:   <<Sym *var; AST *e=NULL;>>
		(	STRING		<<#0 = #[ENode, STRING];>>
        |   CHARACTER	<<#0 = #[ENode, CHARACTER];>>
        |   FNUM		<<#0 = #[ENode, FNUM];>>
        |   integer		<<#0 = #1;>>
        |   WORD	<<if ( (var=zzs_get($1.text)) == NULL )
						  error1("undefined variable", $1.text);
					  else 
						  if ( var->token!=Var && var->token!=Func )
		  					error1("we were kind of hoping for a variable here",$1.text);
					>>
			expr14
			<<if ( var!=NULL ) #0 = #( #[ENode, var->token], #2 );>>
        |   WORD	<<var = zzs_get($1.text);
				 	  if ( var != NULL )
		  			  {
						if ( var->token != Func )
						{
		  					error1("we were kind of hoping for a function here",$1.text);
						}
		  			  }
					>>
			"\(" {expr <<e=#1;>>} "\)"
			expr14
			<<#0 = #( #[ENode, FuncCall], #(#[ENode, Func], #5), e );>>
        |   "\(" expr "\)" {"\(" {expr <<e=#1;>>} "\)"} expr14
			<<#0 = #( NULL, #( #[ENode, LPAREN], #2, #5), e );>>
        )
        { "\+\+"		<<#0 = #( #[ENode, PostInc], #0 );>>
        | "\-\-"		<<#0 = #( #[ENode, PostDec], #0 );>>
        }
        ;

/*
 * build chains of modifiers.
 *
 * -> or . yields
 *
 *		->
 *		|
 *		v
 *	   WORD
 *		|
 *		v
 *	   ...
 *		|
 *		v
 *		->
 *		|
 *		v
 *	   WORD
 *
 * Array refs:
 *
 *	   [ ]
 *		|
 *		v
 *	   expr					(first)
 *	   ...
 *		|
 *		v
 *	   expr					(last)
 */
expr14!	:   "\-\>" WORD	expr14
			<<#0 = #(#[ENode, StructPtrRef], #[ENode, WORD]);
			  #( bottom(#0), #3 );>>
        |   "." WORD expr14
			<<#0 = #(#[ENode, StructRef], #[ENode, WORD]);
			  #( bottom(#0), #3 );>>
        |   "\[" expr "\]" expr14
			<<#0 = #(#[ENode, LBRACK], #2);
			  #( bottom(#0), #4 );>>
		|	<<#0 = NULL;>>
        ;

unary_op:	"&" | "\*" | "\+" | "\-" | "\~" | "!"
		;

integer :   OCT_NUM
        |   HEX_NUM
        |   INT_NUM
        |   L_OCT_NUM
        |   L_HEX_NUM
        |   L_INT_NUM
        ;

#token WORD "[_a-zA-Z][_a-zA-Z0-9]*"
		<<{
			register Sym *p;
			p = zzs_get(NLATEXT);
			if ( p != NULL )
				if ( p->token == TypeName )
				{
					NLA = TypeName;
				}
		}>>
