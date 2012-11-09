//
//  LoginViewController.h
//  PersonalizedDiscounts
//
//  Created by sathish on 10/31/12.
//  Copyright (c) 2012 Moodstocks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserService.h"
#import "AK.h"

@interface LoginViewController : UIViewController

#if MS_SDK_REQUIREMENTS
<MSScannerDelegate>
#endif
{
    NSTimeInterval _lastSync; // timestamp of last successful sync
    UIButton *launchButton;
    AKViewController *aurasmaController;
    NSTimer *splashTimer;
    BOOL hasBeenPresented;

}
@property (nonatomic, retain) IBOutlet UIButton *launchButton;
@property (retain, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *authButton;
@property (retain, nonatomic) IBOutlet UIButton *scanButton;
@property (nonatomic, retain) AKViewController *aurasmaController;

- (IBAction)loginPressed:(UIBarButtonItem *)sender;
- (IBAction)launchPressed:(id)sender;
- (IBAction)scanPressed:(id)sender;
- (void) updateView;

@end
