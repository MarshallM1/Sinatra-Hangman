require 'sinatra'
require 'sinatra/reloader' if development?

#todo
# Add styles
# Prep for heroku deployment

enable :sessions

get '/' do
	if variables.nil?
		newgame
	end
	variables
	erb :index
end

get '/newgame' do
  newgame
  redirect to('/')
end

get '/lost' do
  variables
  erb :lost
end

get '/won' do
  variables
  erb :won
end

post '/' do
  session[:message] = ""
  check(params[:guess])
  redirect to('/')
end

helpers do

	def variables
	    @secret_word = session[:secret_word]
	    @num_guesses = session[:num_guesses]
	    @board = session[:board]
	    @wrong_guesses = session[:wrong_guesses]
	    @used_letters = session[:used_letters]
	    @message = session[:message]
	end

	def newgame
		word_array = File.readlines('5desk.txt')
		found_word = false
		while found_word == false
			potential_word = word_array[rand(word_array.length)].chomp
			if potential_word.length >= 5 && potential_word.length <= 12
				session[:secret_word] = potential_word
				found_word = true
			end
		end
		session[:num_guesses] = 8
		session[:wrong_guesses] = []
		session[:used_letters] = []
		session[:board] = "_" * session[:secret_word].length
		session[:message] = ""
	end

	def check(guess)
		guess.downcase!
		#check if guess is word or char
		if guess.length == 0
			session[:message] = "Please enter a guess"
		elsif guess.length == 1
			#find all the matching chars in the word
			#check if character has been quessed before
			if session[:used_letters].include? guess
				session[:message] = "This character has already been guessed, please guess again"
				return
			else
				session[:used_letters] << guess
				#a = (0 ... s.length).find_all { |i| s[i,1] == '#' }
				guess_index = (0 ... session[:secret_word].length).find_all {|i| session[:secret_word][i,1] == guess}
				if guess_index.length != 0	#found matches
					guess_index.each do |i|
						session[:board][i] = guess
					end
					self.check_win
				else
					session[:message] = "Sorry, but the word does not contain the letter #{guess}"
					session[:num_guesses] -= 1
					session[:wrong_guesses] << guess
					self.check_loss
				end
			end

		else	#if a word is guessed
			if guess == session[:secret_word]
				redirect to('/won')
			else
				session[:message] = "Sorry, but the word is not #{guess}"
				session[:num_guesses] -= 1
				self.check_loss
			end
		end
	end

	def check_win
		if session[:secret_word] == session[:board]
			redirect to('/won')
		else
			check_loss
		end
	end

	def check_loss
		if session[:num_guesses] <= 0
			redirect to('/lost')
		end
	end
end