//
//  IFLeopard.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 09/12/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFLeopard.h"


@implementation IFLeopard

// = Text view magic =

 - (void) showFindIndicatorForRange: (NSRange) charRange
						inTextView: (NSTextView*) textView {
	[textView showFindIndicatorForRange: charRange];
}

// = Animation =

- (void) prepareToAnimateView: (NSView*) view
						layer: (CALayer*) layer {
	NSEnumerator* subviewEnum = [[view subviews] objectEnumerator];
	NSView* subview;
	while (subview = [subviewEnum nextObject]) {
		[self prepareToAnimateView: subview
							 layer: nil];		
	}
	
	if (![view wantsLayer]) {
		[view setWantsLayer: YES];
		[view setNeedsDisplay: YES];
		[[view layer] setNeedsDisplay];
	}
	
	[view layer].backgroundColor = CGColorCreateGenericRGB(0, 0,0,0);
}

- (void) prepareToAnimateView: (NSView*) view {
	[self prepareToAnimateView: view
						 layer: [CALayer layer]];

	NSColor* winColour = [[view window] backgroundColor];
	
	// This will fail if Apple ever re-introduces the pinstripes. (Grr, why isn't there a generic way to convert to CGColors?)
	winColour = [winColour colorUsingColorSpaceName: NSDeviceRGBColorSpace];
	float components[4];
	[winColour getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];

	CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
	CGColorRef annoyingCgColour = CGColorCreate(colourSpace, components);
	[view layer].backgroundColor = annoyingCgColour;
	
	CGColorSpaceRelease(colourSpace);
	CGColorRelease(annoyingCgColour);
}

- (void) setFrame: (NSRect) newFrame
		 ofWindow: (NSWindow*) window {
	[window setFrame: newFrame
			 display: YES
			 animate: NO];
	/*
	[[window animator] setFrame: newFrame
						display: YES];
	 */
}

- (void) setFrame: (NSRect) frame
		   ofView: (NSView*) view {
	if (![view wantsLayer]) { 
		[self prepareToAnimateView: view];
	}
	
	[[view animator] setFrame: frame];
}

- (void) addView: (NSView*) newView
		  toView: (NSView*) superView {
	[newView removeFromSuperview];
	if (![superView wantsLayer]) {
		[self prepareToAnimateView: superView];
	}
	if (![newView wantsLayer]) { 
		[self prepareToAnimateView: newView];
	}
	
	newView.layer.opacity = 1.0;
	
	[superView addSubview: newView];
	
	// Fade up the view
	CABasicAnimation* fadeAnimation = [CABasicAnimation animation];
	fadeAnimation.keyPath			= @"opacity";
	fadeAnimation.fromValue			= [NSNumber numberWithFloat: 0.0];
	fadeAnimation.toValue			= [NSNumber numberWithFloat: 1.0];
	fadeAnimation.beginTime			= CACurrentMediaTime();
	fadeAnimation.repeatCount		= 1;
	fadeAnimation.duration			= 0.3;
	fadeAnimation.timingFunction	= [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
									   
	// Also scale it up
	CATransform3D shrunk = CATransform3DIdentity;
	shrunk = CATransform3DTranslate(shrunk, newView.frame.size.width * 0.1, newView.frame.size.height * 0.1, 0);
	shrunk = CATransform3DScale(shrunk, 0.8, 0.8, 0.8);
	
	CABasicAnimation* scaleAnim		= [CABasicAnimation animation];
	scaleAnim.keyPath				= @"transform";
	scaleAnim.fromValue				= [NSValue valueWithCATransform3D: shrunk];
	scaleAnim.toValue				= [NSValue valueWithCATransform3D: CATransform3DIdentity];
	scaleAnim.beginTime				= CACurrentMediaTime();
	scaleAnim.repeatCount			= 1;
	scaleAnim.duration				= 0.3;
	scaleAnim.timingFunction		= [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];	
	
	// Run the animations
	[newView.layer addAnimation: fadeAnimation
						 forKey: @"Fade"];
	[newView.layer addAnimation: scaleAnim
						 forKey: @"Scale"];
}

- (void) removeView: (NSView*) view {
	if (![view wantsLayer]) { 
		[self prepareToAnimateView: view.superview];
	}
	
	view.layer.opacity = 0;

	// Fade away the view
	CABasicAnimation* fadeAnimation = [CABasicAnimation animation];
	fadeAnimation.keyPath			= @"opacity";
	fadeAnimation.toValue			= [NSNumber numberWithFloat: 0.0];
	fadeAnimation.fromValue			= [NSNumber numberWithFloat: 1.0];
	fadeAnimation.beginTime			= CACurrentMediaTime();
	fadeAnimation.repeatCount		= 1;
	fadeAnimation.duration			= 0.3;
	fadeAnimation.timingFunction	= [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
	
	// Also scale it up
	CATransform3D shrunk = CATransform3DIdentity;
	shrunk = CATransform3DTranslate(shrunk, view.frame.size.width * 0.1, view.frame.size.height * 0.1, 0);
	shrunk = CATransform3DScale(shrunk, 0.8, 0.8, 0.8);

	CABasicAnimation* scaleAnim		= [CABasicAnimation animation];
	scaleAnim.keyPath				= @"transform";
	scaleAnim.toValue				= [NSValue valueWithCATransform3D: shrunk];
	scaleAnim.fromValue				= [NSValue valueWithCATransform3D: CATransform3DIdentity];
	scaleAnim.beginTime				= CACurrentMediaTime();
	scaleAnim.repeatCount			= 1;
	scaleAnim.duration				= 0.3;
	scaleAnim.timingFunction		= [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];	
	
	// Run the animations
	[view.layer addAnimation: fadeAnimation
					  forKey: @"Fade"];
	[view.layer addAnimation: scaleAnim
					  forKey: @"Scale"];
}

@end
