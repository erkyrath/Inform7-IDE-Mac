//
//  IFHeader.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 19/12/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString* IFHeaderChangedNotification;	// Notification send when this heading has changed

///
/// Model class representing a header in the header browser.
///
/// We build a separate model of these to better facilitate animating between states under Leopard.
///
@interface IFHeader : NSObject {
	NSString* headingName;						// The name of this header
	IFHeader* parent;							// The parent of this header (NOT RETAINED)
	NSMutableArray* children;					// The child headings for this heading
}

// Initialisation
- (id) initWithName: (NSString*) name			// Constructs a new header object
			 parent: (IFHeader*) parent
		   children: (NSArray*) children;

// Accessing values
- (NSString*) headingName;							// The name of this header
- (IFHeader*) parent;								// The parent of this header
- (NSArray*) children;								// The headings 'beneath' this one

- (void) setHeadingName: (NSString*) newName;		// Sets the name of this header
- (void) setParent: (IFHeader*) parent;				// The parent for this header
- (void) setChildren: (NSArray*) children;			// Updates the children for this item

@end
