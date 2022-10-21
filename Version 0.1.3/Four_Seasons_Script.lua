-- ===========================================================================
-- Four_Seasons_Script
-- Author: sharpNd
-- 2022-05-10
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
-- _UI = values that are set in the Gameplay script and called in the UI script
-- ===========================================================================


-- ===========================================================================
local kSeasonLength = GameConfiguration.GetValue("iSeasonLength");

-- Keep this value between [0, 0.5[
local kSeasonOffsetFloat = 0.25;
local kMaxSeasonOffset = math.floor(kSeasonLength * kSeasonOffsetFloat);
Game:SetProperty("kMaxSeasonOffset_UI", kMaxSeasonOffset);

local kStartTurn = GameConfiguration.GetStartTurn();

-- This value is used as if the spring before the start of the game had this severity
-- Can be set to something from 1 to 5
local kStartSeverity = 3;

-- no need to keep updated
local iNextSeasonOffset;

-- keep these variables updated with Game:SetProperty at all times
local bSeasonChange_UI;

local iSeasonCounter;
local iThisSeasonOffset;
local iSeasonChangeTurn;
local iNewSeasonSeverity_UI;
local iLastSeasonSeverity;

local sCurrentSeason;
local sNextTurnSeason_UI;
-- ===========================================================================


-- ===========================================================================
-- Check if the game just started or if it was loaded from a save file.
-- ===========================================================================
function CheckGameLoad()
	-- new game started
	if Game:GetProperty("iSeasonCounter") == nil then
		iSeasonCounter = 1;
		Game:SetProperty("iSeasonCounter", iSeasonCounter);
		
		iThisSeasonOffset = math.random(-kMaxSeasonOffset, kMaxSeasonOffset);
		Game:SetProperty("iThisSeasonOffset", iThisSeasonOffset);
		
		iSeasonChangeTurn = kStartTurn + kSeasonLength + iThisSeasonOffset;
		Game:SetProperty("iSeasonChangeTurn", iSeasonChangeTurn);
		
		iLastSeasonSeverity = kStartSeverity;
		Game:SetProperty("iLastSeasonSeverity", iLastSeasonSeverity);
		
		sCurrentSeason = GetSeason(iSeasonCounter);
		Game:SetProperty("sCurrentSeason", sCurrentSeason);
		
		sNextTurnSeason_UI = sCurrentSeason;
		Game:SetProperty("sNextTurnSeason_UI", sCurrentSeason);
		
	-- old game loaded
	else
		bSeasonChange_UI = Game:GetProperty("bSeasonChange_UI");

		iSeasonCounter = Game:GetProperty("iSeasonCounter");
		iThisSeasonOffset = Game:GetProperty("iThisSeasonOffset");
		iSeasonChangeTurn = Game:GetProperty("iSeasonChangeTurn");
		iNewSeasonSeverity_UI = Game:GetProperty("iNewSeasonSeverity_UI");
		iLastSeasonSeverity = Game:GetProperty("iLastSeasonSeverity");

		sCurrentSeason = Game:GetProperty("sCurrentSeason");
		sNextTurnSeason_UI = Game:GetProperty("iNewSeasonSeverity_UI");
	end
end


-- ===========================================================================
-- Apply season changes when season change turn is reached.
-- ===========================================================================
function FourSeasons()	
	local iCurrentTurn =  Game.GetCurrentGameTurn();
	
	-- Game properties are set one turn before the season change for the UI
	if iCurrentTurn == iSeasonChangeTurn - 1 then
		UpdateGameProperties();
		
	elseif bSeasonChange_UI then
		iSeasonCounter = iSeasonCounter + 1;
		Game:SetProperty("iSeasonCounter", iSeasonCounter);
		
		sCurrentSeason = GetSeason(iSeasonCounter);
		Game:SetProperty("sCurrentSeason", sCurrentSeason);
		
		if sCurrentSeason == "SUMMER" then
			AttachSpringModifiers(iLastSeasonSeverity, true);
		else
			if sCurrentSeason == "AUTUMN" then
				AttachAutumnModifiers(iNewSeasonSeverity_UI, false);
			
			elseif sCurrentSeason == "WINTER" then
				AttachAutumnModifiers(iLastSeasonSeverity, true);
				AttachWinterModifiers(iNewSeasonSeverity_UI, false);
			
			elseif sCurrentSeason == "SPRING" then
				AttachWinterModifiers(iLastSeasonSeverity, true);
				AttachSpringModifiers(iNewSeasonSeverity_UI, false);
			end

			iLastSeasonSeverity = iNewSeasonSeverity_UI;
			Game:SetProperty("iLastSeasonSeverity", iLastSeasonSeverity);
		end
		
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
	
	sNextTurnSeason_UI = GetSeason(iSeasonCounter + 1);
	Game:SetProperty("sNextTurnSeason_UI", sNextTurnSeason_UI);
	
	iLastSeasonSeverity = Game:GetProperty("iLastSeasonSeverity");
	
	if sNextTurnSeason_UI ~= "SUMMER" then
		iNewSeasonSeverity_UI = GetNewSeverity(sNextTurnSeason_UI, iLastSeasonSeverity);
	else
		iNewSeasonSeverity_UI = iLastSeasonSeverity;
	end
	
	-- used only for UI, not in this file
	Game:SetProperty("iNewSeasonSeverity_UI", iNewSeasonSeverity_UI);

	iNextSeasonOffset = math.random(-kMaxSeasonOffset, kMaxSeasonOffset);

	local iCurrentTurn =  Game.GetCurrentGameTurn();

	iSeasonChangeTurn = iCurrentTurn - iThisSeasonOffset + kSeasonLength + iNextSeasonOffset + 1;
	Game:SetProperty("iSeasonChangeTurn", iSeasonChangeTurn);
	
	iThisSeasonOffset = iNextSeasonOffset;
	Game:SetProperty("iThisSeasonOffset", iThisSeasonOffset);
	
	-- used only for UI, not in this file
	Game:SetProperty("iSeasonChangeTurnNoOffset_UI", iSeasonChangeTurn - iThisSeasonOffset);
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
-- Returns the severity of the new season as a 'randomized' number based on the severity of the last season.

-- last season		new season severity chance in percent
-- severity			1		2		3		4		5
-- 1				30		40		30	 	0		0
-- 2				20		30		40 		10		0
-- 3				10		20		40 		20		10
-- 4				0		10		40 		30		20
-- 5				0		0		30 		40		30
-- ===========================================================================
function GetNewSeverity(sSeason, iSeverity)
	local tDistribution = {};
	
	-- if autumn had a severity of 4 (or 5), there is a 5% (or 10%) chance that the winter will have a severity 6
	if sSeason == "WINTER" and iSeverity > 3 then
		if iSeverity == 4 then
			tDistribution = {2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 5, 5, 5, 6};
			
		elseif iSeverity == 5 then
			tDistribution = {3, 3, 3, 4, 4, 4, 4, 5, 5, 6};
		end
	else
		if iSeverity == 1 then
			tDistribution = {1, 1, 1, 2, 2, 2, 2, 3, 3, 3};
			
		elseif iSeverity == 2 then
			tDistribution = {1, 1, 2, 2, 2, 3, 3, 3, 3, 4};
			
		elseif iSeverity == 3 then
			tDistribution = {1, 2, 2, 3, 3, 3, 3, 4, 4, 5};
			
		elseif iSeverity == 4 then
			tDistribution = {2, 3, 3, 3, 3, 4, 4, 4, 5, 5};
			
		else
			tDistribution = {3, 3, 3, 4, 4, 4, 4, 5, 5, 5};
		end
	end
	
	-- return a random number from the table
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
-- Attaches autumn modifiers based on autumn severity:
--				UNITS								CITY YIELDS				PLAYERS
-- severity 	healing 	maintenance	movement	food 		production	war weariness
-- 1			0			0			0			0			0			0
-- 2			-5			0			0			0			0			0
-- 3			-5			+1			-1			0			0			0
-- 4			-10			+1			-1			-1			0			+16
-- 5			-10			+2			-1			-1			-1			+16
-- ===========================================================================
function AttachAutumnModifiers(iSeverity, bUndo)
	if bUndo then
		sDefaultAction = "INCREASE";
		sReverseAction = "DECREASE";
	else
		sDefaultAction = "DECREASE";
		sReverseAction = "INCREASE";
	end
	
	local pPlayers = Game.GetPlayers();
	
	for _, pPlayer in pairs(pPlayers) do
		local pPlayerCities = pPlayer:GetCities();
		
		if iSeverity == 1 then
			-- no changes
			
		elseif iSeverity == 2 then
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_HEAL_PER_TURN_BY_5");
			
		elseif iSeverity == 3 then
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_HEAL_PER_TURN_BY_5");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sDefaultAction .. "_UNIT_MAINTENANCE_DISCOUNT_BY_1");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_MOVEMENT_BY_1");

		elseif iSeverity == 4 then
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_HEAL_PER_TURN_BY_10");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sDefaultAction .. "_UNIT_MAINTENANCE_DISCOUNT_BY_1");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_MOVEMENT_BY_1");
			
			for _, pCity in pPlayerCities:Members() do
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_FOOD_YIELD_BY_1");
				--[[local pCityPlots = pCity:GetOwnedPlots();
				for _, pPlot : object in pairs(pCityPlots) do
					if pPlot ~= nil then
						pPlot:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_FOOD_YIELD_BY_1");
					end
				end]]--
			end
			
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sReverseAction .. "_WAR_WEARINESS_BY_16");
		
		else
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_HEAL_PER_TURN_BY_10");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sDefaultAction .. "_UNIT_MAINTENANCE_DISCOUNT_BY_2");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_MOVEMENT_BY_1");
			
			for _, pCity in pPlayerCities:Members() do
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_FOOD_YIELD_BY_1");
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_PRODUCTION_YIELD_BY_1");
			end
			
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sReverseAction .. "_WAR_WEARINESS_BY_16");
		end
	end
end


-- ===========================================================================
-- Attaches winter modifiers based on winter severity:
--				UNITS								CITY YIELDS				PLAYERS
-- severity 	healing 	maintenance	movement	food 		production	war weariness
-- 1			-5			+1			0			-1			0			0
-- 2			-5			+1			-1			-1			0			+16
-- 3			-10			+2			-1			-1			-1			+16
-- 4			-10			+3			-1			-2			-1			+32
-- 5			-10			+4			-2			-3			-1			+32
-- 
-- 6			-15			+5			-2			-4			-2			+48
-- ===========================================================================
function AttachWinterModifiers(iSeverity, bUndo)
	if bUndo then
		sDefaultAction = "INCREASE";
		sReverseAction = "DECREASE";
	else
		sDefaultAction = "DECREASE";
		sReverseAction = "INCREASE";
	end
	
	local pPlayers = Game.GetPlayers();
	
	for _, pPlayer in pairs(pPlayers) do
		local pPlayerCities = pPlayer:GetCities();
	
		if iSeverity == 1 then
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_HEAL_PER_TURN_BY_5");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sDefaultAction .. "_UNIT_MAINTENANCE_DISCOUNT_BY_1");
			
			for _, pCity in pPlayerCities:Members() do
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_FOOD_YIELD_BY_1");
			end
			
		elseif iSeverity == 2 then
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_HEAL_PER_TURN_BY_5");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sDefaultAction .. "_UNIT_MAINTENANCE_DISCOUNT_BY_1");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_MOVEMENT_BY_1");
			
			for _, pCity in pPlayerCities:Members() do
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_FOOD_YIELD_BY_1");
			end
			
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sReverseAction .. "_WAR_WEARINESS_BY_16");
			
		elseif iSeverity == 3 then
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_HEAL_PER_TURN_BY_10");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sDefaultAction .. "_UNIT_MAINTENANCE_DISCOUNT_BY_2");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_MOVEMENT_BY_1");
			
			for _, pCity in pPlayerCities:Members() do
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_FOOD_YIELD_BY_1");
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_PRODUCTION_YIELD_BY_1");
			end
			
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sReverseAction .. "_WAR_WEARINESS_BY_16");
		
		elseif iSeverity == 4 then
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_HEAL_PER_TURN_BY_10");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sDefaultAction .. "_UNIT_MAINTENANCE_DISCOUNT_BY_3");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_MOVEMENT_BY_1");
			
			for _, pCity in pPlayerCities:Members() do
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_FOOD_YIELD_BY_2");
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_PRODUCTION_YIELD_BY_1");
			end
			
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sReverseAction .. "_WAR_WEARINESS_BY_32");
		
		elseif iSeverity == 5 then
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_HEAL_PER_TURN_BY_10");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sDefaultAction .. "_UNIT_MAINTENANCE_DISCOUNT_BY_4");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_MOVEMENT_BY_2");
			
			for _, pCity in pPlayerCities:Members() do
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_FOOD_YIELD_BY_3");
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_PRODUCTION_YIELD_BY_1");
			end
			
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sReverseAction .. "_WAR_WEARINESS_BY_32");
		else
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_HEAL_PER_TURN_BY_15");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sDefaultAction .. "_UNIT_MAINTENANCE_DISCOUNT_BY_5");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_MOVEMENT_BY_2");
			
			for _, pCity in pPlayerCities:Members() do
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_FOOD_YIELD_BY_4");
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_PRODUCTION_YIELD_BY_2");
			end
			
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sReverseAction .. "_WAR_WEARINESS_BY_48");
		end
	end
end


-- ===========================================================================
-- Attaches spring modifiers based on spring severity:
--				UNITS								CITY YIELDS				PLAYERS
-- severity 	healing 	maintenance	movement	food 		production	war weariness
-- 1			0			0			0			0			0			0
-- 2			0			0			0			-1			0			0
-- 3			-5			0			0			-1			0			0
-- 4			-5			0			-1			-1			0			0
-- 5			-10			+1			-1			-2			-1			+16
-- ===========================================================================
function AttachSpringModifiers(iSeverity, bUndo)
	if bUndo then
		sDefaultAction = "INCREASE";
		sReverseAction = "DECREASE";
	else
		sDefaultAction = "DECREASE";
		sReverseAction = "INCREASE";
	end
	
	local pPlayers = Game.GetPlayers();
	
	for _, pPlayer in pairs(pPlayers) do
		local pPlayerCities = pPlayer:GetCities();
		
		if iSeverity == 1 then
			-- no changes
			
		elseif iSeverity == 2 then
			for _, pCity in pPlayerCities:Members() do
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_FOOD_YIELD_BY_1");
			end
			
		elseif iSeverity == 3 then
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_HEAL_PER_TURN_BY_5");
			
			for _, pCity in pPlayerCities:Members() do
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_FOOD_YIELD_BY_1");
			end
		
		elseif iSeverity == 4 then
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_HEAL_PER_TURN_BY_5");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_MOVEMENT_BY_1");
			
			for _, pCity in pPlayerCities:Members() do
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_FOOD_YIELD_BY_1");
			end
		else
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_HEAL_PER_TURN_BY_10");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sDefaultAction .. "_UNIT_MAINTENANCE_DISCOUNT_BY_1");
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_" .. sDefaultAction .. "_MOVEMENT_BY_1");
			
			for _, pCity in pPlayerCities:Members() do
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_FOOD_YIELD_BY_2");
				pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_" .. sDefaultAction .. "_PRODUCTION_YIELD_BY_1");
			end
			
			pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_" .. sReverseAction .. "_WAR_WEARINESS_BY_16");
		end
	end
end


Events.LoadScreenClose.Add(CheckGameLoad);
Events.TurnBegin.Add(FourSeasons);