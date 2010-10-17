//
//  IFNaturalExtensionProject.m
//  Inform
//
//  Created by Andrew Hunter on 18/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFNaturalExtensionProject.h"
#import "IFSingleFile.h"
#import "IFExtensionsManager.h"
#import "IFPreferences.h"

#import "IFAppDelegate.h"

@implementation IFNaturalExtensionProject

- (void) dealloc {
	[vw release];
	
	[super dealloc];
}

- (NSString*)           projectName {
    return [[NSBundle mainBundle] localizedStringForKey: @"Natural Inform extension"
												  value: @"Extension"
												  table: nil];
}

- (NSString*)           projectHeading {
    return [[NSBundle mainBundle] localizedStringForKey: @"Natural Inform"
												  value: @"Natural Inform"
												  table: nil];
}

- (NSAttributedString*) projectDescription {
    return [[[NSAttributedString alloc] initWithString:
        [[NSBundle mainBundle] localizedStringForKey: @"Natural Inform extension description"
											   value: @"Creates a Natural Inform extension directory."
											   table: nil]] autorelease];
}

- (NSObject<IFProjectSetupView>*) configView {
	if (!vw) {
		vw = [[IFNaturalExtensionView alloc] init];
		[NSBundle loadNibNamed: @"NaturalExtensionOptions"
						 owner: vw];
	}
	
	[vw setupControls];

	return vw;
}

- (void) setupFile: (IFProjectFile*) file
          fromView: (NSObject<IFProjectSetupView>*) view {
}

- (BOOL) showFinalPage {
	return NO;
}

- (NSString*) errorMessage {
	if (![vw authorName] || [[vw authorName] isEqualToString: @""]) {
		return [[NSBundle mainBundle] localizedStringForKey: @"BadExtensionAuthor"
													  value: @"Bad extension author" 
													  table: nil];
	}
	
	return nil;
}

- (NSString*) confirmationMessage {
	if ([[NSFileManager defaultManager] fileExistsAtPath: [self saveFilename]]) {
		return [[NSBundle mainBundle] localizedStringForKey: @"Extension already exists"
													  value: @"Extension already exists" 
													  table: nil];
	}
	
	return nil;
}

- (NSString*) saveFilename {
	NSString* extnDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
	
	extnDir = [[extnDir stringByAppendingPathComponent: @"Inform"] stringByAppendingPathComponent: @"Extensions"];
	
	return [[extnDir stringByAppendingPathComponent: [vw authorName]] stringByAppendingPathComponent: [[vw extensionName] stringByAppendingPathExtension: @"i7x"]];
}

- (NSString*) openAsType {
	return @"Inform Extension Directory";
}

- (void) createDeepDirectory: (NSString*) deepDirectory {
	// Creates a directory and any parent directories as required
	if (deepDirectory == nil || [deepDirectory length] < 2) return;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath: [deepDirectory stringByDeletingLastPathComponent]]) {
		[self createDeepDirectory: [deepDirectory stringByDeletingLastPathComponent]];
	}
	
	if (![[NSFileManager defaultManager] fileExistsAtPath: deepDirectory]) {
		[[NSFileManager defaultManager] createDirectoryAtPath: deepDirectory
												   attributes: nil];
	}
}

- (BOOL) createAndOpenDocument: (NSString*) filename {
	NSString* contents = [NSString stringWithFormat: @"%@ by %@ begins here.\n\n%@ ends here.\n", [vw extensionName], [vw authorName], [vw extensionName]];
	NSDictionary* fileAttr = [NSDictionary dictionaryWithObjectsAndKeys: 
		[NSNumber numberWithUnsignedLong: 'INfm'], NSFileHFSCreatorCode,
		[NSNumber numberWithUnsignedLong: 'INex'], NSFileHFSTypeCode,
		nil];
	
	NSData* contentData = [contents dataUsingEncoding: NSUTF8StringEncoding];
	
	// Try to create the extension directory, if necessary
	if (![[NSFileManager defaultManager] fileExistsAtPath: [filename stringByDeletingLastPathComponent]]) {
		[self createDeepDirectory: [filename stringByDeletingLastPathComponent]];
	}
	
	// Try to create the file
	if (![[NSFileManager defaultManager] createFileAtPath: filename
												 contents: contentData
											   attributes: fileAttr]) {
		return NO;
	}
	
	// Open the file
	NSDocument* newDoc = [[IFSingleFile alloc] initWithContentsOfFile: filename
															   ofType: @"Inform 7 extension"];
	
	[[NSDocumentController sharedDocumentController] addDocument: [newDoc autorelease]];
	[newDoc makeWindowControllers];
	[newDoc showWindows];	
	
	// Get the delegate to update the list of extensions
	[[IFExtensionsManager sharedNaturalInformExtensionsManager] updateTableData];
	[[NSApp delegate] updateExtensions];
	
	return YES;
}

@end


@implementation IFNaturalExtensionView

- (NSView*) view {
	return view;
}

- (void) setupControls {
	NSString* longuserName = [[IFPreferences sharedPreferences] newGameAuthorName];

	// If longuserName contains a '.', then we have to enclose it in quotes
	BOOL needQuotes = NO;
	int x;
	for (x=0; x<[longuserName length]; x++) {
		if ([longuserName characterAtIndex: x] == '.') needQuotes = YES;
	}
	
	if (needQuotes) longuserName = [NSString stringWithFormat: @"\"%@\"", longuserName];
	
	[name setStringValue: longuserName];
	[extensionName setStringValue: [[NSBundle mainBundle] localizedStringForKey: @"New Extension"
																		  value: @"New Extension"
																		  table: nil]];
}

- (NSString*) authorName {
	return [name stringValue];
}

- (NSString*) extensionName {
	return [extensionName stringValue];
}

@end
