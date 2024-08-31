MacroSearch = LibStub("AceAddon-3.0"):NewAddon("MacroSearch");
local _ = LibStub("LibLodash-1"):Get()


function MacroSearch:OnEnable()
	--C_Timer.After(1, function() ShowMacroFrame(); end)
end


local addon1LoadedFrame = CreateFrame("Frame")
addon1LoadedFrame:RegisterEvent("ADDON_LOADED")
addon1LoadedFrame:SetScript("OnEvent", function(self, event, name, containsBindings)
    if name == "Blizzard_MacroUI"then
		MacroSearch:init()
    end
end)


filterdMacros = {}




function MacroSearch:init()
	self.SeachBar = CreateFrame("EditBox", nil, MacroFrame, "MacroSearchSearchBarTemplate")
	self.SeachBar:SetPoint("TOPRIGHT", MacroFrame, "TOPRIGHT", -20, -28)
	self.SeachBar:Show()

	local offset = 20
	MacroFrame.MacroSelector:SetPoint("TOPLEFT", 12, -66 - offset)
	MacroFrame.MacroSelector:SetHeight(146 - offset)

	MacroFrame.Inset:SetPoint("TOPLEFT", 4, -60 - offset)
	MacroFrameTab1:SetPoint("TOPLEFT", 51, -28 - offset)

	local tabFn = function()
		MacroSearch:reset()
	end

	MacroFrameTab1:HookScript("OnClick", tabFn)
	MacroFrameTab2:HookScript("OnClick", tabFn)


	local function MacroFrameInitMacroButton(macroButton, selectionIndex, name, texture, body)
		if name ~= nil then
			if type(name) == "table" then 
				macroButton:SetIconTexture(filterdMacros[macroButton.selectionIndex].fn[2]);
		 		macroButton.Name:SetText(filterdMacros[macroButton.selectionIndex].fn[1]);
				macroButton:Enable();
				macroButton:SetSelectionIndex(filterdMacros[macroButton.selectionIndex].index)
			else
				macroButton:SetIconTexture(texture);
				macroButton.Name:SetText(name);
				macroButton:Enable();
			end
			
		else
			macroButton:SetIconTexture("");
			macroButton.Name:SetText("");
			macroButton:Disable();
		end
	end

	MacroFrame.MacroSelector:SetSetupCallback(MacroFrameInitMacroButton);
	self.updateFN = MacroFrame.Update
end

function MacroSearch:search(str)
	if string.len(str) == 0 then
		MacroFrame.Update = self.updateFN
		return 
	end

	filterdMacros = {}
	MacroFrame.Update = function() end

	
	local function getMacroData()
		local values = {}
		local i = 0
		local name, icon

		repeat
			i = i + 1
			name, icon = GetMacroInfo(i)
			if(name) then 
				table.insert(values,  {
					index = i,
					name = name,
					fn =  {GetMacroInfo(i)}
				})
			end
		until(icon == nil)

		return values
	end

	local macros = getMacroData()


	_.forEach(macros, function(macro)
		local find = string.find(string. lower(macro.name), string. lower(str))
		if find and (find > 0) then 
			table.insert(filterdMacros, macro)
		end
	end)

	local function MacroFrameGetMacroInfo(selectionIndex)
		return _.find(macros, function(macro)
			return macro.index == selectionIndex
		end)
	end

	local function MacroFrameGetNumMacros()
		return #filterdMacros
	end

	MacroFrame.MacroSelector:SetSelectionsDataProvider(MacroFrameGetMacroInfo, MacroFrameGetNumMacros);
	MacroFrame:UpdateButtons();
end

function MacroSearch:reset()
	MacroFrame.Update = self.updateFN
	MacroFrame:Update()
	MacroSearch.SeachBar:Reset()
end




MacroSearchSearchBarMixin = {}

function MacroSearchSearchBarMixin:OnLoad()
	SearchBoxTemplate_OnLoad(self);
	self.clearButton:HookScript("OnClick", function(btn)
		MacroSearch:reset()
		SearchBoxTemplateClearButton_OnClick(btn);
	end)
end

function MacroSearchSearchBarMixin:OnEnterPressed()
	EditBox_ClearFocus(self);
	local text = self:GetText();
    local length = string.len(text);
    if length == 0 then
		MacroSearch:reset()
	else
		MacroSearch:search(self:GetText())
	end
end

function MacroSearchSearchBarMixin:Reset()
	self:SetText("");
end