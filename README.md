lua-notifier
=======

event notification module.

---

## Dependencies

- halo: https://github.com/mah0x211/lua-halo

## Installation

```sh
luarocks install notifier --from=http://mah0x211.github.io/rocks/
```


## Create new notifier object

### notifier = Notifier.new()

**Returns**

1. `notifier:table`: an instance of notifier.


## Methods

### Register an event notification observer

#### notifier = notifier:on( name:string, callback:function [, ctx:any [, count:uint] ] )

**Parameters**

- `name:string`: event name.
- `callback:function`: callback function.
- `ctx:any`: any context value that passing to first argument of callback function on invocation. (default: `nil`)
- `count:uint`: number of notification. if notification count reached to this value, an observer will be removed automatically. (default: `0`)

**Returns**

1. `notifier:table`: an instance of notifier.


### Get a number of notification observers 

#### nobs = notifier:getnobs( name:string )

**Parameters**

- `name:string`: event name.

**Returns**

1. `nobs:uint`: number of notification observers


### Unregister an event notification observer

#### notifier = notifier:off( name:string, callback:function )

unregister an event notification observer.

**Parameters**

- `name:string`: event name.
- `callback:function`: callback function.

**Returns**

1. `notifier:table`: an instance of notifier.


### Notify event to event observers.

#### notified, removed = notifier:notify( name:string [, ...] )

**Parameters**

- `name:string`: event name.
- `...`: passed arguments of observers.

**Returns**

1. `notified:number`: number of notified observer.
2. `removed:number`: number of removed observer.


## Usage

```lua
local Notifier = require('notifier');
local notifier = Notifier.new();

local function cbHello( ctx, ... )
    print( ctx, ... );
end

local function cbWorld( ctx, ... )
    print( ctx, ... );
end

local notified, removed;

-- register
notifier
:on( 'hello', cbHello, 'hello context' )
:on( 'world', cbWorld, 'world context', 1 );

-- notify
notified, removed = notifier:notify('hello');
print( notified, removed );

-- notify with arguments
notified, removed = notifier:notify('world', 'a', 'b', 1, 2 );
print( notified, removed );

-- unregister
notifier:off( 'hello', cbHello );
```
