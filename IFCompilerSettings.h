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
extern NSString* IFSettingCompilerName; // default is inform-6.21-zcode
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

// The settings dictionary object
@interface IFCompilerSettings : NSObject<NSCoding>  {
    NSMutableDictionary* store;
}

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
- (BOOL) compileNaturalInformOutput;
- (BOOL) runBuildScript;
- (BOOL) debug;

- (void)      setZCodeVersion: (int) version;
- (int)       zcodeVersion;
- (NSString*) fileExtension;

// Getting command line arguments, etc
- (NSArray*) commandLineArguments;
- (NSString*) compilerToUse;

- (NSString*) naturalInformCompilerToUse; // nil if not using natural inform
- (NSArray*) naturalInformCommandLineArguments;

@end
