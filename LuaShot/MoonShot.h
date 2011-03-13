//
//  MoonShot.h
//  LuaShot
//
//  Created by blezek on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "lua.h"
#import "lualib.h"
#import "lauxlib.h"

@interface MoonShot : NSObject {
  NSMutableDictionary *registeredClasses;
}

- (void)bind:(Class)obj toState:(lua_State*) L;
- (void)bridge:(id)object withName:(NSString*)name toState:(lua_State*)L;
- (id)init;
@end
