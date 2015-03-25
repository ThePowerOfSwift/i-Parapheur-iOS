
#import <Foundation/Foundation.h>

@interface DeviceUtils : NSObject


+ (BOOL)isConnectedToInternet;

+ (void)logError:(NSError *)error;

+ (void)logErrorMessage:(NSString *)message;

+ (void)logErrorMessage:(NSString *)message
				 inView:(UIView *)view;

+ (void)logSuccessMessage:(NSString *)message;

+ (void)logInfoMessage:(NSString *)message;

@end
