//
//  IFRemoveViewWhenDone.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 17/02/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFRemoveViewWhenDone.h"


@implementation IFRemoveViewWhenDone

- (id) initWithView: (NSView*) newView {
	self = [super init];
	
	if (self) {
		view = [newView retain];
	}
	
	return self;
}

- (void) dealloc {
	[view autorelease];
	[super dealloc];
}

- (void)animationDidStop:(CAAnimation *)theAnimation
				finished:(BOOL)flag {
	// Remove the view
	[view removeFromSuperview];
	
	// Should have been retained by whatever created this object
	[self autorelease];
}

@end
