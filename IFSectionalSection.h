//
//  IFSectionalSection.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 28/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

///
/// Data class used by IFSectionalView
///
@interface IFSectionalSection : NSObject {
	// User set items
	NSString* title;
	BOOL isHeading;
	id tag;
	BOOL hasSubsections;
	
	// Calculated items
	NSString* stringToRender;
	NSRect bounds;
}

// Setting/retrieving values
- (void) setTitle: (NSString*) title;
- (void) setHeading: (BOOL) isHeading;
- (void) setTag: (id) tag;
- (void) setHasSubsections: (BOOL) subsections;

- (NSString*) title;
- (BOOL) isHeading;
- (id) tag;
- (BOOL) hasSubsections;

- (void) setStringToRender: (NSString*) string;
- (void) setBounds: (NSRect) bounds;

- (NSString*) stringToRender;
- (NSRect) bounds;

@end
