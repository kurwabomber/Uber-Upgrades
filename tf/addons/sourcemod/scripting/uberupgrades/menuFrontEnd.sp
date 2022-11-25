//UU Front Menu
public Action:Menu_BuyUpgrade(client, args)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !client_respawn_checkpoint[client] )
	{
		menuBuy = CreateMenu(MenuHandler_BuyUpgrade);
		SetMenuTitle(menuBuy, "Uber Upgrades - /buy or +SHOWSCORES");
		
		AddMenuItem(menuBuy, "upgrade_player", "Upgrade Body");
		
		AddMenuItem(menuBuy, "upgrade_primary", "Upgrade Primary Slot");
		
		AddMenuItem(menuBuy, "upgrade_secondary", "Upgrade Secondary Slot");
		
		AddMenuItem(menuBuy, "upgrade_melee", "Upgrade Melee Slot");
		
		AddMenuItem(menuBuy, "upgrade_dispcurrups", "Upgrade Manager");
		
		AddMenuItem(menuBuy, "upgrade_stats", "View Stats");
		
		AddMenuItem(menuBuy, "use_arcane", "Use Arcane Spells");

		if (currentitem_level[client][3] != 242)
		{
			AddMenuItem(menuBuy, "upgrade_buyoneweap", "Buy a Custom Weapon");
		}
		else
		{
			AddMenuItem(menuBuy, "upgrade_upgradeoneweap", "Upgrade Bought Weapon");
		}
		
		AddMenuItem(menuBuy, "preferences", "Change Preferences/Settings");
		
		AddMenuItem(menuBuy, "wiki", "Display In-Game Wiki");
		
		DisplayMenuAtItem(menuBuy, client, args, MENU_TIME_FOREVER)
	}
}
//When you purchase an upgrade
Action:Menu_UpgradeChoice(client, cat_choice, String:TitleStr[100], int page = 0)
{
	new i

	new Handle:menu = CreateMenu(MenuHandler_UpgradeChoice);
	if (cat_choice != -1)
	{
		new w_id = current_w_list_id[client]

		decl String:desc_str[512]
		new tmp_up_idx
		new tmp_ref_idx
		new up_cost
		new Float:tmp_val
		new Float:val
		new Float:tmp_ratio
		new slot
		decl String:plus_sign[4]
		current_w_c_list_id[client] = cat_choice
		slot = current_slot_used[client]
		for (i = 0; (tmp_up_idx = given_upgrd_list[w_id][cat_choice][i]); i++)
		{
			up_cost = upgrades_costs[tmp_up_idx] / 2
			if (slot == 1)
			{
				up_cost = RoundFloat((up_cost * 1.0) * SecondaryCostReduction)
			}
			tmp_ref_idx = upgrades_ref_to_idx[client][slot][tmp_up_idx];
			if (tmp_ref_idx != 20000)
			{
				val = currentupgrades_val[client][slot][tmp_ref_idx]
				tmp_val = currentupgrades_val[client][slot][tmp_ref_idx] - upgrades_i_val[tmp_up_idx]
				if(currentupgrades_i[client][slot][tmp_ref_idx] != 0.0)
					tmp_val = currentupgrades_val[client][slot][tmp_ref_idx] - currentupgrades_i[client][slot][tmp_ref_idx]
			}
			else
			{
				tmp_val = 0.0
				val = 0.0
			}
			tmp_ratio = upgrades_ratio[tmp_up_idx]
			if (tmp_val && tmp_ratio)
			{
				up_cost += RoundFloat(up_cost * (tmp_val / tmp_ratio) * upgrades_costs_inc_ratio[tmp_up_idx])
				if (up_cost < 0.0)
				{
					up_cost *= -1;
					if (up_cost < (upgrades_costs[tmp_up_idx] / 2))
					{
						up_cost = upgrades_costs[tmp_up_idx] / 2
					}
				}
			}
			if (tmp_ratio > 0.0)
			{
				plus_sign = "+"
			}
			else
			{
				tmp_ratio *= -1.0
				plus_sign = "-"
			}
			new String:buf[256]
			new bool:itemDisabled;
			Format(buf, sizeof(buf), "%T", upgradesNames[tmp_up_idx], client)
			if (tmp_ratio < 0.99)
			{
				if(RoundFloat(val*100.0)/100.0 == upgrades_m_val[tmp_up_idx])
				{
					Format(desc_str, sizeof(desc_str), "$%5d - %s\n\t\t\t%s%i%%\t(%i%%) MAXED",
						up_cost, buf,
						plus_sign, RoundFloat(tmp_ratio * 100), (RoundFloat(tmp_val * 100)))
					itemDisabled = true;
				}
				else if(upgrades_restriction_category[tmp_up_idx] != 0 && (val == 0.0 || val - upgrades_i_val[tmp_up_idx] == 0.0))
				{
					for(new it = 0;it<5;it++)
					{
						if(currentupgrades_restriction[client][slot][it] == upgrades_restriction_category[tmp_up_idx])
						{
							Format(desc_str, sizeof(desc_str), "$%5d - %s\n\t\t\t%s%i%%\t(%i%%) RESTRICTED",
								up_cost, buf,
								plus_sign, RoundFloat(tmp_ratio * 100), (RoundFloat(tmp_val * 100)))
							itemDisabled = true;
						}
					}
					if(!itemDisabled)
					{
						Format(desc_str, sizeof(desc_str), "$%5d - %s\n\t\t\t%s%i%%\t(%i%%)",
							up_cost, buf,
							plus_sign, RoundFloat(tmp_ratio * 100), (RoundFloat(tmp_val * 100)))
					}
				}
				else
				{
					Format(desc_str, sizeof(desc_str), "$%5d - %s\n\t\t\t%s%i%%\t(%i%%)",
						up_cost, buf,
						plus_sign, RoundFloat(tmp_ratio * 100), (RoundFloat(tmp_val * 100)))
				}
			}
			else
			{
				if(RoundFloat(val*100.0)/100.0 == upgrades_m_val[tmp_up_idx])
				{
					Format(desc_str, sizeof(desc_str), "$%5d - %s\n\t\t\t%s%3.1f\t(%.1f) MAXED",
						up_cost, buf,
						plus_sign, tmp_ratio, tmp_val)
					itemDisabled = true
				}
				else if(upgrades_restriction_category[tmp_up_idx] != 0 && (val == 0.0 || val - upgrades_i_val[tmp_up_idx] == 0.0))
				{
					for(new it = 0;it<5;it++)
					{
						if(currentupgrades_restriction[client][slot][it] == upgrades_restriction_category[tmp_up_idx])
						{
							Format(desc_str, sizeof(desc_str), "$%5d - %s\n\t\t\t%s%3.1f\t(%.1f) RESTRICTED",
								up_cost, buf,
								plus_sign, RoundFloat(tmp_ratio * 100), (RoundFloat(tmp_val * 100)))
							itemDisabled = true;
						}
					}
					if(!itemDisabled)
					{
						Format(desc_str, sizeof(desc_str), "$%5d - %s\n\t\t\t%s%3.1f\t(%.1f)",
							up_cost, buf,
							plus_sign, tmp_ratio, tmp_val)
					}
				}
				else
				{
					Format(desc_str, sizeof(desc_str), "$%5d - %s\n\t\t\t%s%3.1f\t(%.1f)",
						up_cost, buf,
						plus_sign, tmp_ratio, tmp_val)
				}
			}

			switch(upgrades_display_style[tmp_up_idx])
			{
				case 1:
				{
					if(val == 0.0)
						val = upgrades_i_val[tmp_up_idx];

					char tempStr[32];
					FloatToString((val+upgrades_ratio[tmp_up_idx])/val, tempStr, sizeof(tempStr));
					Format(desc_str, sizeof(desc_str), "%s (%.6sx)", desc_str, tempStr);
				}
				case 2:
				{
					Format(desc_str, sizeof(desc_str), "%s (+%.1f)", desc_str, (GetResistance(client, true, upgrades_ratio[tmp_up_idx])) - (GetResistance(client, true)));
				}
				case 3:
				{
					Format(desc_str, sizeof(desc_str), "%s (+%.1f)", desc_str, (GetResistance(client, true, 0.0, upgrades_ratio[tmp_up_idx])) - (GetResistance(client, true)));
				}
				case 4:
				{
					new Float:arcanePower = 1.0;
					
					new Address:ArcaneActive = TF2Attrib_GetByName(client, "medigun crit fire percent bar deplete")
					if(ArcaneActive != Address_Null)
					{
						arcanePower = TF2Attrib_GetValue(ArcaneActive);
					}
					
					new Float:arcaneDamageMult = 1.0;

					new Address:ArcaneDamageActive = TF2Attrib_GetByName(client, "sticky detonate mode")
					if(ArcaneDamageActive != Address_Null)
					{
						arcaneDamageMult = TF2Attrib_GetValue(ArcaneDamageActive);
					}

					new Float:delta = Pow((arcaneDamageMult+upgrades_ratio[tmp_up_idx]) * Pow(arcanePower, 4.0), 2.45) - Pow(arcaneDamageMult * Pow(arcanePower, 4.0), 2.45);
					Format(desc_str, sizeof(desc_str), "%s (+%.1f)", desc_str, delta);
				}
				case 5:
				{
					new Float:arcanePower = 1.0;
					
					new Address:ArcaneActive = TF2Attrib_GetByName(client, "medigun crit fire percent bar deplete")
					if(ArcaneActive != Address_Null)
					{
						arcanePower = TF2Attrib_GetValue(ArcaneActive);
					}
					
					new Float:arcaneDamageMult = 1.0;

					new Address:ArcaneDamageActive = TF2Attrib_GetByName(client, "sticky detonate mode")
					if(ArcaneDamageActive != Address_Null)
					{
						arcaneDamageMult = TF2Attrib_GetValue(ArcaneDamageActive);
					}

					new Float:delta = Pow(arcaneDamageMult * Pow(arcanePower+upgrades_ratio[tmp_up_idx], 4.0), 2.45) - Pow(arcaneDamageMult * Pow(arcanePower, 4.0), 2.45);
					Format(desc_str, sizeof(desc_str), "%s (+%.1f)", desc_str, delta);
				}
			}

			AddMenuItem(menu, "upgrade", desc_str);
		}
		SetMenuTitle(menu, TitleStr);
		SetMenuExitBackButton(menu, true);
		DisplayMenuAtItem(menu, client, page, MENU_TIME_FOREVER)
	}
}
//Slot Selection
public Action:Menu_ChooseCategory(client, String:TitleStr[128])
{

	new w_id
	
	new Handle:menu = CreateMenu(MenuHandler_Choosecat);
	new slot = current_slot_used[client];
	if (slot != 4)
	{
		w_id = currentitem_catidx[client][slot];
	}
	else
	{
		w_id = _:TF2_GetPlayerClass(client) - 1;
		if(w_id < 0)
		{
			w_id = 0;
		}
	}
	if (w_id >= -1)
	{
		current_w_list_id[client] = w_id
		new String:buf[128]
		for (new i = 0; i < given_upgrd_list_nb[w_id] <= 10 ; i++)
		{
			Format(buf, sizeof(buf), "%T", given_upgrd_classnames[w_id][i], client)
			AddMenuItem(menu, "upgrade", buf);
		}
	}
	SetMenuTitle(menu, TitleStr);
	SetMenuExitBackButton(menu, true);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		DisplayMenu(menu, client, 20);
	}
}
//Tweak menu
public Action:Menu_SpecialUpgradeChoice(client, cat_choice, String:TitleStr[100], selectidx)
{
	
	new i, j
	new Handle:menu = CreateMenu(MenuHandler_SpecialUpgradeChoice);
	SetMenuPagination(menu, 2);
	SetMenuExitBackButton(menu, true);
	
	if (cat_choice != -1)
	{
		decl String:desc_str[512]
		new w_id = current_w_list_id[client]
		new tmp_up_idx
		new tmp_spe_up_idx
		new tmp_ref_idx
		new Float:tmp_val
		new Float:tmp_ratio
		new slot
		decl String:plus_sign[4]
		new String:buft[256]
	
		current_w_c_list_id[client] = cat_choice
		slot = current_slot_used[client]
		for (i = 0; i < given_upgrd_classnames_tweak_nb[w_id]; i++)
		{
			tmp_spe_up_idx = given_upgrd_list[w_id][cat_choice][i]
			Format(buft, sizeof(buft), "%T",  upgrades_tweaks[tmp_spe_up_idx], client);
			if(upgrades_tweaks_cost[tmp_spe_up_idx] > 0.0)
			{
				Format(buft, sizeof(buft), "%s\nCost: $%.0f",  buft, upgrades_tweaks_cost[tmp_spe_up_idx])
			}
			if(upgrades_tweaks_requirement[tmp_spe_up_idx] > 0.0)
			{
				Format(buft, sizeof(buft), "%s\nRequirement: $%.0f spent",  buft, upgrades_tweaks_requirement[tmp_spe_up_idx])
			}
			desc_str = buft;
			for (j = 0; j < upgrades_tweaks_nb_att[tmp_spe_up_idx]; j++)
			{
				tmp_up_idx = upgrades_tweaks_att_idx[tmp_spe_up_idx][j]
				tmp_ref_idx = upgrades_ref_to_idx[client][slot][tmp_up_idx]
				if (tmp_ref_idx != 20000)
				{	
					tmp_val = currentupgrades_val[client][slot][tmp_ref_idx] - upgrades_i_val[tmp_up_idx]
				}
				else
				{
					tmp_val = 0.0
				}
				tmp_ratio = upgrades_ratio[tmp_up_idx]
				if (tmp_ratio > 0.0)
				{
					plus_sign = "+"
				}
				else
				{
					tmp_ratio *= -1.0
					plus_sign = "-"
				}
				new String:buf[256]
				Format(buf, sizeof(buf), "%T", upgradesNames[tmp_up_idx], client)
				if (tmp_ratio < 0.99)
				{
					tmp_ratio *= upgrades_tweaks_att_ratio[tmp_spe_up_idx][j]
					Format(desc_str, sizeof(desc_str), "%s\n%\t-%s\n\t\t\t%s%i%%\t(%i%%)",
						desc_str, buf,
						plus_sign, RoundFloat(tmp_ratio * 100), RoundFloat(tmp_val * 100))
				}
				else
				{
					tmp_ratio *= upgrades_tweaks_att_ratio[tmp_spe_up_idx][j]
					Format(desc_str, sizeof(desc_str), "%s\n\t-%s\n\t\t\t%s%3.1f\t(%.1f)",
						desc_str, buf,
						plus_sign, tmp_ratio, tmp_val)
				}
			}
			AddMenuItem(menu, "upgrade", desc_str);
		}
	}
	else{
	CloseHandle(menu);
	}
	SetMenuTitle(menu, TitleStr);
	DisplayMenuAtItem(menu, client, selectidx, MENU_TIME_FOREVER);

	return; 
}
public	Menu_TweakUpgrades_slot(client, arg, page)
{
	if (arg > -1 && arg < 5
	&& IsValidClient(client) 
	&& IsPlayerAlive(client))
	{
		new Handle:menu = CreateMenu(MenuHandler_AttributesTweak_action);
		new i, s
			
		s = arg;
		current_slot_used[client] = s;
		SetMenuTitle(menu, "$%.0f ***%s - Choose attribute:", CurrencyOwned[client], current_slot_name[s]);
		decl String:buf[256]
		decl String:fstr[512]
		if(currentupgrades_number[client][s] != 0)
		{
			for (i = 0; i < currentupgrades_number[client][s]; i++)
			{
				new u = currentupgrades_idx[client][s][i]
				Format(buf, sizeof(buf), "%T", upgradesNames[u], client)
				if (upgrades_costs[u] < -0.1)
				{
					new nb_time_upgraded = RoundToNearest((upgrades_i_val[u] - currentupgrades_val[client][s][i]) / upgrades_ratio[u])
					new Float:up_cost = upgrades_costs[u] * nb_time_upgraded * 3.0
					if(up_cost > 200.0)
					{
						Format(fstr, sizeof(fstr), "[%s] :\n\t\t%10.2f\n%.0f", buf, RoundFloat(currentupgrades_val[client][s][i]*100.0)/100.0,up_cost)
					}
					else
					{
						Format(fstr, sizeof(fstr), "[%s] :\n\t\t%10.2f", buf, RoundFloat(currentupgrades_val[client][s][i]*100.0)/100.0)
					}
				}
				else if (upgrades_costs[u] > 1.0)
				{
					new nb_time_upgraded;
					if(currentupgrades_i[client][s][i] != 0.0)
					{
						nb_time_upgraded = RoundToNearest((currentupgrades_i[client][s][i] - currentupgrades_val[client][s][i]) / upgrades_ratio[u])
					}
					else
					{
						nb_time_upgraded = RoundToNearest((upgrades_i_val[u] - currentupgrades_val[client][s][i]) / upgrades_ratio[u])
					}
					nb_time_upgraded *= -1
					new Float:up_cost = ((upgrades_costs[u]+((upgrades_costs_inc_ratio[u]*upgrades_costs[u])*(nb_time_upgraded-1))/2)*nb_time_upgraded)
					up_cost /= 2
					if(s == 1)
						up_cost *= SecondaryCostReduction;
						
					if(up_cost > 200.0)
					{
						Format(fstr, sizeof(fstr), "[%s] :\n\t\t%10.2f\n+%.0f", buf, RoundFloat(currentupgrades_val[client][s][i]*100.0)/100.0,up_cost)
					}
					else
					{
						Format(fstr, sizeof(fstr), "[%s] :\n\t\t%10.2f", buf, RoundFloat(currentupgrades_val[client][s][i]*100.0)/100.0)
					}
				}
				else
				{
					Format(fstr, sizeof(fstr), "[%s] :\n\t\t%10.2f", buf, RoundFloat(currentupgrades_val[client][s][i]*100.0)/100.0)
				}
				AddMenuItem(menu, "yep", fstr);
			}
			if (IsValidClient(client) && IsPlayerAlive(client))
			{
				DisplayMenu(menu, client, 20);
			}
			DisplayMenuAtItem(menu, client, page, MENU_TIME_FOREVER);
		}
		else
		{
			PrintToChat(client, "This weapon has no changeable attributes.");
			CloseHandle(menu);
			Menu_TweakUpgrades(client);
		}
	}
}
public Menu_TweakUpgrades(client)
{
	new Handle:menu = CreateMenu(MenuHandler_AttributesTweak);
	new s
	
	SetMenuExitBackButton(menu, true);
	
	SetMenuTitle(menu, "Display Upgrades Or Remove downgrades");
	for (s = 0; s < 5; s++)
	{
		decl String:fstr[100]
		
		Format(fstr, sizeof(fstr), "$%.0f of upgrades | Refund & Remove my %s attributes", client_spent_money[client][s], current_slot_name[s])
		AddMenuItem(menu, "tweak", fstr);
	}
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	return;
}
public Menu_ChangePreferences(client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		new Handle:menu = CreateMenu(MenuHandler_Preferences);
		
		SetMenuExitBackButton(menu, true);
		SetMenuTitle(menu, "Set Preferences");
		AddMenuItem(menu, "increaseX", "+1 X to armor hud.");
		AddMenuItem(menu, "decreaseX", "-1 X to armor hud.");
		AddMenuItem(menu, "increaseY", "+1 Y to armor hud.");
		AddMenuItem(menu, "decreaseY", "-1 Y to armor hud.");
		AddMenuItem(menu, "uurespawn", "Toggle buy menu on spawn.");
		AddMenuItem(menu, "disablewatermark", "Toggle watermark hud element.");
		AddMenuItem(menu, "particleToggle", "Toggle Self-Viewable Particles");
		AddMenuItem(menu, "resetTutorial", "Reset all tutorial HUD elements.");
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
	}
}
Menu_ShowWiki(client, int item = 0)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		new Handle:menu = CreateMenu(MenuHandler_Wiki);
		
		SetMenuExitBackButton(menu, true);
		SetMenuTitle(menu, "★ Uber Upgrades Revamped Wiki ★");
		AddMenuItem(menu, "UpgradeInfo", "Upgrades Walkthrough");
		AddMenuItem(menu, "DamageInfo", "Damage Math Walkthrough");
		AddMenuItem(menu, "ArmorInfo", "Armor Math Walkthrough");
		AddMenuItem(menu, "SpecialTweaksInfo", "Special Tweaks Walkthrough");
		AddMenuItem(menu, "SpecialAbilitiesInfo", "Special Abilities Explanation #1");
		AddMenuItem(menu, "SpecialAbilitiesInfo2", "Special Abilities Explanation #2");
		AddMenuItem(menu, "ArcaneInfo", "Arcane Walkthrough");
		AddMenuItem(menu, "ArcaneInfo2", "Arcane Spells #1");
		AddMenuItem(menu, "ArcaneInfo2", "Arcane Spells #2");
		AddMenuItem(menu, "ArcaneInfo3", "Class Specific Arcanes #1");
		AddMenuItem(menu, "ArcaneInfo4", "Class Specific Arcanes #2");
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			DisplayMenuAtItem(menu, client, item, MENU_TIME_FOREVER);
		}
	}
}
public Action:ShowMults(client, args)
{
	if(IsPlayerAlive(client))
	{
		Menu_ShowStatsMenu(client);
	}
	return Plugin_Handled;
}
public Menu_ShowStatsMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_StatsViewer);
	SetMenuExitBackButton(menu, true);
	SetMenuTitle(menu, "Display weapon stats by slot.");
	AddMenuItem(menu, "slot", "View stats for body");
	AddMenuItem(menu, "slot", "View stats for primary");
	AddMenuItem(menu, "slot", "View stats for secondary");
	AddMenuItem(menu, "slot", "View stats for melee");
	
	if (currentitem_level[client][3] == 242)
	{
		AddMenuItem(menu, "slot", "View stats for bought weapon");
	}
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		DisplayMenu(menu, client, 20);
	}
	return;
}
public Menu_ShowStats(client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		ClientCommand(client, "sm_stats");
	}
	return;
}
public CreateBuyNewWeaponMenu(client)
{
	new Handle:BuyNWmenu = CreateMenu(MenuHandler_ConfirmNewWeapon);
	
	SetMenuTitle(BuyNWmenu, "Buy A Custom Weapon:");
	SetMenuExitBackButton(BuyNWmenu, true);
	new i = 0;
	new it = 0;
	new String:strTotal[32];
	new String:playerClass[16]
	switch(current_class[client])
	{
		case TFClass_Scout:
		{
			playerClass = "scout"
		}
		case TFClass_Soldier:
		{
			playerClass = "soldier"
		}
		case TFClass_Pyro:
		{
			playerClass = "pyro"
		}
		case TFClass_DemoMan:
		{
			playerClass = "demo"
		}
		case TFClass_Heavy:
		{
			playerClass = "heavy"
		}
		case TFClass_Engineer:
		{
			playerClass = "engineer"
		}
		case TFClass_Medic:
		{
			playerClass = "medic"
		}
		case TFClass_Sniper:
		{
			playerClass = "sniper"
		}
		case TFClass_Spy:
		{
			playerClass = "spy"
		}
	}
	for (i = 0; i < upgrades_weapon_nb; i++)
	{
		if(StrContains(upgrades_weapon_class_restrictions[i],playerClass) != -1 || StrEqual(upgrades_weapon_class_restrictions[i],"none",false))
		{
			Format(strTotal, sizeof(strTotal), "%s | Costs $%.0f",upgrades_weapon[i],upgrades_weapon_cost[i]); 
			AddMenuItem(BuyNWmenu, "tweak", strTotal);
			buyableIndexOffParam[client][it] = i
			it++
		}
	}
	if(it == 0)
	{
		PrintToChat(client,"There aren't any custom weapons for this class yet.")
	}
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		DisplayMenu(BuyNWmenu, client, 20);
	}
}