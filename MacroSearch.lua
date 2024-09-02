local _ = LibStub("LibLodash-1"):Get()

MacroSearchMixin = {}

function MacroSearchMixin:OnLoad()
	self.filterdMacros = {}
	self.updateFN = MacroFrame.Update
	local offset = 24
	

	local function getMacroType()
		return PanelTemplates_GetSelectedTab(MacroFrame) == 1 and "account" or "char"
	end

	self.macroType = getMacroType()
	local tabFn = function()
		self.macroType = getMacroType()
		self:reset()
	end
	local function MacroFrameInitMacroButton(macroButton, selectionIndex, name, texture, body)
		if name ~= nil then
			local nname = name
			if type(name) == "table" then
				nname = self.filterdMacros[macroButton.selectionIndex].info[1]
				texture = self.filterdMacros[macroButton.selectionIndex].info[2]
				local nindex = self.filterdMacros[macroButton.selectionIndex].index
				macroButton:SetSelectionIndex(nindex)
			end

			macroButton:SetIconTexture(texture);
			macroButton.Name:SetText(nname);
			macroButton:Enable();
		else
			macroButton:SetIconTexture("");
			macroButton.Name:SetText("");
			macroButton:Disable();
		end
	end

	local function getMacroData(max, base)
		local values = {}
		for i = 1, max, 1 do
			local mi = { GetMacroInfo(base + i) }
			if(mi[2]) then 
				table.insert(values, { index = i, info = mi })
			end
		end
		return values
	end

	local accountMacros = getMacroData(MAX_ACCOUNT_MACROS, 0)
	local charMacros = getMacroData(MAX_CHARACTER_MACROS, MAX_ACCOUNT_MACROS)

	self.macros = {
		account = accountMacros,
		char = charMacros
	}

	MacroFrame.MacroSelector:SetPoint("TOPLEFT", 12, -66 - offset)
	MacroHorizontalBarLeft:SetPoint("TOPLEFT", 2, -210 - offset)
	MacroFrameSelectedMacroBackground:SetPoint("TOPLEFT", 5, -218 - offset)
	MacroFrameTextBackground:SetPoint("TOPLEFT", 6, -289 - offset)

	MacroFrame:SetHeight(MacroFrame:GetHeight() + offset)

	MacroSearchNoSearchResultsText:SetAllPoints(MacroFrame.MacroSelector.ScrollBox)


	MacroFrameTab1:HookScript("OnClick", tabFn)
	MacroFrameTab2:HookScript("OnClick", tabFn)
	MacroFrame.MacroSelector:SetSetupCallback(MacroFrameInitMacroButton);
end

function MacroSearchMixin:OnHide()
	self:reset()
end

function MacroSearchMixin:search(str)
	MacroFrame.Update = function() end

	local macros = self.macros[self.macroType]
	
	self.filterdMacros = _.filter(macros, function(macro)
		local find = string.find(string.lower(macro.info[1]), string.lower(str))
		return find and (find > 0)
	end)

	local function MacroFrameGetMacroInfo(selectionIndex)
		return self.filterdMacros[selectionIndex]
	end

	local function MacroFrameGetNumMacros()
		return #self.filterdMacros
	end

	MacroFrame.MacroSelector:SetSelectionsDataProvider(MacroFrameGetMacroInfo, MacroFrameGetNumMacros);

	if MacroFrameGetNumMacros() == 0 then 
		MacroSearchNoSearchResultsText:Show()
	else
		MacroSearchNoSearchResultsText:Hide()
	end

	MacroFrame:UpdateButtons();
end

function MacroSearchMixin:reset()
	MacroFrame.Update = self.updateFN
	MacroFrame:Update()
	self.SearchBar:Reset()
end


MacroSearchSearchBarMixin = {}

function MacroSearchSearchBarMixin:OnLoad()
	SearchBoxTemplate_OnLoad(self);
	self.clearButton:HookScript("OnClick", function(btn)
		self:GetParent():reset()
		SearchBoxTemplateClearButton_OnClick(btn);
	end)
end
function MacroSearchSearchBarMixin:search(text)
    if string.len(text) == 0 then
		self:GetParent():reset()
	else
		self:GetParent():search(text)
	end
end

function MacroSearchSearchBarMixin:OnEnterPressed()
	EditBox_ClearFocus(self);
	self:search(self:GetText())
end

function MacroSearchSearchBarMixin:OnKeyUp()
	self:search(self:GetText())
end

function MacroSearchSearchBarMixin:Reset()
	self:SetText("");
end