public MenuHandler_AccessDenied(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		PrintToChat(client, "This feature is donators/VIPs only")
	}
    if (action == MenuAction_End)
        CloseHandle(menu);
}


public MenuHandler_UpgradeChoice(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		client_respawn_handled[client] = 0
		new slot = current_slot_used[client]
		new w_id = current_w_list_id[client]
		new cat_id = current_w_c_list_id[client]
		new subcat_id = current_w_sc_list_id[client]
		new upgrade_choice = given_upgrd_list[w_id][cat_id][subcat_id][param2]
		new inum = upgrades_ref_to_idx[client][slot][upgrade_choice]
		
		new rate = 1;


		if(upgrades_requirement[upgrade_choice] > (StartMoney + additionalstartmoney))
		{
			decl String:fstr2[100]
			decl String:fstr[40]
			decl String:fstr3[20]
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
			return;
		}
		
		if(globalButtons[client] & IN_DUCK)
		{
			rate *= 10;
		}
		if(globalButtons[client] & IN_RELOAD)
		{
			rate *= 100;
		}
		if(globalButtons[client] & IN_JUMP)
		{
			rate *= -1;
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
				if(upgrades_description[upgrade_choice][0])
				{
					disableUUMiniHud[client] = 8.0;
					decl String:upgradeDescription[1024]
					Format(upgradeDescription, sizeof(upgradeDescription), "%t:\n%s\n", 
					upgradesNames[upgrade_choice],upgrades_description[upgrade_choice]);
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
				currentupgrades_val[client][slot][inum] = upgrades_i_val[upgrade_choice];
			}
			new idx_currentupgrades_val
			if(currentupgrades_i[client][slot][inum] != 0.0){
				idx_currentupgrades_val = RoundFloat((currentupgrades_val[client][slot][inum] - currentupgrades_i[client][slot][inum])/ upgrades_ratio[upgrade_choice])
			}
			else{
				idx_currentupgrades_val = RoundFloat((currentupgrades_val[client][slot][inum] - upgrades_i_val[upgrade_choice])/ upgrades_ratio[upgrade_choice])
			}
			new Float:upgrades_val = currentupgrades_val[client][slot][inum];
			new Float:up_cost = float(upgrades_costs[upgrade_choice]);
			up_cost /= 2.0;
			if (slot == 1)
			{
				up_cost = (up_cost * 1.0) * SecondaryCostReduction;
			}
			if (inum != 20000 && upgrades_ratio[upgrade_choice])
			{
				new Float:t_up_cost = 0.0;
				new times = 0;
				new bool:notEnough = false;
				for (new idx = 0; idx < rate; idx++)
				{
					new Float:nextcost = t_up_cost + up_cost + up_cost * (idx_currentupgrades_val * upgrades_costs_inc_ratio[upgrade_choice])
					if(nextcost < CurrencyOwned[client] && upgrades_ratio[upgrade_choice] > 0.0 && 
					(canBypassRestriction[client] == true || RoundFloat(upgrades_val*100.0)/100.0 < upgrades_m_val[upgrade_choice]))
					{
						t_up_cost += up_cost + RoundFloat(up_cost * (idx_currentupgrades_val* upgrades_costs_inc_ratio[upgrade_choice]))
						idx_currentupgrades_val++		
						upgrades_val += upgrades_ratio[upgrade_choice]
						times++;
					}
					if(nextcost < CurrencyOwned[client] && upgrades_ratio[upgrade_choice] < 0.0 && 
					(canBypassRestriction[client] == true || RoundFloat(upgrades_val*100.0)/100.0 > upgrades_m_val[upgrade_choice]))
					{
						t_up_cost += up_cost + RoundFloat(up_cost * (idx_currentupgrades_val * upgrades_costs_inc_ratio[upgrade_choice]))
						idx_currentupgrades_val++		
						upgrades_val += upgrades_ratio[upgrade_choice]
						times++;
					}
					if(nextcost > CurrencyOwned[client])
					{
						notEnough = true;
					}
				}
				if(times > 0)
				{
					if(canBypassRestriction[client] == false && upgrades_restriction_category[upgrade_choice] != 0)
					{
						for(new i = 1;i<5;i++)
						{
							if(currentupgrades_restriction[client][slot][i] == upgrades_restriction_category[upgrade_choice])
							{
								PrintToChat(client, "You already have something that fits this restriction category.");
								EmitSoundToClient(client, SOUND_FAIL);
							}
						}
						currentupgrades_restriction[client][slot][upgrades_restriction_category[upgrade_choice]] = upgrades_restriction_category[upgrade_choice];
					}
					if(notEnough == true)
					{
						PrintToChat(client, "You didn't have enough money, so you instead bought the most you could.");
					}
					if (t_up_cost < 0.0)
					{
						t_up_cost *= -1;
						if (t_up_cost < float(upgrades_costs[upgrade_choice] / 2))
						{
							t_up_cost = float(upgrades_costs[upgrade_choice] / 2);
						}
					}
					CurrencyOwned[client] -= t_up_cost;
					currentupgrades_val[client][slot][inum] = upgrades_val

					if(!canBypassRestriction[client])
						check_apply_maxvalue(client, slot, inum, upgrade_choice)

					client_spent_money[client][slot] += t_up_cost
					GiveNewUpgradedWeapon_(client, slot)
					PrintToChat(client, "You bought %t %i times.",upgradesNames[upgrade_choice],times);

					if(upgrades_description[upgrade_choice][0])
					{
						disableUUMiniHud[client] = 8.0;
						decl String:upgradeDescription[1024]
						Format(upgradeDescription, sizeof(upgradeDescription), "%t:\n%s\n", 
						upgradesNames[upgrade_choice],upgrades_description[upgrade_choice]);
						ReplaceString(upgradeDescription, sizeof(upgradeDescription), "\\n", "\n");
						ReplaceString(upgradeDescription, sizeof(upgradeDescription), "%", "pct");
						SendItemInfo(client, upgradeDescription);
					}
				}
			}
		}
		else if(rate < 0)
		{
			new yeah = IntAbs(rate);
			if (inum == 20000)
			{
				inum = currentupgrades_number[client][slot]
				currentupgrades_number[client][slot]++
				upgrades_ref_to_idx[client][slot][upgrade_choice] = inum;
				currentupgrades_idx[client][slot][inum] = upgrade_choice 
				currentupgrades_val[client][slot][inum] = upgrades_i_val[upgrade_choice];
			}
			new idx_currentupgrades_val
			if(currentupgrades_i[client][slot][inum] != 0.0){
				idx_currentupgrades_val = RoundFloat((currentupgrades_val[client][slot][inum] - currentupgrades_i[client][slot][inum])/ upgrades_ratio[upgrade_choice])
			}
			else{
				idx_currentupgrades_val = RoundFloat((currentupgrades_val[client][slot][inum] - upgrades_i_val[upgrade_choice])/ upgrades_ratio[upgrade_choice])
			}
			if(idx_currentupgrades_val > 0)
			{
				new Float:upgrades_val = currentupgrades_val[client][slot][inum];
				new Float:up_cost = float(upgrades_costs[upgrade_choice]);
				up_cost /= 2.0;
				if (slot == 1)
				{
					up_cost = (up_cost * 1.0) * SecondaryCostReduction;
				}
				if (inum != 20000 && upgrades_ratio[upgrade_choice])
				{
					new Float:t_up_cost = 0.0;
					new times = 0;
					for (new idx = 0; idx < yeah; idx++)
					{
						if(idx_currentupgrades_val > 0 && upgrades_ratio[upgrade_choice] > 0.0 && 
						(canBypassRestriction[client] == true || (RoundFloat(upgrades_val*100.0)/100.0 <= upgrades_m_val[upgrade_choice]
						&& client_spent_money[client][slot] + t_up_cost > client_tweak_highest_requirement[client][slot] - 1.0)))
						{
							idx_currentupgrades_val--
							t_up_cost -= up_cost + RoundFloat(up_cost * (idx_currentupgrades_val* upgrades_costs_inc_ratio[upgrade_choice]))		
							upgrades_val -= upgrades_ratio[upgrade_choice]
							times++;
						}
						if(idx_currentupgrades_val > 0 && upgrades_ratio[upgrade_choice] < 0.0 && 
						(canBypassRestriction[client] == true || (RoundFloat(upgrades_val*100.0)/100.0 >= upgrades_m_val[upgrade_choice]
						&& client_spent_money[client][slot] + t_up_cost > client_tweak_highest_requirement[client][slot] - 1.0)))
						{
							idx_currentupgrades_val--
							t_up_cost -= up_cost + RoundFloat(up_cost * (idx_currentupgrades_val * upgrades_costs_inc_ratio[upgrade_choice]))	
							upgrades_val -= upgrades_ratio[upgrade_choice]
							times++;
						}
					}
					if(times > 0)
					{
						CurrencyOwned[client] -= t_up_cost;
						currentupgrades_val[client][slot][inum] = upgrades_val
						if(!canBypassRestriction[client])
							check_apply_maxvalue(client, slot, inum, upgrade_choice)
						client_spent_money[client][slot] += t_up_cost
						GiveNewUpgradedWeapon_(client, slot)
						PrintToChat(client, "You downgraded %t %i times.",upgradesNames[upgrade_choice],times);
					}
					if(idx_currentupgrades_val == 0)
						remove_attribute(client,inum);
				}
			}
		}
		decl String:fstr2[100]
		decl String:fstr[40]
		decl String:fstr3[20]
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
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		if(given_upgrd_subcat_nb[current_w_list_id[client]][current_w_c_list_id[client]] > 0)
		{
			if (current_slot_used[client] == 4)
			{
				decl String:fstr[30]
				decl String:fstr2[128]
				Format(fstr, sizeof(fstr), "%T", "Body Upgrades", client)
				Format(fstr2, sizeof(fstr2), "$%.0f [ - %s - ]", CurrencyOwned[client], fstr)
				Menu_ChooseSubcat(client, current_w_c_list_id[client], fstr2)
			}
			else
			{
				decl String:fstr[30]
				decl String:fstr2[128]
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
				decl String:fstr[30]
				decl String:fstr2[128]
				Format(fstr, sizeof(fstr), "%T", "Body Upgrades", client)
				Format(fstr2, sizeof(fstr2), "$%.0f [ - %s - ]", CurrencyOwned[client], fstr)
				Menu_ChooseCategory(client, fstr2)
			}
			else
			{
				decl String:fstr[30]
				decl String:fstr2[128]
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
}


public MenuHandler_SpeMenubuy(Handle:menu, MenuAction:action, client, param2)
{
	CloseHandle(menu);
	return; 
}
public MenuHandler_ChooseSubcat(Handle:menu, MenuAction:action, client, param2)
{
	new Handle:buymenusel = CreateMenu(MenuHandler_BuyUpgrade);
	if (action == MenuAction_Select)
	{
		decl String:fstr2[100]
		decl String:fstr[40]
		decl String:fstr3[20]
		new slot = current_slot_used[client]
		new cat_id = current_w_sc_list_id[client];
		new w_id = current_w_list_id[client]
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
			decl String:fstr[30]
			decl String:fstr2[128]
			Format(fstr, sizeof(fstr), "%T", "Body Upgrades", client)
			Format(fstr2, sizeof(fstr2), "$%.0f [ - %s - ]", CurrencyOwned[client], fstr)
			Menu_ChooseCategory(client, fstr2)
		}
		else
		{
			decl String:fstr[30]
			decl String:fstr2[128]
			Format(fstr, sizeof(fstr), "%T", current_slot_used[client], client)
			Format(fstr2, sizeof(fstr2), "$%.0f [ - Upgrade %s - ]", CurrencyOwned[client]
																,fstr)
			Menu_ChooseCategory(client, fstr2)
		}
	}
    if (action == MenuAction_End)
        CloseHandle(menu);
	SetMenuExitBackButton(buymenusel, true);
	return; 
}
public MenuHandler_Choosecat(Handle:menu, MenuAction:action, client, param2)
{
	new Handle:buymenusel = CreateMenu(MenuHandler_BuyUpgrade);
	if (action == MenuAction_Select)
	{
		decl String:fstr2[100]
		decl String:fstr[40]
		decl String:fstr3[20]
		new slot = current_slot_used[client]
		new cat_id = currentitem_catidx[client][slot]
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
					new String:TutorialString[32];
					GetClientCookie(client, ArmorTutorial, TutorialString, sizeof(TutorialString));
					if(!strcmp("0", TutorialString))
					{
						SetClientCookie(client, ArmorTutorial, "1"); 
						
						new String:TutorialText[256]
						Format(TutorialText, sizeof(TutorialText), " | Tutorial | \nArmor is exponential in power.\nDamage Reduction is a to the power of 2.35 reduction.\nDamage Reduction Multiplier multiplies the calculated Damage Reduction."); 
						SetHudTextParams(-1.0, -1.0, 15.0, 252, 161, 3, 255, 0, 0.0, 0.0, 0.0);
						ShowHudText(client, 10, TutorialText);
						CPrintToChat(client, "{valve}Tutorial {white}| Armor is exponential in power.\nDamage Reduction is a to the power of 2.35 reduction.\nDamage Reduction Multiplier multiplies the calculated Damage Reduction.");
					}
				}
				else if(param2 == 3)
				{
					new String:TutorialString[32];
					GetClientCookie(client, ArcaneTutorial, TutorialString, sizeof(TutorialString));
					if(!strcmp("0", TutorialString))
					{
						SetClientCookie(client, ArcaneTutorial, "1"); 
						
						new String:TutorialText[256]
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
	SetMenuExitBackButton(buymenusel, true);
	return; 
}


public MenuHandler_BuyUpgrade(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:
			{//Buy body upgrades.
				decl String:fstr[30]
				decl String:fstr2[128]
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
			{//Upgrade / buy new weapon.
				if(currentitem_level[client][3] != 242)
				{
					Menu_BuyNewWeapon(client);
				}
				else
				{
					decl String:fstr[30]
					decl String:fstr2[128]
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
				decl String:fstr[30]
				decl String:fstr2[128]
				param2 -= 1
				current_slot_used[client] = param2
				Format(fstr, sizeof(fstr), "%T", current_slot_name[param2], client)
				Format(fstr2, sizeof(fstr2), "$%.0f [ - Upgrade %s - ]", CurrencyOwned[client]
																  ,fstr)
				Menu_ChooseCategory(client, fstr2)
				/*if(AreClientCookiesCached(client))
				{
					new String:TutorialString[32];
					GetClientCookie(client, WeaponTutorial, TutorialString, sizeof(TutorialString));
					if(!strcmp("0", TutorialString))
					{
						SetClientCookie(client, WeaponTutorial, "1"); 

						new String:TutorialText[512]
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
public MenuHandler_ConfirmNewWeapon(Handle:menu, MenuAction:action, client, param2)
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
public Action:Menu_ConfirmWeapon(client, param2)
{
	new Handle:menu = CreateMenu(MenuHandler_BuyNewWeapon);

	new String:TitleStr[64]
	new String:Description[512]
	Format(TitleStr, sizeof(TitleStr), "%s - Costs $%.0f", upgrades_weapon[param2],upgrades_weapon_cost[param2])
	Format(Description, sizeof(Description), "%s",upgrades_weapon_description[param2])
	ReplaceString(Description, sizeof(Description), "\\n", "\n");
	AddMenuItem(menu, "buyWeapon", "Confirm Purchase");

	SetMenuTitle(menu, "%s\n \n%s\n",TitleStr,Description);
	SetMenuExitBackButton(menu, true);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}
public Action:Timer_giveactionslot(Handle:timer, int client)
{
	client = EntRefToEntIndex(client)
	GiveNewWeapon(client, 3);
}

public MenuHandler_BuyNewWeapon(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new selection = upgrades_weapon_lookingat[client];
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
public MenuHandler_AttributesTweak(Handle:menu, MenuAction:action, client, param2)
{
	SetMenuExitBackButton(menu, true);
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
public MenuHandler_AttributesTweak_action(Handle:menu, MenuAction:action, client, param2)
{
	SetMenuExitBackButton(menu, true);
	if (IsValidClient(client) && IsPlayerAlive(client) && !client_respawn_checkpoint[client])
	{
		new s = current_slot_used[client];
		if (s >= 0 && s < 5 && param2 < MAX_ATTRIBUTES_ITEM)
		{
			if (param2 >= 0)
			{
				new u = currentupgrades_idx[client][s][param2]
				if (u != 20000)
				{
					if(upgrades_costs[u] < -0.1)
					{
						new nb_time_upgraded = RoundToNearest((upgrades_i_val[u] - currentupgrades_val[client][s][param2]) / upgrades_ratio[u])
						new Float:up_cost = upgrades_costs[u] * nb_time_upgraded * 3.0;
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
					if (upgrades_costs[u] > 1.0)
					{
						new nb_time_upgraded;
						if(currentupgrades_i[client][s][param2] != 0.0)
						{
							nb_time_upgraded = RoundToNearest((currentupgrades_i[client][s][param2] - currentupgrades_val[client][s][param2]) / upgrades_ratio[u])
						}
						else
						{
							nb_time_upgraded = RoundToNearest((upgrades_i_val[u] - currentupgrades_val[client][s][param2]) / upgrades_ratio[u])
						}
						nb_time_upgraded *= -1
						new Float:up_cost = ((upgrades_costs[u]+((upgrades_costs_inc_ratio[u]*upgrades_costs[u])*(nb_time_upgraded-1))/2)*nb_time_upgraded)
						up_cost /= 2
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
}
public MenuHandler_SpecialUpgradeChoice(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		client_respawn_handled[client] = 0
		new String:fstr[100]
		new got_req = 1
		new slot = current_slot_used[client]
		new w_id = current_w_list_id[client]
		new cat_id = current_w_c_list_id[client]
		new spTweak = given_upgrd_list[w_id][cat_id][0][param2]
		for (new i = 0; i < upgrades_tweaks_nb_att[spTweak]; i++)
		{
			new upgrade_choice = upgrades_tweaks_att_idx[spTweak][i]
			new inum = upgrades_ref_to_idx[client][slot][upgrade_choice]

			if(canBypassRestriction[client])
				break;

			if (inum != 20000)
			{
				if (currentupgrades_val[client][slot][inum] == upgrades_m_val[upgrade_choice])
				{
					PrintToChat(client, "You already have reached the maximum upgrade for this tweak.");
					EmitSoundToClient(client, SOUND_FAIL);
					got_req = 0
					break;
				}
			}
			else
			{
				if (currentupgrades_number[client][slot] + upgrades_tweaks_nb_att[spTweak] >= MAX_ATTRIBUTES_ITEM)
				{
					PrintToChat(client, "You have not enough upgrade category slots for this tweak.");
					EmitSoundToClient(client, SOUND_FAIL);
					got_req = 0
					break;
				}
			}
			if(upgrades_tweaks_requirement[spTweak] > client_spent_money[client][slot])
			{
				PrintToChat(client, "You must spend more on the slot to use this tweak.");
				EmitSoundToClient(client, SOUND_FAIL);
				got_req = 0
				break;
			}
			if(upgrades_tweaks_cost[spTweak] > CurrencyOwned[client])
			{
				PrintToChat(client, "You don't have enough money for this tweak.");
				EmitSoundToClient(client, SOUND_FAIL);
				got_req = 0
				break;
			}
		}
		if (got_req)
		{
			if(upgrades_tweaks_requirement[spTweak] > 1.0 && client_tweak_highest_requirement[client][slot] < upgrades_tweaks_requirement[spTweak])
			{
				client_tweak_highest_requirement[client][slot] = upgrades_tweaks_requirement[spTweak];
			}
			decl String:clname[255]
			GetClientName(client, clname, sizeof(clname))
			for (new i = 1; i < MaxClients; i++)
			{
				if (IsValidClient(i) && !client_no_d_team_upgrade[i])
				{
					PrintToChat(i,"%s : [%s tweak] - %s!", 
					clname, upgrades_tweaks[spTweak], current_slot_name[slot]);
				}
			}
			for (new i = 0; i < upgrades_tweaks_nb_att[spTweak]; i++)
			{
				new upgrade_choice = upgrades_tweaks_att_idx[spTweak][i]
				UpgradeItem(client, upgrade_choice, upgrades_ref_to_idx[client][slot][upgrade_choice], upgrades_tweaks_att_ratio[spTweak][i], slot)
			}
			GiveNewUpgradedWeapon_(client, slot)
			CurrencyOwned[client] -= upgrades_tweaks_cost[spTweak];
			client_spent_money[client][slot] += upgrades_tweaks_cost[spTweak];
		}
		new String:buf[128]
		Format(buf, sizeof(buf), "%T", current_slot_name[slot], client);
		Format(fstr, sizeof(fstr), "$%.0f [%s] - %s", CurrencyOwned[client], buf, 
				given_upgrd_classnames[w_id][cat_id])
		Menu_SpecialUpgradeChoice(client, cat_id, fstr, GetMenuSelectionPosition())
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack){
		if (current_slot_used[client] == 4)
		{
			decl String:fstr[30]
			decl String:fstr2[128]
			Format(fstr, sizeof(fstr), "%T", "Body Upgrades", client)
			Format(fstr2, sizeof(fstr2), "$%.0f [ - %s - ]", CurrencyOwned[client], fstr)
			Menu_ChooseCategory(client, fstr2)
			
		}
		else
		{
			decl String:fstr[30]
			decl String:fstr2[128]
			Format(fstr, sizeof(fstr), "%T", current_slot_name[current_slot_used[client]], client)
			Format(fstr2, sizeof(fstr2), "$%.0f [ - Upgrade %s - ]", CurrencyOwned[client]
															  ,fstr)
			Menu_ChooseCategory(client, fstr2)
		}
	}
    if (action == MenuAction_End)
        CloseHandle(menu);
}
public MenuHandler_Preferences(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select && IsValidClient(client) && IsPlayerAlive(client))
	{
		if(param2 >= 0 && AreClientCookiesCached(client))
		{
			switch(param2)
			{
				case 0:
				{
					new String:XPos[64];
					GetClientCookie(client, hArmorXPos, XPos, sizeof(XPos));
					new Float:XPosNum = StringToFloat(XPos);
					FloatToString(XPosNum + 0.01, XPos, sizeof(XPos));
					SetClientCookie(client, hArmorXPos, XPos);
					PrintHintText(client, "new XPos = %s", XPos);
				}
				case 1:
				{
					new String:XPos[64];
					GetClientCookie(client, hArmorXPos, XPos, sizeof(XPos));
					new Float:XPosNum = StringToFloat(XPos);
					FloatToString(XPosNum - 0.01, XPos, sizeof(XPos));
					SetClientCookie(client, hArmorXPos, XPos);
					PrintHintText(client, "new XPos = %s", XPos);
				}
				case 2:
				{
					new String:YPos[64];
					GetClientCookie(client, hArmorYPos, YPos, sizeof(YPos));
					new Float:YPosNum = StringToFloat(YPos);
					FloatToString(YPosNum + 0.01, YPos, sizeof(YPos));
					SetClientCookie(client, hArmorYPos, YPos);
					PrintHintText(client, "new YPos = %s", YPos);
				}
				case 3:
				{
					new String:YPos[64];
					GetClientCookie(client, hArmorYPos, YPos, sizeof(YPos));
					new Float:YPosNum = StringToFloat(YPos);
					FloatToString(YPosNum - 0.01, YPos, sizeof(YPos));
					SetClientCookie(client, hArmorYPos, YPos);
					PrintHintText(client, "new YPos = %s", YPos);
				}
				case 4:
				{
					new String:menuEnabled[64];
					GetClientCookie(client, respawnMenu, menuEnabled, sizeof(menuEnabled));
					new Float:menuValue = StringToFloat(menuEnabled);
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
					new String:waterMarkEnabled[64];
					GetClientCookie(client, SAwaterMark, waterMarkEnabled, sizeof(waterMarkEnabled));
					new Float:watermarkValue = StringToFloat(waterMarkEnabled);
					
					if(watermarkValue == 1.0){
						SetClientCookie(client, SAwaterMark, "0");
						PrintHintText(client, "Watermark is now enabled.");
					}else{
						SetClientCookie(client, SAwaterMark, "1");
						PrintHintText(client, "Watermark is now disabled.");
					}
				}
				case 6:
				{
					new String:particleToggleEnabled[64];
					GetClientCookie(client, particleToggle, particleToggleEnabled, sizeof(particleToggleEnabled));
					new Float:particleToggleValue = StringToFloat(particleToggleEnabled);
					
					if(particleToggleValue == 0.0){
						SetClientCookie(client, particleToggle, "1");
						PrintHintText(client, "Self-Viewable Particles is now enabled.");
					}else{
						SetClientCookie(client, particleToggle, "0");
						PrintHintText(client, "Self-Viewable Particles is now disabled.");
					}
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
		Menu_ChangePreferences(client);
	}
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_BuyUpgrade(client, 7);
	}
    if (action == MenuAction_End)
        CloseHandle(menu);
	return; 
}
public MenuHandler_Wiki(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select && IsValidClient(client) && IsPlayerAlive(client))
	{
		if(param2 >= 0 && MenuTimer[client] <= 0.0)
		{
			MenuTimer[client] = 1.0
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
	return; 
}
public MenuHandler_StatsViewer(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select)
	{
		RemoveAllMenuItems(menu);
		
		new primary = -1;
		new secondary = -1;
		new melee = -1;
		if(TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			primary = GetWeapon(client,1);
			secondary = GetWeapon(client,2);
			melee = GetPlayerWeaponSlot(client,2);
		}
		else 
		{
			primary = GetWeapon(client,0);
			secondary = GetWeapon(client,1);
			melee = GetWeapon(client,2);
		}
		new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(param2 == 0)
		{
			SetMenuTitle(menu, "Displaying Body Stats");
			decl String:Description[512];
			new Float:DelayAmount = 1.0;
			new Address:armorDelay = TF2Attrib_GetByName(client, "tmp dmgbuff on hit");
			if(armorDelay != Address_Null)
			{
				DelayAmount /= TF2Attrib_GetValue(armorDelay) + 1.0;
			}

			Format(Description, sizeof(Description), "Body Health = %s\nBody Total Resistance = %s\nArmor Recharge Delay = %.2f\nMovespeed = %sHU/S\nFocus Regeneration = %s/S",
			GetAlphabetForm(float(TF2_GetMaxHealth(client))),
			GetAlphabetForm(GetResistance(client, true)),
			DelayAmount,
			GetAlphabetForm(GetEntPropFloat(client, Prop_Data, "m_flMaxspeed")),
			GetAlphabetForm(fl_RegenFocus[client]*66.6)); 
			
			new Address:zapActive = TF2Attrib_GetByName(client, "arcane zap");
			if(zapActive != Address_Null && TF2Attrib_GetValue(zapActive) > 0.0)
			{
				Format(Description, sizeof(Description), "%s\nZap Damage = %s", 
				Description, GetAlphabetForm(20.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 3.0)))
			}
			new Address:lightningActive = TF2Attrib_GetByName(client, "arcane lightning strike");
			if(lightningActive != Address_Null && TF2Attrib_GetValue(lightningActive) > 0.0)
			{
				Format(Description, sizeof(Description), "%s\nLightning Strike Damage = %s", 
				Description, GetAlphabetForm(200.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 80.0)))
			}
			new Address:callBeyondActive = TF2Attrib_GetByName(client, "arcane a call beyond");
			if(callBeyondActive != Address_Null && TF2Attrib_GetValue(callBeyondActive) > 0.0)
			{
				Format(Description, sizeof(Description), "%s\nA Call Beyond Damage = %s x 25", 
				Description, GetAlphabetForm(200.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 120.0)))
			}
			new Address:BlackskyEyeActive = TF2Attrib_GetByName(client, "arcane blacksky eye");
			if(BlackskyEyeActive != Address_Null && TF2Attrib_GetValue(BlackskyEyeActive) > 0.0)
			{
				Format(Description, sizeof(Description), "%s\nBlacksky Eye Damage = %s", 
				Description, GetAlphabetForm(10.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 7.5)))
			}
			new Address:SunlightSpearActive = TF2Attrib_GetByName(client, "arcane sunlight spear");
			if(SunlightSpearActive != Address_Null && TF2Attrib_GetValue(SunlightSpearActive) > 0.0)
			{
				Format(Description, sizeof(Description), "%s\nSunlight Spear Damage = %s", 
				Description, GetAlphabetForm(100.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 40.0)))
			}
			new Address:lightningenchantmentActive = TF2Attrib_GetByName(client, "arcane lightning enchantment");
			if(lightningenchantmentActive != Address_Null && TF2Attrib_GetValue(lightningenchantmentActive) > 0.0)
			{
				Format(Description, sizeof(Description), "%s\nLightning Enchantment DPS = %s", 
				Description, GetAlphabetForm(20.0*(10.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 4.0))))
			}
			new Address:darkmoonbladeActive = TF2Attrib_GetByName(client, "arcane darkmoon blade");
			if(darkmoonbladeActive != Address_Null && TF2Attrib_GetValue(darkmoonbladeActive) > 0.0)
			{
				Format(Description, sizeof(Description), "%s\nDarkmoon Blade Damage = %s", 
				Description, GetAlphabetForm(10.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 4.5)))
			}
			new Address:snapfreezeActive = TF2Attrib_GetByName(client, "arcane snap freeze");
			if(snapfreezeActive != Address_Null && TF2Attrib_GetValue(snapfreezeActive) > 0.0)
			{
				Format(Description, sizeof(Description), "%s\nSnap Freeze Damage = %s", 
				Description, GetAlphabetForm(10.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 60.0)))
			}
			new Address:arcaneprisonActive = TF2Attrib_GetByName(client, "arcane prison");
			if(arcaneprisonActive != Address_Null && TF2Attrib_GetValue(arcaneprisonActive) > 0.0)
			{
				Format(Description, sizeof(Description), "%s\nArcane Prison Damage = %s", 
				Description, GetAlphabetForm(10.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 5.0)))
			}
			new Address:classSpecificActive = TF2Attrib_GetByName(client, "arcane aerial strike");
			if(classSpecificActive != Address_Null && TF2Attrib_GetValue(classSpecificActive) > 0.0)
			{
				Format(Description, sizeof(Description), "%s\nAerial Strike Damage = %s x 30", 
				Description, GetAlphabetForm(10.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 25.0)))
			}
			new Address:classSpecificActive2 = TF2Attrib_GetByName(client, "arcane inferno");
			if(classSpecificActive2 != Address_Null && TF2Attrib_GetValue(classSpecificActive2) > 0.0)
			{
				Format(Description, sizeof(Description), "%s\nInferno Damage = %s x 20", 
				Description, GetAlphabetForm(20.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 12.5)))
			}
			new Address:classSpecificActive3 = TF2Attrib_GetByName(client, "arcane mine field");
			if(classSpecificActive3 != Address_Null && TF2Attrib_GetValue(classSpecificActive3) > 0.0)
			{
				Format(Description, sizeof(Description), "%s\nMine Field Damage = %s x 20", 
				Description, GetAlphabetForm(90.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 6.5)))
			}
			new Address:classSpecificActive4 = TF2Attrib_GetByName(client, "arcane hunter");
			if(classSpecificActive4 != Address_Null && TF2Attrib_GetValue(classSpecificActive4) > 0.0)
			{
				Format(Description, sizeof(Description), "%s\nArcane Hunter Damage = %s x 5", 
				Description, GetAlphabetForm(200.0 + (Pow(ArcaneDamage[client] * Pow(ArcanePower[client], 4.0), 2.45) * 80.0)))
			}
			AddMenuItem(menu, "body_description", Description, ITEMDRAW_DISABLED);
		}
		else if(param2 == 1 && IsValidWeapon(primary))
		{
			decl String:strName[64];
			GetEntityClassname(primary, strName, 64)
			if(StrContains(strName, "weapon") != -1)
			{
				SetMenuTitle(menu, "Displaying Primary Stats");
				decl String:Description[1024];
				
				Format(Description, sizeof(Description), "Weapon Damage Modifier = %s\nWeapon DPS Modifier = %s\nWeapon Base DPS = %.2f\nWeapon DPS = %s",
				GetAlphabetForm(TF2_GetDamageModifiers(client, primary)),
				GetAlphabetForm(TF2_GetDPSModifiers(client, primary)),
				TF2_GetWeaponclassDPS(client, primary),
				GetAlphabetForm(TF2_GetWeaponclassDPS(client, primary) * TF2_GetDPSModifiers(client, primary))); 

				if(weaponFireRate[primary] != -1.0)
				{
					Format(Description, sizeof(Description), "%s\nWeapon Fire Rate = %.2f RPS",Description, weaponFireRate[primary]);
					new Float:tickRate = 1.0/GetTickInterval();

					for(int i = 1 ; i < 6 ; i++)
					{
						if(weaponFireRate[primary] >= tickRate/i)
						{
							tickRate /= i;
							Format(Description, sizeof(Description), "%s\nWeapon Fire Rate Delta (bonus damage)= %.2fx",Description, 1.0+((weaponFireRate[primary]-tickRate)/tickRate));
							break;
						}
					}
				}

				AddMenuItem(menu, "primary_description", Description, ITEMDRAW_DISABLED);
			}
			else
			{
				SetMenuTitle(menu, "Displaying Primary Wearable Stats");
				decl String:Description[512];
				Format(Description, sizeof(Description), "Look in chat for a list of attributes."); 
				TF2_AttribListAttributesBySlot(client,0);
				AddMenuItem(menu, "primary_description", Description, ITEMDRAW_DISABLED);
			}
		}
		else if(param2 == 2 && IsValidWeapon(secondary))
		{
			decl String:strName[64];
			GetEntityClassname(secondary, strName, 64)
			if(StrContains(strName, "medigun") != -1)
			{
				SetMenuTitle(menu, "Displaying Medigun Stats");
				decl String:Description[512];
				
				new Float:healRateMult = 1.0;
				new Float:armorRateMult = 1.0;
				new Address:Healrate1 = TF2Attrib_GetByName(secondary, "heal rate bonus");
				if(Healrate1 != Address_Null)
				{
					healRateMult *= TF2Attrib_GetValue(Healrate1);
				}
				new Address:Healrate2 = TF2Attrib_GetByName(secondary, "heal rate penalty");
				if(Healrate2 != Address_Null)
				{
					healRateMult *= TF2Attrib_GetValue(Healrate2);
				}
				new Address:Healrate3 = TF2Attrib_GetByName(secondary, "overheal fill rate reduced");
				if(Healrate3 != Address_Null)
				{
					healRateMult *= TF2Attrib_GetValue(Healrate3);
				}
				new Address:overhealBonus = TF2Attrib_GetByName(secondary, "overheal bonus");
				if(overhealBonus != Address_Null)
				{
					armorRateMult *= TF2Attrib_GetValue(overhealBonus);
				}
				
				Format(Description, sizeof(Description), "Medigun Base Heal Rate = %s/S\nMedigun Armor Recharge Bonus For Patient = %sx\nMedigun Range = 2k HU",
				GetAlphabetForm(healRateMult*24.0),
				GetAlphabetForm(armorRateMult)); 
				AddMenuItem(menu, "secondary_description", Description, ITEMDRAW_DISABLED);
			}
			else if(StrContains(strName, "weapon") != -1)
			{
				SetMenuTitle(menu, "Displaying Secondary Stats");
				decl String:Description[1024];
				
				Format(Description, sizeof(Description), "Weapon Damage Modifier = %s\nWeapon DPS Modifier = %s\nWeapon Base DPS = %.2f\nWeapon DPS = %s",
				GetAlphabetForm(TF2_GetDamageModifiers(client, secondary)),
				GetAlphabetForm(TF2_GetDPSModifiers(client, secondary)),
				TF2_GetWeaponclassDPS(client, secondary),
				GetAlphabetForm(TF2_GetWeaponclassDPS(client, secondary) * TF2_GetDPSModifiers(client, secondary))); 

				if(weaponFireRate[secondary] != -1.0)
				{
					Format(Description, sizeof(Description), "%s\nWeapon Fire Rate = %.2f RPS",Description, weaponFireRate[secondary]);
					new Float:tickRate = 1.0/GetTickInterval();

					for(int i = 1 ; i < 6 ; i++)
					{
						if(weaponFireRate[secondary] >= tickRate/i)
						{
							tickRate /= i;
							Format(Description, sizeof(Description), "%s\nWeapon Fire Rate Delta (bonus damage)= %.2fx",Description, 1.0+((weaponFireRate[secondary]-tickRate)/tickRate));
							break;
						}
					}
				}

				AddMenuItem(menu, "secondary_description", Description, ITEMDRAW_DISABLED);
			}
			else if(StrContains(strName, "demoshield") != -1)
			{
				SetMenuTitle(menu, "Displaying Secondary Wearable Stats");
				decl String:Description[512];
				
				Format(Description, sizeof(Description), "Shield Explosion Damage = %s\nLook in chat for a list of attributes.",
				GetAlphabetForm(TF2_GetDPSModifiers(client,CWeapon)*70.0));
				TF2_AttribListAttributesBySlot(client,1);
				AddMenuItem(menu, "secondary_description", Description, ITEMDRAW_DISABLED);
			}
			else
			{
				SetMenuTitle(menu, "Displaying Secondary Wearable Stats");
				decl String:Description[512];
				Format(Description, sizeof(Description), "Look in chat for a list of attributes."); 
				TF2_AttribListAttributesBySlot(client,1);
				AddMenuItem(menu, "secondary_description", Description, ITEMDRAW_DISABLED);
			}
		}
		else if(param2 == 3 && IsValidWeapon(melee))
		{
			decl String:strName[64];
			GetEntityClassname(melee, strName, 64)
			if(StrContains(strName, "weapon") != -1)
			{
				SetMenuTitle(menu, "Displaying Melee Stats");
				decl String:Description[1024];
				
				Format(Description, sizeof(Description), "Weapon Damage Modifier = %s\nWeapon DPS Modifier = %s\nWeapon Base DPS = %.2f\nWeapon DPS = %s",
				GetAlphabetForm(TF2_GetDamageModifiers(client, melee)),
				GetAlphabetForm(TF2_GetDPSModifiers(client, melee)),
				TF2_GetWeaponclassDPS(client, melee),
				GetAlphabetForm(TF2_GetWeaponclassDPS(client, melee) * TF2_GetDPSModifiers(client, melee))); 
				
				if(current_class[client] == TFClass_Engineer)
				{
					new Float:SentryDPS = 160.0;
					
					new Address:miniSentryActive = TF2Attrib_GetByName(melee, "mod wrench builds minisentry");
					if(miniSentryActive != Address_Null && TF2Attrib_GetValue(miniSentryActive) > 0.0)
					{
						SentryDPS = 120.0;
					}
					else
					{
						new Address:sentryRocketMult = TF2Attrib_GetByName(melee, "dmg penalty vs nonstunned");
						if(sentryRocketMult != Address_Null)
						{
							SentryDPS += 30.0*TF2Attrib_GetValue(sentryRocketMult);
						}
					}
					
					if(IsValidEntity(CWeapon))
					{
						new Address:SentryDmgActive = TF2Attrib_GetByName(CWeapon, "ring of fire while aiming");
						if(SentryDmgActive != Address_Null)
						{
							SentryDPS *= TF2Attrib_GetValue(SentryDmgActive);
						}
					}
					new Address:SentryDmgActive1 = TF2Attrib_GetByName(melee, "throwable detonation time");
					if(SentryDmgActive1 != Address_Null)
					{
						SentryDPS *= TF2Attrib_GetValue(SentryDmgActive1);
					}
					new Address:SentryDmgActive2 = TF2Attrib_GetByName(melee, "throwable fire speed");
					if(SentryDmgActive2 != Address_Null)
					{
						SentryDPS *= TF2Attrib_GetValue(SentryDmgActive2);
					}
					new Address:damageActive = TF2Attrib_GetByName(melee, "ubercharge");
					if(damageActive != Address_Null)
					{
						SentryDPS *= Pow(1.05,TF2Attrib_GetValue(damageActive));
					}
					new Address:damageActive2 = TF2Attrib_GetByName(melee, "engy sentry damage bonus");
					if(damageActive2 != Address_Null)
					{
						SentryDPS *= TF2Attrib_GetValue(damageActive2);
					}
					new Address:fireRateActive = TF2Attrib_GetByName(melee, "engy sentry fire rate increased");
					if(fireRateActive != Address_Null)
					{
						SentryDPS /= TF2Attrib_GetValue(fireRateActive);
					}
					
					Format(Description, sizeof(Description), "%s\nSentry DPS = %s", Description, GetAlphabetForm(SentryDPS));
				}
				if(weaponFireRate[melee] != -1.0)
				{
					Format(Description, sizeof(Description), "%s\nWeapon Fire Rate = %.2f RPS",Description, weaponFireRate[melee]);
					new Float:tickRate = 1.0/GetTickInterval();

					for(int i = 1 ; i < 6 ; i++)
					{
						if(weaponFireRate[melee] >= tickRate/i)
						{
							tickRate /= i;
							Format(Description, sizeof(Description), "%s\nWeapon Fire Rate Delta (bonus damage)= %.2fx",Description, 1.0+((weaponFireRate[melee]-tickRate)/tickRate));
							break;
						}
					}
				}
				
				AddMenuItem(menu, "melee_description", Description, ITEMDRAW_DISABLED);
			}
			else
			{
				SetMenuTitle(menu, "Displaying Melee Wearable Stats");
				decl String:Description[512];
				Format(Description, sizeof(Description), "Look in chat for a list of attributes."); 
				TF2_AttribListAttributesBySlot(client,2);
				AddMenuItem(menu, "melee_description", Description, ITEMDRAW_DISABLED);
			}
		}
		else if(param2 == 4 && IsValidWeapon(client_new_weapon_ent_id[client]))
		{
			decl String:strName[64];
			new weapon = client_new_weapon_ent_id[client];
			GetEntityClassname(weapon, strName, 64)
			if(StrContains(strName, "weapon") != -1)
			{
				SetMenuTitle(menu, "Displaying Bought Weapon Stats");
				decl String:Description[1024];
				
				Format(Description, sizeof(Description), "Weapon Damage Modifier = %s\nWeapon DPS Modifier = %s\nWeapon Base DPS = %.2f\nWeapon DPS = %s",
				GetAlphabetForm(TF2_GetDamageModifiers(client, weapon)),
				GetAlphabetForm(TF2_GetDPSModifiers(client, weapon)),
				TF2_GetWeaponclassDPS(client, weapon),
				GetAlphabetForm(TF2_GetWeaponclassDPS(client, weapon) * TF2_GetDPSModifiers(client, weapon))); 

				if(weaponFireRate[weapon] != -1.0)
				{
					Format(Description, sizeof(Description), "%s\nWeapon Fire Rate = %.2f RPS",Description, weaponFireRate[weapon]);
					new Float:tickRate = 1.0/GetTickInterval();

					for(int i = 1 ; i < 6 ; i++)
					{
						if(weaponFireRate[weapon] >= tickRate/i)
						{
							tickRate /= i;
							Format(Description, sizeof(Description), "%s\nWeapon Fire Rate Delta (bonus damage)= %.2fx",Description, 1.0+((weaponFireRate[weapon]-tickRate)/tickRate));
							break;
						}
					}
				}

				AddMenuItem(menu, "primary_description", Description, ITEMDRAW_DISABLED);
			}
			else
			{
				SetMenuTitle(menu, "Displaying Bought Wearable Stats");
				decl String:Description[512];
				Format(Description, sizeof(Description), "Look in chat for a list of attributes."); 
				TF2_AttribListAttributesBySlot(client,0);
				AddMenuItem(menu, "primary_description", Description, ITEMDRAW_DISABLED);
			}
		}
		else
		{
			PrintToChat(client, "Was unable to display player stats. Most likely that the class doesn't have a weapon in that slot.");
		}
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		new String:MenuTitle[64];
		GetMenuTitle(menu, MenuTitle, sizeof(MenuTitle));
		if(!StrEqual(MenuTitle, "Display weapon stats by slot."))
		{
			Menu_ShowStats(client);
		}
		else
		{
			ClientCommand(client, "buy");
		}
	}
	return; 
}