//
//  IFCompilerController.h
//  Inform
//
//  Created by Andrew Hunter on Mon Aug 18 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>

#import "IFCompiler.h"
#import "IFError.h"

// Possible styles (stored in the styles dictionary)
extern NSString* IFStyleBase;

// Basic compiler messages
extern NSString* IFStyleCompilerVersion;
extern NSString* IFStyleCompilerMessage;
extern NSString* IFStyleCompilerWarning;
extern NSString* IFStyleCompilerError;
extern NSString* IFStyleCompilerFatalError;

extern NSString* IFStyleFilename;

// Compiler statistics/dumps/etc
extern NSString* IFStyleAssembly;
extern NSString* IFStyleHexDump;
extern NSString* IFStyleStatistics;

@interface IFCompilerController : NSObject {
    BOOL awake;
    
    IBOutlet NSTextView* compilerResults;
    IBOutlet NSScrollView* resultScroller;

    IBOutlet NSSplitView*   splitView;
    IBOutlet NSScrollView*  messageScroller;
    IBOutlet NSOutlineView* compilerMessages;

    IBOutlet NSWindow*      window;

    double messagesSize;

    IBOutlet NSObject* delegate;

    // File tabView
    NSTabView*     fileTabView;
    NSTabViewItem* splitTab;
    
    // The subtask
    IFCompiler* compiler;

    // Styles
    NSMutableDictionary* styles;
    int highlightPos;

    // Error messages
    NSMutableArray* errorFiles;
    NSMutableArray* errorMessages;
}

+ (NSDictionary*) defaultStyles;

- (void)        resetCompiler;
- (void)        setCompiler: (IFCompiler*) compiler;
- (IFCompiler*) compiler;

- (BOOL) startCompiling;
- (BOOL) abortCompiling;

- (void) addErrorForFile: (NSString*) file
                  atLine: (int) line
                withType: (IFLex) type
                 message: (NSString*) message;

- (void) showWindow: (id) sender;

- (void) setDelegate: (NSObject*) delegate;
- (NSObject*) delegate;

- (void) showContentsOfFilesIn: (NSFileWrapper*) files;
- (void) clearTabViews;

@end

// Delegate methods
@interface NSObject(NSCompilerControllerDelegate)

// Status updates
- (void) compileStarted: (IFCompilerController*) sender;
- (void) compileCompletedAndSucceeded: (IFCompilerController*) sender;
- (void) compileCompletedAndFailed: (IFCompilerController*) sender;

// User interface notification
- (void) errorMessagesCleared: (IFCompilerController*) sender;
- (void) errorMessageHighlighted: (IFCompilerController*) sender
                          atLine: (int) line
                          inFile: (NSString*) file;
- (void) compilerAddError: (IFCompilerController*) sender
                  forFile: (NSString*) file
                   atLine: (int) line
                 withType: (IFLex) type
                  message: (NSString*) message;

@end

