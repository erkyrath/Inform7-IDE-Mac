//
//  IFProgress.m
//  Inform
//
//  Created by Andrew Hunter on 28/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFProgress.h"


@implementation IFProgress

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
		percentage = -1;
		message = nil;
		
		delegate = nil;
	}
	
	return self;
}

- (void) dealloc {
	if (message) [message release];
	
	[super dealloc];
}

// = Setting the current progress =

- (void) setPercentage: (float) newPercentage {
	percentage = newPercentage;
	
	if (delegate && [delegate respondsToSelector: @selector(progressIndicator:percentage:)]) {
		[delegate progressIndicator: self
						 percentage: newPercentage];
	}
}

- (void)	  setMessage: (NSString*) newMessage {
	if (message) [message release];
	message = [newMessage copy];
	
	if (delegate && [delegate respondsToSelector: @selector(progressIndicator:message:)]) {
		[delegate progressIndicator: self
							message: message];
	}
}

- (float) percentage {
	return percentage;
}

- (NSString*) message {
	return message;
}

// = Setting the delegate =

- (void) setDelegate: (id) newDelegate {
	delegate = newDelegate;
}

@end
