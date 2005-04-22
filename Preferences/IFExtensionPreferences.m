//
//  IFExtensionPreferences.m
//  Inform
//
//  Created by Andrew Hunter on 02/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFExtensionPreferences.h"

#import "IFExtensionsManager.h"

@implementation IFExtensionPreferences

- (id) init {
	self = [super initWithNibName: @"ExtensionPreferences"];
	
	if (self) {
		// Set the data sources
		[naturalExtensionView setDataSource: [IFExtensionsManager sharedNaturalInformExtensionsManager]];
		[inform6ExtensionView setDataSource: [IFExtensionsManager sharedInform6ExtensionManager]];
		
		// Register for drag+drop
		[naturalExtensionView registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
		[inform6ExtensionView registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
		
		// Receive updates on the extensions
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(reloadExtensions:)
													 name: IFExtensionsUpdatedNotification
												   object: nil];
	}
	
	return self;
}

- (void) reloadExtensions: (NSNotification*) not {
	NSObject* obj = [not object];
	
	if (obj == [IFExtensionsManager sharedNaturalInformExtensionsManager]) {
		[naturalExtensionView reloadData];
	} else if (obj == [IFExtensionsManager sharedInform6ExtensionManager]) {
		[inform6ExtensionView reloadData];
	}
}

- (void) dealloc {
	// Will probably never be called
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[super dealloc];
}

// = PreferencePane overrides =

- (NSString*) preferenceName {
	return @"Extensions";
}

- (NSImage*) toolbarImage {
	return [NSImage imageNamed: @"Extensions"];
}

@end
