//
//  IFStylePreferences.m
//  Inform
//
//  Created by Andrew Hunter on 01/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFStylePreferences.h"


@implementation IFStylePreferences

- (id) init {
	self = [super initWithNibName: @"StylePreferences"];
	
	if (self) {
	}
	
	return self;
}

// = PreferencePane overrides =

- (NSString*) preferenceName {
	return @"Styles";
}

- (NSImage*) toolbarImage {
	return [NSImage imageNamed: @"Styles"];
}

@end
