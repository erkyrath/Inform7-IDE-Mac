//
//  IFFindTextView.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 05/02/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFFindTextView.h"
#import "IFFindController.h"
#import "IFAppDelegate.h"
#import "IFMatcher.h"

#include <wctype.h>

@implementation NSTextView(IFFindTextView)

- (BOOL) find: (NSString*) phrase
		 type: (IFFindType) type
	direction: (int) direction 
	fromPoint: (int) point {
	// Do nothing if the phrase is empty
	if ([phrase length] <= 0) return NO;
	
	BOOL insensitive = (type&IFFindCaseInsensitive)!=0;
	
	// Create a matcher if we're using regular expressions
	IFMatcher* matcher = nil;
	if ((type&0xff) == IFFindRegexp) {
		matcher = [[IFMatcher alloc] init];
		[matcher autorelease];
		
		[matcher setCaseSensitive: insensitive];
		[matcher addExpression: phrase
					withObject: [NSNumber numberWithBool: YES]];
	}

	// Get the text
	NSString* text = [[self textStorage] string];
	if ([phrase length] > [text length]) return NO;
		 
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

// = Basic interface =

- (BOOL) findNextMatch:	(NSString*) match
				ofType: (IFFindType) type {
	int matchPos = [self selectedRange].location + [self selectedRange].length;
	return [self find: match
				 type: type
			direction: 1
			fromPoint: matchPos];
}

- (BOOL) findPreviousMatch: (NSString*) match
					ofType: (IFFindType) type {
	int matchPos = [self selectedRange].location;
	return [self find: match
				 type: type
			direction: -1
			fromPoint: matchPos];
}

- (BOOL) canUseFindType: (IFFindType) find {
	return YES;
}

- (NSString*) currentSelectionForFind {
	return [[self string] substringWithRange: [self selectedRange]];
}

// = 'Find all' =

- (NSArray*) findAllMatches: (NSString*) match
		   inFindController: (IFFindController*) controller {
	return nil;
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

- (void) replaceAllForPhrase: (NSString*) phrase
				  withString: (NSString*) string
						type: (IFFindType) type {
}

@end
