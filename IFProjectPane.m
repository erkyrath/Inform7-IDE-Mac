//
//  IFProjectPane.m
//  Inform
//
//  Created by Andrew Hunter on Wed Sep 10 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFProjectPane.h"
#import "IFProject.h"
#import "IFProjectController.h"
#import "IFAppDelegate.h"
#import "IFPretendWebView.h"

#import "IFIsFiles.h"
#import "IFIsWatch.h"

#import "IFPreferences.h"

#import "IFJSProject.h"
#import "IFRuntimeErrorParser.h"
#import "IFMaintenanceTask.h"

#import "IFBreadcrumbControl.h"
#import "IFGlkResources.h"
#import "IFViewAnimator.h"

// Approximate maximum length of file to highlight in one 'iteration'
#define minHighlightAmount 2048
#define maxHighlightAmount 2048
#undef  showHighlighting        // Show what's being highlighted
#undef  highlightAll            // Always highlight the entire file (does not necessarily recalculate all highlighting)

NSDictionary* IFSyntaxAttributes[256];

@implementation IFProjectPane

+ (IFProjectPane*) standardPane {
    return [[[self alloc] init] autorelease];
}

+ (void) initialize {
    NSFont* systemFont       = [NSFont systemFontOfSize: 11];
    NSFont* smallFont        = [NSFont boldSystemFontOfSize: 9];
    NSFont* boldSystemFont   = [NSFont boldSystemFontOfSize: 11];
    NSFont* headerSystemFont = [NSFont boldSystemFontOfSize: 12];
    NSFont* monospaceFont    = [NSFont fontWithName: @"Monaco"
                                               size: 9];
	
	[[ZoomPreferences globalPreferences] setDisplayWarnings: YES];
	    
    // Default style
    NSDictionary* defaultStyle = [[NSDictionary dictionaryWithObjectsAndKeys:
        systemFont, NSFontAttributeName, 
        [NSColor blackColor], NSForegroundColorAttributeName,
        nil] retain];
    int x;
    
    for (x=0; x<256; x++) {
        IFSyntaxAttributes[x] = defaultStyle;
    }
    
    // This set of styles will eventually be the 'colourful' set
    // We also need a 'no styles' set (probably just turn off the highlighter, gives
    // speed advantages), and a 'subtle' set (styles indicated only by font changes)
    
    // Styles for various kinds of code
    IFSyntaxAttributes[IFSyntaxString] = [[NSDictionary dictionaryWithObjectsAndKeys:
        systemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.53 green: 0.08 blue: 0.08 alpha: 1.0], NSForegroundColorAttributeName,
		[NSNumber numberWithInt: 0], NSLigatureAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxComment] = [[NSDictionary dictionaryWithObjectsAndKeys:
        smallFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.14 green: 0.43 blue: 0.14 alpha: 1.0], NSForegroundColorAttributeName,
		[NSNumber numberWithInt: 0], NSLigatureAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxMonospace] = [[NSDictionary dictionaryWithObjectsAndKeys:
        monospaceFont, NSFontAttributeName,
        [NSColor blackColor], NSForegroundColorAttributeName,
		[NSNumber numberWithInt: 0], NSLigatureAttributeName,
        nil] retain];
    
    // Inform 6 syntax types
    IFSyntaxAttributes[IFSyntaxDirective] = [[NSDictionary dictionaryWithObjectsAndKeys:
        systemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.20 green: 0.08 blue: 0.53 alpha: 1.0], NSForegroundColorAttributeName,
		[NSNumber numberWithInt: 0], NSLigatureAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxProperty] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.08 green: 0.08 blue: 0.53 alpha: 1.0], NSForegroundColorAttributeName,
		[NSNumber numberWithInt: 0], NSLigatureAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxFunction] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.08 green: 0.53 blue: 0.53 alpha: 1.0], NSForegroundColorAttributeName,
		[NSNumber numberWithInt: 0], NSLigatureAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxCode] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.46 green: 0.06 blue: 0.31 alpha: 1.0], NSForegroundColorAttributeName,
		[NSNumber numberWithInt: 0], NSLigatureAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxAssembly] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.46 green: 0.31 blue: 0.31 alpha: 1.0], NSForegroundColorAttributeName,
		[NSNumber numberWithInt: 0], NSLigatureAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxCodeAlpha] = [[NSDictionary dictionaryWithObjectsAndKeys:
        systemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.4 green: 0.4 blue: 0.3 alpha: 1.0], NSForegroundColorAttributeName,
		[NSNumber numberWithInt: 0], NSLigatureAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxEscapeCharacter] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.73 green: 0.2 blue: 0.73 alpha: 1.0], NSForegroundColorAttributeName,
		[NSNumber numberWithInt: 0], NSLigatureAttributeName,
        nil] retain];
	
	// Natural Inform tab stops
	NSMutableParagraphStyle* tabStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[tabStyle autorelease];

	NSMutableArray* tabStops = [NSMutableArray array];
	for (x=0; x<48; x++) {
		NSTextTab* tab = [[NSTextTab alloc] initWithType: NSLeftTabStopType
												location: 64.0*(x+1)];
		[tabStops addObject: tab];
		[tab release];
	}
	[tabStyle setTabStops: tabStops];
	
    // Natural inform syntax types
	IFSyntaxAttributes[IFSyntaxNaturalInform] = [[NSDictionary dictionaryWithObjectsAndKeys:
        systemFont, NSFontAttributeName, 
        [NSColor blackColor], NSForegroundColorAttributeName,
		tabStyle, NSParagraphStyleAttributeName,
        nil] retain];	
    IFSyntaxAttributes[IFSyntaxHeading] = [[NSDictionary dictionaryWithObjectsAndKeys:
        headerSystemFont, NSFontAttributeName,
		[NSColor blackColor], NSForegroundColorAttributeName,
		tabStyle, NSParagraphStyleAttributeName,
        nil] retain];
	IFSyntaxAttributes[IFSyntaxGameText] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.0 green: 0.3 blue: 0.6 alpha: 1.0], NSForegroundColorAttributeName,
		tabStyle, NSParagraphStyleAttributeName,
        nil] retain];	
	IFSyntaxAttributes[IFSyntaxSubstitution] = [[NSDictionary dictionaryWithObjectsAndKeys:
		systemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.3 green: 0.3 blue: 1.0 alpha: 1.0], NSForegroundColorAttributeName,
		tabStyle, NSParagraphStyleAttributeName,
        nil] retain];	
	
	// The 'plain' style is a bit of a special case. It's used for files that we want to run the syntax
	// highlighter on, but where we want the user to be able to set styles. The user will be able to set
	// certain styles even for things that are affected by the highlighter.
	IFSyntaxAttributes[IFSyntaxPlain] = [[NSDictionary dictionary] retain];
}

- (id) init {
    self = [super init];

    if (self) {
        parent = nil;
        zView = nil;
        gameToRun = nil;
        awake = NO;
        
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(preferencesChanged:)
													 name: IFPreferencesChangedEarlierNotification
												   object: [IFPreferences sharedPreferences]];
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(preferencesChangedQuickly:)
													 name: IFPreferencesDidChangeNotification
												   object: [IFPreferences sharedPreferences]];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(censusCompleted:)
													 name: IFMaintenanceTasksFinished
												   object: nil];
    }

    return self;
}

- (void) dealloc {
	if (gameRunningProgress) {
		[parent removeProgressIndicator: gameRunningProgress];
		[gameRunningProgress release];
		gameRunningProgress = nil;
	}
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    // FIXME: memory leak?
    //    -- Caused by a bug in NSTextView it appears (just creating
    //       anything with an NSTextView causes the same leak).
    //       Doesn't always happen. Not very much memory. Still annoying.
    // (Better in Panther? Looks like it. Definitely fixed in Tiger.)
    [paneView       release];
    [compController release];
	
	[transcriptView setDelegate: nil];
	
	if (indexTabs != nil) {
		[indexTabs setDelegate: nil];
		[indexTabs release];
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
	if (pointToRunTo) [pointToRunTo release];
    if (gameToRun) [gameToRun release];
	if (wView) [wView release];
	
	if (lastAnnotation) [lastAnnotation release];
    
    [super dealloc];
}

+ (NSDictionary*) attributeForStyle: (IFSyntaxStyle) style {
	return [[[IFPreferences sharedPreferences] styles] objectAtIndex: (unsigned)style];
	// return IFSyntaxAttributes[style];
}

- (NSView*) paneView {
    if (!awake) {
        [NSBundle loadNibNamed: @"ProjectPane"
                         owner: self];
    }
    
    return paneView;
}

- (NSView*) activeView {
    switch ([self currentView]) {
        case IFSourcePane:
            return [sourcePage activeView];
        default:
            return [[tabView selectedTabViewItem] view];
    }
}

- (void) removeFromSuperview {
    [paneView removeFromSuperview];
}

- (void) setupFromController {
    IFProject* doc;

    [[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(updateSettings)
												 name: IFSettingNotification
											   object: [[parent document] settings]];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(updatedBreakpoints:)
												 name: IFProjectBreakpointsChangedNotification
											   object: [parent document]];
		
    doc = [parent document];

	// Source page
	sourcePage = [[IFSourcePage alloc] initWithProjectController: parent];
	[sourcePage showSourceFile: [doc mainSourceFile]];
    
	// Compiler
    [compController setCompiler: [doc compiler]];
    [compController setDelegate: self];
	
	// Settings
    [self updateSettings];
	
	// INdex view
	[self updateIndexView];
	
	// The skein view
	[skeinView setSkein: [doc skein]];
	[skeinView setDelegate: parent];

	// (Problem with this is that it updates the menu on every change, which might get to be slow)
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(skeinDidChange:)
												 name: ZoomSkeinChangedNotification
											   object: [doc skein]];
	[self skeinDidChange: nil];
	
	if ([[NSApp delegate] isWebKitAvailable]) {
		[wView setPolicyDelegate: [parent generalPolicy]];
	}
	
	// The transcript
	[[transcriptView layout] setSkein: [doc skein]];
	[transcriptView setDelegate: self];
	
	[wView setUIDelegate: parent];
	[wView setHostWindow: [parent window]];
	
	// Misc stuff
	[sourcePage updateHighlightedLines];
}

- (void) awakeFromNib {
    awake = YES;
	    
	if ((int)[[NSApp delegate] isWebKitAvailable]) {
		// Create the view for the documentation tab
		wView = [[WebView alloc] init];
		[wView setTextSizeMultiplier: [[IFPreferences sharedPreferences] fontSize]];
		[wView setResourceLoadDelegate: self];
		[wView setFrameLoadDelegate: self];
		[docTabView setView: wView];
		[[wView mainFrame] loadRequest: [[[NSURLRequest alloc] initWithURL: [NSURL URLWithString: @"inform:/index.html"]] autorelease]];
	} else {
		wView = nil;
	}
	
    if (parent) {
        [self setupFromController];
        [self stopRunningGame];
    }
	
    [tabView setDelegate: self];
    
    //[sourceText setUsesFindPanel: YES]; -- Not 10.2
}

- (void) setController: (IFProjectController*) p {
    if (!awake) {
        [NSBundle loadNibNamed: @"ProjectPane"
                         owner: self];
    }

    // (Don't need to retain parent, as the parent 'owns' us)
    // Don't need to release for similar reasons.
    parent = p;

    if (awake) {
        [self setupFromController];
    }
}

- (void) selectView: (enum IFProjectPaneType) pane {
    if (!awake) {
        [NSBundle loadNibNamed: @"ProjectPane"
                         owner: self];
    }
    
    NSTabViewItem* toSelect = nil;
    switch (pane) {
        case IFSourcePane:
            toSelect = sourceView;
            break;

        case IFErrorPane:
            toSelect = errorsView;
            break;

        case IFGamePane:
            toSelect = gameTabView;
            break;

        case IFDocumentationPane:
            toSelect = docTabView;
            break;
			
		case IFIndexPane:
			toSelect = indexTabView;
			break;
			
		case IFSkeinPane:
			toSelect = skeinTabView;
			break;
			
		case IFTranscriptPane:
			toSelect = transcriptTabView;
			break;
			
		case IFUnknownPane:
			// No idea
			break;
    }

    if (toSelect) {
        [tabView selectTabViewItem: toSelect];
    } else {
        NSLog(@"Unable to select pane");
    }
}

- (enum IFProjectPaneType) currentView {
    NSTabViewItem* selectedView = [tabView selectedTabViewItem];

    if (selectedView == sourceView) {
        return IFSourcePane;
    } else if (selectedView == errorsView) {
        return IFErrorPane;
    } else if (selectedView == gameTabView) {
        return IFGamePane;
    } else if (selectedView == docTabView) {
        return IFDocumentationPane;
	} else if (selectedView == indexTabView) {
		return IFIndexPane;
	} else if (selectedView == skeinTabView) {
		return IFSkeinPane;
	} else if (selectedView == transcriptTabView) {
		return IFTranscriptPane;
    } else {
        return IFSourcePane;
    }
}

- (void) errorMessageHighlighted: (IFCompilerController*) sender
                          atLine: (int) line
                          inFile: (NSString*) file {
    if (![parent selectSourceFile: file]) {
        // Maybe implement me: show an error alert?
        return;
    }
    
    [parent moveToSourceFileLine: line];
	[parent removeHighlightsOfStyle: IFLineStyleError];
    [parent highlightSourceFileLine: line
							 inFile: [sourcePage openSourceFile]
							  style: IFLineStyleError]; // FIXME: error level?. Filename?
}

- (BOOL) handleURLRequest: (NSURLRequest*) req {
	[[parent auxPane] openURL: [[[req URL] copy] autorelease]];
	
	return YES;
}

- (IFCompilerController*) compilerController {
    return compController;
}

// = The source view =

- (void) prepareToCompile {
	[sourcePage prepareToCompile];
}

- (IFSourcePage*) sourcePage {
	return sourcePage;
}

// = Settings =

- (void) updateSettings {
	if (!parent) {
		return; // Nothing to do
	}
	
	[parent willNeedRecompile: nil];
	
	[settingsController setCompilerSettings: [[parent document] settings]];
	[settingsController updateAllSettings];
	
	return;
}

// = The game view =

- (void) preferencesChangedQuickly: (NSNotification*) not {
	[skeinView setItemWidth: floorf([[IFPreferences sharedPreferences] skeinSpacingHoriz])];
	[skeinView setItemHeight: floorf([[IFPreferences sharedPreferences] skeinSpacingVert])];
}
	
- (void) preferencesChanged: (NSNotification*) not {
	[zView setScaleFactor: 1.0/[[IFPreferences sharedPreferences] fontSize]];
	[wView setTextSizeMultiplier: [[IFPreferences sharedPreferences] fontSize]];
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
    
    if (gameToRun) [gameToRun release];
    gameToRun = [fileName copy];
	
	if (!gameRunningProgress) {
		gameRunningProgress = [[IFProgress alloc] init];
		[parent addProgressIndicator: gameRunningProgress];
	}
    
	[gameRunningProgress setMessage: [[NSBundle mainBundle] localizedStringForKey: @"Loading story file"
																			value: @"Loading story file"
																			table: nil]];
	
	if ([[gameToRun pathExtension] isEqualToString: @"ulx"]) {
		// Screws up the first responder, will cause the GlkView object to force a new first responder after it starts
		[[parent window] makeFirstResponder: [parent window]];

		// Start running as a glulxe task
		gView = [[GlkView alloc] init];
		[gView setDelegate: self];
		[gView addOutputReceiver: parent];
		[gView setImageSource: [[[IFGlkResources alloc] initWithProject: [parent document]] autorelease]];
		
		[gView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
		[gView setFrame: [gameView bounds]];
		[gameView addSubview: gView];
		
		[gView setInputFilename: fileName];
		[gView launchClientApplication: [[NSBundle mainBundle] pathForResource: @"glulxe"
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
		
		[skeinView setItemWidth: floorf([[IFPreferences sharedPreferences] skeinSpacingHoriz])];
		[skeinView setItemHeight: floorf([[IFPreferences sharedPreferences] skeinSpacingVert])];
		
		[zView setFrame: [gameView bounds]];
		[zView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
		[gameView addSubview: zView];
	}
}

- (void) setPointToRunTo: (ZoomSkeinItem*) item {
	if (pointToRunTo) [pointToRunTo release];
	pointToRunTo = [item retain];
}

- (void) stopRunningGame {
    if (zView) {
		[zView killTask];
    }
	
	if (gView) {
		[gView terminateClient];
	}
    
    if ([tabView selectedTabViewItem] == gameTabView) {
        [tabView selectTabViewItem: errorsView];
    }
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
    [tabView selectTabViewItem: gameTabView];
	
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
	} else {
		[parent transcriptToPoint: [[[parent document] skein] rootItem]];
	}
	
    [tabView selectTabViewItem: gameTabView];
    [[paneView window] makeFirstResponder: [zView textView]];
	
	[gameRunningProgress setMessage: [[NSBundle mainBundle] localizedStringForKey: @"Story started"
																			value: @"Story started"
																			table: nil]];
	[parent removeProgressIndicator: gameRunningProgress];
	[gameRunningProgress release];
	gameRunningProgress = nil;
}

// = Tab view delegate =

- (BOOL)            tabView: (NSTabView *)view 
    shouldSelectTabViewItem:(NSTabViewItem *)item {
	// Do nothing if this is the index tab view
	if (view == indexTabs) {
		return YES;
	}
		
	// Assume we're in the main tab view otherwise
    if (item == gameTabView && (zView == nil && gView == nil)) {
        // FIXME: if another view is running a game, then display the tabView in there
        return NO;
    }
	
	if (item == indexTabView && !indexAvailable) {
		return NO;
	}

    return YES;
}

-  (void)			tabView:(NSTabView *)view 
	   didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	if (view == indexTabs) {
		// Do nothing if something mechanical may be changing the selection
		if (indexMachineSelection > 0) return;
		
		// Store this as the last 'user-selected' tab view item
		[lastUserTab release];
		lastUserTab = [[tabViewItem label] retain];
	}
}

// == Debugging ==

- (void) hitBreakpoint: (int) pc {
	[[IFIsWatch sharedIFIsWatch] refreshExpressions];
	[parent hitBreakpoint: pc];
}

- (void) zoomWaitingForInput {
	[[IFIsWatch sharedIFIsWatch] refreshExpressions];
}

// == Documentation ==

- (void) openURL: (NSURL*) url  {
	[tabView selectTabViewItem: docTabView];

	[[wView mainFrame] loadRequest: [[[NSURLRequest alloc] initWithURL: url] autorelease]];
}

// = The index view =

- (BOOL) canSelectIndexTab: (int) whichTab {
	if ([indexTabs indexOfTabViewItemWithIdentifier: [NSNumber numberWithInt: whichTab]] == NSNotFound) {
		return NO;
	} else {
		return YES;
	}
}

- (void) selectIndexTab: (int) whichTab {
	int tabIndex = [indexTabs indexOfTabViewItemWithIdentifier: [NSNumber numberWithInt: whichTab]];
	
	if (tabIndex != NSNotFound) {
		[indexTabs selectTabViewItemAtIndex: tabIndex];
	}
}

- (void) updateIndexView {
	indexAvailable = NO;
	
	if (![IFAppDelegate isWebKitAvailable]) return;
	
	// The index path
	NSString* indexPath = [NSString stringWithFormat: @"%@/Index", [[parent document] fileName]];
	BOOL isDir = NO;
	
	// Check that it exists and is a directory
	if (indexPath == nil) return;
	if (![[NSFileManager defaultManager] fileExistsAtPath: indexPath
											  isDirectory: &isDir]) return;
	if (!isDir) return;		
	
	// Create the tab view that will eventually go into the main view
	indexMachineSelection++;
		
	if (indexTabs != nil) {
		[indexTabs setDelegate: nil];
		[indexTabs removeFromSuperview];
		[indexTabs release];
		indexTabs = nil;
	}
	
	indexTabs = [[NSTabView alloc] initWithFrame: [indexView bounds]];
	[indexTabs setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
	[indexView addSubview: indexTabs];
	
	[indexTabs setDelegate: self];
	
	[indexTabs setControlSize: NSSmallControlSize];
	[indexTabs setFont: [NSFont systemFontOfSize: 10]];
	[indexTabs setAllowsTruncatedLabels: YES];

	// Iterate through the files
	NSArray* files = [[NSFileManager defaultManager] directoryContentsAtPath: indexPath];
	NSEnumerator* fileEnum = [files objectEnumerator];
	NSString* theFile;
	
	NSBundle* mB = [NSBundle mainBundle];
	
	while (theFile = [fileEnum nextObject]) {
		NSString* extension = [[theFile pathExtension] lowercaseString];
		NSString* fullPath = [indexPath stringByAppendingPathComponent: theFile];
		
		NSTabViewItem* userTab = nil;
		
		if ([extension isEqualToString: @"htm"] ||
			[extension isEqualToString: @"html"] ||
			[extension isEqualToString: @"skein"]) {
			// Create a parent view
			NSView* fileView = [[NSView alloc] init];
			[fileView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
			[fileView autorelease];
			
			// Create a 'fake' web view which will get replaced when the view is actually displayed on screen
			IFPretendWebView* pretendView = [[IFPretendWebView alloc] initWithFrame: [fileView bounds]];
			
			[pretendView setHostWindow: [paneView window]];
			[pretendView setRequest: [[[NSURLRequest alloc] initWithURL: [IFProjectPolicy fileURLWithPath: fullPath]] autorelease]];
			[pretendView setPolicyDelegate: [parent docPolicy]];
			
			[pretendView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
			
			// Add it to fileView
			[fileView addSubview: [pretendView autorelease]];
			
			// Create the tab to put this view in
			NSTabViewItem* newTab = [[[NSTabViewItem alloc] init] autorelease];
			
			[newTab setView: fileView];
			
			NSString* label = [mB localizedStringForKey: theFile
												  value: [theFile stringByDeletingPathExtension]
												  table: @"CompilerOutput"];
			[newTab setLabel: label];
			
			// Choose an ID for this tab based on the filename
			int tabId = 0;
			NSString* lowerFile = [theFile lowercaseString];

			if ([lowerFile isEqualToString: @"actions.html"]) tabId = IFIndexActions;
			else if ([lowerFile isEqualToString: @"phrasebook.html"]) tabId = IFIndexPhrasebook;
			else if ([lowerFile isEqualToString: @"scenes.html"]) tabId = IFIndexScenes;
			else if ([lowerFile isEqualToString: @"contents.html"]) tabId = IFIndexContents;
			else if ([lowerFile isEqualToString: @"kinds.html"]) tabId = IFIndexKinds;
			else if ([lowerFile isEqualToString: @"rules.html"]) tabId = IFIndexRules;
			else if ([lowerFile isEqualToString: @"world.html"]) tabId = IFIndexWorld;
			
			[newTab setIdentifier: [NSNumber numberWithInt: tabId]];
			
			// Check if this was the last tab being viewed by the user
			if (lastUserTab != nil && [label caseInsensitiveCompare: lastUserTab] == NSOrderedSame) {
				userTab = newTab;
			}
			
			// Add the tab
			[indexTabs addTabViewItem: newTab];
			indexAvailable = YES;
		}
		
		if (userTab != nil) {
			[indexTabs selectTabViewItem: userTab];
		}
	}

	indexMachineSelection--;
}

// = WebResourceLoadDelegate methods =

- (void)			webView:(WebView *)sender 
				   resource:(id)identifier 
	didFailLoadingWithError:(NSError *)error 
			 fromDataSource:(WebDataSource *)dataSource {
	NSLog(@"IFProjectPane: failed to load page with error: %@", [error localizedDescription]);
}

// = WebFrameLoadDelegate methods =

- (void)					webView:(WebView *)sender
		windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject {
	// Attach the JavaScript object to the opposing view
	IFProjectPane* otherPane = [parent oppositePane: self];		
	IFJSProject* js = [[IFJSProject alloc] initWithPane: otherPane];

	// Attach it to the script object
	[[sender windowScriptObject] setValue: [js autorelease]
								   forKey: @"Project"];
}


// = The skein view =

- (ZoomSkeinView*) skeinView {
	return skeinView;
}

- (void) skeinDidChange: (NSNotification*) not {
	[[[parent document] skein] populatePopupButton: skeinLabelButton];
	[skeinLabelButton selectItem: nil];
}

- (void) clearSkeinDidEnd: (NSWindow*) sheet
			   returnCode: (int) returnCode
			  contextInfo: (void*) contextInfo {
	if (returnCode == NSAlertAlternateReturn) {
		ZoomSkein* skein = [[parent document] skein];
		
		[skein removeTemporaryItems: 0];
		[skein zoomSkeinChanged];
	}
}

- (IBAction) performPruning: (id) sender {
	if ([sender tag] == 1) {
		// Perform the pruning
		ZoomSkein* skein = [[parent document] skein];

		int pruning = 31 - [pruneAmount floatValue];
		if (pruning < 1) pruning = 1;
		
		[skein removeTemporaryItems: pruning];
		[skein zoomSkeinChanged];
	}
	
	// Finish with the sheet
	[NSApp stopModal];
}

- (IBAction) pruneSkein: (id) sender {
	// Set the slider to a default value (prune a little - this is only a little harsher than the auto-pruning)
	[pruneAmount setFloatValue: 10.0];
	
	// Run the 'prune skein' sheet
	[NSApp beginSheet: pruneSkein
	   modalForWindow: [skeinView window]
		modalDelegate: self
	   didEndSelector: nil
		  contextInfo: nil];
	[NSApp runModalForWindow: [skeinView window]];
	[NSApp endSheet: pruneSkein];
	[pruneSkein orderOut: self];
}

- (IBAction) performSkeinLayout: (id) sender {
	// The user has clicked a button indicating she wants to change the skein layout
	
	// Set up the sliders
	[skeinHoriz setFloatValue: [[IFPreferences sharedPreferences] skeinSpacingHoriz]];
	[skeinVert setFloatValue: [[IFPreferences sharedPreferences] skeinSpacingVert]];
	
	// Run the 'layout skein' sheet
	[NSApp beginSheet: skeinSpacing
	   modalForWindow: [skeinView window]
		modalDelegate: self
	   didEndSelector: nil
		  contextInfo: nil];
	[NSApp runModalForWindow: [skeinView window]];
	[NSApp endSheet: skeinSpacing];
	[skeinSpacing orderOut: self];
}

- (IBAction) skeinLayoutOk: (id) sender {
	// The user has confirmed her new skein layout
	[NSApp stopModal];
}

- (IBAction) useDefaultSkeinLayout: (id) sender {
	// The user has clicked a button indicating she wants to use the default skein layout
	[skeinHoriz setFloatValue: 120.0];
	[skeinVert setFloatValue: 96.0];
	
	[self updateSkeinLayout: sender];
}

- (IBAction) updateSkeinLayout: (id) sender {
	// The user has dragged one of the skein layout sliders
	[[IFPreferences sharedPreferences] setSkeinSpacingHoriz: [skeinHoriz floatValue]];
	[[IFPreferences sharedPreferences] setSkeinSpacingVert: [skeinVert floatValue]];
}

- (IBAction) skeinLabelSelected: (id) sender {
	NSString* annotation = [[sender selectedItem] title];
	
	// Reset the annotation count if required
	if (![annotation isEqualToString: lastAnnotation]) {
		annotationCount = 0;
	}
	
	[lastAnnotation release];
	lastAnnotation = [annotation retain];
	
	// Get the list of items for this annotation
	NSArray* availableItems = [[[parent document] skein] itemsWithAnnotation: lastAnnotation];
	if (!availableItems || [availableItems count] == 0) return;
		
	// Reset the annotation count if required
	if ([availableItems count] <= annotationCount) annotationCount = 0;

	// Scroll to the appropriate item
	[skeinView scrollToItem: [availableItems objectAtIndex: annotationCount]];
	
	// Will scroll to the next item in the list if there's more than one
	annotationCount++;
}

// = The transcript view =

- (IFTranscriptLayout*) transcriptLayout {
	return [transcriptView layout];
}

- (IFTranscriptView*) transcriptView {
	return transcriptView;
}

- (void) transcriptPlayToItem: (ZoomSkeinItem*) itemToPlayTo {
	ZoomSkein* skein = [[parent document] skein];
	ZoomSkeinItem* activeItem = [skein activeItem];
	
	ZoomSkeinItem* firstPoint = nil;
	
	// See if the active item is a parent of the point we're playing to (in which case, continue playing. Otherwise, restart and play to that point)
	ZoomSkeinItem* parentItem = [itemToPlayTo parent];
	while (parentItem) {
		if (parentItem == activeItem) {
			firstPoint = activeItem;
			break;
		}
		
		parentItem = [parentItem parent];
	}
	
	if (firstPoint == nil) {
		[parent restartGame];
		firstPoint = [skein rootItem];
	}
	
	// Play to this point
	[parent playToPoint: itemToPlayTo
			  fromPoint: firstPoint];
}

- (void) transcriptShowKnot: (ZoomSkeinItem*) knot {
	// Switch to the skein view
	IFProjectPane* skeinPane = [parent skeinPane];
	
	[skeinPane selectView: IFSkeinPane];
	
	// Scroll to the knot
	[skeinPane->skeinView scrollToItem: knot];
}

- (IBAction) transcriptBlessAll: (id) sender {
	// Display a confirmation dialog (as this can't be undone. Well, not easily)
	NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"Are you sure you want to bless all these items?"
															 value: @"Are you sure you want to bless all these items?"
															 table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"Cancel"
															 value: @"Cancel"
															 table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"Bless All"
															 value: @"Bless All"
															 table: nil],
					  nil, [transcriptView window], self, 
					  @selector(transcriptBlessAllDidEnd:returnCode:contextInfo:), nil,
					  nil, [[NSBundle mainBundle] localizedStringForKey: @"Bless all explanation"
																  value: @"Bless all explanation"
																  table: nil]);
}

- (void) transcriptBlessAllDidEnd: (NSWindow*) sheet
					   returnCode: (int) returnCode
					  contextInfo: (void*) contextInfo {
	if (returnCode == NSAlertAlternateReturn) {
		[transcriptView blessAll];
	} else {
	}
}

// = Breakpoints =

- (IBAction) setBreakpoint: (id) sender {
	// Sets a breakpoint at the current location in the current source file
	
	// If we're not at the source pane, then do nothing
	if ([self currentView] != IFSourcePane) return;
	
	// Work out which file and line we're in
	NSString* currentFile = [sourcePage currentFile];
	int currentLine = [sourcePage currentLine];
	
	if (currentLine >= 0) {
		NSLog(@"Added breakpoint at %@:%i", currentFile, currentLine);
		
		[[parent document] addBreakpointAtLine: currentLine
										inFile: currentFile];
	}
}

- (IBAction) deleteBreakpoint: (id) sender {
	// Sets a breakpoint at the current location in the current source file
	
	// If we're not at the source pane, then do nothing
	if ([self currentView] != IFSourcePane) return;
	
	// Work out which file and line we're in
	NSString* currentFile = [sourcePage currentFile];
	int currentLine = [sourcePage currentLine];
	
	if (currentLine >= 0) {
		NSLog(@"Deleted breakpoint at %@:%i", currentFile, currentLine);
		
		[[parent document] removeBreakpointAtLine: currentLine
										   inFile: currentFile];
	}	
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
	// Can't add breakpoints if we're not showing the source view
	// (Moot: this never gets called at any point where it is useful at the moment)
	if ([menuItem action] == @selector(setBreakpoint:) ||
		[menuItem action] == @selector(deleteBreakpoint:)) {
		return [self currentView]==IFSourcePane;
	}
	
	return YES;
}

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

- (NSTabView*) tabView {
	return tabView;
}

// = Find =

- (void) performFindPanelAction: (id) sender {
	NSLog(@"Bing!");
}

// = Updating extensions =

- (void) censusCompleted: (NSNotification*) not {
	// Force the documentation view to reload (the 'installed extensions' page may be updated)
	[wView reload: self];
}

// = Debugging =

#if 0

- (void) addTestControls {
	NSTabViewItem* testTab = [[NSTabViewItem alloc] init];
	
	[testTab setLabel: @"Testing"];
	[tabView addTabViewItem: testTab];
	
	// Add a test breadcrumb control
	IFBreadcrumbControl* testBreadcrumb = [[IFBreadcrumbControl alloc] initWithFrame: NSMakeRect(20, 20, 300, 32)];
	
	[testBreadcrumb addBreadcrumbWithText: @"*" tag: 0];
	[testBreadcrumb addBreadcrumbWithText: @"Some thing..." tag: 0];
	[testBreadcrumb addBreadcrumbWithText: @"Something else" tag: 0];
	[testBreadcrumb addBreadcrumbWithText: @"The end" tag: 0];
	
	[[testTab view] addSubview: testBreadcrumb];
}

#endif

@end
