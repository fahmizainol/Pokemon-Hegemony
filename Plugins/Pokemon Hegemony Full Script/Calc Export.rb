def export_all
  str = ""
  blacklist = [:PICHU,:MINIOR,:FLABEBE,:FLOETTE,:FLORGES,:PIKACHU,:TATSUGIRI,:SQUAWKABILLY,:UNOWN,:SHELLOS,:GASTRODON,:DEERLING,:SAWSBUCK,:VIVILLON,:ALCREMIE,
    :ROCKRUFF,:WISHIWASHI,:CRAMORANT,:SINISTEA,:POLTEAGEIST,:POTCHAGEIST,:SINISTCHA,:MORPEKO,:DUDUNSPARCE,:GIMMIGHOUL]
  for i in 0...$Trainer.party.length
    pokemon = $Trainer.party[i]
    next if pokemon.egg?
    speciesname = GameData::Species.get(pokemon.species_data).name
    if pokemon.species_data.form > 0 && !blacklist.include?(pokemon.species)
      speciesname += "-#{pokemon.species_data.form_name}"
    elsif pokemon.shiny_locked?
      speciesname += "-Wartime"
    end
    if pokemon.item
      str += "\n#{speciesname} @ #{GameData::Item.get(pokemon.item).name}"
    else
      str += "\n#{speciesname}"
    end
    str += "\nLevel: #{pokemon.level}"
    str += "\n#{GameData::Nature.get(pokemon.nature).name} Nature"
    str += "\nAbility: #{GameData::Ability.get(pokemon.ability).name}"
    str += "\nIVs: #{pokemon.iv[:HP]} HP / #{pokemon.iv[:ATTACK]} Atk / #{pokemon.iv[:DEFENSE]} Def / #{pokemon.iv[:SPECIAL_ATTACK]} SpA / #{pokemon.iv[:SPECIAL_DEFENSE]} SpD / #{pokemon.iv[:SPEED]} Spe\n"
    pokemon.moves.each do |move| 
      if move.name == "Hidden Power" && move.id != :HIDDENPOWER
        str += "- #{move.name} #{GameData::Type.get(move.type).name}\n"
      else
        str += "- #{move.name}\n"
      end
    end
  end
  box = $PokemonStorage.maxBoxes - 2
  box.times do |i|
    $PokemonStorage.maxPokemon(i).times do |j|
      if $PokemonStorage[i,j] != nil
        pokemon2 = $PokemonStorage[i, j]
        next if pokemon2.egg?
        speciesname2 = GameData::Species.get(pokemon2.species_data).name
        if pokemon2.species_data.form > 0 && !blacklist.include?(pokemon2.species)
          speciesname2 += "-#{pokemon2.species_data.form_name}"
        elsif pokemon2.shiny_locked?
          speciesname2 += "-Wartime"
        end
        if pokemon2.item
        str += "\n#{speciesname2} @ #{GameData::Item.get(pokemon2.item).name}"
      else
        str += "\n#{speciesname2}"
      end
        str += "\nLevel: #{pokemon2.level}"
        str += "\n#{GameData::Nature.get(pokemon2.nature).name} Nature"
        str += "\nAbility: #{GameData::Ability.get(pokemon2.ability).name}"
        str += "\nIVs: #{pokemon.iv[:HP]} HP / #{pokemon2.iv[:ATTACK]} Atk / #{pokemon2.iv[:DEFENSE]} Def / #{pokemon2.iv[:SPECIAL_ATTACK]} SpA / #{pokemon2.iv[:SPECIAL_DEFENSE]} SpD / #{pokemon2.iv[:SPEED]} Spe\n"
        pokemon2.moves.each do |move1| 
          if move1.name == "Hidden Power" && move1.id != :HIDDENPOWER
            str += "- #{move1.name} #{GameData::Type.get(move1.type).name}\n"
          else
            str += "- #{move1.name}\n"
          end
        end
      end
    end
  end
  path = "Data/Expert Mode Data/export.txt"
  File.open(path, "wb") { |f|
      f.write(str)
    }
    pbMessage(_INTL("Pokémon exported! Check Data/Expert Mode Data/export.txt for your copy paste!"))
end


def return_items
  party_items = []
  $Trainer.party.each do |pkmn|
    party_items.push(GameData::Item.get(pkmn.item).id) if pkmn.item
    pkmn.item = nil
  end
  box_items = []
  $PokemonStorage.maxBoxes.times do |i|
    $PokemonStorage.maxPokemon(i).times do |j|
      if $PokemonStorage[i,j] != nil && $PokemonStorage[i,j].item != nil
        box_items.push(GameData::Item.get($PokemonStorage[i,j].item).id)
        $PokemonStorage[i,j].item = nil
      end
    end
  end
  party_items.each {|p_item| $PokemonBag.pbStoreItem(p_item)}
  box_items.each {|b_item| $PokemonBag.pbStoreItem(b_item)}
end
