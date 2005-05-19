//
//  IFDiff.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 19/05/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFDiff.h"


@implementation IFDiff

// = Initialisation =

- (id) init {
	return [self initWithSourceArray: [NSArray array]
					destinationArray: [NSArray array]];
}

- (id) initWithSourceArray: (NSArray*) newSourceArray
		  destinationArray: (NSArray*) newDestArray {
	self = [super init];
	
	if (self) {
		sourceArray = [newSourceArray retain];
		destArray = [newDestArray retain];
	}
	
	return self;
}

- (void) dealloc {
	[sourceArray release];
	[destArray release];
	
	[super dealloc];
}

@end
