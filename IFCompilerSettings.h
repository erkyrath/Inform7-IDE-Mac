//
//  IFCompilerSettings.h
//  Inform
//
//  Created by Andrew Hunter on Mon Aug 18 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

// Compiler settings definition class

#import <Foundation/Foundation.h>

// The settings keys
extern NSString* IFSettingCompilerVersion; // default is inform-6.21-zcode
extern NSString* IFSettingLibraryToUse; // default is `Standard'
extern NSString* IFSettingZCodeVersion; // default is 5, 256 = GLULX

// Switches
extern NSString* IFSettingNaturalInform; // default NO
extern NSString* IFSettingStrict;        // default YES
extern NSString* IFSettingInfix;         // default NO
extern NSString* IFSettingDEBUG;         // default YES

// Debug
extern NSString* IFSettingCompileNatOutput;
extern NSString* IFSettingRunBuildScript;

// Notifications
extern NSString* IFSettingNotification;

// Natural Inform
extern NSString* IFSettingLoudly;

// Compiler types
extern NSString* IFCompilerInform6;
extern NSString* IFCompilerNaturalInform;

// The settings dictionary object
@interface IFCompilerSettings : NSObject<NSCoding>  {
    NSMutableDictionary* store;
	NSArray* genericSettings;
}

+ (NSArray*) libraryPaths;
+ (NSString*) pathForLibrary: (NSString*) library;
+ (NSString*) pathForInform7Library: (NSString*) library;
+ (NSArray*) availableLibraries;

// Setting up the settings
- (void) setUsingNaturalInform: (BOOL) setting;
- (void) setStrict: (BOOL) setting;
- (void) setInfix: (BOOL) setting;
- (void) setDebug: (BOOL) setting;
- (void) setCompileNaturalInformOutput: (BOOL) setting;
- (void) setRunBuildScript: (BOOL) setting;
- (BOOL) usingNaturalInform;
- (BOOL) strict;
- (BOOL) infix;
- (BOOL) debug;
- (BOOL) compileNaturalInformOutput;
- (BOOL) runBuildScript;

- (void) setCompilerVersion: (double) version;
- (void) setLibraryToUse: (NSString*) library;
- (double) compilerVersion;
- (NSString*) libraryToUse;

- (void)      setZCodeVersion: (int) version;
- (int)       zcodeVersion;
- (NSString*) fileExtension;

- (void)      setLoudly: (BOOL) loudly;
- (BOOL)      loudly;

- (void) settingsHaveChanged;

// Generic settings (IFSetting)
- (void)      setGenericSettings: (NSArray*) genericSettings;
- (NSArray*)  includePathsForCompiler: (NSString*) compiler;
- (NSArray*)  genericCommandLineForCompiler: (NSString*) compiler;
- (NSMutableDictionary*) dictionaryForClass: (Class) cls;

// Getting command line arguments, etc
- (NSArray*) commandLineArguments;
- (NSArray*) commandLineArgumentsForRelease: (BOOL) release;
- (NSString*) compilerToUse;
- (NSArray*) supportedZMachines;

- (NSString*) naturalInformCompilerToUse; // nil if not using natural inform
- (NSArray*) naturalInformCommandLineArguments;

@end
