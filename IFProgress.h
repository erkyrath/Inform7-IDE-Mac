//
//  IFProgress.h
//  Inform
//
//  Created by Andrew Hunter on 28/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


//
// A progress indicator object
//
@interface IFProgress : NSObject {
	float percentage;
	NSString* message;
	
	id delegate;
}

// Setting the current progress
- (void)	  setPercentage: (float) newPercentage;
- (void)	  setMessage: (NSString*) newMessage;
- (float)	  percentage;
- (NSString*) message;

// Setting the delegate
- (void) setDelegate: (id) delegate;

@end

//
// Progress indicator delegate methods
//
@interface NSObject(IFProgressDelegate)

- (void) progressIndicator: (IFProgress*) indicator
				percentage: (float) newPercentage;
- (void) progressIndicator: (IFProgress*) indicator
				   message: (NSString*) newMessage;

@end
