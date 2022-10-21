-- ===========================================================================
-- Four_Seasons_UI
-- Author: sharpNd
-- 2022-05-10
-- ===========================================================================


-- ===========================================================================
-- Variable naming
-- Prefixes
-- b = boolean
-- f = float
-- i = integer
-- k = constant 
-- p = pointer (not in use here)
-- s = string
-- t = table
-- u = unknown

-- Suffixes
-- _UI = values that are set in the Gameplay script and called in the UI script
-- ===========================================================================


-- ===========================================================================
local kSeasonLength = GameConfiguration.GetValue("iSeasonLength");
-- Number of hours to skip per turn in the animated time of day feature. Float value.
local kHoursPerTurn = 24 / (kSeasonLength * 4);
local kMaxSeasonOffset_UI = Game:GetProperty("kMaxSeasonOffset_UI");
local kStartTurn = GameConfiguration.GetStartTurn();

-- no need to keep updated
local tRightContents;

-- keep updated with GameConfiguration.SetValue() at all times
local sToolTip;
local fCurrentHour;

-- these are kept updated in the Gameplay script with Game:SetProperty
local sNextTurnSeason_UI;
local iNewSeasonSeverity_UI;
local bSeasonChange_UI;
-- ===========================================================================


-- ===========================================================================
-- Adds the 4 Season Buttons to the right side of the top panel.
-- ===========================================================================
function AddSeasonButtons()
	tRightContents = ContextPtr:LookUpControl("/InGame/TopPanel/RightContents");
	
	if tRightContents ~= nil then
		-- adds the four season buttons and hides them
		AddButtonTo(Controls.SummerButton, tRightContents);
		AddButtonTo(Controls.AutumnButton, tRightContents);
		AddButtonTo(Controls.WinterButton, tRightContents);
		AddButtonTo(Controls.SpringButton, tRightContents);
	end
end


-- ===========================================================================
-- Check if the game just started or if it was loaded from a save file.
-- ===========================================================================
function CheckGameLoad()
	local iCurrentTurn = Game.GetCurrentGameTurn();
	
	-- new game started
	if iCurrentTurn == kStartTurn then
		if Controls.SummerButton ~= nil then
			Controls.SummerButton:SetHide(false);

			fCurrentHour = 12.00;
			GameConfiguration.SetValue("fCurrentHour", fCurrentHour);
			UI.SetAmbientTimeOfDay(fCurrentHour);
		end
		
	-- old game loaded
	else
		sNextTurnSeason_UI = Game:GetProperty("sNextTurnSeason_UI");
		
		if sNextTurnSeason_UI == "SUMMER" then
			Controls.SummerButton:SetHide(false);
			
		elseif sNextTurnSeason_UI == "AUTUMN" then
			Controls.AutumnButton:SetHide(false);
			
		elseif sNextTurnSeason_UI == "WINTER" then
			Controls.WinterButton:SetHide(false);
			
		elseif sNextTurnSeason_UI == "SPRING" then
			Controls.SpringButton:SetHide(false);
		end
		
		sToolTip = GameConfiguration.GetValue("sToolTip");
		SetToolTip(sNextTurnSeason_UI, sToolTip);

		fCurrentHour = GameConfiguration.GetValue("fCurrentHour");
		UI.SetAmbientTimeOfDay(fCurrentHour);
	end
end


-- ===========================================================================
-- Adds given button to given content / panel and hides it.
-- ===========================================================================
function AddButtonTo(uButton, tContent)
	uButton:ChangeParent(tContent);
	-- with 1000 the game will always put the buttons on the very left of the top right panel
	tContent:AddChildAtIndex(uButton, 1000);
	uButton:SetHide(true);
	tContent:CalculateSize();
	tContent:ReprocessAnchoring();
	uButton:RegisterCallback(Mouse.eMouseEnter, MouseOverButton);
end


-- ===========================================================================
-- Hide the last season button and show the current season button.
-- ===========================================================================
function UpdateFourSeasonsUI()
	local iCurrentTurn = Game.GetCurrentGameTurn();
	
	if iCurrentTurn == kStartTurn + 1 then
		iMinNextSeasonTurn = kStartTurn + kSeasonLength - kMaxSeasonOffset_UI;
		iMaxNextSeasonTurn = kStartTurn + kSeasonLength + kMaxSeasonOffset_UI;
		
		sToolTip = table.concat({"SUMMER - No Severity[NEWLINE][NEWLINE]No Effects[NEWLINE][NEWLINE]AUTUMN will have a Severity of 1 - 5 and start between [ICON_Turn]Turn ", iMinNextSeasonTurn, " - ", iMaxNextSeasonTurn});
		GameConfiguration.SetValue("sToolTip", sToolTip);
		
		sNextTurnSeason_UI = Game:GetProperty("sNextTurnSeason_UI");
		
		SetToolTip(sNextTurnSeason_UI, sToolTip);
	end
	
	bSeasonChange_UI = Game:GetProperty("bSeasonChange_UI");
	
	if bSeasonChange_UI then
		sNextTurnSeason_UI = Game:GetProperty("sNextTurnSeason_UI");
		
		if sNextTurnSeason_UI == "SUMMER" then
			Controls.SpringButton:SetHide(true);
			Controls.SummerButton:SetHide(false);
			
		elseif sNextTurnSeason_UI == "AUTUMN" then
			Controls.SummerButton:SetHide(true);
			Controls.AutumnButton:SetHide(false);
			
		elseif sNextTurnSeason_UI == "WINTER" then
			Controls.AutumnButton:SetHide(true);
			Controls.WinterButton:SetHide(false);
			
		elseif sNextTurnSeason_UI == "SPRING" then
			Controls.WinterButton:SetHide(true);
			Controls.SpringButton:SetHide(false);
		end
	end
	
	UpdateToolTipString();
	UpdateTimeOfDay();
end


-- ===========================================================================
-- Updates the button hover text with the current information.
-- ===========================================================================
function UpdateToolTipString()	
	bSeasonChange_UI = Game:GetProperty("bSeasonChange_UI");
	
	if bSeasonChange_UI then
		sNextTurnSeason_UI = Game:GetProperty("sNextTurnSeason_UI");
		
		if sNextTurnSeason_UI == "SUMMER" then
			sSeverityInfo = " - No Severity";
			sAllEffects = "No Effects[NEWLINE]";
		else
			iNewSeasonSeverity_UI = Game:GetProperty("iNewSeasonSeverity_UI");
			
			sSeverityInfo = GetCurrentSeverity(sNextTurnSeason_UI, iNewSeasonSeverity_UI);
			
			sUnitEffects = GetUnitEffects(sNextTurnSeason_UI, iNewSeasonSeverity_UI);
			sCityEffects = GetCityEffects(sNextTurnSeason_UI, iNewSeasonSeverity_UI);
			sPlayerEffects = GetPlayerEffects(sNextTurnSeason_UI, iNewSeasonSeverity_UI);
			
			sAllEffects = GetAllEffects(sUnitEffects, sCityEffects, sPlayerEffects);
		end
		
		sNextSeasonInfo = GetNextSeasonInfo(sNextTurnSeason_UI, iNewSeasonSeverity_UI);
		
		-- for some reason a concatenation with .. isn't allowed here
		sToolTip = table.concat({sNextTurnSeason_UI, sSeverityInfo, "[NEWLINE][NEWLINE]", sAllEffects, "[NEWLINE]", sNextSeasonInfo});
		-- Game:SetProperty isn't available in UI scripts but this works the same way
		GameConfiguration.SetValue("sToolTip", sToolTip);
		
		SetToolTip(sNextTurnSeason_UI, sToolTip);
	end
end


-- ===========================================================================
-- Updates animated time of day based on current turn and season.
-- SUMMER is around 12:00 to 18:00
-- AUTUMN is around 18:00 to 24:00
-- WINTER is around 00:00 to 06:00
-- SPRING is around 06:00 to 12:00
-- ===========================================================================
function UpdateTimeOfDay()
	fCurrentHour = math.fmod(fCurrentHour + kHoursPerTurn, 24.00);
	GameConfiguration.SetValue("fCurrentHour", fCurrentHour);
	UI.SetAmbientTimeOfDay(fCurrentHour);
end


-- ===========================================================================
-- Returns next season as a string.
-- ===========================================================================
function GetNextSeason(sSeason)
	if sSeason == "SUMMER" then
		return "AUTUMN";
			
	elseif sSeason == "AUTUMN" then
		return "WINTER";
		
	elseif sSeason == "WINTER" then
		return "SPRING";
		
	elseif sSeason == "SPRING" then
		return "SUMMER";
	end
end


-- ===========================================================================
-- Returns the lowest possible severity of the next season.
-- ===========================================================================
function GetMinSeverity(iSeverity)
	if iSeverity == 1 then
		return 1;
			
	elseif iSeverity == 2 then
		return 1;
			
	elseif iSeverity == 3 then
		return 1;
		
	elseif iSeverity == 4 then
		return 2;
		
	elseif iSeverity == 5 then
		return 3;
		
	elseif iSeverity == 6 then
		return 3;
	end
end


-- ===========================================================================
-- Returns the highest possible severity of the next season.
-- ===========================================================================
function GetMaxSeverity(iSeverity)
	if iSeverity == 1 then
		return 3;
			
	elseif iSeverity == 2 then
		return 4;
			
	elseif iSeverity == 3 then
		return 5;
		
	elseif iSeverity == 4 then
		if sNextTurnSeason_UI == "AUTUMN" then
			return 6;
		else
			return 5;
		end
		
	elseif iSeverity == 5 then
		if sNextTurnSeason_UI == "AUTUMN" then
			return 6;
		else
			return 5;
		end
		
	elseif iSeverity == 6 then
		return 5;
	end
end


-- ===========================================================================
-- Sets the button hover texts with the current information.
-- ===========================================================================
function SetToolTip(sSeason, sText)
	if sSeason == "SUMMER" then
		if Controls.SummerButton ~= nil then
			Controls.SummerButton:SetToolTipString(sText);
		end
			
	elseif sSeason == "AUTUMN" then
		if Controls.AutumnButton ~= nil then
			Controls.AutumnButton:SetToolTipString(sText);
		end
		
	elseif sSeason == "WINTER" then
		if Controls.WinterButton ~= nil then
			Controls.WinterButton:SetToolTipString(sText);
		end
		
	elseif sSeason == "SPRING" then
		if Controls.SpringButton ~= nil then
			Controls.SpringButton:SetToolTipString(sText);
		end
	end
end


-- ===========================================================================
-- Returns true if given table contains given value.
-- ===========================================================================
function TableHasValue(tTable, uValue)
	for _, uElement in pairs(tTable) do
		if uElement == uValue then
			return true;
		end
	end
	
	return false;
end


-- ===========================================================================
-- Returns current severity as a string.
-- ===========================================================================
function GetCurrentSeverity(sSeason, iSeverity)
	if sSeason == "WINTER" and TableHasValue({5, 6}, iSeverity) then
		return table.concat({" - Severity ", iSeverity, " [ICON_Exclamation]"});
	else
		return table.concat({" - Severity ", iSeverity});
	end
end


-- ===========================================================================
-- Returns current unit effects as a string.
-- ===========================================================================
function GetUnitEffects(sSeason, iSeverity)
	sHealingChange = GetHealingChange(sSeason, iSeverity);
	sMaintenanceChange = GetMaintenanceChange(sSeason, iSeverity);
	sMovementChange = GetMovementChange(sSeason, iSeverity);
	
	if sHealingChange == "" and sMaintenanceChange == "" and sMovementChange == "" then
		return "";
	else
		return table.concat({"UNITS", "[NEWLINE]", sHealingChange, sMaintenanceChange, sMovementChange});
	end
end


-- ===========================================================================
-- Returns current city effects as a string.
-- ===========================================================================
function GetCityEffects(sSeason, iSeverity)
	sFoodYieldChange = GetFoodYieldChange(sSeason, iSeverity);
	sProductionYieldChange = GetProductionYieldChange(sSeason, iSeverity);
	
	if sFoodYieldChange == "" and sProductionYieldChange == "" then
		return "";
	else
		return table.concat({"CITIES", "[NEWLINE]", sFoodYieldChange, sProductionYieldChange});
	end
end


-- ===========================================================================
-- Returns current player effects as a string.
-- ===========================================================================
function GetPlayerEffects(sSeason, iSeverity)
	sWarWearinessChange = GetWarWearinessChange(sSeason, iSeverity);
			
	if sWarWearinessChange == "" then
		return "";
	else
		return table.concat({"PLAYERS", "[NEWLINE]", sWarWearinessChange});
	end
end


-- ===========================================================================
-- Returns all current effects as a string.
-- ===========================================================================
function GetAllEffects(sUnits, sCities, sPlayers)
	if sUnitEffects == "" and sCityEffects == "" and sPlayerEffects == "" then
		return "No Effects[NEWLINE]";
	else
		sFirstNewline = "";
		if sUnitEffects ~= "" then
			if sCityEffects ~= "" or sPlayerEffects ~= "" then
				sFirstNewline = "[NEWLINE]";
			end
		end
		
		sSecondNewline = "";
		if sCityEffects ~= "" then
			if sPlayerEffects ~= "" then
				sSecondNewline = "[NEWLINE]";
			end
		end
				
		return table.concat({sUnitEffects, sFirstNewline, sCityEffects, sSecondNewline, sPlayerEffects});
	end
end


-- ===========================================================================
-- Returns possible severity and start turn of the next season as a string.
-- ===========================================================================
function GetNextSeasonInfo(sSeason, iSeverity)
	local sNextSeason = GetNextSeason(sSeason);
	
	iSeasonChangeTurnNoOffset_UI = Game:GetProperty("iSeasonChangeTurnNoOffset_UI");
	
	iMinNextSeasonTurn = iSeasonChangeTurnNoOffset_UI - kMaxSeasonOffset_UI;
	iMaxNextSeasonTurn = iSeasonChangeTurnNoOffset_UI + kMaxSeasonOffset_UI;
	
	if sSeason == "SPRING" then
		return table.concat({sNextSeason, " will have no Severity and start between [ICON_Turn]Turn ", iMinNextSeasonTurn, " - ", iMaxNextSeasonTurn});
	else
		iMinNextSeasonSeverity = GetMinSeverity(iSeverity);
		iMaxNextSeasonSeverity = GetMaxSeverity(iSeverity);
		
		return table.concat({sNextSeason, " will have a Severity of ", iMinNextSeasonSeverity, " - ", iMaxNextSeasonSeverity, " and start between [ICON_Turn]Turn ", iMinNextSeasonTurn, " - ", iMaxNextSeasonTurn});
	end
end


-- ===========================================================================
-- Returns healing change as a string based on current season and severity.
-- ===========================================================================
function GetHealingChange(sSeason, iSeverity)
	if sSeason == "AUTUMN" then
		if iSeverity == 1 then
			return "";
			
		elseif TableHasValue({2, 3}, iSeverity) then
			return "-5 [ICON_Damaged]Healing per [ICON_Turn]Turn[NEWLINE]";
		else
			return "-10 [ICON_Damaged]Healing per [ICON_Turn]Turn[NEWLINE]";
		end
		
	elseif sSeason == "WINTER" then
		if TableHasValue({1, 2}, iSeverity) then
			return "-5 [ICON_Damaged]Healing per [ICON_Turn]Turn[NEWLINE]";
			
		elseif TableHasValue({3, 4, 5}, iSeverity) then
			return "-10 [ICON_Damaged]Healing per [ICON_Turn]Turn[NEWLINE]";
		else
			return "-15 [ICON_Damaged]Healing per [ICON_Turn]Turn[NEWLINE]";
		end
	
	elseif sSeason == "SPRING" then
		if TableHasValue({1, 2}, iSeverity) then
			return "";
			
		elseif TableHasValue({3, 4}, iSeverity) then
			return "-5 [ICON_Damaged]Healing per [ICON_Turn]Turn[NEWLINE]";
		else
			return "-10 [ICON_Damaged]Healing per [ICON_Turn]Turn[NEWLINE]";
		end
	end
end


-- ===========================================================================
-- Returns maintenance change as a string based on current season and severity.
-- ===========================================================================
function GetMaintenanceChange(sSeason, iSeverity)
	if sSeason == "AUTUMN" then
		if TableHasValue({1, 2}, iSeverity) then
			return "";
		elseif TableHasValue({3, 4}, iSeverity) then
			return "+1 [ICON_Gold]Maintenance[NEWLINE]";
		else
			return "+2 [ICON_Gold]Maintenance[NEWLINE]";
		end
		
	elseif sSeason == "WINTER" then
		if TableHasValue({1, 2}, iSeverity) then
			return "+1 [ICON_Gold]Maintenance[NEWLINE]";
			
		elseif iSeverity == 3 then
			return "+2 [ICON_Gold]Maintenance[NEWLINE]";
			
		elseif iSeverity == 4 then
			return "+3 [ICON_Gold]Maintenance[NEWLINE]";
			
		elseif iSeverity == 5 then
			return "+4 [ICON_Gold]Maintenance[NEWLINE]";
		else
			return "+5 [ICON_Gold]Maintenance[NEWLINE]";
		end
	
	elseif sSeason == "SPRING" then
		if TableHasValue({1, 2, 3, 4}, iSeverity) then
			return "";
		else
			return "+1 [ICON_Gold]Maintenance[NEWLINE]";
		end
	end
end


-- ===========================================================================
-- Returns movement change as a string based on current season and severity.
-- ===========================================================================
function GetMovementChange(sSeason, iSeverity)
	if sSeason == "AUTUMN" then
		if TableHasValue({1, 2}, iSeverity) then
			return "";
		else
			return "-1 [ICON_Movement]Movement[NEWLINE]";
		end
		
	elseif sSeason == "WINTER" then
		if iSeverity == 1 then
			return "";
			
		elseif TableHasValue({2, 3, 4}, iSeverity) then
			return "-1 [ICON_Movement]Movement[NEWLINE]";
		else
			return "-2 [ICON_Movement]Movement[NEWLINE]";
		end
	
	elseif sSeason == "SPRING" then
		if TableHasValue({1, 2, 3}, iSeverity) then
			return "";
		else
			return "-1 [ICON_Movement]Movement[NEWLINE]";
		end
	end
end


-- ===========================================================================
-- Returns food yield change as a string based on current season and severity.
-- ===========================================================================
function GetFoodYieldChange(sSeason, iSeverity)
	if sSeason == "AUTUMN" then
		if TableHasValue({1, 2, 3}, iSeverity) then
			return "";
		else
			return "-1 [ICON_Food]Food per Tile[NEWLINE]";
		end
		
	elseif sSeason == "WINTER" then
		if TableHasValue({1, 2, 3}, iSeverity) then
			return "-1 [ICON_Food]Food per Tile[NEWLINE]";
			
		elseif iSeverity == 4 then
			return "-2 [ICON_Food]Food per Tile[NEWLINE]";
		elseif iSeverity == 5 then
			return "-3 [ICON_Food]Food per Tile[NEWLINE]";
		else
			return "-4 [ICON_Food]Food per Tile[NEWLINE]";
		end
	
	elseif sSeason == "SPRING" then
		if iSeverity == 1 then
			return "";
			
		elseif TableHasValue({2, 3, 4}, iSeverity) then
			return "-1 [ICON_Food]Food per Tile[NEWLINE]";
		else
			return "-2 [ICON_Food]Food per Tile[NEWLINE]";
		end
	end
end


-- ===========================================================================
-- Returns food yield change as a string based on current season and severity.
-- ===========================================================================
function GetProductionYieldChange(sSeason, iSeverity)
	if sSeason == "AUTUMN" then
		if TableHasValue({1, 2, 3, 4}, iSeverity) then
			return "";
		else
			return "-1 [ICON_Production]Production per Tile[NEWLINE]";
		end
		
	elseif sSeason == "WINTER" then
		if TableHasValue({1, 2}, iSeverity) then
			return "";
			
		elseif TableHasValue({3, 4, 5}, iSeverity) then
			return "-1 [ICON_Production]Production per Tile[NEWLINE]";
		else
			return "-2 [ICON_Production]Production per Tile[NEWLINE]";
		end
	
	elseif sSeason == "SPRING" then
		if TableHasValue({1, 2, 3, 4}, iSeverity) then
			return "";
		else
			return "-1 [ICON_Production]Production per Tile[NEWLINE]";
		end
	end
end


-- ===========================================================================
-- Returns war weariness change as a string based on current season and severity.
-- ===========================================================================
function GetWarWearinessChange(sSeason, iSeverity)
	if sSeason == "AUTUMN" then
		if TableHasValue({1, 2, 3}, iSeverity) then
			return "";
		else
			return "+16 [ICON_Ability]War Weariness per Combat Action[NEWLINE]";
		end
		
	elseif sSeason == "WINTER" then
		if iSeverity == 1 then
			return "";
			
		elseif TableHasValue({2, 3}, iSeverity) then
			return "+16 [ICON_Ability]War Weariness per Combat Action[NEWLINE]";
			
		elseif TableHasValue({4, 5}, iSeverity) then
			return "+32 [ICON_Ability]War Weariness per Combat Action[NEWLINE]";
		else
			return "+48 [ICON_Ability]War Weariness per Combat Action[NEWLINE]";
		end
	
	elseif sSeason == "SPRING" then
		if TableHasValue({1, 2, 3, 4}, iSeverity) then
			return "";
		else
			return "+16 [ICON_Ability]War Weariness per Combat Action[NEWLINE]";
		end
	end
end


-- ===========================================================================
-- Not sure if I need this.
-- ===========================================================================
function MouseOverButton()
end


Events.LoadScreenClose.Add(AddSeasonButtons);
Events.LoadScreenClose.Add(CheckGameLoad);
Events.TurnBegin.Add(UpdateFourSeasonsUI);