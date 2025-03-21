extends Node

func ready():
	$HTTPRequest.request_completed.connect(_on_request_completed)
	var headers = ["Content-Type: application/json"]
	$HTTPRequest.request("https://datausa.io/api/data?drilldowns=Nation&measures=Population", headers, HTTPClient.METHOD_GET)

	# sending data to server
	#var json = JSON.stringify(data_to_send)
	#$HTTPRequest.request(url, headers, HTTPClient.METHOD_POST, json)
	
	#Setting custome HTTP headers
	#$HTTPRequest.request("https://api.github.com/repos/godotengine/godot/releases/latest", ["User-Agent: YourCustomUserAgent"])

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	print(json["data"])
