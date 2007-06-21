/*
 *  ndfa.h
 *  Inform-xc2
 *
 *  Created by Andrew Hunter on 15/06/2007.
 *  Copyright 2007 Andrew Hunter. All rights reserved.
 *
 */

/*
 * C Implementation of an NDFA/DFA matching algorithm (effectively a 31 bit regular expression engine)
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

/* Data structure representing a running DFA */
typedef struct ndfa_run_state* ndfa_run_state;

/* ===============
 * Data structures
 */

/* ==============
 * Special tokens 
 */

/* Special token indicating that we should match any character not otherwise matched */
#define NDFA_START	((ndfa_token)0xffff0001)
#define NDFA_END	((ndfa_token)0xffff0002)

/* ==============
 * Building NDFAs
 */

/* Callback that can be used while freeing */
typedef void (*ndfa_free_data)(void* data);

/* Creates a new NDFA, with a single start state */
extern ndfa ndfa_create();

/* Releases the memory associated with an NDFA, with optional function to also free all of the data values */
extern void ndfa_free(ndfa nfa, ndfa_free_data free_data);

/* Resets the state to which we're adding NDFA transitions to be the start state */
extern void ndfa_reset(ndfa nfa);

/* Adds an inclusive range of tokens as a new transition */
void ndfa_transition_range(ndfa nfa, ndfa_token token_start, ndfa_token token_end, void* data);

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

/* Handler callback when the ndfa accepts or rejects input */
typedef void (*ndfa_input_handler)(ndfa_run_state state, int length, void* data, void* context);

/* Initialises a ndfa, ready to run */
extern ndfa_run_state ndfa_start(ndfa dfa);

/* Registers a pair of handlers for a DFA */
extern void ndfa_add_handlers(ndfa_run_state run_state, ndfa_input_handler accept, ndfa_input_handler reject, void* context);

/* Retrieves the input most recently rejected/accepted by the DFA (note that less memory is used if this is not called) */
extern ndfa_token* ndfa_last_input(ndfa_run_state run_state);

/* Sends a token to a running DFA */
extern void ndfa_run(ndfa_run_state state, ndfa_token token);

/* Finalises a running DFA */
extern void ndfa_finish(ndfa_run_state state);

#ifdef DEBUG

/* ===============
 * Debugging NDFAs
 */

/* Prints a DFA/NDFA to stdout */
extern void ndfa_dump(ndfa nfa);

#endif

#endif
