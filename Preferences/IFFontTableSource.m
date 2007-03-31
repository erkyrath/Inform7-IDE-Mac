//
//  IFFontTableSource.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 07/01/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFFontTableSource.h"


@interface IFFontTableSource(Private)

- (NSArray*) families;

@end

///
/// Annoyingly, if I set the data source of the table views to the window controller object (which would
/// be a lot easier), Cocoa screws up and releases the table view objects, causing everything to die
/// horribly.
///
@implementation IFFontTableSource

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
		collection = [@"All Fonts" copy];
	}
	
	return self;
}

- (void) dealloc {
	[collection release];
	[families release];
	
	[super dealloc];
}

// = Setting up =

- (void) setCollection: (NSString*) collectionName {
	[collection release];
	collection = [collectionName copy];
	
	[families release];
	families = nil;
}

// = Getting data =

- (int) rowForCollection: (NSString*) collectionName {
	return [[[NSFontManager sharedFontManager] collectionNames] indexOfObject: collectionName];
}

- (int) rowForFamily: (NSString*) family {
	return [[self families] indexOfObject: family];
}

// = Being a Table Source =

- (NSArray*) families {
	if (!families) {
		NSMutableSet* familySet = [NSMutableSet set];
		NSArray* descriptors;
		
		if ([collection isEqualTo: @"All Fonts"]) {
			families = [[[NSFontManager sharedFontManager] availableFontFamilies] mutableCopy];
			[families sortUsingSelector: @selector(caseInsensitiveCompare:)];
		} else {
			descriptors = [[NSFontManager sharedFontManager] fontDescriptorsInCollection: collection];
		
			NSEnumerator* descEnum = [descriptors objectEnumerator];
			NSFontDescriptor* desc;
			
			while (desc = [descEnum nextObject]) {
				[familySet addObject: [desc objectForKey: NSFontFamilyAttribute]];
			}
			
			families = [[familySet allObjects] mutableCopy];
			[families sortUsingSelector: @selector(caseInsensitiveCompare:)];
		}
	}
	
	return families;
}

- (int)numberOfRowsInTableView: (NSTableView*) view {
	NSFontManager* fm = [NSFontManager sharedFontManager];
	
	switch ([view tag]) {
		case 1:
			// Return the number of font collections
			return [[fm collectionNames] count];
			
		case 2:
			return [[self families] count];
	}
	
	// Fallback case
	return 0;
}

- (id)				tableView:(NSTableView *) view
	objectValueForTableColumn:(NSTableColumn *) column
						  row:(int) index {
	NSFontManager* fm = [NSFontManager sharedFontManager];
	
	switch ([view tag]) {
		case 1:
			// Return the number of font collections
			return [[fm collectionNames] objectAtIndex: index];
			
		case 2:
			if (index >= [[self families] count]) return nil;
			return [[self families] objectAtIndex: index];
	}
	
	// Fallback case
	return nil;
}

@end
