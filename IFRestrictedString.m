//
//  IFRestrictedString.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 05/01/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFRestrictedString.h"


@implementation IFRestrictedString

// = Initialisation =

- (id) initWithString: (NSString*) source {
	self = [self init];
	
	if (self) {
		sourceString = [source retain];
		restriction = NSMakeRange(0, [sourceString length]);
	}
	
	return self;
}

- (void) dealloc {
	[sourceString autorelease];
	
	[super dealloc];
}

- (void) setRestriction: (NSRange) newRestriction {
	restriction = newRestriction;
}

// = Mandatory NSString methods =

- (unsigned int) length {
	return restriction.length;
}

- (unichar)characterAtIndex: (unsigned int) index {
	return [sourceString characterAtIndex: index + restriction.location];
}

// = Extra NSString methods =

- (void) getCharacters: (unichar*) buffer {
	[sourceString getCharacters: buffer
						  range: restriction];
}

- (void) getCharacters: (unichar*) buffer
				 range: (NSRange) range {
	[sourceString getCharacters: buffer
						  range: NSMakeRange(range.location + restriction.location, range.length)];
}

- (NSString*) substringWithRange: (NSRange)range {
	return [sourceString substringWithRange: NSMakeRange(range.location + restriction.location, range.length)];
}

@end
