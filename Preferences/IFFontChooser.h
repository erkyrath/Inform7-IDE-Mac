//
//  IFFontChooser.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 07/01/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFFontTableSource.h"
#import "IFSyntaxStorage.h"


@interface IFFontChooser : NSWindowController {
	IBOutlet NSTableView* collections;					// Collections table view
	IBOutlet NSTableView* family;						// Family table view
	IBOutlet NSTextView* preview;						// The preview view
	
	IFFontTableSource* fontSource;						// Source for font information
	IFSyntaxStorage* previewStorage;					// Text storage object
}

- (IBAction) useFont: (id) sender;

@end
