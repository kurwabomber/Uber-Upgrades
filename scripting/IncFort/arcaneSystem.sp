//Arcane Menu
public Menu_ShowArcane(client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		Handle menu = CreateMenu(MenuHandler_ArcaneCast);
		int attunement = 1 + RoundToNearest(GetAttribute(client, "arcane attunement slots",0.0));
		
		SetMenuExitBackButton(menu, true);
		SetMenuTitle(menu, "Use Arcane Spells");
		for (int s = 0; s < attunement; s++)
		{
			char fstr[32]
			Format(fstr, sizeof(fstr), "Use Arcane Spell #%i", s+1);
			AddMenuItem(menu, "spell", fstr);
		}
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
	}
	return;
}
public MenuHandler_ArcaneCast(Handle menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select && IsValidClient(client) && IsPlayerAlive(client))
	{
		RequestFrame(Menu_ShowArcane, client);
		CloseHandle(menu);

		if(param2 < 0 || param2 > Max_Attunement_Slots)
			return;

		if(AttunedSpells[client][param2] == 0.0)
			{PrintHintText(client, "You have nothing attuned to this slot!");return;}

		if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{PrintHintText(client, "You cannot cast spells while invisible.");return;}

		if(TF2_IsPlayerInCondition(client, TFCond_Disguised))
		{
			TF2_RemoveCondition(client, TFCond_Disguised);
		}
		switch(AttunedSpells[client][param2])
		{
			case 1.0:
			{
				CastZap(client, param2);
			}
			case 2.0:
			{
				CastLightning(client, param2);
			}
			case 3.0:
			{
				CastHealing(client, param2);
			}
			case 4.0:
			{
				CastACallBeyond(client, param2);
			}
			case 5.0:
			{
				CastBlackskyEye(client, param2);
			}
			case 6.0:
			{
				CastSunlightSpear(client, param2);
			}
			case 7.0:
			{
				CastLightningEnchantment(client, param2);
			}
			case 8.0:
			{
				CastSnapFreeze(client, param2);
			}
			case 9.0:
			{
				CastArcanePrison(client, param2);
			}
			case 10.0:
			{
				CastDarkmoonBlade(client, param2);
			}
			case 11.0:
			{
				CastSpeedAura(client, param2);
			}
			case 12.0:
			{
				CastAerialStrike(client, param2);
			}
			case 13.0:
			{
				CastInferno(client, param2);
			}
			case 14.0:
			{
				CastMineField(client, param2);
			}
			case 15.0:
			{
				CastShockwave(client, param2);
			}
			case 16.0:
			{
				CastAutoSentry(client, param2);
			}						
			case 17.0:
			{
				CastSoothingSunlight(client, param2);
			}
			case 18.0:
			{
				CastArcaneHunter(client, param2);
			}
			case 19.0:
			{
				CastMarkForDeath(client, param2);
			}
			default:
			{
				PrintHintText(client, "Sorry, we havent implemented this yet!");
			}
		}
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		CloseHandle(menu);
		Menu_BuyUpgrade(client, 0);
	}
	return; 
}
public Action:Command_UseArcane(client, args)
{
	char arg1[128];
	int param2;
	if (!GetCmdArg(1, arg1, sizeof(arg1)))
		return Plugin_Handled;
	
	param2 = StringToInt(arg1)-1;
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (IsPlayerAlive(client))
		return Plugin_Handled;


	Address slotActive = TF2Attrib_GetByName(client, "arcane attunement slots");
	int attuneSlots = 1 + (slotActive == Address_Null ? 0 : RoundToNearest(TF2Attrib_GetValue(slotActive)));

	if(param2 < 0 && param2 > attuneSlots) 
		return Plugin_Handled;

	if(AttunedSpells[client][param2] == 0.0)
		{PrintHintText(client, "You have nothing attuned to this slot!");return Plugin_Handled;}

	if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		{PrintHintText(client, "You cannot cast spells while invisible.");return Plugin_Handled;}

	if(TF2_IsPlayerInCondition(client, TFCond_Disguised))
		TF2_RemoveCondition(client, TFCond_Disguised);

	switch(AttunedSpells[client][param2])
	{
		case 1.0:
		{
			CastZap(client, param2);
		}
		case 2.0:
		{
			CastLightning(client, param2);
		}
		case 3.0:
		{
			CastHealing(client, param2);
		}
		case 4.0:
		{
			CastACallBeyond(client, param2);
		}
		case 5.0:
		{
			CastBlackskyEye(client, param2);
		}
		case 6.0:
		{
			CastSunlightSpear(client, param2);
		}
		case 7.0:
		{
			CastLightningEnchantment(client, param2);
		}
		case 8.0:
		{
			CastSnapFreeze(client, param2);
		}
		case 9.0:
		{
			CastArcanePrison(client, param2);
		}
		case 10.0:
		{
			CastDarkmoonBlade(client, param2);
		}
		case 11.0:
		{
			CastSpeedAura(client, param2);
		}
		case 12.0:
		{
			CastAerialStrike(client, param2);
		}
		case 13.0:
		{
			CastInferno(client, param2);
		}
		case 14.0:
		{
			CastMineField(client, param2);
		}
		case 15.0:
		{
			CastShockwave(client, param2);
		}
		case 16.0:
		{
			CastAutoSentry(client, param2);
		}						
		case 17.0:
		{
			CastSoothingSunlight(client, param2);
		}
		case 18.0:
		{
			CastArcaneHunter(client, param2);
		}
		case 19.0:
		{
			CastMarkForDeath(client, param2);
		}
		default:
		{
			PrintHintText(client, "Sorry, we havent implemented this yet!");
		}
	}
	return Plugin_Handled;
}


//Arcane Spells
CastMarkForDeath(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane mark for death", 0.0));
	if(spellLevel < 1)
		return;
	if(applyArcaneRestrictions(client, attuneSlot, fl_MaxFocus[client]*0.5, 25.0))
		return; 

	float clientpos[3];
	TracePlayerAim(client, clientpos);
	float Range = 900.0*ArcanePower[client];
	for(int i = 1; i<MAXENTITIES;i++)
	{
		if(!IsValidForDamage(i))
			continue;
		if(!IsOnDifferentTeams(client,i))
			continue;

		float VictimPos[3];
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
		VictimPos[2] += 30.0;
		float Distance = GetVectorDistance(clientpos,VictimPos);
		if(Distance > Range)
			continue;

		if(!IsPointVisible(clientpos,VictimPos))
			continue;

		if(IsValidClient3(i))
		{
			TF2_AddCondition(i, TFCond_Sapped, 10.0);
			TF2Attrib_SetByName(i,"CARD: move speed bonus", 0.5);
			TF2Attrib_SetByName(i,"major increased jump height", 0.5);
			CreateTimer(10.0, DisableSlowdown, EntIndexToEntRef(i));
		}
		else if(HasEntProp(i,Prop_Send,"m_hBuilder"))
		{
			SetEntProp(i, Prop_Send, "m_bDisabled", 1);
			CreateTimer(5.0, ReEnableBuilding, EntIndexToEntRef(i));
		}
	}
	EmitSoundToAll(SOUND_SABOTAGE, _, client, SNDLEVEL_SNOWMOBILE, _, 1.0, _,_,clientpos);
}
CastSunlightSpear(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane sunlight spear", 0.0));
	if(spellLevel < 1)
		return;
	if(applyArcaneRestrictions(client, attuneSlot, 30.0 + (20.0 * ArcaneDamage[client]), 0.4))
		return; 

	float clientpos[3];
	GetClientEyePosition(client,clientpos);
	EmitSoundToAll(SOUND_CALLBEYOND_CAST, _, client, SNDLEVEL_NORMAL, _, 0.8, _,_,clientpos);
	int iEntity = CreateEntityByName("tf_projectile_arrow");
	if (!IsValidEdict(iEntity)) 
		return;
	float fAngles[3]
	float fOrigin[3]
	float vBuffer[3]
	float fVelocity[3]
	float fwd[3]
	int iTeam = GetClientTeam(client);
	SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

	SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
	SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
	SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
	//SetEntProp(iEntity, Prop_Send, "m_bCritical", 1);
				
	GetClientEyePosition(client, fOrigin);
	GetClientEyeAngles(client,fAngles);
	
	GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fwd, 30.0);
	
	AddVectors(fOrigin, fwd, fOrigin);
	
	float Speed = 3000.0;
	fVelocity[0] = vBuffer[0]*Speed;
	fVelocity[1] = vBuffer[1]*Speed;
	fVelocity[2] = vBuffer[2]*Speed;
	SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
	TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
	DispatchSpawn(iEntity);
	SDKHook(iEntity, SDKHook_Touch, OnSunlightSpearCollision);
	
	for(int it = 0;it < 3;it++)
	{
		int iParticle = CreateParticle(iEntity, "raygun_projectile_red_crit_trail", true, "", 4.0);
		TeleportEntity(iParticle, NULL_VECTOR, fAngles, NULL_VECTOR);
	}
	
	int iParticle2 = CreateParticle(iEntity, "raygun_projectile_red_trail", true, "", 4.0);
	TeleportEntity(iParticle2, NULL_VECTOR, fAngles, NULL_VECTOR);
	
	TE_SetupKillPlayerAttachments(iEntity);
	TE_SendToAll();
	int color[4]={255, 200, 0,225};
	TE_SetupBeamFollow(iEntity,Laser,0,0.5,3.0,3.0,1,color);
	TE_SendToAll();
}
CastLightningEnchantment(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane lightning enchantment", 0.0));
	if(spellLevel < 1)
		return;
	if(applyArcaneRestrictions(client, attuneSlot, 150.0 + (40.0 * ArcaneDamage[client]), 30.0))
		return; 
		
	LightningEnchantment[client] = (10.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 4.0));
	LightningEnchantmentDuration[client] = 20.0 * ArcanePower[client];	
}
CastDarkmoonBlade(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane darkmoon blade", 0.0));
	if(spellLevel < 1)
		return;
	if(applyArcaneRestrictions(client, attuneSlot, 100.0 + (20.0 * ArcaneDamage[client]), 25.0))
		return; 
	
	DarkmoonBlade[client] = (10.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 4.5));
	DarkmoonBladeDuration[client] = 20.0 * ArcanePower[client];
}
CastSnapFreeze(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane snap freeze", 0.0));
	if(spellLevel < 1)
		return;

	if(applyArcaneRestrictions(client, attuneSlot, 50.0 + (20.0 * ArcaneDamage[client]), 9.0))
		return; 

	float clientpos[3];
	GetClientEyePosition(client, clientpos);
	EmitSoundToAll(SOUND_FREEZE, _, client, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,clientpos);
	float damage = 100.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 60.0);
	for(int i = 1; i<MAXENTITIES;i++)
	{
		if(!IsValidForDamage(i))
			continue;
		if(!IsOnDifferentTeams(client,i))
			continue;

		float VictimPos[3];
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
		VictimPos[2] += 15.0;

		if(GetVectorDistance(clientpos,VictimPos) > 500.0)
			continue;
		
		if(!IsPointVisible(clientpos,VictimPos))
			continue;

		SDKHooks_TakeDamage(i,client,client,damage,DMG_BULLET,-1,NULL_VECTOR,NULL_VECTOR, !IsValidClient3(i));
		if(IsValidClient3(i))
		{
			TF2_AddCondition(i, TFCond_FreezeInput, 0.4);
			TF2_StunPlayer(i, 0.4,1.0,TF_STUNFLAGS_NORMALBONK,client);
		}
	}
	TF2_AddCondition(client, TFCond_ObscuredSmoke, 0.4);
	GetClientAbsOrigin(client, clientpos);
	CreateSmoke(clientpos,0.3,255,255,255,"200","20");
	CreateParticle(client, "utaunt_snowring_icy_parent", true);

}
CastArcanePrison(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane prison", 0.0));
	if(spellLevel < 1)
		return;
	if(applyArcaneRestrictions(client, attuneSlot, 50.0 + (35.0 * ArcaneDamage[client]), 20.0))
		return; 

	float ClientPos[3];
	float ClientAngle[3];
	GetClientEyePosition(client,ClientPos);
	GetClientEyeAngles(client,ClientAngle);
	int iTeam = GetClientTeam(client)
	ClientPos[2] -= 20.0;
	EmitSoundToAll(SOUND_CALLBEYOND_ACTIVE, _, client, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,ClientPos);
	
	int iEntity = CreateEntityByName("tf_projectile_lightningorb");
	if (!IsValidEdict(iEntity)) 
		return;

	float fAngles[3]
	float fOrigin[3]
	float vBuffer[3]
	float fVelocity[3]
	
	if(LookPoint(client,fOrigin))
	{
		SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
		SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
		SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);

		fOrigin[2] += 40.0
		GetClientEyeAngles(client,fAngles);
		
		GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		
		float Speed = 0.0;
		fVelocity[0] = vBuffer[0]*Speed;
		fVelocity[1] = vBuffer[1]*Speed;
		fVelocity[2] = vBuffer[2]*Speed;
		SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
		TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
		DispatchSpawn(iEntity);
	}
}
CastSpeedAura(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane speed aura", 0.0));
	if(spellLevel < 1)
		return;
	if(applyArcaneRestrictions(client, attuneSlot, fl_MaxFocus[client]*0.4, 15.0))
		return; 

	float ClientPos[3];
	GetClientEyePosition(client,ClientPos);
	int iTeam = GetClientTeam(client)
	ClientPos[2] -= 20.0;
	for(int i = 1; i<MaxClients;i++)
	{
		if(!IsValidClient3(i))
			continue;
		if(GetClientTeam(i) != iTeam)
			continue;
		float VictimPos[3];
		GetClientEyePosition(i,VictimPos);
		float Distance = GetVectorDistance(ClientPos,VictimPos);
		float Range = 800.0;
		if(Distance > Range)
			continue;

		TF2_AddCondition(i, TFCond_SpeedBuffAlly, 8.0);
		TF2_AddCondition(i, TFCond_RuneAgility, 8.0);
		TF2_AddCondition(i, TFCond_DodgeChance, 1.5);
	}
	EmitSoundToAll(SOUND_SPEEDAURA, _, client, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,ClientPos);
}
CastAerialStrike(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane aerial strike", 0.0));
	if(spellLevel < 1)
		return;

	if(applyArcaneRestrictions(client, attuneSlot, 50.0 + (45.0 * ArcaneDamage[client]), 50.0))
		return; 

	float ClientPos[3];
	TracePlayerAim(client, ClientPos);
	int iTeam = GetClientTeam(client)
	float ProjectileDamage = 90.0 + (Pow(ArcaneDamage[client]*Pow(ArcanePower[client], 4.0),2.45) * 25.0);
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, client);
	WritePackCell(hPack, iTeam);
	WritePackFloat(hPack, ProjectileDamage);
	
	WritePackFloat(hPack, ClientPos[0]);
	WritePackFloat(hPack, ClientPos[1]);
	WritePackFloat(hPack, ClientPos[2]);
	
	CreateTimer(1.0,aerialStrike,hPack);
	if(iTeam == 2)
	{
		EmitSoundToAll(SOUND_HORN_RED, _, client, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,ClientPos);
		TE_SetupBeamRingPoint(ClientPos, 20.0, 800.0, g_LightningSprite, spriteIndex, 0, 5, 1.0, 10.0, 1.0, {255,0,0,180}, 400, 0);
		TE_SendToAll();
	}
	else
	{
		EmitSoundToAll(SOUND_HORN_BLUE, _, client, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,ClientPos);
		TE_SetupBeamRingPoint(ClientPos, 20.0, 800.0, g_LightningSprite, spriteIndex, 0, 5, 1.0, 10.0, 1.0, {0,0,255,180}, 400, 0);
		TE_SendToAll();
	}
}
public Action:aerialStrike(Handle timer,any:data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	int iTeam = ReadPackCell(data);
	float ProjectileDamage = ReadPackFloat(data);
	float ClientPos[3];
	ClientPos[0] = ReadPackFloat(data);
	ClientPos[1] = ReadPackFloat(data);
	ClientPos[2] = ReadPackFloat(data);
	for(int i = 0;i<30;i++)
	{
		int iEntity = CreateEntityByName("tf_projectile_rocket");
		if (!IsValidEdict(iEntity)) 
			continue;

		float fAngles[3]
		float fOrigin[3]
		float vBuffer[3]
		float fVelocity[3]
		SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
		SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
		SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
		
		fAngles[0] = 89.0;
		fAngles[1] = GetRandomFloat(-150.0,-10.0);
		fAngles[2] = 0.0;
		GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);

		fOrigin = ClientPos;
		fOrigin[0] += GetRandomFloat(-300.0/ArcanePower[client],300.0/ArcanePower[client]);
		fOrigin[1] += GetRandomFloat(-300.0/ArcanePower[client],300.0/ArcanePower[client]);
		fOrigin[2] += 1000.0;
		
		float Speed = 1500.0;
		fVelocity[0] = vBuffer[0]*Speed;
		fVelocity[1] = vBuffer[1]*Speed;
		fVelocity[2] = vBuffer[2]*Speed;
		SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, ProjectileDamage, true);  
		TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
		DispatchSpawn(iEntity);
	}
	CloseHandle(data);
	KillTimer(timer);
}
CastInferno(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane inferno", 0.0));
	if(spellLevel < 1)
		return;
	if(applyArcaneRestrictions(client, attuneSlot, 50.0 + (45.0 * ArcaneDamage[client]), 50.0))
		return;

	float ClientPos[3];
	GetClientEyePosition(client,ClientPos);
	ClientPos[2] -= 20.0;
		
	EmitSoundToAll(SOUND_INFERNO, _, client, SNDLEVEL_ROCKET, _, 1.0, _,_,ClientPos);
	
	//scripting god
	float flamePos[3];
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
	
	
	float DMGDealt = 20.0 + (Pow(ArcaneDamage[client]*Pow(ArcanePower[client], 4.0),2.45) * 12.5);
	for(int i = 1; i<MAXENTITIES;i++)
	{
		if(!IsValidForDamage(i))
			continue;
		if(!IsOnDifferentTeams(client,i))
			continue;

		float VictimPos[3];
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
		float Distance = GetVectorDistance(ClientPos,VictimPos);
		if(Distance > 800.0)
			continue;

		CreateParticle(i, "dragons_fury_effect_parent", true, "", 2.0);
		CreateParticle(i, "utaunt_glowyplayer_orange_glow", true, "", 2.0,_,_,1);
		DOTStock(i,client,DMGDealt,-1,DMG_BURN,20,1.0,0.12,true);
	}
}

CastMineField(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane mine field", 0.0));
	if(spellLevel < 1)
		return;

	if(applyArcaneRestrictions(client, attuneSlot, 50.0 + (45.0 * ArcaneDamage[client]), 50.0))
		return;
		
	float ClientPos[3];
	TracePlayerAim(client, ClientPos);
	int iTeam = GetClientTeam(client)
	
		
	float radius = 300.0*ArcanePower[client];
	float damage = 90.0 + (Pow(ArcaneDamage[client]*Pow(ArcanePower[client], 4.0),2.45) * 6.5);
	for(int i = 0;i<20;i++)
	{
		int iEntity = CreateEntityByName("tf_projectile_pipe_remote");
		if (!IsValidEdict(iEntity)) 
			continue;
		float fAngles[3]
		float fOrigin[3]
		float vBuffer[3]
		float fVelocity[3]
		SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
		SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
		SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
		SetEntPropEnt(iEntity, Prop_Data, "m_hThrower", client)
		
		SetEntPropFloat(iEntity, Prop_Send, "m_DmgRadius", radius);
		SetEntPropFloat(iEntity, Prop_Send, "m_flDamage", damage);
		
		fAngles[0] = 89.0;
		fAngles[1] = GetRandomFloat(-150.0,-10.0);
		fAngles[2] = 0.0;
		GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);

		fOrigin = ClientPos;
		fOrigin[0] += GetRandomFloat(-300.0/ArcanePower[client],300.0/ArcanePower[client]);
		fOrigin[1] += GetRandomFloat(-300.0/ArcanePower[client],300.0/ArcanePower[client]);
		fOrigin[2] += 10.0;
		
		float Speed = 1500.0;
		fVelocity[0] = vBuffer[0]*Speed;
		fVelocity[1] = vBuffer[1]*Speed;
		fVelocity[2] = vBuffer[2]*Speed;
		TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
		DispatchSpawn(iEntity);
		RequestFrame(CheckMines, iEntity);
		SetEntityModel(iEntity, "models/weapons/w_models/w_stickybomb3.mdl");
	}
}
public void CheckMines(ref)
{
	int entity = EntRefToEntIndex(ref); 
	if(!IsValidEntity(entity))
		return;
	if(!HasEntProp(entity, Prop_Data, "m_hThrower"))
		return;
    
	int client = GetEntPropEnt(entity, Prop_Data, "m_hThrower"); 
	if (!IsValidClient(client))
		return;
	if(!IsPlayerAlive(client))
		return;
	
	CreateTimer(0.1,Timer_GrenadeMines,  EntIndexToEntRef(entity), TIMER_REPEAT);
	CreateTimer(20.0,SelfDestruct,  EntIndexToEntRef(entity));
	SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
	lastMinesTime[client] = GetGameTime();
}
public Action:Timer_GrenadeMines(Handle timer, any:ref) 
{ 
    int entity = EntRefToEntIndex(ref);
	if(!IsValidEntity(entity)){KillTimer(timer);return;}

	int client = GetEntPropEnt(entity, Prop_Data, "m_hThrower"); 
	if(!IsValidClient3(client)){KillTimer(timer);return;}

	float distance = GetEntPropFloat(entity, Prop_Send, "m_DmgRadius")
	float damage = GetEntPropFloat(entity, Prop_Send, "m_flDamage")
	float timeMod = 1.0+((GetGameTime()-lastMinesTime[client])*0.35);
	float grenadevec[3], targetvec[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", grenadevec);
	
	for(int i=1; i<=MaxClients; i++)
	{
		if(!IsValidClient3(i))
			continue;

		if(IsClientObserver(i))
			continue;

		if(GetClientTeam(i) == GetClientTeam(client))
			continue;

		GetClientAbsOrigin(i, targetvec);
		if(GetVectorDistance(grenadevec, targetvec, false) > distance)
			continue;

		if(TF2Spawn_IsClientInSpawn(i))
			continue;

		if(!IsAbleToSee(client,i))
			continue;

		EntityExplosion(client, damage*timeMod, distance, grenadevec, 0,_,entity);
		RemoveEntity(entity);
		KillTimer(timer);
		break;
	}
}
CastShockwave(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane shockwave", 0.0));
	if(spellLevel < 1)
		return;
	if(applyArcaneRestrictions(client, attuneSlot, 50.0 + (30.0 * ArcaneDamage[client]), 20.0))
		return; 


	float ClientPos[3];
	GetClientEyePosition(client,ClientPos);
	ClientPos[2] -= 20.0;
		
	float damageDealt = (100.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 60.0));
	for(int i = 1; i<MAXENTITIES;i++)
	{
		if(!IsValidForDamage(i))
			continue;
		if(!IsOnDifferentTeams(client,i))
			continue;

		float VictimPos[3];
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
		VictimPos[2] += 15.0;

		if(!IsPointVisible(ClientPos,VictimPos))
			continue;

		if(GetVectorDistance(ClientPos,VictimPos) > 500.0)
			continue;

		SDKHooks_TakeDamage(i,client,client,damageDealt,DMG_BULLET,-1,NULL_VECTOR,NULL_VECTOR, !IsValidClient3(i));
		if(IsValidClient3(i))
		{
			TF2_AddCondition(i, TFCond_FreezeInput, 0.4);
			TF2_StunPlayer(i, 2.25,1.0,TF_STUNFLAGS_NORMALBONK,client);
			PushEntity(i,client,900.0,200.0);
		}
	}
	TF2_AddCondition(client, TFCond_ObscuredSmoke, 0.4);
	EmitSoundToAll(SOUND_SHOCKWAVE, _, client, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,ClientPos);
	CreateParticle(client, "bombinomicon_burningdebris", true, "", 1.0);
}
CastAutoSentry(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane autosentry", 0.0));
	if(spellLevel < 1)
		return;
	if(applyArcaneRestrictions(client, attuneSlot, fl_MaxFocus[client], 80.0))
		return; 
	int iTeam = GetClientTeam(client)
		
	int iEntity = CreateEntityByName("obj_sentrygun");
	if(!IsValidEntity(iEntity))
		return;

	int iLink = CreateLink(client,true);
	float angles[3];
	float position[3];
	//angles[0] -= 180.0;
	//angles[1] -= 90.0;
	//angles[2] += 90.0;
	
	//position[0] -= 30.0;
	//position[1] += 20.0;
	position[2] -= 75.0;
	
	SetVariantString("!activator");
	AcceptEntityInput(iEntity, "SetParent", iLink);  
	SetVariantString("head"); 
	AcceptEntityInput(iEntity, "SetParentAttachment", iLink); 
	SetEntPropEnt(iEntity, Prop_Send, "m_hEffectEntity", iLink);
	SetEntPropVector(iEntity, Prop_Send, "m_angRotation", angles);
	TeleportEntity(iEntity, position, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(iEntity);
	SetEntProp(iEntity, Prop_Data, "m_spawnflags", 8);
	SetEntProp(iEntity, Prop_Data, "m_takedamage", 0);
	SetEntProp(iEntity, Prop_Send, "m_iUpgradeLevel", 3);
	SetEntProp(iEntity, Prop_Send, "m_iHighestUpgradeLevel", 3);
	SetEntProp(iEntity, Prop_Send, "m_nSkin", iTeam);
	SetEntProp(iEntity, Prop_Send, "m_bBuilding", 1);
	SetEntProp(iEntity, Prop_Send, "m_nSolidType", 0);
	SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0004);
	SetEntProp(iEntity, Prop_Send, "m_hBuiltOnEntity", client);

	SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 0.3);
	SetVariantInt(iTeam);
	AcceptEntityInput(iEntity, "SetTeam");
	SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam)
	SetEntPropEnt(iEntity, Prop_Send, "m_hBuilder", client); 
	SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client); 
	
	CreateTimer(10.0,SelfDestruct,  EntIndexToEntRef(iEntity));
	CreateTimer(10.0,SelfDestruct,  EntIndexToEntRef(iLink));
	CreateTimer(10.0,RemoveAutoSentryID, EntIndexToEntRef(client));
	autoSentryID[client] = iEntity;
}
public Action:RemoveAutoSentryID(Handle timer, any:ref) 
{
	ref = EntRefToEntIndex(ref)
	autoSentryID[ref] = -1;
}
CastSoothingSunlight(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane soothing sunlight", 0.0));
	if(spellLevel < 1)
		return;

	if(applyArcaneRestrictions(client, attuneSlot, fl_MaxFocus[client], 180.0))
		return; 

	float ClientPos[3];
	GetClientEyePosition(client,ClientPos);
	ClientPos[2] -= 40.0;
		
	CreateTimer(4.0,SoothingSunlight,EntIndexToEntRef(client));
	TF2_StunPlayer(client,5.0,0.0,TF_STUNFLAGS_BIGBONK,0);
	TE_SetupBeamRingPoint(ClientPos, 20.0, 800.0, g_LightningSprite, spriteIndex, 0, 5, 4.0, 10.0, 1.0, {255,255,0,180}, 400, 0);
	TE_SendToAll();
}
public Action:SoothingSunlight(Handle timer, client) 
{
	client = EntRefToEntIndex(client)
	if(!IsPlayerAlive(client))
		return;

	int iTeam = GetClientTeam(client)
	float ClientPos[3];
	GetClientEyePosition(client,ClientPos);
	for(int i = 1; i<MaxClients;i++)
	{
		if(!IsValidClient3(i))
			continue;

		if(GetClientTeam(i) != iTeam)
			continue;

		float VictimPos[3];
		GetClientEyePosition(i,VictimPos);
		float Distance = GetVectorDistance(ClientPos,VictimPos);
		if(Distance > 1350.0)
			continue;

		float AmountHealing = TF2_GetMaxHealth(i) * 4.0 * ArcanePower[client];
		AddPlayerHealth(i, RoundToCeil(AmountHealing), 4.0 * ArcanePower[client], true, client);
		fl_CurrentArmor[i] += AmountHealing * 3.0 * ArcanePower[client];
		if(fl_AdditionalArmor[i] < fl_MaxArmor[i] * ArcanePower[client])
			fl_AdditionalArmor[i] = fl_MaxArmor[i] * ArcanePower[client];
		TF2_AddCondition(i,TFCond_MegaHeal,6.5);
	
		float particleOffset[3] = {0.0,0.0,15.0};
		CreateParticle(i, "utaunt_glitter_parent_gold", true, "", 5.0, particleOffset);
	}
	EmitSoundToAll(SOUND_HEAL, _, client, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,ClientPos);
}
CastArcaneHunter(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane hunter", 0.0));
	if(spellLevel < 1)
		return;
	if(applyArcaneRestrictions(client, attuneSlot, 200.0 + (70.0 * ArcaneDamage[client]), 40.0))
		return; 

	float CPOS[3];
	GetClientEyePosition(client,CPOS)
	
	for(int i=0;i<30;i++)
	{
		EmitSoundToAll(SOUND_ARCANESHOOTREADY, _, client, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,CPOS);
	}
	
	float particleOffset[3] = {0.0,0.0,90.0};
	int iParticle = CreateParticle(client, "unusual_psychic_eye", true, "", 3.5, particleOffset);
	if(!IsValidEdict(iParticle))
	{
		Handle pack;
		CreateDataTimer(3.0, Timer_MoveParticle, pack);
		WritePackCell(pack, EntIndexToEntRef(iParticle));
	}

	CreateTimer(0.4,ArcaneHunter,client);
	CreateTimer(0.8,ArcaneHunter,client);
	CreateTimer(1.2,ArcaneHunter,client);
	CreateTimer(1.6,ArcaneHunter,client);
	CreateTimer(2.0,ArcaneHunter,client);
}
public Action:ArcaneHunter(Handle timer, client) 
{
	if(!IsPlayerAlive(client))
		return;

	float clientpos[3];
	float soundPos[3];
	float clientAng[3];
	float fwd[3];
	TracePlayerAim(client, clientpos);
	
	for(int i=1;i<MaxClients;i++)
	{
		if(!IsValidClient3(i))
			continue;
		
		if(!IsOnDifferentTeams(client,i))
			continue;
		
		if(!IsTargetInSightRange(client, i, 10.0, 6000.0, true, false))
			continue;

		if(!IsAbleToSee(client,i, false))
			continue;
			
		GetClientEyePosition(i,clientpos);
		break;
	}
	
	GetClientEyePosition(client, soundPos);
	GetClientEyeAngles(client, clientAng);
	EmitSoundToAll(SOUND_ARCANESHOOT, _, client, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,soundPos);
	// define the direction of the sparks
	float dir[3] = {0.0, 0.0, 0.0};
	
	TE_SetupEnergySplash(clientpos, dir, false);
	TE_SendToAll();
	
	TE_SetupSparks(clientpos, dir, 5000, 1000);
	TE_SendToAll();
	
	float particleOffset[3] = {0.0,0.0,75.0};
	char particleName[32];
	particleName = GetClientTeam(client) == 2 ? "muzzle_raygun_red" : "muzzle_raygun_blue";
	
	GetAngleVectors(clientAng,fwd, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fwd, 30.0);
	AddVectors(particleOffset, fwd, particleOffset);
	
	CreateParticle(client, particleName, false, "", 0.5, particleOffset);
	
	int iParti = CreateEntityByName("info_particle_system");
	int iPart2 = CreateEntityByName("info_particle_system");

	if (IsValidEntity(iParti) && IsValidEntity(iPart2))
	{ 
		char szCtrlParti[32];
		Format(szCtrlParti, sizeof(szCtrlParti), "tf2ctrlpart%i", iPart2);
		DispatchKeyValue(iPart2, "targetname", szCtrlParti);
		DispatchKeyValue(iParti, "effect_name", "merasmus_zap");
		DispatchKeyValue(iParti, "cpoint1", szCtrlParti);
		DispatchSpawn(iParti);
		TeleportEntity(iParti, soundPos, clientAng, NULL_VECTOR);
		TeleportEntity(iPart2, clientpos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(iParti);
		AcceptEntityInput(iParti, "Start");
		
		Handle pack;
		CreateDataTimer(1.0, Timer_KillParticle, pack);
		WritePackCell(pack, EntIndexToEntRef(iParti));
		Handle pack2;
		CreateDataTimer(1.0, Timer_KillParticle, pack2);
		WritePackCell(pack2, EntRefToEntIndex(iPart2));
	}

	float LightningDamage = (200.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 80.0));
	for(int i = 1; i<MAXENTITIES;i++)
	{
		if(!IsValidForDamage(i))
			continue;
		if(!IsOnDifferentTeams(client,i))
			continue;

		float VictimPos[3];
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
		VictimPos[2] += 30.0;
		float Distance = GetVectorDistance(clientpos,VictimPos);
		float Range = 200.0;

		if(Distance > Range)
			continue;

		if(!IsPointVisible(clientpos,VictimPos))
			continue;

		SDKHooks_TakeDamage(i,client,client,LightningDamage,1073741824,-1,NULL_VECTOR,NULL_VECTOR, !IsValidClient3(i));
	}
}
CastBlackskyEye(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane blacksky eye", 0.0));

	if(spellLevel < 1)
		return;

	if(applyArcaneRestrictions(client, attuneSlot, 8.0 + (3.0 * ArcaneDamage[client]), 0.3))
		return; 

	float clientpos[3];
	GetClientEyePosition(client,clientpos);
	EmitSoundToAll(SOUND_CALLBEYOND_CAST, _, client, SNDLEVEL_NORMAL, _, 0.7, _,_,clientpos);
	//Properties
	int maxCount[] = {0,1,2,3};
	float projSpeed[] = {0.0,1200.0,2000.0,3000.0};
	float radius[] = {0.0,700.0,1200.0,1500.0};
	int tickRate[] = {0,4,2,0};
	for(int iter = 0;iter < maxCount[spellLevel];iter++)
	{
		int iEntity = CreateEntityByName("tf_projectile_arrow");
		if (!IsValidEdict(iEntity)) 
			continue;

		float fAngles[3]
		float fOrigin[3]
		float vBuffer[3]
		float fVelocity[3]
		float fwd[3]
		float right[3]
		int iTeam = GetClientTeam(client);
		SetEntityRenderColor(iEntity, 255, 255, 255, 0);
		SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
		SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
		SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
					
		GetClientEyePosition(client, fOrigin);
		GetClientEyeAngles(client,fAngles);
		
		GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		GetAngleVectors(fAngles,fwd, right, NULL_VECTOR);
		ScaleVector(fwd, 60.0);

		switch(iter)
		{
			case 1:
			{
				ScaleVector(right, 50.0);
			}
			case 2:
			{
				ScaleVector(right, -50.0);
			}
		}

		AddVectors(fOrigin, right, fOrigin);
		AddVectors(fOrigin, fwd, fOrigin);
		
		float Speed = projSpeed[spellLevel];
		fVelocity[0] = vBuffer[0]*Speed;
		fVelocity[1] = vBuffer[1]*Speed;
		fVelocity[2] = vBuffer[2]*Speed;
		SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
		TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
		DispatchSpawn(iEntity);
		
		TE_SetupKillPlayerAttachments(iEntity);
		TE_SendToAll();
		int color[4]={100, 100, 100,255};
		TE_SetupBeamFollow(iEntity,Laser,0,2.5,4.0,8.0,3,color);
		TE_SendToAll();
		SDKHook(iEntity, SDKHook_StartTouchPost, BlackskyEyeCollision);
		SDKHook(iEntity, SDKHook_Touch, AddArrowCollisionFunction);
		homingRadius[iEntity] = radius[spellLevel];
		homingTickRate[iEntity] = tickRate[spellLevel];
	}
}
CastACallBeyond(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane a call beyond", 0.0));
	if(spellLevel < 1)
		return;
	if(applyArcaneRestrictions(client, attuneSlot, 50.0 + (70.0 * ArcaneDamage[client]), 50.0))
		return; 


	TF2_StunPlayer(client,1.5,0.0,TF_STUNFLAGS_BIGBONK,0);
	TF2_AddCondition(client, TFCond_FreezeInput, 1.5);
	CreateTimer(1.5, ACallBeyond, EntIndexToEntRef(client));
	
	float clientpos[3];
	GetClientEyePosition(client,clientpos);
	EmitSoundToAll(SOUND_CALLBEYOND_CAST, _, client, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,clientpos);
	CreateParticle(client, "merasmus_tp_bits", true);
	CreateParticle(client, "spellbook_major_burning", true);
	CreateParticle(client, "unusual_meteor_cast_wheel_purple", true);
}
public Action:ACallBeyond(Handle timer, client) 
{
	client = EntRefToEntIndex(client)
	if(!IsPlayerAlive(client))
		return;
	
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane a call beyond", 0.0));

	int projCount[] = {0,15,25,40};
	float radius[] = {0.0,1500.0,2500.0,2500.0};
	int tickRate[] = {0,5,2,0};
	for(int i = 0;i<projCount[spellLevel];i++)
	{
		int iEntity = CreateEntityByName("tf_projectile_arrow");
		if (!IsValidEdict(iEntity)) 
			continue;

		float fAngles[3]
		float fOrigin[3]
		float vBuffer[3]
		float fVelocity[3]
		float fwd[3]
		int iTeam = GetClientTeam(client);
		SetEntityRenderColor(iEntity, 255, 255, 255, 0);
		SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
		SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
		SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
					
		GetClientEyePosition(client, fOrigin);
		GetClientEyeAngles(client,fAngles);
		
		fAngles[0] = -90.0 + GetRandomFloat(-120.0,120.0);
		fAngles[1] += GetRandomFloat(-60.0,60.0);

		GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(fwd, 130.0);
		
		AddVectors(fOrigin, fwd, fOrigin);
		
		float Speed = 1700.0;
		fVelocity[0] = vBuffer[0]*Speed;
		fVelocity[1] = vBuffer[1]*Speed;
		fVelocity[2] = vBuffer[2]*Speed;
		SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
		TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
		DispatchSpawn(iEntity);
		TE_SetupKillPlayerAttachments(iEntity);
		TE_SendToAll();
		int color[4]={255, 255, 255,225};
		TE_SetupBeamFollow(iEntity,Laser,0,2.5,4.0,8.0,3,color);
		TE_SendToAll();
		SDKHook(iEntity, SDKHook_StartTouchPost, CallBeyondCollision);
		SDKHook(iEntity, SDKHook_Touch, AddArrowCollisionFunction);
		
		homingRadius[iEntity] = radius[spellLevel];
		homingTickRate[iEntity] = tickRate[spellLevel];
		homingDelay[iEntity] = 0.4;
	}

	float clientpos[3];
	GetClientEyePosition(client,clientpos);
	EmitSoundToAll(SOUND_CALLBEYOND_ACTIVE, _, client, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,clientpos);
}
CastZap(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane zap", 0.0));

	if(spellLevel < 1)
		return;

	float focusCost = (3.0 + (0.5 * ArcaneDamage[client]))/ArcanePower[client]
	if(fl_CurrentFocus[client] < focusCost)
	{
		PrintHintText(client, "Not enough focus! Requires %.2f focus.",focusCost);
		EmitSoundToClient(client, SOUND_FAIL);
		return;
	}
	if(SpellCooldowns[client][attuneSlot] > 0.0)
		return;

	//zap yeah?
	int closestClient[MAXENTITIES];
	float clientpos[3];
	GetClientEyePosition(client,clientpos);
	clientpos[2] -= 15.0;
	float closestDistance = 2000.0;
	int validCount = 0;
	int maximumTargets[] = {0,1,2,3};
	float range[] = {0.0,600.0,1500.0,1500.0};
	for(int i = 1; i<MAXENTITIES;i++)
	{
		if(!IsValidForDamage(i))
			continue;
		if(!IsOnDifferentTeams(client,i))
			continue;

		float VictimPos[3];
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
		VictimPos[2] += 15.0;
		float Distance = GetVectorDistance(clientpos,VictimPos);

		if(Distance < closestDistance && Distance < range[spellLevel])
		{
			if(IsPointVisible(clientpos,VictimPos))
			{
				PrintToServer("%f", Distance);
				closestClient[validCount] = i;
				closestDistance = Distance;
				validCount++;
			}
		}
	}
	validCount = 0;
	for(int it = MAXENTITIES-1;it>=0 && validCount < maximumTargets[spellLevel];it--)
	{
		if(closestClient[it] != 0){
			validCount++;
			DoZap(client,closestClient[it], spellLevel);
		}
	}
	if(validCount > 0)
	{
		fl_CurrentFocus[client] -= focusCost;
		if(DisableCooldowns != 1)
			SpellCooldowns[client][attuneSlot] = 0.1;
		applyArcaneCooldownReduction(client, attuneSlot);
		PrintHintText(client, "Used %s! -%.2f focus.",SpellList[0],focusCost);
	}
}
DoZap(client,victim,spellLevel)
{
	if(!IsValidForDamage(victim))
		return;

	float clientpos[3];
	float VictimPosition[3];
	float level = ArcaneDamage[client];
	
	GetClientEyePosition(client,clientpos);
	GetEntPropVector(victim, Prop_Data, "m_vecOrigin", VictimPosition);
	VictimPosition[2] += 15.0;
	
	float range[] = {0.0,600.0,1500.0,1500.0};
	
	TE_SetupBeamRingPoint(clientpos, 20.0, range[spellLevel]*1.25, g_LightningSprite, spriteIndex, 0, 5, 0.5, 10.0, 1.0, {255,0,255,133}, 140, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(clientpos,VictimPosition,g_LightningSprite,spriteIndex,0,35,0.15,6.0,5.0,0,1.0,{255,000,255,255},20);
	TE_SendToAll();
	EmitSoundToAll(SOUND_ZAP, _, client, SNDLEVEL_CONVO, _, 1.0, _,_,clientpos);
	
	float LightningDamage = (20.0 + (Pow(level * Pow(ArcanePower[client], 4.0), spellScaling[spellLevel]) * 3.0));
	float radiationAmount[] = {0.0,6.0,10.0,25.0};
	SDKHooks_TakeDamage(victim,client,client, radiationAmount[spellLevel], (DMG_RADIATION+DMG_DISSOLVE), -1, NULL_VECTOR, NULL_VECTOR);
	SDKHooks_TakeDamage(victim,client,client, LightningDamage, 1073741824, -1, NULL_VECTOR, NULL_VECTOR, !IsValidClient3(victim));
	float chance[] = {0.0,0.3,0.6,0.9};
		
	if(chance[spellLevel] >= GetRandomFloat(0.0, 1.0))
	{
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, EntIndexToEntRef(client));
		WritePackCell(hPack, EntIndexToEntRef(victim));
		WritePackCell(hPack, EntIndexToEntRef(spellLevel));
		CreateTimer(0.1,zapAgain,hPack);
	}
}
public Action:zapAgain(Handle timer,any:data)
{
	ResetPack(data);
	int client = EntRefToEntIndex(ReadPackCell(data));
	int victim = EntRefToEntIndex(ReadPackCell(data));
	int spellLevel = EntRefToEntIndex(ReadPackCell(data));
	DoZap(client,victim,spellLevel);
	CloseHandle(data);
}
CastLightning(client, attuneSlot)
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane lightning strike", 0.0));

	if(spellLevel < 1)
		return;

	if(applyArcaneRestrictions(client, attuneSlot, 50.0 + (30.0 * ArcaneDamage[client]), 11.0))
		return; 

	float clientpos[3];
	TracePlayerAim(client, clientpos);
	float temppos[3];
	TracePlayerAim(client, temppos);

	int quantity[] = {0,1,5,25}
	float afterburnDamage[] = {0.0,0.02,0.04,0.08}
	float range[] = {0.0,600.0,1200.0,1500.0}
	for(int iter = 0;iter < quantity[spellLevel];iter++)
	{
		// define where the lightning strike starts
		if(iter > 1)
		{
			clientpos[0] = temppos[0] + GetRandomFloat(-900.0,900.0);
			clientpos[1] = temppos[1] + GetRandomFloat(-900.0,900.0);
		}

		float startpos[3];
		startpos[0] = clientpos[0];
		startpos[1] = clientpos[1];
		startpos[2] = clientpos[2] + 1600;
		
		// define the color of the strike
		int iTeam = GetClientTeam(client);

		int color[4];
		color = iTeam == 2 ? {255, 0, 0, 255} : {0, 0, 255, 255};
		
		// define the direction of the sparks
		float dir[3] = {0.0, 0.0, 0.0};
		
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
		
		for(int i = 1; i<MAXENTITIES;i++)
		{
			if(!IsValidForDamage(i)) 
				continue;
			if (!IsOnDifferentTeams(client,i))
				continue;

			float VictimPos[3];
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
			VictimPos[2] += 30.0;
			float Distance = GetVectorDistance(clientpos,VictimPos);
			if(Distance > range[spellLevel])
				continue;

			if(!IsPointVisible(clientpos,VictimPos))
				continue;

			float LightningDamage = (200.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), spellScaling[spellLevel]) * 80.0));
			SDKHooks_TakeDamage(i,client,client,LightningDamage,DMG_SHOCK,-1,NULL_VECTOR,NULL_VECTOR, !IsValidClient3(i));

			CreateParticle(i, "utaunt_auroraglow_orange_parent", true, "", 3.25);
			
			if(IsValidClient3(i))
				TF2_IgnitePlayer(i, client, 3.0);

			DOTStock(i,client,LightningDamage*afterburnDamage[spellLevel],-1,0,20,1.0,0.1,true);//A fake afterburn. This allows for stacking of DOT & custom tick rates.
		}
	}
	EmitSoundToAll(SOUND_THUNDER, _, client, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,clientpos);
}
CastHealing(client, attuneSlot)//Projected Healing
{
	int spellLevel = RoundToNearest(GetAttribute(client, "arcane projected healing", 0.0));

	if(spellLevel < 1)
		return;

	if(applyArcaneRestrictions(client, attuneSlot, fl_MaxFocus[client]*0.65, 15.0))
		return; 

	float clientpos[3];
	GetClientEyePosition(client,clientpos);
	int iTeam = GetClientTeam(client);
	EmitSoundToAll(SOUND_HEAL, _, client, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,clientpos);
	int iEntity = CreateEntityByName("tf_projectile_flare");
	if (!IsValidEdict(iEntity)) 
		return;

	float fAngles[3]
	float fOrigin[3]
	float vBuffer[3]
	float fVelocity[3]
	float fwd[3]
	SetEntityRenderColor(iEntity, 255, 255, 255, 0);
	SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

	SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
	SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
	SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
	int g_offsCollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	SetEntData(iEntity, g_offsCollisionGroup, 5, 4, true);
				
	GetClientEyePosition(client, fOrigin);
	GetClientEyeAngles(client,fAngles);

	GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fwd, 60.0);

	AddVectors(fOrigin, fwd, fOrigin);

	float Speed = 1800.0;
	fVelocity[0] = vBuffer[0]*Speed;
	fVelocity[1] = vBuffer[1]*Speed;
	fVelocity[2] = vBuffer[2]*Speed;
	SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
	TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
	DispatchSpawn(iEntity);

	TE_SetupKillPlayerAttachments(iEntity);
	TE_SendToAll();

	int color[4];
	color = iTeam == 2 ? {255, 0, 0, 255} : {0, 0, 255, 255};

	TE_SetupBeamFollow(iEntity,Laser,0,2.5,4.0,8.0,3,color);
	TE_SendToAll();
	SDKHook(iEntity, SDKHook_StartTouchPost, ProjectedHealingCollision);
	SDKHook(iEntity, SDKHook_Touch, AddArrowCollisionFunction);
	CreateTimer(0.03, HeavyFriendlyHoming, EntIndexToEntRef(iEntity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}