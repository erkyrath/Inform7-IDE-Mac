//
//  IFPretendWebView.m
//  Inform
//
//  Created by Andrew Hunter on 18/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFPretendWebView.h"
#import "IFPreferences.h"


@implementation IFPretendWebView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		aRequest = nil;
		hostWindow = nil;
    }
    return self;
}

- (void) dealloc {
	[aRequest release];
	[hostWindow release];

	[super dealloc];
}

- (void) morph {
	
}

- (void)drawRect:(NSRect)rect {
	// Morphing time!
	[[NSRunLoop currentRunLoop] performSelector: @selector(morphMe)
										 target: self
									   argument: nil
										  order: 128
										  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
}

- (void) setRequest: (NSURLRequest*) request {
	if (aRequest) [aRequest release];
	aRequest = [request copy];
}

- (void) setHostWindow: (NSWindow*) newHostWindow {
	if (hostWindow) [hostWindow release];
	
	hostWindow = [newHostWindow retain];
}

- (void) setPolicyDelegate: (id) delegate {
	policyDelegate = delegate;
}

- (void) morphMe {
	// Schedule our destruction
	[[self retain] autorelease];
	
	// Create the webview
	WebView* replacementView = [[WebView alloc] initWithFrame: [self frame]];
	[replacementView setAutoresizingMask: [self autoresizingMask]];
	[replacementView setTextSizeMultiplier: [[IFPreferences sharedPreferences] fontSize]];
	
	if (hostWindow) {
		[replacementView setHostWindow: hostWindow];
	}
	
	if (policyDelegate) {
		[replacementView setPolicyDelegate: policyDelegate];
	}
	
	// Leave our superview
	NSView* sview = [[[self superview] retain] autorelease];
	[self removeFromSuperview];
	
	// Add to the superview
	[sview addSubview: replacementView];
	
	// Load the request
	if (aRequest) {
		[[replacementView mainFrame] loadRequest: aRequest];
	}
}

@end
