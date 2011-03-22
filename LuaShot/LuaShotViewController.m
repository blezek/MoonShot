//
//  LuaShotViewController.m
//  LuaShot
//
//  Created by blezek on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LuaShotViewController.h"
#import "MoonShot.h"
#include "lua.h"

@implementation LuaShotViewController

- (void)log:(NSString*) msg {
  NSLog(@"message is %@", msg);
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  MoonShot *shot = [[MoonShot alloc] init];
  lua_State *L = lua_open();  /* create state */
  luaL_openlibs(L);  /* open libraries */
  [shot bind:[self class] toState:L];
  // Run our Lua test code
  
  lua_getglobal( L, "package" );
  lua_getfield( L, -1, "path" ); // get field "path" from table at top of stack (-1)
  NSString *currentPath = [NSString stringWithUTF8String: lua_tostring( L, -1 )]; // grab path string from top of stack
  currentPath = [currentPath stringByAppendingFormat:@";%@/?.lua", [[NSBundle mainBundle] resourcePath]]; // do your path magic here
  NSLog(@"Path is %@", currentPath);
  lua_pop( L, 1 ); // get rid of the string on the stack we just pushed on line 5
  lua_pushstring( L, [currentPath UTF8String] ); // push the new one
  lua_setfield( L, -2, "path" ); // set the field "path" in table at -2 with value at top of stack
  lua_pop( L, 1 ); // get rid of package table from top of stack
  
  [shot bridge:self withName:@"controller" toState:L];
  int status = luaL_dofile ( L, [[[NSBundle mainBundle] pathForResource:@"Test.lua" ofType:nil] UTF8String] );
  if ( status ) {
    NSLog(@"file: Test.lua had errors:\n%s", lua_tostring(L,-1) );
  }
  // Create our object
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self, @"controller", nil];
  NSString *obj = [shot initLuaObject:@"Test" withObjects:dict toState:L];
  
  // Call our Lua code
  lua_pushliteral ( L, "Calling Lua from ObjC" );
  [shot callMethod:@"log" onObject:obj withArgCount:1 toState:L];
  
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
