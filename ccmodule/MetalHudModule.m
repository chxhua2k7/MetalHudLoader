#import <UIKit/UIKit.h>
#import <notify.h>
#import "../shared.h"

@interface CCUIToggleModule : NSObject
@property (nonatomic, getter=isSelected) BOOL selected;
@end

@interface MetalHudModule : CCUIToggleModule
@end

@implementation MetalHudModule

// The token is intentionally never cancelled: notifyd drops a name's state
// once its last registration goes away.
static int stateToken(void) {
    static int token = NOTIFY_TOKEN_INVALID;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        if (notify_register_check(kMHLEnabledStateName, &token) != NOTIFY_STATUS_OK) {
            token = NOTIFY_TOKEN_INVALID;
        }
    });
    return token;
}

- (UIImage *)iconGlyph {
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:24
                                                                                          weight:UIImageSymbolWeightRegular
                                                                                           scale:UIImageSymbolScaleLarge];
    return [UIImage systemImageNamed:@"gauge" withConfiguration:config];
}

- (UIColor *)selectedColor {
    return UIColor.systemGreenColor;
}

- (BOOL)isSelected {
    uint64_t state = MHLStateUnset;
    int token = stateToken();
    if (token != NOTIFY_TOKEN_INVALID) {
        notify_get_state(token, &state);
    }
    return state != MHLStateDisabled;
}

- (void)setSelected:(BOOL)selected {
    int token = stateToken();
    if (token != NOTIFY_TOKEN_INVALID) {
        notify_set_state(token, selected ? MHLStateEnabled : MHLStateDisabled);
    }

    [@{ @kMHLEnabledKey: @(selected) } writeToFile:@kMHLPrefsPath atomically:YES];

    [super setSelected:selected];

    if (selected) {
        [self spinGlyph];
    }
}

// The glyph image view isn't exposed by CCUIToggleModule, so walk the
// button's view hierarchy instead of relying on private subview names.
static void collectImageViews(UIView *view, NSMutableArray<UIImageView *> *out) {
    if ([view isKindOfClass:UIImageView.class]) {
        [out addObject:(UIImageView *)view];
    }
    for (UIView *subview in view.subviews) {
        collectImageViews(subview, out);
    }
}

- (void)spinGlyph {
    // CCUIToggleModule has no contentViewController getter; its view
    // controllers live in the private _contentViewControllers hash table.
    // Everything here is best-effort: on any surprise, skip the animation
    // rather than take down SpringBoard.
    NSMutableArray<UIImageView *> *glyphViews = [NSMutableArray new];
    @try {
        id viewControllers = [self valueForKey:@"contentViewControllers"];
        if (![viewControllers respondsToSelector:@selector(allObjects)]) {
            return;
        }
        for (id viewController in [viewControllers allObjects]) {
            if (![viewController isKindOfClass:UIViewController.class]) {
                continue;
            }
            UIView *contentView = ((UIViewController *)viewController).viewIfLoaded;
            if (contentView) {
                collectImageViews(contentView, glyphViews);
            }
        }
    } @catch (NSException *exception) {
        return;
    }

    CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    spin.fromValue = @0;
    spin.toValue = @(2 * M_PI);
    spin.duration = 0.6;
    spin.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    for (UIImageView *glyphView in glyphViews) {
        [glyphView.layer addAnimation:spin forKey:@"mhl.spin"];
    }
}

@end
