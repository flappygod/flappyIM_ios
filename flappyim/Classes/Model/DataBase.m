//
//  DataBase.m
//  AFNetworking
//
//  Created by lijunlin on 2019/8/8.
//

#import "DataBase.h"

@implementation DataBase

//使用单例模式
+ (instancetype)shareInstance {
    static DataBase *_sharedSingleton = nil;
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
    return [DataBase shareInstance];
}

// 防止外部调用copy
- (id)copyWithZone:(nullable NSZone *)zone {
    return [DataBase shareInstance];
}

// 防止外部调用mutableCopy
- (id)mutableCopyWithZone:(nullable NSZone *)zone {
    return [DataBase shareInstance];
}

//初始化数据库
-(void)setup{
    //获取db
    FMDatabase* db=[self openDB];
    if(db==nil){
        return;
    }
    //4.数据库中创建表（可创建多张）
    NSString *sql = @"create table if not exists message ('messageId' TEXT PRIMARY KEY,'messageSession' TEXT,'messageSessionType' INTEGER,'messageSessionOffset' INTEGER,'messageTableSeq' INTEGER,'messageType' INTEGER ,'messageSend' TEXT,'messageRecieve' TEXT,'messageContent' TEXT,'messageSended' INTEGER,'messageReaded' INTEGER,'messageDate' TEXT,'messageDeletedDate' TEXT,'messageDeleted' INTEGER)";
    //5.执行更新操作 此处database直接操作，不考虑多线程问题，多线程问题，用FMDatabaseQueue 每次数据库操作之后都会返回bool数值，YES，表示success，NO，表示fail,可以通过 @see lastError @see lastErrorCode @see lastErrorMessage
    BOOL result = [db executeUpdate:sql];
    if (result) {
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

//插入消息
-(Boolean)insert:(ChatMessage*)msg{
    //获取db
    FMDatabase* db=[self openDB];
    if(db==nil){
        return false;
    }
    BOOL result = [db executeUpdate:@"insert into 'message'(messageId,messageSession,messageSessionType,messageSessionOffset,messageTableSeq,messageType,messageSend,messageRecieve,messageContent,messageSended,messageReaded,messageDate,messageDeletedDate,messageDeleted) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?)" withArgumentsInArray:@[msg.messageId,msg.messageSession,[NSNumber numberWithInteger:msg.messageSessionType],[NSNumber numberWithInteger:msg.messageSessionOffset],[NSNumber numberWithInteger:msg.messageTableSeq],[NSNumber numberWithInteger:msg.messageType],msg.messageSend,msg.messageRecieve,msg.messageContent,[NSNumber numberWithInteger:msg.messageSended],[NSNumber numberWithInteger:msg.messageReaded],msg.messageDate,msg.messageDeletedDate,[NSNumber numberWithInteger:msg.messageDeleted]]];
    [db close];
    if (result) {
        return true;
    } else {
        return false;
    }
}

//通过ID获取消息
-(ChatMessage*)getMessageByID:(NSString*)messageID{
    //获取db
    FMDatabase* db=[self openDB];
    if(db==nil){
        return nil;
    }
    FMResultSet *result = [db executeQuery:@"select * from 'message' where messageId = ?" withArgumentsInArray:@[messageID]];
    //返回消息
    while ([result next]) {
        ChatMessage *msg = [ChatMessage new];
        msg.messageId = [result stringForColumn:@"messageId"];
        msg.messageSession = [result stringForColumn:@"messageSession"];
        msg.messageSessionType = [result intForColumn:@"messageSessionType"];
        msg.messageSessionOffset = [result intForColumn:@"messageSessionOffset"];
        msg.messageTableSeq = [result intForColumn:@"messageTableSeq"];
        msg.messageType = [result intForColumn:@"messageType"];
        msg.messageSend = [result stringForColumn:@"messageSend"];
        msg.messageRecieve = [result stringForColumn:@"messageRecieve"];
        msg.messageContent = [result stringForColumn:@"messageContent"];
        msg.messageSended = [result intForColumn:@"messageSended"];
        msg.messageReaded = [result intForColumn:@"messageReaded"];
        msg.messageDate = [result stringForColumn:@"messageDate"];
        msg.messageDeleted = [result intForColumn:@"messageDeleted"];
        msg.messageDeletedDate = [result stringForColumn:@"messageDeletedDate"];
        [db close];
        //返回消息
        return msg;
    }
    [db close];
    return nil;
}

//更新数据
-(Boolean)updateMessage:(ChatMessage*)msg{
    //获取db
    FMDatabase* db=[self openDB];
    if(db==nil){
        return false;
    }
    BOOL result = [db executeUpdate:@"update 'message'set messageSession=?,messageSessionType=?,messageSessionOffset=?,messageTableSeq=?,messageType=?,messageSend=?,messageRecieve=?,messageContent=?,messageSended=?,messageReaded=?,messageDate=?,messageDeletedDate=?,messageDeleted=? where messageId = ?" withArgumentsInArray:@[msg.messageSession,[NSNumber numberWithInteger:msg.messageSessionType],[NSNumber numberWithInteger:msg.messageSessionOffset],[NSNumber numberWithInteger:msg.messageTableSeq],[NSNumber numberWithInteger:msg.messageType],msg.messageSend,msg.messageRecieve,msg.messageContent,[NSNumber numberWithInteger:msg.messageSended],[NSNumber numberWithInteger:msg.messageReaded],msg.messageDate,msg.messageDeletedDate,[NSNumber numberWithInteger:msg.messageDeleted],msg.messageId]];
    [db close];
    if (result) {
        return true;
    } else {
        return false;
    }
}


@end
