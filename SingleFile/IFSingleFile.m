//
//  IFSingleFile.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 23/06/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFSingleFile.h"

#import "IFSyntaxStorage.h"
#import "IFNaturalHighlighter.h"
#import "IFInform6Highlighter.h"

@implementation IFSingleFile

- (NSString *)windowNibName {
    // Implement this to return a nib to load OR implement -makeWindowControllers to manually create your controllers.
    return @"SingleFile";
}

- (NSData *)dataRepresentationOfType: (NSString*) type {
    // Implement to provide a persistent data representation of your document OR remove this and implement the file-wrapper or file path based save methods.
    return nil;
}

- (BOOL)loadDataRepresentation: (NSData*) data
						ofType: (NSString*) type {
	NSObject<IFSyntaxHighlighter>* fileHighlighter = nil;
	
	// If the file is of a type that we know how to deal with, then use the appropriate highlighter
	
    return YES;
}

@end
