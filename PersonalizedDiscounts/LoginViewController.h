//
//  LoginViewController.h
//  PersonalizedDiscounts
//
//  Created by sathish on 10/31/12.
//  Copyright (c) 2012 Moodstocks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

@property (retain, nonatomic) IBOutlet UIBarButtonItem *authButton;
- (IBAction)loginPressed:(UIBarButtonItem *)sender;
@property (retain, nonatomic) IBOutlet UIButton *scanButton;
- (IBAction)scanPressed:(id)sender;

@end
