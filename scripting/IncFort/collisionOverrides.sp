public Action:OnStartTouchStomp(client, other)
{
	//Borrowed from goomba stomp, so don't blame me if it's shit. (jk lel)
    if(!IsValidClient3(client))
		return Plugin_Continue;

	int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidWeapon(CWeapon))
		return Plugin_Continue;

	if(hasBuffIndex(client, Buff_InfernalLunge)){
		float clientPosition[3];
		GetClientAbsOrigin(client, clientPosition);

		CreateParticleEx(client, "heavy_ring_of_fire", 0, 0, clientPosition);
		CreateParticleEx(client, "bombinomicon_burningdebris");

		float strongestDPS = 0.0;
		for(int e = 0;e<3;++e){
			int tempWeapon = TF2Util_GetPlayerLoadoutEntity(client, e);
			if(!IsValidWeapon(tempWeapon))
				continue;

			float currentDPS = TF2_GetWeaponclassDPS(client, tempWeapon) * TF2_GetDPSModifiers(client, tempWeapon);
			if(currentDPS > strongestDPS)
				strongestDPS = currentDPS;
		}

		EntityExplosion(client, playerBuffs[client][getBuffInArray(client, Buff_InfernalLunge)].severity*strongestDPS, 500.0, clientPosition, 0,_,_,_,DMG_BLAST|DMG_BURN,CWeapon,0.25,_,_,_,300.0);
		clearBuff(client, getBuffInArray(client, Buff_InfernalLunge));
	}

	if(!IsValidClient3(other))
		return Plugin_Continue;

	float ClientPos[3], VictimPos[3], VictimVecMaxs[3], vec[3];
	GetClientAbsOrigin(client, ClientPos);
	GetClientAbsOrigin(other, VictimPos);
	GetEntPropVector(other, Prop_Send, "m_vecMaxs", VictimVecMaxs);
	float victimHeight = VictimVecMaxs[2];
	float HeightDiff = ClientPos[2] - VictimPos[2];

	if(HeightDiff > victimHeight){
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);
		if(vec[2] < -300.0){
			float stompDamage = TF2_GetDamageModifiers(client, CWeapon, true, true, false) * 200.0;
			stompDamage *= 1.0+(((trueVel[client][2]*-1.0) - 300.0)/1000.0)

			if(TF2Attrib_HookValueFloat(0.0, "agility_powerup", client) == 2.0){
				int splash = 0;
				for(int i = 1;i <= MaxClients; ++i){
					if(!IsValidClient3(i)) continue;
					if(IsOnDifferentTeams(other, i)) continue;
					if(!IsPlayerAlive(i)) continue;
					if(i == other) continue;
					if(splash == 2) break;

					float splashOrigin[3];
					GetClientAbsOrigin(i, splashOrigin);
					if(GetVectorDistance(splashOrigin, ClientPos, true) > 250000.0) continue;

					SDKHooks_TakeDamage(i,client,client,stompDamage,DMG_CLUB|DMG_CRUSH|DMG_IGNOREHOOK,CWeapon,_,_,false);
					++splash;
				}
			}
			
			SDKHooks_TakeDamage(other,client,client,stompDamage,DMG_CLUB|DMG_CRUSH|DMG_IGNOREHOOK,CWeapon,_,_,false);
		}
	}
}

public Action:AddArrowCollisionFunction(entity, client)
{
	char strName[32];
	GetEntityClassname(client, strName, 32)

	if(StrEqual(strName,"tf_projectile_arrow"))
	{
		float origin[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		origin[0] += GetRandomFloat(-4.0,4.0)
		origin[1] += GetRandomFloat(-4.0,4.0)
		TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
	}
	return Plugin_Stop;
}
public Action OnStartTouchSplittingThunder(entity, other){
	SDKHook(entity, SDKHook_Touch, OnSplittingThunderCollision);

	if(other == 0)
		return Plugin_Continue;

	return Plugin_Handled;
}
public Action:OnSplittingThunderCollision(entity, client)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient3(owner) || client == owner)
		return Plugin_Continue;
	
	int spellLevel = RoundToNearest(TF2Attrib_HookValueFloat(0.0, "arcane_spell_level", owner)) + 1;
	
	float origin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);

	float scaling[] = {0.0, 200.0, 250.0, 300.0};
	float ProjectileDamage = scaling[spellLevel] * ArcaneDamage[owner];
	EntityExplosion(owner, ProjectileDamage, 300.0, origin, _, _, entity);
	RemoveEntity(entity);
	return Plugin_Continue;
}
public Action:OnStartTouchSunlightSpear(entity, other)
{
	SDKHook(entity, SDKHook_Touch, OnSunlightSpearCollision);
	return Plugin_Handled;
}
public Action:OnSunlightSpearCollision(entity, client)
{
	bool dealtDamage = false;

	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			if(IsValidClient3(owner) && IsOnDifferentTeams(owner,client))
			{
				int spellLevel = RoundToNearest(TF2Attrib_HookValueFloat(0.0, "arcane_spell_level", owner)) + 1;

				float scaling[] = {0.0, 100.0, 125.0, 160.0};
				float ProjectileDamage = scaling[spellLevel]*ArcaneDamage[owner];
				SDKHooks_TakeDamage(client, entity, owner, ProjectileDamage, DMG_BURN|DMG_IGNOREHOOK,_,_,_,false);
				CreateParticleEx(client, "dragons_fury_effect_parent", 1);
				dealtDamage = true;
			}
		}
	}
	
	if(g_nBounces[entity] >= projectileMaxBounces[entity] || dealtDamage){
		float origin[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		CreateParticleEx(entity, "drg_cow_explosioncore_charged", -1, -1, origin);
		RemoveEntity(entity);
	}
	return Plugin_Stop;
}
public Action:BlackskyEyeCollision(entity, client)
{		
	if(!IsValidEdict(entity))
		return Plugin_Continue;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return Plugin_Continue;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;
		
	if(owner == entity || entity == client)
		return Plugin_Continue;

	int spellLevel = RoundToNearest(TF2Attrib_HookValueFloat(0.0, "arcane_spell_level", owner)) + 1;

	float projvec[3];
	float radius[] = {0.0, 300.0,500.0,800.0};
	float scaling[] = {0.0, 15.0, 20.0, 25.0};
	float ProjectileDamage = scaling[spellLevel]*ArcaneDamage[owner];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", projvec);
	if(IsValidForDamage(client))
	{
		EntityExplosion(owner,2.5*ProjectileDamage,radius[spellLevel], projvec,0,_,entity,0.75,DMG_BLAST);
		RemoveEntity(entity);
	}
	else
	{
		EntityExplosion(owner,ProjectileDamage,radius[spellLevel], projvec,0,_,entity,0.65,DMG_BLAST,_,_,_,_,"ExplosionCore_sapperdestroyed");
	}
		
	return Plugin_Continue;
}
public Action:CallBeyondCollision(entity, client)
{		
	if(!IsValidEdict(entity))
		return Plugin_Continue;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return Plugin_Continue;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;
	
	if(owner == entity || entity == client)
		return Plugin_Continue;
		
	float projvec[3];
	int spellLevel = RoundToNearest(TF2Attrib_HookValueFloat(0.0, "arcane_spell_level", owner)) + 1;
	float scaling[] = {0.0, 90.0, 125.0, 200.0};
	float ProjectileDamage = scaling[spellLevel]*ArcaneDamage[owner];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", projvec);
	EntityExplosion(owner,ProjectileDamage,500.0, projvec,0,_,entity,0.75,DMG_BLAST);
	RemoveEntity(entity);
		
	return Plugin_Continue;
}
public Action:ProjectedHealingCollision(entity, client)
{
	if(!IsValidEdict(entity))
		return Plugin_Continue;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return Plugin_Continue;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;
	
	if(owner == entity || entity == client)
		return Plugin_Continue;
		
	float projvec[3];
	float AmountHealing = (TF2_GetMaxHealth(owner) * 0.2);
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", projvec);
	for(int i = 1; i<= MaxClients;++i)
	{
		if(IsValidClient3(i) && GetClientTeam(i) == GetClientTeam(owner))
		{
			float VictimPos[3];
			GetClientEyePosition(i,VictimPos);
			if(GetVectorDistance(projvec,VictimPos, true) <= 1000000)
			{
				AddPlayerHealth(i, RoundToCeil(AmountHealing), 2.0 * ArcanePower[owner], true, owner);
				TF2_AddCondition(i,TFCond_MegaHeal,3.0, owner);
			}
		}
	}
	RemoveEntity(entity);
		
	return Plugin_Continue;
}
public Action:IgnitionArrowCollision(entity, client)
{		
	if(!IsValidEdict(entity))
		return Plugin_Continue;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return Plugin_Continue;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;
		
	float projvec[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", projvec);
	int CWeapon = EntRefToEntIndex(jarateWeapon[entity]);
	if(IsValidEdict(CWeapon))
	{
		float damageDealt = 0.0, Radius=144.0;
		Address ignitionExplosion = TF2Attrib_GetByName(CWeapon, "damage applies to sappers");
		if(ignitionExplosion != Address_Null)
		{
			damageDealt = TF2Attrib_GetValue(ignitionExplosion);
		}
		Address ignitionExplosionRadius = TF2Attrib_GetByName(CWeapon, "building cost reduction");
		if(ignitionExplosionRadius != Address_Null)
		{
			Radius *= TF2Attrib_GetValue(ignitionExplosionRadius);
		}
		EntityExplosion(owner, damageDealt, Radius, projvec, _, _,entity,_,_,CWeapon,_,_,true, _, _, _, true);
	}
	return Plugin_Continue;
}
public Action:ExplosiveArrowCollision(entity, client)
{		
	if(!IsValidEdict(entity))
		return Plugin_Continue;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return Plugin_Continue;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;
		
	float projvec[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", projvec);

	int CWeapon = EntRefToEntIndex(jarateWeapon[entity]);
	if(!IsValidWeapon(CWeapon))
		return Plugin_Continue;

	EntityExplosion(owner, 60.0, 400.0, projvec, 1, _,entity,1.0,_, CWeapon,0.75, _, true, _, _, _, true);
	
	return Plugin_Continue;
}
public Action:OnStartTouchWarriorArrow(entity, other)
{
	if(!other)
		return Plugin_Stop;

	if(!IsValidForDamage(other))
		return Plugin_Stop;

	SDKHook(entity, SDKHook_Touch, OnCollisionWarriorArrow);
	return Plugin_Handled;
}
public Action:OnCollisionWarriorArrow(entity, client)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(IsOnDifferentTeams(owner,client))
	{
		int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
		if(IsValidEdict(CWeapon))
		{
			int damageType = GetEntProp(entity, Prop_Send, "m_bCritical") ? DMG_BULLET|DMG_CRIT : DMG_BULLET;
			SDKHooks_TakeDamage(client, entity, owner, 25.0, damageType, CWeapon, _,_,false);
		}
		RemoveEntity(entity);
	}

	SDKUnhook(entity, SDKHook_Touch, OnCollisionWarriorArrow);
	return Plugin_Stop;
}
public Action:OnStartTouchSentryFireball(entity, other)
{
	SDKHook(entity, SDKHook_Touch, OnCollisionSentryFireball);
	return Plugin_Continue;
}
public Action:OnCollisionSentryFireball(entity, client)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(IsValidClient3(owner)){
		int pda = EntRefToEntIndex(jarateWeapon[entity]);
		if(IsValidWeapon(pda)){
			float projvec[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", projvec);
			EntityExplosion(owner, projectileDamage[entity], 200.0, projvec, _, _, entity, _, _, pda, _, _, true);
		}
	}
	RemoveEntity(entity);
	return Plugin_Stop;
}
public Action:OnStartTouchSentryBolt(entity, other)
{
	SDKHook(entity, SDKHook_Touch, OnCollisionSentryBolt);
	return Plugin_Continue;
}
public Action:OnCollisionSentryBolt(entity, client)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(IsValidForDamage(client))
	{
		if(IsOnDifferentTeams(owner,client)){
			int sentry = EntRefToEntIndex(jarateWeapon[entity]);
			if(IsValidEntity(sentry))
			{
				SDKHooks_TakeDamage(client, entity, owner, projectileDamage[entity], DMG_BULLET|DMG_IGNOREHOOK, _, _,_,false);
				if(IsValidClient3(client)){
					ShouldNotHome[entity][client] = true;
					BleedBuildup[client] += 4.0;
					checkBleed(client, owner, _, projectileDamage[entity]*3.0);
				}
			}
		}

		float origin[3];
		float ProjAngle[3];
		float vBuffer[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
		GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vBuffer, 90.0);
		AddVectors(origin, vBuffer, origin);
		TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
		RequestFrame(fixPiercingVelocity,EntIndexToEntRef(entity))
	}
	if(client == 0)
		RemoveEntity(entity);
	
	SDKUnhook(entity, SDKHook_Touch, OnCollisionSentryBolt);
	return Plugin_Stop;
}
public Action:OnCollisionBossArrow(entity, client)
{
	char strName[32];
	GetEntityClassname(client, strName, 32)
	char strName1[32];
	GetEntityClassname(entity, strName1, 32)
	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			if(IsOnDifferentTeams(owner,client))
			{
				int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEdict(CWeapon))
				{
					float damageDealt = 240.0*TF2_GetDamageModifiers(owner, CWeapon, false);
					SDKHooks_TakeDamage(client, entity, owner, damageDealt, DMG_BULLET|DMG_IGNOREHOOK, CWeapon, _,_,false);
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
	char strName[32];
	GetEntityClassname(client, strName, 32)
	char strName1[32];
	GetEntityClassname(entity, strName1, 32)
	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
			if(IsValidEdict(CWeapon))
			{
				SDKHooks_TakeDamage(client, owner, owner, 50.0*TF2_GetDamageModifiers(owner, CWeapon, false), DMG_BULLET|DMG_IGNOREHOOK, CWeapon, _,_,false);
			}
			RemoveEntity(entity);
		}
	}
	if(StrContains(strName,"trigger_",false) || StrEqual(strName,strName1,false))
	{	
		if(StrEqual(strName,strName1,false))
		{
			float origin[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
			origin[0] += GetRandomFloat(-4.0,4.0)
			origin[1] += GetRandomFloat(-4.0,4.0)
			TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
		}
	}
	return Plugin_Stop;
}
public Action:OnCollisionPhotoViscerator(entity, client)
{
	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			if(IsOnDifferentTeams(owner,client))
			{
				int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEdict(CWeapon))
				{
					SDKHooks_TakeDamage(client,entity,owner,60.0,DMG_BURN|DMG_IGNITE,CWeapon,_,_,false);
				}
				float pos[3]
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", pos);
				EmitSoundToAll("weapons/cow_mangler_explosion_normal_01.wav", entity,_,100,_,0.85);
				CreateParticleEx(entity, "drg_cow_explosioncore_charged_blue");
				RemoveEntity(entity);
			}
		}
	}
	else
	{
		float origin[3];
		float ProjAngle[3];
		float vBuffer[3];
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
public Action:OnStartTouchMoonveil(entity, other)
{
	SDKHook(entity, SDKHook_Touch, OnCollisionMoonveil);
	return Plugin_Handled;
}
public Action:OnCollisionMoonveil(entity, client)
{
	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			if(IsOnDifferentTeams(owner,client))
			{
				int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEdict(CWeapon))
				{
					float damage = 150.0;
					if (IsValidEntity(CWeapon) && TF2Util_IsEntityWeapon(CWeapon)) {
						damage *= GetAttribute(CWeapon, "damage mult 15");
					}
					damage *= ArcaneDamage[owner];
					SDKHooks_TakeDamage(client,entity,owner,damage,DMG_GENERIC|DMG_IGNOREHOOK,CWeapon, _,_,false);
				}
				RemoveEntity(entity);
			}
		}
	}
	float pos[3]
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", pos);
	EmitSoundToAll("weapons/cow_mangler_explosion_normal_01.wav", entity,_,100,_,0.85);
	CreateParticleEx(entity, "drg_cow_explosioncore_charged_blue");
	SDKUnhook(entity, SDKHook_Touch, OnCollisionMoonveil);
	return Plugin_Continue;
}
public Action:OnStartTouchBoomerang(entity, other)
{
	SDKHook(entity, SDKHook_Touch, OnCollisionBoomerang);
	return Plugin_Handled;
}
public Action:OnCollisionBoomerang(entity, client)
{
	if(IsValidForDamage(client))
	{
		int owner = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		if(IsValidClient3(owner) && IsOnDifferentTeams(owner,client))
		{
			int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
			if(IsValidEdict(CWeapon))
			{
				float damageDealt = 180.0 * TF2_GetDamageModifiers(owner, CWeapon);
				SDKHooks_TakeDamage(client, entity, owner, damageDealt, DMG_SLASH|DMG_IGNOREHOOK, CWeapon,_,_,false);
			}
		}
		float origin[3],ProjAngle[3], vBuffer[3], ProjVelocity[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", ProjVelocity);
		GetVectorAngles(ProjVelocity, ProjAngle);
		GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vBuffer, 120.0);
		AddVectors(origin, vBuffer, origin);
		TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
		if(IsValidClient3(client))
			ShouldNotHome[entity][client] = true;

		delayedResetVelocity(entity, ProjVelocity);
	}
	SDKUnhook(entity, SDKHook_Touch, OnCollisionBoomerang);
	return Plugin_Stop;
}
public Action:OnStartTouchPiercingRocket(entity, other)
{
	SDKHook(entity, SDKHook_Touch, OnCollisionPiercingRocket);
	return Plugin_Handled;
}
public Action:OnCollisionPiercingRocket(entity, client)
{
	SDKUnhook(entity, SDKHook_Touch, OnCollisionPiercingRocket);
	if(!client)
		return Plugin_Continue;

	Action action = Plugin_Continue;
	char strName[32];
	GetEntityClassname(client, strName, 32)
	char strName1[32];
	GetEntityClassname(entity, strName1, 32)
	
	if(!StrEqual(strName, strName1) && IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			if(IsValidClient3(owner) && IsOnDifferentTeams(entity,client))
			{
				float origin[3];
				float ProjAngle[3];
				float vBuffer[3];
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
				GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
				GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(vBuffer, 100.0);
				AddVectors(origin, vBuffer, origin);
				TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
				RequestFrame(fixPiercingVelocity,EntIndexToEntRef(entity))
				
				int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEdict(CWeapon))
				{
					int damageType = GetEntProp(entity, Prop_Send, "m_bCritical") ? DMG_BLAST|DMG_CRIT : DMG_BLAST;
					EntityExplosion(owner, 90.0, 200.0, origin, 0, true, entity, _, damageType, CWeapon,_,_,_,_,_, true, true);
				}
				if(IsValidClient3(client))
					ShouldNotHome[entity][client] = true;
				action = Plugin_Stop;
			}
		}
	}
	if(IsValidEdict(entity))
	{
		float origin[3];
		float ProjAngle[3];
		float vBuffer[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
		GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vBuffer, 20.0);
		AddVectors(origin, vBuffer, origin);
		TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
		RequestFrame(fixPiercingVelocity,EntIndexToEntRef(entity))
		action = Plugin_Stop;
	}

	return action;
}
public Action StartTouchThrownSentryDeploy(entity, other){
	SDKHook(entity, SDKHook_Touch, TouchThrownSentryDeploy);
	return Plugin_Continue;
}
public Action TouchThrownSentryDeploy(entity, other){
	if(!IsValidEntity(entity)) return Plugin_Continue;
	int building = EntRefToEntIndex(jarateWeapon[entity]);
	if(!IsValidEntity(building)) return Plugin_Continue;
	float pos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
	float mins[3],maxs[3],vec[3],angles[3],fwd[3];

	GetEntPropVector(building, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(building, Prop_Send, "m_vecMaxs", maxs);
	vec[0] = pos[0];
	vec[1] = pos[1];
	vec[2] = pos[2] - 5.0;
	pos[2] += 5.0;

	TR_TraceHullFilter(pos,vec, mins,maxs, MASK_PLAYERSOLID_BRUSHONLY, TraceWorldOnly);
	if (!TR_DidHit()) 
		return Plugin_Continue;

	AcceptEntityInput(building, "ClearParent");
	float zeros[3];

	GetEntPropVector(entity, Prop_Data, "m_angRotation", angles);
	angles[0] = 0.0;
	GetAngleVectors(angles,fwd, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fwd, 45.0);
	AddVectors(pos,fwd,fwd);
	TR_TraceRayFilter(pos, fwd, MASK_SHOT_HULL, RayType_EndPoint, TraceWorldOnly);
	if(TR_DidHit()){
		float normal[3];
		TR_GetPlaneNormal(INVALID_HANDLE, normal);
		GetVectorAngles(normal, angles)
	}


	TeleportEntity(building, pos, angles, zeros); //use 0-velocity to calm down bouncyness
	//restore other props: get it out of peudo carry state 
	SetEntProp(building, Prop_Send, "m_bBuilding", 1);
	SetEntProp(building, Prop_Send, "m_bCarried", 0);
	SDKCall(g_SDKFastBuild, building, true);
	SetEntityRenderMode(building, RENDER_NORMAL);
	RemoveEntity(entity);
	isPrimed[building] = true;
	return Plugin_Stop;
}
public Action:OnStartTouchJars(entity, other)
{
	SDKHook(entity, SDKHook_Touch, OnTouchExplodeJar);
	return Plugin_Handled;
}
public Action:OnTouchExplodeJar(entity, other)
{
	float clientvec[3], Radius=250.0;
	int mode=jarateType[entity];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", clientvec);
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity"); 
	if(!IsValidClient3(owner))
		return Plugin_Continue;
	
	int CWeapon = EntRefToEntIndex(jarateWeapon[entity]);
	if(IsValidWeapon(CWeapon))
	{
		Address blastRadius1 = TF2Attrib_GetByName(CWeapon, "Blast radius increased");
		Address blastRadius2 = TF2Attrib_GetByName(CWeapon, "Blast radius decreased");
		if(blastRadius1 != Address_Null){
			Radius *= TF2Attrib_GetValue(blastRadius1)
		}
		if(blastRadius2 != Address_Null){
			Radius *= TF2Attrib_GetValue(blastRadius2)
		}
		float damageBoost = TF2_GetDamageModifiers(owner, CWeapon);
		float jarMult = TF2Attrib_HookValueFloat(1.0, "jar_damage_mult", CWeapon);
		if(entityMaelstromChargeCount[entity] > 0){
			Radius *= 1.35;
			float startpos[3];
			startpos[0] = clientvec[0];
			startpos[1] = clientvec[1];
			startpos[2] = clientvec[2] + 1600;
			
			int color[4];
			color = {255,228,0,255};
			
			// define the direction of the sparks
			TE_SetupBeamPoints(startpos, clientvec, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
			TE_SendToAll();
			TE_SetupSparks(clientvec, {0.0, 0.0, 0.0}, 5000, 1000);
			TE_SendToAll();
			TE_SetupEnergySplash(clientvec, {0.0, 0.0, 0.0}, false);
			TE_SendToAll();
			TE_SetupSmoke(clientvec, g_SmokeSprite, 5.0, 10);
			TE_SendToAll();
			
			EmitSoundToAll(SOUND_THUNDER, entity, _, SNDLEVEL_NORMAL, _, 1.0, _,_,clientvec);
			
			float LightningDamage = 70.0 * damageBoost * entityMaelstromChargeCount[entity];
			float squaredRadius = Radius*Radius*(1+0.01*entityMaelstromChargeCount[entity])*(1+0.01*entityMaelstromChargeCount[entity]);

			int i = -1;
			while ((i = FindEntityByClassname(i, "*")) != -1)
			{
				if(IsValidForDamage(i) && IsOnDifferentTeams(owner,i))
				{
					float VictimPos[3];
					GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
					VictimPos[2] += 30.0;
					if(GetVectorDistance(clientvec,VictimPos,true) <= squaredRadius)
						if(IsPointVisible(clientvec,VictimPos)){
							SDKHooks_TakeDamage(i,entity,owner, LightningDamage, DMG_IGNOREHOOK, CWeapon,_,_,false);
						}
				}
			}

			entityMaelstromChargeCount[entity] = 0;
		}

		int i = -1;
		while ((i = FindEntityByClassname(i, "*")) != -1)
		{
			if(IsValidForDamage(i))
			{
				float VictimPos[3];
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
				VictimPos[2] += 30.0;

				if(GetVectorDistance(clientvec, VictimPos, false) <= Radius)
				{
					if(IsPointVisible(clientvec,VictimPos))
					{
						bool isPlayer = IsValidClient3(i);
						if(IsOnDifferentTeams(owner,i))
						{
							switch(mode)
							{
								case 0:
								{
									SDKHooks_TakeDamage(i,entity,owner,30.0*damageBoost*jarMult,DMG_BULLET|DMG_IGNOREHOOK,CWeapon,_,_,false);
									if(isPlayer){
										miniCritStatusVictim[i] = GetGameTime()+8.0;
										Buff jarateDebuff;
										jarateDebuff.init("Jarated", "", Buff_Jarated, RoundToNearest(damageBoost), owner, 8.0, damageBoost);
										insertBuff(i, jarateDebuff);
									}
								}
								case 1:
								{
									if(isPlayer)
										TF2_AddCondition(i,TFCond_Milked,0.01);
										
									SDKHooks_TakeDamage(i,entity,owner,30.0*damageBoost*jarMult,DMG_BULLET|DMG_IGNOREHOOK,CWeapon,_,_,false);
								}
							}//corrosiveDOT
							if(isPlayer)
							{
								float jarArmorBrokenBuff = TF2Attrib_HookValueFloat(0.0, "jar_applies_armor_decay", CWeapon);
								if(jarArmorBrokenBuff > 0.0)
								{
									Buff pierceBuff;
									pierceBuff.init("Broken Armor", "", Buff_BrokenArmor, RoundFloat(jarArmorBrokenBuff), owner, 6.0, jarArmorBrokenBuff);
									insertBuff(i, pierceBuff);
								}
								float jarCorrosive = TF2Attrib_HookValueFloat(0.0, "jar_debuff_corrosion", CWeapon);
								if(jarCorrosive > 0.0)
								{
									corrosiveDOT[i][owner][0] = TF2_GetDPSModifiers(owner,CWeapon)*jarCorrosive/10.0;
									corrosiveDOT[i][owner][1] = GetGameTime()+5.0;
								}
							}
						}
						else
						{
							if(!isPlayer)
								continue;
								
							float jarAfterburnImmunity = TF2Attrib_HookValueFloat(0.0, "jar_buff_afterburn_immunity", CWeapon);
							if(jarAfterburnImmunity > 0)
								TF2_AddCondition(i,TFCond_AfterburnImmune,jarAfterburnImmunity);

							float jarBuffHaste = TF2Attrib_HookValueFloat(0.0, "jar_buff_haste", CWeapon);
							if(jarBuffHaste > 0.0)
							{
								Buff hasteBuff;
								hasteBuff.init("Minor Haste", "", Buff_Haste, 1, owner, jarBuffHaste);
								hasteBuff.additiveAttackSpeedMult = 0.34;
								insertBuff(i, hasteBuff);
							}

							float jarBuffDefense = TF2Attrib_HookValueFloat(0.0, "jar_buff_defense", CWeapon);
							if(jarBuffDefense > 0.0)
								giveDefenseBuff(i,jarBuffDefense);

							float jarArmorPierceBuff = TF2Attrib_HookValueFloat(0.0, "jar_gives_armor_penetration", CWeapon);
							if(jarArmorPierceBuff > 0.0)
							{
								Buff pierceBuff;
								pierceBuff.init("Armor Piercing Boost", "", Buff_PiercingBuff, 1, owner, 6.0, jarArmorPierceBuff);
								insertBuff(i, pierceBuff);
							}
							
							TF2_RemoveCondition(i, TFCond_OnFire);
						}
					}
				}
			}
		}

		float fragCount = TF2Attrib_HookValueFloat(0.0, "explosive_frag_count", CWeapon);
		bool cannotFragment = TF2Attrib_HookValueInt(0, "jar_cannot_fragment", CWeapon) != 0;
		if(fragCount > 0 && !cannotFragment){
			bool isUniform = TF2Attrib_HookValueFloat(0.0, "explosive_fragment_is_uniform", CWeapon) != 0;
			float fAngles[3];
			if(isUniform){
				fAngles[0] = -30.0;
			}
			for(i = 0;i<RoundToNearest(fragCount);++i)
			{
				int iEntity = CreateEntityByName("tf_projectile_syringe");
				if (!IsValidEdict(iEntity)) 
					continue;

				int iTeam = GetClientTeam(owner);
				float fOrigin[3],vBuffer[3],fVelocity[3],fwd[3];
				SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);
				SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
				fOrigin = clientvec;
				if(isUniform){
					fAngles[1] += 360.0/RoundToNearest(fragCount);
				}
				else{
					fAngles[0] = GetRandomFloat(0.0,-60.0);
					fAngles[1] = GetRandomFloat(-179.0,179.0);
				}

				GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(fwd, 30.0);
				
				AddVectors(fOrigin, fwd, fOrigin);
				GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
				
				float velocity = 1500.0*TF2Attrib_HookValueFloat(1.0, "frag_velocity_mult", CWeapon);
				fVelocity[0] = vBuffer[0]*velocity;
				fVelocity[1] = vBuffer[1]*velocity;
				fVelocity[2] = vBuffer[2]*velocity;
				
				TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
				DispatchSpawn(iEntity);
				setProjGravity(iEntity, 9.0);
				SDKHook(iEntity, SDKHook_Touch, OnCollisionExplosiveFrag);
				jarateWeapon[iEntity] = EntIndexToEntRef(CWeapon);
				CreateTimer(1.0,SelfDestruct,EntIndexToEntRef(iEntity));
				SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008);
				SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
				SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 13);
			}
		}
	}
	switch(mode){
		case 0:{CreateParticleEx(entity, "peejar_impact");}
		case 1:{CreateParticleEx(entity, "peejar_impact_milk");}
		case 2:{CreateParticleEx(entity, "pumpkin_explode");}
		case 3:{CreateParticleEx(entity, "breadjar_impact");}
		case 4:{CreateParticleEx(entity, "gas_can_impact_blue");}
		case 5:{CreateParticleEx(entity, "gas_can_impact_red");}
	}
	EmitSoundToAll(SOUND_JAR_EXPLOSION, entity, -1, 80, 0, 0.8);
	SDKUnhook(entity, SDKHook_Touch, OnTouchExplodeJar);
	jarateType[entity] = -1;
	RemoveEntity(entity);
	return Plugin_Handled;
}
public Action:OnCollisionExplosiveFrag(entity, client)
{
	int CWeapon = EntRefToEntIndex(jarateWeapon[entity])
	if(IsValidEdict(CWeapon))
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
		if(IsValidClient3(owner))
		{
			if(IsValidForDamage(client))
			{
				if(IsOnDifferentTeams(owner,client))
				{
					float damageDealt = 15.0*TF2_GetDamageModifiers(owner, CWeapon, false);
					SDKHooks_TakeDamage(client, entity, owner, damageDealt, DMG_BULLET|DMG_IGNOREHOOK, CWeapon, _,_,false);
				}
			}
			float fragExplosionDamage = TF2Attrib_HookValueFloat(0.0, "explosive_frag_damage", CWeapon);
			if(fragExplosionDamage > 0.0)
			{
				float Radius = 75.0*TF2Attrib_HookValueFloat(1.0, "mult_explosion_radius", CWeapon)*TF2Attrib_HookValueFloat(1.0, "mult_frag_explosion_radius", CWeapon), clientvec[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", clientvec)
				EntityExplosion(owner, fragExplosionDamage, Radius, clientvec, 0, true, entity, 0.25,_,CWeapon,_,75,_ ,"ExplosionCore_sapperdestroyed", _, _, true);
			}
		}
	}
	RemoveEntity(entity);
	return Plugin_Stop;
}
public Action:CollisionFrozenFrag(entity, client)
{
	int CWeapon = EntRefToEntIndex(jarateWeapon[entity])
	if(IsValidEdict(CWeapon))
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
		if(IsValidClient3(owner))
		{
			if(IsValidForDamage(client))
			{
				if(IsOnDifferentTeams(owner,client))
				{
					float damageDealt = 0.65*TF2Util_GetEntityMaxHealth(jarateWeapon[entity]);
					SDKHooks_TakeDamage(client, entity, owner, damageDealt, DMG_PREVENT_PHYSICS_FORCE|DMG_IGNOREHOOK|DMG_PIERCING, CWeapon, _,_,false);
					RemoveEntity(entity);
				}
			}
		}
	}
	return Plugin_Stop;
}
public Action meteorCollision(entity, client)
{		
	if(!IsValidEdict(entity))
		return Plugin_Continue;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return Plugin_Continue;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;

	int CWeapon = jarateWeapon[entity];
	if(!IsValidWeapon(CWeapon))
		return Plugin_Continue;

	float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	int damageType = GetEntProp(entity, Prop_Send, "m_bCritical") ? DMG_BURN|DMG_CRIT : DMG_BURN;

	EntityExplosion(owner, 45.0, 250.0, position, 0, _, entity, _, damageType, CWeapon, _, _, true, _, _, _, true);
		
	return Plugin_Continue;
}
public Action:OnStartTouchDelete(entity, other)
{
	if(IsValidEdict(entity) && !IsValidForDamage(other))
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
		
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;
	
	if (g_nBounces[entity] >= projectileMaxBounces[entity])
		return Plugin_Continue;

	SDKHook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}
public Action:OnStartTouchDragonsBreath(entity, other)
{
	if (other > 0 && other <= MaxClients)
		return Plugin_Continue;
		
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;

	SDKHook(entity, SDKHook_Touch, OnTouchDrag);
	return Plugin_Handled;
}
public Action:OnStartTouchChaos(entity, other)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;

	SDKHook(entity, SDKHook_Touch, OnTouchChaos);
	return Plugin_Handled;
}
public Action:OnTouchChaos(entity, other)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(IsValidClient(owner))
	{
		int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
		if(IsValidEdict(CWeapon))
		{
			float vOrigin[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
			CreateParticleEx(entity, "heavy_ring_of_fire", 0, 0, vOrigin);
			vOrigin[2]+= 30.0;
			int damageType = GetEntProp(entity, Prop_Send, "m_bCritical") ? DMG_BURN|DMG_CRIT : DMG_BURN;
			EntityExplosion(owner, 25.0, 500.0, vOrigin, 0,_,entity,1.0,damageType,CWeapon,0.75, _, true, _, _, _, true);
			RemoveEntity(entity);
		}
	}
	SDKUnhook(entity, SDKHook_Touch, OnTouchChaos);
	return Plugin_Handled;
}
public Action:OnTouchDrag(entity, other)
{
	float vOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);

	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(IsValidClient(owner))
	{
		int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
		if(IsValidEdict(CWeapon))
		{
			vOrigin[2]+= 30.0;
			EntityExplosion(owner, TF2_GetDPSModifiers(owner, CWeapon, false)*45.0, 500.0, vOrigin, 0,_,entity, _, _, _, _, _, true);
		}
	}

	RemoveEntity(entity);
	SDKUnhook(entity, SDKHook_Touch, OnTouchDrag);
	return Plugin_Handled;
}
public Action OnTouch(entity, other)
{
	float vOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
	
	float vAngles[3];
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
	
	float vVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vVelocity);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TEF_ExcludeEntity, entity);
	
	if(!TR_DidHit(trace))
	{
		delete trace;
		return Plugin_Continue;
	}
	
	float vNormal[3];
	TR_GetPlaneNormal(trace, vNormal);
	
	//PrintToServer("Surface Normal: [%.2f, %.2f, %.2f]", vNormal[0], vNormal[1], vNormal[2]);
	
	delete trace;
	
	float dotProduct = GetVectorDotProduct(vNormal, vVelocity);
	
	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);
	
	float vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);
	
	float vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);
	
	//PrintToServer("Angles: [%.2f, %.2f, %.2f] -> [%.2f, %.2f, %.2f]", vAngles[0], vAngles[1], vAngles[2], vNewAngles[0], vNewAngles[1], vNewAngles[2]);
	//PrintToServer("Velocity: [%.2f, %.2f, %.2f] |%.2f| -> [%.2f, %.2f, %.2f] |%.2f|", vVelocity[0], vVelocity[1], vVelocity[2], GetVectorLength(vVelocity), vBounceVec[0], vBounceVec[1], vBounceVec[2], GetVectorLength(vBounceVec));
	
	//we bouncing!
	TeleportEntity(entity, NULL_VECTOR, vNewAngles, vBounceVec);
	if(projectileExplosionBounceDamage[entity] > 0){
		int owner = getOwner(entity);
		if(IsValidClient3(owner)){
			EntityExplosion(owner, projectileExplosionBounceDamage[entity], projectileExplosionBounceRadius[entity], vOrigin, _,_,entity,0.0,_,_,_,_,_,"ExplosionCore_sapperdestroyed");
		}
	}

	g_nBounces[entity]++;
	SDKUnhook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}
public Action OnSmokeStartTouch(entity, other){
	float position[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", position);

	CreateSmokeBombEffect(position, 8.0, GetEntProp(entity, Prop_Send, "m_iTeamNum"));
	RemoveEntity(entity);
	return Plugin_Continue;
}

public Action:OnStartTouchEtherealKnife(entity, other)
{
	if(!other)
		return Plugin_Stop;

	if(!IsValidForDamage(other))
		return Plugin_Stop;

	SDKHook(entity, SDKHook_Touch, OnCollisionEtherealKnife);
	return Plugin_Handled;
}
public Action:OnCollisionEtherealKnife(entity, client)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient3(owner) || client == 0)
		return Plugin_Continue;
		
	if(IsOnDifferentTeams(owner,client) && !hasHit[client][projectileAttackCounter[entity] % 30])
	{
		int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
		if(IsValidEdict(CWeapon))
		{
			int damageType = GetEntProp(entity, Prop_Send, "m_bCritical") ? DMG_CLUB|DMG_CRIT : DMG_CLUB;
			SDKHooks_TakeDamage(client, entity, owner, 45.0, damageType, CWeapon, _,_,false);
			hasHit[client][projectileAttackCounter[entity] % 30] = true;
		}
	}
	float origin[3], ProjAngle[3], vBuffer[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
	GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vBuffer, 30.0);
	AddVectors(origin,vBuffer,origin);
	TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
	RequestFrame(fixPiercingVelocity,EntIndexToEntRef(entity))
	return Plugin_Stop;
}

public Action:OnStartTouchAirblastArrow(entity, other)
{
	SDKHook(entity, SDKHook_Touch, OnAirblastArrowCollision);
	return Plugin_Handled;
}
public Action:OnAirblastArrowCollision(entity, client)
{
	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			if(IsValidClient3(owner) && IsOnDifferentTeams(owner,client))
			{
				SDKHooks_TakeDamage(client, entity, owner, projectileDamage[entity], DMG_BULLET|DMG_IGNOREHOOK,_,_,_,false);
			}
		}
	}

	RemoveEntity(entity);
	return Plugin_Stop;
}
public Action:OnStartTouchPiercingArrow(entity, other)
{
	SDKHook(entity, SDKHook_Touch, OnCollisionPiercingArrow);
	return Plugin_Handled;
}
public Action:OnCollisionPiercingArrow(entity, client)
{
	SDKUnhook(entity, SDKHook_Touch, OnCollisionPiercingArrow);
	if(!client)
		return Plugin_Continue;

	Action action = Plugin_Continue;
	
	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			if(IsValidClient3(owner) && IsOnDifferentTeams(entity,client))
			{
				float origin[3];
				float ProjAngle[3];
				float vBuffer[3];
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
				GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
				GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(vBuffer, 50.0);
				AddVectors(origin, vBuffer, origin);
				TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
				RequestFrame(fixPiercingVelocity,EntIndexToEntRef(entity))
				
				int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEdict(CWeapon))
				{
					int damageType = GetEntProp(entity, Prop_Send, "m_bCritical") ? DMG_BULLET|DMG_CRIT : DMG_BULLET;
					SDKHooks_TakeDamage(client, entity, owner, projectileDamage[entity], damageType, CWeapon, _, _, false);
				}
				if(IsValidClient3(client))
					ShouldNotHome[entity][client] = true;
				action = Plugin_Stop;
			}
		}
	}
	if(IsValidEdict(entity))
	{
		float origin[3];
		float ProjAngle[3];
		float vBuffer[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
		GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vBuffer, 20.0);
		AddVectors(origin, vBuffer, origin);
		TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
		RequestFrame(fixPiercingVelocity,EntIndexToEntRef(entity))
		action = Plugin_Stop;
	}

	return action;
}