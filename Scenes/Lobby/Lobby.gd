extends Control
class_name Lobby

@onready var nUserBox: UserBox = %UserBox
@onready var nJoinTableList: TableList = %JoinTableList
@onready var nWatchBoxes: WatchBoxes = %WatchBoxes
@onready var nGetAccountTimer: Timer = %GetAccountTimer

func _ready() -> void:
	print("Meowwww")
	
	if !Platform.is_web():
		%Banners.hide()
	
	var server_address = Arg.get_arg("--server-address", Config.SERVER_ADDRESS)
	var server_port = Arg.get_arg("--server-port", Config.SERVER_PORT)
	
	APokerClient.connected.connect(_on_connected)
	APokerClient.server_info.connect(_on_server_info)
	APokerClient.login_res.connect(_on_login_res)
	APokerClient.signup_res.connect(_on_signup_res)
	APokerClient.tables.connect(_on_tables)
	APokerClient.sessions.connect(_on_sessions)
	APokerClient.account.connect(_on_account)
	
	APokerClient.connect_to_server(server_address, int(server_port))
	
	if OS.get_name() == "Web":
		%WinTitle.nCloseButton.hide()
		%Banners.custom_minimum_size.y = 220
	
	await get_tree().create_timer(0.75).timeout
	
	ADialogs.open_single(ALoginDialog)

func _process(delta: float) -> void:
	pass

func fetch_account() -> void:
	APokerClient.send_get_account()

func _on_connected():
	APokerClient.send_meow()

func _on_server_info(server_info: TPacket.TServerInfo):
	var label_str = "Server: "
	label_str += server_info.version + "." + str(server_info.build_number)
	label_str += " [" + server_info.revision + "] (" + server_info.compiler + ")"
	%ServerInfoLabel.text = label_str

func _on_login_res(login_res: TPacket.TLoginRes):
	if !login_res.is_ok:
		return
	if !login_res.is_logined:
		return
	
	nUserBox.set_account(login_res.account)
	await get_tree().create_timer(0.4).timeout
	nJoinTableList.refresh()
	
	fetch_account()

func _on_signup_res(signup_res: TPacket.TSignupRes):
	if !signup_res.is_ok:
		return
	if !signup_res.is_logined:
		return
	
	nUserBox.set_account(signup_res.account)
	await get_tree().create_timer(0.4).timeout
	nJoinTableList.refresh()

func _on_account(account: TPacket.TAccount):
	ALoginDialog.account = account
	nUserBox.set_account(account)
	
	nGetAccountTimer.stop()
	nGetAccountTimer.start()

func _on_tables(tables: TPacket.TTables):
	print("Received Tables: (", tables.offset, " - ", tables.length, ")")
	nJoinTableList.load_tables(tables)

func _on_sessions(sessions: TPacket.TSessions):
	print("Received Sessions: (", sessions.offset, " - ", sessions.length, ")")
	nWatchBoxes.sessions = sessions

func _on_WinTitle_quitting() -> void:
	get_tree().quit()

func _on_JoinTableList_refreshing(offset: int, length: int) -> void:
	ASounds.play_bop()
	APokerClient.send_get_tables(offset, length)

func _on_GetAccountTimer_timeout():
	fetch_account()
