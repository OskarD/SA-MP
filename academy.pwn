//==============================================================================
#define COMPILE_LITE_MODE 0
#define Uri // Uri's scripts
//==============================================================================
#include <a_samp>
#include <foreach>
#include <a_mysql>
#include <training_mysql>
#include <utils>
#include <dini>
#include <sscanf2>
#include <zcmd>
// #include <training/OPSP> Replaced with native OnPlayerTakeDamage
#if defined Uri
	#include <training/UriSWAT.pwn> // Uri's (William Walker) SWAT buildings
	#include <training/UriSWAT2.pwn> // Again, think it's a bank
#endif
//==============================================================================
#define COLOR_GRAD1 		0xB4B5B7FF
#define COLOR_ALLDEPT 		0xFF8282AA
#define COLOR_DBLUE 		0x33CCFFAA
#define COLOR_GREY 			0xAFAFAF00
#define COLOR_GREEN 		0x33AA33AA
#define COLOR_YELLOW 		0xFFFF00AA
#define COLOR_BOOC 			0xCAF6B0FF
#define COLOR_WHITE 		0xFFFFFFAA
#define COLOR_LBLUE 		0x95cee1FF
#define COLOR_FADE1 		0xE6E6E6E6
#define COLOR_FADE2 		0xC8C8C8C8
#define COLOR_FADE3 		0xAAAAAAAA
#define COLOR_FADE4 		0x8C8C8C8C
#define COLOR_FADE5 		0x6E6E6E6E
#define COLOR_RED 			0xAA3333AA
#define COLOR_INV 			0xFFFFFF00
#define COLOR_LIGHTBLUE 	0x33CCFFFF
#define COLOR_ORANGE 		0xFF9900AA
#define COLOR_OOC 			0xEADAAAFF
#define COLOR_LIGHTRED 		0xFF6347AA
#define COLOR_LIGHTYELLOW 	0xe9e6b9FF
#define COLOR_ME 			0xC2A2DAAA
#define COLOR_SBLUE 		0x6188c300
#define COLOR_EVENT			0x0080C0FF
//==============================================================================
#define SERVER_MODE				"Police Training"
#define CURRENT_VERSION 		"3.2.0"

#undef MAX_PLAYERS
#define MAX_PLAYERS    			50

#undef MAX_PLAYER_NAME					// It's (24) by default which interfers with sscanf
#define MAX_PLAYER_NAME			24

#define DIALOG_EMPTY			0 		// No results
#define DIALOG_CARS 			1 		// The dialog for /cars
#define DIALOG_TELEPORTS 		2 		// The dialog for /teleports
#define DIALOG_DEATHLIST		3 		// The dialog for /lastdeaths
#define DIALOG_LOGIN			4		// Login dialog
#define DIALOG_AUTH				5		// Auth dialog
#define DIALOG_REGISTER			6		// Register dialog

#define MAX_ADMINLEVEL			5

#define MAX_FACTIONS 			5
#define MAX_FACTION_NAME		33
#define MAX_RANKLENGTH 			26

#define MAX_AUTH_NAME			35
#define MAX_AUTHS				40

#define MAX_WEAPON_NAME			21

#define MAX_DEATHLIST_ENTRIES	12

#define MAX_STATIC_CARS			200

#define MAX_EVENTS				25

#define FACTION_LSPD 			1
#define FACTION_SASD 			2
#define FACTION_CROOKS 			3
#define FACTION_DOC				4

#define CAR_ALARM_OBJECT 		18646

#define SIREN_BURRITO	482
#define SIREN_PREMIER	426
#define SIREN_TAHOMA	566
#define SIREN_HUNTLEY	579
#define SIREN_CHEETAH	415
#define SIREN_BULLET	541
#define SIREN_BUFFALO	402
#define SIREN_SULTAN	560
#define SIREN_ELEGANT	507
#define SIREN_SENTINEL	405
#define SIREN_TOWTRUCK	525

#define THREAD_STATIC_VEHICLES		1
#define THREAD_DEATHLIST			2
#define THREAD_AUTHS				3
#define THREAD_EVENTS				4

native WP_Hash(buffer[], len, const str[]); // Whirlpool plugin
#include <vehicleutils>
//==============================================================================
forward CoNnect(playerid);
forward Academy(playerid);
forward VehicleDeath(vehicleid);
forward TazerTimer(playerid);
forward Countdown(playerid);
forward QueryError(query[], QueryError);
//==============================================================================

enum pInfo
{
	bool:	pLogin,
			pID,
			pName[25],
			pName2[25],
			pAdmin,
			pSkin,
			spec,
			pCarID,
			oldcar,
			pIP[16],
			ready,
			faction,
			rank,
			iplog,
			pLastLogout,
			pMarkedCar
};
new PlayerInfo[MAX_PLAYERS][pInfo];

enum fInfo
{
			fName[MAX_FACTION_NAME],
			fAbbrName[10],
	Float: 	fSpawnX,
	Float: 	fSpawnY,
	Float: 	fSpawnZ,
			fSpawnInt,
			fRank1[MAX_RANKLENGTH],
			fRank2[MAX_RANKLENGTH],
			fRank3[MAX_RANKLENGTH],
			fRank4[MAX_RANKLENGTH],
			fRank5[MAX_RANKLENGTH],
			fRank6[MAX_RANKLENGTH],
			fRank7[MAX_RANKLENGTH],
			fRank8[MAX_RANKLENGTH],
			fRank9[MAX_RANKLENGTH],
			fRank10[MAX_RANKLENGTH],
			fRank11[MAX_RANKLENGTH],
			fRank12[MAX_RANKLENGTH],
			fRank13[MAX_RANKLENGTH],
			fRank14[MAX_RANKLENGTH],
			fRank15[MAX_RANKLENGTH]
}
new FactionInfo[MAX_FACTIONS][fInfo];

enum VehInfos
{
	bool: 	vOwned,
			vSpawner,
			vSiren,
	bool:	vStatic
}
new VehicleInfo[MAX_VEHICLES][VehInfos];

enum AuthInfo
{
	authKey[MAX_AUTH_NAME],
	authLevel
}
new Auth[MAX_AUTHS][AuthInfo];

enum DeathListInfo
{
	dlID,
	dlKilled[MAX_PLAYER_NAME],
	dlKiller[MAX_PLAYER_NAME],
	dlReason,
	dlTime[12]
}
new DeathList[MAX_DEATHLIST_ENTRIES][DeathListInfo];

enum StaticCarsInfo
{
			scVID,
			scDBID,
			scModel,
	Float:	scX,
	Float:	scY,
	Float:	scZ,
	Float:	scAngle,
			scColor1,
			scColor2
}
new StaticCars[MAX_STATIC_CARS][StaticCarsInfo];

enum EventInfo
{
	evID,
	evTime,
	evInfo[128]
}
new Event[MAX_EVENTS][EventInfo];

new SillyStreams[][300] =
{ 	"http://www.fast-serv.com/live/stream.pls?host=sc1010.c591.fast-serv.com&port=80",
	"http://yp.shoutcast.com/sbin/tunein-station.pls?id=2466079",
	"http://yp.shoutcast.com/sbin/tunein-station.pls?id=1932284"
};

new 
	pMuted[MAX_PLAYERS],
	NoOOC,
	bool: academy = false,
	PlayersOnline,
	bool: ShowNames = true,
	bool: Marked[MAX_PLAYERS][MAX_PLAYERS],
	bool: StaticCarsSpawned = false,
	CountDown[2],
	QueryErrorID;

#if COMPILE_LITE_MODE == 0
	#include <RoadBlocksTraining>
#endif

#include <training/LennyRacing>

#include <training/traininglogin>

#include <training/RadioStations>

//==============================================================================
public OnGameModeInit()
{
	print("OnGameModeInit called...");
	print("Connecting to MySQL...");
	mysql_debug(1);
	mysql_connect(SQL_HOST, SQL_USER,SQL_DB, SQL_PASS);
	if(mysql_ping())
		print("Connected to MySQL.\n");
	else
	{
		print("Connection to MySQL failed!");
		SetGameModeText("NO MYSQL CONNECTION");
		SendClientMessageToAll(COLOR_RED, "No MySQL connection available, server shutting down...");
		SendRconCommand("exit");
		return 1;
	}
	
	SetGameModeText(SERVER_MODE " " CURRENT_VERSION);
	
	ShowNameTags(1);
	AddPlayerClass(0, 1530.1564, -1664.5430, 6.2188, 0.0, 0, 0, 0, 0, 0, 0);
    EnableStuntBonusForAll(0);
    AllowInteriorWeapons(1);
    SetNameTagDrawDistance(30.0);
	SetWeather(10);
	
    print("Includes");
    print("---------------");
	
    new Includes;
    #if defined Uri
    	if(UriSWAT_OnGameModeInit())		 // Uri's SWAT buildings
    	    Includes++;
    	if(UriSWAT2_OnGameModeInit())
    	    Includes++;
	#endif
	
	printf("  Loaded %i Includes.\n", Includes);
	
	print("Functions");
	print("---------------");
	new Functions;
	
	LoadFactions();
	Functions++;
	
	#if COMPILE_LITE_MODE == 0
		LoadRoadBlocks();
		Functions++;
	#endif
	
	LR_LoadRaces();
	Functions++;
	
	LoadVehicles();
	Functions++;
	
	LoadAuths();
	Functions++;
	
	LoadDeathList();
	Functions++;
	
	LoadStaticCars();
	Functions++;
	
	LoadEvents();
	Functions++;
	
	printf("  Loaded %i functions.\n", Functions);
	
	for(new i; i < MAX_PLAYERS; i++)
	{
		ResetPlayer(i);
	}
	
	print("OnGameModeInit finished.");
	return 1;
}
//==============================================================================
stock strtok(const string[], &index)
{
	new length = strlen(string);
	while ((index < length) && (string[index] <= ' '))
	{
		index++;
	}

	new offset = index;
	new result[20];
	while ((index < length) && (string[index] > ' ') && ((index - offset) < (sizeof(result) - 1)))
	{
		result[index - offset] = string[index];
		index++;
	}
	result[index - offset] = EOS;
	return result;
}
stock GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, Float:distance)
{
	new Float:a;
	GetPlayerPos(playerid, x, y, a);
	GetPlayerFacingAngle(playerid, a);
	if (GetPlayerVehicleID(playerid))
	{
	    GetVehicleZAngle(GetPlayerVehicleID(playerid), a);
	}
	x += (distance * floatsin(-a, degrees));
	y += (distance * floatcos(-a, degrees));
}
//==============================================================================
stock GetVehicleId(name[])
{
	new VehicleNames[][] =
	{
		"Landstalker","Bravura","Buffalo","Linerunner","Pereniel","Sentinel","Dumper","Firetruck","Trashmaster","Stretch","Manana","Infernus","Voodoo","Pony","Mule","Cheetah","Ambulance","Leviathan","Moonbeam","Esperanto",
		"Taxi","Washington","Bobcat","Mr Whoopee","BF Injection","Hunter","Premier","Enforcer","Securicar","Banshee","Predator","Bus","Rhino","Barracks","Hotknife","Trailer","Previon","Coach","Cabbie","Stallion",
		"Rumpo","RC Bandit","Romero","Packer","Monster","Admiral","Squalo","Seasparrow","Pizzaboy","Tram","Trailer","Turismo","Speeder","Reefer","Tropic","Flatbed","Yankee","Caddy","Solair","Berkley's RC Van",
		"Skimmer","PCJ-600","Faggio","Freeway","RC Baron","RC Raider","Glendale","Oceanic","Sanchez","Sparrow","Patriot","Quad","Coastguard","Dinghy","Hermes","Sabre","Rustler","ZR3 50","Walton","Regina",
		"Comet","BMX","Burrito","Camper","Marquis","Baggage","Dozer","Maverick","News Chopper","Rancher","FBI Rancher","Virgo","Greenwood","Jetmax","Hotring","Sandking","Blista Compact","Police Maverick","Boxville","Benson",
		"Mesa","RC Goblin","Hotring Racer","Hotring Racer","Bloodring Banger","Rancher","Super GT","Elegant","Journey","Bike","Mountain Bike","Beagle","Cropdust","Stunt","Tanker","RoadTrain","Nebula","Majestic","Buccaneer","Shamal",
		"Hydra","FCR-900","NRG-500","HPV1000","Cement Truck","Tow Truck","Fortune","Cadrona","FBI Truck","Willard","Forklift","Tractor","Combine","Feltzer","Remington","Slamvan","Blade","Freight","Streak","Vortex",
		"Vincent","Bullet","Clover","Sadler","Firetruck","Hustler","Intruder","Primo","Cargobob","Tampa","Sunrise","Merit","Utility","Nevada","Yosemite","Windsor","Monster","Monster","Uranus","Jester",
		"Sultan","Stratum","Elegy","Raindance","RC Tiger","Flash","Tahoma","Savanna","Bandito","Freight","Trailer","Kart","Mower","Duneride","Sweeper","Broadway","Tornado","AT-400","DFT-30","Huntley",
		"Stafford","BF-400","Newsvan","Tug","Trailer","Emperor","Wayfarer","Euros","Hotdog","Club","Trailer","Trailer","Andromada","Dodo","RC Cam","Launch","Police Car (LSPD)","Police Car (SFPD)","Police Car (LVPD)","Police Ranger",
		"Picador","S.W.A.T. Van","Alpha","Phoenix","Glendale","Sadler","Luggage Trailer","Luggage Trailer","Stair Trailer","Boxville","Farm Plow","Utility Trailer"
	};
	for(new i=0;i<sizeof(VehicleNames);i++)
	    if(!strcmp(name,VehicleNames[i],true))
	        return i+400;
	return INVALID_VEHICLE_ID;
}
//==============================================================================
stock ResetPlayer(playerid, bool: connecting = false)
{
	PlayerInfo[playerid][pLogin] = false;
	PlayerInfo[playerid][pID] = -1;
	format(PlayerInfo[playerid][pName], MAX_PLAYER_NAME, "ERROR CONTACT LENNY");
	format(PlayerInfo[playerid][pName2], MAX_PLAYER_NAME, "ERROR_CONTACT_LENNY");
	PlayerInfo[playerid][pAdmin] = -1;
	PlayerInfo[playerid][pSkin] = 0;
 	PlayerInfo[playerid][spec] = INVALID_PLAYER_ID;
 	PlayerInfo[playerid][pCarID] = INVALID_VEHICLE_ID;
 	PlayerInfo[playerid][oldcar] = INVALID_VEHICLE_ID;
	format(PlayerInfo[playerid][pIP], 16, "");
	PlayerInfo[playerid][ready] = 0;
	PlayerInfo[playerid][faction] = 0;
	PlayerInfo[playerid][rank] = 10;
	PlayerInfo[playerid][iplog] = 10;
	PlayerInfo[playerid][pLastLogout] = 0;
	PlayerInfo[playerid][pMarkedCar] = INVALID_VEHICLE_ID;
	
	if(connecting == false)
	{
		for(new i; i < MAX_PLAYERS; i++)
		{
			Marked[playerid][i] = false;
		}
		
		foreach(Player, i)
		{
			Marked[i][playerid] = false;
		}
			
		for(new i; i < MAX_VEHICLES; i++)
		{
			if(VehicleInfo[i][vSpawner] == playerid)
			{
				VehicleDeath(i);
			}
		}
	}
}
//==============================================================================
ban(playerid, byplayerid, reason[])
{
	new
		szEscapedReason[120],
		szString[400];
		
	format(szString, sizeof(szString), "[BAN] %s was banned by %s.", PlayerInfo[playerid][pName], PlayerInfo[byplayerid][pName]);
	InsertEvent(szString);
	SendClientMessageToAll(COLOR_LIGHTRED, szString);
	format(szString, sizeof(szString), "Reason: %s", reason);
	SendClientMessageToAll(COLOR_LIGHTRED, szString);

	mysql_real_escape_string(reason, szEscapedReason);
	format(szString, sizeof(szString), "INSERT INTO `bans` (banner, banned, reason, ip) VALUES ('%s', '%s', '%s', '%s')", PlayerInfo[byplayerid][pName], PlayerInfo[playerid][pName], szEscapedReason, PlayerInfo[playerid][pIP]);
	mysql_query(szString);
	
	format(szString, sizeof(szString), "UPDATE `players` SET `banned`=1 WHERE `id`=%d", PlayerInfo[playerid][pID]);
	mysql_query(szString);
	
	CallRemoteFunction("UpdateLastBans", "");
	Kick(playerid);
}
//==============================================================================
stock Log(logname[], string[])
{
	new iYear,
	    iMonth,
	    iDay,
		iHour,
		iMinute,
		iSecond,
		szLogFileName[80],
		szString[200];
		
	getdate(iYear, iMonth, iDay);
	gettime(iHour, iMinute, iSecond);
	format(szLogFileName, 80, "logs/%s.txt", logname);
	format(szString, 200, "[%d-%02d-%02d][%02d:%02d:%02d] %s\r\n", iYear, iMonth, iDay, iHour, iMinute, iSecond, string);
	new File: szLogFile=fopen(szLogFileName, io_append);
	fwrite(szLogFile, szString);
	fclose(szLogFile);
}
//==============================================================================
LoadPlayer(playerid)
{	
	new
		szQuery[130],
		iBanned;

	format(szQuery, 130, "SELECT `banned`,`id`,`admin`,`skin`,`faction`,`rank`,`lastlogout` FROM `players` WHERE `name`='%s'", PlayerInfo[playerid][pName2]);
	mysql_query(szQuery);
	mysql_store_result();
	
	if(mysql_num_rows() != 1)
	{
		printf("[MYSQL WARNING] Tried to load %s, failed due to invalid amount of rows returned (%d)", PlayerInfo[playerid][pName2], mysql_num_rows());
		SendClientMessage(playerid, COLOR_RED, "Couldn't load your account, please write down the time and date and contact Lenny.");
		Kick(playerid);
		return 1;
	}
	
	mysql_fetch_row_format(szQuery, " ");
	sscanf(szQuery, "iiiiiii", iBanned, PlayerInfo[playerid][pID], PlayerInfo[playerid][pAdmin], PlayerInfo[playerid][pSkin], PlayerInfo[playerid][faction], PlayerInfo[playerid][rank], PlayerInfo[playerid][pLastLogout]);
	
	if(PlayerInfo[playerid][pAdmin] < 0)
	{
		printf("[MYSQL WARNING] Admin level is below 0 (%d), name: %s, returned row: %s", PlayerInfo[playerid][pAdmin], PlayerInfo[playerid][pName2], szQuery);
		SendClientMessage(playerid, COLOR_RED, "Your admin level is below 0, which probably means that your account was bugged at some point before this login.");
		SendClientMessage(playerid, COLOR_RED, "Please note down the time and date and contact me (Lenny Carlson) so I can investigate and fix it!");
		mysql_free_result();
		Kick(playerid);
		return 1;
	}

	mysql_free_result();
	
	if(iBanned)
	{
		format(szQuery, 130, "SELECT reason FROM bans WHERE banned='%s' ORDER BY id DESC LIMIT 1", PlayerInfo[playerid][pName]);
		mysql_query(szQuery);
		mysql_store_result();
		mysql_fetch_row_format(szQuery, " ");
		sscanf(szQuery, "s[130]", szQuery);
		mysql_free_result();
		SendClientMessage(playerid, COLOR_RED, " ");
		SendClientMessage(playerid, COLOR_RED, "You are banned from this server. Reason:");
		SendClientMessage(playerid, COLOR_RED, szQuery);
		SendClientMessage(playerid, COLOR_RED, " ");
		Kick(playerid);
		return 1;
	}
	
	format(szQuery, 130, "INSERT INTO loginhistory (pid, name, ip) VALUES (%d, '%s', '%s')", PlayerInfo[playerid][pID], PlayerInfo[playerid][pName], PlayerInfo[playerid][pIP]);
	mysql_query(szQuery);
	
	format(szQuery, 130, "SELECT `id` FROM loginhistory WHERE pid=%d", PlayerInfo[playerid][pID]);
	mysql_query(szQuery);
	mysql_store_result();
	format(szQuery, 130, "You have logged in %d times now!", mysql_num_rows());
	SendClientMessage(playerid, COLOR_GREY, szQuery);
	mysql_free_result();
	
	if(!PlayerInfo[playerid][pSkin])
		PlayerInfo[playerid][pSkin] = 280;
	SetPlayerColor(playerid, COLOR_SBLUE);
	new factionid = PlayerInfo[playerid][faction];
	if(factionid > 0)
		SetPlayerPos(playerid, FactionInfo[factionid][fSpawnX], FactionInfo[factionid][fSpawnY], FactionInfo[factionid][fSpawnZ]);
	
	#if defined USE_PERMISSIONS
		LoadPlayerPermissions(playerid);
	#endif
	return 1;
}
//==============================================================================
Encrypt(string[])
{
	new buf[145];
	WP_Hash(buf, 145, string);
	return(buf);
}
//==============================================================================
LoadFactions()
{
	print("  LoadFactions initalized...");
	new file[13];
	format(file, 13, "factions.txt");
	if(!fexist(file))
        dini_Create(file);
    new file2[MAX_FACTION_NAME+15]; // The faction's file
    //new RankNumber[25];
	for(new i; i < MAX_FACTIONS; i++)
	{
	    new istring[2];
	    format(istring, 2, "%d", i);
		format(FactionInfo[i][fName], sizeof(file2), dini_Get(file, istring));
		//printf("DEBUG: Faction name = %s", FactionInfo[i][fName]);
		if(!strlen(FactionInfo[i][fName]))
		    continue;
		format(file2, sizeof(file2), "factions/%s.txt", FactionInfo[i][fName]);
		if(!fexist(file2))
	        dini_Create(file2);

		format(FactionInfo[i][fAbbrName], 10, dini_Get(file2, "fAbbrName"));
		//printf("DEBUG: fAbbrName = %s", FactionInfo[i][fAbbrName]);
		FactionInfo[i][fSpawnX] = floatstr(dini_Get(file2, "fSpawnX"));
		//printf("DEBUG: fSpawnX = %.2f", FactionInfo[i][fSpawnX]);
		FactionInfo[i][fSpawnY] = floatstr(dini_Get(file2, "fSpawnY"));
		//printf("DEBUG: fSpawnY = %.2f", FactionInfo[i][fSpawnY]);
		FactionInfo[i][fSpawnZ] = floatstr(dini_Get(file2, "fSpawnZ"));
		//printf("DEBUG: fSpawnZ = %.2f", FactionInfo[i][fSpawnZ]);
		FactionInfo[i][fSpawnInt] = dini_Int(file2, "fSpawnInt");
		//printf("DEBUG: fSpawnInt = %d", FactionInfo[i][fSpawnInt]);

		format(FactionInfo[i][fRank1], MAX_RANKLENGTH, dini_Get(file2, "fRank1"));
		//printf("DEBUG: FactionInfo1 = %s", FactionInfo[i][fRank1]);
		format(FactionInfo[i][fRank2], MAX_RANKLENGTH, dini_Get(file2, "fRank2"));
		//printf("DEBUG: FactionInfo2 = %s", FactionInfo[i][fRank2]);
		format(FactionInfo[i][fRank3], MAX_RANKLENGTH, dini_Get(file2, "fRank3"));
		//printf("DEBUG: FactionInfo3 = %s", FactionInfo[i][fRank3]);
		format(FactionInfo[i][fRank4], MAX_RANKLENGTH, dini_Get(file2, "fRank4"));
		//printf("DEBUG: FactionInfo4 = %s", FactionInfo[i][fRank4]);
		format(FactionInfo[i][fRank5], MAX_RANKLENGTH, dini_Get(file2, "fRank5"));
		//printf("DEBUG: FactionInfo5 = %s", FactionInfo[i][fRank5]);
		format(FactionInfo[i][fRank6], MAX_RANKLENGTH, dini_Get(file2, "fRank6"));
		//printf("DEBUG: FactionInfo6 = %s", FactionInfo[i][fRank6]);
		format(FactionInfo[i][fRank7], MAX_RANKLENGTH, dini_Get(file2, "fRank7"));
		//printf("DEBUG: FactionInfo7 = %s", FactionInfo[i][fRank7]);
		format(FactionInfo[i][fRank8], MAX_RANKLENGTH, dini_Get(file2, "fRank8"));
		//printf("DEBUG: FactionInfo8 = %s", FactionInfo[i][fRank8]);
		format(FactionInfo[i][fRank9], MAX_RANKLENGTH, dini_Get(file2, "fRank9"));
		//printf("DEBUG: FactionInfo9 = %s", FactionInfo[i][fRank9]);
		format(FactionInfo[i][fRank10], MAX_RANKLENGTH, dini_Get(file2, "fRank10"));
		//printf("DEBUG: FactionInfo10 = %s", FactionInfo[i][fRank10]);
		format(FactionInfo[i][fRank11], MAX_RANKLENGTH, dini_Get(file2, "fRank11"));
		//printf("DEBUG: FactionInfo10 = %s", FactionInfo[i][fRank10]);
		format(FactionInfo[i][fRank12], MAX_RANKLENGTH, dini_Get(file2, "fRank12"));
		//printf("DEBUG: FactionInfo10 = %s", FactionInfo[i][fRank10]);
		format(FactionInfo[i][fRank13], MAX_RANKLENGTH, dini_Get(file2, "fRank13"));
		//printf("DEBUG: FactionInfo10 = %s", FactionInfo[i][fRank10]);
		format(FactionInfo[i][fRank14], MAX_RANKLENGTH, dini_Get(file2, "fRank14"));
		//printf("DEBUG: FactionInfo10 = %s", FactionInfo[i][fRank10]);
		format(FactionInfo[i][fRank15], MAX_RANKLENGTH, dini_Get(file2, "fRank15"));
		//printf("DEBUG: FactionInfo10 = %s", FactionInfo[i][fRank10]);
	}
}
//==============================================================================
GetPlayerFactionName(playerid)
{
	new string[MAX_FACTION_NAME];
	format(string, sizeof(string), FactionInfo[PlayerInfo[playerid][faction]][fName]);
	return string;
}
GetPlayerRankName(playerid)
{
	new string[MAX_RANKLENGTH];
	switch(PlayerInfo[playerid][rank])
	{
	    case 1:
	        format(string, MAX_RANKLENGTH, FactionInfo[PlayerInfo[playerid][faction]][fRank1]);
		case 2:
		    format(string, MAX_RANKLENGTH, FactionInfo[PlayerInfo[playerid][faction]][fRank2]);
		case 3:
		    format(string, MAX_RANKLENGTH, FactionInfo[PlayerInfo[playerid][faction]][fRank3]);
		case 4:
		    format(string, MAX_RANKLENGTH, FactionInfo[PlayerInfo[playerid][faction]][fRank4]);
		case 5:
		    format(string, MAX_RANKLENGTH, FactionInfo[PlayerInfo[playerid][faction]][fRank5]);
		case 6:
		    format(string, MAX_RANKLENGTH, FactionInfo[PlayerInfo[playerid][faction]][fRank6]);
		case 7:
		    format(string, MAX_RANKLENGTH, FactionInfo[PlayerInfo[playerid][faction]][fRank7]);
		case 8:
		    format(string, MAX_RANKLENGTH, FactionInfo[PlayerInfo[playerid][faction]][fRank8]);
		case 9:
		    format(string, MAX_RANKLENGTH, FactionInfo[PlayerInfo[playerid][faction]][fRank9]);
		case 10:
		    format(string, MAX_RANKLENGTH, FactionInfo[PlayerInfo[playerid][faction]][fRank10]);
		case 11:
		    format(string, MAX_RANKLENGTH, FactionInfo[PlayerInfo[playerid][faction]][fRank11]);
		case 12:
		    format(string, MAX_RANKLENGTH, FactionInfo[PlayerInfo[playerid][faction]][fRank12]);
		case 13:
		    format(string, MAX_RANKLENGTH, FactionInfo[PlayerInfo[playerid][faction]][fRank13]);
		case 14:
		    format(string, MAX_RANKLENGTH, FactionInfo[PlayerInfo[playerid][faction]][fRank14]);
		case 15:
		    format(string, MAX_RANKLENGTH, FactionInfo[PlayerInfo[playerid][faction]][fRank15]);
		default:
		    format(string, MAX_RANKLENGTH, "Unranked");
	}
	return string;
}
GetPlayerFactionAbbr(playerid)
{
	new string[10];
	format(string, 10, FactionInfo[PlayerInfo[playerid][faction]][fAbbrName]);
	return string;
}
stock strrest(string[],idx)
{
	new str1[256], str2[256];
	format(str1,256,string);
	new i=idx;
	str2=strtok(str1,i);
	while(strlen(str2))
		str2=strtok(str1,i);
	strmid(str2,string,idx+1,i);
	return str2;
}
//==============================================================================
main()
{
	print("\n");
	print("--------------------------------------------");
	print(" LSPD Training server, By TheShadow & Lenny");
	print("--------------------------------------------\n");
}
//==============================================================================
error(playerid)
	return SendClientMessage(playerid, COLOR_GREY, "Your admin level is too low to use this command.");
//==============================================================================
GetWeaponSlot(w)
{
	switch(w)
	{
 		case 0..1: return 0;
   		case 2..9: return 1;
   		case 22..24: return 2;
   		case 25..27: return 3;
   		case 28..29,32: return 4;
   		case 30..31: return 5;
   		case 33..34: return 6;
   		case 35..38: return 7;
   		case 16..19: return 8;
   		case 41..43: return 9;
   		case 11..15: return 10;
   		case 44..46: return 11;
   		case 40: return 12;
	}
	return -1;
}
//==============================================================================
GetWeaponId(wname[])
{
    if(!strlen(wname))
        return 0;
    for(new i=1;i<49;i++)
    {
        new wname2[256];
        GetWeaponName(i,wname2,50);
        if(!strcmp(wname,wname2,true,sizeof(wname2))&&strlen(wname2))
            return i;
    }
    return 0;
}
//==============================================================================
IsASkin(skinid)
{
		if((skinid >= 1 &&  skinid <= 41) || (skinid >= 43 && skinid <= 64) || (skinid >= 66 && skinid <= 73) || (skinid >= 75 && skinid <= 85) || (skinid >= 87 &&  skinid <= 299))
		    return 1;
		else if(skinid == 74 || skinid == 119 || skinid == 149 || skinid == 208 || skinid == 273 || skinid == 289)
		    return 0;
		else if(skinid < 1 || skinid > 299)
		    return 0;
		else
			return 0;
}
//==============================================================================
#define FACTIONSKINS (14)
new FactionSkin[FACTIONSKINS] =
{
	280, // LSPD
	281, // LSPD
	265, // LSPD
	266, // LSPD
	267, // LSPD
	282, // SASD
	283, // SASD
	288, // SASD
	284, // Bike
	285, // SWAT
	286, // FBI
	287, // Army
	71,  // Cadet
	93	 // Female
};

new CriminalSkin[]=
{
	105, 	106,	107,	102,	103,	104,
	114,	115,	116,	108,	109,	110,
	121,	122,	123,	173,	174,	175,
	117,	118,	120,	247,	248,	254,
	111,	112,	113,	124,	125,	126,
	127
};
//==============================================================================
public OnPlayerStreamIn(playerid, forplayerid)
{
	ShowPlayerNameTagForPlayer(forplayerid, playerid, ShowNames);
	if(ShowNames)
	{
		if(GetPVarInt(playerid, "Mask"))
		{
			ShowPlayerNameTagForPlayer(forplayerid, playerid, 0);
		}
	}
}
//==============================================================================
public VehicleDeath(vehicleid)
{
	if(VehicleInfo[vehicleid][vOwned])
		PlayerInfo[VehicleInfo[vehicleid][vSpawner]][pCarID] = INVALID_VEHICLE_ID;
	
	VehicleInfo[vehicleid][vOwned] = false;
	VehicleInfo[vehicleid][vSpawner] = INVALID_PLAYER_ID;
	VehicleInfo[vehicleid][vStatic] = false;
	
	if(VehicleInfo[vehicleid][vSiren] != -1)
	{
		DestroyObject(VehicleInfo[vehicleid][vSiren]);
		VehicleInfo[vehicleid][vSiren] = -1;
	}
	
	foreach(Player, i)
	{
		if(PlayerInfo[i][oldcar] == vehicleid)
			PlayerInfo[i][oldcar] = INVALID_VEHICLE_ID;
			
		if(PlayerInfo[i][pMarkedCar] == vehicleid)
			PlayerInfo[i][pMarkedCar] = INVALID_VEHICLE_ID;
	}
	DestroyVehicle(vehicleid);
}
//==============================================================================
SendAdminMessage(const string[])
{
	foreach(Player, i)
	{
	    if(PlayerInfo[i][pAdmin] > 0)
	    {
	        SendClientMessage(i, COLOR_LIGHTBLUE, string);
		}
	}
	return 1;
}

SendFactionMessage(playerid, color, const string[])
{
	new factionid = PlayerInfo[playerid][faction];
	foreach(Player, i)
	{
	    if(PlayerInfo[i][faction] == factionid)
	    {
	        SendClientMessage(i, color, string);
		}
	}
	return 1;
}
//==============================================================================
public OnGameModeExit()
{
	foreach(Player, i)
	{
		OnPlayerDisconnect(i, 3);
	}
	mysql_close();
	return 1;
}
//==============================================================================
stock PlayerFile(playerid)
{
	new szQuery[200];
	format(szQuery, sizeof(szQuery), "UPDATE `players` SET `admin`=%d, `ip`='%s', `faction`=%d, `rank`=%d, `skin`=%d, `iplog`=%d, `lastlogout`=%d WHERE `id`=%d", PlayerInfo[playerid][pAdmin], PlayerInfo[playerid][pIP], PlayerInfo[playerid][faction], PlayerInfo[playerid][rank], PlayerInfo[playerid][pSkin], PlayerInfo[playerid][iplog], gettime(), PlayerInfo[playerid][pID]);
	mysql_query(szQuery);
}

public Countdown()
{
	new
		szCount[7];
	
	if(CountDown[0] <= 0)
	{
		format(szCount, sizeof(szCount), "~g~Go!");
		GameTextForAll(szCount, 2000, 3);
		foreach(Player, i) PlayerPlaySound(i, 1057, 0, 0, 0);
		KillTimer(CountDown[1]);
	}
	else
	{
		format(szCount, sizeof(szCount), "~r~%d", CountDown[0]);
		GameTextForAll(szCount, 500, 3);
		foreach(Player, i) PlayerPlaySound(i, 1056, 0, 0, 0);
		CountDown[0]--;
	}
	return 1;
}
//==============================================================================
public CoNnect(playerid)
{
	PlayerInfo[playerid][pLogin] = true;
	DeletePVar(playerid, "Password");
	SpawnPlayer(playerid);
	LoadPlayer(playerid);
	SendClientMessage(playerid, COLOR_GREY, "You were auto-logged in thanks to IPState. You can disable it with \"{FFFFFF}/ipstate off{AFAFAF}\".");
	printf("[LOGIN] %s logged in (IPState)", PlayerInfo[playerid][pName2]);
	new factionid = PlayerInfo[playerid][faction];
	if(factionid > 0)
	    SetPlayerPos(playerid, FactionInfo[factionid][fSpawnX], FactionInfo[factionid][fSpawnY], FactionInfo[factionid][fSpawnZ]);
	GivePlayerMoney(playerid, 100000);
}
//==============================================================================
public Academy(playerid)
{
	SpawnPlayer(playerid);
}
//==============================================================================
public OnPlayerRequestClass(playerid, classid)
{
	SetPlayerPos(playerid,1532.8749,-1694.0746,33.3828+6);
	SetPlayerCameraPos(playerid,1532.8749,-1694.0746,33.3828);
	SetPlayerCameraLookAt(playerid,1549.7262,-1676.4553,15.0988);
	SetPlayerVirtualWorld(playerid,0);
	if(!PlayerInfo[playerid][pLogin])
	{
		new
			string[256],
			IP[16],
			password[145];
			
		format(string, 256, "SELECT `iplog`,`ip`,`password` FROM `players` WHERE `name` = '%s'", PlayerInfo[playerid][pName2]);
		mysql_query(string);
		mysql_store_result();
		
		mysql_fetch_row_format(string, " ");
		
		sscanf(string, "ds[16]s[145]", PlayerInfo[playerid][iplog], IP, password);
		
		if(PlayerInfo[playerid][iplog] && strlen(PlayerInfo[playerid][pIP]) && strlen(IP) && !strcmp(PlayerInfo[playerid][pIP], IP, false, 16))
		{
			SetTimerEx("CoNnect", 500, false, "d", playerid);
		}
		else if(mysql_num_rows())
		{
			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "{33AA33}Welcome to the Police Training Server!\n{FFFFFF}Thanks to Furion.nl for sponsoring us with this free host!\n\nThis character is registered, please provide your password below.", "Log in", "Exit");
			SetPVarString(playerid, "Password", password);
		}
		else if(academy)
		{
			SetTimerEx("Academy", 1000, 0, "d", playerid);
			SendClientMessage(playerid, COLOR_WHITE, "Welcome to the Police Academy! Listen carefully to the instuctors. Good luck!");
		}
		else
		{
			ShowPlayerDialog(playerid, DIALOG_AUTH, DIALOG_STYLE_INPUT, "Authenticate", "{33AA33}Welcome to the Police Training Server!\n{FFFFFF}Thanks to Furion.nl for sponsoring us with this free host!\n\nThis character is {AA3333}not registered{FFFFFF} and before you can register you need to provide an {33AA33}auth code{FFFFFF} that you can find on your faction's forum. Please specify your {33AA33}auth code{FFFFFF} below.", "Submit", "Exit");
		}
		mysql_free_result();
	}
	return 1;
}
//==============================================================================
public OnPlayerRequestSpawn(playerid)
{
	if(!PlayerInfo[playerid][pLogin])
	    return 0;
	return 1;
}
//==============================================================================
public OnPlayerConnect(playerid)
{
	ResetPlayer(playerid, false);
	if(IsPlayerNPC(playerid))
	{
		SpawnPlayer(playerid);
		return 1;
	}
	GetPlayerIp(playerid, PlayerInfo[playerid][pIP], 16);
	
	//PlayerPlaySound(playerid, 1185, 0.0, 0.0, 0.0); // Some music on join
	
	PlayAudioStreamForPlayer(playerid, SillyStreams[random(sizeof(SillyStreams))]);
	
	GetPlayerName(playerid, PlayerInfo[playerid][pName2], MAX_PLAYER_NAME);
	GetPlayerName(playerid, PlayerInfo[playerid][pName], MAX_PLAYER_NAME);
	
	printf("[SRVDEBUG] %s connected with ID %d", PlayerInfo[playerid][pName2], playerid);
	
	for(new i; i < strlen(PlayerInfo[playerid][pName]); i++)
	{
		if(PlayerInfo[playerid][pName][i] == '_')
 			PlayerInfo[playerid][pName][i] = ' ';
	}	

    SetPlayerColor(playerid, COLOR_GREY);
	
	new Hour, tmp, file[17], string[20];
	gettime(Hour, tmp, tmp);
	format(file, 17, "logs/timelog.txt");
	if(!dini_Exists(file))
	    dini_Create(file);
	format(string, sizeof(string), "%d", Hour);
	tmp = strval(dini_Get(file, string))+1;
	dini_IntSet(file, string, tmp);
	PlayersOnline++;
	format(string, sizeof(string), "Players online: %d", PlayersOnline);
	Log("playersonline", string);
	return 1;
}
//==============================================================================
public OnPlayerUpdate(playerid)
{
	return 1;
}
//==============================================================================
public OnPlayerDisconnect(playerid, reason)
{
	if(PlayerInfo[playerid][pAdmin] < 0)
	{
		printf("[SRVDEBUG] %s logged out with admin level %d, will not be saved.", PlayerInfo[playerid][pName2], PlayerInfo[playerid][pAdmin]);
		PlayerInfo[playerid][pLogin] = false;
	}
	
	if(PlayerInfo[playerid][pLogin])
	    PlayerFile(playerid);
	
   	for(new i=0;i<MAX_PLAYERS;i++)
	if(PlayerInfo[i][spec]==playerid)
	{
		PlayerInfo[i][spec]=INVALID_PLAYER_ID;
		TogglePlayerSpectating(i,0);
	}
    pMuted[playerid] = 0;
    new name[MAX_PLAYER_NAME], string[39 + MAX_PLAYER_NAME];
    GetPlayerName(playerid,name,MAX_PLAYER_NAME);
    switch(reason)
    {
        case 0: format(string,sizeof string,"%s left the server. (Timed out)",name);
        case 1: format(string,sizeof string,"%s left the server. (Leaving)",name);
        case 2: format(string,sizeof string,"%s left the server. (Kicked/Banned)",name);
		case 3: format(string,sizeof string,"%s is being reloaded... (Server restart)",name);
    }
    ProxDetector(40.0, playerid, string,COLOR_GREY,COLOR_GREY,COLOR_GREY,COLOR_GREY,COLOR_GREY);
	
	for(new i; i < MAX_VEHICLES; i++)
	{
		if(VehicleInfo[i][vSpawner] == playerid)
		{
			SetTimerEx("VehicleDeath", 0, 0, "d", i);	
		}
	}
	
	LR_OnPlayerDisconnect(playerid);
	
    PlayersOnline--;
	format(string, sizeof(string), "Players online: %d", PlayersOnline);
	Log("playersonline", string);
	
	ResetPlayer(playerid);
	
	return 1;
}
//==============================================================================
public OnPlayerSpawn(playerid)
{
	if(PlayerInfo[playerid][pLogin])
		SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
	else
	    SetPlayerSkin(playerid, 71);
	//PlayerPlaySound(playerid, 1186, 0.0, 0.0, 0.0); // stop
	StopAudioStreamForPlayer(playerid);
	new factionid = PlayerInfo[playerid][faction];
	if(!factionid)
		SetPlayerVirtualWorld(playerid, 0);
	else
	{
	    //SetPlayerVirtualWorld(playerid, FactionInfo[factionid][fSpawnInt]);
	    SetPlayerPos(playerid, FactionInfo[factionid][fSpawnX], FactionInfo[factionid][fSpawnY], FactionInfo[factionid][fSpawnZ]);
	}
    freeze(playerid,0);
	SetPlayerColor(playerid, COLOR_SBLUE);
	GivePlayerMoney(playerid, 1000000-GetPlayerMoney(playerid));
	return 1;
}
//==============================================================================
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	LR_OnDialogResponse(playerid, dialogid, response, listitem);
	Login_OnDialogResponse(playerid, dialogid, response, inputtext);
	RadioStations_OnDialogResponse(playerid, dialogid, response, inputtext);
	
	switch(dialogid)
	{
	    case DIALOG_CARS:
	    {
	        if(!response)
	            return 1;

			if(GetPlayerInterior(playerid)!=0)
			    return SendClientMessage(playerid,COLOR_GREY,"You have to be outside!");
		    if(IsPlayerInAnyVehicle(playerid))
		        return SendClientMessage(playerid,COLOR_GREY,"Step out of the vehicle first!");
			new cmd[256], string[256];
			if(fexist("cars.txt"))
			{
	        	new File:hFile=fopen("cars.txt",io_read);
	        	new i;
				while(fread(hFile,string))
				{
	   				if(listitem == i)
					{
					    cmd=dini_PRIVATE_ExtractKey(string);
					    break;
					}
					i++;
				}
				fclose(hFile);
			}
			else
			    return SendClientMessage(playerid, COLOR_RED, "Could not read from the cars.txt file, please contact Lenny.");

			format(string,256,"cars/%s.txt",cmd);
			if(!fexist(string))
			    return SendClientMessage(playerid,COLOR_GREY,"Invalid type of car");
			if(PlayerInfo[playerid][pAdmin]<dini_Int(string,"admin"))
			    return error(playerid);
			for(new i; i < MAX_VEHICLES; i++)
			{
				if(VehicleInfo[i][vOwned] == true && VehicleInfo[i][vSpawner] == playerid)
				{
					SetTimerEx("VehicleDeath", 0, 0, "d", i);
				}
			}
			new Float:x, Float:y, Float:z, f, id;
			GetPlayerPos(playerid,x,y,z);
			if(dini_Isset(string,"color1"))
			    f=dini_Int(string,"color1");
			else
			    f=random(252);
			if(dini_Isset(string,"color2"))
			    id=dini_Int(string,"color2");
			else
			    id=random(252);
			new Float:angle;
	        GetPlayerFacingAngle(playerid, angle);
			id=CreateVehicle(dini_Int(string,"id"),x,y,z,angle,f,id,-1);
			new
				Name[2][MAX_PLAYER_NAME];
			sscanf(PlayerInfo[playerid][pName], "s[" #MAX_PLAYER_NAME "]s[" #MAX_PLAYER_NAME "]", Name[0], Name[1]);
			SetVehicleNumberPlate(id, Name[1]);
			SetVehicleToRespawn(id);
			SetVehicleVirtualWorld(id,GetPlayerVirtualWorld(playerid));
	        PutPlayerInVehicle(playerid,id,0);
	        PlayerInfo[playerid][pCarID]=id;
			VehicleInfo[PlayerInfo[playerid][pCarID]][vOwned] = true;
			VehicleInfo[PlayerInfo[playerid][pCarID]][vSpawner] = playerid;
			format(string,256,"(( %s just used the /cars command ))",PlayerInfo[playerid][pName]);
			return ProxDetector(50.0, playerid, string,COLOR_ME,COLOR_ME,COLOR_ME,COLOR_ME,COLOR_ME);
		}
		
	    case DIALOG_TELEPORTS:
	    {
	        if(!response)
	            return 1;

        	new File:hFile=fopen("teleports.txt",io_read),
				szString[500],
				szCMD[50],
				i,
				idx,
				e;
				
			while(fread(hFile,szString))
			{
   				if(listitem == i)
				{
				    szCMD=strtok(szString,idx);
				    break;
				}
				i++;
			}
			fclose(hFile);

			if(PlayerInfo[playerid][pAdmin]<strval(szCMD))
			    return error(playerid);
				
			new Float:pos[4];
			for(new k=0;k<4;k++)
			{
			    szCMD=strtok(szString,idx);
			    pos[k]=floatstr(szCMD);
			}
			
			e=strval(strtok(szString,idx));
			if(!IsPlayerInAnyVehicle(playerid)||e)
			{
				SetPlayerPos(playerid,pos[0],pos[1],pos[2]);
				SetPlayerFacingAngle(playerid,pos[3]);
	        	SetPlayerInterior(playerid,e);
			}
			else
			    SetVehiclePos(GetPlayerVehicleID(playerid),pos[0],pos[1],pos[2]);
			return 1;
		}
		
		case DIALOG_DEATHLIST:
		{
			if(!response)
				return 1;
				
			new
				szString[200];	
				
			format(szString, sizeof(szString), "Name: %s\nKiller: %s\nHow: %s\nTime: %s\nID: %d", DeathList[listitem][dlKilled], DeathList[listitem][dlKiller], GetDeathReasonString(DeathList[listitem][dlReason]), DeathList[listitem][dlTime], DeathList[listitem][dlID]);
			
			ShowPlayerDialog(playerid, DIALOG_EMPTY, DIALOG_STYLE_MSGBOX, "Death info", szString, "Cancel", "");
			
			return 1;
		}
	}
	return 1;
}


//==============================================================================
public OnPlayerDeath(playerid, killerid, reason)
{
	DeathList_Add(playerid, killerid, reason);
	
	new
		szString[128];
	
	format(szString, sizeof(szString), GetDeathReasonString(reason));
	
	if(killerid == INVALID_PLAYER_ID)
	{
		format(szString, sizeof(szString), "[DEATH] %s died (%s).", PlayerInfo[playerid][pName], szString);
	}
	else
	{
		format(szString, sizeof(szString), "[DEATH] %s killed %s with a %s.", PlayerInfo[killerid][pName], PlayerInfo[playerid][pName], szString);
	}
	
	print(szString);
	
	foreach(Player, i)
	{
		if(GetPVarInt(i, "TogDeath") == 1)
		{
			SendClientMessage(i, COLOR_GREY, szString);
		}
	}
	
	DeletePVar(playerid, "TazerWeapon");
	DeletePVar(playerid, "TazerAmmo");
	DeletePVar(playerid, "Tazer");
	
	if(GetPVarInt(playerid, "Racing"))
	{
		cmd_leave(playerid, "");
	}
	
	return 1;
}
//==============================================================================
public OnPlayerTakeDamage(playerid, issuerid, Float: amount, weaponid)
{
	if(weaponid == 23 && GetPVarInt(issuerid, "Tazer") == 1)
	{
		if(IsPlayerInAnyVehicle(playerid))
			return 1;
			
		new
			Float: fHealth,
			Float: fArmor;
		
		GetPlayerHealth(playerid, fHealth);
		GetPlayerArmour(playerid, fArmor);
		
		if(fArmor > 0.0)
		{
			SetPlayerArmour(playerid, fArmor + amount);
		}
		else
		{
			if(fHealth + amount > 100.0)
			{
				SetPlayerArmour(playerid, fHealth + amount - 100);
			}
			else
			{
				SetPlayerHealth(playerid, fHealth + amount);
			}
		}
		
		new
			Float: fPos[3];
			
		GetPlayerPos(playerid, fPos[0], fPos[1], fPos[2]);
		
		if(!IsPlayerInRangeOfPoint(issuerid, 12.0, fPos[0], fPos[1], fPos[2]))
		{
			return 1;
		}		
		
		new
			szString[18 + MAX_PLAYER_NAME * 2];
			
		format(szString, sizeof(szString), "%s was tazered by %s.", PlayerInfo[playerid][pName], PlayerInfo[issuerid][pName]);
		ProxDetector(30.0, playerid, szString, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME, COLOR_ME);
		
		TogglePlayerControllable(playerid, false);
		SetPlayerDrunkLevel(playerid, GetPlayerDrunkLevel(playerid) + 5000);
		
		SetTimerEx("TazerTimer", 10000, false, "i", playerid);
		
		ApplyAnimation(playerid, "PED", "FLOOR_hit_f", 4.0, 1, 0, 0, 0, 0);
	}
    return 1;
}
//==============================================================================
public TazerTimer(playerid)
{
	TogglePlayerControllable(playerid, true);
	SetPlayerDrunkLevel(playerid, GetPlayerDrunkLevel(playerid) - GetPVarInt(playerid, "DrunkTaze"));
	DeletePVar(playerid, "Tazed");
	DeletePVar(playerid, "DrunnkTaze");
}
//==============================================================================
public OnVehicleSpawn(vehicleid)
{
	return 1;
}
//==============================================================================
public OnVehicleDeath(vehicleid, killerid)
{
	SetTimerEx("VehicleDeath", 2000, 0, "d", vehicleid);
}
//==============================================================================
public OnPlayerText(playerid, text[])
{
	new string[168];
	
	if(!PlayerInfo[playerid][pLogin]&&!academy)
	{
	    SendClientMessage(playerid,COLOR_LIGHTRED,"You have to login!");
		return 1;
	}	
	
	if(pMuted[playerid])
	{
		SendClientMessage(playerid,COLOR_LIGHTRED,"You are muted!");
		return 1;
	}
		
    format(string, sizeof(string),"%s says: %s",PlayerInfo[playerid][pName],text);
    if(strlen(string) > 90)
    {
        new string2[146];
        strmid(string2, string, 90, sizeof(string));
        strdel(string, 90, sizeof(string));
		format(string, sizeof(string), "%s...", string);
		ProxDetector(20.0, playerid, string,COLOR_FADE1,COLOR_FADE2,COLOR_FADE3,COLOR_FADE4,COLOR_FADE5);
		ProxDetector(20.0, playerid, string2,COLOR_FADE1,COLOR_FADE2,COLOR_FADE3,COLOR_FADE4,COLOR_FADE5);
		return 0;
	}
    ProxDetector(20.0, playerid, string,COLOR_FADE1,COLOR_FADE2,COLOR_FADE3,COLOR_FADE4,COLOR_FADE5);
	return 0;
}
//==============================================================================
IsValidvehicleModel(model)
	return model >= 400 && model < 611;
//==============================================================================

#include <training/trainingcommands.pwn>

/*public OnPlayerCommandText(playerid, cmdtext[])
{
	return 1;
}*/

//==============================================================================
public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	for(new i=0;i<MAX_PLAYERS;i++)
	    if(PlayerInfo[i][spec]==playerid)
	    {
			SetPlayerInterior(i,newinteriorid);
			SetPlayerVirtualWorld(i,GetPlayerVirtualWorld(playerid));
		}
	return 1;
}
//==============================================================================
public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}
//==============================================================================
public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}
//==============================================================================
public OnPlayerStateChange(playerid, newstate, oldstate)
{
//-----------------Player Get In Car--------------------------------------------
	if(newstate==PLAYER_STATE_DRIVER||newstate==PLAYER_STATE_PASSENGER)
	{
		PlayerInfo[playerid][oldcar]=GetPlayerVehicleID(playerid);
		for(new i=0;i<MAX_PLAYERS;i++)
  			if(PlayerInfo[i][spec]==playerid)
		        PlayerSpectateVehicle(i,GetPlayerVehicleID(playerid));
	}
//----------------------Player Get out of car or died---------------------------
	if(newstate==PLAYER_STATE_ONFOOT||newstate==PLAYER_STATE_SPAWNED)
		for(new i=0;i<MAX_PLAYERS;i++)
		    if(PlayerInfo[i][spec]==playerid)
		        PlayerSpectatePlayer(i,playerid);
	return 1;
}
//==============================================================================
public OnPlayerEnterRaceCheckpoint(playerid)
{	
	LR_OnPlayerEnterRaceCheckpoint(playerid);
}
//==============================================================================
stock ProxDetector(Float:radi, playerid, string[],col1,col2,col3,col4,col5)
{
	new Float:posx, Float:posy, Float:posz;
	new Float:oldposx, Float:oldposy, Float:oldposz;
	new Float:tempposx, Float:tempposy, Float:tempposz;
	GetPlayerPos(playerid, oldposx, oldposy, oldposz);
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(IsPlayerConnected(i))
		{
			if(GetPVarInt(i, "Bigears"))
			{
				SendClientMessage(i,col1,string);
			}
			else
			{
				if(GetPlayerVirtualWorld(i)==GetPlayerVirtualWorld(playerid))
				{
					GetPlayerPos(i, posx, posy, posz);
					tempposx = (oldposx -posx);
					tempposy = (oldposy -posy);
					tempposz = (oldposz -posz);
					if (((tempposx < radi/16) && (tempposx > -radi/16)) && ((tempposy < radi/16) && (tempposy > -radi/16)) && ((tempposz < radi/16) && (tempposz > -radi/16)))
						SendClientMessage(i, col1, string);
					else if (((tempposx < radi/8) && (tempposx > -radi/8)) && ((tempposy < radi/8) && (tempposy > -radi/8)) && ((tempposz < radi/8) && (tempposz > -radi/8)))
						SendClientMessage(i, col2, string);
					else if (((tempposx < radi/4) && (tempposx > -radi/4)) && ((tempposy < radi/4) && (tempposy > -radi/4)) && ((tempposz < radi/4) && (tempposz > -radi/4)))
						SendClientMessage(i, col3, string);
					else if (((tempposx < radi/2) && (tempposx > -radi/2)) && ((tempposy < radi/2) && (tempposy > -radi/2)) && ((tempposz < radi/2) && (tempposz > -radi/2)))
						SendClientMessage(i, col4, string);
					else if (((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi)))
						SendClientMessage(i, col5, string);
				}
			}
		}
	}
	return 1;
}
stock ProxDetector2(Float:radi, playerid, string[],col1,col2,col3,col4,col5)
{
	new Float:posx, Float:posy, Float:posz;
	new Float:oldposx, Float:oldposy, Float:oldposz;
	new Float:tempposx, Float:tempposy, Float:tempposz;
	GetPlayerPos(playerid, oldposx, oldposy, oldposz);
	new factionid = PlayerInfo[playerid][faction];
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(IsPlayerConnected(i))
		{
	        if(PlayerInfo[i][faction] != factionid)
	        {
				if(GetPVarInt(i, "Bigears"))
				{
					SendClientMessage(i,col1,string);
				}
				else
	   			{
					if(GetPlayerVirtualWorld(i)==GetPlayerVirtualWorld(playerid))
					{
						GetPlayerPos(i, posx, posy, posz);
						tempposx = (oldposx -posx);
						tempposy = (oldposy -posy);
						tempposz = (oldposz -posz);
						if (((tempposx < radi/16) && (tempposx > -radi/16)) && ((tempposy < radi/16) && (tempposy > -radi/16)) && ((tempposz < radi/16) && (tempposz > -radi/16)))
							SendClientMessage(i, col1, string);
						else if (((tempposx < radi/8) && (tempposx > -radi/8)) && ((tempposy < radi/8) && (tempposy > -radi/8)) && ((tempposz < radi/8) && (tempposz > -radi/8)))
							SendClientMessage(i, col2, string);
						else if (((tempposx < radi/4) && (tempposx > -radi/4)) && ((tempposy < radi/4) && (tempposy > -radi/4)) && ((tempposz < radi/4) && (tempposz > -radi/4)))
							SendClientMessage(i, col3, string);
						else if (((tempposx < radi/2) && (tempposx > -radi/2)) && ((tempposy < radi/2) && (tempposy > -radi/2)) && ((tempposz < radi/2) && (tempposz > -radi/2)))
							SendClientMessage(i, col4, string);
						else if (((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi)))
							SendClientMessage(i, col5, string);
					}
				}
			}
		}
	}
	return 1;
}

stock LoadVehicles()
{
	print("  LoadVehicles initalized...");
	
	for(new i; i < MAX_VEHICLES; i++)
	{
		VehicleInfo[i][vOwned] = false;
		VehicleInfo[i][vSiren] = -1;
		VehicleInfo[i][vSpawner] = INVALID_PLAYER_ID;	
		VehicleInfo[i][vStatic] = false;
	}
}

stock LoadAuths()
{
	print("  LoadAuths initalized...");
	
	mysql_query("SELECT `key`,`level` FROM `auths` ORDER BY `level` DESC", THREAD_AUTHS);
}

stock LoadDeathList()
{
	print("  LoadDeathList initalized...");
	
	mysql_query("SELECT `id`,`killed`,`killer`,`reason`,`time` FROM `deathlist` ORDER BY `id` DESC LIMIT 12", THREAD_DEATHLIST);
}

stock LoadStaticCars()
{
	print("  LoadStaticCars initalized...");
	
	for(new i; i < MAX_STATIC_CARS; i++)
	{
		StaticCars[i][scVID] = INVALID_VEHICLE_ID;
	}
	
	mysql_query("SELECT id,model,x,y,z,angle,color1,color2 FROM static_vehicles", THREAD_STATIC_VEHICLES);
}

stock LoadEvents()
{
	print("  LoadEvents initalized...");

	new
		szQuery[63];
	
	format(szQuery, sizeof(szQuery), "SELECT id,time,info FROM events ORDER BY id DESC LIMIT %d", MAX_EVENTS);
	mysql_query(szQuery, THREAD_EVENTS);
}


stock ToggleStaticCars()
{
	if(StaticCarsSpawned == true)
	{
		for(new i; i < MAX_STATIC_CARS; i++)
		{
			if(StaticCars[i][scVID] == INVALID_VEHICLE_ID)
				break;
			SetTimerEx("VehicleDeath", 0, 0, "d", StaticCars[i][scVID]);
		}
		StaticCarsSpawned = false;
	}
	
	else
	{
		new
			iColors[2];
			
		for(new i; i < MAX_STATIC_CARS; i++)
		{	
			if(StaticCars[i][scDBID] == INVALID_VEHICLE_ID)
				break;
			
			if(StaticCars[i][scColor1] == -1)
			{
				iColors[0] = random(252);
			}
			else
			{
				iColors[0] = StaticCars[i][scColor1];
			}
			
			if(StaticCars[i][scColor2] == -1)
			{
				iColors[1] = random(252);
			}
			else
			{
				iColors[1] = StaticCars[i][scColor2];
			}
			
			StaticCars[i][scVID] = CreateVehicle(StaticCars[i][scModel], StaticCars[i][scX], StaticCars[i][scY], StaticCars[i][scZ], StaticCars[i][scAngle], iColors[0], iColors[1], 0);
			VehicleInfo[StaticCars[i][scVID]][vStatic] = true;
		}
		
		StaticCarsSpawned = true;
	}
}

stock DeathList_Add(killed, killer, weaponid)
{
	for(new i = MAX_DEATHLIST_ENTRIES - 1; i > 0; i--)
	{
		DeathList[i][dlID] = DeathList[i-1][dlID];
		format(DeathList[i][dlKilled], MAX_PLAYER_NAME, "%s", DeathList[i-1][dlKilled]);
		format(DeathList[i][dlKiller], MAX_PLAYER_NAME, DeathList[i-1][dlKiller]);
		DeathList[i][dlReason] = DeathList[i-1][dlReason];
		format(DeathList[i][dlTime], 12, DeathList[i-1][dlTime]);
	}	
	
	format(DeathList[0][dlKilled], MAX_PLAYER_NAME, PlayerInfo[killed][pName]);
	
	if(killer == INVALID_PLAYER_ID)
	{
		format(DeathList[0][dlKiller], MAX_PLAYER_NAME, "Noone");
	}
	else
	{
		format(DeathList[0][dlKiller], MAX_PLAYER_NAME, PlayerInfo[killer][pName]);
	}
	
	DeathList[0][dlReason] = weaponid;
	
	new
		szString[130],
		iTime[5];
		
	getdate(iTime[4], iTime[0], iTime[1]);
	gettime(iTime[2], iTime[3], iTime[4]);
	
	format(DeathList[0][dlTime], 12, "%02d:%02d %02d/%02d", iTime[2], iTime[3], iTime[0], iTime[1]);
		
	format(szString, sizeof(szString), "INSERT INTO deathlist (killed, killer, reason, time) VALUES ('%s','%s',%d,'%s')", DeathList[0][dlKilled], DeathList[0][dlKiller], DeathList[0][dlReason], DeathList[0][dlTime]);
	mysql_query(szString);
	
	DeathList[0][dlID] = mysql_insert_id();
}

stock GetDeathReasonString(reason)
{
	new
		szReason[21];
	
	switch(reason)
	{
		case 0:
			format(szReason, sizeof(szReason), "Unarmed");
		case 1:
			format(szReason, sizeof(szReason), "Brass Knuckles");
		case 2:
			format(szReason, sizeof(szReason), "Golf Club");
		case 3:
			format(szReason, sizeof(szReason), "Nite Stick");
		case 4:
			format(szReason, sizeof(szReason), "Knife");
		case 5:
			format(szReason, sizeof(szReason), "Baseball Bat");
		case 6:
			format(szReason, sizeof(szReason), "Shovel");
		case 7:
			format(szReason, sizeof(szReason), "Pool Cue");
		case 8:
			format(szReason, sizeof(szReason), "Katana");
		case 9:
			format(szReason, sizeof(szReason), "Chainsaw");
		case 10:
			format(szReason, sizeof(szReason), "Purple Dildo");
		case 11:
			format(szReason, sizeof(szReason), "Small White Vibrator");
		case 12:
			format(szReason, sizeof(szReason), "Large White Vibrator");
		case 13:
			format(szReason, sizeof(szReason), "Silver Vibrator");
		case 14:
			format(szReason, sizeof(szReason), "Flowers");
		case 15:
			format(szReason, sizeof(szReason), "Cane");
		case 16:
			format(szReason, sizeof(szReason), "Grenade");
		case 17:
			format(szReason, sizeof(szReason), "Tear Gas");
		case 18:
			format(szReason, sizeof(szReason), "Molotov Cocktail");
		case 22:
			format(szReason, sizeof(szReason), "9mm");
		case 23:
			format(szReason, sizeof(szReason), "Silenced 9mm");
		case 24:
			format(szReason, sizeof(szReason), "Desert Eagle");
		case 25:
			format(szReason, sizeof(szReason), "Shotgun");
		case 26:
			format(szReason, sizeof(szReason), "Sawn-off Shotgun");
		case 27:
			format(szReason, sizeof(szReason), "Combat Shotgun");
		case 28:
			format(szReason, sizeof(szReason), "Micro SMG");
		case 29:
			format(szReason, sizeof(szReason), "MP5");
		case 30:
			format(szReason, sizeof(szReason), "AK-47");
		case 31:
			format(szReason, sizeof(szReason), "M4");
		case 32:
			format(szReason, sizeof(szReason), "Tec9");
		case 33:
			format(szReason, sizeof(szReason), "Country Rifle");
		case 34:
			format(szReason, sizeof(szReason), "Sniper Rifle");
		case 35:
			format(szReason, sizeof(szReason), "Rocket Launcher");
		case 36:
			format(szReason, sizeof(szReason), "HS Rocket Launcher");
		case 37:
			format(szReason, sizeof(szReason), "Flamethrower");
		case 38:
			format(szReason, sizeof(szReason), "Minigun");
		case 39:
			format(szReason, sizeof(szReason), "Satchel Charge");
		case 40:
			format(szReason, sizeof(szReason), "Detonator");
		case 41:
			format(szReason, sizeof(szReason), "Spraycan");
		case 42:
			format(szReason, sizeof(szReason), "Fire Extinguisher");
		case 43:
			format(szReason, sizeof(szReason), "Camera");
		case 44:
			format(szReason, sizeof(szReason), "Nightvision Goggles");
		case 45:
			format(szReason, sizeof(szReason), "Thermal Goggles");
		case 46:
			format(szReason, sizeof(szReason), "Parachute");
		case 47:
			format(szReason, sizeof(szReason), "Fake Pistol");
		case 49:
			format(szReason, sizeof(szReason), "Vehicle");
		case 50:
			format(szReason, sizeof(szReason), "Helicopter Blades");
		case 51:
			format(szReason, sizeof(szReason), "Explosion");
		case 53:
			format(szReason, sizeof(szReason), "Drowned");
		case 54:
			format(szReason, sizeof(szReason), "Fell Down");
		case 200:
			format(szReason, sizeof(szReason), "Connect");
		case 201:
			format(szReason, sizeof(szReason), "Disconnect");
		case 255:
			format(szReason, sizeof(szReason), "Health Change");
		default:
			format(szReason, sizeof(szReason), "Unknown");
	}

	return szReason;
}

stock AttachObjectModelToVehicle(objectid, vehicleid, Float:fOffsetX, Float:fOffsetY, Float:fOffsetZ, Float:fRotX, Float:fRotY, Float:RotZ)
{
	VehicleInfo[vehicleid][vSiren] = CreateObject(objectid, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
	AttachObjectToVehicle(VehicleInfo[vehicleid][vSiren], vehicleid, fOffsetX, fOffsetY, fOffsetZ, fRotX, fRotY, RotZ);
}

stock ToggleVehicleEngine(vehicleid)
{
	new 
		engine, 
		lights, 
		alarm, 
		doors, 
		bonnet, 
		boot, 
		objective;
		
	GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
	
	if(engine == 1)
	{
		SetVehicleParamsEx(vehicleid, 0, 0, alarm, doors, bonnet, boot, objective);
		return 0;
	}
	else
	{
		SetVehicleParamsEx(vehicleid, 1, 1, alarm, doors, bonnet, boot, objective);
		return 1;
	}
}

stock InsertEvent(info[])
{
	mysql_real_escape_string(info, info);
	
	new
		szQuery[75 + 128];
	
	format(szQuery, sizeof(szQuery), "INSERT INTO events (time,info) VALUES (%d,'%s')", gettime(), info);
	mysql_query(szQuery);
	
	for(new i = MAX_EVENTS - 1; i < -1; i--)
	{
		Event[i][evID] = Event[i - 1][evID];
		Event[i][evTime] = Event[i - 1][evID];
		format(Event[i][evInfo], 128, Event[i - 1][evInfo]);
	}

	Event[0][evID] = mysql_insert_id();
	Event[0][evTime] = gettime();
	format(Event[0][evInfo], 128, info);	
}

stock ListPlayerEvents(playerid, sincetime)
{
	new
		iEventsListed;
		
	for(new i = MAX_EVENTS - 1; i > -1; i--)
	{
		if(Event[i][evTime] > sincetime)
		{
			SendClientMessage(playerid, COLOR_EVENT, Event[i][evInfo]);
			iEventsListed++;
		}
	}
	
	return iEventsListed;
}

Usage(playerid, usage[])
{
	new
		szUsage[128];
		
	format(szUsage, sizeof(szUsage), "{AFAFAF}USAGE: {FFFFFF}%s", usage);
	
	SendClientMessage(playerid, COLOR_GREY, szUsage);
}

public QueryError(query[], QueryError)
{
	printf("Re-sending query %s: %d", query, QueryError);
	mysql_query(query);
}

public OnQueryError(errorid, error[], resultid, extraid, callback[], query[], connectionHandle)
{
	QueryErrorID++;
	
	switch(errorid)
	{
		case CR_COMMAND_OUT_OF_SYNC:
		{
			printf("[MYSQL WARNING] Commands out of sync for thread ID: %d, query: %s, QueryErrorID: %d", resultid, query, QueryErrorID);
		}
		case ER_SYNTAX_ERROR:
		{
			printf("[MYSQL WARNING] Something is wrong in your syntax, query: %s", query);
		}
		case CR_SERVER_LOST: // 2013
		{
			printf("[MYSQL WARNING] Lost connection to MySQL server during query %s", query);
			SetTimerEx("QueryError", 1000, 0, "sd", query, QueryErrorID);
			printf("Re-sending query in 1000 ms, ref: %d", QueryErrorID);
		}
		case 1064: // Error in syntax
		{
			printf("[MYSQL WARNING] You have an error in your syntax in query: %s", query);
		}
		default:
		{
			printf("[MYSQL WARNING] Unknown MySQL Query error ID %d", errorid);
		}
	}
	
	return 1;
}

public OnQueryFinish(query[], resultid, extraid, connectionHandle)
{
	LR_OnQueryFinish(query, resultid, extraid, connectionHandle);
	
	switch(resultid)
	{
		case THREAD_STATIC_VEHICLES:
		{
			mysql_store_result();
			
			new
				i,
				szRow[80];
				
			while(mysql_fetch_row(szRow))
			{
				sscanf(szRow, "p<|>iiffffii", StaticCars[i][scDBID], StaticCars[i][scModel], StaticCars[i][scX], StaticCars[i][scY], StaticCars[i][scZ], StaticCars[i][scAngle], StaticCars[i][scColor1], StaticCars[i][scColor2]);
				i++;
			}
			mysql_free_result();
			
			while(i < MAX_STATIC_CARS)
			{
				StaticCars[i][scDBID] = INVALID_VEHICLE_ID;
				i++;
			}
			
			ToggleStaticCars();
		}
		
		case THREAD_DEATHLIST:
		{
			mysql_store_result();
			
			new
				i,
				szRow[5+MAX_PLAYER_NAME+MAX_PLAYER_NAME+MAX_WEAPON_NAME+7+5];
				
			while(mysql_fetch_row_format(szRow, "%"))
			{
				sscanf(szRow, "p<%>e<is[" #MAX_PLAYER_NAME "]s[" #MAX_PLAYER_NAME "]is[12]>", DeathList[i]);
				i++;
			}
			
			mysql_free_result();
			
			while(i < MAX_DEATHLIST_ENTRIES)
			{
				sscanf("-1%""%""%0%""", "p<%>e<is[" #MAX_PLAYER_NAME "]s[" #MAX_PLAYER_NAME "]is[12]>", DeathList[i]);
				i++;
			}		
		}
		
		case THREAD_AUTHS:
		{
			mysql_store_result();

			new
				szRow[MAX_AUTH_NAME + 5 + MAX_PLAYER_NAME],
				i;
			
			while(mysql_fetch_row_format(szRow, "|"))
			{
				sscanf(szRow, "p<|>s[" #MAX_AUTH_NAME "]i", Auth[i][authKey], Auth[i][authLevel]);
				i++;
			}
			
			mysql_free_result();
			
			while(i < MAX_AUTHS)
			{
				format(Auth[i][authKey], MAX_AUTH_NAME, "");
				Auth[i][authLevel] = -1;
				i++;
			}
		}
		case THREAD_EVENTS:
		{
			mysql_store_result();
			
			new
				szRow[200],
				i;
			
			while(mysql_fetch_row(szRow))
			{
				sscanf(szRow, "p<|>iis[128]", Event[i][evID], Event[i][evTime], Event[i][evInfo]);
				i++;
			}
			
			mysql_free_result();
		}
	}
}

/*stock SplitChatString(&string1[], &string2[])
{
	if(strlen(string1 > 121))
	{
		new
			temp_String[128];
			
		strmid(temp_String, string1, 0, 120);
		
		strmid(string2, string1, 121, 121 + strlen(string2));
		
		string1 = temp_String;
		
		return 1;
	}
	return 0;
}*/