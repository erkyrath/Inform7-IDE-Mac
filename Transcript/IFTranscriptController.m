//
//  IFTranscriptController.m
//  Inform
//
//  Created by Andrew Hunter on 12/09/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFTranscriptController.h"

//
// Hard to think of how this should really work, so lets plan things:
//
// The transcript view is sort of a 'flat' view of the skein view. Unlike the skein view, it
// shows responses and 'expected' responses as well as commands, but it only shows one branch
// of the skein at a time. This makes it perfect for reviewing a game as played, and probably
// as a means for beta testers to communicate with game authors. The transcript is unlikely to
// work well with v6 games: we'll have to see about this.
//
// As such, the transcript is essentially a series of 'blocks', arranged like this:
//
// +-----------------------------------------------------------------------------+
// | > North																	 |
// +--------------------------------------+--------------------------------------+
// | The frob blocks further progress to  |	The frob blocks further progress to	 |
// | the north.							  |	the north. You toy briefly with your |
// |									  |	+4 sword of frob slaying, but the	 |
// |									  |	mere thought of dealing with the	 |
// |									  |	society for the preservation of 	 |
// |									  |	malicious frobs is enough to bring	 |
// |									  | you out in a rash.					 |
// +--------------------------------------+--------------------------------------+
// | > Diagnose																	 |
// +--------------------------------------+--------------------------------------+
// | That's not a verb I recognise.		  | You have an itchy rash.				 |
// +--------------------------------------+--------------------------------------+
//			  Actual response						   Expected response
//
// The command and actual response are coloured red/yellow/green/gray as for the skein view.
// 
// This is a tad complicated to do with Cocoa's text system, though. I think we can't just use
// a standard text view for this (formatting the transcript accordingly): the column display
// woukld be hard to achieve there, as the text system assumes top-to-bottom formatting only.
// We could use lots of TextViews, but I suspect that would be very slow.
//
// At least, this is the general idea. I'll probably go with something simpler for now
//

@implementation IFTranscriptController

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
		transcriptStorage = [[IFTranscriptStorage alloc] init];
	}
	
	return self;
}

- (void) dealloc {
	[transcriptStorage release];
	[transcriptTextView release];
	[skein release];
	
	[super dealloc];
}

// = Setting the skein =

- (void) setSkein: (ZoomSkein*) newSkein {
	if (skein) [skein release];
	
	skein = [newSkein retain];
	[transcriptStorage setTranscriptToPoint: [skein rootItem]];
}

- (ZoomSkein*) skein {
	return skein;
}

- (void) transcriptToPoint: (ZoomSkeinItem*) point {
	[transcriptStorage setTranscriptToPoint: point];
}

- (void) scrollToItem: (ZoomSkeinItem*) item {
	[transcriptTextView scrollRangeToVisible: [transcriptStorage rangeForItem: item]];
}

// = Communications =

- (void) setTranscriptStorage: (IFTranscriptStorage*) storage {
	// Destroy the old storage
	if (transcriptTextView) {
		[transcriptStorage removeLayoutManager: [transcriptTextView layoutManager]];
	}
	[transcriptStorage release];
	
	// Set ourselves up with the new storage
	transcriptStorage = [storage retain];
	if (transcriptTextView) [transcriptStorage addLayoutManager: [transcriptTextView layoutManager]];
}

- (IFTranscriptStorage*) transcriptStorage {
	return transcriptStorage;
}

- (void) setTranscriptTextView: (NSTextView*) textview {
	// Delete the old view
	if (transcriptTextView) {
		[transcriptStorage removeLayoutManager: [transcriptTextView layoutManager]];
		[transcriptTextView release];
	}
	
	// Store the new view
	transcriptTextView = [textview retain];
	
	// Add the new view's layout manager
	[transcriptStorage addLayoutManager: [transcriptTextView layoutManager]];
}

@end
