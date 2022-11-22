public Action:AddArrowCollisionFunction(entity, client)
{
	decl String:strName[128];
	GetEntityClassname(client, strName, 128)
	if(IsValidClient3(client) || !StrContains(strName,"tank_boss",false))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			RemoveEntity(entity);
		}
	}
	if(StrContains(strName,"trigger_",false) || StrEqual(strName,"tf_projectile_arrow",false) || client == -1)
	{	
		if(StrEqual(strName,"tf_projectile_arrow",false))
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
public Action:OnSunlightSpearCollision(entity, client)
{
	decl String:strName[128];
	GetEntityClassname(client, strName, 128)
	if(IsValidForDamage(client))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
			if(IsOnDifferentTeams(owner,client))
			{
				new Float:ProjectileDamage = (140.0 + (Pow(ArcaneDamage[owner] * Pow(ArcanePower[owner], 4.0), 2.45) * 35.0));
				SDKHooks_TakeDamage(client, owner, owner, ProjectileDamage, DMG_SHOCK, -1, NULL_VECTOR, NULL_VECTOR);
				Entity_Hurt(client, RoundToNearest(ProjectileDamage), owner, DMG_GENERIC);
				RemoveEntity(entity);
				CreateParticle(client, "dragons_fury_effect_parent", true, "", 2.0);
			}
		}
	}
	if(StrContains(strName,"trigger_",false) || StrEqual(strName,"tf_projectile_arrow",false) || client == -1)
	{	
		if(StrEqual(strName,"tf_projectile_arrow",false))
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
public Action:BlackskyEyeCollision(entity, client)
{		
	if(!IsValidEntity(entity))
		return Plugin_Continue;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return Plugin_Continue;
	
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;
		
	if(owner == entity || entity == client)
		return Plugin_Continue;
		
	decl String:strName[32];
	GetEntityClassname(client, strName, 32);
	if(StrEqual(strName,"tf_projectile_arrow",false))
		return Plugin_Continue;

	new Float:projvec[3];
	new Float:level = ArcaneDamage[owner];
	new Float:ProjectileDamage = 10.0 + (Pow(level*Pow(ArcanePower[owner], 4.0),2.45) * 7.5);
	if(HasEntProp(entity, Prop_Data, "m_vecOrigin"))
	{
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", projvec);
		EntityExplosion(owner,ProjectileDamage,500.0, projvec,0,false,entity,_,1073741824);
	}
		
	return Plugin_Continue;
}
public Action:CallBeyondCollision(entity, client)
{		
	if(!IsValidEntity(entity))
		return Plugin_Continue;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return Plugin_Continue;
	
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;
	
	if(owner == entity || entity == client)
		return Plugin_Continue;
		
	decl String:strName[32];
	GetEntityClassname(client, strName, 32);
	if(StrEqual(strName,"tf_projectile_arrow",false))
		return Plugin_Continue;
		
	new Float:projvec[3];
	
	new Float:level = ArcaneDamage[owner];
	new Float:ProjectileDamage = 90.0 + (Pow(level*Pow(ArcanePower[owner], 4.0),2.45) * 120.0);
	if(HasEntProp(entity, Prop_Data, "m_vecOrigin"))
	{
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", projvec);
		EntityExplosion(owner,ProjectileDamage,500.0, projvec,0,false,entity,_,1073741824);
	}
		
	return Plugin_Continue;
}
public Action:ProjectedHealingCollision(entity, client)
{		
	if(!IsValidEntity(entity))
		return Plugin_Continue;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return Plugin_Continue;
	
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return Plugin_Continue;
	
	if(owner == entity || entity == client)
		return Plugin_Continue;
		
	decl String:strName[32];
	GetEntityClassname(client, strName, 32);
	if(StrEqual(strName,"tf_projectile_arrow",false))
		return Plugin_Continue;
		
	new Float:projvec[3];
	if(HasEntProp(entity, Prop_Data, "m_vecOrigin"))
	{
		new Float:AmountHealing = (TF2_GetMaxHealth(owner) * 0.2);
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", projvec);
		for(new i = 1; i<MaxClients;i++)
		{
			if(IsValidClient3(i) && GetClientTeam(i) == GetClientTeam(owner))
			{
				new Float:VictimPos[3];
				GetClientEyePosition(i,VictimPos);
				new Float:Distance = GetVectorDistance(projvec,VictimPos);
				new Float:Range = 1000.0;
				if(Distance <= Range)
				{
					AddPlayerHealth(i, RoundToCeil(AmountHealing), 2.0 * ArcanePower[owner], true, owner);
					fl_CurrentArmor[i] += AmountHealing * 1.35 * ArcanePower[owner];
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
			EntityExplosion(owner, 25.0, 500.0, vOrigin, 0,_,entity,1.0,DMG_SONIC+DMG_PREVENT_PHYSICS_FORCE+DMG_RADIUS_MAX,CWeapon,0.75);
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