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

#import "IFHistoryEvent.h"

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
		
		history = [[NSMutableArray alloc] init];
		historyPos = -1;
    }

    return self;
}

- (void) dealloc {
	[sourcePage finished];
	[errorsPage finished];
	[indexPage finished];
	[skeinPage finished];
	[transcriptPage finished];
	[gamePage finished];
	[documentationPage finished];
	[settingsPage finished];

	[sourcePage release];
	[errorsPage release];
	[indexPage release];
	[skeinPage release];
	[transcriptPage release];
	[gamePage release];
	[documentationPage release];
	[settingsPage release];
	
	[pages makeObjectsPerformSelector: @selector(setRecorder:)
						   withObject: nil];
	[pages makeObjectsPerformSelector: @selector(setOtherPane:)
						   withObject: nil];
	[pages release];
	
	[history release];
	[backCell release];
	[forwardCell release];
	[lastEvent release];
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    // FIXME: memory leak?
    //    -- Caused by a bug in NSTextView it appears (just creating
    //       anything with an NSTextView causes the same leak).
    //       Doesn't always happen. Not very much memory. Still annoying.
    // (Better in Panther? Looks like it. Definitely fixed in Tiger.)
    [paneView       release];

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
	
    doc = [parent document];
	
	// Remove the first tab view item - which we can't do in interface builder :-/
	[tabView removeTabViewItem: [[tabView tabViewItems] objectAtIndex: 0]];
	
	// Source page
	sourcePage = [[IFSourcePage alloc] initWithProjectController: parent];
	[self addPage: sourcePage];

	[sourcePage showSourceFile: [doc mainSourceFile]];
	[sourcePage updateHighlightedLines];
	
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
	
	// Documentation page
	documentationPage = [[IFDocumentationPage alloc] initWithProjectController: parent];
	[self addPage: documentationPage];
	[(IFDocumentationPage*)[documentationPage history] showToc: self];
	
	// Settings
	settingsPage = [[IFSettingsPage alloc] initWithProjectController: parent];
	[self addPage: settingsPage];
	
    [settingsPage updateSettings];
	
	// Misc stuff

	// Resize the tab view so that the only margin is on the left
	NSView* tabViewParent = [tabView superview];
	NSView* tabViewClient = [[tabView selectedTabViewItem] view];
	
	NSRect clientRect = [tabViewParent convertRect: [tabViewClient bounds]
										  fromView: tabViewClient];
	NSRect parentRect = [tabViewParent bounds];
	NSRect tabRect = [tabView frame];
	
	//float leftMissing = NSMinX(clientRect) - NSMinX(parentRect);
	float topMissing = NSMinY(clientRect) - NSMinY(parentRect);
	float bottomMissing = NSMaxY(parentRect) - NSMaxY(clientRect);

	//tabRect.origin.x -= leftMissing;
	//tabRect.size.width += leftMissing;
	tabRect.origin.y -= topMissing;
	tabRect.size.height += topMissing + bottomMissing;

	[tabView setFrame: tabRect];
	
	[[self history] selectView: IFSourcePane];
}

- (void) awakeFromNib {
    awake = YES;
	    	
    if (parent) {
        [self setupFromController];
        [gamePage stopRunningGame];
    }
	
    [tabView setDelegate: self];
	
	// Set up the backwards/forwards buttons
	backCell = [[IFPageBarCell alloc] initImageCell: [NSImage imageNamed: @"BackArrow"]];
	forwardCell = [[IFPageBarCell alloc] initImageCell: [NSImage imageNamed: @"ForeArrow"]];
	
	[backCell setKeyEquivalent: @"-"];
	[forwardCell setKeyEquivalent: @"="];
	
	[backCell setTarget: self];
	[forwardCell setTarget: self];
	[backCell setAction: @selector(goBackwards:)];
	[forwardCell setAction: @selector(goForwards:)];
	
	[pageBar setLeftCells: [NSArray arrayWithObjects: backCell, forwardCell, nil]];
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

- (void) willClose {
	// The history might reference this object (or cause a circular reference some other way), so we destroy it now
	[history release]; history = nil;
	[lastEvent release]; lastEvent = nil;
	historyPos = 0;
}

- (NSTabViewItem*) tabViewItemForPage: (IFPage*) page {
	return [tabView tabViewItemAtIndex: [tabView indexOfTabViewItemWithIdentifier: [page identifier]]];
}

- (IFPage*) pageForTabViewItem: (NSTabViewItem*) item {
	NSEnumerator* pageEnum = [pages objectEnumerator];
	IFPage* page;
	
	NSString* identifier = [item identifier];
	while (page = [pageEnum nextObject]) {
		if ([[page identifier] isEqualToString: identifier]) {
			return page;
		}
	}
	
	return nil;
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
            toSelect = [self tabViewItemForPage: documentationPage];;
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
    } else if ([[selectedView identifier] isEqualTo: [documentationPage identifier]]) {
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

- (void) viewSetHasUpdated: (IFCompilerController*) sender {
	[errorsPage viewSetHasUpdated: sender];
}

- (void) compiler: (IFCompilerController*) sender
   switchedToView: (int) viewIndex {
	[errorsPage compiler: sender
		  switchedToView: viewIndex];
}

- (BOOL) handleURLRequest: (NSURLRequest*) req {
	[[[parent auxPane] documentationPage] openURL: [[[req URL] copy] autorelease]];
	
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

- (IFDocumentationPage*) documentationPage {
	return documentationPage;
}

- (IFSettingsPage*) settingsPage {
	return settingsPage;
}

// = The game page =

- (void) stopRunningGame {
	[gamePage stopRunningGame];
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

- (void) selectTabViewItem: (NSTabViewItem*) item {
	[tabView selectTabViewItem: item];
}

- (void) activatePage: (IFPage*) page {
	// Select the active view for the specified page
	[[parent window] makeFirstResponder: [page activeView]];
}

- (void)        tabView:(NSTabView *)tabView
  willSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	IFPage* page = [self pageForTabViewItem: tabViewItem];
	
	// Record in the history
	[[self history] selectTabViewItem: tabViewItem];
	[[self history] activatePage: page];

	// Notify the page that it has been selected
	[page didSwitchToPage];
	
	// Update the right-hand page bar cells
	[pageBar setRightCells: [[self pageForTabViewItem: tabViewItem] toolbarCells]];
}

// = The tab view =

- (NSTabView*) tabView {
	return tabView;
}

// = Find =

- (void) performFindPanelAction: (id) sender {
	NSLog(@"Bing!");
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
	[newPage setOtherPane: [parent oppositePane: self]];
	[newPage setRecorder: self];
	
	// Register for notifications from this page
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(switchToPage:)
												 name: IFSwitchToPageNotification
											   object: newPage];
	
	// Add the page to the tab view
	NSTabViewItem* newItem = [[NSTabViewItem alloc] initWithIdentifier: [newPage identifier]];
	[newItem setLabel: [newPage title]];

	[tabView addTabViewItem: [newItem autorelease]];

	if ([[newItem view] frame].size.width <= 0) {
		[[newItem view] setFrameSize: NSMakeSize(1280, 1024)];
	}
	[[newPage view] setFrame: [[newItem view] bounds]];
	[[newItem view] addSubview: [newPage view]];
}

// = The history =

- (void) updateHistoryControls {
	if (historyPos <= 0) {
		[backCell setEnabled: NO];
	} else {
		[backCell setEnabled: YES];
	}
	
	if (historyPos >= [history count]-1) {
		[forwardCell setEnabled: NO];
	} else {
		[forwardCell setEnabled: YES];
	}
}

- (void) clearLastEvent {
	[lastEvent release];
	lastEvent = nil;
}

- (void) addHistoryEvent: (IFHistoryEvent*) newEvent {
	if (newEvent == nil) return;
	
	// If we've gone backwards in the history, then remove the 'forward' history items
	if (historyPos != [history count]-1) {
		[history removeObjectsInRange: NSMakeRange(historyPos+1, [history count]-(historyPos+1))];
	}
	
	// Add the new history item
	[history addObject: newEvent];
	historyPos++;
	
	// Record it as the last event
	if (lastEvent == nil) {
		[[NSRunLoop currentRunLoop] performSelector: @selector(clearLastEvent)
											 target: self
										   argument: nil
											  order: 99
											  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
	}
	
	[lastEvent autorelease];
	lastEvent = [newEvent retain];
	
	[self updateHistoryControls];
}

- (IFHistoryEvent*) historyEvent {
	if (replaying) return nil;
	
	IFHistoryEvent* event;
	if (lastEvent) {
		event = lastEvent;
	} else {
		// Construct a new event based on this obejct
		IFHistoryEvent* newEvent = [[IFHistoryEvent alloc] initWithObject: self];
		[self addHistoryEvent: newEvent];
		
		event = [newEvent autorelease];
	}
	
	return event;
}

- (void) addHistoryInvocation: (NSInvocation*) invoke {
	if (replaying) return;
	
	// Construct a new event based on the invocation
	IFHistoryEvent* newEvent = [[IFHistoryEvent alloc] initWithInvocation: invoke];
	[self addHistoryEvent: newEvent];
	
	[newEvent release];
}

- (id) history {
	if (replaying) return nil;
	
	IFHistoryEvent* event;
	if (lastEvent) {
		event = lastEvent;
	} else {
		// Construct a new event based on this obejct
		IFHistoryEvent* newEvent = [[IFHistoryEvent alloc] initWithObject: self];
		[self addHistoryEvent: newEvent];
		
		event = [newEvent autorelease];
	}
	
	// Return a suitable proxy
	[event setTarget: self];
	return [event proxy];
}

- (void) goBackwards: (id) sender {
	if (historyPos <= 0) return;
	
	IFViewAnimator* anim = [[[IFViewAnimator alloc] init] autorelease];
	[anim prepareToAnimateView: tabView];
	
	replaying = YES;
	[[history objectAtIndex: historyPos-1] replay];
	historyPos--;
	replaying = NO;
	
	[anim animateTo: tabView
			  style: IFFloatOut];
	[self updateHistoryControls];
}

- (void) goForwards: (id) sender {
	if (historyPos >= [history count]-1) return;
	
	IFViewAnimator* anim = [[[IFViewAnimator alloc] init] autorelease];
	[anim prepareToAnimateView: tabView];
	
	replaying = YES;
	[[history objectAtIndex: historyPos+1] replay];
	historyPos++;
	replaying = NO;
	
	[anim animateTo: tabView
			  style: IFFloatIn];
	[self updateHistoryControls];
}

@end
