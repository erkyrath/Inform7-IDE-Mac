//
//  IFCompilerOptions.m
//  Inform
//
//  Created by Andrew Hunter on 10/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFCompilerOptions.h"

#import "IFCompiler.h"

@implementation IFCompilerOptions

- (id) init {
	return [self initWithNibName: @"CompilerSettings"];
}

- (void) dealloc {
	[super dealloc];
}

// = Misc info =

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Compiler Settings"
												  value: @"Compiler Settings"
												  table: nil];
}

// = Setting up =

- (void) updateFromCompilerSettings {
    IFCompilerSettings* settings = [self compilerSettings];

    // Compiler versions
    NSString* version = [settings compilerVersion];
    NSEnumerator* compilerEnum = [[IFCompiler availableCompilers] objectEnumerator];
    
    [compilerVersion removeAllItems];
    NSDictionary* compilerInfo;
    
    while (compilerInfo = [compilerEnum nextObject]) {
        NSString* compilerStr = [NSString stringWithFormat: @"%@ %@ (%@)",
            [compilerInfo objectForKey: @"name"],
            [compilerInfo objectForKey: @"version"],
            [compilerInfo objectForKey: @"platform"]];
        
        [compilerVersion addItemWithTitle: compilerStr];
        
        if ([IFCompiler compareCompilerVersion: version
									 toVersion: [compilerInfo objectForKey: @"version"]] == NSOrderedSame) {
            [compilerVersion selectItemAtIndex: [compilerVersion numberOfItems]-1];
        }
    }
	
	// Natural Inform
	[naturalInform setState: [settings usingNaturalInform]?NSOnState:NSOffState];
}

- (void) setSettings {
    IFCompilerSettings* settings = [self compilerSettings];

	// Compiler version
	int item = [compilerVersion indexOfSelectedItem];
	NSString* newVersion;
	
	newVersion = [[[IFCompiler availableCompilers] objectAtIndex: item] objectForKey: @"version"];
	
	[settings setCompilerVersion: newVersion];	
	
	// Whether or not to use Natural Inform
	[settings setUsingNaturalInform: [naturalInform state]==NSOnState];
}

@end
