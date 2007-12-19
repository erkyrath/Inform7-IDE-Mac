//
//  IFHeader.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 19/12/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFHeader.h"


NSString* IFHeaderChangedNotification = @"IFHeaderChangedNotification";

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

- (void) dealloc {
	NSEnumerator* childEnum = [children objectEnumerator];
	IFHeader* child;
	while (child = [childEnum nextObject]) {
		[child setParent: nil];
	}

	[headingName release];
	[children release];
	
	[super dealloc];
}

// Accessing values

- (void) hasChanged {
	[[NSNotificationCenter defaultCenter] postNotificationName: IFHeaderChangedNotification
														object: self];
}

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
	
	[self changed];
}

- (void) setParent: (IFHeader*) newParent {
	if (newParent == parent) return;
	
	parent = newParent;
	[self changed];
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
	
	[self changed];
}

@end
