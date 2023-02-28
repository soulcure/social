//
//  FBNullDataTool.m
//  in_app_purchase
//
//  Created by Soto.Poul on 2021/1/26.
//

#import "FBNullDataTool.h"

@implementation FBNullDataTool

+ (id)replaceNullData:(id)obj
{
    if ([obj isKindOfClass:[NSDictionary class]]) {
        return [self replaceNullWithDictionary:obj];
    } else if ([obj isKindOfClass:[NSArray class]]) {
        return [self replaceNullWithArray:obj];
    } else if ([obj isKindOfClass:[NSNumber class]]) {
        if ([obj isKindOfClass:[NSNull class]] || obj == nil) {
            obj = @(0);
        }
        return obj;
    } else if ([obj isKindOfClass:[NSString class]] || obj == nil) {
        return [self replaceNullValue:obj];
    } else if ([obj isKindOfClass:[NSNull class]]) {
        obj = nil;
    }
    return obj;
}

+ (id)replaceNullWithDictionary:(NSMutableDictionary *)dic
{
    NSMutableDictionary *tempDic = [NSMutableDictionary dictionary];
    NSArray *allKey = [dic allKeys];

    for (NSString *key in allKey) {
        [tempDic setObject:[self replaceNullData:dic[key]] forKey:key];
    }

    return tempDic;
}

+ (id)replaceNullWithArray:(NSMutableArray *)arr
{
    __block NSMutableArray *tempArr = [NSMutableArray array];

    [arr enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [tempArr addObject:[self replaceNullData:obj]];
    }];
    return tempArr;
}

+ (NSString *)replaceNullValue:(NSString *)string
{
    NSString *newStr = [NSString stringWithFormat:@"%@", string];

    if ([newStr isKindOfClass:[NSNull class]] ||
        newStr == nil ||
        [newStr isEqualToString:@"(null)"] ||
        [newStr isEqualToString:@""] ||
        [newStr isEqualToString:@"null"] ||
        [newStr isEqualToString:@"<null>"]) {
        newStr = @"";
    }
    return newStr;
}

@end
