//
//  IFSourceFileView.h
//  Inform
//
//  Created by Andrew Hunter on Mon Feb 16 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "IFContextMatcher.h"

// Variation on NSTextView that supports line highlighting

// Highlight array contains entries of type NSArray
//   Each entry contains (line, style) as NSNumbers

@interface IFSourceFileView : NSTextView {
	IFContextMatcher*	syntaxDictionary;										// Context matcher used to implement a syntax dictionary
	
	BOOL tornAtTop;																// YES if we should draw a 'tear' at the top of the view
	BOOL tornAtBottom;															// YES if we should draw a 'tear' at the bottom of the view
}

// Matching syntax

- (void) setSyntaxDictionaryMatcher: (IFContextMatcher*) matcher;				// Context matcher that's used to implement a syntax dictionary

// Drawing 'tears' at the top and bottom

- (void) setTornAtTop: (BOOL) tornAtTop;										// Sets whether or not a 'tear' should appear at the top of the view
- (void) setTornAtBottom: (BOOL) tornAtBottom;									// Sets whether or not a 'tear' should appear at the bottom of the view

@end
