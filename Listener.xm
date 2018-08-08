#import <libactivator/libactivator.h>
#import <rocketbootstrap/rocketbootstrap.h>

#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBAlertItemsController.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>

#import <AppSupport/CPDistributedMessagingCenter.h>

#import <dlfcn.h>
#import <objc/runtime.h>

#import "UIWindow+BigShot.h"
#import "UIView+Toast.h"

#define NSLog(...)

@implementation UIApplication (BigShot)
-(void)captureScreenShot
{
	NSLog(@"captureScreenShot called !!!");
	UIImage *image = [self.keyWindow takeFullScreenShot];
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
}
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
	if(error == nil) {
 		[self.keyWindow makeToast:@"BigShot saved !!!!"];
 	} else {
 		[self.keyWindow makeToast:error.localizedDescription];
 	}
}
@end

@interface BigShotListener : NSObject <LAListener>
@end

@implementation BigShotListener
__strong static id _sharedObject;
static NSArray *blackList = [@[ @"MailAppController", @"FBWildeApplication" ] copy];
+ (id)sharedInstance
{
	if (!_sharedObject) {
		_sharedObject = [[self alloc] init];
		NSString *classString = NSStringFromClass([[UIApplication sharedApplication] class]);
		if ([@"SpringBoard" isEqualToString:classString]) {
			NSLog(@"Registering SpringBoard for activator events");
			[_sharedObject RegisterActions];
		} else if (![blackList containsObject:classString]) {
			CPDistributedMessagingCenter *c = [CPDistributedMessagingCenter centerNamed:[NSString stringWithFormat:@"com.tapthaker.bigshotjb-%@", [[NSBundle mainBundle] bundleIdentifier]]];
			rocketbootstrap_distributedmessagingcenter_apply(c);
			[c registerForMessageName:@"captureScreenShot" target:_sharedObject selector:@selector(takeScreeshot)];
			[c runServerOnCurrentThread];
		}
	}
	return _sharedObject;
}
- (void)loader
{
	NSLog(@"Loaded");
	return;
}
- (void)takeScreeshot
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[UIApplication sharedApplication] captureScreenShot];
	});
}
- (void)RegisterActions
{
    if (access("/usr/lib/libactivator.dylib", F_OK) == 0) {
		dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	    if (Class la = objc_getClass("LAActivator")) {
			[[la sharedInstance] registerListener:(id<LAListener>)self forName:@"com.tapthaker.bigshotjb"];
		}
	}
}
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
	SBApplication *front = (SBApplication*) [(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
	if(front) {
		CPDistributedMessagingCenter *c = [CPDistributedMessagingCenter centerNamed:[NSString stringWithFormat:@"com.tapthaker.bigshotjb-%@", front.bundleIdentifier]];
		rocketbootstrap_distributedmessagingcenter_apply(c);
		[c sendMessageName:@"captureScreenShot" userInfo:nil];
	}
	event.handled = YES;
}
- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName
{
	return @"BigShot";
}
- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName
{
	return @"Capture BigShot";
}
- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName
{
	return @"Captures a full-screen screenshot, including the vertical scrollable area";
}
- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName
{
	return [NSArray arrayWithObjects:@"application", nil];
}
@end


%ctor
{
	[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		[[BigShotListener sharedInstance] loader];
	}];
}