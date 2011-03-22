print ( 'Hi from Lua' )

print ( "Starting lua " .. tostring(_G.LuaShotViewController) )
for n,v in pairs(_G.LuaShotViewController) do
  print (n,v)
end

print ( "Globals" )
for n,v in pairs(_G) do
  print (n,v)
end

print ( "Controller: " .. tostring(controller) )
controller:log ( "hi" )


-- Make a test class
Test = {}
Test.__index = Test

function Test:log(msg)
print ( "calling log" )
DumpTable ( self )
self.controller:log ( msg )
end

function Test:llog(msg)
  print ( msg )
end

function Test.init(self)
self.foo = "foo"
print ( "Initialized!" )
self = setmetatable ( self, Test )
DumpTable(self)
return self
end


function DumpTable ( t )
  for k,v in pairs(t) do
    print ( tostring(k) .. ': ' .. tostring(v) )
  end
end

s = {}
t = Test.init ( s )
t:llog ( "Hi from lua to lua" )
DumpTable ( t )
DumpTable ( getmetatable ( t ) )