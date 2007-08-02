//
//  IFMatcher.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 26/06/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFMatcher.h"
#import "ndfa.h"


static int named_expression_handler(ndfa nfa, ndfa_token* name, void* context);

@implementation IFMatcher

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
		matcherLock = [[NSLock alloc] init];
		results		= [[NSMutableArray alloc] init];
		nfa			= ndfa_create();
		dfa			= NULL;

		ndfa_add_named_regexp_handler(nfa, named_expression_handler, self);
		
		caseSensitive = YES;
	}
	
	return self;
}

- (id) initWithMatcher: (IFMatcher*) matcher {
	self = [super init];
	
	if (self) {
		[matcher->matcherLock lock];
		
		matcherLock		= [[NSLock allocWithZone: [self zone]] init];
		results			= [matcher->results copyWithZone: [self zone]];
		nfa				= ndfa_clone(matcher->nfa);
		dfa				= ndfa_clone(matcher->dfa);
		
		namedRegexps	= [matcher->namedRegexps copyWithZone: [self zone]];
		caseSensitive	= matcher->caseSensitive;
		
		[matcher->matcherLock unlock];
	}
	
	return self;
}

- (void) dealloc {
	if (nfa)	ndfa_free(nfa);
	if (dfa)	ndfa_free(dfa);

	[matcherLock release];
	[results release];
	[namedRegexps release];
	
	[super dealloc];
}

// = Building the lexer =

- (void) clear {
	// Free the NDFA
	ndfa_free(nfa);
	nfa = ndfa_create();
	
	// Clear out the named regular expression and results
	[namedRegexps release]; namedRegexps = nil;
	[results release]; results = [[NSMutableArray alloc] init];
	
	// Reset the named regexp handler
	ndfa_add_named_regexp_handler(nfa, named_expression_handler, self);
}

- (int) compileNamedExpression: (NSString*) name
						 inNfa: (ndfa) compileNfa {
	NSString* regexp = [namedRegexps objectForKey: name];

	if (regexp) {
		int x;
		
		// Convert the regexp to UCS-4
		ndfa_token* ucs4string = malloc(sizeof(ndfa_token)*([regexp length]+1));
		unichar* unistring = malloc(sizeof(unichar)*[regexp length]);
		
		[regexp getCharacters: unistring];
		for (x=0; x<[regexp length]; x++) {
			ucs4string[x] = unistring[x];
		}
		ucs4string[x] = 0;
		
		free(unistring);
		
		// Add it to the NDFA
		if (!ndfa_compile_regexp_ucs4(compileNfa, ucs4string, NULL)) {
			NSLog(@"Warning: received an error while compiling expression '%@'", regexp);
		}
		free(ucs4string);

		return 1;
	}
	
	NSLog(@"Warning: couldn't find regexp named '%@'", name);
	return 0;
}

static int named_expression_handler(ndfa nfa, ndfa_token* name, void* context) {
	IFMatcher* matcher = context;
	
	// Work out how many characters in the name
	int nameLen;
	for (nameLen = 0; name[nameLen]!=0; nameLen++);
	
	// Convert to a NSString
	unichar* uniName = malloc(sizeof(unichar)*nameLen);
	int x;
	for (x=0; x<nameLen; x++) uniName[x] = name[x];
	
	NSString* nameString = [[NSString alloc] initWithCharacters: uniName
														 length: nameLen];
	free(uniName);
	
	// Compile the result
	int result = [matcher compileNamedExpression: nameString
										   inNfa: nfa];
	
	// Tidy up and return
	[nameString release];
	return result;
}

// Adds a new regular expression to the lexer
- (void) addExpression: (NSString*) regexp
			withObject: (NSObject*) result {
	int x;
	
	[matcherLock lock];
	
	// Add extra states on to the DFA, if it exists
	if (nfa == NULL) {
		nfa = dfa;
		ndfa_add_named_regexp_handler(nfa, named_expression_handler, self);
		dfa = NULL;
	}
	
	// Convert the string to NDFA tokens (ie, UCS-4)
	ndfa_token* ucs4string = malloc(sizeof(ndfa_token)*([regexp length]+1));
	unichar* unistring = malloc(sizeof(unichar)*[regexp length]);
	
	[regexp getCharacters: unistring];
	for (x=0; x<[regexp length]; x++) {
		ucs4string[x] = unistring[x];
	}
	ucs4string[x] = 0;
	
	free(unistring);
	
	// Add it to the NDFA
	[results addObject: result];
	ndfa_reset(nfa);
	if (!ndfa_compile_regexp_ucs4(nfa, ucs4string, result)) {
		NSLog(@"Warning: received an error while compiling expression '%@'", regexp);
	}
	free(ucs4string);
	
	[matcherLock unlock];
	
	// TODO: once we've got background compiling, perhaps the thing to do while the compiler is running
	// is to add the expressions to a list to be added to the DFA once the compilation is complete
}

// Adds a new named expression to the lexer
- (void) addNamedExpression: (NSString*) regexp	
				   withName: (NSString*) name {
	if (!namedRegexps) namedRegexps = [[NSMutableDictionary alloc] init];
	
	[namedRegexps setObject: regexp
					 forKey: name];
}

// Starts compiling the lexer in the background, ready for later use
- (void) compileLexer {
	// TODO: compile in the background
	[matcherLock lock];
	
	// Compile the NDFA into a DFA
	dfa = ndfa_compile(nfa);
	if (dfa) {
		ndfa_free(nfa);
		nfa = NULL;
	}

	[matcherLock unlock];
}

// = Running the lexer =

#define RunBufferSize 1024

- (void) reject: (ndfa_run_state) run_state
		 length: (int) length
		  state: (ndfa_pointer) state {
	matchPosition += length;
}
	
- (void) accept: (ndfa_run_state) run_state
		 length: (int) length
		  state: (ndfa_pointer) state {
	if (matchDelegate && [matchDelegate respondsToSelector:@selector(match:inString:range:)]) {
		// Get the list of matches
		NSMutableArray* matches = [[NSMutableArray alloc] init];
		int dataCount;
		void** data = ndfa_data_for_state(dfa, state, &dataCount);
		int x;
		
		for (x=0; x<dataCount; x++) {
			[matches addObject: (NSObject*)data[x]];
		}
		
		// Call the delegate
		continueMatching = [matchDelegate match: matches
									   inString: matchString
										  range: NSMakeRange(matchPosition, length)];
		
		// Finish up with the data
		[matches release];
	}

	matchPosition += length;
}

static void accept_handler(ndfa_run_state run_state, int length, ndfa_pointer state, void* context) {
	IFMatcher* matcher = context;
	
	[matcher accept: run_state
			 length: length
			  state: state];
}

static void reject_handler(ndfa_run_state run_state, int length, ndfa_pointer state, void* context) {
	IFMatcher* matcher = context;
	
	[matcher reject: run_state
			 length: length
			  state: state];
}

// Runs the lexer against a specific string
- (void) match: (NSString*) string
  withDelegate: (id) lexDelegate {
	[matcherLock lock];
	
	// Ensure that we have a DFA to run
	while (dfa == NULL) {
		[matcherLock unlock];
		[self compileLexer];
		[matcherLock lock];
	}
	
	// Prepare the run the DFA against the string
	ndfa_run_state run_state = ndfa_start(dfa);
	ndfa_add_handlers(run_state, accept_handler, reject_handler, self);
	
	unichar* buffer = malloc(sizeof(unichar)*RunBufferSize);
	int bufPos = RunBufferSize;
	int len = [string length];
	int stringPos;
	
	matchPosition	= 0;
	matchDelegate	= lexDelegate;
	matchString		= string;
	
	ndfa_run(run_state, NDFA_START);
	ndfa_run(run_state, NDFA_STARTOFLINE);
	continueMatching = YES;
	for (stringPos = 0; stringPos < len && continueMatching; stringPos++, bufPos++) {
		// Read more characters from the buffer if necessary
		if (bufPos >= RunBufferSize) {
			NSRange charRange = NSMakeRange(stringPos, RunBufferSize);
			if (charRange.location + charRange.length > len) charRange.length = len-charRange.location;

			if (caseSensitive) {
				[string getCharacters: buffer
								range: charRange];				
			} else {
				NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

				NSString* lowerString = [[string substringWithRange: charRange] lowercaseString];
				[lowerString getCharacters: buffer
									 range: NSMakeRange(0, charRange.length)];
				
				[pool release];
			}
			bufPos = 0;
		}
		
		// Process the next character
		if (buffer[bufPos] == '\n' || buffer[bufPos] == '\r') {
			// Treat newlines as start/ends
			ndfa_run(run_state, NDFA_ENDOFLINE);
			ndfa_run(run_state, buffer[bufPos]);
			ndfa_run(run_state, NDFA_STARTOFLINE);
		} else {
			// Just run everything else straight through
			ndfa_run(run_state, buffer[bufPos]);
		}
	}
	ndfa_run(run_state, NDFA_ENDOFLINE);
	ndfa_run(run_state, NDFA_END);
	
	// Finish up
	ndfa_finish(run_state);
	[matcherLock unlock];
}

- (void) setCaseSensitive: (BOOL) isCaseSensitive {
	caseSensitive = isCaseSensitive;
}

// = NSCopying =

- (id) copyWithZone: (NSZone*) zone {
	return [[IFMatcher allocWithZone: zone] initWithMatcher: self];
}

@end
