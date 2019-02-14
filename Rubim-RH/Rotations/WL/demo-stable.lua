-- Edit: Taste#0124
-- Updated to 8.1

-- Addon
local addonName, addonTable = ...

local mainAddon = RubimRH
local HL = HeroLib
local Cache = HeroCache
local Unit = HL.Unit
local Player = Unit.Player
local Target = Unit.Target
local Spell = HL.Spell
local Item = HL.Item
local Pet = Unit.Pet

RubimRH.Spell[266] = {
  -- Racials
  Berserking            = Spell(26297),
  BloodFury             = Spell(20572),
  Fireblood             = Spell(265221),
  -- Abilities
  DrainLife             = Spell(234153),
  SummonDemonicTyrant   = Spell(265187),
  SummonImp             = Spell(688),
  SummonFelguard        = Spell(30146),
  HandOfGuldan          = Spell(105174),
  ShadowBolt            = Spell(686),
  Demonbolt             = Spell(264178),
  CallDreadStalkers     = Spell(104316),
  Fear                  = Spell(5782),
  Implosion             = Spell(196277),
  Shadowfury            = Spell(30283),

  -- Pet abilities
  CauterizeMaster         = Spell(119905),--imp
  Suffering               = Spell(119907),--voidwalker
  SpellLock               = Spell(119910),--Dogi
  Whiplash                = Spell(119909),--Bitch
  AxeToss                 =  Spell(119914),--FelGuard
  FelStorm                = Spell(89751),--FelGuard

  -- Talents
  Dreadlash               = Spell(264078),
  DemonicStrength         = Spell(267171),
  BilescourgeBombers      = Spell(267211),

  DemonicCalling          = Spell(205145),
  PowerSiphon             = Spell(264130),
  Doom                    = Spell(265412),
  DoomDebuff              = Spell(265412),

  DemonSkin               = Spell(219272),
  BurningRush             = Spell(111400),
  DarkPact                = Spell(108416),

  FromTheShadows          = Spell(267170),
  SoulStrike              = Spell(264057),
  SummonVilefiend         = Spell(264119),

  Darkfury                = Spell(264874),
  MortalCoil              = Spell(6789),
  DemonicCircle           = Spell(268358),

  InnerDemons             = Spell(267216),
  SoulConduit             = Spell(215941),
  GrimoireFelguard        = Spell(111898),

  SacrificedSouls         = Spell(267214),
  DemonicConsumption      = Spell(267215),
  NetherPortal            = Spell(267217),
  NetherPortalBuff        = Spell(267218),

  -- Defensive
  UnendingResolve         = Spell(104773),

  -- Azerite
  ForbiddenKnowledge      = Spell(279666),
  BalefulInvocation       = Spell(287059),
  ExplosivePotentialBuff  = Spell(275398),
  ExplosivePotential      = Spell(275395),

  -- Utility
  TargetEnemy             = Spell(153911),
  
  -- Misc
  DemonicCallingBuff      = Spell(205146),
  DemonicCoreBuff         = Spell(264173),
  DemonicPowerBuff        = Spell(265273)
};

local S = RubimRH.Spell[266]

--Variables

-- Rotation Var
local ShouldReturn; -- Used to get the return string
local BestUnit, BestUnitTTD, BestUnitSpellToCast, DebuffRemains; -- Used for cycling

local PetsInfo = {
  [55659] = {"Wild Imp", 20},
  [99737] = {"Wild Imp", 20},
  [98035] = {"Dreadstalker", 12},
  [17252] = {"Felguard", 15},
  [135002] = {"Demonic Tyrant", 15},
};

local PetType = {
  [55659] = {"Wild Imp", 20},
  [99737] = {"Wild Imp", 20},
  [98035] = {"Dreadstalker", 12},
  [17252] = {"Felguard", 15},
  [135002] = {"Demonic Tyrant", 15},
};
	
--Guardians table
HL.GuardiansTable = {
      --{PetType,petID,dateEvent,UnitPetGUID,CastsLeft}
      Pets = {
      },
      PetList= {
	  [55659]="Wild Imp",
	  [99737]="Wild Imp",
	  [98035]="Dreadstalker",
	  [135002]="Demonic Tyrant",
	  [17252]="Felguard"}
};

-- Demono Part 1 Clean
local range = 40

-- Demono Part 2     
	HL:RegisterForSelfCombatEvent(
      function (...)
        dateEvent,_,_,_,_,_,_,UnitPetGUID=select(1,...)
       
        local t={} ; i=1
        for str in string.gmatch(UnitPetGUID, "([^-]+)") do
          t[i] = str
          i = i + 1
        end
        local PetType=HL.GuardiansTable.PetList[tonumber(t[6])]
        if PetType then
          table.insert(HL.GuardiansTable.Pets,{PetType,tonumber(t[6]),GetTime(),UnitPetGUID,5})
        end

      end
      , "SPELL_SUMMON"
    );

	-- Arguments Variables

 
    --Implosion listener (kill all wild imps)
    HL:RegisterForSelfCombatEvent(
      function (...)
        local DestGUID, _, _, _, SpellID = select(8, ...);
        if SpellID == 196277 then
          for key, Value in pairs(HL.GuardiansTable.Pets) do
            if HL.GuardiansTable.Pets[key][1]=="Wild Imp" then
              HL.GuardiansTable.Pets[key]=nil
            end
          end
        end
      end
      , "SPELL_CAST_SUCCESS"
    );

    -- Listen for imp felfirebolts and remove imps after 5 casts
    HL:RegisterForCombatEvent(
      function (...)
        local UnitGUID, _, _, _, _, _, _, _, SpellID = select(4, ...);
        if SpellID == 104318 then
          for key, Value in pairs(HL.GuardiansTable.Pets) do
            if HL.GuardiansTable.Pets[key][4] == UnitGUID then
              if HL.GuardiansTable.Pets[key][5] - 1 > 0 then
                HL.GuardiansTable.Pets[key][5] = HL.GuardiansTable.Pets[key][5] - 1
              else
                HL.GuardiansTable.Pets[key]=nil
              end
            end
          end
        end
      end
      , "SPELL_CAST_SUCCESS"
    );

	-- updates the pet table
local function RefreshPetsTimers()
  if not HL.GuardiansTable.Pets then
    return
  end
  for key, Value in pairs(HL.GuardiansTable.Pets) do
    local duration = 0
    if PetsInfo[HL.GuardiansTable.Pets[key][2]] then
      duration = PetsInfo[HL.GuardiansTable.Pets[key][2]][2]
    end
    if GetTime() - HL.GuardiansTable.Pets[key][3] >= duration then
      HL.GuardiansTable.Pets[key] = nil
    end
  end
end
	
	
-- Get if the pet are invoked. Parameter = true if you also want to test big pets
local function IsPetInvoked (testBigPets)
  testBigPets = testBigPets or false
  return S.Suffering:IsLearned() or S.SpellLock:IsLearned() or S.Whiplash:IsLearned() or S.CauterizeMaster:IsLearned() or S.AxeToss:IsLearned() or (testBigPets and (S.ShadowLock:IsLearned() or S.MeteorStrike:IsLearned()))
end	
-- Demono Part 3 Clean
	
-- Returns the amount of wild imps that are up
local function PetStack(PetType)
  PetType = PetType or false
  local count = 0
	if not HL.GuardiansTable.Pets or not PetType then
		return count
	end
  
	for key, petData in pairs(HL.GuardiansTable.Pets) do
		if petData[1] == PetType then
			count = count + 1
		end 
	end
	return count
end

-- Summoned pet duration
local function PetDuration(PetType)
	if not PetType then 
		return 0 
	end
	local PetsInfo = {
		[55659] = {"Wild Imp", 20},
		[99737] = {"Wild Imp", 20},
		[98035] = {"Dreadstalker", 12},
		[17252] = {"Felguard", 15},
		[135002] = {"Demonic Tyrant", 15},
	}
	local maxduration = 0
	for key, Value in pairs(HL.GuardiansTable.Pets) do
		if HL.GuardiansTable.Pets[key][1] == PetType then
			if (PetsInfo[HL.GuardiansTable.Pets[key][2]][2] - (GetTime() - HL.GuardiansTable.Pets[key][3])) > maxduration then
				maxduration = HL.OffsetRemains((PetsInfo[HL.GuardiansTable.Pets[key][2]][2] - (GetTime() - HL.GuardiansTable.Pets[key][3])), "Auto" );
			end
		end
	end
	return maxduration
end

-- Demono pets function end

local function TyranIsActive()
    if PetDuration("Demonic Tyrant") > 1 then
        return true
    else
        return false
    end
end

-- Calculate future shard count
local function FutureShard()
    local Shard = Player:SoulShards()
    if not Player:IsCasting() then
        return Shard
    else
        if Player:IsCasting(S.NetherPortal) then
            return Shard - 1
        elseif Player:IsCasting(S.CallDreadStalkers) and Player:BuffRemainsP(S.DemonicCallingBuff) == 0 then
            return Shard - 2
        elseif Player:IsCasting(S.SummonVilefiend) then
            return Shard - 1
        elseif Player:IsCasting(S.SummonFelguard) then
            return Shard - 1
		elseif Player:IsCasting(S.BilescourgeBombers) then
            return Shard - 2
        elseif Player:IsCasting(S.SummonDemonicTyrant) and S.BalefulInvocation:AzeriteEnabled() then
            return Shard + 5
        elseif Player:IsCasting(S.HandOfGuldan) then
            if Shard > 3 then
                return Shard - 3
            else
                return 0
            end
        elseif Player:IsCasting(S.Demonbolt) then
            if Shard >= 4 then
                return 5
            else
                return Shard + 2
            end
        elseif Player:IsCasting(S.Shadowbolt) then
            if Shard == 5 then
                return Shard
            else
                return Shard + 1
            end
        else
            return Shard
        end
    end
end

-- New Doom multi dot test 
--local function DoomDoTCycle()
--    if Cache.EnemiesCount[40] > 1 and if S.Doom:IsCastableP() and (not Target:DebuffP(S.DoomDebuff) and Target:TimeToDie() > 30 and Cache.EnemiesCount[40] < 7 then
--        return S.TargetEnemy:Cast()	
--    end
--end


-- enemy in range
local EnemyRanges = { 40, 5 }

local function UpdateRanges()
    for _, i in ipairs(EnemyRanges) do
        HL.GetEnemies(i);
    end
end

	local function Precombat()
    -- flask
    -- food
    -- augmentation
    -- actions.precombat+=/summon_pet
    if S.SummonFelguard:CooldownRemainsP() == 0 and (not IsPetInvoked() or not S.AxeToss:IsLearned()) or not IsPetInvoked() and FutureShard() >= 1 then
        return S.SummonFelguard:Cast()
    end
    -- inner_demons,if=talent.inner_demons.enabled
    if S.InnerDemons:IsCastableP() and (S.InnerDemons:IsAvailable()) then
      return S.InnerDemons:Cast()
    end
    -- snapshot_stats
	-- potion
    -- demonbolt
    if S.Demonbolt:IsCastableP() and not Player:IsCasting(S.Demonbolt) then
      return S.Demonbolt:Cast()
    end
  end

  	local function BuildAShard()
    -- soul_strike
    if S.SoulStrike:IsCastableP() and IsPetInvoked() then
      return S.SoulStrike:Cast()
    end
    -- shadow_bolt
    if S.ShadowBolt:IsCastableP() and Player:SoulShardsP() < 5 then
      return S.ShadowBolt:Cast()
    end
  end
        
		
	local function DconEpOpener()
    -- hand_of_guldan,line_cd=30
    if S.HandOfGuldan:IsCastableP() and FutureShard() > 4 and HL.CombatTime() <= 5 then
      return S.HandOfGuldan:Cast()
    end
    -- doom,line_cd=30
    if S.Doom:IsCastableP() then
      return S.Doom:Cast()
    end
    -- demonic_strength
    if S.DemonicStrength:IsCastableP() and IsPetInvoked() then
      return S.DemonicStrength:Cast()
    end
    -- bilescourge_bombers
    if S.BilescourgeBombers:IsCastableP() and FutureShard() > 1 then
      return S.BilescourgeBombers:Cast()
    end
	-- soul_strike,if=(soul_shard<3|soul_shard=4&buff.demonic_core.stack<=3)|buff.demonic_core.down&soul_shard<5
    if S.SoulStrike:IsCastableP() and ((FutureShard() < 3 or FutureShard() == 4 and Player:BuffStackP(S.DemonicCoreBuff) <= 3) or Player:BuffDownP(S.DemonicCoreBuff) and FutureShard() < 5) then
      return S.SoulStrike:Cast()
    end
	-- implosion,if=buff.wild_imps.stack>2&buff.explosive_potential.down
    if S.Implosion:IsCastableP() and PetStack("Wild Imp") > 2 and Player:BuffDownP(S.ExplosivePotentialBuff) and HL.CombatTime() <= 7 then
      return S.Implosion:Cast()
    end
    -- grimoire_felguard
    if S.GrimoireFelguard:IsCastableP() and FutureShard() >= 1 and Player:BuffRemainsP(S.ExplosivePotentialBuff) > 1 then
      return S.GrimoireFelguard:Cast()
    end
	-- summon_vilefiend
    if S.SummonVilefiend:IsCastableP() and FutureShard() >= 1 and Player:BuffRemainsP(S.ExplosivePotentialBuff) > 1 then
      return S.SummonVilefiend:Cast()
    end
	-- call_dreadstalkers,if=prev_gcd.1.hand_of_guldan
    if S.CallDreadStalkers:IsCastableP() and FutureShard() > 1 and Player:BuffRemainsP(S.ExplosivePotentialBuff) > 1 then
      return S.CallDreadStalkers:Cast()
    end
    -- hand_of_guldan,if=soul_shard=5|soul_shard=4&buff.demonic_calling.remains
    if S.HandOfGuldan:IsCastableP() and FutureShard() > 2 then
      return S.HandOfGuldan:Cast()
    end
	-- hand_of_guldan,if=soul_shard=5|soul_shard=4&buff.demonic_calling.remains
  --  if S.HandOfGuldan:IsCastableP() and FutureShard() > 2 and (Player:PrevGCDP(1, S.HandOfGuldan)) and Player:BuffRemainsP(S.ExplosivePotentialBuff) >= 5 then
   --   return S.HandOfGuldan:Cast()
  --  end
    -- summon_demonic_tyrant,if=prev_gcd.1.call_dreadstalkers
    if S.SummonDemonicTyrant:IsCastableP() and RubimRH.CDsON() and PetStack("Wild Imp") > 2 then
      return S.SummonDemonicTyrant:Cast()
    end
    -- demonbolt,if=soul_shard<=3&buff.demonic_core.remains
    if S.Demonbolt:IsCastableP() and FutureShard() <= 3 and Player:BuffRemainsP(S.DemonicCoreBuff) > 1 then
      return S.Demonbolt:Cast()
    end
    -- call_action_list,name=build_a_shard
        if (true) then
            if BuildAShard() ~= nil then
                return BuildAShard()
            end
        end
  end
  
  
    local function Implosion()
    -- bilescourge_bombers,if=cooldown.summon_demonic_tyrant.remains>9
    if S.BilescourgeBombers:IsCastableP() and Player:SoulShardsP() >= 2 and Cache.EnemiesCount[40] >= 3 and Target:TimeToDie() > 6 then
        return S.BilescourgeBombers:Cast()
    end  
  	-- implosion,if=PetStack.imps>=mainAddon.db.profile[266].sk1+RubimRH.AoEON
    if S.Implosion:IsCastableP() and PetStack("Wild Imp") > 1 and PetStack("Wild Imp") >= mainAddon.db.profile[266].sk1 and RubimRH.AoEON() then
        return S.Implosion:Cast()
    end  
    -- implosion,if=(buff.wild_imps.stack>=6&(soul_shard<3|prev_gcd.1.call_dreadstalkers|buff.wild_imps.stack>=9|prev_gcd.1.bilescourge_bombers|(!prev_gcd.1.hand_of_guldan&!prev_gcd.2.hand_of_guldan))&!prev_gcd.1.hand_of_guldan&!prev_gcd.2.hand_of_guldan&buff.demonic_power.down)|(time_to_die<3&buff.wild_imps.stack>0)|(prev_gcd.2.call_dreadstalkers&buff.wild_imps.stack>2&!talent.demonic_calling.enabled)
    if S.Implosion:IsCastableP() and ((PetStack("Wild Imp") >= 6 and (FutureShard() < 3 or Player:PrevGCDP(1, S.CallDreadStalkers) or PetStack("Wild Imp") >= 9 or Player:PrevGCDP(1, S.BilescourgeBombers) or (not Player:PrevGCDP(1, S.HandOfGuldan) and not Player:PrevGCDP(2, S.HandOfGuldan))) and not Player:PrevGCDP(1, S.HandOfGuldan) and not Player:PrevGCDP(2, S.HandOfGuldan) and Player:BuffDownP(S.DemonicPowerBuff)) or (Target:TimeToDie() < 3 and PetStack("Wild Imp") > 0) or (Player:PrevGCDP(2, S.CallDreadStalkers) and PetStack("Wild Imp") > 2 and not S.DemonicCalling:IsAvailable())) then
      return S.Implosion:Cast()
    end
    -- grimoire_felguard,if=cooldown.summon_demonic_tyrant.remains<13|!equipped.132369
    if S.GrimoireFelguard:IsCastableP() and FutureShard() > 1 and (S.SummonDemonicTyrant:CooldownRemainsP() < 13) then
      return S.GrimoireFelguard:Cast()
    end
    -- call_dreadstalkers,if=(cooldown.summon_demonic_tyrant.remains<9&buff.demonic_calling.remains)|(cooldown.summon_demonic_tyrant.remains<11&!buff.demonic_calling.remains)|cooldown.summon_demonic_tyrant.remains>14
    if S.CallDreadStalkers:IsCastableP() and FutureShard() > 1 and ((S.SummonDemonicTyrant:CooldownRemainsP() < 9 and Player:BuffRemainsP(S.DemonicCallingBuff)) or (S.SummonDemonicTyrant:CooldownRemainsP() < 11 and not Player:BuffRemainsP(S.DemonicCallingBuff)) or S.SummonDemonicTyrant:CooldownRemainsP() > 14) then
      return S.CallDreadStalkers:Cast()
    end
    -- summon_demonic_tyrant
   -- if S.SummonDemonicTyrant:IsCastableP() and RubimRH.CDsON() then
  --    return S.SummonDemonicTyrant:Cast()
  --  end
    -- hand_of_guldan,if=soul_shard>=5
    if S.HandOfGuldan:IsCastableP() and (FutureShard() >= 5) then
      return S.HandOfGuldan:Cast()
    end
    -- hand_of_guldan,if=soul_shard>=3&(((prev_gcd.2.hand_of_guldan|buff.wild_imps.stack>=3)&buff.wild_imps.stack<9)|cooldown.summon_demonic_tyrant.remains<=gcd*2|buff.demonic_power.remains>gcd*2)
    if S.HandOfGuldan:IsCastableP() and (FutureShard() >= 3 and (((Player:PrevGCDP(2, S.HandOfGuldan) or PetStack("Wild Imp") >= 3) and PetStack("Wild Imp") < 9) or S.SummonDemonicTyrant:CooldownRemainsP() <= Player:GCD() * 2 or Player:BuffRemainsP(S.DemonicPowerBuff) > Player:GCD() * 2)) then
      return S.HandOfGuldan:Cast()
    end
    -- demonbolt,if=prev_gcd.1.hand_of_guldan&soul_shard>=1&(buff.wild_imps.stack<=3|prev_gcd.3.hand_of_guldan)&soul_shard<4&buff.demonic_core.up
    if S.Demonbolt:IsCastableP() and Player:PrevGCDP(1, S.HandOfGuldan) and FutureShard() >= 1 and (PetStack("Wild Imp") <= 3 or Player:PrevGCDP(3, S.HandOfGuldan)) and FutureShard() < 4 and Player:BuffP(S.DemonicCoreBuff) then
      return S.Demonbolt:Cast()
    end
    -- summon_vilefiend,if=(cooldown.summon_demonic_tyrant.remains>40&spell_targets.implosion<=2)|cooldown.summon_demonic_tyrant.remains<12
    if S.SummonVilefiend:IsCastableP() and FutureShard() > 1 and ((S.SummonDemonicTyrant:CooldownRemainsP() > 40 and Cache.EnemiesCount[40] <= 2) or S.SummonDemonicTyrant:CooldownRemainsP() < 12) then
      return S.SummonVilefiend:Cast()
    end
    -- bilescourge_bombers,if=cooldown.summon_demonic_tyrant.remains>9
    if S.BilescourgeBombers:IsCastableP() and FutureShard() > 1 and (S.SummonDemonicTyrant:CooldownRemainsP() > 9) then
      return S.BilescourgeBombers:Cast()
    end
    -- soul_strike,if=soul_shard<5&buff.demonic_core.stack<=2
    if S.SoulStrike:IsCastableP() and FutureShard() < 5 and Player:BuffStackP(S.DemonicCoreBuff) <= 2 then
      return S.SoulStrike:Cast()
    end
    -- demonbolt,if=soul_shard<=3&buff.demonic_core.up&(buff.demonic_core.stack>=3|buff.demonic_core.remains<=gcd*5.7)
    if S.Demonbolt:IsCastableP() and FutureShard() <= 3 and Player:BuffP(S.DemonicCoreBuff) and (Player:BuffStackP(S.DemonicCoreBuff) >= 3 or Player:BuffRemainsP(S.DemonicCoreBuff) <= Player:GCD() * 5.7) then
      return S.Demonbolt:Cast()
    end
    -- New Doom multidotting test
    -- actions.implosion+=/doom,cycle_targets=1,max_cycle_targets=7,if=refreshable
    if RubimRH.AoEON() then
            if S.Doom:IsCastableP() and Target:DebuffRefreshableCP(S.Doom) and Target:TimeToDie() > 30 then
                return S.Doom:Cast()
            end
			
			-- Auto switch to next non dotted target
            --DoomDoTCycle()
			--if S.Doom:IsAvailable() then
	       --     DoomDoTCycle()
          --  end
        else
            if S.Doom:IsCastableP() and Target:DebuffRefreshableCP(S.Doom) and Target:TimeToDie() > 30 then
                return S.Doom:Cast()
            end
        end
        
	    -- call_action_list,name=build_a_shard
        if (true) then
            if BuildAShard() ~= nil then
                return BuildAShard()
            end
        end
    end
  
  
  NetherPortal = function()
    -- call_action_list,name=nether_portal_building,if=cooldown.nether_portal.remains<20
    if (S.NetherPortal:CooldownRemainsP() < 20) then
      local ShouldReturn = NetherPortalBuilding(); if ShouldReturn then return ShouldReturn; end
    end
    -- call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>165
    if (S.NetherPortal:CooldownRemainsP() > 165) then
      local ShouldReturn = NetherPortalActive(); if ShouldReturn then return ShouldReturn; end
    end
  end
  
  
    -- NetherPortal Active
    local function NetherPortalActive()
        -- bilescourge_bombers
        if S.BilescourgeBombers:IsCastableP() and FutureShard() > 1 then
            return S.BilescourgeBombers:Cast()
        end
        -- grimoire_felguard,if=cooldown.summon_demonic_tyrant.remains<13|!equipped.132369
        if S.GrimoireFelguard:IsCastableP() and S.SummonDemonicTyrant:CooldownRemainsP() < 13 and FutureShard() > 0 then
            return S.GrimoireFelguard:Cast()
        end
        -- summon_vilefiend,if=cooldown.summon_demonic_tyrant.remains>40|cooldown.summon_demonic_tyrant.remains<12
        if S.SummonVilefiend:IsCastableP() and not Player:IsCasting(S.SummonVilefiend) and FutureShard() > 0 and (S.SummonDemonicTyrant:CooldownRemainsP() > 40 or S.SummonDemonicTyrant:CooldownRemainsP() < 12) then
            return S.SummonVilefiend:Cast()
        end
		-- call_dreadstalkers,if=(cooldown.summon_demonic_tyrant.remains<9&buff.demonic_calling.remains)|(cooldown.summon_demonic_tyrant.remains<11&!buff.demonic_calling.remains)|cooldown.summon_demonic_tyrant.remains>14
        if S.CallDreadStalkers:IsCastableP() and (FutureShard() > 1 or (FutureShard() > 0 and Player:BuffRemainsP(S.DemonicCallingBuff) > 0)) and not Player:IsCasting(S.CallDreadStalkers) and ((S.SummonDemonicTyrant:CooldownRemainsP() < 9 and Player:BuffRemainsP(S.DemonicCallingBuff) > 0) or (S.SummonDemonicTyrant:CooldownRemainsP() < 11 and Player:BuffRemainsP(S.DemonicCallingBuff) == 0) or S.SummonDemonicTyrant:CooldownRemainsP() < 14 ) then
            return S.CallDreadStalkers:Cast()
        end
        -- call_action_list,name=build_a_shard,if=soul_shard=1&(cooldown.call_dreadstalkers.remains<action.shadow_bolt.cast_time|(talent.bilescourge_bombers.enabled&cooldown.bilescourge_bombers.remains<action.shadow_bolt.cast_time))
        if FutureShard() == 1 and (S.CallDreadStalkers:CooldownRemainsP() < S.ShadowBolt:CastTime() or (S.BilescourgeBombers:IsAvailable() and S.BilescourgeBombers:CooldownRemainsP() < S.ShadowBolt:CastTime())) then
            if BuildAShard() ~= nil then
                return BuildAShard()
            end
        end
		-- summon_demonic_tyrant,if=buff.nether_portal.remains<5&soul_shard=0and PetStack("Wild Imp") >= mainAddon.db.profile[266].sk2
        if S.SummonDemonicTyrant:IsCastableP() and RubimRH.CDsON() and S.BalefulInvocation:AzeriteEnabled() and Player:BuffRemainsP(S.NetherPortalBuff) > 5 and FutureShard() == 0 then
            return S.SummonDemonicTyrant:Cast()
        end
		-- summon_demonic_tyrant,if=buff.nether_portal.remains<action.summon_demonic_tyrant.cast_time+0.5.balefulinvocation:azerite
     --   if S.SummonDemonicTyrant:IsCastableP() and S.BalefulInvocation:AzeriteEnabled() and FutureShard() == 0 and (Player:BuffRemainsP(S.NetherPortalBuff) < S.SummonDemonicTyrant:CastTime() + 0.5) then
    --        return S.SummonDemonicTyrant:Cast()
     --   end
        -- hand_of_guldan,if=((cooldown.call_dreadstalkers.remains>action.demonbolt.cast_time)&(cooldown.call_dreadstalkers.remains>action.shadow_bolt.cast_time))&cooldown.nether_portal.remains>(165+action.hand_of_guldan.cast_time)
        if S.HandOfGuldan:IsCastableP() and FutureShard() > 0 and S.CallDreadStalkers:CooldownRemainsP() > S.Demonbolt:CastTime() and S.CallDreadStalkers:CooldownRemainsP() > S.ShadowBolt:CastTime() and S.NetherPortal:CooldownRemainsP() > (165 + S.HandOfGuldan:CastTime()) then
            return S.HandOfGuldan:Cast()
        end
        -- summon_demonic_tyrant,if=buff.nether_portal.remains<5&soul_shard=0
        if S.SummonDemonicTyrant:IsCastableP() and RubimRH.CDsON() and Player:BuffRemainsP(S.NetherPortalBuff) < 5 and FutureShard() == 0 then
            return S.SummonDemonicTyrant:Cast()
        end
        -- summon_demonic_tyrant,if=buff.nether_portal.remains<action.summon_demonic_tyrant.cast_time+0.5.no_balefulinvocation:azerite
        if S.SummonDemonicTyrant:IsCastableP() and RubimRH.CDsON() and (Player:BuffRemainsP(S.NetherPortalBuff) < S.SummonDemonicTyrant:CastTime() + 0.5) then
            return S.SummonDemonicTyrant:Cast()
        end
        -- demonbolt,if=buff.demonic_core.up
    --    if S.Demonbolt:IsCastableP() and Player:SoulShardsP() <= 3 and (Player:BuffP(S.DemonicCoreBuff)) > then
     --       return S.Demonbolt:Cast()
   --     end
        -- call_action_list,name=build_a_shard
        if (true) then
            if BuildAShard() ~= nil then
                return BuildAShard()
            end
        end
  end
  
  -- NetherPortal Building
  local function NetherPortalBuilding()
    -- nether_portal,if=soul_shard>=5&(!talent.power_siphon.enabled|buff.demonic_core.up)
    if S.NetherPortal:IsCastableP() and FutureShard() >= 5 and (not S.PowerSiphon:IsAvailable() or Player:BuffP(S.DemonicCoreBuff)) then
      return S.NetherPortal:Cast()
    end
    -- call_dreadstalkers
    if S.CallDreadStalkers:IsCastableP() and FutureShard() > 1 and FutureShard() >= 2 then
      return S.CallDreadStalkers:Cast()
    end
    -- hand_of_guldan,if=cooldown.call_dreadstalkers.remains>18&soul_shard>=3
    if S.HandOfGuldan:IsCastableP() and S.CallDreadStalkers:CooldownRemainsP() > 18 and FutureShard() >= 3 then
      return S.HandOfGuldan:Cast()
    end
    -- power_siphon,if=buff.wild_imps.stack>=2&buff.demonic_core.stack<=2&buff.demonic_power.down&soul_shard>=3
    if S.PowerSiphon:IsCastableP() and PetStack("Wild Imp") >= 2 and Player:BuffStackP(S.DemonicCoreBuff) <= 2 and Player:BuffDownP(S.DemonicPowerBuff) and FutureShard() >= 3 then
      return S.PowerSiphon:Cast()
    end
    -- hand_of_guldan,if=soul_shard>=5
    if S.HandOfGuldan:IsCastableP() and (FutureShard() >= 5) then
      return S.HandOfGuldan:Cast()
    end
        -- call_action_list,name=build_a_shard
        if (true) then
            if BuildAShard() ~= nil then
                return BuildAShard()
            end
        end
  end
    
    -- Get if the pet are invoked. Parameter = true if you also want to test big pets
    local function IsPetInvoked (testBigPets)
        testBigPets = testBigPets or false;
        return S.Suffering:IsLearned() or S.SpellLock:IsLearned() or S.Whiplash:IsLearned() or S.CauterizeMaster:IsLearned() or S.AxeToss:IsLearned() or (testBigPets and (S.ShadowLock:IsLearned() or S.MeteorStrike:IsLearned()))
    end
    

--- ======= ACTION LISTS =======
local function APL()
    --local Precombat, BuildAShard, DconEpOpener, Implosion, NetherPortal, NetherPortalActive, NetherPortalBuilding
    UpdateRanges()
    RefreshPetsTimers()
  
  	-- call precombat
    if not Player:AffectingCombat() and not Player:IsCasting() then
        if Precombat() ~= nil then
            return Precombat()
        end
    end

    if RubimRH.TargetIsValid() then
    -- berserking,if=pet.demonic_tyrant.active|target.time_to_die<=15
    if S.Berserking:IsCastableP() and RubimRH.CDsON() and TyranIsActive() then
      return S.Berserking:Cast()
    end
    -- blood_fury,if=pet.demonic_tyrant.active|target.time_to_die<=15
    if S.BloodFury:IsCastableP() and RubimRH.CDsON() and TyranIsActive() then
      return S.BloodFury:Cast()
    end
    -- fireblood,if=pet.demonic_tyrant.active|target.time_to_die<=15
    if S.Fireblood:IsCastableP() and RubimRH.CDsON() and TyranIsActive() then
      return S.Fireblood:Cast()
    end
    -- call_action_list,name=dcon_ep_opener,if=azerite.explosive_potential.rank&talent.demonic_consumption.enabled&time<30&!cooldown.summon_demonic_tyrant.remains
    if S.ExplosivePotential:AzeriteEnabled() and S.DemonicConsumption:IsAvailable() and HL.CombatTime() < 15 and S.SummonDemonicTyrant:CooldownRemainsP() <= 5 then
	    if DconEpOpener() ~= nil then
            return DconEpOpener()
        end
    end
    -- hand_of_guldan,if=azerite.explosive_potential.rank&time<5&soul_shard>2&buff.explosive_potential.down&buff.wild_imps.stack<3&!prev_gcd.1.hand_of_guldan&&!prev_gcd.2.hand_of_guldan
    if S.HandOfGuldan:IsCastableP() and S.ExplosivePotential:AzeriteEnabled() and HL.CombatTime() < 5 and FutureShard() > 2 and Player:BuffDownP(S.ExplosivePotentialBuff) and PetStack("Wild Imp") < 3 and not Player:PrevGCDP(1, S.HandOfGuldan) and true and not Player:PrevGCDP(2, S.HandOfGuldan) then
      return S.HandOfGuldan:Cast()
    end
    -- demonbolt,if=soul_shard<=3&buff.demonic_core.up&buff.demonic_core.stack=4
    if S.Demonbolt:IsCastableP() and FutureShard() <= 3 and Player:BuffP(S.DemonicCoreBuff) and Player:BuffStackP(S.DemonicCoreBuff) == 4 then
      return S.Demonbolt:Cast()
    end
    -- implosion,if=azerite.explosive_potential.rank&buff.wild_imps.stack>2&buff.explosive_potential.remains<action.shadow_bolt.execute_time
    if S.Implosion:IsCastableP() and S.ExplosivePotential:AzeriteEnabled() and PetStack("Wild Imp") > 2 and Player:BuffRemainsP(S.ExplosivePotentialBuff) < S.ShadowBolt:ExecuteTime() then
      return S.Implosion:Cast()
    end
    -- implosion,if=azerite.explosive_potential.rank&buff.wild_imps.stack>2&buff.explosive_potential.remains<cooldown.summon_demonic_tyrant.remains&cooldown.summon_demonic_tyrant.remains<11&talent.demonic_consumption.enabled
    if S.Implosion:IsCastableP() and S.ExplosivePotential:AzeriteEnabled() and PetStack("Wild Imp") > 2 and Player:BuffRemainsP(S.ExplosivePotentialBuff) < S.SummonDemonicTyrant:CooldownRemainsP() and S.SummonDemonicTyrant:CooldownRemainsP() < 11 and S.DemonicConsumption:IsAvailable() then
      return S.Implosion:Cast()
    end
    -- doom,if=!ticking&time_to_die>30&spell_targets.implosion<2
    if S.Doom:IsCastableP() and not Target:DebuffP(S.DoomDebuff) and Target:TimeToDie() > 30 and Cache.EnemiesCount[40] < 2 then
      return S.Doom:Cast()
    end
    -- bilescourge_bombers,if=azerite.explosive_potential.rank>0&time<10&spell_targets.implosion<2&buff.dreadstalkers.remains&talent.nether_portal.enabled
    if S.BilescourgeBombers:IsCastableP() and FutureShard() > 1 and S.ExplosivePotential:AzeriteRank() > 0 and HL.CombatTime() < 10 and Cache.EnemiesCount[40] < 2 and PetDuration("Dreadstalker") > 1 and S.NetherPortal:IsAvailable() then
      return S.BilescourgeBombers:Cast()
    end
    -- demonic_strength,if=(buff.wild_imps.stack<6|buff.demonic_power.up)|spell_targets.implosion<2
    if S.DemonicStrength:IsCastableP() and ((PetStack("Wild Imp") < 6 or Player:BuffP(S.DemonicPowerBuff)) or Cache.EnemiesCount[40] < 2) then
      return S.DemonicStrength:Cast()
    end
        -- call_action_list,name=nether_portal,if=talent.nether_portal.enabled&spell_targets.implosion<=2
        if (S.NetherPortal:CooldownRemainsP() < 20) and RubimRH.CDsON() and S.NetherPortal:IsAvailable() then
            if NetherPortalBuilding() ~= nil then
                return NetherPortalBuilding()
            end
        end
        -- call_action_list,name=nether_portal_active,if=cooldown.nether_portal.remains>165
        if (S.NetherPortal:CooldownRemainsP() > 165) and RubimRH.CDsON() and S.NetherPortal:IsAvailable() then
            if NetherPortalActive() ~= nil then
                return NetherPortalActive()
            end
        end  
        -- call_action_list,name=implosion,if=spell_targets.implosion>1
        if (Cache.EnemiesCount[40] > 1) and RubimRH.AoEON() then
            if Implosion() ~= nil then
                return Implosion()
            end
        end
    -- grimoire_felguard,if=cooldown.summon_demonic_tyrant.remains<13
    if S.GrimoireFelguard:IsCastableP() and FutureShard() > 1 and (S.SummonDemonicTyrant:CooldownRemainsP() < 13) then
      return S.GrimoireFelguard:Cast()
    end
    -- summon_vilefiend,if=cooldown.summon_demonic_tyrant.remains>40|cooldown.summon_demonic_tyrant.remains<12
    if S.SummonVilefiend:IsCastableP() and FutureShard() > 1 and (S.SummonDemonicTyrant:CooldownRemainsP() > 40 or S.SummonDemonicTyrant:CooldownRemainsP() < 12) then
      return S.SummonVilefiend:Cast()
    end
        -- actions+=/call_dreadstalkers,if=equipped.132369|(cooldown.summon_demonic_tyrant.remains<9&buff.demonic_calling.remains)|(cooldown.summon_demonic_tyrant.remains<11&!buff.demonic_calling.remains)|cooldown.summon_demonic_tyrant.remains>14
        if S.CallDreadStalkers:IsCastableP() and (FutureShard() > 1 or (FutureShard() > 0 and Player:BuffRemainsP(S.DemonicCallingBuff) > 0)) and not Player:IsCasting(S.CallDreadStalkers) and ( (S.SummonDemonicTyrant:CooldownRemainsP() < 9 and Player:BuffRemainsP(S.DemonicCallingBuff) > 0) or (S.SummonDemonicTyrant:CooldownRemainsP() < 11 and Player:BuffRemainsP(S.DemonicCallingBuff) == 0) or S.SummonDemonicTyrant:CooldownRemainsP() > 14 ) then
           return S.CallDreadStalkers:Cast()
        end
    -- bilescourge_bombers
    if S.BilescourgeBombers:IsCastableP() and FutureShard() > 1 then
      return S.BilescourgeBombers:Cast()
    end
    -- summon_demonic_tyrant,if=soul_shard<3&(!talent.demonic_consumption.enabled|buff.wild_imps.stack>0)
    if S.SummonDemonicTyrant:IsCastableP() and FutureShard() < 3 and RubimRH.CDsON() and (not S.DemonicConsumption:IsAvailable() or PetStack("Wild Imp") > 0) then
      return S.SummonDemonicTyrant:Cast()
    end
    -- power_siphon,if=buff.wild_imps.stack>=2&buff.demonic_core.stack<=2&buff.demonic_power.down&spell_targets.implosion<2
    if S.PowerSiphon:IsCastableP() and PetStack("Wild Imp") >= 2 and Player:BuffStackP(S.DemonicCoreBuff) <= 2 and Player:BuffDownP(S.DemonicPowerBuff) and Cache.EnemiesCount[40] < 2 then
      return S.PowerSiphon:Cast()
    end
    -- doom,if=talent.doom.enabled&refreshable&time_to_die>(dot.doom.remains+30)
    if S.Doom:IsCastableP() and S.Doom:IsAvailable() and Target:DebuffRefreshableCP(S.DoomDebuff) and Target:TimeToDie() > (Target:DebuffRemainsP(S.DoomDebuff) + 30) then
      return S.Doom:Cast()
    end
    -- hand_of_guldan,if=soul_shard>=5|(soul_shard>=3&cooldown.call_dreadstalkers.remains>4&(cooldown.summon_demonic_tyrant.remains>20|(cooldown.summon_demonic_tyrant.remains<gcd*2&talent.demonic_consumption.enabled|cooldown.summon_demonic_tyrant.remains<gcd*4&!talent.demonic_consumption.enabled))&(!talent.summon_vilefiend.enabled|cooldown.summon_vilefiend.remains>3))
    if S.HandOfGuldan:IsCastableP() and FutureShard() >= 5 or (FutureShard() >= 3 and S.CallDreadStalkers:CooldownRemainsP() > 4 and (S.SummonDemonicTyrant:CooldownRemainsP() > 20 or (S.SummonDemonicTyrant:CooldownRemainsP() < Player:GCD() * 2 and S.DemonicConsumption:IsAvailable() or S.SummonDemonicTyrant:CooldownRemainsP() < Player:GCD() * 4 and not S.DemonicConsumption:IsAvailable())) and (not S.SummonVilefiend:IsAvailable() or S.SummonVilefiend:CooldownRemainsP() > 3)) then
      return S.HandOfGuldan:Cast()
    end
    -- soul_strike,if=soul_shard<5&buff.demonic_core.stack<=2
    if S.SoulStrike:IsCastableP() and FutureShard() < 5 and Player:BuffStackP(S.DemonicCoreBuff) <= 2 then
      return S.SoulStrike:Cast()
    end
    -- demonbolt,if=soul_shard<=3&buff.demonic_core.up&((cooldown.summon_demonic_tyrant.remains<6|cooldown.summon_demonic_tyrant.remains>22)|buff.demonic_core.stack>=3|buff.demonic_core.remains<5|time_to_die<25)
    if S.Demonbolt:IsCastableP() and FutureShard() <= 3 and Player:BuffP(S.DemonicCoreBuff) and ((S.SummonDemonicTyrant:CooldownRemainsP() < 6 or S.SummonDemonicTyrant:CooldownRemainsP() > 22) or Player:BuffStackP(S.DemonicCoreBuff) >= 3 or Player:BuffRemainsP(S.DemonicCoreBuff) < 5 or Target:TimeToDie() < 25) then
      return S.Demonbolt:Cast()
    end
    -- call_action_list,name=build_a_shard
        if (true) then
            if BuildAShard() ~= nil then
                return BuildAShard()
            end
        end
    end
    return 0, 135328
end

RubimRH.Rotation.SetAPL(266, APL)

local function PASSIVE()
    return RubimRH.Shared()
end

RubimRH.Rotation.SetPASSIVE(266, PASSIVE)