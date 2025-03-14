#===================
# Move and Ability Effects
#===================

module BattleHandlers
  CertainStatGainAbility = AbilityHandlerHash.new
  CertainStatGainItem = ItemHandlerHash.new
  StatLossImmunity = ItemHandlerHash.new
  ModifyTypeEffectiveness = AbilityHandlerHash.new  # Tera Shell (damage)
  OnMoveSuccessCheck      = AbilityHandlerHash.new  # Tera Shell (display)
  OnInflictingStatus      = AbilityHandlerHash.new  # Poison Puppeteer
  OnTerrainChangeAbility                  = AbilityHandlerHash.new
  def self.triggerCertainStatGainAbility(ability, battler, battle, stat, user, increment)
    CertainStatGainAbility.trigger(ability, battler, battle, stat, user,increment)
  end

  def self.triggerOnStatGain(ability, battler, stat, user, increment)
    OnStatGain.trigger(ability, battler, stat, user, increment)
  end

  def self.triggerCertainStatGainItem(item, battler, stat, user, increment, battle, forced)
    return CertainStatGainItem.trigger(CertainStatGainItem, item, battler, stat, user, increment, battle, forced)
  end

  def self.triggerStatLossImmunity(item, battler, stat, battle, show_message)
    return StatLossImmunity.trigger(StatLossImmunity, item, battler, stat, battle, show_message)
  end

  def self.triggerOnTerrainChange(ability, battler, battle)
    OnTerrainChange.trigger(ability, battler, battle)
  end

  def self.triggerModifyTypeEffectiveness(ability, user, target, move, battle, effectiveness)
    ModifyTypeEffectiveness.trigger(ability, user, target, move, battle, effectiveness, ret: effectiveness)
  end

  def self.triggerOnMoveSuccessCheck(ability, user, target, move, battle)
    OnMoveSuccessCheck.trigger(ability, user, target, move, battle)
  end

  def self.triggerOnInflictingStatus(ability, battler, user, status)
    OnInflictingStatus.trigger(ability, battler, user, status)
  end
end
#===============================================================================
# Item Effects
#===============================================================================

class Pokemon
  def getEggMovesList
    baby = GameData::Species.get(species).get_baby_species
    form = GameData::Species.get(baby).form
    egg = GameData::Species.get_species_form(baby,form).egg_moves
    return egg
  end
  def has_egg_move?
    return false if egg? || shadowPokemon?
    getEggMovesList.each { |m| return true if !hasMove?(m[1]) }
    return false
  end
end

module Effectiveness

  module_function

  def ineffective_type?(attack_type, defend_type1, defend_type2 = nil, defend_type3 = nil)
    value = calculate(attack_type, defend_type1, defend_type2, defend_type3)
    return ineffective?(value)
  end

  def not_very_effective_type?(attack_type, defend_type1, defend_type2 = nil, defend_type3 = nil)
    value = calculate(attack_type, defend_type1, defend_type2, defend_type3)
    return not_very_effective?(value)
  end

  def resistant_type?(attack_type, defend_type1, defend_type2 = nil, defend_type3 = nil)
    value = calculate(attack_type, defend_type1, defend_type2, defend_type3)
    return resistant?(value)
  end

  def normal_type?(attack_type, defend_type1, defend_type2 = nil, defend_type3 = nil)
    value = calculate(attack_type, defend_type1, defend_type2, defend_type3)
    return normal?(value)
  end

  def super_effective_type?(attack_type, defend_type1, defend_type2 = nil, defend_type3 = nil)
    value = calculate(attack_type, defend_type1, defend_type2, defend_type3)
    return super_effective?(value)
  end
end

#Rage Fist
class PokeBattle_Battle
  attr_reader :rage_hit
  attr_reader   :activedAbility # Check if a Pokémon already actived its ability in a battle (Used for Dauntless Shield, etc)
  def isBattlerActivedAbility?(user) ; return @activedAbility[user.index & 1][user.pokemonIndex] ; end
  def setBattlerActivedAbility(user,value=true) ; @activedAbility[user.index & 1][user.pokemonIndex] = value ; end
  def getBattlerHit(user)
    if user.index.nil?
      return 0
    else
      return @rage_hit[user.index & 1][user.pokemonIndex]
    end
  end
  def addBattlerHit(user,qty=1) ; @rage_hit[user.index & 1][user.pokemonIndex] += qty ; end
  def addFaintedCount(user) ; @fainted_count[user.index & 1] += 1 ; end
  def getFaintedCount(user)
    if user.index.nil?
      return 0
    else
      party = pbParty(user.index)
      count = 0
      party.each {|pkmn| count += 1 if pkmn.fainted?}
      PBAI.log_misc("Fainted count: #{count}")
      return count
    end
  end
  def pbCanShowCommands?(idxBattler)
    battler = @battlers[idxBattler]
    return false if !battler || battler.fainted?
    return false if battler.usingMultiTurnAttack?
    return false if battler.effects[PBEffects::CommanderTatsugiri]
    return true
  end

end
class PokeBattle_Move_552 < PokeBattle_Move
  def pbBaseDamage(baseDmg, user, target)
    rage_hit = @battle.getBattlerHit(user)
    return 50 if rage_hit.nil?
    dmg = [baseDmg + 50  * rage_hit,350].min
    return dmg
  end
end

BattleHandlers::DamageCalcUserAbility.add(:ROCKYPAYLOAD,
  proc { |ability,user,target,move,mults,baseDmg,type|
    mults[:attack_multiplier] *= 1.5 if type == :ROCK
  }
)


class PokeBattle_Move
  def pbChangeUsageCounters(user,specialUsage)
    user.effects[PBEffects::FuryCutter]   = 0
    user.effects[PBEffects::ParentalBond] = 0
    user.effects[PBEffects::EchoChamber] = 0
    user.effects[PBEffects::Ambidextrous] = 0
    user.effects[PBEffects::Ricochet] = 0
    user.effects[PBEffects::ProtectRate]  = 1
    @battle.field.effects[PBEffects::FusionBolt]  = false
    @battle.field.effects[PBEffects::FusionFlare] = false
  end

  def pbBeamMove?;            return beamMove?; end
  def pbSoundMove?;           return soundMove?; end
  def pbHammerMove?;           return hammerMove?; end
  def headMove?
    head = [:HEADSMASH,:HEADBUTT,:CROWNRUSH,:SKULLBLITZ,
      :SKULLBASH,:HEADCHARGE,:IRONHEAD,:HEADLONGRUSH,:ZENHEADBUTT]
    return head.include?(@id)
  end

  def pbNumHits(user,targets)
    if user.hasActiveAbility?(:PARENTALBOND) && pbDamagingMove? &&
       !chargingTurnMove? && targets.length==1
      # Record that Parental Bond applies, to weaken the second attack
      user.effects[PBEffects::ParentalBond] = 3
      return 2
    end
    if user.hasActiveAbility?(:AMBIDEXTROUS) && pbDamagingMove? && punchingMove? && !chargingTurnMove? && targets.length==1
      # Record that Parental Bond applies, to weaken the second attack
      user.effects[PBEffects::Ambidextrous] = 3
      return 2
    end
    if user.hasActiveAbility?(:ECHOCHAMBER) && @battle.field.field_effects != :EchoChamber && pbDamagingMove? && soundMove? &&
       !chargingTurnMove? && targets.length==1
      # Record that Parental Bond applies, to weaken the second attack
      user.effects[PBEffects::EchoChamber] = 3
      return 2
    end
    if @battle.field.field_effects == :EchoChamber && !user.hasActiveAbility?(:ECHOCHAMBER) && pbDamagingMove? && Fields::ECHO_MOVES.include?(@id) &&
       !chargingTurnMove? && targets.length==1
      # Record that Parental Bond applies, to weaken the second attack
      user.effects[PBEffects::EchoChamber] = 3
      return 2
    end
    if @battle.field.field_effects == :Mirror && pbDamagingMove? && Fields::RICOCHET_MOVES.include?(@id) &&
       !chargingTurnMove? && targets.length==1
      # Record that Parental Bond applies, to weaken the second attack
      user.effects[PBEffects::Ricochet] = 3
      return 2
    end
    return 1
  end

  def pbShowAnimation(id,user,targets,hitNum=0,showAnimation=true)
    return if !showAnimation
    if (user.effects[PBEffects::ParentalBond]==1 || user.effects[PBEffects::Ambidextrous]==1 || user.effects[PBEffects::EchoChamber] == 1)
      @battle.pbCommonAnimation("ParentalBond",user,targets)
    else
      @battle.pbAnimation(id,user,targets,hitNum)
    end
  end
  #=============================================================================
  # Move's type calculation
  #=============================================================================
  def pbBaseType(user)
    ret = @type
    if ret && user.abilityActive?
      ret = BattleHandlers.triggerMoveBaseTypeModifierAbility(user.ability,user,self,ret)
    end
    return ret
  end

  #=============================================================================
  # Type effectiveness calculation
  #=============================================================================
  def pbCalcTypeMod(moveType,user,target)
    return Effectiveness::NORMAL_EFFECTIVE if !moveType
    return Effectiveness::NORMAL_EFFECTIVE if moveType == :GROUND &&
       target.pbHasType?(:FLYING) && target.hasActiveItem?(:IRONBALL)
    # Determine types
    tTypes = target.pbTypes(true)
    # Get effectivenesses
    typeMods = [Effectiveness::NORMAL_EFFECTIVE_ONE] * 3   # 3 types max
    if moveType == :SHADOW
      if target.shadowPokemon?
        typeMods[0] = Effectiveness::NOT_VERY_EFFECTIVE_ONE
      else
        typeMods[0] = Effectiveness::SUPER_EFFECTIVE_ONE
      end
    else
      tTypes.each_with_index do |type,i|
        typeMods[i] = pbCalcTypeModSingle(moveType,type,user,target)
      end
    end
    # Multiply all effectivenesses together
    ret = 1
    typeMods.each { |m| ret *= m }
    if (target.hasActiveAbility?([:TERASHELL,:TERAFORMZERO]) && target.hp == target.totalhp || target.hasActiveAbility?(:REVERSEROOM))
      ret = BattleHandlers.triggerModifyTypeEffectiveness(target.ability, user, target, self, @battle, ret)
    end
    return ret
  end

  #=============================================================================
  # Accuracy check
  #=============================================================================
  def pbBaseAccuracy(user,target); return @accuracy; end

  # Accuracy calculations for one-hit KO moves and "always hit" moves are
  # handled elsewhere.
  def pbAccuracyCheck(user,target)
    # "Always hit" effects and "always hit" accuracy
    return true if target.effects[PBEffects::Telekinesis]>0
    return true if target.effects[PBEffects::Minimize] && tramplesMinimize?(1)
    baseAcc = pbBaseAccuracy(user,target)
    return true if baseAcc==0
    # Calculate all multiplier effects
    modifiers = {}
    modifiers[:base_accuracy]  = baseAcc
    modifiers[:accuracy_stage] = user.stages[:ACCURACY]
    modifiers[:evasion_stage]  = target.stages[:EVASION]
    modifiers[:accuracy_multiplier] = 1.0
    modifiers[:evasion_multiplier]  = 1.0
    pbCalcAccuracyModifiers(user,target,modifiers)
    # Check if move can't miss
    return true if modifiers[:base_accuracy] == 0
    # Calculation
    accStage = [[modifiers[:accuracy_stage], -6].max, 6].min + 6
    evaStage = [[modifiers[:evasion_stage], -6].max, 6].min + 6
    stageMul = [3,3,3,3,3,3, 3, 4,5,6,7,8,9]
    stageDiv = [9,8,7,6,5,4, 3, 3,3,3,3,3,3]
    accuracy = 100.0 * stageMul[accStage] / stageDiv[accStage]
    evasion  = 100.0 * stageMul[evaStage] / stageDiv[evaStage]
    accuracy = (accuracy * modifiers[:accuracy_multiplier]).round
    evasion  = (evasion  * modifiers[:evasion_multiplier]).round
    evasion = 1 if evasion < 1
    # Calculation
    return @battle.pbRandom(100) < modifiers[:base_accuracy] * accuracy / evasion
  end

  def pbCalcAccuracyModifiers(user,target,modifiers)
    # Ability effects that alter accuracy calculation
    if user.abilityActive?
      BattleHandlers.triggerAccuracyCalcUserAbility(user.ability,
         modifiers,user,target,self,@calcType)
    end
    user.eachAlly do |b|
      next if !b.abilityActive?
      BattleHandlers.triggerAccuracyCalcUserAllyAbility(b.ability,
         modifiers,user,target,self,@calcType)
    end
    if target.abilityActive? && !@battle.moldBreaker
      BattleHandlers.triggerAccuracyCalcTargetAbility(target.ability,
         modifiers,user,target,self,@calcType)
    end
    # Item effects that alter accuracy calculation
    if user.itemActive?
      BattleHandlers.triggerAccuracyCalcUserItem(user.item,
         modifiers,user,target,self,@calcType)
    end
    if target.itemActive?
      BattleHandlers.triggerAccuracyCalcTargetItem(target.item,
         modifiers,user,target,self,@calcType)
    end
    # Other effects, inc. ones that set accuracy_multiplier or evasion_stage to
    # specific values
    if @battle.field.effects[PBEffects::Gravity] > 0
      modifiers[:accuracy_multiplier] *= 5 / 3.0
    end
    if @battle.pbWeather == :Fog
      if !user.pbHasType?(:FAIRY)
        modifiers[:accuracy_multiplier] *= 0.8
      end
    end
    if user.effects[PBEffects::MicleBerry]
      user.effects[PBEffects::MicleBerry] = false
      modifiers[:accuracy_multiplier] *= 1.2
    end
    modifiers[:evasion_stage] = 0 if target.effects[PBEffects::Foresight] && modifiers[:evasion_stage] > 0
    modifiers[:evasion_stage] = 0 if target.effects[PBEffects::MiracleEye] && modifiers[:evasion_stage] > 0
  end

  #=============================================================================
  # Critical hit check
  #=============================================================================
  # Return values:
  #   -1: Never a critical hit.
  #    0: Calculate normally.
  #    1: Always a critical hit.
  def pbCritialOverride(user,target); return 0; end

  # Returns whether the move will be a critical hit.
  def pbIsCritical?(user,target)
    return false if target.pbOwnSide.effects[PBEffects::LuckyChant]>0
    return false if target.hasActiveItem?(:MITHRILSHIELD)
    # Set up the critical hit ratios
    ratios = (Settings::NEW_CRITICAL_HIT_RATE_MECHANICS) ? [24,8,2,1] : [16,8,4,3,2]
    c = 0
    # Ability effects that alter critical hit rate
    if c>=0 && user.abilityActive?
      c = BattleHandlers.triggerCriticalCalcUserAbility(user.ability,user,target,c)
    end
    if c>=0 && target.abilityActive? && !@battle.moldBreaker
      c = BattleHandlers.triggerCriticalCalcTargetAbility(target.ability,user,target,c)
    end
    # Item effects that alter critical hit rate
    if c>=0 && user.itemActive?
      c = BattleHandlers.triggerCriticalCalcUserItem(user.item,user,target,c)
    end
    if c>=0 && target.itemActive?
      c = BattleHandlers.triggerCriticalCalcTargetItem(target.item,user,target,c)
    end
    return false if c<0
    # Move-specific "always/never a critical hit" effects
    case pbCritialOverride(user,target)
    when 1  then return true
    when -1 then return false
    end
    # Other effects
    return true if c>50   # Merciless
    return true if user.effects[PBEffects::LaserFocus]>0
    c += 1 if highCriticalRate?
    c += user.effects[PBEffects::FocusEnergy]
    c += 1 if user.inHyperMode? && @type == :SHADOW
    c = ratios.length-1 if c>=ratios.length
    # Calculation
    return @battle.pbRandom(ratios[c])==0
  end

  #=============================================================================
  # Damage calculation
  #=============================================================================
  def pbBaseDamage(baseDmg,user,target);              return baseDmg;    end
  def pbBaseDamageMultiplier(damageMult,user,target); return damageMult; end
  def pbModifyDamage(damageMult,user,target);         return damageMult; end

  def pbGetAttackStats(user,target)
    if specialMove?
      if user.hasActiveAbility?(:VOCALFRY) && soundMove?
        return user.attack, user.stages[:SPECIAL_ATTACK]+6
      end
      return user.spatk, user.stages[:SPECIAL_ATTACK]+6
    end
    return user.attack, user.stages[:ATTACK]+6
  end

  def pbGetDefenseStats(user,target)
    if specialMove?
      return target.spdef, target.stages[:SPECIAL_DEFENSE]+6
    end
    return target.defense, target.stages[:DEFENSE]+6
  end

  def pbCalcDamage(user,target,numTargets=1)
    return if statusMove?
    if target.damageState.disguise
      target.damageState.calcDamage = 1
      return
    end
    stageMul = [2,2,2,2,2,2, 2, 3,4,5,6,7,8]
    stageDiv = [8,7,6,5,4,3, 2, 2,2,2,2,2,2]
    # Get the move's type
    type = @calcType   # nil is treated as physical
    # Calculate whether this hit deals critical damage
    target.damageState.critical = pbIsCritical?(user,target)
    # Calcuate base power of move
    baseDmg = pbBaseDamage(@baseDamage,user,target)
    # Calculate user's attack stat
    atk, atkStage = pbGetAttackStats(user,target)
    if !target.hasActiveAbility?(:UNAWARE) || @battle.moldBreaker
      atkStage = 6 if target.damageState.critical && atkStage<6
      atk = (atk.to_f*stageMul[atkStage]/stageDiv[atkStage]).floor
    end
    # Calculate target's defense stat
    defense, defStage = pbGetDefenseStats(user,target)
    if !user.hasActiveAbility?(:UNAWARE)
      defStage = 6 if target.damageState.critical && defStage>6
      defStage = 6 if @function == "0E0"
      defense = (defense.to_f*stageMul[defStage]/stageDiv[defStage]).floor
      defense *= 0.75 if @function == "0E0"
    end
    # Calculate all multiplier effects
    multipliers = {
      :base_damage_multiplier  => 1.0,
      :attack_multiplier       => 1.0,
      :defense_multiplier      => 1.0,
      :final_damage_multiplier => 1.0
    }
    pbCalcDamageMultipliers(user,target,numTargets,type,baseDmg,multipliers)
    # Main damage calculation
    baseDmg = [(baseDmg * multipliers[:base_damage_multiplier]).round, 1].max
    atk     = [(atk     * multipliers[:attack_multiplier]).round, 1].max
    defense = [(defense * multipliers[:defense_multiplier]).round, 1].max
    damage  = (((2.0 * user.level / 5 + 2).floor * baseDmg * atk / defense).floor / 50).floor + 2
    damage  = [(damage  * multipliers[:final_damage_multiplier]).round, 1].max
    target.damageState.calcDamage = damage
  end
  #=============================================================================
  # Additional effect chance
  #=============================================================================
  def pbAdditionalEffectChance(user,target,effectChance=0)
    return 0 if target.hasActiveAbility?(:SHIELDDUST) && !@battle.moldBreaker
    ret = (effectChance>0) ? effectChance : @addlEffect
    if Settings::MECHANICS_GENERATION >= 6 || @function != "0A4"   # Secret Power
      ret *= 2 if user.hasActiveAbility?(:SERENEGRACE) ||
                  user.pbOwnSide.effects[PBEffects::Rainbow]>0
    end
    ret = 100 if $DEBUG && Input.press?(Input::CTRL)
    ret = 100 if @id == :SCORCHINGSANDS && @battle.field.field_effects == :Desert
    return ret
  end

  # NOTE: Flinching caused by a move's effect is applied in that move's code,
  #       not here.
  def pbFlinchChance(user,target)
    return 0 if flinchingMove?
    return 0 if target.hasActiveAbility?(:SHIELDDUST) && !@battle.moldBreaker
    return 0 if target.hasActiveAbility?(:INNERFOCUS) && !@battle.moldBreaker
    ret = 0
    if user.hasActiveAbility?(:STENCH,true)
      ret = 10
    elsif user.hasActiveItem?([:KINGSROCK,:RAZORFANG],true)
      ret = 10
    end
    ret *= 2 if user.hasActiveAbility?(:SERENEGRACE) ||
                user.pbOwnSide.effects[PBEffects::Rainbow]>0
    return ret
  end
end

module BattleHandlers
  StatLossImmunityAbilityNonIgnorableSandy = AbilityHandlerHash.new   # Unshaken
  StatLossImmunityItem               = ItemHandlerHash.new #Unshaken Orb
  ItemOnFlinch                       = ItemHandlerHash.new
  def self.triggerStatLossImmunityAbilityNonIgnorableSandy(ability,battler,stat,battle,showMessages)
    ret = StatLossImmunityAbilityNonIgnorableSandy.trigger(ability,battler,stat,battle,showMessages)
    return (ret!=nil) ? ret : false
  end
  def self.triggerStatLossImmunityItem(ability,battler,stat,battle,showMessages)
    ret = StatLossImmunityItem.trigger(ability,battler,stat,battle,showMessages)
    return (ret!=nil) ? ret : false
  end
  def self.triggerItemOnFlinch(item,battler,battle)
    ret = ItemOnFlinch.trigger(item,battler,battle)
    return (ret!=nil) ? ret : false
  end
end

# Focus Policy
BattleHandlers::ItemOnFlinch.add(:FOCUSPOLICY,
  proc { |item,battler,battle|
    battler.pbRaiseStatStageByAbility(:SPEED,2,battler)
  }
)

class PokeBattle_Move_00D < PokeBattle_FreezeMove
  def pbBaseAccuracy(user,target)
    return 0 if @battle.pbWeather == :Hail
    return 0 if @battle.pbWeather == :Sleet
    return super
  end
end

class PokeBattle_Move_015 < PokeBattle_ConfuseMove
  def hitsFlyingTargets?; return true; end

  def pbBaseAccuracy(user,target)
    return super if target.hasUtilityUmbrella?
    case @battle.pbWeather
    when :Sun, :HarshSun
      return 50
    when :Rain, :HeavyRain, :Storm
      return 0
    end
    return super
  end
end

class PokeBattle_Move_008 < PokeBattle_ParalysisMove
  def hitsFlyingTargets?; return true; end

  def pbBaseAccuracy(user,target)
    return super if target.hasUtilityUmbrella?
    case @battle.pbWeather
    when :Sun, :HarshSun
      return 50
    when :Rain, :HeavyRain, :Storm
      return 0
    end
    return super
  end
end

BattleHandlers::EORHealingAbility.add(:RESURGENCE,
  proc { |ability,battler,battle|
    next if !battler.canHeal?
    battle.pbShowAbilitySplash(battler)
    battler.pbRecoverHP(battler.totalhp/16)
    if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    else
      battle.pbDisplay(_INTL("{1}'s {2} restored its HP.",battler.pbThis,battler.abilityName))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::EORHealingAbility.add(:ASPIRANT,
  proc { |ability,battler,battle|
    wishHeal = $game_variables[103]
    $game_variables[101] -= 1
    if $game_variables[101]==0
      wishMaker = $game_variables[102]
      battler.pbRecoverHP(wishHeal)
      battle.pbDisplay(_INTL("{1}'s wish came true!",wishMaker))
    end
    next if $game_variables[101]>0
    if $game_variables[101]<0
      battle.pbShowAbilitySplash(battler)
      if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
        $game_variables[103] = (battler.totalhp/2)
        $game_variables[102] = battler.pbThis
        $game_variables[101] += 2
        battle.pbDisplay(_INTL("{1} made a wish!",battler.pbThis))
      else
        battle.pbDisplay(_INTL("{1} made a wish with {2}",battler.pbThis,battler.abilityName))
      end
    end
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:STEAMENGINE,
  proc { |ability,user,target,move,type,battle|
    next (pbBattleMoveImmunityStatAbility(user,target,move,type,:WATER,:SPEED,6,battle) || pbBattleMoveImmunityStatAbility(user,target,move,type,:FIRE,:SPEED,6,battle))
  }
)

BattleHandlers::SpeedCalcAbility.add(:SLUDGERUSH,
  proc { |ability,battler,mult|
    next mult*2 if [:Poison,:Swamp].include?(battler.battle.field.field_effects)
    next mult*2 if battler.battle.field.terrain == :Poison
  }
)

BattleHandlers::TargetAbilityOnHit.add(:SPLINTER,
  proc { |ability,target,battler,move,battle|
    next if battler.pbOpposingSide.effects[PBEffects::StealthRock] == 1
    next if !move.contactMove?
    battle.pbShowAbilitySplash(battler)
    if battle.field.weather == :Windy || battle.field.field_effects == :WindTunnel
      battle.pbDisplay(_INTL("The wind prevented {1}'s {2} from working!",battler.pbThis,battler.abilityName))
    else
      battle.scene.pbAnimation(GameData::Move.get(:STEALTHROCK).id,battler,battler)
      battler.pbOpposingSide.effects[PBEffects::StealthRock] = 1
      battle.pbDisplay(_INTL("{1}'s {2} set Stealth Rocks!",battler.pbThis,battler.abilityName))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:WEBWEAVER,
  proc { |ability,target,battler,move,battle|
    next if battler.pbOpposingSide.effects[PBEffects::StickyWeb] == 1
    next if !move.contactMove?
    battle.pbShowAbilitySplash(battler)
    if battle.field.weather == :Windy || battle.field.field_effects == :WindTunnel
      battle.pbDisplay(_INTL("The wind prevented {1}'s {2} from working!",battler.pbThis,battler.abilityName))
    else
      battle.scene.pbAnimation(GameData::Move.get(:STICKYWEB).id,battler,battler)
      battler.pbOpposingSide.effects[PBEffects::StickyWeb] = 1
      battle.pbDisplay(_INTL("{1}'s {2} set Sticky Web!",battler.pbThis,battler.abilityName))
    end
    battle.pbHideAbilitySplash(battler)
  }
)


BattleHandlers::TargetAbilityOnHit.add(:SEEDSOWER,
  proc { |ability, user, target, move, battle|
    next if !move.damagingMove?
    next if battle.field.terrain == :Grassy
    battle.pbShowAbilitySplash(target)
    battle.pbDisplay(_INTL("Grass grew to cover the battlefield!"))
    battle.pbStartTerrain(target, :Grassy)
    battle.scene.pbRefreshEverything
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:TRASHSHIELD,
  proc { |ability,user,target,move,mults,baseDmg,type|
    if Effectiveness.super_effective?(target.damageState.typeMod)
      mults[:final_damage_multiplier] *= 1.5
    else
      mults[:final_damage_multiplier] *= 0.75
    end
  }
)

BattleHandlers::TargetAbilityOnHit.add(:TOXICDEBRIS,
  proc { |ability,target,battler,move,battle|
    next if battler.pbOpposingSide.effects[PBEffects::ToxicSpikes] == 2
    next unless move.pbContactMove?(target)
    battle.pbShowAbilitySplash(battler)
    if battle.field.weather == :Windy || battle.field.field_effects == :WindTunnel
      battle.pbDisplay(_INTL("The wind prevented {1}'s {2} from working!",battler.pbThis,battler.abilityName))
    else
      battle.scene.pbAnimation(GameData::Move.get(:TOXICSPIKES).id,battler,battler)
      battler.pbOpposingSide.effects[PBEffects::ToxicSpikes] += 1
      battle.pbDisplay(_INTL("{1}'s {2} set Toxic Spikes!",battler.pbThis,battler.abilityName))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

class PokeBattle_Battle
  alias initialize_ex initialize
  def initialize(scene,p1,p2,player,opponent)
    initialize_ex(scene,p1,p2,player,opponent)
    $game_variables[101] = -1
  end
end

BattleHandlers::EORHealingAbility.add(:HOPEFULTOLL,
  proc { |ability,battler,battle|
    has_status = false
    battle.pbParty(battler.index).each_with_index do |pkmn,i|
      next if !pkmn || !pkmn.able? || pkmn.status==:NONE
      has_status = true
      pkmn.status = :NONE
    end
    battler.status = :NONE
    if has_status
      battle.pbShowAbilitySplash(battler)
      if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1} rang a healing bell!",battler.pbThis))
      else
        battle.pbDisplay(_INTL("{1} sounded a {2}",battler.pbThis,battler.abilityName))
      end
    end
    if battle.doublebattle
      battle.battlers[0].status = :NONE
      battle.battlers[2].status = :NONE
    end
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::EORWeatherAbility.add(:ACIDDRAIN,
  proc { |ability,weather,battler,battle|
    next unless weather==:AcidRain
    next if !battler.canHeal?
    battle.pbShowAbilitySplash(battler)
    battler.pbRecoverHP(battler.totalhp/16)
    if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    else
      battle.pbDisplay(_INTL("{1}'s {2} restored its HP.",battler.pbThis,battler.abilityName))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::EORWeatherAbility.copy(:POISONHEAL,:ACIDDRAIN)

BattleHandlers::CriticalCalcTargetAbility.copy(:BATTLEARMOR,:MAGMAARMOR)

BattleHandlers::AbilityOnSwitchIn.add(:GAIAFORCE,
  proc { |ability,battler,battle|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1} is gathering power from the earth!",battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:BEADSOFRUIN,
  proc { |ability, battler, battle, switch_in|
  battle.pbShowAbilitySplash(battler)
  battle.pbDisplay(_INTL("{1}'s Beads of Ruin weakened the Sp. Def of all surrounding Pokémon!", battler.pbThis))
  battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:COMMANDER,
  proc { |ability, battler, battle, switch_in|
    # dondozo = nil
    battler.allAllies.each{|b|
      next if b.species != :DONDOZO
      next if b.effects[PBEffects::CommanderDondozo] >= 0
      battle.pbShowAbilitySplash(battler)
      battle.pbDisplay(_INTL("{1} goes inside the mouth of {2}!", battler.pbThis, b.pbThis(true)))
      b.effects[PBEffects::CommanderDondozo] = battler.form
      battler.effects[PBEffects::CommanderTatsugiri] = true
      GameData::Stat.each_main_battle { |stat| 
      #   2.times do
      #     battler.stages[stat.id] += 1 if !user.statStageAtMax?(stat)
      #   end
        b.pbRaiseStatStageByAbility(stat.id, 2, b, false) if b.pbCanRaiseStatStage?(stat.id, b)
      }
      # dondozo = b
      battle.pbHideAbilitySplash(battler)
      break
    }
  }
)
# OnBattlerFainting
BattleHandlers::AbilityOnBattlerFainting.add(:COMMANDER,
  proc { |ability, battler, fainted, battle|
   # next if fainted.species != :DONDOZO
   # next if fainted.effects[PBEffects::CommanderDondozo] == -1
   # next if battler.opposes?(fainted)
    if (fainted.species == :DONDOZO && battler.opposes?(fainted) == false)
      fainted.effects[PBEffects::CommanderDondozo] = -1
      battler.effects[PBEffects::CommanderTatsugiri] = false
    end
  }
)

BattleHandlers::CertainSwitchingUserAbility.add(:COMMANDER,
  proc { |ability, switcher, battle|
    switcher.allAllies.each{|b|
      next if b.species != :TATSUGIRI
      next if b.effects[PBEffects::CommanderTatsugiri]
      battle.pbShowAbilitySplash(b)
      battle.pbDisplay(_INTL("{1} goes inside the mouth of {2}!", b.pbThis, switcher.pbThis(true)))
      switcher.effects[PBEffects::CommanderDondozo] = b.form
      b.effects[PBEffects::CommanderTatsugiri] = true
      GameData::Stat.each_main_battle { |stat|
        switcher.pbRaiseStatStageByAbility(stat.id, 2, switcher,false) if switcher.pbCanRaiseStatStage?(stat.id, switcher)
      }
      battle.pbHideAbilitySplash(b)
      break
    }
  }
)
BattleHandlers::MoveImmunityTargetAbility.add(:COMMANDER,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if (!target.effects[PBEffects::CommanderTatsugiri] || target.effects[PBEffects::CommanderTatsugiri] == false)
    battle.pbDisplay(_INTL("{1} avoided the attack!", target.pbThis)) if show_message
    next true
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:COSTAR,
  proc { |ability, battler, battle, switch_in|
    battler.allAllies.each{|b|
      next if b.index == battler.index
      next if !b.hasAlteredStatStages?
      battle.pbShowAbilitySplash(battler)
      GameData::Stat.each_main_battle { |stat| 
        battler.stages[stat.id] = b.stages[stat.id]
      }
      battle.pbDisplay(_INTL("{1} copied {2}'s stat changes!", battler.pbThis, b.pbThis(true)))
      battle.pbHideAbilitySplash(battler)
      break
    }
  }
)

BattleHandlers::TargetAbilityAfterMoveUse.add(:ANGERSHELL,
  proc { |ability, target, user, move, switched_battlers, battle|
    next if !move.damagingMove?
    next if target.damageState.initialHP<target.totalhp/2 || target.hp>=target.totalhp/2
    battle.pbShowAbilitySplash(target)
    [:ATTACK,:SPECIAL_ATTACK,:SPEED].each{|stat|
      target.pbRaiseStatStageByAbility(stat, 1, target, false) if target.pbCanRaiseStatStage?(stat, target)
    }
    [:DEFENSE,:SPECIAL_DEFENSE].each{|stat|
      target.pbLowerStatStageByAbility(stat, 1, target, false) if target.pbCanLowerStatStage?(stat, target)
    }
    battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::EOREffectAbility.add(:CUDCHEW,
  proc { |ability, battler, battle|
    next if battler.item
    next if !battler.recycleItem
    next if !GameData::Item.get(battler.recycleItem).is_berry?
    next if battler.effects[PBEffects::CudChew] > 0
    battle.pbShowAbilitySplash(battler)
    battler.item = battler.recycleItem
    battler.setRecycleItem(nil)
    battler.pbHeldItemTriggerCheck(battler.item)
    battler.item = nil if battler.item
    # battle.pbDisplay(_INTL("{1} harvested one {2}!", battler.pbThis, battler.itemName))
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:ELECTROMORPHOSIS,
  proc { |ability, user, target, move, battle|
    next if target.fainted?
    next if target.effects[PBEffects::Charge] > 0
    battle.pbShowAbilitySplash(target)
    target.effects[PBEffects::Charge] = 2
    battle.pbDisplay(_INTL("Being hit by {1} charged {2} with power!", move.name, target.pbThis(true)))
    battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:GOODASGOLD,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if !move.statusMove?
    next false if target == user
    next false if battle.moldBreaker == true
    if show_message
      battle.pbShowAbilitySplash(target)
      battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:HADRONENGINE,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    if battle.field.terrain == :Electric
      battle.pbDisplay(_INTL("{1} used the Electric Terrain to energize its futuristic engine!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
      next
    end
    battle.pbDisplay(_INTL("{1} turned the ground into Electric Terrain, energizing its futuristic engine!", battler.pbThis))
    battle.pbStartTerrain(battler, :Electric)
    # NOTE: The ability splash is hidden again in def pbStartTerrain.
  }
)
BattleHandlers::DamageCalcUserAbility.add(:HADRONENGINE,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:attack_multiplier] *= 1.5 if move.specialMove? && user.battle.field.terrain == :Electric
  }
)

BattleHandlers::TargetAbilityOnHit.add(:LINGERINGAROMA,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    next if user.fainted?
    next if user.unstoppableAbility? || user.ability == ability || user.ability == :MUMMY
    next if user.hasActiveItem?(:ABILITYSHIELD)
    oldAbil = nil
    battle.pbShowAbilitySplash(target) if user.opposes?(target)
    if user.affectedByContactEffect?(true)
      oldAbil = user.ability
      battle.pbShowAbilitySplash(user, true, false) if user.opposes?(target)
      user.ability = ability
      battle.pbReplaceAbilitySplash(user) if user.opposes?(target)
       battle.pbDisplay(_INTL("A lingering aroma clings to {1}!", user.pbThis(true)))
      # battle.pbDisplay(_INTL("{1}'s Ability became {2}!", user.pbThis, user.abilityName))
      battle.pbHideAbilitySplash(user) if user.opposes?(target)
    end
    battle.pbHideAbilitySplash(target) if user.opposes?(target)
    user.pbOnLosingAbility(oldAbil)
    user.pbTriggerAbilityOnGainingIt
  }
)

BattleHandlers::PriorityChangeAbility.add(:MYCELIUMMIGHT,
  proc { |ability, battler, move, pri|
    if move.statusMove?
      next -1
    end
  }
)
class PokeBattle_Move
  alias myceliummight_pbChangeUsageCounters pbChangeUsageCounters
  def pbChangeUsageCounters(user, specialUsage)
    myceliummight_pbChangeUsageCounters(user, specialUsage)
    @battle.moldBreaker = true if statusMove? && user.hasActiveAbility?(:MYCELIUMMIGHT)
  end
end

BattleHandlers::CertainStatGainAbility.add(:OPPORTUNIST,
  proc { |ability, battler, battle, stat, user,increment|
    next if !battler.opposes?(user)
    next if battler.statStageAtMax?(stat)
    battle.pbShowAbilitySplash(battler)
    increment.times.each do
      battler.stages[stat] += 1 if !battler.statStageAtMax?(stat)
    end
    battle.pbCommonAnimation("StatUp", battler)
    battle.pbDisplay(_INTL("{1} copied its {2}'s stat changes!", battler.pbThis, user.pbThis(true)))
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:ORICHALCUMPULSE,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    if [:Sun, :HarshSun].include?(battler.battle.pbWeather)
      battle.pbDisplay(_INTL("{1} basked in the sunlight, sending its ancient pulse into a frenzy!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
      next 
    end
    pbBattleWeatherAbility(:Sun, battler, battle)
    battle.pbDisplay(_INTL("{1} turned the sunlight harsh, sending its ancient pulse into a frenzy!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)
BattleHandlers::DamageCalcUserAbility.add(:ORICHALCUMPULSE,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:attack_multiplier] *= 1.5 if move.physicalMove? && [:Sun, :HarshSun].include?(user.effectiveWeather)
  }
)

# Protosynthesis
#===============================================================================
BattleHandlers::AbilityOnSwitchIn.add(:PROTOSYNTHESIS,
  proc { |ability, battler, battle, switch_in|
    next if ![:Sun, :HarshSun].include?(battler.battle.pbWeather) && battler.item != :BOOSTERENERGY && battle.field.field_effects != :Lava
    userStats = battler.plainStats
    highestStatValue = 0
    userStats.each_value { |value| highestStatValue = value if highestStatValue < value }
    # GameData::Stat.each_main_battle do |s|
    [:ATTACK,:DEFENSE,:SPECIAL_ATTACK,:SPECIAL_DEFENSE,:SPEED].each do |s|
      next if userStats[s] < highestStatValue
      battle.pbShowAbilitySplash(battler)
      if battler.item == :BOOSTERENERGY && ![:Sun, :HarshSun].include?(battler.battle.pbWeather) && battle.field.field_effects != :Lava
        battler.pbHeldItemTriggered(battler.item)
        battler.effects[PBEffects::BoosterEnergy] = true
        battle.pbDisplay(_INTL("{1} used its Booster Energy to activate Protosynthesis!", battler.pbThis))
      else
        battle.pbDisplay(_INTL("The heat activated {1}'s Protosynthesis!", battler.pbThis(true)))
      end
      battler.effects[PBEffects::ParadoxStat] = s
      battle.pbDisplay(_INTL("{1}'s {2} was heightened!", battler.pbThis,GameData::Stat.get(s).name))
      battle.pbHideAbilitySplash(battler)
      break
    end
  }
)
BattleHandlers::AbilityOnSwitchIn.add(:QUARKDRIVE,
  proc { |ability, battler, battle, switch_in|
    next if ![:Electric,:Magnetic].include?(battle.field.field_effects) && battle.field.terrain != :Electric && battler.item != :BOOSTERENERGY
    userStats = battler.plainStats
    highestStatValue = 0
    userStats.each_value { |value| highestStatValue = value if highestStatValue < value }
    # GameData::Stat.each_main_battle do |s|
    [:ATTACK,:DEFENSE,:SPECIAL_ATTACK,:SPECIAL_DEFENSE,:SPEED].each do |s|
      next if userStats[s] < highestStatValue
      battle.pbShowAbilitySplash(battler)
      if battler.item == :BOOSTERENERGY && (![:Electric,:Magnetic].include?(battle.field.field_effects) && battle.field.terrain != :Electric)
        battler.pbHeldItemTriggered(battler.item)
        battler.effects[PBEffects::BoosterEnergy] = true
        battle.pbDisplay(_INTL("{1} used its Booster Energy to activate its Quark Drive!", battler.pbThis))
      else
        battle.pbDisplay(_INTL("The Electric Terrain activated {1}'s Quark Drive!", battler.pbThis(true)))
      end
      battler.effects[PBEffects::ParadoxStat] = s
      battle.pbDisplay(_INTL("{1}'s {2} was heightened!", battler.pbThis,GameData::Stat.get(s).name))
      battle.pbHideAbilitySplash(battler)
      break
    end
  }
)
BattleHandlers::OnTerrainChangeAbility.add(:QUARKDRIVE,
proc { |ability, battler, battle, switch_in|
    next if battle.field.terrain == :Electric
    next if [:Magnetic,:Electric].include?(battle.field.field_effects)
    next if battler.effects[PBEffects::BoosterEnergy]
    if battler.item == :BOOSTERENERGY
      battler.pbHeldItemTriggered(battler.item)
      battle.pbDisplay(_INTL("{1} used its Booster Energy to activate its Quark Drive!", battler.pbThis))
      next
    end
    battle.pbDisplay(_INTL("The effects of {1}'s Quark Drive wore off!", battler.pbThis(true)))
    battler.effects[PBEffects::ParadoxStat] = nil
  }
)
BattleHandlers::AbilityOnSwitchOut.add(:PROTOSYNTHESIS,
  proc { |ability, battler, endOfBattle|
    battler.effects[PBEffects::BoosterEnergy] = false
    battler.effects[PBEffects::ParadoxStat] = nil
  }
)
BattleHandlers::AbilityOnSwitchOut.copy(:PROTOSYNTHESIS,:QUARKDRIVE)

BattleHandlers::DamageCalcUserAbility.add(:PROTOSYNTHESIS,
  proc { |ability, user, target, move, mults, baseDmg, type|
    if user.effects[PBEffects::ParadoxStat]
      stat = user.effects[PBEffects::ParadoxStat]
      mults[:attack_multiplier] *= 1.3 if (stat == :ATTACK && move.physicalMove?) ||
                                          (stat == :SPECIAL_ATTACK && move.specialMove?)
    end
  }
)
BattleHandlers::DamageCalcUserAbility.copy(:PROTOSYNTHESIS,:QUARKDRIVE)
BattleHandlers::DamageCalcTargetAbility.add(:PROTOSYNTHESIS,
  proc { |ability, user, target, move, mults, baseDmg, type|
    if user.effects[PBEffects::ParadoxStat]
      stat = user.effects[PBEffects::ParadoxStat]
      mults[:defense_multiplier] *= 1.3 if (stat == :DEFENSE && move.physicalMove?) ||
                                          (stat == :SPECIAL_DEFENSE && move.specialMove?)
    end
  }
)
BattleHandlers::DamageCalcTargetAbility.copy(:PROTOSYNTHESIS,:QUARKDRIVE)
BattleHandlers::SpeedCalcAbility.add(:PROTOSYNTHESIS,
  proc { |ability, battler, mult, ret|
    if battler.effects[PBEffects::ParadoxStat]
      stat = battler.effects[PBEffects::ParadoxStat]
      next stat == :SPEED ? 1.5 : 0
    end
  }
)
BattleHandlers::SpeedCalcAbility.copy(:PROTOSYNTHESIS,:QUARKDRIVE)

BattleHandlers::DamageCalcUserAbility.add(:SHARPNESS,
  proc { |ability,user,target,move,mults,baseDmg,type|
    mod = user.activeField == :Castle ? 1.7 : 1.5
    mults[:base_damage_multiplier] = (mults[:base_damage_multiplier]*mod).round if move.slicingMove?
  }
)

BattleHandlers::DamageCalcUserAbility.copy(:SHARPNESS,:SWORDOFMASTERY)

BattleHandlers::DamageCalcUserAbility.add(:ECHOCHAMBER,
  proc { |ability,user,target,move,mults,baseDmg,type|
    next if user.activeField != :EchoChamber
    mults[:base_damage_multiplier] = (mults[:base_damage_multiplier]*1.2).round if move.soundMove? && move.damagingMove?
  }
)
class Game_Temp
  attr_accessor :fainted_member
end
# EventHandlers.add(:on_start_battle, :fainted_member_count,
#   proc {
#     fainted = 0
#     $player.party.each{|p|
#       next if !p || !p.fainted?
#       fainted += 1
#     }
#     $game_temp.fainted_member = [fainted,0] # used for last respect and maybe supreme overlord
#   }
# )
BattleHandlers::DamageCalcUserAbility.add(:SUPREMEOVERLORD,
  proc { |ability, user, target, move, mults, baseDmg, type|
    next if user.effects[PBEffects::SupremeOverlord] <= 0
    mult = 1
    mult += 0.1 * user.effects[PBEffects::SupremeOverlord]
    mults[:base_damage_multiplier] *= mult
  }
)
BattleHandlers::AbilityOnSwitchIn.add(:SUPREMEOVERLORD,
  proc { |ability, battler, battle, switch_in|
  numFainted = 0
  battler.battle.pbParty(battler.idxOwnSide).each { |b| numFainted += 1 if b.fainted? }
  numFainted = 5 if numFainted > 5
  next if numFainted <= 0
  battle.pbShowAbilitySplash(battler)
  # numFainted = 0
  # battler.battle.pbParty(battler.idxOwnSide).each { |b| numFainted += 1 if b.fainted? }
  battle.pbDisplay(_INTL("{1} gained strength from the fallen!", battler.pbThis))
  battler.effects[PBEffects::SupremeOverlord] = numFainted
  battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SWORDOFRUIN,
  proc { |ability, battler, battle, switch_in|
  battle.pbShowAbilitySplash(battler)
  battle.pbDisplay(_INTL("{1}'s Sword of Ruin weakened the Defense of all surrounding Pokémon!", battler.pbThis))
  battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:TABLETSOFRUIN,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}'s Tablets of Ruin weakened the Attack of all surrounding Pokémon!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:THERMALEXCHANGE,
  proc { |ability, user, target, move, battle|
    next if move.calcType != :FIRE
    target.pbRaiseStatStageByAbility(:ATTACK, 1, target)
  }
)
BattleHandlers::StatusImmunityAbility.add(:THERMALEXCHANGE,
  proc { |ability, battler, status|
    next true if status == :BURN
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:VESSELOFRUIN,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}'s Vessel of Ruin weakened the Sp. Atk of all surrounding Pokémon!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:WINDPOWER,
  proc { |ability, user, target, move, battle|
    next if target.fainted?   
    next if !move.windMove?
    next if target.effects[PBEffects::Charge] > 0
    battle.pbShowAbilitySplash(target)
    target.effects[PBEffects::Charge] = 2
    battle.pbDisplay(_INTL("Being hit by {1} charged {2} with power!", move.name, target.pbThis(true)))
    battle.pbHideAbilitySplash(target)
  }
)
#===============================================================================
# Wind Rider
#===============================================================================
BattleHandlers::MoveImmunityTargetAbility.add(:WINDRIDER,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if !move.windMove?
    if show_message
      battle.pbShowAbilitySplash(target)
        battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
      if target.pbCanRaiseStatStage?(:ATTACK, target)
        target.pbRaiseStatStageByAbility(:ATTACK, 1, target, false)
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)
BattleHandlers::AbilityOnSwitchIn.add(:WINDRIDER,
  proc { |ability, battler, battle, switch_in|
    next if battler.pbOwnSide.effects[PBEffects::Tailwind] <= 0 && !battle.field.field_effects != :WindTunnel
    next if !battler.pbCanRaiseStatStage?(:ATTACK, battler, self)
    battle.pbShowAbilitySplash(battler, true)
    battler.pbRaiseStatStage(:ATTACK, 1, battler)
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:FEVERPITCH,
  proc { |ability,battler,battle|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1} gathers an armor of toxic waste!",battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:DUAT,
  proc { |ability,battler,battle|
    battler.effects[PBEffects::Type3] = :TIME
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1} is shrouded in the Duat!",battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:HAUNTED,
  proc { |ability,battler,battle|
    battler.effects[PBEffects::Type3] = :GHOST
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1} is possessed!",battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SHADOWGUARD,
  proc { |ability,battler,battle|
    battler.effects[PBEffects::Type3] = :DARK
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1} is shrouded in the shadows!",battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:ASTRALCLOAK,
  proc { |ability,battler,battle|
    battler.effects[PBEffects::Type3] = :COSMIC
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1} is cloaked in cosmic energy!",battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:EQUINOX,
  proc { |ability,battler,battle|
    pbBattleWeatherAbility(:Starstorm, battler, battle)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:URBANCLOUD,
  proc { |ability,battler,battle|
    pbBattleWeatherAbility(:AcidRain, battler, battle)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:RAGINGSEA,
  proc { |ability,battler,battle|
    pbBattleWeatherAbility(:Rain, battler, battle)
    next if battle.field.terrain == :Electric
    battle.scene.pbAnimation(GameData::Move.get(:ELECTRICTERRAIN).id,battler,battler)
    battle.field.terrainDuration = battler.hasActiveItem?(:TERRAINEXTENDER) ? 8 : 5
    battle.pbStartTerrain(battler, :Electric)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:NIGHTFALL,
  proc { |ability,battler,battle|
    pbBattleWeatherAbility(:Eclipse, battler, battle)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SHROUD,
  proc { |ability,battler,battle|
    pbBattleWeatherAbility(:Fog, battler, battle)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:HAILSTORM,
  proc { |ability,battler,battle|
    pbBattleWeatherAbility(:Sleet, battler, battle)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:CLOUDCOVER,
  proc { |ability,battler,battle|
    pbBattleWeatherAbility(:Overcast, battler, battle)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:TOXICSURGE,
  proc { |ability,battler,battle|
    next if battle.field.terrain == :Poison
    battle.pbShowAbilitySplash(battler)
    battle.scene.pbAnimation(GameData::Move.get(:PSYCHICTERRAIN).id,battler,battler)
    battle.field.terrainDuration = battler.hasActiveItem?(:TERRAINEXTENDER) ? 8 : 5
    battle.pbStartTerrain(battler, :Poison)
    # NOTE: The ability splash is hidden again in def pbStartTerrain.
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:GALEFORCE,
  proc { |ability,battler,battle|
    pbBattleWeatherAbility(:Windy, battler, battle)
    battle.removeAllHazards
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:MINDGAMES,
  proc { |ability,battler,battle|
    battle.pbShowAbilitySplash(battler)
    battle.eachOtherSideBattler(battler.index) do |b|
      next if !b.near?(battler)
      b.pbLowerSpAtkStatStageMindGames(battler)
      b.pbItemOnIntimidatedCheck
    end
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:MEDUSOID,
  proc { |ability,battler,battle|
    battle.pbShowAbilitySplash(battler)
    battle.eachOtherSideBattler(battler.index) do |b|
      next if !b.near?(battler)
      b.pbLowerSpeedStatStageMedusoid(battler)
      b.pbItemOnIntimidatedCheck
    end
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:DIMENSIONSHIFT,
  proc { |ability,battler,battle|
    battle.pbShowAbilitySplash(battler)
    next if battle.field.field_effects == :Dream
    if $gym_gimmick == true && $Trainer.badge_count == 4
      battle.pbDisplay(_INTL("The dimensions are unchanged!"))
    else
      if battle.field.effects[PBEffects::TrickRoom] > 0
        battle.field.effects[PBEffects::TrickRoom] = 0
        battle.scene.pbAnimation(GameData::Move.get(:TRICKROOM).id,battler,battler)
        battle.pbDisplay(_INTL("{1} reverted the dimensions!",battler.pbThis))
        battle.pbCalculatePriority
      else
        battle.field.effects[PBEffects::TrickRoom] = 5
        battle.scene.pbAnimation(GameData::Move.get(:TRICKROOM).id,battler,battler)
        battle.pbDisplay(_INTL("{1} twisted the dimensions!",battler.pbThis))
        battle.pbCalculatePriority
      end
    end
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:CACOPHONY,
  proc { |ability,battler,battle|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1} is creating an uproar!",battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.copy(:CACOPHONY,:MOSHPIT)
BattleHandlers::DamageCalcUserAbility.copy(:PUNKROCK,:MOSHPIT)
BattleHandlers::DamageCalcTargetAbility.copy(:PUNKROCK,:MOSHPIT)

BattleHandlers::DamageCalcUserAbility.add(:FLOWERGIFT,
  proc { |ability,user,target,move,mults,baseDmg,type|
    if move.physicalMove? && [:Sun, :HarshSun].include?(user.battle.pbWeather) || user.battle.field.field_effects == :Garden
      mults[:attack_multiplier] *= 1.5
    end
  }
)

BattleHandlers::DamageCalcUserAllyAbility.add(:FLOWERGIFT,
  proc { |ability,user,target,move,mults,baseDmg,type|
    if move.specialMove? && [:Sun, :HarshSun].include?(user.battle.pbWeather) || user.battle.field.field_effects == :Garden
      mults[:attack_multiplier] *= 1.5
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:FLOWERGIFT,
  proc { |ability,user,target,move,mults,baseDmg,type|
    if [:Sun, :HarshSun].include?(user.battle.pbWeather) || user.battle.field.field_effects == :Garden
      mults[:defense_multiplier] *= 1.5
    end
  }
)

BattleHandlers::SpeedCalcAbility.add(:SANDRUSH,
  proc { |ability,battler,mult|
    if [:Sandstorm].include?(battler.battle.pbWeather) || battler.battle.field.field_effects == :Desert
      next mult * 2
    end
  }
)

BattleHandlers::SpeedCalcAbility.add(:SLUSHRUSH,
  proc { |ability,battler,mult|
    if [:Hail, :Sleet, :Snow].include?(battler.battle.pbWeather) || [:Icy,:SnowyMountainside].include?(battler.battle.field.field_effects)
      next mult * 2
    end
  }
)

BattleHandlers::AccuracyCalcTargetAbility.add(:SNOWCLOAK,
  proc { |ability,mods,user,target,move,type|
    mods[:evasion_multiplier] *= 1.25 if [:Hail,:Sleet,:Snow].include?(target.battle.pbWeather)
  }
)

BattleHandlers::SpeedCalcAbility.add(:SWIFTSWIM,
  proc { |ability,battler,mult|
    if ([:Rain, :HeavyRain, :Storm].include?(battler.battle.pbWeather) && !battler.hasUtilityUmbrella?) || [:Water,:Underwater].include?(battler.battle.field.field_effects)
      next mult * 2
    end
  }
)

BattleHandlers::SpeedCalcAbility.add(:STARSPRINT,
  proc { |ability,battler,mult|
    if [:Starstorm].include?(battler.battle.pbWeather) || [:Space,:Distortion].include?(battler.battle.field.field_effects)
      next mult * 2
    end
  }
)

BattleHandlers::SpeedCalcAbility.add(:BACKDRAFT,
  proc { |ability,battler,mult|
    if [:Windy,:StrongWinds].include?(battler.battle.pbWeather) || battler.battle.field.field_effects == :WindTunnel
      next mult * 2
    end
  }
)

BattleHandlers::SpeedCalcAbility.add(:NOCTEMBOOST,
  proc { |ability,battler,mult|
    if [:Eclipse].include?(battler.battle.pbWeather) || [:Outage,:Space,:DarkRoom].include?(battler.battle.field.field_effects)
      next mult * 2
    end
  }
)

BattleHandlers::SpeedCalcAbility.add(:TOXICRUSH,
  proc { |ability,battler,mult|
    if [:AcidRain].include?(battler.battle.pbWeather) || [:Poison,:Swamp].include?(battler.battle.field.field_effects)
      next mult * 2
    end
  }
)

BattleHandlers::TargetAbilityOnHit.add(:ICEBODY,
  proc { |ability,user,target,move,battle|
    next if !move.pbContactMove?(user)
    next if user.frozen? || battle.pbRandom(100)>=30
    next if !user.pbCanFreeze?(target,false)
    battle.pbShowAbilitySplash(target)
    if user.pbCanFreeze?(target,PokeBattle_SceneConstants::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(PokeBattle_SceneConstants::USE_ABILITY_SPLASH)
      msg = nil
      if !PokeBattle_SceneConstants::USE_ABILITY_SPLASH
        msg = _INTL("{1}'s {2} gave {3} frostbite!",target.pbThis,target.abilityName,user.pbThis(true))
      end
      user.pbFreezeIceBody(target,msg)
    end
    battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::StatusImmunityAbility.copy(:WATERVEIL,:FEVERPITCH)
BattleHandlers::StatusCureAbility.copy(:WATERVEIL,:FEVERPITCH)

BattleHandlers::DamageCalcUserAbility.add(:SUBWOOFER,
  proc { |ability,user,target,move,mults,baseDmg,type|
    if user.index != target.index && move && move.soundMove? && (baseDmg * mults[:base_damage_multiplier] <= 70)
      mults[:base_damage_multiplier]*1.5
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:FAIRYBUBBLE,
  proc { |ability,user,target,move,mults,baseDmg,type|
    mults[:attack_multiplier] *= 2 if type == :FAIRY
  }
)

BattleHandlers::AbilityOnSwitchOut.add(:ZEROTOHERO,
  proc { |ability, battler, endOfBattle|
    next if battler.form == 1
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.pbChangeForm(1,"")
  }
)
BattleHandlers::AbilityOnSwitchIn.add(:ZEROTOHERO,
  proc { |ability, battler, battle, switch_in|
    next if battler.form == 0
    next if battle.isBattlerActivedAbility?(battler)
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1} underwent a heroic transformation!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
    battle.setBattlerActivedAbility(battler)
  }
)

BattleHandlers::StatusImmunityAbility.add(:FAIRYBUBBLE,
  proc { |ability,battler,status|
    next true if status != :NONE
  }
)

BattleHandlers::StatusImmunityAbility.copy(:FAIRYBUBBLE,:PURIFYINGSALT)

BattleHandlers::DamageCalcTargetAbility.add(:FEVERPITCH,
  proc { |ability,user,target,move,mults,baseDmg,type|
    if type == :PSYCHIC
      mults[:final_damage_multiplier] *= 0.5
    end
  }
)

BattleHandlers::StatLossImmunityAbilityNonIgnorableSandy.add(:UNSHAKEN,
  proc { |ability,battler,stat,battle,showMessages|
    if showMessages
      battle.pbShowAbilitySplash(battler)
      if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}'s stats cannot be lowered!",battler.pbThis))
      else
        battle.pbDisplay(_INTL("{1}'s {2} prevents stat loss!",battler.pbThis,battler.abilityName))
      end
      battle.pbHideAbilitySplash(battler)
    end
    next true
  }
)

BattleHandlers::StatLossImmunityItem.add(:UNSHAKENORB,
  proc { |ability,battler,stat,battle,showMessages|
    if showMessages
      ability = battler.ability_id
      battler.ability_id = :UNSHAKEN
      battle.pbShowAbilitySplash(battler)
      battle.pbDisplay(_INTL("{1}'s stats cannot be lowered because of its {2} Orb!",battler.pbThis,battler.abilityName))
      battle.pbHideAbilitySplash(battler)
      battler.ability_id = ability
    end
    next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:WATERCOMPACTION,
  proc { |ability,user,target,move,type,battle|
    next pbBattleMoveImmunityStatAbility(user,target,move,type,:WATER,:SPECIAL_DEFENSE,2,battle)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:WELLBAKEDBODY,
  proc { |ability,user,target,move,type,battle|
    next pbBattleMoveImmunityStatAbility(user,target,move,type,:FIRE,:DEFENSE,2,battle)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:LEGENDARMOR,
  proc { |ability,user,target,move,type,battle|
    next pbBattleMoveImmunityHealAbility(user,target,move,type,:DRAGON,battle)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:EARTHEATER,
  proc { |ability,user,target,move,type,battle|
    next pbBattleMoveImmunityHealAbility(user,target,move,type,:GROUND,battle)
  }
)

BattleHandlers::MoveImmunityTargetAbility.copy(:EARTHEATER,:TERRAFORM)

BattleHandlers::MoveImmunityTargetAbility.add(:UNTAINTED,
  proc { |ability,user,target,move,type,battle|
    next if type != :DARK
    battle.pbShowAbilitySplash(target)
    if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
    else
      battle.pbDisplay(_INTL("{1}'s {2} blocks {3}!",target.pbThis,target.abilityName,move.name))
    end
    battle.pbHideAbilitySplash(target)
    next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:SCALER,
  proc { |ability,user,target,move,type,battle|
    next if type != :ROCK
    battle.pbShowAbilitySplash(target)
    if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
    else
      battle.pbDisplay(_INTL("{1}'s {2} blocks {3}!",target.pbThis,target.abilityName,move.name))
    end
    battle.pbHideAbilitySplash(target)
    next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:MOLTENFURY,
  proc { |ability,user,target,move,type,battle|
    next pbBattleMoveImmunityStatAbility(user,target,move,type,:ROCK,:SPECIAL_ATTACK,1,battle)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:CORRUPTION,
  proc { |ability,user,target,move,type,battle|
    next if type != :FAIRY
    battle.pbShowAbilitySplash(target)
    if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
    else
      battle.pbDisplay(_INTL("{1}'s {2} blocks {3}!",target.pbThis,target.abilityName,move.name))
    end
    battle.pbHideAbilitySplash(target)
    next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:MENTALBLOCK,
  proc { |ability,user,target,move,type,battle|
    next if type != :PSYCHIC
    battle.pbShowAbilitySplash(target)
    if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
    else
      battle.pbDisplay(_INTL("{1}'s {2} blocks {3}!",target.pbThis,target.abilityName,move.name))
    end
    battle.pbHideAbilitySplash(target)
    next true
  }
)

BattleHandlers::MoveBaseTypeModifierAbility.add(:STELLARIZE,
  proc { |ability,user,move,type|
    next if type != :NORMAL || !GameData::Type.exists?(:COSMIC)
    move.powerBoost = true
    next :COSMIC
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:DIMENSIONBLOCK,
  proc { |ability,user,target,move,type,battle|
    next if type != :COSMIC
    battle.pbShowAbilitySplash(target)
    if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
    else
      battle.pbDisplay(_INTL("{1}'s {2} blocks {3}!",target.pbThis,target.abilityName,move.name))
    end
    battle.pbHideAbilitySplash(target)
    next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:PASTELVEIL,
  proc { |ability,user,target,move,type,battle|
    next if type != :POISON
    battle.pbShowAbilitySplash(target)
    if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
    else
      battle.pbDisplay(_INTL("{1}'s {2} blocks {3}!",target.pbThis,target.abilityName,move.name))
    end
    battle.pbHideAbilitySplash(target)
    next true
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:FLOWERGIFT,
  proc { |ability,user,target,move,type,battle|
    next if type != :FIRE
    battle.pbShowAbilitySplash(target)
    if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
    else
      battle.pbDisplay(_INTL("{1}'s {2} blocks {3}!",target.pbThis,target.abilityName,move.name))
    end
    battle.pbHideAbilitySplash(target)
    next true
  }
)

BattleHandlers::MoveBaseTypeModifierAbility.add(:ENTYMATE,
  proc { |ability,user,move,type|
    next if type != :NORMAL || !GameData::Type.exists?(:BUG)
    move.powerBoost = true
    next :BUG
  }
)

BattleHandlers::MoveBaseTypeModifierAbility.add(:EMBLAZEN,
  proc { |ability,user,move,type|
    next if type != :NORMAL || !GameData::Type.exists?(:FIRE)
    move.powerBoost = true
    next :FIRE
  }
)

BattleHandlers::MoveBaseTypeModifierAbility.add(:INTOXICATE,
  proc { |ability,user,move,type|
    next if type != :NORMAL || !GameData::Type.exists?(:POISON)
    move.powerBoost = true
    next :POISON
  }
)

BattleHandlers::DamageCalcUserAbility.copy(:AERILATE,:PIXILATE,:REFRIGERATE,:GALVANIZE,:ENTYMATE,:STELLARIZE,:EMBLAZEN,:INTOXICATE)

BattleHandlers::DamageCalcUserAbility.add(:COMPOSURE,
  proc { |ability,user,target,move,mults,baseDmg,type|
    mults[:attack_multiplier] *= 2 if move.specialMove?
  }
)

BattleHandlers::DamageCalcUserAbility.add(:AMPLIFIER,
  proc { |ability,user,target,move,mults,baseDmg,type|
    mults[:base_damage_multiplier] = (mults[:base_damage_multiplier]*1.5).round if move.soundMove?
  }
)

BattleHandlers::DamageCalcUserAbility.add(:TIGHTFOCUS,
  proc { |ability,user,target,move,mults,baseDmg,type|
    times = user.activeField == :Mirror ? 1.5 : 1.3
    mults[:base_damage_multiplier] = (mults[:base_damage_multiplier]*times).round if move.beamMove?
  }
)

BattleHandlers::DamageCalcUserAbility.copy(:TIGHTFOCUS,:HYPERCANNON)
BattleHandlers::DamageCalcUserAbility.copy(:MEGALAUNCHER,:HYPERCANNON)

BattleHandlers::DamageCalcUserAbility.add(:GAVELPOWER,
  proc { |ability,user,target,move,mults,baseDmg,type|
    mults[:base_damage_multiplier] = (mults[:base_damage_multiplier]*1.5).round if move.hammerMove?
  }
)

BattleHandlers::DamageCalcUserAbility.copy(:GAVELPOWER,:HAMMERSMITH)

BattleHandlers::PriorityChangeAbility.add(:HAMMERSMITH,
  proc { |ability, battler, move, pri|
    if move.hammerMove?
      next 1
    end
  }
)

BattleHandlers::PriorityChangeAbility.copy(:PRANKSTER,:JESTERSTRICK)

BattleHandlers::AbilityOnSwitchIn.add(:ILLUMINATE,
  proc { |ability,battler,battle|
    battler.pbRaiseStatStageByAbility(:ACCURACY,1,battler)
    if battle.field.field_effects == :Mirror
      if battler.attack > battler.spatk
        battler.pbRaiseStatStageByAbility(:ATTACK,1,battler)
      else
        battler.pbRaiseStatStageByAbility(:SPECIAL_ATTACK,1,battler)
      end
    end
    if battle.field.field_effects == :DarkRoom && battle.pbWeather != :Eclipse
      battle.pbDisplay(_INTL("The light brightened the room!"))
      battle.pbChangeField(:None)
      battle.scene.pbRefreshEverything
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:VAMPIRIC,
  proc { |ability,user,target,move,mults,baseDmg,type|
    next if move.function !="14F" 
    next if move.function != "0DD"
    mults[:base_damage_multiplier] = (mults[:base_damage_multiplier]*1.2).round
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:VAMPIRIC,
  proc { |ability,user,targets,move,battle|
    next if !move.bitingMove?
    next if move.function == "14F"
    next if move.function == "0DD"
    next if user.hp == user.totalhp
    totalDamage = 0
    for target in targets
      totalDamage += target.damageState.totalHPLost
    end
    next if totalDamage<=0
    battle.pbShowAbilitySplash(user)
    recovered = user.hasActiveItem?(:BIGROOT) ? (totalDamage*2)/3 : totalDamage/2
    user.pbRecoverHP(recovered)
    battle.pbDisplay(_INTL("{1} sapped some HP.",user.pbThis))
    battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::DamageCalcUserAbility.add(:SYLPHSAP,
  proc { |ability,user,target,move,mults,baseDmg,type|
    next unless type == :FAIRY
    mults[:base_damage_multiplier] = (mults[:base_damage_multiplier]*1.3).round if move.function=="14F" || move.function=="0DD"
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:ICESCALES,
  proc { |ability,user,target,move,mults,baseDmg,type|
    mults[:defense_multiplier] *= 2 if move.specialMove? || !move.function=="122"   # Psyshock
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:PURIFYINGSALT,
  proc { |ability,user,target,move,mults,baseDmg,type|
    mults[:defense_multiplier] *= 2 if type == :GHOST
  }
)

class PokeBattle_Battler
  alias ragefist_pbEffectsOnMakingHit pbEffectsOnMakingHit
  def pbEffectsOnMakingHit(move, user, target)
    ragefist_pbEffectsOnMakingHit(move, user, target)
    if target.damageState.calcDamage > 0 && !target.damageState.substitute
        # target.pokemon.rage_hit += 1
        @battle.addBattlerHit(target)
    end
  end
  def pbItemOnStatDropped(move_user = nil)
    return false if !@statsDropped
    return false if !itemActive?
    return Battle::ItemEffects.triggerOnStatLoss(self.item, self, move_user, @battle)
  end
  def immune_by_ability?(type,ability)
    if type == :COSMIC && ability == :DIMENSIONBLOCK
      return true
    end
    if type == :FIRE && ability == :FLASHFIRE
      return true
    end
    if type == :GRASS && ability == :SAPSIPPER
      return true
    end
    if type == :WATER && [:STORMDRAIN,:WATERABSORB,:DRYSKIN].include?(ability)
      return true
    end
    if type == :GROUND && ability == :LEVITATE
      return true
    end
    return false
  end
  def pbCanLowerStatStage?(stat,user=nil,move=nil,showFailMsg=false,ignoreContrary=false)
    return false if fainted?
    return false if hasActiveAbility?(:UNSHAKEN)
    return false if hasActiveItem?(:UNSHAKENORB)
    # Contrary
    if hasActiveAbility?(:CONTRARY) && !ignoreContrary && !@battle.moldBreaker
      return pbCanRaiseStatStage?(stat,user,move,showFailMsg,true)
    end
    if !user || user.index!=@index   # Not self-inflicted
      if @effects[PBEffects::Substitute]>0 && !(move && move.ignoresSubstitute?(user))
        @battle.pbDisplay(_INTL("{1} is protected by its substitute!",pbThis)) if showFailMsg
        return false
      end
      if pbOwnSide.effects[PBEffects::Mist]>0 &&
         !(user && user.hasActiveAbility?([:INFILTRATOR,:JESTERSTRICK]))
        @battle.pbDisplay(_INTL("{1} is protected by Mist!",pbThis)) if showFailMsg
        return false
      end
      if abilityActive?
        return false if BattleHandlers.triggerStatLossImmunityAbility(
           self.ability,self,stat,@battle,showFailMsg) if !@battle.moldBreaker
        return false if BattleHandlers.triggerStatLossImmunityAbilityNonIgnorable(
           self.ability,self,stat,@battle,showFailMsg)
      end
      if !@battle.moldBreaker
        eachAlly do |b|
          next if !b.abilityActive?
          return false if BattleHandlers.triggerStatLossImmunityAllyAbility(
             b.ability,b,self,stat,@battle,showFailMsg)
        end
      end
    end
    # Check the stat stage
    if statStageAtMin?(stat)
      @battle.pbDisplay(_INTL("{1}'s {2} won't go any lower!",
         pbThis, GameData::Stat.get(stat).name)) if showFailMsg
      return false
    end
    return true
  end
  def pbInitEffects(batonPass)
    if batonPass
      # These effects are passed on if Baton Pass is used, but they need to be
      # reapplied
      @effects[PBEffects::LaserFocus] = (@effects[PBEffects::LaserFocus]>0) ? 2 : 0
      @effects[PBEffects::LockOn]     = (@effects[PBEffects::LockOn]>0) ? 2 : 0
      if @effects[PBEffects::PowerTrick]
        @attack,@defense = @defense,@attack
      end
      # These effects are passed on if Baton Pass is used, but they need to be
      # cancelled in certain circumstances anyway
      @effects[PBEffects::Telekinesis] = 0 if isSpecies?(:GENGAR) && mega?
      @effects[PBEffects::GastroAcid]  = false if unstoppableAbility?
    else
      # These effects are passed on if Baton Pass is used
      @stages[:ATTACK]          = 0
      @stages[:DEFENSE]         = 0
      @stages[:SPEED]           = 0
      @stages[:SPECIAL_ATTACK]  = 0
      @stages[:SPECIAL_DEFENSE] = 0
      @stages[:ACCURACY]        = 0
      @stages[:EVASION]         = 0
      @effects[PBEffects::AquaRing]          = false
      @effects[PBEffects::Confusion]         = 0
      @effects[PBEffects::Curse]             = false
      @effects[PBEffects::Embargo]           = 0
      @effects[PBEffects::FocusEnergy]       = 0
      @effects[PBEffects::GastroAcid]        = false
      @effects[PBEffects::HealBlock]         = 0
      @effects[PBEffects::Ingrain]           = false
      @effects[PBEffects::LaserFocus]        = 0
      @effects[PBEffects::LeechSeed]         = -1
      @effects[PBEffects::LockOn]            = 0
      @effects[PBEffects::LockOnPos]         = -1
      @effects[PBEffects::MagnetRise]        = 0
      @effects[PBEffects::PerishSong]        = 0
      @effects[PBEffects::PerishSongUser]    = -1
      @effects[PBEffects::PowerTrick]        = false
      @effects[PBEffects::StarSap]         = -1
      @effects[PBEffects::Substitute]        = 0
      @effects[PBEffects::Telekinesis]       = 0
      @effects[PBEffects::CudChew]              = 0
    @effects[PBEffects::Comeuppance]          = -1
    @effects[PBEffects::ComeuppanceTarget]    = -1
    @effects[PBEffects::ParadoxStat]          = nil
    @effects[PBEffects::BoosterEnergy]        = false
    @effects[PBEffects::DoubleShock]          = false
    @effects[PBEffects::GlaiveRush]           = 0
    @effects[PBEffects::CommanderTatsugiri]   = false
    @effects[PBEffects::CommanderDondozo]     = -1
    @effects[PBEffects::SaltCure]             = false
    @effects[PBEffects::SupremeOverlord]      = 0
    end
    @fainted               = (@hp==0)
    @initialHP             = 0
    @lastAttacker          = []
    @lastFoeAttacker       = []
    @lastHPLost            = 0
    @lastHPLostFromFoe     = 0
    @tookDamage            = false
    @tookPhysicalHit       = false
    @lastMoveUsed          = nil
    @lastMoveUsedType      = nil
    @lastRegularMoveUsed   = nil
    @lastRegularMoveTarget = -1
    @lastRoundMoved        = -1
    @lastMoveFailed        = false
    @lastRoundMoveFailed   = false
    @movesUsed             = []
    @turnCount             = 0
    @effects[PBEffects::Attract]             = -1
    @battle.eachBattler do |b|   # Other battlers no longer attracted to self
      b.effects[PBEffects::Attract] = -1 if b.effects[PBEffects::Attract]==@index
    end
    @effects[PBEffects::BanefulBunker]       = false
    @effects[PBEffects::BeakBlast]           = false
    @effects[PBEffects::Bide]                = 0
    @effects[PBEffects::BideDamage]          = 0
    @effects[PBEffects::BideTarget]          = -1
    @effects[PBEffects::BurnUp]              = false
    @effects[PBEffects::Charge]              = 0
    @effects[PBEffects::ChoiceBand]          = nil
    @effects[PBEffects::Counter]             = -1
    @effects[PBEffects::CounterTarget]       = -1
    @effects[PBEffects::Dancer]              = false
    @effects[PBEffects::DefenseCurl]         = false
    @effects[PBEffects::DestinyBond]         = false
    @effects[PBEffects::DestinyBondPrevious] = false
    @effects[PBEffects::DestinyBondTarget]   = -1
    @effects[PBEffects::Disable]             = 0
    @effects[PBEffects::DisableMove]         = nil
    @effects[PBEffects::Electrify]           = false
    @effects[PBEffects::Encore]              = 0
    @effects[PBEffects::EncoreMove]          = nil
    @effects[PBEffects::Endure]              = false
    @effects[PBEffects::FirstPledge]         = 0
    @effects[PBEffects::FlashFire]           = false
    @effects[PBEffects::Flinch]              = false
    @effects[PBEffects::FocusPunch]          = false
    @effects[PBEffects::FollowMe]            = 0
    @effects[PBEffects::Foresight]           = false
    @effects[PBEffects::FuryCutter]          = 0
    @effects[PBEffects::GemConsumed]         = nil
    @effects[PBEffects::Grudge]              = false
    @effects[PBEffects::HelpingHand]         = false
    @effects[PBEffects::HyperBeam]           = 0
    @effects[PBEffects::Illusion]            = nil
    $gigaton = false
    if hasActiveAbility?(:ILLUSION)
      idxLastParty = @battle.pbLastInTeam(@index)
      if idxLastParty >= 0 && idxLastParty != @pokemonIndex
        @effects[PBEffects::Illusion]        = @battle.pbParty(@index)[idxLastParty]
      end
    end
    @effects[PBEffects::Imprison]            = false
    @effects[PBEffects::Instruct]            = false
    @effects[PBEffects::Instructed]          = false
    @effects[PBEffects::KingsShield]         = false
    @battle.eachBattler do |b|   # Other battlers lose their lock-on against self
      next if b.effects[PBEffects::LockOn]==0
      next if b.effects[PBEffects::LockOnPos]!=@index
      b.effects[PBEffects::LockOn]    = 0
      b.effects[PBEffects::LockOnPos] = -1
    end
    @effects[PBEffects::MagicBounce]         = false
    @effects[PBEffects::MagicCoat]           = false
    @effects[PBEffects::MeanLook]            = -1
    @battle.eachBattler do |b|   # Other battlers no longer blocked by self
      b.effects[PBEffects::MeanLook] = -1 if b.effects[PBEffects::MeanLook]==@index
    end
    @effects[PBEffects::MeFirst]             = false
    @effects[PBEffects::Metronome]           = 0
    @effects[PBEffects::MicleBerry]          = false
    @effects[PBEffects::Minimize]            = false
    @effects[PBEffects::MiracleEye]          = false
    @effects[PBEffects::MirrorCoat]          = -1
    @effects[PBEffects::MirrorCoatTarget]    = -1
    @effects[PBEffects::MoveNext]            = false
    @effects[PBEffects::MudSport]            = false
    @effects[PBEffects::Nightmare]           = false
    @effects[PBEffects::Obstruct]            = false
    @effects[PBEffects::Outrage]             = 0
    @effects[PBEffects::ParentalBond]        = 0
    @effects[PBEffects::Ambidextrous]        = 0
    @effects[PBEffects::EchoChamber]         = 0
    @effects[PBEffects::PickupItem]          = nil
    @effects[PBEffects::PickupUse]           = 0
    @effects[PBEffects::Pinch]               = false
    @effects[PBEffects::Powder]              = false
    @effects[PBEffects::Prankster]           = false
    @effects[PBEffects::PriorityAbility]     = false
    @effects[PBEffects::PriorityItem]        = false
    @effects[PBEffects::Protect]             = false
    @effects[PBEffects::ProtectRate]         = 1
    @effects[PBEffects::Pursuit]             = false
    @effects[PBEffects::Quash]               = 0
    @effects[PBEffects::Rage]                = false
    @effects[PBEffects::RagePowder]          = false
    @effects[PBEffects::Rollout]             = 0
    @effects[PBEffects::Roost]               = false
    @effects[PBEffects::SkyDrop]             = -1
    @effects[PBEffects::Octolock]            = -1
    @battle.eachBattler do |b|   # Other battlers no longer locked by self
      b.effects[PBEffects::Octolock] = -1 if b.effects[PBEffects::Octolock] == @index
    end
    @effects[PBEffects::JawLock]             = -1
    @battle.eachBattler do |b|   # Other battlers no longer blocked by self
      b.effects[PBEffects::JawLock] = -1 if b.effects[PBEffects::JawLock] == @index
    end
    @battle.eachBattler do |b|   # Other battlers no longer Sky Dropped by self
      b.effects[PBEffects::SkyDrop] = -1 if b.effects[PBEffects::SkyDrop]==@index
    end
    @effects[PBEffects::SlowStart]           = 0
    @effects[PBEffects::SmackDown]           = false
    @effects[PBEffects::Snatch]              = 0
    @effects[PBEffects::SpikyShield]         = false
    @effects[PBEffects::Spotlight]           = 0
    @effects[PBEffects::Stockpile]           = 0
    @effects[PBEffects::StockpileDef]        = 0
    @effects[PBEffects::StockpileSpDef]      = 0
    @effects[PBEffects::Taunt]               = 0
    @effects[PBEffects::ThroatChop]          = 0
    @effects[PBEffects::Torment]             = false
    @effects[PBEffects::Toxic]               = 0
    @effects[PBEffects::Transform]           = false
    @effects[PBEffects::TransformSpecies]    = 0
    @effects[PBEffects::Trapping]            = 0
    @effects[PBEffects::TrappingMove]        = nil
    @effects[PBEffects::TrappingUser]        = -1
    @battle.eachBattler do |b|   # Other battlers no longer trapped by self
      next if b.effects[PBEffects::TrappingUser]!=@index
      b.effects[PBEffects::Trapping]     = 0
      b.effects[PBEffects::TrappingUser] = -1
    end
    @effects[PBEffects::Truant]              = false
    @effects[PBEffects::TwoTurnAttack]       = nil
    @effects[PBEffects::Type3]               = nil
    @effects[PBEffects::Unburden]            = false
    @effects[PBEffects::Uproar]              = 0
    @effects[PBEffects::WaterSport]          = false
    @effects[PBEffects::WeightChange]        = 0
    @effects[PBEffects::Yawn]                = 0
    @effects[PBEffects::GorillaTactics]      = nil
    @effects[PBEffects::BallFetch]           = nil
    @effects[PBEffects::Obstruct]            = false
    @effects[PBEffects::TarShot]             = false
    @effects[PBEffects::Cinders]             = -1
    @effects[PBEffects::Singed]              = false
    @effects[PBEffects::Ricochet]            = 0
    @effects[PBEffects::SuccessiveMove]      = 0
  end
  def pbUseMove(choice,specialUsage=false)
    # NOTE: This is intentionally determined before a multi-turn attack can
    #       set specialUsage to true.
    skipAccuracyCheck = (specialUsage && choice[2]!=@battle.struggle)
    # Start using the move
    pbBeginTurn(choice)
    # Force the use of certain moves if they're already being used
    if usingMultiTurnAttack?
      choice[2] = PokeBattle_Move.from_pokemon_move(@battle, Pokemon::Move.new(@currentMove))
      specialUsage = true
    elsif @effects[PBEffects::Encore]>0 && choice[1]>=0 &&
       @battle.pbCanShowCommands?(@index)
      idxEncoredMove = pbEncoredMoveIndex
      if idxEncoredMove>=0 && @battle.pbCanChooseMove?(@index,idxEncoredMove,false)
        if choice[1]!=idxEncoredMove   # Change move if battler was Encored mid-round
          choice[1] = idxEncoredMove
          choice[2] = @moves[idxEncoredMove]
          choice[3] = -1   # No target chosen
        end
      end
    end
    # Labels the move being used as "move"
    move = choice[2]
    return if !move   # if move was not chosen somehow
    # Try to use the move (inc. disobedience)
    @lastMoveFailed = false
    if !pbTryUseMove(choice,move,specialUsage,skipAccuracyCheck)
      @lastMoveUsed     = nil
      @lastMoveUsedType = nil
      if !specialUsage
        @lastRegularMoveUsed   = nil
        @lastRegularMoveTarget = -1
      end
      @battle.pbGainExp   # In case self is KO'd due to confusion
      pbCancelMoves
      pbEndTurn(choice)
      return
    end
    move = choice[2]   # In case disobedience changed the move to be used
    return if !move   # if move was not chosen somehow
    # Subtract PP
    if !specialUsage
      if !pbReducePP(move)
        @battle.pbDisplay(_INTL("{1} used {2}!",pbThis,move.name))
        @battle.pbDisplay(_INTL("But there was no PP left for the move!"))
        @lastMoveUsed          = nil
        @lastMoveUsedType      = nil
        @lastRegularMoveUsed   = nil
        @lastRegularMoveTarget = -1
        @lastMoveFailed        = true
        pbCancelMoves
        pbEndTurn(choice)
        return
      end
    end
    # Stance Change
    if isSpecies?(:AEGISLASH) && self.ability == :STANCECHANGE
      if move.damagingMove?
        pbChangeForm(1,_INTL("{1} changed to Blade Forme!",pbThis))
      elsif move.id == :KINGSSHIELD
        pbChangeForm(0,_INTL("{1} changed to Shield Forme!",pbThis))
      end
    end
    if hasActiveAbility?(:ACCLIMATE) && move.function == "087" && $gym_weather == false
      oldWeather = @battle.pbWeather
      newWeather = 0
      weatherChange = nil
      choice = @battle.choices[self.index]
      target = @battle.battlers[choice[3]]
      if target != nil && !target.fainted?
        type1 = target.type1
        type2 = target.type2
        case type1
        when :NORMAL
          case type2
          when :GHOST, :PSYCHIC; newWeather = 6
          when :FAIRY; newWeather = 9
          when :FLYING,:COSMIC,:GROUND; newWeather = 3
          when :BUG,:ICE,:GRASS,:STEEL; newWeather = 1
          when :FIGHTING,:DARK,:DRAGON; newWeather = 4
          when :ROCK,:WATER; newWeather = 5
          when :NORMAL,:POISON,:FIRE,:ELECTRIC; newWeather = 10
          end
        when :FIGHTING
          case type2
          when :POISON, :COSMIC; newWeather = 7
          when :STEEL; newWeather = 5
          when :FIRE; newWeather = 2
          when :NORMAL,:FIGHTING,:FLYING,:GROUND,:ROCK,:BUG,:GHOST,:WATER,:GRASS,:ELECTRIC,:PSYCHIC,:ICE,:DRAGON,:DARK,:FAIRY; newWeather = 4
          end
        when :FLYING
          case type2
          when :GROUND, :DRAGON, :COSMIC, :GHOST, :GRASS; newWeather = 3
          when :FIRE, :ICE, :ROCK, :POISON, :BUG, :ELECTRIC, :PSYCHIC, :NORMAL, type1; newWeather = 10
          when :STEEL, :WATER; newWeather = 5
          when :FIGHTING,:DARK,:FAIRY, type1; newWeather = 4
          end
        when :ROCK
          case type2
          when :ICE, :DARK, :FLYING, :BUG, :GROUND, :FAIRY, :FIRE, :POISON, :NORMAL, :FIGHTING, :POISON, type1; newWeather = 2
          when :PSYCHIC, :GHOST; newWeather = 6
          when :COSMIC, :STEEL, :ELECTRIC, :DRAGON, :GRASS, :WATER; newWeather = 5
          end
        when :GROUND
          case type2
          when :WATER,:ELECTRIC,:COSMIC; newWeather = 5
          when :DRAGON, :FLYING, :GRASS; newWeather = 3
          when :NORMAL,:FIGHTING,:POISON,:BUG,:GHOST,:STEEL,:FIRE,:PSYCHIC,:ICE,:DARK,:FAIRY,:ROCK, type1; newWeather = 2
          end
        when :POISON
          case type2
          when :DARK, :STEEL, :ELECTRIC, :ROCK, :FIRE, :ICE, :FLYING,:BUG,type1,:NORMAL; newWeather = 10
          when :PSYCHIC, :GHOST; newWeather = 6
          when :FIGHTING, :GRASS; newWeather = 7
          when :WATER,:DRAGON,:FAIRY; newWeather = 5
          when :COSMIC; newWeather = 1
          when :GROUND; newWeather = 2
          end
        when :BUG
          case type2
          when :GROUND, :WATER, :FIGHTING; newWeather = 7
          when :GRASS, :STEEL, :COSMIC; newWeather = 1
          when :NORMAL,:FLYING,:POISON,:ROCK,:GHOST,:FIRE,:ELECTRIC,:PSYCHIC,:ICE,:DRAGON,:DARK,:FAIRY, type1; newWeather = 10
          end
        when :GHOST
          case type2
          when :FIGHTING, :DARK; newWeather = 4
          when :FAIRY; newWeather = 5
          when :BUG,:COSMIC; newWeather = 1
          when :NORMAL,:FLYING,:POISON,:GROUND,:ROCK,:STEEL,:FIRE,:WATER,:GRASS,:ELECTRIC,:PSYCHIC,:ICE,:DRAGON, type1; newWeather = 7
          end
        when :STEEL
          case type2
          when :WATER,:DRAGON,:DARK,:NORMAL; newWeather = 5
          when :FIRE, :ROCK,:GROUND; newWeather = 2
          when :FLYING,:POISON,:BUG,:GHOST,:STEEL,:GRASS,:ELECTRIC,:PSYCHIC,:ICE,:FAIRY,:COSMIC, type1; newWeather = 1
          end
        when :GRASS
          case type2
          when :STEEL, :COSMIC, :ICE; newWeather = 1
          when :FAIRY; newWeather = 9
          when :DRAGON, :GROUND, :FLYING, :ELECTRIC; newWeather = 3
          when :PSYCHIC; newWeather = 6
          when :ROCK; newWeather = 5
          when :NORMAL, :FIGHTING, :POISON, :BUG, :GHOST, :FIRE, :WATER, type1,:DARK; newWeather = 7
          end
        when :FIRE
          case type2
          when :GRASS; newWeather = 7
          when :COSMIC,:FLYING,:DRAGON,:ELECTRIC; newWeather = 10
          when :NORMAL,:POISON,:GROUND,:ROCK,:WATER,:BUG,:GHOST,:STEEL,:FIRE,:PSYCHIC,:ICE,:DARK,:FAIRY,:FIGHTING, type1; newWeather = 2
          end
        when :WATER
          case type2
          when :FIRE; newWeather = 2
          when :GHOST,:PSYCHIC; newWeather = 6
          when :NORMAL,:FIGHTING,:POISON,:BUG,:STEEL,:GRASS,:ELECTRIC,:ICE,:DRAGON,:DARK,:FAIRY,:COSMIC, type1,:FLYING,:GROUND,:ROCK; newWeather = 5
          end
        when :ELECTRIC
          case type2
          when :FLYING, :GRASS,:GROUND; newWeather = 3
          when :WATER,:STEEL,:DRAGON,:FAIRY,:COSMIC,:FIGHTING,:ROCK; newWeather = 5
          when :BUG,:ICE; newWeather = 1
          when :GHOST,:PSYCHIC; newWeather = 6
          when :NORMAL,:POISON,:FIRE,:DARK, type1; newWeather = 10
          end
        when :ICE
          case type2
          when :GHOST, :PSYCHIC; newWeather = 6
          when :WATER; newWeather = 5
          when :ROCK,:GROUND; newWeather = 2
          when :FIRE, :FLYING, :POISON, :ELECTRIC; newWeather = 10
          when :GRASS, :BUG, :STEEL, :COSMIC, :FAIRY, type1, :NORMAL; newWeather = 1
          when :FIGHTING, :DRAGON, :DARK; newWeather = 4
          end
        when :PSYCHIC
          case type2
          when :FIGHTING,:DARK; newWeather = 4
          when :FAIRY; newWeather = 10
          when :NORMAL,:POISON,:GROUND,:ROCK,:BUG,:GHOST,:STEEL,:FIRE,:ELECTRIC,:DRAGON,:COSMIC,:ICE,:FLYING,:WATER,:GRASS, type1; newWeather = 6
          end
        when :DRAGON
          case type2
          when :GROUND, :FLYING, :GRASS; newWeather = 3
          when :DARK, :FIGHTING, type1; newWeather = 4
          when :FIRE; newWeather = 10
          when :PSYCHIC; newWeather = 6
          when :NORMAL,:POISON,:ROCK,:BUG,:GHOST,:STEEL,:WATER,:ELECTRIC,:ICE,:DRAGON,:FAIRY,:COSMIC; newWeather = 5
          end
        when :DARK
          case type2
          when :NORMAL,:FIGHTING,:FLYING,:GROUND,:BUG,:GHOST,:WATER,:ELECTRIC,:DRAGON,:FAIRY,:GRASS,:PSYCHIC,type1; newWeather = 4
          when :POISON,:FIRE; newWeather = 10
          when :COSMIC,:ICE; newWeather = 1
          when :ROCK,:STEEL; newWeather = 5
          end
        when :FAIRY
          case type2
          when :FIRE; newWeather = 10
          when :COSMIC,:ICE; newWeather = 1
          when :GRASS; newWeather = 9
          when :NORMAL,:FIGHTING,:FLYING,:POISON,:GROUND,:BUG,:STEEL,:WATER,:GRASS,:ELECTRIC,:DRAGON,:DARK,:ROCK, type1; newWeather = 6
          end
        when :COSMIC
          case type2
          when :GROUND, newWeather = 3
          when :GHOST; newWeather = 6
          when :POISON, :FIGHTING; newWeather = 7
          when :ICE, :GRASS, :BUG, :STEEL, :FAIRY; newWeather = 1
          when :NORMAL,:FLYING,:ROCK,:FIRE,:WATER,:ELECTRIC,:PSYCHIC,:DRAGON,type1; newWeather = 5
          end
        end
          case newWeather
          when 1
            weatherChange = :Sun
            newType = :FIRE
          when 2
            weatherChange = :Rain
            newType = :WATER
          when 3
            weatherChange = :Sleet
            newType = :ICE
          when 4
            weatherChange = :Fog
            newType = :FAIRY
          when 5
            weatherChange = :Starstorm
            newType = :COSMIC
          when 6
            weatherChange = :Eclipse
            newType = :DARK
          when 7
            weatherChange = :Windy
            newType = :FLYING
          when 8
            weatherChange = :StrongWinds
            newType = :DRAGON
          when 9
            weatherChange = :AcidRain
            newType = :POISON
          when 10
            weatherChange = :Sandstorm
            newType = :ROCK
          end
        if oldWeather==weatherChange
          weatherChange = @battle.pbWeather
        else
          @battle.pbShowAbilitySplash(self)
          @battle.field.weather = weatherChange
          @battle.field.weatherDuration = 5
          case weatherChange
          when :Starstorm then   @battle.pbDisplay(_INTL("Stars fill the sky."))
          when :Thunder then     @battle.pbDisplay(_INTL("Lightning flashes in th sky."))
          when :Humid then       @battle.pbDisplay(_INTL("The air is humid."))
          when :Overcast then    @battle.pbDisplay(_INTL("The sky is overcast."))
          when :Eclipse then     @battle.pbDisplay(_INTL("The sky is dark."))
          when :Fog then         @battle.pbDisplay(_INTL("The fog is deep."))
          when :AcidRain then    @battle.pbDisplay(_INTL("Acid rain is falling."))
          when :VolcanicAsh then @battle.pbDisplay(_INTL("Volcanic Ash sprinkles down."))
          when :Rainbow then     @battle.pbDisplay(_INTL("A rainbow crosses the sky."))
          when :Borealis then    @battle.pbDisplay(_INTL("The sky is ablaze with color."))
          when :TimeWarp then    @battle.pbDisplay(_INTL("Time has stopped."))
          when :Reverb then      @battle.pbDisplay(_INTL("A dull echo hums."))
          when :DClear then      @battle.pbDisplay(_INTL("The sky is distorted."))
          when :DRain then       @battle.pbDisplay(_INTL("Rain is falling upward."))
          when :DWind then       @battle.pbDisplay(_INTL("The wind is haunting."))
          when :DAshfall then    @battle.pbDisplay(_INTL("Ash floats in midair."))
          when :Sleet then       @battle.pbDisplay(_INTL("Sleet began to fall."))
          when :Windy then       @battle.pbDisplay(_INTL("There is a slight breeze."))
          when :HeatLight then   @battle.pbDisplay(_INTL("Static fills the air."))
          when :DustDevil then   @battle.pbDisplay(_INTL("A dust devil approaches."))
          when :Sun then         @battle.pbDisplay(_INTL("The sunlight is strong."))
          when :Rain then        @battle.pbDisplay(_INTL("It is raining."))
          when :Sandstorm then   @battle.pbDisplay(_INTL("A sandstorm is raging."))
          when :Hail then        @battle.pbDisplay(_INTL("Hail is falling."))
          when :HarshSun then    @battle.pbDisplay(_INTL("The sunlight is extremely harsh."))
          when :HeavyRain then   @battle.pbDisplay(_INTL("It is raining heavily."))
          when :StrongWinds then @battle.pbDisplay(_INTL("The wind is strong."))
          when :ShadowSky then   @battle.pbDisplay(_INTL("The sky is shadowy."))
          end
          @battle.pbHideAbilitySplash(self)
          self.type1 = newType
          oldWeather = @battle.pbWeather
        end
      end
    end
    # Calculate the move's type during this usage
    move.calcType = move.pbCalcType(self)
    # Start effect of Mold Breaker
    @battle.moldBreaker = hasMoldBreaker?
    # Remember that user chose a two-turn move
    if move.pbIsChargingTurn?(self)
      # Beginning the use of a two-turn attack
      @effects[PBEffects::TwoTurnAttack] = move.id
      @currentMove = move.id
    else
      @effects[PBEffects::TwoTurnAttack] = nil   # Cancel use of two-turn attack
    end
    # Add to counters for moves which increase them when used in succession
    move.pbChangeUsageCounters(self,specialUsage)
    # Charge up Metronome item
    if hasActiveItem?(:METRONOME) && !move.callsAnotherMove?
      if @lastMoveUsed && @lastMoveUsed==move.id && !@lastMoveFailed
        @effects[PBEffects::Metronome] += 1
      else
        @effects[PBEffects::Metronome] = 0
      end
    end
    # Record move as having been used
    @lastMoveUsed     = move.id
    @lastMoveUsedType = move.calcType   # For Conversion 2
    if !specialUsage
      @lastRegularMoveUsed   = move.id   # For Disable, Encore, Instruct, Mimic, Mirror Move, Sketch, Spite
      @lastRegularMoveTarget = choice[3]   # For Instruct (remembering original target is fine)
      @movesUsed.push(move.id) if !@movesUsed.include?(move.id)   # For Last Resort
    end
    @battle.lastMoveUsed = move.id   # For Copycat
    @battle.lastMoveUser = @index   # For "self KO" battle clause to avoid draws
    @battle.successStates[@index].useState = 1   # Battle Arena - assume failure
    # Find the default user (self or Snatcher) and target(s)
    user = pbFindUser(choice,move)
    user = pbChangeUser(choice,move,user)
    targets = pbFindTargets(choice,move,user)
    targets = pbChangeTargets(move,user,targets)
    # Pressure
    if !specialUsage
      targets.each do |b|
        next unless b.opposes?(user) && b.hasActiveAbility?(:PRESSURE)
        PBDebug.log("[Ability triggered] #{b.pbThis}'s #{b.abilityName}")
        user.pbReducePP(move)
      end
      if move.pbTarget(user).affects_foe_side
        @battle.eachOtherSideBattler(user) do |b|
          next unless b.hasActiveAbility?(:PRESSURE)
          PBDebug.log("[Ability triggered] #{b.pbThis}'s #{b.abilityName}")
          user.pbReducePP(move)
        end
      end
    end
    # Dazzling/Queenly Majesty make the move fail here
    @battle.pbPriority(true).each do |b|
      next if !b || !b.abilityActive?
      if BattleHandlers.triggerMoveBlockingAbility(b.ability,b,user,targets,move,@battle)
        @battle.pbDisplayBrief(_INTL("{1} used {2}!",user.pbThis,move.name))
        @battle.pbShowAbilitySplash(b)
        @battle.pbDisplay(_INTL("{1} cannot use {2}!",user.pbThis,move.name))
        @battle.pbHideAbilitySplash(b)
        user.lastMoveFailed = true
        pbCancelMoves
        pbEndTurn(choice)
        return
      end
    end
    # "X used Y!" message
    # Can be different for Bide, Fling, Focus Punch and Future Sight
    # NOTE: This intentionally passes self rather than user. The user is always
    #       self except if Snatched, but this message should state the original
    #       user (self) even if the move is Snatched.
    move.pbDisplayUseMessage(self)
    # Snatch's message (user is the new user, self is the original user)
    if move.snatched
      @lastMoveFailed = true   # Intentionally applies to self, not user
      @battle.pbDisplay(_INTL("{1} snatched {2}'s move!",user.pbThis,pbThis(true)))
    end
    # "But it failed!" checks
    if move.pbMoveFailed?(user,targets)
      PBDebug.log(sprintf("[Move failed] In function code %s's def pbMoveFailed?",move.function))
      user.lastMoveFailed = true
      pbCancelMoves
      pbEndTurn(choice)
      return
    end
    # Perform set-up actions and display messages
    # Messages include Magnitude's number and Pledge moves' "it's a combo!"
    move.pbOnStartUse(user,targets)
    # Self-thawing due to the move
    if user.status == :FROZEN && move.thawsUser?
      user.pbCureStatus(false)
      @battle.pbDisplay(_INTL("{1} cured the frostbite!",user.pbThis))
    end
    # Powder
    if user.effects[PBEffects::Powder] && move.calcType == :FIRE
      @battle.pbCommonAnimation("Powder",user)
      @battle.pbDisplay(_INTL("When the flame touched the powder on the Pokémon, it exploded!"))
      user.lastMoveFailed = true
      if ![:Rain, :HeavyRain].include?(@battle.pbWeather) && user.takesIndirectDamage?
        oldHP = user.hp
        user.pbReduceHP((user.totalhp/4.0).round,false)
        user.pbFaint if user.fainted?
        @battle.pbGainExp   # In case user is KO'd by this
        user.pbItemHPHealCheck
        if user.pbAbilitiesOnDamageTaken(oldHP)
          user.pbEffectsOnSwitchIn(true)
        end
      end
      pbCancelMoves
      pbEndTurn(choice)
      return
    end
    # Primordial Sea, Desolate Land
    if move.damagingMove?
      case @battle.pbWeather
      when :HeavyRain
        if move.calcType == :FIRE
          @battle.pbDisplay(_INTL("The Fire-type attack fizzled out in the heavy rain!"))
          user.lastMoveFailed = true
          pbCancelMoves
          pbEndTurn(choice)
          return
        end
      when :HarshSun
        if move.calcType == :WATER
          @battle.pbDisplay(_INTL("The Water-type attack evaporated in the harsh sunlight!"))
          user.lastMoveFailed = true
          pbCancelMoves
          pbEndTurn(choice)
          return
        end
      end
    end
    # Protean / Libero
    if user.hasActiveAbility?([:PROTEAN,:LIBERO]) && !move.callsAnotherMove? && !move.snatched
      if user.pbHasOtherType?(move.calcType) && !GameData::Type.get(move.calcType).pseudo_type
        @battle.pbShowAbilitySplash(user)
        user.pbChangeTypes(move.calcType)
        typeName = GameData::Type.get(move.calcType).name
        @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",user.pbThis,typeName))
        @battle.pbHideAbilitySplash(user)
        # NOTE: The GF games say that if Curse is used by a non-Ghost-type
        #       Pokémon which becomes Ghost-type because of Protean / Libero,
        #       it should target and curse itself. I think this is silly, so
        #       I'm making it choose a random opponent to curse instead.
        if move.function == "10D" && targets.length == 0   # Curse
          choice[3] = -1
          targets = pbFindTargets(choice,move,user)
        end
      end
    end
    # Sword of Mastery
    if user.hasActiveAbility?(:SWORDOFMASTERY) && move.slicingMove?
      if user.pbHasOtherType?(move.calcType) && !GameData::Type.get(move.calcType).pseudo_type
        @battle.pbShowAbilitySplash(user)
        user.pbChangeTypes(move.calcType)
        typeName = GameData::Type.get(move.calcType).name
        @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",user.pbThis,typeName))
        @battle.pbHideAbilitySplash(user)
      end
    end
    #---------------------------------------------------------------------------
    magicCoater  = -1
    magicBouncer = -1
    if targets.length == 0 && move.pbTarget(user).num_targets > 0 && !move.worksWithNoTargets?
      # def pbFindTargets should have found a target(s), but it didn't because
      # they were all fainted
      # All target types except: None, User, UserSide, FoeSide, BothSides
      @battle.pbDisplay(_INTL("But there was no target..."))
      user.lastMoveFailed = true
    else   # We have targets, or move doesn't use targets
      # Reset whole damage state, perform various success checks (not accuracy)
      user.initialHP = user.hp
      targets.each do |b|
        b.damageState.reset
        b.damageState.initialHP = b.hp
        if !pbSuccessCheckAgainstTarget(move,user,b)
          b.damageState.unaffected = true
        end
      end
      # Magic Coat/Magic Bounce checks (for moves which don't target Pokémon)
      if targets.length==0 && move.canMagicCoat?
        @battle.pbPriority(true).each do |b|
          next if b.fainted? || !b.opposes?(user)
          next if b.semiInvulnerable?
          if b.effects[PBEffects::MagicCoat]
            magicCoater = b.index
            b.effects[PBEffects::MagicCoat] = false
            break
          elsif b.hasActiveAbility?(:MAGICBOUNCE) && !@battle.moldBreaker &&
             !b.effects[PBEffects::MagicBounce]
            magicBouncer = b.index
            b.effects[PBEffects::MagicBounce] = true
            break
          end
        end
      end
      # Get the number of hits
      numHits = move.pbNumHits(user,targets)
      # Process each hit in turn
      realNumHits = 0
      for i in 0...numHits
        break if magicCoater>=0 || magicBouncer>=0
        success = pbProcessMoveHit(move,user,targets,i,skipAccuracyCheck)
        if !success
          if i==0 && targets.length>0
            hasFailed = false
            targets.each do |t|
              next if t.damageState.protected
              hasFailed = t.damageState.unaffected
              break if !t.damageState.unaffected
            end
            user.lastMoveFailed = hasFailed
          end
          break
        end
        realNumHits += 1
        break if user.fainted?
        #break if [:SLEEP, :FROZEN].include?(user.status)
        # NOTE: If a multi-hit move becomes disabled partway through doing those
        #       hits (e.g. by Cursed Body), the rest of the hits continue as
        #       normal.
        # Don't stop using the move if Dragon Darts could still hit something
        if move.function == "17C" && realNumHits < numHits
          endMove = true
          @battle.eachBattler do |b|
            next if b == self
            endMove = false
          end
          break if endMove
        else
          # All targets are fainted
          break if targets.all? { |t| t.fainted? }
        end
      end
      # Battle Arena only - attack is successful
      @battle.successStates[user.index].useState = 2
      if targets.length>0
        @battle.successStates[user.index].typeMod = 0
        targets.each do |b|
          next if b.damageState.unaffected
          @battle.successStates[user.index].typeMod += b.damageState.typeMod
        end
      end
      # Effectiveness message for multi-hit moves
      # NOTE: No move is both multi-hit and multi-target, and the messages below
      #       aren't quite right for such a hypothetical move.
      if numHits>1
        if move.damagingMove?
          targets.each do |b|
            next if b.damageState.unaffected || b.damageState.substitute
            move.pbEffectivenessMessage(user,b,targets.length)
          end
        end
        if realNumHits==1
          @battle.pbDisplay(_INTL("Hit 1 time!"))
        elsif realNumHits>1
          @battle.pbDisplay(_INTL("Hit {1} times!",realNumHits))
        end
      end
      # Magic Coat's bouncing back (move has targets)
      targets.each do |b|
        next if b.fainted?
        next if !b.damageState.magicCoat && !b.damageState.magicBounce
        @battle.pbShowAbilitySplash(b) if b.damageState.magicBounce
        @battle.pbDisplay(_INTL("{1} bounced the {2} back!",b.pbThis,move.name))
        @battle.pbHideAbilitySplash(b) if b.damageState.magicBounce
        newChoice = choice.clone
        newChoice[3] = user.index
        newTargets = pbFindTargets(newChoice,move,b)
        newTargets = pbChangeTargets(move,b,newTargets)
        success = pbProcessMoveHit(move,b,newTargets,0,false)
        b.lastMoveFailed = true if !success
        targets.each { |otherB| otherB.pbFaint if otherB && otherB.fainted? }
        user.pbFaint if user.fainted?
      end
      # Magic Coat's bouncing back (move has no targets)
      if magicCoater>=0 || magicBouncer>=0
        mc = @battle.battlers[(magicCoater>=0) ? magicCoater : magicBouncer]
        if !mc.fainted?
          user.lastMoveFailed = true
          @battle.pbShowAbilitySplash(mc) if magicBouncer>=0
          @battle.pbDisplay(_INTL("{1} bounced the {2} back!",mc.pbThis,move.name))
          @battle.pbHideAbilitySplash(mc) if magicBouncer>=0
          success = pbProcessMoveHit(move,mc,[],0,false)
          mc.lastMoveFailed = true if !success
          targets.each { |b| b.pbFaint if b && b.fainted? }
          user.pbFaint if user.fainted?
        end
      end
      # Move-specific effects after all hits
      targets.each { |b| move.pbEffectAfterAllHits(user,b) }
      # Faint if 0 HP
      targets.each { |b| b.pbFaint if b && b.fainted? }
      user.pbFaint if user.fainted?
      # External/general effects after all hits. Eject Button, Shell Bell, etc.
      pbEffectsAfterMove(user,targets,move,realNumHits)
    end
    # End effect of Mold Breaker
    @battle.moldBreaker = false
    # Gain Exp
    @battle.pbGainExp
    # Battle Arena only - update skills
    @battle.eachBattler { |b| @battle.successStates[b.index].updateSkill }
    # Shadow Pokémon triggering Hyper Mode
    pbHyperMode if @battle.choices[@index][0]!=:None   # Not if self is replaced
    # End of move usage
    pbEndTurn(choice)
    # Instruct
    @battle.eachBattler do |b|
      next if !b.effects[PBEffects::Instruct] || !b.lastMoveUsed
      b.effects[PBEffects::Instruct] = false
      idxMove = -1
      b.eachMoveWithIndex { |m,i| idxMove = i if m.id==b.lastMoveUsed }
      next if idxMove<0
      oldLastRoundMoved = b.lastRoundMoved
      @battle.pbDisplay(_INTL("{1} used the move instructed by {2}!",b.pbThis,user.pbThis(true)))
      PBDebug.logonerr{
        b.effects[PBEffects::Instructed] = true
        b.pbUseMoveSimple(b.lastMoveUsed,b.lastRegularMoveTarget,idxMove,false)
        b.effects[PBEffects::Instructed] = false
      }
      b.lastRoundMoved = oldLastRoundMoved
      @battle.pbJudge
      return if @battle.decision>0
    end
    # Dancer
    if !@effects[PBEffects::Dancer] && !user.lastMoveFailed && realNumHits>0 &&
       !move.snatched && magicCoater<0 && @battle.pbCheckGlobalAbility(:DANCER) &&
       move.danceMove?
      dancers = []
      @battle.pbPriority(true).each do |b|
        dancers.push(b) if b.index!=user.index && b.hasActiveAbility?(:DANCER)
      end
      while dancers.length>0
        nextUser = dancers.pop
        oldLastRoundMoved = nextUser.lastRoundMoved
        # NOTE: Petal Dance being used because of Dancer shouldn't lock the
        #       Dancer into using that move, and shouldn't contribute to its
        #       turn counter if it's already locked into Petal Dance.
        oldOutrage = nextUser.effects[PBEffects::Outrage]
        nextUser.effects[PBEffects::Outrage] += 1 if nextUser.effects[PBEffects::Outrage]>0
        oldCurrentMove = nextUser.currentMove
        preTarget = choice[3]
        preTarget = user.index if nextUser.opposes?(user) || !nextUser.opposes?(preTarget)
        @battle.pbShowAbilitySplash(nextUser,true)
        @battle.pbHideAbilitySplash(nextUser)
        if !PokeBattle_SceneConstants::USE_ABILITY_SPLASH
          @battle.pbDisplay(_INTL("{1} kept the dance going with {2}!",
             nextUser.pbThis,nextUser.abilityName))
        end
        PBDebug.logonerr{
          nextUser.effects[PBEffects::Dancer] = true
          nextUser.pbUseMoveSimple(move.id,preTarget)
          nextUser.effects[PBEffects::Dancer] = false
        }
        nextUser.lastRoundMoved = oldLastRoundMoved
        nextUser.effects[PBEffects::Outrage] = oldOutrage
        nextUser.currentMove = oldCurrentMove
        @battle.pbJudge
        return if @battle.decision>0
      end
    end
  end
  def pbProcessMoveHit(move, user, targets, hitNum, skipAccuracyCheck)
    return false if user.fainted?
    # For two-turn attacks being used in a single turn
    move.pbInitialEffect(user, targets, hitNum)
    numTargets = 0   # Number of targets that are affected by this hit
    # Count a hit for Parental Bond (if it applies)
    user.effects[PBEffects::ParentalBond] -= 1 if user.effects[PBEffects::ParentalBond] > 0
    user.effects[PBEffects::Ambidextrous] -= 1 if user.effects[PBEffects::Ambidextrous] > 0
    user.effects[PBEffects::EchoChamber] -= 1 if user.effects[PBEffects::EchoChamber] > 0
    user.effects[PBEffects::Ricochet] -= 1 if user.effects[PBEffects::Ricochet] > 0
    # Accuracy check (accuracy/evasion calc)
    if hitNum == 0 || move.successCheckPerHit?
      targets.each do |b|
        b.damageState.missed = false
        next if b.damageState.unaffected
        if pbSuccessCheckPerHit(move, user, b, skipAccuracyCheck)
          numTargets += 1
        else
          b.damageState.missed     = true
          b.damageState.unaffected = true
        end
      end
      # If failed against all targets
      if targets.length > 0 && numTargets == 0 && !move.worksWithNoTargets?
        targets.each do |b|
          next if !b.damageState.missed || b.damageState.magicCoat
          pbMissMessage(move, user, b)
          if user.itemActive?
            BattleHandlers.triggerUserItemOnMiss(user.item, user, b, move, hitNum, @battle)
          end
          break if move.pbRepeatHit?   # Dragon Darts only shows one failure message
        end
        move.pbCrashDamage(user)
        user.pbItemHPHealCheck
        pbCancelMoves
        return false
      end
    end
    # If we get here, this hit will happen and do something
    all_targets = targets
    targets = move.pbDesignateTargetsForHit(targets, hitNum)   # For Dragon Darts
    targets.each { |b| b.damageState.resetPerHit }
    #---------------------------------------------------------------------------
    # Calculate damage to deal
    if move.pbDamagingMove?
      targets.each do |b|
        next if b.damageState.unaffected
        # Check whether Substitute/Disguise will absorb the damage
        move.pbCheckDamageAbsorption(user, b)
        # Calculate the damage against b
        # pbCalcDamage shows the "eat berry" animation for SE-weakening
        # berries, although the message about it comes after the additional
        # effect below
        move.pbCalcDamage(user, b, targets.length)   # Stored in damageState.calcDamage
        # Lessen damage dealt because of False Swipe/Endure/etc.
        move.pbReduceDamage(user, b)   # Stored in damageState.hpLost
      end
    end
    # Show move animation (for this hit)
    move.pbShowAnimation(move.id, user, targets, hitNum)
    # Type-boosting Gem consume animation/message
    if user.effects[PBEffects::GemConsumed] && hitNum == 0
      # NOTE: The consume animation and message for Gems are shown now, but the
      #       actual removal of the item happens in def pbEffectsAfterMove.
      @battle.pbCommonAnimation("UseItem", user)
      @battle.pbDisplay(_INTL("The {1} strengthened {2}'s power!",
                              GameData::Item.get(user.effects[PBEffects::GemConsumed]).name, move.name))
    end
    # Messages about missed target(s) (relevant for multi-target moves only)
    if !move.pbRepeatHit?
      targets.each do |b|
        next if !b.damageState.missed
        pbMissMessage(move, user, b)
        if user.itemActive?
          BattleHandlers.triggerUserItemOnMiss(user.item, user, b, move, hitNum, @battle)
        end
      end
    end
    # Deal the damage (to all allies first simultaneously, then all foes
    # simultaneously)
    if move.pbDamagingMove?
      # This just changes the HP amounts and does nothing else
      targets.each { |b| move.pbInflictHPDamage(b) if !b.damageState.unaffected }
      # Animate the hit flashing and HP bar changes
      move.pbAnimateHitAndHPLost(user, targets)
    end
    # Self-Destruct/Explosion's damaging and fainting of user
    move.pbSelfKO(user) if hitNum == 0
    user.pbFaint if user.fainted?
    if move.pbDamagingMove?
      targets.each do |b|
        next if b.damageState.unaffected
        # NOTE: This method is also used for the OHKO special message.
        move.pbHitEffectivenessMessages(user, b, targets.length)
        # Record data about the hit for various effects' purposes
        move.pbRecordDamageLost(user, b)
      end
      # Close Combat/Superpower's stat-lowering, Flame Burst's splash damage,
      # and Incinerate's berry destruction
      targets.each do |b|
        next if b.damageState.unaffected
        move.pbEffectWhenDealingDamage(user, b)
        move.pbEffectAfterAllHits(user,b) if [:KNOCKOFF,:BUGBITE,:COVET,:THIEF,:PLUCK].include?(move.id)
      end
      # Ability/item effects such as Static/Rocky Helmet, and Grudge, etc.
      targets.each do |b|
        next if b.damageState.unaffected
        pbEffectsOnMakingHit(move, user, b)
      end
      # Disguise/Endure/Sturdy/Focus Sash/Focus Band messages
      targets.each do |b|
        next if b.damageState.unaffected
        move.pbEndureKOMessage(b)
      end
      # HP-healing held items (checks all battlers rather than just targets
      # because Flame Burst's splash damage affects non-targets)
      @battle.pbPriority(true).each { |b| b.pbItemHPHealCheck }
      # Animate battlers fainting (checks all battlers rather than just targets
      # because Flame Burst's splash damage affects non-targets)
      @battle.pbPriority(true).each { |b| b.pbFaint if b&.fainted? }
    end
    @battle.pbJudgeCheckpoint(user, move)
    # Main effect (recoil/drain, etc.)
    targets.each do |b|
      next if b.damageState.unaffected
      move.pbEffectAgainstTarget(user, b)
    end
    move.pbEffectGeneral(user)
    targets.each { |b| b.pbFaint if b&.fainted? }
    user.pbFaint if user.fainted?
    # Additional effect
    if !user.hasActiveAbility?(:SHEERFORCE)
      targets.each do |b|
        next if b.damageState.calcDamage == 0
        chance = move.pbAdditionalEffectChance(user, b)
        next if chance <= 0
        if @battle.pbRandom(100) < chance
          move.pbAdditionalEffect(user, b)
        end
      end
    end
    # Make the target flinch (because of an item/ability)
    targets.each do |b|
      next if b.fainted?
      next if b.damageState.calcDamage == 0 || b.damageState.substitute
      chance = move.pbFlinchChance(user, b)
      next if chance <= 0
      if @battle.pbRandom(100) < chance
        PBDebug.log("[Item/ability triggered] #{user.pbThis}'s King's Rock/Razor Fang or Stench")
        b.pbFlinch(user)
      end
    end
    # Message for and consuming of type-weakening berries
    # NOTE: The "consume held item" animation for type-weakening berries occurs
    #       during pbCalcDamage above (before the move's animation), but the
    #       message about it only shows here.
    targets.each do |b|
      next if b.damageState.unaffected
      next if !b.damageState.berryWeakened
      @battle.pbDisplay(_INTL("The {1} weakened the damage to {2}!", b.itemName, b.pbThis(true)))
      b.pbConsumeItem
    end
    # Steam Engine (goes here because it should be after stat changes caused by
    # the move)
#    if [:FIRE, :WATER].include?(move.calcType)
#      targets.each do |b|
#        next if b.damageState.unaffected
#        next if b.damageState.calcDamage == 0 || b.damageState.substitute
#        next if !b.hasActiveAbility?(:STEAMENGINE)
#        b.pbRaiseStatStageByAbility(:SPEED, 6, b) if b.pbCanRaiseStatStage?(:SPEED, b)
#      end
#    end
    # Fainting
    targets.each { |b| b.pbFaint if b&.fainted? }
    user.pbFaint if user.fainted?
    # Dragon Darts' second half of attack
    if move.pbRepeatHit? && hitNum == 0 &&
       targets.any? { |b| !b.fainted? && !b.damageState.unaffected }
      pbProcessMoveHit(move, user, all_targets, 1, skipAccuracyCheck)
    end
    return true
  end
  def pbFlinch(_user=nil)
    if hasActiveAbility?(:INNERFOCUS) && !@battle.moldBreaker
      @effects[PBEffects::Flinch] = false
    else
      @effects[PBEffects::Flinch] = true
    end
  end
  def pbLowerSpAtkStatStageMindGames(user)
    return false if fainted?
    # NOTE: Substitute intentially blocks Intimidate even if self has Contrary.
    if @effects[PBEffects::Substitute]>0
      if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
        @battle.pbDisplay(_INTL("{1} is protected by its substitute!",pbThis))
      else
        @battle.pbDisplay(_INTL("{1}'s substitute protected it from {2}'s {3}!",
           pbThis,user.pbThis(true),user.abilityName))
      end
      return false
    end
    if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      return pbLowerStatStageByAbility(:SPECIAL_ATTACK,1,user,false)
    end
    # NOTE: These checks exist to ensure appropriate messages are shown if
    #       Intimidate is blocked somehow (i.e. the messages should mention the
    #       Intimidate ability by name).
    if !hasActiveAbility?(:CONTRARY)
      if pbOwnSide.effects[PBEffects::Mist]>0
        @battle.pbDisplay(_INTL("{1} is protected from {2}'s {3} by Mist!",
           pbThis,user.pbThis(true),user.abilityName))
        return false
      end
      if abilityActive?
        if BattleHandlers.triggerStatLossImmunityAbility(@ability,self,:SPECIAL_ATTACK,@battle,false) ||
           BattleHandlers.triggerStatLossImmunityAbilityNonIgnorable(@ability,self,:SPECIAL_ATTACK,@battle,false) ||
           BattleHandlers.triggerStatLossImmunityAbilityNonIgnorableSandy(@ability,self,:SPECIAL_ATTACK,@battle,false)
          @battle.pbDisplay(_INTL("{1}'s {2} prevented {3}'s {4} from working!",
             pbThis,abilityName,user.pbThis(true),user.abilityName))
          return false
        end
      end
      eachAlly do |b|
        next if !b.abilityActive?
        if BattleHandlers.triggerStatLossImmunityAllyAbility(b.ability,b,self,:SPECIAL_ATTACK,@battle,false)
          @battle.pbDisplay(_INTL("{1} is protected from {2}'s {3} by {4}'s {5}!",
             pbThis,user.pbThis(true),user.abilityName,b.pbThis(true),b.abilityName))
          return false
        end
      end
    end
    return false if !pbCanLowerStatStage?(:SPECIAL_ATTACK,user)
    return pbLowerStatStageByCause(:SPECIAL_ATTACK,1,user,user.abilityName)
  end
  def pbLowerSpeedStatStageMedusoid(user)
    return false if fainted?
    # NOTE: Substitute intentially blocks Intimidate even if self has Contrary.
    if @effects[PBEffects::Substitute]>0
      if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
        @battle.pbDisplay(_INTL("{1} is protected by its substitute!",pbThis))
      else
        @battle.pbDisplay(_INTL("{1}'s substitute protected it from {2}'s {3}!",
           pbThis,user.pbThis(true),user.abilityName))
      end
      return false
    end
    if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      return pbLowerStatStageByAbility(:SPEED,1,user,false)
    end
    # NOTE: These checks exist to ensure appropriate messages are shown if
    #       Intimidate is blocked somehow (i.e. the messages should mention the
    #       Intimidate ability by name).
    if !hasActiveAbility?(:CONTRARY)
      if pbOwnSide.effects[PBEffects::Mist]>0
        @battle.pbDisplay(_INTL("{1} is protected from {2}'s {3} by Mist!",
           pbThis,user.pbThis(true),user.abilityName))
        return false
      end
      if abilityActive?
        if BattleHandlers.triggerStatLossImmunityAbility(@ability,self,:SPEED,@battle,false) ||
           BattleHandlers.triggerStatLossImmunityAbilityNonIgnorable(@ability,self,:SPEED,@battle,false) ||
           BattleHandlers.triggerStatLossImmunityAbilityNonIgnorableSandy(@ability,self,:SPEED,@battle,false)
          @battle.pbDisplay(_INTL("{1}'s {2} prevented {3}'s {4} from working!",
             pbThis,abilityName,user.pbThis(true),user.abilityName))
          return false
        end
      end
      eachAlly do |b|
        next if !b.abilityActive?
        if BattleHandlers.triggerStatLossImmunityAllyAbility(b.ability,b,self,:SPEED,@battle,false)
          @battle.pbDisplay(_INTL("{1} is protected from {2}'s {3} by {4}'s {5}!",
             pbThis,user.pbThis(true),user.abilityName,b.pbThis(true),b.abilityName))
          return false
        end
      end
    end
    return false if !pbCanLowerStatStage?(:SPEED,user)
    return pbLowerStatStageByCause(:SPEED,1,user,user.abilityName)
  end
  def pbLowerEvasionStatStageSyrup(user)
    return false if fainted?
    # NOTE: Substitute intentially blocks Intimidate even if self has Contrary.
    if @effects[PBEffects::Substitute]>0
      if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
        @battle.pbDisplay(_INTL("{1} is protected by its substitute!",pbThis))
      else
        @battle.pbDisplay(_INTL("{1}'s substitute protected it from {2}'s {3}!",
           pbThis,user.pbThis(true),user.abilityName))
      end
      return false
    end
    if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      return pbLowerStatStageByAbility(:EVASION,1,user,false)
    end
    # NOTE: These checks exist to ensure appropriate messages are shown if
    #       Intimidate is blocked somehow (i.e. the messages should mention the
    #       Intimidate ability by name).
    if !hasActiveAbility?(:CONTRARY)
      if pbOwnSide.effects[PBEffects::Mist]>0
        @battle.pbDisplay(_INTL("{1} is protected from {2}'s {3} by Mist!",
           pbThis,user.pbThis(true),user.abilityName))
        return false
      end
      if abilityActive?
        if BattleHandlers.triggerStatLossImmunityAbility(@ability,self,:EVASION,@battle,false) ||
           BattleHandlers.triggerStatLossImmunityAbilityNonIgnorable(@ability,self,:EVASION,@battle,false) ||
           BattleHandlers.triggerStatLossImmunityAbilityNonIgnorableSandy(@ability,self,:EVASION,@battle,false)
          @battle.pbDisplay(_INTL("{1}'s {2} prevented {3}'s {4} from working!",
             pbThis,abilityName,user.pbThis(true),user.abilityName))
          return false
        end
      end
      eachAlly do |b|
        next if !b.abilityActive?
        if BattleHandlers.triggerStatLossImmunityAllyAbility(b.ability,b,self,:EVASION,@battle,false)
          @battle.pbDisplay(_INTL("{1} is protected from {2}'s {3} by {4}'s {5}!",
             pbThis,user.pbThis(true),user.abilityName,b.pbThis(true),b.abilityName))
          return false
        end
      end
    end
    return false if !pbCanLowerStatStage?(:EVASION,user)
    return pbLowerStatStageByCause(:EVASION,1,user,user.abilityName)
  end
  def pbCanInflictStatus?(newStatus,user,showMessages,move=nil,ignoreStatus=false)
    return false if fainted?
    selfInflicted = (user && user.index==@index)
    # Already have that status problem
    if self.status==newStatus && !ignoreStatus
      if showMessages
        msg = ""
        case self.status
        when :SLEEP     then msg = _INTL("{1} is already asleep!", pbThis)
        when :POISON    then msg = _INTL("{1} is already poisoned!", pbThis)
        when :BURN      then msg = _INTL("{1} already has a burn!", pbThis)
        when :PARALYSIS then msg = _INTL("{1} is already paralyzed!", pbThis)
        when :FROZEN    then msg = _INTL("{1} is already frostbitten!", pbThis)
        end
        @battle.pbDisplay(msg)
      end
      return false
    end
    # Trying to replace a status problem with another one
    if self.status != :NONE && !ignoreStatus && !selfInflicted
      @battle.pbDisplay(_INTL("It doesn't affect {1}...",pbThis(true))) if showMessages
      return false
    end
    # Trying to inflict a status problem on a Pokémon behind a substitute
    if @effects[PBEffects::Substitute]>0 && !(move && move.ignoresSubstitute?(user)) &&
       !selfInflicted
      @battle.pbDisplay(_INTL("It doesn't affect {1}...",pbThis(true))) if showMessages
      return false
    end
    # Weather immunity
    if newStatus == :FROZEN && [:Sun, :HarshSun].include?(@battle.pbWeather)
      @battle.pbDisplay(_INTL("It doesn't affect {1}...",pbThis(true))) if showMessages
      return false
    end
    # Terrains immunity
    if affectedByTerrain?
      case @battle.field.terrain
      when :Electric
        if newStatus == :SLEEP
          @battle.pbDisplay(_INTL("{1} surrounds itself with electrified terrain!",
             pbThis(true))) if showMessages
          return false
        end
      when :Misty
        @battle.pbDisplay(_INTL("{1} surrounds itself with misty terrain!",pbThis(true))) if showMessages
        return false
      end
    end
    # Uproar immunity
    if newStatus == :SLEEP && !(hasActiveAbility?(:SOUNDPROOF) && !@battle.moldBreaker)
      @battle.eachBattler do |b|
        next if b.effects[PBEffects::Uproar]==0
        @battle.pbDisplay(_INTL("But the uproar kept {1} awake!",pbThis(true))) if showMessages
        return false
      end
    end
    # Cacophony Immunity
    if newStatus == :SLEEP && hasActiveAbility?([:CACOPHONY,:MOSHPIT])
      @battle.eachBattler do |b|
        next if hasActiveAbility?(:SOUNDPROOF)
        @battle.pbDisplay(_INTL("But the uproar kept {1} awake!",pbThis(true))) if showMessages
        return false
      end
    end
    # Type immunities
    hasImmuneType = false
    case newStatus
    when :SLEEP
      if @battle.field.field_effects == :Dojo
        hasImmuneType |= pbHasType?(:FIGHTING)
        hasImmuneType |= pbHasType?(:PSYCHIC)
      end
    when :POISON
      if !(user && user.hasActiveAbility?(:CORROSION))
        hasImmuneType |= pbHasType?(:POISON)
        hasImmuneType |= pbHasType?(:STEEL)
      end
    when :BURN
      hasImmuneType |= pbHasType?(:FIRE)
    when :PARALYSIS
      hasImmuneType |= pbHasType?(:ELECTRIC) && Settings::MORE_TYPE_EFFECTS
    when :FROZEN
      hasImmuneType |= pbHasType?(:ICE)
    end
    if hasImmuneType
      @battle.pbDisplay(_INTL("It doesn't affect {1}...",pbThis(true))) if showMessages
      return false
    end
    # Ability immunity
    immuneByAbility = false; immAlly = nil
    if BattleHandlers.triggerStatusImmunityAbilityNonIgnorable(self.ability,self,newStatus)
      immuneByAbility = true
    elsif selfInflicted || !@battle.moldBreaker
      if abilityActive? && BattleHandlers.triggerStatusImmunityAbility(self.ability,self,newStatus)
        immuneByAbility = true
      else
        eachAlly do |b|
          next if !b.abilityActive?
          next if !BattleHandlers.triggerStatusImmunityAllyAbility(b.ability,self,newStatus)
          immuneByAbility = true
          immAlly = b
          break
        end
      end
    end
    if immuneByAbility
      if showMessages
        @battle.pbShowAbilitySplash(immAlly || self)
        msg = ""
        if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
          case newStatus
          when :SLEEP     then msg = _INTL("{1} stays awake!", pbThis)
          when :POISON    then msg = _INTL("{1} cannot be poisoned!", pbThis)
          when :BURN      then msg = _INTL("{1} cannot be burned!", pbThis)
          when :PARALYSIS then msg = _INTL("{1} cannot be paralyzed!", pbThis)
          when :FROZEN    then msg = _INTL("{1} cannot be frostbitten!", pbThis)
          end
        elsif immAlly
          case newStatus
          when :SLEEP
            msg = _INTL("{1} stays awake because of {2}'s {3}!",
               pbThis,immAlly.pbThis(true),immAlly.abilityName)
          when :POISON
            msg = _INTL("{1} cannot be poisoned because of {2}'s {3}!",
               pbThis,immAlly.pbThis(true),immAlly.abilityName)
          when :BURN
            msg = _INTL("{1} cannot be burned because of {2}'s {3}!",
               pbThis,immAlly.pbThis(true),immAlly.abilityName)
          when :PARALYSIS
            msg = _INTL("{1} cannot be paralyzed because of {2}'s {3}!",
               pbThis,immAlly.pbThis(true),immAlly.abilityName)
          when :FROZEN
            msg = _INTL("{1} cannot be frozen solid because of {2}'s {3}!",
               pbThis,immAlly.pbThis(true),immAlly.abilityName)
          end
        else
          case newStatus
          when :SLEEP     then msg = _INTL("{1} stays awake because of its {2}!", pbThis, abilityName)
          when :POISON    then msg = _INTL("{1}'s {2} prevents poisoning!", pbThis, abilityName)
          when :BURN      then msg = _INTL("{1}'s {2} prevents burns!", pbThis, abilityName)
          when :PARALYSIS then msg = _INTL("{1}'s {2} prevents paralysis!", pbThis, abilityName)
          when :FROZEN    then msg = _INTL("{1}'s {2} prevents freezing!", pbThis, abilityName)
          end
        end
        @battle.pbDisplay(msg)
        @battle.pbHideAbilitySplash(immAlly || self)
      end
      return false
    end
    # Safeguard immunity
    if pbOwnSide.effects[PBEffects::Safeguard]>0 && !selfInflicted && move &&
       !(user && user.hasActiveAbility?([:INFILTRATOR,:JESTERSTRICK]))
      @battle.pbDisplay(_INTL("{1}'s team is protected by Safeguard!",pbThis)) if showMessages
      return false
    end
    return true
  end
  def unstoppableAbility?(abil = nil)
    abil = @ability_id if !abil
    abil = GameData::Ability.try_get(abil)
    return false if !abil
    ability_blacklist = [
      # Form-changing abilities
      :BATTLEBOND,
      :DISGUISE,
#      :FLOWERGIFT,                                        # This can be stopped
      :FORECAST,
      :MULTITYPE,
      :POWERCONSTRUCT,
      :SCHOOLING,
      :SHIELDSDOWN,
      :STANCECHANGE,
      :ZENMODE,
      :DUAT,
      # Abilities intended to be inherent properties of a certain species
      :COMATOSE,
      :RKSSYSTEM
    ]
    return ability_blacklist.include?(abil.id)
  end
  def ungainableAbility?(abil = nil)
    abil = @ability_id if !abil
    abil = GameData::Ability.try_get(abil)
    return false if !abil
    ability_blacklist = [
      # Form-changing abilities
      :BATTLEBOND,
      :DISGUISE,
      :FLOWERGIFT,
      :FORECAST,
      :MULTITYPE,
      :POWERCONSTRUCT,
      :SCHOOLING,
      :SHIELDSDOWN,
      :STANCECHANGE,
      :ZENMODE,
      :DUAT,
      # Appearance-changing abilities
      :ILLUSION,
      :IMPOSTER,
      # Abilities intended to be inherent properties of a certain species
      :COMATOSE,
      :RKSSYSTEM
    ]
    return ability_blacklist.include?(abil.id)
  end
  def takesSandstormDamage?
    return false if !takesIndirectDamage?
    return false if pbHasType?(:GROUND) || pbHasType?(:ROCK) || pbHasType?(:STEEL)
    return false if inTwoTurnAttack?("0CA","0CB")   # Dig, Dive
    return false if hasActiveAbility?([:OVERCOAT,:SANDFORCE,:SANDRUSH,:SANDVEIL,:ACCLIMATE,:FORECAST,:SCALER,:MOLTENFURY])
    return false if hasActiveItem?([:SAFETYGOGGLES,:SCALERORB])
    return true
  end
  def takesHailDamage?
    return false if !takesIndirectDamage?
    return false if pbHasType?(:ICE)
    return false if inTwoTurnAttack?("0CA","0CB")   # Dig, Dive
    return false if hasActiveAbility?([:OVERCOAT,:ICEBODY,:SNOWCLOAK,:ACCLIMATE,:FORECAST])
    return false if hasActiveItem?(:SAFETYGOGGLES)
    return true
  end
  def takesAcidRainDamage?
    return false if !takesIndirectDamage?
    return false if pbHasType?(:POISON) || pbHasType?(:STEEL)
    return false if inTwoTurnAttack?("0CA","0CB")   # Dig, Dive
    return false if hasActiveAbility?([:OVERCOAT,:ACIDDRAIN,:TOXICRUSH,:ACCLIMATE,:FORECAST])
    return false if hasActiveItem?(:SAFETYGOGGLES)
    return true
  end
  def takesStarstormDamage?
    return false if !takesIndirectDamage?
    return false if pbHasType?(:COSMIC)
    return false if inTwoTurnAttack?("0CA","0CB")   # Dig, Dive
    return false if hasActiveAbility?([:OVERCOAT,:STARSPRINT,:ASTRALCLOAK,:ACCLIMATE,:FORECAST])
    return false if hasActiveItem?(:SAFETYGOGGLES)
    return true
  end
  def pbSuccessCheckAgainstTarget(move,user,target)
    # Unseen Fist
    unseenfist = user.hasActiveAbility?(:UNSEENFIST) && move.contactMove?
    typeMod = move.pbCalcTypeMod(move.calcType,user,target)
    target.damageState.typeMod = typeMod
    # Two-turn attacks can't fail here in the charging turn
    return true if user.effects[PBEffects::TwoTurnAttack]
    return true if user.effects[PBEffects::GlaiveRush] > 0
    # Move-specific failures
    return false if move.pbFailsAgainstTarget?(user,target)
    # Immunity to priority moves because of Psychic Terrain
    if @battle.field.terrain == :Psychic && target.affectedByTerrain? && target.opposes?(user) &&
       @battle.choices[user.index][4]>0   # Move priority saved from pbCalculatePriority
      @battle.pbDisplay(_INTL("{1} surrounds itself with psychic terrain!",target.pbThis))
      return false
    end
    # Crafty Shield
    if target.pbOwnSide.effects[PBEffects::CraftyShield] && user.index!=target.index &&
       move.statusMove? && !move.pbTarget(user).targets_all && !unseenfist && move.function != "18E"
      @battle.pbCommonAnimation("CraftyShield",target)
      @battle.pbDisplay(_INTL("Crafty Shield protected {1}!",target.pbThis(true)))
      target.damageState.protected = true
      @battle.successStates[user.index].protected = true
      return false
    end
    # Wide Guard
    if target.pbOwnSide.effects[PBEffects::WideGuard] && user.index!=target.index &&
       move.pbTarget(user).num_targets > 1 && move.function != "17C" &&
       (Settings::MECHANICS_GENERATION >= 7 || move.damagingMove?) && !unseenfist
      @battle.pbCommonAnimation("WideGuard",target)
      @battle.pbDisplay(_INTL("Wide Guard protected {1}!",target.pbThis(true)))
      target.damageState.protected = true
      @battle.successStates[user.index].protected = true
      return false
    end
    if move.canProtectAgainst?
      # Quick Guard
      if target.pbOwnSide.effects[PBEffects::QuickGuard] &&
         @battle.choices[user.index][4]>0 && !unseenfist   # Move priority saved from pbCalculatePriority
        @battle.pbCommonAnimation("QuickGuard",target)
        @battle.pbDisplay(_INTL("Quick Guard protected {1}!",target.pbThis(true)))
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        return false
      end
      # Protect
      if target.effects[PBEffects::Protect] && !unseenfist
        @battle.pbCommonAnimation("Protect",target)
        @battle.pbDisplay(_INTL("{1} protected itself!",target.pbThis))
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        return false
      end
      if target.effects[PBEffects::Obstruct] && !unseenfist
        @battle.pbCommonAnimation("Obstruct",target)
        @battle.pbDisplay(_INTL("{1} protected itself!",target.pbThis))
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        if move.pbContactMove?(user) && user.affectedByContactEffect?
          if user.pbCanLowerStatStage?(:DEFENSE)
            user.pbLowerStatStage(:DEFENSE,2,nil)
          end
        end
        return false
      end
      # King's Shield
      if target.effects[PBEffects::KingsShield] && move.damagingMove? && !unseenfist
        @battle.pbCommonAnimation("KingsShield",target)
        @battle.pbDisplay(_INTL("{1} protected itself!",target.pbThis))
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        if move.pbContactMove?(user) && user.affectedByContactEffect?
          if user.pbCanLowerStatStage?(:ATTACK)
            user.pbLowerStatStage(:ATTACK, (Settings::MECHANICS_GENERATION >= 8) ? 1 : 2, nil)
          end
        end
        return false
      end
      # Spiky Shield
      if target.effects[PBEffects::SpikyShield] && !unseenfist
        @battle.pbCommonAnimation("SpikyShield",target)
        @battle.pbDisplay(_INTL("{1} protected itself!",target.pbThis))
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        if move.pbContactMove?(user) && user.affectedByContactEffect?
          @battle.scene.pbDamageAnimation(user)
          user.pbReduceHP(user.totalhp/8,false)
          @battle.pbDisplay(_INTL("{1} was hurt!",user.pbThis))
          user.pbItemHPHealCheck
        end
        return false
      end
      # Silk Trap
        if target.effects[PBEffects::SilkTrap] && move.damagingMove? && !unseenfist
          @battle.pbCommonAnimation("SpikyShield", target)
          @battle.pbDisplay(_INTL("{1} protected itself!", target.pbThis))
          target.damageState.protected = true
          @battle.successStates[user.index].protected = true
          if move.pbContactMove?(user) && user.affectedByContactEffect?
            if user.pbCanLowerStatStage?(:SPEED)
              user.pbLowerStatStage(:SPEED, 1, nil)
            end
          end
          return false
        end
      # Baneful Bunker
      if target.effects[PBEffects::BanefulBunker] && !unseenfist
        @battle.pbCommonAnimation("BanefulBunker",target)
        @battle.pbDisplay(_INTL("{1} protected itself!",target.pbThis))
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        if move.pbContactMove?(user) && user.affectedByContactEffect?
          user.pbPoison(target) if user.pbCanPoison?(target,false)
        end
        return false
      end
      # Mat Block
      if target.pbOwnSide.effects[PBEffects::MatBlock] && move.damagingMove? && !unseenfist
        # NOTE: Confirmed no common animation for this effect.
        @battle.pbDisplay(_INTL("{1} was blocked by the kicked-up mat!",move.name))
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        return false
      end
    end
    # Magic Coat/Magic Bounce
    if move.canMagicCoat? && !target.semiInvulnerable? && target.opposes?(user)
      if target.effects[PBEffects::MagicCoat]
        target.damageState.magicCoat = true
        target.effects[PBEffects::MagicCoat] = false
        return false
      end
      if target.hasActiveAbility?(:MAGICBOUNCE) && !@battle.moldBreaker &&
         !target.effects[PBEffects::MagicBounce]
        target.damageState.magicBounce = true
        target.effects[PBEffects::MagicBounce] = true
        return false
      end
    end
    # Immunity because of ability (intentionally before type immunity check)
    return false if move.pbImmunityByAbility(user,target)
    # Type immunity
    if move.pbDamagingMove? && Effectiveness.ineffective?(typeMod)
      PBDebug.log("[Target immune] #{target.pbThis}'s type immunity")
      @battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
      return false
    end
    # Dark-type immunity to moves made faster by Prankster
    if Settings::MECHANICS_GENERATION >= 7 && user.effects[PBEffects::Prankster] &&
       target.pbHasType?(:DARK) && target.opposes?(user)
      PBDebug.log("[Target immune] #{target.pbThis} is Dark-type and immune to Prankster-boosted moves")
      @battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
      return false
    end
    # Airborne-based immunity to Ground moves
    if move.damagingMove? && move.calcType == :GROUND &&
       target.airborne? && !move.hitsFlyingTargets?
      if (target.hasActiveAbility?(:LEVITATE) || target.hasActiveAbility?(:MULTITOOL) || target.hasActiveItem?(:LEVITATEORB)) && !@battle.moldBreaker
        @battle.pbShowAbilitySplash(target)
        if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
          @battle.pbDisplay(_INTL("{1} avoided the attack!",target.pbThis))
        else
          @battle.pbDisplay(_INTL("{1} avoided the attack with {2}!",target.pbThis,target.abilityName))
        end
        @battle.pbHideAbilitySplash(target)
        return false
      end
      if target.hasActiveItem?(:AIRBALLOON)
        @battle.pbDisplay(_INTL("{1}'s {2} makes Ground moves miss!",target.pbThis,target.itemName))
        return false
      end
      if target.effects[PBEffects::MagnetRise] != 0
        @battle.pbDisplay(_INTL("{1} makes Ground moves miss with Magnet Rise!",target.pbThis))
        return false
      end
      if target.effects[PBEffects::Telekinesis]>0
        @battle.pbDisplay(_INTL("{1} makes Ground moves miss with Telekinesis!",target.pbThis))
        return false
      end
    end
    if move.damagingMove? && move.calcType == :GRASS && target.hasActiveItem?(:SAPSIPPERORB)
      ability = target.ability_id
      target.ability_id = :SAPSIPPER
      if ability != target.ability_id
        @battle.pbShowAbilitySplash(target)
        if target.pbCanRaiseStatStage?(:ATTACK,target)
          target.pbRaiseStatStage(:ATTACK,1,target)
          battle.pbDisplay(_INTL("{1}'s {2} Orb boosted its Attack!",target.pbThis,target.abilityName))
        else
          battle.pbDisplay(_INTL("{1}'s {2} Orb made {3} ineffective!",target.pbThis,target.abilityName,move.name))
        end
        @battle.pbHideAbilitySplash(target)
        user.ability_id = ability
      end
      return false
    end
    if move.damagingMove? && move.calcType == :ELECTRIC && target.hasActiveItem?(:LIGHTNINGRODORB)
      ability = target.ability_id
      target.ability_id = :LIGHTNINGROD
      if ability != target.ability_id
        @battle.pbShowAbilitySplash(target)
        if target.pbCanRaiseStatStage?(:SPECIAL_ATTACK,target)
          target.pbRaiseStatStage(:SPECIAL_ATTACK,1,target)
          battle.pbDisplay(_INTL("{1}'s {2} Orb boosted its Special Attack!",target.pbThis,target.abilityName))
        else
          battle.pbDisplay(_INTL("{1}'s {2} Orb made {3} ineffective!",target.pbThis,target.abilityName,move.name))
        end
        @battle.pbHideAbilitySplash(target)
        user.ability_id = ability
      end
      return false
    end
    if move.damagingMove? && move.calcType == :FIRE && target.hasActiveItem?(:FLASHFIREORB)
      ability = target.ability_id
      target.ability_id = :FLASHFIRE
      if ability != target.ability_id
        @battle.pbShowAbilitySplash(target)
        if !target.effects[PBEffects::FlashFire]
          target.effects[PBEffects::FlashFire] = true
            battle.pbDisplay(_INTL("The power of {1}'s Fire-type moves rose because of its {2} Orb!",target.pbThis(true),target.abilityName))
        else
            battle.pbDisplay(_INTL("{1}'s {2} Orb made {3} ineffective!",
               target.pbThis,target.abilityName,move.name))
        end
        @battle.pbHideAbilitySplash(target)
        user.ability_id = ability
      end
      return false
    end
    if move.damagingMove? && move.calcType == :ROCK && target.hasActiveItem?(:SCALERORB)
      ability = target.ability_id
      target.ability_id = :SCALER
      if ability != target.ability_id
        @battle.pbShowAbilitySplash(target)
        battle.pbDisplay(_INTL("{1}'s {2} Orb made {3} ineffective!",target.pbThis,target.abilityName,move.name))
        @battle.pbHideAbilitySplash(target)
        user.ability_id = ability
      end
      return false
    end
    if move.damagingMove? && move.calcType == :COSMIC && target.hasActiveItem?(:DIMENSIONBLOCKORB)
      ability = target.ability_id
      target.ability_id = :DIMENSIONBLOCK
      if ability != target.ability_id
        @battle.pbShowAbilitySplash(target)
        battle.pbDisplay(_INTL("{1}'s {2} Orb made {3} ineffective!",target.pbThis,target.abilityName,move.name))
        @battle.pbHideAbilitySplash(target)
        user.ability_id = ability
      end
      return false
    end
    if move.damagingMove? && move.calcType == :GROUND && target.hasActiveItem?(:EARTHEATERORB)
      ability = target.ability_id
      target.ability_id = :EARTHEATER
      if ability != target.ability_id
        @battle.pbShowAbilitySplash(target)
        if target.canHeal? && target.pbRecoverHP(target.totalhp/4)>0
          @battle.pbDisplay(_INTL("{1}'s {2} Orb restored its HP.",target.pbThis,target.abilityName))
        else
          @battle.pbDisplay(_INTL("{1}'s {2} Orb made {3} ineffective!",target.pbThis,target.abilityName,move.name))
        end
        @battle.pbHideAbilitySplash(target)
        user.ability_id = ability
      end
      return false
    end
    if move.damagingMove? && move.calcType == :WATER && target.hasActiveItem?(:WATERABSORBORB)
      ability = target.ability_id
      target.ability_id = :WATERABSORB
      if ability != target.ability_id
        @battle.pbShowAbilitySplash(target)
        if target.canHeal? && target.pbRecoverHP(target.totalhp/4)>0
          @battle.pbDisplay(_INTL("{1}'s {2} Orb restored its HP.",target.pbThis,target.abilityName))
        else
          @battle.pbDisplay(_INTL("{1}'s {2} Orb made {3} ineffective!",target.pbThis,target.abilityName,move.name))
        end
        @battle.pbHideAbilitySplash(target)
        user.ability_id = ability
      end
      return false
    end
    # Immunity to powder-based moves
    if move.powderMove?
      if target.pbHasType?(:GRASS) && Settings::MORE_TYPE_EFFECTS
        PBDebug.log("[Target immune] #{target.pbThis} is Grass-type and immune to powder-based moves")
        @battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
        return false
      end
      if Settings::MECHANICS_GENERATION >= 6
        if target.hasActiveAbility?(:OVERCOAT) && !@battle.moldBreaker
          @battle.pbShowAbilitySplash(target)
          if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
            @battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
          else
            @battle.pbDisplay(_INTL("It doesn't affect {1} because of its {2}.",target.pbThis(true),target.abilityName))
          end
          @battle.pbHideAbilitySplash(target)
          return false
        end
        if target.hasActiveItem?(:SAFETYGOGGLES)
          PBDebug.log("[Item triggered] #{target.pbThis} has Safety Goggles and is immune to powder-based moves")
          @battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
          return false
        end
      end
    end
    # Substitute
    if target.effects[PBEffects::Substitute]>0 && move.statusMove? &&
       !move.ignoresSubstitute?(user) && user.index!=target.index
      PBDebug.log("[Target immune] #{target.pbThis} is protected by its Substitute")
      @battle.pbDisplay(_INTL("{1} avoided the attack!",target.pbThis(true)))
      return false
    end
    BattleHandlers.triggerOnMoveSuccessCheck(
        target.ability, user, target, move, @battle)
    return true
  end
end

class PokeBattle_Move
    def beamMove?;          return @flags[/p/]; end
    def slicingMove?;       return @flags[/q/]; end
    def windMove?;          return @flags[/r/]; end
    def hammerMove?;        return @flags[/s/]; end
    def kickingMove?;        return @flags[/t/]; end
    def boneMove?
      return [:BONECLUB,:BONEMERANG,:BONERUSH,:SHADOWBONE].include?(@id)
    end
    def ignoresSubstitute?(user)   # user is the Pokémon using this move
      if Settings::MECHANICS_GENERATION >= 6
        return true if soundMove?
        return true if user && user.hasActiveAbility?([:INFILTRATOR,:JESTERSTRICK])
      end
      return false
    end
    def damageReducedByFreeze?;  return true;  end   # For Facade
    def pbHitEffectivenessMessages(user,target,numTargets=1)
      return if target.damageState.disguise
      if target.damageState.substitute
        @battle.pbDisplay(_INTL("The substitute took damage for {1}!",target.pbThis(true)))
      end
      if target.damageState.critical
        if numTargets>1
          @battle.pbDisplay(_INTL("<c2=463f0000>A critical hit on {1}</c2>!",target.pbThis(true)))
        else
          @battle.pbDisplay(_INTL("<c2=463f0000>A critical hit!</c2>"))
        end
      end
      # Effectiveness message, for moves with 1 hit
      if !multiHitMove? && (user.effects[PBEffects::ParentalBond]==0 || user.effects[PBEffects::Ambidextrous]==0 || user.effects[PBEffects::EchoChamber]==0)
        pbEffectivenessMessage(user,target,numTargets)
      end
      if target.damageState.substitute && target.effects[PBEffects::Substitute]==0
        target.effects[PBEffects::Substitute] = 0
        @battle.pbDisplay(_INTL("{1}'s substitute faded!",target.pbThis))
      end
    end
end

class PokeBattle_TargetMultiStatUpMove < PokeBattle_Move
  def pbFailsAgainstTarget?(user,target)
    return false if damagingMove?
    failed = true
    for i in 0...@statUp.length/2
      next if !target.pbCanRaiseStatStage?(@statUp[i*2],user,self)
      failed = false
      break
    end
    if failed
      # NOTE: It's a bit of a faff to make sure the appropriate failure message
      #       is shown here, I know.
      canRaise = false
      if target.hasActiveAbility?(:CONTRARY) && !@battle.moldBreaker
        for i in 0...@statUp.length/2
          next if target.statStageAtMin?(@statUp[i*2])
          canRaise = true
          break
        end
        @battle.pbDisplay(_INTL("{1}'s stats won't go any lower!",target.pbThis)) if !canRaise
      else
        for i in 0...@statUp.length/2
          next if target.statStageAtMax?(@statUp[i*2])
          canRaise = true
          break
        end
        @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",target.pbThis)) if !canRaise
      end
      if canRaise
        target.pbCanRaiseStatStage?(@statUp[0],user,self,true)
      end
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    return if damagingMove?
    showAnim = true
    for i in 0...@statUp.length/2
      next if !target.pbCanRaiseStatStage?(@statUp[i*2],user,self)
      if target.pbRaiseStatStage(@statUp[i*2],@statUp[i*2+1],user,showAnim)
        showAnim = false
      end
    end
  end

  def pbAdditionalEffect(user,target)
    return if target.damageState.substitute
    showAnim = true
    for i in 0...@statUp.length/2
      next if !target.pbCanLowerStatStage?(@statUp[i*2],user,self)
      if target.pbRaiseStatStage(@statUp[i*2],@statUp[i*2+1],user,showAnim)
        showAnim = false
      end
    end
  end
end

class PokeBattle_Move_049 < PokeBattle_TargetStatDownMove
  def ignoresSubstitute?(user); return true; end

  def initialize(battle,move)
    super
    @statDown = [:EVASION,1]
  end

  def pbFailsAgainstTarget?(user,target)
    targetSide = target.pbOwnSide
    targetOpposingSide = target.pbOpposingSide
    return false if targetSide.effects[PBEffects::AuroraVeil]>0 ||
                    targetSide.effects[PBEffects::LightScreen]>0 ||
                    targetSide.effects[PBEffects::Reflect]>0 ||
                    targetSide.effects[PBEffects::Mist]>0 ||
                    targetSide.effects[PBEffects::Safeguard]>0
    return false if targetSide.effects[PBEffects::StealthRock] ||
                    targetSide.effects[PBEffects::Spikes]>0 ||
                    targetSide.effects[PBEffects::ToxicSpikes]>0 ||
                    targetSide.effects[PBEffects::StickyWeb]
    return false if Settings::MECHANICS_GENERATION >= 6 &&
                    (targetOpposingSide.effects[PBEffects::StealthRock] ||
                    targetOpposingSide.effects[PBEffects::Spikes]>0 ||
                    targetOpposingSide.effects[PBEffects::ToxicSpikes]>0 ||
                    targetOpposingSide.effects[PBEffects::StickyWeb] ||
                    targetOpposingSide.effects[PBEffects::CometShards])
    return false if Settings::MECHANICS_GENERATION >= 8 && @battle.field.terrain != :None
    return super
  end

  def pbEffectAgainstTarget(user,target)
    if target.pbCanLowerStatStage?(@statDown[0],user,self)
      target.pbLowerStatStage(@statDown[0],@statDown[1],user)
    end
    if target.pbOwnSide.effects[PBEffects::AuroraVeil]>0
      target.pbOwnSide.effects[PBEffects::AuroraVeil] = 0
      @battle.pbDisplay(_INTL("{1}'s Aurora Veil wore off!",target.pbTeam))
    end
    if target.pbOwnSide.effects[PBEffects::LightScreen]>0
      target.pbOwnSide.effects[PBEffects::LightScreen] = 0
      @battle.pbDisplay(_INTL("{1}'s Light Screen wore off!",target.pbTeam))
    end
    if target.pbOwnSide.effects[PBEffects::Reflect]>0
      target.pbOwnSide.effects[PBEffects::Reflect] = 0
      @battle.pbDisplay(_INTL("{1}'s Reflect wore off!",target.pbTeam))
    end
    if target.pbOwnSide.effects[PBEffects::Mist]>0
      target.pbOwnSide.effects[PBEffects::Mist] = 0
      @battle.pbDisplay(_INTL("{1}'s Mist faded!",target.pbTeam))
    end
    if target.pbOwnSide.effects[PBEffects::Safeguard]>0
      target.pbOwnSide.effects[PBEffects::Safeguard] = 0
      @battle.pbDisplay(_INTL("{1} is no longer protected by Safeguard!!",target.pbTeam))
    end
    if $gym_hazard == false
      if target.pbOwnSide.effects[PBEffects::StealthRock] ||
         (Settings::MECHANICS_GENERATION >= 6 &&
         target.pbOpposingSide.effects[PBEffects::StealthRock])
        target.pbOwnSide.effects[PBEffects::StealthRock]      = false
        target.pbOpposingSide.effects[PBEffects::StealthRock] = false if Settings::MECHANICS_GENERATION >= 6
        @battle.pbDisplay(_INTL("{1} blew away stealth rocks!",user.pbThis))
      end
      if target.pbOwnSide.effects[PBEffects::Spikes]>0 ||
         (Settings::MECHANICS_GENERATION >= 6 &&
         target.pbOpposingSide.effects[PBEffects::Spikes]>0)
        target.pbOwnSide.effects[PBEffects::Spikes]      = 0
        target.pbOpposingSide.effects[PBEffects::Spikes] = 0 if Settings::MECHANICS_GENERATION >= 6
        @battle.pbDisplay(_INTL("{1} blew away spikes!",user.pbThis))
      end
      if target.pbOwnSide.effects[PBEffects::ToxicSpikes]>0 ||
         (Settings::MECHANICS_GENERATION >= 6 &&
         target.pbOpposingSide.effects[PBEffects::ToxicSpikes]>0)
        target.pbOwnSide.effects[PBEffects::ToxicSpikes]      = 0
        target.pbOpposingSide.effects[PBEffects::ToxicSpikes] = 0 if Settings::MECHANICS_GENERATION >= 6
        @battle.pbDisplay(_INTL("{1} blew away poison spikes!",user.pbThis))
      end
      if target.pbOwnSide.effects[PBEffects::StickyWeb] ||
         (Settings::MECHANICS_GENERATION >= 6 &&
         target.pbOpposingSide.effects[PBEffects::StickyWeb])
        target.pbOwnSide.effects[PBEffects::StickyWeb]      = false
        target.pbOpposingSide.effects[PBEffects::StickyWeb] = false if Settings::MECHANICS_GENERATION >= 6
        @battle.pbDisplay(_INTL("{1} blew away sticky webs!",user.pbThis))
      end
      if target.pbOwnSide.effects[PBEffects::CometShards] ||
         (Settings::MECHANICS_GENERATION >= 6 &&
         target.pbOpposingSide.effects[PBEffects::CometShards])
        target.pbOwnSide.effects[PBEffects::CometShards]      = false
        target.pbOpposingSide.effects[PBEffects::CometShards] = false if Settings::MECHANICS_GENERATION >= 6
        @battle.pbDisplay(_INTL("{1} blew away stealth rocks!",user.pbThis))
      end
    else
      @battle.pbDisplay(_INTL("The mysterious force prevents hazard removal!"))
    end
    if Settings::MECHANICS_GENERATION >= 8 && @battle.field.terrain != :None && @battle.field.defaultTerrain != @battle.field.terrain
      case @battle.field.terrain
      when :Electric
        @battle.pbDisplay(_INTL("The electricity disappeared from the battlefield."))
      when :Grassy
        @battle.pbDisplay(_INTL("The grass disappeared from the battlefield."))
      when :Misty
        @battle.pbDisplay(_INTL("The mist disappeared from the battlefield."))
      when :Psychic
        @battle.pbDisplay(_INTL("The weirdness disappeared from the battlefield."))
      when :Poison
        @battle.pbDisplay(_INTL("The toxic waste disappeared from the battlefield."))
      end
      @battle.scene.pbChangeField(@battle.field.defaultTerrain)
      @battle.scene.pbRefreshEverything
    end
  end
end

class PokeBattle_Move_087 < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 2 if @battle.pbWeather != :None &&
                    !([:Sun,:Rain,:HarshSun,:HeavyRain,:Storm].include?(@battle.pbWeather) && user.hasUtilityUmbrella?)
    return baseDmg
  end

  def pbBaseType(user)
    ret = :NORMAL
    case @battle.pbWeather
    when :Sun, :HarshSun
      ret = :FIRE if GameData::Type.exists?(:FIRE)
    when :Rain, :HeavyRain
      ret = :WATER if GameData::Type.exists?(:WATER)
    when :Sandstorm
      ret = :ROCK if GameData::Type.exists?(:ROCK)
    when :Hail, :Sleet
      ret = :ICE if GameData::Type.exists?(:ICE)
    when :Starstorm
      ret = :COSMIC if GameData::Type.exists?(:COSMIC)
    when :Eclipse
      ret = :DARK if GameData::Type.exists?(:DARK)
    when :Fog
      ret = :FAIRY if GameData::Type.exists?(:FAIRY)
    when :Windy
      ret = :FLYING if GameData::Type.exists?(:FLYING)
    when :AcidRain
      ret = :POISON if GameData::Type.exists?(:POISON)
    end
    ret = :NORMAL if user.hasUtilityUmbrella? && [:FIRE,:WATER].include?(ret)
    return ret
  end

  def pbShowAnimation(id,user,targets,hitNum=0,showAnimation=true)
    t = pbBaseType(user)
    hitNum = 1 if t == :FIRE   # Type-specific anims
    hitNum = 2 if t == :WATER
    hitNum = 3 if t == :ROCK
    hitNum = 4 if t == :ICE
    super
  end
end

class PokeBattle_Move_0B3 < PokeBattle_Move
  def callsAnotherMove?; return true; end

  def pbOnStartUse(user,targets)
    # NOTE: It's possible in theory to not have the move Nature Power wants to
    #       turn into, but what self-respecting game wouldn't at least have Tri
    #       Attack in it?
    @npMove = :TRIATTACK
    fe = FIELD_EFFECTS[@battle.field.field_effects]
    if @battle.field.field_effects == :Castle
      @npMove = fe[:nature_power] if GameData::Move.exists?(fe[:nature_power])
    else
      case @battle.field.terrain
      when :Electric
        @npMove = :THUNDERBOLT if GameData::Move.exists?(:THUNDERBOLT)
      when :Grassy
        @npMove = :ENERGYBALL if GameData::Move.exists?(:ENERGYBALL)
      when :Misty
        @npMove = :MOONBLAST if GameData::Move.exists?(:MOONBLAST)
      when :Psychic
        @npMove = :PSYCHIC if GameData::Move.exists?(:PSYCHIC)
      else
        if @battle.field.weather == :Storm
          @npMove = :THUNDERBOLT if GameData::Move.exists?(:THUNDERBOLT)
        end
        case @battle.environment
        when :Grass, :TallGrass, :Forest, :ForestGrass
          if Settings::MECHANICS_GENERATION >= 6
            @npMove = :ENERGYBALL if GameData::Move.exists?(:ENERGYBALL)
          else
            @npMove = :SEEDBOMB if GameData::Move.exists?(:SEEDBOMB)
          end
        when :MovingWater, :StillWater, :Underwater
          @npMove = :HYDROPUMP if GameData::Move.exists?(:HYDROPUMP)
        when :Puddle
          @npMove = :MUDBOMB if GameData::Move.exists?(:MUDBOMB)
        when :Cave
          if Settings::MECHANICS_GENERATION >= 6
            @npMove = :POWERGEM if GameData::Move.exists?(:POWERGEM)
          else
            @npMove = :ROCKSLIDE if GameData::Move.exists?(:ROCKSLIDE)
          end
        when :Rock
          if Settings::MECHANICS_GENERATION >= 6
            @npMove = :EARTHPOWER if GameData::Move.exists?(:EARTHPOWER)
          else
            @npMove = :ROCKSLIDE if GameData::Move.exists?(:ROCKSLIDE)
          end
        when :Sand
          if Settings::MECHANICS_GENERATION >= 6
            @npMove = :EARTHPOWER if GameData::Move.exists?(:EARTHPOWER)
          else
            @npMove = :EARTHQUAKE if GameData::Move.exists?(:EARTHQUAKE)
          end
        when :Snow
          if Settings::MECHANICS_GENERATION >= 6
            @npMove = :FROSTBREATH if GameData::Move.exists?(:FROSTBREATH)
          else
            @npMove = :BLIZZARD if GameData::Move.exists?(:BLIZZARD)
          end
        when :Ice
          @npMove = :ICEBEAM if GameData::Move.exists?(:ICEBEAM)
        when :Volcano
          @npMove = :LAVAPLUME if GameData::Move.exists?(:LAVAPLUME)
        when :Graveyard
          @npMove = :SHADOWBALL if GameData::Move.exists?(:SHADOWBALL)
        when :Sky
          @npMove = :AIRSLASH if GameData::Move.exists?(:AIRSLASH)
        when :Space
          @npMove = :STARBEAM if GameData::Move.exists?(:STARBEAM)
        when :UltraSpace
          @npMove = :PSYSHOCK if GameData::Move.exists?(:PSYSHOCK)
        end
      end
    end
  end

  def pbEffectAgainstTarget(user,target)
    @battle.pbDisplay(_INTL("{1} turned into {2}!", @name, GameData::Move.get(@npMove).name))
    user.pbUseMoveSimple(@npMove, target.index)
  end
end

class PokeBattle_Move_516 < PokeBattle_Move
  def callsAnotherMove?; return true; end

  def pbOnStartUse(user,targets)
    # NOTE: It's possible in theory to not have the move Nature Power wants to
    #       turn into, but what self-respecting game wouldn't at least have Tri
    #       Attack in it?
    @npMove = :STARBEAM
    choice = @battle.choices[user.index]
    target = @battle.battlers[choice[3]]
    if target != nil && !target.fainted?
      type1 = target.type1
      type2 = target.type2
      case type1
      when :NORMAL
        case type2
        when :GHOST, :PSYCHIC, :FAIRY, :POISON, :DARK, :ROCK, type1; $appliance = 13
        when :FLYING, :DRAGON; $appliance = 10
        when :GROUND, :WATER, :ELECTRIC; $appliance = 12
        when :BUG,:COSMIC,:ICE,:GRASS,:STEEL; $appliance = 8
        when :FIGHTING; $appliance = 11
        when :FIRE; $appliance = 9
        end
      when :FIGHTING
        case type2
        when :ROCK, :ELECTRIC; $appliance = 12
        when :STEEL, :ICE, :COSMIC; $appliance = 8
        when :FIRE; $appliance = 9
        when :NORMAL,:FIGHTING,:FLYING,:GROUND,:BUG,:GHOST,:WATER,:GRASS,:PSYCHIC,:DRAGON,:DARK,:FAIRY,:POISON; $appliance = 11
        end
      when :FLYING
        case type2
        when :GROUND,:DRAGON,:GRASS,:ELECTRIC,:PSYCHIC,:NORMAL,:GHOST,:DARK, type1; $appliance = 10
        when :FIRE,:WATER; $appliance = 9
        when :FIGHTING; $appliance = 11
        when :STEEL,:BUG,:COSMIC; $appliance = 8
        when :POISON,:FAIRY,:ICE,:ROCK; $appliance = 13
        end
      when :ROCK
        case type2
        when :ICE, :DARK, :FLYING, :BUG, :PSYCHIC, :FAIRY, :POISON, :NORMAL, :GRASS, :DRAGON, :GHOST, type1; $appliance = 13
        when :GROUND, :WATER, :ELECTRIC, :COSMIC; $appliance = 12
        when :STEEL, :FIGHTING, :FIRE; $appliance = 9
        end
      when :GROUND
        case type2
        when :WATER,:ELECTRIC,:COSMIC; $appliance = 12
        when :DRAGON, :FLYING, :GRASS; $appliance = 10
        when :NORMAL,:FIGHTING,:POISON,:BUG,:GHOST,:STEEL,:FIRE,:PSYCHIC,:ICE,:DARK,:FAIRY,:ROCK, type1; $appliance = 9
        end
      when :POISON
        case type2
        when :DARK, :PSYCHIC, :ELECTRIC, :ROCK,:GHOST,:FAIRY,type1,:NORMAL; $appliance = 13
        when :BUG, :ICE,:COSMIC,:GRASS,:STEEL; $appliance = 8
        when :FLYING, :DRAGON; $appliance = 10
        when :FIRE,:GROUND,:WATER; $appliance = 9
        when :FIGHTING; $appliance = 11
        end
      when :BUG
        case type2
        when type1, :NORMAL, :GRASS, :FIGHTING,:POISON,:DARK,:GHOST,:DRAGON,:FAIRY,:FLYING,:WATER; $appliance = 11
        when :STEEL, :COSMIC,:ICE,:PSYCHIC,:ELECTRIC; $appliance = 8
        when :ROCK,:FIRE,:GROUND; $appliance = 9
        end
      when :GHOST
        case type2
        when :FIGHTING; $appliance = 11
        when :GROUND,:FIRE,:WATER; $appliance = 9
        when :BUG,:COSMIC,:STEEL,:ICE,:GRASS; $appliance = 8
        when :NORMAL,:FLYING,:POISON,:FAIRY,:ROCK,:ELECTRIC,:PSYCHIC,:DRAGON,:DARK, type1; $appliance = 13
        end
      when :STEEL
        case type2
        when :WATER,:FIRE,:ROCK,:GROUND; $appliance = 9
        when :DRAGON,:DARK,:NORMAL,:FLYING,:POISON,:BUG,:GHOST,:STEEL,:GRASS,:ELECTRIC,:PSYCHIC,:ICE,:FAIRY,:COSMIC, type1; $appliance = 8
        end
      when :GRASS
        case type2
        when :STEEL, :COSMIC, :ICE, :FAIRY, :PSYCHIC; $appliance = 8
        when :DRAGON, :GROUND, :FLYING, :ELECTRIC; $appliance = 10
        when :ROCK; $appliance = 13
        when :NORMAL, :FIGHTING, :POISON, :BUG, :GHOST, :WATER, type1,:DARK; $appliance = 11
        end
      when :FIRE
        case type2
        when :GRASS; $appliance = 11
        when :COSMIC; $appliance = 8
        when :NORMAL,:FLYING,:ELECTRIC,:DRAGON,:POISON,:GROUND,:ROCK,:WATER,:BUG,:GHOST,:STEEL,:PSYCHIC,:ICE,:DARK,:FAIRY,:FIGHTING, type1; $appliance = 9
        end
      when :WATER
        case type2
        when :FIRE,:FLYING,:POISON,:DRAGON,:STEEL; $appliance = 9
        when :GRASS,:BUG; $appliance = 11
        when :ICE; $appliance = 10
        when :NORMAL,:FIGHTING,:PSYCHIC,:ELECTRIC,:DARK,:FAIRY,:COSMIC, type1,:GHOST,:GROUND,:ROCK; $appliance = 12
        end
      when :ELECTRIC
        case type2
        when :FLYING,:GRASS,:GROUND,:DRAGON; $appliance = 10
        when :WATER,:ROCK,:GHOST,:PSYCHIC,type1,:DARK,:NORMAL,:FAIRY,:FIGHTING; $appliance = 12
        when :BUG,:ICE,:STEEL,:COSMIC,:POISON; $appliance = 8
        when :FIRE; $appliance = 9
        end
      when :ICE
        case type2
        when :ROCK,:GROUND,:FIRE; $appliance = 9
        when :WATER; $appliance = 10
        when :GRASS, :BUG, :STEEL, :COSMIC, :FAIRY, type1, :NORMAL,:GHOST,:PSYCHIC,:FIGHTING,:DARK,:DRAGON,:FLYING,:POISON,:ELECTRIC; $appliance = 8
        end
      when :PSYCHIC
        case type2
        when :FIGHTING,:GRASS,:BUG; $appliance = 11
        when :FIRE,:STEEL,:ICE,:COSMIC; $appliance = 9
        when :GROUND; $appliance = 12
        when :DRAGON; $appliance = 10
        when :NORMAL,:DARK,:FAIRY,:POISON,:ROCK,:GHOST,:ELECTRIC,:FLYING,:WATER, type1; $appliance = 13
        end
      when :DRAGON
        case type2
        when :FIGHTING; $appliance = 11
        when :FIRE,:ICE,:STEEL,:ROCK,:WATER; $appliance = 9
        when :NORMAL,:DARK,:PSYCHIC,:GROUND,:FLYING,:GRASS,:POISON,:BUG,:GHOST,:ELECTRIC,type1,:FAIRY,:COSMIC; $appliance = 10
        end
      when :DARK
        case type2
        when :NORMAL,:FLYING,:GHOST,:DRAGON,:FAIRY,:POISON,:PSYCHIC,:ROCK,type1; $appliance = 13
        when :GRASS,:FIRE,:STEEL,:ICE,:COSMIC,:BUG; $appliance = 8
        when :FIGHTING; $appliance = 11
        when :GROUND,:WATER,:ELECTRIC; $appliance = 12
        end
      when :FAIRY
        case type2
        when :FIRE,:COSMIC,:STEEL; $appliance = 8
        when :NORMAL,:FIGHTING,:FLYING,:POISON,:GROUND,:BUG,:WATER,:GRASS,:ICE,:ELECTRIC,:DRAGON,:DARK,:ROCK,:PSYCHIC,:GHOST, type1; $appliance = 13
        end
      when :COSMIC
        case type2
        when :WATER,:ROCK,:GROUND; $appliance = 12
        when :FIGHTING; $appliance = 11
        when :NORMAL,:ICE,:GRASS,:BUG,:STEEL,:FAIRY,:GHOST,:POISON,:FLYING,:FIRE,:ELECTRIC,:PSYCHIC,:DRAGON,type1; $appliance = 8
        end
      end
      case $appliance
      when 8
        user.effects[PBEffects::Type3] = :FIRE
        @npMove = :OVERHEAT if GameData::Move.exists?(:OVERHEAT)
      when 9
        user.effects[PBEffects::Type3] = :WATER
        @npMove = :HYDROPUMP if GameData::Move.exists?(:HYDROPUMP)
      when 10
        user.effects[PBEffects::Type3] = :ICE
        @npMove = :BLIZZARD if GameData::Move.exists?(:BLIZZARD)
      when 11
        user.effects[PBEffects::Type3] = :FLYING
        @npMove = :WINDDRILL if GameData::Move.exists?(:WINDDRILL)
      when 12
        user.effects[PBEffects::Type3] = :GRASS
        @npMove = :LEAFSTORM if GameData::Move.exists?(:LEAFSTORM)
      when 13
        user.effects[PBEffects::Type3] = :STEEL
        @npMove = :FLASHCANNON if GameData::Move.exists?(:FLASHCANNON)
      end
      if user.form!=$appliance
        @battle.pbShowAbilitySplash(user,true)
        user.pbChangeForm($appliance,_INTL("{1} transformed!",user.name))
        @battle.pbHideAbilitySplash(user)
      end
    end
  end

  def pbEffectAgainstTarget(user,target)
    @battle.pbDisplay(_INTL("{1} turned into {2}!", @name, GameData::Move.get(@npMove).name))
    user.pbUseMoveSimple(@npMove, target.index)
  end
end

class PokeBattle_Move_103 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    if user.pbOpposingSide.effects[PBEffects::Spikes]>=3
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    if @battle.field.weather==:Windy || @battle.field.field_effects == :WindTunnel
      @battle.pbDisplay(_INTL("The Wind prevented the hazards from being set!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbOpposingSide.effects[PBEffects::Spikes] += 1
    @battle.pbDisplay(_INTL("Spikes were scattered all around {1}'s feet!",
       user.pbOpposingTeam(true)))
  end
end

class PokeBattle_Move_104 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    if user.pbOpposingSide.effects[PBEffects::ToxicSpikes]>=2
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    if @battle.field.weather==:Windy || @battle.field.field_effects == :WindTunnel
      @battle.pbDisplay(_INTL("The Wind prevented the hazards from being set!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbOpposingSide.effects[PBEffects::ToxicSpikes] += 1
    @battle.pbDisplay(_INTL("Poison spikes were scattered all around {1}'s feet!",
       user.pbOpposingTeam(true)))
  end
end

class PokeBattle_Move_105 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    if user.pbOpposingSide.effects[PBEffects::StealthRock]
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    if @battle.field.weather==:Windy || @battle.field.field_effects == :WindTunnel
      @battle.pbDisplay(_INTL("The Wind prevented the hazards from being set!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbOpposingSide.effects[PBEffects::StealthRock] = true
    @battle.pbDisplay(_INTL("Pointed stones float in the air around {1}!",
       user.pbOpposingTeam(true)))
  end
end

class PokeBattle_Move_153 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    if user.pbOpposingSide.effects[PBEffects::StickyWeb]
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    if @battle.field.weather==:Windy || @battle.field.field_effects == :WindTunnel
      @battle.pbDisplay(_INTL("The Wind prevented the hazards from being set!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbOpposingSide.effects[PBEffects::StickyWeb] = true
    @battle.pbDisplay(_INTL("A sticky web has been laid out beneath {1}'s feet!",
       user.pbOpposingTeam(true)))
  end
end

class PokeBattle_Move_110 < PokeBattle_Move
  def pbEffectAfterAllHits(user,target)
    return if user.fainted? || target.damageState.unaffected
    if user.effects[PBEffects::Trapping]>0
      trapMove = GameData::Move.get(user.effects[PBEffects::TrappingMove]).name
      trapUser = @battle.battlers[user.effects[PBEffects::TrappingUser]]
      @battle.pbDisplay(_INTL("{1} got free of {2}'s {3}!",user.pbThis,trapUser.pbThis(true),trapMove))
      user.effects[PBEffects::Trapping]     = 0
      user.effects[PBEffects::TrappingMove] = nil
      user.effects[PBEffects::TrappingUser] = -1
    end
    if user.effects[PBEffects::LeechSeed]>=0
      user.effects[PBEffects::LeechSeed] = -1
      @battle.pbDisplay(_INTL("{1} shed Leech Seed!",user.pbThis))
    end
    if user.effects[PBEffects::StarSap]>=0
      user.effects[PBEffects::StarSap] = -1
      @battle.pbDisplay(_INTL("{1} shed Star Sap!",user.pbThis))
    end
    if $gym_hazard == false
      if user.pbOwnSide.effects[PBEffects::StealthRock]
        user.pbOwnSide.effects[PBEffects::StealthRock] = false
        @battle.pbDisplay(_INTL("{1} blew away stealth rocks!",user.pbThis))
      end
      if user.pbOwnSide.effects[PBEffects::Spikes]>0
        user.pbOwnSide.effects[PBEffects::Spikes] = 0
        @battle.pbDisplay(_INTL("{1} blew away spikes!",user.pbThis))
      end
      if user.pbOwnSide.effects[PBEffects::ToxicSpikes]>0
        user.pbOwnSide.effects[PBEffects::ToxicSpikes] = 0
        @battle.pbDisplay(_INTL("{1} blew away poison spikes!",user.pbThis))
      end
      if user.pbOwnSide.effects[PBEffects::StickyWeb]
        user.pbOwnSide.effects[PBEffects::StickyWeb] = false
        @battle.pbDisplay(_INTL("{1} blew away sticky webs!",user.pbThis))
      end
      if user.pbOwnSide.effects[PBEffects::CometShards]
        user.pbOwnSide.effects[PBEffects::CometShards] = false
        @battle.pbDisplay(_INTL("{1} blew away comet shards!",user.pbThis))
      end
    else
      @battle.pbDisplay(_INTL("The mysterious force prevents hazard removal!"))
    end
    user.pbRaiseStatStage(:SPEED,1,user) if !$game_switches[LvlCap::Expert]
  end
end

class PokeBattle_Move_533 < PokeBattle_PoisonMove
  def pbEffectAfterAllHits(user,target)
    return if user.fainted? || target.damageState.unaffected
    if user.effects[PBEffects::Trapping]>0
      trapMove = GameData::Move.get(user.effects[PBEffects::TrappingMove]).name
      trapUser = @battle.battlers[user.effects[PBEffects::TrappingUser]]
      @battle.pbDisplay(_INTL("{1} got free of {2}'s {3}!",user.pbThis,trapUser.pbThis(true),trapMove))
      user.effects[PBEffects::Trapping]     = 0
      user.effects[PBEffects::TrappingMove] = nil
      user.effects[PBEffects::TrappingUser] = -1
    end
    if user.effects[PBEffects::LeechSeed]>=0
      user.effects[PBEffects::LeechSeed] = -1
      @battle.pbDisplay(_INTL("{1} shed Leech Seed!",user.pbThis))
    end
    if user.effects[PBEffects::StarSap]>=0
      user.effects[PBEffects::StarSap] = -1
      @battle.pbDisplay(_INTL("{1} shed Star Sap!",user.pbThis))
    end
    if user.pbOwnSide.effects[PBEffects::StealthRock]
      user.pbOwnSide.effects[PBEffects::StealthRock] = false
      @battle.pbDisplay(_INTL("{1} blew away stealth rocks!",user.pbThis))
    end
    if user.pbOwnSide.effects[PBEffects::Spikes]>0
      user.pbOwnSide.effects[PBEffects::Spikes] = 0
      @battle.pbDisplay(_INTL("{1} blew away spikes!",user.pbThis))
    end
    if user.pbOwnSide.effects[PBEffects::ToxicSpikes]>0
      user.pbOwnSide.effects[PBEffects::ToxicSpikes] = 0
      @battle.pbDisplay(_INTL("{1} blew away poison spikes!",user.pbThis))
    end
    if user.pbOwnSide.effects[PBEffects::StickyWeb]
      user.pbOwnSide.effects[PBEffects::StickyWeb] = false
      @battle.pbDisplay(_INTL("{1} blew away sticky webs!",user.pbThis))
    end
    if user.pbOwnSide.effects[PBEffects::CometShards]
      user.pbOwnSide.effects[PBEffects::CometShards] = false
      @battle.pbDisplay(_INTL("{1} blew away comet shards!",user.pbThis))
    end
  end
end

class PokeBattle_Move_534 < PokeBattle_Move
  def initialize(battle, move)
    super
    @statUp = [:ATTACK, 1, :SPEED, 1]
  end

  def pbEffectAfterAllHits(user, target)
    return if user.fainted? || target.damageState.unaffected
    tidy = false
    # user side
    if $gym_hazard == false
      if user.pbOwnSide.effects[PBEffects::StealthRock]
        user.pbOwnSide.effects[PBEffects::StealthRock] = false
        @battle.pbDisplay(_INTL("The pointed stones disappeared from around your team!"))
        tidy = true if !tidy
      end
      if user.pbOwnSide.effects[PBEffects::CometShards]
        user.pbOwnSide.effects[PBEffects::CometShards] = false
        @battle.pbDisplay(_INTL("The comet shards blew away!"))
        tidy = true if !tidy
      end
      if user.pbOwnSide.effects[PBEffects::Spikes] > 0
        user.pbOwnSide.effects[PBEffects::Spikes] = 0
        @battle.pbDisplay(_INTL("The spikes disappeared from the ground around your team!"))
        tidy = true if !tidy
      end
      if user.pbOwnSide.effects[PBEffects::ToxicSpikes] > 0
        user.pbOwnSide.effects[PBEffects::ToxicSpikes] = 0
        @battle.pbDisplay(_INTL("The poison spikes disappeared from the ground around your team!"))
        tidy = true if !tidy
      end
      if user.pbOwnSide.effects[PBEffects::StickyWeb]
        user.pbOwnSide.effects[PBEffects::StickyWeb] = false
        @battle.pbDisplay(_INTL("The sticky web has disappeared from the ground around you!"))
        tidy = true if !tidy
      end
    else
      pbDisplay(_INTL("The mysterious force prevents hazard removal!"))
    end
    @battle.allSameSideBattlers(user).each do |b|
      b.effects[PBEffects::Substitute] = 0
      tidy = true if !tidy
    end
    # opp side
    if $gym_hazard == false
      if user.pbOpposingSide.effects[PBEffects::StealthRock]
        user.pbOpposingSide.effects[PBEffects::StealthRock] = false
        @battle.pbDisplay(_INTL("The pointed stones disappeared from around the opposing team!"))
        tidy = true if !tidy
      end
      if user.pbOpposingSide.effects[PBEffects::CometShards]
        user.pbOpposingSide.effects[PBEffects::CometShards] = false
        @battle.pbDisplay(_INTL("The comet shards blew away!"))
        tidy = true if !tidy
      end
      if user.pbOpposingSide.effects[PBEffects::Spikes] > 0
        user.pbOpposingSide.effects[PBEffects::Spikes] = 0
        @battle.pbDisplay(_INTL("The spikes disappeared from the ground around the opposing team!"))
        tidy = true if !tidy
      end
      if user.pbOpposingSide.effects[PBEffects::ToxicSpikes] > 0
        user.pbOpposingSide.effects[PBEffects::ToxicSpikes] = 0
        @battle.pbDisplay(_INTL("The poison spikes disappeared from the ground around the opposing team!"))
        tidy = true if !tidy
      end
      if user.pbOpposingSide.effects[PBEffects::StickyWeb]
        user.pbOpposingSide.effects[PBEffects::StickyWeb] = false
        @battle.pbDisplay(_INTL("The sticky web has disappeared from the ground around the opposing team!"))
      end
    else
      pbDisplay(_INTL("The mysterious force prevents hazard removal!"))
    end
    @battle.eachOtherSideBattler(user.index) do |b|
      b.effects[PBEffects::Substitute] = 0
      tidy = true if !tidy
    end
    @battle.pbDisplay(_INTL("Tidying up complete!")) if tidy
    showAnim = true
    (@statUp.length / 2).times do |i|
      if user.pbCanRaiseStatStage?(@statUp[i * 2], user, self)
        showAnim = false if user.pbRaiseStatStage(@statUp[i * 2], @statUp[(i * 2) + 1], user, showAnim)
      else
        @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!", user.pbThis))
      end
    end
  end
end

class PokeBattle_Move_176 < PokeBattle_StatUpMove
  def initialize(battle,move)
    super
    @statUp = [:SPEED,1]
  end

  def pbMoveFailed?(user,targets)
    if Settings::MECHANICS_GENERATION >= 7 && @id == :AURAWHEEL
      if !user.isSpecies?(:MORPEKO) &&
         !user.effects[PBEffects::TransformSpecies] == :MORPEKO
        @battle.pbDisplay(_INTL("But {1} can't use the move!",user.pbThis))
        return true
      end
    end
    return false
  end

  def pbBaseType(user)
    ret = :NORMAL
    case user.form
    when 0
      ret = :ELECTRIC if GameData::Type.exists?(:ELECTRIC)
    when 1
      ret = :DARK if GameData::Type.exists?(:DARK)
    end
    return ret
  end
end



#===============================================================================
# User's Defense is used instead of user's Attack for this move's calculations.
# (Body Press)
#===============================================================================
class PokeBattle_Move_177 < PokeBattle_Move
  def pbGetAttackStats(user,target)
    return user.defense, (user.stages[:DEFENSE] + 6)
  end
end



#===============================================================================
# If the user attacks before the target, or if the target switches in during the
# turn that Fishious Rend is used, its base power doubles. (Fishious Rend, Bolt Beak)
#===============================================================================
class PokeBattle_Move_178 < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    if @battle.choices[target.index][0]!=:None &&
       ((@battle.choices[target.index][0]!=:UseMove &&
       @battle.choices[target.index][0]==:Shift) || target.movedThisRound?)
    else
      baseDmg *= 2
    end
    return baseDmg
  end
end



#===============================================================================
# Raises all user's stats by 1 stage in exchange for the user losing 1/3 of its
# maximum HP, rounded down. Fails if the user would faint. (Clangorous Soul)
#===============================================================================
class PokeBattle_Move_179 < PokeBattle_Move
  def initialize(battle, move)
    super
    @statUp = [
      :ATTACK, 1,
      :DEFENSE, 1,
      :SPECIAL_ATTACK, 1,
      :SPECIAL_DEFENSE, 1,
      :SPEED, 1
    ]
  end

  def pbMoveFailed?(user, targets)
    if user.hp <= [user.totalhp / 3, 1].max
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return super
  end

  def pbEffectGeneral(user)
    super
    user.pbReduceHP([user.totalhp / 3, 1].max, false)
    user.pbItemHPHealCheck
  end
end



#===============================================================================
# Swaps barriers, veils and other effects between each side of the battlefield.
# (Court Change)
#===============================================================================
class PokeBattle_Move_17A < PokeBattle_Move
  def initialize(battle,move)
    super
    @swapEffects = [:Reflect, :LightScreen, :AuroraVeil, :SeaOfFire,
      :Swamp, :Rainbow, :Mist, :Safeguard, :StealthRock, :Spikes,
      :StickyWeb, :ToxicSpikes, :CometShards, :Tailwind].map!{|e| getConst(PBEffects,e) }
  end

  def pbMoveFailed(user,targets)
    sides = [user.pbOwnSide,user.pbOpposingSide]
    failed = true
    for i in 0...2
      side = @battle.sides[i]
      @swapEffects.each do |j|
        next if !side.effects[j] || side.effects[j] == 0
        failed = false
        break
      end
    end
    if failed
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end


  def pbEffectGeneral(user)
    side0 = @battle.sides[0]
    side1 = @battle.sides[1]
    @swapEffects.each do |j|
      side0.effects[j], side1.effects[j] = side1.effects[j], side0.effects[j]
    end
    @battle.pbDisplay(_INTL("{1} swapped the battle effects affecting each side of the field!",user.pbThis))
  end
end


#===============================================================================
# The user sharply raises the target's Attack and Sp. Atk stats by decorating
# the target. (Decorate)
#===============================================================================
class PokeBattle_Move_17B < PokeBattle_TargetMultiStatUpMove
  def initialize(battle,move)
    super
    @statUp = [:ATTACK,2,:SPATK,2]
  end
end



#===============================================================================
# In singles, this move hits the target twice. In doubles, this move hits each
# target once. If one of the two opponents protects or while semi-invulnerable
# or is a Fairy-type Pokémon, it hits the opponent that doesn't protect twice.
# In Doubles, not affected by WideGuard.
# (Dragon Darts)
#===============================================================================
class PokeBattle_Move_17C < PokeBattle_Move_0BD
  def pbNumHits(user, targets); return 1;    end
  def pbRepeatHit?;             return true; end

  def pbModifyTargets(targets, user)
    return if targets.length != 1
    choices = []
    targets[0].allAllies.each { |b| user.pbAddTarget(choices, user, b, self) }
    return if choices.length == 0
    idxChoice = (choices.length > 1) ? @battle.pbRandom(choices.length) : 0
    user.pbAddTarget(targets, user, choices[idxChoice], self, !pbTarget(user).can_choose_distant_target?)
  end

  def pbShowFailMessages?(targets)
    if targets.length > 1
      valid_targets = targets.select { |b| !b.fainted? && !b.damageState.unaffected }
      return valid_targets.length <= 1
    end
    return super
  end

  def pbDesignateTargetsForHit(targets, hitNum)
    valid_targets = []
    targets.each { |b| valid_targets.push(b) if !b.damageState.unaffected }
    return [valid_targets[1]] if valid_targets[1] && hitNum == 1
    return [valid_targets[0]]
  end
end



#===============================================================================
# Prevents both the user and the target from escaping. (Jaw Lock)
#===============================================================================
class PokeBattle_Move_17D < PokeBattle_Move
  def pbEffectAgainstTarget(user,target)
    if target.effects[PBEffects::JawLockUser] == -1 && !target.effects[PBEffects::JawLock] &&
      user.effects[PBEffects::JawLockUser] == -1 && !user.effects[PBEffects::JawLock]
      user.effects[PBEffects::JawLock]       = true
      target.effects[PBEffects::JawLock]     = true
      user.effects[PBEffects::JawLockUser]   = user.index
      target.effects[PBEffects::JawLockUser] = user.index
      @battle.pbDisplay(_INTL("Neither Pokémon can run away!"))
    end
  end
end



#===============================================================================
# The user restores 1/4 of its maximum HP, rounded half up. If there is and
# adjacent ally, the user restores 1/4 of both its and its ally's maximum HP,
# rounded up. (Life Dew)
#===============================================================================
class PokeBattle_Move_17E < PokeBattle_Move
  def healingMove?; return true; end
  def worksWithNoTargets?; return true; end

  def pbMoveFailed?(user,targets)
    failed = true
    @battle.eachSameSideBattler(user) do |b|
      next if b.hp == b.totalhp
      failed = false
      break
    end
    if failed
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user,target)
    if target.hp == target.totalhp
      @battle.pbDisplay(_INTL("{1}'s HP is full!",target.pbThis))
      return true
    elsif !target.canHeal?
      @battle.pbDisplay(_INTL("{1} is unaffected!",target.pbThis))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    hpGain = (target.totalhp/4.0).round
    target.pbRecoverHP(hpGain)
    @battle.pbDisplay(_INTL("{1}'s HP was restored.",target.pbThis))
  end
end



#===============================================================================
# Increases each stat by 1 stage. Prevents user from fleeing. (No Retreat)
#===============================================================================
class PokeBattle_Move_17F < PokeBattle_MultiStatUpMove
  def pbMoveFailed?(user,targets)
    if user.effects[PBEffects::NoRetreat]
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    if !user.pbCanRaiseStatStage?(:ATTACK,user,self,true) &&
       !user.pbCanRaiseStatStage?(:DEFENSE,user,self,true) &&
       !user.pbCanRaiseStatStage?(:SPATK,user,self,true) &&
       !user.pbCanRaiseStatStage?(:SPDEF,user,self,true) &&
       !user.pbCanRaiseStatStage?(:SPEED,user,self,true)
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    if user.pbCanRaiseStatStage?(:ATTACK,user,self)
      user.pbRaiseStatStage(:ATTACK,1,user)
    end
    if user.pbCanRaiseStatStage?(:DEFENSE,user,self)
      user.pbRaiseStatStage(:DEFENSE,1,user)
    end
    if user.pbCanRaiseStatStage?(:SPEED,user,self)
      user.pbRaiseStatStage(:SPEED,1,user)
    end
    if user.pbCanRaiseStatStage?(:SPATK,user,self)
      user.pbRaiseStatStage(:SPATK,1,user)
    end
    if user.pbCanRaiseStatStage?(:SPDEF,user,self)
      user.pbRaiseStatStage(:SPDEF,1,user)
    end
    if !(user.effects[PBEffects::MeanLook]>=0 || user.effects[PBEffects::Trapping]>0 ||
       user.effects[PBEffects::JawLock] || user.effects[PBEffects::Octolock]>=0)
      user.effects[PBEffects::NoRetreat] = true
      @battle.pbDisplay(_INTL("{1} can no longer escape because it used No Retreat!",user.pbThis))
    end
  end
end


#===============================================================================
# Changes Revelation Dance to only change types for Oricorio
#===============================================================================
class PokeBattle_Move_169 < PokeBattle_Move
  def pbBaseType(user)
    userTypes = user.pbTypes(true)
    if user.isSpecies?(:ORICORIO)
      return userTypes[0]
    else
      return :NORMAL
    end
  end
end

#===============================================================================
# Ignores move redirection from abilities and moves. (Snipe Shot)
#===============================================================================
class PokeBattle_Move_182 < PokeBattle_Move
end



#===============================================================================
# Consumes berry and raises the user's Defense by 2 stages. (Stuff Cheeks)
#===============================================================================
class PokeBattle_Move_183 < PokeBattle_Move

  def pbMoveFailed?(user,targets)
    if (!user.item || !user.item.is_berry?) && user.pbCanRaiseStatStage?(:DEFENSE,user,self)
      @battle.pbDisplay("But it failed!")
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbRaiseStatStage(:DEFENSE,2,user)
    user.pbHeldItemTriggerCheck(user.item,false)
    user.pbConsumeItem(true,true,false) if user.item
  end
end



#===============================================================================
# Forces all active Pokémon to consume their held berries. This move bypasses
# Substitutes. (Tea Time)
#===============================================================================
class PokeBattle_Move_184 < PokeBattle_Move
  def ignoresSubstitute?(user); return true; end

  def pbMoveFailed?(user,targets)
    @validTargets = []
    @battle.eachBattler do |b|
      next if !b.item || !b.item.is_berry?
      @validTargets.push(b.index)
    end
    if @validTargets.length==0
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user,target)
    return false if @validTargets.include?(target.index)
    return true if target.semiInvulnerable?
  end

  def pbEffectAgainstTarget(user,target)
    @battle.pbDisplay(_INTL("It's tea time! Everyone dug in to their Berries!"))
    target.pbHeldItemTriggerCheck(target.item,false)
    target.pbConsumeItem(true,true,false) if target.item.is_berry?
  end
end



#===============================================================================
# Decreases Opponent's Defense by 1 stage. Does Double Damage under gravity
# (Grav Apple)
#===============================================================================
class PokeBattle_Move_185 < PokeBattle_TargetStatDownMove
  def initialize(battle,move)
    super
    @statDown = [:DEFENSE,1]
  end

  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 1.5 if @battle.field.effects[PBEffects::Gravity] > 0
    return baseDmg
  end
end



#===============================================================================
# Decrease 1 stage of speed and weakens target to fire moves. (Tar Shot)
#===============================================================================
class PokeBattle_Move_186 < PokeBattle_Move

  def pbFailsAgainstTarget?(user,target)
    if !target.pbCanLowerStatStage?(:SPEED,target,self) && !target.effects[PBEffects::TarShot]
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    target.pbLowerStatStage(:SPEED,1,target)
    target.effects[PBEffects::TarShot] = true
    @battle.pbDisplay(_INTL("{1} became weaker to fire!",target.pbThis))
  end
end

#===============================================================================
# Hits 3 times and always critical. (Surging Strikes)
#===============================================================================
class PokeBattle_Move_188 < PokeBattle_Move_0A0
  def multiHitMove?;           return true; end
  def pbNumHits(user,targets); return 3;    end
end

#===============================================================================
# Restore HP and heals any status conditions of itself and its allies
# (Jungle Healing)
#===============================================================================
class PokeBattle_Move_189 < PokeBattle_Move
  def healingMove?; return true; end

  def pbMoveFailed?(user,targets)
    jglheal = 0
    for i in 0...targets.length
      jglheal += 1 if (!targets[i].canHeal?) && targets[i].pbHasAnyStatus?
    end
    if jglheal == targets.length
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    target.pbCureStatus
    if target.canHeal?
      hpGain = (target.totalhp/4.0).round
      target.pbRecoverHP(hpGain)
      @battle.pbDisplay(_INTL("{1}'s health was restored.",target.pbThis))
    end
    super
  end
end



#===============================================================================
# Changes type and base power based on Battle Terrain (Terrain Pulse)
#===============================================================================
class PokeBattle_Move_18A < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 2 if @battle.field.terrain != :None && !user.airborne?
    return baseDmg
  end

  def pbBaseType(user)
    ret = :NORMAL
    if !user.airborne?
      case @battle.field.terrain
      when :Electric
        ret = :ELECTRIC if GameData::Type.exists?(:ELECTRIC)
      when :Grassy
        ret = :GRASS if GameData::Type.exists?(:GRASS)
      when :Misty
        ret = :FAIRY if GameData::Type.exists?(:FAIRY)
      when :Psychic
        ret = :PSYCHIC if GameData::Type.exists?(:PSYCHIC)
      when :Poison
        ret = :POISON if GameData::Type.exists?(:POISON)
      end
      if @battle.field.weather == :Storm
        ret = :ELECTRIC if GameData::Type.exists?(:ELECTRIC)
      end
    end
    return ret
  end

  def pbShowAnimation(id,user,targets,hitNum=0,showAnimation=true)
    t = pbBaseType(user)
    hitNum = 1 if t == :ELECTRIC
    hitNum = 2 if t == :GRASS
    hitNum = 3 if t == :FAIRY
    hitNum = 4 if t == :PSYCHIC
    hitNum = 5 if t == :POISON
    super
  end
end



#===============================================================================
# Burns opposing Pokemon that have increased their stats in that turn before the
# execution of this move (Burning Jealousy)
#===============================================================================
class PokeBattle_Move_18B < PokeBattle_Move
  def pbAdditionalEffect(user,target)
    return if target.damageState.substitute
    return if target.damageState.iceface
    if target.pbCanBurn?(user,false,self) &&
       target.effects[PBEffects::BurningJealousy]
      target.pbBurn(user)
    end
  end
end



#===============================================================================
# Move has increased Priority in Grassy Terrain (Grassy Glide)
#===============================================================================
class PokeBattle_Move_18C < PokeBattle_Move
  def pbChangePriority(user)
    return 1 if @battle.field.terrain == :Grassy && !user.airborne?
    return 1 if [:Grassy,:Garden].include?(@battle.field.field_effects)
    return 0
  end
end



#===============================================================================
# Power Doubles onn Electric Terrain (Rising Voltage)
#===============================================================================
class PokeBattle_Move_18D < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 2 if @battle.field.terrain == :Electric &&
                    !target.airborne?
    return baseDmg
  end
end



#===============================================================================
# Boosts Targets' Attack and Defense (Coaching)
#===============================================================================
class PokeBattle_Move_18E < PokeBattle_TargetMultiStatUpMove
  def initialize(battle,move)
    super
    @statUp = [:ATTACK,1,:DEFENSE,1]
  end
end



#===============================================================================
# Renders item unusable (Corrosive Gas)
#===============================================================================
class PokeBattle_Move_18F < PokeBattle_Move
  def pbEffectAgainstTarget(user,target)
    return if @battle.wildBattle? && user.opposes?   # Wild Pokémon can't knock off
    return if user.fainted?
    return if target.damageState.substitute
    return if !target.item || target.unlosableItem?(target.item)
    return if target.hasActiveAbility?(:STICKYHOLD) && !@battle.moldBreaker
    itemName = target.itemName
    target.pbRemoveItem(false)
    @battle.pbDisplay(_INTL("{1} dropped its {2}!",target.pbThis,itemName))
  end
end

#===============================================================================
# Target drops its item. It regains the item at the end of the battle. (Knock Off)
# If target has a losable item, damage is multiplied by 1.5.
#===============================================================================
class PokeBattle_Move_0F0 < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    if Settings::MECHANICS_GENERATION >= 6 &&
       target.item && !target.unlosableItem?(target.item)
       # NOTE: Damage is still boosted even if target has Sticky Hold or a
       #       substitute.
      baseDmg = (baseDmg*1.5).round
    end
    return baseDmg
  end

  def pbEffectAfterAllHits(user,target)
    return if @battle.wildBattle? && user.opposes?   # Wild Pokémon can't knock off
    return if user.fainted?
    return if target.damageState.unaffected || target.damageState.substitute
    return if !target.item || target.unlosableItem?(target.item)
    return if target.hasActiveAbility?(:STICKYHOLD) && !target.affectedByMoldBreaker?
    itemName = target.itemName
    target.pbRemoveItem(true)
    if @battle.wildBattle? && !user.opposes? && !$game_switches[908]
      $PokemonBag.pbStoreItem(target.item)
    end
    target.item = nil
    @battle.pbDisplay(_INTL("{1} dropped its {2}!",target.pbThis,itemName))
  end
end

class PokeBattle_Move_003 < PokeBattle_SleepMove
  def pbMoveFailed?(user,targets)
    if Settings::MECHANICS_GENERATION <= 7 && @id == :DARKVOID
      if !user.isSpecies?(:DARKRAI) && user.effects[PBEffects::TransformSpecies] != :DARKRAI
        @battle.pbDisplay(_INTL("But {1} can't use the move!",user.pbThis))
        return true
      end
    end
    return false
  end

  def pbEndOfMoveUsageEffect(user,targets,numHits,switchedBattlers)
    return if numHits==0
    return if user.fainted? || user.effects[PBEffects::Transform]
    return if @id != :RELICSONG
    return if !user.isSpecies?(:MELOETTA)
    return if user.hasActiveAbility?(:SHEERFORCE) && @addlEffect>0
    newForm = (user.form+1)%2
    user.pbChangeForm(newForm,_INTL("{1} transformed!",user.pbThis))
  end
end

#===============================================================================
# User steals the target's item, if the user has none itself. (Covet, Thief)
# Items stolen from wild Pokémon are kept after the battle.
#===============================================================================
class PokeBattle_Move_0F1 < PokeBattle_Move
  def pbEffectAfterAllHits(user,target)
    return if @battle.wildBattle? && user.opposes?   # Wild Pokémon can't thieve
    return if user.fainted?
    return if target.damageState.unaffected || target.damageState.substitute
    return if !target.item || user.item
    return if target.unlosableItem?(target.item)
    return if user.unlosableItem?(target.item)
    return if target.hasActiveAbility?(:STICKYHOLD) && !target.affectedByMoldBreaker?
    itemName = target.itemName
    user.item = target.item
    # Permanently steal the item from wild Pokémon
    if @battle.wildBattle? && target.opposes? && user.item != nil
      $PokemonBag.pbStoreItem(target.item)
    end
    if @battle.wildBattle? && target.opposes? &&
       target.initialItem==target.item && !user.initialItem
      user.setInitialItem(target.item)
      target.pbRemoveItem
    else
      target.pbRemoveItem(true)
    end
    @battle.pbDisplay(_INTL("{1} stole {2}'s {3}!",user.pbThis,target.pbThis(true),itemName))
    user.pbHeldItemTriggerCheck
  end
end

#===============================================================================
# Power is boosted on Psychic Terrain (Expanding Force)
#===============================================================================
class PokeBattle_Move_190 < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 1.5 if [:Psychic,:Dream].include?(@battle.field.field_effects)
    baseDmg *= 1.5 if @battle.field.terrain == :Psychic
    return baseDmg
  end
end



#===============================================================================
# Boosts Sp Atk on 1st Turn and Attacks on 2nd (Meteor Beam)
#===============================================================================
class PokeBattle_Move_191 < PokeBattle_TwoTurnMove
  def pbIsChargingTurn?(user)
    ret = super
    if !user.effects[PBEffects::TwoTurnAttack]
      if ([:Starstorm].include?(@battle.pbWeather) && !user.hasUtilityUmbrella?) || user.hasActiveAbility?(:IMPATIENT) ||
        [:Space,:Distortion].include?(@battle.field.field_effects)
        @powerHerb = false
        @chargingTurn = true
        @damagingTurn = true
        return false
      end
    end
    return ret
  end
  def pbChargingTurnMessage(user,targets)
    @battle.pbDisplay(_INTL("{1} is overflowing with space power!",user.pbThis))
  end

  def pbChargingTurnEffect(user,target)
    if user.pbCanRaiseStatStage?(:SPECIAL_ATTACK,user,self)
      user.pbRaiseStatStage(:SPECIAL_ATTACK,1,user)
    end
  end
end



#===============================================================================
# Fails if the Target has no Item (Poltergeist)
#===============================================================================
class PokeBattle_Move_192 < PokeBattle_Move
  def pbFailsAgainstTarget?(user,target)
    if !target.item
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    @battle.pbDisplay(_INTL("{1} is about to be attacked by its {2}!",target.pbThis,target.itemName))
    return false
  end
end



#===============================================================================
# Reduces Defense and Raises Speed after all hits (Scale Shot)
#===============================================================================
class PokeBattle_Move_193 < PokeBattle_Move_0C0
  def multiHitMove?; return true; end

  def pbNumHits(user, targets)
    hitChances = [
      2, 2, 2, 2, 2, 2, 2,
      3, 3, 3, 3, 3, 3, 3,
      4, 4, 4,
      5, 5, 5
    ]
    r = @battle.pbRandom(hitChances.length)
    r = hitChances.length - 1 if user.hasActiveAbility?(:SKILLLINK)
    return hitChances[r]
  end

  def pbEffectAfterAllHits(user, target)
    return if target.damageState.unaffected
    if user.pbCanLowerStatStage?(:DEFENSE, user, self)
      user.pbLowerStatStage(:DEFENSE, 1, user)
    end
    if user.pbCanRaiseStatStage?(:SPEED, user, self)
      user.pbRaiseStatStage(:SPEED, 1, user)
    end
  end
end

class PokeBattle_Move_520 < PokeBattle_Move_0C0
  def hitsFlyingTargets?; return true; end

  def pbCalcTypeModSingle(moveType,defType,user,target)
    return Effectiveness::NORMAL_EFFECTIVE_ONE if moveType == :GROUND && defType == :FLYING
    return super
  end
end

class PokeBattle_Move_521 < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 2 if @battle.field.terrain == :Misty && user.affectedByTerrain?
    baseDmg *= 1.25 if @battle.field.field_effects == :DarkRoom
    baseDmg *= 2 if @battle.pbWeather == :Eclipse && !user.hasActiveAbility?(:NOCTEMBOOST)
    return baseDmg
  end
end

#===============================================================================
# Double damage if stats were lowered that turn. (Lash Out)
#===============================================================================
class PokeBattle_Move_194 < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 2 if user.effects[PBEffects::LashOut]
    return baseDmg
  end
end



#===============================================================================
# Removes all Terrain. Fails if there is no Terrain (Steel Roller)
#===============================================================================
class PokeBattle_Move_195 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    if @battle.field.terrain == :None
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    case @battle.field.terrain
      when :Electric
        @battle.pbDisplay(_INTL("The electric current disappeared from the battlefield!"))
      when :Grassy
        @battle.pbDisplay(_INTL("The grass disappeared from the battlefield!"))
      when :Misty
        @battle.pbDisplay(_INTL("The mist disappeared from the battlefield!"))
      when :Psychic
        @battle.pbDisplay(_INTL("The weirdness disappeared from the battlefield!"))
      when :Poison
        @battle.pbDisplay(_INTL("The toxic waste disappeared from the battlefield!"))
    end
    @battle.scene.pbChangeField(@battle.defaultTerrain)
  end
end



#===============================================================================
# Self KO. Boosted Damage when on Misty Terrain (Misty Explosion)
#===============================================================================
class PokeBattle_Move_196 < PokeBattle_Move_0E0
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 1.5 if @battle.field.terrain == :Misty &&
                        !user.airborne?
    return baseDmg
  end
end



#===============================================================================
# Target becomes Psychic type. (Magic Powder)
#===============================================================================
class PokeBattle_Move_197 < PokeBattle_Move
  def pbFailsAgainstTarget?(user,target)
    if !target.canChangeType? ||
       !target.pbHasOtherType?(:PSYCHIC)
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    newType = :PSYCHIC
    target.pbChangeTypes(newType)
    typeName = GameData::Type.get(newType).name
    @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",target.pbThis,typeName))
  end
end

#===============================================================================
# Target's last move used loses 3 PP. (Eerie Spell - Galarian Slowking)
#===============================================================================
class PokeBattle_Move_198 < PokeBattle_Move
  def pbFailsAgainstTarget?(user,target)
    failed = true
    target.eachMove do |m|
      next if m.id != target.lastRegularMoveUsed || m.pp==0 || m.totalpp<=0
      failed = false; break
    end
    if failed
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    target.eachMove do |m|
      next if m.id != target.lastRegularMoveUsed
      reduction = [3,m.pp].min
      target.pbSetPP(m,m.pp-reduction)
      @battle.pbDisplay(_INTL("It reduced the PP of {1}'s {2} by {3}!",
         target.pbThis(true),m.name,reduction))
      break
    end
  end
end


#===============================================================================
# Deals double damage to Dynamax POkémons. Dynamax is not implemented though.
# (Behemoth Blade, Behemoth Bash, Dynamax Cannon)
#===============================================================================
class PokeBattle_Move_199 < PokeBattle_Move
  # DYNAMAX IS NOT IMPLEMENTED.
end

class PokeBattle_Move_500 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    if user.pbOpposingSide.effects[PBEffects::CometShards] || user.pbOpposingSide.effects[PBEffects::StealthRock]
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    if @battle.field.weather==:Windy || @battle.field.field_effects == :WindTunnel
      @battle.pbDisplay(_INTL("The Wind prevented the hazards from being set!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbOpposingSide.effects[PBEffects::CometShards] = true
    @battle.scene.pbAnimation(GameData::Move.get(:STEALTHROCK).id,user,user)
    @battle.pbDisplay(_INTL("Comet shards float in the air around {1}!",
       user.pbOpposingTeam(true)))
  end
end


class PokeBattle_Move_501 < PokeBattle_Move_163
  def recoilMove?;                 return true; end
  def pbCalcTypeModSingle(moveType,defType,user,target)
    return Effectiveness::NORMAL_EFFECTIVE_ONE if moveType == :ELECTRIC &&
                                                        defType == :GROUND
    return super
  end
  def pbRecoilDamage(user,target)
    return (target.damageState.totalHPLost/2.0).round
  end
end

class PokeBattle_Move_502 <PokeBattle_WeatherMove
  def initialize(battle,move)
    super
    @weatherType = :Starstorm
  end
end

class PokeBattle_Move_700 <PokeBattle_WeatherMove
  def initialize(battle,move)
    super
    @weatherType = :Eclipse
  end
end

class PokeBattle_Move_701 <PokeBattle_Move
  def ignoresSubstitute?(user); return true; end
end

class PokeBattle_Move_503 < PokeBattle_TwoTurnMove
  def pbIsChargingTurn?(user)
    ret = super
    if !user.effects[PBEffects::TwoTurnAttack]
      if [:Starstorm].include?(@battle.pbWeather) || [:Space,:Distortion].include?(@battle.field.field_effects)
        @powerHerb = false
        @chargingTurn = true
        @damagingTurn = true
        return false
      end
    end
    return ret
  end

  def pbChargingTurnMessage(user,targets)
    @battle.pbDisplay(_INTL("{1} took in starlight!",user.pbThis))
  end
end

class PokeBattle_Move_504 < PokeBattle_Move_163

  def pbCalcTypeModSingle(moveType,defType,user,target)
    return Effectiveness::NORMAL_EFFECTIVE_ONE if moveType == :DRAGON &&
                                                        defType == :FAIRY
    return super
  end
end

class PokeBattle_Move_505 < PokeBattle_Move
  def pbCalcTypeModSingle(moveType,defType,user,target)
    return Effectiveness::SUPER_EFFECTIVE_ONE if defType == :ELECTRIC
    return super
  end
end

class PokeBattle_Move_524 < PokeBattle_BurnMove
  def pbCalcTypeModSingle(moveType,defType,user,target)
    return Effectiveness::SUPER_EFFECTIVE_ONE if defType == :ICE
    return super
  end
end

class PokeBattle_Move_525 < PokeBattle_Move
  def pbEffectGeneral(user)
    if !$game_switches[LvlCap::Expert] && @battle.field.terrain != :None
      case @battle.field.terrain
      when :Electric
        @battle.pbDisplay(_INTL("The electricity disappeared from the battlefield."))
      when :Grassy
        @battle.pbDisplay(_INTL("The grass disappeared from the battlefield."))
      when :Misty
        @battle.pbDisplay(_INTL("The mist disappeared from the battlefield."))
      when :Psychic
        @battle.pbDisplay(_INTL("The weirdness disappeared from the battlefield."))
      when :Poison
        @battle.pbDisplay(_INTL("The toxic waste disappeared from the battlefield."))
      end
      @battle.scene.pbChangeField(@battle.defaultTerrain)
      @battle.eachBattler do |battler| 
        battler.pbAbilityOnTerrainChange
      end
    end
  end
end

class PokeBattle_Move_526 < PokeBattle_Move
  def pbFailsAgainstTarget?(user, target)
    if target.effects[PBEffects::SaltCure]
      @battle.pbDisplay(_INTL("{1} evaded the attack!", target.pbThis))
      return true
    end
    return false
  end

  def pbMissMessage(user, target)
    @battle.pbDisplay(_INTL("{1} evaded the attack!", target.pbThis))
    return true
  end

  def pbEffectAgainstTarget(user, target)
    target.effects[PBEffects::SaltCure] = true
    @battle.pbDisplay(_INTL("{1} is being salt cured!", target.pbThis))
  end
end

class PokeBattle_Move_527 < PokeBattle_ConfuseMove
  def recoilMove?;        return true; end
  def pbRecoilDamage(user, target); return (user.totalhp / 2);    end
  def pbCrashDamage(user)
    return if !user.takesIndirectDamage?
    @battle.pbDisplay(_INTL("{1} kept going and crashed!", user.pbThis))
    @battle.scene.pbDamageAnimation(user)
    dmg = pbRecoilDamage(user)
    user.pbReduceHP(dmg, false)
    user.pbItemHPHealCheck
    user.pbFaint if user.fainted?
  end
end

class PokeBattle_Move_528 < PokeBattle_StatDownMove
  def initialize(battle,move)
    super
    @statDown = [:SPECIAL_ATTACK,1]
  end
  def pbEffectGeneral(user)
    if user.pbOwnedByPlayer?
      @battle.field.effects[PBEffects::PayDay] += 5 * user.level
    end
    @battle.pbDisplay(_INTL("Coins were scattered everywhere!"))
  end
end

class PokeBattle_Move_529 < PokeBattle_WeatherMove
  def initialize(battle, move)
    super
    @weatherType = :Hail
  end
  def pbDisplayUseMessage(user)
    @battle.pbDisplayBrief(_INTL("{1} is preparing to tell a chillingly bad joke!", user.pbThis))
    super
  end
  def pbFailsAgainstTarget?(user, target, show_message)
    if !@battle.futureSight &&
       @battle.positions[target.index].effects[PBEffects::FutureSightCounter] > 0
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    if user.effects[PBEffects::Taunt] > 0
      @battle.pbDisplay(_INTL("{1} can't use {2} after the taunt!",user.pbThis,@name))
      return true
    end
    return false
  end
  def pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers)
    return if user.fainted?
    @weatherType = :Hail if @weatherType != :Hail
    @battle.pbDisplay(_INTL("{1} went back to {2}!", user.pbThis,
                            @battle.pbGetOwnerName(user.index)))
    @battle.pbPursuit(user.index)
    return if user.fainted?
    newPkmn = @battle.pbGetReplacementPokemonIndex(user.index)   # Owner chooses
    return if newPkmn < 0
    @battle.pbRecallAndReplace(user.index, newPkmn)
    @battle.pbClearChoice(user.index)   # Replacement Pokémon does nothing this round
    @battle.moldBreaker = false
    @peer.pbOnBattlerEnteringBattle(user.index)
    switchedBattlers.push(user.index)
  end
end

class PokeBattle_Move_530 < PokeBattle_Move
  # def ignoresSubstitute?(user); return true; end

  def pbMoveFailed?(user, targets)
    if user.unstoppableAbility?
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    if !target.ability || user.ability == target.ability
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    if target.ungainableAbility? ||
       [:POWEROFALCHEMY, :RECEIVER, :TRACE, :WONDERGUARD, :ACCLIMATE, :MULTITOOL].include?(target.ability_id)
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    return false
  end
  
  def pbEffectAgainstTarget(user, target)
    @battle.allSameSideBattlers(user).each do |b|
      @battle.pbShowAbilitySplash(b, true, false)
      oldAbil = b.ability
      b.ability = target.ability
      @battle.pbReplaceAbilitySplash(b)
      Graphics.frame_rate.times { @battle.scene.pbUpdate }
      @battle.pbHideAbilitySplash(b)
      b.pbOnLosingAbility(oldAbil)
      b.pbTriggerAbilityOnGainingIt
    end
    @battle.pbDisplay(_INTL("{1} copied {2}'s {3} Ability!",
    user.pbThis, target.pbThis(true), target.abilityName))
  end
end

class PokeBattle_Move_531 < PokeBattle_Move
  def pbMoveFailed?(user, targets)
    if !user.pbHasType?(:ELECTRIC)
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectAfterAllHits(user, target)
    if !user.effects[PBEffects::DoubleShock]
      user.effects[PBEffects::DoubleShock] = true
      @battle.pbDisplay(_INTL("{1} used up all its electricity!", user.pbThis))
    end
  end
end

class PokeBattle_Move_532 < PokeBattle_Move
  def canSnatch?; return true; end

  def pbMoveFailed?(user, targets)
    hpLoss = [user.totalhp / 2, 1].max
    if user.hp <= hpLoss
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return true if !(user.pbCanRaiseStatStage?(:ATTACK, user, self, true) &&
                     user.pbCanRaiseStatStage?(:SPECIAL_ATTACK, user, self, true) &&
                     user.pbCanRaiseStatStage?(:SPEED, user, self, true))
    return false
  end

  def pbEffectGeneral(user)
    hpLoss = [user.totalhp / 2, 1].max
    user.pbReduceHP(hpLoss, false, false)
    if user.hasActiveAbility?(:CONTRARY)
      [:ATTACK,:SPECIAL_ATTACK,:SPEED].each{|stat|
        2.times do
          user.stages[stat] -= 1 if !user.statStageAtMin?(stat)
        end
      }
      user.statsLoweredThisRound = true
      user.statsDropped = true
      @battle.pbCommonAnimation("StatDown", user)
      @battle.pbDisplay(_INTL("{1} cut its own HP and minimized its Attack, Sp. Atk, and Speed!", user.pbThis))
    else
      [:ATTACK,:SPECIAL_ATTACK,:SPEED].each{|stat|
        2.times do
          user.stages[stat] += 1 if !user.statStageAtMax?(stat)
        end
      }
      user.statsRaised = true
      @battle.pbCommonAnimation("StatUp", user)
      @battle.pbDisplay(_INTL("{1} cut its own HP and maximized its Attack, Sp. Atk, and Speed!", user.pbThis))
    end
    user.pbItemHPHealCheck
  end
end
class PokeBattle_Move_535 < PokeBattle_StatDownMove
  def initialize(battle,move)
    super
    @statDown = [:SPEED,2]
  end
end

class PokeBattle_Move_536 < PokeBattle_Move
  def canMagicCoat?; return true; end

  def initialize(battle, move)
    super
    @statDown = [:DEFENSE,1]
    @statUp = [:ATTACK,1]
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    return false if damagingMove?
    return !target.pbCanLowerStatStage?(@statDown[0], user, self, show_message) && 
           !target.pbCanRaiseStatStage?(@statUp[0], user, self, show_message) 
  end

  def pbEffectAgainstTarget(user, target)
    return if damagingMove?
    target.pbLowerStatStage(@statDown[0], @statDown[1], user)
    target.pbRaiseStatStage(@statUp[0], @statUp[1], user)
  end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    return if !target.pbCanLowerStatStage?(@statDown[0], user, self) && 
              !target.pbCanRaiseStatStage?(@statUp[0], user, self) 
    target.pbLowerStatStage(@statDown[0], @statDown[1], user)
    target.pbRaiseStatStage(@statUp[0], @statUp[1], user)
  end
end

class PokeBattle_Move_537 < PokeBattle_ProtectMove
  def initialize(battle, move)
    super
    @effect = PBEffects::SilkTrap
  end
end

class PokeBattle_Move_538 < PokeBattle_Move_10C
  def pbMoveFailed?(user, targets)
    if user.effects[PBEffects::Substitute] > 0
      @battle.pbDisplay(_INTL("{1} already has a substitute!", user.pbThis))
      return true
    end
    if !@battle.pbCanChooseNonActive?(user.index)
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    @subLife = [user.totalhp / 2, 1].max
    if user.hp <= @subLife
      @battle.pbDisplay(_INTL("But it does not have enough HP left to make a substitute!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    @battle.pbDisplay(_INTL("{1} shed its tail to create a decoy!", user.pbThis))
  end

  def pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers)
    return if user.fainted? || numHits == 0
    return if !@battle.pbCanChooseNonActive?(user.index)
    @battle.pbDisplay(_INTL("{1} went back to {2}!", user.pbThis,
                            @battle.pbGetOwnerName(user.index)))
    @battle.pbPursuit(user.index)
    return if user.fainted?
    newPkmn = @battle.pbGetReplacementPokemonIndex(user.index)   # Owner chooses
    return if newPkmn < 0
    @battle.pbRecallAndReplace(user.index, newPkmn)
    @battle.pbClearChoice(user.index)   # Replacement Pokémon does nothing this round
    @battle.moldBreaker = false
    @battle.pbOnBattlerEnteringBattle(user.index)
    switchedBattlers.push(user.index)
    user.effects[PBEffects::Trapping]     = 0
    user.effects[PBEffects::TrappingMove] = nil
    user.effects[PBEffects::Substitute]   = @subLife
    @battle.pbAnimation(GameData::Move.get(:SUBSTITUTE).id,@battle.battlers[1],@battle.battlers[1])
  end
end

class PokeBattle_Battle
  def pbRecordBattlerAsParticipated(battler)
    # Record money-doubling effect of Amulet Coin/Luck Incense
    if !battler.opposes? && [:AMULETCOIN, :LUCKINCENSE].include?(battler.item_id)
      @field.effects[PBEffects::AmuletCoin] = true
    end
    # Update battlers' participants (who will gain Exp/EVs when a battler faints)
    eachBattler { |b| b.pbUpdateParticipants }
  end

  def pbMessagesOnBattlerEnteringBattle(battler)
    # Introduce Shadow Pokémon
    if battler.shadowPokemon?
      pbCommonAnimation("Shadow", battler)
      pbDisplay(_INTL("Oh!\nA Shadow Pokémon!")) if battler.opposes?
    end
  end

  # Called when a Pokémon enters battle, and when Ally Switch is used.
  def pbEffectsOnBattlerEnteringPosition(battler)
    position = @positions[battler.index]
    # Healing Wish
    if position.effects[PBEffects::HealingWish]
      if battler.canHeal? || battler.status != :NONE
        pbCommonAnimation("HealingWish", battler)
        pbDisplay(_INTL("The healing wish came true for {1}!", battler.pbThis(true)))
        battler.pbRecoverHP(battler.totalhp)
        battler.pbCureStatus(false)
        position.effects[PBEffects::HealingWish] = false
      elsif Settings::MECHANICS_GENERATION < 8
        position.effects[PBEffects::HealingWish] = false
      end
    end
    # Lunar Dance
    if position.effects[PBEffects::LunarDance]
      full_pp = true
      battler.eachMove { |m| full_pp = false if m.pp < m.total_pp }
      if battler.canHeal? || battler.status != :NONE || !full_pp
        pbCommonAnimation("LunarDance", battler)
        pbDisplay(_INTL("{1} became cloaked in mystical moonlight!", battler.pbThis))
        battler.pbRecoverHP(battler.totalhp)
        battler.pbCureStatus(false)
        battler.eachMove { |m| battler.pbSetPP(m, m.total_pp) }
        position.effects[PBEffects::LunarDance] = false
      elsif Settings::MECHANICS_GENERATION < 8
        position.effects[PBEffects::LunarDance] = false
      end
    end
  end

  def pbEntryHazards(battler)
    battler_side = battler.pbOwnSide
    # Stealth Rock
    if battler_side.effects[PBEffects::StealthRock] && battler.takesIndirectDamage? &&
       GameData::Type.exists?(:ROCK) && !battler.hasActiveItem?(:HEAVYDUTYBOOTS) && !battler.hasActiveAbility?([:SCALER,:MOLTENFURY])
      bTypes = battler.pbTypes(true)
      eff = Effectiveness.calculate(:ROCK, bTypes[0], bTypes[1], bTypes[2])
      if !Effectiveness.ineffective?(eff)
        eff = eff.to_f / Effectiveness::NORMAL_EFFECTIVE
        battler.pbReduceHP(battler.totalhp * eff / 8, false)
        pbDisplay(_INTL("Pointed stones dug into {1}!", battler.pbThis))
        battler.pbItemHPHealCheck
      end
    end
    # Spikes
    if battler_side.effects[PBEffects::Spikes] > 0 && battler.takesIndirectDamage? &&
       !battler.airborne? && !battler.hasActiveItem?(:HEAVYDUTYBOOTS)
      spikesDiv = [8, 6, 4][battler_side.effects[PBEffects::Spikes] - 1]
      battler.pbReduceHP(battler.totalhp / spikesDiv, false)
      pbDisplay(_INTL("{1} is hurt by the spikes!", battler.pbThis))
      battler.pbItemHPHealCheck
    end
    # Toxic Spikes
    if battler_side.effects[PBEffects::ToxicSpikes] > 0 && !battler.fainted? && !battler.airborne?
      if battler.pbHasType?(:POISON)
        battler_side.effects[PBEffects::ToxicSpikes] = 0
        pbDisplay(_INTL("{1} absorbed the poison spikes!", battler.pbThis))
      elsif battler.pbCanPoison?(nil, false) && !battler.hasActiveItem?(:HEAVYDUTYBOOTS)
        if battler_side.effects[PBEffects::ToxicSpikes] == 2
          battler.pbPoison(nil, _INTL("{1} was badly poisoned by the poison spikes!", battler.pbThis), true)
        else
          battler.pbPoison(nil, _INTL("{1} was poisoned by the poison spikes!", battler.pbThis))
        end
      end
    end
    # Sticky Web
    if battler_side.effects[PBEffects::StickyWeb] && !battler.fainted? && !battler.airborne? &&
       !battler.hasActiveItem?(:HEAVYDUTYBOOTS)
      pbDisplay(_INTL("{1} was caught in a sticky web!", battler.pbThis))
      if battler.pbCanLowerStatStage?(:SPEED)
        battler.pbLowerStatStage(:SPEED, 1, nil)
        battler.pbItemStatRestoreCheck
      end
    end
  end
  def pbOnBattlerEnteringBattle(battler_index, skip_event_reset = false)
    battler_index = [battler_index] if !battler_index.is_a?(Array)
    battler_index.flatten!
    # NOTE: This isn't done for switch commands, because they previously call
    #       pbRecallAndReplace, which could cause Neutralizing Gas to end, which
    #       in turn could cause Intimidate to trigger another Pokémon's Eject
    #       Pack. That Eject Pack should trigger at the end of this method, but
    #       this resetting would prevent that from happening, so it is skipped
    #       and instead done earlier in def pbAttackPhaseSwitch.
    if !skip_event_reset
      eachBattler do |b|
        b.droppedBelowHalfHP = false
        b.statsLowered = false
      end
    end
    # For each battler that entered battle, in speed order
    pbPriority(true).each do |b|
      next if !battler_index.include?(b.index) || b.fainted?
      pbRecordBattlerAsParticipated(b)
      pbMessagesOnBattlerEnteringBattle(b)
      # Position/field effects triggered by the battler appearing
      pbEffectsOnBattlerEnteringPosition(b)   # Healing Wish/Lunar Dance
      pbEntryHazards(b)
      # Battler faints if it is knocked out because of an entry hazard above
      if b.fainted?
        b.pbFaint
        pbGainExp
        pbJudge
        next
      end
      b.pbCheckForm
      # Primal Revert upon entering battle
      pbPrimalReversion(b.index)
      # Ending primordial weather, checking Trace
      b.pbContinualAbilityChecks(true)
      # Abilities that trigger upon switching in
      if (!b.fainted? && b.unstoppableAbility?) || b.abilityActive?
        BattleHandlers.triggerAbilityOnSwitchIn(b.ability, b, self)
      end
      pbEndPrimordialWeather   # Checking this again just in case
      # Items that trigger upon switching in (Air Balloon message)
      if b.itemActive?
        BattleHandlers.triggerItemOnSwitchIn(b.item, b, self)
      end
      # Berry check, status-curing ability check
      b.pbHeldItemTriggerCheck
      b.pbAbilityStatusCureCheck
    end
    # Check for triggering of Emergency Exit/Wimp Out/Eject Pack (only one will
    # be triggered)
    pbPriority(true).each do |b|
      break if b.pbItemOnStatDropped
      break if b.pbAbilitiesOnDamageTaken
    end
    eachBattler do |b|
      b.droppedBelowHalfHP = false
      b.statsLowered = false
    end
  end
end

class PokeBattle_Move_539 < PokeBattle_Move
  def pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers)
    return if user.fainted?
    user.effects[PBEffects::GlaiveRush] = 2
  end
end

class PokeBattle_Move_540 < PokeBattle_Move
  def pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers)
    return if user.fainted?
    user.effects[PBEffects::DisableMove] = user.lastRegularMoveUsed
    $gigaton = true
    user.effects[PBEffects::Disable] = 2
  end
end

class PokeBattle_Move_541 < PokeBattle_Move
  def pbBaseDamage(baseDmg, user, target)
    # user.battle.pbParty(user.idxOwnSide).each { |b| numFainted += 1 if b.fainted? }
    # numFainted -= $game_temp.fainted_member[user.idxOwnSide]
    numFainted = @battle.getFaintedCount(user)
    return baseDmg if numFainted <= 0
    baseDmg += baseDmg * numFainted
    return baseDmg
  end
end

class PokeBattle_Move_542 < PokeBattle_Move
  def multiHitMove?;            return true; end
  def pbNumHits(user, targets)
    number = 10
    number = 10 - rand(7) if user.hasActiveItem?(:LOADEDDICE)
    return number
  end

  def successCheckPerHit?
    return @accCheckPerHit
  end

  def pbOnStartUse(user, targets)
    @accCheckPerHit = !user.hasActiveAbility?(:SKILLLINK) && !user.hasActiveItem?(:LOADEDDICE)
  end
end

class PokeBattle_Move_543 < PokeBattle_Move
  def pbEffectGeneral(user)
    if user.effects[PBEffects::CommanderDondozo] >= 0
      stat = [:ATTACK,:DEFENSE,:SPEED][user.effects[PBEffects::CommanderDondozo]]
      user.pbRaiseStatStage(stat, 1, user, true) if user.pbCanRaiseStatStage?(stat, user, self)
    end
  end
end

class PokeBattle_Move_544 < PokeBattle_Move_10A
  def pbBaseType(user)
    userTypes = user.pbTypes(true)
    return userTypes[1]
  end
end

class PokeBattle_Move_506 < PokeBattle_HealingMove
  def pbHealAmount(user)
    return (user.totalhp*2/3.0).round if user.effects[PBEffects::Charge] > 0
    return (user.totalhp*2/3.0).round if [:Digital,:Electric].include?(@battle.field.field_effects)
    return (user.totalhp/2.0).round
  end
end

class PokeBattle_Move_507 < PokeBattle_Move
  def pbEffectAgainstTarget(user,target)
    target.effects[PBEffects::StarSap] = user.index
    @battle.pbDisplay(_INTL("{1} was sapped!",target.pbThis))
  end
end

class PokeBattle_Move_511 < PokeBattle_StatUpMove
  def initialize(battle,move)
    super
    @statUp = [:ATTACK,3]
  end
end

class PokeBattle_Move_512 < PokeBattle_Move
  def canSetRocks?(user)
    return false if user.pbOpposingSide.effects[PBEffects::StealthRock]
    return false if user.pbOpposingSide.effects[PBEffects::CometShards]
    return false if user.pbOwnedByPlayer? && $game_switches[LvlCap::Expert]
    return false if @battle.pbWeather == :Windy
    return false if @battle.field.field_effects == :WindTunnel
    return true
  end
  def pbEffectGeneral(user)
    if canSetRocks?(user)
      @battle.scene.pbAnimation(GameData::Move.get(:STEALTHROCK).id,user,user)
      user.pbOpposingSide.effects[PBEffects::StealthRock] = true
      @battle.pbDisplay(_INTL("Pointed stones float in the air around {1}!",user.pbOpposingTeam(true)))
    end
  end
end

class PokeBattle_Move_522 < PokeBattle_Move
  def canSetSpikes?(user)
    return false if user.pbOpposingSide.effects[PBEffects::Spikes] >= 3
    return false if user.pbOwnedByPlayer? && $game_switches[LvlCap::Expert]
    return false if @battle.pbWeather == :Windy
    return false if @battle.field.field_effects == :WindTunnel
    return true
  end
  def pbEffectGeneral(user)
    if canSetSpikes?(user)
      @battle.scene.pbAnimation(GameData::Move.get(:SPIKES).id,user,user)
      user.pbOpposingSide.effects[PBEffects::Spikes] += 1
      @battle.pbDisplay(_INTL("Spikes around {1}'s feet!",user.pbOpposingTeam(true)))
    end
  end
end

class PokeBattle_Move_513 < PokeBattle_StatUpMove
  def initialize(battle,move)
    super
    @statUp = [:SPEED,1]
  end

  def pbRecoilDamage(user,target)
    return (target.damageState.totalHPLost/3.0).round
  end
end

class PokeBattle_Move_514 < PokeBattle_Move
  def pbAdditionalEffect(user,target)
    return if target.damageState.substitute
    case @battle.pbRandom(3)
    when 0 then target.pbPoison(user) if target.pbCanPoison?(user, false, self)
    when 1 then target.pbSleep if target.pbCanSleep?(user, false, self)
    when 2 then target.pbParalyze(user) if target.pbCanParalyze?(user, false, self)
    end
  end
end

class PokeBattle_Move_515 < PokeBattle_PoisonMove
  def pbBaseDamage(baseDmg,user,target)
    if target.pbHasAnyStatus? &&
       (target.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(user))
      baseDmg *= 2
    end
    return baseDmg
  end
end

class PokeBattle_Move_519 < PokeBattle_BurnMove
  def pbBaseDamage(baseDmg,user,target)
    if target.pbHasAnyStatus? &&
       (target.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(user))
      baseDmg *= 2
    end
    return baseDmg
  end
end

class PokeBattle_Move_517 < PokeBattle_FreezeMove
  def pbBaseDamage(baseDmg,user,target)
    if target.pbHasAnyStatus? &&
       (target.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(user))
      baseDmg *= 2
    end
    return baseDmg
  end
end

class PokeBattle_Move_518 < PokeBattle_MultiStatUpMove
  def initialize(battle,move)
    super
    @statUp = [:ATTACK,1,:DEFENSE,1,:SPEED,1]
  end
end

class PokeBattle_Move_0D8 < PokeBattle_HealingMove
  def pbOnStartUse(user,targets)
    case @battle.pbWeather
    when :Sun, :HarshSun
      if !user.hasUtilityUmbrella
        @healAmount = @type == :FAIRY ? (user.totalhp/2.0).round : (user.totalhp*2/3.0).round
      else
        @healAmount = @type == :FAIRY ? (user.totalhp/4.0).round : (user.totalhp/2.0).round
      end
    when :Rain, :HeavyRain
      if !user.hasUtilityUmbrella?
        @healAmount = (user.totalhp/4.0).round
      else
        @healAmount = (user.totalhp/2.0).round
      end
    when :Starstorm, :Eclipse
      if @type == :FAIRY
        @healAmount = (user.totalhp*2/3.0).round
      else
        @healAmount = (user.totalhp/4.0).round
      end
    when :None, :StrongWinds
      @healAmount = (user.totalhp/2.0).round
    else
      @healAmount = (user.totalhp/4.0).round
    end
    if @battle.field.field_effects == :Space && @type == :FAIRY
      @healAmount = (user.totalhp*2/3)
    end
    if @battle.field.field_effects == :FairyLights && @type != :FAIRY
      @healAmount = (user.totalhp*2/3)
    end
  end

  def pbHealAmount(user)
    return @healAmount
  end
end

class PokeBattle_Move
  def pbRecordDamageLost(user,target)
    damage = target.damageState.hpLost
    # NOTE: In Gen 3 where a move's category depends on its type, Hidden Power
    #       is for some reason countered by Counter rather than Mirror Coat,
    #       regardless of its calculated type. Hence the following two lines of
    #       code.
    moveType = nil
    moveType = :NORMAL if @function=="090"   # Hidden Power
    if physicalMove?(moveType)
      target.effects[PBEffects::Counter]       = damage
      target.effects[PBEffects::CounterTarget] = user.index
    elsif specialMove?(moveType)
      target.effects[PBEffects::MirrorCoat]       = damage
      target.effects[PBEffects::MirrorCoatTarget] = user.index
    end
    if target.effects[PBEffects::Bide]>0
      target.effects[PBEffects::BideDamage] += damage
      target.effects[PBEffects::BideTarget] = user.index
    end
    if target.fainted?
      target.damageState.fainted = true
    end
    target.lastHPLost = damage             # For Focus Punch
    target.tookDamage = true if damage>0   # For Assurance
    target.lastAttacker.push(user.index)   # For Revenge
    if target.opposes?(user)
      target.lastHPLostFromFoe = damage              # For Metal Burst
      target.lastFoeAttacker.push(user.index)        # For Metal Burst
    end
  end
end

class PokeBattle_Battle
  def pbStartWeather(user,newWeather,fixedDuration=false,showAnim=true)
    return if @field.weather==newWeather
    if $gym_weather == true && @field.weather != newWeather
      pbDisplay(_INTL("The weather could not be changed!"))
      pbHideAbilitySplash(user) if user
      return
    end
    fixedDuration = false if $game_switches[LvlCap::Expert]
    @field.weather = newWeather
    duration = (fixedDuration) ? 5 : -1
    if duration>0 && user && user.itemActive?
      duration = BattleHandlers.triggerWeatherExtenderItem(user.item,
         @field.weather,duration,user,self)
    end
    @field.weatherDuration = duration
    weather_data = GameData::BattleWeather.try_get(@field.weather)
    pbCommonAnimation(weather_data.animation) if showAnim && weather_data
    pbHideAbilitySplash(user) if user
    case @field.weather
    when :Sun         then pbDisplay(_INTL("The sunlight turned harsh!"))
    when :Rain        then pbDisplay(_INTL("It started to rain!"))
    when :Sandstorm   then pbDisplay(_INTL("A sandstorm brewed!"))
    when :Hail        then pbDisplay(_INTL("It started to hail!"))
    when :HarshSun    then pbDisplay(_INTL("The sunlight turned extremely harsh!"))
    when :HeavyRain   then pbDisplay(_INTL("A heavy rain began to fall!"))
    when :StrongWinds then pbDisplay(_INTL("Mysterious strong winds are protecting Flying-type Pokémon!"))
    when :ShadowSky   then pbDisplay(_INTL("A shadow sky appeared!"))
    when :Starstorm   then pbDisplay(_INTL("Stars fill the sky."))
    when :Thunder     then pbDisplay(_INTL("Lightning flashes in th sky."))
    when :Storm       then pbDisplay(_INTL("A thunderstorm rages. The ground became electrified!"))
    when :Humid       then pbDisplay(_INTL("The air is humid."))
    #when :Overcast    then pbDisplay(_INTL("The sky is overcast."))
    when :Eclipse     then pbDisplay(_INTL("The sky is dark."))
    when :Fog         then pbDisplay(_INTL("The fog is deep."))
    when :AcidRain    then pbDisplay(_INTL("Acid rain is falling."))
    when :VolcanicAsh then pbDisplay(_INTL("Volcanic Ash sprinkles down."))
    when :Rainbow     then pbDisplay(_INTL("A rainbow crosses the sky."))
    when :Borealis    then pbDisplay(_INTL("The sky is ablaze with color."))
    when :TimeWarp    then pbDisplay(_INTL("Time has stopped."))
    when :Reverb      then pbDisplay(_INTL("A dull echo hums."))
    when :DClear      then pbDisplay(_INTL("The sky is distorted."))
    when :DRain       then pbDisplay(_INTL("Rain is falling upward."))
    when :DWind       then pbDisplay(_INTL("The wind is haunting."))
    when :DAshfall    then pbDisplay(_INTL("Ash floats in midair."))
    when :Sleet       then pbDisplay(_INTL("Sleet began to fall."))
    when :Windy       then pbDisplay(_INTL("There is a slight breeze."))
    when :HeatLight   then pbDisplay(_INTL("Static fills the air."))
    when :DustDevil   then pbDisplay(_INTL("A dust devil approaches."))
    end
    #case @field.field_effects
    #add changes to fields when weather changes here
    #end
    # Check for end of primordial weather, and weather-triggered form changes
    eachBattler { |b| b.pbCheckFormOnWeatherChange }
    pbEndPrimordialWeather if $gym_weather == false
  end

  def pbStartTerrain(user,newTerrain,fixedDuration=true)
    return if @field.terrain==newTerrain
    @field.terrain = newTerrain
    fixedDuration = false if $game_switches[LvlCap::Expert]
    duration = (fixedDuration) ? 5 : -1
    if duration>0 && user && user.itemActive?
      duration = BattleHandlers.triggerTerrainExtenderItem(user.item,
         newTerrain,duration,user,self)
    end
    @field.terrainDuration = duration
    terrain_data = GameData::BattleTerrain.try_get(@field.terrain)
    pbCommonAnimation(terrain_data.animation) if terrain_data
    pbHideAbilitySplash(user) if user
    case @field.terrain
    when :Electric
      pbDisplay(_INTL("An electric current runs across the battlefield!"))
    when :Grassy
      pbDisplay(_INTL("Grass grew to cover the battlefield!"))
    when :Misty
      pbDisplay(_INTL("Mist swirled about the battlefield!"))
    when :Psychic
      pbDisplay(_INTL("The battlefield got weird!"))
    when :Poison
      pbDisplay(_INTL("Toxic waste covered the battlefield!"))
    end
    @scene.pbChangeField(newTerrain)
    # Check for terrain seeds that boost stats in a terrain
    eachBattler { |b|
    b.pbCheckFormOnTerrainChange
    b.pbItemTerrainStatBoostCheck
  }
  end

  def pbEORTerrain
    return unless [:Electric,:Grassy,:Psychic,:Misty,:Poison].include?(@field.terrain)
    return if @field.terrain == @field.defaultTerrain
    # Count down terrain duration
    @field.terrainDuration -= 1 if @field.terrainDuration>0 && !$game_switches[LvlCap::Expert]
    # Terrain wears off
    if @field.terrain != :None && @field.terrainDuration == 0
      case @field.terrain
      when :Electric
        pbDisplay(_INTL("The electric current disappeared from the battlefield!"))
      when :Grassy
        pbDisplay(_INTL("The grass disappeared from the battlefield!"))
      when :Misty
        pbDisplay(_INTL("The mist disappeared from the battlefield!"))
      when :Psychic
        pbDisplay(_INTL("The weirdness disappeared from the battlefield!"))
      when :Poison
        pbDisplay(_INTL("The toxic waste disappeared from the battlefield!"))
      end
      $terrain = 0
      # Start up the default terrain
      field = @field.defaultTerrain !=:None ? @field.defaultTerrain : :None
      pbStartTerrain(nil, field)
      return if @field.terrain == field
    end
  end

  def pbEndOfRoundPhase
    PBDebug.log("")
    PBDebug.log("[End of round]")
    @endOfRound = true
    @scene.pbBeginEndOfRoundPhase
    pbCalculatePriority           # recalculate speeds
    priority = pbPriority(true)   # in order of fastest -> slowest speeds only
    # Weather
    pbEORWeather(priority)
    # Future Sight/Doom Desire
    @positions.each_with_index do |pos,idxPos|
      next if !pos || pos.effects[PBEffects::FutureSightCounter]==0
      pos.effects[PBEffects::FutureSightCounter] -= 1
      next if pos.effects[PBEffects::FutureSightCounter]>0
      next if !@battlers[idxPos] || @battlers[idxPos].fainted?   # No target
      moveUser = nil
      eachBattler do |b|
        next if b.opposes?(pos.effects[PBEffects::FutureSightUserIndex])
        next if b.pokemonIndex!=pos.effects[PBEffects::FutureSightUserPartyIndex]
        moveUser = b
        break
      end
      next if moveUser && moveUser.index==idxPos   # Target is the user
      if !moveUser   # User isn't in battle, get it from the party
        party = pbParty(pos.effects[PBEffects::FutureSightUserIndex])
        pkmn = party[pos.effects[PBEffects::FutureSightUserPartyIndex]]
        if pkmn && pkmn.able?
          moveUser = PokeBattle_Battler.new(self,pos.effects[PBEffects::FutureSightUserIndex])
          moveUser.pbInitDummyPokemon(pkmn,pos.effects[PBEffects::FutureSightUserPartyIndex])
        end
      end
      next if !moveUser   # User is fainted
      move = pos.effects[PBEffects::FutureSightMove]
      pbDisplay(_INTL("{1} took the {2} attack!",@battlers[idxPos].pbThis,
         GameData::Move.get(move).name))
      # NOTE: Future Sight failing against the target here doesn't count towards
      #       Stomping Tantrum.
      userLastMoveFailed = moveUser.lastMoveFailed
      @futureSight = true
      moveUser.pbUseMoveSimple(move,idxPos)
      @futureSight = false
      moveUser.lastMoveFailed = userLastMoveFailed
      @battlers[idxPos].pbFaint if @battlers[idxPos].fainted?
      pos.effects[PBEffects::FutureSightCounter]        = 0
      pos.effects[PBEffects::FutureSightMove]           = nil
      pos.effects[PBEffects::FutureSightUserIndex]      = -1
      pos.effects[PBEffects::FutureSightUserPartyIndex] = -1
    end
    # Wish
    @positions.each_with_index do |pos,idxPos|
      next if !pos || pos.effects[PBEffects::Wish]==0
      pos.effects[PBEffects::Wish] -= 1
      next if pos.effects[PBEffects::Wish]>0
      next if !@battlers[idxPos] || !@battlers[idxPos].canHeal?
      wishMaker = pbThisEx(idxPos,pos.effects[PBEffects::WishMaker])
      @battlers[idxPos].pbRecoverHP(pos.effects[PBEffects::WishAmount])
      pbDisplay(_INTL("{1}'s wish came true!",wishMaker))
    end
    # Sea of Fire damage (Fire Pledge + Grass Pledge combination)
    curWeather = pbWeather
    for side in 0...2
      next if sides[side].effects[PBEffects::SeaOfFire]==0
      next if [:Rain, :HeavyRain].include?(curWeather)
      @battle.pbCommonAnimation("SeaOfFire") if side==0
      @battle.pbCommonAnimation("SeaOfFireOpp") if side==1
      priority.each do |b|
        next if b.opposes?(side)
        next if !b.takesIndirectDamage? || b.pbHasType?(:FIRE)
        oldHP = b.hp
        @scene.pbDamageAnimation(b)
        b.pbReduceHP(b.totalhp/8,false)
        pbDisplay(_INTL("{1} is hurt by the sea of fire!",b.pbThis))
        b.pbItemHPHealCheck
        b.pbAbilitiesOnDamageTaken(oldHP)
        b.pbFaint if b.fainted?
      end
    end
    # Status-curing effects/abilities and HP-healing items
    priority.each do |b|
      next if b.fainted?
      # Grassy Terrain (healing)
      pbEORField(b)
      # Healer, Hydration, Shed Skin
      BattleHandlers.triggerEORHealingAbility(b.ability,b,self) if b.abilityActive?
      # Black Sludge, Leftovers
      BattleHandlers.triggerEORHealingItem(b.item,b,self) if b.itemActive?
    end
    # Aqua Ring
    priority.each do |b|
      next if !b.effects[PBEffects::AquaRing]
      next if !b.canHeal?
      hpGain = b.totalhp/16
      hpGain = (hpGain*1.3).floor if b.hasActiveItem?(:BIGROOT)
      b.pbRecoverHP(hpGain)
      pbDisplay(_INTL("Aqua Ring restored {1}'s HP!",b.pbThis(true)))
    end
    # Ingrain
    priority.each do |b|
      next if !b.effects[PBEffects::Ingrain]
      next if !b.canHeal?
      hpGain = b.totalhp/16
      hpGain = (hpGain*1.3).floor if b.hasActiveItem?(:BIGROOT)
      b.pbRecoverHP(hpGain)
      pbDisplay(_INTL("{1} absorbed nutrients with its roots!",b.pbThis))
    end
    # Leech Seed
    priority.each do |b|
      next if b.effects[PBEffects::LeechSeed]<0
      next if !b.takesIndirectDamage?
      recipient = @battlers[b.effects[PBEffects::LeechSeed]]
      next if !recipient || recipient.fainted?
      oldHP = b.hp
      oldHPRecipient = recipient.hp
      pbCommonAnimation("LeechSeed",recipient,b)
      hpLoss = b.pbReduceHP(b.totalhp/8)
      recipient.pbRecoverHPFromDrain(hpLoss,b,
         _INTL("{1}'s health is sapped by Leech Seed!",b.pbThis))
      recipient.pbAbilitiesOnDamageTaken(oldHPRecipient) if recipient.hp<oldHPRecipient
      b.pbItemHPHealCheck
      b.pbAbilitiesOnDamageTaken(oldHP)
      b.pbFaint if b.fainted?
      recipient.pbFaint if recipient.fainted?
    end
    # Star Sap
    priority.each do |b|
      next if b.effects[PBEffects::StarSap]<0
      next if !b.takesIndirectDamage?
      recipient = @battlers[b.effects[PBEffects::StarSap]]
      next if !recipient || recipient.fainted?
      oldHP = b.hp
      oldHPRecipient = recipient.hp
      pbCommonAnimation("LeechSeed",recipient,b)
      hpLoss = b.pbReduceHP(b.totalhp/8)
      recipient.pbRecoverHPFromDrain(hpLoss,b,
         _INTL("{1}'s health is sapped by Star Sap!",b.pbThis))
      recipient.pbAbilitiesOnDamageTaken(oldHPRecipient) if recipient.hp<oldHPRecipient
      b.pbItemHPHealCheck
      b.pbAbilitiesOnDamageTaken(oldHP)
      b.pbFaint if b.fainted?
      recipient.pbFaint if recipient.fainted?
    end
    # Damage from Hyper Mode (Shadow Pokémon)
    priority.each do |b|
      next if !b.inHyperMode? || @choices[b.index][0]!=:UseMove
      hpLoss = b.totalhp/24
      @scene.pbDamageAnimation(b)
      b.pbReduceHP(hpLoss,false)
      pbDisplay(_INTL("The Hyper Mode attack hurts {1}!",b.pbThis(true)))
      b.pbFaint if b.fainted?
    end
    # Damage from poisoning
    priority.each do |b|
      next if b.fainted?
      next if b.status != :POISON
      if b.statusCount>0
        b.effects[PBEffects::Toxic] += 1
        b.effects[PBEffects::Toxic] = 15 if b.effects[PBEffects::Toxic]>15
      end
      if b.hasActiveAbility?(:POISONHEAL)
        if b.canHeal?
          anim_name = GameData::Status.get(:POISON).animation
          pbCommonAnimation(anim_name, b) if anim_name
          pbShowAbilitySplash(b)
          b.pbRecoverHP(b.totalhp/8)
          if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
            pbDisplay(_INTL("{1}'s HP was restored.",b.pbThis))
          else
            pbDisplay(_INTL("{1}'s {2} restored its HP.",b.pbThis,b.abilityName))
          end
          pbHideAbilitySplash(b)
        end
      elsif b.takesIndirectDamage?
        oldHP = b.hp
        dmg = (b.statusCount==0) ? b.totalhp/8 : b.totalhp*b.effects[PBEffects::Toxic]/16
        b.pbContinueStatus { b.pbReduceHP(dmg,false) }
        b.pbItemHPHealCheck
        b.pbAbilitiesOnDamageTaken(oldHP)
        b.pbFaint if b.fainted?
      end
    end
    priority.each do |b|
      next if b.fainted?
      next if b.effects[PBEffects::Cinders] < 0
      if b.effects[PBEffects::Cinders] > 0
        b.pbReduceHP(b.totalhp/16,false)
        pbDisplay(_INTL("{1} was hurt by the cinders!",b.pbThis))
      else
        pbDisplay(_INTL("{1} cleared away the cinders!",b.pbThis))
      end
    end
    # Damage from burn
    priority.each do |b|
      next if b.status != :BURN || !b.takesIndirectDamage?
      oldHP = b.hp
      dmg = (Settings::MECHANICS_GENERATION >= 7) ? b.totalhp/16 : b.totalhp/8
      dmg = (dmg/2.0).round if b.hasActiveAbility?(:HEATPROOF)
      b.pbContinueStatus { b.pbReduceHP(dmg,false) }
      b.pbItemHPHealCheck
      b.pbAbilitiesOnDamageTaken(oldHP)
      b.pbFaint if b.fainted?
    end
    #Damage from Frostbite
    priority.each do |b|
      next if b.status != :FROZEN || !b.takesIndirectDamage?
      oldHP = b.hp
      dmg = (Settings::MECHANICS_GENERATION >= 7) ? b.totalhp/16 : b.totalhp/8
      b.pbContinueStatus { b.pbReduceHP(dmg,false) }
      b.pbItemHPHealCheck
      b.pbAbilitiesOnDamageTaken(oldHP)
      b.pbFaint if b.fainted?
    end
    # Damage from sleep (Nightmare)
    priority.each do |b|
      b.effects[PBEffects::Nightmare] = false if !b.asleep?
      next if !b.effects[PBEffects::Nightmare] || !b.takesIndirectDamage?
      oldHP = b.hp
      b.pbReduceHP(b.totalhp/4)
      pbDisplay(_INTL("{1} is locked in a nightmare!",b.pbThis))
      b.pbItemHPHealCheck
      b.pbAbilitiesOnDamageTaken(oldHP)
      b.pbFaint if b.fainted?
    end
    # Curse
    priority.each do |b|
      next if !b.effects[PBEffects::Curse] || !b.takesIndirectDamage?
      oldHP = b.hp
      b.pbReduceHP(b.totalhp/4)
      pbDisplay(_INTL("{1} is afflicted by the curse!",b.pbThis))
      b.pbItemHPHealCheck
      b.pbAbilitiesOnDamageTaken(oldHP)
      b.pbFaint if b.fainted?
    end
    # Octolock
    priority.each do |b|
      next if b.fainted? || b.effects[PBEffects::Octolock] != 0 || b.effects[PBEffects::Octolock] != 1
      pbCommonAnimation("Octolock", b)
      b.pbLowerStatStage(:DEFENSE, 1, nil) if b.pbCanLowerStatStage?(:DEFENSE)
      b.pbLowerStatStage(:SPECIAL_DEFENSE, 1, nil, false) if b.pbCanLowerStatStage?(:SPECIAL_DEFENSE)
    end
    # Trapping attacks (Bind/Clamp/Fire Spin/Magma Storm/Sand Tomb/Whirlpool/Wrap)
    priority.each do |b|
      next if b.fainted? || b.effects[PBEffects::Trapping]==0
      b.effects[PBEffects::Trapping] -= 1
      moveName = GameData::Move.get(b.effects[PBEffects::TrappingMove]).name
      if b.effects[PBEffects::Trapping]==0
        pbDisplay(_INTL("{1} was freed from {2}!",b.pbThis,moveName))
      else
        case b.effects[PBEffects::TrappingMove]
        when :BIND        then pbCommonAnimation("Bind", b)
        when :CLAMP       then pbCommonAnimation("Clamp", b)
        when :FIRESPIN    then pbCommonAnimation("FireSpin", b)
        when :MAGMASTORM  then pbCommonAnimation("MagmaStorm", b)
        when :SANDTOMB    then pbCommonAnimation("SandTomb", b)
        when :WRAP        then pbCommonAnimation("Wrap", b)
        when :INFESTATION then pbCommonAnimation("Infestation", b)
        else                   pbCommonAnimation("Wrap", b)
        end
        if b.takesIndirectDamage?
          hpLoss = (Settings::MECHANICS_GENERATION >= 6) ? b.totalhp/8 : b.totalhp/16
          if @battlers[b.effects[PBEffects::TrappingUser]].hasActiveItem?(:BINDINGBAND)
            hpLoss = (Settings::MECHANICS_GENERATION >= 6) ? b.totalhp/6 : b.totalhp/8
          end
          @scene.pbDamageAnimation(b)
          b.pbReduceHP(hpLoss,false)
          pbDisplay(_INTL("{1} is hurt by {2}!",b.pbThis,moveName))
          b.pbItemHPHealCheck
          # NOTE: No need to call pbAbilitiesOnDamageTaken as b can't switch out.
          b.pbFaint if b.fainted?
        end
      end
    end
    priority.each do |battler|
      next if !battler.effects[PBEffects::SaltCure] || !battler.takesIndirectDamage?
      battler.droppedBelowHalfHP = false
      dmg = battler.totalhp / 8
      dmg = (dmg * 2).round if battler.pbHasType?(:STEEL) || battler.pbHasType?(:WATER)
      pbCommonAnimation("SaltCure", battler)
      battler.pbReduceHP(dmg, false)
      pbDisplay(_INTL("{1} is hurt by Salt Cure!", battler.pbThis))
      battler.pbItemHPHealCheck
      battler.pbAbilitiesOnDamageTaken
      battler.pbFaint if battler.fainted?
      battler.droppedBelowHalfHP = false
    end
    # Taunt
    pbEORCountDownBattlerEffect(priority,PBEffects::Taunt) { |battler|
      pbDisplay(_INTL("{1}'s taunt wore off!",battler.pbThis))
    }
    # Encore
    priority.each do |b|
      next if b.fainted? || b.effects[PBEffects::Encore]==0
      idxEncoreMove = b.pbEncoredMoveIndex
      if idxEncoreMove>=0
        b.effects[PBEffects::Encore] -= 1
        if b.effects[PBEffects::Encore]==0 || b.moves[idxEncoreMove].pp==0
          b.effects[PBEffects::Encore] = 0
          pbDisplay(_INTL("{1}'s encore ended!",b.pbThis))
        end
      else
        PBDebug.log("[End of effect] #{b.pbThis}'s encore ended (encored move no longer known)")
        b.effects[PBEffects::Encore]     = 0
        b.effects[PBEffects::EncoreMove] = nil
      end
    end
    # Disable/Cursed Body
    pbEORCountDownBattlerEffect(priority,PBEffects::Disable) { |battler|
      battler.effects[PBEffects::DisableMove] = nil
      $gigaton = false
      pbDisplay(_INTL("{1} is no longer disabled!",battler.pbThis)) if $gigaton == true
    }
    # Magnet Rise
    if @field.field_effects != :Magnetic
      pbEORCountDownBattlerEffect(priority,PBEffects::MagnetRise) { |battler|
        pbDisplay(_INTL("{1}'s electromagnetism wore off!",battler.pbThis))
      }
    end
    # Telekinesis
    pbEORCountDownBattlerEffect(priority,PBEffects::Telekinesis) { |battler|
      pbDisplay(_INTL("{1} was freed from the telekinesis!",battler.pbThis))
    }
    # Heal Block
    pbEORCountDownBattlerEffect(priority,PBEffects::HealBlock) { |battler|
      pbDisplay(_INTL("{1}'s Heal Block wore off!",battler.pbThis))
    }
    # Embargo
    pbEORCountDownBattlerEffect(priority,PBEffects::Embargo) { |battler|
      pbDisplay(_INTL("{1} can use items again!",battler.pbThis))
      battler.pbItemTerrainStatBoostCheck
    }
    # Yawn
    pbEORCountDownBattlerEffect(priority,PBEffects::Yawn) { |battler|
      if battler.pbCanSleepYawn?
        PBDebug.log("[Lingering effect] #{battler.pbThis} fell asleep because of Yawn")
        battler.pbSleep
      end
    }
    # Perish Song
    perishSongUsers = []
    priority.each do |b|
      next if b.fainted? || b.effects[PBEffects::PerishSong]==0
      b.effects[PBEffects::PerishSong] -= 1
      pbDisplay(_INTL("{1}'s perish count fell to {2}!",b.pbThis,b.effects[PBEffects::PerishSong]))
      if b.effects[PBEffects::PerishSong]==0
        perishSongUsers.push(b.effects[PBEffects::PerishSongUser])
        b.pbReduceHP(b.hp)
      end
      b.pbItemHPHealCheck
      b.pbFaint if b.fainted?
    end
    if perishSongUsers.length>0
      # If all remaining Pokemon fainted by a Perish Song triggered by a single side
      if (perishSongUsers.find_all { |idxBattler| opposes?(idxBattler) }.length==perishSongUsers.length) ||
         (perishSongUsers.find_all { |idxBattler| !opposes?(idxBattler) }.length==perishSongUsers.length)
        pbJudgeCheckpoint(@battlers[perishSongUsers[0]])
      end
    end
    if @decision>0
      pbGainExp
      return
    end
    for side in 0...2
      # Reflect
      pbEORCountDownSideEffect(side,PBEffects::Reflect,
         _INTL("{1}'s Reflect wore off!",@battlers[side].pbTeam))
      # Light Screen
      pbEORCountDownSideEffect(side,PBEffects::LightScreen,
         _INTL("{1}'s Light Screen wore off!",@battlers[side].pbTeam))
      # Safeguard
      pbEORCountDownSideEffect(side,PBEffects::Safeguard,
         _INTL("{1} is no longer protected by Safeguard!",@battlers[side].pbTeam))
      # Mist
      pbEORCountDownSideEffect(side,PBEffects::Mist,
         _INTL("{1} is no longer protected by mist!",@battlers[side].pbTeam))
      # Tailwind
      if $gym_gimmick != true
        pbEORCountDownSideEffect(side,PBEffects::Tailwind,
           _INTL("{1}'s Tailwind petered out!",@battlers[side].pbTeam))
      end
      # Lucky Chant
      pbEORCountDownSideEffect(side,PBEffects::LuckyChant,
         _INTL("{1}'s Lucky Chant wore off!",@battlers[side].pbTeam))
      # Pledge Rainbow
      pbEORCountDownSideEffect(side,PBEffects::Rainbow,
         _INTL("The rainbow on {1}'s side disappeared!",@battlers[side].pbTeam(true)))
      # Pledge Sea of Fire
      pbEORCountDownSideEffect(side,PBEffects::SeaOfFire,
         _INTL("The sea of fire around {1} disappeared!",@battlers[side].pbTeam(true)))
      # Pledge Swamp
      pbEORCountDownSideEffect(side,PBEffects::Swamp,
         _INTL("The swamp around {1} disappeared!",@battlers[side].pbTeam(true)))
      # Aurora Veil
      if $gym_gimmick != true
        pbEORCountDownSideEffect(side,PBEffects::AuroraVeil,
           _INTL("{1}'s Aurora Veil wore off!",@battlers[side].pbTeam(true)))
      end
    end
    # Trick Room
    if @field.field_effects != :Dream
      pbEORCountDownFieldEffect(PBEffects::TrickRoom,
         _INTL("The twisted dimensions returned to normal!"))
    end
    # Gravity
    pbEORCountDownFieldEffect(PBEffects::Gravity,
       _INTL("Gravity returned to normal!"))
    # Water Sport
    pbEORCountDownFieldEffect(PBEffects::WaterSportField,
       _INTL("The effects of Water Sport have faded."))
    # Mud Sport
    pbEORCountDownFieldEffect(PBEffects::MudSportField,
       _INTL("The effects of Mud Sport have faded."))
    # Wonder Room
    pbEORCountDownFieldEffect(PBEffects::WonderRoom,
       _INTL("Wonder Room wore off, and Defense and Sp. Def stats returned to normal!"))
    # Magic Room
    pbEORCountDownFieldEffect(PBEffects::MagicRoom,
       _INTL("Magic Room wore off, and held items' effects returned to normal!"))
    # Hurricane
    pbEORCountDownFieldEffect(PBEffects::Hurricane,
       _INTL("The hurricane died down!"))
    # End of terrains
    pbEORTerrain
    priority.each do |b|
      next if b.fainted?
      pbEORTerrainHealing(b)
      # Hyper Mode (Shadow Pokémon)
      if b.inHyperMode?
        if pbRandom(100)<10
          b.pokemon.hyper_mode = false
          b.pokemon.adjustHeart(-50)
          pbDisplay(_INTL("{1} came to its senses!",b.pbThis))
        else
          pbDisplay(_INTL("{1} is in Hyper Mode!",b.pbThis))
        end
      end
      # Uproar
      if b.effects[PBEffects::Uproar]>0
        b.effects[PBEffects::Uproar] -= 1
        if b.effects[PBEffects::Uproar]==0
          pbDisplay(_INTL("{1} calmed down.",b.pbThis))
        else
          pbDisplay(_INTL("{1} is making an uproar!",b.pbThis))
        end
      end
      # Slow Start's end message
      if b.effects[PBEffects::SlowStart]>0
        b.effects[PBEffects::SlowStart] -= 1
        if b.effects[PBEffects::SlowStart]==0
          pbDisplay(_INTL("{1} finally got its act together!",b.pbThis))
        end
      end
      # Bad Dreams, Moody, Speed Boost
      BattleHandlers.triggerEOREffectAbility(b.ability,b,self) if b.abilityActive?
      # Flame Orb, Sticky Barb, Toxic Orb
      BattleHandlers.triggerEOREffectItem(b.item,b,self) if b.itemActive?
      # Harvest, Pickup, Ball Fetch
      BattleHandlers.triggerEORGainItemAbility(b.ability,b,self) if b.abilityActive?
    end
    pbGainExp
    return if @decision>0
    # Form checks
    priority.each { |b| b.pbCheckForm(true) }
    # Switch Pokémon in if possible
    pbEORSwitch
    return if @decision>0
    # In battles with at least one side of size 3+, move battlers around if none
    # are near to any foes
    pbEORShiftDistantBattlers
    # Try to make Trace work, check for end of primordial weather
    priority.each { |b| b.pbContinualAbilityChecks }
    # Reset/count down battler-specific effects (no messages)
    eachBattler do |b|
      b.effects[PBEffects::BanefulBunker]    = false
      b.effects[PBEffects::Charge]           -= 1 if b.effects[PBEffects::Charge]>0
      b.effects[PBEffects::Counter]          = -1
      b.effects[PBEffects::CounterTarget]    = -1
      b.effects[PBEffects::Electrify]        = false
      b.effects[PBEffects::Endure]           = false
      b.effects[PBEffects::FirstPledge]      = 0
      b.effects[PBEffects::Flinch]           = false
      b.effects[PBEffects::FocusPunch]       = false
      b.effects[PBEffects::FollowMe]         = 0
      b.effects[PBEffects::HelpingHand]      = false
      b.effects[PBEffects::HyperBeam]        -= 1 if b.effects[PBEffects::HyperBeam]>0
      b.effects[PBEffects::KingsShield]      = false
      b.effects[PBEffects::LaserFocus]       -= 1 if b.effects[PBEffects::LaserFocus]>0
      if b.effects[PBEffects::LockOn]>0   # Also Mind Reader
        b.effects[PBEffects::LockOn]         -= 1
        b.effects[PBEffects::LockOnPos]      = -1 if b.effects[PBEffects::LockOn]==0
      end
      b.effects[PBEffects::MagicBounce]      = false
      b.effects[PBEffects::MagicCoat]        = false
      b.effects[PBEffects::MirrorCoat]       = -1
      b.effects[PBEffects::MirrorCoatTarget] = -1
      b.effects[PBEffects::Powder]           = false
      b.effects[PBEffects::Prankster]        = false
      b.effects[PBEffects::PriorityAbility]  = false
      b.effects[PBEffects::PriorityItem]     = false
      b.effects[PBEffects::Protect]          = false
      b.effects[PBEffects::RagePowder]       = false
      b.effects[PBEffects::Roost]            = false
      b.effects[PBEffects::Snatch]           = 0
      b.effects[PBEffects::SpikyShield]      = false
      b.effects[PBEffects::SilkTrap]         = false
      b.effects[PBEffects::Spotlight]        = 0
      b.effects[PBEffects::ThroatChop]       -= 1 if b.effects[PBEffects::ThroatChop]>0
      b.effects[PBEffects::Obstruct]         = false
      b.lastHPLost                           = 0
      b.lastHPLostFromFoe                    = 0
      b.tookDamage                           = false
      b.tookPhysicalHit                      = false
      b.statsRaised                          = false
      b.statsLowered                         = false
      b.lastRoundMoveFailed                  = b.lastMoveFailed
      b.lastAttacker.clear
      b.lastFoeAttacker.clear
    end
    # Reset/count down side-specific effects (no messages)
    for side in 0...2
      @sides[side].effects[PBEffects::CraftyShield]         = false
      if !@sides[side].effects[PBEffects::EchoedVoiceUsed]
        @sides[side].effects[PBEffects::EchoedVoiceCounter] = 0
      end
      @sides[side].effects[PBEffects::EchoedVoiceUsed]      = false
      @sides[side].effects[PBEffects::MatBlock]             = false
      @sides[side].effects[PBEffects::QuickGuard]           = false
      @sides[side].effects[PBEffects::Round]                = false
      @sides[side].effects[PBEffects::WideGuard]            = false
    end
    # Reset/count down field-specific effects (no messages)
    @field.effects[PBEffects::IonDeluge]   = false
    @field.effects[PBEffects::FairyLock]   -= 1 if @field.effects[PBEffects::FairyLock]>0
    @field.effects[PBEffects::FusionBolt]  = false
    @field.effects[PBEffects::FusionFlare] = false
    eachBattler do |battler|
      battler.effects[PBEffects::CudChew]             -= 1 if battler.effects[PBEffects::CudChew] > 0
      battler.effects[PBEffects::Comeuppance]          = -1
      battler.effects[PBEffects::ComeuppanceTarget]    = -1
      battler.effects[PBEffects::GlaiveRush]          -= 1 if battler.effects[PBEffects::GlaiveRush] > 0
    end
    # Neutralizing Gas
    pbCheckNeutralizingGas
    @battleAI.end_of_round
    PBAI.log
    @endOfRound = false
  end

  def pbEndPrimordialWeather
    return if $gym_weather == true
    oldWeather = @field.weather
    # End Primordial Sea, Desolate Land, Delta Stream
    case @field.weather
    when :HarshSun
      if !pbCheckGlobalAbility(:DESOLATELAND) && @field.weather != :HarshSun
        @field.weather = :None
        pbDisplay("The harsh sunlight faded!")
      end
    when :HeavyRain
      if !pbCheckGlobalAbility(:PRIMORDIALSEA) && @field.weather != :HeavyRain
        @field.weather = :None
        pbDisplay("The heavy rain has lifted!")
      end
    when :StrongWinds
      if !pbCheckGlobalAbility(:DELTASTREAM) && @field.weather != :StrongWinds
        @field.weather = :None
        pbDisplay("The mysterious air current has dissipated!")
      end
    end
    if @field.weather!=oldWeather
      # Check for form changes caused by the weather changing
      eachBattler { |b| b.pbCheckFormOnWeatherChange }
      # Start up the default weather
      pbStartWeather(nil,$game_screen.weather_type) if $game_screen.weather_type!= :None
    end
  end
end

def pbBattleTypeWeakingBerry(type,moveType,target,mults)
  return if moveType != type
  return if target.battle.pbCheckOpposingAbility(:UNNERVE,@index)
  return if target.battle.pbCheckOpposingAbility(:ASONEICE,@index)
  return if target.battle.pbCheckOpposingAbility(:ASONEGHOST,@index)
  return if target.battle.pbCheckOpposingAbility(:LIONSPRIDE,@index)
  return if Effectiveness.resistant?(target.damageState.typeMod) && moveType != :NORMAL
  mults[:final_damage_multiplier] /= target.hasActiveAbility?(:RIPEN)? 4 : 2
  target.damageState.berryWeakened = true
  target.battle.pbCommonAnimation("EatBerry",target) if $test_trigger == false
end

class PokeBattle_Move_086 < PokeBattle_Move
  def pbBaseDamageMultiplier(damageMult,user,target)
    damageMult *= 2 if (!user.item || user.effects[PBEffects::GemConsumed] != nil) #For doubling up with Flying Gem
    return damageMult
  end
end

#===============================================================================
#Electro Drift/Collision Course
class PokeBattle_Move_523 < PokeBattle_Move
  def pbBaseDamage(baseDmg, user, target)
    baseDmg *= 1.3 if Effectiveness.super_effective?(target.damageState.typeMod)
    return baseDmg
  end
end

class PokeBattle_Move_519 < PokeBattle_TargetMultiStatDownMove
  def initialize(battle,move)
    super
    @statDown = [:DEFENSE,1,:SPECIAL_DEFENSE,1]
  end
end
#=============
#Effects
#=============

module PBEffects
  # Starts from 401 to avoid conflicts with other plugins.
  # Abilities
  ParadoxStat         = 401
  BoosterEnergy       = 402
  CudChew             = 403
  SupremeOverlord     = 404
  # Moves
  Comeuppance         = 405
  ComeuppanceTarget   = 406
  DoubleShock         = 407
  GlaiveRush          = 408
  CommanderTatsugiri  = 409
  CommanderDondozo    = 410
  SilkTrap            = 412
  SaltCure            = 413
  AllySwitch          = 414
  StarSap             = 415
  CometShards         = 416
  Ambidextrous        = 417
  GorillaTactics      = 418
  BallFetch           = 419
  LashOut             = 420
  BurningJealousy     = 421
  NoRetreat           = 422
  Obstruct            = 423
  JawLock             = 424
  JawLockUser         = 425
  TarShot             = 426
  Octolock            = 427
  OctolockUser        = 428
  BlunderPolicy       = 429
  NeutralizingGas     = 430
  EchoChamber         = 431
  Cinders             = 432
  Singed              = 433
  Syrupy              = 434
  SyrupyUser          = 435
  BurningBulwark      = 436
  Ricochet            = 437
  Hurricane           = 438
  Spirits             = 439
  SuccessiveMove      = 440
end

class PokeBattle_Move_570 < PokeBattle_TargetStatDownMove
  def initialize(battle,move)
    super
    @statDown = [:SPEED,1]
  end

  def pbBaseDamage(baseDmg,user,target)
    if @battle.field.terrain == :Grassy
      baseDmg = (baseDmg/2.0).round
    end
    return baseDmg
  end
end

#===============================================================================
# Terrain-inducing move.
#===============================================================================
class PokeBattle_TerrainMove < PokeBattle_Move
  def initialize(battle,move)
    super
    @terrainType = :None
  end

  def pbMoveFailed?(user,targets)
    case @battle.field.weather
    when @terrainType
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    if $gym_terrain == true
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    @battle.pbStartTerrain(user,@terrainType)
    #@battle.pbStartTerrain(user,@terrainType)
  end
end

#===============================================================================
# For 5 rounds, creates an electric terrain which boosts Electric-type moves and
# prevents Pokémon from falling asleep. Affects non-airborne Pokémon only.
# (Electric Terrain)
#===============================================================================
class PokeBattle_Move_154 < PokeBattle_TerrainMove
  def initialize(battle,move)
    super
    @terrainType = :Electric
  end
end



#===============================================================================
# For 5 rounds, creates a grassy terrain which boosts Grass-type moves and heals
# Pokémon at the end of each round. Affects non-airborne Pokémon only.
# (Grassy Terrain)
#===============================================================================
class PokeBattle_Move_155 < PokeBattle_TerrainMove
  def initialize(battle,move)
    super
    @terrainType = :Grassy
  end
end



#===============================================================================
# For 5 rounds, creates a misty terrain which weakens Dragon-type moves and
# protects Pokémon from status problems. Affects non-airborne Pokémon only.
# (Misty Terrain)
#===============================================================================
class PokeBattle_Move_156 < PokeBattle_TerrainMove
  def initialize(battle,move)
    super
    @terrainType = :Misty
  end
end

#===============================================================================
# For 5 rounds, creates a psychic terrain which boosts Psychic-type moves and
# prevents Pokémon from being hit by >0 priority moves. Affects non-airborne
# Pokémon only. (Psychic Terrain)
#===============================================================================
class PokeBattle_Move_173 < PokeBattle_TerrainMove
  def initialize(battle,move)
    super
    @terrainType = :Psychic
  end
end

BattleHandlers::UserAbilityEndOfMove.add(:LIONSPRIDE,
  proc { |ability,user,targets,move,battle|
    next if battle.pbAllFainted?(user.idxOpposingSide)
    numFainted = 0
    targets.each { |b| numFainted += 1 if b.damageState.fainted }
    next if numFainted==0 || !user.pbCanRaiseStatStage?(:SPECIAL_ATTACK,user) || user.fainted?
    battle.pbShowAbilitySplash(user,false,true,GameData::Ability.get(:LIONSPRIDE).name)
    if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      user.pbRaiseStatStage(:SPECIAL_ATTACK,numFainted,user)
    else
      user.pbRaiseStatStageByCause(:SPECIAL_ATTACK,numFainted,user,GameData::Ability.get(:LIONSPRIDE).name)
    end
    battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::AbilityOnSwitchIn.copy(:ASONEGHOST,:LIONSPRIDE)

BattleHandlers::DamageCalcUserAbility.add(:VOCALFRY,
  proc { |ability,user,target,move,mults,baseDmg,type|
    if move.soundMove? && move.damagingMove?
      mults[:base_damage_multiplier] = (mults[:base_damage_multiplier]*1.2).round
    end
  }
)

BattleHandlers::TrappingTargetAbility.add(:DEATHGRIP,
  proc { |ability,switcher,bearer,battle|
    next true if !switcher.hasActiveAbility?(:DEATHGRIP)
  }
)

BattleHandlers::DamageCalcUserAllyAbility.add(:UNKNOWNPOWER,
  proc { |ability,user,target,move,mults,baseDmg,type|
    mults[:final_damage_multiplier] *= 1.3
  }
)

BattleHandlers::DamageCalcUserAbility.add(:UNKNOWNPOWER,
  proc { |ability,user,target,move,mults,baseDmg,type|
    mults[:final_damage_multiplier] *= 1.3
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:UNKNOWNPOWER,
  proc { |ability,user,target,move,mults,baseDmg,type|
    mults[:defense_multiplier] *= 1.5
  }
)

BattleHandlers::SpeedCalcAbility.add(:MEADOWRUSH,
  proc { |ability,battler,mult|
    next mult*2 if [:Grassy,:Garden].include?(battler.battle.field.field_effects)
    next mult*2 if battler.battle.field.terrain == :Grassy
  }
)

BattleHandlers::SpeedCalcAbility.add(:BRAINBLAST,
  proc { |ability,battler,mult|
    next mult*2 if [:Psychic,:Dream].include?(battler.battle.field.field_effects)
    next mult*2 if battler.battle.field.terrain == :Psychic
  }
)

BattleHandlers::DamageCalcUserAbility.add(:ROCKHEAD,
  proc { |ability,user,target,move,mults,baseDmg,type|
    mults[:base_damage_multiplier] = (mults[:base_damage_multiplier]*1.2).round if move.headMove?
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:GODLIKEPOWER,
  proc { |ability,battler,battle|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("Time to get rekt.",battler.pbOpposingTeam))
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::MoveImmunityTargetAbility.add(:PESTICIDE,
  proc { |ability,user,target,move,type,battle|
    next if type != :BUG
    battle.pbShowAbilitySplash(target)
    if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
    else
      battle.pbDisplay(_INTL("{1}'s {2} blocks {3}!",target.pbThis,target.abilityName,move.name))
    end
    if user.status == :NONE
      anim_name = GameData::Status.get(:POISON).animation
      battle.pbCommonAnimation(anim_name, user)
      user.status = :POISON
    end
    battle.pbParty(user.index).each do |pkmn|
      next if !pkmn.hasType?(:BUG) || pkmn.hasType?(:STEEL) || pkmn.hasType?(:POISON)
      next if pkmn.hasAbility?([:IMMUNITY,:PURIFYINGSALT,:FAIRYBUBBLE,:COMATOSE,:SHIELDSDOWN])
      pkmn.status = :POISON
    end
    battle.pbDisplay(_INTL("All Bug-types in the party were Poisoned!"))
    battle.pbHideAbilitySplash(target)
    next true
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:GRASSPELT,
  proc { |ability,user,target,move,mults,baseDmg,type|
    if user.battle.field.terrain == :Grassy || [:Garden,:Grassy].include?(user.battle.field.field_effects)
      mults[:defense_multiplier] *= 1.5
    end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:GRASSYSURGE,
  proc { |ability,battler,battle|
    next if battle.field.terrain == :Grassy
    battle.pbShowAbilitySplash(battler)
    battle.scene.pbAnimation(GameData::Move.get(:GRASSYTERRAIN).id,battler,battler)
    battle.field.terrainDuration = battler.hasActiveItem?(:TERRAINEXTENDER) ? 8 : 5
    battle.pbStartTerrain(battler, :Grassy)
    # NOTE: The ability splash is hidden again in def pbStartTerrain.
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:ELECTRICSURGE,
  proc { |ability,battler,battle|
    next if battle.field.terrain == :Electric
    battle.pbShowAbilitySplash(battler)
    battle.scene.pbAnimation(GameData::Move.get(:ELECTRICTERRAIN).id,battler,battler)
    battle.field.terrainDuration = battler.hasActiveItem?(:TERRAINEXTENDER) ? 8 : 5
    battle.pbStartTerrain(battler, :Electric)
    # NOTE: The ability splash is hidden again in def pbStartTerrain.
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:MISTYSURGE,
  proc { |ability,battler,battle|
    next if battle.field.terrain == :Misty
    battle.pbShowAbilitySplash(battler)
    battle.scene.pbAnimation(GameData::Move.get(:MISTYTERRAIN).id,battler,battler)
    battle.field.terrainDuration = battler.hasActiveItem?(:TERRAINEXTENDER) ? 8 : 5
    battle.pbStartTerrain(battler, :Misty)
    # NOTE: The ability splash is hidden again in def pbStartTerrain.
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:PSYCHICSURGE,
  proc { |ability,battler,battle|
    next if battle.field.terrain == :Psychic
    battle.pbShowAbilitySplash(battler)
    battle.scene.pbAnimation(GameData::Move.get(:PSYCHICTERRAIN).id,battler,battler)
    battle.field.terrainDuration = battler.hasActiveItem?(:TERRAINEXTENDER) ? 8 : 5
    battle.pbStartTerrain(battler, :Psychic)
    # NOTE: The ability splash is hidden again in def pbStartTerrain.
  }
)

BattleHandlers::SpeedCalcAbility.add(:SURGESURFER,
  proc { |ability,battler,mult|
    next mult*2 if [:Electric,:Magnetic,:Digital].include?(battler.battle.field.field_effects)
    next mult*2 if battler.battle.field.terrain == :Electric
    next mult*2 if battler.battle.pbWeather == :Storm
  }
)

class PokeBattle_Move_0D6 < PokeBattle_HealingMove
  def pbHealAmount(user)
    if !user.pbHasType?(:FIRE) && @battle.field.field_effects == :Lava
      @battle.pbDisplay(_INTL("The lava singed {1}'s wings!",user.pbThis))
      user.effects[PBEffects::Singed] = true
      return 0
    else
      return (user.totalhp/2.0).round
    end
  end

  def pbMoveFailed?(user,targets)
    return true if user.effects[PBEffects::Singed]
    return super
  end

  def pbEffectAfterAllHits(user,target)
    user.effects[PBEffects::Roost] = true
  end
end

BattleHandlers::EORWeatherAbility.add(:STARSALVE,
  proc { |ability,weather,battler,battle|
    next unless [:Starstorm].include?(weather)
    next if !battler.canHeal?
    battle.pbShowAbilitySplash(battler)
    battler.pbRecoverHP(battler.totalhp/8)
    if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    else
      battle.pbDisplay(_INTL("{1}'s {2} restored its HP.",battler.pbThis,battler.abilityName))
    end
    battle.pbHideAbilitySplash(battler)
  }
)
#=================
# Gen 9 DLC Moves
#=================
# Matcha Gotcha
class PokeBattle_Move_600 < PokeBattle_BurnMove
  def healingMove?; return Settings::MECHANICS_GENERATION >= 6; end

  def pbEffectAgainstTarget(user,target)
    return if target.damageState.hpLost<=0
    hpGain = (target.damageState.hpLost/2.0).round
    user.pbRecoverHPFromDrain(hpGain,target)
  end
end

# Syrup Bomb
class PokeBattle_Move_601 < PokeBattle_Move
  def pbEffectAgainstTarget(user, target)
    return if target.fainted? || target.damageState.substitute
    return if target.effects[PBEffects::Syrupy] > 0
    target.effects[PBEffects::Syrupy] = 3
    target.effects[PBEffects::SyrupyUser] = user.index
    @battle.pbDisplay(_INTL("{1} got covered in sticky candy syrup!", target.pbThis))
  end

  def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    hitNum = (user.shiny?) ? 1 : 0
    super
  end
end

# Ivy Cudgel
class PokeBattle_Move_602 < PokeBattle_Move
  def pbBaseType(user)
    userTypes = user.pbTypes(true)
    return userTypes[1]
  end
end

# Electro Shot
class PokeBattle_Move_603 < PokeBattle_TwoTurnMove
  attr_reader :statUp

  def initialize(battle, move)
    super
    @statUp = [:SPECIAL_ATTACK, 1]
  end

  def pbIsChargingTurn?(user)
    ret = super
    if !user.effects[PBEffects::TwoTurnAttack] &&
       [:Rain, :HeavyRain].include?(user.effectiveWeather)
      @powerHerb = false
      @chargingTurn = true
      @damagingTurn = true
      return false
    end
    return ret
  end
  
  def pbChargingTurnMessage(user, targets)
    @battle.pbDisplay(_INTL("{1} absorbed electricity!", user.pbThis))
  end

  def pbChargingTurnEffect(user, target)
    if user.pbCanRaiseStatStage?(@statUp[0], user, self)
      user.pbRaiseStatStage(@statUp[0], @statUp[1], user)
    end
  end
end

# Tera Starstorm
class PokeBattle_Move_604 < PokeBattle_Move
  def pbCalcTypeModSingle(moveType,defType,user,target)
    return Effectiveness::SUPER_EFFECTIVE_ONE if target.mega? && user.species == :TERAPAGOS
    return super
  end
end

# Fickle Beam
class PokeBattle_Move_605 < PokeBattle_Move
  def pbOnStartUse(user, targets)
    @allOutAttack = (@battle.pbRandom(100) < 30)
    if @allOutAttack
      @battle.pbDisplay(_INTL("{1} is going all out for this attack!", user.pbThis))
    end
  end

  def pbBaseDamage(baseDmg, user, target)
    return (@allOutAttack) ? baseDmg * 2 : baseDmg
  end
  
  def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    hitNum = 1 if @allOutAttack
    super
  end
end

# Burning Bulwark
class PokeBattle_Move_606 < PokeBattle_ProtectMove
  def initialize(battle,move)
    super
    @effect = PBEffects::BurningBulwark
  end
end

# Dragon Cheer
class PokeBattle_Move_607 < PokeBattle_Move
  def ignoresSubstitute?(user); return true; end
  def canSnatch?; return true; end

  def pbMoveFailed?(user, targets)
    @validTargets = []
    @battle.allSameSideBattlers(user).each do |b|
      next if b.index == user.index
      next if b.effects[PBEffects::FocusEnergy] > 0
      @validTargets.push(b)
    end
    if @validTargets.length == 0
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    return false if @validTargets.any? { |b| b.index == target.index }
    @battle.pbDisplay(_INTL("{1} is already pumped!", target.pbThis)) if show_message
    return true
  end

  def pbEffectAgainstTarget(user, target)
    boost = (target.pbHasType?(:DRAGON)) ? 2 : 1
    target.effects[PBEffects::FocusEnergy] = boost
    @battle.pbCommonAnimation("StatUp", target)
    @battle.pbDisplay(_INTL("{1} is getting pumped!", target.pbThis))
  end
end

# Alluring Voice
class PokeBattle_Move_608 < PokeBattle_ConfuseMove
  def pbAdditionalEffect(user, target)
    super if target.statsRaised
  end
end

# Hard Press
class PokeBattle_Move_609 < PokeBattle_Move
  def pbBaseDamage(baseDmg, user, target)
    return [100 * target.hp / target.totalhp, 1].max
  end
end

# Supercell Slam
class PokeBattle_Move_612 < PokeBattle_Move_10B
  def unusableInGravity?; return false; end
end

# Psychic Noise
class PokeBattle_Move_610 < PokeBattle_Move
  def pbAdditionalEffect(user, target)
    return if target.effects[PBEffects::HealBlock] > 0
    return if pbMoveFailedAromaVeil?(user, target, false)
    target.effects[PBEffects::HealBlock] = 2
    @battle.pbDisplay(_INTL("{1} was prevented from healing!", target.pbThis))
    target.pbItemStatusCureCheck
  end
end

# Upper Hand
class PokeBattle_Move_611 < PokeBattle_FlinchMove
  def pbMoveFailed?(user, targets)
  hasPriority = false
    targets.each do |b|
      next if b.movedThisRound?
      choices = @battle.choices[b.index]
      next if !choices[2].damagingMove?
    next if !choices[4] || choices[4] <= 0 || choices[4] > @priority
      hasPriority = true
    end
    if !hasPriority
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end
end

#====================
# Gen 9 DLC Abilities
#====================
BattleHandlers::AbilityOnSwitchIn.add(:SUPERSWEETSYRUP,
  proc { |ability,battler,battle|
    battle.pbShowAbilitySplash(battler)
    battle.eachOtherSideBattler(battler.index) do |b|
      next if !b.near?(battler)
      b.pbLowerEvasionStatStageSyrup(battler)
      b.pbItemOnIntimidatedCheck
    end
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:HOSPITALITY,
  proc { |ability,battler,battle|
    next if battler.allAllies.none? { |b| b.hp < b.totalhp }
    battle.pbShowAbilitySplash(battler)
    battler.allAllies.each do |b|
      next if b.hp == b.totalhp
      amt = (b.totalhp / 4).floor
      b.pbRecoverHP(amt)
      battle.pbDisplay(_INTL("{1} drank down all the matcha that {2} made!", b.pbThis, battler.pbThis(true)))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::UserAbilityOnHit.add(:TOXICCHAIN,
  proc { |ability,user,target,move,battle|
    next if battle.pbRandom(100) >= 30
    next if target.hasActiveItem?(:COVERTCLOAK)
    battle.pbShowAbilitySplash(user)
    if target.hasActiveAbility?(:SHIELDDUST) && !battle.moldBreaker
      battle.pbShowAbilitySplash(target)
      if !Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1} is unaffected!", target.pbThis))
      end
      battle.pbHideAbilitySplash(target)
    elsif target.pbCanPoison?(user, PokeBattle_SceneConstants::USE_ABILITY_SPLASH)
      msg = nil
      if !Battle::Scene::USE_ABILITY_SPLASH
        msg = _INTL("{1} was badly poisoned!", target.pbThis)
      end
      target.pbPoison(user, msg, true)
    end
    battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::StatLossImmunityAbility.copy(:KEENEYE,:MINDSEYE)
BattleHandlers::AccuracyCalcUserAbility.copy(:KEENEYE,:MINDSEYE)

#===============================================================================
# Embody Aspect
#===============================================================================
BattleHandlers::AbilityOnSwitchIn.add(:EMBODYASPECT,
  proc { |ability, battler, battle, switch_in|
    #next if !battler.isSpecies?(:OGERPON)
    #next if battler.effects[PBEffects::OneUseAbility] == ability
    mask = GameData::Species.get(:OGERPON).form_name
    battle.pbDisplay(_INTL("The {1} worn by {2} shone brilliantly!", mask, battler.pbThis(true)))
    battler.pbRaiseStatStageByAbility(:SPEED, 1, battler)
    #battler.effects[PBEffects::OneUseAbility] = ability
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:EMBODYASPECT_1,
  proc { |ability, battler, battle, switch_in|
    #next if !battler.isSpecies?(:OGERPON)
    #next if battler.effects[PBEffects::OneUseAbility] == ability
    mask = GameData::Species.get(:OGERPON_1).form_name
    battle.pbDisplay(_INTL("The {1} worn by {2} shone brilliantly!", mask, battler.pbThis(true)))
    battler.pbRaiseStatStageByAbility(:SPECIAL_DEFENSE, 1, battler)
    #battler.effects[PBEffects::OneUseAbility] = ability
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:EMBODYASPECT_2,
  proc { |ability, battler, battle, switch_in|
    #next if !battler.isSpecies?(:OGERPON)
    #next if battler.effects[PBEffects::OneUseAbility] == ability
    mask = GameData::Species.get(:OGERPON_2).form_name
    battle.pbDisplay(_INTL("The {1} worn by {2} shone brilliantly!", mask, battler.pbThis(true)))
    battler.pbRaiseStatStageByAbility(:ATTACK, 1, battler)
    #battler.effects[PBEffects::OneUseAbility] = ability
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:EMBODYASPECT_3,
  proc { |ability, battler, battle, switch_in|
    #next if !battler.isSpecies?(:OGERPON)
    #next if battler.effects[PBEffects::OneUseAbility] == ability
    mask = GameData::Species.get(:OGERPON_3).form_name
    battle.pbDisplay(_INTL("The {1} worn by {2} shone brilliantly!", mask, battler.pbThis(true)))
    battler.pbRaiseStatStageByAbility(:DEFENSE, 1, battler)
    #battler.effects[PBEffects::OneUseAbility] = ability
  }
)

#===============================================================================
# Wellspring Mask, Hearthflame Mask, Cornerstone Mask
#===============================================================================
BattleHandlers::DamageCalcUserItem.add(:WELLSPRINGMASK,
  proc { |item,user,target,move,mults,baseDmg,type|
    mults[:final_damage_multiplier] *= 1.2 if user.isSpecies?(:OGERPON)
  }
)

BattleHandlers::DamageCalcUserItem.copy(:WELLSPRINGMASK, :HEARTHFLAMEMASK, :CORNERSTONEMASK, :TEALMASK)


############################# Indigo Disk DLC ##################################

#===============================================================================
# Tera Shell
#===============================================================================
BattleHandlers::ModifyTypeEffectiveness.add(:TERASHELL,
  proc { |ability, user, target, move, battle, effectiveness|
    next if !move.damagingMove?
    next if user.hasMoldBreaker?
    next if target.hp < target.totalhp
    next if effectiveness < Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
    target.damageState.terashell = true
    next Effectiveness::NOT_VERY_EFFECTIVE_MULTIPLIER
  }
)

BattleHandlers::OnMoveSuccessCheck.add(:TERASHELL,
  proc { |ability, user, target, move, battle|
    next if !target.damageState.terashell
    battle.pbShowAbilitySplash(target)
    battle.pbDisplay(_INTL("{1} made its shell gleam! It's distorting type matchups!", target.pbThis))
    battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::ModifyTypeEffectiveness.copy(:TERASHELL,:TERAFORMZERO)
BattleHandlers::OnMoveSuccessCheck.copy(:TERASHELL,:TERAFORMZERO)
#===============================================================================
# Teraform Zero
#===============================================================================
BattleHandlers::AbilityOnSwitchIn.add(:TERAFORMZERO,
  proc { |ability, battler, battle, switch_in|
    #next if battler.ability_triggered?
    #battle.pbSetAbilityTrigger(battler)
    weather = battle.field.weather
    terrain = battle.field.terrain
    next if weather == :None && terrain == :None
    showSplash = false
    if weather != :None && battle.field.defaultWeather == :None && weather != :Starstorm
    showSplash = true
      battle.pbShowAbilitySplash(battler)
      battle.field.weather = :None
      battle.field.weatherDuration = 0
      case weather
      when :Sun         then battle.pbDisplay(_INTL("The sunlight faded."))
      when :Rain        then battle.pbDisplay(_INTL("The rain stopped."))
      when :Sandstorm   then battle.pbDisplay(_INTL("The sandstorm subsided."))
      when :Hail
        case Settings::HAIL_WEATHER_TYPE
        when 0 then battle.pbDisplay(_INTL("The hail stopped."))
        when 1 then battle.pbDisplay(_INTL("The snow stopped."))
        when 2 then battle.pbDisplay(_INTL("The hailstorm ended."))
        end
      when :HarshSun    then battle.pbDisplay(_INTL("The harsh sunlight faded!"))
      when :HeavyRain   then battle.pbDisplay(_INTL("The heavy rain has lifted!"))
      when :StrongWinds then battle.pbDisplay(_INTL("The mysterious air current has dissipated!"))
      else
        battle.pbDisplay(_INTL("The weather returned to normal."))
      end
    end
    if terrain != :None && battle.field.defaultTerrain == :None
      battle.pbShowAbilitySplash(battler) if !showSplash
      battle.field.terrain = :None
      battle.field.terrainDuration = 0
      case terrain
      when :Electric then battle.pbDisplay(_INTL("The electric current disappeared from the battlefield!"))
      when :Grassy   then battle.pbDisplay(_INTL("The grass disappeared from the battlefield!"))
      when :Psychic  then battle.pbDisplay(_INTL("The mist disappeared from the battlefield!"))
      when :Misty    then battle.pbDisplay(_INTL("The weirdness disappeared from the battlefield!"))
      when :Poison   then battle.pbDisplay(_INTL("The toxic waste disappeard from the battlefield!"))

      else
        battle.pbDisplay(_INTL("The battlefield returned to normal."))
      end
    end
    next if !showSplash
    battle.pbHideAbilitySplash(battler)
    battle.allBattlers.each { |b| b.pbCheckFormOnWeatherChange }
    battle.allBattlers.each { |b| b.pbAbilityOnTerrainChange }
    battle.allBattlers.each { |b| b.pbItemTerrainStatBoostCheck }
    battle.scene.pbChangeField(:None)
    @battle.scene.pbRefreshEverything
  }
)

#===============================================================================
# Poison Puppeteer
#===============================================================================
BattleHandlers::OnInflictingStatus.add(:POISONPUPPETEER,
  proc { |ability, user, battler, status|
    next if !user || user.index == battler.index
    next if status != :POISON
    next if battler.effects[PBEffects::Confusion] > 0
    user.battle.pbShowAbilitySplash(user)
    battler.pbConfuse if battler.pbCanConfuse?(user, false, nil)
    user.battle.pbHideAbilitySplash(user)
  }
)

#===============================================================================
# Clear Skies
#===============================================================================
BattleHandlers::AbilityOnSwitchIn.add(:CLEARSKIES,
  proc { |ability, battler, battle, switch_in|
    next if battler.ability_triggered?
    battle.pbSetAbilityTrigger(battler)
    weather = battle.field.weather
    next if weather == :None
    showSplash = false
    if weather != :None
      showSplash = true
      battle.pbShowAbilitySplash(battler)
      battle.field.weather = :None
      battle.field.weatherDuration = 0
      battle.pbDisplay(_INTL("The weather returned to normal."))
    end
    next if !showSplash
    battle.pbHideAbilitySplash(battler)
    battle.allBattlers.each { |b| b.pbCheckFormOnWeatherChange }
  }
)
#===============================================
# Field Effect Move Changes
#===============================================

# Dream Eater

class PokeBattle_Move_0DE < PokeBattle_Move
  def healingMove?; return Settings::MECHANICS_GENERATION >= 6; end

  def pbFailsAgainstTarget?(user,target)
    return false if @battle.field.field_effects == :Dream
    if !target.asleep?
      @battle.pbDisplay(_INTL("{1} wasn't affected!",target.pbThis))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    return if target.damageState.hpLost<=0
    hpGain = (target.damageState.hpLost/2.0).round
    user.pbRecoverHPFromDrain(hpGain,target)
  end
end

# Nightmare

class PokeBattle_Move_10F < PokeBattle_Move
  def pbFailsAgainstTarget?(user,target)
    return false if target.effects[PBEffects::Nightmare] == false && @battle.field.field_effects == :Dream
    if !target.asleep? || target.effects[PBEffects::Nightmare]
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    target.effects[PBEffects::Nightmare] = true
    @battle.pbDisplay(_INTL("{1} began having a nightmare!",target.pbThis))
  end
end

# Rest
class PokeBattle_Move_0D9 < PokeBattle_HealingMove
  def pbMoveFailed?(user,targets)
    return false if @battle.field.field_effects == :Dream && user.canHeal?
    if user.asleep?
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return true if !user.pbCanSleep?(user,true,self,true)
    return true if super
    return false
  end

  def pbHealAmount(user)
    return user.totalhp/2 if @battle.field.field_effects == :Dream
    return user.totalhp-user.hp
  end

  def pbEffectGeneral(user)
    if @battle.field.field_effects == :Dream
      @battle.pbDisplay(_INTL("The Dream field allowed {1} to stay awake and heal!",user.pbThis))
    else
      user.pbSleepSelf(_INTL("{1} slept and became healthy!",user.pbThis),3)
    end
    super
  end
end

# Sleep Talk
class PokeBattle_Move_0B4 < PokeBattle_Move
  def usableWhenAsleep?; return true; end
  def callsAnotherMove?; return true; end

  def initialize(battle,move)
    super
    @moveBlacklist = [
       "0D1",   # Uproar
       "0D4",   # Bide
       # Struggle, Chatter, Belch
       "002",   # Struggle                            # Not listed on Bulbapedia
       "014",   # Chatter                             # Not listed on Bulbapedia
       "158",   # Belch
       # Moves that affect the moveset (except Transform)
       "05C",   # Mimic
       "05D",   # Sketch
       # Moves that call other moves
       "0AE",   # Mirror Move
       "0AF",   # Copycat
       "0B0",   # Me First
       "0B3",   # Nature Power                        # Not listed on Bulbapedia
       "0B4",   # Sleep Talk
       "0B5",   # Assist
       "0B6",   # Metronome
       # Two-turn attacks
       "0C3",   # Razor Wind
       "0C4",   # Solar Beam, Solar Blade
       "0C5",   # Freeze Shock
       "0C6",   # Ice Burn
       "0C7",   # Sky Attack
       "0C8",   # Skull Bash
       "0C9",   # Fly
       "0CA",   # Dig
       "0CB",   # Dive
       "0CC",   # Bounce
       "0CD",   # Shadow Force
       "0CE",   # Sky Drop
       "12E",   # Shadow Half
       "14D",   # Phantom Force
       "14E",   # Geomancy
       # Moves that start focussing at the start of the round
       "115",   # Focus Punch
       "171",   # Shell Trap
       "172"    # Beak Blast
    ]
  end

  def pbMoveFailed?(user,targets)
    @sleepTalkMoves = []
    user.eachMoveWithIndex do |m,i|
      next if @moveBlacklist.include?(m.function)
      next if !@battle.pbCanChooseMove?(user.index,i,false,true)
      @sleepTalkMoves.push(i)
    end
    return false if @battle.field.field_effects == :Dream
    if !user.asleep? || @sleepTalkMoves.length==0
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    choice = @sleepTalkMoves[@battle.pbRandom(@sleepTalkMoves.length)]
    user.pbUseMoveSimple(user.moves[choice].id,user.pbDirectOpposing.index)
  end
end

# Aurora Veil
class PokeBattle_Move_167 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    if @battle.pbWeather != :Hail && @battle.pbWeather != :Sleet && ![:Icy,:FairyLights].include?(@battle.field.field_effects)
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    if user.pbOwnSide.effects[PBEffects::AuroraVeil]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbOwnSide.effects[PBEffects::AuroraVeil] = 5
    user.pbOwnSide.effects[PBEffects::AuroraVeil] = 8 if user.hasActiveItem?(:LIGHTCLAY)
    @battle.pbDisplay(_INTL("{1} made {2} stronger against physical and special moves!",
       @name,user.pbTeam(true)))
  end
end

class PokeBattle_Move_550 < PokeBattle_Move

  def pbBaseDamage(baseDmg, user, target)
    baseDmg *= 1.5 if [:Sun, :HarshSun].include?(@battle.pbWeather)
    baseDmg *= 1.25 if @battle.field.field_effects == :Lava
    return baseDmg
  end
end

BattleHandlers::AbilityOnSwitchIn.add(:KEENEYE,
  proc { |ability,battler,battle|
    battle.pbShowAbilitySplash(battler)
    battler.effects[PBEffects::FocusEnergy] = 2
    battle.scene.pbAnimation(GameData::Move.get(:FOCUSENERGY).id,battler,battler)
    battle.pbDisplay(_INTL("{1} is getting pumped!",battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:REVERSEROOM,
  proc { |ability,battler,battle|
    next if $game_temp.battle_rules["inverseBattle"]
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1} is twisting type matchups against it!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::ModifyTypeEffectiveness.add(:REVERSEROOM,
  proc { |ability, user, target, move, battle, effectiveness|
    next if !move.damagingMove?
    next if user.hasMoldBreaker?
    next if effectiveness == Effectiveness::NORMAL_EFFECTIVE
    mod1 = Effectiveness.calculate_one(move.type, target.types[0])
    mod2 = target.types.length == 1 ? Effectiveness::NORMAL_EFFECTIVE_ONE : Effectiveness.calculate_one(move.type, target.types[1])
    mod3 = target.effects[PBEffects::Type3] != nil ? Effectiveness.calculate_one(move.type, target.effects[PBEffects::Type3]) : Effectiveness::NORMAL_EFFECTIVE_ONE
    case mod1
    when 0
      imod1 = Effectiveness::SUPER_EFFECTIVE_ONE
    when 2
      imod1 = mod1
    else
      imod1 = 4/mod1
    end
    case mod2
    when 0
      imod2 = Effectiveness::SUPER_EFFECTIVE_ONE
    when 2
      imod2 = mod2
    else
      imod2 = 4/mod2
    end
    case mod3
    when 0
      imod3 = Effectiveness::SUPER_EFFECTIVE_ONE
    when 2
      imod3 = mod3
    else
      imod3 = 4/mod3
    end
    ret = imod1 * imod2 * imod3
    next ret
  }
)
#=======================
# Field Effect Abilities
#=======================
=begin
BattleHandlers::AbilityOnSwitchIn.add(:LIGHTNINGROD,
  proc { |ability,battler,battle|
    fe = FIELD_EFFECTS[battle.field.field_effects]
    next battler.pbRaiseStatStageByAbility(:SPECIAL_ATTACK,1,battler) if fe[:abilities].include?(ability)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:MOTORDRIVE,
  proc { |ability,battler,battle|
    fe = FIELD_EFFECTS[battle.field.field_effects]
    next battler.pbRaiseStatStageByAbility(:SPEED,1,battler) if fe[:abilities].include?(ability)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:FLASHFIRE,
  proc { |ability,battler,battle|
    fe = FIELD_EFFECTS[battle.field.field_effects]
    if fe[:abilities].include?(ability)
      battle.pbDisplay(_INTL("{1} had its Fire moves powered up!",battler.pbThis))
      next battler.effects[PBEffects::FlashFire] = true
    end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:WELLBAKEDBODY,
  proc { |ability,battler,battle|
    fe = FIELD_EFFECTS[battle.field.field_effects]
    next battler.pbRaiseStatStageByAbility(:DEFENSE,2,battler) if fe[:abilities].include?(ability)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SAPSIPPER,
  proc { |ability,battler,battle|
    fe = FIELD_EFFECTS[battle.field.field_effects]
    next battler.pbRaiseStatStageByAbility(:ATTACK,1,battler) if fe[:abilities].include?(ability)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:WINDPOWER,
  proc { |ability,battler,battle| 
    next if battle.field.field_effects != :WindTunnel
    battle.pbShowAbilitySplash(target)
    target.effects[PBEffects::Charge] = 2
    battle.pbDisplay(_INTL("Being hit by {1} charged {2} with power!", move.name, target.pbThis(true)))
    battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:INNERFOCUS,
  proc { |ability,battler,battle|
    next if battle.field.field_effects != :Dojo
    battle.pbShowAbilitySplash(battler)
    battler.effects[PBEffects::FocusEnergy] = 2
    battle.scene.pbAnimation(GameData::Move.get(:FOCUSENERGY).id,battler,battler)
    battle.pbDisplay(_INTL("{1} is getting pumped!",battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)
=end