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
		needRefresh = YES;
		extnMgr = [[IFExtensionsManager sharedInform6ExtensionManager] retain];
		
		activeExtensions = nil;
		
		[extensionTable registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(updateTable:)
													 name: IFExtensionsUpdatedNotification
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

	[extnMgr release];
	
	[activeExtensions release];
	
	[super dealloc];
}

// = Compiler settings  =

- (NSArray*) includePathForCompiler: (NSString*) compiler {
	if (![compiler isEqualToString: IFCompilerInform6]) return nil;
	
	NSMutableArray* res = [NSMutableArray array];
	
	NSEnumerator* extnEnum = [activeExtensions objectEnumerator];
	NSString* extn;
		
	while (extn = [extnEnum nextObject]) {
		NSString* extnPath = [extnMgr pathForExtensionWithName: extn];
		
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
	if (activeExtensions == nil || ![activeExtensions isKindOfClass: [NSMutableSet class]]) {
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

- (int)numberOfRowsInTableView: (NSTableView*) tableView {
	return [extnMgr numberOfRowsInTableView: tableView];
}

- (id)				tableView: (NSTableView*) tableView 
	objectValueForTableColumn: (NSTableColumn*) col
						  row: (int) row {
	if ([[col identifier] isEqualToString: @"extension"]) {
		return [extnMgr tableView: tableView
			objectValueForTableColumn: col
								  row: row];
	} else if ([[col identifier] isEqualToString: @"libactive"]) {
		return [NSNumber numberWithBool: [activeExtensions containsObject: [extnMgr extensionForRow: row]]];
	} else {
		return @"UNKNOWN COLUMN";
	}
}

- (void)	tableView: (NSTableView*) aTableView 
	   setObjectValue: (id) anObject 
	   forTableColumn: (NSTableColumn*) col
				  row: (int) rowIndex {
	if ([[col identifier] isEqualToString: @"extension"]) {
		// Do nothing: can't set this
	} else if ([[col identifier] isEqualToString: @"libactive"]) {
		NSString* libname = [extnMgr extensionForRow: rowIndex];
		
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

#if 0
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
#endif

- (BOOL) importExtensionFile: (NSString*) file {
	return [extnMgr addExtension: file];
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

	return YES;
}

// = Actions =

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
	
	userDirectory = [userDirectory stringByAppendingPathComponent: [extnMgr subdirectory]];
	userDirectory = [userDirectory stringByStandardizingPath];
	
	userDirectory = [userDirectory lowercaseString];
	
	NSEnumerator* rowEnum = [extensionTable selectedRowEnumerator];
	NSNumber* row;
	while (row = [rowEnum nextObject]) {
		NSString* extn = [extnMgr extensionForRow: [row intValue]];
		
		[extnMgr deleteExtension: extn];
	}
}

// = PList =

- (NSDictionary*) plistEntries {
	// Need to turn our set into a dictionary
	NSMutableDictionary* res = [NSMutableDictionary dictionary];
	NSEnumerator* extnEnum = [[extnMgr availableExtensions] objectEnumerator];
	NSString* extn;
	NSNumber* trueValue = [NSNumber numberWithBool: YES];
	NSNumber* falseValue = [NSNumber numberWithBool: NO];
	
	while (extn = [extnEnum nextObject]) {
		[res setObject: [activeExtensions containsObject: extn]?trueValue:falseValue
				forKey: extn];
	}
	
	return res;
}

- (void) updateSettings: (IFCompilerSettings*) settings
	   withPlistEntries: (NSDictionary*) entries {
	// Get the active extensions, if we don't already know about them
	if (!activeExtensions) {
		[self updateFromCompilerSettings];
		
		if (!activeExtensions) {
			activeExtensions = [[settings dictionaryForClass: [self class]] objectForKey: @"ActiveExtensions"];
			if (activeExtensions == nil) {
				activeExtensions = [[NSMutableSet alloc] init];
				[[settings dictionaryForClass: [self class]] setObject: [activeExtensions autorelease]
									  forKey: @"ActiveExtensions"];
			}
			[activeExtensions retain];
		}
	}
	
	// Clear out the active extensions
	[activeExtensions removeAllObjects];
	
	// Add everything that's set to true in the dictionary to the active extensions list
	NSEnumerator* keyEnum = [entries keyEnumerator];
	NSString* key;
	
	while (key = [keyEnum nextObject]) {
		if (![[entries objectForKey: key] isKindOfClass: [NSNumber class]]) {
			continue;
		}
		
		BOOL keyValue = [[entries objectForKey: key] boolValue];
		
		if (keyValue) {
			[activeExtensions addObject: key];
		}
	}
	
	// Notify that something has changed
	[self updateFromCompilerSettings];
	
	needRefresh = YES;
	[extensionTable reloadData];
}

- (BOOL) enableForCompiler: (NSString*) compiler {
	// These settings are unsafe to change while using Natural Inform
	if ([compiler isEqualToString: IFCompilerNaturalInform])
		return NO;
	else
		return YES;
}

@end
