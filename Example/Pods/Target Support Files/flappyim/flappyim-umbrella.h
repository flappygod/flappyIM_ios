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

#import "FlappyIM.h"
#import "User.h"

FOUNDATION_EXPORT double flappyimVersionNumber;
FOUNDATION_EXPORT const unsigned char flappyimVersionString[];

