//
//  IFSetting.h
//  Inform
//
//  Created by Andrew Hunter on 06/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Notification strings
extern NSString* IFSettingHasChangedNotification;

@class IFCompilerSettings;

// Representation of a class of settings
// Technically a controller object
//
// It's usually pretty pointless to make extra model objects beyond IFCompilerSettings, so there
// may be some overlap with the model here.
@interface IFSetting : NSObject {
	IBOutlet NSView* settingView;
}

- (id) initWithNibName: (NSString*) nibName;

// Setting up the view
- (NSView*) settingView;
- (IBOutlet void) setSettingView: (NSView*) settingView;

// Information about this settings view
- (NSString*) title;

// Communicating with the IFCompilerSettings object
- (void) setSettingsFor: (IFCompilerSettings*) settings;
- (BOOL) enableForCompiler: (NSString*) compiler;
- (NSArray*) commandLineOptionsForCompiler: (NSString*) compiler;
- (void) updateFromCompilerSettings: (IFCompilerSettings*) settings;

// Notifying the controller about things
- (IBAction) settingsHaveChanged: (id) sender;

// Saving settings
- (NSDictionary*) plistEntries;
- (void) updateSettings: (IFCompilerSettings*) settings
	   withPlistEntries: (NSDictionary*) entries;

@end

#import "IFCompilerSettings.h"