//
//  IFStandardProject.m
//  Inform
//
//  Created by Andrew Hunter on Sat Sep 13 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFStandardProject.h"


// Some useful functions
NSString* quoteInformString(NSString* stringIn) {
    // Turns characters such as '"' into '^'
    NSMutableString* res = [[NSMutableString alloc] init];

    int x, len;

    len = [stringIn length];

    // Strip spaces at the end of the string
    while ([stringIn characterAtIndex: len-1] == 10)
        len--;

    // Quote character appropriately
    for (x=0; x<len; x++) {
        unichar chr = [stringIn characterAtIndex: x];

        if (chr == 10) {
            [res appendString: @"^\n\t\t"];
        } else if (chr < 32) {
            // Ignore
        } else if (chr < 255) {
            switch (chr) {
                case '"':
                    [res appendString: @"~"];
                    break;

                case '@':
                    [res appendString: @"@@64"];
                    break;
                case '\\':
                    [res appendString: @"@@92"];
                    break;
                case '^':
                    [res appendString: @"@@94"];
                    break;
                case '~':
                    [res appendString: @"@@126"];
                    break;

                default:
                    [res appendFormat: @"%c", chr];
            }
        } else {
        }
    }

    return [res autorelease];
}

@implementation IFStandardProject

- (NSString*) projectName {
    return @"Single room";
}

- (NSString*) projectHeading {
    return @"Inform 6.21";
}

- (NSAttributedString*) projectDescription {
    return [[[NSAttributedString alloc] initWithString:
        @"Creates an Inform 6.21 project using the standard library and containing a single room"] autorelease];
}

- (NSObject<IFProjectSetupView>*) configView {
    IFStandardProjectView* vw;

    vw = [[IFStandardProjectView alloc] init];
    [NSBundle loadNibNamed: @"StandardProjectOptions"
                     owner: vw];

    return [vw autorelease];
}

- (void) setupFile: (IFProjectFile*) file
          fromView: (NSObject<IFProjectSetupView>*) view {
    IFStandardProjectView* theView = (IFStandardProjectView*) view;
    
    NSString* sourceTemplate = [NSString stringWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"standardMain" ofType: @"inf"]];

    NSString* sourceFile = [NSString stringWithFormat: sourceTemplate,
        quoteInformString([theView name]), quoteInformString([theView headline]),
        quoteInformString([theView initialRoom]),
        quoteInformString([theView initialRoomDescription]),
        quoteInformString([theView teaser])];
    
    [file addSourceFile: @"main.inf"
           withContents: [sourceFile dataUsingEncoding: NSISOLatin1StringEncoding]];
}

@end

@implementation IFStandardProjectView

- (void) dealloc {
    [view release];
    
    [super dealloc];
}

- (NSView*) view {
    return view;
}

- (NSString*) name {
    return [name stringValue];
}

- (NSString*) headline {
    return [headline stringValue];
}

- (NSString*) teaser {
    return [[teaser textStorage] string];
}

- (NSString*) initialRoom {
    return [initialRoom stringValue];
}

- (NSString*) initialRoomDescription {
    return [[initialRoomDescription textStorage] string];
}

@end

