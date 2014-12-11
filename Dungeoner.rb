class Dungeon
	attr_accessor :player1, :player2, :player, :rooms, :items, :maze, :game

	def initialize(player_name1, player_name2)
		@player1 = Player.new(player_name1)
		@player2 = Player.new(player_name2)
		@player = @player1
		@other_player = @player2
		@rooms = []
		@items = []
		@pills_taken = false
		@box_taken = false
		@crystal_taken = 0
		@beans_taken = false
		@notes_taken = false
		@game = true
	end

	def start(location1, location2)
		@player.location = location1
		@other_player.location = location2
	end

	def show_current_description
		location = find_room_in_dungeon(@player.location)
		puts @player.name + " is in the " + location.reference.to_s + ",\n" + location.description
	end

	def find_room_in_dungeon(reference)
		@rooms.detect{|room| room.reference == reference}
	end

	def find_room_in_direction(direction)
		find_room_in_dungeon(@player.location).connections[direction]
	end

	def go(direction)
		valid = true
		reply = "\nYou go " + direction.to_s
		if find_room_in_direction(direction) == nil
			reply = "\nYou can't go that way" 
			valid = false
		else
			@player.location = find_room_in_direction(direction)
			if @player.location == :Rubbisher
				@player.stench = 4 
				@player.beans = 0
			end
			if @player.location == :free
				@player.won = true
			end
		end
		puts reply
		switch_player if valid
	end

	def find_item(reference)
		@items.detect{|i| i.reference = reference}
	end

	def show_inventory
		empty = ''
		empty = "empty pockets" if @player.inventory.size == 0
		puts "You have: " + @player.inventory.join(", ") + empty
	end


	class Player
		attr_accessor :name, :location, :stench, :beans, :pills, :inventory, :dead, :won

		def initialize(name)
			@name = name
			@stench = 0
			@beans = 0
			@pills = 0
			@inventory = []
			@dead = false
			@won = false
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

		def full_description
			@reference.to_s + "\n\nYou are in " + @description
		end
	end


	class Maze
		attr_accessor :rooms

		def initialize 
			@rooms = []
			num_rooms = rand(6) + 5
			num_rooms.times do |i|
				num_exits = rand(4) + 1
				exits = [:north, :east, :south, :west].sample(num_exits)
				case num_exits
					when 1 then exits_string = "an exit to the " + exits[0].to_s + '.'
					when 2 then exits_string = "exits to the " + exits[0].to_s + ' and ' + exits[1].to_s + '.'
					when 3 then exits_string = "exits to the\n" + exits[0].to_s + ', ' + exits[1].to_s + 
											   ', and ' + exits[2].to_s + '.'
					when 4 then exits_string = "exits to the\n" + exits[0].to_s + ', ' + exits[1].to_s + 
											   ', ' + exits[2].to_s + ', and ' + exits[3].to_s + '.'
				end
				@rooms << Room.new(i.to_s.to_sym, 'a dark, twisting passage with ' + exits_string, exits, [])
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


	def switch_player
		if @player == @player1
			@player = @player2
			@other_player = @player1
		else
			@player = @player1
			@other_player = @player2
		end
		if @player.won && @other_player.won
			puts "\nYou've both escaped! Congratulations!"
			show_achievements
			return
		end
		if @player.dead
			puts @player.name + " is dead."
			switch_player
		end
		if @player.won
			puts @player.name + " is free!"
			switch_player
		end
		@player.stench -= 1
		@player.beans -= 1
		@player.pills += 1 if @player.pills > 0
		if @rooms.include?(find_room_in_dungeon(@player.location))
			puts "\n"
			show_current_description
		else
			puts "\n"
			maze_description
		end
		puts "Something smells awful... the magic in those beans doesn't\nseem to be good for your digestion.\n" if @player.beans > 0
		puts "Something smells awful... the stench from the Rubbisher lingers on you.\n" if @player.stench > 0 && @player.location != :Rubbisher
		puts "The world swims before your eyes." if @player.pills == 1
		puts "In the corners of your vision, colorful phantasms\nflicker in and out of being." if @player.pills == 2
		puts "You can see a spirit world overlaying the real one.\nYour stomach hurts." if @player.pills == 3
		puts "You can see a spirit world overlaying the real one.\nYour entire body is starting to hurt." if @player.pills == 4
		if [3,4].include?(@player.pills) && @player.location == :boss
			puts "The monster's image in the spirit world is far stronger than\n"\
				 "in the real. In the spirit world, you can see the ideas holding\n"\
				 "the creature together... you reach out your hand and you can\n"\
				 "feel them, too. You twist your fingers and those ideas shift. In\n"\
				 "the creature's place, a mouse falls to the floor and scampers away.\n" 
			win_door
		end	
		if @player.pills > 4
			puts "Your entire body feels like tiny rats are eating you from inside your veins,\n"\
			"and the rats are on fire. You can't do anything but lie on the floor and moan."
			@player.dead = true
		end 
	end

	def add_room(reference, description, connections, items)
		@rooms << Room.new(reference, description, connections, items)
	end

	def enter_maze
		@maze = Maze.new
		@player.location = @maze.rooms.sample.reference
		puts "You go west."
	end

	def find_room_in_maze(reference)
		@maze.rooms.detect{|room| room.reference == reference}
	end

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

	def maze_description
		location = find_room_in_maze(@player.location)
		puts @player.name + " is in " + location.description
	end

	def add_item(reference, description, location)
		@items << Item.new(reference, description, location)
	end

	def find_item(reference)
		@items.detect{|i| i.reference == reference}
	end

	def eat(reference)
		item = find_item(reference)
		reply = "You eat the " + item.label + ". "
		reply = "You have no such thing." unless @player.inventory.include?(item)
		@player.inventory.delete(self)
		item.location = nil
		if @player.inventory.include?(item)
			case item.label
			when 'beans' then
				reply += "They taste like magic."
				@player.beans = 5
				@player.stench = 0
			when 'pills' then
				reply += "You throw the empty bottle away. Maybe it wasn't such a good idea to take them all at once..."
				@player.pills = 1
			else
				reply += "You have no idea why you did that."
			end
		end
		puts reply
		switch_player
	end

	def throw(reference)
		item = find_item(reference)
		reply = "You throw the " + reference.to_s + ". "
		reply = "You have no such thing." unless @player.inventory.include?(reference)
		@player.inventory.delete(reference)
		item.location = @player.location
		if @player.inventory.include?(reference)
			case @player.location
			when :Lair then
				case reference
				when :pills then
					reply += "The bottle passes through the monster, bounces off the wall, and lands in front of you."
				when :notes then
					reply += "They flutter to the floor in front of you."
				when :beans then
					reply += "They pass through the monster, bounce off the wall, and land in front of you."
				when :crystal, 'box' then
					reply += "It passes through the monster, bounces off the wall, and lands in front of you."
				end
			when :Rubbisher then
				item.location = nil
				case reference
				when :pills then
					reply += "The bottle lands in the pit and disappears in the junk."
				when :crystal, :box then
					reply += "It lands in the pit and disappears in the junk."
				when :papers, :beans then
					reply += "They land in the pit and disappear in the junk."
				end
			else
				reply += "You have no idea why you did that."
			end
		end
		puts reply
		switch_player
	end

	def examine(reference)
		item = find_item(reference)
		reply = item.description
		reply = "You have no such thing." unless @player.inventory.include?(reference)
		puts reply
	end

	def give(reference)
		item = find_item(reference)
		valid = true
		reply = "You give the " + reference.to_s + " to your friend."
		unless @player.location == @other_player.location
			reply = "You have nobody to give that to." 
			valid = false
		end
		if @player.location == :boss && @other_player.location != :boss
			reply = "You offer the " + reference.to_s + " to the monster, but it only blinks at you." 
			valid = false
		end
		unless @player.inventory.include?(reference)
			reply = "You have no such thing." 
			valid = false
		end
		@player.inventory.delete(reference)
		@other_player.inventory << reference
		item.location = @other_player.inventory
		puts reply
		switch_player if valid
	end

	def wob(reference)
		item = find_item(reference)
		reply = "You wob the " + reference.to_s + ". "
		reply = "You have no such thing." unless @player.inventory.include?(reference)
		if @player.inventory.include?(reference)
			case reference
			when :crystal then
				if @other_player.inventory.include?(reference)
					reply += "Your friend is pulled to your side!"
					@other_player.location = @player.location
				else
					reply += "Nothing happens."
				end
			when :box then
				if @player.location = :Lair
					reply += "The monster begins coming apart in wisps that are\n"\
					"drawn into the box! The box's doors slam behind the last\n"\
					"of the ghost. Without it in the room, you can see an exit\n"\
					"leading to the north."
					win_door(:Lair, :north)
				else
					reply += "Nothing happens."
				end
			else
				reply += "You have no idea why you did that."
			end
		end
		puts reply
		switch_player
	end

	def look(reference)
		item = @items.detect{|i| i.reference == reference}
		reply = "That is either absent or uninteresting."
		case [item.reference, @player.location]
		when [:pills, :Lounge] then
			if @pills_taken
				reply = "It's a very cushy chair."
			else
				reply = "Deep in a crack between two cushions you find a bottle of pills."
			end
		when [:box, :Library] then
			if @box_taken
				reply = "It's just your common library pedestal."
			else
				reply = "There's a small box on the pedestal."
			end
		when [:crystal, :Laboratorium] then
			if @crystal_taken > 1
				reply = "A bunch of junk, as far as you can tell."
			else
				reply = "Among the tools, a beautiful blue crystal catches your eye."
			end
		when [:beans, :garden] then
			if @beans_taken
				reply = "It's nice to see a bit of green."
			else 
				reply = "There are beans on the plants. They smell like magic."
			end
		when [:notes, :Study] then
			if @notes_taken
				reply = "It's a mess of dusty, uninteresting papers."
			else
				reply = "There's a set of notes here that isn't covered with dust."
			end
		end
		puts reply
	end

	def take(reference)
		item = find_item(reference)
		location = find_room_in_dungeon(@player.location)
		location = find_room_in_maze(@player.location) if location == nil
		reply = "You pick up " + item.description
		valid = true
		unless location.items.include?(reference)
			valid = false
			reply = "There is no such thing here"
		end
		location.items.delete_at(location.items.index(reference) || location.items.size)
		item.location = :inventory
		@player.inventory << reference
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
		puts reply
		switch_player if valid
	end

	def drop(reference)
		item = find_item(reference)
		reply = "You drop " + item.description
		reply "You have no such thing" unless @inventory.include?(item)
		@inventory.delete(reference)
		item.location = @player.location.reference
		@player.location.items << reference
		puts reply
		switch_player
	end

	def win_door(room, direction)
		add_room(:free, '', {}, [])
		room = find_room_in_dungeon(room)
		room.connections[direction] = :free
	end

	def show_achievements
		escape_artist = 'ESCAPE ARTIST'
		pica = 'pica'
		pica = 'PICA'
		stinky = 'stinky'
		stinky = 'STINKY'
		double_stink = 'double stink'
		double_stink = 'DOUBLE STINK'
		ghostbuster = 'ghostbuster'
		ghostbuster = 'GHOSTBUSTER'
		overdose = 'overdose'
		overdose = 'OVERDOSE'
		dead_and_free = 'dead and free'
		dead_and_free = 'DEAD AND FREE'
		puts "Your acheivements:"
		puts escape_artist
		puts stinky + double_stink
		puts pica + ghostbuster
		puts overdose + dead_and_free
		@game = false
	end
end

#create the main dungeon object
puts "What's your name?"
player1 = gets.chomp.strip
while player1 == ''
	puts "What's that again?"
	player1 = gets.chomp.strip
end
puts "What's your friend's name?"
player2 = gets.chomp.strip
while player2 == '' || player2 == player1
	puts "What's that again?" if player2 == ' '
	puts "Choose a different friend" if player2 == player1
	player2 = gets.chomp.strip
end
puts "\n"
geondun = Dungeon.new(player1, player2)

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
				"are strewn over the desk. There's and exit to the east.",
				{:east => :Library}, [:notes])
geondun.add_room(:Lair, 
				"A malformed creature crouches on it's haunches in the\n"\
				"middle of the room. It looks like somebody took a bear,\n"\
				"covered it with an entire elephant skin,  hanging in folds,\n"\
				"and replaced it's paws with gorilla hands before going home\n"\
				"and sleeping off the tchitsuun. It doesn't look pleased\n"\
				"to be disturbed. There's an exit to the south.", 
				{:south => :Library}, [])

#add items
geondun.add_item(:pills,
				"a bottle labled 'Tchitsuun', half full of pills", 
				:Lounge)
geondun.add_item(:box, 
				"a box covered in mysterious gadgets.\n"\
				"It has what looks like yellow and black striped doors on one side.", 
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

#start the dungeon by placing the players in the Laboratorium
geondun.start(:Laboratorium, :Laboratorium)
geondun.show_current_description
single = ['east', 'north', 'west', 'south', 'wait', 'inventory']
double = ['eat', 'throw', 'examine', 'give', 'wob', 'look', 'take']

#process actions
loop do 	
	break unless geondun.game

	#take input
	input = gets.chomp.split(' ')
	tries = 0
	until (input.size == 2 && double.include?(input[0]) && geondun.items.include?(geondun.find_item(input[1].to_sym))) or
		  (input.size == 1 && single.include?(input[0])) or
		  (input.size == 2 && input[0] == 'look' && ['tools', 'chair', 'pedestal', 'papers', 'plants'].include?(input[1]))
		puts 'What?'
		tries += 1
		puts "Maybe you'd like to " + valid.sample.to_s + " something?" if tries >= 3
		input = gets.chomp.split(' ')
	end

	#single command management
	if single.include?(input[0])
		if input[0] == 'wait'
			geondun.switch_player
			next
		end
		if input[0] == 'inventory'
			geondun.show_inventory
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
	
	#special processing for 'look'
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
		end
	end

	#double command management
	method = input[0].to_sym
	geondun.send method, input[1].to_sym
	next
end
