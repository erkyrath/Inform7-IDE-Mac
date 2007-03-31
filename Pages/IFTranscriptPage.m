//
//  IFTranscriptPage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFTranscriptPage.h"


@implementation IFTranscriptPage

// = Initialisation =

- (id) initWithProjectController: (IFProjectController*) controller {
	self = [super initWithNibName: @"Transcript"
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
	return [[NSBundle mainBundle] localizedStringForKey: @"Transcript Page Title"
												  value: @"Transcript"
												  table: nil];
}

@end
