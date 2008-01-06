//
//  IFHeaderPage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 02/01/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFHeaderPage.h"


@implementation IFHeaderPage

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
		// Load the nib file
		[NSBundle loadNibNamed: @"Headers"
						 owner: self];
		
		// Set the view depth
		[headerView setDisplayDepth: [depthSlider intValue]];
		[headerView setDelegate: self];
	}
	
	return self;
}

- (void) dealloc {
	if (controller) {
		if (headerView) [controller removeHeaderView: headerView];
		[controller release];				controller = nil;
	}

	[headerView setDelegate: nil];
	
	[pageView release];						pageView = nil;
	[headerView release];					headerView = nil;
	[selectedNode release];					selectedNode = nil;
	
	[super dealloc];
}

// = KVC stuff for the page view/header view =

- (NSView*) pageView {
	return pageView;
}

- (IFHeaderView*) headerView {
	return headerView;
}

- (void) setPageView: (NSView*) newPageView {
	[pageView release]; pageView = nil;
	pageView = [newPageView retain];
}

- (void) setHeaderView: (IFHeaderView*) newHeaderView {
	if (controller && headerView) [controller removeHeaderView: headerView];
	
	[headerView release]; headerView = nil;
	headerView = [newHeaderView retain];

	if (controller && headerView) [controller addHeaderView: headerView];
}

// = Managing the controller =

- (void) setController: (IFHeaderController*) newController {
	if (controller) {
		[controller removeHeaderView: headerView];
		[controller release];
		controller = nil;
	}
	
	if (newController) {
		controller = [newController retain];
		if (headerView) [newController addHeaderView: headerView];
	}
}

- (void) setDelegate: (id) newDelegate {
	delegate = newDelegate;
}

// = Choosing objects =

- (void) selectNode: (IFHeaderNode*) node {
	if (node == selectedNode) return;
	
	[selectedNode setSelectionStyle: IFHeaderNodeUnselected];
	[selectedNode autorelease]; selectedNode = nil;
	
	selectedNode = [node retain];
	[selectedNode setSelectionStyle: IFHeaderNodeSelected];
	[headerView setNeedsDisplay: YES];
}

- (void) highlightNodeWithLines: (NSRange) lines {
	IFHeaderNode* lineNode = [[headerView rootHeaderNode] nodeWithLines: lines
															  intelFile: [controller intelFile]];
	if (lineNode == [headerView rootHeaderNode]) lineNode = nil;
	
	[self selectNode: lineNode];
}

// = User actions =

- (IBAction) updateDepthSlider: (id) sender {
	[headerView setDisplayDepth: [depthSlider intValue]];
}

// = Header view delegate methods =

- (void) headerView: (IFHeaderView*) view
	  clickedOnNode: (IFHeaderNode*) node {
	if (delegate && [delegate respondsToSelector: @selector(headerPage:limitToHeader:)]) {
		[delegate headerPage: self
			   limitToHeader: [node header]];
	}
}

@end
