//
//  IFAdvancedPreferences.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 12/10/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFPreferencePane.h"


//
// Preference pane that contains options mainly intended for use by Inform 7 maintainers
//
@interface IFAdvancedPreferences : IFPreferencePane {
	IBOutlet NSButton* showDebugLogs;					// If checked, show the Inform 6 source and Inform 7 debugging logs
	IBOutlet NSButton* runBuildSh;						// Causes the Inform 7 build process to be run
}

// Actions
- (IBAction) setPreference: (id) sender;				// Causes this view to update its preferences based on the values of the buttons
- (void) reflectCurrentPreferences;						// Causes this view to update its preferences according to the current values set in the preferences

@end
