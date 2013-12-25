//
//  IFNaturalExtensions.m
//  Inform
//
//  Created by Andrew Hunter on 24/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFNaturalExtensions.h"


@implementation IFNaturalExtensions

// = Initialisation =

- (id) init {
	self = [self initWithNibName: @"NaturalInformExtensions"];
	
	if (self) {
		[extnMgr release];
		extnMgr = [[IFExtensionsManager sharedNaturalInformExtensionsManager] retain];

		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(updateOutline:)
													 name: IFExtensionsUpdatedNotification
												   object: nil];
		
		[extnOutline setDataSource: extnMgr];
		[extnOutline registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
	}
	
	return self;
}

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Natural Inform Extensions"
												  value: @"Natural Inform Extensions"
												  table: nil];
}

- (void) updateOutline: (NSNotification*) not {
	[extnOutline reloadData];
}

// = Compiler settings  =

- (NSArray*) includePathForCompiler: (NSString*) compiler {
	return nil; // We never affect the include path
}

// = What we consider a valid extension =

- (BOOL) canAcceptFile: (NSString*) filename {
	// (Directories only)
	BOOL exists, isDir;
	
	exists = [[NSFileManager defaultManager] fileExistsAtPath: filename
												  isDirectory: &isDir];
	
	if (!exists) return NO;				// Can't accept a non-existant file
	if (exists && isDir) return YES;	// We can always accept directories (though they may not be actual extensions, of course)

	return NO;
}

// = Deleting =

- (IBAction) deleteExtension: (id) sender {
	if ([extnOutline numberOfSelectedRows] <= 0) return;
	
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
	
	NSEnumerator* rowEnum = [extnOutline selectedRowEnumerator];
	NSNumber* row;
	while (row = [rowEnum nextObject]) {
		id item = [extnOutline itemAtRow: [row intValue]];
		
		NSString* extn = nil;
		NSString* extnFile = nil;
		
		[extnMgr retrieveDataForItem: item
					   extensionName: &extn
							fileName: &extnFile];
		
		if (extn && extnFile) {
			[extnMgr deleteFile: extnFile
					inExtension: extn];
		} else if (extn) {
			[extnMgr deleteExtension: extn];
		}
	}
}

// = Plist entries =

- (NSDictionary*) plistEntries {
	// (None for this class at the moment)
	return [NSDictionary dictionary];
}

@end
