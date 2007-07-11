/*
 *  ndfatest.c
 *  Copyright (c) 2007 Andrew Hunter
 *
 *  Permission is hereby granted, free of charge, to any person
 *  obtaining a copy of this software and associated documentation
 *  files (the "Software"), to deal in the Software without
 *  restriction, including without limitation the rights to use,
 *  copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following
 *  conditions:
 *
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *  OTHER DEALINGS IN THE SOFTWARE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include "ndfa.h"

void show(ndfa_run_state run, int length, ndfa_pointer accept, void* context) {
	if (accept == NDFA_REJECT) {
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
			printf("? (%04x) ", buf[x]);
		}
	}
	
	printf("\n");
}

int main() {
	/* Make a basic NDFA */
	ndfa test_ndfa = ndfa_create();
	void* accept = malloc(1);
	
	ndfa_reset(test_ndfa);
	/* Try 'thingiethingiegarbagegarbagethingiethingiex' with this: note garbage in the BT buffer */
	/* Also note infinite loop when you try that garbage, that is 'thingiethingiegarbagegarbagethinthingiethin' */
	if (!ndfa_compile_regexp(test_ndfa, ">(joe|bob){2,4}x<", accept)) {
		printf("Couldn't compile regexp to NFA\n");
		abort();
	}
	/*
	if (!ndfa_compile_regexp(test_ndfa, "[A-Za-z]([0-9A-Za-z])*", accept)) {
		printf("Couldn't compile regexp to NFA\n");
		abort();
	}
	*/
	/*
	if (!ndfa_compile_regexp(test_ndfa, "[^\\w0-9]+", accept)) {
		printf("Couldn't compile regexp to NFA\n");
		abort();
	}
	*/
	/*
	ndfa_reset(test_ndfa);
	if (!ndfa_compile_regexp(test_ndfa, "(stuff|nonsense)+", accept)) {
		printf("Couldn't compile regexp to NFA\n");
		abort();
	}
	ndfa_reset(test_ndfa);
	if (!ndfa_compile_regexp(test_ndfa, "$....", accept)) {
		printf("Couldn't compile regexp to NFA\n");
		abort();
	}
	ndfa_reset(test_ndfa);
	if (!ndfa_compile_regexp(test_ndfa, "(some)*garbage", accept)) {
		printf("Couldn't compile regexp to NFA\n");
		abort();
	}
	ndfa_reset(test_ndfa);
	if (!ndfa_compile_regexp(test_ndfa, "(the)+thing", accept)) {
		printf("Couldn't compile regexp to NFA\n");
		abort();
	}
	*/
	/*
	ndfa_reset(test_ndfa);
	if (!ndfa_compile_regexp(test_ndfa, "\\w+", accept)) {
		printf("Couldn't compile regexp to NFA\n");
		abort();
	}
	*/

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
	ndfa_run(run, NDFA_STARTOFLINE);
	for(;!feof(stdin);) {
		int c = fgetc(stdin);
		
		if (c < 0) {
			ndfa_run(run, NDFA_END);
			break;
		} else if (c == '\n') {
			ndfa_run(run, NDFA_ENDOFLINE);
			ndfa_run(run, c);
			ndfa_run(run, NDFA_STARTOFLINE);
		} else {
			ndfa_run(run, c);			
		}
		
		ndfa_run_state run2 = ndfa_copy_run_state(run);
		assert(ndfa_run_state_equals(run, run2));
		assert(ndfa_run_state_equals(run2, run));
		ndfa_finish(run);
		run = run2;
	}
	
	ndfa_finish(run);
	
	/* Free everything up */
	ndfa_free(test_ndfa);
	ndfa_free(test_dfa);
	
	return 0;
}