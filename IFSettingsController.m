//
//  IFSettingsController.m
//  Inform
//
//  Created by Andrew Hunter on 06/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFSettingsController.h"


@implementation IFSettingsController

// = Settings methods =

static NSMutableArray* standardSettingsClasses = nil;

+ (void) initialize {
	if (standardSettingsClasses == nil) {
		standardSettingsClasses = [[NSMutableArray alloc] init];
	}
}

// 'Standard' settings classes are always added to the controller on startup
+ (void) addStandardSettingsClass: (Class) settingClass {
	if (![settingClass isSubclassOfClass: [IFSetting class]]) {
		[NSException raise: @"IFNotASettingClass" 
					format: @"Class %@ is not a derivative of the IFSetting class"];
		return;
	}
	
	[standardSettingsClasses addObject: settingClass];
}

// = Initialisation, etc =

- (id) init {
	self = [super init];
	
	if (self) {
		settings = [[NSMutableArray alloc] init];
		
		// Create all the 'standard' classes
		// These must know how to initialise themselves with just an init call
		NSEnumerator* stdSettingEnum = [standardSettingsClasses objectEnumerator];
		Class settingClass;
		
		while (settingClass = [stdSettingEnum nextObject]) {
			[settings addObject: [[[settingClass alloc] init] autorelease]];
		}
		
		settingsChanging = NO;
	}
	
	return self;
}

- (void) dealloc {
	[settingsView release];
	[compilerSettings release];
	[settings release];

	[super dealloc];
}

// = User interface =

- (void) settingChangedNotification: (NSNotification*) not {
	[self settingsHaveChanged: [not object]];
}

- (void) repopulateSettings {
	// Re-add all the settings views
	IFSetting* setting;
	NSEnumerator* settingEnumerator = [settings objectEnumerator];
		
	[settingsView startRearranging];
	[settingsView removeAllSubviews];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	while (setting = [settingEnumerator nextObject]) {
		[settingsView addSubview: [setting settingView]
					   withTitle: [setting title]];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(settingChangedNotification:) 
													 name: IFSettingHasChangedNotification
												   object: setting];
	}
	
	// This notification will also have been removed above
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(updateAllSettings)
												 name: IFSettingNotification
											   object: [self compilerSettings]];
	
	[settingsView finishRearranging];
	
	[compilerSettings setGenericSettings: settings];
}

- (IFSettingsView*) settingsView {
	return settingsView;
}

- (void) setSettingsView: (IFSettingsView*) view {
	if (settingsView) [settingsView release];
	settingsView = [view retain];
	
	[self repopulateSettings];
}

- (IBAction) settingsHaveChanged: (id) sender {
	if (sender == nil) {
		// All settings have changed
		NSEnumerator* settingEnum = [settings objectEnumerator];
		IFSetting* setting;
		
		while (setting = [settingEnum nextObject]) {
			[self settingsHaveChanged: setting];
		}
		
		return;
	}
	
	if ([sender isKindOfClass: [IFSetting class]]) {
		// A specific settings object has changed
		settingsChanging = YES;
		[(IFSetting*)sender setSettingsFor: [self compilerSettings]];
		settingsChanging = NO;
		
		[self updateAllSettings];
	} else {
		// Same as all settings changed, really
		[self settingsHaveChanged: nil];
	}
}

// = Model =

- (IFCompilerSettings*) compilerSettings {
	return compilerSettings;
}

- (void) setCompilerSettings: (IFCompilerSettings*) cSettings {
	// NOTE: this implementation assumes a one-to-one relationship between the IFCompilerSettings object
	// and ourselves: things may go a bit wonky if multiple settings controllers refer to the same
	// IFCompilerSettings object.
	
	// (FIXME: this actually happens, as each pane has its own SettingsController. Though I don't think
	// this will cause any pain for now)

	// Deregister/release the compiler settings if we're not using them any more
	if (compilerSettings) {
		[[NSNotificationCenter defaultCenter] removeObserver: self
														name: IFSettingNotification
													  object: [self compilerSettings]];
		[compilerSettings release];
	}
	
	// Store the new compiler settings object
	compilerSettings = [cSettings retain];
	[compilerSettings setGenericSettings: settings];

	// Update ourselves when the compiler settings change
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(updateAllSettings)
												 name: IFSettingNotification
											   object: [self compilerSettings]];
}

- (void) updateAllSettings {
	// Don't do anything if we're already in the middle of updating the settings
	if (settingsChanging) return;
	
	// Get each setting object to reflect the status of the current compilerSettings
	NSEnumerator* settingEnum = [settings objectEnumerator];
	IFSetting* setting;
	IFCompilerSettings* cSettings = [self compilerSettings];
	
	while (setting = [settingEnum nextObject]) {
		[setting updateFromCompilerSettings: cSettings];
	}
}

// = The settings to display =

- (void) addSettingsObject: (IFSetting*) setting {
	[settings addObject: setting];
}

@end