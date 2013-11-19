#import <Foundation/Foundation.h>

/**
 * NSDateFormatter instances are expensive to create and they are not thread-safe.
 * Apple recommends creating them once, and storing them in the thread dictionary.
 * This class helps facilitate this.
**/
@interface YapDateFormatter : NSObject

/**
 * A template is NOT a specific format. It is ONLY a list of included format specifiers.
 * To be clear:
 *
 * This is --NOT-- a template: "MM/dd/yy hh:ss"    <-- BAD !!! NOT a template !!!
 * 
 * 
 * EXAMPLE 1:
 * If you wanted to display the time to the user (hours + minutes), the template would be:
 * 
 * TIME TEMPLATE = "jm" --> j = preferred hour format (either h or H), m = minutes
 * 
 * The result may be something like "h:m a", "H:m", or "H-m" depending on locale.
 *
 * Notice the last format uses the proper '-' character instead of ':'.
 * This highlights why templates only specify desired format specifiers.
 * 
 * EXAMPLE 2:
 * If you wanted to display the date to the user (month, day, weekday), the template would be:
 * 
 * DATE TEMPLATE = "EdMMM" --> E = day of week (Tues), d = day of month, MMM = month (Sept)
 * 
 * The result for en_US : "EEE, MMM d"
 * The result for en_GB : "EEE d MMM"
 * 
 * The template is passed to the built-in [NSDateFormatter dateFormatFromTemplate:options:locale:] method.
 * 
 * After converting the date format template to the current locale,
 * this method invokes dateFormatterWithLocalizedFormat:timeZone:cache:
 * and passes a nil timeZone and YES for the cache parameter.
 * 
 * IMPORTANT NOTE:
 *
 * You MUST NOT change the formatter that is returned to you.
 * Do NOT change the date format!
 * Do NOT change the timeZone!
**/
+ (NSDateFormatter *)localizedDateFormatterFromTemplate:(NSString *)templateStringWithoutAnyFormatting;

/**
 * A template is NOT a specific format. It is ONLY a list of included format specifiers.
 * To be clear:
 *
 * This is --NOT-- a template: "MM/dd/yy hh:ss"    <-- BAD !!! NOT a template !!!
 * 
 * 
 * For a full discussion, see localizedDateFormatterFromTemplate.
 *
 * After converting the date format template to the current locale,
 * this method invokes dateFormatterWithLocalizedFormat:timeZone:cache:.
 * 
 * IMPORTANT NOTE:
 *
 * IF you choose to cache the formatter, then you MUST NOT change the formatter that is returned to you.
 * Do NOT change the date format!
 * Do NOT change the timeZone!
**/
+ (NSDateFormatter *)localizedDateFormatterFromTemplate:(NSString *)templateStringWithoutAnyFormatting
                                                  cache:(BOOL)shouldCacheInThreadDictionary;

/**
 * Given an alreday-localized date format string, returns a proper NSDateFormatter instance.
 * 
 * If a pre-cached version already exists for this thread, it is returned.
 * Otherwise a new NSDateFormatter instance is created, cached, and returned.
 * 
 * IMPORTANT NOTE:
 *
 * You MUST NOT change the formatter that is returned to you.
 * Do NOT change the date format!
 * Do NOT change the timeZone!
**/
+ (NSDateFormatter *)dateFormatterWithLocalizedFormat:(NSString *)localizedDateFormatString;

/**
 * Given an alreday-localized date format string, and optional timeZone, returns a proper NSDateFormatter instance.
 *
 * If a timeZone is passed, then the returned dateFormatter will have its timeZone set to the given timeZone.
 * This is particularly useful if you're parsing strings without timezone information, but which are in a known tz.
 *
 * If a pre-cached version already exists for this thread, it is returned.
 * Otherwise a new NSDateFormatter instance is created, cached, and returned.
 * 
 * IMPORTANT NOTE:
 *
 * You MUST NOT change the formatter that is returned to you.
 * Do NOT change the date format!
 * Do NOT change the timeZone!
**/
+ (NSDateFormatter *)dateFormatterWithLocalizedFormat:(NSString *)localizedDateFormatString timeZone:(NSTimeZone *)tz;

/**
 * Given an already-localized date format string, returns a proper NSDateFormatter instance.
 *
 * If the shouldCacheInThreadDictionary is YES,
 * this method will cache NSDateFormatter instances in the thread dictionary.
 * Otherwise a new NSDateFormatter instance is created.
 * 
 * IMPORTANT NOTE:
 *
 * IF you choose to cache the formatter, then you MUST NOT change the formatter that is returned to you.
 * Do NOT change the date format!
 * Do NOT change the timeZone!
**/
+ (NSDateFormatter *)dateFormatterWithLocalizedFormat:(NSString *)localizedDateFormatString
                                                cache:(BOOL)shouldCacheInThreadDictionary;

/**
 * Given an already-localized date format string, returns a proper NSDateFormatter instance.
 * 
 * If a timeZone is passed, then the returned dateFormatter will have its timeZone set to the given timeZone.
 * This is particularly useful if you're parsing strings without timezone information, but which are in a known tz.
 * 
 * If the shouldCacheInThreadDictionary is YES,
 * this method will cache NSDateFormatter instances in the thread dictionary.
 * Otherwise a new NSDateFormatter instance is created.
 * 
 * IMPORTANT NOTE:
 *
 * IF you choose to cache the formatter, then you MUST NOT change the formatter that is returned to you.
 * Do NOT change the date format!
 * Do NOT change the timeZone!
**/
+ (NSDateFormatter *)dateFormatterWithLocalizedFormat:(NSString *)localizedDateFormatString
                                             timeZone:(NSTimeZone *)timeZone
                                                cache:(BOOL)shouldCacheInThreadDictionary;

@end
