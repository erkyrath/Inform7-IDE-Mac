/*
 *  ndfatest.c
 *  Inform-xc2
 *
 *  Created by Andrew Hunter on 17/06/2007.
 *  Copyright 2007 Andrew Hunter. All rights reserved.
 *
 */

#include <stdio.h>
#include <stdlib.h>

#include "ndfa.h"

int main() {
	/* Make a basic NDFA */
	ndfa test_ndfa = ndfa_create();
	void* accept = malloc(1);
	
	ndfa_reset(test_ndfa);
	ndfa_transition(test_ndfa, 'f', NULL);
	ndfa_transition(test_ndfa, 'r', NULL);
	ndfa_transition(test_ndfa, 'e', NULL);
	ndfa_transition(test_ndfa, 'd', accept);

	ndfa_reset(test_ndfa);
	ndfa_transition(test_ndfa, 'f', NULL);
	ndfa_transition(test_ndfa, 'r', NULL);
	ndfa_transition(test_ndfa, 'e', NULL);
	ndfa_transition(test_ndfa, 'd', NULL);
	ndfa_transition(test_ndfa, 'd', NULL);
	ndfa_transition(test_ndfa, 'y', accept);
	
	ndfa_reset(test_ndfa);
	ndfa_transition(test_ndfa, 'd', NULL);
	ndfa_transition(test_ndfa, 'u', NULL);
	ndfa_transition(test_ndfa, 'f', NULL);
	ndfa_transition(test_ndfa, 'f', accept);
	
	ndfa_reset(test_ndfa);
	ndfa_transition(test_ndfa, 'd', NULL);
	ndfa_transition(test_ndfa, 'd', NULL);
	ndfa_transition(test_ndfa, 'u', NULL);
	ndfa_transition(test_ndfa, 'f', NULL);
	ndfa_transition(test_ndfa, 'f', accept);
	
	ndfa_reset(test_ndfa);
	ndfa_transition(test_ndfa, NDFA_START, NULL);
	ndfa_transition(test_ndfa, 'f', NULL);
	ndfa_transition(test_ndfa, 'l', NULL);
	ndfa_transition(test_ndfa, 'u', NULL);
	ndfa_transition(test_ndfa, 'p', accept);
	
	/* Compile it into a DFA */
	ndfa test_dfa = ndfa_compile(test_ndfa);
	
#ifdef DEBUG
	/* Dump it */
	ndfa_dump(test_ndfa);
	ndfa_dump(test_dfa);
#endif
	
	/* Try running the DFA */
	ndfa_run_state run = ndfa_start(test_dfa);
	ndfa_run(run, NDFA_START);
	for(;!feof(stdin);) {
		ndfa_run(run, fgetc(stdin));
	}
	
	/* Free everything up */
	ndfa_free(test_ndfa, NULL);
	ndfa_free(test_dfa, NULL);
	
	return 0;
}