//
//  IFGamePage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFGamePage.h"


@implementation IFGamePage

// = Initialisation =

- (id) initWithProjectController: (IFProjectController*) controller {
	self = [super initWithNibName: @"Game"
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
	return [[NSBundle mainBundle] localizedStringForKey: @"Game Page Title"
												  value: @"Game"
												  table: nil];
}

@end
