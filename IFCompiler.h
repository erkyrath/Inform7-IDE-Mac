//
//  IFCompiler.h
//  Inform
//
//  Created by Andrew Hunter on Mon Aug 18 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IFCompilerSettings.h"

extern NSString* IFCompilerStartingNotification;
extern NSString* IFCompilerStdoutNotification;
extern NSString* IFCompilerStderrNotification;
extern NSString* IFCompilerFinishedNotification;

@interface IFCompiler : NSObject {
    // The task
    NSTask* theTask;

    // Settings, input, output
    IFCompilerSettings* settings;
    NSString* inputFile;
    NSString* outputFile;
    NSString* workingDirectory;
    BOOL deleteOutputFile;

    // Queue of processes to run
    NSMutableArray* runQueue;
    
    // Output/input streams
    NSPipe* stdErr;
    NSPipe* stdOut;

    NSFileHandle* stdErrH;
    NSFileHandle* stdOutH;

    int finishCount; // When =3, notify the delegate that the task is dead

    // Delegate
    NSObject* delegate;
}

+ (NSString*) compilerExecutable;

- (void) setSettings: (IFCompilerSettings*) settings;
- (void) setInputFile: (NSString*) path;
- (void) setDirectory: (NSString*) path;
- (NSString*) inputFile;
- (IFCompilerSettings*) settings;
- (NSString*) directory;

- (void) prepareForLaunch;

- (void) addCustomBuildStage: (NSString*) command
               withArguments: (NSArray*) arguments
              nextStageInput: (NSString*) file;
- (void) addNaturalInformStage;
- (void) addStandardInformStage;
- (NSString*) currentStageInput;

- (void)      deleteOutput;
- (NSString*) outputFile;
- (void)      setOutputFile: (NSString*) file;
- (void)      setDeletesOutput: (BOOL) deletes;

- (void) setDelegate: (id<NSObject>) delegate;
- (id)   delegate;

- (void) launch;

@end

// Delegate method prototypes
@interface NSObject(IFCompilerDelegate)

- (void) taskFinished:       (int) exitCode;
- (void) receivedFromStdOut: (NSString*) data;
- (void) receivedFromStdErr: (NSString*) data;

@end
