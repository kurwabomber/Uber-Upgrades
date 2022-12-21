GetWeaponsCatKVSize(Handle:kv)
{
	new siz = 0
	do
	{
		if (!KvGotoFirstSubKey(kv, false))
		{
			
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				siz++
			}
		}
	}
	while (KvGotoNextKey(kv, false));
	return siz
}

BrowseWeaponsCatKV(Handle:kv)
{
	new u_id = 0
	new t_idx = 0
	SetTrieValue(_weaponlist_names, "body_scout" , t_idx, true);
	t_idx++;
	SetTrieValue(_weaponlist_names, "body_sniper" , t_idx, true);
	t_idx++;
	SetTrieValue(_weaponlist_names, "body_soldier" , t_idx, true);
	t_idx++;
	SetTrieValue(_weaponlist_names, "body_demoman" , t_idx, true);
	t_idx++;
	SetTrieValue(_weaponlist_names, "body_medic" , t_idx, true);
	t_idx++;
	SetTrieValue(_weaponlist_names, "body_heavy" , t_idx, true);
	t_idx++;
	SetTrieValue(_weaponlist_names, "body_pyro" , t_idx, true);
	t_idx++;
	SetTrieValue(_weaponlist_names, "body_spy" , t_idx, true);
	t_idx++;
	SetTrieValue(_weaponlist_names, "body_engie" , t_idx, true);
	t_idx++;
	decl String:Buf[128];
	do
	{
		if (KvGotoFirstSubKey(kv, false))
		{
			BrowseWeaponsCatKV(kv);
			KvGoBack(kv);
		}
		else
		{
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				KvGetSectionName(kv, Buf, sizeof(Buf));
				wcnamelist[u_id] = Buf
				KvGetString(kv, "", Buf, 64);
				if (SetTrieValue(_weaponlist_names, Buf, t_idx, false))
				{
					t_idx++
				}
				GetTrieValue(_weaponlist_names, Buf, wcname_l_idx[u_id])
				
				u_id++;
				
				
			}
		}
	}
	while (KvGotoNextKey(kv, false));
}

BrowseAttributesKV(Handle:kv)
{
	decl String:Buf[512];
	do
	{
		if (KvGotoFirstSubKey(kv, false))
		{
			
			BrowseAttributesKV(kv);
			KvGoBack(kv);
		}
		else
		{
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				KvGetSectionName(kv, Buf, sizeof(Buf));
				if (!strcmp(Buf,"ref"))
				{
					KvGetString(kv, "", Buf, 64);
					strcopy(upgradesNames[_u_id], 64, Buf);
					SetTrieValue(_upg_names, Buf, _u_id, true);
				
				}
				else if (!strcmp(Buf,"name"))
				{
					KvGetString(kv, "", Buf, 64);
					if (strcmp(Buf,""))
					{
						
						
						for (new i_ = 1; i_ < MAX_ATTRIBUTES; i_++)
						{
							if (!strcmp(upgradesWorkNames[i_], Buf))
							{
								upgrades_to_a_id[_u_id] = i_
							
								break;
							}
						}
					}
				}
				else if (!strcmp(Buf,"cost"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_costs[_u_id] = StringToInt(Buf)
				}
				else if (!strcmp(Buf,"increase_ratio"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_costs_inc_ratio[_u_id] = StringToFloat(Buf)
				}
				else if (!strcmp(Buf,"value"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_ratio[_u_id] = StringToFloat(Buf)
				}
				else if (!strcmp(Buf,"init"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_i_val[_u_id] = StringToFloat(Buf)
				}
				else if(!strcmp(Buf,"restriction_category"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_restriction_category[_u_id] = StringToInt(Buf)
				}
				else if(!strcmp(Buf,"display_style"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_display_style[_u_id] = StringToInt(Buf)
				}
				else if(!strcmp(Buf,"description"))
				{
					KvGetString(kv, "", Buf, 512);
					upgrades_description[_u_id] = Buf;
				}
				else if(!strcmp(Buf,"requirement"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_requirement[_u_id] = StringToFloat(Buf);
				}
				else if(!strcmp(Buf, "staged_max"))
				{
					KvGetString(kv, "", Buf, 512);
					char parts[MAX_STAGES][256];
					int it = ExplodeString(Buf, ",", parts, MAX_STAGES, 256);

					for(int i = 1;i<it;i++)
					{
						//PrintToServer("Stage %i | Set to %.2f max.", i, StringToFloat(parts[i])) //it works :D
						upgrades_staged_max[_u_id][i] = StringToFloat(parts[i-1]);
					}
				}
				else if (!strcmp(Buf,"max"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_m_val[_u_id] = StringToFloat(Buf)
					upgrades_staged_max[_u_id][0] = upgrades_m_val[_u_id]
					_u_id++//Finish the attribute here.
				}
			}
		}
	}
	while (KvGotoNextKey(kv, false));
	return (_u_id)
}


BrowseAttListKV(Handle:kv, &w_id = -1, &w_sub_id = -1, &w_subcat_id = 0,w_sub_att_idx = -1, level = 0)
{
	decl String:Buf[128];
	do
	{
		new bool:incrementLater = false;
		KvGetSectionName(kv, Buf, sizeof(Buf));
		if (level == 1)
		{
			if (!GetTrieValue(_weaponlist_names, Buf, w_id))
			{
				PrintToServer("[uu_lists] Malformated uu_lists | uu_weapon.txt file?: %s was not found", Buf)
			}
			w_sub_id = -1;
			w_subcat_id = 0;
			given_upgrd_classnames_tweak_nb[w_id] = 0
		}
		if (level == 2)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf))
			if (!strcmp(Buf, "special_tweaks_listid"))
			{
				KvGetString(kv, "", Buf, 64);
				
				given_upgrd_classnames_tweak_idx[w_id] = StringToInt(Buf)
			}
			else
			{
				w_sub_id++
			
				given_upgrd_classnames[w_id][w_sub_id] = Buf;
				given_upgrd_list_nb[w_id]++;
				w_sub_att_idx = 0;
				w_subcat_id = 0;
			}
		}
		if(level == 3)
		{
			if(StrContains(Buf, "!") != -1)
			{
				incrementLater = true;
				given_upgrd_subclassnames[w_id][w_sub_id][w_subcat_id] = Buf;
				given_upgrd_subcat[w_id][w_sub_id]++;
				given_upgrd_subcat_nb[w_id][w_sub_id]++;
				w_sub_att_idx = 0;
			}
		}
		if (KvGotoFirstSubKey(kv, false))
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			BrowseAttListKV(kv, w_id, w_sub_id, w_subcat_id, w_sub_att_idx, level + 1);
			KvGoBack(kv);
		}
		else
		{
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				new attr_id
				KvGetSectionName(kv, Buf, sizeof(Buf));
			
				if (strcmp(Buf, "special_tweaks_listid"))
				{
					KvGetString(kv, "", Buf, 64);
					if (w_sub_id == given_upgrd_classnames_tweak_idx[w_id])
					{
						given_upgrd_classnames_tweak_nb[w_id]++
						if (!GetTrieValue(_spetweaks_names, Buf, attr_id))
						{
							PrintToServer("[uu_specialtweaks] Malformated uu_specialtweaks | uu_specialtweaks.txt file?: %s was not found", Buf)
						}
					}
					else
					{
						if (!GetTrieValue(_upg_names, Buf, attr_id))
						{
							PrintToServer("[uu_specialtweaks] Malformated uu_attributes | uu_attributes.txt file?: %s was not found", Buf)
						}
					}
					given_upgrd_list[w_id][w_sub_id][w_subcat_id][w_sub_att_idx] = attr_id
					w_sub_att_idx++
				}
			}
		}
		if(incrementLater)
			w_subcat_id++;
	}
	while (KvGotoNextKey(kv, false));
}
BrowseSpeTweaksKV(Handle:kv, &u_id = -1, att_id = -1, level = 0)
{
	decl String:Buf[128];
	new attr_ref
	do
	{
		if (level == 2)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			u_id++
			SetTrieValue(_spetweaks_names, Buf, u_id)
			upgrades_tweaks[u_id] = Buf
			upgrades_tweaks_nb_att[u_id] = 0
			upgrades_tweaks_requirement[u_id] = 0.0;
			upgrades_tweaks_cost[u_id] = 0.0;
			att_id = 0
		}
		if (level == 3)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			if(!strcmp("requirement", Buf))
			{
				KvGetString(kv, "", Buf, 64);
				upgrades_tweaks_requirement[u_id] = StringToFloat(Buf)
			}
			else if(!strcmp("cost", Buf))
			{
				KvGetString(kv, "", Buf, 64);
				upgrades_tweaks_cost[u_id] = StringToFloat(Buf)
			}
			else
			{
				if (!GetTrieValue(_upg_names, Buf, attr_ref))
				{
					PrintToServer("[spetw_lists] Malformated uu_specialtweaks | uu_attribute.txt file?: %s was not found", Buf)
				}
				
				upgrades_tweaks_att_idx[u_id][att_id] = attr_ref
				KvGetString(kv, "", Buf, 64);
				upgrades_tweaks_att_ratio[u_id][att_id] = StringToFloat(Buf)
				
				upgrades_tweaks_nb_att[u_id]++
				att_id++
			}
		}
		if (KvGotoFirstSubKey(kv, false))
		{
			BrowseSpeTweaksKV(kv, u_id, att_id, level + 1);
			KvGoBack(kv);
		}
	}
	while (KvGotoNextKey(kv, false));
	return (u_id)
}
BrowseWeaponsListKV(Handle:kv, &u_id = -1, att_id = -1, level = 0)
{
	decl String:Buf[128];
	new attr_ref
	do
	{
		if (level == 1)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			u_id++
			upgrades_weapon_nb++
			upgrades_weapon[u_id] = Buf
			upgrades_weapon_nb_att[u_id] = 0
			att_id = 0
			PrintToServer("Adding custom weapon | %s. | #%i",upgrades_weapon[u_id], u_id)
		}
		if (level == 2)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			if(!strcmp("index", Buf))
			{
				KvGetString(kv, "", Buf, 64);
				upgrades_weapon_index[u_id] = StringToInt(Buf)
			}
			else if(!strcmp("cost", Buf))
			{
				KvGetString(kv, "", Buf, 64);
				upgrades_weapon_cost[u_id] = StringToFloat(Buf)
			}
			else if(!strcmp("weapon_class", Buf))
			{
				KvGetString(kv, "", Buf, 64);
				upgrades_weapon_class[u_id] = Buf
			}
			else if(!strcmp("weapon_menu", Buf))
			{
				KvGetString(kv, "", Buf, 64);
				upgrades_weapon_class_menu[u_id] = Buf
			}
			else if(!strcmp("description", Buf))
			{
				decl String:Description[512];
				KvGetString(kv, "", Description, 512);
				upgrades_weapon_description[u_id] = Description
			}
			else if(!strcmp("class", Buf))
			{
				KvGetString(kv, "", Buf, 64);
				upgrades_weapon_class_restrictions[u_id] = Buf
			}
			else
			{
				if (!GetTrieValue(_upg_names, Buf, attr_ref))
				{
					PrintToServer("[spetw_lists] Malformated uu_buyableweapons | uu_attribute.txt file?: %s was not found", Buf)
				}
				
				upgrades_weapon_att_idx[u_id][att_id] = attr_ref
				KvGetString(kv, "", Buf, 64);
				upgrades_weapon_att_amt[u_id][att_id] = StringToFloat(Buf)
				
				upgrades_weapon_nb_att[u_id]++
				att_id++
			}
		}
		if (KvGotoFirstSubKey(kv, false))
		{
			BrowseWeaponsListKV(kv, u_id, att_id, level + 1);
			KvGoBack(kv);
		}
	}
	while (KvGotoNextKey(kv, false));
	return (u_id)
}
public _load_cfg_files()
{
	_upg_names = CreateTrie();
	_weaponlist_names = CreateTrie();
	_spetweaks_names = CreateTrie();

	new Handle:kv = CreateKeyValues("uu_weapons");
	kv = CreateKeyValues("weapons");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_weapons.txt");
	if (!KvGotoFirstSubKey(kv))
	{
		return false;
	}
	new siz = GetWeaponsCatKVSize(kv)
	PrintToServer("[UberUpgrades] %d weapons loaded", siz)
	KvRewind(kv);
	BrowseWeaponsCatKV(kv)
	CloseHandle(kv);


	kv = CreateKeyValues("attribs");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_attributes.txt");
	_u_id = 1
	PrintToServer("browsin uu attribs (kvh:%d)", kv)
	BrowseAttributesKV(kv)
	PrintToServer("[UberUpgrades] %d attributes loaded", _u_id)
	CloseHandle(kv);



	new static_uid = 1
	kv = CreateKeyValues("special_tweaks");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_specialtweaks.txt");
	BrowseSpeTweaksKV(kv, static_uid)
	PrintToServer("[UberUpgrades] %d special tweaks loaded", static_uid)
	CloseHandle(kv);

	static_uid = 0
	kv = CreateKeyValues("lists");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_lists.txt");
	BrowseAttListKV(kv, static_uid)
	PrintToServer("[UberUpgrades] %d lists loaded", static_uid)
	CloseHandle(kv);
	
	static_uid = -1
	kv = CreateKeyValues("buyableWeapons");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_buyableweapons.txt");
	BrowseWeaponsListKV(kv, static_uid)
	PrintToServer("[UberUpgrades] %d buyable weapons loaded", static_uid+1)
	CloseHandle(kv);
	
	return true
}