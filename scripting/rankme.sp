#pragma semicolon  1
#define PLUGIN_VERSION "2.4.5"
#include <sourcemod> 
#include <colors>
#include <rankme>
#define MSG "\x04[RankMe]: \x01"
#define SPEC 1
#define TR 2
#define CT 3

new String:sql_criar[] = "CREATE TABLE IF NOT EXISTS rankme (id INTEGER PRIMARY KEY, steam TEXT, name TEXT, lastip TEXT, score NUMERIC, kills NUMERIC, deaths NUMERIC, suicides NUMERIC, tk NUMERIC, shots NUMERIC, hits NUMERIC, headshots NUMERIC, connected NUMERIC, rounds_tr NUMERIC, rounds_ct NUMERIC, lastconnect NUMERIC,knife NUMERIC,glock NUMERIC,usp NUMERIC,p228 NUMERIC,deagle NUMERIC,elite NUMERIC,fiveseven NUMERIC,m3 NUMERIC,xm1014 NUMERIC,mac10 NUMERIC,tmp NUMERIC,mp5navy NUMERIC,ump45 NUMERIC,p90 NUMERIC,galil NUMERIC,ak47 NUMERIC,sg550 NUMERIC,famas NUMERIC,m4a1 NUMERIC,aug NUMERIC,scout NUMERIC,sg552 NUMERIC,awp NUMERIC,g3sg1 NUMERIC,m249 NUMERIC,hegrenade NUMERIC,flashbang NUMERIC,smokegrenade NUMERIC, head NUMERIC, chest NUMERIC, stomach NUMERIC, left_arm NUMERIC, right_arm NUMERIC, left_leg NUMERIC, right_leg NUMERIC,c4_planted NUMERIC,c4_exploded NUMERIC,c4_defused NUMERIC,ct_win NUMERIC, tr_win NUMERIC, hostages_rescued NUMERIC, vip_killed NUMERIC, vip_escaped NUMERIC, vip_played NUMERIC)";
new String:sql_iniciar[] = "INSERT INTO rankme VALUES (NULL,'%s','%s','%s','%d','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0');";
new String:sql_salvar[] = "UPDATE rankme SET score = '%i', kills = '%i', deaths='%i',suicides='%i',tk='%i',shots='%i',hits='%i',headshots='%i', rounds_tr = '%i', rounds_ct = '%i',lastip='%s',name='%s'%s,head='%i',chest='%i', stomach='%i',left_arm='%i',right_arm='%i',left_leg='%i',right_leg='%i',c4_planted='%i',c4_exploded='%i',c4_defused='%i',ct_win='%i',tr_win='%i', hostages_rescued='%i',vip_killed = '%d',vip_escaped = '%d',vip_played = '%d' WHERE steam = '%s';";
new String:sql_salvar_name[] = "UPDATE rankme SET score = '%i', kills = '%i', deaths='%i',suicides='%i',tk='%i',shots='%i',hits='%i',headshots='%i', rounds_tr = '%i', rounds_ct = '%i',lastip='%s',name='%s'%s,head='%i',chest='%i', stomach='%i',left_arm='%i',right_arm='%i',left_leg='%i',right_leg='%i',c4_planted='%i',c4_exploded='%i',c4_defused='%i',ct_win='%i',tr_win='%i', hostages_rescued='%i',vip_killed = '%d',vip_escaped = '%d',vip_played = '%d' WHERE name = '%s';";
new String:sql_connects[] = "UPDATE rankme SET lastconnect='%i', connected='%i' WHERE steam = '%s';";
new String:sql_connects_name[] = "UPDATE rankme SET lastconnect='%i', connected='%i' WHERE name = '%s';";
new String:sql_retrieveclient[] = "SELECT * FROM rankme WHERE steam='%s';";
new String:sql_retrieveclient_name[] = "SELECT * FROM rankme WHERE name='%s';";
new String:sql_removeduplicate[] = "delete from rankme where rankme.id > (SELECT min(id) from rankme as t2 WHERE t2.steam=rankme.steam);";
new String:sql_removeduplicate_name[] = "delete from rankme where rankme.id > (SELECT min(id) from rankme as t2 WHERE t2.name=rankme.name);";
new String:weapons_names[28][] = {"knife","glock","usp","p228","deagle","elite","fiveseven","m3","xm1014","mac10","tmp","mp5navy","ump45","p90","galil","ak47","sg550","famas","m4a1","aug","scout","sg552","awp","g3sg1","m249","hegrenade","flashbang","smokegrenade"};
new String:weapons_names1[28][] = {"Knife"," 9x19 mm Sidearm (Glock)","KM .45 Tactical (USP)","228 Compact","Knighthawk .50C (Desert Eagle)",".40 Dual Elites","ES Five-Seven","Leone 12 Gauge Super","Leone YG1265 Auto Shotgun","Ingram MAC-10","Schmidt Machine Pistol (TMP)","KM Submachine Gun (MP5)","KM UMP45","ES C90 (P90)","IDF Defender","CV-47 (AK-47)","Kreig 550 Commando (SG550)","Clarion 5.56","Maverick M4A1 Carbine (Colt)","Bullpup (AUG)","Schmidt Scout","Kreig 552","Magnum Sniper Rifle (AWP)","D3/AU-1 (G3)","M249","HE Grenade","Flashbang","Smoke Grenade"};
new Handle:cvar_enabled;
new Handle:cvar_chatchange;
new Handle:cvar_rankbots;
new Handle:cvar_silenttrigger;
new Handle:cvar_autopurge;
new Handle:cvar_points_bomb_defused_team;
new Handle:cvar_points_bomb_defused_player;
new Handle:cvar_points_bomb_planted_team;
new Handle:cvar_points_bomb_planted_player;
new Handle:cvar_points_bomb_explode_team;
new Handle:cvar_points_bomb_explode_player;
new Handle:cvar_points_hostage_resc_team;
new Handle:cvar_points_hostage_resc_player;
new Handle:cvar_points_vip_escaped_team;
new Handle:cvar_points_vip_escaped_player;
new Handle:cvar_points_vip_killed_team;
new Handle:cvar_points_vip_killed_player;
new Handle:cvar_points_hs;
new Handle:cvar_points_kill_ct;
new Handle:cvar_points_kill_tr;
new Handle:cvar_points_kill_bonus_ct;
new Handle:cvar_points_kill_bonus_tr;
new Handle:cvar_points_kill_bonus_dif_ct;
new Handle:cvar_points_kill_bonus_dif_tr;
new Handle:cvar_points_start;
new Handle:cvar_points_knife_multiplier;
new Handle:cvar_points_tr_round_win;
new Handle:cvar_points_ct_round_win;
new Handle:cvar_minimal_kills;
new Handle:cvar_percent_points_lose;
new Handle:cvar_points_lose_round_ceil;
new Handle:cvar_show_rank_all;
new Handle:cvar_resetownrank;
new Handle:cvar_minimumplayers;
new Handle:cvar_vip_enabled;
new Handle:cvar_points_lose_tk;
new Handle:cvar_points_lose_suicide;
new Handle:cvar_show_bots_on_rank;
new Handle:cvar_rankbyname;
new Handle:cvar_ffa;
new Handle:cvar_mysql;

new bool:g_enabled;
new bool:g_rankbyname;
new bool:g_resetownrank;
new bool:g_chatchange;
new bool:g_rankbots;
new bool:g_silenttrigger;
new bool:g_points_lose_round_ceil;
new bool:g_show_rank_all;
new bool:g_vip_enabled;
new bool:g_show_bots_on_rank;
new bool:g_ffa;
new bool:g_mysql;
new g_points_bomb_defused_team;
new g_points_bomb_defused_player;
new g_points_bomb_planted_team;
new g_points_bomb_planted_player;
new g_points_bomb_explode_team;
new g_points_bomb_explode_player;
new g_points_hostage_resc_team;
new g_points_hostage_resc_player;
new g_points_hs;
// Size = 4 -> for using client team for points
new g_points_kill[4];
new g_points_kill_bonus[4];
new g_points_kill_bonus_dif[4];
new g_minimal_kills;
new g_points_start;
new Float:g_points_knife_multiplier;
new Float:g_percent_points_lose;
new g_points_round_win[4];
new g_minimumplayers;
new g_points_lose_tk;
new g_points_lose_suicide;
new g_points_vip_escaped_team;
new g_points_vip_escaped_player;
new g_points_vip_killed_team;
new g_points_vip_killed_player;

new Handle:stats_db;
new bool:OnDB[MAXPLAYERS+1];
new session[MAXPLAYERS+1][STATS_NAMES];
new stats[MAXPLAYERS+1][STATS_NAMES];
new weapons[MAXPLAYERS+1][WEAPONS_ENUM];
new hitbox[MAXPLAYERS+1][HITBOXES];
new total_players;


new bool:DEBUGGING=false;
new c4_planted_by;
new String:c4_planted_by_name[MAX_NAME_LENGTH];
#include rankme/cmds

public Plugin:myinfo = {
	name = "RankMe",
	author = "lok1",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};
// Body Parts

public OnPluginStart(){

	
	cvar_enabled = CreateConVar("rankme_enabled","1","Is RankMe enabled? 1 = true 0 = false",_,true,0.0,true,1.0);
	cvar_rankbots = CreateConVar("rankme_rankbots","0","Rank bots? 1 = true 0 = false",_,true,0.0,true,1.0);
	cvar_silenttrigger = CreateConVar("rankme_silenttriggers","0","Silent triggers? 1 = true 0 = false",_,true,0.0,true,1.0);
	cvar_autopurge = CreateConVar("rankme_autopurge","0","Auto-Purge inactive players? X = Days  0 = Off",_,true,0.0);
	cvar_points_bomb_defused_team = CreateConVar("rankme_points_bomb_defused_team","2","How many points CTs got for defusing the C4?",_,true,0.0);
	cvar_points_bomb_defused_player = CreateConVar("rankme_points_bomb_defused_player","2","How many points the CT who defused got additional?",_,true,0.0);
	cvar_points_bomb_planted_team = CreateConVar("rankme_points_bomb_planted_team","2","How many points TRs got for planting the C4?",_,true,0.0);
	cvar_points_bomb_planted_player = CreateConVar("rankme_points_bomb_planted_player","2","How many points the TR who planted got additional?",_,true,0.0);
	cvar_points_bomb_explode_team = CreateConVar("rankme_points_bomb_exploded_team","2","How many points TRs got for exploding the C4?",_,true,0.0);
	cvar_points_bomb_explode_player = CreateConVar("rankme_points_bomb_exploded_player","2","How many points the TR who planted got additional?",_,true,0.0);
	cvar_points_hostage_resc_team = CreateConVar("rankme_points_hostage_rescued_team","2","How many points CTs got for rescuing the hostage?",_,true,0.0);
	cvar_points_hostage_resc_player = CreateConVar("rankme_points_hostage_rescued_player","2","How many points the CT who rescued got additional?",_,true,0.0);
	cvar_points_hs = CreateConVar("rankme_points_hs","1","How many additional points a player got for a HeadShot?",_,true,0.0);
	cvar_points_kill_ct = CreateConVar("rankme_points_kill_ct","2","How many points a CT got for killing?",_,true,0.0);
	cvar_points_kill_tr = CreateConVar("rankme_points_kill_tr","2","How many points a TR got for killing?",_,true,0.0);
	cvar_points_kill_bonus_ct = CreateConVar("rankme_points_kill_bonus_ct","1","How many points a CT got for killing additional by the diffrence of points?",_,true,0.0);
	cvar_points_kill_bonus_tr = CreateConVar("rankme_points_kill_bonus_tr","1","How many points a TR got for killing additional by the diffrence of points?",_,true,0.0);
	cvar_points_kill_bonus_dif_ct = CreateConVar("rankme_points_kill_bonus_dif_ct","100","How many points of diffrence is needed for a CT to got the bonus?",_,true,0.0);
	cvar_points_kill_bonus_dif_tr = CreateConVar("rankme_points_kill_bonus_dif_tr","100","How many points of diffrence is needed for a TR to got the bonus?",_,true,0.0);
	cvar_points_ct_round_win = CreateConVar("rankme_points_ct_round_win","0","How many points an alive CT got for winning the round?",_,true,0.0);
	cvar_points_tr_round_win = CreateConVar("rankme_points_tr_round_win","0","How many points an alive TR got for winning the round?",_,true,0.0);
	cvar_points_knife_multiplier = CreateConVar("rankme_points_knife_multiplier","2.0","Multiplier of points by knife",_,true,0.0);
	cvar_points_start = CreateConVar("rankme_points_start","1000","Starting points",_,true,0.0);
	cvar_minimal_kills = CreateConVar("rankme_minimal_kills","0","Minimal kills for entering the rank",_,true,0.0);
	cvar_percent_points_lose = CreateConVar("rankme_percent_points_lose","1.0","Multiplier of losing points. (WARNING: MAKE SURE TO INPUT IT AS FLOAT) 1.0 equals lose same amount as won by the killer, 0.0 equals no lose",_,true,0.0);
	cvar_points_lose_round_ceil = CreateConVar("rankme_points_lose_round_ceil","1","If the points is f1oat, round it to next the highest or lowest? 1 = highest 0 = lowest",_,true,0.0,true,1.0);
	cvar_chatchange = CreateConVar("rankme_changes_chat","1","Show points changes on chat? 1 = true 0 = false",_,true,0.0,true,1.0);
	cvar_show_rank_all = CreateConVar("rankme_show_rank_all","0","When rank command is used, show for all the rank of the player? 1 = true 0 = false",_,true,0.0,true,1.0);
	cvar_show_bots_on_rank = CreateConVar("rankme_show_bots_on_rank","0","Show bots on rank/top/etc? 1 = true 0 = false",_,true,0.0,true,1.0);
	cvar_resetownrank = CreateConVar("rankme_resetownrank","0","Allow player to reset his own rank? 1 = true 0 = false",_,true,0.0,true,1.0);
	cvar_minimumplayers = CreateConVar("rankme_minimumplayers","2","Minimum players to start giving points",_,true,0.0);
	cvar_vip_enabled = CreateConVar("rankme_vip_enabled","0","Show AS_ maps statiscs (VIP mod) on statsme and session?",_,true,0.0,true,1.0);
	cvar_points_vip_escaped_team = CreateConVar("rankme_points_vip_escaped_team","2","How many points CTs got helping the VIP to escaping?",_,true,0.0);
	cvar_points_vip_escaped_player = CreateConVar("rankme_points_vip_escaped_player","2","How many points the VIP got for escaping?",_,true,0.0);
	cvar_points_vip_killed_team = CreateConVar("rankme_points_vip_killed_team","2","How many points TRs got for killing the VIP?",_,true,0.0);
	cvar_points_vip_killed_player = CreateConVar("rankme_points_vip_killed_player","2","How many points the TR who killed the VIP got additional?",_,true,0.0);
	cvar_points_lose_tk = CreateConVar("rankme_points_lose_tk","0","How many points a player lose for Team Killing?",_,true,0.0);
	cvar_points_lose_suicide = CreateConVar("rankme_points_lose_suicide","0","How many points a player lose for Suiciding?",_,true,0.0);
	cvar_rankbyname = CreateConVar("rankme_rank_by_name","0","Rank players by name? 1 = true 0 = false",_,true,0.0,true,1.0);
	cvar_ffa = CreateConVar("rankme_ffa","0","FFA mode? 1 = true 0 = false",_,true,0.0,true,1.0);
	cvar_mysql = CreateConVar("rankme_mysql","0","Using MySQL? 1 = true 0 = false (SQLite)",_,true,0.0,true,1.0);
	
	AutoExecConfig(true,"rankme");
	
	HookConVarChange(cvar_enabled,OnConVarChanged);
	HookConVarChange(cvar_chatchange,OnConVarChanged);
	HookConVarChange(cvar_show_bots_on_rank,OnConVarChanged);
	HookConVarChange(cvar_show_rank_all,OnConVarChanged);
	HookConVarChange(cvar_resetownrank,OnConVarChanged);
	HookConVarChange(cvar_minimumplayers,OnConVarChanged);
	HookConVarChange(cvar_rankbots,OnConVarChanged);
	HookConVarChange(cvar_silenttrigger,OnConVarChanged);
	HookConVarChange(cvar_autopurge,OnConVarChanged);
	HookConVarChange(cvar_points_bomb_defused_team,OnConVarChanged);
	HookConVarChange(cvar_points_bomb_defused_player,OnConVarChanged);
	HookConVarChange(cvar_points_bomb_planted_team,OnConVarChanged);
	HookConVarChange(cvar_points_bomb_planted_player,OnConVarChanged);
	HookConVarChange(cvar_points_bomb_explode_team,OnConVarChanged);
	HookConVarChange(cvar_points_bomb_explode_player,OnConVarChanged);
	HookConVarChange(cvar_points_hostage_resc_team,OnConVarChanged);
	HookConVarChange(cvar_points_hostage_resc_player,OnConVarChanged);
	HookConVarChange(cvar_points_hs,OnConVarChanged);
	HookConVarChange(cvar_points_kill_ct,OnConVarChanged);
	HookConVarChange(cvar_points_kill_tr,OnConVarChanged);
	HookConVarChange(cvar_points_kill_bonus_ct,OnConVarChanged);
	HookConVarChange(cvar_points_kill_bonus_tr,OnConVarChanged);
	HookConVarChange(cvar_points_kill_bonus_dif_ct,OnConVarChanged);
	HookConVarChange(cvar_points_kill_bonus_dif_tr,OnConVarChanged);
	HookConVarChange(cvar_points_ct_round_win,OnConVarChanged);
	HookConVarChange(cvar_points_tr_round_win,OnConVarChanged);
	HookConVarChange(cvar_points_knife_multiplier,OnConVarChanged);
	HookConVarChange(cvar_points_start,OnConVarChanged);
	HookConVarChange(cvar_minimal_kills,OnConVarChanged);
	HookConVarChange(cvar_percent_points_lose,OnConVarChanged);
	HookConVarChange(cvar_points_lose_round_ceil,OnConVarChanged);
	HookConVarChange(cvar_vip_enabled,OnConVarChanged);
	HookConVarChange(cvar_points_vip_escaped_team,OnConVarChanged);
	HookConVarChange(cvar_points_vip_escaped_player,OnConVarChanged);
	HookConVarChange(cvar_points_vip_killed_team,OnConVarChanged);
	HookConVarChange(cvar_points_vip_killed_player,OnConVarChanged);
	HookConVarChange(cvar_points_lose_tk,OnConVarChanged);
	HookConVarChange(cvar_points_lose_suicide,OnConVarChanged);
	HookConVarChange(cvar_rankbyname,OnConVarChanged);
	HookConVarChange(cvar_ffa,OnConVarChanged);
	HookConVarChange(cvar_mysql,OnConVarChanged_MySQL);
		
	LoadTranslations("rankme.phrases");
	
	HookEvent("player_death",	EventPlayerDeath);
	HookEvent("player_spawn",	EventPlayerSpawn);
	HookEvent("player_hurt",	EventPlayerHurt);
	HookEvent("weapon_fire", EventWeaponFire);
	
	HookEvent( "bomb_planted", Event_BombPlanted );
	HookEvent( "bomb_defused", Event_BombDefused );
	HookEvent( "bomb_exploded", Event_BombExploded );
	
	HookEvent( "hostage_rescued", Event_HostageRescued );
	
	HookEvent( "vip_killed", Event_VipKilled );
	HookEvent( "vip_escaped", Event_VipEscaped );
	
	HookEvent("round_end", Event_RoundEnd);

	HookEvent("player_changename", OnClientChangeName, EventHookMode_Pre);
	// SESSION
	RegConsoleCmd("session",CMD_Session);
	
	RegConsoleCmd("rank",CMD_Rank);
	
	RegConsoleCmd("top",CMD_Top);
	RegConsoleCmd("topknife",CMD_TopKnife);
	RegConsoleCmd("topnade",CMD_TopNade);
	RegConsoleCmd("topweapon",CMD_TopWeapon);
	
	RegConsoleCmd("hitboxme",CMD_HitBox);
	
	RegConsoleCmd("weaponme",CMD_WeaponMe);
	
	RegAdminCmd("resetrank",CMD_ResetRank,ADMFLAG_ROOT);
	RegAdminCmd("rankme_remove_duplicate",CMD_Duplicate,ADMFLAG_ROOT);
	RegAdminCmd("rankpurge",CMD_Purge,ADMFLAG_ROOT);
	RegAdminCmd("resetrank_all",CMD_ResetRankAll,ADMFLAG_ROOT);
	RegAdminCmd("rankme_import_mani",CMD_ManiImport,ADMFLAG_ROOT);
	RegConsoleCmd("resetmyrank",CMD_ResetOwnRank);
	
	RegConsoleCmd("statsme",CMD_StatsMe);

	RegConsoleCmd("sm_next",CMD_Next);
	
	RegConsoleCmd("say", Command_SayChat);
	RegConsoleCmd("say_team", Command_SayChat);
	
	new Handle:version = CreateConVar("rankme_version",PLUGIN_VERSION,"RankMe Version",FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(version,PLUGIN_VERSION,true,true);
	
	
}
public OnConVarChanged_MySQL(Handle:convar, const String:oldValue[], const String:newValue[]){
	DB_Connect(false);
}

public DB_Connect(bool:firstload){
	
	if(g_mysql != GetConVarBool(cvar_mysql) || firstload){
		g_mysql = GetConVarBool(cvar_mysql);
		decl String:error[256];
		if(g_mysql){
			stats_db = SQL_Connect("rankme", false, error, sizeof(error));
		} else {
			stats_db = SQLite_UseDatabase("rankme",error,sizeof(error));
		}
		if(stats_db == INVALID_HANDLE)
		{
			SetFailState("[RankMe] Unable to connect to the database (%s)",error);
		}
		SQL_LockDatabase(stats_db);
		SQL_FastQuery(stats_db,sql_criar);
		SQL_FastQuery(stats_db,"ALTER TABLE rankme MODIFY id INTEGER AUTO_INCREMENT");
		SQL_FastQuery(stats_db,"ALTER TABLE rankme ADD COLUMN vip_killed NUMERIC");
		SQL_FastQuery(stats_db,"ALTER TABLE rankme ADD COLUMN vip_escaped NUMERIC");
		SQL_FastQuery(stats_db,"ALTER TABLE rankme ADD COLUMN vip_played NUMERIC");
		SQL_UnlockDatabase(stats_db);
		
		for(new i=1;i<=MaxClients;i++){
			if(IsClientInGame(i))
				OnClientPutInServer(i);
		}
	}

}
public OnConfigsExecuted(){
	if(stats_db == INVALID_HANDLE)
		DB_Connect(true);
	else
		DB_Connect(false);
	new autopurge = GetConVarInt(cvar_autopurge);
	if(autopurge > 0){
		new deletebefore = GetTime() - (autopurge*86400);
		new String:query[100];
		Format(query,sizeof(query),"DELETE FROM rankme WHERE lastconnect < '%d'",deletebefore);
		SQL_TQuery(stats_db,SQL_PurgeCallback,query);
	}
	
	g_show_bots_on_rank = GetConVarBool(cvar_show_bots_on_rank);
	g_rankbyname = GetConVarBool(cvar_rankbyname);
	g_enabled = GetConVarBool(cvar_enabled);
	g_chatchange = GetConVarBool(cvar_chatchange);
	g_show_rank_all = GetConVarBool(cvar_show_rank_all);
	g_rankbots = GetConVarBool(cvar_rankbots);
	g_silenttrigger = GetConVarBool(cvar_silenttrigger);
	g_ffa = GetConVarBool(cvar_ffa);
	g_points_bomb_defused_team = GetConVarInt(cvar_points_bomb_defused_team);
	g_points_bomb_defused_player = GetConVarInt(cvar_points_bomb_defused_player);
	g_points_bomb_planted_team = GetConVarInt(cvar_points_bomb_planted_team);
	g_points_bomb_planted_player = GetConVarInt(cvar_points_bomb_planted_player);
	g_points_bomb_explode_team = GetConVarInt(cvar_points_bomb_explode_team);
	g_points_bomb_explode_player = GetConVarInt(cvar_points_bomb_explode_player);
	g_points_hostage_resc_team = GetConVarInt(cvar_points_hostage_resc_team);
	g_points_hostage_resc_player = GetConVarInt(cvar_points_hostage_resc_player);
	g_points_hs = GetConVarInt(cvar_points_hs);
	g_points_kill[CT] = GetConVarInt(cvar_points_kill_ct);
	g_points_kill[TR] = GetConVarInt(cvar_points_kill_tr);
	g_points_kill_bonus[CT] = GetConVarInt(cvar_points_kill_bonus_ct);
	g_points_kill_bonus[TR] = GetConVarInt(cvar_points_kill_bonus_tr);
	g_points_kill_bonus_dif[CT] = GetConVarInt(cvar_points_kill_bonus_dif_ct);
	g_points_kill_bonus_dif[TR] = GetConVarInt(cvar_points_kill_bonus_dif_tr);
	g_points_start = GetConVarInt(cvar_points_start);
	g_points_knife_multiplier = GetConVarFloat(cvar_points_knife_multiplier);
	g_points_round_win[TR] = GetConVarInt(cvar_points_tr_round_win);
	g_points_round_win[CT] = GetConVarInt(cvar_points_ct_round_win);
	g_minimal_kills = GetConVarInt(cvar_minimal_kills);
	g_percent_points_lose = GetConVarFloat(cvar_percent_points_lose);
	g_points_lose_round_ceil = GetConVarBool(cvar_points_lose_round_ceil);
	g_minimumplayers = GetConVarInt(cvar_minimumplayers);
	g_resetownrank = GetConVarBool(cvar_resetownrank);
	g_points_vip_escaped_team = GetConVarInt(cvar_points_vip_escaped_team);
	g_points_vip_escaped_player = GetConVarInt(cvar_points_vip_escaped_player);
	g_points_vip_killed_team = GetConVarInt(cvar_points_vip_killed_team);
	g_points_vip_killed_player = GetConVarInt(cvar_points_vip_killed_player);
	g_vip_enabled = GetConVarBool(cvar_vip_enabled);
	g_points_lose_tk = GetConVarInt(cvar_points_lose_tk);
	g_points_lose_suicide = GetConVarInt(cvar_points_lose_suicide);
	new String:query[500];
	if(g_rankbots)
		Format(query,sizeof(query),"SELECT * FROM rankme WHERE kills >= '%d'",g_minimal_kills);
	else
		Format(query,sizeof(query),"SELECT * FROM rankme WHERE kills >= '%d' AND steam <> 'BOT'",g_minimal_kills);
	SQL_TQuery(stats_db,SQL_GetPlayersCallback,query);
	
}
public Action:CMD_Duplicate(client,args){
	if(!g_rankbyname)
		SQL_TQuery(stats_db,SQL_DuplicateCallback,sql_removeduplicate);
	else
		SQL_TQuery(stats_db,SQL_DuplicateCallback,sql_removeduplicate_name);
	
}

public SQL_DuplicateCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[RankMe] Query Fail: %s", error);
		return;
	}
	
	PrintToServer("[RankMe]: %d duplicated rows removed",SQL_GetAffectedRows(owner));
	if(client != 0){
		PrintToChat(client,"[RankMe]: %d duplicated rows removed",SQL_GetAffectedRows(owner));
	}
	//LogAction(-1,-1,"[RankMe]: %d players purged by inactivity",SQL_GetAffectedRows(owner));
	
}

public Action:CMD_ManiImport(client,args){
	new String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "../../cfg/mani_admin_plugin/data/mani_ranks.txt");
	new Handle:hFile = OpenFile(file,"r");
	new String:buffer[600];
	new String:data[65][MAX_NAME_LENGTH];
	new String:query[1500];
	while (!IsEndOfFile(hFile)){
		buffer = "";
		ReadFileLine(hFile,buffer,sizeof(buffer));
		
		
		if(StrContains(buffer,"/") == 0 || strlen(buffer) == 0){} else {
			ExplodeString(buffer,",",data,65,MAX_NAME_LENGTH);
			Format(query,sizeof(query),"INSERT INTO rankme (id,steam,name,lastip,score) SELECT NULL,'%s','%s','%s','%d' WHERE NOT EXISTS (SELECT 1 FROM rankme WHERE steam = '%s')",data[0],data[64],data[01],g_points_start,data[0]);
			
			ReplaceString(query,sizeof(query),"\n","");
			SQL_TQuery(stats_db,SQL_NothingCallback,query);
		
			client =0;
			
			
			new String:weapons_query[500] = "";
			
			weapons[client][0]=StringToInt(data[29]);
			weapons[client][1]=StringToInt(data[37]);
			weapons[client][2]=StringToInt(data[24]);
			weapons[client][3]=StringToInt(data[45]);
			weapons[client][4]=StringToInt(data[25]);
			weapons[client][5]=StringToInt(data[42]);
			weapons[client][6]=StringToInt(data[44]);
			weapons[client][7]=StringToInt(data[33]);
			weapons[client][8]=StringToInt(data[28]);
			weapons[client][9]=StringToInt(data[43]);
			weapons[client][10]=StringToInt(data[38]);
			weapons[client][11]=StringToInt(data[22]);
			weapons[client][12]=StringToInt(data[39]);
			weapons[client][13]=StringToInt(data[40]);
			weapons[client][14]=StringToInt(data[32]);
			weapons[client][15]=StringToInt(data[20]);
			weapons[client][16]=StringToInt(data[31]);
			weapons[client][17]=StringToInt(data[36]);
			weapons[client][18]=StringToInt(data[21]);
			weapons[client][19]=StringToInt(data[26]);
			weapons[client][20]=StringToInt(data[34]);
			weapons[client][21]=StringToInt(data[35]);
			weapons[client][22]=StringToInt(data[23]);
			weapons[client][23]=StringToInt(data[30]);
			weapons[client][24]=StringToInt(data[41]);
			weapons[client][25]=StringToInt(data[27]);
			weapons[client][26]=StringToInt(data[46]);
			weapons[client][27]=StringToInt(data[47]);
			for(new i=0;i<=27;i++){
				Format(weapons_query,sizeof(weapons_query),"%s,%s='%d'",weapons_query,weapons_names[i],weapons[client][i]);
			}
			Format(query,sizeof(query),"UPDATE rankme SET score = '%s', kills = '%s', deaths='%s',suicides='%s',tk='%s',shots='%s',hits='%s',headshots='%s', rounds_tr = '%d', rounds_ct = '%d',lastip='%s',name='%s'%s,head='%s',chest='%s', stomach='%s',left_arm='%s',right_arm='%s',left_leg='%s',right_leg='%s',c4_planted='%s',c4_exploded='%s',c4_defused='%s',ct_win='%s',tr_win='%s', hostages_rescued='%s',vip_killed = '%s',vip_escaped = '%s',vip_played = '%s' WHERE steam = '%s';",data[04],data[07],data[5],data[8],data[9],data[48],data[49],data[06],StringToInt(data[62])+StringToInt(data[63]),StringToInt(data[60])+StringToInt(data[61]),data[01],data[64],weapons_query,data[13],data[14],data[15],data[16],data[17],data[18],data[19],data[50],data[55],data[51],data[60],data[62],data[52],data[59],data[58],data[58],data[0]);
			ReplaceString(query,sizeof(query),"\n","");
			SQL_TQuery(stats_db,SQL_NothingCallback,query);
	
			Format(query,sizeof(query),sql_connects,StringToInt(data[2]),StringToInt(data[10]),data[0]);
			SQL_TQuery(stats_db,SQL_NothingCallback,query);
	
		}
		
	}
	for(new d=1;d<=MaxClients;d++){
		if(IsClientInGame(d))
			OnClientPutInServer(d);
	}
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("RankMe_GivePoint", Native_GivePoint);
	CreateNative("RankMe_GetRank", Native_GetRank);
	CreateNative("RankMe_GetStats", Native_GetStats);
	CreateNative("RankMe_GetSession", Native_GetSession);
	CreateNative("RankMe_GetWeaponStats", Native_GetWeaponStats);
	CreateNative("RankMe_GetHitbox", Native_GetHitbox);
	RegPluginLibrary("rankme");
	
	return APLRes_Success;
}
public Native_GivePoint(Handle:plugin, numParams)
{
	new iClient = GetNativeCell(1);
	new iPoints = GetNativeCell(2);

	new len;
	GetNativeStringLength(3, len);
	
	if (len <= 0)
	{
		return;
	}
	
	
	new String:Reason[len+1];
	new String:Name[MAX_NAME_LENGTH];
	GetNativeString(3, Reason, len+1);
	new iPrintToPlayer=GetNativeCell(4);
	new iPrintToAll=GetNativeCell(5);
	stats[iClient][SCORE] += iPoints;
	session[iClient][SCORE] += iPoints;
	SalvarPlayer(iClient);
	GetClientName(iClient,Name,sizeof(Name));
	if(!g_chatchange)
		return;
	if(iPrintToAll == 1){
		CPrintToChatAll("%s %t",MSG,"GotPointsBy",Name,stats[iClient][SCORE],iPoints,Reason);
	} else if( iPrintToPlayer == 1) {
		CPrintToChat(iClient,"%s %t",MSG,"GotPointsBy",Name,stats[iClient][SCORE],iPoints,Reason);
	}
}

public Native_GetRank(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new Function:callback = GetNativeCell(2);
	new any:data = GetNativeCell(3);
	
	new Handle:pack = CreateDataPack();
	
	WritePackCell(pack, client);
	WritePackCell(pack, _:callback);
	WritePackCell(pack, data);
	WritePackCell(pack, _:plugin);
	
	new String:query[500];
	if(g_rankbots && g_show_bots_on_rank)
		Format(query,sizeof(query),"SELECT * FROM rankme where kills >= '%d' ORDER BY score DESC",g_minimal_kills);
	else
		Format(query,sizeof(query),"SELECT * FROM rankme where kills >= '%d'  AND steam <> 'BOT' ORDER BY score DESC",g_minimal_kills);
	
	SQL_TQuery(stats_db, SQL_GetRankCallback, query, pack);
}

public SQL_GetRankCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new Handle:pack = data;
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new Function:callback = Function:ReadPackCell(pack);
	new any:args = ReadPackCell(pack);
	new Handle:plugin = Handle:ReadPackCell(pack);
	CloseHandle(pack);
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("[RankMe] Query Fail: %s", error);
		CallRankCallback(0, 0, Function:callback, 0, plugin);
		return;
	}
	new i;
	total_players =SQL_GetRowCount(hndl);
	while(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		i++;
		new String:Auth_receive[32];
		SQL_FetchString(hndl,1,Auth_receive,32);
		
		new String:auth[32];
		GetClientAuthString(client,auth,sizeof(auth));
		
		if(StrEqual(Auth_receive,auth,false))
		{
			CallRankCallback(client, i, Function:callback, args, plugin);
			break;
		}
	
	}
}

CallRankCallback(client, rank, Function:callback, any:data, Handle:plugin)
{
	Call_StartFunction(plugin, callback);
	Call_PushCell(client);
	Call_PushCell(rank);
	Call_PushCell(data);
	Call_Finish();
}

public Native_GetStats(Handle:plugin, numParams)
{
	new iClient = GetNativeCell(1);
	new array[20];
	for(new i=0;i<20;i++)
		array[i] = stats[iClient][i];
	
	SetNativeArray(2,array,20);

}
public Native_GetSession(Handle:plugin, numParams)
{
	new iClient = GetNativeCell(1);
	new array[20];
	for(new i=0;i<20;i++)
		array[i] = session[iClient][i];
	
	SetNativeArray(2,array,20);
	
}

public Native_GetWeaponStats(Handle:plugin, numParams)
{
	new iClient = GetNativeCell(1);
	new array[28];
	for(new i=0;i<28;i++)
		array[i] = weapons[iClient][i];
	
	SetNativeArray(2,array,28);
	
}

public Native_GetHitbox(Handle:plugin, numParams)
{
	new iClient = GetNativeCell(1);
	new array[8];
	for(new i=0;i<28;i++)
		array[i] = hitbox[iClient][i];
	
	SetNativeArray(2,array,8);
}


public DumpDB(){
	SQL_TQuery(stats_db,SQL_DumpCallback,"SELECT * from rankme");
}

public Action:OnClientChangeName(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_enabled) 
		return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!g_rankbots && IsFakeClient(client)) 
		return Plugin_Continue;
	if(IsClientConnected(client))
	{
		if(g_rankbyname){
			OnDB[client]=false;
			for(new i=0;i<=19;i++){
				session[client][i] = 0;
				stats[client][i] = 0;
			}
			stats[client][SCORE]=g_points_start;
			for(new i=0;i<=27;i++){
				weapons[client][i] = 0;
			}
			session[client][CONNECTED] = GetTime();
			
			decl String:clientnewname[MAX_NAME_LENGTH];
			GetEventString(event, "newname", clientnewname, sizeof(clientnewname));
			if(client==c4_planted_by)
				strcopy(c4_planted_by_name,sizeof(c4_planted_by_name),clientnewname);
			ReplaceString(clientnewname, sizeof(clientnewname), "'", "");
			new String:query[500];
			Format(query,sizeof(query),sql_retrieveclient_name,clientnewname);
			if(DEBUGGING){
				PrintToServer(query);
				LogError("%s",query);
			}
			SQL_TQuery(stats_db,SQL_LoadPlayerCallback,query,client);
		} else {
			decl String:auth[32];
			GetClientAuthString(client,auth,sizeof(auth));
			decl String:clientnewname[MAX_NAME_LENGTH];
			
			GetEventString(event, "newname", clientnewname, sizeof(clientnewname));
			if(client==c4_planted_by)
				strcopy(c4_planted_by_name,sizeof(c4_planted_by_name),clientnewname);
			//SQL_EscapeString(stats_db,clientnewname,clientnewname,sizeof(clientnewname));
			ReplaceString(clientnewname, sizeof(clientnewname), "'", "");
			new String:query[500];
			Format(query,sizeof(query),"UPDATE rankme SET name='%s' WHERE steam = '%s';",clientnewname,auth);
			
			SQL_TQuery(stats_db,SQL_NothingCallback,query);
		}
	}
	return Plugin_Continue;
}

public Action:Command_SayChat(client, args)
{	
	if(!g_enabled) 
		return Plugin_Continue;
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)) || client == 0)
	{
		return Plugin_Continue;
	}
	
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if(strcmp(text[startidx],"rank",false)==0 || strcmp(text[startidx],"statsme",false)==0 || strcmp(text[startidx],"hitboxme",false)==0 || strcmp(text[startidx],"weaponme",false)==0 || strcmp(text[startidx],"session",false)==0){
		ClientCommand(client,"%s",text);
		if(g_silenttrigger)
			return Plugin_Handled;
	} else if( strcmp(text[startidx],"next",false)==0) {
		CMD_Next(client,args);
		if(g_silenttrigger)
			return Plugin_Handled;
			
	} else if(StrContains(text[startidx],"topknife")  == 0){
	
		if(StrContains(text[startidx]," ") != -1)
		{
			ClientCommand(client,"%s",text);
		} else {
			ClientCommand(client,"topknife %s",text[startidx+3]);
		}
		if(g_silenttrigger)
			return Plugin_Handled;
	
	} else if(StrContains(text[startidx],"topnade")  == 0){
	
		if(StrContains(text[startidx]," ") != -1)
		{
			ClientCommand(client,"%s",text);
		} else {
			ClientCommand(client,"topnade %s",text[startidx+3]);
		}
		if(g_silenttrigger)
			return Plugin_Handled;
	
	}  else if(StrContains(text[startidx],"topweapon")  == 0){
		if(StrContains(text[startidx]," ") != -1)
		{
			ClientCommand(client,"%s",text);
		} else {
			ClientCommand(client,"topweapon %s",text[startidx+3]);
		}
		if(g_silenttrigger)
			return Plugin_Handled;
			
	} else if(StrContains(text[startidx],"top")  == 0){
	
		if(StrContains(text[startidx]," ") != -1)
		{
			ClientCommand(client,"%s",text);
		} else {
			ClientCommand(client,"top %s",text[startidx+3]);
		}
		if(g_silenttrigger)
			return Plugin_Handled;
	}
	
	return Plugin_Continue;	
}

public GetCurrentPlayers(){
	new count;
	for(new i=1;i<=MaxClients;i++){
		if(IsClientInGame(i) && (!IsFakeClient(i) || g_rankbots)){
			count++;
		}
	}
	return count;
}

public OnPluginEnd(){
	if(!g_enabled) 
		return;
	for(new client=1;client<=MaxClients;client++){
		if(IsClientInGame(client)){
			if(!g_rankbots && IsFakeClient(client)) 
				return;
			new String:name[256];
			GetClientName(client, name, sizeof(name));
			//SQL_EscapeString(stats_db,name,name,sizeof(name));
			new String:auth[32];
			GetClientAuthString(client,auth,sizeof(auth));
			
			new String:ip[32];
			GetClientIP(client,ip,sizeof(ip));
			// Make SQL-safe
			ReplaceString(name, sizeof(name), "'", "");

			
			new String:weapons_query[500] = "";
			for(new i=0;i<=27;i++){
				Format(weapons_query,sizeof(weapons_query),"%s,%s='%d'",weapons_query,weapons_names[i],weapons[client][i]);
			}
			new String:query[1500];
		
			Format(query,sizeof(query),sql_salvar,stats[client][SCORE],stats[client][KILLS],stats[client][DEATHS],stats[client][SUICIDES],stats[client][TK],
			stats[client][SHOTS],stats[client][HITS],stats[client][HEADSHOTS],stats[client][ROUNDS_TR],stats[client][ROUNDS_CT],ip,name,weapons_query,
			hitbox[client][1],hitbox[client][2],hitbox[client][3],hitbox[client][4],hitbox[client][5],hitbox[client][6],hitbox[client][7],stats[client][C4_PLANTED],stats[client][C4_EXPLODED],stats[client][C4_DEFUSED],stats[client][CT_WIN],stats[client][TR_WIN],stats[client][HOSTAGES_RESCUED],stats[client][VIP_KILLED],stats[client][VIP_ESCAPED],stats[client][VIP_PLAYED],auth);
			SQL_LockDatabase(stats_db);
			SQL_FastQuery(stats_db,query);
			SQL_UnlockDatabase(stats_db);
		}
	}
}

public GetWeaponNum(String:weaponname[]){


	for(new i=0;i<=27;i++){
		if(StrEqual(weaponname,weapons_names[i]))
			return i;
	}
	return 30;
}

public Action: Event_VipEscaped(Handle:event, const String:name[], bool:dontBroadcast){
	if(!g_enabled || g_minimumplayers > GetCurrentPlayers()) 
		return;
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	for(new i=1;i<=MaxClients;i++){

		if(IsClientInGame(i) && GetClientTeam(i)==CT){
			stats[i][SCORE]+=g_points_vip_escaped_team;
			session[i][SCORE]+=g_points_vip_escaped_team;
		
		}

	}
	stats[client][VIP_PLAYED]++;
	session[client][VIP_PLAYED]++;
	stats[client][VIP_ESCAPED]++;
	session[client][VIP_ESCAPED]++;
	stats[client][SCORE]+=g_points_vip_escaped_player;
	session[client][SCORE]+=g_points_vip_escaped_player;
	new String:cname[MAX_NAME_LENGTH];
	GetClientName(client,cname,sizeof(cname));
	if(!g_chatchange)
		return;
	CPrintToChatAll("%s %t",MSG,"CT_VIPEscaped",g_points_vip_escaped_team);
	if(client != 0 && (g_rankbots || !IsFakeClient(client))) 
		CPrintToChatAll("%s %t",MSG,"VIPEscaped",cname,stats[client][SCORE],g_points_vip_escaped_team+g_points_vip_escaped_player);
}

public Action: Event_VipKilled(Handle:event, const String:name[], bool:dontBroadcast){
	if(!g_enabled || g_minimumplayers > GetCurrentPlayers()) 
		return;
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new killer = GetClientOfUserId(GetEventInt(event,"attacker"));

	for(new i=1;i<=MaxClients;i++){

		if(IsClientInGame(i) && GetClientTeam(i)==TR){
			stats[i][SCORE]+=g_points_vip_killed_team;
			session[i][SCORE]+=g_points_vip_killed_team;
		
		}

	}
	stats[client][VIP_PLAYED]++;
	session[client][VIP_PLAYED]++;
	stats[killer][VIP_KILLED]++;
	session[killer][VIP_KILLED]++;
	stats[killer][SCORE]+=g_points_vip_killed_player;
	session[killer][SCORE]+=g_points_vip_killed_player;
	new String:cname[MAX_NAME_LENGTH];
	GetClientName(killer,cname,sizeof(cname));
	if(!g_chatchange)
		return;
	CPrintToChatAll("%s %t",MSG,"TR_VIPKilled",g_points_vip_killed_team);
	if(client != 0 && (g_rankbots || !IsFakeClient(client))) 
		CPrintToChatAll("%s %t",MSG,"VIPKilled",cname,stats[client][SCORE],g_points_vip_killed_team+g_points_vip_killed_player);
}

public Action: Event_HostageRescued(Handle:event, const String:name[], bool:dontBroadcast){
	if(!g_enabled || g_minimumplayers > GetCurrentPlayers()) 
		return;
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	
	for(new i=1;i<=MaxClients;i++){
	
		if(IsClientInGame(i) && GetClientTeam(i)==CT){
			stats[i][SCORE]+=g_points_hostage_resc_team;
			session[i][SCORE]+=g_points_hostage_resc_team;
		
		}
	
	}
	session[client][HOSTAGES_RESCUED]++;
	stats[client][HOSTAGES_RESCUED]++;
	stats[client][SCORE]+=g_points_hostage_resc_player;
	session[client][SCORE]+=g_points_hostage_resc_player;
	new String:cname[MAX_NAME_LENGTH];
	GetClientName(client,cname,sizeof(cname));
	if(!g_chatchange)
		return;
	if(g_points_hostage_resc_team > 0)
		CPrintToChatAll("%s %t",MSG,"CT_Hostage",g_points_hostage_resc_team);
	
	if(g_points_hostage_resc_player > 0 && client != 0 && (g_rankbots || !IsFakeClient(client))) 
		CPrintToChatAll("%s %t",MSG,"Hostage",cname,stats[client][SCORE],g_points_hostage_resc_player+g_points_hostage_resc_team);
	
}

public Action: Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast){
	if(!g_enabled || g_minimumplayers > GetCurrentPlayers()) 
		return;
	new i;
	new bool:announced=false;
	for(i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i)){
			if(!g_rankbots && IsFakeClient(i)) 
				return;
			if(GetEventInt(event,"winner") == TR && GetClientTeam(i)==TR){
				session[i][TR_WIN]++;
				stats[i][TR_WIN]++;
				if(g_points_round_win[TR] >0 && IsPlayerAlive(i)){
					session[i][SCORE] += g_points_round_win[TR];
					stats[i][SCORE] += g_points_round_win[TR];
					if(!announced && g_chatchange){
						CPrintToChatAll("%s %t",MSG,"TR_Round",g_points_round_win[TR]);
						announced=true;
					}
				}
			} else if((GetEventInt(event,"winner") == CT && GetClientTeam(i)==CT)){
				session[i][CT_WIN]++;
				stats[i][CT_WIN]++;
				if(g_points_round_win[CT] >0 && IsPlayerAlive(i)){
					session[i][SCORE] += g_points_round_win[CT];
					stats[i][SCORE] += g_points_round_win[CT];
					if(!announced && g_chatchange){
						CPrintToChatAll("%s %t",MSG,"CT_Round",g_points_round_win[CT]);
						announced=true;
					}
				}
			}
			
		}
	}
	DumpDB();
}

public EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_enabled || g_minimumplayers > GetCurrentPlayers()) 
		return;
	
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(!g_rankbots && IsFakeClient(client)) 
		return;
	if(GetClientTeam(client) == TR){
		stats[client][ROUNDS_TR]++;
		session[client][ROUNDS_TR]++;
	} else if(GetClientTeam(client) == CT){
		stats[client][ROUNDS_CT]++;
		session[client][ROUNDS_CT]++;
	} 
}

public Action:Event_BombPlanted( Handle:event, const String:name[], bool:dontBroadcast )
{
	if(!g_enabled || g_minimumplayers > GetCurrentPlayers()) 
		return;
	
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	c4_planted_by = client;
	
	for(new i=1;i<=MaxClients;i++){
	
		if(IsClientInGame(i) && GetClientTeam(i)==TR){
			stats[i][SCORE]+=g_points_bomb_planted_team;
			session[i][SCORE]+=g_points_bomb_planted_team;
		
		}
	
	}
	stats[client][C4_PLANTED]++;
	session[client][C4_PLANTED]++;
	stats[client][SCORE]+=g_points_bomb_planted_player;
	session[client][SCORE]+=g_points_bomb_planted_player;
	new String:cname[MAX_NAME_LENGTH];
	GetClientName(client,cname,sizeof(cname));
	strcopy(c4_planted_by_name,sizeof(c4_planted_by_name),cname);
	if(!g_chatchange)
		return;
	if(g_points_bomb_planted_team > 0)
		CPrintToChatAll("%s %t",MSG,"TR_Planting",g_points_bomb_planted_team);
	if(g_points_bomb_planted_player > 0 && client != 0 && (g_rankbots || !IsFakeClient(client))) 
		CPrintToChatAll("%s %t",MSG,"Planting",cname,stats[client][SCORE],g_points_bomb_planted_team+g_points_bomb_planted_player);
		
}

public Action:Event_BombDefused( Handle:event, const String:name[], bool:dontBroadcast )
{
	if(!g_enabled || g_minimumplayers > GetCurrentPlayers()) 
		return;
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	for(new i=1;i<=MaxClients;i++){
	
		if(IsClientInGame(i) && GetClientTeam(i)==CT){
			stats[i][SCORE]+=g_points_bomb_defused_team;
			session[i][SCORE]+=g_points_bomb_defused_team;
		
		}
	
	}
	stats[client][C4_DEFUSED]++;
	session[client][C4_DEFUSED]++;
	stats[client][SCORE]+=g_points_bomb_defused_player;
	session[client][SCORE]+=g_points_bomb_defused_player;
	new String:cname[MAX_NAME_LENGTH];
	GetClientName(client,cname,sizeof(cname));
	if(!g_chatchange)
		return;
	if(g_points_bomb_defused_team > 0)
		CPrintToChatAll("%s %t",MSG,"CT_Defusing",g_points_bomb_defused_team);
	if(g_points_bomb_defused_player > 0 && client != 0 && (g_rankbots || !IsFakeClient(client))) 
		CPrintToChatAll("%s %t",MSG,"Defusing",cname,stats[client][SCORE],g_points_bomb_defused_team+g_points_bomb_defused_player);
}

public Action:Event_BombExploded( Handle:event, const String:name[], bool:dontBroadcast )
{
	if(!g_enabled || g_minimumplayers > GetCurrentPlayers()) 
		return;
	new client =c4_planted_by;
	
	for(new i=1;i<=MaxClients;i++){
	
		if(IsClientInGame(i) && GetClientTeam(i)==TR){
			stats[i][SCORE]+=g_points_bomb_explode_team;
			session[i][SCORE]+=g_points_bomb_explode_team;
		
		}
	
	}
	stats[client][C4_EXPLODED]++;
	session[client][C4_EXPLODED]++;
	stats[client][SCORE]+=g_points_bomb_explode_player;
	session[client][SCORE]+=g_points_bomb_explode_player;
	
	if(!g_chatchange)
		return;
	if(g_points_bomb_explode_team > 0)
		CPrintToChatAll("%s %t",MSG,"TR_Exploding",g_points_bomb_explode_team);
	if(g_points_bomb_explode_player > 0 && client != 0 && (g_rankbots || (IsClientInGame(client) && !IsFakeClient(client)))) 
		CPrintToChatAll("%s %t",MSG,"Exploding",c4_planted_by_name,stats[client][SCORE],g_points_bomb_explode_team+g_points_bomb_explode_player);
}

public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	if(!g_enabled || g_minimumplayers > GetCurrentPlayers()) 
		return;
	
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!g_rankbots && attacker != 0 && (IsFakeClient(victim) || IsFakeClient(attacker))) 
		return;
	
	if(victim == attacker || attacker == 0){
		stats[victim][SUICIDES]++;
		session[victim][SUICIDES]++;
		stats[victim][SCORE] -= g_points_lose_suicide;
		session[victim][SCORE] -= g_points_lose_suicide;
		SalvarPlayer(victim);
		if(g_points_lose_suicide > 0 && g_chatchange){
			new String:vname[MAX_NAME_LENGTH];
			GetClientName(victim,vname,sizeof(vname));
			CPrintToChat(victim,"%s %t",MSG,"LostSuicide",vname,stats[victim][SCORE],g_points_lose_suicide);
		}
	} else if(!g_ffa && (GetClientTeam(victim) == GetClientTeam(attacker))){
		if(attacker < MAXPLAYERS){
			stats[attacker][TK]++;
			session[attacker][TK]++;
			stats[attacker][SCORE] -= g_points_lose_tk;
			session[attacker][SCORE] -= g_points_lose_tk;
			SalvarPlayer(attacker);
			if(g_points_lose_tk > 0 && g_chatchange){
				new String:vname[MAX_NAME_LENGTH];
				GetClientName(victim,vname,sizeof(vname));
				new String:aname[MAX_NAME_LENGTH];
				GetClientName(attacker,aname,sizeof(aname));
				CPrintToChat(victim,"%s %t",MSG,"LostTK",aname,stats[attacker][SCORE],g_points_lose_tk,vname);
				CPrintToChat(attacker,"%s %t",MSG,"LostTK",aname,stats[attacker][SCORE],g_points_lose_tk,vname);
			}
		}
	} else {
		new team =GetClientTeam(attacker);
		new bool:headshot = GetEventBool(event, "headshot");
		decl String:weapon[64];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		ReplaceString(weapon,sizeof(weapon),"weapon_","");
	
		new score_dif;
		if(attacker < MAXPLAYERS)
			score_dif = stats[victim][SCORE] - stats[attacker][SCORE];
		
		if(score_dif < 0 || attacker >= MAXPLAYERS) {
			score_dif = g_points_kill[team];
		} else {
			if(g_points_kill_bonus_dif[team] == 0)
				score_dif = g_points_kill[team] + ((stats[victim][SCORE] - stats[attacker][SCORE])*g_points_kill_bonus[team]);
			else
				score_dif = g_points_kill[team] + (((stats[victim][SCORE] - stats[attacker][SCORE])/g_points_kill_bonus_dif[team])*g_points_kill_bonus[team]);
		}
		if(StrEqual(weapon,"knife")){
			score_dif  = RoundToCeil(score_dif*g_points_knife_multiplier);
		}
		if(headshot && attacker < MAXPLAYERS){
			stats[attacker][HEADSHOTS]++;
			session[attacker][HEADSHOTS]++;
		}
		
		stats[victim][DEATHS]++;
		session[victim][DEATHS]++;
		if(attacker < MAXPLAYERS){
			stats[attacker][KILLS]++;
			session[attacker][KILLS]++;
		}
		if(g_points_lose_round_ceil){
			stats[victim][SCORE] -= RoundToCeil(score_dif*g_percent_points_lose);
			session[victim][SCORE] -= RoundToCeil(score_dif*g_percent_points_lose);
		} else {
			stats[victim][SCORE] -= RoundToFloor(score_dif*g_percent_points_lose);
			session[victim][SCORE] -= RoundToFloor(score_dif*g_percent_points_lose);
		}
		if(attacker < MAXPLAYERS){
			stats[attacker][SCORE] += score_dif;
			session[attacker][SCORE] += score_dif;
			if(GetWeaponNum(weapon) < 29)
				weapons[attacker][GetWeaponNum(weapon)]++;
		}
		new String:vname[MAX_NAME_LENGTH];
		GetClientName(victim,vname,sizeof(vname));
		
		new String:aname[MAX_NAME_LENGTH];
		if(attacker < MAXPLAYERS)
			GetClientName(attacker,aname,sizeof(aname));
		else
			aname = "";
	
		if(g_minimal_kills == 0 || (stats[victim][KILLS] > g_minimal_kills && stats[attacker][KILLS] > g_minimal_kills)){
			if(g_chatchange){
				CPrintToChat(victim,"%s %t",MSG,"Killing",aname,stats[attacker][SCORE],score_dif,vname,stats[victim][SCORE]);
				if(attacker < MAXPLAYERS)
					CPrintToChat(attacker,"%s %t",MSG,"Killing",aname,stats[attacker][SCORE],score_dif,vname,stats[victim][SCORE]);
			}
		} else {
			if(stats[victim][KILLS] < g_minimal_kills && stats[attacker][KILLS] < g_minimal_kills){
				if(g_chatchange){
					CPrintToChat(victim,"%s %t",MSG,"KillingBothNotRanked",aname,stats[attacker][SCORE],score_dif,vname,stats[victim][SCORE],stats[attacker][KILLS],g_minimal_kills,stats[victim][KILLS],g_minimal_kills);
					if(attacker < MAXPLAYERS)
						CPrintToChat(attacker,"%s %t",MSG,"KillingBothNotRanked",aname,stats[attacker][SCORE],score_dif,vname,stats[victim][SCORE],stats[attacker][KILLS],g_minimal_kills,stats[victim][KILLS],g_minimal_kills);
				}
			} else if(stats[victim][KILLS] < g_minimal_kills){
				if(g_chatchange){
					CPrintToChat(victim,"%s %t",MSG,"KillingVictimNotRanked",aname,stats[attacker][SCORE],score_dif,vname,stats[victim][SCORE],stats[victim][KILLS],g_minimal_kills);
					if(attacker < MAXPLAYERS)
						CPrintToChat(attacker,"%s %t",MSG,"KillingVictimNotRanked",aname,stats[attacker][SCORE],score_dif,vname,stats[victim][SCORE],stats[victim][KILLS],g_minimal_kills);
				}
			} else {
				if(g_chatchange){
					CPrintToChat(victim,"%s %t",MSG,"KillingKillerNotRanked",aname,stats[attacker][SCORE],score_dif,vname,stats[victim][SCORE],stats[attacker][KILLS],g_minimal_kills);
					if(attacker < MAXPLAYERS)
						CPrintToChat(attacker,"%s %t",MSG,"KillingKillerNotRanked",aname,stats[attacker][SCORE],score_dif,vname,stats[victim][SCORE],stats[attacker][KILLS],g_minimal_kills);
				}
			} 
		}
		if(headshot && attacker < MAXPLAYERS){
			
			stats[attacker][SCORE]+=g_points_hs;
			session[attacker][SCORE]+=g_points_hs;
			if(g_chatchange && g_points_hs > 0)
				CPrintToChat(attacker,"%s %t",MSG,"Headshot",aname,stats[attacker][SCORE],g_points_hs);
		}
		if(attacker < MAXPLAYERS)
			SalvarPlayer(attacker);
	}
	SalvarPlayer(victim);
	if(attacker < MAXPLAYERS)
		if(stats[attacker][KILLS] == 50)
			total_players++;
}

public Action:EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	if(!g_enabled) 
		return;
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!g_rankbots && (attacker == 0 || IsFakeClient(victim) || IsFakeClient(attacker))) 
		return;
	if(victim != attacker && attacker !=0 && attacker <MAXPLAYERS){
		
		stats[attacker][HITS]++;
		session[attacker][HITS]++;
		new hitgroup = GetEventInt(event,"hitgroup");
		hitbox[attacker][hitgroup]++;
	}
}

public Action:EventWeaponFire(Handle:event,const String:name[],bool:dontBroadcast)
{

	if(!g_enabled) 
		return;
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(!g_rankbots && IsFakeClient(client)) 
		return;
	stats[client][SHOTS]++;
	session[client][SHOTS]++;
	
}

public SalvarPlayer(client){
	if(!g_enabled) 
		return;
	if(!g_rankbots && IsFakeClient(client)) 
		return;
	if(!OnDB[client])
		return;
	new String:name[256];
	GetClientName(client, name, sizeof(name));
	//SQL_EscapeString(stats_db,name,name,sizeof(name));
	new String:auth[32];
	GetClientAuthString(client,auth,sizeof(auth));
	
	new String:ip[32];
	GetClientIP(client,ip,sizeof(ip));
	// Make SQL-safe
	ReplaceString(name, sizeof(name), "'", "");

	
	new String:weapons_query[500] = "";
	for(new i=0;i<=27;i++){
		Format(weapons_query,sizeof(weapons_query),"%s,%s='%d'",weapons_query,weapons_names[i],weapons[client][i]);
	}
	new String:query[1500];
	if(g_rankbyname){
		Format(query,sizeof(query),sql_salvar_name,stats[client][SCORE],stats[client][KILLS],stats[client][DEATHS],stats[client][SUICIDES],stats[client][TK],
			stats[client][SHOTS],stats[client][HITS],stats[client][HEADSHOTS],stats[client][ROUNDS_TR],stats[client][ROUNDS_CT],ip,name,weapons_query,
			hitbox[client][1],hitbox[client][2],hitbox[client][3],hitbox[client][4],hitbox[client][5],hitbox[client][6],hitbox[client][7],stats[client][C4_PLANTED],stats[client][C4_EXPLODED],stats[client][C4_DEFUSED],stats[client][CT_WIN],stats[client][TR_WIN],stats[client][HOSTAGES_RESCUED],stats[client][VIP_KILLED],stats[client][VIP_ESCAPED],stats[client][VIP_PLAYED],name);
	} else {
		Format(query,sizeof(query),sql_salvar,stats[client][SCORE],stats[client][KILLS],stats[client][DEATHS],stats[client][SUICIDES],stats[client][TK],
			stats[client][SHOTS],stats[client][HITS],stats[client][HEADSHOTS],stats[client][ROUNDS_TR],stats[client][ROUNDS_CT],ip,name,weapons_query,
			hitbox[client][1],hitbox[client][2],hitbox[client][3],hitbox[client][4],hitbox[client][5],hitbox[client][6],hitbox[client][7],stats[client][C4_PLANTED],stats[client][C4_EXPLODED],stats[client][C4_DEFUSED],stats[client][CT_WIN],stats[client][TR_WIN],stats[client][HOSTAGES_RESCUED],stats[client][VIP_KILLED],stats[client][VIP_ESCAPED],stats[client][VIP_PLAYED],auth);
	}
	SQL_TQuery(stats_db,SQL_NothingCallback,query);

	if(DEBUGGING){
		PrintToServer(query);
		LogError("%s",query);
	}
	if(g_rankbyname){
		Format(query,sizeof(query),sql_connects_name,GetTime(),stats[client][CONNECTED] + GetTime()-session[client][CONNECTED],name);
	} else {
		Format(query,sizeof(query),sql_connects,GetTime(),stats[client][CONNECTED] + GetTime()-session[client][CONNECTED],auth);
	}
	SQL_TQuery(stats_db,SQL_NothingCallback,query);
	
	if(DEBUGGING){
		PrintToServer(query);
		
		LogError("%s",query);
	}
	
}

public OnClientPutInServer(client){

	OnDB[client]=false;
	for(new i=0;i<=19;i++){
		session[client][i] = 0;
		stats[client][i] = 0;
	}
	stats[client][SCORE]=g_points_start;
	for(new i=0;i<=27;i++){
		weapons[client][i] = 0;
	}
	session[client][CONNECTED] = GetTime();
	
	new String:name[256];
	GetClientName(client, name, sizeof(name));
	//SQL_EscapeString(stats_db,name,name,sizeof(name));
	ReplaceString(name, sizeof(name), "'", "");
	new String:auth[32];
	GetClientAuthString(client,auth,sizeof(auth));
	
	new String:query[500];
	if(g_rankbyname)
		Format(query,sizeof(query),sql_retrieveclient_name,name);
	else
		Format(query,sizeof(query),sql_retrieveclient,auth);
	if(DEBUGGING){
		PrintToServer(query);
		LogError("%s",query);
	}
	if(stats_db != INVALID_HANDLE)
		SQL_TQuery(stats_db,SQL_LoadPlayerCallback,query,client);
}

public SQL_LoadPlayerCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("[RankMe] Load Player Fail: %s", error);
		return;
	}
	if(!IsClientInGame(client))
		return;
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		for(new i=0;i<=10;i++){
			stats[client][i]=SQL_FetchInt(hndl,4+i);
		}
		for(new i=0;i<=27;i++){
			weapons[client][i]=SQL_FetchInt(hndl,16+i);
		}
		for(new i=1;i<=7;i++){
			hitbox[client][i]=SQL_FetchInt(hndl,43+i);
		}
		stats[client][C4_PLANTED]=SQL_FetchInt(hndl,51);
		stats[client][C4_EXPLODED]=SQL_FetchInt(hndl,52);
		stats[client][C4_DEFUSED]=SQL_FetchInt(hndl,53);
		stats[client][CT_WIN] = SQL_FetchInt(hndl,54);
		stats[client][TR_WIN] = SQL_FetchInt(hndl,55);
		stats[client][HOSTAGES_RESCUED] = SQL_FetchInt(hndl,56);
		stats[client][VIP_KILLED] = SQL_FetchInt(hndl,57);
		stats[client][VIP_ESCAPED] = SQL_FetchInt(hndl,58);
		stats[client][VIP_PLAYED] = SQL_FetchInt(hndl,59);
	} else {
		new String:query[500];
		new String:name[256];
		GetClientName(client, name, sizeof(name));
		//SQL_EscapeString(stats_db,name,name,sizeof(name));
		ReplaceString(name, sizeof(name), "'", "");
		new String:auth[32];
		GetClientAuthString(client,auth,sizeof(auth));
		
		new String:ip[32];
		GetClientIP(client,ip,sizeof(ip));
		Format(query,sizeof(query),sql_iniciar ,auth,name,ip,g_points_start);
		SQL_TQuery(stats_db,SQL_NothingCallback,query,_,DBPrio_High);
		
		if(DEBUGGING){
			PrintToServer(query);
			
			LogError("%s",query);
		}
	}
	OnDB[client] = true;
}

public SQL_PurgeCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[RankMe] Query Fail: %s", error);
		return;
	}
	
	PrintToServer("[RankMe]: %d players purged by inactivity",SQL_GetAffectedRows(owner));
	if(client != 0){
		PrintToChat(client,"[RankMe]: %d players purged by inactivity",SQL_GetAffectedRows(owner));
	}
	//LogAction(-1,-1,"[RankMe]: %d players purged by inactivity",SQL_GetAffectedRows(owner));
	
}

public SQL_NothingCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[RankMe] Query Fail: %s", error);
		return;
	}
	
	
}

public OnClientDisconnect(client){
	if(!g_enabled) 
		return;
	if(!g_rankbots && IsFakeClient(client)) 
		return;
	SalvarPlayer(client);
	OnDB[client] = false;
}

public SQL_DumpCallback(Handle:owner, Handle:hndl, const String:error[], any:Datapack){

	if(hndl == INVALID_HANDLE)
	{
		LogError("[RankMe] Query Fail: %s", error);
		PrintToServer(error);
		return;
	}
	
	new Handle:File1;
	new String:fields_values[600];
	new String:field[100];
	File1 = OpenFile("rank.sql","w");
	if(File1==INVALID_HANDLE)
		return;
	new fields = SQL_GetFieldCount(hndl);
	new bool:first;
	WriteFileLine(File1,sql_criar);
	WriteFileLine(File1,"");
	
	while(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		field = "";
		fields_values = "";
		first=true;
		for(new i = 0;i<=fields-1;i++){
			SQL_FetchString(hndl,i,field,sizeof(field));
			ReplaceString(field,sizeof(field),"\\","\\\\",false);
			ReplaceString(field,sizeof(field),"\"","\\\"",false);
			
			if(first){
				Format(fields_values,sizeof(fields_values),"\"%s\"",field);
				first=false;
			}
			else
				Format(fields_values,sizeof(fields_values),"%s,\"%s\"",fields_values,field);
		}
	
		WriteFileLine(File1,"INSERT INTO `rankme` VALUES (%s);",fields_values);
	}
	CloseHandle(File1);
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
	g_show_bots_on_rank = GetConVarBool(cvar_show_bots_on_rank);
	g_rankbyname = GetConVarBool(cvar_rankbyname);
	g_enabled = GetConVarBool(cvar_enabled);
	g_show_rank_all = GetConVarBool(cvar_show_rank_all);
	g_chatchange = GetConVarBool(cvar_chatchange);
	g_rankbots = GetConVarBool(cvar_rankbots);
	g_ffa = GetConVarBool(cvar_ffa);
	g_silenttrigger = GetConVarBool(cvar_silenttrigger);
	g_points_bomb_defused_team = GetConVarInt(cvar_points_bomb_defused_team);
	g_points_bomb_defused_player = GetConVarInt(cvar_points_bomb_defused_player);
	g_points_bomb_planted_team = GetConVarInt(cvar_points_bomb_planted_team);
	g_points_bomb_planted_player = GetConVarInt(cvar_points_bomb_planted_player);
	g_points_bomb_explode_team = GetConVarInt(cvar_points_bomb_explode_team);
	g_points_bomb_explode_player = GetConVarInt(cvar_points_bomb_explode_player);
	g_points_hostage_resc_team = GetConVarInt(cvar_points_hostage_resc_team);
	g_points_hostage_resc_player = GetConVarInt(cvar_points_hostage_resc_player);
	g_points_hs = GetConVarInt(cvar_points_hs);
	g_points_kill[CT] = GetConVarInt(cvar_points_kill_ct);
	g_points_kill[TR] = GetConVarInt(cvar_points_kill_tr);
	g_points_kill_bonus[CT] = GetConVarInt(cvar_points_kill_bonus_ct);
	g_points_kill_bonus[TR] = GetConVarInt(cvar_points_kill_bonus_tr);
	g_points_kill_bonus_dif[CT] = GetConVarInt(cvar_points_kill_bonus_dif_ct);
	g_points_kill_bonus_dif[TR] = GetConVarInt(cvar_points_kill_bonus_dif_tr);
	g_points_start = GetConVarInt(cvar_points_start);
	g_points_knife_multiplier = GetConVarFloat(cvar_points_knife_multiplier);
	g_points_round_win[TR] = GetConVarInt(cvar_points_tr_round_win);
	g_points_round_win[CT] = GetConVarInt(cvar_points_ct_round_win);
	g_minimal_kills = GetConVarInt(cvar_minimal_kills);
	g_percent_points_lose = GetConVarFloat(cvar_percent_points_lose);
	g_points_lose_round_ceil = GetConVarBool(cvar_points_lose_round_ceil);
	g_minimumplayers = GetConVarInt(cvar_minimumplayers);
	g_resetownrank = GetConVarBool(cvar_resetownrank);
	g_points_vip_escaped_team = GetConVarInt(cvar_points_vip_escaped_team);
	g_points_vip_escaped_player = GetConVarInt(cvar_points_vip_escaped_player);
	g_points_vip_killed_team = GetConVarInt(cvar_points_vip_killed_team);
	g_points_vip_killed_player = GetConVarInt(cvar_points_vip_killed_player);
	g_vip_enabled = GetConVarBool(cvar_vip_enabled);
	
	if(convar == cvar_rankbots && stats_db != INVALID_HANDLE){
		new String:query[500];
		if(g_rankbots)
			Format(query,sizeof(query),"SELECT * FROM rankme WHERE kills >= '%d'",g_minimal_kills);
		else
			Format(query,sizeof(query),"SELECT * FROM rankme WHERE kills >= '%d' AND steam <> 'BOT'",g_minimal_kills);
		SQL_TQuery(stats_db,SQL_GetPlayersCallback,query);
	}
}

