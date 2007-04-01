//
//  IFDocumentationPage.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IFPage.h"

//
// The 'documentation' page
//
@interface IFDocumentationPage : IFPage {
	// The documentation view
	WebView* wView;										// The web view that displays the documentation
}

// The documentation view
- (void) openURL: (NSURL*) url;									// Tells the documentation view to open a specific URL

@end
