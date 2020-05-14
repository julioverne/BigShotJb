#import <libactivator/libactivator.h>
#import <rocketbootstrap/rocketbootstrap.h>

#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBAlertItemsController.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>

#import <AppSupport/CPDistributedMessagingCenter.h>

#import <dlfcn.h>
#import <objc/runtime.h>

#import "UIWindow+Bigshot.h"
#import "UIView+Toast.h"

#define NSLog(...)

@implementation UIApplication (BigShot)
-(void)captureScreenShot
{
	NSLog(@"captureScreenShot called !!!");
	UIImage *image = [self.keyWindow takeFullScreenShot];
	[[UIPasteboard generalPasteboard] setData:/*UIImagePNGRepresentation(image)*/UIImageJPEGRepresentation(image, 1.0) forPasteboardType:@"bigshot-to-save"];
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
			[NSTimer scheduledTimerWithTimeInterval:1 target:_sharedObject selector:@selector(checkShotSave) userInfo:nil repeats:YES];
		} else if (![blackList containsObject:classString]) {
			[NSTimer scheduledTimerWithTimeInterval:1 target:_sharedObject selector:@selector(checkIfValid) userInfo:nil repeats:YES];
		}
	}
	return _sharedObject;
}
- (void)checkShotSave
{
	NSData *imageData = [[UIPasteboard generalPasteboard] dataForPasteboardType:@"bigshot-to-save"];
	if(imageData && imageData.length>0) {
		[[UIPasteboard generalPasteboard] setData:[NSData data] forPasteboardType:@"bigshot-to-save"];
		UIImageWriteToSavedPhotosAlbum([[UIImage alloc] initWithData:imageData], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
	}
}
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
	if(error == nil) {
 		[[UIApplication sharedApplication].keyWindow makeToast:@"BigShot saved !!!!"];
 	} else {
 		[[UIApplication sharedApplication].keyWindow makeToast:error.localizedDescription];
 	}
}
- (void)checkIfValid
{
	NSString *expected = [NSString stringWithFormat:@"com.tapthaker.bigshotjb-%@", [[NSBundle mainBundle] bundleIdentifier]];
	NSData *takeCMD = [[UIPasteboard generalPasteboard] dataForPasteboardType:expected];
	if(takeCMD && takeCMD.length>0) {
		[[UIPasteboard generalPasteboard] setData:[NSData data] forPasteboardType:expected];
		[self takeScreenshot];
	}
}
- (void)loader
{
	NSLog(@"Loaded");
	return;
}
- (void)takeScreenshot
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSLog(@"- (void)takeScreenshot");
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
		[[UIPasteboard generalPasteboard] setData:[NSData dataWithBytes:"take" length:4] forPasteboardType:[NSString stringWithFormat:@"com.tapthaker.bigshotjb-%@", front.bundleIdentifier]];
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