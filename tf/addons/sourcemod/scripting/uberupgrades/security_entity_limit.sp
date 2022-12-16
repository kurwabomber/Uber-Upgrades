#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int g_iHighestIndex = 250;

float g_flSpawnTime[2049] = {0.0, ...};
bool shouldNotDespawn[2049] = {false, ...}

public Plugin myinfo =
{
	name = "Security Entity Limit!",
	author = "Benoist3012",
	description = "Remove old entities when server is near the entity limit!",
	version = "aylmao",
	url = "https://forums.alliedmods.net/showthread.php?t=265902"
}

public void OnPluginStart()
{
	CreateConVar("sm_sel_version", "aylmao", "Security Entity Limit version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Post);
}

public Action Event_RoundStart(Event event, const char[] sEventName, bool db)
{
	g_iHighestIndex = 250;
	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "*")) != -1 && iEnt < 2048)
	{
		if (iEnt > g_iHighestIndex)
			g_iHighestIndex = iEnt;
	}

	return Plugin_Continue;
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if (64 < iEntity < 2049)
	{
		if(StrContains(sClassname, "tf_weapon") != -1)
		{
			shouldNotDespawn[iEntity] = true;
		}
		g_flSpawnTime[iEntity] = GetGameTime();
		
		if (iEntity >= 2000)
		{
			SDKHook(iEntity, SDKHook_Spawn, Hook_NoSpawn);
			SDKHook(iEntity, SDKHook_SpawnPost, Hook_SpawnNkill);
		}
		
		if (iEntity >= 1800)
		{
			int iCounter = 0;
			float flTime;
			for (int iEnt = g_iHighestIndex+1 ; iEnt < 2048; iEnt++)
			{
				if(shouldNotDespawn[iEnt] == false && IsValidEntity(iEnt))
				{
					flTime = g_flSpawnTime[iEnt];
					if(9.0 <= (GetGameTime() - flTime))
					{
						AcceptEntityInput(iEnt, "Kill");
						iCounter++;
					}
				}
			}
		}
	}
}
public OnEntityDestroyed(iEntity)
{
	if (64 < iEntity < 2049)
	{
		g_flSpawnTime[iEntity] = 0.0;
		if(shouldNotDespawn[iEntity])
			shouldNotDespawn[iEntity] = false;
	}
}
public Action Hook_NoSpawn(int iEntity)
{
	SDKUnhook(iEntity, SDKHook_Spawn, Hook_NoSpawn);
	return Plugin_Handled;
}

public Action Hook_SpawnNkill(int iEntity)
{
	AcceptEntityInput(iEntity, "Kill");
	SDKUnhook(iEntity, SDKHook_SpawnPost, Hook_SpawnNkill);
	return Plugin_Continue;
}