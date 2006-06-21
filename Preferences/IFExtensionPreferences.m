//
//  IFExtensionPreferences.m
//  Inform
//
//  Created by Andrew Hunter on 02/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFExtensionPreferences.h"

#import "IFExtensionsManager.h"
#import "IFMaintenanceTask.h"

@implementation IFExtensionPreferences

- (id) init {
	self = [super initWithNibName: @"ExtensionPreferences"];
	
	if (self) {
		// Set the data sources
		[naturalExtensionView setDataSource: [IFExtensionsManager sharedNaturalInformExtensionsManager]];
		[inform6ExtensionView setDataSource: [IFExtensionsManager sharedInform6ExtensionManager]];
		
		// Register for drag+drop
		[naturalExtensionView registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
		[inform6ExtensionView registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
		
		// Receive updates on the extensions
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(reloadExtensions:)
													 name: IFExtensionsUpdatedNotification
												   object: nil];
	}
	
	return self;
}

- (void) reloadExtensions: (NSNotification*) not {
	NSObject* obj = [not object];
	
	if (obj == [IFExtensionsManager sharedNaturalInformExtensionsManager]) {
		[naturalExtensionView reloadData];
	} else if (obj == [IFExtensionsManager sharedInform6ExtensionManager]) {
		[inform6ExtensionView reloadData];
	}
}

- (void) dealloc {
	// Will probably never be called
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[super dealloc];
}

// = PreferencePane overrides =

- (NSString*) preferenceName {
	return @"Extensions";
}

- (NSImage*) toolbarImage {
	return [NSImage imageNamed: @"Extensions"];
}

- (NSString*) tooltip {
	return [[NSBundle mainBundle] localizedStringForKey: @"Extensions preferences tooltip"
												  value: @"Extensions preferences tooltip"
												  table: nil];
}

// = Actions =

- (void) finishAddingExtensions: (NSArray*) filenames {
	// Add the files
	NSEnumerator* fileEnum = [filenames objectEnumerator];
	BOOL succeeded = YES;
	NSString* file;
	
	while (file = [fileEnum nextObject]) {
		succeeded = [[IFExtensionsManager sharedNaturalInformExtensionsManager] addExtension: file];
		if (!succeeded) break;
	}	
	
	// Re-run the maintenance tasks
	NSString* compilerPath = [[NSBundle mainBundle] pathForResource: @"ni"
															 ofType: @""
														inDirectory: @"Compilers"];
	if (compilerPath != nil) {
		[[IFMaintenanceTask sharedMaintenanceTask] queueTask: compilerPath
											   withArguments: [NSArray arrayWithObjects: 
												   @"-census",
												   @"-rules",
												   [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"Inform7"] stringByAppendingPathComponent: @"Extensions"],
												   nil]];
	}
	
	// Report an error if we couldn't install the extension for some reason
	if (!succeeded) {
		[[NSRunLoop currentRunLoop] performSelector: @selector(failedToAddExtension:)
											 target: self
										   argument: nil
											  order: 64
											  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
	}
}

- (void) addNaturalExtensionPanelDidEnd: (NSOpenPanel*) sheet
							 returnCode: (int) returnCode
							contextInfo: (void*) contextInfo {
	[sheet setDelegate: nil];
	
	if (returnCode != NSOKButton) return;
	
	// Check to see if any of the files exist
	NSEnumerator* fileEnum = [[sheet filenames] objectEnumerator];
	NSString* file;
	BOOL exists = NO;

	while (file = [fileEnum nextObject]) {
		NSString* title;
		NSString* author;
		
		author = [[IFExtensionsManager sharedNaturalInformExtensionsManager] authorForNaturalInformExtension: file
																									   title: &title];
		
		if (author != nil) {
			NSArray* authorFiles = [[IFExtensionsManager sharedNaturalInformExtensionsManager] filesInExtensionWithName: author];
			
			NSEnumerator* extnEnum = [authorFiles objectEnumerator];
			title = [title lowercaseString];
			NSString* extn;
			
			while (extn = [extnEnum nextObject]) {
				if ([[[extn lastPathComponent] lowercaseString] isEqualToString: title]) {
					exists = YES;
					break;
				}
			}
		}
		
		if (exists) break;
	}
	
	if (exists) {
		// Ask for confirmation
		[[NSRunLoop currentRunLoop] performSelector: @selector(confirmExtensionOverwrite:)
											 target: self
										   argument: [[[sheet filenames] copy] autorelease]
											  order: 64
											  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
	} else {
		// Just add the extension
		[self finishAddingExtensions: [sheet filenames]];
	}
}

- (void) confirmExtensionOverwrite: (id) filenames {
	// Display a 'failed to add extension' alert sheet
	NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"Overwrite Extension"
															 value: @"Overwrite Extension?"
															 table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"Cancel" value: @"Cancel" table: nil], 
					  [[NSBundle mainBundle] localizedStringForKey: @"Replace" value: @"Replace" table: nil], nil,
					  [[self preferenceView] window],
					  self, @selector(overwriteConfirmation:returnCode:contextInfo:),nil, [filenames retain],
					  [[NSBundle mainBundle] localizedStringForKey: @"Overwrite Extension Explanation"
															 value: nil
															 table: nil]);
}

- (void) overwriteConfirmation: (NSWindow *)sheet
					returnCode: (int) returnCode
				   contextInfo: (void*) filen {
	// User has clicked 'Replace' or 'Cancel' to the 'overwrite extensions' dialog
	NSArray* filenames = [(NSArray*)filen autorelease];
	
	if (returnCode == NSAlertAlternateReturn) {
		[self finishAddingExtensions: filenames];
	}
}

- (void) failedToAddExtension: (id) obj {
	// Display a 'failed to add extension' alert sheet
	NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"Failed to Install Extension"
															 value: @"Failed to Install Extension"
															 table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"Cancel" value: @"Cancel" table: nil], nil, nil,
					  [[self preferenceView] window],
					  nil,nil,nil,nil,
					  [[NSBundle mainBundle] localizedStringForKey: @"Failed to Install Extension Explanation"
															 value: nil
															 table: nil]);
}
	
- (IBAction) addNaturalExtension: (id) sender {
	// Present a panel for adding new extensions
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	
	[panel setAccessoryView: nil];
	[panel setCanChooseFiles: YES];
	[panel setCanChooseDirectories: NO];
	[panel setResolvesAliases: YES];
	[panel setAllowsMultipleSelection: NO];
	[panel setTitle: @"Add new Inform 7 Extension"];
	[panel setDelegate: [IFExtensionsManager sharedNaturalInformExtensionsManager]];
	
	[panel beginSheetForDirectory: @"~"
							 file: nil
							types: nil
				   modalForWindow: [sender window]
					modalDelegate: self
				   didEndSelector: @selector(addNaturalExtensionPanelDidEnd:returnCode:contextInfo:)
					  contextInfo: nil];
}

- (IBAction) deleteNaturalExtension: (id) sender {
	if ([preferenceView window] == nil) return;
	if ([[naturalExtensionView selectedRowEnumerator] nextObject] == nil) return;
	
	// Request confirmation
	NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"Can I Delete Extension"
															 value: @"Delete natural extension?"
															 table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"Cancel"
															 value: @"Cancel"
															 table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"Delete"
															 value: @"Delete"
															 table: nil],
					  nil,
					  [preferenceView window],
					  self, @selector(deleteNaturalConfirm:returnCode:contextInfo:), nil, nil,
					  [[NSBundle mainBundle] localizedStringForKey: @"ExtensionDeletionMessage"
															 value: @"Delete natural extension?"
															 table: nil]);
}

- (IBAction) addInform6Extension: (id) sender {
}

- (IBAction) deleteInform6Extension: (id) sender {
	if ([preferenceView window] == nil) return;
	if ([[inform6ExtensionView selectedRowEnumerator] nextObject] == nil) return;
	
	// Request confirmation
	NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"Can I Delete Extension"
															 value: @"Delete natural extension?"
															 table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"Cancel"
															 value: @"Cancel"
															 table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"Delete"
															 value: @"Delete"
															 table: nil],
					  nil,
					  [preferenceView window],
					  self, @selector(deleteInform6Confirm:returnCode:contextInfo:), nil, nil,
					  [[NSBundle mainBundle] localizedStringForKey: @"ExtensionDeletionMessage"
															 value: @"Delete natural extension?"
															 table: nil]);
}

- (void) failedToDeleteExtensions: (NSArray*) extns {
	// Called when some extensions fail to delete for some reason
	NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"FailedToDeleteExtension"
															 value: @"Failed to delete extension"
															 table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"Cancel"
															 value: @"Cancel"
															 table: nil],
					  nil,
					  nil,
					  [preferenceView window],
					  self, nil, nil, nil,
					  [[NSBundle mainBundle] localizedStringForKey: @"FailedToDeleteExtensionMessage"
															 value: @"The extension failed to delete for some reason"
															 table: nil]);
}

- (void) deleteInform6Confirm: (NSWindow*) sheet 
				   returnCode: (int) returnCode 
				  contextInfo: (void*) contextInfo {
	// User has clicked 'Delete' or 'Cancel' when asked if she wants to delete an Inform 6 extension
	if (returnCode == NSAlertAlternateReturn) {
		// Will contain the list of extensions we couldn't delete
		NSMutableArray* failedExtensions = [NSMutableArray array];
		
		// Loop through the selected items
		NSEnumerator* rowEnum = [inform6ExtensionView selectedRowEnumerator];
		NSNumber* row;
		while (row = [rowEnum nextObject]) {
			// Get the extension associated with this item
			NSString* extnName = [[IFExtensionsManager sharedInform6ExtensionManager] extensionForRow: [row intValue]];
			
			if (extnName != nil) {
				// Delete an extension
				if (![[IFExtensionsManager sharedInform6ExtensionManager] deleteExtension: extnName]) {
					[failedExtensions addObject: extnName];
				}			
			}
		}
		
		// If some or all of the extensions failed to delete, then queue an error message
		if ([failedExtensions count] > 0) {
			[[NSRunLoop currentRunLoop] performSelector: @selector(failedToDeleteExtensions:)
												 target: self
											   argument: failedExtensions
												  order: 256
												  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
		}
	}
}

- (void) deleteNaturalConfirm: (NSWindow*) sheet 
				   returnCode: (int) returnCode 
				  contextInfo: (void*) contextInfo {
	// User has clicked 'Delete' or 'Cancel' when asked if she wants to delete a Natural Inform extension
	if (returnCode == NSAlertAlternateReturn) {
		// Will contain the list of extensions we couldn't delete
		NSMutableArray* failedExtensions = [NSMutableArray array];
		
		// Loop through the selected items
		NSEnumerator* rowEnum = [naturalExtensionView selectedRowEnumerator];
		NSNumber* row;
		while (row = [rowEnum nextObject]) {
			// Get the item
			id item = [naturalExtensionView itemAtRow: [row intValue]];
			
			// Get the extension associated with this item
			NSString* extnName = nil;
			NSString* fileName = nil;
			
			[[IFExtensionsManager sharedNaturalInformExtensionsManager] retrieveDataForItem: item
																			  extensionName: &extnName
																				   fileName: &fileName];
			
			if (extnName != nil && fileName != nil) {
				// Delete a file
				if (![[IFExtensionsManager sharedNaturalInformExtensionsManager] deleteFile: fileName
																				inExtension: extnName]) {
					[failedExtensions addObject: [[extnName stringByAppendingString: @"/"] stringByAppendingString: fileName]];
				}
			} else if (extnName != nil) {
				// Delete an extension
				if (![[IFExtensionsManager sharedNaturalInformExtensionsManager] deleteExtension: extnName]) {
					[failedExtensions addObject: extnName];
				}			
			}
		}
		
		// If some or all of the extensions failed to delete, then queue an error message
		if ([failedExtensions count] > 0) {
			[[NSRunLoop currentRunLoop] performSelector: @selector(failedToDeleteExtensions:)
												 target: self
											   argument: failedExtensions
												  order: 256
												  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
		}
	}
}

@end
