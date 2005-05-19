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

// = Performing the comparison =

- (NSArray*) compareArrays {
	// Pretty literal implementation of Figure 2 of the paper
	int max = [sourceArray count] + [destArray count];
	int D, k;
	
	int v[max*2+2];
	
	v[max+1] = 0;
	
	for (D=0; D<=max; D++) {
		for (k=-D; k<=D; k++) {
			int x, y;
			
			if (k == -D || (k != D && v[max+k-1] < v[max+k+1])) {
				x = v[max+k+1];
			} else {
				x = v[max+k-1]+1;
			}
			
			y = x - k;
			
			while (x < [sourceArray count] && y < [destArray count] && [[sourceArray objectAtIndex: x] isEqualTo: [destArray objectAtIndex: y]]) {
				x++;
				y++;
			}
			
			v[k+max] = x;
			
			if (x >= [sourceArray count] && y >= [destArray count]) {
				// Length of a SES is D
				NSMutableArray* res = [NSMutableArray array];
				
				return res;
			}
		}
	}
	
	return nil;
}

@end
