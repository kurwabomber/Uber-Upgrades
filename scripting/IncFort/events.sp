public Event_Playerhurt(Handle event, const char[] name, bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	float damage = GetEventFloat(event, "damageamount");	
	//lastDamageTaken[client] = 0.0;

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

	if(damage == 0.0)
		return;

	if(attacker != client && IsValidClient(attacker)){
		isTagged[attacker][client] = true;
		DamageDealt[attacker] += damage;
		dps[attacker] += damage;
		if(damage > 32767)
		{
			SetEventInt(event, "damageamount", 0);
			PrintCenterText(attacker, "OVERLOAD DMG | %s |", GetAlphabetForm(damage));
		}
		int CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, EntIndexToEntRef(attacker));
		WritePackFloat(hPack, damage);
		CreateTimer(1.01, RemoveDamage, hPack);

		Address knockoutPowerup = TF2Attrib_GetByName(attacker, "knockout powerup");
		if(knockoutPowerup != Address_Null)
		{
			float knockoutPowerupValue = TF2Attrib_GetValue(knockoutPowerup);
			if(knockoutPowerupValue == 1){
				if (IsValidEdict(CWeapon))
				{
					if(TF2Util_GetWeaponSlot(CWeapon) == TFWeaponSlot_Melee)
					{
						float buildupIncrease = (damage/TF2_GetMaxHealth(client))*175.0;
						
						if(hasBuffIndex(attacker, Buff_Plunder)){
							Buff plunderBuff;
							plunderBuff = playerBuffs[attacker][getBuffInArray(attacker, Buff_Plunder)]
							buildupIncrease *= plunderBuff.severity;
						}

						ConcussionBuildup[client] += buildupIncrease;
						if(ConcussionBuildup[client] >= 100.0)
						{
							ConcussionBuildup[client] = 0.0;
							if(GetAttribute(client, "inverter powerup", 0.0) == 1){
								TF2_AddCondition(client, TFCond_MegaHeal, 10.0);
								TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, 10.0);
							}else{
								miniCritStatusVictim[client] = currentGameTime+10.0;
								TF2_StunPlayer(client, 1.0, 1.0, TF_STUNFLAGS_NORMALBONK, attacker);
							}
						}
					}
				}
			}
		}
		if(GetAttribute(attacker, "plague powerup", 0.0) == 3.0){
			if(!hasBuffIndex(client, Buff_LifeLink)){
				Buff lifelinkDebuff;
				lifelinkDebuff.init("Life Link", "-25% HP drain", Buff_LifeLink, RoundToCeil(GetClientHealth(attacker)*0.5), attacker, 10.0);
				insertBuff(client, lifelinkDebuff);

				currentDamageType[attacker].second |= DMG_PIERCING;
				currentDamageType[attacker].second |= DMG_IGNOREHOOK;
				SDKHooks_TakeDamage(attacker, attacker, attacker, GetClientHealth(attacker)*0.5, DMG_PREVENT_PHYSICS_FORCE,_,_,_,false);
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
		if(GetAttribute(client, "vampire powerup", 0.0) == 3.0){
			bloodboundDamage[client] += damage*0.75;
			if(bloodboundHealing[client] > 0 && float(GetClientHealth(client)) - damage < -1){
				AddPlayerHealth(client, RoundToCeil(bloodboundHealing[client]), 6.0, true, client);
				bloodboundHealing[client] = 0.0;
				bloodboundDamage[client] = 0.0;
			}
		}
	}

	if(IsValidClient3(attacker) && !IsFakeClient(attacker))
	{
		/*if(client != attacker && attacker != 0 && damage >= 1.0)
		{
			PrintToConsole(attacker, "%.1f post damage dealt.", damage);
		}*/
		if(damage > 0.0 && attacker != client && IsValidClient3(client))
		{
			int healers = GetEntProp(client, Prop_Send, "m_nNumHealers");
			if(healers > 0)
			{
				for(int i = 0;i<healers;++i){
					int healer = TF2Util_GetPlayerHealer(client,i);
					if(!IsValidClient3(healer))
						continue;
						
					int healingWeapon = GetWeapon(healer, 1);
					if(!IsValidWeapon(healingWeapon))
						continue;

					if(GetAttribute(healingWeapon, "patient damage taken to uber", 0.0))
						AddUbercharge(healingWeapon, 100.0 * damage * GetAttribute(healingWeapon, "patient damage taken to uber", 0.0) / TF2Util_GetEntityMaxHealth(client));
					if(GetAttribute(healingWeapon, "patient damage taken to self heal", 0.0))
						AddPlayerHealth(healer,RoundToCeil(damage * GetAttribute(healingWeapon, "patient damage taken to self heal", 0.0)), _, true, healer);
				}
			}
	
			if(GetAttribute(attacker, "regeneration powerup", 0.0) == 3){
				float heal = damage;
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
				leechDebuff.init("Leeched", "", Buff_Leech, 1, client, 4.0);
				insertBuff(client, leechDebuff)
			}

			int CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			if(IsValidEdict(CWeapon))
			{
				float chainLightningAttribute = GetAttribute(CWeapon, "chain lightning meter on hit", 0.0)
				if(chainLightningAttribute){
					chainLightningAbilityCharge[attacker] += chainLightningAttribute;
					if(chainLightningAbilityCharge[attacker] >= 100.0){
						chainLightningAbilityCharge[attacker] -= 100.0;
						bool isBounced[MAXPLAYERS+1];
						int lastBouncedTarget = attacker;
						float lastBouncedPosition[3];
						GetClientEyePosition(lastBouncedTarget, lastBouncedPosition)
						LastCharge[attacker] = 0.0;
						int i = 0
						int maxBounces = 6;
						for(int target=1;target<=MaxClients && i < maxBounces;target++)
						{
							if(!IsValidClient3(target)) {continue;}
							if(!IsPlayerAlive(target)) {continue;}
							if(!IsOnDifferentTeams(target,attacker)) {continue;}
							if(isBounced[target]) {continue;}

							float VictimPos[3]; 
							GetClientEyePosition(target, VictimPos); 
							if(!IsAbleToSee(lastBouncedTarget, target)) continue;

							isBounced[target] = true;
							GetClientEyePosition(lastBouncedTarget, lastBouncedPosition)
							lastBouncedTarget = target
							int iPart1 = CreateEntityByName("info_particle_system");
							int iPart2 = CreateEntityByName("info_particle_system");

							if (IsValidEdict(iPart1) && IsValidEdict(iPart2))
							{
								char szCtrlParti[32];
								char particleName[32];
								particleName = GetClientTeam(attacker) == 2 ? "dxhr_sniper_rail_red" : "dxhr_sniper_rail_blue";
								Format(szCtrlParti, sizeof(szCtrlParti), "tf2ctrlpart%i", iPart2);
								DispatchKeyValue(iPart2, "targetname", szCtrlParti);

								DispatchKeyValue(iPart1, "effect_name", particleName);
								DispatchKeyValue(iPart1, "cpoint1", szCtrlParti);
								DispatchSpawn(iPart1);
								TeleportEntity(iPart1, lastBouncedPosition, NULL_VECTOR, NULL_VECTOR);
								TeleportEntity(iPart2, VictimPos, NULL_VECTOR, NULL_VECTOR);
								ActivateEntity(iPart1);
								AcceptEntityInput(iPart1, "Start");
								
								CreateTimer(1.0, Timer_KillParticle, EntIndexToEntRef(iPart1));
								CreateTimer(1.0, Timer_KillParticle, EntIndexToEntRef(iPart2));
							}
							currentDamageType[attacker].second |= DMG_IGNOREHOOK;
							SDKHooks_TakeDamage(target,attacker,attacker,100.0*TF2_GetDPSModifiers(attacker, CWeapon),DMG_SHOCK,_,_,_,false)
							++i
						}
					}
				}

				//Lifesteal
				float lifestealFactor = 1.0;
				float maximumOverheal = 1.5;
				int healthHealed;
				if(IsFakeClient(client))
					lifestealFactor = 0.3;

				lifestealFactor *= GetAttribute(CWeapon, "lifesteal effectiveness", 1.0);
				
				Address maximumOverhealModifier = TF2Attrib_GetByName(attacker, "patient overheal penalty");
				if(maximumOverhealModifier != Address_Null)
				{
					maximumOverheal *= TF2Attrib_GetValue(maximumOverhealModifier);
				}

				if(hasBuffIndex(attacker, Buff_Plunder)){
					Buff plunderBuff;
					plunderBuff = playerBuffs[attacker][getBuffInArray(attacker, Buff_Plunder)]
					lifestealFactor *= plunderBuff.severity;
				}
				
				Address LifestealActive = TF2Attrib_GetByName(CWeapon, "bot medic uber health threshold");//Lifesteal attribute
				if(LifestealActive != Address_Null)
					healthHealed += RoundToCeil(damage * TF2Attrib_GetValue(LifestealActive) * lifestealFactor);
				
				Address vampirePowerup = TF2Attrib_GetByName(attacker, "vampire powerup");//Vampire Powerup
				if(vampirePowerup != Address_Null)
					if(TF2Attrib_GetValue(vampirePowerup) == 1)
						healthHealed += RoundToCeil(0.8 * damage * lifestealFactor);
					else if(TF2Attrib_GetValue(vampirePowerup) == 2)
						healthHealed += RoundToCeil(0.3 * damage * lifestealFactor);
				
				if(TF2_IsPlayerInCondition(attacker, TFCond_MedigunDebuff))// Conch
					healthHealed += RoundToCeil(damage * 0.15 * lifestealFactor);
				
				if(GetEventInt(event, "custom") == 2)//backstab
				{
					Address BackstabLifestealActive = TF2Attrib_GetByName(CWeapon, "sanguisuge"); //Kunai
					if(BackstabLifestealActive != Address_Null && TF2Attrib_GetValue(BackstabLifestealActive) > 0.0)
						healthHealed += RoundToCeil(damage * 0.5 * TF2Attrib_GetValue(BackstabLifestealActive));
				}
				if(MadmilkDuration[client] > currentGameTime)
					healthHealed += RoundToCeil(lifestealFactor * damage * (MadmilkDuration[client]-currentGameTime) * 1.66 / 100.0);
				
				if(healthHealed > 0){
					AddPlayerHealth(attacker, healthHealed, maximumOverheal, true, attacker);
					float spreadRatio = GetAttribute(CWeapon, "lifesteal to team", 0.0);
					if(spreadRatio > 0){
						for(int i = 1; i<= MaxClients; ++i){
							if(!IsValidClient3(i))
								continue;
							if(!IsPlayerAlive(i))
								continue;
							if(IsOnDifferentTeams(attacker, i))
								continue;
							if(i == attacker)
								continue;

							AddPlayerHealth(i, RoundToFloor(healthHealed*spreadRatio), maximumOverheal, true, attacker);
						}
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
	
	int medigun = GetWeapon(medic, 1);
	if(!IsValidWeapon(medigun))
		return;
	
	int target = GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
	ApplyUberBuffs(medic, target, medigun);

	CreateTimer(0.1, Timer_UberCheck, EntIndexToEntRef(medigun), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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
			if (IsValidEdict(CWeapon) && GetWeapon(client,1) == CWeapon)
			{
				DHookSetParam(hParams, 1, 1.0);
			}
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
		Address agilityPowerup = TF2Attrib_GetByName(client, "agility powerup");		
		if(agilityPowerup != Address_Null)
		{
			float agilityPowerupValue = TF2Attrib_GetValue(agilityPowerup);
			if(agilityPowerupValue > 0.0)
			{
				switch(cond)
				{
					case TFCond_Slowed:
					{
						return MRES_Supercede;
					}
					case TFCond_TeleportedGlow:
					{
						return MRES_Supercede;
					}
					case TFCond_Dazed:
					{
						return MRES_Supercede;
					}
					case TFCond_FreezeInput:
					{
						return MRES_Supercede;
					}
					case TFCond_GrappledToPlayer:
					{
						return MRES_Supercede;
					}
					case TFCond_LostFooting:
					{
						return MRES_Supercede;
					}
					case TFCond_AirCurrent:
					{
						return MRES_Supercede;
					}
				}
			}
		}

		switch(cond)
		{
			case TFCond_OnFire:
			{
				if(TF2_GetPlayerClass(client) == TFClass_Pyro || TF2_IsPlayerInCondition(client, TFCond_AfterburnImmune))
				{
					return MRES_Supercede;
				}
				Address attribute1 = TF2Attrib_GetByName(client, "absorb damage while cloaked");
				if (attribute1 != Address_Null) 
				{
					if(GetRandomFloat(0.0,1.0) <= TF2Attrib_GetValue(attribute1))
					{
						return MRES_Supercede;
					}
				}
			}
			case TFCond_Bleeding:
			{
				Address attribute2 = TF2Attrib_GetByName(client, "always_transmit_so");
				if (attribute2 != Address_Null) 
				{
					if(GetRandomFloat(0.0,1.0) <= TF2Attrib_GetValue(attribute2))
					{
						return MRES_Supercede;
					}
				}
			}
			case TFCond_Slowed, TFCond_Dazed:
			{
				Address slowResistance = TF2Attrib_GetByName(client, "slow resistance");
				if(slowResistance != Address_Null)
				{
					DHookSetParam(hParams, 2, duration * TF2Attrib_GetValue(slowResistance));
					return MRES_ChangedHandled;
				}
				if(GetAttribute(client, "jarate description", 0.0)){
					return MRES_Supercede;
				}
			}
			case TFCond_Taunting:
			{
				int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEdict(CWeapon))
				{
					char classname[64];
					GetEdictClassname(CWeapon, classname, sizeof(classname)); 
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
					float enrageBonus = GetAttribute(CWeapon, "enraged meter filled when eaten");
					if(enrageBonus){
						enragedKills[client] += RoundFloat(enrageBonus);
					}
				}
			}
			case TFCond_Milked:
			{
				return MRES_Supercede;
			}
			case TFCond_FocusBuff:
			{
				isBuffActive[client] = true;
			}
			case TFCond_CritMmmph:
			{
				isBuffActive[client] = true;
			}
			case TFCond_DefenseBuffed:
			{
				return MRES_Supercede;
			}
			case TFCond_RegenBuffed:
			{
				return MRES_Supercede;
			}
			case TFCond_Jarated, TFCond_MarkedForDeath, TFCond_MarkedForDeathSilent:
			{
				if(GetAttribute(client, "inverter powerup", 0.0) == 1){
					giveDefenseBuff(client, duration);
					return MRES_Supercede;
				}
				else if(GetAttribute(client, "inverter powerup", 0.0) == 2){
					Buff critligma;
					critligma.init("Marked for Crits", "All hits taken are critical", Buff_CritMarkedForDeath, 1, client, duration);
					insertBuff(client, critligma);
					return MRES_Supercede;
				}
				return MRES_Handled;
			}
			case TFCond_MiniCritOnKill:
			{
				miniCritStatusAttacker[client] = currentGameTime+duration;
				return MRES_Supercede;
			}
			case TFCond_CritCola:
			{
				miniCritStatusAttacker[client] = currentGameTime+duration;
				if(GetAttribute(client, "inverter powerup", 0.0) == 1)
					giveDefenseBuff(client, duration);
				else if(GetAttribute(client, "inverter powerup", 0.0) == 2){
					Buff critligma;
					critligma.init("Marked for Crits", "All hits taken are critical", Buff_CritMarkedForDeath, 1, client, duration);
					insertBuff(client, critligma);
				}
				else if(GetAttribute(client, "inverter powerup", 0.0) != 3){
					miniCritStatusVictim[client] = currentGameTime+duration;
				}
				return MRES_Supercede;
			}
			case TFCond_RestrictToMelee:
			{
				if(GetAttribute(client, "inverter powerup", 0.0) == 1 || GetAttribute(client, "inverter powerup", 0.0) == 3)
					return MRES_Supercede;
			}
			case TFCond_Sapped:
			{
				if(GetAttribute(client, "inverter powerup", 0.0) != 3){
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
			TFCond_UberchargedHidden, TFCond_UberBulletResist, TFCond_UberBlastResist, TFCond_UberFireResist, TFCond_AfterburnImmune:
			{
				if(TF2_IsPlayerInCondition(client, TFCond_Sapped) || GetAttribute(client, "inverter powerup", 0.0) == 3)
					return MRES_Supercede;
			}
			case TFCond_ParachuteDeployed:
			{
				int canRedeploy = RoundToNearest(GetAttributeAccumulateAdditive(client, "powerup max charges", 0.0));
				if(canRedeploy > 0)
					return MRES_Supercede;
			}
		}
	}
	return MRES_Ignored;
}
public MRESReturn OnBulletTrace(int victim, Handle hParams){
	float direction[3];
	DHookGetParamVector(hParams, 2, direction);
	CTakeDamageInfo info = CTakeDamageInfo.FromAddress(DHookGetParam(hParams, 1));
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
				EntityExplosion(attacker, info.m_flDamage * TF2_GetDamageModifiers(attacker, weapon, _, false), explosiveBullet, endpos, _, _, _, _, _, weapon, 0.3, _, false, _,_,_,"ExplosionCore_sapperdestroyed");

			float dragonBullet = GetAttribute(weapon, "dragon bullets radius", 0.0);
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

		float KBMult = GetAttributeAccumulateMultiplicative(client, "knockback resistance", 1.0);
		if(KBMult != 1.0){
			if(IsFakeClient(client)){
				ScaleVector(initKB, KBMult);
			}
			else{
				if(knockbackFlags[client] & 1<<0 && client == lastKBSource[client]){
					if(knockbackFlags[client] & 1<<3){
						initKB[0] *= KBMult;
						initKB[1] *= KBMult;
					}if(knockbackFlags[client] & 1<<4){
						initKB[2] *= KBMult;
					}
				}
				else if(knockbackFlags[client] & 1<<1 && client != lastKBSource[client]){
					if(knockbackFlags[client] & 1<<3){
						initKB[0] *= KBMult;
						initKB[1] *= KBMult;
					}if(knockbackFlags[client] & 1<<4){
						initKB[2] *= KBMult;
					}
				}
				else if(knockbackFlags[client] & 1<<2 && lastKBSource[client] == 0){
					if(knockbackFlags[client] & 1<<3){
						initKB[0] *= KBMult;
						initKB[1] *= KBMult;
					}if(knockbackFlags[client] & 1<<4){
						initKB[2] *= KBMult;
					}
				}
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

		float SlowForce = 2.0 * GetAttribute(weapon, "airblast vertical pushback scale")
		float AirblastDamage = 80.0 * GetAttribute(weapon, "airblast pushback scale")
		float TotalRange = 600.0 * GetAttribute(weapon, "deflection size multiplier")
		float Duration = 1.25 * GetAttribute(weapon, "melee range multiplier")
		float ConeRadius = 40.0 * GetAttribute(weapon, "melee bounds multiplier");

		AirblastDamage *= TF2_GetDamageModifiers(owner, weapon);

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
						if(GetClientTeam(i) != GetClientTeam(owner))//Enemies debuffed
						{
							CurrentSlowTimer[i] = currentGameTime+Duration;
							currentDamageType[owner].second |= DMG_IGNOREHOOK;
							SDKHooks_TakeDamage(i,owner,owner,AirblastDamage,DMG_BLAST,weapon,_,_,false);
							
							bool immune = false;
							
							Address agilityPowerup = TF2Attrib_GetByName(i, "agility powerup");		
							if(agilityPowerup != Address_Null && TF2Attrib_GetValue(agilityPowerup) > 0.0)
								immune = true;
							
							if(TF2_IsPlayerInCondition(i,TFCond_MegaHeal))
								immune = true;
							
							if(!immune)
							{
								TF2Attrib_SetByName(i,"move speed penalty", 1/SlowForce);
								TF2Attrib_SetByName(i,"major increased jump height", Pow(1.2/SlowForce,0.3));
							}

							if(GetAttribute(weapon, "airblast flings enemy", 0.0)){
								float flingVelocity[3];
								flingVelocity[2] = GetAttribute(weapon, "airblast flings enemy");
								TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, flingVelocity);

								insertBuff(i, dragonDance);
							}
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
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", currentGameTime);
	}
	return MRES_Ignored;
}
public MRESReturn OnThermalThrusterLaunch(int weapon){
	if(IsValidWeapon(weapon)){
		int owner = getOwner(weapon);
		lastKBSource[owner] = weapon;
		
		float jetpackLunge = GetAttribute(weapon, "jetpack charge damage", 0.0)
		if(jetpackLunge){
			CreateParticle(owner, "utaunt_auroraglow_orange_parent", true, _, 3.5);

			Buff infernalLunge;
			infernalLunge.init("Infernal Lunge", "Deals Contact Damage", Buff_InfernalLunge, 1, owner, 4.0);
			infernalLunge.severity = jetpackLunge;
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
	DHookSetParamVector(hParams, 1, {0.0,0.0,0.0});
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
public MRESReturn OnBotJumpLogic(int entity, Handle hReturn, Handle hParams)  {
	return MRES_Supercede;
}
public Event_PlayerHealed(Handle event, const char[] name, bool:dontBroadcast)
{
	//int client = GetClientOfUserId(GetEventInt(event, "patient"));
	int healer = GetClientOfUserId(GetEventInt(event, "healer"));
	int amount = GetEventInt(event, "amount");
	
	Healed[healer] += float(amount);
}
public TF2Spawn_EnterSpawn(int client, int spawn)
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		int melee = GetWeapon(client,2);
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
		int melee = GetWeapon(client,2);
		if(IsValidEdict(melee))
		{
			TF2Attrib_SetByName(melee,"airblast vulnerability multiplier hidden", 1.0);
			TF2Attrib_SetByName(melee,"damage force increase hidden", 1.0);
		}
	}
}
public Event_BuffDeployed( Handle event, const char[] name, bool:broadcast )
{
	int client = GetClientOfUserId( GetEventInt( event, "buff_owner" ) );
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		isBuffActive[client] = true;
	}

	return;
}
public void TF2_OnConditionAdded(client, TFCond cond)
{
	switch(cond){
		case TFCond_Sapped:{
			buffChange[client] = true;
		}
		case TFCond_Charging:{
			TF2_Override_ChargeSpeed(client);
		}
		case TFCond_Slowed:{
			if(GetAttribute(client, "inverter powerup", 0.0) == 1){
				TF2_AddCondition(client, TFCond_HalloweenSpeedBoost, 3.0);
				TF2_RemoveCondition(client, cond);
			}
		}
		case TFCond_Bonked:{
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 8.0);
			TF2_AddCondition(client, TFCond_HalloweenQuickHeal, 8.0);
			TF2_RemoveCondition(client, cond);
		}
	}
}
public void TF2_OnConditionRemoved(client, TFCond:cond)
{
	switch(cond)
	{
		case TFCond_OnFire:{
			fl_HighestFireDamage[client] = 0.0;
		}
		case TFCond_Charging:{
			float grenadevec[3], distance;
			distance = 500.0;
			GetClientEyePosition(client, grenadevec);
			int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEdict(CWeapon))
			{
				float damage = TF2_GetDPSModifiers(client,CWeapon,false,false) * 70.0;
				int secondary = GetWeapon(client,1);
				if(IsValidEdict(secondary))
				{
					Address bashBonusActive = TF2Attrib_GetByName(secondary, "charge impact damage increased")
					if(bashBonusActive != Address_Null)
					{
						damage *= TF2Attrib_GetValue(bashBonusActive);
					}
				}
				EntityExplosion(client, damage, distance, grenadevec, 1, _, _, _, DMG_ALWAYSGIB + DMG_DISSOLVE, secondary);
			}
		}
		case TFCond_Sapped:{
			buffChange[client] = true;
		}
	}
}
public OnEntityCreated(entity, const char[] classname)
{
	if(!IsValidEdict(entity) || entity < 0 || entity > 2048)
		return;

	int reference = EntIndexToEntRef(entity);
	weaponFireRate[entity] = -1.0;
	isAimlessProjectile[entity] = false;
	
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
	else if(StrContains(classname, "item_powerup_rune", false) == 0)
	{
		RemoveEntity(entity);
	}
	else if(StrEqual(classname, "tank_boss"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Tank);
		RequestFrame(randomizeTankSpecialty, reference);
	}
	
	if(StrContains(classname, "tf_projectile_", false) == 0)
	{
		entitySpawnTime[entity] = currentGameTime;
		g_nBounces[entity] = 0;
		RequestFrame(getProjOrigin, reference);

		if(StrEqual(classname, "tf_projectile_energy_ball") || StrEqual(classname, "tf_projectile_energy_ring")
		|| StrEqual(classname, "tf_projectile_balloffire"))
		{
			RequestFrame(ProjSpeedDelay, reference);
			RequestFrame(PrecisionHoming, reference);
			SDKHook(entity, SDKHook_Touch, FixProjectileCollision);
		}
		else if(StrEqual(classname, "tf_projectile_arrow") || StrEqual(classname, "tf_projectile_healing_bolt"))
		{
			RequestFrame(MultiShot, reference);
			RequestFrame(ProjSpeedDelay, reference);
			RequestFrame(SetZeroGravity, reference);
			RequestFrame(ExplosiveArrow, reference);
			RequestFrame(ChangeProjModel, reference);
			RequestFrame(PrecisionHoming, reference);
			CreateTimer(6.0, SelfDestruct, reference);
			CreateTimer(0.1, ArrowThink, reference, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			RequestFrame(ApplyFullHoming, reference);
			SDKHook(entity, SDKHook_Touch, FixProjectileCollision);
		}
		if(StrEqual(classname, "tf_projectile_syringe") || StrEqual(classname, "tf_projectile_rocket")
		|| StrEqual(classname, "tf_projectile_flare"))
		{
			RequestFrame(MultiShot, reference);
			SDKHook(entity, SDKHook_StartTouch, OnStartTouch);
			RequestFrame(projGravity, reference);
			RequestFrame(PrecisionHoming, reference);
			RequestFrame(ApplyFullHoming, reference);
			SDKHook(entity, SDKHook_Touch, FixProjectileCollision);
		}
		if(StrEqual(classname, "tf_projectile_rocket") || StrEqual(classname, "tf_projectile_flare") || StrEqual(classname, "tf_projectile_sentryrocket"))
		{
			RequestFrame(instantProjectile, reference);
			RequestFrame(monoculusBonus, reference);
			RequestFrame(PrecisionHoming, reference);
			RequestFrame(meteorCollisionCheck, reference);
			SDKHook(entity, SDKHook_Touch, FixProjectileCollision);
		}
		if(StrEqual(classname, "tf_projectile_stun_ball") || StrEqual(classname, "tf_projectile_ball_ornament") || StrEqual(classname, "tf_projectile_cleaver"))
		{
			RequestFrame(MultiShot, reference);
			RequestFrame(projGravity, reference);
			RequestFrame(ResizeProjectile, reference);
			RequestFrame(PrecisionHoming, reference);
			RequestFrame(SetWeaponOwner, reference);
			RequestFrame(ChangeProjModel, reference);
			CreateTimer(1.5, SelfDestruct, reference);
			DataPack pack = CreateDataPack();
			pack.WriteCell(reference);
			pack.WriteFloat(0.1);
			pack.WriteCell(0);
			pack.WriteCell(0);
			RequestFrame(ApplyHomingCharacteristics, pack);
		}
		if(StrEqual(classname, "tf_projectile_pipe") || StrEqual(classname, "tf_projectile_pipe_remote"))
		{
			RequestFrame(MultiShot, reference);
			SDKHook(entity, SDKHook_StartTouch, OnStartTouch);
			RequestFrame(projGravity, reference);
			RequestFrame(PrecisionHoming, reference);
			RequestFrame(ApplyFullHoming, reference);
			RequestFrame(CheckGrenadeMines, reference);
			RequestFrame(ChangeProjModel, reference);
		}
		if(StrEqual(classname, "tf_projectile_sentryrocket"))
		{
			CreateTimer(5.0, SelfDestruct, reference);
			RequestFrame(SentryMultishot, reference);
			homingRadius[entity] = 900.0;
			homingTickRate[entity] = 1;
			RequestFrame(SentryDelay, reference);
		}
		if(StrEqual(classname, "tf_projectile_energy_ring"))
		{
			isProjectileHoming[entity] = true;
			CreateTimer(1.0, SelfDestruct, reference);
		}
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
	isProjectileHoming[entity] = false;
	isProjectileBoomerang[entity] = false;
	isProjectileFireball[entity] = false;
	projectileHomingDegree[entity] = 0.0;
	gravChanges[entity] = false;
	homingRadius[entity] = 0.0;
	homingTickRate[entity] = 0;
	homingTicks[entity] = 0;
	homingDelay[entity] = 0.0;
	homingAimStyle[entity] = -1;
	projectileDamage[entity] = 0.0;
	
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
		SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Tank);
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
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vec);
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
			if(IsValidClient3(owner)){
				int wrench = GetWeapon(owner,2);
				if(IsValidWeapon(wrench)){
					EntityExplosion(owner, TF2_GetSentryDPSModifiers(owner,wrench)*70.0, 350.0, vec, _, _, owner, _ ,DMG_SHOCK, wrench);
				}
			}
		}
	}
	if(debugMode)
		PrintToServer("debugLog | %s was deleted.", classname)
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
		if (!client_respawn_handled[client])
		{
			CreateTimer(0.4, ClChangeClassTimer, GetClientUserId(client));
		}
		CancelClientMenu(client);
		Menu_BuyUpgrade(client, 0);
	}
}
public Event_ResetStats(Handle event, const char[] name, bool:dontBroadcast)
{
	PrintToServer("MvM reset stats????");
	additionalstartmoney = 0.0;
	StartMoneySaved = 0.0;
	gameStage = 0;
	UpdateMaxValuesStage(gameStage)
	OverAllMultiplier = GetConVarFloat(cvar_BotMultiplier);
	replenishStatus = true;
	for(int i = 1; i<=MaxClients;++i){
		if(!IsValidClient(i))
			continue;

		ResetClientUpgrades(i);
		TF2_RemoveAllWeapons(i)
	}
	CreateTimer(0.4, ResetClientsTimer);
	DeleteSavedPlayerData();
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
	PrintToServer("lol | %s | %s", oldMission, missionName);
	
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
			CancelClientMenu(client);
			CurrencySaved[client] = CurrencyOwned[client];
			for (slot = 0; slot < NB_SLOTS_UED; slot++)
			{
				for(a = 0; a < MAX_ATTRIBUTES_ITEM; a++)
				{
					currentupgrades_idx_mvm_chkp[client][slot][a] = currentupgrades_idx[client][slot][a];
					currentupgrades_val_mvm_chkp[client][slot][a] = currentupgrades_val[client][slot][a];
				}
				for(a = 0; a < MAX_ATTRIBUTES; a++)
				{
					upgrades_ref_to_idx_mvm_chkp[client][slot][a] = upgrades_ref_to_idx[client][slot][a];
				}
				client_spent_money_mvm_chkp[client][slot] = client_spent_money[client][slot];
				currentupgrades_number_mvm_chkp[client][slot] = currentupgrades_number[client][slot];
				for(int y = 0;y<5;y++)
				{
					currentupgrades_restriction_mvm_chkp[client][slot][y] = currentupgrades_restriction[client][slot][y];
				}
			}
			client_new_weapon_ent_id_mvm_chkp[client] = client_new_weapon_ent_id[client];
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

	isTagged[attack][client] = false;
		
	fanOfKnivesCount[client] = 0;
	maelstromChargeCount[client] = 0;
	RageBuildup[client] = 0.0;
	frayNextTime[attack] = 0.0;
	enragedKills[client] = 0;
	TeamTacticsBuildup[client] = 0.0;
	isDeathTick[client] = true;

	CancelClientMenu(client);

	if(IsValidClient3(attack)){
		int weapon = GetEntPropEnt(attack, Prop_Send, "m_hActiveWeapon");
		if(IsValidWeapon(weapon)){
			float fireworksChance = GetAttribute(weapon, "fireworks chance", 0.0)
			if(fireworksChance > 0.0){
				float position[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
				EntityExplosion(attack, 100.0*TF2_GetDPSModifiers(attack, weapon)*fireworksChance, 400.0, position, _, _, client);
			}
		}
		int secondary = GetWeapon(attack, 1);
		if(IsValidWeapon(secondary)){
			int damagetype = GetEventInt(event, "damagebits");
			if(damagetype == DMG_ALWAYSGIB + DMG_DISSOLVE){
				float painTrainActive = GetAttribute(secondary, "chain charge on kill", 0.0)
				if(painTrainActive){
					SetEntPropFloat(attack, Prop_Send, "m_flChargeMeter", 100.0);
					TF2_AddCondition(attack, TFCond_Charging);
				}
			}
		}
	}
	if(hasBuffIndex(client, Buff_Frozen)){
		int owner = playerBuffs[client][getBuffInArray(client, Buff_Frozen)].inflictor;
		for(int i = 0;i<9;++i)
		{
			int iEntity = CreateEntityByName("tf_projectile_syringe");
			if (!IsValidEdict(iEntity)) 
				continue;

			int iTeam = GetClientTeam(owner);
			float fAngles[3],fOrigin[3],vBuffer[3]
			float fVelocity[3]
			float fwd[3]
			SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);
			SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", fOrigin);
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
			SetEntityGravity(iEntity, 9.0);

			jarateWeapon[iEntity] = client;
			SDKHook(iEntity, SDKHook_Touch, CollisionFrozenFrag);
			SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 1.5);

			float vecBossMin[3], vecBossMax[3];
			GetEntPropVector(iEntity, Prop_Send, "m_vecMins", vecBossMin);
			GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecBossMax);
			
			float vecScaledBossMin[3], vecScaledBossMax[3];
			
			vecScaledBossMin = vecBossMin;
			vecScaledBossMax = vecBossMax;

			vecScaledBossMin[0] -= 3.0;
			vecScaledBossMax[0] += 3.0;
			vecScaledBossMin[1] -= 3.0;
			vecScaledBossMax[1] += 3.0;
			vecScaledBossMin[2] -= 3.0;
			vecScaledBossMax[2] += 3.0;
			
			SetEntPropVector(iEntity, Prop_Send, "m_vecMins", vecScaledBossMin);
			SetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecScaledBossMax);
			SetEntityRenderColor(iEntity, 0, 128, 255, 90);
			CreateTimer(3.0, SelfDestruct, EntIndexToEntRef(iEntity));
		}
	}

	clearAllBuffs(client);

	if(snowstormActive[client]){
		int particleEffect = EntRefToEntIndex(snowstormParticle[client]);
		if(IsValidEntity(particleEffect)){
			SetVariantString("ParticleEffectStop");
			AcceptEntityInput(particleEffect, "DispatchEffect");
			RemoveEdict(particleEffect);
		}
		snowstormActive[client] = false;
	}

	karmicJusticeScaling[client] = 0.0;

	if(IsValidEdict(autoSentryID[client]) && autoSentryID[client] > 32)
	{
		RemoveEntity(autoSentryID[client]);
		autoSentryID[client] = -1;
	}

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

	if (IsMvM())
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
		if(!(lastFlag[client] & FL_ONGROUND) && flags & FL_ONGROUND)
		{
			Address bossType = TF2Attrib_GetByName(client, "damage force increase text");
			if(bossType != Address_Null && TF2Attrib_GetValue(bossType) > 0.0)
			{
				float bossValue = TF2Attrib_GetValue(bossType);
				switch(bossValue)
				{
					case 2.0:
					{
						miniCritStatusVictim[client] = currentGameTime+10.0;
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
			Address bossType = TF2Attrib_GetByName(client, "damage force increase text");
			if(bossType != Address_Null && TF2Attrib_GetValue(bossType) > 0.0)
			{
				float bossValue = TF2Attrib_GetValue(bossType);
				switch(bossValue)
				{
					case 2.0:
					{
						miniCritStatusVictim[client] = 0.0;
						TF2Attrib_SetByName(CWeapon, "fire rate penalty", 0.1)
						TF2Attrib_SetByName(CWeapon, "dmg taken increased", 0.1)
						TF2Attrib_SetByName(CWeapon, "faster reload rate", 0.0)
						TF2Attrib_SetByName(CWeapon, "Blast radius increased", 1.75)
						SetEntityGravity(client, 0.2);
						SetEntProp(CWeapon, Prop_Data, "m_bReloadsSingly", 0);
						CreateParticleEx(client, "ExplosionCore_MidAir");
					}
				}
				//PrintToChatAll("air")
			}
		}
		if(TF2_IsPlayerInCondition(client, TFCond_Charging))
			TF2_Override_ChargeSpeed(client);

		if(powerupParticle[client] <= currentGameTime && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		{
			Address strengthPowerup = TF2Attrib_GetByName(client, "strength powerup");
			if(strengthPowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(strengthPowerup) == 1){
					CreateParticle(client, "utaunt_tarotcard_orange_wind", true, _, 5.0,_,_,_,true);
					powerupParticle[client] = currentGameTime+5.1;
				}
				else if(TF2Attrib_GetValue(strengthPowerup) == 2){
					CreateParticle(client, "utaunt_tarotcard_orange_wind", true, _, 5.0,_,_,_,true);
					CreateParticle(client, "utaunt_pedalfly_red_spins", true, _, 5.0,_,_,_,true);
					powerupParticle[client] = currentGameTime+5.1;
				}
				else if(TF2Attrib_GetValue(strengthPowerup) == 3){
					CreateParticle(client, "utaunt_tarotcard_orange_wind", true, _, 5.0,_,_,_,true);
					CreateParticle(client, "utaunt_pedalfly_red_pedals", true, _, 5.0,_,_,_,true);
					CreateParticle(client, "critical_rocket_redsparks", true, _, 5.0,_,_,_,true);
					powerupParticle[client] = currentGameTime+5.1;
				}
			}
			Address resistancePowerup = TF2Attrib_GetByName(client, "resistance powerup");
			if(resistancePowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(resistancePowerup) == 1){
					CreateParticleEx(client, "soldierbuff_red_spikes", 1, _, _, 2.0);
					powerupParticle[client] = currentGameTime+2.1;
				}
				else if(TF2Attrib_GetValue(resistancePowerup) == 2){
					CreateParticleEx(client, "utaunt_prismatichaze_parent", 1, _, _, 4.0);
					powerupParticle[client] = currentGameTime+4.1;
				}
				else if(TF2Attrib_GetValue(resistancePowerup) == 3){
					CreateParticleEx(client, "soldierbuff_mvm", 1, _, _, 5.0);
					powerupParticle[client] = currentGameTime+5.1;
				}
			}
			Address vampirePowerup = TF2Attrib_GetByName(client, "vampire powerup");
			if(vampirePowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(vampirePowerup) == 1){
					CreateParticleEx(client, "utaunt_hellpit_parent", 1, _, _, 5.0);
					powerupParticle[client] = currentGameTime+5.1;
				}
				else if(TF2Attrib_GetValue(vampirePowerup) == 2){
					CreateParticle(client, "utaunt_hands_floor1_purple", true, _, 5.0,_,_,_,true);
					CreateParticleEx(client, "utaunt_hellpit_parent", 1, _, _, 5.0);
					powerupParticle[client] = currentGameTime+5.1;
				}
				else if(TF2Attrib_GetValue(vampirePowerup) == 3){
					CreateParticle(client, "utaunt_hands_floor1_red", true, _, 5.0,_,_,_,true);
					CreateParticle(client, "utaunt_hands_floor2_red", true, _, 5.0,_,_,_,true);
					CreateParticleEx(client, "utaunt_hellpit_parent", 1, _, _, 5.0);
					powerupParticle[client] = currentGameTime+5.1;
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
					CreateParticle(client, "utaunt_hands_floor1_purple", true, _, 5.0,_,_,_,true);
					CreateParticleEx(client, "utaunt_hellpit_parent", 1, _, _, 5.0);
					powerupParticle[client] = currentGameTime+5.1;
				}
				
				powerupParticle[client] = currentGameTime+5.0;
			}
			Address precisionPowerup = TF2Attrib_GetByName(client, "precision powerup");
			if(precisionPowerup != Address_Null && TF2Attrib_GetValue(precisionPowerup) > 0.0)
			{
				if(TF2_GetPlayerClass(client) != TFClass_Pyro && TF2_GetPlayerClass(client) != TFClass_Engineer)
					CreateParticle(client, "eye_powerup_blue_lvl_4", true, "righteye", 5.0,_,_,_,true);
				else
					CreateParticle(client, "eye_powerup_blue_lvl_4", true, "eyeglow_R", 5.0,_,_,_,true);

				powerupParticle[client] = currentGameTime+5.0;
			}
			Address agilityPowerup = TF2Attrib_GetByName(client, "agility powerup");
			if(agilityPowerup != Address_Null && TF2Attrib_GetValue(agilityPowerup) > 0.0)
			{
				if(TF2Attrib_GetValue(agilityPowerup) == 1){
					CreateParticle(client, "utaunt_pedalfly_blue_spins", true, _, 5.0,_,_,_,true);
					powerupParticle[client] = currentGameTime+5.1;
				}
				else if(TF2Attrib_GetValue(agilityPowerup) == 2){
					CreateParticle(client, "utaunt_pedalfly_blue_spins", true, _, 5.0,_,_,_,true);
					CreateParticle(client, "utaunt_pedalfly_blue_sparkles", true, _, 5.0,_,_,_,true);
					powerupParticle[client] = currentGameTime+5.1;
				}
				else if(TF2Attrib_GetValue(agilityPowerup) == 3){
					CreateParticle(client, "utaunt_pedalfly_blue_pedals", true, _, 5.0,_,_,_,true);
					powerupParticle[client] = currentGameTime+5.1;
				}

				CreateParticleEx(client, "medic_resist_bullet", 1, _, _, 5.0);
				powerupParticle[client] = currentGameTime+5.1;
			}
			Address knockoutPowerup = TF2Attrib_GetByName(client, "knockout powerup");
			if(knockoutPowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(knockoutPowerup) == 1){
					CreateParticleEx(client, "medic_resist_blast", 1, _, _, 5.0);
					powerupParticle[client] = currentGameTime+5.1;
				}
				else if(TF2Attrib_GetValue(knockoutPowerup) == 2){
					CreateParticle(client, "utaunt_spellsplash_parent", true, _, 5.0,_,_,_,true);
					powerupParticle[client] = currentGameTime+5.1;
				}
				else if(TF2Attrib_GetValue(knockoutPowerup) == 3){
					CreateParticle(client, "utaunt_smoke_floor1", true, _, 5.0,_,_,_,true);
					powerupParticle[client] = currentGameTime+5.1;
				}
			}
			Address kingPowerup = TF2Attrib_GetByName(client, "king powerup");
			if(kingPowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(kingPowerup) == 1){
					int clientTeam = GetClientTeam(client);
					float clientPos[3];
					GetEntPropVector(client, Prop_Data, "m_vecOrigin", clientPos);
					Buff kingBuff;
					kingBuff.init("King Aura", "", Buff_KingAura, 1, client, 3.0);
					kingBuff.multiplicativeAttackSpeedMult = 1.33;
					kingBuff.additiveDamageMult = 0.2;
					for(int i = 1;i<=MaxClients;++i)
					{
						if(IsValidClient3(i) && IsPlayerAlive(i))
						{
							int iTeam = GetClientTeam(i);
							if(clientTeam == iTeam)
							{
								float VictimPos[3];
								GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
								VictimPos[2] += 30.0;
								if(GetVectorDistance(clientPos,VictimPos,true) <= 360000.0)
								{
									if(iTeam == 2)
										CreateParticle(i, "powerup_king_red", true, _, 2.0);
									else
										CreateParticle(i, "powerup_king_blue", true, _, 2.0);
									
									insertBuff(i, kingBuff);
								}
							}
						}
					}
					powerupParticle[client] = currentGameTime+2.1;
				}
				else if(TF2Attrib_GetValue(kingPowerup) == 2){
					if(IsValidClient3(tagTeamTarget[client])){
						CreateParticleEx(client, "utaunt_lavalamp_green_particles", 1, _, _, 4.0);
						CreateParticleEx(tagTeamTarget[client], "utaunt_lavalamp_green_particles", 1, _, _, 4.0);
						powerupParticle[client] = currentGameTime+4.1;
					}
				}
			}
			Address plaguePowerup = TF2Attrib_GetByName(client, "plague powerup");
			if(plaguePowerup != Address_Null && TF2Attrib_GetValue(plaguePowerup) > 0.0)
			{
				if(TF2Attrib_GetValue(plaguePowerup) == 1){
					CreateParticle(client, "powerup_plague_carrier", true, _, 5.0);
					powerupParticle[client] = currentGameTime+5.1;
				}
				else if(TF2Attrib_GetValue(plaguePowerup) == 2){
					CreateParticle(client, "powerup_plague_carrier", true, _, 5.0);
					powerupParticle[client] = currentGameTime+5.1;
				}
				else if(TF2Attrib_GetValue(plaguePowerup) == 3){
					CreateParticleEx(client, "halloween_burningplayer_flyingbits", 1, _, _, 0.6);
					powerupParticle[client] = currentGameTime+0.7;
				}
			}
			Address supernovaPowerup = TF2Attrib_GetByName(client, "supernova powerup");
			if(supernovaPowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(supernovaPowerup) == 1.0){
					CreateParticleEx(client, "powerup_supernova_ready", 1, _, _, 5.0);
					powerupParticle[client] = currentGameTime+5.1;
				}else if(TF2Attrib_GetValue(supernovaPowerup) == 2.0){
					CreateParticleEx(client, "heavy_ring_of_fire");
					powerupParticle[client] = currentGameTime+1.0;
				}else if(TF2Attrib_GetValue(supernovaPowerup) == 3.0){
					CreateParticleEx(client, "utaunt_electric_mist", 1, _, _, 5.0);
					powerupParticle[client] = currentGameTime+5.1;
				}
			}
			Address inverterPowerup = TF2Attrib_GetByName(client, "inverter powerup");
			if(inverterPowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(inverterPowerup) == 1.0){
					CreateParticleEx(client, "utaunt_portalswirl_purple_parent", 1, _, _, 5.0);
					powerupParticle[client] = currentGameTime+5.1;
				}else if(TF2Attrib_GetValue(inverterPowerup) == 2.0){
					CreateParticleEx(client, "utaunt_storm_parent_o", 1, _, _, 5.0);
					powerupParticle[client] = currentGameTime+5.1;
				}else if(TF2Attrib_GetValue(inverterPowerup) == 3.0){
					CreateParticle(client, "utaunt_cremation_black_parent", true, _, 5.0);
					CreateParticle(client, "utaunt_cremation_purple_parent", true, _, 5.0);
					powerupParticle[client] = currentGameTime+5.1;
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
			if(MenuTimer[client] < currentGameTime)
			{
				Menu_BuyUpgrade(client, 0);
				MenuTimer[client] = currentGameTime+0.5;
			}
		}
		else
		{
			inScore[client] = false;
		}

		if (impulse == 201 && ImpulseTimer[client] < currentGameTime)
		{
			if(currentitem_level[client][3] == 242 && client_new_weapon_ent_id[client] != 0 && IsValidEdict(client_new_weapon_ent_id[client]))
			{
				TF2Util_SetPlayerActiveWeapon(client, client_new_weapon_ent_id[client]);
				//SetEntPropFloat(client_new_weapon_ent_id[client], Prop_Send, "m_flNextPrimaryAttack", 0.3+currentGameTime+(1/weaponFireRate[client_new_weapon_ent_id[client]]));
			}
			ImpulseTimer[client] = currentGameTime+0.3;
		}
		if(IsValidEdict(CWeapon))
		{
			if(buttons & IN_ATTACK){
				char strName[32];
				GetEntityClassname(CWeapon, strName, 32)
				if(StrEqual(strName, "tf_weapon_minigun", false)){
					SetEntPropFloat(CWeapon, Prop_Send, "m_flNextSecondaryAttack", GetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack"));
				}
			}
			if(HasEntProp(CWeapon, Prop_Send, "m_flChargedDamage"))
			{
				float charging = GetEntPropFloat(CWeapon, Prop_Send, "m_flChargedDamage");
				if(charging > 0.0 || TF2_IsPlayerInCondition(client, TFCond_Zoomed))
				{
					if(charging < savedCharge[client]){
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

					if(maelstromChargeCount[client] > 1){
						int iEntity = CreateEntityByName("tf_projectile_arrow");
						if (IsValidEntity(iEntity)){
							fAngles[0] -= 3.0;
							SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
							SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);

							GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);

							fVelocity[0] = vBuffer[0]*3000.0;
							fVelocity[1] = vBuffer[1]*3000.0;
							fVelocity[2] = vBuffer[2]*3000.0;

							SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
							SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);

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
				if(buttons & IN_DUCK && buttons & IN_ATTACK3 && fl_GlobalCoolDown[client] <= currentGameTime)
				{
					fl_GlobalCoolDown[client] = currentGameTime+0.4;
					if(GetAttribute(client, "revenge powerup", 0.0) == 1 && RageActive[client] == false && RageBuildup[client] >= 1.0)
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
					if(GetAttribute(client, "revenge powerup", 0.0) == 3 && enragedKills[client] >= 80){
						EmitSoundToAll(SOUND_REVENGE, client, -1, 150, 0, 1.0);
						EmitSoundToAll(SOUND_REVENGE, client, -1, 150, 0, 1.0);
						enragedKills[client] = 0;
						TF2_AddCondition(client, TFCond_CritCanteen, 16.0);
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, 16.0);
						Buff enraged;
						enraged.init("Enraged", "", Buff_Enraged, 1, client, 16.0);
						enraged.additiveAttackSpeedMult = 1.0;
						enraged.multiplicativeDamageTaken = 0.4;

						insertBuff(client, enraged);
					}
					if(duplicationCooldown[client] <= currentGameTime){
						if(GetAttribute(client, "regeneration powerup", 0.0) == 2.0){
							duplicationCooldown[client] = currentGameTime+10.0;
							AddPlayerHealth(client, GetClientHealth(client), 2.0);
							float fOrigin[3];
							GetClientAbsOrigin(client, fOrigin);
							EmitSoundToAll(SOUND_HEAL, client, _, _, _, _, _, _, fOrigin);
						}
					}
					if(GetAttribute(client, "king powerup", 0.0) == 2.0){
						for(int i=1;i<=MaxClients;++i)
						{
							if(!IsValidClient3(i))
								continue;
							
							if(!IsPlayerAlive(i))
								continue;
							
							if(IsOnDifferentTeams(client,i))
								continue;
							
							if(!IsTargetInSightRange(client, i, 10.0, 2000.0, true, false))
								continue;

							if(!IsAbleToSee(client,i, false))
								continue;
								
							tagTeamTarget[client] = i;
							break;
						}
					}
					if(warpCooldown[client] <= currentGameTime){
						if(GetAttribute(client, "agility powerup", 0.0) == 3.0){
							CastWarp(client);
						}
					}
					if(GetAttribute(client, "resistance powerup", 0.0) == 3.0){
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
				}
				
				if(!(flags & FL_ONGROUND))
				{
					if(GetAttribute(client, "agility powerup", 0.0) == 2.0){
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
						if(buttons & IN_DUCK)
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
				}
				
				GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", trueVel[client]);
				float SkillNumber = GetAttribute(CWeapon, "apply look velocity on damage", 0.0);

				switch(SkillNumber)
				{
					case 1.0: //Teleport
					{
						if(weaponArtCooldown[client] > currentGameTime)
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Adrenaline: %.1fs", weaponArtCooldown[client]-currentGameTime); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Adrenaline: READY (MOUSE3)"); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
							if(buttons & IN_ATTACK3)
							{
								if(fl_GlobalCoolDown[client] <= currentGameTime)
								{
									fl_GlobalCoolDown[client] = currentGameTime+0.3;
									weaponArtCooldown[client] = currentGameTime+15.0;
									BleedBuildup[client] = 0.0;
									RadiationBuildup[client] = 0.0;
									miniCritStatusAttacker[client] = currentGameTime+5.0
									TF2_AddCondition(client, TFCond_RestrictToMelee, 5.0);
									TF2_AddCondition(client, TFCond_DodgeChance, 2.5);
									TF2_AddCondition(client, TFCond_AfterburnImmune, 2.5);
									TF2_AddCondition(client, TFCond_UberchargedHidden, 0.01);
									EmitSoundToAll(SOUND_ADRENALINE, client, -1, 150, 0, 1.0);
									CreateParticleEx(client, "utaunt_tarotcard_red_wind", 1, _, _, 5.0);
								}
							}
						}
					}
					case 3.0: //Stun Shot
					{
						if(weaponArtCooldown[client] > currentGameTime)
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Stun Shot: %.1fs", weaponArtCooldown[client]-currentGameTime); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Stun Shot: READY (MOUSE3)"); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
							if(buttons & IN_ATTACK3)
							{
								if(fl_GlobalCoolDown[client] <= currentGameTime)
								{
									weaponArtCooldown[client] = currentGameTime+7.0;
									fl_GlobalCoolDown[client] = currentGameTime+0.8;
									TF2Attrib_SetByName(client, "bullets per shot bonus", 5.0);
									refreshAllWeapons(client);
									SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", currentGameTime);
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
						if(weaponArtCooldown[client] > currentGameTime)
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Juggernaut: %.1fs", weaponArtCooldown[client]-currentGameTime); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Juggernaut: READY (MOUSE3)"); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
							if(buttons & IN_ATTACK3)
							{
								if(fl_GlobalCoolDown[client] <= currentGameTime)
								{
									weaponArtCooldown[client] = currentGameTime+30.0;
									fl_GlobalCoolDown[client] = currentGameTime+0.8;
									TF2_AddCondition(client, TFCond_MegaHeal, 5.0);
								}
							}
						}
					}
					case 5.0: //Fireball Volley
					{
						if(weaponArtCooldown[client] > currentGameTime)
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Fireball Volley: %.1fs", weaponArtCooldown[client]-currentGameTime); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Fireball Volley: READY (MOUSE3)"); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
							if(buttons & IN_ATTACK3)
							{
								if(fl_GlobalCoolDown[client] <= currentGameTime)
								{
									weaponArtCooldown[client] = currentGameTime+15.0;
									fl_GlobalCoolDown[client] = currentGameTime+0.8;
									
									for(int i = 0;i<5;++i)
									{
										int iEntity = CreateEntityByName("tf_projectile_spellfireball");
										if (IsValidEdict(iEntity)) 
										{
											int iTeam = GetClientTeam(client);
											float fAngles[3]
											float fOrigin[3]
											float vBuffer[3]
											float fVelocity[3]
											float fwd[3]
											SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
											SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
											GetClientEyeAngles(client, fAngles);
											GetClientEyePosition(client, fOrigin);
											
											fAngles[1] -= 10.0*(5/2);
											fAngles[1] += i*10.0;

											GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
											ScaleVector(fwd, 30.0);
											
											AddVectors(fOrigin, fwd, fOrigin);
											GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
											
											float velocity = 1300.0;
											fVelocity[0] = vBuffer[0]*velocity;
											fVelocity[1] = vBuffer[1]*velocity;
											fVelocity[2] = vBuffer[2]*velocity;
											
											TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
											DispatchSpawn(iEntity);
											SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchDragonsBreath);
											CreateTimer(10.0,SelfDestruct,EntIndexToEntRef(iEntity));
											homingRadius[iEntity] = 400.0;
											homingTickRate[iEntity] = 3;
										}
									}
								}
							}
						}
					}
					case 6.0: //Detonate
					{
						if(weaponArtCooldown[client] > currentGameTime)
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Detonate Flares: %.1fs", weaponArtCooldown[client]-currentGameTime); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Detonate Flares: READY (MOUSE3)"); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
							if(buttons & IN_ATTACK3)
							{
								if(fl_GlobalCoolDown[client] <= currentGameTime)
								{
									weaponArtCooldown[client] = currentGameTime+0.2;
									fl_GlobalCoolDown[client] = currentGameTime+0.2;
									
									float damageMult = TF2_GetDamageModifiers(client,CWeapon)
									float m_fOrigin[3];
									int entity = -1; 
									while((entity = FindEntityByClassname(entity, "tf_projectile_flare"))!=INVALID_ENT_REFERENCE)
									{
										int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
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
						if(weaponArtCooldown[client] > currentGameTime)
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Dash: %.1fs", weaponArtCooldown[client]-currentGameTime); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Dash: READY (MOUSE2)"); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
							if(buttons & IN_ATTACK2)
							{
								if(fl_GlobalCoolDown[client] <= currentGameTime)
								{
									weaponArtCooldown[client] = currentGameTime+1.0;
									fl_GlobalCoolDown[client] = currentGameTime+0.2;
									
									float flSpeed = GetEntPropFloat(client, Prop_Data, "m_flMaxspeed") * 2.0
									float flVel[3],flAng[3], vBuffer[3]
									GetClientEyeAngles(client,flAng)
									GetAngleVectors(flAng, vBuffer, NULL_VECTOR, NULL_VECTOR)
									flVel[0] = flSpeed * vBuffer[0] * 1.5;
									flVel[1] = flSpeed * vBuffer[1] * 1.5;
									flVel[2] = 100.0 + (flSpeed * (vBuffer[2] * 0.75));
									if(flags & FL_ONGROUND)
										flVel[2] += 200;
									TeleportEntity(client, NULL_VECTOR,NULL_VECTOR, flVel)
									EmitSoundToAll(SOUND_DASH, client, -1, 80, 0, 1.0);
								}
							}
						}
					}
					case 8.0: //Transient Moonlight
					{
						if(weaponArtParticle[client] <= currentGameTime)
						{
							weaponArtParticle[client] = currentGameTime+7.1;
							CreateParticle(CWeapon, "utaunt_auroraglow_purple_parent", true, _, 7.0, _, _, 1);
							int clients[MAXPLAYERS+1], numClients = getClientParticleStatus(clients, client);
							TE_Send(clients,numClients)
						}
						if(weaponArtCooldown[client] > currentGameTime)
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Transient Moonlight: %.1fs", weaponArtCooldown[client]-currentGameTime); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Transient Moonlight: R (MOUSE2)"); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
							if(buttons & IN_ATTACK2)
							{
								if(fl_GlobalCoolDown[client] <= currentGameTime)
								{
									weaponArtCooldown[client] = currentGameTime+6.0;
									fl_GlobalCoolDown[client] = currentGameTime+0.2;
									
									float fAngles[3], fVelocity[3], fOrigin[3], vBuffer[3], fwd[3];
									char projName[32] = "tf_projectile_arrow";
									int iEntity = CreateEntityByName(projName);
									if (IsValidEdict(iEntity)) 
									{
										int iTeam = GetClientTeam(client);
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
										float velocity = 5000.0;
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
										SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchMoonveil);
										
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
										CreateParticle(iEntity, "utaunt_auroraglow_purple_parent", true, _, 5.0, particleOffset);
										particleOffset[2] -= 20.0;
										CreateParticle(iEntity, "utaunt_auroraglow_purple_parent", true, _, 5.0, particleOffset);
										particleOffset[2] += 40.0;
										CreateParticle(iEntity, "utaunt_auroraglow_purple_parent", true, _, 5.0, particleOffset);
									}
								}
							}
						}
					}
					case 9.0: //Corpse Piler
					{
						if(weaponArtParticle[client] <= currentGameTime)
						{
							weaponArtParticle[client] = currentGameTime+14.0;
							CreateParticleEx(CWeapon, "critgun_weaponmodel_red", 1, -1, _, 13.0);
							SetEntityRenderColor(CWeapon, 255,0,0,200);
						}

						if(weaponArtCooldown[client] > currentGameTime)
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Corpse Piler: %.1fs", weaponArtCooldown[client]-currentGameTime); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Corpse Piler: READY (MOUSE2)"); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
							if(buttons & IN_ATTACK2)
							{
								if(fl_GlobalCoolDown[client] <= currentGameTime)
								{
									weaponArtCooldown[client] = currentGameTime+30.0;
									fl_GlobalCoolDown[client] = currentGameTime+0.2;
									
									buttons |= IN_ATTACK;
									SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", currentGameTime);
									RequestFrame(disableWeapon,client);
									
									for(int i=0;i<20;++i)
									{
										Handle hPack = CreateDataPack();
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
						if(weaponArtParticle[client] <= currentGameTime)
						{
							weaponArtParticle[client] = currentGameTime+3.0;
							CreateParticleEx(CWeapon, "critgun_weaponmodel_red", 1, _, _, 4.0);
							
							SetEntityRenderColor(CWeapon, 255, 162, 0,200);
							TF2Attrib_SetByName(CWeapon,"SPELL: Halloween green flames", 1.0);
							TF2Attrib_SetByName(client,"SPELL: Halloween green flames", 1.0);
							TF2Attrib_ClearCache(client);
							TF2Attrib_ClearCache(CWeapon);
						}
						if(weaponArtCooldown[client] > currentGameTime)
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Homing Flares: %.1fs", weaponArtCooldown[client]-currentGameTime); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Homing Flares: READY (MOUSE2)"); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
							if(buttons & IN_ATTACK2)
							{
								if(fl_GlobalCoolDown[client] <= currentGameTime)
								{
									weaponArtCooldown[client] = currentGameTime+3.0;
									fl_GlobalCoolDown[client] = currentGameTime+0.2;
									int iTeam = GetClientTeam(client);
									float fAngles[3],fOrigin[3],vBuffer[3],vRight[3],fVelocity[3],fwd[3]
									for(int i=0;i<3;++i)
									{
										int iEntity = CreateEntityByName("tf_projectile_flare");
										if (IsValidEdict(iEntity)) 
										{
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
											
											float Speed = 1200.0;
											fVelocity[0] = vBuffer[0]*Speed;
											fVelocity[1] = vBuffer[1]*Speed;
											fVelocity[2] = vBuffer[2]*Speed;
											SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
											TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
											DispatchSpawn(iEntity);
											SetEntityGravity(iEntity,0.01);
											
											SDKHook(iEntity, SDKHook_Touch, OnCollisionPhotoViscerator);
											CreateTimer(0.01, HomingFlareThink, EntIndexToEntRef(iEntity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
											CreateParticle(iEntity, "utaunt_auroraglow_green_parent", true, _, 5.0);
											CreateTimer(5.0, SelfDestruct, EntIndexToEntRef(iEntity));
										}
									}
								}
							}
						}
					}
					case 11.0:
					{
						if(weaponArtParticle[client] <= currentGameTime)
						{
							weaponArtParticle[client] = currentGameTime+4.0;
							SetEntityRenderColor(CWeapon, 255, 255, 255, 1);
						}
					}
					case 12.0: //Strong Dash
					{
						if(weaponArtCooldown[client] > currentGameTime)
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Silent Dash: %.1fs", weaponArtCooldown[client]-currentGameTime); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Silent Dash: READY (MOUSE3)"); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
							if(buttons & IN_ATTACK3)
							{
								if(fl_GlobalCoolDown[client] <= currentGameTime)
								{
									weaponArtCooldown[client] = currentGameTime+1.0;
									fl_GlobalCoolDown[client] = currentGameTime+0.2;
									
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
						if(weaponArtParticle[client] <= currentGameTime)
						{
							weaponArtParticle[client] = currentGameTime+3.0;
							CreateParticleEx(CWeapon, "critgun_weaponmodel_red", 1, _, _, 3.0);
						}
					}
					case 14.0:
					{
						if(!immolationActive[client])
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Immolation: INACTIVE"); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Immolation: ACTIVE"); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						if(buttons & IN_ATTACK3)
						{
							if(fl_GlobalCoolDown[client] <= currentGameTime)
							{
								fl_GlobalCoolDown[client] = currentGameTime+0.5;
								immolationActive[client] = !immolationActive[client];
							}
						}
					}
					case 15.0:{
						if(sunstarDuration[client] < currentGameTime)
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Sunstar: INACTIVE"); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);

							if(buttons & IN_ATTACK3)
							{
								if(fl_GlobalCoolDown[client] <= currentGameTime)
								{
									fl_GlobalCoolDown[client] = currentGameTime+0.5;
									int metal = GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
									if(metal > 500){
										sunstarDuration[client] = currentGameTime + 0.002*metal;
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
							Format(CooldownTime, sizeof(CooldownTime), "Sunstar: ACTIVE | %.1fs", sunstarDuration[client]-currentGameTime); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
					}
					case 16.0:{
						if(weaponArtCooldown[client] > currentGameTime)
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Airstrike: %.1fs", weaponArtCooldown[client]-currentGameTime); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
						}
						else
						{
							char CooldownTime[32]
							Format(CooldownTime, sizeof(CooldownTime), "Airstrike: READY", sunstarDuration[client]-currentGameTime); 
							SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 220, 15, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudAbility, CooldownTime);
							if(buttons & IN_ATTACK3)
							{
								if(fl_GlobalCoolDown[client] <= currentGameTime)
								{
									fl_GlobalCoolDown[client] = currentGameTime+0.5;
									weaponArtCooldown[client] = currentGameTime+25.0;

									float rocketDamage = 25.0;
									int melee = GetWeapon(client, 2);

									if(IsValidWeapon(melee))
										rocketDamage *= TF2_GetSentryDPSModifiers(client, melee);
									
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
				}
				float chainLightningAttribute = GetAttribute(CWeapon, "chain lightning meter on hit", 0.0);
				if(chainLightningAttribute){
					char CooldownTime[32]
					Format(CooldownTime, sizeof(CooldownTime), "Chain Lightning: %.0f%", chainLightningAbilityCharge[client]); 
					SetHudTextParams(0.8,0.9, TICKINTERVAL*10, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
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
	currentGameTime = GetGameTime();
	int i = -1;
	while ((i = FindEntityByClassname(i, "*")) != -1)
	{
		if(IsValidEdict(i)){
			if(isProjectileHoming[i])
				OnThinkPost(i);
			
			if(isProjectileBoomerang[i])
				BoomerangThink(i);
			
			if(projectileHomingDegree[i] > 0.0)
				OnHomingThink(i);
			
			if(isEntitySentry[i])
			{
				sentryThought[i] = false;
				SDKCall(g_SDKCallSentryThink, i);
			}

			if(homingRadius[i] > 0.0 && homingDelay[i] < currentGameTime - entitySpawnTime[i])
				OnEntityHomingThink(i);
			
			if(isProjectileFireball[i])
				OnFireballThink(i);

			if(isAimlessProjectile[i])
				OnAimlessThink(i);
		}
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
				int clientMaxHealth = TF2_GetMaxHealth(client);
				stickiesDetonated[client] = 0;
				isDeathTick[client] = false;
				float RegenPerTick = 0.0;

				Address RegenActive = TF2Attrib_GetByName(client, "disguise on backstab");
				if(RegenActive != Address_Null)
					RegenPerTick += TF2Attrib_GetValue(RegenActive)*TICKINTERVAL;

				Address HealingReductionActive = TF2Attrib_GetByName(client, "health from healers reduced");
				if(HealingReductionActive != Address_Null)
					RegenPerTick *= TF2Attrib_GetValue(HealingReductionActive);
				
				Address regenerationPowerup = TF2Attrib_GetByName(client, "regeneration powerup");
				if(regenerationPowerup != Address_Null)
					if(TF2Attrib_GetValue(regenerationPowerup) == 1.0)
						RegenPerTick += TF2_GetMaxHealth(client)*TICKINTERVAL*0.1;//+10% maxHPR/s
					else if(TF2Attrib_GetValue(regenerationPowerup) == 3.0){
						if(bloodAcolyteBloodPool[client] < 3*TF2_GetMaxHealth(client) && GetClientHealth(client) >= TF2_GetMaxHealth(client) * 0.2){
							RegenPerTick -= TF2_GetMaxHealth(client)*TICKINTERVAL*0.08;
							bloodAcolyteBloodPool[client] += TF2_GetMaxHealth(client)*TICKINTERVAL*0.08;
						}
					}

				if(TF2_IsPlayerInCondition(client, TFCond_Plague))
					RegenPerTick *= 0.0;
	
				remainderHealthRegeneration[client] += RegenPerTick;

				if(remainderHealthRegeneration[client] > 1.0){
					int heal = RoundToFloor(remainderHealthRegeneration[client]);
					if(float(clientHealth) + heal < clientMaxHealth)
						SetEntProp(client, Prop_Data, "m_iHealth", clientHealth+heal);
					else if(clientHealth < clientMaxHealth)
						SetEntProp(client, Prop_Data, "m_iHealth", clientMaxHealth);
					
					remainderHealthRegeneration[client] -= heal;
				}
				//drain
				else if(remainderHealthRegeneration[client] < -1.0){
					int heal = RoundToFloor(remainderHealthRegeneration[client]);
					SetEntProp(client, Prop_Data, "m_iHealth", clientHealth+heal);

					remainderHealthRegeneration[client] -= heal;
				}

				if(RageActive[client])
				{
					if(RageBuildup[client] > 0.0)
					{
						RageBuildup[client] -= TICKINTERVAL / 10.0//Revenge lasts 10 seconds (granted they aren't gaining it at the same time)
					}
					else
					{
						RageActive[client] = false;
					}
				}
				if(CurrentSlowTimer[client] <= currentGameTime && CurrentSlowTimer[client] > 0.0)
				{
					TF2Attrib_SetByName(client,"move speed penalty", 1.0);
					TF2Attrib_SetByName(client,"major increased jump height", 1.0);
					CurrentSlowTimer[client] = 0.0;
				}
				//Firerate for Secondaries
				int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				int melee = GetPlayerWeaponSlot(client,2)
				int primary = GetPlayerWeaponSlot(client,0)
				if(IsValidEdict(CWeapon))
				{
					bool flag = true;
					if(IsValidEntity(melee) && CWeapon == melee)
						if(TF2_GetPlayerClass(client) == TFClass_Heavy)
							flag = false;

					if(IsValidEdict(primary) && CWeapon == primary )
						if(TF2_GetPlayerClass(client) == TFClass_Heavy || TF2_GetPlayerClass(client) == TFClass_Sniper)
							flag=false;

					if(GetEntProp(CWeapon, Prop_Data, "m_iClip1") == 0) flag=false;

					if(flag)
					{
						
						float SecondaryROF = 1.0;

						Address Firerate1 = TF2Attrib_GetByName(CWeapon, "fire rate penalty");
						Address Firerate2 = TF2Attrib_GetByName(CWeapon, "fire rate bonus HIDDEN");
						Address Firerate3 = TF2Attrib_GetByName(CWeapon, "fire rate penalty HIDDEN");
						Address Firerate4 = TF2Attrib_GetByName(CWeapon, "fire rate bonus");

						if(Firerate1 != Address_Null)
							SecondaryROF =  SecondaryROF/TF2Attrib_GetValue(Firerate1);
						if(Firerate2 != Address_Null)
							SecondaryROF =  SecondaryROF/TF2Attrib_GetValue(Firerate2);
						if(Firerate3 != Address_Null)
							SecondaryROF =  SecondaryROF/TF2Attrib_GetValue(Firerate3);
						if(Firerate4 != Address_Null)
							SecondaryROF =  SecondaryROF/TF2Attrib_GetValue(Firerate4);

						if(SecondaryROF != 1.0){
							float m_flNextSecondaryAttack = GetEntPropFloat(CWeapon, Prop_Send, "m_flNextSecondaryAttack");
							float SeTime = (m_flNextSecondaryAttack - currentGameTime) - ((SecondaryROF - 1.0) * TICKINTERVAL);
							float FinalS = SeTime+currentGameTime;

							if(FinalS < currentGameTime)
								FinalS = currentGameTime;
							SetEntPropFloat(CWeapon, Prop_Send, "m_flNextSecondaryAttack", FinalS);
						}
						//Remove fire rate bonuses for reload rate on no clip size weapons.
						Address ModClip = TF2Attrib_GetByName(CWeapon, "mod max primary clip override");
						if(ModClip != Address_Null && TF2Attrib_GetValue(ModClip) == -1.0)
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
							float Time = (m_flNextPrimaryAttack - currentGameTime) - ((PrimaryROF - 1.0) * TICKINTERVAL);
							float FinalROF = Time+currentGameTime;
							SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", FinalROF);
							//PrintToChat(client, "%.1f NextPrimaryAttack", FinalROF);
						}
					}
				}
			}

			if(LightningEnchantmentDuration[client] > currentGameTime)
			{
				int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEdict(CWeapon) && CWeapon != 0 && DarkmoonBladeDuration[client] <= 0.0)
				{
					if(weaponTrailTimer[client] < currentGameTime)
					{
						CreateParticle(CWeapon, "utaunt_auroraglow_orange_parent", true, "", 5.0,_,_,1);
						int clients[MAXPLAYERS+1], numClients = getClientParticleStatus(clients, client);
						TE_Send(clients,numClients)
						CreateParticle(client, "utaunt_arcane_yellow_parent", true, "", 5.0);
						
						weaponTrailTimer[client] = currentGameTime+5.1;
					}
				}
			}
			if(DarkmoonBladeDuration[client] > currentGameTime)
			{
				int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				int melee = GetWeapon(client,2);
				if(IsValidEdict(CWeapon) && IsValidEdict(melee) && CWeapon == melee)
				{
					if(weaponTrailTimer[client] < currentGameTime)
					{
						CreateParticle(CWeapon, "utaunt_auroraglow_purple_parent", true, "", 5.0,_,_,1);
						int clients[MAXPLAYERS+1], numClients = getClientParticleStatus(clients, client);
						TE_Send(clients,numClients)
						CreateParticle(client, "utaunt_arcane_purple_parent", true, "", 5.0);
						weaponTrailTimer[client] = currentGameTime+5.1;
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

			if(CheckForAttunement(client))
			{
				for(i = 0; i < Max_Attunement_Slots;++i)
				{
					if(SpellCooldowns[client][i] == 0.0)
						continue;

					if(SpellCooldowns[client][i] > 0.0)
						SpellCooldowns[client][i] -= TICKINTERVAL;
					else
						SpellCooldowns[client][i] = 0.0;
				}
			}
		}
	}
}
public MRESReturn OnBlastExplosion(int entity, Handle hReturn){
	if(!IsValidEntity(entity))
		return MRES_Ignored;

	int owner = getOwner(entity);
	if(!IsValidClient(owner))
		return MRES_Ignored;

	++stickiesDetonated[owner];

	int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
	if(!IsValidWeapon(CWeapon))
		return MRES_Ignored;
	
	float position[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", position);
	position[2] += 15.0;

	float chance = GetAttribute(CWeapon, "sticky recursive explosion chance", 0.0)
	if(chance >= GetRandomFloat(0.0,1.0)){

		DataPack hPack = CreateDataPack();
		hPack.Reset();
		WritePackCell(hPack, EntIndexToEntRef(owner));
		WritePackCell(hPack, EntIndexToEntRef(CWeapon));
		WritePackFloat(hPack, position[0]);
		WritePackFloat(hPack, position[1]);
		WritePackFloat(hPack, position[2]);
		WritePackFloat(hPack, 90.0 * TF2_GetDamageModifiers(owner, CWeapon));
		WritePackFloat(hPack, 120.0 * TF2Attrib_HookValueFloat(1.0, "mult_explosion_radius", CWeapon));
		CreateTimer(0.2, RecursiveExplosions, hPack, TIMER_REPEAT);
	}

	float waspsCount = GetAttribute(CWeapon, "explosion wasps", 0.0)
	if(waspsCount > 0){
		int targetsList[MAXPLAYERS+1];
		float victimPosition[3];
		int index;
		float damage = 40.0 * TF2_GetDamageModifiers(owner, CWeapon);
		for(int i=1;i<=MaxClients;++i){
			if(!IsValidClient3(i))
				continue;
			if(!IsPlayerAlive(i))
				continue;
			if(!IsOnDifferentTeams(owner, i))
				continue;
			
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", victimPosition);
			if(GetVectorDistance(position, victimPosition, true) < 250000){
				targetsList[index] = i;
				index++;
			}
		}
		for(int i=0;i<waspsCount;++i){
			int target = targetsList[GetRandomInt(0,index-1)];
			if(!IsValidClient3(target))
				continue;

			currentDamageType[owner].second |= DMG_IGNOREHOOK;
			SDKHooks_TakeDamage(target, owner, owner, damage,_,_,_,_,false);
			currentDamageType[owner].second |= DMG_IGNOREHOOK;
			SDKHooks_TakeDamage(target, owner, owner, 3.0, DMG_RADIATION+DMG_DISSOLVE,_,_,_,false);

			if(hitParticle[target]+0.2 <= currentGameTime){
				GetEntPropVector(target, Prop_Data, "m_vecOrigin", victimPosition);
				victimPosition[2] += 30.0;
				TE_SetupBeamPoints(position,victimPosition,Laser,Laser,0,5,1.0,1.0,1.0,5,1.0,{247, 136, 0, 150},10);
				TE_SendToAll();
				hitParticle[target] = currentGameTime;
			}
		}
	}

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
	if(HasEntProp(weapon, Prop_Send, "m_flEnergy")){
		if(!GetEntProp(weapon, Prop_Data, "m_bReloadsSingly"))
			SetEntPropFloat(weapon, Prop_Send, "m_flEnergy", 1.0*TF2Util_GetWeaponMaxClip(weapon));
	}
	return MRES_Ignored;
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
	if(!IsValidClient3(client) || !IsValidEdict(client))
		return Plugin_Continue;

	canOverride[client] = true;
	canShootAgain[client] = true;
	int CWeapon = weapon;
	if(IsValidWeapon(CWeapon))
	{
		meleeLimiter[client]++;
		if(getWeaponSlot(client,CWeapon) == 2)
		{
			bool flag = true;
			float ballCheck = GetAttribute(CWeapon, "mod bat launches balls", 0.0);
			if(ballCheck == 0.0)
				ballCheck = GetAttribute(CWeapon, "mod bat launches ornaments", 0.0);

			int a = GetCarriedAmmo(client, 2)
			if(a > 0)
			{
				if(ballCheck == 10.0)
					SDKCall(g_SDKCallLaunchBall, CWeapon);
				flag = false;
			}
			
			if(!IsFakeClient(client) && flag)
			{
				RPS[client] += 0.5;
				Handle hPack = CreateDataPack();
				WritePackCell(hPack, client);
				WritePackFloat(hPack, 0.5);
				CreateTimer(1.0, RemoveFire, hPack);
			}
		}
		else
		{
			if(!IsFakeClient(client)){
				RPS[client] += 1.0;
				Handle hPack = CreateDataPack();
				WritePackCell(hPack, client);
				WritePackFloat(hPack, 1.0);
				CreateTimer(1.0, RemoveFire, hPack);
			}
			char classname[32]; 
			GetEdictClassname(CWeapon, classname, sizeof(classname)); 

			if(StrEqual(classname, "tf_weapon_cleaver"))
			{
				if(weaponFireRate[CWeapon] > 5.0)
				{
					Address override = TF2Attrib_GetByName(CWeapon, "override projectile type");
					if(override == Address_Null)
						SDKCall(g_SDKCallJar, CWeapon);
				}
			}
		}
		float fAngles[3], fVelocity[3], fOrigin[3], vBuffer[3];
		Address bossType = TF2Attrib_GetByName(client, "damage force increase text");
		if(bossType != Address_Null && TF2Attrib_GetValue(bossType) > 0.0)
		{
			float bossValue = TF2Attrib_GetValue(bossType);
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
								Address projspeed = TF2Attrib_GetByName(CWeapon, "Projectile speed increased");
								Address projspeed1 = TF2Attrib_GetByName(CWeapon, "Projectile speed decreased");
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
									SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
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
		}
		Address tracer = TF2Attrib_GetByName(CWeapon, "sniper fires tracer");
		if(LastCharge[client] >= 150.0 && tracer != Address_Null && TF2Attrib_GetValue(tracer) == 1.0)
		{
			TF2Attrib_SetByName(CWeapon, "sniper fires tracer", 0.0);
		}
		
		Address projActive = TF2Attrib_GetByName(CWeapon, "sapper damage penalty hidden");
		Address override = TF2Attrib_GetByName(CWeapon, "override projectile type");
		if(override != Address_Null)
		{
			float projnum = TF2Attrib_GetValue(override);
			switch(projnum)
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
						
						
						SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
						SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
									
						GetClientEyePosition(client, fOrigin);
						fAngles = fEyeAngles[client];
						
						GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
						float Speed = 2000.0;
						Address projspeed = TF2Attrib_GetByName(CWeapon, "Projectile speed increased");
						if(projspeed != Address_Null)
						{
							Speed *= TF2Attrib_GetValue(projspeed);
						}
						fVelocity[0] = vBuffer[0]*Speed;
						fVelocity[1] = vBuffer[1]*Speed;
						fVelocity[2] = vBuffer[2]*Speed;
						
						float ProjectileDamage = 90.0;
						
						Address DMGVSPlayer = TF2Attrib_GetByName(CWeapon, "dmg penalty vs players");
						Address DamagePenalty = TF2Attrib_GetByName(CWeapon, "damage penalty");
						Address DamageBonus = TF2Attrib_GetByName(CWeapon, "damage bonus");
						Address DamageBonusHidden = TF2Attrib_GetByName(CWeapon, "damage bonus HIDDEN");
						Address BulletsPerShot = TF2Attrib_GetByName(CWeapon, "bullets per shot bonus");
						Address AccuracyScales = TF2Attrib_GetByName(CWeapon, "accuracy scales damage");
						Address damageActive = TF2Attrib_GetByName(CWeapon, "ubercharge");
						
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
							Address projspeed = TF2Attrib_GetByName(CWeapon, "Projectile speed increased");
							Address projspeed1 = TF2Attrib_GetByName(CWeapon, "Projectile speed decreased");
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
								SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
							}
							SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
							SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008);
							SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
							SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 13); 
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

						SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
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
						GetClientEyePosition(client, fOrigin);
						GetClientEyeAngles(client, fAngles);
						GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
						GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(fwd, 20.0);
						AddVectors(fOrigin, fwd, fOrigin);
						float velocity = 2000.0;
						Address projspeed = TF2Attrib_GetByName(CWeapon, "Projectile speed increased");
						Address projspeed1 = TF2Attrib_GetByName(CWeapon, "Projectile speed decreased");
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
							SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
						}
						SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
						SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchPiercingRocket);
						SetEntityModel(iEntity, "models/weapons/w_models/w_rocket_airstrike/w_rocket_airstrike.mdl");
						CreateTimer(3.0, SelfDestruct, EntIndexToEntRef(iEntity));
						SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 25.0 * TF2_GetDamageModifiers(client,CWeapon), true);  
					}
				}
				case 43.0:
				{
					int iEntity = CreateEntityByName("tf_projectile_spellfireball");
					if (IsValidEdict(iEntity)) 
					{
						int iTeam = GetClientTeam(client);
						float fwd[3]
						SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
						SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
						GetClientEyeAngles(client, fAngles);
						GetClientEyePosition(client, fOrigin);

						GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(fwd, 30.0);
						
						AddVectors(fOrigin, fwd, fOrigin);
						GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
						
						float velocity = 900.0;
						fVelocity[0] = vBuffer[0]*velocity;
						fVelocity[1] = vBuffer[1]*velocity;
						fVelocity[2] = 150.0 + vBuffer[2]*velocity;
						
						TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
						DispatchSpawn(iEntity);
						SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchChaos);
						setProjGravity(iEntity, 0.4);
						CreateTimer(10.0,SelfDestruct,EntIndexToEntRef(iEntity));
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
						GetClientEyePosition(client, fOrigin);
						GetClientEyeAngles(client, fAngles);
						GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
						GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(fwd, 30.0);
						AddVectors(fOrigin, fwd, fOrigin);
						float velocity = 20000.0;
						Address projspeed = TF2Attrib_GetByName(CWeapon, "Projectile speed increased");
						Address projspeed1 = TF2Attrib_GetByName(CWeapon, "Projectile speed decreased");
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
							SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
						}
						SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
						SetEntProp(iEntity, Prop_Data, "m_bIsLive", true);
						//PrintToServer("%.2f", TF2_GetWeaponFireRate(CWeapon));
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
						
						float velocity = 700.0;
						velocity *= GetAttribute(CWeapon, "Projectile speed increased");
						velocity *= GetAttribute(CWeapon, "Projectile speed decreased");
						ScaleVector(vBuffer,velocity);
					
						DispatchSpawn(iEntity);
						TeleportEntity(iEntity, fOrigin, fAngles, vBuffer);

						SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
						SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
						CreateTimer(0.1, ElectricBallThink, EntIndexToEntRef(iEntity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				case 48.0:
				{
					if(maelstromChargeCount[client] < 50)
						maelstromChargeCount[client]++;
				}
			}
		}
		if(projActive != Address_Null && TF2Attrib_GetValue(projActive) == 2.0)
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
					
					SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
					DispatchSpawn(iEntity);

					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
					SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", CWeapon);
					GetClientEyePosition(client, fOrigin);
					fAngles = fEyeAngles[client];
					
					GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					float Speed = 2000.0;
					fVelocity[0] = vBuffer[0]*Speed;
					fVelocity[1] = vBuffer[1]*Speed;
					fVelocity[2] = vBuffer[2]*Speed;
					SetEntPropVector( iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
					float ProjectileDamage = 100.0 * GetAttribute(CWeapon, "bullets per shot bonus", 1.0);
					
					SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, ProjectileDamage, true);  
					TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
				}
				ShotsLeft[client] = 25;
			}
			else
			{
				ShotsLeft[client]--;
			}
		}
	}
	return Plugin_Continue;
}
public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
		SavePlayerData(client);
	
	DamageDealt[client] = 0.0;
	Kills[client] = 0;
	Deaths[client] = 0;
	dps[client] = 0.0;
	Healed[client] = 0.0;
	current_class[client] = TFClass_Unknown;
	fl_MaxFocus[client] = 100.0;
	fl_CurrentFocus[client] = 100.0;
	BleedBuildup[client] = 0.0;
	RadiationBuildup[client] = 0.0;
	RageActive[client] = false;
	RageBuildup[client] = 0.0;
	SupernovaBuildup[client] = 0.0;
	ConcussionBuildup[client] = 0.0;
	FreezeBuildup[client] = 0.0;
	fl_HighestFireDamage[client] = 0.0;
	isBuffActive[client] = false;
	canBypassRestriction[client] = false;
	clearAllBuffs(client);
	if(snowstormActive[client]){
		int particleEffect = EntRefToEntIndex(snowstormParticle[client]);
		if(IsValidEntity(particleEffect)){
			SetVariantString("ParticleEffectStop");
			AcceptEntityInput(particleEffect, "DispatchEffect");
			RemoveEdict(particleEffect);
		}
		snowstormActive[client] = false;
	}

	int i;
	for(i = 0; i < Max_Attunement_Slots; ++i)
	{
		AttunedSpells[client][i] = 0.0;
	}
	for(i = 1;i<=MaxClients;++i){
		isTagged[i][client] = false;
	}
	if(b_Hooked[client])
	{
		b_Hooked[client] = false;
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		SDKUnhook(client, SDKHook_StartTouch, OnStartTouchStomp);
		SDKUnhook(client, SDKHook_WeaponSwitch, WeaponSwitch);
	}
}
public OnClientPutInServer(client)
{
	fl_MaxFocus[client] = 100.0;
	fl_CurrentFocus[client] = 100.0;
	BleedMaximum[client] = 100.0;
	RadiationMaximum[client] = 400.0;
	fl_HighestFireDamage[client] = 0.0;
	isBuffActive[client] = false;
	canBypassRestriction[client] = false;
	for(int i = 0; i < Max_Attunement_Slots; ++i)
	{
		AttunedSpells[client][i] = 0.0;
	}
	
	if(!b_Hooked[client])
	{
		b_Hooked[client] = true;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		SDKHook(client, SDKHook_StartTouch, OnStartTouchStomp);
		SDKHook(client, SDKHook_WeaponSwitch, WeaponSwitch);
	}
	ClientCommand(client, "sm_showhelp");
}
public OnClientPostAdminCheck(client)
{
	if(IsValidClient(client))
	{
		char clname[255]
		GetClientName(client, clname, sizeof(clname))
		client_no_d_team_upgrade[client] = 1
		if (!client_respawn_handled[client])
		{
			CreateTimer(0.0, ClChangeClassTimer, GetClientUserId(client));
		}
		GivePlayerData(client);

		if(AreClientCookiesCached(client))
		{
			char knockbackToggleEnabled[64];
			GetClientCookie(client, knockbackToggle, knockbackToggleEnabled, sizeof(knockbackToggleEnabled));
			if(StrEqual(knockbackToggleEnabled, "\0"))
				{knockbackFlags[client] = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4);
				IntToString(knockbackFlags[client],knockbackToggleEnabled,sizeof(knockbackToggleEnabled));SetClientCookie(client, knockbackToggle,knockbackToggleEnabled);}

			knockbackFlags[client] = StringToInt(knockbackToggleEnabled);
		}
	}
}
public Event_PlayerRespawn(Handle event, const char[] name, bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	bossPhase[client] = 0;
	RespawnEffect(client);
	currentDamageType[client].clear();
	if(IsValidClient3(client)){

		if(!IsFakeClient(client)){
			CancelClientMenu(client);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
			client_respawn_handled[client] = 1;

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

		SetEntityRenderColor(client, 255, 255, 255, 255);
		TF2_RemoveCondition(client,TFCond_Plague);
		BleedBuildup[client] = 0.0;
		RadiationBuildup[client] = 0.0;
		RageActive[client] = false;
		SupernovaBuildup[client] = 0.0;
		ConcussionBuildup[client] = 0.0;
		FreezeBuildup[client] = 0.0;
		fl_HighestFireDamage[client] = 0.0;
		miniCritStatusAttacker[client] = 0.0;
		miniCritStatusVictim[client] = 0.0;
		CurrentSlowTimer[client] = 0.0;
		canShootAgain[client] = true;
		meleeLimiter[client] = 0;
		//lastDamageTaken[client] = 0.0;
		critStatus[client] = false;
		bloodAcolyteBloodPool[client] = 0.0;
		duplicationCooldown[client] = 0.0;
		warpCooldown[client] = 0.0;
		frayNextTime[client] = 0.0;
		strongholdEnabled[client] = false;
		bloodboundDamage[client] = 0.0;
		bloodboundHealing[client] = 0.0;
		pylonCharge[client] = 0.0;
		tagTeamTarget[client] = -1;
		immolationActive[client] = false;
		sunstarDuration[client] = 0.0;
		for(int i=1;i<=MaxClients;++i)
		{
			corrosiveDOT[client][i][0] = 0.0;
			corrosiveDOT[client][i][1] = 0.0;
			if(i == tagTeamTarget[client])
				tagTeamTarget[client] = -1;
		}
		if(snowstormActive[client]){
			int particleEffect = EntRefToEntIndex(snowstormParticle[client]);
			if(IsValidEntity(particleEffect)){
				SetVariantString("ParticleEffectStop");
				AcceptEntityInput(particleEffect, "DispatchEffect");
				RemoveEdict(particleEffect);
			}
			snowstormActive[client] = false;
		}

	}
	if(IsFakeClient(client)){
		if(IsMvM()){
			BotTimer[client] = 45.0;
			if(IsValidForDamage(TankTeleporter) && !GetEntProp(TankTeleporter, Prop_Send, "m_bDisabled")){
				char classname[128]; 
				GetEdictClassname(TankTeleporter, classname, sizeof(classname)); 
				if(!strcmp("tank_boss", classname)){
					float telePos[3];
					GetEntPropVector(TankTeleporter,Prop_Send, "m_vecOrigin",telePos);
					telePos[2]+= 220.0;
					TeleportEntity(client, telePos, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
		else{
			CreateTimer(0.4, GiveBotUpgrades, GetClientUserId(client));
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
			if (!client_respawn_handled[client])
			{
				CreateTimer(0.1, ClChangeClassTimer, GetClientUserId(client));
			}
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
				AttunedSpells[client][i] = 0.0;
			}
		}
		RespawnEffect(client);
	}
	if(!IsMvM() && IsFakeClient(client))
	{
		CreateTimer(0.4, GiveBotUpgrades, GetClientUserId(client));
	}
}
public Event_Teleported(Handle event, const char[] name, bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int owner = GetClientOfUserId(GetEventInt(event, "builderid"));
	if(IsValidClient3(client) && IsValidClient3(owner))
	{
		int melee = (GetPlayerWeaponSlot(owner,2));
		if(IsValidEdict(melee))
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
				
				float LightningDamage = 325.0 * TF2_GetSentryDPSModifiers(client, melee);
				
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
								currentDamageType[client].second |= DMG_IGNOREHOOK;
								SDKHooks_TakeDamage(i, client, client, LightningDamage, DMG_GENERIC, _,_,_,false);
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
			Address teleportBuffActive = TF2Attrib_GetByName(melee, "zoom speed mod disabled");
			if(teleportBuffActive != Address_Null && TF2Attrib_GetValue(teleportBuffActive) != 0.0)
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
	if (IsValidClient(client) && !TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		if (itemLevel == 242)
		{
			int slot = 3
			current_class[client] = TF2_GetPlayerClass(client)
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
			int slot = TF2Econ_GetItemLoadoutSlot(itemDefinitionIndex, TF2_GetPlayerClass(client));
			if (current_class[client] == TFClass_Spy)
			{
				if (!strcmp(classname, "tf_weapon_pda_spy"))
				{
					current_class[client] = TF2_GetPlayerClass(client)
					currentitem_classname[client][1] = "tf_weapon_pda_spy"
					currentitem_ent_idx[client][1] = entityIndex
					DefineAttributesTab(client, 735, 1, entityIndex)
					currentitem_catidx[client][1] = GetUpgrade_CatList("tf_weapon_pda_spy")
					GiveNewUpgradedWeapon_(client, 1)
				}
			}
			currentitem_catidx[client][4] = _:TF2_GetPlayerClass(client) - 1;
			if (slot != 3 && slot <= NB_SLOTS_UED)
			{
				if (!strcmp(classname, "tf_weapon_revolver"))
					slot =0;
				
				GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
				currentitem_ent_idx[client][slot] = entityIndex
				current_class[client] = TF2_GetPlayerClass(client)
				DefineAttributesTab(client, itemDefinitionIndex, slot, entityIndex)
				currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
				
				switch(current_class[client])
				{
					case (TFClass_Scout):
					{
						if (!strcmp(classname, "tf_weapon_scattergun"))
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_scattergun_")
						}
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
						}
					}
					case (TFClass_Soldier):
					{
						if (!strcmp(classname, "tf_weapon_shotgun"))
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_shotgun_soldier")
						}				
						else if (!strcmp(classname, "tf_weapon_grenadelauncher"))
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_libertylauncher")
						}	
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
						}					
					}
					case (TFClass_Pyro):
					{
						if (!strcmp(classname, "tf_weapon_flaregun"))
						{
							if (itemDefinitionIndex == 39 || itemDefinitionIndex == 1081)
							{
								currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_flaregun")
							}
							else if (itemDefinitionIndex == 351 || itemDefinitionIndex == 740	)
							{
								currentitem_catidx[client][slot] = GetUpgrade_CatList("detonator")
							}
							else
							{
								currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
							}
						}
						else if (!strcmp(classname, "tf_weapon_shotgun") || !strcmp(classname, "tf_weapon_shotgun_pyro"))
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_shotgun_pyro")
						}
						else if(!strcmp(classname, "tf_weapon_flamethrower") && itemDefinitionIndex == 594)
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("pyroweapp")
						}
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
						}
					}
					case (TFClass_DemoMan):
					{
						if (!strcmp(classname, "tf_wearable") && 
						(itemDefinitionIndex == 405 || itemDefinitionIndex == 608))
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_wear_alishoes")
						}		
						else if (!strcmp(classname, "tf_weapon_grenadelauncher") && itemDefinitionIndex == 1151)
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_iron_bomber")
						}
						else if (!strcmp(classname, "tf_weapon_pipebomblauncher") && itemDefinitionIndex == 1150)
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_quickiebomb")
						}
						else if (!strcmp(classname, "tf_weapon_cannon"))
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_libertylauncher")
						}
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
						}					
					}
					case (TFClass_Heavy):
					{
						if (!strcmp(classname, "tf_weapon_minigun") && (itemDefinitionIndex == 312 || itemDefinitionIndex == 811))
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("brassBeast")
						}
						else if (!strcmp(classname, "tf_weapon_shotgun"))
						{
							currentitem_catidx[client][1] = GetUpgrade_CatList("tf_weapon_shotgun_hwg")
						}
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
						}	
					}
					case (TFClass_Engineer):
					{
						if (!strcmp(classname, "tf_weapon_shotgun") && currentitem_level[client][slot] != 242)
						{
							currentitem_catidx[client][0] = GetUpgrade_CatList("tf_weapon_shotgun_primary")
						}
						else if (!strcmp(classname, "tf_weapon_shotgun_primary") && itemDefinitionIndex == 527)
						{
							currentitem_catidx[client][0] = GetUpgrade_CatList("tf_weapon_shotgun_primary_")
						}
						else if (!strcmp(classname, "saxxy"))
						{
							currentitem_catidx[client][2] = GetUpgrade_CatList("tf_weapon_wrench")
						}
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
						}
					}
					case (TFClass_Sniper):
					{
						if(!strcmp(classname, "tf_weapon_grenadelauncher"))
						{
							currentitem_catidx[client][0] = GetUpgrade_CatList("autofirebow")
						}
						else if(itemDefinitionIndex == 752)
						{
							currentitem_catidx[client][0] = GetUpgrade_CatList("hitmans")
						}
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
						}
					}
					case (TFClass_Medic):
					{
						if (!strcmp(classname, "tf_weapon_medigun") && itemDefinitionIndex == 998)
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("vaccinator")
						}
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList(classname)
						}
					}
					case (TFClass_Spy)://filler
					{
					}
				}
				GiveNewUpgradedWeapon_(client, slot);
			}
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
	lastSentryFiring[sentry] = currentGameTime;

	if(IsValidClient3(builder)){
		int melee = GetWeapon(builder, 2);
		if(IsValidWeapon(melee)){
			float override = GetAttribute(melee, "override projectile type", 0.0);
			switch (override){
				case 33.0:{
					if(firestormCounter[builder] == 4)
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
							//why does it hit twice??? also, minisentries deal 25% dmg.
							projectileDamage[iEntity] = 40.0*TF2_GetSentryDamageModifiers(attacker, melee);
							if(GetEntProp(sentry, Prop_Send, "m_bMiniBuilding"))
								projectileDamage[iEntity] *= 0.25;
						}
						firestormCounter[builder] = 0;
					}
					firestormCounter[builder]++
					return Plugin_Stop;
				}
				case 34.0:{
					char projName[32] = "tf_projectile_arrow";
					int iEntity = CreateEntityByName(projName);
					if (IsValidEdict(iEntity)) 
					{
						projectileDamage[iEntity] = 35.0 * TF2_GetSentryDamageModifiers(builder, melee);
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
						CreateSpriteTrail(iEntity, "0.33", "5.0", "1.0", iTeam == 2 ? "materials/effects/arrowtrail_red.vmt":"materials/effects/arrowtrail_blu.vmt", "255 255 255");
					}
					return Plugin_Stop;
				}
			}
			
			shots = RoundToCeil(GetAttribute(melee, "sentry bullets per shot", 1.0) * shots);
			if(shots > 1){//Each bullets per shot increases spread by +50%.
				ScaleVector(spread, 1+float(shots-1)/2.0);
			}

			if(GetAttribute(builder, "precision powerup", 0.0) == 1){//Precision removes sentry spread.
				ScaleVector(spread, 0.0);
			}
		}
	}

	return Plugin_Changed;
}