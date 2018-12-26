#ifdef __STDC__
char *mystrdup(char *);
struct _ast *zzmk_ast(struct _ast *, int, ...);
struct _ast *bottom(struct _ast *);
struct _ast *defineArgs(struct _ast *, Sym **);
void error(char *);
void error1(char *, char *);
void warn(char *);
void warn1(char *, char *);
Sym *addsym(int, char *,int , struct _ast *, struct _ast *);
#else
char *mystrdup();
struct _ast *zzmk_ast();
struct _ast *bottom();
struct _ast *defineArgs();
void error();
void error1();
void warn();
void warn1();
Sym *addsym();
#endif

extern Sym *Globals;
extern Sym *Params;
