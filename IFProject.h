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

#import "ZoomView/ZoomSkein.h"

extern NSString* IFProjectFilesChangedNotification;

@interface IFProject : NSDocument {
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
}

- (IFCompilerSettings*) settings;
- (IFCompiler*)         compiler;
- (IFProjectFile*)      projectFile;
- (NSDictionary*)       sourceFiles;

- (void) prepareForSaving;

- (BOOL) singleFile;
- (NSString*) mainSourceFile;
- (NSTextStorage*) storageForFile: (NSString*) sourceFile;
- (BOOL) fileIsTemporary: (NSString*) sourceFile;
- (BOOL) addFile: (NSString*) newFile;
- (BOOL) removeFile: (NSString*) oldFile;
- (BOOL) renameFile: (NSString*) oldFile 
		withNewName: (NSString*) newFile;

- (NSString*) pathForFile: (NSString*) file;

- (NSTextStorage*) notes;
- (IFIndexFile*)   indexFile;

- (void) reloadIndexFile;

- (ZoomSkein*) skein;

- (BOOL) editingExtension;

- (void) addWatchExpression: (NSString*) expression;
- (void) replaceWatchExpressionAtIndex: (unsigned) index
						withExpression: (NSString*) expression;
- (NSString*) watchExpressionAtIndex: (unsigned) index;
- (unsigned) watchExpressionCount;
- (void) removeWatchExpressionAtIndex: (unsigned) index;

@end
