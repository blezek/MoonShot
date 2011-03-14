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
- (NSString*)initLuaObject:(NSString*)class withObjects:(NSDictionary*)map toState:(lua_State*)L;

// Assumes you've push count arguments on the stack
- (void)callMethod:(NSString*)method onObject:(NSString*)name withArgCount:(int)count toState:(lua_State*)L;

- (id)init;
@end
