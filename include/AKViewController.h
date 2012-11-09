//
//  AKViewController.h
//  AurasmaKit
//
//  Copyright 2012 Aurasma. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AKConfig.h"

@class AKViewController;

@protocol AKViewControllerDelegate <NSObject>

@required
- (void)aurasmaViewControllerDidClose:(AKViewController *)aurasmaViewController;

@optional
- (void)aurasmaViewControllerDidFinishLoading:(AKViewController *)aurasmaViewController;
- (void)aurasmaViewController:(AKViewController *)aurasmaViewController didLoadOverlayView:(UIView *)overlayView;

@end


@interface AKViewController : UIViewController 
{
    id                      delegate;
    
    BOOL                    delayGuide;
    BOOL                    showsCloseButton;
}

@property (nonatomic, assign) id<AKViewControllerDelegate> delegate;
@property (nonatomic) BOOL delayGuide;
@property (nonatomic) BOOL showsCloseButton;

//
// Designated Creator
//

+ (AKViewController *)aurasmaViewControllerWithDelegate:(id)delegate;

- (BOOL)presentOverlayViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)dismissOverlayViewControllerAnimated:(BOOL)animated;

- (void)addButtonWithTarget:(id)target action:(SEL)action image:(UIImage *)image selectedImage:(UIImage *)selectedImage;

- (BOOL)setColor:(UIColor *)color forConfigColor:(AKConfigColor)configColor;
- (BOOL)setBackgroundImage:(UIImage *)image withContentMode:(UIViewContentMode)contentMode;

+ (void)unpackResources; // Synchronous

- (void)startLoading;
- (BOOL)isLoaded;

@end
