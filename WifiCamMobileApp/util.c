//
//  util.c
//  elf_share
//
//  Created by elecfreaks on 15/7/2.
//  Copyright (c) 2015年 elecfreaks. All rights reserved.
//

#include "util.h"

float clip(float value, float min, float max) {
    if(value>max)
        return max;
    if(value<min)
        return min;
    return value;
}