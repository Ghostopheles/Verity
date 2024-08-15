local MAX_BUTTONS_PER_SIDE = 8;
local DEFAULT_TEXT = "$uwu$";

local BUTTON_SCRIPTS = {
    "OnClick",
    "OnEnter",
    "OnLeave"
};

RustboltBasementMixin = {};

---@enum RustboltBasementSide
RustboltBasementMixin.Side = {
    LEFT = 1,
    RIGHT = 2
};
local SIDE = RustboltBasementMixin.Side;

local DEFAULT_BUTTON_TEMPLATE = "RustboltBasementButtonTemplate";

function RustboltBasementMixin:OnLoad()
    self.Buttons = {
        [SIDE.LEFT] = {},
        [SIDE.RIGHT] = {},
    };

    local stride = MAX_BUTTONS_PER_SIDE;
    local paddingX = 0;
    local paddingY = 0;
    local horizontalSpacing = 4;
    local verticalSpacing = 0;

    self.Layouts = {
        [SIDE.LEFT] = AnchorUtil.CreateGridLayout(GridLayoutMixin.Direction.LeftToRight, stride, paddingX, paddingY, horizontalSpacing, verticalSpacing),
        [SIDE.RIGHT] = AnchorUtil.CreateGridLayout(GridLayoutMixin.Direction.RightToLeft, stride, paddingX, paddingY, horizontalSpacing, verticalSpacing),
    };

    self.InitialAnchors = {
        [SIDE.LEFT] = AnchorUtil.CreateAnchor("LEFT", self.ContainerLeft, "LEFT", 0, 0),
        [SIDE.RIGHT] = AnchorUtil.CreateAnchor("RIGHT", self.ContainerRight, "RIGHT", 0, 0),
    };

    local function ResetButton(_, button)
        for _, script in ipairs(BUTTON_SCRIPTS) do
            button:SetScript(script, nil);
        end
    end

    local function InitButton(button)
    end

    self.Pools = {
        [SIDE.LEFT] = CreateFramePool("Button", self.ContainerLeft, DEFAULT_BUTTON_TEMPLATE, ResetButton, false, InitButton, MAX_BUTTONS_PER_SIDE),
        [SIDE.RIGHT] = CreateFramePool("Button", self.ContainerRight, DEFAULT_BUTTON_TEMPLATE, ResetButton, false, InitButton, MAX_BUTTONS_PER_SIDE),
    };

    self.IDToButton = {};
end

function RustboltBasementMixin:OnShow()
end

function RustboltBasementMixin:OnHide()
end

------------

---@class RustboltBasementButtonConfig
---@field Side RustboltBasementSide
---@field IconAtlas string
---@field Text string
---@field ID string
---@field OnClick function
---@field OnEnter? function
---@field OnLeave? function

---@param buttonConfig RustboltBasementButtonConfig
function RustboltBasementMixin:AddButton(buttonConfig)
    local side = buttonConfig.Side;

    local button = self.Pools[side]:Acquire();
    if not button then
        return false;
    end

    button:SetText(buttonConfig.Text or DEFAULT_TEXT);

    for _, script in ipairs(BUTTON_SCRIPTS) do
        button:SetScript(script, buttonConfig[script]);
    end

    tinsert(self.Buttons[side], button);

    self:Layout();
    return button;
end

function RustboltBasementMixin:Layout()
    for side, layout in ipairs(self.Layouts) do
        local InitialAnchor = self.InitialAnchors[side];
        AnchorUtil.ChainLayout(self.Buttons[side], InitialAnchor, layout);
    end
end

function RustboltBasementMixin:GetButtonByID(id)
    return self.IDToButton[id];
end