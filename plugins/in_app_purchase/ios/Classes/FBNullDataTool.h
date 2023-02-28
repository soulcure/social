//
//  FBNullDataTool.h
//  in_app_purchase
//
//  Created by Soto.Poul on 2021/1/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBNullDataTool : NSObject

/**
 空数据容错处理

 @param obj 支持对象  (NSDictionary  NSArray  NSNumber  NSString)
 @return 返回对应的容错空数据
 */
+ (id)replaceNullData:(id)obj;

@end

NS_ASSUME_NONNULL_END
