//
//  IFProjectController.m
//  Inform
//
//  Created by Andrew Hunter on Wed Aug 27 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFProject.h"
#import "IFProjectController.h"
#import "IFProjectPane.h";


@implementation IFProjectController

// == Toolbar items ==
static NSToolbarItem* compileItem       = nil;
static NSToolbarItem* compileAndRunItem = nil;
static NSToolbarItem* releaseItem       = nil;

static NSDictionary*  itemDictionary = nil;

+ (void) initialize {
    compileItem   = [[NSToolbarItem alloc] initWithItemIdentifier: @"compileItem"];
    compileAndRunItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"compileAndRunItem"];
    releaseItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"releaseItem"];

    itemDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
        compileItem, @"compileItem",
        compileAndRunItem, @"compileAndRunItem",
        releaseItem, @"releaseItem",
        nil];

    // FIXME: localisation
    // FIXME: images
    [compileItem setLabel: @"Compile"];
    [compileAndRunItem setLabel: @"Go!"];
    [releaseItem setLabel: @"Release"];

    // The action heroes
    [compileItem setAction: @selector(compilerMan:)];
    [compileAndRunItem setAction: @selector(compileAndRunMan:)];
    [releaseItem setAction: @selector(releaseMan:)];
}

// == Initialistion ==

- (id) init {
    self = [super initWithWindowNibName:@"Project"];

    if (self) {
        toolbar = nil;
        projectPanes = [[NSMutableArray allocWithZone: [self zone]] init];
        splitViews   = [[NSMutableArray allocWithZone: [self zone]] init];
    }

    return self;
}

- (void) dealloc {
    if (toolbar) [toolbar release];
    [projectPanes release];
    [splitViews release];

    [super dealloc];
}

- (void) awakeFromNib {
    // Create the view switch toolbar
    toolbar = [[NSToolbar allocWithZone: [self zone]] initWithIdentifier: @"ProjectToolbar"];

    [toolbar setDelegate: self];
    [toolbar setDisplayMode: NSToolbarDisplayModeLabelOnly]; // FIXME: create icons
    [toolbar setAllowsUserCustomization: YES];
    
    [[self window] setToolbar: toolbar];

    // Setup the default panes
    [projectPanes removeAllObjects];
    [projectPanes addObject: [IFProjectPane standardPane]];
    [projectPanes addObject: [IFProjectPane standardPane]];

    [[projectPanes objectAtIndex: 0] selectView: IFSourcePane];
    [[projectPanes objectAtIndex: 1] selectView: IFErrorPane];

    [self layoutPanes];

    // Monitor for compiler finished notifications
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(compilerFinished:)
                                                 name: IFCompilerFinishedNotification
                                               object: [[self document] compiler]];
}

// == Project pane layout ==
- (void) layoutPanes {
    if ([projectPanes count] == 0) {
        return;
    }

    [projectPanes makeObjectsPerformSelector: @selector(removeFromSuperview)];
    [splitViews makeObjectsPerformSelector: @selector(removeFromSuperview)];
    [splitViews removeAllObjects];
    [[panesView subviews] makeObjectsPerformSelector:
        @selector(removeFromSuperview)];

    if ([projectPanes count] == 1) {
        // Just one pane
        IFProjectPane* firstPane = [projectPanes objectAtIndex: 0];

        [firstPane setController: self];
        
        [[firstPane paneView] setFrame: [panesView bounds]];
        [panesView addSubview: [firstPane paneView]];
    } else {
        // Create the splitViews
        int view, nviews;
        double dividerWidth = 5;

        nviews = [projectPanes count];
        for (view=0; view<nviews-1; view++) {
            NSSplitView* newView = [[NSSplitView allocWithZone: [self zone]] init];

            [newView setVertical: YES];
            [newView setIsPaneSplitter: YES];
            [newView setDelegate: self];
            [newView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];

            dividerWidth = [newView dividerThickness];

            [splitViews addObject: [newView autorelease]];
        }

        // Remaining space for other dividers
        double remaining = [panesView bounds].size.width - dividerWidth*(double)(nviews-1);
        double totalRemaining = [panesView bounds].size.width;
        double viewWidth = floor(remaining / (double)nviews);

        //NSRect paneBounds = [panesView bounds];
        
        // Insert the views
        NSSplitView* lastView = nil;
        for (view=0; view<nviews-1; view++) {
            // Garner some information about the views we're dealing with
            NSSplitView*   thisView = [splitViews objectAtIndex: view];
            IFProjectPane* pane     = [projectPanes objectAtIndex: view];
            NSView*        thisPane = [[projectPanes objectAtIndex: view] paneView];

            [pane setController: self];

            if (view == 0) {
                viewWidth *= 1.25;
                viewWidth = floor(viewWidth);
            } else {
                viewWidth = floor(remaining / (double)(nviews-view));
            }

            // Resize the splitview
            NSRect splitFrame;
            if (lastView != nil) {
                splitFrame = [lastView bounds];
                splitFrame.origin.x += viewWidth + dividerWidth;
                splitFrame.size.width = totalRemaining;
            } else {
                splitFrame = [panesView bounds];
            }
            [thisView setFrame: splitFrame];

            // Add it as a subview
            if (lastView != nil) {
                [lastView addSubview: thisView];
                //[lastView adjustSubviews];
            } else {
                [panesView addSubview: thisView];
            }

            // Add the leftmost view
            NSRect paneFrame = [thisView bounds];
            paneFrame.size.width = viewWidth;

            [thisPane setFrame: paneFrame];
            [thisView addSubview: thisPane];

            lastView = thisView;

            // Update the amount of space remaining
            remaining -= viewWidth;
            totalRemaining -= viewWidth + dividerWidth;
        }

        // Final view
        NSView* finalPane = [[projectPanes lastObject] paneView];
        NSRect finalFrame = [lastView bounds];

        [[projectPanes lastObject] setController: self];

        finalFrame.origin.x += viewWidth + dividerWidth;
        finalFrame.size.width = totalRemaining;
        [finalPane setFrame: finalFrame];
        
        [lastView addSubview: finalPane];
        [lastView adjustSubviews];
    }
}

// == Toolbar delegate functions ==

- (NSToolbarItem *)toolbar: (NSToolbar *) toolbar
     itemForItemIdentifier: (NSString *)  itemIdentifier
 willBeInsertedIntoToolbar: (BOOL)        flag {
    return [itemDictionary objectForKey: itemIdentifier];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
        @"compileItem", @"compileAndRunItem", @"releaseItem",
        NSToolbarSeparatorItemIdentifier, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects: @"compileAndRunItem", @"compileItem", @"releaseItem",
        NSToolbarSeparatorItemIdentifier, nil];
}

// == View selection functions ==
- (IBAction) compilerMan: (id) sender {
    IFProject* doc = [self document];

    compileFinishedAction = @selector(saveCompilerOutput);

    // Save the document
    [doc saveDocument: self];
    
    [projectPanes makeObjectsPerformSelector: @selector(stopRunningGame)];

    // Set up the compiler
    IFCompiler* theCompiler = [doc compiler];
    [theCompiler setSettings: [doc settings]];

    [theCompiler setOutputFile: [NSString stringWithFormat: @"%@/Build/output.z5",
        [doc fileName]]];

    if ([[doc settings] usingNaturalInform]) {
        [theCompiler setInputFile: [NSString stringWithFormat: @"%@",
            [doc fileName]]];
    } else {
        [theCompiler setInputFile: [NSString stringWithFormat: @"%@/Source/%@",
            [doc fileName], [doc mainSourceFile]]];
    }

    
    [theCompiler setDirectory: [NSString stringWithFormat: @"%@/Build", [doc fileName]]];

    // Time to go!
    [theCompiler prepareForLaunch];
    [theCompiler launch];

    [[projectPanes objectAtIndex: 1] selectView: IFErrorPane];
}

- (IBAction) compileAndRunMan: (id) sender {
    [self compilerMan: self];

    compileFinishedAction = @selector(runCompilerOutput);
}

// = Things to do after the compiler has finished =
- (void) saveCompilerOutput {
    // Setup a save panel
    NSSavePanel* panel = [NSSavePanel savePanel];
    IFCompilerSettings* settings = [[self document] settings];

    [panel setAccessoryView: nil];
    [panel setRequiredFileType: [settings fileExtension]];
    [panel setCanSelectHiddenExtension: YES];
    [panel setDelegate: self];
    [panel setPrompt: @"Save"];
    [panel setTreatsFilePackagesAsDirectories: NO];

    // Show it
    NSString* file = [[[self document] fileName] lastPathComponent];
    file = [file stringByDeletingPathExtension];
    
    [panel beginSheetForDirectory: @"~" // FIXME: preferences
                             file: file
                   modalForWindow: [self window]
                    modalDelegate: self
                   didEndSelector: @selector(compilerSavePanelDidEnd:returnCode:contextInfo:)
                      contextInfo: NULL];    
}

- (void) runCompilerOutput {
    // FIXME: Ideally needs to work from the last error pane
    [[projectPanes objectAtIndex: 1] startRunningGame: [[[self document] compiler] outputFile]];
}

- (void) compilerFinished: (NSNotification*) not {
    int exitCode = [[[not userInfo] objectForKey: @"exitCode"] intValue];

    NSFileWrapper* buildDir;

    // Can't do this: things break.
    //buildDir = [[[(IFProject*)[self document] projectFile] fileWrappers] objectForKey: @"Build"];
    //[buildDir updateFromPath: [NSString stringWithFormat: @"%@/Build", [[self document] fileName]]];

    buildDir = [[NSFileWrapper alloc] initWithPath:
        [NSString stringWithFormat: @"%@/Build", [[self document] fileName]]];
    [buildDir autorelease];

    int x;
    for (x=0; x<[projectPanes count]; x++) {
        IFProjectPane* pane = [projectPanes objectAtIndex: x];

        [[pane compilerController] showContentsOfFilesIn: buildDir];
    }

    if (exitCode == 0) {
        // Success!
        if ([[NSFileManager defaultManager] fileExistsAtPath: [[[self document] compiler] outputFile]]) {
            if ([self respondsToSelector: compileFinishedAction]) {
                [self performSelector: compileFinishedAction];
            }
        } else {
            // FIXME: show an alert sheet
            
        }
    }
}

- (void)compilerFaultAlertDidEnd: (NSWindow *)sheet
                      returnCode:(int)returnCode
                     contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        [self saveCompilerOutput]; // Try agin
    } else {
        // Do nothing
    }
}

- (void)compilerSavePanelDidEnd:(NSSavePanel *) sheet
                     returnCode:(int)           returnCode
                    contextInfo:(void *)        contextInfo {
    if (returnCode == NSOKButton) {
        NSString* whereToSave = [sheet filename];

        if (![[NSFileManager defaultManager] copyPath: [[[self document] compiler] outputFile]
                                              toPath: whereToSave
                                             handler: nil]) {
            // File failed to save
            
            // FIXME: internationalisation
            /* FIXME: doesn't work (save panel sheet is still displayed, doh!)
            NSBeginAlertSheet(@"Unable to save file", @"Retry", @"Cancel", nil,
                              [self window], self,
                              @selector(compilerFaultAlertDidEnd:returnCode:contextInfo:),
                              nil, nil,
                              @"An error was encountered while trying to save the file '%@'",
                              [whereToSave lastPathComponent]);
             */
        }
    } else {
        // Change nothing
    }
}

// = Communication from the containing panes =
- (BOOL) selectSourceFile: (NSString*) fileName {
    // IMPLEMENT ME: multiple file types
    return YES; // Only one source file ATM
}

- (void) moveToSourceFileLine: (int) line {
    int paneToUse = 0;
    int x;

    for (x=0; x<[projectPanes count]; x++) {
        IFProjectPane* thisPane = [projectPanes objectAtIndex: x];

        if ([thisPane currentView] == IFSourcePane) {
            // Always use the first source pane found
            paneToUse = x;
            break;
        }

        if ([thisPane currentView] == IFErrorPane) {
            // Avoid a pane showing error messages
            paneToUse = x+1;
        }
    }

    if (paneToUse >= [projectPanes count]) {
        // All error views?
        paneToUse = 0;
    }

    IFProjectPane* thePane = [projectPanes objectAtIndex: paneToUse];
    [thePane selectView: IFSourcePane];
    [thePane moveToLine: line];
    [[self window] makeFirstResponder: [thePane activeView]];
}

- (void) highlightSourceFileLine: (int) line {
    [self highlightSourceFileLine: line
                            style: IFLineStyleNeutral];
}

- (void) highlightSourceFileLine: (int) line
                           style: (enum lineStyle) style {
    // FIXME: clear/set temporary attributes
}

@end
