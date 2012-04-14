//
//  IFProject.h
//  Inform
//
//  Created by Andrew Hunter on Wed Aug 27 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "IFCompiler.h"
#import "IFCompilerSettings.h"
#import "IFProjectFile.h"
#import "IFIndexFile.h"
#import "IFContextMatcher.h"

#import "ZoomView/ZoomSkein.h"

extern NSString* IFProjectFilesChangedNotification;
extern NSString* IFProjectWatchExpressionsChangedNotification;
extern NSString* IFProjectBreakpointsChangedNotification;
extern NSString* IFProjectSourceFileRenamedNotification;
extern NSString* IFProjectSourceFileDeletedNotification;
extern NSString* IFProjectStartedBuildingSyntaxNotification;
extern NSString* IFProjectFinishedBuildingSyntaxNotification;

@interface IFProject : NSDocument<NSTextStorageDelegate> {
    // The data for this project
    IFProjectFile*      projectFile;
    IFCompilerSettings* settings;

    IFCompiler*          compiler;

    NSMutableDictionary* sourceFiles;
    NSString*            mainSource;
	
	NSTextStorage*       notes;
	IFIndexFile*         indexFile;
	
	ZoomSkein*			  skein;
	
	BOOL editingExtension;
    
    BOOL singleFile;
	
	NSMutableArray* watchExpressions;
	NSMutableArray* breakpoints;
	
	NSLock* matcherLock;
	int syntaxBuildCount;
	IFContextMatcher* inform6Matcher;
	IFContextMatcher* inform7Matcher;
	
	// Ports used to communicate with the running syntax matcher builder thread
	NSPort* mainThreadPort;
	NSPort* subThreadPort;
	NSConnection* subThreadConnection;
}

// The files and settings associated with the project

- (IFCompilerSettings*) settings;
- (IFCompiler*)         compiler;
- (IFProjectFile*)      projectFile;
- (NSDictionary*)       sourceFiles;

- (void) prepareForSaving;

// Properties associated with the project

- (BOOL) singleFile;
- (NSString*) mainSourceFile;
- (NSTextStorage*) storageForFile: (NSString*) sourceFile;
- (IFContextMatcher*) syntaxDictionaryMatcherForFile: (NSString*) sourceFile;
- (BOOL) fileIsTemporary: (NSString*) sourceFile;
- (BOOL) addFile: (NSString*) newFile;
- (BOOL) removeFile: (NSString*) oldFile;
- (BOOL) renameFile: (NSString*) oldFile 
		withNewName: (NSString*) newFile;

- (NSString*) pathForFile: (NSString*) file;
- (NSString*) materialsPath;

- (BOOL) editingExtension;

// 'Subsidiary' files

- (NSTextStorage*) notes;
- (IFIndexFile*)   indexFile;

- (void) reloadIndexFile;
- (void) reloadIndexDirectory;

- (ZoomSkein*) skein;

- (void) cleanOutUnnecessaryFiles: (BOOL) alsoCleanIndex;				// Removes compiler-generated files that are less useful to keep around

// The syntax matcher

- (void) rebuildSyntaxMatchers;											// Requests that this project starts to rebuild its syntax matchers (in a separate thread)

// Watchpoints

- (void) addWatchExpression: (NSString*) expression;
- (void) replaceWatchExpressionAtIndex: (unsigned) index
						withExpression: (NSString*) expression;
- (NSString*) watchExpressionAtIndex: (unsigned) index;
- (unsigned) watchExpressionCount;
- (void) removeWatchExpressionAtIndex: (unsigned) index;

// Breakpoints

- (void) addBreakpointAtLine: (int) line
					  inFile: (NSString*) filename;
- (void) replaceBreakpointAtIndex: (unsigned) index
			 withBreakpointAtLine: (int) line
						   inFile: (NSString*) filename;
- (int) lineForBreakpointAtIndex: (unsigned) index;
- (NSString*) fileForBreakpointAtIndex: (unsigned) index;
- (unsigned) breakpointCount;
- (void) removeBreakpointAtIndex: (unsigned) index;
- (void) removeBreakpointAtLine: (int) line
						 inFile: (NSString*) file;

@end
