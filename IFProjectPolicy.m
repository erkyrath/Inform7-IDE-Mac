//
//  IFProjectPolicy.m
//  Inform
//
//  Created by Andrew Hunter on 04/09/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "IFProjectPolicy.h"
#import "IFProjectPane.h"


@implementation IFProjectPolicy

// = Initialisation =

- (id) initWithProjectController: (IFProjectController*) controller {
	self = [super init];
	
	if (self) {
		projectController = controller; // NOT retained; avoids loops
		redirectToDocs = NO;
	}
	
	return self;
}

// = Setting up =

- (void) setProjectController: (IFProjectController*) controller {
	projectController = controller;
}

- (IFProjectController*) projectController {
	return projectController;
}

- (void) setRedirectToDocs: (BOOL) redirect {
	redirectToDocs = redirect;
}

- (BOOL) redirectToDocs {
	return redirectToDocs;
}

// = Our life as a policy delegate =

- (void)					webView: (WebView *)sender 
	decidePolicyForNavigationAction: (NSDictionary *)actionInformation 
							request: (NSURLRequest *)request 
							  frame: (WebFrame *)frame 
				   decisionListener: (id<WebPolicyDecisionListener>)listener {
	// Blah. Link failure if WebKit isn't available here. Constants aren't weak linked
	
	// Double blah. WebNavigationTypeLinkClicked == null, but the action value == 0. Bleh
	if ([[actionInformation objectForKey: WebActionNavigationTypeKey] intValue] == 0) {
		NSURL* url = [request URL];
		
		// Source file redirects
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
			
			// sourceLine can have format 'line10' or '10'. 'line10' is more likely
			int lineNumber = [sourceLine intValue];
			
			if (lineNumber == 0 && [[sourceLine substringToIndex: 4] isEqualToString: @"line"]) {
				lineNumber = [[sourceLine substringFromIndex: 4] intValue];
			}
			
			// Move to the appropriate place in the file
			if (![projectController selectSourceFile: sourceFile]) {
				NSLog(@"Can't select source file '%@'", sourceFile);
				return;
			}			
			
			if (lineNumber >= 0) [projectController moveToSourceFileLine: lineNumber];
			[projectController removeHighlightsOfStyle: IFLineStyleHighlight];
			[projectController highlightSourceFileLine: lineNumber
												inFile: sourceFile
												 style: IFLineStyleHighlight];
			
			// Finished
			return;
		}
		
		// General redirects
		if (redirectToDocs) {
			NSURL* absolute1 = [[[request URL] absoluteURL] standardizedURL];
			NSURL* absolute2 = [[[[[frame dataSource] request] URL] absoluteURL] standardizedURL];

			// We only redirect if the page is different to the current one
			if (!([[absolute1 scheme] caseInsensitiveCompare: [absolute2 scheme]] == 0 &&
				  [[absolute1 path] caseInsensitiveCompare: [absolute2 path]] == 0 &&
				  ([absolute1 query] == [absolute2 query] || [[absolute1 query] caseInsensitiveCompare:[absolute2 query]] == 0))) {			
				[listener ignore];
				[[projectController auxPane] openURL: [[[request URL] copy] autorelease]];
				
				return;
			}
		}
	}
	
	// default action
	[listener use];
}

@end
