public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, float &damage, &damagetype, &weapon, float damageForce[3], float damagePosition[3], damagecustom)
{
	if(IsValidClient3(victim))
	{
		lastKBSource[victim] = attacker;
		if(TF2_IsPlayerInCondition(victim, TFCond_UberchargedHidden) || TF2_IsPlayerInCondition(victim, TFCond_Ubercharged))
			return Plugin_Continue;

		if(!(damagetype & DMG_PIERCING)){
			float dmgMult = TF2Attrib_HookValueFloat(1.0, "dmg_incoming_mult", victim);
			if(dmgMult < 1.0)
				damage *= ConsumePierce(dmgMult, damageForce[0]);
			else
				damage *= dmgMult;
		}
		if(TF2Attrib_HookValueFloat(0.0, "resistance_powerup", victim) == 2.0){
			if(frayNextTime[victim] <= GetGameTime()){
				damage = 0.0;
				frayNextTime[victim] = GetGameTime()+1.0
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
					return Plugin_Changed;
				}
			}
		}
		if(attacker == victim){
			float dmgReduction = TF2Attrib_HookValueFloat(1.0, "dmg_incoming_mult", victim);
			if(dmgReduction < 1.0)
				damage *= ConsumePierce(dmgReduction, damageForce[0]);
			else
				damage *= dmgReduction

			float linearReduction = TF2Attrib_HookValueFloat(1.0, "dmg_taken_divided", victim);
			if(linearReduction != 1.0)
				damage /= linearReduction;

			if(!(damagetype & DMG_PIERCING) && !IsFakeClient(victim)){
				damage /= GetResistance(victim);
			}
		}
		if(IsValidClient3(attacker) && victim != attacker)
		{
			bool isSentry = false;
			if(IsValidEdict(inflictor)){
				ShouldNotHome[inflictor][victim] = true;
				char classname[32]; 
				GetEdictClassname(inflictor, classname, sizeof(classname));
				isSentry = StrEqual("obj_sentrygun", classname) || StrEqual("tf_projectile_sentryrocket", classname);
			}

			if(IsValidWeapon(weapon) && !isSentry)
			{
				if(InfernalEnchantmentDuration[attacker] >= GetGameTime()){
					Buff infernalDOT; infernalDOT.init("Infernal Flames", "", Buff_InfernalDOT, 1, attacker, 8.0);
					insertBuff(victim, infernalDOT);
				}
				if(damagetype & DMG_SLASH && damagecustom == TF_CUSTOM_BLEEDING){
					if(TF2Attrib_HookValueFloat(0.0, "knockout_powerup", attacker) == 2 && TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee){
						damage *= 5;
					}
				}
			}
		}
		float bossValue = TF2Attrib_HookValueFloat(0.0, "player_boss_type", victim);
		switch(bossValue)
		{
			case 1.0:
			{
				if (!TF2_IsPlayerInCondition(victim,TFCond_UberchargedHidden) && GetClientHealth(victim) - damage < TF2_GetMaxHealth(victim) - (TF2_GetMaxHealth(victim)*(0.125*(bossPhase[victim]+1))))//boss phases
				{
					damage = GetClientHealth(victim) - (TF2_GetMaxHealth(victim) - (TF2_GetMaxHealth(victim)*(0.125*(bossPhase[victim]+1))));
					TF2_AddCondition(victim, TFCond_MegaHeal, 1.5, victim);
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
					TF2_AddCondition(victim, TFCond_MegaHeal, 5.0, victim);
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
					TF2_AddCondition(victim, TFCond_MegaHeal, 15.0, victim);
					TF2_AddCondition(victim, TFCond_UberchargedHidden, 1.0);
					giveDefenseBuff(victim, 6.0);
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
									break;
								}
							}
						}
					}
					bossPhase[victim]++;
				}
			}
		}
	}
	if(damagetype & DMG_PIERCING){
		return Plugin_Changed;
	}

	if(IsValidClient3(attacker) && IsValidClient3(victim))
	{
		applyDamageAffinities(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);

		if(IsValidWeapon(weapon)){
			if(attacker != victim){
				char weaponClassName[64]; 
				GetEntityClassname(weapon, weaponClassName, sizeof(weaponClassName));
				if(StrEqual(weaponClassName,"tf_weapon_jar_milk",false))
				{
					float inverterPowerup = TF2Attrib_HookValueFloat(0.0, "inverter_powerup", victim);
					if(inverterPowerup == 1.0){
						MadmilkDuration[attacker] = GetGameTime()+6.0;
						MadmilkInflictor[attacker] = victim;
					}
					else if(inverterPowerup == 2.0){
						MadmilkDuration[victim] = GetGameTime()+12.0;
						MadmilkInflictor[victim] = victim;
					}
					else if(MadmilkDuration[victim] < GetGameTime()+6.0)
					{
						MadmilkDuration[victim] = GetGameTime()+6.0;
						MadmilkInflictor[victim] = attacker;
					}
				}
				Address MadMilkOnhit = TF2Attrib_GetByName(weapon, "armor piercing");
				if(MadMilkOnhit != Address_Null)
				{
					float value = TF2Attrib_GetValue(MadMilkOnhit);

					float inverterPowerup = TF2Attrib_HookValueFloat(0.0, "inverter_powerup", victim);
					if(inverterPowerup == 1.0){
						MadmilkDuration[attacker] = GetGameTime()+value;
						MadmilkInflictor[attacker] = victim;
					}
					else if(inverterPowerup == 2.0){
						MadmilkDuration[victim] = GetGameTime()+2*value;
						MadmilkInflictor[victim] = victim;
					}
					else if(MadmilkDuration[victim] < GetGameTime()+value)
					{
						MadmilkDuration[victim] = GetGameTime()+value
						MadmilkInflictor[victim] = attacker;
					}
				}
			}

			if(attacker != victim && TF2Attrib_HookValueFloat(0.0, "inverter_powerup", attacker) == 2){
				if(hasBuffIndex(attacker, Buff_CritMarkedForDeath)){
					Buff critligma;
					critligma.init("Marked for Crits", "All hits taken are critical", Buff_CritMarkedForDeath, 1, attacker, 8.0);
					insertBuff(victim, critligma);
				}
				if(MadmilkDuration[attacker] > GetGameTime()){
					if(MadmilkDuration[victim] > MadmilkDuration[attacker]){
						MadmilkDuration[victim] = MadmilkDuration[attacker];
					}
				}
				if(TF2_IsPlayerInCondition(attacker, TFCond_Bleeding)){
					TF2Util_MakePlayerBleed(victim, attacker, 8.0, weapon, 8);
				}
				if(TF2_IsPlayerInCondition(attacker, TFCond_Dazed) || TF2_IsPlayerInCondition(attacker, TFCond_FreezeInput)){
					TF2_StunPlayer(victim, 0.35, 0.5, TF_STUNFLAG_SLOWDOWN);
				}
				float strongestAfterburn = 0.0;
				int strongestAfterburnDuration = 0;
				for(int i=0;i < MAX_AFTERBURN_STACKS; ++i){
					if(playerAfterburn[attacker][i].remainingTicks <= 0)
						continue;

					int owner = playerAfterburn[attacker][i].owner;
					if(!IsValidClient3(owner))
						continue;

					if(playerAfterburn[attacker][i].damage*playerAfterburn[attacker][i].remainingTicks > strongestAfterburn*strongestAfterburnDuration){
						strongestAfterburn = playerAfterburn[attacker][i].damage;
						strongestAfterburnDuration = playerAfterburn[attacker][i].remainingTicks;
					}
				}
				if(strongestAfterburn*strongestAfterburnDuration > 0){
					AfterburnStack strongestStack;
					strongestStack.damage = strongestAfterburn;
					strongestStack.remainingTicks = strongestAfterburnDuration;
					strongestStack.owner = attacker;
					insertAfterburn(victim, strongestStack);
				}
			}

			Address bleedBuild = TF2Attrib_GetByName(weapon, "sapper damage bonus");
			if(bleedBuild != Address_Null && !(damagetype & DMG_PREVENT_PHYSICS_FORCE && damagetype & DMG_BURN))//Specifically doesn't apply on afterburn, but works on bleeding DOT.
			{
				float bleedAdd = TF2Attrib_GetValue(bleedBuild);
				if(TF2Attrib_HookValueFloat(0.0, "knockout_powerup", attacker) == 2 && TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee)
					bleedAdd *= 3;

				if(hasBuffIndex(attacker, Buff_Plunder)){
					Buff plunderBuff;
					plunderBuff = playerBuffs[attacker][getBuffInArray(attacker, Buff_Plunder)]
					bleedAdd *= plunderBuff.severity;
				}

				BleedBuildup[victim] += bleedAdd;
				checkBleed(victim, attacker, weapon);
			}
			float radiationAmount = TF2Attrib_HookValueFloat(0.0, "radiation_buildup_onhit", weapon);
			if(radiationAmount > 0)
			{
				if(TF2Attrib_HookValueFloat(0.0, "knockout_powerup", attacker) == 2 && TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee)
					radiationAmount *= 3;

				if(hasBuffIndex(attacker, Buff_Plunder)){
					Buff plunderBuff;
					plunderBuff = playerBuffs[attacker][getBuffInArray(attacker, Buff_Plunder)]
					radiationAmount *= plunderBuff.severity;
				}

				RadiationBuildup[victim] += radiationAmount;
				checkRadiation(victim,attacker);
			}
		}
		if(damagetype == (DMG_RADIATION|DMG_DISSOLVE))//Radiation.
		{
			if(TF2Attrib_HookValueFloat(0.0, "knockout_powerup", attacker) == 2)
				damage *= 3;
			if(hasBuffIndex(attacker, Buff_Plunder)){
				Buff plunderBuff;
				plunderBuff = playerBuffs[attacker][getBuffInArray(attacker, Buff_Plunder)]
				damage *= plunderBuff.severity;
			}
			RadiationBuildup[victim] += damage;
			checkRadiation(victim,attacker);
		}

		if(TF2Attrib_HookValueFloat(0.0, "inverter_powerup", attacker) == 3){
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

		if(TF2_IsPlayerInCondition(victim, TFCond_DefenseBuffed) && TF2_IsPlayerInCondition(victim, TFCond_DefenseBuffNoCritBlock))
			damage *= ConsumePierce(0.65, damageForce[0]);

		ApplyVaccinatorDamageReduction(victim, damagetype, damage, damageForce[0]);

		if(TF2Attrib_HookValueFloat(0.0, "resistance_powerup", victim) == 1 || TF2Attrib_HookValueFloat(0.0, "resistance_powerup", victim) == 3)
			damage *= ConsumePierce(0.5, damageForce[0]);

		if(TF2Attrib_HookValueFloat(0.0, "revenge_powerup", victim) == 1)
			damage *= ConsumePierce(0.8, damageForce[0]);

		if(TF2Attrib_HookValueFloat(0.0, "knockout_powerup", victim) == 1)
			damage *= ConsumePierce(0.8, damageForce[0]);
		else if(TF2Attrib_HookValueFloat(0.0, "knockout_powerup", victim) == 2)
			damage *= ConsumePierce(0.66, damageForce[0]);

		if(TF2Attrib_HookValueFloat(0.0, "king_powerup", victim) == 1)
			damage *= ConsumePierce(0.8, damageForce[0]);
		else if(TF2Attrib_HookValueFloat(0.0, "king_powerup", victim) == 3)
			damage *= ConsumePierce(0.66, damageForce[0]);
		
		if(TF2Attrib_HookValueFloat(0.0, "supernova_powerup", victim) == 1)
			damage *= ConsumePierce(0.8, damageForce[0]);

		if(TF2Attrib_HookValueFloat(0.0, "inverter_powerup", victim) == 1)
			damage *= ConsumePierce(0.8, damageForce[0]);
		else if(TF2Attrib_HookValueFloat(0.0, "inverter_powerup", victim) == 2)
			damage *= ConsumePierce(0.66, damageForce[0]);

		if(TF2Attrib_HookValueFloat(0.0, "regeneration_powerup", victim) == 1)
			damage *= ConsumePierce(0.75, damageForce[0]);

		if(TF2Attrib_HookValueFloat(0.0, "vampire_powerup", victim) == 1 || TF2Attrib_HookValueFloat(0.0, "vampire_powerup", victim) == 3)
			damage *= ConsumePierce(0.75, damageForce[0]);

		//This is actually valid.
		if(1.0 <= TF2Attrib_HookValueFloat(0.0, "plague_powerup", victim) <= 2.0)
			damage *= ConsumePierce(0.75, damageForce[0]);

		if(hasBuffIndex(attacker, Buff_Plagued))
			damage *= 0.5;
		
		int championIndex = getBuffInArray(attacker, Buff_ChampionMark);
		if(championIndex != -1 && playerBuffs[attacker][championIndex].inflictor != victim){
			damage *= ConsumePierce(0.66, damageForce[0]);
		}

		if(TF2Attrib_HookValueFloat(0.0, "juggernaut_powerup", victim) == 1){
			if(damage >= GetClientHealth(victim) * 0.5){
				damage *= ConsumePierce(0.66, damageForce[0]);
			}
			RecoupStack newStack;
			newStack.expireTime = GetGameTime() + 5.0;
			newStack.hpPerTick = damage*TICKINTERVAL*0.5*0.2;
			insertRecoup(victim, newStack);
		}
		else if(TF2Attrib_HookValueFloat(0.0, "juggernaut_powerup", victim) == 3){
			float missingHealth = float(TF2Util_GetEntityMaxHealth(victim) - GetClientHealth(victim));
			if(missingHealth > 0){
				float damageRatio = damage/float(TF2Util_GetEntityMaxHealth(victim))
				float defianceHeal = 0.12 * missingHealth;
				if(damageRatio > 0){
					defianceHeal *= 1.0 + damageRatio * 0.5;
				}
				RecoupStack newStack;
				newStack.expireTime = GetGameTime() + 5.0;
				newStack.hpPerTick = defianceHeal*TICKINTERVAL*0.2;
				insertRecoup(victim, newStack);
			}
		}

		if(StunShotStun[attacker])
		{
			StunShotStun[attacker] = false;
			TF2_StunPlayer(victim, 1.5, 1.0, TF_STUNFLAGS_NORMALBONK, attacker);
		}

		Address ReflectActive = TF2Attrib_GetByName(victim, "extinguish restores health");
		if(ReflectActive != Address_Null && !(damagetype & DMG_IGNOREHOOK))
		{
			float ReflectDamage = damage;
			Address ReflectDamageMultiplier = TF2Attrib_GetByName(victim, "set cloak is movement based");
			if(ReflectDamageMultiplier != Address_Null && GetRandomInt(1, 100) < TF2Attrib_GetValue(ReflectActive) * 33.0)
			{
				float ReflectMult = TF2Attrib_GetValue(ReflectDamageMultiplier);
				ReflectDamage *= ReflectMult
				SDKHooks_TakeDamage(attacker, victim, victim, ReflectDamage, DMG_PREVENT_PHYSICS_FORCE|DMG_REFLECT|DMG_IGNOREHOOK,_,_,_,false);
			}
		}

		//Prevent piercing damage from being guardian'd
		int VictimCWeapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
		if(IsValidWeapon(VictimCWeapon)){
			damage *= ConsumePierce(TF2Attrib_HookValueFloat(1.0, "damage_taken_multiplier_when_active", VictimCWeapon), damageForce[0]);

			if(HasEntProp(VictimCWeapon, Prop_Send, "m_hHealingTarget") && miniCritStatusVictim[victim] < GetGameTime()){
				if(TF2Attrib_HookValueFloat(0.0, "escape plan healing", VictimCWeapon)){
					int healingTarget = GetEntPropEnt(VictimCWeapon, Prop_Send, "m_hHealingTarget");
					if(IsValidClient3(healingTarget)){
						int medicHealth = GetClientHealth(victim);
						int patientHealth = GetClientHealth(victim);
						if(patientHealth > medicHealth && medicHealth - damage <= 10.0){
							SetEntityHealth(victim, patientHealth);
							SetEntityHealth(healingTarget, medicHealth);
							miniCritStatusVictim[victim] = GetGameTime() + 10.0;
							damage *= 0.25;
						}
					}
				}
			}
			float teamTacticsRatio = TF2Attrib_HookValueFloat(0.0, "savior_sacrifice_attribute", VictimCWeapon);
			if(teamTacticsRatio > 0.0){
				float ratio = damage / TF2Util_GetEntityMaxHealth(victim);
				if(ratio > 1.0)
					ratio = 1.0;

				TeamTacticsBuildup[victim] += teamTacticsRatio * ratio;
				if(TeamTacticsBuildup[victim] > 0.5)
					TeamTacticsBuildup[victim] = 0.5;
			}
		}

		if(IsValidWeapon(weapon)){
			if(damagecustom == TF_CUSTOM_HEADSHOT){
				float chargeAfterShot = GetAttribute(weapon, "mult sniper charge after headshot", 0.0);
				if(chargeAfterShot > 0.0)
					savedCharge[attacker] = chargeAfterShot;
			}

			float fireworksChance = TF2Attrib_HookValueFloat(0.0, "fireworks_chance", weapon)
			if(fireworksChance*damage/TF2Util_GetEntityMaxHealth(victim) >= GetRandomFloat() && !(damagetype & DMG_IGNOREHOOK)){
				SDKHooks_TakeDamage(victim, attacker, attacker, 1.0*GetClientHealth(victim), DMG_PREVENT_PHYSICS_FORCE|DMG_PIERCING|DMG_IGNOREHOOK);
				EmitSoundToAll(DetonatorExplosionSound, victim);
			}
			if(!(damagetype & DMG_PIERCING)){ //Make sure it isn't piercing damage...
				float freezeRatio = TF2Attrib_HookValueFloat(0.0, "damage_causes_freeze", weapon);
				if(freezeRatio > 0){
					float frostIncrease = 100.0*freezeRatio*damage/TF2Util_GetEntityMaxHealth(victim);
					if(TF2Attrib_HookValueFloat(0.0, "knockout_powerup", attacker) == 2 && TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee)
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
			
			float concussionRatio = TF2Attrib_HookValueFloat(0.0, "concussion_buildup_ratio", weapon);
			if(TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee && 
				TF2Attrib_HookValueFloat(0.0, "knockout_powerup", weapon) == 1){
					concussionRatio += 175.0;
			}

			if(concussionRatio > 0.0){
				float buildupIncrease = damage/TF2_GetMaxHealth(victim)*concussionRatio;
				
				if(hasBuffIndex(attacker, Buff_Plunder)){
					Buff plunderBuff;
					plunderBuff = playerBuffs[attacker][getBuffInArray(attacker, Buff_Plunder)]
					buildupIncrease *= plunderBuff.severity;
				}

				ConcussionBuildup[victim] += buildupIncrease;
				if(ConcussionBuildup[victim] >= 100.0)
				{
					ConcussionBuildup[victim] = 0.0;
					if(TF2Attrib_HookValueFloat(0.0, "inverter_powerup", victim) == 1){
						TF2_AddCondition(victim, TFCond_MegaHeal, 10.0, victim);
						giveDefenseBuff(victim, 10.0);
					}else{
						miniCritStatusVictim[victim] = GetGameTime()+10.0;
						TF2_StunPlayer(victim, 1.0, 1.0, TF_STUNFLAGS_NORMALBONK, attacker);
					}
				}
			}

			if(TF2Attrib_HookValueFloat(0.0, "king_powerup", attacker) == 3){
				Buff championAffliction;
				championAffliction.init("Champion's Mark", "You take +20 DPS", Buff_ChampionMark, 1, attacker, 10.0, 20.0*TF2_GetDPSModifiers(attacker, weapon));
				insertBuff(victim, championAffliction);
			}
		}

		if(hasBuffIndex(victim, Buff_Bruised) && !(damagetype & DMG_PIERCING) && !(damagetype & DMG_IGNOREHOOK)){
			int bruisedInflictor = playerBuffs[victim][getBuffInArray(victim, Buff_Bruised)].inflictor;
			if(IsValidClient3(bruisedInflictor)){
				float bruisedDamage = damage;
				if(!(damagetype & DMG_CRIT)){
					bruisedDamage *= 2.25;
				}

				if(damage >= TF2Util_GetEntityMaxHealth(victim) * 0.4){
					SDKHooks_TakeDamage(victim, bruisedInflictor, bruisedInflictor, 1.0*GetClientHealth(victim), DMG_PREVENT_PHYSICS_FORCE|DMG_IGNOREHOOK|DMG_PIERCING)
				}
				else if((GetClientHealth(victim) - bruisedDamage)/TF2Util_GetEntityMaxHealth(victim) <= 0.25){
					critStatus[victim] = true;
					damage = bruisedDamage;
					SDKHooks_TakeDamage(victim, bruisedInflictor, bruisedInflictor, 0.25*TF2Util_GetEntityMaxHealth(victim), DMG_PREVENT_PHYSICS_FORCE|DMG_IGNOREHOOK|DMG_PIERCING)
				}
			}
		}
	}

	if(damage < 0.0)
		damage = 0.0;
	return Plugin_Changed;
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage,
		int &damagetype, int &weapon, float damageForce[3], float damagePosition[3],
		int damagecustom, CritType &critType)
{
	float originalDamage = damage;
	CritType originalCrit = critType;
	if(!IsValidClient3(attacker))
		attacker = EntRefToEntIndex(attacker);

	//We don't really have anything to change if the attacker isn't a player anyway.
	if(!IsValidClient3(attacker))
		return Plugin_Continue;

	if(hasBuffIndex(victim, Buff_CritMarkedForDeath)){
		critType = CritType_Crit;
	}

	if(damagetype & DMG_PIERCING){
		critType = CritType_None;
	}

	if(IsValidClient3(victim)){
		if(damagetype & DMG_SLASH){
			damagetype |= DMG_PREVENT_PHYSICS_FORCE;
		}
		switch(damagecustom) {
			case TF_CUSTOM_BACKSTAB:
			{
				damage = 150.0;
				critType = CritType_Crit;
				float backstabRadiation = TF2Attrib_HookValueFloat(0.0, "backstab_radiation_buildup", weapon);
				if(backstabRadiation > 0.0)
				{
					if(TF2Attrib_HookValueFloat(0.0, "knockout_powerup", attacker) == 2)
						backstabRadiation *= 3;

					if(hasBuffIndex(attacker, Buff_Plunder)){
						Buff plunderBuff;
						plunderBuff = playerBuffs[attacker][getBuffInArray(attacker, Buff_Plunder)]
						backstabRadiation *= plunderBuff.severity;
					}

					RadiationBuildup[victim] += backstabRadiation;
					checkRadiation(victim,attacker);
				}
				float stealthedBackstab = TF2Attrib_HookValueFloat(0.0, "stealthed_backstab_duration", weapon);
				if(stealthedBackstab != 1.0)
				{
					TF2_AddCondition(attacker, TFCond_StealthedUserBuffFade, stealthedBackstab);
					TF2_RemoveCondition(attacker, TFCond_Stealthed)
				}
			}
			case 46://Short Circuit Balls
			{
				if(damagetype & DMG_SHOCK)
				{
					damage = 10.0;
					damage *= TF2Attrib_HookValueFloat(1.0, "mult_dmg", weapon);
					damage *= TF2Attrib_HookValueFloat(1.0, "mult_bullets_per_shot", weapon);
				}
			}
			case TF_CUSTOM_BASEBALL:
			{
				if(damagetype & DMG_CLUB) {
					damage = 35.0;
					damage += TF2Attrib_HookValueFloat(0.0, "baseball_base_damage", weapon);
				}
			}
		}
	}

	if(IsValidWeapon(weapon)){
		if(TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee){
			if(TF2Attrib_HookValueFloat(0.0, "knockout_powerup", attacker) == 1){
				damage *= 1.75;
			}
			else if(TF2Attrib_HookValueFloat(0.0, "knockout_powerup", attacker) == 3 && !isTagged[attacker][victim]){
				damage *= 4.0;
				critType = CritType_Crit;
				isTagged[attacker][victim] = true;
			}
		}

		if(IsValidEntity(inflictor)) {
			char classname[32];
			GetEdictClassname(inflictor, classname, sizeof(classname));
			if(StrEqual("tf_projectile_sentryrocket", classname)){
				inflictor = getOwner(inflictor);
				GetEdictClassname(inflictor, classname, sizeof(classname));
			}

			if(StrEqual("obj_sentrygun", classname)){
				if(TF2_IsPlayerCritBuffed(attacker)){
					int CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
					if(IsValidWeapon(CWeapon)){
						int weaponIndex = GetEntProp(CWeapon, Prop_Send, "m_iItemDefinitionIndex");
						if(weaponIndex != 141 && weaponIndex != 1004)
						{
							critType = CritType_Crit;
						}
					}
				}
				float critRating = TF2Attrib_HookValueFloat(0.0, "critical_rating", weapon);
				if(critRating > 0){
					float critRate = critRating/(critRating+200.0);
					if(critRate >= GetRandomFloat()){
						critType = CritType_Crit;
					}
				}
			}
		}
	}

	if(hasBuffIndex(victim, Buff_Stronghold) || TF2Attrib_HookValueFloat(0.0, "resistance_powerup", victim) == 1){
		critType = CritType_None;
	}
	if(originalDamage != damage || originalCrit != critType)
		return Plugin_Changed;
	return Plugin_Continue;
}

public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType){
	if(0 < victim <= MaxClients && 0 < attacker <= MaxClients){
		float critNullify = TF2Attrib_HookValueFloat(0.0, "critical_block_rating", victim);
		float critRating = 0.0; 
		float critMod = 1.0;
		if(IsValidWeapon(weapon)) {
			critRating = TF2Attrib_HookValueFloat(0.0, "critical_rating", weapon);
			critMod = TF2Attrib_HookValueFloat(1.0, "crit_damage_mod", weapon);
		}
		else {
			critRating = TF2Attrib_HookValueFloat(0.0, "critical_rating", attacker);
			critMod = TF2Attrib_HookValueFloat(1.0, "crit_damage_mod", attacker);
		}

		if(critType == CritType_Crit){
			damage /= 3.0;

			if(critNullify/(critNullify+800) >= GetRandomFloat()){
				critType = CritType_None;
			}else{
				damage += damage*((critMod+critRating/200.0)/(1+critNullify/200));
			}
			return Plugin_Changed;
		}
		if(critType == CritType_MiniCrit || miniCritStatus[victim]){
			if(!miniCritStatus[victim])
				damage /= 1.35;
			else
				critType = CritType_MiniCrit

			if(critNullify/(critNullify+800) >= GetRandomFloat()){
				critType = CritType_None;
			}else{
				float bonusDamage = damage*0.35*(critMod+(critRating-critNullify)/200);
				if(bonusDamage < 0)
					bonusDamage = 0.0;
				damage += bonusDamage;
			}
			miniCritStatus[victim] = false;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

public Action OnTakeDamage(victim, &attacker, &inflictor, float &damage, &damagetype, &weapon, float damageForce[3], float damagePosition[3], damagecustom)
{
	//Lets do a sneaky & replace one of the variables with ours.
	damageForce = {0.0, 0.0, 0.0};

	if(0 < attacker <= MaxClients){
		if(IsValidWeapon(weapon)){
			damageForce[0] += TF2Attrib_HookValueFloat(0.0, "dmg_dr_penetration", weapon);
		}

		if(hasBuffIndex(attacker, Buff_PiercingBuff)){
			damageForce[0] += playerBuffs[attacker][getBuffInArray(attacker, Buff_PiercingBuff)].severity;
		}
		
		if(!(damagetype & DMG_IGNOREHOOK)){
			baseDamage[attacker] = damage;

			if(damagetype & DMG_USEDISTANCEMOD)
				damagetype ^= DMG_USEDISTANCEMOD;

			if(IsValidClient3(victim) && IsValidClient3(attacker)){
				Address DodgeBody = TF2Attrib_GetByName(victim, "SET BONUS: chance of hunger decrease");
				if(DodgeBody != Address_Null){
					if(TF2Attrib_GetValue(DodgeBody) >= GetRandomFloat(0.0, 1.0))
						return Plugin_Stop;
				}
				if(damagetype & DMG_BURN && damagetype & DMG_PREVENT_PHYSICS_FORCE)
				{
					return Plugin_Stop;
				}
				if(victim == attacker && damagecustom == TF_CUSTOM_STICKBOMB_EXPLOSION){
					damage *= TF2Attrib_HookValueFloat(1.0, "dmg_outgoing_mult", weapon);
				}
				
				damage = genericPlayerDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
			}

			if (!IsValidClient3(inflictor) && IsValidEdict(inflictor))
				damage = genericSentryDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
		}
		
		if(!(damagetype & DMG_PIERCING) && attacker != victim){
			preDamageMitigationCalcs(victim, attacker, inflictor, damage, weapon, damageForce, damagetype, damagecustom);

			float armorPenetration = TF2Attrib_HookValueFloat(0.0, "armor_penetration_buff", attacker);
			float linearReduction = TF2Attrib_HookValueFloat(1.0, "dmg_taken_divided", victim);
			if(linearReduction != 1.0)
				damage /= linearReduction;

			if(!IsFakeClient(victim)){
				damage /= GetResistance(victim, _, armorPenetration);
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
		if(IsValidWeapon(weapon))
		{
			if(current_class[attacker] == TFClass_Spy && TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee){
				float backstabCapability = TF2Attrib_HookValueFloat(0.0, "backstab_tanks_capability", weapon);
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
					}
				}
			}
		}

		if (!IsValidClient3(inflictor) && IsValidEdict(inflictor))
			damage = genericSentryDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
		
		damage = genericPlayerDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
		if(IsValidWeapon(weapon))
		{
			if(TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee && TF2Attrib_HookValueFloat(0.0, "knockout_powerup", attacker) == 1)
				damage *= 1.35;

			if(weaponFireRate[weapon] > TICKRATE)
			{
				damage *= 1+(weaponFireRate[weapon]-TICKRATE)/TICKRATE;
			}
			applyDamageAffinities(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
		}
	}
	if(damage < 0.0)
	{
		damage = 0.0;
	}
	/*if(IsValidEdict(logic))
	{
		int round = GetEntProp(logic, Prop_Send, "m_nMannVsMachineWaveCount");
		damage *= (Pow(7500.0/(StartMoney+additionalstartmoney), DefenseMod + (DefenseIncreasePerWaveMod * round)) * 6.0)/OverallMod;
	}*/
	return Plugin_Changed;
}

public Action:OnTakeDamagePre_Sapper(victim, &attacker, &inflictor, float &damage, &damagetype, &weapon, float damageForce[3], float damagePosition[3], damagecustom) 
{
	int owner = GetEntPropEnt(victim, Prop_Send, "m_hBuilder"); 
	if(!IsValidClient3(owner) || !IsValidClient3(attacker))
		return Plugin_Continue;

	if(IsValidWeapon(weapon))
		damage = 50.0 * TF2Attrib_HookValueFloat(1.0, "mult_postfiredelay", weapon);
	return Plugin_Changed;
}

public Action:OnTakeDamagePre_Sentry(victim, &attacker, &inflictor, float &damage, &damagetype, &weapon, float damageForce[3], float damagePosition[3], damagecustom) 
{
	damageForce = {0.0, 0.0, 0.0};
	if(IsValidWeapon(weapon))
		damageForce[0] = TF2Attrib_HookValueFloat(0.0, "dmg_dr_penetration", weapon);

	int owner = GetEntPropEnt(victim, Prop_Send, "m_hBuilder");
	char SapperObject[128];
	GetEdictClassname(attacker, SapperObject, sizeof(SapperObject));
	if (StrEqual(SapperObject, "obj_attachment_sapper"))
	{
		int BuildingMaxHealth = GetEntProp(victim, Prop_Send, "m_iMaxHealth");
		damage = float(RoundToCeil(BuildingMaxHealth/110.0)); // in 110 ticks the sentry will be destroyed.

		int SapperOwner = GetEntPropEnt(attacker, Prop_Send, "m_hBuilder");
		if(IsValidClient3(SapperOwner))
		{
			int sapperItem = TF2Util_GetPlayerLoadoutEntity(SapperOwner, 6);
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
		if(!(damagetype & DMG_IGNOREHOOK)){
			damage = genericPlayerDamageModification(victim, attacker, inflictor, damage, weapon, damagetype, damagecustom);
			if(IsValidWeapon(weapon))
			{
				if(TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee && TF2Attrib_HookValueFloat(0.0, "knockout powerup", attacker) == 1)
					damage *= 1.35;
				
				if(weaponFireRate[weapon] > TICKRATE)
				{
					damage *= 1+(weaponFireRate[weapon]-TICKRATE)/TICKRATE;
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
		}
		if(GetEntProp(victim, Prop_Send, "m_bDisabled") == 1)
		{
			for(int i = 1;i<=MaxClients;++i)
			{
				if(!IsValidClient3(i) || GetClientTeam(i) != GetClientTeam(attacker))
					continue;

				if(TF2_GetPlayerClass(i) != TFClass_Spy)
					continue;

				int sapper = TF2Util_GetPlayerLoadoutEntity(i,5);
				if(!IsValidWeapon(sapper))
					continue;

				float sapperBonus = TF2Attrib_HookValueFloat(1.0, "apply_vuln_on_sapped", sapper);
				if(sapperBonus == 1.0)
					continue;

				damage *= sapperBonus;
			}
		}
	}
	if(IsValidClient3(owner))
	{
		if(!(damagetype & DMG_PIERCING) && attacker != owner){
			float armorPenetration = TF2Attrib_HookValueFloat(0.0, "armor_penetration_buff", attacker);
			float linearReduction = TF2Attrib_HookValueFloat(1.0, "dmg_taken_divided", owner);
			if(linearReduction != 1.0)
				damage /= linearReduction;

			if(!IsFakeClient(owner)){
				damage /= GetResistance(owner, true, armorPenetration);
			}else{
				//Armor penetration just gives +10% damage on bots.
				damage *= 1.0 + armorPenetration*0.1;
			}
		}
		
		applyDamageAffinities(owner, attacker, inflictor, damage, weapon, damagetype, damagecustom);
	}
	return Plugin_Changed;
}
public Action OnTakeDamage_MedicShield(victim, &attacker, &inflictor, float &damage, &damagetype, &weapon, float damageForce[3], float damagePosition[3], damagecustom)
{
	damageForce = {0.0, 0.0, 0.0};
	if(IsValidWeapon(weapon))
		damageForce[0] = TF2Attrib_HookValueFloat(0.0, "dmg_dr_penetration", weapon);

	if(0 < attacker <= MaxClients){
		int owner = getOwner(victim);
		if(!IsValidClient3(owner))
			return Plugin_Continue;
		
		if(!(damagetype & DMG_IGNOREHOOK)){
			baseDamage[attacker] = damage;

			if(damagetype & DMG_USEDISTANCEMOD)
				damagetype ^= DMG_USEDISTANCEMOD;

			if(IsClientInGame(attacker)){
				damage = genericPlayerDamageModification(owner, attacker, inflictor, damage, weapon, damagetype, damagecustom);
			}

			if (!IsValidClient3(inflictor) && IsValidEdict(inflictor)){
				damage = genericSentryDamageModification(owner, attacker, inflictor, damage, weapon, damagetype, damagecustom);
			}
		}
		
		if(!(damagetype & DMG_PIERCING) && attacker != owner){
			float armorPenetration = TF2Attrib_HookValueFloat(0.0, "armor_penetration_buff", attacker);
			float linearReduction = TF2Attrib_HookValueFloat(1.0, "dmg_taken_divided", owner);
			if(linearReduction != 1.0)
				damage /= linearReduction;

			if(!IsFakeClient(owner)){
				damage /= GetResistance(owner, true, armorPenetration);
			}else{
				damage *= 1.0 + armorPenetration*0.1;
			}
		}
		float currentRage = GetEntPropFloat(owner, Prop_Send, "m_flRageMeter");
		if(currentRage > 0.0 && GetEntProp(owner, Prop_Send, "m_bRageDraining")){
			currentRage -= 33.34*damage/float(TF2Util_GetEntityMaxHealth(owner));
			if(currentRage < 0.0)
				currentRage = 0.0;
			SetEntPropFloat(owner, Prop_Send, "m_flRageMeter", currentRage)
		}
	}
	return Plugin_Changed;
}
public void preDamageMitigationCalcs(victim, attacker, inflictor, float& damage, weapon, float damageForce[3], damagetype, damagecustom){
	float strengthPowerupValue = TF2Attrib_HookValueFloat(0.0, "strength_powerup", attacker);
	if(strengthPowerupValue == 1.0){
		damage *= 2.0;
	}
	else if(strengthPowerupValue == 3.0 && victim != attacker){
		Buff finisherDebuff; finisherDebuff.init("Bruised", "Marked-for-Finisher", Buff_Bruised, 1, attacker, 8.0);
		insertBuff(victim, finisherDebuff);
	}

	if(RageActive[attacker] == true && TF2Attrib_HookValueFloat(0.0, "revenge_powerup", attacker) == 1)
		damage *= 1.5;
	if(TF2Attrib_HookValueFloat(0.0, "revenge_powerup", attacker) == 2)
		damage *= 1 + RageBuildup[attacker]*0.5;
	
	if(TF2Attrib_HookValueFloat(0.0, "precision_powerup", attacker) == 1)
		damage *= 1.35;
		
	if(IsValidEntity(inflictor) && isAimlessProjectile[inflictor]){
		float victimPosition[3];
		GetEntPropVector(victim, Prop_Data, "m_vecOrigin", victimPosition); 
		float projectilePosition[3];
		GetEntPropVector(inflictor, Prop_Data, "m_vecOrigin", projectilePosition); 
		float distance = GetVectorDistance(victimPosition, projectilePosition);
		if(distance <= 60)
			distance = 0.0;
		
		if(distance <= 250){
			damage *= 1+3*((250-distance)/250);
		}
	}

	if(IsValidClient3(tagTeamTarget[attacker])){
		if(isTagged[tagTeamTarget[attacker]][victim]){
			if(TF2Attrib_HookValueFloat(0.0, "king_powerup", attacker) == 2)
				damage *= 1.75
		}
	}
	else if(hasBuffIndex(attacker, Buff_TagTeam)) {
		Buff tagTeamBuff;
		tagTeamBuff = playerBuffs[attacker][getBuffInArray(attacker, Buff_TagTeam)]
		if(isTagged[tagTeamBuff.inflictor][victim]){
			if(TF2Attrib_HookValueFloat(0.0, "king_powerup", tagTeamBuff.inflictor) == 2)
				damage *= 1.75
		}
	}

	float velocity[3];
	GetEntPropVector(attacker, Prop_Data, "m_vecAbsVelocity", velocity);

	if(velocity[2] < -400.0){
		if(TF2Attrib_HookValueFloat(0.0, "agility_powerup", attacker) == 2){
			damage *= 1.0 + (-velocity[2]-400.0)*0.001;
		}
		if(IsValidWeapon(weapon)){
			float fallingBonus = TF2Attrib_HookValueFloat(0.0, "falling_velocity_to_damage_mult", weapon);
			if(fallingBonus != 0.0){
				damage *= 1.0 + (-velocity[2]-400.0)*0.001*fallingBonus;
			}
		}
	}

	//Guardian
	if(!(damagetype & DMG_REFLECT)){
		int guardian = -1;
		float guardianPercentage;
		float victimPos[3];
		GetClientAbsOrigin(victim, victimPos);
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
			// 1400 HU Radius
			if(GetVectorDistance(victimPos,guardianPos, true) < 1960000)
			{
				int guardianWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
				if(IsValidWeapon(guardianWeapon)){
					float redirect = TF2Attrib_HookValueFloat(0.0, "redirect_teammate_damage_taken", i);
					if(redirect > 0.0){
						if(redirect > guardianPercentage){
							guardian = i;
							guardianPercentage = redirect;
						}
					}
				}
			}
		}
		if(IsValidClient3(guardian)){
			SDKHooks_TakeDamage(guardian, attacker, attacker, damage*guardianPercentage,DMG_PREVENT_PHYSICS_FORCE|DMG_REFLECT|DMG_IGNOREHOOK,_,_,_,false);
			damage *= ConsumePierce((1-guardianPercentage), damageForce[0]);
		}

		if(TF2Attrib_HookValueFloat(0.0, "supernova_powerup", attacker) == 1.0)
		{
			if(damagetype & DMG_BLAST || hasSupernovaSplashed[attacker])
			{
				damage *= 1.8;
			}
			else
			{
				damage *= 1.35;
				float victimPosition[3];
				GetEntPropVector(victim, Prop_Data, "m_vecOrigin", victimPosition); 
				
				EntityExplosion(attacker, damage, 300.0,victimPosition,_,weaponArtParticle[attacker] <= GetGameTime() ? true : false, victim, weaponArtParticle[attacker] <= GetGameTime() ? 0.8 : 0.0, DMG_BLAST|DMG_REFLECT,weapon, 0.5);
				hasSupernovaSplashed[attacker] = true;
				//PARTICLES
				if(weaponArtParticle[attacker] <= GetGameTime())
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
					weaponArtParticle[attacker] = GetGameTime()+1.0;
				}
			}
		}
		if((TF2Attrib_HookValueFloat(0.0, "supernova_powerup", attacker) == 3 || damagetype & DMG_SHOCK) && !hasSupernovaSplashed[attacker]){
			int team = GetClientTeam(attacker);
			float arcDamage = damage * 0.75;
			for(int i = 1;i<=MaxClients;++i){
				if(!IsValidClient3(i))
					continue;
				if(!IsPlayerAlive(i))
					continue;
				if(!isTagged[attacker][i])
					continue;
				if(victim == i)
					continue;
				if(GetClientTeam(i) == team)
					continue;
				if(IsPlayerInSpawn(i))
					continue;

				SDKHooks_TakeDamage(i, attacker, attacker, arcDamage, DMG_SHOCK|DMG_IGNOREHOOK|DMG_REFLECT, _,_,_,false);
			}
			hasSupernovaSplashed[attacker] = true;
		}

		int jaratedIndex = getBuffInArray(victim, Buff_Jarated);
		if(jaratedIndex != -1 && IsValidClient3(playerBuffs[victim][jaratedIndex].inflictor)){
			SDKHooks_TakeDamage(victim,playerBuffs[victim][jaratedIndex].inflictor,playerBuffs[victim][jaratedIndex].inflictor,5.0*playerBuffs[victim][jaratedIndex].priority,DMG_REFLECT|DMG_DISSOLVE|DMG_IGNOREHOOK,_,_,_,false);
		}
		
		if(IsValidWeapon(weapon)){
			int championIndex = getBuffInArray(victim, Buff_ChampionMark);
			if(championIndex != -1 && IsValidClient3(playerBuffs[victim][championIndex].inflictor)){
				SDKHooks_TakeDamage(victim,playerBuffs[victim][championIndex].inflictor,playerBuffs[victim][championIndex].inflictor,playerBuffs[victim][championIndex].severity / TF2_GetFireRate(attacker,weapon,0.8),DMG_REFLECT|DMG_DISSOLVE|DMG_IGNOREHOOK,_,_,_,false);
			}

			float chainLightningAttribute = GetAttribute(weapon, "chain lightning meter on hit", 0.0)
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
						SDKHooks_TakeDamage(target,attacker,attacker,100.0*TF2_GetDamageModifiers(attacker, weapon),DMG_REFLECT|DMG_IGNOREHOOK,_,_,_,false)
						++i
					}
				}
			}
		}
	}

	//Lifesteal
	float lifestealFactor = 0.0;
	float lsCap = 0.5;
	//Additive sources first
	if(IsValidWeapon(weapon))
		lifestealFactor += TF2Attrib_HookValueFloat(0.0, "lifesteal_ability", weapon);//Lifesteal attribute
	else
		lifestealFactor += GetAttribute(attacker, "lifesteal ability", 0.0);//Lifesteal attribute

	if(MadmilkDuration[victim] > GetGameTime()) // Madmilk
		lifestealFactor += (MadmilkDuration[victim]-GetGameTime()) * 1.6667 / 100.0;

	if(TF2_IsPlayerInCondition(attacker, TFCond_MedigunDebuff))// Conch
		lifestealFactor += 0.25;
	
	//Then multiplicative sources
	float vampirePowerup = TF2Attrib_HookValueFloat(0.0, "vampire_powerup", attacker);//Vampire Powerup
	if(vampirePowerup == 1){
		lifestealFactor += 0.85;
		lsCap *= 3.0;
	}
	else if(vampirePowerup == 3){
		lifestealFactor += 0.5;
	}
	
	if(IsValidWeapon(weapon))
		lifestealFactor *= TF2Attrib_HookValueFloat(1.0, "lifesteal_effectiveness", weapon);

	if(hasBuffIndex(attacker, Buff_Plunder)){
		Buff plunderBuff;
		plunderBuff = playerBuffs[attacker][getBuffInArray(attacker, Buff_Plunder)]
		lifestealFactor *= plunderBuff.severity;
	}
	if(lifestealFactor > 0){
		float addedLSPool = lifestealFactor * damage / GetResistance(attacker, true);
		if(vampirePowerup == 3) {
			if(GetClientHealth(attacker) >= TF2Util_GetEntityMaxHealth(attacker)) {
				if(Overleech[attacker] < TF2Util_GetEntityMaxHealth(attacker) * 9){
					Overleech[attacker] += addedLSPool;
					addedLSPool = 0.0;
				}
			}
		}
		LSPool[attacker] += addedLSPool;
		if(LSPool[attacker] > lsCap*TF2Util_GetEntityMaxHealth(attacker)) {
			LSPool[attacker] = lsCap*TF2Util_GetEntityMaxHealth(attacker);
		}
		if(IsValidEntity(inflictor)){
			char inflictorClassname[32];
			GetEdictClassname(inflictor, inflictorClassname, sizeof(inflictorClassname));
			if(StrEqual("tf_projectile_sentryrocket", inflictorClassname)){
				inflictor = getOwner(inflictor);
				GetEdictClassname(inflictor, inflictorClassname, sizeof(inflictorClassname));
			}
			if(StrEqual("obj_sentrygun", inflictorClassname)){
				AddBuildingHealth(inflictor, RoundToCeil(addedLSPool), attacker);
			}
		}
	}
}
public float genericPlayerDamageModification(victim, attacker, inflictor, float damage, weapon, damagetype, damagecustom)
{
	bool isVictimPlayer = IsValidClient3(victim);

	if(!IsOnDifferentTeams(victim, attacker))
		return damage;

	float flatDamage = TF2Attrib_HookValueFloat(0.0, "additive_damage", attacker);
	if(IsValidWeapon(weapon)){
		float resistanceToFlatDamage = TF2Attrib_HookValueFloat(0.0, "damage_reduction_to_additive_damage", weapon);
		if(resistanceToFlatDamage > 0.0)
			flatDamage += TF2Attrib_HookValueFloat(0.0, "quadratic_damage_reduction", attacker) * resistanceToFlatDamage;
	}
	if(flatDamage > 0){
		damage += flatDamage;
	}

	if(isVictimPlayer)
	{
		if(IsFakeClient(attacker) && IsPlayerInSpawn(attacker)){
			return 0.0;
		}

		if(hasBuffIndex(victim, Buff_DragonDance) && playerBuffs[victim][getBuffInArray(victim, Buff_DragonDance)].inflictor == attacker){
			int temp = getBuffInArray(victim, Buff_DragonDance);
			if(playerBuffs[victim][temp].priority != weapon){
				SDKHooks_TakeDamage(victim,attacker,playerBuffs[victim][temp].inflictor,TF2_GetWeaponclassDPS(attacker, playerBuffs[victim][temp].priority) * TF2_GetDPSModifiers(attacker, playerBuffs[victim][temp].priority) * 2.5,DMG_DISSOLVE|DMG_IGNOREHOOK,_,_,_,false);
				clearBuff(victim, temp);
				buffChange[victim]=true;
			}
		}

		if(damagetype == 2052 && damagecustom == 3 && TF2_GetPlayerClass(attacker) == TFClass_Pyro){
			int secondary = TF2Util_GetPlayerLoadoutEntity(attacker,1);
			if(IsValidEdict(secondary) && weapon == secondary){
				damage *= TF2Attrib_HookValueFloat(1.0, "explosion_damage_bonus", weapon);
				damagetype |= DMG_IGNITE;
			}
		}
		if(TF2_GetPlayerClass(victim) == TFClass_Spy && (TF2_IsPlayerInCondition(victim, TFCond_Cloaked) || TF2_IsPlayerInCondition(victim, TFCond_Stealthed))){
			float CloakResistance = TF2Attrib_HookValueFloat(1.0, "absorb damage while cloaked", victim);
			if(CloakResistance != 1.0)
				damage *= CloakResistance;
		}
	}
	
	if(IsValidWeapon(weapon))
	{
		float medicBoost = 1.0;
		float medicWeakness = 1.0;
		
		float multPerStatusEffect = TF2Attrib_HookValueFloat(0.0, "damage_bonus_per_status_effect_on_self", weapon);
		if(multPerStatusEffect != 0.0){
			damage *= 1+multPerStatusEffect*GetAmountOfBuffs(attacker)*GetAmountOfDebuffs(attacker);
		}
		if(isVictimPlayer && attacker != victim)
		{
			float minicritVictimOnHit = TF2Attrib_HookValueFloat(0.0, "mark_for_death_on_hit_duration", weapon);
			if(minicritVictimOnHit > 0 && minicritVictimOnHit > miniCritStatusVictim[victim]-GetGameTime())
				miniCritStatusVictim[victim] = GetGameTime()+minicritVictimOnHit;
			
			float rageOnHit = TF2Attrib_HookValueFloat(0.0, "rage_on_hit", weapon);
			if(rageOnHit != 0.0)
			{
				if(GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter") < 100.0)
					SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter") + rageOnHit)
			}
			int hitgroup = GetEntProp(victim, Prop_Data, "m_LastHitGroup");
			if(damagetype & DMG_BULLET && hitgroup == 1)
			{
				float HeadshotsActive = TF2Attrib_HookValueFloat(0.0, "weapon_can_headshot", weapon);
				if(HeadshotsActive > 0)
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
				if(TF2Attrib_HookValueFloat(0.0, "precision_powerup", attacker) == 1)
				{
					miniCritStatus[victim] = true;
					damagecustom = 1;
				}
			}
			if(TF2_IsPlayerInCondition(victim,TFCond_TmpDamageBonus))
			{
				damage *= 1.3;
			}

			int drainers = GetEntProp(victim, Prop_Send, "m_nNumHealers");
			if(drainers > 0)
			{
				for(int i = 0;i<drainers;++i){
					int drainer = TF2Util_GetPlayerHealer(victim,i);
					if(!IsValidClient3(drainer))
						continue;
					
					int healingWeapon = GetEntPropEnt(drainer, Prop_Send, "m_hActiveWeapon");
					if(!IsValidWeapon(healingWeapon))
						continue;
					
					if(IsOnDifferentTeams(attacker, drainer)){
						// Using exhaust on vaccinator decreases damage dealt by the average of the resistances.
						float exhaustCoefficient = TF2Attrib_HookValueFloat(0.0, "vaccinator_exhaust_attribute", healingWeapon);
						if(exhaustCoefficient > 0.0){
							float appliedWeakness = 1.0-((TF2Attrib_HookValueFloat(0.0, "medigun_bullet_resist_deployed", healingWeapon)+
								TF2Attrib_HookValueFloat(0.0, "medigun_blast_resist_deployed", healingWeapon)+
								TF2Attrib_HookValueFloat(0.0, "medigun_fire_resist_deployed", healingWeapon))/3.0*exhaustCoefficient);

							if(appliedWeakness < medicWeakness)
								medicWeakness = appliedWeakness;
						}
					}
				}
			}
		}
		char classname[64]; 
		GetEdictClassname(weapon, classname, sizeof(classname));
		if(StrEqual(classname, "tf_weapon_syringegun_medic"))
			damage *= 1.8
		if(TF2Attrib_HookValueFloat(0.0, "precision_powerup", attacker) == 3){
			if(! ( StrEqual(classname, "tf_weapon_flamethrower") || StrEqual(classname, "tf_weapon_rocketlauncher_fireball") ) ){
				damage *= 4.0;
			}
		}

		int healers = GetEntProp(attacker, Prop_Send, "m_nNumHealers");
		if(healers > 0)
		{
			for(int i = 0;i<healers;++i){
				int healer = TF2Util_GetPlayerHealer(attacker,i);
				if(!IsValidClient3(healer))
					continue;
				
				int healingWeapon = GetEntPropEnt(healer, Prop_Send, "m_hActiveWeapon");
				if(!IsValidWeapon(healingWeapon))
					continue;
				
				if(!IsOnDifferentTeams(attacker, healer)){
					float appliedBoost = 1.0 + TF2Attrib_HookValueFloat(0.0, "patient_damage_bonus", healingWeapon);

					if(TF2_IsPlayerInCondition(attacker, TFCond_Kritzkrieged))
						appliedBoost += GetAttribute(healingWeapon, "ubercharge effectiveness", 1.0)-1.0;

					appliedBoost *= TF2Attrib_HookValueFloat(1.0, "healing_patient_power", healingWeapon);
					if(appliedBoost > medicBoost)
						medicBoost = appliedBoost;
				}
			}
		}
		damage *= medicBoost * medicWeakness;
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
						
					int healingWeapon = GetEntPropEnt(healer, Prop_Send, "m_hActiveWeapon");
					if(!IsValidWeapon(healingWeapon))
						continue;
					
					if(!IsOnDifferentTeams(healer, victim)){
						if(GetClientHealth(victim) > TF2Util_GetEntityMaxHealth(victim))
							medicRESBonus += TF2Attrib_HookValueFloat(0.0, "patient_overheal_to_damage_mult", healingWeapon);

						if(TF2_IsPlayerInCondition(healer, TFCond_UberFireResist) || TF2_IsPlayerInCondition(healer, TFCond_UberBulletResist) || TF2_IsPlayerInCondition(healer, TFCond_UberBlastResist))
							medicRESBonus += GetAttribute(healingWeapon, "ubercharge effectiveness", 1.0)-1.0;

						medicRESBonus *= TF2Attrib_HookValueFloat(1.0, "healing_patient_power", healingWeapon);
					}
				}
			}
		}
		damage /= medicRESBonus;

		if(!(damagetype & DMG_PIERCING)){
			float additivePiercingDamage = TF2Attrib_HookValueFloat(0.0, "additive_piercing_damage", weapon);
			if(additivePiercingDamage != 0){
				SDKHooks_TakeDamage(victim, inflictor, attacker, additivePiercingDamage, DMG_PREVENT_PHYSICS_FORCE|DMG_IGNOREHOOK|DMG_PIERCING);
			}
		}

		/*
		**	Custom Damage Compatibility Rules
		*/

		//Bullets per shot gives damage instead on projectile overrides.
		float overrideproj = GetAttribute(weapon, "override projectile type");
		if(overrideproj != 1.0){
			damage *= TF2Attrib_HookValueFloat(1.0, "mult_bullets_per_shot", weapon);
		}

		//Cow Mangler Charged Shots receive a bonus from clip size upgrades.
		if(damagecustom == TF_CUSTOM_PLASMA_CHARGED){
			damage *= TF2Attrib_HookValueFloat(1.0, "mult_clipsize_upgrade", weapon);
			damagetype |= DMG_CRIT;
		}

		if(damagetype & DMG_SLASH && damagecustom == TF_CUSTOM_BLEEDING){
			damage /= Pow(TF2Attrib_HookValueFloat(1.0, "mult_postfiredelay", weapon),  0.8);
		}

		float missingHealthDamageBonus = TF2Attrib_HookValueFloat(0.0, "dmg_per_pct_hp_missing", weapon);
		if(missingHealthDamageBonus > 0.0){
			float ratio = GetClientHealth(attacker)/float(TF2Util_GetEntityMaxHealth(attacker));
			if(ratio < 1.0)
				damage *= 1+(missingHealthDamageBonus*100.0)*(1-ratio);
		}

		if(stickiesDetonated[attacker] > 0){
			damage *= 1+TF2Attrib_HookValueFloat(0.0, "dmg_per_sticky_detonated", weapon)*stickiesDetonated[attacker];
		}

		if(isVictimPlayer)
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
			if(immolationActive[attacker]){
				float immolationRatio = TF2Attrib_HookValueFloat(0.0, "immolation_ratio", weapon);
				if(immolationRatio > 0.0){
					Buff immolationStatus;
					immolationStatus.init("Immolation Burn", "Rapidly losing health", Buff_ImmolationBurn, 1, attacker, 8.0, 2.0*immolationRatio*damage);
					insertBuff(victim, immolationStatus);
				}
			}
			if(damagetype & DMG_CLUB){
				float infernalExplosive = TF2Attrib_HookValueFloat(0.0, "dragon_bullets_radius", weapon);
				if(infernalExplosive){
					float enemyPos[3];
					GetClientEyePosition(victim, enemyPos);
					EntityExplosion(attacker, damage, infernalExplosive, enemyPos, _, _, _, _, _, weapon, _, _, true);
					CreateParticleEx(victim, "heavy_ring_of_fire");
				}
			}
			float bouncingBullets = TF2Attrib_HookValueFloat(0.0, "sniper_charged_shots_bounce", weapon);
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
					SDKHooks_TakeDamage(client,attacker,attacker,damage,damagetype|DMG_IGNOREHOOK,_,_,_,false)
					++i
				}
			}
			float conferenceBonus = TF2Attrib_HookValueFloat(0.0, "conference_call_damage", weapon);
			if(conferenceBonus && baseDamage[attacker] > 0)
			{
				float victimPos[3];
				GetClientEyePosition(victim, victimPos);
				int tracerCount = RoundToCeil(TF2Attrib_HookValueFloat(1.0, "conference_call_tracer_count", weapon));

				for(int i = 0; i < 2; ++i){
					float pos1[3],pos2[3];

					float vecangles[3];
					if(i == 0){
						vecangles = {0.0,90.0,0.0};
					}else if(i == 1){
						vecangles = {0.0,0.0,0.0};
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
					for(int t = 0; t < tracerCount;t++){
						float offset[3];offset[0] = GetRandomFloat(-10.0, 10.0);offset[1] = GetRandomFloat(-10.0, 10.0);offset[2] = GetRandomFloat(-10.0, 10.0);
						float endpos1[3], endpos2[3];
						AddVectors(pos1, offset, endpos1);
						AddVectors(pos2, offset, endpos2);

						if(GetRandomInt(0,1))
							SpawnBulletTracer(endpos1, endpos2, "bullet_tracer02_blue");
						else
							SpawnBulletTracer(endpos2, endpos1, "bullet_tracer02_blue");
					}
				}
				for(int i = 1; i< MAXENTITIES; ++i){
					if(penetrationCount[i] > 0){
						SDKHooks_TakeDamage(i,attacker,attacker,baseDamage[attacker]*TF2_GetDamageModifiers(attacker, weapon)*conferenceBonus,DMG_BULLET|DMG_IGNOREHOOK,_,_,_,false);
						penetrationCount[i] = 0;
					}
				}
			}
		}

		if(LightningEnchantmentDuration[attacker] > GetGameTime() && !(damagetype & DMG_VEHICLE)){
			SDKHooks_TakeDamage(victim,attacker,attacker,LightningEnchantment[attacker] / TF2_GetFireRate(attacker,weapon,0.8),DMG_IGNOREHOOK,_,_,_,false);
		}
		else if(DarkmoonBladeDuration[attacker] > GetGameTime()){
			int melee = TF2Util_GetPlayerLoadoutEntity(attacker,2);
			if(melee == weapon){
				SDKHooks_TakeDamage(victim,attacker,attacker,DarkmoonBlade[attacker],DMG_IGNOREHOOK,_,_,_,false);
			}
		}
		
		float arcaneWeaponScaling = TF2Attrib_HookValueFloat(0.0, "arcane_weapon_scaling", weapon);
		if(arcaneWeaponScaling != 0.0){
			arcaneWeaponScaling *= GetAttribute(weapon, "damage mult 15");
			SDKHooks_TakeDamage(victim,attacker,attacker,ArcaneDamage[attacker] * arcaneWeaponScaling,DMG_IGNOREHOOK,_,_,_,false);
		}
		
		if(weaponFireRate[weapon] > 0.0){
			if(weaponFireRate[weapon] > TICKRATE)
			{
				damage *= 1+(weaponFireRate[weapon]-TICKRATE)/TICKRATE;
			}
			int secondary = TF2Util_GetPlayerLoadoutEntity(attacker, 1);
			if(IsValidWeapon(secondary)){
				float inheritanceRatio = TF2Attrib_HookValueFloat(0.0, "dps_inheritance_ratio", attacker);
				if(inheritanceRatio){
					float strongestDPS = 0.0;
					for(int e = 0;e<3;++e){
						int tempWeapon = TF2Util_GetPlayerLoadoutEntity(attacker, e);
						if(!IsValidWeapon(tempWeapon) || tempWeapon == weapon)
							continue;
						float currentDPS = TF2_GetWeaponclassDPS(attacker, tempWeapon) * TF2_GetDPSModifiers(attacker, tempWeapon);
						if(currentDPS > strongestDPS)
							strongestDPS = currentDPS;
					}
					SDKHooks_TakeDamage(victim,attacker,attacker,inheritanceRatio*strongestDPS/weaponFireRate[weapon],DMG_IGNOREHOOK,_,_,_,false);
				}
			}
		}

		if(isVictimPlayer){
			int detonateStacks = RoundToNearest(TF2Attrib_HookValueFloat(0.0, "detonate_afterburn_stacks_on_hit", weapon));
			float detonateAccumulation = 0.0;
			for(int i = 0;i<MAX_AFTERBURN_STACKS;++i){
				if(detonateStacks <= 0)
					break;

				if(playerAfterburn[victim][i].remainingTicks <= 0)
					continue;

				if(playerAfterburn[victim][i].owner != attacker)
					continue;

				detonateAccumulation += playerAfterburn[victim][i].damage * playerAfterburn[victim][i].remainingTicks;
				playerAfterburn[victim][i].remainingTicks = 0;
				detonateStacks--;
			}
			if(detonateAccumulation > 0){
				SDKHooks_TakeDamage(victim, attacker, attacker, detonateAccumulation, DMG_BURN|DMG_PREVENT_PHYSICS_FORCE|DMG_IGNOREHOOK, _, _, _, false);
				if(GetGameTime() > detonateParticleCooldown[attacker]){
					CreateParticleEx(victim, "bombinomicon_burningdebris");
					detonateParticleCooldown[attacker] = GetGameTime() + 0.5;
				}
			}else{
				//afterburn slop
				if(damagetype & DMG_IGNITE || 
				(GetClientTeam(attacker) != GetClientTeam(victim) &&
				(TF2Attrib_HookValueFloat(0.0, "afterburn_rating", weapon) ||
				TF2Attrib_HookValueFloat(0.0, "supernova_powerup", weapon) == 2) &&
				!(damagetype & DMG_BURN && damagetype & DMG_PREVENT_PHYSICS_FORCE) &&
				!(damagetype & DMG_SLASH))) // int afterburn system.
				{
					applyAfterburn(victim, attacker, weapon, damage);
				}
			}

			if(IsValidClient3(attacker)){
				healers = GetEntProp(attacker, Prop_Send, "m_nNumHealers");
				for(int i = 0;i<healers;++i){
					int healer = TF2Util_GetPlayerHealer(attacker,i);
					if(!IsValidClient3(healer))
						continue;

					int healingWeapon = GetEntPropEnt(healer, Prop_Send, "m_hActiveWeapon");
					if(!IsValidWeapon(healingWeapon))
						continue;

					if(TF2Attrib_HookValueFloat(0.0, "magnify_patient_damage", healingWeapon))
						pylonCharge[healer] += damage;

					float pylonCap = TF2Util_GetEntityMaxHealth(healer) * GetResistance(healer);
					if(pylonCharge[healer] >= pylonCap && GetGameTime() >= pylonCooldown[healer]){
						float pylonDamage = 0.65*pylonCap;
						pylonCooldown[healer] = GetGameTime()+1.0;

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
						SDKHooks_TakeDamage(victim,healer,healer,pylonDamage,DMG_BULLET|DMG_IGNOREHOOK,_,_,_,false)

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
							SDKHooks_TakeDamage(client,healer,healer,pylonDamage,DMG_BULLET|DMG_IGNOREHOOK,_,_,_,false)
							++iterations
						}

						pylonCharge[healer] -= pylonCap;
						if(pylonCharge[healer] > pylonCap)
							pylonCharge[healer]  = pylonCap;
						EmitSoundToAll(SOUND_ARCANESHOOT, 1, _, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,startpos);
					}
				}
			}
		}
	}
	return damage;
}
public float genericSentryDamageModification(victim, attacker, inflictor, float damage, weapon, damagetype, damagecustom)
{
	char classname[64];
	GetEdictClassname(inflictor, classname, sizeof(classname));
	if(StrEqual("tf_projectile_sentryrocket", classname)){
		inflictor = getOwner(inflictor);
		GetEdictClassname(inflictor, classname, sizeof(classname));
	}
	
	int weaponIdx = (IsValidWeapon(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
	bool isVictimPlayer = IsValidClient3(victim);

	if (isVictimPlayer && StrEqual(classname, "obj_attachment_sapper"))
		TF2_AddCondition(victim, TFCond_Sapped, 2.0);

	if ((StrEqual("obj_sentrygun", classname)) || weaponIdx == 140)
	{
		int owner; 
		owner = GetEntPropEnt(inflictor, Prop_Send, "m_hBuilder");

		/*if(IsValidForDamage(owner))
		{
			char Ownerclassname[64]; 
			GetEdictClassname(owner, Ownerclassname, sizeof(Ownerclassname)); 
			if(StrEqual(Ownerclassname, "tank_boss"))
			{
				//damage *= TankSentryDamageMod;
				damagetype |= DMG_PREVENT_PHYSICS_FORCE;
			}
		}*/
		if(IsValidClient3(owner))
		{
			damagetype |= DMG_PREVENT_PHYSICS_FORCE;

			int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
			if(IsValidWeapon(CWeapon))
			{
				Address SentryDmgActive = TF2Attrib_GetByName(CWeapon, "ring of fire while aiming");
				if(SentryDmgActive != Address_Null)
				{
					damage *= TF2Attrib_GetValue(SentryDmgActive);
				}
			}

			int secondary = TF2Util_GetPlayerLoadoutEntity(owner, 1);
			if(IsValidWeapon(secondary)){
				damage *= 1+GetEntProp(inflictor, Prop_Send, "m_iKills")*TF2Attrib_HookValueFloat(0.0, "sentry_dmg_bonus_per_kill", secondary);
			}
			if((StrEqual("obj_sentrygun", classname) && GetEntProp(inflictor, Prop_Send, "m_bMiniBuilding") == 1))
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
public void applyDamageAffinities(&victim, &attacker, &inflictor, float &damage, &weapon, &damagetype, &damagecustom)
{
	//Now's the time!
	if(damagetype & DMG_BURN || damagetype & DMG_SLOWBURN || damagetype & DMG_IGNITE)
	{
		if(TF2Attrib_HookValueFloat(0.0, "supernova_powerup", attacker) == 2){
			damage *= 1.5;

			//No more piercing flames!!!!!
			/*int team = GetClientTeam(attacker);

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
			}*/
		}
	}
	if(damagetype & DMG_SHOCK || damagetype & DMG_ENERGYBEAM)
	{
		if(TF2Attrib_HookValueFloat(0.0, "supernova_powerup", attacker) == 3){
			float buff = 1.0;
			for(int i = 1;i<=MaxClients;++i){
				if(isTagged[attacker][i])
					buff += 0.08;
			}
			damage *= buff;
		}
	}
}

void ApplyVaccinatorDamageReduction(int victim, int damagetype, float& damage, float& pierce){
	if(damagetype & DMG_BLAST){
		if(TF2_IsPlayerInCondition(victim, TFCond_UberBlastResist)){
			damage *= ConsumePierce(0.25, pierce);
		}else if(TF2_IsPlayerInCondition(victim, TFCond_SmallBlastResist)){
			damage *= ConsumePierce(0.9, pierce);
		}
	}else if(damagetype & DMG_BURN | DMG_IGNITE){
		if(TF2_IsPlayerInCondition(victim, TFCond_UberFireResist)){
			damage *= ConsumePierce(0.25, pierce);
		}else if(TF2_IsPlayerInCondition(victim, TFCond_SmallFireResist)){
			damage *= ConsumePierce(0.9, pierce);
		}
	}else if(damagetype & DMG_BULLET){
		if(TF2_IsPlayerInCondition(victim, TFCond_UberBulletResist)){
			damage *= ConsumePierce(0.25, pierce);
		}else if(TF2_IsPlayerInCondition(victim, TFCond_SmallBulletResist)){
			damage *= ConsumePierce(0.9, pierce);
		}
	}
}