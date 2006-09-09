//
//  IFHeadingsBrowser.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 24/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import "IFHeadingsBrowser.h"

#import "IFCustomPopup.h"

@implementation IFHeadingsBrowser

- (id) init {
	self = [super init];
	
	if (self) {
		[NSBundle loadNibNamed: @"HeadingsBrowser"
						 owner: self];
		animator = [[IFViewAnimator alloc] initWithFrame: NSMakeRect(0,0,1,1)];
	}
	
	return self;
}

- (void) dealloc {
	[headingsView release];
	[animator release];

	[intel release];
	[root release];
	
	[super dealloc];
}

// = Getting information about this browser =

- (NSView*) view {
	return headingsView;
}

// = Setting what to browse =

- (NSString*) crumbForHeading: (NSString*) fullHeading {
	static NSDictionary* stopwords = nil;
	
	if (stopwords == nil) {
		stopwords = [[NSDictionary dictionaryWithObjectsAndKeys: 
			@"a", @"a",
			@"the", @"the",
			@"an", @"an",
			@"and", @"and",
			nil] retain];
	}
	
	// Get the parts of the heading
	NSArray* parts = [fullHeading componentsSeparatedByString: @" "];
	if ([parts count] < 2) return fullHeading;
	
	// Create the result
	NSMutableString* result = [[[NSMutableString alloc] init] autorelease];
	
	// Format is 'X - heading something[...]'
	[result appendFormat: @"%@ -", [parts objectAtIndex: 1]];
	
	// Iterate through the parts of the name after the section dash
	int part;
	int displayed = 0;
	for (part=2; part<[parts count] && displayed < 2; part++) {
		NSString* thisPart = [[parts objectAtIndex: part] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		// Check that this part is not too short
		if ([thisPart length] <= 1) continue;
		if ([stopwords objectForKey: [thisPart lowercaseString]] != nil) continue;
		
		// Add this part to the list displayed
		displayed++;
		[result appendFormat: @" %@", thisPart];
	}
	
	// Add an ellipsis
	if (part < [parts count]) {
		unichar ellipsis = 0x2026;
		[result appendString: [NSString stringWithCharacters: &ellipsis
													  length: 1]];
	}

	// Return the result
	return result;
}

- (NSString*) typeForHeading: (NSString*) fullHeading {
	// Get the parts of the heading
	NSArray* parts = [fullHeading componentsSeparatedByString: @" "];
	if ([parts count] < 1) return fullHeading;	

	return [[parts objectAtIndex: 0] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString*) titleForHeading: (NSString*) fullHeading {
	// Get the parts of the heading
	NSArray* parts = [fullHeading componentsSeparatedByString: @" "];
	if ([parts count] < 2) return fullHeading;
	
	// Create the result
	NSMutableString* result = [[[NSMutableString alloc] init] autorelease];
	
	// Format is 'X - heading something[...]'
	[result appendFormat: @"%@", [parts objectAtIndex: 1]];
	
	// Iterate through the parts of the name after the section dash
	int part;
	for (part=2; part<[parts count]; part++) {
		NSString* thisPart = [[parts objectAtIndex: part] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		// Add this part to the list displayed
		[result appendFormat: @" %@", thisPart];
	}
	
	// Add an ellipsis
	if (part < [parts count]) {
		unichar ellipsis = 0x2026;
		[result appendString: [NSString stringWithCharacters: &ellipsis
													  length: 1]];
	}
	
	// Return the result
	return result;
}

- (void) updateViews {
	[breadcrumb removeAllBreadcrumbs];
	[animator prepareToAnimateView: sectionView];
	
	// Add the top level 'bullet' breadcrumb
	unichar bullet = 0x2022;
	[breadcrumb addBreadcrumbWithText: [NSString stringWithCharacters: &bullet
															   length: 1]
								  tag: -1];
	
	// Calculate the rest of the sections
	NSMutableArray* sections = [NSMutableArray array];
	IFIntelSymbol* parent = [root parent];
	
	int tagCount = 0;
	while (parent != nil) {
		if ([parent level] <= 0) {
			break;
		}
		
		tagCount++;
		[sections addObject: [parent name]];
		
		parent = [parent parent];
	}
	
	// Add them as breadcrumb sections
	NSEnumerator* crumbEnum = [sections reverseObjectEnumerator];
	NSString* crumb;
	
	while (crumb = [crumbEnum nextObject]) {
		[breadcrumb addBreadcrumbWithText: [self crumbForHeading: crumb]
									  tag: tagCount--];
	}
	
	// Update the section view
	IFIntelSymbol* section = [[root parent] child];
	[sectionView clear];
	
	if (section == nil) section = [intel firstSymbol];
	if ([section level] == 0) section = [section child];

	int level = -1;
	
	while (section != nil) {
		if ([section level] != level) {
			[sectionView addHeading: [[self typeForHeading: [section name]] stringByAppendingString: @"..."]
								tag: nil];
			level = [section level];
		}
		
		[sectionView addSection: [self titleForHeading: [section name]]
					subSections: [section child] != nil
							tag: section];
		
		section = [section sibling];
	}
	
	// Use this opportunity to update the action of the section view
	[sectionView setTarget: self];
	[sectionView setGotoSubsectionAction: @selector(gotoSubsection:)];
	[sectionView setSelectedItemAction: @selector(selectedItem:)];
	
	[breadcrumb setTarget: self];
	[breadcrumb setAction: @selector(gotoBreadcrumb:)];
	
	// Set the size of the section view
	NSRect viewRect = [sectionView frame];
	NSSize idealSize = [sectionView idealSize];
	
	if (viewRect.size.height < idealSize.height || ![[headingsView window] isVisible]) {
		viewRect.size.height = idealSize.height + 4;
		
		NSRect overallRect = [headingsView frame];
		overallRect.size.height = NSMaxY(viewRect) + [breadcrumb frame].size.height;
		
		[headingsView setFrame: overallRect];
		[sectionView setFrame: viewRect];
	}
	
	// Animate to the new view
	if ([[headingsView window] isVisible]) {
		[animator animateTo: sectionView
					  style: animStyle];
	} else {
		[animator finishAnimation];
	}
	animStyle = IFAnimateLeft;
}

- (void) setIntel: (IFIntelFile*) newIntel {
	[intel release];
	intel = [newIntel retain];
	
	// Shrink this view down to a minimum size
	NSRect smallRect = [sectionView frame];
	smallRect.size.height = 4;
	
	NSRect overallRect = [headingsView frame];
	overallRect.size.height = NSMaxY(smallRect)  + [breadcrumb frame].size.height;
	[headingsView setFrame: overallRect];
}

- (void) setSection: (IFIntelSymbol*) newSection {
	[root release];
	root = [newSection retain];
	
	[self updateViews];
}

- (void) setSectionByLine: (int) line {
	[self setSection: [intel nearestSymbolToLine: line]];
}

// = Actions =

- (void) keyDown: (NSEvent*) ev {
	if ([[ev characters] characterAtIndex: 0] == NSLeftArrowFunctionKey) {
		if (root == nil || [[root parent] level] == 0) return;
		
		animStyle = IFAnimateRight;
		[self setSection: [root parent]];
	} else if ([[ev characters] characterAtIndex: 0] == NSRightArrowFunctionKey) {
		IFIntelSymbol* newSection = [(IFIntelSymbol*)[sectionView highlightedTag] child];
		if (newSection != nil) [self setSection: newSection];
	} else {
		[sectionView keyDown: ev];
	}
}

- (void) gotoSubsection: (IFIntelSymbol*) subsection {
	[self setSection: [subsection child]];
}

- (void) selectedItem: (IFIntelSymbol*) subsection {
	if (subsection == nil) {
		// If you select a section name (ie, a 'Chapter...' part, then go to the section above)
		if (root == nil || [[root parent] level] == 0) return;
		
		animStyle = IFAnimateRight;
		[self setSection: [root parent]];
	} else {
		// If you select an actual section, then close the popup
		[IFCustomPopup closeAllPopupsWithSender: subsection];
	}
}

- (void) gotoBreadcrumb: (IFBreadcrumbCell*) crumb {
	int tag = [crumb tag];
	
	IFIntelSymbol* symbol = root;
	if (tag == -1) {
		symbol = nil;
		if (root == nil || [[root parent] level] == 0) return;
	} else {
		int x;
		if (tag == 1) return;
		
		for (x=1; x<tag; x++) {
			symbol = [symbol parent];
		}
	}
	
	animStyle = IFAnimateRight;
	[self setSection: symbol];
}

@end
