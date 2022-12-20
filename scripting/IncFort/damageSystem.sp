public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(IsValidClient3(victim))
	{
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
		if(IsValidClient3(attacker) && victim != attacker && IsValidEntity(inflictor))
		{
			new String:classname[128]; 
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
					new Float:burndmgMult = 1.0;
					new Address:burnMult1 = TF2Attrib_GetByName(weapon, "shot penetrate all players");
					new Address:burnMult2 = TF2Attrib_GetByName(weapon, "weapon burn dmg increased");
					new Address:burnMult3 = TF2Attrib_GetByName(weapon, "weapon burn dmg reduced");
					new Address:burnMult4 = TF2Attrib_GetByName(attacker, "weapon burn dmg increased");
					new Address:burnDivide = TF2Attrib_GetByName(weapon, "dmg penalty vs players");
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
					damage = (0.33*TF2_GetDPSModifiers(attacker, weapon, false, false)*burndmgMult);
				}
				//PrintToServer("%i damagebit", damagetype);
				if(damagetype & DMG_SONIC+DMG_PREVENT_PHYSICS_FORCE+DMG_RADIUS_MAX)//Transient Moonlight
				{
					damage += (10.0 + (Pow(ArcaneDamage[attacker] * Pow(ArcanePower[attacker], 4.0), 2.45) * damage));
					new Address:lameMult = TF2Attrib_GetByName(weapon, "dmg penalty vs players");
					if(lameMult != Address_Null)//lame. AP applies twice.
					{
						damage /= TF2Attrib_GetValue(lameMult);
					}
				}
				if(LightningEnchantmentDuration[attacker] > 0.0 && !(damagetype & DMG_VEHICLE))
				{
					//Normalize all damage to become the same theoretical DPS you'd get with 20 attacks per second.
					damage += (LightningEnchantment[attacker] / TF2_GetFireRate(attacker,weapon,0.6)) * 20.0;
				}
				else if(DarkmoonBladeDuration[attacker] > 0.0)
				{
					new melee = GetWeapon(attacker,2);
					if(IsValidEntity(melee) && melee == weapon)
					{
						damage += DarkmoonBlade[attacker];
					}
				}
				new Address:arcaneWeaponScaling = TF2Attrib_GetByName(weapon,"arcane weapon scaling");
				if(arcaneWeaponScaling != Address_Null)
				{
					damage += (10.0 + (Pow(ArcaneDamage[attacker] * Pow(ArcanePower[attacker], 4.0), 2.45) * TF2Attrib_GetValue(arcaneWeaponScaling)));
				}
				new Float:tickRate = 1.0/GetTickInterval();

				for(int i = 1 ; i < 6 ; i++)
				{
					if(weaponFireRate[weapon] >= tickRate/i)
					{
						tickRate /= i;
						damage *= 1.0+((weaponFireRate[weapon]-tickRate)/tickRate);
						break;
					}
				}
			}
		}
		//PrintToServer("triggered OnTakeDamageAlive");
		new Address:DamageMultiplier = TF2Attrib_GetByName(victim, "sniper zoom penalty");
		if(DamageMultiplier != Address_Null)
		{
			damage *= TF2Attrib_GetValue(DamageMultiplier);
		}
		new Address:DamageMultiplier2 = TF2Attrib_GetByName(victim, "crit mod disabled hidden");
		if(DamageMultiplier2 != Address_Null)
		{
			damage *= TF2Attrib_GetValue(DamageMultiplier2);
		}
	
		new Address:bossType = TF2Attrib_GetByName(victim, "damage force increase text");
		if(bossType != Address_Null && TF2Attrib_GetValue(bossType) > 0.0)
		{
			new Float:bossValue = TF2Attrib_GetValue(bossType);
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
						for(new i=1;i<MaxClients;i++)
						{
							if(IsValidClient3(i) && IsOnDifferentTeams(victim,i) && !IsClientObserver(i) && IsPlayerAlive(i))
							{
								new Float:fOrigin[3],Float:fVictimPos[3];
								GetClientAbsOrigin(i, fOrigin)
								GetClientAbsOrigin(victim,fVictimPos);
								if(GetVectorDistance(fOrigin,fVictimPos) <= 1000.0)
								{
									new iEntity = CreateEntityByName("tf_projectile_lightningorb");
									if (IsValidEdict(iEntity)) 
									{
										new iTeam = GetClientTeam(victim)
										new Float:fAngles[3]
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
	if(IsValidClient(victim))
	{
		new Float:pctArmor = (fl_AdditionalArmor[victim] + fl_CurrentArmor[victim])/fl_MaxArmor[victim];
		if(pctArmor <= 0.0)
		{
			pctArmor = 0.01
		}
		if(fl_ArmorCap[victim] < 1.0)
		{
			fl_ArmorCap[victim] = 1.0;
		}
		damage /= ((1-fl_ArmorCap[victim])-((1-fl_ArmorCap[victim])*pctArmor) + fl_ArmorCap[victim]);
		new VictimCWeapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(VictimCWeapon))
		{
			new Address:ResistanceWhileHeld = TF2Attrib_GetByName(VictimCWeapon, "SET BONUS: mystery solving time decrease");
			if(ResistanceWhileHeld != Address_Null)
			{
				new Float:dmgDivisor = TF2Attrib_GetValue(ResistanceWhileHeld);
				damage = (damage / dmgDivisor);
			}	
			new Address:DodgeWhileHeld = TF2Attrib_GetByName(VictimCWeapon, "SET BONUS: chance of hunger decrease");
			if(DodgeWhileHeld != Address_Null)
			{
				new Float:dodgeChance = TF2Attrib_GetValue(DodgeWhileHeld);
				if(dodgeChance >= GetRandomFloat(0.0, 1.0))
				{
					damage *= 0.0;
					//PrintToConsole(victim, "Attack Dodged!");
					return Plugin_Changed;
				}
			}	
		}
		new Address:DodgeBody = TF2Attrib_GetByName(victim, "SET BONUS: chance of hunger decrease");
		if(DodgeBody != Address_Null)
		{
			new Float:dodgeChance = TF2Attrib_GetValue(DodgeBody);
			if(dodgeChance >= GetRandomFloat(0.0, 1.0))
			{
				damage *= 0.0;
				//PrintToConsole(victim, "Attack Dodged!");
				return Plugin_Changed;
			}
		}
		new Address:rootedDamage = TF2Attrib_GetByName(victim, "rooted damage taken");
		if(rootedDamage != Address_Null && TF2Attrib_GetValue(rootedDamage) > 1.0)
		{
			damage = Pow(damage, (1.0/TF2Attrib_GetValue(rootedDamage)));
		}
	}
	if(IsValidClient3(attacker) && IsValidClient3(victim) && IsValidWeapon(weapon))
	{
		char damageCategory[64] 
		damageCategory = getDamageCategory(damagetype);

		if(StrEqual(damageCategory, "direct"))
		{
			new Address:dmgTakenMultAddr = TF2Attrib_GetByName(victim, "direct damage taken reduced");
			if(dmgTakenMultAddr != Address_Null)
				damage *= TF2Attrib_GetValue(dmgTakenMultAddr);
		}

		if(StrEqual(damageCategory, "arcane"))
		{
			new Address:dmgTakenMultAddr = TF2Attrib_GetByName(victim, "arcane damage taken reduced");
			if(dmgTakenMultAddr != Address_Null)
				damage *= TF2Attrib_GetValue(dmgTakenMultAddr);
		}

		new String:weaponClassName[128]; 
		GetEntityClassname(weapon, weaponClassName, sizeof(weaponClassName));
		if(StrContains(weaponClassName, "tf_weapon") != -1)
		{
			if(attacker != victim)
			{
				new itemIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
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
					if(MadmilkDuration[victim] < 6.0)
					{
						MadmilkDuration[victim] = 6.0;
						MadmilkInflictor[victim] = attacker;
					}
				}
			}
			new Address:MadMilkOnhit = TF2Attrib_GetByName(weapon, "armor piercing");
			if(MadMilkOnhit != Address_Null)
			{
				new Float:value = TF2Attrib_GetValue(MadMilkOnhit);
				if(MadmilkDuration[victim] < value)
				{
					MadmilkDuration[victim] = value
					MadmilkInflictor[victim] = attacker;
				}
			}
		}
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
			}
		}
		new Address:vampirePowerup = TF2Attrib_GetByName(victim, "unlimited quantity");//Vampire Powerup
		if(vampirePowerup != Address_Null)
		{
			new Float:vampirePowerupValue = TF2Attrib_GetValue(vampirePowerup);
			if(vampirePowerupValue > 0.0)
			{
				damage *= 0.75;
			}
		}
		new Address:revengePowerup = TF2Attrib_GetByName(victim, "sniper penetrate players when charged");//Vampire Powerup
		if(revengePowerup != Address_Null)
		{
			new Float:revengePowerupValue = TF2Attrib_GetValue(revengePowerup);
			if(revengePowerupValue > 0.0)
			{
				damage *= 0.8;
			}
		}
		new Address:regenerationPowerup = TF2Attrib_GetByName(victim, "recall");//Vampire Powerup
		if(regenerationPowerup != Address_Null)
		{
			new Float:regenerationPowerupValue = TF2Attrib_GetValue(regenerationPowerup);
			if(regenerationPowerupValue > 0.0)
			{
				damage *= 0.75;
			}
		}

		new Address:knockoutPowerupVictim = TF2Attrib_GetByName(victim, "taunt is press and hold");
		if(knockoutPowerupVictim != Address_Null)
		{
			new Float:knockoutPowerupValue = TF2Attrib_GetValue(knockoutPowerupVictim);
			if(knockoutPowerupValue > 0.0){
				damage *= 0.8;
			}
		}
		
		new Address:kingPowerup = TF2Attrib_GetByName(victim, "attack projectiles");
		if(kingPowerup != Address_Null && TF2Attrib_GetValue(kingPowerup) > 0.0)
		{
			damage *= 0.8;
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
					}
				}
			}
		}
		new Address:plaguePowerup = TF2Attrib_GetByName(victim, "disable fancy class select anim");
		if(plaguePowerup != Address_Null && TF2Attrib_GetValue(plaguePowerup) > 0.0)
		{
			damage *= 0.7;
		}
		
		new Address:supernovaPowerupVictim = TF2Attrib_GetByName(victim, "spawn with physics toy");
		if(supernovaPowerupVictim != Address_Null && TF2Attrib_GetValue(supernovaPowerupVictim) > 0.0)
		{
			damage *= 0.8;
		}
		
		new Address:strengthPowerup = TF2Attrib_GetByName(attacker, "crit kill will gib");
		if(strengthPowerup != Address_Null)
		{
			new Float:strengthPowerupValue = TF2Attrib_GetValue(strengthPowerup);
			if(strengthPowerupValue > 0.0){
				damagetype |= DMG_NOCLOSEDISTANCEMOD;
				damage *= 2.0;
			}
		}
		
		new Address:revengePowerupAttacker = TF2Attrib_GetByName(attacker, "sniper penetrate players when charged");
		if(revengePowerupAttacker != Address_Null)
		{
			if(RageActive[attacker] == true && TF2Attrib_GetValue(revengePowerupAttacker) > 0.0)
			{
				damage *= 1.5;
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
				damage *= 1.35;
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
		}
		
		new Address:knockoutPowerup = TF2Attrib_GetByName(attacker, "taunt is press and hold");
		if(knockoutPowerup != Address_Null)
		{
			new Float:knockoutPowerupValue = TF2Attrib_GetValue(knockoutPowerup);
			if(knockoutPowerupValue > 0.0){
				if(_:TF2II_GetListedItemSlot(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"),TF2_GetPlayerClass(attacker)) == 2)
				{
					damage *= 1.75
				}
			}
		}
		new Address:bleedBuild = TF2Attrib_GetByName(weapon, "sapper damage bonus");
		if(bleedBuild != Address_Null)
		{
			BleedBuildup[victim] += TF2Attrib_GetValue(bleedBuild);
			if(BleedBuildup[victim] >= BleedMaximum[victim])
			{
				BleedBuildup[victim] = 0.0;
				
				new Float:bleedBonus = 1.0;
				new Address:vampirePowerupAttacker = TF2Attrib_GetByName(attacker, "unlimited quantity");
				if(vampirePowerupAttacker != Address_Null && TF2Attrib_GetValue(vampirePowerupAttacker) > 0.0)
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
		return Plugin_Changed;
	}else if(IsValidClient3(victim) && miniCritStatus[victim] == false && IsValidClient3(attacker) && 
	(critType == CritType_MiniCrit || miniCritStatusAttacker[attacker] > 0.0 || miniCritStatusVictim[victim] > 0.0))
	{
		if(debugMode)
			PrintToChat(attacker, "minicrit override 1");
		miniCritStatus[victim] = true;
		damage *= 1.4;
		critType = CritType_None;
		if(damagetype & DMG_CRIT)
			damagetype &= ~DMG_CRIT;
		
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
			new Address:critDamageMult = TF2Attrib_GetByName(weapon, "mod medic killed marked for death ");
			if(critDamageMult != Address_Null)
				damage *= TF2Attrib_GetValue(critDamageMult);
		}
		damage += lastDamageTaken[victim];
		critType = CritType_None
		lastDamageTaken[victim] = 0.0;
		return Plugin_Changed;
	}
	else if(IsValidClient3(victim) && lastDamageTaken[victim] != 0.0 && miniCritStatus[victim] == false && IsValidClient3(attacker) 
	&& (critType == CritType_MiniCrit || miniCritStatusAttacker[attacker] > 0.0 || miniCritStatusVictim[victim] > 0.0))
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
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(damagetype & DMG_CRIT)
	{
		critStatus[victim] = true
		damagetype &= ~DMG_CRIT;
		damage *= 2.25
	}
	if(damagetype & DMG_USEDISTANCEMOD)
		damagetype -= DMG_USEDISTANCEMOD;

	if (!IsValidClient3(inflictor) && IsValidEdict(inflictor))
	{
		damage = genericSentryDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
	}
	if(IsValidClient3(victim) && IsValidClient3(attacker))
	{
		damage = genericPlayerDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
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
		if (!IsValidClient3(inflictor) && IsValidEdict(inflictor))
		{
			damage = genericSentryDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
		}
		damage = genericPlayerDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
	}
	if(damage < 0.0)
	{
		damage = 0.0;
	}
	if(IsValidEntity(logic))
	{
		new round = GetEntProp(logic, Prop_Send, "m_nMannVsMachineWaveCount");
		damage *= (Pow(7500.0/waveToCurrency[round], DefenseMod + (DefenseIncreasePerWaveMod * round)) * 6.0)/OverallMod;
		//PrintToChat(attacker,"%.2f", damage);
	}
	return Plugin_Changed;
}

public Action:OnTakeDamagePre_Sapper(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom) 
{
	new owner = GetEntPropEnt(victim, Prop_Send, "m_hBuilder"); 
	if(!IsClientInGame(owner))
	{
		return Plugin_Continue;
	}
	if(!IsClientInGame(attacker))
	{
		return Plugin_Continue;
	}
	damage = 50.0;
	new melee = (GetWeapon(attacker,2));
	new Address:firerate = TF2Attrib_GetByName(melee, "fire rate bonus HIDDEN");
	if(firerate != Address_Null)
	{
		new Float:dmgpenalty = TF2Attrib_GetValue(firerate);
		damage *= dmgpenalty;
	}
	new Address:firerate1 = TF2Attrib_GetByName(melee, "fire rate bonus");
	if(firerate1 != Address_Null)
	{
		new Float:dmgpenalty = TF2Attrib_GetValue(firerate1);
		damage *= dmgpenalty;
	}
	return Plugin_Changed;
}

public Action:OnTakeDamagePre_Sentry(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom) 
{
	new owner = GetEntPropEnt(victim, Prop_Send, "m_hBuilder");
	new String:SapperObject[128];
	GetEdictClassname(attacker, SapperObject, sizeof(SapperObject));
	if (StrEqual(SapperObject, "obj_attachment_sapper"))
	{
		new BuildingMaxHealth = GetEntProp(victim, Prop_Send, "m_iMaxHealth");
		damage = float(RoundToCeil(BuildingMaxHealth/110.0)); // in 150 ticks the sentry will be destroyed.

		new SapperOwner = GetEntPropEnt(attacker, Prop_Send, "m_hBuilder");
		if(IsValidClient3(SapperOwner))
		{
			new sapperItem = GetWeapon(SapperOwner, 6);
			if(IsValidEntity(sapperItem))
			{
				new Address:LifestealActive = TF2Attrib_GetByName(sapperItem,"mult airblast refire time");
				if(LifestealActive != Address_Null)
				{
					new HealthGained = RoundToCeil(damage * TF2Attrib_GetValue(LifestealActive))
					AddPlayerHealth(SapperOwner, HealthGained, 1.0, true, attacker);
					fl_CurrentArmor[SapperOwner] += float(HealthGained) * 0.2;
				}
				new Address:DamageActive = TF2Attrib_GetByName(sapperItem,"sapper damage bonus");
				if(DamageActive != Address_Null)
				{
					damage *= TF2Attrib_GetValue(DamageActive);
				}
			}
		}
		return Plugin_Changed; //Prevent any other modification to damage.
	}
	if (!IsValidClient3(inflictor) && IsValidEdict(inflictor))
	{
		damage = genericSentryDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
	}
	if(IsValidClient3(attacker) && victim != attacker)
	{
		damage = genericPlayerDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
		if(IsValidWeapon(weapon))
		{
			if(LightningEnchantmentDuration[attacker] > 0.0 && !(damagetype & DMG_VEHICLE))
			{
				//Normalize all damage to become the same theoretical DPS you'd get with 20 attacks per second.
				damage += (LightningEnchantment[attacker] / TF2_GetFireRate(attacker,weapon,0.6)) * 20.0;
			}
			else if(DarkmoonBladeDuration[attacker] > 0.0)
			{
				new melee = GetWeapon(attacker,2);
				if(IsValidWeapon(melee) && melee == weapon)
				{
					damage += DarkmoonBlade[attacker];
				}
			}
			//PrintToServer("%i damagebit", damagetype);
			if(damagetype & DMG_SONIC+DMG_PREVENT_PHYSICS_FORCE+DMG_RADIUS_MAX)//Transient Moonlight
			{
				damage += (10.0 + (Pow(ArcaneDamage[attacker] * Pow(ArcanePower[attacker], 4.0), 2.45) * damage));
				new Address:lameMult = TF2Attrib_GetByName(weapon, "dmg penalty vs players");
				if(lameMult != Address_Null)//lame. AP applies twice.
				{
					damage /= TF2Attrib_GetValue(lameMult);
				}
			}
			new Address:arcaneWeaponScaling = TF2Attrib_GetByName(weapon,"arcane weapon scaling");
			if(arcaneWeaponScaling != Address_Null)
			{
				damage += (10.0 + (Pow(ArcaneDamage[attacker] * Pow(ArcanePower[attacker], 4.0), 2.45) * TF2Attrib_GetValue(arcaneWeaponScaling)));
			}
			new Float:tickRate = 1.0/GetTickInterval();

			for(int i = 1 ; i < 6 ; i++)
			{
				if(weaponFireRate[weapon] >= tickRate/i)
				{
					tickRate /= i;
					damage *= 1.0+((weaponFireRate[weapon]-tickRate)/tickRate);
					break;
				}
			}
		}
		if(TF2_IsPlayerMinicritBuffed(attacker))
		{
			damage *= 1.4;
		}
		if(GetEntProp(victim, Prop_Send, "m_bDisabled") == 1)
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
	}
	if(IsValidClient(owner))
	{
		new Float:pctArmor = (fl_AdditionalArmor[owner] + fl_CurrentArmor[owner])/fl_MaxArmor[owner];
		if(pctArmor <= 0.0)
		{
			pctArmor = 0.01
		}
		new Float:armorAmt = fl_ArmorCap[owner] * 2.0;
		damage /= ((1-armorAmt)-((1-armorAmt)*pctArmor) + armorAmt);
		new Address:sentryRes = TF2Attrib_GetByName(owner, "blast dmg to self increased");
		if(sentryRes != Address_Null)
		{
			damage /= TF2Attrib_GetValue(sentryRes);
		}
		fl_CurrentArmor[owner] -= damage*0.8;
		if(fl_CurrentArmor[owner] < 0.0)
			fl_CurrentArmor[owner] = 0.0
	}
	return Plugin_Changed;
}
public float genericPlayerDamageModification(victim, attacker, inflictor, float damage, weapon, damagetype, damagecustom)
{
	new bool:isVictimPlayer = IsValidClient3(victim);

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
	}
	if(TF2_IsPlayerInCondition(attacker, TFCond_DisguiseRemoved))
	{
		damage *= 1.8;
	}
	if(IsValidWeapon(weapon))
	{
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
		if (damagecustom == TF_CUSTOM_BACKSTAB)
		{
			new bool:ToggleBackstab = true;
			new Address:canBeBackstabbed = TF2Attrib_GetByName(victim, "set item tint RGB");
			if(canBeBackstabbed != Address_Null && TF2Attrib_GetValue(canBeBackstabbed) != 0.0)
			{
				ToggleBackstab = false;
			}
			if(ToggleBackstab == true)
			{
				damage = 450.0 * TF2_GetDamageModifiers(attacker,weapon);
				
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
				
				return damage;
			}
		}
		if(isVictimPlayer && attacker != victim)
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
			if(TF2_IsPlayerInCondition(victim,TFCond_TmpDamageBonus))
			{
				damage *= 1.3;
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
		if(isVictimPlayer)
		{
			new Float:burndmgMult = 1.0;
			new Address:burnMult10 = TF2Attrib_GetByName(weapon, "shot penetrate all players");
			new Address:burnMult11 = TF2Attrib_GetByName(weapon, "weapon burn dmg increased");

			if(burnMult10 != Address_Null) {burndmgMult*=TF2Attrib_GetValue(burnMult10);}
			if(burnMult11 != Address_Null) {burndmgMult*=TF2Attrib_GetValue(burnMult11);}

			new Address:FireDamageActive = TF2Attrib_GetByName(weapon, "flame_ignore_player_velocity");
			if(GetClientTeam(attacker) != GetClientTeam(victim) && FireDamageActive != Address_Null && TF2Attrib_GetValue(FireDamageActive) > 0.1 &&
			TF2_GetDPSModifiers(attacker, weapon)*burndmgMult >= fl_HighestFireDamage[victim] && 
			!(damagetype & DMG_BURN && damagetype & DMG_PREVENT_PHYSICS_FORCE) && !(damagetype & DMG_ENERGYBEAM)) // New afterburn system.
			{
				new Float:afterburnDuration = 2.0;
				new Address:FireDurationActive = TF2Attrib_GetByName(weapon, "weapon burn time increased");
				if(FireDurationActive != Address_Null)
				{
					afterburnDuration *= TF2Attrib_GetValue(FireDurationActive);
				}
				TF2Util_IgnitePlayer(victim, attacker, afterburnDuration, weapon);
				damagetype |= DMG_PLASMA;
				fl_HighestFireDamage[victim] = TF2_GetDPSModifiers(attacker, weapon)*burndmgMult;
			}
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
		if (damagecustom == 46 && damagetype & DMG_SHOCK)
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
		if(damagecustom == TF_CUSTOM_BASEBALL)
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
			damage *= Pow(1.05,TF2Attrib_GetValue(damageActive));
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
		if(isVictimPlayer)
		{
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
	return damage;
}
public float genericSentryDamageModification(victim, attacker, inflictor, float damage, weapon, damagetype, damagecustom)
{
	new String:classname[128]; 
	GetEdictClassname(inflictor, classname, sizeof(classname)); 
	new weaponIdx = (IsValidWeapon(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);

	new bool:isVictimPlayer = IsValidClient3(victim);

	if (isVictimPlayer && StrEqual(classname, "obj_attachment_sapper"))
	{
		TF2_AddCondition(victim, TFCond_Sapped, 2.0);
	}
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
						damage *= Pow(1.05,TF2Attrib_GetValue(damageActive));
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
	return damage;
}