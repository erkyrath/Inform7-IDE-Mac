//
//  IFSectionalView.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 28/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFSectionalSection.h"


///
/// Hierarchical view for showing things by section
///
@interface IFSectionalView : NSView {
	// Details about the sections
	BOOL calculateSizes;										// If true, then we need to calculate the size of the sections in this view
	BOOL compactStrings;										// If true, then we need to compact the strings in this view so that they fit
	NSMutableArray* contents;									// An array of IFSectionalSections
	
	// Calculated items
	NSSize idealSize;											// The ideal size for this control
	NSMutableArray* tracking;									// Array of tracking rectangle tags (NSNumbers)
	IFSectionalSection* highlighted;							// The section that is curren
	
	// The actions
	id target;
	SEL selectedItem;
	SEL gotoSubsection;
}

// Setting up the contents
- (void) clear;													// Removes all of the objects
- (void) addHeading: (NSString*) heading						// Adds a bold heading
				tag: (id) tag;
- (void) addSection: (NSString*) section						// Adds a new section (optionally displaying whether or not it has a subsection)
		subSections: (BOOL) hasSubsections
				tag: (id) tag;
- (id) highlightedTag;											// The tag for the currently highlighted symbol

- (NSSize) idealSize;											// The ideal size for this view: it can be resized to have a lower width, but the height must be the same or greater

// = The actions =

- (void) setTarget: (id) target;								// Sets the target for messages from this control (this is not retained)
- (void) setSelectedItemAction: (SEL) action;					// Sets the action sent when an item is selected
- (void) setGotoSubsectionAction: (SEL) action;					// Sets the action sent when we are requested to go to a specific subsection

@end
