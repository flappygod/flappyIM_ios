//
//  FlappyConfig.h
//  Pods
//
//  Created by lijunlin on 2019/8/9.
//

#ifndef FlappyConfig_h
#define FlappyConfig_h


//线上服务器
#define FLAPPY_BASE @"http://139.224.204.128"


//请求出错
#define  RESULT_FAILURE    0
//请求成功
#define  RESULT_SUCCESS    1
//网络问题
#define  RESULT_KNICKED    2
//解析失败
#define  RESULT_JSONERROR  3
//网络问题
#define  RESULT_NETERROR   4
//未登录
#define  RESULT_NOTLOGIN   5
//上传失败
#define  RESULT_PARSE_ERROR   6
//没有数据
#define  RESULT_DATABASE_ERROR  7

//会话用户被禁用
#define RESULT_SESSION_MEMBER_UNABLE 8
//会话被禁用
#define RESULT_SESSION_UNABLE  9
//会话被删除
#define RESULT_SESSION_DELETED  10


//登录消息
#define REQ_LOGIN  1
//请求消息
#define REQ_MSG  2
//心跳消息
#define REQ_PING  3
//已经接收到的消息
#define REQ_RECEIPT  4
//更新消息
#define REQ_UPDATE  5

//消息接收回执
#define RECEIPT_MSG_ARRIVE 1


//登录返回消息
#define RES_LOGIN  1
//消息发送
#define RES_MSG  2
//心跳，没用
#define RES_PING  3
//回执，没用
#define RES_RECEIPT  4
//更新
#define RES_UPDATE  5
//被踢下线
#define RES_KICKED  6


//系统消息动作
#define SYSTEM_MSG_NOTICE 0


//更新用户
#define SYSTEM_MSG_MEMBER_UPDATE 1
//删除用户
#define SYSTEM_MSG_MEMBER_DELETE 2
//添加用户
#define SYSTEM_MSG_MEMBER_ADD 3


//更新会话
#define SYSTEM_MSG_SESSION_UPDATE 11
//会话Enable
#define SYSTEM_MSG_SESSION_ENABLE 12
//会话Disable
#define SYSTEM_MSG_SESSION_DISABLE 13
//完全删除会话
#define SYSTEM_MSG_SESSION_DELETE 14
//更新单条会话(仅会话信息，不包含人员信息)
#define SYSTEM_MSG_SESSION_UPDATE_INFO 15


//更新信息
#define REQ_UPDATE_SESSION_BATCH 1


//全局
#define GlobalKey @"Global"


#define FlappyNotificationMessage @"FlappyNotificationMessage"


#endif /* FlappyConfig_h */
