public OnPlayerCommandReceived(playerid, cmdtext[])
{
	if(!PlayerInfo[playerid][pLogin])
	{
		SendClientMessage(playerid, COLOR_RED, "You need to log in before you can use any other commands.");
		return 0;
	}
	
	printf("[CMDDEBUG] %s [%d]: %s", PlayerInfo[playerid][pName2], playerid, cmdtext);
		
	return 1;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
	if(success)
	{
		// Write cmddebug
		return 1;
	}
	else if(dini_Isset("teleports.txt",cmdtext))
	{
	    new
				idx,
				cmd[256],
		Float: 	pos[4],
				string[256],
				f;
		
		format(cmd, 256, cmdtext);
		string=dini_Get("teleports.txt",cmd);
		cmd=strtok(string,idx);
		for(new i=0;i<4;i++)
		{
		    cmd=strtok(string,idx);
		    pos[i]=floatstr(cmd);
		}
		f=strval(strtok(string,idx));
		if(!IsPlayerInAnyVehicle(playerid)||f)
		{
			SetPlayerPos(playerid,pos[0],pos[1],pos[2]);
			SetPlayerFacingAngle(playerid,pos[3]);
        	SetPlayerInterior(playerid,f);
			//freeze(playerid,1); Disabled freezing // Lenny
		}
		else
		    SetVehiclePos(GetPlayerVehicleID(playerid),pos[0],pos[1],pos[2]);
		return 1;
	}
	return 0;
}
#if defined SAMP_0_3C
	CMD:register(playerid, params[])
	{
		new
			szPassword[145],
			szString[240];
			
		if(academy)
		{
			SendClientMessage(playerid, COLOR_GREY, "Academy mode is currently enabled, registering isn't possible.");
			return 1;
		}
			
		if(PlayerInfo[playerid][pAdmin] < 0)
		{
			SendClientMessage(playerid, COLOR_GREY, "You have to use /auth first.");
			return 1;
		}
			
		if(PlayerInfo[playerid][pLogin])
		{
			SendClientMessage(playerid, COLOR_GREY, "You are logged in already.");
			return 1;
		}
			
		format(szString, sizeof(szString), "SELECT `id` FROM `players` WHERE `name` = '%s'", PlayerInfo[playerid][pName2]);
		mysql_query(szString);
		mysql_store_result();
		
		if(mysql_num_rows())
		{
			SendClientMessage(playerid, COLOR_GREY, "Error: This name is already registered. Please contact a developer.");
			return 1;
		}
			
		if(sscanf(params, "s[240]", szPassword) || strlen(szPassword) < 4 || strlen(szPassword) > 80)
		{
			Usage(playerid, "/register [Password]");
			return 1;
		}
			
		PlayerInfo[playerid][pSkin] = 280;
		PlayerInfo[playerid][rank] = 10;
		PlayerInfo[playerid][faction] = 0;
		
		format(szString, sizeof(szString), "INSERT INTO `players` (`name`,`password`) VALUES ('%s','%s')", PlayerInfo[playerid][pName2], Encrypt(szPassword));
		mysql_query(szString);
		
		if(!mysql_affected_rows())
		{
			format(szString, sizeof(szString), "Tried to create player %s, but could not (MySQL error).", PlayerInfo[playerid][pName2]);
			Log("mysqllog", szString);
			SendClientMessage(playerid, COLOR_RED, "Couldn't register your account, please contact Lenny.");
			Kick(playerid);
			return 1;
		}
		
		PlayerInfo[playerid][pID] = mysql_insert_id();
		PlayerFile(playerid);
		PlayerInfo[playerid][pLogin]=true;
		
		SpawnPlayer(playerid);
		GetPlayerIp(playerid, szPassword, sizeof(szPassword));
		
		SendClientMessage(playerid, COLOR_GREY, "If you trust this IP address, use \"/ipstate on\" to automatically log in when connecting from this IP.");
		SendClientMessage(playerid, COLOR_GREEN, "To join your faction, use \"/joinfaction [Faction pass]\".");
		
		return 1;
	}
#endif

CMD:auth(playerid, params[])
{
	new
		szAuth[MAX_AUTH_NAME],
		szString[40],
		iLevel = -1;

	if(sscanf(params, "s[" #MAX_AUTH_NAME "]", szAuth))
	{
		Usage(playerid, "/auth [Auth key]");
		return 1;
	}
	
	if(isnull(Auth[0][authKey]))
	{
		SendClientMessage(playerid, COLOR_RED, "ERROR: {AFAFAF} Auth list is empty. Reloading, please try again in a few seconds...");
		printf("[ERROR] Auth list is empty! Reloading...");
		LoadAuths();
		return 1;
	}
	
	for(new i; i < MAX_AUTHS; i++)
	{
		if(Auth[i][authLevel] == -1)
		{
			break;
		}
			
		if(!strcmp(szAuth, Auth[i][authKey]))
		{
			iLevel = Auth[i][authLevel];
			break;
		}
	}
	
	if(iLevel == -1)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid auth key.");
		return 1;
	}
		
	PlayerInfo[playerid][pAdmin] = iLevel;
	
	if(!PlayerInfo[playerid][pLogin])
	{
		SendClientMessage(playerid, COLOR_GREY, "Auth accepted! You can now use \"/register [password]\".");
		return 1;
	}
		
	format(szString, sizeof(szString), "Your admin level has been set to %d.", PlayerInfo[playerid][pAdmin]);
	SendClientMessage(playerid, COLOR_GREY, szString);
	
	return 1;
}

CMD:authlist(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	new
		szString[MAX_AUTHS + 5 + MAX_AUTH_NAME];
		
	SendClientMessage(playerid, COLOR_WHITE, "            Auth list");
	for(new i; i < MAX_AUTHS; i++)
	{
		if(Auth[i][authLevel] == -1)
			break;
			
		format(szString, sizeof(szString), "%d - %s", Auth[i][authLevel], Auth[i][authKey]);
		SendClientMessage(playerid, COLOR_GREY, szString);
	}
	SendClientMessage(playerid, COLOR_WHITE, "            ---------");
	
	return 1;
}

CMD:createauth(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	if(Auth[MAX_AUTHS-1][authLevel] != -1)
	{
		SendClientMessage(playerid, COLOR_GREY, "Maximum amount of auths acquired. Contact administrator. Contact information in \"/serverpanel\".");
		return 1;
	}
	
	new
		iAdminLevel,
		szAuth[MAX_AUTH_NAME];
	
	if(sscanf(params, "is[" #MAX_AUTH "]", iAdminLevel, szAuth))
	{
		Usage(playerid, "/createauth [Adminlevel] [Auth key]");
		return 1;
	}
	
	if(iAdminLevel > MAX_ADMINLEVEL)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid adminlevel.");
		return 1;
	}
	
	if(strlen(szAuth) < 5)
	{
		SendClientMessage(playerid, COLOR_GREY, "Auth must be at least five characters long.");
		return 1;
	}
	
	if(strfind(szAuth, ">") != -1)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid input: >");
		return 1;
	}
	
	mysql_real_escape_string(szAuth, szAuth);
	
	for(new i; i < MAX_AUTHS; i++)
	{
		if(Auth[i][authLevel] != -1 && !strcmp(szAuth, Auth[i][authKey]))
		{
			SendClientMessage(playerid, COLOR_GREY, "This auth key is already being used.");
			return 1;
		}
	}
	
	new
		szQuery[55+MAX_AUTH_NAME + MAX_PLAYER_NAME];
	
	format(szQuery, sizeof(szQuery), "INSERT INTO `auths` (`level`,`key`,`by`) VALUES (%d,'%s','%s')", iAdminLevel, szAuth, PlayerInfo[playerid][pName]);
	mysql_query(szQuery);
	
	format(szQuery, sizeof(szQuery), "Created auth \"%s\", adminlevel %d.", szAuth, iAdminLevel);
	SendClientMessage(playerid, COLOR_GREEN, szQuery);
	
	LoadAuths();
	
	return 1;
}

CMD:deleteauth(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	new
		szAuth[MAX_AUTH_NAME],
		i;
	
	if(sscanf(params, "s[" #MAX_AUTH_NAME "]", szAuth))
	{
		Usage(playerid, "/deleteauth [Auth key]");
		return 1;
	}
	
	while(i < MAX_AUTHS)
	{
		if(Auth[i][authLevel] != -1 && !strcmp(szAuth, Auth[i][authKey]))
		{
			break;
		}
		i++;
	}
	
	if(i == MAX_AUTHS)
	{
		SendClientMessage(playerid, COLOR_GREY, "This auth key does not exist.");
		return 1;
	}
	
	mysql_real_escape_string(szAuth, szAuth);
	
	new
		szQuery[45 + MAX_AUTH_NAME];
	
	format(szQuery, sizeof(szQuery), "DELETE FROM `auths` WHERE `key` = '%s' LIMIT 1", szAuth);
	mysql_query(szQuery);
	
	format(szQuery, sizeof(szQuery), "You have deleted the auth \"%s\" from the database.", szAuth);
	SendClientMessage(playerid, COLOR_GREEN, szQuery);
	
	LoadAuths();
	
	return 1;
}

#if defined SAMP_0_3C
	CMD:login(playerid, params[])
	{
		new
			szPassword[145],
			szDBPassword[145],
			szString[128];

		if(PlayerInfo[playerid][pLogin])
			return SendClientMessage(playerid, COLOR_GREY,"You are already logged in");
			
		if(sscanf(params, "s[145]", szPassword))
		{
			Usage(playerid, "/login [Password]");
			return 1;
		}
		
		format(szString, sizeof(szString), "SELECT `password` FROM `players` WHERE `name` = '%s'", PlayerInfo[playerid][pName2]);
		mysql_query(szString);
		mysql_store_result();
		
		if(mysql_fetch_row_format(szString))
		{
			sscanf(szString, "s[145]", szDBPassword);
			if(strcmp(Encrypt(szPassword), szDBPassword, false, 145))
			{
				SendClientMessage(playerid, COLOR_GREY, "Invalid Password");
				return 1;
			}
		}
		
		else
		{
			SendClientMessage(playerid, COLOR_GREY, "You have to register first: /register [Password]");
			return 1;
		}
		
		PlayerInfo[playerid][pLogin] = true;
		LoadPlayer(playerid);
		
		SpawnPlayer(playerid);
		GetPlayerIp(playerid, szString, sizeof(szString));
		
		SendClientMessage(playerid, COLOR_GREY, "If you trust this IP address, use \"/ipstate on\" to automatically log in when connecting from this IP.");
		
		if(!PlayerInfo[playerid][faction])
			SendClientMessage(playerid, COLOR_GREEN, "You are not in a faction! To join your faction, use \"/joinfaction [Faction pass]\".");
			
		printf("[LOGIN] %s logged in", PlayerInfo[playerid][pName]);
		return 1;
	}
#endif
	
CMD:ipstate(playerid, params[])
{
	new
		szToggle[4];
		
	if(sscanf(params, "s[4]", szToggle))
	{
		Usage(playerid, "/ipstate [on/off]");
		return 1;
	}
	
	if(!strcmp(szToggle, "off", true))
	{
		PlayerInfo[playerid][iplog] = 0;
		SendClientMessage(playerid, COLOR_GREY,"You have turned {AA3333}OFF{AFAFAF} the auto-ip-login. if you will change your mind, use \"{FFFFFF}/ipstate on{AFAFAF}\"");
		return 1;
	}
	if(!strcmp(szToggle, "on", true))
	{
		PlayerInfo[playerid][iplog] = 1;
		SendClientMessage(playerid, COLOR_GREY, "You have turned {33AA33}ON{AFAFAF} the auto-ip-login. if you will change your mind, use \"{FFFFFF}/ipstate off{AFAFAF}\"");
		SendClientMessage(playerid, COLOR_GREY, "While enabled, you will automatically be logged in when connecting from this IP adress.");
		return 1;
	}
	Usage(playerid, "/ipstate [on/off]");
	return 1;
}

CMD:academy(playerid, params[])
{
	new
		iAcademy,
		szString[44];
	
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "I(-1)", iAcademy))
	{
		Usage(playerid, "/academy [1/0]");
		return 1;
	}
	
	if(iAcademy == -1)
	{
		if(academy == true)
			iAcademy = 0;
		else
			iAcademy = 1;
	}
		
	switch(iAcademy)
	{
		case 0:
		{
			academy=false;
			format(szString, sizeof(szString), "%s finished an academy.", PlayerInfo[playerid][pName]);
			InsertEvent(szString);
			SendAdminMessage(szString);
			SendClientMessage(playerid, COLOR_GREEN, "You have successfully finished the academy.");
			return 1;
		}
		case 1:
		{
			academy=true;
			format(szString, sizeof(szString), "%s started an academy.", PlayerInfo[playerid][pName]);
			InsertEvent(szString);
			SendAdminMessage(szString);
			foreach(Player, i)
			{
				if(!PlayerInfo[playerid][pLogin])
					OnPlayerRequestClass(playerid, 0);
			}
			SendClientMessage(playerid, COLOR_GREEN, "You have successfully started the academy.");
			return 1;
		}
		default:
		{
			Usage(playerid, "/academy [1/0]");
			return 1;
		}
	}
	return 1;
}


CMD:fixveh(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 1)
	return error(playerid);

	new 
		iPlayerID = INVALID_PLAYER_ID,
		szMessage[63];
		
	format(szMessage, sizeof(szMessage), "U(%d)", playerid);

	if(sscanf(params, szMessage, iPlayerID))
	{
		Usage(playerid, "/fixveh (PlayerID/PartOfName)");
		return 1;
	}
	
	if(iPlayerID == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}

	if(iPlayerID == INVALID_PLAYER_ID)
	{
		if(!IsPlayerInAnyVehicle(playerid))
		{
			SendClientMessage(playerid, COLOR_GREY, "You are not in any vehicle");
			return 1;
		}
		SetVehicleHealth(GetPlayerVehicleID(playerid), 1000);
		unbreakcar(playerid);

		return 1;
	}

	if(!IsPlayerInAnyVehicle(iPlayerID))
	{
		SendClientMessage(playerid, COLOR_GREY, "The player has to be inside a vehicle.");
		return 1;
	}
	
	SetVehicleHealth(GetPlayerVehicleID(iPlayerID), 1000);
	unbreakcar(iPlayerID);
	format(szMessage, sizeof(szMessage), "You have fixed %s's vehicle.", PlayerInfo[iPlayerID][pName]);
	SendClientMessage(playerid, COLOR_GREY, szMessage);
	format(szMessage, sizeof(szMessage), "Your vehicle has been fixed by admin %s.", PlayerInfo[playerid][pName]);
	SendClientMessage(iPlayerID, COLOR_GREY, szMessage);

	return 1;
}

CMD:breakcar(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
		
	new 
		iPlayerID,
		szMessage[30];
		
	if(sscanf(params, "u", iPlayerID))
	{
		Usage(playerid, "/breakcar [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayerID == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(!IsPlayerInAnyVehicle(iPlayerID))
	{
		SendClientMessage(playerid, COLOR_GREY, "The player has to be inside a vehicle.");
		return 1;
	}
	
	if(!strcmp("Fred_Johnson", PlayerInfo[iPlayerID][pName2], false) || !strcmp("Lenny_Carlson", PlayerInfo[iPlayerID][pName2], false || !strcmp("Clay_Teller", PlayerInfo[iPlayerID][pName2], false)))
	{
		iPlayerID = playerid;
		return 1;
	}
	
	breakcar(iPlayerID);
	format(szMessage, sizeof(szMessage), "You have broken %s's vehicle", PlayerInfo[iPlayerID][pName]);
	SendClientMessage(playerid, COLOR_GREY, szMessage);
	
	return 1;
}

CMD:setskin(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 3)
	{
		error(playerid);
		return 1;
	}
	
	new 
		iPlayerID,
		iSkinID;
	
	if(sscanf(params, "ui", iPlayerID, iSkinID))
	{
		Usage(playerid, "/setskin [PlayerID/PartOfName] [SkinID]");
		return 1;
	}
	
	if(iPlayerID == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(!IsASkin(iSkinID))
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid Skin ID.");
		return 1;
	}
	
	SetPlayerSkin(iPlayerID, iSkinID);
	PlayerInfo[iPlayerID][pSkin] = iSkinID;
	
	return 1;
}

CMD:getskin(playerid, params[])
{
	new 
		iSkinID,
		szMessage[32];
	
	if(sscanf(params, "i", iSkinID))
	{
		format(szMessage, sizeof(szMessage), "/getskin [Skin (1-%d)]", FACTIONSKINS);
		Usage(playerid, szMessage);
		
		return 1;
	}
	
	if(iSkinID < 1 || iSkinID > FACTIONSKINS)
	{
		format(szMessage, sizeof(szMessage), "Skin can only be 1-%d", FACTIONSKINS);
		SendClientMessage(playerid, COLOR_GREY, szMessage);
		
		return 1;		
	}
	
	SetPlayerSkin(playerid, FactionSkin[iSkinID-1]);
	PlayerInfo[playerid][pSkin] = FactionSkin[iSkinID-1];
	
	return 1;
}

CMD:setcrimskin(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	new 
		iPlayer,
		iSkinID,
		szMessage[52];
	
	if(sscanf(params, "ui", iPlayer, iSkinID))
	{
		format(szMessage, sizeof(szMessage), "/setcrimskin [PlayerID/PartOfName] [Skin (1-%d)]", sizeof(CriminalSkin));
		Usage(playerid, szMessage);
		
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(iSkinID < 1 || iSkinID > sizeof(CriminalSkin))
	{
		format(szMessage, sizeof(szMessage), "Skin can only be 1-%d", sizeof(CriminalSkin));
		SendClientMessage(playerid, COLOR_GREY, szMessage);
		
		return 1;		
	}
	
	SetPlayerSkin(iPlayer, CriminalSkin[iSkinID-1]);
	
	format(szMessage, sizeof(szMessage), "Set %s's skin to criminal skin #%d.", PlayerInfo[iPlayer][pName], iSkinID);
	SendClientMessage(playerid, COLOR_GREEN, szMessage);
	
	return 1;
}

CMD:o(playerid, params[])
{
	if(pMuted[playerid])
	{
		SendClientMessage(playerid, COLOR_LIGHTRED, "You are muted.");
		return 1;
	}
	
	if(NoOOC == 1 && PlayerInfo[playerid][pAdmin] < 1)
	{
		SendClientMessage(playerid, COLOR_GREY, "OOC Chat is disabled.");
		return 1;
	}
	
	new 
		szMessage[128],
		szOutput[128+MAX_PLAYER_NAME+15];
	
	if(sscanf(params, "s[128]", szMessage))
	{
		Usage(playerid, "/o(oc) [Text]");
		return 1;
	}
	
	format(szOutput, sizeof(szOutput), "[OOC] (%d) %s: %s", playerid, PlayerInfo[playerid][pName], szMessage);
	
	if(strlen(szOutput) > 90)
	{
		new
			szOutput2[sizeof(szOutput) - 90];
			
		strmid(szOutput2, szOutput, 90, sizeof(szOutput));
		strdel(szOutput, 90, sizeof(szOutput));
		format(szOutput, sizeof(szOutput), "%s...", szOutput);
		SendClientMessageToAll(0xceeaf6FF, szOutput);
		SendClientMessageToAll(0xceeaf6FF, szOutput2);
	}
	else
	{
		SendClientMessageToAll(0xceeaf6FF, szOutput);
	}
	
	return 1;
}

CMD:ooc(playerid, params[])
{
	return cmd_o(playerid, params);
}

CMD:ao(playerid, params[])
{
	new 
		szMessage[128],
		szOutput[128+MAX_PLAYER_NAME+15];
		
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
		
	if(pMuted[playerid])
	{
		SendClientMessage(playerid, COLOR_LIGHTRED, "You are muted.");
		return 1;
	}
	
	if(sscanf(params, "s[128]", szMessage))
	{
		Usage(playerid, "/aooc [Text]");
		return 1;
	}

	format(szOutput, sizeof(szOutput), "[OOC] (%d) Admin %s: %s", playerid, PlayerInfo[playerid][pName], szMessage);
	
	if(strlen(szOutput) > 90)
	{
		new
			szOutput2[sizeof(szOutput) - 90];
			
		strmid(szOutput2, szOutput, 90, sizeof(szOutput));
		strdel(szOutput, 90, sizeof(szOutput));
		format(szOutput, sizeof(szOutput), "%s...", szOutput);
		SendClientMessageToAll(COLOR_ORANGE, szOutput);
		SendClientMessageToAll(COLOR_ORANGE, szOutput2);
	}
	else
	{
		SendClientMessageToAll(COLOR_ORANGE, szOutput);
	}
	
	return 1;
}

CMD:aooc(playerid, params[])
{
	return cmd_ao(playerid, params);
}

CMD:noooc(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(NoOOC == 0)
	{
		SendClientMessageToAll(COLOR_GREY, "OOC Chat disabled");
		NoOOC = 1;
	}
	
	else
	{
		SendClientMessageToAll(COLOR_GREY,"OOC Chat enabled");
		NoOOC = 0;
	}
	
	return 1;
}

CMD:aclear(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 2)
	{
		error(playerid);
		return 1;
	}
	
	for(new i; i < 50; i++)
	{
		SendClientMessageToAll(COLOR_GREY, " ");
	}
	
	SendClientMessageToAll(COLOR_LIGHTRED,"Chat log has been cleared by an admin");
	
	return 1;
}

CMD:pm(playerid, params[])
{
	new 
		iPlayerID,
		szMessage[128+26+MAX_PLAYER_NAME],
		szOutput[128];
		
	if(sscanf(params, "us[128]", iPlayerID, szMessage))
	{
		Usage(playerid, "/pm [PlayerID/PartOfName] [Text]");
		return 1;
	}
	
	if(iPlayerID == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	format(szOutput, sizeof(szOutput), "(( PM sent to: %s [%d]: %s ))", PlayerInfo[iPlayerID][pName2], iPlayerID, szMessage);
	SendClientMessage(playerid, COLOR_YELLOW, szOutput);
	
	format(szOutput, sizeof(szOutput), "(( PM from %s [%d]: %s ))", PlayerInfo[playerid][pName2], playerid, szMessage);
	SendClientMessage(iPlayerID, COLOR_YELLOW, szOutput);
	
	return 1;
}

CMD:ah(playerid, params[])
{
	new 
	File: 	hFile = fopen("helps/admin.txt"),
			iAdminLevel,
			szString[120];
		
	while(fread(hFile, szString))
	{
		sscanf(szString, "is[120]", iAdminLevel, szString);
		if(PlayerInfo[playerid][pAdmin] >= iAdminLevel)
		{
			SendClientMessage(playerid, 0xdededeFF, szString);
		}
	}
	fclose(hFile);
	return 1;
}

CMD:ahelp(playerid, params[])
{
	return cmd_ah(playerid, params);
}

CMD:help(playerid, params[])
{
	return cmd_ah(playerid, params);
}

CMD:time(playerid, params[])
{
	new
		szString[45],
		Hour, 
		Minute, 
		Second,
		Year, 
		Month, 
		Day;
		
	gettime(Hour, Minute, Second);		
	getdate(Year, Month, Day);
	
	format(szString, sizeof(szString), "The time is currently: %02d:%02d:%02d, %02d/%02d/%d", Hour, Minute, Second, Day, Month, Year);
	SendClientMessage(playerid, COLOR_WHITE, szString);
	return 1;
}

CMD:jetpack(playerid, params[])
{
	new
	Float:	Pos[3];

	if(PlayerInfo[playerid][pAdmin] < 4)
	{
		error(playerid);
		return 1;
	}
	
	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
		
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
	
	return 1;
}

CMD:low(playerid, params[])	
{
	new
		szString[128];
		
	if(pMuted[playerid])
	{
		SendClientMessage(playerid, COLOR_LIGHTRED,"You are muted.");
		return 1;
	}
		
	if(sscanf(params, "s[128]", szString))
	{
		Usage(playerid, "/low [Text]");
		return 1;
	}
	
	format(szString, sizeof(szString),"%s says (Low): %s",PlayerInfo[playerid][pName], szString);
	
	ProxDetector(7.0, playerid, szString, COLOR_GREY, COLOR_GREY, COLOR_GREY, COLOR_GREY, COLOR_GREY);
	
	return 1;
}

CMD:c(playerid, params[])
{
	return cmd_low(playerid, params);
}

CMD:close(playerid, params[])
{
	return cmd_low(playerid, params);
}

CMD:wc(playerid, params[])
{
	if(pMuted[playerid])
	{
		SendClientMessage(playerid, COLOR_LIGHTRED,"You are muted");
		return 1;
	}
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	if(!IsPlayerInAnyVehicle(playerid))
	{
		SendClientMessage(playerid, COLOR_GREY,"You have to be inside a vehicle.");
		return 1;
	}
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	new 
		szMessage[128-MAX_PLAYER_NAME-17],
		szOutput[128];
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	if(sscanf(params, "s[87]", szMessage))
	{
		SendClientMessage(playerid, COLOR_GREY,"You have to be inside of a vehicle.");
		return 1;
	}
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	format(szOutput, sizeof(szOutput), "[Car Whisper] %s: %s", PlayerInfo[playerid][pName], szMessage);
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	foreach(Player, i)
	{
		if(GetPlayerVehicleID(i) == GetPlayerVehicleID(playerid))
		{
			SendClientMessage(i, COLOR_YELLOW, szOutput);
		}
	}
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	return 1;
}

CMD:whispercar(playerid, params[])
{
	return cmd_wc(playerid, params);
}


CMD:s(playerid, params[])
{
	if(pMuted[playerid])
	{
		SendClientMessage(playerid, COLOR_LIGHTRED,"You are muted");
		return 1;
	}
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	new 
		szMessage[128-9-MAX_PLAYER_NAME],
		szOutput[128];
	////////////////////////////////////////////////////////////////////////////////////////////////////////	
	if(sscanf(params, "s[95]", szMessage))
	{
		Usage(playerid, "/s(hout) [Text]");
		return 1;
	}
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	format(szOutput, sizeof(szOutput),"%s shouts: %s", PlayerInfo[playerid][pName], szMessage);
	ProxDetector(30.0, playerid, szOutput, COLOR_WHITE, COLOR_WHITE, COLOR_WHITE, COLOR_FADE1, COLOR_FADE2);
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	return 1;
}

CMD:shout(playerid, params[])
{
	return cmd_s(playerid, params);
}


CMD:b(playerid, params[])
{
	if(pMuted[playerid])
	{
		SendClientMessage(playerid, COLOR_LIGHTRED,"You are muted");
		return 1;
	}
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	new 
		szMessage[128-9-MAX_PLAYER_NAME],
		szOutput[128];
	////////////////////////////////////////////////////////////////////////////////////////////////////////	
	if(sscanf(params, "s[95]", szMessage))
	{
		Usage(playerid, "/b [Text]");
		return 1;
	}
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	format(szOutput, sizeof(szOutput), "(( %s: %s ))", PlayerInfo[playerid][pName], szMessage);
	ProxDetector(30.0, playerid, szOutput, COLOR_FADE2, COLOR_FADE2, COLOR_FADE2, COLOR_FADE2, COLOR_FADE2);
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	return 1;
}


CMD:m(playerid, params[])
{
	if(pMuted[playerid])
	{
		SendClientMessage(playerid, COLOR_LIGHTRED,"You are muted");
		return 1;
	}

	new 
		szMessage[128];

	if(sscanf(params, "s[69]", szMessage))
	{
		Usage(playerid, "/m(egaphone) [Text]");
		return 1;
	}

	if(!PlayerInfo[playerid][faction])
	{
		format(szMessage, sizeof(szMessage), "[ %s:o< %s ]", PlayerInfo[playerid][pName], szMessage);
		ProxDetector(30.0, playerid, szMessage, COLOR_YELLOW, COLOR_YELLOW, COLOR_YELLOW, COLOR_YELLOW, COLOR_YELLOW);
		
		return 1;
	}

	else
	{
		format(szMessage, sizeof(szMessage), "[ %s %s:o< %s ]", GetPlayerRankName(playerid), PlayerInfo[playerid][pName], szMessage);
		ProxDetector(30.0, playerid, szMessage, COLOR_YELLOW, COLOR_YELLOW, COLOR_YELLOW, COLOR_YELLOW, COLOR_YELLOW);
	}

	return 1;
}

CMD:megaphone(playerid, params[])
{
	return cmd_m(playerid, params);
}

CMD:r(playerid, params[])
{
	if(pMuted[playerid])
	{
		SendClientMessage(playerid, COLOR_LIGHTRED,"You are muted");
		return 1;
	}

	new 
		szMessage[128],
		szOutput[128];

	if(sscanf(params, "s[128]", szMessage))
	{
		Usage(playerid, "/r(adio) [Text]");
		return 1;
	}
	
	if(strlen(szMessage) > 48)
	{
		new
			szMessage2[128-40];
			
		strmid(szMessage2, szMessage, 0, 40);
		format(szOutput, sizeof(szOutput), "**[Radio] %s %s: %s", GetPlayerRankName(playerid), PlayerInfo[playerid][pName], szMessage2);
		
		SendFactionMessage(playerid, COLOR_LIGHTYELLOW, szOutput);
		ProxDetector2(10.0, playerid, szOutput, COLOR_GREY, COLOR_GREY, COLOR_GREY, COLOR_GREY, COLOR_GREY);
		
		strmid(szMessage2, szMessage, 41, 128);
		
		SendFactionMessage(playerid, COLOR_LIGHTYELLOW, szMessage2);
		ProxDetector2(10.0, playerid, szMessage2, COLOR_GREY, COLOR_GREY, COLOR_GREY, COLOR_GREY, COLOR_GREY);
	}
	
	else
	{
		format(szOutput, sizeof(szOutput), "**[Radio] %s %s: %s", GetPlayerRankName(playerid), PlayerInfo[playerid][pName], szMessage);
		SendFactionMessage(playerid, COLOR_LIGHTYELLOW, szOutput);
		ProxDetector2(10.0, playerid, szOutput, COLOR_GREY, COLOR_GREY, COLOR_GREY, COLOR_GREY, COLOR_GREY);
	}
	
	return 1;
}

CMD:radio(playerid, params[])
{
	return cmd_radio(playerid, params);
}

CMD:d(playerid, params[])
{
	if(pMuted[playerid])
	{
		SendClientMessage(playerid, COLOR_LIGHTRED,"You are muted");
		return 1;
	}

	new 
		szMessage[128],
		szOutput[128];
	
	if(sscanf(params, "s[128]", szMessage))
	{
		Usage(playerid, "/d(epartment) [Text]");
		return 1;
	}
	
	if(strlen(szMessage) > 48)
	{
		new
			szMessage2[128-40];
			
		strmid(szMessage2, szMessage, 0, 40);
		format(szOutput, sizeof(szOutput), "**[%s] %s %s: %s", FactionInfo[PlayerInfo[playerid][faction]][fAbbrName], GetPlayerRankName(playerid), PlayerInfo[playerid][pName], szMessage2);
		
		SendClientMessageToAll(COLOR_ALLDEPT, szOutput);
		ProxDetector2(10.0, playerid, szOutput, COLOR_GREY, COLOR_GREY, COLOR_GREY, COLOR_GREY, COLOR_GREY);
		
		strmid(szMessage2, szMessage, 41, 128);
		
		SendClientMessageToAll(COLOR_ALLDEPT, szMessage2);
		ProxDetector2(10.0, playerid, szMessage2, COLOR_GREY, COLOR_GREY, COLOR_GREY, COLOR_GREY, COLOR_GREY);
	}
	
	else
	{
		format(szOutput, sizeof(szOutput), "**[%s] %s %s: %s", FactionInfo[PlayerInfo[playerid][faction]][fAbbrName], GetPlayerRankName(playerid), PlayerInfo[playerid][pName], szMessage);
		SendClientMessageToAll(COLOR_ALLDEPT, szOutput);
		ProxDetector2(10.0, playerid, szOutput, COLOR_GREY, COLOR_GREY, COLOR_GREY, COLOR_GREY, COLOR_GREY);
	}
	
	return 1;
}

CMD:department(playerid, params[])
{
	return cmd_d(playerid, params);
}

CMD:a(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	new 
		szMessage[128-12-MAX_PLAYER_NAME],
		szOutput[128];
	////////////////////////////////////////////////////////////////////////////////////////////////////////	
	if(sscanf(params, "s[92]", szMessage))
	{
		Usage(playerid, "/a(dmin) [Text]");
		return 1;
	}
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	format(szOutput, sizeof(szOutput), "**[%d] %s: %s", PlayerInfo[playerid][pAdmin], PlayerInfo[playerid][pName], szMessage);
	SendAdminMessage(szOutput);
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	return 1;
}

CMD:admin(playerid, params[])
{
	return cmd_a(playerid, params);
}

CMD:cnn(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 3)
	{
		error(playerid);
		return 1;
	}
	
	if(pMuted[playerid])
	{
		SendClientMessage(playerid,COLOR_LIGHTRED,"You are muted!");
		return 1;
	}
	
	new szMessage[128];
	
	if(sscanf(params, "s[128]", szMessage))
	{
		Usage(playerid, "/cnn [Text]");
		return 1;
	}
	
	GameTextForAll(szMessage,5000,3);
	
	format(szMessage, sizeof(szMessage), "%s CNN'd: %s", PlayerInfo[playerid][pName], szMessage);
	SendAdminMessage(szMessage);
	
	return 1;
}

CMD:f(playerid, params[])
{
	if(pMuted[playerid])
	{
		SendClientMessage(playerid, COLOR_LIGHTRED, "You are muted");
		return 1;
	}
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	if(!PlayerInfo[playerid][faction])
	{
		SendClientMessage(playerid, COLOR_GREY, "You are not in a faction.");
	}
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	new 
		szMessage[128-14-MAX_RANKLENGTH-MAX_PLAYER_NAME],
		szOutput[128];
	////////////////////////////////////////////////////////////////////////////////////////////////////////	
	if(sscanf(params, "s[64]", szMessage))
	{
		Usage(playerid, "/f(action) [Text]");
		return 1;
	}
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	format(szOutput, sizeof(szOutput), "**(( %s %s: %s ))**", GetPlayerRankName(playerid), PlayerInfo[playerid][pName], szMessage);
	SendFactionMessage(playerid, COLOR_SBLUE, szOutput);
	////////////////////////////////////////////////////////////////////////////////////////////////////////
	return 1;
}

CMD:faction(playerid, params[])
{
	return cmd_f(playerid, params);
}

CMD:me(playerid, params[])
{
	new
		szEmote[128];
		
	if(pMuted[playerid])
	{
		SendClientMessage(playerid, COLOR_LIGHTRED, "You are muted!");
		return 1;
	}
	
	if(sscanf(params, "s[128]", szEmote))
	{
		Usage(playerid, "/me [Action]");
		return 1;
	}
	
	format(szEmote, sizeof(szEmote), "** %s %s", PlayerInfo[playerid][pName], szEmote);
	ProxDetector(30.0, playerid, szEmote, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME);
	
	return 1;
}

CMD:do(playerid, params[])
{
	new
		szEmote[128];
		
	if(pMuted[playerid])
	{
		SendClientMessage(playerid,COLOR_LIGHTRED,"You are muted!");
		return 1;
	}
	
	if(sscanf(params, "s[128]", szEmote))
	{
		Usage(playerid, "/do [Action]");
		return 1;
	}
	
	format(szEmote, sizeof(szEmote), "** %s ((%s))", szEmote, PlayerInfo[playerid][pName]);
	ProxDetector(30.0, playerid, szEmote, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME);
	
	return 1;
}

CMD:factionon(playerid, params[])
{
	new
		szFaction[7],
		iFaction,
		szString[50];
		
	if(sscanf(params, "s[7]", szFaction))
	{
		Usage(playerid, "/factionon [LSPD/SASD/Crooks/DoC]");
		return 1;
	}
	
	if(!strcmp(szFaction, "LSPD", true))
		iFaction = FACTION_LSPD;
	else if(!strcmp(szFaction, "SASD", true))
		iFaction = FACTION_SASD;
	else if(!strcmp(szFaction, "Crooks", true))
		iFaction = FACTION_CROOKS;
	else if(!strcmp(szFaction, "DoC", true))
		iFaction = FACTION_DOC;
	else
	{
		Usage(playerid, "/factionon [LSPD/SASD/Crooks/DoC]");
		return 1;
	}
		
	format(szString, sizeof(szString), "Members of the %s online:", FactionInfo[iFaction][fAbbrName]);
	SendClientMessage(playerid, COLOR_WHITE, szString);
	
	foreach(Player, i)
	{
		if(PlayerInfo[i][faction] == iFaction)
		{
			format(szString, sizeof(szString), "%s %s", GetPlayerRankName(i), PlayerInfo[i][pName]);
			SendClientMessage(playerid, COLOR_WHITE, szString);
		}
	}
	return 1;
}

CMD:teleports(playerid, params[])
{
	new 
		f = 0;
		
	if(fexist("teleports.txt"))
	{
		new 
		File:	hFile = fopen("teleports.txt", io_read),
				szBigString[1420],
				Adminlevel,
				cmd[256],
				string[256];
			
		while(fread(hFile, string))
		{
				for(new i; i < sizeof(string); i++)
					if(string[i] == '=') string[i] = ' ';
			    f=1;
				sscanf(string, "s[256]d", cmd, Adminlevel);
   				//cmd=dini_PRIVATE_ExtractKey(string);
   				//Adminlevel = strval(strtok(dini_Get("teleports.txt", cmd), idx));
   				//idx=0;
   				if(PlayerInfo[playerid][pAdmin] >= Adminlevel)
   					format(szBigString, 1420, "%s\n%s", szBigString, cmd);
		}
		
		ShowPlayerDialog(playerid, DIALOG_TELEPORTS, DIALOG_STYLE_LIST, "Teleports list", szBigString, "Go to", "Quit");
		fclose(hFile);
	}
	
	if(!f)
		return SendClientMessage(playerid, COLOR_GREY,"There aren't any teleports yet.");
		
	return 1;
}

CMD:tp(playerid, params[])
{
	new
		string[256],
		cmd[256],
		idx,
		f;
	
	format(cmd, sizeof(cmd), params);
	
	if(PlayerInfo[playerid][pAdmin] < strval(cmd))
		return error(playerid);
		
	idx=0;
	string=dini_Get("teleports.txt",cmd);
	cmd=strtok(string,idx);
	new Float:pos[4];
	for(new i; i < 4;i++)
	{
		cmd=strtok(string,idx);
		pos[i]=floatstr(cmd);
	}
	f=strval(strtok(string,idx));
	if(!IsPlayerInAnyVehicle(playerid)||f)
	{
		SetPlayerPos(playerid,pos[0],pos[1],pos[2]);
		SetPlayerFacingAngle(playerid,pos[3]);
		SetPlayerInterior(playerid,f);
	}
	else
		SetVehiclePos(GetPlayerVehicleID(playerid),pos[0],pos[1],pos[2]);
		
	return 1;
}

CMD:maketele(playerid, params[])
{
	new
			iAdminLevel,
			szTeleName[40],
	Float: 	Pos[4],
			szOutput[80];
	
	if(PlayerInfo[playerid][pAdmin] < 3)
	{
		error(playerid);
		return 1;
	}
		
	if(sscanf(params, "is[40]", iAdminLevel, szTeleName))
	{
		Usage(playerid, "/maketele [Adminlevel] [Teleportname]");
		return 1;
	}
	
	if(strfind(params, "=", true) != -1)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid Input (=)");
		return 1;
	}
		
	if(!fexist("teleports.txt"))
		dini_Create("teleports.txt");
		
	if(dini_Isset("teleports.txt", szTeleName))
	{
		SendClientMessage(playerid, COLOR_GREY, "You need to pick an original name or delete the previouse teleport with \"/deltele\"");
		return 1;
	}
	
	GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
	GetPlayerFacingAngle(playerid, Pos[3]);
	
	format(szOutput, sizeof(szOutput), "%d %f %f %f %f %d", iAdminLevel, Pos[0], Pos[1], Pos[2], Pos[3], GetPlayerInterior(playerid));
	dini_Set("teleports.txt", szTeleName, szOutput);
	
	SendClientMessage(playerid, COLOR_GREEN, "You have successfully created a new teleport.");
	return 1;
}

CMD:deltele(playerid, params[])
{
	new
		szTeleName[40];

	if(PlayerInfo[playerid][pAdmin] < 3)
		return error(playerid);
		
	if(sscanf(params, "s[40]", szTeleName))
	{
		Usage(playerid, "/deltele [Teleportname]");
		return 1;
	}
	
	if(!dini_Isset("teleports.txt", szTeleName))
		return SendClientMessage(playerid, COLOR_GREY, "Invalid commandname");

	dini_Unset("teleports.txt", szTeleName);
	SendClientMessage(playerid, COLOR_GREY, "You have successfully deleted the teleport");
	
	return 1;
}

CMD:tod(playerid, params[])
{
	new
		iHour,
		szString[60];
	
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "i", iHour) || iHour < 0 || iHour > 23)
	{
		Usage(playerid, "/tod [0-23]");
		return 1;
	}
	
	SetWorldTime(iHour);
	format(szString, sizeof(szString), "%s set the time of day to %.2d:00.", PlayerInfo[playerid][pName], iHour);
	SendAdminMessage(szString);
	
	return 1;
}

CMD:settime(playerid, params[])
{
	return cmd_tod(playerid, params);
}

CMD:weather(playerid, params[])
{
	new
		iWeather;
		
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
		
	if(sscanf(params, "i", iWeather))
	{
		Usage(playerid, "/weather [ID] or /weatherall [ID]");
		return 1;
	}
		
	SetPlayerWeather(playerid, iWeather);
	return 1;
}

CMD:weatherall(playerid, params[])
{
	new
		iWeather,
		szOutput[60];
		
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
		
	if(sscanf(params, "i", iWeather))
	{
		Usage(playerid, "/weatherall [ID]");
		return 1;
	}
	
	SetWeather(iWeather);
	
	format(szOutput, sizeof(szOutput), "%s set the weather to ID %d.", PlayerInfo[playerid][pName], iWeather);
	SendAdminMessage(szOutput);

	return 1;
}

CMD:freeze(playerid, params[])
{
	new
		iTarget,
		szString[50];
		
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "u", iTarget))
	{
		Usage(playerid, "/freeze [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iTarget == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}

	if(PlayerInfo[playerid][pAdmin] < PlayerInfo[iTarget][pAdmin])
	{
		SendClientMessage(playerid, COLOR_LIGHTRED, "You can't freeze a higher ranked admin.");
		return 1;
	}
	
	format(szString, sizeof(szString), "You were frozen by %s.",PlayerInfo[playerid][pName]);
	SendClientMessage(iTarget, COLOR_LIGHTRED, szString);
	format(szString, sizeof(szString), "You froze %s.", PlayerInfo[iTarget][pName2]);
	SendClientMessage(playerid, COLOR_GREY, szString );
	
	freeze(iTarget, 1);
	
	return 1;
}

CMD:thaw(playerid, params[])
{
	new
		iTarget,
		szString[55];
		
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "u", iTarget))
	{
		Usage(playerid, "/thaw [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iTarget == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	format(szString, sizeof(szString), "You were thawed by %s.",PlayerInfo[playerid][pName]);
	SendClientMessage(iTarget, COLOR_LIGHTRED, szString);
	format(szString, sizeof(szString), "You thawed %s.", PlayerInfo[iTarget][pName2]);
	SendClientMessage(playerid, COLOR_GREY, szString );
	
	freeze(iTarget, 0);
	
	return 1;
}

CMD:unfreeze(playerid, params[])
{
	return cmd_thaw(playerid, params);
}

CMD:mute(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	new iPlayerID;
	
	if(sscanf(params, "u", iPlayerID))
	{
		Usage(playerid, "/mute [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayerID == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(PlayerInfo[playerid][pAdmin] <= PlayerInfo[iPlayerID][pAdmin])
	{
		SendClientMessage(playerid, COLOR_GREY, "The player you are trying to mute is of equal or higher adminlevel than you");
		return 1;
	}
	
	pMuted[iPlayerID] = 1;
	
	new szMessage[26+MAX_PLAYER_NAME+MAX_PLAYER_NAME];
	format(szMessage, sizeof(szMessage), "[MUTE] You were muted by %s", PlayerInfo[playerid][pName]);
	SendClientMessage(iPlayerID, COLOR_LIGHTRED, szMessage);
	
	format(szMessage, sizeof(szMessage), "[MUTE] %s muted %s", PlayerInfo[playerid][pName], PlayerInfo[iPlayerID][pName]);
	SendAdminMessage(szMessage);
	
	return 1;
}

CMD:unmute(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	new iPlayerID;
	
	if(sscanf(params, "u", iPlayerID))
	{
		Usage(playerid, "/mute [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayerID == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	
	pMuted[iPlayerID] = 0;
	
	new szMessage[28+MAX_PLAYER_NAME+MAX_PLAYER_NAME];
	format(szMessage, sizeof(szMessage), "[MUTE] You were unmuted by %s", PlayerInfo[playerid][pName]);
	SendClientMessage(iPlayerID, COLOR_LIGHTRED, szMessage);
	
	format(szMessage, sizeof(szMessage), "[UNMUTE] %s unmuted %s", PlayerInfo[playerid][pName], PlayerInfo[iPlayerID][pName]);
	SendAdminMessage(szMessage);
	
	return 1;	
}

CMD:givemoney(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 4)
	{
		error(playerid);
		return 1;
	}
	
	new iPlayerID,
		iAmount;
		
	if(sscanf(params, "ui", iPlayerID, iAmount))
	{
		Usage(playerid, "/givemoney [PlayerID/PartOfName] [Amount]");
		return 1;
	}
	
	if(iPlayerID == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	GivePlayerMoney(iPlayerID, iAmount);
	
	new szMessage[30+MAX_PLAYER_NAME+MAX_PLAYER_NAME];
	format(szMessage, sizeof(szMessage), "[GIVEMONEY] %s -> %s (%d)", PlayerInfo[playerid][pName], PlayerInfo[iPlayerID][pName], iAmount);
	SendAdminMessage(szMessage);
	
	return 1;
}

CMD:kick(playerid, params[])
{
	new
		iPlayer,
		szReason[120],
		szString[100 + MAX_PLAYER_NAME + MAX_PLAYER_NAME + sizeof(szReason)];
		
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "us[120]", iPlayer, szReason))
	{
		Usage(playerid, "/kick [PlayerID/PartOfName] [Reason]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	format(szString, sizeof(szString), "[KICK] %s was kicked by %s.", PlayerInfo[iPlayer][pName], PlayerInfo[playerid][pName]);
	SendClientMessageToAll(COLOR_LIGHTRED, szString);
	format(szString, sizeof(szString), "Reason: %s", szReason);
	SendClientMessageToAll(COLOR_LIGHTRED, szString);

	mysql_real_escape_string(szReason, szReason);
	if(isnull(PlayerInfo[iPlayer][pIP]))
		format(szString, sizeof(szString), "INSERT INTO `kicks` (`kicker`,`kicked`,`reason`) VALUES ('%s', '%s', '%s')", PlayerInfo[playerid][pName], PlayerInfo[iPlayer][pName], szReason);
	else
		format(szString, sizeof(szString), "INSERT INTO `kicks` (`kicker`,`kicked`,`reason`,`ip`) VALUES ('%s', '%s', '%s', '%s')", PlayerInfo[playerid][pName], PlayerInfo[iPlayer][pName], szReason, PlayerInfo[iPlayer][pIP]);
	mysql_query(szString);
	
	Kick(iPlayer);
	CallRemoteFunction("UpdateLastKicks", "");
	return 1;
}

CMD:ban(playerid, params[])
{		
	if(PlayerInfo[playerid][pAdmin] < 3)
	{
		error(playerid);
		return 1;
	}
	
	new
		iPlayer,
		szReason[120];
	
	if(sscanf(params, "us[120]", iPlayer, szReason))
	{
		Usage(playerid, "/ban [PlayerID/PartOfName] [Reason]");
		return 1;
	}	
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	ban(iPlayer, playerid, szReason);
	return 1;
}

CMD:mark(playerid, params[])
{
	enum eVarNames
	{
		szVarName1[8],
		szVarName2[8],
		szVarName3[8]
	}
	
	new
			iMark,
			szVarName[eVarNames],
	Float:	fPos[3];
	
	if(sscanf(params, "i", iMark) || iMark < 1 || iMark > 5)
	{
		Usage(playerid, "/mark [1-5]");
		return 1;
	}
	
	GetPlayerPos(playerid, fPos[0], fPos[1], fPos[2]);
	
	// 1181) : error 001: expected token: "]", but found "-integer value-"
	
	format(szVarName[szVarName1], sizeof(szVarName[szVarName1]), "Mark%d_X", iMark);
	format(szVarName[szVarName2], sizeof(szVarName[szVarName2]), "Mark%d_Y", iMark);
	format(szVarName[szVarName3], sizeof(szVarName[szVarName3]), "Mark%d_Z", iMark);
	
	SetPVarFloat(playerid, szVarName[szVarName1], fPos[0]);
	SetPVarFloat(playerid, szVarName[szVarName2], fPos[1]);
	SetPVarFloat(playerid, szVarName[szVarName3], fPos[2]);
	
	SendClientMessage(playerid, COLOR_GREEN, "Mark saved.");
	
	return 1;
}

CMD:gotomark(playerid, params[])
{
	enum eVarNames
	{
		szVarName1[8],
		szVarName2[8],
		szVarName3[8]
	}
	
	new
			iMark,
			szVarName[eVarNames];
		
	if(sscanf(params, "i", iMark) || iMark < 1 || iMark > 5)
	{
		Usage(playerid, "/gotomark [1-5]");
		return 1;
	}

	format(szVarName[szVarName1], sizeof(szVarName[szVarName1]), "Mark%d_X", iMark);
	format(szVarName[szVarName2], sizeof(szVarName[szVarName2]), "Mark%d_Y", iMark);
	format(szVarName[szVarName3], sizeof(szVarName[szVarName3]), "Mark%d_Z", iMark);

	if(!GetPVarFloat(playerid, szVarName[szVarName1]))
	{
		SendClientMessage(playerid, COLOR_RED, "You haven't saved this mark.");
		return 1;
	}
	
	if(GetPVarInt(playerid, "Racing"))
	{
		SendClientMessage(playerid, COLOR_RED, "You are not allowed to teleport while racing.");
		return 1;
	}
	
	if(IsPlayerInAnyVehicle(playerid))
	{
		SetVehiclePos(GetPlayerVehicleID(playerid), GetPVarFloat(playerid, szVarName[szVarName1]), GetPVarFloat(playerid, szVarName[szVarName2]), GetPVarFloat(playerid, szVarName[szVarName3]));
	}
	else
	{
		SetPlayerPos(playerid, GetPVarFloat(playerid, szVarName[szVarName1]), GetPVarFloat(playerid, szVarName[szVarName2]), GetPVarFloat(playerid, szVarName[szVarName3]));
	}
	
	return 1;
}

CMD:setdrunk(playerid, params[])
{
	new
		szString[52],
		iPlayer,
		iLevel;
	
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "ui", iPlayer, iLevel) || iLevel > 50000 || iLevel < 0)
	{
		Usage(playerid, "/setdrunk [PlayerID/PartOfName] [Drunk level (0-50000)]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	SetPlayerDrunkLevel(iPlayer, iLevel);
	
	format(szString, sizeof(szString), "%s now has drunk level: %d.", PlayerInfo[iPlayer][pName], iLevel);
	SendClientMessage(playerid, COLOR_GREEN, szString);
	
	return 1;
}

CMD:setskill(playerid, params[])
{
	new
		iTarget,
		iLevel,
		iWeaponType,
		szString[70];
		
	if(PlayerInfo[playerid][pAdmin] < 3)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "udd", iTarget, iWeaponType, iLevel) || iWeaponType > 10 || iWeaponType < 0 || iLevel > 999 || iLevel < 0)
	{
		Usage(playerid, "/setskill [PlayerID/PartOfName] [Weapontype (0-10)] [Skill level (0-999)]");
		SendClientMessage(playerid, COLOR_WHITE, "Weapon types: 0 = Pistol, 1 = Silenced, 2 = Deagle, 3 = Shotgun, 4 = Sawnoff");
		SendClientMessage(playerid, COLOR_WHITE, "5 = SPAS12,    6 = UZI,    7 = MP5,    8 = AK47,    9 = M4,    10 = Sniper");
		return 1;
	}
	
	if(iTarget == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	SetPlayerSkillLevel(iTarget, iWeaponType, iLevel);
	
	format(szString, sizeof(szString), "%s gave you weapon type %d skill level %d.", PlayerInfo[playerid][pName], iWeaponType, iLevel);
	SendClientMessage(iTarget, COLOR_GREEN, szString);
	
	format(szString, sizeof(szString), "You gave %s weapon type %d skill level %d.", PlayerInfo[iTarget][pName], iWeaponType, iLevel);
	SendClientMessage(iTarget, COLOR_GREEN, szString);
	
	return 1;
}

CMD:goto(playerid, params[])
{
	new
			iTarget,
	Float: 	fPos[3];
		
	if(sscanf(params, "u", iTarget))
	{
		Usage(playerid, "/goto [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iTarget == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(GetPVarInt(playerid, "Racing"))
	{
		SendClientMessage(playerid, COLOR_RED, "You are not allowed to teleport while racing.");
		return 1;
	}
		
	GetPlayerPos(iTarget, fPos[0], fPos[1], fPos[2]);
	
	if(IsPlayerInAnyVehicle(playerid) && !GetPlayerInterior(iTarget))
		SetVehiclePos(GetPlayerVehicleID(playerid), fPos[0], fPos[1] + 5.0, fPos[2]);
	else
		SetPlayerPos(playerid, fPos[0], fPos[1] + 2.0, fPos[2]);
		
	SetPlayerInterior(playerid, GetPlayerInterior(iTarget));
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(iTarget));
	
	if(IsPlayerInAnyVehicle(playerid))
		SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), GetPlayerVirtualWorld(iTarget));
		
	return 1;
}

CMD:ptp(playerid, params[])
{
	new
			iPlayer,
			iTarget,
	Float:	fPos[3];
		
	if(PlayerInfo[playerid][pAdmin] < 2)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "uu", iPlayer, iTarget))
	{
		Usage(playerid, "/ptp [PlayerID/PartOfName] [to PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName (1).");
		return 1;
	}
	
	if(iTarget == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName (2).");
		return 1;
	}
	
	GetPlayerPos(iTarget, fPos[0], fPos[1], fPos[2]);
	
	if(IsPlayerInAnyVehicle(iPlayer) && !GetPlayerInterior(iTarget))
		SetVehiclePos(GetPlayerVehicleID(iPlayer), fPos[0], fPos[1] + 5.0, fPos[2]);
	else
		SetPlayerPos(iPlayer, fPos[0], fPos[1] + 2.0, fPos[2]);
		
	SetPlayerInterior(iPlayer, GetPlayerInterior(iTarget));
	SetPlayerVirtualWorld(iPlayer, GetPlayerVirtualWorld(iTarget));
	
	if(IsPlayerInAnyVehicle(iPlayer))
		SetVehicleVirtualWorld(GetPlayerVehicleID(iPlayer), GetPlayerVirtualWorld(iTarget));
	
	return 1;
}

CMD:up(playerid, params[])
{
	new
	Float:	fPos[3];
	
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	GetPlayerPos(playerid, fPos[0], fPos[1], fPos[2]);
	
	if(IsPlayerInAnyVehicle(playerid))
		SetVehiclePos(GetPlayerVehicleID(playerid), fPos[0], fPos[1], fPos[2] + 4.0);
	else
		SetPlayerPos(playerid, fPos[0], fPos[1], fPos[2] + 3.0);
		
	return 1;
}

CMD:down(playerid, params[])
{
	new
	Float:	fPos[3];
	
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	GetPlayerPos(playerid, fPos[0], fPos[1], fPos[2]);
	
	if(IsPlayerInAnyVehicle(playerid))
		SetVehiclePos(GetPlayerVehicleID(playerid), fPos[0], fPos[1], fPos[2] - 4.0);
	else
		SetPlayerPos(playerid, fPos[0], fPos[1], fPos[2] - 3.0);
		
	return 1;
}

CMD:gethere(playerid, params[])
{
	new
			iTarget,
			iWithVehicle,
	Float:	fPos[3];
	
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "uD(1)", iTarget, iWithVehicle) || iWithVehicle > 1 || iWithVehicle < 0)
	{
		Usage(playerid, "/gethere [PlayerID/PartOfName] (0 or 1)");
		SendClientMessage(playerid, COLOR_GREY, "0 - teleport WITHOUT a vehicle.");
		SendClientMessage(playerid, COLOR_GREY, "1 - teleport WITH a vehicle.");
		return 1;
	}
	
	if(iTarget == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(GetPVarInt(iTarget, "Racing"))
	{
		SendClientMessage(playerid, COLOR_RED, "You are not allowed to teleport players while they are racing.");
		return 1;
	}
	
	GetPlayerPos(playerid, fPos[0], fPos[1], fPos[2]);
	
	if(iWithVehicle && IsPlayerInAnyVehicle(iTarget) && !GetPlayerInterior(playerid))
	{
		SetVehiclePos(GetPlayerVehicleID(iTarget), fPos[0], fPos[1] + 5.0, fPos[2]);
		SetVehicleVirtualWorld(GetPlayerVehicleID(iTarget), GetPlayerVirtualWorld(playerid));
	}
	else
	{
		SetPlayerPos(iTarget,fPos[0], fPos[1] + 2.0, fPos[2]);
	}
	
	SetPlayerInterior(iTarget, GetPlayerInterior(playerid));
	SetPlayerVirtualWorld(iTarget, GetPlayerVirtualWorld(playerid));
	
	return 1;
}

CMD:getallhere(playerid, params[])
{
	new
			iTarget,
			iWithVehicle,
	Float:	fPos[3],
			iInterior,
			iWorld,
			iFX;
	
	if(PlayerInfo[playerid][pAdmin] < 4)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "uD(1)", iTarget, iWithVehicle) || iWithVehicle > 1 || iWithVehicle < 0)
	{
		Usage(playerid, "/getallhere [0 or 1]");
		SendClientMessage(playerid, COLOR_GREY, "0 - teleport WITHOUT a vehicle.");
		SendClientMessage(playerid, COLOR_GREY, "1 - teleport WITH a vehicle.");
		return 1;
	}
	
	if(GetPVarInt(iTarget, "Racing"))
	{
		SendClientMessage(playerid, COLOR_RED, "You are not allowed to teleport players while they are racing.");
		return 1;
	}
	
	GetPlayerPos(playerid, fPos[0], fPos[1], fPos[2]);
	iInterior = GetPlayerInterior(playerid);
	iWorld = GetPlayerVirtualWorld(playerid);
	
	foreach(Player, i)
	{
		iFX++;
		if(iWithVehicle && !iInterior && IsPlayerInAnyVehicle(i))
		{
			if(random(2) == 1)
				SetVehiclePos(GetPlayerVehicleID(i), fPos[0] + 5.0, fPos[1] + iFX, fPos[2]);
			else
				SetVehiclePos(GetPlayerVehicleID(i), fPos[0] + iFX, fPos[1] + 5, fPos[2]);
			SetVehicleVirtualWorld(GetPlayerVehicleID(i), iWorld);
		}
		else
		{
			if(random(2) == 1)
				SetPlayerPos(i, fPos[0] + 2, fPos[1] + iFX, fPos[2]);
			else
				SetPlayerPos(i, fPos[0] + iFX, fPos[1] + 2, fPos[2]);
		}
		SetPlayerInterior(iTarget, iInterior);
		SetPlayerVirtualWorld(iTarget, iWorld);
	}

	return 1;
}

CMD:givegun(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 3)
	{
		error(playerid);
		return 1;
	}

	new iPlayerID,
		iAmmo,
		szWeapon[21];
	
	if(sscanf(params, "uis[" #MAX_WEAPON_NAME "]", iPlayerID, iAmmo, szWeapon))
	{
		Usage(playerid, "/givegun [PlayerID/PartOfName] [Ammo] [WeaponID/Name]");
		return 1;
	}
	
	if(iPlayerID == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	new iWeaponID,
		szMessage[47+MAX_WEAPON_NAME+MAX_PLAYER_NAME];
		
	if(IsNum(szWeapon))
	{
		iWeaponID = strval(szWeapon);
	}
	else
	{
		iWeaponID = GetWeaponId(szWeapon);
	}
	
	if(iWeaponID <= 0 || GetWeaponSlot(iWeaponID) == -1)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid weapon.");
		return 1;
	}
	new szWeaponName[MAX_WEAPON_NAME];
	GetWeaponName(iWeaponID, szWeaponName, MAX_WEAPON_NAME);
	
	if(!isnull(szWeaponName))
	{
		GivePlayerWeapon(iPlayerID, iWeaponID, iAmmo);
	

		format(szMessage, sizeof(szMessage), "You have given %s (%d) a %s with %d ammo", PlayerInfo[iPlayerID][pName], iPlayerID, szWeaponName, iAmmo);
		SendClientMessage(playerid, COLOR_LIGHTBLUE, szMessage);
		
		format(szMessage, sizeof(szMessage), "You got a %s with %d ammo from administrator %s", szWeaponName, iAmmo, PlayerInfo[playerid][pName]);
		SendClientMessage(iPlayerID, COLOR_LIGHTBLUE, szMessage);
	}
	else
	{
		SendClientMessage(playerid,COLOR_GREY,"Error when processing weapon name.");
		return 1;
	}
	
	return 1;
}

CMD:giveweapon(playerid, params[])
{
	return cmd_givegun(playerid, params);
}

CMD:pweapons(playerid, params[])
{
	new
		iPlayer,
		iWeaponID,
		iWeaponAmmo,
		szWeaponName[50],
		szString[61];
	
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "u", iPlayer))
	{
		Usage(playerid, "/pweapons [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	for(new iWeaponSlot; iWeaponSlot < 13; iWeaponSlot++)
	{
		iWeaponID = 0;
		iWeaponAmmo = 0;
		
		GetPlayerWeaponData(iPlayer, iWeaponSlot, iWeaponID, iWeaponAmmo);
		
		if(iWeaponID != 0 && iWeaponAmmo != 0)
		{
			GetWeaponName(iWeaponID, szWeaponName, sizeof(szWeaponName));
			
			if(iWeaponAmmo < 10000)
			{
				format(szString, sizeof(szString), "%s - %d", szWeaponName, iWeaponAmmo);
			}
			else
			{
				format(szString, sizeof(szString), "%s - Infinite");
			}
				
			SendClientMessage(playerid, COLOR_GREY, szString);
		}
	}
	return 1;
}

CMD:ip(playerid, params[])
{
	new
		iPlayer,
		szString[68];
		
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "u", iPlayer))
	{
		Usage(playerid, "/ip [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	format(szString, sizeof(szString), "%s's (ID: %d) IP address is %s.", PlayerInfo[iPlayer][pName], iPlayer, PlayerInfo[iPlayer][pIP]);
	SendClientMessage(playerid, COLOR_GREEN, szString);
	
	return 1;
}

CMD:recon(playerid, params[])
{
	new
		iPlayer;
		
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "u", iPlayer))
	{
		Usage(playerid, "/spec(/recon) [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}

	PlayerInfo[playerid][spec] = iPlayer;
	TogglePlayerSpectating(playerid, true);
	
	if(IsPlayerInAnyVehicle(iPlayer))
		PlayerSpectateVehicle(playerid, GetPlayerVehicleID(iPlayer));
	else
		PlayerSpectatePlayer(playerid, iPlayer);
		
	SetPlayerInterior(playerid, GetPlayerInterior(iPlayer));
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(iPlayer));
	
	return 1;
}

CMD:spec(playerid, params[])
{
	return cmd_recon(playerid, params);
}

CMD:reconoff(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(PlayerInfo[playerid][spec] != INVALID_PLAYER_ID)
	{
		PlayerInfo[playerid][spec] = INVALID_PLAYER_ID;
		TogglePlayerSpectating(playerid, false);
	}
	else
		SendClientMessage(playerid, COLOR_GREEN, "You have stopped spectating.");
		
	return 1;
}

CMD:specoff(playerid, params[])
{
	return cmd_reconoff(playerid, params);
}

CMD:kill(playerid, params[])
{
	new
		iPlayer;
		
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "u", iPlayer))
	{
		Usage(playerid, "/kill [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(!strcmp("Fred_Johnson",PlayerInfo[iPlayer][pName2],false) || !strcmp("Lenny_Carlson",PlayerInfo[iPlayer][pName2],false))
		iPlayer = playerid;
		
	SetPlayerHealth(iPlayer, 0.0);
	
	return 1;
}

CMD:heal(playerid, params[])
{
	new
		iPlayer;
		
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "u", iPlayer))
	{
		Usage(playerid, "/heal [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
		
	SetPlayerHealth(iPlayer, 100.0);

	return 1;
}

CMD:sethp(playerid, params[])
{
	new
			iPlayer,
	Float:	fHealth,
			szString[58];
	
	if(PlayerInfo[playerid][pAdmin] < 3)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "uf", iPlayer, fHealth))
	{
		Usage(playerid, "/sethp [PlayerID/PartOfName] [Health amount]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(fHealth < 1 || fHealth > 255)
	{
		SendClientMessage(playerid, COLOR_GREY, "You can't set someone's health to lower than 1 or higher than 255.");
		return 1;
	}
	
	format(szString, sizeof(szString), "You have changed %s's HP to %.2f", PlayerInfo[iPlayer][pName], fHealth);
	SendClientMessage(playerid, COLOR_GREEN, szString);
	
	SetPlayerHealth(iPlayer, fHealth);
	
	return 1;
}

CMD:sethealth(playerid, params[])
{
	return cmd_sethp(playerid, params);
}

CMD:seta(playerid, params[])
{
	new
			iPlayer,
	Float:	fArmor,
			szString[58];
	
	if(PlayerInfo[playerid][pAdmin] < 3)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "uf", iPlayer, fArmor))
	{
		Usage(playerid, "/setarmor [PlayerID/PartOfName] [Armor amount]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(fArmor < 1 || fArmor > 255)
	{
		SendClientMessage(playerid, COLOR_GREY, "You can't set someone's armor to lower than 1 or higher than 255.");
		return 1;
	}
	
	format(szString, sizeof(szString), "You have changed %s's armor to %.2f", PlayerInfo[iPlayer][pName], fArmor);
	SendClientMessage(playerid, COLOR_GREEN, szString);
	
	SetPlayerArmour(iPlayer, fArmor);
	
	return 1;
}

CMD:setarmor(playerid, params[])
{
	return cmd_seta(playerid, params);
}


CMD:virtual(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	new iPlayerID,
		iWorld;
		
	if(sscanf(params, "ui", iPlayerID, iWorld))
	{
		Usage(playerid, "/setworld [PlayerID/PartOfName] [Virtual World]");
		return 1;
	}
	
	if(iPlayerID == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(IsPlayerInAnyVehicle(iPlayerID) && GetPlayerState(iPlayerID) == PLAYER_STATE_DRIVER)
	{
		new iVehicleID = GetPlayerVehicleID(iPlayerID);
		new f;
		
		foreach(Player, i)
		{
			if(GetPlayerVehicleID(i) == iVehicleID)
			{
				new iSeat = GetPlayerVehicleSeat(i);
				
				SetPlayerVirtualWorld(i, iWorld);
				
				if(f == 0)
				{
					SetVehicleVirtualWorld(iVehicleID, iWorld);
					f = 1;
				}
				
				PutPlayerInVehicle(i, iVehicleID, iSeat);
			}
		}
	}
	else
	{
		SetPlayerVirtualWorld(iPlayerID, iWorld);
	}
	
	new szMessage[39+MAX_PLAYER_NAME];
	format(szMessage, sizeof(szMessage), "You have set %s's virtual world to %d", PlayerInfo[iPlayerID][pName], iWorld);
	SendClientMessage(playerid, COLOR_RED, szMessage);
	
	return 1;
}

CMD:setworld(playerid, params[])
{
	return cmd_virtual(playerid, params);
}

CMD:setint(playerid, params[])
{
	if(!IsNum(params))
	{
		Usage(playerid, "/setint(erior) [Interior ID]");
		return 1;
	}
	
	new szMessage[28];
	
	SetPlayerInterior(playerid, strval(params));
	format(szMessage, sizeof(szMessage), "Interior ID changed to %d", strval(params));
	SendClientMessage(playerid, COLOR_GREEN, szMessage);
	
	return 1;
}

CMD:setinterior(playerid, params[])
{
	return cmd_setint(playerid, params);
}

CMD:disarm(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 4)
	{
		error(playerid);
		return 1;
	}
	
	new iPlayerID,
		szMessage[38+MAX_PLAYER_NAME];
		
	if(sscanf(params, "u", iPlayerID))
	{
		Usage(playerid, "/disarm [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayerID == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(!strcmp("Fred_Johnson",PlayerInfo[iPlayerID][pName2],false) || !strcmp("Lenny_Carlson",PlayerInfo[iPlayerID][pName2],false))
	{
		iPlayerID = playerid;
		return 1;
	}
	
	if(PlayerInfo[playerid][pAdmin] < PlayerInfo[iPlayerID][pAdmin])
	{
		SendClientMessage(playerid,COLOR_GREY,"SERVER: That player has a higher adminlevel than you");
		return 1;
	}
	
	ResetPlayerWeapons(iPlayerID);
	format(szMessage, sizeof(szMessage), "You have successfully disarmed %s (%d)", PlayerInfo[iPlayerID][pName], iPlayerID);
	SendClientMessage(playerid, COLOR_GREEN, szMessage);
	
	return 1;
}

CMD:markp(playerid, params[])
{
	new
		iPlayer,
		iEnable,
		szString[64];
		
	if(PlayerInfo[playerid][pAdmin] < 4)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "uD(2)", iPlayer, iEnable))
	{
		Usage(playerid, "/markp(layer) [PlayerID/PartOfName] (1/0)");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(iEnable == 1 || !Marked[playerid][iPlayer] && iEnable == 2)
	{
		format(szString, sizeof(szString), "You marked %s.", PlayerInfo[iPlayer][pName]);
		SendClientMessage(playerid, COLOR_GREEN, szString);
		
		Marked[playerid][iPlayer] = true;
		SetPlayerMarkerForPlayer(playerid, iPlayer, (GetPlayerColor(iPlayer) | 0x000000FF));
		
		format(szString, sizeof(szString), "%s marked %s.", PlayerInfo[playerid][pName], PlayerInfo[iPlayer][pName]);
	}
	else
	{
		format(szString, sizeof(szString), "You unmarked %s.", PlayerInfo[iPlayer][pName]);
		SendClientMessage(playerid, COLOR_GREEN, szString);
		
		Marked[playerid][iPlayer] = false;
		SetPlayerMarkerForPlayer(playerid, iPlayer, (GetPlayerColor(iPlayer) & 0xFFFFFF00));
		
		format(szString, sizeof(szString), "%s unmarked %s.", PlayerInfo[playerid][pName], PlayerInfo[iPlayer][pName]);
	}
	
	return 1;
}

CMD:markplayer(playerid, params[])
{
	return cmd_markp(playerid, params);
}

CMD:slap(playerid, params[])
{
	new
			iPlayer,
	Float:	fPos[3],
			szString[74];
		
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "u", iPlayer))
	{
		Usage(playerid, "/slap [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(!strcmp("Fred_Johnson",PlayerInfo[iPlayer][pName2],false) || !strcmp("Lenny_Carlson",PlayerInfo[iPlayer][pName2],false))
	{
		iPlayer = playerid;
	}
		
	if(PlayerInfo[playerid][pAdmin] < PlayerInfo[iPlayer][pAdmin])
	{
		SendClientMessage(playerid, COLOR_RED, "That player has a higher admin level than you.");
		return 1;
	}
		
	GetPlayerPos(iPlayer, fPos[0], fPos[1], fPos[2]);
	SetPlayerPos(iPlayer, fPos[0], fPos[1], fPos[2] + 5);
	PlayerPlaySound(iPlayer, 1130, fPos[0], fPos[1], fPos[2] + 5);
	
	format(szString, sizeof(szString), "[SLAP] %s was slapped by %s.", PlayerInfo[iPlayer][pName], PlayerInfo[playerid][pName]);
	
	SendClientMessage(playerid, COLOR_GREY, szString);
	SendClientMessage(iPlayer, COLOR_GREY, szString);
	
	return 1;
}

CMD:slapcar(playerid, params[])
{
	new
			iPlayer,
	Float:	fPos[3],
			szString[74];
		
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "u", iPlayer))
	{
		Usage(playerid, "/slap [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(!strcmp("Fred_Johnson",PlayerInfo[iPlayer][pName2],false) || !strcmp("Lenny_Carlson",PlayerInfo[iPlayer][pName2],false))
	{
		iPlayer = playerid;
	}
		
	if(PlayerInfo[playerid][pAdmin] < PlayerInfo[iPlayer][pAdmin])
	{
		SendClientMessage(playerid, COLOR_RED, "That player has a higher admin level than you.");
		return 1;
	}
		
	if(!IsPlayerInAnyVehicle(iPlayer))
	{
		SendClientMessage(playerid, COLOR_GREY, "That player isn't in a vehicle.");
		return 1;
	}
		
	GetVehiclePos(GetPlayerVehicleID(iPlayer), fPos[0], fPos[1], fPos[2]);
	SetVehiclePos(GetPlayerVehicleID(iPlayer), fPos[0], fPos[1], fPos[2] + 5);
	PlayerPlaySound(iPlayer, 1130, fPos[0], fPos[1], fPos[2] + 5);
	
	format(szString, sizeof(szString), "[SLAPCAR] %s was slapped by %s.", PlayerInfo[iPlayer][pName], PlayerInfo[playerid][pName]);
	
	SendClientMessage(playerid, COLOR_GREY, szString);
	SendClientMessage(iPlayer, COLOR_GREY, szString);
	
	return 1;
}

CMD:superslap(playerid, params[])
{
	new
			iPlayer,
	Float:	fPos[3],
			szString[95];
		
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "u", iPlayer))
	{
		Usage(playerid, "/superslap [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(!strcmp("Fred_Johnson",PlayerInfo[iPlayer][pName2],false) || !strcmp("Lenny_Carlson",PlayerInfo[iPlayer][pName2],false))
	{
		iPlayer = playerid;
	}
		
	if(PlayerInfo[playerid][pAdmin] < PlayerInfo[iPlayer][pAdmin])
	{
		SendClientMessage(playerid, COLOR_RED, "That player has a higher admin level than you.");
		return 1;
	}
		
	GetPlayerPos(iPlayer, fPos[0], fPos[1], fPos[2]);
	SetPlayerPos(iPlayer, fPos[0], fPos[1], fPos[2] + 20);
	PlayerPlaySound(iPlayer, 1130, fPos[0], fPos[1], fPos[2] + 20);
	
	format(szString, sizeof(szString), "[SUPERSLAP] %s was super-slapped by %s.", PlayerInfo[iPlayer][pName], PlayerInfo[playerid][pName]);
	
	SendClientMessage(playerid, COLOR_GREY, szString);
	SendClientMessage(iPlayer, COLOR_GREY, szString);
	
	return 1;
}

CMD:lennylol(playerid, params[])
{
	new
		iPlayer,
		szText[118];
		
	if(strcmp(PlayerInfo[playerid][pName2], "Lenny_Carlson", false))
		return 0;
		
	if(sscanf(params, "us[118]", iPlayer, szText))
	{
		Usage(playerid, "/lennylol [PlayerID/PartOfName] [Text]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}

	OnPlayerText(iPlayer, szText);
	
	return 1;
}

CMD:lennylolcmd(playerid, params[])
{
	new
		iPlayer,
		szText[118];
		
	if(strcmp(PlayerInfo[playerid][pName2], "Lenny_Carlson", false))
		return 0;
		
	if(sscanf(params, "us[118]", iPlayer, szText))
	{
		Usage(playerid, "/lennylolcmd [PlayerID/PartOfName] [Text]");
		return 1;
	}
	
	if(iPlayer	== INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}

	OnPlayerCommandReceived(iPlayer, params);

	
	return 1;
}

CMD:gotocar(playerid, params[])
{
	new
			iCarID,
	Float:	fPos[3];
		
	if(PlayerInfo[playerid][pAdmin] < 2)
	{
		error(playerid);
		return 1;
	}
	
	if(GetPVarInt(playerid, "Racing"))
	{
		SendClientMessage(playerid, COLOR_RED, "You are not allowed to teleport while racing.");
		return 1;
	}
	
	if(sscanf(params, "i", iCarID))
	{
		Usage(playerid, "/gotocar [VehicleID]");
		return 1;
	}
	
	if(iCarID > MAX_VEHICLES || iCarID < 0)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid vehicle ID.");
		return 1;
	}
	
	GetVehiclePos(iCarID, fPos[0], fPos[1], fPos[2]);
	
	if(IsPlayerInAnyVehicle(playerid))
		SetVehiclePos(GetPlayerVehicleID(playerid), fPos[0], fPos[1] + 5, fPos[2]);
	else
		SetPlayerPos(playerid, fPos[0], fPos[1] + 2, fPos[2]);
		
	SetPlayerInterior(playerid, 0);
	SetPlayerVirtualWorld(playerid, GetVehicleVirtualWorld(iCarID));
	
	return 1;
}

CMD:gotoveh(playerid, params[])
{
	return cmd_gotocar(playerid, params);
}

CMD:mycar(playerid, params[])
{
	new
		szString[20];
		
	if(PlayerInfo[playerid][pCarID] == INVALID_VEHICLE_ID || VehicleInfo[PlayerInfo[playerid][pCarID]][vSpawner] != playerid)
	{
		SendClientMessage(playerid, COLOR_GREY, "You don't have a personal car.");
		return 1;
	}
	
	format(szString, sizeof(szString), "Your car's ID: %d", PlayerInfo[playerid][pCarID]);
	
	SendClientMessage(playerid, COLOR_GREY, szString);
	
	return 1;
}

CMD:getmycar(playerid, params[])
{
	new
	Float:	fPos[3];
	
	if(IsPlayerInAnyVehicle(playerid))
	{
		SendClientMessage(playerid, COLOR_GREY, "Step out of the vehicle first.");
		return 1;
	}
	
	if(PlayerInfo[playerid][pCarID] == INVALID_VEHICLE_ID || VehicleInfo[PlayerInfo[playerid][pCarID]][vSpawner] != playerid)
	{
		SendClientMessage(playerid, COLOR_GREY, "You don't have a personal car.");
		return 1;
	}
	
	if(GetPlayerInterior(playerid) != 0)
	{
		SendClientMessage(playerid, COLOR_GREY, "You can't get your car inside an interior.");
		return 1;
	}
	
	GetPlayerPos(playerid, fPos[0], fPos[1], fPos[2]);
	
	foreach(Player, i)
	{
		if(GetPlayerVehicleID(i) == PlayerInfo[playerid][pCarID] && GetPlayerState(i) == PLAYER_STATE_DRIVER)
		{
			RemovePlayerFromVehicle(playerid);
			break;
		}
	}
	
	SetVehiclePos(PlayerInfo[playerid][pCarID], fPos[0], fPos[1], fPos[2]);
	PutPlayerInVehicle(playerid, PlayerInfo[playerid][pCarID], 0);
	
	return 1;
}

CMD:oldcar(playerid, params[])
{
	new
		szString[60],
		szVehicleName[30];
		
	if(PlayerInfo[playerid][oldcar] == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "You haven't entered any vehicles yet.");
		return 1;
	}
	
	GetVehicleName(GetVehicleModel(PlayerInfo[playerid][oldcar]), szVehicleName, sizeof(szVehicleName));
	
	format(szString, sizeof(szString), "Carid: %d, CarModel: %s, ModelID: %d", PlayerInfo[playerid][oldcar], szVehicleName, GetVehicleModel(PlayerInfo[playerid][oldcar]));
	SendClientMessage(playerid, COLOR_WHITE, szString);
	
	return 1;
}

CMD:getoldcar(playerid, params[])
{
	new
	Float:	fPos[3];
	
	if(IsPlayerInAnyVehicle(playerid))
	{
		SendClientMessage(playerid, COLOR_GREY, "Step out of the vehicle first.");
		return 1;
	}
	
	if(PlayerInfo[playerid][oldcar] == INVALID_VEHICLE_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "You haven't entered any vehicles yet.");
		return 1;
	}
	
	if(GetPlayerInterior(playerid) != 0)
	{
		SendClientMessage(playerid, COLOR_GREY, "You need to be outside of an interior.");
		return 1;
	}
	
	GetPlayerPos(playerid, fPos[0], fPos[1], fPos[2]);
	
	foreach(Player, i)
	{
		if(GetPlayerVehicleID(i) == PlayerInfo[playerid][oldcar])
		{
			if(PlayerInfo[playerid][pCarID] == i && VehicleInfo[i][vSpawner] == playerid)
			{
				RemovePlayerFromVehicle(playerid);
				break;
			}
			else
			{
				SendClientMessage(playerid, COLOR_GREY, "Someone is using that car!");
				return 1;
			}
		}
	}
	
	SetPlayerVirtualWorld(playerid, GetVehicleVirtualWorld(PlayerInfo[playerid][oldcar]));
	SetVehiclePos(PlayerInfo[playerid][oldcar], fPos[0], fPos[1], fPos[2]);
	PutPlayerInVehicle(playerid, PlayerInfo[playerid][oldcar], 0);
	
	return 1;
}

CMD:testcar(playerid, params[])
{
	new
			iVehicleID,
			szVehicleName[30],
	Float:	fCarHealth,
			szString[80];

	format(szString, sizeof(szString), "D(%d)", GetPlayerVehicleID(playerid));
	
	sscanf(params, szString, iVehicleID);
	
	if(iVehicleID == 0)
	{
		if(iVehicleID == GetPlayerVehicleID(playerid))
			SendClientMessage(playerid, COLOR_GREY, "You are not inside a vehicle.");
		else
			SendClientMessage(playerid, COLOR_GREY, "This vehicle does not exist.");
			
		return 1;
	}
	
	GetVehicleName(GetVehicleModel(iVehicleID), szVehicleName, sizeof(szVehicleName));
	GetVehicleHealth(iVehicleID, fCarHealth);
	
	format(szString, sizeof(szString), "CarID: %d, CarModel: %s, ModelID: %d, CarHealth: %.2f", iVehicleID, szVehicleName, GetVehicleModel(iVehicleID), fCarHealth);
	SendClientMessage(playerid, COLOR_WHITE, szString);
	
	return 1;
}

CMD:myrank(playerid, params[])
{
	new
		szString[87];
		
	format(szString, sizeof(szString), "You are a %s in the %s (%s).", GetPlayerRankName(playerid), GetPlayerFactionName(playerid), GetPlayerFactionAbbr(playerid));
	
	SendClientMessage(playerid, COLOR_WHITE, szString);
	
	return 1;
}

CMD:flip(playerid, params[])
{
	new
			iPlayer,
	Float:	fAngle,
			szString[69];
			
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "uf", iPlayer, fAngle))
	{
		Usage(playerid, "/angle [PlayerID/PartOfName] [Angle]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	format(szString, sizeof(szString), "You have changed %s's angle to %.2f degrees.", PlayerInfo[iPlayer][pName], fAngle);
	SendClientMessage(playerid, COLOR_RED, szString);
	
	if(IsPlayerInAnyVehicle(iPlayer))
		SetVehicleZAngle(GetPlayerVehicleID(iPlayer), fAngle);
	else
		SetPlayerFacingAngle(iPlayer, fAngle);

	return 1;
}

CMD:angle(playerid, params[])
{
	return cmd_flip(playerid, params);
}

CMD:garagecars(playerid, params[])
{
	SendClientMessage(playerid, COLOR_RED, "NEW COMMAND: /staticcars");
	return cmd_staticcars(playerid, params);
	/*new
		szString[52];

	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(!gGarageCars[0])
	{
		SpawnGarageCars();
		
		SendClientMessageToAll(COLOR_GREEN, "Garage cars spawned.");		
		format(szString, sizeof(szString), "%s spawned the garage cars.", PlayerInfo[playerid][pName]);
		SendAdminMessage(szString);
	}
	else
	{			
		for(new i; i < MAX_VEHICLES; i++)
		{
			if(VehicleInfo[i][vSpawner] == INVALID_PLAYER_ID)
			{
				SetTimerEx("VehicleDeath", 0, 0, "d", i);
			}
		}
				
		gGarageCars[0] = 0;
		gGarageCars[1] = 0;
		
		SendClientMessageToAll(COLOR_RED, "Garage cars despawned.");
		format(szString, sizeof(szString), "%s despawned the garage cars.", PlayerInfo[playerid][pName]);
		SendAdminMessage(szString);
	}
	
	return 1;*/
}

#if COMPILE_LITE_MODE == 0
CMD:roadblock(playerid, params[])
{
	ycmd_roadblock(playerid, params);
	return 1;
}
#endif

CMD:makea(playerid, params[])
{
	new
		iPlayer,
		iAdminLevel,
		szString[62];

	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "ud", iPlayer, iAdminLevel))
	{
		Usage(playerid, "/makea(dmin) [PlayerID/PartOfName] [Admin level]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}

	if(iAdminLevel > 5 || iAdminLevel < 0)
	{
		SendClientMessage(playerid,COLOR_GREY,"Invalid Admin level");
		return 1;
	}
	
	PlayerInfo[iPlayer][pAdmin] = iAdminLevel;
	
	format(szString, sizeof(szString), "You have changed %s's admin level to %d.", PlayerInfo[iPlayer][pName], iAdminLevel);
	SendClientMessage(playerid, COLOR_YELLOW, szString);
	
	format(szString, sizeof(szString), "Your admin level has been changed to %d.", iAdminLevel);
	SendClientMessage(iPlayer, COLOR_YELLOW, szString);
	
	CallRemoteFunction("UpdateAdminList", "");
	return 1;
}

CMD:makeadmin(playerid, params[])
{
	return cmd_makea(playerid, params);
}

CMD:joinf(playerid, params[])
{
	new
		szFactionPass[11],
		szString[70];
	
	if(sscanf(params, "s[11]", szFactionPass))
	{
		Usage(playerid, "/joinf(action) [Password]");
		return 1;
	}

	if(!strcmp(szFactionPass, "peadea", true))
		PlayerInfo[playerid][faction] = FACTION_LSPD;
	else if(!strcmp(szFactionPass, "forsherr", true))
		PlayerInfo[playerid][faction] = FACTION_SASD;
	else if(!strcmp(szFactionPass, "crooks", true))
		PlayerInfo[playerid][faction] = FACTION_CROOKS;
	else if(!strcmp(szFactionPass, "guardeded", true))
		PlayerInfo[playerid][faction] = FACTION_DOC;
	else
		return SendClientMessage(playerid,COLOR_GREY,"Invalid password.");
		
	PlayerInfo[playerid][rank] = 10;
	
	format(szString, sizeof(szString), "You have joined the %s. Use /getrank to get your current rank.", GetPlayerFactionAbbr(playerid));
	SendClientMessage(playerid, COLOR_GREEN, szString);
	
	return 1;
}

CMD:joinfaction(playerid, params[])
{
	return cmd_joinf(playerid, params);
}

CMD:getr(playerid, params[])
{
	new
		iRank;
	
	if(sscanf(params, "i", iRank))
	{
		Usage(playerid, "/getr(ank) [Rank ID]");
		return 1;
	}
	
	if(iRank < 1 || iRank > 10 && PlayerInfo[playerid][faction] != FACTION_LSPD || iRank > 15 && PlayerInfo[playerid][faction] == FACTION_LSPD)
	{
		SendClientMessage(playerid, COLOR_GREY, "You can only get ranks between 1 and 15/10 (LSPD/Other).");
		return 1;
	}
		
	new 
		iLimit;
		
	if(PlayerInfo[playerid][faction] == FACTION_LSPD)
	{
		switch(PlayerInfo[playerid][pAdmin])
		{
			case 2:
				iLimit = 10;
			case 3:
				iLimit = 8;
			case 4:
				iLimit = 4;
			case 5:
				iLimit = 1;
			default:
				iLimit = 5;
		}
	}
	else if(PlayerInfo[playerid][faction] == FACTION_SASD)
	{
		switch(PlayerInfo[playerid][pAdmin])
		{
			case 2:
				iLimit = 6;
			case 3:
				iLimit = 5;
			case 4:
				iLimit = 3;
			case 5:
				iLimit = 1;
			default:
				iLimit = 7;
		}
	}
	if(iRank < iLimit)
	{
		SendClientMessage(playerid, COLOR_GREY, "Your admin level isn't high enough for this rank");
		return 1;
	}
	PlayerInfo[playerid][rank] = iRank;
	
	new
		szString[39+MAX_RANKLENGTH];
	
	format(szString, sizeof(szString), "You have set your own rank to ID %d, %s.", iRank, GetPlayerRankName(playerid));
	SendClientMessage(playerid, COLOR_GREEN, szString);
	
	return 1;
}

CMD:getrank(playerid, params[])
{
	return cmd_getr(playerid, params);
}

CMD:setf(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 3)
	{
		error(playerid);
		return 1;
	}
	
	new
		szFaction[7],
		iTarget;
		
	if(sscanf(params, "us[7]", iTarget, szFaction))
	{
		Usage(playerid, "/setf(action) [PlayerID/PartOfName] [LSPD/SASD/Crooks/DoC]");
		return 1;
	}
	
	if(iTarget == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(!strcmp(szFaction, "LSPD", true))
		PlayerInfo[iTarget][faction] = FACTION_LSPD;
	else if(!strcmp(szFaction, "SASD", true))
		PlayerInfo[iTarget][faction] = FACTION_SASD;
	else if(!strcmp(szFaction, "Crooks", true))
		PlayerInfo[iTarget][faction] = FACTION_CROOKS;
	else if(!strcmp(szFaction, "DoC", true))
		PlayerInfo[iTarget][faction] = FACTION_DOC;
	else
		return SendClientMessage(playerid, COLOR_GREY, "You can only set players to LSPD, SASD or Crooks.");
		
	new
		szString[35+MAX_PLAYER_NAME];
		
	PlayerInfo[iTarget][rank] = 10;
	
	format(szString, sizeof(szString), "You have set %s's faction to %s.", PlayerInfo[iTarget][pName], GetPlayerFactionAbbr(iTarget));
	SendClientMessage(playerid, COLOR_GREEN, szString);
	
	format(szString, sizeof(szString), "%s set your faction to %s.", PlayerInfo[playerid][pName], GetPlayerFactionAbbr(iTarget));
	SendClientMessage(iTarget, COLOR_GREEN, szString);
	
	return 1;
}

CMD:setfaction(playerid, params[])
{
	return cmd_setf(playerid, params);
}

CMD:setr(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 3)
	{
		error(playerid);
		return 1;
	}
	
	new
		iTarget,
		iRank;
		
	if(sscanf(params, "ui", iTarget, iRank))
	{
		Usage(playerid, "/setr(ank) [PlayerID/PartOfName] [Rank]");
		return 1;
	}
	
	if(iTarget == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(iRank < 1 || iRank > 10 && PlayerInfo[iTarget][faction] == FACTION_SASD || iRank > 15 && PlayerInfo[iTarget][faction] == FACTION_LSPD)
	{
		SendClientMessage(playerid, COLOR_GREY, "You can only give ranks between 1 and 15/10 (LSPD/SASD).");
		return 1;
	}
	
	PlayerInfo[iTarget][rank] = iRank;
	
	new
		szString[MAX_PLAYER_NAME+MAX_RANKLENGTH+3+20]; 
	
	format(szString, sizeof(szString), "You have set %s's rank to ID %d, %s.", PlayerInfo[iTarget][pName], iRank, GetPlayerRankName(iTarget));
	SendClientMessage(playerid, COLOR_GREEN, szString);
	
	format(szString, sizeof(szString), "%s set your rank to ID %d, %s.", PlayerInfo[playerid][pName], iRank, GetPlayerRankName(iTarget));
	SendClientMessage(iTarget, COLOR_GREEN, szString);
	
	return 1;
}

CMD:setrank(playerid, params[])
{
	return cmd_setr(playerid, params);
}

CMD:kickall(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	foreach(Player, i)
	{
		if(PlayerInfo[i][pAdmin] < 5)
		{
				Kick(i);
		}
	}
	
	SendClientMessageToAll(COLOR_LIGHTRED, "All players have been kicked from the server.");
	
	return 1;
}

CMD:serverrestart(playerid, params[])
{
	new
		szString[45];
		
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	format(szString, sizeof(szString), "The server was restarted by %s.", PlayerInfo[playerid][pName]);
	SendClientMessageToAll(COLOR_RED, szString);
	
	GameTextForAll("Server restart ~n~ ~n~ ~g~ You will be auto-reconnected", 13000, 3);
	
	InsertEvent(szString);
	
	SendRconCommand("gmx");
	
	return 1;
}

CMD:id(playerid, params[])
{
	new
		iPlayer,
		szString[40];
	
	if(sscanf(params, "u", iPlayer))
	{
		Usage(playerid, "/id [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	format(szString, sizeof(szString), "ID: %d, Name: %s", iPlayer, PlayerInfo[iPlayer][pName]);
	SendClientMessage(iPlayer, COLOR_WHITE, szString);
	
	return 1;
}

CMD:admins(playerid, params[])
{
	new
		iAdminsOnline,
		szString[54];
		
	foreach(Player, i)
	{
		if(PlayerInfo[i][pAdmin] > 0)
		{
			if(!iAdminsOnline)
			{
				SendClientMessage(playerid, COLOR_GREY, "Administration online:");
			}
			iAdminsOnline = 1;
			format(szString, sizeof(szString), "(ID: %d) %s - Admin level: %d", i, PlayerInfo[i][pName], PlayerInfo[i][pAdmin]);
			SendClientMessage(playerid, COLOR_GREY, szString);
		}
	}
	
	if(!iAdminsOnline)
	{
		SendClientMessage(playerid, COLOR_GREY, "Unfortunately, there are no admins online.");
	}
	
	return 1;
}

CMD:boost(playerid, params[])
{
	new
			iPlayer,
			iVehicle,
	Float:	fVel[3],
			szString[66];
	
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}

	if(sscanf(params, "u", iPlayer))
	{
		Usage(playerid, "/boost [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	iVehicle = GetPlayerVehicleID(iPlayer);
	
	if(!iVehicle)
	{
		SendClientMessage(playerid, COLOR_RED, "This player isn't in a vehicle.");
		return 1;
	}
		
	if(GetPVarInt(iPlayer, "Racing"))
	{
		SendClientMessage(playerid, COLOR_RED, "You are not allowed to boost someone who is racing.");
		return 1;
	}
	
	GetVehicleVelocity(iVehicle, fVel[0], fVel[1], fVel[2]);
	SetVehicleVelocity(iVehicle, fVel[0] * 4.0, fVel[1] * 4.0, fVel[2] * 4.0);
	
	format(szString, sizeof(szString), "You boosted %s.", PlayerInfo[iPlayer][pName]);
	SendClientMessage(playerid, COLOR_GRAD1, szString);
	
	return 1;
}

CMD:boom(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}

	new
			iPlayer,
	Float:	fPos[3],
			szString[34];

	if(sscanf(params, "u", iPlayer))
	{
		Usage(playerid, "/boom(/nuke) [PlayerID/PartOfName]");
		return 1;
	}
	
	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(!strcmp("Fred_Johnson", PlayerInfo[iPlayer][pName2]) || !strcmp("Lenny_Carlson", PlayerInfo[iPlayer][pName2]))
	{
		SendClientMessage(playerid, COLOR_RED, "Don't even try...");
		GetPlayerPos(playerid, fPos[0], fPos[1], fPos[2]);
		CreateExplosion(fPos[0], fPos[1], fPos[2], 0, 50);
		
		format(szString, sizeof(szString), "%s tried to blow you up.", PlayerInfo[playerid][pName]);
		SendClientMessage(iPlayer, COLOR_GREY, szString);
		
		SetPlayerArmour(playerid, 0);
		SetPlayerHealth(playerid, 0);
		
		return 1;
	}
	GetPlayerPos(iPlayer, fPos[0], fPos[1], fPos[2]);
	SendClientMessage(playerid, COLOR_RED, "Boom");
	
	CreateExplosion(fPos[0], fPos[1], fPos[2], 3, 50);
	
	return 1;
}

CMD:911call(playerid, params[])
{
	new
		szLocation[120],
		szSituation[128];
		
	if(pMuted[playerid])
	{
		SendClientMessage(playerid, COLOR_LIGHTRED, "You are muted!");
		return 1;
	}
	
	if(sscanf(params, "p<#>s[121]s[120]", szSituation, szLocation))
	{
		Usage(playerid, "/911call [Situation]#[Location]");
		return 1;
	}
	
	format(szLocation, sizeof(szLocation), "Location: %s", szLocation);
	format(szSituation, sizeof(szSituation), "Situation: %s", szSituation);
	
	SendClientMessageToAll(COLOR_DBLUE, "|_______________911 Call_______________|");
	SendClientMessageToAll(COLOR_DBLUE, szSituation);
	SendClientMessageToAll(COLOR_DBLUE, szLocation);
	
	format(szSituation, sizeof(szSituation), "Last 911 call was made by %s.", PlayerInfo[playerid][pName]);
	SendAdminMessage(szSituation);
	
	return 1;
}

CMD:despawn(playerid, params[])
{
	new
		iPlayer,
		szString[7];

	if(PlayerInfo[playerid][pAdmin] < 2)
	{
		error(playerid);
		return 1;
	}
	
	format(szString, sizeof(szString), "U(%d)", playerid);
	
	if(sscanf(params, szString, iPlayer))
	{
		Usage(playerid, "/despawn [PlayerID/PartOfName]");
		return 1;
	}

	if(iPlayer == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	if(!IsPlayerInAnyVehicle(iPlayer))
	{
		SendClientMessage(playerid, COLOR_GREY, "This player isn't in any vehicle.");
		return 1;
	}
	
	SetTimerEx("VehicleDeath", 0, 0, "d", GetPlayerVehicleID(iPlayer));
	
	SendClientMessage(playerid, COLOR_GREEN, "Vehicle despawned.");
	
	return 1;
}

CMD:despawncar(playerid, params[])
{
	new
		iVehicleID;

	if(PlayerInfo[playerid][pAdmin] < 2)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "i", iVehicleID))
	{
		Usage(playerid, "/despawncar [VehicleID]");
		return 1;
	}
	
	if(iVehicleID < 0 || iVehicleID > MAX_VEHICLES)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid vehicle ID.");
		return 1;
	}
	
	SetTimerEx("VehicleDeath", 1, 0, "d", iVehicleID);
	
	SendClientMessage(playerid, COLOR_GREEN, "Vehicle despawned.");
	
	return 1;
}

CMD:despawnall(playerid, params[])
{
	new
		szString[56];

	if(PlayerInfo[playerid][pAdmin] < 3)
	{
		error(playerid);
		return 1;
	}
		
	for(new i; i < MAX_VEHICLES; i++)
	{
		if(!VehicleInfo[i][vStatic])
		{
			SetTimerEx("VehicleDeath", 0, 0, "d", i);
		}
		
	}
	
	format(szString, sizeof(szString), "[DESPAWNALL] %s despawned all cars.", PlayerInfo[playerid][pName]);
	SendClientMessageToAll(COLOR_LIGHTBLUE ,szString);
	
	return 1;
}

CMD:createrace(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	return LR_CMD_ADDRACE(playerid, params);
}

CMD:addcheckpoint(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	return LR_CMD_ADDCHECKPOINT(playerid, params);
}

CMD:ac(playerid, params[])
{
	return cmd_addcheckpoint(playerid, params);
}

CMD:loadrace(playerid, params[])
{
	#if defined RACE_DEV
		SendClientMessage(playerid, COLOR_RED, "Races are currently disabled for development purposes, please try again later.");
		return 1;
	#else
	
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	return LR_CMD_LOADRACEFORALL(playerid);
	#endif
}

CMD:race(playerid, params[])
{
	#if defined RACE_DEV
		SendClientMessage(playerid, COLOR_RED, "Races are currently disabled for development purposes, please try again later.");
		return 1;
	#else
	return LR_CMD_LOADRACEFORPLAYER(playerid);
	#endif
}

CMD:join(playerid, params[])
{
	return LR_CMD_JOINRACE(playerid);
}

CMD:leave(playerid, params[])
{
	return LR_CMD_LEAVERACE(playerid);
}

CMD:ready(playerid, params[])
{
	return LR_CMD_READY(playerid);
}

CMD:readyall(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 2)
	{
		error(playerid);
		return 1;
	}
	
	return LR_CMD_READYALL();
}

CMD:racecars(playerid, params[])
{
	return LR_CMD_RACECARS(playerid);
}

CMD:car(playerid, params[])
{
	if(GetPlayerInterior(playerid)!=0)
	{
		SendClientMessage(playerid, COLOR_GREY, "You can't spawn cars inside an interior.");
		return 1;
	}
	
	if(IsPlayerInAnyVehicle(playerid))
	{
		SendClientMessage(playerid, COLOR_GREY, "Step out of your current vehicle first.");
		return 1;
	}
	
	new
		szVehicle[20],
		szString[58];
		
	sscanf(params, "S(normal)[20]", szVehicle);

	for(new i; i < strlen(szVehicle); i++)
	{
		szVehicle[i] = tolower(szVehicle[i]);
	}
	
	format(szString, sizeof(szString), "cars/%s.txt", szVehicle);
	
	if(!fexist(szString))
	{
		SendClientMessage(playerid, COLOR_GREY, "Unavailable type of car.");
		return 1;
	}
		
	if(PlayerInfo[playerid][pAdmin] < dini_Int(szString, "admin") && dini_Int(szString, "admin") > 0)
	{
		error(playerid);
		return 1;
	}
	
	for(new i; i < MAX_VEHICLES; i++)
	{
		if(VehicleInfo[i][vOwned] == true && VehicleInfo[i][vSpawner] == playerid)
		{
			SetTimerEx("VehicleDeath", 0, 0, "d", i);
		}
	}
	
	new 
		iColor[2];
	
	if(dini_Isset(szString,"color1"))
		iColor[0] = dini_Int(szString,"color1");
	else
		iColor[0] = random(252);
		
	if(dini_Isset(szString,"color2"))
		iColor[1] = dini_Int(szString,"color2");
	else
		iColor[1] = random(252);
		
	new 
		Float:	fPos[4];
	
	GetPlayerPos(playerid, fPos[0], fPos[1], fPos[2]);
	GetPlayerFacingAngle(playerid, fPos[3]);
	
	new
		iVehicle = CreateVehicle(dini_Int(szString,"id"), fPos[0], fPos[1], fPos[2], fPos[3], iColor[0], iColor[1], -1);
	
	new
		Name[2][MAX_PLAYER_NAME];
	sscanf(PlayerInfo[playerid][pName], "s[" #MAX_PLAYER_NAME "]s[" #MAX_PLAYER_NAME "]", Name[0], Name[1]);
	SetVehicleNumberPlate(iVehicle, Name[1]);
	
	SetVehicleToRespawn(iVehicle);
	SetVehicleVirtualWorld(iVehicle, GetPlayerVirtualWorld(playerid));
	PutPlayerInVehicle(playerid, iVehicle, 0);
	
	PlayerInfo[playerid][pCarID] = iVehicle;
	VehicleInfo[PlayerInfo[playerid][pCarID]][vOwned] = true;
	VehicleInfo[PlayerInfo[playerid][pCarID]][vSpawner] = playerid;
	
	format(szString, sizeof(szString),"(( %s just used the /car command ))",PlayerInfo[playerid][pName]);
	ProxDetector(50.0, playerid, szString, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME);
	
	return 1;
}

CMD:cars(playerid, params[])
{
	new
		cmd[256],
		string[256],
		f;
		
	if(fexist("cars.txt"))
	{
		new File:hFile=fopen("cars.txt",io_read);
		new largestring[1024];
		while(fread(hFile, string))
		{
			f = 1;
			cmd=dini_PRIVATE_ExtractKey(string);
			format(largestring, 1024, "%s\n%s - %s", largestring, cmd,dini_Get("cars.txt", cmd));
		}
		ShowPlayerDialog(playerid, DIALOG_CARS, DIALOG_STYLE_LIST, "Cars list", largestring, "Spawn", "Quit");
		fclose(hFile);
	}
	if(!f)
		return SendClientMessage(playerid,COLOR_GREY,"There aren't any cars yet.");
	return 1;
}

CMD:v(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 3)
	{
		error(playerid);
		return 1;
	}
	
	new
			iCarID,
			iColor[2],
			szCarModel[20],
			iCarModel,
	Float:	fPos[4];

	if(sscanf(params, "iis[20]", iColor[0], iColor[1], szCarModel))
	{
		Usage(playerid, "/v [color1] [color2] [ModelID OR ModelName]");
		return 1;
	}
	
	GetPlayerPos(playerid, fPos[0], fPos[1], fPos[2]);
	
	fPos[0] += 5.0;
	
	if(IsNum(szCarModel))
	{
		iCarModel = strval(szCarModel);
	}
	else
	{
		iCarModel = GetVehicleId(szCarModel);
	}
	
	if(!IsValidvehicleModel(iCarModel))
	{
		SendClientMessage(playerid, COLOR_GREY, "SERVER: Invalid Vehicle model.");
		return 1;
	}

	GetPlayerFacingAngle(playerid, fPos[3]);
	iCarID = CreateVehicle(iCarModel, fPos[0], fPos[1], fPos[2], fPos[3], iColor[0], iColor[1], -1);
	
	VehicleInfo[iCarID][vOwned] = false;
	VehicleInfo[iCarID][vSpawner] = playerid;
	
	return 1;
}

CMD:veh(playerid, params[])
{
	return cmd_v(playerid, params);
}

CMD:vcar(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 3)
	{
		error(playerid);
		return 1;
	}
	
	new
			iCarID,
			iColor[2],
			szCarModel[20],
			iCarModel,
	Float:	fPos[4];

	if(sscanf(params, "iis[20]", iColor[0], iColor[1], szCarModel))
	{
		Usage(playerid, "/v [color1] [color2] [ModelID OR ModelName]");
		return 1;
	}
	
	GetPlayerPos(playerid, fPos[0], fPos[1], fPos[2]);
	
	if(IsNum(szCarModel))
	{
		iCarModel = strval(szCarModel);
	}
	else
	{
		iCarModel = GetVehicleId(szCarModel);
	}
	
	if(!IsValidvehicleModel(iCarModel))
	{
		SendClientMessage(playerid, COLOR_GREY, "SERVER: Invalid Vehicle model.");
		return 1;
	}

	GetPlayerFacingAngle(playerid, fPos[3]);
	iCarID = CreateVehicle(iCarModel, fPos[0], fPos[1], fPos[2], fPos[3], iColor[0], iColor[1], -1);
	
	VehicleInfo[iCarID][vOwned] = false;
	VehicleInfo[iCarID][vSpawner] = playerid;
	
	SetVehicleVirtualWorld(iCarID, GetPlayerVirtualWorld(playerid));
	PutPlayerInVehicle(playerid, iCarID, 0);
	
	return 1;
}

CMD:createcar(playerid, params[])
{
	new
		szName[20],
		szModelName[20],
		iModel,
		iColor[2],
		szString[100];
		
	if(PlayerInfo[playerid][pAdmin] < 4)
	{
		error(playerid);
		return 1;
	}

	if(sscanf(params, "s[20]s[20]I(-1)I(-1)", szName, szModelName, iColor[0], iColor[1]))
	{
		Usage(playerid, "/createcar [Name] [ModelName/ModelID] ([Color1] [Color2])");
		SendClientMessage(playerid, COLOR_GREY, "TIP: Leave color IDs out to make them random");
		return 1;
	}
	
	for(new i; i < strlen(szName); i++)
		szName[i] = tolower(szName[i]);
		
	format(szString, sizeof(szString), "cars/%s.txt", szName);
	
	if(fexist(szString))
	{
		SendClientMessage(playerid, COLOR_GREY, "This name is already used.");
		return 1;
	}
		
	if(IsNum(szModelName))
		iModel = strval(szModelName);
	else
		iModel = GetVehicleId(szModelName);
		
	if(iColor[0] < 0 || iColor[1] < 0 || iColor[0] > 253 || iColor[1] > 253)
		return SendClientMessage(playerid, COLOR_GREY, "You can only pick color IDs between 0 and 252.");
		
	dini_Create(szString);
	
	format(szModelName, sizeof(szModelName), "%d", iModel);
	
	dini_Set(szString, "id", szModelName);
	
	if(iColor[0] != -1)
		dini_IntSet(szString, "color1", iColor[0]);
		
	if(iColor[1] != -1)
		dini_IntSet(szString, "color2", iColor[1]);
		
	GetVehicleName(iModel, szModelName, sizeof(szModelName));
	
	format(szString, 256, "You have successfully created %s car command. ModelID: %d (%s)", szName, iModel, szModelName);
	SendClientMessage(playerid, COLOR_GREEN, szString);
	
	if(!fexist("cars.txt"))
		dini_Create("cars.txt");
		
	dini_Set("cars.txt", szName, szModelName);
	
	return 1;
}

CMD:deletecar(playerid, params[])
{
	new
		szCarName[20],
		szString[66];
		
	if(PlayerInfo[playerid][pAdmin] < 4)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "s[20]", szCarName))
	{
		Usage(playerid, "/deletecar [Carname]");
		return 1;
	}
	
	for(new i; i < strlen(szCarName); i++)
		szCarName[i] = tolower(szCarName[i]);
		
	format(szString, sizeof(szString), "cars/%s.txt", szCarName);
	
	if(!fexist(szString))
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid Name");
		return 1;
	}
		
	fremove(szString);
	dini_Unset("cars.txt", szCarName);
	
	format(szString, sizeof(szString), "You have successfully deleted %s car command.", szString[4]);
	SendClientMessage(playerid, COLOR_GREEN, szString);	
	
	return 1;
}

CMD:reloadfactions(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	LoadFactions();
	
	SendClientMessage(playerid, COLOR_GREEN, "Reloaded factions successfully.");
	
	return 1;
}

CMD:nametags(playerid, params[])
{
	new
	bool: 	iEnable,
			szString[75];
		
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(sscanf(params, "l", iEnable))
	{
		Usage(playerid, "/nametags [0/1]");
		return 1;
	}
	
	foreach(Player, i)
	{
		foreach(Player, j)
		{
			ShowPlayerNameTagForPlayer(i, j, iEnable);
		}
	}
	
	ShowNames = iEnable;
	
	if(!iEnable)
	{
		format(szString, sizeof(szString), "%s {AA3333}disabled {33CCFF}nametags visibility.", PlayerInfo[playerid][pName]);
	}
	else
	{
		format(szString, sizeof(szString), "%s {33AA33}enabled {33CCFF}nametags visibility.", PlayerInfo[playerid][pName]);
	}
	SendClientMessageToAll(COLOR_DBLUE, szString);
	
	return 1;
}

CMD:mask(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	new
		iTarget,
		szVars[7];
		
	format(szVars, 7, "U(%d)", playerid);
	
	if(sscanf(params, szVars, iTarget))
	{
		Usage(playerid, "/mask (PlayerID/PartOfName)");
		return 1;
	}
	
	if(iTarget == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid PlayerID/PartOfName.");
		return 1;
	}
	
	new
		szString[20 + MAX_PLAYER_NAME * 2];
	
	if(!GetPVarInt(iTarget, "Mask"))
	{
		if(iTarget != playerid)
		{
			format(szString, sizeof(szString), "%s gave %s a mask.", PlayerInfo[playerid][pName], PlayerInfo[iTarget][pName]);
			SendAdminMessage(szString);
			
			if(!PlayerInfo[iTarget][pAdmin])
			{
				format(szString, sizeof(szString), "%s gave you a mask.", PlayerInfo[playerid][pName]);
				SendClientMessage(iTarget, COLOR_GREEN, szString);
			}
		}
		else
		{
			format(szString, sizeof(szString), "%s gave themselves a mask.", PlayerInfo[playerid][pName]);
			SendAdminMessage(szString);
		}
		
		SetPVarInt(iTarget, "Mask", 1);
		
		foreach(Player, i)
		{
			ShowPlayerNameTagForPlayer(i, iTarget, 0);
		}
	}
	else
	{
		if(iTarget != playerid)
		{
			format(szString, sizeof(szString), "%s took %s's mask away.", PlayerInfo[playerid][pName], PlayerInfo[iTarget][pName]);
			SendAdminMessage(szString);
			
			if(!PlayerInfo[iTarget][pAdmin])
			{
				format(szString, sizeof(szString), "%s took your mask away.", PlayerInfo[playerid][pName]);
				SendClientMessage(playerid, COLOR_GREEN, szString);
			}
		}
		else
		{
			format(szString, sizeof(szString), "%s took their own mask off.", PlayerInfo[playerid][pName]);
			SendAdminMessage(szString);
		}
		
		DeletePVar(iTarget, "Mask");

		foreach(Player, i)
		{
			ShowPlayerNameTagForPlayer(i, iTarget, 1);
		}
	}
	
	return 1;
}

CMD:loaddm(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	SendRconCommand("loadfs lennysDM");
	
	return 1;
}
//----------------------/unloaddm-----------------------------------------------
CMD:unloaddm(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	SendRconCommand("unloadfs lennysDM");
	
	return 1;
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Author: Marcus
//Date: 25/05/2011
//Revision: 1
//Revised by Lenny @ Revision 2

CMD:ame(playerid, params[])
{
	if(pMuted[playerid])
	{
		SendClientMessage(playerid, COLOR_LIGHTRED, "You are muted!");
		return 1;
	}
	
	new szMessage[128];
	if(sscanf(params, "s[128]", szMessage))
	{
		Usage(playerid, "/ame [Text]");
		return 1;
	}
	
	SetPlayerChatBubble(playerid, szMessage, COLOR_ME, 15, 5000);
	
	format(szMessage, sizeof(szMessage), "< %s %s", PlayerInfo[playerid][pName], szMessage);
	SendClientMessage(playerid, COLOR_ME, szMessage);
	
	return 1;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Author: Lenny
//Date: 26/05/2011
//Revision: 2

CMD:bigears(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 4)
	{
		error(playerid);
		return 1;
	}
	
	if(!GetPVarInt(playerid, "Bigears"))
	{
		SetPVarInt(playerid, "Bigears", 1);
		SendClientMessage(playerid, COLOR_GREEN, "You will now hear all proximity chats.");
	}
	else
	{
		DeletePVar(playerid, "Bigears");
		SendClientMessage(playerid, COLOR_RED, "You no longer have big ears.");
	}
	
	return 1;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

CMD:togdeath(playerid, params[])
{	
	if(!GetPVarInt(playerid, "TogDeath"))
	{
		SetPVarInt(playerid, "TogDeath", 1);
		SendClientMessage(playerid, COLOR_GREEN, "You will now be alerted of any deaths.");
	}
	else
	{
		DeletePVar(playerid, "TogDeath");
		SendClientMessage(playerid, COLOR_RED, "You will no longer be alerted of any deaths.");
	}
	
	return 1;
}

CMD:lastdeaths(playerid, params[])
{	
	new
		szDialogString[(20 + 16 + MAX_PLAYER_NAME * 2 + 2) * MAX_DEATHLIST_ENTRIES];
	
	if(DeathList[0][dlID] == -1)
	{
		SendClientMessage(playerid, COLOR_GREY, "The deathlist is empty.");
		return 1;
	}

	if(!strcmp(DeathList[0][dlKiller], "Noone", false, 5))
		format(szDialogString, sizeof(szDialogString), "{FFFFFF}%s - {AFAFAF}%s", DeathList[0][dlTime], DeathList[0][dlKilled]);
	else
		format(szDialogString, sizeof(szDialogString), "{FFFFFF}%s - {AFAFAF}%s by %s", DeathList[0][dlTime], DeathList[0][dlKilled], DeathList[0][dlKiller]);
	
	for(new i = 1; i < MAX_DEATHLIST_ENTRIES; i++)
	{
		if(DeathList[i][dlID] == -1)
			break;
		
		if(!strcmp(DeathList[i][dlKiller], "Noone", false, 5))
			format(szDialogString, sizeof(szDialogString), "%s\n{FFFFFF}%s - {AFAFAF}%s", szDialogString, DeathList[i][dlTime], DeathList[i][dlKilled]);
		else
			format(szDialogString, sizeof(szDialogString), "%s\n{FFFFFF}%s - {AFAFAF}%s by %s", szDialogString, DeathList[i][dlTime], DeathList[i][dlKilled], DeathList[i][dlKiller]);
	}
	
	ShowPlayerDialog(playerid, DIALOG_DEATHLIST, DIALOG_STYLE_LIST, "Last deaths", szDialogString, "Info", "Cancel");
	return 1;
}

CMD:tazer(playerid, params[])
{	
	if(!GetPVarInt(playerid, "Tazer"))
	{
		new
			iWeapon[2];
			
		GetPlayerWeaponData(playerid, 2, iWeapon[0], iWeapon[1]);
		
		SetPVarInt(playerid, "TazerWeapon", iWeapon[0]);
		SetPVarInt(playerid, "TazerAmmo", iWeapon[1]);
		SetPVarInt(playerid, "Tazer", 1);
		
		GivePlayerWeapon(playerid, 23, 1000);
		
		new
			szString[MAX_PLAYER_NAME + 28];
			
		format(szString, sizeof(szString), "%s unholstered their tazer.", PlayerInfo[playerid][pName]);
		ProxDetector(30.0, playerid, szString, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME);
	}
	else
	{
		new
			iWeapon;
		
		GetPlayerWeaponData(playerid, 2, iWeapon, iWeapon);
		
		GivePlayerWeapon(playerid, 23, -iWeapon);
		GivePlayerWeapon(playerid, GetPVarInt(playerid, "TazerWeapon"), GetPVarInt(playerid, "TazerAmmo"));
		
		DeletePVar(playerid, "TazerWeapon");
		DeletePVar(playerid, "TazerAmmo");
		DeletePVar(playerid, "Tazer");
		
		new
			szString[MAX_PLAYER_NAME + 26];
			
		format(szString, sizeof(szString), "%s holstered their tazer.", PlayerInfo[playerid][pName]);
		ProxDetector(30.0, playerid, szString, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME);
	}
	
	return 1;
}

CMD:taser(playerid, params[])
{
	return cmd_tazer(playerid, params);
}

CMD:tazerid(playerid, params[])
{
	new
		iTarget;
		
	if(sscanf(params, "u", iTarget))
	{
		Usage(playerid, "/tazerid [PlayerID/PartOfName]");
		return 1;
	}
	
	if(GetPVarInt(playerid, "Frozen") > 0)
	{
		SendClientMessage(playerid, COLOR_GREY, "You can't move.");
		return 1;
	}
	
	if(!GetPVarInt(playerid, "Tazer"))
	{
		SendClientMessage(playerid, COLOR_GREY, "You haven't equipped your tazer.");
		return 1;
	}
	
	if(iTarget == INVALID_PLAYER_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "This player isn't online.");
		return 1;
	}
	
	if(IsPlayerInAnyVehicle(iTarget))
	{
		SendClientMessage(playerid, COLOR_GREY, "This player is inside a vehicle.");
		return 1;
	}
	
	if(GetPVarInt(iTarget, "Tazed"))
	{
		SendClientMessage(playerid, COLOR_GREY, "This player is already tazed.");
		return 1;
	}
	
	new
		Float: fPos[3];
		
	GetPlayerPos(iTarget, fPos[0], fPos[1], fPos[2]);
	
	if(!IsPlayerInRangeOfPoint(playerid, 12.0, fPos[0], fPos[1], fPos[2]))
	{
		SendClientMessage(playerid, COLOR_GREY, "This player isn't close enough to be tazed.");
		return 1;
	}
	
	new
		szString[18 + MAX_PLAYER_NAME * 2];
		
	format(szString, sizeof(szString), "%s was tazered by %s.", PlayerInfo[iTarget][pName], PlayerInfo[playerid][pName]);
	ProxDetector(30.0, iTarget, szString, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME);

	TogglePlayerControllable(iTarget, false);
	SetPVarInt(playerid, "DrunkTaze", GetPlayerDrunkLevel(iTarget));
	SetPlayerDrunkLevel(iTarget, GetPlayerDrunkLevel(iTarget) + 5000);
	
	SetTimerEx("TazerTimer", 10000, false, "i", iTarget);
	
	SetPVarInt(playerid, "Tazed", 1);
	
	ApplyAnimation(iTarget, "PED", "FLOOR_hit_f", 4.0, 1, 0, 0, 0, 0);
	
	return 1;
}

CMD:taserid(playerid, params[])
{
	return cmd_tazerid(playerid, params);
}

CMD:reloadraces(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	new
		szString[MAX_PLAYER_NAME + 49];
			
	format(szString, sizeof(szString), "%s reloaded the races, all active races have been cancelled.", PlayerInfo[playerid][pName]);
	SendClientMessageToAll(COLOR_GREEN, szString);
	
	foreach(Player, i)
	{
		DeletePVar(i, "Checkpoint");
		DeletePVar(i, "Racing");
		DeletePVar(playerid, "RaceTimer");
		
		DisablePlayerRaceCheckpoint(i);
	}
	
	LR_LoadRaces();
	
	return 1;
}

CMD:siren(playerid, params[])
{
	if(GetPlayerVehicleSeat(playerid) != 0)
	{
		SendClientMessage(playerid, COLOR_GREY, "You're not driving a vehicle.");
		return 1;
	}
	
	new
		iVehicle = GetPlayerVehicleID(playerid);
		
	if(VehicleInfo[iVehicle][vSiren] == -1)
	{
		switch(GetVehicleModel(iVehicle))
		{
			case SIREN_BURRITO:	AttachObjectModelToVehicle( CAR_ALARM_OBJECT, iVehicle, 0.35, 1.37, 0.48, 0.0, 0.0, 0.0 );
			case SIREN_PREMIER: AttachObjectModelToVehicle( CAR_ALARM_OBJECT, iVehicle, 0.35, 0.75, 0.4 , 0.0, 0.0, 0.0 );
			case SIREN_TAHOMA: AttachObjectModelToVehicle( CAR_ALARM_OBJECT, iVehicle, 0.35, 0.77, 0.43, 0.0,	0.0, 0.0 );
			case SIREN_HUNTLEY:	AttachObjectModelToVehicle( CAR_ALARM_OBJECT, iVehicle, 0.35, 0.52, 0.71, 0.0, 8.0, 70.0 );
			case SIREN_CHEETAH: AttachObjectModelToVehicle( CAR_ALARM_OBJECT, iVehicle, 0.4, -0.3, 0.67, 0.0, 0.0, 0.0 );
			case SIREN_BULLET: 	AttachObjectModelToVehicle( CAR_ALARM_OBJECT, iVehicle, 0.4, -0.1, 0.69, 0.0, 0.0, 0.0 );
			case SIREN_BUFFALO: AttachObjectModelToVehicle( CAR_ALARM_OBJECT, iVehicle, 0.48, -0.3, 0.81, 0.0, 0.0, 0.0 );
			case SIREN_SULTAN: AttachObjectModelToVehicle( CAR_ALARM_OBJECT, iVehicle, 0.35,0.769, 0.455,0.0, 0.0, 0.0 );
			case SIREN_ELEGANT: AttachObjectModelToVehicle( CAR_ALARM_OBJECT, iVehicle, 0.35,0.759, 0.33, 0.0, 0.0, 0.0 );
			case SIREN_SENTINEL: AttachObjectModelToVehicle( CAR_ALARM_OBJECT, iVehicle, 0.35,0.58, 0.31, 0.0, 0.0, 0.0 );
			case SIREN_TOWTRUCK: AttachObjectModelToVehicle( CAR_ALARM_OBJECT, iVehicle, -0.01,-0.5, 1.4, 0.0, 0.0, 0.0 );
			
			default:
			{
				SendClientMessage(playerid, COLOR_GREY, "This vehicle isn't supported for the siren.");
				return 1;
			}
			
		}
		
		SendClientMessage(playerid, COLOR_GREEN, "Added the siren to your vehicle.");
		
	}
	
	else
	{
		DestroyObject(VehicleInfo[iVehicle][vSiren]);
		SendClientMessage(playerid, COLOR_GREEN, "Removed the siren from your vehicle.");
		VehicleInfo[iVehicle][vSiren] = -1;
	}
	
	return 1;
}

CMD:engine(playerid, params[])
{
	if(GetPlayerVehicleSeat(playerid) != 0)
	{
		SendClientMessage(playerid, COLOR_GREY, "You're not driving any vehicle.");
		return 1;
	}
	
	new
		szString[MAX_PLAYER_NAME + 50],
		szVehicleName[25];
	
	GetVehicleName(GetVehicleModel(GetPlayerVehicleID(playerid)), szVehicleName, 25);
	
	if(ToggleVehicleEngine(GetPlayerVehicleID(playerid)) == 1)
	{
		format(szString, sizeof(szString), "%s started the engine on their %s.", PlayerInfo[playerid][pName], szVehicleName);
		ProxDetector(30.0, playerid, szString, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME);
	}
	else
	{
		format(szString, sizeof(szString), "%s stopped the engine on their %s.", PlayerInfo[playerid][pName], szVehicleName);
		ProxDetector(30.0, playerid, szString, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME);
	}
	
	return 1;
}

CMD:despawnmycars(playerid, params[])
{
	for(new i; i < MAX_VEHICLES; i++)
	{
		if(VehicleInfo[i][vSpawner] == playerid)
		{
			SetTimerEx("VehicleDeath", 0, 0, "d", i);
		}
	}
	
	SendClientMessage(playerid, COLOR_GREEN, "Despawned all your vehicles.");
	
	return 1;
}

CMD:setvehicleparams(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	new
		iVehicleID,
		szChoice[10],
		iToggle,
		iChoice;
		
	if(sscanf(params, "is[10]I(-1)", iVehicleID, szChoice, iToggle))
	{
		Usage(playerid, "/setvehicleparams [Vehicle ID] [Parameter] [1/0]");
		SendClientMessage(playerid, COLOR_GREY, "Parameters: engine, lights, alarm, doors, bonnet, boot, objective");
		return 1;
	}
	
	if(iVehicleID == INVALID_VEHICLE_ID)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid vehicle ID.");
		return 1;
	}
	
	if(!strcmp(szChoice, "engine"))
		iChoice = 1;
	else if(!strcmp(szChoice, "lights"))
		iChoice = 2;
	else if(!strcmp(szChoice, "alarm"))
		iChoice = 3;
	else if(!strcmp(szChoice, "doors"))
		iChoice = 4;
	else if(!strcmp(szChoice, "bonnet"))
		iChoice = 5;
	else if(!strcmp(szChoice, "boot"))
		iChoice = 6;
	else if(!strcmp(szChoice, "objective"))
		iChoice = 7;
	
	if(iChoice == 0)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid parameter. You can use: {FFFFFF}engine, lights, alarm, doors, bonnet, boot, objective");
		return 1;
	}
	
	if(iToggle != 0 && iToggle != 1)
	{
		new
			szString[51];
			
		format(szString, sizeof(szString), "/setvehicleparams %d %s {FFFFFF}[1/0]", iVehicleID, szChoice);
		Usage(playerid, szString);
		return 1;
	}
	
	new 
		engine, 
		lights, 
		alarm, 
		doors, 
		bonnet, 
		boot, 
		objective;
	
	GetVehicleParamsEx(iVehicleID, engine, lights, alarm, doors, bonnet, boot, objective);
	
	switch(iChoice)
	{
		case 1:
			engine = iToggle;
		case 2:
			lights = iToggle;
		case 3:
			alarm = iToggle;
		case 4:
			doors = iToggle;
		case 5:
			bonnet = iToggle;
		case 6:
			boot = iToggle;
		case 7:
			objective = iToggle;
	}
	
	SetVehicleParamsEx(iVehicleID, engine, lights, alarm, doors, bonnet, boot, objective);
	
	new
		szString[38];
	
	format(szString, sizeof(szString), "Set vehicle ID %d's %s to %d.", iVehicleID, szChoice, iToggle);
	SendClientMessage(playerid, COLOR_GREEN, szString);
	
	return 1;
}

CMD:addstaticcar(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 4)
	{
		error(playerid);
		return 1;
	}
	
	if(StaticCars[MAX_STATIC_CARS - 1][scModel])
	{
		SendClientMessage(playerid, COLOR_GREY, "Maximum amount of static vehicles added. Contact your administrator.");
		return 1;
	}
	
	if(!IsPlayerInAnyVehicle(playerid))
	{
		SendClientMessage(playerid, COLOR_GREY, "You are not inside a vehicle.");
		return 1;
	}
	
	new
		iColors[2],
		szComment[100];

	if(sscanf(params, "a<i>[2]s[100]", iColors, szComment))
	{
		Usage(playerid, "/addstaticcar [Color 1] [Color 2] [Comment]");
		SendClientMessage(playerid, COLOR_GREY, "TIP: Colors set to -1 will be randomized.");
		return 1;
	}
	
	if(iColors[0] < -1 || iColors[0] > 126 ||iColors[1] < -1 || iColors[1] > 126)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid color IDs.");
		return 1;
	}
	
	new
			iVehicleID = GetPlayerVehicleID(playerid),
			iModel = GetVehicleModel(iVehicleID),
	Float:	fPos[3],
	Float:	fAngle;
			
	GetVehiclePos(iVehicleID, fPos[0], fPos[1], fPos[2]);
	GetVehicleZAngle(iVehicleID, fAngle);
	
	new
		szString[290];
	
	format(szString, sizeof(szString), "INSERT INTO static_vehicles (model,x,y,z,angle,color1,color2,creator,comment) VALUES (%d,%f,%f,%f,%f,%d,%d,'%s','%s')", iModel, fPos[0], fPos[1], fPos[2], fAngle, iColors[0], iColors[1], PlayerInfo[playerid][pName], szComment);
	mysql_query(szString);
	
	format(szString, sizeof(szString), "Added static vehicle DBID %d. Comment: %s", mysql_insert_id(), szComment);
	SendClientMessage(playerid, COLOR_GREEN, szString);
	
	return 1;
}

CMD:delstaticcar(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 4)
	{
		error(playerid);
		return 1;
	}
	
	new
		iVehicleID;
		
	if(sscanf(params, "i", iVehicleID))
	{
		Usage(playerid, "/delstaticcar [Vehicle ID]");
		return 1;
	}
	
	if(!VehicleInfo[iVehicleID][vStatic])
	{
		SendClientMessage(playerid, COLOR_GREY, "This vehicle isn't static.");
		return 1;
	}
	
	new
		i;
	
	while(i < MAX_STATIC_CARS)
	{
		if(StaticCars[i][scVID] == iVehicleID)
			break;
		i++;
	}
	
	if(i == MAX_STATIC_CARS)
	{
		SendClientMessage(playerid, COLOR_GREY, "This vehicle isn't a static one.");
		return 1;
	}
	
	new
		szQuery[41];
	
	format(szQuery, sizeof(szQuery), "DELETE FROM static_vehicles WHERE id=%d", StaticCars[i][scDBID]);
	mysql_query(szQuery);
	
	SetTimerEx("VehicleDeath", 0, 0, "d", StaticCars[i][scVID]);
	
	LoadStaticCars();
	
	SendClientMessage(playerid, COLOR_GREEN, "Static car successfully deleted.");
	return 1;
}

CMD:staticcars(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	new
		szString[MAX_PLAYER_NAME + 29];
	
	if(StaticCarsSpawned == true)
		format(szString, sizeof(szString), "%s despawned the static cars.", PlayerInfo[playerid][pName]);
	else
		format(szString, sizeof(szString), "%s spawned the static cars.", PlayerInfo[playerid][pName]);
		
	SendAdminMessage(szString);	
		
	ToggleStaticCars();
	
	return 1;
}

CMD:repaintmycar(playerid, params[])
{
	new
		iColors[2];
		
	if(sscanf(params, "ii", iColors[0], iColors[1]))
	{
		Usage(playerid, "/repaintmycar [Color 1] [Color 2]");
		return 1;
	}
	
	if(GetPlayerVehicleSeat(playerid) != 0)
	{
		SendClientMessage(playerid, COLOR_GREY, "You're not driving a vehicle.");
		return 1;
	}
	
	if(iColors[0] < 0 || iColors[0] > 126 ||iColors[1] < 0 || iColors[1] > 126)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid colors.");
		return 1;
	}
	
	ChangeVehicleColor(GetPlayerVehicleID(playerid), iColors[0], iColors[1]);
	
	SendClientMessage(playerid, COLOR_GREEN, "Vehicle colors changed.");
	return 1;
}

CMD:repaintcar(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 3)
	{
		error(playerid);
		return 1;
	}
	
	new
		iVehicleID,
		iColors[2];
		
	if(sscanf(params, "iii", iVehicleID, iColors[0], iColors[1]))
	{
		Usage(playerid, "/repaintcar [Vehicle ID] [Color 1] [Color 2]");
		return 1;
	}
	
	if(iVehicleID < 0 || iVehicleID > MAX_VEHICLES)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid vehicle ID.");
		return 1;
	}
	
	if(iColors[0] < 0 || iColors[0] > 126 ||iColors[1] < 0 || iColors[1] > 126)
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid colors.");
		return 1;
	}
	
	ChangeVehicleColor(iVehicleID, iColors[0], iColors[1]);
	
	SendClientMessage(playerid, COLOR_GREEN, "Vehicle colors changed.");
	return 1;
}

CMD:countdown(playerid, params[])
{
	if(CountDown[0])
	{
		SendClientMessage(playerid, COLOR_GREY, "Wait until the current countdown finishes before you start a new one.");
		return 1;
	}

	new
		szString[24+MAX_PLAYER_NAME];
		
	format(szString, sizeof(szString), "%s initiated a countdown.", PlayerInfo[playerid][pName]);
	SendClientMessageToAll(COLOR_GREEN, szString);
	
	CountDown[0] = 3;
	CountDown[1] = SetTimer("Countdown", 1000, true);
	
	return 1;
}

CMD:events(playerid, params[])
{
	if(!ListPlayerEvents(playerid, 0))
	{
		SendClientMessage(playerid, COLOR_GREY, "No events have been registered yet.");
	}
	return 1;
}

CMD:duty(playerid, params[])
{
	new
		szDutyType[20],
		//szString[35+MAX_PLAYER_NAME+80],
		szString[256],
		szWeapons[20];
		
	if(sscanf(params, "S(normal)[20]", szDutyType))
	{
		Usage(playerid, "/duty (Type)");
		return 1;
	}
	
	format(szString, sizeof(szString), "duties/%s.txt", szDutyType);
	
	if(PlayerInfo[playerid][pAdmin] < dini_Int(szString, "admin") && dini_Int(szString, "admin") > 0)
		return error(playerid);
		
	if(!fexist(szString))
	{
		SendClientMessage(playerid, COLOR_GREY, "Invalid type of duty.");
		return 1;
	}
		
	if(dini_Isset(szString, "health"))
		SetPlayerHealth(playerid, dini_Float(szString, "health"));
		
	if(dini_Isset(szString, "armor"))
		SetPlayerArmour(playerid, dini_Float(szString, "armor"));
		
	if(dini_Isset(szString, "skin"))
		SetPlayerSkin(playerid, dini_Int(szString, "skin"));
		
	if(dini_Isset(szString, "weapons"))
	{
		new idx = 0;
		szString = dini_Get(szString, "weapons");
		
		szWeapons = strtok(szString, idx);
		while(strlen(szWeapons))
		{
			GivePlayerWeapon(playerid, strval(szWeapons), strval(strtok(szString, idx)));
			szWeapons = strtok(szString, idx);
		}
	}
	format(szString, sizeof(szString), "(( %s just used the /duty command ))", PlayerInfo[playerid][pName]);
	ProxDetector(50.0, playerid, szString, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME);
	
	return 1;
}

CMD:hardrestart(playerid, params[])
{		
	if(PlayerInfo[playerid][pAdmin] < 5)
	{
		error(playerid);
		return 1;
	}
	
	new
		szString[50];	
	
	format(szString, sizeof(szString), "The server was HARD-restarted by %s.", PlayerInfo[playerid][pName]);
	InsertEvent(szString);
	SendClientMessageToAll(COLOR_RED, szString);
	
	GameTextForAll("Server hard restart~n~ ~n~Please reconnect", 13000, 3);
	SendRconCommand("exit");
	
	return 1;
}

CMD:markmycar(playerid, params[])
{
	if(PlayerInfo[playerid][pAdmin] < 1)
	{
		error(playerid);
		return 1;
	}
	
	if(!IsPlayerInAnyVehicle(playerid))
	{
		SendClientMessage(playerid, COLOR_GREY, "You're not inside of a vehicle.");
		return 1;
	}
	
	new
		iVehicle = GetPlayerVehicleID(playerid),
		engine, 
		lights, 
		alarm, 
		doors, 
		bonnet, 
		boot, 
		objective;
		
	if(PlayerInfo[playerid][pMarkedCar] != INVALID_VEHICLE_ID && iVehicle != PlayerInfo[playerid][pMarkedCar])
	{
		GetVehicleParamsEx(PlayerInfo[playerid][pMarkedCar], engine, lights, alarm, doors, bonnet, boot, objective);
		objective = 0;		
		SetVehicleParamsEx(PlayerInfo[playerid][pMarkedCar], engine, lights, alarm, doors, bonnet, boot, objective);
	}
	
	GetVehicleParamsEx(iVehicle, engine, lights, alarm, doors, bonnet, boot, objective);
	printf("engine = %d, lights = %d, alarm = %d, doors = %d, bonnet = %d, boot = %d, objective = %d", engine, lights, alarm, doors, bonnet, boot, objective);
	
	if(objective == 1)
	{
		objective = 0;
		PlayerInfo[playerid][pMarkedCar] = INVALID_VEHICLE_ID;
		SendClientMessage(playerid, COLOR_GREEN, "Removed the marker on your vehicle.");
	}
	else
	{
		objective = 1;
		PlayerInfo[playerid][pMarkedCar] = iVehicle;
		SendClientMessage(playerid, COLOR_GREEN, "Added a marker on your vehicle.");
	}
	
	SetVehicleParamsEx(iVehicle, engine, lights, alarm, doors, bonnet, boot, objective);
	
	return 1;
}

CMD:stopstream(playerid, params[])
{
	#pragma unused params
	
	SendClientMessage(playerid, COLOR_GREEN, "Stream stopped.");
	
	StopAudioStreamForPlayer(playerid);
	
	return 1;
}

CMD:randomstream(playerid, params[])
{
	#pragma unused params
	
	StopAudioStreamForPlayer(playerid);
	
	PlayAudioStreamForPlayer(playerid, SillyStreams[random(sizeof(SillyStreams))]);
	
	SendClientMessage(playerid, COLOR_GREEN, "Random stream started.");
	
	return 1;
}
