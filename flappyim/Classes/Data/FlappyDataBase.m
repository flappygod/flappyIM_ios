//
//  DataBase.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import "FlappyDataBase.h"
#import "FMDatabaseQueue.h"
#import "FlappyStringTool.h"
#import "FlappyJsonTool.h"
#import "SessionData.h"
#import "MJExtension.h"
#import "FlappyData.h"
#import "FMDatabase.h"

//数据库
@implementation FlappyDataBase{
    NSInteger openCount;
    FMDatabase* database;
}

//使用单例模式
+ (instancetype)shareInstance {
    static FlappyDataBase *_sharedSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //不能再使用alloc方法
        //因为已经重写了allocWithZone方法，所以这里要调用父类的分配空间的方法
        _sharedSingleton = [[super allocWithZone:NULL] init];
    });
    return _sharedSingleton;
}


//防止外部调用alloc或者new
+(instancetype)allocWithZone:(struct _NSZone *)zone {
    return [FlappyDataBase shareInstance];
}

// 防止外部调用copy
- (id)copyWithZone:(nullable NSZone *)zone {
    return [FlappyDataBase shareInstance];
}

// 防止外部调用mutableCopy
- (id)mutableCopyWithZone:(nullable NSZone *)zone {
    return [FlappyDataBase shareInstance];
}

//初始化数据库
-(void)setup{
    //获取db
    [self openDB];
    
    //消息表
    NSString *sql = @"create table if not exists message ("
    "messageId TEXT,"
    "messageSessionId TEXT,"
    "messageSessionType INTEGER,"
    "messageSessionOffset INTEGER,"
    "messageTableOffset INTEGER,"
    "messageType INTEGER ,"
    "messageSendId TEXT,"
    "messageSendExtendId TEXT,"
    "messageReceiveId TEXT,"
    "messageReceiveExtendId TEXT,"
    "messageContent TEXT,"
    "messageSendState INTEGER,"
    "messageReadState INTEGER,"
    "messageSecret TEXT,"
    "isDelete INTEGER,"
    "messageDeleteOperation TEXT,"
    "messageDeleteUserList TEXT,"
    "messageDate TEXT,"
    "messageStamp INTEGER,"
    "deleteDate TEXT,"
    "messageInsertUser TEXT,"
    "primary key (messageId,messageInsertUser))";
    
    //会话表
    NSString *sqlTwo=@"create table if not exists session ("
    "sessionId TEXT,"
    "sessionExtendId TEXT,"
    "sessionType INTEGER,"
    "sessionInfo TEXT,"
    "sessionName TEXT,"
    "sessionImage TEXT,"
    "sessionOffset TEXT,"
    "sessionStamp INTEGER,"
    "sessionCreateDate TEXT,"
    "sessionCreateUser TEXT,"
    "sessionDeleted INTEGER,"
    "sessionDeletedDate TEXT,"
    "sessionInsertUser TEXT,"
    "primary key (sessionId,sessionInsertUser))";
    
    //会话用户表
    NSString *sqlThree=@"create table if not exists session_member ("
    "userId TEXT,"
    "userExtendId TEXT,"
    "userName TEXT,"
    "userAvatar TEXT,"
    "userData TEXT,"
    "userCreateDate TEXT,"
    "userLoginDate TEXT,"
    "sessionId TEXT,"
    "sessionMemberLatestRead TEXT,"
    "sessionMemberLatestDelete TEXT,"
    "sessionMemberMarkName TEXT,"
    "sessionMemberMute INTEGER,"
    "sessionMemberPinned INTEGER,"
    "sessionJoinDate TEXT,"
    "sessionLeaveDate TEXT,"
    "isLeave INTEGER,"
    "sessionInsertUser TEXT,"
    "primary key (userId,sessionId,sessionInsertUser))";
    
    
    //执行创建表任务
    if ([database executeUpdate:sql]&&
        [database executeUpdate:sqlTwo]&&
        [database executeUpdate:sqlThree]) {
        NSLog(@"create table success");
    }
    
    //关闭数据库
    [self closeDB];
}

//打开数据库
-(void)openDB{
    @synchronized (self) {
        openCount++;
        if(database==nil){
            //1.创建database路径
            NSString *docuPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
            //打开
            NSString *dbPath = [docuPath stringByAppendingPathComponent:@"flappyim.db"];
            //2.创建对应路径下数据库
            FMDatabase* db = [FMDatabase databaseWithPath:dbPath];
            //3.在数据库中进行增删改查操作时，需要判断数据库是否open，如果open失败，可能是权限或者资源不足，数据库操作完成通常使用close关闭数据库
            bool openFlag = [db open];
            //如果打开成功赋值
            if (openFlag) {
                database = db;
            }
        }
    }
}

//关闭数据库
-(void)closeDB{
    @synchronized (self) {
        openCount--;
        if(openCount==0){
            [database close];
            database=nil;
        }
    }
}


//设置之前没有发送成功的消息
-(void)clearSendingMessage{
    //打开数据库
    [self openDB];
    [database executeUpdate:@"update message set messageSendState = ? where messageSendState = 0", @(SEND_STATE_FAILURE)];
    [self closeDB];
}


//插入消息列表
-(void)insertMessages:(NSMutableArray*)array {
    //如果为空
    if(array==nil || array.count==0){
        return;
    }
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return;
    }
    //获取db
    [self openDB];
    //开始事务
    [database beginTransaction];
    //遍历
    for(ChatMessage* msg in array){
        //获取之前的消息
        ChatMessage* fomerMsg = [self getMessageById:msg.messageId];
        // 插入或替换数据
        BOOL result = [database executeUpdate:@"INSERT OR REPLACE INTO message("
                       "messageId,"
                       "messageSessionId,"
                       "messageSessionType,"
                       "messageSessionOffset,"
                       "messageTableOffset,"
                       "messageType,"
                       "messageSendId,"
                       "messageSendExtendId,"
                       "messageReceiveId,"
                       "messageReceiveExtendId,"
                       "messageContent,"
                       "messageSendState,"
                       "messageReadState,"
                       "messageSecret,"
                       "messageDate,"
                       "deleteDate,"
                       "messageStamp,"
                       "isDelete,"
                       "messageDeleteOperation,"
                       "messageDeleteUserList,"
                       "messageInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
                         withArgumentsInArray:@[
            [FlappyStringTool toUnNullStr:msg.messageId],
            [FlappyStringTool toUnNullStr:msg.messageSessionId],
            [NSNumber numberWithInteger:msg.messageSessionType],
            [NSNumber numberWithInteger:msg.messageSessionOffset],
            [NSNumber numberWithInteger:msg.messageTableOffset],
            [NSNumber numberWithInteger:msg.messageType],
            [FlappyStringTool toUnNullStr:msg.messageSendId],
            [FlappyStringTool toUnNullStr:msg.messageSendExtendId],
            [FlappyStringTool toUnNullStr:msg.messageReceiveId],
            [FlappyStringTool toUnNullStr:msg.messageReceiveExtendId],
            [FlappyStringTool toUnNullStr:msg.messageContent],
            [NSNumber numberWithInteger:msg.messageSendState],
            [NSNumber numberWithInteger:msg.messageReadState],
            [FlappyStringTool toUnNullStr:msg.messageSecret],
            [FlappyStringTool toUnNullStr:msg.messageDate],
            [FlappyStringTool toUnNullStr:msg.deleteDate],
            (fomerMsg!=nil ? [NSNumber numberWithInteger:fomerMsg.messageStamp]:[NSNumber numberWithInteger:(NSInteger)([NSDate date].timeIntervalSince1970*1000)]),
            (fomerMsg!=nil ? [NSNumber numberWithInteger:fomerMsg.isDelete]:[NSNumber numberWithInteger:msg.isDelete]),
            (fomerMsg!=nil ? [FlappyStringTool toUnNullStr:fomerMsg.messageDeleteOperation]:[FlappyStringTool toUnNullStr:msg.messageDeleteOperation]),
            (fomerMsg!=nil ? [FlappyStringTool toUnNullStr:fomerMsg.messageDeleteUserList]:[FlappyStringTool toUnNullStr:msg.messageDeleteUserList]),
            user.userExtendId
        ]];
        
        if (!result) {
            NSLog(@"插入或更新消息失败: %@", [database lastErrorMessage]);
            //如果有一条插入失败，则回滚事务
            [database rollback];
            [self closeDB];
            return;
        }
    }
    //提交事务
    [database commit];
    [self closeDB];
}


//插入消息
-(void)insertMessage:(ChatMessage*)msg {
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return;
    }
    //获取db
    [self openDB];
    //获取之前的消息
    ChatMessage* fomerMsg = [self getMessageById:msg.messageId];
    //插入或替换数据
    BOOL result = [database executeUpdate:@"INSERT OR REPLACE INTO message("
                   "messageId,"
                   "messageSessionId,"
                   "messageSessionType,"
                   "messageSessionOffset,"
                   "messageTableOffset,"
                   "messageType,"
                   "messageSendId,"
                   "messageSendExtendId,"
                   "messageReceiveId,"
                   "messageReceiveExtendId,"
                   "messageContent,"
                   "messageSendState,"
                   "messageReadState,"
                   "messageSecret,"
                   "messageDate,"
                   "deleteDate,"
                   "messageStamp,"
                   "isDelete,"
                   "messageDeleteOperation,"
                   "messageDeleteUserList,"
                   "messageInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
                     withArgumentsInArray:@[
        [FlappyStringTool toUnNullStr:msg.messageId],
        [FlappyStringTool toUnNullStr:msg.messageSessionId],
        [NSNumber numberWithInteger:msg.messageSessionType],
        [NSNumber numberWithInteger:msg.messageSessionOffset],
        [NSNumber numberWithInteger:msg.messageTableOffset],
        [NSNumber numberWithInteger:msg.messageType],
        [FlappyStringTool toUnNullStr:msg.messageSendId],
        [FlappyStringTool toUnNullStr:msg.messageSendExtendId],
        [FlappyStringTool toUnNullStr:msg.messageReceiveId],
        [FlappyStringTool toUnNullStr:msg.messageReceiveExtendId],
        [FlappyStringTool toUnNullStr:msg.messageContent],
        [NSNumber numberWithInteger:msg.messageSendState],
        [NSNumber numberWithInteger:msg.messageReadState],
        [FlappyStringTool toUnNullStr:msg.messageSecret],
        [FlappyStringTool toUnNullStr:msg.messageDate],
        [FlappyStringTool toUnNullStr:msg.deleteDate],
        (fomerMsg!=nil ? [NSNumber numberWithInteger:fomerMsg.messageStamp]:[NSNumber numberWithInteger:(NSInteger)([NSDate date].timeIntervalSince1970*1000)]),
        [NSNumber numberWithInteger:msg.isDelete],
        [FlappyStringTool toUnNullStr:msg.messageDeleteOperation],
        [FlappyStringTool toUnNullStr:msg.messageDeleteUserList],
        user.userExtendId
    ]];
    if (!result) {
        NSLog(@"插入或更新消息失败: %@", [database lastErrorMessage]);
    }
    // 关闭数据库
    [self closeDB];
}

//更新消息发送状态
-(void)updateMessageSendState:messageId
                 andSendState:sendState{
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return;
    }
    [self openDB];
    [database executeUpdate:@"update message set messageSendState=? where messageInsertUser=? and messageId=?"
       withArgumentsInArray:@[
        sendState,
        user.userExtendId,
        messageId]];
    [self closeDB];
}


//更新消息已读
-(void)updateMessageRead:userId
            andSessionId:sessionId
             andTableSeq:tableOffset{
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return;
    }
    [self openDB];
    [database executeUpdate:@"update message set messageReadState=1 where messageInsertUser=? and messageSendId!=? and messageSessionId=? and messageTableOffset<=?"
       withArgumentsInArray:@[
        user.userExtendId,
        userId,
        sessionId,
        tableOffset]];
    [self closeDB];
}


//更新消息已读
-(void)updateMessageRecall:(NSString*)userId
              andMessageId:(NSString*)messageId{
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return;
    }
    [self openDB];
    [database executeUpdate:@"update message set isDelete=1,messageDeleteOperation=?,messageDeleteUserList=?,messageReadState=1 where messageInsertUser=? and messageId=?"
       withArgumentsInArray:@[
        @"recall",
        userId,
        user.userExtendId,
        messageId
    ]];
    [self closeDB];
}

//更新消息被删除
-(void)updateMessageDelete:(NSString*)userId
              andMessageId:(NSString*)messageId{
    
    //检查用户
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return;
    }
    
    //消息更新
    ChatMessage* message = [self getMessageById:messageId];
    if(message==nil||message.isDelete==1){
        return;
    }
    
    //设置删除
    message.isDelete=0;
    
    //删除
    message.messageDeleteOperation=@"delete";
    
    //更新删除的用户
    NSMutableArray* arrayAdd = [FlappyStringTool splitStr:message.messageDeleteUserList withSeprate:@","];
    [arrayAdd addObject:userId];
    message.messageDeleteUserList = [FlappyStringTool joinStr:arrayAdd withSeprate:@","];
    
    //状态已读
    message.messageReadState = 1;
    
    [self insertMessage:message];
    
}


//处理动作消息插入
-(void)handleActionMessageUpdate:(ChatMessage*)msg{
    //未登录状态
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return;
    }
    //不是动作类型不处理
    if(msg.messageType != MSG_TYPE_ACTION){
        return;
    }
    //获取
    ChatAction* action =[msg getChatAction];
    switch(action.actionType){
            //更新消息撤回
        case ACTION_TYPE_RECALL_MSG:{
            NSString* userId = action.actionIds[0];
            NSString* messageId = action.actionIds[2];
            [self updateMessageRecall:userId andMessageId:messageId];
            break;
        }
            //更新消息撤回
        case ACTION_TYPE_DELETE_MSG:{
            NSString* userId = action.actionIds[0];
            NSString* messageId = action.actionIds[2];
            [self updateMessageDelete:userId andMessageId:messageId];
            break;
        }
            //更新消息已读
        case ACTION_TYPE_READ_SESSION:{
            NSString* userId = action.actionIds[0];
            NSString* sessionId = action.actionIds[1];
            NSString* tableOffset = action.actionIds[2];
            //更新消息状态
            [self updateMessageRead:userId
                       andSessionId:sessionId
                        andTableSeq:tableOffset];
            //更新最近消息状态
            [self updateSessionMemberLatestRead:userId
                                   andSessionId:sessionId
                                    andTableSeq:tableOffset];
            break;
        }
            //会话静音
        case ACTION_TYPE_MUTE_SESSION:{
            NSString* userId = action.actionIds[0];
            NSString* sessionId = action.actionIds[1];
            NSString* mute = action.actionIds[2];
            [self updateSessionMemberMute:userId
                             andSessionId:sessionId
                                  andMute:mute];
            break;
        }
            //更撤回
        case ACTION_TYPE_PINNED_SESSION:{
            NSString* userId = action.actionIds[0];
            NSString* sessionId = action.actionIds[1];
            NSString* pinned = action.actionIds[2];
            [self updateSessionMemberPinned:userId
                               andSessionId:sessionId
                                  andPinned:pinned];
            break;
        }
    }
}

//获取未读消息的数量
-(int)getUnReadSessionMessageCountBySessionId:(NSString*)sessionId{
    //用户
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return 0;
    }
    
    [self openDB];
    FMResultSet *results = [database executeQuery:@"SELECT COUNT(*) FROM message  WHERE messageInsertUser=? and messageSessionId=? and messageSendId!=? and messageReadState=0 and messageType!=? and messageType!=?"
                             withArgumentsInArray:@[
        user.userExtendId,
        sessionId,
        user.userId,
        @(MSG_TYPE_SYSTEM),
        @(MSG_TYPE_ACTION),
    ]];
    if ([results next]) {
        int count =[results intForColumnIndex:0];
        [results close];
        [self closeDB];
        return count;
    }else{
        [results close];
        [self closeDB];
        return 0;
    }
}


// 插入多条会话，如果存在就更新
-(Boolean)insertSessions:(NSMutableArray*)array {
    // 没有的情况下就是成功
    if(array==nil || array.count==0){
        return true;
    }
    
    // 获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return false;
    }
    
    // 打开数据库
    [self openDB];
    
    // 开启事务
    [database beginTransaction];
    
    // 是否成功
    Boolean totalSuccess = true;
    
    // 遍历
    for(SessionData* data in array){
        // 插入或替换数据
        BOOL result = [database executeUpdate:@"INSERT OR REPLACE INTO session("
                       "sessionId,"
                       "sessionExtendId,"
                       "sessionType,"
                       "sessionInfo,"
                       "sessionName,"
                       "sessionImage,"
                       "sessionOffset,"
                       "sessionStamp,"
                       "sessionCreateDate,"
                       "sessionCreateUser,"
                       "sessionDeleted,"
                       "sessionDeletedDate,"
                       "sessionInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?)"
                         withArgumentsInArray:@[
            [FlappyStringTool toUnNullStr:data.sessionId],
            [FlappyStringTool toUnNullStr:data.sessionExtendId],
            [NSNumber numberWithInteger:data.sessionType],
            [FlappyStringTool toUnNullStr:data.sessionInfo],
            [FlappyStringTool toUnNullStr:data.sessionName],
            [FlappyStringTool toUnNullStr:data.sessionImage],
            [FlappyStringTool toUnNullStr:data.sessionOffset],
            [NSNumber numberWithLong:data.sessionStamp],
            [FlappyStringTool toUnNullStr:data.sessionCreateDate],
            [FlappyStringTool toUnNullStr:data.sessionCreateUser],
            [NSNumber numberWithInteger:data.isDelete],
            [FlappyStringTool toUnNullStr:data.deleteDate],
            [FlappyStringTool toUnNullStr:user.userExtendId]
        ]];
        
        //插入用户数据
        if(data.users!=nil){
            for(SessionDataMember* member in data.users){
                // 如果一条失败了，就回滚
                BOOL memberResult = [self insertSessionMember:member];
                if(!memberResult){
                    totalSuccess = false;
                    break;
                }
            }
        }
        
        //如果一条失败了，就回滚
        if(!result){
            totalSuccess = false;
            break;
        }
    }
    
    // 如果全部成功了
    if(totalSuccess){
        [database commit];
    }
    
    // 失败了就回滚
    else{
        [database rollback];
    }
    
    // 关闭数据库
    [self closeDB];
    
    // 返回操作是否成功
    return totalSuccess;
}

//获取用户的会话
-(NSMutableArray*)getUserSessions:(NSString*)userExtendID{
    //获取db
    [self openDB];
    FMResultSet *result = [database executeQuery:@"select * from session where sessionInsertUser=?"
                            withArgumentsInArray:@[userExtendID]];
    NSMutableArray* retSessions=[[NSMutableArray alloc] init];
    while ([result next]) {
        SessionData *msg = [SessionData new];
        msg.sessionId = [result stringForColumn:@"sessionId"];
        msg.sessionExtendId = [result stringForColumn:@"sessionExtendId"];
        msg.sessionType = [result intForColumn:@"sessionType"];
        msg.sessionInfo = [result stringForColumn:@"sessionInfo"];
        msg.sessionName = [result stringForColumn:@"sessionName"];
        msg.sessionImage = [result stringForColumn:@"sessionImage"];
        msg.sessionOffset = [result stringForColumn:@"sessionOffset"];
        msg.sessionStamp = [result longForColumn:@"sessionStamp"];
        msg.sessionCreateDate = [result stringForColumn:@"sessionCreateDate"];
        msg.sessionCreateUser = [result stringForColumn:@"sessionCreateUser"];
        msg.isDelete = [result intForColumn:@"sessionDeleted"];
        msg.deleteDate = [result stringForColumn:@"sessionDeletedDate"];
        msg.users=[self getSessionMemberList:msg.sessionId];
        msg.unReadMessageCount = [self getUnReadSessionMessageCountBySessionId:msg.sessionId];
        [retSessions addObject:msg];
    }
    [result close];
    [self closeDB];
    return retSessions;
}



//插入单条会话,如果存在就更新
-(Boolean)insertSession:(SessionData*)data{
    
    //没有的情况下就是成功
    if(data==nil){
        return true;
    }
    
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return false;
    }
    
    // 打开数据库
    [self openDB];
    
    // 开启事务
    [database beginTransaction];
    
    // 是否成功
    Boolean totalSuccess = true;
    
    // 插入或替换数据
    BOOL result = [database executeUpdate:@"INSERT OR REPLACE INTO session("
                   "sessionId,"
                   "sessionExtendId,"
                   "sessionType,"
                   "sessionInfo,"
                   "sessionName,"
                   "sessionImage,"
                   "sessionOffset,"
                   "sessionStamp,"
                   "sessionCreateDate,"
                   "sessionCreateUser,"
                   "sessionDeleted,"
                   "sessionDeletedDate,"
                   "sessionInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?)"
                     withArgumentsInArray:@[
        [FlappyStringTool toUnNullStr:data.sessionId],
        [FlappyStringTool toUnNullStr:data.sessionExtendId],
        [NSNumber numberWithInteger:data.sessionType],
        [FlappyStringTool toUnNullStr:data.sessionInfo],
        [FlappyStringTool toUnNullStr:data.sessionName],
        [FlappyStringTool toUnNullStr:data.sessionImage],
        [FlappyStringTool toUnNullStr:data.sessionOffset],
        [NSNumber numberWithLong:data.sessionStamp],
        [FlappyStringTool toUnNullStr:data.sessionCreateDate],
        [FlappyStringTool toUnNullStr:data.sessionCreateUser],
        [NSNumber numberWithInteger:data.isDelete],
        [FlappyStringTool toUnNullStr:data.deleteDate],
        [FlappyStringTool toUnNullStr:user.userExtendId]
    ]];
    
    // 如果一条失败了，就回滚
    if(!result){
        totalSuccess = false;
    }
    
    // 插入用户数据
    if(data.users!=nil){
        for(SessionDataMember* member in data.users){
            BOOL memberResult = [self insertSessionMember:member];
            if(!memberResult){
                totalSuccess = false;
                break;
            }
        }
    }
    
    // 如果全部成功了
    if(totalSuccess){
        [database commit];
    }
    
    // 失败了就回滚
    else{
        [database rollback];
    }
    
    // 关闭数据库
    [self closeDB];
    
    // 返回操作是否成功
    return totalSuccess;
}


//获取用户的会话
-(SessionData*)getUserSessionByID:(NSString*)sessionId{
    
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return nil;
    }
    
    //获取db
    [self openDB];
    
    //会话
    FMResultSet *result = [database executeQuery:@"select * from session where sessionInsertUser=? and sessionId=?"
                            withArgumentsInArray:@[
        user.userExtendId,
        sessionId
    ]];
    
    //返回消息
    if ([result next]) {
        SessionData *msg = [SessionData new];
        msg.sessionId = [result stringForColumn:@"sessionId"];
        msg.sessionExtendId = [result stringForColumn:@"sessionExtendId"];
        msg.sessionType = [result intForColumn:@"sessionType"];
        msg.sessionInfo = [result stringForColumn:@"sessionInfo"];
        msg.sessionName = [result stringForColumn:@"sessionName"];
        msg.sessionImage = [result stringForColumn:@"sessionImage"];
        msg.sessionOffset = [result stringForColumn:@"sessionOffset"];
        msg.sessionStamp = [result longForColumn:@"sessionStamp"];
        msg.sessionCreateDate = [result stringForColumn:@"sessionCreateDate"];
        msg.sessionCreateUser = [result stringForColumn:@"sessionCreateUser"];
        msg.isDelete = [result intForColumn:@"sessionDeleted"];
        msg.deleteDate = [result stringForColumn:@"sessionDeletedDate"];
        //获取用户数据
        msg.users=[self getSessionMemberList:msg.sessionId];
        //获取未读消息数量
        msg.unReadMessageCount = [self getUnReadSessionMessageCountBySessionId:msg.sessionId];
        [result close];
        [self closeDB];
        return msg;
    }else{
        //没有拿到用户会话
        [result close];
        [self closeDB];
        return nil;
    }
}



//获取用户的会话
-(SessionData*)getUserSessionByExtendId:(NSString*)sessionExtendId{
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return nil;
    }
    
    //获取db
    [self openDB];
    
    //返回消息
    FMResultSet *result = [database executeQuery:@"select * from session where sessionInsertUser=? and sessionExtendId=?"
                            withArgumentsInArray:@[user.userExtendId,sessionExtendId]];
    if ([result next]) {
        SessionData *msg = [SessionData new];
        msg.sessionId = [result stringForColumn:@"sessionId"];
        msg.sessionExtendId = [result stringForColumn:@"sessionExtendId"];
        msg.sessionType = [result intForColumn:@"sessionType"];
        msg.sessionInfo = [result stringForColumn:@"sessionInfo"];
        msg.sessionName = [result stringForColumn:@"sessionName"];
        msg.sessionImage = [result stringForColumn:@"sessionImage"];
        msg.sessionOffset = [result stringForColumn:@"sessionOffset"];
        msg.sessionStamp = [result longForColumn:@"sessionStamp"];
        msg.sessionCreateDate = [result stringForColumn:@"sessionCreateDate"];
        msg.sessionCreateUser = [result stringForColumn:@"sessionCreateUser"];
        msg.isDelete = [result intForColumn:@"sessionDeleted"];
        msg.deleteDate = [result stringForColumn:@"sessionDeletedDate"];
        msg.users=[self getSessionMemberList:msg.sessionId];
        msg.unReadMessageCount = [self getUnReadSessionMessageCountBySessionId:msg.sessionId];
        [result close];
        [self closeDB];
        return msg;
    }
    
    [result close];
    [self closeDB];
    return nil;
}


//删除用户的会话
-(Boolean)deleteUserSession:(NSString*)sessionId{
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return false;
    }
    
    //打开数据库
    [self openDB];
    
    //删除消息
    Boolean flagOne  =  [database executeUpdate:@"DELETE FROM message where messageSessionId=? and messageInsertUser=?"
                           withArgumentsInArray:@[sessionId,user.userExtendId]];
    
    //删除会话
    Boolean flagTwo  =  [database executeUpdate:@"DELETE FROM session where sessionId=? and sessionInsertUser=?"
                           withArgumentsInArray:@[sessionId,user.userExtendId]];
    
    //关闭数据库
    [self closeDB];
    
    return flagOne&&flagTwo;
    
}


//插入会话的用户
-(Boolean)insertSessionMember:(SessionDataMember*) member{
    
    // 获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return false;
    }
    
    // 打开数据库
    [self openDB];
    
    Boolean flag=   [database executeUpdate:@"INSERT OR REPLACE INTO session_member("
                     "userId,"
                     "userExtendId,"
                     "userName,"
                     "userAvatar,"
                     "userData,"
                     "userCreateDate,"
                     "userLoginDate,"
                     "sessionId,"
                     "sessionMemberLatestRead,"
                     "sessionMemberLatestDelete,"
                     "sessionMemberMarkName,"
                     "sessionMemberMute,"
                     "sessionMemberPinned,"
                     "sessionJoinDate,"
                     "sessionLeaveDate,"
                     "isLeave,"
                     "sessionInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
                       withArgumentsInArray:@[
        [FlappyStringTool toUnNullStr:member.userId],
        [FlappyStringTool toUnNullStr:member.userExtendId],
        [FlappyStringTool toUnNullStr:member.userName],
        [FlappyStringTool toUnNullStr:member.userAvatar],
        [FlappyStringTool toUnNullStr:member.userData],
        [FlappyStringTool toUnNullStr:member.userCreateDate],
        [FlappyStringTool toUnNullStr:member.userLoginDate],
        [FlappyStringTool toUnNullStr:member.sessionId],
        [FlappyStringTool toUnNullStr:member.sessionMemberLatestRead],
        [FlappyStringTool toUnNullStr:member.sessionMemberLatestDelete],
        [FlappyStringTool toUnNullStr:member.sessionMemberMarkName],
        [NSNumber numberWithInteger:member.sessionMemberMute],
        [NSNumber numberWithInteger:member.sessionMemberPinned],
        [FlappyStringTool toUnNullStr:member.sessionJoinDate],
        [FlappyStringTool toUnNullStr:member.sessionLeaveDate],
        [NSNumber numberWithInteger:member.isLeave],
        [FlappyStringTool toUnNullStr:user.userExtendId]
    ]];
    
    // 关闭数据库
    [self closeDB];
    
    return  flag;
}


//获取会话ID的用户列表
-(SessionDataMember*)getSessionMember:(NSString*)sessionId
                          andMemberId:(NSString*)userId{
    
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return nil;
    }
    
    //获取db
    [self openDB];
    
    //查询
    FMResultSet *result = [database executeQuery:@"select * from session_member where sessionInsertUser=? and sessionId=? and userId=?"
                            withArgumentsInArray:@[user.userExtendId,sessionId,userId]];
    
    SessionDataMember *member = [SessionDataMember new];
    if ([result next]) {
        member.userId = [result stringForColumn:@"userId"];
        member.userExtendId = [result stringForColumn:@"userExtendId"];
        member.userName = [result stringForColumn:@"userName"];
        member.userAvatar = [result stringForColumn:@"userAvatar"];
        member.userData = [result stringForColumn:@"userData"];
        member.userCreateDate = [result stringForColumn:@"userCreateDate"];
        member.userLoginDate = [result stringForColumn:@"userLoginDate"];
        member.sessionId = [result stringForColumn:@"sessionId"];
        member.sessionMemberLatestRead = [result stringForColumn:@"sessionMemberLatestRead"];
        member.sessionMemberLatestDelete = [result stringForColumn:@"sessionMemberLatestDelete"];
        member.sessionMemberMarkName = [result stringForColumn:@"sessionMemberMarkName"];
        member.sessionMemberMute = [result intForColumn:@"sessionMemberMute"];
        member.sessionMemberPinned = [result intForColumn:@"sessionMemberPinned"];
        member.sessionJoinDate = [result stringForColumn:@"sessionJoinDate"];
        member.sessionLeaveDate = [result stringForColumn:@"sessionLeaveDate"];
        member.isLeave = [result intForColumn:@"isLeave"];
        [result close];
        [self closeDB];
        return  member;
    }
    [result close];
    [self closeDB];
    return nil;
}



//获取会话ID的用户列表
-(NSMutableArray*)getSessionMemberList:(NSString*)sessionId{
    
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return nil;
    }
    
    //获取db
    [self openDB];
    
    //查询
    FMResultSet *result = [database executeQuery:@"select * from session_member where sessionInsertUser=? and sessionId=?"
                            withArgumentsInArray:@[user.userExtendId,sessionId]];
    NSMutableArray* memberList=[[NSMutableArray alloc] init];
    while ([result next]) {
        SessionDataMember *member = [SessionDataMember new];
        
        member.userId = [result stringForColumn:@"userId"];
        member.userExtendId = [result stringForColumn:@"userExtendId"];
        member.userName = [result stringForColumn:@"userName"];
        member.userAvatar = [result stringForColumn:@"userAvatar"];
        member.userData = [result stringForColumn:@"userData"];
        member.userCreateDate = [result stringForColumn:@"userCreateDate"];
        member.userLoginDate = [result stringForColumn:@"userLoginDate"];
        member.sessionId = [result stringForColumn:@"sessionId"];
        member.sessionMemberLatestRead = [result stringForColumn:@"sessionMemberLatestRead"];
        member.sessionMemberLatestDelete = [result stringForColumn:@"sessionMemberLatestDelete"];
        member.sessionMemberMarkName = [result stringForColumn:@"sessionMemberMarkName"];
        member.sessionMemberMute = [result intForColumn:@"sessionMemberMute"];
        member.sessionMemberPinned = [result intForColumn:@"sessionMemberPinned"];
        member.sessionJoinDate = [result stringForColumn:@"sessionJoinDate"];
        member.sessionLeaveDate = [result stringForColumn:@"sessionLeaveDate"];
        member.isLeave = [result intForColumn:@"isLeave"];
        
        [memberList addObject:member];
    }
    [result close];
    [self closeDB];
    return memberList;
}


//更新最近已读的消息
-(void)updateSessionMemberLatestRead:(NSString*)userId
                        andSessionId:(NSString*)sessionId
                         andTableSeq:(NSString*)tableOffset{
    //打开数据库
    [self openDB];
    
    //获取这个用户数据
    SessionDataMember* data = [self getSessionMember:sessionId andMemberId:userId];
    
    //如果不为空就更新
    if(data!=nil){
        data.sessionMemberLatestRead=tableOffset;
        [self insertSessionMember:data];
    }
    
    //关闭数据库
    [self closeDB];
}


//更新mute
-(void)updateSessionMemberMute:(NSString*)userId
                  andSessionId:(NSString*)sessionId
                       andMute:(NSString*)mute{
    //打开数据库
    [self openDB];
    
    //获取这个用户数据
    SessionDataMember* data = [self getSessionMember:sessionId andMemberId:userId];
    
    //如果不为空就更新
    if(data!=nil){
        data.sessionMemberMute=[mute integerValue];
        [self insertSessionMember:data];
    }
    
    //关闭数据库
    [self closeDB];
    
}

//更新pinned
-(void)updateSessionMemberPinned:(NSString*)userId
                    andSessionId:(NSString*)sessionId
                       andPinned:(NSString*)pinned{
    //打开数据库
    [self openDB];
    
    //获取这个用户数据
    SessionDataMember* data = [self getSessionMember:sessionId andMemberId:userId];
    
    //如果不为空就更新
    if(data!=nil){
        data.sessionMemberPinned=[pinned integerValue];
        [self insertSessionMember:data];
    }
    
    //关闭数据库
    [self closeDB];
}



//更新数据
-(Boolean)updateMessage:(ChatMessage*)msg{
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return false;
    }
    //获取db
    [self openDB];
    //更新消息
    BOOL result = [database executeUpdate:@"update message set "
                   "messageSessionId=?,"
                   "messageSessionType=?,"
                   "messageSessionOffset=?,"
                   "messageTableOffset=?,"
                   "messageType=?,"
                   "messageSendId=?,"
                   "messageSendExtendId=?,"
                   "messageReceiveId=?,"
                   "messageReceiveExtendId=?,"
                   "messageContent=?,"
                   "messageSendState=?,"
                   "messageReadState=?,"
                   "messageSecret=?,"
                   "messageDate=?,"
                   "deleteDate=?,"
                   "isDelete=?,"
                   "messageDeleteOperation=?,"
                   "messageDeleteUserList=?"
                   " where "
                   "messageId = ?"
                   " and "
                   "messageInsertUser = ?"
                     withArgumentsInArray:@[
        [FlappyStringTool toUnNullStr:msg.messageSessionId],
        [NSNumber numberWithInteger:msg.messageSessionType],
        [NSNumber numberWithInteger:msg.messageSessionOffset],
        [NSNumber numberWithInteger:msg.messageTableOffset],
        [NSNumber numberWithInteger:msg.messageType],
        [FlappyStringTool toUnNullStr:msg.messageSendId],
        [FlappyStringTool toUnNullStr:msg.messageSendExtendId],
        [FlappyStringTool toUnNullStr:msg.messageReceiveId],
        [FlappyStringTool toUnNullStr:msg.messageReceiveExtendId],
        [FlappyStringTool toUnNullStr:msg.messageContent],
        [NSNumber numberWithInteger:msg.messageSendState],
        [NSNumber numberWithInteger:msg.messageReadState],
        [FlappyStringTool toUnNullStr:msg.messageSecret],
        [FlappyStringTool toUnNullStr:msg.messageDate],
        [FlappyStringTool toUnNullStr:msg.deleteDate],
        [NSNumber numberWithInteger:msg.isDelete],
        [FlappyStringTool toUnNullStr:msg.messageDeleteOperation],
        [FlappyStringTool toUnNullStr:msg.messageDeleteUserList],
        msg.messageId,
        user.userExtendId]];
    [self closeDB];
    if (result) {
        return true;
    } else {
        return false;
    }
}

//通过ID获取消息
-(ChatMessage*)getMessageById:(NSString*)messageID{
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return nil;
    }
    
    //获取db
    [self openDB];
    FMResultSet *result = [database executeQuery:@"select * from message where messageId=? and messageInsertUser=?"
                            withArgumentsInArray:@[messageID,user.userExtendId]];
    //返回消息
    if ([result next]) {
        ChatMessage *msg = [ChatMessage new];
        msg.messageId = [result stringForColumn:@"messageId"];
        msg.messageSessionId = [result stringForColumn:@"messageSessionId"];
        msg.messageSessionType = [result intForColumn:@"messageSessionType"];
        msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
        msg.messageTableOffset = [result intForColumn:@"messageTableOffset"];
        msg.messageType = [result intForColumn:@"messageType"];
        msg.messageSendId = [result stringForColumn:@"messageSendId"];
        msg.messageSendExtendId = [result stringForColumn:@"messageSendExtendId"];
        msg.messageReceiveId = [result stringForColumn:@"messageReceiveId"];
        msg.messageReceiveExtendId = [result stringForColumn:@"messageReceiveExtendId"];
        msg.messageContent = [result stringForColumn:@"messageContent"];
        msg.messageSendState = [result intForColumn:@"messageSendState"];
        msg.messageReadState = [result intForColumn:@"messageReadState"];
        msg.messageSecret = [result stringForColumn:@"messageSecret"];
        msg.messageDate = [result stringForColumn:@"messageDate"];
        msg.isDelete = [result intForColumn:@"isDelete"];
        msg.messageDeleteOperation = [result stringForColumn:@"messageDeleteOperation"];
        msg.messageDeleteUserList = [result stringForColumn:@"messageDeleteUserList"];
        msg.messageStamp = [result longForColumn:@"messageStamp"];
        msg.deleteDate = [result stringForColumn:@"deleteDate"];
        [result close];
        [self closeDB];
        //返回消息
        return msg;
    }
    [result close];
    [self closeDB];
    return nil;
}

//通过会话ID获取最近的一次会话
-(ChatMessage*)getSessionLatestMessage:(NSString*)sessionID{
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return nil;
    }
    //获取db
    [self openDB];
    
    //返回消息
    FMResultSet *result = [database executeQuery:@"select * from message where messageSessionId=? and messageInsertUser=? and messageType!=? and isDelete!=1 order by messageTableOffset desc,messageStamp desc limit 1"
                            withArgumentsInArray:@[
        sessionID,
        user.userExtendId,
        @(MSG_TYPE_ACTION)
    ]];
    if ([result next]) {
        ChatMessage *msg = [ChatMessage new];
        msg.messageId = [result stringForColumn:@"messageId"];
        msg.messageSessionId = [result stringForColumn:@"messageSessionId"];
        msg.messageSessionType = [result intForColumn:@"messageSessionType"];
        msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
        msg.messageTableOffset = [result intForColumn:@"messageTableOffset"];
        msg.messageType = [result intForColumn:@"messageType"];
        msg.messageSendId = [result stringForColumn:@"messageSendId"];
        msg.messageSendExtendId = [result stringForColumn:@"messageSendExtendId"];
        msg.messageReceiveId = [result stringForColumn:@"messageReceiveId"];
        msg.messageReceiveExtendId = [result stringForColumn:@"messageReceiveExtendId"];
        msg.messageContent = [result stringForColumn:@"messageContent"];
        msg.messageSendState = [result intForColumn:@"messageSendState"];
        msg.messageReadState = [result intForColumn:@"messageReadState"];
        msg.messageSecret = [result stringForColumn:@"messageSecret"];
        msg.messageDate = [result stringForColumn:@"messageDate"];
        msg.isDelete = [result intForColumn:@"isDelete"];
        msg.messageDeleteOperation = [result stringForColumn:@"messageDeleteOperation"];
        msg.messageDeleteUserList = [result stringForColumn:@"messageDeleteUserList"];
        msg.messageStamp = [result longForColumn:@"messageStamp"];
        msg.deleteDate = [result stringForColumn:@"deleteDate"];
        [result close];
        [self closeDB];
        return msg;
    }
    [result close];
    [self closeDB];
    return nil;
}

//获取消息
-(NSMutableArray*)getSessionOffsetMessages:(NSString*)sessionID
                                 andOffset:(NSString*)tabOffset
                                  andStamp:(NSString*)stamp{
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return [[NSMutableArray alloc]init];
    }
    //获取db
    [self openDB];
    
    //获取消息
    FMResultSet *result = [database executeQuery:@"select * from message where messageSessionId=? and messageTableOffset=? and messageStamp<? and messageInsertUser=? and messageType!=? and isDelete!=1 order by messageStamp  desc"
                            withArgumentsInArray:@[sessionID,tabOffset,stamp,user.userExtendId,@(MSG_TYPE_ACTION)]];
    NSMutableArray* retArray=[[NSMutableArray alloc]init];
    while ([result next]) {
        ChatMessage *msg = [ChatMessage new];
        msg.messageId = [result stringForColumn:@"messageId"];
        msg.messageSessionId = [result stringForColumn:@"messageSessionId"];
        msg.messageSessionType = [result intForColumn:@"messageSessionType"];
        msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
        msg.messageTableOffset = [result intForColumn:@"messageTableOffset"];
        msg.messageType = [result intForColumn:@"messageType"];
        msg.messageSendId = [result stringForColumn:@"messageSendId"];
        msg.messageSendExtendId = [result stringForColumn:@"messageSendExtendId"];
        msg.messageReceiveId = [result stringForColumn:@"messageReceiveId"];
        msg.messageReceiveExtendId = [result stringForColumn:@"messageReceiveExtendId"];
        msg.messageContent = [result stringForColumn:@"messageContent"];
        msg.messageSendState = [result intForColumn:@"messageSendState"];
        msg.messageReadState = [result intForColumn:@"messageReadState"];
        msg.messageSecret = [result stringForColumn:@"messageSecret"];
        msg.messageDate = [result stringForColumn:@"messageDate"];
        msg.isDelete = [result intForColumn:@"isDelete"];
        msg.messageDeleteOperation = [result stringForColumn:@"messageDeleteOperation"];
        msg.messageDeleteUserList = [result stringForColumn:@"messageDeleteUserList"];
        msg.messageStamp = [result longForColumn:@"messageStamp"];
        msg.deleteDate = [result stringForColumn:@"deleteDate"];
        [retArray addObject:msg];
    }
    [result close];
    [self closeDB];
    return retArray;
}

//通过sessionID，获取之前的
-(NSMutableArray*)getSessionFormerMessages:(NSString*)sessionID
                             withMessageID:(NSString*)messageId
                                  withSize:(NSInteger)size{
    
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return [[NSMutableArray alloc]init];
    }
    
    //获取db
    [self openDB];
    
    //获取当前的消息ID
    ChatMessage* msg=[self getMessageById:messageId];
    
    //当前的
    NSMutableArray* retArray=[[NSMutableArray alloc] init];
    NSMutableArray* sequeceArray=[self getSessionOffsetMessages:sessionID
                                                      andOffset:[NSString stringWithFormat:@"%ld",(long)msg.messageTableOffset]
                                                       andStamp:[NSString stringWithFormat:@"%ld",(long)msg.messageStamp]];
    [retArray addObjectsFromArray:sequeceArray];
    //获取消息
    FMResultSet *result = [database executeQuery:@"select * from message where messageSessionId=? and messageTableOffset<? and messageInsertUser=? and messageType!=? and isDelete!=1 order by messageTableOffset desc,messageStamp desc limit ?"
                            withArgumentsInArray:@[
        sessionID,
        [NSNumber numberWithInteger:msg.messageTableOffset],
        user.userExtendId,
        @(MSG_TYPE_ACTION),
        [NSNumber numberWithInteger:size]
    ]];
    NSMutableArray* listArray=[[NSMutableArray alloc]init];
    while ([result next]) {
        ChatMessage *msg = [ChatMessage new];
        msg.messageId = [result stringForColumn:@"messageId"];
        msg.messageSessionId = [result stringForColumn:@"messageSessionId"];
        msg.messageSessionType = [result intForColumn:@"messageSessionType"];
        msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
        msg.messageTableOffset = [result intForColumn:@"messageTableOffset"];
        msg.messageType = [result intForColumn:@"messageType"];
        msg.messageSendId = [result stringForColumn:@"messageSendId"];
        msg.messageSendExtendId = [result stringForColumn:@"messageSendExtendId"];
        msg.messageReceiveId = [result stringForColumn:@"messageReceiveId"];
        msg.messageReceiveExtendId = [result stringForColumn:@"messageReceiveExtendId"];
        msg.messageContent = [result stringForColumn:@"messageContent"];
        msg.messageSendState = [result intForColumn:@"messageSendState"];
        msg.messageReadState = [result intForColumn:@"messageReadState"];
        msg.messageSecret = [result stringForColumn:@"messageSecret"];
        msg.messageDate = [result stringForColumn:@"messageDate"];
        msg.messageStamp = [result longForColumn:@"messageStamp"];
        msg.isDelete = [result intForColumn:@"isDelete"];
        msg.messageDeleteOperation = [result stringForColumn:@"messageDeleteOperation"];
        msg.messageDeleteUserList = [result stringForColumn:@"messageDeleteUserList"];
        msg.deleteDate = [result stringForColumn:@"deleteDate"];
        [listArray addObject:msg];
    }
    //关闭
    [result close];
    //关闭
    [self closeDB];
    //结果集
    [retArray addObjectsFromArray:listArray];
    //获取
    if (retArray.count > size) {
        NSRange range = NSMakeRange(0, size);
        retArray = [[NSMutableArray alloc] initWithArray:[retArray subarrayWithRange:range]];
    }
    return retArray;
}

//获取没有处理的系统消息
-(NSMutableArray*)getNotActionSystemMessageBySessionId:(NSString*)sessionID{
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return [[NSMutableArray alloc]init];
    }
    //获取消息
    [self openDB];
    FMResultSet *result = [database executeQuery:@"select * from message where messageType=0 and messageReadState=0 and messageSessionId=? and messageInsertUser=? order by messageTableOffset  desc"
                            withArgumentsInArray:@[sessionID,user.userExtendId]];
    NSMutableArray* retArray=[[NSMutableArray alloc]init];
    while ([result next]) {
        ChatMessage *msg = [ChatMessage new];
        msg.messageId = [result stringForColumn:@"messageId"];
        msg.messageSessionId = [result stringForColumn:@"messageSessionId"];
        msg.messageSessionType = [result intForColumn:@"messageSessionType"];
        msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
        msg.messageTableOffset = [result intForColumn:@"messageTableOffset"];
        msg.messageType = [result intForColumn:@"messageType"];
        msg.messageSendId = [result stringForColumn:@"messageSendId"];
        msg.messageSendExtendId = [result stringForColumn:@"messageSendExtendId"];
        msg.messageReceiveId = [result stringForColumn:@"messageReceiveId"];
        msg.messageReceiveExtendId = [result stringForColumn:@"messageReceiveExtendId"];
        msg.messageContent = [result stringForColumn:@"messageContent"];
        msg.messageSendState = [result intForColumn:@"messageSendState"];
        msg.messageReadState = [result intForColumn:@"messageReadState"];
        msg.messageSecret = [result stringForColumn:@"messageSecret"];
        msg.messageDate = [result stringForColumn:@"messageDate"];
        msg.isDelete = [result intForColumn:@"isDelete"];
        msg.messageDeleteOperation = [result stringForColumn:@"messageDeleteOperation"];
        msg.messageDeleteUserList = [result stringForColumn:@"messageDeleteUserList"];
        msg.messageStamp = [result longForColumn:@"messageStamp"];
        msg.deleteDate = [result stringForColumn:@"deleteDate"];
        [retArray addObject:msg];
    }
    [result close];
    [self closeDB];
    return retArray;
}

//获取没有处理的系统消息
-(NSMutableArray*)getNotActionSystemMessage{
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return [[NSMutableArray alloc]init];
    }
    
    //获取消息
    [self openDB];
    FMResultSet *result = [database executeQuery:@"select * from message where messageReadState=0 and messageType=? and messageInsertUser=? order by messageTableOffset asc"
                            withArgumentsInArray:@[
        @(MSG_TYPE_SYSTEM),
        user.userExtendId
    ]];
    NSMutableArray* retArray=[[NSMutableArray alloc]init];
    while ([result next]) {
        ChatMessage *msg = [ChatMessage new];
        msg.messageId = [result stringForColumn:@"messageId"];
        msg.messageSessionId = [result stringForColumn:@"messageSessionId"];
        msg.messageSessionType = [result intForColumn:@"messageSessionType"];
        msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
        msg.messageTableOffset = [result intForColumn:@"messageTableOffset"];
        msg.messageType = [result intForColumn:@"messageType"];
        msg.messageSendId = [result stringForColumn:@"messageSendId"];
        msg.messageSendExtendId = [result stringForColumn:@"messageSendExtendId"];
        msg.messageReceiveId = [result stringForColumn:@"messageReceiveId"];
        msg.messageReceiveExtendId = [result stringForColumn:@"messageReceiveExtendId"];
        msg.messageContent = [result stringForColumn:@"messageContent"];
        msg.messageSendState = [result intForColumn:@"messageSendState"];
        msg.messageReadState = [result intForColumn:@"messageReadState"];
        msg.messageSecret = [result stringForColumn:@"messageSecret"];
        msg.messageDate = [result stringForColumn:@"messageDate"];
        msg.isDelete = [result intForColumn:@"isDelete"];
        msg.messageDeleteOperation = [result stringForColumn:@"messageDeleteOperation"];
        msg.messageDeleteUserList = [result stringForColumn:@"messageDeleteUserList"];
        msg.messageStamp = [result longForColumn:@"messageStamp"];
        msg.deleteDate = [result stringForColumn:@"deleteDate"];
        [retArray addObject:msg];
    }
    [result close];
    [self closeDB];
    return retArray;
}

@end
