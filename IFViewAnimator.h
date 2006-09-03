//
//  IFViewAnimator.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 01/09/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum IFViewAnimationStyle {
	IFAnimateLeft,
	IFAnimateRight
} IFViewAnimationStyle;

///
/// A class that can be used to perform various animations for a particular view
///
@interface IFViewAnimator : NSView {
	// The start and the end of the animation
	NSImage* startImage;
	NSImage* endImage;
	
	// Animation settings
	NSTimeInterval animationTime;
	IFViewAnimationStyle animationStyle;
	
	// Information used while animating
	NSTimer* animationTimer;
	NSRect originalFrame;
	NSView* originalView;
	NSView* originalSuperview;
	NSDate* whenStarted;
}

// Caching views
+ (NSImage*) cacheView: (NSView*) view;								// Returns an image with the contents of the specified view
- (void) cacheStartView: (NSView*) view;							// Caches a specific image as the start of an animation

// Animating
- (void) prepareToAnimateView: (NSView*) view;						// Prepares to animate, using the specified view as a template
- (void) animateTo: (NSView*) view									// Begins animating the specified view so that transitions from the state set in prepareToAnimateView to the new state
			 style: (IFViewAnimationStyle) style;
- (void) finishAnimation;											// Abandons any running animation

@end

@interface NSObject(IFViewAnimation)

- (void) removeTrackingRects;										// Optional method implemented by views that is a request from the animation view to remove any applicable tracking rectangles
- (void) setTrackingRects;											// Optional method implemented by views that is a request from the animation view to add any tracking rectangles back again

@end
