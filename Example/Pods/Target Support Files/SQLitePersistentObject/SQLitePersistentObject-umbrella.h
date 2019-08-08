#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "NSData-SQLitePersistence.h"
#import "NSDate-SQLitePersistence.h"
#import "NSMutableArray-MultipleSort.h"
#import "NSMutableData-SQLitePersistence.h"
#import "NSNumber-SQLitePersistence.h"
#import "NSObject-ClassName.h"
#import "NSObject-MissingKV.h"
#import "NSObject-SQLitePersistence.h"
#import "NSString-NumberStuff.h"
#import "NSString-SQLiteColumnName.h"
#import "NSString-SQLitePersistence.h"
#import "NSString-UppercaseFirst.h"
#import "SQLiteInstanceManager.h"
#import "SQLitePersistentObject.h"
#import "UIColor-SQLitePersistentObject.h"
#import "UIImage-SQLitePersistence.h"

FOUNDATION_EXPORT double SQLitePersistentObjectVersionNumber;
FOUNDATION_EXPORT const unsigned char SQLitePersistentObjectVersionString[];

