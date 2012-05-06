//
//  IFGamePage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFGamePage.h"
#import "IFErrorsPage.h"
#import "IFPreferences.h"
#import "IFGlkResources.h"
#import "IFRuntimeErrorParser.h"
#import "IFIsWatch.h"
#import "IFTestMe.h"
#import "IFWebUriProtocol.h"

@interface IFGamePage(Private)

- (void) updatedBreakpoints: (NSNotification*) not;

@end

@implementation IFGamePage

// = Initialisation =

- (id) initWithProjectController: (IFProjectController*) controller {
	self = [super initWithNibName: @"Game"
				projectController: controller];
	
	if (self) {
        zView = nil;
        gameToRun = nil;		
		
		// Register for breakpoints updates
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(updatedBreakpoints:)
													 name: IFProjectBreakpointsChangedNotification
												   object: [parent document]];
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(preferencesChanged:)
													 name: IFPreferencesChangedEarlierNotification
												   object: [IFPreferences sharedPreferences]];
	}
	
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	if (gameRunningProgress) {
		[parent removeProgressIndicator: gameRunningProgress];
		[gameRunningProgress release];
		gameRunningProgress = nil;
	}
		
    if (zView) {
		[zView setDelegate: nil];
		[zView killTask];
		[zView release];
	}
	if (gView) {
		[gView setDelegate: nil];
		[gView terminateClient];
		[gView release];
		gView = nil;
	}
    if (wView) {
        [wView release];
        wView = nil;
        scriptObject = nil;
    }
	if (pointToRunTo) [pointToRunTo release];
    if (gameToRun) [gameToRun release];

	[super dealloc];
}

// = Details about this view =

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Game Page Title"
												  value: @"Game"
												  table: nil];
}

// = Page validation =

- (BOOL) shouldShowPage {
	return zView != nil || gView != nil || wView != nil;
}

// = The game view =

- (void) preferencesChanged: (NSNotification*) not {
	[zView setScaleFactor: 1.0/[[IFPreferences sharedPreferences] fontSize]];
	[gView setScaleFactor: [[IFPreferences sharedPreferences] fontSize]];
}

- (void) activateDebug {
	setBreakpoint = YES;
}

- (void) startRunningGame: (NSString*) fileName {
	[[[parent document] skein] zoomInterpreterRestart];
	
    if (zView) {
		[zView killTask];
        [zView removeFromSuperview];
        [zView release];
        zView = nil;
    }
	
	if (gView) {
		[gView terminateClient];
		[gView removeFromSuperview];
		[gView release];
		gView = nil;
	}
    
    if (wView) {
        [wView removeFromSuperview];
        [wView release];
        wView = nil;
        scriptObject = nil;
    }
    
    if (gameToRun) [gameToRun release];
    gameToRun = [fileName copy];
	
	if (!gameRunningProgress) {
		gameRunningProgress = [[IFProgress alloc] init];
		[parent addProgressIndicator: gameRunningProgress];
	}
    
	[gameRunningProgress setMessage: [[NSBundle mainBundle] localizedStringForKey: @"Loading story file"
																			value: @"Loading story file"
																			table: nil]];
    
    // Fetch the z-code version set in the document settings
    int zcodeVersion = [[[parent document] settings] zcodeVersion];
    
    if (zcodeVersion == 257) {
        // Run in a web view
        
        // Get the name of the game folder
        NSString* gameFolder = [fileName stringByDeletingLastPathComponent];
        
        // Register the runtime URL, one level up from the game folder
        if (runtimeUrl == nil) {
            runtimeUrl = [IFWebUriProtocol registerFolder: [[[gameFolder stringByDeletingLastPathComponent] lastPathComponent] stringByDeletingPathExtension]
                                                   atPath: [NSURL fileURLWithPath: gameFolder]];
        }
        
        // Get the URL to play (runtimeUrl/play.html)
        NSURL* playUrl = [runtimeUrl URLByAppendingPathComponent: @"play.html"];
        
        // Create a new web view
        wView = [[WebView alloc] initWithFrame: [view bounds]];

        [wView setResourceLoadDelegate: self];
        [wView setFrameLoadDelegate: self];

        // Add to the view
		[wView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
		[wView setFrame: [view bounds]];
        [view addSubview: wView];
        
        // Load the request
        NSLog(@"Using Web interpreter '%@'", [playUrl absoluteString]);
        [wView setMainFrameURL: [playUrl absoluteString]];
        
        // Set this view as active
        [self switchToPage];
        [[parent window] makeFirstResponder: wView];
        
        [parent removeProgressIndicator: gameRunningProgress];
        [gameRunningProgress release];
        gameRunningProgress = nil;
    }
	
	else if ([[gameToRun pathExtension] isEqualToString: @"ulx"]) {
        // Run as a glulx task
		IFRuntimeErrorParser* runtimeErrors = [[[IFRuntimeErrorParser alloc] init] autorelease];
		[runtimeErrors setDelegate: parent];

		// Screws up the first responder, will cause the GlkView object to force a new first responder after it starts
		[[parent window] makeFirstResponder: [parent window]];
		
		// Work out the default client to use
		NSString*		clientName = [[IFPreferences sharedPreferences] glulxInterpreter];
		NSLog(@"Using glulx interpreter '%@'", clientName);
		
		// Start running as a glulxe task
		gView = [[GlkView alloc] init];
		[gView setDelegate: self];
		[gView addOutputReceiver: parent];
		[gView addOutputReceiver: runtimeErrors];
		
		[gView setImageSource: [[[IFGlkResources alloc] initWithProject: [parent document]] autorelease]];
		
		[gView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
		[gView setFrame: [view bounds]];
		[view addSubview: gView];
		
		[gView setScaleFactor: [[IFPreferences sharedPreferences] fontSize]];
		
		[gView setInputFilename: fileName];
		[gView launchClientApplication: [[NSBundle mainBundle] pathForResource: clientName
																		ofType: @""
																   inDirectory: @"this/is_a/workaround"]
						 withArguments: nil];
	} else {
		// Start running as a Zoom task
		IFRuntimeErrorParser* runtimeErrors = [[IFRuntimeErrorParser alloc] init];
		
		[runtimeErrors setDelegate: parent];
		
		zView = [[ZoomView allocWithZone: [self zone]] init];
		[zView setDelegate: self];
		[[[parent document] skein] zoomInterpreterRestart];
		[zView addOutputReceiver: [[parent document] skein]];
		[zView addOutputReceiver: runtimeErrors];
		[zView runNewServer: nil];
		
		[zView setColours: [NSArray arrayWithObjects:
			[NSColor colorWithDeviceRed: 0 green: 0 blue: 0 alpha: 1],
			[NSColor colorWithDeviceRed: 1 green: 0 blue: 0 alpha: 1],
			[NSColor colorWithDeviceRed: 0 green: 1 blue: 0 alpha: 1],
			[NSColor colorWithDeviceRed: 1 green: 1 blue: 0 alpha: 1],
			[NSColor colorWithDeviceRed: 0 green: 0 blue: 1 alpha: 1],
			[NSColor colorWithDeviceRed: 1 green: 0 blue: 1 alpha: 1],
			[NSColor colorWithDeviceRed: 0 green: 1 blue: 1 alpha: 1],
			[NSColor colorWithDeviceRed: 1 green: 1 blue: 1 alpha: 1],
			
			[NSColor colorWithDeviceRed: .73 green: .73 blue: .73 alpha: 1],
			[NSColor colorWithDeviceRed: .53 green: .53 blue: .53 alpha: 1],
			[NSColor colorWithDeviceRed: .26 green: .26 blue: .26 alpha: 1],
			nil]];
		
		[zView setScaleFactor: 1.0/[[IFPreferences sharedPreferences] fontSize]];
		
		[zView setFrame: [view bounds]];
		[zView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
		[view addSubview: zView];
	}
}

- (void) setPointToRunTo: (ZoomSkeinItem*) item {
	if (pointToRunTo) [pointToRunTo release];
	pointToRunTo = [item retain];
}

- (void) setTestMe: (BOOL) willTestMe {
	testMe = willTestMe;
}

- (void) stopRunningGame {
    if (zView) {
		[zView killTask];
    }
	
	if (gView) {
		[gView terminateClient];
	}
    
	[self switchToPageWithIdentifier: [[IFErrorsPage class] description]
							fromPage: [self identifier]];
}

- (void) pauseRunningGame {
	if (zView) {
		[zView debugTask];
	}
}

- (ZoomView*) zoomView {
	return zView;
}

- (GlkView*) glkView {
	return gView;
}

- (BOOL) isRunningGame {
	return (zView != nil && [zView isRunning]) || (gView != nil);
}

// (GlkView delegate functions)
- (void) taskHasStarted {
	[self switchToPage];
	
	[parent glkTaskHasStarted: self];
	
	[gameRunningProgress setMessage: [[NSBundle mainBundle] localizedStringForKey: @"Story started"
																			value: @"Story started"
																			table: nil]];
	[parent removeProgressIndicator: gameRunningProgress];
	[gameRunningProgress release];
	gameRunningProgress = nil;	
	
	if (pointToRunTo) {
		[parent transcriptToPoint: pointToRunTo
					  switchViews: NO];
		
		id inputSource = [ZoomSkein inputSourceFromSkeinItem: [[[parent document] skein] rootItem]
													  toItem: pointToRunTo];
		
		[parent setGlkInputSource: inputSource];
		[gView addInputReceiver: parent];
		
		[pointToRunTo release];
		pointToRunTo = nil;
		testMe = NO;
	} else if (testMe) {
		id inputSource = [[[IFTestMe alloc] init] autorelease];
		[parent setGlkInputSource: inputSource];
		[gView addInputReceiver: parent];
	}
}

// (ZoomView delegate functions)

- (void) inputSourceHasFinished: (id) sender {
	[parent inputSourceHasFinished: nil];
}

- (void) zMachineStarted: (id) sender {	
    [[zView zMachine] loadStoryFile: 
        [NSData dataWithContentsOfFile: gameToRun]];
	
	[[zView zMachine] loadDebugSymbolsFrom: [[[[parent document] fileName] stringByAppendingPathComponent: @"Build"] stringByAppendingPathComponent: @"gameinfo.dbg"]
							withSourcePath: [[[parent document] fileName] stringByAppendingPathComponent: @"Source"]];
	
	// Set the initial breakpoint if 'Debug' was selected
	if (setBreakpoint) {
		if (![[zView zMachine] setBreakpointAtName: @"Initialise"]) {
			[[zView zMachine] setBreakpointAtName: @"main"];
		}
	}
	
	// Set the other breakpoints anyway
	int breakpoint;
	for (breakpoint = 0; breakpoint < [[parent document] breakpointCount]; breakpoint++) {
		int line = [[parent document] lineForBreakpointAtIndex: breakpoint];
		NSString* file = [[parent document] fileForBreakpointAtIndex: breakpoint];
		
		if (line >= 0) {
			if (![[zView zMachine] setBreakpointAtName: [NSString stringWithFormat: @"%@:%i", file, line+1]]) {
				NSLog(@"Failed to set breakpoint at %@:%i", file, line+1);
			}
		}
	}
	
	setBreakpoint = NO;
	
	// Run to the appropriate point in the skein
	if (pointToRunTo) {
		[parent transcriptToPoint: pointToRunTo];
		
		id inputSource = [ZoomSkein inputSourceFromSkeinItem: [[[parent document] skein] rootItem]
													  toItem: pointToRunTo];
		
		[zView setInputSource: inputSource];
		
		[pointToRunTo release];
		pointToRunTo = nil;
	} else if (testMe) {
		id inputSource = [[[IFTestMe alloc] init] autorelease];
		[zView setInputSource: inputSource];
	} else {
		[parent transcriptToPoint: [[[parent document] skein] rootItem]];
	}
	
	[self switchToPage];
    [[parent window] makeFirstResponder: [zView textView]];
	
	[gameRunningProgress setMessage: [[NSBundle mainBundle] localizedStringForKey: @"Story started"
																			value: @"Story started"
																			table: nil]];
	[parent removeProgressIndicator: gameRunningProgress];
	[gameRunningProgress release];
	gameRunningProgress = nil;
}

- (NSString*) pathForNamedFile: (NSString*) name {
	// Append .glkdata if the name has no extension
	name = [name lastPathComponent];
	name = [[name stringByDeletingPathExtension] stringByAppendingPathExtension: @"glkdata"];
	
	// Work out the location of the materials directory
	NSString* projectPath	= [[parent document] fileName];
	NSString* materials		= [[parent document] materialsPath];
	
	// Default location is materials/Files
	NSString* filesDir		= [materials stringByAppendingPathComponent: @"Files"];
	
	// Use this directory if it exists
	BOOL isDir;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: filesDir
													   isDirectory: &isDir];
	
	if (exists && isDir) {
		// Use the files directory
		return [filesDir stringByAppendingPathComponent: name];
	} else {
		// Use the directory the project is in
		return [[projectPath stringByDeletingLastPathComponent] stringByAppendingPathComponent: name];
	}
}

// = Breakpoints =

- (void) updatedBreakpoints: (NSNotification*) not {
	// Give up if there's no Z-Machine running
	if (!zView) return;
	if (![zView zMachine]) return;
	
	// Clear out the old breakpoints
	[[zView zMachine] removeAllBreakpoints];
	
	// Set the breakpoints
	int breakpoint;
	for (breakpoint = 0; breakpoint < [[parent document] breakpointCount]; breakpoint++) {
		int line = [[parent document] lineForBreakpointAtIndex: breakpoint];
		NSString* file = [[parent document] fileForBreakpointAtIndex: breakpoint];
		
		if (line >= 0) {
			if (![[zView zMachine] setBreakpointAtName: [NSString stringWithFormat: @"%@:%i", file, line+1]]) {
				NSLog(@"Failed to set breakpoint at %@:%i", file, line+1);
			}
		}
	}
}

// = Debugging =

- (void) hitBreakpoint: (int) pc {
	[[IFIsWatch sharedIFIsWatch] refreshExpressions];
	[parent hitBreakpoint: pc];
}

- (void) zoomWaitingForInput {
	[[IFIsWatch sharedIFIsWatch] refreshExpressions];
}

// = WebResourceLoadDelegate methods =

- (void)			webView:(WebView *)sender 
          resource:(id)identifier 
didFailLoadingWithError:(NSError *)error 
    fromDataSource:(WebDataSource *)dataSource {
	NSLog(@"IFGamePage: failed to load page with error: %@", [error localizedDescription]);
}

// = WebFrameLoadDelegate methods =

- (void)consoleLog:(NSString *)aMessage {
    NSLog(@"IFGamePage Javascript: %@", aMessage);
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
    if (aSelector == @selector(consoleLog:)) {
        return NO;
    }
    
    return YES;
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    if (frame == [frame findFrameNamed:@"_top"]) {
        scriptObject = [sender windowScriptObject];
    }
}

- (void)					webView:(WebView *)sender 
    didStartProvisionalLoadForFrame:(WebFrame *)frame {
}

- (void)					webView:(WebView *)sender
windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject {
    [windowScriptObject setValue:self forKey:@"InformWebView"];
    [windowScriptObject evaluateWebScript:@"console = { log: function(msg) { InformWebView.consoleLog_(msg); } }"];
}

@end
