#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "[VIP] BunnyHop"
#define PLUGIN_AUTHOR "IND "
#define PLUGIN_VERSION "0.1"
#define AUTHOR_URL "https://github.com/ind333"

#define VIP_BHOP "BunnyHop"

#include <sourcemod>
#include <vip_core>

public Plugin myinfo = {
	name 	= PLUGIN_NAME,
	author 	= PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	url 	= PLUGIN_URL
}

Handle g_hTimer;
int g_iTimerSeconds;
char g_szTag[PLATFORM_MAX_PATH];
bool g_bIsBhop, g_bIsEnabledTimer, g_bIsEnabledMessage;

public void VIP_OnVIPLoaded() {
	VIP_RegisterFeature(VIP_BHOP, BOOL);

	fetchConfig();
	loadConfigs();
	LoadTranslations("vip.bunnyhop.phrases");

	HookEvent("round_start", Event_RoundStart);
}

public void OnPluginStart() {
	if(VIP_IsVIPLoaded()) VIP_OnVIPLoaded();
}

stock void fetchConfig() {
	if(!FileExists("addons/sourcemod/data/vip/modules/bunnyhop.ini")) {
		OpenFile("addons/sourcemod/data/vip/modules/bunnyhop.ini", "w");
		
		Handle hConfig = CreateKeyValues("BunnyHop");

		KvSetString(hConfig, "bhop_chat_prefix",	"[BunnyHop]");
		KvSetNum(hConfig, "bhop_timer_enabled", 	1);
     	KvSetNum(hConfig, "bhop_timer_seconds", 	5);
     	KvSetNum(hConfig, "bhop_timer_messages",	1);
     	
     	KvRewind(hConfig);
     	KeyValuesToFile(hConfig, "addons/sourcemod/data/vip/modules/bunnyhop.ini");
     	
		CloseHandle(hConfig);
	}
}

stock void loadConfigs() {
	char szBuffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szBuffer, sizeof szBuffer, "data/vip/modules/bunnyhop.ini");

	KeyValues hKV = CreateKeyValues("BunnyHop");
	if(!hKV.ImportFromFile(szBuffer)) SetFailState("Config file is missing: %s", szBuffer);
	
	g_bIsEnabledTimer = hKV.GetNum("bhop_timer_enabled", 1) ? true : false;
	g_iTimerSeconds = hKV.GetNum("bhop_timer_seconds", 5);
	g_bIsEnabledMessage = hKV.GetNum("bhop_timer_messages", 1) ? true : false;
	hKV.GetString("bhop_chat_prefix", g_szTag, sizeof g_szTag, "[BunnyHop]");
}

public void Event_RoundStart(Handle hEvent, char[] szName, bool bDontBroadcast)  {
	if(g_bIsEnabledTimer) {
		g_bIsBhop = false;

		int iTime = GetConVarInt(FindConVar("mp_freezetime")) + g_iTimerSeconds;
		
		if(g_hTimer != INVALID_HANDLE) KillTimer(g_hTimer);
	
		CreateTimer(g_iTimerSeconds + GetConVarFloat(FindConVar("mp_freezetime")), Timer_EnableBhop, _, TIMER_FLAG_NO_MAPCHANGE);
		
		if(g_bIsEnabledMessage){
			for(int i = 1; i <= MaxClients; i++) {
				if(IsClientInGame(i) && !IsFakeClient(i) && VIP_IsClientVIP(i)) {
					if(VIP_GetClientFeatureStatus(i, VIP_BHOP) == ENABLED) {
						char szMessage[PLATFORM_MAX_PATH];
						FormatEx(szMessage, sizeof szMessage, "%s %T", g_szTag, "BunnyHop_Started", i, i, iTime);
						
						PrintToChat(i, szMessage);
					}
				}
			}
		}
	}else g_bIsBhop = true;
}

public Action Timer_EnableBhop(Handle hTimer) {
	g_bIsBhop = true;
	
	if(g_bIsEnabledMessage){
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i) && VIP_IsClientVIP(i)) {
				if(VIP_GetClientFeatureStatus(i, VIP_BHOP) == ENABLED) {
					char szMessage[PLATFORM_MAX_PATH];
					FormatEx(szMessage, sizeof szMessage, "%s %T", g_szTag, "BunnyHop_Ended", i, i);
					
					PrintToChat(i, szMessage);
				}
			}
		}
	}
}

public void OnPluginEnd() {
	VIP_UnregisterFeature(VIP_BHOP);
}

public Action OnPlayerRunCmd(int iClient, int& iButtons, int& impulse, float fVel[3], float fAngles[3], int& iWeapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2]) {
	if(!g_bIsBhop) return;
	
	if(IsPlayerAlive(iClient) && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, VIP_BHOP) && iButtons & IN_JUMP && !(GetEntityFlags(iClient) & FL_ONGROUND) && !(GetEntityMoveType(iClient) & MOVETYPE_LADDER) && GetEntProp(iClient, Prop_Data, "m_nWaterLevel") <= 1) 
		iButtons &= ~IN_JUMP;
}