//
//  IFOutputSettings.m
//  Inform
//
//  Created by Andrew Hunter on 10/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFOutputSettings.h"

NSString* IFSettingCreateBlorb = @"IFSettingCreateBlorb";

@implementation IFOutputSettings

- (id) init {
	return [self initWithNibName: @"OutputSettings"];
}

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Output Settings"
												  value: @"Output Settings"
												  table: nil];
}

// = Setting up =

- (BOOL) createBlorbForRelease {
    IFCompilerSettings* settings = [self compilerSettings];
	NSNumber* value = [[settings dictionaryForClass: [self class]] objectForKey: IFSettingCreateBlorb];
	
	if (value)
		return [value boolValue];
	else
		return YES;
}

- (void) setCreateBlorbForRelease: (BOOL) setting {
    IFCompilerSettings* settings = [self compilerSettings];
	
	[[settings dictionaryForClass: [self class]] setObject: [NSNumber numberWithBool: setting]
													forKey: IFSettingCreateBlorb];
	[settings settingsHaveChanged];
}

- (void) updateFromCompilerSettings {
    IFCompilerSettings* settings = [self compilerSettings];

	// Supported Z-Machine versions
	NSArray* supportedZMachines = [settings supportedZMachines];
	
	NSEnumerator* cellEnum = [[zmachineVersion cells] objectEnumerator];
	NSCell* cell;
	
	while (cell = [cellEnum nextObject]) {
		if (supportedZMachines == nil) {
			[cell setEnabled: YES];
		} else {
			if ([supportedZMachines containsObject: [NSNumber numberWithInt: [cell tag]]]) {
				[cell setEnabled: YES];
			} else {
				[cell setEnabled: NO];
			}
		}
	}
	
	// Selected Z-Machine version
    if ([zmachineVersion cellWithTag: [settings zcodeVersion]] != nil) {
        [zmachineVersion selectCellWithTag: [settings zcodeVersion]];
    } else {
        [zmachineVersion deselectAllCells];
    }
	
	// Whether or not we should generate a blorb file on release
	[releaseBlorb setState: [self createBlorbForRelease]?NSOnState:NSOffState];
}

- (void) setSettings {
	BOOL willCreateBlorb = [releaseBlorb state]==NSOnState;
    IFCompilerSettings* settings = [self compilerSettings];

	[settings setZCodeVersion: [[zmachineVersion selectedCell] tag]];
	[self setCreateBlorbForRelease: willCreateBlorb];
}

@end
