/*
 * stdpccts.h -- P C C T S  I n c l u d e
 *
 * Terence Parr, Hank Dietz and Will Cohen: 1989-1993
 * Purdue University Electrical Engineering
 * ANTLR Version 1.10
 */
#include <stdio.h>
#define ANTLR_VERSION	110

#ifdef __cplusplus
#ifndef __STDC__
#define __STDC__
#endif
#endif
#include "set.h"
#include <ctype.h>
#include "syn.h"
#include "hash.h"
#include "generic.h"
#define zzcr_attr(attr,tok,t)
#define zzEOF_TOKEN 1
#define zzSET_SIZE 12
#include "antlr.h"
#include "tokens.h"
#include "dlgdef.h"
#include "mode.h"
