//
//  IFTranscriptController.h
//  Inform
//
//  Created by Andrew Hunter on 12/09/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <ZoomView/ZoomSkein.h>

@interface IFTranscriptController : NSObject {

}

// Setting the skein
- (void)       setSkein: (ZoomSkein*) skein;
- (ZoomSkein*) skein;

// Updates
- (void) refreshTranscript;
- (void) updateSkeinItem: (ZoomSkeinItem*) item;


@end