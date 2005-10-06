//
//  IFCompiler.h
//  Inform
//
//  Created by Andrew Hunter on Mon Aug 18 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IFCompilerSettings.h"
#import "IFProgress.h"

extern NSString* IFCompilerStartingNotification;
extern NSString* IFCompilerStdoutNotification;
extern NSString* IFCompilerStderrNotification;
extern NSString* IFCompilerFinishedNotification;

//
// Protocol implemented by classes that can find alternative 'problems' files
//
@protocol IFCompilerProblemHandler

- (NSURL*) urlForProblemWithErrorCode: (int) errorCode;		// Returns the problem URL to use when the compiler finishes with a specific error code

@end

//
// Class that handles actually running a compiler (more like a 'make' class these days)
//
@interface IFCompiler : NSObject {
    // The task
    NSTask* theTask;						// Task where the compiler is running

    // Settings, input, output
    IFCompilerSettings* settings;			// Settings for the compiler
	BOOL release;							// YES if compiling for release
    NSString* inputFile;					// The input file for this compiler
    NSString* outputFile;					// The output filename for this compiler
    NSString* workingDirectory;				// The working directory for this stage
    BOOL deleteOutputFile;					// YES if the output file should be deleted when the compiler is dealloced
	
	NSURL* problemsURL;						// The URL of the problems page we should show

    // Queue of processes to run
    NSMutableArray* runQueue;				// Queue of tasks to run to produce the end result
    
    // Output/input streams
    NSPipe* stdErr;							// stdErr pipe
    NSPipe* stdOut;							// stdOut pipe

    NSFileHandle* stdErrH;					// File handle for std err
    NSFileHandle* stdOutH;					// ... and for std out

    int finishCount;						// When =3, notify the delegate that the task is dead (long live the task)
	
	// Progress
	IFProgress* progress;					// Progress indicator for compilation
	
    // Delegate
    id delegate;							// The delegate object. (NOT RETAINED)
}

//+ (NSString*) compilerExecutable;
+ (NSDictionary*) parseCompilerFilename: (NSString*) pathname;						// Parses an inform6 compiler filename, retrieves information about whether or not it compiles glulx, the version, etc
+ (NSString*)	  maxCompilerVersion;												// Most recent available Inform 6 compiler version
+ (NSString*)	  compilerExecutableWithVersion: (NSString*) ver;					// 6.21, 6.30 etc - path for an Inform 6 compiler with the given version number
+ (NSArray*)	  compilerZMachineVersionsForCompiler: (NSString*) compilerPath;	// Available Z-Machine/glulx versions for a given Inform 6 compiler
+ (NSArray*)	  compilerPaths;													// Places where Inform 6 compilers are likely to be found
+ (NSArray*)	  availableCompilers;												// List of available Inform 6 compilers

+ (int) majorVersionFromCompilerVersion: (NSString*) version;						// Major version number from an Inform 6 compiler version
+ (int) minorVersionFromCompilerVersion: (NSString*) version;						// Minor version number from an Inform 6 compiler version
+ (NSComparisonResult) compareCompilerVersion: (NSString*) version1					// Compare two compiler version numbers to see which is more recent
									toVersion: (NSString*) version2;

- (void) setBuildForRelease: (BOOL) willRelease;									// If set, debug options will be turned off while building
- (void) setSettings: (IFCompilerSettings*) settings;								// Sets the settings to use while compiling
- (void) setInputFile: (NSString*) path;											// Sets the initial input file
- (void) setDirectory: (NSString*) path;											// Sets the build products directory
- (NSString*) inputFile;															// Retrieves the input file name
- (IFCompilerSettings*) settings;													// Retrieves the settings
- (NSString*) directory;															// Retrieves the working directory path

- (void) prepareForLaunch;															// Prepares the first task for launch
- (BOOL) isRunning;																	// YES if a compiler is running

- (void) addCustomBuildStage: (NSString*) command									// Adds a new build stage to the compiler
               withArguments: (NSArray*) arguments
              nextStageInput: (NSString*) file
				errorHandler: (NSObject<IFCompilerProblemHandler>*) handler
					   named: (NSString*) stageName;
- (void) addNaturalInformStage;														// Adds a new Natural Inform build stage to the compiler
- (void) addStandardInformStage;													// Adds a new Inform 6 build stage to the compiler
- (NSString*) currentStageInput;													// Pathname of the input file for the current build stage

- (void)      deleteOutput;															// Deletes the output from the compiler
- (NSString*) outputFile;															// Path of the compiler output file
- (NSURL*)    problemsURL;															// URL of the file that should be shown in the 'Problems' tab; nil if we should use the standard problems.html file
- (void)      setOutputFile: (NSString*) file;										// Sets the file that the compiler should target
- (void)      setDeletesOutput: (BOOL) deletes;										// If YES, the output is deleted when the compiler is deallocated

- (void) setDelegate: (id<NSObject>) delegate;										// Sets the delegate object for the compiler. The delegate is NOT RETAINED.
- (id)   delegate;																	// Retrieves the delegate object.

- (void) launch;																	// IGNITION! Er, fires off the compiler task.

- (void) sendStdOut: (NSString*) data;												// Pretends that the given string appeared on the standard out of the task

- (IFProgress*) progress;															// Retrieves the progress indicator for this compiler

@end

//
// Delegate method prototypes
//
@interface NSObject(IFCompilerDelegate)

- (void) taskFinished:       (int) exitCode;										// Called when every stage has completed, or when a stage fails (ie, when compiling has finished for whatever reason)
- (void) receivedFromStdOut: (NSString*) data;										// Called when some data arrives on stdout from the compiler
- (void) receivedFromStdErr: (NSString*) data;										// Called when some data arrives on stderr from the compiler

@end
