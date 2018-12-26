/* define some hash function */
#ifndef HASH
#define HASH(p, h) while ( *p != '\0' ) h = (h<<1) + *p++;
#endif

typedef struct symrec {
	char * symbol;
	struct symrec *next, *prev, **head, *scope;
	unsigned hash;
	int token; 	/* either FUNC or VAR */
	int level; 	/* either LOCAL, GLOBAL, PARAMETER */
	int offset; /* offset from sp on the stack */
				/* locals are - offset, param is 0 */
	} Sym, *SymPtr;

void zzs_init();
void zzs_done();
void zzs_add();
Sym *zzs_get();
void zzs_del();
void zzs_keydel();
Sym **zzs_scope();
Sym *zzs_rmscope();
void zzs_stat();
Sym *zzs_new();
Sym *zzs_newadd();
char *zzs_strdup();

