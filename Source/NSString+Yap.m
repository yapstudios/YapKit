#import "NSString+Yap.h"
#import <CommonCrypto/CommonHMAC.h>


@implementation NSString (Yap)

- (NSString *)deCamelizeWith:(NSString *)delimiter
{
	NSCharacterSet *capitals = [NSCharacterSet uppercaseLetterCharacterSet];
	
	unichar *buffer = calloc([self length], sizeof(unichar));
	[self getCharacters:buffer];
	
	NSMutableString *underscored = [NSMutableString string];
	
	NSString *currChar;
	for (int i = 0; i < [self length]; i++)
	{
		currChar = [NSString stringWithCharacters:buffer+i length:1];
		if([capitals characterIsMember:buffer[i]]) {
			[underscored appendFormat:@"%@%@", delimiter, [currChar lowercaseString]];
		} else {
			[underscored appendString:currChar];
		}
	}
	
	free(buffer);
	return underscored;
}

- (NSString *) stringCollapsingCharacterSet: (NSCharacterSet *) characterSet toCharacter: (unichar) ch {
	NSUInteger fullLength = [self length];
	NSUInteger length = 0;
	unichar *newString = malloc(sizeof(unichar) * (fullLength + 1));
	
	BOOL isInCharset = NO;
	for (int i = 0; i < fullLength; i++) {
        unichar thisChar = [self characterAtIndex: i];
		
        if ([characterSet characterIsMember: thisChar]) {
			isInCharset = YES;
        }
        else {
			if (isInCharset) {
				newString[length++] = ch;
			}
			
			newString[length++] = thisChar;
			isInCharset = NO;
        }
	}
	
	newString[length] = '\0';
	
	NSString *result = [NSString stringWithCharacters: newString length: length];
	
	free(newString);
	
	return result;
}

+ (NSString *)stringWithContentsOfArray:(NSArray *)array separatedByString:(NSString *)separator
{
	NSMutableString *result = [NSMutableString string];
	[array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if (idx > 0)
			[result appendString:separator];
		[result appendString:obj];
	}];
	return [result length] ? [NSString stringWithString:result] : nil;
}

@end
