//
//  MoonShot.m
//  LuaShot
//
//  Created by blezek on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MoonShot.h"
#import "NSObject+Properties.h"
#import "RegexKitLite.h"
#import <objc/runtime.h>

static int ObjectCounter = 0;
#define MAX_ARGS 5

typedef struct {
  NSInvocation *invocation;
  char argtypes[MAX_ARGS];
} MethodContext;

static int thunk ( lua_State *L ) {
  NSLog(@"thunk!");
  MethodContext *context = (MethodContext*)lua_touserdata(L, lua_upvalueindex(1));
  NSInvocation *invocation = context->invocation;
  NSLog(@"Invocation: %@", invocation );
  NSMethodSignature *signature = [invocation methodSignature];
  NSLog(@"Found invocation: %@ with signature %@", invocation, signature );
  
  // Do we have enough arguments
  int numberOfLuaArgs = lua_gettop(L);
  int numberOfObjCArgs = [signature numberOfArguments];
  // Both have id(self), but ObjectiveC adds the selector, yet Lua starts at 1!
  if ( (numberOfLuaArgs + 1) != numberOfObjCArgs ) {
    return luaL_error(L, "method requires %d arguments, given %d", numberOfObjCArgs, numberOfLuaArgs );
  }
  for ( int idx = 2; idx < numberOfObjCArgs; idx++ ) {
    const char* argString = [signature getArgumentTypeAtIndex:idx];
    char argType = argString[0];
    int luaType = lua_type(L, idx);
    NSLog(@"ObjC type: %s Lua type: %d", argString, luaType);
    
    // Lua has the fewer "types"
    switch ( luaType ) {
      case LUA_TSTRING: {
        if ( argType == _C_ID ) {
          NSString *arg = [NSString stringWithUTF8String:lua_tostring(L,idx)];
          [invocation setArgument:&arg atIndex:idx];
          NSLog(@"Set string argument to %@", arg);
        } else {
          return luaL_error(L, "unexpected string argument");
        }
        break;
      }
      case LUA_TNUMBER: {
        int intArg;
        short shortArg;
        float floatArg;
        double doubleArg;
        void *arg;
        switch ( argType ) {
          case _C_INT:
            intArg = (int)lua_tonumber(L, idx);
            arg = &intArg;
            break;
          case _C_SHT:
            shortArg = (short)lua_tonumber(L, idx);
            arg = &shortArg;
            break;
          case _C_DBL:
            shortArg = (double)lua_tonumber(L, idx);
            arg = &doubleArg;
            break;
          case _C_FLT:
            shortArg = (float)lua_tonumber(L, idx);
            arg = &floatArg;
            break;
          default:
            return luaL_error(L, "unexpected numeric argument");
        }
        NSLog(@"Set numeric argument %f", lua_tonumber(L, idx) );
        [invocation setArgument:arg atIndex:idx];
      }
    }
  }
  // OK, actually run it!
  // We must have an ObjectiveC object...
  id obj = *((id*)lua_touserdata(L, 1));
  NSLog(@"Object is: %@", obj);
  
  [invocation invokeWithTarget:obj];
  
  return 0;
}

static void DumpStack(lua_State* l)
{
  int i;
  int top = lua_gettop(l);
  
  NSLog(@"Total in stack %d",top);
  
  for (i = top; i >= 1; i--)
  {  /* repeat for each level */
    int t = lua_type(l, i);
    switch (t) {
      case LUA_TSTRING:  /* strings */
        NSLog(@"\t(%d)string: '%s'", i, lua_tostring(l, i));
        break;
      case LUA_TBOOLEAN:  /* booleans */
        NSLog(@"\t(%d)boolean %s",i, lua_toboolean(l, i) ? "true" : "false");
        break;
      case LUA_TNUMBER:  /* numbers */
        NSLog(@"\t(%d)number: %g", i, lua_tonumber(l, i));
        break;
      default:  /* other values */
        NSLog(@"\t(%d)%s", i, lua_typename(l, t));
        break;
    }
  }
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
  NSLog(@"Finishing bridge");
  lua_pop(L, 2);
  DumpStack(L);
}

- (void)callMethod:(NSString*)method onObject:(NSString*)name withArgCount:(int)count toState:(lua_State*)L {
  
  // Get the global variable
  NSLog(@"Starting callMethod" );
  DumpStack(L);
  lua_getglobal(L, [name UTF8String]);
  DumpStack(L);
  
  lua_getglobal(L, "DumpTable");
  
  lua_insert(L,-2);
  DumpStack(L);
  lua_call(L, 1, 0);
  DumpStack(L);

  lua_getglobal(L, [name UTF8String]);
  DumpStack(L);
  if ( !lua_getmetatable(L, -1) ) {
    NSLog(@"No meta table");
    lua_pop(L, 1);
    return;
  }
  
  
  
  lua_pushstring(L, [method UTF8String]);
  lua_gettable(L, -2);
  if ( lua_isnil(L, -1) ) {
    NSLog(@"Failed to find method" );
    DumpStack(L);
    lua_pop(L, 2);
    return;
  }
  lua_remove(L, -2); // Pull off the meta table
  NSLog(@"Fonud method");
  DumpStack(L);
  
  // Stack (top)  method object arguments... (bottom)
  // Move the object to the 1st argument
  lua_insert ( L, -count - 2 );
  lua_insert ( L, -count - 1 );
  NSLog(@"Ready to call!" );
  DumpStack(L);
  int status = lua_pcall(L, count+1, 0, 0);
  if ( status != 0 ) {
    DumpStack(L);
    NSLog (@"Error(%d) calling method %@ on object %@: %s", status, method, name, lua_tostring(L, -1) );
    lua_pop(L, 1);
  }
  
}

// Create a lua object of the given class (class.init(self)), where self
// is a dictionary containing the given objects.
- (NSString*)initLuaObject:(NSString*)class withObjects:(NSDictionary*)map toState:(lua_State*)L {
  NSLog(@"Starting initLuaObject");
  DumpStack(L);
  // Find the right method!
  lua_getglobal(L,[class UTF8String]);
  // Did we get a table?
  if ( lua_type(L, -1) != LUA_TTABLE ) {
    NSLog(@"Class %@ didn't return a Lua table!", class);
    return nil;
  }
  // Find the init method
  lua_getfield(L, -1, "init");
  if ( lua_type(L,-1) != LUA_TFUNCTION ) {
    NSLog(@"Class %@ didn't have an init method", class);
    return nil;
  }
  // Remove the table
  lua_remove(L, -2);
  NSLog(@"Should have only the init method");
  DumpStack(L);
  
  // Create our "self"
  lua_newtable(L);
  int tableIdx = lua_gettop(L);
  for ( NSString *key in [map allKeys] ) {
    // Represent to lua
    id *handle = (id*)lua_newuserdata(L,sizeof(id));
    id obj = [map objectForKey:key];
    *handle = obj;
    luaL_getmetatable (L, class_getName([obj class]) );
    lua_setmetatable(L, -2);
    lua_setfield(L, tableIdx, [key UTF8String]);
    NSLog(@"Set field %@ to value %@", key, obj );
  }
  NSLog(@"Right before init call");
  DumpStack(L);
  lua_call ( L, 1, 1 );
  NSString *name = [NSString stringWithFormat:@"LuaObject%d", ObjectCounter++];
  lua_setglobal(L,[name UTF8String]);
  // lua_pop(L, 1);  // Pop the object off
  DumpStack(L);
  return name;
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
    [context->invocation setSelector:selector];
    NSLog(@"Invocation: %@", context->invocation );
    lua_pushstring ( L, [name UTF8String] );
    lua_pushlightuserdata(L, (void*)context);
    lua_pushcclosure(L, thunk, 1);
    lua_settable ( L, methodTable );
  }
  free ( methods );
  
}

@end
