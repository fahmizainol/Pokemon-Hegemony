#To set up your Field Effects, first register your Field Effect in the Field Effects Main script.
#Then, fill in the information below for each of your field effects, and if your field effects have custom intro scripts
#you will need to define them in the pbStartBattleCore script in the Main file. Just search for these items in the script
#to add custom effects if you so wish.
FIELD_EFFECTS = {
    :None => {
      :field_name => "None",
      :intro_message => nil, #message shown when field is active
      :field_ebdx => nil, # EBDX Environment Symbol (i.e. :GRASSY)
      :nature_power => :TRIATTACK,
      :mimicry => :NORMAL, #what type Camouflage/Mimicry will change you to
      :intro_script => nil, #a script that runs at the beginning of the battle
      #structure: "script name"
      :abilities => [], #abilities affected by this field
      :ability_effects => {}, #specific effects abilities trigger a stat boost that are not their normal effect.
      #ability effects data structure: Ability => [stat,amount boosted] example: :WATERVEIL -> [:EVASION,1]
      :move_damage_boost => {}, #if a move gets a power buff or nerf
      #structure: modifier => [move] i.e 1.2 => [:EARTHQUAKE]
      :move_messages => {}, #message the move getting the power change shows
      #structure: "message" => [move]
      :move_type_change => {}, #if a move changes type
      #structure: type => [move]
      :move_type_mod => {}, #if a move adds a type
      #structure: type => [move]
      :move_accuracy_change => {}, #if a move changes accuracy
      #structure = newAccuracy => [move]
      :defensive_modifiers => {}, #structure = modifier => [type,flag] where flag sets the kind of modifier.
      #flags are: physical, special, fullhp. fullhp flag cuts damage by the 1/modifier. other flags multiply def mods.
      #example: 2 => [:GHOST, "fullhp"] would make it so ghost types take 1/2 damage from full
      :type_damage_change => {}, #if a type gets a power buff or nerf
      #structure = modifier => [type] (i.e 1.2 => [:DRAGON] would boost dragon moves by 1.2 in this field)
      :type_messages => {}, #the message that shows when a type gets a buff or nerf
      #structure: "message" => [type]
      :type_type_mod => {}, #if a type gets added to a matchup based on the move type used due to the field
      #structure: addedType => [originalType]
      :type_mod_message => {}, #the message that shows if a type of move adds a type
      #structure: "message" => [oldType]
      :type_type_change => {}, #if a type changes due to the field
      #structure: newType => [oldType]
      :type_change_message => {}, #the message that shows if a type of move changes type
      #structure: "message" => [oldType]
      :type_accuracy_change => {},
      :side_effects => {}, #special effects activated when using certain moves or types, using flags as condition references
      #structure: "flag" => [move or type]
      :field_changers => {}, #moves or types that change the field
      #structure: newField => [type or move]
      :change_message => {}, #message that shows when the field changes
      #structure => "message" => [type or move]
      :field_change_conditions => {} #optional conditions that your field can change under
      #example would be if your field can only change in certain weather
      #structure: newField => condition
      #note: condition must be a method that can be run to check if the conditions are met
      #major note: all things in brackets MUST stay in brackets when used in these sections, or the script
      #will fail
    },
    :Clear => {
      :field_name => "None",
      :intro_message => nil, #message shown when field is active
      :field_ebdx => :INDOOR, #image file name without the file extension
      :nature_power => :TRIATTACK,
      :mimicry => :NORMAL, #what type Camouflage/Mimicry will change you to
      :intro_script => nil, #a script that runs at the beginning of the battle
      #structure: "script name"
      :abilities => [], #abilities affected by this field
      :ability_effects => {}, #specific effects abilities trigger a stat boost that are not their normal effect.
      #ability effects data structure: Ability => [stat,amount boosted] example: :WATERVEIL -> [:EVASION,1]
      :move_damage_boost => {}, #if a move gets a power buff or nerf
      #structure: modifier => [move] i.e 1.2 => [:EARTHQUAKE]
      :move_messages => {}, #message the move getting the power change shows
      #structure: "message" => [move]
      :move_type_change => {}, #if a move changes type
      #structure: type => [move]
      :move_type_mod => {}, #if a move adds a type
      #structure: type => [move]
      :move_accuracy_change => {}, #if a move changes accuracy
      #structure = newAccuracy => [move]
      :defensive_modifiers => {}, #structure = modifier => [type,flag] where flag sets the kind of modifier.
      #flags are: physical, special, fullhp. fullhp flag cuts damage by the 1/modifier. other flags multiply def mods.
      #example: 2 => [:GHOST, "fullhp"] would make it so ghost types take 1/2 damage from full
      :type_damage_change => {}, #if a type gets a power buff or nerf
      #structure = modifier => [type] (i.e 1.2 => [:DRAGON] would boost dragon moves by 1.2 in this field)
      :type_messages => {}, #the message that shows when a type gets a buff or nerf
      #structure: "message" => [type]
      :type_type_mod => {}, #if a type gets added to a matchup based on the move type used due to the field
      #structure: addedType => [originalType]
      :type_mod_message => {}, #the message that shows if a type of move adds a type
      #structure: "message" => [oldType]
      :type_type_change => {}, #if a type changes due to the field
      #structure: newType => [oldType]
      :type_change_message => {}, #the message that shows if a type of move changes type
      #structure: "message" => [oldType]
      :type_accuracy_change => {},
      :side_effects => {}, #special effects activated when using certain moves or types, using flags as condition references
      #structure: "flag" => [move or type]
      :field_changers => {}, #moves or types that change the field
      #structure: newField => [type or move]
      :change_message => {}, #message that shows when the field changes
      #structure => "message" => [type or move]
      :field_change_conditions => {} #optional conditions that your field can change under
      #example would be if your field can only change in certain weather
      #structure: newField => condition
      #note: condition must be a method that can be run to check if the conditions are met
      #major note: all things in brackets MUST stay in brackets when used in these sections, or the script
      #will fail
    },
    :Forest => {
      :field_name => "Forest",
      :intro_message => "The forest is dark.",
      :field_ebdx => :FOREST,
      :nature_power => :SILVERWIND,
      :mimicry => :BUG,
      :intro_script => nil,
      :abilities => [:SWARM],
      :ability_effects => {
      :SWARM => [[:ATTACK,1],[:SPECIAL_ATTACK,1]]
      },
      :move_damage_boost => {
      1.2 => [Fields::WIND_MOVES]
      },
      :move_messages => {"The forest bugs are riding the wind!" => [Fields::WIND_MOVES]},
      :move_type_change => {},
      :move_type_mod => {
        :BUG => [Fields::WIND_MOVES]
      },
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
      1.2 => [:BUG,:DARK]
      },
      :type_messages => {
        "The bugs of the forest joined in!" => [:BUG],
        "The darkness of the forest joined the attack!" => [:DARK]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {:Clear => Fields::IGNITE_MOVES},
      :change_message => {"The forest burned down!" => Fields::IGNITE_MOVES},
      :field_change_conditions => {:Clear => Fields.ignite?} 
    },
    :Garden => {
      :field_name => "Garden",
      :intro_message => "What a pretty garden...",
      :field_ebdx => :GARDEN,
      :nature_power => :ENERGYBALL,
      :mimicry => :GRASS,
      :intro_script => nil,
      :abilities => [:GRASSPELT,:FLOWERVEIL,:SAPSIPPER,:AROMAVEIL,:SWEETVEIL,:LEAFGUARD,:MEADOWRUSH],
      :ability_effects => {
      :FLOWERVEIL => [[:DEFENSE,1]],
      :AROMAVEIL => [[:DEFENSE,1]],
      :SWEETVEIL => [[:SPECIAL_DEFENSE,1]],
      :LEAFGUARD => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
      :GRASSPELT => [[:DEFENSE,1]]
      },
      :move_damage_boost => {
      1.2 => [Fields::WIND_MOVES]
      },
      :move_messages => {"The wind blew through the grass." => [Fields::WIND_MOVES]},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.3 => [:GRASS,:FAIRY,:BUG]
      },
      :type_messages => {"The field boosted the attack!" => [:GRASS,:BUG,:FAIRY]},
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {:Clear => Fields::IGNITE_MOVES},
      :change_message => {"The garden burned down!" => Fields::IGNITE_MOVES},
      :field_change_conditions => {:Clear => Fields.ignite?} 
    },
    :Grassy => {
      :field_name => "Grassy",
      :intro_message => "Grass covers the field.",
      :field_ebdx => :GRASSY,
      :nature_power => :ENERGYBALL,
      :mimicry => :GRASS,
      :intro_script => nil,
      :abilities => [:GRASSPELT,:SAPSIPPER,:LEAFGUARD,:MEADOWRUSH],
      :ability_effects => {
      :LEAFGUARD => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]]
      },
      :move_damage_boost => {
      1.2 => [Fields::WIND_MOVES],
      0.5 => [Fields::QUAKE_GRASSY]
      },
      :move_messages => {
        "The wind blew through the grass." => [Fields::WIND_MOVES],
        "The grass weakened the attack!" => [Fields::QUAKE_GRASSY]
      },
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.3 => [:GRASS]
      },
      :type_messages => {"The field boosted the attack!" => [:GRASS]},
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {
        :Wildfire => Fields::IGNITE_MOVES,
        :Clear => Fields::REMOVAL
      },
      :change_message => {
        "The field caught fire!" => Fields::IGNITE_MOVES,
        "The grass got blown away!" => Fields::REMOVAL
      },
      :field_change_conditions => {
        :Wildfire => Fields.ignite?,
        :Clear => true
      } 
    },
    :Electric => {
      :field_name => "Electric",
      :intro_message => "Electricity runs along the field.",
      :field_ebdx => :ELECTRIC,
      :nature_power => :THUNDERBOLT,
      :mimicry => :ELECTRIC,
      :intro_script => nil,
      :abilities => [:VOLTABSORB,:LIGHTNINGROD,:MOTORDRIVE,:QUARKDRIVE,:SURGESURFER,:STATIC],
      :ability_effects => {
        :STATIC => [[:DEFENSE,1]]
      },
      :move_damage_boost => {},
      :move_messages => {},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.3 => [:ELECTRIC]
      },
      :type_messages => {"The field powered the attack!" => [:ELECTRIC]},
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {
        :Clear => Fields::QUAKE_MOVES,
        :Clear => Fields::REMOVAL
      },
      :change_message => {
        "The field got stamped out!" => Fields::QUAKE_MOVES,
        "The electricity got blown away!" => Fields::REMOVAL
      },
      :field_change_conditions => {
        :Clear => true
      } 
    },
    :Wildfire => {
      :field_name => "Wildfire",
      :intro_message => "The field is ablaze.",
      :field_ebdx => :CHAMPION,
      :nature_power => :FLAMETHROWER,
      :mimicry => :FIRE,
      :intro_script => nil,
      :abilities => [:FLASHFIRE,:WELLBAKEDBODY,:THERMALEXCHANGE,:HEATPROOF,:MAGMAARMOR],
      :ability_effects => {
        :THERMALEXHCANGE => [[:ATTACK,1]],
        :HEATPROOF => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :MAGMAARMOR => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]]
      },
      :move_damage_boost => {
      1.2 => [Fields::WIND_MOVES]
      },
      :move_messages => {"The wind fueled the flames." => [Fields::WIND_MOVES]},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {},
      :type_messages => {},
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {
        :GRASS => :FIRE
      },
      :type_change_message => {
        "The grass caught fire!" => [:GRASS]
      },
      :type_accuracy_change => {},
      :side_effects => {"cinders" => Fields::WIND_MOVES},
      :field_changers => {:Clear => Fields::DOUSERS},
      :change_message => {"The wildfire was doused!" => Fields::DOUSERS},
      :field_change_conditions => {:Clear => Fields.douse?} 
    },
    :Misty => {
      :field_name => "Misty",
      :intro_message => "Mist swirled about the battlefield.",
      :field_ebdx => :MISTY,
      :nature_power => :MOONBLAST,
      :mimicry => :FAIRY,
      :intro_script => nil,
      :abilities => [:FAIRYBUBBLE,:ILLUSION,:CLOUDNINE],
      :ability_effects => {
        :FAIRYBUBBLE => [[:DEFENSE,1]],
        :ILLUSION => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :CLOUDNINE => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]]
      },
      :move_damage_boost => {},
      :move_messages => {},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        0.5 => [:DRAGON]
      },
      :type_messages => {"The mist weakened the attack!" => [:DRAGON]},
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {:Clear => Fields::REMOVAL},
      :change_message => {"The mist got blown away!" => Fields::REMOVAL},
      :field_change_conditions => {:Clear => true} 
    },
    :Psychic => {
      :field_name => "Psychic",
      :intro_message => "The field got weird.",
      :field_ebdx => :PSYCHIC,
      :nature_power => :PSYCHIC,
      :mimicry => :PSYCHIC,
      :intro_script => nil,
      :abilities => [],
      :ability_effects => {},
      :move_damage_boost => {},
      :move_messages => {},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.3 => [:PSYCHIC]
      },
      :type_messages => {"The terrain boosted the attack!" => [:PSYCHIC]},
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {:Clear => Fields::REMOVAL},
      :change_message => {"The weird terrain got blown away!" => Fields::REMOVAL},
      :field_change_conditions => {
        :Clear => true
      } 
    },
    :Poison => {
      :field_name => "Poison",
      :intro_message => "The field is covered with toxic waste.",
      :field_ebdx => :POISON,
      :nature_power => :DEATHTOLL,
      :mimicry => :POISON,
      :intro_script => nil,
      :abilities => [:POISONPOINT,:POISONTOUCH,:FEVERPITCH,:CORROSION,:NITRIC,:SLUDGERUSH,:TOXICRUSH],
      :ability_effects => {
        :POISONPOINT => [[:DEFENSE,1]],
        :POISONTOUCH => [[:ATTACK,1]],
        :FEVERPITCH => [[:SPECIAL_ATTACK,1],[:SPECIAL_DEFENSE,1]],
        :CORROSION => [[:SPECIAL_ATTACK,1]],
        :NITRIC => [[:ATTACK,1],[:SPECIAL_ATTACK,1]]
      },
      :move_damage_boost => {},
      :move_messages => {},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.3 => [:POISON]
      },
      :type_messages => {"The toxic waste boosted the attack!" => [:POISON]},
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {
        :Wildfire => Fields::IGNITE_MOVES,
        :Clear => Fields::REMOVAL},
      :change_message => {
        "The toxic waste caught fire!" => Fields::IGNITE_MOVES,
        "The toxic waste got blown away!" => Fields::REMOVAL},
      :field_change_conditions => {
        :Wildfire => Fields.ignite?,
        :Clear => true
      } 
    },
    :EchoChamber => {
      :field_name => "Cave",
      :intro_message => "A dull echo hums...",
      :field_ebdx => :DARKCAVE,
      :nature_power => :HYPERVOICE,
      :mimicry => :NORMAL,
      :intro_script => nil,
      :abilities => [:SOUNDPROOF,:CACOPHONY,:PUNKROCK,:LIQUIDVOICE],
      :ability_effects => {
        :SOUNDPROOF => [[:SPECIAL_DEFENSE,1]],
        :CACOPHONY => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :PUNKROCK => [[:SPECIAL_ATTACK,1]],
        :LIQUIDVOICE => [[:SPECIAL_ATTACK,1]]
      },
      :move_damage_boost => {
        1.0 => [Fields::ECHO_MOVES]
      },
      :move_messages => {"The cave echoed loudly!" => [Fields::ECHO_MOVES]},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:ROCK,:DARK,:GHOST],
        0.8 => [:FIRE,:GRASS]
      },
      :type_messages => {
        "The cave boosted the attack!" => [:ROCK],
        "The cave darkness boosted the attack!" => [:DARK,:GHOST],
        "The cave darkness weakened the attack!" => [:FIRE,:GRASS]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {},
      :change_message => {},
      :field_change_conditions => {} 
    },
    :Desert => {
      :field_name => "Desert",
      :intro_message => "The sand is everywhere...",
      :field_ebdx => :DESERT,
      :nature_power => :EARTHPOWER,
      :mimicry => :GROUND,
      :intro_script => nil,
      :abilities => [:SANDRUSH,:SANDVEIL,:SANDFORCE],
      :ability_effects => {},
      :move_damage_boost => {
      1.2 => [Fields::WIND_MOVES]
      },
      :move_messages => {"The sand kicked up!" => [Fields::WIND_MOVES]},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:FIRE,:GROUND],
        0.8 => [:WATER,:GRASS]
      },
      :type_messages => {
        "The desert boosted the attack!" => [:GROUND,:FIRE],
        "The desert weakened the attack!" => [:WATER,:GRASS]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {"sand" => Fields::WIND_MOVES},
      :field_changers => {},
      :change_message => {},
      :field_change_conditions => {} 
    },
    :Ruins => {
      :field_name => "Ruins",
      :intro_message => "A mysterious presence surrounds you...",
      :field_ebdx => :TEMPLE,
      :nature_power => :PSYCHIC,
      :mimicry => :PSYCHIC,
      :intro_script => nil,
      :abilities => [:MAGICGUARD,:MAGICBOUNCE,:POWERSPOT,:UNKNOWNPOWER,:WONDERSKIN,:NEUROFORCE],
      :ability_effects => {
        :MAGICGUARD => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :MAGICBOUNCE => [[:SPEED,1]],
        :POWERSPOT => [[:ATTACK,1],[:SPECIAL_ATTACK,1]],
        :NEUROFORCE => [[:ATTACK,1],[:SPECIAL_ATTACK,1]],
        :UNKNOWNPOWER => [[:ATTACK,1],[:SPECIAL_ATTACK,1],[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :WONDERSKIN => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]]
      },
      :move_damage_boost => {},
      :move_messages => {},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {
        2 => [:PSYCHIC,"fullhp"]
      },
      :type_damage_change => {
        1.2 => [:PSYCHIC,:FIRE,:GRASS,:WATER]
      },
      :type_messages => {
        "The ruins boosted the attack!" => [:PSYCHIC,:FIRE,:GRASS,:WATER]
      },
      :type_type_mod => {
        :ROCK => :PSYCHIC
      },
      :type_mod_message => {
        "The rubble joined the telekenetic strike!" => :PSYCHIC
      },
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {:Clear => Fields::QUAKE_MOVES},
      :change_message => {"The quake leveled the ruins!" => Fields::QUAKE_MOVES},
      :field_change_conditions => {:Clear => true} 
    },
    :Swamp => {
      :field_name => "Swamp",
      :intro_message => "The swamp feels unstable...",
      :field_ebdx => :MOUNTAINLAKE,
      :nature_power => :SLUDGEWAVE,
      :mimicry => :POISON,
      :intro_script => nil,
      :abilities => [:POISONPOINT,:POISONTOUCH,:FEVERPITCH,:CORROSION,:NITRIC,:SLUDGERUSH,:TOXICRUSH,:POISONHEAL,:TOXICBOOST],
      :ability_effects => {
        :POISONPOINT => [[:DEFENSE,1]],
        :POISONTOUCH => [[:ATTACK,1]],
        :FEVERPITCH => [[:SPECIAL_ATTACK,1],[:SPECIAL_DEFENSE,1]],
        :CORROSION => [[:SPECIAL_ATTACK,1]],
        :NITRIC => [[:ATTACK,1],[:SPECIAL_ATTACK,1]]
      },
      :move_damage_boost => {},
      :move_messages => {},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:WATER,:GRASS,:POISON],
        0.8 => [:FIRE,:ROCK,:FIGHTING]
      },
      :type_messages => {
        "The swamp boosted the attack!" => [:WATER,:GRASS,:POISON],
        "The swamp weakened the attack!" => [:FIGHTING,:FIRE,:ROCK]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {
        0 => [:WATER,:POISON]
      },
      :side_effects => {},
      :field_changers => {:Clear => Fields::SWAMP_REMOVAL},
      :change_message => {"The rocks filled in the swamp!" => Fields::SWAMP_REMOVAL},
      :field_change_conditions => {:Clear => true} 
    },
    :Lava => {
      :field_name => "Lava",
      :intro_message => "Lava flows underfoot...",
      :field_ebdx => :MAGMA,
      :nature_power => :LAVAPLUME,
      :mimicry => :FIRE,
      :intro_script => nil,
      :abilities => [:FLASHFIRE,:WELLBAKEDBODY,:THERMALEXCHANGE,:HEATPROOF,:MAGMAARMOR,:STEAMENGINE,:SOLARPOWER,:PROTOSYNTHESIS,:STEAMPOWERED],
      :ability_effects => {
        :THERMALEXHCANGE => [[:ATTACK,1]],
        :HEATPROOF => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :MAGMAARMOR => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :SOLARPOWER => [[:SPECIAL_ATTACK,1]],
        :STEAMPOWERED => [[:SPECIAL_ATTACK,1]]
      },
      :move_damage_boost => {
        0.0 => [Fields::WEAK_WATER],
        0.8 => [Fields::STRONG_WATER]
      },
      :move_messages => {
        "The water fizzled out!" => [Fields::WEAK_WATER],
        "The lava evaporated some of the water!" => [Fields::STRONG_WATER]
      },
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:FIRE],
        0.8 => [:ICE]
      },
      :type_messages => {
        "The lava boosted the heat!" => [:FIRE],
        "The ice melted!" => [:ICE]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {
        :ICE => :WATER
      },
      :type_change_message => {
        "The heat weakened the water" => [:ICE]
      },
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {
        :Mountainside => Fields::SWAMP_REMOVAL,
        :Clear => Fields::LAVA_REMOVAL
      },
      :change_message => {
        "The lava flow was stopped!" => Fields::SWAMP_REMOVAL,
        "The lava was cooled by the water!" => Fields::LAVA_REMOVAL
      },
      :field_change_conditions => {
        :Clear => Fields.douse?,
        :Mountainside => true
      } 
    },
    :SnowyMountainside => {
      :field_name => "Snowy Mountainside",
      :intro_message => "A chilling wind blows by...",
      :field_ebdx => :SNOWYMOUNTAIN,
      :nature_power => :ICE,
      :mimicry => :BLIZZARD,
      :intro_script => nil,
      :abilities => [:SLUSHRUSH,:SNOWCLOAK,:ICEBODY],
      :ability_effects => {
        :SNOWCLOAK => [[:DEFENSE,1]]
      },
      :move_damage_boost => {
      1.2 => [Fields::WIND_MOVES]
      },
      :move_messages => {
        "The chilling winds kicked up!" => [Fields::WIND_MOVES],
        "The rocks picked up ice!" => [[:ROCKSLIDE]],
        "AVALANCHE!" => [Fields::ECHO_MOVES]
      },
      :move_type_change => {},
      :move_type_mod => {
        :ICE => [[:ROCKSLIDE],Fields::ECHO_MOVES]
      },
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:ICE,:ROCK]},
      :type_messages => {
        "The frozen mountain boosted the attack!" => [:ICE]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {},
      :change_message => {},
      :field_change_conditions => {} 
    },
    :Mountainside => {
      :field_name => "Mountainside",
      :intro_message => "These rocks seem unsteady...",
      :field_ebdx => :MOUNTAIN,
      :nature_power => :ROCK,
      :mimicry => :ROCKSLIDE,
      :intro_script => nil,
      :abilities => [:SCALER,:SPLINTER,:SOLIDROCK,:ROCKHEAD],
      :ability_effects => {
        :SCALER => [[:DEFENSE,1]],
        :SPLINTER => [[:SPECIAL_DEFENSE,1]],
        :SOLIDROCK => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :ROCKHEAD => [[:ATTACK,1]]
      },
      :move_damage_boost => {
      1.2 => [Fields::QUAKE_MOVES]
      },
      :move_messages => {
        "LANDSLIDE!" => [Fields::QUAKE_MOVES]},
      :move_type_change => {},
      :move_type_mod => {
        :ROCK => [Fields::QUAKE_MOVES]
      },
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:ROCK]},
      :type_messages => {
        "The mountain boosted the attack!" => [:ROCK]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {},
      :change_message => {},
      :field_change_conditions => {} 
    },
    :City => {
      :field_name => "City",
      :intro_message => "The city hums with activity...",
      :field_ebdx => :OUTDOOR,
      :nature_power => :STEEL,
      :mimicry => :MAGNETBOMB,
      :intro_script => nil,
      :abilities => [:STEELWORKER,:FULLMETALBODY,:IRONFIST,:LIGHTNINGROD,:CACOPHONY],
      :ability_effects => {
        :STEELWORKER => [[:ATTACK,1]],
        :FULLMETALBODY => [[:DEFENSE,1]],
        :IRONFIST => [[:ATTACK,1]],
        :CACOPHONY => [[:SPECIAL_DEFENSE,1]]
      },
      :move_damage_boost => {
        1.5 => [Fields::OUTAGE_MOVES]
      },
      :move_messages => {
        "The city lights boosted the attack!" => [Fields::OUTAGE_MOVES]},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {},
      :type_messages => {},
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {
        :Clear => Fields::QUAKE_MOVES,
        :Wildfire => Fields::IGNITE_MOVES,
        :Outage => Fields::OUTAGE_MOVES
      },
      :change_message => {
        "The city came crashing down!" => Fields::QUAKE_MOVES,
        "The city caught fire!" => Fields::IGNITE_MOVES,
        "Power outage!" => Fields::OUTAGE_MOVES
      },
      :field_change_conditions => {
        :Wildfire => Fields.ignite?,
        :Clear => true,
        :Outage => true
      } 
    },
    :Outage => {
      :field_name => "Outage",
      :intro_message => "The power's out...",
      :field_ebdx => :CITYNIGHT,
      :nature_power => :DARK,
      :mimicry => :DARKPULSE,
      :intro_script => nil,
      :abilities => [:NOCTEMBOOST,:DARKAURA],
      :ability_effects => {
        :DARKAURA => [[:SPECIAL_ATTACK,1]]
      },
      :move_damage_boost => {},
      :move_messages => {},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:DARK,:GHOST]
      },
      :type_messages => {
        "The darkness joined the attack" => [:DARK,:GHOST]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {
        :Clear => Fields::QUAKE_MOVES,
        :Wildfire => Fields::IGNITE_MOVES,
        :City => Fields::RECHARGE_MOVES
      },
      :change_message => {
        "The city came crashing down!" => Fields::QUAKE_MOVES,
        "The city caught fire!" => Fields::IGNITE_MOVES,
        "The electricity recharged the city!" => Fields::RECHARGE_MOVES
      },
      :field_change_conditions => {
        :Wildfire => Fields.ignite?,
        :Clear => true,
        :City => true
      } 
    },
    :DragonsDen => {
      :field_name => "Dragon's Den",
      :intro_message => "You feel a powerful aura...",
      :field_ebdx => :DRAGONSDEN,
      :nature_power => :DRAGONPULSE,
      :mimicry => :DRAGON,
      :intro_script => nil,
      :abilities => [:DRAGONSMAW,:THERMALEXCHANGE,:FLASHFIRE,:WELLBAKEDODY,:LEGENDARMOR,:HEATPROOF],
      :ability_effects => {
        :DRAGONSMAW => [[:ATTACK,1],[:SPECIAL_ATTACK,1]],
        :THERMALEXCHANGE => [[:ATTACK,1]],
        :HEATPROOF => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]]
      },
      :move_damage_boost => {},
      :move_messages => {},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {
        2 => [:DRAGON,"fullhp"]
      },
      :type_damage_change => {
        1.3 => [:DRAGON,:FIRE]
      },
      :type_messages => {
        "The power of the ancients amplified the attack!" => [:DRAGON,:FIRE]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {},
      :change_message => {},
      :field_change_conditions => {} 
    },
    :Water => {
      :field_name => "Water",
      :intro_message => "The waves are crashing around you.",
      :field_ebdx => :WATER,
      :nature_power => :SURF,
      :mimicry => :WATER,
      :intro_script => nil,
      :abilities => [:SWIFTSWIM,:STORMDRAIN,:WATERCOMPACTION,:STEAMENGINE,:WATERABSORB,:DRYSKIN],
      :ability_effects => {},
      :move_damage_boost => {
        1.2 => [Fields::WIND_MOVES]
      },
      :move_messages => {
        "The wind rushed over the water!" => [Fields::WIND_MOVES]
      },
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:WATER,:ELECTRIC],
        0.8 => [:FIRE]
      },
      :type_messages => {
        "The water weakened the attack!" => [:FIRE],
        "The waves joined the attack!" => [:WATER],
        "Electricity flowed through the water!" => [:ELECTRIC]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {"hurricane" => Fields::HURRICANE_MOVES},
      :field_changers => {:Underwater => Fields::UNDERWATER_MOVES},
      :change_message => {"The battle moved underwater!" => Fields::UNDERWATER_MOVES},
      :field_change_conditions => {:Underwater => true} 
    },
    :Underwater => {
      :field_name => "Underwater",
      :intro_message => "Bloop bloop...",
      :field_ebdx => :UNDERWATER,
      :nature_power => :WATERPULSE,
      :mimicry => :WATER,
      :intro_script => nil,
      :abilities => [:SWIFTSWIM,:STORMDRAIN,:WATERCOMPACTION,:STEAMENGINE,:WATERABSORB,:DRYSKIN],
      :ability_effects => {},
      :move_damage_boost => {
        1.5 => [Fields::PULSE_MOVES],
        1.2 => [Fields::SOUND_MOVES],
        0.8 => [Fields::PUNCHING_MOVES,Fields::KICKING_MOVES,Fields::WIND_MOVES]
      },
      :move_messages => {
        "The water slowed the attack!" => [Fields::PUNCHING_MOVES,Fields::KICKING_MOVES,Fields::WIND_MOVES],
        "The sound reverberated strongly through the water!" => [Fields::SOUND_MOVES],
        "Underwater pressure gave a massive boost!" => [Fields::PULSE_MOVES]
      },
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:WATER,:ELECTRIC],
        0.8 => [:BUG,:FIGHTING],
        0.0 => [:FIRE]
      },
      :type_messages => {
        "The water doused the attack!" => [:FIRE],
        "The water joined the attack!" => [:WATER],
        "The water slowed the attack!" => [:BUG,:FIGHTING],
        "Electricity flowed through the water!" => [:ELECTRIC]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {:Water => [:DIVE]},
      :change_message => {"The battle moved above water!" => [:DIVE]},
      :field_change_conditions => {:Water => true} 
    },
    :Dream => {
      :field_name => "Dream",
      :intro_message => "It's never quite as it seems...",
      :field_ebdx => :DREAM,
      :nature_power => :DREAMEATER,
      :mimicry => :PSYCHIC,
      :intro_script => "dream",
      :abilities => [:BADDREAMS,:BRAINBLAST,:NEUROFORCE,:MINDGAMES],
      :ability_effects => {
        :NEUROFORCE => [[:SPECIAL_ATTACK,1]],
        :MINDGAMES => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :BADDREAMS => [[:SPECIAL_ATTACK,1]]
      },
      :move_damage_boost => {
        1.3 => [:PAYBACK,:REVENGE]
      },
      :move_messages => {
        "Only in your dreams..." => [:PAYBACK,:REVENGE]
      },
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:PSYCHIC,:DARK]
      },
      :type_messages => {
        "Such sweet dreams..." => [:PSYCHIC],
        "A horrible nightmare!" => [:DARK]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {},
      :change_message => {},
      :field_change_conditions => {} 
    },
    :Icy => {
      :field_name => "Icy",
      :intro_message => "Caution! Thin ice!",
      :field_ebdx => :ICY,
      :nature_power => :ICEBEAM,
      :mimicry => :ICE,
      :intro_script => nil,
      :abilities => [:ICEBODY,:SLUSHRUSH,:SNOWCLOAK],
      :ability_effects => {
        :SNOWCLOAK => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
      },
      :move_damage_boost => {},
      :move_messages => {},
      :move_type_change => {
        :ICE => Fields::WEAK_WATER + Fields::STRONG_WATER
      },
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:ICE]
      },
      :type_messages => {
        "A biting chill joins the attack!" => [:ICE]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {
        :Water => Fields::MELT_MOVES,
        :Clear => Fields::SWAMP_REMOVAL
      },
      :change_message => {
        "The ice melted!" => Fields::MELT_MOVES,
        "The ice broke!" => Fields::SWAMP_REMOVAL
      },
      :field_change_conditions => {
        :Water => Fields.melt?,
        :Clear => Fields.melt?
      } 
    },
    :Magnetic => {
      :field_name => "Magnetic",
      :intro_message => "The field is magnetized.",
      :field_ebdx => :MAGNETIC,
      :nature_power => :PARABOLICCHARGE,
      :mimicry => :ELECTRIC,
      :intro_script => nil,
      :abilities => [:VOLTABSORB,:LIGHTNINGROD,:MOTORDRIVE,:QUARKDRIVE,:MAGNETPULL,:BATTERY,:PLUS,:MINUS,:SURGESURFER],
      :ability_effects => {
        :MAGNETPULL => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :BATTERY => [[:SPECIAL_ATTACK,1],[:SPEED,1]],
        :PLUS => [[:SPECIAL_ATTACK,1]],
        :MINUS => [[:SPECIAL_ATTACK,1]]
      },
      :move_damage_boost => {},
      :move_messages => {},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.3 => [:ELECTRIC,:STEEL]
      },
      :type_messages => {"The field powered the attack!" => [:ELECTRIC,:STEEL]},
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {
        :Clear => Fields::MAGNET_REMOVAL
      },
      :change_message => {
        "The field got demagnetized!" => Fields::MAGNET_REMOVAL
      },
      :field_change_conditions => {:Clear => true} 
    },
    :Mirror => {
      :field_name => "Mirror",
      :intro_message => "All around me are familiar faces...",
      :field_ebdx => :MIRROR,
      :nature_power => :FLASHCANNON,
      :mimicry => :STEEL,
      :intro_script => nil,
      :abilities => [:TIGHTFOCUS,:MIRRORARMOR,:FULLMETALBODY,:CLEARBODY,:UNSHAKEN,:ILLUMINATE],
      :ability_effects => {
        :MIRRORARMOR => [[:SPECIAL_DEFENSE,1]],
        :FULLMETALBODY => [[:DEFENSE,1]],
        :CLEARBODY => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :UNSHAKEN => [[:ATTACK,1],[:SPECIAL_ATTACK,1]]
      },
      :move_damage_boost => {
        1.3 => [Fields::SPECIAL_STEEL],
        1.0 => [Fields::RICOCHET_MOVES]
      },
      :move_messages => {
        "The mirror boosted the attack!" => [Fields::SPECIAL_STEEL],
        "The mirror ricocheted the attack!" => [Fields::RICOCHET_MOVES]
      },
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.3 => [:PSYCHIC]
      },
      :type_messages => {"The mirror amplified the psychic energy!" => [:PSYCHIC]},
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {
        :Clear => Fields::SWAMP_REMOVAL
      },
      :change_message => {
        "The mirror shattered!" => Fields::SWAMP_REMOVAL
      },
      :field_change_conditions => {:Clear => true} 
    },
    :Space => {
      :field_name => "Space",
      :intro_message => "The final frontier...",
      :field_ebdx => :SPACE,
      :nature_power => :STARBEAM,
      :mimicry => :COSMIC,
      :intro_script => nil,
      :abilities => [:ASTRALCLOAK,:STARSALVE,:NOCTEMBOOST,:STARSPRINT],
      :ability_effects => {
        :ASTRALCLOAK => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]]
      },
      :move_damage_boost => {
        0.0 => [Fields::SOUND_MOVES]
      },
      :move_messages => {
        "The sound dissipated!" => [Fields::SOUND_MOVES]
      },
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:COSMIC,:DARK],
        0.8 => [:ROCK,:FIRE]
      },
      :type_messages => {
        "The stars join the attack!" => [:COSMIC],
        "The darkness is overwhelming!" => [:DARK],
        "The lack of gravity weakened the attack!" => [:ROCK],
        "The fire got stifled without air!" => [:FIRE]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {},
      :change_message => {},
      :field_change_conditions => {} 
    },
    :Digital => {
      :field_name => "Digital",
      :intro_message =>"Beep boop boop beep bop...",
      :field_ebdx => :DISCO,
      :nature_power => :TRIATTACK,
      :mimicry => :NORMAL,
      :intro_script => nil,
      :abilities => [:VOLTABSORB,:LIGHTNINGROD,:MOTORDRIVE,:QUARKDRIVE,:SURGESURFER,:DOWNLOAD],
      :ability_effects => {},
      :move_damage_boost => {1.3 => [[:SPAMRAID]]},
      :move_messages => {
        "ERROR: VIRUS DETECTED" => [[:SPAMRAID]]
      },
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:ELECTRIC,:NORMAL]
      },
      :type_messages => {
        "The field powered the attack!" => [:ELECTRIC,:NORMAL]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {
        :Clear => Fields::SHORT_MOVES
      },
      :change_message => {
        "The field shorted out!" => Fields::SHORT_MOVES
      },
      :field_change_conditions => {:Clear => true} 
    },
    :Dojo => {
      :field_name => "Dojo",
      :intro_message =>"You can feel the focus...",
      :field_ebdx => :INDOOR,
      :nature_power => :DRAINPUNCH,
      :mimicry => :FIGHTING,
      :intro_script => nil,
      :abilities => [:INNERFOCUS,:STEADFAST,:IRONFIST],
      :ability_effects => {
        :STEADFAST => [[:SPEED,1]]
      },
      :move_damage_boost => {
        1.2 => [Fields::SOUND_MOVES]
      },
      :move_messages => {
        "Concentration broken!" => [Fields::SOUND_MOVES]
      },
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {
        1.2 => [:FIGHTING,nil],
      },
      :type_damage_change => {
        1.2 => [:FIGHTING,:PSYCHIC]
      },
      :type_messages => {
        "The power of focus!" => [:FIGHTING,:PSYCHIC]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {
        :Clear => Fields::QUAKE_MOVES
      },
      :change_message => {
        "The dojo was leveled!" => Fields::QUAKE_MOVES
      },
      :field_change_conditions => {:Clear => true} 
    },
    :Distortion => {
      :field_name => "Distortion",
      :intro_message => "Everything feels wrong here...",
      :field_ebdx => :DIMENSION,
      :nature_power => :ASTRALGALE,
      :mimicry => :COSMIC,
      :intro_script => "distortion",
      :abilities => [:STARSALVE,:DISGUISE,:PRANKSTER,:IMPOSTER,:STARSPRINT],
      :ability_effects => {
        :DISGUISE => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :IMPOSTER => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :PRANKSTER => [[:SPEED,1]]
      },
      :move_damage_boost => {},
      :move_messages => {},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {
        90 => [:DARKVOID]
      },
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:COSMIC,:DARK,:DRAGON],
        0.8 => [:PSYCHIC,:FAIRY,:FIGHTING]
      },
      :type_messages => {
        "The void joins the attack!" => [:COSMIC,:DARK],
        "The ancient power draws power from the distortion!" => [:DRAGON],
        "The distortion weakened the attack!" => [:PSYCHIC,:FAIRY,:FIGHTING]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {},
      :change_message => {},
      :field_change_conditions => {} 
    },
    :WindTunnel => {
      :field_name => "Wind Tunnel",
      :intro_message => "Air steadily flows around you...",
      :field_ebdx => :WINDTUNNEL,
      :nature_power => :AIRCANNON,
      :mimicry => :FLYING,
      :intro_script => "wind",
      :abilities => [:WINDPOWER,:WINDRIDER,:BACKDRAFT],
      :ability_effects => {},
      :move_damage_boost => {
        1.2 => [Fields::WIND_MOVES,Fields::KICKING_MOVES]
      },
      :move_messages => {
        "The wind gave the move momentum!" => [Fields::KICKING_MOVES],
        "A backdraft is blowing!" => [Fields::WIND_MOVES]
      },
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:FLYING,:ICE]
      },
      :type_messages => {
        "The wind pushes the attack!" => [:FLYING],
        "An extra chill!" => [:ICE]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {},
      :change_message => {},
      :field_change_conditions => {} 
    },
    :DarkRoom => {
      :field_name => "Dark Room",
      :intro_message => "The room has a low light.",
      :field_ebdx => :DARKNESS,
      :nature_power => :DARKPULSE,
      :mimicry => :DARK,
      :intro_script => nil,
      :abilities => [:NOCTEMBOOST,:DARKAURA,:PRANKSTER,:IMPOSTER],
      :ability_effects => {
        :DARKAURA => [[:SPECIAL_ATTACK,1]],
        :PRANKSTER => [[:SPEED,1]],
        :IMPOSTER => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]]
      },
      :move_damage_boost => {
        1.3 => [Fields::LIGHT_MOVES]
      },
      :move_messages => {
        "Too bright!" => [Fields::LIGHT_MOVES]
      },
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:DARK,:GHOST],
        0.8 => [:PSYCHIC,:FAIRY,:GRASS]
      },
      :type_messages => {
        "The darkness joined the attack" => [:DARK,:GHOST],
        "The darkness choked out the attack." => [:PSYCHIC,:FAIRY,:GRASS]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {
        :Clear => Fields::LIGHT_MOVES,
      },
      :change_message => {
        "The lights came on!" => Fields::LIGHT_MOVES
      },
      :field_change_conditions => {:Clear => Fields.light?} 
    },
    :FairyLights => {
      :field_name => "Fairy Lights",
      :intro_message => "Pretty sparkly lights all around...",
      :field_ebdx => :FAIRYLIGHTS,
      :nature_power => :DAZZLINGGLEAM,
      :mimicry => :FAIRY,
      :intro_script => nil,
      :abilities => [:ILLUMINATE,:DAZZLING,:FAIRYAURA,:FAIRYBUBBLE,:SHIELDDUST,:MAGICGUARD],
      :ability_effects => {
        :FAIRYAURA => [[:SPECIAL_ATTACK,1]],
        :ILLUMINATE => [[:SPEED,1]],
        :DAZZLING => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :FAIRYBUBBLE => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :MAGICGUARD => [[:SPECIAL_DEFENSE,1]],
        :SHIELDDUST => [[:DEFENSE,1]]
      },
      :move_damage_boost => {
        1.3 => [Fields::FAIRY_LIGHTS_MOVES]
      },
      :move_messages => {},
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:FAIRY],
        0.8 => [:DARK,:GHOST]
      },
      :type_messages => {
        "The sparkles are blinding!" => [:FAIRY],
        "The lights overpower the darkness!" => [:DARK,:GHOST]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {:Clear => Fields::FAIRY_LIGHTS_REMOVAL},
      :change_message => {"The lights were snuffed out!" => Fields::FAIRY_LIGHTS_REMOVAL},
      :field_change_conditions => {:Clear => true} 
    },
    :Castle => {
      :field_name => "Castle",
      :intro_message => "The castle walls stand strong.",
      :field_ebdx => :CASTLE,
      :nature_power => :TWINBLADES,
      :mimicry => :STEEL,
      :intro_script => nil,
      :abilities => [:FILTER,:PRISMARMOR,:BATTLEARMOR,:SHELLARMOR,:QUEENLYMAJESTY],
      :ability_effects => {},
      :move_damage_boost => {
        1.2 => [Fields::SLICING_MOVES]
      },
      :move_messages => {
        "The blade meets its target!" => [Fields::SLICING_MOVES]
      },
      :move_type_change => {},
      :move_type_mod => {},
      :move_accuracy_change => {},
      :defensive_modifiers => {},
      :type_damage_change => {
        1.2 => [:ROCK,:STEEL,:PSYCHIC,:FAIRY,:COSMIC],
        0.8 => [:DRAGON,:FIGHTING]
      },
      :type_messages => {
        "The fortress imbued power into the attack!" => [:ROCK,:STEEL,:PSYCHIC,:FAIRY,:COSMIC],
        "The fortress is well guarded!" => [:DRAGON,:FIGHTING]
      },
      :type_type_mod => {
        :COSMIC => :ROCK
      },
      :type_mod_message => {
        "Nearby meteorites and runes joined the attack!" => :ROCK
      },
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {},
      :field_changers => {},
      :change_message => {},
      :field_change_conditions => {} 
    },
    :Graveyard => {
      :field_name => "Graveyard",
      :intro_message => "The headstones are watching...",
      :field_ebdx => :GRAVEYARD,
      :nature_power => :SHADOWBALL,
      :mimicry => :GHST,
      :intro_script => nil,
      :abilities => [:CURSEDBODY,:PERISHBODY,:HAUNTED,:SHADOWGUARD,:SHADOWTAG],
      :ability_effects => {
        :CURSEDBODY => [[:DEFENSE,1]],
        :PERISHBODY => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]],
        :HAUNTED => [[:SPECIAL_ATTACK,1]],
        :SHADOWGUARD => [[:SPECIAL_DEFENSE,1]],
        :SHADOWTAG => [[:DEFENSE,1],[:SPECIAL_DEFENSE,1]]
      },
      :move_damage_boost => {},
      :move_messages => {
        "The wind is haunting!" => [Fields::WIND_MOVES]
      },
      :move_type_change => {},
      :move_type_mod => {
        :GHOST => [Fields::WIND_MOVES]
      },
      :move_accuracy_change => {},
      :defensive_modifiers => {
        2 => [:GHOST,"fullhp"]
      },
      :type_damage_change => {
        1.2 => [:GHOST,:DARK,:GROUND],
        0.8 => [:PSYCHIC,:FAIRY,:FIGHTING]
      },
      :type_messages => {
        "The graveyard boosted the attack!" => [:GHOST,:DARK,:GROUND],
        "The crippling fear weakens the attack!" => [:PSYCHIC,:FAIRY,:FIGHTING]
      },
      :type_type_mod => {},
      :type_mod_message => {},
      :type_type_change => {},
      :type_change_message => {},
      :type_accuracy_change => {},
      :side_effects => {"spirits" => [Fields::QUAKE_MOVES]},
      :field_changers => {},
      :change_message => {},
      :field_change_conditions => {} 
    },
  }