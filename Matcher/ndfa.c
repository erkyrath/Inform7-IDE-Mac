/*
 *  ndfa.c
 *  Inform-xc2
 *
 *  Created by Andrew Hunter on 15/06/2007.
 *  Copyright 2007 Andrew Hunter. All rights reserved.
 *
 */

#include <stdlib.h>
#include <assert.h>

#include "ndfa.h"

#define NDFA_GROW (32)						/* Amount to grow arrays by when allocating memory */

/* Data structures used to represent a DFA/NDFA */
#define NDFA_MAGIC (0x4dfa4dfa)				/* Magic number */

typedef struct ndfa_state ndfa_state;

typedef struct ndfa_transit {
	/* NDFA transition */
	ndfa_token	token;						/* The token which this transition moves on */
	ndfa_state*	new_state;					/* The state that is reached when this token is matched */
} ndfa_transit;

struct ndfa_state {
	/* NDFA information */
	unsigned int		id;					/* ID for this state */
	int					num_transitions;	/* Number of transitions from this state */
	int					total_transitions;	/* Total amount allocated for transitions from this state */
	ndfa_transit*		transitions;		/* Transitions associated with this state */
	void*				data;				/* Data if this state is accepted */
};

struct ndfa {
	unsigned int	magic;					/* Magic number indicating this is a valid NDFA */
	
	unsigned int	next_state_id;			/* Next ID for a new state for this NDFA */
	
	int				is_dfa;					/* non-zero if this is a compiled DFA that can actually be run */
	ndfa_state*		start;					/* The start state */
	ndfa_state*		compile_state;			/* The state from which the next transistion will be added*/
	
	int				num_states;				/* Number of used states in the states array */
	int				total_states;			/* Total number of states in this ndfa */
	ndfa_state*		states;					/* All the states associated with this ndfa */
};

/* ==============
 * Building NDFAs
 */

/* Creates a new NDFA state with the specified data and no transitions */
static ndfa_state* state_create(ndfa nfa, void* data) {
	/* Choose a state in the states array for this NDFA */
	int this_state = nfa->num_states++;
	
	/* Create more space if needed */
	if (nfa->num_states >= nfa->total_states) {
		nfa->total_states += NDFA_GROW;
		nfa->states = realloc(nfa->states, sizeof(ndfa_state)*nfa->total_states);
		
		assert(nfa->states != NULL);
	}
	
	/* Allocate a new state */
	ndfa_state* new_state = nfa->states + this_state;
	
	/* Populate it */
	new_state->id					= nfa->next_state_id++;
	new_state->num_transitions		= 0;
	new_state->total_transitions	= 0;
	new_state->transitions			= NULL;
	new_state->data					= data;
	
	/* Return the result */
	return new_state;
}

/* Adds a transition to the specified state */
static void add_transition(ndfa_state* from, ndfa_state* to, ndfa_token token) {
	/* Choose a location in the transition array for the new transition */
	int this_transition = from->num_transitions++;
	
	/* Grow the transitions array if necessary */
	if (from->num_transitions >= from->total_transitions) {
		from->total_transitions += NDFA_GROW;
		from->transitions = realloc(from->transitions, sizeof(ndfa_transit)*from->total_transitions);
		
		assert(from->transitions != NULL);
	}
	
	/* Allocate a new transition */
	ndfa_transit* new_transit = from->transitions + this_transition;
	
	new_transit->token		= token;
	new_transit->new_state	= to;
}

/* Creates a new NDFA, with a single start state */
ndfa ndfa_create() {
	/* Allocate a new NDFA */
	ndfa new_ndfa = malloc(sizeof(struct ndfa));
	assert(new_ndfa != NULL);
	
	/* Populate it with a single start state */
	new_ndfa->is_dfa		= 0;
	new_ndfa->next_state_id	= 0;
	new_ndfa->num_states	= 0;
	new_ndfa->total_states	= 0;
	new_ndfa->states		= NULL;
	new_ndfa->magic			= NDFA_MAGIC;
	
	new_ndfa->start			= state_create(new_ndfa, NULL);
	new_ndfa->compile_state	= new_ndfa->start; 

	/* Return it */
	return new_ndfa;
}

/* Releases the memory associated with an NDFA, with optional function to also free all of the data values */
void ndfa_free(ndfa nfa, ndfa_free_data free_data) {
	int x;

	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	
	/* Kill the magic */
	nfa->magic = 0;
	
	/* Free all of the state data */
	if (free_data) {
		for (x=0; x<nfa->num_states; x++) {
			free_data(nfa->states[x].data);
		}
	}
	
	/* Free all of the transitions */
	for (x=0; x<nfa->num_states; x++) {
		free(nfa->states[x].transitions);
	}
	
	/* Free up the nfa */
	free(nfa->states);
	free(nfa);
}

/* Resets the state to which we're adding NDFA transitions to be the start state */
void ndfa_reset(ndfa nfa) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	
	/* Reset the 'current' state back to the start */
	nfa->compile_state = nfa->start;
}

/* Adds a new single transition on receiving the given token, and moves the ndfa to that point */
/* Data should be non-null to indicate an accepting state. Note that the NDFA is greedy by default. */
void ndfa_transition(ndfa nfa, ndfa_token token, void* data) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	
	/* Construct a new state for this transition */
	ndfa_state* new_state = state_create(nfa, data);
	
	/* Add this transition */
	add_transition(nfa->compile_state, new_state, token);
}

/* ===============
 * Compiling NDFAs
 */

/* Compiles an NDFA into a DFA */
ndfa ndfa_compile(ndfa nfa) {
#warning TODO!
	return NULL;
}

/* =============
 * Running NDFAs
 */
