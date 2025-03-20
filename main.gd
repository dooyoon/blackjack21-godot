extends Node

var numberOfDecks = 1
var deck = []
var dealer = player.new()
var player1 = player.new()
var dealtCardsImg = []
var viewCenterX
var viewCenterY
var cardSize = 125
var newDeal = false
enum players {dealer, player1, split}
var isActive = players.player1

func message(msg, color):
	$Warning.visible = true
	$Warning.text = msg
	$Warning.add_theme_font_size_override("font_size", 36)
	$Warning.add_theme_color_override('font_color', color)
	
	await get_tree().create_timer(3).timeout
	$Warning.visible = false
	
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

func _ready():
	showButtons(false)
	viewCenterX = get_viewport().size.x / 2
	viewCenterY = get_viewport().size.y / 2
	
	buildDeck()
	$Balance.text = str(player1.balance)
	$Bet.text = str(player1.bet)

	$actions/Stand.pressed.connect(_stand_button_pressed)
	$actions/Hit.pressed.connect(_hit_button_pressed)
	$actions/Double.pressed.connect(_double_button_pressed)
	$actions/Split.pressed.connect(_split_button_pressed)
	$actions/Insurance.pressed.connect(_insurance_button_pressed)
	$placeBet.pressed.connect(_placeBet_button_pressed)
	$chip100.pressed.connect(_chip100_button_pressed)
	
	$Timer.timeout.connect(resetTable)

func resetTable():
	showButtons(false)
	isActive = players.player1

	dealer.hands.clear()
	dealer.hasAce=false
	dealer.blackjack=false
	dealer.busted=false
	dealer.hasAce=false

	
	player1.hands.clear()
	player1.bet = 0
	player1.busted =false
	player1.blackjack=false
	player1.hasAce=false
	player1.insurance=false


	$totalDealer.visible = false
	$totalPlayer.visible = false
	$placeBet.visible = true
	
	for card in dealtCardsImg:
		remove_child(card)
	
	dealtCardsImg.clear()

	if deck.size() < 15:
		deck.clear()
		buildDeck()
		print('Reshuffle')

	$Timer.stop()
	
	newDeal=false
	$placeBet.visible = true
	$chip100.visible = true

func mockCard(value):
	var card = card.new()
	var score = value
	if value in ['J','Q','K']: score=10
	if value in ['A']: score=11

	card.suit = 'Club'
	card.value = value
	card.score = score
	return card

func getHandScore(hand):
	var totalScore = 0
	var aceCount = 0
	#check if hand has any Ace
	for card in hand:
		if card.value in ['A']: aceCount += 1
		
	for card in hand:
		if card.hidden == false:
			totalScore += card.score
			if totalScore > 21 && aceCount > 0:
				for n in hand.size():
					if str(hand[n].value) == 'A' && hand[n].score == 11: 
						hand[n].score = 1
						totalScore -= 10
						if totalScore < 22: break

	return totalScore

func dealInitialCards():
	$placeBet.visible = false
	$chip100.visible = false
	
	dealCard(players.dealer,null)
	dealCard(players.player1,null)
	#dealCard(players.player1,mockCard(7))
	dealCard(players.dealer,null)
	dealCard(players.player1,null)
	#dealCard(players.player1,mockCard(7))
		
	if getHandScore(player1.hands) == 21:
		player1.blackjack = true
		showDealerHidden(dealer.hands[1])
		checkScore()
	
	if dealer.hasAce:
		print('Insurance?')
		$actions/Insurance.visible=true
		
	elif dealer.blackjack:
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
				if (getHandScore(dealer.hands) + card.score == 21):
					dealer.blackjack = true
			
			getImg(players.dealer, card, dealer.hands.size())
			dealer.hands.append(card)

			for n in dealer.hands:
				if(n.value in ['A']):
					dealer.hasAce=true

		players.player1:

			getImg(players.player1, card, player1.hands.size())
				
			player1.hands.append(card)

	deck.pop_at(index)

	$totalDealer.visible = true
	$totalPlayer.visible = true
	updateTotal()
	
	#print('Number of cards left: %s' % deck.size())

func updateMoney():
	$Balance.text = str(player1.balance)
	$Bet.text = str(player1.bet)

func updateTotal():
	$totalPlayer.text = str(getHandScore(player1.hands))
	$totalDealer.text = str(getHandScore(dealer.hands))
	
func playsound():
	$sound/chip.play()
	await $sound/chip.finished

func showButtons(show):
	if show:
		$actions/Stand.visible = true
		$actions/Hit.visible = true
		$actions/Double.visible = true
		$actions/Split.visible = true
		
	else:
		$actions/Stand.visible = false
		$actions/Hit.visible = false
		$actions/Double.visible = false
		$actions/Split.visible = false
		$actions/Insurance.visible = false

func dealersTurn():
	showButtons(false)
	isActive = players.dealer
	checkScore()
	
	dealer.hands[1].hidden = false
	showDealerHidden(dealer.hands[1])
	
	# dealer hits on soft-17
	if getHandScore(dealer.hands) == 17 && dealer.hasAce && dealer.hands.size() == 2:
		dealCard(players.dealer,null)

	#var count=0
	while (!dealer.busted && !player1.busted) && getHandScore(dealer.hands) < 17:
		dealCard(players.dealer,null)
		#if dealer.hands.size() == 2: dealCard('dealer',{'suit':'Club','value':'A','score':11,'hidden':false})
		#else: dealCard('dealer',null)

		if getHandScore(dealer.hands) > 21:
			dealer.busted =true

		#count += 1
		#print('Dealer loop: %s' % count)

	print("outside while")
	checkScore()

func checkScore():
	var player1Score = getHandScore(player1.hands)
	var dealerScore = getHandScore(dealer.hands)
	
	if player1.blackjack && !dealer.blackjack:
		message('BlackJack!','ORANGE')
		player1.balance += player1.bet + player1.bet * 1.5
		newDeal = true
	elif player1.blackjack && dealer.blackjack:
		message('Even Money','CYAN')
		player1.balance += player1.bet * 2
		newDeal = true
	elif dealer.blackjack:
		print('Dealer Blackjack...')
		# Did any one do Insurance?
		newDeal = true
	elif !player1.busted:
		if dealer.busted || player1Score > dealerScore: 
			message('Won','ORANGE')
			player1.balance += player1.bet * 2
		elif dealerScore > player1Score:
			message('Lost','RED')
		elif dealerScore == player1Score:
			message('Push','CYAN')
			player1.balance += player1.bet
		newDeal = true
	elif player1.busted && !dealer.busted:
		newDeal = true
	
	playsound()
	player1.bet = 0
	$Balance.text = str(player1.balance)
	$Bet.text = str(player1.bet)
	
	if newDeal: 	$Timer.start()

func _placeBet_button_pressed():
	$sound/chip.play()
	await $sound/chip.finished
	if player1.bet > 0:
		dealInitialCards()
		showButtons(true)
		$placeBet.visible = false
	else:
		print('Place a bet first')

func _chip100_button_pressed():
	$sound/chip.play()
	await $sound/chip.finished
	if newDeal == true: return

	player1.bet += 100
	player1.balance -= 100
	updateMoney()

func _stand_button_pressed():
	$actions/Insurance.visible = false
	#print("Stand")
	isActive = players.dealer
	dealersTurn()

func _hit_button_pressed():
	if $actions/Insurance.visible == true:
		$actions/Insurance.visible = false
	if dealer.blackjack: dealersTurn(); return

	#print("Hit")
	dealCard(players.player1,null)
	
	if getHandScore(player1.hands) > 21:
		player1.busted = true
		dealersTurn()

	if getHandScore(player1.hands) == 21:
		dealersTurn()

func _double_button_pressed():
	if $actions/Insurance.visible == true:
		$actions/Insurance.visible = false
	if dealer.blackjack: dealersTurn(); return

	if player1.balance >= player1.bet:
		#print("Double")
		player1.balance -= player1.bet
		player1.bet *= 2
		updateMoney()
		dealCard(players.player1,null)
		dealersTurn()
	else:
		print('Not enough balace left!')

func _split_button_pressed():
	if $actions/Insurance.visible == true:
		$actions/Insurance.visible = false
	if dealer.blackjack: dealersTurn(); return

	message("Split",'RED')
	player1.split.append(player1.hands[1])
	player1.hands.pop_back()
	updateTotal()
	remove_child(dealtCardsImg[3])
	getImg('split',player1.split[0],player1.split.size())

func _insurance_button_pressed():
	#print("Insurance")
	$actions/Insurance.visible=false
	player1.balance -= player1.bet / 2
	updateMoney()
	if dealer.blackjack:
		player1.balance += player1.bet * 2

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
		'split':
			newCard.position.y = 300
			newCard.position.x = (get_viewport().size.x + (count * cardSize)) / 2 - 400	#newCard.position.x = viewCenterX - size/2
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
	var bet=0
	var hands=[]
	var split=[]
	var blackjack=false
	var hasAce=false
	var busted=false
	var insurance=false
