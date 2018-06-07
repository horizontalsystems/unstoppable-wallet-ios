// CoreBitcoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#endif

@interface BTCQRCode : NSObject

#if TARGET_OS_IPHONE
/*!
 * Returns a QR code image with a given size.
 * The `string` is typically a bitcoin address in Base58Check format.
 */
+ (UIImage*) imageForString:(NSString*)string size:(CGSize)size scale:(CGFloat)scale;

/*!
 * Returns a QR code image with a given size.
 * The `url` is typically a bitcoin payment request "bitcoin:<address>?amount=..."
 */
+ (UIImage*) imageForURL:(NSURL*)url size:(CGSize)size scale:(CGFloat)scale;

/*!
 * Returns a scanning view and retains a detection block.
 *
 * Block is called for every QR code detected. To stop recognition, remove view from the window.
 *
 * Block is released when view is removed from window.
 */
+ (UIView*) scannerViewWithBlock:(void(^)(NSString* message))detectionBlock;


/*!
 * Returns a scanning view and retains a detection block.
 *
 * Block is called for every QR code detected. To stop recognition, remove view from the window.
 *
 * Block is released when view is removed from window.
 *
 * The device position helps selecting the camera (front or back)
 */
+ (UIView*) scannerViewUsingDevice:(AVCaptureDevicePosition) devicePosition
                       orientation:(AVCaptureVideoOrientation) orientation
                             block:(void(^)(NSString* message))detectionBlock;
#endif

@end
