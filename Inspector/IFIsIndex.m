//
//  IFIsIndex.m
//  Inform
//
//  Created by Andrew Hunter on Fri May 07 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import "IFIsIndex.h"
#import "IFAppDelegate.h"

#import "IFProjectController.h"

NSString* IFIsIndexInspector = @"IFIsIndexInspector";

@implementation IFIsIndex

+ (IFIsIndex*) sharedIFIsIndex {
	static IFIsIndex* sharedIndex = nil;
	
	if (sharedIndex == nil && [IFAppDelegate isWebKitAvailable]) {
		sharedIndex = [[IFIsIndex alloc] init];
	}
	
	return sharedIndex;
}

- (id) init {
	self = [super init];
	
	if (self) {
		[self setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Inspector Index"
															   value: @"Index"
															   table: nil]];
		
		indexView = [[WebView alloc] init];
		[indexView setPolicyDelegate: self];
		[indexView setFrameSize: NSMakeSize(100, 300)];
		[indexView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
		[indexView makeTextSmaller: self];
		
		// Need a way to select 'small' scrollbar size.
		
		inspectorView = [indexView retain];
		canDisplay = NO;
	}

	return self;
}

- (void) dealloc {
	[indexView release];
	[super dealloc];
}

- (NSString*) key {
	return IFIsIndexInspector;
}

- (BOOL) available {
	return canDisplay;
}

- (void) inspectWindow: (NSWindow*) window {
	activeWindow = window;
	
	canDisplay = NO;
	if ([window windowController] != nil) {
		[self updateIndexFrom: [window windowController]];
	}
}

- (void) updateIndexFrom: (NSWindowController*) controller {
	// Refuse to update if this is the wrong window
	if ([controller window] != activeWindow) return;
	
	// Only update if this is a project controller
	if ([controller isKindOfClass: [IFProjectController class]]) {
		canDisplay = YES;
		
		IFProjectController* proj = (IFProjectController*) controller;
		
		if ([proj pathToIndexFile] != nil) {
			[[indexView mainFrame] loadRequest: [[[NSURLRequest alloc] initWithURL: [NSURL fileURLWithPath: [proj pathToIndexFile]]] autorelease]];
		} else {
			[[indexView mainFrame] loadRequest: [[[NSURLRequest alloc] initWithURL: [NSURL URLWithString: @"nodoc:noindex"]] autorelease]];
		}
	}
}

// = Web policy delegate methods =

- (void)					webView: (WebView *)sender 
	decidePolicyForNavigationAction: (NSDictionary *)actionInformation 
							request: (NSURLRequest *)request 
							  frame: (WebFrame *)frame 
				   decisionListener: (id<WebPolicyDecisionListener>)listener {
	if (activeWindow == nil || !canDisplay) {
		[listener ignore];
		return;
	}
	
	// Blah. Link failure if WebKit isn't available here. Constants aren't weak linked
	
	// Double blah. WebNavigationTypeLinkClicked == null, but the action value == 0. Bleh
	if ([[actionInformation objectForKey: WebActionNavigationTypeKey] intValue] == 0) {
		NSURL* url = [request URL];
				
		if ([[url scheme] isEqualTo: @"source"]) {
			// We deal with these ourselves
			[listener ignore];
			
			// Format is 'source file name#line number'
			NSString* path = [[[request URL] resourceSpecifier] stringByReplacingPercentEscapesUsingEncoding: NSASCIIStringEncoding];
			NSArray* components = [path componentsSeparatedByString: @"#"];
			
			if ([components count] != 2) {
				NSLog(@"Bad source URL: %@", path);
				if ([components count] < 2) return;
				// (try anyway)
			}
			
			NSString* sourceFile = [[components objectAtIndex: 0] stringByReplacingPercentEscapesUsingEncoding: NSUnicodeStringEncoding];
			NSString* sourceLine = [[components objectAtIndex: 1] stringByReplacingPercentEscapesUsingEncoding: NSUnicodeStringEncoding];
			
			// Move to the appropriate place in the file
			IFProjectController* controller = [activeWindow windowController];
			
			if (![controller selectSourceFile: sourceFile]) {
				NSLog(@"Can't select source file '%@'", sourceFile);
				return;
			}
			
			[activeWindow makeKeyWindow];
			[controller moveToSourceFileLine: [sourceLine intValue]];
			[controller removeHighlightsOfStyle: IFLineStyleError];
			[controller highlightSourceFileLine: [sourceLine intValue]
										 inFile: sourceFile
										  style: IFLineStyleError]; // FIXME: error level?. Filename?						
						
			// Finished
			return;
		}
	}

	// default action
	[listener use];
}

@end
