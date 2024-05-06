public Action:DisplayCurrentUps(client, args)
{
	char arg1[64];
	int arg;
	if (GetCmdArg(1, arg1, sizeof(arg1)))
	{
		arg = StringToInt(arg1);
		if(IsValidClient(client) && client != 0)
		{
			TF2_AttribListAttributesBySlot(client,arg);
		}
	}
}
public Action:Command_ShowStats(client, args)
{
	char args2[64], strTarget[MAX_TARGET_LENGTH], target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count, slot;
	bool tn_is_ml;

	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int i = 0; i < target_count; ++i)
	{
		if(GetCmdArg(2, args2, sizeof(args2)))
		{
			slot = StringToInt(args2);
			if(IsValidClient3(target_list[i]) && IsPlayerAlive(target_list[i]))
			{
				TF2_AttribListAttributesBySlot(target_list[i], slot)
			}
		}
	}
	return Plugin_Handled;
}
public Action:Command_SetHealth(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_sethealth \"target\" \"amount\"");
		return Plugin_Handled;
	}
	char strTarget[MAX_TARGET_LENGTH], target_name[MAX_TARGET_LENGTH], strVal[128];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	GetCmdArg(2, strVal, sizeof(strVal));

	for(int i = 0; i < target_count; ++i)
	{
		SetEntityHealth(target_list[i], StringToInt(strVal));
	}
	return Plugin_Handled;
}
public Action:Command_SetCash(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setcash \"target\" \"amount\"");
		return Plugin_Handled;
	}
	char strTarget[MAX_TARGET_LENGTH], target_name[MAX_TARGET_LENGTH], strVal[128];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	float GivenCash;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, strVal, sizeof(strVal));
	GivenCash = StringToFloat(strVal);

	for(int i = 0; i < target_count; ++i)
	{
		CurrencyOwned[target_list[i]] = GivenCash;
	}
	return Plugin_Handled;
}
public Action:Command_AddCash(client, args)
{
	
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addcash \"target\" \"amount\"");
		return Plugin_Handled;
	}

	char strTarget[MAX_TARGET_LENGTH], target_name[MAX_TARGET_LENGTH], strVal[128];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	float GivenCash;

	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	GetCmdArg(2, strVal, sizeof(strVal));
	GivenCash = StringToFloat(strVal);
	for(int i = 0; i < target_count; ++i)
	{
		
		CurrencyOwned[target_list[i]] += GivenCash;
	}
	return Plugin_Handled;
}
public Action:Command_RemoveCash(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removecash \"target\" \"amount\"");
		return Plugin_Handled;
	}
	char strTarget[MAX_TARGET_LENGTH], target_name[MAX_TARGET_LENGTH], strVal[128];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	float GivenCash;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, strVal, sizeof(strVal));
	GivenCash = StringToFloat(strVal);

	for(int i = 0; i < target_count; ++i)
	{
		CurrencyOwned[target_list[i]] -= GivenCash;
	}
	return Plugin_Handled;
}
public Action:Command_SetIFAdmin(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setifadmin \"target\" \"bool\"");
		return Plugin_Handled;
	}
	char strTarget[MAX_TARGET_LENGTH], target_name[MAX_TARGET_LENGTH], strToggle[64];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml, toggle;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, strToggle, sizeof(strToggle));
	toggle = view_as<bool>(StringToInt(strToggle));

	for(int i = 0; i < target_count; ++i)
	{
		canBypassRestriction[target_list[i]] = toggle;
	}
	return Plugin_Handled;
}
public Action:ShowHelp(client, args)
{
	if(IsValidClient3(client))
	{
		CPrintToChat(client, "{gray}Help | {gold}This server is running Incremental Fortress v%s", PLUGIN_VERSION);
		if(!IsMvM())
		{
			CPrintToChat(client, "{gray}Help | {gold}/votemenu can be used to adjust how many bots and how difficult they are.")
		}
	}
	return Plugin_Handled;
}
public Action:AdjustHud(client, args)
{
	if(IsValidClient3(client))
	{
		char args1[128];
		char args2[128];
		if(GetCmdArg(1, args1, sizeof(args1)))
		{
			SetClientCookie(client, hArmorXPos, args1);
		}
		if(GetCmdArg(2, args2, sizeof(args2)))
		{
			SetClientCookie(client, hArmorYPos, args2);
		}
	}
	else
	{
		PrintToChat(client, "Invalid Client");
	}
	return Plugin_Handled;
}
public Action:Menu_QuickBuyUpgrade(client, args)
{
	/*
	char arg1[32];
	int arg1_ = -1;
	char arg2[32];
	int arg2_ = -1;
	char arg3[32];
	int arg3_ = -1;
	char arg4[32];
	int arg3_ = -1;
	char arg5[32];
	int arg5_ = 0;
	new	bool:flag = false
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (GetCmdArg(1, arg1, sizeof(arg1)))
		{
			arg2_ = -1
			arg3_ = -1
			if(!strcmp("1", arg1)){
			arg1_ = 4;
			}
			if(!strcmp("2", arg1)){
			arg1_ = 0;
			}
			if(!strcmp("3", arg1)){
			arg1_ = 1;
			}
			if(!strcmp("4", arg1)){
			arg1_ = 2;
			}
			if(!strcmp("5", arg1)){
			arg1_ = 3;
			}
			if (arg1_ > -1 && arg1_ < 6 && GetCmdArg(2, arg2, sizeof(arg2)))
			{
				int w_id = currentitem_catidx[client][arg1_]
				arg2_ = StringToInt(arg2)-1;
				if (GetCmdArg(3, arg3, sizeof(arg3)))
				{
					arg3_ = StringToInt(arg3)-1;
					arg5_ = 1


					if (GetCmdArg(5, arg5, sizeof(arg5)))
					{
						arg5_ = StringToInt(arg5);
						if (arg5_ >= 100000)
						{
							arg5_ = 100000
						}
						if (arg5_ < 1)
						{
							arg5_ = 1
						}
					}
					if(arg2_ <= -1)
						arg2_ = 0
					if(arg3_ <= -1)
						arg3_ = 0
					if(arg2_ >= 127)
						arg2_ = 127
					if(arg3_ >= 127)
						arg3_ = 127
					refreshUpgrades(client, arg1_)
					if(w_id != -1 && arg2_ == given_upgrd_classnames_tweak_idx[w_id])
					{
						int loopBroke = 0;
						int got_req = 1
						int spTweak = given_upgrd_list[w_id][arg2_][arg3_]
						if(upgrades_tweaks_requirement[spTweak] <= client_spent_money[client][arg1_])
						{
							if(upgrades_tweaks_requirement[spTweak] > 1.0 && client_tweak_highest_requirement[client][arg1_] < upgrades_tweaks_requirement[spTweak])
							{
								client_tweak_highest_requirement[client][arg1_] = upgrades_tweaks_requirement[spTweak];
							}
							for(int timesUpgraded = 0; timesUpgraded < arg5_ && loopBroke == 0; timesUpgraded++)
							{
								if(CurrencyOwned[client] >= upgrades_tweaks_cost[spTweak])
								{
									for (int i = 0; i < upgrades_tweaks_nb_att[spTweak]; ++i)
									{
										int upgrade_choice = upgrades_tweaks_att_idx[spTweak][i]
										int inum = upgrades_ref_to_idx[client][arg1_][upgrade_choice]
										if (inum != 20000)
										{
											if (currentupgrades_val[client][arg1_][inum] == upgrades_m_val[upgrade_choice])
											{
												got_req = 0;
												loopBroke = 1;
											}
										}
										else
										{
											if (currentupgrades_number[client][arg1_] + upgrades_tweaks_nb_att[spTweak] >= MAX_ATTRIBUTES_ITEM)
											{
												got_req = 0;
												loopBroke = 1;
											}
										}
									}
									if (got_req)
									{
										for (int i = 0; i < upgrades_tweaks_nb_att[spTweak]; ++i)
										{
											int upgrade_choice = upgrades_tweaks_att_idx[spTweak][i]
											UpgradeItem(client, upgrade_choice, upgrades_ref_to_idx[client][arg1_][upgrade_choice], upgrades_tweaks_att_ratio[spTweak][i], arg1_)
											CurrencyOwned[client] -= upgrades_tweaks_cost[spTweak];
											client_spent_money[client][arg1_] += upgrades_tweaks_cost[spTweak]
										}
										GiveNewUpgradedWeapon_(client, arg1_)
									}
								}
								else
								{
									got_req = 0;
									loopBroke = 1;
								}
							}
							if(got_req)
							{
								PrintToChat(client, "Qbuy successful.")
							}
							else
							{
								PrintToChat(client, "Qbuy failed.")
							}
						}
						else
						{
							PrintToChat(client, "You must spend more on the slot to use this tweak.");
						}
						return Plugin_Handled;
					}
					if(arg1_ == 5)
					{
						if (arg3_ >= 0)
						{
							int u = currentupgrades_idx[client][arg2_][arg3_]
							if (u != 20000)
							{
								if (upgrades_costs[u] < -0.1)
								{
									int nb_time_upgraded = RoundToNearest((upgrades_i_val[u] - currentupgrades_val[client][arg2_][arg3_]) / upgrades_ratio[u])
									float up_cost = upgrades_costs[u] * nb_time_upgraded * 3.0
									if(up_cost > 200.0)
									{
										if (CurrencyOwned[client] >= up_cost)
										{
											remove_attribute(client, arg3_)
											CurrencyOwned[client] -= up_cost;
											client_spent_money[client][arg1_] += up_cost
											PrintToChat(client, "Attribute removed.")
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
									int nb_time_upgraded;
									if(currentupgrades_i[client][arg2_][arg3_] != 0.0)
									{
										nb_time_upgraded = RoundToNearest((currentupgrades_i[client][arg2_][arg3_] - currentupgrades_val[client][arg2_][arg3_]) / upgrades_ratio[u])
									}
									else
									{
										nb_time_upgraded = RoundToNearest((upgrades_i_val[u] - currentupgrades_val[client][arg2_][arg3_]) / upgrades_ratio[u])
									}
									nb_time_upgraded *= -1
									float up_cost = ((upgrades_costs[u]+((upgrades_costs_inc_ratio[u]*upgrades_costs[u])*(nb_time_upgraded-1))/2)*nb_time_upgraded)
									up_cost /= 2
									if(arg2_ == 1)
										up_cost *= SecondaryCostReduction;
										
									if(up_cost > 200.0)
									{
										if(client_spent_money[client][arg1_] - up_cost > client_tweak_highest_requirement[client][arg1_] - 1.0)
										{
											remove_attribute(client, arg3_)
											CurrencyOwned[client] += up_cost;
											client_spent_money[client][arg1_] -= up_cost
											PrintToChat(client, "Attribute refunded.")
										}
										else
										{
											PrintToChat(client, "You cannot go below money spent of tweaks bought that have requirements. Highest Requirement is %.0f", client_tweak_highest_requirement[client][arg1_]);
											EmitSoundToClient(client, SOUND_FAIL);
										}
									}
								}
							}
						}
						return Plugin_Handled;
					}
					if (arg2_ > -1 && arg2_ < given_upgrd_list_nb[w_id] && given_upgrd_list[w_id][arg2_][arg3_])
					{
						int upgrade_choice = given_upgrd_list[w_id][arg2_][arg3_]
						int inum = upgrades_ref_to_idx[client][arg1_][upgrade_choice]
						
						if (inum == 20000)
						{
							if(upgrades_restriction_category[upgrade_choice] != 0)
							{
								for(int i = 1;i<5;++i)
								{
									if(currentupgrades_restriction[client][arg1_][i] == upgrades_restriction_category[upgrade_choice])
									{
										PrintToChat(client, "You already have something that fits this restriction category.");
										EmitSoundToClient(client, SOUND_FAIL);
										return Plugin_Handled;
									}
								}
								currentupgrades_restriction[client][arg1_][upgrades_restriction_category[upgrade_choice]] = upgrades_restriction_category[upgrade_choice];
							}
							inum = currentupgrades_number[client][arg1_]
							currentupgrades_number[client][arg1_]++
							upgrades_ref_to_idx[client][arg1_][upgrade_choice] = inum;
							currentupgrades_idx[client][arg1_][inum] = upgrade_choice 
							currentupgrades_val[client][arg1_][inum] = upgrades_i_val[upgrade_choice];
						}
						else if(currentupgrades_val[client][arg1_][inum] - upgrades_i_val[upgrade_choice] == 0.0 && upgrades_restriction_category[upgrade_choice] != 0)
						{
							for(int i = 1;i<5;++i)
							{
								if(currentupgrades_restriction[client][arg1_][i] == upgrades_restriction_category[upgrade_choice])
								{
									PrintToChat(client, "You already have something that fits this restriction category.");
									EmitSoundToClient(client, SOUND_FAIL);
									return Plugin_Handled;
								}
							}
							currentupgrades_restriction[client][arg1_][upgrades_restriction_category[upgrade_choice]] = upgrades_restriction_category[upgrade_choice];
						}
						int idx_currentupgrades_val
						if(currentupgrades_i[client][arg1_][inum] != 0.0){
							idx_currentupgrades_val = RoundFloat((currentupgrades_val[client][arg1_][inum] - currentupgrades_i[client][arg1_][inum])/ upgrades_ratio[upgrade_choice])
						}
						else{
							idx_currentupgrades_val = RoundFloat((currentupgrades_val[client][arg1_][inum] - upgrades_i_val[upgrade_choice])/ upgrades_ratio[upgrade_choice])
						}
						float upgrades_val = currentupgrades_val[client][arg1_][inum];
						float up_cost = float(upgrades_costs[upgrade_choice]);
						up_cost /= 2.0;
						if (arg1_ == 1)
						{
							up_cost = (up_cost * 1.0) * SecondaryCostReduction;
						}
						if (inum != 20000 && upgrades_ratio[upgrade_choice])
						{
							float t_up_cost = 0.0;
							int times = 0;
							bool notEnough = false;
							for (int idx = 0; idx < arg5_; idx++)
							{
								float nextcost = t_up_cost + up_cost + up_cost * (idx_currentupgrades_val * upgrades_costs_inc_ratio[upgrade_choice])
								if(nextcost < CurrencyOwned[client] && upgrades_ratio[upgrade_choice] > 0.0 && RoundFloat(upgrades_val*100.0)/100.0 < upgrades_m_val[upgrade_choice])
								{
									t_up_cost += up_cost + RoundFloat(up_cost * (idx_currentupgrades_val* upgrades_costs_inc_ratio[upgrade_choice]))
									idx_currentupgrades_val++		
									upgrades_val += upgrades_ratio[upgrade_choice]
									times++;
								}
								if(nextcost < CurrencyOwned[client] && upgrades_ratio[upgrade_choice] < 0.0 && RoundFloat(upgrades_val*100.0)/100.0 > upgrades_m_val[upgrade_choice])
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
							flag = true
							CurrencyOwned[client] -= t_up_cost;
							currentupgrades_val[client][arg1_][inum] = upgrades_val
							check_apply_maxvalue(client, arg1_, inum, upgrade_choice)
							client_spent_money[client][arg1_] += t_up_cost
							GiveNewUpgradedWeapon_(client, arg1_)
							PrintToChat(client, "You bought %t %i times.",upgradesNames[upgrade_choice],times);
						}
					}
				}
			}
		}
		if (!flag)
		{
			ReplyToCommand(client, "Usage: /qbuy [Slot #] [Category #] [Upgrade #] [# to buy]");
			ReplyToCommand(client, "Example : /qbuy 1 1 1 100 = buy health 100 times.");
			ReplyToCommand(client, "Example : /qbuy 2 1 1 100 = buy damage on primary 100 times.");
		}
	}
	else
	{
		ReplyToCommand(client, "You cannot quick-buy while dead.");
	}
	*/
	return Plugin_Handled;
}
public Action:ReloadCfgFiles(client, args)
{
	CreateTimer(0.1, Timer_WaitForTF2Econ, _);	   
	for (int cl = 0; cl <= MaxClients; cl++)
	{
		if(IsValidClient3(cl))
		{
			current_class[cl] = TF2_GetPlayerClass(cl)
			
			if (!client_respawn_handled[cl])
			{
				CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(cl));
			}
		}
	}
	return Plugin_Handled;
}
public Action jointeam_callback(client, const char[] command, argc) 
{
	CancelClientMenu(client);

	return Plugin_Continue;
}
public Action:ResetPlayers(client, args)
{
	for (int i = 1; i <= MaxClients; ++i) 
	{ 
		if (IsClientInGame(i)) 
		{
			ResetClientUpgrades(i);
		} 
	}
	additionalstartmoney = 0.0;
	return Plugin_Handled;
}
public Action:GiveAllMoney(client, args)
{
	char arg1[128];
	float arg;
	if(GetCmdArg(1, arg1, sizeof(arg1)))
	{
		arg = StringToFloat(arg1);
		for (int i = 0; i <= MaxClients; ++i) 
		{ 
			CurrencyOwned[i] = arg;
		}
	}
	return Plugin_Handled;
}

public Action:ShowSpentMoney(client, args)
{
	for(int i = 0; i <= MaxClients; ++i)
	{
		if (IsValidClient(i))
		{
			char cstr[255]
			GetClientName(i, cstr, 255)
			PrintToChat(client, "**%s**\n**", cstr)
			for (int s = 0; s < 5; s++)
			{
				PrintToChat(client, "%s : $%d of upgrades", current_slot_name[s], client_spent_money[i][s])
			}
		}
	}
	return Plugin_Handled;
}
public Action:ShowStats(client, args)
{
	for(int i = 0; i <= MaxClients; ++i)
	{
		if (IsValidClient(i))
		{
			char cstr[255]
			GetClientName(i, cstr, 255)
			PrintToConsole(client, "\n%s:\n--------------\nHealed: %.0f\nDamage: %.0f\nKills: %d\nDeaths: %d\n", cstr, Healed[i], DamageDealt[i], Kills[i], Deaths[i])
		}
	}
	PrintToChat(client, "Output is in console.");
	return Plugin_Handled;
}
public Action:ShowTeamMoneyRatio(admid, args)
{
	for(int i = 0; i <= MaxClients; ++i)
	{
		if (IsValidClient(i))
		{
			char cstr[255]
			GetClientName(i, cstr, 255)
			PrintToChat(admid, "**%s**\n**", cstr)
			for (int s = 0; s < 5; s++)
			{
				PrintToChat(admid, "%s : $%.0f of upgrades", current_slot_name[s], client_spent_money[i][s])
			}
		}
	}
	return Plugin_Handled;
}
public Action:TestCommand(client, args)
{
	for(int s = 0; s < NB_SLOTS_UED; s++)
	{
		PrintToChat(client, "---Slot #%i---",s);
		for(int i = 0; i < MAX_ATTRIBUTES_ITEM; ++i)
		{
			PrintToChat(client, "currentUpgradesIDX %i", currentupgrades_idx[client][s][i]);
			PrintToChat(client, "upgrades_ref_to_idx %i", upgrades_ref_to_idx[client][s][currentupgrades_idx[client][s][i]]);
			PrintToChat(client, "currentUpgradesVal %.2f", currentupgrades_val[client][s][i]);
		}
		PrintToChat(client, "currentUpgradesNumber %i", currentupgrades_number[client][s]);
		PrintToChat(client, "clientSpentMoney %.2f", client_spent_money[client][s]);
		PrintToChat(client, "currentitem_idx %i", currentitem_idx[client][s]);
		PrintToChat(client, "currentitem_level %i", currentitem_level[client][s]);
	}
	return Plugin_Handled;
}

public OnCvarChanged(Handle cvar, const char[] oldVal, const char[] newVal)
{
	if(cvar == cvar_MoneyBonusKill)
		MoneyBonusKill = GetConVarFloat(cvar_MoneyBonusKill);
	else if(cvar == cvar_ServerMoneyMult)
		ServerMoneyMult = GetConVarFloat(cvar_ServerMoneyMult);
	else if(cvar == cvar_BotMultiplier){
		OverAllMultiplier = GetConVarFloat(cvar_BotMultiplier);
		for(int i=1;i<=MaxClients;++i){
			if(IsValidClient3(i) && IsFakeClient(i)){
				ForcePlayerSuicide(i);
			}
		}
	}
	else if(cvar == cvar_DisableBotUpgrade){
		DisableBotUpgrades = GetConVarInt(cvar_DisableBotUpgrade);
		for(int i=1;i<=MaxClients;++i){
			if(IsValidClient3(i) && IsFakeClient(i)){
				ForcePlayerSuicide(i);
			}
		}
	}
	else if(cvar == cvar_StartMoney){
		StartMoney = GetConVarFloat(cvar_StartMoney);
		CheckForGamestage();
	}
	else if(cvar == cvar_DisableCooldowns){
		DisableCooldowns = GetConVarInt(cvar_DisableCooldowns);
		for(int client=1;client<=MaxClients;client++){
			if(IsValidClient(client)){
				if(CheckForAttunement(client)){
					for(int i = 0; i < Max_Attunement_Slots;++i){
						SpellCooldowns[client][i] = 0.0;
					}
				}
			}
		}
	}
	else if(cvar == cvar_debug){
		debugMode = view_as<bool>(GetConVarInt(cvar_debug));
	}
	else if(cvar == cvar_InfiniteMoney){
		infiniteMoney = view_as<bool>(GetConVarInt(cvar_InfiniteMoney));
	}
}
public Action Command_DealDamage(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_damage \"target\" \"amount\"");
		return Plugin_Handled;
	}
	char strTarget[MAX_TARGET_LENGTH], target_name[MAX_TARGET_LENGTH], strDmg[64];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	float Damage;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, strDmg, sizeof(strDmg));
	Damage = StringToFloat(strDmg);	
	for(int i = 0; i < target_count; ++i)
	{
		if(IsValidClient3(target_list[i]))
		{
			RadiationBuildup[target_list[i]] += Damage;
		}
	}
	return Plugin_Handled;
}
public Action:Command_GiveKills(client, args)
{
	char args3[128];
	int kills;
	int victim;
	
	char strTarget[MAX_TARGET_LENGTH], target_name[MAX_TARGET_LENGTH]
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	char strTarget2[MAX_TARGET_LENGTH], target_name2[MAX_TARGET_LENGTH];
	int target_list2[MAXPLAYERS], target_count2;
	bool tn_is_ml2;
	GetCmdArg(2, strTarget2, sizeof(strTarget2));
	if((target_count2 = ProcessTargetString(strTarget2, client, target_list2, MAXPLAYERS, 0, target_name2, sizeof(target_name2), tn_is_ml2)) <= 0)
	{
		ReplyToTargetError(client, target_count2);
		return Plugin_Handled;
	}
	
	PrintToServer("Attempting to give kills.");
	for(int i = 0; i < target_count; ++i)
	{
		if(GetCmdArg(3, args3, sizeof(args3)) && IsValidClient3(target_list[i]) && IsValidClient3(target_list2[i]))
		{
			victim = target_list2[i];
			kills = StringToInt(args3);
			PrintToServer("Attempting to give %i kills to %N. %N is the victim.",kills,target_list[i],target_list2[i]);
			if(IsValidClient3(target_list[i]) && IsPlayerAlive(target_list[i]) && IsValidClient3(victim) && IsPlayerAlive(victim))
			{
				Handle datapack = CreateDataPack();
				WritePackCell(datapack,EntIndexToEntRef(victim));
				WritePackCell(datapack,EntIndexToEntRef(target_list[i]));
				CreateTimer(0.1,Timer_KillPlayer,datapack);
				StrangeFarming[victim][target_list[i]] = kills;
				PrintToServer("Giving %i kills to %N. %N is the victim.",kills,target_list[i],victim);
			}
		}
	}
	return Plugin_Handled;
}

public Action Command_AutoOptimize(int client, int args){
	char strTarget[MAX_TARGET_LENGTH], target_name[MAX_TARGET_LENGTH]
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	int slot = GetCmdArgInt(2);
	
	for(int i = 0; i < target_count; ++i)
	{
		if(!IsValidClient3(target_list[i]))
			continue;

		PrintToServer("Auto-optimizing for %N", client);
		int upgrade_choice
		int w_id = currentitem_catidx[target_list[i]][slot];
		bool escape = false;
		for(int ii = 0; ii< LISTS_CATEGORIES;++ii){
			if(escape)
				break;

			for(int iii = 0; iii< MAX_ATTRIBUTES_ITEM;++iii){
				if(escape)
					break;

				if(upgrades_efficiency_list[target_list[i]][slot][given_upgrd_list[w_id][ii][0][iii]] == 1){
					upgrade_choice = given_upgrd_list[w_id][ii][0][iii];
					escape = true;
				}
			}
		}

		int inum = upgrades_ref_to_idx[target_list[i]][slot][upgrade_choice]

		while(is_client_got_req(target_list[i], upgrade_choice, slot, inum)){
			UpgradeItem(target_list[i], upgrade_choice, inum, 1.0, slot)

			int numEff = 0;
			for(int e=0;e<MAX_ATTRIBUTES;++e)
			{
				if(upgrades_efficiency[target_list[i]][slot][e])
					++numEff;
			}
			float max = 0.0;
			int highestIndex = 0;
			bool toBlock[MAX_ATTRIBUTES];
			for(int k=0;k<numEff;++k){
				for(int t=0;t<MAX_ATTRIBUTES;++t)
				{
					int tempNum = upgrades_ref_to_idx[target_list[i]][slot][t];
					if(tempNum == 20000)
						continue;

					float val = currentupgrades_val[target_list[i]][slot][tempNum];
					int up_cost = upgrades[t].cost;
					up_cost += RoundFloat(up_cost * (val / upgrades[t].ratio) * upgrades[t].cost_inc_ratio)
					if (up_cost < 0.0)
					{
						up_cost *= -1;
						if (up_cost < upgrades[t].cost)
							up_cost = upgrades[t].cost
					}

					switch(upgrades[t].display_style)
					{
						case 1:
						{
							if(val == 0.0)
								val = upgrades[t].i_val;
		
							upgrades_efficiency[client][slot][t] = 50000.0*(((val+upgrades[t].ratio)/val)-1.0)/up_cost;
						}
						case 6:
						{
							if(val == 0.0)
								val = upgrades[t].i_val;
							upgrades_efficiency[client][slot][t] = 50000.0*(0.05)/up_cost;
						}
					}
				}
			}

			for(int k=0;k<numEff;++k) 
			{
				for(int t=0;t<MAX_ATTRIBUTES;++t)
				{
					int tempNum = upgrades_ref_to_idx[target_list[i]][slot][t];
					if(tempNum == 20000)
						continue;

					if(RoundFloat(currentupgrades_val[target_list[i]][slot][tempNum]*100) == RoundFloat(upgrades[t].m_val * 100))
					{
						toBlock[t] = true;
						upgrades_efficiency_list[target_list[i]][slot][t] = 0;
						upgrades_efficiency[target_list[i]][slot][t] = 0.0;
					}

					if(!toBlock[t] && upgrades_efficiency[target_list[i]][slot][t])
					{
						if(upgrades_efficiency[target_list[i]][slot][t] > max)
						{
							max = upgrades_efficiency[target_list[i]][slot][t]
							highestIndex = t;
						}
					}
				}
				max = 0.0;
				toBlock[highestIndex] = true;
				upgrades_efficiency_list[target_list[i]][slot][highestIndex] = k+1;
			}

			escape = false;
			for(int ii = 0; ii< LISTS_CATEGORIES;++ii){
				if(escape)
					break;

				for(int iii = 0; iii< MAX_ATTRIBUTES_ITEM;++iii){
					if(escape)
						break;

					if(upgrades_efficiency_list[target_list[i]][slot][given_upgrd_list[w_id][ii][0][iii]] == 1){
						upgrade_choice = given_upgrd_list[w_id][ii][0][iii];
						escape = true;
					}
				}
			}
			inum = upgrades_ref_to_idx[target_list[i]][slot][upgrade_choice];
		}
	}

	return Plugin_Handled;
}