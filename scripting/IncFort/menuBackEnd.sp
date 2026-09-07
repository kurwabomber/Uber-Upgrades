public MenuHandler_UpgradeChoice(Menu menu, MenuAction action, client, param2)
{
	if(action == MenuAction_DisplayItem){
		playerUpgradeMenuPage[client] = param2;
	}
	else if (action == MenuAction_Select)
	{
		int slot = current_slot_used[client]
		int w_id = current_w_list_id[client]
		int cat_id = current_w_c_list_id[client]
		int subcat_id = current_w_sc_list_id[client]
		int upgrade_choice = given_upgrd_list[w_id][cat_id][subcat_id][param2]

		if(upgrades[upgrade_choice].is_global)
			slot = 4;

		int inum = upgrades_ref_to_idx[client][slot][upgrade_choice]
		int rate = getUpgradeRate(client);
		if(canBypassRestriction[client] == false && upgrades[upgrade_choice].requirement > (StartMoney + additionalstartmoney))
		{
			char fstr2[100]
			char fstr[40]
			char fstr3[20]
			if (slot != 4)
			{
				Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[w_id][cat_id], 
						client)
				Format(fstr3, sizeof(fstr3), "%T", current_slot_name[slot], client)
				Format(fstr2, sizeof(fstr2), "$%.0f [%s] - %s", CurrencyOwned[client], fstr3,
					fstr)
			}
			else
			{
				Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[_:current_class[client] - 1][cat_id], 
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
				UpgradeItem(client, upgrade_choice, inum, 1.0, slot);
				GiveNewUpgradedWeapon_(client, slot);

				if(singularBuysPerMinute[client] >= 50)
				{
					singularBuysPerMinute[client] = 0
					PrintToChat(client,"You can CROUCH for 10x purchasing and RELOAD for 100x purchasing.");
					PrintToChat(client,"Downgrading is possible by using JUMP key while upgrading.");
				}
				if(upgrades[upgrade_choice].description[0])
				{
					SendUpgradeDescription(client, upgrade_choice, currentupgrades_val[client][slot][inum]);
				}
				if(upgrades[upgrade_choice].display_style == 8){
					int amount
					if(currentupgrades_i[client][slot][inum] != 0.0)
						amount = RoundFloat((currentupgrades_val[client][slot][inum] - currentupgrades_i[client][slot][inum])/ upgrades[upgrade_choice].ratio)
					else
						amount = RoundFloat((currentupgrades_val[client][slot][inum] - upgrades[upgrade_choice].i_val)/ upgrades[upgrade_choice].ratio)
					
					//really... why
					GivePowerupDescription(client, upgrades[upgrade_choice].attr_name, amount);
				}
			}
		}
		else if(rate > 1)
		{
			bool firstTimeBuying = false;
			if (inum == 20000)
			{
				firstTimeBuying = true;
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
						t_up_cost += up_cost + RoundFloat(up_cost * (idx_currentupgrades_val* upgrades[upgrade_choice].cost_inc_ratio));
						idx_currentupgrades_val++;
						upgrades_val += upgrades[upgrade_choice].ratio;
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
				if(canBypassRestriction[client] == false && upgrades[upgrade_choice].restriction_category != 0)
				{
					int cap = 1;
					if(gameStage >= 2 && slot == 4){
						cap++;
					}
					if(currentupgrades_restriction[client][slot][upgrades[upgrade_choice].restriction_category] >= cap)
					{
						PrintToChat(client, "You already have something that fits this restriction category.");
						EmitSoundToClient(client, SOUND_FAIL);
						times = 0;
					}
				}
				if(times > 0)
				{
					if(canBypassRestriction[client] == false && upgrades[upgrade_choice].restriction_category != 0
						&& (firstTimeBuying || currentupgrades_val[client][slot][inum] - upgrades[upgrade_choice].i_val == 0.0)){
						currentupgrades_restriction[client][slot][upgrades[upgrade_choice].restriction_category]++;
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
					PrintToChat(client, "You bought %T %i times.",upgrades[upgrade_choice].name, client, times);

					if(upgrades[upgrade_choice].description[0])
					{
						SendUpgradeDescription(client, upgrade_choice, upgrades_val);
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
						PrintToChat(client, "You downgraded %T %i times.",upgrades[upgrade_choice].name, client,times);
					}
					if(idx_currentupgrades_val == 0)
						remove_attribute(client,inum,slot);
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

    if (action == MenuAction_End){
        for(int i = 1; i <= MaxClients; i++)
        {
			if(playerUpgradeMenus[i] == menu)
			{
				playerUpgradeMenus[i] = null;
                break;
            }
        }
		delete menu;
	}
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
    if (action == MenuAction_End){
		delete menu;
	}
	return; 
}
public MenuHandler_Choosecat(Handle menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		char fstr2[100]
		char fstr[40]
		char fstr3[20]
		int slot = current_slot_used[client];
		int cat_id = currentitem_catidx[client][slot];
		int w_id = current_w_list_id[client];
		if (slot != 4)
		{
			if(given_upgrd_list_nb[w_id] != param2){
				Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[cat_id][param2], client)
				Format(fstr3, sizeof(fstr3), "%T", current_slot_name[slot], client)
				Format(fstr2, sizeof(fstr2), "$%.0f [%s] - %s", CurrencyOwned[client],fstr3,fstr)
			}
			if(given_upgrd_subcat[cat_id][param2] > 0)
			{
				Menu_ChooseSubcat(client, param2, fstr2)
			}
			else
			{
				if(given_upgrd_list_nb[w_id] == param2)
				{
					Menu_TweakUpgrades_slot(client, slot, 0);
				}
				else if (param2 == given_upgrd_classnames_tweak_idx[cat_id])
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
		}
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack){
		Menu_BuyUpgrade(client, 0);
	}
    if (action == MenuAction_End){
		delete menu;
	}
	return; 
}


public MenuHandler_BuyUpgrade(Handle menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		bool isBuildingSlot = false;
		if(param2 >= 4 && current_class[client] == TFClass_Engineer){
			param2--;
			isBuildingSlot = true;
		}

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
			case 5:
			{//Use arcane
				Menu_ShowArcane(client);
			}
			case 6:
			{//Show stats
				Menu_ShowStats(client);
			}
			case 7:
			{//Change preferences menu
				Menu_ChangePreferences(client);
			}
			default:
			{
				char fstr[30]
				char fstr2[128]
				param2--;
				if(isBuildingSlot){
					current_slot_used[client] = 5;
					Format(fstr, sizeof(fstr), "%T", current_slot_name[5], client)
					Format(fstr2, sizeof(fstr2), "$%.0f [ - Upgrade %s - ]", CurrencyOwned[client] ,fstr)
					Menu_ChooseCategory(client, fstr2)
				}else{
					current_slot_used[client] = param2
					Format(fstr, sizeof(fstr), "%T", current_slot_name[param2], client)
					Format(fstr2, sizeof(fstr2), "$%.0f [ - Upgrade %s - ]", CurrencyOwned[client] ,fstr)
					Menu_ChooseCategory(client, fstr2)
				}
			}
		}
	}
    if (action == MenuAction_End){
		delete menu;
	}
}
public MenuHandler_ConfirmNewWeapon(Handle menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		param2 = buyableIndexOffParam[client][param2];
		Menu_ConfirmWeapon(client,param2);
		upgrades_weapon_lookingat[client] = param2;
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack){
		Menu_BuyUpgrade(client, 7);
	}
    if (action == MenuAction_End){
		delete menu;
	}
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
			PrintToChat(client, "You don't have enough money to buy this custom weapon.");
			EmitSoundToClient(client, SOUND_FAIL);
		}
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack){
		CreateBuyNewWeaponMenu(client)
	}
    if (action == MenuAction_End){
		delete menu;
	}
}
public Action:Timer_giveactionslot(Handle timer, int client)
{
	client = EntRefToEntIndex(client)
	if(IsValidClient(client))
		GiveNewWeapon(client, 3);
}

public MenuHandler_AttributesTweak(Handle menu, MenuAction:action, client, param2)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		Menu_TweakUpgrades_slot(client, param2, 0)
	}
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Menu_BuyUpgrade(client, 0);
	}
    if (action == MenuAction_End){
		delete menu;
	}
	return; 
}
public MenuHandler_AttributesTweak_action(Handle menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select){
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			int s = current_slot_used[client];
			if (s < 0 || s > NB_SLOTS_UED)
				return;

			if (param2 < 0)
				return;

			int downsideCounter = 0;
			int upgradeIndex = 0;
			for (int i = 0; i < currentupgrades_number[client][s]; ++i)
			{
				int u = currentupgrades_idx[client][s][i]
				if (upgrades[u].cost < -0.1)
				{
					int nb_time_upgraded = RoundToNearest((upgrades[u].i_val - currentupgrades_val[client][s][i]) / upgrades[u].ratio);
					float up_cost = float(upgrades[u].cost*nb_time_upgraded);
					if(up_cost > 200.0)
					{
						if(downsideCounter == param2){
							upgradeIndex = i;
							break;
						}
						downsideCounter++;
					}
				}
			}
			int u = currentupgrades_idx[client][s][upgradeIndex]
			if (u != 20000)
			{
				if(upgrades[u].cost < -0.1)
				{
					int nb_time_upgraded = RoundToNearest((upgrades[u].i_val - currentupgrades_val[client][s][upgradeIndex]) / upgrades[u].ratio)
					float up_cost = float(upgrades[u].cost * nb_time_upgraded);
					if(up_cost > 200.0)
					{
						if (CurrencyOwned[client] >= up_cost)
						{
							remove_attribute(client, upgradeIndex, s);
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
				Menu_TweakUpgrades_slot(client, s, GetMenuSelectionPosition())
			}
		}
	}
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		char fstr[64], fstr2[64];
		Format(fstr, sizeof(fstr), "%T", current_slot_name[current_slot_used[client]], client)
		Format(fstr2, sizeof(fstr2), "$%.0f [ - Upgrade %s - ]", CurrencyOwned[client]
															,fstr)
		Menu_ChooseCategory(client, fstr2);
	}
    if (action == MenuAction_End){
		delete menu;
	}
}
public MenuHandler_SpecialUpgradeChoice(Handle menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_DisplayItem){
		playerTweakMenuPage[client] = param2;
	}
	if (action == MenuAction_Select)
	{
		char fstr[100]
		int got_req = 1
		int slot = current_slot_used[client]
		int w_id = current_w_list_id[client]
		int cat_id = current_w_c_list_id[client]
		int spTweak = given_upgrd_list[w_id][cat_id][0][param2]
		float rate = (globalButtons[client] & IN_JUMP) ? -1.0 : 1.0;

		if(!canBypassRestriction[client]){
			for(int k = 0;k < 5;k++){
				if(currentupgrades_restriction[client][slot][k] == 0)
					continue;

				if(rate >= 1.0 && currentupgrades_restriction[client][slot][k] == tweaks[spTweak].restriction){
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

		if (got_req)
		{
			if(rate > 0) {
				if(tweaks[spTweak].requirement > 1.0 && client_tweak_highest_requirement[client][slot] < tweaks[spTweak].requirement)
				{
					client_tweak_highest_requirement[client][slot] = tweaks[spTweak].requirement;
				}
				if(tweaks[spTweak].restriction != 0)
				{
					currentupgrades_restriction[client][slot][tweaks[spTweak].restriction] = tweaks[spTweak].restriction;
				}
				for (int i = 0; i < tweaks[spTweak].nb_att; ++i)
				{
					int upgrade_choice = tweaks[spTweak].att_idx[i]
					UpgradeItem(client, upgrade_choice, upgrades_ref_to_idx[client][slot][upgrade_choice], tweaks[spTweak].att_ratio[i], slot, true);
				}
				GiveNewUpgradedWeapon_(client, slot)
				client_spent_money[client][slot] += tweaks[spTweak].cost;
				if(!canBypassRestriction[client])
					CurrencyOwned[client] -= tweaks[spTweak].cost;
			}
			else {
				bool removedRestriction = true;
				for (int i = 0; i < tweaks[spTweak].nb_att; ++i)
				{
					int upgrade_choice = tweaks[spTweak].att_idx[i]
					int tmp_ref_idx = upgrades_ref_to_idx[client][slot][upgrade_choice]
					// In this case, the tweak hasn't been selected at all.
					if (tmp_ref_idx == 20000)
					{
						removedRestriction = false;
						break;
					}
					else // In this case, it has been selected, but has already been refunded.
					{
						if(currentupgrades_i[client][slot][tmp_ref_idx] != 0.0 &&
							currentupgrades_val[client][slot][tmp_ref_idx] == currentupgrades_i[client][slot][tmp_ref_idx]){
							removedRestriction = false;
							break;
						}
						else if (currentupgrades_val[client][slot][tmp_ref_idx] == upgrades[upgrade_choice].i_val){
							removedRestriction = false;
							break;
						}
					}
				}

				if(removedRestriction){
					removedRestriction = false;
					for (int i = 0; i < tweaks[spTweak].nb_att; ++i)
					{
						int upgrade_choice = tweaks[spTweak].att_idx[i]
						int tmp_ref_idx = upgrades_ref_to_idx[client][slot][upgrade_choice]
						if (tmp_ref_idx != 20000)
						{
							float tmp_val = upgrades[upgrade_choice].ratio*tweaks[spTweak].att_ratio[i];
							float tmp_init = upgrades[upgrade_choice].i_val;
							currentupgrades_val[client][slot][tmp_ref_idx] -= tmp_val;
							if(currentupgrades_i[client][slot][tmp_ref_idx] != 0.0){
								tmp_init = currentupgrades_i[client][slot][tmp_ref_idx];
							}

							if(tmp_val < 0){
								if(currentupgrades_val[client][slot][tmp_ref_idx] >= tmp_init){
									currentupgrades_val[client][slot][tmp_ref_idx] = tmp_init;
									removedRestriction = true;
								}
							}
							else if(tmp_val > 0){
								if(currentupgrades_val[client][slot][tmp_ref_idx] <= tmp_init){
									currentupgrades_val[client][slot][tmp_ref_idx] = tmp_init;
									removedRestriction = true;
								}
							}
						}
					}
					if(tweaks[spTweak].restriction != 0 && removedRestriction)
					{
						currentupgrades_restriction[client][slot][tweaks[spTweak].restriction] = 0;
					}
					GiveNewUpgradedWeapon_(client, slot)
					client_spent_money[client][slot] -= tweaks[spTweak].cost;
					if(!canBypassRestriction[client])
						CurrencyOwned[client] += tweaks[spTweak].cost;
				}
			}
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

    if (action == MenuAction_End){
        for(int i = 1; i <= MaxClients; i++)
        {
			if(playerTweakMenus[i] == menu)
			{
				playerTweakMenus[i] = null;
                break;
            }
        }
		delete menu;
	}
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
				default:
				{
					PrintHintText(client, "Sorry, we havent implemented this yet!");
				}
			}
		}
	}
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack){
		Menu_BuyUpgrade(client, 7);
	}
    if (action == MenuAction_End){
		delete menu;
	}
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
    if (action == MenuAction_End){
		delete menu;
	}
	return; 
}
public MenuHandler_StatsSlotViewer(Handle menu, MenuAction:action, client, param2){
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack){
		Menu_ShowStats(client);
	}
    if (action == MenuAction_End){
		delete menu;
	}
	return; 
}