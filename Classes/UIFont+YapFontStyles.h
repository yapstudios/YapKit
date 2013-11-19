#import <Foundation/Foundation.h>


// System Font
extern NSString *UIFontStrings_SystemFontNormal;
extern NSString *UIFontStrings_SystemFontBold;

// Custom Font 1
extern NSString *UIFontStrings_YapFontLight;
extern NSString *UIFontStrings_YapFontBook;
extern NSString *UIFontStrings_YapFontNormal;
extern NSString *UIFontStrings_YapFontMedium;
extern NSString *UIFontStrings_YapFontHeavy;
extern NSString *UIFontStrings_YapFontBold;

// Custom Font 2
extern NSString *UIFontStrings_YapFont2Book;
extern NSString *UIFontStrings_YapFont2Bold;
extern NSString *UIFontStrings_YapFont2DisplayMedium;
extern NSString *UIFontStrings_YapFont2DisplayMediumAlt;
extern NSString *UIFontStrings_YapFont2DisplayBold;
extern NSString *UIFontStrings_YapFont2DisplayBoldAlt;
extern NSString *UIFontStrings_YapFont2DisplayTilting;

// Custom Font 3
extern NSString *UIFontStrings_YapFont3DisplayTilting;

@interface UIFont (Nice)

// Custom Font 1
+ (UIFont *)yapFontLightOfSize:(CGFloat)inSize;
+ (UIFont *)yapFontBookOfSize:(CGFloat)inSize;
+ (UIFont *)yapFontNormalOfSize:(CGFloat)inSize;
+ (UIFont *)yapFontMediumOfSize:(CGFloat)inSize;
+ (UIFont *)yapFontHeavyOfSize:(CGFloat)inSize;
+ (UIFont *)yapFontBoldOfSize:(CGFloat)inSize;

// Custom Font 2
+ (UIFont *)yapFont2BookOfSize:(CGFloat)inSize;
+ (UIFont *)yapFont2BoldOfSize:(CGFloat)inSize;
+ (UIFont *)yapFont2DisplayMediumOfSize:(CGFloat)inSize;
+ (UIFont *)yapFont2DisplayMediumAltOfSize:(CGFloat)inSize;
+ (UIFont *)yapFont2DisplayBoldOfSize:(CGFloat)inSize;
+ (UIFont *)yapFont2DisplayBoldAltOfSize:(CGFloat)inSize;
+ (UIFont *)yapFont2DisplayTiltingOfSize:(CGFloat)inSize; // Info on tilting fonts: http://www.fonts.com/content/learning/fyti/typefaces/titling

// Custom Font 3
+ (UIFont *)yapFont3DisplayTiltingOfSize:(CGFloat)inSize; // Info on tilting fonts: http://www.fonts.com/content/learning/fyti/typefaces/titling

@end
