//
//  CHTumblrMenuView.m
//  TumblrMenu
//
//  Created by HangChen on 12/9/13.
//  Copyright (c) 2013 Hang Chen (https://github.com/cyndibaby905)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "CHTumblrMenuView.h"
#define CHTumblrMenuViewTag 1999
#define CHTumblrMenuViewTitleHeight 30
#define CHTumblrMenuViewVerticalPadding 20
#define CHTumblrMenuViewRriseAnimationID @"CHTumblrMenuViewRriseAnimationID"
#define CHTumblrMenuViewDismissAnimationID @"CHTumblrMenuViewDismissAnimationID"
#define CHTumblrMenuViewAnimationTime 0.36
#define CHTumblrMenuViewAnimationInterval (CHTumblrMenuViewAnimationTime / 5)

#define TumblrBlue [UIColor colorWithRed:45/255.0f green:68/255.0f blue:94/255.0f alpha:1.0]

@interface CHTumblrMenuItemButton : UIButton
+ (id)TumblrMenuItemButtonWithTitle:(NSString*)title andIcon:(UIImage*)icon andSelectedBlock:(CHTumblrMenuViewSelectedBlock)block;
@property(nonatomic,copy)CHTumblrMenuViewSelectedBlock selectedBlock;
@end

@implementation CHTumblrMenuItemButton

+ (id)TumblrMenuItemButtonWithTitle:(NSString*)title andIcon:(UIImage*)icon andSelectedBlock:(CHTumblrMenuViewSelectedBlock)block
{
    CHTumblrMenuItemButton *button = [CHTumblrMenuItemButton buttonWithType:UIButtonTypeCustom];
    [button setImage:icon forState:UIControlStateNormal];
    
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.titleLabel.font = [UIFont systemFontOfSize:12.0];
    button.titleLabel.numberOfLines = 0;
    
    button.selectedBlock = block;
 
    return button;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.width);
    self.titleLabel.frame = CGRectMake(0, self.bounds.size.width, self.bounds.size.width, CHTumblrMenuViewTitleHeight);
}
@end

@implementation CHTumblrMenuView
{
    UIImageView *backgroundView_;
}
@synthesize backgroundImgView = backgroundView_;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UITapGestureRecognizer *ges = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
        ges.delegate = self;
        [self addGestureRecognizer:ges];
        self.backgroundColor = [UIColor clearColor];
        backgroundView_ = [[UIImageView alloc] initWithFrame:self.bounds];
        backgroundView_.backgroundColor = [UIColor clearColor];
        backgroundView_.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:backgroundView_];
        self.buttons = [[NSMutableArray alloc] initWithCapacity:6];
        
        self.columnPerRow = 3;
        self.iconHeight = 72.0;
    }
    return self;
}

- (void)addMenuItemWithTitle:(NSString*)title andIcon:(UIImage*)icon andSelectedBlock:(CHTumblrMenuViewSelectedBlock)block
{
    CHTumblrMenuItemButton *button = [CHTumblrMenuItemButton TumblrMenuItemButtonWithTitle:title andIcon:icon andSelectedBlock:block];
    
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    
    [self.buttons addObject:button];
}

- (CGRect)frameForButtonAtIndex:(NSUInteger)index
{
    NSUInteger rowCount = ceil((CGFloat)self.buttons.count / (CGFloat)self.columnPerRow);
    NSUInteger rowIndex = index / self.columnPerRow;
    
    NSUInteger lastRowColumnCount = ((self.buttons.count % self.columnPerRow) != 0) ? self.buttons.count % self.columnPerRow : self.columnPerRow;
    NSUInteger columnCount = (rowCount == (rowIndex + 1)) ? lastRowColumnCount : self.columnPerRow;
    NSUInteger columnIndex =  index % columnCount;
    
    CGFloat spacing = (self.bounds.size.width - self.iconHeight * columnCount) / (columnCount + 1);
    
    CGFloat offsetX = spacing + (self.iconHeight + spacing) * columnIndex;
    
    CGFloat itemHeight = (self.iconHeight + CHTumblrMenuViewTitleHeight);
    CGFloat offsetY = self.bounds.size.height - ((itemHeight + CHTumblrMenuViewVerticalPadding) * (rowCount - rowIndex));

    return CGRectMake(offsetX, offsetY, self.iconHeight, itemHeight);

}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    for (NSUInteger i = 0; i < self.buttons.count; i++) {
        CHTumblrMenuItemButton *button = self.buttons[i];
        button.frame = [self frameForButtonAtIndex:i];
    }
    
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer.view isKindOfClass:[CHTumblrMenuItemButton class]]) {
        return NO;
    }
    
    CGPoint location = [gestureRecognizer locationInView:self];
    for (UIView* subview in self.buttons) {
        if (CGRectContainsPoint(subview.frame, location)) {
            return NO;
        }
    }
    
    return YES;
}

- (void)dismiss:(id)sender
{
    UITapGestureRecognizer *ges = nil;
    
    if (self.gestureRecognizers.count) {
        ges = self.gestureRecognizers.firstObject;
        ges.enabled = NO;
    }
    
    
    [self dropAnimation];
    double delayInSeconds = CHTumblrMenuViewAnimationTime  + CHTumblrMenuViewAnimationInterval * (self.buttons.count + 1);
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self removeFromSuperview];
        
        if (ges) {
            ges.enabled = YES;
        }
    });
}


- (void)buttonTapped:(CHTumblrMenuItemButton*)btn
{
    [self dismiss:nil];
    double delayInSeconds = CHTumblrMenuViewAnimationTime  + CHTumblrMenuViewAnimationInterval * (self.buttons.count + 1);
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        btn.selectedBlock();

    });
}


- (void)riseAnimation
{
    if (_message.length && self.buttons.count) {
        if (!_messageLabel) {
            _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            _messageLabel.font = [UIFont systemFontOfSize:17.0];
            _messageLabel.textColor = [UIColor whiteColor];
            _messageLabel.textAlignment = NSTextAlignmentCenter;
            _messageLabel.numberOfLines = 0;
            _messageLabel.layer.opacity = 0.0;
            [self addSubview:self.messageLabel];
        }
        
        _messageLabel.text = _message;
        
        CGRect firstButtonFrame = [self frameForButtonAtIndex:0];
        
        CGFloat messagePadding = 20.0;
        
        CGFloat messageWidth = (self.bounds.size.width - messagePadding * 2);
        
        CGSize messageSize = [_messageLabel sizeThatFits:CGSizeMake(messageWidth, CGFLOAT_MAX)];
        
        _messageLabel.frame = CGRectMake(messagePadding, firstButtonFrame.origin.y - CHTumblrMenuViewVerticalPadding - messageSize.height, messageWidth, messageSize.height);
        
        CABasicAnimation *opacityAnimation;
        opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnimation.fromValue = [NSNumber numberWithFloat:0.0];
        opacityAnimation.toValue = [NSNumber numberWithFloat:1.0];
        opacityAnimation.duration = CHTumblrMenuViewAnimationTime;
        opacityAnimation.beginTime = CACurrentMediaTime() + CHTumblrMenuViewAnimationTime;
        opacityAnimation.fillMode = kCAFillModeForwards;
        opacityAnimation.removedOnCompletion = NO;
        [_messageLabel.layer addAnimation:opacityAnimation forKey:@"riseAnimation"];
    }
    
    
    NSUInteger columnCount = self.columnPerRow;
    NSUInteger rowCount = self.buttons.count / columnCount + (self.buttons.count%columnCount>0?1:0);


    for (NSUInteger index = 0; index < self.buttons.count; index++) {
        CHTumblrMenuItemButton *button = self.buttons[index];
        button.layer.opacity = 0;
        CGRect frame = [self frameForButtonAtIndex:index];
        NSUInteger rowIndex = index / columnCount;
        NSUInteger columnIndex = index % columnCount;
        CGPoint fromPosition = CGPointMake(frame.origin.x + self.iconHeight / 2.0,frame.origin.y +  (rowCount - rowIndex + 2)*200 + (self.iconHeight + CHTumblrMenuViewTitleHeight) / 2.0);
        
        CGPoint toPosition = CGPointMake(frame.origin.x + self.iconHeight / 2.0,frame.origin.y + (self.iconHeight + CHTumblrMenuViewTitleHeight) / 2.0);

        double delayInSeconds = rowIndex * columnCount * CHTumblrMenuViewAnimationInterval;
        if (!columnIndex) {
            delayInSeconds += CHTumblrMenuViewAnimationInterval;
        }
        else if(columnIndex == 2) {
            delayInSeconds += CHTumblrMenuViewAnimationInterval * 2;
        }

        CABasicAnimation *positionAnimation;
        
        positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        positionAnimation.fromValue = [NSValue valueWithCGPoint:fromPosition];
        positionAnimation.toValue = [NSValue valueWithCGPoint:toPosition];
        positionAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.45f :1.2f :0.75f :1.0f];
        positionAnimation.duration = CHTumblrMenuViewAnimationTime;
        positionAnimation.beginTime = [button.layer convertTime:CACurrentMediaTime() fromLayer:nil] + delayInSeconds;
        [positionAnimation setValue:[NSNumber numberWithUnsignedInteger:index] forKey:CHTumblrMenuViewRriseAnimationID];
        positionAnimation.delegate = self;
        
        [button.layer addAnimation:positionAnimation forKey:@"riseAnimation"];


        
    }
}

- (void)dropAnimation
{
    if (_messageLabel) {
        CABasicAnimation *opacityAnimation;
        opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnimation.fromValue = [NSNumber numberWithFloat:1.0];
        opacityAnimation.toValue = [NSNumber numberWithFloat:0.0];
        opacityAnimation.duration = CHTumblrMenuViewAnimationTime;
        opacityAnimation.beginTime = CACurrentMediaTime() + CHTumblrMenuViewAnimationTime;
        opacityAnimation.fillMode = kCAFillModeBackwards;
        opacityAnimation.removedOnCompletion = NO;
        [_messageLabel.layer addAnimation:opacityAnimation forKey:@"riseAnimation"];
        
        
    }
    
    
    NSUInteger columnCount = self.columnPerRow;
    NSUInteger rowCount = self.buttons.count / columnCount + (self.buttons.count%columnCount>0?1:0);
    
    
    for (NSUInteger index = 0; index < self.buttons.count; index++) {
        CHTumblrMenuItemButton *button = self.buttons[index];
        CGRect frame = [self frameForButtonAtIndex:index];
        NSUInteger rowIndex = index / columnCount;
        NSUInteger columnIndex = index % columnCount;

        CGPoint toPosition = CGPointMake(frame.origin.x + self.iconHeight / 2.0,frame.origin.y +  (rowCount - rowIndex + 2)*200 + (self.iconHeight + CHTumblrMenuViewTitleHeight) / 2.0);
        
        CGPoint fromPosition = CGPointMake(frame.origin.x + self.iconHeight / 2.0,frame.origin.y + (self.iconHeight + CHTumblrMenuViewTitleHeight) / 2.0);
        
        double delayInSeconds = rowIndex * columnCount * CHTumblrMenuViewAnimationInterval;
        if (!columnIndex) {
            delayInSeconds += CHTumblrMenuViewAnimationInterval;
        }
        else if(columnIndex == 2) {
            delayInSeconds += CHTumblrMenuViewAnimationInterval * 2;
        }
        CABasicAnimation *positionAnimation;
        
        positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        positionAnimation.fromValue = [NSValue valueWithCGPoint:fromPosition];
        positionAnimation.toValue = [NSValue valueWithCGPoint:toPosition];
        positionAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.3 :0.5f :1.0f :1.0f];
        positionAnimation.duration = CHTumblrMenuViewAnimationTime;
        positionAnimation.beginTime = [button.layer convertTime:CACurrentMediaTime() fromLayer:nil] + delayInSeconds;
        [positionAnimation setValue:[NSNumber numberWithUnsignedInteger:index] forKey:CHTumblrMenuViewDismissAnimationID];
        positionAnimation.delegate = self;
        
        [button.layer addAnimation:positionAnimation forKey:@"riseAnimation"];
        
        
        
    }

}

- (void)animationDidStart:(CAAnimation *)anim
{
    NSUInteger columnCount = self.columnPerRow;
    if([anim valueForKey:CHTumblrMenuViewRriseAnimationID]) {
        NSUInteger index = [[anim valueForKey:CHTumblrMenuViewRriseAnimationID] unsignedIntegerValue];
        UIView *view = self.buttons[index];
        CGRect frame = [self frameForButtonAtIndex:index];
        CGPoint toPosition = CGPointMake(frame.origin.x + self.iconHeight / 2.0,frame.origin.y + (self.iconHeight + CHTumblrMenuViewTitleHeight) / 2.0);
        CGFloat toAlpha = 1.0;
        
        view.layer.position = toPosition;
        view.layer.opacity = toAlpha;
        
    }
    else if([anim valueForKey:CHTumblrMenuViewDismissAnimationID]) {
        NSUInteger index = [[anim valueForKey:CHTumblrMenuViewDismissAnimationID] unsignedIntegerValue];
        NSUInteger rowIndex = index / columnCount;
        NSUInteger columnCount = self.columnPerRow;
        NSUInteger rowCount = self.buttons.count / columnCount + (self.buttons.count%columnCount>0?1:0);

        UIView *view = self.buttons[index];
        CGRect frame = [self frameForButtonAtIndex:index];
        CGPoint toPosition = CGPointMake(frame.origin.x + self.iconHeight / 2.0,frame.origin.y +  (rowCount - rowIndex + 2)*200 + (self.iconHeight + CHTumblrMenuViewTitleHeight) / 2.0);
        
        view.layer.position = toPosition;
    }
}


- (void)show
{
    
    UIViewController *appRootViewController;
    UIWindow *window;
    
    window = [UIApplication sharedApplication].keyWindow;
   
        
    appRootViewController = window.rootViewController;
    
 
    
    UIViewController *topViewController = appRootViewController;
    while (topViewController.presentedViewController != nil)
    {
        topViewController = topViewController.presentedViewController;
    }
    
    if ([topViewController.view viewWithTag:CHTumblrMenuViewTag]) {
        [[topViewController.view viewWithTag:CHTumblrMenuViewTag] removeFromSuperview];
    }
    
    self.frame = topViewController.view.bounds;
    [topViewController.view addSubview:self];
    
    [self riseAnimation];
}


@end
