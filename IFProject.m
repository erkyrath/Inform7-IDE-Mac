//
//  IFProject.m
//  Inform
//
//  Created by Andrew Hunter on Wed Aug 27 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFProject.h"
#import "IFProjectController.h"

#import "IFPreferences.h"

#import "IFSyntaxStorage.h"
#import "IFNaturalHighlighter.h"
#import "IFInform6Highlighter.h"

#import "IFNaturalIntel.h"
#import "IFSharedContextMatcher.h"

#include "uuid/uuid.h"

NSString* IFProjectFilesChangedNotification = @"IFProjectFilesChangedNotification";
NSString* IFProjectWatchExpressionsChangedNotification = @"IFProjectWatchExpressionsChangedNotification";
NSString* IFProjectBreakpointsChangedNotification = @"IFProjectBreakpointsChangedNotification";
NSString* IFProjectSourceFileRenamedNotification = @"IFProjectSourceFileRenamedNotification";
NSString* IFProjectSourceFileDeletedNotification = @"IFProjectSourceFileDeletedNotification";
NSString* IFProjectStartedBuildingSyntaxNotification = @"IFProjectStartedBuildingSyntaxNotification";
NSString* IFProjectFinishedBuildingSyntaxNotification = @"IFProjectFinishedBuildingSyntaxNotification";

@implementation IFProject

- (IFContextMatcher*) syntaxDictionaryMatcherForFile: (NSString*) filename {
	NSString* extn = [[filename pathExtension] lowercaseString];
	IFContextMatcher* result = nil;
	
	[matcherLock lock];
	if ([extn isEqualToString: @"inf"] ||
		[extn isEqualToString: @"i6"] ||
		[extn isEqualToString: @"h"]) {
		// Inform 6 file
		result = [[inform6Matcher retain] autorelease];
	} else if ([extn isEqualToString: @"ni"] ||
			   [extn isEqualToString: @""]) {
		// Natural Inform file
		result = [[inform7Matcher retain] autorelease];
	}
	[matcherLock unlock];
	
	return result;
}

- (id<IFSyntaxHighlighter,NSObject>) highlighterForFilename: (NSString*) filename {
	NSString* extn = [[filename pathExtension] lowercaseString];
	
	if (![[IFPreferences sharedPreferences] enableSyntaxHighlighting]) return nil;
	
	if ([extn isEqualToString: @"inf"] ||
		[extn isEqualToString: @"i6"] ||
		[extn isEqualToString: @"h"]) {
		// Inform 6 file
		return [[[IFInform6Highlighter alloc] init] autorelease];
	} else if ([extn isEqualToString: @"ni"] ||
			   [extn isEqualToString: @""]) {
		// Natural Inform file
		return [[[IFNaturalHighlighter alloc] init] autorelease];
	}
	
	// No highlighter
	return nil;
}

- (id<IFSyntaxIntelligence,NSObject>) intelligenceForFilename: (NSString*) filename {
	NSString* extn = [[filename pathExtension] lowercaseString];
	
	if (![[IFPreferences sharedPreferences] enableIntelligence]) return nil;
	
	if ([extn isEqualToString: @"inf"] ||
		[extn isEqualToString: @"i6"] ||
		[extn isEqualToString: @"h"]) {
		// Inform 6 file (no intelligence yet)
		return nil;
	} else if ([extn isEqualToString: @"ni"] ||
			   [extn isEqualToString: @""]) {
		// Natural Inform file
		return [[[IFNaturalIntel alloc] init] autorelease];
	}
	
	// No intelligence
	return nil;
}

- (IFSyntaxStorage*) storageWithString: (NSString*) string
						   forFilename: (NSString*) filename {
	// Fix any newlines in string
	int initialLength = [string length];
	int len = 0;
	
	// Note that the string can only get shorter
	unichar* fixedString = malloc(sizeof(unichar)*[string length]);
	
	int x;
	BOOL useFixedVersion = NO;
	for (x=0; x<initialLength; x++) {
		// Fetch the next character
		unichar ch = [string characterAtIndex: x];
		
		// See if we've got a newline
		if (ch == 10) {
			// Ignore the next character if it's a carriage return
			if (x+1<initialLength && [string characterAtIndex: x+1] == 13) {
				x++;
				useFixedVersion = YES;
			}
			
			// Store a newline
			fixedString[len++] = 10;
		} else if (ch == 13) {
			// Length doesn't always change, but we've got a CR line ending where a NL one should exist
			useFixedVersion = YES;
			
			// Ignore the next character if it's a newline
			if (x+1<initialLength && [string characterAtIndex: x+1] == 10) {				
				x++;
			}
			
			// Store a newline
			fixedString[len++] = 10;
		} else {
			// Copy this character through
			fixedString[len++] = ch;
		}
	}
	
	// Use the fixed string if it's different from the original
	if (useFixedVersion) {
		NSLog(@"Warning: reformated newlines in file '%@'", filename);
		string = [NSString stringWithCharacters: fixedString
										 length: len];
	}
	
	free(fixedString);
	
	// Create the syntax-highlighting text storage object
	IFSyntaxStorage* res = [[IFSyntaxStorage alloc] initWithString: string];
	
	// Set the 'intelligence' and highlighting style appropriately
	[res setIntelligence: [self intelligenceForFilename: filename]];
	[res setHighlighter: [self highlighterForFilename: filename]];
	[res setElasticTabs: [settings elasticTabs]];
	[res setDelegate: self];
	
	return [res autorelease];
}

- (IFSyntaxStorage*) storageWithAttributedString: (NSAttributedString*) string
									 forFilename: (NSString*) filename {
	IFSyntaxStorage* res = [[IFSyntaxStorage alloc] initWithAttributedString: string];
	
	[res setIntelligence: [self intelligenceForFilename: filename]];
	[res setHighlighter: [self highlighterForFilename: filename]];
	[res setElasticTabs: [settings elasticTabs]];
	[res setDelegate: self];
	
	return [res autorelease];
}

- (IFSyntaxStorage*) storageWithData: (NSData*) fileContents
						 forFilename: (NSString*) filename {
	BOOL loadAsRtf = NO;
	
	if ([[[filename pathExtension] lowercaseString] isEqualToString: @"rtf"])
		loadAsRtf = YES;
	
	if (loadAsRtf) {
		return [self storageWithAttributedString: [[[NSAttributedString alloc] initWithRTF: fileContents
																		documentAttributes: nil] autorelease]
									 forFilename: filename];
	} else {
		// First, try loading as a UTF-8 string (this is the default behaviour)
		NSString* fileString = [[NSString alloc] initWithData: fileContents
													 encoding: NSUTF8StringEncoding];
		
		if (fileString == nil) {
			// This can happen if fileString isn't in UTF-8 format for some reason (perhaps due to external editing)
			// Retry with Latin-1 and log a warning
			NSLog(@"Warning: file '%@' cannot be interpreted as UTF-8: trying Latin-1", filename);
			fileString = [[NSString alloc] initWithData: fileContents
											   encoding: NSISOLatin1StringEncoding];
		}
		if (fileString == nil) {
			// We can't interpret this file in any way - report the failure. An exception will be thrown later
			NSLog(@"Warning: no text available for file '%@'", filename);
		}
		return [self storageWithString: [fileString autorelease]
						   forFilename: filename];
	}
}

// == Initialisation ==

- (id) init {
    self = [super init];

    if (self) {
        settings = [[IFCompilerSettings allocWithZone: [self zone]] init];
        projectFile = nil;
        sourceFiles = nil;
        mainSource  = nil;
        singleFile  = YES;
		
		[settings setElasticTabs: [[IFPreferences sharedPreferences] elasticTabs]];
		
		skein = [[ZoomSkein alloc] init];

        compiler = [[IFCompiler allocWithZone: [self zone]] init];
		
		notes = [[NSTextStorage alloc] initWithString: @""];
		
		watchExpressions = [[NSMutableArray alloc] init];
		breakpoints = [[NSMutableArray alloc] init];
		
		inform6Matcher = [[IFSharedContextMatcher matcherForInform6] retain];
		inform7Matcher = [[IFSharedContextMatcher matcherForInform7] retain];
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
	
	[watchExpressions release];
	[breakpoints release];
	
	[inform6Matcher release];
	[inform7Matcher release];

	if (mainThreadPort)			[mainThreadPort release];
	if (subThreadPort)			[subThreadPort release];
	if (subThreadConnection)	[subThreadConnection release];
	
    [super dealloc];
}

// == Loading/saving ==

- (BOOL) readFromFile: (NSString*) fileName
			   ofType: (NSString*) fileType {
    if ([fileType isEqualTo: @"Inform project file"] || [fileType isEqualTo: @"Inform project"]) {
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
            IFSyntaxStorage* text;

			if (![[source objectForKey: key] isRegularFile]) continue;

			NSData* regularFileContents = [[source objectForKey: key] regularFileContents];
			
			text = [self storageWithData: regularFileContents
							 forFilename: key];

            [sourceFiles setObject: text
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
				[settings setElasticTabs: [[IFPreferences sharedPreferences] elasticTabs]];
			} else {
				// Standard settings
				settings = [[IFCompilerSettings alloc] init];
				[settings setElasticTabs: [[IFPreferences sharedPreferences] elasticTabs]];
			}
		}

        singleFile = NO;
		
		// Create a uuid.txt file, if it doesn't already exit
		if ([[projectFile fileWrappers] objectForKey: @"uuid.txt"] == nil) {
			// Generate a UUID string
			uuid_t newUID;
			uuid_clear(newUID);
			uuid_generate(newUID);
			
			char uid[40];
			uuid_unparse(newUID, uid);
			
			NSString* uidString = [NSString stringWithCString: uid];
			[projectFile addRegularFileWithContents: [uidString dataUsingEncoding: NSUTF8StringEncoding]
								  preferredFilename: @"uuid.txt"];
		}
		
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
		
		// Load the watchpoints file (if present)
		NSFileWrapper* watchWrapper = [[projectFile fileWrappers] objectForKey: @"Watchpoints.plist"];
		if (watchWrapper != nil && [watchWrapper regularFileContents] != nil) {
			NSString* propError = nil;
			NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
			NSArray* watchpointsLoaded = [NSPropertyListSerialization propertyListFromData: [watchWrapper regularFileContents]
																		  mutabilityOption: NSPropertyListImmutable
																					format: &format
																		  errorDescription: &propError];
			
			if (watchpointsLoaded && [watchpointsLoaded isKindOfClass: [NSArray class]]) {
				[watchExpressions release];
				watchExpressions = [watchpointsLoaded mutableCopy];
			}
		}
		
		// Load the breakpoints file (if present)
		NSFileWrapper* breakWrapper = [[projectFile fileWrappers] objectForKey: @"Breakpoints.plist"];
		if (breakWrapper != nil && [breakWrapper regularFileContents] != nil) {
			NSString* propError = nil;
			NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
			NSArray* breakpointsLoaded = [NSPropertyListSerialization propertyListFromData: [breakWrapper regularFileContents]
																		  mutabilityOption: NSPropertyListImmutable
																					format: &format
																		  errorDescription: &propError];
			
			if (breakpointsLoaded && [breakpointsLoaded isKindOfClass: [NSArray class]]) {
				[breakpoints release];
				breakpoints = [breakpointsLoaded mutableCopy];
			}
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
		[settings setElasticTabs: [[IFPreferences sharedPreferences] elasticTabs]];
        
        // Load the single file
        NSString* theFile = [NSString stringWithContentsOfFile: fileName];
		
		IFSyntaxStorage* text = [[IFSyntaxStorage alloc] initWithString: theFile];
		[text setHighlighter: [[[IFInform6Highlighter alloc] init] autorelease]];
        
        if (sourceFiles) [sourceFiles release];
        sourceFiles = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
            [text autorelease],
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
		[settings setElasticTabs: [[IFPreferences sharedPreferences] elasticTabs]];
        
        // Load the single file
        NSString* theFile = [NSString stringWithContentsOfFile: fileName];

		IFSyntaxStorage* text = [[IFSyntaxStorage alloc] initWithString: theFile];
		[text setIntelligence: [[[IFNaturalIntel alloc] init] autorelease]];
		[text setHighlighter: [[[IFNaturalHighlighter alloc] init] autorelease]];
		[text setElasticTabs: [settings elasticTabs]];

        if (sourceFiles) [sourceFiles release];
        sourceFiles = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
            [text autorelease],
            [fileName lastPathComponent], nil];
        
        if (mainSource) [mainSource release];
        mainSource = [[fileName lastPathComponent] copy];
        
        singleFile = YES;
        return YES;
	} else if ([fileType isEqualTo: @"Inform Extension Directory"]) {
		// Opening a plain ole extension
		editingExtension = YES;
		singleFile = NO;
		
        // Open the directory
        projectFile = [[IFProjectFile allocWithZone: [self zone]]
			initWithPath: fileName];
		
        if (![projectFile isDirectory]) {
            [projectFile release];
            projectFile = nil;
            return NO;
        }
		
        // Turn the source directory into NSTextStorages
        NSFileWrapper* sourceDir = projectFile;
		
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
            IFSyntaxStorage* text;
			
			if ([key characterAtIndex: 0] == '.') continue;
			if (![[source objectForKey: key] isRegularFile]) continue;
			
			NSData* regularFileContents = [[source objectForKey: key] regularFileContents];
			
			text = [self storageWithData: regularFileContents
							 forFilename: key];
			
            [sourceFiles setObject: text
                            forKey: key];
			
            if ([[key pathExtension] isEqualTo: @"inf"] ||
                [[key pathExtension] isEqualTo: @"ni"] ||
				[[key pathExtension] isEqualTo: @""]) {
                if (mainSource) [mainSource release];
                mainSource = [key copy];
            }
        }
		
		// Create an 'Untitled' file if there's no mainSource
		if (!mainSource) {
			mainSource = [@"Untitled" retain];
			[sourceFiles setObject: [self storageWithString: @""
												forFilename: @"Untitled"]
							forKey: mainSource];
		}
		
		return YES;
	}
    
    return NO;
}

- (BOOL) writeToFile: (NSString*) fileName ofType: (NSString*) fileType {
    if ([fileType isEqualTo: @"Inform project file"] || [fileType isEqualTo: @"Inform project"]) {
        [self prepareForSaving];
        
        return [projectFile writeToFile: fileName
                             atomically: YES
                        updateFilenames: YES];
    } else if ([fileType isEqualToString: @"Inform source file"] ||
               [fileType isEqualToString: @"Inform header file"]) {
        NSTextStorage* theFile = [self storageForFile: [self mainSourceFile]];
		
		if (theFile == nil) {
			NSLog(@"Bug: no file storage found");
		}
        
        return [[theFile string] writeToFile: fileName
                                  atomically: YES];
    } else if ([fileType isEqualToString: @"Inform Extension Directory"]) {
        [self prepareForSaving];
        
        return [projectFile writeToFile: fileName
                             atomically: YES
                        updateFilenames: YES];
	}
    
    return NO;
}

- (BOOL) addFile: (NSString*) newFile {
    if ([sourceFiles objectForKey: newFile] != nil) return NO;
    if (singleFile) return NO;
	    
    [sourceFiles setObject: [self storageWithString: @""
										forFilename: newFile]
                    forKey: newFile];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: IFProjectFilesChangedNotification
														object: self];
    return YES;
}

- (BOOL) removeFile: (NSString*) oldFile {
	if ([sourceFiles objectForKey: oldFile] == nil) return YES; // Deleting a non-existant file always succeeds
	if (singleFile) return NO;
	
	[sourceFiles removeObjectForKey: oldFile];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: IFProjectSourceFileDeletedNotification
														object: self
													  userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
														  oldFile, @"OldFilename",
														  nil]];
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
					forKey: [[newFile copy] autorelease]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: IFProjectSourceFileRenamedNotification
														object: self
													  userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
														  [[oldFile copy] autorelease], @"OldFilename",
														  [[newFile copy] autorelease], @"NewFilename",
														  nil]];
	[[NSNotificationCenter defaultCenter] postNotificationName: IFProjectFilesChangedNotification
														object: self];
	return YES;
}

// == General housekeeping ==
- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
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
	
	// Clean out any files that we aren't using any more, if set in the preferences
	if ([[IFPreferences sharedPreferences] cleanProjectOnClose]) {
		[self cleanOutUnnecessaryFiles: NO];
	}
    
    // Output all the source files to the project file wrapper
    NSEnumerator* keyEnum = [sourceFiles keyEnumerator];
    NSString*     key;
    NSFileWrapper* source;
	
	if (!editingExtension) {
		source = [[NSFileWrapper alloc] initDirectoryWithFileWrappers: nil];

		[source setPreferredFilename: @"Source"];
		[source setFilename: @"Source"];
	} else {
		//source = [projectFile retain];
		source = [[IFProjectFile alloc] initDirectoryWithFileWrappers: [NSDictionary dictionary]];
		[source setPreferredFilename: @"Source"];
		[projectFile release];
		projectFile = [source retain];
	}

    while (key = [keyEnum nextObject]) {
        NSData*        data;
        NSFileWrapper* file;
        
        if ([[key pathExtension] isEqualToString: @"rtf"]) {
            NSAttributedString* str = [sourceFiles objectForKey: key];
            
            data = [str RTFFromRange: NSMakeRange(0, [str length]) documentAttributes: nil];
        } else {
            data = [[[sourceFiles objectForKey: key] string] dataUsingEncoding: NSUTF8StringEncoding];
        }
        file = [[NSFileWrapper alloc] initRegularFileWithContents: data];

        [file setFilename: key];
        [file setPreferredFilename: key];

        [source addFileWrapper: [file autorelease]];
    }
	
	if (editingExtension) {
		// That's all folks
		[source release];
		return;
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
	
	// The watchpoints file
	[projectFile removeFileWrapper: [[projectFile fileWrappers] objectForKey: @"Watchpoints.plist"]];
	
	if ([watchExpressions count] > 0) {
		NSString* plistError = nil;
		
		NSFileWrapper* watchWrapper = [[NSFileWrapper alloc] initRegularFileWithContents: 
			[NSPropertyListSerialization dataFromPropertyList: watchExpressions
													   format: NSPropertyListXMLFormat_v1_0
											 errorDescription: &plistError]];
		
		[watchWrapper setPreferredFilename: @"Watchpoints.plist"];
		[projectFile addFileWrapper: watchWrapper];
		
		[watchWrapper release];
	}
	
	// The breakpoints file
	[projectFile removeFileWrapper: [[projectFile fileWrappers] objectForKey: @"Breakpoints.plist"]];
	
	if ([breakpoints count] > 0) {
		NSString* plistError = nil;
		
		NSFileWrapper* breakWrapper = [[NSFileWrapper alloc] initRegularFileWithContents: 
			[NSPropertyListSerialization dataFromPropertyList: breakpoints
													   format: NSPropertyListXMLFormat_v1_0
											 errorDescription: &plistError]];
		
		[breakWrapper setPreferredFilename: @"Breakpoints.plist"];
		[projectFile addFileWrapper: breakWrapper];
		
		[breakWrapper release];
	}
	
    // Setup the settings
    [projectFile setSettings: settings];
}

- (NSString*) mainSourceFile {
    if (singleFile || editingExtension) return mainSource;
    
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
	
	if (editingExtension) {
		// Special case: we're editing an extension, so source files are in the root directory
		sourceDir = [[self fileName] stringByStandardizingPath];
	}
	
	if (projectFile == nil && [[sourceFile lastPathComponent] isEqualToString: [[self fileName] lastPathComponent]]) {
		if (![sourceFile isAbsolutePath]) {
			// Special case: when we're editing an individual file, then we always use that filename if possible
			sourceFile = [self fileName];
		}
	}
	
	// Refuse to return storage for files outside the project directory
	if (sourceDir && [sourceFile isAbsolutePath]) {
		if (![[sourceFile stringByStandardizingPath] hasPrefix: sourceDir]) {
			return nil;
		}
	}
	
	if (![sourceFile isAbsolutePath]) {
		// Force absolute path
		sourceFile = [[sourceDir stringByAppendingPathComponent: sourceFile] stringByStandardizingPath];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath: sourceFile]) {
			// project/Source/whatever doesn't exist: try project/whatever
			sourceFile = [[[self fileName] stringByAppendingPathComponent: originalSourceFile] stringByStandardizingPath];
			
			if (![[NSFileManager defaultManager] fileExistsAtPath: sourceFile]) {
				// If neither exists, use project/Source/whatever by default
				sourceFile = [[sourceDir stringByAppendingPathComponent: sourceFile] stringByStandardizingPath];
			}
		}
	}
	
	if ([sourceFile isAbsolutePath]) {
		// Absolute path
		if ([[[sourceFile stringByDeletingLastPathComponent] stringByStandardizingPath] isEqualToString: sourceDir]) {
			return [sourceFiles objectForKey: [sourceFile lastPathComponent]];
		}
		
		if (![[NSFileManager defaultManager] fileExistsAtPath: sourceFile]) {
			return nil;
		}
		
		// Temporary text storage
		NSString* textData = [[NSString alloc] initWithData: [NSData dataWithContentsOfFile: sourceFile]
												   encoding: NSUTF8StringEncoding];
		
		if (textData == nil) {
			// Sometimes a file cannot be interpreted using UTF-8: present something in this case
			textData = [[NSString alloc] initWithData: [NSData dataWithContentsOfFile: sourceFile]
											 encoding: NSISOLatin1StringEncoding];
		}
		
		storage = [self storageWithString: textData
							  forFilename: sourceFile];
		
		return storage;
	} else {
		// Not absolute path
	}
	
    return [sourceFiles objectForKey: sourceFile];
}

- (BOOL) fileIsTemporary: (NSString*) sourceFile {
	// If the filename is Source/Whatever, make it just Whatever
	if ([[sourceFile stringByDeletingLastPathComponent] isEqualToString: @"Source"]) {
		sourceFile = [sourceFile lastPathComponent];
	}
	
	// Work out the source directory
	NSString* sourceDir = [[[self fileName] stringByAppendingPathComponent: @"Source"] stringByStandardizingPath];
	
	if (editingExtension) {
		// Special case: we're editing an extension, so source files are in the root directory
		sourceDir = [[self fileName] stringByStandardizingPath];
	}
	
	if (projectFile == nil && [[sourceFile lastPathComponent] isEqualToString: [[self fileName] lastPathComponent]]) {
		if (![sourceFile isAbsolutePath]) {
			// Special case: when we're editing an individual file, then we always use that filename if possible
			sourceFile = [self fileName];
		}
	}
	
	sourceFile = [sourceFile stringByStandardizingPath];
	sourceDir = [sourceDir stringByStandardizingPath];	
	NSString* filename = [[self fileName] stringByStandardizingPath];
	
	if ([sourceFile isAbsolutePath]) {
		// Must begin with our filename/source
		if (projectFile == nil) {
			// Must be our filename
			if ([filename isEqualToString: sourceFile])
				return NO;
			else
				return YES;
		}
		
		if ([[sourceFile stringByDeletingLastPathComponent] isEqualToString: sourceDir]) {
			return NO;
		} else {
			return YES;
		}
	} else {
		// Must be in the list of project files
		if ([sourceFiles objectForKey: sourceFile] != nil) {
			return NO;
		} else {
			return YES;
		}
	}
	
	return YES;
}

- (IFProjectFile*) projectFile {
    return projectFile;
}

- (NSDictionary*) sourceFiles {
    return sourceFiles;
}

- (NSString*) pathForFile: (NSString*) file {
	if ([file isAbsolutePath]) return [file stringByStandardizingPath];
	
	if (!editingExtension)
		return [[[[self fileName] stringByAppendingPathComponent: @"Source"] stringByAppendingPathComponent: file] stringByStandardizingPath];
	else
		return [[[self fileName] stringByAppendingPathComponent: file] stringByStandardizingPath];
	
	if ([sourceFiles objectForKey: file] != nil) {
		return [[[self fileName] stringByAppendingPathComponent: @"Source"] stringByAppendingPathComponent: file];
	}
	
	// FIXME: search libraries
	
	return file;
}

- (NSString*) materialsPath {
	// Work out the location of the materials folder
	NSString* projectPath	= [self fileName];
	NSString* projectName	= [[projectPath lastPathComponent] stringByDeletingPathExtension];
	NSString* materialsName	= [NSString stringWithFormat: @"%@ Materials", projectName];
	NSString* materialsPath	= [[projectPath stringByDeletingLastPathComponent] stringByAppendingPathComponent: materialsName];
	
	return materialsPath;
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

- (void) reloadIndexDirectory {
	// Nothing to do if this is a single file
	if (singleFile) return;
	
	// Try to get the index file wrapper
	NSFileWrapper* oldIndexWrapper = [[projectFile fileWrappers] objectForKey: @"Index"];
	if (oldIndexWrapper && [self fileName]) {
		// Load in the index again
		NSFileWrapper*	indexWrapper	= nil;
		NSString*		indexPath		= [[self fileName] stringByAppendingPathComponent: @"Index"];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: indexPath]) {
			indexWrapper = [[[NSFileWrapper alloc] initWithPath: indexPath] autorelease];
			[indexWrapper setPreferredFilename: @"Index"];
		}
		
		// Remove the old index wrapper
		if (oldIndexWrapper) {
			[projectFile removeFileWrapper: oldIndexWrapper];
		}
		
		// Replace with the new one
		if (indexWrapper) {
			[projectFile addFileWrapper: indexWrapper];
		}
	}
}

- (BOOL) editingExtension {
	return editingExtension;
}

// = The skein =

- (ZoomSkein*) skein {
	return skein;
}

// = Watch expressions =

- (void) addWatchExpression: (NSString*) expression {
	[watchExpressions addObject: [[expression copy] autorelease]];
}

- (void) replaceWatchExpressionAtIndex: (unsigned) index
						withExpression: (NSString*) expression {
	[watchExpressions replaceObjectAtIndex: index
								withObject: [[expression copy] autorelease]];
}

- (void) removeWatchExpressionAtIndex: (unsigned) index {
	[watchExpressions removeObjectAtIndex: index];
}

- (NSString*) watchExpressionAtIndex: (unsigned) index {
	return [watchExpressions objectAtIndex: index];
}

- (unsigned) watchExpressionCount {
	return [watchExpressions count];
}

// Breakpoints

- (void) breakpointsHaveChanged {
	[[NSNotificationCenter defaultCenter] postNotificationName: IFProjectBreakpointsChangedNotification
														object: self];
}

- (void) addBreakpointAtLine: (int) line
					  inFile: (NSString*) filename {
	[breakpoints addObject: [NSArray arrayWithObjects: [NSNumber numberWithInt: line], [[filename copy] autorelease], nil]];
	
	[self breakpointsHaveChanged];
}

- (void) replaceBreakpointAtIndex: (unsigned) index
			 withBreakpointAtLine: (int) line
						   inFile: (NSString*) filename {
	[breakpoints replaceObjectAtIndex: index
						   withObject: [NSArray arrayWithObjects: [NSNumber numberWithInt: line], [[filename copy] autorelease], nil]];
	
	[self breakpointsHaveChanged];
}

- (int) lineForBreakpointAtIndex: (unsigned) index {
	return [[[breakpoints objectAtIndex: index] objectAtIndex: 0] intValue];
}

- (NSString*) fileForBreakpointAtIndex: (unsigned) index {
	return [[breakpoints objectAtIndex: index] objectAtIndex: 1];
}

- (unsigned) breakpointCount {
	return [breakpoints count];
}

- (void) removeBreakpointAtIndex: (unsigned) index {
	[breakpoints removeObjectAtIndex: index];
	
	[self breakpointsHaveChanged];
}

- (void) removeBreakpointAtLine: (int) line
						 inFile: (NSString*) file {
	NSArray* bp =  [NSArray arrayWithObjects: [NSNumber numberWithInt: line], [[file copy] autorelease], nil];
	NSUInteger index = [breakpoints indexOfObject: bp];
	
	if (index == NSNotFound) {
		NSLog(@"Attempt to remove nonexistant breakpoint %@:%i", file, line);
		return;
	}
	
	[self removeBreakpointAtIndex: index];
}

// = SyntaxStorage delegate =

- (void) rewroteCharactersInStorage: (IFSyntaxStorage*) storage
							  range: (NSRange) range
					 originalString: (NSString*) originalString
				  replacementString: (NSString*) replacementString {
	NSUndoManager* undo = [self undoManager];

	[undo setActionName: [[NSBundle mainBundle] localizedStringForKey: @"Auto Typing"
																value: @"Auto Typing"
																table: nil]];
	[undo beginUndoGrouping];

	// This ensures that we can redo this action
	[[undo prepareWithInvocationTarget: self] rewroteCharactersInStorage: storage
																   range: NSMakeRange(range.location, [replacementString length])
														  originalString: replacementString
													   replacementString: originalString];
	
	// Store the undo information
	[[undo prepareWithInvocationTarget: storage] replaceCharactersInRange: NSMakeRange(range.location, [replacementString length])
															   withString: originalString];
	
	[undo endUndoGrouping];
}

// = Cleaning =

- (void) cleanOutUnnecessaryFiles: (BOOL) alsoCleanIndex {
	// Clean out the build folder from the project
	NSFileWrapper* build = [[projectFile fileWrappers] objectForKey: @"Build"];
	if (build) [projectFile removeFileWrapper: build];
	
	// Replace it with an empty directory
	build = [[[NSFileWrapper alloc] initDirectoryWithFileWrappers: [NSDictionary dictionary]] autorelease];
	[build setPreferredFilename: @"Build"];
	[projectFile addFileWrapper: build];
	
	// There may also be a 'Temp' directory: remove that too (no need to recreate this)
	NSFileWrapper* temp = [[projectFile fileWrappers] objectForKey: @"Temp"];
	if (temp) [projectFile removeFileWrapper: temp];
	
	// Clean out the index folder from the project
	if (alsoCleanIndex) {
		NSFileWrapper* index = [[projectFile fileWrappers] objectForKey: @"Index"];
		if (index) [projectFile removeFileWrapper: index];
		
		// Replace it with an empty directory
		index = [[[NSFileWrapper alloc] initDirectoryWithFileWrappers: [NSDictionary dictionary]] autorelease];
		[index setPreferredFilename: @"Index"];
		[projectFile addFileWrapper: index];
	}
}

// = The syntax matcher =

- (void) rebuildSyntaxMatchers {
	// Post a notification so the UI can explain what's going on
	[[NSNotificationCenter defaultCenter] postNotificationName: IFProjectStartedBuildingSyntaxNotification
														object: self];
	
	// Start a thread to build the syntax matchers for this project
	[matcherLock lock];
	
	// Increase the build count so that only the results from the most recent thread gets through
	syntaxBuildCount++;
	
	// Build the thread information dictionary
	NSMutableDictionary* threadDictionary = [[[NSMutableDictionary alloc] init] autorelease];
	[threadDictionary setObject: [NSNumber numberWithInt: syntaxBuildCount]
						 forKey: @"RebuildNumber"];
	
	// Get the data for the files to copy
	NSMutableDictionary* xmlData = [[[NSMutableDictionary alloc] init] autorelease];
	
	if ([projectFile isDirectory]) {
		// Look in the syntax directory in the project directory
		NSString* xmlDir = [[self fileName] stringByAppendingPathComponent: @"Syntax"];
		
		// Refresh the syntax wrapper if necessary
		NSFileWrapper* syntaxWrapper = [[projectFile fileWrappers] objectForKey: @"Syntax"];
		[syntaxWrapper updateFromPath: xmlDir];
		
		// Must exist and be a directory
		BOOL isDir;
		if (![[NSFileManager defaultManager] fileExistsAtPath: xmlDir
												  isDirectory: &isDir])
			isDir = NO;
		
		if (isDir) {
			NSDictionary* fileWrappers = [syntaxWrapper fileWrappers];
			NSEnumerator* fileEnum = [[fileWrappers allKeys] objectEnumerator];
			NSString* file;
			
			// Iterate through the files in the directory and read in all the .xml files
			while (file = [fileEnum nextObject]) {
				if ([[file pathExtension] isEqualToString: @"xml"]) {
					NSData* dataForFile = [[fileWrappers objectForKey: file] regularFileContents];
					
					if (dataForFile) {
						[xmlData setObject: dataForFile
									forKey: file];
					}
				}
			}
		}
	}
	
	[threadDictionary setObject: xmlData
						 forKey: @"XmlData"];
	
	// Start a thread to build the syntax matchers
	if (mainThreadPort)			[mainThreadPort release];
	if (subThreadPort)			[subThreadPort release];
	if (subThreadConnection)	[subThreadConnection release];
	
	mainThreadPort	= [[NSPort port] retain];
	subThreadPort	= [[NSPort port] retain];
	[[NSRunLoop currentRunLoop] addPort: mainThreadPort
								forMode: NSDefaultRunLoopMode];
	
	subThreadConnection = [[NSConnection alloc] initWithReceivePort: mainThreadPort
														   sendPort: subThreadPort];
	[subThreadConnection setRootObject: self];
	
	[self retain];
	[NSThread detachNewThreadSelector: @selector(runSyntaxRebuild:)
							 toTarget: self
						   withObject: threadDictionary];
	
	[matcherLock unlock];
}

- (void) finishedRebuildingSyntax: (int) rebuildNumber {
	// Check the rebuild number
	[matcherLock lock];
	if (rebuildNumber != syntaxBuildCount) {
		// Do nothing if the last build to finish is not the build we're currently running
		[matcherLock unlock];
		return;
	}
	[matcherLock unlock];
	
	// Notify that the build has finished
	[[NSNotificationCenter defaultCenter] postNotificationName: IFProjectFinishedBuildingSyntaxNotification
														object: self];
}

- (void) runSyntaxRebuild: (NSDictionary*) rebuild {
	NSAutoreleasePool* mainPool = [[NSAutoreleasePool alloc] init];

	// Get the rebuild number
	int thisRebuild = [[rebuild objectForKey: @"RebuildNumber"] intValue];

	// Set up the connection to the main thread
	[[NSRunLoop currentRunLoop] addPort: subThreadPort
								forMode: NSDefaultRunLoopMode];
	NSConnection* mainThreadConnection = [[[NSConnection alloc] initWithReceivePort: subThreadPort
																		   sendPort: mainThreadPort] autorelease];

	// Check that this thread is still current
	[matcherLock lock];
	if (thisRebuild != syntaxBuildCount) {
		// Give up
		[self autorelease];
		[matcherLock unlock];
		[mainPool release];
		return;
	}
	[matcherLock unlock];
	
	// Start building the new context matcher by copying the general matcher
	IFContextMatcher* newI7Matcher = [[IFSharedContextMatcher matcherForInform7] copy];
	
	// Now read from all of the matcher files in the project directory
	NSDictionary* xmlData = [rebuild objectForKey: @"XmlData"];
	NSArray* filenames = [xmlData keysSortedByValueUsingSelector: @selector(caseInsensitiveCompare:)];
	
	NSEnumerator* fileEnum = [filenames objectEnumerator];
	NSString* file;
	
	while (file = [fileEnum nextObject]) {
		// Check that this thread is still current
		[matcherLock lock];
		if (thisRebuild != syntaxBuildCount) {
			// Give up
			[self autorelease];
			[newI7Matcher release];
			[matcherLock unlock];
			[mainPool release];
			return;
		}
		[matcherLock unlock];
		
		// Get the new matcher to read in the specified file
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		[newI7Matcher readXml: [[[NSXMLParser alloc] initWithData: [xmlData objectForKey: file]] autorelease]];
		[pool release];
	}
	
	// Now we can substitute the newly built parser
	[matcherLock lock];
	
	// Check that we're still in the right build
	if (thisRebuild != syntaxBuildCount) {
		// Give up
		[self autorelease];
		[newI7Matcher release];
		[matcherLock unlock];
		[mainPool release];
		return;
	}
	
	// Substitute the I7 matcher
	[inform7Matcher release];
	inform7Matcher = newI7Matcher;

	[matcherLock unlock];
	
	// Notify the main thread that the matcher is ready
	[(IFProject*)[mainThreadConnection rootProxy] finishedRebuildingSyntax: thisRebuild];
		
	// We're done
	[self autorelease];
	[mainPool release];
}

@end
