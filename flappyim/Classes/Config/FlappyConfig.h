//
//  FlappyConfig.h
//  Pods
//
//  Created by lijunlin on 2019/8/9.
//

#ifndef FlappyConfig_h
#define FlappyConfig_h


//当前的设备类型
#define  DEVICE_TYPE   @"Ios"

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
#define  RESULT_NO_DATA   7




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

//更新信息
#define UPDATE_SESSION_SGINGLE 1





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


#define GlobalKey @"Global"



#endif /* FlappyConfig_h */
