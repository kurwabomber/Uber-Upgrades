public Event_Playerhurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	new Float:damage = GetEventFloat(event, "damageamount");	
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
	if(attacker != client && IsValidClient(attacker)){
		DamageDealt[attacker] += damage;
		dps[attacker] += damage;
		if(damage > 32767)
		{
			SetEventInt(event, "damageamount", 0);
			PrintCenterText(attacker, "OVERLOAD DMG | %s |", GetAlphabetForm(damage));
		}
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, EntIndexToEntRef(attacker));
		WritePackFloat(hPack, damage);
		CreateTimer(1.01, RemoveDamage, hPack);

		new Address:knockoutPowerup = TF2Attrib_GetByName(attacker, "taunt is press and hold");
		if(knockoutPowerup != Address_Null)
		{
			new Float:knockoutPowerupValue = TF2Attrib_GetValue(knockoutPowerup);
			if(knockoutPowerupValue > 0.0){
				new CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(CWeapon))
				{
					if(getWeaponSlot(client,CWeapon) == 2)
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
	new Float:armorLoss = damage/fl_ArmorRes[client];
	if(IsValidClient3(attacker))
	{
		if(TF2_IsPlayerInCondition(attacker, TFCond_CritCanteen))
			armorLoss *= 1.4;
	}
	if(IsValidClient3(client))
	{
		new Address:revengePowerup = TF2Attrib_GetByName(client, "sniper penetrate players when charged");
		if(revengePowerup != Address_Null)
		{
			new Float:revengePowerupValue = TF2Attrib_GetValue(revengePowerup);
			if(revengePowerupValue > 0.0)
			{
				RageBuildup[client] += (damage/float(TF2_GetMaxHealth(client)))*0.667;
				if(RageBuildup[client] > 1.0)
					RageBuildup[client]= 1.0;
			}
		}
		new Address:supernovaPowerupVictim = TF2Attrib_GetByName(client, "spawn with physics toy");
		if(supernovaPowerupVictim != Address_Null && TF2Attrib_GetValue(supernovaPowerupVictim) > 0.0)
		{
			SupernovaBuildup[client] += (damage/float(TF2_GetMaxHealth(client)));
			if(SupernovaBuildup[client] > 1.0)
				SupernovaBuildup[client] = 1.0;
		}
	}
	if(fl_AdditionalArmor[client] > 0.0)
	{
		fl_AdditionalArmor[client] -= armorLoss;
		if(fl_AdditionalArmor[client] < 0.0)
		{
			fl_AdditionalArmor[client] = 0.0;
		}
	}
	else
	{
		fl_CurrentArmor[client] -= armorLoss;
		if(fl_CurrentArmor[client] < 0.0)
		{
			fl_CurrentArmor[client] = 0.0;
		}
	}
	
	if(IsValidClient3(attacker) && !IsFakeClient(attacker))
	{
		/*if(client != attacker && attacker != 0 && damage >= 1.0)
		{
			PrintToConsole(attacker, "%.1f post damage dealt.", damage);
		}*/

		if(IsValidClient3(attacker) && damage > 0.0 && attacker != client && IsValidClient3(client))
		{
			new CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(CWeapon))
			{
				new Float:lifestealFactor = 1.0;
				new Float:maximumOverheal = 1.5;
				if(IsFakeClient(client))
					lifestealFactor = 0.3;
				
				new Address:maximumOverhealModifier = TF2Attrib_GetByName(attacker, "patient overheal penalty");
				if(maximumOverhealModifier != Address_Null)
				{
					maximumOverheal *= TF2Attrib_GetValue(maximumOverhealModifier);
				}
				
				new Address:LifestealActive = TF2Attrib_GetByName(CWeapon, "bot medic uber health threshold");//Lifesteal attribute
				if(LifestealActive != Address_Null)
				{
					new HealthGained = RoundToCeil(0.1 * damage * TF2Attrib_GetValue(LifestealActive) * lifestealFactor);
					AddPlayerHealth(attacker, HealthGained, maximumOverheal, true, attacker);
					fl_CurrentArmor[attacker] += float(HealthGained) * 0.2;
				}
				
				new Address:vampirePowerup = TF2Attrib_GetByName(attacker, "unlimited quantity");//Vampire Powerup
				if(vampirePowerup != Address_Null && TF2Attrib_GetValue(vampirePowerup) > 0.0)
				{
					new HealthGained = RoundToCeil(0.8 * damage * lifestealFactor);
					AddPlayerHealth(attacker, HealthGained, maximumOverheal*2.0, true, attacker);
					fl_CurrentArmor[attacker] += float(HealthGained);
				}
				
				if(TF2_IsPlayerInCondition(attacker, TFCond_MedigunDebuff))// Conch
				{
					new HealthGained = RoundToCeil(damage * 0.15 * lifestealFactor);
					AddPlayerHealth(attacker, HealthGained, maximumOverheal, true, attacker);
					fl_CurrentArmor[attacker] += float(HealthGained) * 0.2;
				}
				if(GetEventInt(event, "custom") == 2)//backstab
				{
					new Address:BackstabLifestealActive = TF2Attrib_GetByName(CWeapon, "sanguisuge"); //Kunai
					if(BackstabLifestealActive != Address_Null && TF2Attrib_GetValue(BackstabLifestealActive) > 0.0)
					{
						new HealthGained = RoundToCeil(damage * 0.5 * TF2Attrib_GetValue(BackstabLifestealActive));
						AddPlayerHealth(attacker, HealthGained, maximumOverheal*1.5, true, attacker);
						fl_CurrentArmor[attacker] += float(HealthGained) * 0.2;
					}
				}
				if(MadmilkDuration[client] > 0.0)
				{
					new HealthGained = RoundToCeil(lifestealFactor * damage * MadmilkDuration[client] * 1.66 / 100.0);
					AddPlayerHealth(attacker, HealthGained, maximumOverheal, true, attacker);
					fl_CurrentArmor[attacker] += float(HealthGained) * 0.2;
				}
			}
		}
	}
	if(IsValidClient3(attacker) && IsFakeClient(attacker))
	{
		if(IsValidClient3(attacker) && damage > 0.0 && attacker != client && IsValidClient3(client))
		{
			new CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(CWeapon))
			{
				new Address:LifestealActive = TF2Attrib_GetByName(CWeapon, "bot medic uber health threshold");
				if(LifestealActive != Address_Null)
				{
					new HealthGained = RoundToCeil(1.25 * damage * TF2Attrib_GetValue(LifestealActive));
					AddPlayerHealth(attacker, HealthGained, 1.5, true, attacker);
				}
				if(TF2_IsPlayerInCondition(attacker, TFCond_MedigunDebuff))
				{
					new HealthGained = RoundToCeil(damage * 0.5)
					AddPlayerHealth(attacker, HealthGained, 1.5, true, attacker);
				}
			}
		}
	}
}
public MRESReturn OnModifyRagePre(Address pPlayerShared, Handle hParams) {
	int client = GetEntityFromAddress((DereferencePointer(pPlayerShared + g_offset_CTFPlayerShared_pOuter)));
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
public MRESReturn OnCondApply(Address pPlayerShared, Handle hParams) {
	int client = GetEntityFromAddress((DereferencePointer(pPlayerShared + g_offset_CTFPlayerShared_pOuter)));
	float duration = DHookGetParam(hParams, 2);
	TFCond cond = view_as<TFCond>(DHookGetParam(hParams, 1));
	if(IsValidClient3(client))
	{
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
				new Address:attribute1 = TF2Attrib_GetByName(client, "absorb damage while cloaked");
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
				new Address:attribute2 = TF2Attrib_GetByName(client, "always_transmit_so");
				if (attribute2 != Address_Null) 
				{
					if(GetRandomFloat(0.0,1.0) <= TF2Attrib_GetValue(attribute2))
					{
						return MRES_Supercede;
					}
				}
				TF2Attrib_SetByName(client, "health from healers reduced", 0.5);
			}
			case TFCond_Slowed:
			{
				new Address:slowResistance = TF2Attrib_GetByName(client, "slow resistance");
				if(slowResistance != Address_Null)
				{
					DHookSetParam(hParams, 2, duration * TF2Attrib_GetValue(slowResistance));
					return MRES_Override;
				}
			}
			case TFCond_Bonked:
			{
				TF2_AddCondition(client, TFCond_SpeedBuffAlly, 8.0);
				TF2_AddCondition(client, TFCond_HalloweenQuickHeal, 8.0);
				return MRES_Supercede;
			}
			case TFCond_Taunting:
			{
				new Address:TauntSpeedActive = TF2Attrib_GetByName(client, "gesture speed increase");
				if(TauntSpeedActive != Address_Null)
				{
					SetTauntAttackSpeed(client, TF2Attrib_GetValue(TauntSpeedActive));
				}
				new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new String:classname[64];
					GetEdictClassname(CWeapon, classname, sizeof(classname)); 
					if(StrContains(classname, "tf_weapon_lunchbox",false) == 0)
					{//Hook onto all sandvich stuff or something to that effect
						new Address:ArmorGain = TF2Attrib_GetByName(CWeapon, "squad surplus claimer id DEPRECATED");
						new Address:ArmorRegen = TF2Attrib_GetByName(CWeapon, "mvm completed challenges bitmask");
						new Address:ShieldingActive = TF2Attrib_GetByName(CWeapon, "energy weapon charged shot");
						if(ArmorGain != Address_Null)
						{
							fl_CurrentArmor[client] += TF2Attrib_GetValue(ArmorGain)
							if(fl_CurrentArmor[client] > fl_MaxArmor[client])
							{
								fl_CurrentArmor[client] = fl_MaxArmor[client]
							}
						}
						if(ArmorRegen != Address_Null)
						{
							fl_ArmorRegenBonus[client] = TF2Attrib_GetValue(ArmorRegen)
							fl_ArmorRegenBonusDuration[client] = 4.0
						}
						else
						{
							fl_ArmorRegenBonus[client] = 1.0
						}
						if(ShieldingActive != Address_Null)
						{
							if(fl_AdditionalArmor[client] < TF2Attrib_GetValue(ShieldingActive))
							{
								fl_AdditionalArmor[client] = TF2Attrib_GetValue(ShieldingActive)
							}
						}
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
			case TFCond_Buffed:
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
			case TFCond_Jarated:
			{
				miniCritStatusVictim[client] = duration;
				return MRES_Supercede;
			}
			case TFCond_MarkedForDeath:
			{
				miniCritStatusVictim[client] = duration;
				return MRES_Supercede;
			}
			case TFCond_MarkedForDeathSilent:
			{
				miniCritStatusVictim[client] = duration;
				return MRES_Supercede;
			}
			case TFCond_MiniCritOnKill:
			{
				miniCritStatusAttacker[client] = duration;
				return MRES_Supercede;
			}
			case TFCond_CritCola:
			{
				miniCritStatusAttacker[client] = duration;
				return MRES_Supercede;
			}
			case TFCond_NoHealingDamageBuff:
			{
				miniCritStatusAttacker[client] = duration;
				return MRES_Supercede;
			}
			case TFCond_Sapped:
			{
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
			}
			case TFCond_Ubercharged:
			{
				if(TF2_IsPlayerInCondition(client, TFCond_Sapped))
					return MRES_Supercede;
			}
			case TFCond_Cloaked:
			{
				if(TF2_IsPlayerInCondition(client, TFCond_Sapped))
					return MRES_Supercede;
			}
			case TFCond_Disguised:
			{
				if(TF2_IsPlayerInCondition(client, TFCond_Sapped))
					return MRES_Supercede;
			}
			case TFCond_MegaHeal:
			{
				if(TF2_IsPlayerInCondition(client, TFCond_Sapped))
					return MRES_Supercede;
			}
			case TFCond_DefenseBuffNoCritBlock:
			{
				if(TF2_IsPlayerInCondition(client, TFCond_Sapped))
					return MRES_Supercede;
			}
			case TFCond_DefenseBuffMmmph:
			{
				if(TF2_IsPlayerInCondition(client, TFCond_Sapped))
					return MRES_Supercede;
			}
			case TFCond_UberchargedHidden:
			{
				if(TF2_IsPlayerInCondition(client, TFCond_Sapped))
					return MRES_Supercede;
			}
			case TFCond_UberBulletResist:
			{
				if(TF2_IsPlayerInCondition(client, TFCond_Sapped))
					return MRES_Supercede;
			}
			case TFCond_UberBlastResist:
			{
				if(TF2_IsPlayerInCondition(client, TFCond_Sapped))
					return MRES_Supercede;
			}
			case TFCond_UberFireResist:
			{
				if(TF2_IsPlayerInCondition(client, TFCond_Sapped))
					return MRES_Supercede;
			}
			case TFCond_AfterburnImmune:
			{
				if(TF2_IsPlayerInCondition(client, TFCond_Sapped))
					return MRES_Supercede;
			}
		}
	}
	return MRES_Ignored;
}
public MRESReturn OnCalculateBotSpeedPost(int client, Handle hReturn) {
	DHookSetReturn(hReturn, 3000.0);
	return MRES_Supercede;
}
public MRESReturn OnSentryThink(int entity)  {
	if(IsValidEntity(entity))
	{
		if(sentryThought[entity] == false)
		{
			sentryThought[entity] = true;
			return MRES_Ignored;
		}
	}
	return MRES_Supercede;
}
public MRESReturn IsInWorldCheck(int entity, Handle hReturn, Handle hParams)  {
	if(IsValidEntity(entity))
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
public MRESReturn OnRecoilApplied(int entity, Handle hParams)  {
	DHookSetParamVector(hParams, 1, NULL_VECTOR);
	return MRES_ChangedHandled;
}
public MRESReturn OnFireRateCall(int entity, Handle hReturn, Handle hParams)  {
	if(IsValidWeapon(entity))
	{
		new Float:rate = DHookGetReturn(hReturn);

		//If their weapon doesn't have a clip, reload rate also affects fire rate.
		if(HasEntProp(entity, Prop_Data, "m_iClip1") && GetEntProp(entity,Prop_Data,"m_iClip1")  == -1)
		{
			new Address:ModClip = TF2Attrib_GetByName(entity, "mod max primary clip override");
			if(ModClip == Address_Null)
			{
				new Address:apsMult12 = TF2Attrib_GetByName(entity, "faster reload rate");
				new Address:apsMult13 = TF2Attrib_GetByName(entity, "Reload time increased");
				new Address:apsMult14 = TF2Attrib_GetByName(entity, "Reload time decreased");
				new Address:apsMult15 = TF2Attrib_GetByName(entity, "reload time increased hidden");
				
				if(apsMult12 != Address_Null) {
				rate *= TF2Attrib_GetValue(apsMult12);
				}
				if(apsMult13 != Address_Null) {
				rate *= TF2Attrib_GetValue(apsMult13);
				}
				if(apsMult14 != Address_Null) {
				rate *= TF2Attrib_GetValue(apsMult14);
				}
				if(apsMult15 != Address_Null) {
				rate *= TF2Attrib_GetValue(apsMult15);
				}
			}
		}
		weaponFireRate[entity] = 1.0/rate;
	}
	return MRES_Ignored;
}
public MRESReturn OnBotJumpLogic(int entity, Handle hReturn, Handle hParams)  {
	return MRES_Supercede;
}
public Event_PlayerHealed(Handle:event, const String:name[], bool:dontBroadcast)
{
	//new client = GetClientOfUserId(GetEventInt(event, "patient"));
	new healer = GetClientOfUserId(GetEventInt(event, "healer"));
	new amount = GetEventInt(event, "amount");
	
	Healed[healer] += float(amount);
}
public TF2Spawn_EnterSpawn(int client, int spawn)
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		new melee = GetWeapon(client,2);
		if(IsValidEntity(melee))
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
		new melee = GetWeapon(client,2);
		if(IsValidEntity(melee))
		{
			TF2Attrib_SetByName(melee,"airblast vulnerability multiplier hidden", 1.0);
			TF2Attrib_SetByName(melee,"damage force increase hidden", 1.0);
		}
	}
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
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
}
public void TF2_OnConditionRemoved(client, TFCond:cond)
{
	if(cond == TFCond_Bleeding)
	{
		TF2Attrib_SetByName(client, "health from healers reduced", 1.0);
	}
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
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
}
public OnEntityCreated(entity, const char[] classname)
{
	if(!IsValidEntity(entity) || entity < 0 || entity > 2048)
		return;


	weaponFireRate[entity] = -1.0;
	if(StrEqual(classname, "obj_attachment_sapper"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Sapper); 
	}
	else if(StrEqual(classname, "obj_sentrygun"))
    {
		isEntitySentry[entity] = true;
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Sentry); 
		CreateTimer(0.35, BuildingRegeneration, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		RequestFrame(checkEnabledSentry, EntIndexToEntRef(entity));
	}
	else if(StrEqual(classname, "obj_dispenser"))
    {
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Sentry); 
		CreateTimer(0.35, BuildingRegeneration, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(StrEqual(classname, "obj_teleporter"))
    {
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Sentry); 
		CreateTimer(0.35, BuildingRegeneration, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(StrContains(classname, "item_currencypack", false) == 0)
	{
		RequestFrame(TeleportToNearestPlayer, EntIndexToEntRef(entity));
	}
	else if(StrContains(classname, "item_powerup_rune", false) == 0)
	{
		RemoveEntity(entity);
	}
	else if(StrEqual(classname, "tank_boss"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Tank);
		RequestFrame(randomizeTankSpecialty, EntIndexToEntRef(entity));
	}
	
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
			RequestFrame(ResizeProjectile, EntIndexToEntRef(entity))
			RequestFrame(PrecisionHoming, EntIndexToEntRef(entity));
			CreateTimer(0.03, ThrowableHomingThink, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(1.5, SelfDestruct, EntIndexToEntRef(entity));
		}
		if(StrEqual(classname, "tf_projectile_pipe") || StrEqual(classname, "tf_projectile_pipe_remote"))
		{
			RequestFrame(CheckGrenadeMines, EntIndexToEntRef(entity));
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
	if(!IsValidEntity(entity) || entity < 0 || entity > 2048)
		return;

	new String:classname[32];
	GetEntityClassname(entity, classname, 32)
	for(new i=1;i<MaxClients;i++)
	{
		ShouldNotHome[entity][i] = false;
	}
	isEntitySentry[entity] = false;
	isProjectileHoming[entity] = false;
	isProjectileBoomerang[entity] = false;
	projectileHomingDegree[entity] = 0.0;
	gravChanges[entity] = false;
	//isProjectileSlash[entity][0] = 0.0;
	//isProjectileSlash[entity][1] = 0.0;
	jarateWeapon[entity] = -1;
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
public Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
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
public Event_ResetStats(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(isFailHooked == true)
	{
		UnhookEvent("mvm_wave_failed", Event_mvm_wave_failed)
		isFailHooked = false;
	}
	
	PrintToServer("MvM reset stats????");
	CreateTimer(0.2, LockMission);
	additionalstartmoney = 0.0;
	StartMoneySaved = 0.0;
	OverAllMultiplier = GetConVarFloat(cvar_BotMultiplier);
	for (new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client) && !IsFakeClient(client))
		{
			new primary = (GetWeapon(client,0));
			if(IsValidEntity(primary))
			{
				TF2Attrib_RemoveAll(primary);
			}
			new secondary = (GetWeapon(client,1));
			if(IsValidEntity(secondary))
			{
				TF2Attrib_RemoveAll(secondary);
			}
			new melee = (GetWeapon(client,2));
			if(IsValidEntity(melee))
			{
				TF2Attrib_RemoveAll(melee);
			}
			TF2Attrib_RemoveAll(client);
			current_class[client] = TF2_GetPlayerClass(client)
			if (!client_respawn_handled[client])
			{
				CreateTimer(0.05, ClChangeClassTimer, GetClientUserId(client));
			}
			CancelClientMenu(client);
			Menu_BuyUpgrade(client, 0);
			ResetClientUpgrades(client)
			TF2_RespawnPlayer(client);
		}
		CurrencySaved[client] = 0.0;
		additionalstartmoney = 0.0;
		StartMoneySaved = 0.0;
		CurrencyOwned[client] = (StartMoney + additionalstartmoney);
		for(new j = 0; j < Max_Attunement_Slots;j++)
		{
			SpellCooldowns[client][j] = 0.0;
		}
	}
	additionalstartmoney = 0.0;
	DeleteSavedPlayerData();

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
public Event_mvm_wave_failed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(isFailHooked == true)
	{
		UnhookEvent("mvm_wave_failed", Event_mvm_wave_failed)
		isFailHooked = false;
	}
	CreateTimer(0.75, THEREWILLBEBLOOD);
}
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	MoneyForTeamRatio[RED] = 1.0
	MoneyForTeamRatio[BLUE] = 1.0
}
public Event_mvm_wave_complete(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(isFailHooked == true)
	{
		UnhookEvent("mvm_wave_failed", Event_mvm_wave_failed)
		isFailHooked = false;
	}
}
public Event_mvm_wave_begin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client, slot, a;
	PrintToServer("mvm wave begin");
	if(isFailHooked == false)
	{
		HookEvent("mvm_wave_failed", Event_mvm_wave_failed)
		isFailHooked = true;
	}
	for (client = 1; client < MaxClients; client++)
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
				for(new y = 0;y<5;y++)
				{
					currentupgrades_restriction_mvm_chkp[client][slot][y] = currentupgrades_restriction[client][slot][y];
				}
			}
			client_new_weapon_ent_id_mvm_chkp[client] = client_new_weapon_ent_id[client];
		}
	}
	StartMoneySaved = StartMoney + additionalstartmoney;
}
public Action:Event_PlayerCollectMoney(Handle:event, const String:name[], bool:dontBroadcast)
{
	new money = GetEventInt(event, "currency");
	additionalstartmoney += float(money)*mvmadditional*mvmadditional;
	for (new i = 0; i <= MaxClients; i++) 
	{
		CurrencyOwned[i] += money;
	}
	SetEventInt(event, "currency", 0);
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CancelClientMenu(client);
	new attack = GetClientOfUserId(GetEventInt(event, "attacker"));
	fanOfKnivesCount[client] = 0;
	if(IsValidClient(client))
	{
		if(IsValidEntity(autoSentryID[client]) && autoSentryID[client] > 32)
		{
			RemoveEntity(autoSentryID[client]);
			autoSentryID[client] = -1;
		}
		if(attack != client && !(GetEventInt(event, "death_flags") & 32))
		{
			Kills[attack]++;
			Deaths[client]++;
		}
	}
	if ((!IsMvM()) && !(GetEventInt(event, "death_flags") & 32))
	{
		if((StartMoney + additionalstartmoney) < 50000000.0)
		{
			new Float:BotMoneyKill = (100.0+((SquareRoot(MoneyBonusKill + Pow((StartMoney + additionalstartmoney), 0.985))) * ServerMoneyMult) * 3.0);
			new Float:PlayerMoneyKill = (100.0+((SquareRoot(MoneyBonusKill + Pow((additionalstartmoney + StartMoney), 1.125))) * ServerMoneyMult) * 3.0);
			
			
			if (IsValidClient(attack) && IsValidClient(client) && attack != client)
			{
				for (new i = 0; i <= MaxClients; i++) 
				{ 
					CurrencyOwned[i] += PlayerMoneyKill
					if(IsValidClient(i) && IsClientInGame(i))
					{
						PrintToConsole(i, "+$%.0f",  PlayerMoneyKill)
					}
				}  
				additionalstartmoney += PlayerMoneyKill;
			}
			if(!IsValidClient(client) && attack != client)
			{
				for (new i = 0; i <= MaxClients; i++) 
				{ 
					CurrencyOwned[i] += BotMoneyKill
					if (IsValidClient(i) && IsClientInGame(i)) 
					{
						PrintToConsole(i, "+$%.0f", BotMoneyKill);
					} 
				}  
				additionalstartmoney += BotMoneyKill
			}
			
			if((StartMoney + additionalstartmoney) > 50000000.0)
			{
				additionalstartmoney = 50000000.0 - StartMoney;
			}

			if((StartMoney + additionalstartmoney) > 1000000.0 && gameStage == 0)
			{
				gameStage = 1;
				CPrintToChatAll("{valve}Uber Upgrades {white}| You have reached the Vector stage! New upgrades unlocked.");

				UpdateMaxValuesStage(gameStage);
			}
			else if((StartMoney + additionalstartmoney) > 5000000.0 && gameStage == 1)
			{
				gameStage = 2;
				CPrintToChatAll("{valve}Uber Upgrades {white}| You have reached the Dyad stage! New upgrades unlocked.");

				UpdateMaxValuesStage(gameStage);
			}
			else if((StartMoney + additionalstartmoney) > 25000000.0 && gameStage == 2)
			{
				gameStage = 3;
				CPrintToChatAll("{valve}Uber Upgrades {white}| You have reached the Triad stage! New upgrades unlocked.");

				UpdateMaxValuesStage(gameStage);
			}
		}
		else if(hardcapWarning == false)
		{
			hardcapWarning = true;
			CPrintToChatAll("{valve}Uber Upgrades {white}| {red}WARNING {white}| You have reached the hardcap for money in PvP!");
		}
	}
}

//Called on player CMD (~almost every tick, but varies based on response rate)
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	new Float:tickRate = GetTickInterval();
	if (IsValidClient(client))
	{
		new flags = GetEntityFlags(client)
		if(shouldAttack[client] == true){
			shouldAttack[client] = false;
			buttons |= IN_ATTACK;
		}
		if(buttons & IN_SCORE)
		{
			inScore[client] = true;
			if(MenuTimer[client] <= 0.0)
			{
				Menu_BuyUpgrade(client, 0);
				MenuTimer[client] = 0.5;
			}
		}
		else
		{
			inScore[client] = false;
		}

		if ((impulse == 201) && ImpulseTimer[client] <= 0.0 && IsValidEntity(client_new_weapon_ent_id[client]))
		{
			if(currentitem_level[client][3] == 242)
			{
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon",client_new_weapon_ent_id[client]);
				EquipPlayerWeapon(client, client_new_weapon_ent_id[client]);
			}
		}
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
						charging += TF2Attrib_GetValue(charge)*tickRate;
					}
					new Address:precisionPowerup = TF2Attrib_GetByName(client, "refill_ammo");
					if(precisionPowerup != Address_Null)
					{
						new Float:precisionPowerupValue = TF2Attrib_GetValue(precisionPowerup);
						if(precisionPowerupValue > 0.0){
							charging += 90.0*tickRate;
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
				if(!(buttons & IN_ATTACK) && globalButtons[client] & IN_ATTACK && fanOfKnivesCount[client] > 1)
				{
					new Float:fOrigin[3], Float:fAngles[3];
					GetClientEyePosition(client, fOrigin);

					GetClientEyeAngles(client, fAngles);
					fAngles[1] -= 15.0;
					for(new i = 0; i < fanOfKnivesCount[client]; i++)
					{
						fAngles[1] += 30.0/fanOfKnivesCount[client]
						TeleportEntity(client, NULL_VECTOR, fAngles, NULL_VECTOR);
						SDKCall(g_SDKCallJar, CWeapon);
					}
					fAngles[1] -= 15.0;
					TeleportEntity(client, NULL_VECTOR, fAngles, NULL_VECTOR);
					fanOfKnivesCount[client] = 0;
				}
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
						
						stompDamage = TF2_GetDPSModifiers(client, CWeapon, false, false) * 80.0;
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
									SDKHooks_TakeDamage(i,client,client,stompDamage,DMG_CLUB+DMG_CRIT,CWeapon, NULL_VECTOR, NULL_VECTOR);
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
								SetHudTextParams(x, y, tickRate*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Adrenaline: READY (MOUSE3)"); 
								SetHudTextParams(x, y, tickRate*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
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
								SetHudTextParams(x, y, tickRate*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Explosive Shot: READY (MOUSE3)"); 
								SetHudTextParams(x, y, tickRate*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
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
								SetHudTextParams(x, y, tickRate*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Stun Shot: READY (MOUSE3)"); 
								SetHudTextParams(x, y, tickRate*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
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
								SetHudTextParams(x, y, tickRate*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Juggernaut: READY (MOUSE3)"); 
								SetHudTextParams(x, y, tickRate*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
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
								SetHudTextParams(x, y, tickRate*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Dragon's Breath: READY (MOUSE3)"); 
								SetHudTextParams(x, y, tickRate*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
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
								SetHudTextParams(x, y, tickRate*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Detonate Flares: READY (MOUSE3)"); 
								SetHudTextParams(x, y, tickRate*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
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
								SetHudTextParams(x, y, tickRate*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Dash: READY (MOUSE2)"); 
								SetHudTextParams(x, y, tickRate*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
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
								SetHudTextParams(x, y, tickRate*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Transient Moonlight: R (MOUSE2)"); 
								SetHudTextParams(x, y, tickRate*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
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
								SetHudTextParams(x, y, tickRate*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Corpse Piler: READY (MOUSE2)"); 
								SetHudTextParams(x, y, tickRate*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
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
								SetHudTextParams(x, y, tickRate*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Homing Flares: READY (MOUSE2)"); 
								SetHudTextParams(x, y, tickRate*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
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
								SetHudTextParams(x, y, tickRate*5, red, blue, green, alpha, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudAbility, CooldownTime);
							}
							else
							{
								decl String:CooldownTime[32]
								Format(CooldownTime, sizeof(CooldownTime), "Silent Dash: READY (MOUSE3)"); 
								SetHudTextParams(x, y, tickRate*5, Readyred, Readyblue, Readygreen, alpha, 0, 0.0, 0.0, 0.0);
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
		lastFlag[client] = flags;
		globalButtons[client] = buttons;
	}
	return Plugin_Continue;
}
//Called on server thinking, 66.6/s
public OnGameFrame()
{
	new Float:tickRate = GetTickInterval();

	for(new i=MaxClients; i < MAXENTITIES; i++)
	{
		if(IsValidEntity(i))
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
			if(isEntitySentry[i] == true)
			{
				sentryThought[i] = false;
				SDKCall(g_SDKCallSentryThink, i);
			}
		}
	}
	for(new client=1; client<=MaxClients; client++)
	{
		if(MadmilkDuration[client] > 0.0)
			MadmilkDuration[client]-=tickRate;
		if(IsValidClient3(client))
		{
			if(MenuTimer[client] > 0.0){
			MenuTimer[client] -= tickRate; }
			if(efficiencyCalculationTimer[client] > 0.0){
			efficiencyCalculationTimer[client] -= tickRate; }
			if(ImpulseTimer[client] > 0.0){
			ImpulseTimer[client] -= tickRate; }
			if(weaponTrailTimer[client] > 0.0){
			weaponTrailTimer[client] -= tickRate;}
			if(fl_ArmorRegenBonusDuration[client] > 0.0){
			fl_ArmorRegenBonusDuration[client] -= tickRate;}
			
			if(IsPlayerAlive(client))
			{
				if(fl_GlobalCoolDown[client] > 0.0){
				fl_GlobalCoolDown[client] -= tickRate; }
				if(weaponArtCooldown[client] > 0.0){
				weaponArtCooldown[client] -= tickRate; }
				if(weaponArtParticle[client] > 0.0){
				weaponArtParticle[client] -= tickRate; }
				if(powerupParticle[client] > 0.0){
				powerupParticle[client] -= tickRate; }
				if(RadiationBuildup[client] > 0.0){
				RadiationBuildup[client] -= (RadiationMaximum[client] * 0.0285) * tickRate; }//Fully remove radiation within 35 seconds.
				if(CurrentSlowTimer[client] > 0.0){
				CurrentSlowTimer[client] -= tickRate; }
				if(BleedBuildup[client] > 0.0){
				BleedBuildup[client] -= (BleedMaximum[client] * 0.143) * tickRate; }//Fully remove bleed within 7 seconds.
				if(ConcussionBuildup[client] > 0.0){
				ConcussionBuildup[client] -= 100.0 * 0.03 * tickRate; }//Fully remove concussion within 30 seconds.
				if(miniCritStatusVictim[client] > 0.0){
				miniCritStatusVictim[client] -= tickRate;}
				if(miniCritStatusAttacker[client] > 0.0){
				miniCritStatusAttacker[client] -= tickRate;}
				if(disableUUMiniHud[client] > 0.0){
				disableUUMiniHud[client] -= tickRate;}

				if(RageActive[client])
				{
					if(RageBuildup[client] > 0.0)
					{
						RageBuildup[client] -= tickRate / 10.0//Revenge lasts 10 seconds (granted they aren't gaining it at the same time)
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
					new bool:flag = true;
					if(IsValidEntity(melee) && CWeapon == melee && TF2_GetPlayerClass(client) == TFClass_Heavy ){flag=false;}
					if(IsValidEntity(primary) && CWeapon == primary && TF2_GetPlayerClass(client) == TFClass_Sniper){flag=false;}
					if((IsValidEntity(primary) && CWeapon == primary && TF2_GetPlayerClass(client) == TFClass_Heavy)){flag=false;}

					if(flag)
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
						//Remove fire rate bonuses for reload rate on no clip size weapons.
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

			if(LightningEnchantmentDuration[client] > 0.0)
			{
				LightningEnchantmentDuration[client] -= tickRate; 
				new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon) && CWeapon != 0 && DarkmoonBladeDuration[client] <= 0.0)
				{
					if(weaponTrailTimer[client] <= 0.0)
					{
						CreateParticle(CWeapon, "utaunt_auroraglow_orange_parent", true, "", 5.0,_,_,1);
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
						CreateParticle(client, "utaunt_arcane_yellow_parent", true, "", 5.0);
						
						weaponTrailTimer[client] = 5.1;
					}
				}
			}
			if(DarkmoonBladeDuration[client] > 0.0)
			{
				DarkmoonBladeDuration[client] -= tickRate; 
				new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				new melee = GetWeapon(client,2);
				if(IsValidEntity(CWeapon) && IsValidEntity(melee) && CWeapon == melee)
				{
					if(weaponTrailTimer[client] <= 0.0)
					{
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
						CreateParticle(client, "utaunt_arcane_purple_parent", true, "", 5.0);
						weaponTrailTimer[client] = 5.1;
					}
				}
			}
			if(fl_CurrentArmor[client] < fl_MaxArmor[client])
			{
				if(!TF2_IsPlayerInCondition(client,TFCond_NoTaunting_DEPRECATED))
				{
					fl_CurrentArmor[client] += fl_ArmorRegen[client];
				}
				fl_CurrentArmor[client] += fl_ArmorRegenConstant[client];
			}
			
			if(fl_CurrentFocus[client] + fl_RegenFocus[client] < fl_MaxFocus[client])
			{
				fl_CurrentFocus[client] += fl_RegenFocus[client];
			}
			else if(fl_CurrentFocus[client] < fl_MaxFocus[client])
			{
				fl_CurrentFocus[client] = fl_MaxFocus[client];
			}
			
			if(fl_CurrentFocus[client] > fl_MaxFocus[client])
			{
				fl_CurrentFocus[client] = fl_MaxFocus[client];
			}
			if(fl_CurrentArmor[client] > fl_MaxArmor[client])
			{
				fl_CurrentArmor[client] = fl_MaxArmor[client];
			}
			
			if(fl_CurrentArmor[client] < 0.0)
			{
				fl_CurrentArmor[client] = 0.0;
			}
			if(fl_CurrentFocus[client] < 0.0)
			{
				fl_CurrentFocus[client] = 0.0;
			}
			if(CheckForAttunement(client))
			{
				for(new i = 0; i < Max_Attunement_Slots;i++)
				{
					if(SpellCooldowns[client][i] > 0.0)
					{
						SpellCooldowns[client][i] -= tickRate;
					}
					if(SpellCooldowns[client][i] < 0.0)
					{
						SpellCooldowns[client][i] = 0.0;
					}
				}
			}
		}
	}
}
public MRESReturn OnMyWeaponFired(int client, Handle hReturn, Handle hParams)
{
	if(!IsValidClient3(client) || !IsValidEntity(client))
		return MRES_Ignored;
	if(IsValidClient3(client))//Players
	{
		canShootAgain[client] = true;
		new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(IsValidWeapon(CWeapon))
		{
			meleeLimiter[client]++;
			if(!IsFakeClient(client))
			{
				if(getWeaponSlot(client,CWeapon) == 2)
				{
					RPS[client] += 0.5;
					new Handle:hPack = CreateDataPack();
					WritePackCell(hPack, client);
					WritePackFloat(hPack, 0.5);
					CreateTimer(1.0, RemoveFire, hPack);

					if(meleeLimiter[client] & 1 && weaponFireRate[CWeapon] > 5.01)
					{
						SDKCall(g_SDKCallSmack, CWeapon);
					}
				}
				else
				{
					RPS[client] += 1.0;
					new Handle:hPack = CreateDataPack();
					WritePackCell(hPack, client);
					WritePackFloat(hPack, 1.0);
					CreateTimer(1.0, RemoveFire, hPack);
					new String:classname[64]; 
					GetEdictClassname(CWeapon, classname, sizeof(classname)); 

					if(StrEqual(classname, "tf_weapon_cleaver"))
					{
						if(weaponFireRate[CWeapon] > 5.0)
						{
							new Address:override = TF2Attrib_GetByName(CWeapon, "override projectile type");
							if(override == Address_Null)
								SDKCall(g_SDKCallJar, CWeapon);
						}
					}
				}
			}
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
						new String:projName[32] = "tf_projectile_pipe";
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
							new Float:velocity = 20000.0;
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
						/*
						new Float:fwd[3]
						GetClientEyePosition(client, fOrigin);
						GetClientEyeAngles(client, fAngles);
						new Float:tempAngle[3] = fAngles;
						new Float:velocity = 6000.0;
						new Float:vecAngImpulse[3];
						GetCleaverAngularImpulse(vecAngImpulse);
						for(new i = 0; i < fanOfKnivesCount[client]; i++)
						{
							new String:projName[32] = "tf_projectile_cleaver";
							new iEntity = CreateEntityByName(projName);
							if (IsValidEdict(iEntity)) 
							{
								new iTeam = GetClientTeam(client);
								SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
								SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
								SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
								tempAngle = fAngles[1] + GetRandomFloat(-35.0,35.0);
								GetAngleVectors(tempAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
								GetAngleVectors(tempAngle,fwd, NULL_VECTOR, NULL_VECTOR);
								ScaleVector(fwd, 30.0);
								AddVectors(fOrigin, fwd, fOrigin);
								fVelocity[0] = vBuffer[0]*velocity;
								fVelocity[1] = vBuffer[1]*velocity;
								fVelocity[2] = vBuffer[2]*velocity;

								SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
								SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
								SetEntProp(iEntity, Prop_Data, "m_bIsLive", true);
							
								DispatchSpawn(iEntity);
								TeleportEntity(iEntity, fOrigin, tempAngle, NULL_VECTOR);
								SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vecAngImpulse, client, 0, 5.0);
							}
						}
						fanOfKnivesCount[client] = 0;
						*/
					}
				}
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
public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
	{
		SavePlayerData(client);
		if(IsMvM())
		{
			CreateTimer(0.2, ResetMission);
		}
	}
	DamageDealt[client] = 0.0;
	Kills[client] = 0.0;
	Deaths[client] = 0.0;
	dps[client] = 0.0;
	Healed[client] = 0.0;
	current_class[client] = TFClass_Unknown;
	fl_MaxArmor[client] = 300.0;
	fl_CurrentArmor[client] = 300.0;
	fl_AdditionalArmor[client] = 0.0;
	fl_MaxFocus[client] = 100.0;
	fl_CurrentFocus[client] = 100.0;
	BleedBuildup[client] = 0.0;
	RadiationBuildup[client] = 0.0;
	RageActive[client] = false;
	RageBuildup[client] = 0.0;
	SupernovaBuildup[client] = 0.0;
	ConcussionBuildup[client] = 0.0;
	fl_HighestFireDamage[client] = 0.0;
	isBuffActive[client] = false;
	canBypassRestriction[client] = false;
	for(new i = 0; i < Max_Attunement_Slots; i++)
	{
		AttunedSpells[client][i] = 0.0;
	}
	if(IsClientInGame(client))
	{
		if(b_Hooked[client] == true)
		{
			b_Hooked[client] = false;
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		}
	}
}
public OnClientPutInServer(client)
{
	fl_MaxArmor[client] = 300.0;
	fl_CurrentArmor[client] = 300.0;
	fl_AdditionalArmor[client] = 0.0;
	fl_MaxFocus[client] = 100.0;
	fl_CurrentFocus[client] = 100.0;
	BleedMaximum[client] = 100.0;
	RadiationMaximum[client] = 400.0;
	fl_HighestFireDamage[client] = 0.0;
	isBuffActive[client] = false;
	canBypassRestriction[client] = false;
	for(new i = 0; i < Max_Attunement_Slots; i++)
	{
		AttunedSpells[client][i] = 0.0;
	}
	DHookEntity(Hook_OnMyWeaponFired, true, client);
	
	if(b_Hooked[client] == false)
	{
		b_Hooked[client] = true;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		SDKHook(client, SDKHook_PreThinkPost, Hook_PreThink);
	}
	ClientCommand(client, "sm_showhelp");
}
public OnClientPostAdminCheck(client)
{
	if(IsValidClient(client))
	{
		decl String:clname[255]
		GetClientName(client, clname, sizeof(clname))
		client_no_d_team_upgrade[client] = 1
		if (!client_respawn_handled[client])
		{
			CreateTimer(0.0, ClChangeClassTimer, GetClientUserId(client));
		}
		GivePlayerData(client);
	}
}
public void Hook_PreThink(int client)
{
	if(IsFakeClient(client) || !IsPlayerAlive(client) || IsClientObserver(client))
		return;
	if(DragonsFurySpeedValue[client] != 0.0)
	{
		new String:dragonFurySpeed[32];
		FloatToString(DragonsFurySpeedValue[client],dragonFurySpeed,sizeof(dragonFurySpeed));
		SendConVarValue(client, FindConVar("tf_fireball_distance"), dragonFurySpeed);
		SetConVarFloat(FindConVar("tf_fireball_distance"), DragonsFurySpeedValue[client]);
	}
	if(isParachuteReOpenable[client] == 1 || isParachuteReOpenable[client] == 2)
	{
		new finalValue = isParachuteReOpenable[client] - 1;
		new String:parachuteCVAR[32];
		IntToString(finalValue,parachuteCVAR,sizeof(parachuteCVAR));
		SendConVarValue(client, FindConVar("tf_parachute_deploy_toggle_allowed"), parachuteCVAR);
		SetConVarInt(FindConVar("tf_parachute_deploy_toggle_allowed"), finalValue);
	}
	if(shieldVelocity[client] != 0.0)
	{
		new String:chargeSpeed[32];
		FloatToString(shieldVelocity[client],chargeSpeed,sizeof(chargeSpeed));
		SendConVarValue(client, FindConVar("tf_max_charge_speed"), chargeSpeed);
		SetConVarFloat(FindConVar("tf_max_charge_speed"), shieldVelocity[client]);
	}
}
public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	bossPhase[client] = 0;
	if(IsClientInGame(client) && IsValidClient(client))
	{
		CancelClientMenu(client);
		TF2Attrib_ClearCache(client);
		RespawnEffect(client);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
		client_respawn_handled[client] = 1;
		CreateTimer(0.4, WeaponReGiveUpgrades, GetClientUserId(client));
		SetEntProp(client, Prop_Send, "m_nCurrency", 0);
		CancelClientMenu(client);
		SetClientViewEntity(client, client);
		if(AreClientCookiesCached(client))
		{
			new String:menuEnabled[64];
			GetClientCookie(client, respawnMenu, menuEnabled, sizeof(menuEnabled));
			new Float:menuValue = StringToFloat(menuEnabled);
			if(menuValue == 0.0)
			{
				Menu_BuyUpgrade(client, 0);
			}
		}
		else
		{
			Menu_BuyUpgrade(client, 0);
		}
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
	if(!IsMvM() && IsFakeClient(client))
	{
		CreateTimer(0.4, GiveBotUpgrades, GetClientUserId(client));
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
public Event_PlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new nextclass = GetEventInt(event,"class");
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
			new slot;
			for(slot = 0; slot < 5;slot++)
			{
				currentupgrades_idx[client][slot] = blankArray1[client][slot]
				currentupgrades_val[client][slot] = blankArray2[client][slot]
				currentupgrades_i[client][slot] = blankArray2[client][slot]
				currentupgrades_number[client][slot] = blankArray[client][slot]
			}
			for(new i = 0; i < Max_Attunement_Slots; i++)
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
					LightningDamage *= Pow(1.05,TF2Attrib_GetValue(damageActive));
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
								SDKHooks_TakeDamage(i, client, client, LightningDamage, DMG_GENERIC, -1, NULL_VECTOR, NULL_VECTOR, !IsValidClient3(i));
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
public TF2Items_OnGiveNamedItem_Post(client, String:classname[], itemDefinitionIndex, itemLevel, itemQuality, entityIndex)
{
	if (IsValidClient(client) && !TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		if (itemLevel == 242)
		{
			new slot = 3
			current_class[client] = TF2_GetPlayerClass(client)
			currentitem_ent_idx[client][slot] = entityIndex;
			currentitem_level[client][slot] = 242;
			if (!currentupgrades_number[client][slot])
			{
				currentitem_idx[client][slot] = 20000
			}
			DefineAttributesTab(client, itemDefinitionIndex, slot)
			GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
			currentitem_catidx[client][slot] = GetUpgrade_CatList(upgrades_weapon_class_menu[upgrades_weapon_current[client]]);
			//PrintToServer("OGiveItem slot %d: [%s] #%d CAT[%d] qual%d", slot, classname, itemDefinitionIndex, currentitem_catidx[client][slot], itemLevel)
		}
		else
		{
			new slot = _:TF2II_GetItemSlot(itemDefinitionIndex, TF2_GetPlayerClass(client));
			if (current_class[client] == TFClass_Spy)
			{
				if (!strcmp(classname, "tf_weapon_pda_spy"))
				{
					current_class[client] = TF2_GetPlayerClass(client)
					currentitem_classname[client][1] = "tf_weapon_pda_spy"
					currentitem_ent_idx[client][1] = entityIndex
					DefineAttributesTab(client, 735, 1)
					currentitem_catidx[client][1] = GetUpgrade_CatList("tf_weapon_pda_spy")
					GiveNewUpgradedWeapon_(client, 1)
				}
			}
			currentitem_catidx[client][4] = _:TF2_GetPlayerClass(client) - 1;
			if (slot != 3 && slot <= NB_SLOTS_UED)
			{
				GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
				currentitem_ent_idx[client][slot] = entityIndex
				current_class[client] = TF2_GetPlayerClass(client)
				DefineAttributesTab(client, itemDefinitionIndex, slot)
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