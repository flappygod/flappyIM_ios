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

#import "ChatImage.h"
#import "ChatMessage.h"
#import "ChatSession.h"
#import "ChatUser.h"
#import "ChatVoice.h"
#import "Flappy.pbobjc.h"
#import "FlappyBaseSession.h"
#import "FlappyIM.h"
#import "FlappySession.h"
#import "PostTool.h"
#import "SessionGroupData.h"
#import "SessionSingleData.h"

FOUNDATION_EXPORT double flappyimVersionNumber;
FOUNDATION_EXPORT const unsigned char flappyimVersionString[];

