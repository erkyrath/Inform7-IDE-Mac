//
//  main.m
//  Inform
//
//  Created by Andrew Hunter on Fri Aug 15 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define DEBUG_BUILD
#ifdef DEBUG_BUILD
static void reportLeaks(void) {
    // List just the unreferenced memory
    char flup[256];
    sprintf(flup, "/usr/bin/leaks -nocontext %i", getpid());
    system(flup);
}
#endif

int main(int argc, const char *argv[])
{
#ifdef DEBUG_BUILD
    atexit(reportLeaks);
#endif
    return NSApplicationMain(argc, argv);
}
