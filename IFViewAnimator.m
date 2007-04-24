//
//  IFViewAnimator.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 01/09/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import "IFViewAnimator.h"


@implementation IFViewAnimator

// = Initialisation =

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		animationTime = 0.2;
    }
    return self;
}

- (void) dealloc {
	[self finishAnimation];
	
	[startImage release];
	[endImage release];
	[whenStarted release];
	
	[super dealloc];
}

// = Caching views =

+ (void) detrackView: (NSView*) view {
	if ([view respondsToSelector: @selector(removeTrackingRects)]) {
		[view removeTrackingRects];
	}
}

+ (void) trackView: (NSView*) view {
	if ([view respondsToSelector: @selector(setTrackingRects)]) {
		[view setTrackingRects];
	}
}

+ (NSImage*) cacheView: (NSView*) view {
	// Create the cached representation of the view
	NSRect viewFrame = [view frame];
	NSCachedImageRep* cacheRep = [[NSCachedImageRep alloc] initWithSize: viewFrame.size
																  depth: [[NSScreen deepestScreen] depth]
															   separate: YES
																  alpha: YES];
	
	// Move the view to the cached rep's window
	NSView* oldParent = [view superview];
	[IFViewAnimator detrackView: view];
	[view removeFromSuperviewWithoutNeedingDisplay];
	
	if ([[cacheRep window] contentView] == nil) {
		[[cacheRep window] setContentView: [[[NSView alloc] init] autorelease]];
	}
	
	[view setFrame: [cacheRep rect]];
	[[[cacheRep window] contentView] addSubview: view];
	[view setNeedsDisplay: YES];
	
	// Draw the view (initialising the image)
	[[[cacheRep window] contentView] display];
	
	// Move the view back to where it belongs
	[IFViewAnimator detrackView: view];
	[view removeFromSuperviewWithoutNeedingDisplay];
	[view setFrame: viewFrame];
	[oldParent addSubview: view];

	[IFViewAnimator trackView: view];

	// Construct the final image
	NSImage* result = [[NSImage alloc] initWithSize: viewFrame.size];
	
	NSArray* representations = [[[result representations] copy] autorelease];
	NSEnumerator* repEnum = [representations objectEnumerator];
	NSImageRep* rep;
	while (rep = [repEnum nextObject]) {
		[result removeRepresentation: rep];
	}

	[result addRepresentation: [cacheRep autorelease]];
	return [result autorelease];
}

- (void) cacheStartView: (NSView*) view {
	[startImage release];
	startImage = [[[self class] cacheView: view] retain];
}

// = Animating =

- (void) setTime: (float) newAnimationTime {
	animationTime = newAnimationTime;
}

- (void) finishAnimation {
	if (originalView != nil) {
		[self removeFromSuperview];
		
		NSRect frame = originalFrame;
		frame.size = [originalView frame].size;
		
		[originalView setFrame: frame];
		[originalSuperview addSubview: originalView];
		[originalView setNeedsDisplay: YES];
		[IFViewAnimator trackView: originalView];
				
		[originalView release]; originalView = nil;
		[originalSuperview release]; originalSuperview = nil;
		[animationTimer invalidate]; [animationTimer release]; animationTimer = nil;
	}
}

- (void) prepareToAnimateView: (NSView*) view {
	[self finishAnimation];

	// Cache the initial view
	[self cacheStartView: view];

	// Replace the specified view with the animating view (ie, this view)
	[originalView autorelease];
	[originalSuperview release];
	originalView = [view retain];
	originalSuperview = [[view superview] retain];
	originalFrame = [view frame];
		
	[IFViewAnimator detrackView: originalView];
	[originalView removeFromSuperviewWithoutNeedingDisplay];
	[self setFrame: originalFrame];
	[originalSuperview addSubview: self];
	[self setNeedsDisplay: YES];
	
	[self setAutoresizingMask: [originalView autoresizingMask]];
}

- (void) animateTo: (NSView*) view
			 style: (IFViewAnimationStyle) style {
	[whenStarted release];
	whenStarted = [[NSDate date] retain];
	
	// Create the final image
	[endImage release];
	endImage = [[[self class] cacheView: view] retain];
	
	// Replace the specified view with the animating view (ie, this view)
	[originalView autorelease];
	originalView = [view retain];
	originalFrame = [view frame];
	
	[IFViewAnimator detrackView: originalView];
	[self setFrame: originalFrame];
	[originalSuperview addSubview: self];
	[self setNeedsDisplay: YES];
	
	// Start running the animation
	animationStyle = style;
	animationTimer = [[NSTimer timerWithTimeInterval: 0.01
											  target: self
											selector: @selector(animationTick)
											userInfo: nil
											 repeats: YES] retain];
	
	[[NSRunLoop currentRunLoop] addTimer: animationTimer
								 forMode: NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer: animationTimer
								 forMode: NSEventTrackingRunLoopMode];
}

- (float) percentDone {
	NSTimeInterval timePassed = -[whenStarted timeIntervalSinceNow];
	float done = ((float)timePassed)/((float)animationTime);
	
	if (done < 0) done = 0;
	if (done > 1) done = 1.0;
	
	done = -2.0*done*done*done + 3.0*done*done;
	
	return done;
}

- (void) animationTick {
	if ([self percentDone] >= 1.0)
		[self finishAnimation];
	else
		[self setNeedsDisplay: YES];
}

// = Drawing =

static BOOL ViewNeedsDisplay(NSView* view) {
	if (view == nil) return NO;
	if ([view needsDisplay]) return YES;
	
	NSEnumerator* viewEnum = [[view subviews] objectEnumerator];
	NSView* subview;
	while (subview = [viewEnum nextObject]) {
		if (ViewNeedsDisplay(subview)) return YES;
	}
	
	return NO;
}

- (void)drawRect:(NSRect)rect {
	// Recache the view if it wants to be redrawn
	if (ViewNeedsDisplay(originalView)) {
		[endImage release];
		endImage = [[[self class] cacheView: originalView] retain];
	}
	
	// Draw the appropriate animation frame
	float percentDone = [self percentDone];
	float percentNotDone = 1.0-percentDone;
	
	NSRect bounds = [self bounds];
	NSSize startSize = [startImage size];
	NSSize endSize = [endImage size];
	NSRect startFrom, startTo;
	NSRect endFrom, endTo;
	
	switch (animationStyle) {
		case IFAnimateLeft:
			// Work out where to place the images
			startFrom.origin = NSMakePoint(startSize.width*percentDone, 0);
			startFrom.size = NSMakeSize(startSize.width*percentNotDone, startSize.height);
			startTo.origin = NSMakePoint(0, NSMaxY(bounds)-startSize.height);
			startTo.size = startFrom.size;

			endFrom.origin = NSMakePoint(0, 0);
			endFrom.size = NSMakeSize(endSize.width*percentDone, endSize.height);
			endTo.origin = NSMakePoint(startSize.width*percentNotDone, NSMaxY(bounds)-endSize.height);
			endTo.size = endFrom.size;
			
			// Draw them
			[startImage drawInRect: startTo
						  fromRect: startFrom
						 operation: NSCompositeSourceOver
						  fraction: 1.0];
			[endImage drawInRect: endTo
						fromRect: endFrom
					   operation: NSCompositeSourceOver
						fraction: 1.0];
			break;

		case IFAnimateRight:
			// Work out where to place the images
			startFrom.origin = NSMakePoint(0, 0);
			startFrom.size = NSMakeSize(startSize.width*percentNotDone, startSize.height);
			startTo.origin = NSMakePoint(startSize.width*percentDone, NSMaxY(bounds)-startSize.height);
			startTo.size = startFrom.size;
			
			endFrom.origin = NSMakePoint(endSize.width*percentNotDone, 0);
			endFrom.size = NSMakeSize(endSize.width*percentDone, endSize.height);
			endTo.origin = NSMakePoint(0, NSMaxY(bounds)-endSize.height);
			endTo.size = endFrom.size;
			
			// Draw them
			[startImage drawInRect: startTo
						  fromRect: startFrom
						 operation: NSCompositeSourceOver
						  fraction: 1.0];
			[endImage drawInRect: endTo
						fromRect: endFrom
					   operation: NSCompositeSourceOver
						fraction: 1.0];
			break;
			
		case IFFloatIn:
		{
			// New view appears to 'float' in from above
			startTo.origin = bounds.origin;
			startTo.size = startSize;
			startFrom.origin = NSMakePoint(0,0);
			startFrom.size = startSize;
			
			// Draw the old view
			[startImage drawInRect: startTo
						  fromRect: startFrom
						 operation: NSCompositeSourceOver
						  fraction: 1.0];
			
			// Draw the new view
			endFrom.origin = NSMakePoint(0,0);
			endFrom.size = endSize;
			endTo = endFrom;
			endTo.origin = bounds.origin;
			
			float scaleFactor = 0.95 + 0.05*percentDone;
			endTo.size.height *= scaleFactor;
			endTo.size.width *= scaleFactor;
			endTo.origin.x += (endFrom.size.width - endTo.size.width) / 2;
			endTo.origin.y += (endFrom.size.height - endTo.size.height) + 10.0*percentNotDone;
			
			[endImage drawInRect: endTo
						fromRect: endFrom
					   operation: NSCompositeSourceOver
						fraction: percentDone];
			break;
		}

		case IFFloatOut:
		{
			// Old view appears to 'float' out above
			endTo.origin = bounds.origin;
			endTo.size = endSize;
			endFrom.origin = NSMakePoint(0,0);
			endFrom.size = endSize;
			
			// Draw the old view
			[endImage drawInRect: endTo
						fromRect: endFrom
					   operation: NSCompositeSourceOver
						fraction: 1.0];
			
			// Draw the new view
			startFrom.origin = NSMakePoint(0,0);
			startFrom.size = startSize;
			startTo = startFrom;
			startTo.origin = bounds.origin;
			
			float scaleFactor = 0.95 + 0.05*percentNotDone;
			startTo.size.height *= scaleFactor;
			startTo.size.width *= scaleFactor;
			startTo.origin.x += (startFrom.size.width - startTo.size.width) / 2;
			startTo.origin.y += (startFrom.size.height - startTo.size.height) + 10.0*percentDone;
			
			[startImage drawInRect: startTo
						  fromRect: startFrom
						 operation: NSCompositeSourceOver
						  fraction: percentNotDone];
			break;
		}
	}
}

@end
