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

function Test.init(self)
  self.foo = "foo"
  print ( "Initialized!" )
  return self
end

function Test:log(msg)
  self.controller:log ( msg )
end
