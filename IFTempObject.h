//
//  IFTempObject.h
//  Inform
//
//  Created by Andrew Hunter on 09/03/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//
// Class used to manage a 'temporary' object (notifies the delegate when it and the object it contains is released)
//
@interface IFTempObject : NSObject {
	NSObject* object;
	id delegate;
}

- (id) initWithObject: (NSObject*) tempObject
			 delegate: (id) delegate;

@end

@interface NSObject(IFTempObjectDelegate)

- (void) tempObjectHasDeallocated: (NSObject*) tempObject;

@end
