public MenuHandler_AccessDenied(Handle menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		PrintToChat(client, "This feature is donators/VIPs only")
	}
    if (action == MenuAction_End)
        CloseHandle(menu);
}
public MenuHandler_UpgradeChoice(Handle menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_DisplayItem)
	{
		char desc_str[128];
		char info_str[16];
		int style;
		GetMenuItem(menu, param2, info_str, sizeof(info_str), style, desc_str, sizeof(desc_str));
		int slot = current_slot_used[client]
		int w_id = current_w_list_id[client]
		int cat_id = current_w_c_list_id[client]
		int subcat_id = current_w_sc_list_id[client]
		int upgrade_choice = given_upgrd_list[w_id][cat_id][subcat_id][param2]
		playerUpgradeMenuPage[client] = param2;
		if(upgrades[upgrade_choice].display_style == 0)
			return RedrawMenuItem(desc_str);
		
		switch(upgrades[upgrade_choice].display_style)
		{
			case 1:
			{		
				if(upgrades_efficiency_list[client][slot][upgrade_choice])
					Format(desc_str, sizeof(desc_str), "%s (#%i)", desc_str, upgrades_efficiency_list[client][slot][upgrade_choice]);
			}
			case 6:
			{
				if(upgrades_efficiency_list[client][slot][upgrade_choice])
					Format(desc_str, sizeof(desc_str), "%s (#%i)", desc_str, upgrades_efficiency_list[client][slot][upgrade_choice]);
			}
			case 2:
			{
				if(upgrades_efficiency_list[client][slot][upgrade_choice])
					Format(desc_str, sizeof(desc_str), "%s (#%i)", desc_str, upgrades_efficiency_list[client][slot][upgrade_choice]);
			}
			case 3:
			{
				if(upgrades_efficiency_list[client][slot][upgrade_choice])
					Format(desc_str, sizeof(desc_str), "%s (#%i)", desc_str, upgrades_efficiency_list[client][slot][upgrade_choice]);
			}
		}
		return RedrawMenuItem(desc_str);
		
	}
	else if (action == MenuAction_Select)
	{
		client_respawn_handled[client] = 0
		int slot = current_slot_used[client]
		int w_id = current_w_list_id[client]
		int cat_id = current_w_c_list_id[client]
		int subcat_id = current_w_sc_list_id[client]
		int upgrade_choice = given_upgrd_list[w_id][cat_id][subcat_id][param2]
		int inum = upgrades_ref_to_idx[client][slot][upgrade_choice]
		int rate = getUpgradeRate(client);

		if(canBypassRestriction[client] == false && upgrades[upgrade_choice].requirement > (StartMoney + additionalstartmoney))
		{
			char fstr2[100]
			char fstr[40]
			char fstr3[20]
			if (slot != 4)
			{
				Format(fstr, sizeof(fstr), "%t", given_upgrd_classnames[w_id][cat_id], 
						client)
				Format(fstr3, sizeof(fstr3), "%T", current_slot_name[slot], client)
				Format(fstr2, sizeof(fstr2), "$%.0f [%s] - %s", CurrencyOwned[client], fstr3,
					fstr)
			}
			else
			{
				Format(fstr, sizeof(fstr), "%t", given_upgrd_classnames[_:current_class[client] - 1][cat_id], 
						client)
				Format(fstr3, sizeof(fstr3), "%T", "Body Upgrades", client)
				Format(fstr2, sizeof(fstr2), "$%.0f [%s] - %s", CurrencyOwned[client], fstr3,
					fstr)
			}
			Menu_UpgradeChoice(client, subcat_id, cat_id, fstr2, GetMenuSelectionPosition())
			PrintToChat(client,"The server has not reached this level yet.")
			return param2;
		}
		if(rate == 1)
		{
			if (is_client_got_req(client, upgrade_choice, slot, inum))
			{
				singularBuysPerMinute[client]++;
				UpgradeItem(client, upgrade_choice, inum, 1.0, slot)
				GiveNewUpgradedWeapon_(client, slot)
				
				if(singularBuysPerMinute[client] >= 50)
				{
					singularBuysPerMinute[client] = 0
					PrintToChat(client,"You can use the QBUY system by using /qbuy.\nOr you can CROUCH for 10x purchasing and RELOAD for 100x purchasing.");
					PrintToChat(client,"Downgrading is possible by using JUMP key while upgrading.");
				}
				if(upgrades[upgrade_choice].description[0])
				{
					disableIFMiniHud[client] = currentGameTime+8.0;
					char upgradeDescription[512]
					Format(upgradeDescription, sizeof(upgradeDescription), "%t:\n%s\n", 
					upgrades[upgrade_choice].name,upgrades[upgrade_choice].description);
					ReplaceString(upgradeDescription, sizeof(upgradeDescription), "\\n", "\n");
					ReplaceString(upgradeDescription, sizeof(upgradeDescription), "%", "pct");
					SendItemInfo(client, upgradeDescription);
				}
			}
		}
		else if(rate > 1)
		{
			if (inum == 20000)
			{
				inum = currentupgrades_number[client][slot]
				currentupgrades_number[client][slot]++
				upgrades_ref_to_idx[client][slot][upgrade_choice] = inum;
				currentupgrades_idx[client][slot][inum] = upgrade_choice 
				currentupgrades_val[client][slot][inum] = upgrades[upgrade_choice].i_val;
			}
			int idx_currentupgrades_val
			if(currentupgrades_i[client][slot][inum] != 0.0){
				idx_currentupgrades_val = RoundFloat((currentupgrades_val[client][slot][inum] - currentupgrades_i[client][slot][inum])/ upgrades[upgrade_choice].ratio)
			}
			else{
				idx_currentupgrades_val = RoundFloat((currentupgrades_val[client][slot][inum] - upgrades[upgrade_choice].i_val)/ upgrades[upgrade_choice].ratio)
			}
			float upgrades_val = currentupgrades_val[client][slot][inum];
			float up_cost = float(upgrades[upgrade_choice].cost);
			if (slot == 1)
				up_cost *= SecondaryCostReduction;
			
			if (inum != 20000 && upgrades[upgrade_choice].ratio)
			{
				float t_up_cost = 0.0;
				int times = 0;
				bool notEnough = false;
				for (int idx = 0; idx < rate; idx++)
				{
					float nextcost = t_up_cost + up_cost + up_cost * (idx_currentupgrades_val * upgrades[upgrade_choice].cost_inc_ratio)
					if(nextcost < CurrencyOwned[client] && upgrades[upgrade_choice].ratio > 0.0 && 
					(canBypassRestriction[client] == true || RoundFloat(upgrades_val*100.0)/100.0 < upgrades[upgrade_choice].m_val))
					{
						t_up_cost += up_cost + RoundFloat(up_cost * (idx_currentupgrades_val* upgrades[upgrade_choice].cost_inc_ratio))
						idx_currentupgrades_val++		
						upgrades_val += upgrades[upgrade_choice].ratio
						times++;
					}
					else if(nextcost < CurrencyOwned[client] && upgrades[upgrade_choice].ratio < 0.0 && 
					(canBypassRestriction[client] == true || RoundFloat(upgrades_val*100.0)/100.0 > upgrades[upgrade_choice].m_val))
					{
						t_up_cost += up_cost + RoundFloat(up_cost * (idx_currentupgrades_val * upgrades[upgrade_choice].cost_inc_ratio))
						idx_currentupgrades_val++		
						upgrades_val += upgrades[upgrade_choice].ratio
						times++;
					}
					else if(nextcost > CurrencyOwned[client])
					{
						notEnough = true;
						break;
					}
					else{
						break;
					}
				}
				if(times > 0)
				{
					if(canBypassRestriction[client] == false && upgrades[upgrade_choice].restriction_category != 0)
					{
						for(int i = 1;i<5;i++)
						{
							if(currentupgrades_restriction[client][slot][i] == upgrades[upgrade_choice].restriction_category)
							{
								PrintToChat(client, "You already have something that fits this restriction category.");
								EmitSoundToClient(client, SOUND_FAIL);
								break;
							}
						}
						currentupgrades_restriction[client][slot][upgrades[upgrade_choice].restriction_category] = upgrades[upgrade_choice].restriction_category;
					}
					if(notEnough == true)
					{
						PrintToChat(client, "You didn't have enough money, so you instead bought the most you could.");
					}
					if (t_up_cost < 0.0)
					{
						t_up_cost *= -1;
						if (t_up_cost < upgrades[upgrade_choice].cost)
							t_up_cost = float(upgrades[upgrade_choice].cost);
					}
					CurrencyOwned[client] -= t_up_cost;
					currentupgrades_val[client][slot][inum] = upgrades_val

					if(!canBypassRestriction[client])
						check_apply_maxvalue(client, slot, inum, upgrade_choice)

					client_spent_money[client][slot] += t_up_cost
					GiveNewUpgradedWeapon_(client, slot)
					PrintToChat(client, "You bought %t %i times.",upgrades[upgrade_choice].name,times);

					if(upgrades[upgrade_choice].description[0])
					{
						disableIFMiniHud[client] = currentGameTime+8.0;
						char upgradeDescription[512]
						Format(upgradeDescription, sizeof(upgradeDescription), "%t:\n%s\n", 
						upgrades[upgrade_choice].name,upgrades[upgrade_choice].description);
						ReplaceString(upgradeDescription, sizeof(upgradeDescription), "\\n", "\n");
						ReplaceString(upgradeDescription, sizeof(upgradeDescription), "%", "pct");
						SendItemInfo(client, upgradeDescription);
					}
				}
			}
		}
		else if(rate < 0)
		{
			int yeah = IntAbs(rate);
			if (inum == 20000)
			{
				inum = currentupgrades_number[client][slot]
				currentupgrades_number[client][slot]++
				upgrades_ref_to_idx[client][slot][upgrade_choice] = inum;
				currentupgrades_idx[client][slot][inum] = upgrade_choice 
				currentupgrades_val[client][slot][inum] = upgrades[upgrade_choice].i_val;
			}
			int idx_currentupgrades_val
			if(currentupgrades_i[client][slot][inum] != 0.0){
				idx_currentupgrades_val = RoundFloat((currentupgrades_val[client][slot][inum] - currentupgrades_i[client][slot][inum])/ upgrades[upgrade_choice].ratio)
			}
			else{
				idx_currentupgrades_val = RoundFloat((currentupgrades_val[client][slot][inum] - upgrades[upgrade_choice].i_val)/ upgrades[upgrade_choice].ratio)
			}
			if(idx_currentupgrades_val > 0)
			{
				float upgrades_val = currentupgrades_val[client][slot][inum];
				float up_cost = float(upgrades[upgrade_choice].cost);
				if (slot == 1)
					up_cost *= SecondaryCostReduction;
			
				if (inum != 20000 && upgrades[upgrade_choice].ratio)
				{
					float t_up_cost = 0.0;
					int times = 0;
					if(upgrades_val == upgrades[upgrade_choice].m_val)
					{
						idx_currentupgrades_val--
						float temp = currentupgrades_i[client][slot][inum] != 0.0 ? currentupgrades_i[client][slot][inum] : upgrades[upgrade_choice].i_val;
						t_up_cost -= up_cost + RoundFloat(up_cost * (idx_currentupgrades_val* upgrades[upgrade_choice].cost_inc_ratio));
						upgrades_val = temp+(idx_currentupgrades_val * upgrades[upgrade_choice].ratio);
						times++;
					}
					for (;times < yeah;)
					{
						if(idx_currentupgrades_val > 0 && upgrades[upgrade_choice].ratio > 0.0 && 
						(canBypassRestriction[client] == true || (RoundFloat(upgrades_val*100.0)/100.0 <= upgrades[upgrade_choice].m_val
						&& client_spent_money[client][slot] + t_up_cost > client_tweak_highest_requirement[client][slot] - 1.0)))
						{
							idx_currentupgrades_val--
							t_up_cost -= up_cost + RoundFloat(up_cost * (idx_currentupgrades_val* upgrades[upgrade_choice].cost_inc_ratio))		
							upgrades_val -= upgrades[upgrade_choice].ratio
						}
						else if(idx_currentupgrades_val > 0 && upgrades[upgrade_choice].ratio < 0.0 && 
						(canBypassRestriction[client] == true || (RoundFloat(upgrades_val*100.0)/100.0 >= upgrades[upgrade_choice].m_val
						&& client_spent_money[client][slot] + t_up_cost > client_tweak_highest_requirement[client][slot] - 1.0)))
						{
							idx_currentupgrades_val--
							t_up_cost -= up_cost + RoundFloat(up_cost * (idx_currentupgrades_val * upgrades[upgrade_choice].cost_inc_ratio))	
							upgrades_val -= upgrades[upgrade_choice].ratio
						}
						else{
							break;
						}
						times++;
					}
					if(times > 0)
					{
						CurrencyOwned[client] -= t_up_cost;
						currentupgrades_val[client][slot][inum] = upgrades_val
						if(!canBypassRestriction[client])
							check_apply_maxvalue(client, slot, inum, upgrade_choice)
						client_spent_money[client][slot] += t_up_cost
						GiveNewUpgradedWeapon_(client, slot)
						PrintToChat(client, "You downgraded %t %i times.",upgrades[upgrade_choice].name,times);
					}
					if(idx_currentupgrades_val == 0)
						remove_attribute(client,inum);
				}
			}
		}
		char fstr2[100];
		getUpgradeMenuTitle(client, w_id, cat_id, slot, fstr2);
		Menu_UpgradeChoice(client, subcat_id, cat_id, fstr2, GetMenuSelectionPosition())
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		if(given_upgrd_subcat_nb[current_w_list_id[client]][current_w_c_list_id[client]] > 0)
		{
			if (current_slot_used[client] == 4)
			{
				char fstr[30]
				char fstr2[128]
				Format(fstr, sizeof(fstr), "%T", "Body Upgrades", client)
				Format(fstr2, sizeof(fstr2), "$%.0f [ - %s - ]", CurrencyOwned[client], fstr)
				Menu_ChooseSubcat(client, current_w_c_list_id[client], fstr2)
			}
			else
			{
				char fstr[30]
				char fstr2[128]
				Format(fstr, sizeof(fstr), "%T", current_slot_name[current_slot_used[client]], client)
				Format(fstr2, sizeof(fstr2), "$%.0f [ - Upgrade %s - ]", CurrencyOwned[client]
																,fstr)
				Menu_ChooseSubcat(client, current_w_c_list_id[client], fstr2)
			}
		}
		else
		{
			if (current_slot_used[client] == 4)
			{
				char fstr[30]
				char fstr2[128]
				Format(fstr, sizeof(fstr), "%T", "Body Upgrades", client)
				Format(fstr2, sizeof(fstr2), "$%.0f [ - %s - ]", CurrencyOwned[client], fstr)
				Menu_ChooseCategory(client, fstr2)
			}
			else
			{
				char fstr[30]
				char fstr2[128]
				Format(fstr, sizeof(fstr), "%T", current_slot_name[current_slot_used[client]], client)
				Format(fstr2, sizeof(fstr2), "$%.0f [ - Upgrade %s - ]", CurrencyOwned[client]
																,fstr)
				Menu_ChooseCategory(client, fstr2)
			}
		}
	}
    if (action == MenuAction_End)
	{
        CloseHandle(menu);
	}
	return 0;
}


public MenuHandler_SpeMenubuy(Handle menu, MenuAction:action, client, param2)
{
	CloseHandle(menu);
	return; 
}
public MenuHandler_ChooseSubcat(Handle menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		char fstr2[100]
		char fstr[40]
		char fstr3[20]
		int slot = current_slot_used[client]
		int cat_id = current_w_sc_list_id[client];
		int w_id = current_w_list_id[client]
		if (slot != 4)
		{
			Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[w_id][cat_id], client)
			Format(fstr3, sizeof(fstr3), "%T", current_slot_name[slot], client)
			Format(fstr2, sizeof(fstr2), "$%.0f [%s] - %s", CurrencyOwned[client],fstr3,fstr)
			Menu_UpgradeChoice(client, param2, cat_id, fstr2)
		}
		else
		{
			Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[w_id][cat_id], client)
			Format(fstr3, sizeof(fstr3), "%T", "Body Upgrades", client)
			Format(fstr2, sizeof(fstr2), "$%.0f [%s] - %s", CurrencyOwned[client], fstr3, fstr)
			Menu_UpgradeChoice(client, param2, cat_id, fstr2)
		}
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack){
		if(current_slot_used[client] == 4)
		{
			char fstr[30]
			char fstr2[128]
			Format(fstr, sizeof(fstr), "%T", "Body Upgrades", client)
			Format(fstr2, sizeof(fstr2), "$%.0f [ - %s - ]", CurrencyOwned[client], fstr)
			Menu_ChooseCategory(client, fstr2)
		}
		else
		{
			char fstr[30]
			char fstr2[128]
			Format(fstr, sizeof(fstr), "%T", current_slot_used[client], client)
			Format(fstr2, sizeof(fstr2), "$%.0f [ - Upgrade %s - ]", CurrencyOwned[client]
																,fstr)
			Menu_ChooseCategory(client, fstr2)
		}
	}
    if (action == MenuAction_End)
        CloseHandle(menu);
	return; 
}
public MenuHandler_Choosecat(Handle menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		char fstr2[100]
		char fstr[40]
		char fstr3[20]
		int slot = current_slot_used[client]
		int cat_id = currentitem_catidx[client][slot]
		if (slot != 4)
		{
			Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[cat_id][param2], client)
			Format(fstr3, sizeof(fstr3), "%T", current_slot_name[slot], client)
			Format(fstr2, sizeof(fstr2), "$%.0f [%s] - %s", CurrencyOwned[client],fstr3,fstr)
			if(given_upgrd_subcat[cat_id][param2] > 0)
			{
				Menu_ChooseSubcat(client, param2, fstr2)
			}
			else
			{
				if (param2 == given_upgrd_classnames_tweak_idx[cat_id])
				{
					Menu_SpecialUpgradeChoice(client, param2, fstr2,0)
				}
				else
				{
					Menu_UpgradeChoice(client, 0, param2, fstr2)
				}
			}
		}
		else
		{
			Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[cat_id][param2], client)
			Format(fstr3, sizeof(fstr3), "%T", "Body Upgrades", client)
			Format(fstr2, sizeof(fstr2), "$%.0f [%s] - %s", CurrencyOwned[client], fstr3, fstr)
			if(given_upgrd_subcat[cat_id][param2] > 0)
			{
				Menu_ChooseSubcat(client, param2, fstr2)
			}
			else
			{
				if (param2 == given_upgrd_classnames_tweak_idx[cat_id])
				{
					Menu_SpecialUpgradeChoice(client, param2, fstr2,0)
				}
				else
				{
					Menu_UpgradeChoice(client, 0, param2, fstr2)
				}
			}
			/*if(AreClientCookiesCached(client))
			{
				if(param2 == 0)
				{
					char TutorialString[32];
					GetClientCookie(client, ArmorTutorial, TutorialString, sizeof(TutorialString));
					if(!strcmp("0", TutorialString))
					{
						SetClientCookie(client, ArmorTutorial, "1"); 
						
						char TutorialText[256]
						Format(TutorialText, sizeof(TutorialText), " | Tutorial | \nArmor is exponential in power.\nDamage Reduction is a to the power of 2.35 reduction.\nDamage Reduction Multiplier multiplies the calculated Damage Reduction."); 
						SetHudTextParams(-1.0, -1.0, 15.0, 252, 161, 3, 255, 0, 0.0, 0.0, 0.0);
						ShowHudText(client, 10, TutorialText);
						CPrintToChat(client, "{valve}Tutorial {white}| Armor is exponential in power.\nDamage Reduction is a to the power of 2.35 reduction.\nDamage Reduction Multiplier multiplies the calculated Damage Reduction.");
					}
				}
				else if(param2 == 3)
				{
					char TutorialString[32];
					GetClientCookie(client, ArcaneTutorial, TutorialString, sizeof(TutorialString));
					if(!strcmp("0", TutorialString))
					{
						SetClientCookie(client, ArcaneTutorial, "1"); 
						
						char TutorialText[256]
						Format(TutorialText, sizeof(TutorialText), " | Tutorial | \nArcane Damage boosts damage exponentially.\nArcane Power increases all stats & boosts Arcane Damage to the power of 4.\nArcane spells can be used at the front of the buy menu."); 
						SetHudTextParams(-1.0, -1.0, 15.0, 252, 161, 3, 255, 0, 0.0, 0.0, 0.0);
						ShowHudText(client, 10, TutorialText);
						CPrintToChat(client, "{valve}Tutorial {white}| Arcane Damage boosts damage exponentially.\nArcane Power increases all stats & boosts Arcane Damage to the power of 4.\nArcane spells can be used at the front of the buy menu.");
					}
				}
			}*/
		}
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack){
		Menu_BuyUpgrade(client, 0);
	}
    if (action == MenuAction_End)
        CloseHandle(menu);
	return; 
}


public MenuHandler_BuyUpgrade(Handle menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:
			{//Buy body upgrades.
				char fstr[30]
				char fstr2[128]
				current_slot_used[client] = 4;
				Format(fstr, sizeof(fstr), "%T", "Body Upgrades", client)
				Format(fstr2, sizeof(fstr2), "$%.0f [ - %s - ]", CurrencyOwned[client], fstr)
				Menu_ChooseCategory(client, fstr2)
			}
			case 4:
			{//Upgrade Manager
				Menu_TweakUpgrades(client);
			}
			case 5:
			{//Show stats
				Menu_ShowStats(client);
			}
			case 6:
			{//Use arcane
				Menu_ShowArcane(client);
			}
			case 7:
			{//Upgrade / buy int weapon.
				if(currentitem_level[client][3] != 242)
				{
					Menu_BuyNewWeapon(client);
				}
				else
				{
					char fstr[30]
					char fstr2[128]
					current_slot_used[client] = 3
					Format(fstr, sizeof(fstr), "%T", current_slot_name[3], client)
					Format(fstr2, sizeof(fstr2), "$%.0f [ - Upgrade %s - ]", CurrencyOwned[client]
																	  ,fstr)
					Menu_ChooseCategory(client, fstr2)
				}
			}
			case 8:
			{//Change preferences menu
				Menu_ChangePreferences(client);
			}
			case 9:
			{//Show wiki
				Menu_ShowWiki(client);
			}
			default:
			{
				char fstr[30]
				char fstr2[128]
				param2 -= 1
				current_slot_used[client] = param2
				Format(fstr, sizeof(fstr), "%T", current_slot_name[param2], client)
				Format(fstr2, sizeof(fstr2), "$%.0f [ - Upgrade %s - ]", CurrencyOwned[client]
																  ,fstr)
				Menu_ChooseCategory(client, fstr2)
				/*if(AreClientCookiesCached(client))
				{
					char TutorialString[32];
					GetClientCookie(client, WeaponTutorial, TutorialString, sizeof(TutorialString));
					if(!strcmp("0", TutorialString))
					{
						SetClientCookie(client, WeaponTutorial, "1"); 

						char TutorialText[512]
						Format(TutorialText, sizeof(TutorialText), " | Tutorial | \nDamage upgrades will show many different damage multipliers.\nThey all stack multiplicatively.\nExponential Damage Bonus is a damage bonus to the power of 5."); 
						SetHudTextParams(-1.0, -1.0, 15.0, 252, 161, 3, 255, 0, 0.0, 0.0, 0.0);
						ShowHudText(client, 10, TutorialText);
					}
				}*/
			}
		}
	}
    if (action == MenuAction_End)
        CloseHandle(menu);
}
public MenuHandler_ConfirmNewWeapon(Handle menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		param2 = buyableIndexOffParam[client][param2]
		if (CurrencyOwned[client] >= upgrades_weapon_cost[param2] && client_spent_money[client][3] == 0.0 && currentitem_level[client][3] != 242)
		{
			Menu_ConfirmWeapon(client,param2)
			upgrades_weapon_lookingat[client] = param2
		}
		else
		{
			PrintToChat(client, "You don't have enough money or you already a weapon in slot 3.");
			EmitSoundToClient(client, SOUND_FAIL);
		}
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack){
		Menu_BuyUpgrade(client, 7);
	}
	if(action == MenuAction_End)
		CloseHandle(menu);
}

public MenuHandler_BuyNewWeapon(Handle menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		int selection = upgrades_weapon_lookingat[client];
		upgrades_weapon_lookingat[client] = -1
		if (CurrencyOwned[client] >= upgrades_weapon_cost[selection] && client_spent_money[client][3] == 0.0 && currentitem_level[client][3] != 242)
		{
			PrintToChat(client, "Weapon Bought! Reload the buy menu to upgrade it.\nUse the SPRAY key to switch to it! Default key is 'T' and the command is 'impulse 201'.");
			currentitem_idx[client][3] = upgrades_weapon_index[selection];
			currentitem_classname[client][3] = upgrades_weapon_class[selection];
			CurrencyOwned[client] -= upgrades_weapon_cost[selection];
			client_spent_money[client][3] = upgrades_weapon_cost[selection];
			upgrades_weapon_current[client] = selection;
			CreateTimer(0.1, Timer_giveactionslot, EntIndexToEntRef(client));
		}
		else
		{
			PrintToChat(client, "You don't have enough money or you already a weapon in slot 3.");
			EmitSoundToClient(client, SOUND_FAIL);
		}
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack){
		CreateBuyNewWeaponMenu(client)
	}
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public MenuHandler_AttributesTweak(Handle menu, MenuAction:action, client, param2)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !client_respawn_checkpoint[client])
	{
		Menu_TweakUpgrades_slot(client, param2, 0)
	}
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_BuyUpgrade(client, 0);
	}
    if (action == MenuAction_End)
        CloseHandle(menu);
	return; 
}
public MenuHandler_AttributesTweak_action(Handle menu, MenuAction:action, client, param2)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !client_respawn_checkpoint[client])
	{
		int s = current_slot_used[client];
		if (s >= 0 && s < 5 && param2 < MAX_ATTRIBUTES_ITEM)
		{
			if (param2 >= 0)
			{
				int u = currentupgrades_idx[client][s][param2]
				if (u != 20000)
				{
					if(upgrades[u].cost < -0.1)
					{
						int nb_time_upgraded = RoundToNearest((upgrades[u].i_val - currentupgrades_val[client][s][param2]) / upgrades[u].ratio)
						float up_cost = float(upgrades[u].cost * nb_time_upgraded);
						if(up_cost > 200.0)
						{
							if (CurrencyOwned[client] >= up_cost)
							{
								remove_attribute(client, param2);
								CurrencyOwned[client] -= up_cost;
								client_spent_money[client][s] += up_cost;
							}
							else
							{
								PrintToChat(client, "You don't have enough money.");
								EmitSoundToClient(client, SOUND_FAIL);
							}
						}
					}
					if (upgrades[u].cost > 1.0)
					{
						int nb_time_upgraded;
						if(currentupgrades_i[client][s][param2] != 0.0)
						{
							nb_time_upgraded = RoundToNearest((currentupgrades_i[client][s][param2] - currentupgrades_val[client][s][param2]) / upgrades[u].ratio)
						}
						else
						{
							nb_time_upgraded = RoundToNearest((upgrades[u].i_val - currentupgrades_val[client][s][param2]) / upgrades[u].ratio)
						}
						nb_time_upgraded *= -1
						float up_cost = ((upgrades[u].cost+((upgrades[u].cost_inc_ratio*upgrades[u].cost)*(nb_time_upgraded-1))/2)*nb_time_upgraded)
						if(s == 1)
							up_cost *= SecondaryCostReduction;
							
						if(up_cost > 200.0)
						{
							if(canBypassRestriction[client] || client_spent_money[client][s] - up_cost > client_tweak_highest_requirement[client][s] - 1.0)
							{
								remove_attribute(client, param2)
								CurrencyOwned[client] += up_cost;
								client_spent_money[client][s] -= up_cost
								PrintToChat(client, "Attribute refunded.")
							}
							else
							{
								PrintToChat(client, "You cannot go below money spent of tweaks bought that have requirements. Highest Requirement is %.0f", client_tweak_highest_requirement[client][s]);
								EmitSoundToClient(client, SOUND_FAIL);
							}
						}
					}
					Menu_TweakUpgrades_slot(client, s, GetMenuSelectionPosition())
				}
			}
		}
	}
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_TweakUpgrades(client);
	}
	if(action == MenuAction_End)
		CloseHandle(menu);
}
public MenuHandler_SpecialUpgradeChoice(Handle menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		client_respawn_handled[client] = 0
		char fstr[100]
		int got_req = 1
		int slot = current_slot_used[client]
		int w_id = current_w_list_id[client]
		int cat_id = current_w_c_list_id[client]
		int spTweak = given_upgrd_list[w_id][cat_id][0][param2]

		if(!canBypassRestriction[client]){
			for(int k = 0;k < 5;k++){
				if(currentupgrades_restriction[client][slot][k] == 0)
					continue;

				if(currentupgrades_restriction[client][slot][k] == tweaks[spTweak].restriction){
					PrintToChat(client, "You already have a restricted upgrade for this tweak.");
					EmitSoundToClient(client, SOUND_FAIL);
					got_req = 0;
					break;
				}
			}

			if(tweaks[spTweak].requirement > client_spent_money[client][slot])
			{
				PrintToChat(client, "You must spend more on the slot to use this tweak.");
				EmitSoundToClient(client, SOUND_FAIL);
				got_req = 0;
			}
			if(tweaks[spTweak].gamestage_requirement > gameStage)
			{
				PrintToChat(client, "You must reach the required game stage.");
				EmitSoundToClient(client, SOUND_FAIL);
				got_req = 0;
			}
			if(tweaks[spTweak].cost > CurrencyOwned[client])
			{
				PrintToChat(client, "You don't have enough money for this tweak.");
				EmitSoundToClient(client, SOUND_FAIL);
				got_req = 0;
			}
		}
		for (int i = 0; i < tweaks[spTweak].nb_att && got_req == 1; i++)
		{
			int upgrade_choice = tweaks[spTweak].att_idx[i]
			int inum = upgrades_ref_to_idx[client][slot][upgrade_choice]

			if(canBypassRestriction[client])
				break;

			if (inum != 20000)
			{
				if (currentupgrades_val[client][slot][inum] == upgrades[upgrade_choice].m_val)
				{
					PrintToChat(client, "You already have reached the maximum upgrade for this tweak.");
					EmitSoundToClient(client, SOUND_FAIL);
					got_req = 0
					break;
				}
			}
			else
			{
				if (currentupgrades_number[client][slot] + tweaks[spTweak].nb_att >= MAX_ATTRIBUTES_ITEM)
				{
					PrintToChat(client, "You have not enough upgrade category slots for this tweak.");
					EmitSoundToClient(client, SOUND_FAIL);
					got_req = 0
					break;
				}
			}
		}
		if (got_req)
		{
			if(tweaks[spTweak].requirement > 1.0 && client_tweak_highest_requirement[client][slot] < tweaks[spTweak].requirement)
			{
				client_tweak_highest_requirement[client][slot] = tweaks[spTweak].requirement;
			}
			if(tweaks[spTweak].restriction != 0)
			{
				currentupgrades_restriction[client][slot][tweaks[spTweak].restriction] = tweaks[spTweak].restriction;
			}
			char clname[255]
			GetClientName(client, clname, sizeof(clname))
			for (int i = 1; i < MaxClients; i++)
			{
				if (IsValidClient(i) && !client_no_d_team_upgrade[i])
				{
					PrintToChat(i,"%s : [%s tweak] - %s!", 
					clname, tweaks[spTweak].tweaks, current_slot_name[slot]);
				}
			}
			for (int i = 0; i < tweaks[spTweak].nb_att; i++)
			{
				int upgrade_choice = tweaks[spTweak].att_idx[i]
				UpgradeItem(client, upgrade_choice, upgrades_ref_to_idx[client][slot][upgrade_choice], tweaks[spTweak].att_ratio[i], slot)
			}
			GiveNewUpgradedWeapon_(client, slot)
			client_spent_money[client][slot] += tweaks[spTweak].cost;
			if(!canBypassRestriction[client])
				CurrencyOwned[client] -= tweaks[spTweak].cost;
		}
		char buf[128]
		Format(buf, sizeof(buf), "%T", current_slot_name[slot], client);
		Format(fstr, sizeof(fstr), "$%.0f [%s] - %s", CurrencyOwned[client], buf, 
				given_upgrd_classnames[w_id][cat_id])
		Menu_SpecialUpgradeChoice(client, cat_id, fstr, GetMenuSelectionPosition())
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack){
		if (current_slot_used[client] == 4)
		{
			char fstr[30]
			char fstr2[128]
			Format(fstr, sizeof(fstr), "%T", "Body Upgrades", client)
			Format(fstr2, sizeof(fstr2), "$%.0f [ - %s - ]", CurrencyOwned[client], fstr)
			Menu_ChooseCategory(client, fstr2)
			
		}
		else
		{
			char fstr[30]
			char fstr2[128]
			Format(fstr, sizeof(fstr), "%T", current_slot_name[current_slot_used[client]], client)
			Format(fstr2, sizeof(fstr2), "$%.0f [ - Upgrade %s - ]", CurrencyOwned[client]
															  ,fstr)
			Menu_ChooseCategory(client, fstr2)
		}
	}
    if (action == MenuAction_End)
        CloseHandle(menu);
}
public MenuHandler_Preferences(Handle menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		Menu_ChangePreferences(client);
		if(param2 >= 0 && AreClientCookiesCached(client))
		{
			switch(param2)
			{
				case 0:
				{
					char XPos[64];
					GetClientCookie(client, hArmorXPos, XPos, sizeof(XPos));
					float XPosNum = StringToFloat(XPos);
					FloatToString(XPosNum + 0.01, XPos, sizeof(XPos));
					SetClientCookie(client, hArmorXPos, XPos);
					PrintHintText(client, "new XPos = %s", XPos);
				}
				case 1:
				{
					char XPos[64];
					GetClientCookie(client, hArmorXPos, XPos, sizeof(XPos));
					float XPosNum = StringToFloat(XPos);
					FloatToString(XPosNum - 0.01, XPos, sizeof(XPos));
					SetClientCookie(client, hArmorXPos, XPos);
					PrintHintText(client, "new XPos = %s", XPos);
				}
				case 2:
				{
					char YPos[64];
					GetClientCookie(client, hArmorYPos, YPos, sizeof(YPos));
					float YPosNum = StringToFloat(YPos);
					FloatToString(YPosNum + 0.01, YPos, sizeof(YPos));
					SetClientCookie(client, hArmorYPos, YPos);
					PrintHintText(client, "new YPos = %s", YPos);
				}
				case 3:
				{
					char YPos[64];
					GetClientCookie(client, hArmorYPos, YPos, sizeof(YPos));
					float YPosNum = StringToFloat(YPos);
					FloatToString(YPosNum - 0.01, YPos, sizeof(YPos));
					SetClientCookie(client, hArmorYPos, YPos);
					PrintHintText(client, "new YPos = %s", YPos);
				}
				case 4:
				{
					char menuEnabled[64];
					GetClientCookie(client, respawnMenu, menuEnabled, sizeof(menuEnabled));
					float menuValue = StringToFloat(menuEnabled);
					if(menuValue == 1.0){
						SetClientCookie(client, respawnMenu, "0");
						PrintHintText(client, "Respawn menu is now enabled.");
					}else{
						SetClientCookie(client, respawnMenu, "1");
						PrintHintText(client, "Respawn menu is now disabled.");
					}
				}
				case 5:
				{
					char particleToggleEnabled[64];
					GetClientCookie(client, particleToggle, particleToggleEnabled, sizeof(particleToggleEnabled));
					float particleToggleValue = StringToFloat(particleToggleEnabled);
					
					if(particleToggleValue == 0.0){
						SetClientCookie(client, particleToggle, "1");
						PrintHintText(client, "Self-Viewable Particles is now enabled.");
					}else{
						SetClientCookie(client, particleToggle, "0");
						PrintHintText(client, "Self-Viewable Particles is now disabled.");
					}
				}
				case 6:
				{
					Menu_ChangeKnockbackPreferences(client);
				}
				case 7:
				{
					SetClientCookie(client, EngineerTutorial, "0");
					SetClientCookie(client, ArmorTutorial, "0");
					SetClientCookie(client, ArcaneTutorial, "0");
					SetClientCookie(client, WeaponTutorial, "0");
					PrintHintText(client, "Reset all tutorial HUD messages.");
				}
				default:
				{
					PrintHintText(client, "Sorry, we havent implemented this yet!");
				}
			}
		}
	}
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
		Menu_BuyUpgrade(client, 7);
	
    if (action == MenuAction_End)
        CloseHandle(menu);
	return; 
}
public MenuHandler_KnockbackPreferences(Handle menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		char knockbackToggleEnabled[64];
		GetClientCookie(client, knockbackToggle, knockbackToggleEnabled, sizeof(knockbackToggleEnabled));
		int knockbackToggleValue = StringToInt(knockbackToggleEnabled);
		if(param2 >= 0 && AreClientCookiesCached(client))
		{
			knockbackToggleValue ^= 1<<param2;
			IntToString(knockbackToggleValue, knockbackToggleEnabled, sizeof(knockbackToggleEnabled));
			SetClientCookie(client, knockbackToggle, knockbackToggleEnabled);
			knockbackFlags[client] = knockbackToggleValue;
		}
		Menu_ChangeKnockbackPreferences(client);
	}
	else if(action == MenuAction_DisplayItem)
	{
		char knockbackToggleEnabled[64];
		GetClientCookie(client, knockbackToggle, knockbackToggleEnabled, sizeof(knockbackToggleEnabled));
		int knockbackToggleValue = StringToInt(knockbackToggleEnabled);
		char desc_str[128];
		char info_str[16];
		int style;
		GetMenuItem(menu, param2, info_str, sizeof(info_str), style, desc_str, sizeof(desc_str));
		char toggleSwitch[16] = "Disabled";
		if(knockbackToggleValue & 1 << param2)
			toggleSwitch = "Enabled";

		Format(desc_str, sizeof(desc_str), "%s%s", desc_str, toggleSwitch);
		return RedrawMenuItem(desc_str);
	}
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
		Menu_ChangePreferences(client);
	
    if (action == MenuAction_End)
        {CloseHandle(menu);}
}
public MenuHandler_Wiki(Handle menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select && IsValidClient(client) && IsPlayerAlive(client))
	{
		if(param2 >= 0 && MenuTimer[client] < currentGameTime)
		{
			MenuTimer[client] = 1.0+currentGameTime
			switch(param2)
			{
				case 0:
				{
					CPrintToChat(client, " ");
					CPrintToChat(client, "{valve}Wiki {white}| Upgrades in Incremental Fortress have a base cost, increase ratio, value, initial value & max.\n You can buy these upgrades with the console command 'menuselect' or 'qbuy'.");
					CPrintToChat(client, "{valve}Wiki {white}| Using menuselect means to choose whatever selection by console. qbuy is to bulk buy an upgrade or tweak. It follows the same style as menuselect, for example : qbuy 1 1 1 100 would buy health 100 times.");
					CPrintToChat(client, "{valve}Wiki {white}| ★ Damage Multiplier ★ upgrades do not increase in cost. ");
					CPrintToChat(client, " ");
				}
				case 1:
				{
					CPrintToChat(client, " ");
					CPrintToChat(client, "{valve}Wiki {white}| Damage upgrades are all multiplicative with each other.");
					CPrintToChat(client, "{valve}Wiki {white}| 'Exponential damage boost' is their effect to the power of 5. ie : +70%% exponential damage boost would be equal to 14.2 times damage.");
					CPrintToChat(client, "{valve}Wiki {white}| 'Life Steal Ability' takes the post-damage dealt of an attack, then divides it by 10, then multiplies is by the attribute's value, and returns it as healing.");
					CPrintToChat(client, "{valve}Wiki {white}| Many attributes are meant to scale universally regardless of weapon changes. For example, bullets per shot increases damage of rocket weapons as well.");
					CPrintToChat(client, " ");
				}
				case 2:
				{
					CPrintToChat(client, " ");
					CPrintToChat(client, "{valve}Wiki {white}| The armor calculation is an exponential divisor to damage taken.");
					CPrintToChat(client, "{valve}Wiki {white}| The divisor formula without armor percentage taken into account is | damage = damage/(DamageReduction*DamageReductionMultiplier)^2.35");
					CPrintToChat(client, "{valve}Wiki {white}| This effect however, is modified to scale with how much armor supply you have VS your maximum armor supply. This effect is capped to a 99%% reduction.");
					CPrintToChat(client, " ");
				}
				case 3:
				{
					CPrintToChat(client, " ");
					CPrintToChat(client, "{valve}Wiki {white}| Special Tweaks are sidegrades to weapons. Some of them have removable downgrades such as 'Fast Shot', but mostly they cannot be removed due to their extremely strong effects.");
					CPrintToChat(client, "{valve}Wiki {white}| By going to the 'Upgrade Manager' on the front page of the menu, you can remove the downgrades or remove any upgrades you need to refund.");
					CPrintToChat(client, "{valve}Wiki {white}| Special Tweaks can have requirements and costs. If the tweak has a requirement, you cannot refund your weapon below that spent cost. Generally those are buffs as well.");
					CPrintToChat(client, " ");
				}
				case 4:
				{
					CPrintToChat(client, " ");
					CPrintToChat(client, "{valve}Wiki {white}| Special Abilities are triggered by using the middle click button. Very few weapons have special abilities.");
					CPrintToChat(client, "{valve}Wiki {white}| Stun Shot is the shotgun's ability. Gives an additonal 3x bullets per shot, and freezes your weapon for .3s. Your shot will inflict 0.6s of stun.");
					CPrintToChat(client, "{valve}Wiki {white}| Explosive shot is the Fortified Compound's ability. Your next shot will deal a 120 base damage explosion.");
					CPrintToChat(client, "{valve}Wiki {white}| Detonate is the Huo-Long-Heater's ability. It detonates all of the flares that are active, just like the detonator. Cannot inflict damage to self.");
					CPrintToChat(client, "{valve}Wiki {white}| Adrenaline is the ability for melees. Massively increases dodge chance for 2.5s and gives minicrits for 5s. Clears all effects.");
					CPrintToChat(client, " ");
				}
				case 5:
				{
					CPrintToChat(client, " ");
					CPrintToChat(client, "{valve}Wiki {white}| Dragon's Breath is the ability for the Dragon's Fury. Shoots 5 high gravity bouncing fireballs that deal 35 base DPS.");
					CPrintToChat(client, "{valve}Wiki {white}| Dash is the ability for The Winger, it re-directs your movement up to 3x of it's base max. Vertical velocity is decreased by -25%%.");
					CPrintToChat(client, " ");
				}
				case 6:
				{
					CPrintToChat(client, " ");
					CPrintToChat(client, "{valve}Wiki {white}| Arcane are spells that are triggered through the 'Use Arcane Spells' category. They have exponential scaling which allows them to compete with weapons and armor upgrades. ");
					CPrintToChat(client, "{valve}Wiki {white}| ie : Zap has a formula of '(20.0 + ((ArcaneDamage * (ArcanePower^4.0))^2.45) * 3.0))'. Zap can also chain-trigger the effect with a 30%% chance.");
					CPrintToChat(client, "{valve}Wiki {white}| All arcanes follow the formula to this, except the base damage and scaling change, which is the '20.0' and the '3.0' in the zap formula respectively.");
					CPrintToChat(client, "{valve}Wiki {white}| Arcane Power exponentially increases your Arcane Damage total, increases regeneration, max focus, decreases cooldowns, and buff durations.");
					CPrintToChat(client, "{valve}Wiki {white}| You can add key bindings for arcane usage by using 'sm_arcane #'. ie: 'sm_arcane 2' will use your second arcane spell attuned.");
					CPrintToChat(client, " ");
				}
				case 7:
				{
					CPrintToChat(client, " ");
					CPrintToChat(client, "{valve}Wiki {white}| Zap has a formula of 20 base, 3 scaling. Zap can also chain-trigger the effect with a 30%% chance. CD is 0.1s.");
					CPrintToChat(client, "{valve}Wiki {white}| Lightning Strike has a formula of 200 base, 80 scaling. It will apply a DOT that deals 2%% of it's main damage, but 20 times over 2 seconds. CD is 11s.");
					CPrintToChat(client, "{valve}Wiki {white}| Projected Healing heals for 20%% of the caster's max HP with overheal. 135%% of that healing is also turned into healing armor. It applies an additional boost to armor recharge for 3 seconds. CD is 15s.");
					CPrintToChat(client, "{valve}Wiki {white}| A Call Beyond shoots 25 explosive homing bolts that deal 90 base, 120 scaling damage each. Cast time is 1.5s. CD is 50s.");
					CPrintToChat(client, "{valve}Wiki {white}| Blacksky Eye shoots an explosive homing bolt that deals 10 base, 7.5 scaling damage each. CD is 0.3s.");
					CPrintToChat(client, " ");
				}
				case 8:
				{
					CPrintToChat(client, " ");
					CPrintToChat(client, "{valve}Wiki {white}| Sunlight spear is a fast arrow-style projectile that deals 100 base and 40 scaling. CD is 0.4s.");
					CPrintToChat(client, "{valve}Wiki {white}| Lightning Enchantment deals 10 base, 4 scaling. However, this is multiplied by 20 and then divided by the fire rate of the weapon proportional to dps boost. (always same DPS). CD is 30s, lasts 20s.");
					CPrintToChat(client, "{valve}Wiki {white}| Darkmoon Blade deals 10 base, 3.5 scaling. This is applied to only melee attacks. CD is 25s, lasts 20s.");
					CPrintToChat(client, "{valve}Wiki {white}| Snap Freeze deals 100 base, 60 scaling within a 500HU radius of you. Stuns targets for 0.4s. Also massively increases your dodge chance for 0.4s. CD is 9s.");
					CPrintToChat(client, "{valve}Wiki {white}| Arcane Prison binds targets together and deals 10 base, 5 scaling each tick of damage. Also increases the radiation meter on targets. CD is 20s.");
					CPrintToChat(client, " ");
				}
				case 9:
				{
					CPrintToChat(client, " ");
					CPrintToChat(client, "{valve}Wiki {white}| Scout | Speed Aura | Gives a speed bonus and the agility rune effects for 8s. Also gives massively increased dodge chance for 1.5s. CD is 35s.");
					CPrintToChat(client, "{valve}Wiki {white}| Soldier | Aerial Strike | Summons 30 rockets in an array that deal 90 base and 25 scaling. CD is 60s.");
					CPrintToChat(client, "{valve}Wiki {white}| Pyro | Inferno | Applies a DOT that deals 20 base and 12.5 scaling 20 times every 0.12s. Radius is 800 HU. CD is 60s.");
					CPrintToChat(client, "{valve}Wiki {white}| Demoman | Mine Field | Summons 20 grenades that explode when enemies are within 300HU. Deals 90 base, 6.5 scaling. For every second, the grenades increase in damage by +35%% with a max of 20s. CD is 50s.");
					CPrintToChat(client, "{valve}Wiki {white}| Heavy | Shockwave | Deals 100 base and 60 scaling within a 500HU radius. Stuns for 2.25s and pushes them away 900HU. CD is 20s.");
					CPrintToChat(client, " ");
				}
				case 10:
				{
					CPrintToChat(client, " ");
					CPrintToChat(client, "{valve}Wiki {white}| Engineer | Auto Sentry | Connects a sentry to your head that deals the same damage as a LVL 3 sentry. CD is 120s and lasts 10s regardless of arcane power.");
					CPrintToChat(client, "{valve}Wiki {white}| Medic | Soothing Sunlight | Cast time is 4s. Within a 1350HU radius, heal everyone for 4x your health and give 3x your healing as armor. Gives an additional +100%% armor buff to your teammates. Boosts armor regen by 2x for 6.5s.");
					CPrintToChat(client, "{valve}Wiki {white}| Sniper | Arcane Hunter | Deals 200 base 80 scaling 5x over 2 seconds. Has a splash radius and also autoaims in a 10 degree radius. CD is 30s.");
					CPrintToChat(client, "{valve}Wiki {white}| Spy | Sabotage | Applies sapped effect to enemies around cursor in a 900HU radius. -50%% speed and jump height, lasts 10s. If the target is a building, it'll be disabled for 5s. CD is 25s.");
					CPrintToChat(client, " ");
				}
				default:
				{
					PrintHintText(client, "Sorry, we havent implemented this yet!");
				}
			}
		}
		Menu_ShowWiki(client, GetMenuSelectionPosition());
		CloseHandle(menu);
	}
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_BuyUpgrade(client, 7);
	}
	if(action == MenuAction_End)
		CloseHandle(menu);
	return; 
}
public MenuHandler_StatsViewer(Handle menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select)
	{
		Menu_ShowStatsSlot(client, param2);
	}
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		ClientCommand(client, "buy");
	}
	if(action == MenuAction_End)
		CloseHandle(menu);
	return; 
}
public MenuHandler_StatsSlotViewer(Handle menu, MenuAction:action, client, param2){
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
		Menu_ShowStats(client);
	
	if(action == MenuAction_End)
		CloseHandle(menu);

	return; 
}