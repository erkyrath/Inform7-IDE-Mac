//
//  IFLibrarySettings.m
//  Inform
//
//  Created by Andrew Hunter on 10/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFLibrarySettings.h"


@implementation IFLibrarySettings

- (id) init {
	return [self initWithNibName: @"LibrarySettings"];
}

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Library Settings"
												  value: @"Library Settings"
												  table: nil];
}

// = Setting up =

- (void) updateFromCompilerSettings: (IFCompilerSettings*) settings {
    // Library versions
	NSArray* libraryDirectory = [IFCompilerSettings availableLibraries];
    
    NSEnumerator* libEnum = [libraryDirectory objectEnumerator];
    NSString* libVer;
    NSString* currentLibVer = [settings libraryToUse];
    
    [libraryVersion removeAllItems];
    
    while (libVer = [libEnum nextObject]) {
        [libraryVersion addItemWithTitle: libVer];
        
        if ([libVer isEqualToString: currentLibVer]) {
            [libraryVersion selectItemAtIndex: [libraryVersion numberOfItems]-1];
        }
    }
}

- (void) setSettingsFor: (IFCompilerSettings*) settings {
	[settings setLibraryToUse: [libraryVersion itemTitleAtIndex: [libraryVersion indexOfSelectedItem]]];
}

@end
