//
//  IFFontTableSource.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 07/01/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IFFontTableSource : NSObject {
	NSString* collection;									// The collection that we should show in the font family list
	
	NSMutableArray* families;								// The list of font families for the current font
}

- (void) setCollection: (NSString*) collectionName;			// Choose the collection to filter byu

- (int) rowForCollection: (NSString*) collectionName;		// The row for a specific collection
- (int) rowForFamily: (NSString*) family;					// The row for the specified family

@end
