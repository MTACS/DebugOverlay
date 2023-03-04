#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include "dlfcn.h"

@interface UIColor (DebugOverlay) 
+ (id)tableCellGroupedBackgroundColor;
@end

@interface _UIStatusBarStringView : UILabel
@end

@interface _UIStatusBarTimeItem : NSObject
- (id)viewForIdentifier:(id)arg0;
- (void)toggleDebugOverlay;
@end

@interface UIDebuggingInformationOverlayInvokeGestureHandler : NSObject 
+ (id)mainHandler;
- (void)_handleActivationGesture:(id)arg0;
@end

@interface UIDebuggingInformationOverlayViewController : UIViewController
@end

@interface UIDebuggingInformationHierarchyCell : UICollectionViewCell
@property (readonly, nonatomic) UIButton *infoButton;
@end

@interface UIDebuggingInformationHierarchyViewController : UIViewController
@property (retain, nonatomic) UICollectionView *collectionView;
@end

@interface UIDebuggingInformationOverlay : UIWindow
@property (readonly, nonatomic) UIDebuggingInformationOverlayViewController *overlayViewController;
+ (void)prepareDebuggingOverlay;
+ (id)overlay;
- (void)toggleVisibility;
@end

@interface UIDebuggingInformationContainerView : UIView
@property (nonatomic) BOOL shadowHidden;
@end

@interface DebugOverlay: NSObject
+ (void)toggleOverlay;
@end

@implementation DebugOverlay
+ (void)toggleOverlay {
    id debugInfoClass = NSClassFromString(@"UIDebuggingInformationOverlay");
    if (@available(iOS 11.0, *)) {
        id handlerClass = NSClassFromString(@"UIDebuggingInformationOverlayInvokeGestureHandler");

        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            Method initMethod = class_getInstanceMethod(debugInfoClass, @selector(init));
            IMP newInit = method_getImplementation(class_getInstanceMethod([UIWindow class], @selector(init)));
            method_setImplementation(initMethod, newInit);
        });

		id debugOverlayInstance = [debugInfoClass overlay];
		[debugOverlayInstance setFrame:[[UIScreen mainScreen] bounds]];

        UIGestureRecognizer *emptyGesture = [[UIGestureRecognizer alloc] init];
        emptyGesture.state = UIGestureRecognizerStateEnded;

		id handler = [handlerClass mainHandler];
        [handler _handleActivationGesture:emptyGesture];

	} else {
        SEL selector = NSSelectorFromString(@"overlay");
		((void (*)(id, SEL))[debugInfoClass methodForSelector:selector])(debugInfoClass, selector);
	}
}
@end

%group DebugOverlay
%hook UIWindow
%new
- (void)presentDebugOverlay {
	[DebugOverlay toggleOverlay];
}
%end

%hook UIDebuggingInformationRootTableViewController
- (id)initWithStyle:(NSInteger)arg0 {
	return %orig(UITableViewStyleInsetGrouped);
}
%end

%hook UIDebuggingInformationContainerView
- (void)layoutSubviews {
	%orig;
	MSHookIvar<UIView *>(self, "_shadowView").backgroundColor = [UIColor systemBackgroundColor];
}
%end

%hook UIDebuggingInformationHierarchyViewController
- (void)viewDidLayoutSubviews {
	%orig;
	self.collectionView.backgroundColor = [UIColor systemBackgroundColor];
}
%end

%hook UIDebuggingInformationHierarchyCell
- (void)layoutSubviews {
	%orig;
	self.backgroundColor = [UIColor tableCellGroupedBackgroundColor];
}
- (UIButton *)infoButton {
	UIButton *button = %orig;
	button.imageView.tintColor = [UIColor labelColor];
	return button;
}
%end
%end

%ctor {
	%init(DebugOverlay);
}