//
//  IFPage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFPage.h"


@implementation IFPage

// = Initialisation =

- (id) initWithNibName: (NSString*) nib
	 projectController: (IFProjectController*) controller {
	self = [super init];
	
	if (self) {
		parent = controller;
	}
	
	return self;
}

- (void) dealloc {
	if (releaseView) [view release];
	[super dealloc];
}

// = Details about this view =

- (NSString*) title {
	return @"Untitled";
}

- (NSView*) view {
	return view;
}

- (IBOutlet void) setView: (NSView*) newView {
	if (releaseView) [view release];
	view = [newView retain];
	releaseView = YES;
}

@end
