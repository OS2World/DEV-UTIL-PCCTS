/*
 * A n t l r  T r a n s l a t i o n  H e a d e r
 *
 * Terence Parr, Hank Dietz and Will Cohen: 1989-1993
 * Purdue University Electrical Engineering
 * ANTLR Version 1.10
 */
#include <stdio.h>
#define ANTLR_VERSION	110

#ifdef __cplusplus
#ifndef __STDC__
#define __STDC__
#endif
#endif
#include "set.h"
#include <ctype.h>
#include "syn.h"
#include "hash.h"
#include "generic.h"
#define zzcr_attr(attr,tok,t)
#define zzEOF_TOKEN 1
#define zzSET_SIZE 12
#include "antlr.h"
#include "tokens.h"
#include "dlgdef.h"
#include "mode.h"
ANTLR_INFO

#ifdef __STDC__
static void chkToken(char *, char *, char *);
#else
static void chkToken();
#endif

#ifdef __STDC__
void
grammar()
#else
grammar()
#endif
{
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
	Graph g;  
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==71) ) {
			zzmatch(71); zzCONSUME;
			zzmatch(Action);
			
			HdrAction = (char *) calloc(strlen(LATEXT(1))+1, sizeof(char));
			require(HdrAction!=NULL, "rule grammar: cannot allocate header action");
			strcpy(HdrAction, LATEXT(1));
			 zzCONSUME;
		}
		zzEXIT(zztasp2);
		}
	}
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==72) ) {
			zzmatch(72); zzCONSUME;
			zzmatch(QuotedTerm);
			
			ParserName=StripQuotes(mystrdup(LATEXT(1)));
			if ( RulePrefix[0]!='\0' )
			{
				warn("#parser meta-op incompatible with '-gp prefix'; '-gp' ignored");
				RulePrefix[0]='\0';
			}
			 zzCONSUME;
		}
		zzEXIT(zztasp2);
		}
	}
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		char *a;  
		while ( 1 ) {
			if ( (LA(1)==Action) ) {
				zzmatch(Action);
				
				a = (char *) calloc(strlen(LATEXT(1))+1, sizeof(char));
				require(a!=NULL, "rule grammar: cannot allocate action");
				strcpy(a, LATEXT(1));
				list_add(&BeforeActions, a);
				 zzCONSUME;
			}
			else {
				if ( (LA(1)==79) ) {
					laction();
				}
				else {
					if ( (LA(1)==80) ) {
						aLexclass();
					}
					else {
						if ( (LA(1)==85) ) {
							token();
						}
						else {
							if ( (LA(1)==82) ) {
								error();
							}
							else break;
						}
					}
				}
			}
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
	rule();
	zzNON_GUESS_MODE {
	g=zzaArg(zztasp1,4); SynDiag = (Junction *) zzaArg(zztasp1,4 ).left;  
	}
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( 1 ) {
			if ( (LA(1)==NonTerminal) ) {
				rule();
				zzNON_GUESS_MODE {
				if ( zzaArg(zztasp2,1 ).left!=NULL ) {g.right = NULL; g = Or(g, zzaArg(zztasp2,1));}  
				}
			}
			else {
				if ( (LA(1)==80) ) {
					aLexclass();
				}
				else {
					if ( (LA(1)==85) ) {
						token();
					}
					else {
						if ( (LA(1)==82) ) {
							error();
						}
						else break;
					}
				}
			}
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		char *a;  
		while ( 1 ) {
			if ( (LA(1)==Action) ) {
				zzmatch(Action);
				
				a = (char *) calloc(strlen(LATEXT(1))+1, sizeof(char));
				require(a!=NULL, "rule grammar: cannot allocate action");
				strcpy(a, LATEXT(1));
				list_add(&AfterActions, a);
				 zzCONSUME;
			}
			else {
				if ( (LA(1)==79) ) {
					laction();
				}
				else {
					if ( (LA(1)==82) ) {
						error();
					}
					else break;
				}
			}
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
	zzmatch(Eof); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	CannotContinue=TRUE;  
	zzsyn(zzMissText, zzBadTok, "", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd1, 0x1);
	}
}

#ifdef __STDC__
void
rule()
#else
rule()
#endif
{
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
	RuleEntry *q; Junction *p; Graph r; int f, l; ECnode *e;
	char *pdecl=NULL, *ret=NULL, *a; CurRetDef = CurParmDef = NULL;
	zzmatch(NonTerminal);
	q=NULL;
	if ( hash_get(Rname, LATEXT(1))!=NULL ) {
		warn(eMsg1("duplicate rule definition: '%s'",LATEXT(1)))
		CannotContinue=TRUE;
	}
	else
	{
		q = (RuleEntry *)hash_add(Rname,
		LATEXT(1),
		(Entry *)newRuleEntry(LATEXT(1)));
		CurRule = q->str;
	}
	CurRuleNode = q;
	f = CurFile; l = zzline;
	NumRules++;
	 zzCONSUME;
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==74) ) {
			zzmatch(74);
			if ( q!=NULL ) q->noAST = TRUE;  
			 zzCONSUME;
		}
		zzEXIT(zztasp2);
		}
	}
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		;  
		if ( (setwd1[LA(1)]&0x2) ) {
			{
				zzBLOCK(zztasp3);
				zzMake0;
				{
				if ( (LA(1)==75) ) {
					zzmatch(75); zzCONSUME;
				}
				zzEXIT(zztasp3);
				}
			}
			zzmatch(PassAction);
			pdecl = (char *) calloc(strlen(LATEXT(1))+1, sizeof(char));
			require(pdecl!=NULL, "rule rule: cannot allocate param decl");
			strcpy(pdecl, LATEXT(1));
			CurParmDef = pdecl;
			 zzCONSUME;
		}
		zzEXIT(zztasp2);
		}
	}
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==76) ) {
			zzmatch(76); zzCONSUME;
			zzmatch(PassAction);
			ret = (char *) calloc(strlen(LATEXT(1))+1, sizeof(char));
			require(ret!=NULL, "rule rule: cannot allocate ret type");
			strcpy(ret, LATEXT(1));
			CurRetDef = ret;
			 zzCONSUME;
		}
		zzEXIT(zztasp2);
		}
	}
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==QuotedTerm) ) {
			zzmatch(QuotedTerm);
			if ( q!=NULL ) q->egroup=mystrdup(LATEXT(1));  
			 zzCONSUME;
		}
		zzEXIT(zztasp2);
		}
	}
	zzNON_GUESS_MODE {
	
	if ( GenEClasseForRules && q!=NULL ) {
		e = newECnode;
		require(e!=NULL, "cannot allocate error class node");
		if ( q->egroup == NULL ) {a = q->str; a[0] = (char)toupper(a[0]);}
		else a = q->egroup;
		if ( Tnum( a ) == 0 )
		{
			e->tok = addTname( a );
			list_add(&eclasses, (char *)e);
			if ( q->egroup == NULL ) a[0] = (char)tolower(a[0]);
			/* refers to itself */
			list_add(&(e->elist), mystrdup(q->str));
		}
		else {
			warn(eMsg1("default errclass for '%s' would conflict with token/errclass",a));
			if ( q->egroup == NULL ) a[0] = (char)tolower(a[0]);
			free(e);
		}
	}
	}
	zzNON_GUESS_MODE {
	BlkLevel++;  
	}
	zzmatch(77); zzCONSUME;
	block();
	zzNON_GUESS_MODE {
	r = makeBlk(zzaArg(zztasp1,7));
	((Junction *)r.left)->jtype = RuleBlk;
	if ( q!=NULL ) ((Junction *)r.left)->rname = q->str;
	((Junction *)r.left)->file = f;
	((Junction *)r.left)->line = l;
	((Junction *)r.left)->pdecl = pdecl;
	((Junction *)r.left)->ret = ret;
	((Junction *)r.left)->lock = makelocks();
	((Junction *)r.left)->pred_lock = makelocks();
	p = newJunction();	/* add EndRule Node */
	((Junction *)r.right)->p1 = (Node *)p;
	r.right = (Node *) p;
	p->jtype = EndRule;
	p->lock = makelocks();
	p->pred_lock = makelocks();
	((Junction *)r.left)->end = p;
	if ( q!=NULL ) q->rulenum = NumRules;
	zzaArg(zztasp1,7) = r;
	}
	zzNON_GUESS_MODE {
	--BlkLevel;  
	}
	zzmatch(78); zzCONSUME;
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==Action) ) {
			zzmatch(Action);
			a = (char *) calloc(strlen(LATEXT(1))+1, sizeof(char));
			require(a!=NULL, "rule rule: cannot allocate error action");
			strcpy(a, LATEXT(1));
			((Junction *)r.left)->erraction = a;
			 zzCONSUME;
		}
		zzEXIT(zztasp2);
		}
	}
	zzNON_GUESS_MODE {
	if ( q==NULL ) zzaArg(zztasp1,0 ).left = NULL; else zzaArg(zztasp1,0) = zzaArg(zztasp1,7);  
	}
	zzNON_GUESS_MODE {
	CurRuleNode = NULL;  
	}
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	CannotContinue=TRUE;  
	zzsyn(zzMissText, zzBadTok, "", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd1, 0x4);
	}
}

#ifdef __STDC__
void
laction()
#else
laction()
#endif
{
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
	char *a;  
	zzmatch(79); zzCONSUME;
	zzmatch(Action);
	
	a = (char *) calloc(strlen(LATEXT(1))+1, sizeof(char));
	require(a!=NULL, "rule laction: cannot allocate action");
	strcpy(a, LATEXT(1));
	list_add(&LexActions, a);
	 zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, "", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd1, 0x8);
	}
}

#ifdef __STDC__
void
aLexclass()
#else
aLexclass()
#endif
{
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
	zzmatch(80); zzCONSUME;
	zzmatch(TokenTerm);
	lexclass(mystrdup(LATEXT(1)));  
	 zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, "", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd1, 0x10);
	}
}

#ifdef __STDC__
void
error()
#else
error()
#endif
{
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
	char *t=NULL; ECnode *e; int go=1; TermEntry *p;  
	zzmatch(82); zzCONSUME;
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		;  
		if ( (LA(1)==TokenTerm) ) {
			zzmatch(TokenTerm);
			t=mystrdup(LATEXT(1));  
			 zzCONSUME;
		}
		else {
			if ( (LA(1)==QuotedTerm) ) {
				zzmatch(QuotedTerm);
				t=mystrdup(LATEXT(1));  
				 zzCONSUME;
			}
			else {zzFAIL(1,zzerr1,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
		}
		zzEXIT(zztasp2);
		}
	}
	zzNON_GUESS_MODE {
	e = newECnode;
	require(e!=NULL, "cannot allocate error class node");
	e->lexclass = CurrentLexClass;
	if ( Tnum( (t=StripQuotes(t)) ) == 0 )
	{
		if ( hash_get(Texpr, t) != NULL )
		warn(eMsg1("errclass name conflicts with regular expression  '%s'",t));
		e->tok = addTname( t );
		require((p=(TermEntry *)hash_get(Tname, t)) != NULL,
		"hash table mechanism is broken");
		p->errclassname = 1;	/* entry is errclass name, not token */
		list_add(&eclasses, (char *)e);
	}
	else
	{
	warn(eMsg1("redefinition of errclass or conflict w/token '%s'; ignored",t));
	free( e );
	go=0;
}
	}
	zzmatch(83); zzCONSUME;
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==NonTerminal) ) {
			zzmatch(NonTerminal);
			if ( go ) t=mystrdup(LATEXT(1));  
			 zzCONSUME;
		}
		else {
			if ( (LA(1)==TokenTerm) ) {
				zzmatch(TokenTerm);
				if ( go ) t=mystrdup(LATEXT(1));  
				 zzCONSUME;
			}
			else {
				if ( (LA(1)==QuotedTerm) ) {
					zzmatch(QuotedTerm);
					if ( go ) t=mystrdup(LATEXT(1));  
					 zzCONSUME;
				}
				else {zzFAIL(1,zzerr2,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
			}
		}
		zzEXIT(zztasp2);
		}
	}
	zzNON_GUESS_MODE {
	if ( go ) list_add(&(e->elist), t);  
	}
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (setwd1[LA(1)]&0x20) ) {
			{
				zzBLOCK(zztasp3);
				zzMake0;
				{
				if ( (LA(1)==NonTerminal) ) {
					zzmatch(NonTerminal);
					if ( go ) t=mystrdup(LATEXT(1));  
					 zzCONSUME;
				}
				else {
					if ( (LA(1)==TokenTerm) ) {
						zzmatch(TokenTerm);
						if ( go ) t=mystrdup(LATEXT(1));  
						 zzCONSUME;
					}
					else {
						if ( (LA(1)==QuotedTerm) ) {
							zzmatch(QuotedTerm);
							if ( go ) t=mystrdup(LATEXT(1));  
							 zzCONSUME;
						}
						else {zzFAIL(1,zzerr3,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
					}
				}
				zzEXIT(zztasp3);
				}
			}
			zzNON_GUESS_MODE {
			if ( go ) list_add(&(e->elist), t);  
			}
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
	zzmatch(84); zzCONSUME;
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	zzsyn(zzMissText, zzBadTok, "", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd1, 0x40);
	}
}

#ifdef __STDC__
void
token()
#else
token()
#endif
{
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
	char *t=NULL, *e=NULL, *a=NULL;  
	zzmatch(85); zzCONSUME;
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==TokenTerm) ) {
			zzmatch(TokenTerm);
			t=mystrdup(LATEXT(1));  
			 zzCONSUME;
		}
		zzEXIT(zztasp2);
		}
	}
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==QuotedTerm) ) {
			zzmatch(QuotedTerm);
			e=mystrdup(LATEXT(1));  
			 zzCONSUME;
		}
		zzEXIT(zztasp2);
		}
	}
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		if ( (LA(1)==Action) ) {
			zzmatch(Action);
			
			a = (char *) calloc(strlen(LATEXT(1))+1, sizeof(char));
			require(a!=NULL, "rule token: cannot allocate action");
			strcpy(a, LATEXT(1));
			 zzCONSUME;
		}
		zzEXIT(zztasp2);
		}
	}
	zzNON_GUESS_MODE {
	chkToken(t, e, a);  
	}
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	CannotContinue=TRUE;  
	zzsyn(zzMissText, zzBadTok, "", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd1, 0x80);
	}
}

#ifdef __STDC__
void
block()
#else
block()
#endif
{
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
	
	Graph g, b;
	alt();
	zzNON_GUESS_MODE {
	b = g = zzaArg(zztasp1,1);  
	}
	zzNON_GUESS_MODE {
	
	if ( ((Junction *)g.left)->p1->ntype == nAction )
	{
		if ( !((ActionNode *)(((Junction *)g.left)->p1))->is_predicate )
		{
			((ActionNode *)(((Junction *)g.left)->p1))->init_action = TRUE;
		}
	}
	}
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (LA(1)==86) ) {
			zzmatch(86); zzCONSUME;
			alt();
			zzNON_GUESS_MODE {
			g = Or(g, zzaArg(zztasp2,2));  
			}
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
	zzNON_GUESS_MODE {
	zzaArg(zztasp1,0) = b;  
	}
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	CannotContinue=TRUE;  
	zzsyn(zzMissText, zzBadTok, "", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd2, 0x1);
	}
}

#ifdef __STDC__
void
alt()
#else
alt()
#endif
{
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
	int n=0; Graph g; g.left=g.right=NULL;  
	{
		zzBLOCK(zztasp2);
		zzMake0;
		{
		while ( (setwd2[LA(1)]&0x2) ) {
			element();
			zzNON_GUESS_MODE {
			n++; g = Cat(g, zzaArg(zztasp2,1));  
			}
			zzLOOP(zztasp2);
		}
		zzEXIT(zztasp2);
		}
	}
	zzNON_GUESS_MODE {
	if ( n == 0 ) g = emptyAlt();
	zzaArg(zztasp1,0) = g;
	}
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	CannotContinue=TRUE;  
	zzsyn(zzMissText, zzBadTok, "", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd2, 0x4);
	}
}

#ifdef __STDC__
void
element()
#else
element()
#endif
{
	zzRULE;
	zzBLOCK(zztasp1);
	zzMake0;
	{
	TokNode *p; RuleRefNode *q;  
	if ( (LA(1)==TokenTerm) ) {
		zzmatch(TokenTerm);
		zzaArg(zztasp1,0) = buildToken(LATEXT(1));  
		 zzCONSUME;
		{
			zzBLOCK(zztasp2);
			zzMake0;
			{
			p = (TokNode *) ((Junction *)zzaRet.left)->p1;  
			if ( (LA(1)==87) ) {
				zzmatch(87);
				p->astnode=ASTroot;  
				 zzCONSUME;
			}
			else {
				if ( (setwd2[LA(1)]&0x8) ) {
					zzNON_GUESS_MODE {
					p->astnode=ASTchild;  
					}
				}
				else {
					if ( (LA(1)==74) ) {
						zzmatch(74);
						p->astnode=ASTexclude;  
						 zzCONSUME;
					}
					else {zzFAIL(1,zzerr4,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
				}
			}
			zzEXIT(zztasp2);
			}
		}
	}
	else {
		if ( (LA(1)==QuotedTerm) ) {
			zzmatch(QuotedTerm);
			zzaArg(zztasp1,0) = buildToken(LATEXT(1));  
			 zzCONSUME;
			{
				zzBLOCK(zztasp2);
				zzMake0;
				{
				p = (TokNode *) ((Junction *)zzaRet.left)->p1;  
				if ( (LA(1)==87) ) {
					zzmatch(87);
					p->astnode=ASTroot;  
					 zzCONSUME;
				}
				else {
					if ( (setwd2[LA(1)]&0x10) ) {
						zzNON_GUESS_MODE {
						p->astnode=ASTchild;  
						}
					}
					else {
						if ( (LA(1)==74) ) {
							zzmatch(74);
							p->astnode=ASTexclude;  
							 zzCONSUME;
						}
						else {zzFAIL(1,zzerr5,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
					}
				}
				zzEXIT(zztasp2);
				}
			}
		}
		else {
			if ( (LA(1)==NonTerminal) ) {
				zzmatch(NonTerminal);
				zzaArg(zztasp1,0) = buildRuleRef(LATEXT(1));  
				 zzCONSUME;
				{
					zzBLOCK(zztasp2);
					zzMake0;
					{
					if ( (LA(1)==74) ) {
						zzmatch(74);
						q = (RuleRefNode *) ((Junction *)zzaRet.left)->p1;
						q->astnode=ASTexclude;  
						 zzCONSUME;
					}
					zzEXIT(zztasp2);
					}
				}
				{
					zzBLOCK(zztasp2);
					zzMake0;
					{
					if ( (setwd2[LA(1)]&0x20) ) {
						{
							zzBLOCK(zztasp3);
							zzMake0;
							{
							if ( (LA(1)==75) ) {
								zzmatch(75); zzCONSUME;
							}
							zzEXIT(zztasp3);
							}
						}
						zzmatch(PassAction);
						addParm(((Junction *)zzaRet.left)->p1, LATEXT(1));  
						 zzCONSUME;
					}
					zzEXIT(zztasp2);
					}
				}
				{
					zzBLOCK(zztasp2);
					zzMake0;
					{
					char *a; RuleRefNode *rr=(RuleRefNode *) ((Junction *)zzaRet.left)->p1;
					if ( (LA(1)==76) ) {
						zzmatch(76); zzCONSUME;
						zzmatch(PassAction);
						
						a = (char *) calloc(strlen(LATEXT(1))+1, sizeof(char));
						require(a!=NULL, "rule element: cannot allocate assignment");
						strcpy(a, LATEXT(1));
						rr->assign = a;
						 zzCONSUME;
					}
					zzEXIT(zztasp2);
					}
				}
			}
			else {
				if ( (LA(1)==Action) ) {
					zzmatch(Action);
					zzaArg(zztasp1,0) = buildAction(LATEXT(1),action_file,action_line, 0);  
					 zzCONSUME;
				}
				else {
					if ( (LA(1)==Pred) ) {
						zzmatch(Pred);
						zzaArg(zztasp1,0) = buildAction(LATEXT(1),action_file,action_line, 1);  
						 zzCONSUME;
						{
							zzBLOCK(zztasp2);
							zzMake0;
							{
							char *a; ActionNode *act = (ActionNode *) ((Junction *)zzaRet.left)->p1;  
							if ( (LA(1)==PassAction) ) {
								zzmatch(PassAction);
								
								a = (char *) calloc(strlen(LATEXT(1))+1, sizeof(char));
								require(a!=NULL, "rule element: cannot allocate predicate fail action");
								strcpy(a, LATEXT(1));
								act->pred_fail = a;
								 zzCONSUME;
							}
							zzEXIT(zztasp2);
							}
						}
					}
					else {
						if ( (LA(1)==88) ) {
							zzNON_GUESS_MODE {
							BlkLevel++;  
							}
							zzmatch(88); zzCONSUME;
							block();
							zzNON_GUESS_MODE {
							zzaArg(zztasp1,0) = zzaArg(zztasp1,2); --BlkLevel;  
							}
							zzmatch(89); zzCONSUME;
							{
								zzBLOCK(zztasp2);
								zzMake0;
								{
								if ( (LA(1)==90) ) {
									zzmatch(90);
									zzaRet = makeLoop(zzaRet);  
									 zzCONSUME;
								}
								else {
									if ( (LA(1)==91) ) {
										zzmatch(91);
										zzaRet = makePlus(zzaRet);  
										 zzCONSUME;
									}
									else {
										if ( (LA(1)==92) ) {
											zzmatch(92);
											zzaRet = makeBlk(zzaRet);
											FoundGuessBlk = 1;
											((Junction *) ((Junction *)zzaRet.left)->p1)->guess=1;
											 zzCONSUME;
										}
										else {
											if ( (setwd2[LA(1)]&0x40) ) {
												zzNON_GUESS_MODE {
												zzaRet = makeBlk(zzaRet);  
												}
											}
											else {zzFAIL(1,zzerr6,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
										}
									}
								}
								zzEXIT(zztasp2);
								}
							}
							{
								zzBLOCK(zztasp2);
								zzMake0;
								{
								if ( (LA(1)==PassAction) ) {
									zzmatch(PassAction);
									addParm(((Junction *)zzaRet.left)->p1, LATEXT(1));  
									 zzCONSUME;
								}
								zzEXIT(zztasp2);
								}
							}
						}
						else {
							if ( (LA(1)==83) ) {
								zzNON_GUESS_MODE {
								BlkLevel++;  
								}
								zzmatch(83); zzCONSUME;
								block();
								zzNON_GUESS_MODE {
								zzaArg(zztasp1,0) = makeOpt(zzaArg(zztasp1,2)); --BlkLevel;  
								}
								zzmatch(84); zzCONSUME;
								{
									zzBLOCK(zztasp2);
									zzMake0;
									{
									if ( (LA(1)==PassAction) ) {
										zzmatch(PassAction);
										addParm(((Junction *)zzaRet.left)->p1, LATEXT(1));  
										 zzCONSUME;
									}
									zzEXIT(zztasp2);
									}
								}
							}
							else {
								if ( (LA(1)==77) ) {
									zzmatch(77);
									warn(eMsg1("missing ';' on rule %s", CurRule));
									CannotContinue=TRUE;  
									 zzCONSUME;
								}
								else {
									if ( (LA(1)==90) ) {
										zzmatch(90);
										warn("don't you want a ')' with that '*'?"); CannotContinue=TRUE;  
										 zzCONSUME;
									}
									else {
										if ( (LA(1)==91) ) {
											zzmatch(91);
											warn("don't you want a ')' with that '+'?"); CannotContinue=TRUE;  
											 zzCONSUME;
										}
										else {
											if ( (LA(1)==76) ) {
												zzmatch(76);
												warn("'>' can only appear after a nonterminal"); CannotContinue=TRUE;  
												 zzCONSUME;
											}
											else {
												if ( (LA(1)==PassAction) ) {
													zzmatch(PassAction);
													warn("[...] out of context 'rule > [...]'");
													CannotContinue=TRUE;  
													 zzCONSUME;
												}
												else {zzFAIL(1,zzerr7,&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	zzEXIT(zztasp1);
	return;
fail:
	zzEXIT(zztasp1);
	CannotContinue=TRUE;  
	zzsyn(zzMissText, zzBadTok, "", zzMissSet, zzMissTok, zzErrk, zzBadText);
	zzresynch(setwd2, 0x80);
	}
}

/* semantics of #token */
static void
#ifdef __STDC__
chkToken(char *t, char *e, char *a)
#else
chkToken(t,e,a)
char *t, *e, *a;
#endif
{
	if ( t==NULL && e==NULL ) {			/* none found */
		warn("#token requires at least token name or rexpr");
	}
	else if ( t!=NULL && e!=NULL ) {	/* both found */
		Tklink(t, e);
		if ( a!=NULL ) {
			if ( hasAction(e) ) {
				warn(eMsg1("redefinition of action for %s; ignored",e));
			}
			else setHasAction(e, a);
		}
	}
	else if ( t!=NULL ) {				/* only one found */
		if ( Tnum( t ) == 0 ) addTname( t );
		else {
			warn(eMsg1("redefinition of token %s; ignored",t));
		}
		if ( a!=NULL ) {
			warn(eMsg1("action cannot be attached to a token name (%s); ignored",t));
			free(a);
		}
	}
	else if ( e!=NULL ) {
		if ( Tnum( e ) == 0 ) addTexpr( e );
		else {
			if ( hasAction(e) ) {
				warn(eMsg1("redefinition of action for %s; ignored",e));
			}
			else if ( a==NULL ) {
				warn(eMsg1("redefinition of expr %s; ignored",e));
			}
		}
		if ( a!=NULL ) setHasAction(e, a);
	}
}

/* This is designed for use with 1.10, but if created with 1.06,
* must define SetWordType.  Also define EOF for 1.06.
#define zzEOF_TOKEN 1
typedef unsigned SetWordType;
*/

/* ANTLR-specific syntax error message generator 
* (define USER_ZZSYN when compiling so don't get 2 definitions)
*/
void
#ifdef __STDC__
zzsyn(char *text, unsigned tok, char *egroup, SetWordType *eset, unsigned etok, int k, char *bad_text)
#else
zzsyn(text, tok, egroup, eset, etok, k, bad_text)
char *text, *egroup, *bad_text;
unsigned tok;
unsigned etok;
int k;
SetWordType *eset;
#endif
{
fprintf(stderr, ErrHdr, FileStr[CurFile]!=NULL?FileStr[CurFile]:"stdin", zzline);
fprintf(stderr, " syntax error at \"%s\"", (tok==zzEOF_TOKEN)?"EOF":text);
if ( !etok && !eset ) {fprintf(stderr, "\n"); return;}
if ( k==1 ) fprintf(stderr, " missing");
else
{
fprintf(stderr, "; \"%s\" not", bad_text);
if ( zzset_deg(eset)>1 ) fprintf(stderr, " in");
}
if ( zzset_deg(eset)>0 ) zzedecode(eset);
else fprintf(stderr, " %s", zztokens[etok]);
if ( strlen(egroup) > 0 ) fprintf(stderr, " in %s", egroup);
fprintf(stderr, "\n");
}
