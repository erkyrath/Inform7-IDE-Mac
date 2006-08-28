//
//  IFSectionalSection.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 28/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import "IFSectionalSection.h"


@implementation IFSectionalSection

// = Initialisation =

- (void) dealloc {
	[title release];
	[tag autorelease];
	[stringToRender release];
	
	[super dealloc];
}

// = Setting/retrieving values =

- (void) setTitle: (NSString*) newTitle {
	[title autorelease];
	title = [newTitle copy];
}

- (void) setHeading: (BOOL) heading {
	isHeading = heading;
}

- (void) setTag: (id) newTag {
	[tag autorelease];
	tag = [newTag retain];
}

- (void) setHasSubsections: (BOOL) subsections {
	hasSubsections = subsections;
}

- (NSString*) title {
	return title;
}

- (BOOL) isHeading {
	return isHeading;
}

- (id) tag {
	return tag;
}

- (BOOL) hasSubsections {
	return hasSubsections;
}

- (void) setStringToRender: (NSString*) string {
	[stringToRender release];
	stringToRender = [string copy];
}

- (void) setBounds: (NSRect) newBounds {
	bounds = newBounds;
}

- (NSString*) stringToRender {
	return stringToRender;
}

- (NSRect) bounds {
	return bounds;
}

@end
