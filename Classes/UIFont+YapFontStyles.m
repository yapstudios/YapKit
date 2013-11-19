#import "UIFont+YapFontStyles.h"


// System Font
const NSString *UIFontStrings_SystemFontNormal = @"HelveticaNeue";
const NSString *UIFontStrings_SystemFontBold = @"HelveticaNeue-Bold";

// Custom Font 1
const NSString *UIFontStrings_YapFontLight = @"HelveticaNeue";
const NSString *UIFontStrings_YapFontBook = @"HelveticaNeue";
const NSString *UIFontStrings_YapFontNormal = @"HelveticaNeue";
const NSString *UIFontStrings_YapFontMedium = @"HelveticaNeue-Medium";
const NSString *UIFontStrings_YapFontHeavy = @"HelveticaNeue-Bold";
const NSString *UIFontStrings_YapFontBold = @"HelveticaNeue-Bold";

// Custom Font 2
const NSString *UIFontStrings_YapFont2Book = @"NeutrafaceText-Book";
const NSString *UIFontStrings_YapFont2Bold = @"NeutrafaceText-Bold";
const NSString *UIFontStrings_YapFont2DisplayMedium = @"NeutrafaceDisplay-Medium";
const NSString *UIFontStrings_YapFont2DisplayMediumAlt = @"NeutrafaceDisplay-MediumAlt";
const NSString *UIFontStrings_YapFont2DisplayBold = @"NeutrafaceDisplay-Bold";
const NSString *UIFontStrings_YapFont2DisplayBoldAlt = @"NeutrafaceDisplay-BoldAlt";
const NSString *UIFontStrings_YapFont2DisplayTilting = @"NeutrafaceDisplay-Titling";

// Custom Font 3
const NSString *UIFontStrings_YapFont3DisplayTilting = @"Neutraface2Display-Titling";

@implementation UIFont (Nice)


// Custom Font 1
+ (UIFont *)yapFontLightOfSize:(CGFloat)inSize;
{
	return [UIFont fontWithName:(NSString *)UIFontStrings_YapFontLight size:inSize];
}

+ (UIFont *)yapFontBookOfSize:(CGFloat)inSize;
{
	return [UIFont fontWithName:(NSString *)UIFontStrings_YapFontBook size:inSize];
    
}

+ (UIFont *)yapFontNormalOfSize:(CGFloat)inSize;
{
	return [UIFont fontWithName:(NSString *)UIFontStrings_YapFontNormal size:inSize];
}

+ (UIFont *)yapFontMediumOfSize:(CGFloat)inSize;
{
	return [UIFont fontWithName:(NSString *)UIFontStrings_YapFontMedium size:inSize];
}

+ (UIFont *)yapFontHeavyOfSize:(CGFloat)inSize;
{
	return [UIFont fontWithName:(NSString *)UIFontStrings_YapFontHeavy size:inSize];
}

+ (UIFont *)yapFontBoldOfSize:(CGFloat)inSize;
{
	return [UIFont fontWithName:(NSString *)UIFontStrings_YapFontBold size:inSize];
}

// Custom Font 2
+ (UIFont *)yapFont2BookOfSize:(CGFloat)inSize;
{
	return [UIFont fontWithName:(NSString *)UIFontStrings_YapFont2Book size:inSize];
}

+ (UIFont *)yapFont2BoldOfSize:(CGFloat)inSize;
{
	return [UIFont fontWithName:(NSString *)UIFontStrings_YapFont2Bold size:inSize];
}

+ (UIFont *)yapFont2DisplayMediumOfSize:(CGFloat)inSize;
{
	return [UIFont fontWithName:(NSString *)UIFontStrings_YapFont2DisplayMedium size:inSize];
}

+ (UIFont *)yapFont2DisplayBoldOfSize:(CGFloat)inSize;
{
	return [UIFont fontWithName:(NSString *)UIFontStrings_YapFont2DisplayBold size:inSize];
}

+ (UIFont *)yapFont2DisplayMediumAltOfSize:(CGFloat)inSize;
{
	return [UIFont fontWithName:(NSString *)UIFontStrings_YapFont2DisplayMediumAlt size:inSize];
}

+ (UIFont *)yapFont2DisplayBoldAltOfSize:(CGFloat)inSize;
{
	return [UIFont fontWithName:(NSString *)UIFontStrings_YapFont2DisplayBoldAlt size:inSize];
}

+ (UIFont *)yapFont2DisplayTiltingOfSize:(CGFloat)inSize;
{
	return [UIFont fontWithName:(NSString *)UIFontStrings_YapFont2DisplayTilting size:inSize];
}

// Custom Font 3
+ (UIFont *)yapFont3DisplayTiltingOfSize:(CGFloat)inSize;
{
	return [UIFont fontWithName:(NSString *)UIFontStrings_YapFont3DisplayTilting size:inSize];
}

@end
