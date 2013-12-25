//
//  IFTempObject.h
//  Inform
//
//  Created by Andrew Hunter on 09/03/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//
// Class used to manage a 'temporary' object (notifies the delegate when it and the object it contains
// is released)
//
@interface IFTempObject : NSObject {
	NSObject* object;										// The temporary object
	id delegate;											// The delegate
}

- (id) initWithObject: (NSObject*) tempObject				// Construct with a given object and delegate
			 delegate: (id) delegate;

@end

@interface NSObject(IFTempObjectDelegate)

- (void) tempObjectHasDeallocated: (NSObject*) tempObject;	// Called when the temp object should go away

@end
