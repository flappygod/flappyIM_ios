//
//  ApiConfig.h
//  Pods
//
//  Created by lijunlin on 2019/8/6.
//

#ifndef ApiConfig_h
#define ApiConfig_h



//当前的设备类型
#define  DEVICE_TYPE   @"IOS"



//基础地址
#define BaseUrl @"http://192.168.124.105"

//创建账户
#define URL_register [NSString stringWithFormat:@"%@/api/register",BaseUrl]

//登录账号
#define URL_login [NSString stringWithFormat:@"%@/api/login",BaseUrl]

//自动登录账号
#define URL_autoLogin [NSString stringWithFormat:@"%@/api/autoLogin",BaseUrl]

//创建两个人之间的会话
#define URL_createSession [NSString stringWithFormat:@"%@/api/createSession",BaseUrl]

//发送消息
#define URL_sendMessage [NSString stringWithFormat:@"%@/api/sendMessage",BaseUrl]




//请求失败
#define  RESULT_FAILURE    0
//请求成功
#define  RESULT_SUCCESS    1
//数据解析失败
#define  RESULT_JSONERROR  2
//网络连接失败
#define  RESULT_NETERROR   3




//登录消息
#define REQ_LOGIN  1
//请求消息
#define REQ_MSG  2
//心跳消息
#define REQ_PING  3



//登录返回消息
#define RES_LOGIN  1

//消息发送
#define RES_MSG  2



#endif /* ApiConfig_h */
