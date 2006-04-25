//
//  IFMaintenanceTask.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/04/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import "IFMaintenanceTask.h"

NSString* IFMaintenanceTasksStarted = @"IFMaintenanceTasksStarted";
NSString* IFMaintenanceTasksFinished = @"IFMaintenanceTasksFinished";

@implementation IFMaintenanceTask

// = Initialisation =

+ (IFMaintenanceTask*) sharedMaintenanceTask {
	static IFMaintenanceTask* maintenanceTask = nil;
	
	if (!maintenanceTask) {
		maintenanceTask = [[IFMaintenanceTask alloc] init];
	}
	
	return maintenanceTask;
}

- (id) init {
	self = [super init];
	
	if (self) {
		activeTask = nil;
		pendingTasks = [[NSMutableArray alloc] init];
		
		haveFinished = YES;
	}
	
	return self;
}

- (void) dealloc {
	[activeTask release];
	[pendingTasks release];
	
	[super dealloc];
}

// = Starting tasks =

- (BOOL) startNextTask {
	if (activeTask != nil) return YES;
	if ([pendingTasks count] <= 0) return NO;
	
	// Retrieve the next task to run
	NSArray* newTask = [[[pendingTasks objectAtIndex: 0] retain] autorelease];
	[pendingTasks removeObjectAtIndex: 0];
	
	// Set up a new task
	activeTask = [[NSTask alloc] init];
	
	[activeTask setLaunchPath: [newTask objectAtIndex: 0]];
	[activeTask setArguments: [newTask objectAtIndex: 1]];
	
	// Register for notifications
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(taskFinished:)
												 name: NSTaskDidTerminateNotification
											   object: activeTask];
	
	// Notify anyone who's interested that we're started
	if (haveFinished) {
		[[NSNotificationCenter defaultCenter] postNotificationName: IFMaintenanceTasksStarted
															object: self];
		haveFinished = NO;
	}
	
	// Start the task
	[activeTask launch];
	return YES;
}

- (void) taskFinished: (NSNotification*) not {
	// Stop monitoring the old task
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: NSTaskDidTerminateNotification
												  object: activeTask];
	
	// Clear up the old task
	[activeTask release];
	activeTask = nil;
	
	// Start the next task in the queue
	if (![self startNextTask]) {
		// We've finished!
		haveFinished = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName: IFMaintenanceTasksFinished
															object: self];
	}
}

// = Queuing tasks =

- (void) queueTask: (NSString*) command {
	[self queueTask: command
	  withArguments: [NSArray array]];
}

- (void) queueTask: (NSString*) command
	 withArguments: (NSArray*) arguments {
	[pendingTasks addObject:
		[NSArray arrayWithObjects: command, arguments, nil]];
	
	[self startNextTask];
}

@end
