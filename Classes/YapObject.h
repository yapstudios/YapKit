#import <Foundation/Foundation.h>


/**
 * Utility / Helper methods for various yap objects that get encoded, decoded,'
 * stored in a database and/or initialized from downloaded plists.
**/
@interface YapObject : NSObject

/**
 * Converts the given value to the proper type for a resourceId variable.
**/
+ (NSNumber *)valueAsNumber:(id)value;
+ (NSString *)valueAsString:(id)value;

/**
 * Ensures the given value is of a specific type, converting it if possible.
**/

+ (NSURL *)valueAsURL:(id)value;

+ (NSSet *)valueAsSet:(id)value;
+ (NSSet *)valueAsSetOfNumbers:(id)value;
+ (NSSet *)valueAsSetOfStrings:(id)value;

+ (NSArray *)valueAsArray:(id)value;
+ (NSArray *)valueAsArrayOfNumbers:(id)value;
+ (NSArray *)valueAsArrayOfStrings:(id)value;

@end
