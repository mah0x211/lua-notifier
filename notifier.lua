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
local isString = require('util.is').string;
local isFunction = require('util.is').Function;
local isTable = require('util.is').table;
local isUInt = require('util.is').uint;

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



local function addobserver( own, name, callback, obs )
    local notification = own.notification;
    local observers = notification[name];

    -- create observers[name] table
    if not isTable( observers ) then
        observers = setmetatable({
            [callback] = obs
        },{
            __mode = 'k'
        });
        notification[name] = observers;
    -- add observer
    else
        observers[callback] = obs;
    end
end


--- observe notification
function Notifier:on( name, callback, ctx, count )
    local own = protected(self);
    local nobservers = own.nobservers;
    local obs;
    
    if not isString( name ) then
        error( 'name must be type of string' );
    elseif not isFunction( callback ) then
        error( 'callback must be type of function' );
    elseif count ~= nil and not isUInt( count ) then
        error( 'count must be uint' );
    -- increment number of observers
    elseif not nobservers[name] then
        nobservers[name] = 1;
    else
        nobservers[name] = nobservers[name] + 1;
    end

    -- create observer
    obs = {
        ctx = ctx,
        count = count or 0
    };

    -- add to changelist
    if own.changelist then
        own.changelist[#own.changelist + 1] = {
            proc = addobserver,
            name = name,
            callback = callback,
            obs = obs
        };
    -- add to observers
    else
        addobserver( own, name, callback, obs );
    end

    return self;
end


--- unobserve notification
function delobserver( own, name, callback )
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

            -- remove empty-observers from notification container
            if nobservers[name] == 0 then
                notification[name] = nil;
                nobservers[name] = nil;
            end
        end
    end
end


function Notifier:off( name, callback )
    local own = protected(self);
    local nobservers = own.nobservers;

    if nobservers[name] and nobservers[name] > 0 then
        -- decrement number of observers
        nobservers[name] = nobservers[name] - 1;

        if own.changelist then
            own.changelist[#own.changelist + 1] = {
                proc = delobserver,
                name = name,
                callback = callback
            };
        else
            delobserver( own, name, callback );
        end
    end

    return self;
end


-- invoke notification
function Notifier:notify( name, ... )
    local own = protected(self);
    local notification = own.notification;
    local observers = notification[name];
    local notified = 0;
    local removed = 0;
    
    if isTable( observers ) then
        local changelist = {};
        local item;

        -- set changelist reference
        own.changelist = changelist;

        -- notify
        for callback, obs in pairs( observers ) do
            -- has call counter
            if obs.count > 0 then
                obs.count = obs.count - 1;
                -- add callback into the changelist if reached to 0
                if obs.count == 0 then
                    self:off( name, callback );
                end
            end

            notified = notified + 1;
            callback( obs.ctx, ... );
        end

        -- remove changelist reference
        own.changelist = nil;

        -- apply changelist
        for i = 1, #changelist do
            item = changelist[i];
            -- increment remove count
            if item.proc == delobserver then
                removed = removed + 1;
            end

            item.proc( own, item.name, item.callback, item.obs );
        end
    end
    
    return notified, removed;
end


return Notifier.exports;
