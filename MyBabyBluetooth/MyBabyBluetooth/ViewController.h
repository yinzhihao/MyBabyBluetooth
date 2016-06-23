//
//  ViewController.h
//  MyBabyBluetooth
//
//  Created by yinzhihao on 16/6/12.
//  Copyright © 2016年 yzh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BabyBluetooth.h"

typedef enum : NSUInteger {
    Align_Left = 0x00,
    Align_Center,
    Align_Right
} Align_Type_e;

typedef enum : NSUInteger {
    Char_Normal = 0x00,
    Char_Zoom_2,
    Char_Zoom_3,
    Char_Zoom_4
} Char_Zoom_Num_e;
@interface ViewController : UIViewController


@end

