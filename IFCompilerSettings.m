//
//  IFCompilerSettings.m
//  Inform
//
//  Created by Andrew Hunter on Mon Aug 18 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

//
// We've got a bit of an evolutionary thing going on here. Originally, this was going to be the 
// repository of all settings. Back in those days, Inform.app was just a front-end for the Inform 6
// compiler and didn't really do anything fancy. Now, I've redesigned things so that we can have
// 'IFSetting' objects: these are controller objects for individual sets of settings, and can have
// their own store. But we've still got this object, which acts as the interface to the compiler itself,
// so the 'older' settings are stored here and not as part of the new settings system.
//
// At some point, the settings that are here should probably be moved into their respective IFSetting 
// objects, but for the moment, they will remain.
//

#import "IFCompilerSettings.h"
#import "IFCompiler.h"
#import "IFSetting.h"

NSString* IFSettingLibraryToUse    = @"IFSettingLibraryToUse";
NSString* IFSettingCompilerVersion = @"IFSettingCompilerVersion";
NSString* IFSettingZCodeVersion    = @"IFSettingZCodeVersion";

NSString* IFSettingNaturalInform = @"IFSettingNaturalInform";
NSString* IFSettingStrict        = @"IFSettingStrict";
NSString* IFSettingInfix         = @"IFSettingInfix";
NSString* IFSettingDEBUG         = @"IFSettingDEBUG";

// Debug
NSString* IFSettingCompileNatOutput = @"IFSettingCompileNatOutput";
NSString* IFSettingRunBuildScript   = @"IFSettingRunBuildScript";

// Natural Inform
NSString* IFSettingLoudly = @"IFSettingLoudly";

// Compiler types
NSString* IFCompilerInform6		  = @"IFCompilerInform6";
NSString* IFCompilerNaturalInform = @"IFCompilerNaturalInform";

// Notifications
NSString* IFSettingNotification = @"IFSettingNotification";

@implementation IFCompilerSettings

// == Possible locations for the library ==
+ (NSArray*) inform7LibraryPaths {
	static NSArray* libPaths = nil;
	
	if (libPaths == nil) {
		NSMutableArray* res = [NSMutableArray array];
		NSArray* libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
		
		// User-supplied library directories
		NSEnumerator* libEnum;
		NSString* lib;
		
		libEnum = [libraries objectEnumerator];
		while (lib = [libEnum nextObject]) {
			[res addObject: [[lib stringByAppendingPathComponent: @"Inform"] stringByAppendingPathComponent: @"Inform7"]];
		}
		
		// Internal library directories
		NSString* bundlePath = [[NSBundle mainBundle] resourcePath];
		[res addObject: [bundlePath stringByAppendingPathComponent: @"Inform7"]];
		
		libPaths = [res copy];
	}
	
	return libPaths;
}

+ (NSArray*) libraryPaths {
	static NSArray* libPaths = nil;
	
	if (libPaths == nil) {
		NSMutableArray* res = [NSMutableArray array];
		NSArray* libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
		
		// User-supplied library directories
		NSEnumerator* libEnum;
		NSString* lib;
		
		libEnum = [libraries objectEnumerator];
		while (lib = [libEnum nextObject]) {
			[res addObject: [[lib stringByAppendingPathComponent: @"Inform"] stringByAppendingPathComponent: @"Libraries"]];
		}
		
		// Internal library directories
		NSString* bundlePath = [[NSBundle mainBundle] resourcePath];
		[res addObject: [bundlePath stringByAppendingPathComponent: @"Library"]];
		
		libPaths = [res copy];
	}
	
	return libPaths;
}

+ (NSString*) pathForLibrary: (NSString*) library {
	NSArray* searchPaths = [[self class] libraryPaths];
	
	NSEnumerator* searchEnum = [searchPaths objectEnumerator];
	NSString* path;
	
	while (path = [searchEnum nextObject]) {
		NSString* libDir = [path stringByAppendingPathComponent: library];
		BOOL isDir;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: libDir
												 isDirectory: &isDir]) {
			if (isDir == NO) {
				// Should be a file containing the actual library directory
				// (We do this because we can't rely on the finder to reliably copy
				// symbolic links)
				// Must be a directory
				NSString* newDir = [NSString stringWithContentsOfFile: libDir];
				
				libDir = [path stringByAppendingPathComponent: newDir];
				
				if (![[NSFileManager defaultManager] fileExistsAtPath: libDir
														  isDirectory: &isDir]) {
					NSLog(@"Couldn't find library link (%@) from %@ in %@", newDir, library, path);
					continue;
				}
				if (!isDir) {
					NSLog(@"Library link to %@ not a directory in %@", newDir, path);
					continue;
				}
			}
			
			return libDir;
		}
	}
	
	return nil;
}

+ (NSArray*) availableLibraries {
	NSMutableArray* result = [NSMutableArray array];
	NSArray* paths = [[self class] libraryPaths];
	
	NSEnumerator* pathEnum = [paths objectEnumerator];
	NSString* path;
	
	while (path = [pathEnum nextObject]) {
		NSArray* libraryDirectory = [[NSFileManager defaultManager] directoryContentsAtPath: path];
		
		NSEnumerator* libEnum = [libraryDirectory objectEnumerator];
		NSString* lib;
		
		while (lib = [libEnum nextObject]) {
			if (![result containsObject: lib]) [result addObject: lib];
		}
	}
	
	return result;
}

+ (NSString*) pathForInform7Library: (NSString*) library {
	NSArray* searchPaths = [[self class] inform7LibraryPaths];
	
	NSEnumerator* searchEnum = [searchPaths objectEnumerator];
	NSString* path;
	
	while (path = [searchEnum nextObject]) {
		NSString* libDir = [path stringByAppendingPathComponent: library];
		BOOL isDir;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: libDir
												 isDirectory: &isDir]) {
			if (isDir == NO) {
				// Should be a file containing the actual library directory
				// (We do this because we can't rely on the finder to reliably copy
				// symbolic links)
				// Must be a directory
				NSString* newDir = [NSString stringWithContentsOfFile: libDir];
				
				libDir = [path stringByAppendingPathComponent: newDir];
				
				if (![[NSFileManager defaultManager] fileExistsAtPath: libDir
														  isDirectory: &isDir]) {
					NSLog(@"Couldn't find library link (%@) from %@ in %@", newDir, library, path);
					continue;
				}
				if (!isDir) {
					NSLog(@"Library link to %@ not a directory in %@", newDir, path);
					continue;
				}
			}
			
			return libDir;
		}
	}
	
	return nil;
}

// == Initialisation ==
- (id) init {
    self = [super init];

    if (self) {
        store = [[NSMutableDictionary allocWithZone: [self zone]] init];

        // Default settings
        [store setObject: @"Standard"
                  forKey: IFSettingLibraryToUse];
        [self setUsingNaturalInform: NO];
    }

    return self;
}

- (void) dealloc {
    [store release];
	if (genericSettings) [genericSettings release];

    [super dealloc];
}

// == The command line ==
- (NSArray*) commandLineArguments {
	return [self commandLineArgumentsForRelease: NO];
}

- (NSArray*) commandLineArgumentsForRelease: (BOOL) release {
    NSMutableArray* result = [NSMutableArray array];

    // Switches
    NSMutableString* switches = [NSMutableString stringWithString: @"-"];
	[switches appendString: @"k"];
    [switches appendString: @"E2"];

    if ([self strict] && !release) {
        [switches appendString: @"S"];
    } else {
        [switches appendString: @"~S"];
    }

    if ([self infix] && !release) {
        [switches appendString: @"X"];
    } else {
        // Off by default
    }

    if ([self debug] && !release) {
        [switches appendString: @"D"];
    } else {
        [switches appendString: @"~D"];
    }

    if ([self usingNaturalInform]) {
        // Disable warnings when compiling with Natural Inform
        [switches appendString: @"w"];
    }

	// Select a zcode version
	NSArray* supportedZCodeVersions = [self supportedZMachines];
	int zcVersion = [self zcodeVersion];
	
	if (supportedZCodeVersions != nil && 
		![supportedZCodeVersions containsObject: [NSNumber numberWithInt: zcVersion]]) {
		// Use default version
		zcVersion = [[supportedZCodeVersions objectAtIndex: 0] intValue];
	}

	if (zcVersion < 255) {
		// ZCode
		[switches appendString: [NSString stringWithFormat: @"v%i",
			[self zcodeVersion]]];
	} else {
		// Glulx
		
		// FIXME: this assumes we only ever use a biplatform compiler
		// Not sure this is an urgent fix, though: all future versions of Inform should be BP
		[switches appendString: [NSString stringWithFormat: @"G",
			[self zcodeVersion]]];
	}

    [result addObject: switches];

    // Paths
    NSMutableArray* includePath = [NSMutableArray array];

    // User-defined includes
    
    // Library
    NSString* library = [store objectForKey: IFSettingLibraryToUse];
	NSString* libPath = [[self class] pathForLibrary: library];
	
	if (libPath == nil) libPath = [[self class] pathForLibrary: @"Standard"];
	if (libPath == nil) libPath = [[self class] pathForLibrary: [[[self class] availableLibraries] objectAtIndex: 0]];
	if (library == nil) libPath = nil;

    if (library != nil) {
        BOOL isDir;

        if (![[NSFileManager defaultManager] fileExistsAtPath: libPath
                                                  isDirectory: &isDir]) {
            // IMPLEMENT ME: try user preferences file
            libPath = nil;
        }
    } else {
    }

    if (libPath) {
        [includePath addObject: libPath];
    }
    
    [includePath addObject: @"./"];
    [includePath addObject: @"../Source/"];

    // Finish up paths

    NSMutableString* incString = [NSMutableString stringWithString: @"+include_path="];
    NSEnumerator* incEnum = [includePath objectEnumerator];
    NSString* path;
    BOOL comma = NO;

    while (path = [incEnum nextObject]) {
        if (comma) [incString appendString: @","];
        [incString appendString: path];
        comma = YES;
    }

    [result addObject: incString];
	
	// Command line options from the set of generic settings objects
	[result addObjectsFromArray: [self genericCommandLineForCompiler: IFCompilerInform6]];
    
    return result;
}

- (NSString*) compilerToUse {
    NSNumber* compilerVersion = [store objectForKey: IFSettingCompilerVersion];
    
    if (compilerVersion == nil)
        compilerVersion = [NSNumber numberWithDouble: [IFCompiler maxCompilerVersion]];
    
    return [IFCompiler compilerExecutableWithVersion: [compilerVersion doubleValue]];
}

- (NSArray*) supportedZMachines {
	return [IFCompiler compilerZMachineVersionsForCompiler: [self compilerToUse]];
}


- (NSString*) naturalInformCompilerToUse {
    if (![self usingNaturalInform]) {
        return nil;
    }

    NSString* compString = [NSString stringWithFormat: @"%@/Compilers/ni",
        [[NSBundle mainBundle] resourcePath]];
    NSString* homeNI = @"~/ni";
    homeNI = [homeNI stringByExpandingTildeInPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath: compString]) {
        return compString;
    } else if ([[NSFileManager defaultManager] fileExistsAtPath: homeNI]){
        return homeNI;
    } else {
        return nil; // No compiler available
    }
}

- (NSArray*) naturalInformCommandLineArguments {
    NSMutableArray* res = [NSMutableArray array];
    
    BOOL isLoudly = [self loudly];
    
    if (isLoudly) {
        [res addObject: @"-loudly"];
    }
	
	NSString* extensions = [[self class] pathForInform7Library: @"Extensions"];
	if (extensions != nil) {
		[res addObject: @"-rules"];
		[res addObject: extensions];
	}
	
	[res addObjectsFromArray: [self genericCommandLineForCompiler: IFCompilerNaturalInform]];
    
    return res;
}

// = Setting up the settings =
- (void) settingsHaveChanged {
    [[NSNotificationCenter defaultCenter] postNotificationName: IFSettingNotification
                                                        object: self];
}

- (void) setUsingNaturalInform: (BOOL) setting {
    [store setObject: [NSNumber numberWithBool: setting]
              forKey: IFSettingNaturalInform];
    [self settingsHaveChanged];
}

- (BOOL) usingNaturalInform {
    NSNumber* usingNaturalInform = [store objectForKey: IFSettingNaturalInform];

    if (usingNaturalInform) {
        return [usingNaturalInform boolValue];
    } else {
        return NO;
    }
}

- (void) setStrict: (BOOL) setting {
    [store setObject: [NSNumber numberWithBool: setting]
              forKey: IFSettingStrict];
    [self settingsHaveChanged];
}

- (BOOL) strict {
    NSNumber* setting = [store objectForKey: IFSettingStrict];

    if (setting) {
        return [setting boolValue];
    } else {
        return YES;
    }
}

- (void) setInfix: (BOOL) setting {
    [store setObject: [NSNumber numberWithBool: setting]
              forKey: IFSettingInfix];
    [self settingsHaveChanged];
}

- (BOOL) infix {
    NSNumber* setting = [store objectForKey: IFSettingInfix];

    if (setting) {
        return [setting boolValue];
    } else {
        return NO;
    }
}

- (void) setDebug: (BOOL) setting {
    [store setObject: [NSNumber numberWithBool: setting]
              forKey: IFSettingDEBUG];
    [self settingsHaveChanged];
}

- (BOOL) debug {
    NSNumber* setting = [store objectForKey: IFSettingDEBUG];

    if (setting) {
        return [setting boolValue];
    } else {
        return YES;
    }
}

- (void) setCompileNaturalInformOutput: (BOOL) setting {
    [store setObject: [NSNumber numberWithBool: setting]
              forKey: IFSettingCompileNatOutput];
    [self settingsHaveChanged];
}

- (BOOL) compileNaturalInformOutput {
    NSNumber* setting = [store objectForKey: IFSettingCompileNatOutput];

    if (setting) {
        return [setting boolValue];
    } else {
        return YES;
    }
}

- (void) setRunBuildScript: (BOOL) setting {
    [store setObject: [NSNumber numberWithBool: setting]
              forKey: IFSettingRunBuildScript];
    [self settingsHaveChanged];
}

- (BOOL) runBuildScript {
    NSNumber* setting = [store objectForKey: IFSettingRunBuildScript];

    if (setting) {
        return [setting boolValue];
    } else {
        return NO;
    }
}

- (void) setLoudly: (BOOL) setting {
    [store setObject: [NSNumber numberWithBool: setting]
              forKey: IFSettingLoudly];
    [self settingsHaveChanged];
}

- (BOOL) loudly {
    return [[store objectForKey: IFSettingLoudly] boolValue];
}

- (void) setZCodeVersion: (int) version {
    [store setObject: [NSNumber numberWithInt: version]
              forKey: IFSettingZCodeVersion];
    [self settingsHaveChanged];
}

- (int) zcodeVersion {
    NSNumber* setting = [store objectForKey: IFSettingZCodeVersion];

    if (setting) {
        return [setting intValue];
    } else {
        return 5;
    }
}

- (NSString*) fileExtension {
    int version = [self zcodeVersion];
    return [NSString stringWithFormat: @"z%i", version];
}

- (void) setCompilerVersion: (double) version {
    [store setObject: [NSNumber numberWithDouble: version]
                                          forKey: IFSettingCompilerVersion];
    [self settingsHaveChanged];
}

- (double) compilerVersion {
    NSNumber* compilerVersion = [store objectForKey: IFSettingCompilerVersion];
    
    if (compilerVersion == nil)
        return [IFCompiler maxCompilerVersion];
    
    return [compilerVersion doubleValue];
}

- (void) setLibraryToUse: (NSString*) library {
    [store setObject: [[library copy] autorelease]
              forKey: IFSettingLibraryToUse];
    [self settingsHaveChanged];
}

- (NSString*) libraryToUse {
    return [store objectForKey: IFSettingLibraryToUse];
}

// = Generic settings =
- (void) setGenericSettings: (NSArray*) newGenericSettings {
	if (genericSettings) [genericSettings release];
	genericSettings = [newGenericSettings retain];
}

- (NSArray*) genericCommandLineForCompiler: (NSString*) compiler {
	NSEnumerator* settingEnum = [genericSettings objectEnumerator];
	IFSetting* setting;
	
	NSMutableArray* result = [NSMutableArray array];
	
	while (setting = [settingEnum nextObject]) {
		NSArray* settingOptions = [setting commandLineOptionsForCompiler: compiler];
		
		[result addObjectsFromArray: settingOptions];
	}
	
	return result;
}

// = NSCoding =
- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject: store];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [self init]; // Call the designated initialiser first

    [store release];
    store = [[decoder decodeObject] retain];

    return self;
}

@end
