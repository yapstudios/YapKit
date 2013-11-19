#import <Foundation/Foundation.h>


@interface NSString (Yap)

- (NSString *)deCamelizeWith:(NSString *)delimiter;

- (NSString *)md5Hash;

- (NSString *) stringCollapsingCharacterSet: (NSCharacterSet *) characterSet toCharacter: (unichar) ch;

+ (NSString *)stringWithContentsOfArray:(NSArray *)array separatedByString:(NSString *)separator;

@end
