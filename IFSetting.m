//
//  IFSetting.m
//  Inform
//
//  Created by Andrew Hunter on 06/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFSetting.h"


NSString* IFSettingHasChangedNotification = @"IFSettingHasChangedNotification";

@implementation IFSetting

// = Initialisation =

- (id) init {
	return [self initWithNibName: nil];
}

- (id) initWithNibName: (NSString*) nibName {
	self = [super init];
	
	if (self) {
		settingView = nil;
		
		if (nibName != nil)
			[NSBundle loadNibNamed: nibName
							 owner: self];
	}
	
	return self;
}

- (void) dealloc {
	if (settingView) [settingView release];
	[super dealloc];
}

// = Setting up the view =

- (NSView*) settingView {
	return settingView;
}

- (IBOutlet void) setSettingView: (NSView*) newSettingView {
	if (settingView) [settingView release];
	settingView = [newSettingView retain];
}

- (NSString*) title {
	return @"Setting";
}

// = Communicating with the IFCompilerSettings object =

- (void) setSettingsFor: (IFCompilerSettings*) settings {
	// Do nothing
}

- (BOOL) enableForCompiler: (NSString*) compiler {
	return YES;
}

- (NSArray*) commandLineOptionsForCompiler: (NSString*) compiler {
	return nil;
}

- (void) updateFromCompilerSettings: (IFCompilerSettings*) settings {
	// Do nothing
}

// = Notifying the controller about things =

- (IBAction) settingsHaveChanged: (id) sender {
	[[NSNotificationCenter defaultCenter] postNotificationName: IFSettingHasChangedNotification
														object: self];
}

// = Saving settings =

- (NSDictionary*) plistEntries {
	return [NSDictionary dictionary]; // No settings
}

- (void) updateSettings: (IFCompilerSettings*) settings
	   withPlistEntries: (NSDictionary*) entries {
	// Do nothing
}

@end
