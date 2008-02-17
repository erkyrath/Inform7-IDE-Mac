//
//  IFRemoveLayerWhenDone.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 17/02/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFRemoveLayerWhenDone.h"


@implementation IFRemoveLayerWhenDone

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
	// Remove the layer from this view
	[view setWantsLayer: NO];
	//[view setLayer: nil];
}

@end
