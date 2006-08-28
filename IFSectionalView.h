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
	BOOL calculateSizes;
	NSMutableArray* contents;
	
	// Calculated items
	NSSize idealSize;
}

// Setting up the contents
- (void) clear;													// Removes all of the objects
- (void) addHeading: (NSString*) heading						// Adds a bold heading
				tag: (id) tag;
- (void) addSection: (NSString*) section						// Adds a new section (optionally displaying whether or not it has a subsection)
		subSections: (BOOL) hasSubsections
				tag: (id) tag;

- (NSSize) size;												// The ideal size for this view: it can be resized to have a lower width, but the height must be the same or greater

@end
