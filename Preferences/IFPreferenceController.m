//
//  IFPreferenceController.m
//  Inform
//
//  Created by Andrew Hunter on 12/01/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFPreferenceController.h"


@implementation IFPreferenceController

// = Construction =

+ (IFPreferenceController*) sharedPreferenceController {
	static IFPreferenceController* sharedPrefController = nil;

	if (sharedPrefController == nil) {
		sharedPrefController = [[IFPreferenceController alloc] init];
	}
	
	return sharedPrefController;
}

// = Initialisation =

- (id) init {
	NSRect mainScreenRect = [[NSScreen mainScreen] frame];
	
	self = [super initWithWindow: [[[NSWindow alloc] initWithContentRect: NSMakeRect(NSMinX(mainScreenRect)+200, NSMaxY(mainScreenRect)-400, 512, 300) 
															   styleMask: NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask
																 backing: NSBackingStoreBuffered 
																   defer: YES] autorelease]];
	
	if (self) {
		// Set up window
		[self setWindowFrameAutosaveName: @"PreferenceWindow"];
	}
	
	return self;
}

// = Preference switching =

@end
