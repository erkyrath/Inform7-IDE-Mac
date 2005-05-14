//
//  IFTranscriptItem.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 10/05/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


//
// Corresponds to an individual transcript item.
//
// I imagine a large game might end up trying to display ~2000 of these, so we need to be able to handle that
// in a reasonable manner. It would be nice if there was a sensible way to use the layout manager without also
// needing an NSTextView, but that's (apparently) not really possible. Maybe ~6000 textviews is doable, but it
// doesn't sound likely to me.
//
// Annoyingly, Tiger has a mechanism for doing exactly what we're doing with the transcripts. Unfortunately,
// not everyone has Tiger. All Inform code must run OK on Panther at least.
//
@interface IFTranscriptItem : NSObject {
	// Item data
	NSString* command;						// Command that precedes this item (may be nil)
	NSString* transcript;					// The actual transcript from the game (not editable)
	NSString* expected;						// 'Expected' or 'comment' text (editable)
	
	NSDictionary* attributes;				// Font, etc that this item will use
	
	BOOL played;							// Whether or not this item has been played
	BOOL changed;							// Whether or not this item has changed since the last play through
	
	// View data
	float width;							// Width of the view that contains this item
	float offset;							// Offset of this item from the top
	
	// Calculated data
	int textEquality;						// -1 if empty, 0 if not equal, 1 if equal except for whitespace, 2 if exactly equal
	
	BOOL calculated;						// YES if the various calculations are up to date
	float textHeight;
	float height;							// Height of this item
}

// Setting the item data
- (void) setCommand: (NSString*) command;						// Command that precedes this item (may be nil)
- (void) setTranscript: (NSString*) transcript;					// The actual transcript from the game (not editable)
- (void) setExpected: (NSString*) expected;						// 'Expected' or 'comment' text (editable)

- (void) setPlayed: (BOOL) played;								// Whether or not this item has been played in the story
- (void) setChanged: (BOOL) changed;							// Whether or not this item changed on this run through

- (void) setAttributes: (NSDictionary*) attributes;				// Set the attributes used for display

- (NSDictionary*) attributes;									// Retrieve the attributes used for display

// Setting the data from the view
- (void) setWidth: (float) newWidth;							// Total width of the view
- (void) setOffset: (float) offset;								// Offset from the top

- (float) offset;												// Offset from the top

// Calculating the height of this item
- (void) calculateItem;											// Calculates the data associated with this transcript item
- (BOOL) calculated;											// YES if the calculations for this item are up to date
- (float) height;												// The height of this item

// Drawing
- (void) drawAtPoint: (NSPoint) point;							// Draws this transcript item at the given location

@end
