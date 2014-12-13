#needs prettying of ingame text, doublecheck and comment
class Dungeon
	attr_accessor :player1, :player2, :player, :other_player, :rooms, :items, :maze, :game

	#initializes players, item taken trackers, achievement trackers, and other trackers
	def initialize(player_name1, player_name2)
		@player1 = Player.new(player_name1)
		@player2 = Player.new(player_name2)
		@player = @player1
		@other_player = @player2
		@rooms = []
		@items = []
		@maze = Maze.new
		
		@pills_taken = false
		@box_taken = false
		@crystal_taken = 0
		@beans_taken = false
		@notes_taken = false
		
		@escape_artists = 'escape artists'
		@pica = 'pica'
		@generous = 'generous'
		@ghostbuster = 'ghostbuster'
		@stinky = 'stinky'
		@double_stink = 'double stink'
		@overdose = 'overdose'
		@dead_and_free = 'dead and free'
		
		@eaten = 0
		@given = 0
		@game = true
	end

	#starts each player in a location
	def start(location1, location2)
		@player.location = location1
		@other_player.location = location2
	end


	
	class Player
		attr_accessor :name, :location, :stench, :beans, :pills, :inventory, :dead

		def initialize(name)
			@name = name
			@stench = 0
			@beans = 0
			@pills = 0
			@inventory = []
			@dead = false
		end
	end

	class Room
		attr_accessor :reference, :description, :connections, :items

		def initialize(reference, description, connections, items)
			@reference = reference
			@description = description
			@connections = connections
			@items = items
		end
	end

	#describes a maze with a garden and a random number of other rooms
	class Maze
		attr_accessor :rooms

		def initialize 
			@rooms = []
			num_rooms = rand(6) + 5
			num_rooms.times do |i|
				num_exits = rand(4) + 1
				exits = [:north, :east, :south, :west].sample(num_exits)
				case num_exits
					when 1 then exits_string = "an exit to the " + exits[0].to_s + "."
					when 2 then exits_string = "exits to the " + exits[0].to_s + " and " + exits[1].to_s + "."
					when 3 then exits_string = "exits to the\n" + exits[0].to_s + ", " + exits[1].to_s + 
											   ", and " + exits[2].to_s + "."
					when 4 then exits_string = "exits to the\n" + exits[0].to_s + ", " + exits[1].to_s + 
											   ", " + exits[2].to_s + ", and " + exits[3].to_s + "."
				end
				@rooms << Room.new(i.to_s.to_sym, "a dark, twisting passage with " + exits_string, exits, [])
			end
			unless @beans_taken
				@rooms << Room.new(:garden, 
								  "an open space lit through a crack in the ceiling.\n"\
								  "There are plants growing under a beam of sunshine. There are\n"\
								  "exits to the north, east, south, and west.", 
								  [:north, :east, :south, :west], [:beans])
			end
		end 
	end

	class Item
		attr_accessor :reference, :description, :location

		def initialize(reference, description, location)
			@reference = reference
			@description = description
			@location = location
		end
	end



	def add_room(reference, description, connections, items)
		@rooms << Room.new(reference, description, connections, items)
	end

	def add_item(reference, description, location)
		@items << Item.new(reference, description, location)
	end



	#returns a room in this class's maze object, given the room's reference
	def find_room_in_maze(reference)
		@maze.rooms.detect{|room| room.reference == reference}
	end

	#returns room object in dungeon or maze, given room's reference
	#returns nil if reference isn't valid
	def find_room_in_dungeon(reference)
		room = @rooms.detect{|room| room.reference == reference}
		room = find_room_in_maze(reference) if room == nil
		room
	end

	#returns reference of destination given reference of a direction
	#returns nil if direction isn't valid
	def find_room_in_direction(direction)
		find_room_in_dungeon(@player.location).connections[direction]
	end

	#returns item object given its reference
	#returns nil if reference isn't valid
	def find_item(reference)
		@items.detect{|i| i.reference = reference}
	end



	#handles regular movement in dungeon, not movement in maze or entrance of maze
	#puts result of movement attempt, and if valid:
		#changes player location, deals with location effects, and switches player.
	def go(direction)
		valid = true
		reply = "\nYou go " + direction.to_s
		if find_room_in_direction(direction) == nil
			reply = "\nYou can't go that way" 
			valid = false
		else
			@player.location = find_room_in_direction(direction)
			
			#Rubbisher effect, in case player enters Rubbisher
			#and is wobbed out before beginning turn
			if @player.location == :Rubbisher
				@player.stench = 4 
				@player.beans = 0
			end
		
		end
		puts reply
		switch_player if valid
	end

	#puts player in a random room in maze
	def enter_maze
		@player.location = @maze.rooms.sample.reference
		puts "You go west."
	end

	#puts result of movement attempt in maze, and switches player if valid
	def go_maze(direction)
		location = find_room_in_maze(@player.location)
		valid = true
		reply = "You go " + direction.to_s + "."
		unless location.connections.include?(direction)
			reply = "You can't go that way" 
			valid = false
		else
			@player.location = @maze.rooms.sample.reference
		end
		puts reply
		switch_player if valid
	end



	#puts description of the room current player is in
	def show_current_description
		location = find_room_in_dungeon(@player.location)
		reply = String.new

		#format of description depends on location: dungeon, Lair, or maze?
		if find_room_in_maze(@player.location) == nil
			reply = "\n" + @player.name + " is in the " + location.reference.to_s + 
					",\n" + location.description
			if @player.location == :Lair
				if find_room_in_dungeon(:Lair).connections[:north] == nil
					reply += " A malformed creature crouches on its\n"\
							 "haunches in the middle of the room. There's an exit to\n"\
							 "the south." 
				else
					reply += " There are exits to the north and south."
				end
			end
		else
			reply = "\n" + @player.name + " is in " + location.description 
		end
		
		#adds list of items dropped on floor
		floor = location.items.clone
		case location.reference
		when :Laboratorium then
			floor.delete(:crystal) if @crystal_taken == 0
			floor.delete_at(floor.find_index(:crystal)) if @crystal_taken == 1
		when :Lounge then
			floor.delete(:pills) unless @pills_taken
		when :garden then
			floor.delete(:beans) unless @beans_taken
		when :Library then
			floor.delete(:box) unless @box_taken
		when :Study then
			floor.delete(:notes) unless @notes_taken
		end
		if floor.size == 1
			reply += "\nThere's the following item on the floor: " + floor.join
		end
		if floor.size > 1
			reply += "\nThere are the following items on the floor:\n" + floor.join(", ")
		end
		puts reply
	end

	#puts current player's inventory
	def show_inventory
		empty = String.new
		empty = "empty pockets" if @player.inventory.size == 0
		puts "\nYou have: " + @player.inventory.join(", ") + empty
	end

	#puts currently available commands
	def valid_input
		#adds single word commands
		valid = ['help', 'wait', 'inventory']
		location = find_room_in_dungeon(@player.location)
		location.connections.each do |direction, destination|
			valid << direction.to_s
		end
		
		#adds two word commands
		@player.inventory.each do |reference|
			['eat', 'throw', 'examine', 'drop'].each do |action|
			valid << action + " " + reference.to_s
			end
		end
		if @player.location == @other_player.location || @player.location == :Lair
			@player.inventory.each do |reference|
				valid << 'give' + " " + reference.to_s
			end
		end
		if @player.inventory.include?(:crystal) && @other_player.inventory.include?(:crystal)
			valid << 'wob crystal'
		end
		case @player.location
		when :Laboratorium then
			valid << 'look tools'
			valid << 'take crystal' unless @crystal_taken > 1
		when :garden then
			valid << 'look plants'
			valid << 'take beans' unless @beans_taken
		when :Lounge then
			valid << 'look chair'
			valid << 'take pills' unless @pills_taken
		when :Library then
			valid << 'look pedestal'
			valid << 'take box' unless @box_taken
		when :Study then
			valid << 'look papers'
			valid << 'take notes' unless @notes_taken
		when :Lair then
			valid << 'wob box' if @player.inventory.include?(:box)
			valid << 'look creature'
			valid << 'take creature'
		end
		valid.each do |string|
			puts string
		end
	end



	#switches players and handles a whole shitton of other stuff
	def switch_player
		puts "\n"
		if @player == @player1
			@player = @player2
			@other_player = @player1
		else
			@player = @player1
			@other_player = @player2
		end
		
		#Matt easter egg
		if @player.name.downcase == 'matt'
			descriptors = [' the Amazing', ' the Hero', ' the Incroyable', 
						   ' the Handsome', ' the Clever', ' the Wonderful', ' the Indominable']
			@player.name = @player.name + descriptors.sample
		end

		@player.stench -= 1
		@player.stench = 4 if @player.location == :Rubbisher
		@player.beans -= 1
		@player.pills += 1 if @player.pills > 0
		if @player.location == :free && @other_player.location == :free
			@escape_artists = @escape_artists.upcase
			if @player.stench > 0 || @player.beans > 0 || @other_player.stench > 0 || @other_player.beans > 0
				@stinky = @stinky.upcase
			end
			if (@player.stench > 0 && @other_player.beans > 0) || (@player.beans > 0 && @other_player.stench > 0)
				@double_stink = @double_stink.upcase
			end
			puts "\nYou've both escaped! Congratulations!"
			if @player.dead
				puts @player.name + " is dead."
				@dead_and_free = @dead_and_free.upcase
			end
			puts "\nSomething smells awful... the magic in those beans doesn't\nseem to be good for your digestion.\n" if @player.beans > 0 && @player.location != :Rubbisher
			puts "\nSomething smells awful... the stench from the Rubbisher lingers on you.\n" if @player.stench > 0 && @player.location != :Rubbisher
			if @other_player.dead
				puts @other_player.name + " is dead."
				@dead_and_free = @dead_and_free.upcase
			end
			puts "\nSomething smells awful... the magic in those beans doesn't\nseem to be good for your digestion.\n" if @other_player.beans > 0
			puts "\nSomething smells awful... the stench from the Rubbisher lingers on you.\n" if @other_player.stench > 0
			show_achievements
			@game = false
			return
		end
		if @player.location == :free && @other_player.dead
			puts "\nYou've escaped, but you've left your friend behind to rot.\n"\
				 "Way to go, hero."
			@game = false
		end
		if @player.location == :free
			puts "\n" + @player.name + " is free!"
		end
		if @player.dead
			puts "\n" + @player.name + " is dead."
		end
		show_current_description unless @player.location == :free
		puts "\nThe world swims before your eyes." if @player.pills == 2
		puts "\nIn the corners of your vision, colorful phantasms\nflicker in and out of being." if @player.pills == 3
		puts "\nYou can see a spirit world overlaying the real one.\nYour stomach hurts." if @player.pills == 4
		puts "\nYou can see a spirit world overlaying the real one.\nYour entire body is starting to hurt." if @player.pills == 5
		if [4, 5].include?(@player.pills) && @player.location == :Lair && find_room_in_dungeon(:Lair).connections[:north] == nil
			puts "\nThe creature's image in the spirit world is far stronger than\n"\
				 "in the real. In the spirit world, you can see the ideas holding\n"\
				 "the creature together... you reach out your hand and you can\n"\
				 "feel them, too. You twist your fingers and those ideas shift.\n"\
				 "The creature blurs and disappears. In it's place, a mouse falls\n"\
				 "to the floor and scampers away. Without the creature there, you\n"\
				 "can see an exit to the north." 
			win_door(:Lair, :north)
		end	
		if @player.pills == 6
			puts "\nYour entire body feels like tiny rats are eating you from inside your veins,\n"\
			"and the rats are on fire. You can't do anything but lie on the floor and moan."
			@player.dead = true
			@overdose = @overdose.upcase
			switch_player
			return
		end
		puts "\nSomething smells awful... the magic in those beans doesn't\nseem to be good for your digestion.\n" if @player.beans > 0
		puts "\nSomething smells awful... the stench from the Rubbisher lingers on you.\n" if @player.stench > 0 && @player.location != :Rubbisher
		if @player.location == :Lair && (@player.stench > 0 || @player.beans > 0) && find_room_in_dungeon(:Lair).connections[:north] == nil
			puts "\nThe creature takes a step back, and wrinkles its already wrinkly nose. As it\n"\
			"glides to the side and disappears through the wall, you think you hear it\n"\
			"mutter something about the disadvantages of an enhanced sense of smell.\n"\
			"Without the creature there, you can see an exit to the north."
			win_door(:Lair, :north)
		end
		if @player.location == :free && @other_player.dead
			return
		end
		if @player.location == :free
			switch_player
			return
		end
		if @player.dead
			switch_player
			return
		end

		#Matt easter egg
		if ['matt the amazing', 'matt the hero', 'matt the incroyable', 
			'matt the handsome', 'matt the clever', 'matt the wonderful', 
			'matt the indominable'].include?(@player.name.downcase)
			@player.name = @player.name.slice(0, 4)
		end
	
	end



	def eat(reference)
		item = @items.detect{|i| i.reference == reference && i.location == @player.inventory}
		reply = "\nYou have no such thing."
		valid = false
		unless item == nil
			reply = "\nYou eat the " + reference.to_s + "."
			@player.inventory.delete_at(@player.inventory.find_index(reference))
			item.location = nil
			valid = true
			case reference
			when :beans then
				reply += " They taste like magic."
				@player.beans = 5
				@player.stench = 0
			when :pills then
				reply += " You throw the empty bottle away.\nMaybe it wasn't such a good idea to take them all at once..."
				@player.pills = 1
			else
				@eaten += 1
				@pica = @pica.upcase if @eaten > 3
				reply += " You have no idea why you did that."
			end
		end
		puts reply
		switch_player if valid
	end

	def throw(reference)
		item = @items.detect{|i| i.reference == reference && i.location == @player.inventory}
		reply = "\nYou have no such thing."
		valid = false
		unless item == nil
			reply = "\nYou throw the " + reference.to_s + "."
			item.location = @player.location
			find_room_in_dungeon(@player.location).items << reference unless @player.location == :Rubbisher
			@player.inventory.delete_at(@player.inventory.find_index(reference))
			valid = true
			case @player.location
			when :Lair then
				case reference
				when :pills then
					reply += " The bottle passes through the monster,\nbounces off the wall, and lands in front of you."
				when :notes then
					reply += " They flutter to the floor in front of you."
				when :beans then
					reply += " They pass through the monster, bounce\noff the wall, and land in front of you."
				when :crystal, :box then
					reply += " It passes through the monster, bounces\noff the wall, and lands in front of you."
				end
			when :Rubbisher then
				item.location = nil
				case reference
				when :pills then
					reply += " The bottle lands in the pit and disappears\nin the junk."
				when :crystal, :box then
					reply += " It lands in the pit and disappears\nin the junk."
				when :papers, :beans then
					reply += " They land in the pit and disappear\nin the junk."
				end
			else
				reply += " You have no idea why you did that."
			end
		end
		puts reply
		switch_player if valid
	end

	def examine(reference)
		item = find_item(reference)
		reply = "\nYou have no such thing."
		reply = "\n" + item.description if @player.inventory.include?(reference)
		puts reply
	end

	def give(reference)
		item = @items.detect{|i| i.reference == reference && i.location == @player.inventory}
		reply = "\nYou have no such thing."
		valid = false
		unless item == nil
			reply = "\nYou have nobody to give that to."
			if @player.location == :Lair
				reply = "\nYou offer the " + reference.to_s + " to the monster, but it only blinks at you." 
			end
			if @player.location == @other_player.location
				@given += 1
				@generous = @generous.upcase if @given > 3
				reply = "\nYou give the " + reference.to_s + " to your friend."
				@player.inventory.delete_at(@player.inventory.find_index(reference))
				@other_player.inventory << reference
				item.location = @other_player.inventory
				valid = true
			end
		end
		puts reply
		switch_player if valid
	end

	def wob(reference)
		item = find_item(reference)
		reply = "\nYou have no such thing."
		valid = false
		if @player.inventory.include?(reference)
			reply = "\nYou wob the " + reference.to_s + "."
			case reference
			when :crystal then
				if @other_player.inventory.include?(reference)
					reply += " Your friend is pulled to your side!"
					@other_player.stench = 4 if @other_player.location == :Rubbisher
					@other_player.location = @player.location
					valid = true
				else
					reply += " Nothing happens."
				end
			when :box then
				if @player.location == :Lair && find_room_in_dungeon(:Lair).connections[:north] == nil
					reply += " The monster begins coming apart in wisps that\n"\
					"are drawn into the box! The box's doors slam behind the last\n"\
					"of the ghost. Without it in the room, you can see an exit\n"\
					"leading to the north."
					win_door(:Lair, :north)
					@ghostbuster = @ghostbuster.upcase
					valid = true
				else
					reply += " Nothing happens."
				end
			else
				reply += " You have no idea why you did that."
			end
		end
		puts reply
		switch_player if valid
	end

	def look(reference)
		reply = "\nThat is either absent or uninteresting."
		case [reference, @player.location]
		when [:pills, :Lounge] then
			if @pills_taken
				reply = "\nIt's a very cushy chair."
			else
				reply = "\nDeep in a crack between two cushions you find a bottle of pills."
			end
		when [:box, :Library] then
			if @box_taken
				reply = "\nIt's just your common library pedestal."
			else
				reply = "\nThere's a small box on the pedestal."
			end
		when [:crystal, :Laboratorium] then
			if @crystal_taken > 1
				reply = "\nA bunch of junk, as far as you can tell."
			else
				reply = "\nAmong the tools, a beautiful blue crystal catches your eye."
			end
		when [:beans, :garden] then
			if @beans_taken
				reply = "\nIt's nice to see a bit of green."
			else 
				reply = "\nThere are beans on the plants. They smell like magic."
			end
		when [:notes, :Study] then
			if @notes_taken
				reply = "\nIt's a mess of dusty, uninteresting papers."
			else
				reply = "\nThere's a set of notes here that isn't covered with dust."
			end
		when [:ghost, :Lair] then
			reply = "\nIt's " + find_item(:ghost).description
		end
		puts reply
	end

	def take(reference)
		item = @items.detect{|i| i.reference == reference && i.location == @player.location}
		location = find_room_in_dungeon(@player.location)
		reply = "\nThere's no such thing here"
		valid = false
		unless item == nil
			if reference == :ghost
				puts "\nYou move towards the creature and it snarls at you.\n"\
						"You decide to leave it alone."
				return
			end
			reply = "\nYou pick up " + item.description
			location.items.delete_at(location.items.find_index(reference.to_sym))
			item.location = @player.inventory
			@player.inventory << reference
			valid = true
			case reference
			when :pills then
				@pills_taken = true
			when :box then
				@box_taken = true
			when :crystal then
				@crystal_taken += 1
			when :beans then
				@beans_taken = true
			when :notes then
				@notes_taken = true
			end
		end
		puts reply
		switch_player if valid
	end

	def drop(reference)
		item = @items.detect{|i| i.reference == reference && i.location == @player.inventory}
		reply = "\nYou have no such thing" 
		valid = false
		unless item == nil
			reply = "\nYou drop " + item.description
			@player.inventory.delete_at(@player.inventory.find_index(reference))
			item.location = @player.location
			find_room_in_dungeon(@player.location).items << reference
			valid = true
		end
		puts reply
		switch_player if valid
	end



	def win_door(room, direction)
		add_room(:free, '', {}, [])
		room = find_room_in_dungeon(room)
		room.connections[direction] = :free
		find_room_in_dungeon(:Lair).items.delete(:ghost)
		find_item(:ghost).location == nil
	end

	def show_achievements
		puts "\nYour achievements:"
		puts @escape_artists
		puts @pica + "       " + @generous + "      " + @ghostbuster
		puts @stinky + "     " + @double_stink
		puts @overdose + "   " + @dead_and_free
	end
end



#create the main dungeon object
puts "\nGeondun is meant to be explored more than won. Don't be\n"\
	 "afraid to restart if you think you've reached a dead end.\n"\
	 "Type 'inventory' to see what you have, 'quit' to quit, and\n"\
	 "'help' if you get really stuck."
puts "\nWhat's your name?"
player1 = gets.chomp.strip
while player1 == ''
	puts "What's that again?"
	player1 = gets.chomp.strip
end
puts "\nWhat's your friend's name?"
player2 = gets.chomp.strip
while player2 == '' || player2 == player1
	puts "What's that again?" if player2 == ' '
	puts "Choose a different friend" if player2 == player1
	player2 = gets.chomp.strip
end
geondun = Dungeon.new(player2, player1)

#add rooms
geondun.add_room(:Laboratorium, 
				"a small, high-ceilinged space cluttered with tools.\n"\
				"There are exits to the north, east, and west.", 
				{:east => :Rubbisher, :north => :Lounge, :west => :Maze}, [:crystal, :crystal])
geondun.add_room(:Rubbisher, 
				"a pit filled with refuse and stench. There's an exit\n"\
				"to the west.\nIt smells awful.", 
				{:west => :Laboratorium}, [])
geondun.add_room(:Lounge, 
				"a cozy room containing a deep, plush chair. There\n"\
				"are exits to the north and south.", 
				{:south => :Laboratorium, :north => :Library}, [:pills])
geondun.add_room(:Library, 
				"a room covered wall-to-wall in empty bookshelves.\n"\
				"There's a pedestal in one dusty corner. There are\n"\
				"exits to the north, south, and west.", 
				{:north => :Lair, :west => :Study, :south => :Lounge}, [:box])
geondun.add_room(:Study, 
				"a room only big enough for a desk and chair. Papers\n"\
				"are strewn over the desk. There's an exit to the east.",
				{:east => :Library}, [:notes])
geondun.add_room(:Lair, "a rough cavern.", {:south => :Library}, [])

#add items
geondun.add_item(:pills,
				"a bottle labled 'Tchitsuun', half full of pills", 
				:Lounge)
geondun.add_item(:box, 
				"a box covered in mysterious gadgets.\n"\
				"It has what looks like yellow and black striped\n"\
				"doors on one side.", 
				:Library)
geondun.add_item(:crystal, 
				"a carefully cut and polished blue crystal", 
				:Laboratorium)
geondun.add_item(:crystal, 
				"a carefully cut and polished blue crystal", 
				:Laboratorium)
geondun.add_item(:beans, 
				"fresh haricot beans. They look like food,\n"\
				"but they smell like magic.", 
				:garden)
geondun.add_item(:notes, 
				"two pages. The first is part of a page that\n"\
				"looks like it was torn from a book. It reads: 'nd hallucinations.\n"\
				"Delusions often include the belief, persistent after other\n"\
				"effects have subsided, that previous hallucinations continue\n"\
				"to influence reality. Tests have '. The second is a page of hurriedly\n"\
				"scribbled, barely legible notes. It reads: 'The old [unclear]\n"\
				"...[unclear] is NOT [unclear]!! It's [unclear] PERMEABLE to \n"\
				"[unclear]...[unclear]lasm remains?'", 
				:Study)
geondun.add_item(:ghost, 
				"a malformed creature crouching on its haunches\n"\
				"in the middle of the room. It looks like somebody took\n"\
				"a bear, covered it with an entire elephant skin, hanging\n"\
				"in folds, and replaced its paws with gorilla hands before\n"\
				"going home and sleeping off the tchitsuun. It doesn't look\n"\
				"pleased to be disturbed.", 
				:Lair)

#start the dungeon by placing the players in the Laboratorium
geondun.start(:Laboratorium, :Laboratorium)
geondun.switch_player
single = ['east', 'north', 'west', 'south', 'wait', 'inventory', 'help', 'quit']
double = ['eat', 'throw', 'examine', 'give', 'wob', 'look', 'take', 'drop']
help_asked = false

#process actions
loop do 	
	break unless geondun.game

	#take input
	input = gets.chomp.split(' ')
	tries = 0
	until (input.size == 2 && double.include?(input[0]) && geondun.items.include?(geondun.find_item(input[1].to_sym))) or
		  (input.size == 1 && single.include?(input[0])) or
		  (input.size == 2 && input[0] == 'look' && ['tools', 'chair', 'pedestal', 'papers', 'plants', 'creature'].include?(input[1])) or
		  (input.size == 2 && input[0] == 'take' && input[1] == 'creature')
		puts 'What?'
		tries += 1
		puts "Maybe you'd like to " + double.sample.to_s + " something?" if tries >= 2
		input = gets.chomp.split(' ')
	end

	#single command management
	if single.include?(input[0])
		break if input[0] == 'quit'
		if input[0] == 'wait'
			geondun.switch_player
			next
		end
		if input[0] == 'inventory'
			geondun.show_inventory
			next
		end
		if input[0] == 'help'
			unless help_asked
				puts "\nAre you SURE??"
				answer = gets.chomp.strip.downcase
				help_asked = true if answer == 'yes' || answer == 'y'
			end
			if help_asked
				puts "\nAvailable commands: "
				geondun.valid_input
			end
			next
		end
		if geondun.rooms.include?(geondun.find_room_in_dungeon(geondun.player.location))
			if geondun.player.location == :Laboratorium && input[0] == 'west'
				geondun.enter_maze
				geondun.switch_player	
				next
			end
			geondun.go(input[0].to_sym)
			next
		else 
			geondun.go_maze(input[0].to_sym)
			next
		end
	end
	
	#special processing for 'look' and 'take'
	if input[0] == 'look'
		case input[1]
		when 'tools' then
			input[1] = 'crystal'
		when 'chair' then
			input[1] = 'pills'
		when 'pedestal' then
			input[1] = 'box'
		when 'papers' then
			input[1] = 'notes'
		when 'plants' then
			input[1] = 'beans'
		when 'creature' then
			input[1] = 'ghost'
		end
	end
	if input[0] == 'take' && input[1] == 'creature'
		input[1] = 'ghost'
	end

	#double command management
	method = input[0].to_sym
	geondun.send method, input[1].to_sym
	next
end
