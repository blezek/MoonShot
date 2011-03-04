//
//  BindLua.h
//  LuaShot
//
//  Created by blezek on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "lua.h"

@interface BindLua : NSObject {
}

-(void)bind:(Class)obj toState:(lua_State*) L;

@end
