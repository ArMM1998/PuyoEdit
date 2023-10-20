extends HTTPRequest

func _ready():
	var url = "https://github.com/ArMM1998/PuyoEdit/releases/latest"
	request(url)


func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:  # Success
		body = str(body.get_string_from_ascii())
		
		var version = (body.substr(body.find("/ArMM1998/PuyoEdit/releases/tag/"), 256).split("\"")[0].split("tag/")[1])
		
		var out_of_date = checkVersion(version)
		if out_of_date:
			owner.popupUpdate(version)
		
	else:
		print("Request failed with response code: ", response_code)


func checkVersion(version):
	var current_version = []
	for digit in owner.current_version.split("."):
		current_version.append(int(digit))
		
	if current_version.size() == 2:
		current_version.append(0)
	var online_version = []
	for digit in version.split("."):
		online_version.append(int(digit))
	if online_version.size() == 2:
		online_version.append(0)
	
	#check first digit
	if current_version[0] < online_version[0]: #online version is newer
		return(true)
	elif current_version[0] > online_version[0]: #online version is older
		return(false)
	else:	#first digit matches, so move on to the next
		if current_version[1] < online_version[1]: #online version is newer
			return(true)
		elif current_version[1] > online_version[1]: #online version is older
			return(false)
		else: #second digit also matches. check if there is a third
			if current_version[2] < online_version[2]: #online version is newer
				return(true)
			elif current_version[2] > online_version[2]: #online version is older
				return(false)
			else: #second digit also matches. check if there is a third
				return(false)
