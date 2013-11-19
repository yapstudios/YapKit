#import <Foundation/Foundation.h>

// These are automatically optimized by the compiler.
// Readability is key.

#define FIVE_MINUTES    (60.0 * 5.0)
#define TEN_MINTUES    (60.0 * 10.0)
#define TWENTY_MINTUES (60.0 * 20.0)
#define THIRTY_MINUTES (60.0 * 30.0)
#define FORTY_MINUTES  (60.0 * 40.0)
#define FIFTY_MINUTES  (60.0 * 50.0)

#define HALF_HOUR      THIRTY_MINUTES
#define ONE_HOUR       (60.0 * 60.0)

#define ONE_DAY        (60.0 * 60.0 * 24.0)


@interface NSDate (YapHelper)

- (BOOL)isEarlierThanDate:(NSDate *)another;
- (BOOL)isLaterThanDate:(NSDate *)another;

- (BOOL)isEarlierOrEqualToDate:(NSDate *)another;
- (BOOL)isLaterOrEqualToDate:(NSDate *)another;

- (BOOL)isSameDayAsDate:(NSDate *)inDate;

+ (BOOL)isDate:(NSDate *)date inRangeFrom:(NSDate *)rangeStartDate interval:(NSTimeInterval)rangeInterval;

- (NSInteger)year;
- (NSInteger)month;
- (NSInteger)day;
- (NSInteger)weekday;
- (NSInteger)hour;
- (NSInteger)minute;
- (NSInteger)second;

- (NSDate *)startOfHour;
- (NSDate *)middleOfHour;
- (NSDate *)startOfDay;

- (NSDate *)nextOrThisDayWithWeekday:(NSUInteger)inWeekday;

- (NSString *)timeSinceNowString;
- (NSString *)timeSinceNowCondensedString;
- (NSString *)timeSinceLastUpdateString;

+ (NSString *)stringForDisplayFromPastEvent:(NSDate *)date;

@end
