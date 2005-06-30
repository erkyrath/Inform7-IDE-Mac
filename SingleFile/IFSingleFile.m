//
//  IFSingleFile.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 23/06/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFSingleFile.h"
#import "IFSingleController.h"

#import "IFSyntaxStorage.h"
#import "IFNaturalHighlighter.h"
#import "IFInform6Highlighter.h"

@implementation IFSingleFile

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
		fileStorage = [[IFSyntaxStorage alloc] init];
		fileEncoding = NSUTF8StringEncoding;
	}
	
	return self;
}

- (void) dealloc {
	[fileStorage release]; fileStorage = nil;
	
	[super dealloc];
}

// = Data =

- (void)makeWindowControllers {
    IFSingleController *aController = [[IFSingleController allocWithZone:[self zone]] init];
    [self addWindowController:aController];
    [aController release];
}

- (NSData *)dataRepresentationOfType: (NSString*) type {
    return [[fileStorage string] dataUsingEncoding: fileEncoding];
}

- (BOOL)loadDataRepresentation: (NSData*) data
						ofType: (NSString*) type {
	NSObject<IFSyntaxHighlighter>* fileHighlighter = nil;		// The highlighter we'll eventually use
	fileEncoding = NSUTF8StringEncoding;						// The encoding the file is probably in
	
	// If the file is of a type that we know how to deal with, then use the appropriate highlighter
	type = [type lowercaseString];
	if ([type isEqualToString: @"inform control language file"]) {
		// No highlighter currently available for ICL files, and they're latin-1
		fileEncoding = NSISOLatin1StringEncoding;
	} else if ([type isEqualToString: @"inform 6 source file"]) {
		fileEncoding = NSISOLatin1StringEncoding;
		fileHighlighter = [[IFInform6Highlighter alloc] init];
	} else if ([type isEqualToString: @"natural inform source file"] || [type isEqualToString: @"inform 7 extension"]) {
		fileHighlighter = [[IFNaturalHighlighter alloc] init];
	}
	
	[fileHighlighter autorelease];
	
	// Create the file data
	NSString* fileString = [[NSString alloc] initWithData: data
												 encoding: fileEncoding];
	if (fileString == nil) {
		fileEncoding = NSISOLatin1StringEncoding;
		fileString = [[NSString alloc] initWithData: data
										   encoding: fileEncoding];
	}
	
	if (fileString == nil) {
		NSLog(@"Error: failed to load file: could not find an acceptable character encoding");
		return NO;
	}
	
	[fileStorage release]; fileStorage = nil;
	fileStorage = [[IFSyntaxStorage alloc] initWithString: [fileString autorelease]];
	if (fileHighlighter) [fileStorage setHighlighter: fileHighlighter];
	
    return YES;
}

// = Retrieving document data =

- (IFSyntaxStorage*) storage {
	return fileStorage;
}

@end
