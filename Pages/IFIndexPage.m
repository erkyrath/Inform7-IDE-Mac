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
	[indexCells release];
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

- (int) indexOfItemWithIdentifier: (id) identifier {
	NSEnumerator* cellEnum = [indexCells objectEnumerator];
	IFPageBarCell* cell;
	
	int index = 0;
	while (cell = [cellEnum nextObject]) {
		if ([[cell identifier] isEqual: identifier]) return index;
		index++;
	}
	
	return NSNotFound;
}

- (BOOL) canSelectIndexTab: (int) whichTab {
	if ([self indexOfItemWithIdentifier: [NSNumber numberWithInt: whichTab]] == NSNotFound) {
		return NO;
	} else {
		return YES;
	}
}

- (void) selectIndexTab: (int) whichTab {
	int tabIndex = [self indexOfItemWithIdentifier: [NSNumber numberWithInt: whichTab]];
	
	if (tabIndex != NSNotFound) {
		[self switchToCell: [indexCells objectAtIndex: tabIndex]];
		
		NSEnumerator* cellEnum = [indexCells objectEnumerator];
		NSCell* cell;
		while (cell = [cellEnum nextObject]) {
			[cell setState: NSOffState];
		}
		[[indexCells objectAtIndex: tabIndex] setState: NSOnState];
	}
}

- (void) updateIndexView {
	indexAvailable = NO;
	
	if (![IFAppDelegate isWebKitAvailable]) return;
	
	// The index path
	NSString* indexPath = [NSString stringWithFormat: @"%@/Index", [[parent document] fileName]];
	BOOL isDir = NO;
	
	if (indexCells) [indexCells release];
	indexCells = [[NSMutableArray alloc] init];
	
	// Check that it exists and is a directory
	if (indexPath == nil) return;
	if (![[NSFileManager defaultManager] fileExistsAtPath: indexPath
											  isDirectory: &isDir]) return;
	if (!isDir) return;		
	
	// Create the tab view that will eventually go into the main view
	indexMachineSelection++;
	
	// Iterate through the files
	NSArray* files = [[NSFileManager defaultManager] directoryContentsAtPath: indexPath];
	files = [files sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
	NSEnumerator* fileEnum = [files objectEnumerator];
	NSString* theFile;
	
	NSBundle* mB = [NSBundle mainBundle];
	
	while (theFile = [fileEnum nextObject]) {
		NSString* extension = [[theFile pathExtension] lowercaseString];
		NSString* fullPath = [indexPath stringByAppendingPathComponent: theFile];
		
		IFPageBarCell* userTab = nil;
		
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
			IFPageBarCell* newTab = [[[IFPageBarCell alloc] init] autorelease];
			
			[newTab setView: fileView];
			
			NSString* label = [mB localizedStringForKey: theFile
												  value: [theFile stringByDeletingPathExtension]
												  table: @"CompilerOutput"];
			[newTab setStringValue: label];
			[newTab setRadioGroup: 128];
			
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
			[newTab setTarget: self];
			[newTab setAction: @selector(switchToCell:)];
			
			// Check if this was the last tab being viewed by the user
			if (lastUserTab != nil && [label caseInsensitiveCompare: lastUserTab] == NSOrderedSame) {
				userTab = newTab;
			} else if (lastUserTab == nil && tabId == IFIndexContents) {
				userTab = newTab;
			}
			
			// Add the tab
			[indexCells insertObject: newTab
							 atIndex: 0];
			indexAvailable = YES;
		}
		
		[self toolbarCellsHaveUpdated];
			
		if (userTab != nil) {
			[self switchToCell: userTab];
			[userTab setState: NSOnState];
		}
	}
	
	indexMachineSelection--;
}

- (BOOL) indexAvailable {
	return indexAvailable;
}

// = Switching cells =

- (void) selectCellWithTitle: (NSString*) title {
	NSEnumerator* cellEnum = [indexCells objectEnumerator];
	IFPageBarCell* cell;
	while (cell = [cellEnum nextObject]) {
		if ([[cell stringValue] isEqual: title]) {
			[cell setState: NSOnState];
			[self switchToCell: cell];
			return;
		}
	}
}

- (IBAction) switchToCell: (id) sender {
	// Get the cell that was clicked on
	IFPageBarCell* cell = nil;
	
	if ([sender isKindOfClass: [IFPageBarCell class]]) cell = sender;
	else if ([sender isKindOfClass: [IFPageBarView class]]) cell = (IFPageBarCell*)[sender lastTrackedCell];
	
	// Clear out the subviews of this view
	[[[self view] subviews] makeObjectsPerformSelector: @selector(removeFromSuperview)];
	
	// Morph the view, if it supports morphing
	NSEnumerator* subviewEnum = [[[cell view] subviews] objectEnumerator];
	NSView* subview;
	while (subview = [subviewEnum nextObject]) {
		if ([subview respondsToSelector: @selector(morphMe)]) [(id)subview morphMe];		
	}
	
	// Add the new view as a subview of this control
	[[cell view] setFrame: [[self view] bounds]];
	[[self view] addSubview: [cell view]];
	
	// Do nothing if something mechanical may be changing the selection
	if (indexMachineSelection <= 0)
	{
		// Store this as the last 'user-selected' tab view item
		[lastUserTab release];
		lastUserTab = [[cell stringValue] retain];
	}
	
	[[self history] switchToPage];
	[[self history] selectCellWithTitle: [cell stringValue]];
}

- (void) didSwitchToPage {
	[[self history] selectCellWithTitle: lastUserTab];
	[super didSwitchToPage];
}

// = The page bar =

- (NSArray*) toolbarCells {
	if (indexCells == nil) return [NSArray array];
	return indexCells;
}

@end
