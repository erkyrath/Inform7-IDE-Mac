//
//  IFProject.m
//  Inform
//
//  Created by Andrew Hunter on Wed Aug 27 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFProject.h"
#import "IFProjectController.h"


@implementation IFProject

// == Initialisation ==

- (id) init {
    self = [super init];

    if (self) {
        settings = [[IFCompilerSettings allocWithZone: [self zone]] init];
        projectFile = nil;
        sourceFiles = nil;
        mainSource  = nil;
        singleFile  = YES;

        compiler = [[IFCompiler allocWithZone: [self zone]] init];
        
        /*
        sourceFiles = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
            [[[NSTextStorage alloc] init] autorelease], @"untitled.inf", nil] retain];
        mainSource = [@"untitled.inf" retain];
         */
    }

    return self;
}

- (void) dealloc {
    [settings release];
    [compiler release];
    if (projectFile) [projectFile release];
    if (sourceFiles) [sourceFiles release];
    if (mainSource)  [mainSource  release];
    
    [super dealloc];
}

// == Loading/saving ==
- (BOOL) readFromFile: (NSString*) fileName ofType: (NSString*) fileType {
    if ([fileType isEqualTo: @"Inform project file"]) {
        if (projectFile) [projectFile release];
        if (sourceFiles) [sourceFiles release];
        if (mainSource)  [mainSource  release];

        // Open the directory
        projectFile = [[IFProjectFile allocWithZone: [self zone]]
            initWithPath: fileName];

        if (![projectFile isDirectory]) {
            [projectFile release];
            projectFile = nil;
            return NO;
        }

        // Refresh the settings
        if (settings) [settings release];
        settings = [[projectFile settings] retain];

        // Turn the source directory into NSTextStorages
        NSFileWrapper* sourceDir = [[projectFile fileWrappers] objectForKey: @"Source"];

        if (sourceDir == nil ||
            ![sourceDir isDirectory]) {
            [projectFile release];
            projectFile = nil;
            return NO;
        }

        if (sourceFiles) [sourceFiles release];
        sourceFiles = [[NSMutableDictionary allocWithZone: [self zone]] init];
        NSDictionary* source = [sourceDir fileWrappers];
        NSEnumerator* sourceEnum = [source keyEnumerator];
        NSString* key;

        if (mainSource) [mainSource release];
        mainSource = nil;

        while (key = [sourceEnum nextObject]) {
            NSTextStorage* text;
            NSString*      textData;

            if ([[key pathExtension] isEqualToString: @"rtf"]) {
                NSAttributedString* attr = [[NSAttributedString alloc] initWithRTF: 
                    [[[sourceDir fileWrappers] objectForKey: key] regularFileContents]
                                                                documentAttributes: nil];
                
                text = [[NSTextStorage allocWithZone: [self zone]] initWithAttributedString:
                    attr];
            } else {
                textData = [[NSString alloc] initWithData:
                    [[[sourceDir fileWrappers] objectForKey: key] regularFileContents]
                                                 encoding: NSISOLatin1StringEncoding];

                text = [[NSTextStorage allocWithZone: [self zone]] initWithString:
                    textData];
                [textData release];
            }

            [sourceFiles setObject: [text autorelease]
                            forKey: key];

            if ([[key pathExtension] isEqualTo: @"inf"] ||
                [[key pathExtension] isEqualTo: @"ni"]) {
                if (mainSource) [mainSource release];
                mainSource = [key copy];
            }
        }

        singleFile = NO;
        
        return YES;
    } else if ([fileType isEqualTo: @"Inform source file"] ||
               [fileType isEqualTo: @"Inform header file"]) {
        // No project file
        if (projectFile) [projectFile release];
        projectFile = nil;
        
        // Default settings
        if (settings) [settings release];
        settings = [[IFCompilerSettings allocWithZone: [self zone]] init];
        
        // Load the single file
        NSString* theFile = [NSString stringWithContentsOfFile: fileName];
        
        if (sourceFiles) [sourceFiles release];
        sourceFiles = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
            [[[NSTextStorage alloc] initWithString: theFile] autorelease],
            [fileName lastPathComponent], nil];
        
        if (mainSource) [mainSource release];
        mainSource = [[fileName lastPathComponent] copy];
        
        singleFile = YES;
        return YES;
    }
    
    return NO;
}

- (BOOL) writeToFile: (NSString*) fileName ofType: (NSString*) fileType {
    if ([fileType isEqualTo: @"Inform project file"]) {
        [self prepareForSaving];
        
        return [projectFile writeToFile: fileName
                             atomically: YES
                        updateFilenames: YES];
    } else if ([fileType isEqualToString: @"Inform source file"] ||
               [fileType isEqualToString: @"Inform header file"]) {
        NSTextStorage* theFile = [self storageForFile: [self mainSourceFile]];
        
        return [[theFile string] writeToFile: fileName
                                  atomically: YES];
    }
    
    return NO;
}

- (BOOL) addFile: (NSString*) newFile {
    if ([sourceFiles objectForKey: newFile] != nil) return NO;
    if (singleFile) return NO;
    
    [sourceFiles setObject: [[[NSTextStorage alloc] init] autorelease]
                    forKey: newFile];
    
    return YES;
}

// == General housekeeping ==
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
}

- (void)makeWindowControllers {
    IFProjectController *aController = [[IFProjectController allocWithZone:[self zone]] init];
    [self addWindowController:aController];
    [aController release];
}

// == Document info ==
- (IFCompilerSettings*) settings {
    return settings;
}

- (IFCompiler*) compiler {
    return compiler;
}

- (BOOL) singleFile {
    return singleFile;
}

// == Getting the files ==
- (void) prepareForSaving {
    // Update the project file wrapper from whatever is on the disk
    // (Implement me)
    
    // Output all the source files to the project file wrapper
    NSEnumerator* keyEnum = [sourceFiles keyEnumerator];
    NSString*     key;
    NSFileWrapper* source = [[NSFileWrapper alloc] initDirectoryWithFileWrappers: nil];

    [source setPreferredFilename: @"Source"];
    [source setFilename: @"Source"];

    while (key = [keyEnum nextObject]) {
        NSData*        data;
        NSFileWrapper* file;
        
        if ([[key pathExtension] isEqualToString: @"rtf"]) {
            NSAttributedString* str = [sourceFiles objectForKey: key];
            
            data = [str RTFFromRange: NSMakeRange(0, [str length]) documentAttributes: nil];
        } else {
            data = [[[sourceFiles objectForKey: key] string] dataUsingEncoding: NSISOLatin1StringEncoding];
        }
        file = [[NSFileWrapper alloc] initRegularFileWithContents: data];

        [file setFilename: key];
        [file setPreferredFilename: key];

        [source addFileWrapper: [file autorelease]];
    }

    // Replace the source file wrapper
    [projectFile removeFileWrapper: [[projectFile fileWrappers] objectForKey: @"Source"]];
    [projectFile addFileWrapper: [source autorelease]];

    // Setup the settings
    [projectFile setSettings: settings];
}

- (NSString*) mainSourceFile {
    if (singleFile) return mainSource;
    
    NSFileWrapper* sourceDir = [[projectFile fileWrappers] objectForKey: @"Source"];

    NSDictionary* source = [sourceDir fileWrappers];
    NSEnumerator* sourceEnum = [source keyEnumerator];
    NSString* key;

    if (mainSource) [mainSource autorelease];
    mainSource = nil;

    while (key = [sourceEnum nextObject]) {
        if ([[key pathExtension] isEqualTo: @"inf"] ||
            [[key pathExtension] isEqualTo: @"ni"]) {
            if (mainSource) [mainSource autorelease];
            mainSource = [key copy];
        }
    }

    return mainSource;
}

- (NSTextStorage*) storageForFile: (NSString*) sourceFile {
    return [sourceFiles objectForKey: sourceFile];
}

- (IFProjectFile*) projectFile {
    return projectFile;
}

- (NSDictionary*) sourceFiles {
    return sourceFiles;
}

@end
