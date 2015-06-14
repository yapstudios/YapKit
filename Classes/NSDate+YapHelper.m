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
	
	NSUInteger components = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
	
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
	return [[calendar components:NSCalendarUnitYear fromDate:self] year];
}

- (NSInteger)month
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	return [[calendar components:NSCalendarUnitMonth fromDate:self] month];
}

- (NSInteger)day
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	return [[calendar components:NSCalendarUnitDay fromDate:self] day];
}

- (NSInteger)weekday
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	return [[calendar components:NSCalendarUnitWeekday fromDate:self] weekday];
}

- (NSInteger)hour
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	return [[calendar components:NSCalendarUnitHour fromDate:self] hour];
}

- (NSInteger)minute
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	return [[calendar components:NSCalendarUnitMinute fromDate:self] minute];
}

- (NSInteger)second
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	return [[calendar components:NSCalendarUnitSecond fromDate:self] second];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Time Rounding
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSDate *)startOfHour
{
	NSCalendar *calendar = [YapCalendar cachedAutoupdatingCurrentCalendar];
	
	NSUInteger components = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour;
	
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
	
	NSUInteger components = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour;
	
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
	
	NSUInteger components = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour;
	
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
		frmt = NSLocalizedStringFromTable(@"%d weeks ago", @"YapKit", @"{Number} weeks ago");
		result = [NSString stringWithFormat:frmt, days];
	}
	else if (weeks == 1)
	{
		result = NSLocalizedStringFromTable(@"1 week ago", @"YapKit", @"1 week ago");
	}
	else if (days > 1) // If this is NOT supposed to be "else if", then document it as so.
	                   // Otherwise one would mistake it as a bug, and eagerly "fix" it.
	{
		frmt = NSLocalizedStringFromTable(@"%d days ago", @"YapKit", @"{Number} days ago");
		result = [NSString stringWithFormat:frmt, days];
	}
	else if (days == 1)
	{
		result = NSLocalizedStringFromTable(@"1 day ago", @"YapKit", @"1 day ago");
	}
	else if (hours > 1)
	{
		frmt = NSLocalizedStringFromTable(@"%d hours ago", @"YapKit", @"{Number} hours ago");
		result = [NSString stringWithFormat:frmt, hours];
	}
	else if (hours == 1)
	{
		result = NSLocalizedStringFromTable(@"1 hour ago", @"YapKit", @"1 hour ago");
	}
	else if (minutes > 1)
	{
		frmt = NSLocalizedStringFromTable(@"%d minutes ago", @"YapKit", @"{Number} minutes ago");
		result = [NSString stringWithFormat:frmt, minutes];
	}
	else if (minutes == 1)
	{
		result = NSLocalizedStringFromTable(@"1 minute ago", @"YapKit", @"1 minute ago");
	}
	else
	{
	//	frmt = NSLocalizedStringFromTable(@"%d secs", @"YapKit", @"Relative time indicator for age of object");
	//	result = [NSString stringWithFormat:frmt, seconds];
		
		result = NSLocalizedStringFromTable(@"Just now", @"YapKit", @"Happened only a moment ago");
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
		frmt = NSLocalizedStringFromTable(@"%dw ago", @"YapKit", @"Abbreviated: {Number}w ago ({Number} weeks ago)");
		result = [NSString stringWithFormat:frmt, days];
	}
	else if (weeks == 1)
	{
		result = NSLocalizedStringFromTable(@"1w ago", @"YapKit", @"Abbreviated: 1w ago (1 week ago)");
	}
	else if (days > 1) // If this is NOT supposed to be "else if", then document it as so.
		// Otherwise one would mistake it as a bug, and eagerly "fix" it.
	{
		frmt = NSLocalizedStringFromTable(@"%dd ago", @"YapKit", @"Abbreviated: {Number}d ago ({Number} days ago)");
		result = [NSString stringWithFormat:frmt, days];
	}
	else if (days == 1)
	{
		result = NSLocalizedStringFromTable(@"1d ago", @"YapKit", @"Abbreviated: 1d ago (1 day ago)");
	}
	else if (hours > 1)
	{
		frmt = NSLocalizedStringFromTable(@"%dh ago", @"YapKit", @"Abbreviated: {Number}h ago ({Number} hours ago)");
		result = [NSString stringWithFormat:frmt, hours];
	}
	else if (hours == 1)
	{
		result = NSLocalizedStringFromTable(@"1h ago", @"YapKit", @"Abbreviated: 1h ago (1 hour ago)");
	}
	else if (minutes > 1)
	{
		frmt = NSLocalizedStringFromTable(@"%dm ago", @"YapKit", @"Abbreviated: {Number}m ago ({Number} minutes ago)");
		result = [NSString stringWithFormat:frmt, minutes];
	}
	else if (minutes == 1)
	{
		result = NSLocalizedStringFromTable(@"1m ago", @"YapKit", @"Abbreviated: 1m ago (1 minute ago)");
	}
	else
	{
		//	frmt = NSLocalizedStringFromTable(@"%d secs", @"YapKit", @"Relative time indicator for age of object");
		//	result = [NSString stringWithFormat:frmt, seconds];
		
		result = NSLocalizedStringFromTable(@"<1m ago", @"YapKit", @"Abbreviated: <1h ago (less than 1 hour ago)");
	}
	
	return result;
}

- (NSString *)timeSinceNowCondensedString
{
	NSDate *now = [NSDate date];
	NSTimeInterval timePassed = ceil([now timeIntervalSinceDate:self]);
	
	NSString *timeString = nil;
	NSString *justNowString = NSLocalizedStringFromTable(@"just now", @"YapKit", @"Happened only a moment ago");
	BOOL shouldAddPluralizer = NO;
	
	if (timePassed > 60 * 60 * 24 * 7 * 4 * 12) { //greater than a year
		timePassed = timePassed / 60.0 / 60.0 / 24.0 / 7.0 / 4.0 / 12.0;
		timeString = NSLocalizedStringFromTable(@"year", @"YapKit", @"year abbr.");
		shouldAddPluralizer = YES;
	} else if (timePassed > 60 * 60 * 24 * 7 * 4) { //greater than a month
		timePassed = timePassed / 60.0 / 60.0 / 24.0 / 7.0 / 4.0;
		timeString = NSLocalizedStringFromTable(@"month", @"YapKit", @"month abbr.");
		shouldAddPluralizer = YES;
	} else if (timePassed > 60 * 60 * 24 * 7) { //greater than a week
		timePassed = timePassed / 60.0 / 60.0 / 24.0 / 7.0;
		timeString = NSLocalizedStringFromTable(@"week", @"YapKit", @"week abbr.");
		shouldAddPluralizer = YES;
	} else if (timePassed > 60 * 60 * 24) { //greater than a day
		timePassed = timePassed / 60.0 / 60.0 / 24.0;
		timeString = NSLocalizedStringFromTable(@"day", @"YapKit", @"day abbr.");
		shouldAddPluralizer = YES;
	} else if (timePassed > 60 * 60) { //greater than an hour
		timePassed = timePassed / 60.0 / 60.0;
		timeString = NSLocalizedStringFromTable(@"hr", @"YapKit", @"hour abbr.");
		shouldAddPluralizer = YES;
	} else if (timePassed > 60) { //greater than a minute
		timePassed = timePassed / 60.0;
		timeString = NSLocalizedStringFromTable(@"min", @"YapKit", @"minute abbr.");
		shouldAddPluralizer = NO;
	} else {
		timePassed = 0;
		timeString = justNowString;
	}
	
	NSString *timestampString = [timeString copy];
	NSString *durationString = [[NSString alloc] initWithFormat:@"%i", (int)timePassed];
	
	if (![timeString isEqualToString:justNowString]) {
		timestampString = [NSString stringWithFormat:@"%@\u00a0%@", durationString, timeString];
	}
	
	if ((int)timePassed != 1 && shouldAddPluralizer) {
		timestampString = [NSString stringWithFormat:@"%@s", timestampString];
	}
	
	return timestampString;
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
		frmt = NSLocalizedStringFromTable(@"Last updated %d weeks ago", @"YapKit", @"Relative time indicator of time since last update");
		result = [NSString stringWithFormat:frmt, days];
	}
	else if (weeks == 1)
	{
		result = NSLocalizedStringFromTable(@"Last updated 1 week ago", @"YapKit", @"");
	}
	else if (days > 1) // If this is NOT supposed to be "else if", then document it as so.
	                   // Otherwise one would mistake it as a bug, and eagerly "fix" it.
	{
		frmt = NSLocalizedStringFromTable(@"Last updated %d days ago", @"YapKit", @"Relative time indicator of time since last update");
		result = [NSString stringWithFormat:frmt, days];
	}
	else if (days == 1)
	{
		result = NSLocalizedStringFromTable(@"Last updated 1 day ago", @"YapKit", @"Relative time indicator of time since last update");
	}
	else if (hours > 1)
	{
		frmt = NSLocalizedStringFromTable(@"Last updated %d hours ago", @"YapKit", @"Relative time indicator of time since last update");
		result = [NSString stringWithFormat:frmt, hours];
	}
	else if (hours == 1)
	{
		result = NSLocalizedStringFromTable(@"Last updated 1 hour ago", @"YapKit", @"Relative time indicator of time since last update");
	}
	else if (minutes > 1)
	{
		frmt = NSLocalizedStringFromTable(@"Last updated %d minutes ago", @"YapKit", @"Relative time indicator of time since last update");
		result = [NSString stringWithFormat:frmt, minutes];
	}
	else if (minutes == 1)
	{
		result = NSLocalizedStringFromTable(@"Last updated 1 minute ago", @"YapKit", @"Relative time indicator of time since last update");
	}
	else
	{
		result = NSLocalizedStringFromTable(@"Just updated", @"YapKit", @"Relative time indicator of time since last update");
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
	
	NSUInteger components = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
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
