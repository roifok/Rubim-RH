-- 4/4/2019 rewrite
local addonName, addonTable = ...;
local HL = HeroLib;
local Cache = HeroCache;
local Unit = HL.Unit;
local Pet = Unit.Pet;
local Player = Unit.Player;
local Target = Unit.Target;
local Spell = HL.Spell;
local Item = HL.Item;

RubimRH.Spell[254] = {
    SummonPet = Spell(883),
    HuntersMarkDebuff = Spell(257284),
    HuntersMark = Spell(257284),
    DoubleTap = Spell(260402),
    TrueshotBuff = Spell(288613),
    Trueshot = Spell(288613),
    AimedShot = Spell(19434),
    UnerringVisionBuff = Spell(274446),
    UnerringVision = Spell(274444),
    CallingtheShots = Spell(260404),
    SurgingShots = Spell(287707),
    Streamline = Spell(260367),
    FocusedFire = Spell(278531),
    RapidFire = Spell(257044),
    Berserking = Spell(26297),
    BloodFury = Spell(20572),
    AncestralCall = Spell(274738),
    Fireblood = Spell(265221),
    LightsJudgment = Spell(255647),
    CarefulAim = Spell(260228),
    ExplosiveShot = Spell(212431),
    Barrage = Spell(120360),
    AMurderofCrows = Spell(131894),
    SerpentSting = Spell(271788),
    SerpentStingDebuff = Spell(271788),
    ArcaneShot = Spell(185358),
    MasterMarksmanBuff = Spell(269576),
    PreciseShotsBuff = Spell(260242),
    IntheRhythm = Spell(264198),
    PiercingShot = Spell(198670),
    SteadyFocus = Spell(193533),
    SteadyShot = Spell(56641),
    TrickShotsBuff = Spell(257622),
    Multishot = Spell(257620),
    SurvivalOfTheFittest = Spell(264735),

    --CUSTOM
    Exhilaration = Spell(109304),
    AspectoftheTurtle = Spell(186265),
    CounterShot = Spell(147362),
	
		  --8.2 Essences
  UnleashHeartOfAzeroth = Spell(280431),
  BloodOfTheEnemy       = Spell(297108),
  BloodOfTheEnemy2      = Spell(298273),
  BloodOfTheEnemy3      = Spell(298277),
  ConcentratedFlame     = Spell(295373),
  ConcentratedFlame2    = Spell(299349),
  ConcentratedFlame3    = Spell(299353),
  GuardianOfAzeroth     = Spell(295840),
  GuardianOfAzeroth2    = Spell(299355),
  GuardianOfAzeroth3    = Spell(299358),
  FocusedAzeriteBeam    = Spell(295258),
  FocusedAzeriteBeam2   = Spell(299336),
  FocusedAzeriteBeam3   = Spell(299338),
  PurifyingBlast        = Spell(295337),
  PurifyingBlast2       = Spell(299345),
  PurifyingBlast3       = Spell(299347),
  TheUnboundForce       = Spell(298452),
  TheUnboundForce2      = Spell(299376),
  TheUnboundForce3      = Spell(299378),
  RippleInSpace         = Spell(302731),
  RippleInSpace2        = Spell(302982),
  RippleInSpace3        = Spell(302983),
  WorldveinResonance    = Spell(295186),
  WorldveinResonance2   = Spell(298628),
  WorldveinResonance3   = Spell(299334),
  MemoryOfLucidDreams   = Spell(298357),
  MemoryOfLucidDreams2  = Spell(299372),
  MemoryOfLucidDreams3  = Spell(299374),
}

local S = RubimRH.Spell[254]

if not Item.Hunter then
    Item.Hunter = {}
end

Item.Hunter.Marksmanship = {
    -- Legendaries
    SephuzSecret = Item(132452, { 11, 12 }),
    -- Trinkets
    onvergenceofFates = Item(140806, { 13, 14 }),
    -- Potions
    PotionOfProlongedPower = Item(142117),
}
local I = Item.Hunter.Marksmanship

local function PetActive()
    local petActive = false
    if Pet:Exists() then
        petActive = true
    end

    if Pet:IsActive() then
        petActive = true
    end

    if Pet:IsDeadOrGhost() then
        petActive = false
    end

    return petActive
end

S.AimedShot:RegisterInFlight()

local EnemyRanges = { 40 }
local function UpdateRanges()
    for _, i in ipairs(EnemyRanges) do
        HL.GetEnemies(i);
    end
end
-- Rotation Var
local ShouldReturn; -- Used to get the return string
local function num(val)
    if val then
        return 1
    else
        return 0
    end
end

local function bool(val)
    return val ~= 0
end

local function GetEnemiesCount()
  if RubimRH.AoEON() then
    if RubimRH.db.profile[254].useSplashData == "Enabled" then
      RubimRH.UpdateSplashCount(Target, 10)
      return RubimRH.GetSplashCount(Target, 10)
    else
      UpdateRanges()
      --return GetEnemiesCount()
	  return active_enemies()
    end
  else
    return 1
  end
end

-- Trinket var
local trinket2 = 1030910
local trinket1 = 1030902

-- Trinket Ready
local function trinketReady(trinketPosition)
    local inventoryPosition
    
	if trinketPosition == 1 then
        inventoryPosition = 13
    end
    
	if trinketPosition == 2 then
        inventoryPosition = 14
    end
    
	local start, duration, enable = GetInventoryItemCooldown("Player", inventoryPosition)
    if enable == 0 then
        return false
    end

    if start + duration - GetTime() > 0 then
        return false
    end
	
	if RubimRH.db.profile.mainOption.useTrinkets[1] == false then
	    return false
	end
	
   	if RubimRH.db.profile.mainOption.useTrinkets[2] == false then
	    return false
	end	
	
    if RubimRH.db.profile.mainOption.trinketsUsage == "Everything" then
        return true
    end
	
	if RubimRH.db.profile.mainOption.trinketsUsage == "Boss Only" then
        if not UnitExists("boss1") then
            return false
        end

        if UnitExists("target") and not (UnitClassification("target") == "worldboss" or UnitClassification("target") == "rareelite" or UnitClassification("target") == "rare") then
            return false
        end
    end	
    return true
end

local function DetermineEssenceRanks()
  S.BloodOfTheEnemy = S.BloodOfTheEnemy2:IsAvailable() and S.BloodOfTheEnemy2 or S.BloodOfTheEnemy
  S.BloodOfTheEnemy = S.BloodOfTheEnemy3:IsAvailable() and S.BloodOfTheEnemy3 or S.BloodOfTheEnemy
  S.MemoryOfLucidDreams = S.MemoryOfLucidDreams2:IsAvailable() and S.MemoryOfLucidDreams2 or S.MemoryOfLucidDreams
  S.MemoryOfLucidDreams = S.MemoryOfLucidDreams3:IsAvailable() and S.MemoryOfLucidDreams3 or S.MemoryOfLucidDreams
  S.PurifyingBlast = S.PurifyingBlast2:IsAvailable() and S.PurifyingBlast2 or S.PurifyingBlast
  S.PurifyingBlast = S.PurifyingBlast3:IsAvailable() and S.PurifyingBlast3 or S.PurifyingBlast
  S.RippleInSpace = S.RippleInSpace2:IsAvailable() and S.RippleInSpace2 or S.RippleInSpace
  S.RippleInSpace = S.RippleInSpace3:IsAvailable() and S.RippleInSpace3 or S.RippleInSpace
  S.ConcentratedFlame = S.ConcentratedFlame2:IsAvailable() and S.ConcentratedFlame2 or S.ConcentratedFlame
  S.ConcentratedFlame = S.ConcentratedFlame3:IsAvailable() and S.ConcentratedFlame3 or S.ConcentratedFlame
  S.TheUnboundForce = S.TheUnboundForce2:IsAvailable() and S.TheUnboundForce2 or S.TheUnboundForce
  S.TheUnboundForce = S.TheUnboundForce3:IsAvailable() and S.TheUnboundForce3 or S.TheUnboundForce
  S.WorldveinResonance = S.WorldveinResonance2:IsAvailable() and S.WorldveinResonance2 or S.WorldveinResonance
  S.WorldveinResonance = S.WorldveinResonance3:IsAvailable() and S.WorldveinResonance3 or S.WorldveinResonance
  S.FocusedAzeriteBeam = S.FocusedAzeriteBeam2:IsAvailable() and S.FocusedAzeriteBeam2 or S.FocusedAzeriteBeam
  S.FocusedAzeriteBeam = S.FocusedAzeriteBeam3:IsAvailable() and S.FocusedAzeriteBeam3 or S.FocusedAzeriteBeam
end

-- # Essences
local function Essences()
  -- blood_of_the_enemy
  if S.BloodOfTheEnemy:IsCastableP() then
    return S.UnleashHeartOfAzeroth:Cast()
  end
  -- concentrated_flame
  if S.ConcentratedFlame:IsCastableP() then
    return S.UnleashHeartOfAzeroth:Cast()
  end
  -- guardian_of_azeroth
  if S.GuardianOfAzeroth:IsCastableP() then
    return S.UnleashHeartOfAzeroth:Cast()
  end
  -- focused_azerite_beam
  if S.FocusedAzeriteBeam:IsCastableP() then
    return S.UnleashHeartOfAzeroth:Cast()
  end
  -- purifying_blast
  if S.PurifyingBlast:IsCastableP() then
    return S.UnleashHeartOfAzeroth:Cast()
  end
  -- the_unbound_force
  if S.TheUnboundForce:IsCastableP() then
    return S.UnleashHeartOfAzeroth:Cast()
  end
  -- ripple_in_space
  if S.RippleInSpace:IsCastableP() then
    return S.UnleashHeartOfAzeroth:Cast()
  end
  -- worldvein_resonance
  if S.WorldveinResonance:IsCastableP() then
    return S.UnleashHeartOfAzeroth:Cast()
  end
  -- memory_of_lucid_dreams,if=fury<40&buff.metamorphosis.up
  if S.MemoryOfLucidDreams:IsCastableP() then
    return S.UnleashHeartOfAzeroth:Cast()
  end
  return false
end

--- APL Main
local function APL ()
    local Precombat, Cds, St, Trickshots
    UpdateRanges()
    DetermineEssenceRanks()
    
	Precombat = function()
        if RubimRH.TargetIsValid() then
            -- flask
            -- augmentation
            -- food
            -- summon_pet,if=active_enemies<3
            if S.SummonPet:IsCastableP() and (not Player:IsMoving() and GetEnemiesCount() < 3) then
                return S.SummonPet:Cast()
            end
            -- snapshot_stats
            -- potion
            -- hunters_mark
            if S.HuntersMark:IsCastableP() and Target:DebuffDown(S.HuntersMarkDebuff) then
                return S.HuntersMark:Cast()
            end
            -- double_tap,precast_time=10
            if S.DoubleTap:IsCastableP() and RubimRH.CDsON() then
                return S.DoubleTap:Cast()
            end
            -- trueshot,precast_time=1.5,if=active_enemies>2
            if S.Trueshot:IsCastableP() and RubimRH.CDsON() and Player:BuffDownP(S.TrueshotBuff) and (GetEnemiesCount() > 2) then
                return S.Trueshot:Cast()
            end
            -- aimed_shot,if=active_enemies<3
            if S.AimedShot:IsReadyP() and (not Player:IsMoving() and GetEnemiesCount() < 3) then
                return S.AimedShot:Cast()
            end
        end
    end

  -- Protect against interrupt of channeled spells
  if Player:IsCasting() and Player:CastRemains() >= ((select(4, GetNetStats()) / 1000) * 2) or Player:IsChanneling() then
      return 0, "Interface\\Addons\\Rubim-RH\\Media\\channel.tga"
  end 

    if QueueSkill() ~= nil then
        return QueueSkill()
    end

    -- auto_shot
    -- counter_shot,if=equipped.sephuzs_secret&target.debuff.casting.react&cooldown.buff_sephuzs_secret.up&!buff.sephuzs_secret.up
    -- Counter Shot -> User request
    if S.CounterShot:IsReady() and RubimRH.InterruptsON() and Target:IsInterruptible() then
        return S.CounterShot:Cast()
    end
    
    


    --    if S.MendPet:IsCastable() and Pet:IsActive() and (GetEnemiesCount() < 3)  and Pet:HealthPercentage() > 0 and Pet:HealthPercentage() <= 95 and not Pet:Buff(S.MendPet) then
    --        return S.MendPet:Cast()
    --    end

    --    if Pet:IsDeadOrGhost() and (GetEnemiesCount() < 3) then
    --        return S.MendPet:Cast()
    --    elseif not Pet:IsActive() and (GetEnemiesCount() < 3) then
    --        return S.MendPet:Cast()
    --    end

    Cds = function()
		-- actions.cds+=/call_action_list,name=essences
-- call_action_list,name=essences
    local ShouldReturn = Essences(); if ShouldReturn and (true) then return ShouldReturn; end
        -- hunters_mark,if=debuff.hunters_mark.down&!buff.trueshot.up
        if S.HuntersMark:IsCastableP() and (Target:DebuffDown(S.HuntersMarkDebuff) and not Player:BuffP(S.TrueshotBuff)) then
            return S.HuntersMark:Cast()
        end
        -- double_tap,if=cooldown.rapid_fire.remains<gcd|cooldown.rapid_fire.remains<cooldown.aimed_shot.remains|target.time_to_die<20
        if S.DoubleTap:IsCastableP() and RubimRH.CDsON() and (S.RapidFire:CooldownRemainsP() < Player:GCD() or S.RapidFire:CooldownRemainsP() < S.AimedShot:CooldownRemainsP() or Target:TimeToDie() < 20) then
            return S.DoubleTap:Cast()
        end
        -- berserking,if=cooldown.trueshot.remains>60
        if S.Berserking:IsCastableP() and RubimRH.CDsON() and (S.Trueshot:CooldownRemainsP() > 60) then
            return S.Berserking:Cast()
        end
        -- blood_fury,if=cooldown.trueshot.remains>30
        if S.BloodFury:IsCastableP() and RubimRH.CDsON() and (S.Trueshot:CooldownRemainsP() > 30) then
            return S.BloodFury:Cast()
        end
        -- ancestral_call,if=cooldown.trueshot.remains>30
        if S.AncestralCall:IsCastableP() and RubimRH.CDsON() and (S.Trueshot:CooldownRemainsP() > 30) then
            return S.AncestralCall:Cast()
        end
        -- fireblood,if=cooldown.trueshot.remains>30
        if S.Fireblood:IsCastableP() and RubimRH.CDsON() and (S.Trueshot:CooldownRemainsP() > 30) then
            return S.Fireblood:Cast()
        end
        -- lights_judgment
        if S.LightsJudgment:IsCastableP() and RubimRH.CDsON() then
            return S.LightsJudgment:Cast()
        end
        -- potion,if=buff.trueshot.react&buff.bloodlust.react|buff.trueshot.up&target.health.pct<20&talent.careful_aim.enabled|target.time_to_die<2
        -- trueshot,if=focus>60&(buff.precise_shots.down&cooldown.rapid_fire.remains&target.time_to_die>cooldown.trueshot.duration_guess+duration|target.health.pct<20|!talent.careful_aim.enabled)|target.time_to_die<15
        if S.Trueshot:IsCastableP() and RubimRH.CDsON() and Player:Focus() > 60 and (Player:BuffDownP(S.PreciseShotsBuff) and bool(S.RapidFire:CooldownRemainsP()) and Target:TimeToDie() > S.Trueshot:CooldownRemainsP() + S.TrueshotBuff:BaseDuration() or (Target:HealthPercentage() < 20 or not S.CarefulAim:IsAvailable())) then
            return S.Trueshot:Cast()
        end
    end

    St = function()
        -- explosive_shot
        if S.ExplosiveShot:IsCastableP() then
            return S.ExplosiveShot:Cast()
        end
        -- barrage,if=active_enemies>1
        if S.Barrage:IsReadyP() and (not Player:IsMoving() and GetEnemiesCount() > 1) then
            return S.Barrage:Cast()
        end
        -- a_murder_of_crows
        if S.AMurderofCrows:IsCastableP() then
            return S.AMurderofCrows:Cast()
        end
        -- serpent_sting,if=refreshable&!action.serpent_sting.in_flight
        if S.SerpentSting:IsCastableP() and (Target:DebuffRefreshableCP(S.SerpentStingDebuff) and not S.SerpentSting:InFlight()) then
            return S.SerpentSting:Cast()
        end
        -- rapid_fire,if=buff.trueshot.down|focus<70
        if S.RapidFire:IsCastableP() and (Player:BuffDownP(S.TrueshotBuff) or Player:Focus() < 70) then
            return S.RapidFire:Cast()
        end
        -- arcane_shot,if=buff.trueshot.up&buff.master_marksman.up
        if S.ArcaneShot:IsCastableP() and (Player:BuffP(S.MasterMarksmanBuff) and Player:BuffP(S.TrueshotBuff)) then
            return S.ArcaneShot:Cast()
        end
        -- aimed_shot,if=buff.trueshot.up|(buff.double_tap.down|ca_execute)&buff.precise_shots.down|full_recharge_time<cast_time
        if S.AimedShot:IsReadyP() and not Player:IsMoving() and (Player:BuffP(S.TrueshotBuff) or (Player:BuffDownP(S.DoubleTap)) and Player:BuffDownP(S.PreciseShotsBuff) or S.AimedShot:FullRechargeTime() < S.AimedShot:CastTime()) then
            return S.AimedShot:Cast()
        end
        -- piercing_shot
        if S.PiercingShot:IsCastableP() then
            return S.PiercingShot:Cast()
        end
        -- arcane_shot,if=buff.trueshot.down&(buff.precise_shots.up&(focus>41|buff.master_marksman.up)|(focus>50&azerite.focused_fire.enabled|focus>75)&(cooldown.trueshot.remains>5|focus>80)|target.time_to_die<5)
        if S.ArcaneShot:IsCastableP() and (Player:BuffDownP(S.TrueshotBuff) and (Player:BuffP(S.PreciseShotsBuff) and (Player:Focus() > 41 or Player:BuffP(S.MasterMarksmanBuff)) or (Player:Focus() > 50 and S.FocusedFire:AzeriteEnabled() or Player:Focus() > 75) and (S.Trueshot:CooldownRemainsP() > 5 or Player:Focus() > 80) or Target:TimeToDie() < 5)) then
			return S.ArcaneShot:Cast()
        end
        -- steady_shot
        if S.SteadyShot:IsCastableP() then
            return S.SteadyShot:Cast()
        end
    end

    Trickshots = function()
        -- barrage
        if S.Barrage:IsReadyP() and (not Player:IsMoving()) then
            return S.Barrage:Cast()
        end
        -- explosive_shot
        if S.ExplosiveShot:IsCastableP() then
            return S.ExplosiveShot:Cast()
        end
		-- aimed_shot,if=buff.trick_shots.up&ca_execute&buff.double_tap.up
		if S.AimedShot:IsReadyP() and not Player:IsMoving() and (Player:BuffP(S.TrickShotsBuff) and Player:BuffP(S.DoubleTap)) then
			return S.AimedShot:Cast()
		end
        -- rapid_fire,if=buff.trick_shots.up&(azerite.focused_fire.enabled|azerite.in_the_rhythm.rank>1|azerite.surging_shots.enabled|talent.streamline.enabled)
        if S.RapidFire:IsCastableP() and (Player:BuffP(S.TrickShotsBuff) and (S.FocusedFire:AzeriteEnabled() or S.IntheRhythm:AzeriteRank() > 1 or S.SurgingShots:AzeriteEnabled() or S.Streamline:IsAvailable())) then
            return S.RapidFire:Cast()
        end
        -- aimed_shot,if=buff.trick_shots.up&(buff.precise_shots.down|cooldown.aimed_shot.full_recharge_time<action.aimed_shot.cast_time)
        if S.AimedShot:IsReadyP() and not Player:IsMoving() and (Player:BuffP(S.TrickShotsBuff) and (Player:BuffDownP(S.PreciseShotsBuff) or S.AimedShot:FullRechargeTimeP() < S.AimedShot:CastTime())) then
            return S.AimedShot:Cast()
        end
        -- rapid_fire,if=buff.trick_shots.up
        if S.RapidFire:IsCastableP() and (Player:BuffP(S.TrickShotsBuff)) then
            return S.RapidFire:Cast()
        end
        -- multishot,if=buff.trick_shots.down|buff.precise_shots.up|focus>70
        if S.Multishot:IsCastableP() and (Player:BuffDownP(S.TrickShotsBuff) or Player:BuffP(S.PreciseShotsBuff) and not Player:BuffP(S.TrueshotBuff) or Player:Focus() > 70) then
            return S.Multishot:Cast()
        end
        -- piercing_shot
        if S.PiercingShot:IsCastableP() then
            return S.PiercingShot:Cast()
        end
        -- a_murder_of_crows
        if S.AMurderofCrows:IsCastableP() then
            return S.AMurderofCrows:Cast()
        end
        -- serpent_sting,if=refreshable&!action.serpent_sting.in_flight
        if S.SerpentSting:IsCastableP() and (Target:DebuffRefreshableCP(S.SerpentStingDebuff) and not S.SerpentSting:InFlight()) then
            return S.SerpentSting:Cast()
        end
        -- steady_shot
        if S.SteadyShot:IsCastableP() then
            return S.SteadyShot:Cast()
        end
    end

    if not Player:AffectingCombat() and RubimRH.PrecombatON() then
        local Precombat = Precombat();
        if Precombat then
            return Precombat;
        end
        return 0, 462338
    end
    if RubimRH.TargetIsValid() then
        -- auto_shot
        -- use_items,if=buff.trueshot.up|!talent.calling_the_shots.enabled|target.time_to_die<20
        -- call_action_list,name=cds
        if (true) then
            local ShouldReturn = Cds();
            if ShouldReturn then
                return ShouldReturn;
            end
        end
        -- call_action_list,name=st,if=active_enemies<3
        if (GetEnemiesCount() < 3 or not RubimRH.AoEON()) then
            local ShouldReturn = St();
            if ShouldReturn then
                return ShouldReturn;
            end
        end
        -- call_action_list,name=trickshots,if=active_enemies>2
        if (GetEnemiesCount() > 2 and RubimRH.AoEON()) then
            local ShouldReturn = Trickshots();
            if ShouldReturn then
                return ShouldReturn;
            end
        end
    end

    return 0, 135328
end
RubimRH.Rotation.SetAPL(254, APL)
local function PASSIVE()

    if S.Exhilaration:IsReady() and Player:HealthPercentage() <= RubimRH.db.profile[254].sk1 then
        return S.Exhilaration:Cast()
    end
    if S.AspectoftheTurtle:IsReady() and Player:HealthPercentage() <= RubimRH.db.profile[254].sk2 then
        return S.AspectoftheTurtle:Cast()
    end
	if S.SurvivalOfTheFittest:IsReady() and S.SurvivalOfTheFittest:IsAvailable() and Player:HealthPercentage() <= RubimRH.db.profile[254].sk3 then
        return S.SurvivalOfTheFittest:Cast()
    end

    return RubimRH.Shared()
end

RubimRH.Rotation.SetPASSIVE(254, PASSIVE)