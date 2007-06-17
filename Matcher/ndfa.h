/*
 *  ndfa.h
 *  Inform-xc2
 *
 *  Created by Andrew Hunter on 15/06/2007.
 *  Copyright 2007 Andrew Hunter. All rights reserved.
 *
 */

/*
 * C Implementation of an NDFA/DFA matching algorithm (effectively a unicode regular expression engine)
 */

#ifndef INFORM_NDFA_H
#define INFORM_NDFA_H

/* ===============
 * Data structures
 */

/* Tokens are 32-bit numbers */
typedef unsigned int ndfa_token;

/* Data structure used to represent a DFA/NDFA */
typedef struct ndfa* ndfa;

/* ==============
 * Special tokens 
 */

/* Special token indicating that we should match any character not otherwise matched */
#define NDFA_ANY	((ndfa_token)0xffffffff)
#define NDFA_START	((ndfa_token)0xfffffffe)
#define NDFA_END	((ndfa_token)0xfffffffd)

/* ==============
 * Building NDFAs
 */

typedef void (*ndfa_free_data)(void* data);

/* Creates a new NDFA, with a single start state */
extern ndfa ndfa_create();

/* Releases the memory associated with an NDFA, with optional function to also free all of the data values */
extern void ndfa_free(ndfa nfa, ndfa_free_data free_data);

/* Resets the state to which we're adding NDFA transitions to be the start state */
extern void ndfa_reset(ndfa nfa);

/* Adds a new single transition on receiving the given token, and moves the ndfa to that point */
/* Data should be non-null to indicate an accepting state. Note that the NDFA is greedy by default. */
extern void ndfa_transition(ndfa nfa, ndfa_token token, void* data);

/* ===============
 * Compiling NDFAs
 */

/* Compiles an NDFA into a DFA (with only one transition per token) */
extern ndfa ndfa_compile(ndfa nfa);

/* =============
 * Running NDFAs
 */

#ifdef DEBUG

/* ===============
 * Debugging NDFAs
 */

/* Prints a DFA/NDFA to stdout */
extern void ndfa_dump(ndfa nfa);

#endif

#endif
