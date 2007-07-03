//
//  IFContextMatchWindow.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 03/07/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

///
/// Popup window representing information on the item the user has indicated in the main window
///
@interface IFContextMatchWindow : NSWindowController {

}

// Controlling this window
- (void) popupAtLocation: (NSPoint) pointAt;

@end
