//
//  IFNewProject.m
//  Inform
//
//  Created by Andrew Hunter on Fri Sep 12 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFNewProject.h"
#import "IFProjectFile.h"
#import "IFProject.h"

#import "IFEmptyProject.h"
#import "IFStandardProject.h"
#import "IFEmptyNaturalProject.h"
#import "IFNaturalExtensionProject.h"

@implementation IFNewProject

// = Initialisation =
static NSArray* projects = nil;
static NSMutableArray*      projectClasses;
static NSMutableDictionary* projectDictionary = nil;

+ (void) initialize {
    // List of projects
    projects = [[NSArray arrayWithObjects:
        [[IFEmptyNaturalProject alloc] init],
		[[IFNaturalExtensionProject alloc] init],
        [[IFEmptyProject alloc] init],
        [[IFStandardProject alloc] init],
        nil] retain];

    // Project dictionary
    projectClasses    = [[NSMutableArray array] retain];
    projectDictionary = [[NSMutableDictionary dictionary] retain];
    
    NSEnumerator* projectEnum = [projects objectEnumerator];
    NSObject<IFProjectType>* project;

    while (project = [projectEnum nextObject]) {
        NSMutableArray* curList = [projectDictionary objectForKey:
            [project projectHeading]];

        if (curList != nil) {
            [curList addObject: project];
        } else {
            curList = [NSMutableArray arrayWithObject: project];
            [projectDictionary setObject: curList
                                  forKey: [project projectHeading]];
            [projectClasses addObject: [project projectHeading]];
        }
    }
}

+ (void) finalize {
    [projects      release];
    [projectClasses    release];
    [projectDictionary release];
}

- (id) init {
    self = [super initWithWindowNibName: @"NewProject"];

    if (self) {
        [self setShouldCascadeWindows: NO];

        projectType = nil;
        projectView = nil;
    }

    return self;
}

- (void) dealloc {
    if (projectType) [projectType release];
    if (projectView) [projectView release];
    
    [super dealloc];
}

- (void) windowDidLoad {
    // Center the window
    NSRect screenFrame = [[[self window] deepestScreen] frame];
    NSRect winFrame    = [[self window] frame];

    winFrame.origin.x = screenFrame.origin.x + (screenFrame.size.width/2) -
        (winFrame.size.width/2);
    winFrame.origin.y = screenFrame.origin.y + (screenFrame.size.height/2) -
        (winFrame.size.height/2);

    [[self window] setFrame: winFrame
                    display: YES];

    // Expand the project list
    NSEnumerator* classEnum = [projectClasses objectEnumerator];
    NSString*     projectClass;
    while (projectClass = [classEnum nextObject]) {
        [projectTypes expandItem: projectClass];
    }

    // Select the first project type
    [projectTypes selectRow: [projectTypes rowForItem: [projects objectAtIndex: 0]]
       byExtendingSelection: NO];

    // Display the first pane
    [projectTypeView setFrame: [projectPaneView bounds]];
    [projectPaneView addSubview: projectTypeView];

    [previousButton setEnabled: NO];
    [nextButton setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Next"
																 value: @"Next"
																 table: nil]];

    currentView =  projectTypeView;
}

// = Interface =

- (void) manuallyCreateProject {
	if ([projectType respondsToSelector: @selector(createAndOpenDocument:)]) {
		if ([projectType createAndOpenDocument: [projectType saveFilename]]) {
			// Success
			[self close];
			return;
		} else {
			[projectPaneView addSubview: currentView];
			NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"Unable to create project"
																	 value: @"Unable to create project"
																	 table: nil],
							  [[NSBundle mainBundle] localizedStringForKey: @"Cancel"
																	 value: @"Cancel"
																	 table: nil],
							  nil, nil,
							  [self window],
							  nil,
							  nil,
							  nil,
							  nil,
							  [[NSBundle mainBundle] localizedStringForKey: @"Inform was unable to save the project file"
																	 value: @"Inform was unable to save the project file"
																	 table: nil]);
		}
		
		return;
	}
	
	// Use information from the project type to create the project
	IFProjectFile* theFile = [[IFProjectFile alloc] initDirectoryWithFileWrappers: [NSDictionary dictionary]];
	BOOL success;
	
	[theFile setFilename: [projectType saveFilename]];
	[projectType setupFile: theFile
				  fromView: projectView];
	
	success = [theFile writeToFile: [projectType saveFilename]
						atomically: YES
				   updateFilenames: YES];
	
	if (success) {
		[self close];
		
		// Owing to a bug in NSFileWrapper (I think), we can't set the
		// 'hidden extension' attribute there, so we use NSFileManager
		// to do this instead.
		if (hideExtension) {
			NSMutableDictionary* attributes = [[[NSFileManager defaultManager] fileAttributesAtPath: [projectLocation stringValue] traverseLink: YES] mutableCopy];
			[attributes setObject: [NSNumber numberWithBool: YES]
						   forKey: NSFileExtensionHidden];
			[[NSFileManager defaultManager] changeFileAttributes: attributes
														  atPath: [projectLocation stringValue]];
			[attributes release];
		}

		NSDocument* newDoc = [[IFProject alloc] initWithContentsOfFile: [projectType saveFilename]
																ofType: [projectType openAsType]];
		
		[[NSDocumentController sharedDocumentController] addDocument: [newDoc autorelease]];
		[newDoc makeWindowControllers];
		[newDoc showWindows];
		
		[theFile release];		
	} else {
		[projectPaneView addSubview: currentView];
		NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"Unable to create project"
																 value: @"Unable to create project"
																 table: nil],
						  [[NSBundle mainBundle] localizedStringForKey: @"Cancel"
																 value: @"Cancel"
																 table: nil],
						  nil, nil,
						  [self window],
						  nil,
						  nil,
						  nil,
						  nil,
						  [[NSBundle mainBundle] localizedStringForKey: @"Inform was unable to save the project file"
																 value: @"Inform was unable to save the project file"
																 table: nil]);
	}
}

- (void) confirmDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSAlertAlternateReturn) {
		// Only happens when we're manually creating the project
		[self manuallyCreateProject];
	}
}

- (IBAction) nextView:     (id) sender {
    [currentView removeFromSuperview];
	
	BOOL shouldUseFinalPage = YES;
	
	if (projectType && [projectType respondsToSelector: @selector(showFinalPage)]) {
		shouldUseFinalPage = [projectType showFinalPage];
	}

    if ((currentView == projectTypeView && projectView == nil) ||
        (projectView != nil && currentView == [projectView view] && shouldUseFinalPage)) {
        // Change to the file location view
        currentView = projectLocationView;
		
		if ([[projectLocation stringValue] isEqualTo: @""]) {
			// Pop up the save dialog
			[self chooseLocation: self];
		}

        [previousButton setEnabled: YES];
        [nextButton setEnabled: ![[projectLocation stringValue] isEqualTo: @""]];
        [nextButton setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Finished"
																	 value: @"Finished"
																	 table: nil]];
    } else if (currentView == projectTypeView) {
        // Change to the project type view
        currentView = [projectView view];

        [previousButton setEnabled: YES];
        [nextButton setEnabled: YES];
        [nextButton setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Next"
																	 value: @"Next"
																	 table: nil]];
		
		if (!shouldUseFinalPage) {
			[nextButton setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Finished"
																		 value: @"Finished"
																		 table: nil]];
		}
	} else if (currentView == [projectView view] && !shouldUseFinalPage) {
		[projectPaneView addSubview: currentView];

		// Get the file to save and finish up (must implement these selectors now)
		NSString* confirm = nil;
		NSString* error = nil;
		
		if ([projectType respondsToSelector: @selector(errorMessage)]) {
			error = [projectType errorMessage];
		}
		
		if (!error && [projectType respondsToSelector: @selector(confirmationMessage)]) {
			confirm = [projectType confirmationMessage];
		}
		
		if (error) {
			// Display an error message
            NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"Unable to create project"
																	 value: @"Unable to create project"
																	 table: nil],
                              [[NSBundle mainBundle] localizedStringForKey: @"Cancel"
																	 value: @"Cancel"
																	 table: nil],
                              nil, nil,
                              [self window],
                              nil,
                              nil,
                              nil,
                              nil,
                              error);			
			return;
		}
		
		if (confirm) {
			// Display a confirmation message (FIXME: do something about the result)
            NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"Are you sure you wish to create this project?"
																	 value: @"Are you sure you wish to create this project?"
																	 table: nil],
                              [[NSBundle mainBundle] localizedStringForKey: @"Cancel"
																	 value: @"Cancel"
																	 table: nil],
							  [[NSBundle mainBundle] localizedStringForKey: @"Create"
																	 value: @"Create"
																	 table: nil],
							  nil,
                              [self window],
                              self,
							  @selector(confirmDidEnd:returnCode:contextInfo:),
                              nil,
                              nil,
                              confirm);			
			return;			
		}
		
		[self manuallyCreateProject];
    } else if (currentView == projectLocationView) {
        // Save and finish up
        IFProjectFile* theFile = [[IFProjectFile alloc] initWithEmptyProject];
        BOOL success;
        
		[theFile setFilename: [projectLocation stringValue]];
        [projectType setupFile: theFile
                      fromView: projectView];

        success = [theFile writeToFile: [projectLocation stringValue]
                            atomically: YES
                       updateFilenames: YES];

        if (success) {
            [self close];

            // Owing to a bug in NSFileWrapper (I think), we can't set the
            // 'hidden extension' attribute there, so we use NSFileManager
            // to do this instead.
            if (hideExtension) {
                NSMutableDictionary* attributes = [[[NSFileManager defaultManager] fileAttributesAtPath: [projectLocation stringValue] traverseLink: YES] mutableCopy];
                [attributes setObject: [NSNumber numberWithBool: YES]
                               forKey: NSFileExtensionHidden];
                [[NSFileManager defaultManager] changeFileAttributes: attributes
                                                              atPath: [projectLocation stringValue]];
                [attributes release];
            }

            /*
            IFProject* openDoc;

            openDoc = [[IFProject alloc] initWithContentsOfFile: [projectLocation stringValue]
                                                         ofType: @"Inform project file"];
            if (openDoc) {
                [openDoc makeWindowControllers];
                [[openDoc windowControllers] makeObjectsPerformSelector: @selector(showWindow:)
                                                             withObject: self];
            }
             */
            [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile: [projectLocation stringValue]
                                                                                    display: YES];

            [theFile release];
        } else {
            [projectPaneView addSubview: currentView];
            NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"Unable to create project"
																	 value: @"Unable to create project"
																	 table: nil],
                              [[NSBundle mainBundle] localizedStringForKey: @"Cancel"
																	 value: @"Cancel"
																	 table: nil],
                              nil, nil,
                              [self window],
                              nil,
                              nil,
                              nil,
                              nil,
                              [[NSBundle mainBundle] localizedStringForKey: @"Inform was unable to save the project file"
																	 value: @"Inform was unable to save the project file"
																	 table: nil]);
        }
    } else {
        // Change to the project type view
        [previousButton setEnabled: NO];
        [nextButton setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Next"
																	 value: @"Next"
																	 table: nil]];
        [nextButton setEnabled: YES];

        currentView =  projectTypeView;        
    }

    [currentView setFrame: [projectPaneView bounds]];
    [projectPaneView addSubview: currentView];
}

- (IBAction) previousView: (id) sender {
    [currentView removeFromSuperview];

    if (currentView == projectLocationView &&
        projectView != nil) {
        currentView = [projectView view];
    } else {
        // Change to the project type view
        [previousButton setEnabled: NO];

        currentView =  projectTypeView;
    }

    [nextButton setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Next"
																 value: @"Next"
																 table: nil]];
    [nextButton setEnabled: YES];

    [currentView setFrame: [projectPaneView bounds]];
    [projectPaneView addSubview: currentView];
}

- (IBAction) cancel: (id) sender {
    [self close];
}

- (IBAction) chooseLocation: (id) sender {
    // Setup a save panel
    NSSavePanel* panel = [NSSavePanel savePanel];

    [panel setAccessoryView: nil];
    [panel setRequiredFileType: @"inform"];
    [panel setCanSelectHiddenExtension: YES];
    [panel setDelegate: self];
    [panel setPrompt: [[NSBundle mainBundle] localizedStringForKey: @"Create"
															 value: @"Create"
															 table: nil]];
    [panel setTreatsFilePackagesAsDirectories: NO];

    // Show it
    [panel beginSheetForDirectory: @"~"
                             file: nil
                   modalForWindow: [self window]
                    modalDelegate: self
                   didEndSelector: @selector(savePanelDidEnd:returnCode:contextInfo:)
                      contextInfo: NULL];
}

- (void) close {
	[[self window] orderOut: self];
	
	// (Allowing a delay ensures that there is no crash after the window closes: the file selector can be a bit tetchy)
	[self performSelector: @selector(autorelease)
			   withObject: nil
			   afterDelay: 30.0];
}

- (void)savePanelDidEnd:(NSSavePanel *) sheet
             returnCode:(int)           returnCode
            contextInfo:(void *)        contextInfo {
    if (returnCode == NSOKButton) {
        hideExtension = [sheet isExtensionHidden];
        
        [projectLocation setStringValue: [sheet filename]];
        [nextButton setEnabled: YES];
		
		if (![[projectLocation stringValue] isEqualTo: @""]) {
			// Act as if we finished
			[self nextView: self];
		}
    } else {
        // Change nothing - return to the previous view
		[self previousView: self];
    }
}

// = Outline view =

- (int)         outlineView:(NSOutlineView *)outlineView
     numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        return [projectClasses count];
    }

    int classNum = [projectClasses indexOfObjectIdenticalTo: item];

    if (classNum == NSNotFound) {
        return 0;
    }

    return [[projectDictionary objectForKey:
        [projectClasses objectAtIndex: classNum]] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
   isItemExpandable:(id)item {
    if (item == nil) return YES;
    return [projectClasses indexOfObjectIdenticalTo: item] != NSNotFound;
}

- (id)outlineView:(NSOutlineView *)outlineView
            child:(int)index
           ofItem:(id)item {
    if (item == nil) {
        return [projectClasses objectAtIndex: index];
    }

    int classNum = [projectClasses indexOfObjectIdenticalTo: item];

    if (classNum == NSNotFound) {
        return nil;
    }

    return [[projectDictionary objectForKey:
        [projectClasses objectAtIndex: classNum]] objectAtIndex: index];
}

- (id)          outlineView:(NSOutlineView *)outlineView
  objectValueForTableColumn:(NSTableColumn *)tableColumn
                     byItem:(id)item {
    if ([item isKindOfClass: [NSString class]]) {
        // Must be a project class heading
        NSFontManager* mgr = [NSFontManager sharedFontManager];
        NSFont* boldFont = [mgr convertFont: [NSFont systemFontOfSize: 12]
                                toHaveTrait: NSBoldFontMask];
        
        NSAttributedString* str = [[NSAttributedString alloc] initWithString: item
                                                                  attributes: [NSDictionary dictionaryWithObjectsAndKeys: boldFont, NSFontAttributeName, nil]];

        return [str autorelease];
    }

    // Must be a NSObject<IFProjectType> object
    NSAttributedString* str = [[NSAttributedString alloc] initWithString: [item projectName]];

    return [str autorelease];
}

- (BOOL) outlineView: (NSOutlineView*) outlineView
    shouldSelectItem: (id) item {
    if (item == nil)
        return NO;

    int classNum = [projectClasses indexOfObjectIdenticalTo: item];

    if (classNum == NSNotFound) {
        return YES;
    }

    return NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSObject<IFProjectType>* obj = [projectTypes itemAtRow: [projectTypes selectedRow]];

    if (obj == nil ||
        ![obj conformsToProtocol: @protocol(IFProjectType)]) {
        [nextButton setEnabled: NO];
        [[[projectDescriptionView textStorage] mutableString] setString: [[NSBundle mainBundle] localizedStringForKey: @"Please choose a project type"
																												value: @"Please choose a project type"
																												table: nil]];
        return;
    }

    if (projectType) [projectType release];
    if (projectView) [projectView release];

    projectType = [obj retain];
    projectView = [obj configView];

    if (projectView) {
        [projectView retain];
    }

    [[projectDescriptionView textStorage] setAttributedString: [obj projectDescription]];
    [nextButton setEnabled: YES];
}

@end
