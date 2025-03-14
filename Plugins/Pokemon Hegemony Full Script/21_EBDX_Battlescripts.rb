module BattleScripts
  def self.pbSetFieldEffect(terrain,sprites)
    fe = FIELD_EFFECTS[terrain]
    gfx = fe[:field_ebdx]
    data = getConst(EnvironmentEBDX, gfx)
    sprites["battlebg"].reconfigure(data,Color.white)
  end
  #============
  #Mini Bosses
  #============
  HELUM = {
    "turnStart0" => proc do
        @scene.pbAnimation(GameData::Move.get(:GRASSYTERRAIN).id,@battle.battlers[1],@battle.battlers[1])
        @sprites["battlebg"].reconfigure(:GRASSY, Color.white)
        @battle.field.terrain = :Grassy
        @battle.field.terrainDuration = -1
        $gym_gimmick = true
        @scene.pbDisplay("The battlefield got permanently grassy!")
    end
  }
  OGAN = {
    "turnStart0" => proc do
        $gym_hazard = true
        @scene.pbAnimation(GameData::Move.get(:AURORAVEIL).id,@battle.battlers[1],@battle.battlers[1])
        @scene.pbDisplay("A mysterious force prevents hazard removal!")
    end
  }
  NEONN = {
    "turnStart0" => proc do
        @scene.pbAnimation(GameData::Move.get(:WISH).id,@battle.battlers[1],@battle.battlers[1])
        @battle.field.weather = :Starstorm
        @battle.field.weatherDuration = -1
        $gym_weather = true
        @scene.pbDisplay("Stars permanently filled the sky!")
        @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange}
    end
  }

  PSYCHICTERRAIN = {
    "turnStart0" => proc do 
      if $game_switches[LvlCap::Expert]
        @scene.pbAnimation(GameData::Move.get(:PSYCHICTERRAIN).id,@battle.battlers[1],@battle.battlers[1])
        @battle.field.terrain = :Psychic
        @battle.field.terrainDuration = -1
        $gym_terrain  = true
        @scene.pbDisplay("The trainer set permanent Psychic Terrain!")
      end
    end
  }

  NITRO = {
    "turnStart0" => proc do
        @scene.pbAnimation(GameData::Move.get(:TAILWIND).id,@battle.battlers[1],@battle.battlers[1])
        @battle.battlers[1].pbOwnSide.effects[PBEffects::Tailwind] = 1
        $gym_tailwind = true
        @scene.pbDisplay("A permanent Tailwind blew in behind the opponent's team!")
    end
  }

  KRYPTO = {
    "turnStart0" => proc do
        @scene.pbAnimation(GameData::Move.get(:TAILWIND).id,@battle.battlers[1],@battle.battlers[1])
        @battle.field.weather = :StrongWinds
        $gym_weather = true
        @scene.pbDisplay("A Delta Stream brewed!")
        @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange}
    end
  }

  CHLOROS = {
    "turnStart0" => proc do
        @scene.pbAnimation(GameData::Move.get(:PSYCHICTERRAIN).id,@battle.battlers[1],@battle.battlers[1])
        @sprites["battlebg"].reconfigure(:PSYCHIC, Color.white)
        @battle.field.terrain = :Psychic
        @battle.field.terrainDuration = -1
        @battle.field.effects[PBEffects::TrickRoom] = 1
        $gym_gimmick = true
        @scene.pbDisplay("The battlefield got permanently weird!")
        @scene.pbDisplay("The dimensions were permanently twisted!")
    end
}

  CAPITOL = {
    "turnStart0" => proc do
          @scene.pbAnimation(GameData::Move.get(:SLUDGEWAVE).id,@battle.battlers[1],@battle.battlers[1])
          @sprites["battlebg"].reconfigure(:POISON, Color.white)
          @battle.field.terrain = :Poison
          @battle.field.terrainDuration = -1
          $gym_gimmick = true
          @scene.pbAnimation(GameData::Move.get(:RAINDANCE).id,@battle.battlers[1],@battle.battlers[1])
          @battle.field.weather = :AcidRain
          @battle.field.weatherDuration = -1
          $gym_weather = true
          @scene.pbDisplay("The battlefield got permanently toxic!")
    end
  }
  BOSSPOKEMON = {
    "turnStart0" => proc do
        # hide databoxes
        @scene.pbHideAllDataboxes
        # show flavor text
        EliteBattle.playCommonAnimation(:AURAFLARE, @scene, 1)
        @vector.reset # AURAFLARE doesn't reset the vector by default
        @scene.wait(16, true) # set true to anchor the sprites to vector
        # raise battler Attack sharply (doesn't display text)
        @scene.pbDisplay("It's a boss Pokémon!")
        @scene.wait(16)
        # play common animation
        EliteBattle.playCommonAnimation(:ROAR, @scene, 1)
        @scene.wait(8)
        $game_switches[908] = true
        # show databoxes
        @scene.pbShowAllDataboxes
      end
  }
  #============
  #Gym Leaders
  #============
  TURNER = {
    "afterLastOpp" => "My last Pokémon. Time to switch up my approach!",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("Let's see just how prepared you are!")
    end
  }

  HAZEL = {
    "afterLastOpp" => "Hmm, my last Pokémon...",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("I'm very curious to see how you handle this battle style.")
    end
  }

  ASTRID = {
    "afterLastOpp" => "My heavens. Is this my last Pokémon?",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("I hope you're ready to learn about the power of Cosmic-types.")
    end
  }

  GAIL = {
    "afterLastOpp" => "I see you've picked up rather fast. Think you can handle this one, though?",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("You'll be so confused in this battle. It's ok, you'll learn.")
      @scene.pbAnimation(GameData::Move.get(:TRICKROOM).id,@battle.battlers[1],@battle.battlers[1])
      @scene.pbDisplay("Type matchups were inverted!")
    end
  }

  GORDON = {
    "afterLastOpp" => proc do
      pname = $Trainer.name
      rname = $game_variables[12]
      @scene.pbTrainerSpeak("Get ready #{pname}! Here's my trump card")
    end,
    "turnStart0" => proc do
      pname = $Trainer.name
      rname = $game_variables[12]
      @scene.pbTrainerSpeak("I have heard good things about you from #{rname}! Let's see if he was right.")
      @scene.pbAnimation(GameData::Move.get(:TAILWIND).id,@battle.battlers[1],@battle.battlers[1])
      @battle.field.weather = :StrongWinds
      $gym_weather = true
      @scene.pbDisplay("A Delta Stream brewed!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange}
    end
  }

  WINSLOW = {
    "afterLastOpp" => "Am I being played here? This is my last ditch Pokémon!",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("Things are about to get real twisted in here!")
    end
}

  VINCENT = {
    "afterLastOpp" => "Looks like it's closing time. Last call!",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("Let's march.")
    end
  }

  JACKSON = {
    "afterLastOpp" => "Don't think we've given up!",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("I don't plan on losing to some punk.")
    end
  }

  MILITIA1 = {
    "afterLastOpp" => "You are quite good. How frustrating.",
    "turnStart0" => "You don't know what you're dealing with, kid."
  }

  MILITIA2 = {
    "afterLastOpp" => "...",
    "turnStart0" => "..."
  }

  ARMY1 = {
    "afterLastOpp" => "How interesting...",
    "turnStart0" => proc do 
      @scene.pbTrainerSpeak("Stop while you can kid. You're way out of your depth.")
      if $game_switches[LvlCap::Expert]
        @scene.pbAnimation(GameData::Move.get(:WISH).id,@battle.battlers[1],@battle.battlers[1])
        @battle.field.weather = :Eclipse
        @battle.field.weatherDuration = -1
        $gym_weather = true
        @scene.pbDisplay("Ahab set permanent Eclipse!")
      end
    end
  }

  ARMY2 = {
    "afterLastOpp" => "How infuriating...",
    "turnStart0" => "Don't think you can beat my team again like you did last time."
  }

  OFFCORP1 = {
    "afterLastOpp" => "I can't say I was expecting this.",
    "turnStart0" => "Prepare to be overrun."
  }

  OFFCORP_LEAGUE = {
    "turnStart0" => proc do 
    end
  }

  NAVY1 = {
    "afterLastOpp" => "Ah, I see yer point. Well said, yungin.",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("Ye may as well be a criminal showing up at a time like this.")
    end
  }

  NAVY2 = {
    "afterLastOpp" => "...",
    "turnStart0" => "..."
  }

  AIRFORCE1 = {
    "afterLastOpp" => "I do believe we are getting to the best part of this match!",
    "turnStart0" => proc do 
      @scene.pbTrainerSpeak("It's not that I don't trust you kiddo. I've just got to do my due diligence.")
    end
  }

  RIVAL2_Sand = {
    "turnStart0" => proc do
      rname = $game_variables[12]
      @scene.pbAnimation(GameData::Move.get(:SANDSTORM).id,@battle.battlers[1],@battle.battlers[1])
      @battle.field.weather = :Sandstorm
      @battle.field.weatherDuration = -1
      $gym_weather = true
      @scene.pbDisplay("A sandstorm brewed!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange}
    end
  }

  RIVAL2_Wind = {
    "turnStart0" => proc do
      rname = $game_variables[12]
      @scene.pbAnimation(GameData::Move.get(:TAILWIND).id,@battle.battlers[1],@battle.battlers[1])
      @battle.field.weather = :Windy
      @battle.field.weatherDuration = -1
      $gym_weather = true
      @scene.pbDisplay("The wind picked up!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange }
    end
  }

  RIVAL2_Sun = {
    "turnStart0" => proc do
      rname = $game_variables[12]
      @scene.pbAnimation(GameData::Move.get(:SUNNYDAY).id,@battle.battlers[1],@battle.battlers[1])
      @battle.field.weather = :Sun
      @battle.field.weatherDuration = -1
      $gym_weather = true
      @scene.pbDisplay("The sunlight grew bright!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange }
    end
  }

  CHANCELLOR = {
    "afterLastOpp" => "I will not accept this. I WILL MAINTAIN CONTROL!",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("You can't seem to comprehend. I control EVERYTHING.")
      @scene.pbAnimation(GameData::Move.get(:PSYCHICTERRAIN).id,@battle.battlers[1],@battle.battlers[1])
      @sprites["battlebg"].reconfigure(:PSYCHIC, Color.white)
      @battle.field.terrain = :Psychic
      @battle.field.terrainDuration = -1
      $gym_gimmick = true
      @scene.pbDisplay("The battlefield got permanently weird!")
    end
  }
  #==============================================================================
  # Post-Game
  #==============================================================================
  JASPER = {
    "afterLastOpp" => "Hmm. You are very good. Very good indeed.",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("Allow me to formally introduce you to how we do Dojo Battles here!")
      @scene.pbAnimation(GameData::Move.get(:SANDSTORM).id,@battle.battlers[1],@battle.battlers[1])
      @battle.field.weather = :Sandstorm
      @battle.field.weatherDuration = -1
      $gym_weather = true
      @scene.pbDisplay("Jasper set a permanent Sandstorm!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange}
    end
  }
  APOLLO = {
    "afterLastOpp" => "Oh my. How exciting!",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("My dojo is themed around the Sun. Let me show you!")
      @scene.pbAnimation(GameData::Move.get(:SUNNYDAY).id,@battle.battlers[1],@battle.battlers[1])
      @battle.field.weather = :HarshSun
      @battle.field.weatherDuration = -1
      $gym_weather = true
      @scene.pbDisplay("Apollo set up Harsh Sunlight!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange }
    end
  }
  LUNA = {
    "afterLastOpp" => "Hmmph. This isn't over yet.",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("...time to show you why I hate visitors to my island...")
      @battle.pbCommonAnimation("ShadowSky")
      @battle.field.weather = :Eclipse
      @battle.field.weatherDuration = -1
      $gym_weather = true
      @scene.pbDisplay("Luna set a permanent Eclipse!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange }
    end
  }
  MALOKI = {
    "afterLastOpp" => "This is one righteous battle, my dude!",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("Time to feel the tidal wave come crashing in!")
      @scene.pbAnimation(GameData::Move.get(:RAINDANCE).id,@battle.battlers[1],@battle.battlers[1])
      @battle.field.weather = :HeavyRain
      $gym_weather = true
      @scene.pbDisplay("Maloki set up Heavy Rain!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange }
    end
  }
  JULIET = {
    "afterLastOpp" => "Like, WHOA. This is my last one!",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("YAY! Battle time!")
      @scene.pbAnimation(GameData::Move.get(:ELECTRICTERRAIN).id,@battle.battlers[1],@battle.battlers[1])
      @sprites["battlebg"].reconfigure(:ELECTRIC, Color.white)
      @battle.field.terrain = :Electric
      @battle.field.terrainDuration = -1
      $gym_gimmick = true
      @scene.pbDisplay("Juliet set up a permanent Electric Terrain!")
    end
  }
  OLAF = {
    "afterLastOpp" => "Huh. Not bad, kid.",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("I really do not care for battling, but here we go.")
      @scene.pbAnimation(GameData::Move.get(:BLIZZARD).id,@battle.battlers[1],@battle.battlers[1])
      @battle.field.weather = :Sleet
      @battle.field.weatherDuration = -1
      $gym_weather = true
      @scene.pbDisplay("Olaf set up permanent Sleet!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange }
    end
  }
  WENDY = {
    "afterLastOpp" => "Huh. Not bad, kid.",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("Umm, I'm really not sure...ok, here we go, I guess...")
      @scene.pbAnimation(GameData::Move.get(:TAILWIND).id,@battle.battlers[1],@battle.battlers[1])
      @battle.field.weather = :Windy
      @battle.field.weatherDuration = -1
      $gym_weather = true
      @scene.pbDisplay("Wendy set up a permanent Wind!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange }
    end
  }
  ADAM = {
    "afterLastOpp" => "Wow! You're so tough! But can you handle this?",
    "turnStart0" => proc do
      @scene.pbTrainerSpeak("Let's get this show going!")
      @scene.pbAnimation(GameData::Move.get(:MISTYTERRAIN).id,@battle.battlers[1],@battle.battlers[1])
      @sprites["battlebg"].reconfigure(:MISTY, Color.white)
      @battle.field.terrain = :Misty
      @battle.field.terrainDuration = -1
      $gym_gimmick = true
      @scene.pbDisplay("Adam set up a permanent Misty Terrain!")
    end
  }
  CHANCELLOR1 = {
    "afterLastOpp" => "I have to succeed at this. You will NOT stand in my way!",
    "turnStart0" => proc do
      @scene.pbDisplay("The Harsh Sun is permanent!")
      @scene.pbTrainerSpeak("Why can't you just stay out of our business?!?")
      @scene.pbAnimation(GameData::Move.get(:PSYCHICTERRAIN).id,@battle.battlers[1],@battle.battlers[1])
      @sprites["battlebg"].reconfigure(:PSYCHIC, Color.white)
      @battle.field.terrain = :Psychic
      @battle.field.terrainDuration = -1
      $gym_gimmick = true
      $gym_weather = true
      @scene.pbDisplay("Yule set up a permanent Psychic Terrain!")
    end
  }
  ASTRIDLEAGUE = {
    "turnStart0" => proc do
      @scene.pbAnimation(GameData::Move.get(:WISH).id,@battle.battlers[1],@battle.battlers[1])
      @battle.field.weather = :Starstorm
      @battle.field.weatherDuration = -1
      $gym_weather = true
      @scene.pbDisplay("Astrid set a permanent Starstorm!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange}
    end
  }
  WINSLOWLEAGUE = {
    "turnStart0" => proc do
      @scene.pbAnimation(GameData::Move.get(:PSYCHICTERRAIN).id,@battle.battlers[1],@battle.battlers[1])
      @sprites["battlebg"].reconfigure(:PSYCHIC, Color.white)
        @battle.field.terrain = :Psychic
        @battle.field.terrainDuration = -1
        @battle.field.effects[PBEffects::TrickRoom] = 1
        $gym_gimmick = true
      @scene.pbDisplay("Winslow set permanent Psychic Terrain and Trick Room!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange}
    end
  }
  EUGENERAIN = {
    "turnStart0" => proc do
      @scene.pbAnimation(GameData::Move.get(:RAINDANCE).id,@battle.battlers[1],@battle.battlers[1])
      @battle.field.weather = :HeavyRain
      $gym_weather = true
      @scene.pbDisplay("Eugene set up Heavy Rain!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange}
    end
  }
  EUGENESLEET = {
    "turnStart0" => proc do
      @scene.pbAnimation(GameData::Move.get(:HAIL).id,@battle.battlers[1],@battle.battlers[1])
      @battle.field.weather = :Sleet
      @battle.field.weatherDuration = -1
      $gym_weather = true
      @scene.pbDisplay("Eugene set up permanent Sleet!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange}
    end
  }
  ARMANDLEAGUE = {
    "turnStart0" => proc do
      @scene.pbAnimation(GameData::Move.get(:TAILWIND).id,@battle.battlers[1],@battle.battlers[1])
      @battle.field.weather = :StrongWinds
      $gym_weather = true
      @scene.pbDisplay("Armand set up Delta Stream!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange}
    end
  }
  WINSTONLEAGUE = {
    "turnStart0" => proc do
      @scene.pbAnimation(GameData::Move.get(:TAILWIND).id,@battle.battlers[1],@battle.battlers[1])
      @battle.field.weather = :Windy
      @battle.field.weatherDuration = -1
      $gym_weather = true
      @scene.pbDisplay("The trainer set a permanent Wind!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange}
    end
  }
  VINCENTLEAGUE = {
    "turnStart0" => proc do
      @scene.pbAnimation(GameData::Move.get(:SLUDGEWAVE).id,@battle.battlers[1],@battle.battlers[1])
      @sprites["battlebg"].reconfigure(:POISON, Color.white)
        @battle.field.terrain = :Poison
        @battle.field.terrainDuration = -1
        $gym_gimmick = true
      @scene.pbDisplay("The trainer set permanent Poison Terrain!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange}
    end
  }
  JOSEPHSAND = {
    "turnStart0" => proc do
      @scene.pbAnimation(GameData::Move.get(:SANDSTORM).id,@battle.battlers[1],@battle.battlers[1])
      @battle.field.weather = :Sandstorm
      @battle.field.weatherDuration = -1
      $gym_weather = true
      @scene.pbDisplay("The trainer set a permanent Sandstorm!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange}
    end
  }
  JOSEPHTERRAIN = {
    "turnStart0" => proc do
      @scene.pbAnimation(GameData::Move.get(:ELECTRICTERRAIN).id,@battle.battlers[1],@battle.battlers[1])
      @sprites["battlebg"].reconfigure(:ELECTRIC, Color.white)
        @battle.field.terrain = :Electric
        @battle.field.terrainDuration = -1
        $gym_gimmick = true
      @scene.pbDisplay("The trainer set permanent Electric Terrain!")
      @battle.eachBattler { |b| b.pbCheckFormOnWeatherChange}
    end
  }
end

module EnvironmentEBDX
  TEMPLE = {
    "backdrop" => "Sapphire",
    "vacuum" => "dark006",
    "img001" => {
      :scrolling => true, :vertical => true, :speed => 1,
      :bitmap => "decor003a",
      :oy => 180, :y => 90, :flat => true
    }, "img002" => {
      :bitmap => "shade",
      :oy => 100, :y => 98, :flat => false
    }, "img003" => {
      :scrolling => true, :speed => 16,
      :bitmap => "decor005",
      :oy => 0, :y => 4, :z => 4, :flat => true
    }, "img004" => {
      :scrolling => true, :speed => 16, :direction => -1,
      :bitmap => "decor006",
      :oy => 0, :z => 4, :flat => true
    }, "img005" => {
      :scrolling => true, :speed => 0.5,
      :bitmap => "base001a",
      :oy => 0, :y => 122, :z => 1, :flat => true
    }, "img006" => {
      :bitmap => "pillars",
      :oy => 100, :x => 96, :y => 98, :flat => false, :zoom => 0.5
    }
  }
  SNOWYMOUNTAIN = {
    "backdrop" => "Snow", "sky" => true, "img001" => {
      :bitmap => "mountainB",
      :x => 192, :y => 107
    }
  }
  ICY = {"backdrop" => "Snow"}
  GARDEN = {"backdrop" => "Sky"}
  CASTLE = {"backdrop" => "City"}
  FAIRYLIGHTS = {"backdrop" => "Field"}
  SPACE = {"backdrop" => "Space"}
  DESERT = {"backdrop" => "Sand"}
  ELECTRIC = {"backdrop" => "Electric"}
  GRASSY = {"backdrop" => "Grassy"}
  MISTY = {"backdrop" => "Misty"}
  PSYCHIC = {"backdrop" => "Psychic"}
  POISON = {"backdrop" => "Poison"}
  MAGNETIC = {"backdrop" => "Net"}
  WINDTUNNEL = {"backdrop" => "Sapphire"}
  GRAVEYARD = {"backdrop" => "DanceFloor"}
  CITY = {
    "backdrop" => "City", "sky" => true, "trees" => {
      :elements => 9,
      :x => [150,271,78,288,176,42,118,348,321],
      :y => [108,117,118,126,126,128,136,136,145],
      :zoom => [0.44,0.44,0.59,0.59,0.59,0.64,0.85,0.7,1],
      :mirror => [false,false,true,true,true,false,false,true,false]
    }
  }
  CITYNIGHT = {
    "backdrop" => "Darkness", "sky" => true,  "trees" => {
      :bitmap => "treePine", :colorize => false, :elements => 8,
      :x => [92,248,300,40,138,216,274,318],
      :y => [132,132,144,118,112,118,110,110],
      :zoom => [1,1,1.1,0.9,0.8,0.85,0.75,0.75],
      :z => [2,2,2,1,1,1,1,1],
    }, "outdoor" => false
  }
  DRAGONSDEN = {
    "backdrop" => "Champion",
    "lightsA" => true,
    "img001" => {
      :scrolling => true, :vertical => true, :speed => 1,
      :bitmap => "decor003",
      :oy => 180, :y => 90, :z => 1, :flat => true
    }, "img005" => {
      :scrolling => true, :speed => 0.5,
      :bitmap => "base001",
      :oy => 0, :y => 122, :z => 1, :flat => true
    },
  }
  DREAM = {
    "backdrop" => "Misty",
    "lightsA" => true,
    "img001" => {
      :scrolling => true, :vertical => true, :speed => 1,
      :bitmap => "decor003",
      :oy => 180, :y => 90, :z => 1, :flat => true
    }, "img002" => {
      :bitmap => "decor004",
      :oy => 100, :y => 98, :z => 2, :flat => false
    }, "img003" => {
      :scrolling => true, :speed => 16,
      :bitmap => "decor005",
      :oy => 0, :y => 4, :z => 4, :flat => true
    }, "img004" => {
      :scrolling => true, :speed => 16, :direction => -1,
      :bitmap => "decor006",
      :oy => 0, :z => 4, :flat => true
    }, "img005" => {
      :scrolling => true, :speed => 0.5,
      :bitmap => "base001",
      :oy => 0, :y => 122, :z => 1, :flat => true
    }, "img006" => {
      :scrolling => true, :speed => 0.5, :direction => 1,
      :bitmap => "fog",
      :oy => 0, :z => 4, :flat => true
    }
  }
  MIRROR = {"backdrop" => "IndoorB"}
end