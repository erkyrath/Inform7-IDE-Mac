//
//  IFMiscSettings.m
//  Inform
//
//  Created by Andrew Hunter on 10/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFMiscSettings.h"


@implementation IFMiscSettings

- (id) init {
	return [self initWithNibName: @"MiscSettings"];
}

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Misc Settings"
												  value: @"Misc Settings"
												  table: nil];
}

// = Setting up =

- (void) updateFromCompilerSettings: (IFCompilerSettings*) settings {
    [strictMode setState: [settings strict]?NSOnState:NSOffState];
    [infixMode setState: [settings infix]?NSOnState:NSOffState];
    [debugMode setState: [settings debug]?NSOnState:NSOffState];
}

- (void) setSettingsFor: (IFCompilerSettings*) settings {
	[settings setStrict: [strictMode state]==NSOnState];
	[settings setInfix: [infixMode state]==NSOnState];
	[settings setDebug: [debugMode state]==NSOnState];
}

@end
