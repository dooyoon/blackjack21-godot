extends Node
var numberOfDecks = 2
var deck = []
var dealer = player.new()
var player1 = player.new()
var dealerPlay = false

func _ready():
	print("Hello")
	$dealerCards.add_theme_font_size_override("font_size", 36)
	$dealerCards.global_position.x = get_viewport().size.x / 2 - $dealerCards.text.length() * 10
	
	$playerCards.add_theme_font_size_override("font_size", 36)
	$playerCards.global_position.x = get_viewport().size.x / 2 - $playerCards.text.length() *10
	
	buildDeck()
	dealInitialCards()
	showCards('player1')
	showCards('dealer')
	showButtons(true)

	$Stand.pressed.connect(_stand_button_pressed)
	$Hit.pressed.connect(_hit_button_pressed)
	$Double.pressed.connect(_double_button_pressed)
	$Split.pressed.connect(_split_button_pressed)
	$Insurance.pressed.connect(_insurance_button_pressed)
	
func dealInitialCards():
	dealCard('dealer')
	dealCard('player1')
	dealCard('dealer')
	dealCard('player1')

func _process(delta: float) -> void:
	if $Stand.is_processing_input():
	#if Input.is_action_just_pressed("myButtons"):
		print('Stand button pressed')
		
func playersTurn():
	var till21 = true
	showButtons(true)
	showCards('player1')
	pass
	
func dealersTurn():
	dealer.hands[1].hidden = false
	showCards('dealer')
	pass
	
func buildDeck():
	#var suits = ['Spades', 'Hearts', 'Clubs', 'Diamonds']
	var suits = ['S', 'H', 'C', 'D']
	var values = [2,3,4,5,6,7,8,9,10,'J','Q','K','A']

	for n in numberOfDecks:
		for suit in suits:
			for value in values:
				var card = card.new()
				card.suit = suit
				card.value = value
				deck.push_back(card)
	
func dealCard(to):
	# deal 1st card to player
	var index = randi_range(0, deck.size()-1)
	var card = deck[index]
	print(card)
	match to:
		'dealer':
			if !dealerPlay && dealer.hands.size() == 1:
				card.hidden = true
			dealer.hands.append(card)
		'player1':
			player1.hands.append(card)
	deck.pop_at(index)

func showCards(to):
	match to:
		'dealer':
			$dealerCards.text = ''
			for card in dealer.hands:
				if card.hidden:
					$dealerCards.text += 'XX '
				else:
					$dealerCards.text += card.suit + '-' + str(card.value) + ' '
				
		'player1':
			$playerCards.text = ''
			for card in player1.hands:
				$playerCards.text += card.suit + '-' + str(card.value) + ' '

func bet():
	pass

func showButtons(show):
	if show:
		$Stand.visible = true
		$Hit.visible = true
		$Double.visible = true
		$Split.visible = true
	else:
		$Stand.visible = false
		$Hit.visible = false
		$Double.visible = false
		$Split.visible = false
		
func _stand_button_pressed():
	dealerPlay = true
	print("Stand")

func _hit_button_pressed():
	print("Hit")
	pass

func _double_button_pressed():
	dealerPlay = true
	print("Double")

func _split_button_pressed():
	print("Split")
	pass

func _insurance_button_pressed():
	print("Insurance")
	pass

class card:
	var suit
	var value
	var hidden
	
class player:
	var balance
	var bet
	var hands=[]
	var blackjack=false
	var hasAce=false
	var busted=false
