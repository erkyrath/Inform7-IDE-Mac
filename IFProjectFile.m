//
//  IFProjectFile.m
//  Inform
//
//  Created by Andrew Hunter on Fri Sep 12 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFProjectFile.h"


@implementation IFProjectFile

// = Empty project creation =
- (id) initWithEmptyProject {
    // First we have to create the source directory, etc
    NSFileWrapper* srcDir;
    NSFileWrapper* bldDir;
    NSFileWrapper* indexDir;

    srcDir = [[NSFileWrapper alloc] initDirectoryWithFileWrappers: [NSDictionary dictionary]];
    bldDir = [[NSFileWrapper alloc] initDirectoryWithFileWrappers: [NSDictionary dictionary]];
    indexDir = [[NSFileWrapper alloc] initDirectoryWithFileWrappers: [NSDictionary dictionary]];
    [srcDir setPreferredFilename: @"Source"];
    [bldDir setPreferredFilename: @"Build"];
    [indexDir setPreferredFilename: @"Index"];

    [srcDir autorelease]; [bldDir autorelease]; [indexDir autorelease];

    if (srcDir == nil || bldDir == nil) {
        return nil;
    }
  
    self = [super initDirectoryWithFileWrappers:
        [NSDictionary dictionaryWithObjectsAndKeys: srcDir, @"Source", bldDir, @"Build", indexDir, @"Index", nil]];

    if (self) {
        sourceDirectory = [srcDir retain];
        buildDirectory  = [bldDir retain];
    }
    
    return self;
}

- (void) dealloc {
    [sourceDirectory release];
    [buildDirectory release];
    
    [super dealloc];
}

- (void) addSourceFile: (NSString*) filename {
    [sourceDirectory addRegularFileWithContents: [NSData data]
                              preferredFilename: filename];
}

- (void) addSourceFile: (NSString*) filename
          withContents: (NSData*) contents {
    [sourceDirectory addRegularFileWithContents: contents
                              preferredFilename: filename];
}

- (void) setSettings: (IFCompilerSettings*) settings {
    // Add the settings plist to the wrapper
    NSFileWrapper* settingsWrapper;
    [self removeFileWrapper: [[self fileWrappers] objectForKey:
        @"Settings.plist"]];
	
	NSData* settingsData = [settings currentPlist];

	settingsWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:
        settingsData];
    [settingsWrapper setPreferredFilename: @"Settings.plist"];
    [settingsWrapper setFilename: @"Settings.plist"];

    [self addFileWrapper: [settingsWrapper autorelease]];

	// Delete the old-style file, if it exists
	NSFileWrapper* settingsFile = [[self fileWrappers] objectForKey: @"Settings"];
	if (settingsFile) [self removeFileWrapper: settingsFile];
}

- (IFCompilerSettings*) settings {
    NSFileWrapper* settingsFile = [[self fileWrappers] objectForKey: @"Settings.plist"];

	if (settingsFile == nil) {
		// Old-style loading
		settingsFile = [[self fileWrappers] objectForKey: @"Settings"];

		if (settingsFile == nil) {
			return nil;
			//return [[[IFCompilerSettings alloc] init] autorelease];
		}

		NSData* settingsData = [settingsFile regularFileContents];
		NSUnarchiver* theCoder = [[NSUnarchiver alloc] initForReadingWithData:
			settingsData];

		// Decode the file
		NSString* creator = [theCoder decodeObject];
		int version = -1;
		[theCoder decodeValueOfObjCType: @encode(int) at: &version];
		IFCompilerSettings* settings = [[theCoder decodeObject] retain];

		// Release the decoder
		[theCoder release];

		if (creator == nil || version != 1 || settings == nil) {
			// We don't understand this file
			return [[[IFCompilerSettings alloc] init] autorelease];       
		}

		return [settings autorelease];
	} else {
		// New-style loading
		IFCompilerSettings* newSettings = [[[IFCompilerSettings alloc] init] autorelease];
		
		[newSettings restoreSettingsFromPlist: [settingsFile regularFileContents]];
		
		return newSettings;
	}
}

@end
