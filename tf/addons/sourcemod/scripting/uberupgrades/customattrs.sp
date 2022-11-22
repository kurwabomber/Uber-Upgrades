// Includes
#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2_isPlayerInSpawn>
#include <dhooks>
#include <weapondata>
#include <tf2itemsinfo>
#include <tf_econ_data>
#include <tf2wearables>
#include <morecolors>
#include <razorstocks>
#include <vphysics>
#include <tf_ontakedamage>
#include <clientprefs>

// Plugin Info
public Plugin:myinfo =
{
	name = "UberUpgrades Custom Attribues",
	author = "Razor",
	description = "Plugin for handling custom attributes.",
	version = "2.0",
	url = "n/a",
}
//Sounds
//bounce

new g_nBounces[MAXENTITIES];
new bool:isProjectileHoming[MAXENTITIES];
new bool:isProjectileBoomerang[MAXENTITIES];
new Float:projectileHomingDegree[MAXENTITIES];
//new Float:isProjectileSlash[MAXENTITIES][2];
new bool:eurekaActive[MAXPLAYERS+1];
new Float:entitySpawnTime[MAXENTITIES]
new bool:StunShotBPS[MAXPLAYERS+1];
new bool:StunShotStun[MAXPLAYERS+1];
new bool:shouldAttack[MAXPLAYERS+1];
new bool:critStatus[MAXPLAYERS+1];
new bool:miniCritStatus[MAXPLAYERS+1];
new bool:RageActive[MAXPLAYERS+1];
new Float:miniCritStatusVictim[MAXPLAYERS+1];
new Float:miniCritStatusAttacker[MAXPLAYERS+1];
new Float:corrosiveDOT[MAXPLAYERS+1][MAXPLAYERS+1][2]
new Laser;
//lasers?
//Handles
Handle Hook_OnMyWeaponFired;
Handle g_SDKCallInitGrenade;
new Handle:particleToggle
new Handle:hudSync;
new Handle:hudAbility;
static Address g_offset_CTFPlayerShared_pOuter;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////Actual Hooks & Functions////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// On Plugin Start
public OnPluginStart()
{
	LoadTranslations("common.phrases.txt");
	HookEvent("player_hurt", Event_Playerhurt, EventHookMode_Pre)
	HookEvent("player_changeclass", Event_PlayerRespawn);
	HookEvent("player_spawn", Event_PlayerRespawn)
	HookEvent("player_death", Event_PlayerRespawn)
	HookEvent("post_inventory_application", Event_PlayerRespawn)
	HookEvent("player_teleported", Event_Teleported)
	HookEvent("mvm_reset_stats", Event_ResetStats);
	HookEvent("deploy_buff_banner",	Event_BuffDeployed);
	
	/*RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);*/
	CreateTimer(10.0, Timer_EveryTenSeconds, _, TIMER_REPEAT);
	CreateTimer(1.0, Timer_EverySecond, _, TIMER_REPEAT);
	CreateTimer(0.07, Timer_Every100MS, _, TIMER_REPEAT);

	OnPluginStart_RegisterWeaponData();
	logic = FindEntityByClassname(-1, "tf_objective_resource");
	hudSync = CreateHudSynchronizer();
	hudAbility = CreateHudSynchronizer();
	cvar_debug = CreateConVar("sm_debugmode", "0", "toggles chat spam");
	debugMode = view_as<bool>(GetConVarInt(cvar_debug));

	RegAdminCmd("sm_damage", Command_DealDamage, ADMFLAG_ROOT, "Deals damage to a player.")
	RegAdminCmd("sm_giveKills", Command_GiveKills, ADMFLAG_ROOT, "Feeds kills to a strange weapon.")
	//RegAdminCmd("sm_leveling", Command_levels, ADMFLAG_ROOT, "Enables/Disables Levels")
	
	AddCommandListener(eurekaAttempt, "eureka_teleport");

	Handle config = LoadGameConfigFile("tf2.uurevamped");
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(config, SDKConf_Virtual, "CTFWeaponBaseGrenadeProj::InitGrenade(int float)");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	g_SDKCallInitGrenade = EndPrepSDKCall();
	if(g_SDKCallInitGrenade==INVALID_HANDLE)
	{
		PrintToServer("CustomAttrs | Grenade Creation offset not found.");
	}
	
	
	Handle g_DHookOnModifyRage = DHookCreateFromConf(config, "CTFPlayerShared::ModifyRage()");
	
	if(g_DHookOnModifyRage == INVALID_HANDLE)
	{
		PrintToServer("CustomAttrs | Rage Modifier fucked up.");
	}
	DHookEnableDetour(g_DHookOnModifyRage, false, OnModifyRagePre);
	
	g_offset_CTFPlayerShared_pOuter = view_as<Address>(GameConfGetOffset(config, "CTFPlayerShared::m_pOuter"));

	config = LoadGameConfigFile("tf2.uurevamped");
	
	int offset = GameConfGetOffset(config, "CBasePlayer::OnMyWeaponFired");
	if (offset == -1)
		SetFailState("Missing offset for CBasePlayer::OnMyWeaponFired");
	
	Hook_OnMyWeaponFired = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, OnMyWeaponFired);
	DHookAddParam(Hook_OnMyWeaponFired, HookParamType_Int);
	
	delete config;
	
	for (int i = 1 ; i <= MaxClients ; i++)
		if(IsValidClient3(i))
			OnClientPutInServer(i);
			//reapply hooks
}
public OnAllPluginsLoaded()
{
	particleToggle = FindClientCookie("particleToggle");
}
public OnPluginEnd()
{
	hudSync.Close();
	hudAbility.Close();
	for (int i = 1 ; i <= MaxClients ; i++)
		if(IsValidClient3(i))
			OnClientDisconnect(i);
}
public Action:Command_DealDamage(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_damage \"target\" \"amount\"");
		return Plugin_Handled;
	}

	new String:strTarget[MAX_TARGET_LENGTH], String:strDmg[128], Float:Damage, String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, strDmg, sizeof(strDmg));
	Damage = StringToFloat(strDmg);	
	for(new i = 0; i < target_count; i++)
	{
		if(IsValidClient3(target_list[i]))
		{
			RadiationBuildup[target_list[i]] += Damage;
		}
	}
	return Plugin_Handled;
}
public Event_Playerhurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Float:damage = float(GetEventInt(event, "damageamount"));
	lastDamageTaken[client] = 0.0;
	if(critStatus[client])
	{
		SetEventBool(event, "crit", true);
		critStatus[client] = false;
	}
	else if(miniCritStatus[client])
	{
		SetEventBool(event, "minicrit", true);
		miniCritStatus[client] = false;
	}
	if(IsValidClient3(attacker))
	{
		new Address:knockoutPowerup = TF2Attrib_GetByName(attacker, "taunt is press and hold");
		if(knockoutPowerup != Address_Null)
		{
			new Float:knockoutPowerupValue = TF2Attrib_GetValue(knockoutPowerup);
			if(knockoutPowerupValue > 0.0){
				new CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(CWeapon))
				{
					if(_:TF2II_GetListedItemSlot(GetEntProp(CWeapon, Prop_Send, "m_iItemDefinitionIndex"),TF2_GetPlayerClass(attacker)) == 2)
					{
						ConcussionBuildup[client] += (damage/TF2_GetMaxHealth(client))*175.0;
						if(ConcussionBuildup[client] >= 100.0)
						{
							ConcussionBuildup[client] = 0.0;
							miniCritStatusVictim[client] = 10.0;
							TF2_StunPlayer(client, 1.0, 1.0, TF_STUNFLAGS_NORMALBONK, attacker);
						}
					}
				}
			}
		}
	}
	if(IsValidClient3(client))
	{
		new Address:revengePowerup = TF2Attrib_GetByName(client, "sniper penetrate players when charged");
		if(revengePowerup != Address_Null)
		{
			new Float:revengePowerupValue = TF2Attrib_GetValue(revengePowerup);
			if(revengePowerupValue > 0.0)
			{
				RageBuildup[client] += (damage/TF2_GetMaxHealth(client))*0.667;
				if(RageBuildup[client] > 1.0)
					RageBuildup[client]= 1.0;
			}
		}
		new Address:supernovaPowerupVictim = TF2Attrib_GetByName(client, "spawn with physics toy");
		if(supernovaPowerupVictim != Address_Null && TF2Attrib_GetValue(supernovaPowerupVictim) > 0.0)
		{
			SupernovaBuildup[client] += (damage/TF2_GetMaxHealth(client));
			if(SupernovaBuildup[client] > 0.0)
				SupernovaBuildup[client] = 1.0;
		}
	}
}
public MRESReturn OnModifyRagePre(Address pPlayerShared, Handle hParams) {
	int client = GetClientFromPlayerShared(pPlayerShared)
	if(TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		if(IsValidClient(client))
		{
			float flMultiplier = 1.0;
			
			new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (IsValidEntity(CWeapon))
			{
				new Address:FireRate1 = TF2Attrib_GetByName(CWeapon, "fire rate bonus");
				new Address:FireRate2 = TF2Attrib_GetByName(CWeapon, "fire rate penalty");
				new Address:FireRate3 = TF2Attrib_GetByName(CWeapon, "fire rate penalty HIDDEN");
				new Address:FireRate4 = TF2Attrib_GetByName(CWeapon, "fire rate bonus HIDDEN");
				
				if(FireRate1 != Address_Null)
				{
					flMultiplier *= TF2Attrib_GetValue(FireRate1);
				}
				if(FireRate2 != Address_Null)
				{
					flMultiplier *= TF2Attrib_GetValue(FireRate2);
				}
				if(FireRate3 != Address_Null)
				{
					flMultiplier *= TF2Attrib_GetValue(FireRate3);
				}
				if(FireRate4 != Address_Null)
				{
					flMultiplier *= TF2Attrib_GetValue(FireRate4);
				}
			}
			DHookSetParam(hParams, 1, 7.5 * flMultiplier);
		}
	}
	if(TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		DHookSetParam(hParams, 1, 0.4);
	}
	if(TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(CWeapon))
		{
			if(GetWeapon(client,1) == CWeapon)
			{
				DHookSetParam(hParams, 1, 1.0);
			}
		}
	}
	return MRES_ChangedHandled;
}
public Action:Timer_EverySecond(Handle:timer)// Self Explanitory. 
{
	if(IsMvM())
	{
		for(new i = 1; i < MaxClients; i++)
		{
			if(IsValidClient3(i))
			{
				if(IsFakeClient(i) && !IsClientObserver(i) && IsPlayerAlive(i))
				{
					BotTimer[i] -= 1.0;
					if(BotTimer[i] <= 0.0)
					{
						BotTimer[i] = 120.0;
						if(TF2_IsPlayerInCondition(i, TFCond_UberchargedHidden) || TF2Spawn_IsClientInSpawn(i))
						{
							PrintToServer("Slaying %N due to staying ubered for too long.", i);
							ForcePlayerSuicide(i);
						}
					}
				}
			}
		}
	}
/*	if(LevelsToggle == 1)
	{
		for(new client = 0; client < MaxClients; client++)
		{
			ChatPerSecond[client] = 2;
			if(IsValidClient(client))
			{
				PlayerLevel[client] = 1.0;
				new primary = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Primary);
				new secondary = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Secondary);
				new melee = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Melee);
				
				new Address:dmgReduction = TF2Attrib_GetByName(client, "sniper zoom penalty");
				new Address:capActive = TF2Attrib_GetByName(client, "tool escrow until date")
				new Address:Defense = TF2Attrib_GetByName(client, "is throwable chargeable");
				new Float:fl_ArmorCap = 1.0;
				new Float:DefenseMult = 1.0;
				new Float:ArmorMult = 1.0;
				
				if(capActive != Address_Null)
				{
					ArmorMult = TF2Attrib_GetValue(capActive);
				}
				if(Defense != Address_Null)
				{
					DefenseMult = TF2Attrib_GetValue(Defense);
				}
				fl_ArmorCap = Pow(ArmorMult*DefenseMult, 2.45) + 1.0;
				if(dmgReduction != Address_Null)
				{
					fl_ArmorCap /= TF2Attrib_GetValue(dmgReduction);
				}
				
				new Float:DelayAmount = 1.0;
				new Address:armorDelay = TF2Attrib_GetByName(client, "tmp dmgbuff on hit");
				if(armorDelay != Address_Null)
				{
					DelayAmount /= TF2Attrib_GetValue(armorDelay) + 1.0;
				}
				new Float:ArmorPower = 0.0 + Pow(fl_ArmorCap / 4.0, 0.5) + Pow(TF2_GetMaxHealth(client)/20.0, 0.6) + 1/Pow(DelayAmount,1.33);
				
				new Float:PrimaryPower = 0.0;
				if(IsValidEntity(primary))
				{
					PrimaryPower = 0.0 + Pow((TF2_GetWeaponclassDPS(client, primary) * TF2_GetDPSModifiers(client, primary))/30.0, 0.4);
				}
				new Float:SecondaryPower = 0.0;
				if(IsValidEntity(secondary))
				{
					SecondaryPower = 0.0 + Pow((TF2_GetWeaponclassDPS(client, secondary) * TF2_GetDPSModifiers(client, secondary))/30.0, 0.4);
				}
				new Float:MeleePower = 0.0;
				if(IsValidEntity(melee))
				{
					MeleePower = 0.0 + Pow((TF2_GetWeaponclassDPS(client, melee) * TF2_GetDPSModifiers(client, melee))/30.0, 0.4);
				}
				new Float:arcanePower = 1.0;
				new Address:ArcaneActive = TF2Attrib_GetByName(client, "medigun crit fire percent bar deplete")
				if(ArcaneActive != Address_Null)
				{
					arcanePower = TF2Attrib_GetValue(ArcaneActive);
				}
				
				new Float:arcaneDamageMult = 1.0;
				new Address:ArcaneDamageActive = TF2Attrib_GetByName(client, "sticky detonate mode")
				if(ArcaneDamageActive != Address_Null)
				{
					arcaneDamageMult = TF2Attrib_GetValue(ArcaneDamageActive) * Pow(arcanePower, 4.0);
				}
				
				new Float:MaxFocus = 100.0;
				new Address:focusActive = TF2Attrib_GetByName(client, "medigun crit bullet percent bar deplete")
				if(focusActive != Address_Null)
				{
					MaxFocus = (TF2Attrib_GetValue(focusActive)+100.0)*Pow(arcanePower, 2.0);
				}
				else
				{
					MaxFocus = 100.0*arcanePower;
				}
				
				new Float:arcaneRegen = 1.0;
				new Address:regenActive = TF2Attrib_GetByName(client, "medigun crit blast percent bar deplete")
				if(regenActive != Address_Null)
				{
					arcaneRegen = MaxFocus * 0.0005 * TF2Attrib_GetValue(regenActive) * Pow(arcanePower, 2.0);
				}
				else
				{
					arcaneRegen = MaxFocus * 0.0005 * Pow(arcanePower, 2.0);
				}
				new attunement = 1;
				new Address:attuneActive = TF2Attrib_GetByName(client, "throwable fire speed");
				if(attuneActive != Address_Null)
				{
					attunement += RoundToNearest(TF2Attrib_GetValue(attuneActive));
				}
				new Float:ArcanePower = Pow(Pow(arcaneDamageMult, 1.5)+ (MaxFocus/100.0) + (arcaneRegen/GetTickInterval()/2.0), 0.6) + (attunement * 5.0);
				
				switch(TF2_GetPlayerClass(client))
				{
					case TFClass_Engineer:
					{
						new Float:theoreticalSentryDPS = 128.0
						if(IsValidEntity(melee))
						{
							new Address:sentryDmg1 = TF2Attrib_GetByName(melee, "engy sentry damage bonus")
							if(sentryDmg1 != Address_Null)
							{
								theoreticalSentryDPS *= (TF2Attrib_GetValue(sentryDmg1));
							}
							new Address:sentryDmg4 = TF2Attrib_GetByName(melee, "throwable detonation time")
							if(sentryDmg4 != Address_Null)
							{
								theoreticalSentryDPS *= (TF2Attrib_GetValue(sentryDmg4));
							}
							new Address:sentryDmg5 = TF2Attrib_GetByName(melee, "engy sentry fire rate increased")
							if(sentryDmg5 != Address_Null)
							{
								theoreticalSentryDPS *= (TF2Attrib_GetValue(sentryDmg5));
							}
							new Address:sentryDmg6 = TF2Attrib_GetByName(melee, "throwable fire speed")
							if(sentryDmg6 != Address_Null)
							{
								theoreticalSentryDPS *= (TF2Attrib_GetValue(sentryDmg6));
							}
							new Address:sentryDmg7 = TF2Attrib_GetByName(melee, "override projectile type")
							if(sentryDmg7 != Address_Null)
							{
								if(TF2Attrib_GetValue(sentryDmg7))
								{
									theoreticalSentryDPS *= 1.1;
								}
							}
						}
						if(IsValidEntity(secondary))
						{
							new Address:sentryDmg3 = TF2Attrib_GetByName(secondary, "ring of fire while aiming")
							if(sentryDmg3 != Address_Null)
							{
								theoreticalSentryDPS *= Pow(TF2Attrib_GetValue(sentryDmg3),1.25);
							}
						}
						ArmorPower *= 1.2;
						PlayerLevel[client] += Pow(theoreticalSentryDPS/30.0, 0.4);
					}
					case TFClass_Medic:
					{
						new Float:SupportPower = 1.0;
						if(IsValidEntity(secondary))
						{
							new Address:medigun1 = TF2Attrib_GetByName(secondary, "heal rate bonus")
							if(medigun1 != Address_Null)
							{
								SupportPower *= Pow(TF2Attrib_GetValue(medigun1),1.1);
							}
							new Address:medigun2 = TF2Attrib_GetByName(secondary, "heal rate penalty")
							if(medigun2 != Address_Null)
							{
								SupportPower *= Pow(TF2Attrib_GetValue(medigun2),1.1);
							}
							new Address:medigun3 = TF2Attrib_GetByName(secondary, "ubercharge rate bonus")
							if(medigun3 != Address_Null)
							{
								SupportPower *= Pow(TF2Attrib_GetValue(medigun3),1.25);
							}
							new Address:medigun4 = TF2Attrib_GetByName(secondary, "overheal fill rate reduced")
							if(medigun4 != Address_Null)
							{
								SupportPower *= Pow(TF2Attrib_GetValue(medigun4),1.2);
							}
							new Address:medigun5 = TF2Attrib_GetByName(secondary, "overheal bonus")
							if(medigun5 != Address_Null)
							{
								SupportPower *= Pow(TF2Attrib_GetValue(medigun5),1.8);
							}
							new Address:medigun6 = TF2Attrib_GetByName(secondary, "hidden secondary max ammo penalty")
							if(medigun6 != Address_Null)
							{
								SupportPower *= Pow(TF2Attrib_GetValue(medigun6),2.25);
							}
						}
						PlayerLevel[client] += SupportPower;
					}
				}
				PlayerLevel[client] += (ArcanePower + ArmorPower + PrimaryPower + SecondaryPower + MeleePower);
			}
		}
	}*/
	debugMode = view_as<bool>(GetConVarInt(cvar_debug));
}
public Action:Timer_EveryTenSeconds(Handle:timer)// Self Explanitory. 
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient3(client) && IsPlayerAlive(client))
		{
			new melee = GetWeapon(client, 2);
			if(IsValidEntity(melee) && GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex") == 307)
			{
				new Address:MaxChargesActive = TF2Attrib_GetByName(melee, "zombiezombiezombiezombie");
				new MaxCharges = 1;
				if(MaxChargesActive != Address_Null)
				{
					MaxCharges += RoundToNearest(TF2Attrib_GetValue(MaxChargesActive));
				}
				CaberUses[client] = MaxCharges;
			}
			new Address:bossType = TF2Attrib_GetByName(client, "damage force increase text");
			if(bossType != Address_Null && TF2Attrib_GetValue(bossType) > 0.0)
			{
				new Float:bossValue = TF2Attrib_GetValue(bossType);
				switch(bossValue)
				{
					case 3.0:
					{
						CreateParticle(client, "critgun_weaponmodel_red", true, "", 10.0,_,_,1);
						TE_SendToAll();
						SetEntityRenderColor(client, 190,0,0,255);
						new counter = 0;
						new bool:clientList[MAXPLAYERS+1];
						for(new i = 1; i<MaxClients; i++)
						{
							if (IsValidClient3(i) && IsPlayerAlive(i))
							{
								if(GetClientTeam(client) == GetClientTeam(i))
								{
									if(GetEntProp(i, Prop_Send, "m_bUseBossHealthBar") == 0 && !TF2_IsPlayerInCondition(i, TFCond_KingAura))
									{
										new Float:clientpos[3],Float:targetpos[3];
										GetClientAbsOrigin(client, clientpos);
										GetClientAbsOrigin(i, targetpos);
										new Float:distance = GetVectorDistance(clientpos, targetpos);
										if(distance <= 900.0)
										{
											counter++;
											clientList[i] = true;
											if(counter == 5)
											{
												break;
											}
										}
									}
								}
							}
						}
						if(counter > 2)
						{
							TF2_AddCondition(client, TFCond_MVMBotRadiowave, 2.0);
							
							for(new buffed = 1; buffed<MaxClients;buffed++)
							{
								if(clientList[buffed])
								{
									TF2_AddCondition(buffed, TFCond_MVMBotRadiowave, 1.0);
									TF2_AddCondition(buffed, TFCond_KingAura, 1000.0);
									TF2Attrib_SetByName(buffed, "damage bonus HIDDEN", 2.5);
									TF2Attrib_SetByName(buffed, "crit mod disabled hidden", 0.5);
									SetEntityRenderColor(buffed, 190,0,0,255);
								}
							}
						}
					}
					case 5.0:
					{
						new spellCasted = GetRandomInt(0,3);
						if(spellCasted == 0)
						{
							new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
							if(IsValidEntity(CWeapon))
							{
								new Float:ClientPos[3];
								new Float:flamePos[3];
								GetClientAbsOrigin(client,ClientPos);
								new Float:sphereRadius = 700.0;
								new Float:tempdiameter;
								for(new i=-9;i<=8;i++){
									new Float:rad=float(i*10)/360.0*(3.14159265*2);
									tempdiameter=sphereRadius*Cosine(rad)*2;
									new Float:heightoffset=sphereRadius*Sine(rad);

									//PrintToChatAll("degree %d rad %f sin %f cos %f radius %f offset %f",i*10,rad,Sine(rad),Cosine(rad),radius,heightoffset);

									new Float:origin[3];
									origin[0]=ClientPos[0];
									origin[1]=ClientPos[1];
									origin[2]=ClientPos[2]+heightoffset;
									TE_SetupBeamRingPoint(origin, 0.0, tempdiameter, Laser, spriteIndex, 0, 0, 1.0, 2.0, 0.0, {255,200,0,122}, 1500, 0);
									TE_SendToAll();
								}
								
								//scripting god
								flamePos = ClientPos;
								flamePos[2] += 400.0;
								//ohhhhh myyyyy god!!!!!!
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[0] += 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[1] += 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[1] -= 800.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[0] -= 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[1] += 800.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[0] -= 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[1] -= 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[1] -= 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								
								
								new Float:DMGDealt = 3.0 * TF2_GetDPSModifiers(client,CWeapon);
								for(new i = 1; i<MAXENTITIES;i++)
								{
									if(IsValidForDamage(i))
									{
										if(IsOnDifferentTeams(client,i))
										{
											new Float:VictimPos[3];
											GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
											new Float:Distance = GetVectorDistance(ClientPos,VictimPos);
											if(Distance <= 800.0)
											{
												CreateParticle(i, "dragons_fury_effect_parent", true, "", 2.0);
												CreateParticle(i, "utaunt_glowyplayer_orange_glow", true, "", 2.0,_,_,1);
												DOTStock(i,client,DMGDealt,-1,DMG_BURN,20,1.0,0.12,true);
											}
										}
									}
								}
							}
						}
						else if(spellCasted == 2)
						{
							BleedBuildup[client] = 0.0;
							RadiationBuildup[client] = 0.0;
							miniCritStatusAttacker[client] = 10.0
							TF2_AddCondition(client, TFCond_DodgeChance, 2.5);
							TF2_AddCondition(client, TFCond_AfterburnImmune, 2.5);
							TF2_AddCondition(client, TFCond_UberchargedHidden, 0.01);
							EmitSoundToAll(SOUND_ADRENALINE, client, -1, 150, 0, 1.0);
							CreateParticle(client, "utaunt_tarotcard_red_wind", true, "", 10.0);
						}
						else if(spellCasted == 3 || spellCasted == 1)
						{
							new iTeam = GetClientTeam(client);
							for(new i=0;i<3;i++)
							{
								new iEntity = CreateEntityByName("tf_projectile_flare");
								if (IsValidEdict(iEntity)) 
								{
									new Float:fAngles[3]
									new Float:fOrigin[3]
									new Float:vBuffer[3]
									new Float:vRight[3]
									new Float:fVelocity[3]
									new Float:fwd[3]
									SetEntityRenderColor(iEntity, 255, 255, 255, 0);
									SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

									SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
									SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
									SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
									SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
									SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008 + 0x0004);
									SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
									SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 2);
												
									GetClientEyePosition(client, fOrigin);
									GetClientEyeAngles(client,fAngles);
									
									GetAngleVectors(fAngles, vBuffer, vRight, NULL_VECTOR);
									GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
									ScaleVector(fwd, 60.0);
									ScaleVector(vRight, 30.0*(i-1))
									AddVectors(fOrigin, vRight, fOrigin);
									AddVectors(fOrigin, fwd, fOrigin);
									
									new Float:Speed = 1200.0;
									fVelocity[0] = vBuffer[0]*Speed;
									fVelocity[1] = vBuffer[1]*Speed;
									fVelocity[2] = vBuffer[2]*Speed;
									SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
									TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
									DispatchSpawn(iEntity);
									SetEntityGravity(iEntity,0.01);
									
									SDKHook(iEntity, SDKHook_Touch, OnCollisionPhotoViscerator);
									CreateTimer(0.01, HomingFlareThink, EntIndexToEntRef(iEntity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
									CreateParticle(iEntity, "utaunt_auroraglow_green_parent", true, "", 5.0);
									CreateTimer(5.0, SelfDestruct, EntIndexToEntRef(iEntity));
								}
							}
						}
					}
					case 6.0:
					{
						TF2Attrib_SetByName(client, "Attack not cancel charge", 1.0);
						TF2Attrib_SetByName(client, "full charge turn control", 100.0);
						TF2Attrib_SetByName(client, "charge time increased", 10000000.0);
						TF2Attrib_SetByName(client, "charge recharge rate increased", 100.0);
						TF2_AddCondition(client, TFCond_Charging, 15.0);
						new iEntity = CreateEntityByName("eyeball_boss");
						new iTeam = GetClientTeam(client);
						if (IsValidEdict(iEntity)) 
						{
							new Float:fOrigin[3]
							SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

							SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
							SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
										
							GetClientEyePosition(client, fOrigin);
							TeleportEntity(iEntity, fOrigin, NULL_VECTOR, NULL_VECTOR);
							DispatchSpawn(iEntity);
							
							CreateTimer(9.0, SelfDestruct, EntIndexToEntRef(iEntity));
							jarateWeapon[iEntity] = EntIndexToEntRef(client);
						}
					}
					case 7.0:
					{
						new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
						if(IsValidEntity(CWeapon))
						{
							CreateParticle(CWeapon, "utaunt_auroraglow_orange_parent", true, "", 10.0,_,_,1);
							TE_SendToAll();
								
							new Float:clientpos[3];
							GetClientAbsOrigin(client,clientpos);
							clientpos[0] += GetRandomFloat(-200.0,200.0);
							clientpos[1] += GetRandomFloat(-200.0,200.0);
							clientpos[2] = getLowestPosition(clientpos);
							// define where the lightning strike starts
							new Float:startpos[3];
							startpos[0] = clientpos[0];
							startpos[1] = clientpos[1];
							startpos[2] = clientpos[2] + 1600;
							
							// define the color of the strike
							new iTeam = GetClientTeam(client);
							//PrintToChat(client, "%i", iTeam);
							new color[4];
							if(iTeam == 2)
							{
								color = {255, 0, 0, 255};
							}
							else if (iTeam == 3)
							{
								color = {0, 0, 255, 255};
							}
							
							// define the direction of the sparks
							new Float:dir[3] = {0.0, 0.0, 0.0};
							
							TE_SetupBeamPoints(startpos, clientpos, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
							TE_SendToAll();
							
							TE_SetupSparks(clientpos, dir, 5000, 1000);
							TE_SendToAll();
							
							TE_SetupEnergySplash(clientpos, dir, false);
							TE_SendToAll();
							
							TE_SetupSmoke(clientpos, g_SmokeSprite, 5.0, 10);
							TE_SendToAll();
							
							TE_SetupBeamRingPoint(clientpos, 20.0, 650.0, g_LightningSprite, spriteIndex, 0, 5, 0.5, 10.0, 1.0, color, 200, 0);
							TE_SendToAll();
							
							CreateParticle(-1, "utaunt_electricity_cloud_parent_WB", false, "", 5.0, startpos);
							
							EmitAmbientSound("ambient/explosions/explode_9.wav", startpos, client, 50);
							
							new Float:LightningDamage = 150.0*TF2_GetDPSModifiers(client,CWeapon);
						
							for(new i = 1; i<MAXENTITIES;i++)
							{
								if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
								{
									new Float:VictimPos[3];
									GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
									VictimPos[2] += 30.0;
									new Float:Distance = GetVectorDistance(clientpos,VictimPos);
									if(Distance <= 500.0)
									{
										if(IsPointVisible(clientpos,VictimPos))
										{
											Entity_Hurt(i, RoundToNearest(LightningDamage), client, DMG_GENERIC);
											if(IsValidClient3(i))
											{
												new Float:velocity[3];
												velocity[0]=0.0;
												velocity[1]=0.0;
												velocity[2]=1800.0;
												TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, velocity);
												new Handle:hPack = CreateDataPack();
												WritePackCell(hPack, EntIndexToEntRef(i));
												WritePackCell(hPack, EntIndexToEntRef(client));
												CreateTimer(0.5,thunderClapPart2,hPack);
											}
										}
									}
								}
							}
						}
						CreateParticle(client, "utaunt_arcane_yellow_parent", true, "", 10.0);
					}
				}
			}
		}
	}
}
/*
public Action:Command_Say(client, args)
{
	if (!IsValidClient3(client))
	{
		return Plugin_Continue;
	}
	if(LevelsToggle != 1)
	{
		return Plugin_Continue;
	}
	if(ChatPerSecond[client] == 0)
	{
		return Plugin_Stop;
	}
	
	decl	String:sMessage[256];
	GetCmdArgString(sMessage, sizeof(sMessage));
	
	return ProcessMessage(client, false, sMessage, sizeof(sMessage));
}

public Action:Command_SayTeam(client, args)
{
	if (!IsValidClient3(client))
	{
		return Plugin_Continue;
	}
	if(LevelsToggle != 1)
	{
		return Plugin_Continue;
	}
	if(ChatPerSecond[client] == 0)
	{
		return Plugin_Stop;
	}
	decl String:sMessage[256];
	GetCmdArgString(sMessage, sizeof(sMessage));
	
	return ProcessMessage(client, true, sMessage, sizeof(sMessage));
}
stock Action:ProcessMessage(client, bool:teamchat, String:message[], maxlength)
{
	new team = GetClientTeam(client);
	
	ReplaceString(message, maxlength, "%", "pct");
	StripQuotes(message);
	TrimString(message);
	
	decl String:sBasicPartN[1280];
	
	if (IsValidClient(client) && !IsStringBlank(message))
	{
		if(message[0] == '!' || message[0] == '/' || message[0] == '@')
		{
			PrintToConsole(client,"Issued Command : %s",message);
			return Plugin_Stop;
		}
		ChatPerSecond[client]--;
		if(teamchat || !IsPlayerAlive(client))
		{
			return Plugin_Continue;
		}
		if((team == 2 || team == 3))
		{
			if(team == 2)
			{
				if(PlayerLevel[client] > 5000)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{white}★★ LVL %s ★★ {default}| {red}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 2000)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{white}★ LVL %s ★ {default}| {red}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 1000)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{blue}LVL %s {default}| {red}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 800)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{green}LVL %s {default}| {red}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 600)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{red}LVL %s {default}| {red}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 400)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{orange}LVL %s {default}| {red}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 200)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{gold}LVL %s {default}| {red}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 100)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{silver}LVL %s {default}| {red}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 50)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{brown}LVL %s {default}| {red}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{gray}LVL %s {default}| {red}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
			}
			else if(team == 3)
			{
				if(PlayerLevel[client] > 5000)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{white}★★ LVL %s ★★ {default}| {blue}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 2000)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{white}★ LVL %s ★ {default}| {blue}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 1000)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{blue}LVL %s {default}| {blue}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 800)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{green}LVL %s {default}| {blue}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 600)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{red}LVL %s {default}| {blue}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 400)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{orange}LVL %s {default}| {blue}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 200)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{gold}LVL %s {default}| {blue}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 100)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{silver}LVL %s {default}| {blue}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else if(PlayerLevel[client] > 50)
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{brown}LVL %s {default}| {blue}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
				else
				{
					Format(sBasicPartN, sizeof(sBasicPartN), "{gray}LVL %s {default}| {blue}%N {default}:  %s", GetAlphabetForm(PlayerLevel[client]), client, message);
				}
			}
			CPrintToChatAll("%s",sBasicPartN);
			PrintToServer("LVL %s | %N : %s",GetAlphabetForm(PlayerLevel[client]),client,message);
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
*/
ExplosiveArrow(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEntity(entity))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(IsValidClient(owner))
			{
				new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new Address:ignitionChance = TF2Attrib_GetByName(CWeapon, "Wrench index");
					if(ignitionChance != Address_Null)
					{
						if(TF2Attrib_GetValue(ignitionChance) >= GetRandomFloat(0.0, 1.0))
						{
							SetEntProp(entity, Prop_Send, "m_bArrowAlight", 1);
							
							new Address:ignitionExplosion = TF2Attrib_GetByName(CWeapon, "damage applies to sappers");
							if(ignitionExplosion != Address_Null && TF2Attrib_GetValue(ignitionExplosion) > 0.0)
							{
								jarateWeapon[entity] = EntIndexToEntRef(CWeapon)
								SDKHook(entity, SDKHook_StartTouchPost, IgnitionArrowCollision);
							}
						}
					}
					if(fl_ArrowStormDuration[owner] > 0.0)
					{
						jarateWeapon[entity] = EntIndexToEntRef(CWeapon)
						SDKHook(entity, SDKHook_StartTouchPost, ExplosiveArrowCollision);
					}
				}
			}
		}
	}
}
public Action:IgnitionArrowCollision(entity, client)
{		
	if(!IsValidEntity(entity))
		return Plugin_Continue;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return Plugin_Continue;
	
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;
		
	new Float:projvec[3];
	
	if(HasEntProp(entity, Prop_Data, "m_vecOrigin"))
	{
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", projvec);
		new CWeapon = EntRefToEntIndex(jarateWeapon[entity]);
		if(IsValidEntity(CWeapon))
		{
			new Float:damageDealt = 0.0,Float:Radius=144.0;
			new Address:ignitionExplosion = TF2Attrib_GetByName(CWeapon, "damage applies to sappers");
			if(ignitionExplosion != Address_Null)
			{
				damageDealt = TF2Attrib_GetValue(ignitionExplosion);
			}
			new Address:ignitionExplosionRadius = TF2Attrib_GetByName(CWeapon, "building cost reduction");
			if(ignitionExplosionRadius != Address_Null)
			{
				Radius *= TF2Attrib_GetValue(ignitionExplosionRadius);
			}
			EntityExplosion(owner, damageDealt * TF2_GetDamageModifiers(owner, CWeapon), Radius, projvec, _, _,entity,_,_,CWeapon,_,_,true);
		}
	}
	return Plugin_Continue;
}
public Action:ExplosiveArrowCollision(entity, client)
{		
	if(!IsValidEntity(entity))
		return Plugin_Continue;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return Plugin_Continue;
	
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;
		
	new Float:projvec[3];
	
	if(HasEntProp(entity, Prop_Data, "m_vecOrigin"))
	{
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", projvec);
		new CWeapon = EntRefToEntIndex(jarateWeapon[entity]);
		if(IsValidEntity(CWeapon))
		{
			EntityExplosion(owner, TF2_GetDamageModifiers(owner, CWeapon) * 250.0, 400.0, projvec, 1, _,entity,1.0,_,_,0.75);
		}
		fl_ArrowStormDuration[owner]--;
	}
	return Plugin_Continue;
}
public Action:projectileCollision(entity, client)
{
	if(!IsValidEntity(entity)) return Plugin_Stop;
	decl String:strName[64];
	GetEntityClassname(client, strName, 64)
	decl String:entName[64]
	GetEntityClassname(entity, entName, 64);
	if(StrEqual(strName,entName,false))
	{	
		if(StrEqual(strName,entName,false))
		{
			new Float:origin[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
			origin[0] += GetRandomFloat(-4.0,4.0)
			origin[1] += GetRandomFloat(-4.0,4.0)
			TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
		}
	}
	if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
	{
		new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
		if(owner != client && (IsValidClient3(client) || client == 0 || StrEqual(strName,"func_door",false) || StrEqual(strName,"prop_dynamic",false)
		|| StrEqual(strName,"prop_physics",false) || StrContains(strName,"tf",false)))
		{
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}
public Action:OnCollisionWarriorArrow(entity, client)
{
	decl String:strName[128];
	GetEntityClassname(client, strName, 128)
	decl String:strName1[128];
	GetEntityClassname(entity, strName1, 128)
	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			if(IsOnDifferentTeams(owner,client))
			{
				new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new Float:damageDealt = 30.0;
					new Address:multiHitActive = TF2Attrib_GetByName(CWeapon, "taunt move acceleration time");
					if(multiHitActive != Address_Null)
					{
						damageDealt *= TF2Attrib_GetValue(multiHitActive) + 1.0;
					}
					Entity_Hurt(client, RoundToNearest(damageDealt*TF2_GetDamageModifiers(owner, CWeapon, false)), owner, DMG_BULLET);
				}
				RemoveEntity(entity);
			}
		}
	}
	return Plugin_Stop;
}
public Action:OnCollisionBossArrow(entity, client)
{
	decl String:strName[128];
	GetEntityClassname(client, strName, 128)
	decl String:strName1[128];
	GetEntityClassname(entity, strName1, 128)
	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			if(IsOnDifferentTeams(owner,client))
			{
				new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new Float:damageDealt = 240.0;
					Entity_Hurt(client, RoundToNearest(damageDealt*TF2_GetDamageModifiers(owner, CWeapon, false)), owner, DMG_BULLET);
					if(IsValidClient3(client))
					{
						RadiationBuildup[client] += 100.0;
						checkRadiation(client,owner);
					}
				}
				RemoveEntity(entity);
			}
		}
	}
	return Plugin_Stop;
}
public Action:OnCollisionArrow(entity, client)
{
	decl String:strName[128];
	GetEntityClassname(client, strName, 128)
	decl String:strName1[128];
	GetEntityClassname(entity, strName1, 128)
	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(CWeapon))
			{
				Entity_Hurt(client, RoundToNearest(50.0*TF2_GetDamageModifiers(owner, CWeapon, false)), owner, DMG_BULLET);
			}
			RemoveEntity(entity);
		}
	}
	if(StrContains(strName,"trigger_",false) || StrEqual(strName,strName1,false))
	{	
		if(StrEqual(strName,strName1,false))
		{
			new Float:origin[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
			origin[0] += GetRandomFloat(-4.0,4.0)
			origin[1] += GetRandomFloat(-4.0,4.0)
			TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
		}
	}
	return Plugin_Stop;
}
stock void ZeroVector(float vec[3])
{
    vec[0] = vec[1] = vec[2] = 0.0;
}
public Event_BuffDeployed( Handle:event, const String:name[], bool:broadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "buff_owner" ) );
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		isBuffActive[client] = true;
	}

	return;
}
public void TF2_OnConditionAdded(client, TFCond:cond)
{
	if (IsValidClient3(client) && IsPlayerAlive(client))
	{
		switch(cond)
		{
			case TFCond_FocusBuff:
			{
				isBuffActive[client] = true;
			}
			case TFCond_CritMmmph:
			{
				isBuffActive[client] = true;
			}
			case TFCond_Buffed:
			{
				TF2_RemoveCondition(client, TFCond_Buffed);
			}
			case TFCond_DefenseBuffed:
			{
				TF2_RemoveCondition(client, TFCond_DefenseBuffed);
			}
			case TFCond_RegenBuffed:
			{
				TF2_RemoveCondition(client, TFCond_RegenBuffed);
			}
			case TFCond_Jarated:
			{
				TF2_RemoveCondition(client, TFCond_Jarated);
				miniCritStatusVictim[client] = 8.0;
			}
			case TFCond_MarkedForDeath:
			{
				TF2_RemoveCondition(client, TFCond_MarkedForDeath);
				miniCritStatusVictim[client] = 4.0;
			}
			case TFCond_MarkedForDeathSilent:
			{
				TF2_RemoveCondition(client, TFCond_MarkedForDeathSilent);
				miniCritStatusVictim[client] = 4.0;
			}
			case TFCond_Taunting:
			{
				new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new String:classname[64];
					GetEdictClassname(CWeapon, classname, sizeof(classname)); 
					if(StrContains(classname, "tf_weapon_lunchbox",false) == 0)
					{//Hook onto all sandvich stuff or something to that effect
						new Address:MiniCritActive = TF2Attrib_GetByName(CWeapon, "duel loser account id");
						if(MiniCritActive != Address_Null)
						{
							miniCritStatusVictim[client] = 16.0;
							miniCritStatusAttacker[client] = 16.0;
							TF2_AddCondition(client, TFCond_RestrictToMelee, 16.0);
							TF2_AddCondition(client, TFCond_SpeedBuffAlly, 16.0);
							new melee = GetWeapon(client, 2)
							if(IsValidEntity(melee) && HasEntProp(melee, Prop_Send, "m_iItemDefinitionIndex"))
							{
								SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon",melee);
								EquipPlayerWeapon(client, melee);
							}
						}
					}
				}
			}
		}
		new Address:agilityPowerup = TF2Attrib_GetByName(client, "store sort override DEPRECATED");		
		if(agilityPowerup != Address_Null)
		{
			new Float:agilityPowerupValue = TF2Attrib_GetValue(agilityPowerup);
			if(agilityPowerupValue > 0.0)
			{
				switch(cond)
				{
					case TFCond_Slowed:
					{
						TF2_RemoveCondition(client, TFCond_Slowed);
					}
					case TFCond_TeleportedGlow:
					{
						TF2_RemoveCondition(client, TFCond_TeleportedGlow);
					}
					case TFCond_Dazed:
					{
						TF2_RemoveCondition(client, TFCond_Dazed);
					}
					case TFCond_FreezeInput:
					{
						TF2_RemoveCondition(client, TFCond_FreezeInput);
					}
					case TFCond_GrappledToPlayer:
					{
						TF2_RemoveCondition(client, TFCond_GrappledToPlayer);
					}
					case TFCond_LostFooting:
					{
						TF2_RemoveCondition(client, TFCond_LostFooting);
					}
					case TFCond_AirCurrent:
					{
						TF2_RemoveCondition(client, TFCond_AirCurrent);
					}
				}
			}
		}
	}
}
public Event_ResetStats(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:responseBuffer[4096];
	new ObjectiveEntity = FindEntityByClassname(-1, "tf_objective_resource");
	GetEntPropString(ObjectiveEntity, Prop_Send, "m_iszMvMPopfileName", responseBuffer, sizeof(responseBuffer));
	if(StrContains(responseBuffer, "UU", false) != -1)
	{
		if(StrContains(responseBuffer, "_Boss_Rush", false) != -1)
		{
			DefenseMod = 2.35;
			DamageMod = 2.55;
			DefenseIncreasePerWaveMod = 0.03;
			OverallMod = 1.8;
			PrintToServer("UU | Set Mission to Boss Rush");
		}
		else if(StrContains(responseBuffer, "_Defend", false) != -1)
		{
			DefenseMod = 2.55;
			DamageMod = 2.55;
			DefenseIncreasePerWaveMod = 0.03;
			OverallMod = 1.8;
			PrintToServer("UU | Set Mission to Defend");
		}
		else if(StrContains(responseBuffer, "_Extreme", false) != -1)
		{
			DefenseMod = 2.35;
			DamageMod = 2.55;
			DefenseIncreasePerWaveMod = 0.03;
			OverallMod = 1.35;
			PrintToServer("UU | Set Mission to Extreme");
		}
		else if(StrContains(responseBuffer, "_Hard", false) != -1)
		{
			DefenseMod = 2.35;
			DamageMod = 2.55;
			DefenseIncreasePerWaveMod = 0.03;
			OverallMod = 1.1;
			PrintToServer("UU | Set Mission to Hard");
		}
		else if(StrContains(responseBuffer, "_Intermediate", false) != -1)
		{
			DefenseMod = 2.0;
			DamageMod = 2.3;
			DefenseIncreasePerWaveMod = 0.015;
			OverallMod = 1.5;
			PrintToServer("UU | Set Mission to Intermediate");
		}
		else if(StrContains(responseBuffer, "_Rush", false) != -1)
		{
			DefenseMod = 2.35;
			DamageMod = 2.55;
			DefenseIncreasePerWaveMod = 0.03;
			OverallMod = 1.1;
			PrintToServer("UU | Set Mission to Rush");
		}
		else if(StrContains(responseBuffer, "_Survival", false) != -1)
		{
			DefenseMod = 2.35;
			DamageMod = 2.55;
			DefenseIncreasePerWaveMod = 0.03;
			OverallMod = 1.5;
			PrintToServer("UU | Set Mission to Survival");
		}
		else
		{
			DefenseMod = 1.75;
			DamageMod = 2.1;
			DefenseIncreasePerWaveMod = 0.0;
			OverallMod = 1.0;
			PrintToServer("UU | Set Mission to Default");
		}
	}
}
public Event_PlayerRespawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsValidClient3(client))
	{
		TF2_RemoveCondition(client,TFCond_Plague);
		BleedBuildup[client] = 0.0;
		RadiationBuildup[client] = 0.0;
		RageActive[client] = false;
		RageBuildup[client] = 0.0;
		SupernovaBuildup[client] = 0.0;
		ConcussionBuildup[client] = 0.0;
		fl_HighestFireDamage[client] = 0.0;
		miniCritStatusAttacker[client] = 0.0;
		miniCritStatusVictim[client] = 0.0;
		CurrentSlowTimer[client] = 0.0;
		canShootAgain[client] = true
		meleeLimiter[client] = 0;
		lastDamageTaken[client] = 0.0;
		SetEntityRenderColor(client, 255,255,255,255);
		for(new i=1;i<MaxClients;i++)
		{
			corrosiveDOT[client][i][0] = 0.0;
			corrosiveDOT[client][i][1] = 0.0;
		}
	}
	if(IsMvM() && IsFakeClient(client))
	{
		BotTimer[client] = 120.0;
		if(IsValidForDamage(TankTeleporter))
		{
			new String:classname[128]; 
			GetEdictClassname(TankTeleporter, classname, sizeof(classname)); 
			if(!strcmp("tank_boss", classname))
			{
				new Float:telePos[3];
				GetEntPropVector(TankTeleporter,Prop_Send, "m_vecOrigin",telePos);
				telePos[2]+= 250.0;
				TeleportEntity(client, telePos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}
public Action:eurekaAttempt(client, const String:command[], argc) 
{
	if(IsValidClient3(client) && eurekaActive[client] == false && weaponArtCooldown[client] <= 0.0)
	{
		eurekaActive[client] = true;
		new Float:tauntDelay = 2.3;
		new Address:TauntSpeedActive = TF2Attrib_GetByName(client, "gesture speed increase");
		if(TauntSpeedActive != Address_Null)
		{
			tauntDelay /= TF2Attrib_GetValue(TauntSpeedActive);
		}
		CreateTimer(tauntDelay,eurekaDelayed,EntIndexToEntRef(client));
	}
}
public Event_Teleported(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new owner = GetClientOfUserId(GetEventInt(event, "builderid"));
	if(IsValidClient3(client) && IsValidClient3(owner))
	{
		new melee = (GetPlayerWeaponSlot(owner,2));
		if(IsValidEntity(melee))
		{
			new weaponIndex = GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex");
			if(weaponIndex == 589)
			{
				new Float:clientpos[3];
				GetClientAbsOrigin(client,clientpos);
				clientpos[0] += GetRandomFloat(-200.0,200.0);
				clientpos[1] += GetRandomFloat(-200.0,200.0);
				clientpos[2] = getLowestPosition(clientpos);
				// define where the lightning strike starts
				new Float:startpos[3];
				startpos[0] = clientpos[0];
				startpos[1] = clientpos[1];
				startpos[2] = clientpos[2] + 1600;
				
				// define the color of the strike
				new iTeam = GetClientTeam(client);
				//PrintToChat(client, "%i", iTeam);
				new color[4];
				if(iTeam == 2)
				{
					color = {255, 0, 0, 255};
				}
				else if (iTeam == 3)
				{
					color = {0, 0, 255, 255};
				}
				
				// define the direction of the sparks
				new Float:dir[3] = {0.0, 0.0, 0.0};
				
				TE_SetupBeamPoints(startpos, clientpos, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
				TE_SendToAll();
				
				TE_SetupSparks(clientpos, dir, 5000, 1000);
				TE_SendToAll();
				
				TE_SetupEnergySplash(clientpos, dir, false);
				TE_SendToAll();
				
				TE_SetupSmoke(clientpos, g_SmokeSprite, 5.0, 10);
				TE_SendToAll();
				
				TE_SetupBeamRingPoint(clientpos, 20.0, 650.0, g_LightningSprite, spriteIndex, 0, 5, 0.5, 10.0, 1.0, color, 200, 0);
				TE_SendToAll();
				
				CreateParticle(-1, "utaunt_electricity_cloud_parent_WB", false, "", 5.0, startpos);
				
				EmitAmbientSound("ambient/explosions/explode_9.wav", startpos, client, 50);
				
				new Float:LightningDamage = 325.0;
				
				new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new Address:SentryDmgActive = TF2Attrib_GetByName(CWeapon, "ring of fire while aiming");
					if(SentryDmgActive != Address_Null)
					{
						LightningDamage *= TF2Attrib_GetValue(SentryDmgActive);
					}
				}
				new Address:SentryDmgActive1 = TF2Attrib_GetByName(melee, "throwable detonation time");
				if(SentryDmgActive1 != Address_Null)
				{
					LightningDamage *= TF2Attrib_GetValue(SentryDmgActive1);
				}
				new Address:SentryDmgActive2 = TF2Attrib_GetByName(melee, "throwable fire speed");
				if(SentryDmgActive2 != Address_Null)
				{
					LightningDamage *= TF2Attrib_GetValue(SentryDmgActive2);
				}
				new Address:damageActive = TF2Attrib_GetByName(melee, "ubercharge");
				if(damageActive != Address_Null)
				{
					LightningDamage *= Pow(TF2Attrib_GetValue(damageActive), 5.0);
				}
				new Address:damageActive2 = TF2Attrib_GetByName(melee, "engy sentry damage bonus");
				if(damageActive2 != Address_Null)
				{
					LightningDamage *= TF2Attrib_GetValue(damageActive2);
				}
				new Address:fireRateActive = TF2Attrib_GetByName(melee, "engy sentry fire rate increased");
				if(fireRateActive != Address_Null)
				{
					LightningDamage /= TF2Attrib_GetValue(fireRateActive);
				}
				
				for(new i = 1; i<MAXENTITIES;i++)
				{
					if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
					{
						new Float:VictimPos[3];
						GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
						VictimPos[2] += 30.0;
						new Float:Distance = GetVectorDistance(clientpos,VictimPos);
						if(Distance <= 500.0)
						{
							if(IsPointVisible(clientpos,VictimPos))
							{
								Entity_Hurt(i, RoundToNearest(LightningDamage), client, DMG_GENERIC);
								if(IsValidClient3(i))
								{
									new Float:velocity[3];
									velocity[0]=0.0;
									velocity[1]=0.0;
									velocity[2]=1800.0;
									TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, velocity);
									new Handle:hPack = CreateDataPack();
									WritePackCell(hPack, EntIndexToEntRef(i));
									WritePackCell(hPack, EntIndexToEntRef(client));
									CreateTimer(0.5,thunderClapPart2,hPack);
								}
							}
						}
					}
				}
			}
			new Address:teleportBuffActive = TF2Attrib_GetByName(melee, "zoom speed mod disabled");
			if(teleportBuffActive != Address_Null && TF2Attrib_GetValue(teleportBuffActive) != 0.0)
			{
				TF2_AddCondition(client, TFCond_RuneAgility, 4.0);
				TF2_AddCondition(client, TFCond_KingAura, 4.0);
				TF2_AddCondition(client, TFCond_HalloweenSpeedBoost, 4.0);
			}
		}
	}
}
public Action:thunderClapPart2(Handle:timer, any:data) 
{  
	ResetPack(data);
	new victim = EntRefToEntIndex(ReadPackCell(data));
	new client = EntRefToEntIndex(ReadPackCell(data));
	if(IsValidClient3(client) && IsValidClient3(victim))
	{
		new Float:velocity[3];
		velocity[0]=0.0;
		velocity[1]=0.0;
		velocity[2]=-3000.0;
		TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velocity);
		RadiationBuildup[victim] += 100.0;
		checkRadiation(victim,client);
	}
	CloseHandle(data);
}
public Action:eurekaDelayed(Handle:timer, int client) 
{
	client = EntRefToEntIndex(client);
	eurekaActive[client] = false;
	if(IsValidClient3(client))
	{
		new melee = (GetPlayerWeaponSlot(client,2));
		if(IsValidEntity(melee))
		{
			new weaponIndex = GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex");
			if(weaponIndex == 589)
			{
				new Float:clientpos[3];
				GetClientAbsOrigin(client,clientpos);
				clientpos[0] += GetRandomFloat(-200.0,200.0);
				clientpos[1] += GetRandomFloat(-200.0,200.0);
				clientpos[2] = getLowestPosition(clientpos);
				// define where the lightning strike starts
				new Float:startpos[3];
				startpos[0] = clientpos[0];
				startpos[1] = clientpos[1];
				startpos[2] = clientpos[2] + 1600;
				
				// define the color of the strike
				new iTeam = GetClientTeam(client);
				//PrintToChat(client, "%i", iTeam);
				new color[4];
				if(iTeam == 2)
				{
					color = {255, 0, 0, 255};
				}
				else if (iTeam == 3)
				{
					color = {0, 0, 255, 255};
				}
				
				// define the direction of the sparks
				new Float:dir[3] = {0.0, 0.0, 0.0};
				
				TE_SetupBeamPoints(startpos, clientpos, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
				TE_SendToAll();
				
				TE_SetupSparks(clientpos, dir, 5000, 1000);
				TE_SendToAll();
				
				TE_SetupEnergySplash(clientpos, dir, false);
				TE_SendToAll();
				
				TE_SetupSmoke(clientpos, g_SmokeSprite, 5.0, 10);
				TE_SendToAll();
				
				TE_SetupBeamRingPoint(clientpos, 20.0, 1000.0, g_LightningSprite, spriteIndex, 0, 5, 0.5, 10.0, 1.0, color, 200, 0);
				TE_SendToAll();
				
				CreateParticle(-1, "utaunt_electricity_cloud_parent_WB", false, "", 5.0, startpos);
				
				EmitAmbientSound("ambient/explosions/explode_9.wav", startpos, client, 50);
				
				new Float:LightningDamage = 500.0;
				
				new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new Address:SentryDmgActive = TF2Attrib_GetByName(CWeapon, "ring of fire while aiming");
					if(SentryDmgActive != Address_Null)
					{
						LightningDamage *= TF2Attrib_GetValue(SentryDmgActive);
					}
				}
				new Address:SentryDmgActive1 = TF2Attrib_GetByName(melee, "throwable detonation time");
				if(SentryDmgActive1 != Address_Null)
				{
					LightningDamage *= TF2Attrib_GetValue(SentryDmgActive1);
				}
				new Address:SentryDmgActive2 = TF2Attrib_GetByName(melee, "throwable fire speed");
				if(SentryDmgActive2 != Address_Null)
				{
					LightningDamage *= TF2Attrib_GetValue(SentryDmgActive2);
				}
				new Address:damageActive = TF2Attrib_GetByName(melee, "ubercharge");
				if(damageActive != Address_Null)
				{
					LightningDamage *= Pow(TF2Attrib_GetValue(damageActive), 5.0);
				}
				new Address:damageActive2 = TF2Attrib_GetByName(melee, "engy sentry damage bonus");
				if(damageActive2 != Address_Null)
				{
					LightningDamage *= TF2Attrib_GetValue(damageActive2);
				}
				new Address:fireRateActive = TF2Attrib_GetByName(melee, "engy sentry fire rate increased");
				if(fireRateActive != Address_Null)
				{
					LightningDamage /= TF2Attrib_GetValue(fireRateActive);
				}
				
				for(new i = 1; i<MAXENTITIES;i++)
				{
					if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
					{
						new Float:VictimPos[3];
						GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
						VictimPos[2] += 30.0;
						new Float:Distance = GetVectorDistance(clientpos,VictimPos);
						if(Distance <= 1000.0)
						{
							if(IsPointVisible(clientpos,VictimPos))
							{
								Entity_Hurt(i, RoundToNearest(LightningDamage), client, DMG_GENERIC);
								if(IsValidClient3(i))
								{
									new Float:velocity[3];
									velocity[0]=0.0;
									velocity[1]=0.0;
									velocity[2]=1800.0;
									TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, velocity);
									new Handle:hPack = CreateDataPack();
									WritePackCell(hPack, EntIndexToEntRef(i));
									WritePackCell(hPack, EntIndexToEntRef(client));
									CreateTimer(0.5,thunderClapPart2,hPack);
								}
							}
						}
					}
				}
				weaponArtCooldown[client] = 0.55;
			}
			new Address:teleportBuffActive = TF2Attrib_GetByName(melee, "zoom speed mod disabled");
			if(teleportBuffActive != Address_Null && TF2Attrib_GetValue(teleportBuffActive) != 0.0)
			{
				TF2_AddCondition(client, TFCond_RuneAgility, 4.0);
				TF2_AddCondition(client, TFCond_KingAura, 4.0);
				TF2_AddCondition(client, TFCond_HalloweenSpeedBoost, 4.0);
			}
		}
	}
}
// On Map Start
public OnMapStart()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(!IsValidClient3(i)){continue;}
		if(b_Hooked[i] == false)
		{
			b_Hooked[i] = true;
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		}
		fl_HighestFireDamage[i] = 0.0;
	}
	//char g_sMaterialHalo[200] = "materials/sprites/halo01.vmt";
	//char g_sModelBox[200] = "models/props/cs_militia/silo_01.mdl";
	//g_iHaloMaterial = PrecacheModel(g_sMaterialHalo);
	//PrecacheModel(g_sModelBox, true);
	PrecacheSound(SOUND_ARROW);
	PrecacheSound(ExplosionSound1);
	PrecacheSound(ExplosionSound2);
	PrecacheSound(ExplosionSound3);
	PrecacheSound(SmallExplosionSound1);
	PrecacheSound(SmallExplosionSound2);
	PrecacheSound(SmallExplosionSound3);
	PrecacheSound(DetonatorExplosionSound);
	PrecacheSound(SOUND_ADRENALINE);
	PrecacheSound(SOUND_REVENGE);
	PrecacheSound(SOUND_SUPERNOVA);
	PrecacheSound(SOUND_DASH);
	PrecacheSound(SOUND_JAR_EXPLOSION);
	PrecacheModel("models/weapons/c_models/c_madmilk/c_madmilk.mdl");
	PrecacheModel("models/weapons/c_models/urinejar.mdl");
	PrecacheModel("models/weapons/c_models/c_breadmonster/c_breadmonster.mdl");
	PrecacheModel("models/weapons/c_models/c_breadmonster/c_breadmonster_milk.mdl");
	PrecacheModel("models/weapons/c_models/c_sd_cleaver/c_sd_cleaver.mdl");
	PrecacheModel("models/weapons/w_models/w_syringe_proj.mdl");
	PrecacheModel("materials/effects/arrowtrail_red.vmt");
	PrecacheModel("materials/effects/arrowtrail_blu.vmt");
	PrecacheModel("models/weapons/c_models/c_croc_knife/c_croc_knife.mdl");
	PrecacheModel("models/weapons/w_models/w_rocket_airstrike/w_rocket_airstrike.mdl");
	Laser = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_SmokeSprite = PrecacheModel("sprites/steam1.vmt");
	g_LightningSprite = PrecacheModel("sprites/lgtning.vmt");
	spriteIndex = PrecacheModel("materials/sprites/halo01.vmt");
}

// On Client Put In Server
public OnClientPutInServer(client)
{
	if(b_Hooked[client] == false)
	{
		b_Hooked[client] = true;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	}
	BleedMaximum[client] = 100.0;
	RadiationMaximum[client] = 400.0;
	//PlayerLevel[client] = 1.0;
	fl_HighestFireDamage[client] = 0.0;
	isBuffActive[client] = false;
	DHookEntity(Hook_OnMyWeaponFired, true, client);
}

// On Client Disconnect
public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		if(b_Hooked[client] == true)
		{
			b_Hooked[client] = false;
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		}
	}
	BleedBuildup[client] = 0.0;
	RadiationBuildup[client] = 0.0;
	RageActive[client] = false;
	RageBuildup[client] = 0.0;
	SupernovaBuildup[client] = 0.0;
	ConcussionBuildup[client] = 0.0;
	//PlayerLevel[client] = 1.0;
	fl_HighestFireDamage[client] = 0.0;
	isBuffActive[client] = false;
}
public OnGameFrame()
{
	new Float:Ticktime = GetTickInterval();
	for(new i=MaxClients; i < MAXENTITIES; i++)
	{
		if(isProjectileHoming[i] == true)
		{
			OnThinkPost(i);
		}
		if(isProjectileBoomerang[i] == true)
		{
			BoomerangThink(i);
		}
		if(projectileHomingDegree[i] > 0.0)
		{
			OnHomingThink(i);
		}
		/*if(isProjectileSlash[i][0] != 0.0)
		{
			SlashThink(i);
		}*/
	}
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient3(client) && IsPlayerAlive(client))
		{
			if(fl_GlobalCoolDown[client] > 0.0){
			fl_GlobalCoolDown[client] -= Ticktime; }
			if(weaponArtCooldown[client] > 0.0){
			weaponArtCooldown[client] -= Ticktime; }
			if(weaponArtParticle[client] > 0.0){
			weaponArtParticle[client] -= Ticktime; }
			if(powerupParticle[client] > 0.0){
			powerupParticle[client] -= Ticktime; }
			if(RadiationBuildup[client] > 0.0){
			RadiationBuildup[client] -= (RadiationMaximum[client] * 0.0285) * Ticktime; }//Fully remove radiation within 35 seconds.
			if(CurrentSlowTimer[client] > 0.0){
			CurrentSlowTimer[client] -= Ticktime; }
			if(BleedBuildup[client] > 0.0){
			BleedBuildup[client] -= (BleedMaximum[client] * 0.143) * Ticktime; }//Fully remove bleed within 7 seconds.
			if(ConcussionBuildup[client] > 0.0){
			ConcussionBuildup[client] -= 100.0 * 0.03 * Ticktime; }//Fully remove concussion within 30 seconds.
			if(miniCritStatusVictim[client] > 0.0){
			miniCritStatusVictim[client] -= Ticktime;}
			if(miniCritStatusAttacker[client] > 0.0){
			miniCritStatusAttacker[client] -= Ticktime;}
			if(RageActive[client])
			{
				if(RageBuildup[client] > 0.0)
				{
					RageBuildup[client] -= Ticktime / 10.0//Revenge lasts 10 seconds (granted they aren't gaining it at the same time)
				}
				else
				{
					RageActive[client] = false;
				}
			}

			if(CurrentSlowTimer[client] <= 0.0 && CurrentSlowTimer[client] > -1000.0)
			{
				TF2Attrib_SetByName(client,"move speed penalty", 1.0);
				TF2Attrib_SetByName(client,"major increased jump height", 1.0);
				CurrentSlowTimer[client] = -2000.0;
			}
		
			//Firerate for Secondaries
			new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			new melee = GetPlayerWeaponSlot(client,2)
			new primary = GetPlayerWeaponSlot(client,0)
			if(IsValidEntity(CWeapon))
			{
				new Address:overAllFireRate= TF2Attrib_GetByName(CWeapon, "ubercharge overheal rate penalty");
				if(overAllFireRate != Address_Null)
				{
					new Float:Amount = TF2Attrib_GetValue(overAllFireRate)
					new Float:m_flNextPrimaryAttack = GetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack");
					new Float:m_flNextSecondaryAttack = GetEntPropFloat(CWeapon, Prop_Send, "m_flNextSecondaryAttack");
					/*if (Amount > 12)
					{
						SetEntPropFloat(CWeapon, Prop_Send, "m_flPlaybackRate", 12.0);
					}
					else
					{
						SetEntPropFloat(CWeapon, Prop_Send, "m_flPlaybackRate", Amount);
					}*/
					
					new Float:GameTime = GetGameTime();
					
					new Float:PeTime = (m_flNextPrimaryAttack - GameTime) - ((Amount - 1.0) * GetTickInterval());
					new Float:SeTime = (m_flNextSecondaryAttack - GameTime) - ((Amount - 1.0) * GetTickInterval());
					new Float:FinalP = PeTime+GameTime;
					new Float:FinalS = SeTime+GameTime;
					
					
					SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", FinalP);
					SetEntPropFloat(CWeapon, Prop_Send, "m_flNextSecondaryAttack", FinalS);
				}
				
				if(IsValidEntity(melee) && CWeapon == melee && TF2_GetPlayerClass(client) == TFClass_Heavy ){
					continue;
				}
				if(IsValidEntity(primary) && CWeapon == primary && TF2_GetPlayerClass(client) == TFClass_Sniper){
					continue;
				}
				if(!(IsValidEntity(primary) && CWeapon == primary && TF2_GetPlayerClass(client) == TFClass_Heavy))
				{
					new Float:SecondaryROF = 1.0;
					new Address:Firerate1 = TF2Attrib_GetByName(CWeapon, "fire rate penalty");
					new Address:Firerate2 = TF2Attrib_GetByName(CWeapon, "fire rate bonus HIDDEN");
					new Address:Firerate3 = TF2Attrib_GetByName(CWeapon, "fire rate penalty HIDDEN");
					new Address:Firerate4 = TF2Attrib_GetByName(CWeapon, "fire rate bonus");
					if(Firerate1 != Address_Null)
					{
						new Float:Firerate1Amount = TF2Attrib_GetValue(Firerate1);
						SecondaryROF =  SecondaryROF/Firerate1Amount;
					}
					if(Firerate2 != Address_Null)
					{
						new Float:Firerate2Amount = TF2Attrib_GetValue(Firerate2);
						SecondaryROF =  SecondaryROF/Firerate2Amount;
					}
					if(Firerate3 != Address_Null)
					{
						new Float:Firerate3Amount = TF2Attrib_GetValue(Firerate3);
						SecondaryROF =  SecondaryROF/Firerate3Amount;
					}
					if(Firerate4 != Address_Null)
					{
						new Float:Firerate4Amount = TF2Attrib_GetValue(Firerate4);
						SecondaryROF =  SecondaryROF/Firerate4Amount;
					}
					SecondaryROF = Pow(SecondaryROF, 0.4);
					new Float:m_flNextSecondaryAttack = GetEntPropFloat(CWeapon, Prop_Send, "m_flNextSecondaryAttack");
					new Float:SeTime = (m_flNextSecondaryAttack - GetGameTime()) - ((SecondaryROF - 1.0) * GetTickInterval());
					new Float:FinalS = SeTime+GetGameTime();
					SetEntPropFloat(CWeapon, Prop_Send, "m_flNextSecondaryAttack", FinalS);
				}
				
				new Address:ModClip = TF2Attrib_GetByName(CWeapon, "mod max primary clip override");
				if(ModClip != Address_Null)
				{
					if(TF2Attrib_GetValue(ModClip) == -1.0)
					{
						new Float:PrimaryROF = 1.0;
						new Address:ReloadRate = TF2Attrib_GetByName(CWeapon, "faster reload rate");
						new Address:ReloadRate1 = TF2Attrib_GetByName(CWeapon, "reload time increased hidden");
						new Address:ReloadRate2 = TF2Attrib_GetByName(CWeapon, "Reload time increased");
						if(ReloadRate != Address_Null)
						{
							PrimaryROF *= TF2Attrib_GetValue(ReloadRate);
						}
						if(ReloadRate1 != Address_Null)
						{
							PrimaryROF *= TF2Attrib_GetValue(ReloadRate1);
						}
						if(ReloadRate2 != Address_Null)
						{
							PrimaryROF *= TF2Attrib_GetValue(ReloadRate2);
						}
						new Float:m_flNextPrimaryAttack = GetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack");
						new Float:Time = (m_flNextPrimaryAttack - GetGameTime()) - ((PrimaryROF - 1.0) / (1/GetTickInterval()));
						new Float:FinalROF = Time+GetGameTime();
						SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", FinalROF);
						//PrintToChat(client, "%.1f NextPrimaryAttack", FinalROF);
					}
				}
			}
		}
	}
}
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	new Float:Ticktime = GetTickInterval();
	if (IsValidClient(client))
	{
		new flags = GetEntityFlags(client)
		if(shouldAttack[client] == true){
			shouldAttack[client] = false;
			buttons |= IN_ATTACK;
		}
		
		float punch[3] = {0.01, 0.0, 0.0};
		//float punchVel[3] = {-0.05,0.0,0.0};
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", punch);	
		//SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", punchVel);
		new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(CWeapon))
		{
			decl String:strName[32];
			GetEntityClassname(CWeapon, strName, 32)
			if(StrContains(strName, "tf_weapon_minigun", false) == 0)
			{
				if(buttons & IN_ATTACK)
				{
					SetEntPropFloat(CWeapon, Prop_Send, "m_flNextSecondaryAttack", GetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack"));
				}
			}
			if(HasEntProp(CWeapon, Prop_Send, "m_flChargedDamage"))
			{
				new Float:charging = GetEntPropFloat(CWeapon, Prop_Send, "m_flChargedDamage");
				if(charging > 0.0)
				{
					new Address:charge = TF2Attrib_GetByName(CWeapon, "Repair rate increased");
					if(charge != Address_Null)
					{
						charging += TF2Attrib_GetValue(charge)*Ticktime;
					}
					new Address:precisionPowerup = TF2Attrib_GetByName(client, "refill_ammo");
					if(precisionPowerup != Address_Null)
					{
						new Float:precisionPowerupValue = TF2Attrib_GetValue(precisionPowerup);
						if(precisionPowerupValue > 0.0){
							charging += 90.0*Ticktime;
						}
					}
					
					SetEntPropFloat(CWeapon, Prop_Send, "m_flChargedDamage", charging);
					
					new Address:tracer = TF2Attrib_GetByName(CWeapon, "sniper fires tracer");
					LastCharge[client] = charging;
					//PrintToChat(client,"a %.2f",LastCharge[client]);
					if(LastCharge[client] >= 150.0 && tracer != Address_Null && TF2Attrib_GetValue(tracer) == 0.0)
					{
						TF2Attrib_SetByName(CWeapon, "sniper fires tracer", 1.0);
					}
				}
			}
			if(IsPlayerAlive(client))
			{
				if(buttons & IN_DUCK && buttons & IN_ATTACK3)
				{
					if(RageActive[client] == false && RageBuildup[client] >= 1.0)
					{
						RageActive[client] = true;
						EmitSoundToAll(SOUND_REVENGE, client, -1, 150, 0, 1.0);
						EmitSoundToAll(SOUND_REVENGE, client, -1, 150, 0, 1.0);
						
						TF2_AddCondition(client, TFCond_CritCanteen, 1.0);
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
						TF2_AddCondition(client, TFCond_DefenseBuffMmmph, 1.0);
						TF2_AddCondition(client, TFCond_PreventDeath, 1.0);
						TF2_AddCondition(client, TFCond_UberchargedHidden, 1.0);
						TF2_AddCondition(client, TFCond_KingAura, 1.0);
					}
					if(SupernovaBuildup[client] >= 1.0)
					{
						SupernovaBuildup[client] = 0.0;
						EmitSoundToAll(SOUND_SUPERNOVA, client, -1, 150, 0, 1.0);
						EmitSoundToAll(SOUND_SUPERNOVA, client, -1, 150, 0, 1.0);
						
						new iTeam = GetClientTeam(client);
						if(iTeam == 2)
						{
							CreateParticle(client, "powerup_supernova_explode_red", false, "", 1.0);
						}
						else
						{
							CreateParticle(client, "powerup_supernova_explode_blue", false, "", 1.0);
						}
						new Float:clientpos[3];
						GetClientEyePosition(client,clientpos);
						for(new i = 1; i<MAXENTITIES;i++)
						{
							if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
							{
								new Float:VictimPos[3];
								GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
								VictimPos[2] += 30.0;
								new Float:Distance = GetVectorDistance(clientpos,VictimPos);
								if(Distance <= 800.0)
								{
									if(IsValidClient3(i))
									{
										TF2_StunPlayer(i, 6.0, 1.0, TF_STUNFLAGS_NORMALBONK, client);
									}
									else if(HasEntProp(i,Prop_Send,"m_hBuilder"))
									{
										SetEntProp(i, Prop_Send, "m_bDisabled", 1);
										CreateTimer(10.0, ReEnableBuilding, EntIndexToEntRef(i));
									}
								}
							}
						}
						
					}
				}
				
				if(!(lastFlag[client] & FL_ONGROUND) && flags & FL_ONGROUND)
				{
					if(trueVel[client][2] <= -500.0)
					{
						new Float:targetvec[3],Float:clientvec[3],Float:stompDamage;
						
						stompDamage = TF2_GetDPSModifiers(client, CWeapon, false, false) * 35.0;
						stompDamage *= 1.0+(((trueVel[client][2]*-1.0) - 500.0)/1000.0)
						new Address:multiHitActive = TF2Attrib_GetByName(CWeapon, "taunt move acceleration time");
						if(multiHitActive != Address_Null)
						{
							stompDamage *= TF2Attrib_GetValue(multiHitActive) + 1.0;
						}
						
						GetClientAbsOrigin(client, clientvec);
						for(new i=1; i<=MaxClients; i++)
						{
							if(IsValidClient3(i) && IsClientInGame(i) && IsPlayerAlive(i))
							{
								GetClientEyePosition(i, targetvec);
								if(!IsClientObserver(i) && GetClientTeam(i) != GetClientTeam(client) && GetVectorDistance(clientvec, targetvec, false) < 75.0)
								{
									SDKHooks_TakeDamage(i,client,client,stompDamage,DMG_CLUB,CWeapon, NULL_VECTOR, NULL_VECTOR);
								}
							}
						}
					}
					new Address:bossType = TF2Attrib_GetByName(client, "damage force increase text");
					if(bossType != Address_Null && TF2Attrib_GetValue(bossType) > 0.0)
					{
						new Float:bossValue = TF2Attrib_GetValue(bossType);
						switch(bossValue)
						{
							case 2.0:
							{
								miniCritStatusVictim[client] = 10.0;
								TF2Attrib_SetByName(CWeapon, "fire rate penalty", 1.0)
								TF2Attrib_SetByName(CWeapon, "dmg taken increased", 2.0)
								TF2Attrib_SetByName(CWeapon, "faster reload rate", 1.0)
								TF2Attrib_SetByName(CWeapon, "Blast radius increased", 0.5)
								TF2Attrib_SetByName(CWeapon, "cannot pick up intelligence", 1.0)
								TF2Attrib_SetByName(CWeapon, "increased jump height", 2.5)
								SetEntProp(CWeapon, Prop_Data, "m_bReloadsSingly", 1);
							}
						}
						//PrintToChatAll("ground")
					}
					SetEntityGravity(client, 1.0);
				}
				else if((lastFlag[client] & FL_ONGROUND) && !(flags & FL_ONGROUND))
				{
					new Address:bossType = TF2Attrib_GetByName(client, "damage force increase text");
					if(bossType != Address_Null && TF2Attrib_GetValue(bossType) > 0.0)
					{
						new Float:bossValue = TF2Attrib_GetValue(bossType);
						switch(bossValue)
						{
							case 2.0:
							{
								miniCritStatusVictim[client] = 0.0;
								TF2Attrib_SetByName(CWeapon, "fire rate penalty", 0.2)
								TF2Attrib_SetByName(CWeapon, "dmg taken increased", 0.1)
								TF2Attrib_SetByName(CWeapon, "faster reload rate", 0.0)
								TF2Attrib_SetByName(CWeapon, "Blast radius increased", 1.75)
								SetEntityGravity(client, 0.5);
								SetEntProp(CWeapon, Prop_Data, "m_bReloadsSingly", 0);
								CreateParticle(client, "ExplosionCore_MidAir", false, "", 0.1);
							}
						}
						//PrintToChatAll("air")
					}
				}
				else if(!(flags & FL_ONGROUND))
				{
					if(buttons & IN_DUCK)
					{
						new Address:weighDownAbility = TF2Attrib_GetByName(client, "noise maker");
						if(weighDownAbility != Address_Null && TF2Attrib_GetValue(weighDownAbility) > 0.0)
						{
							SetEntityGravity(client, TF2Attrib_GetValue(weighDownAbility) + 1.0);
						}
					}
					else
					{
						SetEntityGravity(client, 1.0);
					}
				}
				
				if(powerupParticle[client] <= 0.0 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
				{
					
					new Address:strengthPowerup = TF2Attrib_GetByName(client, "crit kill will gib");
					if(strengthPowerup != Address_Null && TF2Attrib_GetValue(strengthPowerup) > 0.0)
					{
						CreateParticle(client, "utaunt_tarotcard_orange_wind", true, "", 5.0);
						powerupParticle[client] = 5.0;
					}
					new Address:resistancePowerup = TF2Attrib_GetByName(client, "expiration date");
					if(resistancePowerup != Address_Null && TF2Attrib_GetValue(resistancePowerup) > 0.0)
					{
						CreateParticle(client, "soldierbuff_red_spikes", true, "", 2.0);
						powerupParticle[client] = 2.0;
					}
					new Address:vampirePowerup = TF2Attrib_GetByName(client, "unlimited quantity");
					if(vampirePowerup != Address_Null && TF2Attrib_GetValue(vampirePowerup) > 0.0)
					{
						CreateParticle(client, "spell_batball_red", true, "", 2.0);
						powerupParticle[client] = 8.0;
					}
					new Address:regenerationPowerup = TF2Attrib_GetByName(client, "recall");
					if(regenerationPowerup != Address_Null && TF2Attrib_GetValue(regenerationPowerup) > 0.0)
					{
						new iTeam = GetClientTeam(client);
						if(iTeam == 2)
						{
							CreateParticle(client, "medic_megaheal_red_shower", true, "", 5.0);
						}
						else
						{
							CreateParticle(client, "medic_megaheal_blue_shower", true, "", 5.0);
						}
						powerupParticle[client] = 5.0;
					}
					new Address:precisionPowerup = TF2Attrib_GetByName(client, "refill_ammo");
					if(precisionPowerup != Address_Null && TF2Attrib_GetValue(precisionPowerup) > 0.0)
					{
						if(TF2_GetPlayerClass(client) != TFClass_Pyro && TF2_GetPlayerClass(client) != TFClass_Engineer)
						{
							CreateParticle(client, "eye_powerup_blue_lvl_4", true, "righteye", 5.0);
						}
						else
						{
							CreateParticle(client, "eye_powerup_blue_lvl_4", true, "eyeglow_R", 5.0);
						}
						powerupParticle[client] = 5.0;
					}
					new Address:agilityPowerup = TF2Attrib_GetByName(client, "store sort override DEPRECATED");
					if(agilityPowerup != Address_Null && TF2Attrib_GetValue(agilityPowerup) > 0.0)
					{
						CreateParticle(client, "medic_resist_bullet", true, "", 5.0);
						powerupParticle[client] = 5.0;
					}
					new Address:knockoutPowerup = TF2Attrib_GetByName(client, "taunt is press and hold");
					if(knockoutPowerup != Address_Null && TF2Attrib_GetValue(knockoutPowerup) > 0.0)
					{
						CreateParticle(client, "medic_resist_blast", true, "", 5.0);
						powerupParticle[client] = 5.0;
					}
					new Address:kingPowerup = TF2Attrib_GetByName(client, "attack projectiles");
					if(kingPowerup != Address_Null && TF2Attrib_GetValue(kingPowerup) > 0.0)
					{
						new clientTeam = GetClientTeam(client);
						new Float:clientPos[3];
						GetEntPropVector(client, Prop_Data, "m_vecOrigin", clientPos);
						for(new i = 1;i<MaxClients;i++)
						{
							if(IsValidClient3(i) && IsPlayerAlive(i))
							{
								new iTeam = GetClientTeam(i);
								if(clientTeam == iTeam)
								{
									new Float:VictimPos[3];
									GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
									VictimPos[2] += 30.0;
									new Float:Distance = GetVectorDistance(clientPos,VictimPos);
									if(Distance <= 600.0)
									{
										if(iTeam == 2)
										{
											CreateParticle(i, "powerup_king_red", true, "", 2.0);
										}
										else
										{
											CreateParticle(i, "powerup_king_blue", true, "", 2.0);
										}
										TF2_AddCondition(i, TFCond_KingAura, 3.0)
									}
								}
							}
						}
						powerupParticle[client] = 2.0;
					}
					new Address:plaguePowerup = TF2Attrib_GetByName(client, "disable fancy class select anim");
					if(plaguePowerup != Address_Null && TF2Attrib_GetValue(plaguePowerup) > 0.0)
					{
						CreateParticle(client, "powerup_plague_carrier", true, "", 5.0);
						powerupParticle[client] = 5.0;
					}
					new Address:supernovaPowerup = TF2Attrib_GetByName(client, "spawn with physics toy");
					if(supernovaPowerup != Address_Null && TF2Attrib_GetValue(supernovaPowerup) > 0.0)
					{
						CreateParticle(client, "powerup_supernova_ready", true, "", 5.0);
						powerupParticle[client] = 5.0;
					}
				}
				
				GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", trueVel[client]);
				new Address:Skill = TF2Attrib_GetByName(CWeapon, "apply look velocity on damage");
				if(Skill != Address_Null)
				{
					new Float:SkillNumber = TF2Attrib_GetValue(Skill);
					new Float:x = 0.8;
					new Float:y = 0.9;
					new red = 0;
					new blue = 101;
					new green = 189;
					
					new Readyred = 0;
					new Readyblue = 219;
					new Readygreen = 15;
					
					new alpha = 255;
					switch(SkillNumber)
					{
						case 1.0: //Teleport
						{
							if(weaponArtCooldown[client] > 0.0)
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Adrenaline: %.1fs", weaponArtCooldown[client]); 
								SetHudTextParams(x, y, Ticktime*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Adrenaline: READY (MOUSE3)"); 
								SetHudTextParams(x, y, Ticktime*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
								if(buttons & IN_ATTACK3)
								{
									if(fl_GlobalCoolDown[client] <= 0.0)
									{
										fl_GlobalCoolDown[client] = 0.3;
										weaponArtCooldown[client] = 15.0;
										BleedBuildup[client] = 0.0;
										RadiationBuildup[client] = 0.0;
										miniCritStatusAttacker[client] = 5.0
										TF2_AddCondition(client, TFCond_RestrictToMelee, 5.0);
										TF2_AddCondition(client, TFCond_DodgeChance, 2.5);
										TF2_AddCondition(client, TFCond_AfterburnImmune, 2.5);
										TF2_AddCondition(client, TFCond_UberchargedHidden, 0.01);
										EmitSoundToAll(SOUND_ADRENALINE, client, -1, 150, 0, 1.0);
										CreateParticle(client, "utaunt_tarotcard_red_wind", true, "", 5.0);
									}
								}
							}
						}
						case 2.0: //Explosive Shot
						{
							if(weaponArtCooldown[client] > 0.0)
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Explosive Shot: %.1fs", weaponArtCooldown[client]); 
								SetHudTextParams(x, y, Ticktime*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Explosive Shot: READY (MOUSE3)"); 
								SetHudTextParams(x, y, Ticktime*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
								if(buttons & IN_ATTACK3)
								{
									if(fl_GlobalCoolDown[client] <= 0.0)
									{
										weaponArtCooldown[client] = 7.0;
										fl_GlobalCoolDown[client] = 0.8;
										fl_ArrowStormDuration[client] = 1.0;
										PrintToChat(client, "Your next shot will explode!");
									}
								}
							}
						}
						case 3.0: //Stun Shot
						{
							if(weaponArtCooldown[client] > 0.0)
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Stun Shot: %.1fs", weaponArtCooldown[client]); 
								SetHudTextParams(x, y, Ticktime*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Stun Shot: READY (MOUSE3)"); 
								SetHudTextParams(x, y, Ticktime*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
								if(buttons & IN_ATTACK3)
								{
									if(fl_GlobalCoolDown[client] <= 0.0)
									{
										weaponArtCooldown[client] = 7.0;
										fl_GlobalCoolDown[client] = 0.8;
										TF2Attrib_SetByName(client, "bullets per shot bonus", 5.0);
										refreshAllWeapons(client);
										SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
										buttons |= IN_ATTACK;
										StunShotBPS[client] = true;
										StunShotStun[client] = true;
										RequestFrame(StunShotFunc, client);
									}
								}
							}
						}
						case 4.0: //Juggernaut
						{
							if(weaponArtCooldown[client] > 0.0)
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Juggernaut: %.1fs", weaponArtCooldown[client]); 
								SetHudTextParams(x, y, Ticktime*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Juggernaut: READY (MOUSE3)"); 
								SetHudTextParams(x, y, Ticktime*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
								if(buttons & IN_ATTACK3)
								{
									if(fl_GlobalCoolDown[client] <= 0.0)
									{
										weaponArtCooldown[client] = 30.0;
										fl_GlobalCoolDown[client] = 0.8;
										TF2_AddCondition(client, TFCond_MegaHeal, 5.0);
									}
								}
							}
						}
						case 5.0: //Dragon's Breath
						{
							if(weaponArtCooldown[client] > 0.0)
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Dragon's Breath: %.1fs", weaponArtCooldown[client]); 
								SetHudTextParams(x, y, Ticktime*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Dragon's Breath: READY (MOUSE3)"); 
								SetHudTextParams(x, y, Ticktime*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
								if(buttons & IN_ATTACK3)
								{
									if(fl_GlobalCoolDown[client] <= 0.0)
									{
										weaponArtCooldown[client] = 15.0;
										fl_GlobalCoolDown[client] = 0.8;
										
										for(new i = 0;i<5;i++)
										{
											new iEntity = CreateEntityByName("tf_projectile_spellfireball");
											if (IsValidEdict(iEntity)) 
											{
												new iTeam = GetClientTeam(client);
												new Float:fAngles[3]
												new Float:fOrigin[3]
												new Float:vBuffer[3]
												new Float:fVelocity[3]
												new Float:fwd[3]
												SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
												SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
												GetClientEyeAngles(client, fAngles);
												GetClientEyePosition(client, fOrigin);
												
												fAngles[1] -= 20.0*(5/2);
												fAngles[1] += i*20.0;

												GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
												ScaleVector(fwd, 30.0);
												
												AddVectors(fOrigin, fwd, fOrigin);
												GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
												
												new Float:velocity = 300.0;
												new Float:vecAngImpulse[3];
												GetCleaverAngularImpulse(vecAngImpulse);
												fVelocity[0] = vBuffer[0]*velocity;
												fVelocity[1] = vBuffer[1]*velocity;
												fVelocity[2] = vBuffer[2]*velocity;
												
												TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
												DispatchSpawn(iEntity);
												setProjGravity(iEntity, 9.0);
												SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchDragonsBreath);
												CreateTimer(10.0,SelfDestruct,EntIndexToEntRef(iEntity));
											}
										}
									}
								}
							}
						}
						case 6.0: //Detonate
						{
							if(weaponArtCooldown[client] > 0.0)
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Detonate Flares: %.1fs", weaponArtCooldown[client]); 
								SetHudTextParams(x, y, Ticktime*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Detonate Flares: READY (MOUSE3)"); 
								SetHudTextParams(x, y, Ticktime*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
								if(buttons & IN_ATTACK3)
								{
									if(fl_GlobalCoolDown[client] <= 0.0)
									{
										weaponArtCooldown[client] = 0.2;
										fl_GlobalCoolDown[client] = 0.2;
										
										new Float:damageMult = TF2_GetDamageModifiers(client,CWeapon)
										new Float:m_fOrigin[3];
										new entity = -1; 
										while((entity = FindEntityByClassname(entity, "tf_projectile_flare"))!=INVALID_ENT_REFERENCE)
										{
											new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
											if(!IsValidClient(owner)) continue;
											if(owner == client)
											{
												GetEntPropVector(entity, Prop_Data, "m_vecOrigin", m_fOrigin);
												EntityExplosion(client, 22.0*damageMult, 300.0, m_fOrigin, 2, _, entity);
												RemoveEntity(entity);
											}
										}
									}
								}
							}
						}
						case 7.0: //Weak Dash
						{
							if(weaponArtCooldown[client] > 0.0)
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Dash: %.1fs", weaponArtCooldown[client]); 
								SetHudTextParams(x, y, Ticktime*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Dash: READY (MOUSE2)"); 
								SetHudTextParams(x, y, Ticktime*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
								if(buttons & IN_ATTACK2)
								{
									if(fl_GlobalCoolDown[client] <= 0.0)
									{
										weaponArtCooldown[client] = 1.0;
										fl_GlobalCoolDown[client] = 0.2;
										
										new Float:flSpeed = GetEntPropFloat(client, Prop_Data, "m_flMaxspeed") * 2.0
										new Float:flVel[3],Float:flAng[3], Float:vBuffer[3]
										GetClientEyeAngles(client,flAng)
										GetAngleVectors(flAng, vBuffer, NULL_VECTOR, NULL_VECTOR)
										flVel[0] = flSpeed * vBuffer[0] * 1.5;
										flVel[1] = flSpeed * vBuffer[1] * 1.5;
										flVel[2] = 100.0 + (flSpeed * (vBuffer[2] * 0.75));
										TeleportEntity(client, NULL_VECTOR,NULL_VECTOR, flVel)
										EmitSoundToAll(SOUND_DASH, client, -1, 80, 0, 1.0);
									}
								}
							}
						}
						case 8.0: //Transient Moonlight
						{
							if(weaponArtParticle[client] <= 0.0)
							{
								weaponArtParticle[client] = 3.0;
								CreateParticle(CWeapon, "utaunt_auroraglow_purple_parent", true, "", 5.0,_,_,1);
								bool particleEnabler = false;
								if(AreClientCookiesCached(client))
								{
									new String:particleEnabled[64];
									GetClientCookie(client, particleToggle, particleEnabled, sizeof(particleEnabled));
									new Float:menuValue = StringToFloat(particleEnabled);
									if(menuValue == 1.0)
									{
										particleEnabler = true;
									}
								}
								int[] clients = new int[MaxClients];
								int numClients;
								for(new i=1;i<MaxClients;i++)
								{
									if(IsValidClient3(i) && (i != client || particleEnabler == true))
									{
										clients[numClients++] = i;
									}
								}
								TE_Send(clients,numClients)
							}
							if(weaponArtCooldown[client] > 0.0)
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Transient Moonlight: %.1fs", weaponArtCooldown[client]); 
								SetHudTextParams(x, y, Ticktime*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Transient Moonlight: R (MOUSE2)"); 
								SetHudTextParams(x, y, Ticktime*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
								if(buttons & IN_ATTACK2)
								{
									if(fl_GlobalCoolDown[client] <= 0.0)
									{
										weaponArtCooldown[client] = 6.0;
										fl_GlobalCoolDown[client] = 0.2;
										
										decl Float:fAngles[3], Float:fVelocity[3], Float:fOrigin[3], Float:vBuffer[3];
										new String:projName[32] = "tf_projectile_arrow";
										new iEntity = CreateEntityByName(projName);
										if (IsValidEdict(iEntity)) 
										{
											new iTeam = GetClientTeam(client);
											new Float:fwd[3]
											SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

											//SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
											//SetEntityRenderColor(iEntity, 0, 0, 0, 0);
								
											SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
											SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
											GetClientEyePosition(client, fOrigin);
											GetClientEyeAngles(client, fAngles);
											GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
											GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
											ScaleVector(fwd, 50.0);
											AddVectors(fOrigin, fwd, fOrigin);
											new Float:velocity = 5000.0;
											fVelocity[0] = vBuffer[0]*velocity;
											fVelocity[1] = vBuffer[1]*velocity;
											fVelocity[2] = vBuffer[2]*velocity;
											
											TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
											DispatchSpawn(iEntity);
											//SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vecAngImpulse, client, 0, 5.0);
											SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
											if(HasEntProp(iEntity, Prop_Send, "m_hLauncher"))
											{
												SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
											}
											SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
											SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008);
											SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
											SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 13);
											SDKHook(iEntity, SDKHook_Touch, OnCollisionMoonveil);
											
											float vecBossMin[3], vecBossMax[3];
											GetEntPropVector(iEntity, Prop_Send, "m_vecMins", vecBossMin);
											GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecBossMax);
											
											float vecScaledBossMin[3], vecScaledBossMax[3];
											
											vecScaledBossMin = vecBossMin;
											vecScaledBossMax = vecBossMax;
											
											//PrintToChat(client, "%.2f | %.2f",vecScaledBossMin[0],vecScaledBossMax[0])
											//PrintToChat(client, "%.2f | %.2f",vecScaledBossMin[1],vecScaledBossMax[1])
											//PrintToChat(client, "%.2f | %.2f",vecScaledBossMin[2],vecScaledBossMax[2])

											vecScaledBossMin[0] -= 10.0;
											vecScaledBossMax[0] += 10.0;
											vecScaledBossMin[1] -= 10.0;
											vecScaledBossMax[1] += 10.0;
											vecScaledBossMin[2] -= 20.0;
											vecScaledBossMax[2] += 20.0;
											
											
											SetEntPropVector(iEntity, Prop_Send, "m_vecMins", vecScaledBossMin);
											SetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecScaledBossMax);
											
											float particleOffset[3];
											CreateParticle(iEntity, "utaunt_auroraglow_purple_parent", true, "", 5.0);
											particleOffset[2] -= 20.0;
											CreateParticle(iEntity, "utaunt_auroraglow_purple_parent", true, "", 5.0, particleOffset);
											particleOffset[2] += 40.0;
											CreateParticle(iEntity, "utaunt_auroraglow_purple_parent", true, "", 5.0, particleOffset);
										}
									}
								}
							}
						}
						case 9.0: //Corpse Piler
						{
							if(weaponArtParticle[client] <= 0.0)
							{
								weaponArtParticle[client] = 3.0;
								CreateParticle(CWeapon, "critgun_weaponmodel_red", true, "", 5.0,_,_,1);
								TE_SendToAll();
								SetEntityRenderColor(CWeapon, 255,0,0,200);
							}
							if(weaponArtCooldown[client] > 0.0)
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Corpse Piler: %.1fs", weaponArtCooldown[client]); 
								SetHudTextParams(x, y, Ticktime*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Corpse Piler: READY (MOUSE2)"); 
								SetHudTextParams(x, y, Ticktime*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
								if(buttons & IN_ATTACK2)
								{
									if(fl_GlobalCoolDown[client] <= 0.0)
									{
										weaponArtCooldown[client] = 30.0;
										fl_GlobalCoolDown[client] = 0.2;
										
										buttons |= IN_ATTACK;
										SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
										RequestFrame(disableWeapon,client);
										
										for(new i=0;i<20;i++)
										{
											new Handle:hPack = CreateDataPack();
											WritePackCell(hPack, EntIndexToEntRef(CWeapon));
											WritePackCell(hPack, EntIndexToEntRef(client));
											CreateTimer(0.06*i, CreateBloodTracer, hPack);
										}
									}
								}
							}
						}
						case 10.0: //Homing Flares
						{
							if(weaponArtParticle[client] <= 0.0)
							{
								weaponArtParticle[client] = 3.0;
								CreateParticle(CWeapon, "critgun_weaponmodel_red", true, "", 5.0,_,_,1);
								TE_SendToAll();
								
								SetEntityRenderColor(CWeapon, 255, 162, 0,200);
								TF2Attrib_SetByName(CWeapon,"SPELL: Halloween green flames", 1.0);
								TF2Attrib_SetByName(client,"SPELL: Halloween green flames", 1.0);
								TF2Attrib_ClearCache(client);
								TF2Attrib_ClearCache(CWeapon);
							}
							if(weaponArtCooldown[client] > 0.0)
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Homing Flares: %.1fs", weaponArtCooldown[client]); 
								SetHudTextParams(x, y, Ticktime*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Homing Flares: READY (MOUSE2)"); 
								SetHudTextParams(x, y, Ticktime*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
								if(buttons & IN_ATTACK2)
								{
									if(fl_GlobalCoolDown[client] <= 0.0)
									{
										weaponArtCooldown[client] = 3.0;
										fl_GlobalCoolDown[client] = 0.2;
										new iTeam = GetClientTeam(client);
										for(new i=0;i<3;i++)
										{
											new iEntity = CreateEntityByName("tf_projectile_flare");
											if (IsValidEdict(iEntity)) 
											{
												new Float:fAngles[3]
												new Float:fOrigin[3]
												new Float:vBuffer[3]
												new Float:vRight[3]
												new Float:fVelocity[3]
												new Float:fwd[3]
												SetEntityRenderColor(iEntity, 255, 255, 255, 0);
												SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

												SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
												SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
												SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
												SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
												SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008 + 0x0004);
												SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
												SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 2);
															
												GetClientEyePosition(client, fOrigin);
												GetClientEyeAngles(client,fAngles);
												
												GetAngleVectors(fAngles, vBuffer, vRight, NULL_VECTOR);
												GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
												ScaleVector(fwd, 60.0);
												ScaleVector(vRight, 30.0*(i-1))
												AddVectors(fOrigin, vRight, fOrigin);
												AddVectors(fOrigin, fwd, fOrigin);
												
												new Float:Speed = 1200.0;
												fVelocity[0] = vBuffer[0]*Speed;
												fVelocity[1] = vBuffer[1]*Speed;
												fVelocity[2] = vBuffer[2]*Speed;
												SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
												TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
												DispatchSpawn(iEntity);
												SetEntityGravity(iEntity,0.01);
												
												SDKHook(iEntity, SDKHook_Touch, OnCollisionPhotoViscerator);
												CreateTimer(0.01, HomingFlareThink, EntIndexToEntRef(iEntity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
												CreateParticle(iEntity, "utaunt_auroraglow_green_parent", true, "", 5.0);
												CreateTimer(5.0, SelfDestruct, EntIndexToEntRef(iEntity));
											}
										}
									}
								}
							}
						}
						case 11.0:
						{
							if(weaponArtParticle[client] <= 0.0)
							{
								weaponArtParticle[client] = 4.0;
								SetEntityRenderColor(CWeapon, 255, 255, 255, 1);
							}
						}
						case 12.0: //Strong Dash
						{
							if(weaponArtParticle[client] <= 0.0)
							{
								weaponArtParticle[client] = 7.0;
								SetEntityRenderColor(CWeapon, 0, 0, 0,130);
							}
							if(weaponArtCooldown[client] > 0.0)
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Silent Dash: %.1fs", weaponArtCooldown[client]); 
								SetHudTextParams(x, y, Ticktime*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Silent Dash: READY (MOUSE3)"); 
								SetHudTextParams(x, y, Ticktime*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
								if(buttons & IN_ATTACK3)
								{
									if(fl_GlobalCoolDown[client] <= 0.0)
									{
										weaponArtCooldown[client] = 1.0;
										fl_GlobalCoolDown[client] = 0.2;
										
										new Float:flSpeed = GetEntPropFloat(client, Prop_Data, "m_flMaxspeed") * 2.0
										new Float:flVel[3],Float:flAng[3], Float:vBuffer[3]
										GetClientEyeAngles(client,flAng)
										GetAngleVectors(flAng, vBuffer, NULL_VECTOR, NULL_VECTOR)
										flVel[0] = flSpeed * vBuffer[0] * 1.5;
										flVel[1] = flSpeed * vBuffer[1] * 1.5;
										flVel[2] = 100.0 + (flSpeed * vBuffer[2]);
										
										if(flVel[2] < -100.0)
											flVel[2] *= 2.5;
										TeleportEntity(client, NULL_VECTOR,NULL_VECTOR, flVel)
									}
								}
							}
						}
						case 13.0:
						{
							if(weaponArtParticle[client] <= 0.0)
							{
								weaponArtParticle[client] = 3.0;
								CreateParticle(CWeapon, "critgun_weaponmodel_red", true, "", 6.0,_,_,1);
								TE_SendToAll();
							}
						}
					}
				}
			}
		}
		fEyeAngles[client] = angles;
		AirblastPatch(client);
		lastFlag[client] = flags
	}
	return Plugin_Changed;
}
public Action:CreateBloodTracer(Handle:timer,any:data)
{
	ResetPack(data);
	new weapon = EntRefToEntIndex(ReadPackCell(data));
	new client = EntRefToEntIndex(ReadPackCell(data));
	if(IsValidEntity(client) && IsValidEntity(weapon))
	{
		decl Float:fAngles[3], Float:fOrigin[3], Float:vBuffer[3], Float:fOriginEnd[3], Float:fwd[3], Float:opposite[3], Float:PlayerOrigin[3];
		GetClientEyePosition(client, fOrigin);
		GetClientEyePosition(client, PlayerOrigin);
		GetClientEyeAngles(client, fAngles);
		GetAngleVectors(fAngles, fwd, NULL_VECTOR, vBuffer);
		ScaleVector(fwd, 600.0);
		AddVectors(fOrigin, fwd, fOrigin);
		fOriginEnd = fOrigin;
		ScaleVector(vBuffer, 200.0);
		AddVectors(fOriginEnd, vBuffer, fOriginEnd)
		ScaleVector(vBuffer, -1.0);
		AddVectors(fOrigin, vBuffer, fOrigin)
		
		opposite[0] = GetRandomFloat( -300.0, 300.0 );
		opposite[1] = GetRandomFloat( -300.0, 300.0 );
		opposite[2] = GetRandomFloat( -100.0, 100.0 );
		
		new Float:mult = 1.0
		new Address:multiHitActive = TF2Attrib_GetByName(weapon, "taunt move acceleration time");
		if(multiHitActive != Address_Null)
		{
			mult *= TF2Attrib_GetValue(multiHitActive) + 1.0;
		}
		mult *= TF2_GetDPSModifiers(client, weapon, false, false) * 10.0;
		for(new i = 1; i<MAXENTITIES;i++)
		{
			if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
			{
				new Float:VictimPos[3];
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
				VictimPos[2] += 30.0;
				new Float:Distance = GetVectorDistance(fOrigin,VictimPos);
				new Float:Range = 500.0;
				if(Distance <= Range)
				{
					if(IsPointVisible(PlayerOrigin,VictimPos))
					{
						CreateParticle(i, "env_sawblood", true, "", 2.0);
						Entity_Hurt(i, RoundToNearest(mult), client, DMG_BLAST);
					}
				}
			}
		}
		
		fOrigin[0] += opposite[0]
		fOrigin[1] += opposite[1]
		fOrigin[2] += opposite[2]
		
		fOriginEnd[0] -= opposite[0]
		fOriginEnd[1] -= opposite[1]
		fOriginEnd[2] -= opposite[2]

		new color[4];
		color = {255, 0, 0, 255}
		TE_SetupBeamPoints(fOrigin,fOriginEnd,Laser,Laser,0,5,2.5,4.0,8.0,3,1.0,color,10);
		TE_SendToAll();
		
		shouldAttack[client] = true;
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
		RequestFrame(disableWeapon,client);
	}
	CloseHandle(data);
}
disableWeapon(client)
{
	new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1.0);
}
StunShotFunc(client)
{
	new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.6);
	CreateTimer(0.5, removeBulletsPerShot, client);
}
AirblastPatch(client)
{
	if( !IsPlayerAlive(client) )
		return;
	
	if( TF2_GetPlayerClass(client) != TFClass_Pyro )
		return;

	new iNextTickTime = RoundToNearest(GetGameTime()/GetTickInterval())+ 5;
	SetEntProp( client, Prop_Data, "m_nNextThinkTick", iNextTickTime );
	
	if( GetEntProp( client, Prop_Data, "m_nWaterLevel" ) > 1 )
		return;
	
	if( (GetClientButtons(client) & IN_ATTACK2) != IN_ATTACK2 )
		return;

	new iWeapon = GetEntPropEnt( client, Prop_Send, "m_hActiveWeapon" );
	if( !IsValidEntity(iWeapon) )
		return;
	
	decl String:strClassname[64];
	GetEntityClassname( iWeapon, strClassname, sizeof(strClassname) );
	if( !StrEqual( strClassname, "tf_weapon_flamethrower", false ) &&  !StrEqual( strClassname, "tf_weapon_rocketlauncher_fireball", false ) )
		return;

	if( ( GetEntPropFloat( iWeapon, Prop_Send, "m_flNextSecondaryAttack" ) - flNextSecondaryAttack[client] ) <= 0.0 )
		return;
		
	flNextSecondaryAttack[client] = GetEntPropFloat( iWeapon, Prop_Send, "m_flNextSecondaryAttack" );
	
	new Float:SlowForce = 2.0;
	new Float:DamageDealt = 80.0;
	new Float:TotalRange = 600.0;
	new Float:Duration = 1.25;
	new Float:ConeRadius = 40.0;
	new Address:SlowActive = TF2Attrib_GetByName(iWeapon, "airblast vertical pushback scale");
	new Address:DamageActive = TF2Attrib_GetByName(iWeapon, "airblast pushback scale");
	new Address:RangeActive = TF2Attrib_GetByName(iWeapon, "deflection size multiplier");
	new Address:DurationActive = TF2Attrib_GetByName(iWeapon, "melee range multiplier");
	new Address:RadiusActive = TF2Attrib_GetByName(iWeapon, "melee bounds multiplier");

	if(SlowActive != Address_Null){
		SlowForce *= TF2Attrib_GetValue(SlowActive)
	}
	if(DamageActive != Address_Null){
		DamageDealt *= TF2Attrib_GetValue(DamageActive)
	}
	if(RangeActive != Address_Null){
		TotalRange *= TF2Attrib_GetValue(RangeActive)
	}
	if(DurationActive != Address_Null){
		Duration *= TF2Attrib_GetValue(DurationActive)
	}
	if(RadiusActive != Address_Null){
		ConeRadius *= TF2Attrib_GetValue(RadiusActive)
	}	
	DamageDealt *= TF2_GetDamageModifiers(client, iWeapon);
	
	new Address:lameMult = TF2Attrib_GetByName(iWeapon, "dmg penalty vs players");
	if(lameMult != Address_Null)//lame. AP applies twice.
	{
		DamageDealt /= TF2Attrib_GetValue(lameMult);
	}
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient3(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(IsTargetInSightRange(client, i, ConeRadius, TotalRange, true, false))
			{
				if(IsAbleToSee(client,i, false) == true)
				{
					if(GetClientTeam(i) != GetClientTeam(client))//Enemies debuffed
					{
						CurrentSlowTimer[i] = Duration;
						SDKHooks_TakeDamage(i,client,client,DamageDealt,DMG_BLAST,iWeapon, NULL_VECTOR, NULL_VECTOR);
						
						new bool:immune = false;
						
						new Address:agilityPowerup = TF2Attrib_GetByName(client, "store sort override DEPRECATED");		
						if(agilityPowerup != Address_Null && TF2Attrib_GetValue(agilityPowerup) > 0.0)
						{
							immune = true;
						}
						if(TF2_IsPlayerInCondition(i,TFCond_MegaHeal))
						{
							immune = true;
						}
						if(!immune)
						{
							TF2Attrib_SetByName(i,"move speed penalty", 1/SlowForce);
							TF2Attrib_SetByName(i,"major increased jump height", Pow(1.2/SlowForce,0.3));
						}
						//PrintToChat(client, "%N was airblasted. Took %.2f base damage and was slowed for %.2f seconds.", i, DamageDealt, Duration);
					}
					else//Teammates buffed.
					{
						TF2_AddCondition(i, TFCond_AfterburnImmune, 6.0);
						TF2_AddCondition(i, TFCond_SpeedBuffAlly, 6.0);
						TF2_AddCondition(i, TFCond_DodgeChance, 0.2);
					}
				}
			}
		}
	}
	
}
/*
public Event_BuildingHealed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new building = GetClientOfUserId(GetEventInt(event, "building"));
	new healer = GetClientOfUserId(GetEventInt(event, "healer"));
	new amount = GetEventInt(event, "amount");
	
	if(amount > 0)
	{
		
	}
}
*/
checkRadiation(victim,attacker)
{
	if(RadiationBuildup[victim] >= RadiationMaximum[victim])
	{
		RadiationBuildup[victim] = 0.0;
		if(!IsFakeClient(victim))
		{
			new Float:victimMaxArmor = 300.0;
			new Address:armorActive = TF2Attrib_GetByName(victim, "obsolete ammo penalty")
			if(armorActive != Address_Null)
			{
				new Float:armorAmount = TF2Attrib_GetValue(armorActive);
				victimMaxArmor += armorAmount;
			}
			new armorLost = RoundToNearest(victimMaxArmor/2.0);
			DealFakeDamage(victim,attacker,-1, armorLost);
			TF2_AddCondition(victim, TFCond_NoTaunting_DEPRECATED, 5.0);
			
			new Float:particleOffset[3] = {0.0,0.0,10.0};
			CreateParticle(victim, "utaunt_electricity_cloud_electricity_WY", true, "", 5.0, particleOffset);
			CreateParticle(victim, "utaunt_auroraglow_green_parent", true, "", 5.0);
			CreateParticle(victim, "merasmus_blood", true, "", 2.0);
		}
		else
		{
			miniCritStatusVictim[victim] = 7.5;
			TF2_AddCondition(victim, TFCond_Bleeding, 7.5);
			TF2_AddCondition(victim, TFCond_AirCurrent, 7.5);
			TF2_AddCondition(victim, TFCond_NoTaunting_DEPRECATED, 7.5);
			new Float:particleOffset[3] = {0.0,0.0,10.0};
			CreateParticle(victim, "utaunt_electricity_cloud_electricity_WY", true, "", 7.5, particleOffset);
			CreateParticle(victim, "utaunt_auroraglow_green_parent", true, "", 7.5);
			CreateParticle(victim, "merasmus_blood", true, "", 7.5);
		}
	}
}
public Action:OnCollisionPhotoViscerator(entity, client)
{
	decl String:strName[128];
	GetEntityClassname(client, strName, 128)
	decl String:strName1[128];
	GetEntityClassname(entity, strName1, 128)
	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			if(IsOnDifferentTeams(owner,client))
			{
				new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new Float:damage = TF2_GetDPSModifiers(owner,CWeapon)*10.0;
					new Address:lameMult = TF2Attrib_GetByName(CWeapon, "dmg penalty vs players");
					if(lameMult != Address_Null)//lame. AP applies twice.
					{
						damage /= TF2Attrib_GetValue(lameMult);
					}
					DOTStock(client,owner,1.0,CWeapon,DMG_BURN + DMG_PREVENT_PHYSICS_FORCE,20,0.5,0.2,true);
					SDKHooks_TakeDamage(client,owner,owner,damage,DMG_BURN,CWeapon, NULL_VECTOR, NULL_VECTOR);
				}
				RemoveEntity(entity);
				new Float:pos[3]
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", pos);
				EmitSoundToAll("weapons/cow_mangler_explosion_normal_01.wav", entity,_,100,_,0.85);
				CreateParticle(-1, "drg_cow_explosioncore_charged_blue", false, "", 0.1, pos);
			}
		}
	}
	else
	{
		new Float:origin[3];
		new Float:ProjAngle[3];
		new Float:vBuffer[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
		GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vBuffer, 20.0);
		AddVectors(origin,vBuffer,origin);
		TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
		RequestFrame(fixPiercingVelocity,EntIndexToEntRef(entity))
	}
	return Plugin_Stop;
}
public Action:OnCollisionMoonveil(entity, client)
{
	decl String:strName[128];
	GetEntityClassname(client, strName, 128)
	decl String:strName1[128];
	GetEntityClassname(entity, strName1, 128)
	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			if(IsOnDifferentTeams(owner,client))
			{
				new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new Float:mult = 1.0
					new Address:multiHitActive = TF2Attrib_GetByName(CWeapon, "taunt move acceleration time");
					if(multiHitActive != Address_Null)
					{
						mult *= TF2Attrib_GetValue(multiHitActive) + 1.0;
					}
					SDKHooks_TakeDamage(client,owner,owner,mult*35.0,DMG_SONIC+DMG_PREVENT_PHYSICS_FORCE+DMG_RADIUS_MAX,CWeapon, NULL_VECTOR, NULL_VECTOR);
				}
				RemoveEntity(entity);
			}
		}
	}
	new Float:pos[3]
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", pos);
	EmitSoundToAll("weapons/cow_mangler_explosion_normal_01.wav", entity,_,100,_,0.85);
	CreateParticle(-1, "drg_cow_explosioncore_charged_blue", false, "", 0.1, pos);
	return Plugin_Continue;
}
public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	new bool:changed = false;
	if(IsValidClient3(victim) && IsValidClient3(attacker))
	{
		if(IsValidEntity(inflictor))
			ShouldNotHome[inflictor][victim] = true;
		if(damagetype == (DMG_RADIATION+DMG_DISSOLVE))//Radiation.
		{
			RadiationBuildup[victim] += damage;
			checkRadiation(victim,attacker);
		}
		if(damagetype != (DMG_PREVENT_PHYSICS_FORCE+DMG_ENERGYBEAM))
		{
			new bool:delayBool = true;
			new Address:regenerationPowerup = TF2Attrib_GetByName(victim, "recall");
			if(regenerationPowerup != Address_Null)
			{
				new Float:regenerationPowerupValue = TF2Attrib_GetValue(regenerationPowerup);
				if(regenerationPowerupValue > 0.0){delayBool = false;}
			}
			if(delayBool)
			{
				new Address:armorDelay = TF2Attrib_GetByName(victim, "tmp dmgbuff on hit");
				if(armorDelay != Address_Null)
				{
					new Float:DelayAmount = TF2Attrib_GetValue(armorDelay) + 1.0;
					TF2_AddCondition(victim, TFCond_NoTaunting_DEPRECATED, 1.5/DelayAmount);
				}
				else
				{
					TF2_AddCondition(victim, TFCond_NoTaunting_DEPRECATED, 1.5);
				}
			}
		}
		if(damagetype == (DMG_BURN | DMG_PREVENT_PHYSICS_FORCE))
		{
			new CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(CWeapon))
			{
				damage = 0.0;
				new Float:burndmgMult = 1.0;
				new Address:burnMult1 = TF2Attrib_GetByName(CWeapon, "shot penetrate all players");
				new Address:burnMult2 = TF2Attrib_GetByName(CWeapon, "weapon burn dmg increased");
				new Address:burnMult3 = TF2Attrib_GetByName(CWeapon, "weapon burn dmg reduced");
				new Address:burnMult4 = TF2Attrib_GetByName(attacker, "weapon burn dmg increased");
				new Address:burnDivide = TF2Attrib_GetByName(CWeapon, "dmg penalty vs players");
				if(burnMult1 != Address_Null) {
				burndmgMult*=TF2Attrib_GetValue(burnMult1)
				}
				if(burnMult2 != Address_Null) {
				burndmgMult*=TF2Attrib_GetValue(burnMult2)
				}
				if(burnMult3 != Address_Null) {
				burndmgMult*=TF2Attrib_GetValue(burnMult3)
				}
				if(burnMult4 != Address_Null) {
				burndmgMult*=TF2Attrib_GetValue(burnMult4)
				}
				if(burnDivide != Address_Null) {
				burndmgMult/=TF2Attrib_GetValue(burnDivide)
				}
				//PrintToServer("%.2f, %.2f",TF2_GetDPSModifiers(attacker, CWeapon, false, false) * burndmgMult, burndmgMult)
				SDKHooks_TakeDamage(victim, attacker, attacker, 2.0*TF2_GetDPSModifiers(attacker, CWeapon, false, false)*burndmgMult, DMG_SLASH, -1, NULL_VECTOR, NULL_VECTOR);
				return Plugin_Stop;
			}
		}
		new Address:resistancePowerup = TF2Attrib_GetByName(victim, "expiration date");
		if(resistancePowerup != Address_Null)
		{
			new Float:resistancePowerupValue = TF2Attrib_GetValue(resistancePowerup);
			if(resistancePowerupValue > 0.0)
			{
				if(critStatus[victim] == true){
					critStatus[victim] = false;
					damage /= 2.25;
				}else if(miniCritStatus[victim] == true){
					miniCritStatus[victim] = false;
					damage /= 1.4;
				}
				
				damage /= 2.0;
				changed = true;
			}
		}
		new Address:vampirePowerup = TF2Attrib_GetByName(victim, "unlimited quantity");//Vampire Powerup
		if(vampirePowerup != Address_Null)
		{
			new Float:vampirePowerupValue = TF2Attrib_GetValue(vampirePowerup);
			if(vampirePowerupValue > 0.0)
			{
				damage *= 0.75;
				changed = true;
			}
		}
		new Address:revengePowerup = TF2Attrib_GetByName(victim, "sniper penetrate players when charged");//Vampire Powerup
		if(revengePowerup != Address_Null)
		{
			new Float:revengePowerupValue = TF2Attrib_GetValue(revengePowerup);
			if(revengePowerupValue > 0.0)
			{
				damage *= 0.8;
				changed = true;
			}
		}
		new Address:regenerationPowerup = TF2Attrib_GetByName(victim, "recall");//Vampire Powerup
		if(regenerationPowerup != Address_Null)
		{
			new Float:regenerationPowerupValue = TF2Attrib_GetValue(regenerationPowerup);
			if(regenerationPowerupValue > 0.0)
			{
				damage *= 0.75;
				changed = true;
			}
		}

		new Address:knockoutPowerupVictim = TF2Attrib_GetByName(victim, "taunt is press and hold");
		if(knockoutPowerupVictim != Address_Null)
		{
			new Float:knockoutPowerupValue = TF2Attrib_GetValue(knockoutPowerupVictim);
			if(knockoutPowerupValue > 0.0){
				damage *= 0.8;
				changed = true;
			}
		}
		
		new Address:kingPowerup = TF2Attrib_GetByName(victim, "attack projectiles");
		if(kingPowerup != Address_Null && TF2Attrib_GetValue(kingPowerup) > 0.0)
		{
			damage *= 0.8;
			changed = true;
		}
		
		if(TF2_IsPlayerInCondition(attacker, TFCond_Plague))
		{
			if(IsValidClient3(plagueAttacker[attacker]))
			{
				new Address:plaguePowerup = TF2Attrib_GetByName(plagueAttacker[attacker], "disable fancy class select anim");
				if(plaguePowerup != Address_Null)
				{
					new Float:plaguePowerupValue = TF2Attrib_GetValue(plaguePowerup);
					if(plaguePowerupValue > 0.0)
					{
						damage /= 2.0;
						changed = true;
					}
				}
			}
		}
		new Address:plaguePowerup = TF2Attrib_GetByName(victim, "disable fancy class select anim");
		if(plaguePowerup != Address_Null && TF2Attrib_GetValue(plaguePowerup) > 0.0)
		{
			damage *= 0.7;
			changed = true;
		}
		
		new Address:supernovaPowerupVictim = TF2Attrib_GetByName(victim, "spawn with physics toy");
		if(supernovaPowerupVictim != Address_Null && TF2Attrib_GetValue(supernovaPowerupVictim) > 0.0)
		{
			damage *= 0.8;
			changed = true;
		}
		
		new Address:strengthPowerup = TF2Attrib_GetByName(attacker, "crit kill will gib");
		if(strengthPowerup != Address_Null)
		{
			new Float:strengthPowerupValue = TF2Attrib_GetValue(strengthPowerup);
			if(strengthPowerupValue > 0.0){
				damagetype |= DMG_NOCLOSEDISTANCEMOD;
				damage *= 2.0;
				changed = true;
			}
		}
		
		new Address:revengePowerupAttacker = TF2Attrib_GetByName(attacker, "sniper penetrate players when charged");
		if(revengePowerupAttacker != Address_Null)
		{
			if(RageActive[attacker] == true && TF2Attrib_GetValue(revengePowerupAttacker) > 0.0)
			{
				damagetype |= DMG_RADIUS_MAX;
				damage *= 1.75;
				changed = true;
				if(powerupParticle[attacker] <= 0.0)
				{
					CreateParticle(victim, "critgun_weaponmodel_red", true, "", 1.0,_,_,1);
					TE_SendToAll();
					powerupParticle[attacker] = 1.0;
				}
			}
		}
		
		new Address:precisionPowerup = TF2Attrib_GetByName(attacker, "refill_ammo");
		if(precisionPowerup != Address_Null)
		{
			new Float:precisionPowerupValue = TF2Attrib_GetValue(precisionPowerup);
			if(precisionPowerupValue > 0.0){
				damagetype |= DMG_RADIUS_MAX;
				damage *= 1.25;
				changed = true;
			}
		}
		
		new clientTeam = GetClientTeam(attacker);
		new Float:clientPos[3];
		GetEntPropVector(attacker, Prop_Data, "m_vecOrigin", clientPos);
		new Float:highestKingDMG = 1.0;
		for(new i = 1;i<MaxClients;i++)
		{
			if(IsValidClient3(i) && IsPlayerAlive(i))
			{
				new iTeam = GetClientTeam(i);
				if(clientTeam == iTeam)
				{
					new Float:VictimPos[3];
					GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
					VictimPos[2] += 30.0;
					new Float:Distance = GetVectorDistance(clientPos,VictimPos);
					if(Distance <= 600.0)
					{
						new Address:kingPowerupAttacker = TF2Attrib_GetByName(i, "attack projectiles");
						if(kingPowerupAttacker != Address_Null && TF2Attrib_GetValue(kingPowerupAttacker) > 0.0)
						{
							highestKingDMG = 1.2;
							break;
						}
					}
				}
			}
		}
		if(highestKingDMG > 1.0)
		{
			damage *= highestKingDMG;
			changed = true;
		}
		
		new Address:knockoutPowerup = TF2Attrib_GetByName(attacker, "taunt is press and hold");
		if(knockoutPowerup != Address_Null)
		{
			new Float:knockoutPowerupValue = TF2Attrib_GetValue(knockoutPowerup);
			if(knockoutPowerupValue > 0.0){
				if(_:TF2II_GetListedItemSlot(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"),TF2_GetPlayerClass(attacker)) == 2)
				{
					damage *= 1.75
					changed = true;
				}
			}
		}
		
		if(IsValidEntity(weapon) && weapon != 0 && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
		{
			new Address:bleedBuild = TF2Attrib_GetByName(weapon, "sapper damage bonus");
			if(bleedBuild != Address_Null)
			{
				BleedBuildup[victim] += TF2Attrib_GetValue(bleedBuild);
				if(BleedBuildup[victim] >= BleedMaximum[victim])
				{
					BleedBuildup[victim] = 0.0;
					
					new Float:bleedBonus = 1.0;
					
					new Address:vampirePowerup = TF2Attrib_GetByName(attacker, "unlimited quantity");
					if(vampirePowerup != Address_Null && TF2Attrib_GetValue(vampirePowerup) > 0.0)
					{
						bleedBonus += 0.25;
					}
					
					SDKHooks_TakeDamage(victim, attacker, attacker, TF2_GetDamageModifiers(attacker, weapon)*100.0*bleedBonus,DMG_PREVENT_PHYSICS_FORCE, -1, NULL_VECTOR, NULL_VECTOR);
					CreateParticle(victim, "env_sawblood", true, "", 2.0);
				}
			}
			new Address:radiationBuild = TF2Attrib_GetByName(weapon, "accepted wedding ring account id 1");
			if(radiationBuild != Address_Null)
			{
				RadiationBuildup[victim] += TF2Attrib_GetValue(radiationBuild);
				checkRadiation(victim,attacker);
			}
			new Address:Skill = TF2Attrib_GetByName(weapon, "apply look velocity on damage");
			if(Skill != Address_Null)
			{
				switch(TF2Attrib_GetValue(Skill))
				{
					case 13.0: //Bloodlust
					{
						new Float:offset[3]
						offset[2] += 40.0;
						CreateParticle(victim, "env_sawblood", true, "", 2.0, offset);
					}
				}
			}
			if(StunShotStun[attacker])
			{
				StunShotStun[attacker] = false;
				TF2_StunPlayer(victim, 1.5, 1.0, TF_STUNFLAGS_NORMALBONK, attacker);
			}
			if(!(damagetype & DMG_ENERGYBEAM))
			{
				new Float:clientpos[3],Float:targetpos[3];
				GetClientAbsOrigin(attacker, clientpos);
				GetClientAbsOrigin(victim, targetpos);
				new Float:distance = GetVectorDistance(clientpos, targetpos);
				if(distance > 512.0)
				{
					new Address:FalloffIncrease = TF2Attrib_GetByName(weapon, "dmg falloff increased");
					if(FalloffIncrease != Address_Null)
					{
						damagetype |= DMG_ENERGYBEAM;
						if(TF2Attrib_GetValue(FalloffIncrease) != 1.0)
						{
							new Float:Max = 1024.0; //the maximum units that the player and target is at (assuming you've already gotten the vectors)
							if(distance > Max)
							{
								distance = Max;
							}
							new Float:MinFallOffDist = 512.0 / (TF2Attrib_GetValue(FalloffIncrease) - 0.48); //the minimum units that the player and target is at (assuming you've already gotten the vectors) 
							new Float:base = damage; //base becomes the initial damage
							new Float:multiplier = (MinFallOffDist / Max); //divides the minimal distance with the maximum you've set
							new Float:falloff = (multiplier * base);  //this is to get how much the damage will be at maximum distance
							new Float:Sinusoidal = ((falloff-base) / (Max-MinFallOffDist));  //does slope formula to get a sinusoidal fall off
							new Float:intercept = (base - (Sinusoidal*MinFallOffDist));  //this calculation gets the 'y-intercept' to determine damage ramp up
							damage = ((Sinusoidal*distance)+intercept); //gets final damage by taking the slope formula, multiplying it by your vectors, and adds the damage ramp up Y intercept. 
						}
						changed = true;
						//Debug.
						//PrintToChat(attacker, "%.2f multiplier", multiplier);
						//PrintToChat(attacker, "%.2f falloff", falloff);
						//PrintToChat(attacker, "%.2f Sinusoidal", Sinusoidal);
						//PrintToChat(attacker, "%.2f intercept", intercept);
						//PrintToChat(attacker, "%.2f damage", damage);
					}
				}
			}
			new Address:ReflectActive = TF2Attrib_GetByName(victim, "extinguish restores health");
			if(ReflectActive != Address_Null)
			{
				new Float:ReflectDamage = damage;
				new Address:ReflectDamageMultiplier = TF2Attrib_GetByName(victim, "set cloak is movement based");
				if(ReflectDamageMultiplier != Address_Null && GetRandomInt(1, 100) < TF2Attrib_GetValue(ReflectActive) * 33.0)
				{
					new Float:ReflectMult = TF2Attrib_GetValue(ReflectDamageMultiplier);
					ReflectDamage *= ReflectMult
					SDKHooks_TakeDamage(attacker, victim, victim, ReflectDamage, (DMG_PREVENT_PHYSICS_FORCE+DMG_ENERGYBEAM), -1, NULL_VECTOR, NULL_VECTOR);
				}
			}
			
			for(new i = 1; i < MaxClients; i++)
			{
				if(IsValidClient3(i) && GetClientTeam(i) == GetClientTeam(victim) && i != victim)
				{
					new Float:victimPos[3];
					new Float:guardianPos[3];
					GetClientEyePosition(victim,victimPos);
					GetClientEyePosition(i,guardianPos);
					if(GetVectorDistance(victimPos,guardianPos, false) < 1400.0)
					{
						new Address:RedirectActive = TF2Attrib_GetByName(i, "mult cloak meter regen rate");
						if(RedirectActive != Address_Null)
						{
							new Float:redirect = TF2Attrib_GetValue(RedirectActive);
							SDKHooks_TakeDamage(i, attacker, attacker, damage*redirect, (DMG_PREVENT_PHYSICS_FORCE+DMG_ENERGYBEAM), -1, NULL_VECTOR, NULL_VECTOR);
							damage *= (1-redirect);
							changed = true;
						}
					}
				}
			}
		}
		/*if(damage >= 2000000000.0 || damage <= -10000000.0)
		{
			new String:damageError[1024];
			
			Format(damageError, sizeof(damageError), "Somehow %N dealt damage out of bounds!", attacker);
			Format(damageError, sizeof(damageError), "%s\nDamage = %2.f", damageError,damage);
			if(IsValidEntity(weapon))
			{
				Format(damageError, sizeof(damageError), "%s\nWeapon = %i", damageError,GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
			}
			Format(damageError, sizeof(damageError), "%s\nVictim = %N", damageError,victim);
			Format(damageError, sizeof(damageError), "%s\nInflictor = %i", damageError,inflictor);
			Format(damageError, sizeof(damageError), "%s\nDamage Type = %i", damageError,damagetype);
			Format(damageError, sizeof(damageError), "%s\nDamage Custom = %i", damageError,damagecustom);
			Format(damageError, sizeof(damageError), "%s\nDamage Types = ", damageError);

			if(damagetype & DMG_BULLET)
			{
				Format(damageError, sizeof(damageError), "%s | Bullet", damageError);
			}
			if(damagetype & DMG_SLASH)
			{
				Format(damageError, sizeof(damageError), "%s | Slash", damageError);
			}
			if(damagetype & DMG_BURN)
			{
				Format(damageError, sizeof(damageError), "%s | Burn", damageError);
			}
			if(damagetype & DMG_VEHICLE)
			{
				Format(damageError, sizeof(damageError), "%s | Vehicle", damageError);
			}
			if(damagetype & DMG_FALL)
			{
				Format(damageError, sizeof(damageError), "%s | Fall", damageError);
			}
			if(damagetype & DMG_BLAST)
			{
				Format(damageError, sizeof(damageError), "%s | Blast", damageError);
			}
			if(damagetype & DMG_CLUB)
			{
				Format(damageError, sizeof(damageError), "%s | Club", damageError);
			}
			if(damagetype & DMG_SHOCK)
			{
				Format(damageError, sizeof(damageError), "%s | Shock", damageError);
			}
			if(damagetype & DMG_SONIC)
			{
				Format(damageError, sizeof(damageError), "%s | Sonic", damageError);
			}
			if(damagetype & DMG_PREVENT_PHYSICS_FORCE)
			{
				Format(damageError, sizeof(damageError), "%s | No KB", damageError);
			}
			if(damagetype & DMG_ACID)
			{
				Format(damageError, sizeof(damageError), "%s | Crit", damageError);
			}
			if(damagetype & DMG_ENERGYBEAM)
			{
				Format(damageError, sizeof(damageError), "%s | No Fall-Off", damageError);
			}
			if(damagetype & DMG_POISON)
			{
				Format(damageError, sizeof(damageError), "%s | No Fall-Off Close", damageError);
			}
			if(damagetype & DMG_RADIATION)
			{
				Format(damageError, sizeof(damageError), "%s | Half Fall-Off", damageError);
			}
			if(damagetype & DMG_SLOWBURN)
			{
				Format(damageError, sizeof(damageError), "%s | Has Fall-Off", damageError);
			}
			if(damagetype & DMG_PLASMA)
			{
				Format(damageError, sizeof(damageError), "%s | Ignite Victim", damageError);
			}
			if(damagetype & DMG_AIRBOAT)
			{
				Format(damageError, sizeof(damageError), "%s | Can Headshot", damageError);
			}
			if(damagetype & DMG_DROWN)
			{
				Format(damageError, sizeof(damageError), "%s | Drown", damageError);
			}
			if(damagetype & DMG_PARALYZE)
			{
				Format(damageError, sizeof(damageError), "%s | Paralyze", damageError);
			}
			if(damagetype & DMG_NERVEGAS)
			{
				Format(damageError, sizeof(damageError), "%s | Nerve Gas", damageError);
			}
			if(damagetype & DMG_DROWNRECOVER)
			{
				Format(damageError, sizeof(damageError), "%s | Drown Recovery", damageError);
			}
			
			if(damagetype & DMG_PHYSGUN)
			{
				Format(damageError, sizeof(damageError), "%s | PhysGun", damageError);
			}
			if(damagetype & DMG_DISSOLVE)
			{
				Format(damageError, sizeof(damageError), "%s | Dissolve", damageError);
			}
			if(damagetype & DMG_BLAST_SURFACE)
			{
				Format(damageError, sizeof(damageError), "%s | Blast Surface", damageError);
			}
			if(damagetype & DMG_DIRECT)
			{
				Format(damageError, sizeof(damageError), "%s | Direct", damageError);
			}
			if(damagetype & DMG_BUCKSHOT)
			{
				Format(damageError, sizeof(damageError), "%s | Buckshot", damageError);
			}
			LogError(damageError);
		}
		*/
		//PrintToChat(attacker,"damageCustom %i", damagecustom);
	}
	if(damage < 0.0)
	{
		damage *= 0.0;
		return Plugin_Changed;
	}
	if(changed == true)
		return Plugin_Changed;
	return Plugin_Continue;
}
////
// On Take Damage
public Action:TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3],int damagecustom, CritType &critType)
{
	if(damagetype & DMG_CRIT)
	{
		critStatus[victim] = true
		damagetype &= ~DMG_CRIT;
		damage *= 2.25
		return Plugin_Changed;
	}
	if(IsValidClient3(victim) && miniCritStatus[victim] == false && IsValidClient3(attacker) && (critType == CritType_MiniCrit || miniCritStatusAttacker[attacker] > 0.0 || miniCritStatusVictim[victim] > 0.0))
	{
		//PrintToChat(attacker, "minicrit override 1");
		miniCritStatus[victim] = true
		critType = CritType_None
		damage *= 1.4;
		
		if(damagetype & DMG_CRIT)
			damagetype &= ~DMG_CRIT;
		
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
public Action:TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage,
int &damagetype, int &weapon, float damageForce[3], float damagePosition[3],
int damagecustom, CritType &critType)
{
	if(damagetype & DMG_CRIT)
	{
		critStatus[victim] = true
		damagetype &= ~DMG_CRIT;
		damage = lastDamageTaken[victim] * 2.25;
		
		lastDamageTaken[victim] = 0.0;
		return Plugin_Changed;
	}
	if(IsValidClient3(victim) && lastDamageTaken[victim] != 0.0 && miniCritStatus[victim] == false && IsValidClient3(attacker) && (critType == CritType_MiniCrit || miniCritStatusAttacker[attacker] > 0.0 || miniCritStatusVictim[victim] > 0.0))
	{
		//PrintToChat(attacker, "minicrit override failsafe");
		miniCritStatus[victim] = true
		critType = CritType_None
		damage = lastDamageTaken[victim] * 1.4;
		
		if(damagetype & DMG_CRIT)
			damagetype &= ~DMG_CRIT;
		
		lastDamageTaken[victim] = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	//PrintToChatAll("%i", inflictor);
	if(damagetype & DMG_CRIT)
	{
		critStatus[victim] = true
		damagetype &= ~DMG_CRIT;
		damage *= 2.25
	}
	if (damagecustom == TF_CUSTOM_BACKSTAB && IsValidClient3(victim))
	{
		new bool:ToggleBackstab = true;
		new Address:canBeBackstabbed = TF2Attrib_GetByName(victim, "set item tint RGB");
		if(canBeBackstabbed != Address_Null && TF2Attrib_GetValue(canBeBackstabbed) != 0.0)
		{
			ToggleBackstab = false;
		}
		if(ToggleBackstab == true)
		{
			new Address:dmgMult1 = TF2Attrib_GetByName(weapon, "damage bonus");
			new Address:dmgMult3 = TF2Attrib_GetByName(weapon, "damage bonus HIDDEN");
			new Address:dmgMult4 = TF2Attrib_GetByName(weapon, "damage penalty");
			damage = 450.0;
			if(dmgMult1 != Address_Null)
			{
				damage *= TF2Attrib_GetValue(dmgMult1);
			}	
			if(dmgMult3 != Address_Null)
			{
				damage *= TF2Attrib_GetValue(dmgMult3);
			}	
			if(dmgMult4 != Address_Null)
			{
				damage *= TF2Attrib_GetValue(dmgMult4);
			}
			
			new Address:backstabRadiation = TF2Attrib_GetByName(weapon, "no double jump");
			if(backstabRadiation != Address_Null)
			{
				RadiationBuildup[victim] += TF2Attrib_GetValue(backstabRadiation);
				checkRadiation(victim,attacker);
			}
			new Address:stealthedBackstab = TF2Attrib_GetByName(weapon, "airblast cost increased");
			if(stealthedBackstab != Address_Null)
			{
				TF2_AddCondition(attacker, TFCond_StealthedUserBuffFade, TF2Attrib_GetValue(stealthedBackstab));
				TF2_RemoveCondition(attacker, TFCond_Stealthed)
			}
		}
		
	}
	if(damagecustom == TF_CUSTOM_CANNONBALL_PUSH)
	{
		damage = TF2_GetDamageModifiers(attacker,weapon) * 50.0;
		new Address:lameMult = TF2Attrib_GetByName(weapon, "dmg penalty vs players");
		if(lameMult != Address_Null)//lame. AP applies twice.
		{
			damage /= TF2Attrib_GetValue(lameMult);
		}
		return Plugin_Changed;
	}
	if (!IsValidClient3(inflictor) && IsValidEdict(inflictor))
	{
		new String:classname[128]; 
		GetEdictClassname(inflictor, classname, sizeof(classname)); 
		new weaponIdx = ((IsValidEntity(weapon) && weapon > MaxClients && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
		//PrintToChatAll("classname %s",classname);
		if ((!strcmp("obj_sentrygun", classname) || !strcmp("tf_projectile_sentryrocket", classname)) || weaponIdx == 140)
		{
			new owner; 
			if(!strcmp("tf_projectile_sentryrocket", classname))
			{
				owner = attacker;
			}
			else
			{
				owner = GetEntPropEnt(inflictor, Prop_Send, "m_hBuilder");
			}
			
			if(!IsValidClient3(owner))
			{
				if(IsValidForDamage(GetEntProp(inflictor, Prop_Send, "m_hBuiltOnEntity")))
				{
					owner = GetEntProp(inflictor, Prop_Send, "m_hBuiltOnEntity");
				}
			}
			if(IsValidForDamage(owner))
			{
				new String:Ownerclassname[128]; 
				GetEdictClassname(owner, Ownerclassname, sizeof(Ownerclassname)); 
				if(StrEqual(Ownerclassname, "tank_boss"))
				{
					damage *= TankSentryDamageMod;
					damagetype |= DMG_PREVENT_PHYSICS_FORCE;
				}
			}
			if(IsValidClient3(owner))
			{
				new melee = GetPlayerWeaponSlot(owner,2);
				if((GetEntPropFloat(inflictor, Prop_Send, "m_flModelScale") != 0.3))
				{
					damagetype |= DMG_PREVENT_PHYSICS_FORCE;
					
					if(IsValidEntity(melee))
					{
						new Address:sentryOverrideActive = TF2Attrib_GetByName(melee, "override projectile type");
						if(sentryOverrideActive != Address_Null)
						{
							new Float:sentryOverride = TF2Attrib_GetValue(sentryOverrideActive);
							switch(sentryOverride)
							{
								case 34.0:
								{
									if(damagetype & DMG_BULLET)
									{
										if(0.1 >= GetRandomFloat(0.0, 1.0))
										{
											new iEntity = CreateEntityByName("tf_projectile_cleaver");
											if (IsValidEdict(iEntity)) 
											{
												new iTeam = GetClientTeam(owner);
												new Float:fAngles[3]
												new Float:fOrigin[3]
												new Float:vBuffer[3]
												new Float:fVelocity[3]
												new Float:fwd[3]
												SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);
												SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
												new angleOffsetB = FindSendPropInfo("CObjectSentrygun", "m_iAmmoShells") - 16;
												GetEntPropVector( inflictor, Prop_Send, "m_vecOrigin", fOrigin );
												if(GetEntProp(inflictor, Prop_Send, "m_iUpgradeLevel") == 0)
												{
													fOrigin[2] += 30.0;
												}
												else if(GetEntProp(inflictor, Prop_Send, "m_bMiniBuilding") == 1)
												{
													fOrigin[2] += 25.0;
												}
												else
												{
													fOrigin[2] += 40.0;
												}
												
												GetEntDataVector( inflictor, angleOffsetB, fAngles );

												GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
												ScaleVector(fwd, 30.0);
												
												AddVectors(fOrigin, fwd, fOrigin);
												fAngles[0] -= 5.0;
												GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
												new Float:Speed[3];
												new bool:movementType = false;
												if(HasEntProp(iEntity, Prop_Data, "m_vecAbsVelocity"))
												{
													GetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", Speed);
													fVelocity[0] = vBuffer[0]*GetVectorLength(Speed);
													fVelocity[1] = vBuffer[1]*GetVectorLength(Speed);
													fVelocity[2] = vBuffer[2]*GetVectorLength(Speed);
													if(GetVectorLength(Speed) > 5.0)
													{
														movementType = true;
													}
												}
												if(movementType == false)
												{
													new Float:velocity = 2000.0;
													new Address:projspeed = TF2Attrib_GetByName(melee, "Projectile speed increased");
													new Address:projspeed1 = TF2Attrib_GetByName(melee, "Projectile speed decreased");
													if(projspeed != Address_Null){
														velocity *= TF2Attrib_GetValue(projspeed)
													}
													if(projspeed1 != Address_Null){
														velocity *= TF2Attrib_GetValue(projspeed1)
													}
													new Float:vecAngImpulse[3];
													GetCleaverAngularImpulse(vecAngImpulse);
													fVelocity[0] = vBuffer[0]*velocity;
													fVelocity[1] = vBuffer[1]*velocity;
													fVelocity[2] = vBuffer[2]*velocity;
													
													TeleportEntity(iEntity, fOrigin, fAngles, NULL_VECTOR);
													DispatchSpawn(iEntity);
													SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vecAngImpulse, owner, 0, 5.0);
												}
											}
										}
									}
								}
								case 33.0:
								{
									if(damagetype & DMG_BULLET)
									{
										if(firestormCounter[owner] >= 4)
										{
											new iEntity = CreateEntityByName("tf_projectile_spellfireball");
											if (IsValidEdict(iEntity)) 
											{
												new iTeam = GetClientTeam(owner);
												new Float:fAngles[3]
												new Float:fOrigin[3]
												new Float:vBuffer[3]
												new Float:fVelocity[3]
												new Float:fwd[3]
												SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);
												SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
												new angleOffsetB = FindSendPropInfo("CObjectSentrygun", "m_iAmmoShells") - 16;
												GetEntPropVector( inflictor, Prop_Send, "m_vecOrigin", fOrigin );
												if(GetEntProp(inflictor, Prop_Send, "m_iUpgradeLevel") == 0)
												{
													fOrigin[2] += 30.0;
												}
												else if(GetEntProp(inflictor, Prop_Send, "m_bMiniBuilding") == 1)
												{
													fOrigin[2] += 25.0;
												}
												else
												{
													fOrigin[2] += 40.0;
												}
												
												GetEntDataVector( inflictor, angleOffsetB, fAngles );

												GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
												ScaleVector(fwd, 30.0);
												
												AddVectors(fOrigin, fwd, fOrigin);
												GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
												new Float:Speed[3];
												new bool:movementType = false;
												if(HasEntProp(iEntity, Prop_Data, "m_vecAbsVelocity"))
												{
													GetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", Speed);
													fVelocity[0] = vBuffer[0]*GetVectorLength(Speed);
													fVelocity[1] = vBuffer[1]*GetVectorLength(Speed);
													fVelocity[2] = vBuffer[2]*GetVectorLength(Speed);
													if(GetVectorLength(Speed) > 5.0)
													{
														movementType = true;
													}
												}
												if(movementType == false)
												{
													new Float:velocity = 11000.0;
													new Float:vecAngImpulse[3];
													GetCleaverAngularImpulse(vecAngImpulse);
													fVelocity[0] = vBuffer[0]*velocity;
													fVelocity[1] = vBuffer[1]*velocity;
													fVelocity[2] = vBuffer[2]*velocity;
													
													TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
													DispatchSpawn(iEntity);
													//SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vecAngImpulse, owner, 0, 5.0);
												}
											}
											firestormCounter[owner] = 0;
										}
										else
										{
											firestormCounter[owner]++
										}
										damage = 0.0;
									}
								}
								case 32.0:
								{
									if(damagetype & DMG_BULLET)
									{
										if(0.025 >= GetRandomFloat(0.0, 1.0))
										{
											new iEntity = CreateEntityByName("tf_projectile_spellmeteorshower");
											if (IsValidEdict(iEntity)) 
											{
												new iTeam = GetClientTeam(owner);
												new Float:fAngles[3]
												new Float:fOrigin[3]
												new Float:vBuffer[3]
												new Float:fVelocity[3]
												SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);
												SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
												new angleOffsetB = FindSendPropInfo("CObjectSentrygun", "m_iAmmoShells") - 16;
												GetEntPropVector( inflictor, Prop_Send, "m_vecOrigin", fOrigin );
												if(GetEntProp(inflictor, Prop_Send, "m_iUpgradeLevel") == 0)
												{
													fOrigin[2] += 30.0;
												}
												else if(GetEntProp(inflictor, Prop_Send, "m_bMiniBuilding") == 1)
												{
													fOrigin[2] += 25.0;
												}
												else
												{
													fOrigin[2] += 40.0;
												}
												GetEntDataVector( inflictor, angleOffsetB, fAngles );
												fAngles[0] -= 5.0;
												GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
												new Float:Speed[3];
												new bool:movementType = false;
												if(HasEntProp(iEntity, Prop_Data, "m_vecAbsVelocity"))
												{
													GetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", Speed);
													fVelocity[0] = vBuffer[0]*GetVectorLength(Speed);
													fVelocity[1] = vBuffer[1]*GetVectorLength(Speed);
													fVelocity[2] = vBuffer[2]*GetVectorLength(Speed);
													if(GetVectorLength(Speed) > 5.0)
													{
														movementType = true;
													}
												}
												if(movementType == false)
												{
													new Float:velocity = 2000.0;
													new Address:projspeed = TF2Attrib_GetByName(melee, "Projectile speed increased");
													new Address:projspeed1 = TF2Attrib_GetByName(melee, "Projectile speed decreased");
													if(projspeed != Address_Null){
														velocity *= TF2Attrib_GetValue(projspeed)
													}
													if(projspeed1 != Address_Null){
														velocity *= TF2Attrib_GetValue(projspeed1)
													}
													new Float:vecAngImpulse[3];
													GetCleaverAngularImpulse(vecAngImpulse);
													fVelocity[0] = vBuffer[0]*velocity;
													fVelocity[1] = vBuffer[1]*velocity;
													fVelocity[2] = vBuffer[2]*velocity;
													
													TeleportEntity(iEntity, fOrigin, fAngles, NULL_VECTOR);
													DispatchSpawn(iEntity);
													SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vecAngImpulse, owner, 0, 5.0);
												}
											}
										}
									}
								}
							}
						}
					}
				}
				new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new Address:SentryDmgActive = TF2Attrib_GetByName(CWeapon, "ring of fire while aiming");
					if(SentryDmgActive != Address_Null)
					{
						damage *= TF2Attrib_GetValue(SentryDmgActive);
					}
				}
				if(IsValidEntity(melee))
				{
					new Address:SentryDmgActive1 = TF2Attrib_GetByName(melee, "throwable detonation time");
					if(SentryDmgActive1 != Address_Null)
					{
						damage *= TF2Attrib_GetValue(SentryDmgActive1);
					}
					new Address:SentryDmgActive2 = TF2Attrib_GetByName(melee, "throwable fire speed");
					if(SentryDmgActive2 != Address_Null)
					{
						damage *= TF2Attrib_GetValue(SentryDmgActive2);
					}
					new Address:damageActive = TF2Attrib_GetByName(melee, "ubercharge");
					if(damageActive != Address_Null)
					{
						damage *= Pow(TF2Attrib_GetValue(damageActive), 5.0);
					}
				}
				if((!strcmp("obj_sentrygun", classname) && GetEntProp(inflictor, Prop_Send, "m_bMiniBuilding") == 1))
				{
					damage *= 1.5
				}
			}
		}
		if (StrEqual(classname, "obj_attachment_sapper"))
		{
			TF2_AddCondition(victim, TFCond_Sapped, 2.0);
		}
		if(IsValidClient3(attacker) && TF2_GetPlayerClass(attacker) == TFClass_Engineer)
		{
			if(!strcmp("tf_projectile_spellfireball", classname))
			{
				new primary = GetPlayerWeaponSlot(attacker,0)
				new melee = GetPlayerWeaponSlot(attacker,2)
				if(IsValidEntity(melee))
				{
					new Address:sentryOverrideActive = TF2Attrib_GetByName(melee, "override projectile type");
					if(sentryOverrideActive != Address_Null)
					{
						new Float:sentryOverride = TF2Attrib_GetValue(sentryOverrideActive);
						if(sentryOverride == 32.0)
						{
							damage = 20.0;
							damagetype |= DMG_PREVENT_PHYSICS_FORCE;
						}
						else if(sentryOverride == 33.0)
						{
							damage = 60.0;
							damagetype |= DMG_PREVENT_PHYSICS_FORCE;
						}
					}
					
					
					new Address:SentryDmgActive = TF2Attrib_GetByName(melee, "engy sentry damage bonus");
					new Address:SentryDmgActive1 = TF2Attrib_GetByName(melee, "throwable detonation time");
					new Address:SentryDmgActive2 = TF2Attrib_GetByName(melee, "throwable fire speed");
					if(SentryDmgActive != Address_Null)
					{
						damage *= TF2Attrib_GetValue(SentryDmgActive);
					}
					if(SentryDmgActive1 != Address_Null)
					{
						damage *= TF2Attrib_GetValue(SentryDmgActive1);
					}
					if(SentryDmgActive2 != Address_Null)
					{
						damage *= TF2Attrib_GetValue(SentryDmgActive2);
					}
					new Address:damageActive = TF2Attrib_GetByName(melee, "ubercharge");
					if(damageActive != Address_Null)
					{
						damage *= Pow(TF2Attrib_GetValue(damageActive), 5.0);
					}
				}
				if(IsValidEntity(primary))
				{
					new Address:SentryDmgActive2 = TF2Attrib_GetByName(primary, "engy sentry damage bonus");
					if(SentryDmgActive2 != Address_Null)
					{
						damage *= TF2Attrib_GetValue(SentryDmgActive2);
					}
				}
				new CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new Address:SentryDmgActive = TF2Attrib_GetByName(CWeapon, "ring of fire while aiming");
					if(SentryDmgActive != Address_Null)
					{
						damage *= TF2Attrib_GetValue(SentryDmgActive);
					}
				}
			}
		}
	}
	if(IsValidClient3(victim) && IsValidClient3(attacker))
	{
		if(IsFakeClient(attacker) && TF2Spawn_IsClientInSpawn(attacker))
		{
			damage *= 0.0;
			return Plugin_Changed;
		}
		if(TF2_GetPlayerClass(victim) == TFClass_Scout && weapon == GetPlayerWeaponSlot(victim,2)){
		damagetype |= DMG_PREVENT_PHYSICS_FORCE;
		return Plugin_Changed;
		}
		if(GetClientTeam(victim) == GetClientTeam(attacker))
		{
			return Plugin_Changed;
		}
		if(damagetype == 4 && damagecustom == 3 && TF2_GetPlayerClass(attacker) == TFClass_Pyro)
		{
			new secondary = GetWeapon(attacker,1);
			if(IsValidEntity(secondary) && weapon == secondary)
			{
				new Address:gasExplosionDamage = TF2Attrib_GetByName(weapon, "clip size bonus");
				if(gasExplosionDamage != Address_Null)
				{
					damage *= TF2Attrib_GetValue(gasExplosionDamage);
				}
			}
		}
		if(GetEntProp(victim, Prop_Send, "m_bGlowEnabled") == 1 || TF2_IsPlayerInCondition(victim, TFCond_UberchargedHidden))
		{
			TF2_AddCondition(victim, TFCond_MegaHeal, 0.01);
		}
		if(TF2_GetPlayerClass(victim) == TFClass_Spy && (TF2_IsPlayerInCondition(victim, TFCond_Cloaked) || TF2_IsPlayerInCondition(victim, TFCond_Stealthed)))
		{
			new Address:CloakResistance = TF2Attrib_GetByName(GetPlayerWeaponSlot(victim,4), "absorb damage while cloaked");
			if(CloakResistance != Address_Null)
			{
				damage *= TF2Attrib_GetValue(CloakResistance);
			}
		}
		if(TF2_IsPlayerInCondition(victim, TFCond_CompetitiveLoser))
		{
			damage *= 0.35;
		}
		if(TF2_IsPlayerInCondition(attacker, TFCond_DisguiseRemoved))
		{
			damage *= 1.8;
		}
		if(GetClientTeam(attacker) == GetClientTeam(victim) && victim != attacker)
		{
			damage *= 0.0;
		}
		if(IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
		{
			char damageCategory[64] 
			damageCategory = getDamageCategory(damagetype);
			new weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			switch(weaponIndex)
			{
				case 141,1004:
				{
					if(damagetype & DMG_CRIT)
					{
						TF2_AddCondition(victim, TFCond_TmpDamageBonus, 5.0);
					}
				}
			}
			if(TF2_IsPlayerInCondition(victim,TFCond_TmpDamageBonus))
			{
				damage *= 1.3;
			}
			if(attacker != victim)
			{
				new Address:minicritVictimOnHit = TF2Attrib_GetByName(weapon, "recipe component defined item 1");
				if(minicritVictimOnHit != Address_Null)
				{
					miniCritStatusVictim[victim] = TF2Attrib_GetValue(minicritVictimOnHit)
				}
				
				new Address:rageOnHit = TF2Attrib_GetByName(weapon, "mod rage on hit bonus");
				if(rageOnHit != Address_Null)
				{
					if(GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter") < 150.0)
					{
						SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter") + TF2Attrib_GetValue(rageOnHit))
					}
					//PrintToChat(attacker, "%.2f Rage",  GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter"))
				}
				new hitgroup = GetEntProp(victim, Prop_Data, "m_LastHitGroup");
				if(hitgroup == 1)
				{
					new Address:HeadshotsActive = TF2Attrib_GetByName(weapon, "charge time decreased");
					if(HeadshotsActive != Address_Null)
					{
						critStatus[victim] = true;
						damagecustom = 1;
						damage *= TF2Attrib_GetValue(HeadshotsActive);
					}
					//Fix The Classic's "Cannot Headshot Without Full Charge" while not scoped.
					new Address:classicDebuff = TF2Attrib_GetByName(weapon, "sniper no headshot without full charge");
					{
						if(classicDebuff != Address_Null && TF2Attrib_GetValue(classicDebuff) == 0.0 && !TF2_IsPlayerInCondition(attacker, TFCond_Zoomed))
						{
							damagetype |= DMG_CRIT;
							damagecustom = 1;
						}
					}
					new Address:precisionPowerup = TF2Attrib_GetByName(attacker, "refill_ammo");
					if(precisionPowerup != Address_Null)
					{
						new Float:precisionPowerupValue = TF2Attrib_GetValue(precisionPowerup);
						if(precisionPowerupValue > 0.0){
							miniCritStatus[victim] = true;
							damage *= precisionPowerupValue * 1.35;
							damagecustom = 1;
						}
					}
				}
			}
			if(TF2_IsPlayerInCondition(victim, TFCond_Sapped))
			{
				for(new i = 1;i<MaxClients;i++)
				{
					if(IsValidClient3(i) && GetClientTeam(i) == GetClientTeam(attacker))
					{
						if(TF2_GetPlayerClass(i) == TFClass_Spy)
						{
							new sapper = GetWeapon(i,6);
							if(IsValidEntity(sapper))
							{
								new Address:SappedPlayerVuln = TF2Attrib_GetByName(sapper, "scattergun knockback mult");
								if(SappedPlayerVuln != Address_Null)
								{
									damage *= TF2Attrib_GetValue(SappedPlayerVuln);
								}
							}
						}
					}
				}
			}
			if(TF2_GetPlayerClass(attacker) == TFClass_Medic)
			{
				new String:classname[128]; 
				GetEdictClassname(weapon, classname, sizeof(classname)); 
				if(weapon == GetPlayerWeaponSlot(attacker,0) && StrContains(classname, "crossbow") == -1)
				{
					damagetype |= DMG_ENERGYBEAM;
					damage *= 1.8;
				}
			}
			new Address:dmgBoost = TF2Attrib_GetByName(weapon, "mod demo buff type");
			if(dmgBoost != Address_Null)
			{
				damage *= TF2Attrib_GetValue(dmgBoost);
			}
			new Float:medicDMGBonus = 1.0;
			new healers = GetEntProp(attacker, Prop_Send, "m_nNumHealers");
			if(healers > 0)
			{
				for (new i = 1; i < MaxClients; i++)
				{
					if (IsValidClient(i))
					{
						new healerweapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
						if(IsValidEntity(healerweapon))
						{
							if(HasEntProp(healerweapon, Prop_Send, "m_hHealingTarget") && GetEntPropEnt(healerweapon, Prop_Send, "m_hHealingTarget") == attacker)
							{
								if(IsValidEntity(healerweapon))
								{
									new Address:dmgActive = TF2Attrib_GetByName(healerweapon, "hidden secondary max ammo penalty");
									if(dmgActive != Address_Null)
									{
										medicDMGBonus += TF2Attrib_GetValue(dmgActive);
									}
								}
							}
						}
					}
				}
			}
			damage *= medicDMGBonus;
			new Address:SniperChargingFactorActive = TF2Attrib_GetByName(weapon, "no charge impact range");
			if(SniperChargingFactorActive != Address_Null)
			{
				if(LastCharge[attacker] > 50.0)
				{
					damage *= TF2Attrib_GetValue(SniperChargingFactorActive);
				}
			}
			new Address:CleaverdamageActive = TF2Attrib_GetByName(weapon, "disguise damage reduction");
			if(CleaverdamageActive != Address_Null)
			{
				damage *= TF2Attrib_GetValue(CleaverdamageActive);
			}
			new Address:damageModifierActive = TF2Attrib_GetByName(weapon, "throwable healing");
			if(damageModifierActive != Address_Null)
			{
				damage *= TF2Attrib_GetValue(damageModifierActive);
			}
			new Address:damageModifierActive2 = TF2Attrib_GetByName(weapon, "taunt is highfive");
			if(damageModifierActive2 != Address_Null)
			{
				damage *= TF2Attrib_GetValue(damageModifierActive2);
			}
			new Address:HiddenDamageActive = TF2Attrib_GetByName(weapon, "throwable damage");
			if(HiddenDamageActive != Address_Null)
			{
				damage *= TF2Attrib_GetValue(HiddenDamageActive);
			}
			new Address:expodamageActive = TF2Attrib_GetByName(weapon, "taunt turn speed");
			if(expodamageActive != Address_Null)
			{
				damage *= Pow(TF2Attrib_GetValue(expodamageActive), 6.0);
			}
			new Address:HeadshotDamage = TF2Attrib_GetByName(weapon, "overheal penalty");
			if(HeadshotDamage != Address_Null && damagecustom == 1)
			{
				damage *= TF2Attrib_GetValue(HeadshotDamage);
			}

			new Float:burndmgMult = 1.0;
			new Address:burnMult10 = TF2Attrib_GetByName(weapon, "shot penetrate all players");
			new Address:burnMult11 = TF2Attrib_GetByName(weapon, "weapon burn dmg increased");
			if(burnMult10 != Address_Null) {
			burndmgMult*=TF2Attrib_GetValue(burnMult10)
			}
			if(burnMult11 != Address_Null) {
			burndmgMult*=TF2Attrib_GetValue(burnMult11)
			}
			new Address:FireDamageActive = TF2Attrib_GetByName(weapon, "flame_ignore_player_velocity");
			if(GetClientTeam(attacker) != GetClientTeam(victim) && FireDamageActive != Address_Null && TF2Attrib_GetValue(FireDamageActive) > 0.1 &&
			TF2_GetDPSModifiers(attacker, weapon)*burndmgMult >= fl_HighestFireDamage[victim] && 
			!(damagetype & DMG_BURN && damagetype & DMG_PREVENT_PHYSICS_FORCE) && !(damagetype & DMG_SLASH)) // New afterburn system.
			{
				new Float:afterburnDuration = 2.0;
				new Address:FireDurationActive = TF2Attrib_GetByName(weapon, "weapon burn time increased");
				if(FireDurationActive != Address_Null)
				{
					afterburnDuration *= TF2Attrib_GetValue(FireDurationActive);
				}
				TF2_IgnitePlayer(victim, attacker, afterburnDuration);
				damagetype |= DMG_PLASMA;
				fl_HighestFireDamage[victim] = TF2_GetDPSModifiers(attacker, weapon)*burndmgMult;
			}
			new Address:overrideproj = TF2Attrib_GetByName(weapon, "override projectile type");
			new Address:energyWeapActive = TF2Attrib_GetByName(weapon, "energy weapon penetration");
			if(overrideproj != Address_Null)
			{
				new Float:override = TF2Attrib_GetValue(overrideproj);
				if((override > 1.0 && override <= 2.0) || (override > 5.0 && override <= 6.0))
				{
					new Address:bulletspershot = TF2Attrib_GetByName(weapon, "bullets per shot bonus");
					new Address:bulletspershotBody = TF2Attrib_GetByName(attacker, "bullets per shot bonus");
					new Address:accscales = TF2Attrib_GetByName(weapon, "accuracy scales damage");

					if(accscales != Address_Null)
					{
						damage *= Pow(TF2Attrib_GetValue(accscales),0.95);
					}
					if(bulletspershot != Address_Null)
					{
						damage *= Pow(TF2Attrib_GetValue(bulletspershot), 0.9)
					}
					if(bulletspershotBody != Address_Null)
					{
						damage *= Pow(TF2Attrib_GetValue(bulletspershotBody), 0.9)
					}
				}
				if(override == 31)
				{
					new Address:DamageBonusHidden = TF2Attrib_GetByName(weapon, "damage bonus HIDDEN");
					new Address:DamagePenalty = TF2Attrib_GetByName(weapon, "damage penalty");
					new Address:DamageBonus = TF2Attrib_GetByName(weapon, "damage bonus");
					new Address:bulletspershot = TF2Attrib_GetByName(weapon, "bullets per shot bonus");
					new Address:accscales = TF2Attrib_GetByName(weapon, "accuracy scales damage");
					
					if(DamageBonusHidden != Address_Null)
					{
						damage *= TF2Attrib_GetValue(DamageBonusHidden);
					}
					if(DamagePenalty != Address_Null)
					{
						damage *= TF2Attrib_GetValue(DamagePenalty);
					}
					if(DamageBonus != Address_Null)
					{
						damage *= TF2Attrib_GetValue(DamageBonus);
					}
					if(accscales != Address_Null)
					{
						damage *= Pow(TF2Attrib_GetValue(accscales),0.95);
					}
					if(bulletspershot != Address_Null)
					{
						damage *= Pow(TF2Attrib_GetValue(bulletspershot), 0.9)
					}
				}
			}
			if(energyWeapActive != Address_Null && TF2Attrib_GetValue(energyWeapActive) != 0.0)
			{
				new Address:bulletspershot = TF2Attrib_GetByName(weapon, "bullets per shot bonus");
				new Address:accscales = TF2Attrib_GetByName(weapon, "accuracy scales damage");
				if(accscales != Address_Null)
				{
					damage *= Pow(TF2Attrib_GetValue(accscales),0.95);
				}
				if(bulletspershot != Address_Null)
				{
					damage *= Pow(TF2Attrib_GetValue(bulletspershot), 0.9)
				}
			}
			if(damagecustom == TF_CUSTOM_PLASMA_CHARGED)
			{
				PrintToConsole(attacker, "Full charge hit!");
				new Address:clipActive = TF2Attrib_GetByName(weapon, "clip size bonus upgrade");
				if(clipActive != Address_Null)
				{
					damage *= Pow(TF2Attrib_GetValue(clipActive)+1.0, 0.9);
				}
				damagetype |= DMG_CRIT;
			}
			if (damagecustom == 46 && damagetype & DMG_SHOCK && IsValidClient3(victim))
			{
				new Address:dmgMult1 = TF2Attrib_GetByName(weapon, "damage bonus");
				new Address:dmgMult2 = TF2Attrib_GetByName(weapon, "bullets per shot bonus");
				new Address:dmgMult3 = TF2Attrib_GetByName(weapon, "damage bonus HIDDEN");
				new Address:dmgMult4 = TF2Attrib_GetByName(weapon, "damage penalty");
				damage = 10.0;
				if(dmgMult1 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(dmgMult1);
				}
				if(dmgMult2 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(dmgMult2);
				}	
				if(dmgMult3 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(dmgMult3);
				}	
				if(dmgMult4 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(dmgMult4);
				}	
			}
			if(damagecustom == TF_CUSTOM_BASEBALL && IsValidClient3(victim))
			{
				new Address:dmgMult1 = TF2Attrib_GetByName(weapon, "damage bonus");
				new Address:dmgMult2 = TF2Attrib_GetByName(weapon, "damage bonus HIDDEN");
				new Address:dmgMult3 = TF2Attrib_GetByName(weapon, "damage penalty");
				new Address:dmgAdd = TF2Attrib_GetByName(weapon, "has pipboy build interface");
				damage = 45.0;
				if(dmgAdd != Address_Null)
				{
					damage += TF2Attrib_GetValue(dmgAdd);
				}
				if(dmgMult1 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(dmgMult1);
				}
				if(dmgMult2 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(dmgMult2);
				}	
				if(dmgMult3 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(dmgMult3);
				}
			}
			new Address:DealsNoKBActive = TF2Attrib_GetByName(weapon, "apply z velocity on damage");
			if(DealsNoKBActive != Address_Null)
			{
				if(TF2Attrib_GetValue(DealsNoKBActive) == 3.0)
				{
					damagetype |= DMG_PREVENT_PHYSICS_FORCE;
				}
			}
			new Address:damageActive = TF2Attrib_GetByName(weapon, "ubercharge");
			if(damageActive != Address_Null)
			{
				damage *= Pow(TF2Attrib_GetValue(damageActive), 5.0);
			}
			if(TF2_IsPlayerInCondition(attacker, TFCond_RunePrecision))
			{
				damage *= 2.0;
			}
			if(damagetype & DMG_CLUB)
			{
				new Address:multiHitActive = TF2Attrib_GetByName(weapon, "taunt move acceleration time");
				if(multiHitActive != Address_Null)
				{
					DOTStock(victim,attacker,damage,weapon,damagetype + DMG_VEHICLE,RoundToNearest(TF2Attrib_GetValue(multiHitActive)),0.4,0.15,true);
				}
			}
			new Address:bouncingBullets = TF2Attrib_GetByName(weapon, "flame size penalty");
			if(bouncingBullets != Address_Null && LastCharge[attacker] >= 150.0)
			{
				new Float:DOTDmg = damage;
				new Address:damageVsPlayersActive = TF2Attrib_GetByName(weapon, "dmg penalty vs players");
				if(damageVsPlayersActive != Address_Null)
				{
					DOTDmg *= TF2Attrib_GetValue(damageVsPlayersActive);
				}
				//PrintToChat(attacker, "%s dmg", GetAlphabetForm(DOTDmg));
				new bool:isBounced[MAXPLAYERS+1];
				isBounced[victim] = true
				new lastBouncedTarget = victim;
				new Float:lastBouncedPosition[3];
				GetClientEyePosition(lastBouncedTarget, lastBouncedPosition)
				LastCharge[attacker] = 0.0;
				new i = 0
				new maxBounces = RoundToNearest(TF2Attrib_GetValue(bouncingBullets));
				for(new client=1;client<MaxClients;client++)
				{
					if(IsValidClient3(client) && IsPlayerAlive(client) && IsOnDifferentTeams(client,attacker) && isBounced[client] == false && i < maxBounces)
					{
						new Float:VictimPos[3]; 
						GetClientEyePosition(client, VictimPos); 
						new Float:distance = GetVectorDistance(lastBouncedPosition, VictimPos);
						if(distance <= 350.0)
						{
							isBounced[client] = true;
							GetClientEyePosition(lastBouncedTarget, lastBouncedPosition)
							lastBouncedTarget = client
							new iParti = CreateEntityByName("info_particle_system");
							new iPart2 = CreateEntityByName("info_particle_system");

							if (IsValidEntity(iParti) && IsValidEntity(iPart2))
							{ 
								decl String:szCtrlParti[32];
								new String:particleName[32];
								if(GetClientTeam(attacker) == 2)
								{
									particleName = "dxhr_sniper_rail_red"
								}
								else
								{
									particleName = "dxhr_sniper_rail_blue"
								}
								Format(szCtrlParti, sizeof(szCtrlParti), "tf2ctrlpart%i", iPart2);
								DispatchKeyValue(iPart2, "targetname", szCtrlParti);

								DispatchKeyValue(iParti, "effect_name", particleName);
								DispatchKeyValue(iParti, "cpoint1", szCtrlParti);
								DispatchSpawn(iParti);
								TeleportEntity(iParti, lastBouncedPosition, NULL_VECTOR, NULL_VECTOR);
								TeleportEntity(iPart2, VictimPos, NULL_VECTOR, NULL_VECTOR);
								ActivateEntity(iParti);
								AcceptEntityInput(iParti, "Start");
								
								new Handle:pack;
								CreateDataTimer(1.0, Timer_KillParticle, pack);
								WritePackCell(pack, iParti);
								new Handle:pack2;
								CreateDataTimer(1.0, Timer_KillParticle, pack2);
								WritePackCell(pack2, iPart2);
							}
							SDKHooks_TakeDamage(client,attacker,attacker,DOTDmg,damagetype,-1,NULL_VECTOR,NULL_VECTOR)
							i++
						}
					}
				}
			}
			new Address:supernovaPowerup = TF2Attrib_GetByName(attacker, "spawn with physics toy");
			if(supernovaPowerup != Address_Null)
			{
				new Float:supernovaPowerupValue = TF2Attrib_GetValue(supernovaPowerup);
				if(supernovaPowerupValue > 0.0){
					if(StrEqual(getDamageCategory(damagetype),"blast",false))
					{
						damage *= 1.8;
					}
					else
					{
						damage *= 1.35;
						new Float:victimPosition[3];
						GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", victimPosition); 
						
						EntityExplosion(attacker, damage, 300.0,victimPosition,_,weaponArtParticle[attacker] <= 0.0 ? true : false, victim,_,_,weapon, 0.5, 70);
						//PARTICLES
						if(weaponArtParticle[attacker] <= 0.0)
						{
							new iParti = CreateEntityByName("info_particle_system");
							new iPart2 = CreateEntityByName("info_particle_system");

							if (IsValidEntity(iParti) && IsValidEntity(iPart2))
							{
								decl String:particleName[32];
								if(GetClientTeam(attacker) == 2)
								{
									particleName = "powerup_supernova_strike_red";
								}
								else
								{
									particleName = "powerup_supernova_strike_blue";
								}
								
								new Float:clientPos[3], Float:clientAng[3];
								GetClientEyePosition(attacker, clientPos);
								GetClientEyeAngles(attacker,clientAng);
								
								decl String:szCtrlParti[32];
								Format(szCtrlParti, sizeof(szCtrlParti), "tf2ctrlpart%i", iPart2);
								DispatchKeyValue(iPart2, "targetname", szCtrlParti);
								DispatchKeyValue(iParti, "effect_name", particleName);
								DispatchKeyValue(iParti, "cpoint1", szCtrlParti);
								DispatchSpawn(iParti);
								TeleportEntity(iParti, clientPos, clientAng, NULL_VECTOR);
								TeleportEntity(iPart2, victimPosition, NULL_VECTOR, NULL_VECTOR);
								ActivateEntity(iParti);
								AcceptEntityInput(iParti, "Start");
								
								new Handle:pack;
								CreateDataTimer(0.2, Timer_KillParticle, pack);
								WritePackCell(pack, EntIndexToEntRef(iParti));
								new Handle:pack2;
								CreateDataTimer(0.2, Timer_KillParticle, pack2);
								WritePackCell(pack2, EntRefToEntIndex(iPart2));
							}
							weaponArtParticle[attacker] = 1.0;
						}
					}
				}
			}
		}
	}
	lastDamageTaken[victim] = damage;
	if(damage < 0.0)
	{
		damage = 0.0;
	}

	return Plugin_Changed;
}
public Action:OnTakeDamagePre_Tank(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom) 
{
	if(IsValidEntity(victim) && IsValidClient3(attacker))
	{
		if(damagecustom == TF_CUSTOM_CANNONBALL_PUSH)
		{
			damage = TF2_GetDamageModifiers(attacker,weapon) * 50.0;
			new Address:lameMult = TF2Attrib_GetByName(weapon, "dmg penalty vs players");
			if(lameMult != Address_Null)//lame. AP applies twice.
			{
				damage /= TF2Attrib_GetValue(lameMult);
			}
			return Plugin_Changed;
		}
		if (!IsValidClient3(inflictor) && IsValidEdict(inflictor))
		{
			new String:classname[128]; 
			GetEdictClassname(inflictor, classname, sizeof(classname)); 
			new weaponIdx = ((IsValidEntity(weapon) && weapon > MaxClients && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			//PrintToChatAll("classname %s",classname);
			if ((!strcmp("obj_sentrygun", classname) || !strcmp("tf_projectile_sentryrocket", classname)) || weaponIdx == 140)
			{
				new owner; 
				if(!strcmp("tf_projectile_sentryrocket", classname))
				{
					owner = attacker;
				}
				else
				{
					owner = GetEntPropEnt(inflictor, Prop_Send, "m_hBuilder");
				}
				
				if(!IsValidClient3(owner))
				{
					if(IsValidForDamage(GetEntProp(inflictor, Prop_Send, "m_hBuiltOnEntity")))
					{
						owner = GetEntProp(inflictor, Prop_Send, "m_hBuiltOnEntity");
					}
				}
				if(IsValidForDamage(owner))
				{
					new String:Ownerclassname[128]; 
					GetEdictClassname(owner, Ownerclassname, sizeof(Ownerclassname)); 
					if(StrEqual(Ownerclassname, "tank_boss"))
					{
						damage *= TankSentryDamageMod;
						damagetype |= DMG_PREVENT_PHYSICS_FORCE;
					}
				}
				if(IsValidClient3(owner))
				{
					new melee = GetPlayerWeaponSlot(owner,2);
					if((GetEntPropFloat(inflictor, Prop_Send, "m_flModelScale") != 0.3))
					{
						damagetype |= DMG_PREVENT_PHYSICS_FORCE;
						
						if(IsValidEntity(melee))
						{
							new Address:sentryOverrideActive = TF2Attrib_GetByName(melee, "override projectile type");
							if(sentryOverrideActive != Address_Null)
							{
								new Float:sentryOverride = TF2Attrib_GetValue(sentryOverrideActive);
								switch(sentryOverride)
								{
									case 34.0:
									{
										if(damagetype & DMG_BULLET)
										{
											if(0.1 >= GetRandomFloat(0.0, 1.0))
											{
												new iEntity = CreateEntityByName("tf_projectile_cleaver");
												if (IsValidEdict(iEntity)) 
												{
													new iTeam = GetClientTeam(owner);
													new Float:fAngles[3]
													new Float:fOrigin[3]
													new Float:vBuffer[3]
													new Float:fVelocity[3]
													new Float:fwd[3]
													SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);
													SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
													new angleOffsetB = FindSendPropInfo("CObjectSentrygun", "m_iAmmoShells") - 16;
													GetEntPropVector( inflictor, Prop_Send, "m_vecOrigin", fOrigin );
													if(GetEntProp(inflictor, Prop_Send, "m_iUpgradeLevel") == 0)
													{
														fOrigin[2] += 30.0;
													}
													else if(GetEntProp(inflictor, Prop_Send, "m_bMiniBuilding") == 1)
													{
														fOrigin[2] += 25.0;
													}
													else
													{
														fOrigin[2] += 40.0;
													}
													
													GetEntDataVector( inflictor, angleOffsetB, fAngles );

													GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
													ScaleVector(fwd, 30.0);
													
													AddVectors(fOrigin, fwd, fOrigin);
													fAngles[0] -= 5.0;
													GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
													new Float:Speed[3];
													new bool:movementType = false;
													if(HasEntProp(iEntity, Prop_Data, "m_vecAbsVelocity"))
													{
														GetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", Speed);
														fVelocity[0] = vBuffer[0]*GetVectorLength(Speed);
														fVelocity[1] = vBuffer[1]*GetVectorLength(Speed);
														fVelocity[2] = vBuffer[2]*GetVectorLength(Speed);
														if(GetVectorLength(Speed) > 5.0)
														{
															movementType = true;
														}
													}
													if(movementType == false)
													{
														new Float:velocity = 2000.0;
														new Address:projspeed = TF2Attrib_GetByName(melee, "Projectile speed increased");
														new Address:projspeed1 = TF2Attrib_GetByName(melee, "Projectile speed decreased");
														if(projspeed != Address_Null){
															velocity *= TF2Attrib_GetValue(projspeed)
														}
														if(projspeed1 != Address_Null){
															velocity *= TF2Attrib_GetValue(projspeed1)
														}
														new Float:vecAngImpulse[3];
														GetCleaverAngularImpulse(vecAngImpulse);
														fVelocity[0] = vBuffer[0]*velocity;
														fVelocity[1] = vBuffer[1]*velocity;
														fVelocity[2] = vBuffer[2]*velocity;
														
														TeleportEntity(iEntity, fOrigin, fAngles, NULL_VECTOR);
														DispatchSpawn(iEntity);
														SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vecAngImpulse, owner, 0, 5.0);
													}
												}
											}
										}
									}
									case 33.0:
									{
										if(damagetype & DMG_BULLET)
										{
											if(firestormCounter[owner] >= 4)
											{
												new iEntity = CreateEntityByName("tf_projectile_spellfireball");
												if (IsValidEdict(iEntity)) 
												{
													new iTeam = GetClientTeam(owner);
													new Float:fAngles[3]
													new Float:fOrigin[3]
													new Float:vBuffer[3]
													new Float:fVelocity[3]
													new Float:fwd[3]
													SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);
													SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
													new angleOffsetB = FindSendPropInfo("CObjectSentrygun", "m_iAmmoShells") - 16;
													GetEntPropVector( inflictor, Prop_Send, "m_vecOrigin", fOrigin );
													if(GetEntProp(inflictor, Prop_Send, "m_iUpgradeLevel") == 0)
													{
														fOrigin[2] += 30.0;
													}
													else if(GetEntProp(inflictor, Prop_Send, "m_bMiniBuilding") == 1)
													{
														fOrigin[2] += 25.0;
													}
													else
													{
														fOrigin[2] += 40.0;
													}
													
													GetEntDataVector( inflictor, angleOffsetB, fAngles );

													GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
													ScaleVector(fwd, 30.0);
													
													AddVectors(fOrigin, fwd, fOrigin);
													GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
													new Float:Speed[3];
													new bool:movementType = false;
													if(HasEntProp(iEntity, Prop_Data, "m_vecAbsVelocity"))
													{
														GetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", Speed);
														fVelocity[0] = vBuffer[0]*GetVectorLength(Speed);
														fVelocity[1] = vBuffer[1]*GetVectorLength(Speed);
														fVelocity[2] = vBuffer[2]*GetVectorLength(Speed);
														if(GetVectorLength(Speed) > 5.0)
														{
															movementType = true;
														}
													}
													if(movementType == false)
													{
														new Float:velocity = 11000.0;
														new Float:vecAngImpulse[3];
														GetCleaverAngularImpulse(vecAngImpulse);
														fVelocity[0] = vBuffer[0]*velocity;
														fVelocity[1] = vBuffer[1]*velocity;
														fVelocity[2] = vBuffer[2]*velocity;
														
														TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
														DispatchSpawn(iEntity);
														//SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vecAngImpulse, owner, 0, 5.0);
													}
												}
												firestormCounter[owner] = 0;
											}
											else
											{
												firestormCounter[owner]++
											}
											damage = 0.0;
										}
									}
									case 32.0:
									{
										if(damagetype & DMG_BULLET)
										{
											if(0.025 >= GetRandomFloat(0.0, 1.0))
											{
												new iEntity = CreateEntityByName("tf_projectile_spellmeteorshower");
												if (IsValidEdict(iEntity)) 
												{
													new iTeam = GetClientTeam(owner);
													new Float:fAngles[3]
													new Float:fOrigin[3]
													new Float:vBuffer[3]
													new Float:fVelocity[3]
													SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);
													SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
													new angleOffsetB = FindSendPropInfo("CObjectSentrygun", "m_iAmmoShells") - 16;
													GetEntPropVector( inflictor, Prop_Send, "m_vecOrigin", fOrigin );
													if(GetEntProp(inflictor, Prop_Send, "m_iUpgradeLevel") == 0)
													{
														fOrigin[2] += 30.0;
													}
													else if(GetEntProp(inflictor, Prop_Send, "m_bMiniBuilding") == 1)
													{
														fOrigin[2] += 25.0;
													}
													else
													{
														fOrigin[2] += 40.0;
													}
													GetEntDataVector( inflictor, angleOffsetB, fAngles );
													fAngles[0] -= 5.0;
													GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
													new Float:Speed[3];
													new bool:movementType = false;
													if(HasEntProp(iEntity, Prop_Data, "m_vecAbsVelocity"))
													{
														GetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", Speed);
														fVelocity[0] = vBuffer[0]*GetVectorLength(Speed);
														fVelocity[1] = vBuffer[1]*GetVectorLength(Speed);
														fVelocity[2] = vBuffer[2]*GetVectorLength(Speed);
														if(GetVectorLength(Speed) > 5.0)
														{
															movementType = true;
														}
													}
													if(movementType == false)
													{
														new Float:velocity = 2000.0;
														new Address:projspeed = TF2Attrib_GetByName(melee, "Projectile speed increased");
														new Address:projspeed1 = TF2Attrib_GetByName(melee, "Projectile speed decreased");
														if(projspeed != Address_Null){
															velocity *= TF2Attrib_GetValue(projspeed)
														}
														if(projspeed1 != Address_Null){
															velocity *= TF2Attrib_GetValue(projspeed1)
														}
														new Float:vecAngImpulse[3];
														GetCleaverAngularImpulse(vecAngImpulse);
														fVelocity[0] = vBuffer[0]*velocity;
														fVelocity[1] = vBuffer[1]*velocity;
														fVelocity[2] = vBuffer[2]*velocity;
														
														TeleportEntity(iEntity, fOrigin, fAngles, NULL_VECTOR);
														DispatchSpawn(iEntity);
														SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vecAngImpulse, owner, 0, 5.0);
													}
												}
											}
										}
									}
								}
							}
						}
					}
					new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
					if(IsValidEntity(CWeapon))
					{
						new Address:SentryDmgActive = TF2Attrib_GetByName(CWeapon, "ring of fire while aiming");
						if(SentryDmgActive != Address_Null)
						{
							damage *= TF2Attrib_GetValue(SentryDmgActive);
						}
					}
					if(IsValidEntity(melee))
					{
						new Address:SentryDmgActive1 = TF2Attrib_GetByName(melee, "throwable detonation time");
						if(SentryDmgActive1 != Address_Null)
						{
							damage *= TF2Attrib_GetValue(SentryDmgActive1);
						}
						new Address:SentryDmgActive2 = TF2Attrib_GetByName(melee, "throwable fire speed");
						if(SentryDmgActive2 != Address_Null)
						{
							damage *= TF2Attrib_GetValue(SentryDmgActive2);
						}
						new Address:damageActive = TF2Attrib_GetByName(melee, "ubercharge");
						if(damageActive != Address_Null)
						{
							damage *= Pow(TF2Attrib_GetValue(damageActive), 5.0);
						}
					}
					if((!strcmp("obj_sentrygun", classname) && GetEntProp(inflictor, Prop_Send, "m_bMiniBuilding") == 1))
					{
						damage *= 1.5
					}
				}
			}
			if(IsValidClient3(attacker) && TF2_GetPlayerClass(attacker) == TFClass_Engineer)
			{
				if(!strcmp("tf_projectile_spellfireball", classname))
				{
					new primary = GetPlayerWeaponSlot(attacker,0)
					new melee = GetPlayerWeaponSlot(attacker,2)
					if(IsValidEntity(melee))
					{
						new Address:sentryOverrideActive = TF2Attrib_GetByName(melee, "override projectile type");
						if(sentryOverrideActive != Address_Null)
						{
							new Float:sentryOverride = TF2Attrib_GetValue(sentryOverrideActive);
							if(sentryOverride == 32.0)
							{
								damage = 20.0;
								damagetype |= DMG_PREVENT_PHYSICS_FORCE;
							}
							else if(sentryOverride == 33.0)
							{
								damage = 60.0;
								damagetype |= DMG_PREVENT_PHYSICS_FORCE;
							}
						}
						
						
						new Address:SentryDmgActive = TF2Attrib_GetByName(melee, "engy sentry damage bonus");
						new Address:SentryDmgActive1 = TF2Attrib_GetByName(melee, "throwable detonation time");
						new Address:SentryDmgActive2 = TF2Attrib_GetByName(melee, "throwable fire speed");
						if(SentryDmgActive != Address_Null)
						{
							damage *= TF2Attrib_GetValue(SentryDmgActive);
						}
						if(SentryDmgActive1 != Address_Null)
						{
							damage *= TF2Attrib_GetValue(SentryDmgActive1);
						}
						if(SentryDmgActive2 != Address_Null)
						{
							damage *= TF2Attrib_GetValue(SentryDmgActive2);
						}
						new Address:damageActive = TF2Attrib_GetByName(melee, "ubercharge");
						if(damageActive != Address_Null)
						{
							damage *= Pow(TF2Attrib_GetValue(damageActive), 5.0);
						}
					}
					if(IsValidEntity(primary))
					{
						new Address:SentryDmgActive2 = TF2Attrib_GetByName(primary, "engy sentry damage bonus");
						if(SentryDmgActive2 != Address_Null)
						{
							damage *= TF2Attrib_GetValue(SentryDmgActive2);
						}
					}
					new CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
					if(IsValidEntity(CWeapon))
					{
						new Address:SentryDmgActive = TF2Attrib_GetByName(CWeapon, "ring of fire while aiming");
						if(SentryDmgActive != Address_Null)
						{
							damage *= TF2Attrib_GetValue(SentryDmgActive);
						}
					}
				}
			}
		}
		if(IsFakeClient(attacker) && TF2Spawn_IsClientInSpawn(attacker))
		{
			damage *= 0.0;
			return Plugin_Changed;
		}
		if(damagetype == 4 && damagecustom == 3 && TF2_GetPlayerClass(attacker) == TFClass_Pyro)
		{
			new secondary = GetWeapon(attacker,1);
			if(IsValidEntity(secondary) && weapon == secondary)
			{
				new Address:gasExplosionDamage = TF2Attrib_GetByName(weapon, "clip size bonus");
				if(gasExplosionDamage != Address_Null)
				{
					damage *= TF2Attrib_GetValue(gasExplosionDamage);
				}
			}
		}
		if(TF2_IsPlayerInCondition(attacker, TFCond_DisguiseRemoved))
		{
			damage *= 1.8;
		}
		if(IsValidEntity(weapon))
		{	
			new Address:strengthPowerup = TF2Attrib_GetByName(attacker, "crit kill will gib");
			if(strengthPowerup != Address_Null)
			{
				new Float:strengthPowerupValue = TF2Attrib_GetValue(strengthPowerup);
				if(strengthPowerupValue > 0.0){
					damagetype |= DMG_NOCLOSEDISTANCEMOD;
					damage *= 2.0;
				}
			}
			
			new Address:knockoutPowerup = TF2Attrib_GetByName(attacker, "taunt is press and hold");
			if(knockoutPowerup != Address_Null)
			{
				new Float:knockoutPowerupValue = TF2Attrib_GetValue(knockoutPowerup);
				if(knockoutPowerupValue > 0.0){
					if(_:TF2II_GetListedItemSlot(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"),TF2_GetPlayerClass(attacker)) == 2)
					{
						damage *= 1.5;
					}
				}
			}
			
			new Address:revengePowerup = TF2Attrib_GetByName(attacker, "sniper penetrate players when charged");
			if(revengePowerup != Address_Null)
			{
				if(RageActive[attacker] == true && TF2Attrib_GetValue(revengePowerup) > 0.0)
				{
					damagetype |= DMG_RADIUS_MAX;
					damage *= 1.75;
				}
			}
			
			new Address:precisionPowerup = TF2Attrib_GetByName(attacker, "refill_ammo");
			if(precisionPowerup != Address_Null)
			{
				new Float:precisionPowerupValue = TF2Attrib_GetValue(precisionPowerup);
				if(precisionPowerupValue > 0.0){
					damagetype |= DMG_RADIUS_MAX;
					damage *= 1.2;
				}
			}
			
			new clientTeam = GetClientTeam(attacker);
			new Float:clientPos[3];
			GetEntPropVector(attacker, Prop_Data, "m_vecOrigin", clientPos);
			new Float:highestKingDMG = 1.0;
			for(new i = 1;i<MaxClients;i++)
			{
				if(IsValidClient3(i) && IsPlayerAlive(i))
				{
					new iTeam = GetClientTeam(i);
					if(clientTeam == iTeam)
					{
						new Float:VictimPos[3];
						GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
						VictimPos[2] += 30.0;
						new Float:Distance = GetVectorDistance(clientPos,VictimPos);
						if(Distance <= 600.0)
						{
							new Address:kingPowerup = TF2Attrib_GetByName(i, "attack projectiles");
							if(kingPowerup != Address_Null && TF2Attrib_GetValue(kingPowerup) > 0.0)
							{
								highestKingDMG = 1.2;
								break;
							}
						}
					}
				}
			}
			if(highestKingDMG > 1.0)
			{
				damage *= highestKingDMG;
			}
			
			new Address:rageOnHit = TF2Attrib_GetByName(weapon, "mod rage on hit bonus");
			if(rageOnHit != Address_Null)
			{
				if(GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter") < 150.0)
				{
					SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter") + TF2Attrib_GetValue(rageOnHit))
				}
				//PrintToChat(attacker, "%.2f Rage",  GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter"))
			}
			new hitgroup = GetEntProp(victim, Prop_Data, "m_LastHitGroup");
			if(hitgroup == 1 || damagecustom == 1)
			{
				new Address:HeadshotsActive = TF2Attrib_GetByName(weapon, "charge time decreased");
				if(HeadshotsActive != Address_Null)
				{
					critStatus[victim] = true;
					damagecustom = 1;
					damage *= TF2Attrib_GetValue(HeadshotsActive);
				}
				//Fix The Classic's "Cannot Headshot Without Full Charge" while not scoped.
				new Address:classicDebuff = TF2Attrib_GetByName(weapon, "sniper no headshot without full charge");
				{
					if(classicDebuff != Address_Null && TF2Attrib_GetValue(classicDebuff) == 0.0 && !TF2_IsPlayerInCondition(attacker, TFCond_Zoomed))
					{
						damagetype |= DMG_CRIT;
						damagecustom = 1;
					}
				}
				if(precisionPowerup != Address_Null)
				{
					new Float:precisionPowerupValue = TF2Attrib_GetValue(precisionPowerup);
					if(precisionPowerupValue > 0.0){
						miniCritStatus[victim] = true;
						damage *= precisionPowerupValue * 1.35;
						damagecustom = 1;
					}
				}
			}
			if(TF2_GetPlayerClass(attacker) == TFClass_Medic)
			{
				new String:classname[128]; 
				GetEdictClassname(weapon, classname, sizeof(classname)); 
				if(weapon == GetPlayerWeaponSlot(attacker,0) && StrContains(classname, "crossbow") == -1)
				{
					damagetype |= DMG_ENERGYBEAM;
					damage *= 1.8;
				}
			}
			new Address:dmgBoost = TF2Attrib_GetByName(weapon, "mod demo buff type");
			if(dmgBoost != Address_Null)
			{
				damage *= TF2Attrib_GetValue(dmgBoost);
			}
			new Float:medicDMGBonus = 1.0;
			new healers = GetEntProp(attacker, Prop_Send, "m_nNumHealers");
			if(healers > 0)
			{
				for (new i = 1; i < MaxClients; i++)
				{
					if (IsValidClient(i))
					{
						new healerweapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
						if(IsValidEntity(healerweapon))
						{
							if(HasEntProp(healerweapon, Prop_Send, "m_hHealingTarget") && GetEntPropEnt(healerweapon, Prop_Send, "m_hHealingTarget") == attacker)
							{
								if(IsValidEntity(healerweapon))
								{
									new Address:dmgActive = TF2Attrib_GetByName(healerweapon, "hidden secondary max ammo penalty");
									if(dmgActive != Address_Null)
									{
										medicDMGBonus += TF2Attrib_GetValue(dmgActive);
									}
								}
							}
						}
					}
				}
			}
			damage *= medicDMGBonus;
			new Address:SniperChargingFactorActive = TF2Attrib_GetByName(weapon, "no charge impact range");
			if(SniperChargingFactorActive != Address_Null)
			{
				if(LastCharge[attacker] > 50.0)
				{
					damage *= TF2Attrib_GetValue(SniperChargingFactorActive);
				}
			}
			new Address:CleaverdamageActive = TF2Attrib_GetByName(weapon, "disguise damage reduction");
			if(CleaverdamageActive != Address_Null)
			{
				damage *= TF2Attrib_GetValue(CleaverdamageActive);
			}
			new Address:damageModifierActive = TF2Attrib_GetByName(weapon, "throwable healing");
			if(damageModifierActive != Address_Null)
			{
				damage *= TF2Attrib_GetValue(damageModifierActive);
			}
			new Address:damageModifierActive2 = TF2Attrib_GetByName(weapon, "taunt is highfive");
			if(damageModifierActive2 != Address_Null)
			{
				damage *= TF2Attrib_GetValue(damageModifierActive2);
			}
			new Address:HiddenDamageActive = TF2Attrib_GetByName(weapon, "throwable damage");
			if(HiddenDamageActive != Address_Null)
			{
				damage *= TF2Attrib_GetValue(HiddenDamageActive);
			}
			new Address:expodamageActive = TF2Attrib_GetByName(weapon, "taunt turn speed");
			if(expodamageActive != Address_Null)
			{
				damage *= Pow(TF2Attrib_GetValue(expodamageActive), 6.0);
			}
			new Address:HeadshotDamage = TF2Attrib_GetByName(weapon, "overheal penalty");
			if(HeadshotDamage != Address_Null && damagecustom == 1)
			{
				damage *= TF2Attrib_GetValue(HeadshotDamage);
			}

			new Address:overrideproj = TF2Attrib_GetByName(weapon, "override projectile type");
			new Address:energyWeapActive = TF2Attrib_GetByName(weapon, "energy weapon penetration");
			if(overrideproj != Address_Null)
			{
				new Float:override = TF2Attrib_GetValue(overrideproj);
				if((override > 1.0 && override <= 2.0) || (override > 5.0 && override <= 6.0))
				{
					new Address:bulletspershot = TF2Attrib_GetByName(weapon, "bullets per shot bonus");
					new Address:bulletspershotBody = TF2Attrib_GetByName(attacker, "bullets per shot bonus");
					new Address:accscales = TF2Attrib_GetByName(weapon, "accuracy scales damage");

					if(accscales != Address_Null)
					{
						damage *= Pow(TF2Attrib_GetValue(accscales),0.95);
					}
					if(bulletspershot != Address_Null)
					{
						damage *= Pow(TF2Attrib_GetValue(bulletspershot), 0.9)
					}
					if(bulletspershotBody != Address_Null)
					{
						damage *= Pow(TF2Attrib_GetValue(bulletspershotBody), 0.9)
					}
				}
				if(override == 31)
				{
					new Address:DamageBonusHidden = TF2Attrib_GetByName(weapon, "damage bonus HIDDEN");
					new Address:DamagePenalty = TF2Attrib_GetByName(weapon, "damage penalty");
					new Address:DamageBonus = TF2Attrib_GetByName(weapon, "damage bonus");
					new Address:bulletspershot = TF2Attrib_GetByName(weapon, "bullets per shot bonus");
					new Address:accscales = TF2Attrib_GetByName(weapon, "accuracy scales damage");
					
					if(DamageBonusHidden != Address_Null)
					{
						damage *= TF2Attrib_GetValue(DamageBonusHidden);
					}
					if(DamagePenalty != Address_Null)
					{
						damage *= TF2Attrib_GetValue(DamagePenalty);
					}
					if(DamageBonus != Address_Null)
					{
						damage *= TF2Attrib_GetValue(DamageBonus);
					}
					if(accscales != Address_Null)
					{
						damage *= Pow(TF2Attrib_GetValue(accscales),0.95);
					}
					if(bulletspershot != Address_Null)
					{
						damage *= Pow(TF2Attrib_GetValue(bulletspershot), 0.9)
					}
				}
			}
			if(energyWeapActive != Address_Null && TF2Attrib_GetValue(energyWeapActive) != 0.0)
			{
				new Address:bulletspershot = TF2Attrib_GetByName(weapon, "bullets per shot bonus");
				new Address:accscales = TF2Attrib_GetByName(weapon, "accuracy scales damage");
				if(accscales != Address_Null)
				{
					damage *= Pow(TF2Attrib_GetValue(accscales),0.95);
				}
				if(bulletspershot != Address_Null)
				{
					damage *= Pow(TF2Attrib_GetValue(bulletspershot), 0.9)
				}
			}
			if(damagecustom == TF_CUSTOM_PLASMA_CHARGED)
			{
				PrintToConsole(attacker, "Full charge hit!");
				new Address:clipActive = TF2Attrib_GetByName(weapon, "clip size bonus upgrade");
				if(clipActive != Address_Null)
				{
					damage *= Pow(TF2Attrib_GetValue(clipActive)+1.0, 0.9);
				}
				damagetype |= DMG_CRIT;
			}
			if (damagecustom == 46 && damagetype & DMG_SHOCK && IsValidClient3(victim))
			{
				new Address:dmgMult1 = TF2Attrib_GetByName(weapon, "damage bonus");
				new Address:dmgMult2 = TF2Attrib_GetByName(weapon, "bullets per shot bonus");
				new Address:dmgMult3 = TF2Attrib_GetByName(weapon, "damage bonus HIDDEN");
				new Address:dmgMult4 = TF2Attrib_GetByName(weapon, "damage penalty");
				damage = 10.0;
				if(dmgMult1 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(dmgMult1);
				}
				if(dmgMult2 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(dmgMult2);
				}	
				if(dmgMult3 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(dmgMult3);
				}	
				if(dmgMult4 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(dmgMult4);
				}	
			}
			if(damagecustom == TF_CUSTOM_BASEBALL && IsValidClient3(victim))
			{
				new Address:dmgMult1 = TF2Attrib_GetByName(weapon, "damage bonus");
				new Address:dmgMult2 = TF2Attrib_GetByName(weapon, "damage bonus HIDDEN");
				new Address:dmgMult3 = TF2Attrib_GetByName(weapon, "damage penalty");
				new Address:dmgAdd = TF2Attrib_GetByName(weapon, "has pipboy build interface");
				damage = 45.0;
				if(dmgAdd != Address_Null)
				{
					damage += TF2Attrib_GetValue(dmgAdd);
				}
				if(dmgMult1 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(dmgMult1);
				}
				if(dmgMult2 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(dmgMult2);
				}	
				if(dmgMult3 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(dmgMult3);
				}
			}
			new Address:damageActive = TF2Attrib_GetByName(weapon, "ubercharge");
			if(damageActive != Address_Null)
			{
				damage *= Pow(TF2Attrib_GetValue(damageActive), 5.0);
			}
			if(TF2_IsPlayerInCondition(attacker, TFCond_RunePrecision))
			{
				damage *= 2.0;
			}
			if(damagetype & DMG_CLUB)
			{
				new Address:multiHitActive = TF2Attrib_GetByName(weapon, "taunt move acceleration time");
				if(multiHitActive != Address_Null)
				{
					DOTStock(victim,attacker,damage,weapon,damagetype + DMG_VEHICLE,RoundToNearest(TF2Attrib_GetValue(multiHitActive)),0.4,0.15,true);
				}
			}
			new Address:supernovaPowerup = TF2Attrib_GetByName(attacker, "spawn with physics toy");
			if(supernovaPowerup != Address_Null)
			{
				new Float:supernovaPowerupValue = TF2Attrib_GetValue(supernovaPowerup);
				if(supernovaPowerupValue > 0.0){
					damage *= 2.0;
				}
			}
		}
	}
	if(damage < 0.0)
	{
		damage = 0.0;
	}
	if(IsValidEntity(logic))
	{
		new round = GetEntProp(logic, Prop_Send, "m_nMannVsMachineWaveCount");
		new Float:currency = 60000.0;
		for(new i = 1;i<round;i++)
		{
			currency += (currency*0.2)+20000.0;
		}
		damage *= (Pow(7500.0/currency, DefenseMod + (DefenseIncreasePerWaveMod * round)) * 6.0)/OverallMod;
		//PrintToChat(attacker,"%.2f", damage);
	}
	return Plugin_Changed;
}
public Action:removeBulletsPerShot(Handle:timer, int client) 
{  
    if(IsValidClient3(client)) 
    { 
		TF2Attrib_SetByName(client, "bullets per shot bonus", 1.0);
		refreshAllWeapons(client);
		StunShotStun[client] = false;
		StunShotBPS[client] = false;
    }
}
/*printATKSPD(client)
{
	new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEntity(CWeapon))
	{
		new Float:m_flNextPrimaryAttack = GetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack");
		if(GetGameTime() - m_flNextPrimaryAttack < 0.0 || GetGameTime() - m_flNextPrimaryAttack <= GetTickInterval())
		{
			m_flNextPrimaryAttack = GetGameTime();
		}
		m_flNextPrimaryAttack += 0.111;
		SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", m_flNextPrimaryAttack);
		PrintToServer("%.2fs next attack", m_flNextPrimaryAttack - GetGameTime());
	}
}*/
public Action:AttackTwice(Handle:timer, any:data) 
{  
	ResetPack(data);
	new client = EntRefToEntIndex(ReadPackCell(data));
	new CWeapon = EntRefToEntIndex(ReadPackCell(data));
	new timesLeft = ReadPackCell(data);
	if(IsValidClient3(client) && IsValidEntity(CWeapon))
	{
		timesLeft--;
		shouldAttack[client] = true;
		SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
		
		if(timesLeft > 0)
		{
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack, EntIndexToEntRef(client));
			WritePackCell(hPack, EntIndexToEntRef(CWeapon));
			WritePackCell(hPack, timesLeft);
			CreateTimer(0.1,AttackTwice,hPack);
		}
	}
	else
	{
		KillTimer(timer)
	}
	CloseHandle(data);
}
public MRESReturn OnMyWeaponFired(int client, Handle hReturn, Handle hParams)
{
	if(!IsValidClient3(client) || !IsValidEntity(client))
		return MRES_Ignored;
	if(IsValidClient3(client))
	{
		float punch[3] = {0.01, 0.0, 0.0};
		//float punchVel[3] = {-0.05,0.0,0.0};
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", punch);	
		//SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", punchVel);
		canShootAgain[client] = true;
		new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(CWeapon))
		{
			/*if(!IsFakeClient(client))
			{
				new iEntity = CreateEntityByName("tf_projectile_arrow");
				if (IsValidEdict(iEntity)) 
				{
					new Float:fAngles[3],Float:fTempAngles[3];
					new Float:fOrigin[3]
					new Float:vBuffer[3]
					new Float:fVelocity[3]
					new Float:fwd[3]
					new Float:vRight[3]
					new Float:vUp[3]
					new iTeam = GetClientTeam(client);
					SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
					SetEntityRenderColor(iEntity, 0, 0, 0, 0);
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
					SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
					SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
					SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 4);
					SetEntProp(iEntity, Prop_Data, "m_nSolidType", 0);
					SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 6);
								
					GetClientEyePosition(client, fOrigin);
					GetClientEyeAngles(client,fAngles);
					GetAngleVectors(fAngles,fwd, vRight, vUp);
					switch(GetRandomInt(0,0))
					{
						case 0:
						{
							ScaleVector(fwd, 300.0);
							ScaleVector(vUp, -200.0);
							ScaleVector(vRight, -300.0);
							fTempAngles[0] = fAngles[0]-20.0;
							fTempAngles[1] = fAngles[1]-40.0;
							GetAngleVectors(fTempAngles,vBuffer, NULL_VECTOR, NULL_VECTOR);
							isProjectileSlash[iEntity][0] = -4.0;
							isProjectileSlash[iEntity][1] = -4.0;
						}
					}
					AddVectors(fOrigin, fwd, fOrigin);
					AddVectors(fOrigin, vRight, fOrigin);
					AddVectors(fOrigin, vUp, fOrigin);
					new Float:Speed = 4000.0;
					fVelocity[0] = vBuffer[0]*Speed;
					fVelocity[1] = vBuffer[1]*Speed;
					fVelocity[2] = vBuffer[2]*Speed;
					SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
					SetEntityMoveType(iEntity, MOVETYPE_NOCLIP);
					DispatchSpawn(iEntity);
					TeleportEntity(iEntity, fOrigin, fTempAngles, fVelocity);
					CreateTimer(0.01, HomingFlareThink, EntIndexToEntRef(iEntity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(0.325, SelfDestruct, EntIndexToEntRef(iEntity));
					
					TE_SetupKillPlayerAttachments(iEntity);
					TE_SendToAll();
					new color[4]={255, 255, 255,225};
					TE_SetupBeamFollow(iEntity,Laser,0,0.3,4.0,8.0,1,color);
					TE_SendToAll();
				}
			}*/
			//RequestFrame(printATKSPD, client);
			//new melee = GetWeapon(client,2);
			meleeLimiter[client]++;
			/*
			if(melee == CWeapon && meleeLimiter[client] >= 2)
			{
				meleeLimiter[client] = 0;
				
				new Float:Range = 80.0;
				new Float:Radius = 10.0;
				new Float:damage = 65.0;
				
				if(TF2_GetPlayerClass(client) == TFClass_Scout)
				{
					Range = 60.0;
					damage = 35.0;
				}
				if(TF2_GetPlayerClass(client) == TFClass_Spy)
				{
					Range = 60.0;
					damage = 40.0;
				}				
				new Address:rangeMult = TF2Attrib_GetByName(CWeapon, "melee range multiplier");
				if(rangeMult != Address_Null)
				{
					Range *= TF2Attrib_GetValue(rangeMult);
				}
				
				new Address:radiusMult = TF2Attrib_GetByName(CWeapon, "melee bounds multiplier");
				if(radiusMult != Address_Null)
				{
					Radius *= TF2Attrib_GetValue(radiusMult);
				}
				
				new Address:swordActive = TF2Attrib_GetByName(CWeapon, "is_a_sword");
				if(swordActive != Address_Null)
				{
					if(TF2Attrib_GetValue(swordActive) != 0.0)
					{
						Range *= 1.2;
						Radius *= 1.2;
					}
				}
				new Float:ClientPos[3];
				new Float:ClientAngle[3];
				GetClientEyePosition(client,ClientPos);
				GetClientEyeAngles(client,ClientAngle);
				
				new Float:EndPos[3];
				MoveForward(ClientPos,ClientAngle, EndPos, Range);
				//PrintToChat(client, "%.2f 0 | %.2f 1 | %.2f 2", EndPos[0],EndPos[1],EndPos[2]);
				
				new Float:min[3];
				new Float:max[3];
				
				for (new i=0; i<sizeof(min); i++)
				{
					min[i] -= 7.0 + Radius;
					max[i] += 7.0 + Radius;
				}
				
				TR_TraceHullFilter(ClientPos,EndPos,min,max,MASK_SOLID,TraceEntityFilterPlayer,client);
				if(TR_DidHit())
				{
					new victim = TR_GetEntityIndex();
					if(IsValidClient3(victim) && GetClientTeam(client) != GetClientTeam(victim))
					{
						new Address:lameMult = TF2Attrib_GetByName(melee, "dmg penalty vs players");
						if(lameMult != Address_Null)
						{
							damage /= TF2Attrib_GetValue(lameMult);
						}//It calculates armor piercing damage twice.
						SDKHooks_TakeDamage(victim, client, client, TF2_GetDamageModifiers(client,CWeapon)*damage, DMG_CLUB, melee, NULL_VECTOR, NULL_VECTOR);
					}
					else
					{
						for(victim = 1;victim<MaxClients;victim++)
						{
							if(IsValidClient3(victim) && GetClientTeam(client) != GetClientTeam(victim) && GetPlayerDistance(client,victim) <= 50.0)
							{
								new Address:lameMult = TF2Attrib_GetByName(melee, "dmg penalty vs players");
								if(lameMult != Address_Null)
								{
									damage /= TF2Attrib_GetValue(lameMult);
								}//It calculates armor piercing damage twice.
								SDKHooks_TakeDamage(victim, client, client, TF2_GetDamageModifiers(client,CWeapon)*damage, DMG_CLUB, melee, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
			*/
			decl Float:fAngles[3], Float:fVelocity[3], Float:fOrigin[3], Float:vBuffer[3];
			new Address:bossType = TF2Attrib_GetByName(client, "damage force increase text");
			if(bossType != Address_Null && TF2Attrib_GetValue(bossType) > 0.0)
			{
				new Float:bossValue = TF2Attrib_GetValue(bossType);
				switch(bossValue)
				{
					case 1.0:
					{
						if(meleeLimiter[client] > 20)
						{
							meleeLimiter[client] = 0;
							for(new i=-3;i<=3;i+=1)
							{
								new String:projName[32] = "tf_projectile_arrow";
								new iEntity = CreateEntityByName(projName);
								if (IsValidEdict(iEntity)) 
								{
									new iTeam = GetClientTeam(client);
									new Float:fwd[3]
									new Float:right[3]
									SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

									//SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
									//SetEntityRenderColor(iEntity, 0, 0, 0, 0);
						
									SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
									SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
									GetClientEyePosition(client, fOrigin);
									GetClientEyeAngles(client, fAngles);
									GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
									GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
									GetAngleVectors(fAngles, NULL_VECTOR, right, NULL_VECTOR);
									ScaleVector(right, 8.0 * i);
									ScaleVector(fwd, 50.0);
									AddVectors(fOrigin, fwd, fOrigin);
									AddVectors(fOrigin, right, fOrigin);
									new Float:velocity = 5000.0;
									new Address:projspeed = TF2Attrib_GetByName(CWeapon, "Projectile speed increased");
									new Address:projspeed1 = TF2Attrib_GetByName(CWeapon, "Projectile speed decreased");
									if(projspeed != Address_Null){
										velocity *= TF2Attrib_GetValue(projspeed)
									}
									if(projspeed1 != Address_Null){
										velocity *= TF2Attrib_GetValue(projspeed1)
									}
									new Float:vecAngImpulse[3];
									GetCleaverAngularImpulse(vecAngImpulse);
									fVelocity[0] = vBuffer[0]*velocity;
									fVelocity[1] = vBuffer[1]*velocity;
									fVelocity[2] = vBuffer[2]*velocity;
									
									TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
									DispatchSpawn(iEntity);
									//SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vecAngImpulse, client, 0, 5.0);
									SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
									if(HasEntProp(iEntity, Prop_Send, "m_hLauncher"))
									{
										SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
									}
									SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
									SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008);
									SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
									SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 13); 
									if(StrEqual(projName, "tf_projectile_arrow", false))
									{
										SDKHook(iEntity, SDKHook_Touch, OnCollisionBossArrow);
										
										if(iTeam == 2)
										{
											CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0", "materials/effects/arrowtrail_red.vmt", "255 255 255");
										}
										else
										{
											CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0", "materials/effects/arrowtrail_blu.vmt", "255 255 255");
										}
									}
								}
							}
						}
					}
				}
			}
			new Address:meleeAttacks = TF2Attrib_GetByName(CWeapon, "duck rating");
			if(meleeAttacks != Address_Null && meleeLimiter[client] > RoundToNearest(TF2Attrib_GetValue(meleeAttacks) * 2.0))
			{
				new Handle:hPack = CreateDataPack();
				WritePackCell(hPack, EntIndexToEntRef(client));
				WritePackCell(hPack, EntIndexToEntRef(CWeapon));
				WritePackCell(hPack, RoundToNearest(TF2Attrib_GetValue(meleeAttacks)));
				CreateTimer(0.1,AttackTwice,hPack);
				meleeLimiter[client] = 0;
			}
			new Address:tracer = TF2Attrib_GetByName(CWeapon, "sniper fires tracer");
			if(LastCharge[client] >= 150.0 && tracer != Address_Null && TF2Attrib_GetValue(tracer) == 1.0)
			{
				TF2Attrib_SetByName(CWeapon, "sniper fires tracer", 0.0);
			}
			
			new Address:projActive = TF2Attrib_GetByName(CWeapon, "sapper damage penalty hidden");
			new Address:override = TF2Attrib_GetByName(CWeapon, "override projectile type");
			if(override != Address_Null)
			{
				new Float:projnum = TF2Attrib_GetValue(override);
				switch(projnum)
				{
					case 27.0:
					{
						new iEntity = CreateEntityByName("tf_projectile_sentryrocket");
						if (IsValidEdict(iEntity)) 
						{
							new iTeam = GetClientTeam(client);
							SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

							SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
							SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
							
							
							SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
							SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
										
							GetClientEyePosition(client, fOrigin);
							fAngles = fEyeAngles[client];
							
							GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
							new Float:Speed = 2000.0;
							new Address:projspeed = TF2Attrib_GetByName(CWeapon, "Projectile speed increased");
							if(projspeed != Address_Null)
							{
								Speed *= TF2Attrib_GetValue(projspeed);
							}
							fVelocity[0] = vBuffer[0]*Speed;
							fVelocity[1] = vBuffer[1]*Speed;
							fVelocity[2] = vBuffer[2]*Speed;
							
							new Float:ProjectileDamage = 90.0;
							
							new Address:DMGVSPlayer = TF2Attrib_GetByName(CWeapon, "dmg penalty vs players");
							new Address:DamagePenalty = TF2Attrib_GetByName(CWeapon, "damage penalty");
							new Address:DamageBonus = TF2Attrib_GetByName(CWeapon, "damage bonus");
							new Address:DamageBonusHidden = TF2Attrib_GetByName(CWeapon, "damage bonus HIDDEN");
							new Address:BulletsPerShot = TF2Attrib_GetByName(CWeapon, "bullets per shot bonus");
							new Address:AccuracyScales = TF2Attrib_GetByName(CWeapon, "accuracy scales damage");
							new Address:damageActive = TF2Attrib_GetByName(CWeapon, "ubercharge");
							
							if(damageActive != Address_Null)
							{
								ProjectileDamage *= Pow(TF2Attrib_GetValue(damageActive), 5.0);
							}
							if(DMGVSPlayer != Address_Null)
							{
								ProjectileDamage *= TF2Attrib_GetValue(DMGVSPlayer);
							}
							if(DamagePenalty != Address_Null)
							{
								ProjectileDamage *= TF2Attrib_GetValue(DamagePenalty);
							}
							if(DamageBonus != Address_Null)
							{
								ProjectileDamage *= TF2Attrib_GetValue(DamageBonus);
							}
							if(DamageBonusHidden != Address_Null)
							{
								ProjectileDamage *= TF2Attrib_GetValue(DamageBonusHidden);
							}
							if(BulletsPerShot != Address_Null)
							{
								ProjectileDamage *= TF2Attrib_GetValue(BulletsPerShot);
							}
							if(AccuracyScales != Address_Null)
							{
								ProjectileDamage *= TF2Attrib_GetValue(AccuracyScales);
							}
							
							SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, ProjectileDamage, true);  
							
							TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
							DispatchSpawn(iEntity);
						}
					}
					case 40.0:
					{
						if(meleeLimiter[client] >= 2)
						{
							meleeLimiter[client] = 0;
							for(new i=-1;i<=1;i+=2)
							{
								new String:projName[32] = "tf_projectile_arrow";
								new iEntity = CreateEntityByName(projName);
								if (IsValidEdict(iEntity)) 
								{
									new iTeam = GetClientTeam(client);
									new Float:fwd[3]
									new Float:right[3]
									SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

									//SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
									//SetEntityRenderColor(iEntity, 0, 0, 0, 0);
						
									SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
									SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
									GetClientEyePosition(client, fOrigin);
									GetClientEyeAngles(client, fAngles);
									GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
									GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
									GetAngleVectors(fAngles, NULL_VECTOR, right, NULL_VECTOR);
									ScaleVector(right, 8.0 * i);
									ScaleVector(fwd, 50.0);
									AddVectors(fOrigin, fwd, fOrigin);
									AddVectors(fOrigin, right, fOrigin);
									new Float:velocity = 5000.0;
									new Address:projspeed = TF2Attrib_GetByName(CWeapon, "Projectile speed increased");
									new Address:projspeed1 = TF2Attrib_GetByName(CWeapon, "Projectile speed decreased");
									if(projspeed != Address_Null){
										velocity *= TF2Attrib_GetValue(projspeed)
									}
									if(projspeed1 != Address_Null){
										velocity *= TF2Attrib_GetValue(projspeed1)
									}
									new Float:vecAngImpulse[3];
									GetCleaverAngularImpulse(vecAngImpulse);
									fVelocity[0] = vBuffer[0]*velocity;
									fVelocity[1] = vBuffer[1]*velocity;
									fVelocity[2] = vBuffer[2]*velocity;
									
									TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
									DispatchSpawn(iEntity);
									//SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vecAngImpulse, client, 0, 5.0);
									SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
									if(HasEntProp(iEntity, Prop_Send, "m_hLauncher"))
									{
										SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
									}
									SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
									SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008);
									SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
									SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 13); 
									if(StrEqual(projName, "tf_projectile_arrow", false))
									{
										SDKHook(iEntity, SDKHook_Touch, OnCollisionWarriorArrow);
										
										if(iTeam == 2)
										{
											CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0", "materials/effects/arrowtrail_red.vmt", "255 255 255");
										}
										else
										{
											CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0", "materials/effects/arrowtrail_blu.vmt", "255 255 255");
										}
									}
								}
							}
						}
					}
					case 41.0:
					{
						if(meleeLimiter[client] >= 2)
						{
							meleeLimiter[client] = 0;
							new String:projName[32] = "tf_projectile_arrow";
							new iEntity = CreateEntityByName(projName);
							if (IsValidEdict(iEntity)) 
							{
								new iTeam = GetClientTeam(client);
								new Float:fwd[3]
								SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

								//SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
								//SetEntityRenderColor(iEntity, 0, 0, 0, 0);
					
								SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
								SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
								GetClientEyePosition(client, fOrigin);
								GetClientEyeAngles(client, fAngles);
								GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
								GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
								ScaleVector(fwd, 30.0);
								AddVectors(fOrigin, fwd, fOrigin);
								new Float:velocity = 4000.0;
								new Address:projspeed = TF2Attrib_GetByName(CWeapon, "Projectile speed increased");
								new Address:projspeed1 = TF2Attrib_GetByName(CWeapon, "Projectile speed decreased");
								if(projspeed != Address_Null){
									velocity *= TF2Attrib_GetValue(projspeed)
								}
								if(projspeed1 != Address_Null){
									velocity *= TF2Attrib_GetValue(projspeed1)
								}
								new Float:vecAngImpulse[3];
								GetCleaverAngularImpulse(vecAngImpulse);
								fVelocity[0] = vBuffer[0]*velocity;
								fVelocity[1] = vBuffer[1]*velocity;
								fVelocity[2] = vBuffer[2]*velocity;
								
								TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
								DispatchSpawn(iEntity);
								//SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vecAngImpulse, client, 0, 5.0);
								SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
								if(HasEntProp(iEntity, Prop_Send, "m_hLauncher"))
								{
									SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
								}
								SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
								isProjectileBoomerang[iEntity] = true;
								SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008);
								SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
								SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 13); 
								SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 1.4);
								ResizeHitbox(iEntity, 2.0)
								SDKHook(iEntity, SDKHook_Touch, OnCollisionBoomerang);
								
								if(iTeam == 2)
								{
									CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0", "materials/effects/arrowtrail_red.vmt", "255 255 255");
								}
								else
								{
									CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0", "materials/effects/arrowtrail_blu.vmt", "255 255 255");
								}
								SetEntityModel(iEntity, "models/weapons/c_models/c_croc_knife/c_croc_knife.mdl");
							}
						}
					}
					case 42.0:
					{
						new String:projName[32] = "tf_projectile_rocket";
						new iEntity = CreateEntityByName(projName);
						if (IsValidEdict(iEntity)) 
						{
							new iTeam = GetClientTeam(client);
							new Float:fwd[3]
							SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

							//SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
							//SetEntityRenderColor(iEntity, 0, 0, 0, 0);
				
							SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
							SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
							GetClientEyePosition(client, fOrigin);
							GetClientEyeAngles(client, fAngles);
							GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
							GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
							ScaleVector(fwd, 35.0);
							AddVectors(fOrigin, fwd, fOrigin);
							new Float:velocity = 3000.0;
							new Address:projspeed = TF2Attrib_GetByName(CWeapon, "Projectile speed increased");
							new Address:projspeed1 = TF2Attrib_GetByName(CWeapon, "Projectile speed decreased");
							if(projspeed != Address_Null){
								velocity *= TF2Attrib_GetValue(projspeed)
							}
							if(projspeed1 != Address_Null){
								velocity *= TF2Attrib_GetValue(projspeed1)
							}
							new Float:vecAngImpulse[3];
							GetCleaverAngularImpulse(vecAngImpulse);
							fVelocity[0] = vBuffer[0]*velocity;
							fVelocity[1] = vBuffer[1]*velocity;
							fVelocity[2] = vBuffer[2]*velocity;
							
							TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
							DispatchSpawn(iEntity);
							//SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vecAngImpulse, client, 0, 5.0);
							SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
							if(HasEntProp(iEntity, Prop_Send, "m_hLauncher"))
							{
								SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
							}
							SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
							SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 1.2);
							SDKHook(iEntity, SDKHook_Touch, OnCollisionPiercingRocket);
							SDKUnhook(iEntity, SDKHook_Touch, projectileCollision);
							SetEntityModel(iEntity, "models/weapons/w_models/w_rocket_airstrike/w_rocket_airstrike.mdl");
							CreateTimer(3.0, SelfDestruct, EntIndexToEntRef(iEntity));
							SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 70.0 * TF2_GetDamageModifiers(client,CWeapon), true);  
						}
					}
					case 43.0:
					{
						new iEntity = CreateEntityByName("tf_projectile_spellfireball");
						if (IsValidEdict(iEntity)) 
						{
							new iTeam = GetClientTeam(client);
							new Float:fwd[3]
							SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
							SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
							GetClientEyeAngles(client, fAngles);
							GetClientEyePosition(client, fOrigin);

							GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
							ScaleVector(fwd, 30.0);
							
							AddVectors(fOrigin, fwd, fOrigin);
							GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
							
							new Float:velocity = 900.0;
							new Float:vecAngImpulse[3];
							GetCleaverAngularImpulse(vecAngImpulse);
							fVelocity[0] = vBuffer[0]*velocity;
							fVelocity[1] = vBuffer[1]*velocity;
							fVelocity[2] = vBuffer[2]*velocity;
							
							TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
							DispatchSpawn(iEntity);
							SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchChaos);
							CreateTimer(10.0,SelfDestruct,EntIndexToEntRef(iEntity));
						}
					}
					case 44.0:
					{
						new Float:ClientPos[3],Float:ProjectileDamage=20.0,iTeam=GetClientTeam(client),melee=GetWeapon(client,2)
						TracePlayerAim(client, ClientPos);
						GetClientEyePosition(client, fOrigin);
						
						new Address:SentryDmgActive = TF2Attrib_GetByName(CWeapon, "ring of fire while aiming");
						if(SentryDmgActive != Address_Null)
						{
							ProjectileDamage *= TF2Attrib_GetValue(SentryDmgActive);
						}
						
						if(IsValidEntity(melee))
						{
							new Address:SentryDmgActive1 = TF2Attrib_GetByName(melee, "throwable detonation time");
							if(SentryDmgActive1 != Address_Null)
							{
								ProjectileDamage *= TF2Attrib_GetValue(SentryDmgActive1);
							}
							new Address:SentryDmgActive2 = TF2Attrib_GetByName(melee, "throwable fire speed");
							if(SentryDmgActive2 != Address_Null)
							{
								ProjectileDamage *= TF2Attrib_GetValue(SentryDmgActive2);
							}
							new Address:damageActive = TF2Attrib_GetByName(melee, "ubercharge");
							if(damageActive != Address_Null)
							{
								ProjectileDamage *= Pow(TF2Attrib_GetValue(damageActive), 5.0);
							}
							new Address:damageActive2 = TF2Attrib_GetByName(melee, "engy sentry damage bonus");
							if(damageActive2 != Address_Null)
							{
								ProjectileDamage *= TF2Attrib_GetValue(damageActive2);
							}
							new Address:fireRateActive = TF2Attrib_GetByName(melee, "engy sentry fire rate increased");
							if(fireRateActive != Address_Null)
							{
								ProjectileDamage /= TF2Attrib_GetValue(fireRateActive);
							}
						}
						
						for(new i = 0;i<60;i++)
						{
							new Handle:hPack = CreateDataPack();
							WritePackCell(hPack, client);
							WritePackCell(hPack, iTeam);
							WritePackFloat(hPack, ProjectileDamage);
							
							WritePackFloat(hPack, ClientPos[0]);
							WritePackFloat(hPack, ClientPos[1]);
							WritePackFloat(hPack, ClientPos[2]);
							
							WritePackFloat(hPack, fOrigin[0]);
							WritePackFloat(hPack, fOrigin[1]);
							WritePackFloat(hPack, fOrigin[2]);
							
							CreateTimer(0.6+(i*0.03),orbitalStrike,hPack);
						}
					}
				}
				/*if(projnum == 31)
				{
					new iEntity = CreateEntityByName("tf_projectile_lightningorb");
					if (IsValidEdict(iEntity)) 
					{
						new iTeam = GetClientTeam(client);
						SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

						SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
						SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
						
						
						SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
						SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
									
						GetClientEyePosition(client, fOrigin);
						fAngles = fEyeAngles[client];
						
						GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
						new Float:Speed = 700.0;
						
						new Address:projspeed = TF2Attrib_GetByName(CWeapon, "Projectile speed increased");
						if(projspeed != Address_Null)
						{
							Speed *= TF2Attrib_GetValue(projspeed);
						}
						fVelocity[0] = vBuffer[0]*Speed;
						fVelocity[1] = vBuffer[1]*Speed;
						fVelocity[2] = vBuffer[2]*Speed;
						DispatchSpawn(iEntity);
						TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
					}
				}*/
			}
			if(projActive != Address_Null && TF2Attrib_GetValue(projActive) == 2.0)
			{
				if(ShotsLeft[client] < 1)
				{
					new iEntity = CreateEntityByName("tf_projectile_sentryrocket");
					if (IsValidEdict(iEntity)) 
					{
						new iTeam = GetClientTeam(client);
						SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

						SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
						SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
						
						
						SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
						DispatchSpawn(iEntity);
									
						GetClientEyePosition(client, fOrigin);
						fAngles = fEyeAngles[client];
						
						GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
						new Float:Speed = 2000.0;
						fVelocity[0] = vBuffer[0]*Speed;
						fVelocity[1] = vBuffer[1]*Speed;
						fVelocity[2] = vBuffer[2]*Speed;
						SetEntPropVector( iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
						new Float:ProjectileDamage = 20.0;
						
						new Address:DMGVSPlayer = TF2Attrib_GetByName(CWeapon, "taunt is highfive");
						new Address:DamagePenalty = TF2Attrib_GetByName(CWeapon, "damage penalty");
						new Address:DamageBonus = TF2Attrib_GetByName(CWeapon, "damage bonus");
						new Address:DamageBonusHidden = TF2Attrib_GetByName(CWeapon, "damage bonus HIDDEN");
						new Address:BulletsPerShot = TF2Attrib_GetByName(CWeapon, "bullets per shot bonus");
						new Address:AccuracyScales = TF2Attrib_GetByName(CWeapon, "disguise damage reduction");
						new Address:damageActive = TF2Attrib_GetByName(CWeapon, "ubercharge");
						
						if(damageActive != Address_Null)
						{
							ProjectileDamage *= Pow(TF2Attrib_GetValue(damageActive), 5.0);
						}
						if(DMGVSPlayer != Address_Null)
						{
							ProjectileDamage *= TF2Attrib_GetValue(DMGVSPlayer);
						}
						if(DamagePenalty != Address_Null)
						{
							ProjectileDamage *= TF2Attrib_GetValue(DamagePenalty);
						}
						if(DamageBonus != Address_Null)
						{
							ProjectileDamage *= TF2Attrib_GetValue(DamageBonus);
						}
						if(DamageBonusHidden != Address_Null)
						{
							ProjectileDamage *= TF2Attrib_GetValue(DamageBonusHidden);
						}
						if(BulletsPerShot != Address_Null)
						{
							ProjectileDamage *= TF2Attrib_GetValue(BulletsPerShot);
						}
						if(AccuracyScales != Address_Null)
						{
							ProjectileDamage *= TF2Attrib_GetValue(AccuracyScales);
						}
						SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, ProjectileDamage, true);  
						TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
					}
					ShotsLeft[client] = 30;
				}
				else
				{
					ShotsLeft[client]--;
				}
			}
		}
	}
	return MRES_Ignored;
}
public Action:orbitalStrike(Handle:timer,any:data)
{
	ResetPack(data);
	new client = ReadPackCell(data);
	new iTeam = ReadPackCell(data);
	new Float:ProjectileDamage = ReadPackFloat(data);
	new Float:ClientPos[3];
	ClientPos[0] = ReadPackFloat(data);
	ClientPos[1] = ReadPackFloat(data);
	ClientPos[2] = ReadPackFloat(data);
	new Float:ClientOrigin[3];
	ClientOrigin[0] = ReadPackFloat(data);
	ClientOrigin[1] = ReadPackFloat(data);
	ClientOrigin[2] = ReadPackFloat(data);
	new iEntity = CreateEntityByName("tf_projectile_rocket");
	if (IsValidEdict(iEntity)) 
	{
		new Float:fAngles[3]
		new Float:fOrigin[3]
		new Float:vBuffer[3]
		new Float:fVelocity[3]
		new Float:EndVector[3]
		SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
		SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
		SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
		
		fOrigin = ClientOrigin;
		fOrigin[0] += GetRandomFloat(-300.0,300.0);
		fOrigin[1] += GetRandomFloat(-300.0,300.0);
		fOrigin[2] = getHighestPosition(fOrigin)-50.0;
		
		MakeVectorFromPoints(fOrigin, ClientPos , EndVector);
		GetVectorAngles(EndVector, fAngles);
		GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		
		new Float:Speed = 4500.0;
		fVelocity[0] = vBuffer[0]*Speed;
		fVelocity[1] = vBuffer[1]*Speed;
		fVelocity[2] = vBuffer[2]*Speed;
		SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, ProjectileDamage, true);  
		TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
		DispatchSpawn(iEntity);
	}
	CloseHandle(data);
}
public SlashThink(entity) 
{ 
	if(IsValidEntity(entity))
	{
		new Float:ProjAngle[3];
		new Float:ProjVelocity[3];
		new Float:vBuffer[3];
		new Float:speed;
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
		//ProjAngle[1] += isProjectileSlash[entity][1];
		//ProjAngle[0] += isProjectileSlash[entity][0];
		GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", ProjVelocity);
		speed = GetVectorLength(ProjVelocity)
		GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR)
		ProjVelocity[0] = vBuffer[0] * speed;
		ProjVelocity[1] = vBuffer[1] * speed;
		ProjVelocity[2] = vBuffer[2] * speed;
		TeleportEntity(entity, NULL_VECTOR, ProjAngle, ProjVelocity);
	}
}
public BoomerangThink(entity) 
{ 
	if(IsValidEntity(entity) && GetGameTime() - entitySpawnTime[entity] > 0.3 && GetGameTime() - entitySpawnTime[entity] < 0.92)
	{
		new Float:ProjAngle[3];
		new Float:ProjVelocity[3];
		new Float:vBuffer[3];
		new Float:speed;
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
		ProjAngle[1] += 5.5;
		ProjAngle[0] = 0.0;
		GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", ProjVelocity);
		speed = GetVectorLength(ProjVelocity)
		GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR)
		ProjVelocity[0] = vBuffer[0] * speed;
		ProjVelocity[1] = vBuffer[1] * speed;
		ProjVelocity[2] = vBuffer[2] * speed;
		TeleportEntity(entity, NULL_VECTOR, ProjAngle, ProjVelocity);
	}
}
public Action:OnCollisionBoomerang(entity, client)
{
	decl String:strName[128];
	GetEntityClassname(client, strName, 128)
	decl String:strName1[128];
	GetEntityClassname(entity, strName1, 128)
	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			if(IsValidClient3(owner) && IsOnDifferentTeams(owner,client))
			{
				new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new Float:damageDealt = 120.0 * TF2_GetDamageModifiers(owner, CWeapon);
					new Address:multiHitActive = TF2Attrib_GetByName(CWeapon, "taunt move acceleration time");
					if(multiHitActive != Address_Null)
					{
						damageDealt *= TF2Attrib_GetValue(multiHitActive) + 1.0;
					}
					Entity_Hurt(client, RoundToNearest(damageDealt), owner, DMG_BULLET);
				}
			}
			new Float:origin[3];
			new Float:ProjAngle[3];
			new Float:vBuffer[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
			GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
			GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(vBuffer, 20.0);
			origin[0] += vBuffer[0]
			origin[1] += vBuffer[1]
			TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
			if(IsValidClient3(client))
				ShouldNotHome[entity][client] = true;
		}
	}
	return Plugin_Stop;
}
public Action:OnCollisionPiercingRocket(entity, client)
{
	decl String:strName[128];
	GetEntityClassname(client, strName, 128)
	decl String:strName1[128];
	GetEntityClassname(entity, strName1, 128)
	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			if(IsValidClient3(owner) && IsOnDifferentTeams(entity,client))
			{
				new Float:origin[3];
				new Float:ProjAngle[3];
				new Float:vBuffer[3];
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
				GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
				GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(vBuffer, 100.0);
				AddVectors(origin, vBuffer, origin);
				TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
				RequestFrame(fixPiercingVelocity,EntIndexToEntRef(entity))
				
				new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new Float:damageDealt = 70.0 * TF2_GetDamageModifiers(owner, CWeapon);
					
					new Float:clientpos[3],Float:targetpos[3];
					GetEntPropVector(owner, Prop_Data, "m_vecAbsOrigin", clientpos);
					GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", targetpos);
					new Float:distance = GetVectorDistance(clientpos, targetpos);
					if(distance > 512.0)
					{
						new Float:Max = 1024.0; //the maximum units that the player and target is at (assuming you've already gotten the vectors)
						if(distance > Max)
						{
							distance = Max;
						}
						new Float:MinFallOffDist = 512.0 / (2.0 - 0.48); //the minimum units that the player and target is at (assuming you've already gotten the vectors) 
						new Float:base = damageDealt; //base becomes the initial damage
						new Float:multiplier = (MinFallOffDist / Max); //divides the minimal distance with the maximum you've set
						new Float:falloff = (multiplier * base);  //this is to get how much the damage will be at maximum distance
						new Float:Sinusoidal = ((falloff-base) / (Max-MinFallOffDist));  //does slope formula to get a sinusoidal fall off
						new Float:intercept = (base - (Sinusoidal*MinFallOffDist));  //this calculation gets the 'y-intercept' to determine damage ramp up
						damageDealt = ((Sinusoidal*distance)+intercept); //gets final damage by taking the slope formula, multiplying it by your vectors, and adds the damage ramp up Y intercept. 
					}
					EntityExplosion(owner, damageDealt, 144.0, origin, 0, true, entity, _, _,_,0.5)
				}
				if(IsValidClient3(client))
					ShouldNotHome[entity][client] = true;
				return Plugin_Stop;
			}
		}
	}
	if(IsValidEntity(entity))
	{
		new Float:origin[3];
		new Float:ProjAngle[3];
		new Float:vBuffer[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
		GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vBuffer, 20.0);
		AddVectors(origin, vBuffer, origin);
		TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
		RequestFrame(fixPiercingVelocity,EntIndexToEntRef(entity))
	}
	return Plugin_Continue;
}
stock fixPiercingVelocity(entity)
{
	entity = EntRefToEntIndex(entity)
	if(IsValidEntity(entity))
	{
		new Float:origin[3];
		new Float:ProjAngle[3];
		new Float:vBuffer[3];
		new Float:fVelocity[3];
		new Float:speed = 3000.0;
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
		GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
		if(HasEntProp(entity, Prop_Send, "m_vInitialVelocity"))
		{
			GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", fVelocity);
			speed = GetVectorLength(fVelocity);
		}
		fVelocity[0] = vBuffer[0]*speed;
		fVelocity[1] = vBuffer[1]*speed;
		fVelocity[2] = vBuffer[2]*speed;
		TeleportEntity(entity, origin,NULL_VECTOR,fVelocity);
	}
}
public void TF2_OnConditionRemoved(client, TFCond:cond)
{
	if(cond == TFCond_TeleportedGlow){
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.0);
	}
	if(cond == TFCond_OnFire){
		fl_HighestFireDamage[client] = 0.0;
	}
	if(cond == TFCond_Charging){
		new Float:grenadevec[3], Float:distance;
		distance = 500.0;
		GetClientEyePosition(client, grenadevec);
		new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(CWeapon))
		{
			new Float:damage = TF2_GetDPSModifiers(client,CWeapon,false,false) * 70.0;
			new secondary = GetWeapon(client,1);
			if(IsValidEntity(secondary))
			{
				new Address:bashBonusActive = TF2Attrib_GetByName(secondary, "charge impact damage increased")
				if(bashBonusActive != Address_Null)
				{
					damage *= TF2Attrib_GetValue(bashBonusActive);
				}
			}
			EntityExplosion(client, damage, distance, grenadevec, 1);
		}
	}
}
public OnEntityCreated(entity, const char[] classname)
{
	if(StrContains(classname, "tf_projectile_", false) == 0)
	{
		entitySpawnTime[entity] = GetGameTime();
		g_nBounces[entity] = 0;
		if(StrEqual(classname, "tf_projectile_energy_ball") || StrEqual(classname, "tf_projectile_energy_ring")
		|| StrEqual(classname, "tf_projectile_balloffire"))
		{
			RequestFrame(ProjSpeedDelay, EntIndexToEntRef(entity));
			RequestFrame(PrecisionHoming, EntIndexToEntRef(entity));
		}
		else if(StrEqual(classname, "tf_projectile_arrow") || StrEqual(classname, "tf_projectile_healing_bolt"))
		{
			RequestFrame(MultiShot, EntIndexToEntRef(entity));
			RequestFrame(ProjSpeedDelay, EntIndexToEntRef(entity));
			RequestFrame(SetZeroGravity, EntIndexToEntRef(entity));
			RequestFrame(ExplosiveArrow, EntIndexToEntRef(entity));
			RequestFrame(ChangeProjModel, EntIndexToEntRef(entity));
			RequestFrame(PrecisionHoming, EntIndexToEntRef(entity));
			CreateTimer(4.0, SelfDestruct, EntIndexToEntRef(entity));
			CreateTimer(0.1, ArrowThink, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.03, HeadshotHomingThink, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		if(StrEqual(classname, "tf_projectile_syringe") || StrEqual(classname, "tf_projectile_rocket")
		|| StrEqual(classname, "tf_projectile_flare")|| StrEqual(classname, "tf_projectile_pipe")
		|| StrEqual(classname, "tf_projectile_pipe_remote"))
		{
			RequestFrame(MultiShot, EntIndexToEntRef(entity));
			CreateTimer(0.03, HomingThink, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			SDKHook(entity, SDKHook_StartTouch, OnStartTouch);
			RequestFrame(projGravity, EntIndexToEntRef(entity));
			RequestFrame(PrecisionHoming, EntIndexToEntRef(entity));
		}
		if(StrEqual(classname, "tf_projectile_rocket") || StrEqual(classname, "tf_projectile_flare") || StrEqual(classname, "tf_projectile_sentryrocket"))
		{
			SDKHook(entity, SDKHook_Touch, projectileCollision);
			SDKHook(entity, SDKHook_StartTouchPost, meteorCollision);
			RequestFrame(instantProjectile, EntIndexToEntRef(entity));
			RequestFrame(monoculusBonus, EntIndexToEntRef(entity));
			RequestFrame(PrecisionHoming, EntIndexToEntRef(entity));
		}
		if(StrEqual(classname, "tf_projectile_stun_ball") || StrEqual(classname, "tf_projectile_ball_ornament") || StrEqual(classname, "tf_projectile_cleaver"))
		{
			RequestFrame(MultiShot, EntIndexToEntRef(entity));
			RequestFrame(projGravity, EntIndexToEntRef(entity));
			CreateTimer(0.03, ThrowableHomingThink, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		if(StrEqual(classname, "tf_projectile_pipe") || StrEqual(classname, "tf_projectile_pipe_remote"))
		{
			RequestFrame(CheckMines, EntIndexToEntRef(entity));
			RequestFrame(ChangeProjModel, EntIndexToEntRef(entity));
		}
		if(StrEqual(classname, "tf_projectile_sentryrocket"))
		{
			CreateTimer(5.0, SelfDestruct, EntIndexToEntRef(entity));
			RequestFrame(SentryMultishot, EntIndexToEntRef(entity));
			CreateTimer(0.03, HomingSentryRocketThink, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			RequestFrame(SentryDelay, EntIndexToEntRef(entity));
		}
		if(StrEqual(classname, "tf_projectile_energy_ring"))
		{
			isProjectileHoming[entity] = true;
			CreateTimer(1.0, SelfDestruct, EntIndexToEntRef(entity));
		}
	}
	if(StrEqual(classname, "tank_boss"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Tank);
		RequestFrame(randomizeTankSpecialty, EntIndexToEntRef(entity));
	}
	if(StrEqual(classname, "obj_sentrygun"))
	{
		RequestFrame(checkEnabledSentry, EntIndexToEntRef(entity));
	}
	if(StrContains(classname, "item_currencypack", false) == 0)
	{
		RequestFrame(TeleportToNearestPlayer, EntIndexToEntRef(entity));
	}
	if(StrContains(classname, "item_powerup_rune", false) == 0)
	{
		RemoveEntity(entity);
	}
	
	if(IsValidEntity(entity))
	{
		if (HasEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity"))
		{
			if (GetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity") == 0)
			{
				SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
			}
		}
		if(debugMode)
			PrintToServer("debugLog | %s was created.", classname)
	}
}
public OnEntityDestroyed(entity)
{
	if(IsValidEntity(entity))
	{
		new String:classname[32];
		GetEntityClassname(entity, classname, 32)
		if(entity > 0 && entity <= 2048)
		{
			for(new i=1;i<MaxClients;i++)
			{
				ShouldNotHome[entity][i] = false;
			}
			isProjectileHoming[entity] = false;
			isProjectileBoomerang[entity] = false;
			projectileHomingDegree[entity] = 0.0;
			gravChanges[entity] = false;
			//isProjectileSlash[entity][0] = 0.0;
			//isProjectileSlash[entity][1] = 0.0;
			jarateWeapon[entity] = -1;
		}
		if(StrEqual(classname, "tank_boss"))
		{
			int iLink = GetEntPropEnt(entity, Prop_Send, "m_hEffectEntity");
			if(IsValidEntity(iLink))
			{
				AcceptEntityInput(iLink, "ClearParent");
				AcceptEntityInput(iLink, "Kill");
			}
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Tank);
		}
		if(debugMode)
			PrintToServer("debugLog | %s was deleted.", classname)
	}
}
monoculusBonus(entity) 
{
	entity = EntRefToEntIndex(entity);
    if(IsValidEdict(entity)) 
    { 
		int monoculus = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidEntity(monoculus))
		{
			new client = EntRefToEntIndex(jarateWeapon[monoculus]);
			if(IsValidClient3(client))
			{
				new Float:vAngles[3];
				new Float:vPosition[3];
				new Float:vBuffer[3];
				new Float:vVelocity[3];
				new Float:vel[3];
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPosition);
				GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
				GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
				GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
				new Float:projspd = 3.0;
				vVelocity[0] = vBuffer[0]*projspd*GetVectorLength(vel);
				vVelocity[1] = vBuffer[1]*projspd*GetVectorLength(vel);
				vVelocity[2] = vBuffer[2]*projspd*GetVectorLength(vel);
				TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
				
				new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					SetEntDataFloat(entity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 90.0 * TF2_GetDamageModifiers(client,CWeapon), true);  
				}
			}
		}
    } 
}
checkEnabledSentry(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEntity(entity))
	{
		if(HasEntProp(entity,Prop_Send,"m_hBuilder"))
		{
			new owner = GetEntPropEnt(entity,Prop_Send,"m_hBuilder" );
			if(IsValidClient3(owner))
			{
				new melee = (GetPlayerWeaponSlot(owner,2));
				if(IsValidEntity(melee))
				{
					new weaponIndex = GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex");
					if(weaponIndex == 589)
					{
						PrintToChat(owner, "Your sentry is disabled (Eureka Effect).");
						RemoveEntity(entity);
					}
				}
			}
		}
	}
}
randomizeTankSpecialty(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEntity(entity))//In case if the tank somehow instantly despawns.
	{
		new specialtyID = GetRandomInt(0,1);
		switch(specialtyID)
		{
			case 0:
			{
				new iEntity = CreateEntityByName("obj_sentrygun");
				if(IsValidEntity(iEntity))
				{
					new Float:position[3];
					GetEntPropVector(entity, Prop_Data, "m_vecOrigin", position);
					
					new iLink = CreateLink(entity);
					
					SetVariantString("!activator");
					AcceptEntityInput(iEntity, "SetParent", iLink);  
					SetEntPropEnt(entity, Prop_Send, "m_hEffectEntity", iLink);
					position[2] += 200.0;
					
					TeleportEntity(iEntity, position, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(iEntity);
					SetEntProp(iEntity, Prop_Data, "m_spawnflags", 8);
					SetEntProp(iEntity, Prop_Data, "m_takedamage", 0);
					SetEntProp(iEntity, Prop_Send, "m_iUpgradeLevel", 3);
					SetEntProp(iEntity, Prop_Send, "m_iHighestUpgradeLevel", 3);
					SetEntProp(iEntity, Prop_Send, "m_nSkin", 1);
					SetEntProp(iEntity, Prop_Send, "m_bBuilding", 1);
					SetEntProp(iEntity, Prop_Send, "m_nSolidType", 2);
					SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0);
					SetEntProp(iEntity, Prop_Send, "m_hBuiltOnEntity", entity);
					SetVariantInt(3);
					AcceptEntityInput(iEntity, "SetTeam");
					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 3)
					if(IsValidEntity(logic))
					{
						new round = GetEntProp(logic, Prop_Send, "m_nMannVsMachineWaveCount");
						new Float:currency = 60000.0;
						for(new i = 1;i<round;i++)
						{
							currency += (currency*0.2)+20000.0;
						}
						TankSentryDamageMod = Pow((currency/11000), DamageMod + (round * 0.03)) * 1.8 * OverallMod;
					}
				}
			}
			case 1:
			{
				if(!IsValidEntity(TankTeleporter))
				{
					new iEntity = CreateEntityByName("obj_teleporter");
					if(IsValidEntity(iEntity))
					{
						new Float:position[3];
						GetEntPropVector(entity, Prop_Data, "m_vecOrigin", position);
						
						new iLink = CreateLink(entity);
						
						SetVariantString("!activator");
						AcceptEntityInput(iEntity, "SetParent", iLink);  
						SetEntPropEnt(entity, Prop_Send, "m_hEffectEntity", iLink);
						
						position[2] += 200.0;
						
						TeleportEntity(iEntity, position, NULL_VECTOR, NULL_VECTOR);
						DispatchSpawn(iEntity);
						SetEntProp(iEntity, Prop_Data, "m_spawnflags", 6);
						SetEntProp(iEntity, Prop_Data, "m_takedamage", 0);
						SetEntProp(iEntity, Prop_Send, "m_nSkin", 1);
						SetEntProp(iEntity, Prop_Send, "m_bBuilding", 1);
						SetVariantInt(3);
						AcceptEntityInput(iEntity, "SetTeam");
						SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 3)
						SetEntProp(iEntity, Prop_Data, "m_iTeleportType", TFObjectMode_Exit);
						SetEntProp(iEntity, Prop_Send, "m_iObjectMode", TFObjectMode_Exit);
						CreateTimer(10.0, SetTankTeleporter, EntIndexToEntRef(entity));
					}
				}
			}
		}
	}
}
public Action:SetTankTeleporter(Handle:timer, int entity) 
{  
	entity = EntRefToEntIndex(entity)
	if(IsValidEntity(entity))
	{
		TankTeleporter = entity;
	}
}
ChangeProjModel(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEntity(entity))
	{
		new client;
		if(HasEntProp(entity, Prop_Data, "m_hThrower"))
		{
			client = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		}
		else if(HasEntProp(entity, Prop_Data, "m_hOwnerEntity"))
		{
			client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		}
		if(IsValidClient(client))
		{
			new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(CWeapon))
			{
				new iItemDefinitionIndex = GetEntProp(CWeapon, Prop_Send, "m_iItemDefinitionIndex");
				switch(iItemDefinitionIndex)
				{
					case 222:
					{
						SetEntityModel(entity, "models/weapons/c_models/c_madmilk/c_madmilk.mdl");
						SDKHook(entity, SDKHook_StartTouch, OnStartTouchJars);
						gravChanges[entity] = true;
						jarateType[entity] = 1;
						jarateWeapon[entity] = EntIndexToEntRef(CWeapon);
						SetEntityGravity(entity, 1.75);
					}
					case 1121:
					{
						SetEntityModel(entity, "models/weapons/c_models/c_breadmonster/c_breadmonster_milk.mdl");
						SDKHook(entity, SDKHook_StartTouch, OnStartTouchJars);
						gravChanges[entity] = true;
						jarateType[entity] = 1;
						jarateWeapon[entity] = EntIndexToEntRef(CWeapon);
						SetEntityGravity(entity, 1.75);
					}
					case 58,1149:
					{
						SetEntityModel(entity, "models/weapons/c_models/urinejar.mdl");
						SDKHook(entity, SDKHook_StartTouch, OnStartTouchJars);
						gravChanges[entity] = true;
						jarateType[entity] = 0;
						jarateWeapon[entity] = EntIndexToEntRef(CWeapon);
						SetEntityGravity(entity, 1.75);
					}
					case 1105:
					{
						SetEntityModel(entity, "models/weapons/c_models/c_breadmonster/c_breadmonster.mdl");
						SDKHook(entity, SDKHook_StartTouch, OnStartTouchJars);
						gravChanges[entity] = true;
						jarateType[entity] = 0;
						jarateWeapon[entity] = EntIndexToEntRef(CWeapon);
						SetEntityGravity(entity, 1.75);
					}
					case 812,833:
					{
						SetEntityModel(entity, "models/weapons/c_models/c_sd_cleaver/c_sd_cleaver.mdl");
					}
				}
			}
		}
	}
}
public Action:OnStartTouchJars(entity, other)
{
	SDKHook(entity, SDKHook_Touch, OnTouchExplodeJar);
	return Plugin_Handled;
}
public Action:OnTouchExplodeJar(entity, other)
{
	new Float:targetvec[3],Float:clientvec[3],Float:Radius=144.0,mode=jarateType[entity];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", clientvec);
	new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity"); 
	if(!IsValidClient(owner))
		return Plugin_Continue;
	
	new CWeapon = EntRefToEntIndex(jarateWeapon[entity]);
	if(IsValidEntity(CWeapon))
	{
		new Address:blastRadius1 = TF2Attrib_GetByName(CWeapon, "Blast radius increased");
		new Address:blastRadius2 = TF2Attrib_GetByName(CWeapon, "Blast radius decreased");
		if(blastRadius1 != Address_Null){
			Radius *= TF2Attrib_GetValue(blastRadius1)
		}
		if(blastRadius2 != Address_Null){
			Radius *= TF2Attrib_GetValue(blastRadius2)
		}
		
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsValidClient3(i) && IsClientInGame(i) && IsPlayerAlive(i))
			{
				GetClientEyePosition(i, targetvec);
				if(!IsClientObserver(i) && GetVectorDistance(clientvec, targetvec, false) <= Radius)
				{
					if(IsPointVisible(clientvec,targetvec))
					{
						if(GetClientTeam(i) != GetClientTeam(owner))
						{
							switch(mode)
							{
								case 0:
								{
									TF2_AddCondition(i,TFCond_Jarated,0.01);
									SDKHooks_TakeDamage(i,owner,owner,30.0,DMG_BULLET,CWeapon,NULL_VECTOR,NULL_VECTOR);
									miniCritStatusVictim[i] = 8.0
								}
								case 1:
								{
									TF2_AddCondition(i,TFCond_Milked,0.01);
									SDKHooks_TakeDamage(i,owner,owner,30.0,DMG_BULLET,CWeapon,NULL_VECTOR,NULL_VECTOR);
								}
							}//corrosiveDOT
							new Address:jarCorrosive = TF2Attrib_GetByName(CWeapon, "building cost reduction");
							if(jarCorrosive != Address_Null)
							{
								new Float:damageDealt = TF2_GetDPSModifiers(owner,CWeapon)*TF2Attrib_GetValue(jarCorrosive);
								corrosiveDOT[i][owner][0] = damageDealt;
								corrosiveDOT[i][owner][1] = 2.0
							}
						}
						else
						{
							if(i != owner)
							{
								new Address:jarAfterburnImmunity = TF2Attrib_GetByName(CWeapon, "overheal decay disabled");
								if(jarAfterburnImmunity != Address_Null)
								{
									TF2_AddCondition(i,TFCond_AfterburnImmune,TF2Attrib_GetValue(jarAfterburnImmunity));
								}
								new Address:jarKingBuff = TF2Attrib_GetByName(CWeapon, "no crit vs nonburning");
								if(jarKingBuff != Address_Null)
								{
									TF2_AddCondition(i,TFCond_KingAura,TF2Attrib_GetValue(jarKingBuff));
								}
								new Address:jarPreventDeath = TF2Attrib_GetByName(CWeapon, "fists have radial buff");
								if(jarPreventDeath != Address_Null)
								{
									TF2_AddCondition(i,TFCond_PreventDeath,TF2Attrib_GetValue(jarPreventDeath));
								}
								new Address:jarDefensiveBuff = TF2Attrib_GetByName(CWeapon, "set cloak is feign death");
								if(jarDefensiveBuff != Address_Null)
								{
									TF2_AddCondition(i,TFCond_DefenseBuffNoCritBlock,TF2Attrib_GetValue(jarDefensiveBuff));
								}
							}
							TF2_RemoveCondition(i, TFCond_OnFire);
						}
					}
				}
			}
		}
		new Address:jarFragsToggle = TF2Attrib_GetByName(CWeapon, "overheal decay penalty");
		if(jarFragsToggle != Address_Null)
		{
			for(new i = 0;i<RoundToNearest(TF2Attrib_GetValue(jarFragsToggle));i++)
			{
				new iEntity = CreateEntityByName("tf_projectile_syringe");
				if (IsValidEdict(iEntity)) 
				{
					new iTeam = GetClientTeam(owner);
					new Float:fAngles[3]
					new Float:fOrigin[3];
					new Float:vBuffer[3]
					new Float:fVelocity[3]
					new Float:fwd[3]
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);
					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
					fOrigin = clientvec;
					fAngles[0] = GetRandomFloat(0.0,-60.0)
					fAngles[1] = GetRandomFloat(-179.0,179.0)

					GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
					ScaleVector(fwd, 30.0);
					
					AddVectors(fOrigin, fwd, fOrigin);
					GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					
					new Float:velocity = 2000.0;
					fVelocity[0] = vBuffer[0]*velocity;
					fVelocity[1] = vBuffer[1]*velocity;
					fVelocity[2] = vBuffer[2]*velocity;
					
					TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
					DispatchSpawn(iEntity);
					setProjGravity(iEntity, 9.0);
					SDKHook(iEntity, SDKHook_Touch, OnCollisionJarateFrag);
					jarateWeapon[iEntity] = EntIndexToEntRef(CWeapon);
					CreateTimer(1.0,SelfDestruct,EntIndexToEntRef(iEntity));
					SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008);
					SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
					SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 13);
				}
			}
		}
	}
	switch(mode)
	{
		case 0:
		{
			CreateParticle(-1, "peejar_impact", false, "", 1.0, clientvec);
		}
		case 1:
		{
			CreateParticle(-1, "peejar_impact_milk", false, "", 1.0, clientvec);
		}
		case 2:
		{
			CreateParticle(-1, "pumpkin_explode", false, "", 1.0, clientvec);
		}
		case 3:
		{
			CreateParticle(-1, "breadjar_impact", false, "", 1.0, clientvec);
		}
		case 4:
		{
			CreateParticle(-1, "gas_can_impact_blue", false, "", 1.0, clientvec);
		}
		case 5:
		{
			CreateParticle(-1, "gas_can_impact_red", false, "", 1.0, clientvec);
		}
	}
	EmitSoundToAll(SOUND_JAR_EXPLOSION, entity, -1, 80, 0, 0.8);
	SDKUnhook(entity, SDKHook_Touch, OnTouchExplodeJar);
	jarateType[entity] = -1;
	RemoveEntity(entity);
	return Plugin_Handled;
}
public Action:OnCollisionJarateFrag(entity, client)
{
	decl String:strName[128];
	GetEntityClassname(client, strName, 128)
	decl String:strName1[128];
	GetEntityClassname(entity, strName1, 128)
	new CWeapon = EntRefToEntIndex(jarateWeapon[entity])
	if(IsValidEntity(CWeapon))
	{
		new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
		if(IsValidClient3(owner))
		{
			if(IsValidForDamage(client))
			{
				if(IsOnDifferentTeams(owner,client))
				{
					new Float:damageDealt = 15.0;
					Entity_Hurt(client, RoundToNearest(damageDealt*TF2_GetDamageModifiers(owner, CWeapon, false)), owner, DMG_BULLET);
				}
			}
			new Address:fragmentExplosion = TF2Attrib_GetByName(CWeapon, "overheal decay bonus");
			if(fragmentExplosion != Address_Null && TF2Attrib_GetValue(fragmentExplosion) > 0.0)
			{
				new Float:Radius = 50.0,Float:clientvec[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", clientvec)
				new Address:blastRadius1 = TF2Attrib_GetByName(CWeapon, "Blast radius increased");
				new Address:blastRadius2 = TF2Attrib_GetByName(CWeapon, "Blast radius decreased");
				if(blastRadius1 != Address_Null){
					Radius *= TF2Attrib_GetValue(blastRadius1)
				}
				if(blastRadius2 != Address_Null){
					Radius *= TF2Attrib_GetValue(blastRadius2)
				}
				EntityExplosion(owner, TF2Attrib_GetValue(fragmentExplosion) * TF2_GetDamageModifiers(owner, CWeapon), Radius, clientvec, 0, true, entity, 0.4,_,CWeapon,_,75)
			}
		}
	}
	RemoveEntity(entity);
	return Plugin_Stop;
}
SentryDelay(entity) 
{
	entity = EntRefToEntIndex(entity);
    if(IsValidEdict(entity)) 
    {
		int building = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		//PrintToChatAll("1");
		if(!IsValidClient3(building) && IsValidEntity(building) && HasEntProp(building,Prop_Send,"m_hBuilder"))
		{
			//PrintToChatAll("2");
			new owner = GetEntPropEnt(building,Prop_Send,"m_hBuilder" );
			if(IsValidClient3(owner))
			{
				//PrintToChatAll("3");
				new melee = GetWeapon(owner,2);
				if(IsValidEntity(melee))
				{
					//PrintToChatAll("4");
					new Address:projspeed = TF2Attrib_GetByName(melee, "Projectile speed increased");
					new Address:projspeed1 = TF2Attrib_GetByName(melee, "Projectile speed decreased");
					if(projspeed != Address_Null || projspeed1 != Address_Null)
					{
						//PrintToChatAll("5");
						new Float:vAngles[3];
						new Float:vPosition[3];
						new Float:vBuffer[3];
						new Float:vVelocity[3];
						new Float:vel[3];
						GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPosition);
						GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
						GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", vel); 
						GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
						new Float:projspd = 1.0;
						if(projspeed != Address_Null){
							projspd *= TF2Attrib_GetValue(projspeed)
						}
						if(projspeed1 != Address_Null){
							projspd *= TF2Attrib_GetValue(projspeed1)
						}
						vVelocity[0] = vBuffer[0]*projspd*GetVectorLength(vel);
						vVelocity[1] = vBuffer[1]*projspd*GetVectorLength(vel);
						vVelocity[2] = vBuffer[2]*projspd*GetVectorLength(vel);
						TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
						SetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", vVelocity); 
					}
				}
			}
		}
    } 
}
public Action:meteorCollision(entity, client)
{		
	if(!IsValidEntity(entity))
		return Plugin_Continue;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return Plugin_Continue;
	
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;
	
	if(HasEntProp(entity, Prop_Data, "m_vecOrigin"))
	{
		new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(CWeapon))
		{
			int iItemDefinitionIndex = GetEntProp(CWeapon, Prop_Send, "m_iItemDefinitionIndex");
			if(iItemDefinitionIndex == 595)
			{
				new Float:position[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
				EntityExplosion(owner, TF2_GetDamageModifiers(owner,CWeapon) * 45.0, 250.0, position, 0, _, entity);
				return Plugin_Continue;
			}
		}
	}
		
	return Plugin_Continue;
}
TeleportToNearestPlayer(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEntity(entity))
	{
		new Float:EntityPos[3];
		new Float:distance = 30000.0;
		new Float:ClientPosition[3];
		new ClosestClient = -1;
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", EntityPos); 
		for( new client = 1; client <= MaxClients; client++ )
		{
			if(IsValidClient(client) && !IsClientObserver(client) && IsPlayerAlive(client))
			{ 
				GetClientAbsOrigin(client, ClientPosition);
				if(TF2_GetPlayerClass(client) == TFClass_Scout)
				{
					ClosestClient = client;
					break;
				}
				new Float:CalcDistance = GetVectorDistance(EntityPos,ClientPosition); 
				if(distance > CalcDistance)
				{
					distance = CalcDistance;
					ClosestClient = client;
				}
			}
		}
		if(IsValidClient(ClosestClient))
		{
			TeleportEntity(entity, ClientPosition, NULL_VECTOR, NULL_VECTOR);
		}
	}
}
stock SentryMultishot(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEntity(entity))
	{
		int inflictor = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		int client;
		if(!IsValidClient3(inflictor) && IsValidEntity(inflictor) && HasEntProp(inflictor,Prop_Send,"m_hBuilder"))
		{
			client = GetEntPropEnt(inflictor, Prop_Send, "m_hBuilder");
			if(IsValidClient3(client))
			{
				new melee = (GetPlayerWeaponSlot(client,2));
				if(IsValidEntity(melee))
				{
					new Address:doubleShotActive = TF2Attrib_GetByName(melee, "dmg penalty vs nonstunned");		
					if(doubleShotActive != Address_Null && TF2Attrib_GetValue(doubleShotActive) > 0.0)
					{
						new Handle:hPack = CreateDataPack();
						WritePackCell(hPack, EntIndexToEntRef(inflictor));
						WritePackCell(hPack, EntIndexToEntRef(client));
						WritePackCell(hPack, RoundToCeil(TF2Attrib_GetValue(doubleShotActive)));
						CreateTimer(0.1,ShootTwice,hPack);
					}
				}
			}
		}
	}
}
public Action:ShootTwice(Handle:timer, any:data) 
{  
	ResetPack(data);
	new inflictor = EntRefToEntIndex(ReadPackCell(data));
	new client = EntRefToEntIndex(ReadPackCell(data));
	new timesLeft = ReadPackCell(data);
	if(!IsValidClient3(inflictor) && IsValidEntity(inflictor) && HasEntProp(inflictor,Prop_Send,"m_hBuilder") && timesLeft > 0)
	{
		if(IsValidClient3(client))
		{
			new melee = (GetPlayerWeaponSlot(client,2));
			if(IsValidEntity(melee))
			{
				new Address:doubleShotActive = TF2Attrib_GetByName(melee, "dmg penalty vs nonstunned");
				if(doubleShotActive != Address_Null && TF2Attrib_GetValue(doubleShotActive) > 0.0)
				{
					new iEntity = CreateEntityByName("tf_projectile_sentryrocket");
					if (IsValidEdict(iEntity)) 
					{
						new Float:fAngles[3]
						new Float:fOrigin[3]
						new Float:vBuffer[3]
						new Float:fVelocity[3]
						new Float:fwd[3]
						new iTeam = GetClientTeam(client);
						SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

						SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
						SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
						SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
						SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
									
						new angleOffsetB = FindSendPropInfo("CObjectSentrygun", "m_iAmmoShells") - 16;
						GetEntPropVector( inflictor, Prop_Send, "m_vecOrigin", fOrigin );
						fOrigin[2] += 55.0;
						GetEntDataVector( inflictor, angleOffsetB, fAngles );
						
						GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
						GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(fwd, 30.0);
						
						AddVectors(fOrigin, fwd, fOrigin);
						
						new Float:Speed = 1100.0;
						new Address:projspeed = TF2Attrib_GetByName(melee, "Projectile speed increased");
						new Address:projspeed1 = TF2Attrib_GetByName(melee, "Projectile speed decreased");
						if(projspeed != Address_Null){
							Speed *= TF2Attrib_GetValue(projspeed)
						}
						if(projspeed1 != Address_Null){
							Speed *= TF2Attrib_GetValue(projspeed1)
						}
						fVelocity[0] = vBuffer[0]*Speed;
						fVelocity[1] = vBuffer[1]*Speed;
						fVelocity[2] = vBuffer[2]*Speed;
						
						new Float:ProjectileDamage = 100.0;
						
						new Address:SentryDmgActive = TF2Attrib_GetByName(melee, "engy sentry damage bonus");
						if(SentryDmgActive != Address_Null)
						{
							ProjectileDamage *= TF2Attrib_GetValue(SentryDmgActive);
						}
						SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, ProjectileDamage, true);  
						SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity ); 
						TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
						DispatchSpawn(iEntity);
						timesLeft--;
						if(timesLeft > 0)
						{
							new Handle:hPack = CreateDataPack();
							WritePackCell(hPack, EntIndexToEntRef(inflictor));
							WritePackCell(hPack, EntIndexToEntRef(client));
							WritePackCell(hPack, timesLeft);
							CreateTimer(0.1,ShootTwice,hPack);
						}
					}
				}
			}
		}
	}
	else
	{
		KillTimer(timer)
	}
	CloseHandle(data);
}
public Action:ReEnable(Handle:timer, any:ref) 
{ 
    new entity = EntRefToEntIndex(ref); 

    if(IsValidEdict(entity)) 
    { 
		AcceptEntityInput(entity, "Enable");
		KillTimer(timer)
    }
	else
	{
		KillTimer(timer)
	}
}
public Action:SelfDestruct(Handle:timer, any:ref) 
{ 
    new entity = EntRefToEntIndex(ref); 

    if(IsValidEdict(entity)) 
    { 
		RemoveEntity(entity);
		KillTimer(timer)
    }
	else
	{
		KillTimer(timer)
	}
}
SetZeroGravity(ref)
{
	new entity = EntRefToEntIndex(ref); 
    if(IsValidEdict(entity)) 
    { 
		SetEntityGravity(entity, -0.003);
    }
}
public Action:ArrowThink(Handle:timer, any:ref) 
{ 
	new entity = EntRefToEntIndex(ref); 
    if(IsValidEdict(entity) && !gravChanges[entity]) 
    { 
		SetEntityGravity(entity, 0.001);
    }
	else
	{
		KillTimer(timer)
	}
}
stock void ResizeHitbox(int entity, float fScale)
{
	float vecBossMin[3], vecBossMax[3];
	GetEntPropVector(entity, Prop_Send, "m_vecMins", vecBossMin);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecBossMax);
	
	float vecScaledBossMin[3], vecScaledBossMax[3];
	
	vecScaledBossMin = vecBossMin;
	vecScaledBossMax = vecBossMax;
	
	ScaleVector(vecScaledBossMin, fScale);
	ScaleVector(vecScaledBossMax, fScale);
	
	SetEntPropVector(entity, Prop_Send, "m_vecMins", vecScaledBossMin);
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecScaledBossMax);
}
stock ResizeProjectile(entity)
{
	if(IsValidEntity(entity))
	{
		int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient3(client))
		{
			new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(CWeapon))
			{
				new Address:sizeActive = TF2Attrib_GetByName(CWeapon, "SET BONUS: no death from headshots")
				if(sizeActive != Address_Null)
				{
					new Float:size = TF2Attrib_GetValue(sizeActive);					
					ResizeHitbox(entity, size);
				}
			}
		}
	}
}
public Action:OnStartTouchDelete(entity, other)
{
	if(IsValidEntity(entity) && !IsValidForDamage(other))
	{
		SDKHook(entity, SDKHook_Touch, OnTouchDelete);
	}
	return Plugin_Continue;
}
public Action:OnTouchDelete(entity, other)
{
	RemoveEntity(entity);
	return Plugin_Stop;
}
public Action:OnStartTouch(entity, other)
{
	if (other > 0 && other <= MaxClients)
		return Plugin_Continue;
		
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;
	new maxBounces = 0;
	
	if(HasEntProp(entity, Prop_Data, "m_vecOrigin"))
	{
		new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(CWeapon))
		{
			new Address:bounceActive = TF2Attrib_GetByName(CWeapon, "ReducedCloakFromAmmo")
			if(bounceActive != Address_Null)
			{
				maxBounces = RoundToNearest(TF2Attrib_GetValue(bounceActive));
			}
		}
	}
	
	if (g_nBounces[entity] >= maxBounces)
		return Plugin_Continue;

	SDKHook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}
public Action:OnStartTouchDragonsBreath(entity, other)
{
	if (other > 0 && other <= MaxClients)
		return Plugin_Continue;
		
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;
	
	new maxBounces = 6;
	
	if (g_nBounces[entity] >= maxBounces)
		return Plugin_Continue;

	SDKHook(entity, SDKHook_Touch, OnTouchDrag);
	return Plugin_Handled;
}
public Action:OnStartTouchChaos(entity, other)
{
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;

	SDKHook(entity, SDKHook_Touch, OnTouchChaos);
	return Plugin_Handled;
}
public Action:OnTouchChaos(entity, other)
{
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(IsValidClient(owner))
	{
		new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(CWeapon))
		{
			decl Float:vOrigin[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
			vOrigin[2]+= 30.0;
			EntityExplosion(owner, 25.0, 500.0, vOrigin, 0,_,entity,1.0,1052160,CWeapon,0.75);
			RemoveEntity(entity);
		}
	}
	SDKUnhook(entity, SDKHook_Touch, OnTouchChaos);
	return Plugin_Handled;
}
public Action:OnTouchDrag(entity, other)
{
	decl Float:vOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
	
	decl Float:vAngles[3];
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
	
	decl Float:vVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vVelocity);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TEF_ExcludeEntity, entity);
	
	if(!TR_DidHit(trace))
	{
		CloseHandle(trace);
		return Plugin_Continue;
	}
	
	decl Float:vNormal[3];
	TR_GetPlaneNormal(trace, vNormal);
	
	//PrintToServer("Surface Normal: [%.2f, %.2f, %.2f]", vNormal[0], vNormal[1], vNormal[2]);
	
	CloseHandle(trace);
	
	new Float:dotProduct = GetVectorDotProduct(vNormal, vVelocity);
	
	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);
	
	decl Float:vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);
	
	decl Float:vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);
	
	//PrintToServer("Angles: [%.2f, %.2f, %.2f] -> [%.2f, %.2f, %.2f]", vAngles[0], vAngles[1], vAngles[2], vNewAngles[0], vNewAngles[1], vNewAngles[2]);
	//PrintToServer("Velocity: [%.2f, %.2f, %.2f] |%.2f| -> [%.2f, %.2f, %.2f] |%.2f|", vVelocity[0], vVelocity[1], vVelocity[2], GetVectorLength(vVelocity), vBounceVec[0], vBounceVec[1], vBounceVec[2], GetVectorLength(vBounceVec));
	
	new Handle:datapack = CreateDataPack();
	WritePackCell(datapack,EntIndexToEntRef(entity));
	for(new i=0;i<3;i++)
	{
		WritePackFloat(datapack,0.0);
		WritePackFloat(datapack,vNewAngles[i]);
		WritePackFloat(datapack,vBounceVec[i]);
	}
	
	RequestFrame(DelayedTeleportEntity,datapack);
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(IsValidClient(owner))
	{
		new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(CWeapon))
		{
			vOrigin[2]+= 30.0;
			EntityExplosion(owner, TF2_GetDPSModifiers(owner, CWeapon, false)*35.0, 500.0, vOrigin, 0,_,entity);
		}
	}
	g_nBounces[entity]++;
	SDKUnhook(entity, SDKHook_Touch, OnTouchDrag);
	return Plugin_Handled;
}
public Action:OnTouch(entity, other)
{
	decl Float:vOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
	
	decl Float:vAngles[3];
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
	
	decl Float:vVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vVelocity);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TEF_ExcludeEntity, entity);
	
	if(!TR_DidHit(trace))
	{
		CloseHandle(trace);
		return Plugin_Continue;
	}
	
	decl Float:vNormal[3];
	TR_GetPlaneNormal(trace, vNormal);
	
	//PrintToServer("Surface Normal: [%.2f, %.2f, %.2f]", vNormal[0], vNormal[1], vNormal[2]);
	
	CloseHandle(trace);
	
	new Float:dotProduct = GetVectorDotProduct(vNormal, vVelocity);
	
	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);
	
	decl Float:vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);
	
	decl Float:vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);
	
	//PrintToServer("Angles: [%.2f, %.2f, %.2f] -> [%.2f, %.2f, %.2f]", vAngles[0], vAngles[1], vAngles[2], vNewAngles[0], vNewAngles[1], vNewAngles[2]);
	//PrintToServer("Velocity: [%.2f, %.2f, %.2f] |%.2f| -> [%.2f, %.2f, %.2f] |%.2f|", vVelocity[0], vVelocity[1], vVelocity[2], GetVectorLength(vVelocity), vBounceVec[0], vBounceVec[1], vBounceVec[2], GetVectorLength(vBounceVec));
	
	new Handle:datapack = CreateDataPack();
	WritePackCell(datapack,EntIndexToEntRef(entity));
	for(new i=0;i<3;i++)
	{
		WritePackFloat(datapack,0.0);
		WritePackFloat(datapack,vNewAngles[i]);
		WritePackFloat(datapack,vBounceVec[i]);
	}
	
	RequestFrame(DelayedTeleportEntity,datapack);
	
	CloseHandle(trace);
	g_nBounces[entity]++;
	SDKUnhook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}
public OnHomingThink(entity) 
{ 
	if(IsValidEntity(entity))
	{
		new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient3(owner))
		{
			new Target = GetClosestTarget(entity, owner); 
			if(IsValidClient3(Target))
			{
				if(owner != Target)
				{
					float TargetPos[3];
					GetClientAbsOrigin(Target, TargetPos);
					TargetPos[2]+=40.0;
					float flRocketPos[3];
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", flRocketPos);
					new Float:distance = GetVectorDistance( flRocketPos, TargetPos ); 
					
					if( distance <= projectileHomingDegree[entity] && GetGameTime() - entitySpawnTime[entity] < 3.0 )
					{
						new Float:ProjVector[3], Float:BaseSpeed, Float:NewSpeed, Float:ProjAngle[3], Float:AimVector[3], Float:InitialSpeed[3]; 
						
						GetEntPropVector( entity, Prop_Send, "m_vInitialVelocity", InitialSpeed ); 
						if ( GetVectorLength( InitialSpeed ) < 10.0 ) GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", InitialSpeed ); 
						BaseSpeed = GetVectorLength( InitialSpeed ) * 0.3; 
						
						GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", flRocketPos ); 
						GetClientAbsOrigin( Target, TargetPos ); 
						TargetPos[2] += 20.0;
						MakeVectorFromPoints( flRocketPos, TargetPos, AimVector ); 
						
						if(distance <= projectileHomingDegree[entity]*2.0 + 20.0)
						{
							SubtractVectors( TargetPos, flRocketPos, ProjVector ); //100% HOME
						}
						else
						{
							GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", ProjVector ); //50% HOME
						}
						AddVectors( ProjVector, AimVector, ProjVector ); 
						NormalizeVector( ProjVector, ProjVector );
						
						GetEntPropVector( entity, Prop_Data, "m_angRotation", ProjAngle ); 
						GetVectorAngles( ProjVector, ProjAngle ); 
						
						NewSpeed = ( BaseSpeed * 2.0 ) + 1.0 * BaseSpeed * 1.02; 
						ScaleVector( ProjVector, NewSpeed ); 
						
						TeleportEntity( entity, NULL_VECTOR, ProjAngle, ProjVector ); 
					}
				}
			}
		}
	}
}
public OnThinkPost(entity) 
{ 
	if(IsValidEntity(entity))
	{
		new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient3(owner))
		{
			new Target = GetClosestTarget(entity, owner); 
			if(IsValidClient3(Target))
			{
				new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new Address:homingActive = TF2Attrib_GetByName(CWeapon, "crit from behind");
					if(homingActive != Address_Null)
					{
						new Float:maxDistance = TF2Attrib_GetValue(homingActive)
						if(owner != Target)
						{
							float flTargetPos[3];
							GetClientAbsOrigin(Target, flTargetPos);
							flTargetPos[2]+=40.0;
							float flRocketPos[3];
							GetEntPropVector(entity, Prop_Send, "m_vecOrigin", flRocketPos);
							new Float:distance = GetVectorDistance( flRocketPos, flTargetPos ); 
							
							if( distance <= maxDistance )
							{
								new Float:flVelocityChange[3];
								TeleportEntity(entity, flTargetPos, NULL_VECTOR, flVelocityChange);
							}
						}
					}
				}
			}
		}
	}
}
public Action:HeadshotHomingThink(Handle:timer, any:ref) 
{ 
	new entity = EntRefToEntIndex(ref); 
	new bool:flag = false;
	if(IsValidEntity(entity))
    {
		new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient3(owner))
		{
			new Target = GetClosestTarget(entity, owner); 
			if(IsValidClient3(Target))
			{
				new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new Address:homingActive = TF2Attrib_GetByName(CWeapon, "crit from behind");
					if(homingActive != Address_Null)
					{
						new Float:maxDistance = TF2Attrib_GetValue(homingActive)
						if(owner != Target)
						{
							new Float:EntityPos[3], Float:TargetPos[3]; 
							GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityPos ); 
							GetClientAbsOrigin( Target, TargetPos ); 
							new Float:distance = GetVectorDistance( EntityPos, TargetPos ); 
							
							if( distance <= maxDistance )
							{
								new Float:ProjLocation[3], Float:ProjVector[3], Float:BaseSpeed, Float:NewSpeed, Float:ProjAngle[3], Float:AimVector[3], Float:InitialSpeed[3]; 
								
								GetEntPropVector( entity, Prop_Send, "m_vInitialVelocity", InitialSpeed ); 
								if ( GetVectorLength( InitialSpeed ) < 10.0 ) GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", InitialSpeed ); 
								BaseSpeed = GetVectorLength( InitialSpeed ) * 0.3; 
								
								GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", ProjLocation ); 
								GetClientAbsOrigin(Target, TargetPos);
								TargetPos[2]+=20.0;
								MakeVectorFromPoints( ProjLocation, TargetPos, AimVector ); 
								
								//GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", ProjVector ); //50% HOME
								SubtractVectors( TargetPos, ProjLocation, ProjVector ); //100% HOME
								AddVectors( ProjVector, AimVector, ProjVector ); 
								NormalizeVector( ProjVector, ProjVector ); 
								
								GetEntPropVector( entity, Prop_Data, "m_angRotation", ProjAngle ); 
								GetVectorAngles( ProjVector, ProjAngle ); 
								
								NewSpeed = ( BaseSpeed * 2.0 ) + 1.0 * BaseSpeed * 1.1; 
								ScaleVector( ProjVector, NewSpeed ); 
								
								TeleportEntity( entity, NULL_VECTOR, ProjAngle, ProjVector ); 
								SetEntityGravity(entity, 0.001);
							}
						}
					}
					else
					{
						flag = true;
					}
				}
			}
		}
		else{
		flag = true;
		}
    }
	else{
		flag = true;
	}
	if(flag == true){
		KillTimer(timer);
	}
}
public Action:ThrowableHomingThink(Handle:timer, any:ref) 
{ 
	new entity = EntRefToEntIndex(ref); 
	new bool:flag = false;
	if(IsValidEntity(entity))
    {
		new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient3(owner))
		{
			new Target = GetClosestTarget(entity, owner); 
			if(IsValidClient3(Target))
			{
				new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new Address:homingActive = TF2Attrib_GetByName(CWeapon, "crit from behind");
					if(homingActive != Address_Null)
					{
						new Float:maxDistance = TF2Attrib_GetValue(homingActive)
						if(owner != Target)
						{
							new Float:EntityPos[3], Float:TargetPos[3]; 
							GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityPos ); 
							GetClientAbsOrigin( Target, TargetPos ); 
							new Float:distance = GetVectorDistance( EntityPos, TargetPos ); 
							
							if( distance <= maxDistance )
							{
								new Float:ProjLocation[3], Float:ProjVector[3], Float:NewSpeed, Float:ProjAngle[3], Float:AimVector[3]; 
								
								
								GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", ProjLocation ); 
								GetClientAbsOrigin( Target, TargetPos ); 
								TargetPos[2] += 40.0; 
								
								MakeVectorFromPoints( ProjLocation, TargetPos, AimVector ); 
								
								//GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", ProjVector ); //50% HOME
								SubtractVectors( TargetPos, ProjLocation, ProjVector ); //100% HOME
								AddVectors( ProjVector, AimVector, ProjVector ); 
								NormalizeVector( ProjVector, ProjVector ); 
								
								GetEntPropVector( entity, Prop_Data, "m_angRotation", ProjAngle ); 
								GetVectorAngles( ProjVector, ProjAngle ); 
								
								NewSpeed = 2000.0; 
								ScaleVector( ProjVector, NewSpeed ); 
								
								TeleportEntity( entity, NULL_VECTOR, ProjAngle, ProjVector ); 
								SetEntityGravity(entity, 0.001);
							}
						}
					}
					else
					{
						flag = true;
					}
				}
			}
		}
		else{
		flag = true;
		}
    }
	else{
		flag = true;
	}
	if(flag == true){
		KillTimer(timer);
	}
}
CheckMines(ref)
{
	new entity = EntRefToEntIndex(ref); 
	if(IsValidEntity(entity) && HasEntProp(entity, Prop_Data, "m_hThrower") == true)
    {
        new client = GetEntPropEnt(entity, Prop_Data, "m_hThrower"); 
        if (IsValidClient(client) && IsPlayerAlive(client))
		{
			new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(CWeapon))
			{
				new Address:minesActive = TF2Attrib_GetByName(CWeapon, "enables aoe heal");
				if(minesActive != Address_Null && TF2Attrib_GetValue(minesActive) <= 0.01)
				{
					new Float:damage = 90.0 * TF2_GetDamageModifiers(client,CWeapon);
					new Float:radius = 100.8;
					CreateTimer(0.0,Timer_GrenadeMines,  EntIndexToEntRef(entity), TIMER_REPEAT);
					CreateTimer(TF2Attrib_GetValue(minesActive) * -3.0,SelfDestruct,  EntIndexToEntRef(entity));
					
					new Address:blastRadius1 = TF2Attrib_GetByName(CWeapon, "Blast radius increased");
					new Address:blastRadius2 = TF2Attrib_GetByName(CWeapon, "Blast radius decreased");
					if(blastRadius1 != Address_Null){
						radius *= TF2Attrib_GetValue(blastRadius1)
					}
					if(blastRadius2 != Address_Null){
						radius *= TF2Attrib_GetValue(blastRadius2)
					}
					SetEntPropFloat(entity, Prop_Send, "m_DmgRadius", radius);
					SetEntPropFloat(entity, Prop_Send, "m_flDamage", damage);
					if(TF2Attrib_GetValue(minesActive) > -4.0)
						SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
				}
			}
		}
	}
}
public Action:Timer_GrenadeMines(Handle:timer, any:ref) 
{ 
    new entity = EntRefToEntIndex(ref);
	new bool:flag = false;
	if(IsValidEntity(entity))
	{
		new client = GetEntPropEnt(entity, Prop_Data, "m_hThrower"); 
		if(IsValidClient3(client))
		{
			new Float:distance = GetEntPropFloat(entity, Prop_Send, "m_DmgRadius")
			new Float:damage = GetEntPropFloat(entity, Prop_Send, "m_flDamage")
			new Float:grenadevec[3], Float:targetvec[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", grenadevec);
			for(new i=0; i<=MaxClients; i++)
			{
				if(!IsValidClient3(i)){continue;}
				GetClientAbsOrigin(i, targetvec);
				if(!IsClientObserver(i) && GetClientTeam(i) != GetClientTeam(client) && GetVectorDistance(grenadevec, targetvec, false) < distance)
				{
					if(!TF2Spawn_IsClientInSpawn(i) && client != i && IsAbleToSee(client,i))
					{
						EntityExplosion(client, damage, distance, grenadevec, 0,_,entity);
						RemoveEntity(entity);
						flag = true;
						break;
					}
				}
			}
		}
		else
		{
			flag = true;
		}
	}
	else
	{
		flag = true;
	}
	if(flag == true)
	{
		KillTimer(timer);
	}
}

MultiShot(ref) 
{ 
    new entity = EntRefToEntIndex(ref);
    if(IsValidEdict(entity)) 
    {
		if(debugMode)
			PrintToChatAll("Multishot | ValidEntity");
		new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(HasEntProp(entity, Prop_Data, "m_hThrower"))
		{
			owner = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		}
		if(IsValidClient(owner))
		{
			if(debugMode)
				PrintToChatAll("Multishot | Has Owner");
			if(canShootAgain[owner] == true)
			{
				if(debugMode)
					PrintToChatAll("Multishot | Can Shoot");
				canShootAgain[owner] = false
				new CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new Address:projActive = TF2Attrib_GetByName(CWeapon, "deflection size multiplier");
					new Address:spread1 = TF2Attrib_GetByName(CWeapon, "projectile spread angle penalty");
					if(projActive != Address_Null)
					{
						new Float:spread = 3.0;
						if(spread1 != Address_Null)
						{
							spread += TF2Attrib_GetValue(spread1)
						}
						new Float:projShoot = TF2Attrib_GetValue(projActive)
						for (new v = 0; v < projShoot+1; v++)
						{
							if(RoundToCeil(projShoot+1)/2 != v)
							{
								new String:projName[32];
								GetEntityClassname(entity, projName, 32)
								if(debugMode)
									PrintToChatAll(projName);
								new iEntity = CreateEntityByName(projName);
								if (IsValidEdict(iEntity)) 
								{
									new iTeam = GetClientTeam(owner);
									new Float:fAngles[3]
									new Float:fOrigin[3]
									new Float:vBuffer[3]
									new Float:fVelocity[3]
									new Float:fwd[3]
									SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);

									//SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
									//SetEntityRenderColor(iEntity, 0, 0, 0, 0);
						
									SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
									SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", owner);
									if(HasEntProp(entity, Prop_Send, "m_bCritical") && GetEntProp(entity, Prop_Send, "m_bCritical", 4) == 1){
									SetEntProp(iEntity, Prop_Send, "m_bCritical", 1);
									}
									GetClientEyePosition(owner, fOrigin);
									GetClientEyeAngles(owner, fAngles);
									fAngles[1] -= (spread * projShoot * 0.5);
									fAngles[1] += (v * spread);
									GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
									GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
									ScaleVector(fwd, 100.0);
									AddVectors(fOrigin, fwd, fOrigin);
									new Float:Speed[3];
									new bool:movementType = false;
									if(HasEntProp(entity, Prop_Data, "m_vecAbsVelocity"))
									{
										GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", Speed);
										if(debugMode)
											PrintToChatAll("Multishot | %.2f speed", GetVectorLength(Speed))
										fVelocity[0] = vBuffer[0]*GetVectorLength(Speed);
										fVelocity[1] = vBuffer[1]*GetVectorLength(Speed);
										fVelocity[2] = vBuffer[2]*GetVectorLength(Speed);
										if(GetVectorLength(Speed) > 5.0)
										{
											movementType = true;
										}
									}
									if(movementType == false)
									{
										new Float:velocity = 2000.0;
										new Address:projspeed = TF2Attrib_GetByName(CWeapon, "Projectile speed increased");
										new Address:projspeed1 = TF2Attrib_GetByName(CWeapon, "Projectile speed decreased");
										if(projspeed != Address_Null){
											velocity *= TF2Attrib_GetValue(projspeed)
										}
										if(projspeed1 != Address_Null){
											velocity *= TF2Attrib_GetValue(projspeed1)
										}
										new Float:vecAngImpulse[3];
										GetCleaverAngularImpulse(vecAngImpulse);
										fVelocity[0] = vBuffer[0]*velocity;
										fVelocity[1] = vBuffer[1]*velocity;
										fVelocity[2] = vBuffer[2]*velocity;
										
										//new Float:vecUnknown2[3];
										//vecUnknown2[1] = GetRandomFloat(0.0, 100.0);
										TeleportEntity(iEntity, fOrigin, fAngles, NULL_VECTOR); // fuck it, i'll do it later
										DispatchSpawn(iEntity);
										SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vecAngImpulse, owner, 0, 5.0);
										SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
										if(HasEntProp(iEntity, Prop_Send, "m_hLauncher"))
										{
											SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
										}
										SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", owner);
										if(debugMode)
											PrintToChatAll("Multishot | %.2f speed", GetVectorLength(fVelocity))
										//PrintToChat(owner, "you suck!");
									}
									//Damage Systems.....
									if(StrEqual(projName, "tf_projectile_rocket", false) || StrEqual(projName, "tf_projectile_pipe", false))
									{
										new Float:ProjectileDamage = 90.0;
										
										new Address:DamagePenalty = TF2Attrib_GetByName(CWeapon, "damage penalty");
										new Address:DamageBonus = TF2Attrib_GetByName(CWeapon, "damage bonus");
										new Address:DamageBonusHidden = TF2Attrib_GetByName(CWeapon, "damage bonus HIDDEN");
										
										if(DamagePenalty != Address_Null)
										{
											new Float:dmgmult2 = TF2Attrib_GetValue(DamagePenalty);
											ProjectileDamage *= dmgmult2;
										}
										if(DamageBonus != Address_Null)
										{
											new Float:dmgmult3 = TF2Attrib_GetValue(DamageBonus);
											ProjectileDamage *= dmgmult3;
										}
										if(DamageBonusHidden != Address_Null)
										{
											new Float:dmgmult4 = TF2Attrib_GetValue(DamageBonusHidden);
											ProjectileDamage *= dmgmult4;
										}
										if(StrEqual(projName, "tf_projectile_rocket", false))
										{
											SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, ProjectileDamage, true);
										}
										if(StrEqual(projName, "tf_projectile_pipe", false))
										{
											new Float:radiusMult = 1.0;
											new Address:blastRadius1 = TF2Attrib_GetByName(CWeapon, "Blast radius increased");
											new Address:blastRadius2 = TF2Attrib_GetByName(CWeapon, "Blast radius decreased");
											if(blastRadius1 != Address_Null){
												radiusMult *= TF2Attrib_GetValue(blastRadius1)
											}
											if(blastRadius2 != Address_Null){
												radiusMult *= TF2Attrib_GetValue(blastRadius2)
											}
											SetEntPropFloat(iEntity, Prop_Send, "m_DmgRadius", 144.0 * radiusMult);
											SetEntPropFloat(iEntity, Prop_Send, "m_flDamage", ProjectileDamage);
										} 
									}
									if(movementType == true)
									{
										SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
										TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
										DispatchSpawn(iEntity);
									}
									if(StrEqual(projName, "tf_projectile_arrow", false) || StrEqual(projName, "tf_projectile_healing_bolt", false))
									{
										SDKHook(iEntity, SDKHook_Touch, OnCollisionArrow);
										SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchDelete);
										
										if(StrEqual(projName, "tf_projectile_healing_bolt", false))
										{
											SetEntityModel(iEntity, "models/weapons/w_models/w_syringe_proj.mdl");
											SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 3.0);
										}
										if(StrEqual(projName, "tf_projectile_arrow", false))
										{
											if(iTeam == 2)
											{
												CreateSpriteTrail(iEntity, "1.0", "5.0", "1.0", "materials/effects/arrowtrail_red.vmt", "255 255 255");
											}
											else
											{
												CreateSpriteTrail(iEntity, "1.0", "5.0", "1.0", "materials/effects/arrowtrail_blu.vmt", "255 255 255");
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
    }
}
PrecisionHoming(entity) 
{
	entity = EntRefToEntIndex(entity);
    if(IsValidEdict(entity)) 
    { 
		int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient3(client))
		{
			new Address:precisionPowerup = TF2Attrib_GetByName(client, "refill_ammo");
			if(precisionPowerup != Address_Null && TF2Attrib_GetValue(precisionPowerup) > 0.0)
			{
				projectileHomingDegree[entity] = 200.0;
			}
		}
    } 
}
ProjSpeedDelay(entity) 
{
	entity = EntRefToEntIndex(entity);
    if(IsValidEdict(entity)) 
    { 
		int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient(client))
		{
			new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(ClientWeapon))
			{
				new Address:projspeed = TF2Attrib_GetByName(ClientWeapon, "Projectile speed increased");
				if(projspeed != Address_Null)
				{
					new Float:vAngles[3];
					new Float:vPosition[3];
					new Float:vBuffer[3];
					new Float:vVelocity[3];
					new Float:vel[3];
					GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPosition);
					GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
					GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
					GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					new Float:projspd = TF2Attrib_GetValue(projspeed);
					vVelocity[0] = vBuffer[0]*projspd*GetVectorLength(vel);
					vVelocity[1] = vBuffer[1]*projspd*GetVectorLength(vel);
					vVelocity[2] = vBuffer[2]*projspd*GetVectorLength(vel);
					TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
				}
			}
		}
    } 
}
projGravity(entity) 
{
	entity = EntRefToEntIndex(entity);
    if(IsValidEdict(entity)) 
    { 
	//PrintToChatAll("START | movetype = %i | gravity = %.2f", GetEntityMoveType(entity), GetEntityGravity(entity));
		//PrintToChatAll("0");
		new client;
		if(HasEntProp(entity, Prop_Data, "m_hThrower"))
		{
			client = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		}
		else if(HasEntProp(entity, Prop_Data, "m_hOwnerEntity"))
		{
			client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		}
		if(IsValidClient3(client))
		{
			//PrintToChatAll("1");
			new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(ClientWeapon))
			{
				//PrintToChatAll("2");
				new Address:projgravity = TF2Attrib_GetByName(ClientWeapon, "cloak_consume_on_feign_death_activate");
				if(projgravity != Address_Null)
				{
					//PrintToChatAll("3");
					if(GetEntityMoveType(entity) != MOVETYPE_VPHYSICS)
					{
						SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
						SetEntityGravity(entity, TF2Attrib_GetValue(projgravity));
						RequestFrame(PrecisionHoming, EntIndexToEntRef(entity));
					}
					else
					{
						if(HasEntProp(entity, Prop_Data, "m_angRotation"))
						{
							new Float:flAng[3],Float:fVelocity[3],Float:vBuffer[3];
							new Float:velocity = 2000.0;
							GetEntPropVector(entity, Prop_Data, "m_angRotation", flAng);
							
							GetAngleVectors(flAng, vBuffer, NULL_VECTOR, NULL_VECTOR);
							
							fVelocity[0] = vBuffer[0]*velocity;
							fVelocity[1] = vBuffer[1]*velocity;
							fVelocity[2] = vBuffer[2]*velocity;
							//SetEntPropVector(entity, Prop_Data, "m_vecVelocity", fVelocity);
							TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, fVelocity);
							SetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", fVelocity);
							SetEntPropVector(entity, Prop_Data, "m_angRotation", flAng);
						}
						Phys_EnableGravity(entity, false);
					}
					//PrintToChatAll("END | movetype = %i | gravity = %.2f", GetEntityMoveType(entity), GetEntityGravity(entity));
				}
			}
		}
    } 
}
setProjGravity(entity, Float:gravity) 
{
    if(IsValidEntity(entity)) 
    {
		SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
		SetEntityGravity(entity, gravity);
    } 
}
instantProjectile(entity) 
{
    if(IsValidEdict(entity)) 
    { 
		int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient(client))
		{
			new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(ClientWeapon))
			{
				new Address:projspeed = TF2Attrib_GetByName(ClientWeapon, "Projectile speed increased");
				if(projspeed != Address_Null && TF2Attrib_GetValue(projspeed) >= 100.0)
				{
					new Float:vAngles[3];
					new Float:vPosition[3];
					new Float:vBuffer[3];
					new Float:vVelocity[3];
					new Float:vel[3];
					GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPosition);
					GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
					GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
					GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					new Float:projspd = 500.0;
					vVelocity[0] = vBuffer[0]*projspd*GetVectorLength(vel);
					vVelocity[1] = vBuffer[1]*projspd*GetVectorLength(vel);
					vVelocity[2] = vBuffer[2]*projspd*GetVectorLength(vel);
					TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
				}
			}
		}
    } 
}
/*public Action:Command_levels(client, args)
{
	new String:args1[128];

	if(GetCmdArg(1, args1, sizeof(args1)))
	{
		LevelsToggle = StringToInt(args1);
	}
	return Plugin_Handled;
}*/
public Action:Command_GiveKills(client, args)
{
	new String:args3[128];
	new kills;
	new victim;
	
	new String:strTarget[MAX_TARGET_LENGTH], String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new String:strTarget2[MAX_TARGET_LENGTH], String:target_name2[MAX_TARGET_LENGTH],target_list2[MAXPLAYERS], target_count2, bool:tn_is_ml2;
	GetCmdArg(2, strTarget2, sizeof(strTarget2));
	if((target_count2 = ProcessTargetString(strTarget2, client, target_list2, MAXPLAYERS, 0, target_name2, sizeof(target_name2), tn_is_ml2)) <= 0)
	{
		ReplyToTargetError(client, target_count2);
		return Plugin_Handled;
	}
	
	PrintToServer("Attempting to give kills.");
	for(new i = 0; i < target_count; i++)
	{
		if(GetCmdArg(3, args3, sizeof(args3)) && IsValidClient3(target_list[i]) && IsValidClient3(target_list2[i]))
		{
			victim = target_list2[i];
			kills = StringToInt(args3);
			PrintToServer("Attempting to give %i kills to %N. %N is the victim.",kills,target_list[i],target_list2[i]);
			if(IsValidClient3(target_list[i]) && IsPlayerAlive(target_list[i]) && IsValidClient3(victim) && IsPlayerAlive(victim))
			{
				new Handle:datapack = CreateDataPack();
				WritePackCell(datapack,EntIndexToEntRef(victim));
				WritePackCell(datapack,EntIndexToEntRef(target_list[i]));
				CreateTimer(0.1,Timer_KillPlayer,datapack);
				StrangeFarming[victim][target_list[i]] = kills;
				PrintToServer("Giving %i kills to %N. %N is the victim.",kills,target_list[i],victim);
			}
		}
	}
	return Plugin_Handled;
}
public Action:Timer_KillPlayer(Handle:timer,Handle:datapack)
{
	ResetPack(datapack);
	new victim = EntRefToEntIndex(ReadPackCell(datapack));
	new attacker = EntRefToEntIndex(ReadPackCell(datapack));
	if(IsValidClient3(victim) && IsValidClient3(attacker) && StrangeFarming[victim][attacker] > 0)
	{
		new currentWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(currentWeapon))
		{
			SDKHooks_TakeDamage(victim,attacker,attacker,100000000.0, DMG_GENERIC,currentWeapon,NULL_VECTOR,NULL_VECTOR)
			TF2_RespawnPlayer(victim);
			
			new Handle:Newdatapack = CreateDataPack();
			WritePackCell(Newdatapack,EntIndexToEntRef(victim));
			WritePackCell(Newdatapack,EntIndexToEntRef(attacker));
			CreateTimer(0.1,Timer_KillPlayer,Newdatapack);
			StrangeFarming[victim][attacker]--;
		}
	}
	CloseHandle(datapack);
}
static int GetClientFromPlayerShared(Address pPlayerShared) {
	Address pOuter = DereferencePointer(pPlayerShared + g_offset_CTFPlayerShared_pOuter);
	return GetEntityFromAddress(pOuter);
}