//
//  SocketConnector.h
//  AFNetworking
//
//  Created by lijunlin on 2019/8/17.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import "FlappyApiRequest.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import "ChatMessage.h"
#import "ChatUser.h"
#import "Flappy.pbobjc.h"
#import "FlappyChatSession.h"
#import "FlappyApiRequest.h"
#import "FlappySocket.h"


@interface FlappySocket : NSObject<GCDAsyncSocketDelegate>


//socket通信
@property (nonatomic,strong)  GCDAsyncSocket*  socket;
//成功
@property (nonatomic,strong)  FlappySuccess  success;
//失败
@property (nonatomic,strong)  FlappyFailure  failure;
//正在登录的用户
@property (nonatomic,strong)  ChatUser*  user;
//登录成功之后非正常退出的情况
@property (nonatomic,strong)  FlappyDead  dead;
//登录的数据
@property (nonatomic,strong)  id  loginData;
//正在更新的数据
@property (nonatomic,strong)  NSMutableArray*  updateArray;


//进行初始化
-(instancetype)initWithSuccess:(FlappySuccess)success
                    andFailure:(FlappyFailure)failure
                       andDead:(FlappyDead)dead;

//建立长连接
-(void)connectSocket:(NSString*)serverAddress
            withPort:(NSString*)serverPort
            withUser:(ChatUser*)user;

//主动下线
-(void)offline:(Boolean)regular;


@end

