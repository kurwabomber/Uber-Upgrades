public Action:Timer_Second(Handle timer)
{
	for(int client = 1; client < MaxClients; client++)
	{
		if(singularBuysPerMinute[client] > 0)
			singularBuysPerMinute[client]--;
		if (IsValidClient3(client) && !IsFakeClient(client))
		{
			Address armorActive = TF2Attrib_GetByName(client, "obsolete ammo penalty")
			if(armorActive != Address_Null)
			{
				float armorAmount = TF2Attrib_GetValue(armorActive);
				fl_MaxArmor[client] = armorAmount+300.0;
			}
			else
			{
				fl_MaxArmor[client] = 300.0;
			}
			Address resActive = TF2Attrib_GetByName(client, "energy weapon no drain")
			if(resActive != Address_Null)
			{
				float resAmount = TF2Attrib_GetValue(resActive);
				fl_ArmorRes[client] = resAmount+1.0;
			}
			else
			{
				fl_ArmorRes[client] = 1.0;
			}
			fl_ArmorCap[client] = GetResistance(client);
			
			GetClientCookie(client, hArmorXPos, ArmorXPos[client], sizeof(ArmorXPos));
			GetClientCookie(client, hArmorYPos, ArmorYPos[client], sizeof(ArmorYPos));
			
			Address armorRecharge = TF2Attrib_GetByName(client, "tmp dmgbuff on hit");
			float ArmorRechargeMult = 1.0;
			if(fl_ArmorRegenBonusDuration[client] > 0.0)
			{
				ArmorRechargeMult *= fl_ArmorRegenBonus[client]
			}
			fl_ArmorRegenConstant[client] = 0.0;
			if(IsNearSpencer(client) == true)
			{
				ArmorRechargeMult *= 2.0
				fl_ArmorRegenConstant[client] += 0.05;
			}
			Address HealingReductionActive = TF2Attrib_GetByName(client, "health from healers reduced");
			if(HealingReductionActive != Address_Null)
			{
				ArmorRechargeMult *= TF2Attrib_GetValue(HealingReductionActive);
			}
			if(armorRecharge != Address_Null)
			{
				ArmorRechargeMult *= TF2Attrib_GetValue(armorRecharge);
			}
			int healers = GetEntProp(client, Prop_Send, "m_nNumHealers");
			if(healers > 0)
			{
				for (int i = 1; i < MaxClients; i++)
				{
					if (IsValidClient(i))
					{
						int healerweapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
						if(IsValidEntity(healerweapon))
						{
							if(HasEntProp(healerweapon, Prop_Send, "m_hHealingTarget") && GetEntPropEnt(healerweapon, Prop_Send, "m_hHealingTarget") == client)
							{
								if(IsValidEntity(healerweapon))
								{
									Address overhealBonus = TF2Attrib_GetByName(healerweapon, "overheal bonus");
									if(overhealBonus != Address_Null)
									{
										ArmorRechargeMult *= TF2Attrib_GetValue(overhealBonus);
									}
									Address constantArmorRegen = TF2Attrib_GetByName(healerweapon, "SRifle Charge rate increased");
									if(constantArmorRegen != Address_Null)
									{
										fl_ArmorRegenConstant[client] += (fl_ArmorRegen[client]*TF2Attrib_GetValue(constantArmorRegen));
									}
								}
							}
						}
					}
				}
			}
			if(TF2_IsPlayerInCondition(client, TFCond_MegaHeal))
			{
				ArmorRechargeMult *= 2.0;
			}
			fl_ArmorRegen[client] = (fl_MaxArmor[client]*0.0002);
			fl_ArmorRegen[client] += (fl_MaxArmor[client]*0.0002*ArmorRechargeMult);
			//Arcane
			float arcanePower = 1.0;
			
			Address ArcaneActive = TF2Attrib_GetByName(client, "arcane power")
			if(ArcaneActive != Address_Null)
			{
				arcanePower = TF2Attrib_GetValue(ArcaneActive);
			}
			ArcanePower[client] = arcanePower;
			
			float arcaneDamageMult = 1.0;
			Address ArcaneDamageActive = TF2Attrib_GetByName(client, "arcane damage")
			if(ArcaneDamageActive != Address_Null)
			{
				arcaneDamageMult = TF2Attrib_GetValue(ArcaneDamageActive);
			}
			ArcaneDamage[client] = arcaneDamageMult;
			Address focusActive = TF2Attrib_GetByName(client, "arcane focus max")
			if(focusActive != Address_Null)
			{
				fl_MaxFocus[client] = (TF2Attrib_GetValue(focusActive)+100.0)* Pow(arcanePower, 2.0);
			}
			else
			{
				fl_MaxFocus[client] = 100.0*arcanePower;
			}
			Address regenActive = TF2Attrib_GetByName(client, "arcane focus regeneration")
			if(regenActive != Address_Null)
			{
				fl_RegenFocus[client] = fl_MaxFocus[client] * 0.00015 * TF2Attrib_GetValue(regenActive) *  Pow(arcanePower, 2.0);
			}
			else
			{
				fl_RegenFocus[client] = fl_MaxFocus[client] * 0.00015 *  Pow(arcanePower, 2.0);
			}
		}
	}
	if(IsMvM())
	{
		for(int i = 1; i < MaxClients; i++)
		{
			if(IsValidClient3(i))
			{
				if(IsFakeClient(i) && !IsClientObserver(i) && IsPlayerAlive(i))
				{
					BotTimer[i] -= 1.0;
					if(BotTimer[i] <= 0.0)
					{
						BotTimer[i] = 120.0;
						if(TF2_IsPlayerInCondition(i, TFCond_UberchargedHidden) || TF2Spawn_IsClientInSpawn(i))
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
	for(int client = 0; client < MaxClients; client++)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			if(CurrencyOwned[client] >= 300000000000.0)
			{
				CurrencyOwned[client] = 300000000000.0;
			}
			if(CurrencyOwned[client] < 0.0)
			{
				CurrencyOwned[client] = 0.0;
			}
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
						Menu_UpgradeChoice(client, current_w_sc_list_id[client], current_w_c_list_id[client], fstr2, playerUpgradeMenuPage[client]);
					}
				}

				if(disableIFMiniHud[client] <= 0.0)
				{
					char Startcash[128]
					Format(Startcash, sizeof(Startcash), "%.0f Startmoney\n$%.0f\n%0.f Player Kills\n%0.f Player Deaths\n%s Damage Dealt\n%s DPS\n%0.f RPS\n%s Damage Healed", StartMoney+additionalstartmoney,CurrencyOwned[client],Kills[client],Deaths[client],GetAlphabetForm(DamageDealt[client]),GetAlphabetForm(dps[client]),RPS[client],GetAlphabetForm(Healed[client])); 
					SendItemInfo(client, Startcash);
				}
				SetEntProp(client, Prop_Send, "m_nCurrency", 0);
				char ArmorLeft[64]
				int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					Format(ArmorLeft, sizeof(ArmorLeft), "Armor | %i / %i", RoundToCeil(fl_CurrentArmor[client] + fl_AdditionalArmor[client]), RoundToNearest(fl_MaxArmor[client])); 
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
						for(int i = 0;i<Max_Attunement_Slots && attunement > activeSpells;i++)
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

					if (AreClientCookiesCached(client))
					{
						if(StringToFloat(ArmorXPos[client]) != 0.0 && StringToFloat(ArmorYPos[client]))
						{
							if(fl_AdditionalArmor[client] <= 0.0)
							{
								SetHudTextParams(StringToFloat(ArmorXPos[client]), StringToFloat(ArmorYPos[client]), 0.5, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudSync, ArmorLeft);
							}
							else
							{
								SetHudTextParams(StringToFloat(ArmorXPos[client]), StringToFloat(ArmorYPos[client]), 0.5, 255, 187, 0, 255, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudSync, ArmorLeft);
							}
						}
						else
						{
							if(fl_AdditionalArmor[client] <= 0.0)
							{
								SetHudTextParams(-0.75, -0.2, 0.21, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudSync, ArmorLeft);
							}
							else
							{
								SetHudTextParams(-0.75, -0.2, 0.21, 255, 187, 0, 255, 0, 0.0, 0.0, 0.0);
								ShowSyncHudText(client, hudSync, ArmorLeft);
							}
						}
					}
					else
					{
						if(fl_AdditionalArmor[client] <= 0.0)
						{
							SetHudTextParams(-0.75, -0.2, 0.21, 0, 101, 189, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudSync, ArmorLeft);
						}
						else
						{
							SetHudTextParams(-0.75, -0.2, 0.21, 255, 187, 0, 255, 0, 0.0, 0.0, 0.0);
							ShowSyncHudText(client, hudSync, ArmorLeft);
						}
					}
				}
			}

			oldPlayerButtons[client] = globalButtons[client];
		}
		if(IsValidClient3(client))
		{
			Address RegenActive = TF2Attrib_GetByName(client, "disguise on backstab");
			if(RegenActive != Address_Null)
			{
				float RegenPerSecond = TF2Attrib_GetValue(RegenActive);
				float RegenPerTick = RegenPerSecond/10;
				Address HealingReductionActive = TF2Attrib_GetByName(client, "health from healers reduced");
				if(HealingReductionActive != Address_Null)
				{
					RegenPerTick *= TF2Attrib_GetValue(HealingReductionActive);
				}
				
				Address regenerationPowerup = TF2Attrib_GetByName(client, "recall");
				if(regenerationPowerup != Address_Null)
				{
					float regenerationPowerupValue = TF2Attrib_GetValue(regenerationPowerup);
					if(regenerationPowerupValue > 0.0)
					{
						RegenPerTick += TF2_GetMaxHealth(client) / 100.0;
					}
				}
				
				int clientHealth = GetEntProp(client, Prop_Data, "m_iHealth");
				int clientMaxHealth = TF2_GetMaxHealth(client);
				if(clientHealth < clientMaxHealth)
				{
					if(TF2_IsPlayerInCondition(client, TFCond_MegaHeal))
					{
						RegenPerTick *= 2.0;
					}
					if(TF2_IsPlayerInCondition(client, TFCond_Plague))
					{
						RegenPerTick *= 0.0;
					}
					if(float(clientHealth) + RegenPerTick < clientMaxHealth)
					{
						SetEntProp(client, Prop_Data, "m_iHealth", clientHealth+RoundToNearest(RegenPerTick));
					}
					else
					{
						SetEntProp(client, Prop_Data, "m_iHealth", clientMaxHealth);
					}
				}
			}
			int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(CWeapon))
			{
				Address PrecisionActive = TF2Attrib_GetByName(CWeapon, "medic regen bonus");
				if(PrecisionActive != Address_Null)
				{
					if(TF2Attrib_GetValue(PrecisionActive) != 0.0)
					{
						TF2_AddCondition(client, TFCond_RunePrecision, 0.2);
					}
				}
			}
			Address conditionToggle = TF2Attrib_GetByName(client, "has pipboy build interface");
			if(conditionToggle != Address_Null)
			{
				if(TF2Attrib_GetValue(conditionToggle) > 1.0)
				{
					TF2_AddCondition(client, view_as<TFCond>(RoundToNearest(TF2Attrib_GetValue(conditionToggle))), 0.2);
				}
			}
		}
	}
}
public Action:Timer_Every100MS(Handle timer)
{
	for(int client = 1; client < MaxClients; client++)
	{
		if (IsValidClient3(client) && IsPlayerAlive(client))
		{
			Address bleedResistance = TF2Attrib_GetByName(client, "sapper damage penalty");
			int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			int primary = GetWeapon(client, 0);
			int secondary = GetWeapon(client, 1);
			int melee = GetWeapon(client, 2);
			if(bleedResistance != Address_Null)
			{
				BleedMaximum[client] = 100.0 + TF2Attrib_GetValue(bleedResistance);
			}
			if(!IsFakeClient(client))
			{
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
					
					SetHudTextParams(0.43, 0.21, 0.21, 199, 28, 28, 255, 0, 0.0, 0.0, 0.0);
					ShowSyncHudText(client, hudStatus, StatusEffectText);
				}
				if(RageBuildup[client] > 0.0)
				{
					char StatusEffectText[256]
					if(RageBuildup[client] < 1.0)
					{
						Format(StatusEffectText, sizeof(StatusEffectText),"Revenge: %.0f%", RageBuildup[client]*100.0);
					}
					else
					{
						Format(StatusEffectText, sizeof(StatusEffectText),"Revenge: READY (Crouch + Mouse3)", RageBuildup[client]*100.0);
					}
					
					SetHudTextParams(0.1, 0.85, 0.21, 199, 28, 28, 255, 0, 0.0, 0.0, 0.0);
					ShowHudText(client, 9, StatusEffectText);
					
					if(RageActive[client] == true)
					{
						TF2_AddCondition(client, TFCond_CritCanteen, 1.0);
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
						TF2_AddCondition(client, TFCond_DefenseBuffMmmph, 1.0);
						TF2_AddCondition(client, TFCond_PreventDeath, 1.0);
						TF2_AddCondition(client, TFCond_KingAura, 1.0);
						CreateParticle(client, "critgun_weaponmodel_red", true, "", 1.0,_,_,1);
						TE_SendToAll();
					}
				}
				if(SupernovaBuildup[client] > 0.0)
				{
					char StatusEffectText[256]
					if(SupernovaBuildup[client] < 1.0)
					{
						Format(StatusEffectText, sizeof(StatusEffectText),"Supernova: %.0f%", SupernovaBuildup[client]*100.0);
					}
					else
					{
						Format(StatusEffectText, sizeof(StatusEffectText),"Supernova: READY (Crouch + Mouse3)", SupernovaBuildup[client]*100.0);
					}
					SetHudTextParams(0.1, 0.85, 0.21, 199, 28, 28, 255, 0, 0.0, 0.0, 0.0);
					ShowHudText(client, 9, StatusEffectText);
				}
			}
			float plaguePower = 0.0;
			Address plaguePowerup = TF2Attrib_GetByName(client, "plague powerup");
			float clientPos[3];
			GetEntPropVector(client, Prop_Data, "m_vecOrigin", clientPos);
			if(plaguePowerup != Address_Null && TF2Attrib_GetValue(plaguePowerup) > 0.0)
			{
				plaguePower = 1.0;
				for(int e = MaxClients;e<MAXENTITIES;e++)
				{
					if(IsValidEntity(e))
					{
						char strName[32];
						GetEntityClassname(e, strName, 32)
						if(StrContains(strName, "item_healthkit_", false) == 0 && GetEntProp(e, Prop_Data, "m_bDisabled") == 0)
						{
							float VictimPos[3];
							GetEntPropVector(e, Prop_Data, "m_vecOrigin", VictimPos);
							if(GetVectorDistance(clientPos,VictimPos) <= 600.0)
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
			for(int i=1;i<MaxClients;i++)
			{
				if(corrosiveDOT[client][i][0] != 0.0 && corrosiveDOT[client][i][1] >= 0.0)
				{
					corrosiveDOT[client][i][1] -= 0.07
					if(IsValidClient3(i))
					{
						SDKHooks_TakeDamage(client,i,i,corrosiveDOT[client][i][0],DMG_BLAST,-1, NULL_VECTOR, NULL_VECTOR);
					}
				}
				if(plaguePower > 0.0 && IsValidClient3(i) && IsPlayerAlive(i) && !TF2_IsPlayerInCondition(i,TFCond_Plague))
				{
					if(IsOnDifferentTeams(client,i))
					{
						float VictimPos[3];
						GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
						if(GetVectorDistance(clientPos,VictimPos) <= 100.0)
						{
							plagueAttacker[i] = client;
							TF2_AddCondition(i, TFCond_Plague, 20.0);
							TF2_AddCondition(i, TFCond_NoTaunting_DEPRECATED, 2.0);
						}
					}
				}
			}
			if(IsValidEntity(CWeapon))
			{
				Address infAmmo = TF2Attrib_GetByName(CWeapon, "vision opt in flags")
				if(infAmmo != Address_Null)
				{
					SetAmmo_Weapon(CWeapon,RoundToNearest(TF2Attrib_GetValue(infAmmo)))
				}
			}
			if(IsValidEntity(melee) && GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex") == 307)
			{
				if(CaberUses[client] > 0 && GetEntProp(melee, Prop_Send, "m_iDetonated") == 1)
				{
					SetEntProp(melee, Prop_Send, "m_bBroken", 0);
					SetEntProp(melee, Prop_Send, "m_iDetonated", 0);
					CaberUses[client]--;
				}
			}
			if(IsValidEntity(primary))
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
							miniCritStatusAttacker[client] = 0.3
							TF2_AddCondition(client, TFCond_RuneHaste, 0.3);
							TF2_RemoveCondition(client, TFCond_FocusBuff);
						}
						case 594:
						{
							miniCritStatusAttacker[client] = 0.3
							TF2_AddCondition(client, TFCond_RuneAgility, 0.3);
							TF2_RemoveCondition(client, TFCond_CritMmmph);
						}
					}
				}
			}
			if(IsValidEntity(secondary))
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
					//Base Vanilla Buff Overrides
					int buff = GetEntProp(secondary, Prop_Send, "m_iItemDefinitionIndex")
					switch(buff)
					{
						case 129,1001:
						{
							float ClientPos[3], VictimPos[3];
							for(int i=1;i<MaxClients;i++)
							{
								if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(client) == GetClientTeam(i))
								{
									GetClientAbsOrigin(client, ClientPos);
									GetClientAbsOrigin(i, VictimPos);
									if(GetVectorDistance(ClientPos,VictimPos) <= range)
									{
										TF2_AddCondition(i, TFCond_DisguiseRemoved, 0.3)//Buff Banner | 1.8x dmg
										if(miniCritStatusAttacker[i] < 0.3)
											miniCritStatusAttacker[i] = 0.3
									}
								}
							}
						}
						case 226:
						{
							float ClientPos[3], VictimPos[3];
							for(int i=1;i<MaxClients;i++)
							{
								if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(client) == GetClientTeam(i))
								{
									GetClientAbsOrigin(client, ClientPos);
									GetClientAbsOrigin(i, VictimPos);
									if(GetVectorDistance(ClientPos,VictimPos) <= range)
									{
										TF2_AddCondition(i, TFCond_DefenseBuffNoCritBlock, 0.3)//Battalion's Backup | No more crit immunity
									}
								}
							}
						}
						case 354:
						{
							float ClientPos[3], VictimPos[3];
							for(int i=1;i<MaxClients;i++)
							{
								if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(client) == GetClientTeam(i))
								{
									GetClientAbsOrigin(client, ClientPos);
									GetClientAbsOrigin(i, VictimPos);
									if(GetVectorDistance(ClientPos,VictimPos) <= range)
									{
										TF2_AddCondition(i, TFCond_MedigunDebuff, 0.3)//concheror | 15% lifesteal (150% lifesteal attribute)
									}
								}
							}
						}
					}
					//Custom Buff Effects
					//Lightning Strike banner : lightningCounter : "has pipboy build interface"
					Address lightningBannerActive = TF2Attrib_GetByName(secondary, "has pipboy build interface");
					if(lightningBannerActive != Address_Null && TF2Attrib_GetValue(lightningBannerActive) != 0.0 && IsValidEntity(CWeapon))
					{
						if(lightningCounter[client] >= 8)
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
							
							// define the color of the strike
							int iTeam = GetClientTeam(client);
							//PrintToChat(client, "%i", iTeam);
							int color[4];
							if(iTeam == 2)
							{
								color = {255, 0, 0, 255};
							}
							else if (iTeam == 3)
							{
								color = {0, 0, 255, 255};
							}
							
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
							
							CreateParticle(-1, "utaunt_electricity_cloud_parent_WB", false, "", 5.0, startpos);
							
							EmitAmbientSound("ambient/explosions/explode_9.wav", startpos, client, 50);
							
							float LightningDamage = TF2_GetDPSModifiers(client,CWeapon)*10.0*TF2Attrib_GetValue(lightningBannerActive);
							for(int i = 1; i<MAXENTITIES;i++)
							{
								if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
								{
									float VictimPos[3];
									GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
									VictimPos[2] += 30.0;
									float Distance = GetVectorDistance(clientpos,VictimPos);
									if(Distance <= range*0.3)
									{
										if(IsPointVisible(clientpos,VictimPos))
										{
											SDKHooks_TakeDamage(i,client,client, LightningDamage, 1073741824, -1, NULL_VECTOR, NULL_VECTOR, !IsValidClient3(i));
										}
									}
								}
							}
							lightningCounter[client] = 0;
						}
						else
						{
							lightningCounter[client]++;
						}
					}
				}
			}
		}
	}
}
public Action:Timer_EveryTenSeconds(Handle timer)// Self Explanitory. 
{
	for(int client = 1; client < MaxClients; client++)
	{
		if (IsValidClient3(client) && IsPlayerAlive(client))
		{
			int melee = GetWeapon(client, 2);
			if(IsValidEntity(melee) && GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex") == 307)
			{
				Address MaxChargesActive = TF2Attrib_GetByName(melee, "zombiezombiezombiezombie");
				int MaxCharges = 1;
				if(MaxChargesActive != Address_Null)
				{
					MaxCharges += RoundToNearest(TF2Attrib_GetValue(MaxChargesActive));
				}
				CaberUses[client] = MaxCharges;
			}
			Address bossType = TF2Attrib_GetByName(client, "damage force increase text");
			if(bossType != Address_Null && TF2Attrib_GetValue(bossType) > 0.0)
			{
				float bossValue = TF2Attrib_GetValue(bossType);
				switch(bossValue)
				{
					case 3.0:
					{
						CreateParticle(client, "critgun_weaponmodel_red", true, "", 10.0,_,_,1);
						TE_SendToAll();
						SetEntityRenderColor(client, 190,0,0,255);
						int counter = 0;
						bool clientList[MAXPLAYERS+1];
						for(int i = 1; i<MaxClients; i++)
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
										float distance = GetVectorDistance(clientpos, targetpos);
										if(distance <= 900.0)
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
							
							for(int buffed = 1; buffed<MaxClients;buffed++)
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
							if(IsValidEntity(CWeapon))
							{
								float ClientPos[3];
								float flamePos[3];
								GetClientAbsOrigin(client,ClientPos);
								float sphereRadius = 700.0;
								float tempdiameter;
								for(int i=-9;i<=8;i++){
									float rad=float(i*10)/360.0*(3.14159265*2);
									tempdiameter=sphereRadius*Cosine(rad)*2;
									float heightoffset=sphereRadius*Sine(rad);

									//PrintToChatAll("degree %d rad %f sin %f cos %f radius %f offset %f",i*10,rad,Sine(rad),Cosine(rad),radius,heightoffset);

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
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[0] += 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[1] += 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[1] -= 800.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[0] -= 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[1] += 800.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[0] -= 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[1] -= 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								//
								flamePos[1] -= 400.0;
								CreateParticle(-1, "cinefx_goldrush_flames", false, "", 3.5,flamePos);
								
								
								float DMGDealt = 3.0 * TF2_GetDPSModifiers(client,CWeapon);
								for(int i = 1; i<MAXENTITIES;i++)
								{
									if(IsValidForDamage(i))
									{
										if(IsOnDifferentTeams(client,i))
										{
											float VictimPos[3];
											GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
											float Distance = GetVectorDistance(ClientPos,VictimPos);
											if(Distance <= 800.0)
											{
												CreateParticle(i, "dragons_fury_effect_parent", true, "", 2.0);
												CreateParticle(i, "utaunt_glowyplayer_orange_glow", true, "", 2.0,_,_,1);
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
							miniCritStatusAttacker[client] = 10.0
							TF2_AddCondition(client, TFCond_DodgeChance, 2.5);
							TF2_AddCondition(client, TFCond_AfterburnImmune, 2.5);
							TF2_AddCondition(client, TFCond_UberchargedHidden, 0.01);
							EmitSoundToAll(SOUND_ADRENALINE, client, -1, 150, 0, 1.0);
							CreateParticle(client, "utaunt_tarotcard_red_wind", true, "", 10.0);
						}
						else if(spellCasted == 3 || spellCasted == 1)
						{
							int iTeam = GetClientTeam(client);
							for(int i=0;i<3;i++)
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
									CreateParticle(iEntity, "utaunt_auroraglow_green_parent", true, "", 5.0);
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
						if(IsValidEntity(CWeapon))
						{
							CreateParticle(CWeapon, "utaunt_auroraglow_orange_parent", true, "", 10.0,_,_,1);
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
							
							// define the color of the strike
							int iTeam = GetClientTeam(client);
							//PrintToChat(client, "%i", iTeam);
							int color[4];
							if(iTeam == 2)
							{
								color = {255, 0, 0, 255};
							}
							else if (iTeam == 3)
							{
								color = {0, 0, 255, 255};
							}
							
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
							
							CreateParticle(-1, "utaunt_electricity_cloud_parent_WB", false, "", 5.0, startpos);
							
							EmitAmbientSound("ambient/explosions/explode_9.wav", startpos, client, 50);
							
							float LightningDamage = 150.0*TF2_GetDPSModifiers(client,CWeapon);
						
							for(int i = 1; i<MAXENTITIES;i++)
							{
								if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
								{
									float VictimPos[3];
									GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
									VictimPos[2] += 30.0;
									float Distance = GetVectorDistance(clientpos,VictimPos);
									if(Distance <= 500.0)
									{
										if(IsPointVisible(clientpos,VictimPos))
										{
											SDKHooks_TakeDamage(i,client,client, LightningDamage, 1073741824, -1, NULL_VECTOR, NULL_VECTOR, !IsValidClient3(i));
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
						CreateParticle(client, "utaunt_arcane_yellow_parent", true, "", 10.0);
					}
				}
			}
		}
	}
}
public Action:BuildingRegeneration(Handle timer, any:entity) 
{
	entity = EntRefToEntIndex(entity)
	if(!IsValidEntity(entity) || !IsValidEdict(entity))
	{
		return;
	}
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hBuilder"); 
	if(!IsValidEntity(owner) || !IsValidEdict(owner))
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
public Action:refreshallweapons(Handle timer, int client) 
{
	for(int i = 0;i < 6;i++)
	{
		refreshUpgrades(client,i);
	}
}
public Action:GiveMaxHealth(Handle timer, any:userid) 
{
	int client = GetClientOfUserId(userid);
	if(IsValidClient3(client) && TF2_GetMaxHealth(client) >= GetClientHealth(client))
	{
		SetEntityHealth(client, TF2_GetMaxHealth(client))
	}
}
public Action:SelfDestruct(Handle timer, any:ref) 
{ 
    int entity = EntRefToEntIndex(ref); 

    if(IsValidEdict(entity)) 
    { 
		RemoveEntity(entity);
		KillTimer(timer)
    }
	else
	{
		KillTimer(timer)
	}
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
//On a wave fail:
public Action:THEREWILLBEBLOOD(Handle timer)
{
    int ent, round

    ent = FindEntityByClassname(-1, "tf_objective_resource");
	if(IsValidEntity(ent))
	{
		round = GetEntProp(ent, Prop_Send, "m_nMannVsMachineWaveCount");
		
		if(round > 0)
		{
			int slot,i
			for (int client = 1; client < MaxClients; client++)
			{
				if (IsValidClient(client))
				{
					for (slot = 0; slot < NB_SLOTS_UED; slot++)
					{
						for(i = 0; i < MAX_ATTRIBUTES_ITEM; i++)
						{
							currentupgrades_idx[client][slot][i] = currentupgrades_idx_mvm_chkp[client][slot][i]
							currentupgrades_val[client][slot][i] = currentupgrades_val_mvm_chkp[client][slot][i]
						}
						for(i = 0; i < MAX_ATTRIBUTES; i++)
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
					client_respawn_checkpoint[client] = 1
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
public Action:LockMission(Handle timer)
{
	char responseBuffer[4096];
	int ObjectiveEntity = FindEntityByClassname(-1, "tf_objective_resource");
	GetEntPropString(ObjectiveEntity, Prop_Send, "m_iszMvMPopfileName", responseBuffer, sizeof(responseBuffer));
	PrintToServer("%s mission",responseBuffer);
	if(StrContains(responseBuffer, "IF", false) != -1)
	{
		PrintToServer("Is on a IF mission.");
		return;
	}
	char mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	StrCat(mapName, sizeof(mapName),"_IF");
	ServerCommand("tf_mvm_popfile %s", mapName);
	PrintToServer("Mission was changed to something not Incremental Fortress!");
	CPrintToChatAll("{valve}Incremental Fortress {white}| {red}WARNING {white}| You must choose a mission that is made for Incremental Fortress.");
}
public Action:ResetMission(Handle timer)
{
	bool resetMission = true;
	for(int i = 1;i<MaxClients;i++)
	{
		if(IsClientInGame(i))
		{
			resetMission = false;
		}
	}
	if(resetMission)
	{
		char mapName[64]
		GetCurrentMap(mapName, sizeof(mapName))
		StrCat(mapName, sizeof(mapName),"_IF");
		ServerCommand("tf_mvm_popfile %s", mapName)
		PrintToServer("Everyone left! Time to restart everything.");
		additionalstartmoney = 0.0
		StartMoney = GetConVarFloat(cvar_StartMoney);
		OverAllMultiplier = GetConVarFloat(cvar_BotMultiplier);
		for (int client = 0; client < MaxClients; client++)
		{
			CurrencyOwned[client] = (StartMoney + additionalstartmoney);
		}
		DeleteSavedPlayerData();
	}
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
			if(IsValidEntity(weaponinSlot))
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
	//PrintToChatAll("%i gaming", client);
	if(IsValidClient3(client))
	{
		//PrintToChatAll("%N", client);
		if(IsValidEntity(GetWeapon(client,0)) && HasEntProp(GetWeapon(client,0), Prop_Data, "m_iClip1"))
		{
			int primaryAmmo = GetMaxClip(GetWeapon(client,0));
			if(primaryAmmo > 1)
				SetClipAmmo(client, 0, primaryAmmo);
		}
		if(IsValidEntity(GetWeapon(client,1)) && HasEntProp(GetWeapon(client,1), Prop_Data, "m_iClip1"))
		{
			int secondaryAmmo = GetMaxClip(GetWeapon(client,1));
			if(secondaryAmmo > 1)
				SetClipAmmo(client, 1, secondaryAmmo);
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
public Action:eurekaAttempt(client, const char[] command, argc) 
{
	if(IsValidClient3(client) && eurekaActive[client] == false && weaponArtCooldown[client] <= 0.0)
	{
		eurekaActive[client] = true;
		float tauntDelay = 2.3;
		Address TauntSpeedActive = TF2Attrib_GetByName(client, "gesture speed increase");
		if(TauntSpeedActive != Address_Null)
		{
			tauntDelay /= TF2Attrib_GetValue(TauntSpeedActive);
		}
		CreateTimer(tauntDelay,eurekaDelayed,EntIndexToEntRef(client));
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
	eurekaActive[client] = false;
	if(IsValidClient3(client))
	{
		int melee = (GetPlayerWeaponSlot(client,2));
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
				
				// define the color of the strike
				int iTeam = GetClientTeam(client);
				//PrintToChat(client, "%i", iTeam);
				int color[4];
				if(iTeam == 2)
				{
					color = {255, 0, 0, 255};
				}
				else if (iTeam == 3)
				{
					color = {0, 0, 255, 255};
				}
				
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
				
				CreateParticle(-1, "utaunt_electricity_cloud_parent_WB", false, "", 5.0, startpos);
				
				EmitAmbientSound("ambient/explosions/explode_9.wav", startpos, client, 50);
				
				float LightningDamage = 500.0;
				
				int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					Address SentryDmgActive = TF2Attrib_GetByName(CWeapon, "ring of fire while aiming");
					if(SentryDmgActive != Address_Null)
					{
						LightningDamage *= TF2Attrib_GetValue(SentryDmgActive);
					}
				}
				Address SentryDmgActive1 = TF2Attrib_GetByName(melee, "throwable detonation time");
				if(SentryDmgActive1 != Address_Null)
				{
					LightningDamage *= TF2Attrib_GetValue(SentryDmgActive1);
				}
				Address SentryDmgActive2 = TF2Attrib_GetByName(melee, "throwable fire speed");
				if(SentryDmgActive2 != Address_Null)
				{
					LightningDamage *= TF2Attrib_GetValue(SentryDmgActive2);
				}
				Address damageActive = TF2Attrib_GetByName(melee, "ubercharge");
				if(damageActive != Address_Null)
				{
					LightningDamage *= Pow(1.05,TF2Attrib_GetValue(damageActive));
				}
				Address damageActive2 = TF2Attrib_GetByName(melee, "engy sentry damage bonus");
				if(damageActive2 != Address_Null)
				{
					LightningDamage *= TF2Attrib_GetValue(damageActive2);
				}
				Address fireRateActive = TF2Attrib_GetByName(melee, "engy sentry fire rate increased");
				if(fireRateActive != Address_Null)
				{
					LightningDamage /= TF2Attrib_GetValue(fireRateActive);
				}
				
				for(int i = 1; i<MAXENTITIES;i++)
				{
					if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
					{
						float VictimPos[3];
						GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
						VictimPos[2] += 30.0;
						float Distance = GetVectorDistance(clientpos,VictimPos);
						if(Distance <= 1000.0)
						{
							if(IsPointVisible(clientpos,VictimPos))
							{
								SDKHooks_TakeDamage(i,client,client, LightningDamage, 1073741824, -1, NULL_VECTOR, NULL_VECTOR, !IsValidClient3(i));
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
				weaponArtCooldown[client] = 0.55;
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
	if(IsValidEntity(client) && IsValidEntity(weapon))
	{
		float fAngles[3], fOrigin[3], vBuffer[3], fOriginEnd[3], fwd[3], opposite[3], PlayerOrigin[3];
		TracePlayerAimRanged(client, 800.0, fOrigin);
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
		for(int i = 1; i<MAXENTITIES;i++)
		{
			if(IsValidForDamage(i) && IsOnDifferentTeams(client,i))
			{
				float VictimPos[3];
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", VictimPos);
				VictimPos[2] += 30.0;
				float Distance = GetVectorDistance(fOrigin,VictimPos);
				float Range = 500.0;
				if(Distance <= Range)
				{
					if(IsPointVisible(PlayerOrigin,VictimPos))
					{
						CreateParticle(i, "env_sawblood", true, "", 2.0);
						SDKHooks_TakeDamage(i,client,client, mult, DMG_SLASH, weapon, NULL_VECTOR, NULL_VECTOR, !IsValidClient3(i));
					}
				}
			}
		}
		
		fOrigin[0] += opposite[0]
		fOrigin[1] += opposite[1]
		fOrigin[2] += opposite[2]
		
		fOriginEnd[0] -= opposite[0]
		fOriginEnd[1] -= opposite[1]
		fOriginEnd[2] -= opposite[2]

		int color[4];
		color = {255, 0, 0, 255}
		TE_SetupBeamPoints(fOrigin,fOriginEnd,Laser,Laser,0,5,2.5,4.0,8.0,3,1.0,color,10);
		TE_SendToAll();
		
		shouldAttack[client] = true;
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
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
public Action:AttackTwice(Handle timer, any:data) 
{  
	ResetPack(data);
	int client = EntRefToEntIndex(ReadPackCell(data));
	int CWeapon = EntRefToEntIndex(ReadPackCell(data));
	int timesLeft = ReadPackCell(data);
	if(IsValidClient3(client) && IsValidEntity(CWeapon))
	{
		timesLeft--;
		shouldAttack[client] = true;
		SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
		
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
	CloseHandle(data);
}
public Action:SetTankTeleporter(Handle timer, int entity) 
{  
	entity = EntRefToEntIndex(entity)
	if(IsValidEntity(entity))
	{
		TankTeleporter = entity;
	}
}
public Action:ShootTwice(Handle timer, any:data) 
{  
	ResetPack(data);
	int inflictor = EntRefToEntIndex(ReadPackCell(data));
	int client = EntRefToEntIndex(ReadPackCell(data));
	int timesLeft = ReadPackCell(data);
	if(!IsValidClient3(inflictor) && IsValidEntity(inflictor) && HasEntProp(inflictor,Prop_Send,"m_hBuilder") && timesLeft > 0)
	{
		if(IsValidClient3(client))
		{
			int melee = (GetPlayerWeaponSlot(client,2));
			if(IsValidEntity(melee))
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
public Action:HeadshotHomingThink(Handle timer, any:ref) 
{ 
	int entity = EntRefToEntIndex(ref); 
	bool flag = false;
	if(IsValidEntity(entity))
    {
		int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient3(owner))
		{
			int Target = GetClosestTarget(entity, owner); 
			if(IsValidClient3(Target))
			{
				int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					Address homingActive = TF2Attrib_GetByName(CWeapon, "crit from behind");
					if(homingActive != Address_Null)
					{
						float maxDistance = TF2Attrib_GetValue(homingActive)
						if(owner != Target)
						{
							float EntityPos[3], TargetPos[3]; 
							GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityPos ); 
							GetClientAbsOrigin( Target, TargetPos ); 
							float distance = GetVectorDistance( EntityPos, TargetPos ); 
							
							if( distance <= maxDistance )
							{
								float ProjLocation[3], ProjVector[3], BaseSpeed, NewSpeed, ProjAngle[3], AimVector[3], InitialSpeed[3]; 
								
								GetEntPropVector( entity, Prop_Send, "m_vInitialVelocity", InitialSpeed ); 
								if ( GetVectorLength( InitialSpeed ) < 10.0 ) GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", InitialSpeed ); 
								BaseSpeed = GetVectorLength( InitialSpeed ) * 0.3; 
								
								GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", ProjLocation ); 
								GetClientAbsOrigin(Target, TargetPos);
								TargetPos[2]+=20.0;
								MakeVectorFromPoints( ProjLocation, TargetPos, AimVector ); 
								
								//GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", ProjVector ); //50% HOME
								SubtractVectors( TargetPos, ProjLocation, ProjVector ); //100% HOME
								AddVectors( ProjVector, AimVector, ProjVector ); 
								NormalizeVector( ProjVector, ProjVector ); 
								
								GetEntPropVector( entity, Prop_Data, "m_angRotation", ProjAngle ); 
								GetVectorAngles( ProjVector, ProjAngle ); 
								
								NewSpeed = ( BaseSpeed * 2.0 ) + 1.0 * BaseSpeed * 1.1; 
								ScaleVector( ProjVector, NewSpeed ); 
								
								TeleportEntity( entity, NULL_VECTOR, ProjAngle, ProjVector ); 
								SetEntityGravity(entity, 0.001);
							}
						}
					}
					else
					{
						flag = true;
					}
				}
			}
		}
		else{
		flag = true;
		}
    }
	else{
		flag = true;
	}
	if(flag == true){
		KillTimer(timer);
	}
}
public Action:ThrowableHomingThink(Handle timer, any:ref) 
{ 
	int entity = EntRefToEntIndex(ref); 
	bool flag = false;
	if(IsValidEntity(entity))
    {
		int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(!IsValidClient3(owner) && HasEntProp(entity, Prop_Data, "m_hThrower"))
			owner = GetEntPropEnt(entity, Prop_Data, "m_hThrower"); 

		if(IsValidClient3(owner))
		{
			int Target = GetClosestTarget(entity, owner); 
			if(IsValidClient3(Target))
			{
				int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					Address homingActive = TF2Attrib_GetByName(CWeapon, "crit from behind");
					if(homingActive != Address_Null)
					{
						float maxDistance = TF2Attrib_GetValue(homingActive)
						if(owner != Target)
						{
							float EntityPos[3], TargetPos[3]; 
							GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityPos ); 
							GetClientAbsOrigin( Target, TargetPos ); 
							float distance = GetVectorDistance( EntityPos, TargetPos ); 
							
							if( distance <= maxDistance )
							{
								float ProjLocation[3], ProjVector[3], NewSpeed, ProjAngle[3], AimVector[3]; 
								
								
								GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", ProjLocation ); 
								GetClientAbsOrigin( Target, TargetPos ); 
								TargetPos[2] += 40.0; 
								
								MakeVectorFromPoints( ProjLocation, TargetPos, AimVector ); 
								
								//GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", ProjVector ); //50% HOME
								SubtractVectors( TargetPos, ProjLocation, ProjVector ); //100% HOME
								AddVectors( ProjVector, AimVector, ProjVector ); 
								NormalizeVector( ProjVector, ProjVector ); 
								
								GetEntPropVector( entity, Prop_Data, "m_angRotation", ProjAngle ); 
								GetVectorAngles( ProjVector, ProjAngle ); 
								
								NewSpeed = 2000.0; 
								ScaleVector( ProjVector, NewSpeed ); 
								
								TeleportEntity( entity, NULL_VECTOR, ProjAngle, ProjVector ); 
								SetEntityGravity(entity, 0.001);
							}
						}
					}
					else
					{
						flag = true;
					}
				}
			}
		}
		else{
		flag = true;
		}
    }
	else{
		flag = true;
	}
	if(flag == true){
		KillTimer(timer);
	}
}
public Action:Timer_PlayerGrenadeMines(Handle timer, any:ref) 
{
    int entity = EntRefToEntIndex(ref);
	bool flag = false;
	if(IsValidEntity(entity))
	{
		int client = GetEntPropEnt(entity, Prop_Data, "m_hThrower"); 
		if(IsValidClient3(client))
		{
			float distance = GetEntPropFloat(entity, Prop_Send, "m_DmgRadius")
			float damage = GetEntPropFloat(entity, Prop_Send, "m_flDamage")
			float grenadevec[3], targetvec[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", grenadevec);
			for(int i=0; i<=MaxClients; i++)
			{
				if(!IsValidClient3(i)){continue;}
				GetClientAbsOrigin(i, targetvec);
				if(!IsClientObserver(i) && GetClientTeam(i) != GetClientTeam(client) && GetVectorDistance(grenadevec, targetvec, false) < distance)
				{
					if(!TF2Spawn_IsClientInSpawn(i) && client != i && IsAbleToSee(client,i))
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
		if(IsValidEntity(currentWeapon))
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