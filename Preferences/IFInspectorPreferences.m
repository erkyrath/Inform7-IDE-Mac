//
//  IFInspectorPreferences.m
//  Inform
//
//  Created by Andrew Hunter on 02/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFInspectorPreferences.h"


@implementation IFInspectorPreferences

- (id) init {
	self = [super initWithNibName: @"InspectorPreferences"];
	
	if (self) {
	}
	
	return self;
}

// = PreferencePane overrides =

- (NSString*) preferenceName {
	return @"Inspectors";
}

- (NSImage*) toolbarImage {
	return [NSImage imageNamed: @"Inspectors"];
}

@end
