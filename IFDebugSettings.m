//
//  IFDebugSettings.m
//  Inform
//
//  Created by Andrew Hunter on 10/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFDebugSettings.h"


@implementation IFDebugSettings

- (id) init {
	return [self initWithNibName: @"DebugSettings"];
}

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Debug Settings"
												  value: @"Debug Settings"
												  table: nil];
}

// = Setting up =

- (void) updateFromCompilerSettings {
    IFCompilerSettings* settings = [self compilerSettings];
	
	[donotCompileNaturalInform setState:
        (![settings compileNaturalInformOutput])?NSOnState:NSOffState];
    [runBuildSh setState: [settings runBuildScript]?NSOnState:NSOffState];
    [runLoudly setState: [settings loudly]?NSOnState:NSOffState];
	[debugMemory setState: [settings debugMemory]?NSOnState:NSOffState];
}

- (void) setSettings {
    IFCompilerSettings* settings = [self compilerSettings];

	[settings setRunBuildScript: [runBuildSh state]==NSOnState];
	[settings setCompileNaturalInformOutput: [donotCompileNaturalInform state]!=NSOnState];
	[settings setLoudly: [runLoudly state]==NSOnState];
	[settings setDebugMemory: [debugMemory state]==NSOnState];
}

- (BOOL) enableForCompiler: (NSString*) compiler {
	// These settings are presently permanently disabled
	return NO;
}

@end
