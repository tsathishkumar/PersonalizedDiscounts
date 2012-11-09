//
//  AKOverlayViewController.h
//  AKTest
//
//  Created by Steven Bruce on 30/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AKOverlayViewController;

@protocol AKOverlayViewControllerDelegate

@required
- (void)overlayViewControllerDidFinish:(AKOverlayViewController*)controller;

@end

@interface AKOverlayViewController : UIViewController
{
    id delegate;
}

@property (nonatomic, assign) id delegate;

- (IBAction)donePressed;

@end
