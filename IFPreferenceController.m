//
//  IFPreferenceController.m
//  Inform
//
//  Created by Andrew Hunter on 12/01/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFPreferenceController.h"


@implementation IFPreferenceController

// = Construction =

+ (IFPreferenceController*) sharedPreferenceController {
	static IFPreferenceController* sharedPrefController = nil;

	if (sharedPrefController == nil) {
		sharedPrefController = [[IFPreferenceController alloc] init];
	}
}

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
		
	}
	
	return self;
}

// = Preference switching =

@end
