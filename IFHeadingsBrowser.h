//
//  IFHeadingsBrowser.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 24/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFBreadcrumbControl.h"

#import "IFIntelFile.h"
#import "IFIntelSymbol.h"
#import "IFSectionalView.h"
#import "IFViewAnimator.h"

@interface IFHeadingsBrowser : NSObject {
	// Views
	IBOutlet NSView* headingsView;
	IBOutlet IFSectionalView* sectionView;
	IBOutlet IFBreadcrumbControl* breadcrumb;
	
	IFViewAnimator* animator;
	IFViewAnimationStyle animStyle;
	
	// Current status
	IFIntelFile* intel;											// The intel file to find symbols from
	IFIntelSymbol* root;										// The root symbol whose child symbols to display (or null)
}

// Getting information about this browser
- (NSView*) view;												// The view that will display this browser

// Setting what to browse
- (void) setIntel: (IFIntelFile*) intel;						// Sets the IFIntelFile object to get symbols from
- (void) setSection: (IFIntelSymbol*) section;					// Sets the section to display
- (void) setSectionByLine: (int) line;							// Chooses a section from the current IFIntel

@end
