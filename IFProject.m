//
//  IFProject.m
//  Inform
//
//  Created by Andrew Hunter on Wed Aug 27 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFProject.h"
#import "IFProjectController.h"

NSString* IFProjectFilesChangedNotification = @"IFProjectFilesChangedNotification";


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
		
		skein = [[ZoomSkein alloc] init];

        compiler = [[IFCompiler allocWithZone: [self zone]] init];
		
		notes = [[NSTextStorage alloc] initWithString: @""];
        
        /*
        sourceFiles = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
            [[[NSTextStorage alloc] init] autorelease], @"untitled.inf", nil] retain];
        mainSource = [@"untitled.inf" retain];
         */
    }

    return self;
}

- (void) dealloc {
    if (sourceFiles) [sourceFiles release];
    if (projectFile) [projectFile release];
    if (mainSource)  [mainSource  release];
	if (notes)       [notes release];
	if (indexFile)   [indexFile release];
	if (skein)		 [skein release];

	[settings release];
    [compiler release];

    [super dealloc];
}

// == Loading/saving ==
- (BOOL) readFromFile: (NSString*) fileName
			   ofType: (NSString*) fileType {
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

		// Load all the source files
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
		
		// Re-create the settings as required
		if (settings == nil) {
			if ([[mainSource pathExtension] isEqualTo: @"ni"]) {
				// Standard natural inform settings
				settings = [[IFCompilerSettings alloc] init];
				
				[settings setLibraryToUse: @"Natural"];
				[settings setUsingNaturalInform: YES];
			} else {
				// Standard settings
				settings = [[IFCompilerSettings alloc] init];
			}
		}

        singleFile = NO;
		
		// Load the notes (if present)
		NSFileWrapper* noteWrapper = [[projectFile fileWrappers] objectForKey: @"notes.rtf"];
		if (noteWrapper != nil && [noteWrapper regularFileContents] != nil) {
			NSTextStorage* newNotes = [[NSTextStorage alloc] initWithRTF: [noteWrapper regularFileContents]
													  documentAttributes: nil];
			
			if (newNotes) {
				if (notes) [notes release];
				notes = newNotes;
			}
		}
		
		// Load the skein file (if present)
		NSFileWrapper* skeinWrapper = [[projectFile fileWrappers] objectForKey: @"Skein.skein"];
		if (skeinWrapper != nil && [skeinWrapper regularFileContents] != nil) {
			[skein parseXmlData: [skeinWrapper regularFileContents]];
			[skein setActiveItem: [skein rootItem]];
		}
        
		// Load the index file (if present)
		[self reloadIndexFile];
		
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
    } else if ([fileType isEqualTo: @"Natural Inform source file"]) {
        // No project file
        if (projectFile) [projectFile release];
        projectFile = nil;
        
        // Default settings (Natural Inform)
        if (settings) [settings release];
        settings = [[IFCompilerSettings allocWithZone: [self zone]] init];
		
		[settings setLibraryToUse: @"Natural"];
		[settings setUsingNaturalInform: YES];
        
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
	    
    [sourceFiles setObject: [[[NSTextStorage alloc] initWithString: @""] autorelease]
                    forKey: newFile];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: IFProjectFilesChangedNotification
														object: self];
    return YES;
}

- (BOOL) removeFile: (NSString*) oldFile {
	if ([sourceFiles objectForKey: oldFile] == nil) return YES; // Deleting a non-existant file always succeeds
	if (singleFile) return NO;
	
	[sourceFiles removeObjectForKey: oldFile];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: IFProjectFilesChangedNotification
														object: self];
	return YES;
}

- (BOOL) renameFile: (NSString*) oldFile 
		withNewName: (NSString*) newFile {
	if ([sourceFiles objectForKey: oldFile] == nil) return NO;
	if ([sourceFiles objectForKey: newFile] != nil) return NO;
	if (singleFile) return NO;
	
	NSTextStorage* oldFileStorage = [[sourceFiles objectForKey: oldFile] retain];
	
	[sourceFiles removeObjectForKey: oldFile];
	[sourceFiles setObject: oldFileStorage
					forKey: newFile];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: IFProjectFilesChangedNotification
														object: self];
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
	
	// The notes file
	NSFileWrapper* notesWrapper = [[[NSFileWrapper alloc] initRegularFileWithContents: 
		[notes RTFFromRange: NSMakeRange(0, [notes length])
		 documentAttributes: nil]] autorelease];
	
	[notesWrapper setPreferredFilename: @"notes.rtf"];
	[projectFile removeFileWrapper: [[projectFile fileWrappers] objectForKey: @"notes.rtf"]];
	[projectFile addFileWrapper: notesWrapper];
	
	// The skein file
	NSFileWrapper* skeinWrapper = [[[NSFileWrapper alloc] initRegularFileWithContents:
		[[@"<?xml version=\"1.0\"?>\n" stringByAppendingString: [skein xmlData]] dataUsingEncoding: NSUTF8StringEncoding]] autorelease];
	
	[skeinWrapper setPreferredFilename: @"Skein.skein"];
	[projectFile removeFileWrapper: [[projectFile fileWrappers] objectForKey: @"Skein.skein"]];
	[projectFile addFileWrapper: skeinWrapper];
	
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
	NSTextStorage* storage;
	NSString* originalSourceFile = sourceFile;
	NSString* sourceDir = [[[self fileName] stringByAppendingPathComponent: @"Source"] stringByStandardizingPath];
	
	if (projectFile == nil && [[sourceFile lastPathComponent] isEqualToString: [[self fileName] lastPathComponent]]) {
		if (![sourceFile isAbsolutePath]) {
			// Special case: when we're editing an individual file, then we always use that filename if possible
			sourceFile = [self fileName];
		}
	}
	
	if (![sourceFile isAbsolutePath]) {
		// Force absolute path
		sourceFile = [[sourceDir stringByAppendingPathComponent: sourceFile] stringByStandardizingPath];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath: sourceFile]) {
			// project/Source/whatever doesn't exist: try project/whatever
			sourceFile = [[[self fileName] stringByAppendingPathComponent: originalSourceFile] stringByStandardizingPath];
		}
	}
	
	if ([sourceFile isAbsolutePath]) {
		// Absolute path
		if ([[[sourceFile stringByDeletingLastPathComponent] stringByStandardizingPath] isEqualToString: sourceDir]) {
			return [sourceFiles objectForKey: [sourceFile lastPathComponent]];
		}
		
		if (![[NSFileManager defaultManager] fileExistsAtPath: sourceFile]) {
			NSLog(@"IFProject: WARNING: Unable to find file '%@'", sourceFile);
		}
		
		// Temporary text storage
		NSString* textData = [[NSString alloc] initWithData: [NSData dataWithContentsOfFile: sourceFile]
												   encoding: NSISOLatin1StringEncoding];
		storage = [[NSTextStorage alloc] initWithString: [textData autorelease]];
		
		NSLog(@"IFProject: Using temporary storage from %@", sourceFile);
		return [storage autorelease];
	} else {
		// Not absolute path
	}
	
    return [sourceFiles objectForKey: sourceFile];
}

- (IFProjectFile*) projectFile {
    return projectFile;
}

- (NSDictionary*) sourceFiles {
    return sourceFiles;
}

- (NSString*) pathForFile: (NSString*) file {
	if ([file isAbsolutePath]) return [file stringByStandardizingPath];
	
	return [[[[self fileName] stringByAppendingPathComponent: @"Source"] stringByAppendingPathComponent: file] stringByStandardizingPath];
	
	if ([sourceFiles objectForKey: file] != nil) {
		return [[[self fileName] stringByAppendingPathComponent: @"Source"] stringByAppendingPathComponent: file];
	}
	
	// FIXME: search libraries
	
	return file;
}

- (NSTextStorage*) notes {
	return notes;
}

// = The index file =
- (IFIndexFile*) indexFile {
	return indexFile;
}

- (void) reloadIndexFile {
	if (singleFile) return; // Nothing to do
	
	if (indexFile) [indexFile release];
	indexFile = nil;
	
	indexFile = [[IFIndexFile alloc] initWithContentsOfFile: [[[self fileName] stringByAppendingPathComponent: @"Index"] stringByAppendingPathComponent: @"Headings.xml"]];
}

// = The skein =
- (ZoomSkein*) skein {
	return skein;
}

@end
