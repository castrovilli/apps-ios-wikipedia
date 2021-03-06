//  Created by Monte Hurd on 2/3/14.

#import "UIViewController+HideKeyboard.h"
#import "AppDelegate.h"

@implementation UIViewController (HideKeyboard)

-(void)hideKeyboard
{
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIViewController *rootVC = appDelegate.window.rootViewController;
    [rootVC recurseSubVCs];
}

-(void)recurseSubVCs
{
    [self recurseSubviewsOfView:self.view];
    for (UIViewController *subVC in self.childViewControllers) {
        [subVC recurseSubVCs];
    }
}

-(void)recurseSubviewsOfView:(UIView *)view
{
    if ([view respondsToSelector:@selector(isFirstResponder)]) {
        if (view.isFirstResponder) {
            if ([view respondsToSelector:@selector(resignFirstResponder)]) {
                if (view.canResignFirstResponder) {
                    [view resignFirstResponder];
                }
            }
        }
    }
    for (UIView *subView in view.subviews) {
        [self recurseSubviewsOfView:subView];
    }
}

@end
