GetWeaponsCatKVSize(Handle kv)
{
	int siz = 0
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

BrowseWeaponsCatKV(Handle kv)
{
	int u_id = 0
	int t_idx = 0
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
	char Buf[128];
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

BrowseAttributesKV(Handle kv)
{
	char Buf[256];
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
					strcopy(upgrades[_u_id].name, 64, Buf);
					SetTrieValue(_upg_names, Buf, _u_id, true);
				}
				else if (!strcmp(Buf,"name"))
				{
					KvGetString(kv, "", Buf, 64);
					if (strcmp(Buf,""))
					{
						for (int i_ = 1; i_ < MAX_ATTRIBUTES; i_++)
						{
							if (!strcmp(upgrades[i_].attr_name, Buf))
							{
								upgrades[_u_id].to_a_id = i_
								break;
							}
						}
					}
				}
				else if (!strcmp(Buf,"cost"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades[_u_id].cost = StringToInt(Buf)
				}
				else if (!strcmp(Buf,"increase_ratio"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades[_u_id].cost_inc_ratio = StringToFloat(Buf)
				}
				else if (!strcmp(Buf,"value"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades[_u_id].ratio = StringToFloat(Buf)
				}
				else if (!strcmp(Buf,"init"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades[_u_id].i_val = StringToFloat(Buf)
				}
				else if(!strcmp(Buf,"restriction_category"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades[_u_id].restriction_category = StringToInt(Buf)
				}
				else if(!strcmp(Buf,"display_style"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades[_u_id].display_style = StringToInt(Buf)
				}
				else if(!strcmp(Buf,"description"))
				{
					KvGetString(kv, "", Buf, 256);
					upgrades[_u_id].description = Buf;
				}
				else if(!strcmp(Buf,"requirement"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades[_u_id].requirement = StringToFloat(Buf);
				}
				else if(!strcmp(Buf, "staged_max"))
				{
					KvGetString(kv, "", Buf, 256);
					char parts[MAX_STAGES][256];
					int it = ExplodeString(Buf, ",", parts, MAX_STAGES, 256);

					for(int i = 1;i<it;i++)
					{
						//PrintToServer("Stage %i | Set to %.2f max.", i, StringToFloat(parts[i])) //it works :D
						upgrades[_u_id].staged_max[i] = StringToFloat(parts[i-1]);
					}
				}
				else if (!strcmp(Buf,"max"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades[_u_id].m_val = StringToFloat(Buf)
					upgrades[_u_id].staged_max[0] = upgrades[_u_id].m_val;
					_u_id++//Finish the attribute here.
				}
			}
		}
	}
	while (KvGotoNextKey(kv, false));
	return (_u_id)
}


BrowseAttListKV(Handle kv, &w_id = -1, &w_sub_id = -1, &w_subcat_id = 0,w_sub_att_idx = -1, level = 0)
{
	char Buf[128];
	do
	{
		bool incrementLater = false;
		KvGetSectionName(kv, Buf, sizeof(Buf));
		if (level == 1)
		{
			if (!GetTrieValue(_weaponlist_names, Buf, w_id))
			{
				PrintToServer("[if_lists] Malformated if_lists | if_weapon.txt file?: %s was not found", Buf)
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
				int attr_id
				KvGetSectionName(kv, Buf, sizeof(Buf));
			
				if (strcmp(Buf, "special_tweaks_listid"))
				{
					KvGetString(kv, "", Buf, 64);
					if (w_sub_id == given_upgrd_classnames_tweak_idx[w_id])
					{
						given_upgrd_classnames_tweak_nb[w_id]++
						if (!GetTrieValue(_spetweaks_names, Buf, attr_id))
						{
							PrintToServer("[if_specialtweaks] Malformated if_specialtweaks | if_specialtweaks.txt file?: %s was not found", Buf)
						}
					}
					else
					{
						if (!GetTrieValue(_upg_names, Buf, attr_id))
						{
							PrintToServer("[if_specialtweaks] Malformated if_attributes | if_attributes.txt file?: %s was not found", Buf)
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
BrowseSpeTweaksKV(Handle kv, &u_id = -1, att_id = -1, level = 0)
{
	char Buf[32];
	int attr_ref
	do
	{
		if (level == 2)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			u_id++
			SetTrieValue(_spetweaks_names, Buf, u_id)
			tweaks[u_id].tweaks = Buf
			tweaks[u_id].nb_att = 0
			tweaks[u_id].requirement = 0.0;
			tweaks[u_id].cost = 0.0;
			att_id = 0
		}
		if (level == 3)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			if(!strcmp("requirement", Buf))
			{
				KvGetString(kv, "", Buf, 32);
				tweaks[u_id].requirement = StringToFloat(Buf)
			}
			else if(!strcmp("cost", Buf))
			{
				KvGetString(kv, "", Buf, 32);
				tweaks[u_id].cost = StringToFloat(Buf)
			}
			else
			{
				if (!GetTrieValue(_upg_names, Buf, attr_ref))
					PrintToServer("[spetw_lists] Malformated if_specialtweaks | if_attribute.txt file?: %s was not found", Buf)
				
				
				tweaks[u_id].att_idx[att_id] = attr_ref;
				KvGetString(kv, "", Buf, 32);
				tweaks[u_id].att_ratio[att_id] = StringToFloat(Buf)
				
				tweaks[u_id].nb_att++
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
BrowseWeaponsListKV(Handle kv, &u_id = -1, att_id = -1, level = 0)
{
	char Buf[128];
	int attr_ref
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
				char Description[512];
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
					PrintToServer("[spetw_lists] Malformated if_buyableweapons | if_attribute.txt file?: %s was not found", Buf)
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

	Handle kv = CreateKeyValues("if_weapons");
	kv = CreateKeyValues("weapons");
	FileToKeyValues(kv, "addons/sourcemod/configs/if_weapons.txt");
	if (!KvGotoFirstSubKey(kv))
	{
		return false;
	}
	int siz = GetWeaponsCatKVSize(kv)
	PrintToServer("[UberUpgrades] %d weapons loaded", siz)
	KvRewind(kv);
	BrowseWeaponsCatKV(kv)
	CloseHandle(kv);


	kv = CreateKeyValues("attribs");
	FileToKeyValues(kv, "addons/sourcemod/configs/if_attributes.txt");
	_u_id = 1
	PrintToServer("browsin if attribs (kvh:%d)", kv)
	BrowseAttributesKV(kv)
	PrintToServer("[UberUpgrades] %d attributes loaded", _u_id)
	CloseHandle(kv);



	int static_uid = 1
	kv = CreateKeyValues("special_tweaks");
	FileToKeyValues(kv, "addons/sourcemod/configs/if_specialtweaks.txt");
	BrowseSpeTweaksKV(kv, static_uid)
	PrintToServer("[UberUpgrades] %d special tweaks loaded", static_uid)
	CloseHandle(kv);

	static_uid = 0
	kv = CreateKeyValues("lists");
	FileToKeyValues(kv, "addons/sourcemod/configs/if_lists.txt");
	BrowseAttListKV(kv, static_uid)
	PrintToServer("[UberUpgrades] %d lists loaded", static_uid)
	CloseHandle(kv);
	
	static_uid = -1
	kv = CreateKeyValues("buyableWeapons");
	FileToKeyValues(kv, "addons/sourcemod/configs/if_buyableweapons.txt");
	BrowseWeaponsListKV(kv, static_uid)
	PrintToServer("[UberUpgrades] %d buyable weapons loaded", static_uid+1)
	CloseHandle(kv);
	
	return true
}