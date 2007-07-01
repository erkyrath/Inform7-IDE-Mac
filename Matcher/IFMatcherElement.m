//
//  IFMatcherElement.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 27/06/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFMatcherElement.h"


@implementation IFMatcherElement

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
		description = [@"" retain];
		link = [@"" retain];
	}
	
	return self;
}

- (void) dealloc {
	[description release]; description = nil;
	[link release]; link = nil;
	
	[super dealloc];
}

// = Setting the values in this element =

- (NSString*) elementDescription {
	return description;
}

- (void) setElementDescription: (NSString*) newDescription {
	if (newDescription == nil) newDescription = @"";
	[description release];
	description = [newDescription copy];
}

- (NSString*) elementLink {
	return link;
}

- (void) setElementLink: (NSString*) newLink {
	if (newLink == nil) newLink = @"";
	[link release];
	link = [newLink copy];
}

@end
