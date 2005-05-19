//
//  IFDiffStep.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 19/05/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum IFDiffType {
	IFDiffRemoveItem,					// Item removed from the source array (in the graph, this represents a step across)
	IFDiffAddItem,						// Item added to the source array (step down)
	IFDiffSameItem,						// Item is the same in both arrays (diagonal step)
};

//
// Representation of a difference noted by IFDiff
//
@interface IFDiffStep : NSObject {
	NSObject* item;						// The item this step applies to
	enum IFDiffType type;				// The type of difference
}

// Initialisation
- (id) initWithObject: (NSObject*) item
				 type: (enum IFDiffType) type;

// Dealing with the encapsulated information
- (void) setItem: (NSObject*) item;
- (void) setType: (enum IFDiffType) type;

- (NSObject*) item;
- (enum IFFDiffType) type;

@end
