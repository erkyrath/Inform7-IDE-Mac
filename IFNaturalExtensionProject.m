//
//  IFNaturalExtensionProject.m
//  Inform
//
//  Created by Andrew Hunter on 18/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFNaturalExtensionProject.h"

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
		return [[NSBundle mainBundle] localizedStringForKey: @"ExtensionAlreadyExists"
													  value: @"Extension already exists" 
													  table: nil];
	}
	
	return nil;
}

- (NSString*) saveFilename {
	NSString* extnDir = [[[NSApp delegate] directoriesToSearch: @"Extensions"] objectAtIndex: 0];
	
	return [extnDir stringByAppendingPathComponent: [vw authorName]];
}

- (NSString*) openAsType {
	return @"Inform Extension Directory";
}

@end


@implementation IFNaturalExtensionView

- (NSView*) view {
	return view;
}

- (void) setupControls {
	NSString* longuserName = NSFullUserName();
	if ([longuserName length] == 0 || longuserName == nil) longuserName = NSUserName();
	if ([longuserName length] == 0 || longuserName == nil) longuserName = @"Unknown Author";

	[name setStringValue: longuserName];
}

- (NSString*) authorName {
	return [name stringValue];
}

@end
