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

@interface IFProject : NSDocument {
    // The data for this project
    IFProjectFile*      projectFile;
    IFCompilerSettings* settings;

    IFCompiler*          compiler;

    NSMutableDictionary* sourceFiles;
    NSString*            mainSource;
    
    BOOL singleFile;
}

- (IFCompilerSettings*) settings;
- (IFCompiler*)         compiler;
- (IFProjectFile*)      projectFile;
- (NSDictionary*)       sourceFiles;

- (void) prepareForSaving;

- (BOOL) singleFile;
- (NSString*) mainSourceFile;
- (NSTextStorage*) storageForFile: (NSString*) sourceFile;
- (BOOL) addFile: (NSString*) newFile;

@end
