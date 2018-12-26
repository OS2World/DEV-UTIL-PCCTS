/*
 * genmk -- a program to make makefiles for PCCTS
 *
 * genmk project f1.g f2.g f3.g ...
 *
 * where fi.g are the grammar files you want a makefile for
 *
 * ANTLR 1.10
 * Terence John Parr 1989 - 1993
 * Purdue University
 */
#include <stdio.h>

char *dlg = "parser.dlg";
char *err = "err.c";
char *hdr = "stdpccts.h";
char *tok = "tokens.h";
char *mode = "mode.h";

main(argc, argv)
int argc;
char **argv;
{
	char *project;
	char **files;

	if ( argc < 3 )
	{
		fprintf(stderr, "genmk: genmk project f1.g f2.g f3.g ...\n");
		exit(-1);
	}
	project = argv[1];
	files = &argv[2];
	mk(project, files, argc-2);
	return 0;
}

mk(project, files, n)
char *project;
char **files;
int n;
{
	printf("#\n");
	printf("# PCCTS makefile for: ");
	pfiles(files, n, NULL);
	printf("\n");
	printf("# PCCTS release 1.10\n");
	printf("#\n");
	printf("DLG_FILE = %s\n", dlg);
	printf("ERR_FILE = %s\n", err);
	printf("HDR_FILE = %s\n", hdr);
	printf("TOK_FILE = %s\n", tok);
	printf("MOD_FILE = %s\n", mode);
	printf("K = 1\n");
	printf("ANTLR_H = .\n");
	printf("BIN = .\n");
	printf("ANTLR = $(BIN)/antlr\n");
	printf("DLG = $(BIN)/dlg\n");
	printf("CFLAGS = -I. -I$(ANTLR_H)\n");
	printf("AFLAGS = -fe $(ERR_FILE) -fh $(HDR_FILE) -fl $(DLG_FILE) -ft $(TOK_FILE) \\\n         -fm $(MOD_FILE) -k $(K) -gk\n");
	printf("DFLAGS = -C2 -i\n");
	printf("GRM = ");
	pfiles(files, n, NULL);
	printf("\n");
	printf("SRC = ");
	pfiles(files, n, "c");
	printf(" scan.c err.c\n");
	printf("OBJ = ");
	pfiles(files, n, "o");
	printf(" scan.o err.o\n");
	printf("\n%s: $(OBJ) $(SRC)\n", project);
	printf("	cc -o %s $(CFLAGS) $(OBJ)\n", project);
	printf("\n");
	pfiles(files, n, "o");
	printf(" : $(MOD_FILE) $(TOK_FILE) ");
	pfiles(files, n, "c");
	printf("\n\n");
	pfiles(files, n, "c");
	printf(" %s tokens.h : ", dlg);
	pfiles(files, n, NULL);
	printf("\n");
	printf("	$(ANTLR) $(AFLAGS) ");
	pfiles(files, n, NULL);
	printf("\n");
	printf("\n");
	printf("scan.c mode.h : %s\n", dlg);
	printf("	$(DLG) $(DFLAGS) %s scan.c\n", dlg);
	printf("\n");
}

pfiles(files, n, suffix)
char **files;
int n;
char *suffix;
{
	int first=1;

	while ( n>0 )
	{
		char *p = &(*files)[strlen(*files)-1];
		if ( !first ) putchar(' ');
		first=0;
		while ( p > *files && *p != '.' ) --p;
		if ( p == *files )
		{
			fprintf(stderr,
					"genmk: filenames must be file.suffix format: %s\n",
					*files);
			exit(-1);
		}
		if ( suffix == NULL ) printf("%s", *files);
		else
		{
			*p = '\0';
			printf("%s.%s", *files, suffix);
			*p = '.';
		}
		files++;
		--n;
	}
}
