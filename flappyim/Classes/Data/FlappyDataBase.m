#import "FlappyDataBase.h"
#import "FMDatabaseQueue.h"
#import "FlappyStringTool.h"
#import "FlappyJsonTool.h"
#import "ChatSessionData.h"
#import "MJExtension.h"
#import "FlappyData.h"
#import "FMDatabase.h"
#import <math.h>

//数据库
@implementation FlappyDataBase {
    NSInteger openCount;
    FMDatabase* database;
}

//使用单例模式
+ (instancetype)shareInstance {
    static FlappyDataBase *_sharedSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
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
-(void)setup {
    [self openDB];
    
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
    
    "messageReplyMsgId TEXT,"
    "messageReplyMsgType INTEGER,"
    "messageReplyMsgContent TEXT,"
    "messageReplyUserId TEXT,"
    "messageRecallUserId TEXT,"
    "messageAtUserIds TEXT,"
    "messageReadUserIds TEXT,"
    "messageDeleteUserIds TEXT,"
    
    "messageDate TEXT,"
    "messageStamp INTEGER,"
    "deleteDate TEXT,"
    "messageInsertUser TEXT,"
    "primary key (messageId,messageInsertUser))";
    
    NSString *sqlTwo = @"create table if not exists session ("
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
    
    NSString *sqlThree = @"create table if not exists session_member ("
    "userId TEXT,"
    "userExtendId TEXT,"
    "userName TEXT,"
    "userAvatar TEXT,"
    "userData TEXT,"
    "userCreateDate TEXT,"
    "userLoginDate TEXT,"
    "sessionId TEXT,"
    "sessionMemberLatestRead INTEGER,"
    "sessionMemberLatestDelete INTEGER,"
    "sessionMemberMarkName TEXT,"
    "sessionMemberMute INTEGER,"
    "sessionMemberPinned INTEGER,"
    "sessionJoinDate TEXT,"
    "sessionLeaveDate TEXT,"
    "isLeave INTEGER,"
    "sessionInsertUser TEXT,"
    "primary key (userId,sessionId,sessionInsertUser))";
    
    if ([database executeUpdate:sql] &&
        [database executeUpdate:sqlTwo] &&
        [database executeUpdate:sqlThree]) {
        NSLog(@"create table success");
    }
    
    [self closeDB];
}

//打开数据库
-(void)openDB {
    @synchronized (self) {
        openCount++;
        if (database == nil) {
            NSString *docuPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
            NSString *dbPath = [docuPath stringByAppendingPathComponent:@"flappyim.db"];
            FMDatabase* db = [FMDatabase databaseWithPath:dbPath];
            bool openFlag = [db open];
            if (openFlag) {
                database = db;
            }
        }
    }
}

//关闭数据库
-(void)closeDB {
    @synchronized (self) {
        openCount--;
        if (openCount == 0) {
            [database close];
            database = nil;
        }
    }
}

//通用的数据库操作模板方法
- (id)executeDbOperation:(id (^)(FMDatabase *db, ChatUser *user))operation {
    return [self executeDbOperation:operation defaultValue:nil];
}


//通用的数据库操作模板方法
- (id)executeDbOperation:(id (^)(FMDatabase *db, ChatUser *user))operation
            defaultValue:(id)defaultValue{
    [self openDB];
    ChatUser *user = [[FlappyData shareInstance] getUser];
    id result = nil;
    if (user != nil) {
        result = operation(database, user);
    }
    [self closeDB];
    return result==nil ? defaultValue:result;
}



//设置之前没有发送成功的消息
-(void)clearSendingMessage {
    [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        [db executeUpdate:@"update message set messageSendState = ? where messageSendState = 0", @(SEND_STATE_FAILURE)];
        return nil;
    }];
}

//插入消息列表
-(void)insertMessages:(NSMutableArray *)array {
    if (array == nil || array.count == 0) {
        return;
    }
    [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        [db beginTransaction];
        for (ChatMessage *msg in array) {
            [self updateSessionOffset:msg.messageSessionId andSessionOffset:msg.messageSessionOffset];
            ChatMessage *fomerMsg = [self getMessageById:msg.messageId];
            BOOL result = [db executeUpdate:@"INSERT OR REPLACE INTO message("
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
                           "messageReplyMsgId,"
                           "messageReplyMsgType,"
                           "messageReplyMsgContent,"
                           "messageReplyUserId,"
                           "messageRecallUserId,"
                           "messageAtUserIds,"
                           "messageReadUserIds,"
                           "messageDeleteUserIds,"
                           "messageInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
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
                (fomerMsg != nil ? [NSNumber numberWithInteger:fomerMsg.messageStamp] : [NSNumber numberWithInteger:(NSInteger)([NSDate date].timeIntervalSince1970 * 1000)]),
                [NSNumber numberWithInteger:msg.isDelete],
            
                [FlappyStringTool toUnNullStr:msg.messageReplyMsgId],
                [NSNumber numberWithInteger:msg.messageReplyMsgType],
                [FlappyStringTool toUnNullStr:msg.messageReplyMsgContent],
                [FlappyStringTool toUnNullStr:msg.messageReplyUserId],
                [FlappyStringTool toUnNullStr:msg.messageRecallUserId],
                [FlappyStringTool toUnNullStr:msg.messageAtUserIds],
                [FlappyStringTool toUnNullStr:msg.messageReadUserIds],
                [FlappyStringTool toUnNullStr:msg.messageDeleteUserIds],

                user.userExtendId
            ]];
            
            if (!result) {
                NSLog(@"插入或更新消息失败: %@", [db lastErrorMessage]);
                [db rollback];
                return nil;
            }
        }
        [db commit];
        return nil;
    }];
}

//插入消息
-(void)insertMessage:(ChatMessage *)msg {
    [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        [self updateSessionOffset:msg.messageSessionId 
                 andSessionOffset:msg.messageSessionOffset];
        ChatMessage *fomerMsg = [self getMessageById:msg.messageId];
        BOOL result = [db executeUpdate:@"INSERT OR REPLACE INTO message("
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
                       "messageReplyMsgId,"
                       "messageReplyMsgType,"
                       "messageReplyMsgContent,"
                       "messageReplyUserId,"
                       "messageRecallUserId,"
                       "messageAtUserIds,"
                       "messageReadUserIds,"
                       "messageDeleteUserIds,"
                       "messageInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
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
            (fomerMsg != nil ? [NSNumber numberWithInteger:fomerMsg.messageStamp] : [NSNumber numberWithInteger:(NSInteger)([NSDate date].timeIntervalSince1970 * 1000)]),
            [NSNumber numberWithInteger:msg.isDelete],
            
            [FlappyStringTool toUnNullStr:msg.messageReplyMsgId],
            [NSNumber numberWithInteger:msg.messageReplyMsgType],
            [FlappyStringTool toUnNullStr:msg.messageReplyMsgContent],
            [FlappyStringTool toUnNullStr:msg.messageReplyUserId],
            [FlappyStringTool toUnNullStr:msg.messageRecallUserId],
            [FlappyStringTool toUnNullStr:msg.messageAtUserIds],
            [FlappyStringTool toUnNullStr:msg.messageReadUserIds],
            [FlappyStringTool toUnNullStr:msg.messageDeleteUserIds],
            
            user.userExtendId
        ]];
        if (!result) {
            NSLog(@"插入或更新消息失败: %@", [db lastErrorMessage]);
        }
        return nil;
    }];
}

//更新消息发送状态
-(void)updateMessageSendState:(NSString *)messageId andSendState:(NSInteger)sendState {
    [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        [db executeUpdate:@"update message set messageSendState=? where messageInsertUser=? and messageId=?"
     withArgumentsInArray:@[
            @(sendState),
            user.userExtendId,
            messageId
        ]];
        return nil;
    }];
}

//获取未读消息的数量
-(int)getUnReadSessionMessageCountBySessionId:(NSString *)sessionId {
    return [[self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM message WHERE messageInsertUser=? and messageSessionId=? and messageSendId!=? and messageReadState=0 and (messageRecallUserId is null or messageRecallUserId == '') and (messageDeleteUserIds not like ?) and messageType!=? and messageType!=?"
                           withArgumentsInArray:@[
            user.userExtendId,
            sessionId,
            user.userId,
            [NSString stringWithFormat:@"%%%@%%",user.userId],
            @(MSG_TYPE_SYSTEM),
            @(MSG_TYPE_ACTION),
        ]];
        int count = 0;
        if ([results next]) {
            count = [results intForColumnIndex:0];
        }
        [results close];
        return @(count);
    }] intValue];
}

//获取是否最近删除
-(Boolean)getIsDeleteTemp:(NSString *)sessionId {
    return [[self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        
        long latestSessionOffset = 0;
        long latestSessionOffsetDelete = 0;
        
        //获取最近消息
        FMResultSet *result = [db executeQuery:@"select * from message where messageSessionId=? and messageInsertUser=? and messageType!=? and isDelete!=1 order by messageTableOffset desc,messageStamp desc limit 1"
                          withArgumentsInArray:@[
            sessionId,
            user.userExtendId,
            @(MSG_TYPE_ACTION)
        ]];
        if ([result next]) {
            latestSessionOffset = [result intForColumn:@"messageSessionOffset"];
        }
        [result close];
        
        //获取最近删除
        result = [db executeQuery:@"select * from session_member where sessionInsertUser=? and sessionId=? and userId=?"
                          withArgumentsInArray:@[user.userExtendId, sessionId, user.userId]];
        if ([result next]) {
            latestSessionOffsetDelete= [result longForColumn:@"sessionMemberLatestDelete"];
        }
        [result close];
        
        
        
        
        Boolean flag = (latestSessionOffsetDelete >= latestSessionOffset && latestSessionOffset != 0);
        return @(flag);
        
    } ] boolValue];
}


// 插入多条会话，如果存在就更新
-(Boolean)insertSessions:(NSMutableArray *)array {
    if (array == nil || array.count == 0) {
        return true;
    }
    return [[self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        [db beginTransaction];
        Boolean totalSuccess = true;
        for (ChatSessionData *data in array) {
            BOOL result = [db executeUpdate:@"INSERT OR REPLACE INTO session("
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
                user.userExtendId
            ]];
            
            if (data.users != nil) {
                for (ChatSessionMember *member in data.users) {
                    BOOL memberResult = [self insertSessionMember:member];
                    if (!memberResult) {
                        totalSuccess = false;
                        break;
                    }
                }
            }
            
            if (!result) {
                totalSuccess = false;
                break;
            }
        }
        
        if (totalSuccess) {
            [db commit];
        } else {
            [db rollback];
        }
        return @(totalSuccess);
    }] boolValue];
}

//获取用户的会话
-(NSMutableArray *)getUserSessions:(NSString *)userExtendID {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *result = [db executeQuery:@"select * from session where sessionInsertUser=?"
                          withArgumentsInArray:@[userExtendID]];
        NSMutableArray *retSessions = [[NSMutableArray alloc] init];
        while ([result next]) {
            ChatSessionData *msg = [ChatSessionData new];
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
            msg.unReadMessageCount = [self getUnReadSessionMessageCountBySessionId:msg.sessionId];
            msg.isDeleteTemp = [self getIsDeleteTemp:msg.sessionId];
            msg.users = [self getSessionMemberList:msg.sessionId];
            [retSessions addObject:msg];
        }
        [result close];
        return retSessions;
    } defaultValue: [[NSMutableArray alloc] init]];
}

//插入单条会话,如果存在就更新
-(Boolean)insertSession:(ChatSessionData *)data {
    return [[self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        [db beginTransaction];
        BOOL result = [db executeUpdate:@"INSERT OR REPLACE INTO session("
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
            user.userExtendId
        ]];
        
        Boolean totalSuccess = result;
        
        if (data.users != nil) {
            for (ChatSessionMember *member in data.users) {
                BOOL memberResult = [self insertSessionMember:member];
                if (!memberResult) {
                    totalSuccess = false;
                    break;
                }
            }
        }
        
        if (totalSuccess) {
            [db commit];
        } else {
            [db rollback];
        }
        return @(totalSuccess);
    }] boolValue];
}

//获取用户的会话
-(ChatSessionData *)getUserSessionByID:(NSString *)sessionId {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *result = [db executeQuery:@"select * from session where sessionInsertUser=? and sessionId=?"
                          withArgumentsInArray:@[
            user.userExtendId,
            sessionId
        ]];
        
        ChatSessionData *msg = nil;
        if ([result next]) {
            msg = [ChatSessionData new];
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
            msg.unReadMessageCount = [self getUnReadSessionMessageCountBySessionId:msg.sessionId];
            msg.isDeleteTemp = [self getIsDeleteTemp:msg.sessionId];
            msg.users = [self getSessionMemberList:msg.sessionId];
        }
        [result close];
        return msg;
    }];
}

//获取用户的会话
-(ChatSessionData *)getUserSessionByExtendId:(NSString *)sessionExtendId {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *result = [db executeQuery:@"select * from session where sessionInsertUser=? and sessionExtendId=?"
                          withArgumentsInArray:@[user.userExtendId, sessionExtendId]];
        
        ChatSessionData *msg = nil;
        if ([result next]) {
            msg = [ChatSessionData new];
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
            msg.unReadMessageCount = [self getUnReadSessionMessageCountBySessionId:msg.sessionId];
            msg.isDeleteTemp = [self getIsDeleteTemp:msg.sessionId];
            msg.users = [self getSessionMemberList:msg.sessionId];
        }
        [result close];
        return msg;
    }];
}

//删除用户的会话
-(Boolean)deleteUserSession:(NSString *)sessionId {
    return [[self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        BOOL flag = [db executeUpdate:@"update session set sessionDeleted = 1 where sessionId=? and sessionInsertUser=?"
                 withArgumentsInArray:@[sessionId, user.userExtendId]];
        return @(flag);
    }] boolValue];
}

//插入会话的用户
-(Boolean)insertSessionMember:(ChatSessionMember *)member {
    return [[self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        BOOL flag = [db executeUpdate:@"INSERT OR REPLACE INTO session_member("
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
            [NSNumber numberWithInteger:member.sessionMemberLatestRead],
            [NSNumber numberWithInteger:member.sessionMemberLatestDelete],
            [FlappyStringTool toUnNullStr:member.sessionMemberMarkName],
            [NSNumber numberWithInteger:member.sessionMemberMute],
            [NSNumber numberWithInteger:member.sessionMemberPinned],
            [FlappyStringTool toUnNullStr:member.sessionJoinDate],
            [FlappyStringTool toUnNullStr:member.sessionLeaveDate],
            [NSNumber numberWithInteger:member.isLeave],
            user.userExtendId
        ]];
        return @(flag);
    }] boolValue];
}

//获取会话ID的用户列表
-(ChatSessionMember *)getSessionMember:(NSString *)sessionId andMemberId:(NSString *)userId {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *result = [db executeQuery:@"select * from session_member where sessionInsertUser=? and sessionId=? and userId=?"
                          withArgumentsInArray:@[user.userExtendId, sessionId, userId]];
        
        ChatSessionMember *member = nil;
        if ([result next]) {
            member = [ChatSessionMember new];
            member.userId = [result stringForColumn:@"userId"];
            member.userExtendId = [result stringForColumn:@"userExtendId"];
            member.userName = [result stringForColumn:@"userName"];
            member.userAvatar = [result stringForColumn:@"userAvatar"];
            member.userData = [result stringForColumn:@"userData"];
            member.userCreateDate = [result stringForColumn:@"userCreateDate"];
            member.userLoginDate = [result stringForColumn:@"userLoginDate"];
            member.sessionId = [result stringForColumn:@"sessionId"];
            member.sessionMemberLatestRead = [result longForColumn:@"sessionMemberLatestRead"];
            member.sessionMemberLatestDelete = [result longForColumn:@"sessionMemberLatestDelete"];
            member.sessionMemberMarkName = [result stringForColumn:@"sessionMemberMarkName"];
            member.sessionMemberMute = [result intForColumn:@"sessionMemberMute"];
            member.sessionMemberPinned = [result intForColumn:@"sessionMemberPinned"];
            member.sessionJoinDate = [result stringForColumn:@"sessionJoinDate"];
            member.sessionLeaveDate = [result stringForColumn:@"sessionLeaveDate"];
            member.isLeave = [result intForColumn:@"isLeave"];
        }
        [result close];
        return member;
    }];
}

//获取会话ID的用户列表
-(NSMutableArray *)getSessionMemberList:(NSString *)sessionId {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *result = [db executeQuery:@"select * from session_member where sessionInsertUser=? and sessionId=?"
                          withArgumentsInArray:@[user.userExtendId, sessionId]];
        NSMutableArray *memberList = [[NSMutableArray alloc] init];
        while ([result next]) {
            ChatSessionMember *member = [ChatSessionMember new];
            member.userId = [result stringForColumn:@"userId"];
            member.userExtendId = [result stringForColumn:@"userExtendId"];
            member.userName = [result stringForColumn:@"userName"];
            member.userAvatar = [result stringForColumn:@"userAvatar"];
            member.userData = [result stringForColumn:@"userData"];
            member.userCreateDate = [result stringForColumn:@"userCreateDate"];
            member.userLoginDate = [result stringForColumn:@"userLoginDate"];
            member.sessionId = [result stringForColumn:@"sessionId"];
            member.sessionMemberLatestRead = [result longForColumn:@"sessionMemberLatestRead"];
            member.sessionMemberLatestDelete = [result longForColumn:@"sessionMemberLatestDelete"];
            member.sessionMemberMarkName = [result stringForColumn:@"sessionMemberMarkName"];
            member.sessionMemberMute = [result intForColumn:@"sessionMemberMute"];
            member.sessionMemberPinned = [result intForColumn:@"sessionMemberPinned"];
            member.sessionJoinDate = [result stringForColumn:@"sessionJoinDate"];
            member.sessionLeaveDate = [result stringForColumn:@"sessionLeaveDate"];
            member.isLeave = [result intForColumn:@"isLeave"];
            [memberList addObject:member];
        }
        [result close];
        return memberList;
    } defaultValue: [[NSMutableArray alloc] init]];
}

//更新数据
-(Boolean)updateMessage:(ChatMessage *)msg {
    return [[self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        BOOL result = [db executeUpdate:@"update message set "
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
                
                       "messageReplyMsgId=?,"
                       "messageReplyMsgType=?,"
                       "messageReplyMsgContent=?,"
                       "messageReplyUserId=?,"
                       "messageRecallUserId=?,"
                       "messageAtUserIds=?,"
                       "messageReadUserIds=?,"
                       "messageDeleteUserIds=?"
                       
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
            
            [FlappyStringTool toUnNullStr:msg.messageReplyMsgId],
            [NSNumber numberWithInteger:msg.messageReplyMsgType],
            [FlappyStringTool toUnNullStr:msg.messageReplyMsgContent],
            [FlappyStringTool toUnNullStr:msg.messageReplyUserId],
            [FlappyStringTool toUnNullStr:msg.messageRecallUserId],
            [FlappyStringTool toUnNullStr:msg.messageAtUserIds],
            [FlappyStringTool toUnNullStr:msg.messageReadUserIds],
            [FlappyStringTool toUnNullStr:msg.messageDeleteUserIds],
            
            msg.messageId,
            user.userExtendId
        ]];
        return @(result);
    }] boolValue];
}

//通过ID获取消息
-(ChatMessage *)getMessageById:(NSString *)messageID {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *result = [db executeQuery:@"select * from message where messageId=? and messageInsertUser=?"
                          withArgumentsInArray:@[messageID, user.userExtendId]];
        
        ChatMessage *msg = nil;
        if ([result next]) {
            msg = [ChatMessage new];
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
            
            msg.messageReplyMsgId = [result stringForColumn:@"messageReplyMsgId"];
            msg.messageReplyMsgType = [result intForColumn:@"messageReplyMsgType"];
            msg.messageReplyMsgContent = [result stringForColumn:@"messageReplyMsgContent"];
            msg.messageReplyUserId = [result stringForColumn:@"messageReplyUserId"];
            msg.messageRecallUserId = [result stringForColumn:@"messageRecallUserId"];
            msg.messageAtUserIds = [result stringForColumn:@"messageAtUserIds"];
            msg.messageReadUserIds = [result stringForColumn:@"messageReadUserIds"];
            msg.messageDeleteUserIds = [result stringForColumn:@"messageDeleteUserIds"];
            
            
            msg.messageStamp = [result longForColumn:@"messageStamp"];
            msg.deleteDate = [result stringForColumn:@"deleteDate"];
        }
        [result close];
        return msg;
    }];
}

//通过会话ID获取最近的一次会话
-(NSInteger)getSessionOffsetLatest:(NSString *)sessionID {
    return [[self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *result = [db executeQuery:@"select * from message where messageSessionId=? and messageInsertUser=? and messageType!=? and isDelete!=1 and messageSendState in (1,2,3,4) order by messageTableOffset desc,messageStamp desc limit 1"
                          withArgumentsInArray:@[
            sessionID,
            user.userExtendId,
            @(MSG_TYPE_ACTION)
        ]];
        
        NSInteger offset = 0;
        if ([result next]) {
            offset = [result intForColumn:@"messageSessionOffset"];
        }
        [result close];
        return @(offset);
    }] integerValue];
}


//通过会话ID获取最近的一次会话
-(ChatMessage *)getSessionLatestMessage:(NSString *)sessionID {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *result = [db executeQuery:@"select * from message where messageSessionId=? and messageInsertUser=? and messageType!=? and isDelete!=1 order by messageTableOffset desc,messageStamp desc limit 1"
                          withArgumentsInArray:@[
            sessionID,
            user.userExtendId,
            @(MSG_TYPE_ACTION)
        ]];
        
        ChatMessage *msg = nil;
        if ([result next]) {
            msg = [ChatMessage new];
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
            
            msg.messageReplyMsgId = [result stringForColumn:@"messageReplyMsgId"];
            msg.messageReplyMsgType = [result intForColumn:@"messageReplyMsgType"];
            msg.messageReplyMsgContent = [result stringForColumn:@"messageReplyMsgContent"];
            msg.messageReplyUserId = [result stringForColumn:@"messageReplyUserId"];
            msg.messageRecallUserId = [result stringForColumn:@"messageRecallUserId"];
            msg.messageAtUserIds = [result stringForColumn:@"messageAtUserIds"];
            msg.messageReadUserIds = [result stringForColumn:@"messageReadUserIds"];
            msg.messageDeleteUserIds = [result stringForColumn:@"messageDeleteUserIds"];
            
            msg.messageStamp = [result longForColumn:@"messageStamp"];
            msg.deleteDate = [result stringForColumn:@"deleteDate"];
        }
        [result close];
        return msg;
    }];
}

//获取消息
-(NSMutableArray *)getSessionOffsetMessages:(NSString *)sessionID
                                  andOffset:(NSString *)tabOffset
                        andSmallerThanStamp:(NSString *)stamp {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *result = [db executeQuery:@"select * from message where messageSessionId=? and messageTableOffset=? and messageStamp<? and messageInsertUser=? and messageType!=? and isDelete!=1 order by messageStamp desc"
                          withArgumentsInArray:@[
            sessionID,
            tabOffset,
            stamp,
            user.userExtendId,
            @(MSG_TYPE_ACTION)
        ]];
        NSMutableArray *retArray = [[NSMutableArray alloc] init];
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
            
            msg.messageReplyMsgId = [result stringForColumn:@"messageReplyMsgId"];
            msg.messageReplyMsgType = [result intForColumn:@"messageReplyMsgType"];
            msg.messageReplyMsgContent = [result stringForColumn:@"messageReplyMsgContent"];
            msg.messageReplyUserId = [result stringForColumn:@"messageReplyUserId"];
            msg.messageRecallUserId = [result stringForColumn:@"messageRecallUserId"];
            msg.messageAtUserIds = [result stringForColumn:@"messageAtUserIds"];
            msg.messageReadUserIds = [result stringForColumn:@"messageReadUserIds"];
            msg.messageDeleteUserIds = [result stringForColumn:@"messageDeleteUserIds"];
            
            msg.messageStamp = [result longForColumn:@"messageStamp"];
            msg.deleteDate = [result stringForColumn:@"deleteDate"];
            [retArray addObject:msg];
        }
        [result close];
        return retArray;
    } defaultValue: [[NSMutableArray alloc] init]];
}


//获取消息
-(NSMutableArray *)getSessionOffsetMessages:(NSString *)sessionID
                                  andOffset:(NSString *)tabOffset
                         andLargerThanStamp:(NSString *)stamp {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *result = [db executeQuery:@"select * from message where messageSessionId=? and messageTableOffset=? and messageStamp>? and messageInsertUser=? and messageType!=? and isDelete!=1 order by messageStamp desc"
                          withArgumentsInArray:@[
            sessionID,
            tabOffset,
            stamp,
            user.userExtendId,
            @(MSG_TYPE_ACTION)
        ]];
        NSMutableArray *retArray = [[NSMutableArray alloc] init];
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
            
            msg.messageReplyMsgId = [result stringForColumn:@"messageReplyMsgId"];
            msg.messageReplyMsgType = [result intForColumn:@"messageReplyMsgType"];
            msg.messageReplyMsgContent = [result stringForColumn:@"messageReplyMsgContent"];
            msg.messageReplyUserId = [result stringForColumn:@"messageReplyUserId"];
            msg.messageRecallUserId = [result stringForColumn:@"messageRecallUserId"];
            msg.messageAtUserIds = [result stringForColumn:@"messageAtUserIds"];
            msg.messageReadUserIds = [result stringForColumn:@"messageReadUserIds"];
            msg.messageDeleteUserIds = [result stringForColumn:@"messageDeleteUserIds"];
            
            msg.messageStamp = [result longForColumn:@"messageStamp"];
            msg.deleteDate = [result stringForColumn:@"deleteDate"];
            [retArray addObject:msg];
        }
        [result close];
        return retArray;
    } defaultValue: [[NSMutableArray alloc] init]];
}



//通过sessionID，获取之前的
-(NSMutableArray *)getSessionFormerMessages:(NSString *)sessionID withMessageID:(NSString *)messageId withSize:(NSInteger)size {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        
        //当前用户
        ChatSessionMember* sessionMember = [self getSessionMember:sessionID andMemberId:user.userId];
        
        //查询比当前消息小的stamp的消息而且messageTableOffset相等的
        ChatMessage *msg = [self getMessageById:messageId];
        NSMutableArray *sequeceArray = [self getSessionOffsetMessages:sessionID 
                                                            andOffset:[NSString stringWithFormat:@"%ld", (long)msg.messageTableOffset]
                                                  andSmallerThanStamp:[NSString stringWithFormat:@"%ld", (long)msg.messageStamp]];
        
        
        //获取消息
        FMResultSet *result = [db executeQuery:@"select * from message where messageSessionId=? and messageTableOffset<? and messageSessionOffset>? and messageInsertUser=? and messageType!=? and isDelete!=1 order by messageTableOffset desc,messageStamp desc limit ?"
                          withArgumentsInArray:@[
            sessionID,
            [NSNumber numberWithInteger:msg.messageTableOffset],
            [NSNumber numberWithInteger:sessionMember.sessionMemberLatestDelete],
            user.userExtendId,
            @(MSG_TYPE_ACTION),
            [NSNumber numberWithInteger:size]
        ]];
        NSMutableArray *listArray = [[NSMutableArray alloc] init];
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
            
            msg.messageReplyMsgId = [result stringForColumn:@"messageReplyMsgId"];
            msg.messageReplyMsgType = [result intForColumn:@"messageReplyMsgType"];
            msg.messageReplyMsgContent = [result stringForColumn:@"messageReplyMsgContent"];
            msg.messageReplyUserId = [result stringForColumn:@"messageReplyUserId"];
            msg.messageRecallUserId = [result stringForColumn:@"messageRecallUserId"];
            msg.messageAtUserIds = [result stringForColumn:@"messageAtUserIds"];
            msg.messageReadUserIds = [result stringForColumn:@"messageReadUserIds"];
            msg.messageDeleteUserIds = [result stringForColumn:@"messageDeleteUserIds"];
            
            msg.deleteDate = [result stringForColumn:@"deleteDate"];
            [listArray addObject:msg];
        }
        [result close];
        
        //返回值拼装，先放sequeceArray
        NSMutableArray *retArray = [[NSMutableArray alloc] initWithArray:sequeceArray];
        [retArray addObjectsFromArray:listArray];
        
        if (retArray.count > size) {
            NSRange range = NSMakeRange(0, size);
            retArray = [[NSMutableArray alloc] initWithArray:[retArray subarrayWithRange:range]];
        }
        return retArray;
    } defaultValue: [[NSMutableArray alloc] init]];
}


//通过sessionID，获取之后的
-(NSMutableArray *)getSessionNewerMessages:(NSString *)sessionID withMessageID:(NSString *)messageId withSize:(NSInteger)size {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        
        //查询比当前消息大的stamp的消息而且messageTableOffset相等的
        ChatMessage *msg = [self getMessageById:messageId];
        NSMutableArray *sequeceArray = [self getSessionOffsetMessages:sessionID 
                                                            andOffset:[NSString stringWithFormat:@"%ld", (long)msg.messageTableOffset]
                                                   andLargerThanStamp:[NSString stringWithFormat:@"%ld", (long)msg.messageStamp]];
        
        //获取消息
        FMResultSet *result = [db executeQuery:@"select * from message where messageSessionId=? and messageTableOffset>? and messageInsertUser=? and messageType!=? and isDelete!=1 order by messageTableOffset desc,messageStamp desc limit ?"
                          withArgumentsInArray:@[
            sessionID,
            [NSNumber numberWithInteger:msg.messageTableOffset],
            user.userExtendId,
            @(MSG_TYPE_ACTION),
            [NSNumber numberWithInteger:size]
        ]];
        NSMutableArray *listArray = [[NSMutableArray alloc] init];
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
            
            msg.messageReplyMsgId = [result stringForColumn:@"messageReplyMsgId"];
            msg.messageReplyMsgType = [result intForColumn:@"messageReplyMsgType"];
            msg.messageReplyMsgContent = [result stringForColumn:@"messageReplyMsgContent"];
            msg.messageReplyUserId = [result stringForColumn:@"messageReplyUserId"];
            msg.messageRecallUserId = [result stringForColumn:@"messageRecallUserId"];
            msg.messageAtUserIds = [result stringForColumn:@"messageAtUserIds"];
            msg.messageReadUserIds = [result stringForColumn:@"messageReadUserIds"];
            msg.messageDeleteUserIds = [result stringForColumn:@"messageDeleteUserIds"];
            
            msg.deleteDate = [result stringForColumn:@"deleteDate"];
            [listArray addObject:msg];
        }
        [result close];
        
        
        //返回值拼装，先放listArray
        NSMutableArray *retArray = [[NSMutableArray alloc] initWithArray:listArray];
        [retArray addObjectsFromArray:sequeceArray];
        
        if (retArray.count > size) {
            NSRange range = NSMakeRange(retArray.count-size, size);
            retArray = [[NSMutableArray alloc] initWithArray:[retArray subarrayWithRange:range]];
        }
        return retArray;
    } defaultValue: [[NSMutableArray alloc] init]];
}


//获取没有处理的系统消息
-(NSMutableArray *)getNotActionSystemMessageBySessionId:(NSString *)sessionID {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *result = [db executeQuery:@"select * from message where messageType=0 and messageReadState=0 and messageSessionId=? and messageInsertUser=? order by messageTableOffset desc"
                          withArgumentsInArray:@[sessionID, user.userExtendId]];
        NSMutableArray *retArray = [[NSMutableArray alloc] init];
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
            
            msg.messageReplyMsgId = [result stringForColumn:@"messageReplyMsgId"];
            msg.messageReplyMsgType = [result intForColumn:@"messageReplyMsgType"];
            msg.messageReplyMsgContent = [result stringForColumn:@"messageReplyMsgContent"];
            msg.messageReplyUserId = [result stringForColumn:@"messageReplyUserId"];
            msg.messageRecallUserId = [result stringForColumn:@"messageRecallUserId"];
            msg.messageAtUserIds = [result stringForColumn:@"messageAtUserIds"];
            msg.messageReadUserIds = [result stringForColumn:@"messageReadUserIds"];
            msg.messageDeleteUserIds = [result stringForColumn:@"messageDeleteUserIds"];
            
            msg.messageStamp = [result longForColumn:@"messageStamp"];
            msg.deleteDate = [result stringForColumn:@"deleteDate"];
            [retArray addObject:msg];
        }
        [result close];
        return retArray;
    } defaultValue: [[NSMutableArray alloc] init]];
}

//获取没有处理的系统消息
-(NSMutableArray *)getNotActionSystemMessage {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *result = [db executeQuery:@"select * from message where messageReadState=0 and messageType=? and messageInsertUser=? order by messageTableOffset asc"
                          withArgumentsInArray:@[
            @(MSG_TYPE_SYSTEM),
            user.userExtendId
        ]];
        NSMutableArray *retArray = [[NSMutableArray alloc] init];
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
            
            
            msg.messageReplyMsgId = [result stringForColumn:@"messageReplyMsgId"];
            msg.messageReplyMsgType = [result intForColumn:@"messageReplyMsgType"];
            msg.messageReplyMsgContent = [result stringForColumn:@"messageReplyMsgContent"];
            msg.messageReplyUserId = [result stringForColumn:@"messageReplyUserId"];
            msg.messageRecallUserId = [result stringForColumn:@"messageRecallUserId"];
            msg.messageAtUserIds = [result stringForColumn:@"messageAtUserIds"];
            msg.messageReadUserIds = [result stringForColumn:@"messageReadUserIds"];
            msg.messageDeleteUserIds = [result stringForColumn:@"messageDeleteUserIds"];
            
            msg.messageStamp = [result longForColumn:@"messageStamp"];
            msg.deleteDate = [result stringForColumn:@"deleteDate"];
            [retArray addObject:msg];
        }
        [result close];
        return retArray;
    } defaultValue: [[NSMutableArray alloc] init]];
}

//处理动作消息插入
-(void)handleActionMessageUpdate:(ChatMessage *)msg {
    [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        if (msg.messageType != MSG_TYPE_ACTION) {
            return nil;
        }
        ChatAction *action = [msg getChatAction];
        switch (action.actionType) {
            case ACTION_TYPE_MSG_RECALL: {
                NSString *userId = action.actionIds[0];
                NSString *messageId = action.actionIds[2];
                [self updateMessageRecall:userId andMessageId:messageId];
                break;
            }
            case ACTION_TYPE_MSG_DELETE: {
                NSString *userId = action.actionIds[0];
                NSString *messageId = action.actionIds[2];
                [self updateMessageDelete:userId andMessageId:messageId];
                break;
            }
            case ACTION_TYPE_SESSION_READ: {
                NSString *userId = action.actionIds[0];
                NSString *sessionId = action.actionIds[1];
                NSString *tableOffset = action.actionIds[2];
                [self updateMessageRead:userId andSessionId:sessionId andTableSeq:tableOffset];
                [self updateSessionMemberLatestRead:userId andSessionId:sessionId andTableSeq:tableOffset];
                break;
            }
            case ACTION_TYPE_SESSION_MUTE: {
                NSString *userId = action.actionIds[0];
                NSString *sessionId = action.actionIds[1];
                NSString *mute = action.actionIds[2];
                [self updateSessionMemberMute:userId andSessionId:sessionId andMute:mute];
                break;
            }
            case ACTION_TYPE_SESSION_PIN: {
                NSString *userId = action.actionIds[0];
                NSString *sessionId = action.actionIds[1];
                NSString *pinned = action.actionIds[2];
                [self updateSessionMemberPinned:userId andSessionId:sessionId andPinned:pinned];
                break;
            }
            case ACTION_TYPE_SESSION_DELETE_TEMP: {
                NSString *userId = action.actionIds[0];
                NSString *sessionId = action.actionIds[1];
                NSString *sessionOffset = action.actionIds[2];
                [self updateSessionDeleteTemp:userId andSessionId:sessionId andSessionOffset:sessionOffset];
                break;
            }
            case ACTION_TYPE_SESSION_DELETE_PERMANENT: {
                NSString *userId = action.actionIds[0];
                NSString *sessionId = action.actionIds[1];
                NSString *sessionOffset = action.actionIds[2];
                [self updateSessionDeletePermanent:userId andSessionId:sessionId andSessionOffset:sessionOffset];
                break;
            }
        }
        [self updateMessageReadByMsgId:msg.messageId];
        return nil;
    }];
}

//更新消息已读
-(void)updateMessageRecall:(NSString *)userId andMessageId:(NSString *)messageId {
    [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        [db executeUpdate:@"update message set isDelete=1,messageRecallUserId=?,messageReadState=1 where messageInsertUser=? and messageId=?"
     withArgumentsInArray:@[
            userId,
            user.userExtendId,
            messageId
        ]];
        return nil;
    }];
}

//更新消息被删除
-(void)updateMessageDelete:(NSString *)userId andMessageId:(NSString *)messageId {
    ChatMessage *message = [self getMessageById:messageId];
    if (message == nil || message.isDelete == 1) {
        return;
    }
    message.isDelete = 0;
    
    //添加
    NSMutableArray *arrayAdd = [FlappyStringTool splitStr:message.messageDeleteUserIds withSeprate:@","];
    [arrayAdd addObject:userId];
    message.messageDeleteUserIds = [FlappyStringTool joinStr:arrayAdd withSeprate:@","];
    
    message.messageReadState = 1;
    [self insertMessage:message];
}

//更新消息已读
-(void)updateMessageRead:(NSString *)userId andSessionId:(NSString *)sessionId andTableSeq:(NSString *)tableOffset {
    [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        [db executeUpdate:@"update message set messageReadState=1, messageReadUserIds = IFNULL(messageReadUserIds, '') || CASE WHEN messageReadUserIds IS NULL OR messageReadUserIds = '' THEN '' ELSE ',' END || ?  where messageInsertUser=? and messageSendId!=? and messageSessionId=? and messageTableOffset<=? and messageType NOT IN (?, ?)"
     withArgumentsInArray:@[
            userId,
            user.userExtendId,
            userId,
            sessionId,
            tableOffset,
            @(MSG_TYPE_SYSTEM),
            @(MSG_TYPE_ACTION),
        ]];
        return nil;
    }];
}

//更新消息已读
-(void)updateMessageReadByMsgId:(NSString *)messageId{
    [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        [db executeUpdate:@"update message set messageReadState=1 where messageInsertUser=? and messageId!=?"
     withArgumentsInArray:@[
            user.userExtendId,
            messageId,
        ]];
        return nil;
    }];
}


//更新最近已读的消息
-(void)updateSessionOffset:(NSString *)sessionId andSessionOffset:(NSInteger)sessionOffset {
    [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        BOOL result = [db executeUpdate:@"UPDATE session SET sessionOffset = ? WHERE sessionId = ? AND sessionInsertUser = ? AND sessionOffset < ?"
                   withArgumentsInArray:@[
            [NSString stringWithFormat:@"%ld", (long)sessionOffset],
            sessionId,
            user.userExtendId,
            [NSString stringWithFormat:@"%ld", (long)sessionOffset]
        ]];
        if (!result) {
            NSLog(@"更新会话失败: %@", [db lastErrorMessage]);
        }
        return nil;
    }];
}

//更新最近已读的消息
-(void)updateSessionMemberLatestRead:(NSString *)userId andSessionId:(NSString *)sessionId andTableSeq:(NSString *)tableOffset {
    ChatSessionMember *data = [self getSessionMember:sessionId andMemberId:userId];
    if (data != nil) {
        data.sessionMemberLatestRead = [tableOffset longLongValue];
        [self insertSessionMember:data];
    }
}

//更新mute
-(void)updateSessionMemberMute:(NSString *)userId andSessionId:(NSString *)sessionId andMute:(NSString *)mute {
    ChatSessionMember *data = [self getSessionMember:sessionId andMemberId:userId];
    if (data != nil) {
        data.sessionMemberMute = [mute integerValue];
        [self insertSessionMember:data];
    }
}

//更新pinned
-(void)updateSessionMemberPinned:(NSString *)userId andSessionId:(NSString *)sessionId andPinned:(NSString *)pinned {
    ChatSessionMember *data = [self getSessionMember:sessionId andMemberId:userId];
    if (data != nil) {
        data.sessionMemberPinned = [pinned integerValue];
        [self insertSessionMember:data];
    }
}

//更新删除
-(void)updateSessionDeleteTemp:(NSString *)userId andSessionId:(NSString *)sessionId andSessionOffset:(NSString *)sessionOffset {
    ChatSessionMember *data = [self getSessionMember:sessionId andMemberId:userId];
    if (data != nil) {
        data.sessionMemberLatestDelete = [sessionOffset longLongValue];
        [self insertSessionMember:data];
    }
}

//更新删除
-(void)updateSessionDeletePermanent:(NSString *)userId andSessionId:(NSString *)sessionId andSessionOffset:(NSString *)sessionOffset {
    ChatSessionData *session = [self getUserSessionByID:sessionId];
    if (session != nil) {
        session.isDelete = 1;
        [self insertSession:session];
    }
}

@end
