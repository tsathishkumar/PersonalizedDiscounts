//
//  LoginViewController.h
//  PersonalizedDiscounts
//
//  Created by sathish on 10/31/12.
//  Copyright (c) 2012 Moodstocks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

- (IBAction)loginPressed:(UIButton *)sender;
@property (retain, nonatomic) IBOutlet UIButton *authButton;

@end
