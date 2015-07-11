--[[
  
  Copyright (C) 2015 Masatoshi Teruya
 
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
 
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
 
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
  
  
  notifier.lua
  lua-notifier
  Created by Masatoshi Teruya on 15/07/11.
  
--]]

-- modules
local inspect = require('util').inspect;
local isString = require('util.typeof').string;
local isFunction = require('util.typeof').Function;
local isTable = require('util.typeof').table;
local isUInt = require('util.typeof').uint;
-- class
local Notifier = require('halo').class.Notifier;

Notifier:property {
    protected = {
        notification = {}
    }
};

--- observe notification
function Notifier:on( name, callback, ctx, count )
    local own = protected(self);
    local observers = own.notification[name];
    local idx;
    
    if not isString( name ) then
        error( 'name must be type of string' );
    elseif not isFunction( callback ) then
        error( 'callback must be type of function' );
    elseif count ~= nil and not isUInt( count ) then
        error( 'count must be uint' );
    -- create observers[name] table
    elseif not isTable( observers ) then
        observers = setmetatable( {}, { __mode = 'k' } );
        own.notification[name] = observers;
    end
    
    -- add observer
    observers[callback] = {
        ctx = ctx,
        count = count or 0
    };
    
    return self;
end


--- unobserve notification
function Notifier:off( name, callback )
    local own = protected(self);
    local observers = own.notification[name];
    
    if isTable( observers ) then
        -- remove all observers
        if callback == nil then
            own.notification[name] = nil;
        -- remove observer associated with callback
        elseif isFunction( callback ) then
            observers[callback] = nil;
        else
            error( 'callback must be type of function' );
        end
    end
    
    return self;
end


-- invoke notification
function Notifier:notify( name, ... )
    local observers = protected(self).notification[name];
    local notified = 0;
    local removed = 0;
    
    if isTable( observers ) then
        local offlist = {};
        
        for callback, obs in pairs( observers ) do
            callback( obs.ctx, ... );
            notified = notified + 1;
            -- register callback into offlist if ncount value is less than 1
            if obs.count > 0 then
                obs.count = obs.count - 1;
                if obs.count == 0 then
                    offlist[#offlist + 1] = callback;
                end
            end
        end
        
        -- remove callback functions
        removed = #offlist;
        if removed > 0 then
            for _, callback in ipairs( offlist ) do
                observers[callback] = nil;
            end
        end
    end
    
    return notified, removed;
end


return Notifier.exports;
