public MRESReturn OnDamageTypeCalc(int weapon, Handle hReturn) {
	if(!IsValidWeapon(weapon))
		return MRES_Ignored;

	int damagetype = DHookGetReturn(hReturn);
	int client = getOwner(weapon);
	if(!IsValidClient3(client))
		return MRES_Ignored;

	currentDamageType[client].first = damagetype;

	return MRES_Ignored;
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, float &damage, &damagetype, &weapon, float damageForce[3], float damagePosition[3], damagecustom)
{
	if(currentDamageType[attacker].first == 0)
		currentDamageType[attacker].first = damagetype;

	if(IsValidClient3(victim))
	{
		lastKBSource[victim] = attacker;
		if(TF2Spawn_IsClientInSpawn(victim))
		{
			if(victim == attacker)
			{
				damage = 1.0;
				return Plugin_Changed;
			}
			else
			{
				if(IsValidClient3(attacker) && TF2_IsPlayerInCondition(attacker, TFCond_CritOnWin))
				{
					return Plugin_Changed;
				}
				damage = 0.001;
				return Plugin_Changed;
			}
		}
		if(IsValidClient3(attacker) && victim != attacker && IsValidEdict(inflictor))
		{
			char classname[128]; 
			GetEdictClassname(inflictor, classname, sizeof(classname));
			if(!strcmp("tf_projectile_lightningorb", classname))
			{
				damage += (30.0 + (Pow(ArcaneDamage[attacker] * Pow(ArcanePower[attacker], 4.0), 2.45) * 5.0));
				damagetype |= DMG_PREVENT_PHYSICS_FORCE;
			}
			if(IsValidWeapon(weapon))
			{
				if(damagetype == (DMG_BURN | DMG_PREVENT_PHYSICS_FORCE))
				{
					damage = 0.0;
					float burndmgMult = 1.0;
					burndmgMult *= GetAttribute(weapon, "shot penetrate all players");
					burndmgMult *= GetAttribute(weapon, "weapon burn dmg increased");
					burndmgMult *= GetAttribute(weapon, "weapon burn dmg reduced");
					burndmgMult *= GetAttribute(attacker, "weapon burn dmg increased");
					burndmgMult /= GetAttribute(weapon, "dmg penalty vs players");
					damage = (0.33*TF2_GetDPSModifiers(attacker, weapon, false, false)*burndmgMult);
				}
				if(currentDamageType[attacker].second & DMG_ARCANE)
					damage += (10.0 + (Pow(ArcaneDamage[attacker] * Pow(ArcanePower[attacker], 4.0), 2.45) * damage));
				if(LightningEnchantmentDuration[attacker] > 0.0 && !(damagetype & DMG_VEHICLE))
				//Normalize all damage to become the same theoretical DPS you'd get with 20 attacks per second.
					damage += (LightningEnchantment[attacker] / TF2_GetFireRate(attacker,weapon,0.6)) * 20.0;
				else if(DarkmoonBladeDuration[attacker] > 0.0)
				{
					int melee = GetWeapon(attacker,2);
					if(melee == weapon)
						damage += DarkmoonBlade[attacker];
				}
				float arcaneWeaponScaling = GetAttribute(weapon,"arcane weapon scaling",0.0);
				if(arcaneWeaponScaling != 0.0)
					damage += (10.0 + (Pow(ArcaneDamage[attacker] * Pow(ArcanePower[attacker], 4.0), 2.45) * arcaneWeaponScaling));
				
				int i = RoundToCeil(TICKRATE/weaponFireRate[weapon]);
				if(i <= 6)
				{
					if(i == 0) i = 1;
					damage *= i*weaponFireRate[weapon]/TICKRATE;
				}
			}
		}
		if(!(currentDamageType[attacker].second & DMG_PIERCING))
			damage *= TF2Attrib_HookValueFloat(1.0, "dmg_incoming_mult", victim);
		Address bossType = TF2Attrib_GetByName(victim, "damage force increase text");
		if(bossType != Address_Null && TF2Attrib_GetValue(bossType) > 0.0)
		{
			float bossValue = TF2Attrib_GetValue(bossType);
			switch(bossValue)
			{
				case 1.0:
				{
					if (!TF2_IsPlayerInCondition(victim,TFCond_UberchargedHidden) && GetClientHealth(victim) - damage < TF2_GetMaxHealth(victim) - (TF2_GetMaxHealth(victim)*(0.125*(bossPhase[victim]+1))))//boss phases
					{
						damage = GetClientHealth(victim) - (TF2_GetMaxHealth(victim) - (TF2_GetMaxHealth(victim)*(0.125*(bossPhase[victim]+1))));
						TF2_AddCondition(victim, TFCond_MegaHeal, 1.5);
						TF2_AddCondition(victim, TFCond_UberchargedHidden, 1.5);
						TF2_AddCondition(victim, TFCond_RuneHaste, 5.0);
						TF2_AddCondition(victim, TFCond_KingAura, 5.0);
						
						bossPhase[victim]++;
					}
				}
				case 4.0:
				{
					if (!TF2_IsPlayerInCondition(victim,TFCond_UberchargedHidden) && GetClientHealth(victim) - damage < TF2_GetMaxHealth(victim) - (TF2_GetMaxHealth(victim)*(0.2*(bossPhase[victim]+1))))//boss phases
					{
						damage = GetClientHealth(victim) - (TF2_GetMaxHealth(victim) - (TF2_GetMaxHealth(victim)*(0.2*(bossPhase[victim]+1))));
						TF2_AddCondition(victim, TFCond_MegaHeal, 5.0);
						TF2_AddCondition(victim, TFCond_UberchargedHidden, 1.5);
						TF2_AddCondition(victim, TFCond_RuneAgility, 5.0);
						
						
						bossPhase[victim]++;
					}
				}
				case 7.0:
				{
					if (!TF2_IsPlayerInCondition(victim,TFCond_UberchargedHidden) && GetClientHealth(victim) - damage < TF2_GetMaxHealth(victim) - (TF2_GetMaxHealth(victim)*(0.25*(bossPhase[victim]+1))))//boss phases
					{
						damage = GetClientHealth(victim) - (TF2_GetMaxHealth(victim) - (TF2_GetMaxHealth(victim)*(0.25*(bossPhase[victim]+1))));
						TF2_AddCondition(victim, TFCond_MegaHeal, 5.0);
						TF2_AddCondition(victim, TFCond_UberchargedHidden, 0.5);
						for(int i=1;i<MaxClients;i++)
						{
							if(IsValidClient3(i) && IsOnDifferentTeams(victim,i) && !IsClientObserver(i) && IsPlayerAlive(i))
							{
								float fOrigin[3], fVictimPos[3];
								GetClientAbsOrigin(i, fOrigin)
								GetClientAbsOrigin(victim,fVictimPos);
								if(GetVectorDistance(fOrigin,fVictimPos) <= 1000.0)
								{
									int iEntity = CreateEntityByName("tf_projectile_lightningorb");
									if (IsValidEdict(iEntity)) 
									{
										int iTeam = GetClientTeam(victim)
										float fAngles[3]
										SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", victim);

										SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
										SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
										SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", victim);
										SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", victim);

										fOrigin[2] += 40.0
										GetClientEyeAngles(victim,fAngles);

										TeleportEntity(iEntity, fOrigin, fAngles, NULL_VECTOR);
										DispatchSpawn(iEntity);
									}
								}
							}
						}
						bossPhase[victim]++;
					}
				}
			}
		}
	}

	if(!(currentDamageType[attacker].second & DMG_PIERCING) && IsValidClient(victim))
	{
		float pctArmor = (fl_AdditionalArmor[victim] + fl_CurrentArmor[victim])/fl_MaxArmor[victim];
		if(pctArmor < 0.01)
		{
			pctArmor = 0.01
		}
		if(fl_ArmorCap[victim] < 1.0)
		{
			fl_ArmorCap[victim] = 1.0;
		}
		damage /= ((1-fl_ArmorCap[victim])-((1-fl_ArmorCap[victim])*pctArmor) + fl_ArmorCap[victim]);
		int VictimCWeapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
		if(IsValidEdict(VictimCWeapon))
		{
			Address ResistanceWhileHeld = TF2Attrib_GetByName(VictimCWeapon, "SET BONUS: mystery solving time decrease");
			if(ResistanceWhileHeld != Address_Null)
			{
				float dmgDivisor = TF2Attrib_GetValue(ResistanceWhileHeld);
				damage = (damage / dmgDivisor);
			}	
			Address DodgeWhileHeld = TF2Attrib_GetByName(VictimCWeapon, "SET BONUS: chance of hunger decrease");
			if(DodgeWhileHeld != Address_Null)
			{
				float dodgeChance = TF2Attrib_GetValue(DodgeWhileHeld);
				if(dodgeChance >= GetRandomFloat(0.0, 1.0))
				{
					damage *= 0.0;
					//PrintToConsole(victim, "Attack Dodged!");
					return Plugin_Changed;
				}
			}	
		}
		Address DodgeBody = TF2Attrib_GetByName(victim, "SET BONUS: chance of hunger decrease");
		if(DodgeBody != Address_Null)
		{
			float dodgeChance = TF2Attrib_GetValue(DodgeBody);
			if(dodgeChance >= GetRandomFloat(0.0, 1.0))
			{
				damage *= 0.0;
				//PrintToConsole(victim, "Attack Dodged!");
				return Plugin_Changed;
			}
		}
		Address rootedDamage = TF2Attrib_GetByName(victim, "rooted damage taken");
		if(rootedDamage != Address_Null && TF2Attrib_GetValue(rootedDamage) > 1.0)
		{
			damage = Pow(damage, (1.0/TF2Attrib_GetValue(rootedDamage)));
		}
	}
	if(IsValidClient3(attacker) && IsValidClient3(victim) && IsValidWeapon(weapon))
	{
		char damageCategory[64];
		damageCategory = getDamageCategory(currentDamageType[attacker]);

		applyDamageAffinities(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom, damageCategory);

		char weaponClassName[128]; 
		GetEntityClassname(weapon, weaponClassName, sizeof(weaponClassName));
		if(StrContains(weaponClassName, "tf_weapon") != -1)
		{
			if(attacker != victim)
			{
				int itemIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
				if(StrEqual(weaponClassName,"tf_weapon_jar",false))
				{
					TF2_AddCondition(victim, TFCond_Jarated, 0.01);
				}
				if(itemIndex == 230)
				{
					TF2_AddCondition(victim, TFCond_Jarated, 0.01);
				}
				if(StrEqual(weaponClassName,"tf_weapon_jar_milk",false))
				{
					if(MadmilkDuration[victim] < currentGameTime+6.0)
					{
						MadmilkDuration[victim] = currentGameTime+6.0;
						MadmilkInflictor[victim] = attacker;
					}
				}
			}
			Address MadMilkOnhit = TF2Attrib_GetByName(weapon, "armor piercing");
			if(MadMilkOnhit != Address_Null)
			{
				float value = TF2Attrib_GetValue(MadMilkOnhit);
				if(MadmilkDuration[victim] < currentGameTime+value)
				{
					MadmilkDuration[victim] = currentGameTime+value
					MadmilkInflictor[victim] = attacker;
				}
			}
		}
		if(IsValidEdict(inflictor))
			ShouldNotHome[inflictor][victim] = true;
		if(damagetype == (DMG_RADIATION+DMG_DISSOLVE))//Radiation.
		{
			RadiationBuildup[victim] += damage;
			checkRadiation(victim,attacker);
		}
		if(damagetype != (DMG_PREVENT_PHYSICS_FORCE+DMG_ENERGYBEAM))
		{
			bool delayBool = true;
			Address regenerationPowerup = TF2Attrib_GetByName(victim, "regeneration powerup");
			if(regenerationPowerup != Address_Null)
			{
				float regenerationPowerupValue = TF2Attrib_GetValue(regenerationPowerup);
				if(regenerationPowerupValue > 0.0){delayBool = false;}
			}
			if(delayBool)
			{
				Address armorDelay = TF2Attrib_GetByName(victim, "tmp dmgbuff on hit");
				if(armorDelay != Address_Null)
				{
					float DelayAmount = TF2Attrib_GetValue(armorDelay) + 1.0;
					TF2_AddCondition(victim, TFCond_NoTaunting_DEPRECATED, 1.5/DelayAmount);
				}
				else
				{
					TF2_AddCondition(victim, TFCond_NoTaunting_DEPRECATED, 1.5);
				}
			}
		}
		Address resistancePowerup = TF2Attrib_GetByName(victim, "resistance powerup");
		if(resistancePowerup != Address_Null)
		{
			float resistancePowerupValue = TF2Attrib_GetValue(resistancePowerup);
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
			}
		}
		Address vampirePowerup = TF2Attrib_GetByName(victim, "vampire powerup");//Vampire Powerup
		if(vampirePowerup != Address_Null)
		{
			float vampirePowerupValue = TF2Attrib_GetValue(vampirePowerup);
			if(vampirePowerupValue > 0.0)
			{
				damage *= 0.75;
			}
		}
		Address revengePowerup = TF2Attrib_GetByName(victim, "revenge powerup");//Vampire Powerup
		if(revengePowerup != Address_Null)
		{
			float revengePowerupValue = TF2Attrib_GetValue(revengePowerup);
			if(revengePowerupValue > 0.0)
			{
				damage *= 0.8;
			}
		}
		Address regenerationPowerup = TF2Attrib_GetByName(victim, "regeneration powerup");//Regeneration powerup
		if(regenerationPowerup != Address_Null)
		{
			float regenerationPowerupValue = TF2Attrib_GetValue(regenerationPowerup);
			if(regenerationPowerupValue > 0.0)
			{
				damage *= 0.75;
			}
		}

		Address knockoutPowerupVictim = TF2Attrib_GetByName(victim, "knockout powerup");
		if(knockoutPowerupVictim != Address_Null)
		{
			float knockoutPowerupValue = TF2Attrib_GetValue(knockoutPowerupVictim);
			if(knockoutPowerupValue > 0.0){
				damage *= 0.8;
			}
		}
		
		Address kingPowerup = TF2Attrib_GetByName(victim, "king powerup");
		if(kingPowerup != Address_Null && TF2Attrib_GetValue(kingPowerup) > 0.0)
		{
			damage *= 0.8;
		}
		
		if(TF2_IsPlayerInCondition(attacker, TFCond_Plague))
		{
			int plagueInflictor = GetClientOfUserId(plagueAttacker[attacker]);
			if(IsValidClient3(plagueInflictor))
			{
				Address plaguePowerup = TF2Attrib_GetByName(plagueInflictor, "plague powerup");
				if(plaguePowerup != Address_Null)
				{
					float plaguePowerupValue = TF2Attrib_GetValue(plaguePowerup);
					if(plaguePowerupValue > 0.0)
						damage /= 2.0;
				}
			}
		}
		Address plaguePowerup = TF2Attrib_GetByName(victim, "plague powerup");
		if(plaguePowerup != Address_Null && TF2Attrib_GetValue(plaguePowerup) > 0.0)
		{
			damage *= 0.7;
		}
		
		Address supernovaPowerupVictim = TF2Attrib_GetByName(victim, "supernova powerup");
		if(supernovaPowerupVictim != Address_Null && TF2Attrib_GetValue(supernovaPowerupVictim) > 0.0)
		{
			damage *= 0.8;
		}
		
		Address strengthPowerup = TF2Attrib_GetByName(attacker, "strength powerup");
		if(strengthPowerup != Address_Null)
		{
			float strengthPowerupValue = TF2Attrib_GetValue(strengthPowerup);
			if(strengthPowerupValue > 0.0){
				damagetype |= DMG_NOCLOSEDISTANCEMOD;
				damage *= 2.0;
			}
		}
		
		Address revengePowerupAttacker = TF2Attrib_GetByName(attacker, "revenge powerup");
		if(revengePowerupAttacker != Address_Null)
		{
			if(RageActive[attacker] == true && TF2Attrib_GetValue(revengePowerupAttacker) > 0.0)
			{
				damage *= 1.5;
				if(powerupParticle[attacker] <= currentGameTime)
				{
					CreateParticle(victim, "critgun_weaponmodel_red", true, "", 1.0,_,_,1);
					TE_SendToAll();
					powerupParticle[attacker] = currentGameTime+0.2;
				}
			}
		}
		
		Address precisionPowerup = TF2Attrib_GetByName(attacker, "precision powerup");
		if(precisionPowerup != Address_Null)
		{
			float precisionPowerupValue = TF2Attrib_GetValue(precisionPowerup);
			if(precisionPowerupValue > 0.0){
				damage *= 1.35;
			}
		}
		
		int clientTeam = GetClientTeam(attacker);
		float clientPos[3];
		GetEntPropVector(attacker, Prop_Data, "m_vecOrigin", clientPos);
		float highestKingDMG = 1.0;
		for(int i = 1;i<MaxClients;i++)
		{
			if(IsValidClient3(i) && IsPlayerAlive(i))
			{
				int iTeam = GetClientTeam(i);
				if(clientTeam == iTeam)
				{
					float VictimPos[3];
					GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
					VictimPos[2] += 30.0;
					float Distance = GetVectorDistance(clientPos,VictimPos);
					if(Distance <= 600.0)
					{
						Address kingPowerupAttacker = TF2Attrib_GetByName(i, "king powerup");
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
		}
		
		Address knockoutPowerup = TF2Attrib_GetByName(attacker, "knockout powerup");
		if(knockoutPowerup != Address_Null)
		{
			float knockoutPowerupValue = TF2Attrib_GetValue(knockoutPowerup);
			if(knockoutPowerupValue > 0.0){
				if(TF2Econ_GetItemLoadoutSlot(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"),TF2_GetPlayerClass(attacker)) == 2)
				{
					damage *= 1.75
				}
			}
		}
		Address bleedBuild = TF2Attrib_GetByName(weapon, "sapper damage bonus");
		if(bleedBuild != Address_Null)
		{
			BleedBuildup[victim] += TF2Attrib_GetValue(bleedBuild);
			if(BleedBuildup[victim] >= BleedMaximum[victim])
			{
				BleedBuildup[victim] = 0.0;
				
				float bleedBonus = 1.0;
				Address vampirePowerupAttacker = TF2Attrib_GetByName(attacker, "unlimited quantity");
				if(vampirePowerupAttacker != Address_Null && TF2Attrib_GetValue(vampirePowerupAttacker) > 0.0)
				{
					bleedBonus += 0.25;
				}
				
				SDKHooks_TakeDamage(victim, attacker, attacker, TF2_GetDamageModifiers(attacker, weapon)*100.0*bleedBonus,DMG_PREVENT_PHYSICS_FORCE, -1, NULL_VECTOR, NULL_VECTOR);
				CreateParticle(victim, "env_sawblood", true, "", 2.0);
			}
		}
		Address radiationBuild = TF2Attrib_GetByName(weapon, "accepted wedding ring account id 1");
		if(radiationBuild != Address_Null)
		{
			RadiationBuildup[victim] += TF2Attrib_GetValue(radiationBuild);
			checkRadiation(victim,attacker);
		}
		Address Skill = TF2Attrib_GetByName(weapon, "apply look velocity on damage");
		if(Skill != Address_Null)
		{
			switch(TF2Attrib_GetValue(Skill))
			{
				case 13.0: //Bloodlust
				{
					float offset[3]
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
			float clientpos[3], targetpos[3];
			GetClientAbsOrigin(attacker, clientpos);
			GetClientAbsOrigin(victim, targetpos);
			float distance = GetVectorDistance(clientpos, targetpos);
			if(distance > 512.0)
			{
				Address FalloffIncrease = TF2Attrib_GetByName(weapon, "dmg falloff increased");
				if(FalloffIncrease != Address_Null)
				{
					if(TF2Attrib_GetValue(FalloffIncrease) != 1.0)
					{
						float Max = 1024.0; //the maximum units that the player and target is at (assuming you've already gotten the vectors)
						if(distance > Max)
						{
							distance = Max;
						}
						float MinFallOffDist = 512.0 / (TF2Attrib_GetValue(FalloffIncrease) - 0.48); //the minimum units that the player and target is at (assuming you've already gotten the vectors) 
						float base = damage; //base becomes the initial damage
						float multiplier = (MinFallOffDist / Max); //divides the minimal distance with the maximum you've set
						float falloff = (multiplier * base);  //this is to get how much the damage will be at maximum distance
						float Sinusoidal = ((falloff-base) / (Max-MinFallOffDist));  //does slope formula to get a sinusoidal fall off
						float intercept = (base - (Sinusoidal*MinFallOffDist));  //this calculation gets the 'y-intercept' to determine damage ramp up
						damage = ((Sinusoidal*distance)+intercept); //gets final damage by taking the slope formula, multiplying it by your vectors, and adds the damage ramp up Y intercept. 
					}
					//Debug.
					//PrintToChat(attacker, "%.2f multiplier", multiplier);
					//PrintToChat(attacker, "%.2f falloff", falloff);
					//PrintToChat(attacker, "%.2f Sinusoidal", Sinusoidal);
					//PrintToChat(attacker, "%.2f intercept", intercept);
					//PrintToChat(attacker, "%.2f damage", damage);
				}
			}
		}
		Address ReflectActive = TF2Attrib_GetByName(victim, "extinguish restores health");
		if(ReflectActive != Address_Null)
		{
			float ReflectDamage = damage;
			Address ReflectDamageMultiplier = TF2Attrib_GetByName(victim, "set cloak is movement based");
			if(ReflectDamageMultiplier != Address_Null && GetRandomInt(1, 100) < TF2Attrib_GetValue(ReflectActive) * 33.0)
			{
				float ReflectMult = TF2Attrib_GetValue(ReflectDamageMultiplier);
				ReflectDamage *= ReflectMult
				SDKHooks_TakeDamage(attacker, victim, victim, ReflectDamage, (DMG_PREVENT_PHYSICS_FORCE+DMG_ENERGYBEAM), -1, NULL_VECTOR, NULL_VECTOR);
			}
		}
		
		for(int i = 1; i < MaxClients; i++)
		{
			if(IsValidClient3(i) && GetClientTeam(i) == GetClientTeam(victim) && i != victim)
			{
				float victimPos[3];
				float guardianPos[3];
				GetClientEyePosition(victim,victimPos);
				GetClientEyePosition(i,guardianPos);
				if(GetVectorDistance(victimPos,guardianPos, false) < 1400.0)
				{
					Address RedirectActive = TF2Attrib_GetByName(i, "mult cloak meter regen rate");
					if(RedirectActive != Address_Null)
					{
						float redirect = TF2Attrib_GetValue(RedirectActive);
						SDKHooks_TakeDamage(i, attacker, attacker, damage*redirect, (DMG_PREVENT_PHYSICS_FORCE+DMG_ENERGYBEAM), -1, NULL_VECTOR, NULL_VECTOR);
						damage *= (1-redirect);
					}
				}
			}
		}
	}
	if(damage < 0.0)
		damage = 0.0;
	return Plugin_Changed;
}
public Action:TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3],int damagecustom, CritType &critType)
{
	attacker = EntRefToEntIndex(attacker);
	if(critType == CritType_Crit)
	{
		critStatus[victim] = true
		damagetype &= ~DMG_CRIT;
		damage *= 2.25;
		critType = CritType_None;
		currentDamageType[attacker].second |= DMG_ACTUALCRIT;
		return Plugin_Changed;
	}else if(IsValidClient3(victim) && miniCritStatus[victim] == false && IsValidClient3(attacker) && 
	(critType == CritType_MiniCrit || miniCritStatusAttacker[attacker] > currentGameTime || miniCritStatusVictim[victim] > currentGameTime))
	{
		if(debugMode)
			PrintToChat(attacker, "minicrit override 1");
		miniCritStatus[victim] = true;
		damage *= 1.4;
		critType = CritType_None;
		if(damagetype & DMG_CRIT)
			damagetype &= ~DMG_CRIT;

		currentDamageType[attacker].second |= DMG_MINICRIT;
		return Plugin_Changed;
	}
	lastDamageTaken[victim] = damage;
	//PrintToServer("triggered customOnTakeDamage");
	return Plugin_Continue;
}
public Action:TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage,
int &damagetype, int &weapon, float damageForce[3], float damagePosition[3],
int damagecustom, CritType &critType)
{
	attacker = EntRefToEntIndex(attacker);
	if(critType == CritType_Crit)
	{
		critStatus[victim] = true
		damagetype &= ~DMG_CRIT;
		damage = lastDamageTaken[victim] * 1.25;
		if(IsValidWeapon(weapon))
		{
			Address critDamageMult = TF2Attrib_GetByName(weapon, "mod medic killed marked for death");
			if(critDamageMult != Address_Null)
				damage *= TF2Attrib_GetValue(critDamageMult);
		}
		damage += lastDamageTaken[victim];
		critType = CritType_None
		lastDamageTaken[victim] = 0.0;
		return Plugin_Changed;
	}
	else if(IsValidClient3(victim) && lastDamageTaken[victim] != 0.0 && miniCritStatus[victim] == false && IsValidClient3(attacker) 
	&& (critType == CritType_MiniCrit || miniCritStatusAttacker[attacker] > currentGameTime || miniCritStatusVictim[victim] > currentGameTime))
	{
		if(debugMode)
			PrintToChat(attacker, "minicrit override failsafe");
		miniCritStatus[victim] = true
		damage = lastDamageTaken[victim] * 1.4;
		critType = CritType_None
		if(damagetype & DMG_CRIT)
			damagetype &= ~DMG_CRIT;
		
		lastDamageTaken[victim] = 0.0;
		return Plugin_Changed;
	}
	//PrintToServer("triggered ModifyRules");
	return Plugin_Continue;
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, float &damage, &damagetype, &weapon, float damageForce[3], float damagePosition[3], damagecustom)
{
	if(damagetype & DMG_CRIT)
	{
		critStatus[victim] = true
		damagetype &= ~DMG_CRIT;
		damage *= 2.25
	}
	if(damagetype & DMG_USEDISTANCEMOD)
		damagetype ^= DMG_USEDISTANCEMOD;

	if (!IsValidClient3(inflictor) && IsValidEdict(inflictor))
		damage = genericSentryDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
	
	if(IsValidClient3(victim) && IsValidClient3(attacker))
		damage = genericPlayerDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
	
	lastDamageTaken[victim] = damage;
	if(damage < 0.0)
	{
		damage = 0.0;
	}

	return Plugin_Changed;
}
public Action:OnTakeDamagePre_Tank(victim, &attacker, &inflictor, float &damage, &damagetype, &weapon, float damageForce[3], float damagePosition[3], damagecustom) 
{
	if(IsValidEdict(victim) && IsValidClient3(attacker))
	{
		currentDamageType[attacker].first = damagetype;
		if (!IsValidClient3(inflictor) && IsValidEdict(inflictor))
			damage = genericSentryDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
		
		damage = genericPlayerDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
		if(IsValidWeapon(weapon))
		{
			if(GetAttribute(attacker, "knockout powerup", 0.0) != 0.0)
				damage *= 1.35;
			
			if(LightningEnchantmentDuration[attacker] > 0.0 && !(damagetype & DMG_VEHICLE))
			{
				//Normalize all damage to become the same theoretical DPS you'd get with 20 attacks per second.
				damage += (LightningEnchantment[attacker] / TF2_GetFireRate(attacker,weapon,0.6)) * 20.0;
			}
			else if(DarkmoonBladeDuration[attacker] > 0.0)
			{
				int melee = GetWeapon(attacker,2);
				if(IsValidWeapon(melee) && melee == weapon)
				{
					damage += DarkmoonBlade[attacker];
				}
			}
			if(currentDamageType[attacker].second & DMG_ARCANE)
				damage += (10.0 + (Pow(ArcaneDamage[attacker] * Pow(ArcanePower[attacker], 4.0), 2.45) * damage));
			Address arcaneWeaponScaling = TF2Attrib_GetByName(weapon,"arcane weapon scaling");
			if(arcaneWeaponScaling != Address_Null)
				damage += (10.0 + (Pow(ArcaneDamage[attacker] * Pow(ArcanePower[attacker], 4.0), 2.45) * TF2Attrib_GetValue(arcaneWeaponScaling)));
			
			int i = RoundToCeil(TICKRATE/weaponFireRate[weapon]);
			if(i <= 6)
			{
				if(i == 0) i = 1;
				damage *= i*weaponFireRate[weapon]/TICKRATE;
			}
			applyDamageAffinities(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom, getDamageCategory(currentDamageType[attacker]));
		}
	}
	if(damage < 0.0)
	{
		damage = 0.0;
	}
	if(IsValidEdict(logic))
	{
		int round = GetEntProp(logic, Prop_Send, "m_nMannVsMachineWaveCount");
		damage *= (Pow(7500.0/waveToCurrency[round], DefenseMod + (DefenseIncreasePerWaveMod * round)) * 6.0)/OverallMod;
	}
	return Plugin_Changed;
}

public Action:OnTakeDamagePre_Sapper(victim, &attacker, &inflictor, float &damage, &damagetype, &weapon, float damageForce[3], float damagePosition[3], damagecustom) 
{
	int owner = GetEntPropEnt(victim, Prop_Send, "m_hBuilder"); 
	if(!IsClientInGame(owner))
	{
		return Plugin_Continue;
	}
	if(!IsClientInGame(attacker))
	{
		return Plugin_Continue;
	}
	currentDamageType[attacker].first = damagetype;
	damage = 50.0;
	int melee = (GetWeapon(attacker,2));
	Address firerate = TF2Attrib_GetByName(melee, "fire rate bonus HIDDEN");
	if(firerate != Address_Null)
	{
		float dmgpenalty = TF2Attrib_GetValue(firerate);
		damage *= dmgpenalty;
	}
	Address firerate1 = TF2Attrib_GetByName(melee, "fire rate bonus");
	if(firerate1 != Address_Null)
	{
		float dmgpenalty = TF2Attrib_GetValue(firerate1);
		damage *= dmgpenalty;
	}
	return Plugin_Changed;
}

public Action:OnTakeDamagePre_Sentry(victim, &attacker, &inflictor, float &damage, &damagetype, &weapon, float damageForce[3], float damagePosition[3], damagecustom) 
{
	int owner = GetEntPropEnt(victim, Prop_Send, "m_hBuilder");
	currentDamageType[attacker].first = damagetype;
	char SapperObject[128];
	GetEdictClassname(attacker, SapperObject, sizeof(SapperObject));
	if (StrEqual(SapperObject, "obj_attachment_sapper"))
	{
		int BuildingMaxHealth = GetEntProp(victim, Prop_Send, "m_iMaxHealth");
		damage = float(RoundToCeil(BuildingMaxHealth/110.0)); // in 110 ticks the sentry will be destroyed.

		int SapperOwner = GetEntPropEnt(attacker, Prop_Send, "m_hBuilder");
		if(IsValidClient3(SapperOwner))
		{
			int sapperItem = GetWeapon(SapperOwner, 6);
			if(IsValidEdict(sapperItem))
			{
				Address LifestealActive = TF2Attrib_GetByName(sapperItem,"mult airblast refire time");
				if(LifestealActive != Address_Null)
				{
					int HealthGained = RoundToCeil(damage * TF2Attrib_GetValue(LifestealActive))
					AddPlayerHealth(SapperOwner, HealthGained, 1.0, true, attacker);
					fl_CurrentArmor[SapperOwner] += float(HealthGained) * 0.2;
				}
				Address DamageActive = TF2Attrib_GetByName(sapperItem,"sapper damage bonus");
				if(DamageActive != Address_Null)
				{
					damage *= TF2Attrib_GetValue(DamageActive);
				}
			}
		}
		return Plugin_Changed; //Prevent any other modification to damage.
	}
	if (!IsValidClient3(inflictor) && IsValidEdict(inflictor))
		damage = genericSentryDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);

	if(IsValidClient3(attacker) && victim != attacker)
	{
		damage = genericPlayerDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
		if(IsValidWeapon(weapon))
		{
			if(GetAttribute(attacker, "knockout powerup", 0.0) != 0.0)
				damage *= 1.35;
			
			if(LightningEnchantmentDuration[attacker] > 0.0 && !(damagetype & DMG_VEHICLE))
			{
				//Normalize all damage to become the same theoretical DPS you'd get with 20 attacks per second.
				damage += (LightningEnchantment[attacker] / TF2_GetFireRate(attacker,weapon,0.6)) * 20.0;
			}
			else if(DarkmoonBladeDuration[attacker] > 0.0)
			{
				int melee = GetWeapon(attacker,2);
				if(IsValidWeapon(melee) && melee == weapon)
				{
					damage += DarkmoonBlade[attacker];
				}
			}
			//PrintToServer("%i damagebit", damagetype);
			if(currentDamageType[attacker].second & DMG_ARCANE)
				damage += (10.0 + (Pow(ArcaneDamage[attacker] * Pow(ArcanePower[attacker], 4.0), 2.45) * damage));
			Address arcaneWeaponScaling = TF2Attrib_GetByName(weapon,"arcane weapon scaling");
			if(arcaneWeaponScaling != Address_Null)
				damage += (10.0 + (Pow(ArcaneDamage[attacker] * Pow(ArcanePower[attacker], 4.0), 2.45) * TF2Attrib_GetValue(arcaneWeaponScaling)));
			
			int i = RoundToCeil(TICKRATE/weaponFireRate[weapon]);
			if(i <= 6)
			{
				if(i == 0) i = 1;
				damage *= i*weaponFireRate[weapon]/TICKRATE;
			}
		}
		if(TF2_IsPlayerMinicritBuffed(attacker))
		{
			damage *= 1.4;
		}
		if(GetEntProp(victim, Prop_Send, "m_bDisabled") == 1)
		{
			for(int i = 1;i<MaxClients;i++)
			{
				if(!IsValidClient3(i) || GetClientTeam(i) != GetClientTeam(attacker))
					continue;

				if(TF2_GetPlayerClass(i) != TFClass_Spy)
					continue;

				int sapper = GetWeapon(i,6);
				if(!IsValidWeapon(sapper))
					continue;

				float sapperBonus = GetAttribute(sapper, "scattergun knockback mult");
				if(sapperBonus == 1.0)
					continue;

				damage *= GetAttribute(sapper, "scattergun knockback mult");
			}
		}
	}
	if(IsValidClient3(owner))
	{
		if(!IsFakeClient(owner))
		{
			float pctArmor = (fl_AdditionalArmor[owner] + fl_CurrentArmor[owner])/fl_MaxArmor[owner];
			if(pctArmor <= 0.0)
			{
				pctArmor = 0.01
			}
			float armorAmt = fl_ArmorCap[owner] * 2.0;
			damage /= ((1-armorAmt)-((1-armorAmt)*pctArmor) + armorAmt);
			fl_CurrentArmor[owner] -= damage*0.8;
			if(fl_CurrentArmor[owner] < 0.0)
				fl_CurrentArmor[owner] = 0.0
		}
		damage *= TF2Attrib_HookValueFloat(1.0, "dmg_incoming_mult", owner);

		applyDamageAffinities(owner, attacker, inflictor, damage, weapon, damagetype, damagecustom, getDamageCategory(currentDamageType[attacker]));
	}
	return Plugin_Changed;
}
public float genericPlayerDamageModification(victim, attacker, inflictor, float damage, weapon, damagetype, damagecustom)
{
	bool isVictimPlayer = IsValidClient3(victim);

	if(isVictimPlayer)
	{
		if(IsFakeClient(attacker) && TF2Spawn_IsClientInSpawn(attacker))
		{
			return 0.0;
		}
		if(TF2_GetPlayerClass(victim) == TFClass_Scout && weapon == GetPlayerWeaponSlot(victim,2)){
		damagetype |= DMG_PREVENT_PHYSICS_FORCE;
		return 1.0;
		}
		if(damagetype == 4 && damagecustom == 3 && TF2_GetPlayerClass(attacker) == TFClass_Pyro)
		{
			int secondary = GetWeapon(attacker,1);
			if(IsValidEdict(secondary) && weapon == secondary)
			{
				float gasExplosionDamage = GetAttribute(weapon, "ignition explosion damage bonus");
				if(gasExplosionDamage != 1.0)
					damage *= gasExplosionDamage;
			}
		}
		if(TF2_GetPlayerClass(victim) == TFClass_Spy && (TF2_IsPlayerInCondition(victim, TFCond_Cloaked) || TF2_IsPlayerInCondition(victim, TFCond_Stealthed)))
		{
			float CloakResistance = GetAttribute(GetPlayerWeaponSlot(victim,4), "absorb damage while cloaked");
			if(CloakResistance != 1.0)
				damage *= CloakResistance;
		}
		if(TF2_IsPlayerInCondition(victim, TFCond_CompetitiveLoser))
		{
			damage *= 0.35;
		}
	}
	if(TF2_IsPlayerInCondition(attacker, TFCond_DisguiseRemoved))
	{
		damage *= 1.8;
	}
	if(IsValidWeapon(weapon))
	{
		int weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
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
		if (damagecustom == TF_CUSTOM_BACKSTAB)
		{
			bool ToggleBackstab = true;
			float canBeBackstabbed = GetAttribute(victim, "set item tint RGB");
			if(canBeBackstabbed != 1.0)
				ToggleBackstab = false;

			if(ToggleBackstab == true)
			{
				damage = 450.0 * TF2_GetDamageModifiers(attacker,weapon);
				
				float backstabRadiation = GetAttribute(weapon, "no double jump");
				if(backstabRadiation != 1.0)
				{
					RadiationBuildup[victim] += backstabRadiation;
					checkRadiation(victim,attacker);
				}
				float stealthedBackstab = GetAttribute(weapon, "airblast cost increased");
				if(stealthedBackstab != 1.0)
				{
					TF2_AddCondition(attacker, TFCond_StealthedUserBuffFade, stealthedBackstab);
					TF2_RemoveCondition(attacker, TFCond_Stealthed)
				}
				
				return damage;
			}
		}
		if(isVictimPlayer && attacker != victim)
		{
			if (damagecustom == 46 && damagetype & DMG_SHOCK)//Short Circuit Balls
			{
				damage = 10.0;
				damage *= GetAttribute(weapon, "damage bonus");
				damage *= GetAttribute(weapon, "bullets per shot bonus");
				damage *= GetAttribute(weapon, "damage bonus HIDDEN");
				damage *= GetAttribute(weapon, "damage penalty");
			}
			if(damagecustom == TF_CUSTOM_BASEBALL)//Sandman Balls & Wrap Assassin Ornaments
			{
				damage = 45.0;
				damage += GetAttribute(weapon, "has pipboy build interface");
				damage *= GetAttribute(weapon, "damage bonus");
				damage *= GetAttribute(weapon, "damage bonus HIDDEN");
				damage *= GetAttribute(weapon, "damage penalty");
			}

			float minicritVictimOnHit = GetAttribute(weapon, "recipe component defined item 1", 0.0);
			if(minicritVictimOnHit != 0.0)
				miniCritStatusVictim[victim] = minicritVictimOnHit;
			
			float rageOnHit = GetAttribute(weapon, "mod rage on hit bonus", 0.0);
			if(rageOnHit != 0.0)
			{
				if(GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter") < 150.0)
					SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter") + rageOnHit)
			}
			int hitgroup = GetEntProp(victim, Prop_Data, "m_LastHitGroup");
			if(StrEqual(getDamageCategory(currentDamageType[attacker]),"direct",false) && hitgroup == 1)
			{
				float HeadshotsActive = GetAttribute(weapon, "charge time decreased",0.0);
				if(HeadshotsActive != 0.0)
				{
					critStatus[victim] = true;
					damagecustom = 1;
					damage *= HeadshotsActive;
				}
				//Fix The Classic's "Cannot Headshot Without Full Charge" while not scoped.
				float classicDebuff = GetAttribute(weapon, "sniper no headshot without full charge", 0.0);
				{
					if(classicDebuff == 0.0 && !TF2_IsPlayerInCondition(attacker, TFCond_Zoomed))
					{
						damagetype |= DMG_CRIT;
						damagecustom = 1;
					}
				}
				float precisionPowerup = GetAttribute(attacker, "precision powerup", 0.0);
				if(precisionPowerup != 0.0)
				{
					miniCritStatus[victim] = true;
					damage *= precisionPowerup * 1.35;
					damagecustom = 1;
				}
			}
			if(TF2_IsPlayerInCondition(victim,TFCond_TmpDamageBonus))
			{
				damage *= 1.3;
			}
			if(TF2_IsPlayerInCondition(victim, TFCond_Sapped))
			{
				for(int i = 1;i<MaxClients;i++)
				{
					if(!IsValidClient3(i) || GetClientTeam(i) != GetClientTeam(attacker))
						continue;

					if(TF2_GetPlayerClass(i) != TFClass_Spy)
						continue;

					int sapper = GetWeapon(i,6);
					if(!IsValidWeapon(sapper))
						continue;

					float sapperBonus = GetAttribute(sapper, "scattergun knockback mult");
					if(sapperBonus == 1.0)
						continue;

					damage *= GetAttribute(sapper, "scattergun knockback mult");
				}
			}
		}
		if(TF2_GetPlayerClass(attacker) == TFClass_Medic)
		{
			char classname[128]; 
			GetEdictClassname(weapon, classname, sizeof(classname)); 
			if(weapon == GetPlayerWeaponSlot(attacker,0) && StrContains(classname, "crossbow") == -1)
			{
				damagetype |= DMG_ENERGYBEAM;
				damage *= 1.8;
			}
		}
		float medicDMGBonus = 1.0;
		int healers = GetEntProp(attacker, Prop_Send, "m_nNumHealers");
		if(healers > 0)
		{
			for (int i = 1; i < MaxClients; i++)
			{
				if (!IsValidClient3(i))
					continue;
				int healerweapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
				if(!IsValidWeapon(healerweapon))
					continue;
				if(!HasEntProp(healerweapon, Prop_Send, "m_hHealingTarget") || GetEntPropEnt(healerweapon, Prop_Send, "m_hHealingTarget") != attacker)
					continue;
				
				float dmgActive = GetAttribute(healerweapon, "hidden secondary max ammo penalty");
				if(dmgActive != 1.0)
					medicDMGBonus += dmgActive;
			}
		}
		damage *= medicDMGBonus;
		damage *= TF2Attrib_HookValueFloat(1.0, "dmg_outgoing_mult", attacker);
		float SniperChargingFactorActive = GetAttribute(weapon, "no charge impact range");
		if(SniperChargingFactorActive != 1.0)
		{
			if(LastCharge[attacker] > 50.0)
				damage *= SniperChargingFactorActive;
		}
		float expodamageActive = GetAttribute(weapon, "taunt turn speed");
		if(expodamageActive != 1.0)
			damage *= Pow(expodamageActive, 6.0);

		float HeadshotDamage = GetAttribute(weapon, "overheal penalty");
		if(HeadshotDamage != 1.0 && damagecustom == 1)
			damage *= HeadshotDamage;

		if(isVictimPlayer)
		{
			float burndmgMult = 1.0;
			burndmgMult *= GetAttribute(weapon, "shot penetrate all players");
			burndmgMult *= GetAttribute(weapon, "weapon burn dmg increased");

			if(GetClientTeam(attacker) != GetClientTeam(victim) && GetAttribute(weapon, "flame_ignore_player_velocity", 0.0) &&
			TF2_GetDPSModifiers(attacker, weapon)*burndmgMult >= fl_HighestFireDamage[victim] && 
			!(damagetype & DMG_BURN && damagetype & DMG_PREVENT_PHYSICS_FORCE) && !(damagetype & DMG_ENERGYBEAM)) // int afterburn system.
			{
				float afterburnDuration = 2.0 * GetAttribute(weapon, "weapon burn time increased");
				TF2Util_IgnitePlayer(victim, attacker, afterburnDuration, weapon);
				damagetype |= DMG_PLASMA;
				fl_HighestFireDamage[victim] = TF2_GetDPSModifiers(attacker, weapon)*burndmgMult;
			}
		}
		float overrideproj = GetAttribute(weapon, "override projectile type");
		float energyWeapActive = GetAttribute(weapon, "energy weapon penetration", 0.0);
		if(overrideproj != 1.0)
		{
			if((overrideproj > 1.0 && overrideproj <= 2.0) || (overrideproj > 5.0 && overrideproj <= 6.0))
			{
				damage *= GetAttribute(weapon, "bullets per shot bonus");
				damage *= GetAttribute(attacker, "bullets per shot bonus");
				damage *= GetAttribute(weapon, "accuracy scales damage");
			}
		}
		if(energyWeapActive != 0.0)
		{
			damage *= GetAttribute(weapon, "bullets per shot bonus");
			damage *= GetAttribute(weapon, "accuracy scales damage");
		}
		if(damagecustom == TF_CUSTOM_PLASMA_CHARGED)
		{
			PrintToConsole(attacker, "Full charge hit!");
			damage *= Pow(GetAttribute(weapon, "clip size bonus upgrade")+1.0, 0.9);
			damagetype |= DMG_CRIT;
		}
		float DealsNoKBActive = GetAttribute(weapon, "apply z velocity on damage");
		if(DealsNoKBActive == 3.0)
			damagetype |= DMG_PREVENT_PHYSICS_FORCE;

		float damageActive = GetAttribute(weapon, "ubercharge", 0.0);
		if(damageActive != 0.0)
			damage *= Pow(1.05,damageActive);

		if(TF2_IsPlayerInCondition(attacker, TFCond_RunePrecision))
			damage *= 2.0;

		if(damagetype & DMG_CLUB)
		{
			float multiHitActive = GetAttribute(weapon, "taunt move acceleration time",0.0);
			if(multiHitActive != 0.0)
				DOTStock(victim,attacker,damage,weapon,damagetype + DMG_VEHICLE,RoundToNearest(multiHitActive),0.4,0.15,true);
		}
		if(isVictimPlayer)
		{
			float bouncingBullets = GetAttribute(weapon, "flame size penalty", 0.0);
			if(bouncingBullets != 0.0 && LastCharge[attacker] >= 150.0)
			{
				//PrintToChat(attacker, "%s dmg", GetAlphabetForm(DOTDmg));
				bool isBounced[MAXPLAYERS+1];
				isBounced[victim] = true
				int lastBouncedTarget = victim;
				float lastBouncedPosition[3];
				GetClientEyePosition(lastBouncedTarget, lastBouncedPosition)
				LastCharge[attacker] = 0.0;
				int i = 0
				int maxBounces = RoundToNearest(bouncingBullets);
				for(int client=1;client<MaxClients && i < maxBounces;client++)
				{
					if(!IsValidClient3(client)) {continue;}
					if(!IsPlayerAlive(client)) {continue;}
					if(!IsOnDifferentTeams(client,attacker)) {continue;}
					if(isBounced[client]) {continue;}

					float VictimPos[3]; 
					GetClientEyePosition(client, VictimPos); 
					float distance = GetVectorDistance(lastBouncedPosition, VictimPos);
					if(distance > 350.0) {continue;}
					
					isBounced[client] = true;
					GetClientEyePosition(lastBouncedTarget, lastBouncedPosition)
					lastBouncedTarget = client
					int iParti = CreateEntityByName("info_particle_system");
					int iPart2 = CreateEntityByName("info_particle_system");

					if (IsValidEdict(iParti) && IsValidEdict(iPart2))
					{
						char szCtrlParti[32];
						char particleName[32];
						particleName = GetClientTeam(attacker) == 2 ? "dxhr_sniper_rail_red" : "dxhr_sniper_rail_blue";
						Format(szCtrlParti, sizeof(szCtrlParti), "tf2ctrlpart%i", iPart2);
						DispatchKeyValue(iPart2, "targetname", szCtrlParti);

						DispatchKeyValue(iParti, "effect_name", particleName);
						DispatchKeyValue(iParti, "cpoint1", szCtrlParti);
						DispatchSpawn(iParti);
						TeleportEntity(iParti, lastBouncedPosition, NULL_VECTOR, NULL_VECTOR);
						TeleportEntity(iPart2, VictimPos, NULL_VECTOR, NULL_VECTOR);
						ActivateEntity(iParti);
						AcceptEntityInput(iParti, "Start");
						
						Handle pack;
						CreateDataTimer(1.0, Timer_KillParticle, pack);
						WritePackCell(pack, iParti);
						Handle pack2;
						CreateDataTimer(1.0, Timer_KillParticle, pack2);
						WritePackCell(pack2, iPart2);
					}
					SDKHooks_TakeDamage(client,attacker,attacker,damage,damagetype,-1,NULL_VECTOR,NULL_VECTOR)
					i++
				}
			}
		}
		float supernovaPowerup = GetAttribute(attacker, "supernova powerup",0.0);
		if(supernovaPowerup != 0.0)
		{
			if(StrEqual(getDamageCategory(currentDamageType[attacker]),"blast",false))
			{
				damage *= 1.8;
			}
			else
			{
				damage *= 1.35;
				float victimPosition[3];
				GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", victimPosition); 
				
				EntityExplosion(attacker, damage, 300.0,victimPosition,_,weaponArtParticle[attacker] <= currentGameTime ? true : false, victim,_,_,weapon, 0.5, 70);
				//PARTICLES
				if(weaponArtParticle[attacker] <= currentGameTime)
				{
					int iParti = CreateEntityByName("info_particle_system");
					int iPart2 = CreateEntityByName("info_particle_system");

					if (IsValidEdict(iParti) && IsValidEdict(iPart2))
					{
						char particleName[32];
						particleName = GetClientTeam(attacker) == 2 ? "powerup_supernova_strike_red" : "powerup_supernova_strike_blue";
						
						float clientPos[3], clientAng[3];
						GetClientEyePosition(attacker, clientPos);
						GetClientEyeAngles(attacker,clientAng);
						
						char szCtrlParti[32];
						Format(szCtrlParti, sizeof(szCtrlParti), "tf2ctrlpart%i", iPart2);
						DispatchKeyValue(iPart2, "targetname", szCtrlParti);
						DispatchKeyValue(iParti, "effect_name", particleName);
						DispatchKeyValue(iParti, "cpoint1", szCtrlParti);
						DispatchSpawn(iParti);
						TeleportEntity(iParti, clientPos, clientAng, NULL_VECTOR);
						TeleportEntity(iPart2, victimPosition, NULL_VECTOR, NULL_VECTOR);
						ActivateEntity(iParti);
						AcceptEntityInput(iParti, "Start");
						
						Handle pack;
						CreateDataTimer(0.2, Timer_KillParticle, pack);
						WritePackCell(pack, EntIndexToEntRef(iParti));
						Handle pack2;
						CreateDataTimer(0.2, Timer_KillParticle, pack2);
						WritePackCell(pack2, EntRefToEntIndex(iPart2));
					}
					weaponArtParticle[attacker] = currentGameTime+1.0;
				}
			}
		}
	}
	return damage;
}
public float genericSentryDamageModification(victim, attacker, inflictor, float damage, weapon, damagetype, damagecustom)
{
	char classname[128]; 
	GetEdictClassname(inflictor, classname, sizeof(classname)); 
	int weaponIdx = (IsValidWeapon(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);

	bool isVictimPlayer = IsValidClient3(victim);

	if (isVictimPlayer && StrEqual(classname, "obj_attachment_sapper"))
	{
		TF2_AddCondition(victim, TFCond_Sapped, 2.0);
	}
	//PrintToChatAll("classname %s",classname);
	if ((!strcmp("obj_sentrygun", classname) || !strcmp("tf_projectile_sentryrocket", classname)) || weaponIdx == 140)
	{
		int owner; 
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
			char Ownerclassname[128]; 
			GetEdictClassname(owner, Ownerclassname, sizeof(Ownerclassname)); 
			if(StrEqual(Ownerclassname, "tank_boss"))
			{
				damage *= TankSentryDamageMod;
				damagetype |= DMG_PREVENT_PHYSICS_FORCE;
			}
		}
		if(IsValidClient3(owner))
		{
			int melee = GetPlayerWeaponSlot(owner,2);
			if((GetEntPropFloat(inflictor, Prop_Send, "m_flModelScale") != 0.3))
			{
				damagetype |= DMG_PREVENT_PHYSICS_FORCE;
				
				if(IsValidEdict(melee))
				{
					Address sentryOverrideActive = TF2Attrib_GetByName(melee, "override projectile type");
					if(sentryOverrideActive != Address_Null)
					{
						float sentryOverride = TF2Attrib_GetValue(sentryOverrideActive);
						switch(sentryOverride)
						{
							case 34.0:
							{
								if(damagetype & DMG_BULLET)
								{
									if(0.1 >= GetRandomFloat(0.0, 1.0))
									{
										int iEntity = CreateEntityByName("tf_projectile_cleaver");
										if (IsValidEdict(iEntity)) 
										{
											int iTeam = GetClientTeam(owner);
											float fAngles[3]
											float fOrigin[3]
											float vBuffer[3]
											float fVelocity[3]
											float fwd[3]
											SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);
											SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
											int angleOffsetB = FindSendPropInfo("CObjectSentrygun", "m_iAmmoShells") - 16;
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
											float Speed[3];
											bool movementType = false;
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
												float velocity = 2000.0;
												Address projspeed = TF2Attrib_GetByName(melee, "Projectile speed increased");
												Address projspeed1 = TF2Attrib_GetByName(melee, "Projectile speed decreased");
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
										int iEntity = CreateEntityByName("tf_projectile_spellfireball");
										if (IsValidEdict(iEntity)) 
										{
											int iTeam = GetClientTeam(owner);
											float fAngles[3]
											float fOrigin[3]
											float vBuffer[3]
											float fVelocity[3]
											float fwd[3]
											SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);
											SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
											int angleOffsetB = FindSendPropInfo("CObjectSentrygun", "m_iAmmoShells") - 16;
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
											float Speed[3];
											bool movementType = false;
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
												float velocity = 11000.0;
												float vecAngImpulse[3];
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
										int iEntity = CreateEntityByName("tf_projectile_spellmeteorshower");
										if (IsValidEdict(iEntity)) 
										{
											int iTeam = GetClientTeam(owner);
											float fAngles[3]
											float fOrigin[3]
											float vBuffer[3]
											float fVelocity[3]
											SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);
											SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
											int angleOffsetB = FindSendPropInfo("CObjectSentrygun", "m_iAmmoShells") - 16;
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
											float Speed[3];
											bool movementType = false;
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
												float velocity = 2000.0;
												Address projspeed = TF2Attrib_GetByName(melee, "Projectile speed increased");
												Address projspeed1 = TF2Attrib_GetByName(melee, "Projectile speed decreased");
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
			int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
			if(IsValidEdict(CWeapon))
			{
				Address SentryDmgActive = TF2Attrib_GetByName(CWeapon, "ring of fire while aiming");
				if(SentryDmgActive != Address_Null)
				{
					damage *= TF2Attrib_GetValue(SentryDmgActive);
				}
			}
			if(IsValidEdict(melee))
			{
				Address SentryDmgActive1 = TF2Attrib_GetByName(melee, "throwable detonation time");
				if(SentryDmgActive1 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(SentryDmgActive1);
				}
				Address SentryDmgActive2 = TF2Attrib_GetByName(melee, "throwable fire speed");
				if(SentryDmgActive2 != Address_Null)
				{
					damage *= TF2Attrib_GetValue(SentryDmgActive2);
				}
				Address damageActive = TF2Attrib_GetByName(melee, "ubercharge");
				if(damageActive != Address_Null)
				{
					damage *= Pow(1.05,TF2Attrib_GetValue(damageActive));
				}
			}
			if((!strcmp("obj_sentrygun", classname) && GetEntProp(inflictor, Prop_Send, "m_bMiniBuilding") == 1))
			{
				damage *= 1.5
			}
		}
		if(IsValidClient3(attacker) && TF2_GetPlayerClass(attacker) == TFClass_Engineer)
		{
			if(!strcmp("tf_projectile_spellfireball", classname))
			{
				int primary = GetPlayerWeaponSlot(attacker,0)
				int melee = GetPlayerWeaponSlot(attacker,2)
				if(IsValidEdict(melee))
				{
					Address sentryOverrideActive = TF2Attrib_GetByName(melee, "override projectile type");
					if(sentryOverrideActive != Address_Null)
					{
						float sentryOverride = TF2Attrib_GetValue(sentryOverrideActive);
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
					
					
					Address SentryDmgActive = TF2Attrib_GetByName(melee, "engy sentry damage bonus");
					Address SentryDmgActive1 = TF2Attrib_GetByName(melee, "throwable detonation time");
					Address SentryDmgActive2 = TF2Attrib_GetByName(melee, "throwable fire speed");
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
					Address damageActive = TF2Attrib_GetByName(melee, "ubercharge");
					if(damageActive != Address_Null)
					{
						damage *= Pow(1.05,TF2Attrib_GetValue(damageActive));
					}
				}
				if(IsValidEdict(primary))
				{
					Address SentryDmgActive2 = TF2Attrib_GetByName(primary, "engy sentry damage bonus");
					if(SentryDmgActive2 != Address_Null)
					{
						damage *= TF2Attrib_GetValue(SentryDmgActive2);
					}
				}
				int CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
				if(IsValidEdict(CWeapon))
				{
					Address SentryDmgActive = TF2Attrib_GetByName(CWeapon, "ring of fire while aiming");
					if(SentryDmgActive != Address_Null)
					{
						damage *= TF2Attrib_GetValue(SentryDmgActive);
					}
				}
			}
		}
	}
	return damage;
}
public void applyDamageAffinities(&victim, &attacker, &inflictor, float &damage, &weapon, &damagetype, &damagecustom, char[] damageCategory)
{
	/*extendedDamageTypes bits;
	bits = currentDamageType[attacker];
	*///Lets use this later...

	currentDamageType[attacker].clear();

	if(StrEqual(damageCategory, "direct"))
	{
		Address dmgTakenMultAddr = TF2Attrib_GetByName(victim, "direct damage taken reduced");
		if(dmgTakenMultAddr != Address_Null)
			damage *= TF2Attrib_GetValue(dmgTakenMultAddr);

		Address dmgMasteryAddr = TF2Attrib_GetByName(attacker, "physical damage affinity");
		if(dmgMasteryAddr != Address_Null){
			damage = Pow(damage, TF2Attrib_GetValue(dmgMasteryAddr));

			if(IsValidEdict(inflictor) && !IsValidClient3(inflictor) && !HasEntProp(inflictor, Prop_Send, "m_iItemDefinitionIndex"))
				{damagetype |= DMG_CLUB;damagetype |= DMG_BULLET;}

			if(damagetype & DMG_CLUB)
			{
				//Melee reduces on average 5% of their armor per second.
				float multiHitActive = GetAttribute(weapon, "taunt move acceleration time",0.0);
				fl_CurrentArmor[victim] -= fl_CurrentArmor[victim]*0.05/(weaponFireRate[weapon]*(multiHitActive+1));
			}
			if(damagetype & DMG_BULLET || damagetype & DMG_BUCKSHOT)
			{
				//Deal 3 piercing damage.
				currentDamageType[attacker].second |= DMG_PIERCING;
				SDKHooks_TakeDamage(victim, attacker, attacker, 3.0, DMG_GENERIC, weapon);
			}
		}
	}
	if(StrEqual(damageCategory, "fire"))
	{
		Address dmgMasteryAddr = TF2Attrib_GetByName(attacker, "fire damage affinity");
		if(dmgMasteryAddr != Address_Null){
			damage = Pow(damage, TF2Attrib_GetValue(dmgMasteryAddr));
			damage *= 1.0+(TF2Util_GetPlayerBurnDuration(victim)*0.05);
		}
	}
	if(StrEqual(damageCategory, "blast"))
	{
		Address dmgMasteryAddr = TF2Attrib_GetByName(attacker, "explosive damage affinity");
		if(dmgMasteryAddr != Address_Null)
			damage = Pow(damage, TF2Attrib_GetValue(dmgMasteryAddr));
		
	}
	if(StrEqual(damageCategory, "electric"))
	{
		Address dmgMasteryAddr = TF2Attrib_GetByName(attacker, "electric damage affinity");
		if(dmgMasteryAddr != Address_Null)
			damage = Pow(damage, TF2Attrib_GetValue(dmgMasteryAddr));
		
	}
	if(damagetype & DMG_CRIT)
	{
		Address dmgMasteryAddr = TF2Attrib_GetByName(attacker, "crit damage affinity");
		if(dmgMasteryAddr != Address_Null)
			damage = Pow(damage, TF2Attrib_GetValue(dmgMasteryAddr));
		
	}
	if(StrEqual(damageCategory, "arcane"))
	{
		Address dmgTakenMultAddr = TF2Attrib_GetByName(victim, "arcane damage taken reduced");
		if(dmgTakenMultAddr != Address_Null)
			damage *= TF2Attrib_GetValue(dmgTakenMultAddr);

		Address dmgMasteryAddr = TF2Attrib_GetByName(attacker, "arcane damage affinity");
		if(dmgMasteryAddr != Address_Null)
			damage = Pow(damage, TF2Attrib_GetValue(dmgMasteryAddr));
	}
}