# Classless Dialogue Scripts meant to make the game easier to work with
# Incorporating these will actually cause events to process quicker than using the Show Text commands

DIALOGUE_DATA = {}

$currentDialogue = nil

class Dialogue
  def self.set_dialogue(id,event_id,gender="male")
    color = gender == "male" ? "7fe00000" : "463f0000"
    DIALOGUE_DATA[id] = {} if DIALOGUE_DATA[id].nil?
    DIALOGUE_DATA[id][:event_id] = event_id
    DIALOGUE_DATA[id][:color] = color
    DIALOGUE_DATA[id][:dialogue] = []
    $currentDialogue = id
  end

  def self.id
    return $currentDialogue
  end

  def self.data(id=self.id)
    return DIALOGUE_DATA[id]
  end

  def self.pbDisplay(msg)
    data = self.data
    color = data[:color]
    event_id = data[:event_id]
    pbCallBub(2,event_id)
    pbMessage(_INTL("\\[{1}]{2}",color,msg))
  end

  def self.pbEndDialogue
    $currentDialogue = nil
  end

  def self.elipsis_pause(length=10)
    pbDisplay(_INTL("\\ts[{1}]...",length))
  end

  def self.register_all
    self.joseph_nenox
    self.sylvester_secret_lab
    self.sylvester_secret_lab_post_battle
    PBAI.log_misc("All dialogue registered.")
  end

  def self.register_dialogue(msg)
    data = self.data
    data[:dialogue].push(msg)
  end

  def self.register_elipsis
    data = self.data
    data[:dialogue].push("...")
  end

  def self.get_character(parameter = 0)
      case parameter
      when -1   # player
        return $game_player
      when 0    # this event
        events = $game_map.events
        return (events) ? events[@event_id] : nil
      else      # specific event
        events = $game_map.events
        return (events) ? events[parameter] : nil
      end
    end

  def self.display_dialogue(id)
    data = self.data(id)
    event_id = data[:event_id]
    set_dialogue(id,event_id)
    data[:dialogue].each do |msg|
      if msg == "..."
        elipsis_pause
      else
        pbDisplay(msg)
      end
    end
    pbEndDialogue
  end

  #====================================================================#
  #                      Actual Dialogue Data                          #
  #====================================================================#

  def self.joseph_nenox
    set_dialogue(:joseph_nenox,3)
    register_dialogue("Oh, \\PN, I didn't realize you'd gotten here so soon.")
    register_dialogue("I was just coming to check on Sylvester because I heard the Militia was headed this way.")
    register_elipsis
    register_dialogue("Wait, you've already beaten them? You really do move fast, huh?")
    register_dialogue("Well, again I'm in your debt. I hate that you're having to go around and clean up messes meant for adults.")
    register_dialogue("Anyway, I'm sure I'll be seeing you again. I say your next bet is to head back to Neonn Town.")
    register_dialogue("There's a cave hidden somewhere on Route 4 that should set you on the right path toward your next Gym.")
    register_elipsis
    register_dialogue("Well, good luck \\PN!")
    pbEndDialogue
  end
  def self.sylvester_secret_lab
    set_dialogue(:sylvester_secret_lab,4)
    register_elipsis
    register_dialogue("I figured you'd eventually find this place.")
    register_dialogue("I came here to make sure all our data was backed up to HQ before I shut this place down.")
    register_dialogue("But you just can't leave things alone, can you?")
    register_elipsis
    register_dialogue("Well, \\PN, you leave me no choice but to bury you here with what remains of this lab.")
    pbEndDialogue
  end
  def self.sylvester_secret_lab_post_battle
    set_dialogue(:sylvester2,4)
    register_dialogue("I can see why the others are irritated with you too.")
    register_dialogue("You're quite strong, but you don't stand a chance against what we've been building.")
    register_dialogue("In fact, I'd be willing to bet the Zirco team has finished their final test of it.")
    register_dialogue("So while I'd like to hope otherwise, I'm betting I'll see you later, \\PN.")
    pbEndDialogue
  end
  
end