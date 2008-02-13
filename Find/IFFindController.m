//
//  IFFindController.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 05/02/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFFindController.h"
#import "IFAppDelegate.h"


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

- (IBAction) findAll: (id) sender {
	[self showAuxiliaryView: findAllView];
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
	return [activeDelegate respondsToSelector: @selector(findAllMatches:inFindController:)];
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

- (void) updateFromFirstResponder {
	NSWindow* mainWindow = [NSApp mainWindow];
	activeDelegate = [self chooseDelegateFromWindow: mainWindow];
	[self updateControls];
}

- (void) mainWindowChanged: (NSNotification*) not {
	// Update this control from the first responder
	activeDelegate = [self chooseDelegateFromWindow: [not object]];
	[self updateControls];
}
						   
- (void) windowDidLoad {
	[self updateFromFirstResponder];
	
	winFrame		= [[self window] frame];
	contentFrame	= [[[self window] contentView] frame];
	
	textViewSize	= [regexpTextView frame];
}

- (void) windowDidBecomeKey: (NSNotification*) not {
	// Update this window again as the first responder may have changed (can't get notifications for this)
	[self updateFromFirstResponder];
}

// = The auxiliary view =

- (void) showAuxiliaryView: (NSView*) newAuxView {
	// Do nothing if the aux view hasn't changed
	if (newAuxView == auxView) return;
	
	// Hide the old auxiliary view
	if (auxView) {
		[[NSApp delegate] removeView: auxView];
		[auxView autorelease];
		auxView = nil;
	}
	
	// Show the new auxiliary view
	NSRect viewFrame	= [[[self window] contentView] frame];
	NSRect auxFrame		= NSMakeRect(0,0,0,0);
	
	if (newAuxView) {
		// Remember this view
		auxView		= [newAuxView retain];
		auxFrame	= [auxView frame];
		
		// Set its size
		auxFrame.origin		= NSMakePoint(NSMinX(contentFrame), NSMaxY(viewFrame)-contentFrame.size.height-auxFrame.size.height);
		auxFrame.size.width = [[[self window] contentView] frame].size.width;
		[auxView setFrame: auxFrame];
		
		// Add it to the window
		[[NSApp delegate] addView: auxView
						   toView: [[self window] contentView]];
	}
	
	// Resize the window
	NSRect newWinFrame = [[self window] frame];

	float heightDiff		= (winFrame.size.height + auxFrame.size.height) - newWinFrame.size.height;
	newWinFrame.size.height += heightDiff;
	newWinFrame.origin.y	-= heightDiff;

	[[NSApp delegate] setFrame: newWinFrame
					  ofWindow: [self window]];
}

@end
