//
//  IFInform6Extensions.m
//  Inform
//
//  Created by Andrew Hunter on 12/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFInform6Extensions.h"

NSString* IFExtensionsChangedNotification = @"IFExtensionsChangedNotification";

@implementation IFInform6Extensions

- (id) init {
	return [self initWithNibName: @"Inform6Extensions"];
}

- (id) initWithNibName: (NSString*) nibName {
	self = [super initWithNibName: nibName];
	
	if (self) {
		extensions = nil;
		needRefresh = YES;
		
		activeExtensions = nil;
		
		[extensionTable registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(updateTable:)
													 name: IFExtensionsChangedNotification
												   object: nil];
	}
	
	return self;
}

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Inform 6 Libraries"
												  value: @"Inform 6 Libraries"
												  table: nil];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	if (extensions) [extensions release];
	if (extensionPath) [extensionPath release];
	
	[activeExtensions release];
	
	[super dealloc];
}

// = Meta-information about what to look for =

- (NSString*) extensionSubdirectory {
	return @"Inform 6 Extensions";
}

- (NSArray*) directoriesToSearch {
	NSArray* libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSMutableArray* libraryDirectories = [NSMutableArray array];
	
	// Look for 'Inform 6 Extensions' directories in each library directory
	NSEnumerator* libEnum = [libraries objectEnumerator];
	NSString* libPath;
	
	while (libPath = [libEnum nextObject]) {
		NSString* extnPath = [[libPath stringByAppendingPathComponent: @"Inform"] stringByAppendingPathComponent: [self extensionSubdirectory]];
		BOOL isDir;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: extnPath
												 isDirectory: &isDir]) {
			if (isDir) [libraryDirectories addObject: extnPath];
		}
	}
	
	return libraryDirectories;
}

// = Searching the extensions =

static int stringCompare(id a, id b, void* context) {
	return [(NSString*)a compare: b];
}

- (void) searchForExtensions {
	// Clear out the old extensions
	if (extensions) [extensions release];
	extensions = [[NSMutableArray alloc] init];
	
	if (extensionPath) [extensionPath release];
	extensionPath = [[NSMutableDictionary alloc] init];
	
	// Get the list of extensions
	NSArray* directories = [self directoriesToSearch];
	
	// An extension lives in a directory in one of the directories specified above
	NSEnumerator* dirEnum = [directories objectEnumerator];
	NSString* dir;

	while (dir = [dirEnum nextObject]) {
		// Get the contents of this directory
		NSArray* dirContents = [[NSFileManager defaultManager] directoryContentsAtPath: dir];
		
		if (!dirContents) continue;
		
		// Iterate through: add any directories found as an extension
		NSEnumerator* extnEnum = [dirContents objectEnumerator];
		NSString* extn;
		
		while (extn = [extnEnum nextObject]) {
			NSString* extnPath = [dir stringByAppendingPathComponent: extn];
			BOOL exists, isDir;
			
			exists = [[NSFileManager defaultManager] fileExistsAtPath: extnPath
														  isDirectory: &isDir];
			
			if (!exists || !isDir) continue;
			if ([extensions indexOfObjectIdenticalTo: extn] != NSNotFound) continue;
			
			[extensions addObject: extn];
			[extensionPath setObject: extnPath
							  forKey: extn];
		}
	}
	
	// Sort them
	[extensions sortUsingFunction: stringCompare
						  context: nil];
}

- (NSString*) pathForExtension: (NSString*) extension {
	return [extensionPath objectForKey: extension];
}

// = Compiler settings  =

- (NSArray*) includePathForCompiler: (NSString*) compiler {
	if (![compiler isEqualToString: IFCompilerInform6]) return nil;
	
	NSMutableArray* res = [NSMutableArray array];
	
	NSEnumerator* extnEnum = [activeExtensions objectEnumerator];
	NSString* extn;
		
	while (extn = [extnEnum nextObject]) {
		NSString* extnPath = [self pathForExtension: extn];
		
		if (extnPath != nil) {
			[res addObject: extnPath];
		}
	}
				
	return res;
}

- (void) updateFromCompilerSettings {
	if (activeExtensions) [activeExtensions release];
	
	// Retrieve the list of active extensions from the dictionary
	activeExtensions = [[self dictionary] objectForKey: @"ActiveExtensions"];
	if (activeExtensions == nil) {
		activeExtensions = [[NSMutableSet alloc] init];
		[[self dictionary] setObject: [activeExtensions autorelease]
							  forKey: @"ActiveExtensions"];
	}
	[activeExtensions retain];
	
	needRefresh = YES;
	[extensionTable reloadData];
}

// = Table data source =

- (void) updateTable: (NSNotification*) not {
	needRefresh = YES;
	[extensionTable reloadData];
}

- (void) notifyThatExtensionsHaveChanged {
	[[NSNotificationCenter defaultCenter] postNotificationName: IFExtensionsChangedNotification
														object: self];
}

- (int)numberOfRowsInTableView: (NSTableView*) tableView {
	if (needRefresh) [self searchForExtensions];
	
	return [extensions count];
}

- (id)				tableView: (NSTableView*) tableView 
	objectValueForTableColumn: (NSTableColumn*) col
						  row: (int) row {
	if ([[col identifier] isEqualToString: @"libname"]) {
		return [extensions objectAtIndex: row];
	} else if ([[col identifier] isEqualToString: @"libactive"]) {
		return [NSNumber numberWithBool: [activeExtensions containsObject: [extensions objectAtIndex: row]]];
	} else {
		return @"UNKNOWN COLUMN";
	}
}

- (void)	tableView: (NSTableView*) aTableView 
	   setObjectValue: (id) anObject 
	   forTableColumn: (NSTableColumn*) col
				  row: (int) rowIndex {
	if ([[col identifier] isEqualToString: @"libname"]) {
		// Do nothing: can't set this
	} else if ([[col identifier] isEqualToString: @"libactive"]) {
		NSString* libname = [extensions objectAtIndex: rowIndex];
		
		if ([anObject boolValue]) {
			[activeExtensions addObject: libname];
		} else {
			[activeExtensions removeObject: libname];
		}
		
		[self settingsHaveChanged: aTableView];
	} else {
		// Nothing to do
	}
}

// = Dragging and dropping files to the table view =

- (BOOL) canAcceptFile: (NSString*) filename {
	BOOL exists, isDir;
	
	exists = [[NSFileManager defaultManager] fileExistsAtPath: filename
												  isDirectory: &isDir];
	
	if (!exists) return NO;				// Can't accept a non-existant file
	if (exists && isDir) return YES;	// We can always accept directories (though they may not be actual extensions, of course)
	
	// We can accept .h or .inf files as well
	NSString* extension = [filename pathExtension];
	extension = [extension lowercaseString];
	
	if ([extension isEqualToString: @"h"] ||
		[extension isEqualToString: @"inf"]) {
		return YES;
	}
	
	return NO;
}

- (BOOL) canAcceptPasteboard: (NSPasteboard*) pasteboard {
	NSArray* pbFiles = [pasteboard propertyListForType: NSFilenamesPboardType];
	
	if (pbFiles == nil || ![pbFiles isKindOfClass: [NSArray class]]) {
		return NO;
	}
	
	// We can accept directories, .inf or .h files for addition as extensions
	NSEnumerator* fileEnum = [pbFiles objectEnumerator];
	NSString* filename;
	
	while (filename = [fileEnum nextObject]) {
		if (![self canAcceptFile: filename]) {
			return NO;
		}
	}
	
	return YES;
}

- (NSDragOperation) tableView: (NSTableView *)tableView 
				 validateDrop: (id <NSDraggingInfo>)info 
				  proposedRow: (int)row 
		proposedDropOperation: (NSTableViewDropOperation)operation {
	if (![self canAcceptPasteboard: [info draggingPasteboard]]) {
		// Can't accept this
		return NSDragOperationNone;
	}
	
	return NSDragOperationCopy;
}

- (NSString*) directoryNameForExtension: (NSString*) extn {
	NSString* coreName = [[extn stringByDeletingPathExtension] lastPathComponent];
	NSString* realName = coreName;

	int count = 1;
	
	// Update the list of extensions
	needRefresh = YES;
	[self searchForExtensions];
	
	// Create a unique name based on the extensions that exist
	do {
		NSEnumerator* extnEnum = [extensions objectEnumerator];
		NSString* oldExtn;
		NSString* lowName = [realName lowercaseString];
		BOOL exists = NO;
		
		while (oldExtn = [extnEnum nextObject]) {
			if ([[oldExtn lowercaseString] isEqualToString: lowName]) {
				exists = YES;
				break;
			}
		}
		
		if (!exists) break; // Finished
		
		// Otherwise, next name
		count++;
		realName = [coreName stringByAppendingFormat: @" %i", count];
	} while (1);
	
	return realName;
}

- (BOOL) importExtensionFile: (NSString*) file {
	file = [file stringByStandardizingPath];
	if (!file) return NO;
	
	// Create the user library directory if required
	NSArray* libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString* userDirectory = [[libraries objectAtIndex: 0] stringByAppendingPathComponent: @"Inform"];
	BOOL exists, isDir;
	
	userDirectory = [userDirectory stringByStandardizingPath];
	if (!userDirectory) return NO;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath: userDirectory]) {
		[[NSFileManager defaultManager] createDirectoryAtPath: userDirectory
												   attributes: nil];
	}
	
	exists = [[NSFileManager defaultManager] fileExistsAtPath: userDirectory
												  isDirectory: &isDir];
	if (!exists || !isDir) {
		NSLog(@"%@ is not a directory", userDirectory);
		return NO;
	}
	
	userDirectory = [userDirectory stringByAppendingPathComponent: [self extensionSubdirectory]];
	userDirectory = [userDirectory stringByStandardizingPath];
	
	if (!userDirectory) return NO;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath: userDirectory]) {
		[[NSFileManager defaultManager] createDirectoryAtPath: userDirectory
												   attributes: nil];
	}
	
	exists = [[NSFileManager defaultManager] fileExistsAtPath: userDirectory
												  isDirectory: &isDir];
	if (!exists || !isDir) {
		NSLog(@"%@ is not a directory", userDirectory);
		return NO;
	}
		
	// Refuse to install if the extension already exists as part of the user directory
	NSString* lowerFile = [file lowercaseString];
	NSString* lowerDir = [userDirectory lowercaseString];
	
	if ([lowerFile length] >= [lowerDir length] &&
		[[lowerFile substringToIndex: [lowerDir length]] isEqualToString: lowerDir]) {
		// Files are the same
		NSLog(@"Extensions %@ already appears to be installed", file);
		return NO;
	}
	
	// Install the extension in the appropriate directory
	// Directories are copied as-is
	// Files have a directory created and are then copied
	NSString* extnName = [self directoryNameForExtension: file];
	
	exists = [[NSFileManager defaultManager] fileExistsAtPath: file
												  isDirectory: &isDir];
	
	if (!exists) {
		NSLog(@"Oops: %@ disappeared", file);
		return NO;
	}
	
	NSString* finalPath = [userDirectory stringByAppendingPathComponent: extnName];
	
	if (isDir) {
		// Just copy the directory
		[[NSFileManager defaultManager] copyPath: file
										  toPath: finalPath
										 handler: nil];
	} else {
		// Create the directory, then copy the file
		[[NSFileManager defaultManager] createDirectoryAtPath: finalPath
												   attributes: nil];
		
		[[NSFileManager defaultManager] copyPath: file
										  toPath: [finalPath stringByAppendingPathComponent: [file lastPathComponent]]
										 handler: nil];
	}
	
	[[NSWorkspace sharedWorkspace] noteFileSystemChanged: file];
	
	return YES;
}

- (BOOL) tableView: (NSTableView *) tableView 
		acceptDrop: (id <NSDraggingInfo>) info
			   row: (int) row 
	 dropOperation: (NSTableViewDropOperation) operation {
	NSPasteboard* pasteboard = [info draggingPasteboard];
	
	// Verify that we can indeed accept this pasteboard
	if (![self canAcceptPasteboard: pasteboard]) {
		return NO;
	}
	
	NSArray* pbFiles = [pasteboard propertyListForType: NSFilenamesPboardType];
	if (pbFiles == nil || ![pbFiles isKindOfClass: [NSArray class]]) {
		return NO;
	}
		
	// Copy the files into the user directory
	NSEnumerator* fileEnum = [pbFiles objectEnumerator];
	NSString* file;
	
	while (file = [fileEnum nextObject]) {
		[self importExtensionFile: file];
	}
	
	// Update the tables
	[self notifyThatExtensionsHaveChanged];

	return YES;
}

// Actions

- (IBAction) addExtension: (id) sender {
	// Present a panel for adding new extensions
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	
	[panel setAccessoryView: nil];
	[panel setCanChooseFiles: YES];
	[panel setCanChooseDirectories: YES];
	[panel setResolvesAliases: YES];
	[panel setAllowsMultipleSelection: YES];
	[panel setTitle: @"Add new extension"];
	[panel setDelegate: self];
	
	[panel beginSheetForDirectory: @"~"
							 file: nil
							types: [NSArray arrayWithObjects: @"inf", @"h", nil]
				   modalForWindow: [sender window]
					modalDelegate: self
				   didEndSelector: @selector(addExtensionPanelDidEnd:returnCode:contextInfo:)
					  contextInfo: nil];
}

- (IBAction) deleteExtension: (id) sender {
	if ([extensionTable numberOfSelectedRows] <= 0) return;
	
	// Display a confirm dialog
	NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: [extensionTable numberOfSelectedRows]>1?@"Can I Delete Extensions":@"Can I Delete Extension"
															 value: @"Are you sure?" 
															 table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"DoNotDeleteTheExtension"
															 value: @"Delete" 
															 table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"DeleteTheExtension"
															 value: @"Delete" 
															 table: nil],
					  nil,
					  [sender window],
					  self, @selector(deleteExtensionConfirmed:returnCode:contextInfo:),
					  nil, nil,
					  [[NSBundle mainBundle] localizedStringForKey: @"ExtensionDeletionMessage"
															 value: @"Noo, don't hurt the poor extensions!" 
															 table: nil]);
}

- (void) addExtensionPanelDidEnd: (NSOpenPanel*) sheet
					  returnCode: (int) returnCode
					 contextInfo: (void*) contextInfo {
	[sheet setDelegate: nil];
	
	if (returnCode != NSOKButton) return;
	
	// Add the files
	NSEnumerator* fileEnum = [[sheet filenames] objectEnumerator];
	NSString* file;
	
	while (file = [fileEnum nextObject]) {
		if ([self canAcceptFile: file]) {
			[self importExtensionFile: file];
		}
	}
	
	// Refresh everything
	[self notifyThatExtensionsHaveChanged];
}

- (BOOL)panel:(id)sender isValidFilename:(NSString *)filename {
	return [self canAcceptFile: filename];
}

- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename {
	return [self canAcceptFile: filename];
}

- (void) deleteExtensionConfirmed: (NSWindow*) sheet
					   returnCode: (int) returnCode
					  contextInfo: (void*) info {
	// The alternate button is the 'delete' button
	if (returnCode != NSAlertAlternateReturn) return;
	
	// Delete all extensions that are selected and in the user directory
	NSArray* libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString* userDirectory = [[libraries objectAtIndex: 0] stringByAppendingPathComponent: @"Inform"];
	
	userDirectory = [userDirectory stringByAppendingPathComponent: [self extensionSubdirectory]];
	userDirectory = [userDirectory stringByStandardizingPath];
	
	userDirectory = [userDirectory lowercaseString];
	
	NSEnumerator* rowEnum = [extensionTable selectedRowEnumerator];
	NSNumber* row;
	while (row = [rowEnum nextObject]) {
		NSString* extn = [extensions objectAtIndex: [row intValue]];
		NSString* extnPath = [extensionPath objectForKey: extn];
		
		extnPath = [extnPath stringByStandardizingPath];
		
		if (extn != nil && extnPath != nil) {
			// Must be in the user directory
			extnPath = [extnPath lowercaseString];
			
			if ([extnPath length] < [userDirectory length]) continue;
			if (![[extnPath substringToIndex: [userDirectory length]] isEqualToString: userDirectory]) continue;
			
			// OK, we can try to delete this directory - send it to the trash
			int tag;
			[[NSWorkspace sharedWorkspace] performFileOperation: NSWorkspaceRecycleOperation
														 source: [extnPath stringByDeletingLastPathComponent]
													destination: @""
														  files: [NSArray arrayWithObject: [extnPath lastPathComponent]]
															tag: &tag];
		}
	}
	
	// Notify of the changes
	[self notifyThatExtensionsHaveChanged];
}

@end
