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
local isString = require('util.is').string;
local isFunction = require('util.is').Function;
local isTable = require('util.is').table;
local isUInt = require('util.is').uint;

-- class
local Notifier = require('halo').class.Notifier;


--- init
function Notifier:init()
    self.notification = {};
    self.nobservers = {};
    return self;
end

--- get number of observers
function Notifier:getnobs( name )
    if not isString( name ) then
        error( 'name must be type of string' );
    end

    return self.nobservers[name] or 0;
end



local function addobserver( self, name, callback, obs )
    local observers = self.notification[name];

    -- create observers[name] table
    if not isTable( observers ) then
        observers = setmetatable({
            [callback] = obs
        },{
            __mode = 'k'
        });
        self.notification[name] = observers;
    -- add observer
    else
        observers[callback] = obs;
    end
end


--- observe notification
function Notifier:on( name, callback, ctx, count )
    local obs;

    if not isString( name ) then
        error( 'name must be type of string' );
    elseif not isFunction( callback ) then
        error( 'callback must be type of function' );
    elseif count ~= nil and not isUInt( count ) then
        error( 'count must be uint' );
    -- increment number of observers
    elseif not self.nobservers[name] then
        self.nobservers[name] = 1;
    else
        self.nobservers[name] = self.nobservers[name] + 1;
    end

    -- create observer
    obs = {
        ctx = ctx,
        count = count or 0
    };

    -- add to changelist
    if self.changelist then
        self.changelist[#self.changelist + 1] = {
            proc = addobserver,
            name = name,
            callback = callback,
            obs = obs
        };
    -- add to observers
    else
        addobserver( self, name, callback, obs );
    end

    return self;
end


--- unobserve notification
local function delobserver( self, name, callback )
    local observers = self.notification[name];

    if isTable( observers ) then
        -- remove all observers
        if callback == nil then
            self.notification[name] = nil;
            self.nobservers[name] = nil;
        -- invalid type of callback
        elseif not isFunction( callback ) then
            error( 'callback must be type of function' );
        -- remove observer associated with callback
        elseif observers[callback] then
            observers[callback] = nil;

            -- remove empty-observers from notification container
            if self.nobservers[name] == 0 then
                self.notification[name] = nil;
                self.nobservers[name] = nil;
            end
        end
    end
end


function Notifier:off( name, callback )
    local nobservers = self.nobservers;

    if nobservers[name] and nobservers[name] > 0 then
        -- decrement number of observers
        nobservers[name] = nobservers[name] - 1;

        if self.changelist then
            self.changelist[#self.changelist + 1] = {
                proc = delobserver,
                name = name,
                callback = callback
            };
        else
            delobserver( self, name, callback );
        end
    end

    return self;
end


--- invoke notification
function Notifier:notify( name, ... )
    local observers = self.notification[name];
    local notified = 0;
    local removed = 0;

    if isTable( observers ) then
        local changelist = {};
        local item;

        -- set changelist reference
        self.changelist = changelist;

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
        self.changelist = nil;

        -- apply changelist
        for i = 1, #changelist do
            item = changelist[i];
            -- increment remove count
            if item.proc == delobserver then
                removed = removed + 1;
            end

            item.proc( self, item.name, item.callback, item.obs );
        end
    end

    return notified, removed;
end


return Notifier.exports;
