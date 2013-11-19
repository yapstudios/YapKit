#import <Foundation/Foundation.h>

/**
 * Similar to NSDateFormatter, NSCalendar's are somewhat expensive to create and they are not thread-safe.
 *
 * For speed, we prefer to use Apple's autoupdatingCurrentCalendar, and store it in the thread dictionary.
 * This class helps facilitate this.
**/
@interface YapCalendar : NSObject

/**
 * Contrary to popular belief, [NSCalendar currentCalendar] is NOT a singleton.
 * A new instance is created each time you invoke the method.
 * 
 * Use this method for extra fast access to a NSCalendar instance.
**/
+ (NSCalendar *)cachedAutoupdatingCurrentCalendar;

@end
