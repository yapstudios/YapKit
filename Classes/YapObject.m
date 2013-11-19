#import "YapObject.h"

#import <objc/runtime.h>

@implementation YapObject

+ (NSNumber *)valueAsNumber:(id)value
{
	if ([value isKindOfClass:[NSNumber class]])
	{
		return (NSNumber *)value;
	}
	if ([value isKindOfClass:[NSString class]])
	{
		errno = 0;
		unsigned long long num;
		
		NSCharacterSet *hex = [NSCharacterSet characterSetWithCharactersInString:@"abcdefABCDEF"];
		NSRange hexRange = [(NSString *)value rangeOfCharacterFromSet:hex];
		
		if (hexRange.location != NSNotFound)
			num = strtoull([(NSString *)value UTF8String], NULL, 16);
		else
			num = strtoull([(NSString *)value UTF8String], NULL, 10);
		
		if (errno == 0)
			return [NSNumber numberWithUnsignedLongLong:num];
		else
			return nil;
	}
	
	return nil;
}

+ (NSString *)valueAsString:(id)value
{
	if ([value isKindOfClass:[NSString class]])
	{
		return (NSString *)value;
	}
	if ([value isKindOfClass:[NSNumber class]])
	{
		return [(NSNumber *)value stringValue];
	}
	
	return nil;
}

+ (NSURL *)valueAsURL:(id)value
{
	if ([value isKindOfClass:[NSURL class]])
	{
		return (NSURL *)value;
	}
	if ([value isKindOfClass:[NSString class]])
	{
		return [NSURL URLWithString:(NSString *)value];
	}
	
	return nil;
}

+ (NSSet *)valueAsSet:(id)value
{
	if ([value isKindOfClass:[NSSet class]])
	{
		return (NSSet *)value;
	}
	if ([value isKindOfClass:[NSArray class]])
	{
		return [NSSet setWithArray:(NSArray *)value];
	}
	
	return nil;
}

+ (NSSet *)valueAsSetOfNumbers:(id)value
{
	if (![value isKindOfClass:[NSSet class]] && ![value isKindOfClass:[NSArray class]])
		return nil;
	
	NSMutableSet *set = [NSMutableSet setWithCapacity:[value count]];
	
	for (id object in value)
	{
		NSNumber *number = [self valueAsNumber:object];
		if (number)
		{
			[set addObject:number];
		}
	}
	
	return [set copy];
}

+ (NSSet *)valueAsSetOfStrings:(id)value
{
	if (![value isKindOfClass:[NSSet class]] && ![value isKindOfClass:[NSArray class]])
		return nil;
	
	NSMutableSet *set = [NSMutableSet setWithCapacity:[value count]];
	
	for (id object in value)
	{
		NSString *string = [self valueAsString:object];
		if (string)
		{
			[set addObject:string];
		}
	}
	
	return [set copy];
}

+ (NSArray *)valueAsArray:(id)value
{
	if ([value isKindOfClass:[NSArray class]])
	{
		return (NSArray *)value;
	}
	if ([value isKindOfClass:[NSSet class]])
	{
		return [(NSSet *)value allObjects];
	}
	
	return nil;
}

+ (NSArray *)valueAsArrayOfNumbers:(id)value
{
	if (![value isKindOfClass:[NSArray class]] && ![value isKindOfClass:[NSSet class]])
		return nil;
	
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[value count]];
	
	for (id object in value)
	{
		NSNumber *number = [self valueAsNumber:object];
		if (number)
		{
			[array addObject:number];
		}
	}
	
	return [array copy];
}

+ (NSArray *)valueAsArrayOfStrings:(id)value
{
	if (![value isKindOfClass:[NSArray class]] && ![value isKindOfClass:[NSSet class]])
		return nil;
	
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[value count]];
	
	for (id object in value)
	{
		NSString *string = [self valueAsString:object];
		if (string)
		{
			[array addObject:string];
		}
	}
	
	return [array copy];
}

@end
