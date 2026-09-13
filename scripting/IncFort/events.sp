public Event_Playerhurt(Handle event, const char[] name, bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	float damage = GetEventFloat(event, "damageamount");	

	if(critStatus[client])
	{
		SetEventBool(event, "crit", true);
		critStatus[client] = false;
	}

	if(attacker != client && IsValidClient3(attacker)){
		isTagged[attacker][client] = true;
		DamageDealt[attacker] += damage;

		if(TF2Attrib_HookValueFloat(0.0, "plague_powerup", attacker) == 3.0){
			if(!hasBuffIndex(client, Buff_LifeLink)){
				Buff lifelinkDebuff;
				lifelinkDebuff.init("Life Link", "-35% HP drain/10s", Buff_LifeLink, RoundToCeil(GetClientHealth(attacker)*0.3), attacker, 10.0);
				insertBuff(client, lifelinkDebuff);
				SDKHooks_TakeDamage(attacker, attacker, attacker, GetClientHealth(attacker)*0.3, DMG_PREVENT_PHYSICS_FORCE|DMG_IGNOREHOOK|DMG_PIERCING,_,_,_,false);
			}
		}

		float razorbackRetaliationDamage = TF2Attrib_HookValueFloat(0.0, "razorback_retaliation", client);
		if(razorbackRetaliationDamage > 0.0 && GetGameTime() > nextRetaliationTime[client]){
			nextRetaliationTime[client] = GetGameTime() + 1.0;
			int projCount = RoundToNearest(TF2Attrib_HookValueFloat(0.0, "razorback_retaliation_count", client));

			float fAngles[3], fVelocity[3], fOrigin[3], vImpulse[3];
			int team = GetClientTeam(client);
			GetClientEyeAngles(client, fAngles);
			GetClientEyePosition(client, fOrigin);
			GetCleaverAngularImpulse(vImpulse);
			fAngles[1] -= 15.0 + 15.0/projCount;
			fAngles[0] -= 2.0;
			int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidWeapon(CWeapon))
			{
				float damageDealt = razorbackRetaliationDamage * TF2_GetDPSModifiers(client, CWeapon);
				for(int i = 0; i < projCount; i++)
				{
					fAngles[1] += 30.0/projCount;
					int iEntity = CreateEntityByName("tf_projectile_cleaver");
					if (!IsValidEdict(iEntity))
						continue;

					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", team);

					GetAngleVectors(fAngles, fVelocity, NULL_VECTOR, NULL_VECTOR);

					ScaleVector(fVelocity, 4000.0);

					// For some reason the launcher for cleavers is the inflictor during the damage step.
					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", iEntity);
					SetEntProp(iEntity, Prop_Data, "m_bIsLive", true);

					TeleportEntity(iEntity, fOrigin, fAngles, NULL_VECTOR);
					DispatchSpawn(iEntity);
					Phys_EnableDrag(iEntity, false);
					SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vImpulse, client, 50.0, 146.0);
					projectileDamage[iEntity] = damageDealt;
				}
			}
		}
	}
	if(karmicJusticeScaling[client]){
		karmicJusticeScaling[client] += 800.0*damage/float(TF2Util_GetEntityMaxHealth(client));
		if(karmicJusticeScaling[client] >= 400.0){
			karmicJusticeScaling[client] = 400.0;
			KarmicJusticeExplosion(client);
		}
	}
	if(IsValidClient3(client))
	{
		lastDamageTime[client] = GetGameTime();
		Address revengePowerup = TF2Attrib_GetByName(client, "revenge powerup");
		if(revengePowerup != Address_Null)
		{
			float revengePowerupValue = TF2Attrib_GetValue(revengePowerup);
			if(revengePowerupValue > 0.0)
			{
				RageBuildup[client] += (damage/float(TF2_GetMaxHealth(client)))*0.667;
				if(RageBuildup[client] > 1.0)
					RageBuildup[client]= 1.0;
			}
		}
		Address supernovaPowerupVictim = TF2Attrib_GetByName(client, "supernova powerup");
		if(supernovaPowerupVictim != Address_Null && TF2Attrib_GetValue(supernovaPowerupVictim) == 1.0)
		{
			SupernovaBuildup[client] += (damage/float(TF2_GetMaxHealth(client)));
			if(SupernovaBuildup[client] > 1.0)
				SupernovaBuildup[client] = 1.0;
		}
	}

	if(IsValidClient3(attacker) && !IsFakeClient(attacker))
	{
		if(damage > 0.0 && attacker != client && IsValidClient3(client))
		{
			int healers = GetEntProp(client, Prop_Send, "m_nNumHealers");
			if(healers > 0)
			{
				for(int i = 0;i<healers;++i){
					int healer = TF2Util_GetPlayerHealer(client,i);
					if(!IsValidClient3(healer))
						continue;
						
					int healingWeapon = GetEntPropEnt(healer, Prop_Send, "m_hActiveWeapon");
					if(!IsValidWeapon(healingWeapon))
						continue;

					if(GetAttribute(healingWeapon, "patient damage taken to uber", 0.0))
						AddUbercharge(healingWeapon, 100.0 * damage * GetAttribute(healingWeapon, "patient damage taken to uber", 0.0) / TF2Util_GetEntityMaxHealth(client));
					if(GetAttribute(healingWeapon, "patient damage taken to self heal", 0.0))
						AddPlayerHealth(healer,RoundToCeil(damage * GetAttribute(healingWeapon, "patient damage taken to self heal", 0.0)), _, true, healer);
				}
			}
	
			if(GetAttribute(attacker, "regeneration powerup", 0.0) == 3){
				float heal = damage+20.0;
				if(heal > bloodAcolyteBloodPool[attacker])
					heal = bloodAcolyteBloodPool[attacker];
				
				if(heal > 0.0){
					float attackerOrigin[3];
					GetClientAbsOrigin(attacker, attackerOrigin);

					for(int i = 1; i<=MaxClients;++i){
						if(!IsValidClient3(i))
							continue;
						if(!IsPlayerAlive(i))
							continue;
						if(IsOnDifferentTeams(attacker, i))
							continue;
						
						float victimOrigin[3];
						GetClientAbsOrigin(i, victimOrigin);
						if(GetVectorDistance(attackerOrigin, victimOrigin, true) > 640000.0)
							continue;

						AddPlayerHealth(i, RoundToCeil(heal), 3.0, true, attacker);
					}
					bloodAcolyteBloodPool[attacker] -= heal;
				}
			}
			if(GetAttribute(attacker, "vampire powerup", 0.0) == 2.0){
				Buff leechDebuff;
				leechDebuff.init("Leeched", "", Buff_Leech, 1, attacker, 4.0);
				insertBuff(client, leechDebuff);
			}

			int CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			if(IsValidEdict(CWeapon))
			{
				int arrowNovaCap = RoundToNearest(TF2Attrib_HookValueFloat(0.0, "arrow_nova_altfire_cap", CWeapon));
				if(arrowNovaCap && arrowExpulsionCooldown[attacker]-GetGameTime() <= 2.5){
					arrowNovaCount[attacker][client]++;
					if(arrowNovaCount[attacker][client] > arrowNovaCap){
						arrowNovaCount[attacker][client] = arrowNovaCap;
					} else if (arrowNovaCount[attacker][client] <= 0){
						arrowNovaCount[attacker][client] = 1;
					}
				}
			}
		}
	}
	if(IsValidClient3(attacker) && IsFakeClient(attacker))
	{
		if(IsValidClient3(attacker) && damage > 0.0 && attacker != client && IsValidClient3(client))
		{
			int CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			if(IsValidEdict(CWeapon))
			{
				Address LifestealActive = TF2Attrib_GetByName(CWeapon, "bot medic uber health threshold");
				if(LifestealActive != Address_Null)
				{
					int HealthGained = RoundToCeil(1.25 * damage * TF2Attrib_GetValue(LifestealActive));
					AddPlayerHealth(attacker, HealthGained, 1.5, true, attacker);
				}
				if(TF2_IsPlayerInCondition(attacker, TFCond_MedigunDebuff))
				{
					int HealthGained = RoundToCeil(damage * 0.5)
					AddPlayerHealth(attacker, HealthGained, 1.5, true, attacker);
				}
			}
		}
	}
}
public Event_UberDeployed(Event event, const char[] name, bool dontBroadcast){
	int medic = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient3(medic) || !IsPlayerAlive(medic) || TF2_GetPlayerClass(medic) != TFClass_Medic)
		return;
	
	int medigun = GetEntPropEnt(medic, Prop_Send, "m_hActiveWeapon");
	if(!IsValidWeapon(medigun))
		return;
	
	int target = GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
	ApplyUberBuffs(medic, target, medigun);

	CreateTimer(0.1, Timer_UberCheck, EntIndexToEntRef(medigun), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}
public MRESReturn OnMakeBleed(Address pPlayerShared, Handle hParams) {
	int client = GetEntityFromAddress((DereferencePointer(pPlayerShared + g_offset_CTFPlayerShared_pOuter)));

	if(!IsValidClient3(client))
		return MRES_Ignored;

	if(TF2_IsPlayerInCondition(client, TFCond_Bleeding))
		return MRES_Supercede;
		
	return MRES_Ignored;
}
public MRESReturn OnPlayerStunned(Address pPlayerShared, Handle hParams){
	int client = GetEntityFromAddress((DereferencePointer(pPlayerShared + g_offset_CTFPlayerShared_pOuter)));
	float duration = DHookGetParam(hParams, 1);
	if(!IsValidClient3(client))
		return MRES_Ignored;

	Address slowResistance = TF2Attrib_GetByName(client, "slow resistance");
	if(slowResistance != Address_Null)
	{
		DHookSetParam(hParams, 1, duration * TF2Attrib_GetValue(slowResistance));
		return MRES_ChangedHandled;
	}
	if(GetAttribute(client, "jarate description", 0.0)){
		return MRES_Supercede;
	}

	return MRES_Ignored;
}
public MRESReturn OnModifyRagePre(Address pPlayerShared, Handle hParams) {
	int client = GetEntityFromAddress((DereferencePointer(pPlayerShared + g_offset_CTFPlayerShared_pOuter)));

	if(!IsValidClient(client))
		return MRES_Ignored;	

	switch(TF2_GetPlayerClass(client))
	{
		case TFClass_Scout:{
			DHookSetParam(hParams, 1, 2.0);
		}
		case TFClass_Soldier:{
			float flMultiplier = 1.0;
			int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (IsValidEdict(CWeapon))
			{
				Address FireRate1 = TF2Attrib_GetByName(CWeapon, "fire rate bonus");
				Address FireRate2 = TF2Attrib_GetByName(CWeapon, "fire rate penalty");
				Address FireRate3 = TF2Attrib_GetByName(CWeapon, "fire rate penalty HIDDEN");
				Address FireRate4 = TF2Attrib_GetByName(CWeapon, "fire rate bonus HIDDEN");
				
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
		case TFClass_Pyro:{
			DHookSetParam(hParams, 1, 0.4);
		}
		case TFClass_Sniper:{
			int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (IsValidEdict(CWeapon) && TF2Util_GetPlayerLoadoutEntity(client,1) == CWeapon)
			{
				DHookSetParam(hParams, 1, 1.0);
			}
		}
		case TFClass_Medic:{
			float value = DHookGetParam(hParams, 1);
			// It originally takes 400 heals to build up, so 100/150 = 2/3x slower (~4x HP), and scales with max hp upgrade.
			DHookSetParam(hParams, 1, 100.0*value/TF2Util_GetEntityMaxHealth(client));
		}
	}
	return MRES_ChangedHandled;
}
public MRESReturn OnCondApply(Address pPlayerShared, Handle hParams) {
	int client = GetEntityFromAddress((DereferencePointer(pPlayerShared + g_offset_CTFPlayerShared_pOuter)));
	float duration = DHookGetParam(hParams, 2);
	TFCond cond = view_as<TFCond>(DHookGetParam(hParams, 1));
	if(IsValidClient3(client))
	{
		float agilityPowerup = TF2Attrib_HookValueFloat(0.0, "agility_powerup", client);
		float juggernautPowerup = TF2Attrib_HookValueFloat(0.0, "juggernaut_powerup", client);

		if(agilityPowerup == 1 || juggernautPowerup == 1){
			switch(cond)
			{
				case TFCond_Slowed, TFCond_TeleportedGlow, TFCond_Dazed, TFCond_FreezeInput, TFCond_GrappledToPlayer, TFCond_LostFooting, TFCond_AirCurrent:
				{
					return MRES_Supercede;
				}
			}
		}

		switch(cond)
		{
			case TFCond_OnFire:
			{
				Address attribute1 = TF2Attrib_GetByName(client, "absorb damage while cloaked");
				if (attribute1 != Address_Null) 
				{
					if(GetRandomFloat(0.0,1.0) <= TF2Attrib_GetValue(attribute1))
					{
						return MRES_Supercede;
					}
				}
			}
			case TFCond_Milked:
			{
				return MRES_Supercede;
			}
			case TFCond_DefenseBuffed:
			{
				return MRES_Supercede;
			}
			case TFCond_RegenBuffed:
			{
				return MRES_Supercede;
			}
			case TFCond_CritMmmph:
			{
				return MRES_Supercede;
			}
			case TFCond_FocusBuff:
			{
				int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEdict(CWeapon))
					if(TF2Attrib_HookValueFloat(0.0, "sniper_rage_DISPLAY_ONLY", CWeapon))
						return MRES_Supercede;
			}
			case TFCond_Jarated, TFCond_MarkedForDeath, TFCond_MarkedForDeathSilent:
			{
				if(TF2Attrib_HookValueFloat(0.0, "inverter_powerup", client) == 1){
					giveDefenseBuff(client, duration);
					return MRES_Supercede;
				}
				else if(TF2Attrib_HookValueFloat(0.0, "inverter_powerup", client) == 2){
					Buff critligma;
					critligma.init("Marked for Crits", "All hits taken are critical", Buff_CritMarkedForDeath, 1, client, duration);
					insertBuff(client, critligma);
					return MRES_Supercede;
				}
				return MRES_Handled;
			}
			case TFCond_MiniCritOnKill:
			{
				miniCritStatusAttacker[client] = GetGameTime()+duration;
				return MRES_Supercede;
			}
			case TFCond_CritCola:
			{
				miniCritStatusAttacker[client] = GetGameTime()+duration;
				if(TF2Attrib_HookValueFloat(0.0, "inverter_powerup", client) == 1)
					giveDefenseBuff(client, duration);
				else if(TF2Attrib_HookValueFloat(0.0, "inverter_powerup", client) == 2){
					Buff critligma;
					critligma.init("Marked for Crits", "All hits taken are critical", Buff_CritMarkedForDeath, 1, client, duration);
					insertBuff(client, critligma);
				}
				else if(TF2Attrib_HookValueFloat(0.0, "inverter_powerup", client) != 3){
					miniCritStatusVictim[client] = GetGameTime()+duration;
				}
				return MRES_Supercede;
			}
			case TFCond_RestrictToMelee:
			{
				if(TF2Attrib_HookValueFloat(0.0, "inverter_powerup", client) == 1 || TF2Attrib_HookValueFloat(0.0, "inverter_powerup", client) == 3)
					return MRES_Supercede;
			}
			case TFCond_Sapped:
			{
				if(TF2Attrib_HookValueFloat(0.0, "inverter_powerup", client) != 3){
					TF2_RemoveCondition(client, TFCond_Ubercharged);
					TF2_RemoveCondition(client, TFCond_Cloaked);
					TF2_RemoveCondition(client, TFCond_Disguised);
					TF2_RemoveCondition(client, TFCond_MegaHeal);
					TF2_RemoveCondition(client, TFCond_DefenseBuffNoCritBlock);
					TF2_RemoveCondition(client, TFCond_DefenseBuffMmmph);
					TF2_RemoveCondition(client, TFCond_UberchargedHidden);
					TF2_RemoveCondition(client, TFCond_UberBulletResist);
					TF2_RemoveCondition(client, TFCond_UberBlastResist);
					TF2_RemoveCondition(client, TFCond_UberFireResist);
					TF2_RemoveCondition(client, TFCond_AfterburnImmune);
				}else{
					return MRES_Supercede;
				}
			}
			case TFCond_Ubercharged, TFCond_Cloaked, TFCond_Disguised, TFCond_MegaHeal, TFCond_DefenseBuffNoCritBlock,TFCond_DefenseBuffMmmph,
			TFCond_UberchargedHidden, TFCond_UberBulletResist, TFCond_UberBlastResist, TFCond_UberFireResist, TFCond_AfterburnImmune, TFCond_Kritzkrieged, TFCond_CritCanteen:
			{
				if(TF2_IsPlayerInCondition(client, TFCond_Sapped) || TF2Attrib_HookValueFloat(0.0, "inverter_powerup", client) == 3 || hasBuffIndex(client, Buff_Nullification))
					return MRES_Supercede;
			}
			case TFCond_ParachuteDeployed:
			{
				int canRedeploy = RoundToNearest(GetAttributeAccumulateAdditive(client, "powerup max charges", 0.0));
				if(canRedeploy > 0)
					return MRES_Supercede;
			}
			case TFCond_Taunting:
			{
				int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEdict(CWeapon))
				{
					float healSeverity = TF2Attrib_HookValueFloat(1.0, "consu_heal_buff", CWeapon);
					if(healSeverity > 1){
						Buff healingBuff;
						healingBuff.init("Incoming Healing Boost", "", Buff_HealingBuff, 1, client, 8.0, healSeverity);
						insertBuff(client, healingBuff);
					}

					float tauntRate = TF2Attrib_HookValueFloat(1.0, "taunt_time_mult", CWeapon);
					if(tauntRate != 1.0){
						TF2Attrib_SetByName(CWeapon, "gesture speed increase", tauntRate);
					}

					RequestFrame(ApplyTauntAttackSpeed, EntIndexToEntRef(client));
				}
			}
			case TFCond_Charging:
			{
				TF2Attrib_AddCustomPlayerAttribute(client, "Attack not cancel charge", 1.0, 0.25);
			}
		}
	}
	return MRES_Ignored;
}
public MRESReturn OnBulletTrace(int victim, Handle hParams){
	float direction[3];
	DHookGetParamVector(hParams, 2, direction);
	CTakeDamageInfo info = CTakeDamageInfo.FromAddress(DHookGetParamAddress(hParams, 1));
	int attacker = EHandleToEntIndex(info.m_hAttacker);
	if(!IsValidClient3(attacker))
		return MRES_Ignored;

	int weapon = EHandleToEntIndex(info.m_hWeapon);
	if(!IsValidWeapon(weapon))
		return MRES_Ignored;

	if(TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee)
		return MRES_Ignored;

	if(IsValidClient3(attacker) && IsValidWeapon(weapon)){
		float pos[3];
		GetClientEyePosition(attacker, pos);
		GetVectorAngles(direction, direction);
		TR_TraceRayFilter(pos, direction, MASK_SOLID, RayType_Infinite, FilterPlayer, attacker);
		if (TR_DidHit()) {
			float endpos[3];
			TR_GetEndPosition(endpos);

			float explosiveBullet = GetAttribute(weapon, "explosive bullets radius", 0.0);
			if(explosiveBullet)
				EntityExplosion(attacker, info.m_flDamage * TF2_GetDamageModifiers(attacker, weapon, _, false), explosiveBullet, endpos, _, _, _, 0.4, _, weapon, 0.3, _, _, "ExplosionCore_sapperdestroyed");

			float dragonBullet = TF2Attrib_HookValueFloat(0.0, "dragon_bullets_radius", weapon);
			if(dragonBullet){
				EntityExplosion(attacker, info.m_flDamage * TF2_GetDamageModifiers(attacker, weapon, _, false), dragonBullet, endpos, _, _, _, _, _, weapon, 0.3, _, true);
				CreateParticleEx(-1, "heavy_ring_of_fire", -1, -1, endpos);
			}
		}
	}
	return MRES_Ignored;
}
public MRESReturn OnKnockbackApply(int client, Handle hParams) {
	if(IsValidClient3(client))
	{
		float initKB[3];
		DHookGetParamVector(hParams,1,initKB);

		if(IsValidWeapon(lastKBSource[client])){
			ScaleVector(initKB,GetAttribute(lastKBSource[client], "weapon self dmg push force increased", 1.0));
			ScaleVector(initKB,GetAttribute(lastKBSource[client], "weapon push force multiplier", 1.0));
		}

		float KBMult = TF2Attrib_HookValueFloat(1.0, "knockback_resistance", client);
		if(IsFakeClient(client)){
			ScaleVector(initKB, KBMult);
		}
		else{
			if(!IsValidWeapon(lastKBSource[client]) && client != lastKBSource[client]){
				ScaleVector(initKB, KBMult)
			}
		}
		DHookSetParamVector(hParams, 1,initKB);
		lastKBSource[client] = 0;
	}
	return MRES_Override;
}
public MRESReturn OnAirblast(int weapon, Handle hParams){
	if(IsValidWeapon(weapon)){
		int owner = getOwner(weapon);

		if(TF2Attrib_HookValueFloat(0.0, "disable_custom_airblast", weapon) == 0.0){
			float AirblastDamage = 25.0 * GetAttribute(weapon, "airblast pushback scale") * TF2_GetDamageModifiers(owner, weapon);
			float TotalRange = 600.0 * GetAttribute(weapon, "deflection size multiplier");
			float ConeRadius = 40.0 * GetAttribute(weapon, "melee bounds multiplier");

			Buff airblasted;
			airblasted.init("Airblasted", "", Buff_Airblasted, 1, owner, 4.0 * GetAttribute(weapon, "melee range multiplier"));
			airblasted.multiplicativeMoveSpeedMult = 0.7 / GetAttribute(weapon, "airblast vertical pushback scale");
			Buff dragonDance;
			dragonDance.init("Combo Starter", "", Buff_DragonDance, weapon, owner, 2.0);
			for(int i=1; i<=MaxClients; ++i)
			{
				if(IsValidClient3(i) && IsClientInGame(i) && IsPlayerAlive(i))
				{
					if(IsTargetInSightRange(owner, i, ConeRadius, TotalRange, true, false))
					{
						if(IsAbleToSee(owner,i, false) == true)
						{
							if(GetClientTeam(i) != GetClientTeam(owner))
							{
								SDKHooks_TakeDamage(i,owner,owner,AirblastDamage,DMG_BLAST|DMG_IGNOREHOOK,weapon,_,_,false);
								
								float dDanceAttr = TF2Attrib_HookValueFloat(0.0, "airblast_flings_enemy", weapon);
								if(dDanceAttr){
									float flingVelocity[3];
									flingVelocity[2] = dDanceAttr;
									TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, flingVelocity);
									insertBuff(i, dragonDance);
								}

								if(TF2Attrib_HookValueFloat(0.0, "agility_powerup", owner) == 1.0)
									continue;
								
								if(TF2_IsPlayerInCondition(i,TFCond_MegaHeal))
									continue;
								
								insertBuff(i, airblasted);
							}
							else
							{
								TF2_AddCondition(i, TFCond_AfterburnImmune, 6.0, owner);
								TF2_AddCondition(i, TFCond_SpeedBuffAlly, 6.0);
								TF2_AddCondition(i, TFCond_DodgeChance, 0.2);
							}
						}
					}
				}
			}
		}

		if(TF2Attrib_HookValueFloat(0.0, "airblast_fires_arrows", weapon)){
			int iEntity = CreateEntityByName("tf_projectile_arrow");
			if (IsValidEntity(iEntity)){
				float fAngles[3],fOrigin[3], vBuffer[3],fVelocity[3],fwd[3],right[3];
				int iTeam = GetClientTeam(owner);
				SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);

				SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
				SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
				SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", owner);
				SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", owner);
				GetClientEyePosition(owner, fOrigin);
				GetClientEyeAngles(owner,fAngles);
				GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
				GetAngleVectors(fAngles,fwd, right, NULL_VECTOR);

				ScaleVector(fwd, 30.0);
				AddVectors(fOrigin, fwd, fOrigin);

				fVelocity[0] = vBuffer[0]*2500.0;
				fVelocity[1] = vBuffer[1]*2500.0;
				fVelocity[2] = vBuffer[2]*2500.0;
				SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
				TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
				DispatchSpawn(iEntity);
				SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchAirblastArrow);
				SDKHook(iEntity, SDKHook_Touch, AddArrowCollisionFunction);
				projectileDamage[iEntity] = 50.0 * TF2_GetDamageModifiers(owner, weapon);
				int color[4]={255, 200, 0,225};
				TE_SetupBeamFollow(iEntity,Laser,0,0.2,3.0,3.0,1,color);
				TE_SendToAll();
			}
		}

		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
	}
	return MRES_Ignored;
}
public MRESReturn OnPrimaryAttack(int weapon, Handle hParams){
	if(IsValidWeapon(weapon)){
		float tickInterval = GetTickInterval();
		float nextFireTime = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
		float fireInterval = nextFireTime-GetGameTime();
		if(fireInterval <= tickInterval)
			return MRES_Ignored;
	
		float leftover = 1-((fireInterval/tickInterval)-RoundToFloor(fireInterval/tickInterval));
		weaponSavedAttackTime[weapon] += leftover*tickInterval;
		if(weaponSavedAttackTime[weapon] >= tickInterval){
			int overflowTimes = RoundToFloor(weaponSavedAttackTime[weapon]/tickInterval);
			weaponSavedAttackTime[weapon] -= overflowTimes*tickInterval;
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+tickInterval*(RoundToCeil(fireInterval/tickInterval)-overflowTimes));
			
			//PrintToServer("times: %d | saved time: %f | old interval: %f | new interval: %f", overflowTimes, weaponSavedAttackTime[weapon], fireInterval, tickInterval*(RoundToCeil(fireInterval/tickInterval)-overflowTimes));
		}
	}
	return MRES_Ignored;
}
public MRESReturn OnThermalThrusterLaunch(int weapon){
	if(IsValidWeapon(weapon)){
		int owner = getOwner(weapon);
		lastKBSource[owner] = weapon;
		
		float jetpackLunge = TF2Attrib_HookValueFloat(0.0, "jetpack_charge_damage", weapon)
		if(jetpackLunge){
			CreateParticle(owner, "utaunt_auroraglow_orange_parent", true, _, 3.5);

			Buff infernalLunge;
			infernalLunge.init("Infernal Lunge", "Deals Contact Damage", Buff_InfernalLunge, 1, owner, 4.0, jetpackLunge);
			insertBuff(owner, infernalLunge);
		}
	}
	return MRES_Ignored;
}
//New bot speed cap is 3khu/s
public MRESReturn OnCalculateBotSpeedPost(int client, Handle hReturn) {
	DHookSetReturn(hReturn, 3000.0);
	return MRES_Supercede;
}

public MRESReturn OnSentryThink(int entity)  {
	if(IsValidEdict(entity))
	{
		if(sentryThought[entity] == false)
		{
			sentryThought[entity] = true;
			return MRES_Ignored;
		}
	}
	return MRES_Supercede;
}
//This one is a recursive per tick think essentially, so if you return to override it'll stop the thinking.
public MRESReturn OnFireballRangeThink(int entity)  {
	isProjectileFireball[entity] = true;
	return MRES_Supercede;
}
public MRESReturn OnShieldChargeMove(Address address, Handle hReturn){
	DHookSetReturn(hReturn, false);
	return MRES_Supercede;
}
public MRESReturn IsInWorldCheck(int entity, Handle hReturn, Handle hParams)  {
	if(IsValidEdict(entity))
	{
		char sClass[32];
		float position[3];
		GetEdictClassname(entity, sClass, sizeof(sClass));
		if(StrContains(sClass, "_projectile")) 
    	{ 
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
			if(!TR_PointOutsideWorld(position))
			{
				DHookSetReturn(hReturn, true);
				return MRES_Supercede;
			}
    	} 
	}
	return MRES_Ignored;
}
public MRESReturn CheckEntityVelocity(Address pPlayerShared, Handle hReturn)  {
	DHookSetReturn(hReturn, 1);
	return MRES_Supercede;
}
public MRESReturn OnRecoilApplied(int entity, Handle hParams)  {
	//DHookSetParamVector(hParams, 1, {0.0,0.0,0.0});
	return MRES_ChangedHandled;
}
public MRESReturn OnCurrencySpawn(int entity, Handle hParams)  {
	float amount = DHookGetParam(hParams, 1);

	additionalstartmoney += amount;
	for (int i = 1; i <= MaxClients; ++i) 
	{
		CurrencyOwned[i] += amount;

		if(!IsValidClient3(i))
			continue;
		if(!IsPlayerAlive(i))
			continue;
		if(GetClientTeam(i) != 2)
			continue;
		if(TF2_GetPlayerClass(i) != TFClass_Scout)
			continue;

		float overhealPCT = 1.0+(0.5*TF2Attrib_HookValueFloat(1.0, "mult_patient_overheal_penalty", i));
		int healAmount = RoundToCeil(TF2_GetMaxHealth(i) * 0.03 * TF2Attrib_HookValueFloat(1.0, "mult_health_fromhealers", i));
		AddPlayerHealth(i, healAmount, overhealPCT, true, 0);
	}

	CheckForGamestage();

	DHookSetParam(hParams, 1, 0);
	
	RemoveEntity(entity);

	return MRES_ChangedHandled;
}
public Event_PlayerHealed(Handle event, const char[] name, bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "patient"));
	int healer = GetClientOfUserId(GetEventInt(event, "healer"));
	int amount = GetEventInt(event, "amount");
	
	Healed[healer] += float(amount);

	if(hasBuffIndex(client, Buff_Leech)){ //This is post healing modifiers, so this should be after all reductions.
		AddPlayerHealth(playerBuffs[client][getBuffInArray(client, Buff_Leech)].inflictor, amount);
	}
	if(TF2Attrib_HookValueFloat(0.0, "king_powerup", client) == 2.0){
		if(IsValidClient3(tagTeamTarget[client]) && IsPlayerAlive(tagTeamTarget[client]) && !IsOnDifferentTeams(client, tagTeamTarget[client]) ){
			AddPlayerHealth(tagTeamTarget[client], amount);
		}
	}
}
public TF2Spawn_EnterSpawn(int client, int spawn)
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		int melee = TF2Util_GetPlayerLoadoutEntity(client,2);
		if(IsValidEdict(melee))
		{
			TF2Attrib_SetByName(melee,"airblast vulnerability multiplier hidden", 0.0);
			TF2Attrib_SetByName(melee,"damage force increase hidden", 0.0);
		}
	}
}
public TF2Spawn_LeaveSpawn(int client, int spawn)
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		int melee = TF2Util_GetPlayerLoadoutEntity(client,2);
		if(IsValidEdict(melee))
		{
			TF2Attrib_SetByName(melee,"airblast vulnerability multiplier hidden", 1.0);
			TF2Attrib_SetByName(melee,"damage force increase hidden", 1.0);
		}
	}
}
public void TF2_OnConditionAdded(client, TFCond cond)
{
	switch(cond){
		case TFCond_Sapped:{
			buffChange[client] = true;
		}
		case TFCond_Slowed:{
			if(TF2Attrib_HookValueFloat(0.0, "inverter_powerup", client) == 1){
				TF2_AddCondition(client, TFCond_HalloweenSpeedBoost, 3.0);
				TF2_RemoveCondition(client, cond);
			}
		}
		case TFCond_Bonked:{
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 8.0);
			TF2_AddCondition(client, TFCond_HalloweenQuickHeal, 8.0);
			TF2_RemoveCondition(client, cond);
			removeAfterburn(client);
		}
		case TFCond_Ubercharged, TFCond_UberchargedCanteen,
		TFCond_AfterburnImmune:
		{
			removeAfterburn(client);
		}
		case TFCond_UberchargedHidden:
		{
			removeAfterburn(client);
			TF2Attrib_SetByName(client, "jump height cancel", 1.0/TF2Attrib_HookValueFloat(1.0, "mod_jump_height", client));
		}
	}
	TF2Util_UpdatePlayerSpeed(client);
}
public void TF2_OnConditionRemoved(client, TFCond:cond)
{
	switch(cond)
	{
		case TFCond_OnFire:{
			fl_HighestFireDamage[client] = 0.0;
		}
		case TFCond_Charging:{
			float grenadevec[3];
			GetClientEyePosition(client, grenadevec);
			int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			int secondary = TF2Util_GetPlayerLoadoutEntity(client,1);
			if(IsValidWeapon(CWeapon) && IsValidEntity(secondary))
			{
				float damage = TF2_GetDPSModifiers(client,CWeapon,false,false) * 70.0;
				damage *= TF2Attrib_HookValueFloat(1.0, "charge_impact_damage", secondary);
				damage *= 1.0 + 0.1 * (GetEntProp(client, Prop_Send, "m_iDecapitations") > 5 ? 5 : GetEntProp(client, Prop_Send, "m_iDecapitations"));
				
				if(GetAttribute(CWeapon, "charge explosion ignites instead", 0.0)){
					float targetVec[3];
					for(int i = 1; i <= MaxClients; ++i){
						if(!IsValidClient3(i))
							continue;

						if(!IsOnDifferentTeams(client, i))
							continue;
						
						GetClientAbsOrigin(i, targetVec);
						if(GetVectorDistance(grenadevec, targetVec, true) > 250000.0)
							continue;

						applyAfterburn(i, client, CWeapon, damage);
					}
				}else{
					EntityExplosion(client, damage, 500.0, grenadevec, 1, _, secondary, _, DMG_ALWAYSGIB | DMG_DISSOLVE, CWeapon);
				}
			}
		}
		case TFCond_Sapped:{
			buffChange[client] = true;
		}
		case TFCond_Taunting:
		{
			int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEdict(CWeapon))
			{
				float damageReduction = GetAttribute(CWeapon, "energy buff dmg taken multiplier", 1.0);
				if(damageReduction != 1.0)
					TF2Attrib_AddCustomPlayerAttribute(client, "damage taken mult 3", damageReduction, 12.0);
				
				Buff lunchboxChange;
				lunchboxChange.init("Eating Buffs", "", Buff_LunchboxChange, 1, client, 12.0);
				lunchboxChange.additiveMoveSpeedMult = GetAttribute(CWeapon, "buff movement speed", 0.0);
				lunchboxChange.multiplicativeAttackSpeedMult = GetAttribute(CWeapon, "buff fire rate", 1.0);
				lunchboxChange.multiplicativeDamageTaken = GetAttribute(CWeapon, "buff damage taken", 1.0);
				if(lunchboxChange.additiveMoveSpeedMult != 0.0 || lunchboxChange.multiplicativeAttackSpeedMult != 1.0 || lunchboxChange.multiplicativeDamageTaken != 1.0){
					insertBuff(client, lunchboxChange);
				}

				float afterburnImmunityDuration = TF2Attrib_HookValueFloat(0.0, "consu_afterburn_immunity", CWeapon);
				if(afterburnImmunityDuration > 0){
					TF2_AddCondition(client, TFCond_AfterburnImmune, afterburnImmunityDuration, client);
				}
			}
		}
		case TFCond_UberchargedHidden:
		{
			removeAfterburn(client);
			TF2Attrib_RemoveByName(client, "jump height cancel");
		}
	}
	TF2Util_UpdatePlayerSpeed(client);
}
public OnEntityCreated(entity, const char[] classname)
{
	if(!IsValidEdict(entity) || entity < 0 || entity > 2048)
		return;

	int reference = EntIndexToEntRef(entity);
	weaponFireRate[entity] = -1.0;
	weaponSavedAttackTime[entity] = 0.0;
	isAimlessProjectile[entity] = false;
	recursiveExplosionCount[entity] = 0;
	if(StrEqual(classname, "obj_attachment_sapper"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Sapper); 
	}
	else if(StrEqual(classname, "obj_sentrygun"))
    {
		isEntitySentry[entity] = true;
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Sentry); 
		CreateTimer(0.35, BuildingRegeneration, reference, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		RequestFrame(checkEnabledSentry, reference);
	}
	else if(StrEqual(classname, "obj_dispenser"))
    {
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Sentry); 
		CreateTimer(0.35, BuildingRegeneration, reference, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(StrEqual(classname, "obj_teleporter"))
    {
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Sentry); 
		CreateTimer(0.35, BuildingRegeneration, reference, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(StrEqual(classname, "item_powerup_rune") || StrEqual(classname, "tf_gas_manager"))
	{
		RemoveEntity(entity);
	}
	else if(StrEqual(classname, "tank_boss"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Tank);
		RequestFrame(randomizeTankSpecialty, reference);
	}
	else if(StrEqual(classname, "entity_medigun_shield"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage_MedicShield);
	}
	
	if(StrContains(classname, "tf_projectile_", false) == 0)
	{
		entitySpawnTime[entity] = GetGameTime();
		g_nBounces[entity] = 0;
		RequestFrame(onProjectileSpawned, reference);
		int flags;
		bool success = projectilePropertyMap.GetValue(classname, flags);
		if(success){
			if(flags & PROJ_SPEEDUPGRADE){
				RequestFrame(ProjSpeedDelay, reference);
			}
			if(flags & PROJ_BOUNCE){
				SDKHook(entity, SDKHook_StartTouch, OnStartTouch);
			}
			if(flags & PROJ_GRAVITY){
				RequestFrame(projGravity, reference);
				RequestFrame(meteorCollisionCheck, reference);
			}
			if(flags & PROJ_NOGRAVITY){
				RequestFrame(SetZeroGravity, reference);
			}
			if(flags & PROJ_FRAGMENT){
				RequestFrame(FragmentProperties, reference);
			}
			if(flags & PROJ_JAR){
				RequestFrame(ChangeProjModel, reference);
			}
			if(flags & PROJ_HOMING){
				RequestFrame(PrecisionHoming, reference);
			}
			if(flags & PROJ_PARENTING){
				RequestFrame(ProjParenting, reference);
			}
		}
		
		float lifespan;
		success = projectileLifespanMap.GetValue(classname, lifespan);
		if(success){
			CreateTimer(lifespan, SelfDestruct, reference);
		}

		if(StrEqual(classname, "tf_projectile_flare"))
		{
			DHookEntity(g_DHookFlareExplosion, true, entity);
		}
		else if(StrEqual(classname, "tf_projectile_sentryrocket"))
		{
			RequestFrame(SentryMultishot, reference);
			homingRadius[entity] = 900.0;
			homingTickRate[entity] = 1;
			RequestFrame(SentryDelay, reference);
		}
		else if(StrEqual(classname, "tf_projectile_arrow"))
		{
			RequestFrame(ExplosiveArrow, reference);
		}
		else if(StrEqual(classname, "tf_projectile_rocket"))
		{
			RequestFrame(monoculusBonus, reference);
		}
	}
	else if(StrContains(classname, "tf_weapon", false) == 0)
	{
		DHookEntity(g_DHookPrimaryAttack, true, entity);
	}

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
public OnEntityDestroyed(entity)
{
	if(!IsValidEdict(entity) || entity < 0 || entity > 2048)
		return;

	char classname[32];
	GetEntityClassname(entity, classname, 32)
	for(int i=1;i<=MaxClients;++i)
	{ShouldNotHome[entity][i] = false;}
	for(int i=0;i<MAXENTITIES;++i)
	{ShouldNotHit[entity][i] = false;}
	isEntitySentry[entity] = false;
	isProjectileBoomerang[entity] = false;
	isProjectileFireball[entity] = false;
	gravChanges[entity] = false;
	homingRadius[entity] = 0.0;
	homingTickRate[entity] = 0;
	homingTicks[entity] = 0;
	homingDelay[entity] = 0.0;
	homingAimStyle[entity] = -1;
	projectileDamage[entity] = 0.0;
	projectileFragCount[entity] = 0;
	locusMinesFunction[entity] = null;
	locusMinesRadius[entity] = 0.0;
	locusMinesProjCount[entity] = 0;
	projectileMaxBounces[entity] = 0;
	projectileAttackCounter[entity] = -1;
	isProjectileParented[entity] = false;
	projectileExplosionBounceDamage[entity] = 0.0;
	projectileExplosionBounceRadius[entity] = 0.0;
	rocketSplitCount[entity] = 0;
	projectileUniformFrag[entity] = false;

	//isProjectileSlash[entity][0] = 0.0;
	//isProjectileSlash[entity][1] = 0.0;
	jarateWeapon[entity] = -1;
	jarateType[entity] = -1;
	if(StrEqual(classname, "tank_boss"))
	{
		int iLink = GetEntPropEnt(entity, Prop_Send, "m_hEffectEntity");
		if(IsValidEdict(iLink))
		{
			AcceptEntityInput(iLink, "ClearParent");
			AcceptEntityInput(iLink, "Kill");
		}
	}
	if(StrEqual(classname, "obj_sentrygun"))
	{
		int parent = GetEntPropEnt(entity, Prop_Send, "moveparent");
		if(IsValidEntity(parent)){
			char targetname[32];
			GetEntPropString(parent, Prop_Data, "m_iName", targetname, sizeof(targetname));
			if(StrContains(targetname, "physbuilding_"))
				RemoveEntity(parent);
		}
		if(isPrimed[entity]){
			isPrimed[entity] = false;
			float vec[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vec);
			vec[2] += 15.0;

			int owner = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
			if(IsValidClient3(owner)){
				EntityExplosion(owner, TF2_GetSentryDPSModifiers(owner)*70.0, 350.0, vec, _, _, owner, _ ,DMG_SHOCK);
			}
		}
	}
	if(debugMode)
		PrintToServer("debugLog | %s was deleted.", classname)
}
public Action build_command_callback(int client, const char[] command, int argc){
	if(GetCmdArgInt(1) == 2){
		function_AllowBuilding(client);
	}
	return Plugin_Continue;
}
public Action removeAllBuildings(client, const char[] command, argc) 
{
	if(GetCmdArgInt(1) == 2){
		for(int i=1;i<2048;++i){

			if(!IsValidEntity(i)){
				continue;
			}

			decl String:netclass[32];
			GetEntityNetClass(i, netclass, sizeof(netclass));

			if ( !(strcmp(netclass, "CObjectSentrygun") == 0) ){
				continue;
			}

			if(GetEntDataEnt2(i, OwnerOffset)!=client){
				continue;
			}
			SetVariantInt(9999999);
			AcceptEntityInput(i,"RemoveHealth");
		}
	}else if(GetCmdArgInt(1) == 0){
		for(int i=1;i<2048;++i){

			if(!IsValidEntity(i)){
				continue;
			}

			decl String:netclass[32];
			GetEntityNetClass(i, netclass, sizeof(netclass));

			if ( !(strcmp(netclass, "CObjectDispenser") == 0)){
				continue;
			}

			if(GetEntDataEnt2(i, OwnerOffset)!=client){
				continue;
			}
			SetVariantInt(9999999);
			AcceptEntityInput(i,"RemoveHealth");
		}
	}
	return Plugin_Continue;
}
public Action WeaponSwitch(client, weapon){
	//Safety Checks
	if(!IsClientInGame(client)){
		return Plugin_Continue;
	}
	RequestFrame(UpdatePlayerSpellSlots, client);
	RequestFrame(UpdatePlayerMaxHealth, client);

	if(TF2_GetPlayerClass(client)!=TFClass_Engineer){
		return Plugin_Continue;
	}
	if(!IsValidEntity(GetPlayerWeaponSlot(client,1))){
		return Plugin_Continue;
	}
	if(!IsValidEntity(GetPlayerWeaponSlot(client,3))){
		return Plugin_Continue;
	}
	if(!IsValidEntity(GetPlayerWeaponSlot(client,4))){
		return Plugin_Continue;
	}
	if(!IsValidEntity(weapon)){
		return Plugin_Continue;
	}

	//if the building pda is opened
	//Switches some buildings to sappers so the game doesn't count them as engie buildings
	if(GetPlayerWeaponSlot(client,3)==weapon){
		function_AllowBuilding(client);
		return Plugin_Continue;
	}//else if the client is not holding the building tool
	else if(GetEntProp(weapon,Prop_Send,"m_iItemDefinitionIndex")!=28){
		function_AllowDestroying(client);
		return Plugin_Continue;
	}
	return Plugin_Continue;

}
public Action Event_ObjectBuilt(Event event, const char[] name, bool dontBroadcast){
	int obj = event.GetInt("object");
	int entity = event.GetInt("index");
	int entRef = EntIndexToEntRef(entity);
	DataPack pack = new DataPack();
	pack.WriteCell(entRef);
	pack.WriteCell(obj);
	RequestFrame(wrenchBonus, pack);

	return Plugin_Continue;
}
public Event_PlayerChangeTeam(Handle event, const char[] name, bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client) && IsClientObserver(client) == false && IsPlayerAlive(client))
	{
		current_class[client] = TF2_GetPlayerClass(client)
		CreateTimer(0.4, ChangeClassTimer, GetClientUserId(client));
		CancelClientMenu(client);
		Menu_BuyUpgrade(client, 0);
	}
}
public Event_ResetStats(Handle event, const char[] name, bool:dontBroadcast)
{
	PrintToServer("IF | Reset all players stats. (MvM)");
	OverAllMultiplier = GetConVarFloat(cvar_BotMultiplier);
	replenishStatus = true;
	for(int i = 1; i<=MaxClients;++i){
		if(!IsValidClient(i))
			continue;

		ResetClientUpgrades(i);
		
		for(int slot=0;slot<NB_SLOTS_UED;++slot){
			currentitem_idx[i][slot] = 20000;
		}

		TF2_RemoveAllWeapons(i)
	}
	ResetVariables();
	CreateTimer(0.3, ResetClientsTimer);
	//DeleteSavedPlayerData();
	failLock = false;
	disableMvMCash = false;
}
public Event_mvm_wave_failed(Handle event, const char[] name, bool:dontBroadcast)
{
	char oldMission[256];
	strcopy(oldMission, sizeof(oldMission), missionName);

	int ObjectiveEntity = FindEntityByClassname(-1, "tf_objective_resource");
	if(IsValidEntity(ObjectiveEntity))
		GetEntPropString(ObjectiveEntity, Prop_Send, "m_iszMvMPopfileName", missionName, sizeof(missionName));
	PrintToServer("mission failed? | %s | %s", oldMission, missionName);
	
	if(oldMission[0] != '\0' && StrEqual(oldMission, missionName) && failLock){
		CreateTimer(0.2, WaveFailed);
	}else{
		PrintToServer("Mission Loaded");
		CreateTimer(0.5, MissionLoaded);
	}
}
public Event_mvm_wave_begin(Handle event, const char[] name, bool:dontBroadcast)
{
	int client, slot, a;
	failLock = true;
	for (client = 1; client <= MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			for (slot = 0; slot < NB_SLOTS_UED; slot++)
			{
				for(a = 0; a < MAX_ATTRIBUTES_ITEM; a++)
				{
					currentupgrades_idx_mvm_checkpoint[client][slot][a] = currentupgrades_idx[client][slot][a];
					currentupgrades_val_mvm_checkpoint[client][slot][a] = currentupgrades_val[client][slot][a];
				}
				for(a = 0; a < MAX_ATTRIBUTES; a++)
				{
					upgrades_ref_to_idx_mvm_checkpoint[client][slot][a] = upgrades_ref_to_idx[client][slot][a];
				}
				client_spent_money_mvm_checkpoint[client][slot] = client_spent_money[client][slot];
				currentupgrades_number_mvm_checkpoint[client][slot] = currentupgrades_number[client][slot];
				for(int y = 0;y<5;y++)
				{
					currentupgrades_restriction_mvm_checkpoint[client][slot][y] = currentupgrades_restriction[client][slot][y];
				}
			}
			UniqueWeaponRef_mvm_checkpoint[client] = UniqueWeaponRef[client];
		}
	}
	StartMoneySaved = StartMoney + additionalstartmoney;
}
public Action:Event_PlayerDeath(Handle event, const char[] name, bool:dontBroadcast)
{
	//prevent death triggering multiple times
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isDeathTick[client]){
		dontBroadcast = true;
		return;
	}

	if((GetEventInt(event, "death_flags") & 32))
		return;

	int attack = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(!IsValidClient3(client))
		return;

	isBotScrambled[client] = false;
	isDeathTick[client] = true;
	
	CancelClientMenu(client);

	if(IsValidClient3(attack) && attack != client){
		int weapon = GetEntPropEnt(attack, Prop_Send, "m_hActiveWeapon");
		RequestFrame(UpdatePlayerMaxHealth, attack);
		if(IsValidWeapon(weapon)){
			float fireworksChance = GetAttribute(weapon, "fireworks chance", 0.0)
			if(fireworksChance > 0.0){
				float position[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
				EntityExplosion(attack, 100.0*TF2_GetDPSModifiers(attack, weapon)*fireworksChance, 400.0, position, _, _, client);
			}
		}
		int inflictor = GetEventInt(event, "inflictor_entindex");
		if(IsValidEntity(inflictor)){
			float painTrainActive = TF2Attrib_HookValueFloat(0.0, "chain_charge_on_kill", inflictor);
			if(painTrainActive){
				SetEntPropFloat(attack, Prop_Send, "m_flChargeMeter", 100.0);
				TF2_AddCondition(attack, TFCond_Charging);
			}
		}
	}
	if(hasBuffIndex(client, Buff_Frozen)){
		int owner = playerBuffs[client][getBuffInArray(client, Buff_Frozen)].inflictor;
		float fAngles[3], fOrigin[3], vBuffer[3], fVelocity[3], fwd[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fOrigin);
		fOrigin[2] += 35.0;

		for(int i = 0;i<12;++i)
		{
			int iEntity = CreateEntityByName("tf_projectile_syringe");
			if (!IsValidEdict(iEntity)) 
				continue;

			int iTeam = GetClientTeam(owner);
			SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);
			SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);

			fAngles[0] = GetRandomFloat(-10.0,-40.0);
			fAngles[1] = GetRandomFloat(-179.0,179.0);

			GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(fwd, 30.0);
			
			AddVectors(fOrigin, fwd, fOrigin);
			GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
			
			fVelocity[0] = vBuffer[0]*1500.0;
			fVelocity[1] = vBuffer[1]*1500.0;
			fVelocity[2] = vBuffer[2]*1500.0;
			
			TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
			DispatchSpawn(iEntity);
			SetEntityGravity(iEntity, 5.0);

			jarateWeapon[iEntity] = client;
			SDKHook(iEntity, SDKHook_Touch, CollisionFrozenFrag);
			SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 2.5);
			SetEntityRenderColor(iEntity, 0, 128, 255, 180);
			CreateTimer(5.0, SelfDestruct, EntIndexToEntRef(iEntity));
		}
	}

	if(IsValidEdict(autoSentryID[client]) && autoSentryID[client] > 32)
	{
		RemoveEntity(autoSentryID[client]);
		autoSentryID[client] = -1;
	}
	cleanSlateClient(client);
	if(!IsValidClient3(attack))
		return;

	if(GetAttribute(attack, "revenge powerup", 0.0) == 3){
		AddPlayerHealth(attack, RoundToCeil(GetClientHealth(attack)*0.06), 1.0);
	}

	if(attack != client && !(GetEventInt(event, "death_flags") & 32))
	{
		Kills[attack]++;
		Deaths[client]++;
	}
	
	if(attack == client)
		return;

	if (isMvM)
		return;

	if((StartMoney + additionalstartmoney) < MAXMONEY)
	{	
		if(IsFakeClient(client))
		{
			float BotMoneyKill = (100.0+((SquareRoot(MoneyBonusKill + Pow((StartMoney + additionalstartmoney), 0.985))) * ServerMoneyMult) * 3.0);
			if((StartMoney + additionalstartmoney + BotMoneyKill) > MAXMONEY)
				BotMoneyKill = MAXMONEY - StartMoney - additionalstartmoney;
		
			for (int i = 1; i <= MaxClients; ++i) 
			{
				CurrencyOwned[i] += BotMoneyKill
				if (IsValidClient(i))
					PrintToConsole(i, "+$%.0f", BotMoneyKill);
			}  
			additionalstartmoney += BotMoneyKill
		}
		else
		{
			float PlayerMoneyKill = (100.0+((SquareRoot(MoneyBonusKill + Pow((additionalstartmoney + StartMoney), 1.125))) * ServerMoneyMult) * 3.0);
			if((StartMoney + additionalstartmoney + PlayerMoneyKill) > MAXMONEY)
				PlayerMoneyKill = MAXMONEY - StartMoney - additionalstartmoney;

			for (int i = 1; i <= MaxClients; ++i) 
			{
				CurrencyOwned[i] += PlayerMoneyKill
				if(IsValidClient(i))
					PrintToConsole(i, "+$%.0f",  PlayerMoneyKill)
			}  
			additionalstartmoney += PlayerMoneyKill;
		}
	
		CheckForGamestage();
	}
	else if(hardcapWarning == false)
	{
		hardcapWarning = true;
		CPrintToChatAll("{valve}Incremental Fortress {white}| {red}WARNING {white}| You have reached the hardcap for money in PvP!");
	}
}

public Action Event_ArrowImpact(Handle event, const char[] name, bool dontBroadcast){
	return Plugin_Stop;
}

//Called on player CMD (~almost every tick, but varies based on response rate)

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{	
	if(!IsPlayerAlive(client) || !IsValidClient3(client) || IsClientObserver(client))
		return Plugin_Continue;

	int flags = GetEntityFlags(client)
	Action return_value = Plugin_Continue;

	int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEdict(CWeapon))
	{
		if(powerupParticle[client] <= GetGameTime() && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		{
			Address strengthPowerup = TF2Attrib_GetByName(client, "strength powerup");
			if(strengthPowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(strengthPowerup) == 1){
					CreateParticle(client, "utaunt_tarotcard_orange_wind", true, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
				else if(TF2Attrib_GetValue(strengthPowerup) == 2){
					CreateParticle(client, "utaunt_tarotcard_orange_wind", true, _, 5.0);
					CreateParticle(client, "utaunt_pedalfly_red_spins", true, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
				else if(TF2Attrib_GetValue(strengthPowerup) == 3){
					CreateParticle(client, "utaunt_tarotcard_orange_wind", true, _, 5.0);
					CreateParticle(client, "utaunt_pedalfly_red_pedals", true, _, 5.0);
					CreateParticle(client, "critical_rocket_redsparks", true, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
			}
			Address resistancePowerup = TF2Attrib_GetByName(client, "resistance powerup");
			if(resistancePowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(resistancePowerup) == 1){
					CreateParticleEx(client, "soldierbuff_red_spikes", 1, _, _, 2.0);
					powerupParticle[client] = GetGameTime()+2.1;
				}
				else if(TF2Attrib_GetValue(resistancePowerup) == 2){
					CreateParticleEx(client, "utaunt_prismatichaze_parent", 1, _, _, 4.0);
					powerupParticle[client] = GetGameTime()+4.1;
				}
				else if(TF2Attrib_GetValue(resistancePowerup) == 3){
					CreateParticleEx(client, "soldierbuff_mvm", 1, _, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
			}
			Address vampirePowerup = TF2Attrib_GetByName(client, "vampire powerup");
			if(vampirePowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(vampirePowerup) == 1){
					CreateParticleEx(client, "utaunt_hellpit_parent", 1, _, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
				else if(TF2Attrib_GetValue(vampirePowerup) == 2){
					CreateParticle(client, "utaunt_hands_floor1_purple", true, _, 5.0);
					CreateParticleEx(client, "utaunt_hellpit_parent", 1, _, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
				else if(TF2Attrib_GetValue(vampirePowerup) == 3){
					CreateParticle(client, "utaunt_hands_floor1_red", true, _, 5.0);
					CreateParticle(client, "utaunt_hands_floor2_red", true, _, 5.0);
					CreateParticleEx(client, "utaunt_hellpit_parent", 1, _, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
			}
			Address regenerationPowerup = TF2Attrib_GetByName(client, "regeneration powerup");
			if(regenerationPowerup != Address_Null && TF2Attrib_GetValue(regenerationPowerup) > 0.0)
			{
				int iTeam = GetClientTeam(client);
				if(iTeam == 2)
					CreateParticle(client, "medic_megaheal_red_shower", true, _, 5.0);
				else
					CreateParticle(client, "medic_megaheal_blue_shower", true, _, 5.0);

				if(TF2Attrib_GetValue(regenerationPowerup) == 3){
					CreateParticle(client, "utaunt_hands_floor1_purple", true, _, 5.0);
					CreateParticleEx(client, "utaunt_hellpit_parent", 1, _, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
				
				powerupParticle[client] = GetGameTime()+5.0;
			}
			Address precisionPowerup = TF2Attrib_GetByName(client, "precision powerup");
			if(precisionPowerup != Address_Null && TF2Attrib_GetValue(precisionPowerup) > 0.0)
			{
				if(TF2_GetPlayerClass(client) != TFClass_Pyro && TF2_GetPlayerClass(client) != TFClass_Engineer)
					CreateParticle(client, "eye_powerup_blue_lvl_4", true, "righteye", 5.0);
				else
					CreateParticle(client, "eye_powerup_blue_lvl_4", true, "eyeglow_R", 5.0);

				powerupParticle[client] = GetGameTime()+5.0;
			}
			Address agilityPowerup = TF2Attrib_GetByName(client, "agility powerup");
			if(agilityPowerup != Address_Null && TF2Attrib_GetValue(agilityPowerup) > 0.0)
			{
				if(TF2Attrib_GetValue(agilityPowerup) == 1){
					CreateParticle(client, "utaunt_pedalfly_blue_spins", true, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
				else if(TF2Attrib_GetValue(agilityPowerup) == 2){
					CreateParticle(client, "utaunt_pedalfly_blue_spins", true, _, 5.0);
					CreateParticle(client, "utaunt_pedalfly_blue_sparkles", true, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
				else if(TF2Attrib_GetValue(agilityPowerup) == 3){
					CreateParticle(client, "utaunt_pedalfly_blue_pedals", true, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}

				CreateParticleEx(client, "medic_resist_bullet", 1, _, _, 5.0);
				powerupParticle[client] = GetGameTime()+5.1;
			}
			Address knockoutPowerup = TF2Attrib_GetByName(client, "knockout powerup");
			if(knockoutPowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(knockoutPowerup) == 1){
					CreateParticleEx(client, "medic_resist_blast", 1, _, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
				else if(TF2Attrib_GetValue(knockoutPowerup) == 2){
					CreateParticle(client, "utaunt_spellsplash_parent", true, _, 1.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
				else if(TF2Attrib_GetValue(knockoutPowerup) == 3){
					CreateParticle(client, "utaunt_smoke_floor1", true, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
			}
			Address kingPowerup = TF2Attrib_GetByName(client, "king powerup");
			if(kingPowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(kingPowerup) == 2){
					if(IsValidClient3(tagTeamTarget[client])){
						CreateParticleEx(client, "utaunt_lavalamp_green_particles", 1, _, _, 4.0);
						CreateParticleEx(tagTeamTarget[client], "utaunt_lavalamp_green_particles", 1, _, _, 4.0);
						powerupParticle[client] = GetGameTime()+4.1;
					}
				}
			}
			Address plaguePowerup = TF2Attrib_GetByName(client, "plague powerup");
			if(plaguePowerup != Address_Null && TF2Attrib_GetValue(plaguePowerup) > 0.0)
			{
				if(TF2Attrib_GetValue(plaguePowerup) == 1){
					CreateParticle(client, "powerup_plague_carrier", true, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
				else if(TF2Attrib_GetValue(plaguePowerup) == 2){
					CreateParticle(client, "powerup_plague_carrier", true, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
				else if(TF2Attrib_GetValue(plaguePowerup) == 3){
					CreateParticleEx(client, "halloween_burningplayer_flyingbits", 1, _, _, 0.6);
					powerupParticle[client] = GetGameTime()+0.7;
				}
			}
			Address supernovaPowerup = TF2Attrib_GetByName(client, "supernova powerup");
			if(supernovaPowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(supernovaPowerup) == 1.0){
					CreateParticleEx(client, "powerup_supernova_ready", 1, _, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}else if(TF2Attrib_GetValue(supernovaPowerup) == 2.0){
					CreateParticle(client, "heavy_ring_of_fire", false, "", 1.0,_,_,1);
					int clients[MAXPLAYERS+1], numClients = getClientParticleStatus(clients, client);
					TE_Send(clients,numClients)
					powerupParticle[client] = GetGameTime()+1.0;
				}else if(TF2Attrib_GetValue(supernovaPowerup) == 3.0){
					CreateParticleEx(client, "utaunt_electric_mist", 1, _, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
			}
			Address inverterPowerup = TF2Attrib_GetByName(client, "inverter powerup");
			if(inverterPowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(inverterPowerup) == 1.0){
					CreateParticleEx(client, "utaunt_portalswirl_purple_parent", 1, _, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}else if(TF2Attrib_GetValue(inverterPowerup) == 2.0){
					CreateParticle(client, "utaunt_storm_parent_o", true, "", 5.0,_,_,1);
					int clients[MAXPLAYERS+1], numClients = getClientParticleStatus(clients, client);
					TE_Send(clients,numClients)
					powerupParticle[client] = GetGameTime()+5.1;
				}else if(TF2Attrib_GetValue(inverterPowerup) == 3.0){
					CreateParticle(client, "utaunt_cremation_black_parent", true, _, 5.0);
					CreateParticle(client, "utaunt_cremation_purple_parent", true, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
			}
			switch(TF2Attrib_HookValueFloat(0.0, "revenge_powerup", client)) {
				case 1.0: {
					if(RageActive[client]){
						CreateParticleEx(client, "utaunt_poweraura_teamcolor_red", 1, _, _, 1.0);
						powerupParticle[client] = GetGameTime()+1.1;
					}
				}
				case 2.0, 3.0: {
					if(RageBuildup[client] > 0.65){
						CreateParticleEx(client, "utaunt_poweraura_teamcolor_red", 1, _, _, 1.0);
						powerupParticle[client] = GetGameTime()+1.1;
					}
				}
			}
			switch(TF2Attrib_HookValueFloat(0.0, "juggernaut_powerup", client)) {
				case 1.0: {
					CreateParticleEx(client, "medic_resist_fire", 1, _, _, 5.0);
					powerupParticle[client] = GetGameTime()+5.1;
				}
				case 2.0:{
					CreateParticleEx(client, "medic_resist_fire", 1);
					int iTeam = GetClientTeam(client);
					if(iTeam == 2)
						CreateParticleEx(client, "medic_megaheal_red", 1, _, _, 5.0);
					else
						CreateParticleEx(client, "medic_megaheal_blue", 1, _, _, 5.0);

					powerupParticle[client] = GetGameTime()+5.1;
				}
				case 3.0: {
					CreateParticleEx(client, "medic_resist_fire", 1, _, _, 5.0);
					CreateParticleEx(client, "utaunt_iconicoutline_orange_sparkles", 1);
					CreateParticleEx(client, "utaunt_iconicoutline_cyan_sparkles", 1);
					powerupParticle[client] = GetGameTime()+5.1;
				}
			}
		}
	}
	if (!IsFakeClient(client))
	{
		if(shouldAttack[client] == true){
			shouldAttack[client] = false;
			buttons |= IN_ATTACK;
		}

		if(buttons & IN_ATTACK)
			relentlessTicks[client]++;
		else
			relentlessTicks[client] = 0;

		if(buttons & IN_SCORE)
		{
			inScore[client] = true;
			if(MenuTimer[client] < GetGameTime())
			{
				Menu_BuyUpgrade(client, 0);
				MenuTimer[client] = GetGameTime()+0.5;
			}
		}
		else
		{
			inScore[client] = false;
		}

		if (impulse == 201 && ImpulseTimer[client] < GetGameTime())
		{
			if(IsValidEntity(EntRefToEntIndex(UniqueWeaponRef[client])))
			{
				TF2Util_SetPlayerActiveWeapon(client, EntRefToEntIndex(UniqueWeaponRef[client]));
			}
			ImpulseTimer[client] = GetGameTime()+0.3;
		}
		if(IsValidEdict(CWeapon))
		{
			if(buttons & IN_ATTACK){
				char strName[32];
				GetEntityClassname(CWeapon, strName, 32)
				if(StrEqual(strName, "tf_weapon_minigun", false)){
					SetEntPropFloat(CWeapon, Prop_Send, "m_flNextSecondaryAttack", GetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack"));
				}

				if(CheckForAttunement(client))
				{
					for(int i = 0;i<Max_Attunement_Slots;++i)
					{
						if(AttunedSpells[client][i] != 0)
						{
							int spellID = AttunedSpells[client][i]-1
							if(SpellCooldowns[client][spellID]-GetGameTime() > 0.0)
								continue;

							if(TF2Attrib_HookValueInt(0, arcaneMap[spellID].attribute, client) < 2)
								continue;
							
							Call_StartFunction(INVALID_HANDLE, arcaneMap[spellID].callback);
							Call_PushCell(client);
							Call_PushCell(i);
							Call_Finish();
						}
					}
				}
			}
			if(HasEntProp(CWeapon, Prop_Send, "m_flChargedDamage"))
			{
				float charging = GetEntPropFloat(CWeapon, Prop_Send, "m_flChargedDamage");
				
				if(charging > 0.0 || TF2_IsPlayerInCondition(client, TFCond_Zoomed))
				{
					if(charging < savedCharge[client] && GetGameTime() >= GetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack") - 0.1){
						charging = savedCharge[client];
						SetEntPropFloat(CWeapon, Prop_Send, "m_flChargedDamage", savedCharge[client]);
						savedCharge[client] = 0.0;
					}
					Address tracer = TF2Attrib_GetByName(CWeapon, "sniper fires tracer");
					LastCharge[client] = charging;
					if(LastCharge[client] >= 150.0 && tracer != Address_Null && TF2Attrib_GetValue(tracer) == 0.0)
					{
						TF2Attrib_SetByName(CWeapon, "sniper fires tracer", 1.0);
					}
				}
			}
			if(IsPlayerAlive(client))
			{
				if(HasEntProp(CWeapon, Prop_Send, "m_iWeaponState")){
					if(GetAttribute(CWeapon, "minigun full movement", 0.0))
						if(buttons & IN_ATTACK3)
							{buttons |= IN_JUMP;return_value=Plugin_Changed;}
				}
				if(!(buttons & IN_ATTACK) && globalButtons[client] & IN_ATTACK)
				{
					float fOrigin[3], fAngles[3], vBuffer[3], fVelocity[3], vImpulse[3];
					GetCleaverAngularImpulse(vImpulse);
					GetClientEyePosition(client, fOrigin);
					GetClientEyeAngles(client, fAngles);
					int iTeam = GetClientTeam(client);

					if(maelstromChargeCount[client] >= 1){
						int iEntity = CreateEntityByName("tf_projectile_arrow");
						if (IsValidEntity(iEntity)){
							fAngles[0] -= 1.0;
							SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
							SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);

							GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);

							fVelocity[0] = vBuffer[0]*3000.0;
							fVelocity[1] = vBuffer[1]*3000.0;
							fVelocity[2] = vBuffer[2]*3000.0;

							SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
							SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
							SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );

							TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
							DispatchSpawn(iEntity);
							
							SDKHook(iEntity, SDKHook_Touch, AddArrowCollisionFunction);
							if(iTeam == 2)
								CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0", "materials/effects/arrowtrail_red.vmt", "255 255 255");
							else
								CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0", "materials/effects/arrowtrail_blu.vmt", "255 255 255");
							entityMaelstromChargeCount[iEntity] = maelstromChargeCount[client];
							maelstromChargeCount[client] = 0;
						}
					}
					else if(fanOfKnivesCount[client] > 1){

						fAngles[1] -= 15.0 + 15.0/fanOfKnivesCount[client];
						fAngles[0] -= 2.0;
						for(int i = 0; i < fanOfKnivesCount[client]; ++i)
						{
							fAngles[1] += 30.0/fanOfKnivesCount[client]
							int iEntity = CreateEntityByName("tf_projectile_cleaver");
							if (!IsValidEdict(iEntity))
								continue;

							SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);

							GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);

							fVelocity[0] = vBuffer[0]*4000.0;
							fVelocity[1] = vBuffer[1]*4000.0;
							fVelocity[2] = vBuffer[2]*4000.0;

							SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
							SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
							SetEntProp(iEntity, Prop_Data, "m_bIsLive", true);

							TeleportEntity(iEntity, fOrigin, fAngles, NULL_VECTOR);
							DispatchSpawn(iEntity);
							Phys_EnableDrag(iEntity, false);
							SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vImpulse, client, 50, 146.0);
						}

						fanOfKnivesCount[client] = 0;
					}
				}
				
				GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", trueVel[client]);
				float SkillNumber = GetAttribute(CWeapon, "weapon ability id", 0.0);

				float x = 0.6, y = 0.9;
				switch(SkillNumber)
				{
					case 6.0: //Detonate
					{
						char CooldownTime[32]
						Format(CooldownTime, sizeof(CooldownTime), "Detonate Flares: READY (M3)"); 
						SetHudTextParams(x, y, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
						ShowSyncHudText(client, hudAbility, CooldownTime);
						if(buttons & IN_ATTACK3)
						{
							if(fl_GlobalCoolDown[client] <= GetGameTime())
							{
								fl_GlobalCoolDown[client] = GetGameTime()+0.1;
								
								float m_fOrigin[3];
								int entity = -1; 
								while((entity = FindEntityByClassname(entity, "tf_projectile_flare"))!=INVALID_ENT_REFERENCE)
								{
									if(GetGameTime() - entitySpawnTime[entity] <= 0.1) { continue; }

									int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
									if(!IsValidClient(owner)) continue;
									if(owner == client)
									{
										GetEntPropVector(entity, Prop_Data, "m_vecOrigin", m_fOrigin);
										EntityExplosion(client, 28.0, 400.0, m_fOrigin, 2, _, entity, _, DMG_BURN|DMG_BLAST, CWeapon, _, _, true, _, _, _, true);
										RemoveEntity(entity);
									}
								}
							}
						}
					}
					case 11.0:
					{
						if(weaponArtParticle[client] <= GetGameTime())
						{
							weaponArtParticle[client] = GetGameTime()+4.0;
							SetEntityRenderColor(CWeapon, 255, 255, 255, 1);
						}
					}
					case 12.0: //Strong Dash
					{
						if(weaponArtCooldown[client] > GetGameTime())
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Dash: %.1fs", weaponArtCooldown[client]-GetGameTime()); 
							SetHudTextParams(x, y, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Dash: READY (M3)"); 
							SetHudTextParams(x, y, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
							if(buttons & IN_ATTACK3)
							{
								if(fl_GlobalCoolDown[client] <= GetGameTime())
								{
									weaponArtCooldown[client] = GetGameTime()+1.0;
									fl_GlobalCoolDown[client] = GetGameTime()+0.2;
									
									float flSpeed = GetEntPropFloat(client, Prop_Data, "m_flMaxspeed") * 2.0
									float flVel[3],flAng[3],vBuffer[3]
									GetClientEyeAngles(client,flAng)
									GetAngleVectors(flAng, vBuffer, NULL_VECTOR, NULL_VECTOR)
									flVel[0] = flSpeed * vBuffer[0] * 1.5;
									flVel[1] = flSpeed * vBuffer[1] * 1.5;
									flVel[2] = 100.0 + (flSpeed * vBuffer[2]);
									
									if(flVel[2] < -100.0)
										flVel[2] *= 2.5;

									if(flags & FL_ONGROUND)
										flVel[2] += 200;

									TeleportEntity(client, NULL_VECTOR,NULL_VECTOR, flVel)
								}
							}
						}
					}
					case 13.0:
					{
						if(weaponArtParticle[client] <= GetGameTime())
						{
							weaponArtParticle[client] = GetGameTime()+3.0;
							CreateParticleEx(CWeapon, "critgun_weaponmodel_red", 1, _, _, 3.0);
						}
					}
					case 14.0:
					{
						if(!immolationActive[client])
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Immolation: INACTIVE (M3)"); 
							SetHudTextParams(x, y, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Immolation: ACTIVE (M3)"); 
							SetHudTextParams(x, y, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						if(buttons & IN_ATTACK3)
						{
							if(fl_GlobalCoolDown[client] <= GetGameTime())
							{
								fl_GlobalCoolDown[client] = GetGameTime()+0.5;
								immolationActive[client] = !immolationActive[client];
							}
						}
					}
					case 15.0:{
						if(sunstarDuration[client] < GetGameTime())
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Sunstar: INACTIVE (M3)"); 
							SetHudTextParams(x, y, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);

							if(buttons & IN_ATTACK3)
							{
								if(fl_GlobalCoolDown[client] <= GetGameTime())
								{
									fl_GlobalCoolDown[client] = GetGameTime()+0.5;
									int metal = GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
									if(metal > 500){
										sunstarDuration[client] = GetGameTime() + 0.002*metal;
										SetEntProp(client, Prop_Data, "m_iAmmo", 1, 4, 3);
									}else{
										PrintToChat(client, "Sunstar requires >500 metal.");
										float fOrigin[3];
										GetClientEyePosition(client, fOrigin);
										EmitSoundToAll(SOUND_ARCANESHOOTREADY, 0, _, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,fOrigin);
									}
								}
							}
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Sunstar: ACTIVE | %.1fs", sunstarDuration[client]-GetGameTime()); 
							SetHudTextParams(x, y, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
					}
					case 16.0:{
						if(weaponArtCooldown[client] > GetGameTime())
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Airstrike: %.1fs", weaponArtCooldown[client]-GetGameTime()); 
							SetHudTextParams(x, y, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Airstrike: READY (M3)", sunstarDuration[client]-GetGameTime()); 
							SetHudTextParams(x, y, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
							if(buttons & IN_ATTACK3)
							{
								if(fl_GlobalCoolDown[client] <= GetGameTime())
								{
									fl_GlobalCoolDown[client] = GetGameTime()+0.5;
									weaponArtCooldown[client] = GetGameTime()+25.0;

									float rocketDamage = 25.0;
									int melee = TF2Util_GetPlayerLoadoutEntity(client, 2);

									if(IsValidWeapon(melee))
										rocketDamage *= TF2_GetSentryDPSModifiers(client);
									
									DataPack pack = new DataPack();
									pack.Reset();
									pack.WriteCell(client);
									pack.WriteCell(GetClientTeam(client));
									pack.WriteFloat(rocketDamage);
									float ClientPos[3];
									TracePlayerAim(client, ClientPos);
									pack.WriteFloat(ClientPos[0]);
									pack.WriteFloat(ClientPos[1]);
									pack.WriteFloat(ClientPos[2]);
									float ClientOrigin[3];
									GetClientEyePosition(client, ClientOrigin);
									pack.WriteFloat(ClientOrigin[0]);
									pack.WriteFloat(ClientOrigin[1]);
									pack.WriteFloat(ClientOrigin[2]);

									const int times = 200;
									for(int i=0;i<times;++i){
										CreateTimer(0.4+(i*0.01), orbitalStrike, pack);
									}
									CreateTimer(0.5+(times*0.01), deletePack, pack);
								}
							}
						}
					}
					case 17.0:{
						char CooldownTime[64]
						Format(CooldownTime, sizeof(CooldownTime), "Build Sentry: M2\nDestroy Sentries: M3"); 
						SetHudTextParams(x, y, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
						ShowSyncHudText(client, hudAbility, CooldownTime);
						if(buttons & IN_ATTACK2){
							FakeClientCommand(client, "build 2");
						}
						else if(buttons & IN_ATTACK3){
							FakeClientCommand(client, "destroy 2");
						}
					}
					case 18.0:{
						if(weaponArtCooldown[client] > GetGameTime())
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Smoke Bomb: %.1fs", weaponArtCooldown[client]-GetGameTime()); 
							SetHudTextParams(x, y, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Smoke Bomb: READY (M1)", sunstarDuration[client]-GetGameTime()); 
							SetHudTextParams(x, y, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
							if(buttons & IN_ATTACK)
							{
								if(fl_GlobalCoolDown[client] <= GetGameTime())
								{
									fl_GlobalCoolDown[client] = GetGameTime()+0.5;
									weaponArtCooldown[client] = GetGameTime()+25.0*GetAttribute(CWeapon, "effect bar recharge rate increased");
									
									float fAngles[3],fOrigin[3],vBuffer[3],fVelocity[3], fwd[3];
									for(int i = 0;i<3;++i){
										int iEntity = CreateEntityByName("tf_projectile_flare");
										if (!IsValidEdict(iEntity)) 
											continue;

										SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
										SetEntProp(iEntity, Prop_Send, "m_iTeamNum", GetClientTeam(client), 1);
										SetEntProp(iEntity, Prop_Send, "m_nSkin", (GetClientTeam(client)-2));
										SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
										SetEntityModel(iEntity, "models/weapons/w_models/w_sd_sapper.mdl");

										SetEntityRenderMode(iEntity, RENDER_NONE);
										GetClientEyePosition(client, fOrigin);
										GetClientEyeAngles(client,fAngles);

										fAngles[1] -= 2*4.0;
										fAngles[1] += i*8.0;
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

										int color[4] = {255, 255, 255, 100};

										TE_SetupBeamFollow(iEntity,Laser,0,0.5,4.0,8.0,3,color);
										TE_SendToAll();

										SDKHook(iEntity, SDKHook_StartTouch, OnSmokeStartTouch);
										SetEntityGravity(iEntity, 3.0);
									}

									int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
									if(IsValidWeapon(melee))
										TF2Util_SetPlayerActiveWeapon(client, melee);
								}
							}
						}
					}
				}

				if(buttons & IN_DUCK && buttons & IN_ATTACK3 && fl_GlobalCoolDown[client] <= GetGameTime())
				{
					fl_GlobalCoolDown[client] = GetGameTime()+0.4;
					if(TF2Attrib_HookValueFloat(0.0, "revenge_powerup", client) == 1 && RageActive[client] == false && RageBuildup[client] >= 1.0)
					{
						RageActive[client] = true;
						EmitSoundToAll(SOUND_REVENGE, client, -1, 150, 0, 1.0);
						EmitSoundToAll(SOUND_REVENGE, client, -1, 150, 0, 1.0);
						
						TF2_AddCondition(client, TFCond_CritCanteen, 1.0);
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
						TF2_AddCondition(client, TFCond_DefenseBuffMmmph, 1.0);
						TF2_AddCondition(client, TFCond_UberchargedHidden, 1.0);
						TF2_AddCondition(client, TFCond_KingAura, 1.0);
					}
					if(duplicationCooldown[client] <= GetGameTime()){
						if(TF2Attrib_HookValueFloat(0.0, "regeneration_powerup", client) == 2.0){
							duplicationCooldown[client] = GetGameTime()+10.0;
							AddPlayerHealth(client, GetClientHealth(client), 2.0);
							float fOrigin[3];
							GetClientAbsOrigin(client, fOrigin);
							EmitSoundToAll(SOUND_HEAL, client, _, _, _, _, _, _, fOrigin);
						}
					}
					if(TF2Attrib_HookValueFloat(0.0, "king_powerup", client) == 2.0){
						for(int i=1;i<=MaxClients;++i)
						{
							if(!IsValidClient3(i) || i == client)
								continue;
							
							if(!IsPlayerAlive(i))
								continue;
							
							if(IsOnDifferentTeams(client,i))
								continue;
							
							if(!IsTargetInSightRange(client, i, 30.0, 2000.0, true, false))
								continue;

							if(!IsAbleToSee(client,i, false))
								continue;
								
							tagTeamTarget[client] = i;
							break;
						}
					}
					if(warpCooldown[client] <= GetGameTime()){
						if(TF2Attrib_HookValueFloat(0.0, "agility_powerup", client) == 3.0){
							CastWarp(client);
						}
					}
					if(TF2Attrib_HookValueFloat(0.0, "resistance_powerup", client) == 3.0){
						strongholdEnabled[client] = !strongholdEnabled[client];

						if(strongholdEnabled[client]){
							SetEntityMoveType(client, MOVETYPE_NONE);
							float fOrigin[3];
							GetClientAbsOrigin(client, fOrigin);
							EmitSoundToAll(SOUND_STRONGHOLD, 0,_,_,_,1.0, _, _, fOrigin);
							PrintHintText(client, "Stronghold Enabled");
						}else{
							SetEntityMoveType(client, MOVETYPE_WALK);
							PrintHintText(client, "Stronghold Disabled");
						}
						TeleportEntity(client, _, _, {0.0,0.0,0.0});
					}

					if(SupernovaBuildup[client] >= 1.0)
					{
						SupernovaBuildup[client] = 0.0;
						EmitSoundToAll(SOUND_SUPERNOVA, client, -1, 150, 0, 1.0);
						EmitSoundToAll(SOUND_SUPERNOVA, client, -1, 150, 0, 1.0);
						
						int iTeam = GetClientTeam(client);
						if(iTeam == 2)
							CreateParticleEx(client, "powerup_supernova_explode_red");
						else
							CreateParticleEx(client, "powerup_supernova_explode_blue");
						
						float clientpos[3];
						GetClientEyePosition(client,clientpos);
						int i = -1;
						while ((i = FindEntityByClassname(i, "*")) != -1)
						{
							if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
							{
								float VictimPos[3];
								GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
								VictimPos[2] += 30.0;
								if(GetVectorDistance(clientpos,VictimPos,true) <= 640000.0)
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

					if(infernalDetonationCooldown[client]-GetGameTime() < 0){
						if(TF2Attrib_HookValueFloat(0.0, "supernova_powerup", client) == 2){
							infernalDetonationCooldown[client] = GetGameTime()+10.0;
							for(int victim = 1; victim <= MaxClients; victim++){
								if(!IsValidClient3(victim))
									continue;
								if(!IsPlayerAlive(victim))
									continue;
								if(!IsOnDifferentTeams(client, victim))
									continue;

								float detonateAccumulation = 0.0;
								for(int i = 0;i<MAX_AFTERBURN_STACKS;++i){
									if(playerAfterburn[victim][i].remainingTicks <= 0)
										continue;

									if(playerAfterburn[victim][i].owner != client)
										continue;

									detonateAccumulation += playerAfterburn[victim][i].damage * playerAfterburn[victim][i].remainingTicks;
									playerAfterburn[victim][i].remainingTicks = 0;
								}
								if(detonateAccumulation > 0){
									SDKHooks_TakeDamage(victim, client, client, detonateAccumulation, DMG_BURN|DMG_PREVENT_PHYSICS_FORCE|DMG_IGNOREHOOK, _, _, _, false);
									CreateParticleEx(victim, "bombinomicon_burningdebris");
								}
							}
						}
					}
				}
				
				float chainLightningAttribute = GetAttribute(CWeapon, "chain lightning meter on hit", 0.0);
				if(chainLightningAttribute){
					char CooldownTime[32]
					Format(CooldownTime, sizeof(CooldownTime), "Chain Lightning: %.0f%", chainLightningAbilityCharge[client]); 
					SetHudTextParams(x, y, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
					ShowSyncHudText(client, hudAbility, CooldownTime);
				}

				if (fanOfKnivesCount[client] > 0) {
					char CooldownTime[32]
					Format(CooldownTime, sizeof(CooldownTime), "Fan of Knives: %i/100", fanOfKnivesCount[client]); 
					SetHudTextParams(x, y, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
					ShowSyncHudText(client, hudAbility, CooldownTime);
				}
				else if (maelstromChargeCount[client] > 0) {
					char CooldownTime[32]
					Format(CooldownTime, sizeof(CooldownTime), "Maelstrom Charge: %i/25", maelstromChargeCount[client]); 
					SetHudTextParams(x, y, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
					ShowSyncHudText(client, hudAbility, CooldownTime);
				}

				
				float arrowNovaDamage = TF2Attrib_HookValueFloat(0.0, "arrow_nova_altfire", CWeapon);
				if(arrowNovaDamage){
					char CooldownTime[32];
					if(arrowExpulsionCooldown[client]-GetGameTime() < 0){
						Format(CooldownTime, sizeof(CooldownTime), "Arrow Nova: READY (M2)"); 
						if(buttons & IN_ATTACK2){
							int team = GetClientTeam(client);
							arrowExpulsionCooldown[client] = GetGameTime() + 3.0;
							for(int i = 1; i<=MaxClients; i++){
								if(!IsValidClient3(i))
									continue;
								if(!IsPlayerAlive(i))
									continue;
								if(!IsOnDifferentTeams(client, i))
									continue;
								if(arrowNovaCount[client][i] == 0)
									continue;
								
								float fAngles[3], fOrigin[3], vBuffer[3];
								fAngles[0] = 0.2;
								fAngles[1] = GetRandomFloat(-180.0, 180.0);
								fAngles[2] = 0.0;
								GetClientAbsOrigin(i, fOrigin);
								fOrigin[2] += 50.0;

								for(int j = 0; j < arrowNovaCount[client][i]; j++){
									fAngles[1] += 360.0/arrowNovaCount[client][i];
									int iEntity = CreateEntityByName("tf_projectile_arrow");
									if (!IsValidEdict(iEntity)) 
										continue;

									SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
									SetEntProp(iEntity, Prop_Send, "m_iTeamNum", team);

									GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
									ScaleVector(vBuffer, 1000.0);
									
									TeleportEntity(iEntity, fOrigin, fAngles, vBuffer);

									SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", vBuffer );
									SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", weapon);
									SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008);
									SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
									SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 13);

									DispatchSpawn(iEntity);
									projectileDamage[iEntity] = arrowNovaDamage;
									homingDelay[iEntity] = 9999.0;
									SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchPiercingArrow);
									CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0",
										team == 2 ? "materials/effects/arrowtrail_red.vmt":"materials/effects/arrowtrail_blu.vmt", "255 255 255");
								}
								arrowNovaCount[client][i] = 0;
							}
						}
					}
					else {
						Format(CooldownTime, sizeof(CooldownTime), "Arrow Nova: %.1fs", arrowExpulsionCooldown[client]-GetGameTime()); 
					}
					SetHudTextParams(x, y, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
					ShowSyncHudText(client, hudAbility, CooldownTime);
				}
			}
		}
		fEyeAngles[client] = angles;
		lastFlag[client] = flags;
		globalButtons[client] = buttons;
	}
	return return_value;
}
//Called on server thinking, 66.6/s

public OnGameFrame()
{
	int i = -1;
	while ((i = FindEntityByClassname(i, "*")) != -1)
	{
		if(!IsValidEdict(i))
			continue;

		if(homingRadius[i] > 0.0 && homingDelay[i] < GetGameTime() - entitySpawnTime[i])
			OnEntityHomingThink(i);
		
		if(isEntitySentry[i])
		{
			sentryThought[i] = false;
			SDKCall(g_SDKCallSentryThink, i);
		}
		
		if(isProjectileFireball[i])
			OnFireballThink(i);

		if(isAimlessProjectile[i])
			OnAimlessThink(i);

		if(isProjectileBoomerang[i])
			BoomerangThink(i);
	}
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient3(client))
		{
			if(IsPlayerAlive(client))
			{
				if(RadiationBuildup[client] > 0.0){
				RadiationBuildup[client] -= (RadiationMaximum[client] * 0.0285) * TICKINTERVAL; }//Fully remove radiation within 35 seconds.
				if(BleedBuildup[client] > 0.0){
				BleedBuildup[client] -= (BleedMaximum[client] * 0.143) * TICKINTERVAL; }//Fully remove bleed within 7 seconds.
				if(ConcussionBuildup[client] > 0.0){
				ConcussionBuildup[client] -= 3.0 * TICKINTERVAL; }
				if(FreezeBuildup[client] > 0.0){
				FreezeBuildup[client] -= 3.0 * TICKINTERVAL; }
				if(TeamTacticsBuildup[client] > 0.0){
					TeamTacticsBuildup[client] -= 0.001*TICKINTERVAL;
				}else if(TeamTacticsBuildup[client] < 0.0)
					TeamTacticsBuildup[client] = 0.0;

				int clientHealth = GetEntProp(client, Prop_Data, "m_iHealth");
				stickiesDetonated[client] = 0;
				isDeathTick[client] = false;
				hasSupernovaSplashed[client] = false;
				float RegenPerTick = 0.0;

				if(TF2_IsPlayerInCondition(client, TFCond_HalloweenSpeedBoost)){
					TF2Attrib_RemoveByName(client, "halloween reload time decreased");
					TF2Attrib_RemoveByName(client, "halloween fire rate bonus");
					TF2Attrib_RemoveByName(client, "halloween increased jump height");
				}

				Address RegenActive = TF2Attrib_GetByName(client, "disguise on backstab");
				if(RegenActive != Address_Null)
					RegenPerTick += TF2Attrib_GetValue(RegenActive)*TICKINTERVAL;

				Address HealingReductionActive = TF2Attrib_GetByName(client, "health from healers reduced");
				if(HealingReductionActive != Address_Null)
					RegenPerTick *= TF2Attrib_GetValue(HealingReductionActive);
				
				Address regenerationPowerup = TF2Attrib_GetByName(client, "regeneration powerup");
				if(regenerationPowerup != Address_Null){
					if(TF2Attrib_GetValue(regenerationPowerup) == 1.0)
						RegenPerTick += TF2_GetMaxHealth(client)*TICKINTERVAL*0.1;//+10% maxHPR/s
					else if(TF2Attrib_GetValue(regenerationPowerup) == 3.0){
						if(bloodAcolyteBloodPool[client] < 3*TF2_GetMaxHealth(client) && GetClientHealth(client) >= TF2_GetMaxHealth(client) * 0.2){
							RegenPerTick -= TF2_GetMaxHealth(client)*TICKINTERVAL*0.08;
							bloodAcolyteBloodPool[client] += TF2_GetMaxHealth(client)*TICKINTERVAL*0.08;
						}
					}
				}
				for(int stack = 0;stack < MAX_RECOUP_STACKS; stack++){
					if(playerRecoup[client][stack].expireTime < GetGameTime())
						continue;

					RegenPerTick += playerRecoup[client][stack].hpPerTick;
				}
				
				if(TF2Attrib_HookValueFloat(0.0, "revenge_powerup", client) == 3){
					RegenPerTick -= TF2_GetMaxHealth(client)*TICKINTERVAL*0.25*RageBuildup[client];
				}

				if(TF2_IsPlayerInCondition(client, TFCond_Plague))
					RegenPerTick *= 0.0;

				if(GetClientHealth(client) < TF2Util_GetEntityMaxHealth(client)){
					if(Overleech[client] > 0 && TF2Attrib_HookValueFloat(0.0, "vampire_powerup", client) == 3) {
						float overleechBonus = TF2Util_GetEntityMaxHealth(client)*TICKINTERVAL;
						if(overleechBonus > Overleech[client]) {
							overleechBonus = Overleech[client];
						}
						RegenPerTick += overleechBonus * 1.5;
						Overleech[client] -= overleechBonus;
					}
				}
	
				remainderHealthRegeneration[client] += RegenPerTick;

				if(remainderHealthRegeneration[client] > 1.0){
					int heal = RoundToFloor(remainderHealthRegeneration[client]);
					AddPlayerHealth(client, heal, 1.0);
					remainderHealthRegeneration[client] -= heal;
				}
				//drain
				else if(remainderHealthRegeneration[client] < -1.0){
					int heal = RoundToFloor(remainderHealthRegeneration[client]);
					if(clientHealth+heal > 0){
						SetEntProp(client, Prop_Data, "m_iHealth", clientHealth+heal);
					}else{
						ForcePlayerSuicide(client);
					}

					remainderHealthRegeneration[client] -= heal;
				}
				
				if(LSPool[client] > 0){
					int healthGained = RoundToCeil(TICKINTERVAL * TF2Util_GetEntityMaxHealth(client) * 0.1);
					
					LSPool[client] -= float(healthGained);
					AddPlayerHealth(client, healthGained, 1.5);
					float spreadRatio = TF2Attrib_HookValueFloat(0.0, "lifesteal_to_team", client);
					if(spreadRatio > 0){
						for(int patient = 1; patient<= MaxClients; ++patient){
							if(!IsValidClient3(patient))
								continue;
							if(!IsPlayerAlive(patient))
								continue;
							if(IsOnDifferentTeams(client, patient))
								continue;
							if(patient == client)
								continue;

							AddPlayerHealth(patient, healthGained, 1.5, true, client);
						}
					}
				}

				if(RageActive[client])
				{
					if(RageBuildup[client] > 0.0)
					{
						RageBuildup[client] -= TICKINTERVAL / 10.0//Revenge lasts 10 seconds (granted they aren't gaining it at the same time)
						if (RageBuildup[client] < 0.0)
							RageBuildup[client] = 0.0;
					}
					else
					{
						RageActive[client] = false;
					}
				}
				//Firerate for Secondary Fire
				int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEdict(CWeapon))
				{
					float bossType = TF2Attrib_HookValueFloat(0.0, "player_boss_type", client);
					if(bossType == 2.0){
						if(GetEntityFlags(client) & FL_ONGROUND)
						{
							miniCritStatusVictim[client] = GetGameTime()+10.0;
							TF2Attrib_SetByName(CWeapon, "fire rate penalty", 1.25)
							TF2Attrib_SetByName(CWeapon, "damage taken mult 3", 2.0)
							TF2Attrib_SetByName(CWeapon, "faster reload rate", 1.0)
							TF2Attrib_SetByName(CWeapon, "Blast radius increased", 0.5)
							TF2Attrib_SetByName(CWeapon, "cannot pick up intelligence", 1.0)
							TF2Attrib_SetByName(CWeapon, "increased jump height", 2.5)
							SetEntProp(CWeapon, Prop_Data, "m_bReloadsSingly", 1);
							SetEntityGravity(client, 1.0);
						}
						else
						{
							miniCritStatusVictim[client] = 0.0;
							TF2Attrib_SetByName(CWeapon, "fire rate penalty", 0.1)
							TF2Attrib_SetByName(CWeapon, "damage taken mult 3", 0.25)
							TF2Attrib_SetByName(CWeapon, "faster reload rate", 0.0)
							TF2Attrib_SetByName(CWeapon, "Blast radius increased", 1.75)
							SetEntityGravity(client, 0.5);
							SetEntProp(CWeapon, Prop_Data, "m_bReloadsSingly", 0);
						}
					}

					if(TF2Attrib_HookValueFloat(0.0, "regenerate_stickbomb", CWeapon)) {
						if(HasEntProp(CWeapon, Prop_Send, "m_iDetonated"))
							SetEntProp(CWeapon, Prop_Send, "m_iDetonated", 0);
					}
					bool flag = true;
					if(TF2Util_GetWeaponSlot(CWeapon) == TFWeaponSlot_Melee)
						if(TF2_GetPlayerClass(client) == TFClass_Heavy)
							flag = false;

					if(TF2Util_GetWeaponSlot(CWeapon) == TFWeaponSlot_Primary)
						if(TF2_GetPlayerClass(client) == TFClass_Heavy || TF2_GetPlayerClass(client) == TFClass_Sniper)
							flag=false;

					if(flag)
					{
						float SecondaryROF = 1.0/TF2Attrib_HookValueFloat(1.0, "mult_postfiredelay", CWeapon);
						if(SecondaryROF != 1.0){
							float m_flNextSecondaryAttack = GetEntPropFloat(CWeapon, Prop_Send, "m_flNextSecondaryAttack");
							if(m_flNextSecondaryAttack > GetGameTime()){
								float SeTime = (m_flNextSecondaryAttack - GetGameTime()) - ((SecondaryROF - 1.0) * TICKINTERVAL);
								float FinalS = SeTime+GetGameTime();
								SetEntPropFloat(CWeapon, Prop_Send, "m_flNextSecondaryAttack", FinalS);
							}
						}
						//Remove fire rate bonuses for reload rate on no clip size weapons.
						if(TF2Attrib_HookValueFloat(0.0, "mod_max_primary_clip_override", CWeapon) == -1.0)
						{
							float PrimaryROF = 1.0;
							Address ReloadRate = TF2Attrib_GetByName(CWeapon, "faster reload rate");
							Address ReloadRate1 = TF2Attrib_GetByName(CWeapon, "reload time increased hidden");
							Address ReloadRate2 = TF2Attrib_GetByName(CWeapon, "Reload time increased");
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
							float m_flNextPrimaryAttack = GetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack");
							float Time = (m_flNextPrimaryAttack - GetGameTime()) - ((PrimaryROF - 1.0) * TICKINTERVAL);
							float FinalROF = Time+GetGameTime();
							SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", FinalROF);
						}
					}
				}
				if(!(GetEntityFlags(client) & FL_ONGROUND))
				{
					if(TF2Attrib_HookValueFloat(0.0, "agility_powerup", client) == 2.0){
						quakerTime[client]+=TICKINTERVAL;
						if(quakerTime[client] >= 0.4){
							Address weighDownAbility = TF2Attrib_GetByName(client, "noise maker");
							if(weighDownAbility != Address_Null && TF2Attrib_GetValue(weighDownAbility) > 0.0)
							{
								SetEntityGravity(client, 1.5*TF2Attrib_GetValue(weighDownAbility) + 1.0);
							}
						}
					}
					else{
						if(globalButtons[client] & IN_DUCK)
						{
							Address weighDownAbility = TF2Attrib_GetByName(client, "noise maker");
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
				}else{
					quakerTime[client] = 0.0;
					SetEntityGravity(client, 1.0);
				}
			}

			if(LightningEnchantmentDuration[client] > GetGameTime())
			{
				int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidWeapon(CWeapon))
				{
					if(weaponTrailTimer[client] < GetGameTime())
					{
						CreateParticle(CWeapon, "utaunt_auroraglow_orange_parent", true, "", 5.0,_,_,1);
						int clients[MAXPLAYERS+1], numClients = getClientParticleStatus(clients, client);
						TE_Send(clients,numClients)
						CreateParticle(client, "utaunt_arcane_yellow_parent", true, "", 5.0,_,_, 1);
						TE_Send(clients,numClients)
						
						weaponTrailTimer[client] = GetGameTime()+5.1;
					}
				}
			}
			else if(DarkmoonBladeDuration[client] > GetGameTime())
			{
				int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidWeapon(CWeapon) && TF2Util_GetWeaponSlot(CWeapon) == TFWeaponSlot_Melee)
				{
					if(weaponTrailTimer[client] < GetGameTime())
					{
						CreateParticle(CWeapon, "utaunt_auroraglow_purple_parent", true, "", 5.0,_,_,1);
						int clients[MAXPLAYERS+1], numClients = getClientParticleStatus(clients, client);
						TE_Send(clients,numClients)
						CreateParticle(client, "utaunt_arcane_purple_parent", true, "", 5.0,_,_,1);
						TE_Send(clients,numClients)
						weaponTrailTimer[client] = GetGameTime()+5.1;
					}
				}
			}
			
			if(fl_CurrentFocus[client] + fl_RegenFocus[client] < fl_MaxFocus[client])
				fl_CurrentFocus[client] += fl_RegenFocus[client];
			else if(fl_CurrentFocus[client] < fl_MaxFocus[client])
				fl_CurrentFocus[client] = fl_MaxFocus[client];
			
			if(fl_CurrentFocus[client] > fl_MaxFocus[client])
				fl_CurrentFocus[client] = fl_MaxFocus[client];

			if(fl_CurrentFocus[client] < 0.0)
				fl_CurrentFocus[client] = 0.0;
		}
	}
}
public MRESReturn OnScattergunFinishReload(int weapon){
	SDKCall(g_SDKCallScattergunReload, weapon);
	return MRES_Supercede;
}
public MRESReturn OnTaunt(int client){
	int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEdict(CWeapon))
	{
		float tauntRate = TF2Attrib_HookValueFloat(1.0, "taunt_time_mult", CWeapon);
		if(tauntRate != 1.0){
			TF2Attrib_SetByName(CWeapon, "gesture speed increase", tauntRate);
		}

		RequestFrame(ApplyTauntAttackSpeed, EntIndexToEntRef(client));
	}
	return MRES_Ignored;
}
public MRESReturn OnBlastExplosion(int entity, Handle hReturn){
	ExplosionHookEffects(entity);
	return MRES_Ignored;
}
public MRESReturn OnFinishReload(int weapon)
{
	if(!IsValidWeapon(weapon))
		return MRES_Ignored;

	int client = getOwner(weapon);
	if(!IsValidClient3(client))
		return MRES_Ignored;

	relentlessTicks[client] = 0;
	return MRES_Ignored;
}

public MRESReturn OnAmmoPerShot(int weapon, Handle hReturn)
{
	if(!IsValidWeapon(weapon))
		return MRES_Ignored;

	int client = getOwner(weapon);
	if(!IsValidClient3(client))
		return MRES_Ignored;

	float conservationRate = 1-TF2Attrib_HookValueFloat(1.0, "ammo_conservation", weapon)*TF2Attrib_HookValueFloat(1.0, "global_ammo_conservation", client);
	if(conservationRate >= GetRandomFloat()){
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public MRESReturn OnEnergyPerShot(int weapon)
{
	if(!IsValidWeapon(weapon))
		return MRES_Ignored;

	int client = getOwner(weapon);
	if(!IsValidClient3(client))
		return MRES_Ignored;

	float conservationRate = 1-TF2Attrib_HookValueFloat(1.0, "ammo_conservation", weapon)*TF2Attrib_HookValueFloat(1.0, "global_ammo_conservation", client);
	if(conservationRate >= GetRandomFloat()){
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
	if(!IsValidClient3(client) || !IsValidEdict(client))
		return Plugin_Continue;

	canShootAgain[client] = true;
	if(IsValidWeapon(weapon))
	{
		float critRating = TF2Attrib_HookValueFloat(0.0, "critical_rating", weapon);
		if(critRating > 0){
			float critRate = critRating/(critRating+200.0);
			if(critRate >= GetRandomFloat()){
				result = true;
			}
		}

		float fAngles[3], fVelocity[3], fOrigin[3], vBuffer[3];
		meleeLimiter[client]++;
		if(TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee)
		{
			float ballCheck = GetAttribute(weapon, "mod bat launches balls", 0.0);
			if(ballCheck == 0.0)
				ballCheck = GetAttribute(weapon, "mod bat launches ornaments", 0.0);

			int a = GetCarriedAmmo(client, 2)
			if(a > 0)
			{
				if(ballCheck == -1.0)
					SDKCall(g_SDKCallLaunchBall, weapon);
			}
		}
		else
		{
			char classname[32]; 
			GetEdictClassname(weapon, classname, sizeof(classname)); 

			if(StrEqual(classname, "tf_weapon_cleaver"))
			{
				if(weaponFireRate[weapon] > 5.0)
				{
					if(TF2Attrib_HookValueFloat(0.0, "override_projectile_type", weapon) == 0.0)
						SDKCall(g_SDKCallJar, weapon);
				}
			}
		}
		float bossValue = TF2Attrib_HookValueFloat(0.0, "player_boss_type", client);
		switch(bossValue)
		{
			case 1.0:
			{
				if(meleeLimiter[client] > 20)
				{
					meleeLimiter[client] = 0;
					for(int i=-3;i<=3;i+=1)
					{
						char projName[32] = "tf_projectile_arrow";
						int iEntity = CreateEntityByName(projName);
						if (IsValidEdict(iEntity)) 
						{
							int iTeam = GetClientTeam(client);
							float fwd[3]
							float right[3]
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
							float velocity = 5000.0;
							Address projspeed = TF2Attrib_GetByName(weapon, "Projectile speed increased");
							Address projspeed1 = TF2Attrib_GetByName(weapon, "Projectile speed decreased");
							if(projspeed != Address_Null){
								velocity *= TF2Attrib_GetValue(projspeed)
							}
							if(projspeed1 != Address_Null){
								velocity *= TF2Attrib_GetValue(projspeed1)
							}
							float vecAngImpulse[3];
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
								SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", weapon);
							}
							SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
							SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008);
							SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
							SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 13); 
							SDKHook(iEntity, SDKHook_Touch, OnCollisionBossArrow);
							if(iTeam == 2)
								CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0", "materials/effects/arrowtrail_red.vmt", "255 255 255");
							else
								CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0", "materials/effects/arrowtrail_blu.vmt", "255 255 255");
						}
					}
				}
			}
		}
		Address tracer = TF2Attrib_GetByName(weapon, "sniper fires tracer");
		if(LastCharge[client] >= 150.0 && tracer != Address_Null && TF2Attrib_GetValue(tracer) == 1.0)
		{
			TF2Attrib_SetByName(weapon, "sniper fires tracer", 0.0);
		}
		
		switch(TF2Attrib_HookValueFloat(0.0, "override_projectile_type", weapon))
		{
			case 27.0:
			{
				int iEntity = CreateEntityByName("tf_projectile_sentryrocket");
				if (IsValidEdict(iEntity)) 
				{
					int iTeam = GetClientTeam(client);
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
					SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
					SetEntProp(iEntity, Prop_Send, "m_bCritical", result);
					
					SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
								
					GetClientEyePosition(client, fOrigin);
					fAngles = fEyeAngles[client];
					
					GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					float Speed = 2000.0;
					Address projspeed = TF2Attrib_GetByName(weapon, "Projectile speed increased");
					if(projspeed != Address_Null)
					{
						Speed *= TF2Attrib_GetValue(projspeed);
					}
					fVelocity[0] = vBuffer[0]*Speed;
					fVelocity[1] = vBuffer[1]*Speed;
					fVelocity[2] = vBuffer[2]*Speed;
					
					float ProjectileDamage = 90.0;
					
					Address DMGVSPlayer = TF2Attrib_GetByName(weapon, "dmg penalty vs players");
					Address DamagePenalty = TF2Attrib_GetByName(weapon, "damage penalty");
					Address DamageBonus = TF2Attrib_GetByName(weapon, "damage bonus");
					Address DamageBonusHidden = TF2Attrib_GetByName(weapon, "damage bonus HIDDEN");
					Address BulletsPerShot = TF2Attrib_GetByName(weapon, "bullets per shot bonus");
					Address AccuracyScales = TF2Attrib_GetByName(weapon, "accuracy scales damage");
					Address damageActive = TF2Attrib_GetByName(weapon, "ubercharge");
					
					if(damageActive != Address_Null)
					{
						ProjectileDamage *= Pow(1.05,TF2Attrib_GetValue(damageActive));
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
				for(int i=-1;i<=1;i+=2)
				{
					char projName[32] = "tf_projectile_arrow";
					int iEntity = CreateEntityByName(projName);
					if (IsValidEdict(iEntity)) 
					{
						int iTeam = GetClientTeam(client);
						float fwd[3]
						float right[3]
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
						float velocity = 3000.0;
						Address projspeed = TF2Attrib_GetByName(weapon, "Projectile speed increased");
						Address projspeed1 = TF2Attrib_GetByName(weapon, "Projectile speed decreased");
						if(projspeed != Address_Null){
							velocity *= TF2Attrib_GetValue(projspeed)
						}
						if(projspeed1 != Address_Null){
							velocity *= TF2Attrib_GetValue(projspeed1)
						}
						float vecAngImpulse[3];
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
							SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", weapon);
						}
						SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
						SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008);
						SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
						SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 13);
						SetEntProp(iEntity, Prop_Send, "m_bCritical", result);
						SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchWarriorArrow);
							CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0",
							iTeam == 2 ? "materials/effects/arrowtrail_red.vmt":"materials/effects/arrowtrail_blu.vmt", "255 255 255");
					}
				}
			}
			case 41.0:
			{
				meleeLimiter[client] = 0;
				int iEntity = CreateEntityByName("tf_projectile_cleaver");
				if (IsValidEdict(iEntity)) 
				{
					int iTeam = GetClientTeam(client);
					GetClientEyePosition(client, fOrigin);
					GetClientEyeAngles(client, fAngles);
					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
					GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					fAngles[2] = 90.0;
					fVelocity[0] = vBuffer[0]*3000.0;
					fVelocity[1] = vBuffer[1]*3000.0;
					fVelocity[2] = vBuffer[2]*3000.0;

					ScaleVector(vBuffer, 75.0);
					AddVectors(fOrigin, vBuffer, fOrigin);

					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", weapon);
					SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
					SetEntProp(iEntity, Prop_Data, "m_bIsLive", true);
					SetEntProp(iEntity, Prop_Send, "m_bCritical", 1);

					TeleportEntity(iEntity, fOrigin, fAngles, NULL_VECTOR);
					DispatchSpawn(iEntity);
					Phys_EnableGravity(iEntity, false);
					Phys_EnableDrag(iEntity, false);
					//Set Thrower is used in init.
					float impulse[3];
					GetCleaverAngularImpulse(impulse);
					isProjectileBoomerang[iEntity] = true;
					
					SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, impulse, client, 50, 146.0);

					SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchBoomerang);

					SetEntityModel(iEntity, "models/weapons/c_models/c_croc_knife/c_croc_knife.mdl");
				}
			}
			case 42.0:
			{
				char projName[32] = "tf_projectile_rocket";
				int iEntity = CreateEntityByName(projName);
				if (IsValidEdict(iEntity)) 
				{
					int iTeam = GetClientTeam(client);
					float fwd[3]
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

					//SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
					//SetEntityRenderColor(iEntity, 0, 0, 0, 0);
		
					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
					SetEntProp(iEntity, Prop_Send, "m_bCritical", result);
					GetClientEyePosition(client, fOrigin);
					GetClientEyeAngles(client, fAngles);
					GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
					ScaleVector(fwd, 20.0);
					AddVectors(fOrigin, fwd, fOrigin);
					float velocity = 2000.0;
					Address projspeed = TF2Attrib_GetByName(weapon, "Projectile speed increased");
					Address projspeed1 = TF2Attrib_GetByName(weapon, "Projectile speed decreased");
					if(projspeed != Address_Null){
						velocity *= TF2Attrib_GetValue(projspeed)
					}
					if(projspeed1 != Address_Null){
						velocity *= TF2Attrib_GetValue(projspeed1)
					}
					float vecAngImpulse[3];
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
						SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", weapon);
					}
					SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
					SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchPiercingRocket);
					SetEntityModel(iEntity, "models/weapons/w_models/w_rocket_airstrike/w_rocket_airstrike.mdl");
					CreateTimer(3.0, SelfDestruct, EntIndexToEntRef(iEntity));
					SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 25.0 * TF2_GetDamageModifiers(client,weapon), true);  
				}
			}
			case 43.0:
			{
				int projCount = RoundToNearest(TF2Attrib_HookValueFloat(1.0, "mult_projectile_count", client));
				GetClientEyeAngles(client, fAngles);
				fAngles[1] -= 15.0 + 15.0/projCount;
				fAngles[0] -= 2.0;
				for(int i = 0; i < projCount; ++i)
				{
					fAngles[1] += 30.0/projCount;
					int iEntity = CreateEntityByName("tf_projectile_spellfireball");
					if (IsValidEdict(iEntity)) 
					{
						int iTeam = GetClientTeam(client);
						float fwd[3]
						SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
						SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
						SetEntProp(iEntity, Prop_Send, "m_bCritical", result);
						GetClientEyePosition(client, fOrigin);

						GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(fwd, 30.0);
						
						AddVectors(fOrigin, fwd, fOrigin);
						GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
						
						float velocity = 900.0;
						fVelocity[0] = vBuffer[0]*velocity;
						fVelocity[1] = vBuffer[1]*velocity;
						fVelocity[2] = 100.0 + vBuffer[2]*velocity;
						
						TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
						DispatchSpawn(iEntity);
						SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchChaos);
						setProjGravity(iEntity, 0.4);
						CreateTimer(10.0,SelfDestruct,EntIndexToEntRef(iEntity));
					}
				}
			}
			case 45.0:
			{
				char projName[32] = "tf_projectile_pipe";
				int iEntity = CreateEntityByName(projName);
				if (IsValidEdict(iEntity)) 
				{
					int iTeam = GetClientTeam(client);
					float fwd[3]
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

					//SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
					//SetEntityRenderColor(iEntity, 0, 0, 0, 0);
		
					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
					SetEntProp(iEntity, Prop_Send, "m_bCritical", result);
					GetClientEyePosition(client, fOrigin);
					GetClientEyeAngles(client, fAngles);
					GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
					ScaleVector(fwd, 30.0);
					AddVectors(fOrigin, fwd, fOrigin);
					float velocity = 20000.0;
					Address projspeed = TF2Attrib_GetByName(weapon, "Projectile speed increased");
					Address projspeed1 = TF2Attrib_GetByName(weapon, "Projectile speed decreased");
					if(projspeed != Address_Null){
						velocity *= TF2Attrib_GetValue(projspeed)
					}
					if(projspeed1 != Address_Null){
						velocity *= TF2Attrib_GetValue(projspeed1)
					}
					float vecAngImpulse[3];
					GetCleaverAngularImpulse(vecAngImpulse);
					fVelocity[0] = vBuffer[0]*velocity;
					fVelocity[1] = vBuffer[1]*velocity;
					fVelocity[2] = vBuffer[2]*velocity;
				
					DispatchSpawn(iEntity);
					TeleportEntity(iEntity, fOrigin, fAngles, NULL_VECTOR);
					SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vecAngImpulse, client, 0, 5.0);
					if(HasEntProp(iEntity, Prop_Send, "m_hLauncher"))
					{
						SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", weapon);
					}
					SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
					SetEntProp(iEntity, Prop_Data, "m_bIsLive", true);
					//PrintToServer("%.2f", TF2_GetWeaponFireRate(weapon));
				}
			}
			case 46.0:
			{
				if(fanOfKnivesCount[client] < 100)
					fanOfKnivesCount[client]++;
			}
			case 47.0:
			{
				int iEntity = CreateEntityByName("tf_projectile_mechanicalarmorb");
				if (IsValidEdict(iEntity)) 
				{
					int iTeam = GetClientTeam(client);
					float fwd[3]
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
					GetClientEyePosition(client, fOrigin);
					GetClientEyeAngles(client, fAngles);
					GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
					ScaleVector(fwd, 30.0);
					AddVectors(fOrigin, fwd, fOrigin);
					ScaleVector(vBuffer,700.0);
					DispatchSpawn(iEntity);
					TeleportEntity(iEntity, fOrigin, fAngles, vBuffer);
					
					SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0004);
					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", weapon);
					SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
					CreateTimer(0.1, ElectricBallThink, EntIndexToEntRef(iEntity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					EmitSoundToAll(SOUND_COWMANGLER_SHOT, 0, client, SNDLEVEL_NORMAL, _, 1.0, _, _, fOrigin);
				}
			}
			case 48.0:
			{
				if(maelstromChargeCount[client] < 25)
					maelstromChargeCount[client]++;
			}
			case 49.0:
			{
				GetClientEyePosition(client, fOrigin);
				GetClientEyeAngles(client, fAngles);
				
				for(int i=0;i<15;i++)
				{
					int iEntity = CreateEntityByName("tf_projectile_arrow");
					if (!IsValidEntity(iEntity)) 
						continue;

					int iTeam = GetClientTeam(client);
					float fwd[3], cloneAngle[3], cloneOrigin[3];
					cloneAngle = fAngles;
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
		
					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
					cloneAngle[0] += GetRandomFloat(-1.0, 1.0);
					cloneAngle[1] += GetRandomFloat(-8.0, 8.0);
					GetAngleVectors(cloneAngle,fwd, NULL_VECTOR, NULL_VECTOR);
					fVelocity[0] = fwd[0]*4000.0;
					fVelocity[1] = fwd[1]*4000.0;
					fVelocity[2] = fwd[2]*4000.0;

					ScaleVector(fwd, 50.0);
					AddVectors(fOrigin, fwd, cloneOrigin);
					
					TeleportEntity(iEntity, cloneOrigin, cloneAngle, fVelocity);
					DispatchSpawn(iEntity);
					SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );

					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", weapon);
					SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
					SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008);
					SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
					SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 13);
					SetEntProp(iEntity, Prop_Send, "m_bCritical", result);
					SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchEtherealKnife);
					TE_SetupBeamFollow(iEntity,Laser,0,0.2,3.0,3.0,1,{0, 255, 150,225});
					TE_SendToAll();
					projectileAttackCounter[iEntity] = currentAttackCounter;
					homingDelay[iEntity] = 9999.0; //please do not let this home... it can't hit properly
				}
				currentAttackCounter++;
				for(int i = 0; i<MAXENTITIES;i++){
					hasHit[i][currentAttackCounter % 30] = false;
				}
			}
			case 50.0:
			{
				int bulletCount = RoundToCeil(TF2Attrib_HookValueFloat(0.0, "fan_of_bullets_count", weapon));
				GetClientEyePosition(client, fOrigin);
				GetClientEyeAngles(client, fAngles);

				const float spread = 8.0;
				fAngles[1] -= spread + spread/bulletCount;
				fOrigin[2] -= 10.0;

				for(int j = 0; j < bulletCount; ++j){
					fAngles[1] += (spread*2)/bulletCount;
					float endpos[3];

					Handle traceray = TR_TraceRayFilterEx(fOrigin, fAngles, MASK_SHOT_HULL, RayType_Infinite, PenetrationCallTrace, client);
					if (TR_DidHit(traceray)) {
						TR_GetEndPosition(endpos, traceray);
					}
					delete traceray;
					
					SpawnBulletTracer(fOrigin, endpos, "bullet_pistol_tracer01_red");
				}
				for(int i = 1; i < MAXENTITIES; ++i){
					if(penetrationCount[i] > 0){
						SDKHooks_TakeDamage(i,client,client,25.0*penetrationCount[i],DMG_BULLET,weapon,_,_,false);
						penetrationCount[i] = 0;
					}
				}
			}
			case 51.0:
			{
				int iEntity = CreateEntityByName("tf_projectile_arrow");
				if (IsValidEdict(iEntity)) 
				{
					int iTeam = GetClientTeam(client);
					float fwd[3]
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);

					GetClientEyePosition(client, fOrigin);
					GetClientEyeAngles(client, fAngles);
					fAngles[0] -= 10.0;

					GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
					AddVectors(fOrigin, fwd, fOrigin);
					float velocityBonus = TF2Attrib_HookValueFloat(1.0, "mult_projectile_speed", weapon);
					ScaleVector(vBuffer, 1300.0*velocityBonus);
					
					TeleportEntity(iEntity, fOrigin, fAngles, vBuffer);
					DispatchSpawn(iEntity);

					SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", vBuffer );
					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", weapon);
					SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008);
					SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
					SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 13);
					SetEntProp(iEntity, Prop_Send, "m_bCritical", result);
					SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchWarriorArrow);
					CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0",
						iTeam == 2 ? "materials/effects/arrowtrail_red.vmt":"materials/effects/arrowtrail_blu.vmt", "255 255 255");

					DataPack pack = CreateDataPack();
					pack.WriteCell(EntIndexToEntRef(iEntity))
					pack.WriteFloat(3.0);

					CreateTimer(0.1, Timer_SetEntityGravity, pack);
					CreateTimer(0.4/velocityBonus, Timer_HailArrowSplit, EntIndexToEntRef(iEntity));
				}
			}
		}

		int globalShotsPerRocket = RoundToNearest(TF2Attrib_HookValueFloat(0.0, "global_shoots_additional_rocket", client));
		if(globalShotsPerRocket > 0)
		{
			if(ShotsLeft[client] < 1)
			{
				int iEntity = CreateEntityByName("tf_projectile_sentryrocket");
				if (IsValidEdict(iEntity)) 
				{
					int iTeam = GetClientTeam(client);
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
					SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
					SetEntProp(iEntity, Prop_Send, "m_bCritical", result);
					
					SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
					DispatchSpawn(iEntity);

					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", weapon);
					SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", weapon);
					GetClientEyePosition(client, fOrigin);
					fAngles = fEyeAngles[client];
					
					GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					float Speed = 2000.0;
					fVelocity[0] = vBuffer[0]*Speed;
					fVelocity[1] = vBuffer[1]*Speed;
					fVelocity[2] = vBuffer[2]*Speed;
					SetEntPropVector( iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
					float ProjectileDamage = 100.0 * GetAttribute(weapon, "bullets per shot bonus", 1.0);
					
					SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, ProjectileDamage, true);  
					TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
				}
				ShotsLeft[client] = globalShotsPerRocket;
			}
			else
			{
				ShotsLeft[client]--;
			}
		}
	}
	return Plugin_Changed;
}
public OnClientDisconnect(client)
{
	/*if(!IsFakeClient(client))
		SavePlayerData(client);*/
	
	DamageDealt[client] = 0.0;
	Kills[client] = 0;
	Deaths[client] = 0;
	Healed[client] = 0.0;
	current_class[client] = TFClass_Unknown;
	canBypassRestriction[client] = false;
	cleanSlateClient(client);
	int i;
	for(i = 0; i < Max_Attunement_Slots; ++i)
	{
		AttunedSpells[client][i] = 0;
	}
	for(i = 1;i<=MaxClients;++i){
		isTagged[i][client] = false;
	}
}
public OnClientPutInServer(client)
{
	ResetClientUpgrades(client);
	fl_MaxFocus[client] = 100.0;
	fl_CurrentFocus[client] = 100.0;
	BleedMaximum[client] = 100.0;
	RadiationMaximum[client] = 400.0;
	fl_HighestFireDamage[client] = 0.0;
	canBypassRestriction[client] = false;
	for(int i = 0; i < Max_Attunement_Slots; ++i)
	{
		AttunedSpells[client][i] = 0;
	}
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(client, SDKHook_StartTouch, OnStartTouchStomp);
	SDKHook(client, SDKHook_WeaponSwitch, WeaponSwitch);
	ClientCommand(client, "sm_showhelp");
}
public OnClientPostAdminCheck(client)
{
	if(IsValidClient(client))
	{
		char clname[255]
		GetClientName(client, clname, sizeof(clname))
		CreateTimer(0.0, ChangeClassTimer, GetClientUserId(client));
		//GivePlayerData(client);
	}
}
public Event_PlayerRespawn(Handle event, const char[] name, bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient3(client)){
		RespawnEffect(client);
		if(!IsFakeClient(client)){
			CancelClientMenu(client);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
			if(!replenishStatus)
				CreateTimer(0.3, WeaponReGiveUpgrades, GetClientUserId(client));
	
			if(AreClientCookiesCached(client)){
				char menuEnabled[64];
				GetClientCookie(client, respawnMenu, menuEnabled, sizeof(menuEnabled));
				float menuValue = StringToFloat(menuEnabled);
				if(menuValue == 0.0)
					Menu_BuyUpgrade(client, 0);
			}
			else{
				Menu_BuyUpgrade(client, 0);
			}
		}
		cleanSlateClient(client);
		if(IsFakeClient(client)){
			if(isMvM){
				if(IsValidForDamage(TankTeleporter) && !GetEntProp(TankTeleporter, Prop_Send, "m_bDisabled")){
					char classname[128]; 
					GetEdictClassname(TankTeleporter, classname, sizeof(classname)); 
					if(StrEqual("tank_boss", classname)){
						float telePos[3];
						GetEntPropVector(TankTeleporter,Prop_Send, "m_vecOrigin",telePos);
						telePos[2]+= 220.0;
						TeleportEntity(client, telePos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			else{
				if(!isBotScrambled[client]){
					TF2_SetPlayerClass(client, allowedBotClasses[GetRandomInt(0,sizeof(allowedBotClasses)-1)]);
					RequestFrame(RespawnPlayer,EntIndexToEntRef(client));
					isBotScrambled[client] = true;
				}
				else{
					CreateTimer(0.8, GiveBotUpgrades, GetClientUserId(client));
				}
			}
		}
	}
}
public Event_PlayerChangeClass(Handle event, const char[] name, bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int nextclass = GetEventInt(event,"class");
	if (IsValidClient(client))
	{
		if(current_class[client] != view_as<TFClassType>(nextclass))
		{
			previous_class[client] = TF2_GetPlayerClass(client);
			ResetClientUpgrades(client)
			ChangeClassEffect(client);
			CreateTimer(0.1, ChangeClassTimer, GetClientUserId(client));
			CancelClientMenu(client);
			CurrencyOwned[client] = (StartMoney + additionalstartmoney);
			int slot;
			for(slot = 0; slot < 5;slot++)
			{
				currentupgrades_idx[client][slot] = blankArray1[client][slot]
				currentupgrades_val[client][slot] = blankArray2[client][slot]
				currentupgrades_i[client][slot] = blankArray2[client][slot]
				currentupgrades_number[client][slot] = blankArray[client][slot]
			}
			for(int i = 0; i < Max_Attunement_Slots; ++i)
			{
				AttunedSpells[client][i] = 0;
			}
		}
	}
}
public Event_Teleported(Handle event, const char[] name, bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int owner = GetClientOfUserId(GetEventInt(event, "builderid"));
	if(IsValidClient3(client) && IsValidClient3(owner))
	{
		int melee = TF2Util_GetPlayerLoadoutEntity(owner,2);
		if(IsValidEntity(melee))
		{
			int weaponIndex = GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex");
			if(weaponIndex == 589)
			{
				float clientpos[3];
				GetClientAbsOrigin(client,clientpos);
				clientpos[0] += GetRandomFloat(-200.0,200.0);
				clientpos[1] += GetRandomFloat(-200.0,200.0);
				clientpos[2] = getLowestPosition(clientpos);
				// define where the lightning strike starts
				float startpos[3];
				startpos[0] = clientpos[0];
				startpos[1] = clientpos[1];
				startpos[2] = clientpos[2] + 1600;
				
				int color[4];
				color = {255,228,0,255};
				
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
				
				EmitSoundToAll(SOUND_THUNDER, 0, _, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,clientpos);
				
				float LightningDamage = 325.0 * TF2_GetSentryDPSModifiers(client);
				
				int i = -1;
				while ((i = FindEntityByClassname(i, "*")) != -1)
				{
					if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
					{
						float VictimPos[3];
						GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
						VictimPos[2] += 30.0;
						if(GetVectorDistance(clientpos,VictimPos, true) <= 250000.0)
						{
							if(IsPointVisible(clientpos,VictimPos))
							{
								SDKHooks_TakeDamage(i, client, client, LightningDamage, DMG_GENERIC|DMG_IGNOREHOOK, _,_,_,false);
								if(IsValidClient3(i))
								{
									float velocity[3];
									velocity[0]=0.0;
									velocity[1]=0.0;
									velocity[2]=1800.0;
									TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, velocity);
									Handle hPack = CreateDataPack();
									WritePackCell(hPack, EntIndexToEntRef(i));
									WritePackCell(hPack, EntIndexToEntRef(client));
									CreateTimer(0.5,thunderClapPart2,hPack);
								}
							}
						}
					}
				}
			}
		}
		int pda = TF2Util_GetPlayerLoadoutEntity(owner,5);
		if(IsValidEntity(pda))
		{
			float tpBuffs = GetAttribute(pda, "zoom speed mod disabled", 0.0);
			if(tpBuffs != 0.0)
			{
				TF2_AddCondition(client, TFCond_RuneAgility, 4.0);
				TF2_AddCondition(client, TFCond_KingAura, 4.0);
				TF2_AddCondition(client, TFCond_HalloweenSpeedBoost, 4.0);
			}
		}
	}
}
public TF2Items_OnGiveNamedItem_Post(client, char[] classname, itemDefinitionIndex, itemLevel, itemQuality, entityIndex)
{
	if(!IsValidClient3(client))
		return;

	if (TF2_IsPlayerInCondition(client, TFCond_Disguised))
		return;

	if(isMvM && IsFakeClient(client))
		return;

	current_class[client] = TF2_GetPlayerClass(client)
	if (itemLevel == 242)
	{
		int slot = 3
		currentitem_ent_idx[client][slot] = entityIndex;
		currentitem_level[client][slot] = 242;
		if (!currentupgrades_number[client][slot])
		{
			currentitem_idx[client][slot] = 20000
		}
		DefineAttributesTab(client, itemDefinitionIndex, slot, entityIndex)
		GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
		currentitem_catidx[client][slot] = GetUpgrade_CatList(upgrades_weapon_class_menu[upgrades_weapon_current[client]]);
		//PrintToServer("OGiveItem slot %d: [%s] #%d CAT[%d] qual%d", slot, classname, itemDefinitionIndex, currentitem_catidx[client][slot], itemLevel)
	}
	else
	{
		int slot = TF2Econ_GetItemLoadoutSlot(itemDefinitionIndex, current_class[client]);
		if (current_class[client] == TFClass_Spy)
		{
			if (StrEqual(classname, "tf_weapon_builder") || StrEqual(classname, "tf_weapon_sapper"))
				slot = 1;
			else if (StrEqual(classname, "tf_weapon_revolver"))
				slot = 0;
		}
		if (current_class[client] == TFClass_Engineer)
		{
			if (StrEqual(classname, "tf_weapon_pda_engineer_build"))
				slot = 5;
		}
		currentitem_catidx[client][4] = _:TF2_GetPlayerClass(client) - 1;
		if (slot != 3 && slot <= NB_SLOTS_UED && slot > -1)
		{
			GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
			currentitem_ent_idx[client][slot] = entityIndex
			DefineAttributesTab(client, itemDefinitionIndex, slot, entityIndex)
			currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
			
			switch(current_class[client])
			{
				case (TFClass_Scout):
				{
					if (StrEqual(classname, "tf_weapon_scattergun")){
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_scattergun_")
					}
					else if (StrEqual(classname, "tf_weapon_pistol") || StrEqual(classname, "tf_weapon_handgun_scout_secondary")){
						currentitem_catidx[client][slot] = GetUpgrade_CatList("scout_pistols")
					}
					else{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
				}
				case (TFClass_Soldier):
				{
					if (StrEqual(classname, "tf_weapon_shotgun")){
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_shotgun_soldier")
					}				
					else if (StrEqual(classname, "tf_weapon_grenadelauncher")){
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_libertylauncher")
					}	
					else{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}					
				}
				case (TFClass_Pyro):
				{
					if (StrEqual(classname, "tf_weapon_flaregun")){
						if (itemDefinitionIndex == 39 || itemDefinitionIndex == 1081){
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_flaregun")
						}
						else if (itemDefinitionIndex == 351 || itemDefinitionIndex == 740){
							currentitem_catidx[client][slot] = GetUpgrade_CatList("detonator")
						}
						else{
							currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
						}
					}
					else if (StrEqual(classname, "tf_weapon_shotgun") || StrEqual(classname, "tf_weapon_shotgun_pyro")){
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_shotgun_pyro")
					}
					else if(StrEqual(classname, "tf_weapon_flamethrower") && itemDefinitionIndex == 594){
						currentitem_catidx[client][slot] = GetUpgrade_CatList("pyroweapp")
					}
					else{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
				}
				case (TFClass_DemoMan):
				{
					if (StrEqual(classname, "tf_wearable") && 
					(itemDefinitionIndex == 405 || itemDefinitionIndex == 608)){
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_wear_alishoes")
					}		
					else if (StrEqual(classname, "tf_weapon_grenadelauncher") && itemDefinitionIndex == 1151){
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_iron_bomber")
					}
					else if (StrEqual(classname, "tf_weapon_pipebomblauncher") && itemDefinitionIndex == 1150){
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_quickiebomb")
					}
					else{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}					
				}
				case (TFClass_Heavy):
				{
					if (StrEqual(classname, "tf_weapon_minigun") && (itemDefinitionIndex == 312 || itemDefinitionIndex == 811)){
						currentitem_catidx[client][slot] = GetUpgrade_CatList("brassBeast")
					}
					else if (StrEqual(classname, "tf_weapon_shotgun")){
						currentitem_catidx[client][1] = GetUpgrade_CatList("tf_weapon_shotgun_hwg")
					}
					else{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}	
				}
				case (TFClass_Engineer):
				{
					if (StrEqual(classname, "tf_weapon_shotgun") && currentitem_level[client][slot] != 242){
						currentitem_catidx[client][0] = GetUpgrade_CatList("tf_weapon_shotgun_primary")
					}
					else if (StrEqual(classname, "tf_weapon_shotgun_primary") && itemDefinitionIndex == 527){
						currentitem_catidx[client][0] = GetUpgrade_CatList("tf_weapon_shotgun_primary_")
					}
					else if (StrEqual(classname, "saxxy")){
						currentitem_catidx[client][2] = GetUpgrade_CatList("tf_weapon_wrench")
					}
					else{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
				}
				case (TFClass_Sniper):
				{
					if(StrEqual(classname, "tf_weapon_crossbow")){
						currentitem_catidx[client][0] = GetUpgrade_CatList("autofirebow")
					}
					else if(itemDefinitionIndex == 752){
						currentitem_catidx[client][0] = GetUpgrade_CatList("hitmans")
					}
					else if(itemDefinitionIndex == 230){
						currentitem_catidx[client][0] = GetUpgrade_CatList("sydneySleeper")
					}
					else{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
				}
				case (TFClass_Medic):
				{
					if (StrEqual(classname, "tf_weapon_medigun") && itemDefinitionIndex == 998){
						currentitem_catidx[client][slot] = GetUpgrade_CatList("vaccinator")
					}
					else{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
					}
				}
			}
			GiveNewUpgradedWeapon_(client, slot);
		}
	}
}

public Action EurekaTeleportHook(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	int client = msg.ReadByte();
	if(IsValidClient3(client))
		CreateTimer(0.6,eurekaDelayed,EntIndexToEntRef(client));
	
	return Plugin_Continue;
}

public Action TF2_SentryFireBullet(int sentry, int builder, int &shots, float src[3], const float dirShooting[3], float spread[3], float &distance, int &tracerFreq, float &damage, int &playerDamage, int &flags, float &damageForceScale, int &attacker, int &ignoreEnt){
	lastSentryFiring[sentry] = GetGameTime();

	if(IsValidClient3(builder)){
		int pda = TF2Util_GetPlayerLoadoutEntity(builder, 5);
		if(IsValidWeapon(pda)){
			float override = TF2Attrib_HookValueFloat(0.0, "sentry_override_projectile_type", pda);
			switch (override){
				case 1.0:{
					if(firestormCounter[builder] == 6)
					{
						int iEntity = CreateEntityByName("tf_projectile_spellfireball");
						if (IsValidEdict(iEntity)) 
						{
							int iTeam = GetClientTeam(builder);
							float fVelocity[3], fAngles[3];
							float fwd[3]; fwd[0] = dirShooting[0]*30.0; fwd[1] = dirShooting[1]*30.0; fwd[2] = dirShooting[2]*30.0;
							SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", builder);
							SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
							AddVectors(src, fwd, src);
							GetVectorAngles(dirShooting, fAngles);
							fVelocity[0] = dirShooting[0]*11000.0;
							fVelocity[1] = dirShooting[1]*11000.0;
							fVelocity[2] = dirShooting[2]*11000.0;
							
							TeleportEntity(iEntity, src, fAngles, fVelocity);
							DispatchSpawn(iEntity);
							projectileDamage[iEntity] = 150.0*TF2_GetSentryDamageModifiers(attacker);
							if(GetEntProp(sentry, Prop_Send, "m_bMiniBuilding"))
								projectileDamage[iEntity] *= 0.25;

							jarateWeapon[iEntity] = EntIndexToEntRef(pda);
							SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchSentryFireball);
						}
						firestormCounter[builder] = 0;
					}
					firestormCounter[builder]++
					return Plugin_Stop;
				}
				case 2.0:{
					char projName[32] = "tf_projectile_arrow";
					int iEntity = CreateEntityByName(projName);
					if (IsValidEdict(iEntity)) 
					{
						projectileDamage[iEntity] = 35.0 * TF2_GetSentryDamageModifiers(builder);
						jarateWeapon[iEntity] = EntIndexToEntRef(sentry);
						if(GetEntProp(sentry, Prop_Send, "m_bMiniBuilding"))
							projectileDamage[iEntity] *= 0.25;

						int iTeam = GetClientTeam(builder);
						float fwd[3], fAngles[3], fVelocity[3];
						GetVectorAngles(dirShooting, fAngles);
						SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", builder);

						fVelocity = dirShooting; fwd = dirShooting;
						ScaleVector(fVelocity, 4000.0);
						SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
						SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", builder);
						ScaleVector(fwd, 50.0);
						AddVectors(fwd, src, src);
						
						TeleportEntity(iEntity, src, fAngles, fVelocity);
						DispatchSpawn(iEntity);
						SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
						SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008);
						SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
						SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 13); 
						SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchSentryBolt);
						SDKHook(iEntity, SDKHook_Touch, AddArrowCollisionFunction);
						CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0", iTeam == 2 ? "materials/effects/arrowtrail_red.vmt":"materials/effects/arrowtrail_blu.vmt", "255 255 255");
					}
					return Plugin_Stop;
				}
			}
			
			shots = RoundToCeil(GetAttribute(pda, "sentry bullets per shot", 1.0) * shots);

			if(GetAttribute(builder, "precision powerup", 0.0) == 1){//Precision removes sentry spread.
				ScaleVector(spread, 0.0);
			}
		}
	}

	return Plugin_Changed;
}

Buff OnStatusEffectApplied(int victim, Buff newBuff){
	Buff inserted;
	inserted = newBuff;

	if(IsValidClient3(victim)){
		if(!isBonus[inserted.id]){
			float block_rating = TF2Attrib_HookValueFloat(0.0, "debuff_block_rating", victim);
			inserted.severity /= 1 + 0.05*block_rating;
			inserted.duration = GetGameTime() + ((inserted.duration-GetGameTime()) / (1 + 0.05*block_rating));
		}
		if(inserted.id == Buff_KingAura){
			int index = EntRefToEntIndex(kingParticle[victim]);
			if(!IsValidEntity(index) || index == 0){
				if(GetClientTeam(victim) == 2)
					kingParticle[victim] = EntIndexToEntRef(CreateParticle(victim, "powerup_king_red", true, _, 0.0));
				else
					kingParticle[victim] = EntIndexToEntRef(CreateParticle(victim, "powerup_king_blue", true, _, 0.0));
			}
		}
	}
	return inserted;
}

void OnStatusEffectRemoved(int client, Buff currentbuff){
	switch(currentbuff.id){
		case Buff_LifeLink:{
			if(IsValidClient3(currentbuff.inflictor)){
				for(int i=1;i<=MaxClients;++i){
					if(!IsValidClient3(i)) continue;
					if(!IsPlayerAlive(i)) continue;
					if(!IsOnDifferentTeams(currentbuff.inflictor,i))
						AddPlayerHealth(i, currentbuff.priority, 2.0, true, currentbuff.inflictor);
				}
			}
		}
		case Buff_Frozen:{
			SetEntityRenderColor(client, 255, 255, 255, 255);
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
		case Buff_KingAura:{
			int index = EntRefToEntIndex(kingParticle[client]);
			if(IsValidEntity(index) && index > 0){
				RemoveEntity(index);
				kingParticle[client] = -1;
			}
		}
	}
}

public Event_PickupItem(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient3(client))
		return;

	char itemName[32];
	GetEventString(event, "item", itemName, sizeof(itemName));
	
	if(StrContains(itemName, "medkit") != -1) {
		removeDebuffs(client);
	}
}