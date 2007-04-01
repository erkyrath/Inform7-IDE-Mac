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
        awake = NO;
		
		pages = [[NSMutableArray alloc] init];
        
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(preferencesChanged:)
													 name: IFPreferencesChangedEarlierNotification
												   object: [IFPreferences sharedPreferences]];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(censusCompleted:)
													 name: IFMaintenanceTasksFinished
												   object: nil];
    }

    return self;
}

- (void) dealloc {
	[sourcePage release];
	[errorsPage release];
	[indexPage release];
	[skeinPage release];
	[transcriptPage release];
	[gamePage release];
	[pages release];
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    // FIXME: memory leak?
    //    -- Caused by a bug in NSTextView it appears (just creating
    //       anything with an NSTextView causes the same leak).
    //       Doesn't always happen. Not very much memory. Still annoying.
    // (Better in Panther? Looks like it. Definitely fixed in Tiger.)
    [paneView       release];

	if (wView) [wView release];
    
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
	
    doc = [parent document];

	// Source page
	sourcePage = [[IFSourcePage alloc] initWithProjectController: parent];
	[sourcePage showSourceFile: [doc mainSourceFile]];
	
	[self addPage: sourcePage];
	
	// Errors page
	errorsPage = [[IFErrorsPage alloc] initWithProjectController: parent];
	[self addPage: errorsPage];
    
	// Compiler (lives on the errors page)
    [[errorsPage compilerController] setCompiler: [doc compiler]];
    [[errorsPage compilerController] setDelegate: self];
	
	// Index page
	indexPage = [[IFIndexPage alloc] initWithProjectController: parent];
	[self addPage: indexPage];
	
	[indexPage updateIndexView];
	
	// Skein page
	skeinPage = [[IFSkeinPage alloc] initWithProjectController: parent];
	[self addPage: skeinPage];
	
	// Transcript page
	transcriptPage = [[IFTranscriptPage alloc] initWithProjectController: parent];
	[self addPage: transcriptPage];
	
	// Game page
	gamePage = [[IFGamePage alloc] initWithProjectController: parent];
	[self addPage: gamePage];
	
	// Settings
    [self updateSettings];
	
	if ([[NSApp delegate] isWebKitAvailable]) {
		[wView setPolicyDelegate: [parent generalPolicy]];
	}
	
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
        [gamePage stopRunningGame];
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


- (void) preferencesChanged: (NSNotification*) not {
	[wView setTextSizeMultiplier: [[IFPreferences sharedPreferences] fontSize]];
}

- (NSTabViewItem*) tabViewItemForPage: (IFPage*) page {
	return [tabView tabViewItemAtIndex: [tabView indexOfTabViewItemWithIdentifier: [page identifier]]];
}

- (void) selectView: (enum IFProjectPaneType) pane {
    if (!awake) {
        [NSBundle loadNibNamed: @"ProjectPane"
                         owner: self];
    }
    
    NSTabViewItem* toSelect = nil;
    switch (pane) {
        case IFSourcePane:
            toSelect = [self tabViewItemForPage: sourcePage];
            break;

        case IFErrorPane:
            toSelect = [self tabViewItemForPage: errorsPage];
            break;

        case IFGamePane:
            toSelect = [self tabViewItemForPage: gamePage];
            break;

        case IFDocumentationPane:
            toSelect = docTabView;
            break;
			
		case IFIndexPane:
            toSelect = [self tabViewItemForPage: indexPage];
			break;
			
		case IFSkeinPane:
			toSelect = [self tabViewItemForPage: skeinPage];
			break;
			
		case IFTranscriptPane:
			toSelect = [self tabViewItemForPage: transcriptPage];
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

    if ([[selectedView identifier] isEqualTo: [sourcePage identifier]]) {
        return IFSourcePane;
    } else if ([[selectedView identifier] isEqualTo: [errorsPage identifier]]) {
        return IFErrorPane;
    } else if ([[selectedView identifier] isEqualTo: [gamePage identifier]]) {
        return IFGamePane;
    } else if (selectedView == docTabView) {
        return IFDocumentationPane;
	} else if ([[selectedView identifier] isEqualTo: [indexPage identifier]]) {
		return IFIndexPane;
	} else if ([[selectedView identifier] isEqualTo: [skeinPage identifier]]) {
		return IFSkeinPane;
	} else if ([[selectedView identifier] isEqualTo: [transcriptPage identifier]]) {
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
    return [errorsPage compilerController];
}

// = Menu actions =

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
	// Can't add breakpoints if we're not showing the source view
	// (Moot: this never gets called at any point where it is useful at the moment)
	if ([menuItem action] == @selector(setBreakpoint:) ||
		[menuItem action] == @selector(deleteBreakpoint:)) {
		return [self currentView]==IFSourcePane;
	}
	
	return YES;
}

// = The source view =

- (void) prepareToCompile {
	[sourcePage prepareToCompile];
}

- (void) showSourceFile: (NSString*) file {
	[[self sourcePage] showSourceFile: file];
}

// = The pages =

- (IFSourcePage*) sourcePage {
	return sourcePage;
}

- (IFErrorsPage*) errorsPage {
	return errorsPage;
}

- (IFIndexPage*) indexPage {
	return indexPage;
}

- (IFSkeinPage*) skeinPage {
	return skeinPage;
}

- (IFTranscriptPage*) transcriptPage {
	return transcriptPage;
}

- (IFGamePage*) gamePage {
	return gamePage;
}

// = The game page =

- (void) stopRunningGame {
	[gamePage stopRunningGame];
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

// = Tab view delegate =

- (BOOL)            tabView: (NSTabView *)view 
    shouldSelectTabViewItem:(NSTabViewItem *)item {
	// Get the identifier for this tab page
	id identifier = [item identifier];
	if (identifier == nil) return YES;
	
	// Find the associated IFPage object
	IFPage* page;
	NSEnumerator* pageEnum = [pages objectEnumerator];
	while (page = [pageEnum nextObject]) {
		if ([[page identifier] isEqual: identifier]) {
			break;
		}
	}
	
	if (page != nil) {
		return [page shouldShowPage];
	}
	
	return YES;
}

// == Documentation ==

- (void) openURL: (NSURL*) url  {
	[tabView selectTabViewItem: docTabView];

	[[wView mainFrame] loadRequest: [[[NSURLRequest alloc] initWithURL: url] autorelease]];
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

// = The tab view =

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

// = Dealing with pages =

- (void) switchToPage: (NSNotification*) not {
	// Work out which page we're switching to, and the optional page that must be showing for the switch to occur
	NSString* identifier = [[not userInfo] objectForKey: @"Identifier"];
	NSString* fromPage = [[not userInfo] objectForKey: @"OldPageIdentifier"];

	// If no 'to' page is specified, then switch to the sending object
	if (identifier == nil) identifier = [(IFPage*)[not object] identifier];
	
	// If a 'from' page is specified, then the current page must be that page, or the switch won't take place
	if (fromPage != nil) {
		id currentPage = [[tabView selectedTabViewItem] identifier];
		if (![fromPage isEqualTo: currentPage]) {
			return;
		}
	}
	
	// Select the page
	[tabView selectTabViewItem: [tabView tabViewItemAtIndex: [tabView indexOfTabViewItemWithIdentifier: identifier]]];
}

- (void) addPage: (IFPage*) newPage {
	// Add this page to the list of pages being managed by this control
	[pages addObject: newPage];
	
	// Register for notifications from this page
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(switchToPage:)
												 name: IFSwitchToPageNotification
											   object: newPage];
	
	// Add the page to the tab view
	NSTabViewItem* newItem = [[NSTabViewItem alloc] initWithIdentifier: [newPage identifier]];
	[newItem setLabel: [newPage title]];

	[tabView addTabViewItem: newItem];

	if ([[newItem view] frame].size.width <= 0) {
		[[newItem view] setFrameSize: NSMakeSize(800, 200)];
	}
	[[newPage view] setFrame: [[newItem view] bounds]];
	[[newItem view] addSubview: [newPage view]];
}

@end
