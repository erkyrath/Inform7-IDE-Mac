//
//  IFSingleFile.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 23/06/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFSingleFile.h"


@implementation IFSingleFile

- (NSString *)windowNibName {
    // Implement this to return a nib to load OR implement -makeWindowControllers to manually create your controllers.
    return @"IFSingleFile";
}

- (NSData *)dataRepresentationOfType:(NSString *)type {
    // Implement to provide a persistent data representation of your document OR remove this and implement the file-wrapper or file path based save methods.
    return nil;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type {
    // Implement to load a persistent data representation of your document OR remove this and implement the file-wrapper or file path based load methods.
    return YES;
}

@end
