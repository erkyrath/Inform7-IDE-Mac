//
//  IFInspectorWindow.m
//  Inform
//
//  Created by Andrew Hunter on Thu Apr 29 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import "IFInspectorWindow.h"
#import "IFIsArrow.h"
#import "IFInspectorView.h"
#import "IFIsFlippedView.h"


@implementation IFInspectorWindow

+ (IFInspectorWindow*) sharedInspectorWindow {
	static IFInspectorWindow* sharedWindow = nil;
	
	if (sharedWindow == nil) {
		sharedWindow = [[[self class] alloc] init];
	}
	
	return sharedWindow;
}

- (id) init {
	// Create ourselves a window
	NSScreen* mainScreen = [NSScreen mainScreen];
	float width = 240;
	float height = 10;
	
	NSPanel* ourWindow = [[NSPanel alloc] initWithContentRect: NSMakeRect(NSMaxX([mainScreen frame])-width-50, NSMaxY([mainScreen frame])-height-50, 
																				 width, height)
													styleMask: NSTitledWindowMask|NSClosableWindowMask|NSUtilityWindowMask
													  backing: NSBackingStoreBuffered
														defer: YES];
	
	[ourWindow setFloatingPanel: YES];
	[ourWindow setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Inspectors"
																value: @"Inspectors"
																table: nil]];
	[ourWindow setMinSize: NSMakeSize(0,0)];
	[ourWindow setMaxSize: NSMakeSize(4000, 4000)];
	
	// Initialise ourselves properly
	return [self initWithWindow: [ourWindow autorelease]];
}

- (id)initWithWindow:(NSWindow *)window {
	self = [super initWithWindow: window];
	
	if (self) {
		inspectors = [[NSMutableArray alloc] init];
		inspectorViews = [[NSMutableArray alloc] init];
		updating = NO;
		
		// The sole purpose of IFIsFlippedView is to return YES to isFlipped...
		[[self window] setContentView: [[[IFIsFlippedView alloc] init] autorelease]];
		
		// - Easy, but broken
		//[self setWindowFrameAutosaveName: @"InspectorWindowFrame"];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(newMainWindow:)
													 name: NSWindowDidBecomeMainNotification
												   object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(byeMainWindow:)
													 name: NSWindowDidResignMainNotification
												   object: nil];
		newMainWindow = NO;
		activeMainWindow = nil;
	}
	
	return self;
}

- (void) dealloc {
	[inspectors release];
	[inspectorViews release];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[super dealloc];
}

// = Dealing with inspector views =
- (void) addInspector: (IFInspector*) newInspector {
	// Add the inspector
	[newInspector setInspectorWindow: self];
	[inspectors addObject: newInspector];

	// Create an inspector view for it
	NSRect ourFrame = [[[self window] contentView] frame];
	IFInspectorView* insView = [[IFInspectorView alloc] initWithFrame: NSMakeRect(0,0,ourFrame.size.width,20)];
	
	[insView setView: [newInspector inspectorView]];
	[insView setTitle: [newInspector title]];
	
	[insView setPostsFrameChangedNotifications: YES];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(updateInspectors:)
												 name: NSViewFrameDidChangeNotification
											   object: insView];
	
	[[[self window] contentView] addSubview: insView];
	[inspectorViews addObject: [insView autorelease]];
	
	// Update the list of inspectors
	[self updateInspectors];
}

// = Dealing with updates =
- (void) updateInspectors: (NSNotification*) not {
	[self updateInspectors];
}

- (void) updateInspectors {
	if (updating) return;
	
	[[NSRunLoop currentRunLoop] performSelector: @selector(finishUpdate)
										 target: self
									   argument: nil
										  order: 128
										  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
	updating = YES;
}

- (void) finishUpdate {
	// Display + order all the inspector and relevant controls
	updating = NO; // Do this first: if there's an exception, then we won't be hurt as much
	
	NSRect contentFrame = [[[self window] contentView] frame];
	
	NSEnumerator* inspectorEnum = [inspectorViews objectEnumerator];
	IFInspectorView* insView;
	
	// Position all the inspectors
	float ypos = contentFrame.origin.y;
	while (insView = [inspectorEnum nextObject]) {
		NSRect insFrame = [insView frame];
		
		insFrame.origin = NSMakePoint(contentFrame.origin.x, ypos);
		insFrame.size.width = contentFrame.size.width;
		
		[insView setFrame: insFrame];
		
		ypos += insFrame.size.height;
	}
	
	// ypos defines the size of the window
	
	// Need to do things this way as Jaguar has no proper calculation routines
	NSRect currentFrame = [[self window] frame];
	
	float difference = currentFrame.size.height - contentFrame.size.height;
	
	NSRect newFrame = currentFrame;
	newFrame.size.height = ypos + difference;
	newFrame.origin.y -= newFrame.size.height-currentFrame.size.height;
	
	[[self window] setFrame: newFrame
					display: YES];
}

// = Dealing with window changes =

- (void) newMainWindow: (NSNotification*) notification {
	// Notify the inspectors of the change
	NSWindow* newMain = [notification object];
	
	if (activeMainWindow != newMain) {
		activeMainWindow = newMain;
	
		if (!newMainWindow) {
			newMainWindow = YES;
			[[NSRunLoop currentRunLoop] performSelector: @selector(updateMainWindow:)
												 target: self
											   argument: nil
												  order: 129
												  modes: [NSArray arrayWithObjects: NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil]];
		}
	}
}

- (void) byeMainWindow: (NSNotification*) notification {
	// Notify the inspectors of the change
	NSWindow* notTheMainWindowAnyMore = [notification object];
	
	if (activeMainWindow == notTheMainWindowAnyMore) {
		activeMainWindow = nil;

		if (!newMainWindow) {
			newMainWindow = YES;
			[[NSRunLoop currentRunLoop] performSelector: @selector(updateMainWindow:)
												 target: self
											   argument: nil
												  order: 129
												  modes: [NSArray arrayWithObjects: NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil]];
		}
	}
}

- (void) updateMainWindow: (id) arg {
	// The main window has changed: notify the inspectors
	newMainWindow = NO;
	[inspectors makeObjectsPerformSelector: @selector(inspectWindow:)
								withObject: activeMainWindow];
}

@end
