#import "NSDate+YapHelper.h"
#import "YapDateFormatter.h"
#import "YapCalendar.h"


@implementation NSDate (Hour)

- (BOOL)isEarlierThanDate:(NSDate *)another
{
	NSComparisonResult cmp = [self compare:another];
	
	// [receiver compare:anotherDate] :
	//
	// NSOrderedSame       : The receiver and anotherDate are exactly equal to each other.
	// NSOrderedDescending : The receiver is later in time than anotherDate.
	// NSOrderedAscending  : The receiver is earlier in time than anotherDate.
	
	return (cmp == NSOrderedAscending);
}

- (BOOL)isLaterThanDate:(NSDate *)another
{
	NSComparisonResult cmp = [self compare:another];
	
	// [receiver compare:anotherDate] :
	// 
	// NSOrderedSame       : The receiver and anotherDate are exactly equal to each other.
	// NSOrderedDescending : The receiver is later in time than anotherDate.
	// NSOrderedAscending  : The receiver is earlier in time than anotherDate.
	
	return (cmp == NSOrderedDescending);
}

- (BOOL)isEarlierOrEqualToDate:(NSDate *)another
{
	// IMPORTANT : The implementation of earlierDate & laterDate does NOT match the documentation.
	// It is uncertain if Apple will correct the implementation or documentation.
	// Thus it is best to avoid these methods.
	
	NSComparisonResult cmp = [self compare:another];
	
	// [receiver compare:anotherDate] :
	//
	// NSOrderedSame       : The receiver and anotherDate are exactly equal to each other.
	// NSOrderedDescending : The receiver is later in time than anotherDate.
	// NSOrderedAscending  : The receiver is earlier in time than anotherDate.
	
	return (cmp != NSOrderedDescending);
}

- (BOOL)isLaterOrEqualToDate:(NSDate *)another
{
	// IMPORTANT : The implementation of earlierDate & laterDate does NOT match the documentation.
	// It is uncertain if Apple will correct the implementation or documentation.
	// Thus it is best to avoid these methods.
	
	NSComparisonResult cmp = [self compare:another];
	
	// [receiver compare:anotherDate] :
	//
	// NSOrderedSame       : The receiver and anotherDate are exactly equal to each other.
	// NSOrderedDescending : The receiver is later in time than anotherDate.
	// NSOrderedAscending  : The receiver is earlier in time than anotherDate.
	
	return (cmp != NSOrderedAscending);
}

- (BOOL)isSameDayAsDate:(NSDate *)another
{
	if (another == nil) return NO;
	
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	
	NSUInteger components = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	
	NSDateComponents *selfDateComponents = [calendar components:components fromDate:self];
	NSDateComponents *anotherDateComponents = [calendar components:components fromDate:another];
	
	return [selfDateComponents day]   == [anotherDateComponents day]
	    && [selfDateComponents month] == [anotherDateComponents month]
	    && [selfDateComponents year]  == [anotherDateComponents year];
}

+ (BOOL)isDate:(NSDate *)date inRangeFrom:(NSDate *)rangeStartDate interval:(NSTimeInterval)rangeInterval
{
	NSTimeInterval dateInterval = [date timeIntervalSinceDate:rangeStartDate];
	
	return ((dateInterval >= 0.0) && (dateInterval < rangeInterval));
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Date Components
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)year
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	return [[calendar components:NSYearCalendarUnit fromDate:self] year];
}

- (NSInteger)month
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	return [[calendar components:NSMonthCalendarUnit fromDate:self] month];
}

- (NSInteger)day
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	return [[calendar components:NSDayCalendarUnit fromDate:self] day];
}

- (NSInteger)weekday
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	return [[calendar components:NSWeekdayCalendarUnit fromDate:self] weekday];
}

- (NSInteger)hour
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	return [[calendar components:NSHourCalendarUnit fromDate:self] hour];
}

- (NSInteger)minute
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	return [[calendar components:NSMinuteCalendarUnit fromDate:self] minute];
}

- (NSInteger)second
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	return [[calendar components:NSSecondCalendarUnit fromDate:self] second];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Time Rounding
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSDate *)startOfHour
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	
	NSUInteger components = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit;
	
	NSDateComponents *dateComponents = [calendar components:components fromDate:self];
	
	if (dateComponents.minute == 0 && dateComponents.second == 0)
	{
		return self;
	}
	else
	{
		[dateComponents setMinute:0];
		[dateComponents setSecond:0];
		
		return [calendar dateFromComponents:dateComponents];
	}
}

- (NSDate *)middleOfHour
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	
	NSUInteger components = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit;
	
	NSDateComponents *dateComponents = [calendar components:components fromDate:self];
	
	if (dateComponents.minute == 30 && dateComponents.second == 0)
	{
		return self;
	}
	else
	{
		[dateComponents setMinute:30];
		[dateComponents setSecond:0];
		
		return [calendar dateFromComponents:dateComponents];
	}
}

- (NSDate *)startOfDay
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	
	NSUInteger components = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit;
	
	NSDateComponents *dateComponents = [calendar components:components fromDate:self];
	
	if (dateComponents.hour == 0 && dateComponents.minute == 0 && dateComponents.second == 0)
	{
		return self;
	}
	else
	{
		[dateComponents setHour:0];
		[dateComponents setMinute:0];
		[dateComponents setSecond:0];
	
		return [calendar dateFromComponents:dateComponents];
	}
}

- (NSDate *)nextOrThisDayWithWeekday:(NSUInteger)inWeekday
{
	// Fet the current date index
	NSUInteger thisIndex = [self weekday];
	
	// ASSUME: unifiorm 7-day-per-week calendar
	
	// Get how many days ago we should look.
	NSUInteger daysUntilThen = (inWeekday - thisIndex + 7) % 7;
	
	// Compute the new date using seconds
	return [[NSDate alloc] initWithTimeInterval:daysUntilThen * 24 * 60.0 * 60.0 sinceDate:self];
	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Strings
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *)timeSinceNowString
{
	// Calculate time string(s)
	
	NSTimeInterval ti = [self timeIntervalSinceNow] * -1.0; // num seconds in the past (1 min ago = +60)
	
	if (ti < 90) { // Under 90 seconds ago, let's just say "now"
		ti = 0;
	}
	
	ti = ti/60;
	NSUInteger minutes = (NSUInteger) ti % 60;
	ti = ti/60;
	NSUInteger hours = (NSUInteger) ti % 24;
	ti = ti/24;
	NSUInteger days = (NSUInteger) ti;
	ti = ti/7;
	NSUInteger weeks = (NSUInteger) ti;
	
	NSString *frmt = nil;
	NSString *result = nil;
	
	if (weeks > 1)
	{
		frmt = NSLocalizedString(@"%d weeks ago", @"Relative time indicator for age of object");
		result = [NSString stringWithFormat:frmt, days];
	}
	else if (weeks == 1)
	{
		result = NSLocalizedString(@"1 week ago", @"");
	}
	else if (days > 1) // If this is NOT supposed to be "else if", then document it as so.
	                   // Otherwise one would mistake it as a bug, and eagerly "fix" it.
	{
		frmt = NSLocalizedString(@"%d days ago", @"Relative time indicator for age of object");
		result = [NSString stringWithFormat:frmt, days];
	}
	else if (days == 1)
	{
		result = NSLocalizedString(@"1 day ago", @"");
	}
	else if (hours > 1)
	{
		frmt = NSLocalizedString(@"%d hours ago", @"Relative time indicator for age of object");
		result = [NSString stringWithFormat:frmt, hours];
	}
	else if (hours == 1)
	{
		result = NSLocalizedString(@"1 hour ago", @"");
	}
	else if (minutes > 1)
	{
		frmt = NSLocalizedString(@"%d minutes ago", @"Relative time indicator for age of object");
		result = [NSString stringWithFormat:frmt, minutes];
	}
	else if (minutes == 1)
	{
		result = NSLocalizedString(@"1 minute ago", @"Relative time indicator for age of object");
	}
	else
	{
	//	frmt = NSLocalizedString(@"%d secs", @"Relative time indicator for age of object");
	//	result = [NSString stringWithFormat:frmt, seconds];
		
		result = NSLocalizedString(@"Just now", @"Relative time indicator for age of object");
	}
	
	return result;
}

- (NSString *)timeSinceNowAbbreviated
{
	// Calculate time string(s)
	
	NSTimeInterval ti = [self timeIntervalSinceNow] * -1.0; // num seconds in the past (1 min ago = +60)
	
	if (ti < 90) { // Under 90 seconds ago, let's just say "now"
		ti = 0;
	}
	
	ti = ti/60;
	NSUInteger minutes = (NSUInteger) ti % 60;
	ti = ti/60;
	NSUInteger hours = (NSUInteger) ti % 24;
	ti = ti/24;
	NSUInteger days = (NSUInteger) ti;
	ti = ti/7;
	NSUInteger weeks = (NSUInteger) ti;
	
	NSString *frmt = nil;
	NSString *result = nil;
	
	if (weeks > 1)
	{
		frmt = NSLocalizedString(@"%dw ago", @"Relative time indicator for age of object");
		result = [NSString stringWithFormat:frmt, days];
	}
	else if (weeks == 1)
	{
		result = NSLocalizedString(@"1w ago", @"");
	}
	else if (days > 1) // If this is NOT supposed to be "else if", then document it as so.
		// Otherwise one would mistake it as a bug, and eagerly "fix" it.
	{
		frmt = NSLocalizedString(@"%dd ago", @"Relative time indicator for age of object");
		result = [NSString stringWithFormat:frmt, days];
	}
	else if (days == 1)
	{
		result = NSLocalizedString(@"1d ago", @"");
	}
	else if (hours > 1)
	{
		frmt = NSLocalizedString(@"%dh ago", @"Relative time indicator for age of object");
		result = [NSString stringWithFormat:frmt, hours];
	}
	else if (hours == 1)
	{
		result = NSLocalizedString(@"1h ago", @"");
	}
	else if (minutes > 1)
	{
		frmt = NSLocalizedString(@"%dm ago", @"Relative time indicator for age of object");
		result = [NSString stringWithFormat:frmt, minutes];
	}
	else if (minutes == 1)
	{
		result = NSLocalizedString(@"1m ago", @"Relative time indicator for age of object");
	}
	else
	{
		//	frmt = NSLocalizedString(@"%d secs", @"Relative time indicator for age of object");
		//	result = [NSString stringWithFormat:frmt, seconds];
		
		result = NSLocalizedString(@"<1m ago", @"Relative time indicator for age of object");
	}
	
	return result;
}

- (NSString *)timeSinceNowCondensedString
{
	// Calculate time string(s)
	
	NSTimeInterval ti = [self timeIntervalSinceNow] * -1.0; // num seconds in the past (1 min ago = +60)
	
	if (ti < 90) { // Under 90 seconds ago, let's just say "now"
		ti = 0;
	}
	
	ti = ti/60;
	NSUInteger minutes = (NSUInteger) ti % 60;
	ti = ti/60;
	NSUInteger hours = (NSUInteger) ti % 24;
	ti = ti/24;
	NSUInteger days = (NSUInteger) ti;
	ti = ti/7;
	NSUInteger weeks = (NSUInteger) ti;
	
	NSString *frmt = nil;
	NSString *result = nil;
	
	if (weeks > 1)
	{
		frmt = NSLocalizedString(@"%d weeks", @"Relative time indicator for age of object");
		result = [NSString stringWithFormat:frmt, days];
	}
	else if (weeks == 1)
	{
		result = NSLocalizedString(@"1 week", @"");
	}
	else if (days > 1) // If this is NOT supposed to be "else if", then document it as so.
	                   // Otherwise one would mistake it as a bug, and eagerly "fix" it.
	{
		frmt = NSLocalizedString(@"%d days", @"Relative time indicator for age of object");
		result = [NSString stringWithFormat:frmt, days];
	}
	else if (days == 1)
	{
		result = NSLocalizedString(@"1 day", @"");
	}
	else if (hours > 1)
	{
		frmt = NSLocalizedString(@"%d hours", @"Relative time indicator for age of object");
		result = [NSString stringWithFormat:frmt, hours];
	}
	else if (hours == 1)
	{
		result = NSLocalizedString(@"1 hour", @"");
	}
	else if (minutes > 1)
	{
		frmt = NSLocalizedString(@"%d mins", @"Relative time indicator for age of object");
		result = [NSString stringWithFormat:frmt, minutes];
	}
	else if (minutes == 1)
	{
		result = NSLocalizedString(@"1 min", @"Relative time indicator for age of object");
	}
	else
	{
		result = NSLocalizedString(@"Just now", @"Relative time indicator for age of object");
	}
	
	return result;
}

/**
 * Use this for "Last updated X components ago" string.
**/
- (NSString *)timeSinceLastUpdateString
{
	// Calculate time string(s)
	
	NSTimeInterval ti = [self timeIntervalSinceNow] * -1.0; // num seconds in the past (1 min ago = +60)
	
	if (ti < 90) { // Under 90 seconds ago, let's just say "now"
		ti = 0;
	}
	
	ti = ti/60;
	NSUInteger minutes = (NSUInteger) ti % 60;
	ti = ti/60;
	NSUInteger hours = (NSUInteger) ti % 24;
	ti = ti/24;
	NSUInteger days = (NSUInteger) ti;
	ti = ti/7;
	NSUInteger weeks = (NSUInteger) ti;
	
	NSString *frmt = nil;
	NSString *result = nil;
	
	if (weeks > 1)
	{
		frmt = NSLocalizedString(@"Last updated %d weeks ago", @"Relative time indicator of time since last update");
		result = [NSString stringWithFormat:frmt, days];
	}
	else if (weeks == 1)
	{
		result = NSLocalizedString(@"Last updated 1 week ago", @"");
	}
	else if (days > 1) // If this is NOT supposed to be "else if", then document it as so.
	                   // Otherwise one would mistake it as a bug, and eagerly "fix" it.
	{
		frmt = NSLocalizedString(@"Last updated %d days ago", @"Relative time indicator of time since last update");
		result = [NSString stringWithFormat:frmt, days];
	}
	else if (days == 1)
	{
		result = NSLocalizedString(@"Last updated 1 day ago", @"Relative time indicator of time since last update");
	}
	else if (hours > 1)
	{
		frmt = NSLocalizedString(@"Last updated %d hours ago", @"Relative time indicator of time since last update");
		result = [NSString stringWithFormat:frmt, hours];
	}
	else if (hours == 1)
	{
		result = NSLocalizedString(@"Last updated 1 hour ago", @"Relative time indicator of time since last update");
	}
	else if (minutes > 1)
	{
		frmt = NSLocalizedString(@"Last updated %d minutes ago", @"Relative time indicator of time since last update");
		result = [NSString stringWithFormat:frmt, minutes];
	}
	else if (minutes == 1)
	{
		result = NSLocalizedString(@"Last updated 1 minute ago", @"Relative time indicator of time since last update");
	}
	else
	{
		result = NSLocalizedString(@"Just updated", @"Relative time indicator of time since last update");
	}
	
	return result;
}

+ (NSString *)stringForDisplayFromPastEvent:(NSDate *)date
{
	// If the date is in today, display 12-hour time with meridian.
	// If it is within the last 7 days, display weekday name (Friday).
	// If within the calendar year, display as Jan 23.
	// Else display as Nov 11, 2008
	
	NSDate *today = [NSDate date];
	
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	
	NSUInteger components = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDateComponents *dateComponents = [calendar components:components fromDate:today];
	dateComponents.hour = 0;
	dateComponents.minute = 0;
	dateComponents.second = 0;
	
	NSDate *midnight = [calendar dateFromComponents:dateComponents];
	
	if ([date compare:midnight] == NSOrderedDescending)
	{
		// Date was today.
		// Display using hour and minute (in proper localized form).
		
		NSDateFormatter *df = [YapDateFormatter localizedDateFormatterFromTemplate:@"jm"]; // 11:30 AM
		return [df stringFromDate:date];
	}
	else
	{
		// Is date within last 7 days?
		
		NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
		[componentsToSubtract setDay:-7];
		
		NSDate *lastweek = [calendar dateByAddingComponents:componentsToSubtract toDate:today options:0];
		
		if ([date compare:lastweek] == NSOrderedDescending)
		{
			NSDateFormatter *df = [YapDateFormatter dateFormatterWithLocalizedFormat:@"EEEE"]; // Tuesday
			return [df stringFromDate:date];
		}
		else
		{
			// Is date within same same calendar year?
			
			NSInteger thisYear = [dateComponents year];
			
			dateComponents = [calendar components:components fromDate:date];
			NSInteger dateYear = [dateComponents year];
			
			if (dateYear == thisYear)
			{
				NSDateFormatter *df = [YapDateFormatter localizedDateFormatterFromTemplate:@"MMM d"]; // May 4
				return [df stringFromDate:date];
			}
			else
			{
				NSDateFormatter *df = [YapDateFormatter localizedDateFormatterFromTemplate:@"MMM d YYYY"]; // ^, 2011
				return [df stringFromDate:date];
			}
		}
	}
}

@end
