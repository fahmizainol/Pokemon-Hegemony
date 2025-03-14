def egglocke_generator
  eggs = []
  pbEachPokemon { |poke,_box|
    mon = poke.species
    egg = GameData::Species.get(mon).get_baby_species
    evos = GameData::Species.get(egg).get_family_evolutions
    eggs.push(evos)
  }
  loop do
    pkmn = Randomizer.all_species.sample
    pkmn = GameData::Species.get(pkmn).get_baby_species
    next if eggs.include?(pkmn)
    pkmn = Pokemon.new(pkmn,1)
    pkmn.calc_stats
    pkmn.name           = _INTL("Egg")
    pkmn.steps_to_hatch = 20
    pkmn.hatched_map    = 0
    pkmn.obtain_method  = 1
    if $game_switches[75]
      for stat in pkmn.iv.keys
        pkmn.iv[stat] = 31
      end
    end
    2.times do
      pkmn.learn_move(addRandomEggMove(pkmn.species))
    end
    return pkmn if !eggs.include?(pkmn.species) && pbHasEgg?(pkmn.species)
  end
end

def addRandomEggMove(species)
    baby = GameData::Species.get(species).get_baby_species
    form = GameData::Species.get(species).form
    egg = GameData::Species.get_species_form(baby,form).egg_moves
    moveChoice = rand(egg.length)
    moves = egg[moveChoice]
    return moves
end


def grass_starter_eggs
  egg_list = [:BULBASAUR,:CHIKORITA,:TREECKO,:TURTWIG,:SNIVY,:CHESPIN,:ROWLET,:GROOKEY,:SPRIGATITO]
  eggs = []
  pbEachPokemon { |poke,_box|
    mon = poke.species
    evo = GameData::Species.get(mon).get_baby_species
    evos = GameData::Species.get(evo).get_family_evolutions
    eggs.push(evos)
  }
  eggs.flatten!
  eggs.uniq!
  eggs.each do |e|
    if egg_list.include?(e)
      egg_list.delete(e)
    end
  end
  return egg_list
end

def fire_starter_eggs
  egg_list = [:CHARMANDER,:CYNDAQUIL,:TORCHIC,:CHIMCHAR,:TEPIG,:FENNEKIN,:LITTEN,:SCORBUNNY,:FUECOCO]
  eggs = []
  pbEachPokemon { |poke,_box|
    mon = poke.species
    evo = GameData::Species.get(mon).get_baby_species
    evos = GameData::Species.get(evo).get_family_evolutions
    eggs.push(evos)
  }
  eggs.flatten!
  eggs.uniq!
  eggs.each do |e|
    if egg_list.include?(e)
      egg_list.delete(e)
    end
  end
  return egg_list
end

def water_starter_eggs
  egg_list = [:SQUIRTLE,:TOTODILE,:MUDKIP,:PIPLUP,:OSHAWOTT,:FROAKIE,:POPPLIO,:SOBBLE,:QUAXLY]
  eggs = []
  pbEachPokemon { |poke,_box|
    mon = poke.species
    evo = GameData::Species.get(mon).get_baby_species
    evos = GameData::Species.get(evo).get_family_evolutions
    eggs.push(evos)
  }
  eggs.flatten!
  eggs.uniq!
  eggs.each do |e|
    if egg_list.include?(e)
      egg_list.delete(e)
    end
  end
  return egg_list
end

def grass_starter_egg_vendor
  egg_list = [:BULBASAUR,:CHIKORITA,:TREECKO,:TURTWIG,:SNIVY,:CHESPIN,:ROWLET,:GROOKEY,:SPRIGATITO]
  return egg_list
end

def fire_starter_egg_vendor
  egg_list = [:CHARMANDER,:CYNDAQUIL,:TORCHIC,:CHIMCHAR,:TEPIG,:FENNEKIN,:LITTEN,:SCORBUNNY,:FUECOCO]
  return egg_list
end

def water_starter_egg_vendor
  egg_list = [:SQUIRTLE,:TOTODILE,:MUDKIP,:PIPLUP,:OSHAWOTT,:FROAKIE,:POPPLIO,:SOBBLE,:QUAXLY]
  return egg_list
end

def hisui_eggs
  egg_list = [:CYNDAQUIL,:ROWLET,:OSHAWOTT,:QWILFISH,:SNEASEL,:GOOMY,:BERGMITE,:PETILIL,:ZORUA,:GROWLITHE,:VOLTORB,:RUFFLET,:BASCULIN]
  eggs = []
  pbEachPokemon { |poke,_box|
    mon = poke.species
    evo = GameData::Species.get(mon).get_baby_species
    evos = GameData::Species.get(evo).get_family_evolutions
    eggs.push(evos)
  }
  eggs.flatten!
  eggs.uniq!
  eggs.each do |e|
    if egg_list.include?(e)
      egg_list.delete(e)
    end
  end
  if egg_list == []
    egg_list = [:CYNDAQUIL,:ROWLET,:OSHAWOTT,:QWILFISH,:SNEASEL,:GOOMY,:BERGMITE,:PETILIL,:ZORUA,:GROWLITHE,:VOLTORB,:RUFFLET,:BASCULIN]
  end
  return egg_list
end

def random_eggs
  egg_list = [:MELTAN,:MILCERY,:SKITTY,:GULPIN,:FLABEBE,:AZURILL,:MAREANIE,:SNEASEL,:TEDDIURSA,:TOXEL,:CUBONE,:DARUMAKA,:MIMEJR,:MEOWTH,:PONYTA,:CORSOLA,:FARFETCHD,:GEODUDE,:ROLYCOLY,:SKIDDO,:KLINK,:STANTLER,:PICHU,:MAGBY,:ELEKID,:SMOOCHUM,:HAPPINY,:MUNCHLAX,:POIPOLE,:COSMOG,:PHIONE,:KUBFU,:LARVESTA,:SIZZLIPEDE,:SILICOBRA,:MAGNEMITE,:CARBINK,:AUDINO,:RALTS,:ABRA,:GASTLY,:DROWZEE,:ELGYEM,:BRONZOR,:MUNNA,:IMPIDIMP,:INDEEDEE,:PINCURCHIN,:PYUKUMUKU,:WYNAUT,:SCRAGGY,:SEEL,:HORSEA,:JIGGLYPUFF,:MANKEY,:SEVIPER,
  :ZANGOOSE,:SNUBBULL,:MAREEP,:GIRAFARIG,:DUNSPARCE,:CHINGLING,:SNORUNT,:SPHEAL,:BUIZEL,:FINNEON,:ARROKUDA,:MORELULL,:FOMANTIS,:INKAY,:COTTONEE,:MISDREAVUS,:MURKROW,:FEEBAS,:GOTHITA,:SOLOSIS,:STUNFISK,:PIKIPEK,:EMOLGA,:PLUSLE,:MINUN,:TOGEDEMARU,:MORPEKO,:VOLBEAT,:ILLUMISE,:ODDISH,:BELLSPROUT,:IGGLYBUFF,:CLEFFA,:PICHU,:STARYU,:GRIMER,:KOFFING,:LAPRAS,:ZUBAT,:NATU,:BONSLY,:WEEDLE,:CATERPIE,:WAILMER,:SHELMET,:KARRABLAST,:SCYTHER,:BARBOACH,:LUVDISC,:DEDENNE,:MINIOR,:CLOBBOPUS,:CRABRAWLER,:KRABBY,
  :SKORUPI,:FOMANTIS,:DEWPIDER,:BUNEARY,:TYNAMO,:DELIBIRD,:REMORAID,:WOOLOO,:NICKIT,:SKWOVET,:DHELMISE,:EKANS,:CRYOGONAL,:CUBCHOO,:WISHIWASHI,:DEINO,:TRAPINCH,:BELDUM,:BAGON,:LARVITAR,:DRATINI,:EEVEE,:GIBLE,:NOIBAT,:JANGMOO,:DREEPY,:RIOLU,:TYROGUE,:CROAGUNK,:GLIGAR,:HATENNA,:ZIGZAGOON,:ROOKIDEE,:JOLTIK,:WOOPER,
  :TAROUNTULA,:LECHONK,:FIDOUGH,:GIMMIGHOUL,:TAUROS,:MILTANK,:BOUFFALANT,:FRIGIBAX,:FLITTLE,:TOEDSCOOL,:WIGLETT,:DONDOZO,:TATSUGIRI,:VELUZA,:TADBULB,:PAWMI,:FLAMIGO,:MASCHIFF,:GREAVARD,:PAWNIARD,:SMOLIV,:NYMBLE,:BOMBIRDIER,:KLAWF,:ORTHWORM,:CAPSAKID,:GLIMMET,:VAROOM,:BRAMBLIN,:WATTREL,:SHROODLE,:CYCLIZAR,:TINKATINK,:TANDEMAUS,:RELLOR,:FINIZEN,:NACLI,:CETODDLE]
  eggs = []
  pbEachPokemon { |poke,_box|
    mon = poke.species
    evo = GameData::Species.get(mon).get_baby_species
    evos = GameData::Species.get(evo).get_family_evolutions
    eggs.push(evos)
  }
  eggs.flatten!
  eggs.uniq!
  eggs.each do |e|
    if egg_list.include?(e)
      egg_list.delete(e)
    end
  end
  return egg_list
end

def wartime_eggs
  egg_list = [
    :GROWLITHE2,
    :DRIFLOON2,
    :DREEPY2,
    :GIBLE2,
    :CARVANHA2,
    :TREECKO2,
    :TORCHIC2,
    :MUDKIP2,
    :FINNEON2
  ]
  eggs = []
  pbEachPokemon { |poke,_box|
    mon = poke.species
    evo = GameData::Species.get(mon).get_baby_species
    evos = GameData::Species.get(evo).get_family_evolutions
    eggs.push(evos)
  }
  eggs.flatten!
  eggs.uniq!
  eggs.each do |e|
    if egg_list.include?(e)
      egg_list.delete(e)
    end
  end
  if egg_list == []
    egg_list = [
      :GROWLITHE2,
      :DRIFLOON2,
      :DREEPY2,
      :GIBLE2,
      :CARVANHA2,
      :TREECKO2,
      :TORCHIC2,
      :MUDKIP2,
      :FINNEON2
    ]
  end
  return egg_list
end

def postgame_wartime_eggs
  egg_list = [
    :MAGNEMITE2,
    :FERROSEED2,
    :IMPIDIMP2,
    :ARON2,
    :SNORUNT2,
    :TURTWIG2,
    :CHIMCHAR2,
    :PIPLUP2
  ]
  eggs = []
  pbEachPokemon { |poke,_box|
    mon = poke.species
    evo = GameData::Species.get(mon).get_baby_species
    evos = GameData::Species.get(evo).get_family_evolutions
    eggs.push(evos)
  }
  eggs.flatten!
  eggs.uniq!
  eggs.each do |e|
    if egg_list.include?(e)
      egg_list.delete(e)
    end
  end
  if egg_list == []
    egg_list = [
      :MAGNEMITE2,
      :DEINO2,
      :FERROSEED2,
      :IMPIDIMP2,
      :TURTWIG2,
      :CHIMCHAR2,
      :PIPLUP2
    ]
  end
  return egg_list
end

def generate_hisui_egg
  rand = rand(hisui_eggs.length)
  egg = hisui_eggs[rand]
  if pbGenerateEgg(egg,_I("Random Hiker"))
    pbMessage(_INTL("\\me[Egg get]\\PN received an Egg!"))
    pbCallBub(2,@event_id)
    pbMessage(_INTL("\\[7fe00000]Take good care of it!"))
    egg = $Trainer.last_party
    species = egg.species
    move = GameData::Species.get(species).egg_moves
    egg.ability_index = 2
    egg.form = (species == :BASCULIN) ? 2 : 1
    if $game_switches[75]
      for stat in egg.iv.keys
        egg.iv[stat] = 31
      end
    else
      egg.iv[:HP] = 31
      egg.iv[:DEFENSE] = 31
      egg.iv[:SPECIAL_DEFENSE] = 31
    end
    egg.learn_move(move[rand(move.length)])
    egg.steps_to_hatch = 200
    egg.calc_stats
    vTSS(@event_id,"A")
  else
    pbCallBub(2,@event_id)
    pbMessage(_INTL("\\[7fe00000]Oh, you can't carry it with you."))
    pbCallBub(2,@event_id)
    pbMessage(_INTL("\\[7fe00000]Make some space in your party and come back."))
  end
end

def generate_wartime_egg
  rand = rand(wartime_eggs.length)
  egg = wartime_eggs[rand]
  if pbGenerateEgg(egg,_I("Random Hiker"))
    pbMessage(_INTL("\\me[Egg get]\\PN received an Egg!"))
    pbCallBub(2,@event_id)
    pbMessage(_INTL("\\[7fe00000]Take good care of it!"))
    egg = $Trainer.last_party
    species = egg.species
    move = GameData::Species.get(species).egg_moves
    egg.ability_index = 2
    if $game_switches[75]
      for stat in egg.iv.keys
        egg.iv[stat] = 31
      end
    else
      egg.iv[:HP] = 31
      egg.iv[:DEFENSE] = 31
      egg.iv[:SPECIAL_DEFENSE] = 31
    end
    egg.learn_move(move[rand(move.length)])
    egg.steps_to_hatch = 200
    egg.calc_stats
    vTSS(@event_id,"A")
  else
    pbCallBub(2,@event_id)
    pbMessage(_INTL("\\[7fe00000]Oh, you can't carry it with you."))
    pbCallBub(2,@event_id)
    pbMessage(_INTL("\\[7fe00000]Make some space in your party and come back."))
  end
end

def generate_postgame_wartime_egg
  rand = rand(postgame_wartime_eggs.length)
  egg = postgame_wartime_eggs[rand]
  if pbGenerateEgg(egg,_I("Random Hiker"))
    pbMessage(_INTL("\\me[Egg get]\\PN received an Egg!"))
    pbCallBub(2,@event_id)
    pbMessage(_INTL("\\[7fe00000]Take good care of it!"))
    egg = $Trainer.last_party
    species = egg.species
    move = GameData::Species.get(species).egg_moves
    egg.ability_index = 2
    if $game_switches[75]
      for stat in egg.iv.keys
        egg.iv[stat] = 31
      end
    else
      egg.iv[:HP] = 31
      egg.iv[:DEFENSE] = 31
      egg.iv[:SPECIAL_DEFENSE] = 31
    end
    egg.learn_move(move[rand(move.length)])
    egg.steps_to_hatch = 200
    egg.calc_stats
    vTSS(@event_id,"A")
  else
    pbCallBub(2,@event_id)
    pbMessage(_INTL("\\[7fe00000]Oh, you can't carry it with you."))
    pbCallBub(2,@event_id)
    pbMessage(_INTL("\\[7fe00000]Make some space in your party and come back."))
  end
end

def generate_random_egg
  rand = rand(random_eggs.length)
  regionals = [:CUBONE,:DARUMAKA,:MEOWTH,:PONYTA,:CORSOLA,:FARFETCHD,:GEODUDE,:STUNFISK,:GRIMER,:KOFFING,:ZIGZAGOON,:WOOPER,:TAUROS]
  reg_rand = rand(10)
  egg = random_eggs[rand]
  if pbGenerateEgg(egg,_I("Random Hiker"))
    pbMessage(_INTL("\\me[Egg get]\\PN received an Egg!"))
    pbCallBub(2,@event_id)
    pbMessage(_INTL("\\[7fe00000]Take good care of it!"))
    egg = $Trainer.last_party
    species = egg.species
    move = GameData::Species.get(species).egg_moves
    egg.ability_index = 2
    egg.form = regionals.include?(species) ? (reg_rand > 4 ? 1 : 0) : 0
    if $game_switches[75]
      for stat in egg.iv.keys
        egg.iv[stat] = 31
      end
    else
      egg.iv[:HP] = 31
      egg.iv[:DEFENSE] = 31
      egg.iv[:SPECIAL_DEFENSE] = 31
    end
    egg.learn_move(move[rand(move.length)])
    egg.steps_to_hatch = 200
    egg.calc_stats
    vTSS(@event_id,"A")
  else
    pbCallBub(2,@event_id)
    pbMessage(_INTL("\\[7fe00000]Oh, you can't carry it with you."))
    pbCallBub(2,@event_id)
    pbMessage(_INTL("\\[7fe00000]Make some space in your party and come back."))
  end
end

def generate_starter_egg(type)
  case type
  when :GRASS
    rand = rand(grass_starter_eggs.length)
    hisui_rand = rand(10)
    egg = grass_starter_eggs[rand]
    if pbGenerateEgg(egg,_I("Random Hiker"))
      pbMessage(_INTL("\\me[Egg get]\\PN received an Egg!"))
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Take good care of it!"))
      egg = $Trainer.last_party
      species = egg.species
      move = GameData::Species.get(species).egg_moves
      egg.ability_index = 2
      if species == :ROWLET
        egg.form = hisui_rand>4 ? 1 : 0
      else
        egg.form = 0
      end
      if $game_switches[75]
        for stat in egg.iv.keys
          egg.iv[stat] = 31
        end
      else
        egg.iv[:HP] = 31
        egg.iv[:DEFENSE] = 31
        egg.iv[:SPECIAL_DEFENSE] = 31
      end
      egg.learn_move(move[rand(move.length)])
      egg.steps_to_hatch = 200
      egg.calc_stats
      vTSS(@event_id,"A")
    else
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Oh, you can't carry it with you."))
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Make some space in your party and come back."))
    end
  when :FIRE
    rand = rand(fire_starter_eggs.length)
    hisui_rand = rand(10)
    egg = fire_starter_eggs[rand]
    if pbGenerateEgg(egg,_I("Random Hiker"))
      pbMessage(_INTL("\\me[Egg get]\\PN received an Egg!"))
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Take good care of it!"))
      egg = $Trainer.last_party
      species = egg.species
      move = GameData::Species.get(species).egg_moves
      egg.ability_index = 2
      if species == :CYNDAQUIL
        egg.form = hisui_rand>4 ? 1 : 0
      else
        egg.form = 0
      end
      if $game_switches[75]
        for stat in egg.iv.keys
          egg.iv[stat] = 31
        end
      else
        egg.iv[:HP] = 31
        egg.iv[:DEFENSE] = 31
        egg.iv[:SPECIAL_DEFENSE] = 31
      end
      egg.learn_move(move[rand(move.length)])
      egg.steps_to_hatch = 200
      egg.calc_stats
      vTSS(@event_id,"A")
    else
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Oh, you can't carry it with you."))
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Make some space in your party and come back."))
    end
  when :WATER
    rand = rand(water_starter_eggs.length)
    hisui_rand = rand(10)
    egg = water_starter_eggs[rand]
    if pbGenerateEgg(egg,_I("Random Hiker"))
      pbMessage(_INTL("\\me[Egg get]\\PN received an Egg!"))
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Take good care of it!"))
      egg = $Trainer.last_party
      species = egg.species
      move = GameData::Species.get(species).egg_moves
      egg.ability_index = 2
      if species == :OSHAWOTT
        egg.form = hisui_rand>4 ? 1 : 0
      else
        egg.form = 0
      end
      if $game_switches[75]
        for stat in egg.iv.keys
          egg.iv[stat] = 31
        end
      else
        egg.iv[:HP] = 31
        egg.iv[:DEFENSE] = 31
        egg.iv[:SPECIAL_DEFENSE] = 31
      end
      egg.learn_move(move[rand(move.length)])
      egg.steps_to_hatch = 200
      egg.calc_stats
      vTSS(@event_id,"A")
    else
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Oh, you can't carry it with you."))
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Make some space in your party and come back."))
    end
  end
end

def generate_starter_egg_vendor(type)
  case type
  when :GRASS
    rand = rand(grass_starter_egg_vendor.length)
    hisui_rand = rand(10)
    egg = grass_starter_egg_vendor[rand]
    if pbGenerateEgg(egg,_I("Random Hiker"))
      pbMessage(_INTL("\\me[Egg get]\\PN received an Egg!"))
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Take good care of it!"))
      egg = $Trainer.last_party
      species = egg.species
      move = GameData::Species.get(species).egg_moves
      egg.ability_index = 2
      egg.form = species != :ROWLET ? 0 : (hisui_rand > 4 ? 1 : 0)
      if $game_switches[75]
        for stat in egg.iv.keys
          egg.iv[stat] = 31
        end
      else
        egg.iv[:HP] = 31
        egg.iv[:DEFENSE] = 31
        egg.iv[:SPECIAL_DEFENSE] = 31
      end
      egg.learn_move(move[rand(move.length)])
      egg.steps_to_hatch = 200
      egg.calc_stats
      vTSS(@event_id,"A")
    else
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Oh, you can't carry it with you."))
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Make some space in your party and come back."))
    end
  when :FIRE
    rand = rand(fire_starter_egg_vendor.length)
    hisui_rand = rand(10)
    egg = fire_starter_egg_vendor[rand]
    if pbGenerateEgg(egg,_I("Random Hiker"))
      pbMessage(_INTL("\\me[Egg get]\\PN received an Egg!"))
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Take good care of it!"))
      egg = $Trainer.last_party
      species = egg.species
      move = GameData::Species.get(species).egg_moves
      egg.ability_index = 2
      egg.form = species != :CYNDAQUIL ? 0 : (hisui_rand > 4 ? 1 : 0)
      if $game_switches[75]
        for stat in egg.iv.keys
          egg.iv[stat] = 31
        end
      else
        egg.iv[:HP] = 31
        egg.iv[:DEFENSE] = 31
        egg.iv[:SPECIAL_DEFENSE] = 31
      end
      egg.learn_move(move[rand(move.length)])
      egg.steps_to_hatch = 200
      egg.calc_stats
      vTSS(@event_id,"A")
    else
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Oh, you can't carry it with you."))
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Make some space in your party and come back."))
    end
  when :WATER
    rand = rand(water_starter_egg_vendor.length)
    hisui_rand = rand(10)
    egg = water_starter_egg_vendor[rand]
    if pbGenerateEgg(egg,_I("Random Hiker"))
      pbMessage(_INTL("\\me[Egg get]\\PN received an Egg!"))
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Take good care of it!"))
      egg = $Trainer.last_party
      species = egg.species
      move = GameData::Species.get(species).egg_moves
      egg.ability_index = 2
      egg.form = species != :OSHAWOTT ? 0 : (hisui_rand > 4 ? 1 : 0)
      if $game_switches[75]
        for stat in egg.iv.keys
          egg.iv[stat] = 31
        end
      else
        egg.iv[:HP] = 31
        egg.iv[:DEFENSE] = 31
        egg.iv[:SPECIAL_DEFENSE] = 31
      end
      egg.learn_move(move[rand(move.length)])
      egg.steps_to_hatch = 200
      egg.calc_stats
      vTSS(@event_id,"A")
    else
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Oh, you can't carry it with you."))
      pbCallBub(2,@event_id)
      pbMessage(_INTL("\\[7fe00000]Make some space in your party and come back."))
    end
  end
end

def generate_expert_egg(mapid)
  map = pbLoadMapInfos
  map_name = map[mapid].name
  case map_name
  when "Helum City"
    eggs = [:MAGBY,:ELEKID,:SMOOCHUM,:BONSLY,:PHANPY,:TYROGUE,:PICHU,:EXEGGCUTE]
    form = 0
  when "Ogan Town"
    eggs = [:WOOPER,:GRIMER,:GROWLITHE,:VULPIX,:SANDSHREW,:MEOWTH,:GEODUDE,:ZIGZAGOON]
    form = 1
  when "Neonn Town"
    eggs = [:EEVEE,:EEVEE,:EEVEE,:EEVEE,:HERACROSS,:HAWLUCHA,:PINSIR,:RIOLU]
    form = 0
  when "Sodum Town"
    eggs = [:CUTIEFLY,:NYMBLE,:SEWADDLE,:BLIPBUG,:LARVESTA,:VENIPEDE,:JOLTIK,:SCYTHER]
    form = 0
  when "Krypto Quay"
    eggs = [:FLABEBE,:TOGEPI,:SNUBBULL,:AZURILL,:MAWILE,:GULPIN,:CLEFFA,:FIDOUGH]
    form = 0
  when "Chloros City"
    eggs = [:CHARCADET,:CHARCADET,:CHARCADET,:CHARCADET,:CYNDAQUIL,:FUECOCO,:CHARMANDER,:TEPIG]
    form = 0
  when "Nitro City"
    eggs = [:EEVEE,:EEVEE,:BUNEARY,:STUFFUL,:HELIOPTILE,:SENTRET,:SHROODLE,:ZORUA]
    form = 0
  end
  reg_rand = rand(10)
  rand_egg = rand(eggs.length)
  egg = eggs[rand_egg]
  if pbGenerateEgg(egg,_I("Random Hiker"))
    pbMessage(_INTL("\\me[Egg get]\\PN received an Egg!"))
    pbCallBub(2,@event_id)
    pbMessage(_INTL("\\[7fe00000]Take good care of it!"))
    egg = $Trainer.last_party
    species = egg.species_data
    egg.form = (species == :ZORUA) ? 1 : form
    stats = [:HP,:ATTACK,:DEFENSE,:SPEED,:SPECIAL_ATTACK,:SPECIAL_DEFENSE]
    count = 0
    egg.three_random_ivs
    egg.steps_to_hatch = 200
    egg.calc_stats
    $game_switches[919] = true
  else
    pbCallBub(2,@event_id)
    pbMessage(_INTL("\\[7fe00000]Oh, you can't carry it with you."))
    pbCallBub(2,@event_id)
    pbMessage(_INTL("\\[7fe00000]Make some space in your party and come back."))
  end
end