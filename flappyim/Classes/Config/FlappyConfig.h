//
//  FlappyConfig.h
//  Pods
//
//  Created by lijunlin on 2019/8/9.
//

#ifndef FlappyConfig_h
#define FlappyConfig_h


//当前的设备类型
#define  DEVICE_TYPE   @"IOS"



//基础地址
#define BaseUrl @"http://49.234.106.91"



//上传文件的地址
#define URL_uploadUrl [NSString stringWithFormat:@"%@/upload/fileUpload",BaseUrl]

//创建账户
#define URL_register [NSString stringWithFormat:@"%@/api/register",BaseUrl]

//登录账号
#define URL_login [NSString stringWithFormat:@"%@/api/login",BaseUrl]

//退出账号
#define URL_logout [NSString stringWithFormat:@"%@/api/logout",BaseUrl]

//自动登录账号
#define URL_autoLogin [NSString stringWithFormat:@"%@/api/autoLogin",BaseUrl]

//创建会话
#define URL_createSingleSession [NSString stringWithFormat:@"%@/api/createSingleSession",BaseUrl]

//获取单聊会话
#define URL_getSingleSession [NSString stringWithFormat:@"%@/api/getSingleSession",BaseUrl]


//创建多人会话
#define URL_createGroupSession [NSString stringWithFormat:@"%@/api/createGroupSession",BaseUrl]

//获取多人会话
#define URL_getSessionByID [NSString stringWithFormat:@"%@/api/getSessionByID",BaseUrl]

//添加用户到会话
#define URL_addUserToSession [NSString stringWithFormat:@"%@/api/addUserToSession",BaseUrl]

//删除会话中的用户
#define URL_delUserInSession [NSString stringWithFormat:@"%@/api/delUserInSession",BaseUrl]





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
#define  RESULT_FILEERR   6




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




#endif /* FlappyConfig_h */
