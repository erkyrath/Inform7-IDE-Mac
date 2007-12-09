/*
 *  IFLeopardProtocol.h
 *  Inform-xc2
 *
 *  Created by Andrew Hunter on 09/12/2007.
 *  Copyright 2007 Andrew Hunter. All rights reserved.
 *
 */

///
/// Extra functions available to the Inform UI under leopard
///
@protocol IFLeopardProtocol

// Text view magic

- (void) showFindIndicatorForRange: (NSRange) charRange					// Shows the find indicator for the specified range
						inTextView: (NSTextView*) textView;

@end
