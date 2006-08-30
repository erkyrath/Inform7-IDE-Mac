//
//  IFSectionalView.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 28/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


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
}

// Setting up the contents
- (void) clear;													// Removes all of the objects
- (void) addHeading: (NSString*) heading						// Adds a bold heading
				tag: (id) tag;
- (void) addSection: (NSString*) section						// Adds a new section (optionally displaying whether or not it has a subsection)
		subSections: (BOOL) hasSubsections
				tag: (id) tag;

- (NSSize) idealSize;											// The ideal size for this view: it can be resized to have a lower width, but the height must be the same or greater

@end
