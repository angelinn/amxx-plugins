/*

	Задължително трябва да работят и двата плъгина, за да може да изкарва информацията.
	При написването на /server и избиране на сървър, се изкарва информация за сървъра и има команди (Refresh и Connect).
	Подобно на xredirect, та дори и по-добро, без излишни худове и препращания при пълен сървър !

*/

#include <amxmodx>
#include <amxmisc>
#include <server_query>
#include <cromchat>

#define TASK_ID_UPDATE   1234
#define TASK_ID_NOTIFY   7177
#define UPDATE_DELAY     10.0

// my logs directory function
stock get_logsdir(output[], len) {
	return get_localinfo("amxx_logs", output, len);
}

enum _:Status {
	Status_Offline,
	Status_Online
};

enum _:ServerData {
	Server_Name[32],
	Server_Address[32],
	Server_Port,
	Server_Status,
	Server_NumPlayers,
	Server_MaxPlayers,
	Server_Map[64]
};

new Array:gServerData;
new gNumServers;

new bool:gUpdating;
new bool:gFirstUpdate = true;
new gUpdateIndex;
new gUpdateManual;

new gMenuText[1024];
const PERPAGE = 7;

#define MAX_PLAYERS 32

new gMenuPage[MAX_PLAYERS + 1];
new gSelectedServer[MAX_PLAYERS + 1];

new const gMenuTitleSelect[] = "MenuSelect";
new const gMenuTitleInfo  [] = "MenuInfo";

new gCurrentMap[64];
new gMaxPlayers;
//new gMsgSayText;
new gRedirectInfo[256];

new const REDIRECT_INFO[] = "__redirected";

new gCvarRefresh;
new gCvarNotifyTime;

public plugin_init() {
	register_plugin("Server Menu", "0.0.3", "Exolent");
	
	CC_SetPrefix("&x04[Servers Menu]&x01");
	
	register_clcmd("say /server", "CmdServer");
	register_clcmd("say /servers", "CmdServer");
	register_clcmd("say_team /server", "CmdServer");
	register_clcmd("say_team /servers", "CmdServer");
	
	register_menu(gMenuTitleSelect, 1023, "MenuSelect");
	register_menu(gMenuTitleInfo  , 1023, "MenuInfo"  );
	
	gCvarRefresh = register_cvar("server_menu_refresh", "3");
	gCvarNotifyTime = register_cvar("server_menu_notify_time", "120")
	
	gServerData = ArrayCreate(ServerData);
	
	LoadServers();
	
	if(gNumServers) {
		UpdateServers();
	}
	
	get_mapname(gCurrentMap, charsmax(gCurrentMap));
	
	gMaxPlayers = get_maxplayers();
	
	new notifyTime = get_pcvar_float(gCvarNotifyTime)
	if (notifyTime > 0)
		set_task(notifyTime, "NotifyServers", TASK_ID_NOTIFY, _, _, "b")

	//gMsgSayText = get_user_msgid("SayText");
}

public plugin_end() {
	ArrayDestroy(gServerData);
}

public client_putinserver(id) {
	if(get_user_info(id, REDIRECT_INFO, gRedirectInfo, charsmax(gRedirectInfo)) && gRedirectInfo[0]) {
		new map[64], numPlayers, maxPlayers, hostName[128], piece[32];
		
		strtok(gRedirectInfo, map, charsmax(map), gRedirectInfo, charsmax(gRedirectInfo), ';');
		
		strtok(gRedirectInfo, piece, charsmax(piece), gRedirectInfo, charsmax(gRedirectInfo), ';');
		numPlayers = str_to_num(piece);
		
		strtok(gRedirectInfo, piece, charsmax(piece), hostName, charsmax(hostName), ';');
		maxPlayers = str_to_num(piece);
		
		new name[32];
		get_user_name(id, name, charsmax(name));
		
		CC_SendMatched(0, CC_COLOR_TEAM, "^3 %s^1 redirected from^3 %s (Map: %s - Players: %d%d)", name, hostName, map, numPlayers, maxPlayers);
		
		set_user_info(id, REDIRECT_INFO, "");
	}
}

public client_disconnected(id) {
	if(gUpdateManual == id) {
		gUpdateManual = -1;
	}
	
	remove_task(id);
}

public CmdServer(id) {
	if(!gNumServers) {
		set_task(0.1, "TaskShowNoServers", id);
	} else {
		gMenuPage[id] = 0;
		
		ShowServerList(id);
	}
}

public TaskShowNoServers(id) 
{
	CC_SendMatched(id, CC_COLOR_TEAM, "There are no servers to redirect to.");
}

ShowServerList(id) {
	gSelectedServer[id] = 0;
	
	new len = copy(gMenuText, charsmax(gMenuText), "\ySelect server:");
	new keys;
	
	new page = gMenuPage[id];
	new pages = (gNumServers + PERPAGE - 1) / PERPAGE;
	
	if(page < 0) {
		gMenuPage[id] = page = 0;
	}
	else if(page >= pages) {
		gMenuPage[id] = page = pages - 1;
	}
	
	if(pages > 1) {
		len += formatex(gMenuText[len], charsmax(gMenuText) - len, " %d/%d", (page + 1), pages);
	}
	
	len += copy(gMenuText[len], charsmax(gMenuText) - len, "^n^n");
	
	new start = page * PERPAGE;
	new stop = min(start + PERPAGE, gNumServers);
	
	new data[ServerData];
	
	for(new i = start; i < stop; i++) {
		ArrayGetArray(gServerData, i, data);
		
		len += formatex(gMenuText[len], charsmax(gMenuText) - len, "\r%d. \w%s [\y%s\w] %d/%d^n", (i - start + 1), data[Server_Name], data[Server_Map], data[Server_NumPlayers], data[Server_MaxPlayers]);
		
		keys |= (1 << (i - start));
	}
	
	if(page > 0) {
		len += copy(gMenuText[len], charsmax(gMenuText) - len, "^n\r8. \wBack");
		keys |= MENU_KEY_8;
	}
	
	if((page + 1) < pages) {
		len += copy(gMenuText[len], charsmax(gMenuText) - len, "^n\r9. \wNext");
		keys |= MENU_KEY_9
	}
	
	len += copy(gMenuText[len], charsmax(gMenuText) - len, "^n\r0. \wExit");
	keys |= MENU_KEY_0;
	
	show_menu(id, keys, gMenuText, _, gMenuTitleSelect);
}

public MenuSelect(id, key) {
	switch(++key % 10) {
		case 8: {
			gMenuPage[id]--;
			
			ShowServerList(id);
		}
		case 9: {
			gMenuPage[id]++;
			
			ShowServerList(id);
		}
		case 0: {
		}
		default: {
			gSelectedServer[id] = (gMenuPage[id] * PERPAGE) + key - 1;
			
			ShowServerInfo(id);
		}
	}
}

ShowServerInfo(id) {
	new data[ServerData];
	ArrayGetArray(gServerData, gSelectedServer[id], data);
	
	new len = formatex(gMenuText, charsmax(gMenuText), "\yServer name is %s^nServer ip address is %s:%d^n^n", data[Server_Name], data[Server_Address], data[Server_Port]);
	new keys;
	
	if(data[Server_Status] == Status_Online) {
		len += copy(    gMenuText[len], charsmax(gMenuText) - len, "\rStatus: \yOnline^n");
		len += formatex(gMenuText[len], charsmax(gMenuText) - len, "\rPlayers: \w%d/%d^n", data[Server_NumPlayers], data[Server_MaxPlayers]);
		len += formatex(gMenuText[len], charsmax(gMenuText) - len, "\rMap: \w%s^n^n", data[Server_Map]);
		
		if(get_pcvar_num(gCvarRefresh) & 2) {
			len += copy(    gMenuText[len], charsmax(gMenuText) - len, "\r1. \wRefresh^n");
			
			keys |= MENU_KEY_1;
		}
		
		len += copy(    gMenuText[len], charsmax(gMenuText) - len, "\r2. \wRedirect^n");
		
		keys |= MENU_KEY_2;
	} else {
		len += copy(    gMenuText[len], charsmax(gMenuText) - len, "\rStatus: \yOffline^n^n");
	}
	
	len += copy(gMenuText[len], charsmax(gMenuText) - len, "^n\r9. \wBack");
	keys |= MENU_KEY_9;
	
	len += copy(gMenuText[len], charsmax(gMenuText) - len, "^n\r0. \wExit");
	keys |= MENU_KEY_0;
	
	show_menu(id, keys, gMenuText, _, gMenuTitleInfo);
}

public MenuInfo(id, key) {
	switch(++key % 10) {
		case 1: {
			if(!gUpdating) {
				gUpdateIndex = gSelectedServer[id];
				gUpdateManual = id;
				
				remove_task(TASK_ID_UPDATE);
				
				CC_SendMatched(id, CC_COLOR_TEAM, "Please wait while the server updates...");
				
				UpdateServers();
				
			} else {
				CC_SendMatched(id, CC_COLOR_TEAM, "The servers are already updating right now.");
			}
			
			ShowServerInfo(id);
		}
		case 2: {
			new data[ServerData];
			ArrayGetArray(gServerData, gSelectedServer[id], data);
			
			new name[32];
			get_user_name(id, name, charsmax(name));
			
			CC_SendMatched(0, CC_COLOR_TEAM, "^3 %s^1 redirected to^3 %s^1 (Map: %s - Players: %d/%d)", name, data[Server_Name], data[Server_Map], data[Server_NumPlayers], data[Server_MaxPlayers]);
			
			new len = formatex(gRedirectInfo, charsmax(gRedirectInfo), "%s;%d;%d;", gCurrentMap, get_playersnum(), gMaxPlayers);
			get_user_name(0, gRedirectInfo[len], charsmax(gRedirectInfo) - len);
			
			set_user_info(id, REDIRECT_INFO, gRedirectInfo);
			
			client_cmd(id, ";Connect %s:%d", data[Server_Address], data[Server_Port]);
		}
		case 9: {
			ShowServerList(id);
		}
		case 0: {
			gSelectedServer[id] = 0;
		}
	}
}

public UpdateServers() {
	new data[ServerData];
	ArrayGetArray(gServerData, gUpdateIndex, data);
	
	new errcode, error[128];
	while(!sq_query(data[Server_Address], data[Server_Port], SQ_Server, "SQueryResults", errcode)) {
		sq_error(errcode, error, charsmax(error));
		
		data[Server_Status] = Status_Offline;
		
		ArraySetArray(gServerData, gUpdateIndex++, data);
		
		if(gUpdateManual) {
			if(gUpdateManual > 0) {
				CC_SendMatched(gUpdateManual, CC_COLOR_TEAM, "There was an error updating the server information");
				
				gSelectedServer[gUpdateManual] = gUpdateIndex;
				
				ShowServerInfo(gUpdateManual);
			}
			
			gUpdateIndex = 0;
			gUpdateManual = 0;
			
			set_task(UPDATE_DELAY, "UpdateServers", TASK_ID_UPDATE);
			return;
		}
		
		if(gUpdateIndex == gNumServers) {
			gUpdateIndex = 0;
			
			if(gFirstUpdate) {
				gFirstUpdate = false;
				
				if(get_pcvar_num(gCvarRefresh) & 1) {
					set_task(UPDATE_DELAY, "UpdateServers", TASK_ID_UPDATE);
				}
			} else {
				set_task(UPDATE_DELAY, "UpdateServers", TASK_ID_UPDATE);
			}
			
			return;
		}
		
		ArrayGetArray(gServerData, gUpdateIndex, data);
	}
	
	gUpdating = true;
}

public SQueryResults(id, type, Trie:buffer, Float:queryTime, bool:failed, _data[], _dataSize) {
	gUpdating = false;
	
	new data[ServerData];
	ArrayGetArray(gServerData, gUpdateIndex, data);
	
	if(failed) {
		data[Server_Status] = Status_Offline;
	} else {
		data[Server_Status] = Status_Online;
        
		TrieGetString(buffer, "map", data[Server_Map], charsmax(data[Server_Map]));
		TrieGetCell(buffer, "num_players", data[Server_NumPlayers]);
		TrieGetCell(buffer, "max_players", data[Server_MaxPlayers]);
	}
	
	ArraySetArray(gServerData, gUpdateIndex, data);
	
	if(gUpdateManual) {
		if(gUpdateManual > 0) {
			CC_SendMatched(gUpdateManual, CC_COLOR_TEAM, "Updated server information.");
			
			gSelectedServer[gUpdateManual] = gUpdateIndex;
			
			ShowServerInfo(gUpdateManual);
		}
		
		gUpdateIndex = 0;
		gUpdateManual = 0;
		
		set_task(UPDATE_DELAY, "UpdateServers", TASK_ID_UPDATE);
		return;
	}
	
	if(++gUpdateIndex < gNumServers) {
		UpdateServers();
	} else {
		gUpdateIndex = 0;
		
		if(gFirstUpdate) {
			gFirstUpdate = false;
			
			if(get_pcvar_num(gCvarRefresh) & 1) {
				set_task(UPDATE_DELAY, "UpdateServers", TASK_ID_UPDATE);
			}
		} else {
			set_task(UPDATE_DELAY, "UpdateServers", TASK_ID_UPDATE);
		}
	}
}

LoadServers() {
	new file[64];
	get_configsdir(file, charsmax(file));
	add(file, charsmax(file), "/servers.ini");
	
	new f = fopen(file, "rt");
	
	if(!f) return;
	
	// File format:
	// "Server Name Here" "Address:Port"
	
	new line[256];
	new data[ServerData];
	new pos;
	
	while(!feof(f)) {
		fgets(f, line, charsmax(line));
		trim(line);
		
		if(!line[0] || line[0] == ';' || line[0] == '/' && line[1] == '/') {
			continue;
		}
		
		parse(line, data[Server_Name], charsmax(data[Server_Name]), data[Server_Address], charsmax(data[Server_Address]));
		
		pos = contain(data[Server_Address], ":");
		
		if(pos > 0) {
			data[Server_Address][pos] = 0;
			data[Server_Port] = str_to_num(data[Server_Address][pos + 1]);
		} else {
			data[Server_Port] = 27015;
		}
		
		ArrayPushArray(gServerData, data);
		gNumServers++;
	}
	
	fclose(f);
}



public NotifyServers()
{
	new data[ServerData];
	new notifyMessage[1024]
	new server[128]

	new len 

	for (new i = 0; i < gNumServers; i++)
	{
		server[0] = 0

		ArrayGetArray(gServerData, i, data);

		if (data[Server_Status] == Status_Online)
		{
			len += formatex(server, charsmax(server) - len, "^3%s ^1[^4%s^1] %d/%d ", data[Server_Name], data[Server_Map], data[Server_NumPlayers], data[Server_MaxPlayers]);
			strcat(notifyMessage, server, charsmax(notifyMessage) - len)
		}
	}
	
	if (gNumServers > 0)
		CC_SendMatched(0, CC_COLOR_TEAM, "^1 Use ^3/servers ^1to redirect - %s", notifyMessage);
}
