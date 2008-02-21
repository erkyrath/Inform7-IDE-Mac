//
//  IFFindTextView.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 05/02/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFFindTextView.h"
#import "IFFindController.h"
#import "IFFindResult.h"
#import "IFAppDelegate.h"
#import "IFMatcher.h"

#include <wctype.h>

@implementation NSTextView(IFFindTextView)

- (NSRange) find: (NSString*) phrase
			type: (IFFindType) type
	   direction: (int) direction 
	   fromPoint: (int) point
		 matcher: (IFMatcher**) oldMatcher {
	NSRange result = NSMakeRange(NSNotFound, NSNotFound);
	
	// Do nothing if the phrase is empty
	if ([phrase length] <= 0) return result;
	
	BOOL insensitive = (type&IFFindCaseInsensitive)!=0;
	
	// Create a matcher if we're using regular expressions
	IFMatcher* matcher = nil;
	if ((type&0xff) == IFFindRegexp) {
		if (oldMatcher && *oldMatcher) {
			// Re-use the previous regexp matcher if it's available
			matcher = [[*oldMatcher retain] autorelease];
		} else {
			// Otherwise a new regexp matcher
			matcher = [[IFMatcher alloc] init];
			[matcher autorelease];
			
			[matcher setCaseSensitive: insensitive];
			[matcher addExpression: phrase
						withObject: [NSNumber numberWithBool: YES]];
			
			if (oldMatcher) *oldMatcher = matcher;
		}
	}

	// Get the text
	NSString* text = [[self textStorage] string];
	if ([phrase length] > [text length]) return NSMakeRange(NSNotFound, NSNotFound);
		 
	// Get the characters for the phrase
	if (insensitive) phrase = [phrase lowercaseString];
	unichar* phraseBuf = malloc(sizeof(unichar)*[phrase length]+1);
	[phrase getCharacters: phraseBuf];
	
	int matchLoc = NSNotFound;
	int matchLength = 0;
	
	// Simple search in the specified direction
	int pos = point;
	int phraseLength = [phrase length];
	if (matcher) phraseLength = 1;
	do {
		// Move on to the next position
		pos += direction;
		
		// Wrap around if necessary
		if (direction < 0 && pos < 0) 
			pos = [text length] - phraseLength;
		if (direction > 0 && pos > [text length]-phraseLength)
			pos = 0;
		
		// See if we have a match at this position
		if (matcher) {
			// Use the regexp matching algorithm
			NSRange searchRange;
			NSRange matchRange;
			
			if (direction == -1) {
				// Searching backwards is horrendously inefficient
				if (pos < point) {
					searchRange.location = pos;
					searchRange.length   = point - pos;
				} else {
					searchRange.location = pos;
					searchRange.length	 = [text length] - pos;
				}
			} else {
				// Searching forwards is much better!
				if (pos == 0) {
					searchRange.location = 0;
					searchRange.length	= [text length];
					pos = point;
				} else {
					searchRange.location = pos;
					searchRange.length	 = [text length] - pos;
					pos = [text length];
				}
			}
			
			if ([matcher nextMatchFromString: text
								 searchRange: searchRange
									  result: nil
								 resultRange: &matchRange]) {
				matchLoc	= matchRange.location;
				matchLength = matchRange.length;
				break;
			}
		} else {
			// Use the standard match algorithm
			int x;
			BOOL match = YES;
			
			for (x=0; x<[phrase length]; x++) {
				unichar c = [text characterAtIndex: x+pos];
				if (insensitive) c = towlower(c);
				if (c != phraseBuf[x]) {
					match = NO;
					break;
				}
			}
			
			if (match && ((type&0xff) == IFFindBeginsWith || (type&0xff) == IFFindCompleteWord)) {
				// This match must be at the start of a word
				unichar preceedingChar = ' ';
				if (pos > 0) {
					preceedingChar = [text characterAtIndex: pos-1];
				}
				
				if (!iswblank(preceedingChar) && !iswpunct(preceedingChar)) {
					// Words begin with whitespace, or punctuation
					match = NO;
				}
			}

			if (match && (type&0xff) == IFFindCompleteWord) {
				// This match must be at the end of a word
				unichar followingChar = ' ';
				if (pos + [phrase length] < [text length]) {
					followingChar = [text characterAtIndex: pos+[phrase length]];
				}
				
				if (!iswblank(followingChar) && !iswpunct(followingChar)) {
					// Words end with whitespace, or punctuation
					match = NO;
				}
			}
			
			// Stop if we've got a match
			if (match) {
				matchLoc = pos;
				matchLength = [phrase length];
				break;
			}
		}
	} while (pos != point);
	
	free(phraseBuf);
	
	if (matchLoc != NSNotFound) {
		// Highlight the match
		NSRange matchRange = NSMakeRange(matchLoc, matchLength);
		
		result = matchRange;
		
		return result;
	} else {
		return NSMakeRange(NSNotFound, NSNotFound);
	}
}

// = Basic interface =

- (BOOL) findNextMatch:	(NSString*) match
				ofType: (IFFindType) type {
	int matchPos = [self selectedRange].location + [self selectedRange].length;
	NSRange matchRange = [self find: match
							   type: type
						  direction: 1
						  fromPoint: matchPos
							matcher: nil];
	
	if (matchRange.location != NSNotFound) {
		[self scrollRangeToVisible: matchRange];
		[self setSelectedRange: matchRange];
		[[[NSApp delegate] leopard] showFindIndicatorForRange: matchRange
												   inTextView: self];
		return YES;
	} else {
		NSBeep();
		return NO;
	}
}

- (BOOL) findPreviousMatch: (NSString*) match
					ofType: (IFFindType) type {
	int matchPos = [self selectedRange].location;
	NSRange matchRange =  [self find: match
								type: type
						   direction: -1
						   fromPoint: matchPos
							 matcher: nil];
	
	if (matchRange.location != NSNotFound) {
		[self scrollRangeToVisible: matchRange];
		[self setSelectedRange: matchRange];
		[[[NSApp delegate] leopard] showFindIndicatorForRange: matchRange
												   inTextView: self];
		return YES;
	} else {
		NSBeep();
		return NO;
	}
}

- (BOOL) canUseFindType: (IFFindType) find {
	return YES;
}

- (NSString*) currentSelectionForFind {
	return [[self string] substringWithRange: [self selectedRange]];
}

// = 'Find all' =

- (void) highlightFindResult: (IFFindResult*) result {
	NSRange matchRange = [[result data] rangeValue];

	[self scrollRangeToVisible: matchRange];
	[self setSelectedRange: matchRange];
	[[[NSApp delegate] leopard] showFindIndicatorForRange: matchRange
											   inTextView: self];
}

- (NSArray*) findAllMatches: (NSString*) match
					 ofType: (IFFindType) type
		   inFindController: (IFFindController*) controller
			 withIdentifier: (id) identifier {
	// Do nothing if no phrase is supplied
	if ([match length] <= 0) return nil;
	
	// Prepare to match all of the results
	int pos = 0;
	NSRange nextMatch;
	NSMutableArray* result = [[NSMutableArray alloc] init];
	IFMatcher* matcher = nil;
	
	for (;;) {
		// Find the next result.
		// TODO: preserve the matcher if possible
		nextMatch = [self find: match
						  type: type
					 direction: 1
					 fromPoint: pos
					   matcher: &matcher];
		
		// If this match is valid, then add it to the list of results
		if (nextMatch.location >= pos && nextMatch.location != NSNotFound) {
			// Ignore it if it has no length
			if (nextMatch.length == 0) {
				pos = nextMatch.location + 1;
				continue;
			}
			
			// Try to use 64 characters of context on either side of the match
			int contextStart;
			for (contextStart = nextMatch.location; contextStart > nextMatch.location-15; contextStart--) {
				if (contextStart == 0) break;
				
				unichar chr = 0;
				if (contextStart > 0) chr = [[[self textStorage] string] characterAtIndex: contextStart-1];
				if (chr == '\n' || chr == '\r') break;
			}
			int contextEnd   = nextMatch.location + nextMatch.length + 128;
			
			if (contextEnd > [[self textStorage] length]) contextEnd = [[self textStorage] length];
			
			[result addObject: [[[IFFindResult alloc] initWithMatchType: @"Text"
															   location: @"Text"
																context: [[[self textStorage] string] substringWithRange: NSMakeRange(contextStart, contextEnd-contextStart)]
														   contextRange: NSMakeRange(nextMatch.location - contextStart, nextMatch.length)
																   data: [NSValue valueWithRange: nextMatch]] autorelease]];
			
			// Move to the next position
			pos = nextMatch.location + nextMatch.length;
		} else {
			break;
		}
	};
	
	return result;
}

// = Search as you type =

- (void) beginSearchAsYouType {
}

- (void) findAsYouType: (NSString*) phrase
				ofType: (IFFindType) type {
}

- (void) endSearchAsYouType {
}

// = Replace =

- (void) replaceFoundWith: (NSString*) match 
					range: (NSRange) selected {
	NSString* previousValue = [[self string] substringWithRange: selected];
	
	[[self textStorage] replaceCharactersInRange: selected
									  withString: match];
	selected.length = [match length];
	[self setSelectedRange: selected];
	
	// Create an undo action for this replacement
	[[self undoManager] beginUndoGrouping];
	[[self undoManager] setActionName: [[NSBundle mainBundle] localizedStringForKey: @"Replace"
																			  value: @"Replace"
																			  table: nil]];
	[[[self undoManager] prepareWithInvocationTarget: self] replaceFoundWith: previousValue
																	   range: selected];
	[[self undoManager] endUndoGrouping];
}

- (void) replaceFoundWith: (NSString*) match {
	NSRange selected = [self selectedRange];
	[self replaceFoundWith: match
					 range: selected];
}

- (void) beginReplaceAll: (IFFindController*) sender {
	// Begin an undo action for this operation
	[[self undoManager] beginUndoGrouping];
	[[self undoManager] setActionName: [[NSBundle mainBundle] localizedStringForKey: @"Replace All"
																			  value: @"Replace All"
																			  table: nil]];
}

- (void) finishedReplaceAll: (IFFindController*) sender {
	// Finished with the replace all operation
	[[self undoManager] endUndoGrouping];
}


- (void) replaceFindAllResult: (NSString*) match 
						range: (NSRange) selected {
	NSString* previousValue = [[self string] substringWithRange: selected];
	
	[[self textStorage] replaceCharactersInRange: selected
									  withString: match];
	selected.length = [match length];
	[self setSelectedRange: selected];
	
	// Create an undo action for this replacement
	[[[self undoManager] prepareWithInvocationTarget: self] replaceFindAllResult: previousValue
																		   range: selected];
}

- (IFFindResult*) replaceFindAllResult: (IFFindResult*) result
							withString: (NSString*) replacement 
								offset: (int*) offset {
	// Get the original match
	NSRange matchRange = [[result data] rangeValue];
	matchRange.location += *offset;
	NSString* originalMatch = [[result context] substringWithRange: [result contextRange]];
	
	// Check that the user hasn't edited the text since the match was made
	if (![[[[self textStorage] string] substringWithRange: matchRange] isEqualToString: originalMatch]) {
		return nil;
	}
	
	// Update the context to create a new match
	NSRange contextRange = [result contextRange];
	NSString* oldContext = [result context];
	NSString* newContext = [NSString stringWithFormat: @"%@%@%@",
							[oldContext substringToIndex: contextRange.location],
							replacement,
							[oldContext substringFromIndex: contextRange.location + contextRange.length]];
	NSRange newContextRange = [result contextRange];
	newContextRange.length = [replacement length];
	
	NSRange newMatchRange = matchRange;
	newMatchRange.length = [replacement length];
	IFFindResult* newResult = [[[IFFindResult alloc] initWithMatchType: [result matchType]
															  location: [result location] 
															   context: newContext
														  contextRange: newContextRange
																  data: [NSValue valueWithRange: newMatchRange]]
							   autorelease];
	
	// Perform the replacement
	[self replaceFindAllResult: replacement
						 range: matchRange];
	
	// Update the offset so future matches are replaced correctly
	*offset += (int)[replacement length] - (int)[originalMatch length];
	return newResult;
}

@end
