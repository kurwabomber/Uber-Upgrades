public Action:OnStartTouchStomp(client, other)
{
	//Borrowed from goomba stomp, so don't blame me if it's shit. (jk lel)
    if(!IsValidClient3(other) || !IsValidClient3(client))
		return Plugin_Continue;

	int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidWeapon(CWeapon))
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

			if(GetAttribute(client, "agility powerup", 0.0) == 2.0){
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

					currentDamageType[client].second |= DMG_IGNOREHOOK;
					SDKHooks_TakeDamage(i,client,client,stompDamage,DMG_CLUB|DMG_CRUSH,CWeapon,_,_,false);
					++splash;
				}
			}
			
			currentDamageType[client].second |= DMG_IGNOREHOOK;
			SDKHooks_TakeDamage(other,client,client,stompDamage,DMG_CLUB|DMG_CRUSH,CWeapon,_,_,false);
		}
	}
	if(hasBuffIndex(client, Buff_InfernalLunge)){
		CreateParticleEx(client, "heavy_ring_of_fire", 0, 0, ClientPos);
		CreateParticleEx(client, "bombinomicon_burningdebris");

		float strongestDPS = 0.0;
		for(int e = 0;e<3;++e){
			int tempWeapon = GetWeapon(client, e);
			if(!IsValidWeapon(tempWeapon))
				continue;

			float currentDPS = TF2_GetWeaponclassDPS(client, tempWeapon) * TF2_GetDPSModifiers(client, tempWeapon);
			if(currentDPS > strongestDPS)
				strongestDPS = currentDPS;
		}
		EntityExplosion(client, playerBuffs[client][getBuffInArray(client, Buff_InfernalLunge)].severity*strongestDPS, 500.0, ClientPos, 0,_,_,_,DMG_BLAST+DMG_BURN,CWeapon,0.25, _,_,_,_,_,_,300.0);
		playerBuffs[client][getBuffInArray(client, Buff_InfernalLunge)].clear();
	}
}

public Action FixProjectileCollision(entity, client)
{
	char strName[32];
	GetEntityClassname(client, strName, 32)

	if(StrContains(strName,"tf_projectile") != -1)
	{
		float origin[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		origin[0] += GetRandomFloat(-1.0,1.0)
		origin[1] += GetRandomFloat(-1.0,1.0)
		TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
		return Plugin_Stop;
	}

	return Plugin_Continue;
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
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient3(owner) || client == owner)
		return Plugin_Continue;
	
	int spellLevel = RoundToNearest(GetAttribute(owner, "arcane splitting thunder", 0.0));
	if(spellLevel < 1)
		return Plugin_Continue;
	
	float origin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);

	float scaling[] = {0.0, 200.0, 400.0, 800.0};
	float ProjectileDamage = 5000.0 + (Pow(ArcaneDamage[owner]*Pow(ArcanePower[owner], 4.0),spellScaling[spellLevel]) * scaling[spellLevel]);
	EntityExplosion(owner, ProjectileDamage, 300.0, origin, _, _, entity);
	RemoveEntity(entity);

	SDKUnhook(entity, SDKHook_Touch, OnSplittingThunderCollision);
	return Plugin_Continue;
}
public Action:OnStartTouchSunlightSpear(entity, other)
{
	SDKHook(entity, SDKHook_Touch, OnSunlightSpearCollision);
	return Plugin_Handled;
}
public Action:OnSunlightSpearCollision(entity, client)
{
	char strName[32];
	GetEntityClassname(client, strName, 32)
	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			if(IsOnDifferentTeams(owner,client))
			{
				int spellLevel = RoundToNearest(GetAttribute(owner, "arcane sunlight spear", 0.0));
				if(spellLevel < 1)
					return Plugin_Continue;

				float scaling[] = {0.0, 35.0, 70.0, 140.0};
				float ProjectileDamage = 140.0 + (Pow(ArcaneDamage[owner]*Pow(ArcanePower[owner], 4.0),spellScaling[spellLevel]) * scaling[spellLevel]);
				currentDamageType[owner].second |= DMG_IGNOREHOOK;
				SDKHooks_TakeDamage(client, owner, owner, ProjectileDamage, DMG_SHOCK,_,_,_,false);
				RemoveEntity(entity);
				CreateParticleEx(client, "dragons_fury_effect_parent", 1);
			}
		}
	}
	if(StrContains(strName,"trigger_",false) || StrEqual(strName,"tf_projectile_arrow",false) || client == -1)
	{	
		if(StrEqual(strName,"tf_projectile_arrow",false))
		{
			float origin[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
			origin[0] += GetRandomFloat(-4.0,4.0)
			origin[1] += GetRandomFloat(-4.0,4.0)
			TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
		}
	}
	SDKUnhook(entity, SDKHook_Touch, OnSunlightSpearCollision);
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
		
	char strName[32];
	GetEntityClassname(client, strName, 32);
	if(StrEqual(strName,"tf_projectile_arrow",false))
		return Plugin_Continue;

	Address BlackskyEyeActive = TF2Attrib_GetByName(owner, "arcane blacksky eye");
	int spellLevel = BlackskyEyeActive == Address_Null ? 0 : RoundToNearest(TF2Attrib_GetValue(BlackskyEyeActive));
	
	if(spellLevel < 1)
		return Plugin_Continue;

	float projvec[3];
	float radius[] = {0.0, 300.0,500.0,800.0};
	float scaling[] = {0.0, 7.5, 8.5, 12.0};
	float ProjectileDamage = 10.0 + (Pow(ArcaneDamage[owner]*Pow(ArcanePower[owner], 4.0),spellScaling[spellLevel]) * scaling[spellLevel]);
	if(HasEntProp(entity, Prop_Data, "m_vecOrigin"))
	{
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", projvec);
		EntityExplosion(owner,ProjectileDamage,radius[spellLevel], projvec,0,false,entity,_,1073741824);
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
		
	char strName[32];
	GetEntityClassname(client, strName, 32);
	if(StrEqual(strName,"tf_projectile_arrow",false))
		return Plugin_Continue;
		
	float projvec[3];
	
	float level = ArcaneDamage[owner];
	float ProjectileDamage = 90.0 + (Pow(level*Pow(ArcanePower[owner], 4.0),2.45) * 120.0);
	if(HasEntProp(entity, Prop_Data, "m_vecOrigin"))
	{
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", projvec);
		EntityExplosion(owner,ProjectileDamage,500.0, projvec,0,false,entity,_,1073741824);
	}
		
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
		
	char strName[32];
	GetEntityClassname(client, strName, 32);
	if(StrEqual(strName,"tf_projectile_arrow",false))
		return Plugin_Continue;
		
	float projvec[3];
	if(HasEntProp(entity, Prop_Data, "m_vecOrigin"))
	{
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
					TF2_AddCondition(i,TFCond_MegaHeal,3.0);
				}
			}
		}
		RemoveEntity(entity);
	}
		
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
	
	if(HasEntProp(entity, Prop_Data, "m_vecOrigin"))
	{
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
			EntityExplosion(owner, damageDealt * TF2_GetDamageModifiers(owner, CWeapon), Radius, projvec, _, _,entity,_,_,CWeapon,_,_,true);
		}
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
	
	if(HasEntProp(entity, Prop_Data, "m_vecOrigin"))
	{
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", projvec);
		int CWeapon = EntRefToEntIndex(jarateWeapon[entity]);
		if(IsValidEdict(CWeapon))
		{
			EntityExplosion(owner, TF2_GetDamageModifiers(owner, CWeapon) * 60.0, 400.0, projvec, 1, _,entity,1.0,_,_,0.75);
		}
	}
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
			float damageDealt = 30.0;
			Address multiHitActive = TF2Attrib_GetByName(CWeapon, "taunt move acceleration time");
			if(multiHitActive != Address_Null)
			{
				damageDealt *= TF2Attrib_GetValue(multiHitActive) + 1.0;
			}
			currentDamageType[owner].second |= DMG_IGNOREHOOK;
			SDKHooks_TakeDamage(client, owner, owner, damageDealt*TF2_GetDamageModifiers(owner, CWeapon, false), DMG_BULLET, CWeapon, _,_,false);
		}
		RemoveEntity(entity);
	}

	SDKUnhook(entity, SDKHook_Touch, OnCollisionWarriorArrow);
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

	char strName[32];
	GetEntityClassname(client, strName, 32)
	char strName1[32];
	GetEntityClassname(entity, strName1, 32)

	if(IsValidForDamage(client) && IsOnDifferentTeams(owner,client))
	{
		if(!StrEqual(strName, strName1))
		{
			int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
			if(IsValidEdict(CWeapon))
			{
				currentDamageType[owner].second |= DMG_IGNOREHOOK;
				SDKHooks_TakeDamage(client, owner, owner, projectileDamage[entity], DMG_BULLET, _, _,_,false);
			}
			if(IsValidClient3(client)){
				ShouldNotHome[entity][client] = true;
				BleedBuildup[client] += 4.0;
				checkBleed(client, owner, _, projectileDamage[entity]*3.0);
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
					currentDamageType[owner].second |= DMG_IGNOREHOOK;
					SDKHooks_TakeDamage(client, owner, owner, damageDealt, DMG_BULLET, CWeapon, _,_,false);
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
				currentDamageType[owner].second |= DMG_IGNOREHOOK;
				SDKHooks_TakeDamage(client, owner, owner, 50.0*TF2_GetDamageModifiers(owner, CWeapon, false), DMG_BULLET, CWeapon, _,_,false);
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
					float damage = TF2_GetDPSModifiers(owner,CWeapon)*25.0;
					Address lameMult = TF2Attrib_GetByName(CWeapon, "dmg penalty vs players");
					if(lameMult != Address_Null)//lame. AP applies twice.
					{
						damage /= TF2Attrib_GetValue(lameMult);
					}
					DOTStock(client,owner,damage*0.1,CWeapon,DMG_BURN + DMG_PREVENT_PHYSICS_FORCE,20,0.5,0.2,true);
					currentDamageType[owner].second |= DMG_IGNOREHOOK;
					SDKHooks_TakeDamage(client,owner,owner,damage,DMG_BURN,CWeapon,_,_,false);
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
					float mult = 1.0/GetAttribute(CWeapon, "fire rate bonus", 1.0);
					currentDamageType[owner].second |= DMG_ARCANE;
					currentDamageType[owner].second |= DMG_IGNOREHOOK;
					SDKHooks_TakeDamage(client,owner,owner,mult*40.0,DMG_GENERIC,CWeapon, _,_,false);
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
		if(owner == client)
			{RemoveEntity(entity);return Plugin_Handled;}

		if(IsValidClient3(owner) && IsOnDifferentTeams(owner,client))
		{
			int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
			if(IsValidEdict(CWeapon))
			{
				float damageDealt = 180.0 * TF2_GetDamageModifiers(owner, CWeapon);
				currentDamageType[owner].second |= DMG_IGNOREHOOK;
				SDKHooks_TakeDamage(client, owner, owner, damageDealt, DMG_SLASH, CWeapon,_,_,false);
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
	if(!client)
		RemoveEntity(entity);
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
					float damageDealt = 70.0 * TF2_GetDamageModifiers(owner, CWeapon);
					EntityExplosion(owner, damageDealt, 200.0, origin, 0, true, entity, _, _,_,_,_,_,_,_,_,_,_,true);
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
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", pos);
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
	isPrimed[entity] = true;
	return Plugin_Stop;
}
public Action:OnStartTouchJars(entity, other)
{
	SDKHook(entity, SDKHook_Touch, OnTouchExplodeJar);
	return Plugin_Handled;
}
public Action:OnTouchExplodeJar(entity, other)
{
	float clientvec[3], Radius=144.0;
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
		if(entityMaelstromChargeCount[entity] > 0){
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
			TE_SetupBeamRingPoint(clientvec, 20.0, Radius*(1+0.01*entityMaelstromChargeCount[entity]), g_LightningSprite, spriteIndex, 0, 5, 0.5, 10.0, 1.0, color, 200, 0);
			TE_SendToAll();
			
			EmitSoundToAll(SOUND_THUNDER, entity, _, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,clientvec);
			
			float LightningDamage = 200.0 * damageBoost * entityMaelstromChargeCount[entity];
			
			int i = -1;
			while ((i = FindEntityByClassname(i, "*")) != -1)
			{
				if(IsValidForDamage(i) && IsOnDifferentTeams(owner,i))
				{
					float VictimPos[3];
					GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
					VictimPos[2] += 30.0;
					if(GetVectorDistance(clientvec,VictimPos,true) <= Radius*Radius*(1+0.01*entityMaelstromChargeCount[entity])*(1+0.01*entityMaelstromChargeCount[entity]))
						if(IsPointVisible(clientvec,VictimPos)){
							currentDamageType[owner].second |= DMG_IGNOREHOOK;
							SDKHooks_TakeDamage(i,owner,owner, LightningDamage, 1073741824, _,_,_,false);
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
									currentDamageType[owner].second |= DMG_IGNOREHOOK;
									SDKHooks_TakeDamage(i,owner,owner,30.0*damageBoost,DMG_BULLET,CWeapon,_,_,false);
									if(isPlayer){
										miniCritStatusVictim[i] = currentGameTime+8.0;
										Buff jarateDebuff;
										jarateDebuff.init("Jarated", "", Buff_Jarated, RoundToNearest(damageBoost), owner, 8.0);
										insertBuff(i, jarateDebuff);
									}
								}
								case 1:
								{
									if(isPlayer)
										TF2_AddCondition(i,TFCond_Milked,0.01);
										
									currentDamageType[owner].second |= DMG_IGNOREHOOK;
									SDKHooks_TakeDamage(i,owner,owner,30.0*damageBoost,DMG_BULLET,CWeapon,_,_,false);
								}
							}//corrosiveDOT
							if(isPlayer)
							{
								Address jarArmorBrokenBuff = TF2Attrib_GetByName(CWeapon, "jar applies armor decay");
								if(jarArmorBrokenBuff != Address_Null)
								{
									Buff pierceBuff;
									pierceBuff.init("Broken Armor", "", Buff_BrokenArmor, RoundFloat(TF2Attrib_GetValue(jarArmorBrokenBuff)), owner, 6.0);
									insertBuff(i, pierceBuff);
								}
								Address jarCorrosive = TF2Attrib_GetByName(CWeapon, "building cost reduction");
								if(jarCorrosive != Address_Null)
								{
									float damageDealt = TF2_GetDPSModifiers(owner,CWeapon)*TF2Attrib_GetValue(jarCorrosive);
									corrosiveDOT[i][owner][0] = damageDealt;
									corrosiveDOT[i][owner][1] = 2.0
								}
							}
						}
						else
						{
							if(!isPlayer)
								continue;
								
							Address jarAfterburnImmunity = TF2Attrib_GetByName(CWeapon, "overheal decay disabled");
							if(jarAfterburnImmunity != Address_Null)
								TF2_AddCondition(i,TFCond_AfterburnImmune,TF2Attrib_GetValue(jarAfterburnImmunity));

							if(GetAttribute(CWeapon, "no crit vs nonburning", 0.0) > 0.0)
							{
								Buff hasteBuff;
								hasteBuff.init("Minor Haste", "", Buff_Haste, 1, owner, GetAttribute(CWeapon, "no crit vs nonburning", 0.0));
								hasteBuff.additiveAttackSpeedMult = 0.5;
								insertBuff(i, hasteBuff);
							}

							Address jarDefensiveBuff = TF2Attrib_GetByName(CWeapon, "set cloak is feign death");
							if(jarDefensiveBuff != Address_Null)
								giveDefenseBuff(i,TF2Attrib_GetValue(jarDefensiveBuff));

							Address jarArmorPierceBuff = TF2Attrib_GetByName(CWeapon, "jar gives armor penetration");
							if(jarArmorPierceBuff != Address_Null)
							{
								Buff pierceBuff;
								pierceBuff.init("Armor Piercing Boost", "", Buff_PiercingBuff, 1, owner, 6.0);
								pierceBuff.severity = TF2Attrib_GetValue(jarArmorPierceBuff);
								insertBuff(i, pierceBuff);
							}
							
							TF2_RemoveCondition(i, TFCond_OnFire);
						}
					}
				}
			}
		}
		Address jarFragsToggle = TF2Attrib_GetByName(CWeapon, "overheal decay penalty");
		if(jarFragsToggle != Address_Null)
		{
			for(i = 0;i<RoundToNearest(TF2Attrib_GetValue(jarFragsToggle));++i)
			{
				int iEntity = CreateEntityByName("tf_projectile_syringe");
				if (IsValidEdict(iEntity)) 
				{
					int iTeam = GetClientTeam(owner);
					float fAngles[3]
					float fOrigin[3];
					float vBuffer[3]
					float fVelocity[3]
					float fwd[3]
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);
					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
					fOrigin = clientvec;
					fAngles[0] = GetRandomFloat(0.0,-60.0)
					fAngles[1] = GetRandomFloat(-179.0,179.0)

					GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
					ScaleVector(fwd, 30.0);
					
					AddVectors(fOrigin, fwd, fOrigin);
					GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					
					float velocity = 2000.0;
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
public Action:OnCollisionJarateFrag(entity, client)
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
					currentDamageType[owner].second |= DMG_IGNOREHOOK;
					SDKHooks_TakeDamage(client, owner, owner, damageDealt, DMG_BULLET, CWeapon, _,_,false);
				}
			}
			Address fragmentExplosion = TF2Attrib_GetByName(CWeapon, "overheal decay bonus");
			if(fragmentExplosion != Address_Null && TF2Attrib_GetValue(fragmentExplosion) > 0.0)
			{
				float Radius = 50.0, clientvec[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", clientvec)
				Address blastRadius1 = TF2Attrib_GetByName(CWeapon, "Blast radius increased");
				Address blastRadius2 = TF2Attrib_GetByName(CWeapon, "Blast radius decreased");
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
					currentDamageType[owner].second |= DMG_FROST;
					currentDamageType[owner].second |= DMG_PIERCING;
					currentDamageType[owner].second |= DMG_IGNOREHOOK;
					float damageDealt = 0.5*TF2Util_GetEntityMaxHealth(jarateWeapon[entity]);
					SDKHooks_TakeDamage(client, owner, owner, damageDealt, DMG_PREVENT_PHYSICS_FORCE, CWeapon, _,_,false);
					RemoveEntity(entity);
				}
			}
		}
	}
	return Plugin_Stop;
}
public Action:meteorCollision(entity, client)
{		
	if(!IsValidEdict(entity))
		return Plugin_Continue;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return Plugin_Continue;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;

	int CWeapon = jarateWeapon[entity];
	if(IsValidEdict(CWeapon))
	{
		float position[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
		EntityExplosion(owner, TF2_GetDamageModifiers(owner,CWeapon) * 45.0, 250.0, position, 0, _, entity);
		return Plugin_Continue;
	}
		
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
	int maxBounces = 0;
	
	if(HasEntProp(entity, Prop_Data, "m_vecOrigin"))
	{
		int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
		if(IsValidEdict(CWeapon))
		{
			Address bounceActive = TF2Attrib_GetByName(CWeapon, "ReducedCloakFromAmmo")
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
			EntityExplosion(owner, 80.0, 500.0, vOrigin, 0,_,entity,1.0,DMG_SONIC+DMG_PREVENT_PHYSICS_FORCE+DMG_RADIUS_MAX,CWeapon,0.75);
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
public Action:OnTouch(entity, other)
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
		CloseHandle(trace);
		return Plugin_Continue;
	}
	
	float vNormal[3];
	TR_GetPlaneNormal(trace, vNormal);
	
	//PrintToServer("Surface Normal: [%.2f, %.2f, %.2f]", vNormal[0], vNormal[1], vNormal[2]);
	
	CloseHandle(trace);
	
	float dotProduct = GetVectorDotProduct(vNormal, vVelocity);
	
	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);
	
	float vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);
	
	float vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);
	
	//PrintToServer("Angles: [%.2f, %.2f, %.2f] -> [%.2f, %.2f, %.2f]", vAngles[0], vAngles[1], vAngles[2], vNewAngles[0], vNewAngles[1], vNewAngles[2]);
	//PrintToServer("Velocity: [%.2f, %.2f, %.2f] |%.2f| -> [%.2f, %.2f, %.2f] |%.2f|", vVelocity[0], vVelocity[1], vVelocity[2], GetVectorLength(vVelocity), vBounceVec[0], vBounceVec[1], vBounceVec[2], GetVectorLength(vBounceVec));
	
	Handle datapack = CreateDataPack();
	WritePackCell(datapack,EntIndexToEntRef(entity));
	for(int i=0;i<3;++i)
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