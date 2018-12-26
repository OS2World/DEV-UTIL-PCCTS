/*      Code to manage type trees for each type
 *  These trees then can be used to determine whether varibles have the
 *  same type.
 *
 *  Will Cohen
 *  12/18/90
 */

#define tnode   struct _tnode_
tnode {
	tnode	*down,*right;	/* everything in child-sibling tree */
	int	n_type;		/* indicates what kind of node this is */
};

/* types of tnodes */


/* functions */
extern int compatible(/*t1,t2*/);	/* returns 0 for incompatible, 1 for */
					/*  compatible */
extern int acompatible(/*t1,t2*/);	/* returns 1 if can assigment okay */
					/* t1<-t2 */
extern tnode   *new_tnode();		/* makes and fills in a tnode */
