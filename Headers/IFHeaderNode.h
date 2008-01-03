//
//  IFHeaderNode.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 03/01/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFHeader.h"

typedef enum IFHeaderNodeSelectionStyle {
	IFHeaderNodeUnselected,					// Node is unselected
	IFHeaderNodeSelected,					// Node has been selected by the user
	IFHeaderNodeInputCursor					// Node contains the input cursor
} IFHeaderNodeSelectionStyle;

///
/// A single node in a header view
///
@interface IFHeaderNode : NSObject {
	NSPoint position;								// The position of this node
	NSRect frame;									// The frame for this node
	int depth;										// The depth of this node in the tree
	
	IFHeader* header;								// The IFHeader item associated with this node
	NSMutableArray* children;						// The child nodes of this node
}

// Constructing this node

- (id) initWithHeader: (IFHeader*) header			// Constructs a new header node
			 position: (NSPoint) position
				depth: (int) depth;
- (void) populateToDepth: (int) maxDepth;			// Populates this node to the specified depth

// Getting information about this node

- (NSRect) frame;									// The frame for this node
- (IFHeader*) header;								// The header associated with this node
- (IFHeaderNodeSelectionStyle) selectionStyle;		// The selection style of this node
- (void) setSelectionStyle: (IFHeaderNodeSelectionStyle) selectionStyle;

// Drawing the node

- (void) drawNodeInRect: (NSRect) rect				// Draws this node
			  withFrame: (NSRect) frame;

@end
