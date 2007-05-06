//
//  IFPretendWebView.h
//  Inform
//
//  Created by Andrew Hunter on 18/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

//
// View that morphs into a webview the first time it's displayed
//
@interface IFPretendWebView : NSView {
	NSURLRequest* aRequest;
	NSWindow* hostWindow;
	id policyDelegate;
	id frameLoadDelegate;
}

- (void) setRequest: (NSURLRequest*) request;
- (void) setHostWindow: (NSWindow*) newHostWindow;
- (void) setPolicyDelegate: (id) delegate;
- (void) setFrameLoadDelegate: (id) delegate;

- (NSURLRequest*) request;

- (void) morphMe;

@end
