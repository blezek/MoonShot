//
//  BindLua.m
//  LuaShot
//
//  Created by blezek on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BindLua.h"
#import "NSObject+Properties.h"
#import <objc/runtime.h>

@implementation BindLua

- (void)bind:(Class)obj toState:(lua_State *)L {

  // Start the introspection

  NSLog(@"Methods: %@", [obj methodNames] );
  
}

@end
