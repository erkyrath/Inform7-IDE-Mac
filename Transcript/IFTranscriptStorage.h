//
//  IFTranscriptStorage.h
//  Inform
//
//  Created by Andrew Hunter on 19/09/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <ZoomView/ZoomSkeinItem.h>

@interface IFTranscriptStorage : NSTextStorage {
	NSMutableArray* transcriptItems;
	NSMutableArray* itemPositionData;
	ZoomSkeinItem*  finalItem;
}

// Setting up what to display/edit
- (void) setTranscriptToPoint: (ZoomSkeinItem*) finalItem;

@end
