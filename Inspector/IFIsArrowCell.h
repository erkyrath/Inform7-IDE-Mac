//
//  IFIsArrowCell.h
//  Inform
//
//  Created by Andrew Hunter on Fri Apr 30 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>

// Cell representing the flippy arrow thingie used to hide/reveal inspectors
// Not using a Disclosure button because that's not supported on Jaguar

@interface IFIsArrowCell : NSActionCell {
	NSRect currentFrame; // Used for mouse tracking
	
	int state;
	
	// The 'up/down' animation
	int endState;
	NSTimer* animationTimeout;
	
	NSView* lastControlView;
}

- (void) performFlip;

@end
