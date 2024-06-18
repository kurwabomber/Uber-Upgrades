public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, float &damage, &damagetype, &weapon, float damageForce[3], float damagePosition[3], damagecustom)
{
	//PrintToServer("triggered ontakedamagealive");
	if(currentDamageType[attacker].first == 0)
		currentDamageType[attacker].first = damagetype;
	
	if(IsValidClient3(victim))
	{
		lastKBSource[victim] = attacker;
		if(GetAttribute(victim, "resistance powerup", 0.0) == 2.0){
			if(frayNextTime[victim] <= currentGameTime){
				damage = 0.0;
				frayNextTime[victim] = currentGameTime+1.0
				float position[3], patientPosition[3];
				GetClientAbsOrigin(victim, position);

				for(int i = 1;i<=MaxClients;++i){
					if(!IsValidClient3(i))
						continue;
					if(IsOnDifferentTeams(victim, i))
						continue;

					GetClientAbsOrigin(i, patientPosition);
					if(GetVectorDistance(position, patientPosition, true) > 250000)
						continue;

					giveDefenseBuff(i, 3.0);
					TF2_AddCondition(i, TFCond_SpeedBuffAlly, 3.0);
				}
				return Plugin_Stop;
			}
		}
		if(IsPlayerInSpawn(victim))
		{
			if(victim == attacker)
			{
				damage = 1.0;
				currentDamageType[attacker].clear();
				return Plugin_Changed;
			}
			else
			{
				if(IsValidClient3(attacker) && TF2_IsPlayerInCondition(attacker, TFCond_CritOnWin))
				{
					damage *= 2.0;
				}
				else
				{
					damage = 0.001;
					currentDamageType[attacker].clear();
					return Plugin_Changed;
				}
			}
		}
		if(attacker == victim){
			float dmgReduction = TF2Attrib_HookValueFloat(1.0, "dmg_incoming_mult", victim);
			if(dmgReduction != 1.0)
				damage *= dmgReduction

			float linearReduction = GetAttribute(victim, "dmg taken divided");
			if(linearReduction != 1.0)
				damage /= linearReduction;

			if(!(currentDamageType[attacker].second & DMG_PIERCING) && !IsFakeClient(victim)){
				damage /= GetResistance(victim);
			}
		}
		if(IsValidClient3(attacker) && victim != attacker)
		{
			bool isSentry = false;
			if(IsValidEdict(inflictor)){
				char classname[32]; 
				GetEdictClassname(inflictor, classname, sizeof(classname));
				isSentry = !strcmp("obj_sentrygun", classname) || !strcmp("tf_projectile_sentryrocket", classname);
			}

			if(IsValidWeapon(weapon) && !isSentry)
			{
				if(InfernalEnchantmentDuration[attacker] >= currentGameTime){
					Buff infernalDOT; infernalDOT.init("Infernal Flames", "", Buff_InfernalDOT, 1, attacker, 8.0);
					insertBuff(victim, infernalDOT);
				}
				if(damagetype & DMG_SLASH){
					if(GetAttribute(attacker, "knockout powerup", 0.0) == 2 && TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee){
						damage *= 5;
					}
				}
			}
		}
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
						TF2_AddCondition(victim, TFCond_UberchargedHidden, 0.5);
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
						TF2_AddCondition(victim, TFCond_UberchargedHidden, 0.5);
						TF2_AddCondition(victim, TFCond_RuneAgility, 5.0);
						
						//eventually add the vortex tp back thing
						bossPhase[victim]++;
					}
				}
				case 7.0:
				{
					if (!TF2_IsPlayerInCondition(victim,TFCond_UberchargedHidden) && GetClientHealth(victim) - damage < TF2_GetMaxHealth(victim) - (TF2_GetMaxHealth(victim)*(0.5*(bossPhase[victim]+1))))//boss phases
					{
						damage = GetClientHealth(victim) - (TF2_GetMaxHealth(victim) - (TF2_GetMaxHealth(victim)*(0.25*(bossPhase[victim]+1))));
						TF2_AddCondition(victim, TFCond_MegaHeal, 5.0);
						TF2_AddCondition(victim, TFCond_UberchargedHidden, 0.5);
						for(int i=1;i<=MaxClients;++i)
						{
							if(IsValidClient3(i) && IsOnDifferentTeams(victim,i) && !IsClientObserver(i) && IsPlayerAlive(i))
							{
								float fOrigin[3], fVictimPos[3];
								GetClientAbsOrigin(i, fOrigin)
								GetClientAbsOrigin(victim,fVictimPos);
								if(GetVectorDistance(fOrigin,fVictimPos, true) <= 1000000.0)
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
	int VictimCWeapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");

	if(IsValidClient3(attacker)){
		int healers = GetEntProp(attacker, Prop_Send, "m_nNumHealers");
		for(int i = 0;i<healers;++i){
			int healer = TF2Util_GetPlayerHealer(attacker,i);
			if(!IsValidClient3(healer))
				continue;

			int healingWeapon = GetWeapon(healer, 1);
			if(!IsValidWeapon(healingWeapon))
				continue;

			if(GetAttribute(healingWeapon, "magnify patient damage", 0.0))
				pylonCharge[healer] += damage;

			if(currentDamageType[healer].second & DMG_IGNOREHOOK)
				continue;

			float pylonCap = 10.0*TF2Util_GetEntityMaxHealth(healer);
			if(pylonCharge[healer] >= pylonCap){
				float pylonDamage = 0.15 * pylonCap * GetResistance(healer);

				bool isBounced[MAXPLAYERS+1];
				isBounced[victim] = true
				int lastBouncedTarget = victim;
				float lastBouncedPosition[3], startpos[3];
				GetClientEyePosition(healer, startpos)
				GetClientEyePosition(lastBouncedTarget, lastBouncedPosition)
				int iterations = 0
				int maxBounces = 5;

				char szCtrlParti[32];
				char particleName[32];
				particleName = GetClientTeam(attacker) == 2 ? "dxhr_sniper_rail_red" : "dxhr_sniper_rail_blue";

				{
					int iPart1 = CreateEntityByName("info_particle_system");
					int iPart2 = CreateEntityByName("info_particle_system");

					if (IsValidEdict(iPart1) && IsValidEdict(iPart2))
					{
						Format(szCtrlParti, sizeof(szCtrlParti), "tf2ctrlpart%i", iPart2);
						DispatchKeyValue(iPart2, "targetname", szCtrlParti);

						DispatchKeyValue(iPart1, "effect_name", particleName);
						DispatchKeyValue(iPart1, "cpoint1", szCtrlParti);
						DispatchSpawn(iPart1);
						TeleportEntity(iPart1, startpos, NULL_VECTOR, NULL_VECTOR);
						TeleportEntity(iPart2, lastBouncedPosition, NULL_VECTOR, NULL_VECTOR);
						ActivateEntity(iPart1);
						AcceptEntityInput(iPart1, "Start");
						
						CreateTimer(1.0, Timer_KillParticle, EntIndexToEntRef(iPart1));
						CreateTimer(1.0, Timer_KillParticle, EntIndexToEntRef(iPart2));
					}
				}
				currentDamageType[healer].second |= DMG_IGNOREHOOK;
				SDKHooks_TakeDamage(victim,healer,healer,0.15*pylonDamage,DMG_BULLET,_,_,_,false)

				for(int client=1;client<=MaxClients && iterations < maxBounces;client++)
				{
					if(!IsValidClient3(client)) {continue;}
					if(!IsPlayerAlive(client)) {continue;}
					if(!IsOnDifferentTeams(client,attacker)) {continue;}
					if(isBounced[client]) {continue;}

					float VictimPos[3]; 
					GetClientEyePosition(client, VictimPos); 
					if(GetVectorDistance(lastBouncedPosition, VictimPos, true) > 490000.0) {continue;}//700 HU range
					
					isBounced[client] = true;
					GetClientEyePosition(lastBouncedTarget, lastBouncedPosition)
					lastBouncedTarget = client
					int iPart1 = CreateEntityByName("info_particle_system");
					int iPart2 = CreateEntityByName("info_particle_system");

					if (IsValidEdict(iPart1) && IsValidEdict(iPart2))
					{
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
					currentDamageType[healer].second |= DMG_IGNOREHOOK;
					SDKHooks_TakeDamage(client,healer,healer,0.15*pylonDamage,DMG_BULLET,_,_,_,false)
					++iterations
				}

				pylonCharge[healer] -= pylonCap;
				if(pylonCharge[healer] > pylonCap)
					pylonCharge[healer]  = pylonCap;
				EmitSoundToAll(SOUND_ARCANESHOOT, 1, _, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,startpos);
			}
		}
	}
	if(IsValidClient3(attacker) && IsValidClient3(victim))
	{
		char damageCategory[64];
		damageCategory = getDamageCategory(currentDamageType[attacker], attacker);

		applyDamageAffinities(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom, damageCategory);

		if(IsValidWeapon(weapon)){
			char weaponClassName[64]; 
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
						if(GetAttribute(victim, "inverter powerup", 0.0) == 1.0){
							MadmilkDuration[attacker] = currentGameTime+6.0;
							MadmilkInflictor[attacker] = victim;
						}
						else if(GetAttribute(victim, "inverter powerup", 0.0) == 2.0){
							MadmilkDuration[victim] = currentGameTime+12.0;
							MadmilkInflictor[victim] = victim;
						}
						else if(MadmilkDuration[victim] < currentGameTime+6.0)
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

					if(GetAttribute(victim, "inverter powerup", 0.0) == 1){
						MadmilkDuration[attacker] = currentGameTime+value;
						MadmilkInflictor[attacker] = victim;
					}
					else if(GetAttribute(victim, "inverter powerup", 0.0) == 2.0){
						MadmilkDuration[victim] = currentGameTime+2*value;
						MadmilkInflictor[victim] = victim;
					}
					else if(MadmilkDuration[victim] < currentGameTime+value)
					{
						MadmilkDuration[victim] = currentGameTime+value
						MadmilkInflictor[victim] = attacker;
					}
				}
			}

			if(attacker != victim && GetAttribute(attacker, "inverter powerup", 0.0) == 2){
				if(hasBuffIndex(attacker, Buff_CritMarkedForDeath)){
					Buff critligma;
					critligma.init("Marked for Crits", "All hits taken are critical", Buff_CritMarkedForDeath, 1, victim, 8.0);
					insertBuff(victim, critligma);
				}
				if(MadmilkDuration[attacker] > currentGameTime){
					if(MadmilkDuration[victim] > MadmilkDuration[attacker]){
						MadmilkDuration[victim] = MadmilkDuration[attacker];
					}
				}
				if(TF2_IsPlayerInCondition(attacker, TFCond_Bleeding)){
					TF2Util_MakePlayerBleed(victim, attacker, 8.0, weapon, 8);
				}
				if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire)){
					TF2Util_IgnitePlayer(victim, attacker, 10.0, weapon);
				}
				if(TF2_IsPlayerInCondition(attacker, TFCond_Dazed) || TF2_IsPlayerInCondition(attacker, TFCond_FreezeInput)){
					TF2_StunPlayer(victim, 0.35, _, TF_STUNFLAGS_BIGBONK);
				}
			}

			Address bleedBuild = TF2Attrib_GetByName(weapon, "sapper damage bonus");
			if(bleedBuild != Address_Null && !(damagetype & DMG_PREVENT_PHYSICS_FORCE && damagetype & DMG_BURN))//Specifically doesn't apply on afterburn, but works on bleeding DOT.
			{
				float bleedAdd = TF2Attrib_GetValue(bleedBuild);
				if(GetAttribute(attacker, "knockout powerup", 0.0) == 2 && TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee)
					bleedAdd *= 3;

				if(hasBuffIndex(attacker, Buff_Plunder)){
					Buff plunderBuff;
					plunderBuff = playerBuffs[attacker][getBuffInArray(attacker, Buff_Plunder)]
					bleedAdd *= plunderBuff.severity;
				}

				BleedBuildup[victim] += bleedAdd;

				checkBleed(victim, attacker, weapon);
			}
			Address radiationBuild = TF2Attrib_GetByName(weapon, "accepted wedding ring account id 1");
			if(!(damagetype & DMG_PREVENT_PHYSICS_FORCE) && radiationBuild != Address_Null)
			{
				float radiationAdd = TF2Attrib_GetValue(radiationBuild);
				if(GetAttribute(attacker, "knockout powerup", 0.0) == 2 && TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee)
					radiationAdd *= 3;

				if(hasBuffIndex(attacker, Buff_Plunder)){
					Buff plunderBuff;
					plunderBuff = playerBuffs[attacker][getBuffInArray(attacker, Buff_Plunder)]
					radiationAdd *= plunderBuff.severity;
				}

				RadiationBuildup[victim] += radiationAdd;
				checkRadiation(victim,attacker);
			}
		}
		if(IsValidEdict(inflictor))
			ShouldNotHome[inflictor][victim] = true;
		if(damagetype == (DMG_RADIATION+DMG_DISSOLVE))//Radiation.
		{
			if(GetAttribute(attacker, "knockout powerup", 0.0) == 2)
				damage *= 3;
			if(hasBuffIndex(attacker, Buff_Plunder)){
				Buff plunderBuff;
				plunderBuff = playerBuffs[attacker][getBuffInArray(attacker, Buff_Plunder)]
				damage *= plunderBuff.severity;
			}
			RadiationBuildup[victim] += damage;
			checkRadiation(victim,attacker);
		}

		if(GetAttribute(attacker, "inverter powerup", 0.0) == 3){
			Buff nullification;
			nullification.init("Nullification", "No status effects", Buff_Nullification, 1, victim, 2.0);
			insertBuff(victim, nullification);

			TF2_RemoveCondition(victim, TFCond_Ubercharged);
			TF2_RemoveCondition(victim, TFCond_Cloaked);
			TF2_RemoveCondition(victim, TFCond_Disguised);
			TF2_RemoveCondition(victim, TFCond_MegaHeal);
			TF2_RemoveCondition(victim, TFCond_DefenseBuffNoCritBlock);
			TF2_RemoveCondition(victim, TFCond_DefenseBuffMmmph);
			TF2_RemoveCondition(victim, TFCond_UberchargedHidden);
			TF2_RemoveCondition(victim, TFCond_UberBulletResist);
			TF2_RemoveCondition(victim, TFCond_UberBlastResist);
			TF2_RemoveCondition(victim, TFCond_UberFireResist);
			TF2_RemoveCondition(victim, TFCond_AfterburnImmune);
			TF2_RemoveCondition(victim, TFCond_Kritzkrieged);
			TF2_RemoveCondition(victim, TFCond_CritCanteen);
			miniCritStatusAttacker[victim] = 0.0;
		}

		if(GetAttribute(victim, "resistance powerup", 0.0) == 1 || GetAttribute(victim, "resistance powerup", 0.0) == 3)
			damage *= 0.5;

		//Just in case in the future I ever want multiple powerups...
		if(GetAttribute(victim, "revenge powerup", 0.0) == 1)
			damage *= 0.8;

		if(GetAttribute(victim, "knockout powerup", 0.0) == 1)
			damage *= 0.8;
		else if(GetAttribute(victim, "knockout powerup", 0.0) == 2)
			damage *= 0.66;

		if(GetAttribute(victim, "king powerup", 0.0) == 1)
			damage *= 0.8;
		
		if(GetAttribute(victim, "supernova powerup", 0.0) == 1)
			damage *= 0.8;

		if(GetAttribute(victim, "inverter powerup", 0.0) == 1)
			damage *= 0.8;
		else if(GetAttribute(victim, "inverter powerup", 0.0) == 2)
			damage *= 0.5;

		if(GetAttribute(victim, "regeneration powerup", 0.0) == 1)
			damage *= 0.75;

		if(GetAttribute(victim, "vampire powerup", 0.0) == 1)
			damage *= 0.75;

		//This is actually valid.
		if(1 <= GetAttribute(victim, "plague powerup", 0.0) <= 2){
			damage *= 0.75;
		}
		
		if(TF2_IsPlayerInCondition(attacker, TFCond_Plague))
		{
			int plagueInflictor = TF2Util_GetPlayerConditionProvider(attacker, TFCond_Plague);
			if(IsValidClient3(plagueInflictor))
				if(GetAttribute(plagueInflictor, "plague powerup", 0.0))
					damage /= 2.0;
		}
		
		Address strengthPowerup = TF2Attrib_GetByName(attacker, "strength powerup");
		if(strengthPowerup != Address_Null)
		{
			float strengthPowerupValue = TF2Attrib_GetValue(strengthPowerup);
			if(strengthPowerupValue == 1.0){
				damagetype |= DMG_NOCLOSEDISTANCEMOD;
				damage *= 2.0;
			}
			else if(strengthPowerupValue == 2.0 && IsValidWeapon(weapon)){
				if(weaponFireRate[weapon] < TICKRATE)
					damage *= 1+2*(weaponFireRate[weapon]/TICKRATE);
				else
					damage *= 3;
			}
			else if(strengthPowerupValue == 3.0){
				Buff finisherDebuff; finisherDebuff.init("Bruised", "Marked-for-Finisher", Buff_Bruised, 1, attacker, 8.0);
				insertBuff(victim, finisherDebuff);

				if(!(currentDamageType[attacker].second & DMG_PIERCING) && !(currentDamageType[attacker].second & DMG_IGNOREHOOK)){
					float bruisedDamage = damage;
					if(!(damagetype & DMG_CRIT)){
						bruisedDamage *= 2.25;
					}

					if(damage >= TF2Util_GetEntityMaxHealth(victim) * 0.4){
						currentDamageType[attacker].second |= DMG_PIERCING;
						currentDamageType[victim].second |= DMG_PIERCING;
						SDKHooks_TakeDamage(victim, attacker, attacker, 1.0*GetClientHealth(victim), DMG_PREVENT_PHYSICS_FORCE)
						SDKHooks_TakeDamage(attacker, victim, victim, 0.05*TF2Util_GetEntityMaxHealth(attacker), DMG_PREVENT_PHYSICS_FORCE);
					}
					else if((GetClientHealth(victim) - bruisedDamage)/TF2Util_GetEntityMaxHealth(victim) <= 0.25){
						critStatus[victim] = true;
						damage = bruisedDamage;
						currentDamageType[attacker].second |= DMG_PIERCING;
						SDKHooks_TakeDamage(victim, attacker, attacker, 0.25*TF2Util_GetEntityMaxHealth(victim), DMG_PREVENT_PHYSICS_FORCE)
					}
				}
			}
		}
		
		if(RageActive[attacker] == true && GetAttribute(attacker, "revenge powerup", 0.0) == 1)
		{
			damage *= 1.5;
			if(powerupParticle[attacker] <= currentGameTime)
			{
				CreateParticleEx(victim, "critgun_weaponmodel_red", 1, 0, damagePosition, 0.5);
				powerupParticle[attacker] = currentGameTime+0.6;
			}
		}
		if(GetAttribute(attacker, "revenge powerup", 0.0) == 2)
			damage *= 1 + RageBuildup[attacker]*0.5;
		
		if(GetAttribute(attacker, "precision powerup", 0.0) == 1)
			damage *= 1.35;
		else if(GetAttribute(attacker, "precision powerup", 0.0) == 2){
			if(IsValidEntity(inflictor) && isAimlessProjectile[inflictor]){
				float victimPosition[3];
				GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", victimPosition); 
				float projectilePosition[3];
				GetEntPropVector(inflictor, Prop_Data, "m_vecAbsOrigin", projectilePosition); 
				float distance = GetVectorDistance(victimPosition, projectilePosition);
				if(distance <= 200){
					damage *= 1+3*((200-distance)/200);
				}
			}
		}

		if(IsValidClient3(tagTeamTarget[attacker])){
			if(isTagged[tagTeamTarget[attacker]][victim]){
				if(GetAttribute(victim, "king powerup", 0.0) == 2)
					damage *= 1.75
			}
		}

		if(GetAttribute(attacker, "agility powerup", 0.0) == 2){
			float velocity[3];
			GetEntPropVector(attacker, Prop_Data, "m_vecAbsVelocity", velocity);

			if(velocity[2] < -400.0)
				damage *= 1.0 + (-velocity[2]-400.0)*0.001;
		}

		if(StunShotStun[attacker])
		{
			StunShotStun[attacker] = false;
			TF2_StunPlayer(victim, 1.5, 1.0, TF_STUNFLAGS_NORMALBONK, attacker);
		}

		Address ReflectActive = TF2Attrib_GetByName(victim, "extinguish restores health");
		if(ReflectActive != Address_Null && !(currentDamageType[attacker].second & DMG_IGNOREHOOK))
		{
			float ReflectDamage = damage;
			Address ReflectDamageMultiplier = TF2Attrib_GetByName(victim, "set cloak is movement based");
			if(ReflectDamageMultiplier != Address_Null && GetRandomInt(1, 100) < TF2Attrib_GetValue(ReflectActive) * 33.0)
			{
				float ReflectMult = TF2Attrib_GetValue(ReflectDamageMultiplier);
				ReflectDamage *= ReflectMult
				currentDamageType[victim].second |= DMG_IGNOREHOOK;
				SDKHooks_TakeDamage(attacker, victim, victim, ReflectDamage, (DMG_PREVENT_PHYSICS_FORCE+DMG_ENERGYBEAM),_,_,_,false);
			}
		}

		float victimPos[3];
		GetClientEyePosition(victim,victimPos);

		//Prevent piercing damage from being guardian'd
		if(!(currentDamageType[attacker].second & DMG_PIERCING)){
			int guardian = -1;
			float guardianPercentage;
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(!IsValidClient3(i))
					continue;
				if(!IsPlayerAlive(i))
					continue;
				if(GetClientTeam(i) != GetClientTeam(victim))
					continue;
				if(i == victim)
					continue;

				float guardianPos[3];
				GetClientEyePosition(i,guardianPos);
				if(GetVectorDistance(victimPos,guardianPos, true) < 1960000)
				{
					int guardianWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
					if(IsValidWeapon(guardianWeapon)){
						float redirect = GetAttribute(guardianWeapon, "mult cloak meter regen rate", 0.0) + GetAttribute(i, "mult cloak meter regen rate", 0.0);
						if(redirect > 0.0){
							if(redirect > guardianPercentage){
								guardian = i;
								guardianPercentage = redirect;
							}
						}
					}
					if(damage > GetClientHealth(victim) && GetAttribute(i, "king powerup", 0.0) == 3.0){
						currentDamageType[attacker].second |= DMG_IGNOREHOOK;
						SDKHooks_TakeDamage(i, attacker, attacker, damage, (DMG_PREVENT_PHYSICS_FORCE+DMG_ENERGYBEAM),_,_,_,false);
						currentDamageType[attacker].second |= DMG_PIERCING;
						currentDamageType[attacker].second |= DMG_IGNOREHOOK;
						SDKHooks_TakeDamage(i, attacker, attacker, GetClientHealth(i) * 0.15, DMG_PREVENT_PHYSICS_FORCE);
						damage *= 0.0;
						TF2_AddCondition(victim, TFCond_UberchargedCanteen, 0.5, i);
						TF2_AddCondition(i, TFCond_UberchargedCanteen, 0.1, i);
						break;
					}
				}
			}
			if(IsValidClient3(guardian) && !(currentDamageType[attacker].second & DMG_IGNOREHOOK)){
				currentDamageType[attacker].second |= DMG_IGNOREHOOK;
				SDKHooks_TakeDamage(guardian, attacker, attacker, damage*guardianPercentage,DMG_PREVENT_PHYSICS_FORCE,_,_,_,false);
				damage *= (1-guardianPercentage);
			}
		}
		if(IsValidWeapon(VictimCWeapon)){
			if(HasEntProp(VictimCWeapon, Prop_Send, "m_hHealingTarget") && miniCritStatusVictim[victim] < currentGameTime){
				if(GetAttribute(VictimCWeapon, "escape plan healing", 0.0)){
					int healingTarget = GetEntPropEnt(VictimCWeapon, Prop_Send, "m_hHealingTarget");
					if(IsValidClient3(healingTarget)){
						int medicHealth = GetClientHealth(victim);
						int patientHealth = GetClientHealth(victim);
						if(patientHealth > medicHealth && medicHealth - damage <= 10.0){
							SetEntityHealth(victim, patientHealth);
							SetEntityHealth(healingTarget, medicHealth);
							miniCritStatusVictim[victim] = currentGameTime + 10.0;
							damage *= 0.25;
						}
					}
				}
			}
			float teamTacticsRatio = GetAttribute(VictimCWeapon, "savior sacrifice attribute", 0.0);
			if(teamTacticsRatio > 0.0){
				float ratio = damage / TF2Util_GetEntityMaxHealth(victim);
				if(ratio > 1.0)
					ratio == 1.0;

				TeamTacticsBuildup[victim] += teamTacticsRatio * ratio;
				if(TeamTacticsBuildup[victim] > 0.5)
					TeamTacticsBuildup[victim] = 0.5;
			}
		}

		if(IsValidWeapon(weapon)){
			if(damagecustom == TF_CUSTOM_HEADSHOT){
				if(GetAttribute(weapon, "mult sniper charge after headshot", 0.0))
					savedCharge[attacker] = GetAttribute(weapon, "mult sniper charge after headshot", 0.0);
			}

			float fireworksChance = GetAttribute(weapon, "fireworks chance", 0.0)
			if(fireworksChance*damage/TF2Util_GetEntityMaxHealth(victim) >= GetRandomFloat() && !(currentDamageType[attacker].second & DMG_IGNOREHOOK)){
				currentDamageType[attacker].second |= DMG_PIERCING;
				currentDamageType[attacker].second |= DMG_IGNOREHOOK;
				SDKHooks_TakeDamage(victim, attacker, attacker, 1.0*GetClientHealth(victim), DMG_PREVENT_PHYSICS_FORCE);
				EmitSoundToAll(DetonatorExplosionSound, victim);
			}

			if(GetAttribute(attacker, "vampire powerup", 0.0) == 3.0 && !(currentDamageType[attacker].second & DMG_PIERCING)){
				float tempDmg = damage;
				if(GetClientHealth(attacker) - tempDmg < TF2Util_GetEntityMaxHealth(attacker)*0.2)
					tempDmg = GetClientHealth(attacker) - TF2Util_GetEntityMaxHealth(attacker)*0.2;

				if(tempDmg > 0){
					currentDamageType[attacker].second |= DMG_PIERCING;
					currentDamageType[attacker].second |= DMG_IGNOREHOOK;
					SDKHooks_TakeDamage(attacker, attacker, attacker, tempDmg, DMG_PREVENT_PHYSICS_FORCE);
					bloodboundDamage[attacker] += tempDmg;
				}

				if(bloodboundDamage[attacker] > 0){
					currentDamageType[attacker].second |= DMG_PIERCING;
					currentDamageType[attacker].second |= DMG_IGNOREHOOK;
					SDKHooks_TakeDamage(victim, attacker, attacker, bloodboundDamage[attacker], DMG_PREVENT_PHYSICS_FORCE);
					bloodboundHealing[attacker] += bloodboundDamage[attacker];
					bloodboundDamage[attacker] = 0.0
				}
			}

			if(!(currentDamageType[attacker].second & DMG_IGNOREHOOK) && !(currentDamageType[attacker].second & DMG_FROST) && !(currentDamageType[attacker].second & DMG_PIERCING) && !(damagetype == DMG_BURN + DMG_PREVENT_PHYSICS_FORCE)){ //Make sure it isn't piercing, frost or afterburn damage...
				float freezeRatio = GetAttribute(weapon, "damage causes freeze", 0.0);
				if(freezeRatio > 0){
					float frostIncrease = freezeRatio*damage/TF2Util_GetEntityMaxHealth(victim);
					if(GetAttribute(attacker, "knockout powerup", 0.0) == 2 && TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee)
						frostIncrease *= 2.0;
					if(hasBuffIndex(attacker, Buff_Plunder)){
						Buff plunderBuff;
						plunderBuff = playerBuffs[attacker][getBuffInArray(attacker, Buff_Plunder)]
						frostIncrease *= plunderBuff.severity;
					}
					
					FreezeBuildup[victim] += frostIncrease;
					checkFreeze(victim, attacker);
				}
			}
		}
	}

	if(IsValidClient3(attacker))
		currentDamageType[attacker].clear();

	if(damage < 0.0)
		damage = 0.0;
	return Plugin_Changed;
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage,
		int &damagetype, int &weapon, float damageForce[3], float damagePosition[3],
		int damagecustom, CritType &critType)
{
	if(!IsValidClient3(attacker))
		attacker = EntRefToEntIndex(attacker);

	//We don't really have anything to change if the attacker isn't a player anyway.
	if(!IsValidClient3(attacker))
		return Plugin_Continue;

	Action changed = Plugin_Continue;

	if(hasBuffIndex(victim, Buff_CritMarkedForDeath) || currentDamageType[attacker].second & DMG_ACTUALCRIT)
	{
		critType = CritType_Crit;
		changed = Plugin_Changed;
	}

	if(currentDamageType[attacker].second & DMG_PIERCING){
		critType = CritType_None;
		changed = Plugin_Changed;
	}
	currentDamageType[attacker].first = damagetype;

	if(IsValidClient3(victim)){
		if(damagetype & DMG_SLASH){
			damagetype |= DMG_PREVENT_PHYSICS_FORCE
			changed = Plugin_Changed;
		}
		
		if (damagecustom == TF_CUSTOM_BACKSTAB)
		{
			damage = 150.0;
			critType = CritType_Crit;
			float backstabRadiation = GetAttribute(weapon, "no double jump");
			if(backstabRadiation != 1.0)
			{
				if(GetAttribute(attacker, "knockout powerup", 0.0) == 2)
					backstabRadiation *= 3;

				if(hasBuffIndex(attacker, Buff_Plunder)){
					Buff plunderBuff;
					plunderBuff = playerBuffs[attacker][getBuffInArray(attacker, Buff_Plunder)]
					backstabRadiation *= plunderBuff.severity;
				}

				RadiationBuildup[victim] += backstabRadiation;
				checkRadiation(victim,attacker);
			}
			float stealthedBackstab = GetAttribute(weapon, "airblast cost increased");
			if(stealthedBackstab != 1.0)
			{
				TF2_AddCondition(attacker, TFCond_StealthedUserBuffFade, stealthedBackstab);
				TF2_RemoveCondition(attacker, TFCond_Stealthed)
			}
			changed = Plugin_Changed;
		}
		if (damagecustom == 46 && damagetype & DMG_SHOCK)//Short Circuit Balls
		{
			damage = 10.0;
			damage *= GetAttribute(weapon, "damage bonus");
			damage *= GetAttribute(weapon, "bullets per shot bonus");
			damage *= GetAttribute(weapon, "damage bonus HIDDEN");
			damage *= GetAttribute(weapon, "damage penalty");
			changed = Plugin_Changed;
		}
		if(damagecustom == TF_CUSTOM_BASEBALL)//Sandman Balls & Wrap Assassin Ornaments
		{
			damage = 45.0;
			damage += GetAttribute(weapon, "has pipboy build interface");
			damage *= GetAttribute(weapon, "damage bonus");
			damage *= GetAttribute(weapon, "damage bonus HIDDEN");
			damage *= GetAttribute(weapon, "damage penalty");
			changed = Plugin_Changed;
		}
	}

	if(IsValidWeapon(weapon)){
		if(TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee){
			if(GetAttribute(attacker, "knockout powerup", 0.0) == 1){
				damage *= 1.75
			}
			else if(GetAttribute(attacker, "knockout powerup", 0.0) == 3 && !isTagged[attacker][victim]){
				damage *= 4.0;
				critType = CritType_Crit;
				changed = Plugin_Changed;
			}
		}
	}

	if(hasBuffIndex(victim, Buff_Stronghold) || GetAttribute(victim, "resistance powerup", 0.0) == 1){
		critType = CritType_None;
		changed = Plugin_Changed;
	}
	return changed;
}
/*
public Action:TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage,
int &damagetype, int &weapon, float damageForce[3], float damagePosition[3],
int damagecustom, CritType &critType)
{
	if(!IsValidClient3(victim))
		return Plugin_Continue;

	attacker = EntRefToEntIndex(attacker);

	return Plugin_Continue;
}
*/
public Action OnTakeDamage(victim, &attacker, &inflictor, float &damage, &damagetype, &weapon, float damageForce[3], float damagePosition[3], damagecustom)
{
	if(0 < attacker <= MaxClients){
		if(!(currentDamageType[attacker].second & DMG_IGNOREHOOK)){
			baseDamage[attacker] = damage;

			if(damagetype & DMG_USEDISTANCEMOD)
				damagetype ^= DMG_USEDISTANCEMOD;

			if(currentDamageType[attacker].first == 0)
				currentDamageType[attacker].first = damagetype;

			if(IsValidClient3(victim) && IsValidClient3(attacker)){
				Address DodgeBody = TF2Attrib_GetByName(victim, "SET BONUS: chance of hunger decrease");
				if(DodgeBody != Address_Null){
					if(TF2Attrib_GetValue(DodgeBody) >= GetRandomFloat(0.0, 1.0))
						return Plugin_Stop;
				}

				damage = genericPlayerDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
			}

			if (!IsValidClient3(inflictor) && IsValidEdict(inflictor))
				damage = genericSentryDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
		}
		
		if(!(currentDamageType[attacker].second & DMG_PIERCING) && attacker != victim){
			float armorPenetration = TF2Attrib_HookValueFloat(0.0, "armor penetration buff", attacker);

			float dmgReduction = TF2Attrib_HookValueFloat(1.0, "dmg_incoming_mult", victim);
			if(dmgReduction != 1.0)
				damage *= dmgReduction

			float linearReduction = GetAttribute(victim, "dmg taken divided");
			if(linearReduction != 1.0)
				damage /= linearReduction;

			if(!IsFakeClient(victim)){
				damage /= GetResistance(victim, _, _,_, -armorPenetration);
			}else{
				//Armor penetration just gives +10% damage on bots.
				damage *= 1.0 + armorPenetration*0.1;
			}
		}
	}
	return Plugin_Changed;
}
public Action:OnTakeDamagePre_Tank(victim, &attacker, &inflictor, float &damage, &damagetype, &weapon, float damageForce[3], float damagePosition[3], damagecustom) 
{
	if(IsValidEdict(victim) && IsValidClient3(attacker))
	{
		currentDamageType[attacker].first = damagetype;
		if(IsValidWeapon(weapon))
		{
			if(current_class[attacker] == TFClass_Spy && TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee){
				float backstabCapability = GetAttribute(weapon, "backstab tanks capability", 0.0);
				if(backstabCapability){
					float tankRotation[3], attackerOrigin[3], attackerAngle[3], difference[3];
					GetEntPropVector(victim, Prop_Data, "m_angRotation", tankRotation);
					GetClientEyePosition(attacker, attackerOrigin);
					GetClientEyeAngles(attacker, attackerAngle);
					SubtractVectors(damagePosition, attackerOrigin, difference);

					GetAngleVectors(tankRotation, tankRotation, NULL_VECTOR, NULL_VECTOR);
					GetAngleVectors(attackerAngle, attackerAngle, NULL_VECTOR, NULL_VECTOR);

					difference[2] = 0.0;
					tankRotation[2] = 0.0;
					attackerAngle[2] = 0.0;
					
					NormalizeVector(difference, difference);
					NormalizeVector(attackerAngle, attackerAngle);
					NormalizeVector(tankRotation, tankRotation);

					float flPosVsTargetViewDot = GetVectorDotProduct( difference, tankRotation );
					float flPosVsOwnerViewDot = GetVectorDotProduct( difference, attackerAngle );
					float flViewAnglesDot = GetVectorDotProduct( tankRotation, attackerAngle );

					if( flPosVsTargetViewDot > 0 && flPosVsOwnerViewDot > 0.5 && flViewAnglesDot > -0.3 ){
						damage = backstabCapability;
						damagetype |= DMG_CRIT;
						currentDamageType[attacker].second |= DMG_ACTUALCRIT
					}
				}
			}
		}

		if (!IsValidClient3(inflictor) && IsValidEdict(inflictor))
			damage = genericSentryDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
		
		damage = genericPlayerDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
		if(IsValidWeapon(weapon))
		{
			if(TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee && GetAttribute(attacker, "knockout powerup", 0.0) == 1)
				damage *= 1.35;

			int i = RoundToCeil(TICKRATE/weaponFireRate[weapon]);
			if(i <= 6)
			{
				if(i == 0) i = 1;
				damage *= i*weaponFireRate[weapon]/TICKRATE;
			}
			applyDamageAffinities(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom, getDamageCategory(currentDamageType[attacker], attacker));
		}
	}
	if(damage < 0.0)
	{
		damage = 0.0;
	}
	if(IsValidEdict(logic))
	{
		int round = GetEntProp(logic, Prop_Send, "m_nMannVsMachineWaveCount");
		damage *= (Pow(7500.0/(StartMoney+additionalstartmoney), DefenseMod + (DefenseIncreasePerWaveMod * round)) * 6.0)/OverallMod;
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
			if(TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee && GetAttribute(attacker, "knockout powerup", 0.0) == 1)
				damage *= 1.35;
			
			int i = RoundToCeil(TICKRATE/weaponFireRate[weapon]);
			if(i <= 6)
			{
				if(i == 0) i = 1;
				damage *= i*weaponFireRate[weapon]/TICKRATE;
			}
			if(damagecustom == TF_CUSTOM_PLASMA_CHARGED || damagecustom == TF_CUSTOM_PLASMA){
				if(!GetAttribute(weapon, "energy weapon no hurt building", 1.0)){
					damage *= 5.0;
				}
			}
		}
		if(TF2_IsPlayerMinicritBuffed(attacker))
		{
			damage *= 1.4;
		}
		if(GetEntProp(victim, Prop_Send, "m_bDisabled") == 1)
		{
			for(int i = 1;i<=MaxClients;++i)
			{
				if(!IsValidClient3(i) || GetClientTeam(i) != GetClientTeam(attacker))
					continue;

				if(TF2_GetPlayerClass(i) != TFClass_Spy)
					continue;

				int sapper = GetWeapon(i,5);
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
			float armorAmt = GetResistance(owner);
			damage /= armorAmt;
		}
		damage *= TF2Attrib_HookValueFloat(1.0, "dmg_incoming_mult", owner);

		applyDamageAffinities(owner, attacker, inflictor, damage, weapon, damagetype, damagecustom, getDamageCategory(currentDamageType[attacker], attacker));
	}
	return Plugin_Changed;
}
public float genericPlayerDamageModification(victim, attacker, inflictor, float damage, weapon, damagetype, damagecustom)
{
	bool isVictimPlayer = IsValidClient3(victim);

	if(!IsOnDifferentTeams(victim, attacker))
		return damage;

	damage += GetAttribute(attacker, "additive damage bonus", 0.0);
	if(IsValidWeapon(weapon)){
		if(GetAttribute(weapon, "damage reduction to additive damage", 0.0) > 0.0)
			damage += GetAttribute(attacker, "tool escrow until date", 0.0) * GetAttribute(attacker, "is throwable chargeable", 0.0) * GetAttribute(weapon, "damage reduction to additive damage", 0.0)
	}

	if(isVictimPlayer)
	{
		if(IsFakeClient(attacker) && IsPlayerInSpawn(attacker)){
			return 0.0;
		}
		int jaratedIndex = getBuffInArray(victim, Buff_Jarated);
		if(jaratedIndex != -1){
			currentDamageType[playerBuffs[victim][jaratedIndex].inflictor].second |= DMG_IGNOREHOOK;
			SDKHooks_TakeDamage(victim,playerBuffs[victim][jaratedIndex].inflictor,playerBuffs[victim][jaratedIndex].inflictor,10.0*playerBuffs[victim][jaratedIndex].priority,DMG_DISSOLVE,_,_,_,false);
		}
		if(hasBuffIndex(victim, Buff_DragonDance)){
			int temp = getBuffInArray(victim, Buff_DragonDance);
			if(playerBuffs[victim][temp].priority != weapon){
				currentDamageType[attacker].second |= DMG_IGNOREHOOK;
				SDKHooks_TakeDamage(victim,attacker,playerBuffs[victim][temp].inflictor,TF2_GetWeaponclassDPS(attacker, playerBuffs[victim][temp].priority) * TF2_GetDPSModifiers(attacker, playerBuffs[victim][temp].priority) * 2.5,DMG_DISSOLVE,_,_,_,false);
				playerBuffs[victim][temp].clear();
				buffChange[victim]=true;
			}
		}
		if(damagetype == 4 && damagecustom == 3 && TF2_GetPlayerClass(attacker) == TFClass_Pyro){
			int secondary = GetWeapon(attacker,1);
			if(IsValidEdict(secondary) && weapon == secondary){
				float gasExplosionDamage = GetAttribute(weapon, "ignition explosion damage bonus");
				if(gasExplosionDamage != 1.0)
					damage *= gasExplosionDamage;
			}
		}
		if(TF2_GetPlayerClass(victim) == TFClass_Spy && (TF2_IsPlayerInCondition(victim, TFCond_Cloaked) || TF2_IsPlayerInCondition(victim, TFCond_Stealthed))){
			float CloakResistance = GetAttribute(GetPlayerWeaponSlot(victim,4), "absorb damage while cloaked");
			if(CloakResistance != 1.0)
				damage *= CloakResistance;
		}
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
		if(isVictimPlayer && attacker != victim)
		{
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
				if(precisionPowerup == 1)
				{
					miniCritStatus[victim] = true;
					damage *= 1.35;
					damagecustom = 1;
				}
			}
			if(TF2_IsPlayerInCondition(victim,TFCond_TmpDamageBonus))
			{
				damage *= 1.3;
			}
		}
		char classname[32]; 
		GetEdictClassname(weapon, classname, sizeof(classname)); 
		if(StrEqual(classname, "tf_weapon_syringegun_medic"))
			damage *= 1.8
		else if(StrEqual(classname, "tf_weapon_scattergun") ||
		StrEqual(classname, "tf_weapon_handgun_scout_primary") ||
		StrEqual(classname, "tf_weapon_soda_popper") ||
		StrEqual(classname, "tf_weapon_pep_brawler_blaster") ||
		StrContains(classname, "shotgun") != -1){
			float victimPosition[3];
			GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", victimPosition); 
			float attackerPosition[3];
			GetEntPropVector(attacker, Prop_Data, "m_vecAbsOrigin", attackerPosition); 
			float distance = GetVectorDistance(victimPosition, attackerPosition);
			if(distance > 400)
				distance = 400.0;

			damage *= 2+1.75*((400-distance)/400);
		}

		//Healers of attacker
		float medicDMGBonus = 1.0;
		int healers = GetEntProp(attacker, Prop_Send, "m_nNumHealers");
		if(healers > 0)
		{
			for(int i = 0;i<healers;++i){
				int healer = TF2Util_GetPlayerHealer(attacker,i);
				if(!IsValidClient3(healer))
					continue;
					
				int healingWeapon = GetWeapon(healer, 1);
				if(!IsValidWeapon(healingWeapon))
					continue;
				
				if(IsOnDifferentTeams(attacker, healer)){
					medicDMGBonus -= (GetAttribute(healingWeapon, "medigun blast resist passive", 0.0)+GetAttribute(healingWeapon, "medigun bullet resist passive", 0.0)+GetAttribute(healingWeapon, "medigun fire resist passive", 0.0))/6.0;
				}
				else{
					medicDMGBonus += GetAttribute(healingWeapon, "hidden secondary max ammo penalty", 0.0);

					if(TF2_IsPlayerInCondition(attacker, TFCond_Kritzkrieged))
						medicDMGBonus += GetAttribute(healingWeapon, "ubercharge effectiveness", 1.0)-1.0;

					medicDMGBonus *= GetAttribute(healingWeapon, "healing patient power", 1.0);
				}
			}
		}
		damage *= medicDMGBonus;
		damage *= TF2Attrib_HookValueFloat(1.0, "dmg_outgoing_mult", weapon);

		//Healers of victim
		float medicRESBonus = 1.0;
		if(isVictimPlayer){
			healers = GetEntProp(victim, Prop_Send, "m_nNumHealers");
			if(healers > 0)
			{
				for(int i = 0;i<healers;++i){
					int healer = TF2Util_GetPlayerHealer(victim,i);
					if(!IsValidClient3(healer))
						continue;
						
					int healingWeapon = GetWeapon(healer, 1);
					if(!IsValidWeapon(healingWeapon))
						continue;
					
					if(!IsOnDifferentTeams(healer, victim)){
						if(GetClientHealth(victim) > TF2Util_GetEntityMaxHealth(victim))
							medicRESBonus += GetAttribute(healingWeapon, "patient overheal to damage mult", 0.0);

						if(TF2_IsPlayerInCondition(healer, TFCond_UberFireResist) || TF2_IsPlayerInCondition(healer, TFCond_UberBulletResist) || TF2_IsPlayerInCondition(healer, TFCond_UberBlastResist))
							medicRESBonus += GetAttribute(healingWeapon, "ubercharge effectiveness", 1.0)-1.0;

						medicRESBonus *= GetAttribute(healingWeapon, "healing patient power", 1.0);
					}
				}
			}
		}
		damage /= medicRESBonus;

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

		if(!(currentDamageType[attacker].second & DMG_PIERCING)){
			float additivePiercingDamage = GetAttribute(weapon, "additive piercing damage", 0.0);
			if(additivePiercingDamage != 0){
				currentDamageType[attacker].second |= DMG_PIERCING;
				currentDamageType[attacker].second |= DMG_IGNOREHOOK;
				SDKHooks_TakeDamage(victim, inflictor, attacker, additivePiercingDamage, DMG_PREVENT_PHYSICS_FORCE);
			}
		}

		if(isVictimPlayer)
		{
			float burndmgMult = 1.0;
			burndmgMult *= GetAttribute(weapon, "shot penetrate all players");
			burndmgMult *= GetAttribute(weapon, "weapon burn dmg increased");
			burndmgMult *= GetAttribute(attacker, "weapon burn dmg increased");

			if(GetAttribute(attacker, "knockout powerup", 0.0) == 2 && TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee)
				burndmgMult *= 3;

			if(damagetype & DMG_ACTUALIGNITE || (GetClientTeam(attacker) != GetClientTeam(victim) && (GetAttribute(weapon, "flame_ignore_player_velocity", 0.0) || GetAttribute(attacker, "supernova powerup", 0.0) == 2) &&
			TF2_GetDPSModifiers(attacker, weapon)*burndmgMult >= fl_HighestFireDamage[victim] && 
			!(damagetype & DMG_BURN && damagetype & DMG_PREVENT_PHYSICS_FORCE) && !(damagetype & DMG_ENERGYBEAM))) // int afterburn system.
			{
				float afterburnDuration = 2.0 * GetAttribute(weapon, "weapon burn time increased");
				TF2Util_IgnitePlayer(victim, attacker, afterburnDuration, weapon);
				fl_HighestFireDamage[victim] = TF2_GetDPSModifiers(attacker, weapon)*burndmgMult;
			}
		}
		float overrideproj = GetAttribute(weapon, "override projectile type");
		float energyWeapActive = GetAttribute(weapon, "energy weapon penetration", 0.0);
		if(overrideproj != 1.0 || energyWeapActive != 0.0)
		{
			damage *= GetAttribute(weapon, "bullets per shot bonus");
			damage *= GetAttribute(weapon, "accuracy scales damage");
		}
		if(damagecustom == TF_CUSTOM_PLASMA_CHARGED)
		{
			damage *= Pow(GetAttribute(weapon, "clip size bonus upgrade")+1.0, 0.9);
			damagetype |= DMG_CRIT;
		}

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

		if(damagetype & DMG_SLASH){//Bleed receives ^0.5 damage boost from fire rate.
			damage /= Pow(TF2Attrib_HookValueFloat(1.0, "mult_postfiredelay", weapon),  0.5);
		}

		float missingHealthDamageBonus = GetAttribute(weapon, "dmg per pct hp missing", 0.0)
		if(missingHealthDamageBonus > 0.0){
			float ratio = GetClientHealth(attacker)/float(TF2Util_GetEntityMaxHealth(attacker));
			if(ratio < 1.0)
				damage *= 1+(missingHealthDamageBonus*100.0)*(1-ratio);
		}

		if(stickiesDetonated[attacker] > 0){
			damage *= 1+GetAttribute(weapon, "dmg per sticky detonated", 0.0)*stickiesDetonated[attacker];
		}

		if(isVictimPlayer)
		{
			if(immolationActive[attacker]){
				float immolationRatio = GetAttribute(weapon, "immolation ratio", 0.0);
				if(immolationRatio > 0.0){
					Buff immolationStatus;
					immolationStatus.init("Immolation Burn", "Rapidly losing health", Buff_ImmolationBurn, TF2Util_GetEntityMaxHealth(attacker)*RoundFloat(immolationRatio*100), attacker, 5.0);
					immolationStatus.severity = immolationRatio;
					insertBuff(victim, immolationStatus);
				}
			}
			if(damagetype & DMG_CLUB){
				float infernalExplosive = GetAttribute(weapon, "Dragon Bullets Radius", 0.0);
				if(infernalExplosive){
					float enemyPos[3];
					GetClientEyePosition(victim, enemyPos);
					EntityExplosion(attacker, damage, infernalExplosive, enemyPos, _, _, _, _, _, weapon, _, _, true);
					CreateParticleEx(victim, "heavy_ring_of_fire");
				}
			}
			float bouncingBullets = GetAttribute(weapon, "flame size penalty", 0.0);
			if(bouncingBullets != 0.0 && LastCharge[attacker] >= 150.0)
			{
				bool isBounced[MAXPLAYERS+1];
				isBounced[victim] = true
				int lastBouncedTarget = victim;
				float lastBouncedPosition[3];
				GetClientEyePosition(lastBouncedTarget, lastBouncedPosition)
				LastCharge[attacker] = 0.0;
				int i = 0
				int maxBounces = RoundToNearest(bouncingBullets);
				for(int client=1;client<=MaxClients && i < maxBounces;client++)
				{
					if(!IsValidClient3(client)) {continue;}
					if(!IsPlayerAlive(client)) {continue;}
					if(!IsOnDifferentTeams(client,attacker)) {continue;}
					if(isBounced[client]) {continue;}

					float VictimPos[3]; 
					GetClientEyePosition(client, VictimPos); 
					if(GetVectorDistance(lastBouncedPosition, VictimPos, true) > 122500.0) {continue;}
					
					isBounced[client] = true;
					GetClientEyePosition(lastBouncedTarget, lastBouncedPosition)
					lastBouncedTarget = client
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
					SDKHooks_TakeDamage(client,attacker,attacker,damage,damagetype,_,_,_,false)
					++i
				}
			}
			float conferenceBonus = GetAttribute(weapon, "conference call damage", 0.0);
			if(conferenceBonus && baseDamage[attacker] > 0)
			{
				float victimPos[3];
				GetClientEyePosition(victim, victimPos);

				for(int i = 0; i < 3; ++i){
					float pos1[3],pos2[3];

					float vecangles[3];
					if(i == 0){
						vecangles = {90.0,0.0,0.0};
					}else if(i == 1){
						vecangles = {0.0,0.0,0.0};
					}else{
						vecangles = {0.0,90.0,0.0};
					}

					Handle traceray = TR_TraceRayFilterEx(victimPos, vecangles, MASK_SHOT_HULL, RayType_Infinite, PenetrationCallTrace, attacker);
					if (TR_DidHit(traceray)) {
						TR_GetEndPosition(pos1, traceray);
						delete traceray;
					}
					if(i != 1)
						ScaleVector(vecangles, -1.0);
					else
						vecangles[1] = 179.99;

					Handle traceray2 = TR_TraceRayFilterEx(victimPos, vecangles, MASK_SHOT_HULL, RayType_Infinite, PenetrationCallTrace, attacker);
					if (TR_DidHit(traceray2)) {
						TR_GetEndPosition(pos2, traceray2);
						delete traceray2;
					}
					delete traceray2;

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
						TeleportEntity(iPart1, pos1, NULL_VECTOR, NULL_VECTOR);
						TeleportEntity(iPart2, pos2, NULL_VECTOR, NULL_VECTOR);
						ActivateEntity(iPart1);
						AcceptEntityInput(iPart1, "Start");
						
						CreateTimer(1.0, Timer_KillParticle, EntIndexToEntRef(iPart1));
						CreateTimer(1.0, Timer_KillParticle, EntIndexToEntRef(iPart2));
					}
				}
				for(int i = 1; i< MAXENTITIES; ++i){
					if(isPenetrated[i]){
						currentDamageType[attacker].second |= DMG_IGNOREHOOK;
						SDKHooks_TakeDamage(i,attacker,attacker,baseDamage[attacker]*TF2_GetDamageModifiers(attacker, weapon)*conferenceBonus,damagetype,_,_,_,false);
						isPenetrated[i] = false;
					}
				}
			}
		}
		if(GetAttribute(attacker, "supernova powerup", 0.0) == 1.0)
		{
			if(StrContains(getDamageCategory(currentDamageType[attacker], attacker),"blast",false) != -1)
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
					int iPart1 = CreateEntityByName("info_particle_system");
					int iPart2 = CreateEntityByName("info_particle_system");

					if (IsValidEdict(iPart1) && IsValidEdict(iPart2))
					{
						char particleName[32];
						particleName = GetClientTeam(attacker) == 2 ? "powerup_supernova_strike_red" : "powerup_supernova_strike_blue";
						
						float clientPos[3], clientAng[3];
						GetClientEyePosition(attacker, clientPos);
						GetClientEyeAngles(attacker,clientAng);
						
						char szCtrlParti[32];
						Format(szCtrlParti, sizeof(szCtrlParti), "tf2ctrlpart%i", iPart2);
						DispatchKeyValue(iPart2, "targetname", szCtrlParti);
						DispatchKeyValue(iPart1, "effect_name", particleName);
						DispatchKeyValue(iPart1, "cpoint1", szCtrlParti);
						DispatchSpawn(iPart1);
						TeleportEntity(iPart1, clientPos, clientAng, NULL_VECTOR);
						TeleportEntity(iPart2, victimPosition, NULL_VECTOR, NULL_VECTOR);
						ActivateEntity(iPart1);
						AcceptEntityInput(iPart1, "Start");
						
						CreateTimer(1.0, Timer_KillParticle, EntIndexToEntRef(iPart1));
						CreateTimer(1.0, Timer_KillParticle, EntIndexToEntRef(iPart2));
					}
					weaponArtParticle[attacker] = currentGameTime+1.0;
				}
			}
		}
		if(isVictimPlayer && StrContains(getDamageCategory(currentDamageType[attacker], attacker),"electric",false) != -1){
			int team = GetClientTeam(attacker);
			float arcDamage = baseDamage[attacker] * TF2_GetDamageModifiers(attacker, weapon, true) * 0.5;
			for(int i = 1;i<=MaxClients;++i){
				if(!IsValidClient3(i))
					continue;
				if(!IsPlayerAlive(i))
					continue;
				if(GetClientTeam(i) == team)
					continue;
				if(!isTagged[attacker][i])
					continue;
				if(IsPlayerInSpawn(i))
					continue;

				currentDamageType[attacker].second |= DMG_IGNOREHOOK;
				SDKHooks_TakeDamage(i, attacker, attacker, arcDamage, DMG_SHOCK, weapon,_,_,false);
			}
		}

		if(LightningEnchantmentDuration[attacker] > currentGameTime && !(damagetype & DMG_VEHICLE)){
			currentDamageType[attacker].second |= DMG_IGNOREHOOK;
			SDKHooks_TakeDamage(victim,attacker,attacker,LightningEnchantment[attacker] / TF2_GetFireRate(attacker,weapon,0.6) * 20.0,_,_,_,_,false);
		}
		else if(DarkmoonBladeDuration[attacker] > currentGameTime){
			int melee = GetWeapon(attacker,2);
			if(melee == weapon){
				currentDamageType[attacker].second |= DMG_IGNOREHOOK;
				SDKHooks_TakeDamage(victim,attacker,attacker,DarkmoonBlade[attacker],_,_,_,_,false);
			}
		}
		
		float arcaneWeaponScaling = GetAttribute(weapon,"arcane weapon scaling",0.0);
		if(arcaneWeaponScaling != 0.0){
			currentDamageType[attacker].second |= DMG_IGNOREHOOK;
			SDKHooks_TakeDamage(victim,attacker,attacker,10.0 + (Pow(ArcaneDamage[attacker] * Pow(ArcanePower[attacker], 4.0), spellScaling[2]) * arcaneWeaponScaling),_,_,_,_,false);
		}
		
		if(weaponFireRate[weapon] > 0.0){
			int i = RoundToCeil(TICKRATE/weaponFireRate[weapon]);
			if(i <= 6 && i >= 0)
			{
				if(i == 0) i = 1;
				damage *= i*weaponFireRate[weapon]/TICKRATE;
			}
			int secondary = GetWeapon(attacker, 1);
			if(IsValidWeapon(secondary)){
				float inheritanceRatio = GetAttribute(secondary, "dps inheritance ratio", 0.0);
				if(inheritanceRatio){
					float strongestDPS = 0.0;
					for(int e = 0;e<3;++e){
						int tempWeapon = GetWeapon(attacker, e);
						if(!IsValidWeapon(tempWeapon) || tempWeapon == weapon)
							continue;
						float currentDPS = TF2_GetWeaponclassDPS(attacker, tempWeapon) * TF2_GetDPSModifiers(attacker, tempWeapon);
						if(currentDPS > strongestDPS)
							strongestDPS = currentDPS;
					}
					currentDamageType[attacker].second |= DMG_IGNOREHOOK;
					SDKHooks_TakeDamage(victim,attacker,attacker,inheritanceRatio*strongestDPS/weaponFireRate[weapon],_,_,_,_,false);
				}
			}
		}
		if(damagetype & DMG_BURN && damagetype & DMG_PREVENT_PHYSICS_FORCE)
		{
			if(GetAttribute(victim, "inverter powerup", 0.0) == 1.0)
				damage *= 0.0;
			else{
				float burndmgMult = 1.0;
				burndmgMult *= GetAttribute(weapon, "shot penetrate all players");
				burndmgMult *= GetAttribute(weapon, "weapon burn dmg increased");
				burndmgMult *= GetAttribute(weapon, "weapon burn dmg reduced");
				burndmgMult *= GetAttribute(attacker, "weapon burn dmg increased");
				burndmgMult /= GetAttribute(weapon, "dmg penalty vs players");
				if(GetAttribute(attacker, "knockout powerup", 0.0) == 2 && TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee)
					burndmgMult *= 5;
				damage = (0.33*TF2_GetDPSModifiers(attacker, weapon, false, false)*burndmgMult);
			}
		}
	}
	return damage;
}
public float genericSentryDamageModification(victim, attacker, inflictor, float damage, weapon, damagetype, damagecustom)
{
	char classname[64];
	GetEdictClassname(inflictor, classname, sizeof(classname));
	if(!strcmp("tf_projectile_sentryrocket", classname)){
		inflictor = getOwner(inflictor);
		GetEdictClassname(inflictor, classname, sizeof(classname));
	}
	
	int weaponIdx = (IsValidWeapon(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
	bool isVictimPlayer = IsValidClient3(victim);

	if (isVictimPlayer && StrEqual(classname, "obj_attachment_sapper"))
		TF2_AddCondition(victim, TFCond_Sapped, 2.0);

	if ((!strcmp("obj_sentrygun", classname)) || weaponIdx == 140)
	{
		int owner; 
		owner = GetEntPropEnt(inflictor, Prop_Send, "m_hBuilder");

		if(IsValidForDamage(owner))
		{
			char Ownerclassname[64]; 
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
			damagetype |= DMG_PREVENT_PHYSICS_FORCE;

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
			int secondary = GetWeapon(owner, 1);
			if(IsValidWeapon(secondary)){
				damage *= 1+GetEntProp(inflictor, Prop_Send, "m_iKills")*GetAttribute(secondary, "sentry dmg bonus per kill", 0.0);
			}
			if((!strcmp("obj_sentrygun", classname) && GetEntProp(inflictor, Prop_Send, "m_bMiniBuilding") == 1))
			{//Minisentries deal 4 damage base.
				damage *= 0.5
			}
		}
	}
	if(projectileDamage[inflictor] > 0.0){
		damage = projectileDamage[inflictor];
	}else if(ShouldNotHit[inflictor][victim])
		return 0.0;
		
	return damage;
}
public void applyDamageAffinities(&victim, &attacker, &inflictor, float &damage, &weapon, &damagetype, &damagecustom, char[] damageCategory)
{
	//Now's the time!
	extendedDamageTypes bits;
	bits = currentDamageType[attacker];

	if(!IsValidWeapon(weapon))
		return;

	currentDamageType[attacker].clear();
	bool isVictimPlayer = IsValidClient3(victim);

	if(StrContains(damageCategory, "direct") != -1)
	{
		if(isVictimPlayer){
			Address dmgTakenMultAddr = TF2Attrib_GetByName(victim, "direct damage taken reduced");
			if(dmgTakenMultAddr != Address_Null)
				damage *= TF2Attrib_GetValue(dmgTakenMultAddr);
		}

		Address dmgMasteryAddr = TF2Attrib_GetByName(attacker, "physical damage affinity");
		if(dmgMasteryAddr != Address_Null){
			damage *= TF2Attrib_GetValue(dmgMasteryAddr)*TF2Attrib_GetValue(dmgMasteryAddr);

			if(IsValidEdict(inflictor) && !IsValidClient3(inflictor) && !HasEntProp(inflictor, Prop_Send, "m_iItemDefinitionIndex"))
				{damagetype |= DMG_CLUB;damagetype |= DMG_BULLET;}

			if(damagetype & DMG_BULLET || damagetype & DMG_BUCKSHOT)
			{
				//Deal 3 piercing damage.
				currentDamageType[attacker].second |= DMG_PIERCING;
				currentDamageType[attacker].second |= DMG_IGNOREHOOK;
				SDKHooks_TakeDamage(victim, attacker, attacker, 3.0, DMG_PREVENT_PHYSICS_FORCE, weapon);
			}
		}
	}
	else if(StrContains(damageCategory, "fire") != -1)
	{
		Address dmgMasteryAddr = TF2Attrib_GetByName(attacker, "fire damage affinity");
		if(dmgMasteryAddr != Address_Null){
			damage *= TF2Attrib_GetValue(dmgMasteryAddr)*TF2Attrib_GetValue(dmgMasteryAddr);
			if(isVictimPlayer)
				damage *= 1.0+(TF2Util_GetPlayerBurnDuration(victim)*0.05);
		}

		if(GetAttribute(attacker, "supernova powerup", 0.0) == 2){
			damage *= 1.7;

			int team = GetClientTeam(attacker);

			Buff infernalDOTBuff;
			infernalDOTBuff.init("Piercing Flames", "", Buff_PowerupBurning, 1, attacker, 5.0);

			float victimOrigin[3];
			GetClientAbsOrigin(victim, victimOrigin);
			
			for(int i = 1;i<=MaxClients;++i){
				if(!IsValidClient3(i))
					continue;
				if(!IsPlayerAlive(i))
					continue;
				if(GetClientTeam(i) == team)
					continue;

				float splashOrigin[3];
				GetClientAbsOrigin(i, splashOrigin);
				if(GetVectorDistance(victimOrigin, splashOrigin, true) > 250000)
					continue;
				
				insertBuff(i, infernalDOTBuff);
			}
		}
	}
	else if(StrContains(damageCategory, "blast") != -1)
	{
		Address dmgMasteryAddr = TF2Attrib_GetByName(attacker, "explosive damage affinity");
		if(dmgMasteryAddr != Address_Null)
			damage *= TF2Attrib_GetValue(dmgMasteryAddr)*TF2Attrib_GetValue(dmgMasteryAddr);
	}
	else if(StrContains(damageCategory, "electric") != -1)
	{
		Address dmgMasteryAddr = TF2Attrib_GetByName(attacker, "electric damage affinity");
		if(dmgMasteryAddr != Address_Null)
			damage *= TF2Attrib_GetValue(dmgMasteryAddr)*TF2Attrib_GetValue(dmgMasteryAddr);

		if(GetAttribute(attacker, "supernova powerup", 0.0) == 3){
			float buff = 1.0;
			for(int i = 1;i<=MaxClients;++i){
				if(isTagged[attacker][i])
					buff += 0.08;
			}
			damage *= buff;
		}
	}
	else if(StrContains(damageCategory, "arcane") != -1)
	{
		if(isVictimPlayer){
			Address dmgTakenMultAddr = TF2Attrib_GetByName(victim, "arcane damage taken reduced");
			if(dmgTakenMultAddr != Address_Null)
				damage *= TF2Attrib_GetValue(dmgTakenMultAddr);
		}
		Address dmgMasteryAddr = TF2Attrib_GetByName(attacker, "arcane damage affinity");
		if(dmgMasteryAddr != Address_Null)
			damage *= TF2Attrib_GetValue(dmgMasteryAddr)*TF2Attrib_GetValue(dmgMasteryAddr);
	}

	if(StrContains(damageCategory, "crit") != -1)
	{
		Address dmgMasteryAddr = TF2Attrib_GetByName(attacker, "crit damage affinity");
		if(dmgMasteryAddr != Address_Null)
			damage = Pow(damage, TF2Attrib_GetValue(dmgMasteryAddr) + (bits.second & DMG_ACTUALCRIT ? 0.2 : 0.0) );

	}
}