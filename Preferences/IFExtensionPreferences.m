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
		[naturalExtensionView setDataSource: [IFExtensionsManager sharedNaturalInformExtensionsManager]];
		[inform6ExtensionView setDataSource: [IFExtensionsManager sharedInform6ExtensionManager]];
	}
	
	return self;
}

// = PreferencePane overrides =

- (NSString*) preferenceName {
	return @"Extensions";
}

- (NSImage*) toolbarImage {
	return [NSImage imageNamed: @"Extensions"];
}

@end
