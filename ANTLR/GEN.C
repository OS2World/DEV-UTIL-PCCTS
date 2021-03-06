/*
 * gen.c
 *
 * $Id: gen.c,v 1.17 1993/08/24 14:44:32 pccts Exp pccts $
 * $Revision: 1.17 $
 *
 * Generate C code (ANSI, K&R, C++)
 *
 * SOFTWARE RIGHTS
 *
 * We reserve no LEGAL rights to the Purdue Compiler Construction Tool
 * Set (PCCTS) -- PCCTS is in the public domain.  An individual or
 * company may do whatever they wish with source code distributed with
 * PCCTS or the code generated by PCCTS, including the incorporation of
 * PCCTS, or its output, into commerical software.
 * 
 * We encourage users to develop software with PCCTS.  However, we do ask
 * that credit is given to us for developing PCCTS.  By "credit",
 * we mean that if you incorporate our source code into one of your
 * programs (commercial product, research project, or otherwise) that you
 * acknowledge this fact somewhere in the documentation, research report,
 * etc...  If you like PCCTS and have developed a nice tool with the
 * output, please mention that you developed it using PCCTS.  In
 * addition, we ask that this header remain intact in our source code.
 * As long as these guidelines are kept, we expect to continue enhancing
 * this system and expect to make other tools available as they are
 * completed.
 *
 * ANTLR 1.10
 * Terence Parr
 * Purdue University
 * 1989-1993
 */
#include <stdio.h>
#ifdef __cplusplus
#ifndef __STDC__
#define __STDC__
#endif
#endif
#include <ctype.h>
#include "set.h"
#include "syn.h"
#include "hash.h"
#include "generic.h"
#include "dlgdef.h"

					/* T r a n s l a t i o n  T a b l e s */

/* C_Trans[node type] == pointer to function that knows how to translate that node. */
#ifdef __cplusplus
void (*C_Trans[NumNodeTypes+1])(...) = {
	NULL,
	NULL,					/* See next table.  Junctions have many types */
	(void (*)(...)) genRuleRef,
	(void (*)(...)) genToken,
	(void (*)(...)) genAction
};
#else
void (*C_Trans[NumNodeTypes+1])() = {
	NULL,
	NULL,					/* See next table.  Junctions have many types */
	genRuleRef,
	genToken,
	genAction
};
#endif

/* C_JTrans[Junction type] == pointer to function that knows how to translate that
 * kind of junction node.
 */
#ifdef __cplusplus
void (*C_JTrans[NumJuncTypes+1])(...) = {
	NULL,
	(void (*)(...)) genSubBlk,
	(void (*)(...)) genOptBlk,
	(void (*)(...)) genLoopBlk,
	(void (*)(...)) genEndBlk,
	(void (*)(...)) genRule,
	(void (*)(...)) genJunction,
	(void (*)(...)) genEndRule,
	(void (*)(...)) genPlusBlk,
	(void (*)(...)) genLoopBegin
};
#else
void (*C_JTrans[NumJuncTypes+1])() = {
	NULL,
	genSubBlk,
	genOptBlk,
	genLoopBlk,
	genEndBlk,
	genRule,
	genJunction,
	genEndRule,
	genPlusBlk,
	genLoopBegin
};
#endif

#define PastWhiteSpace(s)	while (*(s) == ' ' || *(s) == '\t') {s++;}

static int tabs = 0;
#define TAB { int i; for (i=0; i<tabs; i++) putc('\t', output); }
static void
#ifdef __STDC__
tab( void )
#else
tab( )
#endif
TAB

#ifdef __STDC__
static ActionNode *findImmedAction( Node * );
static void dumpRetValAssign(char *, char *);
static void dumpAfterActions(FILE *output);
static set ComputeErrorSet(Junction *, int);
static void makeErrorClause(Junction *, set, int);
static void DumpFuncHeader( Junction *, RuleEntry * );
static int has_guess_block_as_first_item(Junction *);
static int genExprSets(set *, int);
#else
static ActionNode *findImmedAction();
static void dumpRetValAssign();
static void dumpAfterActions();
static set ComputeErrorSet();
static void makeErrorClause();
static void DumpFuncHeader();
static int has_guess_block_as_first_item();
static int genExprSets();
#endif

#define gen(s)			{tab(); fprintf(output, s);}
#define gen1(s,a)		{tab(); fprintf(output, s,a);}
#define gen2(s,a,b)		{tab(); fprintf(output, s,a,b);}
#define gen3(s,a,b,c)	{tab(); fprintf(output, s,a,b,c);}
#define gen4(s,a,b,c,d)	{tab(); fprintf(output, s,a,b,c,d);}
#define gen5(s,a,b,c,d,e)	{tab(); fprintf(output, s,a,b,c,d,e);}
#define gen6(s,a,b,c,d,e,f)	{tab(); fprintf(output, s,a,b,c,d,e,f);}

#define _gen(s)			{fprintf(output, s);}
#define _gen1(s,a)		{fprintf(output, s,a);}
#define _gen2(s,a,b)	{fprintf(output, s,a,b);}
#define _gen3(s,a,b,c)	{fprintf(output, s,a,b,c);}
#define _gen4(s,a,b,c,d){fprintf(output, s,a,b,c,d);}
#define _gen5(s,a,b,c,d,e){fprintf(output, s,a,b,c,d,e);}

static void
#ifdef __STDC__
warn_about_using_gk_option(void)
#else
warn_about_using_gk_option()
#endif
{
	static int warned_already=0;

	if ( !DemandLookahead || warned_already ) return;
	warned_already = 1;
	warnNoFL("-gk option could cause trouble for <<...>>? predicates");
}

void
#ifdef __STDC__
freeBlkFsets( Junction *q )
#else
freeBlkFsets( q )
Junction *q;
#endif
{
	int i;
	Junction *alt;
	require(q!=NULL, "freeBlkFsets: invalid node");

	for (alt=q; alt != NULL; alt= (Junction *) alt->p2 )
	{
		for (i=1; i<=CLL_k; i++) set_free(alt->fset[i]);
	}
}

static void
#ifdef __STDC__
BLOCK_Head( void )
#else
BLOCK_Head( )
#endif
{
	gen("{\n");
	tabs++;
	gen1("zzBLOCK(zztasp%d);\n", BlkLevel);
}

static void
#ifdef __STDC__
BLOCK_Tail( void )
#else
BLOCK_Tail( )
#endif
{
	gen1("zzEXIT(zztasp%d);\n", BlkLevel);
	gen("}\n");
	tabs--;
	gen("}\n");
}

static void
#ifdef __STDC__
BLOCK_Preamble( Junction *q )
#else
BLOCK_Preamble( q )
Junction *q;
#endif
{
	ActionNode *a;
	Junction *begin;

	BLOCK_Head();
	if ( q->jtype == aPlusBlk ) gen("int zzcnt=1;\n");
	if ( q->parm != NULL ) gen1("zzaPush(%s);\n", q->parm)
	else gen("zzMake0;\n");
	gen("{\n");
	if ( q->jtype == aLoopBegin ) begin = (Junction *) ((Junction *)q->p1);
	else begin = q;
	if ( has_guess_block_as_first_item(begin) )
	{
		gen("zzGUESS_BLOCK\n");
	}
	if ( q->jtype == aLoopBegin )
		a = findImmedAction( ((Junction *)q->p1)->p1 );	/* look at aLoopBlk */
	else
		a = findImmedAction( q->p1 );
	if ( a!=NULL && !a->is_predicate ) {
		dumpAction(a->action, output, tabs, a->file, a->line, 1);
		a->done = 1;	/* remove action. We have already handled it */
	}
}

static void
#ifdef __STDC__
genExprTree( Tree *t, int k )
#else
genExprTree( t, k )
Tree *t;
int k;
#endif
{
	require(t!=NULL, "genExprTree: NULL tree");
	
	if ( t->token == ALT )
	{
		_gen("("); genExprTree(t->down, k); _gen(")");
		if ( t->right!=NULL )
		{
			_gen("||");
			_gen("("); genExprTree(t->right, k); _gen(")");
		}
		return;
	}
	if ( t->down!=NULL ) _gen("(");
	_gen1("LA(%d)==",k);
	if ( TokenStr[t->token] == NULL ) _gen1("%d", t->token)
	else _gen1("%s", TokenStr[t->token]);
	if ( t->down!=NULL )
	{
		_gen("&&");
		_gen("("); genExprTree(t->down, k+1); _gen(")");
	}
	if ( t->down!=NULL ) _gen(")");
	if ( t->right!=NULL )
	{
		_gen("||");
		_gen("("); genExprTree(t->right, k); _gen(")");
	}
}

/*
 * Generate LL(k) type expressions of the form:
 *
 *		 (LA(1) == T1 || LA(1) == T2 || ... || LA(1) == Tn) &&
 *		 (LA(2) == T1 || LA(2) == T2 || ... || LA(2) == Tn) &&
 *			.....
 *		 (LA(k) == T1 || LA(k) == T2 || ... || LA(k) == Tn)
 *
 * If GenExprSets generate:
 *
 *		(setwdi[LA(1)]&(1<<j)) && (setwdi[LA(2)]&(1<<j)) ...
 *
 * where n is set_deg(expr) and Ti is some random token and k is the last nonempty
 * set in fset <=CLL_k.
 * k=1..CLL_k where CLL_k >= 1.
 *
 * This routine is visible only to this file and cannot answer a TRANS message.
 *
 * TJP June '93: If predicates are allowed in parsing expressions:
 *
 * (	production 1
 * |	production 2
 * ...
 * |	production n
 * )
 *
 * where production 1 yields visible predicates: <<pred>>? <<pred2>>?
 *
 * generates:
 *
 * if ( (context_of_pred && pred) &&
 *		(context_of_pred2 && pred2) &&
 *		(production 1 prediction) ) {
 * 		...
 * }
 * else if ( production 2 prediction ) {
 * 		...
 * }
 * ...
 *
 * If no context, then just test expression.
 */
static int
#ifdef __STDC__
genExpr( Junction *j )
#else
genExpr( j )
Junction *j;
#endif
{
	int max_k, context_was_present=0;

	if ( ParseWithPredicates && j->predicate!=NULL )
	{
		Predicate *p = j->predicate;
		warn_about_using_gk_option();
		_gen("(");
		while ( p!=NULL )
		{
			if ( HoistPredicateContext )
			{
				context_was_present = 0;
				if ( LL_k>1 && p->tcontext!=NULL )
				{
					context_was_present = 1;
					_gen("((");
					genExprTree(p->tcontext, 1);
					_gen(") && (");
				}
				else if ( LL_k==1 && set_deg(p->scontext[1])>0 )
				{
					context_was_present = 1;
					_gen("((");
					genExprSets(&(p->scontext[0]), CLL_k);
					_gen(") && (");
				}
			}

			dumpAction(p->expr, output, 0, j->file, j->line, 0);

			if ( HoistPredicateContext && context_was_present )
			{
				_gen("))");
			}
			p = p->next;
			if ( p!=NULL ) _gen(" && ");
		}
		_gen(") && (");
	}

	/* if full LL(k) is sufficient, then don't use approximate (-ck) lookahead
	 * from CLL_k..LL_k
	 */
	{
		int limit;
		if ( j->ftree!=NULL ) limit = LL_k;
		else limit = CLL_k;
		max_k = genExprSets(j->fset, limit);
	}

	/* Do tests for real tuples from other productions that conflict with
	 * artificial tuples generated by compression (using sets of tokens
	 * rather than k-trees).
	 */
	if ( j->ftree != NULL )
	{
		_gen(" && !("); genExprTree(j->ftree, 1); _gen(")");
	}
	if ( ParseWithPredicates && j->predicate!=NULL ) _gen(")");
	return max_k;
}

static int
#ifdef __STDC__
genExprSets( set *fset, int limit )
#else
genExprSets( fset, limit )
set *fset;
int limit;
#endif
{
	int k = 1;
	int max_k = 0;
	unsigned *e, *g, firstTime=1;

	if ( GenExprSets )
	{
		while ( !set_nil(fset[k]) && k<=limit )
		{
			if ( set_deg(fset[k])==1 )	/* too simple for a set? */
			{
				int e;
				_gen1("(LA(%d)==",k);
				e = set_int(fset[k]);
				if ( TokenStr[e] == NULL ) _gen1("%d)", e)
				else _gen1("%s)", TokenStr[e]);
			}
			else
			{
				NewSet();
				FillSet( fset[k] );
				_gen3("(setwd%d[LA(%d)]&0x%x)", wordnum, k, 1<<setnum);
			}
			if ( k>max_k ) max_k = k;
			if ( k == CLL_k ) break;
			k++;
			if ( !set_nil(fset[k]) && k<=limit ) _gen(" && ");
		}
		return max_k;
	}

	while ( !set_nil(fset[k]) && k<=limit )
	{
		if ( (e=g=set_pdq(fset[k])) == NULL ) fatal("genExpr: cannot allocate IF expr pdq set");
		for (; *e!=nil; e++)
		{
			if ( !firstTime ) _gen(" || ") else { _gen("("); firstTime = 0; }
			_gen1("LA(%d)==",k);
			if ( TokenStr[*e] == NULL ) _gen1("%d", *e)
			else _gen1("%s", TokenStr[*e]);
		}
		free( g );
		_gen(")");
		if ( k>max_k ) max_k = k;
		if ( k == CLL_k ) break;
		k++;
		if ( !set_nil(fset[k]) && k<=limit ) { firstTime=1; _gen(" && "); }
	}
	return max_k;
}

/*
 * Generate code for any type of block.  If the last alternative in the block is
 * empty (not even an action) don't bother doing it.  This permits us to handle
 * optional and loop blocks as well.
 *
 * Only do this block, return after completing the block.
 * This routine is visible only to this file and cannot answer a TRANS message.
 */
static set
#ifdef __STDC__
genBlk( Junction *q, int jtype, int *max_k, int *need_right_curly )
#else
genBlk( q, jtype, max_k, need_right_curly )
Junction *q;
int jtype;
int *max_k;
int *need_right_curly;
#endif
{
	set f;
	Junction *alt;
	int a_guess_in_block = 0;
	require(q!=NULL,				"genBlk: invalid node");
	require(q->ntype == nJunction,	"genBlk: not junction");

	*need_right_curly=0;
	if ( q->p2 == NULL )	/* only one alternative?  Then don't need if */
	{	
		if ( first_item_is_guess_block((Junction *)q->p1)!=NULL )
		{
			warnFL("(...)? as only alternative of block is unnecessary", FileStr[q->file], q->line);
			gen("zzGUESS\n");	/* guess anyway to make output code consistent */
			gen("if ( !zzrv )\n");
		}
		TRANS(q->p1);
		return empty;		/* no decision to be made-->no error set */
	}

	f = First(q, 1, jtype, max_k);
	for (alt=q; alt != NULL; alt= (Junction *) alt->p2 )
	{
		if ( alt->p2 == NULL )					/* chk for empty alt */
		{	
			Node *p = alt->p1;
			if ( p->ntype == nJunction )
			{
				/* we have empty alt */
				if ( ((Junction *)p)->p1 == (Node *)q->end )
				{
					break;						/* don't do this one, quit */
				}
			}
		}
		if ( alt != q ) gen("else ")
		else
		{
			if ( DemandLookahead ) gen1("LOOK(%d);\n", *max_k);
		}
		if ( alt!=q )
		{
			_gen("{\n");
			tabs++;
			(*need_right_curly)++;
			/* code to restore state if a prev alt didn't follow guess */
			if ( a_guess_in_block ) gen("if ( zzguessing ) zzGUESS_DONE;\n");
		}
		if ( first_item_is_guess_block((Junction *)alt->p1)!=NULL )
		{
			a_guess_in_block = 1;
			gen("zzGUESS\n");
		}
		gen("if ( ");
		if ( first_item_is_guess_block((Junction *)alt->p1)!=NULL ) _gen("!zzrv && ");
		genExpr(alt);
		_gen(" ) ");
		_gen("{\n");
		tabs++;
		TRANS(alt->p1);
		--tabs;
		gen("}\n");
	}
	return f;
}

static int
#ifdef __STDC__
has_guess_block_as_first_item( Junction *q )
#else
has_guess_block_as_first_item( q )
Junction *q;
#endif
{
	Junction *alt;

	for (alt=q; alt != NULL; alt= (Junction *) alt->p2 )
	{
		if ( first_item_is_guess_block((Junction *)alt->p1)!=NULL ) return 1;
	}
	return 0;
}

/* return NULL if 1st item of alt is (...)? block; else return ptr to aSubBlk node
 * of (...)?;  This function ignores actions and predicates.
 */
Junction *
#ifdef __STDC__
first_item_is_guess_block( Junction *q )
#else
first_item_is_guess_block( q )
Junction *q;
#endif
{
	while ( q!=NULL && ((q->ntype==nJunction && q->jtype==Generic) || q->ntype==nAction) )
	{
		if ( q->ntype==nJunction ) q = (Junction *)q->p1;
		else q = (Junction *) ((ActionNode *)q)->next;
	}

	if ( q==NULL ) return NULL;
	if ( q->ntype!=nJunction ) return NULL;
	if ( q->jtype!=aSubBlk ) return NULL;
	if ( !q->guess ) return NULL;
	return q;
}

/* Generate an action.  Don't if action is NULL which means that it was already
 * handled as an init action.
 */
void
#ifdef __STDC__
genAction( ActionNode *p )
#else
genAction( p )
ActionNode *p;
#endif
{
	require(p!=NULL,			"genAction: invalid node and/or rule");
	require(p->ntype==nAction,	"genAction: not action");
	
	if ( !p->done )
	{
		if ( p->is_predicate )
		{
			gen("if (!(");
			dumpAction(p->action, output, 0, p->file, p->line, 0);
			if ( p->pred_fail != NULL ) {_gen1(")) {{%s};}\n", p->pred_fail);}
			else _gen1(")) {zzfailed_pred(\"%s\");}\n",p->action);
		}
		else
		{
			gen("zzNON_GUESS_MODE {\n");
			dumpAction(p->action, output, tabs, p->file, p->line, 1);
			gen("}\n");
		}
/*		p->done = 1; */
	}
	TRANS(p->next)
}

/*
 *		if invoking rule has !noAST pass zzSTR to rule ref and zzlink it in
 *		else pass addr of temp root ptr (&_ast) (don't zzlink it in).
 *
 *		if ! modifies rule-ref, then never link it in and never pass zzSTR.
 *		Always pass address of temp root ptr.
 */
void
#ifdef __STDC__
genRuleRef( RuleRefNode *p )
#else
genRuleRef( p )
RuleRefNode *p;
#endif
{
	Junction *q;
	RuleEntry *r, *r2;
	char *parm = "";
	require(p!=NULL,			"genRuleRef: invalid node and/or rule");
	require(p->ntype==nRuleRef, "genRuleRef: not rule reference");
	
	r = (RuleEntry *) hash_get(Rname, p->text);
	if ( r == NULL ) {warnNoFL( eMsg1("rule %s not defined", p->text) ); return;}
	r2 = (RuleEntry *) hash_get(Rname, p->rname);
	if ( r2 == NULL ) {warnNoFL("Rule hash table is screwed up beyond belief"); return;}

	tab();
	if ( GenAST )
	{
		if ( r2->noAST || p->astnode==ASTexclude )
		{
			_gen("_ast = NULL; ");
			parm = "&_ast";
		}
		else parm = "zzSTR";
		if ( p->assign!=NULL )
		{
			if ( !HasComma(p->assign) ) {_gen1("%s = ",p->assign);}
			else _gen1("{ struct _rv%d _trv; _trv = ", r->rulenum);
		}
		_gen5("%s%s(%s%s%s);", RulePrefix,
							   p->text,
							   parm,
							   (p->parms!=NULL)?",":"",
							   (p->parms!=NULL)?p->parms:"");
		if ( !r2->noAST && p->astnode == ASTinclude )
		{
			_gen(" zzlink(_root, &_sibling, &_tail);");
		}
	}
	else
	{
		if ( p->assign!=NULL )
		{
			if ( !HasComma(p->assign) ) {_gen1("%s = ",p->assign);}
			else _gen1("{ struct _rv%d _trv; _trv = ", r->rulenum);
		}
        _gen3("%s%s(%s);", RulePrefix, p->text, (p->parms!=NULL)?p->parms:"");
	}
	q = RulePtr[r->rulenum];	/* find definition of ref'd rule */
	if ( p->assign!=NULL )
		if ( HasComma(p->assign) )
		{
			dumpRetValAssign(p->assign, q->ret);
			_gen("}");
		}
	_gen("\n");
	TRANS(p->next)
}

/*
 * Generate code to match a token.
 *
 * Getting the next token is tricky.  We want to ensure that any action
 * following a token is executed before the next GetToken();
 */ 
void
#ifdef __STDC__
genToken( TokNode *p )
#else
genToken( p )
TokNode *p;
#endif
{
	RuleEntry *r;
	ActionNode *a;
	require(p!=NULL,			"genToken: invalid node and/or rule");
	require(p->ntype==nToken,	"genToken: not token");
	
	r = (RuleEntry *) hash_get(Rname, p->rname);
	if ( r == NULL ) {warnNoFL("Rule hash table is screwed up beyond belief"); return;}
	if ( TokenStr[p->token]!=NULL ) gen1("zzmatch(%s);", TokenStr[p->token])
	else gen1("zzmatch(%d);", p->token);
	a = findImmedAction( p->next );
	if ( GenAST )
	{
		if ( !r->noAST )
		{
			if ( p->astnode==ASTchild )
				{_gen(" zzsubchild(_root, &_sibling, &_tail);");}
			else if ( p->astnode==ASTroot )
				{_gen(" zzsubroot(_root, &_sibling, &_tail);");}
			else
				{_gen(" zzastDPush;");}
		}
		else _gen(" zzastDPush;");
	}
	if ( a != NULL )
	{
		/* delay next token fetch until after action */
		_gen("\n");
		if ( a->is_predicate )
		{
			gen("if (!(");
			dumpAction(a->action, output, 0, a->file, a->line, 0);
			_gen1(")) {zzfailed_pred(\"%s\");}\n",a->action);
		}
		else
		{
			dumpAction(a->action, output, tabs, a->file, a->line, 1);
		}
		a->done = 1;
		if ( !DemandLookahead ) {gen(" zzCONSUME;\n");}
		else gen("\n");
		TRANS( a->next );
	}
	else
	{
		if ( !DemandLookahead ) {_gen(" zzCONSUME;\n");}
		else gen("\n");
		TRANS(p->next);
	}
}

void
#ifdef __STDC__
genOptBlk( Junction *q )
#else
genOptBlk( q )
Junction *q;
#endif
{
	int max_k;
	set f;
	int need_right_curly;
	require(q!=NULL,				"genOptBlk: invalid node and/or rule");
	require(q->ntype == nJunction,	"genOptBlk: not junction");
	require(q->jtype == aOptBlk,	"genOptBlk: not optional block");

	BLOCK_Preamble(q);
	BlkLevel++;
	f = genBlk(q, aOptBlk, &max_k, &need_right_curly);
	set_free(f);
	freeBlkFsets(q);
	BlkLevel--;
	{ int i; for (i=1; i<=need_right_curly; i++) {tabs--; gen("}\n");} }
	BLOCK_Tail();
	if (q->end->p1 != NULL) TRANS(q->end->p1);
}

/*
 * Generate code for a loop blk of form:
 *
 *				 |---|
 *				 v   |
 *			   --o-G-o-->o--
 */
void
#ifdef __STDC__
genLoopBlk( Junction *q, Junction *begin, int max_k )
#else
genLoopBlk( q, begin, max_k )
Junction *q;
Junction *begin;
int max_k;
#endif
{
	int dum_k;
	set f;
	int need_right_curly;
	require(q->ntype == nJunction,	"genLoopBlk: not junction");
	require(q->jtype == aLoopBlk,	"genLoopBlk: not loop block");

	if ( q->visited ) return;
	q->visited = TRUE;
	if ( q->p2 == NULL )	/* only one alternative? */
	{
		f = First(q, 1, aLoopBlk, &dum_k);
		if ( DemandLookahead ) gen1("LOOK(%d);\n", max_k);
		gen("while ( ");
		if ( begin!=NULL )
		{
			genExpr(begin);
		}
		else genExpr(q);
		_gen(" ) {\n");
		tabs++;
		TRANS(q->p1);
		gen1("zzLOOP(zztasp%d);\n", BlkLevel-1);
		if ( DemandLookahead ) gen1("LOOK(%d);\n", max_k);
		--tabs;
		gen("}\n");
		freeBlkFsets(q);
		set_free(f);
		q->visited = FALSE;
		return;
	}
	gen("while ( 1 ) {\n");
	tabs++;
	if ( begin!=NULL )
	{
		if ( DemandLookahead ) gen1("LOOK(%d);\n",max_k);
		gen("if ( ");
		genExpr((Junction *)begin->p2);
		_gen(" ) break;\n");
	}
	f = genBlk(q, aLoopBlk, &max_k, &need_right_curly);
	set_free(f);
	freeBlkFsets(q);
	if ( begin==NULL ) gen("else break;\n");		/* code for exiting loop */
	{ int i; for (i=1; i<=need_right_curly; i++) {tabs--; gen("}\n");} }
	gen1("zzLOOP(zztasp%d);\n", BlkLevel-1);
	--tabs;
	gen("}\n");
	q->visited = FALSE;
}

/*
 * Generate code for a loop blk of form:
 *
 * 				         |---|
 *					     v   |
 *			   --o-->o-->o-G-o-->o--
 *                   |           ^
 *                   v           |
 *					 o-----------o
 *
 * q->end points to the last node (far right) in the blk.  Note that q->end->jtype
 * must be 'EndBlk'.
 *
 * Generate code roughly of the following form:
 *
 *	do {
 *		... code for alternatives ...
 *  } while ( First Set of aLoopBlk );
 *
 *	OR if > 1 alternative
 *
 *	do {
 *		... code for alternatives ...
 *		else break;
 *  } while ( 1 );
 */
void
#ifdef __STDC__
genLoopBegin( Junction *q )
#else
genLoopBegin( q )
Junction *q;
#endif
{
	set f;
	int i;
	int max_k;
	require(q!=NULL,				"genLoopBegin: invalid node and/or rule");
	require(q->ntype == nJunction,	"genLoopBegin: not junction");
	require(q->jtype == aLoopBegin,	"genLoopBegin: not loop block");
	require(q->p2!=NULL,			"genLoopBegin: invalid Loop Graph");

	BLOCK_Preamble(q);
	BlkLevel++;
	f = First(q, 1, aLoopBegin, &max_k);
	if ( LL_k>1 && !set_nil(q->fset[2]) )
		genLoopBlk( (Junction *)q->p1, q, max_k );
	else genLoopBlk( (Junction *)q->p1, NULL, max_k );
	for (i=1; i<=CLL_k; i++) set_free(q->fset[i]);
	for (i=1; i<=CLL_k; i++) set_free(((Junction *)q->p2)->fset[i]);
	--BlkLevel;
	BLOCK_Tail();
	set_free(f);
	if (q->end->p1 != NULL) TRANS(q->end->p1);
}

/*
 * Generate code for a loop blk of form:
 *
 * 					 |---|
 *					 v   |
 *			       --o-G-o-->o--
 *
 * q->end points to the last node (far right) in the blk.  Note that q->end->jtype
 * must be 'EndBlk'.
 *
 * Generate code roughly of the following form:
 *
 *	do {
 *		... code for alternatives ...
 *  } while ( First Set of aPlusBlk );
 *
 *	OR if > 1 alternative
 *
 *	do {
 *		... code for alternatives ...
 *		else if not 1st time through, break;
 *  } while ( 1 );
 */
void
#ifdef __STDC__
genPlusBlk( Junction *q )
#else
genPlusBlk( q )
Junction *q;
#endif
{
	int max_k;
	set f;
	int need_right_curly;
	require(q!=NULL,				"genPlusBlk: invalid node and/or rule");
	require(q->ntype == nJunction,	"genPlusBlk: not junction");
	require(q->jtype == aPlusBlk,	"genPlusBlk: not Plus block");

	if ( q->visited ) return;
	q->visited = TRUE;
	BLOCK_Preamble(q);
	BlkLevel++;
	if ( q->p2 == NULL )	/* only one alternative? */
	{
		gen("do {\n");
		tabs++;
		TRANS(q->p1);
		gen1("zzLOOP(zztasp%d);\n", BlkLevel-1);
		f = First(q, 1, aPlusBlk, &max_k);
		if ( DemandLookahead ) gen1("LOOK(%d);\n", max_k);
		--tabs;
		gen("} while ( ");
		genExpr(q);
		_gen(" );\n");
		--BlkLevel;
		BLOCK_Tail();
		q->visited = FALSE;
		freeBlkFsets(q);
		set_free(f);
		if (q->end->p1 != NULL) TRANS(q->end->p1);
		return;
	}
	gen("do {\n");
	tabs++;
	f = genBlk(q, aPlusBlk, &max_k, &need_right_curly);
	gen("else if ( zzcnt>1 ) break; ");/* code for exiting loop */
	makeErrorClause(q,f,max_k);
	{ int i; for (i=1; i<=need_right_curly; i++) {tabs--; gen("}\n");} }
	freeBlkFsets(q);
	gen1("zzcnt++; zzLOOP(zztasp%d);\n", BlkLevel-1);
	if ( DemandLookahead ) gen1("LOOK(%d);\n", max_k);
	--tabs;
	gen("} while ( 1 );\n");
	--BlkLevel;
	BLOCK_Tail();
	q->visited = FALSE;
	if (q->end->p1 != NULL) TRANS(q->end->p1);
}

/*
 * Generate code for a sub blk of alternatives of form:
 *
 *			       --o-G1--o--
 *					 |     ^
 *					 v    /|
 *			         o-G2-o|
 *					 |     ^
 *					 v     |
 *				   ..........
 *					 |     ^
 *					 v    /
 *			         o-Gn-o
 *
 * q points to the 1st junction of blk (upper-left).
 * q->end points to the last node (far right) in the blk.  Note that q->end->jtype
 * must be 'EndBlk'.
 * The last node in every alt points to q->end.
 *
 * Generate code of the following form:
 *	if ( First(G1) ) {
 *		...code for G1...
 *	}
 *	else if ( First(G2) ) {
 *		...code for G2...
 *	}
 *	...
 *	else {
 *		...code for Gn...
 *	}
 */
void
#ifdef __STDC__
genSubBlk( Junction *q )
#else
genSubBlk( q )
Junction *q;
#endif
{
	int max_k;
	set f;
	int need_right_curly;
	require(q->ntype == nJunction,	"genSubBlk: not junction");
	require(q->jtype == aSubBlk,	"genSubBlk: not subblock");

	BLOCK_Preamble(q);
	BlkLevel++;
	f = genBlk(q, aSubBlk, &max_k, &need_right_curly);
	if ( q->p2 != NULL ) {tab(); makeErrorClause(q,f,max_k);}
	{ int i; for (i=1; i<=need_right_curly; i++) {tabs--; gen("}\n");} }
	freeBlkFsets(q);
	--BlkLevel;
	BLOCK_Tail();

	if ( q->guess )
	{
		gen("zzGUESS_DONE\n");
	}

	/* must duplicate if (alpha)?; one guesses (validates), the second pass matches */
	if ( q->guess && analysis_point(q)==q )
	{
		BLOCK_Preamble(q);
		BlkLevel++;
		f = genBlk(q, aSubBlk, &max_k, &need_right_curly);
		if ( q->p2 != NULL ) {tab(); makeErrorClause(q,f,max_k);}
		{ int i; for (i=1; i<=need_right_curly; i++) {tabs--; gen("}\n");} }
		freeBlkFsets(q);
		--BlkLevel;
		BLOCK_Tail();
	}

	if (q->end->p1 != NULL) TRANS(q->end->p1);
}

/*
 * Generate code for a rule.
 *
 *		rule--> o-->o-Alternatives-o-->o
 * Or,
 *		rule--> o-->o-Alternative-o-->o
 *
 * The 1st junction is a RuleBlk.  The second can be a SubBlk or just a junction
 * (one alternative--no block), the last is EndRule.
 * The second to last is EndBlk if more than one alternative exists in the rule.
 *
 * To get to the init-action for a rule, we must bypass the RuleBlk,
 * and possible SubBlk.
 * Mark any init-action as generated so genBlk() does not regenerate it.
 */
void
#ifdef __STDC__
genRule( Junction *q )
#else
genRule( q )
Junction *q;
#endif
{
	int max_k;
	set follow, rk, f;
	ActionNode *a;
	RuleEntry *r;
	static int file = -1;
	int need_right_curly;
	require(q->ntype == nJunction,	"genRule: not junction");
	require(q->jtype == RuleBlk,	"genRule: not rule");

	r = (RuleEntry *) hash_get(Rname, q->rname);
	if ( r == NULL ) warnNoFL("Rule hash table is screwed up beyond belief");
	if ( q->file != file )		/* open new output file if need to */
	{
		if ( output != NULL ) fclose( output );
		output = fopen(outname(FileStr[q->file]), "w");
		require(output != NULL, "genRule: can't open output file");
		if ( file == -1 ) genHdr1(q->file);
		else genHdr(q->file);
		file = q->file;
	}
	DumpFuncHeader(q,r);
	tabs++;
	if ( q->ret!=NULL )
	{
		if ( HasComma(q->ret) ) {gen1("struct _rv%d _retv;\n",r->rulenum);}
		else
		{
			tab();
			DumpType(q->ret, output);
			gen(" _retv;\n");
		}
	}
	gen("zzRULE;\n");
	gen1("zzBLOCK(zztasp%d);\n", BlkLevel);
	gen("zzMake0;\n");
	gen("{\n");

	if ( has_guess_block_as_first_item((Junction *)q->p1) )
	{
		gen("zzGUESS_BLOCK\n");
	}

	/* L o o k  F o r  I n i t  A c t i o n */
	if ( ((Junction *)q->p1)->jtype == aSubBlk )
		a = findImmedAction( ((Junction *)q->p1)->p1 );
	else
		a = findImmedAction( q->p1 );	/* only one alternative in rule */
	if ( a!=NULL && !a->is_predicate )
	{
		dumpAction(a->action, output, tabs, a->file, a->line, 1);
		a->done = 1;	/* ignore action. We have already handled it */
	}
	if ( TraceGen ) gen1("zzTRACEIN(\"%s\");\n", q->rname);

	BlkLevel++;
	q->visited = TRUE;				/* mark RULE as visited for FIRST/FOLLOW */
	f = genBlk((Junction *)q->p1, RuleBlk, &max_k, &need_right_curly);
	if ( q->p1 != NULL )
		if ( ((Junction *)q->p1)->p2 != NULL )
			{tab(); makeErrorClause((Junction *)q->p1,f,max_k);}
	{ int i; for (i=1; i<=need_right_curly; i++) {tabs--; gen("}\n");} }
	freeBlkFsets((Junction *)q->p1);
	q->visited = FALSE;
	--BlkLevel;
	gen1("zzEXIT(zztasp%d);\n", BlkLevel);

	if ( TraceGen ) gen1("zzTRACEOUT(\"%s\");\n", q->rname);

	if ( q->ret!=NULL ) gen("return _retv;\n") else gen("return;\n");
	/* E r r o r  R e c o v e r y */
	NewSet();
	rk = empty;
	REACH(q->end, 1, &rk, follow);
	FillSet( follow );
	set_free( follow );
	_gen("fail:\n");
	gen("zzEXIT(zztasp1);\n");
	if ( FoundGuessBlk ) gen("if ( zzguessing ) {zzGUESS_FAIL;}\n");
	if ( q->erraction!=NULL )
		dumpAction(q->erraction, output, tabs, q->file, q->line, 1);
	gen1("zzsyn(zzMissText, zzBadTok, %s, zzMissSet, zzMissTok, zzErrk, zzBadText);\n", r->egroup==NULL?"\"\"":r->egroup);
	gen2("zzresynch(setwd%d, 0x%x);\n", wordnum, 1<<setnum);

	if ( TraceGen ) gen1("zzTRACEOUT(\"%s\");\n", q->rname);

	if ( q->ret!=NULL ) gen("return _retv;\n");
	gen("}\n");
	tabs--;
	gen("}\n");
	if ( q->p2 != NULL ) {TRANS(q->p2);} /* generate code for next rule too */
	else dumpAfterActions( output );
}

static void
#ifdef __STDC__
DumpFuncHeader( Junction *q, RuleEntry *r )
#else
DumpFuncHeader( q, r )
Junction *q;
RuleEntry *r;
#endif
{
	/* A N S I */
	_gen("\n#ifdef __STDC__\n");
	if ( q->ret!=NULL )
	{
		if ( HasComma(q->ret) ) {gen1("struct _rv%d\n",r->rulenum);}
		else
		{
			DumpType(q->ret, output);
			gen("\n");
		}
	}
	else
	{
		_gen("void\n");
	}
	gen2("%s%s(", RulePrefix, q->rname);
	if ( GenAST )
	{
		_gen("AST **_root");
		if ( q->pdecl!=NULL ) _gen(",");
	}
	_gen1("%s)\n", (q->pdecl!=NULL)?q->pdecl:"");

	/* K & R */
	gen("#else\n");
	if ( q->ret!=NULL )
	{
		if ( HasComma(q->ret) ) {gen1("struct _rv%d\n",r->rulenum);}
		else
		{
			DumpType(q->ret, output);
			gen("\n");
		}
	}
	gen2("%s%s(", RulePrefix, q->rname);
	if ( GenAST )
	{
		_gen("_root");
		if ( q->pdecl!=NULL ) _gen(",");
	}

	DumpListOfParmNames( q->pdecl, output );
	gen(")\n");
	if ( GenAST ) gen("AST **_root;\n");
	DumpOldStyleParms( q->pdecl, output );
	gen("#endif\n");
	gen("{\n");
}

void
#ifdef __STDC__
genJunction( Junction *q )
#else
genJunction( q )
Junction *q;
#endif
{
	require(q->ntype == nJunction,	"genJunction: not junction");
	require(q->jtype == Generic,	"genJunction: not generic junction");

	if ( q->p1 != NULL ) TRANS(q->p1);
	if ( q->p2 != NULL ) TRANS(q->p2);
}

void
#ifdef __STDC__
genEndBlk( Junction *q )
#else
genEndBlk( q )
Junction *q;
#endif
{
}

void
#ifdef __STDC__
genEndRule( Junction *q )
#else
genEndRule( q )
Junction *q;
#endif
{
}

void
#ifdef __STDC__
genHdr( int file )
#else
genHdr( file )
int file;
#endif
{
	_gen("/*\n");
	_gen(" * A n t l r  T r a n s l a t i o n  H e a d e r\n");
	_gen(" *\n");
	_gen(" * Terence Parr, Hank Dietz and Will Cohen: 1989-1993\n");
	_gen(" * Purdue University Electrical Engineering\n");
	_gen1(" * ANTLR Version %s\n", Version);
	_gen(" */\n");
	_gen("#include <stdio.h>\n");
	_gen1("#define ANTLR_VERSION	%s\n", VersionDef);
	if ( strcmp(ParserName, DefaultParserName)!=0 )
		_gen2("#define %s %s\n", DefaultParserName, ParserName);
   	if ( strcmp(ParserName, DefaultParserName)!=0 )
		{_gen1("#include \"%s\"\n", RemapFileName);}
	if ( GenLineInfo ) _gen2(LineInfoFormatStr, 1, FileStr[file]);
	if ( HdrAction != NULL ) dumpAction( HdrAction, output, 0, -1, 0, 1);
	if ( FoundGuessBlk )
	{
		_gen("#define ZZCAN_GUESS\n");
		_gen("#include <setjmp.h>\n");
	}
	if ( OutputLL_k > 1 ) _gen1("#define LL_K %d\n", OutputLL_k);
	if ( GenAST ) _gen("#define GENAST\n\n");
	if ( DemandLookahead ) _gen("#define DEMAND_LOOK\n\n");
	_gen1("#define zzEOF_TOKEN %d\n", EofToken);
	_gen1("#define zzSET_SIZE %d\n", NumWords(TokenNum-1)*sizeof(unsigned));
	_gen("#include \"antlr.h\"\n");
	if ( GenAST ) _gen("#include \"ast.h\"\n\n");
    _gen1("#include \"%s\"\n", DefFileName);
	_gen("#include \"dlgdef.h\"\n");
	_gen1("#include \"%s\"\n", ModeFileName);
}

void
#ifdef __STDC__
genHdr1( int file )
#else
genHdr1( file )
int file;
#endif
{
	ListNode *p;

	genHdr(file);
	if ( GenAST )
	{
		_gen("#include \"ast.c\"\n");
		_gen("zzASTgvars\n\n");
	}
	_gen("ANTLR_INFO\n");
	if ( BeforeActions != NULL )
	{
		for (p = BeforeActions->next; p!=NULL; p=p->next)
			dumpAction( (char *)p->elem, output, 0, -1, 0, 1);
	}
}

void
#ifdef __STDC__
genStdPCCTSIncludeFile( FILE *f )
#else
genStdPCCTSIncludeFile( f )
FILE *f;
#endif
{
	fprintf(f,"/*\n");
	fprintf(f," * %s -- P C C T S  I n c l u d e\n", stdpccts);
	fprintf(f," *\n");
	fprintf(f," * Terence Parr, Hank Dietz and Will Cohen: 1989-1993\n");
	fprintf(f," * Purdue University Electrical Engineering\n");
	fprintf(f," * ANTLR Version %s\n", Version);
	fprintf(f," */\n");
	fprintf(f,"#include <stdio.h>\n");
	fprintf(f, "#define ANTLR_VERSION	%s\n", VersionDef);
	if ( strcmp(ParserName, DefaultParserName)!=0 )
		fprintf(f, "#define %s %s\n", DefaultParserName, ParserName);
	if ( strcmp(ParserName, DefaultParserName)!=0 )
		fprintf(f, "#include \"%s\"\n", RemapFileName);
	if ( HdrAction != NULL ) dumpAction( HdrAction, f, 0, -1, 0, 1);
	if ( OutputLL_k > 1 ) fprintf(f,"#define LL_K %d\n", OutputLL_k);
	if ( GenAST ) fprintf(f,"#define GENAST\n");
	if ( DemandLookahead ) fprintf(f,"#define DEMAND_LOOK\n");
	fprintf(f, "#define zzEOF_TOKEN %d\n", EofToken);
	fprintf(f, "#define zzSET_SIZE %d\n", NumWords(TokenNum-1)*sizeof(unsigned));
	fprintf(f,"#include \"antlr.h\"\n");
	if ( GenAST ) fprintf(f,"#include \"ast.h\"\n");
	fprintf(f,"#include \"%s\"\n", DefFileName);
	fprintf(f,"#include \"dlgdef.h\"\n");
	fprintf(f,"#include \"%s\"\n", ModeFileName);
}

/* dump action 's' to file 'output' starting at "local" tab 'tabs'
   Dump line information in front of action if GenLineInfo is set
   If file == -1 then GenLineInfo is ignored.
   The user may redefine the LineInfoFormatStr to his/her liking
   most compilers will like the default, however.

   June '93; changed so that empty lines are left alone so that
   line information is correct for the compiler/debuggers.
*/
void
#ifdef __STDC__
dumpAction( char *s, FILE *output, int tabs, int file, int line, int final_newline )
#else
dumpAction( s, output, tabs, file, line, final_newline )
char *s;
FILE *output;
int tabs;
int file;
int line;
int final_newline;
#endif
{
    int inDQuote, inSQuote;
    require(s!=NULL, 		"dumpAction: NULL action");
    require(output!=NULL,	eMsg1("dumpAction: output FILE is NULL for %s",s));

	if ( GenLineInfo && file != -1 )
	{
		fprintf(output, LineInfoFormatStr, line, FileStr[file]);
	}
    PastWhiteSpace( s );
	/* don't print a tab if first non-white char is a # (preprocessor command) */
	if ( *s!='#' ) {TAB;}
    inDQuote = inSQuote = FALSE;
    while ( *s != '\0' )
    {
        if ( *s == '\\' )
        {
            putc( *s++, output ); /* Avoid '"' Case */
            if ( *s == '\0' ) return;
            if ( *s == '\'' ) putc( *s++, output );
            if ( *s == '\"' ) putc( *s++, output );
        }
        if ( *s == '\'' )
        {
            if ( !inDQuote ) inSQuote = !inSQuote;
        }
        if ( *s == '"' )
        {
            if ( !inSQuote ) inDQuote = !inDQuote;
        }
        if ( *s == '\n' )
        {
            putc('\n', output);
			s++;
            PastWhiteSpace( s );
            if ( *s == '}' )
            {
                --tabs;
				TAB;
                putc( *s++, output );
                continue;
            }
            if ( *s == '\0' ) return;
			if ( *s != '#' )	/* #define, #endif etc.. start at col 1 */
            {
				TAB;
			}
        }
        if ( *s == '}' && !(inSQuote || inDQuote) )
        {
            --tabs;            /* Indent one fewer */
        }
        if ( *s == '{' && !(inSQuote || inDQuote) )
        {
            tabs++;            /* Indent one more */
        }
        putc( *s, output );
        s++;
    }
    if ( final_newline ) putc('\n', output);
}

static void
#ifdef __STDC__
dumpAfterActions( FILE *output )
#else
dumpAfterActions( output )
FILE *output;
#endif
{
	ListNode *p;
	require(output!=NULL, "dumpAfterActions: output file was NULL for some reason");
	if ( AfterActions != NULL )
	{
		for (p = AfterActions->next; p!=NULL; p=p->next)
			dumpAction( (char *)p->elem, output, 0, -1, 0, 1 );
	}
	fclose( output );
}

/*
 * Find the next action in the stream of execution.  Do not pass
 * junctions with more than one path leaving them.
 * Only pass generic junctions.
 *
 *	Scan forward while (generic junction with p2==NULL)
 *	If we stop on an action, return ptr to the action
 *	else return NULL;
 */
static ActionNode *
#ifdef __STDC__
findImmedAction( Node *q )
#else
findImmedAction( q )
Node *q;
#endif
{
	Junction *j;
	require(q!=NULL, "findImmedAction: NULL node");
	require(q->ntype>=1 && q->ntype<=NumNodeTypes, "findImmedAction: invalid node");
	
	while ( q->ntype == nJunction )
	{
		j = (Junction *)q;
		if ( j->jtype != Generic || j->p2 != NULL ) return NULL;
		q = j->p1;
		if ( q == NULL ) return NULL;
	}
	if ( q->ntype == nAction ) return (ActionNode *)q;
	return NULL;
}

static void
#ifdef __STDC__
dumpRetValAssign( char *retval, char *ret_def )
#else
dumpRetValAssign( retval, ret_def )
char *retval;
char *ret_def;
#endif
{
	char *q = ret_def;
	
	tab();
	while ( *retval != '\0' )
	{
		while ( isspace((*retval)) ) retval++;
		while ( *retval!=',' && *retval!='\0' ) putc(*retval++, output);
		fprintf(output, " = _trv.");
		
		DumpNextNameInDef(&q, output);
		putc(';', output); putc(' ', output);
		if ( *retval == ',' ) retval++;
	}
}

/* This function computes the set of tokens that can possibly be seen k
 * tokens in the future from point j
 */
static set
#ifdef __STDC__
ComputeErrorSet( Junction *j, int k )
#else
ComputeErrorSet( j, k )
Junction *j;
int k;
#endif
{
	Junction *alt1;
	set a, rk, f;
	require(j->ntype==nJunction, "ComputeErrorSet: non junction passed");

	f = rk = empty;
	for (alt1=j; alt1!=NULL; alt1 = (Junction *)alt1->p2)
	{
		REACH(alt1->p1, k, &rk, a);
		require(set_nil(rk), "ComputeErrorSet: rk != nil");
		set_free(rk);
		set_orin(&f, a);
		set_free(a);
	}
	return f;
}

static void
#ifdef __STDC__
makeErrorClause( Junction *q, set f, int max_k )
#else
makeErrorClause( q, f, max_k )
Junction *q;
set f;
int max_k;
#endif
{
	if ( max_k == 1 )
	{
		_gen1("else {zzFAIL(1,zzerr%d", DefErrSet(&f))
		set_free(f);
	}
	else
	{
		int i;
		set_free(f);
		_gen1("else {zzFAIL(%d", max_k);
		for (i=1; i<=max_k; i++)
		{
			f = ComputeErrorSet(q, i);
			_gen1(",zzerr%d", DefErrSet( &f ));
			set_free(f);
		}
	}
	_gen(",&zzMissSet,&zzMissText,&zzBadTok,&zzBadText,&zzErrk); goto fail;}\n");
}
