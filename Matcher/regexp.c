/*
 *  regexp.c
 *  Inform-xc2
 *
 *  Created by Andrew Hunter on 15/06/2007.
 *  Copyright 2007 Andrew Hunter. All rights reserved.
 *
 */

/*
 * Routines for building regular expressions into ndfas
 */

#include <stdlib.h>
#include <string.h>

#include "ndfa.h"


/* =============================
 * Compiling regular expressions
 */

/* Compiles a UCS-4 regexp into a ndfa */
int ndfa_compile_regexp_ucs4(ndfa nfa, const ndfa_token* regexp, void* data) {
	int was_successful = 1;
	int bracket_stack = 0;
	ndfa_pointer recent_state;		/* State to go back to for ?, *, etc */
	
	/* Create an initial state for this regexp */
	ndfa_pointer original_state = ndfa_get_pointer(nfa);
	ndfa_pointer start_state = ndfa_create_state(nfa);
	
	ndfa_set_pointer(nfa, start_state);
	
	/* Run through the regular expression */
	int x;
	int this_state;
	ndfa_push(nfa);
	for (x=0; regexp[x] != 0; x++) {
		/* Perform actions depending on the character we encounter */
		switch (regexp[x]) {
			case '(':
				/* Start a new bracketed list */
				ndfa_push(nfa);
				bracket_stack++;
				break;
				
			case ')':
				if (bracket_stack <= 0) {
					/* Mismatched bracket */
					was_successful = 0;
					goto failed;
				}
				
				/* Finish this bracketed list */
				recent_state = ndfa_peek(nfa);
				ndfa_pop(nfa);
				bracket_stack--;
				break;
				
			case '+':
				/* Repeat from recent_state */
				this_state = ndfa_get_pointer(nfa);
				ndfa_set_pointer(nfa, recent_state);
				ndfa_push(nfa);
				ndfa_set_pointer(nfa, this_state);
				ndfa_repeat(nfa);
				ndfa_pop(nfa);
				break;
			
			default:
				/* Just add this chararcter to the nfa */
				recent_state = ndfa_peek(nfa);
				ndfa_transition(nfa, regexp[x], NULL);
				break;
		}
	}
	
	/* Join the initial state with the original state */
	ndfa_pointer join_states[2];
	join_states[0] = original_state;
	join_states[1] = start_state;
	ndfa_join(nfa, 2, join_states);
	
	/* Report success */
failed:;
	return was_successful;
}

/* Compiles an ASCII regexp into a ndfa */
int ndfa_compile_regexp(ndfa nfa, const char* regexp, void* data) {
	/* Convert the regexp to UCS-4 */
	int len = strlen((const char*)regexp);
	int x;
	ndfa_token* ucs4 = malloc(sizeof(ndfa_token)*(len+1));
	
	for (x=0; regexp[x] != 0; x++) {
		ucs4[x] = (unsigned char)regexp[x];
	}
	ucs4[x] = 0;
	
	/* Compile it */
	int result = ndfa_compile_regexp_ucs4(nfa, ucs4, data);
	free(ucs4);
	
	return result;
}
