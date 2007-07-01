//
//  IFMatcherStructure.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 27/06/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFMatcherStructure.h"


@implementation IFMatcherStructure

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
		title = [@"" retain];
		regexp = [@"" retain];
	}
	
	return self;
}

- (void) dealloc {
	[title release]; title = nil;
	[regexp release]; regexp = nil;
	[matcher release]; matcher = nil;
	
	[super dealloc];
}

// = Handling the values in this structure =

- (NSString*) title {
	return title;
}

- (void) setTitle:(NSString*) newTitle {
	if (newTitle == nil) newTitle = @"";
	[title release];
	title = [newTitle copy];
}

- (NSString*) regexp {
	return regexp;
}

- (void) setRegexp: (NSString*) newRegexp {
	if (newRegexp == nil) newRegexp = @"";
	[regexp release];
	regexp = [newRegexp copy];
}

- (IFMatcher*) matcher {
	if (matcher == nil) matcher = [[IFMatcher alloc] init];
	return matcher;
}

@end
