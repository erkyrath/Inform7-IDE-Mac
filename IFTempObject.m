//
//  IFTempObject.m
//  Inform
//
//  Created by Andrew Hunter on 09/03/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFTempObject.h"


@implementation IFTempObject

- (id) initWithObject: (NSObject*) tempObject
			 delegate: (id) dg {
	self = [super init];
	
	if (self) {
		object = [tempObject retain];
		delegate = [dg retain];
	}
	
	return self;
}

- (void) dealloc {
	// Notify the delegate
	if (object && delegate && [delegate respondsToSelector: @selector(tempObjectHasDeallocated:)]) {
		[delegate tempObjectHasDeallocated: object];
	}
	
	[object release]; object = nil;
	[delegate release]; delegate = nil;
	
   	[super dealloc];
}

@end
