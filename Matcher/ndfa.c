/*
 *  ndfa.c
 *  Inform-xc2
 *
 *  Created by Andrew Hunter on 15/06/2007.
 *  Copyright 2007 Andrew Hunter. All rights reserved.
 *
 */

/*
 * TODO: 'state' for the state in the running part is confusing with 'state' for an NDFA state
 */

#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "ndfa.h"

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
	/* NDFA information */
	unsigned int		id;					/* ID for this state */
	int					num_transitions;	/* Number of transitions from this state */
	int					total_transitions;	/* Total amount allocated for transitions from this state */
	ndfa_transit*		transitions;		/* Transitions associated with this state */
	void*				data;				/* Data if this state is accepted */
};

struct ndfa {
	unsigned int	magic;					/* Magic number indicating this is a valid NDFA */
	
	int				is_dfa;					/* non-zero if this is a compiled DFA that can actually be run */
	int				start;					/* The start state */
	int				compile_state;			/* The state from which the next transistion will be added*/
	
	int				num_states;				/* Number of used states in the states array */
	int				total_states;			/* Total number of states in this ndfa */
	ndfa_state*		states;					/* All the states associated with this ndfa */
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
		printf("\nState %i (%i transitions)%s:\n", state_num, state->num_transitions, state->data?" (accepting)":"");
		
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
static ndfa_state* create_state(ndfa nfa, void* data) {
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
	new_state->data					= data;
	
	/* Return the result */
	return new_state;
}

/* Adds a transition to the specified state */
static void add_transition(ndfa_state* from, ndfa_state* to, ndfa_token token_start, ndfa_token token_end) {
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
	
	/* Add a 'start' transition */
	add_transition(new_ndfa->states + new_ndfa->start, new_ndfa->states + new_ndfa->start, NDFA_START, NDFA_START+1);

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

/* Adds an inclusive range of tokens as a new transition */
void ndfa_transition_range(ndfa nfa, ndfa_token token_start, ndfa_token token_end, void* data) {
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	
	/* Construct a new state for this transition */
	ndfa_state* new_state = create_state(nfa, data);
	
	/* Add this transition */
	add_transition(nfa->states + nfa->compile_state, new_state, token_start, token_end+1);
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
	add_transition(nfa->states + nfa->compile_state, new_state, token, token+1);
	nfa->compile_state = new_state->id;
	
	/* This is not a DFA any more */
	nfa->is_dfa = 0;
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
static compound_state* create_compound_state(int num_states, int* states) {
	compound_state* new_state = malloc(sizeof(compound_state) + sizeof(int)*num_states);
	
	new_state->num_states	= num_states;
	new_state->dfa			= -1;

	memcpy(new_state->states, states, sizeof(int)*num_states);
	
	return new_state;
}

static int compare_compound_state(compound_state* a, int num_states, int* states) {
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
static compound_state* find_compound_state(compound_state_cache* cache, int num_states, int* states) {
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
#warning FIXME
		/* FIXME: do something with the data in the compound state */
		state->dfa = create_state(dfa, NULL)->id;

#warning FIXME MORE
		for (x=0; x<state->num_states; x++) {
			if (nfa->states[state->states[x]].data) {
				dfa->states[state->dfa].data = nfa->states[state->states[x]].data;
			}
		}
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
		add_transition(dfa_state, dfa->states + transition_state->dfa, this_token.start, this_token.end);
	}
}

/* Compiles an NDFA into a DFA */
ndfa ndfa_compile(ndfa nfa) {
	int x;
	assert(nfa != NULL);
	assert(nfa->magic == NDFA_MAGIC);
	
	/* Sort all of the transitions in the NDFA into order */
	/* 
	for (x=0; x<nfa->num_states; x++) {
		qsort(nfa->states[x].transitions, nfa->states[x].num_transitions, 
			  sizeof(ndfa_transit), compare_transitions);
	} */
	
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
static int transit_for_state(ndfa_state* state, ndfa_token token) {
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
static void accept(ndfa_run_state state, int accept_state, int length) {
	int x;
	void* data = state->dfa->states[accept_state].data;
	state->bt_accept_length = length;
	
	for (x=0; x<state->num_handlers; x++) {
		if (state->handlers[x].accept) {
			state->handlers[x].accept(state, length, data, state->handlers[x].context);
		}
	}
}

/* Rejects the specified number of characters */
static void reject(ndfa_run_state state, int length) {
	int x;
	state->bt_accept_length = length;
	
	for (x=0; x<state->num_handlers; x++) {
		if (state->handlers[x].reject) {
			state->handlers[x].reject(state, length, NULL, state->handlers[x].context);
		}
	}
}

/* Sends a token to a running DFA */
void ndfa_run(ndfa_run_state state, ndfa_token token) {
	assert(state->magic == NDFA_RUN_MAGIC);
	
	/* Store this token in the backtrack buffer */
	if (token < 0x7fffffff) {
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
		if (dfastate->data) {
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
		if (dfastate->data) {
			/* All but one character has accepted */
			
			/* Accept all but the last character in the backtracking buffer */
			accept(state, dfastate->id, state->bt_len-1);
			
			/* Clear the backtracking buffer and retry the token */
			state->bt_len = 1;
			state->bt_start = state->bt_current = 0;
			state->bt_accept_state = -1;
			state->state = state->dfa->start;
			
			state->backtrack[state->bt_current++] = token;
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
			dfastate = state->dfa->states + state->dfa->start;
			while (pos != state->bt_current) {
				/* Get the transition for this state */
				next_state = transit_for_state(dfastate, state->backtrack[pos]);
				
				if (next_state >= 0) {
					/* +++=== Transition to the next state ===+++ */
					dfastate = state->dfa->states + next_state;
					
					if (dfastate->data) {
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
