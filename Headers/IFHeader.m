//
//  IFHeader.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 19/12/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFHeader.h"


@implementation IFHeader

// Initialisation

- (id) init {
	return [self initWithName: @""
					   parent: nil
					 children: nil];
}

- (id) initWithName: (NSString*) name
			 parent: (IFHeader*) newParent
		   children: (NSArray*) newChildren {
	self = [super init];
	
	if (self) {
		headingName = [name copy];
		parent = newParent;
		
		if (newChildren) {
			children = [[NSMutableArray alloc] initWithArray: newChildren
												   copyItems: NO];
		} else {
			children = [[NSMutableArray alloc] init];
		}
		
		NSEnumerator* childEnum = [children objectEnumerator];
		IFHeader* child;
		while (child = [childEnum nextObject]) {
			[child setParent: self];
		}
	}
	
	return self;
}

// Accessing values

- (NSString*) headingName {
	return [[headingName retain] autorelease];
}

- (IFHeader*) parent {
	return [[parent retain] autorelease];
}

- (NSArray*) children {
	return [[children retain] autorelease];
}

- (void) setHeadingName: (NSString*) newName {
	[headingName release];
	headingName = [newName retain];
}

- (void) setParent: (IFHeader*) newParent {
	parent = newParent;
}

- (void) setChildren: (NSArray*) newChildren {
	NSEnumerator* childEnum = [children objectEnumerator];
	IFHeader* child;
	while (child = [childEnum nextObject]) {
		[child setParent: nil];
	}

	[children release];
	if (newChildren) {
		children = [[NSMutableArray alloc] initWithArray: newChildren
											   copyItems: NO];
	} else {
		children = [[NSMutableArray alloc] init];
	}
	
	childEnum = [children objectEnumerator];
	while (child = [childEnum nextObject]) {
		[child setParent: self];
	}
}

@end
