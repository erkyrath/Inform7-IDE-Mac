//
//  IFIntelSymbol.m
//  Inform
//
//  Created by Andrew Hunter on 05/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFIntelSymbol.h"

NSString* IFSectionSymbolType = @"IFSectionSymbolType";

@implementation IFIntelSymbol

// = Initialisation =

- (void) dealloc {
	if (name) [name release];
	if (type) [type release];
	
	// ourFile releases us, not the other way around
	
	//if (nextSymbol) [nextSymbol release];
	// if (lastSymbol) [lastSymbol release]; -- not retained when set (ensures that we actually get released!)
	
	[super dealloc];
}

// = Symbol data =

- (NSString*) name {
	return name;
}

- (NSString*) type {
	return type;
}

- (int) level {
	if (level < 0) {
		// IMPLEMENT ME: calculate level relative to previous item, return that (might have changed since last time)
		return -1;
	}
	
	return level;
}

- (enum IFSymbolRelation) relation {
	return relation;
}

- (int) levelDelta {
	return levelDelta;
}

- (void) setName: (NSString*) newName {
	if (name) [name release];
	name = [newName copy];
}

- (void) setType: (NSString*) newType {
	if (type) [type release];
	type = [newType copy];
}

- (void) setLevel: (int) newLevel {
	level = newLevel;
}

- (void) setRelation: (enum IFSymbolRelation) newRelation {
	relation = newRelation;
}

- (void) setLevelDelta: (int) newDelta {
	levelDelta = newDelta;
}

// = Debug =

- (NSString*) description {
	NSMutableString* res = [NSMutableString string];
	
	[res appendFormat: @"IFIntelSymbol '%@' - delta %i", name, levelDelta];
	
	return res;
}

// = Our relation to other symbols in the file =

- (IFIntelSymbol*) parent {
}

- (IFIntelSymbol*) child {
}

- (IFIntelSymbol*) sibling {
}

- (IFIntelSymbol*) previousSibling {
}

@end
