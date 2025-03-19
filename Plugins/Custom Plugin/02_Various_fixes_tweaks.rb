# Fix for trainers not working
module GameData
    module ClassMethods

        alias load_original load
        def load
            if(self::DATA_FILENAME == "trainers.dat")
                print("trainers.data")
                t1 = load_data("Data/trainers.dat")
                t2 = load_data("Data/trainers_ext.dat")
                trainers = t1.merge(t2)
                const_set(:DATA, trainers)
            else
            const_set(:DATA, load_data("Data/#{self::DATA_FILENAME}"))
            end
        end
    end
end

# Remove display brief message in battles
class PokeBattle_Battle
    alias pbDisplayBrief_ebdx pbDisplayBrief
    def pbDisplayBrief(msg, &block)
        @scene.pbDisplayMessage(msg, &block)
    end
end