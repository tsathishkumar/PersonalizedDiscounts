//
//  LoginViewController.h
//  PersonalizedDiscounts
//
//  Created by sathish on 10/31/12.
//  Copyright (c) 2012 Moodstocks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserService.h"

@interface LoginViewController : UIViewController

#if MS_SDK_REQUIREMENTS
<MSScannerDelegate>
#endif
{
    NSTimeInterval _lastSync; // timestamp of last successful sync
}
@property (retain, nonatomic) IBOutlet UILabel *welcomeLabel;

@property (retain, nonatomic) IBOutlet UIBarButtonItem *authButton;
- (IBAction)loginPressed:(UIBarButtonItem *)sender;
@property (retain, nonatomic) IBOutlet UIButton *scanButton;
- (IBAction)scanPressed:(id)sender;
- (void) updateView;

@end
