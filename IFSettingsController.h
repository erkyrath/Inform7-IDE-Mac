//
//  IFSettingsController.h
//  Inform
//
//  Created by Andrew Hunter on 06/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFSettingsView.h"
#import "IFCompilerSettings.h"
#import "IFSetting.h"

@interface IFSettingsController : NSObject {
	// UI + model
	IBOutlet IFSettingsView* settingsView;
	IBOutlet IFCompilerSettings* compilerSettings;

	// Settings to display
	NSMutableArray* settings;		// Array of IFSetting
	
	BOOL settingsChanging;
}

// Plug-in support
+ (void) addStandardSettingsClass: (Class) settingClass;

+ (NSMutableArray*) makeStandardSettings;

// User interface
- (IFSettingsView*) settingsView;
- (void) setSettingsView: (IFSettingsView*) view;

- (IBAction) settingsHaveChanged: (id) sender;

// Model
- (IFCompilerSettings*) compilerSettings;
- (void) setCompilerSettings: (IFCompilerSettings*) settings;

- (void) updateAllSettings;

// The settings to display
- (void) addSettingsObject: (IFSetting*) setting;

@end
