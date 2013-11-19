#import "YapDateFormatter.h"


@implementation YapDateFormatter

/**
 * This method is extensively documented in the header file.
 * Please please please read the header file.
**/
+ (NSDateFormatter *)localizedDateFormatterFromTemplate:(NSString *)templateString
{
	NSString *localizedDateFormatString = [NSDateFormatter dateFormatFromTemplate:templateString
	                                                                      options:0
	                                                                       locale:[NSLocale currentLocale]];
	
	return [self dateFormatterWithLocalizedFormat:localizedDateFormatString timeZone:nil cache:YES];
}

/**
 * This method is extensively documented in the header file.
 * Please please please read the header file.
**/
+ (NSDateFormatter *)localizedDateFormatterFromTemplate:(NSString *)templateString
                                                  cache:(BOOL)shouldCacheInThreadDictionary
{
	NSString *localizedDateFormatString = [NSDateFormatter dateFormatFromTemplate:templateString
	                                                                      options:0
	                                                                       locale:[NSLocale currentLocale]];
	
	return [self dateFormatterWithLocalizedFormat:localizedDateFormatString timeZone:nil cache:YES];
}

/**
 * See header file for extensive documentation.
**/
+ (NSDateFormatter *)dateFormatterWithLocalizedFormat:(NSString *)localizedDateFormatString
{
	return [self dateFormatterWithLocalizedFormat:localizedDateFormatString timeZone:nil cache:YES];
}

/**
 * See header file for extensive documentation.
**/
+ (NSDateFormatter *)dateFormatterWithLocalizedFormat:(NSString *)localizedDateFormatString timeZone:(NSTimeZone *)tz
{
	return [self dateFormatterWithLocalizedFormat:localizedDateFormatString timeZone:tz cache:YES];
}

/**
 * See header file for extensive documentation.
**/
+ (NSDateFormatter *)dateFormatterWithLocalizedFormat:(NSString *)localizedDateFormatString
                                                cache:(BOOL)shouldCacheInThreadDictionary
{
	return [self dateFormatterWithLocalizedFormat:localizedDateFormatString
	                                     timeZone:nil
	                                        cache:shouldCacheInThreadDictionary];
}

/**
 * See header file for extensive documentation.
**/
+ (NSDateFormatter *)dateFormatterWithLocalizedFormat:(NSString *)localizedDateFormatString
                                             timeZone:(NSTimeZone *)timeZone
                                                cache:(BOOL)shouldCacheInThreadDictionary
{
    if (shouldCacheInThreadDictionary)
    {
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSDateFormatter *dateFormatter = [threadDictionary objectForKey:localizedDateFormatString];
        
        if (dateFormatter == nil)
        {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = localizedDateFormatString;
            
            if (timeZone)
            {
                dateFormatter.timeZone = timeZone;
                
                NSString *key = [NSString stringWithFormat:@"%@-%@", localizedDateFormatString, [timeZone name]];
                [threadDictionary setObject:dateFormatter forKey:key];
            }
            else
            {
                [threadDictionary setObject:dateFormatter forKey:localizedDateFormatString];
            }
        }
        
        return dateFormatter;
    }
    else
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = localizedDateFormatString;
        if (timeZone)
            dateFormatter.timeZone = timeZone;
        
        return dateFormatter;
    }
}

@end
