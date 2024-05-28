local SCREENS_ALL = "all";
local DOUBLE_TAP_TIMEOUT = Verity.Constants.Input.DoubleTapTimeout;

---@class VerityInputContext
local InputContextBase = {
    OnUp = false,
    Hold = false,
    DoubleTap = false,
    Screens = {},
    Gate = nil,
};

function InputContextBase:Init(onUp, hold, doubleTap, screens, gate)
    self.OnUp = onUp or false;
    self.Hold = hold or false;
    self.DoubleTap = doubleTap or false;
    self.Screens = screens or SCREENS_ALL;
    self.Gate = gate or nil;
end

------------

---@class VerityInputListener
local InputListenerBase = {
    Context = InputContextBase,
    Callback = function() end,
    Owner = nil,
};

function InputListenerBase:Init(context, callback, owner)
    self.Context = context;
    self.Callback = callback;
    self.Owner = owner;
end

------------

---@class VerityInputManager
---@field Keys table<string, table<VerityInputListener>>
local InputManager = {
    Keys = {},
    HandlingKeyDown = false,
    HandlingKeyUp = false,
    LastKey = nil,
};

---@param onUp? boolean
---@param hold? boolean
---@param doubleTap? boolean
---@param screens? table | string
---@return VerityInputContext
function InputManager:CreateInputContext(onUp, hold, doubleTap, screens, func)
    return CreateAndInitFromMixin(InputContextBase, onUp, hold, doubleTap, screens, func);
end

---@param context VerityInputContext
---@param callback function
---@param owner table
---@return VerityInputListener
function InputManager:CreateInputListener(context, callback, owner)
    return CreateAndInitFromMixin(InputListenerBase, context, callback, owner);
end

--- Creates and registers an input listener
---@param key string
---@param callback function
---@param owner table
---@param context? VerityInputContext | string | function
---@return VerityInputListener
function InputManager:RegisterInputListener(key, callback, owner, context)
    if not self.Keys[key] then
        self.Keys[key] = {};
    end

    if type(context) == "string" then
        local screens = context ~= SCREENS_ALL and {[context] = true} or SCREENS_ALL;
        context = self:CreateInputContext(nil, nil, nil, screens);
    elseif type(context) == "function" then
        context = self:CreateInputContext(nil, nil, nil, nil, context);
    end

    if not context then
        context = self:CreateInputContext();
    end

    local listener = self:CreateInputListener(context, callback, owner);
    tinsert(self.Keys[key], listener);

    return listener;
end

function InputManager:HandleInputError(key, message)
    print("Error handling input for key '" .. key .. "'\n" .. message);
end

function InputManager:ShouldPropagateKey(key)
    return not self.Keys[key];
end

function InputManager:SetLastKey(key)
    self.LastKey = key;

    self.KeyTimeout = false;
    local callback = C_FunctionContainers.CreateCallback(function() self.KeyTimeout = true; end);

    C_Timer.After(DOUBLE_TAP_TIMEOUT, callback);
end

function InputManager:ClearLastKey()
    self.LastKey = nil;
end

function InputManager:IsDoubleTap(key)
    return key == self.LastKey and not self.KeyTimeout;
end

--- Evaluates a context against the current input state
---@param context VerityInputContext
---@param keyUp? boolean
---@return boolean success
function InputManager:EvaluateContext(context, key, keyUp)
    local currentScreen = VerityGameWindow:GetScreen().Name;
    if context.Screens ~= SCREENS_ALL and not context.Screens[currentScreen] then
        return false;
    end

    if context.OnUp and not keyUp then
        return false;
    end

    if context.Hold then
        return false; -- TODO: implement
    end

    if context.DoubleTap and not self:IsDoubleTap(key) then
        return false;
    end

    if context.Gate then
        local success, result = pcall(context.Gate);
        if not success then self:HandleInputError(key, result); end;
        return success;
    end

    return true;
end

function InputManager:OnKeyDown(key)
    self.HandlingKeyDown = true;

    local listeners = self.Keys[key];
    if not listeners then
        return false;
    end

    for _, listener in pairs(listeners) do
        local context = listener.Context;
        if self:EvaluateContext(context, key, false) then
            local success, result = pcall(listener.Callback, listener.Owner, key);
            print(success, result);
            if not success then self:HandleInputError(key, result); end;
        end
    end

    self:SetLastKey(key);
    self.HandlingKeyDown = false;
end

function InputManager:OnKeyUp(key)
    self.HandlingKeyUp = true;

    self.HandlingKeyUp = false;
end

------------

Verity.InputManager = InputManager;