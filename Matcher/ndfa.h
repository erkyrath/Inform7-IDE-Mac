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
typedef unsigned int ndfa_pointer;

/* Data structure representing a running DFA */
typedef struct ndfa_run_state* ndfa_run_state;

/* ==============
 * Special tokens 
 */

/* Special token indicating that we should match any character not otherwise matched */
#define NDFA_START		((ndfa_token)0xffff0001)
#define NDFA_END		((ndfa_token)0xffff0002)

/* Special pointer indicating a rejection */
#define NDFA_REJECT		((ndfa_pointer)0xffffffff)

/* ==============
 * Building NDFAs
 */

/* Creates a new NDFA, with a single start state */
extern ndfa ndfa_create();

/* Releases the memory associated with an NDFA */
extern void ndfa_free(ndfa nfa);

/* Resets the state to which we're adding NDFA transitions to be the start state */
extern void ndfa_reset(ndfa nfa);

/* Creates a new state without any transitions leading to it */
extern ndfa_pointer ndfa_create_state(ndfa nfa);

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

/* Peeks at the value on top of the state stack */
extern ndfa_pointer ndfa_peek(ndfa nfa);

/* Sets the state on top of the stack as the current state (equivalent of an OR in a regexp) */
/* This also notes all of the parallel finishing states as it goes for later use with rejoin */
extern void ndfa_or(ndfa nfa);

/* Joins all of the finishing states created after the most recent set of ndfa_or calls, giving them all a common finishing state */
/* Additionally, pops from the state stack */
extern void ndfa_rejoin(ndfa nfa);

/* Adds a transistion to the states after the state on top of the state stack (without popping, equivalent to a + in a regexp) */
/* Can be combined with ndfa_or and/or ndfa_add_data to give the equivalent of * */
extern void ndfa_repeat(ndfa nfa);

/* Takes the state machine after the first item on the stack to the current location and repeats it a given number of times */
/* Set push_last_start to cause the start state of the last repetition to be pushed onto the stack (if this isn't set, the stack is unchanged) */
extern void ndfa_repeat_number(ndfa nfa, int min_count, int max_count, int push_last_start);

/* Copies all of the states following the specified state into a new, isolated, state machine and returns the pointer to it */
/* If non-null, anchor is updated to point to a where a specific state was copied to */
extern ndfa_pointer ndfa_copy(ndfa nfa, ndfa_pointer state, ndfa_pointer* anchor);

/* Given a list of states, joins them together into a single 'final' state */
extern ndfa_pointer ndfa_join(ndfa nfa, int num_states, const ndfa_pointer* state);

/* =============================
 * Compiling regular expressions
 */

/* Compiles a UCS-4 regexp into a ndfa */
extern int ndfa_compile_regexp_ucs4(ndfa nfa, const ndfa_token* regexp, void* data);

/* Compiles an ASCII regexp into a ndfa */
extern int ndfa_compile_regexp(ndfa nfa, const char* regexp, void* data);

/* ===============
 * Compiling NDFAs
 */

/* Compiles an NDFA into a DFA (with only one transition per token) */
extern ndfa ndfa_compile(ndfa nfa);

/* ===============
 * Querying NDFAs
 */

/* Returns the data blocks associated with a particular state */
extern void** ndfa_data_for_state(ndfa nfa, ndfa_pointer state, int* count);

/* =============
 * Running NDFAs
 */

/* Handler callback when the ndfa accepts or rejects input */
/* accept will be NDFA_REJECT if this is being called due to a rejection */
typedef void (*ndfa_input_handler)(ndfa_run_state state, int length, ndfa_pointer accept, void* context);

/* Initialises a ndfa, ready to run */
extern ndfa_run_state ndfa_start(ndfa dfa);

/* Registers a pair of handlers for a DFA */
extern void ndfa_add_handlers(ndfa_run_state run_state, ndfa_input_handler accept, ndfa_input_handler reject, void* context);

/* Retrieves the input most recently rejected/accepted by the DFA (note that less memory is used if this is not called) */
extern ndfa_token* ndfa_last_input(ndfa_run_state run_state);

/* Sends a token to a running DFA */
extern void ndfa_run(ndfa_run_state state, ndfa_token token);

/* Copies a running DFA */
extern ndfa_run_state ndfa_copy_run_state(ndfa_run_state run_state);

/* Compares a DFA to a copy (non-zero if the run states are the same) */
/* Combined with copy_run_state, this can be used to implement a restartable syntax highlighter */
extern int ndfa_run_state_equals(ndfa_run_state run_state1, ndfa_run_state run_state2);

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
