//
//  IFStandardProject.h
//  Inform
//
//  Created by Andrew Hunter on Sat Sep 13 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFProjectType.h"


// Standard project interface
@interface IFStandardProject : NSObject<IFProjectType> {

}

@end

// The setup view for a standard project
@interface IFStandardProjectView : NSObject<IFProjectSetupView> {
    IBOutlet NSTextField* name;
    IBOutlet NSTextField* headline;
    IBOutlet NSTextView*  teaser;
    IBOutlet NSTextField* initialRoom;
    IBOutlet NSTextView*  initialRoomDescription;

    IBOutlet NSView*      view;
}

- (NSString*) name;
- (NSString*) headline;
- (NSString*) teaser;
- (NSString*) initialRoom;
- (NSString*) initialRoomDescription;

- (NSView*)   view;

@end
