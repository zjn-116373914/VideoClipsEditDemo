//
//  UIColor+RCColor.h
//  RubikCube
//
//  Created by Artanis Protoss on 2022/11/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (RCColor)
/// 16进制颜色值(RGB)
+(UIColor *)colorWithHexString:(NSString *)color alpha:(float)alpha;

/// 16进制颜色值(RGBA)
+(UIColor *)colorWithHexAString:(NSString *)color;
@end

NS_ASSUME_NONNULL_END
