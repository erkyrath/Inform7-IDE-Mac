//
//  IFHeadingsBrowser.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 24/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import "IFHeadingsBrowser.h"


@implementation IFHeadingsBrowser

- (id) init {
	self = [super init];
	
	if (self) {
		[NSBundle loadNibNamed: @"HeadingsBrowser"
						 owner: self];
	}
	
	return self;
}

- (void) dealloc {
	[headingsView release];

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
		
		// Check that this part is not too sh
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

- (void) updateViews {
	[breadcrumb removeAllBreadcrumbs];
	
	// Add the top level 'bullet' breadcrumb
	unichar bullet = 0x2022;
	[breadcrumb addBreadcrumbWithText: [NSString stringWithCharacters: &bullet
															   length: 1]
								  tag: 0];
	
	// Calculate the rest of the sections
	NSMutableArray* sections = [NSMutableArray array];
	IFIntelSymbol* parent = [root parent];
	
	int tagCount = 0;
	while (parent != nil) {
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
}

- (void) setIntel: (IFIntelFile*) newIntel {
	[intel release];
	intel = [newIntel retain];
}

- (void) setSection: (IFIntelSymbol*) newSection {
	[root release];
	root = [newSection retain];
	
	[self updateViews];
}

- (void) setSectionByLine: (int) line {
	[self setSection: [intel nearestSymbolToLine: line]];
}

@end
