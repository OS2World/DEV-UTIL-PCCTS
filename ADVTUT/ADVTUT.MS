.de iH
\\$1 \\$2 \\$3 \\$4 \\$5 \\$6 \\$7 \\$8
\\.XS
.if \\n(NS-4 	
.if \\n(NS-3 	
.if \\n(NS-2 	
.if \\n(NS-1 	
\\*(SN \\$1 \\$2 \\$3 \\$4 \\$5 \\$6 \\$7 \\$8
\\.XE
..
.de 1s
.nr PS 11
.nr VS 12
.br
.LP
..
.de 2s
.nr PS 11
.nr VS 16
.br
.LP
..
.de cB
.nr PS 9
.nr VS 11
.br
.LP
.KS
.LD
.ft CW
..
.de cE
.DE
.KE
.2s
.ft R
..
.EH 'PCCTS Advanced Tutorial 1.0x'
.OH 'PCCTS Advanced Tutorial 1.0x'
.EF '''Page %'
.OF '''Page %'
.TL
\s+4PCCTS Version 1.0x Advanced Tutorial\s-4
.AU
Terence Parr, Hank Dietz, Will Cohen
.AI
School of Electrical Engineering
Purdue University
West Lafayette, IN  47907
\fISpring 1992\fP
\f(CWparrt@ecn.purdue.edu\fP
\f(CWhankd@ecn.purdue.edu\fP
\f(CWcohenw@ecn.purdue.edu\fP
.2s
.LP
.br
.PP
Constructing a translator can be viewed as an iterative refinement
process moving from language recognition to intermediate-form
transformation.  This document presents one possible sequence of
refinements.  We shall use as many features of PCCTS as is reasonable
without regards to optimality.
.PP
We will develop a compiler for a simple string manipulation language
called \fIsc\fP.  The compiler will generate code for a simple stack
machine.
.PP
This document assumes familiarity with the concept of a parser generator and
other language recognition tools \(em in particular, a passing familiarity
with YACC is useful.
.PP
The development will proceed as follows:
.IP \fI(i)\fP
Define a grammar to recognize functions, statements, variable
definitions and expressions in \fIsc\fP.
.IP \fI(ii)\fP
Add symbol table management to the grammar developed in \fI(i)\fP
.IP \fI(iii)\fP
Add actions to translate \fIsc\fP into stack code for a simple stack
machine.
.IP \fI(iv)\fP
Construct trees as an intermediate-form.
.IP \fI(v)\fP
Build a code-generator to translate the trees into executable C code.
.bp
.NH
.iH \fIsc\fP Language definition
.PP
\fIsc\fP is a simple, C-like language with only one data object
type\(em string.  It has global variables, functions, arguments and
local variables.  There are no arrays or structures.
.NH 2
.iH \fIsc\fP Expressions
.PP
Expression atoms are limited to variables, string constants
(\f(CW"\fIcharacter(s)\f(CW"\fR) and function calls
(\f(CWfunction(\fIexpr\f(CW)\fR).  The string constants
\f(CW"false"\fP or \f(CW"0"\fP represent false and \f(CW"true"\fR or
\f(CW"1"\fP represent true.  A limited set of operators are available
(from highest to lowest precedence)
.IP \f(CW-\fP 8n
Unary operator negate. Numeric operator.
.IP "\f(CW*, /\fP"
Binary operators multiply and divide.  Groups left-to-right.  Numeric
operator.
.IP "\f(CW+, -\fP"
Binary operators add and subtract.  Groups left-to-right.  Numeric
operator except for \f(CW+\fP which is \*Qconcatenate\*U if one of
operands is non-numeric.
.IP "\f(CW==, !=\fP"
Binary operators equal, not equal.  Groups left-to-right.  Numeric or
non-numeric.
.IP \f(CW=\fP
Binary assignment operator.  Groups right-to-left.  For example,
\f(CWa\ =\ b\ =\ c\fP means to assign \f(CWc\fP to \f(CWb\fP and then to
\f(CWa\fP.
.LP
.NH 2
.iH \fIsc\fP Functions and statements
.PP
Functions may have multiple local variables, but at most one parameter.
All functions implicitly return a string to the
calling function, although the value need not be used.  If a
\f(CWreturn\fP-statement is not executed within a function, the return
value for that function is undefined.  Functions are defined exactly
as in C:
.cB
\fIfunction\fP(\fIarg\fP)
{
	\fIstatement(s)\fP
}
.cE
.PP
A function called \f(CWmain()\fP must exist so that our interpreter
and compiled code knows where to begin execution.  Also, \f(CWmain()\fP
always has a implicitly passed parameter which contains any
command-line argument.
.PP
\fIsc\fP has six statements.
.IP \f(CWif\fP
Conditionals have the form:
.RS
.cB
if ( \fIexpr\fP ) \fIstatement\fP
.cE
.RE
.IP \f(CWwhile\fP
Loops have the form:
.RS
.cB
while ( \fIexpr\fP ) \fIstatement\fP
.cE
.RE
.IP "\f(CW{\fP \fIstatement(s)\fP \f(CW}\fP"
Block statements treat more than one statement as a single statement as
in C.  However, one cannot define variables local to a block statement.
.IP "\fIexpr\fP\f(CW;\fP"
An \fIexpr\fP can include any valid \fIsc\fP expression, but only expressions
involving assignments and function calls are useful.
.IP "\f(CWreturn\fP \fIexpr\fP \f(CW;\fP"
This statement behaves exactly like the C return statement except that
only strings can be returned.
.IP "\f(CWprint\fP \fIexpr\fP\f(CW;\fP"
Print the string described by \fIexpr\fP to \f(CWstdout\fP.
.NH 2
.iH Example
.PP
The following code is a simple \fIsc\fP program that computes \fIn\fP
factorial.
.cB
main(n)
{
	print fact(n);
	print "\en";
}

fact(n)
{
	if ( n == "0" ) return "1";
	return n * fact(n - "1");
}
.cE
.NH
.iH Language recognition
.PP
We begin our project by constructing a parser\(ema program that will
recognize phrases in \fIsc\fP.  The first two subsections describe the
\fIsc\fP lexicon while the later subsections present the \fIsc\fP grammar
with and without symbol table management.
.NH 2
.iH Lexical analysis
.PP
Our language has only strings of upper- and lower-case letters, called
\f(CWWORD\fP's, operators, string constants and a few grammatical
grouping symbols; all of which except \f(CWWORD\fP will be defined
implicitly by mentioning them in the grammar.  \f(CWWORD\fP will be
placed last in the grammar\(emi.e. after all keywords have been
defined.  Since keywords are really just strings of characters as
well, they must be treated specially.  When two (or more) regular
expressions can be matched for the current input text, DLG scanners
resolve the ambiguity by matching the input to the expression
mentioned first in the description.  Hence, we place
.cB
#token WORD "[a-zA-Z]+"
.cE
.LP
at the bottom of the file.
.PP
Tabs, blanks and carriage-returns are all considered white space and
are to be ignored (although we wish to track line numbers).  The
following ANTLR code will instruct the parser to skip over white space.
.cB
#token "[\et\e ]+"   << zzskip(); >>         /* Ignore White */
#token "\en"        << zzline++; zzskip(); >>
.cE
.PP
Strings are strings of characters enclosed in double-quotes.  For simplicity
we will allow any character not in the ASCII range 0..0x1F (hex) plus
any "escaped" version of the same character set.
.cB
#token STRING       "\e"(~[\e0-\e0x1f\e"\e\e]|(\e\e~[\e0-\e0x1f]))*\e"" <<;>>
.cE
.NH 2
.iH Attributes
.PP
The DLG scanner matches keywords, \f(CWWORD\fP's, etc... on the input
stream.  The way ANTLR parsers access that text
is though the attribute mechanism.  Attributes are run-time objects
associated will all grammar elements (items to the right of the \f(CW:\fP
in a rule definition).  Although attributes are associated with subrules
and rule references, only those attributes linked to grammar tokens are
of interest to us.  Attributes are denoted \f(CW$\fP\fIi\fP where \fIi\fP
is the grammar element \fIi\fP positions from the start of the alternative.
The user must define an attribute type called \f(CWAttrib\fP.  This type
is most often some sort of string whether constant or dynamically allocated.
For simplicity, we employ a standard attribute type available with the
PCCTS system.  Attributes are structures that contain a
constant width (30 character) string.  By placing the character array
inside of a structure, the entire string can be copied like any simple
C variable.  The ANTLR pseudo-op \f(CW#header\fP is used to describe
attributes and other information that must be present in all generated
C files.  In our case, we simply need to include the standard
text attribute definition.  This pseudo-op must occur first in the
grammar file if it exists at all.
.cB
#header <<#include "charbuf.h">>
.cE
.NH 2
.iH Grammatical analysis
.PP
This subsection describes the grammatical or syntactic aspects of \fIsc\fP.
No symbol table management is used and therefore functions and variables
are considered simple \f(CWWORD\fP's.  Later versions of the grammar
can use the tokens \f(CWVAR\fP and \f(CWFUNC\fP.
.NH 3
.iH Definitions, variables
.PP
An \fIsc\fP program is a sequence of definitions\(emvariables or functions:
.cB
p       :   ( func | "var" def ";" )* ;
.cE
.LP
The \f(CW( )*\fP subrule means that there are zero or more definitions.
The \f(CW|\fP operator starts a new alternative.
.PP
The grammar for a variable definitions is broken up between the rule
\f(CWp\fP and \f(CWdef\fP so that \f(CWdef\fP can be reused for
parameter definitions (it also makes more sense when code generation
has been added).
.cB
def     :   WORD ;
.cE
.NH 3
.iH Functions
.PP
\fIsc\fP functions follow C's format except that the default
return type is a string instead of \f(CWint\fP.  
.cB
func    :   WORD "\e(" { WORD } "\e)"
            "\e{"
                ( def )*
                ( statement )*
            "\e}"
        ;
.cE
.LP
Note that the parentheses and the curly-braces must be escaped
with \f(CW\e\fP because they are special regular expression symbols.
.NH 3
.iH Statements
.PP
The statements outlined in the \fIsc\fP language definition can be
described with
.cB
statement
        :   expr ";"
        |   "\e{" ( statement )* "\e}"
        |   "if" "\e(" expr "\e)" statement {"else" statement}
        |   "while" "\e(" expr "\e)" statement
        |   "return" expr ";"
        |   "print" expr ";"
        ;
.cE
.LP
where \f(CW{ }\fP means optional.
.NH 3
.iH Expressions
.PP
The operators and expression atoms described in the language definition
can be recognized by the following grammar fragment.
.cB
expr    :   WORD "=" expr
        |   expr0
        ;

expr0   :   expr1 ( ("=="|"!=") expr1 )*
        ;

expr1   :   expr2 ( ("\e+"|"\e-") expr2 )*
        ;

expr2   :   expr3 ( ("\e*"|"/") expr3 )*
        ;

expr3   :   {"\e-"} expr4
        ;

expr4   :   STRING
        |   WORD { "\e(" { expr } "\e)" }
        |   "\e(" expr "\e)"
        ;
.cE
.LP
Rule \f(CWexpr\fP is ambiguous if we only look one token into the
future since \f(CWWORD\fP can also be an \f(CWexpr0\fP.  However, if
we were to tell ANTLR to use two tokens, it could see that the
\f(CW"="\fP assignment operator uniquely identifies which alternative
to match when \f(CWWORD\fP is the first token of lookahead.  Rule
\f(CWexpr\fP makes this grammar LL(2); but, we only use the extra
token of lookahead in \f(CWexpr\fP (leaving all others LL(1)).  Please
note the use of ANTLR's command-line option \*Q\f(CW-k 2\fP\*U in the
makefiles presented below.
.PP
ANTLR does not have a method of explicitly outlining operator precedence.
Instead precedence is implicitly defined by the rule invocation sequence
or abstractly by the parse-tree.  Rule \f(CWexpr\fP calls
\f(CWexpr0\fP which calls \f(CWexpr1\fP etc... nesting more
and more deeply.  The precedence rule-of-thumb in ANTLR (and any LL-type
parser) is: the deeper the nesting level, the higher the precedence (the
more tightly the operator binds).  Operators in the expression starting
rule have the lowest precedence whereas operators in the last rule
in the expression recursion have the highest precedence.  This becomes
obvious when a parse-tree for some input text is examined.
.PP
Once again, note that the operators for \fIsc\fP must be escaped as they are
reserved regular expression operators as well.
.bp
.NH 2
.iH Complete ANTLR description (w/o symbol table management)
.PP
The following code is the complete ANTLR description to recognize \fIsc\fP
programs.  Nothing is added to the symbol table and undefined
variables/functions are not flagged.
.cB
#header <<#include "charbuf.h">>

#token "[\et\e ]+"    << zzskip(); >>                /* Ignore White */
#token "\en"         << zzline++; zzskip(); >>
#token STRING "\e"(~[\e0-\e0x1f\e"\e\e]|(\e\e~[\e0-\e0x1f]))*\e"" <<;>>

<< main() { ANTLR(p(), stdin); } >>

p       :   ( func | "var" def ";" )*
            "@"
        ;

def     :   WORD
        ;

func    :   WORD "\e(" { def } "\e)"
            "\e{"
                ( "var" def ";" )*
                ( statement )*
            "\e}"
        ;

statement
        :   expr ";"
        |   "\e{" ( statement )* "\e}"
        |   "if" "\e(" expr "\e)" statement {"else" statement}
        |   "while" "\e(" expr "\e)" statement
        |   "return" expr ";"
        |   "print" expr ";"
        ;

expr    :   WORD "=" expr
        |   expr0
        ;

expr0   :   expr1 ( ("==" | "!=") expr1 )*
        ;

expr1   :   expr2 ( ("\e+" | "\e-") expr2 )*
        ;

expr2   :   expr3 ( ( "\e*" | "/" ) expr3 )*
        ;

expr3   :   {"\e-" } expr4
        ;

expr4   :   STRING
        |   WORD { "\e(" { expr } "\e)" }
        |   "\e(" expr "\e)"
        ;

#token WORD "[a-zA-Z]+"
.cE
.NH 2
.iH Makefile
.PP
The following makefile can be used to make the above language description
into an executable file.  We assume that the ANTLR includes and standard
attribute packages are located in a directory accessible to us as
\f(CW../h\fP.  The grammar listed above must be in file
\f(CWtut1.g\fP.
.cB
#
# Makefile for 1.00 tutorial (no symbol table stuff)
# ANTLR creates parser.dlg, err.c, tut1.c, tokens.h
# DLG creates scan.c, mode.h
#
CFLAGS= -I../h
GRM=tut1
SRC=scan.c $(GRM).c err.c
OBJ=scan.o $(GRM).o err.o

tutorial: $(OBJ) $(SRC)
    cc -o $(GRM) $(OBJ)

# build a parser and lexical description from a language description
$(GRM).c parser.dlg : $(GRM).g
    antlr -k 2 $(GRM).g

# build the scanner from a lexical description
scan.c : parser.dlg
    dlg -C2 parser.dlg scan.c
.cE
.LP
Remember that \f(CWmake\fP wants a tab, not spaces, in front of the
action statements (e.g. \f(CWcc\fP, \f(CWantlr\fP, ...).
.NH 2
.iH Testing
.PP
After successful completion of \f(CWmake\fP, the executable
\f(CWtut\fP will exist in the current directory.  \f(CWtut\fP takes
input from \f(CWstdin\fP.  Therefore, one parses a file via
.cB
tut < \fIfile\fP.sc
.cE
.LP
The prompt will return without a message if no syntax errors were
discovered.  However, if \fIfile\fP contains lexical or syntactic
errors, error messages will appear.  We have given no instructions
related to translation, so nothing happens if all is well.
.NH 2
.iH Symbol table management
.PP
The grammar presented thus far can only recognize \fIsc\fP programs.
No translation is possible because it does not deal with the semantics
of the input program only its structure.  To begin semantic
interpretation, one must add new symbols to a symbol table.  The
symbols required to \*Qunderstand\*U an \fIsc\fP program are
.IP \f(CWVAR\fP 10n
Symbol is a local (denoted with the \f(CW#define\fP constant \f(CWLOCAL\fP),
a parameter (\f(CWPARAMETER\fP) or global (\f(CWGLOBAL\fP) variable.
.IP \f(CWFUNC\fP 10n
Symbol is a function whose level is always \f(CWGLOBAL\fP.
.PP
A symbol table record requires two fields: \f(CWtoken\fP which indicates
either \f(CWVAR\fP or \f(CWFUNC\fP and \f(CWlevel\fP which is either
\f(CWLOCAL\fP, \f(CWPARAMETER\fP or \f(CWGLOBAL\fP.
.PP
The PCCTS system comes with a simple symbol table manager.  The source
is documented well and its functions will be referenced without
explanation here.  To use the functions, our grammar must include a
file called \f(CWsym.h\fP and define a symbol table structure.  We
shall put the \f(CW#include\fP in the \f(CW#header\fP directive.
.cB
#header <<#include "sym.h"
		  #include "charbuf.h">>
.cE
.LP
The file \f(CWsym.c\fP contains the actual functions and must be
linked into your executable.  Our makefile will handle this
automatically.  The \f(CWsym.c\fP can be found in the
\f(CWsupport/sym\fR subdirectory of the standard PCCTS installation;
this should be copied into the tutorial directory.
.PP
The symbol table manager requires a number of fields within the symbol
table entry.  A template has been provided that the user can copy into
their work directory and modify.  The template in \f(CWsym.h\fP will
be modified in our case to include the two fields mentioned
above\(em\f(CWtoken\fP and \f(CWlevel\fP.
.cB
typedef struct symrec {
			char *symbol;
			struct symrec *next, *prev, **head, *scope;
			int token;  /* either FUNC or VAR */
			int level;  /* either LOCAL, GLOBAL, PARAMETER */
            int offset; /* offset from sp on the stack */
                        /* locals are - offset, param is 0 */
                        /* used only in tut4; reserved */
		} Sym, *SymPtr;
.cE
.LP
We add the following definitions to the front of our grammar.
.cB
<<
#define HashTableSize       999
#define StringTableSize     5000
#define GLOBAL              0
#define PARAMETER           1
#define LOCAL               2

static Sym *globals = NULL;        /* global scope for symbols */
>>
.cE
where \f(CWglobals\fP is used to track all global symbols
(functions and variables).  Also, to print out symbol scopes, we
define a function called \f(CWpScope(Sym\ *p)\fP that dumps a scope to
\f(CWstdout\fP.  It's implementation is unimportant and given with
the full grammar description listed below.  To initialize the symbol
table, we add a function call to the symbol table manager library
yielding a new \f(CWmain()\fP.
.cB
main()
{
    zzs_init(HashTableSize, StringTableSize);
    ANTLR(p(), stdin);
}
.cE
.PP
When a variable, parameter or function is defined, we want to add that
symbol to the symbol table.  We shall treat parameters like variables
grammatically and use field \f(CWlevel\fP to differentiate between
them.  When a \f(CWWORD\fP is found in rule \f(CWdef\fP, we will add
it to the symbol table using the scope and level passed into
\f(CWdef\fP.  The situation is complicated slightly by the fact that a
local variable may have the same name as a global variable.  Scopes
are linked lists that weave through the symbol table grouping all
entries within the same scope.  Our grammar for rule \f(CWdef\fP
becomes:
.cB
def[Sym **scope, int level] : <<Sym *var;>> (WORD | VAR) ;
.cE
.LP
where the init-action defines a local variable called \f(CWvar\fP.
.PP
To handle the definition of previously unknown symbols, we add an
action after the \f(CWWORD\fP reference.
.cB
( WORD
  <<zzs_scope($scope);         /* set current scope to scope passed in */
    var = zzs_newadd($1.text); /* create entry, add text of WORD to table */
    var->level = $level;       /* set the level to level passed in */
    var->token = VAR;          /* symbol is a variable */
  >>
| VAR
)
.cE
.LP
To deal with a symbol defined in another scope we add the following
action to the \f(CWVAR\fP reference.
.cB
( WORD
  <<...>>
| VAR
  <<var = zzs_get($1.text);    /* get previous definition */
    if ( level != var->level ) /* make sure we have a diff scope */
    {
      zzs_scope($scope);       /* same here as above for unknown */
      var = zzs_newadd($1.text);
      var->level = $level;
      var->token = VAR;
    }
    else printf("redefined variable ignored: %s\en", $1.text);
  >>
)
.cE
.LP
Note that this implies that the lexical analyzer will modify the token
number according to its definition in the symbol table (if any).  This
is generally not a good idea, but can be quite helpful when trying to
remove nasty ambiguities in your grammar.  Typically more than one
token of lookahead makes it unnecessary to use \*Qderived\*U tokens.
We do so here to illustrate the interaction of lexical analyzer and
parser.
.PP
Rule \f(CWp\fP must be modified to pass a scope and level to rule
\f(CWdef\fP.  In addition, we will remove the global scope at the end
of parsing and print out the symbols.
.cB
p       :   <<Sym *p;>>
            ( func | "var" def[&globals, GLOBAL] ";" )*
            <<p = zzs_rmscope(&globals);
              printf("Globals:\en");
              if ( p != NULL ) pScope(p);
            >>
            "@"
        ;
.cE
.PP
Rule \f(CWfunc\fP now must create a \f(CWFUNC\fP symbol table entry
and define a \f(CWVAR\fP entry for its parameter if one exists.  Rule
\f(CWfunc\fP checks for duplicate \f(CWFUNC\fP entries by only
matching unknown \f(CWWORD\fP's.  If a function had been previously
defined, its token would be \f(CWFUNC\fP.
.cB
func    :   <<Sym *locals=NULL, *var, *p;>>
            WORD
			<<zzs_scope(&globals);
			  var = zzs_newadd($1.text);
		      var->level = GLOBAL;
			  var->token = FUNC;
			>>
            "\e(" { def[&locals, PARAMETER] } "\e)"
            "\e{"
                 ( "var" def[&locals, LOCAL] ";" )*
                 ( statement )*
            "\e}"
            <<p = zzs_rmscope(&locals);
              printf("Locals for %s:\en", $1.text);
              if ( p != NULL ) pScope(p);
            >>
        ;
.cE
.LP
At the end of the function, we remove the local scope of variables
(and parameter if it exists) and print the symbols out to
\f(CWstdout\fP.
.PP
When a \f(CWWORD\fP is encountered on the input stream, we need to look
it up in the symbol table to find out whether it is a variable
(parameter) or a function.  The token number needs to be changed
accordingly before the parser sees it so that it will not try to match
a \f(CWWORD\fP.  Any \f(CWWORD\fP references in an expression that are
not defined in the symbol table are undefined variables.  We
accomplish this token \*Qderivation\*U strategy by attaching an action
to the regular expression for \f(CWWORD\fP.
.cB
#token WORD "[a-zA-Z]+"
	<<{
		Sym *p = zzs_get(LATEXT(1));
		if ( p != NULL ) NLA = p->token;
	}>>
.cE
.LP
The macro \f(CWLATEXT(1)\fP is always set to the text matched on the
input stream for the current token.  \f(CWNLA\fP is the next token of
look-ahead.  We need to change this from \f(CWWORD\fP to whatever is
found in the symbol table.
.PP
Rules for statements and expressions do not change when adding symbol
table management because they simply apply a structure to grammar
symbols and do not introduce new ones.
.NH 2
.iH Complete ANTLR description (with symbol table management)
.PP
The following code is the complete ANTLR description to recognize \fIsc\fP
programs.  Functions, variables and parameters are added to the symbol
table and are printed to \f(CWstdout\fP after function definitions and at the
end of the \fIsc\fP program.
.cB
#header <<
    #include "sym.h"
    #include "charbuf.h"
>>

#token "[\et\e ]+"    << zzskip(); >>                /* Ignore White */
#token "\en"         << zzline++; zzskip(); >>
#token STRING "\e"(~[\e0-\e0x1f\e"\e\e]|(\e\e~[\e0-\e0x1f]))*\e"" <<;>>

<<
#define HashTableSize       999
#define StringTableSize     5000
#define GLOBAL              0
#define PARAMETER           1
#define LOCAL               2

static Sym *globals = NULL; /* global scope for symbols */
.cE
.cB
main()
{
    zzs_init(HashTableSize, StringTableSize);
    ANTLR(p(), stdin);
}

pScope(p)
Sym *p;
{
    for (; p!=NULL; p=p->scope)
    {
        printf("\etlevel %d | %-12s | %-15s\en",
            p->level,
            zztokens[p->token],
            p->symbol);
    }
}
>>
.cE
.cB
p       :   <<Sym *p;>>
            ( func | "var" def[&globals, GLOBAL] ";" )*
            <<p = zzs_rmscope(&globals);
              printf("Globals:\en");
              pScope(p);
            >>
            "@"
        ;

def[Sym **scope, int level]
        :   <<Sym *var;>>
            (   WORD
                <<zzs_scope($scope);
                  var = zzs_newadd($1.text);
                  var->level = $level;
                  var->token = VAR;
                >>
            |   VAR
                <<var = zzs_get($1.text);
                  if ( $level != var->level )
                  {
                    zzs_scope($scope);
                    var = zzs_newadd($1.text);
                    var->level = $level;
                    var->token = VAR;
                  }
                  else printf("redefined variable ignored: %s\en", $1.text);
                >>
            )
        ;
.cE
.cB
func    :   <<Sym *locals=NULL, *var, *p;>>
            WORD
            <<zzs_scope(&globals);
              var = zzs_newadd($1.text);
              var->level = GLOBAL;
              var->token = FUNC;
            >>
            "\e(" { def[&locals, PARAMETER] } "\e)"
            "\e{"
                ( "var" def[&locals, LOCAL] ";" )*
                ( statement )*
            "\e}"
            <<p = zzs_rmscope(&locals);
              printf("Locals for %s:\en", $1.text);
              pScope(p);
            >>
        ;

statement
        :   expr ";"
        |   "\e{" ( statement )* "\e}"
        |   "if" "\e(" expr "\e)" statement
            {"else" statement}
        |   "while" "\e(" expr "\e)" statement
        |   "return" expr ";"
        |   "print" expr ";"
        ;
.cE
.cB
expr    :   VAR "=" expr
        |   expr0
        ;

expr0   :   expr1 ( (   "=="
                    |   "!="
                    )
                    expr1
                  )*
        ;

expr1   :   expr2 ( (   "\e+"
                    |   "\e-"
                    )
                    expr2
                  )*
        ;

expr2   :   expr3 ( (   "\e*"
                    |   "/"
                    )
                    expr3
                  )*
        ;

expr3   :   {"\e-" } expr4
        ;
.cE
.cB
expr4   :   STRING
        |   VAR
        |   (   FUNC
            |   WORD
            )
            "\e(" { expr } "\e)"
        |   "\e(" expr "\e)"
    ;

#token WORD "[a-zA-Z]+"
    <<{
        Sym *p = zzs_get(LATEXT(1));
        if ( p != NULL ) NLA = p->token;
    }>>
.cE
.NH 2
.iH File \f(CWsym.h\fP
.PP
The following is a modification of the \f(CWsym.h\fP template provided
with PCCTS.  The fields of the symbol table entry structure have
augmented for our purposes as outlined above.
.cB
/* define some hash function */
#ifndef HASH
#define HASH(p, h) while ( *p != '\e0' ) h = (h<<1) + *p++;
#endif

typedef struct symrec {
            char * symbol;
            struct symrec *next, *prev, **head, *scope;
            unsigned hash;
            int token;  /* either FUNC or VAR */
            int level;  /* either LOCAL, GLOBAL, PARAMETER */
            int offset; /* offset from sp on the stack */
                        /* locals are - offset, param is 0 */
                        /* used only tut4; reserved */
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
.cE
.NH 2
.iH Makefile (for use with symbol table management)
.PP
The following makefile can be used to make the above language description
into an executable file.  We assume that the ANTLR includes and standard
attribute packages are located in a directory accessible to us as
\f(CW../h\fP.  Also, \f(CWsym.c\fP, \f(CWsym.h\fP are located in the
current working directory.  The grammar listed above must be in file
\f(CWtut2.g\fP.
.cB
#
# Makefile for 1.00 tutorial
# ANTLR creates parser.dlg, err.c, tut1.c
# DLG creates scan.c
#
CFLAGS= -I../h
GRM=tut2
SRC=scan.c $(GRM).c err.c sym.c
OBJ=scan.o $(GRM).o err.o sym.o

tutorial: $(OBJ) $(SRC)
    cc -o $(GRM) $(OBJ)

$(GRM).c parser.dlg : $(GRM).g
    antlr -k 2 $(GRM).g

scan.c : parser.dlg
    dlg -C2 parser.dlg scan.c
.cE
.NH 2
.iH Sample input/output
.PP
The current state of the program accepts input like the following
sample.
.cB
var i;
var j;

f(k)
{
    var local;
    var j;

    if ( "true" ) local = "zippo";
}

g()
{
    var note;

    note = "1";
    while ( note )
    {
        i = "456";
    }
}
.cE
.LP
The output of our executable, \f(CWtut\fP, would be
.cB
Locals for f:
        level 2 | VAR          | j              
        level 2 | VAR          | local          
        level 1 | VAR          | k              
Locals for g:
        level 2 | VAR          | note           
Globals:
        level 0 | FUNC         | g              
        level 0 | FUNC         | f              
        level 0 | VAR          | j              
        level 0 | VAR          | i              
.cE
.LP
Note that the parameter \f(CWk\fP is level 1 for \f(CWPARAMETER\fP
and the local variable \f(CWlocal\fP is level 2 for \f(CWLOCAL\fP.
.NH
.iH Translate \fIsc\fP to stack code
.PP
Generating code for a stack machine is simple and can be done by
simply adding \f(CWprintf()\fP actions to the grammar in the
appropriate places.
.PP
We begin with a discussion of the stack machine and how to generate
code for it.  Next we augment our grammar with actions to dump stack
code to \f(CWstdout\fP.
.NH 2
.iH A simple stack machine for \fIsc\fP
.PP
Our stack machine consists of a single CPU, a finite stack of strings,
a finite memory, a stack pointer (\f(CWsp\fP) and a frame pointer
(\f(CWfp\fP).  All data items used by stack programs are strings
(currently set to a maximum length of 100).  Our string stack grows
downwards towards 0 from the maximum stack height.
.PP
To make implementation simple, our stack code will actually be a
sequence of macro invocations in a C program.  This way C will take
care of control-flow and allocating space etc...  The minimum stack
code program defines a \f(CW_main\fP and includes \f(CWsc.h\fP which
contains all of the stack code macros:
.cB
#include "sc.h"
_main()
{
    BEGIN;
    END;
}
.cE
.LP
The \f(CWBEGIN\fP and \f(CWEND\fP macros are explained below.
.NH 3
.iH Functions
.PP
Every \fIsc\fP program requires a \f(CWmain\fP which will we translate
to \f(CW_main\fP (a C function \f(CWmain\fP will call \f(CW_main\fP).
Other functions are translated verbatim.  The parameter to your main
program will be the first command line argument when you execute your
\fIsc\fP program (after translation to C).  If no command line
argument is specified, a \f(CW""\fP is pushed.
.PP
Parameters are pushed on the string stack before a function is called,
so no argument is needed to the resulting C function.  Return values
are implicitly strings but are also returned on the string stack\ \(em
avoiding the need to define a return type of the C function.  An
\*Qinstruction\*U (macro) called \f(CWBEGIN\fP is executed before any
other in a function.  This saves the current frame pointer and then
makes it point to the argument passed into the function.  \f(CWEND\fP
is used to restore the frame pointer to its previous value and make
the stack pointer point to the return value.  After a function call,
the top of stack is always the return value.
.PP
Arguments and local variables are at offsets to the frame pointer.
The optional argument is at offset 0.  The first local variable is at
offset 1, the second at offset 2 and so on.  Graphically,
.cB
       |    .      |
       |    .      |
       |   arg     |   fp + 0
       | 1st local |   fp - 1
       | 2nd local |   fp - 2
       |   ...     |
       |    .      |
       |    .      |
.cE
.LP
A dummy argument is pushed by the calling function if no argument is
specified.
.PP
To translate a function,
.cB
\fIf\fP(\fIarg\fP)
{
}
.cE
.LP
we simply dump the following
.cB
\fIf\fP()
{
    BEGIN;
    END;
}
.cE
.LP
Note that the argument disappears because we pass arguments on the
string stack not the C hardware stack.
.NH 3
.iH Variables
.PP
Global variables of the form
.cB
var \fIname\fP;
.cE
.LP
are translated to
.cB
SCVAR \fIname\fP;
.cE
.LP
where SCVAR is a C type defined in \f(CWsc.h\fP that makes space for a
\fIsc\fP variable.
.PP
Local variables are allocated on the string stack and are created at
run time via the instruction \f(CWLOCAL\fP.  Each execution of
\f(CWLOCAL\fP allocates space for one more local variable on the
stack.  \f(CWLOCAL\fP's must be executed after the \f(CWBEGIN\fP but
before any other stack code instruction.  The \f(CWEND\fP macro resets
the stack pointer so that these locals disappear after each function
invocation.  For example,
.cB
main()
{
	var i;
	var j;
}
.cE
.LP
is translated to:
.cB
#include "sc.h"
_main()
{
    BEGIN;
    LOCAL;
    LOCAL;
    END;
}
.cE
.NH 3
.iH Expressions
.PP
Operator precedence is defined implicitly in top-down (LL) grammars.
The deeper the level of recursion, the higher the precedence.  To
generate code for operators, one prints out the correct macro for that
operator after the two operators have been seen (because we are
generating code for a stack machine).  If the operator is a unary
operator like negate, we wait until the operand is seen and then print
the operator.  For instance, \f(CWexpr1\fP,
.cB
expr1   :   expr2 ( ("\e+"|"\e-") expr2)*
        ;
.cE
.LP
would be translated as:
.cB
expr1   :   <<char *op;>>
            expr2 ( (   "\e+" <<op="ADD";>>
                    |   "\e-" <<op="SUB";>>
                    )
                    expr2
                    <<printf("\et%s;\en", op);>>
                  )*
        ;

.cE
.LP
where \f(CWADD\fP and \f(CWSUB\fP are \fIsc\fP stack machine macros
defined below.
.PP
The assignment operator groups right to left and must generate code
that duplicates itself after each assignment so that the value of the
expression is on the stack for any chained assignement.  For example,
.cB
main()
{
    var a;
    var b;

    a = b = "test";
}
.cE
.LP
would be translated to:
.cB
#include "sc.h"
_main()             /* main() */
{
    BEGIN;
    LOCAL;          /* var a; */
    LOCAL;          /* var b; */
    SPUSH("test");  /* a = b = "test"; */
    DUP;
    LSTORE(2);      /* store into b */
    DUP;
    LSTORE(1);      /* store into a */
    POP;
    END;
}
.cE
.PP
Since an expression is a statement, it is possible that a value could
be left on the stack.  For example,
.cB
main()
{
	"expression";
}
.cE
.LP
We must pop this extraneous value off the stack:
.cB
#include "sc.h"
_main()
{
    BEGIN;
    SPUSH("expression");
    POP;
    END;
}
.cE
.NH 3
.iH Instructions
.PP
All instructions take operands from the stack and return results on the
stack.  Some have no side effects on the stack but alter the C program
counter.
.IP \f(CWPUSH(\fIv\f(CW)\fR 12n
Push the value of variable \fIv\fP onto the stack.
.IP \f(CWSPUSH(\fIs\f(CW)\fR 12n
Push the value of the string constant \fIs\fP onto the stack.
.IP \f(CWLPUSH(\fIn\f(CW)\fR 12n
Push the value of the local variable or function argument at offset
\fIn\fP onto the stack.
.IP \f(CWSTORE(\fIv\f(CW)\fR 12n
Pop the top of stack and store it into variable \fIv\fP.
.IP \f(CWLSTORE(\fIn\f(CW)\fR 12n
Pop the top of stack and store it into local variable or function
argument at offset \fIn\fP.
.IP \f(CWPOP\fR 12n
Pop the top of stack; stack is one string smaller.  No side effects
with data memory.
.IP \f(CWLOCAL\fR 12n
Create space on the stack for a local variable.  Must appear after
\f(CWBEGIN\fP but before any other instruction in a function.
.IP \f(CWBRF(\fIa\f(CW)\fR 12n
Branch, if top of stack is \f(CW"false"\fP or \f(CW"0"\fP, to
\*Qaddress\*U \fIa\fP (C label); top of stack is popped off.
.IP \f(CWBRT(\fIa\f(CW)\fR 12n
Branch, if top of stack is \f(CW"true"\fP or \f(CW"1"\fP, to
\*Qaddress\*U \fIa\fP (C label); top of stack is popped off.
.IP \f(CWBR(\fIa\f(CW)\fR 12n
Branch to \*Qaddress\*U \fIa\fP (C label).  Stack is not touched.
.IP \f(CWCALL(\fIf\f(CW)\fR 12n
Call the function \fIf\fP.  Returns with result on stack top.
.IP \f(CWPRINT\fR 12n
Pop the top of stack and print the string to \f(CWstdout\fP.
.IP \f(CWRETURN\fR 12n
Set the return value to the top of stack.  Return from the function.
.IP \f(CWEQ\fR 12n
Perform \f(CWstack[sp] = (stack[sp+1] == stack[sp])\fP.
.IP \f(CWNEQ\fR 12n
Perform \f(CWstack[sp] = (stack[sp+1] != stack[sp])\fP.
.IP \f(CWADD\fR 12n
Perform \f(CWstack[sp] = (stack[sp+1] + stack[sp])\fP.
.IP \f(CWSUB\fR 12n
Perform \f(CWstack[sp] = (stack[sp+1] - stack[sp])\fP.
.IP \f(CWMUL\fR 12n
Perform \f(CWstack[sp] = (stack[sp+1] * stack[sp])\fP.
.IP \f(CWDIV\fR 12n
Perform \f(CWstack[sp] = (stack[sp+1] / stack[sp])\fP.
.IP \f(CWNEG\fR 12n
Perform \f(CWstack[sp] = -stack[sp]\fP.
.IP \f(CWDUP\fR 12n
Perform \f(CWPUSH(stack[sp])\fP.
.IP \f(CWBEGIN\fR 12n
Function preamble.
.IP \f(CWEND\fR 12n
Function cleanup.
.PP
Boolean operations yield string constants \f(CW"false"\fP for false
and \f(CWtrue\fR for true.  All other operations yield string
constants representing numerical values (\f(CW"3"+"4"\fP is
\f(CW"7"\fP).
.NH 2
.iH Examples
.PP
The sample factorial program from above,
.cB
main(n)
{
	print fact(n);
	print "\en";
}

fact(n)
{
	if ( n == "0" ) return "1";
	return n * fact(n - "1");
}
.cE
.LP
would be translated to:
.cB
#include "sc.h"
_main()             /* main(n) */
{                   /* { */
    BEGIN;
    LPUSH(0);       /* print fact(n); */
    CALL(fact);
    PRINT;
    SPUSH("\en");    /* print "\en"; */
    PRINT;
    END;            /* } */
}
.cE
.cB
fact()              /* fact(n) */
{
    BEGIN;
    LPUSH(0);       /* if ( n == "0" ) */
    SPUSH("0");
    EQ;
    BRF(iflabel0);
    SPUSH("1");     /* return "1"; */
    RETURN;
iflabel0: ;
    LPUSH(0);       /* return n * fact(n - "1"); */
    LPUSH(0);
    SPUSH("1");
    SUB;
    CALL(fact);
    MUL;
    RETURN;
    END;            /* } */
}
.cE
.LP
.NH 2
.iH Augmenting grammar to dump stack code
.PP
In order to generate code, we must track the offset of local
variables.  To do so, we add a field, \f(CWoffset\fP, to our symbol
table record:
.cB
typedef struct symrec {
    char * symbol;
    struct symrec *next, *prev, **head, *scope;
    unsigned hash;
    int token;  /* either FUNC or VAR */
    int level;  /* either LOCAL, GLOBAL, PARAMETER */
    int offset; /* offset from sp on the stack */
                /* locals are negative offsets, param is 0 */
    } Sym, *SymPtr;
.cE
.PP
We begin modifying our grammar by making a global variable that tracks
the offset of local variables and defining a variable to track label
numbers:
.cB
static int current_local_var_offset, LabelNum=0;
.cE
.PP
Because the translation of all programs must include the \fIsc\fP
stack machine definitions, we add a \f(CWprintf\fP to rule \f(CWp\fP:
.cB
p       :   <<Sym *p; printf("#include \e"sc.h\e"\en"); >>
            ( func | "var" def[&globals, GLOBAL] ";" )*
            <<  p = zzs_rmscope(&globals); >>
            "@"
        ;
.cE
.PP
In order to generate the variable definition macros and update the
symbol table, we modify rule \f(CWdef\fP as follows:
.cB
def[Sym **scope, int level]
        :   <<Sym *var;>>
            (   WORD
                <<zzs_scope($scope);
                  var = zzs_newadd($1.text);
                  var->level = $level;
                  var->token = VAR;
                  var->offset = current_local_var_offset++;
                  switch(var->level) {
                        case GLOBAL: printf("SCVAR %s;\en", $1.text); break;
                        case  LOCAL : printf("\etLOCAL;\en"); break;
                  }
                >>
            |   VAR
                <<var = zzs_get($1.text);
                  if ( $level != var->level )
                  {
                    zzs_scope($scope);
                    var = zzs_newadd($1.text);
                    var->level = $level;
                    var->token = VAR;
                    var->offset = current_local_var_offset++;

                    switch(var-> level) {
                        case GLOBAL: printf("\etSCVAR %s;\en",$1.text);break;
                        case  LOCAL : printf("\etLOCAL;\en"); break;
                    }
                  }
                  else printf("redefined variable ignored: %s\en",$1.text);
                >>
            )
        ;
.cE
.PP
The function definition rule must now dump a function template to
\f(CWstdout\fP and generate the \f(CWBEGIN\fP and \f(CWEND\fP macros.
\f(CWfunc\fP must also update \f(CWcurrent_local_var_offset\fP.  Note
that the code to dump symbols is gone.
.cB
func :  <<Sym *locals=NULL, *var, *p; current_local_var_offset =0;>>
            WORD
            <<zzs_scope(&globals);
              var = zzs_newadd($1.text);
              var->level = GLOBAL;
              var->token = FUNC;

              if (strcmp("main",$1.text)) { printf("%s()\en",$1.text); }
              else printf("_main()\en");
            >>
            "\e(" (  def[&locals, PARAMETER]
                 |  <<current_local_var_offset = 1;>>
                 )
            "\e)"
            "\e{" << printf("{\en\etBEGIN;\en"); >>
                ( "var" def[&locals, LOCAL] ";" )*
                ( statement )*
            "\e}" << printf("\etEND;\en}\en"); >>
            <<  p = zzs_rmscope(&locals); >>
        ;
.cE
.PP
Statements are easy to handle since \f(CWexpr\fP generates most of the
code.
.cB
statement : <<int n;>>
            expr ";"            <<printf("\etPOP;\en");>>
        |   "\e{" ( statement )* "\e}"
        |   "if" "\e(" expr "\e)" << n = LabelNum++;
                                   printf("\etBRF(iflabel%d);\en",n); >>
                statement       << printf("iflabel%d: ;\en",n); >>
            {"else" statement}
        |
            "while"             << n = LabelNum++;
                                   printf("wbegin%d: ;\en", n); >>
            "\e(" expr "\e)"      << printf("\etBRF(wend%d);\en",n); >>
            statement           << printf("\etBR(wbegin%d);\en", n); >>
                                << printf("wend%d: ;\en",n); >>
                                << n++; >>
        |   "return" expr ";"   << printf("\etRETURN;\en"); >>
        |   "print" expr ";"    << printf("\etPRINT;\en"); >>
        ;
.cE
.NH 2
.iH Full translator
.PP
The following grammar accepts programs in \fIsc\fP and translates them
into stack code.
.cB
#header <<#include "sym.h"
          #include "charbuf.h"
        >>

#token "[\et\e ]+"  << zzskip(); >>                /* Ignore White */
#token "\en"       << zzline++; zzskip(); >>
#token STRING     "\e"(~[\e0-\e0x1f\e"\e\e]|(\e\e~[\e0-\e0x1f]))*\e"" <<;>>

<<
#define HashTableSize       999
#define StringTableSize     5000
#define GLOBAL              0
#define PARAMETER           1
#define LOCAL               2

static Sym *globals = NULL; /* global scope for symbols */
static int current_local_var_offset, LabelNum=0;
.cE
.cB
main()
{
    zzs_init(HashTableSize, StringTableSize);
    ANTLR(p(), stdin);
}

pScope(p)
Sym *p;
{
    for (; p!=NULL; p=p->scope)
    {
        printf("\etlevel %d | %-12s | %-15s\en",
            p->level,
            zztokens[p->token],
            p->symbol);
    }
}
>>
.cE
.cB
p       :   <<Sym *p; printf("#include \e"sc.h\e"\en"); >>
            ( func | "var" def[&globals, GLOBAL] ";" )*
            <<  p = zzs_rmscope(&globals); >>
            "@"
        ;

def[Sym **scope, int level]
        :   <<Sym *var;>>
            (   WORD
                <<zzs_scope($scope);
                  var = zzs_newadd($1.text);
                  var->level = $level;
                  var->token = VAR;
                  var->offset = current_local_var_offset++;
                  switch(var->level) {
                        case  GLOBAL: printf("SCVAR %s;\en", $1.text); break;
                        case  LOCAL : printf("\etLOCAL;\en"); break;
                  }
                >>
            |   VAR
                <<var = zzs_get($1.text);
                  if ( $level != var->level )
                  {
                    zzs_scope($scope);
                    var = zzs_newadd($1.text);
                    var->level = $level;
                    var->token = VAR;
                    var->offset = current_local_var_offset++;

                    switch(var-> level) {
                        case  GLOBAL: printf("\etSCVAR %s;\en", $1.text); break;
                        case  LOCAL : printf("\etLOCAL;\en"); break;
                    }
                  }
                  else printf("redefined variable ignored: %s\en", $1.text);
                >>
            )
        ;
.cE
.cB
func    :   <<Sym *locals=NULL, *var, *p; current_local_var_offset = 0;>>
            WORD
            <<zzs_scope(&globals);
              var = zzs_newadd($1.text);
              var->level = GLOBAL;
              var->token = FUNC;

              if (strcmp("main",$1.text)) { printf("%s()\en",$1.text); }
              else printf("_main()\en");
            >>
            "\e(" (  def[&locals, PARAMETER]
                 |  <<current_local_var_offset = 1;>>
                 )
            "\e)"
            "\e{" << printf("{\en\etBEGIN;\en"); >>
                ( "var" def[&locals, LOCAL] ";" )*
                ( statement )*
            "\e}" << printf("\etEND;\en}\en"); >>
            <<  p = zzs_rmscope(&locals); >>
        ;

statement : <<int n;>>
            expr ";"            <<printf("\etPOP;\en");>>
        |   "\e{" ( statement )* "\e}"
        |   "if" "\e(" expr "\e)" << n = LabelNum++;
                                   printf("\etBRF(iflabel%d);\en",n); >> 
                statement       << printf("iflabel%d: ;\en",n); >>
            {"else" statement}
        |   
            "while"             << n = LabelNum++;
                                   printf("wbegin%d: ;\en", n); >>
            "\e(" expr "\e)"      << printf("\etBRF(wend%d);\en",n); >>
            statement           << printf("\etBR(wbegin%d);\en", n); >>
                                << printf("wend%d: ;\en",n); >>
                                << n++; >>
        |   "return" expr ";"   << printf("\etRETURN;\en"); >>
        |   "print" expr ";"    << printf("\etPRINT;\en"); >>
        ;
.cE
.cB
expr    :   <<Sym *s;>>
            VAR "=" expr        << printf("\etDUP;\en"); >>
            <<s = zzs_get($1.text);
              if ( s->level != GLOBAL )
                printf("\etLSTORE(%d);\en", s->offset);
              else printf("\etSTORE(%s);\en", s->symbol);
            >>
        |   expr0
        ;

expr0   :   <<char *op;>>
            expr1 ( (   "==" <<op="EQ";>>
                    |   "!=" <<op="NEQ";>>
                    )
                    expr1
                    <<printf("\et%s;\en", op);>>
                  )*
        ;

expr1   :   <<char *op;>>
            expr2 ( (   "\e+" <<op="ADD";>>
                    |   "\e-" <<op="SUB";>>
                    )
                    expr2
                    <<printf("\et%s;\en", op);>>
                  )*
        ;

expr2   :   <<char *op;>>
            expr3 ( (   "\e*" <<op="MUL";>>
                    |   "/"  <<op="DIV";>>
                    )
                    expr3
                    <<printf("\et%s;\en", op);>>
                  )*
        ;
.cE
.cB
expr3   :   <<char *op=NULL;>>
            {"\e-" <<op="NEG";>>} expr4
            <<if ( op!=NULL ) printf("\et%s;\en", op);>>
        ;

expr4   :   <<Sym *s; int arg;>>
            STRING   << printf("\etSPUSH(%s);\en", $1.text); >>
        |   VAR     << s = zzs_get($1.text);
                       if ( s->level != GLOBAL )
                            printf("\etLPUSH(%d);\en", s->offset);
                       else printf("\etPUSH(%s);\en", s->symbol);
                    >>
        |   (   FUNC    <<$0=$1;>>
            |   WORD    <<$0=$1;>>
            )
            "\e(" { <<arg=0;>> expr <<arg=1;>> } "\e)"
            <<if ( !arg ) printf("\etSPUSH(\e"\e");\en");
              printf("\etCALL(%s);\en", $1.text);>>
        |   "\e(" expr "\e)"
    ;

#token WORD "[a-zA-Z]+"
    <<{
        Sym *p = zzs_get(zzlextext);
        if ( p != NULL ) NLA = p->token;
    }>>
.cE
.NH 2
.iH Makefile for Full Translator
.PP
The makefile is no different from the one used for the symbol table
management version of the tutorial except that we need to change the
\f(CWGRM\fP make variable as follows:
.cB
GRM=tut3
.cE
.LP
which implies that \f(CWtut3.g\fP is the file containing the third
revision of our \fIsc\fP translator.
.NH 2
.iH Use of translator
.PP
Once the translator has been made using the makefile, it is ready to
translate \fIsc\fP programs.  To translate and execute the factorial
example from above, we execute the following:
.cB
tut3 < fact.c > temp.c
.cE
where \f(CWfact.c\fP is the file containing the factorial code.
\f(CWtemp.c\fP will contain the translated program.  It is valid C
code because it is nothing more than a bunch of macro invocations (the
macros are defined in \f(CWsc.h\fP).  We can compile \f(CWtemp.c\fP
like any other C program:
.cB
cc temp.c
.cE
.LP
To execute the program, we type:
.cB
a.out \fIn\fP
.cE
.LP
where \fIn\fP is the number you want the factorial of.  Typing:
.cB
a.out 8
.cE
.LP
yields:
.cB
40320.000000
.cE
.NH 2
.iH Stack code macros\ \(em \f(CWsc.h\fP
.PP
The following file is included by any C program using the stack code
instructions outlined above.
.cB
/* sc.h -- string C stack machine macros
 *
 * For use with PCCTS advanced tutorial version 1.0x
 */
#include <stdio.h>
#include <ctype.h>
#include <math.h>

/*
 * The function invocation stack looks like:
 *
 *  |	.		|
 *  |	.		|
 *  |	arg		|	fp + 0		arg is "" if none specified
 *  | 1st local	|	fp - 1
 *  | 2nd local	|	fp - 2
 *  |	...		|
 *  |	.		|
 *  |	.		|
 */
.cE
.cB
#define STR_SIZE		100
#define STK_SIZE		200
/* define stack */
typedef struct { char text[STR_SIZE]; } SCVAR;
static SCVAR stack[STK_SIZE];
static int sp = STK_SIZE, fp;

/* number begins with number or '.' followed by number.  All numbers
 * are converted to floats before comparison.
 */
#define SCnumber(a)	(isdigit(a[0]) || (a[0]=='.' && isdigit(a[1])))
.cE
.cB
#define TOS			stack[sp].text
#define NTOS		stack[sp+1].text
#define TOSTRUE		((strcmp(TOS, "true")==0)||(strcmp(TOS, "1")==0)		\e
					||(SCnumber(TOS)&&atof(TOS)==1.0) )
#define TOSFALSE	((strcmp(TOS, "false")==0)||(strcmp(TOS, "0")==0)		\e
					||(SCnumber(TOS)&&atof(TOS)==0.0) )

#define PUSH(a)		{if ( sp==0 ) {fprintf(stderr, "stk ovf!\en"); exit(-1);} \e
					strcpy(stack[--sp].text, (a).text);}

#define SPUSH(a)	{if ( sp==0 ) {fprintf(stderr, "stk ovf!\en"); exit(-1);} \e
					strcpy(stack[--sp].text, a);}

#define LPUSH(a)	{if ( sp==0 ) {fprintf(stderr, "stk ovf!\en"); exit(-1);} \e
					stack[--sp] = stack[fp-a];}
.cE
.cB
#define CALL(f)		{f();}

#define POP			stack[sp++]

#define LOCAL		{if ( sp==0 ) {fprintf(stderr, "stk ovf!\en"); exit(-1);} \e
					stack[--sp].text[0] = '\e0';}
.cE
.cB
#define BRF(lab)	if ( TOSFALSE ) {POP; goto lab;} else POP;
#define BRT(lab)	if ( TOSTRUE ) {POP; goto lab;} else POP;
#define BR(lab)		goto lab

#define PRINT		printf("%s", POP.text)

#define RETURN		{strcpy(stack[fp].text, TOS); END; return;}

#define STORE(v)	{v = POP;}
#define LSTORE(off)	{stack[fp-off] = POP;}
.cE
.cB
/* operators */

#define EQ			{char *a,*b; float c,d;									\e
					a = POP.text; b = POP.text;								\e
					if ( SCnumber(a) && SCnumber(b) ) {						\e
						c=atof(a); d=atof(b);								\e
						if ( c == d ) {SPUSH("true");}						\e
					    else SPUSH("false");								\e
					}														\e
					else if ( strcmp(a, b)==0 ) {SPUSH("true");}			\e
					     else SPUSH("false");}
#define NEQ			{SCVAR a,b; float c,d;									\e
					a = POP.text; b = POP.text;								\e
					if ( SCnumber(a) && SCnumber(b) ) {						\e
						c=atof(a); d=atof(b);								\e
						if ( c != d ) {SPUSH("true");}						\e
					    else SPUSH("false");								\e
					}														\e
					else if ( strcmp(a, b)!=0 ) {SPUSH("true");}			\e
					     else SPUSH("false");}
#define ADD			{SCVAR c; float a,b;									\e
					if ( !SCnumber(NTOS) || !SCnumber(TOS) ) { 				\e
						strncat(NTOS, TOS, STR_SIZE - strlen(NTOS));		\e
						sp++;												\e
					} else {												\e
						a=atof(POP.text); b=atof(POP.text);					\e
						sprintf(c.text, "%f", a+b); PUSH(c);				\e
					}}
#define SUB			{SCVAR c; float a,b; a=atof(POP.text); b=atof(POP.text); \e
					sprintf(c.text, "%f", b-a); PUSH(c);}
#define MUL			{SCVAR c; float a,b; a=atof(POP.text); b=atof(POP.text); \e
					sprintf(c.text, "%f", a*b); PUSH(c);}
#define DIV			{SCVAR c; float a,b; a=atof(POP.text); b=atof(POP.text); \e
					sprintf(c.text, "%f", b/a); PUSH(c);}
#define NEG			{SCVAR c; float a; a=atof(POP.text); \e
					sprintf(c.text, "%f", -a); PUSH(c);}
#define DUP			{if ( sp==0 ) {fprintf(stderr, "stk ovf!\en"); exit(-1);} \e
					stack[sp-1] = stack[sp]; --sp;}
.cE
.cB
#define BEGIN		int save_fp = fp; fp = sp
#define END			sp = fp; fp = save_fp;

main(argc, argv)
int argc;
char *argv[];
{
	if ( argc == 2 ) {SPUSH(argv[1]);}
	else SPUSH("");
	CALL(_main);
	POP;
}
.cE
.NH
.iH Intermediate form construction
.PP
This section describes how trees can be used as an intermediate form
of the \fIsc\fP source program and how our \f(CWtut2.g\fP symbol table
management example can be modified to construct these trees.  Example
tree constructions are given as well as the complete source.

	Note that this section and the code generation section essentially
duplicate the translation achieved in the previous section on stack
code.  We arrive at the solution from a different angle, however.
This method is much more general and would be used for \*Qreal\*U
grammars.
.NH 2
.iH Tree Construction
.PP
To construct an intermediate form (IF) representation of an \fIsc\fP
program, we will construct trees using the abstract syntax tree (AST)
mechanism provided with PCCTS.  PCCTS supports an automatic and an
explicit tree construction mechanism; we will use both.  We will
augment the grammar that has the symbol table management actions\ \(em
\f(CWtut2.g\fP.
.PP
In order to use the AST mechanism within PCCTS, we must do the
following:
.IP \(bu
Define the AST fields, \f(CWAST_FIELDS\fP, needed by the user.
.IP \(bu
Define the default AST node constructor, \f(CWzzcr_ast()\fP, that
converts from a lexeme to an AST node.
.IP \(bu
Define an explicit AST node constructor\ \(em \f(CWzzmk_ast()\fP
(because we use the explicit tree constructor mechanism also).
.PP
Our tree nodes will contain a token number to identify the node.  This
token number can also be a value for which there is no corresponding
lexical item (e.g. a function call may have a node called
\f(CWDefineVar\fP).  If the token indicates that the node represents a
variable or function, we must have information as to its level, offset
from the frame pointer (if a local or parameter) and the string
representing the name of the item.  This information can all be held
via:
.cB
#define AST_FIELDS int token, level, offset; char str[D_TextSize];
.cE
.LP
which will be added to the \f(CW#header\fP PCCTS pseudo-op action.
Note that \f(CWD_TextSize\fP is defined in \f(CWcharbuf\fP.h.
.PP
To tell PCCTS how it should build AST nodes for use with the automatic
tree construction mechanism, we define the following macro in the
\f(CW#header\fP action:
.cB
#define zzcr_ast(ast,attr,tok,text) create_ast(ast,attr,tok,text)
.cE
.LP
which merely calls a function we define as follows:
.cB
create_ast(ast,attr,tok,text)
AST *ast;
Attrib *attr;
int tok;
char *text;
{
    Sym *s;

    ast->token = tok;
    if ( tok == VAR )
    {
        s = zzs_get(text);
        ast->level = s->level;
        ast->offset = s->offset;
    }
    if ( tok == STRING || tok == VAR || tok == FUNC ) strcpy(ast->str, text);
}
.cE
.LP
Because of the symbol table lookup etc... we make the node constructor
a function rather than have the code replicated at each invocation of
the \f(CWzzcr_ast\fP macro.
.PP
When we explicitly construct trees, the automatic node constructor is
generally disabled and we must explicitly call a function to create an
AST node:
.cB
AST *
zzmk_ast(node, token, str)
AST *node;
int token;
char *str;
{
    Sym *s;

    node->token = token;
    if ( token == VAR )
    {
        s = zzs_get(str);
        node->level = s->level;
        node->offset = s->offset;
    }
    if ( tok == STRING || tok == VAR || tok == FUNC )
		strcpy(node->str, str);
    return node;
}
.cE
This function will be invoked when we have a grammar action with a
reference of the form \f(CW#[\fItoken, string\fP]\fR.
.PP
In order to print out the trees that we have defined, let us define a
simple function to do a preorder, lisp-like walk of our trees:
.cB
lisp(tree)
AST *tree;
{
    while ( tree!= NULL )
    {
        if ( tree->down != NULL ) printf(" (");
        if ( tree->token == STRING ||
             tree->token == VAR ||
             tree->token == FUNC ) printf(" %s", tree->str);
        else printf(" %s", zztokens[tree->token]);
        lisp(tree->down);
        if ( tree->down != NULL ) printf(" )");
        tree = tree->right;
    }
}
.cE
.PP
PCCTS automatically assumes that all rules will produce trees and that
all terminals within rules will result in nodes added to the current
tree.  In the case of rules \f(CWp\fP, \f(CWexpr4\fP,
\f(CWstatement\fP and \f(CWfunc\fP, this is not true.  We will
explicitly handle the trees within these rules.  Therefore, we append
a \f(CW!\fP after the definition of these rules.  We need to decide
how each \fIsc\fP construct will be translated to a subtree and when
we will pass these trees off to the code generator.  We will collect
all subtrees within a function and then, just before we remove the
symbols for that function, we will pass this tree off to \f(CWlisp\fP
to be printed; we will pass it off to the code generator when we
define it in the next section.  After it has been printed, the
function trees will be destroyed.  For global variable definitions, we
will pass each one individually off to
\f(CWlisp\fP and then destroy the tree.
.PP
Before modifying the rules of the grammar, we must define labels for a
number of regular expressions so that the token value of that
expression can be referenced from within an action.  We also define
labels for tokens which do not exist physically in a program, but are
needed for code generation.
.cB
/* Not actual terminals, just node identifiers */
#token DefineFunc
#token SLIST
.cE
.cB
/* Define tokens for code generation */
#token DefineVar    "var"
#token Mul          "\*"
#token Div          "/"
#token Add          "\+"
#token Sub          "\-"
#token Equal        "=="
#token NotEqual     "!="
#token If           "if"
#token While        "while"
#token Return       "return"
#token Print        "print"
#token Assign       "="
.cE
.PP
All PCCTS grammars that use the AST mechanism need to pass the address
of a \f(CWNULL\fP pointer to the starting rule.
.cB
main()
{
    AST *root=NULL;

    zzs_init(HashTableSize, StringTableSize);
    ANTLR(p(&root), stdin);
}
.cE
.PP
Rule \f(CWp\fP is modified as follows:
.cB
p!      :   <<Sym *p; AST *v;>>
            (   func
            |   "var" def[&globals, GLOBAL] ";"
                <<v = #(#[DefineVar], #2);
                  lisp(v); printf("\en"); zzfree_ast(v);
                >>
            )*
            <<p = zzs_rmscope(&globals);>>
            "@"
        ;
.cE
.LP
The \f(CW#[DefineVar]\fP reference calls our \f(CWzzmk_ast\fP macro
to create an AST node whose token is set to \f(CWDefineVar\fP.  The
reference to \f(CW#(#[DefineVar], #2)\fP is a tree constructor
which makes the \f(CWDefineVar\fP node the parent of the tree returned
by rule \f(CWdef\fP\ \(em \f(CW#2\fP.  In general, the tree
constructor has the form:
.cB
#( \fIroot\fP, \fIsibling1\fP, \fIsibling2\fP, ..., \fIsiblingN\fP )
.cE
.LP
where any \f(CWNULL\fP pointer terminates the list except for the root
pointer. \f(CW#2\fP refers to the second AST node or tree within an
alternative\ \(em \f(CWdef\fP in our case.  Rule \f(CWdef\fP itself
does not change because PCCTS automatically creates a node for the
\f(CWWORD\fP or \f(CWVAR\fP and passes it back to the invoking rule.
.PP
Trees for functions are constructed in the following form:
.cB
     DefineFunc
         |
         v
        FUNC -> DefineVar -> DefineVar -> SLIST
                    |            |          |
                    v            |          v
              optional_arg       |        stat1 -> ... > statn
                                 v
                               local1 -> ... -> localn
.cE
.LP
where \f(CWDefineFunc\fP and \f(CWDefineVar\fP are dummy tokens used
only in trees (as opposed to the grammar).  Rule \f(CWfunc\fP is
modified to build these trees:
.cB
func!  :  <<Sym *locals=NULL, *var, *p; AST *f,*parm=NULL,*v=NULL,*s=NULL;
              current_local_var_offset = 0;>>
            WORD
            <<zzs_scope(&globals);
              var = zzs_newadd($1.text);
              var->level = GLOBAL;
              var->token = FUNC;
            >>
            "\e(" (  def[&locals, PARAMETER] <<parm=#1;>>
                 |  <<current_local_var_offset = 1;>>
                 )
            "\e)"
            "\e{"
                ( "var" def[&locals, LOCAL]
                  <<if ( v==NULL ) v = #2; else v = #(NULL,v,#2);>>
                  ";"
                )*
                ( statement
                  <<if ( s==NULL ) s = #1; else s = #(NULL,s,#1);>>
                )*
            "\e}"
            <<s = #(#[SLIST], s);
              v = #(#[DefineVar], v);
              parm = #(#[DefineVar], parm);
              f = #(#[DefineFunc], #[FUNC,$1.text], parm, v, s);
              lisp(f); printf("\een"); zzfree_ast(f);
              p = zzs_rmscope(&locals);>>
        ;
.cE
.LP
Variable \f(CWparm\fP is set to the AST node created by \f(CWdef\fP
if a parameter is found else it is \f(CWNULL\fP.  Variable \f(CWv\fP
is used to maintain a list of local variables.  The tree constructor
.cB
v = #(NULL,v,#2);
.cE
.LP
says to make a new tree with no root and with siblings \f(CWv\fP and
\f(CW#2\fP\ \(em which effectively links \f(CW#2\fP to the end of the
current list of variables.  Variable \f(CWs\fP behaves in a similar
fashion.  After the list of variables and statements have been
accumulated, we add a dummy node (\f(CWDefineVar\fP, \f(CWSLIST\fP) as
a root to each list so that we get the structure given above.  To
examine the trees we have constructed, we make a call to \f(CWlisp\fP
and then destroy the tree.
.PP
Even though it is not necessary to do so, we will build trees for
\f(CWstatement\fP explicitly (in general, the automatic mechanism is
best for expressions with simple operator/operand relationships).
.cB
statement!: <<AST *s=NULL, *el=NULL;>>
            expr ";"                          <<#0 = #1;>>
        |   "\e{"
                ( statement
                  <<if ( s==NULL ) s = #1; else s = #(NULL,s,#1);>>
                )*
            "\e}" <<#0 = #(#[SLIST], s);>>
        |   "if" "\e(" expr "\e)" statement
            {"else" statement <<el=#2;>>}     <<#0 = #(#[If], #3, #5,el);>>
        | "while" "\e(" expr "\e)" statement    <<#0 = #(#[While], #3,#5);>>
        | "return" expr ";"                   <<#0 = #(#[Return], #2);>>
        | "print" expr ";"                    <<#0 = #(#[Print], #2);>>
        ;
.cE
.LP
Many of the tokens in \f(CWstatement\fP are not included in the tree
because they are a notational convenience for humans or are used for
grouping purposes.  As before, we track lists of statements using the
tree constructor: \f(CW#(NULL,s,#1)\fP.
.PP
The last unusual rule is \f(CWexpr\fP:
.cB
expr4!  :   <<AST *f=NULL, *arg=NULL;>>
            STRING          <<#0 = #[STRING, $1.text];>>
        |   VAR             <<#0 = #[STRING, $1.text];>>
        |   (   FUNC        <<f  = #[FUNC, $1.text];>>
            |   WORD        <<f  = #[FUNC, $1.text];>>
            )
            "\e(" { expr <<arg=#1;>> } "\e)"
            <<#0 = #(f, arg);>>
        |   "\e(" expr "\e)"  <<#0 = #2;>>
        ;
.cE
.LP
Assigning a tree to \f(CW#0\fP makes that tree the return tree.
However, it should really only be used in rules that do not use the
automatic tree construction mechanism; i.e. there is a \f(CW! after\fP
the rule definition.  For a function call, we make a tree with a
\f(CWFUNC\fP node at the root and the optional argument as the child.
The third alternative merely returns what is computed by \f(CWexpr\fP;
the parenthesis are mechanism for syntactic precedence and add nothing
to the tree.  The tree structure itself embodies the precedence.
.PP
The only other required modifications to the grammar are to indicate
which tokens are operators (subtree roots) and which are operands in
the expression rules.  To indicate that a token is to be made a
subtree root, we append a \f(CW^\fP.  All other tokens are considered
operands (children).  Appending a token with \f(CW!\fP indicates that
it is not to be included in the tree.  For example, to make trees like:
.cB
        operator
            |
            v
          opnd1 -> opnd2
.cE
.LP
we modify the operators in \f(CWexpr\fP through \f(CWexpr3\fP in a
fashion similar to:
.cB
expr1   :   expr2 ( (   "\e+"^
                    |   "\e-"^
                    )
                    expr2
                  )*
        ;
.cE
.LP
and
.cB
expr3   :   { "\e-"^ } expr4
        ;
.cE
.NH 2
.iH Full Grammar to Construct Trees
.PP
The following grammar constructs AST's as an intermediate form (IF) of an
\fIsc\fP program and prints out the IF in lisp-like preorder.
.cB
#header <<#include "sym.h"
          #include "charbuf.h"
          #define AST_FIELDS int token, level, offset; char str[D_TextSize];
          #define zzcr_ast(ast,attr,tok,text) create_ast(ast,attr,tok,text)
          #define DONT_CARE         0
          #define SIDE_EFFECTS      1
          #define VALUE             2
        >>

#token "[\et\e ]+"    << zzskip(); >>                /* Ignore White */
#token "\en"         << zzline++; zzskip(); >>
#token STRING "\e"(~[\e0-\e0x1f\e"\e\e]|(\e\e~[\e0-\e0x1f]))*\e"" <<;>>

/* Not actual terminals, just node identifiers */
#token DefineFunc
#token SLIST
.cE
.cB
/* Define tokens for code generation */
#token DefineVar    "var"
#token Mul          "\e*"
#token Div          "/"
#token Add          "\e+"
#token Sub          "\e-"
#token Equal        "=="
#token NotEqual     "!="
#token If           "if"
#token While        "while"
#token Return       "return"
#token Print        "print"
#token Assign       "="

<<;>>

<<
#define HashTableSize       999
#define StringTableSize     5000
#define GLOBAL              0
#define PARAMETER           1
#define LOCAL               2
.cE
.cB
static Sym *globals = NULL; /* global scope for symbols */
static int current_local_var_offset=0;

create_ast(ast,attr,tok,text)
AST *ast;
Attrib *attr;
int tok;
char *text;
{
    Sym *s;

    ast->token = tok;
    if ( tok == VAR )
    {
        s = zzs_get(text);
        ast->level = s->level;
        ast->offset = s->offset;
    }
    if ( tok == STRING || tok == VAR || tok == FUNC ) strcpy(ast->str, text);
}
.cE
.cB
AST *
zzmk_ast(node, token, str)
AST *node;
int token;
char *str;
{
    Sym *s;

    node->token = token;
    if ( token == VAR )
    {
        s = zzs_get(str);
        node->level = s->level;
        node->offset = s->offset;
    }
    if ( token == STRING || token == VAR || token == FUNC )
        strcpy(node->str, str);
    return node;
}
.cE
.cB
lisp(tree)
AST *tree;
{
    while ( tree!= NULL )
    {
        if ( tree->down != NULL ) printf(" (");
        if ( tree->token == STRING ||
             tree->token == VAR ||
             tree->token == FUNC ) printf(" %s", tree->str);
        else printf(" %s", zztokens[tree->token]);
        lisp(tree->down);
        if ( tree->down != NULL ) printf(" )");
        tree = tree->right;
    }
}

main()
{
    AST *root=NULL;

    zzs_init(HashTableSize, StringTableSize);
    ANTLR(p(&root), stdin);
}
.cE
.cB
pScope(p)
Sym *p;
{
    for (; p!=NULL; p=p->scope)
    {
        printf("\etlevel %d | %-12s | %-15s\en",
            p->level,
            zztokens[p->token],
            p->symbol);
    }
}
>>

p!      :   <<Sym *p; AST *v;>>
            (   func
            |   "var" def[&globals, GLOBAL] ";"
                <<v = #(#[DefineVar], #2);
                  gen(v,DONT_CARE); printf("\en"); zzfree_ast(v);
                >>
            )*
            <<p = zzs_rmscope(&globals);>>
            "@"
        ;
.cE
.cB
def[Sym **scope, int level]
        :   <<Sym *var;>>
            (   WORD
                <<zzs_scope($scope);
                  var = zzs_newadd($1.text);
                  var->level = $level;
                  var->token = VAR;
                  var->offset = current_local_var_offset++;
                >>
            |   VAR
                <<var = zzs_get($1.text);
                  if ( $level != var->level )
                  {
                    zzs_scope($scope);
                    var = zzs_newadd($1.text);
                    var->level = $level;
                    var->token = VAR;
                    var->offset = current_local_var_offset++;
                  }
                  else printf("redefined variable ignored: %s\en", $1.text);
                >>
            )
        ;

func!   :   <<Sym *locals=NULL, *var, *p; AST *f,*parm=NULL,*v=NULL,*s=NULL;
              current_local_var_offset = 0;>>
            WORD
            <<zzs_scope(&globals);
              var = zzs_newadd($1.text);
              var->level = GLOBAL;
              var->token = FUNC;
            >>
            "\e(" (  def[&locals, PARAMETER] <<parm=#1;>>
                 |  <<current_local_var_offset = 1;>>
                 )
            "\e)"
            "\e{"
                ( "var" def[&locals, LOCAL]
                  <<if ( v==NULL ) v = #2; else v = #(NULL,v,#2);>>
                  ";"
                )*
                ( statement
                  <<if ( s==NULL ) s = #1; else s = #(NULL,s,#1);>>
                )*
            "\e}"
            <<s = #(#[SLIST], s);
              v = #(#[DefineVar], v);
              parm = #(#[DefineVar], parm);
              f = #(#[DefineFunc], #[FUNC,$1.text], parm, v, s);
              gen(f,DONT_CARE); printf("\en"); zzfree_ast(f);
              p = zzs_rmscope(&locals);>>
        ;
.cE
.cB
statement!: <<AST *s=NULL, *el=NULL;>>
            expr ";"                            <<#0 = #1;>>
        |   "\e{"
                ( statement
                  <<if ( s==NULL ) s = #1; else s = #(NULL,s,#1);>>
                )*
            "\e}"                                <<#0 = #(#[SLIST], s);>>
        |   "if" "\e(" expr "\e)" statement
            {"else" statement <<el=#2;>>}       <<#0 = #(#[If], #3, #5, el);>>
        |   "while" "\e(" expr "\e)" statement    <<#0 = #(#[While], #3, #5);>>
        |   "return" expr ";"                   <<#0 = #(#[Return], #2);>>
        |   "print" expr ";"                    <<#0 = #(#[Print], #2);>>
        ;

expr    :   VAR "="^ expr
        |   expr0
        ;

expr0   :   expr1 ( (   "=="^
                    |   "!="^
                    )
                    expr1
                  )*
        ;

expr1   :   expr2 ( (   "\e+"^
                    |   "\e-"^
                    )
                    expr2
                  )*
        ;

expr2   :   expr3 ( (   "\e*"^
                    |   "/"^
                    )
                    expr3
                  )*
        ;
.cE
.cB
expr3   :   { "\e-"^ } expr4
        ;

expr4!  :   <<AST *f=NULL, *arg=NULL;>>
            STRING          <<#0 = #[STRING, $1.text];>>
        |   VAR             <<#0 = #[VAR, $1.text];>>
        |   (   FUNC        <<f  = #[FUNC, $1.text];>>
            |   WORD        <<f  = #[FUNC, $1.text];>>
            )
            "\e(" { expr <<arg=#1;>> } "\e)"
            <<#0 = #(f, arg);>>
        |   "\e(" expr "\e)"  <<#0 = #2;>>
        ;

#token WORD "[a-zA-Z]+"
    <<{
        Sym *p = zzs_get(LATEXT(1));
        if ( p != NULL ) NLA = p->token;
    }>>
.cE
.NH 2
.iH Example translations
.PP
To illustrate how functions get translated, consider the following
\fIsc\fP program:
.cB
var a;

main(n)
{
    var b;
}
.cE
.LP
Our translator would create trees represented by:
.cB
 ( DefineVar WORD )
 ( DefineFunc FUNC ( DefineVar WORD ) ( DefineVar WORD ) SLIST )
.cE
.LP
where \f(CWWORD\fP represents the variables found on the input
stream.  \f(CWSLIST\fP has no child because there were no statements
in the function.
.PP
Some example statement transformations follow.
.LP
\f(CWif\fP:
.cB
if ( b == "hello" ) print n;
.cE
.LP
translates to
.cB
( If ( Equal b "hello" ) ( Print n ) )
.cE
.LP
\f(CWwhile\fP:
.cB
while ( i != "10" ) { print i; i = i+"1"; }
.cE
.LP
translates to
.cB
( While ( NotEqual i "10" ) ( SLIST ( Print i ) ( = i ( Add i "1" ) ) ) )
.cE
.PP
Expressions have the operator at the root and the operands as
children.  For example,
.cB
i = a + "3" * "9" + f("jim");
.cE
.LP
would be translated to:
.cB
( = i ( Add ( Add a ( Mul "3" "9" ) ) ( f "jim" ) ) )
.cE
.LP
which looks like:
.cB
        =
        |
        v
        i -> Add
              |
              v
             Add --------------> f
              |                  |
              v                  v
              a -> Mul         "jim"
                    |
                    v
                   "3" -> "9"
.cE
.NH
.iH  Code generation from intermediate form
.PP
To translate the intermediate form (IF) to the stack code described
above, we present the following simple little code generator.  We use
no devious C programming to make this fast or nifty because this
document concentrates on how PCCTS grammars are developed not on how
to write spectacular C code.
.NH 2
.iH Modification of tree construction grammar
.PP
To convert from the translator above that printed out trees in lisp
format, we add the following definitions needed as arguments to
\f(CWgen()\fP in the \f(CW#header\fP action.
.cB
          #define DONT_CARE         0
          #define SIDE_EFFECTS      1
          #define VALUE             2
.cE
.PP
Also, we replace all calls to \f(CWlisp(\fItree\fP)\fR with
\f(CWgen(\fItree\fP, DONT_CARE)\fP.
.NH 2
.iH Code generator
.PP
Function \f(CWgen()\fP presented below accepts an AST as an argument
and walks the tree generating output when necessary.  You will notice
all the header information needed by this file, \f(CWcode.c\fP.  This
illustrates one of the minor inconveniences of PCCTS.  Any C file that
needs to access PCCTS variables, rules, etc... must include all of the
things that PCCTS generates at the head of all PCCTS generated files.
.PP
The code generator accepts an evaluation mode argument so that it can
remove some unnecessary code.  For example,
.cB
main()
{
    "3" + f();
} 
f()
{}
.cE
.LP
would result in
.cB
#include "sc.h"
_main()
{
    BEGIN;
    CALL(f);
    POP;
    END;
}

f()
{
    BEGIN;
    END;
}
.cE
.LP
Code to push and add \f(CW"3"\fP was eliminated because it had no side
effects.  Only function calls have side effects in \fIsc\fP.
.cB
/*
 * Simple code generator for PCCTS 1.0x tutorial
 *
 * Terence Parr
 * Purdue University
 * Electrical Engineering
 * March 19, 1992
 */
#include <stdio.h>
#include "sym.h"
#include "charbuf.h"
#define AST_FIELDS int token, level, offset; char str[D_TextSize];
#define zzcr_ast(ast,attr,tok,text) create_ast(ast,attr,tok,text)
#include "antlr.h"
#include "ast.h"
#include "tokens.h"
#include "dlgdef.h"
#include "mode.h"
#define GLOBAL              0
#define PARAMETER           1
#define LOCAL               2
.cE
.cB
static int LabelNum=0, GenHeader=0;

#define DONT_CARE			0
#define SIDE_EFFECTS		1
#define VALUE				2
.cE
.cB
gen(t,emode)
AST *t;
int emode;	/* evaluation mode member { SIDE_EFFECTS, VALUE, DONT_CARE } */
{
	AST *func, *arg, *locals, *slist, *a, *opnd1, *opnd2, *lhs, *rhs;
	int n;
.cE
.cB
	if ( t == NULL ) return;
	if ( !GenHeader ) { printf("#include \e"sc.h\e"\en"); GenHeader=1; }

	switch ( t->token )
	{
.cE
.cB
	case DefineFunc :
		func = zzchild(t);
		arg = zzchild( zzsibling(func) );
		locals = zzchild( zzsibling( zzsibling(func) ) );
		slist = zzsibling( zzsibling( zzsibling(func) ) );
		if ( strcmp(func->str, "main") == 0 )
			printf("_%s()\en{\en\etBEGIN;\en", func->str);
		else
			printf("%s()\en{\en\etBEGIN;\en", func->str);
		for (a=locals; a!=NULL; a = zzsibling(a)) printf("\etLOCAL;\en");
		gen( slist, DONT_CARE );
		printf("\etEND;\en}\en");
		break;
.cE
.cB
	case SLIST :
		for (a=zzchild(t); a!=NULL; a = zzsibling(a))
		{
			gen( a, EvalMode(a->token) );
			if ( a->token == Assign ) printf("\etPOP;\en");
		}
		break;
.cE
.cB
	case DefineVar :
		printf("SCVAR %s;\en", zzchild(t)->str);
		break;
.cE
.cB
	case Mul :
	case Div :
	case Add :
	case Sub :
	case Equal :
	case NotEqual :
		opnd1 = zzchild(t);
		opnd2 = zzsibling( opnd1 );
		gen( opnd1, emode );
		gen( opnd2, emode );
		if ( emode == SIDE_EFFECTS ) break;
		switch ( t->token )
		{
		case Mul : printf("\etMUL;\en"); break;
		case Div : printf("\etDIV;\en"); break;
		case Add : printf("\etADD;\en"); break;
		case Sub : if ( opnd2==NULL ) printf("\etNEG;\en");
				   else printf("\etSUB;\en");
				   break;
		case Equal : printf("\etEQ;\en"); break;
		case NotEqual : printf("\etNEQ;\en"); break;
		}
		break;
.cE
.cB
	case If :
		a = zzchild(t);
		gen( a, VALUE );				/* gen code for expr */
		n = LabelNum++;
		printf("\etBRF(iflabel%d);\en", n);
		a = zzsibling(a);
		gen( a, EvalMode(a->token) );	/* gen code for statement */
		printf("iflabel%d: ;\en", n);
		break;
.cE
.cB
	case While :
		a = zzchild(t);
		n = LabelNum++;
		printf("wbegin%d: ;\en", n);
		gen( a, VALUE );				/* gen code for expr */
		printf("\etBRF(wend%d);\en", n);
		a = zzsibling(a);
		gen( a, EvalMode(a->token) );	/* gen code for statement */
		printf("\etBR(wbegin%d);\en", n);
		printf("wend%d: ;\en", n);
		break;
.cE
.cB
	case Return :
		gen( zzchild(t), VALUE );
		printf("\etRETURN;\en");
		break;
.cE
.cB
	case Print :
		gen( zzchild(t), VALUE );
		printf("\etPRINT;\en");
		break;
.cE
.cB
	case Assign :
		lhs = zzchild(t);
		rhs = zzsibling( lhs );
		gen( rhs, emode );
		printf("\etDUP;\en");
		if ( lhs->level == GLOBAL ) printf("\etSTORE(%s);\en", lhs->str);
		else printf("\etLSTORE(%d);\en", lhs->offset);
		break;
.cE
.cB
	case VAR :
		if ( emode == SIDE_EFFECTS ) break;
		if ( t->level == GLOBAL ) printf("\etPUSH(%s);\en", t->str);
		else printf("\etLPUSH(%d);\en", t->offset);
		break;
.cE
.cB
	case FUNC :
		gen( zzchild(t), VALUE );
		printf("\etCALL(%s);\en", t->str);
		break;
.cE
.cB
	case STRING :
		if ( emode == SIDE_EFFECTS ) break;
		printf("\etSPUSH(%s);\en", t->str);
		break;
.cE
.cB
	default :
		printf("Don't know how to handle: %s\en", zztokens[t->token]);
		break;
	}
}
.cE
.cB
EvalMode( tok )
int tok;
{
	if ( tok == Assign || tok == If || tok == While ||
		 tok == Print || tok == Return ) return VALUE;
	else return SIDE_EFFECTS;
}
.cE
.NH 2
.iH Makefile for code generator
.PP
This makefile is roughly the same as before except that we need to
tell PCCTS to generate tree information and we need to link in the
code generator.
.cB
CFLAGS= -I../h
GRM=tut4
SRC=scan.c $(GRM).c err.c sym.c code.c
OBJ=scan.o $(GRM).o err.o sym.o code.o

tutorial: $(OBJ) $(SRC)
    cc -o $(GRM) $(OBJ)

$(GRM).c parser.dlg : $(GRM).g
    antlr -k 2 -gt $(GRM).g

scan.c : parser.dlg
    dlg -C2 parser.dlg scan.c
.cE
.pn 0
.bp
.PX
