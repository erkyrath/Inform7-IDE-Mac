//
//  IFCblorbProblem.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 28/01/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import "IFCblorbProblem.h"


@implementation IFCblorbProblem

- (NSURL*) urlForProblemWithErrorCode: (int) errorCode {
	return [NSURL URLWithString: @"inform:/ErrorCblorb.html"];
}

- (NSURL*) urlForSuccess {
	return [NSURL URLWithString: @"inform:/GoodCblorb.html"];
}

@end
