//
//  IFTranscriptStorage.h
//  Inform
//
//  Created by Andrew Hunter on 19/09/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <ZoomView/ZoomSkeinItem.h>

@class IFTranscriptString;
@interface IFTranscriptStorage : NSTextStorage {
	NSMutableArray* transcriptItems;
	NSMutableArray* itemPositionData;
	ZoomSkeinItem*  finalItem;
	
	IFTranscriptString* string;
}

// Setting up what to display/edit
- (void) setTranscriptToPoint: (ZoomSkeinItem*) finalItem;

// Mainly used when communicating with an IFTranscriptString
- (NSArray*) itemPositionData;
- (NSArray*) transcriptItems;
- (unsigned) indexOfItemAtCharacterPosition: (unsigned) pos;

@end

#import "IFTranscriptString.h"
