/* S y m b o l  l e v e l s */
#define GLOBAL		1
#define PARAMETER	2
#define LOCAL		3

/* T y p e s */
#define tNone		0x0000
#define tInt		0x0001
#define tFloat		0x0002
#define tChar		0x0004
#define tShort		0x0008
#define tLong		0x0010
#define tDouble		0x0020
#define tVoid		0x0040
#define tUnsigned	0x0080
#define tEllipsis	0x0100
#define tUnion		0x0200
#define tStruct		0x0400
#define tEnum		0x0800
#define tTypeName	0x1000
#define tSigned		0x2000

/* T y p e  q u a l i f i e r s */
#define cvNone		0x0000
#define cvConst		0x0001
#define cvVolatile	0x0002

/* S t o r a g e  c l a s s e s */
#define scNone		0x0000
#define scAuto		0x0001
#define scRegister	0x0002
#define scStatic	0x0004
#define scExtern	0x0008
#define scTypedef	0x0010


/* A S T  n o d e s */

/* type-tree nodes */
#define BaseTypeQ	1
#define PointerQ	2
#define ArrayQ		3
#define FunctionQ	4
#define FieldQ		5
#define SymQ		6

/* expr-tree nodes */
#define ENode		10


#define AST_FIELDS	int nodeType;		\
					union {				\
						qPointer p;		\
						qArray a;		\
						qFunction f;	\
						qField fi;		\
						qSym s;			\
						ExprNode e;		\
						qBaseType t;	\
					} data;

typedef struct _eNode {
			int token;
		} ExprNode;

typedef struct _eOperator {
			int token;
		} eOperator;

typedef struct _qSym {
			char *name;
			void *init;
		} qSym;

typedef struct _qField {
			char *name;
		} qField;

typedef struct _qPointer {
			int cv;
		} qPointer;

typedef struct _qArray {
			struct _ast *dim;
		} qArray;

/* don't need this right now */
typedef struct _qFunction {
			void *code;
		} qFunction;

typedef struct _qBaseType {
			char *name;	/* type/struct/union name */
			int cv;
			int sc;
			int type;
		} qBaseType;

/* how to create a default node */
#define zzcr_ast(ast, attr, tok, text)				\
			(ast)->data.e.token = tok;				\
			(ast)->nodeType = ENode;
