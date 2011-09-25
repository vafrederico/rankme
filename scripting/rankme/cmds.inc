// FROM SMLIB
stock Array_FindHighestValue(any:array[], size, start=0){
	if (start < 0) {
		start = 0;
	}

	new any:value = array[start];
	new any:tempValue;
	new x = start;
	
	for (new i=start; i < size; i++) {
		
		tempValue = array[i];
		
		if (tempValue > value) {
			value = tempValue;
			x = i;
		}
		
	}
	
	return x;
}

public Action:CMD_ResetRank(client,args){
	if(!g_bEnabled) 
		return Plugin_Continue;
	new String:arg1[64];
	
	GetCmdArg(1,arg1,sizeof(arg1));
	
	//ReplaceString(arg1,sizeof(arg1)," ","");
	ReplaceString(arg1,sizeof(arg1),"\"","");
	new String:query[100];
	if(g_bRankByName){
		Format(query,sizeof(query),"DELETE FROM rankme WHERE name='%s'",arg1);
	} else {
		Format(query,sizeof(query),"DELETE FROM rankme WHERE steam='%s'",arg1);
	}
	SQL_TQuery(g_hStatsDb,SQL_NothingCallback,query);
	LogAction(client,-1,"[RankMe]: Reseted rank (%s)",arg1);
	new String:auth[64];
	for(new i=1;i<=MaxClients;i++){
		if(IsClientInGame(i)){
		
			GetClientAuthString(i,auth,sizeof(auth));
			
			if(StrEqual(auth,arg1,false))
				OnClientPutInServer(i);
		
		}
	}
	ReplyToCommand(client,"[RankMe]: Reseted");
	return Plugin_Handled;
}

public Action:CMD_ResetRankAll(client,args){
	if(!g_bEnabled) 
		return Plugin_Continue;
	
	SQL_TQuery(g_hStatsDb,SQL_NothingCallback,"DELETE FROM rankme WHERE 1=1");
	
	LogAction(client,-1,"[RankMe]: All rank data has been reseted");
	
	for(new i=1;i<=MaxClients;i++){
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}
	ReplyToCommand(client,"[RankMe]: All rank data has been reseted");
	return Plugin_Handled;
}

public Action:CMD_Purge(client,args){
	if(!g_bEnabled) 
		return Plugin_Continue;
	new String:arg1[64];
	
	GetCmdArg(1,arg1,sizeof(arg1));
	
	ReplaceString(arg1,sizeof(arg1)," ","");
	ReplaceString(arg1,sizeof(arg1),"\"","");
	
	new deletebefore;
	if(StringToInt(arg1) == 0){
		ReplyToCommand(client,"[RankMe]: Usage: rankpurge X (where X equals number of days of inactivity");
		return Plugin_Handled;
	}
	deletebefore = GetTime() - (StringToInt(arg1)*86400);
	new String:query[100];
	Format(query,sizeof(query),"DELETE FROM rankme WHERE lastconnect < '%d'",deletebefore);
	SQL_TQuery(g_hStatsDb,SQL_PurgeCallback,query);
	LogAction(client,-1,"[RankMe]: Purged rank (%s days inactivity)",arg1);
	ReplyToCommand(client,"[RankMe]: Purged");
	return Plugin_Handled;
}

public SQL_GetPlayersCallback(Handle:owner, Handle:hndl, const String:error[], any:Datapack){
	if(hndl == INVALID_HANDLE)
	{
		LogError("[RankMe] Query Fail: %s", error);
		PrintToServer(error);
		return;
	}
	g_TotalPlayers =SQL_GetRowCount(hndl);
}

public Action:CMD_TopWeapon(client,args){
	if(!g_bEnabled) 
		return Plugin_Continue;
	if(client == 0 || !IsClientInGame(client))
		return Plugin_Handled;
	if(args > 0){
		new String:arg1[20];
		new String:arg2[5];
		GetCmdArg(1,arg1,sizeof(arg1));
		GetCmdArg(2,arg2,sizeof(arg2));
		if(!StrEqual(arg1,"") && StringToInt(arg2) != 0 && GetWeaponNum(arg1) != 30){
			ShowTOPWeapon(client,GetWeaponNum(arg1),StringToInt(arg2));
		}	else if(!StrEqual(arg1,"") && GetWeaponNum(arg1) != 30){
			ShowTOPWeapon(client,GetWeaponNum(arg1),0);
		}
	} else {
		new Handle:menu = CreateMenu(MenuHandler_TopWeapon_Choose);
		SetMenuTitle(menu,"Top Weapon:");
		for(new i=0;i<=27;i++){
			AddMenuItem(menu,g_sWeaponsNamesGame[i],g_sWeaponsNamesFull[i]);
		}
		DisplayMenu(menu,client,MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public MenuHandler_TopWeapon_Choose(Handle:menu, MenuAction:action, param1, param2){
	
	if (action == MenuAction_Select)
	{
		new String:temp[250];
	
		GetMenuItem(menu, param2, temp, sizeof(temp));
		if(StringToInt(temp) >= 0){
			ShowTOPWeapon(param1,GetWeaponNum(temp),0);
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ShowTOPWeapon(client,weapon,at){
	if(client == 0 || !IsClientInGame(client))
		return;
	new Handle:Datapack= CreateDataPack();
	
	WritePackCell(Datapack,client);
	WritePackCell(Datapack,weapon);
	if(at>0){
		WritePackCell(Datapack,at-1);
		
	}	else {
		WritePackCell(Datapack,0);
		
	}
	new String:query[200];
	if(g_bRankBots && g_bShowBotsOnRank)
		Format(query,sizeof(query),"SELECT * FROM rankme where kills >= '%d' ORDER BY %s DESC LIMIT %i, 10",g_MinimalKills,g_sWeaponsNamesGame[weapon],at-1);
	else
		Format(query,sizeof(query),"SELECT * FROM rankme where kills >= '%d'  AND steam <> 'BOT' ORDER BY %s DESC LIMIT %i, 10",g_MinimalKills,g_sWeaponsNamesGame[weapon],at-1);
	
	SQL_TQuery(g_hStatsDb,SQL_TopWeaponCallback,query,Datapack);

}

public SQL_TopWeaponCallback(Handle:owner, Handle:hndl, const String:error[], any:Datapack){
	if(hndl == INVALID_HANDLE)
	{
		LogError("[RankMe] Query Fail: %s", error);
		PrintToServer(error);
		return;
	}
	
	ResetPack(Datapack);
	new i;
	new client = ReadPackCell(Datapack);
	if(client == 0 || !IsClientInGame(client))
		return;
		
	new weapon = ReadPackCell(Datapack);
	new at = ReadPackCell(Datapack);
	if(!SQL_HasResultSet(hndl) || SQL_GetRowCount(hndl) ==0){
		ShowTOPWeapon(client,weapon,g_TotalPlayers-9);
		return;
	}
	new String:name[256];
	new String:temp[500];
	
	new Handle:menu = CreateMenuEx(GetMenuStyleHandle(MenuStyle:MenuStyle_Radio),MenuHandler_TopWeapon);
	
	Format(temp,sizeof(temp)," %T\n","Showing",client,at+1,at+10,g_TotalPlayers);
	SetMenuTitle(menu,"");
	new String:sBuffer[200];

	while(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		i++;
		SQL_FetchString(hndl,2,name,sizeof(name));
		Format(sBuffer,sizeof(sBuffer),"%d - %s (%d) - %T: %d\n",i+at,name,SQL_FetchInt(hndl,4),"Kills",client,SQL_FetchInt(hndl,16+weapon));
		if(strlen(temp)+strlen(sBuffer) < MAX_LENGTH_MENU){
			Format(temp,sizeof(temp),"%s%s",temp,sBuffer);
			sBuffer="\0";
		}
	} 
	Format(temp,sizeof(temp),"%s\n ",temp);
	new String:temp1[20];
	Format(temp1,sizeof(temp1),"%d;%d",weapon,0);
	AddMenuItem(menu,temp1,temp);
	
	
	Format(temp,sizeof(temp),"%d;%d",weapon,at+i);
	
	Format(temp1,sizeof(temp1),"%T","Next",client);
	if(i>9)
		AddMenuItem(menu,temp,temp1);
	Format(temp,sizeof(temp),"%d;%d",weapon,at-i);
	Format(temp1,sizeof(temp1),"%T","Back",client);
	if(at+i-1 >9)
		AddMenuItem(menu,temp,temp1);
	
	DisplayMenuAtItem(menu,client,at,MENU_TIME_FOREVER);
}

public MenuHandler_TopWeapon(Handle:menu, MenuAction:action, param1, param2){
	
	if (action == MenuAction_Select)
	{
		new String:temp[250];
	
		GetMenuItem(menu, param2, temp, sizeof(temp));
		
		new String:v[2][5];
		ExplodeString(temp,";",v,2,5);
		if(StringToInt(v[1]) >= 0){
			ShowTOPWeapon(param1,StringToInt(v[0]),StringToInt(v[1])+1);
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:CMD_Top(client,args){
	if(!g_bEnabled) 
		return Plugin_Continue;
	if(client == 0 || !IsClientInGame(client))
		return Plugin_Handled;
	
	new String:arg1[5];
	GetCmdArg(1,arg1,sizeof(arg1));
	if(!StrEqual(arg1,"") && StringToInt(arg1) != 0){
		ShowTOP(client,StringToInt(arg1));
	}	else {
		ShowTOP(client,0);
	}
	return Plugin_Handled;
}

ShowTOP(client,at){
	if(client == 0 || !IsClientInGame(client))
		return;
	new Handle:Datapack= CreateDataPack();
	
	WritePackCell(Datapack,client);
	
	if(at>0){
		WritePackCell(Datapack,at-1);
		
	}	else {
		WritePackCell(Datapack,0);
		
	}
	new String:query[200];
	if(g_bRankBots && g_bShowBotsOnRank)
		Format(query,sizeof(query),"SELECT * FROM rankme where kills >= '%d' ORDER BY score DESC LIMIT %i, 10",g_MinimalKills,at-1);
	else
		Format(query,sizeof(query),"SELECT * FROM rankme where kills >= '%d'  AND steam <> 'BOT' ORDER BY score DESC LIMIT %i, 10",g_MinimalKills,at-1);
	
	SQL_TQuery(g_hStatsDb,SQL_TopCallback,query,Datapack);

}

public SQL_TopCallback(Handle:owner, Handle:hndl, const String:error[], any:Datapack){
	if(hndl == INVALID_HANDLE)
	{
		LogError("[RankMe] Query Fail: %s", error);
		PrintToServer(error);
		return;
	}
	
	ResetPack(Datapack);
	new i;
	new client = ReadPackCell(Datapack);
	if(client == 0 || !IsClientInGame(client))
		return;
	new at = ReadPackCell(Datapack);
	
	if(!SQL_HasResultSet(hndl) || SQL_GetRowCount(hndl) ==0){
		ShowTOP(client,g_TotalPlayers-9);
		return;
	}
	new String:name[256];
	new String:temp[500];
	
	new Handle:menu = CreateMenuEx(GetMenuStyleHandle(MenuStyle:MenuStyle_Radio),MenuHandler_Top);
	
	new Float:kdr;
	Format(temp,sizeof(temp)," %T\n","Showing",client,at+1,at+10,g_TotalPlayers);
	SetMenuTitle(menu,"");
	new String:sBuffer[200];
	while(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		
		i++;
		
		SQL_FetchString(hndl,2,name,sizeof(name));
			
		
		new deaths;
		if(SQL_FetchInt(hndl,6) == 0)
			deaths = 1;
		else 
			deaths=SQL_FetchInt(hndl,6);
		
		kdr = SQL_FetchFloat(hndl,5)/deaths;
		Format(sBuffer,sizeof(sBuffer),"%d - %s (%d) - KDR: %.2f\n",i+at,name,SQL_FetchInt(hndl,4),kdr);
		
		if(strlen(temp)+strlen(sBuffer) < MAX_LENGTH_MENU){
			Format(temp,sizeof(temp),"%s%s",temp,sBuffer);
			sBuffer="\0";
		}
	} 
	Format(temp,sizeof(temp),"%s\n ",temp);
	AddMenuItem(menu,temp,temp);
	
	
	IntToString(at+i,temp,sizeof(temp));
	new String:temp1[20];
	Format(temp1,sizeof(temp1),"%T","Next",client);
	if(i>9)
		AddMenuItem(menu,temp,temp1);
	IntToString(at-i,temp,sizeof(temp));
	Format(temp1,sizeof(temp1),"%T","Back",client);
	if(at+i-1 >9)
		AddMenuItem(menu,temp,temp1);
	
	DisplayMenuAtItem(menu,client,at,MENU_TIME_FOREVER);
}

public MenuHandler_Top(Handle:menu, MenuAction:action, param1, param2){
	
	if (action == MenuAction_Select)
	{
		new String:temp[250];
	
		GetMenuItem(menu, param2, temp, sizeof(temp));
		if(StringToInt(temp) >= 0){
			ShowTOP(param1,StringToInt(temp)+1);
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:CMD_TopKnife(client,args){
	if(!g_bEnabled) 
		return Plugin_Continue;
	if(client == 0 || !IsClientInGame(client))
		return Plugin_Handled;

	new String:arg1[5];
	GetCmdArg(1,arg1,sizeof(arg1));
	if(!StrEqual(arg1,"") && StringToInt(arg1) != 0){
		ShowTOPKnife(client,StringToInt(arg1));
	}	else {
		ShowTOPKnife(client,0);
	}
	return Plugin_Handled;
}

ShowTOPKnife(client,at){
	if(client == 0 || !IsClientInGame(client))
		return;
	new Handle:Datapack= CreateDataPack();
	
	WritePackCell(Datapack,client);
	
	if(at>0){
		WritePackCell(Datapack,at-1);
		
	}	else {
		WritePackCell(Datapack,0);
		
	}
	new String:query[200];
	if(g_bRankBots && g_bShowBotsOnRank)
		Format(query,sizeof(query),"SELECT * FROM rankme where kills >= '%d' ORDER BY knife DESC LIMIT %i, 10",g_MinimalKills,at-1);
	else
		Format(query,sizeof(query),"SELECT * FROM rankme where kills >= '%d'  AND steam <> 'BOT' ORDER BY knife DESC LIMIT %i, 10",g_MinimalKills,at-1);
		
	SQL_TQuery(g_hStatsDb,SQL_TopKnifeCallback,query,Datapack);

}

public SQL_TopKnifeCallback(Handle:owner, Handle:hndl, const String:error[], any:Datapack){
	if(hndl == INVALID_HANDLE)
	{
		LogError("[RankMe] Query Fail: %s", error);
		PrintToServer(error);
		return;
	}
	ResetPack(Datapack);
	new i;
	new client = ReadPackCell(Datapack);
	if(client == 0 || !IsClientInGame(client))
		return;
	new at = ReadPackCell(Datapack);
	if(!SQL_HasResultSet(hndl) || SQL_GetRowCount(hndl) ==0){
		ShowTOPKnife(client,g_TotalPlayers-9);
		return;
	}
	new String:name[256];
	new String:temp[500];
	
	new Handle:menu = CreateMenuEx(GetMenuStyleHandle(MenuStyle:MenuStyle_Radio),MenuHandler_TopKnife);
	
	Format(temp,sizeof(temp)," %T\n","Showing",client,at+1,at+10,g_TotalPlayers);
	SetMenuTitle(menu,"");
	new String:sBuffer[200];
	while(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		
		i++;
		
		SQL_FetchString(hndl,2,name,sizeof(name));
			
		
	
		Format(sBuffer,sizeof(sBuffer),"%d - %s (%d) - %T: %d\n",i+at,name,SQL_FetchInt(hndl,4),"KnifeKills",client,SQL_FetchInt(hndl,16));
		
		if(strlen(temp)+strlen(sBuffer) < MAX_LENGTH_MENU){
			Format(temp,sizeof(temp),"%s%s",temp,sBuffer);
			sBuffer="\0";
		}
	} 
	Format(temp,sizeof(temp),"%s\n ",temp);
	AddMenuItem(menu,temp,temp);
	
	
	IntToString(at+i,temp,sizeof(temp));
	new String:temp1[20];
	Format(temp1,sizeof(temp1),"%T","Next",client);
	if(i>9)
		AddMenuItem(menu,temp,temp1);
	IntToString(at-i,temp,sizeof(temp));
	Format(temp1,sizeof(temp1),"%T","Back",client);
	if(at+i-1 >9)
		AddMenuItem(menu,temp,temp1);

	DisplayMenuAtItem(menu,client,at,MENU_TIME_FOREVER);
}

public MenuHandler_TopKnife(Handle:menu, MenuAction:action, param1, param2){
	
	if (action == MenuAction_Select)
	{
		new String:temp[250];
	
		GetMenuItem(menu, param2, temp, sizeof(temp));
		if(StringToInt(temp) >= 0){
			ShowTOPKnife(param1,StringToInt(temp)+1);
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:CMD_TopNade(client,args){
	if(!g_bEnabled) 
		return Plugin_Continue;
	if(client == 0 || !IsClientInGame(client))
		return Plugin_Handled;

	new String:arg1[5];
	GetCmdArg(1,arg1,sizeof(arg1));
	if(!StrEqual(arg1,"") && StringToInt(arg1) != 0){
		ShowTOPNade(client,StringToInt(arg1));
	}	else {
		ShowTOPNade(client,0);
	}
	return Plugin_Handled;
}

ShowTOPNade(client,at){
	if(client == 0 || !IsClientInGame(client))
		return;
	new Handle:Datapack= CreateDataPack();
	
	WritePackCell(Datapack,client);
	
	if(at>0){
		WritePackCell(Datapack,at-1);
		
	}	else {
		WritePackCell(Datapack,0);
		
	}
	new String:query[200];
	if(g_bRankBots && g_bShowBotsOnRank)
		Format(query,sizeof(query),"SELECT name,score,hegrenade+flashbang+smokegrenade as nadekill FROM rankme where kills >= '%d' ORDER BY nadekill DESC LIMIT %i, 10",g_MinimalKills,at-1);
	else
		Format(query,sizeof(query),"SELECT name,score,hegrenade+flashbang+smokegrenade as nadekill FROM rankme where kills >= '%d'  AND steam <> 'BOT' ORDER BY nadekill DESC LIMIT %i, 10",g_MinimalKills,at-1);
		
	SQL_TQuery(g_hStatsDb,SQL_TopNadeCallback,query,Datapack);

}

public SQL_TopNadeCallback(Handle:owner, Handle:hndl, const String:error[], any:Datapack){
	if(hndl == INVALID_HANDLE)
	{
		LogError("[RankMe] Query Fail: %s", error);
		PrintToServer(error);
		return;
	}
	ResetPack(Datapack);
	new i;
	new client = ReadPackCell(Datapack);
	if(client == 0 || !IsClientInGame(client))
		return;
	new at = ReadPackCell(Datapack);
	if(!SQL_HasResultSet(hndl) || SQL_GetRowCount(hndl) ==0){
		ShowTOPNade(client,g_TotalPlayers-9);
		return;
	}
	new String:name[256];
	new String:temp[500];
	
	new Handle:menu = CreateMenuEx(GetMenuStyleHandle(MenuStyle:MenuStyle_Radio),MenuHandler_TopNade);
	new String:sBuffer[200];
	Format(temp,sizeof(temp)," %T\n","Showing",client,at+1,at+10,g_TotalPlayers);
	SetMenuTitle(menu,"");
	while(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		
		i++;
		
		SQL_FetchString(hndl,0,name,sizeof(name));
			
		
	
		Format(sBuffer,sizeof(sBuffer),"%d - %s (%d) - %T: %d\n",i+at,name,SQL_FetchInt(hndl,1),"Kills",client,SQL_FetchInt(hndl,2));
		
		if(strlen(temp)+strlen(sBuffer) < MAX_LENGTH_MENU){
			Format(temp,sizeof(temp),"%s%s",temp,sBuffer);
			sBuffer="\0";
		}
	} 
	Format(temp,sizeof(temp),"%s\n ",temp);
	AddMenuItem(menu,temp,temp);
	
	
	IntToString(at+i,temp,sizeof(temp));
	new String:temp1[20];
	Format(temp1,sizeof(temp1),"%T","Next",client);
	if(i>9)
		AddMenuItem(menu,temp,temp1);
	IntToString(at-i,temp,sizeof(temp));
	Format(temp1,sizeof(temp1),"%T","Back",client);
	if(at+i-1 >9)
		AddMenuItem(menu,temp,temp1);

	DisplayMenuAtItem(menu,client,at,MENU_TIME_FOREVER);
}

public MenuHandler_TopNade(Handle:menu, MenuAction:action, param1, param2){
	
	if (action == MenuAction_Select)
	{
		new String:temp[250];
	
		GetMenuItem(menu, param2, temp, sizeof(temp));
		if(StringToInt(temp) >= 0){
			ShowTOPNade(param1,StringToInt(temp)+1);
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_DoNothing(Handle:menu, MenuAction:action, param1, param2){
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:CMD_Rank(client,args){
	if(!g_bEnabled) 
		return Plugin_Continue;
	if(client == 0 || !IsClientInGame(client))
		return Plugin_Handled;
	
	if(g_aStats[client][KILLS] < g_MinimalKills){
		PrintToChat(client,"%s %t",MSG,"NotRanked",g_aStats[client][KILLS],g_MinimalKills);
		return Plugin_Handled;
	}
	new String:query[500];
	if(g_bRankBots && g_bShowBotsOnRank)
		Format(query,sizeof(query),"SELECT * FROM rankme where kills >= '%d' ORDER BY score DESC",g_MinimalKills);
	else
		Format(query,sizeof(query),"SELECT * FROM rankme where kills >= '%d'  AND steam <> 'BOT' ORDER BY score DESC",g_MinimalKills);
	
	SQL_TQuery(g_hStatsDb,SQL_RankCallback,query,client);
	return Plugin_Handled;
}

public SQL_RankCallback(Handle:owner, Handle:hndl, const String:error[], any:client){
	if(hndl == INVALID_HANDLE)
	{
		LogError("[RankMe] Query Fail: %s", error);
		return;
	}
	if(client == 0 || !IsClientInGame(client))
		return;
	new i;
	new String:name[256];
	GetClientName(client, name, sizeof(name));
	new String:auth[32];
	GetClientAuthString(client,auth,sizeof(auth));
	g_TotalPlayers =SQL_GetRowCount(hndl);
	new String:Name_receive[MAX_NAME_LENGTH];
	new String:Auth_receive[32];
	while(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		i++;
		SQL_FetchString(hndl,2,Name_receive,MAX_NAME_LENGTH);
		SQL_FetchString(hndl,1,Auth_receive,32);
			
		if((g_bRankByName && StrEqual(Name_receive,name,false)) || (!g_bRankByName && StrEqual(Auth_receive,auth,false))){
			new Float:kdr;
			new deaths;
			if(SQL_FetchInt(hndl,6) == 0)
				deaths = 1;
			else 
				deaths=SQL_FetchInt(hndl,6);
			
			kdr = SQL_FetchFloat(hndl,5)/deaths;
			if(g_bShowRankAll){
				CPrintToChatAll("%s %t",MSG,"IsRankedAt", name,i,SQL_GetRowCount(hndl),g_aStats[client][SCORE],g_aStats[client][KILLS],g_aStats[client][DEATHS],kdr);
			} else {
				CPrintToChat(client,"%s %t",MSG,"IsRankedAt", name,i,SQL_GetRowCount(hndl),g_aStats[client][SCORE],g_aStats[client][KILLS],g_aStats[client][DEATHS],kdr);
			}
			break;
		}
	} 
}

public Action:CMD_Session(client,args){
	if(!g_bEnabled) 
		return Plugin_Continue;
	if(client == 0 || !IsClientInGame(client))
		return Plugin_Handled;
	new Handle:panel = CreateMenuEx(_,MenuHandler_DoNothing,MENU_ACTIONS_ALL);
	new String:text[255];
	new String:temp[255];
	SetMenuPagination(panel,4);
	Format(temp,sizeof(temp),"- %T\n","BasicStats",client);
	StrCat(text,255,temp);
	Format(temp,sizeof(temp),"%T: %i\n","Points",client,g_aSession[client][SCORE]);
	StrCat(text,255,temp);
	new ikills = g_aSession[client][KILLS];
	new ideaths=g_aSession[client][DEATHS];
	new deaths;
	if(ideaths == 0)
		deaths = 1;
	else 
		deaths=ideaths;
	new Float:kills = IntToFloat(ikills);

	new shots;
	if(g_aSession[client][SHOTS] == 0)
		shots = 1;
	else
		shots = g_aSession[client][SHOTS];
	
	Format(temp,255,"%T   KDR: %.2f\n","KillsDeaths",client,ikills,ideaths,kills/deaths);
	StrCat(text,255,temp);
	Format(temp,255,"Headshots: %d   %T: %d   TKs: %d\n ",g_aSession[client][HEADSHOTS],"Suicides",client,g_aSession[client][SUICIDES],g_aSession[client][TK]);
	StrCat(text,255,temp);
	AddMenuItem(panel,"",text);
	text="";
	
	Format(temp,sizeof(temp),"- %T\n","RoundStats",client);
	StrCat(text,255,temp);
	Format(temp,255,"%T: %d/%d   %T: %d/%d\n ","TRWins",client,g_aSession[client][TR_WIN],g_aSession[client][ROUNDS_TR],"CTWins",client,g_aSession[client][CT_WIN],g_aSession[client][ROUNDS_CT]);
	StrCat(text,255,temp);
	AddMenuItem(panel,"",text);
	text="";
	
	Format(temp,sizeof(temp),"- %T\n","HitStats",client);
	StrCat(text,255,temp);
	Format(temp,255,"%T: %d   %T: %d   %T: %.2f%%\n ","Shots",client,shots,"Hits",client,g_aSession[client][HITS],"Accuracy",client,IntToFloat(g_aSession[client][HITS])/shots*100);
	StrCat(text,255,temp);
	AddMenuItem(panel,"",text);
	text="";
	
	Format(temp,sizeof(temp),"- %T\n","BombHostagesStats",client);
	StrCat(text,255,temp);
	Format(temp,255,"%T: %d   %T: %d   %T: %d\n","PlantedBombs",client,g_aSession[client][C4_PLANTED],"ExplodedBombs",client,g_aSession[client][C4_EXPLODED],"DefusedBombs",client,g_aSession[client][C4_DEFUSED]);
	StrCat(text,255,temp);
	Format(temp,255,"%T: %d","RescuedHostages",client,g_aSession[client][HOSTAGES_RESCUED]);
	StrCat(text,255,temp);
	AddMenuItem(panel,"",text);
	text="";
	
	if(g_bVipEnabled){
		Format(temp,sizeof(temp),"- %T\n","VIPStats",client);
		StrCat(text,255,temp);
		Format(temp,255,"%T: %d/%d   %T: %d\n ","VIPEscapes",client,g_aSession[client][VIP_ESCAPED],g_aSession[client][VIP_PLAYED],"VIPsKilled",client,g_aSession[client][VIP_KILLED]);
		StrCat(text,255,temp);
		AddMenuItem(panel,"",text);
		text="";
	}
	
	Format(temp,sizeof(temp),"- %T\n","OtherStats",client);
	StrCat(text,255,temp);
	new time = GetTime()-g_aSession[client][CONNECTED];
	new hours = RoundToFloor(time/3600.0);
	time = time-(hours*3600);
	
	new minutes = RoundToFloor(time/60.0);
	time = time-(minutes*60);
	
	Format(temp,255,"%T","TimeConnected",client,hours,minutes,time);
	StrCat(text,255,temp);
	AddMenuItem(panel,"",text);
	text="";
	
	DisplayMenu(panel,client,MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action:CMD_HitBox(client,args){
	if(!g_bEnabled) 
		return Plugin_Continue;
	if(client == 0 || !IsClientInGame(client))
		return Plugin_Handled;

	new Handle:panel = CreateMenuEx(_,MenuHandler_DoNothing,MENU_ACTIONS_ALL);
	new String:temp[255];
	new ihits;
	new Float:hits;
	ihits = g_aStats[client][HITS];
	new String:text[255];
	if(ihits == 0)
		hits= 1.0;
	else
		hits = IntToFloat(ihits);
	
	Format(temp,255,"HitBox:\n");
	StrCat(text,255,temp);
	Format(temp,255,"%T: %d (%.2f%%)\n","Head",client,g_aHitBox[client][1],(g_aHitBox[client][1]/hits)*100);
	StrCat(text,255,temp);
	Format(temp,255,"%T: %d (%.2f%%)\n","Chest",client,g_aHitBox[client][2],(g_aHitBox[client][2]/hits)*100);
	StrCat(text,255,temp);
	Format(temp,255,"%T: %d (%.2f%%)\n","Stomach",client,g_aHitBox[client][3],(g_aHitBox[client][3]/hits)*100);
	StrCat(text,255,temp);
	Format(temp,255,"%T: %d (%.2f%%)\n","LeftArm",client,g_aHitBox[client][4],(g_aHitBox[client][4]/hits)*100);
	StrCat(text,255,temp);
	Format(temp,255,"%T: %d (%.2f%%)\n","RightArm",client,g_aHitBox[client][5],(g_aHitBox[client][5]/hits)*100);
	StrCat(text,255,temp);
	Format(temp,255,"%T: %d (%.2f%%)\n","LeftLeg",client,g_aHitBox[client][6],(g_aHitBox[client][6]/hits)*100);
	StrCat(text,255,temp);
	Format(temp,255,"%T: %d (%.2f%%)","RightLeg",client,g_aHitBox[client][7],(g_aHitBox[client][7]/hits)*100);
	StrCat(text,255,temp);
	AddMenuItem(panel,"",text);

	DisplayMenu(panel,client,MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Action:CMD_WeaponMe(client,args){
	if(!g_bEnabled) 
		return Plugin_Continue;
	if(client == 0 || !IsClientInGame(client))
		return Plugin_Handled;
	new weapons_a[28];
	for(new a=0;a<=27;a++){
		weapons_a[a] = g_aWeapons[client][a];
	}
	new weapons_b[28][2];
	new index;
	new start;
	new bool:indexs[28];
	for(new a =0; a<=27;a++){
		index =Array_FindHighestValue(weapons_a, sizeof(weapons_a));
		weapons_b[a][0] = index;
		weapons_b[a][1] = weapons_a[index];
		
		
		if(weapons_a[index] == 0){
			start=a;
			break;
		}
		weapons_a[index] = 0;
		indexs[index]=true;
	}

	for(new b=0; b<=27; b++){
	
		if(indexs[b] ==false){
			if(start <=27)
				weapons_b[start][0]=b;
			
			start++;
		}
	}
	new Handle:panel = CreateMenu(MenuHandler_DoNothing);
	
	new ikills =g_aStats[client][KILLS];
	
	new Float:hits;
	if(ikills == 0)
		hits= 1.0;
	else
		hits = IntToFloat(ikills);

	new String:temp[255];
	Format(temp,sizeof(temp),"%T","WeaponsStats",client);
	SetMenuTitle(panel, temp);
	for(new i=0;i<=27;i++){
		Format(temp,sizeof(temp),"%s: %d (%.2f%%)",g_sWeaponsNamesFull[weapons_b[i][0]],weapons_b[i][1],(weapons_b[i][1]/hits)*100);
		AddMenuItem(panel,temp,temp,ITEMDRAW_DISABLED);
	}
	
	DisplayMenu(panel,client,MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action:CMD_StatsMe(client,args){
	if(!g_bEnabled) 
		return Plugin_Continue;
	
	if(client == 0 || !IsClientInGame(client))
		return Plugin_Handled;
	new String:query[500];
	if(g_bRankBots && g_bShowBotsOnRank)
		Format(query,sizeof(query),"SELECT * FROM rankme where kills >= '%d' ORDER BY score DESC",g_MinimalKills);
	else
		Format(query,sizeof(query),"SELECT * FROM rankme where kills >= '%d'  AND steam <> 'BOT' ORDER BY score DESC",g_MinimalKills);
	SQL_TQuery(g_hStatsDb,SQL_StatsMeCallback,query,client);
	return Plugin_Handled;
	
}

public SQL_StatsMeCallback(Handle:owner, Handle:hndl, const String:error[], any:client){
	if(hndl == INVALID_HANDLE)
	{
		LogError("[RankMe] Query Fail: %s", error);
		return;
	}
	if(client == 0 || !IsClientInGame(client))
		return;
	new i;
	new String:auth[32];
	GetClientAuthString(client,auth,sizeof(auth));
	new String:name[MAX_NAME_LENGTH];
	GetClientName(client,name,sizeof(name));
	g_TotalPlayers =SQL_GetRowCount(hndl);
	new String:Auth_receive[32];
	new String:Name_receive[MAX_NAME_LENGTH];
	while(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		i++;
		SQL_FetchString(hndl,1,Auth_receive,32);
		
		SQL_FetchString(hndl,2,Name_receive,MAX_NAME_LENGTH);
		
		if((g_bRankByName && StrEqual(name,Name_receive)) || (!g_bRankByName && StrEqual(Auth_receive,auth,false))){
			new Handle:panel = CreateMenuEx(_,MenuHandler_DoNothing,MENU_ACTIONS_ALL);
			new String:text[255];
			SetMenuPagination(panel,4);
			new ikills = g_aStats[client][KILLS];
			new ideaths=g_aStats[client][DEATHS];
			new deaths;
			if(ideaths == 0)
				deaths = 1;
			else 
				deaths=ideaths;
			new Float:kills = IntToFloat(ikills);
			new shots;
			if(g_aStats[client][SHOTS] == 0)
				shots = 1;
			else
				shots = g_aStats[client][SHOTS];
			new String:temp[255];
			Format(temp,sizeof(temp),"- %T\n","BasicStats",client);
			StrCat(text,255,temp);
			Format(temp,sizeof(temp),"Rank: %i/%i   %T: %i [%i]\n",i,SQL_GetRowCount(hndl),"Points",client,g_aStats[client][SCORE],g_aSession[client][SCORE]);
			StrCat(text,255,temp);
			Format(temp,255,"%T   KDR: %.2f\n","KillsDeaths",client,ikills,ideaths,kills/deaths);
			StrCat(text,255,temp);
			Format(temp,255,"Headshots: %d   %T: %d   TKs: %d\n ",g_aStats[client][HEADSHOTS],"Suicides",client,g_aStats[client][SUICIDES],g_aStats[client][TK]);
			StrCat(text,255,temp);
			AddMenuItem(panel,"",text);
			text="";
			
			Format(temp,sizeof(temp),"- %T\n","RoundStats",client);
			StrCat(text,255,temp);
			Format(temp,255,"%T: %d/%d   %T: %d/%d\n ","TRWins",client,g_aStats[client][TR_WIN],g_aStats[client][ROUNDS_TR],"CTWins",client,g_aStats[client][CT_WIN],g_aStats[client][ROUNDS_CT]);
			StrCat(text,255,temp);
			AddMenuItem(panel,"",text);
			text="";
			
			Format(temp,sizeof(temp),"- %T\n","HitStats",client);
			StrCat(text,255,temp);
			Format(temp,255,"%T: %d   %T: %d   %T: %.2f%%\n ","Shots",client,shots,"Hits",client,g_aStats[client][HITS],"Accuracy",client,IntToFloat(g_aStats[client][HITS])/shots*100);
			StrCat(text,255,temp);
			AddMenuItem(panel,"",text);
			text="";
			
			Format(temp,sizeof(temp),"- %T\n","BombHostagesStats",client);
			StrCat(text,255,temp);
			Format(temp,255,"%T: %d   %T: %d   %T: %d\n","PlantedBombs",client,g_aStats[client][C4_PLANTED],"ExplodedBombs",client,g_aStats[client][C4_EXPLODED],"DefusedBombs",client,g_aStats[client][C4_DEFUSED]);
			StrCat(text,255,temp);
			Format(temp,255,"%T: %d","RescuedHostages",client,g_aStats[client][HOSTAGES_RESCUED]);
			StrCat(text,255,temp);
			AddMenuItem(panel,"",text);
			text="";
						
			if(g_bVipEnabled){
				Format(temp,sizeof(temp),"- %T\n","VIPStats",client);
				StrCat(text,255,temp);
				Format(temp,255,"%T: %d/%d   %T: %d\n ","VIPEscapes",client,g_aStats[client][VIP_ESCAPED],g_aStats[client][VIP_PLAYED],"VIPsKilled",client,g_aStats[client][VIP_KILLED]);
				StrCat(text,255,temp);
				AddMenuItem(panel,"",text);
				text="";
			}
			
			Format(temp,sizeof(temp),"- %T\n","OtherStats",client);
			StrCat(text,255,temp);
			new time = g_aStats[client][CONNECTED] + GetTime()-g_aSession[client][CONNECTED];
			new hours = RoundToFloor(time/3600.0);
			time = time-(hours*3600);
			
			new minutes = RoundToFloor(time/60.0);
			time = time-(minutes*60);
			
			Format(temp,255,"%T","TimeConnected",client,hours,minutes,time);
			StrCat(text,255,temp);
			AddMenuItem(panel,"",text);
			text="";
			DisplayMenu(panel,client,MENU_TIME_FOREVER);
			
		}
	}
}

public PanelNoHandle(Handle:menu, MenuAction:action, param1, param2){

	

}

public Action:CMD_Next(client,args){
	if(!g_bEnabled) 
		return Plugin_Continue;
	if(client == 0 || !IsClientInGame(client))
		return Plugin_Handled;
	new String:query[500];
	if(g_bRankBots && g_bShowBotsOnRank)
		Format(query,sizeof(query),"SELECT * FROM rankme where kills >= '%d' ORDER BY score DESC",g_MinimalKills);
	else
		Format(query,sizeof(query),"SELECT * FROM rankme where kills >= '%d'  AND steam <> 'BOT' ORDER BY score DESC",g_MinimalKills);
	SQL_TQuery(g_hStatsDb,SQL_NextCallback,query,client);
	return Plugin_Handled;
}

public SQL_NextCallback(Handle:owner, Handle:hndl, const String:error[], any:client){
	if(hndl == INVALID_HANDLE)
	{
		LogError("[RankMe] Query Fail: %s", error);
		return;
	}
	if(client == 0 || !IsClientInGame(client))
		return;
	new i;
	new a;
	g_TotalPlayers =SQL_GetRowCount(hndl);
	new String:next_players_name[10][MAX_NAME_LENGTH];
	new next_players_score[10];
	new bool:dobreak;
	new String:name[MAX_NAME_LENGTH];
	GetClientName(client,name,sizeof(name));
	new String:auth[32];
	GetClientAuthString(client,auth,sizeof(auth));
	new String:Auth_receive[32];
	new String:Name_receive[MAX_NAME_LENGTH];
	while(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		i++;
		
		SQL_FetchString(hndl,1,Auth_receive,32);
		SQL_FetchString(hndl,2,Name_receive,MAX_NAME_LENGTH);
		
		
		if((g_bRankByName && StrEqual(name,Name_receive)) || (!g_bRankByName && StrEqual(Auth_receive,auth,false))){
		
			dobreak=true;
		
		}
		else {
		
			if(i<=10){
				SQL_FetchString(hndl,2,next_players_name[i-1],MAX_NAME_LENGTH-1);
				next_players_score[i-1]=SQL_FetchInt(hndl,4);
			}
			else {
				for(a=0;a<9;a++){
				
					next_players_score[a] = next_players_score[a+1];
					strcopy(next_players_name[a],MAX_NAME_LENGTH-1,next_players_name[a+1]);
				}
				SQL_FetchString(hndl,2,next_players_name[9],MAX_NAME_LENGTH-1);
				next_players_score[9]=SQL_FetchInt(hndl,4);
			}
		}
		if(dobreak)
			break;
	} 
	new Handle:panel = CreateMenuEx(_,MenuHandler_DoNothing,MENU_ACTIONS_ALL);
	new String:text[500];
	new String:temp[255];
	Format(temp,sizeof(temp),"%T\n","Next9Players",client);
	StrCat(text,255,temp);
	
	new max;
	if(i<10){
		max = i-1; 
	} else {
		max = 9;
	}
	for(new b=0;b<=max;b++){
		if(!StrEqual(next_players_name[b],"",false)){
			Format(temp,sizeof(temp),"- %s (%d) => +%d\n",next_players_name[b],next_players_score[b],next_players_score[b]-g_aStats[client][SCORE]);
			StrCat(text,500,temp);
		}
		
	}
	AddMenuItem(panel,"",text);
	DisplayMenu(panel,client,MENU_TIME_FOREVER);
	
	CloseHandle(panel);
}

public Action:CMD_ResetOwnRank(client,args){

	if(!g_bEnabled || !g_bResetOwnRank) 
		return Plugin_Continue;
	if(client == 0 || !IsClientInGame(client))
		return Plugin_Handled;
	new String:param[64];
	new String:query[100];
	if(g_bRankByName){
		GetClientName(client,param,sizeof(param));
		Format(query,sizeof(query),"DELETE FROM rankme WHERE name='%s'",param);
	} else {
		GetClientAuthString(client,param,sizeof(param));
		Format(query,sizeof(query),"DELETE FROM rankme WHERE steam='%s'",param);
	}
	SQL_TQuery(g_hStatsDb,SQL_NothingCallback,query);
	LogAction(client,-1,"[RankMe]: Reseted own rank (%s)",param);
	OnClientPutInServer(client);
	ReplyToCommand(client,"[RankMe]: Reseted");
	return Plugin_Handled;
}

public Float:IntToFloat(integer){
	new String:s[300];
	IntToString(integer,s,sizeof(s));
	return StringToFloat(s);
}

public FloatToInt(Float:ifloat){
	new String:s[300];
	FloatToString(ifloat,s,sizeof(s));
	return StringToInt(s);
}
