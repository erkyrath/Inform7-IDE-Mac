//
//  IFTranscriptString.h
//  Inform
//
//  Created by Andrew Hunter on 07/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFTranscriptStorage.h"

@interface IFTranscriptString : NSString {
	IFTranscriptStorage* storage;
}

// (Generally only created by the transcript object itself.)
- (id) initWithTranscriptStorage: (IFTranscriptStorage*) storage;

@end
