//
//  IFErrorsPage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFErrorsPage.h"


@implementation IFErrorsPage

// = Initialisation =

- (id) initWithProjectController: (IFProjectController*) controller {
	self = [super initWithNibName: @"Errors"
				projectController: controller];
	
	if (self) {
		
	}
	
	return self;
}

- (void) dealloc {
	[compilerController release];
	
	[super dealloc];
}

// = Details about this view =

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Errors Page Title"
												  value: @"Errors"
												  table: nil];
}

// = Setting some interface building values =

// (These need to be released, so implement getters/setters)

- (IFCompilerController*) compilerController {
	return compilerController;
}

- (void) setCompilerController: (IFCompilerController*) controller {
	[compilerController release];
	compilerController = [controller retain];
}

@end
