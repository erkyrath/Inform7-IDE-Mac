//
//  IFJSProject.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 29/08/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFJSProject.h"


@implementation IFJSProject

// = Initialisation =

- (id) initWithPane: (IFProjectPane*) newPane {
	self = [super init];
	
	if (self) {
		pane = newPane;
	}
	
	return self;
}

- (void) dealloc {
	pane = nil;
	
	[super dealloc];
}

// = JavaScript names for our selectors =

+ (NSString *) webScriptNameForSelector: (SEL)sel {
	if (sel == @selector(selectView:)) {
		return @"selectView";
	} else if (sel == @selector(pasteCode:)) {
		return @"pasteCode";
	} else if (sel == @selector(runStory:)) {
		return @"runStory";
	} else if (sel == @selector(replayStory:)) {
		return @"replayStory";
	} else if (sel == @selector(addCommand:)) {
		return @"addCommand";
	} else if (sel == @selector(clearCommands)) {
		return @"clearCommands";
	}
	
	return nil;
}

+ (BOOL) isSelectorExcludedFromWebScript: (SEL)sel {
	if (sel == @selector(selectView:) || sel == @selector(pasteCode:) || sel == @selector(replayStory:) || sel == @selector(addCommand:) || sel == @selector(clearCommands)) {
		return NO;
	}
	
	return YES;
}

// = JavaScript operations on the pane =

- (void) selectView: (NSString*) view {
	view = [view lowercaseString];
	
	if ([view isEqualToString: @"source"]) {
		[pane selectView: IFSourcePane];
	} else if ([view isEqualToString: @"error"]) {
		[pane selectView: IFErrorPane];
	} else if ([view isEqualToString: @"game"]) {
		[pane selectView: IFGamePane];
	} else if ([view isEqualToString: @"documentation"]) {
		[pane selectView: IFDocumentationPane];
	} else if ([view isEqualToString: @"index"]) {
		[pane selectView: IFIndexPane];
	} else if ([view isEqualToString: @"skein"]) {
		[pane selectView: IFTranscriptPane];
	} else {
		// Other view types are not supported at present
	}
}

- (void) pasteCode: (NSString*) code {
	[pane pasteSourceCode: code];
}

- (void) runStory: (NSString*) game {
}

- (void) replayStory: (NSString*) game {
}

- (void) addCommand: (NSString*) command {
}

- (void) clearCommands {
}

- (void)finalizeForWebScript {
	pane = nil;
}

@end
