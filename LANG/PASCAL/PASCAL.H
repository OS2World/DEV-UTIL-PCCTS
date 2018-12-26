/* pascal.h header file for the antlr pascal grammar
 *
 * 6/9/91
 */

#define TRUE	1
#define FALSE	0

Sym *make_special_entry();

typedef Sym *Attrib;
#define zzcr_attr(attr,tok,text)	{*(attr) = CurSym;}

