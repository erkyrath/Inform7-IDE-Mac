//
//  IFIndexPage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFIndexPage.h"

#import "IFAppDelegate.h"
#import "IFPretendWebView.h"

@implementation IFIndexPage

// = Initialisation =

- (id) initWithProjectController: (IFProjectController*) controller {
	self = [super initWithNibName: @"Index"
				projectController: controller];
	
	if (self) {
		lastUserTab = [@"Contents" copy];
	}
	
	return self;
}

- (void) dealloc {
	if (indexTabs != nil) {
		[indexTabs setDelegate: nil];
		[indexTabs release];
	}
	[lastUserTab release];

	[super dealloc];
}

// = Details about this view =

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Index Page Title"
												  value: @"Index"
												  table: nil];
}

// = Page validation =

- (BOOL) shouldShowPage {
	return indexAvailable;
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
	
	indexTabs = [[NSTabView alloc] initWithFrame: [view bounds]];
	[indexTabs setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
	[view addSubview: indexTabs];
	
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
			
			[pretendView setHostWindow: [parent window]];
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

- (BOOL) indexAvailable {
	return indexAvailable;
}

// = Tab view delegate methods =

-  (void)			tabView:(NSTabView *)tabView 
	   didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	if (tabView == indexTabs) {
		// Do nothing if something mechanical may be changing the selection
		if (indexMachineSelection > 0) return;
		
		// Store this as the last 'user-selected' tab view item
		[lastUserTab release];
		lastUserTab = [[tabViewItem label] retain];
	}
}

@end
