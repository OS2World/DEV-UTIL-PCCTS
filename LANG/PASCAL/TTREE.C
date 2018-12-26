/*	Code to manage type trees for each type
 *  These trees then can be used to determine whether varibles have the
 *  same type.
 *
 *  Will Cohen
 *  12/18/90
 */

#include <stdio.h>
#include "ttree.h"

#define TRUE	1
#define FALSE	0


/* returns flag to state two trees compatible types*/
int compatible(t1,t2)
tnode *t1, *t2;
{
	int	result = TRUE;

	return result;
}

/* returns flag to if a value of t2 can be assigned to type t1 */
int acompatible(t1,t2)
tnode *t1, *t2;
{
	int	result = TRUE;

	return result;
}


/* build tnode */
tnode *new_tnode(t,down,right)
int t;
tnode *down,*right;
{
	register tnode *p;

	if ( (p = (tnode *) calloc(1,sizeof(tnode))) == 0 )
	{
		fprintf(stderr,"Out of memory\n");
		exit(1);
	}
	p->n_type = t;
	p->down = down;
	p->right = right;
	return p;
}

/* things to build the simple type trees */
