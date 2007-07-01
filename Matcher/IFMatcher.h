//
//  IFMatcher.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 26/06/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ndfa.h"

///
/// Class for lexing regular expressions
///
@interface IFMatcher : NSObject {
	NSLock*		matcherLock;						// Lock used to allow us to compile the NDFA in the background
	
	ndfa		nfa;								// Lexer in the process of being built
	ndfa		dfa;								// Lexer that's ready to run
	
	NSMutableArray* results;						// Array of objects that can be results

	NSMutableDictionary* namedRegexps;				// Array of named regular expressions
		
	// TODO: could put these in an independant class to make this class completely thread-safe
	NSString* matchString;							// The string currently being matched against
	int matchPosition;								// Position of the last known match (while match is running)
	id matchDelegate;								// The delegate passed to the matcher function
}

// Building the lexer
- (void) addNamedExpression: (NSString*) regexp		// Adds a new named expression to the lexer
				   withName: (NSString*) name;
- (void) addExpression: (NSString*) regexp			// Adds a new regular expression to the lexer
			withObject: (NSObject*) result;
- (void) compileLexer;								// Starts compiling the lexer in the background, ready for later use

// Running the lexer
- (void) match: (NSString*) string					// Runs the lexer against a specific string
  withDelegate: (id) lexDelegate;

@end

@interface NSObject(IFMatcherDelegate)

- (void) match: (NSArray*) match					// Reports a match on on the specified string
	  inString: (NSString*) matchString
		 range: (NSRange) range;

@end
