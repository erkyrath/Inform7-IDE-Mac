//
//  NSPretendTextView.h
//  Inform
//
//  Created by Andrew Hunter on 02/12/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//
// View that morphs into a text view first time it is displayed
//
@interface IFPretendTextView : NSView {
	NSString* eventualString;
}

// Setting up
- (void) setEventualString: (NSString*) newEventualString;

@end
