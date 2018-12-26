/* F u n c t i o n s */

/* recognize a function definition (after the "func_name(...)").
 * If old-style arguments are found, a pointer to the list of
 * arguments is passed in.  If there are no parameters or if new-style
 * definitions are used, $args is NULL.
 */
func_def[AST *args]
		:	<<Sym *p, **save; int oldstyle=0;
			  save = zzs_scope(NULL); zzs_scope(&Params);>>
			(	decl[PARAMETER]
				<<oldstyle=1;>>
			)*
			<<if ($args==NULL && oldstyle)
				error("we've already got the parameters, thanks");
			  else checkArgs( args );
			  zzs_scope( save );
			>>
			block
		;

block	:	<<Sym *p, **saveScope=zzs_scope(NULL), *locals=NULL;
			  static int level=LOCAL-1;>>
			<<level++; zzs_scope(&locals);>>

			"\{"^
				( decl[level] )*
				( stat[level] )*
			"\}"!

			<<--level;
			  p = zzs_rmscope(&locals);		/* unlink from sym table */
			  pScope(p, "parameters\n");
			  zzs_scope(saveScope);			/* return to old scope */
			>>
		;

/*
 * match a statement and yield an expr-tree
 *
 * Label		":"
 *		 		 |
 *		 		 v
 *				WORD
 *
 * expr			expr
 *
 * block		block
 *
 * if			"if"
 *				 |
 *				 v
 *				expr --> stat --> stat		(2nd stat only if else-clause)
 *
 * while		"while"
 *				 |
 *				 v
 *				expr --> stat
 *
 * do			"do"
 *				 |
 *				 v
 *				stat --> expr
 *
 * for			"for"
 *				 |
 *				 v
 *				expr --> expr --> expr -> stat
 *
 * switch		"switch"
 *				 |
 *				 v
 *				expr --> stat
 *
 * case			"case"
 *				 |
 *				 v
 *				expr
 *
 * continue		"continue"
 *
 * break		"break"
 *
 * return		"return"
 *				 |
 *				 v
 *				expr
 *
 * goto			"goto"
 *				 |
 *				 v
 *				WORD
 *
 * ";"
 */
stat[int level]
		:	<<Sym *label;>>
			WORD ":"^
			<<label = zzs_get($1.text);
			  if ( label != NULL ) {
				if ( label->defined )
					error1("you've already defined label", $1.text);
				label->defined = 1;
			  }
			  else {
			  	label = addsym(Label, $1.text, $level, NULL, NULL);
				label->defined = 1;
			  }
			>>
		|	expr ";"!
		|	block
		|	"if"^ "\("! expr "\)"! stat[$level] { "else"! stat[$level] }
		|	"while"^ "\("! expr "\)"! stat[$level]
		|	"do"^ stat[$level] "while" "\("! expr "\)"! ";"!
		|	"for"^ "\("! { expr } ";"! { expr } ";"!
			{ expr } "\)"!
			stat[$level]
		|	"switch"^ "\("! expr "\)"! stat[$level]
		|	"case"^ expr ":"!
		|	"default"^ ":"!
		|	"continue"^ ";"!
		|	"break" ";"!
		|	"return"^ { expr } ";"!
		|	"goto"^ WORD ";"!
			<<if ( zzs_get($2.text) == NULL )
			  	addsym(Label, $2.text, $level, NULL, NULL);
			>>
		|	";"!
		;
