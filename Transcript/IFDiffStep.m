//
//  IFDiffStep.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 19/05/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFDiffStep.h"


@implementation IFDiffStep

// = Initialisation =

- (id) initWithObject: (NSObject*) newItem
				 type: (enum IFDiffType) newType {
	self = [super init];
	
	if (self) {
		item = [newItem retain];
		type = newType;
	}
	
	return self;
}

// = Dealing with the encapsulated information =

- (void) setItem: (NSObject*) newItem {
	[item release];
	item = [newItem retain];
}

- (void) setType: (enum IFDiffType) newType {
	type = newType;
}

- (NSObject*) item {
	return item;
}

- (enum IFFDiffType) type {
	return type;
}

@end
