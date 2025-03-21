extends Node

var numberOfDecks = 2
var deck = []
var dealer = player.new()
var player1 = player.new()
var dealtCardsImg = []
var viewCenterX
var viewCenterY
var cardSize = 125
var isActive = players.player1
var numberOfShuffles = 0
var stats = {'win':0, 'draw': 0, 'loss':0}

enum players {dealer, player1, split, none}
enum colors {RED, BLUE, CYAN, ORANGE, GRAY, YELLOW}
enum actions {SHOW, HIDE, DOUBLE, SPLIT, DOUBLE_OFF, SPLIT_OFF}

func message(msg, colorIndex):
	$Warning.visible = true
	$Warning.text = msg

	$Warning.add_theme_font_size_override("font_size", 36)
	$Warning.add_theme_color_override('font_color',colors.keys()[colorIndex])
	
	await get_tree().create_timer(3).timeout
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
	showButtons(actions.HIDE)
	viewCenterX = get_viewport().size.x / 2
	viewCenterY = get_viewport().size.y / 2
	
	buildDeck()
	$Balance.text = str(player1.balance)
	$Bet.text = str(player1.bet[0])

	$actions/Stand.pressed.connect(_stand_button_pressed)
	$actions/Hit.pressed.connect(_hit_button_pressed)
	$actions/Double.pressed.connect(_double_button_pressed)
	$actions/Split.pressed.connect(_split_button_pressed)
	$actions/Insurance.pressed.connect(_insurance_button_pressed)
	$placeBet.pressed.connect(_placeBet_button_pressed)
	$chip100.pressed.connect(_chip100_button_pressed)
	
	$Timer.timeout.connect(resetTable)

func resetTable():
	showButtons(actions.HIDE)
	isActive = players.player1

	dealer.hands.clear()
	dealer.hasAce=false
	dealer.hasAce=false

	player1.hands.clear()
	player1.split.clear()
	player1.bet = [0]
	player1.hasAce=false
	player1.insurance=false
	#player1.totalBet=0
	#player1.totalWin=0

	$totalDealer.visible = false
	$totalPlayer.visible = false
	$totalSplit.visible = false
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

	if isBlackjack(player1.hands):
		showDealerHidden(dealer.hands[1])
		checkScore()
	
	if dealer.hasAce:
		message('Insurance?',colors.YELLOW)
		$actions/Insurance.visible=true
		
	elif dealer.hands[1].score + dealer.hands[0].score == 21:
		dealer.hands[1].hidden=false
		showDealerHidden(dealer.hands[1])
		checkScore()

func dealCard(to, custom):
	# deal 1st card to player
	var cardImgPath
	var index = randi_range(0, deck.size()-1)
	var card = deck[index]
	if custom: card = custom
	card.imageIndex = dealtCardsImg.size()
	card.hidden=false
	
	match to:
		players.dealer:
			if isActive != players.dealer && dealer.hands.size() == 1:
				card.hidden = true

			getImg(players.dealer, card, dealer.hands.size())
			dealer.hands.append(card)

			if dealer.hands[0].value in ['A']: 
				dealer.hasAce = true

		players.player1:
			getImg(players.player1, card, player1.hands.size())
			player1.hands.append(card)
			if player1.hands.size() > 2: showButtons(actions.DOUBLE_OFF)

		players.split:
			player1.split.append(card)
			getImg(players.split, card, player1.split.size())
			if player1.hands.size() > 2: showButtons(actions.DOUBLE_OFF)

	deck.pop_at(index)

	$totalDealer.visible = true
	$totalPlayer.visible = true
	updateTotal()
	
func getHandScore(hand):
	var totalScore = 0
	var aceIndex = []
	#check if hand has any Ace
	var index=0
	for card in hand:
		if card.value in ['A']: aceIndex.append(index)
		index +=1
		
	for card in hand:
		if card.hidden == false:
			totalScore += card.score
			if totalScore > 21 && aceIndex.size() > 0:
				for n in aceIndex:
					if hand[n].score == 11: 
						hand[n].score = 1
						totalScore -= 10
						if totalScore < 22: break

	return totalScore

func isBlackjack(hand):
	var score=0
	if hand.size() == 2:
		for n in hand:
			score += n.score
		if score == 21: return true		
	return false

func updateMoney():
	$Balance.text = str(player1.balance)
	$Bet.text = str(player1.bet[0])

func updateTotal():
	$totalPlayer.text = str(getHandScore(player1.hands))
	$totalDealer.text = str(getHandScore(dealer.hands))
	if (player1.split.size() > 0): 
		$totalSplit.text = str(getHandScore(player1.split))
		
	#stats:
	$stats/cardsRemaining.text = 'number of cards left: %s' % str(deck.size())
	
func playsound():
	$sound/chip.play()
	await $sound/chip.finished

func showButtons(show):
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

func dealersTurn():
	showButtons(actions.HIDE)
	isActive = players.dealer
	
	dealer.hands[1].hidden = false
	showDealerHidden(dealer.hands[1])
	
	if getHandScore(player1.hands) > 21:
		checkScore() # if player busted, checkScore and start new hand
	
	# dealer hits on soft-17
	if getHandScore(dealer.hands) == 17 && dealer.hasAce && dealer.hands.size() == 2:
		dealCard(players.dealer,null)

	#var count=0
	while (getHandScore(dealer.hands) < 17 && getHandScore(player1.hands) <= 21):
		dealCard(players.dealer,null)

	checkScore()

func checkScore():
	var playerScore
	var playerBlackjack
	var dealerScore = getHandScore(dealer.hands)
	var dealerBlackjack = isBlackjack(dealer.hands)

	for n in player1.bet.size():
		match n:
			0: 
				playerScore = getHandScore(player1.hands)
				playerBlackjack = isBlackjack(player1.hands)
			1: 
				playerScore = getHandScore(player1.split)
				playerBlackjack = isBlackjack(player1.split)

		if playerBlackjack && !dealerBlackjack:
			message('BlackJack!',colors.ORANGE)
			player1.balance += player1.bet[n] + player1.bet[n] * 1.5
			player1.totalWin += player1.bet[n] + player1.bet[n] * 1.5
			stats.win += 1
			isActive = players.none
		elif playerBlackjack && dealerBlackjack:
			message('Even Money',colors.CYAN)
			player1.balance += player1.bet[n] * 2
			player1.totalWin += player1.bet[n] * 2
			stats.win += 1
			isActive = players.none
		elif dealerBlackjack:
			message('Dealer Blackjack...',colors.RED)
			# Did any one do Insurance?
			if player1.insurance:
				player1.balance += player1.bet[0] * 1.5
				player1.totalWin += player1.bet[0] * 1.5
			stats.loss += 1
			isActive = players.none
		elif !playerScore > 21:
			if dealerScore > 21 || playerScore > dealerScore: 
				message('Won',colors.ORANGE)
				player1.balance += player1.bet[n] * 2
				player1.totalWin += player1.bet[n] * 2
				stats.win += 1
				isActive = players.none
			elif dealerScore > playerScore:
				message('Lost',colors.RED)
				stats.loss += 1
				isActive = players.none
			elif dealerScore == playerScore:
				message('Push',colors.CYAN)
				player1.balance += player1.bet[n]
				player1.totalWin += player1.bet[n]
				stats.draw += 1
				isActive = players.none
			
		elif playerScore > 21 && dealerScore <=21:
			message('Lost',colors.RED)
			isActive = players.none
	
	if isActive == players.none:
		playsound()
		$Balance.text = str(player1.balance)
		player1.bet = [0]
		$Bet.text = str(player1.bet[0])

		$Timer.start()

		#stats:
		$stats/numberOfShuffles.text = 'number of shuffles: %s' % str(numberOfShuffles)
		$stats/totalWinnning.text = 'winning: %s' % str(player1.totalWin - player1.totalBet)
		#$stats/winLoss.text = 'win: '+ str(stats.win) + '\tdraw: ' + str(stats.draw) + '\tloss: ' + str(stats.loss)
		$stats/winLoss.text = 'win: %d %4s draw: %d %4s loss: %d' % [stats.win,'', stats.draw,'', stats.loss]
		

func _placeBet_button_pressed():

	$sound/chip.play()
	await $sound/chip.finished
	if player1.bet[0] > 0:
		$placeBet.visible = false
		player1.balance -= player1.bet[0]
		player1.totalBet += player1.bet[0]
		updateMoney()	
		dealInitialCards()
		showButtons(actions.SHOW)
	else:
		message('Place a bet first',colors.ORANGE)

func _chip100_button_pressed():
	$sound/chip.play()
	await $sound/chip.finished
	if isActive == players.dealer: return

	player1.bet[0] += 100
	updateMoney()

func nextTurn():
	if player1.split.size() > 0 && isActive != players.split:
		isActive = players.split
		$totalPlayer.add_theme_color_override('font_color','WHITE')
		$totalSplit.add_theme_color_override('font_color','RED')
		updateTotal()
	elif isActive == players.split:
		isActive = players.dealer
		$totalSplit.add_theme_color_override('font_color','WHITE')
	else:
		isActive = players.dealer

	if isActive == players.dealer:	dealersTurn()

func _stand_button_pressed():
	$actions/Insurance.visible = false
	nextTurn()

func _hit_button_pressed():
	if $actions/Insurance.visible == true:
		$actions/Insurance.visible = false
	if isBlackjack(dealer.hands): dealersTurn(); return

	match isActive:
		players.split:
			dealCard(players.split,null)
			if getHandScore(player1.split) >= 21:
				nextTurn()
		_:
			dealCard(players.player1,null)
			if getHandScore(player1.hands) >= 21:
				nextTurn()

func _double_button_pressed():
	if $actions/Insurance.visible == true:
		$actions/Insurance.visible = false
	if isBlackjack(dealer.hands): dealersTurn(); return
		
	if isActive == players.player1:
		if player1.balance >= player1.bet[0]:
			player1.balance -= player1.bet[0]
			player1.totalBet += player1.bet[0]
			player1.bet[0] = player1.bet[0] * 2
		else:
			message('Need more money!',colors.RED)
	elif isActive == players.split && player1.bet.size() > 1:
		if player1.balance >= player1.bet[1]:
			player1.balance -= player1.bet[1]
			player1.totalBet += player1.bet[1]
			player1.bet[1] = player1.bet[1] * 2
		else:
			message('Need more money!',colors.RED)
		
	updateMoney()
	dealCard(isActive,null)
	nextTurn()

func _split_button_pressed():
	if $actions/Insurance.visible == true:
		$actions/Insurance.visible = false
	if isBlackjack(dealer.hands): dealersTurn(); return

	#if player1.hands.size() == 1: return
	message("Split",colors.RED)
	player1.split.append(player1.hands[1])
	player1.hands.pop_back()
	$totalSplit.visible = true
	$totalPlayer.add_theme_color_override('font_color','RED')
	remove_child(dealtCardsImg[player1.split[0].imageIndex])
	
	getImg(players.split,player1.split[0],player1.split.size())
	dealCard(players.player1,null)
	
	player1.bet.append(player1.bet[0])
	player1.balance -= player1.bet[0]
	player1.totalBet += player1.bet[0]
	updateTotal()

func _insurance_button_pressed():
	message("Got Insurance", colors.ORANGE)
	$actions/Insurance.visible=false
	player1.balance -= player1.bet[0] / 2
	player1.totalBet += player1.bet[0] / 2
	updateMoney()
	if isBlackjack(dealer.hands):
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
			newCard.position.x = (get_viewport().size.x + (count * cardSize)) / 2 - 100	#newCard.position.x = viewCenterX - size/2
		players.split:
			newCard.position.y = 300
			newCard.position.x = (get_viewport().size.x + (count * cardSize)) / 2 - 500	#newCard.position.x = viewCenterX - size/2
		_:
			newCard.position.y = 300
			newCard.position.x = (get_viewport().size.x + (count * cardSize)) / 2 - 100
	
	dealtCardsImg.append(newCard)
	add_child(newCard)
	
	tempCard.image = newCard

func showDealerHidden(tempCard):
	var path = getImgPath(tempCard)
	var image = Image.new()
	image.load(path)
	image.resize(cardSize,cardSize*1.5)

	var texture = ImageTexture.create_from_image(image)
	tempCard.image.texture = texture
	
	$totalDealer.text = str(getHandScore(dealer.hands))

func loadBackground():
	var background = TextureRect.new()
	var image = Image.new()
	image.load('res://img/empty_table.jpg')
	var texture = ImageTexture.create_from_image(image)
	background.texture = texture
	add_child(background)
	pass

class card:
	var suit
	var value
	var score
	var hidden
	var image
	var imageIndex

class player:
	var balance=1000
	var bet=[0]
	var hands=[]
	var split=[]
	var hasAce=false
	var insurance=false
	var totalBet=0
	var totalWin=0
