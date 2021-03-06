//
//  DataBase.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import "FlappyDataBase.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "SessionData.h"
#import "FlappyStringTool.h"
#import "FlappyJsonTool.h"
#import "FlappyData.h"
#import "MJExtension.h"

@implementation FlappyDataBase

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
    FMDatabase* db=[self openDB];
    if(db==nil){
        return;
    }
    //4.数据库中创建表（可创建多张）
    NSString *sql = @"create table if not exists message (messageId TEXT PRIMARY KEY,messageSession TEXT,messageSessionType INTEGER,messageSessionOffset INTEGER,messageTableSeq INTEGER,messageType INTEGER ,messageSend TEXT,messageSendExtendid TEXT,messageRecieve TEXT,messageRecieveExtendid TEXT,messageContent TEXT,messageSended INTEGER,messageReaded INTEGER,messageDate TEXT,messageDeletedDate TEXT,messageStamp INTEGER,messageDeleted INTEGER)";
    
    NSString *sqlTwo=@"create table if not exists session (sessionId TEXT,sessionExtendId TEXT,sessionType INTEGER,sessionName TEXT,sessionImage TEXT,sessionOffset TEXT,sessionStamp INTEGER,sessionCreateDate TEXT,sessionCreateUser TEXT,sessionDeleted INTEGER,sessionDeletedDate TEXT,users TEXT,sessionInsertUser TEXT,primary key (sessionId,sessionInsertUser))";
    
    //5.执行更新操作 此处database直接操作，不考虑多线程问题，多线程问题，用FMDatabaseQueue 每次数据库操作之后都会返回bool数值，YES，表示success，NO，表示fail,可以通过 @see lastError @see lastErrorCode @see lastErrorMessage
    BOOL result = [db executeUpdate:sql];
    //两个语句
    BOOL resultTwo = [db executeUpdate:sqlTwo];
    if (result&&resultTwo) {
        NSLog(@"create table success");
    }
    [db close];
}

//获取db
-(FMDatabase*)openDB{
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
        return nil;
    }
    return db;
}


//插入多条会话，如果存在就更新
-(Boolean)insertSessions:(NSMutableArray*)array{
    //没有的情况下就是成功
    if(array==nil||array.count==0){
        return true;
    }
    
    //为了保证线程安全,因为我们需要及时返还，又不能使用FMDatabaseQueue，只能加锁
    @synchronized (self) {
        //打开数据库
        FMDatabase* db=[self openDB];
        if(db==nil){
            return false;
        }
        //查询浙西数组是否存在
        NSMutableArray* contains=[[NSMutableArray alloc] init];
        //遍历
        for(int s=0;s<array.count;s++){
            //会话数据
            SessionData* data=[array objectAtIndex:s];
            //查询当前用户是否已经存在这个会话
            FMResultSet *formers = [db executeQuery:@"select * from session where sessionInsertUser = ? and sessionExtendId=?"
                               withArgumentsInArray:@[[FlappyData shareInstance].getUser.userExtendId,data.sessionExtendId]];
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
        [db beginTransaction];
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
                //存在就更新数据
                BOOL result = [db executeUpdate:@"update session set sessionId=?,sessionExtendId=?,sessionType=?,sessionName=?,sessionImage=?,sessionOffset=?,sessionStamp=?,sessionCreateDate=?,sessionCreateUser=?,sessionDeleted=?,sessionDeletedDate=?,users=? where sessionInsertUser = ? and sessionExtendId=?"
                           withArgumentsInArray:@[
                                                  
                                                  [FlappyStringTool toUnNullStr:data.sessionId],
                                                  [FlappyStringTool toUnNullStr:data.sessionExtendId],
                                                  [NSNumber numberWithInteger:data.sessionType],
                                                  [FlappyStringTool toUnNullStr:data.sessionName],
                                                  [FlappyStringTool toUnNullStr:data.sessionImage],
                                                  [FlappyStringTool toUnNullStr:data.sessionOffset],
                                                  [NSNumber numberWithInteger:data.sessionStamp],
                                                  [FlappyStringTool toUnNullStr:data.sessionCreateDate],
                                                  [FlappyStringTool toUnNullStr:data.sessionCreateUser],
                                                  [NSNumber numberWithInteger:data.sessionDeleted],
                                                  [FlappyStringTool toUnNullStr:data.sessionDeletedDate],
                                                  [FlappyStringTool toUnNullStr:[FlappyJsonTool DicToJSONString:data.users]],
                                                  
                                                  [FlappyStringTool toUnNullStr:[FlappyData shareInstance].getUser.userExtendId],
                                                  data.sessionExtendId
                                                  
                                                  ]];
                
                //如果一条失败了，就回滚
                if(result==false){
                    totalSuccess=false;
                    break;
                }
            }else{
                BOOL result = [db executeUpdate:@"insert into session(sessionId,sessionExtendId,sessionType,sessionName,sessionImage,sessionOffset,sessionStamp,sessionCreateDate,sessionCreateUser,sessionDeleted,sessionDeletedDate,users,sessionInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?)"
                           withArgumentsInArray:@[
                                                  
                                                  [FlappyStringTool toUnNullStr:data.sessionId],
                                                  [FlappyStringTool toUnNullStr:data.sessionExtendId],
                                                  [NSNumber numberWithInteger:data.sessionType],
                                                  [FlappyStringTool toUnNullStr:data.sessionName],
                                                  [FlappyStringTool toUnNullStr:data.sessionImage],
                                                  [FlappyStringTool toUnNullStr:data.sessionOffset],
                                                  [NSNumber numberWithInteger:data.sessionStamp],
                                                  [FlappyStringTool toUnNullStr:data.sessionCreateDate],
                                                  [FlappyStringTool toUnNullStr:data.sessionCreateUser],
                                                  [NSNumber numberWithInteger:data.sessionDeleted],
                                                  [FlappyStringTool toUnNullStr:data.sessionDeletedDate],
                                                  [FlappyStringTool toUnNullStr:[FlappyJsonTool DicToJSONString:data.users]],
                                                  [FlappyStringTool toUnNullStr:[FlappyData shareInstance].getUser.userExtendId]
                                                  
                                                  ]];
                
                //如果一条失败了，就回滚
                if(result==false){
                    totalSuccess=false;
                    break;
                }
            }
        }
        if(totalSuccess){
            //如果全部成功了
            [db commit];
        }
        else{
            //失败了就回滚
            [db rollback];
        }
        [db close];
        //是否成功
        if (totalSuccess) {
            return true;
        } else {
            return false;
        }
    }
}

//插入单条会话,如果存在就更新
-(Boolean)insertSession:(SessionData*)data{
    
    @synchronized (self) {
        //获取db
        FMDatabase* db=[self openDB];
        if(db==nil){
            return false;
        }
        //是否成功
        Boolean totalSuccess=true;
        //查询当前用户是否存在一条当前一样的会话
        FMResultSet *formers = [db executeQuery:@"select * from session where sessionInsertUser = ? and sessionExtendId=?"
                           withArgumentsInArray:@[[FlappyData shareInstance].getUser.userExtendId,data.sessionExtendId]];
        //如果存在
        if([formers next]){
            //如果存在就更新
            [formers close];
            //更新数据
            BOOL result = [db executeUpdate:@"update session set sessionId=?,sessionExtendId=?,sessionType=?,sessionName=?,sessionImage=?,sessionOffset=?,sessionStamp=?,sessionCreateDate=?,sessionCreateUser=?,sessionDeleted=?,sessionDeletedDate=?,users=? where sessionInsertUser = ? and sessionExtendId=?"
                       withArgumentsInArray:@[
                                              
                                              [FlappyStringTool toUnNullStr:data.sessionId],
                                              [FlappyStringTool toUnNullStr:data.sessionExtendId],
                                              [NSNumber numberWithInteger:data.sessionType],
                                              [FlappyStringTool toUnNullStr:data.sessionName],
                                              [FlappyStringTool toUnNullStr:data.sessionImage],
                                              [FlappyStringTool toUnNullStr:data.sessionOffset],
                                              [NSNumber numberWithInteger:data.sessionStamp],
                                              [FlappyStringTool toUnNullStr:data.sessionCreateDate],
                                              [FlappyStringTool toUnNullStr:data.sessionCreateUser],
                                              [NSNumber numberWithInteger:data.sessionDeleted],
                                              [FlappyStringTool toUnNullStr:data.sessionDeletedDate],
                                              [FlappyStringTool toUnNullStr:[FlappyJsonTool DicToJSONString:data.users]],
                                              
                                              [FlappyStringTool toUnNullStr:[FlappyData shareInstance].getUser.userExtendId],
                                              data.sessionExtendId
                                              
                                              ]];
            
            //如果一条失败了，就回滚
            if(!result){
                totalSuccess=false;
            }
        }else{
            //如果不存在就插入数据
            [formers close];
            //插入数据
            BOOL result = [db executeUpdate:@"insert into session(sessionId,sessionExtendId,sessionType,sessionName,sessionImage,sessionOffset,sessionStamp,sessionCreateDate,sessionCreateUser,sessionDeleted,sessionDeletedDate,users,sessionInsertUser) values(?,?,?,?,?,?,?,?,?,?,?,?,?)"
                       withArgumentsInArray:@[
                                              
                                              [FlappyStringTool toUnNullStr:data.sessionId],
                                              [FlappyStringTool toUnNullStr:data.sessionExtendId],
                                              [NSNumber numberWithInteger:data.sessionType],
                                              [FlappyStringTool toUnNullStr:data.sessionName],
                                              [FlappyStringTool toUnNullStr:data.sessionImage],
                                              [FlappyStringTool toUnNullStr:data.sessionOffset],
                                              [NSNumber numberWithInteger:data.sessionStamp],
                                              [FlappyStringTool toUnNullStr:data.sessionCreateDate],
                                              [FlappyStringTool toUnNullStr:data.sessionCreateUser],
                                              [NSNumber numberWithInteger:data.sessionDeleted],
                                              [FlappyStringTool toUnNullStr:data.sessionDeletedDate],
                                              [FlappyStringTool toUnNullStr:[FlappyJsonTool DicToJSONString:data.users]],
                                              [FlappyStringTool toUnNullStr:[FlappyData shareInstance].getUser.userExtendId]
                                              
                                              ]];
            
            //如果一条失败了，就回滚
            if(!result){
                totalSuccess=false;
            }
        }
        [db close];
        if (totalSuccess) {
            return true;
        } else {
            return false;
        }
    }
}

//获取用户的会话
-(SessionData*)getUserSessionByExtendID:(NSString*)sessionExtendId{
    @synchronized (self) {
        
        NSString* userExtendID=[FlappyData shareInstance].getUser.userExtendId;
        
        //获取db
        FMDatabase* db=[self openDB];
        if(db==nil){
            return nil;
        }
        FMResultSet *result = [db executeQuery:@"select * from session where sessionInsertUser = ? and sessionExtendId=?"
                          withArgumentsInArray:@[userExtendID,sessionExtendId]];
        //返回消息
        if ([result next]) {
            
            SessionData *msg = [SessionData new];
            msg.sessionId = [result stringForColumn:@"sessionId"];
            msg.sessionExtendId = [result stringForColumn:@"sessionExtendId"];
            msg.sessionType = [result intForColumn:@"sessionType"];
            msg.sessionName = [result stringForColumn:@"sessionName"];
            msg.sessionImage = [result stringForColumn:@"sessionImage"];
            msg.sessionOffset = [result stringForColumn:@"sessionOffset"];
            msg.sessionStamp = [result intForColumn:@"sessionStamp"];
            msg.sessionCreateDate = [result stringForColumn:@"sessionCreateDate"];
            msg.sessionCreateUser = [result stringForColumn:@"sessionCreateUser"];
            msg.sessionDeleted = [result intForColumn:@"sessionDeleted"];
            msg.sessionDeletedDate = [result stringForColumn:@"sessionDeletedDate"];
            //转换
            NSArray* array=[FlappyJsonTool JSONStringToDictionary:[result stringForColumn:@"users"]];
            NSMutableArray* usersArr=[[NSMutableArray alloc]init];
            for(int s=0;s<array.count;s++){
                SessionData* session=[SessionData mj_objectWithKeyValues:[array objectAtIndex:s]];
                [usersArr addObject:session];
            }
            msg.users=usersArr;
            
            [result close];
            [db close];
            return msg;
        }
        
        [result close];
        [db close];
        //没有拿到用户会话
        return nil;
    }
}

//获取用户的会话
-(NSMutableArray*)getUserSessions:(NSString*)userExtendID{
    @synchronized (self) {
        //获取db
        FMDatabase* db=[self openDB];
        if(db==nil){
            return nil;
        }
        FMResultSet *result = [db executeQuery:@"select * from session where sessionInsertUser = ?"
                          withArgumentsInArray:@[userExtendID]];
        
        NSMutableArray* retSessions=[[NSMutableArray alloc] init];
        
        //返回消息
        while ([result next]) {
            SessionData *msg = [SessionData new];
            msg.sessionId = [result stringForColumn:@"sessionId"];
            msg.sessionExtendId = [result stringForColumn:@"sessionExtendId"];
            msg.sessionType = [result intForColumn:@"sessionType"];
            msg.sessionName = [result stringForColumn:@"sessionName"];
            msg.sessionImage = [result stringForColumn:@"sessionImage"];
            msg.sessionOffset = [result stringForColumn:@"sessionOffset"];
            msg.sessionStamp = [result intForColumn:@"sessionStamp"];
            msg.sessionCreateDate = [result stringForColumn:@"sessionCreateDate"];
            msg.sessionCreateUser = [result stringForColumn:@"sessionCreateUser"];
            msg.sessionDeleted = [result intForColumn:@"sessionDeleted"];
            msg.sessionDeletedDate = [result stringForColumn:@"sessionDeletedDate"];
            //转换
            NSArray* array=[FlappyJsonTool JSONStringToDictionary:[result stringForColumn:@"users"]];
            NSMutableArray* usersArr=[[NSMutableArray alloc]init];
            for(int s=0;s<array.count;s++){
                SessionData* session=[SessionData mj_objectWithKeyValues:[array objectAtIndex:s]];
                [usersArr addObject:session];
            }
            msg.users=usersArr;
            //加入其中
            [retSessions addObject:msg];
        }
        
        [result close];
        
        [db close];
        return retSessions;
    }
}

//插入消息
-(Boolean)insertMsg:(ChatMessage*)msg{
    @synchronized (self) {
        //获取db
        FMDatabase* db=[self openDB];
        if(db==nil){
            return false;
        }
        
        //是否成功
        Boolean totalSuccess=true;
        
        //查询当前用户是否存在一条当前一样的会话
        FMResultSet *formers = [db executeQuery:@"select * from message where messageId = ?"
                           withArgumentsInArray:@[msg.messageId]];
        
        if([formers next]){
            
            [formers close];
            
            BOOL result = [db executeUpdate:@"update message set messageSession=?,messageSessionType=?,messageSessionOffset=?,messageTableSeq=?,messageType=?,messageSend=?,messageSendExtendid=?,messageRecieve=?,messageRecieveExtendid=?,messageContent=?,messageSended=?,messageReaded=?,messageDate=?,messageDeletedDate=?,messageDeleted=? where messageId = ?"
                       withArgumentsInArray:@[
                                              [FlappyStringTool toUnNullStr:msg.messageSession],
                                              [NSNumber numberWithInteger:msg.messageSessionType],
                                              [NSNumber numberWithInteger:msg.messageSessionOffset],
                                              [NSNumber numberWithInteger:msg.messageTableSeq],
                                              [NSNumber numberWithInteger:msg.messageType],
                                              [FlappyStringTool toUnNullStr:msg.messageSend],
                                              [FlappyStringTool toUnNullStr:msg.messageSendExtendid],
                                              [FlappyStringTool toUnNullStr:msg.messageRecieve],
                                              [FlappyStringTool toUnNullStr:msg.messageRecieveExtendid],
                                              [FlappyStringTool toUnNullStr:msg.messageContent],
                                              [NSNumber numberWithInteger:msg.messageSended],
                                              [NSNumber numberWithInteger:msg.messageReaded],
                                              [FlappyStringTool toUnNullStr:msg.messageDate],
                                              [FlappyStringTool toUnNullStr:msg.messageDeletedDate],
                                              [NSNumber numberWithInteger:msg.messageDeleted],
                                              msg.messageId]];
            if(!result){
                totalSuccess=false;
            }
        }else{
            
            [formers close];
            
            BOOL result = [db executeUpdate:@"insert into message(messageId,messageSession,messageSessionType,messageSessionOffset,messageTableSeq,messageType,messageSend,messageSendExtendid,messageRecieve,messageRecieveExtendid,messageContent,messageSended,messageReaded,messageDate,messageDeletedDate,messageStamp,messageDeleted) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
                       withArgumentsInArray:@[
                                              //插入部分
                                              [FlappyStringTool toUnNullStr:msg.messageId],
                                              [FlappyStringTool toUnNullStr:msg.messageSession],
                                              [NSNumber numberWithInteger:msg.messageSessionType],
                                              [NSNumber numberWithInteger:msg.messageSessionOffset],
                                              [NSNumber numberWithInteger:msg.messageTableSeq],
                                              [NSNumber numberWithInteger:msg.messageType],
                                              [FlappyStringTool toUnNullStr:msg.messageSend],
                                              [FlappyStringTool toUnNullStr:msg.messageSendExtendid],
                                              [FlappyStringTool toUnNullStr:msg.messageRecieve],
                                              [FlappyStringTool toUnNullStr:msg.messageRecieveExtendid],
                                              [FlappyStringTool toUnNullStr:msg.messageContent],
                                              [NSNumber numberWithInteger:msg.messageSended],
                                              [NSNumber numberWithInteger:msg.messageReaded],
                                              [FlappyStringTool toUnNullStr:msg.messageDate],
                                              [FlappyStringTool toUnNullStr:msg.messageDeletedDate],
                                              [NSNumber numberWithInteger:(NSInteger)([NSDate date].timeIntervalSince1970*1000)],
                                              [NSNumber numberWithInteger:msg.messageDeleted]
                                              
                                              ]];
            if(!result){
                totalSuccess=false;
            }
        }
        
        
        [db close];
        if (totalSuccess) {
            return true;
        } else {
            return false;
        }
    }
}

//插入消息列表
-(Boolean)insertMsgs:(NSMutableArray*)array{
    if(array==nil||array.count==0){
        return true;
    }
    @synchronized (self) {
        //获取db
        FMDatabase* db=[self openDB];
        if(db==nil){
            return false;
        }
        
        NSMutableArray* contains=[[NSMutableArray alloc]init];
        
        for(int s=0;s<array.count;s++){
            ChatMessage* msg=[array objectAtIndex:s];
            //查询当前用户是否存在一条当前一样的会话
            FMResultSet *formers = [db executeQuery:@"select * from message where messageId = ?"
                               withArgumentsInArray:@[msg.messageId]];
            
            if([formers next]){
                [contains addObject:[NSNumber numberWithInteger:1]];
            }else{
                [contains addObject:[NSNumber numberWithInteger:0]];
            }
            [formers close];
        }
        
        
        //开始事务
        [db beginTransaction];
        //是否成功
        Boolean totalSuccess=true;
        //遍历
        for(int s=0;s<array.count;s++){
            ChatMessage* msg=[array objectAtIndex:s];
            //是否包含
            NSNumber* nuber=[contains objectAtIndex:s];
            //包含更新
            if(nuber.intValue==1){
                
                BOOL result = [db executeUpdate:@"update message set messageSession=?,messageSessionType=?,messageSessionOffset=?,messageTableSeq=?,messageType=?,messageSend=?,messageSendExtendid=?,messageRecieve=?,messageRecieveExtendid=?,messageContent=?,messageSended=?,messageReaded=?,messageDate=?,messageDeletedDate=?,messageDeleted=? where messageId = ?"
                           withArgumentsInArray:@[
                                                  [FlappyStringTool toUnNullStr:msg.messageSession],
                                                  [NSNumber numberWithInteger:msg.messageSessionType],
                                                  [NSNumber numberWithInteger:msg.messageSessionOffset],
                                                  [NSNumber numberWithInteger:msg.messageTableSeq],
                                                  [NSNumber numberWithInteger:msg.messageType],
                                                  [FlappyStringTool toUnNullStr:msg.messageSend],
                                                  [FlappyStringTool toUnNullStr:msg.messageSendExtendid],
                                                  [FlappyStringTool toUnNullStr:msg.messageRecieve],
                                                  [FlappyStringTool toUnNullStr:msg.messageRecieveExtendid],
                                                  [FlappyStringTool toUnNullStr:msg.messageContent],
                                                  [NSNumber numberWithInteger:msg.messageSended],
                                                  [NSNumber numberWithInteger:msg.messageReaded],
                                                  [FlappyStringTool toUnNullStr:msg.messageDate],
                                                  [FlappyStringTool toUnNullStr:msg.messageDeletedDate],
                                                  [NSNumber numberWithInteger:msg.messageDeleted],
                                                  msg.messageId]];
                if(!result){
                    totalSuccess=false;
                }
            }else{
                //不包含插入
                BOOL result = [db executeUpdate:@"insert into message(messageId,messageSession,messageSessionType,messageSessionOffset,messageTableSeq,messageType,messageSend,messageSendExtendid,messageRecieve,messageRecieveExtendid,messageContent,messageSended,messageReaded,messageDate,messageDeletedDate,messageStamp,messageDeleted) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
                           withArgumentsInArray:@[
                                                  //插入部分
                                                  [FlappyStringTool toUnNullStr:msg.messageId],
                                                  [FlappyStringTool toUnNullStr:msg.messageSession],
                                                  [NSNumber numberWithInteger:msg.messageSessionType],
                                                  [NSNumber numberWithInteger:msg.messageSessionOffset],
                                                  [NSNumber numberWithInteger:msg.messageTableSeq],
                                                  [NSNumber numberWithInteger:msg.messageType],
                                                  [FlappyStringTool toUnNullStr:msg.messageSend],
                                                  [FlappyStringTool toUnNullStr:msg.messageSendExtendid],
                                                  [FlappyStringTool toUnNullStr:msg.messageRecieve],
                                                  [FlappyStringTool toUnNullStr:msg.messageRecieveExtendid],
                                                  [FlappyStringTool toUnNullStr:msg.messageContent],
                                                  [NSNumber numberWithInteger:msg.messageSended],
                                                  [NSNumber numberWithInteger:msg.messageReaded],
                                                  [FlappyStringTool toUnNullStr:msg.messageDate],
                                                  [FlappyStringTool toUnNullStr:msg.messageDeletedDate],
                                                  [NSNumber numberWithInteger:(NSInteger)([NSDate date].timeIntervalSince1970*1000)],
                                                  [NSNumber numberWithInteger:msg.messageDeleted]
                                                  
                                                  ]];
                if(!result){
                    totalSuccess=false;
                }
            }
            
        }
        //如果全部成功了
        if(totalSuccess){
            [db commit];
        }
        //失败了就回滚
        else{
            [db rollback];
        }
        [db close];
        //是否成功
        if (totalSuccess) {
            return true;
        } else {
            return false;
        }
    }
}



//通过ID获取消息
-(ChatMessage*)getMessageByID:(NSString*)messageID{
    @synchronized (self) {
        //获取db
        FMDatabase* db=[self openDB];
        if(db==nil){
            return nil;
        }
        FMResultSet *result = [db executeQuery:@"select * from message where messageId = ?" withArgumentsInArray:@[messageID]];
        //返回消息
        if ([result next]) {
            ChatMessage *msg = [ChatMessage new];
            msg.messageId = [result stringForColumn:@"messageId"];
            msg.messageSession = [result stringForColumn:@"messageSession"];
            msg.messageSessionType = [result intForColumn:@"messageSessionType"];
            msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
            msg.messageTableSeq = [result intForColumn:@"messageTableSeq"];
            msg.messageType = [result intForColumn:@"messageType"];
            msg.messageSend = [result stringForColumn:@"messageSend"];
            msg.messageSendExtendid = [result stringForColumn:@"messageSendExtendid"];
            msg.messageRecieve = [result stringForColumn:@"messageRecieve"];
            msg.messageRecieveExtendid = [result stringForColumn:@"messageRecieveExtendid"];
            msg.messageContent = [result stringForColumn:@"messageContent"];
            msg.messageSended = [result intForColumn:@"messageSended"];
            msg.messageReaded = [result intForColumn:@"messageReaded"];
            msg.messageDate = [result stringForColumn:@"messageDate"];
            msg.messageDeleted = [result intForColumn:@"messageDeleted"];
            msg.messageStamp = [result longForColumn:@"messageStamp"];
            msg.messageDeletedDate = [result stringForColumn:@"messageDeletedDate"];
            [result close];
            [db close];
            //返回消息
            return msg;
        }
        [result close];
        [db close];
        return nil;
    }
}

//更新数据
-(Boolean)updateMessage:(ChatMessage*)msg{
    @synchronized (self) {
        //获取db
        FMDatabase* db=[self openDB];
        if(db==nil){
            return false;
        }
        BOOL result = [db executeUpdate:@"update message set messageSession=?,messageSessionType=?,messageSessionOffset=?,messageTableSeq=?,messageType=?,messageSend=?,messageSendExtendid=?,messageRecieve=?,messageRecieveExtendid=?,messageContent=?,messageSended=?,messageReaded=?,messageDate=?,messageDeletedDate=?,messageDeleted=? where messageId = ?"
                   withArgumentsInArray:@[
                                          [FlappyStringTool toUnNullStr:msg.messageSession],
                                          [NSNumber numberWithInteger:msg.messageSessionType],
                                          [NSNumber numberWithInteger:msg.messageSessionOffset],
                                          [NSNumber numberWithInteger:msg.messageTableSeq],
                                          [NSNumber numberWithInteger:msg.messageType],
                                          [FlappyStringTool toUnNullStr:msg.messageSend],
                                          [FlappyStringTool toUnNullStr:msg.messageSendExtendid],
                                          [FlappyStringTool toUnNullStr:msg.messageRecieve],
                                          [FlappyStringTool toUnNullStr:msg.messageRecieveExtendid],
                                          [FlappyStringTool toUnNullStr:msg.messageContent],
                                          [NSNumber numberWithInteger:msg.messageSended],
                                          [NSNumber numberWithInteger:msg.messageReaded],
                                          [FlappyStringTool toUnNullStr:msg.messageDate],
                                          [FlappyStringTool toUnNullStr:msg.messageDeletedDate],
                                          [NSNumber numberWithInteger:msg.messageDeleted],
                                          msg.messageId]];
        [db close];
        if (result) {
            return true;
        } else {
            return false;
        }
    }
}

//通过会话ID获取最近的一次会话
-(ChatMessage*)getSessionLatestMessage:(NSString*)sessionID{
    @synchronized (self) {
        //获取db
        FMDatabase* db=[self openDB];
        if(db==nil){
            return nil;
        }
        FMResultSet *result = [db executeQuery:@"select * from message where messageSession = ? order by messageTableSeq desc,messageStamp desc limit 1" withArgumentsInArray:@[sessionID]];
        //返回消息
        if ([result next]) {
            ChatMessage *msg = [ChatMessage new];
            msg.messageId = [result stringForColumn:@"messageId"];
            msg.messageSession = [result stringForColumn:@"messageSession"];
            msg.messageSessionType = [result intForColumn:@"messageSessionType"];
            msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
            msg.messageTableSeq = [result intForColumn:@"messageTableSeq"];
            msg.messageType = [result intForColumn:@"messageType"];
            msg.messageSend = [result stringForColumn:@"messageSend"];
            msg.messageSendExtendid = [result stringForColumn:@"messageSendExtendid"];
            msg.messageRecieve = [result stringForColumn:@"messageRecieve"];
            msg.messageRecieveExtendid = [result stringForColumn:@"messageRecieveExtendid"];
            msg.messageContent = [result stringForColumn:@"messageContent"];
            msg.messageSended = [result intForColumn:@"messageSended"];
            msg.messageReaded = [result intForColumn:@"messageReaded"];
            msg.messageDate = [result stringForColumn:@"messageDate"];
            msg.messageDeleted = [result intForColumn:@"messageDeleted"];
            msg.messageStamp = [result longForColumn:@"messageStamp"];
            msg.messageDeletedDate = [result stringForColumn:@"messageDeletedDate"];
            [result close];
            [db close];
            //返回消息
            return msg;
        }
        [result close];
        [db close];
        return nil;
    }
}

//获取消息
-(NSMutableArray*)getSessionSequeceMessage:(NSString*)sessionID
                                withOffset:(NSString*)tabSequece{
    //获取db
    FMDatabase* db=[self openDB];
    if(db==nil){
        return nil;
    }
    FMResultSet *result = [db executeQuery:@"select * from message where messageSession = ? and messageTableSeq=? order by messageStamp  desc" withArgumentsInArray:@[sessionID,tabSequece]];
    
    //创建消息列表
    NSMutableArray* retArray=[[NSMutableArray alloc]init];
    //返回消息
    while ([result next]) {
        //获取之前的消息
        ChatMessage *msg = [ChatMessage new];
        msg.messageId = [result stringForColumn:@"messageId"];
        msg.messageSession = [result stringForColumn:@"messageSession"];
        msg.messageSessionType = [result intForColumn:@"messageSessionType"];
        msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
        msg.messageTableSeq = [result intForColumn:@"messageTableSeq"];
        msg.messageType = [result intForColumn:@"messageType"];
        msg.messageSend = [result stringForColumn:@"messageSend"];
        msg.messageSendExtendid = [result stringForColumn:@"messageSendExtendid"];
        msg.messageRecieve = [result stringForColumn:@"messageRecieve"];
        msg.messageRecieveExtendid = [result stringForColumn:@"messageRecieveExtendid"];
        msg.messageContent = [result stringForColumn:@"messageContent"];
        msg.messageSended = [result intForColumn:@"messageSended"];
        msg.messageReaded = [result intForColumn:@"messageReaded"];
        msg.messageDate = [result stringForColumn:@"messageDate"];
        msg.messageDeleted = [result intForColumn:@"messageDeleted"];
        msg.messageStamp = [result longForColumn:@"messageStamp"];
        msg.messageDeletedDate = [result stringForColumn:@"messageDeletedDate"];
        [retArray addObject:msg];
    }
    [result close];
    [db close];
    return retArray;
}

//获取没有处理的系统消息
-(NSMutableArray*)getNotActionSystemMessageWithSession:(NSString*)sessionID{
    @synchronized (self) {
        //获取db
        FMDatabase* db=[self openDB];
        if(db==nil){
            return nil;
        }
        FMResultSet *result = [db executeQuery:@"select * from message where messageReaded = 0 and messageType=0 and messageSession=? order by messageTableSeq  desc" withArgumentsInArray:@[sessionID]];
        
        //创建消息列表
        NSMutableArray* retArray=[[NSMutableArray alloc]init];
        //返回消息
        while ([result next]) {
            //获取之前的消息
            ChatMessage *msg = [ChatMessage new];
            msg.messageId = [result stringForColumn:@"messageId"];
            msg.messageSession = [result stringForColumn:@"messageSession"];
            msg.messageSessionType = [result intForColumn:@"messageSessionType"];
            msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
            msg.messageTableSeq = [result intForColumn:@"messageTableSeq"];
            msg.messageType = [result intForColumn:@"messageType"];
            msg.messageSend = [result stringForColumn:@"messageSend"];
            msg.messageSendExtendid = [result stringForColumn:@"messageSendExtendid"];
            msg.messageRecieve = [result stringForColumn:@"messageRecieve"];
            msg.messageRecieveExtendid = [result stringForColumn:@"messageRecieveExtendid"];
            msg.messageContent = [result stringForColumn:@"messageContent"];
            msg.messageSended = [result intForColumn:@"messageSended"];
            msg.messageReaded = [result intForColumn:@"messageReaded"];
            msg.messageDate = [result stringForColumn:@"messageDate"];
            msg.messageDeleted = [result intForColumn:@"messageDeleted"];
            msg.messageStamp = [result longForColumn:@"messageStamp"];
            msg.messageDeletedDate = [result stringForColumn:@"messageDeletedDate"];
            [retArray addObject:msg];
        }
        [result close];
        [db close];
        return retArray;
    }
}

//获取没有处理的系统消息
-(NSMutableArray*)getNotActionSystemMessage{
    @synchronized (self) {
        //获取db
        FMDatabase* db=[self openDB];
        if(db==nil){
            return nil;
        }
        FMResultSet *result = [db executeQuery:@"select * from message where messageReaded = 0 and messageType=0 order by messageTableSeq  desc"];
        
        //创建消息列表
        NSMutableArray* retArray=[[NSMutableArray alloc]init];
        //返回消息
        while ([result next]) {
            //获取之前的消息
            ChatMessage *msg = [ChatMessage new];
            msg.messageId = [result stringForColumn:@"messageId"];
            msg.messageSession = [result stringForColumn:@"messageSession"];
            msg.messageSessionType = [result intForColumn:@"messageSessionType"];
            msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
            msg.messageTableSeq = [result intForColumn:@"messageTableSeq"];
            msg.messageType = [result intForColumn:@"messageType"];
            msg.messageSend = [result stringForColumn:@"messageSend"];
            msg.messageSendExtendid = [result stringForColumn:@"messageSendExtendid"];
            msg.messageRecieve = [result stringForColumn:@"messageRecieve"];
            msg.messageRecieveExtendid = [result stringForColumn:@"messageRecieveExtendid"];
            msg.messageContent = [result stringForColumn:@"messageContent"];
            msg.messageSended = [result intForColumn:@"messageSended"];
            msg.messageReaded = [result intForColumn:@"messageReaded"];
            msg.messageDate = [result stringForColumn:@"messageDate"];
            msg.messageDeleted = [result intForColumn:@"messageDeleted"];
            msg.messageStamp = [result longForColumn:@"messageStamp"];
            msg.messageDeletedDate = [result stringForColumn:@"messageDeletedDate"];
            [retArray addObject:msg];
        }
        [result close];
        [db close];
        return retArray;
    }
}

//通过sessionID，获取之前的
-(NSMutableArray*)getSessionFormerMessage:(NSString*)sessionID
                      withMessageID:(NSString*)messageId
                           withSize:(NSInteger)size{
    
    
    //获取当前的消息ID
    ChatMessage* msg=[self getMessageByID:messageId];
    
    
    @synchronized (self) {
        NSMutableArray* retArray=[[NSMutableArray alloc] init];
        //当前的
        NSMutableArray* sequeceArray=[self getSessionSequeceMessage:sessionID
                                                         withOffset:[NSString stringWithFormat:@"%ld",(long)msg.messageTableSeq]];
        
        for(int s=0;s<sequeceArray.count;s++){
            ChatMessage* mem=[sequeceArray objectAtIndex:s];
            if(mem.messageStamp<msg.messageStamp){
                [retArray addObject:mem];
            }
        }
        
        //获取db
        FMDatabase* db=[self openDB];
        if(db==nil){
            return nil;
        }
        FMResultSet *result = [db executeQuery:@"select * from message where messageSession = ? and messageTableSeq<? order by messageTableSeq desc,messageStamp  desc limit ?" withArgumentsInArray:@[sessionID,[NSNumber numberWithInteger:msg.messageTableSeq],[NSNumber numberWithInteger:size]]];
        
        //创建消息列表
        NSMutableArray* listArray=[[NSMutableArray alloc]init];
        //返回消息
        while ([result next]) {
            //获取之前的消息
            ChatMessage *msg = [ChatMessage new];
            msg.messageId = [result stringForColumn:@"messageId"];
            msg.messageSession = [result stringForColumn:@"messageSession"];
            msg.messageSessionType = [result intForColumn:@"messageSessionType"];
            msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
            msg.messageTableSeq = [result intForColumn:@"messageTableSeq"];
            msg.messageType = [result intForColumn:@"messageType"];
            msg.messageSend = [result stringForColumn:@"messageSend"];
            msg.messageSendExtendid = [result stringForColumn:@"messageSendExtendid"];
            msg.messageRecieve = [result stringForColumn:@"messageRecieve"];
            msg.messageRecieveExtendid = [result stringForColumn:@"messageRecieveExtendid"];
            msg.messageContent = [result stringForColumn:@"messageContent"];
            msg.messageSended = [result intForColumn:@"messageSended"];
            msg.messageReaded = [result intForColumn:@"messageReaded"];
            msg.messageDate = [result stringForColumn:@"messageDate"];
            msg.messageDeleted = [result intForColumn:@"messageDeleted"];
            msg.messageStamp = [result longForColumn:@"messageStamp"];
            msg.messageDeletedDate = [result stringForColumn:@"messageDeletedDate"];
            [listArray addObject:msg];
        }
        
        [result close];
        [db close];
        
        [retArray addObjectsFromArray:listArray];
        
        if(retArray.count>size){
            NSMutableArray* newArray=[[NSMutableArray alloc]init];
            for(int s=0;s<size;s++){
                [newArray addObject: [retArray objectAtIndex:s]];
            }
            retArray=newArray;
        }
        
        return retArray;
    }
}



@end
