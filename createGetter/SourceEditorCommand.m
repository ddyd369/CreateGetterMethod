//
//  SourceEditorCommand.m
//  createGetter
//
//  Created by 赵丹 on 2016/9/30.
//  Copyright © 2016年 microfastup. All rights reserved.
//
/*
 *第一版先实现基本功能.
 *第二步, 使它不会重复生成getter方法
 *3.对不同的对象类型分别定制生成的代码
 *4.生成的代码可以指定样式. 也就是将样式作为参数抛出去. 可以在外部定制.
 *5.模仿Eclipse. 点击生成setter. getter. 先弹出对话框. 由用户选择生成那些属性的setter. getter方法
 *6.找到当前编辑器光标所在行. 将生成的setter getter 从光标所在行插入.
 *7.setter getter 方法类型可以在对话框中选择.  例如. button[UIButton alloc] init]; 还是[UIButton buttonTypexxxx...];
 */

#import "SourceEditorCommand.h"
#import <Cocoa/Cocoa.h>

@interface SourceEditorCommand ()

@property (nonatomic, assign) NSInteger predicate;
@property (nonatomic, strong) NSMutableArray *indexsArray;

@end

@implementation SourceEditorCommand

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler
{
    self.predicate = NO;
    NSArray *stringArray = [NSArray arrayWithArray:invocation.buffer.lines];
    
    self.indexsArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < stringArray.count; i++) {
        if (!self.predicate) {
            [self beginPredicate:stringArray[i]];
        }else
        {
            if ([self endPredicate:stringArray[i]]) {
                NSMutableArray *resultArray = [self makeResultStringArray];
                
                for (int i = (int)invocation.buffer.lines.count - 1; i > 0 ; i--) {
                    NSString *stringend = stringArray[i];
                    if ([stringend containsString:@"@end"]) {
                        for (NSArray *array in resultArray) {
                            
                            for (int x = (int)(array.count - 1); x >= 0; x--) {
                                [invocation.buffer.lines addObject:@""];
                                [invocation.buffer.lines insertObject:array[x] atIndex:i - 1];
                            }
                        }
                    }else if ([stringend containsString:@"@implementation"])
                    {
                        completionHandler(nil);
                        return;
                    }
                }
                completionHandler(nil);
                return;
            }else
            {
                //没有匹配到 end  需要匹配property
                [self predicateForProperty:stringArray[i]];
                
            }
        }
    }
    completionHandler(nil);
}


- (NSMutableArray *)makeResultStringArray
{
    NSMutableArray *itemsArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.indexsArray.count; i++) {
        
        NSString *categoryStr = self.indexsArray[i][@"category"];
        NSString *nameStr = self.indexsArray[i][@"name"];
        
        NSString *line1 = [NSString stringWithFormat:@"- (%@ *)%@", categoryStr, nameStr];
        NSString *line2 = [NSString stringWithFormat:@"{"];
        NSString *line3 = [NSString stringWithFormat:@"    if (!_%@) {", nameStr];
        NSString *line4 = [NSString stringWithFormat:@"        _%@ = [[%@ alloc] init];", nameStr, categoryStr];
        NSString *line5 = [NSString stringWithFormat:@"    }"];
        NSString *line6 = [NSString stringWithFormat:@"    return _%@;", nameStr];
        NSString *line7 = [NSString stringWithFormat:@"}"];
        NSString *line8 = [NSString stringWithFormat:@""];
        
        NSMutableArray *lineArrays = [[NSMutableArray alloc] initWithObjects:line1, line2, line3, line4, line5, line6, line7, line8, nil];
        [itemsArray addObject:lineArrays];
    }
    return itemsArray;
}

- (NSMutableArray *)indexsArray
{
    if (!_indexsArray) {
        _indexsArray = [[NSMutableArray alloc] init];
    }
    return _indexsArray;
}



- (void)predicateForProperty:(NSString *)string
{
    NSString *str = string;
    NSPredicate *pre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^@property.*;\\n$"];
    if ([pre evaluateWithObject:str]) {
        //这是一个property.
        if (![str containsString:@"IBOutlet"] && ![str containsString:@"^"] && ![str containsString:@"//"]) {
            //不是IBOutLet或者blcok  也就是说它是一个需要声场getter方法的属性.
            NSString *category = @"";
            NSString *name = @"";
            
            NSRange range1 = [str rangeOfString:@"\\).*\\*" options:NSRegularExpressionSearch];
            NSString *string1 = [str substringWithRange:range1];
            NSRange range2 = [string1 rangeOfString:@"[a-zA-Z0-9_]+" options:NSRegularExpressionSearch];
            category = [string1 substringWithRange:range2];
            
            NSRange range3 = [str rangeOfString:@"\\*.*;" options:NSRegularExpressionSearch];
            NSString *string2 = [str substringWithRange:range3];
            NSRange range4 = [string2 rangeOfString:@"[a-zA-Z0-9_]+" options:NSRegularExpressionSearch];
            name = [string2 substringWithRange:range4];
            
            NSDictionary *dic = @{@"category" : category, @"name" : name};
            [self.indexsArray addObject:dic];
        }
    }
}


- (void)beginPredicate:(NSString *)string
{
    NSString *str = string;
    if ([str containsString:@"@interface"]) {
        self.predicate = YES;
    }
}

- (BOOL)endPredicate:(NSString *)string
{
    if ([string containsString:@"@end"]) {
        self.predicate = NO;
        return YES;
    }
    return NO;
}

@end
