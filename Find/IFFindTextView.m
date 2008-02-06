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

@implementation NSTextView(IFFindTextView)

- (void) find: (NSString*) phrase
		 type: (IFFindType) type
	direction: (int) direction 
	fromPoint: (int) point {
	// Do nothing if the phrase is empty
	if ([phrase length] <= 0) return;
	
	BOOL insensitive = (type&IFFindCaseInsensitive)!=0;

	// Get the text
	NSString* text = [[self textStorage] string];
	if ([phrase length] > [text length]) return;
		 
	// Get the characters for the phrase
	if (insensitive) phrase = [phrase lowercaseString];
	unichar* phraseBuf = malloc(sizeof(unichar)*[phrase length]+1);
	[phrase getCharacters: phraseBuf];
	
	int matchLoc = NSNotFound;
	
	// Simple search in the specified direction
	int pos = point;
	do {
		// Move on to the next position
		pos += direction;
		
		// Wrap around if necessary
		if (direction < 0 && pos < 0) 
			pos = [text length] - [phrase length];
		if (direction > 0 && pos > [text length]-[phrase length])
			pos = 0;
		
		// See if we have a match at this position
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
			break;
		}
	} while (pos != point);
	
	free(phraseBuf);
	
	if (matchLoc != NSNotFound) {
		// Highlight the match
		NSRange matchRange = NSMakeRange(matchLoc, [phrase length]);
		
		[self scrollRangeToVisible: matchRange];
		[self setSelectedRange: matchRange];
		[[[NSApp delegate] leopard] showFindIndicatorForRange: matchRange
												   inTextView: self];
	} else {
		NSBeep();
	}
}

// = Basic interface =

- (void) findNextMatch:	(NSString*) match
				ofType: (IFFindType) type {
	int matchPos = [self selectedRange].location + [self selectedRange].length;
	[self find: match
		  type: type
	 direction: 1
	 fromPoint: matchPos];
}

- (void) findPreviousMatch: (NSString*) match
					ofType: (IFFindType) type {
	int matchPos = [self selectedRange].location;
	[self find: match
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

// 'Find all'
- (NSArray*) findAllMatches: (NSString*) match
		   inFindController: (IFFindController*) controller {
	return nil;
}

// Search as you type
- (void) beginSearchAsYouType {
}

- (void) findAsYouType: (NSString*) phrase
				ofType: (IFFindType) type {
}

- (void) endSearchAsYouType {
}

// Replace
- (void) replaceFoundWith: (NSString*) match {
}

- (void) replaceAllForPhrase: (NSString*) phrase
				  withString: (NSString*) string
						type: (IFFindType) type {
}

@end
