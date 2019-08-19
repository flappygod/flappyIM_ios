//
//  FlappyDef.h
//  Istudy
//
//  Created by macbook air on 16/7/8.
//  Copyright © 2016年 lipo. All rights reserved.
//

#ifndef FlappyDef_h
#define FlappyDef_h


// View 坐标(x,y)和宽高(width,height)
#define X(v)                    (v).frame.origin.x
#define Y(v)                    (v).frame.origin.y
#define WIDTH(v)                (v).frame.size.width
#define HEIGHT(v)               (v).frame.size.height


// 当前版本
#define FSystemVersion          ([[[UIDevice currentDevice] systemVersion] floatValue])
#define DSystemVersion          ([[[UIDevice currentDevice] systemVersion] doubleValue])
#define SSystemVersion          ([[UIDevice currentDevice] systemVersion])

// 当前语言
#define CURRENTLANGUAGE         ([[NSLocale preferredLanguages] objectAtIndex:0])

// 是否Retina屏
#define isRetina                ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? \
CGSizeEqualToSize(CGSizeMake(640, 960), \
[[UIScreen mainScreen] currentMode].size) : \
NO)

// 是否iPad
#define isPad                   (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)


//NSUserDefault 存数据
#define UNSaveObject(obj,key) \
if(obj!=nil && key!=nil){ \
[[NSUserDefaults standardUserDefaults] setObject:obj forKey:key]; \
[[NSUserDefaults standardUserDefaults] synchronize]; \
}


#define UNSaveInteger(obj,key) \
if(key!=nil){ \
[[NSUserDefaults standardUserDefaults] setInteger:obj forKey:key]; \
[[NSUserDefaults standardUserDefaults] synchronize]; \
}

//NSUserDefault 取数据
#define UNGetInteger(key)    key!=nil ? [[NSUserDefaults standardUserDefaults] integerForKey:key] : 0

#define UNGetObject(key)    key!=nil ? [[NSUserDefaults standardUserDefaults] objectForKey:key] : nil


//NSUserDefault 移除数据
#define UNRemoveObject(key)\
[[NSUserDefaults standardUserDefaults] removeObjectForKey:key];\
[[NSUserDefaults standardUserDefaults] synchronize];

//一个像素点的line
#define SPACELINE_HEIGHT   1.0f/[[UIScreen mainScreen] scale]  
//[[UIScreen mainScreen] bounds].size.height >667 ?  0.3f:0.5f

//创建一个颜色
#define UNColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]


#define UNColorAlpha(r, g, b ,a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]

#endif /* FlappyDef_h */
