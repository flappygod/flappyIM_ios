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
    //4.数据库中创建表（可创建多张）
    NSString *sql = @"create table if not exists message (messageId TEXT,messageSession TEXT,messageSessionType INTEGER,messageSessionOffset INTEGER,messageTableSeq INTEGER,messageType INTEGER ,messageSendId TEXT,messageSendExtendId TEXT,messageReceiveId TEXT,messageReceiveExtendId TEXT,messageContent TEXT,messageSendState INTEGER,messageReadState INTEGER,isDelete INTEGER,messageDate TEXT,messageStamp INTEGER,deleteDate TEXT,messageInsertUser TEXT,primary key (messageId,messageInsertUser))";
    
    NSString *sqlTwo=@"create table if not exists session (sessionId TEXT,sessionExtendId TEXT,sessionType INTEGER,sessionInfo TEXT,sessionName TEXT,sessionImage TEXT,sessionOffset TEXT,sessionStamp INTEGER,sessionCreateDate TEXT,sessionCreateUser TEXT,sessionDeleted INTEGER,sessionDeletedDate TEXT,users TEXT,sessionInsertUser TEXT,primary key (sessionId,sessionInsertUser))";
    
    //5.执行更新操作 此处database直接操作，不考虑多线程问题，多线程问题，用FMDatabaseQueue 每次数据库操作之后都会返回bool数值，YES，表示success，NO，表示fail,可以通过 @see lastError @see lastErrorCode @see lastErrorMessage
    BOOL result = [database executeUpdate:sql];
    //两个语句
    BOOL resultTwo = [database executeUpdate:sqlTwo];
    if (result&&resultTwo) {
        NSLog(@"create table success");
    }
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
            [db open];
            if (![db open]) {
                NSLog(@"db open fail");
            }
            database = db;
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
    [database executeUpdate:@"update message set messageSendState = 9 where messageSendState = 0"];
    [self closeDB];
}

//插入多条会话，如果存在就更新
-(Boolean)insertSessions:(NSMutableArray*)array{
    
    //没有的情况下就是成功
    if(array==nil||array.count==0){
        return true;
    }
    
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return false;
    }
    
    //打开数据库
    [self openDB];
    
    //查询浙西数组是否存在
    NSMutableArray* contains=[[NSMutableArray alloc] init];
    //遍历
    for(int s=0;s<array.count;s++){
        //会话数据
        SessionData* data=[array objectAtIndex:s];
        //查询当前用户是否已经存在这个会话
        FMResultSet *formers = [database executeQuery:@"select * from session where sessionInsertUser = ? and sessionId=?"
                                 withArgumentsInArray:@[user.userExtendId,data.sessionId]];
        //如果存在
        if([formers next]){
            //存在
            [contains addObject:[NSNumber numberWithInteger:1]];
        }else{
            //不存在
            [contains addObject:[NSNumber numberWithInteger:0]];
        }
        [formers close];
    }
    //开启事务
    [database beginTransaction];
    //是否成功
    Boolean totalSuccess=true;
    //遍历
    for(int s=0;s<array.count;s++){
        
        //会话数据
        SessionData* data=[array objectAtIndex:s];
        //是否包含
        NSNumber* nuber=[contains objectAtIndex:s];
        //包含更新
        if(nuber.intValue==1){
            NSMutableArray<ChatUser*>* usersData=data.users;
            NSMutableArray<NSDictionary*>* usersDataDic=[[NSMutableArray alloc]init];
            for(int s=0;s<usersData.count;s++){
                [usersDataDic addObject:[[usersData objectAtIndex:s] mj_keyValues]];
            }
            //存在就更新数据
            BOOL result = [database executeUpdate:@"update session set sessionId=?,sessionExtendId=?,sessionType=?,sessionInfo=?,sessionName=?,sessionImage=?,sessionOffset=?,sessionStamp=?,sessionCreateDate=?,sessionCreateUser=?,sessionDeleted=?,sessionDeletedDate=?,users=? where sessionInsertUser = ? and sessionExtendId=?"
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
                [FlappyStringTool toUnNullStr:[FlappyJsonTool DicToJSONString:usersDataDic]],
                [FlappyStringTool toUnNullStr:user.userExtendId],
                data.sessionExtendId
                
            ]];
            
            //如果一条失败了，就回滚
            if(result==false){
                totalSuccess=false;
                break;
            }
        }else{
            NSMutableArray<ChatUser*>* usersData=data.users;
            NSMutableArray<NSDictionary*>* usersDataDic=[[NSMutableArray alloc]init];
            for(int s=0;s<usersData.count;s++){
                [usersDataDic addObject:[[usersData objectAtIndex:s] mj_keyValues]];
            }
            BOOL result = [database executeUpdate:@"insert into session(sessionId,sessionExtendId,sessionType,sessionInfo,sessionName,sessionImage,sessionOffset,sessionStamp,sessionCreateDate,sessionCreateUser,sessionDeleted,sessionDeletedDate,users,sessionInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
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
                [FlappyStringTool toUnNullStr:[FlappyJsonTool DicToJSONString:usersDataDic]],
                [FlappyStringTool toUnNullStr:user.userExtendId]
            ]];
            //如果一条失败了，就回滚
            if(result==false){
                totalSuccess=false;
                break;
            }
        }
    }
    //如果全部成功了
    if(totalSuccess){
        [database commit];
    }
    //失败了就回滚
    else{
        [database rollback];
    }
    [self closeDB];
    //是否成功
    if (totalSuccess) {
        return true;
    } else {
        return false;
    }
}

//插入单条会话,如果存在就更新
-(Boolean)insertSession:(SessionData*)data{
    
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return false;
    }
    
    //获取db
    [self openDB];
    
    //是否成功
    Boolean totalSuccess=true;
    //查询当前用户是否存在一条当前一样的会话
    FMResultSet *formers = [database executeQuery:@"select * from session where sessionInsertUser=? and sessionExtendId=?"
                             withArgumentsInArray:@[user.userExtendId,data.sessionExtendId]];
    //如果存在
    if([formers next]){
        //如果存在就更新
        [formers close];
        
        //User数据
        NSMutableArray<ChatUser*>* usersData=data.users;
        NSMutableArray<NSDictionary*>* usersDataDic=[[NSMutableArray alloc]init];
        for(int s=0;s<usersData.count;s++){
            [usersDataDic addObject:[[usersData objectAtIndex:s] mj_keyValues]];
        }
        //更新数据
        BOOL result = [database executeUpdate:@"update session set sessionId=?,sessionExtendId=?,sessionType=?,sessionInfo=?,sessionName=?,sessionImage=?,sessionOffset=?,sessionStamp=?,sessionCreateDate=?,sessionCreateUser=?,sessionDeleted=?,sessionDeletedDate=?,users=? where sessionInsertUser = ? and sessionExtendId=?"
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
            [FlappyStringTool toUnNullStr:[FlappyJsonTool DicToJSONString:usersDataDic]],
            [FlappyStringTool toUnNullStr:user.userExtendId],
            data.sessionExtendId
            
        ]];
        
        //如果一条失败了，就回滚
        if(!result){
            totalSuccess=false;
        }
    }else{
        //如果不存在就插入数据
        [formers close];
        //User数据
        NSMutableArray<ChatUser*>* usersData=data.users;
        NSMutableArray<NSDictionary*>* usersDataDic=[[NSMutableArray alloc]init];
        for(int s=0;s<usersData.count;s++){
            [usersDataDic addObject:[[usersData objectAtIndex:s] mj_keyValues]];
        }
        //插入数据
        BOOL result = [database executeUpdate:@"insert into session(sessionId,sessionExtendId,sessionType,sessionInfo,sessionName,sessionImage,sessionOffset,sessionStamp,sessionCreateDate,sessionCreateUser,sessionDeleted,sessionDeletedDate,users,sessionInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
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
            [FlappyStringTool toUnNullStr:[FlappyJsonTool DicToJSONString:usersDataDic]],
            [FlappyStringTool toUnNullStr:user.userExtendId]
            
        ]];
        
        //如果一条失败了，就回滚
        if(!result){
            totalSuccess=false;
        }
    }
    [self closeDB];
    if (totalSuccess) {
        return true;
    } else {
        return false;
    }
}

//获取未读消息的数量
-(int)getSessionUnReadMessageCount:(NSString*)sessionId{
    [self openDB];
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return 0;
    }
    FMResultSet *results = [database executeQuery:@"SELECT COUNT(*) FROM message  WHERE messageInsertUser = ? and messageSession = ? and messageSendId != ? and messageReadState = 0 and messageType != 0 and messageType != 8"
                             withArgumentsInArray:@[
        user.userExtendId,
        sessionId,
        user.userId,
    ]];
    [self closeDB];
    if ([results next]) {
        return [results intForColumnIndex:0];
    }
    return 0;
}


//获取用户的会话
-(SessionData*)getUserSessionByID:(NSString*)sessionId{
    //获取db
    [self openDB];
    
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return nil;
    }
    
    //会话
    FMResultSet *result = [database executeQuery:@"select * from session where sessionInsertUser = ? and sessionId=?"
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
        NSArray* array=[FlappyJsonTool JSONStringToDictionary:[result stringForColumn:@"users"]];
        NSMutableArray* usersArr=[[NSMutableArray alloc]init];
        for(int s=0;s<array.count;s++){
            ChatUser* session=[ChatUser mj_objectWithKeyValues:[array objectAtIndex:s]];
            [usersArr addObject:session];
        }
        msg.users=usersArr;
        msg.unReadMessageCount = [self getSessionUnReadMessageCount:msg.sessionId];
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
-(SessionData*)getUserSessionByExtendID:(NSString*)sessionExtendId{
    //获取db
    [self openDB];
    
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return nil;
    }
    
    
    FMResultSet *result = [database executeQuery:@"select * from session where sessionInsertUser = ? and sessionExtendId=?"
                            withArgumentsInArray:@[user.userExtendId,sessionExtendId]];
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
        //转换
        NSArray* array=[FlappyJsonTool JSONStringToDictionary:[result stringForColumn:@"users"]];
        NSMutableArray* usersArr=[[NSMutableArray alloc]init];
        for(int s=0;s<array.count;s++){
            ChatUser* session=[ChatUser mj_objectWithKeyValues:[array objectAtIndex:s]];
            [usersArr addObject:session];
        }
        msg.users=usersArr;
        msg.unReadMessageCount = [self getSessionUnReadMessageCount:msg.sessionId];
        [result close];
        [self closeDB];
        return msg;
    }
    
    [result close];
    [self closeDB];
    return nil;
}

//获取用户的会话
-(NSMutableArray*)getUserSessions:(NSString*)userExtendID{
    //获取db
    [self openDB];
    FMResultSet *result = [database executeQuery:@"select * from session where sessionInsertUser = ?"
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
        //转换
        NSArray* array=[FlappyJsonTool JSONStringToDictionary:[result stringForColumn:@"users"]];
        NSMutableArray* usersArr=[[NSMutableArray alloc]init];
        for(int s=0;s<array.count;s++){
            ChatUser* session=[ChatUser mj_objectWithKeyValues:[array objectAtIndex:s]];
            [usersArr addObject:session];
        }
        msg.users=usersArr;
        msg.unReadMessageCount = [self getSessionUnReadMessageCount:msg.sessionId];
        [retSessions addObject:msg];
    }
    [result close];
    [self closeDB];
    return retSessions;
}

//插入消息
-(void)insertMessage:(ChatMessage*)msg{
    //获取db
    [self openDB];
    
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return ;
    }
    
    //查询当前用户是否存在一条当前一样的会话
    FMResultSet *formers = [database executeQuery:@"select * from message where messageId = ? and messageInsertUser = ?"
                             withArgumentsInArray:@[msg.messageId,user.userExtendId]];
    
    if([formers next]){
        [formers close];
        [database executeUpdate:@"update message set messageSession=?,messageSessionType=?,messageSessionOffset=?,messageTableSeq=?,messageType=?,messageSendId=?,messageSendExtendId=?,messageReceiveId=?,messageReceiveExtendId=?,messageContent=?,messageSendState=?,messageReadState=?,messageDate=?,deleteDate=?,isDelete=? where messageId = ? and messageInsertUser = ?"
           withArgumentsInArray:@[
            [FlappyStringTool toUnNullStr:msg.messageSession],
            [NSNumber numberWithInteger:msg.messageSessionType],
            [NSNumber numberWithInteger:msg.messageSessionOffset],
            [NSNumber numberWithInteger:msg.messageTableSeq],
            [NSNumber numberWithInteger:msg.messageType],
            [FlappyStringTool toUnNullStr:msg.messageSendId],
            [FlappyStringTool toUnNullStr:msg.messageSendExtendId],
            [FlappyStringTool toUnNullStr:msg.messageReceiveId],
            [FlappyStringTool toUnNullStr:msg.messageReceiveExtendId],
            [FlappyStringTool toUnNullStr:msg.messageContent],
            [NSNumber numberWithInteger:msg.messageSendState],
            [NSNumber numberWithInteger:msg.messageReadState],
            [FlappyStringTool toUnNullStr:msg.messageDate],
            [FlappyStringTool toUnNullStr:msg.deleteDate],
            [NSNumber numberWithInteger:msg.isDelete],
            msg.messageId,
            user.userExtendId]];
        //关闭数据库
        [self closeDB];
        //检测actionMessage
        [self handleActionMessageUpdate:msg];
    }else{
        [formers close];
        [database executeUpdate:@"insert into message(messageId,messageSession,messageSessionType,messageSessionOffset,messageTableSeq,messageType,messageSendId,messageSendExtendId,messageReceiveId,messageReceiveExtendId,messageContent,messageSendState,messageReadState,messageDate,deleteDate,messageStamp,isDelete,messageInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
           withArgumentsInArray:@[
            //插入部分
            [FlappyStringTool toUnNullStr:msg.messageId],
            [FlappyStringTool toUnNullStr:msg.messageSession],
            [NSNumber numberWithInteger:msg.messageSessionType],
            [NSNumber numberWithInteger:msg.messageSessionOffset],
            [NSNumber numberWithInteger:msg.messageTableSeq],
            [NSNumber numberWithInteger:msg.messageType],
            [FlappyStringTool toUnNullStr:msg.messageSendId],
            [FlappyStringTool toUnNullStr:msg.messageSendExtendId],
            [FlappyStringTool toUnNullStr:msg.messageReceiveId],
            [FlappyStringTool toUnNullStr:msg.messageReceiveExtendId],
            [FlappyStringTool toUnNullStr:msg.messageContent],
            [NSNumber numberWithInteger:msg.messageSendState],
            [NSNumber numberWithInteger:msg.messageReadState],
            [FlappyStringTool toUnNullStr:msg.messageDate],
            [FlappyStringTool toUnNullStr:msg.deleteDate],
            [NSNumber numberWithInteger:(NSInteger)([NSDate date].timeIntervalSince1970*1000)],
            [NSNumber numberWithInteger:msg.isDelete],
            user.userExtendId
        ]];
        //关闭数据库
        [self closeDB];
        //收到actionMessage
        [self handleActionMessageInsert:msg];
    }
}

//处理动作消息插入
-(void)handleActionMessageInsert:(ChatMessage*)msg{
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return;
    }
    
    //不是动作类型不处理
    if(msg.messageType != MSG_TYPE_ACTION){
        return;
    }
    
    ChatAction* action =[msg getChatAction];
    switch(action.actionType){
            //更新消息已读
        case ACTION_TYPE_READ:{
            NSString* userId = action.actionIds[0];
            NSString* sessionId = action.actionIds[1];
            NSString* tableSequence = action.actionIds[2];
            //更新消息状态
            [self updateMessageRead:userId
                       andSessionId:sessionId
                        andTableSeq:tableSequence];
            //更新最近消息状态
            [self updateSessionMemberLatestRead:userId
                                   andSessionId:sessionId
                                    andTableSeq:tableSequence];
            break;
        }
            
            //更新消息删除
        case ACTION_TYPE_DELETE:{
            NSString* userId = action.actionIds[0];
            NSString* sessionId = action.actionIds[1];
            NSString* messageId = action.actionIds[2];
            //不是自己发送的消息，进行删除，如果是自己插入的话，需要等到消息发送成功之后在handleActionMessageUpdate中操作
            if([user.userId integerValue] != [userId integerValue]){
                [self updateMessageDelete:userId
                             andSessionId:sessionId
                             andMessageId:messageId];
                
            }
            
            break;
        }
    }
}



//处理动作消息插入
-(void)handleActionMessageUpdate:(ChatMessage*)msg{
    
    //不是动作类型不处理
    if(msg.messageType != MSG_TYPE_ACTION){
        return;
    }
    
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return;
    }
    ChatAction* action =[msg getChatAction];
    switch(action.actionType){
            //更新消息已读
        case ACTION_TYPE_READ:{
            NSString* userId = action.actionIds[0];
            NSString* sessionId = action.actionIds[1];
            NSString* tableSequence = action.actionIds[2];
            //更新消息状态
            [self updateMessageRead:userId
                       andSessionId:sessionId
                        andTableSeq:tableSequence];
            //更新最近消息状态
            [self updateSessionMemberLatestRead:userId
                                   andSessionId:sessionId
                                    andTableSeq:tableSequence];
            break;
        }
            
            //更新消息删除
        case ACTION_TYPE_DELETE:{
            NSString* userId = action.actionIds[0];
            NSString* sessionId = action.actionIds[1];
            NSString* messageId = action.actionIds[2];
            [self updateMessageDelete:userId
                         andSessionId:sessionId
                         andMessageId:messageId];
            break;
        }
    }
    
}

//更新消息已读
-(void)updateMessageRead:userId
            andSessionId:sessionId
             andTableSeq:tableSequence{
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return;
    }
    [self openDB];
    [database executeUpdate:@"update message set messageReadState=1 where messageInsertUser = ? and messageSendId != ? and messageSession = ? and messageTableSeq <= ?"
       withArgumentsInArray:@[
        user.userExtendId,
        userId,
        sessionId,
        tableSequence]];
    [self closeDB];
}

//更新消息已读
-(void)updateMessageDelete:userId
              andSessionId:sessionId
              andMessageId:messageId{
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return;
    }
    [self openDB];
    [database executeUpdate:@"update message set isDelete=1 where messageInsertUser = ? and messageSession = ? and messageId = ?"
       withArgumentsInArray:@[
        user.userExtendId,
        sessionId,
        messageId
    ]];
    [self closeDB];
}

//更新最近已读的消息
-(void)updateSessionMemberLatestRead:userId
                        andSessionId:sessionId
                         andTableSeq:tableSequence{
    //更新会话
    SessionData* data = [self getUserSessionByID:sessionId];
    NSMutableArray* userList=data.users;
    for(ChatUser* user in userList){
        if([user.userId integerValue]==[userId integerValue]){
            user.sessionMemberLatestRead=tableSequence;
        }
    }
    [self insertSession:data];
}

//插入消息列表
-(void)insertMessages:(NSMutableArray*)array{
    //如果为空
    if(array==nil||array.count==0){
        return ;
    }
    
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return ;
    }
    
    //获取db
    [self openDB];
    
    //消息
    NSMutableArray* contains=[[NSMutableArray alloc]init];
    
    //查询当前用户是否存在一条当前一样的会话
    for(int s=0;s<array.count;s++){
        ChatMessage* msg=[array objectAtIndex:s];
        FMResultSet *formers = [database executeQuery:@"select * from message where messageId = ? and messageInsertUser = ?"
                                 withArgumentsInArray:@[msg.messageId,user.userExtendId]];
        
        if([formers next]){
            [contains addObject:[NSNumber numberWithInteger:1]];
        }else{
            [contains addObject:[NSNumber numberWithInteger:0]];
        }
        [formers close];
    }
    
    
    //开始事务
    [database beginTransaction];
    //遍历
    for(int s=0;s<array.count;s++){
        ChatMessage* msg=[array objectAtIndex:s];
        //是否包含
        NSNumber* nuber=[contains objectAtIndex:s];
        //包含更新
        if(nuber.intValue==1){
            [database executeUpdate:@"update message set messageSession=?,messageSessionType=?,messageSessionOffset=?,messageTableSeq=?,messageType=?,messageSendId=?,messageSendExtendId=?,messageReceiveId=?,messageReceiveExtendId=?,messageContent=?,messageSendState=?,messageReadState=?,messageDate=?,deleteDate=?,isDelete=? where messageId = ? and messageInsertUser = ?"
               withArgumentsInArray:@[
                [FlappyStringTool toUnNullStr:msg.messageSession],
                [NSNumber numberWithInteger:msg.messageSessionType],
                [NSNumber numberWithInteger:msg.messageSessionOffset],
                [NSNumber numberWithInteger:msg.messageTableSeq],
                [NSNumber numberWithInteger:msg.messageType],
                [FlappyStringTool toUnNullStr:msg.messageSendId],
                [FlappyStringTool toUnNullStr:msg.messageSendExtendId],
                [FlappyStringTool toUnNullStr:msg.messageReceiveId],
                [FlappyStringTool toUnNullStr:msg.messageReceiveExtendId],
                [FlappyStringTool toUnNullStr:msg.messageContent],
                [NSNumber numberWithInteger:msg.messageSendState],
                [NSNumber numberWithInteger:msg.messageReadState],
                [FlappyStringTool toUnNullStr:msg.messageDate],
                [FlappyStringTool toUnNullStr:msg.deleteDate],
                [NSNumber numberWithInteger:msg.isDelete],
                msg.messageId,
                user.userExtendId]];
        }else{
            //不包含插入
            [database executeUpdate:@"insert into message(messageId,messageSession,messageSessionType,messageSessionOffset,messageTableSeq,messageType,messageSendId,messageSendExtendId,messageReceiveId,messageReceiveExtendId,messageContent,messageSendState,messageReadState,messageDate,deleteDate,messageStamp,isDelete) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
               withArgumentsInArray:@[
                //插入部分
                [FlappyStringTool toUnNullStr:msg.messageId],
                [FlappyStringTool toUnNullStr:msg.messageSession],
                [NSNumber numberWithInteger:msg.messageSessionType],
                [NSNumber numberWithInteger:msg.messageSessionOffset],
                [NSNumber numberWithInteger:msg.messageTableSeq],
                [NSNumber numberWithInteger:msg.messageType],
                [FlappyStringTool toUnNullStr:msg.messageSendId],
                [FlappyStringTool toUnNullStr:msg.messageSendExtendId],
                [FlappyStringTool toUnNullStr:msg.messageReceiveId],
                [FlappyStringTool toUnNullStr:msg.messageReceiveExtendId],
                [FlappyStringTool toUnNullStr:msg.messageContent],
                [NSNumber numberWithInteger:msg.messageSendState],
                [NSNumber numberWithInteger:msg.messageReadState],
                [FlappyStringTool toUnNullStr:msg.messageDate],
                [FlappyStringTool toUnNullStr:msg.deleteDate],
                [NSNumber numberWithInteger:(NSInteger)([NSDate date].timeIntervalSince1970*1000)],
                [NSNumber numberWithInteger:msg.isDelete]
            ]];
        }
    }
    //提交
    [database commit];
    [self closeDB];
}



//通过ID获取消息
-(ChatMessage*)getMessageByID:(NSString*)messageID{
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return nil;
    }
    
    //获取db
    [self openDB];
    FMResultSet *result = [database executeQuery:@"select * from message where messageId = ? and messageInsertUser = ?"
                            withArgumentsInArray:@[messageID,user.userExtendId]];
    //返回消息
    if ([result next]) {
        ChatMessage *msg = [ChatMessage new];
        msg.messageId = [result stringForColumn:@"messageId"];
        msg.messageSession = [result stringForColumn:@"messageSession"];
        msg.messageSessionType = [result intForColumn:@"messageSessionType"];
        msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
        msg.messageTableSeq = [result intForColumn:@"messageTableSeq"];
        msg.messageType = [result intForColumn:@"messageType"];
        msg.messageSendId = [result stringForColumn:@"messageSendId"];
        msg.messageSendExtendId = [result stringForColumn:@"messageSendExtendId"];
        msg.messageReceiveId = [result stringForColumn:@"messageReceiveId"];
        msg.messageReceiveExtendId = [result stringForColumn:@"messageReceiveExtendId"];
        msg.messageContent = [result stringForColumn:@"messageContent"];
        msg.messageSendState = [result intForColumn:@"messageSendState"];
        msg.messageReadState = [result intForColumn:@"messageReadState"];
        msg.messageDate = [result stringForColumn:@"messageDate"];
        msg.isDelete = [result intForColumn:@"isDelete"];
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
    BOOL result = [database executeUpdate:@"update message set messageSession=?,messageSessionType=?,messageSessionOffset=?,messageTableSeq=?,messageType=?,messageSendId=?,messageSendExtendId=?,messageReceiveId=?,messageReceiveExtendId=?,messageContent=?,messageSendState=?,messageReadState=?,messageDate=?,deleteDate=?,isDelete=? where messageId = ? and messageInsertUser = ?"
                     withArgumentsInArray:@[
        [FlappyStringTool toUnNullStr:msg.messageSession],
        [NSNumber numberWithInteger:msg.messageSessionType],
        [NSNumber numberWithInteger:msg.messageSessionOffset],
        [NSNumber numberWithInteger:msg.messageTableSeq],
        [NSNumber numberWithInteger:msg.messageType],
        [FlappyStringTool toUnNullStr:msg.messageSendId],
        [FlappyStringTool toUnNullStr:msg.messageSendExtendId],
        [FlappyStringTool toUnNullStr:msg.messageReceiveId],
        [FlappyStringTool toUnNullStr:msg.messageReceiveExtendId],
        [FlappyStringTool toUnNullStr:msg.messageContent],
        [NSNumber numberWithInteger:msg.messageSendState],
        [NSNumber numberWithInteger:msg.messageReadState],
        [FlappyStringTool toUnNullStr:msg.messageDate],
        [FlappyStringTool toUnNullStr:msg.deleteDate],
        [NSNumber numberWithInteger:msg.isDelete],
        msg.messageId,
        user.userExtendId]];
    [self closeDB];
    if (result) {
        return true;
    } else {
        return false;
    }
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
    FMResultSet *result = [database executeQuery:@"select * from message where messageSession = ? and messageInsertUser = ? order by messageTableSeq desc,messageStamp desc limit 1"
                            withArgumentsInArray:@[sessionID,user.userExtendId]];
    if ([result next]) {
        ChatMessage *msg = [ChatMessage new];
        msg.messageId = [result stringForColumn:@"messageId"];
        msg.messageSession = [result stringForColumn:@"messageSession"];
        msg.messageSessionType = [result intForColumn:@"messageSessionType"];
        msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
        msg.messageTableSeq = [result intForColumn:@"messageTableSeq"];
        msg.messageType = [result intForColumn:@"messageType"];
        msg.messageSendId = [result stringForColumn:@"messageSendId"];
        msg.messageSendExtendId = [result stringForColumn:@"messageSendExtendId"];
        msg.messageReceiveId = [result stringForColumn:@"messageReceiveId"];
        msg.messageReceiveExtendId = [result stringForColumn:@"messageReceiveExtendId"];
        msg.messageContent = [result stringForColumn:@"messageContent"];
        msg.messageSendState = [result intForColumn:@"messageSendState"];
        msg.messageReadState = [result intForColumn:@"messageReadState"];
        msg.messageDate = [result stringForColumn:@"messageDate"];
        msg.isDelete = [result intForColumn:@"isDelete"];
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
-(NSMutableArray*)getSessionSequeceMessage:(NSString*)sessionID
                                withOffset:(NSString*)tabSequece{
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return [[NSMutableArray alloc]init];
    }
    //获取db
    [self openDB];
    
    //获取消息
    FMResultSet *result = [database executeQuery:@"select * from message where messageSession = ? and messageTableSeq=? and messageInsertUser = ? order by messageStamp  desc"
                            withArgumentsInArray:@[sessionID,tabSequece,user.userExtendId]];
    NSMutableArray* retArray=[[NSMutableArray alloc]init];
    while ([result next]) {
        ChatMessage *msg = [ChatMessage new];
        msg.messageId = [result stringForColumn:@"messageId"];
        msg.messageSession = [result stringForColumn:@"messageSession"];
        msg.messageSessionType = [result intForColumn:@"messageSessionType"];
        msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
        msg.messageTableSeq = [result intForColumn:@"messageTableSeq"];
        msg.messageType = [result intForColumn:@"messageType"];
        msg.messageSendId = [result stringForColumn:@"messageSendId"];
        msg.messageSendExtendId = [result stringForColumn:@"messageSendExtendId"];
        msg.messageReceiveId = [result stringForColumn:@"messageReceiveId"];
        msg.messageReceiveExtendId = [result stringForColumn:@"messageReceiveExtendId"];
        msg.messageContent = [result stringForColumn:@"messageContent"];
        msg.messageSendState = [result intForColumn:@"messageSendState"];
        msg.messageReadState = [result intForColumn:@"messageReadState"];
        msg.messageDate = [result stringForColumn:@"messageDate"];
        msg.isDelete = [result intForColumn:@"isDelete"];
        msg.messageStamp = [result longForColumn:@"messageStamp"];
        msg.deleteDate = [result stringForColumn:@"deleteDate"];
        [retArray addObject:msg];
    }
    [result close];
    [self closeDB];
    return retArray;
}

//获取没有处理的系统消息
-(NSMutableArray*)getNotActionSystemMessageWithSession:(NSString*)sessionID{
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return [[NSMutableArray alloc]init];
    }
    
    //获取db
    [self openDB];
    
    //获取列表
    FMResultSet *result = [database executeQuery:@"select * from message where messageReadState = 0 and messageType=0 and messageSession=? and messageInsertUser = ? order by messageTableSeq  desc"
                            withArgumentsInArray:@[sessionID,user.userExtendId]];
    NSMutableArray* retArray=[[NSMutableArray alloc]init];
    while ([result next]) {
        ChatMessage *msg = [ChatMessage new];
        msg.messageId = [result stringForColumn:@"messageId"];
        msg.messageSession = [result stringForColumn:@"messageSession"];
        msg.messageSessionType = [result intForColumn:@"messageSessionType"];
        msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
        msg.messageTableSeq = [result intForColumn:@"messageTableSeq"];
        msg.messageType = [result intForColumn:@"messageType"];
        msg.messageSendId = [result stringForColumn:@"messageSendId"];
        msg.messageSendExtendId = [result stringForColumn:@"messageSendExtendId"];
        msg.messageReceiveId = [result stringForColumn:@"messageReceiveId"];
        msg.messageReceiveExtendId = [result stringForColumn:@"messageReceiveExtendId"];
        msg.messageContent = [result stringForColumn:@"messageContent"];
        msg.messageSendState = [result intForColumn:@"messageSendState"];
        msg.messageReadState = [result intForColumn:@"messageReadState"];
        msg.messageDate = [result stringForColumn:@"messageDate"];
        msg.isDelete = [result intForColumn:@"isDelete"];
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
    
    //获取db
    [self openDB];
    
    //获取消息
    FMResultSet *result = [database executeQuery:@"select * from message where messageReadState = 0 and messageType=0 and messageInsertUser = ? order by messageTableSeq  desc"
                            withArgumentsInArray:@[user.userExtendId]];
    NSMutableArray* retArray=[[NSMutableArray alloc]init];
    while ([result next]) {
        ChatMessage *msg = [ChatMessage new];
        msg.messageId = [result stringForColumn:@"messageId"];
        msg.messageSession = [result stringForColumn:@"messageSession"];
        msg.messageSessionType = [result intForColumn:@"messageSessionType"];
        msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
        msg.messageTableSeq = [result intForColumn:@"messageTableSeq"];
        msg.messageType = [result intForColumn:@"messageType"];
        msg.messageSendId = [result stringForColumn:@"messageSendId"];
        msg.messageSendExtendId = [result stringForColumn:@"messageSendExtendId"];
        msg.messageReceiveId = [result stringForColumn:@"messageReceiveId"];
        msg.messageReceiveExtendId = [result stringForColumn:@"messageReceiveExtendId"];
        msg.messageContent = [result stringForColumn:@"messageContent"];
        msg.messageSendState = [result intForColumn:@"messageSendState"];
        msg.messageReadState = [result intForColumn:@"messageReadState"];
        msg.messageDate = [result stringForColumn:@"messageDate"];
        msg.isDelete = [result intForColumn:@"isDelete"];
        msg.messageStamp = [result longForColumn:@"messageStamp"];
        msg.deleteDate = [result stringForColumn:@"deleteDate"];
        [retArray addObject:msg];
    }
    [result close];
    [self closeDB];
    return retArray;
}

//通过sessionID，获取之前的
-(NSMutableArray*)getSessionFormerMessage:(NSString*)sessionID
                            withMessageID:(NSString*)messageId
                                 withSize:(NSInteger)size{
    
    
    //获取当前的消息ID
    ChatMessage* msg=[self getMessageByID:messageId];
    
    //获取user
    ChatUser* user = [[FlappyData shareInstance] getUser];
    if(user==nil){
        return [[NSMutableArray alloc]init];
    }
    
    //获取db
    [self openDB];
    
    //当前的
    NSMutableArray* retArray=[[NSMutableArray alloc] init];
    NSMutableArray* sequeceArray=[self getSessionSequeceMessage:sessionID
                                                     withOffset:[NSString stringWithFormat:@"%ld",(long)msg.messageTableSeq]];
    
    for(int s=0;s<sequeceArray.count;s++){
        ChatMessage* mem=[sequeceArray objectAtIndex:s];
        if(mem.messageStamp<msg.messageStamp){
            [retArray addObject:mem];
        }
    }
    
    //获取消息
    FMResultSet *result = [database executeQuery:@"select * from message where messageSession = ? and messageTableSeq<? and messageInsertUser = ? order by messageTableSeq desc,messageStamp desc limit ?"
                            withArgumentsInArray:@[sessionID,[NSNumber numberWithInteger:msg.messageTableSeq],user.userExtendId,[NSNumber numberWithInteger:size]]];
    NSMutableArray* listArray=[[NSMutableArray alloc]init];
    while ([result next]) {
        ChatMessage *msg = [ChatMessage new];
        msg.messageId = [result stringForColumn:@"messageId"];
        msg.messageSession = [result stringForColumn:@"messageSession"];
        msg.messageSessionType = [result intForColumn:@"messageSessionType"];
        msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
        msg.messageTableSeq = [result intForColumn:@"messageTableSeq"];
        msg.messageType = [result intForColumn:@"messageType"];
        msg.messageSendId = [result stringForColumn:@"messageSendId"];
        msg.messageSendExtendId = [result stringForColumn:@"messageSendExtendId"];
        msg.messageReceiveId = [result stringForColumn:@"messageReceiveId"];
        msg.messageReceiveExtendId = [result stringForColumn:@"messageReceiveExtendId"];
        msg.messageContent = [result stringForColumn:@"messageContent"];
        msg.messageSendState = [result intForColumn:@"messageSendState"];
        msg.messageReadState = [result intForColumn:@"messageReadState"];
        msg.messageDate = [result stringForColumn:@"messageDate"];
        msg.messageStamp = [result longForColumn:@"messageStamp"];
        msg.isDelete = [result intForColumn:@"isDelete"];
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
    if(retArray.count>size){
        NSMutableArray* newArray=[[NSMutableArray alloc]init];
        for(int s=0;s<size;s++){
            [newArray addObject: [retArray objectAtIndex:s]];
        }
        retArray=newArray;
    }
    return retArray;
}



@end
