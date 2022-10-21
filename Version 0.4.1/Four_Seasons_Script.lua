-- ===========================================================================
-- Four_Seasons_Script
-- Author: sharpNd
-- 2022-07-11
-- Version 0.4.1
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

local iSeasonCounter;
local iThisSeasonOffset;
local iThisSeasonChangeTurn;
local iNextSeasonChangeTurn;
local iThisSeasonSeverity;
local iNextSeasonSeverity_UI;

local sThisSeason;
local sNextSeason_UI;

-- These tables provide the effect values. You only have to edit the values here and both Gameplay and UI (except Civilopedia) adjust automatically.
-- (!) Make sure that Four_Seasons_Modifiers.xml has the modifiers needed if you set values that go out of the default range, e.g. increase / decrease food yield by 4.
-- You should also keep Four_Seasons_Civilopedia_Text.xml updated with changes because it is not dynamic. But in the end the pedia it not essential, just an extra detail
-- SUMMER
-- Severity							 	 	 1		 2		 3		 4	   	 5
-- UNITS
local kSummerExperienceEffects_UI = 	{  -60,    -40,    -20, 	 0, 	 0	};
local kSummerHealingEffects_UI = 		{	10, 	 5, 	 5, 	 0, 	 0	};
local kSummerMaintenanceEffects_UI = 	{	 0,  	 0, 	 0, 	 0, 	 1	};
local kSummerMovementEffects_UI = 		{ 	 1, 	 1, 	 0, 	 0, 	 0	};
local kSummerSeaMovementEffects_UI = 	{ 	 0, 	 0, 	 0, 	 0, 	 0	};
-- CITIES
local kSummerFoodEffects_UI = 			{	 1, 	 1, 	 0, 	 0, 	-1	};
local kSummerProductionEffects_UI = 	{ 	 1, 	 0, 	 0, 	 0, 	 0	};
-- WARS
local kSummerWearinessEffects_UI = 		{    0, 	 0, 	 0, 	 0, 	 0	};
-- AUTUMN
-- Severity							 	 	 1		 2		 3		 4	   	 5
-- UNITS
local kAutumnExperienceEffects_UI = 	{	 0, 	 0, 	20, 	40, 	40	};
local kAutumnHealingEffects_UI = 		{	 0,      0, 	-5, 	-5,     -5	};
local kAutumnMaintenanceEffects_UI = 	{	 0,  	 0, 	 1, 	 1, 	 2	};
local kAutumnMovementEffects_UI = 		{ 	 0, 	 0, 	 0, 	-1, 	-1	};
local kAutumnSeaMovementEffects_UI = 	{ 	 0, 	 0, 	 0, 	 0, 	 0	};
-- CITIES
local kAutumnFoodEffects_UI = 			{	 1, 	 0, 	 0, 	-1, 	-1	};
local kAutumnProductionEffects_UI = 	{ 	 0, 	 0, 	 0, 	 0, 	-1	};
-- WARS
local kAutumnWearinessEffects_UI = 		{ 	 0, 	 0, 	 0, 	16, 	16	};
-- WINTER
-- Severity							 	 	 1		 2		 3		 4	   	 5		6
-- UNITS
local kWinterExperienceEffects_UI = 	{	20, 	40, 	40, 	60, 	80,	  100	};
local kWinterHealingEffects_UI = 		{	-5, 	-5, 	-5,    -10,    -10,	  -15	};
local kWinterMaintenanceEffects_UI = 	{	 1,      1, 	 2, 	 3, 	 4, 	5	};
local kWinterMovementEffects_UI = 		{ 	 0, 	-1, 	-1, 	-1, 	-2,	   -2	};
local kWinterSeaMovementEffects_UI = 	{ 	 0, 	 0, 	 0,  	-1, 	-1,	   -2	};
-- CITIES
local kWinterFoodEffects_UI = 			{	-1, 	-1, 	-1, 	-2, 	-2,	   -3	};
local kWinterProductionEffects_UI = 	{ 	 0, 	 0, 	-1, 	-1, 	-1,	   -2	};
-- WARS
local kWinterWearinessEffects_UI = 		{ 	 0, 	16, 	16, 	32, 	32,	   48	};
-- SPRING
-- Severity							 	 	 1		 2		 3		 4	   	 5
-- UNITS
local kSpringExperienceEffects_UI = 	{  -20, 	 0, 	 0,  	20, 	40	};
local kSpringHealingEffects_UI = 		{	 5, 	 0, 	 0, 	-5, 	-5	};
local kSpringMaintenanceEffects_UI = 	{	 0, 	 0, 	 1, 	 1, 	 2	};
local kSpringMovementEffects_UI = 		{	 0, 	 0, 	 0, 	 0, 	-1	};
local kSpringSeaMovementEffects_UI = 	{	 0, 	 0, 	 0, 	 0, 	 0	};
-- CITIES
local kSpringFoodEffects_UI = 			{	 0, 	 0, 	-1, 	-1, 	-1	};
local kSpringProductionEffects_UI = 	{	 0, 	 0, 	 0, 	 0, 	 0	};
-- WARS
local kSpringWearinessEffects_UI = 		{	 0, 	 0, 	 0, 	 0, 	16	};

-- SUMMER
Game:SetProperty("kSummerExperienceEffects_UI", 	kSummerExperienceEffects_UI);
Game:SetProperty("kSummerHealingEffects_UI", 		kSummerHealingEffects_UI);
Game:SetProperty("kSummerMaintenanceEffects_UI", 	kSummerMaintenanceEffects_UI);
Game:SetProperty("kSummerMovementEffects_UI", 		kSummerMovementEffects_UI);
Game:SetProperty("kSummerSeaMovementEffects_UI", 	kSummerSeaMovementEffects_UI);
Game:SetProperty("kSummerFoodEffects_UI", 			kSummerFoodEffects_UI);
Game:SetProperty("kSummerProductionEffects_UI", 	kSummerProductionEffects_UI);
Game:SetProperty("kSummerWearinessEffects_UI", 		kSummerWearinessEffects_UI);
-- AUTUMN
Game:SetProperty("kAutumnExperienceEffects_UI", 	kAutumnExperienceEffects_UI);
Game:SetProperty("kAutumnHealingEffects_UI", 		kAutumnHealingEffects_UI);
Game:SetProperty("kAutumnMaintenanceEffects_UI", 	kAutumnMaintenanceEffects_UI);
Game:SetProperty("kAutumnMovementEffects_UI", 		kAutumnMovementEffects_UI);
Game:SetProperty("kAutumnSeaMovementEffects_UI", 	kAutumnSeaMovementEffects_UI);
Game:SetProperty("kAutumnFoodEffects_UI", 			kAutumnFoodEffects_UI);
Game:SetProperty("kAutumnProductionEffects_UI", 	kAutumnProductionEffects_UI);
Game:SetProperty("kAutumnWearinessEffects_UI", 		kAutumnWearinessEffects_UI);
-- WINTER
Game:SetProperty("kWinterExperienceEffects_UI", 	kWinterExperienceEffects_UI);
Game:SetProperty("kWinterHealingEffects_UI", 		kWinterHealingEffects_UI);
Game:SetProperty("kWinterMaintenanceEffects_UI", 	kWinterMaintenanceEffects_UI);
Game:SetProperty("kWinterMovementEffects_UI", 		kWinterMovementEffects_UI);
Game:SetProperty("kWinterSeaMovementEffects_UI", 	kWinterSeaMovementEffects_UI);
Game:SetProperty("kWinterFoodEffects_UI", 			kWinterFoodEffects_UI);
Game:SetProperty("kWinterProductionEffects_UI", 	kWinterProductionEffects_UI);
Game:SetProperty("kWinterWearinessEffects_UI", 		kWinterWearinessEffects_UI);
-- SPRING
Game:SetProperty("kSpringExperienceEffects_UI", 	kSpringExperienceEffects_UI);
Game:SetProperty("kSpringHealingEffects_UI", 		kSpringHealingEffects_UI);
Game:SetProperty("kSpringMaintenanceEffects_UI", 	kSpringMaintenanceEffects_UI);
Game:SetProperty("kSpringMovementEffects_UI", 		kSpringMovementEffects_UI);
Game:SetProperty("kSpringSeaMovementEffects_UI", 	kSpringSeaMovementEffects_UI);
Game:SetProperty("kSpringFoodEffects_UI", 			kSpringFoodEffects_UI);
Game:SetProperty("kSpringProductionEffects_UI", 	kSpringProductionEffects_UI);
Game:SetProperty("kSpringWearinessEffects_UI", 		kSpringWearinessEffects_UI);
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

		iSeasonCounter = iSeasonCounter + 1;
		Game:SetProperty("iSeasonCounter", iSeasonCounter);
		
		sThisSeason = GetSeason(iSeasonCounter);
		Game:SetProperty("sThisSeason", sThisSeason);
		
		if sThisSeason == "SUMMER" then
			AttachSpringModifiers(iThisSeasonSeverity, true);
			AttachSummerModifiers(iNextSeasonSeverity_UI, false);

		elseif sThisSeason == "AUTUMN" then
			AttachSummerModifiers(iThisSeasonSeverity, true);
			AttachAutumnModifiers(iNextSeasonSeverity_UI, false);
				
		elseif sThisSeason == "WINTER" then
			AttachAutumnModifiers(iThisSeasonSeverity, true);
			AttachWinterModifiers(iNextSeasonSeverity_UI, false);
				
		elseif sThisSeason == "SPRING" then
			AttachWinterModifiers(iThisSeasonSeverity, true);
			AttachSpringModifiers(iNextSeasonSeverity_UI, false);
		end

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
-- Returns the severity of the new season as a randomized number based on the severity of the last season.

-- last season		new season severity chance in percent
-- severity			1		2		3		4		5
-- 1				20		40		20	 	10		10
-- 2				20		30		30 		10		10
-- 3				10		20		40 		20		10
-- 4				10		10		30 		30		20
-- 5				10		10		20 		40		20
-- ===========================================================================
function GetNewSeverity(sSeason, iSeverity)
	local tDistribution = {};
	-- when changing from summer to autumn in the start of the game, act as if the start summer had a severity of 2 instead of 4 (for balance reasons)
	iSeasonCounter = Game:GetProperty("iSeasonCounter");
	if iSeasonCounter == 1 then
		tDistribution = {1, 1, 2, 2, 2, 3, 3, 3, 4, 5};
	else
	-- if autumn had a severity of 5, there is a 10% chance that the winter will have a severity 6
		if sSeason == "WINTER" and iSeverity == 5 then
			tDistribution = {1, 2, 3, 3, 4, 4, 4, 4, 5, 6};
		else
			if iSeverity == 1 then
				tDistribution = {1, 1, 2, 2, 2, 2, 3, 3, 4, 5};
				
			elseif iSeverity == 2 then
				tDistribution = {1, 1, 2, 2, 2, 3, 3, 3, 4, 5};
				
			elseif iSeverity == 3 then
				tDistribution = {1, 2, 2, 3, 3, 3, 3, 4, 4, 5};
				
			elseif iSeverity == 4 then
				tDistribution = {1, 2, 3, 3, 3, 4, 4, 4, 5, 5};
			-- last severity was 5 or 6 
			else
				tDistribution = {1, 2, 3, 3, 4, 4, 4, 4, 5, 5};
			end
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
-- Checks if there are any Summer effects with given Severity.
-- ===========================================================================
function HasSummerEffects(iSeverity)
	if kSummerExperienceEffects_UI[iSeverity] == 0 and kSummerHealingEffects_UI[iSeverity] == 0 and kSummerMaintenanceEffects_UI[iSeverity] == 0 and 
	kSummerMovementEffects_UI[iSeverity] == 0 and kSummerSeaMovementEffects_UI[iSeverity] == 0 and kSummerFoodEffects_UI[iSeverity] == 0 and 
	kSummerProductionEffects_UI[iSeverity] == 0 and kSummerWearinessEffects_UI[iSeverity] == 0 then
		return false;
	end
	return true;
end


-- ===========================================================================
-- Checks if there are Summer City effects with given Severity.
-- ===========================================================================
function HasSummerCityEffects(iSeverity)
	if kSummerFoodEffects_UI[iSeverity] == 0 and kSummerProductionEffects_UI[iSeverity] == 0 then
		return false;
	end
	return true;
end


-- ===========================================================================
-- Attaches Summer modifiers based on Summer Severity.
-- ===========================================================================
function AttachSummerModifiers(iSeverity, bUndo)
	if bUndo then
		iFactor = -1;
	else
		iFactor = 1;
	end
	
	-- For optimization. Attaching modifiers has an impact on performance, so amount of modifiers attached is minimized
	local bHasSummerEffects = HasSummerEffects(iSeverity);
	if bHasSummerEffects then
		local pPlayers = Game.GetPlayers();
		for _, pPlayer in pairs(pPlayers) do
			-- UNITS
			if kSummerExperienceEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_UNIT_EXPERIENCE_BY_" .. tostring(kSummerExperienceEffects_UI[iSeverity] * iFactor));
			end
			if kSummerHealingEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_HEAL_PER_TURN_BY_" .. tostring(kSummerHealingEffects_UI[iSeverity] * iFactor));
			end
			if kSummerMaintenanceEffects_UI[iSeverity] ~= 0 then
				-- a negative value increases the maintenance because it reduces the maintenance discount, hence the multiplication by -1
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_ADJUST_UNIT_MAINTENANCE_DISCOUNT_BY_" .. tostring(kSummerMaintenanceEffects_UI[iSeverity] * iFactor * -1));
			end
			if kSummerMovementEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_MOVEMENT_BY_" .. tostring(kSummerMovementEffects_UI[iSeverity] * iFactor));
				-- undo movement change for sea units (because the modifier above applies to all units) and apply separate movement change instead
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_SEA_MOVEMENT_BY_" .. tostring(kSummerMovementEffects_UI[iSeverity] * iFactor * -1));
			end
			if kSummerSeaMovementEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_SEA_MOVEMENT_BY_" .. tostring(kSummerSeaMovementEffects_UI[iSeverity] * iFactor));
			end
			-- CITIES
			-- For optimization. Cylcing through every city if its not needed is costly regarding performance
			local bHasSummerCityEffects = HasSummerCityEffects(iSeverity);
			if bHasSummerCityEffects then
				local pPlayerCities = pPlayer:GetCities();
				for _, pCity in pPlayerCities:Members() do
					if kSummerFoodEffects_UI[iSeverity] ~= 0 then
						pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_FOOD_YIELD_BY_" .. tostring(kSummerFoodEffects_UI[iSeverity] * iFactor));
					end
					if kSummerProductionEffects_UI[iSeverity] ~= 0 then
						pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_PRODUCTION_YIELD_BY_" .. tostring(kSummerProductionEffects_UI[iSeverity] * iFactor));
					end
				end
			end
			-- WARS
			if kSummerWearinessEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_ADJUST_WAR_WEARINESS_BY_" .. tostring(kSummerWearinessEffects_UI[iSeverity] * iFactor));
			end
		end
	end
end


-- ===========================================================================
-- Checks if there are any Autumn effects with given Severity.
-- ===========================================================================
function HasAutumnEffects(iSeverity)
	if kAutumnExperienceEffects_UI[iSeverity] == 0 and kAutumnHealingEffects_UI[iSeverity] == 0 and kAutumnMaintenanceEffects_UI[iSeverity] == 0 and 
	kAutumnMovementEffects_UI[iSeverity] == 0 and kAutumnSeaMovementEffects_UI[iSeverity] == 0 and kAutumnFoodEffects_UI[iSeverity] == 0 and 
	kAutumnProductionEffects_UI[iSeverity] == 0 and kAutumnWearinessEffects_UI[iSeverity] == 0 then
		return false;
	end
	return true;
end


-- ===========================================================================
-- Checks if there are Autumn City effects with given Severity.
-- ===========================================================================
function HasAutumnCityEffects(iSeverity)
	if kAutumnFoodEffects_UI[iSeverity] == 0 and kAutumnProductionEffects_UI[iSeverity] == 0 then
		return false;
	end
	return true;
end


-- ===========================================================================
-- Attaches Autumn modifiers based on Autumn Severity.
-- ===========================================================================
function AttachAutumnModifiers(iSeverity, bUndo)
	if bUndo then
		iFactor = -1;
	else
		iFactor = 1;
	end

	local bHasAutumnEffects = HasAutumnEffects(iSeverity);
	if bHasAutumnEffects then
		local pPlayers = Game.GetPlayers();
		for _, pPlayer in pairs(pPlayers) do
			-- UNITS
			if kAutumnExperienceEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_UNIT_EXPERIENCE_BY_" .. tostring(kAutumnExperienceEffects_UI[iSeverity] * iFactor));
			end
			if kAutumnHealingEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_HEAL_PER_TURN_BY_" .. tostring(kAutumnHealingEffects_UI[iSeverity] * iFactor));
			end
			if kAutumnMaintenanceEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_ADJUST_UNIT_MAINTENANCE_DISCOUNT_BY_" .. tostring(kAutumnMaintenanceEffects_UI[iSeverity] * iFactor * -1));
			end
			if kAutumnMovementEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_MOVEMENT_BY_" .. tostring(kAutumnMovementEffects_UI[iSeverity] * iFactor));
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_SEA_MOVEMENT_BY_" .. tostring(kAutumnMovementEffects_UI[iSeverity] * iFactor * -1));
			end
			if kAutumnSeaMovementEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_SEA_MOVEMENT_BY_" .. tostring(kAutumnSeaMovementEffects_UI[iSeverity] * iFactor));
			end
			-- CITIES
			local bHasAutumnCityEffects = HasAutumnCityEffects(iSeverity);
			if bHasAutumnCityEffects then
				local pPlayerCities = pPlayer:GetCities();
				for _, pCity in pPlayerCities:Members() do
					if kAutumnFoodEffects_UI[iSeverity] ~= 0 then
						pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_FOOD_YIELD_BY_" .. tostring(kAutumnFoodEffects_UI[iSeverity] * iFactor));
					end
					if kAutumnProductionEffects_UI[iSeverity] ~= 0 then
						pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_PRODUCTION_YIELD_BY_" .. tostring(kAutumnProductionEffects_UI[iSeverity] * iFactor));
					end
				end
			end
			-- WARS
			if kAutumnWearinessEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_ADJUST_WAR_WEARINESS_BY_" .. tostring(kAutumnWearinessEffects_UI[iSeverity] * iFactor));
			end
		end
	end
end


-- ===========================================================================
-- Checks if there are any Winter effects with given Severity.
-- ===========================================================================
function HasWinterEffects(iSeverity)
	if kWinterExperienceEffects_UI[iSeverity] == 0 and kWinterHealingEffects_UI[iSeverity] == 0 and kWinterMaintenanceEffects_UI[iSeverity] == 0 and 
	kWinterMovementEffects_UI[iSeverity] == 0 and kWinterSeaMovementEffects_UI[iSeverity] == 0 and kWinterFoodEffects_UI[iSeverity] == 0 and 
	kWinterProductionEffects_UI[iSeverity] == 0 and kWinterWearinessEffects_UI[iSeverity] == 0 then
		return false;
	end
	return true;
end


-- ===========================================================================
-- Checks if there are Winter City effects with given Severity.
-- ===========================================================================
function HasWinterCityEffects(iSeverity)
	if kWinterFoodEffects_UI[iSeverity] == 0 and kWinterProductionEffects_UI[iSeverity] == 0 then
		return false;
	end
	return true;
end


-- ===========================================================================
-- Attaches Winter modifiers based on Winter Severity.
-- ===========================================================================
function AttachWinterModifiers(iSeverity, bUndo)
	if bUndo then
		iFactor = -1;
	else
		iFactor = 1;
	end
	
	local bHasWinterEffects = HasWinterEffects(iSeverity);
	if bHasWinterEffects then
		local pPlayers = Game.GetPlayers();
		for _, pPlayer in pairs(pPlayers) do
			-- UNITS
			if kWinterExperienceEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_UNIT_EXPERIENCE_BY_" .. tostring(kWinterExperienceEffects_UI[iSeverity] * iFactor));
			end
			if kWinterHealingEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_HEAL_PER_TURN_BY_" .. tostring(kWinterHealingEffects_UI[iSeverity] * iFactor));
			end
			if kWinterMaintenanceEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_ADJUST_UNIT_MAINTENANCE_DISCOUNT_BY_" .. tostring(kWinterMaintenanceEffects_UI[iSeverity] * iFactor * -1));
			end
			if kWinterMovementEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_MOVEMENT_BY_" .. tostring(kWinterMovementEffects_UI[iSeverity] * iFactor));
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_SEA_MOVEMENT_BY_" .. tostring(kWinterMovementEffects_UI[iSeverity] * iFactor * -1));
			end
			if kWinterSeaMovementEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_SEA_MOVEMENT_BY_" .. tostring(kWinterSeaMovementEffects_UI[iSeverity] * iFactor));
			end
			-- CITIES
			local bHasWinterCityEffects = HasWinterCityEffects(iSeverity);
			if bHasWinterCityEffects then
				local pPlayerCities = pPlayer:GetCities();
				for _, pCity in pPlayerCities:Members() do
					if kWinterFoodEffects_UI[iSeverity] ~= 0 then
						pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_FOOD_YIELD_BY_" .. tostring(kWinterFoodEffects_UI[iSeverity] * iFactor));
					end
					if kWinterProductionEffects_UI[iSeverity] ~= 0 then
						pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_PRODUCTION_YIELD_BY_" .. tostring(kWinterProductionEffects_UI[iSeverity] * iFactor));
					end
				end
			end
			-- WARS
			if kWinterWearinessEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_ADJUST_WAR_WEARINESS_BY_" .. tostring(kWinterWearinessEffects_UI[iSeverity] * iFactor));
			end
		end
	end
end


-- ===========================================================================
-- Checks if there are any Spring effects with given Severity.
-- ===========================================================================
function HasSpringEffects(iSeverity)
	if kSpringExperienceEffects_UI[iSeverity] == 0 and kSpringHealingEffects_UI[iSeverity] == 0 and kSpringMaintenanceEffects_UI[iSeverity] == 0 and 
	kSpringMovementEffects_UI[iSeverity] == 0 and kSpringSeaMovementEffects_UI[iSeverity] == 0 and kSpringFoodEffects_UI[iSeverity] == 0 and 
	kSpringProductionEffects_UI[iSeverity] == 0 and kSpringWearinessEffects_UI[iSeverity] == 0 then
		return false;
	end
	return true;
end


-- ===========================================================================
-- Checks if there are Spring City effects with given Severity.
-- ===========================================================================
function HasSpringCityEffects(iSeverity)
	if kSpringFoodEffects_UI[iSeverity] == 0 and kSpringProductionEffects_UI[iSeverity] == 0 then
		return false;
	end
	return true;
end


-- ===========================================================================
-- Attaches Spring modifiers based on Spring Severity.
-- ===========================================================================
function AttachSpringModifiers(iSeverity, bUndo)
	if bUndo then
		iFactor = -1;
	else
		iFactor = 1;
	end

	local bHasSpringEffects = HasSpringEffects(iSeverity);
	if bHasSpringEffects then
		local pPlayers = Game.GetPlayers();
		for _, pPlayer in pairs(pPlayers) do
			-- UNITS
			if kSpringExperienceEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_UNIT_EXPERIENCE_BY_" .. tostring(kSpringExperienceEffects_UI[iSeverity] * iFactor));
			end
			if kSpringHealingEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_HEAL_PER_TURN_BY_" .. tostring(kSpringHealingEffects_UI[iSeverity] * iFactor));
			end
			if kSpringMaintenanceEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_ADJUST_UNIT_MAINTENANCE_DISCOUNT_BY_" .. tostring(kSpringMaintenanceEffects_UI[iSeverity] * iFactor * -1));
			end
			if kSpringMovementEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_MOVEMENT_BY_" .. tostring(kSpringMovementEffects_UI[iSeverity] * iFactor));
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_SEA_MOVEMENT_BY_" .. tostring(kSpringMovementEffects_UI[iSeverity] * iFactor * -1));
			end
			if kSpringSeaMovementEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_UNITS_ADJUST_SEA_MOVEMENT_BY_" .. tostring(kSpringSeaMovementEffects_UI[iSeverity] * iFactor));
			end
			-- CITIES
			local bHasSpringCityEffects = HasSpringCityEffects(iSeverity);
			if bHasSpringCityEffects then
				local pPlayerCities = pPlayer:GetCities();
				for _, pCity in pPlayerCities:Members() do
					if kSpringFoodEffects_UI[iSeverity] ~= 0 then
						pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_FOOD_YIELD_BY_" .. tostring(kSpringFoodEffects_UI[iSeverity] * iFactor));
					end
					if kSpringProductionEffects_UI[iSeverity] ~= 0 then
						pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_PRODUCTION_YIELD_BY_" .. tostring(kSpringProductionEffects_UI[iSeverity] * iFactor));
					end
				end
			end
			-- WARS
			if kSpringWearinessEffects_UI[iSeverity] ~= 0 then
				pPlayer:AttachModifierByID("FOUR_SEASONS_PLAYER_ADJUST_WAR_WEARINESS_BY_" .. tostring(kSpringWearinessEffects_UI[iSeverity] * iFactor));
			end
		end
	end
end


-- ===========================================================================
-- Attach plot yield modifiers to cities that are newly founded.
-- iPlayerID and iCityID are not used but are required as place holders.
-- ===========================================================================
function OnCityBuilt(iPlayerID, iCityID, iPlotX, iPlotY)
	local pCity = Cities.GetCityInPlot(iPlotX, iPlotY);
	sThisSeason = Game:GetProperty("sThisSeason");
	iThisSeasonSeverity = Game:GetProperty("iThisSeasonSeverity");
	-- attach food and production modifiers to the newly founded city if there are effects
	if sThisSeason == "SUMMER" then
		if kSummerFoodEffects_UI[iThisSeasonSeverity] ~= 0 then
			pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_FOOD_YIELD_BY_" .. tostring(kSummerFoodEffects_UI[iThisSeasonSeverity]));
		end
		if kSummerProductionEffects_UI[iThisSeasonSeverity] ~= 0 then
			pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_PRODUCTION_YIELD_BY_" .. tostring(kSummerProductionEffects_UI[iThisSeasonSeverity]));
		end

	elseif sThisSeason == "AUTUMN" then
		if kAutumnFoodEffects_UI[iThisSeasonSeverity] ~= 0 then
			pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_FOOD_YIELD_BY_" .. tostring(kAutumnFoodEffects_UI[iThisSeasonSeverity]));
		end
		if kAutumnProductionEffects_UI[iThisSeasonSeverity] ~= 0 then
			pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_PRODUCTION_YIELD_BY_" .. tostring(kAutumnProductionEffects_UI[iThisSeasonSeverity]));
		end

	elseif sThisSeason == "WINTER" then
		if kWinterFoodEffects_UI[iThisSeasonSeverity] ~= 0 then
			pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_FOOD_YIELD_BY_" .. tostring(kWinterFoodEffects_UI[iThisSeasonSeverity]));
		end
		if kWinterProductionEffects_UI[iThisSeasonSeverity] ~= 0 then
			pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_PRODUCTION_YIELD_BY_" .. tostring(kWinterProductionEffects_UI[iThisSeasonSeverity]));
		end

	elseif sThisSeason == "SPRING" then
		if kSpringFoodEffects_UI[iThisSeasonSeverity] ~= 0 then
			pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_FOOD_YIELD_BY_" .. tostring(kSpringFoodEffects_UI[iThisSeasonSeverity]));
		end
		if kSpringProductionEffects_UI[iThisSeasonSeverity] ~= 0 then
			pCity:AttachModifierByID("FOUR_SEASONS_CITY_PLOT_YIELDS_ADJUST_PRODUCTION_YIELD_BY_" .. tostring(kSpringProductionEffects_UI[iThisSeasonSeverity]));
		end
	end
end


Events.LoadScreenClose.Add(CheckGameLoad);
Events.TurnBegin.Add(FourSeasons);
GameEvents.CityBuilt.Add(OnCityBuilt);