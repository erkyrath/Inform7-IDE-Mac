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
extern NSString* IFStyleProgress;

extern NSString* IFStyleFilename;

// Compiler statistics/dumps/etc
extern NSString* IFStyleAssembly;
extern NSString* IFStyleHexDump;
extern NSString* IFStyleStatistics;

//
// The compiler controller handles the interface between the compiler and the UI
//
// (In ye olden dayes, this was a window controller as well, but now young whippersnapper
// compilers can go anywhere, so it's not any more)
//
@interface IFCompilerController : NSObject {
    BOOL awake;										// YES if we're all initialised (ie, loaded up from a nib)
    
    IBOutlet NSTextView* compilerResults;			// Output from the compiler ends up here
    IBOutlet NSScrollView* resultScroller;			// ...and is scrolled around by this thingmebob

    IBOutlet NSSplitView*   splitView;				// Yin/yang?
    IBOutlet NSScrollView*  messageScroller;		// This scrolls around our parsed messages
    IBOutlet NSOutlineView* compilerMessages;		// ...and this actually displays them

    IBOutlet NSWindow*      window;					// We're attached to this window

    double messagesSize;							// When we've got some messages to display, this is how high the pane will be

    IBOutlet NSObject* delegate;					// This object receives our delegate messages

	// File views
	NSMutableArray* auxViews;						// The list of views supplied by this object (NI can produce some extra HTML results: this is where we display them)
	NSMutableArray* viewNames;						// The list of names for the auxiliary views
	int splitViewIndex;								// The index of the split view in the list of aux views (= 0 always at the moment)
	int runtimeView;								// The index of the runtime error view
	int selectedView;								// The index of the currently selected view
	
	NSView* activeView;								// The currently active view
    
    // The subtask
    IFCompiler* compiler;							// This is the actual compiler
	NSURL* lastProblemURL;							// The last problem URL returned by the compiler
	NSURL* overrideURL;								// The overridden problems URL

    // Styles
    NSMutableDictionary* styles;					// The attributes used to render various strings recognised by the parser
    int highlightPos;								// The position the highlighter has reached (see IFError.[hl])

    // Error messages
    NSMutableArray* errorFiles;						// A list of the files that the compiler has reported errors on (this is how we group errors together by file)
    NSMutableArray* errorMessages;					// A list of the error messages that the compiler has reported
	NSString* blorbLocation;						// Where cblorb has requested that the blorb file be copied
}

+ (NSDictionary*) defaultStyles;						// The default styles for the error messages

- (void)        resetCompiler;							// Destroys + recreates the compiler (ie, resets it back to its initial state)
- (void)        setCompiler: (IFCompiler*) compiler;	// Sets a specific compiler object to use
- (IFCompiler*) compiler;								// Retrieves the current compiler object

- (BOOL) startCompiling;								// Tells the compiler to start
- (BOOL) abortCompiling;								// Tells the compiler to stop

- (void) addErrorForFile: (NSString*) file				// Adds an error to the display
                  atLine: (int) line
                withType: (IFLex) type
                 message: (NSString*) message;

- (void) showWindow: (id) sender;						// Displays the window thats displaying the compiler messages

- (void) setDelegate: (NSObject*) delegate;				// Sets the delegate object
- (NSObject*) delegate;									// Retrieves the delegate object

- (void) overrideProblemsURL: (NSURL*) problemsURL;		// No matter the exit/RTP supplied by the compiler, use this problems URL instead
- (void) showRuntimeError: (NSURL*) errorURL;			// Creates a tab for the 'runtime error' file given by errorURL (displayed by webkit)
- (void) showContentsOfFilesIn: (NSFileWrapper*) files	// Creates tabs for the files contained in the given filewrapper (which came from the given path)
					  fromPath: (NSString*) path;
- (void) clearTabViews;									// Gets rid of the file tabs created by the previous function

- (NSString*) blorbLocation;							// Where cblorb thinks the final blorb file should be copied to

- (void) setSplitView: (NSSplitView*) newSplitView;		// Sets the splitter view for this object
- (NSSplitView*) splitView;								// Gets the splitter view for this object

- (int) viewIndex;										// The index of the currently selected view
- (void) switchToViewWithIndex: (int) index;			// Switches to a view with the specified index
- (void) switchToSplitView;								// Switches to the default split view
- (void) switchToRuntimeErrorView;						// Switches to the runtime error view
- (NSArray*) viewNames;									// Returns a list of the names of the views this controller can display

@end

// Delegate methods
@interface NSObject(NSCompilerControllerDelegate)

// Status updates
- (void) compileStarted: (IFCompilerController*) sender;				// Called when the compiler starts doing things
- (void) compileCompletedAndSucceeded: (IFCompilerController*) sender;	// Called when the compiler has finished and reports success
- (void) compileCompletedAndFailed: (IFCompilerController*) sender;		// Called when the compiler has finished and reports failure

// User interface notification
- (void) errorMessagesCleared: (IFCompilerController*) sender;			// Called when the list of errors are cleared
- (void) errorMessageHighlighted: (IFCompilerController*) sender		// Called when the user selects a specific error
                          atLine: (int) line
                          inFile: (NSString*) file;
- (void) compilerAddError: (IFCompilerController*) sender				// Called when the compiler generates a new error
                  forFile: (NSString*) file
                   atLine: (int) line
                 withType: (IFLex) type
                  message: (NSString*) message;
- (BOOL) handleURLRequest: (NSURLRequest*) request;						// First chance opportunity to redirect URL requests (used so that NI error URLs are handled)
- (void) viewSetHasUpdated: (IFCompilerController*) sender;				// Notification that the compiler controller has changed its set of views
- (void) compiler: (IFCompilerController*) sender						// Notification that the compiler has switched to the specified view
   switchedToView: (int) viewIndex;	

@end

