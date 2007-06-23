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

/* Given a character that follows a '\' returns the 'real' character to use */
static int quoted_char(int quoted) {
	switch (quoted)
	{
		case '0':
			return '\0';
		
		case 't':
			return '\t';
			
		case 'n':
			return '\n';
			
		case 'r':
			return '\r';
			
		case 'w':
			/* Special case: this is a set of characters */
			return ' ';
		
		default:
			/* Default is just the character that was quoted */
			return quoted;
	}
}

/* Compiles in the whitespace set into the nfa */
static void add_whitespace_set(ndfa nfa) {
	ndfa_push(nfa);
	
	/* Excludes NBSP characters */
	ndfa_transition(nfa, ' ', NULL); 
	ndfa_or(nfa);
	ndfa_transition_range(nfa, 0x9, 0xd, NULL); 		/* Unicode whitespace control characters */
	ndfa_or(nfa);
	ndfa_transition(nfa, 0x85, NULL);					/* NEL */
	ndfa_or(nfa);
	ndfa_transition(nfa, 0x1680, NULL); 				/* Ogham space mark */
	ndfa_or(nfa);
	ndfa_transition(nfa, 0x180E, NULL); 				/* Mongolian vowel separator */
	ndfa_or(nfa);
	ndfa_transition_range(nfa, 0x2000, 0x200a, NULL); 	/* Various */
	ndfa_or(nfa);
	ndfa_transition_range(nfa, 0x2028, 0x2029, NULL); 	/* LSP/PSP */
	ndfa_or(nfa);
	ndfa_transition(nfa, 0x205F, NULL); 				/* Medium mathematical space */
	ndfa_or(nfa);
	ndfa_transition(nfa, 0x3000, NULL); 				/* Ideographic space */
	
	ndfa_rejoin(nfa);
}

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
				ndfa_rejoin(nfa);
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
				
			case '|':
				/* Perform an OR with the last state on the stack */
				ndfa_or(nfa);
				break;
			
			case '\\':
				/* Quoted character */
				x++;
				if (regexp[x] == 0) {
					/* Unterminated quote */
					was_successful = 0;
					goto failed;
				}
				
				if (regexp[x] == 'w') {
					/* Whitespace set */
					recent_state = ndfa_get_pointer(nfa);
					add_whitespace_set(nfa);
				} else {
					/* Add the quoted character */
					recent_state = ndfa_get_pointer(nfa);
					ndfa_transition(nfa, quoted_char(regexp[x]), NULL);
				}
				break;
			
			default:
				/* Just add this chararcter to the nfa */
				recent_state = ndfa_get_pointer(nfa);
				ndfa_transition(nfa, regexp[x], NULL);
				break;
		}
	}
	
	/* Rejoin any ORed states */
	ndfa_rejoin(nfa);
	
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
