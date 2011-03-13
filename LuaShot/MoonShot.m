//
//  MoonShot.m
//  LuaShot
//
//  Created by blezek on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MoonShot.h"
#import "NSObject+Properties.h"
#import <objc/runtime.h>

#define MAX_ARGS

typedef struct {
  NSInvocation *invocation;
  char argtypes[MAX_ARGS];
} MethodContext;

static int thunk ( lua_State *L ) {
  NSLog(@"thunk!");
  return 0;
}


@implementation MoonShot

- (id)init {
  self = [super init];
  registeredClasses = [NSMutableDictionary dictionaryWithCapacity:10];
  return self;
}

- (void)bridge:(id)object withName:(NSString*)name toState:(lua_State*)L {
  lua_pushstring(L, [name UTF8String]);
  // Represent to lua
  id *handle = (id*)lua_newuserdata(L,sizeof(id));
  *handle = object;
  luaL_getmetatable (L, class_getName([object class]) );
  lua_setmetatable(L, -2);
  lua_settable(L,LUA_GLOBALSINDEX);
}

- (void)bind:(Class)obj toState:(lua_State *)L {

  // Start the introspection
  NSString *className = NSStringFromClass ( obj );
  
  unsigned int i, count = 0;
	Method * methods = class_copyMethodList( obj, &count );
	
	if ( count == 0 ) {
    NSLog ( @"No methods defined" );
	}

  // Add things to Lua, start with a new table
  lua_newtable ( L );
  int methodTable = lua_gettop ( L );
  luaL_newmetatable ( L, [className UTF8String] );
  int metatable = lua_gettop(L);
  lua_pushstring ( L, [className UTF8String] );
  lua_pushvalue ( L, methodTable );
  lua_settable(L, LUA_GLOBALSINDEX );
  lua_pushliteral(L,"__metatable");
  lua_pushvalue(L,methodTable);
  lua_settable(L,metatable);
  
  lua_pushliteral(L,"__index");
  lua_pushvalue ( L, methodTable );
  lua_settable(L,metatable);
  
	for ( i = 0; i < count; i++ ) {
    // Create invokers for each method
    NSString *name = [NSString stringWithUTF8String: sel_getName(method_getName ( methods[i]))];
    name = [name stringByReplacingOccurrencesOfRegex:@":" withString:@""];
    NSLog (@"New name is %@", name );
    SEL selector = method_getName ( methods[i] );
    if ( selector == 0 ) {
      NSLog ( @"Selector is zero!" );
    }
    
    unsigned int numberOfArguments = method_getNumberOfArguments(methods[i]);
    char returnType[64];
    method_getReturnType(methods[i], returnType, 64);

    NSLog(@"Method: %@ has %d arguments and returns %s", name, numberOfArguments, returnType );
    MethodContext* context = (MethodContext*)malloc(sizeof(MethodContext));
    for ( unsigned int idx = 0; idx < numberOfArguments; idx++ ) {
      char argumentType[128];
      method_getArgumentType(methods[i], idx, argumentType, 128);
      NSLog(@"\tArgument %d is of type %s", idx, argumentType );
      context->argtypes[idx] = argumentType[0];
    }
    // We need to create a closure containing the invocation
    NSLog(@"Signature: %@", [obj instanceMethodSignatureForSelector:@selector(didReceiveMemoryWarning)] );
    context->invocation = [NSInvocation invocationWithMethodSignature:[obj instanceMethodSignatureForSelector:selector]];
    lua_pushstring ( L, [name UTF8String] );
    lua_pushlightuserdata(L, (void*)context);
    lua_pushcclosure(L, thunk, 1);
    lua_settable ( L, methodTable );
  }
  free ( methods );
  
}

@end
