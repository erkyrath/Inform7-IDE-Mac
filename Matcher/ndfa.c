/*
 *  ndfa.c
 *  Inform-xc2
 *
 *  Created by Andrew Hunter on 15/06/2007.
 *  Copyright 2007 Andrew Hunter. All rights reserved.
 *
 */

/*
 * The following macros can be defined to affect how this is compiled:
 *
 * DEBUG		include debugging code
 * RELEASE		reduce the number of assertions to increase performance
 * INLINE		use 'inline' to increase performance (compiler must support it)
 * __INLINE__	syntax for declaring static functions as being inlined (uses inline by default)
 */

/*
 * TODO: 'state' for the state in the running part is confusing with 'state' for an NDFA state
 */

#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "ndfa.h"

/* set this to 0 this to use less memory but have joins take longer */
#define FAST_JOINS 1

#ifdef INLINE
# ifndef __INLINE__
#  define __INLINE__ inline
# endif
#else
# undef __INLINE__
# define __INLINE__
#endif

#define NDFA_GROW (32)						/* Amount to grow arrays by when allocating memory */

/* Data structures used to represent a DFA/NDFA */
#define NDFA_MAGIC (0x4dfa4dfa)				/* Magic number */

typedef struct ndfa_state ndfa_state;

typedef struct ndfa_token_range {
	ndfa_token start;						/* First token in this range (inclusive) */
	ndfa_token end;							/* Final token in this range (exclusive) */
} ndfa_token_range;

typedef struct ndfa_transit {
	/* NDFA transition */
	ndfa_token_range	tokens;				/* The token which this transition moves on */
	int					new_state;			/* The state that is reached when this token is matched */
} ndfa_transit;

struct ndfa_state {
	/* NDFA state information */
	unsigned int		id;					/* ID for this state */
	int					num_transitions;	/* Number of transitions from this state */
	int					total_transitions;	/* Total amount allocated for transitions from this state */
	ndfa_transit*		transitions;		/* Transitions associated with this state */
	
	int 				num_data;			/* Number of data pointers associated with this state (if >0 this is an accepting state)*/
	void**				data_pointers;		/* Data if this state is accepted */
	
	unsigned int		shared_state;		/* Any transitions from this state are also added to the shared_state (handles blank ORs) */
	
#if FAST_JOINS
	/* These make _join go faster */
	int 				num_sources;		/* Number of states that have a transition to this one */
	int 				total_sources;		/* Total number of states in the sources array */
	unsigned int*		sources;			/* States that target this one */
#endif
};

typedef struct ndfa_join_stack {
	int  			num_states;				/* Number of states that will be joined */
	unsigned int*	states;					/* The states to join together when rejoin is used */
} ndfa_join_stack;

struct ndfa {
	/* Definition of an NDFA */
	unsigned int		magic;				/* Magic number indicating this is a valid NDFA */
	
	int					is_dfa;				/* non-zero if this is a compiled DFA that can actually be run */
	int					start;				/* The start state */
	int					compile_state;		/* The state from which the next transistion will be added*/
	
	int					num_states;			/* Number of used states in the states array */
	int					total_states;		/* Total number of states in this ndfa */
	ndfa_state*			states;				/* All the states associated with this ndfa */
	
	int					stack_length;		/* Number of states on the stack */
	int					stack_total;		/* Total size of the state stack */
	int*				state_stack;		/* The state stack itself */
	ndfa_join_stack**	stack_joins;		/* The state join stack */
};

#ifdef DEBUG

#include <stdio.h>

/* ===============
 * Debugging NDFAs
 */

#define CHARFORTOKEN(token) ((token)>=32&&(token)<127?(token):'?')

/* Prints a DFA/NDFA to stdout */
void ndfa_dump(ndfa nfa) {
	int state_num;
	
	printf("%i states (%s)\n", nfa->num_states, nfa->is_dfa?"deterministic":"nondeterministic");
	
	for (state_num = 0; state_num < nfa->num_states; state_num++) {
		ndfa_state* state = nfa->states + state_num;
		printf("\nState %i (%i transitions)%s", state_num, state->num_transitions, state->num_data>0?" (accepting)":"");
		if (state->shared_state != 0xffffffff) {
			printf(" (linked to state %i)", state->shared_state);
		}
		printf("\n");
		
		int transition;
		for (transition = 0; transition < state->num_transitions; transition++) {
			ndfa_transit* trans = state->transitions + transition;
			printf("  %i-%i (%c-%c) -> %i\n", 
				   trans->tokens.start, trans->tokens.end-1,
				   CHARFORTOKEN(trans->tokens.start), CHARFORTOKEN(trans->tokens.end-1), 
				   trans->new_state);
		}
	}
	
	printf("\n");
}

#endif

/* ==============
 * Building NDFAs
 */

/* Creates a new NDFA state with the specified data and no transitions */
static __INLINE__ ndfa_state* create_state(ndfa nfa, void* data) {
	/* Choose a state in the states array for this NDFA */
	int this_state = nfa->num_states++;
	
	/* Create more space if needed */
	if (this_state >= nfa->total_states) {
		nfa->total_states += NDFA_GROW;
		nfa->states = realloc(nfa->states, sizeof(ndfa_state)*nfa->total_states);
		
		assert(nfa->states != NULL);
	}
	
	/* Allocate a new state */
	ndfa_state* new_state = nfa->states + this_state;
	
	/* Populate it */
	new_state->id					= this_state;
	new_state->num_transitions		= 0;
	new_state->total_transitions	= 0;
	new_state->transitions			= NULL;
	new_state->shared_state			= 0xffffffff;
	
	new_state->num_data				= 0;
	new_state->data_pointers		= NULL;
	
#if FAST_JOINS
	new_state->num_sources			= 0;
	new_state->total_sources		= 0;
	new_state->sources				= NULL;
#endif
	
	/* Return the result */
	return new_state;
}

/* Adds a transition to the specified state */
static __INLINE__ void add_transition(ndfa nfa, ndfa_state* from, ndfa_state* to, ndfa_token token_start, ndfa_token token_end) {
	/* Choose a location in the transition array for the new transition */
	int this_transition = from->num_transitions++;
	
	/* Grow the transitions array if necessary */
	if (this_transition >= from->total_transitions) {
		from->total_transitions += NDFA_GROW;
		from->transitions = realloc(from->transitions, sizeof(ndfa_transit)*from->total_transitions);
		
		assert(from->transitions != NULL);
	}
	
	/* Allocate a new transition */
	ndfa_transit* new_transit = from->transitions + this_transition;
	
	new_transit->tokens.start	= token_start;
	new_transit->tokens.end		= token_end;
	new_transit->new_state		= to->id;
	
#if FAST_JOINS
	/* Remember that the 'from' state joins to the 'to' state */
	if (from != to) {
		if (to->num_sources >= to->total_sources) {
			to->total_sources += NDFA_GROW;
			to->sources = realloc(to->sources, sizeof(unsigned int)*to->total_sources);
		}
		to->sources[to->num_sources++] = from->id;
	}
#endif
	
	/* Add this transition to any shared states */
	if (from->shared_state != 0xffffffff) {
		int shared = from->shared_state;
		from->shared_state = 0xffffffff;
		add_transition(nfa, nfa->states + shared, to, token_start, token_end);
		from->shared_state = shared;
	}
}

/* Creates a new NDFA, with a single start state */
ndfa ndfa_create() {
	/* Allocate a new NDFA */
	ndfa new_ndfa = malloc(sizeof(struct ndfa));
	assert(new_ndfa != NULL);
	
	/* Populate it with a single start state */
	new_ndfa->is_dfa		= 0;
	new_ndfa->num_states	= 0;
	new_ndfa->total_states	= 0;
	new_ndfa->states		= NULL;
	new_ndfa->magic			= NDFA_MAGIC;
	
	new_ndfa->start			= create_state(new_ndfa, NULL)->id;
	new_ndfa->compile_state	= new_ndfa->start;
	
	new_ndfa->state_stack	= NULL;
	new_ndfa->stack_total	= 0;
	new_ndfa->stack_length	= 0;
	new_ndfa->stack_joins	= NULL;
	
	/* Add a 'start' transition */
	add_transition(new_ndfa, new_ndfa->states + new_ndfa->start, new_ndfa->states + new_ndfa->start, NDFA_START, NDFA_START+1);

	/* Return it */
	return new_ndfa;
}

/* Releases the memory associated with an NDFA */
void ndfa_free(ndfa nfa) {
	int x;

	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	
	/* Kill the magic */
	nfa->magic = 0;
	
	/* Free all of the state data */
	for (x=0; x<nfa->num_states; x++) {
		if (nfa->states[x].data_pointers)	free(nfa->states[x].data_pointers);
#if FAST_JOINS
		if (nfa->states[x].sources) 		free(nfa->states[x].sources);
#endif
	}
	
	/* Free all of the transitions */
	for (x=0; x<nfa->num_states; x++) {
		free(nfa->states[x].transitions);
	}
	
	/* Free up the join stacks */
	for (x=0; x<nfa->stack_total; x++) {
		if (nfa->stack_joins[x] != NULL) {
			free(nfa->stack_joins[x]->states);
			free(nfa->stack_joins[x]);
		}
	}
	
	/* Free up the nfa */
	free(nfa->stack_joins);
	free(nfa->state_stack);
	free(nfa->states);
	free(nfa);
}

/* Resets the state to which we're adding NDFA transitions to be the start state */
void ndfa_reset(ndfa nfa) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	
	/* Reset the 'current' state back to the start */
	nfa->compile_state = nfa->start;
	
	/* Clear the stack */
	nfa->stack_length = 0;
}

/* Creates a new state without any transitions leading to it */
ndfa_pointer ndfa_create_state(ndfa nfa) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	
	return create_state(nfa, NULL)->id;
}

/* Adds an inclusive range of tokens as a new transition */
void ndfa_transition_range(ndfa nfa, ndfa_token token_start, ndfa_token token_end, void* data) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	
	/* Construct a new state for this transition */
	ndfa_state* new_state = create_state(nfa, data);
	
	/* Add this transition */
	add_transition(nfa, nfa->states + nfa->compile_state, new_state, token_start, token_end+1);
	nfa->compile_state = new_state->id;
	
	/* This is not a DFA any more */
	nfa->is_dfa = 0;
}

/* Adds a new single transition on receiving the given token, and moves the ndfa to that point */
/* Data should be non-null to indicate an accepting state. Note that the NDFA is greedy by default. */
void ndfa_transition(ndfa nfa, ndfa_token token, void* data) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	
	/* Construct a new state for this transition */
	ndfa_state* new_state = create_state(nfa, data);
	
	/* Add this transition */
	add_transition(nfa, nfa->states + nfa->compile_state, new_state, token, token+1);
	nfa->compile_state = new_state->id;
	
	/* This is not a DFA any more */
	nfa->is_dfa = 0;
}

/* Adds a transition to/from a specific known state */
void ndfa_transition_to(ndfa nfa, ndfa_pointer from, ndfa_pointer to, ndfa_token token_start, ndfa_token token_end) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	
	assert(from >= 0);
	assert(to >= 0);
	assert(from < nfa->num_states);
	assert(to < nfa->num_states);
	
	/* Add this transition */
	add_transition(nfa, nfa->states + from, nfa->states + to, token_start, token_end);
	
	/* This is not a DFA any more */
	nfa->is_dfa = 0;
}

/* Retrieves a pointer to the current NDFA state */
ndfa_pointer ndfa_get_pointer(ndfa nfa) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);

	/* Return the compile state */
	return nfa->compile_state;
}

/* Sets the current state using a pointer retrieved using get_pointer */
void ndfa_set_pointer(ndfa nfa, ndfa_pointer to) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	
	assert(to >= 0);
	assert(to < nfa->num_states);	
	
	nfa->compile_state = to;
}

/* Adds some data to a specific state */
static void add_data(ndfa nfa, void* data, ndfa_pointer state) {
	/* Do nothing if this is no data */
	if (data == NULL) return;
	
	/* Add a new data pointer to the specified state */
	nfa->states[state].num_data++;
	nfa->states[state].data_pointers = realloc(nfa->states[state].data_pointers, sizeof(void*)*nfa->states[state].num_data);
	nfa->states[state].data_pointers[nfa->states[state].num_data-1] = data;
	
	/* Also add data to any linked states */
	if (nfa->states[nfa->compile_state].shared_state != 0xffffffff) {
		int shared_state = nfa->states[nfa->compile_state].shared_state;
		nfa->states[nfa->compile_state].shared_state = 0xffffffff;
		
		add_data(nfa, data, shared_state);
		
		nfa->states[nfa->compile_state].shared_state = shared_state;
	}	
}

/* Adds some data for the current state (makes it accepting if non-null). */ 
/* Note that a state may have more than one piece of data associated with it */
void ndfa_add_data(ndfa nfa, void* data) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);

	add_data(nfa, data, nfa->compile_state);
}

/* Adds a note for the current state (doesn't make it accepting but can still be retrieved later) */
void ndfa_add_note(ndfa nfa, void* note) {
	#warning TODO: add notes
}

/* Pushes the current state onto a stack */
void ndfa_push(ndfa nfa) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	
	/* Increase the total stack if necessary */
	if (nfa->stack_length >= nfa->stack_total) {
		int last_total = nfa->stack_total;
		
		if (nfa->stack_total == 0) nfa->stack_total = 4;
		nfa->stack_total *= 2;
		nfa->state_stack = realloc(nfa->state_stack, sizeof(int) * nfa->stack_total);
		nfa->stack_joins = realloc(nfa->stack_joins, sizeof(ndfa_join_stack*) * nfa->stack_total);
		
		assert(nfa->state_stack != NULL);
		assert(nfa->stack_joins != NULL);
		
		int x;
		for (x=last_total; x<nfa->stack_total; x++) {
			nfa->stack_joins[x] = NULL;
		}
	}
	
	/* Reset the join stack if it exists */
	if (nfa->stack_joins[nfa->stack_length]) {
		nfa->stack_joins[nfa->stack_length]->num_states = 0;
	}
	
	/* Store the current state on the stack */
	nfa->state_stack[nfa->stack_length++] = nfa->compile_state;
}

/* Pops and discards the last state on the state stack */
void ndfa_pop(ndfa nfa) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	assert(nfa->stack_length > 0);
	
	/* Discard the element on top of the stack */
	nfa->stack_length--;
}

/* Peeks at the value on top of the state stack */
ndfa_pointer ndfa_peek(ndfa nfa) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	assert(nfa->stack_length > 0);
	
	return nfa->state_stack[nfa->stack_length-1];
}

/* Sets the state on top of the stack as the current state (equivalent of an OR in a regexp) */
/* This also notes all of the parallel finishing states as it goes for later use with rejoin */
void ndfa_or(ndfa nfa) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	assert(nfa->stack_length > 0);
	
	/* Remember the current state in the join stack */
	ndfa_join_stack* joins;
	
	if (nfa->stack_joins[nfa->stack_length-1] != NULL) {
		joins = nfa->stack_joins[nfa->stack_length-1];
	} else {
		nfa->stack_joins[nfa->stack_length-1] = joins = malloc(sizeof(ndfa_join_stack));
		joins->num_states	= 0;
		joins->states 		= NULL;
	}
	
	joins->num_states++;
	joins->states = realloc(joins->states, sizeof(int)*joins->num_states);
	joins->states[joins->num_states-1] = nfa->compile_state;
	
	/* Move the compile state */
	nfa->compile_state = nfa->state_stack[nfa->stack_length-1];
	nfa->is_dfa = 0;
}

/* Joins all of the finishing states created after the most recent set of ndfa_or calls, giving them all a common finishing state */
/* Additionally, pops from the state stack */
void ndfa_rejoin(ndfa nfa) {
	int x;
	
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	assert(nfa->stack_length > 0);
	
	/* Remember the start state */
	int rejoin_from = nfa->state_stack[nfa->stack_length-1];
	
	/* Pop from the stack */
	nfa->stack_length--;
	
	/* Retrieve the current join stack */
	ndfa_join_stack* joins = nfa->stack_joins[nfa->stack_length];
	if (joins == NULL) return;
	if (joins->num_states == 0) return;
	
	/* Add the current compile state to the list of items in this state */
	joins->num_states++;
	joins->states = realloc(joins->states, sizeof(int)*joins->num_states);
	joins->states[joins->num_states-1] = nfa->compile_state;
	
	/* If the current compile state is the same as the start state, then try to pick another */
	if (nfa->compile_state == rejoin_from) {
		/* This is needed because otherwise any non-zero length branch will just get skipped */
		for (x=0; x<joins->num_states; x++) {
			if (joins->states[x] != rejoin_from) {
				nfa->compile_state = joins->states[x];
			}
		}
	}
	
	/* Check for any blank states */
	int blank_states = 0;
	for (x=0; x<joins->num_states; x++) {
		if (joins->states[x] == rejoin_from) {
			blank_states = 1;
		}
	}
	
	if (blank_states) {
		/* Some states have no transitions: remove them from the list */
		int num_nonblank_states = 0;
		unsigned int nonblank_states[joins->num_states];
		
		for (x=0; x<joins->num_states; x++) {
			if (joins->states[x] != rejoin_from) {
				nonblank_states[num_nonblank_states++] = joins->states[x];
			}
		}

		if (num_nonblank_states > 0) {
			/* Join all the states with transitions */
			ndfa_pointer final_state = ndfa_join(nfa, num_nonblank_states, nonblank_states);
			
			/* Share the final state */
			nfa->states[final_state].shared_state = rejoin_from;
		}
	} else {
		/* Join all the states */
		ndfa_join(nfa, joins->num_states, joins->states);
	}
}

/* Adds a transistion to the states after the state on top of the state stack (without popping, equivalent to a + in a regexp) */
/* Can be combined with or and/or add_data to give the equivalent of * */
void ndfa_repeat(ndfa nfa) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	assert(nfa->stack_length > 0);
	
	/* Get the state number we're repeating to */
	int repeat_to = nfa->state_stack[nfa->stack_length-1];
	
	/* Add looping transitions from here to all of the states after the repeating state */
	int x;
	for (x=0; x<nfa->states[repeat_to].num_transitions; x++) {
		/* Get information about this transition */
		ndfa_transit* transit = nfa->states[repeat_to].transitions + x;
		ndfa_state* from = nfa->states + nfa->compile_state;
		ndfa_state* to = nfa->states + transit->new_state;
				
		/* Add a new transition for this action */
		add_transition(nfa, from, to, transit->tokens.start, transit->tokens.end);
	}
	
	nfa->is_dfa = 0;
}

/* Information that can be used to copy from a particular state */
typedef struct ndfa_copy_state {
	/* Preparation */
	int		num_states;								/* Number of states stored here */
	int*	states;									/* Ordered list of states that will be copied */
	
	/* Most recent copy */
	int*	state_map;								/* Maps states in the state array to copied states */
} ndfa_copy_state;

/* Adds a new state to a copy state, and returns non-zero if it wasn't there before */
static __INLINE__ int add_copy_state(ndfa_copy_state* copy_state, int state) {
	/* Binary search for the existing state */
	int top = copy_state->num_states - 1;
	int bottom = 0;
	while (top >= bottom) {
		int middle = (top+bottom)>>1;
		
		if (copy_state->states[middle] > state) top = middle - 1;
		else if (copy_state->states[middle] < state) bottom = middle + 1;
		else return 0;
	}
	
	/* bottom is now the first location containing a state greater than the requested state */
	
	/* Allocate space for the new state */
	copy_state->states = realloc(copy_state->states, sizeof(int)*(copy_state->num_states+1));
	assert(copy_state->states != NULL);
	
	/* Place the new state into the array */
	memmove(copy_state->states + bottom + 1, copy_state->states + bottom, sizeof(int)*(copy_state->num_states - bottom));
	copy_state->num_states++;
	copy_state->states[bottom] = state;
	
	return 1;
}

/* Given a NDFA state, adds both the state and all of the states it can reach to the list of copy states */
static void process_copy_state(ndfa nfa, ndfa_copy_state* copy_state, int state) {
	/* Add the state, and give up if it's already there */
	if (!add_copy_state(copy_state, state)) return;
	
	/* Add each state that can be reached by a transition from here, and recursively process them */
	int x;
	for (x=0; x<nfa->states[state].num_transitions; x++) {
		process_copy_state(nfa, copy_state, nfa->states[state].transitions[x].new_state);
	}
}

/* Prepares to copy a part of a NDFA */
static ndfa_copy_state* create_copy_state(ndfa nfa, int start_state) {
	/* Allocate the result */
	ndfa_copy_state* result = malloc(sizeof(ndfa_copy_state));
	assert(result != NULL);
	
	/* Set the initial values */
	result->num_states	= 0;
	result->states		= NULL;
	result->state_map	= NULL;
	
	/* Process the start state */
	process_copy_state(nfa, result, start_state);
	
	/* All done */
	return result;
}

/* Frees up a copy state block */
static void free_copy_state(ndfa_copy_state* copy_state) {
	if (copy_state->states) 	free(copy_state->states);
	if (copy_state->state_map)	free(copy_state->state_map);
	free(copy_state);
}

/* Allocates new states for a copy */
static void allocate_copied_states(ndfa nfa, ndfa_copy_state* copy_state) {
	copy_state->state_map = realloc(copy_state->state_map, sizeof(int)*copy_state->num_states);
	assert(copy_state->state_map != NULL);
	
	int x;
	for (x=0; x<copy_state->num_states; x++) {
		copy_state->state_map[x] = create_state(nfa, NULL)->id;
	}
}

/* Finds the index into a copy state of a specific state */
static __INLINE__ int copy_state_index(ndfa_copy_state* copy_state, int original_state) {
	/* Binary search for the existing state */
	int top = copy_state->num_states - 1;
	int bottom = 0;
	while (top >= bottom) {
		int middle = (top+bottom)>>1;
		
		if (copy_state->states[middle] > original_state) top = middle - 1;
		else if (copy_state->states[middle] < original_state) bottom = middle + 1;
		else return middle;
	}
	
	return -1;	
}

/* Duplicates the transitions for a copy */
static void copy_transitions(ndfa nfa, ndfa_copy_state* copy_state) {
	assert(copy_state->state_map != NULL);
	
	int x;
	for (x=0; x<copy_state->num_states; x++) {
		/* Get the original state */
		int state = copy_state->states[x];
		
		/* Iterate through the transitions for this state */
		int y;
		for (y = 0; y < nfa->states[state].num_transitions; y++) {
			/* Work out where we're going from and where we're going to */
			ndfa_transit* transit	= nfa->states[state].transitions + y;
			int transit_to 			= transit->new_state;
			int transit_index 		= copy_state_index(copy_state, transit_to);
			assert(transit_index >= 0);
			int copy_transit_to		= copy_state->state_map[transit_index];
			
			/* Add a new transition */
			add_transition(nfa, nfa->states + copy_state->state_map[x], nfa->states + copy_transit_to, transit->tokens.start, transit->tokens.end);
		}
		
		/* Duplicate the shared state */
		if (nfa->states[state].shared_state != 0xffffffff) {
			int shared_index = copy_state_index(copy_state, nfa->states[state].shared_state);
			
			if (shared_index == -1) {
				nfa->states[state].shared_state = nfa->states[state].shared_state;
			} else {
				nfa->states[state].shared_state = copy_state->state_map[shared_index];
			}
		}
	}
}

/* Duplicates the data for a copy */
static void copy_data(ndfa nfa, ndfa_copy_state* copy_state) {
	assert(copy_state->state_map != NULL);

	int x;
	for (x = 0; x<copy_state->num_states; x++) {
		int original	= copy_state->states[x];
		int final		= copy_state->state_map[x];
		
		if (nfa->states[final].data_pointers != NULL) {
			free(nfa->states[final].data_pointers);
			nfa->states[final].data_pointers = NULL;
		}
		
		nfa->states[final].num_data			= nfa->states[original].num_data;
		nfa->states[final].data_pointers 	= malloc(sizeof(void*)*nfa->states[final].num_data);
		
		memcpy(nfa->states[final].data_pointers, nfa->states[original].data_pointers, sizeof(void*)*nfa->states[final].num_data);
	}
}

/* Copies all of the states following the specified state into a new, isolated, state machine and returns the pointer to it */
/* If non-null, anchor is updated to point to a where a specific state was copied to */
ndfa_pointer ndfa_copy(ndfa nfa, ndfa_pointer state, ndfa_pointer* anchor) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	
	assert(state >= 0);
	assert(state < nfa->num_states);
	
	assert(anchor == NULL || *anchor >= 0);
	assert(anchor == NULL || *anchor < nfa->num_states);
	
	/* Work out the states that can be reached from this point */
	ndfa_copy_state* copy_state = create_copy_state(nfa, state);
	
	/* Create a new state for each state that can be reached */
	allocate_copied_states(nfa, copy_state);
	
	/* Duplicate the transitions */
	copy_transitions(nfa, copy_state);
	
	/* Duplicate the data */
	copy_data(nfa, copy_state);
	
	/* Return the results */
	if (anchor) {
		int anchor_index = copy_state_index(copy_state, *anchor);
		assert(anchor_index >= 0);
		
		*anchor = copy_state->state_map[anchor_index];
	}
	
	int final_index = copy_state_index(copy_state, state);
	assert(final_index >= 0);
	int result = copy_state->state_map[final_index];
	
	free_copy_state(copy_state);
	
	nfa->is_dfa = 0;
	return result;
}

/* Takes the state machine after the first item on the stack to the current location and repeats it a given number of times */
void ndfa_repeat_number(ndfa nfa, int min_count, int max_count) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	assert(nfa->stack_length > 0);
	assert(max_count >= min_count);
	assert(min_count >= 0);

	int x;
	
	/* Start copying from the state on top of the stack */
	int copy_from = nfa->state_stack[nfa->stack_length-1];
	
	/* Create max_count copies of the state machine to here */
	/* Note that we can't immediately wire up the transitions as we'd also copy the last copy made, resulting in the counts being exponetial */
	unsigned int copy_start[max_count];
	unsigned int copy_finish[max_count];
	
	{
		ndfa_copy_state* copy_state = create_copy_state(nfa, copy_from);
	
		for (x=0; x<max_count; x++) {
			/* Create a copy of the state machine */
			allocate_copied_states(nfa, copy_state);
			copy_transitions(nfa, copy_state);
			copy_data(nfa, copy_state);

			/* Remember the start and end states */
			int start_index = copy_state_index(copy_state, copy_from);
			int end_index = copy_state_index(copy_state, nfa->compile_state);
		
			assert(start_index >= 0);
			assert(end_index >= 0);
		
			copy_start[x] 	= copy_state->state_map[start_index];
			copy_finish[x]	= copy_state->state_map[end_index];
		}
	
		free_copy_state(copy_state);
	}
	
	/* Wire up the transitions for the linear states */
	int transit_from = nfa->compile_state;
	for (x=0; x<max_count; x++) {
		/* Transit from transit_from to every state after copy_start */
		ndfa_state* start_state = nfa->states + copy_start[x];
		
		int y;
		for (y=0; y<start_state->num_transitions; y++) {
			add_transition(nfa, nfa->states + transit_from, nfa->states + start_state->transitions[y].new_state, start_state->transitions[y].tokens.start, start_state->transitions[y].tokens.end);
		}
		
		/* Transit_from now becomes the last state of this copy */
		transit_from = copy_finish[x];
	}
	
	/* The current state should move on to the final state in the list */
	nfa->compile_state = copy_finish[max_count - 1];
	
	/* Join up any states between min_count and max_count */
	if (min_count < max_count) {
		ndfa_join(nfa, max_count - min_count, copy_finish + min_count);
	}
	
	nfa->is_dfa = 0;
}

static int compare_state_pointers(const void* a, const void* b) {
	const ndfa_pointer* ap = a;
	const ndfa_pointer* bp = b;
	
	if (*ap > *bp) return 1;
	else if (*ap < *bp) return -1;
	else return 0;
}

/* Given a list of states, joins them together into a single 'final' state */
ndfa_pointer ndfa_join(ndfa nfa, int num_states, const ndfa_pointer* state) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	assert(num_states > 0);
	
	/* Create the 'joined' final state */
	int final_state = state[0];
	int set_compile_state = 0;
	
	/* Sort the states into order */
	ndfa_pointer sorted_states[num_states];
	memcpy(sorted_states, state, sizeof(ndfa_pointer)*num_states);
	qsort(sorted_states, num_states, sizeof(ndfa_pointer), compare_state_pointers);
	
	/* All transitions that go to any of the states in the array need to be remapped to go to our final transition */
	int x;
#if FAST_JOINS
	for (x=0; x<num_states; x++) {
		assert(state[x] >= 0);
		assert(state[x] < nfa->num_states);

		int y;
		ndfa_state* state_to = nfa->states + state[x];
		
		assert(nfa->states[state[x]].shared_state == 0xffffffff);
		
		for (y=0; y<state_to->num_sources; y++) {
			int z;
			ndfa_state* state_from = nfa->states + state_to->sources[y];
			
			for (z=0; z<state_from->num_transitions; z++) {
				ndfa_pointer dest_state = state_from->transitions[y].new_state;

				if (bsearch(&dest_state, sorted_states, num_states, sizeof(ndfa_pointer), compare_state_pointers)) {
					state_from->transitions[z].new_state = final_state;
				}				
			}
		}
	}
#else
	for (x=0; x<nfa->num_states; x++) {
		int y;
		ndfa_state* this_state = nfa->states + x;

		assert(nfa->states[state[x]].shared_state == 0xffffffff);
		
		for (y=0; y<this_state->num_transitions; y++) {
			ndfa_pointer dest_state = this_state->transitions[y].new_state;
			
			if (bsearch(&dest_state, sorted_states, num_states, sizeof(ndfa_pointer), compare_state_pointers)) {
				this_state->transitions[y].new_state = final_state;
			}
		}
	}
#endif
	
	/* Any references in the join stack need to be changed to go to our final state instead */
	for (x=0; x<nfa->stack_length; x++) {
		ndfa_join_stack* join = nfa->stack_joins[x];
		if (join == NULL) continue;
		if (join->num_states == 0) continue;
		
		int y;
		for (y=0; y<join->num_states; y++) {
			if (bsearch(&join->states[y], sorted_states, num_states, sizeof(ndfa_pointer), compare_state_pointers)) {
				join->states[y] = final_state;
			}
		}
	}
	
	/* Add transitions from the final state to any states reachable from the original states */
	ndfa_state* final = nfa->states + final_state;
	for (x=1; x<num_states; x++) {						/* Note that because we make the first state in the array the 'final' state, we don't add any transitions from there */
		if (state[x] == nfa->compile_state) set_compile_state = 1;
		
		ndfa_state* this_state = nfa->states + state[x];
		int y;
		
		for (y=0; y<this_state->num_transitions; y++) {
			ndfa_transit* transit = this_state->transitions + y;
			add_transition(nfa, final, nfa->states + transit->new_state, transit->tokens.start, transit->tokens.end);
		}
	}
	
	/* Join up the data for all of the states */
	for (x=1; x<num_states; x++) {
		int y;
		ndfa_state* this_state = nfa->states + state[x];
		
		for (y=0; y<this_state->num_data; y++) {
			add_data(nfa, this_state->data_pointers[y], final_state);
		}
	}
	
	/* Return the result */
	nfa->is_dfa = 0;
	if (set_compile_state) nfa->compile_state = final_state;
	return final_state;
}

/* ===============
 * Compiling NDFAs
 */

/* Structure representing a combined list of states */
typedef struct compound_state {
	int num_states;							/* Number of states in this compound state */
	int dfa;								/* The index of this state in the DFA (or -1 if not yet created) */
	int states[1];							/* The states making up this compound state */
} compound_state;

/* Cache of the known compound states */
typedef struct compound_state_cache {
	int num_states;							/* Number of compound states in this cache */
	int total_states;						/* Total available states in the array */
	compound_state** states;				/* Ordered list of compound states in the cache */
} compound_state_cache;

/* Creates a 'compound' state, given an ordered list of state indexes */
static __INLINE__ compound_state* create_compound_state(int num_states, int* states) {
	compound_state* new_state = malloc(sizeof(compound_state) + sizeof(int)*num_states);
	
	new_state->num_states	= num_states;
	new_state->dfa			= -1;

	memcpy(new_state->states, states, sizeof(int)*num_states);
	
	return new_state;
}

static __INLINE__ int compare_compound_state(compound_state* a, int num_states, int* states) {
	if (a->num_states > num_states) return 1;
	else if (a->num_states < num_states) return -1;
	else {
		int x;
		for (x=0; x<num_states; x++) {
			if (a->states[x] > states[x]) return 1;
			else if (a->states[x] < states[x]) return -1;
		}
	}
	
	return 0;
}

/* Constructs a new compound state cache */
static compound_state_cache* create_compound_cache() {
	compound_state_cache* new_cache = malloc(sizeof(compound_state_cache));
	
	new_cache->num_states		= 0;
	new_cache->total_states		= 0;
	new_cache->states			= NULL;
	
	return new_cache;
}

/* Finds or creates compound state in a cache */
static __INLINE__ compound_state* find_compound_state(compound_state_cache* cache, int num_states, int* states) {
	/* Perform a binary search to find an existing compound state */
	int bottom = 0;
	int top = cache->num_states-1;
	
	while (top >= bottom) {
		int middle = (top+bottom)>>1;
		int compare = compare_compound_state(cache->states[middle], num_states, states);
		
		if (compare == 0) return cache->states[middle];
		
		if (compare < 0) bottom = middle + 1;
		else top = middle - 1;
	}
	
	/* Couldn't find this state already, so create a new one */
	compound_state* new_state = create_compound_state(num_states, states);
	
	/* bottom now indicates the first state that is greater than this one */
	cache->num_states++;
	if (cache->num_states >= cache->total_states) {
		cache->total_states += NDFA_GROW;
		cache->states = realloc(cache->states, cache->total_states*sizeof(compound_state*));
		
		assert(cache->states != NULL);
	}
	
	assert(bottom < cache->num_states);
	
	if (bottom < cache->num_states-1) {
		/* Make room for the new state */
		memmove(cache->states + bottom + 1, cache->states + bottom, sizeof(compound_state*)*(cache->num_states-bottom-1));
	}
	
	/* Store the new state */
	cache->states[bottom] = new_state;
	
	/* Return the result */
	return new_state;
}

/* Compares the tokens in two transitions */
static int compare_transitions(const void* a, const void* b) {
	const ndfa_transit* tr1 = a;
	const ndfa_transit* tr2 = b;
	
	if (tr1->tokens.start > tr2->tokens.start) return 1;			/* Sort by start token order */
	else if (tr2->tokens.start > tr1->tokens.start) return -1;
	else if (tr1->tokens.end > tr2->tokens.end) return -1;			/* Ensure longer ranges come before shorter ranges*/
	else if (tr2->tokens.end > tr1->tokens.end) return 1;
	else {
		if (tr1->new_state > tr2->new_state) return 1;
		else if (tr2->new_state > tr1->new_state) return -1;
		else return 0;
	}
}

/* Recursively compiles a compound state into a state in the DFA */
static void compile_state(compound_state* state, ndfa dfa, ndfa nfa, compound_state_cache* cache) {
	int x;
	
	/* If this state doesn't already have a DFA state associated with it, then create one */
	if (state->dfa == -1) {
		state->dfa = create_state(dfa, NULL)->id;

		/* Merge any data associated with this state */
		for (x=0; x<state->num_states; x++) {
			int y;
			
			printf("%i ", state->states[x]);
			
			for (y=0; y<nfa->states[state->states[x]].num_data; y++) {
				add_data(dfa, nfa->states[state->states[x]].data_pointers[y], state->dfa);
			}
		}
		
		printf(" -> %i\n", state->dfa);
	}
	
	/* Clear out the list of transitions associated with this state */
	ndfa_state* dfa_state = dfa->states + state->dfa;
	dfa_state->num_transitions = 0;
	
	/* Construct a list of all the transitions from the compound state */
	int num_transitions = 0;
	for (x=0; x<state->num_states; x++) {
		num_transitions += nfa->states[state->states[x]].num_transitions;
	}
	
	ndfa_transit* transitions = malloc(sizeof(ndfa_transit)*num_transitions);
	int pos = 0;
	for (x=0; x<state->num_states; x++) {
		ndfa_state* nfa_state = nfa->states + state->states[x];
		
		memcpy(transitions + pos, nfa_state->transitions, sizeof(ndfa_transit)*nfa_state->num_transitions);
		pos += nfa_state->num_transitions;
	}
	
	/* Sort into token/state order */
	qsort(transitions, num_transitions, sizeof(ndfa_transit), compare_transitions);
	
	/* Split overlapping ranges */
	int have_split = 0;
	for (x=0; x < num_transitions-1; x++) {
		ndfa_transit* this_transit = transitions + x;
		ndfa_transit* next_transit = transitions + x + 1;
		
		if (this_transit->tokens.start < next_transit->tokens.start 
			&& this_transit->tokens.end > next_transit->tokens.start) {
			ndfa_transit next_copy = *next_transit;
			ndfa_transit this_copy = *this_transit;
			int y;

			/* this_transit overlaps next_transit - split it in two */
			ndfa_transit new_transit;
			
			new_transit.tokens.start	= next_transit->tokens.start;
			new_transit.tokens.end		= this_transit->tokens.end;
			new_transit.new_state		= 0;

			/* Work out where to add the new transition */
			have_split = 1;
			int insert_pos = x+1;
			while (insert_pos < num_transitions && compare_transitions(transitions + insert_pos, &new_transit) < 0) {
				insert_pos++;
			}

			/* We might also need to split a number of transitions preceeding this one*/
			have_split = 1;
			for (y=x; y>=0 
				 && transitions[y].tokens.start == this_copy.tokens.start
				 && transitions[y].tokens.end == this_copy.tokens.end;
				 y--) {
				/* Split this transition */
				new_transit.new_state		= transitions[y].new_state;
				
				transitions[y].tokens.end	= next_copy.tokens.start;
				
				/* Allocate space for the new transition */
				transitions = realloc(transitions, sizeof(ndfa_transit)*(num_transitions+1));
				memmove(transitions + insert_pos+1, transitions + insert_pos, sizeof(ndfa_transit)*(num_transitions-insert_pos));
				num_transitions++;
				
				transitions[insert_pos] = new_transit;
			}
			continue;
		} else if (this_transit->tokens.start == next_transit->tokens.start 
				   && this_transit->tokens.end > next_transit->tokens.end) {
			/* The end of this transition (and maybe some of the preceeding transitions) overlaps the following transition */
			int y;
			ndfa_transit next_copy = *next_transit;

			/* Work out the new transition */
			ndfa_transit new_transit;
			
			new_transit.tokens.start	= next_copy.tokens.end;
			new_transit.tokens.end		= transitions[x].tokens.end;
			new_transit.new_state		= 0;
			
			/* Work out where to add the new transition */
			have_split = 1;
			int insert_pos = x+2;
			while (insert_pos < num_transitions && compare_transitions(transitions + insert_pos, &new_transit) < 0) {
				insert_pos++;
			}
			
			for (y=x; y>=0 
				 && transitions[y].tokens.start == next_copy.tokens.start
				 && transitions[y].tokens.end > next_copy.tokens.end;
				 y--) {
				/* Split this transition */
				new_transit.new_state		= transitions[y].new_state;
				
				transitions[y].tokens.end	= next_copy.tokens.end;
				
				/* Allocate space for the new transition */
				transitions = realloc(transitions, sizeof(ndfa_transit)*(num_transitions+1));
				memmove(transitions + insert_pos+1, transitions + insert_pos, sizeof(ndfa_transit)*(num_transitions-insert_pos));
				num_transitions++;
				
				transitions[insert_pos] = new_transit;
			}
		}
	}
	
	/* Resort if we've split any transitions */
	if (have_split)
	{
		qsort(transitions, num_transitions, sizeof(ndfa_transit), compare_transitions);
	}

	int nfa_states[num_transitions];

	/* Iterate through the transitions */
	for (x = 0; x < num_transitions;) {
		int num_states = 0;
		
		/* Get the tokens for the new compound state */
		ndfa_token_range this_token = transitions[x].tokens;
		nfa_states[num_states++] = transitions[x].new_state;
		
		/* Work out all of the states that are reached by this token */
		x++;
		for (; x < num_transitions && transitions[x].tokens.start == this_token.start; x++) {
			if (nfa_states[num_states-1] != transitions[x].new_state) {
				nfa_states[num_states++] = transitions[x].new_state;
			}
		}
		
		/* Find or create the compound state for this transition */
		compound_state* transition_state = find_compound_state(cache, num_states, nfa_states);
		
		/* Compile it if it has no associated state in the DFA yet */
		if (transition_state->dfa == -1) {
			compile_state(transition_state, dfa, nfa, cache);
		}
		
		/* Add a transition to the DFA */
		dfa_state = dfa->states + state->dfa;
		add_transition(dfa, dfa_state, dfa->states + transition_state->dfa, this_token.start, this_token.end);
	}
	
	/* Done with the transitions */
	free(transitions);
}

/* Compiles an NDFA into a DFA */
ndfa ndfa_compile(ndfa nfa) {
	int x;
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
		
	/* Construct a ndfa to compile the DFA into */
	ndfa dfa = ndfa_create();
	
	/* Build a cache of the compound states that will make up the DFA */
	compound_state_cache* cache = create_compound_cache();
	
	/* Create the start state as a compound state */
	int start_state_list[1];
	start_state_list[0] = 0;
	
	compound_state* start_state = find_compound_state(cache, 1, start_state_list);
	start_state->dfa = 0;
	
	/* Compile the start state */
	compile_state(start_state, dfa, nfa, cache);
	
	/* Free the list of compound states */
	for (x=0; x<cache->num_states; x++) {
		free(cache->states[x]);
	}
	free(cache->states);
	free(cache);
	
	/* Return the result */
	dfa->is_dfa = 1;
	return dfa;
}

/* ===============
 * Querying NDFAs
 */

/* Returns the data blocks associated with a particular state */
void** ndfa_data_for_state(ndfa nfa, ndfa_pointer state, int* count) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	assert(state >= 0);
	assert(state < nfa->num_states);
	
	if (count) *count = nfa->states[state].num_data;
	return nfa->states[state].data_pointers;
}

/* =============
 * Running NDFAs
 */

#define NDFA_RUN_MAGIC (0xdfa0f00d)

typedef struct ndfa_handler {
	ndfa_input_handler accept;
	ndfa_input_handler reject;
	void* context;
} ndfa_handler;

struct ndfa_run_state {
	unsigned int magic;						/* Magic number */
	
	int needs_freeing;						/* 1 if the dfa associated with this state needs freeing */
	ndfa dfa;								/* The compiled DFA */
	
	ndfa_token* backtrack;					/* The backtracking/matching circular buffer */
	int bt_start;							/* Start token in the backtrack buffer */
	int bt_current;							/* Current token in the backtrack buffer */
	int bt_len;								/* Number of tokens currently in the backtrack buffer */
	int bt_total;							/* Total tokens available in the backtrack buffer */
	
	int bt_accept;							/* Position in the backtrack buffer of the last accepting state */
	int bt_accept_state;					/* Accepting state in the backtracking buffer */
	int bt_accept_length;					/* Number of characters from the start of the backtrack buffer to put into the 'last accepted' buffer */
	
	ndfa_token* lastbuffer;					/* Buffer of characters last returned by ndfa_last_input() */
	
	int state;								/* Current state in the DFA */
	
	int num_handlers;						/* Number of handles associated with this run state */
	ndfa_handler* handlers;					/* Handlers that deal with accept/reject events */
};

/* Initialises a ndfa, ready to run */
ndfa_run_state ndfa_start(ndfa dfa) {
	/* Allocate the new state */
	ndfa_run_state new_state = malloc(sizeof(struct ndfa_run_state));
	
	/* If dfa isn't a compiled DFA then compile it (SLOW) */
	if (dfa->is_dfa) {
		new_state->needs_freeing	= 0;
		new_state->dfa				= dfa;
	} else {
		new_state->needs_freeing	= 1;
		new_state->dfa				= ndfa_compile(dfa);
	}
	
	/* Create an initial backtrack buffer of 32 characters */
	new_state->bt_len			= 0;
	new_state->bt_total			= 32;
	new_state->bt_start			= 0;
	new_state->bt_current		= 0;
	new_state->bt_accept		= 0;
	new_state->bt_accept_state	= -1;
	new_state->backtrack		= malloc(sizeof(ndfa_token)*new_state->bt_total);

	/* There are initially 0 handlers */
	new_state->num_handlers		= 0;
	new_state->handlers			= NULL;
	
	/* Normally we don't supply a buffer of previous characters */
	new_state->lastbuffer		= NULL;
	
	/* Set the initial state to be the start state */
	new_state->state			= dfa->start;
	
	/* Abracadabra */
	new_state->magic			= NDFA_RUN_MAGIC;
	return new_state;
}

/* Given a state and a token, returns the state that should be transitioned to */
static __INLINE__ int transit_for_state(ndfa_state* state, ndfa_token token) {
	int bottom = 0;
	int top = state->num_transitions-1;
	
	while (top >= bottom) {
		int middle = (bottom + top)>>1;
		
		if (state->transitions[middle].tokens.start > token) top = middle - 1;
		else if (state->transitions[middle].tokens.end <= token) bottom = middle + 1;
		else return state->transitions[middle].new_state;
	}
	
	return -1;
}

static void grow_backtrack_buffer(ndfa_run_state state) {
	/* Allocate a new backtracking buffer */
	int new_total = state->bt_total*2;
	ndfa_token* new_backtrack = malloc(sizeof(ndfa_token)*new_total);
	
	/* Copy in the characters from the old buffer */
	if (state->bt_current > state->bt_start) {
		memcpy(new_backtrack, state->backtrack + state->bt_start, sizeof(ndfa_token)*(state->bt_current-state->bt_start));
		
		state->bt_current -= state->bt_start;
		state->bt_accept -= state->bt_start;
		state->bt_start = 0;
	} else {
		int num_to_end = state->bt_total - state->bt_start;
		memcpy(new_backtrack, state->backtrack + state->bt_start, sizeof(ndfa_token)*(num_to_end));
		memcpy(new_backtrack + num_to_end, state->backtrack, sizeof(ndfa_token)*(state->bt_current));
		
		state->bt_current += num_to_end;
		state->bt_accept += num_to_end;
		if (state->bt_accept >= state->bt_total) state->bt_accept -= state->bt_total;
		state->bt_start = 0;
	}
	
	/* Free the old buffer */
	free(state->backtrack);
	state->backtrack = new_backtrack;	
}

/* Accepts the specified number of characters */
static __INLINE__ void accept(ndfa_run_state state, int accept_state, int length) {
	int x;
	state->bt_accept_length = length;
	
	for (x=0; x<state->num_handlers; x++) {
		if (state->handlers[x].accept) {
			state->handlers[x].accept(state, length, 1, state->handlers[x].context);
		}
	}
}

/* Rejects the specified number of characters */
static __INLINE__ void reject(ndfa_run_state state, int length) {
	int x;
	state->bt_accept_length = length;
	
	if (state->bt_len == 0) return;
	
	for (x=0; x<state->num_handlers; x++) {
		if (state->handlers[x].reject) {
			state->handlers[x].reject(state, length, NDFA_REJECT, state->handlers[x].context);
		}
	}
}

/* Sends a token to a running DFA */
void ndfa_run(ndfa_run_state state, ndfa_token token) {
	assert(state->magic == NDFA_RUN_MAGIC);
	
	/* Store this token in the backtrack buffer */
	if (token <= 0x7fffffff) {
		state->backtrack[state->bt_current++] = token;
		if (state->bt_current >= state->bt_total) state->bt_current = 0;
		state->bt_len++;
		
		/* Grow the buffer if needed */
		if (state->bt_len >= state->bt_total) {
			grow_backtrack_buffer(state);
		}
	}
	
retry:;
	/* Fetch the current DFA state */
	ndfa_state* dfastate = state->dfa->states + state->state;

	/* Work out the transition for this character */
	int next_state = transit_for_state(dfastate, token);
	
	if (next_state >= 0) {
		/* +++=== Move to the next state ===+++ */
		state->state = next_state;
		
		dfastate = state->dfa->states + next_state;
		if (dfastate->num_data > 0) {
			/* The next state is an accepting state */
			if (dfastate->num_transitions == 0) {
				/* This is an accepting state */
				accept(state, next_state, state->bt_len);
				
				/* Clear the backtracking buffer */
				state->bt_len = 0;
				state->bt_start = state->bt_current = 0;
				state->bt_accept_state = -1;
				state->state = state->dfa->start;
			} else {
				/* Record this as the last known accepting state */
				state->bt_accept = state->bt_current;
				state->bt_accept_state = next_state;
			}
		}
	} else {
		/* +++=== Can't proceed: we've reached a rejecting state ===+++ */
		if (dfastate->num_data > 0) {
			/* All but one character has accepted */
			
			/* Accept all but the last character in the backtracking buffer */
			accept(state, dfastate->id, state->bt_len-1);
			
			/* Clear the backtracking buffer and retry the token */
			if (token <= 0x7fffffff) {
				state->bt_len = 1;
				state->bt_start = state->bt_current = 0;
				state->bt_accept_state = -1;
	 			state->state = state->dfa->start;
			
				state->backtrack[state->bt_current++] = token;
			} else {
				state->bt_len = 0;
				state->bt_start = state->bt_current = 0;
				state->bt_accept_state = -1;
	 			state->state = state->dfa->start;
			}
			goto retry;
		} else {
			if (state->bt_accept_state >= 0) {
				/* There's an accepting state we can backtrack to */
				int num_accepted = state->bt_accept - state->bt_start;
				if (num_accepted < 0) num_accepted += state->bt_total;
				
				accept(state, state->bt_accept_state, num_accepted);
				
				/* Backtrack */
				state->bt_start = state->bt_accept;
				state->bt_len -= num_accepted;
				state->bt_accept_state = -1;
			} else if (state->bt_len > 0) {
				/* Reject the first character in the backtracking buffer */
				reject(state, 1);
				state->bt_start++;
				state->bt_len--;
				if (state->bt_start >= state->bt_total) state->bt_start = 0;
			}
			
			/* Run the state machine over the backtracked buffer */
			int pos = state->bt_start;
			int backtracked = pos != state->bt_current;
			dfastate = state->dfa->states + state->dfa->start;
			while (pos != state->bt_current) {
				/* Get the transition for this state */
				next_state = transit_for_state(dfastate, state->backtrack[pos]);
				
				if (next_state >= 0) {
					/* +++=== Transition to the next state ===+++ */
					dfastate = state->dfa->states + next_state;
					
					if (dfastate->num_data > 0) {
						/* Record this as an accepting state */
						state->bt_accept = pos;
						state->bt_accept_state = next_state;
					}
				} else {
					if (state->bt_accept_state >= 0) {
						/* +++=== Accept everything up to bt_accept ===+++ */
						int num_accepted = state->bt_accept - state->bt_start;
						if (num_accepted < 0) num_accepted += state->bt_total;

						accept(state, state->bt_accept_state, num_accepted);
						
						/* Backtrack to bt_accept */
						pos = state->bt_accept;
						
						state->bt_start = state->bt_accept;
						state->bt_len -= num_accepted;
						state->bt_accept_state = -1;
					} else if (state->bt_len > 0) {
						/* +++=== Reject the first character in the backtracking buffer ===+++ */
						reject(state, 1);
						state->bt_start++;
						state->bt_len--;
						if (state->bt_start >= state->bt_total) state->bt_start = 0;
						pos = state->bt_start-1;
					}
					
					/* Reset */
					dfastate = state->dfa->states + state->dfa->start;
				}
				
				/* Next character */
				pos++;
				if (pos >= state->bt_total) pos = 0;
			}
			
			/* All up to date now */
			state->state = dfastate->id;
			
			/* Retry any special tokens */
			if (token > 0x7fffffff && backtracked) {
				goto retry;
			}
		}
	}
}

/* Registers a pair of handlers for a DFA */
void ndfa_add_handlers(ndfa_run_state state, ndfa_input_handler accept, ndfa_input_handler reject, void* context) {
	assert(state->magic == NDFA_RUN_MAGIC);
	
	/* Allocate a new handler */
	state->num_handlers++;
	state->handlers = realloc(state->handlers, sizeof(ndfa_handler)*(state->num_handlers));
	ndfa_handler* new_handler = state->handlers + state->num_handlers-1;
	
	/* Fill it in */
	new_handler->accept		= accept;
	new_handler->reject		= reject;
	new_handler->context	= context;
}

/* Retrieves the input most recently rejected/accepted by the DFA (note that less memory is used if this is not called) */
ndfa_token* ndfa_last_input(ndfa_run_state state) {
	assert(state->magic == NDFA_RUN_MAGIC);
	assert(state->bt_accept_length >= 0 && state->bt_accept_length <= state->bt_len);

	state->lastbuffer = realloc(state->lastbuffer, sizeof(ndfa_token)*state->bt_accept_length);
	
	/* Copy the start of the buffer */
	int num_to_copy = state->bt_accept_length;
	if (state->bt_start + num_to_copy > state->bt_total) {
		num_to_copy = state->bt_total - state->bt_start;
	}
	memcpy(state->lastbuffer, state->backtrack + state->bt_start, sizeof(ndfa_token)*num_to_copy);
	
	/* Copy the remainder of the buffer (if any) */
	if (num_to_copy < state->bt_accept_length) {
		memcpy(state->lastbuffer + num_to_copy, state->backtrack, sizeof(ndfa_token)*(state->bt_accept_length - num_to_copy));
	}
	
	/* lastbuffer now contains the result */
	return state->lastbuffer;
}

/* Finalises a running DFA */
void ndfa_finish(ndfa_run_state state) {
	assert(state->magic == NDFA_RUN_MAGIC);
	
	state->magic = 0;
	if (state->handlers)	free(state->handlers);
	if (state->lastbuffer)	free(state->lastbuffer);
	free(state->backtrack);
	free(state);
}
