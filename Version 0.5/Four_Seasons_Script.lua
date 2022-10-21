-- ===========================================================================
-- Four_Seasons_Script
-- Author: sharpNd
-- 2022-07-23
-- Version 0.5
-- ===========================================================================


-- ===========================================================================
-- Variable naming
-- Prefixes
-- b = boolean
-- f = float (not in use here)
-- i = integer
-- k = constant 
-- p = pointer
-- s = string
-- t = table
-- u = unknown (not in use here)

-- Suffixes
-- _UI = values that are set in the Gameplay Script and used in the UI script
-- ===========================================================================


-- ===========================================================================
local kSeasonLength = GameConfiguration.GetValue("iSeasonLength");
-- this is for everyone who saved a game in earlier versions and loads it up in V0.5 or later, because iSeverityBias didn't exist and needs a value other than nil
local kSeverityBias;
if GameConfiguration.GetValue("iSeverityBias") == nil then
	kSeverityBias = 3;
else
	kSeverityBias = GameConfiguration.GetValue("iSeverityBias");
end

-- Keep this value between [0, 0.5[
local kSeasonOffsetRange = 0.2;
local kMaxSeasonOffset_UI = math.floor(kSeasonLength * kSeasonOffsetRange);
Game:SetProperty("kMaxSeasonOffset_UI", kMaxSeasonOffset_UI);

local kStartTurn = GameConfiguration.GetStartTurn();

-- Severity of the first Summer. Leaving this at 4 so that there are no effects in the start.
-- If you change this, make sure to attach the Summer modifiers in CheckGameLoad().
local kStartSeverity_UI = 4;
Game:SetProperty("kStartSeverity_UI", kStartSeverity_UI);

-- keep these variables updated with Game:SetProperty at all times
local bSeasonChange_UI;
local bEraFactorChange;
local bAutoplayEnabled; -- when autoplay is enabled, era based changes can't be done (this is only relevant for me when testing though)

local iSeasonCounter;
local iThisSeasonOffset;
local iThisSeasonChangeTurn;
local iNextSeasonChangeTurn;
local iThisSeasonSeverity;
local iNextSeasonSeverity_UI;
local iWearinessEraFactor_UI;

local sThisSeason;
local sNextSeason_UI;

-- These tables provide the effect values. Edit these and both Gameplay and UI (except Civilopedia) adjust.
-- (!) Make sure that Four_Seasons_Modifiers.xml has the modifiers needed if you set values that go out of the default range. Example: increase or decrease food yield by 5 or more.

-- Season							Summer						Autumn						Winter							 Spring
-- Severity							1	 2	  3	   4	5		1	 2	  3	   4	5		1	 2	  3	   4	5	 6		 1	  2	   3    4 	 5
-- UNITS
local kExperienceEffects_UI =  { {-60, -40, -20,   0,   0 }, {  0,   0,  20,  40,  40 }, { 20,  40,  40,  60,  80, 100 }, {-20,   0,   0,  20,  40 } };
local kHealingEffects_UI =	   { { 10,   5,   5,   0,   0 }, {  0,   0,  -5,  -5,  -5 }, { -5,  -5,  -5, -10, -10, -15 }, {  5,   0,   0,  -5,  -5 } };
local kMaintenanceEffects_UI = { {  0,   0,   0,   0,   1 }, {  0,   0,   1,   1,   2 }, {  1,   1,   2,   3,   4,   5 }, {  0,   0,   1,   1,   2 } };
local kMovementEffects_UI =	   { {  1,   1,   0,   0,   0 }, {  0,   0,   0,  -1,  -1 }, {  0,  -1,  -1,  -1,  -2,  -2 }, {  0,   0,   0,   0,  -1 } };
local kSeaMovementEffects_UI = { {  0,   0,   0,   0,   0 }, {  0,   0,   0,   0,   0 }, {  0,   0,   0,  -1,  -2,-999 }, {  0,   0,   0,   0,   0 } };
-- CITIES
local kFoodEffects_UI =		   { {  1,   1,   0,   0,  -1 }, {  1,   0,   0,  -1,  -1 }, { -1,  -1,  -2,  -2,  -3,  -4 }, {  0,   0,  -1,  -1,  -1 } };
local kProductionEffects_UI =  { {  1,   0,   0,   0,   0 }, {  0,   0,   0,   0,  -1 }, {  0,   0,  -1,  -1,  -1,  -2 }, {  0,   0,   0,   0,   0 } };
-- WARS
local kWearinessEffects_UI =   { {  0,   0,   0,   0,   0 }, {  0,   0,   0,  16,  16 }, {  0,  16,  16,  32,  32,  48 }, {  0,   0,   0,   0,  16 } };

Game:SetProperty("kExperienceEffects_UI", 	kExperienceEffects_UI);
Game:SetProperty("kHealingEffects_UI", 		kHealingEffects_UI);
Game:SetProperty("kMaintenanceEffects_UI", 	kMaintenanceEffects_UI);
Game:SetProperty("kMovementEffects_UI", 	kMovementEffects_UI);
Game:SetProperty("kSeaMovementEffects_UI", 	kSeaMovementEffects_UI);
Game:SetProperty("kFoodEffects_UI", 		kFoodEffects_UI);
Game:SetProperty("kProductionEffects_UI", 	kProductionEffects_UI);
Game:SetProperty("kWearinessEffects_UI", 	kWearinessEffects_UI);
-- ===========================================================================


-- ===========================================================================
-- Check if the game just started or if it was loaded from a save file.
-- ===========================================================================
function CheckGameLoad()
	-- new game started
	if Game:GetProperty("iSeasonCounter") == nil then
		iSeasonCounter = 1;
		Game:SetProperty("iSeasonCounter", iSeasonCounter);
		
		-- new / first season start offset
		iThisSeasonOffset = math.random(-kMaxSeasonOffset_UI, kMaxSeasonOffset_UI);
		Game:SetProperty("iThisSeasonOffset", iThisSeasonOffset);
		
		iThisSeasonChangeTurn = kStartTurn + kSeasonLength + iThisSeasonOffset;
		Game:SetProperty("iThisSeasonChangeTurn", iThisSeasonChangeTurn);

		iThisSeasonSeverity = kStartSeverity_UI;
		Game:SetProperty("iThisSeasonSeverity", iThisSeasonSeverity);
		
		sThisSeason = GetSeason(iSeasonCounter);
		Game:SetProperty("sThisSeason", sThisSeason);
		
		sNextSeason_UI = sThisSeason;
		Game:SetProperty("sNextSeason_UI", sNextSeason_UI);

		-- used only for UI, not in this file
		iSeasonChangeTurnNoOffset_UI = kStartTurn + kSeasonLength;
		Game:SetProperty("iSeasonChangeTurnNoOffset_UI", iSeasonChangeTurnNoOffset_UI);
		
	-- old game loaded
	else
		bSeasonChange_UI = Game:GetProperty("bSeasonChange_UI");

		iSeasonCounter = Game:GetProperty("iSeasonCounter");
		iThisSeasonOffset = Game:GetProperty("iThisSeasonOffset");
		iThisSeasonChangeTurn = Game:GetProperty("iThisSeasonChangeTurn");
		iNextSeasonChangeTurn = Game:GetProperty("iNextSeasonChangeTurn");
		iNextSeasonSeverity_UI = Game:GetProperty("iNextSeasonSeverity_UI");
		iThisSeasonSeverity = Game:GetProperty("iThisSeasonSeverity");

		sThisSeason = Game:GetProperty("sThisSeason");
		sNextSeason_UI = Game:GetProperty("iNextSeasonSeverity_UI");
	end
end


-- ===========================================================================
-- Apply season changes when season change turn is reached.
-- ===========================================================================
function FourSeasons()	
	local iCurrentTurn =  Game.GetCurrentGameTurn();

	-- Game properties are set one turn before the season change for the UI
	if iCurrentTurn == iThisSeasonChangeTurn - 1 then
		UpdateGameProperties();
		
	elseif iCurrentTurn == iThisSeasonChangeTurn and bSeasonChange_UI then
		iThisSeasonChangeTurn = iNextSeasonChangeTurn;
		Game:SetProperty("iThisSeasonChangeTurn", iThisSeasonChangeTurn);

		local sLastSeason = GetSeason(iSeasonCounter);

		iSeasonCounter = iSeasonCounter + 1;
		Game:SetProperty("iSeasonCounter", iSeasonCounter);
		
		sThisSeason = GetSeason(iSeasonCounter);
		Game:SetProperty("sThisSeason", sThisSeason);

		AttachModifiers(iThisSeasonSeverity, sLastSeason, true);
		AttachModifiers(iNextSeasonSeverity_UI, sThisSeason, false);

		iThisSeasonSeverity = iNextSeasonSeverity_UI;
		Game:SetProperty("iThisSeasonSeverity", iThisSeasonSeverity);
		
		bSeasonChange_UI = false;
		Game:SetProperty("bSeasonChange_UI", bSeasonChange_UI);
	end
end


-- ===========================================================================
-- Set game properties for the UI.
-- ===========================================================================
function UpdateGameProperties()
	bSeasonChange_UI = true;
	Game:SetProperty("bSeasonChange_UI", bSeasonChange_UI);
	
	sNextSeason_UI = GetSeason(iSeasonCounter + 1);
	Game:SetProperty("sNextSeason_UI", sNextSeason_UI);
	
	iThisSeasonSeverity = Game:GetProperty("iThisSeasonSeverity");

	iNextSeasonSeverity_UI = GetNewSeverity(sNextSeason_UI, iThisSeasonSeverity);
	Game:SetProperty("iNextSeasonSeverity_UI", iNextSeasonSeverity_UI);

	if Players[Game.GetLocalPlayer()] == nil then
		bAutoplayEnabled = true;
		Game:SetProperty("bAutoplayEnabled", bAutoplayEnabled);
	else
		bAutoplayEnabled = false;
		Game:SetProperty("bAutoplayEnabled", bAutoplayEnabled);
		-- starts at 0, ends at 8
		local iCurrentEra = Players[Game.GetLocalPlayer()]:GetEra();
		iWearinessEraFactor_UI = GetWearinessEraFactor(iCurrentEra);
		if Game:GetProperty("iWearinessEraFactor_UI") ~= nil then
			if iWearinessEraFactor_UI ~= Game:GetProperty("iWearinessEraFactor_UI") then
				bEraFactorChange = true;
			else
				bEraFactorChange = false;
			end
			Game:SetProperty("bEraFactorChange", bEraFactorChange);
		end
		Game:SetProperty("iWearinessEraFactor_UI", iWearinessEraFactor_UI);
	end

	local iNextSeasonOffset = math.random(-kMaxSeasonOffset_UI, kMaxSeasonOffset_UI);
	local iCurrentTurn =  Game.GetCurrentGameTurn();
	iNextSeasonChangeTurn = iCurrentTurn - iThisSeasonOffset + kSeasonLength + iNextSeasonOffset + 1;
	Game:SetProperty("iNextSeasonChangeTurn", iNextSeasonChangeTurn);
	
	iThisSeasonOffset = iNextSeasonOffset;
	Game:SetProperty("iThisSeasonOffset", iThisSeasonOffset);
	
	-- used only for UI, not in this file
	iSeasonChangeTurnNoOffset_UI = iNextSeasonChangeTurn - iThisSeasonOffset;
	Game:SetProperty("iSeasonChangeTurnNoOffset_UI", iSeasonChangeTurnNoOffset_UI);
end


-- ===========================================================================
-- Returns the current season as a string.
-- ===========================================================================
function GetSeason(iCounter)
	local iSeasonInterval = math.fmod(iCounter, 4);
	
	if iSeasonInterval == 1 then 
		return "SUMMER";
		
	elseif iSeasonInterval == 2 then 
		return "AUTUMN";
		
	elseif iSeasonInterval == 3 then 
		return "WINTER";
		
	elseif iSeasonInterval == 0 then 
		return "SPRING";
	end
end


-- ===========================================================================
-- Returns the severity of the new season as a randomized number based on the severity of the last season and the severity bias.
-- Note that sSeason is the current season while iSeverity is from the last season
-- ===========================================================================
function GetNewSeverity(sSeason, iSeverity)
	local tProbabilities = {};
	-- the probability for severity 6 in winter is always "taken away" from severity 5
	if sSeason == "WINTER" then
		--	kSeverityBias	    1						  2						    3					 	  4				 	   		5
		if iSeverity == 1 then
			tProbabilities = { {50, 20, 10, 10,  9,  1}, {30, 30, 20, 10,  8,  2}, {20, 40, 20, 10,  8,  2}, {20, 20, 20, 20, 18,  2}, {10, 20, 30, 30,  7,  3} };
				
		elseif iSeverity == 2 then
			tProbabilities = { {40, 20, 20, 10,  8,  2}, {20, 40, 20, 10,  7,  3}, {20, 30, 30, 10,  6,  4}, {10, 20, 30, 20, 15,  5}, {10, 20, 20, 30, 14,  6} };
				
		elseif iSeverity == 3 then
			tProbabilities = { {30, 30, 20, 10,  7,  3}, {20, 30, 20, 20,  6,  4}, {10, 20, 40, 20,  5,  5}, {10, 20, 20, 30, 12,  8}, {10, 10, 20, 30, 21,  9} };
				
		elseif iSeverity == 4 then
			tProbabilities = { {20, 30, 20, 20,  6,  4}, {20, 20, 30, 20,  5,  5}, {10, 10, 30, 30, 11,  9}, {10, 10, 20, 40, 10, 10}, {10, 10, 20, 20, 28, 12} };
		
		else
			tProbabilities = { {10, 30, 30, 20,  5,  5}, {20, 20, 20, 20, 11,  9}, {10, 10, 20, 40, 10, 10}, {10, 10, 20, 30, 18, 12}, {10, 10, 10, 20, 35, 15} };
		end
	else
		-- added up, the probabilities don't necessarily need to be 100 but it is nicer
		--	kSeverityBias	    1					  2						3					  4				 	    5
		if iSeverity == 1 then
			tProbabilities = { {50, 20, 10, 10, 10}, {30, 30, 20, 10, 10}, {20, 40, 20, 10, 10}, {20, 20, 20, 20, 20}, {10, 20, 30, 30, 10} };
				
		elseif iSeverity == 2 then
			tProbabilities = { {40, 20, 20, 10, 10}, {20, 40, 20, 10, 10}, {20, 30, 30, 10, 10}, {10, 20, 30, 20, 20}, {10, 20, 20, 30, 20} };
				
		elseif iSeverity == 3 then
			tProbabilities = { {30, 30, 20, 10, 10}, {20, 30, 20, 20, 10}, {10, 20, 40, 20, 10}, {10, 20, 20, 30, 20}, {10, 10, 20, 30, 30} };
				
		elseif iSeverity == 4 then
			tProbabilities = { {20, 30, 20, 20, 10}, {20, 20, 30, 20, 10}, {10, 10, 30, 30, 20}, {10, 10, 20, 40, 20}, {10, 10, 20, 20, 40} };
		
		else
			tProbabilities = { {10, 30, 30, 20, 10}, {20, 20, 20, 20, 20}, {10, 10, 20, 40, 20}, {10, 10, 20, 30, 30}, {10, 10, 10, 20, 50} };
		end
	end

	local tDistribution = {};
	for iSeverity, iProbability in pairs(tProbabilities[kSeverityBias]) do
		for i = iProbability, 1, -1 do
			table.insert(tDistribution, iSeverity);
		end
	end

	-- choose table based on severity bias and return a random number from it
	return tDistribution[math.random(GetTableLength(tDistribution))];
end


-- ===========================================================================
-- Returns length of given table.
-- ===========================================================================
function GetTableLength(tTable)
	local iCounter = 0;
	for _ in pairs(tTable) do 
		iCounter = iCounter + 1;
	end
	return iCounter;
end


-- ===========================================================================
-- Returns the weariness factor based on the current era.
-- ===========================================================================
function GetWearinessEraFactor(iEra)
	-- industrial and later
	if iEra >= 4 then
		return 3;
	-- medieval and renaissance
	elseif iEra >= 2 then
		return 2;
	-- ancient and classical
	else
		return 1;
	end
end


-- ===========================================================================
-- Returns two values that are used in the Attach Modifiers functions.
-- ===========================================================================
function GetOverallFactor(bUndo)
	if bUndo then
		return -1;
	else
		return 1;
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
-- Attaches Summer modifiers based on Summer Severity.
-- ===========================================================================
function AttachModifiers(iSeverity, sSeason, bUndo)
	local iSeasonIndex = GetSeasonIndex(sSeason);
	local iOverallFactor = GetOverallFactor(bUndo);
	local pPlayers = Game.GetPlayers();

	for _, pPlayer in pairs(pPlayers) do
		-- UNITS
		-- For optimization. Attaching modifiers has an impact on performance, so amount of modifiers attached is minimized
		if kExperienceEffects_UI[iSeasonIndex][iSeverity] ~= 0 then
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_UNIT_EXPERIENCE_BY_" .. tostring(kExperienceEffects_UI[iSeasonIndex][iSeverity] * iOverallFactor));
		end
		if kHealingEffects_UI[iSeasonIndex][iSeverity] ~= 0 then
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_HEAL_PER_TURN_BY_" .. tostring(kHealingEffects_UI[iSeasonIndex][iSeverity] * iOverallFactor));
		end
		if kMaintenanceEffects_UI[iSeasonIndex][iSeverity] ~= 0 then
			-- a negative value increases the maintenance because it reduces the maintenance discount, hence the multiplication by -1
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_ADJUST_UNIT_MAINTENANCE_DISCOUNT_BY_" .. tostring(kMaintenanceEffects_UI[iSeasonIndex][iSeverity] * iOverallFactor * -1));
		end
		if kMovementEffects_UI[iSeasonIndex][iSeverity] ~= 0 then
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_MOVEMENT_BY_" .. tostring(kMovementEffects_UI[iSeasonIndex][iSeverity] * iOverallFactor));
			-- undo movement change for sea units (because the modifier above applies to all units) and apply separate movement change instead
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_SEA_MOVEMENT_BY_" .. tostring(kMovementEffects_UI[iSeasonIndex][iSeverity] * iOverallFactor * -1));
		end
		if kSeaMovementEffects_UI[iSeasonIndex][iSeverity] ~= 0 then
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_SEA_MOVEMENT_BY_" .. tostring(kSeaMovementEffects_UI[iSeasonIndex][iSeverity] * iOverallFactor));
		end
		-- CITIES
		-- For optimization. Cycling through every city costs performance
		if kFoodEffects_UI[iSeasonIndex][iSeverity] ~= 0 or kProductionEffects_UI[iSeasonIndex][iSeverity] ~= 0 then
			local pPlayerCities = pPlayer:GetCities();
			for _, pCity in pPlayerCities:Members() do
				if kFoodEffects_UI[iSeasonIndex][iSeverity] ~= 0 then
					pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_FOOD_YIELD_BY_" .. tostring(kFoodEffects_UI[iSeasonIndex][iSeverity] * iOverallFactor));
				end
				if kProductionEffects_UI[iSeasonIndex][iSeverity] ~= 0 then
					pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_PRODUCTION_YIELD_BY_" .. tostring(kProductionEffects_UI[iSeasonIndex][iSeverity] * iOverallFactor));
				end
			end
		end
		-- WARS
		if kWearinessEffects_UI[iSeasonIndex][iSeverity] ~= 0 then
			bAutoplayEnabled = Game:GetProperty("bAutoplayEnabled");
			if bAutoplayEnabled then
				iWearinessEraFactor_UI = 2;
			else
				bEraFactorChange = Game:GetProperty("bEraFactorChange");
				if bEraFactorChange and bUndo then
					iWearinessEraFactor_UI = Game:GetProperty("iWearinessEraFactor_UI") - 1;
				else
					iWearinessEraFactor_UI = Game:GetProperty("iWearinessEraFactor_UI");
				end
			end
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_ADJUST_WAR_WEARINESS_BY_" .. tostring(kWearinessEffects_UI[iSeasonIndex][iSeverity] * iOverallFactor * iWearinessEraFactor_UI));
		end
	end
end


-- ===========================================================================
-- Attach plot yield modifiers to cities that are newly founded.
-- The first two place holder arguments are PlayerID and CityID.
-- ===========================================================================
function OnCityBuilt(_, _, iPlotX, iPlotY)
	sThisSeason = Game:GetProperty("sThisSeason");
	local iSeasonIndex = GetSeasonIndex(sThisSeason);
	iThisSeasonSeverity = Game:GetProperty("iThisSeasonSeverity");

	-- attach food and production modifiers to the newly founded city if there are effects
	local pCity = Cities.GetCityInPlot(iPlotX, iPlotY);
	if kFoodEffects_UI[iSeasonIndex][iThisSeasonSeverity] ~= 0 then
		pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_FOOD_YIELD_BY_" .. tostring(kFoodEffects_UI[iSeasonIndex][iThisSeasonSeverity]));
	end
	if kProductionEffects_UI[iSeasonIndex][iThisSeasonSeverity] ~= 0 then
		pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_PRODUCTION_YIELD_BY_" .. tostring(kProductionEffects_UI[iSeasonIndex][iThisSeasonSeverity]));
	end
end


Events.LoadScreenClose.Add(CheckGameLoad);
Events.TurnBegin.Add(FourSeasons);
GameEvents.CityBuilt.Add(OnCityBuilt);