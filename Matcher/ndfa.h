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

/* Data structure pointing to a specific state in an NDFA */
typedef int ndfa_pointer;

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
extern void ndfa_transition_range(ndfa nfa, ndfa_token token_start, ndfa_token token_end, void* data);

/* Adds a new single transition on receiving the given token, and moves the ndfa to that point */
/* Data should be non-null to indicate an accepting state. Note that the NDFA is greedy by default. */
extern void ndfa_transition(ndfa nfa, ndfa_token token, void* data);

/* Adds a transition to/from a specific known state */
extern void ndfa_transition_to(ndfa nfa, ndfa_pointer from, ndfa_pointer to, ndfa_token token_start, ndfa_token token_end);

/* Retrieves a pointer to the current NDFA state */
extern ndfa_pointer ndfa_get_pointer(ndfa nfa);

/* Sets the current state using a pointer retrieved using get_pointer */
extern void ndfa_set_pointer(ndfa nfa, ndfa_pointer to);

/* Adds some data for the current state (makes it accepting if non-null). */ 
/* Note that a state may have more than one piece of data associated with it */
extern void ndfa_add_data(ndfa nfa, void* data);

/* Adds a note for the current state (doesn't make it accepting but can still be retrieved later) */
extern void ndfa_add_note(ndfa nfa, void* note);

/* Pushes the current state onto a stack */
extern void ndfa_push(ndfa nfa);

/* Pops and discards the last state on the state stack */
extern void ndfa_pop(ndfa nfa);

/* Pops a state from the stack and sets it as the current state (equivalent of an OR in a regexp) */
extern void ndfa_or(ndfa nfa);

/* Adds a transistion to the states after the state on top of the state stack (without popping, equivalent to a + in a regexp) */
/* Can be combined with ndfa_or and/or ndfa_add_data to give the equivalent of * */
extern void ndfa_repeat(ndfa nfa);

/* Takes the state machine after the first item on the stack to the current location and repeats it a given number of times */
extern void ndfa_repeat_number(ndfa nfa, int min_count, int max_count);

/* Copies all of the states following the specified state into a new, isolated, state machine and returns the pointer to it */
/* If non-null, anchor is updated to point to a where a specific state was copied to */
extern ndfa_pointer ndfa_copy(ndfa nfa, ndfa_pointer state, ndfa_pointer* anchor);

/* Given a list of states, joins them together into a single 'final' state */
extern ndfa_pointer ndfa_join(ndfa nfa, int num_states, const ndfa_pointer* state);

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
