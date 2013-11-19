#import "YapCalendar.h"


@implementation YapCalendar

+ (NSCalendar *)cachedAutoupdatingCurrentCalendar
{
	NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
	NSCalendar *calendar = [threadDictionary objectForKey:@"autoupdatingCurrentCalendar"];
	
	if (calendar == nil)
	{
		calendar = [NSCalendar autoupdatingCurrentCalendar];
		[threadDictionary setObject:calendar forKey:@"autoupdatingCurrentCalendar"];
	}
	
	return calendar;
}

@end
