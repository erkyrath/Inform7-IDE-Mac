//
//  IFHeaderController.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 19/12/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFHeaderController.h"


@implementation IFHeaderController

- (void) setChildrenForHeader: (IFHeader*) root
					   symbol: (IFIntelSymbol*) symbol 
					  recurse: (BOOL) recurse {
	IFIntelSymbol* child = [symbol child];
	
	// If the symbol has no children then don't add it to the list
	if (!child) {
		[root setChildren: [NSArray array]];
		return;
	}
	
	// Otherwise, build up the set of symbols from the children of this item
	NSMutableArray* newChildren = [[[NSMutableArray alloc] init] autorelease];
	while (child) {
		// Build the new header
		IFHeader* newChild = [[IFHeader alloc] initWithName: [symbol name]
													 parent: root
												   children: nil];
		[newChild setSymbol: child];
		
		// Add it to the array
		[newChildren addObject: newChild];
		
		// Recurse if necessary
		if (recurse) {
			[self setChildrenForHeader: newChild
								symbol: child
							   recurse: YES];
		}
		
		// Done with this item
		[newChild release];

		// Move onto the sibling for this header
		child = [child sibling];
	}
	
	// Set the children for this symbol
	[root setChildren: newChildren];
}
					   

- (void) updateFromIntelligence: (IFIntelFile*) intel {
	// Firstly, build up a header structure from the intelligence object
	IFHeader* newRoot = [[IFHeader alloc] initWithName: @"Root"
												parent: nil 
											  children: nil];
	[newRoot autorelease];
	[self setChildrenForHeader: newRoot
						symbol: [intel firstSymbol]
					   recurse: YES];
	
	// Now, compare to the existing headings and update as appropriate, flagging those that
	// need to be removed or added.
}

@end
