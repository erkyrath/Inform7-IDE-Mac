//
//  IFSkeinPage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFSkeinPage.h"


@implementation IFSkeinPage

// = Initialisation =

- (id) initWithProjectController: (IFProjectController*) controller {
	self = [super initWithNibName: @"Skein"
				projectController: controller];
	
	if (self) {
		
	}
	
	return self;
}

- (void) dealloc {
	[super dealloc];
}

// = Details about this view =

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Skein Page Title"
												  value: @"Skein"
												  table: nil];
}

@end
