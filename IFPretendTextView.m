//
//  NSPretendTextView.m
//  Inform
//
//  Created by Andrew Hunter on 02/12/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFPretendTextView.h"


@implementation IFPretendTextView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void) dealloc {
	if (eventualString) {
		[eventualString release];
		eventualString = nil;
	}
	
	[super dealloc];
}

- (void)drawRect:(NSRect)rect {
	[[NSRunLoop currentRunLoop] performSelector: @selector(morphMe)
										 target: self
									   argument: nil
										  order: 128
										  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
}

- (void) setEventualString: (NSString*) newEventualString {
	if (eventualString) {
		[eventualString release];
		eventualString = nil;
	}

	eventualString = [newEventualString copy];
}

- (void) morphMe {
	// Schedule our destruction
	[[self retain] autorelease];
	
	// Create the text view, with some default options
	NSTextView* textView = [[NSTextView alloc] initWithFrame: [self frame]];
	NSScrollView* scrollView = [[NSScrollView alloc] initWithFrame: [self frame]];
	
	if (eventualString) {
		[[[textView textStorage] mutableString] setString: eventualString];
		
		[eventualString release];
		eventualString = nil;
	}
	
	[[textView textContainer] setWidthTracksTextView: NO];
	[[textView textContainer] setContainerSize: NSMakeSize(1e8, 1e8)];
	[textView setMinSize:NSMakeSize(0.0, 0.0)];
	[textView setMaxSize:NSMakeSize(1e8, 1e8)];
	[textView setVerticallyResizable:YES];
	[textView setHorizontallyResizable:YES];
	[textView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
	[textView setEditable: NO];
	[textView setUsesFindPanel: YES]; // FIXME: Won't work on Jaguar
	
	[scrollView setDocumentView: textView];
	[scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
	[scrollView setHasHorizontalScroller: YES];
	[scrollView setHasVerticalScroller: YES];
				
	// Leave our superview
	NSView* sview = [[[self superview] retain] autorelease];
	[self removeFromSuperview];
	
	// Add to the superview
	[sview addSubview: scrollView];
	
	[textView release];
	[scrollView release];
}

@end
