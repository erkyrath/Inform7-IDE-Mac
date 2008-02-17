//
//  IFFindController.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 05/02/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFFindController.h"
#import "IFAppDelegate.h"
#import "IFFindResult.h"


@implementation IFFindController

// = Initialisation =

+ (IFFindController*) sharedFindController {
	static IFFindController* sharedController = nil;
	
	if (!sharedController) {
		sharedController = [[IFFindController alloc] initWithWindowNibName: @"Find"];
	}
	
	return sharedController;
}

- (id) initWithWindowNibName: (NSString*) nibName {
	self = [super initWithWindowNibName: (NSString*) nibName];
	
	if (self) {
		// Get notifications about when the main window changes
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(mainWindowChanged:)
													 name: NSWindowDidBecomeMainNotification
												   object: nil];
	}
	
	return self;
}

- (void) dealloc {
	// Stop receiving notifications
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[auxView release];
	
	[findAllResults release];
	[findIdentifier release];
	
	[locationColumn release];
	[typeColumn release];
	
	// Finish up
	[super dealloc];
}

// = Actions =

- (IFFindType) currentFindType {
	NSMenuItem* selected = [searchType selectedItem];
	
	IFFindType flags = 0;
	if ([ignoreCase state] == NSOnState) flags |= IFFindCaseInsensitive;
	
	if (selected == containsItem) {
		return IFFindContains | flags;
	} else if (selected == beginsWithItem) {
		return IFFindBeginsWith | flags;
	} else if (selected == completeWordItem) {
		return IFFindCompleteWord | flags;
	} else if (selected == regexpItem) {
		return IFFindRegexp | flags;
	} else {
		return IFFindContains | flags;
	}
}

- (IBAction) findNext: (id) sender {
	if (activeDelegate && [activeDelegate respondsToSelector: @selector(findNextMatch:ofType:)]) {
		[activeDelegate findNextMatch: [findPhrase stringValue]
							   ofType: [self currentFindType]];
		// TODO: record the phrase in the history
	}
}

- (IBAction) findPrevious: (id) sender {
	if (activeDelegate && [activeDelegate respondsToSelector: @selector(findNextMatch:ofType:)]) {
		[activeDelegate findPreviousMatch: [findPhrase stringValue]
								   ofType: [self currentFindType]];
		// TODO: record the phrase in the history
	}
}

- (IBAction) replaceAndFind: (id) sender {
	if (activeDelegate 
		&& [activeDelegate respondsToSelector: @selector(replaceFoundWith:)] 
		&& [activeDelegate respondsToSelector:@selector(findNextMatch:ofType:)]) {
		[activeDelegate replaceFoundWith: [replacePhrase stringValue]];
		[activeDelegate findNextMatch: [findPhrase stringValue]
							   ofType: [self currentFindType]];
	}
}

- (IBAction) replace: (id) sender {
	if (activeDelegate && [activeDelegate respondsToSelector: @selector(replaceFoundWith:)]) {
		[activeDelegate replaceFoundWith: [replacePhrase stringValue]];
	}
}

- (IBAction) useSelectionForFind: (id) sender {
	// Hack: ensure the window is loaded
	[self window];
	
	if (activeDelegate && [activeDelegate respondsToSelector: @selector(currentSelectionForFind)]) {
		NSString* searchFor = [activeDelegate currentSelectionForFind];
		if (searchFor && ![@"" isEqualToString: searchFor]) {
			[findPhrase setStringValue: searchFor];
			[searchType selectItem: containsItem];
			
			[self findNext: self];
			return;
		}
	}
	
	// Can't do this!
	NSBeep();
}

- (IBAction) findTypeChanged: (id) sender {
	if ([searchType selectedItem] == regexpItem) {
		[self showAuxiliaryView: regexpHelpView];
	} else {
		if (auxView == regexpHelpView) {
			[self showAuxiliaryView: nil];
		}
	}
}

- (IBAction) toggleRegexpHelp: (id) sender {
	if (auxView != regexpHelpView) return;
	
	if ([showRegexpHelp state] == NSOffState) {
		[[NSApp delegate] removeView: regexpTextView];
	} else {
		[[NSApp delegate] addView: regexpTextView
						   toView: regexpHelpView];
	}
}

- (void) keyDown: (NSEvent*) evt {
	// TODO: this doesn't work
	NSBeep();
	
	// Pressing <cr> while using the find box causes the find to take place and the window to close
	if ([[evt characters] isEqualToString: @"\r"] || [[evt characters] isEqualToString: @"\n"]) {
		[[self window] orderOut: self];
		[self findNext: self];
	}
}

// = Find menu actions =

- (BOOL) canFindAgain: (id) sender {
	if (activeDelegate && ![@"" isEqualToString: [findPhrase stringValue]]) {
		return YES;
	} else {
		return NO;
	}
}

- (BOOL) canUseSelectionForFind: (id) sender {
	if (activeDelegate && [activeDelegate respondsToSelector: @selector(currentSelectionForFind)]) {
		if (![@"" isEqualToString: [activeDelegate currentSelectionForFind]]) {
			return YES;
		}
	}
	
	return NO;
}

// = Updating the find delegate =

- (BOOL) isSuitableDelegate: (id) object {
	if (!object) return NO;
	
	if ([object respondsToSelector: @selector(findNextMatch:ofType:)]) {
		return YES;
	} else {
		return NO;
	}
}

- (id) chooseDelegateFromWindow: (NSWindow*) window {
	// Default delegate behaviour is to look at the window controller first, then the window, then the views
	// up the chain from the active view
	if ([self isSuitableDelegate: [window windowController]]) {
		return [window windowController];
	} else if ([self isSuitableDelegate: window]) {
		return window;
	}
	
	NSResponder* responder = [window firstResponder];
	while (responder) {
		if ([self isSuitableDelegate: responder]) {
			return responder;
		}
		responder = [responder nextResponder];
	}
	
	return nil;
}

- (BOOL) canSearch {
	return [activeDelegate respondsToSelector: @selector(findNextMatch:ofType:)];
}

- (BOOL) canReplace {
	return [activeDelegate respondsToSelector: @selector(replaceFoundWith:)];
}

- (BOOL) canFindAll {
	return [activeDelegate respondsToSelector: @selector(findAllMatches:ofType:inFindController:withIdentifier:)];
}

- (BOOL) supportsFindType: (IFFindType) type {
	if (activeDelegate) {
		if ([activeDelegate respondsToSelector: @selector(canUseFindType:)]) {
			// If the delegate specifies what types of thing it can find, then use that
			return [activeDelegate canUseFindType: type];
		} else {
			// Default is to support all but regular expressions
			if (type == IFFindRegexp) return NO;
			return YES;
		}
	}
	
	// If there's no delegate, allow everything
	return YES;
}

- (void) updateControls {
	[findPhrase setEnabled: [self canSearch] || [self canFindAll]];
	[replacePhrase setEnabled: [self canReplace]];
	
	[ignoreCase setEnabled: [self canSearch]];
	[searchType setEnabled: [self canSearch]];
	
	[containsItem setEnabled: [self supportsFindType: IFFindContains]];
	[beginsWithItem setEnabled: [self supportsFindType: IFFindBeginsWith]];
	[completeWordItem setEnabled: [self supportsFindType: IFFindCompleteWord]];
	[regexpItem setEnabled: [self supportsFindType: IFFindRegexp]];
	
	[next setEnabled: [self canSearch]];
	[previous setEnabled: [self canSearch]];
	[replaceAndFind setEnabled: [self canReplace]];
	[replace setEnabled: [self canReplace]];
	[findAll setEnabled: [self canFindAll]];
	
	// 'Contains' is the basic type of search
	if (![[searchType selectedItem] isEnabled]) {
		[searchType selectItem: containsItem];
	}
}

- (void) setActiveDelegate: (id) newDelegate {
	if (newDelegate == activeDelegate) return;
	
	activeDelegate = newDelegate;

	[findIdentifier autorelease]; findIdentifier = nil;
	if (searching) {
		[findProgress stopAnimation: self];
		searching = NO;
	}
	if (auxView != regexpHelpView) {
		[self showAuxiliaryView: nil];
	}

	[self updateControls];
}

- (void) updateFromFirstResponder {
	NSWindow* mainWindow = [NSApp mainWindow];
	[self setActiveDelegate: [self chooseDelegateFromWindow: mainWindow]];
}

- (void) mainWindowChanged: (NSNotification*) not {
	// Update this control from the first responder
	[self setActiveDelegate: [self chooseDelegateFromWindow: [not object]]];
}
						   
- (void) windowDidLoad {
	[self updateFromFirstResponder];
	
	winFrame		= [[self window] frame];
	contentFrame	= [[[self window] contentView] frame];
	
	textViewSize	= [regexpTextView frame];

	[typeColumn retain];
	[locationColumn retain];
	[findAllView retain];
	
	[[[NSApp delegate] leopard] prepareToAnimateView: auxViewPanel];
}

- (void) windowDidBecomeKey: (NSNotification*) not {
	// Update this window again as the first responder may have changed (can't get notifications for this)
	[self updateFromFirstResponder];
}

// = 'Find all' =

- (void) updateFindAllResults {
	// Show nothing if there are no results in the find view
	if ([findAllResults count] <= 0) {
		[self showAuxiliaryView: foundNothingView];
		return;
	}
	
	// Decide whether or not to show the 'location' and 'type' columns
	NSMutableSet* locations	= [NSMutableSet set];
	NSMutableSet* types		= [NSMutableSet set];
	
	NSEnumerator* resultEnum = [findAllResults objectEnumerator];
	IFFindResult* result;
	while (result = [resultEnum nextObject]) {
		[locations addObject: [result location]];
		[types addObject: [result matchType]];
	}
	
	[findAllTable removeTableColumn: typeColumn];
	[findAllTable removeTableColumn: locationColumn];
	
	if ([locations count] > 1) {
		[findAllTable addTableColumn: locationColumn];
		[findAllTable moveColumn: [findAllTable columnWithIdentifier: @"location"]
						toColumn: 0];
	}
	if ([types count] > 1) {
		[findAllTable addTableColumn: typeColumn];
		[findAllTable moveColumn: [findAllTable columnWithIdentifier: @"type"]
						toColumn: 0];
	}
	
	// Refresh the table
	[self showAuxiliaryView: findAllView];
	[findAllTable reloadData];
}

- (void) willFindMore: (id) identifier {
	if (identifier == findIdentifier) {
		[findProgress startAnimation: self];
		searching = YES;
	}
}

- (void) finishedSearching: (id) identifier {
	if (identifier == findIdentifier) {
		[findProgress stopAnimation: self];
		searching = NO;
	}
}

- (void) foundItems: (NSArray*) items
	 withIdentifier: (id) identifier {
	if (!items) return;
	
	if (identifier == findIdentifier) {
		[findAllResults addObjectsFromArray: items];
		[self updateFindAllResults];
	}
}

- (NSView*) findAllView {
	return findAllView;
}

- (void) setFindAllView: (NSView*) newFindView {
	[findAllView autorelease];
	findAllView = [newFindView retain];
}

- (IBAction) findAll: (id) sender {
	if (![self canFindAll]) {
		return;
	}
	
	// Load a new 'find all' view
	[NSBundle loadNibNamed: @"FindAll"
					 owner: self];
	
	// Create a new find identifier
	[findIdentifier autorelease];
	findAllCount++;
	findIdentifier = [[NSNumber alloc] initWithInt: findAllCount];
	
	// Clear out the find results
	[findAllResults autorelease];
	findAllResults = [[NSMutableArray alloc] init];
	
	// Perform the initial find
	NSArray* findResults = [activeDelegate findAllMatches: [findPhrase stringValue]
												   ofType: [self currentFindType]
										 inFindController: self
										   withIdentifier: findIdentifier];
	if (findResults) {
		[findAllResults addObjectsFromArray: findResults];
	}
	
	[self updateFindAllResults];
}

// = The find all table =

- (int)numberOfRowsInTableView: (NSTableView*) aTableView {
	return [findAllResults count];
}

- (id)				tableView: (NSTableView*) aTableView 
	objectValueForTableColumn: (NSTableColumn*) aTableColumn
					row: (int) rowIndex {
	NSString* ident = [aTableColumn identifier];
	IFFindResult* row = [findAllResults objectAtIndex: rowIndex];
	
	if ([ident isEqualToString: @"location"]) {
		return [row location];
	} else if ([ident isEqualToString: @"type"]) {
		// Localise the type name
		NSString* key = [@"SearchType " stringByAppendingString: [row matchType]];
		
		return [[NSBundle mainBundle] localizedStringForKey: key
													  value: key
													  table: nil];
	} else if ([ident isEqualToString: @"context"]) {
		return [row attributedContext];
	}
	
	return nil;
}

- (void)tableViewSelectionDidChange: (NSNotification *)aNotification {
}

// = The auxiliary view =

- (void) showAuxiliaryView: (NSView*) newAuxView {
	// Do nothing if the aux view hasn't changed
	if (newAuxView == auxView) return;
	
	[[[NSApp delegate] leopard] prepareToAnimateView: auxViewPanel];
	[auxViewPanel setNeedsDisplay: YES];

	// Hide the old auxiliary view
	[auxViewPanel setNeedsDisplay: YES];
	if (auxView) {
		[auxView setNeedsDisplay: YES];
		[[NSApp delegate] removeView: auxView];
		[auxView autorelease];
		auxView = nil;
	}
	
	// Hack: Core animation is rubbish and screws everything up if you try to resize the window immediately after adding a layer to a view
	[[self window] displayIfNeeded];
	
	// Show the new auxiliary view
	NSRect auxFrame		= NSMakeRect(0,0,0,0);
	
	if (newAuxView) {
		// Remember this view
		auxFrame	= [newAuxView frame];
		
		// Set its size
		auxFrame.origin		= NSMakePoint(0, NSMaxY(auxViewPanel.bounds)-auxFrame.size.height);
		auxFrame.size.width = [[[self window] contentView] frame].size.width;
		[newAuxView setFrame: auxFrame];
	}
	
	// Resize the window
	NSRect newWinFrame = [[self window] frame];

	float heightDiff		= (winFrame.size.height + auxFrame.size.height) - newWinFrame.size.height;
	newWinFrame.size.height += heightDiff;
	newWinFrame.origin.y	-= heightDiff;

	[[NSApp delegate] setFrame: newWinFrame
					  ofWindow: [self window]];
	
	// Add the new view
	if (newAuxView) {
		[newAuxView setNeedsDisplay: YES];
		auxView		= [newAuxView retain];

		auxFrame.origin		= NSMakePoint(0, NSMaxY(auxViewPanel.bounds)-auxFrame.size.height);
		auxFrame.size.width = [[[self window] contentView] frame].size.width;
		[newAuxView setFrame: auxFrame];

		[[NSApp delegate] addView: newAuxView
						   toView: auxViewPanel];
	}
}

@end
