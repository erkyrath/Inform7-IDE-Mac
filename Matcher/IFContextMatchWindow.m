//
//  IFContextMatchWindow.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 03/07/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFContextMatchWindow.h"
#import "IFContextTopDecalView.h"


@implementation IFContextMatchWindow

- (id) init {
	NSImage* topDecal = [NSImage imageNamed: @"InfoWindowTop"];
	
	// Create the window that we're going to popup
	NSWindow* contextWindow = [[NSPanel alloc] initWithContentRect: NSMakeRect(0,0,[topDecal size].width, 320)
														  styleMask: NSBorderlessWindowMask
															backing: NSBackingStoreBuffered 
															  defer: NO];
	[contextWindow setLevel: NSTornOffMenuWindowLevel];
	[contextWindow setOpaque: NO];
	[contextWindow setAlphaValue: 0.95];
	
	self = [super initWithWindow: [contextWindow autorelease]];
	
	if (self) {
		// Add the views for the window
		
		// The upper decal
		NSSize topSize = [topDecal size];
		NSView* topView = [[IFContextTopDecalView alloc] initWithFrame: NSMakeRect(0,0, topSize.width, topSize.height)];
		[contextWindow setContentView: topView];
		[topView release];
		
		// The text view
		NSRect contentRect = [[contextWindow contentView] frame];
		NSTextView* textView = [[NSTextView alloc] initWithFrame: NSMakeRect(NSMinX(contentRect), NSMinY(contentRect), contentRect.size.width, contentRect.size.height-topSize.height)];
		
		[textView setBackgroundColor: [NSColor windowBackgroundColor]];
		[textView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
		
		[textView setEditable: NO];
		[textView setSelectable: NO];
		[textView setTextContainerInset: NSMakeSize(8, 8)];
		[[[textView textStorage] mutableString] appendString: @"Hello, world"];
		
		[[contextWindow contentView] addSubview: textView];
		
		// Ensure the window has a shadow
		[contextWindow setHasShadow: YES];
	}
	
	return self;
}

- (void) dealloc {
	[super dealloc];
}

@end
