extends Node

var numberOfDecks = 2
var deck = []
var dealer = player.new()
var player1 = player.new()
var dealerPlay = false
var dealtCards = []
var viewCenterX
var viewCenterY
var cardSize = 125

func _ready():
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

	dealerPlay=false

	dealer.hands=[]
	dealer.score=0
	dealer.hasAce=false
	dealer.blackjack=false
	dealer.busted=false
	dealer.hasAce=false

	
	player1.hands=[]
	player1.score=0
	player1.bet = 0
	player1.busted =false
	player1.blackjack=false
	player1.hasAce=false
	player1.insurance=false


	$totalDealer.visible = false
	$totalPlayer.visible = false
	$placeBet.visible = true
	
	for card in dealtCards:
			remove_child(card)
	
	dealtCards=[]
	
	$Timer.stop()

func dealInitialCards():
	dealCard('dealer',null)
	#dealCard('dealer',{'suit':'C','value':'A','score':11,'hidden':false})
	dealCard('player1',null) #{'suit':'C','value':'A','score':11})
	dealCard('dealer',null)
	#dealCard('dealer',{'suit':'C','value':10,'score':10,'hidden':false})
	dealCard('player1',null) #{'suit':'C','value':10,'score':10})
		
	if player1.score == 21:
		player1.blackjack = true
		checkScore()
	
	if dealer.hasAce:
		print('Insurance?')
		$actions/Insurance.visible=true
		
	elif dealer.blackjack:
		dealer.hands[1].hidden=false
		dealer.score = 21
		showDealerHidden(dealer.hands[1])
		checkScore()

func buildDeck():
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

func dealCard(to, custom):
	# deal 1st card to player
	var cardImgPath
	var index = randi_range(0, deck.size()-1)
	var card = deck[index]
	if custom: card = custom
	match to:
		'dealer':
			if !dealerPlay && dealer.hands.size() == 1:
				card.hidden = true
				if (dealer.score + card.score == 21):
					dealer.blackjack = true
			else:
				dealer.score += card.score
			
			getImg('dealer', card, dealer.hands.size())
			dealer.hands.append(card)

			if(dealer.hands[0].value in ['A']):
				dealer.hasAce=true
			
		'player1':
			if card.score == 11: player1.hasAce = true

			getImg('player', card, player1.hands.size())

			player1.hands.append(card)
			player1.score += card.score

	deck.pop_at(index)
	
	$totalPlayer.text = str(player1.score)
	$totalDealer.text = str(dealer.score)
	$totalDealer.visible = true
	$totalPlayer.visible = true

func updateMoney():
	$Balance.text = str(player1.balance)
	$Bet.text = str(player1.bet)

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
	print('Dealer\'s turn')
	dealer.hands[1].hidden = false
	dealer.score += dealer.hands[1].score
	showDealerHidden(dealer.hands[1])
	
	while (dealer.score < 17) && !player1.busted:
		dealCard('dealer',null)
	if dealer.score > 21: dealer.busted =true
	checkScore()

func checkScore():
	if player1.blackjack && !dealer.blackjack:
		print('Blackjack!')
		player1.balance += player1.bet + player1.bet * 1.5
	elif player1.blackjack && dealer.blackjack:
		print('Even money')
		player1.balance += player1.bet * 2
	elif dealer.blackjack:
		print('Dealer Blackjack...')
		# Did any one do Insurance?
	elif !player1.busted:
		if dealer.busted || player1.score > dealer.score: 
			print('Player WON')
			player1.balance += player1.bet * 2
		elif dealer.score > player1.score:
			print('Player LOST')
		elif dealer.score == player1.score:
			print('DRAW')
			player1.balance += player1.bet

	playsound()
	player1.bet = 0
	$Balance.text = str(player1.balance)
	$Bet.text = str(player1.bet)
	
	$Timer.start()

func _placeBet_button_pressed():
	$sound/chip.play()
	await $sound/chip.finished
	dealInitialCards()
	showButtons(true)
	$placeBet.visible = false

func _chip100_button_pressed():
	player1.bet += 100
	player1.balance -= 100
	updateMoney()
	$sound/chip.play()
	await $sound/chip.finished

func _stand_button_pressed():
	print("Stand")
	showDealerHidden(dealer.hands[1])
	dealerPlay = true
	showButtons(false)
	dealersTurn()

func _hit_button_pressed():
	print("Hit")
	dealCard('player1',null)
	if (player1.score > 21):
		player1.busted = true
		showButtons(false)
		dealersTurn()

func _double_button_pressed():
	if player1.balance >= player1.bet:
		print("Double")
		dealerPlay = true
		player1.balance -= player1.bet
		player1.bet *= 2
		updateMoney()
		dealCard('player1',null)
		showButtons(false)
		dealersTurn()
	else:
		print('Not enough balace left!')

func _split_button_pressed():
	print("Split")

func _insurance_button_pressed():
	print("Insurance")
	$actions/Insurance.visible=false
	player1.balance -= player1.bet / 2
	updateMoney()
	if dealer.blackjack:
		player1.balance += player1.bet * 2

class card:
	var suit
	var value
	var score
	var hidden
	var image

class player:
	var balance=1000
	var bet=0
	var hands=[]
	var cards=[]
	var blackjack=false
	var hasAce=false
	var busted=false
	var score=0
	var insurance=false

func getImgPath(card):
	return 'img/cards/' + str(card.suit) + str(card.value) + '.svg'
	
func getImg(to, card, count): # card width, height is 3/2 ratio
	var path
	var newCard = TextureRect.new()
	var image = Image.new()
	
	#count +=1 # hand length is ordinal number so add 1 to get the actual index.
	if card.hidden:
		path = 'img/cards/Card_back.svg'
	else:
		path = getImgPath(card)
	
	image.load(path)
	image.resize(cardSize,cardSize*1.5)
	
	var texture = ImageTexture.create_from_image(image)
	newCard.texture = texture
	
	match to:
		'dealer': 
			newCard.position.y = 75
			newCard.position.x = (get_viewport().size.x + (count * cardSize)) / 2 - 100	#newCard.position.x = viewCenterX - size/2
		_:
			newCard.position.y = 300
			newCard.position.x = (get_viewport().size.x + (count * cardSize)) / 2 - 100
	
	dealtCards.append(newCard)
	add_child(newCard)
	
	card.image = newCard

func showDealerHidden(card):
	var path = getImgPath(card)
	var image = Image.new()
	image.load(path)
	image.resize(cardSize,cardSize*1.5)

	var texture = ImageTexture.create_from_image(image)
		
	card.image.texture = texture
