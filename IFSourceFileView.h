//
//  IFSourceFileView.h
//  Inform
//
//  Created by Andrew Hunter on Mon Feb 16 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>

// Variation on NSTextView that supports line highlighting

// Highlight array contains entries of type NSArray
//   Each entry contains (line, style) as NSNumbers

@interface IFSourceFileView : NSTextView {
	NSArray* highlights;
}

- (void) updateHighlights;
- (void) highlightFromArray: (NSArray*) highlightArray;

@end
