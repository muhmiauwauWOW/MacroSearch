MacroSearch = LibStub("AceAddon-3.0"):NewAddon("MacroSearch");
local _ = LibStub("LibLodash-1"):Get()


function MacroSearch:OnEnable()
	print("dddd")


	C_Timer.After(1, function() ShowMacroFrame(); end)

end


local addon1LoadedFrame = CreateFrame("Frame")
addon1LoadedFrame:RegisterEvent("ADDON_LOADED")
addon1LoadedFrame:SetScript("OnEvent", function(self, event, name, containsBindings)
	print(name, name == "Blizzard_MacroUI")
    if name == "Blizzard_MacroUI"then
		MacroSearch:init()
    end

	if event == "UPDATE_MACROS" then 
		print("UPDATE_MACROS")

	end
end)


filterdMacros = {}


function MacroSearch:init()
	print("init")

	local f = CreateFrame("EditBox", nil, MacroFrame, "MacroSearchSearchBarTemplate")
	f:SetPoint("TOPRIGHT", MacroFrame, "TOPRIGHT", -20, -28)
	f:Show()

	local offset = 20
	MacroFrame.MacroSelector:SetPoint("TOPLEFT", 12, -66 - offset)
	MacroFrame.MacroSelector:SetHeight(146 - offset)

	MacroFrame.Inset:SetPoint("TOPLEFT", 4, -60 - offset)
	MacroFrameTab1:SetPoint("TOPLEFT", 51, -28 - offset)


	C_Timer.After(1, function() MacroSearch:search("print") end)
	

	local function MacroFrameInitMacroButton(macroButton, selectionIndex, name, texture, body)
		if name ~= nil then
			--print("name",name)
			if type(name) == "table" then 
				print("in here", filterdMacros[macroButton.selectionIndex].fn[1])
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

function MacroSearch:search3(str)
	print("search", str)

	---if self.updateFN then self:reset() return end

	self.updateFN = MacroFrame.Update

	MacroFrame.Update = function() end



	for button in MacroFrame.MacroSelector:EnumerateButtons() do
		DevTool:AddData(button, "button")
		-- button:SetIconTexture(filterdMacros[button.selectionIndex][2]);
		local name = button.Name:GetText();

		local find = string.find(name, str) and true or false
		DevTool:AddData({name, find}, "name")
		if find then 
			button:Show();
		else
			button = nil
		end
	end


end



function MacroSearch:search(str)
	

	---if self.updateFN then self:reset() return end

	if string.len(str) == 0 then
		MacroFrame.Update = self.updateFN
		return 
	end

	filterdMacros = {}

	print("search", str)

	MacroFrame.Update = function() end

	local useAccountMacros = PanelTemplates_GetSelectedTab(MacroFrame) == 1;
	local numAccountMacros, numCharacterMacros = GetNumMacros();

	
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

	DevTool:AddData(macros, "macros")

	
	local filterd = _.filter(macros, function(macro)
		local find = string.find(macro.name, str)
		return find and (find > 0) or false
	end)


	


	_.forEach(filterd, function(macro)
		DevTools_Dump(macro.fn)
		table.insert(filterdMacros, macro)
	end)

	
	local function MacroFrameGetMacroInfo(selectionIndex)
		if string.len(str) == 0 then
			if selectionIndex > MacroFrame.MacroSelector.numMacros then
				return nil;
			end

			local actualIndex = self:GetMacroDataIndex(selectionIndex);
			return GetMacroInfo(actualIndex);
		end

		if selectionIndex > #filterdMacros then
			return nil;
		end


		return _.find(macros, function(macro)
			return macro.index == selectionIndex
		end)

		-- if not find then return end
		-- return find;
	end

	local function MacroFrameGetNumMacros()
		if string.len(str) == 0 then
			return useAccountMacros and MAX_ACCOUNT_MACROS or MAX_CHARACTER_MACROS;
		end
		return #filterdMacros
	end


	DevTool:AddData({GetMacroInfo(1)}, "GetMacroInfo")
	MacroFrame.MacroSelector:SetSelectionsDataProvider(MacroFrameGetMacroInfo, MacroFrameGetNumMacros);
	-- MacroFrame.MacroSelector:UpdateAllSelectedTextures()
	-- DevTool:AddData(MacroFrameGetMacroInfo(2), "?")
	
	-- MacroFrame.MacroSelector.setupCallback()

	local function MacroFrameInitMacroButton(macroButton, selectionIndex, name, texture, body)
		print(selectionIndex, name, texture, body)
		if name ~= nil then
			macroButton:SetIconTexture(texture);
			macroButton.Name:SetText(name);
			macroButton:Enable();
		else
			macroButton:SetIconTexture("");
			macroButton.Name:SetText("");
			macroButton:Disable();
		end
	end

	

	 for button in MacroFrame.MacroSelector:EnumerateButtons() do
		
		if string.len(str) == 0 then
	-- 		local name, icon =  GetMacroInfo(button.selectionIndex)
	-- 		if name ~= nil then
	-- 			button:SetIconTexture(icon);
	-- 			button.Name:SetText(name);
	-- 			button:Enable();
	-- 		else
	-- 			button:SetIconTexture("");
	-- 			button.Name:SetText("");
	-- 			button:Disable();
	-- 		end
	 	else
	-- 		DevTool:AddData(button, "button")
	-- 		button:SetIconTexture(filterdMacros[button.selectionIndex].fn[2]);
	-- 		button.Name:SetText(filterdMacros[button.selectionIndex].fn[1]);
			-- button:SetSelectionIndex(filterdMacros[button.selectionIndex].index)
		end

		
	-- 	-- macroButton:Enable();
	end

	MacroFrame:UpdateButtons();
end

function MacroSearch:reset(str)

	print("reset")
	MacroFrame:Update()
end










MacroSearchSearchBarMixin = {}

function MacroSearchSearchBarMixin:OnLoad()
	SearchBoxTemplate_OnLoad(self);
	self.clearButton:HookScript("OnClick", function(btn)
		MacroSearch:search("")
		MacroSearch:reset()
		SearchBoxTemplateClearButton_OnClick(btn);
	end)
end

function MacroSearchSearchBarMixin:OnEnterPressed()
	EditBox_ClearFocus(self);
	local text = self:GetText();
    local length = string.len(text);
    if length == 0 then
		MacroSearch:search("")
	else
		MacroSearch:search(self:GetText())
	end
	

end
