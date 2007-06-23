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

void show(ndfa_run_state run, int length, void* data, void* context) {
	if (data == NULL) {
		printf("REJECT: ");
	} else {
		printf("Accepted: ");
	}
	
	ndfa_token* buf = ndfa_last_input(run);
	int x;
	for (x=0; x<length; x++) {
		if (buf[x] >= 32 && buf[x] < 127) {
			printf("%c", buf[x]);
		} else {
			printf("?");
		}
	}
	
	printf("\n");
}

int main() {
	/* Make a basic NDFA */
	ndfa test_ndfa = ndfa_create();
	void* accept = malloc(1);
	
	ndfa_reset(test_ndfa);
	if (!ndfa_compile_regexp(test_ndfa, "(stuff|nonsense)+\\w", accept)) {
		printf("Couldn't compile NFA\n");
		abort();
	}
	
#ifdef DEBUG
	/* Dump it */
	ndfa_dump(test_ndfa);
#endif
	
	/* Compile it into a DFA */
	ndfa test_dfa = ndfa_compile(test_ndfa);
	
#ifdef DEBUG
	/* Dump it */
	ndfa_dump(test_dfa);
#endif
	
	/* Try running the DFA */
	ndfa_run_state run = ndfa_start(test_dfa);
	ndfa_add_handlers(run, show, show, NULL);
	ndfa_run(run, NDFA_START);
	for(;!feof(stdin);) {
		ndfa_run(run, fgetc(stdin));
	}
	
	ndfa_finish(run);
	
	/* Free everything up */
	ndfa_free(test_ndfa, NULL);
	ndfa_free(test_dfa, NULL);
	
	return 0;
}