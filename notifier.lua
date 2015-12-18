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
        notification = {},
        nobservers = {}
    }
};


--- get number of observers
function Notifier:getnobs( name )
    local nobs = protected(self).nobservers[name];

    if not isString( name ) then
        error( 'name must be type of string' );
    end

    return nobs or 0;
end


--- observe notification
function Notifier:on( name, callback, ctx, count )
    local own = protected(self);
    local nobservers = own.nobservers;
    local notification = own.notification;
    local observers = notification[name];
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
        notification[name] = observers;
        nobservers[name] = 0;
    end
    
    -- add observer
    observers[callback] = {
        ctx = ctx,
        count = count or 0
    };
    -- increment number of observers
    nobservers[name] = nobservers[name] + 1;

    return self;
end


--- unobserve notification
function Notifier:off( name, callback )
    local own = protected(self);
    local nobservers = own.nobservers;
    local notification = own.notification;
    local observers = notification[name];

    if isTable( observers ) then
        -- remove all observers
        if callback == nil then
            notification[name] = nil;
            nobservers[name] = nil;
        -- invalid type of callback
        elseif not isFunction( callback ) then
            error( 'callback must be type of function' );
        -- remove observer associated with callback
        elseif observers[callback] then
            observers[callback] = nil;

            -- decrement number of observers
            if nobservers[name] > 1 then
                nobservers[name] = nobservers[name] - 1;
            -- remove empty-observers from notification container
            else
                notification[name] = nil;
                nobservers[name] = nil;
            end
        end
    end
    
    return self;
end


-- invoke notification
function Notifier:notify( name, ... )
    local own = protected(self);
    local nobservers = own.nobservers;
    local notification = own.notification;
    local observers = notification[name];
    local notified = 0;
    local removed = 0;
    
    if isTable( observers ) then
        local offlist = {};
        local cb;

        -- notify
        for callback, obs in pairs( observers ) do
            callback( obs.ctx, ... );
            notified = notified + 1;
            -- has call counter
            if obs.count > 0 then
                obs.count = obs.count - 1;
                -- register a callback into the offlist if reached to 0
                if obs.count == 0 then
                    offlist[#offlist + 1] = callback;
                    nobservers[name] = nobservers[name] - 1;
                end
            end
        end
        
        -- remove callback functions
        removed = #offlist;
        for i = 1, #offlist do
            cb = offlist[i];
            if observers[cb] then
                observers[cb] = nil;
            end
        end

        -- remove empty-observers from notification container
        if nobservers[name] < 1 then
            notification[name] = nil;
        end
    end
    
    return notified, removed;
end


return Notifier.exports;
