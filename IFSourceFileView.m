//
//  IFSourceFileView.m
//  Inform
//
//  Created by Andrew Hunter on Mon Feb 16 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import "IFSourceFileView.h"


@implementation IFSourceFileView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self setDrawsBackground: NO];
    }
    return self;
}

- (void) awakeFromNib {
	[self setDrawsBackground: NO];
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	[[self backgroundColor] set];
	NSRectFill(rect);
	
	[super drawRect:rect];
}

static int lineSorter(NSArray* a, NSArray* b, void* context) {
	return [[a objectAtIndex: 0] compare: [b objectAtIndex: 0]];
}

- (void) updateHighlights {
}

- (void) highlightFromArray: (NSArray*) highlightArray {
	// Sort the lines
	NSArray* sortedArray = [highlightArray sortedArrayUsingFunction: lineSorter
															context: nil];
	
	// 
}

@end
