//
//  IFAdvancedPreferences.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 12/10/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFAdvancedPreferences.h"
#import "IFPreferences.h"

@implementation IFAdvancedPreferences

// = Initialisation =

- (id) init {
	self = [super initWithNibName: @"AdvancedPreferences"];
	
	if (self) {
		[self reflectCurrentPreferences];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(reflectCurrentPreferences)
													 name: IFPreferencesDidChangeNotification
												   object: [IFPreferences sharedPreferences]];
	}
	
	return self;
}

// = Preference overrides =

- (NSString*) preferenceName {
	return @"Advanced";
}

- (NSImage*) toolbarImage {
	return [NSImage imageNamed: @"Advanced"];
}

// = Actions =

- (IBAction) setPreference: (id) sender {
	// Read the current state of the buttons
	BOOL willBuildSh = [runBuildSh state]==NSOnState;
	BOOL willDebug = [showDebugLogs state]==NSOnState;
	
	// Set the shared preferences to suitable values
	[[IFPreferences sharedPreferences] setRunBuildSh: willBuildSh];
	[[IFPreferences sharedPreferences] setShowDebuggingLogs: willDebug];
}

- (void) reflectCurrentPreferences {
	// Set the buttons according to the current state of the preferences
	[runBuildSh setState: [[IFPreferences sharedPreferences] runBuildSh]?NSOnState:NSOffState];
	[showDebugLogs setState: [[IFPreferences sharedPreferences] showDebuggingLogs]?NSOnState:NSOffState];
}

@end
