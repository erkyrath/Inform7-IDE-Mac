//
//  IFCompiler.m
//  Inform
//
//  Created by Andrew Hunter on Mon Aug 18 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFCompiler.h"

#import "Preferences/IFPreferences.h"

#import "IFNaturalProblem.h"
#import "IFInform6Problem.h"
#import "IFCblorbProblem.h"

static int mod = 0;

NSString* IFCompilerStartingNotification = @"IFCompilerStartingNotification";
NSString* IFCompilerStdoutNotification   = @"IFCompilerStdoutNotification";
NSString* IFCompilerStderrNotification   = @"IFCompilerStderrNotification";
NSString* IFCompilerFinishedNotification = @"IFCompilerFinishedNotification";

@implementation IFCompiler

// = Compiler versioning =

+ (NSDictionary*) parseCompilerFilename: (NSString*) pathname {
    // Compiler filenames have the form xxx-n.nn-[zcode|biplatform|glulx]
    NSString* filename = [pathname lastPathComponent];
    
    int x;
    int lastComponent = 0;
    NSMutableArray* components = [NSMutableArray array];
    
    for (x=0; x<[filename length]; x++) {
        if ([filename characterAtIndex: x] == '-') {
            [components addObject: [filename substringWithRange: NSMakeRange(lastComponent,
                                                                             x-lastComponent)]];
            lastComponent = x+1;
        }
    }
    
    [components addObject: [filename substringWithRange: NSMakeRange(lastComponent,
                                                                     x-lastComponent)]];
        
    if ([components count] != 3) return nil;
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [components objectAtIndex: 0], @"name",
        [components objectAtIndex: 1], @"version", 
        [components objectAtIndex: 2], @"platform",
        filename, @"filename",
        pathname, @"pathname",
        nil];
}

+ (int) majorVersionFromCompilerVersion: (NSString*) version {
	NSArray* versions = [version componentsSeparatedByString: @"."];
	
	if ([versions count] < 2) return 0;
	
	return [[versions objectAtIndex: 0] intValue];
}

+ (int) minorVersionFromCompilerVersion: (NSString*) version {
	NSArray* versions = [version componentsSeparatedByString: @"."];
	
	if ([versions count] < 2) return 0;
	
	return [[versions objectAtIndex: 1] intValue];
}

+ (NSComparisonResult) compareCompilerVersion: (NSString*) version1
									toVersion: (NSString*) version2 {
	Class ourClass = [self class];
	
	int majorVersion1 = [ourClass majorVersionFromCompilerVersion: version1];
	int majorVersion2 = [ourClass majorVersionFromCompilerVersion: version2];
	
	if (majorVersion1 > majorVersion2) return NSOrderedDescending;
	if (majorVersion2 > majorVersion1) return NSOrderedAscending;
	
	int minorVersion1 = [ourClass minorVersionFromCompilerVersion: version1];
	int minorVersion2 = [ourClass minorVersionFromCompilerVersion: version2];
	
	if (minorVersion1 > minorVersion2) return NSOrderedDescending;
	if (minorVersion2 > minorVersion1) return NSOrderedAscending;
	
	return NSOrderedSame;
}

+ (NSString*) maxCompilerVersion {
    NSString* maxVersion = nil;
    
    NSArray* compilers = [self availableCompilers];
    
    NSEnumerator* compEnum = [compilers objectEnumerator];
    NSDictionary* compDetails;
    
    while (compDetails = [compEnum nextObject]) {
		if ([[self class] compareCompilerVersion: [compDetails objectForKey: @"version"]
									   toVersion: maxVersion] == NSOrderedDescending) {
			maxVersion = [compDetails objectForKey: @"version"];
		}
    }
    
    return maxVersion;
}

+ (NSString*) compilerExecutableWithVersion: (NSString*) ver {
	NSArray* compilers = [self availableCompilers];
    
    NSString* comp = nil;
    
    NSEnumerator* compEnum = [compilers objectEnumerator];
    NSDictionary* compDetails;
    
    while (compDetails = [compEnum nextObject]) {
		if ([IFCompiler compareCompilerVersion: ver
									 toVersion: [compDetails objectForKey: @"version"]] == NSOrderedSame) {
			comp = [compDetails objectForKey: @"pathname"];
		}
    }
	
	if (comp == nil) {
		// Try harder to find a compiler version
		NSEnumerator* compEnum = [compilers objectEnumerator];

		while (compDetails = [compEnum nextObject]) {
			if (comp == nil && 
				[IFCompiler compareCompilerVersion: ver
										 toVersion: [compDetails objectForKey: @"version"]] == NSOrderedDescending) {
				comp = [compDetails objectForKey: @"pathname"];
			}
		}
		
		if (comp == nil) {
			comp = [[compilers objectAtIndex: 0] objectForKey: @"pathname"];
		}
	}
	
	return comp;
}

+ (NSArray*) compilerZMachineVersionsForCompiler: (NSString*) compilerPath {
	NSArray* compilers = [self availableCompilers];
        
    NSEnumerator* compEnum = [compilers objectEnumerator];
    NSDictionary* compDetails;
    
    while (compDetails = [compEnum nextObject]) {
        if ([[compDetails objectForKey: @"pathname"] isEqualToString: compilerPath]) {
			NSString* compType = [compDetails objectForKey: @"platform"];
			
			// compType can be 'zcode', 'biplatform' or 'glulx'. Default is assumed to be 'zcode'
			// First entry in the array is the 'default' type to be used if an unsupported version
			// is selected
			if ([compType isEqualToString: @"biplatform"]) {
				return [NSArray arrayWithObjects:
					[NSNumber numberWithInt: 5],
					[NSNumber numberWithInt: 3],
					[NSNumber numberWithInt: 4],
					[NSNumber numberWithInt: 6],
					[NSNumber numberWithInt: 7],
					[NSNumber numberWithInt: 8],
					[NSNumber numberWithInt: 256],
					nil];
			} else if ([compType isEqualToString: @"glulx"]) {
				return [NSArray arrayWithObjects: [NSNumber numberWithInt: 256], nil];
			} else {
				// ZCode or 'other'
				return [NSArray arrayWithObjects:
					[NSNumber numberWithInt: 5],
					[NSNumber numberWithInt: 3],
					[NSNumber numberWithInt: 4],
					[NSNumber numberWithInt: 6],
					[NSNumber numberWithInt: 7],
					[NSNumber numberWithInt: 8],
					nil];
			}
        }
    }
	
	return nil;
}

static NSArray* compilerCache = nil;

+ (NSArray*) compilerPaths {
	static NSArray* paths = nil;
	
	if (paths == nil) {
		NSMutableArray* res = [NSMutableArray array];
		NSArray* libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
		
		// User-supplied compiler directories
		NSEnumerator* libEnum;
		NSString* lib;
		
		libEnum = [libraries objectEnumerator];
		while (lib = [libEnum nextObject]) {
			[res addObject: [[lib stringByAppendingPathComponent: @"Inform"] stringByAppendingPathComponent: @"Compilers"]];
		}
		
		// Internal compiler directories
		NSString* bundlePath = [[NSBundle mainBundle] resourcePath];
		[res addObject: [bundlePath stringByAppendingPathComponent: @"Compilers"]];
		
		paths = [res copy];
	}
	
	return paths;
}

static int versionCompare(NSDictionary* a, NSDictionary* b, void* context) {
	NSNumber* version1 = [a objectForKey: @"version"];
	NSNumber* version2 = [b objectForKey: @"version"];
	
	return [version1 compare: version2];
}

+ (NSArray*) availableCompilers {
	if (compilerCache) return compilerCache;
	
	NSMutableArray* result = [NSMutableArray array];
	NSMutableArray* versions = [NSMutableArray array];
	NSArray* paths = [[self class] compilerPaths];
	
	NSEnumerator* pathEnum = [paths objectEnumerator];
	NSString* path;
	
	while (path = [pathEnum nextObject]) {
		NSArray* compilerDirectory = [[NSFileManager defaultManager] directoryContentsAtPath: path];
		
		NSEnumerator* compilerEnum = [compilerDirectory objectEnumerator];
		NSString* compiler;
		
		while (compiler = [compilerEnum nextObject]) {
			NSString* compPath = [path stringByAppendingPathComponent: compiler];
			NSDictionary* compDetails = [self parseCompilerFilename: compPath];
			NSNumber* version = [compDetails objectForKey: @"version"];
			
			if (compDetails != nil && ![versions containsObject: version]) {
				[result addObject: compDetails];
				[versions addObject: version];
			}
		}
	}
	
	[result sortUsingFunction: versionCompare context: nil];
	
	return compilerCache = [result retain];
}

// == Initialisation, etc ==

- (id) init {
    self = [super init];

    if (self) {
        settings = nil;
        inputFile = nil;
        theTask = nil;
        stdOut = stdErr = nil;
        delegate = nil;
        workingDirectory = nil;
		release = NO;
		
		progress = [[IFProgress alloc] init];

        deleteOutputFile = YES;
        runQueue = [[NSMutableArray allocWithZone: [self zone]] init];
    }
    
    return self;
}

- (void) dealloc {
    if (deleteOutputFile) [self deleteOutput];

    [theTask release];
    theTask = nil;

    if (outputFile)       [outputFile release];
    if (workingDirectory) [workingDirectory release];    
    if (settings)         [settings release];
    if (inputFile)        [inputFile release];

    if (stdOut) [stdOut release];
    if (stdErr) [stdErr release];
	
	if (stdErrH) [stdErrH release];
	if (stdOutH) [stdOutH release];
	
    //if (delegate) [delegate release];
	
	if (problemsURL) [problemsURL release];
	if (problemHandler) [problemHandler release];

    [runQueue release];
	[progress release];

	[[NSNotificationCenter defaultCenter] removeObserver: self];

    [super dealloc];
}

// == Setup ==

- (void) setBuildForRelease: (BOOL) willRelease {
	release = willRelease;
}

- (void) setSettings: (IFCompilerSettings*) set {
    if (settings) [settings release];

    settings = [set retain];
}

- (void) setInputFile: (NSString*) path {
    if (inputFile) [inputFile release];

    inputFile = [path copyWithZone: [self zone]];
}

- (NSString*) inputFile {
    return inputFile;
}

- (IFCompilerSettings*) settings {
    return settings;
}

- (void) deleteOutput {
    if (outputFile) {
        if ([[NSFileManager defaultManager] fileExistsAtPath: outputFile]) {
            NSLog(@"Removing '%@'", outputFile);
            [[NSFileManager defaultManager] removeFileAtPath: outputFile
                                                     handler: nil];
        } else {
            NSLog(@"Compiler produced no output");
            // Nothing to do
        }
        
        [outputFile release];
        outputFile = nil;
    }
}

- (void) addCustomBuildStage: (NSString*) command
               withArguments: (NSArray*) arguments
              nextStageInput: (NSString*) file
				errorHandler: (NSObject<IFCompilerProblemHandler>*) handler
					   named: (NSString*) stageName {
    if (theTask) {
        // This starts a new build process, so we kill the old task if it's still
        // running
        if ([theTask isRunning]) {
            [theTask terminate];
        }
        [theTask release];
        theTask = nil;
    }

    [runQueue addObject: [NSArray arrayWithObjects:
        [NSString stringWithString: command],
        [NSArray arrayWithArray: arguments],
        [NSString stringWithString: file],
		[[stageName copy] autorelease],
		handler,
		nil]];
}

- (void) addNaturalInformStage {
    // Prepare the arguments
    NSMutableArray* args = [NSMutableArray arrayWithArray: [settings naturalInformCommandLineArguments]];

    [args addObject: @"-package"];
    [args addObject: [NSString stringWithString: [self currentStageInput]]];
	[args addObject: [NSString stringWithFormat: @"-extension=%@", [settings fileExtension]]];
	
	if (release) {
		[args addObject: @"-release"];
	}
	
	if ([[IFPreferences sharedPreferences] showDebuggingLogs]) {
		[args addObject: @"-log"];
	}
	
	if ([settings nobbleRng] && !release) {
		[args addObject: @"-rng"];
	}
	
    [self addCustomBuildStage: [settings naturalInformCompilerToUse]
                withArguments: args
               nextStageInput: [NSString stringWithFormat: @"%@/Build/auto.inf", [self currentStageInput]]
				 errorHandler: [[[IFNaturalProblem alloc] init] autorelease]
						named: [[NSBundle mainBundle] localizedStringForKey: @"Compiling Natural Inform source" 
																	  value: @"Compiling Natural Inform source"
																	  table: nil]];
}

- (void) addStandardInformStage: (BOOL) usingNaturalInform {
    if (!outputFile) [self outputFile];
    
    // Prepare the arguments
    NSMutableArray* args = [NSMutableArray arrayWithArray: [settings commandLineArgumentsForRelease: release]];

    // [args addObject: @"-x"];
   
    [args addObject: [NSString stringWithString: [self currentStageInput]]];
    [args addObject: [NSString stringWithString: outputFile]];

    [self addCustomBuildStage: [settings compilerToUse]
                withArguments: args
               nextStageInput: outputFile
				 errorHandler: usingNaturalInform?[[[IFInform6Problem alloc] init] autorelease]:nil
						named: [[NSBundle mainBundle] localizedStringForKey: @"Compiling Inform 6 source" 
																	  value: @"Compiling Inform 6 source"
																	  table: nil]];
}

- (NSString*) currentStageInput {
    NSString* inFile = inputFile;
    if (![runQueue count] <= 0) inFile = [[runQueue lastObject] objectAtIndex: 2];

    return inFile;
}

- (BOOL) isRunning {
	return theTask!=nil?[theTask isRunning]:NO;
}

- (void) sendTaskDetails: (NSTask*) task {
	NSMutableString* taskMessage = [NSMutableString stringWithFormat: @"Launching: %@", [[task launchPath] lastPathComponent]];
	
	NSEnumerator* argEnum = [[task arguments] objectEnumerator];
	NSString* arg;
	while (arg = [argEnum nextObject]) {
		[taskMessage appendFormat: @" \"%@\"", arg];
	}
	
	[taskMessage appendString: @"\n"];
	[self sendStdOut: taskMessage];
}

- (void) prepareForLaunchWithBlorbStage: (BOOL) makeBlorb {
    // Kill off any old tasks...
    if (theTask) {
        if ([theTask isRunning]) {
            [theTask terminate];
        }
        [theTask release];
        theTask = nil;		
    }

	// There are no problems
	[problemsURL release]; problemsURL = nil;

    if (deleteOutputFile) [self deleteOutput];

    // Prepare the arguments
    if ([runQueue count] <= 0) {
        if ([[IFPreferences sharedPreferences] runBuildSh]) {
            NSString* buildsh = [[NSBundle mainBundle] pathForResource: @"build"
																ofType: @"sh"
														   inDirectory: @"Compilers"];
			
			if (buildsh == nil || ![[NSFileManager defaultManager] fileExistsAtPath: buildsh]) {
				buildsh = [@"~/build.sh" stringByExpandingTildeInPath];
			}
            
			[self addCustomBuildStage: buildsh
						withArguments: [NSArray array]
					   nextStageInput: [self currentStageInput]
						 errorHandler: nil
								named: @"Debug build stage"];
        }
        
        if ([settings usingNaturalInform]) {
            [self addNaturalInformStage];
        }

        if (![settings usingNaturalInform] || [settings compileNaturalInformOutput]) {
            [self addStandardInformStage: [settings usingNaturalInform]];
        }
		
		if (makeBlorb && [settings usingNaturalInform]) {
			// Blorb files kind of create an exception: we change our output file, for instance, and the input file is determined by the blurb file output by NI
			NSString* extension;
			
			if ([settings zcodeVersion] > 128) {
				extension = @"gblorb";
			} else {
				extension = @"zblorb";
			}
			
			// Work out the new output file
			NSString* oldOutput = [self outputFile];
			NSString* newOutput = [NSString stringWithFormat: @"%@.%@", [oldOutput stringByDeletingPathExtension], extension];
			
			// Work out where the blorb is coming from (this will only work for project directories, which luckily is all the current version of Inform will compile)
			NSString* blorbFile = [NSString stringWithFormat: @"%@/Release.blurb",
				[[[self currentStageInput] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent]];
			
			// Add a cBlorb stage
			NSString* cBlorbLocation = [[NSBundle mainBundle] pathForResource: @"cBlorb"
																	   ofType: @""
																  inDirectory: @"Compilers"];
			
			[self addCustomBuildStage: cBlorbLocation
						withArguments: [NSArray arrayWithObjects:
							blorbFile, 
							newOutput, 
							nil]
					   nextStageInput: newOutput
						 errorHandler: [[[IFCblorbProblem alloc] initWithBuildDir: [[self currentStageInput] stringByDeletingLastPathComponent]] autorelease]
								named: @"cBlorb build stage"];
			
			// Change the output file
			[self setOutputFile: newOutput];
		}
    }

    /*
    NSMutableArray* args = [NSMutableArray arrayWithArray: [settings commandLineArguments]];

    [args addObject: @"-x"];

    [args addObject: [NSString stringWithString: inputFile]];
    [args addObject: [NSString stringWithString: outputFile]];
     */
    
	NSString* stageName = [[runQueue objectAtIndex: 0] objectAtIndex: 3];
	[progress setMessage: stageName];
	[progress setPercentage: -1.0];
	
    NSArray* args     = [[runQueue objectAtIndex: 0] objectAtIndex: 1];
    NSString* command = [[runQueue objectAtIndex: 0] objectAtIndex: 0];
	
	[problemHandler release]; problemHandler = nil;
	if ([[runQueue objectAtIndex: 0] count] > 4) {
		problemHandler = [[[runQueue objectAtIndex: 0] objectAtIndex: 4] retain];
	}
	
    [[args retain] autorelease];
    [[command retain] autorelease];
    [runQueue removeObjectAtIndex: 0];

    // Prepare the task
    theTask = [[NSTask allocWithZone: [self zone]] init];
    finishCount = 0;
	
	if ([settings debugMemory]) {
		NSMutableDictionary* newEnvironment = [[theTask environment] mutableCopy];
		if (!newEnvironment) newEnvironment = [[NSMutableDictionary alloc] init];
		
		[newEnvironment setObject: @"1"
						   forKey: @"MallocGuardEdges"];
		[newEnvironment setObject: @"1"
						   forKey: @"MallocScribble"];
		[newEnvironment setObject: @"1"
						   forKey: @"MallocBadFreeAbort"];
		[newEnvironment setObject: @"512"
						   forKey: @"MallocCheckHeapStart"];
		[newEnvironment setObject: @"256"
						   forKey: @"MallocCheckHeapEach"];
		[newEnvironment setObject: @"1"
						   forKey: @"MallocStackLogging"];
		
		[theTask setEnvironment: newEnvironment];
		[newEnvironment release];
	}
	
	NSMutableString* executeString = [@"" mutableCopy];
		
	[executeString appendString: command];
	[executeString appendString: @" \\\n\t"];

	NSEnumerator* argEnum = [args objectEnumerator];;
	NSString* arg;

	while (arg = [argEnum nextObject]) {
		[executeString appendString: arg];
		[executeString appendString: @" "];
	}
		
	[executeString appendString: @"\n"];
	[self sendStdOut: executeString];
	[executeString release]; executeString = nil;

    [theTask setArguments:  args];
    [theTask setLaunchPath: command];
    if (workingDirectory)
        [theTask setCurrentDirectoryPath: workingDirectory];
    else
        [theTask setCurrentDirectoryPath: NSTemporaryDirectory()];

    // Prepare the task's IO

    // waitForDataInBackground is a daft way of doing things and a waste of a thread
    if (stdErr) [stdErr release];
    if (stdOut) [stdOut release];
	
	if (stdErrH) [stdErrH release];
	if (stdOutH) [stdOutH release];
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];

    stdErr = [[NSPipe allocWithZone: [self zone]] init];
    stdOut = [[NSPipe allocWithZone: [self zone]] init];

    [theTask setStandardOutput: stdOut];
    [theTask setStandardError:  stdErr];

    stdErrH = [[stdErr fileHandleForReading] retain];
    stdOutH = [[stdOut fileHandleForReading] retain];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(stdOutWaiting:)
                                                 name: NSFileHandleDataAvailableNotification
                                               object: stdOutH];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(stdErrWaiting:)
                                                 name: NSFileHandleDataAvailableNotification
                                               object: stdErrH];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(taskDidFinish:)
                                                 name: NSTaskDidTerminateNotification
                                               object: theTask];

    [stdOutH waitForDataInBackgroundAndNotify];
    [stdErrH waitForDataInBackgroundAndNotify];
}

- (void) launch {
    [[NSNotificationCenter defaultCenter] postNotificationName: IFCompilerStartingNotification
                                                        object: self];
	[self sendTaskDetails: theTask];
    [theTask launch];
}

- (NSURL*)    problemsURL {
	return problemsURL;
}

- (NSString*) outputFile {
    if (outputFile == nil) {
        outputFile = [[NSString stringWithFormat: @"%@/Inform-%x-%x.%@",
            NSTemporaryDirectory(), time(NULL), ++mod, [settings fileExtension]] retain];
        deleteOutputFile = YES;
    }

    return [NSString stringWithString: outputFile];
}

- (void) setOutputFile: (NSString*) file {
    if (outputFile) [outputFile release];
    outputFile = [file copy];
    deleteOutputFile = NO;
}

- (void) setDeletesOutput: (BOOL) deletes {
    deleteOutputFile = deletes;
}

- (void) setDelegate: (id<NSObject>) dg {
	delegate = dg;
    //if (delegate) [delegate release];
    //delegate = [dg retain];
}

- (id) delegate {
    return delegate;
}

- (void) setDirectory: (NSString*) path {
    if (workingDirectory) [workingDirectory release];
    workingDirectory = [path copy];
}

- (NSString*) directory {
    return [[workingDirectory copy] autorelease];
}

- (void) taskHasReallyFinished {
	int exitCode = [theTask terminationStatus];

    if ([runQueue count] <= 0) {
        if (exitCode != 0 && problemHandler) {
			[problemsURL release]; problemsURL = nil;
			
			problemsURL = [[problemHandler urlForProblemWithErrorCode: exitCode] copy];
		} else if (exitCode == 0 && problemHandler) {
			if ([problemHandler respondsToSelector: @selector(urlForSuccess)]) {
				problemsURL = [[problemHandler urlForSuccess] copy];
			}
		}
			
        if (delegate &&
            [delegate respondsToSelector: @selector(taskFinished:)]) {
            [delegate taskFinished: exitCode];
        }

        NSDictionary* uiDict = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt: exitCode],
            @"exitCode",
            nil];
        [[NSNotificationCenter defaultCenter] postNotificationName: IFCompilerFinishedNotification
                                                            object: self
                                                          userInfo: uiDict];
    } else {
        if (exitCode != 0) {
			if (problemHandler) {
				[problemsURL release]; problemsURL = nil;
				
				problemsURL = [[problemHandler urlForProblemWithErrorCode: exitCode] copy];
			}
			
            // The task failed
            if (delegate &&
                [delegate respondsToSelector: @selector(taskFinished:)]) {
                [delegate taskFinished: exitCode];
            }
            
            // Notify everyone of the failure
            NSDictionary* uiDict = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt: exitCode],
                @"exitCode",
                nil];
            [[NSNotificationCenter defaultCenter] postNotificationName: IFCompilerFinishedNotification
                                                                object: self
                                                              userInfo: uiDict];
            
            // Give up
            [runQueue removeAllObjects];
            [theTask release];
            theTask = nil;
            
            return;
        }
        
        // Prepare the next task for launch
        if (theTask) {
            if ([theTask isRunning]) {
                [theTask terminate];
            }
            [theTask release];
            theTask = nil;
        }
		
		NSString* stageName = [[runQueue objectAtIndex: 0] objectAtIndex: 3];
		[progress setMessage: stageName];
		[progress setPercentage: -1.0];
		
        NSArray* args     = [[runQueue objectAtIndex: 0] objectAtIndex: 1];
        NSString* command = [[runQueue objectAtIndex: 0] objectAtIndex: 0];

		[problemHandler release]; problemHandler = nil;
		if ([[runQueue objectAtIndex: 0] count] > 4) {
			problemHandler = [[[runQueue objectAtIndex: 0] objectAtIndex: 4] retain];
		}

		[[args retain] autorelease];
        [[command retain] autorelease];
        [runQueue removeObjectAtIndex: 0];

        theTask = [[NSTask allocWithZone: [self zone]] init];
        finishCount = 0;
		
		if ([settings debugMemory]) {
			NSMutableDictionary* newEnvironment = [[theTask environment] mutableCopy];
			if (!newEnvironment) newEnvironment = [[NSMutableDictionary alloc] init];
			
			[newEnvironment setObject: @"1"
							   forKey: @"MallocGuardEdges"];
			[newEnvironment setObject: @"1"
							   forKey: @"MallocScribble"];
			[newEnvironment setObject: @"1"
							   forKey: @"MallocBadFreeAbort"];
			[newEnvironment setObject: @"512"
							   forKey: @"MallocCheckHeapStart"];
			[newEnvironment setObject: @"256"
							   forKey: @"MallocCheckHeapEach"];
			[newEnvironment setObject: @"1"
							   forKey: @"MallocStackLogging"];
			
			[theTask setEnvironment: newEnvironment];
			[newEnvironment release];
		}
		
		NSMutableString* executeString = [@"" mutableCopy];
			
		[executeString appendString: command];
		[executeString appendString: @" \\\n\t"];
			
		NSEnumerator* argEnum = [args objectEnumerator];;
		NSString* arg;
			
		while (arg = [argEnum nextObject]) {
			[executeString appendString: arg];
			[executeString appendString: @" "];
		}
			
		[executeString appendString: @"\n"];
		[self sendStdOut: executeString];
		[executeString release]; executeString = nil;
		
        // Prepare the task
        [theTask setArguments:  args];
        [theTask setLaunchPath: command];
        if (workingDirectory)
            [theTask setCurrentDirectoryPath: workingDirectory];
        else
            [theTask setCurrentDirectoryPath: NSTemporaryDirectory()];

        // Prepare the task's IO
        if (stdErr) [stdErr release];
        if (stdOut) [stdOut release];

		if (stdErrH) [stdErrH release];
        if (stdOutH) [stdOutH release];

        [[NSNotificationCenter defaultCenter] removeObserver: self];

        stdErr = [[NSPipe allocWithZone: [self zone]] init];
        stdOut = [[NSPipe allocWithZone: [self zone]] init];

        [theTask setStandardOutput: stdOut];
        [theTask setStandardError:  stdErr];

        stdErrH = [[stdErr fileHandleForReading] retain];
        stdOutH = [[stdOut fileHandleForReading] retain];

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(stdOutWaiting:)
                                                     name: NSFileHandleDataAvailableNotification
                                                   object: stdOutH];

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(stdErrWaiting:)
                                                     name: NSFileHandleDataAvailableNotification
                                                   object: stdErrH];

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(taskDidFinish:)
                                                     name: NSTaskDidTerminateNotification
                                                   object: theTask];

        [stdOutH waitForDataInBackgroundAndNotify];
        [stdErrH waitForDataInBackgroundAndNotify];

        // Launch it
		[self sendTaskDetails: theTask];
        [theTask launch];
    }
}

// == Notifications ==
- (void) sendStdOut: (NSString*) data {
	if (delegate &&
		[delegate respondsToSelector: @selector(receivedFromStdOut:)]) {
		[delegate receivedFromStdOut: data]; 
	}
	
	NSDictionary* uiDict = [NSDictionary dictionaryWithObjectsAndKeys:
		data,
		@"string",
		nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: IFCompilerStdoutNotification
														object: self
													  userInfo: uiDict];
}

- (void) stdOutWaiting: (NSNotification*) not {
	if (finishCount >= 3) return;

    NSData* inData = [stdOutH availableData];

    if ([inData length]) {
		[self sendStdOut: [NSString stringWithCString: [inData bytes]
											   length: [inData length]]];

        [stdOutH waitForDataInBackgroundAndNotify];
    } else {
        finishCount++;

        if (finishCount == 3) {
            [self taskHasReallyFinished];
        }
    }
}

- (void) stdErrWaiting: (NSNotification*) not {
	if (finishCount >= 3) return;
	
    NSData* inData = [stdErrH availableData];

    if ([inData length]) {
        if (delegate &&
            [delegate respondsToSelector: @selector(receivedFromStdErr:)]) {
            [delegate receivedFromStdErr: [NSString stringWithCString: [inData bytes]
                                                               length: [inData length]]];
        }

        NSDictionary* uiDict = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithCString: [inData bytes]
                                 length: [inData length]],
                @"string",
                nil];
        [[NSNotificationCenter defaultCenter] postNotificationName: IFCompilerStderrNotification
                                                            object: self
                                                          userInfo: uiDict];
        
        [stdErrH waitForDataInBackgroundAndNotify];
    } else {
        finishCount++;

        if (finishCount == 3) {
            [self taskHasReallyFinished];
        }
    }
}

- (void) taskDidFinish: (NSNotification*) not {
    finishCount++;

    if (finishCount == 3) {
        [self taskHasReallyFinished];
    }
}

- (IFProgress*) progress {
	return progress;
}

@end
