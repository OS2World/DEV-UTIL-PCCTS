/* a modified aTrax that just keeps the rules applied in a circular buffer
 * it then prints them when an error occurs to get the context that
 * rules was applied in
 *
 * Will Cohen
 * 2/7/90
 */

#include <stdio.h>
#include <string.h>
#include "sym.h"
#include "pascal.h"
#include "dlgdef.h"
#include "antlr.h"

#define N_RULES		50	/* last N_RULES kept in buffer for analysis */
#define LINE_LEN 	128	/* max length of line allowed */
#define FORMAT	"%s(%.128s)\n"	/* number here and in LINE_LEN should agree */

/* circular buffer for rules */
char *rules_applied[N_RULES];
char *rules_text[N_RULES][LINE_LEN];

int line_n = 0;
int valid_lines = 0;

#ifdef OLD
/* put the trace in the circular buffer */
zzTRACE(rule)
char *rule;
{
	/* only need to store the pointer to the rule */
	rules_applied[line_n] = rule;
	strncpy(rules_text[line_n],LATEXT(1), LINE_LEN);
	line_n = (++line_n) % N_RULES;
	if (valid_lines < N_RULES) ++valid_lines;
}


/* prints out the rules in buffer */
print_trax()
{
	register i,k;

	k = (line_n-valid_lines)%N_RULES;
	/* take care of negative modulii */
	if (k<0) k += N_RULES;
	for(i = 0; i<valid_lines; i++){
		fprintf(stderr, FORMAT,	rules_applied[k], rules_text[k]);
		k++;
		if (k>= N_RULES) k = 0;
		}
}
#endif
