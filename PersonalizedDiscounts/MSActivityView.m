/**
 * Copyright (c) 2012 Moodstocks SAS
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "MSActivityView.h"

@interface MSActivityView ()
- (void)cancel;
@end

@implementation MSActivityView

@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        
        _label = [[UILabel alloc] init];
        _label.backgroundColor = [UIColor clearColor];
        _label.lineBreakMode = UILineBreakModeTailTruncation;
        _label.font = [UIFont boldSystemFontOfSize:16];
        _label.textColor = [UIColor whiteColor];
        [self addSubview:_label];
        
        _gear = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:_gear];
        
        _cancelButton = [[UIButton alloc] init];
        [_cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        [_cancelButton setShowsTouchWhenHighlighted:YES];
        [self addSubview:_cancelButton];
    }
    return self;
}

- (void)dealloc {
    [_label release];
    [_gear release];
    [_cancelButton release];
    
    _delegate = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat w = self.frame.size.width;
    CGFloat h = self.frame.size.height;
    
    CGFloat gw = _gear.frame.size.width;
    CGFloat gh = _gear.frame.size.height;
    _gear.frame = CGRectMake(0.5 * (w - gw), 0.5 * (h - gh), gw, gh);
    
    CGSize textSize = [_label.text sizeWithFont:_label.font];
    const CGFloat spacing = 10;
    CGFloat xl = 0.5 * (w - textSize.width);
    CGFloat yl = _gear.frame.origin.y + gh;
    _label.frame = CGRectMake(xl, yl + spacing, textSize.width, textSize.height);
    
    CGFloat margin = 5;
    UIImage *cancelImage = [UIImage imageNamed:@"cancel.png"];
    [_cancelButton setBackgroundImage:cancelImage forState:UIControlStateNormal];
    _cancelButton.frame = CGRectMake(w - (cancelImage.size.width + margin), margin, cancelImage.size.width, cancelImage.size.height);
}

#pragma mark -
#pragma mark Public

- (NSString *)text {
    return _label.text;
}

- (void)setText:(NSString *)text {
    _label.text = text;
    [self setNeedsLayout];
}

- (BOOL)isAnimating {
    return _gear.isAnimating;
}

- (void)setIsAnimating:(BOOL)isAnimating {
    if (isAnimating) {
        [_gear startAnimating];
    }
    else {
        [_gear stopAnimating];
    }
    [self setNeedsLayout];
}

#pragma mark -
#pragma mark Private

- (void)cancel {
    if ([_delegate respondsToSelector:@selector(activityViewDidCancel:)])
         [_delegate performSelector:@selector(activityViewDidCancel:) withObject:self];
}

@end
