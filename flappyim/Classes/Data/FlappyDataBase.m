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
    "messagePinState INTEGER,"
    "messageSecret TEXT,"
    "isDelete INTEGER,"
    
    "messageReplyMsgId TEXT,"
    "messageReplyMsgType INTEGER,"
    "messageReplyMsgContent TEXT,"
    "messageReplyUserId TEXT,"
    
    "messageForwardTitle TEXT,"
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
    "sessionEnable INTEGER,"
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
    "sessionMemberType INTEGER,"
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

//通用的数据库操作模板方法，默认不使用事务
- (id)executeDbOperation:(id (^)(FMDatabase *db, ChatUser *user))operation {
    return [self executeDbOperation:operation defaultValue:nil useTransaction:NO];
}

//通用的数据库操作模板方法，支持默认值，默认不使用事务
- (id)executeDbOperation:(id (^)(FMDatabase *db, ChatUser *user))operation
            defaultValue:(id)defaultValue {
    return [self executeDbOperation:operation defaultValue:defaultValue useTransaction:NO];
}

//通用的数据库操作模板方法，支持事务开启参数
- (id)executeDbOperation:(id (^)(FMDatabase *db, ChatUser *user))operation
            defaultValue:(id)defaultValue
          useTransaction:(BOOL)useTransaction {
    //打开数据库连接
    [self openDB];
    //获取当前登录用户
    ChatUser *user = [[FlappyData shareInstance] getUser];
    id result = nil;
    
    //如果用户存在，执行数据库操作
    if (user != nil) {
        @try {
            //如果启用事务，则开启事务
            if (useTransaction) {
                [database beginTransaction];
            }
            //执行具体的数据库操作
            result = operation(database, user);
            //如果启用事务，则提交事务
            if (useTransaction) {
                [database commit];
            }
        } @catch (NSException *exception) {
            //如果启用事务，则回滚事务
            if (useTransaction) {
                [database rollback];
            }
            //打印异常日志，便于调试
            NSLog(@"Database operation failed: %@", exception);
        } @finally {
            //关闭数据库连接
            [self closeDB];
        }
    } else {
        //如果用户不存在，直接关闭数据库
        [self closeDB];
    }
    //返回结果，如果为 nil，则返回默认值
    return result == nil ? defaultValue : result;
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
        for (ChatMessage *msg in array) {
            //更新会话偏移量
            [self updateSessionOffset:msg.messageSessionId andSessionOffset:msg.messageSessionOffset];
            //获取消息的前一条记录
            ChatMessage *fomerMsg = [self getMessageById:msg.messageId];
            //插入或更新消息
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
                           "messagePinState,"
                           "messageSecret,"
                           "messageDate,"
                           "deleteDate,"
                           "messageStamp,"
                           "isDelete,"
                           "messageReplyMsgId,"
                           "messageReplyMsgType,"
                           "messageReplyMsgContent,"
                           "messageReplyUserId,"
                           "messageForwardTitle,"
                           "messageRecallUserId,"
                           "messageAtUserIds,"
                           "messageReadUserIds,"
                           "messageDeleteUserIds,"
                           "messageInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
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
                [NSNumber numberWithInteger:msg.messagePinState],
                [FlappyStringTool toUnNullStr:msg.messageSecret],
                [FlappyStringTool toUnNullStr:msg.messageDate],
                [FlappyStringTool toUnNullStr:msg.deleteDate],
                (fomerMsg != nil ? [NSNumber numberWithInteger:fomerMsg.messageStamp] : [NSNumber numberWithInteger:(NSInteger)([NSDate date].timeIntervalSince1970 * 1000)]),
                [NSNumber numberWithInteger:msg.isDelete],
                
                [FlappyStringTool toUnNullStr:msg.messageReplyMsgId],
                [NSNumber numberWithInteger:msg.messageReplyMsgType],
                [FlappyStringTool toUnNullStr:msg.messageReplyMsgContent],
                [FlappyStringTool toUnNullStr:msg.messageReplyUserId],
                [FlappyStringTool toUnNullStr:msg.messageForwardTitle],
                [FlappyStringTool toUnNullStr:msg.messageRecallUserId],
                [FlappyStringTool toUnNullStr:msg.messageAtUserIds],
                [FlappyStringTool toUnNullStr:msg.messageReadUserIds],
                [FlappyStringTool toUnNullStr:msg.messageDeleteUserIds],
                
                user.userExtendId
            ]];
            //如果插入或更新失败，返回 nil 并中止操作
            if (!result) {
                NSLog(@"插入或更新消息失败: %@", [db lastErrorMessage]);
                return nil;
            }
        }
        return @(YES);
    } defaultValue:@(NO) useTransaction:YES];
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
                       "messagePinState,"
                       "messageSecret,"
                       "messageDate,"
                       "deleteDate,"
                       "messageStamp,"
                       "isDelete,"
                       "messageReplyMsgId,"
                       "messageReplyMsgType,"
                       "messageReplyMsgContent,"
                       "messageReplyUserId,"
                       "messageForwardTitle,"
                       "messageRecallUserId,"
                       "messageAtUserIds,"
                       "messageReadUserIds,"
                       "messageDeleteUserIds,"
                       "messageInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
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
            [NSNumber numberWithInteger:msg.messagePinState],
            [FlappyStringTool toUnNullStr:msg.messageSecret],
            [FlappyStringTool toUnNullStr:msg.messageDate],
            [FlappyStringTool toUnNullStr:msg.deleteDate],
            (fomerMsg != nil ? [NSNumber numberWithInteger:fomerMsg.messageStamp] : [NSNumber numberWithInteger:(NSInteger)([NSDate date].timeIntervalSince1970 * 1000)]),
            [NSNumber numberWithInteger:msg.isDelete],
            
            [FlappyStringTool toUnNullStr:msg.messageReplyMsgId],
            [NSNumber numberWithInteger:msg.messageReplyMsgType],
            [FlappyStringTool toUnNullStr:msg.messageReplyMsgContent],
            [FlappyStringTool toUnNullStr:msg.messageReplyUserId],
            [FlappyStringTool toUnNullStr:msg.messageForwardTitle],
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
                       "messagePinState=?,"
                       "messageSecret=?,"
                       "messageDate=?,"
                       "deleteDate=?,"
                       "isDelete=?,"
                       
                       "messageReplyMsgId=?,"
                       "messageReplyMsgType=?,"
                       "messageReplyMsgContent=?,"
                       "messageReplyUserId=?,"
                       "messageForwardTitle=?,"
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
            [NSNumber numberWithInteger:msg.messagePinState],
            [FlappyStringTool toUnNullStr:msg.messageSecret],
            [FlappyStringTool toUnNullStr:msg.messageDate],
            [FlappyStringTool toUnNullStr:msg.deleteDate],
            [NSNumber numberWithInteger:msg.isDelete],
            
            [FlappyStringTool toUnNullStr:msg.messageReplyMsgId],
            [NSNumber numberWithInteger:msg.messageReplyMsgType],
            [FlappyStringTool toUnNullStr:msg.messageReplyMsgContent],
            [FlappyStringTool toUnNullStr:msg.messageReplyUserId],
            [FlappyStringTool toUnNullStr:msg.messageForwardTitle],
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
            msg = [[ChatMessage alloc] initWithResult:result];
        }
        [result close];
        return msg;
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
        FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM message WHERE messageInsertUser=? and messageSessionId=? and messageSendId!=? and messageReadState=0 and (messageRecallUserId is null or messageRecallUserId == '') and (messageDeleteUserIds not like ?) and messageType not in (?,?,?)"
                           withArgumentsInArray:@[
            user.userExtendId,
            sessionId,
            user.userId,
            [NSString stringWithFormat:@"%%%@%%",user.userId],
            @(MSG_TYPE_SYSTEM),
            @(MSG_TYPE_ACTION),
            @(MSG_TYPE_READ_RECEIPT),
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
        FMResultSet *result = [db executeQuery:@"select * from message where messageSessionId=? and messageInsertUser=? and messageType not in (?,?) and isDelete!=1 order by messageTableOffset desc,messageStamp desc limit 1"
                          withArgumentsInArray:@[
            sessionId,
            user.userExtendId,
            @(MSG_TYPE_ACTION),
            @(MSG_TYPE_READ_RECEIPT)
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
            msg.isEnable = [result intForColumn:@"sessionEnable"];
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
-(Boolean)insertSessionInfo:(ChatSession*)data {
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
                       "sessionEnable,"
                       "sessionDeleted,"
                       "sessionDeletedDate,"
                       "sessionInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
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
            [NSNumber numberWithInteger:data.isEnable],
            [NSNumber numberWithInteger:data.isDelete],
            [FlappyStringTool toUnNullStr:data.deleteDate],
            user.userExtendId
        ]];
        return @(result);
    }] boolValue];
}


- (BOOL)insertOrUpdateSessionData:(ChatSessionData *)data
                       inDatabase:(FMDatabase *)db
                         withUser:(ChatUser *)user {
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
                   "sessionEnable,"
                   "sessionDeleted,"
                   "sessionDeletedDate,"
                   "sessionInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
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
        [NSNumber numberWithInteger:data.isEnable],
        [NSNumber numberWithInteger:data.isDelete],
        [FlappyStringTool toUnNullStr:data.deleteDate],
        user.userExtendId
    ]];
    
    //如果会话用户不为空
    if (data.users != nil && data.users.count > 0) {
        
        //获取当前会话的所有用户 ID
        NSMutableArray<NSString *> *currentUserIds = [NSMutableArray array];
        for (ChatSessionMember *member in data.users) {
            [currentUserIds addObject:[FlappyStringTool toUnNullStr:member.userId]];
        }
        
        //查询数据库中该会话的所有用户 ID（根据 sessionId 和 sessionInsertUser 筛选）
        NSMutableArray<NSString *> *existingUserIds = [NSMutableArray array];
        FMResultSet *resultSet = [db executeQuery:@"SELECT userId FROM session_member WHERE sessionId = ? AND sessionInsertUser = ?",
                                  [FlappyStringTool toUnNullStr:data.sessionId],
                                  user.userExtendId];
        while ([resultSet next]) {
            [existingUserIds addObject:[resultSet stringForColumn:@"userId"]];
        }
        [resultSet close];
        
        //找出需要更新的用户 ID
        NSMutableArray<NSString *> *usersToMarkAsLeft = [existingUserIds mutableCopy];
        [usersToMarkAsLeft removeObjectsInArray:currentUserIds];
        
        //将这些用户的 isLeave 字段置为 true
        if (usersToMarkAsLeft.count > 0) {
            NSMutableString *placeholders = [NSMutableString string];
            for (NSInteger i = 0; i < usersToMarkAsLeft.count; i++) {
                [placeholders appendString:@"?"];
                if (i < usersToMarkAsLeft.count - 1) {
                    [placeholders appendString:@","];
                }
            }
            NSString *sql = [NSString stringWithFormat:@"UPDATE session_member SET isLeave = 1 WHERE sessionId = ? AND sessionInsertUser = ? AND userId IN (%@)", placeholders];
            NSMutableArray *args = [NSMutableArray arrayWithObjects:[FlappyStringTool toUnNullStr:data.sessionId], user.userExtendId, nil];
            [args addObjectsFromArray:usersToMarkAsLeft];
            [db executeUpdate:sql withArgumentsInArray:args];
        }
        
        //插入或更新当前会话的用户
        for (ChatSessionMember *member in data.users) {
            [db executeUpdate:@"INSERT OR REPLACE INTO session_member("
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
             "sessionMemberType,"
             "sessionMemberMute,"
             "sessionMemberPinned,"
             "sessionJoinDate,"
             "sessionLeaveDate,"
             "isLeave,"
             "sessionInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
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
                [NSNumber numberWithInteger:member.sessionMemberType],
                [NSNumber numberWithInteger:member.sessionMemberMute],
                [NSNumber numberWithInteger:member.sessionMemberPinned],
                [FlappyStringTool toUnNullStr:member.sessionJoinDate],
                [FlappyStringTool toUnNullStr:member.sessionLeaveDate],
                [NSNumber numberWithInteger:member.isLeave],
                user.userExtendId
            ]];
        }
    }
    return result;
}


// 插入单条会话，如果存在就更新
- (Boolean)insertSession:(ChatSessionData *)data {
    return [[self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        // 调用公共方法插入或更新单个会话
        BOOL result = [self insertOrUpdateSessionData:data inDatabase:db withUser:user];
        return @(result);
    } defaultValue:@(NO) useTransaction:YES] boolValue];
}

//插入多个会话
-(Boolean)insertSessions:(NSMutableArray<ChatSessionData *> *)array {
    return [[self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        for (ChatSessionData *data in array) {
            [self insertOrUpdateSessionData:data inDatabase:db withUser:user];
        }
        return @(YES);
    } defaultValue:@(NO) useTransaction:YES] boolValue];
}

//获取用户的会话(用户仅包含自己)
-(ChatSessionData*) getUserSessionOnlyCurrentUserById:(NSString*)sessionId
                                            andUserId:(NSString*)userId{
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
            msg.isEnable = [result intForColumn:@"sessionEnable"];
            msg.isDelete = [result intForColumn:@"sessionDeleted"];
            msg.deleteDate = [result stringForColumn:@"sessionDeletedDate"];
            msg.unReadMessageCount = [self getUnReadSessionMessageCountBySessionId:msg.sessionId];
            msg.isDeleteTemp = [self getIsDeleteTemp:msg.sessionId];
            NSMutableArray* array = [[NSMutableArray alloc] init];
            ChatSessionMember* member = [self getSessionMember:sessionId andMemberId:userId];
            if(member!=nil){
                [array addObject:member];
            }
            msg.users = array;
        }
        [result close];
        return msg;
    }];
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
            msg.isEnable = [result intForColumn:@"sessionEnable"];
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
            msg.isEnable = [result intForColumn:@"sessionEnable"];
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

//删除用户的会话
-(Boolean)setUserSession:(NSString *)sessionId
                isEnable:(NSInteger)enable{
    return [[self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        BOOL flag = [db executeUpdate:@"update session set sessionEnable = ? where sessionId=? and sessionInsertUser=?"
                 withArgumentsInArray:@[@(enable),sessionId, user.userExtendId]];
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
                     "sessionMemberType,"
                     "sessionMemberMute,"
                     "sessionMemberPinned,"
                     "sessionJoinDate,"
                     "sessionLeaveDate,"
                     "isLeave,"
                     "sessionInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
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
            [NSNumber numberWithInteger:member.sessionMemberType],
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
            member.sessionMemberType = [result intForColumn:@"sessionMemberType"];
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

//获取不在活跃会话中的成员列表
- (NSMutableArray*)getSyncNotActiveMember:(NSArray*)activeSessionIds {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        //构建SQL查询条件
        NSMutableString *whereClause = [NSMutableString string];
        //添加sessionInsertUser参数
        NSMutableArray *arguments = [[NSMutableArray alloc] init];
        [arguments addObject:user.userExtendId];
        [arguments addObject:user.userId];
        
        if (activeSessionIds && [activeSessionIds isKindOfClass:[NSArray class]] && activeSessionIds.count > 0) {
            [whereClause appendString:@" AND sessionId NOT IN ("];
            for (int i = 0; i < activeSessionIds.count; i++) {
                [whereClause appendString:@"?"];
                if (i < activeSessionIds.count - 1) {
                    [whereClause appendString:@", "];
                }
                [arguments addObject:activeSessionIds[i]];
            }
            [whereClause appendString:@")"];
        }
        //构建完整的查询语句
        NSString *query = [NSString stringWithFormat:@"select * from session_member where sessionInsertUser = ? and userId = ? and isLeave != 1%@", whereClause];
        //执行查询
        FMResultSet *result = [db executeQuery:query withArgumentsInArray:arguments];
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
            member.sessionMemberType = [result intForColumn:@"sessionMemberType"];
            member.sessionMemberMute = [result intForColumn:@"sessionMemberMute"];
            member.sessionMemberPinned = [result intForColumn:@"sessionMemberPinned"];
            member.sessionJoinDate = [result stringForColumn:@"sessionJoinDate"];
            member.sessionLeaveDate = [result stringForColumn:@"sessionLeaveDate"];
            member.isLeave = [result intForColumn:@"isLeave"];
            [memberList addObject:member];
        }
        [result close];
        return memberList;
    } defaultValue:[[NSMutableArray alloc] init]];
}

//获取会话ID的用户列表
-(NSMutableArray *)getSessionMemberList:(NSString *)sessionId {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *result = [db executeQuery:@"select * from session_member where sessionInsertUser=? and sessionId=? order by sessionJoinDate asc"
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
            member.sessionMemberType = [result intForColumn:@"sessionMemberType"];
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


//通过会话ID获取最近的一次会话
-(NSInteger)getSessionOffsetLatest:(NSString *)sessionID {
    return [[self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *result = [db executeQuery:@"select * from message where messageSessionId=? and messageInsertUser=? and messageType not in (?,?) and messageSendState in (1,2,3,4) order by messageTableOffset desc,messageStamp desc limit 1"
                          withArgumentsInArray:@[
            sessionID,
            user.userExtendId,
            @(MSG_TYPE_ACTION),
            @(MSG_TYPE_READ_RECEIPT)
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
        //当前用户
        ChatSessionMember* sessionMember = [self getSessionMember:sessionID andMemberId:user.userId];
        FMResultSet *result = [db executeQuery:@"select * from message where messageSessionId=? and messageInsertUser=? and messageSessionOffset>? and messageType not in (?,?) and isDelete!=1 order by messageTableOffset desc,messageStamp desc limit 1"
                          withArgumentsInArray:@[
            sessionID,
            user.userExtendId,
            [NSNumber numberWithInteger:sessionMember!=nil ? sessionMember.sessionMemberLatestDelete : 0],
            @(MSG_TYPE_ACTION),
            @(MSG_TYPE_READ_RECEIPT)
        ]];
        
        ChatMessage *msg = nil;
        if ([result next]) {
            msg = [[ChatMessage alloc] initWithResult:result];
        }
        [result close];
        return msg;
    }];
}



// 获取所有 @ 我的消息（支持分页）
- (NSMutableArray *)getAllAtMeMessages:(NSString *)sessionID
                            incluedAll:(BOOL)includeAll
                                  page:(NSInteger)page
                                  size:(NSInteger)size {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        //当前用户
        ChatSessionMember *sessionMember = [self getSessionMember:sessionID andMemberId:user.userId];
        //构建 SQL 查询
        NSMutableString *query = [NSMutableString stringWithString:
                                  @"SELECT * FROM message WHERE messageSessionId=?  AND messageSendId != ? AND messageSessionOffset>? AND messageInsertUser=? AND messageType not in (?,?) AND isDelete!=1"];
        //如果 includeAll为YES，则增加对"all"的判断
        if (includeAll) {
            [query appendString:@" AND (messageAtUserIds LIKE ? OR messageAtUserIds LIKE ?)"];
        } else {
            [query appendString:@" AND messageAtUserIds LIKE ?"];
        }
        [query appendString:@" ORDER BY messageTableOffset ASC, messageStamp ASC LIMIT ? OFFSET ?"];
        //构建参数列表
        NSMutableArray *arguments = [NSMutableArray array];
        //对应 messageSessionId=?
        [arguments addObject:sessionID];
        //对应 messageSessionId=?
        [arguments addObject:user.userId];
        //对应 messageSessionOffset>?
        [arguments addObject:@(sessionMember != nil ? sessionMember.sessionMemberLatestDelete : 0)];
        //对应 messageInsertUser=?
        [arguments addObject:user.userExtendId];
        //动作消息排除
        [arguments addObject:@(MSG_TYPE_ACTION)];
        //回执消息排除
        [arguments addObject:@(MSG_TYPE_READ_RECEIPT)];
        
        if (includeAll) {
            //针对当前用户的 @
            [arguments addObject:[NSString stringWithFormat:@"%%%@%%", sessionMember.userId]];
            
            //针对 "all" 的 @
            [arguments addObject:[NSString stringWithFormat:@"%%%@%%", MESSAGE_AT_ALL]];
        } else {
            //仅针对当前用户的 @
            [arguments addObject:[NSString stringWithFormat:@"%%%@%%", sessionMember.userId]];
        }
        //对应 LIMIT ?
        [arguments addObject:@(size)];
        //对应 OFFSET ?
        [arguments addObject:@((page - 1) * size)];
        //执行查询
        FMResultSet *result = [db executeQuery:query withArgumentsInArray:arguments];
        //转换结果为数组
        NSMutableArray *listArray = [[NSMutableArray alloc] init];
        while ([result next]) {
            ChatMessage *msg = [[ChatMessage alloc] initWithResult:result];
            [listArray addObject:msg];
        }
        [result close];
        
        return listArray;
        
    } defaultValue:[[NSMutableArray alloc] init]];
}


//获取未读的at我的消息
-(NSMutableArray*)getUnReadAtMeMessages:(NSString*)sessionID
                             incluedAll:(Boolean)includeAll
                               withSize:(NSInteger)size{
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        
        //当前用户
        ChatSessionMember *sessionMember = [self getSessionMember:sessionID andMemberId:user.userId];
        //构建 SQL 查询
        NSMutableString *query = [NSMutableString stringWithString:
                                  @"SELECT * FROM message WHERE messageSessionId=? AND messageSendId != ? AND messageReadState=0 AND messageSessionOffset>? AND messageInsertUser=? AND messageType not in (?,?) AND isDelete!=1"];
        //如果includeAll为YES，则增加对"all"的判断
        if (includeAll) {
            [query appendString:@" AND (messageAtUserIds LIKE ? OR messageAtUserIds LIKE ?)"];
        } else {
            [query appendString:@" AND messageAtUserIds LIKE ?"];
        }
        [query appendString:@" ORDER BY messageTableOffset ASC, messageStamp ASC LIMIT ?"];
        
        //构建参数列表
        NSMutableArray *arguments = [NSMutableArray array];
        //对应 messageSessionId=?
        [arguments addObject:sessionID];
        //对应 messageSessionId=?
        [arguments addObject:user.userId];
        //对应 messageSessionOffset>?
        [arguments addObject:@(sessionMember != nil ? sessionMember.sessionMemberLatestDelete : 0)];
        //对应 messageInsertUser=?
        [arguments addObject:user.userExtendId];
        //动作消息排除
        [arguments addObject:@(MSG_TYPE_ACTION)];
        //回执消息排除
        [arguments addObject:@(MSG_TYPE_READ_RECEIPT)];
        if (includeAll) {
            //针对当前用户的 @
            [arguments addObject:[NSString stringWithFormat:@"%%%@%%", sessionMember.userId]];
            //针对 "all" 的 @
            [arguments addObject:[NSString stringWithFormat:@"%%%@%%", MESSAGE_AT_ALL]];
        } else {
            //仅针对当前用户的 @
            [arguments addObject:[NSString stringWithFormat:@"%%%@%%", sessionMember.userId]];
        }
        //对应 LIMIT ?
        [arguments addObject:@(size)];
        //执行查询
        FMResultSet *result = [db executeQuery:query withArgumentsInArray:arguments];
        //转换结果为数组
        NSMutableArray *listArray = [[NSMutableArray alloc] init];
        while ([result next]) {
            ChatMessage *msg = [[ChatMessage alloc] initWithResult:result];
            [listArray addObject:msg];
        }
        [result close];
        return listArray;
    } defaultValue:[[NSMutableArray alloc] init]];
}


//通过sessionID，获取之前的
-(NSMutableArray *)getSessionFormerMessages:(NSString *)sessionID withMessageID:(NSString *)messageId withSize:(NSInteger)size {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        
        //当前用户
        ChatSessionMember* sessionMember = [self getSessionMember:sessionID andMemberId:user.userId];
        
        //查询比当前消息小的stamp的消息而且messageTableOffset相等的
        ChatMessage *msg = [self getMessageById:messageId];
        
        //获取消息
        FMResultSet *result = [db executeQuery:@"select * from message where messageSessionId=? and (messageTableOffset < ? or (messageTableOffset = ? and messageStamp < ?)) and messageSessionOffset>? and messageInsertUser=? and messageType not in (?,?) and isDelete!=1 order by messageTableOffset desc,messageStamp desc limit ?"
                          withArgumentsInArray:@[
            sessionID,
            [NSNumber numberWithInteger:msg.messageTableOffset],
            [NSNumber numberWithInteger:msg.messageTableOffset],
            [NSNumber numberWithInteger:msg.messageStamp],
            [NSNumber numberWithInteger:sessionMember!=nil ? sessionMember.sessionMemberLatestDelete : 0],
            user.userExtendId,
            @(MSG_TYPE_ACTION),
            @(MSG_TYPE_READ_RECEIPT),
            [NSNumber numberWithInteger:size]
        ]];
        NSMutableArray *listArray = [[NSMutableArray alloc] init];
        while ([result next]) {
            ChatMessage *msg = [[ChatMessage alloc] initWithResult:result];
            [listArray addObject:msg];
        }
        [result close];
        
        return listArray;
    } defaultValue: [[NSMutableArray alloc] init]];
}


//通过sessionID，获取之后的
-(NSMutableArray *)getSessionNewerMessages:(NSString *)sessionID withMessageID:(NSString *)messageId withSize:(NSInteger)size {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        
        //查询比当前消息大的stamp的消息而且messageTableOffset相等的
        ChatMessage *msg = [self getMessageById:messageId];
        
        //获取消息
        FMResultSet *result = [db executeQuery:@"select * from message where messageSessionId=? and (messageTableOffset > ? or (messageTableOffset = ? and messageStamp > ?)) and messageInsertUser=? and messageType not in (?,?) and isDelete!=1 order by messageTableOffset asc,messageStamp asc limit ?"
                          withArgumentsInArray:@[
            sessionID,
            [NSNumber numberWithInteger:msg.messageTableOffset],
            [NSNumber numberWithInteger:msg.messageTableOffset],
            [NSNumber numberWithInteger:msg.messageStamp],
            user.userExtendId,
            @(MSG_TYPE_ACTION),
            @(MSG_TYPE_READ_RECEIPT),
            [NSNumber numberWithInteger:size]
        ]];
        NSMutableArray *listArray = [[NSMutableArray alloc] init];
        while ([result next]) {
            ChatMessage *msg = [[ChatMessage alloc] initWithResult:result];
            [listArray addObject:msg];
        }
        [result close];
        
        //使用ReverseObjectEnumerator
        NSArray *formerArray = [[listArray reverseObjectEnumerator] allObjects];
        NSMutableArray *reversedArray = [NSMutableArray arrayWithArray:formerArray];
        
        return reversedArray;
    } defaultValue: [[NSMutableArray alloc] init]];
}

//搜索文本消息
-(NSMutableArray *)searchTextMessage:(NSString*)text
                        andSessionId:(NSString*)sessionId
                        andMessageId:(NSString*)messageId
                             andSize:(NSInteger)size{
    
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        
        //请求字符串与参数
        NSString* queryStr = [NSString stringWithFormat:@"select * from message where 1=1 "];
        NSMutableArray* qureyParam = [[NSMutableArray alloc] init];
        
        //有文本输入
        if(sessionId!=nil&&sessionId.length!=0){
            ChatSessionMember* sessionMember = [self getSessionMember:sessionId andMemberId:user.userId];
            queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageSessionId=? "];
            queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageSessionOffset > ? "];
            [qureyParam addObject: sessionId];
            [qureyParam addObject: [NSNumber numberWithInteger:sessionMember!=nil ? sessionMember.sessionMemberLatestDelete : 0]];
        }
        
        
        //查询文本
        if(text!=nil&&text.length!=0){
            queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageContent like ? "];
            [qureyParam addObject: [NSString stringWithFormat:@"%%%@%%",text]];
        }
        
        //查询文本
        if(messageId!=nil&&messageId.length!=0){
            ChatMessage *msg = [self getMessageById:messageId];
            queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and (messageTableOffset < ? or (messageTableOffset = ? and messageStamp < ?)) "];
            [qureyParam addObject: [NSNumber numberWithInteger:msg.messageTableOffset]];
            [qureyParam addObject: [NSNumber numberWithInteger:msg.messageTableOffset]];
            [qureyParam addObject: [NSNumber numberWithInteger:msg.messageStamp]];
        }
        
        //消息插入者
        queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageInsertUser = ? "];
        [qureyParam addObject: user.userExtendId];
        
        //消息类型
        queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageType = ? and isDelete != 1 "];
        [qureyParam addObject: @(MSG_TYPE_TEXT)];
        
        //执行搜索
        FMResultSet *result = [db executeQuery:queryStr withArgumentsInArray:qureyParam];
        NSMutableArray *listArray = [[NSMutableArray alloc] init];
        while ([result next]) {
            ChatMessage *msg = [[ChatMessage alloc] initWithResult:result];
            [listArray addObject:msg];
        }
        [result close];
        
        return listArray;
    } defaultValue: [[NSMutableArray alloc] init]];
    
}


//搜索图片消息
-(NSMutableArray *)searchImageMessage:(NSString*)sessionId
                         andMessageId:(NSString*)messageId
                              andSize:(NSInteger)size{
    
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        
        //请求字符串与参数
        NSString* queryStr = [NSString stringWithFormat:@"select * from message where 1=1 "];
        NSMutableArray* qureyParam = [[NSMutableArray alloc] init];
        
        //有文本输入
        if(sessionId!=nil&&sessionId.length!=0){
            ChatSessionMember* sessionMember = [self getSessionMember:sessionId andMemberId:user.userId];
            queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageSessionId=? "];
            queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageSessionOffset > ? "];
            [qureyParam addObject: sessionId];
            [qureyParam addObject: [NSNumber numberWithInteger:sessionMember!=nil ? sessionMember.sessionMemberLatestDelete : 0]];
        }
        
        //查询文本
        if(messageId!=nil&&messageId.length!=0){
            ChatMessage *msg = [self getMessageById:messageId];
            queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and (messageTableOffset < ? or (messageTableOffset = ? and messageStamp < ?)) "];
            [qureyParam addObject: [NSNumber numberWithInteger:msg.messageTableOffset]];
            [qureyParam addObject: [NSNumber numberWithInteger:msg.messageTableOffset]];
            [qureyParam addObject: [NSNumber numberWithInteger:msg.messageStamp]];
        }
        
        //消息插入者
        queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageInsertUser = ? "];
        [qureyParam addObject: user.userExtendId];
        
        //消息类型
        queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageType = ? and isDelete != 1 "];
        [qureyParam addObject: @(MSG_TYPE_IMG)];
        
        //执行搜索
        FMResultSet *result = [db executeQuery:queryStr withArgumentsInArray:qureyParam];
        NSMutableArray *listArray = [[NSMutableArray alloc] init];
        while ([result next]) {
            ChatMessage *msg = [[ChatMessage alloc] initWithResult:result];
            [listArray addObject:msg];
        }
        [result close];
        
        return listArray;
    } defaultValue: [[NSMutableArray alloc] init]];
    
}



//搜索图片消息
-(NSMutableArray *)searchVideoMessage:(NSString*)sessionId
                         andMessageId:(NSString*)messageId
                              andSize:(NSInteger)size{
    
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        
        //请求字符串与参数
        NSString* queryStr = [NSString stringWithFormat:@"select * from message where 1=1 "];
        NSMutableArray* qureyParam = [[NSMutableArray alloc] init];
        
        //有文本输入
        if(sessionId!=nil&&sessionId.length!=0){
            ChatSessionMember* sessionMember = [self getSessionMember:sessionId andMemberId:user.userId];
            queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageSessionId=? "];
            queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageSessionOffset > ? "];
            [qureyParam addObject: sessionId];
            [qureyParam addObject: [NSNumber numberWithInteger:sessionMember!=nil ? sessionMember.sessionMemberLatestDelete : 0]];
        }
        
        //查询文本
        if(messageId!=nil&&messageId.length!=0){
            ChatMessage *msg = [self getMessageById:messageId];
            queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and (messageTableOffset < ? or (messageTableOffset = ? and messageStamp < ?)) "];
            [qureyParam addObject: [NSNumber numberWithInteger:msg.messageTableOffset]];
            [qureyParam addObject: [NSNumber numberWithInteger:msg.messageTableOffset]];
            [qureyParam addObject: [NSNumber numberWithInteger:msg.messageStamp]];
        }
        
        //消息插入者
        queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageInsertUser = ? "];
        [qureyParam addObject: user.userExtendId];
        
        //消息类型
        queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageType = ? and isDelete != 1 "];
        [qureyParam addObject: @(MSG_TYPE_VIDEO)];
        
        //执行搜索
        FMResultSet *result = [db executeQuery:queryStr withArgumentsInArray:qureyParam];
        NSMutableArray *listArray = [[NSMutableArray alloc] init];
        while ([result next]) {
            ChatMessage *msg = [[ChatMessage alloc] initWithResult:result];
            [listArray addObject:msg];
        }
        [result close];
        
        return listArray;
    } defaultValue: [[NSMutableArray alloc] init]];
    
}


//搜索图片消息
-(NSMutableArray *)searchVoiceMessage:(NSString*)sessionId
                         andMessageId:(NSString*)messageId
                              andSize:(NSInteger)size{
    
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        
        //请求字符串与参数
        NSString* queryStr = [NSString stringWithFormat:@"select * from message where 1=1 "];
        NSMutableArray* qureyParam = [[NSMutableArray alloc] init];
        
        //有文本输入
        if(sessionId!=nil&&sessionId.length!=0){
            ChatSessionMember* sessionMember = [self getSessionMember:sessionId andMemberId:user.userId];
            queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageSessionId=? "];
            queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageSessionOffset > ? "];
            [qureyParam addObject: sessionId];
            [qureyParam addObject: [NSNumber numberWithInteger:sessionMember!=nil ? sessionMember.sessionMemberLatestDelete : 0]];
        }
        
        //查询文本
        if(messageId!=nil&&messageId.length!=0){
            ChatMessage *msg = [self getMessageById:messageId];
            queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and (messageTableOffset < ? or (messageTableOffset = ? and messageStamp < ?)) "];
            [qureyParam addObject: [NSNumber numberWithInteger:msg.messageTableOffset]];
            [qureyParam addObject: [NSNumber numberWithInteger:msg.messageTableOffset]];
            [qureyParam addObject: [NSNumber numberWithInteger:msg.messageStamp]];
        }
        
        //消息插入者
        queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageInsertUser = ? "];
        [qureyParam addObject: user.userExtendId];
        
        //消息类型
        queryStr = [NSString stringWithFormat:@"%@%@",queryStr,@"and messageType = ? and isDelete != 1 "];
        [qureyParam addObject: @(MSG_TYPE_VOICE)];
        
        //执行搜索
        FMResultSet *result = [db executeQuery:queryStr withArgumentsInArray:qureyParam];
        NSMutableArray *listArray = [[NSMutableArray alloc] init];
        while ([result next]) {
            ChatMessage *msg = [[ChatMessage alloc] initWithResult:result];
            [listArray addObject:msg];
        }
        [result close];
        
        return listArray;
    } defaultValue: [[NSMutableArray alloc] init]];
    
}



//获取没有处理的系统消息
-(NSMutableArray *)getNotActionSystemMessageBySessionId:(NSString *)sessionID {
    return [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        FMResultSet *result = [db executeQuery:@"select * from message where messageType=0 and messageReadState=0 and messageSessionId=? and messageInsertUser=? order by messageTableOffset desc"
                          withArgumentsInArray:@[sessionID, user.userExtendId]];
        NSMutableArray *retArray = [[NSMutableArray alloc] init];
        while ([result next]) {
            ChatMessage *msg = [[ChatMessage alloc] initWithResult:result];
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
            ChatMessage *msg = [[ChatMessage alloc] initWithResult:result];
            [retArray addObject:msg];
        }
        [result close];
        return retArray;
    } defaultValue: [[NSMutableArray alloc] init]];
}

//处理消息阅读回执
-(void)handleMessageReadReceipt:(ChatMessage *)msg {
    [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        if (msg.messageType != MSG_TYPE_READ_RECEIPT) {
            return nil;
        }
        ChatReadReceipt *receipt = [msg getReadReceipt];
        NSString *sessionId = receipt.sessionId;
        NSString *userId = receipt.userId;
        NSString *tableOffset = receipt.readOffset;
        [self updateMessageRead:userId andSessionId:sessionId andTableSeq:tableOffset];
        [self updateSessionMemberLatestRead:userId andSessionId:sessionId andTableSeq:tableOffset];
        [self updateMessageReadByMsgId:msg.messageId];
        return nil;
    }];
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
        [db executeUpdate:@"UPDATE message SET messageReadState = 1, messageReadUserIds = IFNULL(messageReadUserIds, '') || CASE WHEN messageReadUserIds IS NULL OR messageReadUserIds = '' THEN '' ELSE ',' END || ? WHERE messageInsertUser = ? AND messageSendId != ? AND messageSessionId = ? AND messageTableOffset <= ? AND messageType NOT IN (?, ?, ?) AND (messageReadUserIds IS NULL OR messageReadUserIds NOT LIKE ?)"
     withArgumentsInArray:@[
            userId, // 要追加的 userId
            user.userExtendId,
            userId,
            sessionId,
            tableOffset,
            @(MSG_TYPE_SYSTEM),
            @(MSG_TYPE_ACTION),
            @(MSG_TYPE_READ_RECEIPT),
            //NOT LIKE 条件，避免重复
            [NSString stringWithFormat:@"%%%@%%", userId]
        ]];
        return nil;
    }];
}

//更新消息已读
-(void)updateMessageReadByMsgId:(NSString *)messageId{
    [self executeDbOperation:^id(FMDatabase *db, ChatUser *user) {
        [db executeUpdate:@"update message set messageReadState=1 where messageInsertUser=? and messageId=?"
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


@end
