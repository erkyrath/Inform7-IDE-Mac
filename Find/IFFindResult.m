//
//  IFFindResult.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 17/02/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFFindResult.h"


@implementation IFFindResult


// = Initialisation =

- (id) initWithMatchType: (NSString*) newMatchType
				location: (NSString*) newLocationDescription
				 context: (NSString*) newContext
			contextRange: (NSRange) newHighlightRange
					data: (id) newData {
	self = [super init];
	
	if (self) {
		matchType		= [newMatchType retain];
		location		= [newLocationDescription retain];
		context			= [newContext retain];
		contextRange	= newHighlightRange;
		data			= [newData retain];
	}
	
	return self;
}

- (void) dealloc {
	[matchType autorelease];
	[location autorelease];
	[context autorelease];
	[data autorelease];
	
	[super dealloc];
}

// = Data =

- (NSString*) matchType {
	return matchType;
}

- (NSString*) location {
	return location;
}

- (NSString*) context {
	return context;
}

- (NSRange) contextRange {
	return contextRange;
}

- (id) data {
	return data;
}

- (NSAttributedString*) attributedContext {
	NSDictionary* normalAttributes = [NSDictionary dictionaryWithObjectsAndKeys: 
									  [NSFont systemFontOfSize: 9], NSFontAttributeName,
									  nil];
	NSDictionary* boldAttributes = [NSDictionary dictionaryWithObjectsAndKeys: 
									[NSFont boldSystemFontOfSize: 11], NSFontAttributeName,
									nil];
	
	NSMutableAttributedString* result = [[[NSMutableAttributedString alloc] initWithString: [self context]
																				attributes: normalAttributes] autorelease];
	[result addAttributes: boldAttributes
					range: [self contextRange]];
	
	return result;
}

// = Copying =

- (id) copyWithZone: (NSZone*) zone {
	return [self retain];
}

@end
