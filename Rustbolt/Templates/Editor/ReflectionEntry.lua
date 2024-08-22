---@class RustboltEditorReflectionEntryData
---@field Text string
---@field OnClick function
---@field Default? any
---@field LinkedEntity? RustboltObject
---@field LinkedCVar? string
---@field Children? table

RustboltEditorReflectionEntryMixin = {};

function RustboltEditorReflectionEntryMixin:OnLoad()
    Rustbolt.FrameUtil.AddFrameBorder(self);
end

function RustboltEditorReflectionEntryMixin:Init(data)
end