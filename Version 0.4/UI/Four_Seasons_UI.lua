-- ===========================================================================
-- Four_Seasons_UI
-- Author: sharpNd
-- 2022-06-03
-- Version 0.4
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
-- _UI = values that are set in the Gameplay script and used in the UI script
-- ===========================================================================


-- ===========================================================================
local kSeasonLength = GameConfiguration.GetValue("iSeasonLength");
-- this is for everyone who saved a game in V0.2 and loads it up in V0.3, because kChangTime didn't exist and needs a value other than nil
if GameConfiguration.GetValue("bTimeOfDayBasedOnSeason") == nil then
	kChangeTime = true;
else
	kChangeTime = GameConfiguration.GetValue("bTimeOfDayBasedOnSeason");
end
-- number of hours to skip per turn in the animated time of day feature. float value.
local kHoursPerTurn = 24 / (kSeasonLength * 4);
local kStartTurn = GameConfiguration.GetStartTurn();
-- time (probably in seconds) the UI takes to transition the ambient time of day
local kTimeTransitionSpeed = 1.0;

-- keep updated with GameConfiguration.SetValue() at all times
local sToolTip;
local fCurrentHour;

-- these are kept updated in the Gameplay script with Game:SetProperty
local sNextSeason_UI;
local iNextSeasonSeverity_UI;
local bSeasonChange_UI;
local kMaxSeasonOffset_UI = Game:GetProperty("kMaxSeasonOffset_UI");
local kStartSeverity_UI = Game:GetProperty("kStartSeverity_UI");

-- get tables providing the effect values
-- SUMMER
local kSummerExperienceEffects_UI = 	Game:GetProperty("kSummerExperienceEffects_UI");
local kSummerHealingEffects_UI = 		Game:GetProperty("kSummerHealingEffects_UI");
local kSummerMaintenanceEffects_UI = 	Game:GetProperty("kSummerMaintenanceEffects_UI");
local kSummerMovementEffects_UI = 		Game:GetProperty("kSummerMovementEffects_UI");
local kSummerSeaMovementEffects_UI = 	Game:GetProperty("kSummerSeaMovementEffects_UI");
local kSummerFoodEffects_UI =			Game:GetProperty("kSummerFoodEffects_UI");
local kSummerProductionEffects_UI = 	Game:GetProperty("kSummerProductionEffects_UI");
local kSummerWearinessEffects_UI = 		Game:GetProperty("kSummerWearinessEffects_UI");
-- AUTUMN
local kAutumnExperienceEffects_UI = 	Game:GetProperty("kAutumnExperienceEffects_UI");
local kAutumnHealingEffects_UI = 		Game:GetProperty("kAutumnHealingEffects_UI");
local kAutumnMaintenanceEffects_UI = 	Game:GetProperty("kAutumnMaintenanceEffects_UI");
local kAutumnMovementEffects_UI = 		Game:GetProperty("kAutumnMovementEffects_UI");
local kAutumnSeaMovementEffects_UI = 	Game:GetProperty("kAutumnSeaMovementEffects_UI");
local kAutumnFoodEffects_UI =			Game:GetProperty("kAutumnFoodEffects_UI");
local kAutumnProductionEffects_UI = 	Game:GetProperty("kAutumnProductionEffects_UI");
local kAutumnWearinessEffects_UI = 		Game:GetProperty("kAutumnWearinessEffects_UI");
-- WINTER
local kWinterExperienceEffects_UI = 	Game:GetProperty("kWinterExperienceEffects_UI");
local kWinterHealingEffects_UI = 		Game:GetProperty("kWinterHealingEffects_UI");
local kWinterMaintenanceEffects_UI = 	Game:GetProperty("kWinterMaintenanceEffects_UI");
local kWinterMovementEffects_UI = 		Game:GetProperty("kWinterMovementEffects_UI");
local kWinterSeaMovementEffects_UI = 	Game:GetProperty("kWinterSeaMovementEffects_UI");
local kWinterFoodEffects_UI =			Game:GetProperty("kWinterFoodEffects_UI");
local kWinterProductionEffects_UI = 	Game:GetProperty("kWinterProductionEffects_UI");
local kWinterWearinessEffects_UI = 		Game:GetProperty("kWinterWearinessEffects_UI");
-- SPRING
local kSpringExperienceEffects_UI = 	Game:GetProperty("kSpringExperienceEffects_UI");
local kSpringHealingEffects_UI = 		Game:GetProperty("kSpringHealingEffects_UI");
local kSpringMaintenanceEffects_UI = 	Game:GetProperty("kSpringMaintenanceEffects_UI");
local kSpringMovementEffects_UI = 		Game:GetProperty("kSpringMovementEffects_UI");
local kSpringSeaMovementEffects_UI = 	Game:GetProperty("kSpringSeaMovementEffects_UI");
local kSpringFoodEffects_UI =			Game:GetProperty("kSpringFoodEffects_UI");
local kSpringProductionEffects_UI = 	Game:GetProperty("kSpringProductionEffects_UI");
local kSpringWearinessEffects_UI = 		Game:GetProperty("kSpringWearinessEffects_UI");
-- ===========================================================================


-- ===========================================================================
-- Adds the 4 Season Buttons to the right side of the top panel.
-- ===========================================================================
function AddSeasonButtons()
	local tRightContents = ContextPtr:LookUpControl("/InGame/TopPanel/RightContents");
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

			sToolTip = Locale.Lookup("LOC_FOUR_SEASONS_START_TEXT");
			GameConfiguration.SetValue("sToolTip", sToolTip);
			Controls.SummerButton:SetToolTipString(sToolTip);

			if kChangeTime then
				fCurrentHour = 11.00;
				GameConfiguration.SetValue("fCurrentHour", fCurrentHour);
				UI.EnableTimeOfDayOverride(fCurrentHour, kTimeTransitionSpeed);
			end
		end
	-- old game loaded
	else
		sNextSeason_UI = Game:GetProperty("sNextSeason_UI");
		if sNextSeason_UI == "SUMMER" then
			Controls.SummerButton:SetHide(false);
			
		elseif sNextSeason_UI == "AUTUMN" then
			Controls.AutumnButton:SetHide(false);
			
		elseif sNextSeason_UI == "WINTER" then
			Controls.WinterButton:SetHide(false);
			
		elseif sNextSeason_UI == "SPRING" then
			Controls.SpringButton:SetHide(false);
		end
		
		sToolTip = GameConfiguration.GetValue("sToolTip");
		SetToolTip(sNextSeason_UI, sToolTip);

		if kChangeTime then
			fCurrentHour = GameConfiguration.GetValue("fCurrentHour");
			UI.EnableTimeOfDayOverride(fCurrentHour, kTimeTransitionSpeed);
		end
	end
end


-- ===========================================================================
-- Adds given button to given content / panel and hides it.
-- ===========================================================================
function AddButtonTo(uButton, tContent)
	uButton:ChangeParent(tContent);
	-- with 1000 the game will always put the buttons on the very left of the top right panel
	-- (unless the player has 1000 other mods adding an icon there...)
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
		sToolTip = GetToolTipString(true);
		-- Game:SetProperty isn't available in UI scripts but this works the same way
		GameConfiguration.SetValue("sToolTip", sToolTip);
		
		SetToolTip("SUMMER", sToolTip);
	end
	
	bSeasonChange_UI = Game:GetProperty("bSeasonChange_UI");
	
	if bSeasonChange_UI then
		sNextSeason_UI = Game:GetProperty("sNextSeason_UI");
		
		if sNextSeason_UI == "SUMMER" then
			Controls.SpringButton:SetHide(true);
			Controls.SummerButton:SetHide(false);
			
		elseif sNextSeason_UI == "AUTUMN" then
			Controls.SummerButton:SetHide(true);
			Controls.AutumnButton:SetHide(false);
			
		elseif sNextSeason_UI == "WINTER" then
			Controls.AutumnButton:SetHide(true);
			Controls.WinterButton:SetHide(false);
			
		elseif sNextSeason_UI == "SPRING" then
			Controls.WinterButton:SetHide(true);
			Controls.SpringButton:SetHide(false);
		end

		sToolTip = GetToolTipString(false);
		GameConfiguration.SetValue("sToolTip", sToolTip);
		SetToolTip(sNextSeason_UI, sToolTip);
	end

	if kChangeTime then
		UpdateTimeOfDay();
	end
end


-- ===========================================================================
-- Updates the button hover text with the current information.
-- ===========================================================================
function GetToolTipString(bGameStart)
	if bGameStart then
		sThisSeason = Locale.Lookup("LOC_FOUR_SEASONS_SUMMER_TEXT");
		sNextSeason_UI = "SUMMER";
		iNextSeasonSeverity_UI = kStartSeverity_UI;
	else
		sNextSeason_UI = Game:GetProperty("sNextSeason_UI");
		sThisSeason = GetCurrentSeason(sNextSeason_UI);
		iNextSeasonSeverity_UI = Game:GetProperty("iNextSeasonSeverity_UI");
	end

	sSeverityInfo = table.concat({Locale.Lookup("LOC_FOUR_SEASONS_SEVERITY_TEXT"), " ", tostring(iNextSeasonSeverity_UI)});
	
	sUnitEffects = GetUnitEffects(sNextSeason_UI, iNextSeasonSeverity_UI);
	sCityEffects = GetCityEffects(sNextSeason_UI, iNextSeasonSeverity_UI);
	sWarEffects = GetWarEffects(sNextSeason_UI, iNextSeasonSeverity_UI);	
	sAllEffects = GetAllEffects(sUnitEffects, sCityEffects, sWarEffects);

	sNextSeasonInfo = GetNextSeasonInfo(sNextSeason_UI, iNextSeasonSeverity_UI);
		
	-- for some reason a concatenation with .. isn't allowed in UI scripts		
	return table.concat({sThisSeason, " - ", sSeverityInfo, "[NEWLINE][NEWLINE]", sAllEffects, "[NEWLINE]", sNextSeasonInfo});
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
-- Updates animated time of day based on current turn and season.
-- SUMMER is around 11:00 to 17:00
-- AUTUMN is around 17:00 to 23:00
-- WINTER is around 23:00 to 05:00
-- SPRING is around 05:00 to 11:00
-- ===========================================================================
function UpdateTimeOfDay()
	fCurrentHour = math.fmod(fCurrentHour + kHoursPerTurn, 24.00);
	GameConfiguration.SetValue("fCurrentHour", fCurrentHour);
	UI.EnableTimeOfDayOverride(fCurrentHour, kTimeTransitionSpeed);
end


-- ===========================================================================
-- Returns next season as a string.
-- ===========================================================================
function GetCurrentSeason(sSeason)
	if sSeason == "SUMMER" then
		return Locale.Lookup("LOC_FOUR_SEASONS_SUMMER_TEXT");
			
	elseif sSeason == "AUTUMN" then
		return Locale.Lookup("LOC_FOUR_SEASONS_AUTUMN_TEXT");
		
	elseif sSeason == "WINTER" then
		return Locale.Lookup("LOC_FOUR_SEASONS_WINTER_TEXT");
		
	elseif sSeason == "SPRING" then
		return Locale.Lookup("LOC_FOUR_SEASONS_SPRING_TEXT");
	end
end


-- ===========================================================================
-- Returns next season as a string.
-- ===========================================================================
function GetNextSeason(sSeason)
	if sSeason == "SUMMER" then
		return Locale.Lookup("LOC_FOUR_SEASONS_AUTUMN_TEXT");
			
	elseif sSeason == "AUTUMN" then
		return Locale.Lookup("LOC_FOUR_SEASONS_WINTER_TEXT");
		
	elseif sSeason == "WINTER" then
		return Locale.Lookup("LOC_FOUR_SEASONS_SPRING_TEXT");
		
	elseif sSeason == "SPRING" then
		return Locale.Lookup("LOC_FOUR_SEASONS_SUMMER_TEXT");
	end
end


-- ===========================================================================
-- Returns current unit effects as a string.
-- ===========================================================================
function GetUnitEffects(sSeason, iSeverity)
	sExperienceChange = GetExperienceChange(sSeason, iSeverity);
	sHealingChange = GetHealingChange(sSeason, iSeverity);
	sMaintenanceChange = GetMaintenanceChange(sSeason, iSeverity);
	sMovementChange = GetMovementChange(sSeason, iSeverity);
	sSeaMovementChange = GetSeaMovementChange(sSeason, iSeverity);
	
	if sExperienceChange == "" and sHealingChange == "" and sMaintenanceChange == "" and sMovementChange == "" and sSeaMovementChange == "" then
		return "";
	else
		return table.concat({Locale.Lookup("LOC_FOUR_SEASONS_UNITS_TEXT"), "[NEWLINE]", sExperienceChange, sHealingChange, sMaintenanceChange, sMovementChange, sSeaMovementChange});
	end
end


-- ===========================================================================
-- Returns current city effects as a string.
-- ===========================================================================
function GetCityEffects(sSeason, iSeverity)
	sFoodChange = GetFoodChange(sSeason, iSeverity);
	sProductionChange = GetProductionChange(sSeason, iSeverity);
	
	if sFoodChange == "" and sProductionChange == "" then
		return "";
	else
		return table.concat({Locale.Lookup("LOC_FOUR_SEASONS_CITIES_TEXT"), "[NEWLINE]", sFoodChange, sProductionChange});
	end
end


-- ===========================================================================
-- Returns current wars effects as a string.
-- ===========================================================================
function GetWarEffects(sSeason, iSeverity)
	sWarWearinessChange = GetWearinessChange(sSeason, iSeverity);
			
	if sWarWearinessChange == "" then
		return "";
	else
		return table.concat({Locale.Lookup("LOC_FOUR_SEASONS_WARS_TEXT"), "[NEWLINE]", sWarWearinessChange});
	end
end


-- ===========================================================================
-- Returns all current effects as a string.
-- ===========================================================================
function GetAllEffects(sUnits, sCities, sWars)
	if sUnits == "" and sCities == "" and sWars == "" then
		return table.concat({Locale.Lookup("LOC_FOUR_SEASONS_NO_EFFECTS_TEXT"), "[NEWLINE]"});
	else
		sFirstNewline = "";
		if sUnits ~= "" then
			if sCities ~= "" or sWars ~= "" then
				sFirstNewline = "[NEWLINE]";
			end
		end
		
		sSecondNewline = "";
		if sCities ~= "" then
			if sWars ~= "" then
				sSecondNewline = "[NEWLINE]";
			end
		end

		sEffectHeading = table.concat({Locale.Lookup("LOC_FOUR_SEASONS_EFFECTS_HEADING_TEXT"), "[NEWLINE][NEWLINE]"});
				
		return table.concat({sEffectHeading, sUnits, sFirstNewline, sCities, sSecondNewline, sWars});
	end
end


-- ===========================================================================
-- Returns start turn of the next season as a string.
-- ===========================================================================
function GetNextSeasonInfo(sSeason, iSeverity)
	local sNextSeason = GetNextSeason(sSeason);
	
	iSeasonChangeTurnNoOffset_UI = Game:GetProperty("iSeasonChangeTurnNoOffset_UI");
	
	iMinNextSeasonTurn = iSeasonChangeTurnNoOffset_UI - kMaxSeasonOffset_UI;
	iMaxNextSeasonTurn = iSeasonChangeTurnNoOffset_UI + kMaxSeasonOffset_UI;
	
	return table.concat({sNextSeason, " ", Locale.Lookup("LOC_FOUR_SEASONS_NEW_SEASON_INFO_1_TEXT"), " ", tostring(iMinNextSeasonTurn), " ", Locale.Lookup("LOC_FOUR_SEASONS_NEW_SEASON_INFO_2_TEXT"), " ", tostring(iMaxNextSeasonTurn)});
end


-- ===========================================================================
-- Returns experience change as a string based on current season and severity.
-- ===========================================================================
function GetExperienceChange(sSeason, iSeverity)
	local iExperienceValue;

	if sSeason == "SUMMER" then
		iExperienceValue = kSummerExperienceEffects_UI[iSeverity];

	elseif sSeason == "AUTUMN" then
		iExperienceValue = kAutumnExperienceEffects_UI[iSeverity];
		
	elseif sSeason == "WINTER" then
		iExperienceValue = kWinterExperienceEffects_UI[iSeverity];

	elseif sSeason == "SPRING" then
		iExperienceValue = kSpringExperienceEffects_UI[iSeverity];
	end

	if iExperienceValue == 0 then
		return "";
	else
		local sExperienceValue = tostring(iExperienceValue);
		if iExperienceValue > 0 then
			sExperienceValue = table.concat({"+", sExperienceValue});
		end
		local sExperienceText = Locale.Lookup("LOC_FOUR_SEASONS_EXPERIENCE_TEXT");
		return table.concat({sExperienceValue, "% ", sExperienceText, "[NEWLINE]"});
	end
end


-- ===========================================================================
-- Returns healing change as a string based on current season and severity.
-- ===========================================================================
function GetHealingChange(sSeason, iSeverity)
	local iHealingValue;

	if sSeason == "SUMMER" then
		iHealingValue = kSummerHealingEffects_UI[iSeverity];

	elseif sSeason == "AUTUMN" then
		iHealingValue = kAutumnHealingEffects_UI[iSeverity];
		
	elseif sSeason == "WINTER" then
		iHealingValue = kWinterHealingEffects_UI[iSeverity];

	elseif sSeason == "SPRING" then
		iHealingValue = kSpringHealingEffects_UI[iSeverity];
	end

	if iHealingValue == 0 then
		return "";
	else
		local sHealingValue = tostring(iHealingValue);
		if iHealingValue > 0 then
			sHealingValue = table.concat({"+", sHealingValue});
		end
		local sHealingText = Locale.Lookup("LOC_FOUR_SEASONS_HEALING_TEXT");
		return table.concat({sHealingValue, " ", sHealingText, "[NEWLINE]"});
	end
end


-- ===========================================================================
-- Returns maintenance change as a string based on current season and severity.
-- ===========================================================================
function GetMaintenanceChange(sSeason, iSeverity)
	local iMaintenanceValue;

	if sSeason == "SUMMER" then
		iMaintenanceValue = kSummerMaintenanceEffects_UI[iSeverity];

	elseif sSeason == "AUTUMN" then
		iMaintenanceValue = kAutumnMaintenanceEffects_UI[iSeverity];
		
	elseif sSeason == "WINTER" then
		iMaintenanceValue = kWinterMaintenanceEffects_UI[iSeverity];
	
	elseif sSeason == "SPRING" then
		iMaintenanceValue = kSpringMaintenanceEffects_UI[iSeverity]
	end

	if iMaintenanceValue == 0 then
		return "";
	else
		local sMaintenanceValue = tostring(iMaintenanceValue);
		if iMaintenanceValue > 0 then
			sMaintenanceValue = table.concat({"+", sMaintenanceValue});
		end
		local sMaintenanceText = Locale.Lookup("LOC_FOUR_SEASONS_MAINTENANCE_TEXT");
		return table.concat({sMaintenanceValue, " ", sMaintenanceText, "[NEWLINE]"});
	end
end


-- ===========================================================================
-- Returns movement change as a string based on current season and severity.
-- ===========================================================================
function GetMovementChange(sSeason, iSeverity)
	local iMovementValue;
	
	if sSeason == "SUMMER" then
		iMovementValue = kSummerMovementEffects_UI[iSeverity];

	elseif sSeason == "AUTUMN" then
		iMovementValue = kAutumnMovementEffects_UI[iSeverity];
		
	elseif sSeason == "WINTER" then
		iMovementValue = kWinterMovementEffects_UI[iSeverity];
	
	elseif sSeason == "SPRING" then
		iMovementValue = kSpringMovementEffects_UI[iSeverity];
	end

	if iMovementValue == 0 then
		return "";
	else
		local sMovementValue = tostring(iMovementValue);
		if iMovementValue > 0 then
			sMovementValue = table.concat({"+", sMovementValue});
		end
		local sMovementText = Locale.Lookup("LOC_FOUR_SEASONS_MOVEMENT_TEXT");
		return table.concat({sMovementValue, " ", sMovementText, "[NEWLINE]"});
	end
end


-- ===========================================================================
-- Returns sea movement change as a string based on current season and severity.
-- ===========================================================================
function GetSeaMovementChange(sSeason, iSeverity)
	local iSeaMovementValue;
	
	if sSeason == "SUMMER" then
		iSeaMovementValue = kSummerSeaMovementEffects_UI[iSeverity];

	elseif sSeason == "AUTUMN" then
		iSeaMovementValue = kAutumnSeaMovementEffects_UI[iSeverity];
		
	elseif sSeason == "WINTER" then
		iSeaMovementValue = kWinterSeaMovementEffects_UI[iSeverity];
	
	elseif sSeason == "SPRING" then
		iSeaMovementValue = kSpringSeaMovementEffects_UI[iSeverity];
	end

	if iSeaMovementValue == 0 then
		return "";
	else
		local sSeaMovementValue = tostring(iSeaMovementValue);
		if iSeaMovementValue > 0 then
			sSeaMovementValue = table.concat({"+", sSeaMovementValue});
		end
		local sSeaMovementText = Locale.Lookup("LOC_FOUR_SEASONS_SEA_MOVEMENT_TEXT");
		return table.concat({sSeaMovementValue, " ", sSeaMovementText, "[NEWLINE]"});
	end
end


-- ===========================================================================
-- Returns food yield change as a string based on current season and severity.
-- ===========================================================================
function GetFoodChange(sSeason, iSeverity)
	local iFoodValue;
	
	if sSeason == "SUMMER" then
		iFoodValue = kSummerFoodEffects_UI[iSeverity];

	elseif sSeason == "AUTUMN" then
		iFoodValue = kAutumnFoodEffects_UI[iSeverity];
		
	elseif sSeason == "WINTER" then
		iFoodValue = kWinterFoodEffects_UI[iSeverity];
	
	elseif sSeason == "SPRING" then
		iFoodValue = kSpringFoodEffects_UI[iSeverity];
	end

	if iFoodValue == 0 then
		return "";
	else
		local sFoodValue = tostring(iFoodValue);
		if iFoodValue > 0 then
			sFoodValue = table.concat({"+", sFoodValue});
		end
		local sFoodText = Locale.Lookup("LOC_FOUR_SEASONS_FOOD_TEXT");
		return table.concat({sFoodValue, " ", sFoodText, "[NEWLINE]"});
	end
end


-- ===========================================================================
-- Returns food yield change as a string based on current season and severity.
-- ===========================================================================
function GetProductionChange(sSeason, iSeverity)
	local iProductionValue;

	if sSeason == "SUMMER" then
		iProductionValue = kSummerProductionEffects_UI[iSeverity];

	elseif sSeason == "AUTUMN" then
		iProductionValue = kAutumnProductionEffects_UI[iSeverity];
		
	elseif sSeason == "WINTER" then
		iProductionValue = kWinterProductionEffects_UI[iSeverity];
	
	elseif sSeason == "SPRING" then
		iProductionValue = kSpringProductionEffects_UI[iSeverity];
	end

	if iProductionValue == 0 then
		return "";
	else
		local sProductionValue = tostring(iProductionValue);
		if iProductionValue > 0 then
			sProductionValue = table.concat({"+", sProductionValue});
		end
		local sProductionText = Locale.Lookup("LOC_FOUR_SEASONS_PRODUCTION_TEXT");
		return table.concat({sProductionValue, " ", sProductionText, "[NEWLINE]"});
	end
end


-- ===========================================================================
-- Returns war weariness change as a string based on current season and severity.
-- ===========================================================================
function GetWearinessChange(sSeason, iSeverity)
	local iWearinessValue;

	if sSeason == "SUMMER" then
		iWearinessValue = kSummerWearinessEffects_UI[iSeverity];

	elseif sSeason == "AUTUMN" then
		iWearinessValue = kAutumnWearinessEffects_UI[iSeverity];
		
	elseif sSeason == "WINTER" then
		iWearinessValue = kWinterWearinessEffects_UI[iSeverity];
	
	elseif sSeason == "SPRING" then
		iWearinessValue = kSpringWearinessEffects_UI[iSeverity];
	end

	if iWearinessValue == 0 then
		return "";
	else
		local sWearinessValue = tostring(iWearinessValue);
		if iWearinessValue > 0 then
			sWearinessValue = table.concat({"+", sWearinessValue});
		end
		local sWearinessText = Locale.Lookup("LOC_FOUR_SEASONS_WEARINESS_TEXT");
		return table.concat({sWearinessValue, " ", sWearinessText, "[NEWLINE]"});
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
-- Not sure if I need this.
-- ===========================================================================
function MouseOverButton()
end


Events.LoadScreenClose.Add(AddSeasonButtons);
Events.LoadScreenClose.Add(CheckGameLoad);
Events.TurnBegin.Add(UpdateFourSeasonsUI);