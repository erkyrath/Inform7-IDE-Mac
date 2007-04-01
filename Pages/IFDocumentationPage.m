//
//  IFDocumentationPage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFDocumentationPage.h"
#import "IFJSProject.h"
#import "IFPreferences.h"
#import "IFMaintenanceTask.h"
#import "IFAppDelegate.h"


@implementation IFDocumentationPage

// = Initialisation =

- (id) initWithProjectController: (IFProjectController*) controller {
	self = [super initWithNibName: @"Errors"
				projectController: controller];
	
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(preferencesChanged:)
													 name: IFPreferencesChangedEarlierNotification
												   object: [IFPreferences sharedPreferences]];
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(censusCompleted:)
													 name: IFMaintenanceTasksFinished
												   object: nil];
		
		if ((int)[[NSApp delegate] isWebKitAvailable]) {
			// Create the view for the documentation tab
			wView = [[WebView alloc] init];
			[wView setTextSizeMultiplier: [[IFPreferences sharedPreferences] fontSize]];
			[wView setResourceLoadDelegate: self];
			[wView setFrameLoadDelegate: self];
			
			[wView setFrame: [view bounds]];
			[wView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
			[view addSubview: wView];
			
			[[wView mainFrame] loadRequest: [[[NSURLRequest alloc] initWithURL: [NSURL URLWithString: @"inform:/index.html"]] autorelease]];
		} else {
			wView = nil;
		}		
		
		if ([[NSApp delegate] isWebKitAvailable]) {
			[wView setPolicyDelegate: [parent generalPolicy]];
			
			[wView setUIDelegate: parent];
			[wView setHostWindow: [parent window]];
		}
	}
	
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	if (wView) [wView release];
    
	[super dealloc];
}

// = Details about this view =

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Documentation Page Title"
												  value: @"Documentation"
												  table: nil];
}

// = Updating extensions =

- (void) censusCompleted: (NSNotification*) not {
	// Force the documentation view to reload (the 'installed extensions' page may be updated)
	[wView reload: self];
}

// = Preferences =

- (void) preferencesChanged: (NSNotification*) not {
	[wView setTextSizeMultiplier: [[IFPreferences sharedPreferences] fontSize]];
}

// = Documentation =

- (void) openURL: (NSURL*) url  {
	[self switchToPage];
	
	[[wView mainFrame] loadRequest: [[[NSURLRequest alloc] initWithURL: url] autorelease]];
}

// = WebResourceLoadDelegate methods =

- (void)			webView:(WebView *)sender 
				   resource:(id)identifier 
	didFailLoadingWithError:(NSError *)error 
			 fromDataSource:(WebDataSource *)dataSource {
	NSLog(@"IFDocumentationPage: failed to load page with error: %@", [error localizedDescription]);
}

// = WebFrameLoadDelegate methods =

- (void)					webView:(WebView *)sender
		windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject {
	if (otherPane) {
		// Attach the JavaScript object to the opposing view
		IFJSProject* js = [[IFJSProject alloc] initWithPane: otherPane];
		
		// Attach it to the script object
		[[sender windowScriptObject] setValue: [js autorelease]
									   forKey: @"Project"];
	}
}

@end
