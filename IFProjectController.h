//
//  IFProjectController.h
//  Inform
//
//  Created by Andrew Hunter on Wed Aug 27 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <ZoomView/ZoomView.h>

enum lineStyle {
    IFLineStyleNeutral,
    
    IFLineStyleWarning,
    IFLineStyleError,
    IFLineStyleFatalError,

    // For later
    IFLineStyleBreakpoint,
    IFLineStyleExecutionPoint
};

@interface IFProjectController : NSWindowController {
    IBOutlet NSView* panesView;
    
    // The toolbar
    NSToolbar* toolbar;

    // The collection of panes
    NSMutableArray* projectPanes;
    NSMutableArray* splitViews;

    // Action after a compile has finished
    SEL compileFinishedAction;
}

- (void) layoutPanes;

// Communication from the containing panes (maybe other uses, too - scripting?)
- (BOOL) selectSourceFile: (NSString*) fileName;
- (void) moveToSourceFileLine: (int) line;
- (void) highlightSourceFileLine: (int) line;
- (void) highlightSourceFileLine: (int) line
                           style: (enum lineStyle) style;

@end
