//
//  IFCompilerOptions.h
//  Inform
//
//  Created by Andrew Hunter on 10/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFSetting.h"

@interface IFCompilerOptions : IFSetting {
    IBOutlet NSPopUpButton* compilerVersion;
    IBOutlet NSButton* naturalInform;	
}

@end
