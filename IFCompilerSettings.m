//
//  IFCompilerSettings.m
//  Inform
//
//  Created by Andrew Hunter on Mon Aug 18 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFCompilerSettings.h"
#import "IFCompiler.h"

NSString* IFSettingLibraryToUse  = @"IFSettingLibraryToUse";
NSString* IFSettingCompilerVersion = @"IFSettingCompilerVersion";
NSString* IFSettingZCodeVersion  = @"IFSettingZCodeVersion";

NSString* IFSettingNaturalInform = @"IFSettingNaturalInform";
NSString* IFSettingStrict        = @"IFSettingStrict";
NSString* IFSettingInfix         = @"IFSettingInfix";
NSString* IFSettingDEBUG         = @"IFSettingDEBUG";

// Debug
NSString* IFSettingCompileNatOutput = @"IFSettingCompileNatOutput";
NSString* IFSettingRunBuildScript = @"IFSettingRunBuildScript";

// Natural Inform
NSString* IFSettingLoudly = @"IFSettingLoudly";

// Notifications
NSString* IFSettingNotification = @"IFSettingNotification";

@implementation IFCompilerSettings

// == Possible locations for the library ==
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

    [super dealloc];
}

// == The command line ==
- (NSArray*) commandLineArguments {
    NSMutableArray* result = [NSMutableArray array];

    NSString* bundlePath = [[NSBundle mainBundle] resourcePath];

    // Switches
    NSMutableString* switches = [NSMutableString stringWithString: @"-"];
    [switches appendString: @"E2"];

    if ([self strict]) {
        [switches appendString: @"S"];
    } else {
        [switches appendString: @"~S"];
    }

    if ([self infix]) {
        [switches appendString: @"X"];
    } else {
        // Off by default
    }

    if ([self debug]) {
        [switches appendString: @"D"];
    } else {
        [switches appendString: @"~D"];
    }

    if ([self usingNaturalInform]) {
        // Disable warnings when compiling with Natural Inform
        [switches appendString: @"w"];
    }

    [switches appendString: [NSString stringWithFormat: @"v%i",
        [self zcodeVersion]]];

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
    
    return result;
}

- (NSString*) compilerToUse {
    NSNumber* compilerVersion = [store objectForKey: IFSettingCompilerVersion];
    
    if (compilerVersion == nil)
        compilerVersion = [NSNumber numberWithDouble: [IFCompiler maxCompilerVersion]];
    
    return [IFCompiler compilerExecutableWithVersion: [compilerVersion doubleValue]];
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
