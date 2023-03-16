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

#import "ChatFile.h"
#import "ChatImage.h"
#import "ChatLocation.h"
#import "ChatMessage.h"
#import "ChatSession.h"
#import "ChatSystem.h"
#import "ChatUser.h"
#import "ChatVideo.h"
#import "ChatVoice.h"
#import "Flappy.pbobjc.h"
#import "FlappyApiRequest.h"
#import "FlappyBaseSession.h"
#import "FlappyBlocks.h"
#import "FlappyChatSession.h"
#import "FlappyFailureWrap.h"
#import "FlappyIM.h"
#import "FlappySocket.h"
#import "SessionData.h"

FOUNDATION_EXPORT double flappyimVersionNumber;
FOUNDATION_EXPORT const unsigned char flappyimVersionString[];

