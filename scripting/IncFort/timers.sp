public Action:Timer_Second(Handle timer)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(singularBuysPerMinute[client] > 0)
			singularBuysPerMinute[client]--;
		if (IsValidClient3(client))
		{
			if(GetAttribute(client, "regeneration powerup", 0.0) == 1.0){
				for(int i=0;i<3;++i){
					int weapon = GetWeapon(client, i);
					if(!IsValidWeapon(weapon))
						continue;
					if(!HasEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"))
						continue;
					
					int type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"); 
					SetAmmo_Weapon(weapon, TF2Util_GetPlayerMaxAmmo(client, type, current_class[client]));
				}
			}
			else if(GetAttribute(client, "regeneration powerup", 0.0) == 2.0){
				for(int i=0;i<3;++i){
					int weapon = GetWeapon(client, i);
					if(!IsValidWeapon(weapon))
						continue;
					if(!HasEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"))
						continue;
					if(GetAttribute(weapon, "auto fires full clip all at once", 0.0) || GetAttribute(weapon, "auto fires full clip", 0.0))
						continue;

					if(HasEntProp(weapon, Prop_Send, "m_iClip1")){
						if(GetEntProp(weapon,Prop_Data,"m_iClip1")  == -1)
							SetAmmo_Weapon(weapon, TF2Util_GetPlayerMaxAmmo(client, GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"), current_class[client]));
						else
							SetEntProp(weapon, Prop_Send, "m_iClip1", 4*TF2Util_GetWeaponMaxClip(weapon));
					}
					if(HasEntProp(weapon, Prop_Send, "m_flEnergy")){
						SetEntPropFloat(weapon, Prop_Send, "m_flEnergy", 4.0*TF2Util_GetWeaponMaxClip(weapon));
					}
				}
			}
			

			fl_ArmorCap[client] = GetResistance(client);
			if(IsValidClient(client)){
				GetClientCookie(client, hArmorXPos, ArmorXPos[client], sizeof(ArmorXPos));
				GetClientCookie(client, hArmorYPos, ArmorYPos[client], sizeof(ArmorYPos));
			}

			//Arcane
			float arcanePower = 1.0;
			
			Address ArcaneActive = TF2Attrib_GetByName(client, "arcane power")
			if(ArcaneActive != Address_Null)
				arcanePower = TF2Attrib_GetValue(ArcaneActive);

			ArcanePower[client] = arcanePower;
			
			float arcaneDamageMult = 1.0;
			Address ArcaneDamageActive = TF2Attrib_GetByName(client, "arcane damage")
			if(ArcaneDamageActive != Address_Null)
				arcaneDamageMult = TF2Attrib_GetValue(ArcaneDamageActive);

			ArcaneDamage[client] = arcaneDamageMult;

			Address focusActive = TF2Attrib_GetByName(client, "arcane focus max")
			if(focusActive != Address_Null)
				fl_MaxFocus[client] = (TF2Attrib_GetValue(focusActive)+100.0)* Pow(arcanePower, 2.0);
			else
				fl_MaxFocus[client] = 100.0*arcanePower;

			Address regenActive = TF2Attrib_GetByName(client, "arcane focus regeneration")
			if(regenActive != Address_Null)
				fl_RegenFocus[client] = fl_MaxFocus[client] * 0.00015 * TF2Attrib_GetValue(regenActive) *  Pow(arcanePower, 2.0);
			else
				fl_RegenFocus[client] = fl_MaxFocus[client] * 0.00015 *  Pow(arcanePower, 2.0);
		}
	}
	if(IsMvM())
	{
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsValidClient3(i))
			{
				if(IsFakeClient(i) && !IsClientObserver(i) && IsPlayerAlive(i))
				{
					BotTimer[i] -= 1.0;
					if(BotTimer[i] <= 0.0)
					{
						BotTimer[i] = 45.0;
						if(TF2_IsPlayerInCondition(i, TFCond_UberchargedHidden) || IsPlayerInSpawn(i))
						{
							PrintToServer("Slaying %N due to staying ubered for too long.", i);
							ForcePlayerSuicide(i);
						}
					}
				}
			}
		}
	}
}
public Action:Timer_FixedVariables(Handle timer)
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if (!IsValidClient3(client) || !IsPlayerAlive(client))
			continue;

		if(disableMvMCash){
			SetEntProp(client, Prop_Send, "m_nCurrency", 0);
		}
		if(infiniteMoney){
			CurrencyOwned[client] = 9999999999999999.0;
		}

		int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

		ManagePlayerBuffs(client);

		Address conditionToggle = TF2Attrib_GetByName(client, "has pipboy build interface");
		if(conditionToggle != Address_Null)
		{
			if(TF2Attrib_GetValue(conditionToggle) > 1.0)
			{
				TF2_AddCondition(client, view_as<TFCond>(RoundToNearest(TF2Attrib_GetValue(conditionToggle))), 0.2);
			}
		}

		if(snowstormActive[client]){
			int spellLevel = RoundToNearest(GetAttribute(client, "arcane snowstorm", 0.0));
			if(spellLevel >= 1){
				float ratio = fl_CurrentFocus[client]/fl_MaxFocus[client];
				if(ratio >= 0.005){
					float damageDealt = (70.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), spellScaling[spellLevel]) * 90.0))*0.1 * ArcanePower[client];
					float explosionRadius[] = {0.0, 300.0, 600.0, 1500.0};
					float pos[3];
					GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
					EntityExplosion(client, damageDealt, explosionRadius[spellLevel], pos, -1, false, client, _, _, _, _, _, _, _, DMG_FROST);
					fl_CurrentFocus[client] -= fl_MaxFocus[client]*0.005/ArcanePower[client];
				}else{
					int particleEffect = EntRefToEntIndex(snowstormParticle[client]);
					if(IsValidEntity(particleEffect)){
						CreateTimer(0.1, Timer_KillParticle, snowstormParticle[client]);
					}
					snowstormActive[client] = false;
				}
			}
		}
		if(IsValidWeapon(CWeapon)){
			if(immolationActive[client]){
				float immolationRatio = GetAttribute(CWeapon, "immolation ratio", 0.0);
				if(immolationRatio > 0.0){
					currentDamageType[client].second |= DMG_PIERCING
					currentDamageType[client].second |= DMG_IGNOREHOOK;
					SDKHooks_TakeDamage(client, client, client, TF2Util_GetEntityMaxHealth(client)*immolationRatio*0.1, DMG_PREVENT_PHYSICS_FORCE,_,_,_,false);
				}
			}
			if(sunstarDuration[client] >= currentGameTime){
				float sunstarActive = GetAttribute(CWeapon, "apply look velocity on damage", 0.0);
				if(sunstarActive == 15.0){
					float clientpos[3], soundPos[3], clientAng[3], fwd[3];
					TracePlayerAim(client, clientpos);

					for(int i=1;i<=MaxClients;++i)
					{
						if(!IsValidClient3(i))
							continue;
						
						if(!IsPlayerAlive(i))
							continue;

						if(!IsOnDifferentTeams(client,i))
							continue;

						if(TF2_IsPlayerInCondition(i, TFCond_Ubercharged) || TF2_IsPlayerInCondition(i, TFCond_UberchargedHidden))
							continue;
						
						if(!IsTargetInSightRange(client, i, 10.0, 6000.0, true, false))
							continue;

						if(!IsAbleToSee(client,i, false))
							continue;
							
						GetClientEyePosition(i,clientpos);
						clientpos[2] -= 10.0;
						break;
					}
					
					GetClientEyePosition(client, soundPos);
					GetClientEyeAngles(client, clientAng);
					EmitSoundToAll(SOUND_ARCANESHOOT, 0, _, _, _, 0.5, _,_,soundPos);
					
					float particleOffset[3] = {0.0,0.0,75.0};
					char particleName[32];
					particleName = GetClientTeam(client) == 2 ? "muzzle_raygun_red" : "muzzle_raygun_blue";
					
					GetAngleVectors(clientAng,fwd, NULL_VECTOR, NULL_VECTOR);
					ScaleVector(fwd, 30.0);
					AddVectors(particleOffset, fwd, particleOffset);
					
					CreateParticle(client, particleName, false, "", 0.5, particleOffset);
					
					int iParti = CreateEntityByName("info_particle_system");
					int iPart2 = CreateEntityByName("info_particle_system");

					if (IsValidEdict(iParti) && IsValidEdict(iPart2))
					{
						char szCtrlParti[32];
						Format(szCtrlParti, sizeof(szCtrlParti), "tf2ctrlpart%i", iPart2);
						DispatchKeyValue(iPart2, "targetname", szCtrlParti);
						DispatchKeyValue(iParti, "effect_name", "merasmus_zap");
						DispatchKeyValue(iParti, "cpoint1", szCtrlParti);
						DispatchSpawn(iParti);
						TeleportEntity(iParti, soundPos, clientAng, NULL_VECTOR);
						TeleportEntity(iPart2, clientpos, NULL_VECTOR, NULL_VECTOR);
						ActivateEntity(iParti);
						AcceptEntityInput(iParti, "Start");
						
						CreateTimer(0.5, Timer_KillParticle, EntIndexToEntRef(iParti));
						CreateTimer(0.5, Timer_KillParticle, EntIndexToEntRef(iPart2));
					}

					float LightningDamage = 5.0*TF2_GetDPSModifiers(client, CWeapon);
					int i = -1;
					while ((i = FindEntityByClassname(i, "*")) != -1)
					{
						if(!IsValidForDamage(i))
							continue;
						if(!IsOnDifferentTeams(client,i))
							continue;

						float VictimPos[3];
						GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
						VictimPos[2] += 30.0;

						if(GetVectorDistance(clientpos,VictimPos,true) > 40000.0)
							continue;

						if(!IsPointVisible(clientpos,VictimPos))
							continue;

						currentDamageType[client].second |= DMG_IGNOREHOOK;
						SDKHooks_TakeDamage(i,client,client,LightningDamage,DMG_SHOCK,CWeapon,_,_,false);
					}
				}
			}
		}
		if(hasBuffIndex(client, Buff_ImmolationBurn)){
			Buff info;
			info = playerBuffs[client][getBuffInArray(client, Buff_ImmolationBurn)];
			if(IsValidClient3(info.inflictor)){
				if(info.severity > 0.0){
					currentDamageType[info.inflictor].second |= DMG_PIERCING
					currentDamageType[info.inflictor].second |= DMG_IGNOREHOOK;
					SDKHooks_TakeDamage(client, info.inflictor, info.inflictor, TF2Util_GetEntityMaxHealth(info.inflictor)*info.severity*0.1, DMG_PREVENT_PHYSICS_FORCE,_,_,_,false);
				}
			}
		}

		if(GetAttribute(client, "resistance powerup", 0.0) != 3.0){
			if(strongholdEnabled[client]){
				SetEntityMoveType(client, MOVETYPE_WALK);
				PrintHintText(client, "Stronghold Disabled");
				strongholdEnabled[client] = false;
			}
		}

		if(IsFakeClient(client))
			continue;
		
		if(inScore[client] == false)
		{
			int delta = (globalButtons[client] ^ oldPlayerButtons[client]) & globalButtons[client];
			int inverseDelta = (oldPlayerButtons[client] ^ globalButtons[client]) & oldPlayerButtons[client];
			if(delta & IN_DUCK || delta & IN_JUMP || delta & IN_RELOAD || inverseDelta & IN_DUCK
			|| inverseDelta & IN_JUMP || inverseDelta & IN_RELOAD)
			{//Update menu based on operators
				if(IsValidHandle(view_as<Menu>(playerUpgradeMenus[client])))
				{
					char fstr2[100];
					getUpgradeMenuTitle(client, current_w_list_id[client], current_w_c_list_id[client], current_slot_used[client], fstr2);
					Menu_UpgradeChoice(client, current_w_sc_list_id[client], current_w_c_list_id[client], fstr2, RoundToFloor(playerUpgradeMenuPage[client]/7.0)*7);
				}
			}

			if(IsValidWeapon(CWeapon)){
				if(GetAttribute(CWeapon, "magnify patient damage", 0.0)){
					char buffer[32]
					if(pylonCharge[client] < 10.0*TF2Util_GetEntityMaxHealth(client)*GetResistance(client, true))
						Format(buffer, sizeof(buffer), "Pylon Charge: %.1f%", 10.0*pylonCharge[client]/(TF2Util_GetEntityMaxHealth(client)*GetResistance(client, true)));
					else
					 	Format(buffer, sizeof(buffer), "Pylon Charge: READY");

					SetHudTextParams(0.8, 0.9, 0.4, 232, 133, 2, 200);
					ShowSyncHudText(client, hudAbility, buffer);
				}
				if(GetAttribute(CWeapon, "healing aoe radius", 0.0)){
					float range = GetAttribute(CWeapon, "healing aoe radius", 0.0);
					range *= range;
					float healRate = 1.5 * TF2Attrib_HookValueFloat(1.0, "mult_medigun_healrate", CWeapon);
					float overheal = 1.5 * TF2Attrib_HookValueFloat(1.0, "mult_medigun_overheal_amount", CWeapon);
					float position[3], patientPosition[3];
					GetEntPropVector(client, Prop_Data, "m_vecOrigin", position);
					for(int i = 1; i <= MaxClients;++i){
						if(!IsValidClient3(i))
							continue;
						if(!IsPlayerAlive(i))
							continue;
						if(IsOnDifferentTeams(client, i))
							continue;

						GetEntPropVector(i, Prop_Data, "m_vecOrigin", patientPosition);
						if(GetVectorDistance(position, patientPosition, true) > range)
							continue;
							
						AddPlayerHealth(i, RoundToCeil(healRate), overheal, true, client);
					}
				}
			}
			char ArmorLeft[64]
			Format(ArmorLeft, sizeof(ArmorLeft), "Effective Health | %s", GetAlphabetForm(GetResistance(client, true)*GetClientHealth(client))); 

			if(GetAttribute(client, "regeneration powerup", 0.0) == 3.0){
				Format(ArmorLeft, sizeof(ArmorLeft), "%s\nBlood Pool  | %.0f", ArmorLeft, bloodAcolyteBloodPool[client]); 
			}
			if(CheckForAttunement(client))
			{
				Format(ArmorLeft, sizeof(ArmorLeft), "%s\nFocus  | %.0f / %.0f", ArmorLeft, fl_CurrentFocus[client],fl_MaxFocus[client]); 
				char spellHUD[1024]
				Format(spellHUD, sizeof(spellHUD), "Current Spells Active | \n");
				int activeSpells = 0;
				int attunement = 1;
				Address attuneActive = TF2Attrib_GetByName(client, "arcane attunement slots");
				if(attuneActive != Address_Null)
				{
					attunement += RoundToNearest(TF2Attrib_GetValue(attuneActive));
				}
				for(int i = 0;i<Max_Attunement_Slots && attunement > activeSpells;++i)
				{
					if(AttunedSpells[client][i] != 0.0)
					{
						activeSpells++;
						int spellID = RoundToNearest(AttunedSpells[client][i]-1.0)
						char spellnum[64]
						Format(spellnum, sizeof(spellnum),"%i - %s | Cooldown %.1f\n", i+1, SpellList[spellID], SpellCooldowns[client][i]);
						StrCat(spellHUD,sizeof(spellHUD),spellnum);
					}
				}
				SetHudTextParams(0.02, 0.02, 0.21, 69, 245, 66, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(client, hudSpells, spellHUD);
			}

			if (AreClientCookiesCached(client)){
				SetHudTextParams(StringToFloat(ArmorXPos[client]), StringToFloat(ArmorYPos[client]), 0.5, 255, 187, 0, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(client, hudSync, ArmorLeft);
			}else{
				SetHudTextParams(-0.75, -0.2, 0.5, 255, 187, 0, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(client, hudSync, ArmorLeft);
			}
		}
		oldPlayerButtons[client] = globalButtons[client];
	}
}
public Action:Timer_Every100MS(Handle timer)
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if (IsValidClient3(client) && IsPlayerAlive(client))
		{
			DoSapperEffects(client);
			Address bleedResistance = TF2Attrib_GetByName(client, "sapper damage penalty");
			int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			int primary = GetWeapon(client, 0);
			int secondary = GetWeapon(client, 1);
			if(bleedResistance != Address_Null)
			{
				BleedMaximum[client] = 100.0 + TF2Attrib_GetValue(bleedResistance);
			}
			if(BleedBuildup[client] > 0.0 || RadiationBuildup[client] > 0.0)
			{
				char StatusEffectText[1024]
				Format(StatusEffectText, sizeof(StatusEffectText), " | Status Effects | "); 
				
				if(BleedBuildup[client] > 0.0)
				{
					char buildup[512];
					Format(buildup, sizeof(buildup),"\n    BLEED: %.0f%", (BleedBuildup[client]/BleedMaximum[client])*100.0);
					StrCat(StatusEffectText,sizeof(StatusEffectText),buildup);
				}
				if(RadiationBuildup[client] > 0.0)
				{
					char buildup[512];
					Format(buildup, sizeof(buildup),"\n   RADIATION: %.0f%", (RadiationBuildup[client]/RadiationMaximum[client])*100.0);
					StrCat(StatusEffectText,sizeof(StatusEffectText),buildup);
				}
				if(ConcussionBuildup[client] > 0.0)
				{
					char buildup[512];
					Format(buildup, sizeof(buildup),"\n   CONCUSSION: %.0f%", ConcussionBuildup[client]*100.0);
					StrCat(StatusEffectText,sizeof(StatusEffectText),buildup);
				}
				if(FreezeBuildup[client] > 0.0)
				{
					char buildup[512];
					Format(buildup, sizeof(buildup),"\n   FREEZE: %.0f%", FreezeBuildup[client]*100.0);
					StrCat(StatusEffectText,sizeof(StatusEffectText),buildup);
				}
				
				SetHudTextParams(0.43, 0.21, 0.21, 199, 28, 28, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(client, hudStatus, StatusEffectText);
			}
			char StatusEffectText[256]

			if(GetAttribute(client, "revenge powerup", 0.0) == 1)
			{
				if(RageBuildup[client] < 1.0)
					Format(StatusEffectText, sizeof(StatusEffectText),"Revenge: %.0f%", RageBuildup[client]*100.0);
				else
					Format(StatusEffectText, sizeof(StatusEffectText),"Revenge: READY (Crouch + Mouse3)", RageBuildup[client]*100.0);
				
				if(RageActive[client] == true){
					TF2_AddCondition(client, TFCond_CritCanteen, 1.0);
					TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
					TF2_AddCondition(client, TFCond_DefenseBuffMmmph, 1.0);
					TF2_AddCondition(client, TFCond_KingAura, 1.0);
				}
			}
			else if(GetAttribute(client, "revenge powerup", 0.0) == 2)
			{
				Format(StatusEffectText, sizeof(StatusEffectText),"Berserk: %.0f%", RageBuildup[client]*100.0);
				
				miniCritStatusAttacker[client] = currentGameTime + 1.0;
				TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
				if(RageBuildup[client] > 0.3){
					TF2_AddCondition(client, TFCond_DefenseBuffMmmph, 1.0);
					TF2_AddCondition(client, TFCond_KingAura, 1.0);
				}
				if(RageBuildup[client] > 0.65){
					TF2_AddCondition(client, TFCond_CritCanteen, 1.0);
				}

				RageBuildup[client] -= 0.007
				if(RageBuildup[client] < 0)
					RageBuildup[client] = 0.0;
			}
			else if(GetAttribute(client, "revenge powerup", 0.0) == 3)
			{
				if(enragedKills[client] < 80)
					Format(StatusEffectText, sizeof(StatusEffectText),"Enraged: %d kills remaining", 80-enragedKills[client]);
				else
					Format(StatusEffectText, sizeof(StatusEffectText),"Enraged: READY (Crouch + Mouse3)");
			}
			else if(GetAttribute(client, "vampire powerup", 0.0) == 3)
			{
				Format(StatusEffectText, sizeof(StatusEffectText),"Bloodbound: +%.0f% dmg | +%.0f heal", bloodboundDamage[client], bloodboundHealing[client]);
			}
			else if(GetAttribute(client, "supernova powerup", 0.0) == 1)
			{
				if(SupernovaBuildup[client] < 1.0)
					Format(StatusEffectText, sizeof(StatusEffectText),"Supernova: %.0f%", SupernovaBuildup[client]*100.0);
				else
					Format(StatusEffectText, sizeof(StatusEffectText),"Supernova: READY (Crouch + Mouse3)");
			}
			else if(GetAttribute(client, "regeneration powerup", 0.0) == 2.0)
			{
				if(duplicationCooldown[client] > currentGameTime)
					Format(StatusEffectText, sizeof(StatusEffectText),"Duplication: %.2fs", duplicationCooldown[client] - currentGameTime);
				else
					Format(StatusEffectText, sizeof(StatusEffectText),"Duplication: READY (Crouch + Mouse3)");
			}
			else if(GetAttribute(client, "agility powerup", 0.0) == 3.0)
			{
				if(warpCooldown[client] > currentGameTime)
					Format(StatusEffectText, sizeof(StatusEffectText),"Warp: %.2fs", warpCooldown[client] - currentGameTime);
				else
					Format(StatusEffectText, sizeof(StatusEffectText),"Warp: READY (Crouch + Mouse3)");
			}
			else if(GetAttribute(client, "resistance powerup", 0.0) == 2.0)
			{
				if(frayNextTime[client] > currentGameTime)
					Format(StatusEffectText, sizeof(StatusEffectText),"Fray: %.2fs", frayNextTime[client] - currentGameTime);
				else
					Format(StatusEffectText, sizeof(StatusEffectText),"Fray: READY");
			}
			else if(GetAttribute(client, "resistance powerup", 0.0) == 3.0)
			{
				if(!strongholdEnabled[client])
					Format(StatusEffectText, sizeof(StatusEffectText),"Stronghold: INACTIVE (Crouch + Mouse3)");
				else
					Format(StatusEffectText, sizeof(StatusEffectText),"Stronghold: ACTIVE (Crouch + Mouse3)");
			}
			else if(GetAttribute(client, "king powerup", 0.0) == 2.0)
			{
				if(!IsValidClient3(tagTeamTarget[client]))
					Format(StatusEffectText, sizeof(StatusEffectText),"Tag-Team: INACTIVE (Crouch + Mouse3)");
				else
					Format(StatusEffectText, sizeof(StatusEffectText),"Tag-Team: %N", tagTeamTarget[client]);
			}

			if(StatusEffectText[0] != '\0'){
				SetHudTextParams(0.1, 0.85, 0.21, 199, 28, 28, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, 9, StatusEffectText);
			}
			bool plagueActive = false;
			Address plaguePowerup = TF2Attrib_GetByName(client, "plague powerup");
			float clientPos[3];
			GetEntPropVector(client, Prop_Data, "m_vecOrigin", clientPos);
			if(plaguePowerup != Address_Null && TF2Attrib_GetValue(plaguePowerup) == 1)
			{
				plagueActive = true;
				int e = 33;
				while ((e = FindEntityByClassname(e, "item_healthkit_*")) != -1)
				{
					if(IsValidEdict(e))
					{
						char strName[32];
						GetEntityClassname(e, strName, 32)
						if(GetEntProp(e, Prop_Data, "m_bDisabled") == 0)
						{
							float VictimPos[3];
							GetEntPropVector(e, Prop_Data, "m_vecOrigin", VictimPos);
							if(GetVectorDistance(clientPos,VictimPos, true) <= 360000.0)
							{
								AddPlayerHealth(client, RoundToCeil(TF2_GetMaxHealth(client) * 0.25), 3.0, true, client);
								TF2_RemoveCondition(client,TFCond_NoTaunting_DEPRECATED);
								TF2_AddCondition(client, TFCond_MegaHeal, 2.0);
								
								if(GetEntProp(e, Prop_Data, "m_bAutoMaterialize"))
								{
									AcceptEntityInput(e, "Disable");
									CreateTimer(10.0, ReEnable, EntIndexToEntRef(e))
								}
								else
								{
									RemoveEntity(e);
								}
							}
						}
					}
				}
			}
			if(strongholdEnabled[client]){
				if(GetAttribute(client, "resistance powerup", 0.0) == 3.0){
					Buff strongholdBonus;
					strongholdBonus.init("Stronghold", "Crit immunity & 1.33x healing", Buff_Stronghold, 1, client, 1.0);
					for(int i=1;i<=MaxClients;++i){
						if(!IsValidClient3(i)) continue;
						if(IsOnDifferentTeams(client, i)) continue;
						if(!IsPlayerAlive(i)) continue;

						float VictimPos[3];
						GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
						if(GetVectorDistance(clientPos, VictimPos, true) > 640000.0) continue;

						insertBuff(i, strongholdBonus);
					}
				}
			}

			if(GetAttribute(client, "king powerup", 0.0) == 2.0){
				if(IsValidClient3(tagTeamTarget[client]) && !IsOnDifferentTeams(client, tagTeamTarget[client]) && IsPlayerAlive(client)){
					Buff tagteamBuff;
					tagteamBuff.init("Tag-Team Linked", "", Buff_TagTeam, 1, client, 1.0);
					tagteamBuff.additiveDamageMult = 0.4;

					insertBuff(client, tagteamBuff);
					insertBuff(tagTeamTarget[client], tagteamBuff);
				}
			}

			Buff leechDebuff;
			leechDebuff.init("Leeched", "", Buff_Leech, 1, client, 1.0);
			Buff decayDebuff;
			decayDebuff.init("Decay", "", Buff_Decay, 1, client, 1.0);

			for(int i=1;i<=MaxClients;++i)
			{
				if(!IsValidClient3(i)) continue; 
				if(!IsPlayerAlive(i)) continue;

				if(corrosiveDOT[client][i][0] != 0.0 && corrosiveDOT[client][i][1] >= 0.0)
				{
					corrosiveDOT[client][i][1] -= TICKINTERVAL*10.0;
					
					if(IsValidClient3(i)){
						currentDamageType[client].second |= DMG_IGNOREHOOK;
						SDKHooks_TakeDamage(client,i,i,corrosiveDOT[client][i][0],_,i,_,_,false);
					}
				}
				if(!hasBuffIndex(i, Buff_Leech)){
					if(GetAttribute(i, "vampire powerup", 0.0) != 2.0 && GetAttribute(client, "vampire powerup", 0.0) == 2.0){
						float VictimPos[3];
						GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
						if(GetVectorDistance(clientPos,VictimPos, true) <= 360000.0)
							insertBuff(i, leechDebuff);
					}
				}
				if(IsOnDifferentTeams(client,i)){
					if(!hasBuffIndex(i, Buff_Decay)){
						if(GetAttribute(client, "plague powerup", 0.0) == 2.0){
							float VictimPos[3];
							GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
							if(GetVectorDistance(clientPos,VictimPos, true) <= 160000.0)
								insertBuff(i, decayDebuff);
						}
					}
					if(plagueActive && !TF2_IsPlayerInCondition(i, TFCond_Plague)){
						float VictimPos[3];
						GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
						if(GetVectorDistance(clientPos,VictimPos, true) <= 10000.0)
							TF2_AddCondition(i, TFCond_Plague, TFCondDuration_Infinite, client);
					}
				}
			}
			if(hasBuffIndex(client, Buff_Decay)){
				Buff decay; decay = playerBuffs[client][getBuffInArray(client, Buff_Decay)];
				if(client != decay.inflictor && IsValidClient3(decay.inflictor) && IsOnDifferentTeams(client,decay.inflictor)){
					currentDamageType[decay.inflictor].second |= DMG_IGNOREHOOK;
					currentDamageType[decay.inflictor].second |= DMG_PIERCING;
					SDKHooks_TakeDamage(client, decay.inflictor, decay.inflictor, 10.0 + GetClientHealth(client)*0.002,_,_,_,_,false);
					currentDamageType[decay.inflictor].second |= DMG_IGNOREHOOK;
					SDKHooks_TakeDamage(client, decay.inflictor, decay.inflictor, 5.0,DMG_RADIATION+DMG_DISSOLVE,_,_,_,false);
				}
			}
			if(hasBuffIndex(client, Buff_InfernalDOT)){
				Buff infernalDOT; infernalDOT = playerBuffs[client][getBuffInArray(client, Buff_InfernalDOT)];
				if(client != infernalDOT.inflictor && IsValidClient3(infernalDOT.inflictor)){
					currentDamageType[infernalDOT.inflictor].second |= DMG_IGNOREHOOK;
					SDKHooks_TakeDamage(client, infernalDOT.inflictor, infernalDOT.inflictor, InfernalEnchantment[infernalDOT.inflictor]*0.07,_,_,_,_,false);
					CreateParticleEx(client, "halloween_burningplayer_flyingbits", 1, _, _, 0.6);
				}
			}
			if(hasBuffIndex(client, Buff_LifeLink)){
				Buff lifelink; lifelink = playerBuffs[client][getBuffInArray(client, Buff_LifeLink)];
				if(IsValidClient3(lifelink.inflictor)){
					currentDamageType[lifelink.inflictor].second |= DMG_PIERCING;
					currentDamageType[lifelink.inflictor].second |= DMG_IGNOREHOOK;
					SDKHooks_TakeDamage(client, lifelink.inflictor, lifelink.inflictor, GetClientHealth(client)*0.0025, DMG_PREVENT_PHYSICS_FORCE,_,_,_,false);
				}
			}
			if(hasBuffIndex(client, Buff_PowerupBurning)){
				Buff infernalDOT; infernalDOT = playerBuffs[client][getBuffInArray(client, Buff_PowerupBurning)];
				if(client != infernalDOT.inflictor && IsValidClient3(infernalDOT.inflictor)){
					currentDamageType[infernalDOT.inflictor].second |= DMG_PIERCING;
					currentDamageType[infernalDOT.inflictor].second |= DMG_IGNOREHOOK;
					SDKHooks_TakeDamage(client, infernalDOT.inflictor, infernalDOT.inflictor, 10.0,_,_,_,_,false);
					CreateParticleEx(client, "halloween_burningplayer_flyingbits", 1);
				}
			}

			int inflictor = TF2Util_GetPlayerConditionProvider(client, TFCond_Plague);
			if(IsValidClient3(inflictor))
			{
				//Deal 3 piercing damage to plagued opponents.
				currentDamageType[inflictor].second |= DMG_PIERCING;
				currentDamageType[inflictor].second |= DMG_IGNOREHOOK;
				SDKHooks_TakeDamage(client, inflictor, inflictor, 3.0, DMG_PREVENT_PHYSICS_FORCE,_,_,_,false);
			}
			if(IsValidWeapon(CWeapon))
			{
				Address infAmmo = TF2Attrib_GetByName(CWeapon, "vision opt in flags")
				if(infAmmo != Address_Null)
				{
					SetAmmo_Weapon(CWeapon,RoundToNearest(TF2Attrib_GetValue(infAmmo)))
				}
				int conditionOnActive = RoundToNearest(GetAttribute(CWeapon, "set throwable type", 0.0));
				if(conditionOnActive)
					TF2_AddCondition(client, view_as<TFCond>(conditionOnActive), 0.15, client);

				weaponFireRate[CWeapon] = TF2_GetFireRate(client, CWeapon);
			}
			if(IsValidEdict(primary))
			{
				if (GetEntPropFloat(client, Prop_Send, "m_flRageMeter") < 1.0)
					isBuffActive[client] = false;

				if(isBuffActive[client] == true)
				{
					/*float range = 800.0;
					Address rangeMult = TF2Attrib_GetByName(primary, "clip size bonus")
					if(rangeMult != Address_Null)
					{
						range *= TF2Attrib_GetValue(rangeMult);
					}*/
					//Base Vanilla Buff Overrides
					int buff = GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex")
					switch(buff)
					{
						case 752:
						{
							miniCritStatusAttacker[client] = currentGameTime+0.3
							TF2_AddCondition(client, TFCond_RuneHaste, 0.3);
							TF2_RemoveCondition(client, TFCond_FocusBuff);
						}
						case 594:
						{
							miniCritStatusAttacker[client] = currentGameTime+0.3
							TF2_AddCondition(client, TFCond_RuneAgility, 0.3);
							TF2_RemoveCondition(client, TFCond_CritMmmph);
						}
					}
				}
			}
			if(IsValidEdict(secondary))
			{
				if (GetEntPropFloat(client, Prop_Send, "m_flRageMeter") < 0.1)
					isBuffActive[client] = false;

				if(isBuffActive[client] == true)
				{
					float range = 800.0;
					Address rangeMult = TF2Attrib_GetByName(secondary, "clip size bonus")
					if(rangeMult != Address_Null)
					{
						range *= TF2Attrib_GetValue(rangeMult);
					}
					float ClientPos[3];
					GetClientAbsOrigin(client, ClientPos);
					//Base Vanilla Buff Overrides
					int buff = GetEntProp(secondary, Prop_Send, "m_iItemDefinitionIndex")
					switch(buff)
					{
						case 129,1001:
						{
							float VictimPos[3];
							for(int i=1;i<=MaxClients;++i)
							{
								if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(client) == GetClientTeam(i))
								{
									GetClientAbsOrigin(i, VictimPos);
									if(GetVectorDistance(ClientPos,VictimPos,true ) <= range*range)
									{
										if(miniCritStatusAttacker[i] < currentGameTime+0.3)
											miniCritStatusAttacker[i] = currentGameTime+0.3
									}
								}
							}
						}
						case 226:
						{
							float VictimPos[3];
							for(int i=1;i<=MaxClients;++i)
							{
								if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(client) == GetClientTeam(i))
								{
									GetClientAbsOrigin(i, VictimPos);
									if(GetVectorDistance(ClientPos,VictimPos, true) <= range*range)
										TF2_AddCondition(i, TFCond_DefenseBuffNoCritBlock, 0.3)
								}
							}
						}
						case 354:
						{
							float VictimPos[3];
							for(int i=1;i<=MaxClients;++i)
							{
								if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(client) == GetClientTeam(i))
								{
									GetClientAbsOrigin(i, VictimPos);
									if(GetVectorDistance(ClientPos,VictimPos,true) <= range*range)
										TF2_AddCondition(i, TFCond_MedigunDebuff, 0.3)
								}
							}
						}
					}
					{
						float plunderBonus = GetAttribute(secondary, "buff plunder multiplier", 1.0)
						if(plunderBonus > 1.0){
							Buff plunderBuff;
							plunderBuff.init("Plunder Bonus", "Increased Hit&Kill Effects", Buff_Plunder, RoundFloat(plunderBonus*100), client, 0.5);
							plunderBuff.severity = plunderBonus;

							float VictimPos[3];
							for(int i=1;i<=MaxClients;++i)
							{
								if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(client) == GetClientTeam(i))
								{
									GetClientAbsOrigin(i, VictimPos);
									if(GetVectorDistance(ClientPos,VictimPos,true ) <= range*range)
										insertBuff(i, plunderBuff);
								}
							}
						}
					}
					//Custom Buff Effects
					//Lightning Strike banner : lightningCounter : "has pipboy build interface"
					if(IsValidWeapon(CWeapon)){
						float barrageLevel = GetAttribute(secondary, "buff barrage", 0.0)
						if(barrageLevel > 0 && lightningCounter[client] % 12 == 0){
							float fOrigin[3], fAngles[3], vBuffer[3];
							GetClientEyePosition(client, fOrigin);
							fAngles = fEyeAngles[client];
							fAngles[1] -= 15.0 + 15.0/barrageLevel;
							for(int i=0;i<RoundToCeil(barrageLevel);++i){
								fAngles[1] += 30.0/barrageLevel;
								int iEntity = CreateEntityByName("tf_projectile_sentryrocket");
								int iTeam = GetClientTeam(client);
								SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

								SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
								SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
								
								SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
								SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
								
								GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);

								ScaleVector(vBuffer, 50.0);
								AddVectors(vBuffer, fOrigin, fOrigin);

								ScaleVector(vBuffer, 30.0);
								
								float ProjectileDamage = 40+10*barrageLevel;
								SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, ProjectileDamage, true);  
								
								TeleportEntity(iEntity, fOrigin, fAngles, vBuffer);
								DispatchSpawn(iEntity);
							}
						}

						Address lightningBannerActive = TF2Attrib_GetByName(secondary, "has pipboy build interface");
						if(lightningBannerActive != Address_Null && TF2Attrib_GetValue(lightningBannerActive) != 0.0)
						{
							if(lightningCounter[client] % 8 == 0)
							{
								float clientpos[3];
								GetClientAbsOrigin(client,clientpos);
								clientpos[0] += GetRandomFloat(-500.0,500.0);
								clientpos[1] += GetRandomFloat(-500.0,500.0);
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
								
								EmitAmbientSound("ambient/explosions/explode_9.wav", startpos, client, 50);
								
								float LightningDamage = TF2_GetDPSModifiers(client,CWeapon)*10.0*TF2Attrib_GetValue(lightningBannerActive);
								int i = -1;
								while ((i = FindEntityByClassname(i, "*")) != -1)
								{
									if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
									{
										float VictimPos[3];
										GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
										VictimPos[2] += 30.0;
										if(GetVectorDistance(clientpos,VictimPos,true) <= range*range*0.3)
											if(IsPointVisible(clientpos,VictimPos)){
												currentDamageType[client].second |= DMG_IGNOREHOOK;
												SDKHooks_TakeDamage(i,client,client, LightningDamage, 1073741824, secondary, _,_,false);
											}
									}
								}
							}
						}
						lightningCounter[client]++;
					}
				}
			}
		}
	}
}
public Action:Timer_EveryTenSeconds(Handle timer)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient3(client) && IsPlayerAlive(client))
		{
			Address bossType = TF2Attrib_GetByName(client, "damage force increase text");
			if(bossType != Address_Null && TF2Attrib_GetValue(bossType) > 0.0)
			{
				float bossValue = TF2Attrib_GetValue(bossType);
				switch(bossValue)
				{
					case 3.0:
					{
						CreateParticleEx(client, "critgun_weaponmodel_red", 1, _, _, 10.0);
						SetEntityRenderColor(client, 190,0,0,255);
						int counter = 0;
						bool clientList[MAXPLAYERS+1];
						for(int i = 1; i<=MaxClients; ++i)
						{
							if (IsValidClient3(i) && IsPlayerAlive(i))
							{
								if(GetClientTeam(client) == GetClientTeam(i))
								{
									if(GetEntProp(i, Prop_Send, "m_bUseBossHealthBar") == 0 && !TF2_IsPlayerInCondition(i, TFCond_KingAura))
									{
										float clientpos[3], targetpos[3];
										GetClientAbsOrigin(client, clientpos);
										GetClientAbsOrigin(i, targetpos);
										if(GetVectorDistance(clientpos, targetpos, true) <= 810000.0)
										{
											counter++;
											clientList[i] = true;
											if(counter == 5)
											{
												break;
											}
										}
									}
								}
							}
						}
						if(counter > 2)
						{
							TF2_AddCondition(client, TFCond_MVMBotRadiowave, 2.0);
							
							for(int buffed = 1; buffed<=MaxClients;buffed++)
							{
								if(clientList[buffed])
								{
									TF2_AddCondition(buffed, TFCond_MVMBotRadiowave, 1.0);
									TF2_AddCondition(buffed, TFCond_KingAura, 1000.0);
									TF2Attrib_SetByName(buffed, "damage bonus HIDDEN", 2.5);
									TF2Attrib_SetByName(buffed, "crit mod disabled hidden", 0.5);
									SetEntityRenderColor(buffed, 190,0,0,255);
								}
							}
						}
					}
					case 5.0:
					{
						int spellCasted = GetRandomInt(0,3);
						if(spellCasted == 0)
						{
							int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
							if(IsValidEdict(CWeapon))
							{
								float ClientPos[3];
								float flamePos[3];
								GetClientAbsOrigin(client,ClientPos);
								float sphereRadius = 700.0;
								float tempdiameter;
								for(int i=-9;i<=8;++i){
									float rad=float(i*10)/360.0*(3.14159265*2);
									tempdiameter=sphereRadius*Cosine(rad)*2;
									float heightoffset=sphereRadius*Sine(rad);

									float origin[3];
									origin[0]=ClientPos[0];
									origin[1]=ClientPos[1];
									origin[2]=ClientPos[2]+heightoffset;
									TE_SetupBeamRingPoint(origin, 0.0, tempdiameter, Laser, spriteIndex, 0, 0, 1.0, 2.0, 0.0, {255,200,0,122}, 1500, 0);
									TE_SendToAll();
								}
								
								//scripting god
								flamePos = ClientPos;
								flamePos[2] += 400.0;

								//ohhhhh myyyyy god!!!!!!
								CreateParticle(-1, "cinefx_goldrush_flames", _, _, _, flamePos);
								//
								flamePos[0] += 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", _, _, _, flamePos);
								//
								flamePos[1] += 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", _, _, _, flamePos);
								//
								flamePos[1] -= 800.0;
								CreateParticle(-1, "cinefx_goldrush_flames", _, _, _, flamePos);
								//
								flamePos[0] -= 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", _, _, _, flamePos);
								//
								flamePos[1] += 800.0;
								CreateParticle(-1, "cinefx_goldrush_flames", _, _, _, flamePos);
								//
								flamePos[0] -= 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", _, _, _, flamePos);
								//
								flamePos[1] -= 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", _, _, _, flamePos);
								//
								flamePos[1] -= 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", _, _, _, flamePos);
								
								
								float DMGDealt = 7.5 * TF2_GetDPSModifiers(client,CWeapon);
								int i = -1;
								while ((i = FindEntityByClassname(i, "*")) != -1)
								{
									if(IsValidForDamage(i))
									{
										if(IsOnDifferentTeams(client,i))
										{
											float VictimPos[3];
											GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
											if(GetVectorDistance(ClientPos,VictimPos,true) <= 640000.0)
											{
												CreateParticle(i, "dragons_fury_effect_parent", true, _, 2.0);
												CreateParticle(i, "utaunt_glowyplayer_orange_glow", true, _, 2.0);
												DOTStock(i,client,DMGDealt,-1,DMG_BURN,20,1.0,0.12,true);
											}
										}
									}
								}
							}
						}
						else if(spellCasted == 2)
						{
							BleedBuildup[client] = 0.0;
							RadiationBuildup[client] = 0.0;
							miniCritStatusAttacker[client] = currentGameTime+10.0
							TF2_AddCondition(client, TFCond_DodgeChance, 2.5);
							TF2_AddCondition(client, TFCond_AfterburnImmune, 2.5);
							TF2_AddCondition(client, TFCond_UberchargedHidden, 0.01);
							EmitSoundToAll(SOUND_ADRENALINE, client, -1, 150, 0, 1.0);
							CreateParticleEx(client, "utaunt_tarotcard_red_wind", 1, _, _, 10.0);
						}
						else if(spellCasted == 3 || spellCasted == 1)
						{
							int iTeam = GetClientTeam(client);
							for(int i=0;i<3;++i)
							{
								int iEntity = CreateEntityByName("tf_projectile_flare");
								if (IsValidEdict(iEntity)) 
								{
									float fAngles[3]
									float fOrigin[3]
									float vBuffer[3]
									float vRight[3]
									float fVelocity[3]
									float fwd[3]
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
					case 6.0:
					{
						TF2Attrib_SetByName(client, "Attack not cancel charge", 1.0);
						TF2Attrib_SetByName(client, "full charge turn control", 100.0);
						TF2Attrib_SetByName(client, "charge time increased", 10000000.0);
						TF2Attrib_SetByName(client, "charge recharge rate increased", 100.0);
						TF2_AddCondition(client, TFCond_Charging, 15.0);
						int iEntity = CreateEntityByName("eyeball_boss");
						int iTeam = GetClientTeam(client);
						if (IsValidEdict(iEntity)) 
						{
							float fOrigin[3]
							SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

							SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
							SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
										
							GetClientEyePosition(client, fOrigin);
							TeleportEntity(iEntity, fOrigin, NULL_VECTOR, NULL_VECTOR);
							DispatchSpawn(iEntity);
							
							CreateTimer(9.0, SelfDestruct, EntIndexToEntRef(iEntity));
							jarateWeapon[iEntity] = EntIndexToEntRef(client);
						}
					}
					case 7.0:
					{
						int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
						if(IsValidEdict(CWeapon))
						{
							CreateParticleEx(CWeapon, "utaunt_auroraglow_orange_parent", 1, _, _, 10.0);
							TE_SendToAll();
								
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
							
							EmitAmbientSound("ambient/explosions/explode_9.wav", startpos, client, 50);
							
							float LightningDamage = 150.0*TF2_GetDPSModifiers(client,CWeapon);
						
							int i = -1;
							while ((i = FindEntityByClassname(i, "*")) != -1)
							{
								if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
								{
									float VictimPos[3];
									GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
									VictimPos[2] += 30.0;
									if(GetVectorDistance(clientpos,VictimPos,true) <= 250000.0)
									{
										if(IsPointVisible(clientpos,VictimPos))
										{
											currentDamageType[client].second |= DMG_IGNOREHOOK;
											SDKHooks_TakeDamage(i,client,client, LightningDamage, 1073741824, _,_,_,false);
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
						CreateParticleEx(client, "utaunt_arcane_yellow_parent", 1, _, _, 10.0);
					}
				}
			}
		}
	}
}
public Action:BuildingRegeneration(Handle timer, any:entity) 
{
	entity = EntRefToEntIndex(entity)
	if(!IsValidEdict(entity) || !IsValidEdict(entity))
	{
		return;
	}
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hBuilder"); 
	if(!IsValidEdict(owner) || !IsValidEdict(owner))
	{
		return;
	}
	if(!IsClientInGame(owner))
	{
		return;
	}
	if(GetEntProp(entity, Prop_Send, "m_bDisabled") == 1)
	{
		return;
	}
	int BuildingMaxHealth = GetEntProp(entity, Prop_Send, "m_iMaxHealth");
	int BuildingHealth = GetEntProp(entity, Prop_Send, "m_iHealth");
	if(BuildingMaxHealth != BuildingHealth)
	{
		int mode = 2;
		if(mode == 1)
		{
			int melee = (GetWeapon(owner,2));
			Address BuildingRegen = TF2Attrib_GetByName(melee, "Projectile speed decreased");
			if(BuildingRegen != Address_Null)
			{
				float buildingHPRegen = TF2Attrib_GetValue(BuildingRegen);
				int Regeneration = RoundToNearest(((buildingHPRegen*BuildingMaxHealth)/100.0)/7.5);
				if(BuildingHealth < BuildingMaxHealth)
				{
					if((Regeneration + BuildingHealth) > BuildingMaxHealth)
					{
						AddEntHealth(entity, BuildingMaxHealth - BuildingHealth)
					}
					else
					{
						AddEntHealth(entity, Regeneration)
					}
				}
			}
		}
		if(mode == 2)
		{
			Address BuildingRegen = TF2Attrib_GetByName(owner, "disguise on backstab");
			if(BuildingRegen != Address_Null)
			{
				int Regeneration = RoundToNearest(TF2Attrib_GetValue(BuildingRegen)/3);
				if(BuildingHealth < BuildingMaxHealth)
				{
					if((Regeneration + BuildingHealth) > BuildingMaxHealth)
					{
						AddEntHealth(entity, BuildingMaxHealth - BuildingHealth)
					}
					else
					{
						AddEntHealth(entity, Regeneration)
					}
				}
			}
		}
	}
	int sentrynumber = EntRefToEntIndex(entity)
	char SentryObject[128];
	GetEdictClassname(sentrynumber, SentryObject, sizeof(SentryObject));
	if (StrEqual(SentryObject, "obj_sentrygun"))
	{
		int melee = (GetWeapon(owner,2));
		int sentryLevel = GetEntLevel(entity);
		int shells = GetEntProp(entity, Prop_Send, "m_iAmmoShells");
		int rockets = GetEntProp(entity, Prop_Send, "m_iAmmoRockets");
		Address AmmoRegen = TF2Attrib_GetByName(melee, "disguise on backstab");
		float maxAmmoMultiplier = 1.0;
		Address ammoMult = TF2Attrib_GetByName(melee, "mvm sentry ammo");
		if(ammoMult != Address_Null)
			maxAmmoMultiplier = TF2Attrib_GetValue(ammoMult);

		if(AmmoRegen != Address_Null)
		{
			int AmmoRegeneration = RoundToNearest(TF2Attrib_GetValue(AmmoRegen)/5.0);
			
			if(sentryLevel != 1)
			{
				if((shells + AmmoRegeneration) < RoundToNearest(200.0 * maxAmmoMultiplier))
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoShells", shells + AmmoRegeneration);
				}
				else
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoShells", RoundToNearest(200.0 * maxAmmoMultiplier));
				}
			}
			else
			{
				if((shells + AmmoRegeneration) < RoundToNearest(150.0 * maxAmmoMultiplier))
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoShells", shells + AmmoRegeneration);
				}
				else
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoShells", RoundToNearest(150.0 * maxAmmoMultiplier));
				}
			}
			if(sentryLevel == 3)
			{
				if((rockets + (AmmoRegeneration/10)) < RoundToNearest(20.0 * maxAmmoMultiplier))
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoRockets", rockets + (AmmoRegeneration/10));
				}
				else
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoRockets", RoundToNearest(20.0 * maxAmmoMultiplier));
				}				
			}
		}
	}
}
public Action Timer_UberCheck(Handle timer, int medigun){
	int medigunID = EntRefToEntIndex(medigun);
	if(!IsValidWeapon(medigunID) || !GetEntProp(medigunID, Prop_Send, "m_bChargeRelease"))
		return Plugin_Stop;

	if(GetEntProp(medigunID, Prop_Send, "m_bHolstered"))
		return Plugin_Continue;

	int medic = getOwner(medigunID);
	if(!IsValidClient3(medic) || !IsPlayerAlive(medic) || TF2_GetPlayerClass(medic) != TFClass_Medic)
		return Plugin_Stop;

	
	int target = GetEntPropEnt(medigunID, Prop_Send, "m_hHealingTarget");	
	ApplyUberBuffs(medic, target, medigunID);

	return Plugin_Continue;
}
public Action:refreshallweapons(Handle timer, int client) 
{
	for(int i = 0;i < 6;++i){
		refreshUpgrades(client,i);
	}
}
public Action:GiveMaxHealth(Handle timer, any:userid) 
{
	int client = GetClientOfUserId(userid);
	if(IsValidClient3(client) && TF2Util_GetEntityMaxHealth(client) >= GetClientHealth(client))
		SetEntityHealth(client, TF2Util_GetEntityMaxHealth(client))
}
public Action:SelfDestruct(Handle timer, any:ref) 
{ 
    int entity = EntRefToEntIndex(ref); 
    if(IsValidEdict(entity)) 
		RemoveEntity(entity);
	KillTimer(timer)
}
public Action:DisableSlowdown(Handle timer, int entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidClient3(entity))
	{
		TF2Attrib_SetByName(entity,"move speed penalty", 1.0);
		TF2Attrib_SetByName(entity,"major increased jump height", 1.0);
	}
}
public Action:Timer_KillLaser(Handle timer, int entity)
{
	TE_SetupKillPlayerAttachments(entity);
	TE_SendToAll();
	return Plugin_Stop;
}
public Action ResetClientsTimer(Handle timer){
	replenishStatus = false;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			PrintToServer("Resetting Client %N", client);
			current_class[client] = TF2_GetPlayerClass(client)
			CancelClientMenu(client);
			Menu_BuyUpgrade(client, 0);
			TF2_RegeneratePlayer(client);
		}
		CurrencySaved[client] = 0.0;
		CurrencyOwned[client] = (StartMoney + additionalstartmoney);
		for(int j = 0; j < Max_Attunement_Slots;j++){
			SpellCooldowns[client][j] = 0.0;
		}
	}
	return Plugin_Stop;
}
/*public Action Timer_DelayedRespawn(Handle timer, int client){
	client = EntRefToEntIndex(client);
	if(IsValidClient3(client)){
		TF2_RegeneratePlayer(client);
	}

	return Plugin_Stop;
}*/
public Action MissionLoaded(Handle timer){
	for(int i = 1;i<=MaxClients;++i){
		client_respawn_checkpoint[i] = false;
		if(IsValidClient(i)){
			StartMoney = float(GetEntProp(i, Prop_Send, "m_nCurrency"));
			CurrencyOwned[i] = (StartMoney + additionalstartmoney);
		}
	}
	disableMvMCash = true;
	PrintToServer("%.2f Startmoney", StartMoney);

	if(StrContains(missionName, "IF", false) != -1)
	{
		if(StrContains(missionName, "_Boss_Rush", false) != -1)
		{
			DefenseMod = 2.35;
			DamageMod = 2.55;
			DefenseIncreasePerWaveMod = 0.03;
			OverallMod = 1.8;
			PrintToServer("IF | Set Mission to Boss Rush");
		}
		else if(StrContains(missionName, "_Defend", false) != -1)
		{
			DefenseMod = 2.55;
			DamageMod = 2.55;
			DefenseIncreasePerWaveMod = 0.03;
			OverallMod = 1.8;
			PrintToServer("IF | Set Mission to Defend");
		}
		else if(StrContains(missionName, "_Extreme", false) != -1)
		{
			DefenseMod = 2.35;
			DamageMod = 2.55;
			DefenseIncreasePerWaveMod = 0.03;
			OverallMod = 1.35;
			PrintToServer("IF | Set Mission to Extreme");
		}
		else if(StrContains(missionName, "_Hard", false) != -1)
		{
			DefenseMod = 2.35;
			DamageMod = 2.55;
			DefenseIncreasePerWaveMod = 0.03;
			OverallMod = 1.1;
			PrintToServer("IF | Set Mission to Hard");
		}
		else if(StrContains(missionName, "_Intermediate", false) != -1)
		{
			DefenseMod = 2.0;
			DamageMod = 2.3;
			DefenseIncreasePerWaveMod = 0.015;
			OverallMod = 1.5;
			PrintToServer("IF | Set Mission to Intermediate");
		}
		else if(StrContains(missionName, "_Rush", false) != -1)
		{
			DefenseMod = 2.35;
			DamageMod = 2.55;
			DefenseIncreasePerWaveMod = 0.03;
			OverallMod = 1.1;
			PrintToServer("IF | Set Mission to Rush");
		}
		else if(StrContains(missionName, "_Survival", false) != -1)
		{
			DefenseMod = 2.35;
			DamageMod = 2.55;
			DefenseIncreasePerWaveMod = 0.03;
			OverallMod = 1.5;
			PrintToServer("IF | Set Mission to Survival");
		}
		else
		{
			DefenseMod = 1.75;
			DamageMod = 2.1;
			DefenseIncreasePerWaveMod = 0.0;
			OverallMod = 1.0;
			PrintToServer("IF | Set Mission to Default");
		}
	}
	return Plugin_Stop;
}
//On a wave fail:
public Action WaveFailed(Handle timer)
{
	if(!failLock)
		return Plugin_Stop;

	failLock = false;
    int ent, round

    ent = FindEntityByClassname(-1, "tf_objective_resource");
	if(IsValidEdict(ent))
	{
		round = GetEntProp(ent, Prop_Send, "m_nMannVsMachineWaveCount");
		
		if(round > 0)
		{
			int slot,i
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsValidClient(client))
				{
					for (slot = 0; slot < NB_SLOTS_UED; slot++)
					{
						for(i = 0; i < MAX_ATTRIBUTES_ITEM; ++i)
						{
							currentupgrades_idx[client][slot][i] = currentupgrades_idx_mvm_chkp[client][slot][i]
							currentupgrades_val[client][slot][i] = currentupgrades_val_mvm_chkp[client][slot][i]
						}
						for(i = 0; i < MAX_ATTRIBUTES; ++i)
						{
							upgrades_ref_to_idx[client][slot][i] = upgrades_ref_to_idx_mvm_chkp[client][slot][i]
						}
						client_spent_money[client][slot] = client_spent_money_mvm_chkp[client][slot];
						currentupgrades_number[client][slot] = currentupgrades_number_mvm_chkp[client][slot]
						for(int y = 0;y<5;y++)
						{
							currentupgrades_restriction[client][slot][y] = currentupgrades_restriction_mvm_chkp[client][slot][y];
						}
					}
					client_new_weapon_ent_id[client] = client_new_weapon_ent_id_mvm_chkp[client];
					if (!client_respawn_handled[client])
					{
						CreateTimer(2.0, ClChangeClassTimer, GetClientUserId(client));
					}
					CreateTimer(0.25, MvMFailTimer, GetClientUserId(client));
					PrintToServer("%N has %.0f saved currency.", client, CurrencySaved[client]);
				}
				CurrencyOwned[client] = CurrencySaved[client];
				for(int j = 0; j < Max_Attunement_Slots;j++)
				{
					SpellCooldowns[client][j] = 0.0;
				}
			}
			PrintToServer("MvM Mission Failed");
			additionalstartmoney = StartMoneySaved - StartMoney;
			PrintToServer("%.0f Start Money.", StartMoney + additionalstartmoney);
		}
	}
	return Plugin_Stop;
}
public Action:RemoveFire(Handle timer, any:data)
{
	ResetPack(data);
	
	int client = ReadPackCell(data);
	float loss = ReadPackFloat(data);
	
	RPS[client] -= loss;
	
	if(RPS[client] < 0.0)
	{
		RPS[client] = 0.0;
	}
	CloseHandle(data);
}
public Action:WeaponReGiveUpgrades(Handle timer, any:userid)
{
	int client = GetClientOfUserId(userid);
	if(IsValidClient3(client))
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			client_respawn_handled[client] = 1
			for (int slot = 0; slot < NB_SLOTS_UED; slot++)
			{
				if (slot == 3 && client_new_weapon_ent_id[client])
				{
					GiveNewWeapon(client, 3);
				}
				else
				{
					GiveNewUpgradedWeapon_(client, slot)
				}
			}
		}
		if(IsFakeClient(client) || MoneyBonusKill == 5000)
		{
			if(!IsValidClient(client) && (!IsMvM()))
			{
				TF2Attrib_ClearCache(client);
			}
		}
		client_respawn_handled[client] = 0
	}
}
public Action:Timer_Resetupgrades(Handle timer, any:userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		for (int slot = 0; slot < NB_SLOTS_UED; slot++)
		{
			client_spent_money[client][slot] = 0.0
			client_spent_money_mvm_chkp[client][slot] = 0.0
			client_tweak_highest_requirement[client][slot] = 0.0;
		}
		if (!client_respawn_handled[client])
		{
			CreateTimer(0.1, ClChangeClassTimer, GetClientUserId(client));
		}
	}
}
public Action:MvMFailTimer(Handle timer, any:userid)
{
	int client = GetClientOfUserId(userid);
	
	if (IsValidClient(client))
	{
		TF2Attrib_RemoveAll(client);
		TF2Attrib_ClearCache(client);
		TF2_RespawnPlayer(client);
		for (int slot = 0; slot < NB_SLOTS_UED; slot++)
		{
			int weaponinSlot = GetWeapon(client,slot);
			if(IsValidEdict(weaponinSlot))
			{
				TF2Attrib_RemoveAll(weaponinSlot);
				TF2Attrib_ClearCache(weaponinSlot);
			}
			GiveNewUpgradedWeapon_(client, slot);
		}
		TF2_RespawnPlayer(client);
		TF2Attrib_ClearCache(client);
	}
}
public Action:ClChangeClassTimer(Handle timer, any:userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		client_respawn_checkpoint[client] = 0;
		if(AreClientCookiesCached(client))
		{
			char menuEnabled[64];
			GetClientCookie(client, respawnMenu, menuEnabled, sizeof(menuEnabled));
			float menuValue = StringToFloat(menuEnabled);
			if(menuValue == 0.0)
			{
				Menu_BuyUpgrade(client, 0);
			}
		}
		else
		{
			Menu_BuyUpgrade(client, 0);
		}
	}
}
public Action:GiveMaxAmmo(Handle timer, any:userid) 
{
	int client = GetClientOfUserId(userid);
	if(IsValidClient3(client))
	{
		int primary = GetWeapon(client,0);
		int secondary = GetWeapon(client,1);
		if(IsValidWeapon(primary) && HasEntProp(primary, Prop_Data, "m_iClip1"))
		{
			float autoFires = GetAttribute(primary, "auto fires full clip", 0.0);
			if(autoFires != 0.0)
				return;

			int primaryAmmo = TF2Util_GetWeaponMaxClip(primary);
			if(primaryAmmo > 1)
				SetClipAmmo(client, 0, primaryAmmo);
			
			if(HasEntProp(primary, Prop_Send, "m_flEnergy"))
				SetEntPropFloat(primary, Prop_Send, "m_flEnergy", float(primaryAmmo));
		}
		if(IsValidWeapon(secondary) && HasEntProp(secondary, Prop_Data, "m_iClip1"))
		{
			float autoFires = GetAttribute(secondary, "auto fires full clip", 0.0);
			if(autoFires != 0.0)
				return;

			int secondaryAmmo = TF2Util_GetWeaponMaxClip(secondary);
			if(secondaryAmmo > 1)
				SetClipAmmo(client, 1, secondaryAmmo);

			if(HasEntProp(secondary, Prop_Send, "m_flEnergy"))
				SetEntPropFloat(secondary, Prop_Send, "m_flEnergy", float(secondaryAmmo));
		}
		
		if(!IsFakeClient(client) && AreClientCookiesCached(client))
		{
			if(current_class[client] == TFClass_Engineer)
			{
				char TutorialString[32];
				GetClientCookie(client, EngineerTutorial, TutorialString, sizeof(TutorialString));
				if(!strcmp("0", TutorialString))
				{
					SetClientCookie(client, EngineerTutorial, "1"); 
					
					char TutorialText[256]
					Format(TutorialText, sizeof(TutorialText), " | Tutorial | \nAs an engineer, your sentry inherits your survivability upgrades on the body.\nThe sentry upgrades are located on melee upgrades."); 
					SetHudTextParams(-1.0, -1.0, 15.0, 252, 161, 3, 255, 0, 0.0, 0.0, 0.0);
					ShowHudText(client, 10, TutorialText);
					CPrintToChat(client, "{valve}Tutorial {white}| As an engineer, your sentry inherits your survivability upgrades on the body.\nThe sentry upgrades are located on melee upgrades.");
				}
			}
		}
	}
}

public Action:thunderClapPart2(Handle timer, any:data) 
{  
	ResetPack(data);
	int victim = EntRefToEntIndex(ReadPackCell(data));
	int client = EntRefToEntIndex(ReadPackCell(data));
	if(IsValidClient3(client) && IsValidClient3(victim))
	{
		float velocity[3];
		velocity[0]=0.0;
		velocity[1]=0.0;
		velocity[2]=-3000.0;
		TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velocity);
		RadiationBuildup[victim] += 100.0;
		checkRadiation(victim,client);
	}
	CloseHandle(data);
}
public Action:eurekaDelayed(Handle timer, int client) 
{
	client = EntRefToEntIndex(client);
	if(IsValidClient3(client))
	{
		int melee = (GetPlayerWeaponSlot(client,2));
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
				
				TE_SetupBeamRingPoint(clientpos, 20.0, 1000.0, g_LightningSprite, spriteIndex, 0, 5, 0.5, 10.0, 1.0, color, 200, 0);
				TE_SendToAll();
				
				EmitSoundToAll(SOUND_THUNDER, 0, _, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,clientpos);
				
				float LightningDamage = 500.0 * TF2_GetSentryDPSModifiers(client, melee);
				
				int i = -1;
				while ((i = FindEntityByClassname(i, "*")) != -1)
				{
					if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
					{
						float VictimPos[3];
						GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
						VictimPos[2] += 30.0;
						if(GetVectorDistance(clientpos,VictimPos,true) <= 1000000.0)
						{
							if(IsPointVisible(clientpos,VictimPos))
							{
								currentDamageType[client].second |= DMG_IGNOREHOOK;
								SDKHooks_TakeDamage(i,client,client, LightningDamage, 1073741824, _,_,_,false);
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
public Action:CreateBloodTracer(Handle timer,any:data)
{
	ResetPack(data);
	int weapon = EntRefToEntIndex(ReadPackCell(data));
	int client = EntRefToEntIndex(ReadPackCell(data));
	if(IsValidEdict(client) && IsValidEdict(weapon))
	{
		float fAngles[3], fOrigin[3], vBuffer[3], fOriginEnd[3], fwd[3], opposite[3], PlayerOrigin[3];
		TracePlayerAimRanged(client, 1000.0, fOrigin);
		GetClientEyePosition(client, PlayerOrigin);
		GetClientEyeAngles(client, fAngles);
		GetAngleVectors(fAngles, fwd, NULL_VECTOR, vBuffer);
		ScaleVector(fwd, -80.0);
		AddVectors(fOrigin, fwd, fOrigin);
		fOriginEnd = fOrigin;
		ScaleVector(vBuffer, 200.0);
		AddVectors(fOriginEnd, vBuffer, fOriginEnd)
		ScaleVector(vBuffer, -1.0);
		AddVectors(fOrigin, vBuffer, fOrigin)
		
		opposite[0] = GetRandomFloat( -500.0, 500.0 );
		opposite[1] = GetRandomFloat( -500.0, 500.0 );
		opposite[2] = GetRandomFloat( -100.0, 100.0 );
		
		float mult = 1.0
		Address multiHitActive = TF2Attrib_GetByName(weapon, "taunt move acceleration time");
		if(multiHitActive != Address_Null)
		{
			mult *= TF2Attrib_GetValue(multiHitActive) + 1.0;
		}
		mult *= TF2_GetDPSModifiers(client, weapon, false, false) * 10.0;
		int i = -1;
		while ((i = FindEntityByClassname(i, "*")) != -1)
		{
			if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
			{
				float VictimPos[3];
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
				VictimPos[2] += 30.0;
				if(GetVectorDistance(fOrigin,VictimPos,true) <= 250000)
				{
					if(IsPointVisible(PlayerOrigin,VictimPos))
					{
						CreateParticleEx(i, "env_sawblood");
						currentDamageType[client].second |= DMG_IGNOREHOOK;
						SDKHooks_TakeDamage(i,client,client, mult, DMG_SLASH, weapon, _,_,false);
					}
				}
			}
		}
		
		switch(GetRandomInt(1,3)){
			case 1:{
				EmitSoundToAll(SOUND_SLASHHIT1, 0,_,SNDLEVEL_NORMAL,_,1.0, _, _, fOrigin);
			}
			case 2:{
				EmitSoundToAll(SOUND_SLASHHIT2, 0,_,SNDLEVEL_NORMAL,_,1.0, _, _, fOrigin);
			}
			case 3:{
				EmitSoundToAll(SOUND_SLASHHIT3, 0,_,SNDLEVEL_NORMAL,_,1.0, _, _, fOrigin);
			}
		}
		fOrigin[0] += opposite[0] + GetRandomFloat( -200.0, 200.0 );
		fOrigin[1] += opposite[1] + GetRandomFloat( -200.0, 200.0 );
		fOrigin[2] += opposite[2]
		
		fOriginEnd[0] -= opposite[0]
		fOriginEnd[1] -= opposite[1]
		fOriginEnd[2] -= opposite[2]

		int color[4];
		color = {255, 0, 0, 255}
		TE_SetupBeamPoints(fOrigin,fOriginEnd,Laser,Laser,0,5,2.5,2.0,2.0,3,1.0,color,10);
		TE_SendToAll();
		
		shouldAttack[client] = true;
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", currentGameTime);
		RequestFrame(disableWeapon,client);
	}
	CloseHandle(data);
}
public Action:removeBulletsPerShot(Handle timer, int client) 
{  
    if(IsValidClient3(client)) 
    { 
		TF2Attrib_SetByName(client, "bullets per shot bonus", 1.0);
		refreshAllWeapons(client);
		StunShotStun[client] = false;
		StunShotBPS[client] = false;
    }
}
public Action Timer_SplittingThunderThink(Handle timer, int entityRef){
	int entity = EntRefToEntIndex(entityRef);
	if(!IsValidEntity(entity))
		return Plugin_Stop;
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient3(owner))
		return Plugin_Continue;
	
	int spellLevel = RoundToNearest(GetAttribute(owner, "arcane splitting thunder", 0.0));
	if(spellLevel < 1)
		return Plugin_Continue;

	float startpos[3], endpos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", endpos);

	startpos[0] = endpos[0];
	startpos[1] = endpos[1];
	startpos[2] = endpos[2] + 1600;
	
	int color[4];
	color = {255,228,0,255};
	
	// define the direction of the sparks
	float dir[3] = {0.0, 0.0, 0.0};
	
	TE_SetupBeamPoints(startpos, endpos, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
	TE_SendToAll();
	
	TE_SetupSparks(endpos, dir, 300, 1000);
	TE_SendToAll();
	
	TE_SetupEnergySplash(endpos, dir, false);
	TE_SendToAll();
	
	TE_SetupSmoke(endpos, g_SmokeSprite, 5.0, 10);
	TE_SendToAll();
	
	float scaling[] = {0.0, 100.0, 200.0, 300.0};
	float ProjectileDamage = 2000.0 + (Pow(ArcaneDamage[owner]*Pow(ArcanePower[owner], 4.0),spellScaling[spellLevel]) * scaling[spellLevel]);

	EntityExplosion(owner, ProjectileDamage, 300.0, endpos, -1, false, entity);
	EmitSoundToAll(SOUND_THUNDER, entity, _, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,endpos);

	return Plugin_Continue;
}
public Action:AttackTwice(Handle timer, any:data) 
{  
	ResetPack(data);
	int client = EntRefToEntIndex(ReadPackCell(data));
	int CWeapon = EntRefToEntIndex(ReadPackCell(data));
	int timesLeft = ReadPackCell(data);
	if(IsValidClient3(client) && IsValidEdict(CWeapon))
	{
		timesLeft--;
		shouldAttack[client] = true;
		SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", currentGameTime);
		
		if(timesLeft > 0)
		{
			Handle hPack = CreateDataPack();
			WritePackCell(hPack, EntIndexToEntRef(client));
			WritePackCell(hPack, EntIndexToEntRef(CWeapon));
			WritePackCell(hPack, timesLeft);
			CreateTimer(0.1,AttackTwice,hPack);
		}
	}
	else
	{
		KillTimer(timer)
	}
	CloseHandle(data);
}
public Action deletePack(Handle timer, DataPack data){
	delete data;
	return Plugin_Stop;
}
public Action:orbitalStrike(Handle timer,any:data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	int iTeam = ReadPackCell(data);
	float ProjectileDamage = ReadPackFloat(data);
	float ClientPos[3];
	ClientPos[0] = ReadPackFloat(data);
	ClientPos[1] = ReadPackFloat(data);
	ClientPos[2] = ReadPackFloat(data);
	float ClientOrigin[3];
	ClientOrigin[0] = ReadPackFloat(data);
	ClientOrigin[1] = ReadPackFloat(data);
	ClientOrigin[2] = ReadPackFloat(data);
	int iEntity = CreateEntityByName("tf_projectile_rocket");
	if (IsValidEdict(iEntity)) 
	{
		float fAngles[3]
		float fOrigin[3]
		float vBuffer[3]
		float fVelocity[3]
		float EndVector[3]
		SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
		SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
		SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
		
		fOrigin = ClientOrigin;
		fOrigin[0] += GetRandomFloat(-300.0,300.0);
		fOrigin[1] += GetRandomFloat(-300.0,300.0);
		fOrigin[2] = getHighestPosition(fOrigin)-50.0;
		
		MakeVectorFromPoints(fOrigin, ClientPos , EndVector);
		GetVectorAngles(EndVector, fAngles);
		GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		
		float Speed = 4500.0;
		fVelocity[0] = vBuffer[0]*Speed;
		fVelocity[1] = vBuffer[1]*Speed;
		fVelocity[2] = vBuffer[2]*Speed;
		SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, ProjectileDamage, true);  
		TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
		DispatchSpawn(iEntity);
	}
}
public Action Timer_ThrownSentryDeploy(Handle timer, any data){
	int entity = EntRefToEntIndex(data);
	if(!IsValidEntity(entity)) return Plugin_Stop;
	int parent = GetEntPropEnt(entity, Prop_Send, "moveparent");
	if(!IsValidEntity(parent)) return Plugin_Stop;
	float pos[3];
	GetEntPropVector(parent, Prop_Data, "m_vecOrigin", pos);
	float mins[3],maxs[3],vec[3],angles[3];

	GetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);
	vec[0] = pos[0];
	vec[1] = pos[1];
	vec[2] = pos[2] - 5.0;
	pos[2] += 5.0;

	Handle tr = TR_TraceHullFilterEx(pos,vec, mins,maxs, MASK_PLAYERSOLID_BRUSHONLY, TraceWorldOnly);
	if (!TR_DidHit(tr)) {
		delete tr
		return Plugin_Continue;
	}

	delete tr

	AcceptEntityInput(entity, "ClearParent");
	float zeros[3];

	GetEntPropVector(parent, Prop_Data, "m_angRotation", angles);
	angles[0] = 0.0;

	TeleportEntity(entity, pos, angles, zeros); //use 0-velocity to calm down bouncyness
	//restore other props: get it out of peudo carry state 
	SetEntProp(entity, Prop_Send, "m_bBuilding", 1);
	SetEntProp(entity, Prop_Send, "m_bCarried", 0);
	SDKCall(g_SDKFastBuild, entity, true);
	SetEntityRenderMode(entity, RENDER_NORMAL);
	RemoveEntity(parent);
	isPrimed[entity] = true;
	return Plugin_Stop;
}
public Action SetTankTeleporter(Handle timer, int entity) 
{ 
	entity = EntRefToEntIndex(entity)
	if(IsValidEdict(entity))
		TankTeleporter = entity;
	
	return Plugin_Stop;
}
public Action:ShootTwice(Handle timer, any:data) 
{  
	ResetPack(data);
	int inflictor = EntRefToEntIndex(ReadPackCell(data));
	int client = EntRefToEntIndex(ReadPackCell(data));
	int timesLeft = ReadPackCell(data);
	if(!IsValidClient3(inflictor) && IsValidEdict(inflictor) && HasEntProp(inflictor,Prop_Send,"m_hBuilder") && timesLeft > 0)
	{
		if(IsValidClient3(client))
		{
			int melee = (GetPlayerWeaponSlot(client,2));
			if(IsValidEdict(melee))
			{
				Address doubleShotActive = TF2Attrib_GetByName(melee, "dmg penalty vs nonstunned");
				if(doubleShotActive != Address_Null && TF2Attrib_GetValue(doubleShotActive) > 0.0)
				{
					int iEntity = CreateEntityByName("tf_projectile_sentryrocket");
					if (IsValidEdict(iEntity)) 
					{
						float fAngles[3]
						float fOrigin[3]
						float vBuffer[3]
						float fVelocity[3]
						float fwd[3]
						int iTeam = GetClientTeam(client);
						SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

						SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
						SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
						SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
						SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
									
						int angleOffsetB = FindSendPropInfo("CObjectSentrygun", "m_iAmmoShells") - 16;
						GetEntPropVector( inflictor, Prop_Send, "m_vecOrigin", fOrigin );
						fOrigin[2] += 55.0;
						GetEntDataVector( inflictor, angleOffsetB, fAngles );
						
						GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
						GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(fwd, 30.0);
						
						AddVectors(fOrigin, fwd, fOrigin);
						
						float Speed = 1100.0;
						Address projspeed = TF2Attrib_GetByName(melee, "Projectile speed increased");
						Address projspeed1 = TF2Attrib_GetByName(melee, "Projectile speed decreased");
						if(projspeed != Address_Null){
							Speed *= TF2Attrib_GetValue(projspeed)
						}
						if(projspeed1 != Address_Null){
							Speed *= TF2Attrib_GetValue(projspeed1)
						}
						fVelocity[0] = vBuffer[0]*Speed;
						fVelocity[1] = vBuffer[1]*Speed;
						fVelocity[2] = vBuffer[2]*Speed;
						
						float ProjectileDamage = 100.0;
						
						Address SentryDmgActive = TF2Attrib_GetByName(melee, "engy sentry damage bonus");
						if(SentryDmgActive != Address_Null)
						{
							ProjectileDamage *= TF2Attrib_GetValue(SentryDmgActive);
						}
						SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, ProjectileDamage, true);  
						SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity ); 
						TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
						DispatchSpawn(iEntity);
						timesLeft--;
						if(timesLeft > 0)
						{
							Handle hPack = CreateDataPack();
							WritePackCell(hPack, EntIndexToEntRef(inflictor));
							WritePackCell(hPack, EntIndexToEntRef(client));
							WritePackCell(hPack, timesLeft);
							CreateTimer(0.1,ShootTwice,hPack);
						}
					}
				}
			}
		}
	}
	else
	{
		KillTimer(timer)
	}
	CloseHandle(data);
}
public Action RecursiveExplosions(Handle timer, DataPack ref) 
{
	ref.Reset();
    int owner = EntRefToEntIndex(ref.ReadCell()); 
	int weapon = EntRefToEntIndex(ref.ReadCell());
	float position[3];
	position[0] = ref.ReadFloat();
	position[1] = ref.ReadFloat();
	position[2] = ref.ReadFloat();

	if(IsValidClient3(owner) && IsValidWeapon(weapon)){
		EntityExplosion(owner, ref.ReadFloat(), ref.ReadFloat(), position);
		float chance = GetAttribute(weapon, "sticky recursive explosion chance", 0.0)
		if(chance >= GetRandomFloat(0.0,1.0)){
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}
public Action:ReEnable(Handle timer, any:ref) 
{ 
    int entity = EntRefToEntIndex(ref); 

    if(IsValidEdict(entity)) 
    { 
		AcceptEntityInput(entity, "Enable");
		KillTimer(timer)
    }
	else
	{
		KillTimer(timer)
	}
}
public Action:ArrowThink(Handle timer, any:ref) 
{ 
	int entity = EntRefToEntIndex(ref); 
    if(IsValidEdict(entity) && !gravChanges[entity]) 
    { 
		SetEntityGravity(entity, 0.001);
    }
	else
	{
		KillTimer(timer)
	}
}
public Action ElectricBallThink(Handle timer, any ref){
	int entity = EntRefToEntIndex(ref); 
    if(IsValidEntity(entity)) 
    { 
		int client = getOwner(entity);
		int weapon = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");
		float damage = 25.0*TF2_GetDPSModifiers(client, weapon);
		float radius = 240.0*GetAttribute(weapon, "Blast radius increased");
		float position[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", position);

		for(int i = 1; i<=MaxClients; ++i){
			if(!IsValidClient3(i))
				continue;
			if(!IsPlayerAlive(i))
				continue;
			if(!IsOnDifferentTeams(client, i))
				continue;

			float victimPosition[3];
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", victimPosition);

			if(GetVectorDistance(position, victimPosition, true) > radius*radius)
				continue;
			
			currentDamageType[client].second |= DMG_IGNOREHOOK;
			SDKHooks_TakeDamage(i, entity, client, damage, DMG_BURN, weapon,_,_,false);
		}
		return Plugin_Continue;
    }
	return Plugin_Stop;
}
public Action:Timer_PlayerGrenadeMines(Handle timer, any:ref) 
{
    int entity = EntRefToEntIndex(ref);
	bool flag = false;
	if(IsValidEdict(entity))
	{
		int client = GetEntPropEnt(entity, Prop_Data, "m_hThrower"); 
		if(IsValidClient3(client))
		{
			float distance = GetEntPropFloat(entity, Prop_Send, "m_DmgRadius")
			float damage = GetEntPropFloat(entity, Prop_Send, "m_flDamage")
			float grenadevec[3], targetvec[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", grenadevec);
			for(int i=0; i<=MaxClients; ++i)
			{
				if(!IsValidClient3(i)){continue;}
				GetClientAbsOrigin(i, targetvec);
				if(!IsClientObserver(i) && GetClientTeam(i) != GetClientTeam(client) && GetVectorDistance(grenadevec, targetvec, true) < distance*distance)
				{
					if(!IsPlayerInSpawn(i) && client != i && IsAbleToSee(client,i))
					{
						EntityExplosion(client, damage, distance, grenadevec, 0,_,entity);
						RemoveEntity(entity);
						flag = true;
						break;
					}
				}
			}
		}
		else
		{
			flag = true;
		}
	}
	else
	{
		flag = true;
	}
	if(flag == true)
	{
		KillTimer(timer);
	}
}
public Action:Timer_KillPlayer(Handle timer,Handle datapack)
{
	ResetPack(datapack);
	int victim = EntRefToEntIndex(ReadPackCell(datapack));
	int attacker = EntRefToEntIndex(ReadPackCell(datapack));
	if(IsValidClient3(victim) && IsValidClient3(attacker) && StrangeFarming[victim][attacker] > 0)
	{
		int currentWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if(IsValidEdict(currentWeapon))
		{
			SDKHooks_TakeDamage(victim,attacker,attacker,100000000.0, DMG_GENERIC,currentWeapon,NULL_VECTOR,NULL_VECTOR)
			TF2_RespawnPlayer(victim);
			
			Handle Newdatapack = CreateDataPack();
			WritePackCell(Newdatapack,EntIndexToEntRef(victim));
			WritePackCell(Newdatapack,EntIndexToEntRef(attacker));
			CreateTimer(0.1,Timer_KillPlayer,Newdatapack);
			StrangeFarming[victim][attacker]--;
		}
	}
	CloseHandle(datapack);
}