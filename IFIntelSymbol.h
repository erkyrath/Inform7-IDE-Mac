//
//  IFIntelSymbol.h
//  Inform
//
//  Created by Andrew Hunter on 05/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Our relationship to the preceding symbol in the file
enum IFSymbolRelation {
	IFSymbolOnLevel = 0,		// Delta = the level the symbol is on compared to the preceeding symbol of the same type
	IFSymbolDeltaLevel			// Delta = number of levels up (or down if negative) for this symbol
};

// Standard symbol types
extern NSString* IFSectionSymbolType;	// Natural Inform section
// (IMPLEMENT ME: Inform 6 objects, etc)

@class IFIntelFile;

//
// A single symbol gathered by the 'intelligence'
//
@interface IFIntelSymbol : NSObject<NSCopying> {
	// Our data
	NSString* name;
	NSString* type;
	int level;
	enum IFSymbolRelation relation;
	int levelDelta;
	
	// The file we're stored in
	IFIntelFile* ourFile;
	
	// Our relation in the list of symbols
@public
	// Only public to IFIntelFile
	IFIntelSymbol* nextSymbol;
	IFIntelSymbol* lastSymbol;
}

// Symbol data
- (NSString*) name;
- (NSString*) type;
- (int) level;
- (enum IFSymbolRelation) relation;
- (int) levelDelta;

- (void) setName: (NSString*) newName;
- (void) setType: (NSString*) newType;
- (void) setLevel: (int) level;
- (void) setRelation: (enum IFSymbolRelation) relation;
- (void) setLevelDelta: (int) newDelta;

// (If we're stored in an IFIntelFile, our relation to other symbols in the file)
- (IFIntelSymbol*) parent;			// May go down multiple levels
- (IFIntelSymbol*) child;
- (IFIntelSymbol*) sibling;
- (IFIntelSymbol*) previousSibling;

@end

#import "IFIntelFile.h"
