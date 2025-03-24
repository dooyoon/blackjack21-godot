extends Node

var numberOfDecks = 1
var deck = []
var dealer = player.new()
var player1 = player.new()
var dealtCardsImg = []
var viewCenterX
var viewCenterY
var cardSize = 125
var numberOfShuffles = 0
var stats = {'win':0, 'draw': 0, 'loss':0}
var deplayForNewHand = 2 # senconds
var loadedStats = false

enum players {dealer, player1, split, none}
enum colors {RED, BLUE, CYAN, ORANGE, GRAY, YELLOW}
enum actions {SHOW, HIDE, DOUBLE, SPLIT, DOUBLE_OFF, SPLIT_OFF}

func message(msg, colorIndex):
	$Warning.visible = true
	$Warning.text = msg

	$Warning.add_theme_font_size_override("font_size", 36)
	$Warning.add_theme_color_override('font_color',colors.keys()[colorIndex])
	
	await get_tree().create_timer(deplayForNewHand).timeout
	$Warning.visible = false
	updateMoney()

func buildDeck():
	deck.clear()
	var suits = ['Spade', 'Heart', 'Club', 'Diamond']
	#var suits = ['S', 'H', 'C', 'D']
	var values = [2,3,4,5,6,7,8,9,10,'J','Q','K','A']

	for n in numberOfDecks:
		for suit in suits:
			for value in values:
				var score=0
				if value in ['J','Q','K']:
					score = 10
				elif value in ['A']:
					score = 11
				else:
					score = value
				var card = card.new()
				card.suit = suit
				card.value = value
				card.score = score
				deck.push_back(card)
				#print('%s - %s - %s' % [suit, value, score] )

func mockCard(value):
	var card = card.new()
	var score = value
	if value in ['J','Q','K']: score=10
	if value in ['A']: score=11

	card.suit = 'Club'
	card.value = value
	card.score = score
	return card

func _ready():
	#loadGameStats()
	player1.balance = 1000

	$Timer.wait_time = deplayForNewHand
	showActions(actions.HIDE)
	viewCenterX = get_viewport().size.x / 2
	viewCenterY = get_viewport().size.y / 2
	
	buildDeck()
	$stats/Balance.text = str(player1.balance)
	$stats/Bet.text = str(player1.bet[0])

	$actions/Stand.pressed.connect(_stand_button_pressed)
	$actions/Hit.pressed.connect(_hit_button_pressed)
	$actions/Double.pressed.connect(_double_button_pressed)
	$actions/Split.pressed.connect(_split_button_pressed)
	$actions/Insurance.pressed.connect(_insurance_button_pressed)
	$placeBet.pressed.connect(_placeBet_button_pressed)
	$chip100.pressed.connect(_chip100_button_pressed)
	
	$Timer.timeout.connect(resetTable)

func resetTable():
	saveGameStats()

	showActions(actions.HIDE)

	dealer.hands.clear()

	player1.hands.clear()
	player1.bet = [0]

	$scores/totalDealer.visible = false
	$scores/totalPlayer.visible = false
	$scores/totalSplit.visible = false
	$placeBet.visible = true
	
	for card in dealtCardsImg:
		remove_child(card)
	
	dealtCardsImg.clear()

	if deck.size() <= 15:
		deck.clear()
		buildDeck()
		message('Reshuffle',colors.ORANGE)
		numberOfShuffles +=1

	$Timer.stop()

	$placeBet.visible = true
	$chip100.visible = true

func dealInitialCards():
	$placeBet.visible = false
	$chip100.visible = false

	dealCard(players.dealer,null)
	#dealCard(players.dealer,mockCard('A'))

	dealCard(players.player1,null)
	#dealCard(players.player1,mockCard(10))

	dealCard(players.dealer,null)
	#dealCard(players.dealer,mockCard(10))

	dealCard(players.player1,null)
	#dealCard(players.player1,mockCard('A'))
	
	if isBlackjack(player1.hands.values()[0]):
		showDealerHidden(dealer.hands.values()[0].cards[1])
		checkScore()
	
	if dealer.hands.values()[0].hasAce:
		message('Insurance?',colors.YELLOW)
		$actions/Insurance.visible=true

func dealCard(to, custom):
	# deal 1st card to player
	var cardImgPath
	var temphand

	var index = randi_range(0, deck.size()-1)
	var card = deck[index]
	if custom: card = custom
	card.imageIndex = dealtCardsImg.size()
	card.hidden=false
	
	match to:
		players.dealer:
			if dealer.hands.size() == 0:
					temphand = hand.new()
					if card.value in ['A']: temphand.hasAce = true
					dealer.hands.set('0',temphand)
			else:
				if dealer.hands.values()[0].cards.size() ==	1:
					card.hidden=true
			
			temphand = dealer.hands.values()[0]
			temphand.cards.append(card)

			getImg(players.dealer, card, temphand.cards.size())
			temphand.score = getHandScore(temphand)

			if (temphand.cards.size() >= 2):
				temphand.blackjack = isBlackjack(temphand)
				temphand.score = getHandScore(temphand)
				if temphand.score > 21: temphand.busted = true

			dealer.hands.values()[0] = temphand
			
			$scores/totalDealer.visible = true
			$scores/totalDealer.text = str(dealer.hands.values()[0].score)
			
		players.player1:
			
			match player1.hands.size():
				0:
					temphand = hand.new()
					player1.hands.set('0',temphand)
					temphand.bet = player1.bet[0]
				_:
					temphand = player1.hands.values()[0]

			temphand.cards.append(card)
			getImg(players.player1, card, temphand.cards.size())
			
			if (temphand.cards.size() >= 2):
				temphand.blackjack = isBlackjack(temphand)
				temphand.score = getHandScore(temphand)
				if temphand.score > 21: temphand.busted = true

			player1.hands.values()[0] = temphand

			$scores/totalPlayer.visible = true
			$scores/totalPlayer.text = str(player1.hands.values()[0].score)


	deck.pop_at(index)

	#stats:
	$stats/cardsRemaining.text = 'number of cards left: %s' % str(deck.size())

func nextTurn():
	#set the current playing hand to be done so that next hand can be played
	for n in player1.hands.values().size():
		if !player1.hands.values()[n].done:
			player1.hands.values()[n].done = true
			break

	if isAllPlayersHandsDone(): 
		dealersTurn()
		checkScore()
		playsound()
		$stats/Balance.text = str(player1.balance)
		player1.bet = [0]
		$stats/Bet.text = str(player1.bet[0])

		$Timer.start()

		updateStats()

func isAllPlayersHandsDone():
	var allhandsdone = true
	for temphand in player1.hands.values():
		if !temphand.done: allhandsdone = false
	return allhandsdone

func dealersTurn():
	showActions(actions.HIDE)
	
	dealer.hands.values()[0].cards[1].hidden = false
	showDealerHidden(dealer.hands.values()[0].cards[1])

	#update dealerscore
	dealer.hands.values()[0].score =  getHandScore(dealer.hands.values()[0])

	#are there any player not busted?
	var liveHands=false
	for n in player1.hands.values().size():
		if !player1.hands.values()[n].busted: liveHands=true

	# dealer hits on soft-17
	var soft17=false
	if dealer.hands.values()[0].cards.size() == 2 && dealer.hands.values()[0].score == 17 && 	dealer.hands.values()[0].hasAce:
		soft17=true

	while (
		(soft17 || dealer.hands.values()[0].score < 17) &&
		liveHands &&
		!dealer.hands.values()[0].blackjack
		):
		dealCard(players.dealer,null)
	
func checkScore():
	var dealerBlackjack = dealer.hands.values()[0].blackjack
	var dealerScore =  dealer.hands.values()[0].score
	
	for temphand in player1.hands.values():
		if temphand.blackjack && dealerBlackjack:
			message('BlackJack!',colors.ORANGE)
			player1.balance += temphand.bet * 2.5
			player1.totalWin += temphand.bet * 2.5
			stats.win += 1
		elif temphand.blackjack && dealerBlackjack:
			message('Even Money',colors.CYAN)
			player1.balance += temphand * 2
			player1.totalWin += temphand * 2
			stats.win += 1
		elif dealerBlackjack:
			message('Dealer Blackjack...',colors.RED)
			# Did any one do Insurance?
			if temphand.insurance:
				player1.balance += temphand.bet * 2
				player1.totalWin += temphand.bet * 2
			stats.loss += 1
		elif temphand.score <= 21:
			if temphand.score > dealerScore || dealerScore > 21:
				message('Won',colors.ORANGE)
				player1.balance += temphand.bet * 2
				player1.totalWin += temphand.bet * 2
				stats.win += 1
			elif temphand.score < dealerScore:
				message('Lost',colors.RED)
				stats.loss += 1
			elif temphand.score == dealerScore:
				message('Push',colors.CYAN)
				player1.balance += temphand.bet
				player1.totalWin += temphand.bet
				stats.draw += 1
		elif dealerScore <= 21:
			message('Lost',colors.RED)

func getHandScore(hand):
	var totalScore = 0
	var aceIndex = []
	#check if hand has any Ace
	var index=0
	for card in hand.cards:
		if card.value in ['A']: aceIndex.append(index)
		index +=1
		
	for card in hand.cards:
		if card.hidden == false:
			totalScore += card.score
			if totalScore > 21 && aceIndex.size() > 0:
				for n in aceIndex:
					if hand.cards[n].score == 11: 
						hand.cards[n].score = 1
						totalScore -= 10
						if totalScore < 22: break

	return totalScore

func isBlackjack(hand):
	var score=0
	if hand.cards.size() == 2:
		for n in hand.cards:
			score += n.score
		if score == 21: return true
	return false

func updateMoney():
	$stats/Balance.text = str(player1.balance)
	$stats/Bet.text = str(player1.bet[0])

func updateStats():
	#stats:
	$stats/numberOfShuffles.text = 'number of shuffles: %s' % str(numberOfShuffles)
	$stats/totalWinnning.text = 'winning: %s' % str(player1.totalWin - player1.totalBet)
	$stats/winLoss.text = 'win: %d %4s draw: %d %4s loss: %d' % [stats.win,'', stats.draw,'', stats.loss]

func playsound():
	$sound/chip.play()
	await $sound/chip.finished

func showActions(show):
	match show:
		actions.SHOW:
			$actions/Stand.visible = true
			$actions/Hit.visible = true
			$actions/Double.visible = true

		actions.DOUBLE_OFF:
			$actions/Double.visible = false

		actions.SPLIT:
			$actions/Split.visible = true

		actions.SPLIT_OFF:
			$actions/Split.visible = false
		
		actions.HIDE:
			$actions/Stand.visible = false
			$actions/Hit.visible = false
			$actions/Double.visible = false
			$actions/Split.visible = false
			$actions/Insurance.visible = false

#func showDoubleSplit(hand):
#	if hand.size() == 2:
#		if hand[0].score == hand[1].score: showActions(actions.SPLIT)
#	if hand.size() > 2:
#		showActions(actions.DOUBLE_OFF)
#		showActions(actions.SPLIT_OFF)

func _placeBet_button_pressed():

	$sound/chip.play()
	await $sound/chip.finished
	if player1.bet[0] > 0:
		$placeBet.visible = false
		player1.balance -= player1.bet[0]
		player1.totalBet += player1.bet[0]
		updateMoney()	
		dealInitialCards()
		showActions(actions.SHOW)
	else:
		message('Place a bet first',colors.ORANGE)

func _chip100_button_pressed():
	$sound/chip.play()
	await $sound/chip.finished

	player1.bet[0] += 100
	updateMoney()

func _hit_button_pressed():
	if $actions/Insurance.visible: $actions/Insurance.visible = false
	if dealer.hands.values()[0].blackjack: nextTurn(); return

	for n in player1.hands.size():
		if !player1.hands.values()[n].done:
			dealCard(players.player1,null)
			if player1.hands.values()[n].busted:
				nextTurn()

func _stand_button_pressed():
	$actions/Insurance.visible = false
	nextTurn()

func _double_button_pressed():
	if $actions/Insurance.visible: $actions/Insurance.visible = false
	if dealer.hands.values()[0].blackjack: nextTurn(); return

	for n in player1.hands.size():
		if !player1.hands.values()[n].done:
			if player1.balance >= player1.hands.values()[n].bet:
				player1.balance -= player1.hands.values()[n].bet
				player1.totalBet += player1.hands.values()[n].bet
				player1.hands.values()[n].bet = player1.hands.values()[n].bet * 2
				player1.hands.values()[n].done = true
				dealCard(players.player1,null)
			else:
				message('Don not have enough money!',colors.RED)
		
	updateMoney()
	nextTurn()

func _split_button_pressed():
	if $actions/Insurance.visible: $actions/Insurance.visible = false
	if dealer.hands.values()[0].blackjack: nextTurn(); return

	for n in player1.hands.size():
		# hands still in play and only when there are only 2 cards for split.
		if !player1.hands[n].done && player1.hands[n].cards.size() == 2:
			message("Split",colors.RED)
			$scores/totalSplit.visible = true
			$scores/totalPlayer.add_theme_color_override('font_color','RED')
			
			var temphand = hand.new()
			temphand.cards.append(player1.hands.values()[n].cards[1])
			player1.hands.values()[n].cards.pop_back()
			remove_child(dealtCardsImg[temphand.cards[0].imageIndex])
			
			getImg(players.split,temphand.cards[0],1)
			
			temphand.bet = player1.hands[n].bet
			player1.balance -= temphand.bet
			player1.totalBet += temphand.bet
			
			player1.hands.append(temphand)
			player1.hands[n].done = true
			dealCard(players.player1,null)

			nextTurn()

func _insurance_button_pressed():
	message("Buy Insurance", colors.ORANGE)
	$actions/Insurance.visible=false
	#only if balance has enough to cover insurance
	if player1.balance >= player1.hands.values()[0].bet:
		player1.balance -= player1.hands.values()[0].bet / 2
		player1.totalBet += player1.hands.values()[0].bet / 2
		player1.hands.values()[0].insurance = true
		updateMoney()
	if dealer.hands.values()[0].blackjack:
		nextTurn()

func getImgPath(tempCard):
	return 'img/cards/' + str(tempCard.suit) + str(tempCard.value) + '.svg'

func getImg(to, tempCard, count): # card width, height is 3/2 ratio
	var path
	var newCard = TextureRect.new()
	var image = Image.new()
	
	#count +=1 # hand length is ordinal number so add 1 to get the actual index.
	if tempCard.hidden:
		path = 'img/cards/Card_back.svg'
	else:
		path = getImgPath(tempCard)
	
	image.load(path)
	image.resize(cardSize,cardSize*1.5)
	
	var texture = ImageTexture.create_from_image(image)
	newCard.texture = texture
	
	match to:
		players.dealer: 
			newCard.position.y = 75
			newCard.position.x = (get_viewport().size.x + (count * cardSize)) / 2 - 100 #newCard.position.x = viewCenterX - size/2
		players.split:
			newCard.position.y = 300
			newCard.position.x = (get_viewport().size.x + (count * cardSize)) / 2 - 500 #newCard.position.x = viewCenterX - size/2
		_:
			newCard.position.y = 300
			newCard.position.x = (get_viewport().size.x + (count * cardSize)) / 2 - 100
	
	dealtCardsImg.append(newCard)
	add_child(newCard)
	
func showDealerHidden(tempCard):
	var path = getImgPath(tempCard)
	var image = Image.new()
	image.load(path)
	image.resize(cardSize,cardSize*1.5)

	var texture = ImageTexture.create_from_image(image)
	
	remove_child(dealtCardsImg[tempCard.imageIndex])
	dealtCardsImg[tempCard.imageIndex].texture = texture
	add_child(dealtCardsImg[tempCard.imageIndex])
	
	$scores/totalDealer.text = str(getHandScore(dealer.hands.values()[0]))

func loadBackground():
	var background = TextureRect.new()
	var image = Image.new()
	image.load('res://img/empty_table.jpg')
	var texture = ImageTexture.create_from_image(image)
	background.texture = texture
	add_child(background)
	pass

func saveGameStats():
	var save_values={
		'balance':player1.balance,
		'win':stats.win,
		'draw':stats.draw,
		'loss':stats.loss
	}
	var file=FileAccess.open('user://savedStats.dat',FileAccess.WRITE)
	file.store_var(save_values)
	#file.store_line('Hey')
	file.close()

func loadGameStats():
	if loadedStats == false:
		loadedStats= true # only attemp to load when game starts for first time
		if !FileAccess.file_exists('user://savedStats.dat'):
			print('No saved to load!')
			return
		var file = FileAccess.open('user://savedStats.dat',FileAccess.READ)
		var content = file.get_var()

		player1.balance = int(content['balance'])
		stats.win = int(content['win'])
		stats.draw = int(content['draw'])
		stats.loss = int(content['loss'])
		updateStats()

class card:
	var suit
	var value
	var score
	var hidden
	var image
	var imageIndex

class hand:
	var bet=0
	var cards=[]
	var score=0
	var blackjack=false
	var insurance=false
	var split=false
	var hasAce=false
	var aceIndex=[]
	var busted=false
	var done=false

class player:
	var balance=1000
	var bet=[0]
	var hands={}
	var totalBet=0
	var totalWin=0
