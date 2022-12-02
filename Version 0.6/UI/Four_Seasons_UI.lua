-- ===========================================================================
-- Four_Seasons_UI
-- Author: sharpNd
-- 2022-07-23
-- Version 0.5
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
-- _ = unused function parameters (not in use here)

-- Suffixes
-- _UI = values that are set in the Gameplay script and used in the UI script
-- ===========================================================================


-- ===========================================================================
local kSeasonLength = GameConfiguration.GetValue("iSeasonLength");
-- this is for everyone who saved a game in earlier versions and loads it up in V0.3 or later, because kChangTime didn't exist and needs a value other than nil
local kChangeTime;
if GameConfiguration.GetValue("bTimeOfDayBasedOnSeason") == nil then
	kChangeTime = true;
else
	kChangeTime = GameConfiguration.GetValue("bTimeOfDayBasedOnSeason");
end
-- this is for everyone who saved a game in earlier versions and loads it up in V0.5 or later, because iSeverityBias didn't exist and needs a value other than nil
local kSeverityBias;
if GameConfiguration.GetValue("iSeverityBias") == nil then
	kSeverityBias = 3;
else
	kSeverityBias = GameConfiguration.GetValue("iSeverityBias");
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
local kExperienceEffects_UI = 	Game:GetProperty("kExperienceEffects_UI");
local kHealingEffects_UI =		Game:GetProperty("kHealingEffects_UI");
local kMaintenanceEffects_UI =	Game:GetProperty("kMaintenanceEffects_UI");
local kMovementEffects_UI =		Game:GetProperty("kMovementEffects_UI");
local kSeaMovementEffects_UI =	Game:GetProperty("kSeaMovementEffects_UI");
local kFoodEffects_UI =			Game:GetProperty("kFoodEffects_UI");
local kProductionEffects_UI =	Game:GetProperty("kProductionEffects_UI");
local kWearinessEffects_UI =	Game:GetProperty("kWearinessEffects_UI");
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

			local sWelcome = Locale.Lookup("LOC_FOUR_SEASONS_START_TEXT");
			local sYourSettings = Locale.Lookup("LOC_FOUR_SEASONS_START_YOUR_SETTINGS_TEXT");
			local sYourSeasonLength = table.concat({Locale.Lookup("LOC_FOUR_SEASONS_START_SEASON_LENGTH_TEXT"), " ", tostring(kSeasonLength)});
			local sYourSeverityBias = table.concat({Locale.Lookup("LOC_FOUR_SEASONS_START_SEVERITY_BIAS_TEXT"), " ", tostring(kSeverityBias)});
			local sChangeTime = table.concat({Locale.Lookup("LOC_FOUR_SEASONS_START_TOD_SEASON_TEXT"), " ", tostring(kChangeTime)});
			local sSeeCivilopedia = table.concat({Locale.Lookup("LOC_FOUR_SEASONS_START_SEE_CIVILOPEDIA_TEXT")});

			sToolTip = table.concat({sWelcome, "[NEWLINE][NEWLINE]", sYourSettings, "[NEWLINE][NEWLINE]", sYourSeasonLength, "[NEWLINE]", sYourSeverityBias, "[NEWLINE]", sChangeTime, "[NEWLINE][NEWLINE]", sSeeCivilopedia});
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

	local sSeverityIcon;
	if iNextSeasonSeverity_UI == 6 then
		sSeverityIcon = " [ICON_Exclamation]";
	else
		sSeverityIcon = "";
	end
	local sSeverityInfo = table.concat({Locale.Lookup("LOC_FOUR_SEASONS_SEVERITY_TEXT"), " ", tostring(iNextSeasonSeverity_UI), sSeverityIcon});
	
	local iSeasonIndex = GetSeasonIndex(sNextSeason_UI);

	local sUnitEffects = GetUnitEffects(iSeasonIndex, iNextSeasonSeverity_UI);
	local sCityEffects = GetCityEffects(iSeasonIndex, iNextSeasonSeverity_UI);
	local sWarEffects = GetWarEffects(iSeasonIndex, iNextSeasonSeverity_UI);	
	local sAllEffects = GetAllEffects(sUnitEffects, sCityEffects, sWarEffects);

	local sNextSeasonInfo = GetNextSeasonInfo(sNextSeason_UI, iNextSeasonSeverity_UI);
		
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
-- Returns the Season Index that is used for the 2d effect tables.
-- ===========================================================================
function GetSeasonIndex(sSeason)
	if sSeason == "SUMMER" then
		return 1;

	elseif sSeason == "AUTUMN" then
		return 2;

	elseif sSeason == "WINTER" then
		return 3;

	elseif sSeason == "SPRING" then
		return 4;
	end
end


-- ===========================================================================
-- Returns current unit effects as a string.
-- ===========================================================================
function GetUnitEffects(iSeasonIndex, iSeverity)
	local sExperienceChange = GetExperienceChange(iSeasonIndex, iSeverity);
	local sHealingChange = GetHealingChange(iSeasonIndex, iSeverity);
	local sMaintenanceChange = GetMaintenanceChange(iSeasonIndex, iSeverity);
	local sMovementChange = GetMovementChange(iSeasonIndex, iSeverity);
	local sSeaMovementChange = GetSeaMovementChange(iSeasonIndex, iSeverity);
	
	if sExperienceChange == "" and sHealingChange == "" and sMaintenanceChange == "" and sMovementChange == "" and sSeaMovementChange == "" then
		return "";
	else
		return table.concat({Locale.Lookup("LOC_FOUR_SEASONS_UNITS_TEXT"), "[NEWLINE]", sExperienceChange, sHealingChange, sMaintenanceChange, sMovementChange, sSeaMovementChange});
	end
end


-- ===========================================================================
-- Returns current city effects as a string.
-- ===========================================================================
function GetCityEffects(iSeasonIndex, iSeverity)
	local sFoodChange = GetFoodChange(iSeasonIndex, iSeverity);
	local sProductionChange = GetProductionChange(iSeasonIndex, iSeverity);
	
	if sFoodChange == "" and sProductionChange == "" then
		return "";
	else
		return table.concat({Locale.Lookup("LOC_FOUR_SEASONS_CITIES_TEXT"), "[NEWLINE]", sFoodChange, sProductionChange});
	end
end


-- ===========================================================================
-- Returns current wars effects as a string.
-- ===========================================================================
function GetWarEffects(iSeasonIndex, iSeverity)
	local sWarWearinessChange = GetWearinessChange(iSeasonIndex, iSeverity);
			
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
		local sFirstNewline = "";
		if sUnits ~= "" then
			if sCities ~= "" or sWars ~= "" then
				sFirstNewline = "[NEWLINE]";
			end
		end
		
		local sSecondNewline = "";
		if sCities ~= "" then
			if sWars ~= "" then
				sSecondNewline = "[NEWLINE]";
			end
		end

		local sEffectHeading = table.concat({Locale.Lookup("LOC_FOUR_SEASONS_EFFECTS_HEADING_TEXT"), "[NEWLINE][NEWLINE]"});
				
		return table.concat({sEffectHeading, sUnits, sFirstNewline, sCities, sSecondNewline, sWars});
	end
end


-- ===========================================================================
-- Returns start turn of the next season as a string.
-- ===========================================================================
function GetNextSeasonInfo(sSeason, iSeverity)
	local sNextSeason = GetNextSeason(sSeason);
	local iSeasonChangeTurnNoOffset_UI = Game:GetProperty("iSeasonChangeTurnNoOffset_UI");
	local iMinNextSeasonTurn = iSeasonChangeTurnNoOffset_UI - kMaxSeasonOffset_UI;
	local iMaxNextSeasonTurn = iSeasonChangeTurnNoOffset_UI + kMaxSeasonOffset_UI;
	return table.concat({sNextSeason, " ", Locale.Lookup("LOC_FOUR_SEASONS_NEW_SEASON_INFO_1_TEXT"), " ", tostring(iMinNextSeasonTurn), " ", Locale.Lookup("LOC_FOUR_SEASONS_NEW_SEASON_INFO_2_TEXT"), " ", tostring(iMaxNextSeasonTurn)});
end


-- ===========================================================================
-- Returns experience change as a string based on current season and severity.
-- ===========================================================================
function GetExperienceChange(iSeasonIndex, iSeverity)
	local iExperienceValue = kExperienceEffects_UI[iSeasonIndex][iSeverity];

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
function GetHealingChange(iSeasonIndex, iSeverity)
	local iHealingValue = kHealingEffects_UI[iSeasonIndex][iSeverity];

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
function GetMaintenanceChange(iSeasonIndex, iSeverity)
	local iMaintenanceValue = kMaintenanceEffects_UI[iSeasonIndex][iSeverity];

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
function GetMovementChange(iSeasonIndex, iSeverity)
	local iMovementValue = kMovementEffects_UI[iSeasonIndex][iSeverity];

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
function GetSeaMovementChange(iSeasonIndex, iSeverity)
	local iSeaMovementValue = kSeaMovementEffects_UI[iSeasonIndex][iSeverity];

	if iSeaMovementValue == 0 then
		return "";
	else
		local sSeaMovementValue;
		-- no movement for naval units (water freezing)
		if iSeaMovementValue == -999 then
			sSeaMovementValue = Locale.Lookup("LOC_FOUR_SEASONS_NO_SEA_MOVEMENT_TEXT");
		else
			sSeaMovementValue = tostring(iSeaMovementValue);
			if iSeaMovementValue > 0 then
				sSeaMovementValue = table.concat({"+", sSeaMovementValue});
			end
		end
		local sSeaMovementText = Locale.Lookup("LOC_FOUR_SEASONS_SEA_MOVEMENT_TEXT");
		return table.concat({sSeaMovementValue, " ", sSeaMovementText, "[NEWLINE]"});
	end
end


-- ===========================================================================
-- Returns food yield change as a string based on current season and severity.
-- ===========================================================================
function GetFoodChange(iSeasonIndex, iSeverity)
	local iFoodValue = kFoodEffects_UI[iSeasonIndex][iSeverity];

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
function GetProductionChange(iSeasonIndex, iSeverity)
	local iProductionValue = kProductionEffects_UI[iSeasonIndex][iSeverity];

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
function GetWearinessChange(iSeasonIndex, iSeverity)
	local iWearinessValue = kWearinessEffects_UI[iSeasonIndex][iSeverity];

	if iWearinessValue == 0 then
		return "";
	else
		local bAutoplayEnabled = Game:GetProperty("bAutoplayEnabled");
		local iWearinessEraFactor_UI;
		if bAutoplayEnabled then
			iWearinessEraFactor_UI = 2;
		else
			iWearinessEraFactor_UI = Game:GetProperty("iWearinessEraFactor_UI");
		end
		local sWearinessValue = tostring(iWearinessValue * iWearinessEraFactor_UI);
		if iWearinessValue > 0 then
			sWearinessValue = table.concat({"+", sWearinessValue});
		end
		local sWearinessText = Locale.Lookup("LOC_FOUR_SEASONS_WEARINESS_TEXT");
		return table.concat({sWearinessValue, " ", sWearinessText, "[NEWLINE]"});
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