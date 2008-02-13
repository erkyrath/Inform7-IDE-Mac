//
//  IFLeopard.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 09/12/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFLeopard.h"


@implementation IFLeopard

// = Text view magic =

 - (void) showFindIndicatorForRange: (NSRange) charRange
						inTextView: (NSTextView*) textView {
	[textView showFindIndicatorForRange: charRange];
}

// = Animation =

- (void) setFrame: (NSRect) newFrame
		 ofWindow: (NSWindow*) window {
	[[window animator] setFrame: newFrame
						display: NO];
}

- (void) setFrame: (NSRect) frame
		   ofView: (NSView*) view {
	if (![view wantsLayer]) { 
		[view setWantsLayer: YES];
	}
	
	[[view animator] setFrame: frame];
}

- (void) addView: (NSView*) newView
		  toView: (NSView*) superView {
	[newView removeFromSuperview];
	if (![newView wantsLayer]) { 
		[newView setWantsLayer: YES];
	}
	
	[newView setAlphaValue: 0];
	
	[superView addSubview: newView];
	
	[[newView animator] setAlphaValue: 1.0];
}

- (void) removeView: (NSView*) view {
	if (![view wantsLayer]) { 
		[view setWantsLayer: YES];
	}
	
	[[view animator] setAlphaValue: 0.0];
}

@end
