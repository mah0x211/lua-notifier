-- create class
local Notifier = require('../notifier');
local notifier = Notifier.new();
local unpack = unpack or table.unpack;

local invoked = {
    hello = {
        count = 0
    },
    hello2 = {
        count = 0
    },
    world = {
        count = 0
    }
};

local function update( tbl, ctx, ... )
    tbl.count = tbl.count + 1;
    tbl.ctx = ctx;
    tbl.args = {...};
end

local function cbHello( ... )
    update( invoked.hello, ... );
end

local function cbHello2( ... )
    update( invoked.hello2, ... );
end

local function cbWorld( ... )
    update( invoked.world, ... );
end


-- invalid arguments
for _, arg in ipairs({
    {},
    { 1 },
    { 'hello', '' },
    { 'hello', cbHello, {}, '' },
    { 'hello', cbHello, {}, -1 }
}) do
    ifTrue(isolate(function()
        notifier:on( unpack( arg ) );
    end));
end

-- add observers
notifier
:on('hello', cbHello, 'hello context')
:on('hello', cbHello2, 'hello context');

-- notify
notifier:notify('hello');
ifNotEqual( invoked.hello.ctx, 'hello context' );
ifNotEqual( invoked.hello.count, 1 );


-- notify with arguments
local args = { 'a', 'b', 'c' };
local args2 = { 'x', 'y', 'z' };
ifNotEqual( { notifier:notify('hello', unpack( args ) ) }, { 2, 0 } );
ifNotEqual( invoked.hello.ctx, 'hello context' );
ifNotEqual( invoked.hello.count, 2 );
ifNotEqual( invoked.hello.args, args );
ifNotEqual( invoked.hello, invoked.hello2 );


-- remove cbHello
notifier:off('hello', cbHello );
ifNotEqual( { notifier:notify('hello', unpack( args2 ) ) }, { 1, 0 } );
ifNotEqual( invoked.hello.ctx, 'hello context' );
ifNotEqual( invoked.hello.count, 2 );
ifNotEqual( invoked.hello.args, args );
-- hello2 still alive
ifNotEqual( invoked.hello2.ctx, 'hello context' );
ifNotEqual( invoked.hello2.count, 3 );
ifNotEqual( invoked.hello2.args, args2 );

-- remove all 'hello' observer
notifier:off('hello');
ifNotEqual( { notifier:notify('hello', unpack( args ) ) }, { 0, 0 } );
ifNotEqual( invoked.hello.ctx, 'hello context' );
ifNotEqual( invoked.hello.count, 2 );
ifNotEqual( invoked.hello.args, args );
ifNotEqual( invoked.hello2.ctx, 'hello context' );
ifNotEqual( invoked.hello2.count, 3 );
ifNotEqual( invoked.hello2.args, args2 );


-- remove observer automatically if called 2 times
notifier:on('world', cbWorld, 'world context', 2);
notifier:notify('world', unpack( args ) );
ifNotEqual( { notifier:notify('world', unpack( args ) ) }, { 1, 1 } );
ifNotEqual( invoked.world.ctx, 'world context' );
ifNotEqual( invoked.world.count, 2 );
ifNotEqual( invoked.world.args, args );

notifier:notify('world', unpack( args2 ) );
ifNotEqual( invoked.world.ctx, 'world context' );
ifNotEqual( invoked.world.count, 2 );
ifNotEqual( invoked.world.args, args );

