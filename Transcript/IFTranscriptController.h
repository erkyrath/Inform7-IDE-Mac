//
//  IFTranscriptController.h
//  Inform
//
//  Created by Andrew Hunter on 12/09/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <ZoomView/ZoomSkein.h>

#import "IFTranscriptStorage.h"

@interface IFTranscriptController : NSObject {
	IBOutlet NSTextView* transcriptTextView;
	
	IFTranscriptStorage* transcriptStorage;
	ZoomSkein* skein;
}

// Setting the skein
- (void)       setSkein: (ZoomSkein*) skein;
- (ZoomSkein*) skein;

- (void) transcriptToPoint: (ZoomSkeinItem*) point;
- (void) scrollToItem: (ZoomSkeinItem*) item;

// Updates
- (void) refreshTranscript;
- (void) updateSkeinItem: (ZoomSkeinItem*) item;

// Communications
- (void) setTranscriptTextView: (NSTextView*) textview;

- (void) setTranscriptStorage: (IFTranscriptStorage*) storage;
- (IFTranscriptStorage*) transcriptStorage;

@end
