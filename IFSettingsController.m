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

- (void) repopulateSettings {
	IFSetting* setting;
	NSEnumerator* settingEnumerator = [settings objectEnumerator];
	
	[settingsView startRearranging];
	[settingsView removeAllSubviews];
	
	while (setting = [settingEnumerator nextObject]) {
		[settingsView addSubview: [setting settingView]
					   withTitle: [setting title]];
	}
	
	[settingsView finishRearranging];
}

- (IFSettingsView*) settingsView {
	return settingsView;
}

- (void) setSettingsView: (IFSettingsView*) view {
	if (settingsView) [settingsView release];
	settingsView = [view retain];
	
	[self repopulateSettings];
}

// = Model =

- (IFCompilerSettings*) compilerSettings {
	return compilerSettings;
}

- (void) setCompilerSettings: (IFCompilerSettings*) cSettings {
	if (compilerSettings) [compilerSettings release];
	compilerSettings = [cSettings retain];
}

// = The settings to display =

- (void) addSettingsObject: (IFSetting*) setting {
	[settings addObject: setting];
}

@end
