public GetUpgrade_CatList(char[] WCName)
{
	int i, wis, w_id
	
	wis = 0
	
	for (i = wis, w_id = -1; i < WCNAMELISTSIZE; i++)
	{
		if (!strcmp(wcnamelist[i], WCName, false))
		{
			w_id = wcname_l_idx[i]
			
			return w_id
		}
	}
	if (w_id < -1)
	{
		PrintToServer("UberUpgrade error: #%s# was not a valid weapon classname..", WCName)
	}
	return w_id
}
CheckForAttunement(client)
{
	bool flag = false;
	for(int i = 0;i<Max_Attunement_Slots;i++)
	{
		if(AttunedSpells[client][i] != 0.0)
		{
			flag = true;
			break;
		}
	}
	return flag;
}
public bool:GiveNewWeapon(client, slot)
{
	Handle newItem = TF2Items_CreateItem(PRESERVE_ATTRIBUTES+FORCE_GENERATION);
	int Flags = 0;
	
	int itemDefinitionIndex = currentitem_idx[client][slot]
	TF2Items_SetItemIndex(newItem, itemDefinitionIndex);
	
	TF2Items_SetLevel(newItem, 242);
	
	Flags = PRESERVE_ATTRIBUTES;
	Flags |= FORCE_GENERATION;
	
	TF2Items_SetFlags(newItem, Flags);
	
	TF2Items_SetClassname(newItem, currentitem_classname[client][slot]);
	
	int entity = TF2Items_GiveNamedItem(client, newItem);
	if (IsValidEntity(entity))
	{
		client_new_weapon_ent_id[client] = entity;
		currentitem_level[client][slot] = 242;
		GiveNewUpgradedWeapon_(client, slot)
		EquipPlayerWeapon(client, entity);
		return true;
	}
	else
	{
		return false
	}
}
public GiveNewUpgradedWeapon_(client, slot)
{
	if(IsValidClient(client))
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
		
	int iNumAttributes;
	int iEnt;
	iNumAttributes = currentupgrades_number[client][slot]
	if (slot == 4 && IsValidClient(client))
	{
		iEnt = client
	}
	else if (currentitem_level[client][slot] != 242)
	{
		iEnt = currentitem_ent_idx[client][slot]
	}
	else
	{
		slot = 3
		iEnt = client_new_weapon_ent_id[client];
	}
	if (IsValidEntity(iEnt) && HasEntProp(iEnt, Prop_Send, "m_AttributeList"))
	{
		if( iNumAttributes > 0 )
		{
			for(int a = 0; a < iNumAttributes ; a++ )
			{
				int ifid = upgrades_to_a_id[currentupgrades_idx[client][slot][a]]
				if (strcmp(upgradesWorkNames[ifid], ""))
				{
					TF2Attrib_SetByName(iEnt, upgradesWorkNames[ifid],currentupgrades_val[client][slot][a]);
				}
			}
		}
		refreshUpgrades(client, slot)
	}
}
stock is_client_got_req(client, upgrade_choice, slot, inum, float rate = 1.0)
{

	if (canBypassRestriction[client])
		return 1;

	float up_cost = float(upgrades_costs[upgrade_choice]) * rate;
	int max_ups = currentupgrades_number[client][slot];
	up_cost /= 2.0;
	if (slot == 1)
	{
		up_cost *= SecondaryCostReduction
	}
	if (inum != 20000 && upgrades_ratio[upgrade_choice])
	{
		if(currentupgrades_i[client][slot][inum] != 0.0)
		{
			up_cost += up_cost * ((currentupgrades_val[client][slot][inum] - currentupgrades_i[client][slot][inum])
			/ upgrades_ratio[upgrade_choice]) * upgrades_costs_inc_ratio[upgrade_choice];
		}
		else
		{
			up_cost += up_cost * ((currentupgrades_val[client][slot][inum] - upgrades_i_val[upgrade_choice])
			/ upgrades_ratio[upgrade_choice]) * upgrades_costs_inc_ratio[upgrade_choice];
		}
		if (up_cost < 0.0)
		{
			up_cost *= -1.0;
			if (up_cost < float(upgrades_costs[upgrade_choice] / 2))
			{
				up_cost = float(upgrades_costs[upgrade_choice] / 2);
			}
		}
	}
	
	if (CurrencyOwned[client] < up_cost)
	{
		PrintToChat(client, "You don't have enough money.");
		EmitSoundToClient(client, SOUND_FAIL);
		return 0
	}
	else
	{
		if(upgrades_restriction_category[upgrade_choice] != 0)
		{
			if(inum == 20000)//havent upgraded
			{
				//PrintToChat(client, "E");
				for(int i = 1;i<5;i++)
				{
					if(currentupgrades_restriction[client][slot][i] == upgrades_restriction_category[upgrade_choice])
					{
						PrintToChat(client, "You already have something that fits this restriction category.");
						EmitSoundToClient(client, SOUND_FAIL);
						return 0;
					}
				}
				currentupgrades_restriction[client][slot][upgrades_restriction_category[upgrade_choice]] = upgrades_restriction_category[upgrade_choice];
			}
			else if(currentupgrades_val[client][slot][inum] - upgrades_i_val[upgrade_choice] == 0.0)
			{
				for(int i = 1;i<5;i++)
				{
					if(currentupgrades_restriction[client][slot][i] == upgrades_restriction_category[upgrade_choice])
					{
						PrintToChat(client, "You already have something that fits this restriction category.");
						EmitSoundToClient(client, SOUND_FAIL);
						return 0;
					}
				}
				currentupgrades_restriction[client][slot][upgrades_restriction_category[upgrade_choice]] = upgrades_restriction_category[upgrade_choice];
			}
		}
		
		if (inum != 20000)
		{	
			if (currentupgrades_val[client][slot][inum] == upgrades_m_val[upgrade_choice])
			{
				PrintToChat(client, "You already have reached the maximum upgrade for this category.");
				EmitSoundToClient(client, SOUND_FAIL);
				return 0
			}
		}
		else
		{
			if (max_ups >= MAX_ATTRIBUTES_ITEM)
			{
				PrintToChat(client, "You have reached the maximum number of upgrade category for this item.");
				EmitSoundToClient(client, SOUND_FAIL);
				return 0
			}
		}
		CurrencyOwned[client] -= up_cost
		client_spent_money[client][slot] += up_cost
		return 1
	}
}

public	check_apply_maxvalue(client, slot, inum, upgrade_choice)
{
	if ((upgrades_ratio[upgrade_choice] > 0.0
		 && currentupgrades_val[client][slot][inum] > upgrades_m_val[upgrade_choice])
		|| (upgrades_ratio[upgrade_choice] < 0.0 
			&& currentupgrades_val[client][slot][inum] < upgrades_m_val[upgrade_choice]))
		{
			currentupgrades_val[client][slot][inum] = upgrades_m_val[upgrade_choice]
		}
}

public ResetClientUpgrade_slot(client, slot)
{
	int iNumAttributes = currentupgrades_number[client][slot]
	
	
	if (client_spent_money[client][slot])
	{
		CurrencyOwned[client] += client_spent_money[client][slot];
	}
	currentitem_level[client][slot] = 0
	client_spent_money[client][slot] = 0.0
	client_spent_money_mvm_chkp[client][slot] = 0.0
	currentupgrades_number[client][slot] = 0;
	currentupgrades_number_mvm_chkp[client][slot] = 0;
	client_tweak_highest_requirement[client][slot] = 0.0;
	
	for(int y = 0; y<5;y++)
	{
		currentupgrades_restriction[client][slot][y] = 0;
		currentupgrades_restriction_mvm_chkp[client][slot][y] = 0;
	}
	
	
	for (int i = 0; i < iNumAttributes; i++)
	{
		currentupgrades_val_mvm_chkp[client][slot][i] = 0.0;
		currentupgrades_val[client][slot][i] = 0.0;
		currentupgrades_i[client][slot][i] = 0.0;
		currentupgrades_idx[client][slot][i] = 0;
		currentupgrades_idx_mvm_chkp[client][slot][i] = currentupgrades_idx[client][slot][i];
	}
	//I AM THE STORM THAT IS APPROACHING
	//Thank you retard MR L
	for(int i = 0; i < MAX_ATTRIBUTES; i++)
	{
		upgrades_ref_to_idx[client][slot][i] = 20000;
		upgrades_ref_to_idx_mvm_chkp[client][slot][i] = 20000;
		upgrades_efficiency[client][slot][i] = 0.0;
		upgrades_efficiency_list[client][slot][i] = 0;
	}
	
	if (slot != 4 && currentitem_idx[client][slot])
	{
		currentitem_idx[client][slot] = 20000
		GiveNewUpgradedWeapon_(client, slot)
		if(IsValidWeapon(currentitem_ent_idx[client][slot]))
			DefineAttributesTab(client, GetEntProp(currentitem_ent_idx[client][slot], Prop_Send, "m_iItemDefinitionIndex"), slot, currentitem_ent_idx[client][slot]);
	}
	

	if (slot == 3)
	{
		currentitem_idx[client][slot] = 20000
		currentitem_ent_idx[client][slot] = -1
		GiveNewUpgradedWeapon_(client, slot)
		client_new_weapon_ent_id[client] = 0;
		client_new_weapon_ent_id_mvm_chkp[client] = 0;
		upgrades_weapon_current[client] = -1;
	}
	if (slot == 4)
	{
		currentitem_idx[client][slot] = 20000
		GiveNewUpgradedWeapon_(client, slot)
		for(int i = 0; i < Max_Attunement_Slots; i++)
		{
			AttunedSpells[client][i] = 0.0;
		}
	}
}

public ResetClientUpgrades(client)
{
	int slot
	
	client_respawn_handled[client] = 0
	for (slot = 0; slot < NB_SLOTS_UED; slot++)
	{
		ResetClientUpgrade_slot(client, slot)
	}
}
public DefineAttributesTab(client, itemidx, slot, entity)
{
	if (currentitem_idx[client][slot] == 20000)
	{
		int a, a2, i, a_i
		currentitem_idx[client][slot] = itemidx
		if(currentitem_level[client][slot] != 242)
		{
			int attributeIndexes[21];
			int attributeCount = TF2Attrib_ListDefIndices(entity, attributeIndexes);
			Address attr;
			for( a = 0, a2 = 0; a < attributeCount && a < 21; a++ )
			{
				attr = TF2Attrib_GetByDefIndex(entity, attributeIndexes[a]);
				if(attr == Address_Null)
					continue;

				char Buf[64]
				a_i = attributeIndexes[a];
				TF2Econ_GetAttributeName( a_i, Buf, 64);
				if (GetTrieValue(_upg_names, Buf, i))
				{	
					currentupgrades_idx[client][slot][a2] = i
					upgrades_ref_to_idx[client][slot][i] = a2;
					currentupgrades_val[client][slot][a2] = TF2Attrib_GetValue(attr);
					currentupgrades_i[client][slot][a2] = currentupgrades_val[client][slot][a2];
					a2++
				}
			}


			ArrayList inumAttr = TF2Econ_GetItemStaticAttributes(itemidx);
			for( a=0; a < inumAttr.Length && a < 21; a++ )
			{
				bool cancel = false;
				a_i = inumAttr.Get(a,0);
				for(int e = 0;e<sizeof(attributeIndexes);e++){
					if(attributeIndexes[e] == a_i){cancel = true;break;}
				}
				if(cancel){continue;}

				char Buf[64]
				TF2Econ_GetAttributeName( a_i, Buf, 64);
				if (GetTrieValue(_upg_names, Buf, i))
				{
					currentupgrades_idx[client][slot][a2] = i
					upgrades_ref_to_idx[client][slot][i] = a2;
					currentupgrades_val[client][slot][a2] = inumAttr.Get(a,1);
					currentupgrades_i[client][slot][a2] = currentupgrades_val[client][slot][a2];
					a2++
				}
			}
			delete inumAttr;
			currentupgrades_number[client][slot] = a2
		}
		else
		{
			for( a = 0, a2 = 0; a < upgrades_weapon_nb_att[upgrades_weapon_current[client]] && a < 42; a++ )
			{
				currentupgrades_idx[client][slot][a2] = upgrades_weapon_att_idx[upgrades_weapon_current[client]][a]
				upgrades_ref_to_idx[client][slot][i] = a2;
				currentupgrades_val[client][slot][a2] = upgrades_weapon_att_amt[upgrades_weapon_current[client]][a];
				currentupgrades_i[client][slot][a2] = currentupgrades_val[client][slot][a2]
				a2++
			}
			currentupgrades_number[client][slot] = a2
		}
	}
	else
	{
		if (itemidx >= 0 && itemidx != currentitem_idx[client][slot] && currentitem_idx[client][slot] != 20000)
		{
			ResetClientUpgrade_slot(client, slot)
			//PrintToServer("Gave %N upgrade lists and reset their upgrades.", client);
			int a, a2, i, a_i
		
			currentitem_idx[client][slot] = itemidx
			if(currentitem_level[client][slot] != 242)
			{
				int attributeIndexes[21];
				int attributeCount = TF2Attrib_ListDefIndices(entity, attributeIndexes);
				Address attr;
				for( a = 0, a2 = 0; a < attributeCount && a < 21; a++ )
				{
					attr = TF2Attrib_GetByDefIndex(entity, attributeIndexes[a]);
					if(attr == Address_Null)
						continue;

					char Buf[64]
					a_i = attributeIndexes[a];
					TF2Econ_GetAttributeName( a_i, Buf, 64);
					if (GetTrieValue(_upg_names, Buf, i))
					{	
						currentupgrades_idx[client][slot][a2] = i
						upgrades_ref_to_idx[client][slot][i] = a2;
						currentupgrades_val[client][slot][a2] = TF2Attrib_GetValue(attr);
						currentupgrades_i[client][slot][a2] = currentupgrades_val[client][slot][a2];
						a2++
					}
				}


				ArrayList inumAttr = TF2Econ_GetItemStaticAttributes(itemidx);
				for(a = 0; a < inumAttr.Length && a < 21; a++ )
				{
					bool cancel = false;
					a_i = inumAttr.Get(a,0);
					for(int e = 0;e<sizeof(attributeIndexes);e++){
						if(attributeIndexes[e] == a_i){cancel = true;break;}
					}
					if(cancel){continue;}
					char Buf[64]
					TF2Econ_GetAttributeName( a_i, Buf, 64);
					if (GetTrieValue(_upg_names, Buf, i))
					{
						currentupgrades_idx[client][slot][a2] = i
						upgrades_ref_to_idx[client][slot][i] = a2;
						currentupgrades_val[client][slot][a2] = inumAttr.Get(a,1);
						currentupgrades_i[client][slot][a2] = currentupgrades_val[client][slot][a2];
						a2++
					}
				}
				delete inumAttr;
				currentupgrades_number[client][slot] = a2
				DisplayItemChange(client,itemidx);
			}
		}
	}
}
applyArcaneCooldownReduction(client, attuneSlot)
{
	float cdReduction = 1.0/ArcanePower[client];

	Address cdMult = TF2Attrib_GetByName(client, "arcane cooldown rate");
	if(cdMult != Address_Null)
		cdReduction *= TF2Attrib_GetValue(cdMult);

	SpellCooldowns[client][attuneSlot] *= cdReduction
}
DisplayItemChange(client,itemidx)
{
	char ChangeString[256];
	switch(itemidx)
	{
		//scout primaries
		case 220:
		{
			ChangeString = "Shortstop | You deal and take 15% more damage. Take no damage from self-inflicted ways.";
		}
		case 448:
		{
			ChangeString = "The Soda Popper | You drain your maximum health down to 100 while held. Slows you down by -20% but increases speed by 80% when held.";
		}
		case 1103:
		{
			ChangeString = "The Back Scatter | 2.5x damage if victim is below 40% health. 3x self push force.";
		}
		//scout secondaries
		case 46:
		{
			ChangeString = "Bonk! Atomic Punch | You gain a speed boost and some healing when used.";
		}
		case 449:
		{
			ChangeString = "The Winger | Right click is a dash ability based on your maximum speed. 3x slower reload speed.";
		}
		case 222:
		{
			ChangeString = "The Mad Milk | Shoots a grenade which applies a 15% lifesteal effect on the enemy. Scales with duration left.";
		}
		case 1121:
		{
			ChangeString = "Mutated Milk | Shoots a grenade which applies a 15% lifesteal effect on the enemy. Scales with duration left.";
		}
		case 812,833:
		{
			ChangeString = "The Flying Guillotine | Has infinite ammo.";
		}
		//Scout Melee
		case 44:
		{
			ChangeString = "The Sandman | Ball base damage increased to 40.";
		}
		case 648:
		{
			ChangeString = "The Wrap Assassin | Ball base damage increased to 40.";
		}
		case 349:
		{
			ChangeString = "Sun-on-a-Stick | Deals 7.5x afterburn, but initial melee hit deals half."
		}
		//Soldier Primary
		case 127:
		{
			ChangeString = "The Direct Hit | 1.7x damage.";
		}
		case 228,1085:
		{
			ChangeString = "The Black Box | Applies afterburn to enemies. -4 HPR (this stalls out armor recharge).";
		}
		case 414:
		{
			ChangeString = "The Liberty Launcher | Fires clip all at once. Reload time -60% and damage is reduced by 50%. Shots have a huge delay in-between.";
		}
		case 441:
		{
			ChangeString = "The Cow Mangler 5000 | Secondary fire shot scales with clip size.";
		}
		case 1104:
		{
			ChangeString = "The Air Strike | Rocket jumping gives 30% faster fire rate.";
		}
		//Soldier Secondary
		case 129,1001:
		{
			ChangeString = "The Buff Banner | Gives a +35% damage boost while still giving minicrits. Rage scales off of firerate of weapon.";
		}
		case 226:
		{
			ChangeString = "The Battalion's Backup | No longer gives crit immunity. Rage scales off of firerate of weapon.";
		}
		case 354:
		{
			ChangeString = "The Concheror | Gives a 15% lifesteal effect to teammates when active. Can overheal to 150%. Rage scales off of firerate of weapon.";
		}
		case 133:
		{
			ChangeString = "The Gunboats | Reduces blast damage taken by -20%.";
		}
		case 442:
		{
			ChangeString = "The Righteous Bison | Shoots homing lasers which continously deal damage. Converts fire rate to damage.";
		}
		case 1101:
		{
			ChangeString = "The B.A.S.E Jumper | Increased gravity & Heavily increased mobility when deployed.";
		}
		//Soldier Melee
		case 416:
		{
			ChangeString = "The Market Gardener | Gives minicrits while airborne & has damage fall-off.";
		}
		//Pyro Primary
		case 215:
		{
			ChangeString = "The Degreaser | You deal 20% less damage. Airblast has 25% more radius and 1.4x damage.";
		}
		case 594:
		{
			ChangeString = "The Phlogistinator | Rage gain is now based on hits dealt rather than damage dealt. Rage gives minicrits and agility rune instead of crits.";
		}
		//Pyro Secondary
		case 595:
		{
			ChangeString = "The Manmelter | Projectile has 15x the gravity. Explodes on contact. Converts fire rate to damage.";
		}
		case 1179:
		{
			ChangeString = "The Thermal Thruster | Heavily increased velocity. Usage is much quicker.";
		}
		//Pyro Melee
		case 348:
		{
			ChangeString = "Sharpened Volcano Fragment | Deals 7.5x afterburn, but initial melee hit deals half. Converts fire rate to damage."
		}
		//Demo Primary
		case 308:
		{
			ChangeString = "The Loch-n-Load | Deals 20% more damage. Projectiles don't have gravity.";
		}
		case 996:
		{
			ChangeString = "The Loose Cannon | Fires clip all at once. Reload time -60% and damage is reduced by 50%. Shots have a huge delay in-between.";
		}
		case 1151:
		{
			ChangeString = "The Iron Bomber | Shoots grenades that explode when victims are within 70% of the blast radius. 15% more damage. Has no splash fall-off.";
		}
		//Demo Secondaries
		case 131,1144:
		{
			ChangeString = "The Chargin' Targe | Gives +35 base health. When the charge ends, it deals an explosion that has 70 base DPS which scales on current weapon.";
		}
		case 406:
		{
			ChangeString = "The Splendid Screen | Charge deals 70% more damage. When the charge ends, it deals an explosion that has 70 base DPS which scales on current weapon.";
		}
		case 1099:
		{
			ChangeString = "The Tide Turner | When the charge ends, it deals an explosion that has 70 base DPS which scales on current weapon.";
		}
		case 130:
		{
			ChangeString = "The Scottish Resistance | +60 max stickies.";
		}
		case 1150:
		{
			ChangeString = "The Quickiebomb Launcher | Middle click is a fast dash that scales off movespeed multipliers. -25% damage dealt. Converts fire rate bonuses to damage.";
		}
		//Heavy Primaries
		case 312:
		{
			ChangeString = "The Brass Beast | Shoots rockets that have 150 base damage and 144HU blast radius and can penetrate enemies. Each penetration triggers an explosion. Cannot hit enemies multiple times. 3x slower fire rate.";
		}
		case 811,832:
		{
			ChangeString = "The Huo-Long Heater | Shoots flares. Deals 66% less damage. +200% projectile speed. Press mouse3 (middle click) to detonate the flares. Massively increased blast radius.";
		}
		case 424:
		{
			ChangeString = "Tomislav | Shoots instant travel rockets. +50% blast radius, +300% self push force, -100% rocket jump self damage, -35% damage.";
		}
		//Heavy Secondaries
		case 311:
		{
			ChangeString = "Buffalo Steak Sandvich | No longer limits speed.";
		}
		case 159:
		{
			ChangeString = "The Dalokohs Bar | Adds an additional 15 armor when eaten.";
		}
		case 433:
		{
			ChangeString = "Fishcake | Adds an additional 15 armor when eaten.";
		}
		//Heavy Melee
		case 310:
		{
			ChangeString = "The Warrior's Spirit | Deals -40% damage. Shoots an additional 2 arrows per attack that deal 30 base damage.";
		}
		case 43:
		{
			ChangeString = "The Killing Gloves of Boxing | Gives 2 seconds of minicrits on kill instead.";
		}
		//Engineer Primary
		case 588:
		{
			ChangeString = "The Pomson 6000 | Shoots homing lasers which continously deal damage. Converts fire rate to damage.";
		}
		case 141,1004:
		{
			ChangeString = "The Frontier Justice | On crit: target recieves 1.3x damage for 5s.";
		}
		//Engineer Secondary
		case 528:
		{
			ChangeString = "The Short Circuit | Shoots explosive bullets instead. Applies burn. Shoots 2x slower. -20% damage.";
		}
		//Engineer Melee
		case 329:
		{
			ChangeString = "The Jag | Will instantly build buildings at level 3, but will cost 100% of your metal.";
		}
		case 589:
		{
			ChangeString = "The Eureka Effect | Teleporting will deal 500 base DPS based on sentry upgrades, stun targets, and launch them into the air. At the peak of the launch, will increase radiation. Cannot build a sentry.";
		}
		//Medic Secondaries
		case 411:
		{
			ChangeString = "The Quick-Fix | Healing target constantly gives a 3% armor regeneration. (Based on their own armor regeneration.) Uber gives an additional 2x health regeneration and armor regeneration.";
		}
		//Medic Melee
		case 37:
		{
			ChangeString = "The Ubersaw | Gives 3% uber per hit.";
		}
		//Sniper Primaries
		case 230:
		{
			ChangeString = "The Sydney Sleeper | Applies 2 seconds of jarate on hit.";
		}
		case 526,30665:
		{
			ChangeString = "The Machina | Fully charged shots bounce to 3 other targets at max within a 350HU radius. ";
		}
		case 1098:
		{
			ChangeString = "The Classic | Charged shots have 60% more scaling.";
		}
		case 752:
		{
			ChangeString = "The Hitman's Heatmaker | Shoots rockets with 20% more damage. Focus gives minicrits and increased firerate. Deals 50% more damage if victim is overhealed.";
		}
		case 56,1005:
		{
			ChangeString = "The Huntsman | Has no drawspeed, 2 clip size. Arrows fly straight. Slows enemy by -40% for 1s on hit.";
		}
		case 1092:
		{
			ChangeString = "The Fortified Compound | Greatbow styled. Cannot move when drawn, & deals massively increased damage. Converts fire rate to damage. Arrows fly straight.";
		}
		//Sniper Secondaries
		case 751:
		{
			ChangeString = "The Cleaner's Carbine | No longer has crikey. Close ranged backattacks do minicrits. Converts fire rate to damage.";
		}
		case 58,1083,1105:
		{
			ChangeString = "The Jarate | Infinite ammo.";
		}
		//Sniper Melees
		case 232:
		{
			ChangeString = "The Bushwacka | Shoots an arrow that deals 120 base damage and has a boomerang styled trajectory. Projectile pierces all targets forever and can hit multiple times. Fires 4x slower.";
		}
		//Spy Primaries
		case 61,1006:
		{
			ChangeString = "The Ambassador | Has 15% more fall-off. Can constantly headshot. Headshots deal minicrits.";
		}
		case 460:
		{
			ChangeString = "The Enforcer | Takes 2 ammo per shot. 2x fire rate. 7x slower reload speed. Pierces resistance status effects (ie : vaccinator)";
		}
		case 525:
		{
			ChangeString = "The Diamondback | Converts fire rate to damage.";
		}
		//Spy Melees
		case 356:
		{
			ChangeString = "The Conniver's Kunai | Backstabs instead have a 50% lifesteal bonus.";
		}
		//Spy Misc
		case 59:
		{
			ChangeString = "The Dead Ringer | Now gives 90% damage reduction on main hit. 75% while cloaked.";
		}
		case 735,736,810,831,933,1080,1102:
		{
			ChangeString = "Sappers | Destroys buildings within 110 damage ticks (regardless of damage modifiers.)";
		}
	}
	if(ChangeString[0])
	{
		CPrintToChat(client, "{valve}Incremental Fortress {default}| {steelblue}Weapon Changes{default} | %s", ChangeString)
	}
}
public UpgradeItem(client, upgrade_choice, inum, float ratio, slot)
{
	if (inum == 20000)
	{
		inum = currentupgrades_number[client][slot]
		upgrades_ref_to_idx[client][slot][upgrade_choice] = inum;
		currentupgrades_idx[client][slot][inum] = upgrade_choice 
		currentupgrades_val[client][slot][inum] = upgrades_i_val[upgrade_choice];
		currentupgrades_number[client][slot] = currentupgrades_number[client][slot] + 1
		
		currentupgrades_val[client][slot][inum] += (upgrades_ratio[upgrade_choice] * ratio);
	}
	else
	{
		currentupgrades_val[client][slot][inum] += (upgrades_ratio[upgrade_choice] * ratio);
		if(!canBypassRestriction[client])
		 check_apply_maxvalue(client, slot, inum, upgrade_choice)
	}
	client_last_up_idx[client] = upgrade_choice
	client_last_up_slot[client] = slot
}
public remove_attribute(client, inum)
{
	int slot = current_slot_used[client];
	if(currentupgrades_i[client][slot][inum] != 0.0 && upgrades_costs[currentupgrades_idx[client][slot][inum]] > 1.0)
	{
		currentupgrades_val[client][slot][inum] = currentupgrades_i[client][slot][inum];
	}
	else
	{
		currentupgrades_val[client][slot][inum] = upgrades_i_val[currentupgrades_idx[client][slot][inum]];
	}
	int u = currentupgrades_idx[client][slot][inum]
	if (u != 20000)
	{
		if(upgrades_restriction_category[u] != 0)
		{
			for(int i = 1;i<5;i++)
			{
				if(i == upgrades_restriction_category[u])
				{
					currentupgrades_restriction[client][slot][i] = 0;
				}
			}
		}
	}
	GiveNewUpgradedWeapon_(client, slot)
}
bool LookupOffset(int &iOffset, const char[] strClass, const char[] strProp)
{
	iOffset = FindSendPropInfo(strClass, strProp);
	if (iOffset <= 0)
	{
		SetFailState("Could not locate offset for %s::%s", strClass, strProp);
	}
	return true;
}
public GetEntLevel(entity)
{
    return GetEntProp(entity, Prop_Send, "m_iUpgradeLevel", 1);
}
public AddEntHealth(entity, amount)
{
    SetVariantInt(amount);
    AcceptEntityInput(entity, "AddHealth");
}
public void SetTauntAttackSpeed(int client, float speed)
{
	float flTauntAttackTime = GetEntDataFloat(client, g_iOffset);
	float flCurrentTime = GetGameTime();
	float flNextTauntAttackTime = flCurrentTime + ((flTauntAttackTime - flCurrentTime) / speed);
	if (flTauntAttackTime > 0.0)
	{
		SetEntDataFloat(client, g_iOffset, flNextTauntAttackTime, true);
		g_flLastAttackTime[client] = flNextTauntAttackTime;
		DataPack hPack;
		CreateDataTimer(0.1, Timer_SetNextAttackTime, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		hPack.WriteCell(GetClientUserId(client));
		hPack.WriteFloat(speed);
	}
}
public Action Timer_SetNextAttackTime(Handle timer, DataPack hPack)
{
	hPack.Reset();
	int client = GetClientOfUserId(hPack.ReadCell());
	float flTauntAttackTime = GetEntDataFloat(client, g_iOffset);
	
	if (g_flLastAttackTime[client] == flTauntAttackTime)
	{
		return Plugin_Continue;
	}
	else if (g_flLastAttackTime[client] > 0.0 && flTauntAttackTime == 0.0)
	{
		g_flLastAttackTime[client] = 0.0;
		return Plugin_Stop;
	}
	else
	{
		float speed = hPack.ReadFloat();
		float flCurrentTime = GetGameTime();
		float flNextTauntAttackTime = flCurrentTime + ((flTauntAttackTime - flCurrentTime) / speed);
		SetEntDataFloat(client, g_iOffset, flNextTauntAttackTime, true);
		g_flLastAttackTime[client] = flNextTauntAttackTime;
	}
	return Plugin_Continue;
}
public Action:RemoveDamage(Handle timer, any:data)
{
	ResetPack(data);
	
	int client = EntRefToEntIndex(ReadPackCell(data));
	float damage = ReadPackFloat(data);
	if(IsValidClient(client))
	{
		dps[client] -= damage;
		
		if(dps[client] < 0.0)
		{
			dps[client] = 0.0;
		}
	}
	CloseHandle(data);
}
RespawnEffect(client)
{
	if(IsValidClient(client) && IsClientObserver(client) == false)
	{
		current_class[client] = TF2_GetPlayerClass(client)
		fl_CurrentFocus[client] = fl_MaxFocus[client];
		fl_CurrentArmor[client] = fl_MaxArmor[client];
		fl_AdditionalArmor[client] = 0.0;
		LightningEnchantmentDuration[client] = 0.0;
		CreateTimer(0.4,GiveMaxAmmo,GetClientUserId(client));
	}
	TF2Attrib_SetByName(client,"deploy time decreased", 0.0);
	TF2Attrib_SetByName(client,"crit_dmg_falloff", 1.0);
	TF2Attrib_SetByName(client,"airblast_pushback_no_stun", 1.0);
	TF2Attrib_SetByName(client,"airblast_pushback_disabled", 1.0);
	TF2Attrib_SetByName(client,"airblast_deflect_projectiles_disabled", 1.0);
	TF2Attrib_SetByName(client,"no damage view flinch", 1.0);
	CreateTimer(0.2,GiveMaxHealth,GetClientUserId(client));
}
UpdateMaxValuesStage(int stage)
{
	for(int i = 0;i<MAX_ATTRIBUTES;i++)
	{
		if(upgrades_staged_max[i][stage] != 0.0)
		{
			upgrades_m_val[i] = upgrades_staged_max[i][stage];
		}
	}
}
ChangeClassEffect(client)
{
	if(IsValidClient(client))
	{
		current_class[client] = TF2_GetPlayerClass(client)
	}
	TF2Attrib_RemoveAll(client)
	RespawnEffect(client);
	if(!TF2Spawn_IsClientInSpawn(client))
	{
		ForcePlayerSuicide(client);
	}
}

//PostUpgrade
refreshUpgrades(client, slot)
{
	if(IsValidClient3(client) && IsPlayerAlive(client))
	{
		current_class[client] = TF2_GetPlayerClass(client);
		int slotItem;
		if(slot == 3 && IsValidEntity(client_new_weapon_ent_id[client]) && client_new_weapon_ent_id[client] > 0)
		{
			slotItem = client_new_weapon_ent_id[client];
		}
		else
		{
			slotItem = currentitem_ent_idx[client][slot];
		}
		if(slot == 4)
		{
			bool isUsed[32];
			for(int i = 0; i<Max_Attunement_Slots;i++)
			{
				AttunedSpells[client][i] = 0.0;
				Address zapActive = TF2Attrib_GetByName(client, "arcane zap");
				Address lightningActive = TF2Attrib_GetByName(client, "arcane lightning strike");
				Address healingAuraActive = TF2Attrib_GetByName(client, "arcane projected healing");
				Address callBeyondActive = TF2Attrib_GetByName(client, "arcane a call beyond");
				Address blackskyEyeActive = TF2Attrib_GetByName(client, "arcane blacksky eye");
				Address sunlightSpearActive = TF2Attrib_GetByName(client, "arcane sunlight spear");
				Address lightningenchantmentActive = TF2Attrib_GetByName(client, "arcane lightning enchantment");
				Address snapfreezeActive = TF2Attrib_GetByName(client, "arcane snap freeze");
				Address arcaneprisonActive = TF2Attrib_GetByName(client, "arcane prison");
				Address darkmoonbladeActive = TF2Attrib_GetByName(client, "arcane darkmoon blade");
				if(zapActive != Address_Null && !isUsed[1])
				{
					if(TF2Attrib_GetValue(zapActive) > 0.1)
					{
						AttunedSpells[client][i] = 1.0;
						isUsed[1] = true
						continue;
					}
				}
				if(lightningActive != Address_Null && !isUsed[2])
				{
					if(TF2Attrib_GetValue(lightningActive) > 0.1)
					{
						AttunedSpells[client][i] = 2.0;
						isUsed[2] = true
						continue;
					}
				}
				if(healingAuraActive != Address_Null && !isUsed[3])
				{
					if(TF2Attrib_GetValue(healingAuraActive) > 0.1)
					{
						AttunedSpells[client][i] = 3.0;
						isUsed[3] = true
						continue;
					}
				}
				if(callBeyondActive != Address_Null && !isUsed[4])
				{
					if(TF2Attrib_GetValue(callBeyondActive) > 0.1)
					{
						AttunedSpells[client][i] = 4.0;
						isUsed[4] = true
						continue;
					}
				}
				if(blackskyEyeActive != Address_Null && !isUsed[5])
				{
					if(TF2Attrib_GetValue(blackskyEyeActive) > 0.1)
					{
						AttunedSpells[client][i] = 5.0;
						isUsed[5] = true
						continue;
					}
				}
				if(sunlightSpearActive != Address_Null && !isUsed[6])
				{
					if(TF2Attrib_GetValue(sunlightSpearActive) > 0.1)
					{
						AttunedSpells[client][i] = 6.0;
						isUsed[6] = true
						continue;
					}
				}
				if(lightningenchantmentActive != Address_Null && !isUsed[7])
				{
					if(TF2Attrib_GetValue(lightningenchantmentActive) > 0.1)
					{
						AttunedSpells[client][i] = 7.0;
						isUsed[7] = true
						continue;
					}
				}
				if(snapfreezeActive != Address_Null && !isUsed[8])
				{
					if(TF2Attrib_GetValue(snapfreezeActive) > 0.1)
					{
						AttunedSpells[client][i] = 8.0;
						isUsed[8] = true
						continue;
					}
				}
				if(arcaneprisonActive != Address_Null && !isUsed[9])
				{
					if(TF2Attrib_GetValue(arcaneprisonActive) > 0.1)
					{
						AttunedSpells[client][i] = 9.0;
						isUsed[9] = true
						continue;
					}
				}
				if(darkmoonbladeActive != Address_Null && !isUsed[10])
				{
					if(TF2Attrib_GetValue(darkmoonbladeActive) > 0.1)
					{
						AttunedSpells[client][i] = 10.0;
						isUsed[10] = true
						continue;
					}
				}
			
				//Class Specifics
				switch(current_class[client])
				{
					case TFClass_Scout:
					{
						Address speedAuraActive = TF2Attrib_GetByName(client, "arcane speed aura");//Scout
						if(speedAuraActive != Address_Null && !isUsed[11])
						{
							if(TF2Attrib_GetValue(speedAuraActive) > 0.1)
							{
								AttunedSpells[client][i] = 11.0;
								isUsed[11] = true
								continue;
							}
						}
					}
					case TFClass_Soldier:
					{
						Address aerialStrikeActive = TF2Attrib_GetByName(client, "arcane aerial strike");
						if(aerialStrikeActive != Address_Null && !isUsed[12])
						{
							if(TF2Attrib_GetValue(aerialStrikeActive) > 0.1)
							{
								AttunedSpells[client][i] = 12.0;
								isUsed[12] = true
								continue;
							}
						}
					}
					case TFClass_Pyro:
					{
						Address infernoActive = TF2Attrib_GetByName(client, "arcane inferno");
						if(infernoActive != Address_Null && !isUsed[13])
						{
							if(TF2Attrib_GetValue(infernoActive) > 0.1)
							{
								AttunedSpells[client][i] = 13.0;
								isUsed[13] = true
								continue;
							}
						}
					}
					case TFClass_DemoMan:
					{
						Address mineFieldActive = TF2Attrib_GetByName(client, "arcane mine field");
						if(mineFieldActive != Address_Null && !isUsed[14])
						{
							if(TF2Attrib_GetValue(mineFieldActive) > 0.1)
							{
								AttunedSpells[client][i] = 14.0;
								isUsed[14] = true
								continue;
							}
						}
					}
					case TFClass_Heavy:
					{
						Address shockwaveActive = TF2Attrib_GetByName(client, "arcane shockwave");
						if(shockwaveActive != Address_Null && !isUsed[15])
						{
							if(TF2Attrib_GetValue(shockwaveActive) > 0.1)
							{
								AttunedSpells[client][i] = 15.0;
								isUsed[15] = true
								continue;
							}
						}
					}
					case TFClass_Engineer:
					{
						Address autoSentryActive = TF2Attrib_GetByName(client, "arcane autosentry");
						if(autoSentryActive != Address_Null && !isUsed[16])
						{
							if(TF2Attrib_GetValue(autoSentryActive) > 0.1)
							{
								AttunedSpells[client][i] = 16.0;
								isUsed[16] = true
								continue;
							}
						}
					}
					case TFClass_Medic:
					{
						Address soothingSunlightActive = TF2Attrib_GetByName(client, "arcane soothing sunlight");
						if(soothingSunlightActive != Address_Null && !isUsed[17])
						{
							if(TF2Attrib_GetValue(soothingSunlightActive) > 0.1)
							{
								AttunedSpells[client][i] = 17.0;
								isUsed[17] = true
								continue;
							}
						}
					}
					case TFClass_Sniper:
					{
						Address arcaneHunterActive = TF2Attrib_GetByName(client, "arcane hunter");
						if(arcaneHunterActive != Address_Null && !isUsed[18])
						{
							if(TF2Attrib_GetValue(arcaneHunterActive) > 0.1)
							{
								AttunedSpells[client][i] = 18.0;
								isUsed[18] = true
								continue;
							}
						}
					}
					case TFClass_Spy:
					{
						Address markForDeathActive = TF2Attrib_GetByName(client, "arcane mark for death");
						if(markForDeathActive != Address_Null && !isUsed[19])
						{
							if(TF2Attrib_GetValue(markForDeathActive) > 0.1)
							{
								AttunedSpells[client][i] = 19.0;
								isUsed[19] = true
								continue;
							}
						}
					}
				}
			}
			Address healthActive = TF2Attrib_GetByName(client, "health from packs decreased");		
			if(healthActive != Address_Null)
			{
				float healthMultiplier = TF2Attrib_GetValue(healthActive);
				float MaxHealth = GetClientBaseHP(client)*healthMultiplier;
				TF2Attrib_SetByName(client,"max health additive bonus", MaxHealth);
				if(TF2Spawn_IsClientInSpawn(client))
				{
					CreateTimer(0.2,GiveMaxHealth,GetClientUserId(client));
				}
				if(current_class[client] == TFClass_Engineer)
				{
					TF2Attrib_SetByName(client,"engy building health bonus", 1.0+healthMultiplier);
				}
			}
			if(fl_AdditionalArmor[client] > 0.0)
			{
				float postArmorAmount = 300.0
				Address armorActive = TF2Attrib_GetByName(client, "obsolete ammo penalty")
				if(armorActive != Address_Null)
				{
					postArmorAmount = TF2Attrib_GetValue(armorActive)+300.0;
				}
				if(postArmorAmount < fl_MaxArmor[client] && fl_AdditionalArmor[client] > postArmorAmount)
				{
					fl_AdditionalArmor[client] = postArmorAmount
				}
			}
			
			//Powerups
			Address kingPowerup = TF2Attrib_GetByName(client, "king powerup");
			if(kingPowerup != Address_Null)
			{
				float kingPowerupValue = TF2Attrib_GetValue(kingPowerup);
				if(kingPowerupValue > 0.0)
				{
					TF2Attrib_SetByName(client,"ubercharge rate bonus", 1.5);
					TF2Attrib_SetByName(client,"heal rate bonus", 1.5);
				}
				else
				{
					TF2Attrib_RemoveByName(client,"ubercharge rate bonus");
					TF2Attrib_RemoveByName(client,"heal rate bonus");
				}
			}
			
			Address precisionPowerup = TF2Attrib_GetByName(client, "precision powerup");
			if(precisionPowerup != Address_Null)
			{
				float precisionPowerupValue = TF2Attrib_GetValue(precisionPowerup);
				if(precisionPowerupValue > 0.0){
					TF2Attrib_SetByName(client,"weapon spread bonus", 0.05);
					TF2Attrib_SetByName(client,"Projectile speed increased", 2.0);
					TF2Attrib_SetByName(client,"Projectile range increased", 1.35);
					TF2Attrib_SetByName(client,"blast dmg to self increased", 0.001);
					if(current_class[client] == TFClass_DemoMan)
					{
						int secondary = GetWeapon(client,1);
						if(IsValidEntity(secondary))
						{
							TF2Attrib_SetByName(secondary,"sticky arm time penalty", -2.0);
						}
					}
				}else{
					TF2Attrib_RemoveByName(client,"weapon spread bonus");
					TF2Attrib_RemoveByName(client,"Projectile speed increased");
					TF2Attrib_RemoveByName(client,"Projectile range increased");
					TF2Attrib_RemoveByName(client,"blast dmg to self increased");
					if(current_class[client] == TFClass_DemoMan)
					{
						int secondary = GetWeapon(client,1);
						if(IsValidEntity(secondary))
						{
							TF2Attrib_SetByName(secondary,"sticky arm time penalty", -2.0);
						}
					}
				}
			}
			
			Address agilityPowerup = TF2Attrib_GetByName(client, "agility powerup");		
			if(agilityPowerup != Address_Null)
			{
				float agilityPowerupValue = TF2Attrib_GetValue(agilityPowerup);
				if(agilityPowerupValue > 0.0)
				{
					TF2Attrib_SetByName(client,"major move speed bonus", 1.4);
					TF2Attrib_SetByName(client,"major increased jump height", 1.3);
					TF2Attrib_SetByName(client,"self dmg push force increased", 1.75);
					TF2Attrib_SetByName(client,"SET BONUS: chance of hunger decrease", 0.35);
					TF2Attrib_SetByName(client,"has pipboy build interface", 72.0);
				}
				else
				{
					TF2Attrib_RemoveByName(client,"major move speed bonus");
					TF2Attrib_RemoveByName(client,"major increased jump height");
					TF2Attrib_RemoveByName(client,"self dmg push force increased");
					TF2Attrib_RemoveByName(client,"SET BONUS: chance of hunger decrease");
					TF2Attrib_RemoveByName(client,"has pipboy build interface");
				}
			}

		}
		if(slot != 4 && IsValidEntity(slotItem) && slotItem > 0 && HasEntProp(slotItem, Prop_Data, "m_iClip1"))
		{
			float Spread = 0.0;
			Address spread1 = TF2Attrib_GetByName(slotItem, "spread penalty");
			if(spread1 != Address_Null)
			{
				Spread += 1.0;
				Spread *= (TF2Attrib_GetValue(spread1)*2.0);
			}
			Address spread2 = TF2Attrib_GetByName(slotItem, "weapon spread bonus");
			if(spread2 != Address_Null)
			{
				Spread -= 0.1
				Spread *= TF2Attrib_GetValue(spread2);
			}
			Address precisionPowerup = TF2Attrib_GetByName(client, "precision powerup");
			if(precisionPowerup != Address_Null)
			{
				float precisionPowerupValue = TF2Attrib_GetValue(precisionPowerup);
				if(precisionPowerupValue > 0.0){
					Spread = 0.0;
				}
			}
			if(Spread != 0.0)
			{
				TF2Attrib_SetByName(slotItem, "projectile spread angle penalty", Spread);
			}
			Address reloadActive = TF2Attrib_GetByName(slotItem, "multiple sentries");
			if(reloadActive!=Address_Null)
			{
				SetEntProp(slotItem, Prop_Data, "m_bReloadsSingly", 0);
			}
			Address firerateActive = TF2Attrib_GetByName(slotItem, "disguise speed penalty");
			Address heavyweaponActive = TF2Attrib_GetByName(slotItem, "Converts Firerate to Damage");//Implement "Heavy" Weapons
			if(heavyweaponActive != Address_Null && TF2Attrib_GetValue(heavyweaponActive) != 0.0)
			{
				Address firerateActive2 = TF2Attrib_GetByName(slotItem, "fire rate bonus HIDDEN");
				Address firerateActive3 = TF2Attrib_GetByName(slotItem, "fire rate penalty HIDDEN");
				float damageModifier = 1.0;
				if(firerateActive != Address_Null)
				{
					damageModifier *= TF2Attrib_GetValue(firerateActive);
					TF2Attrib_RemoveByName(slotItem, "fire rate bonus");
				}
				if(firerateActive2 != Address_Null)
				{
					damageModifier /= TF2Attrib_GetValue(firerateActive2);
					TF2Attrib_RemoveByName(slotItem, "fire rate bonus HIDDEN");
				}
				if(firerateActive3 != Address_Null)
				{
					damageModifier /= TF2Attrib_GetValue(firerateActive3);
					TF2Attrib_RemoveByName(slotItem, "fire rate penalty HIDDEN");
				}
				//If their weapon doesn't have a clip, reload rate also affects fire rate.
				if((HasEntProp(slotItem, Prop_Data, "m_iClip1") && GetEntProp(slotItem,Prop_Data,"m_iClip1")  == -1) || TF2Attrib_GetValue(heavyweaponActive) > 1.0)
				{
					Address DPSMult12 = TF2Attrib_GetByName(slotItem, "faster reload rate");
					Address DPSMult13 = TF2Attrib_GetByName(slotItem, "Reload time increased");
					Address DPSMult14 = TF2Attrib_GetByName(slotItem, "Reload time decreased");
					Address DPSMult15 = TF2Attrib_GetByName(slotItem, "reload time increased hidden");
					
					if(DPSMult12 != Address_Null) {
					damageModifier /= TF2Attrib_GetValue(DPSMult12);
					TF2Attrib_RemoveByName(slotItem, "faster reload rate");
					}
					if(DPSMult13 != Address_Null) {
					damageModifier /= TF2Attrib_GetValue(DPSMult13);
					TF2Attrib_RemoveByName(slotItem, "Reload time increased");
					}
					if(DPSMult14 != Address_Null) {
					damageModifier /= TF2Attrib_GetValue(DPSMult14);
					TF2Attrib_RemoveByName(slotItem, "Reload time decreased");
					}
					if(DPSMult15 != Address_Null) {
					damageModifier /= TF2Attrib_GetValue(DPSMult15);
					TF2Attrib_RemoveByName(slotItem, "reload time increased hidden");
					}
				}
				if(damageModifier != 1.0)
				{
					TF2Attrib_SetByName(slotItem,"throwable healing", damageModifier);
					//PrintToChat(client,"int mult = %.2f",damageModifier);
				}
			}
			else if(firerateActive != Address_Null)
			{
				TF2Attrib_SetByName(slotItem,"fire rate bonus", 1.0/TF2Attrib_GetValue(firerateActive));
			}
			TF2Attrib_ClearCache(slotItem);
		}
	}
}
stock int getUpgradeRate(client)
{
	int rate = 1;
	if(globalButtons[client] & IN_DUCK)
		rate *= 10;
	if(globalButtons[client] & IN_RELOAD)
		rate *= 100;
	if(globalButtons[client] & IN_JUMP)
		rate *= -1;

	return rate;
}
public void getUpgradeMenuTitle(int client, int w_id, int cat_id, int slot, char fstr2[100])
{
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
}
public Action:GiveBotUpgrades(Handle timer, any:userid) 
{
	int client = GetClientOfUserId(userid);
	if(DisableBotUpgrades != 1 && IsValidClient3(client) && IsPlayerAlive(client))
	{
		int primary = (GetWeapon(client,0));
		int secondary = (GetWeapon(client,1));
		int melee = (GetWeapon(client,2));
		if(TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			melee = GetPlayerWeaponSlot(client,2);
		}
		
		if(!IsValidEntity(primary))
			primary = GetPlayerWeaponSlot(client,0);
		if(!IsValidEntity(secondary))
			secondary = GetPlayerWeaponSlot(client,1);
		if(!IsValidEntity(melee))
			melee = GetPlayerWeaponSlot(client,2);
		
		if(!IsValidEntity(primary) || !IsValidEntity(secondary) || !IsValidEntity(melee))
		{
			return Plugin_Continue;
		}
		
		int i = 0;
		
		TF2Attrib_RemoveAll(client);
		TF2Attrib_RemoveAll(primary);
		TF2Attrib_RemoveAll(secondary);
		TF2Attrib_RemoveAll(melee);
		
		current_class[client] = TF2_GetPlayerClass(client)

		TF2Attrib_SetByName(client,"increased jump height", 2.0);
		TF2Attrib_SetByName(client,"weapon spread bonus", 0.4);
		//TF2Attrib_SetByName(client,"rage giving scale",(500.0/(additionalstartmoney+StartMoney)) / OverAllMultiplier);
		if((additionalstartmoney+StartMoney) >= 500000)
		{
			TF2Attrib_SetByName(client,"damage bonus HIDDEN",(2.0));
			TF2Attrib_SetByName(client,"damage taken mult 2",(0.5));
		}
		if((additionalstartmoney+StartMoney) >= 1500000)
		{
			TF2Attrib_SetByName(client,"damage bonus HIDDEN",(3.0));
			TF2Attrib_SetByName(client,"damage taken mult 2",(0.33));
		}
		if((additionalstartmoney+StartMoney) <= 750000)
		{
			TF2Attrib_SetByName(client,"damage taken mult 1",Pow(7600.0/(additionalstartmoney+StartMoney)/ OverAllMultiplier, 1.6));
			TF2Attrib_SetByName(client,"damage force increase",1/(additionalstartmoney+StartMoney)/9000.0);
		}
		if((additionalstartmoney+StartMoney) > 750000)
		{
			TF2Attrib_SetByName(client,"damage taken mult 1",Pow(7400.0/(additionalstartmoney+StartMoney)/ OverAllMultiplier, 1.78));
			TF2Attrib_SetByName(client,"damage force increase",1/(additionalstartmoney+StartMoney)/6000.0);
		}
		for(i=0;i<3;i++)
		{
			int weap = GetWeapon(client,i);
			if((additionalstartmoney+StartMoney) >= 1000000){
			
				TF2Attrib_SetByName(weap,"damage penalty",1+((additionalstartmoney+StartMoney)/16000.0)*OverAllMultiplier);
				TF2Attrib_SetByName(weap,"damage mult 1",1+((additionalstartmoney+StartMoney)/20000.0)*OverAllMultiplier);
			}
			else
			{
				TF2Attrib_SetByName(weap,"damage penalty",1+((additionalstartmoney+StartMoney)/15000.0)*OverAllMultiplier);
				TF2Attrib_SetByName(weap,"damage mult 1",1+((additionalstartmoney+StartMoney)/18000.0)*OverAllMultiplier);
			}
			if(i != 2)
			{
				if (current_class[client] != TFClass_Heavy && current_class[client] != TFClass_Pyro && current_class[client] != TFClass_Sniper )
				{
					TF2Attrib_SetByName(weap,"faster reload rate",(9000.0/(additionalstartmoney+StartMoney)));
				}
			}
		}
		
		TF2Attrib_SetByName(client,"maxammo primary increased",1+((additionalstartmoney+StartMoney)/5000.0)*OverAllMultiplier);
		TF2Attrib_SetByName(client,"maxammo secondary increased",1+((additionalstartmoney+StartMoney)/5000.0)*OverAllMultiplier);
		TF2Attrib_SetByName(client,"ammo regen", 1.0);
		TF2Attrib_SetByName(client,"increased air control", 3.0);
		TF2Attrib_SetByName(melee,"melee range multiplier", 50.0);
		TF2Attrib_SetByName(melee,"fire rate penalty HIDDEN", 0.75);
		if((additionalstartmoney+StartMoney) <= 300000.0/OverAllMultiplier)
		{
			TF2Attrib_SetByName(client,"move speed bonus",1+(((additionalstartmoney+StartMoney)/300000.0)*OverAllMultiplier));
		}
		else
		{
			TF2Attrib_SetByName(client,"move speed bonus",(2.00));
		}
		
		switch(current_class[client])
		{
			case TFClass_Scout:
			{
				TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/200.0)*OverAllMultiplier);
				TF2Attrib_SetByName(client,"clip size bonus",1+((additionalstartmoney+StartMoney)/12500.0)*OverAllMultiplier);
				TF2Attrib_SetByName(client,"disguise on backstab",((additionalstartmoney+StartMoney)/10000.0)*OverAllMultiplier);
				if((additionalstartmoney+StartMoney) <= 480000/OverAllMultiplier)
				{
					TF2Attrib_SetByName(client,"damage bonus",1+(((additionalstartmoney+StartMoney)/160000.0)*OverAllMultiplier));
				}
				else
				{
					TF2Attrib_SetByName(client,"damage bonus", 4.0);
				}
				for(i=0;i<3;i++)
				{
					int weap = GetWeapon(client,i);
					if((additionalstartmoney+StartMoney) <= 400000/OverAllMultiplier)
					{
						TF2Attrib_SetByName(weap,"fire rate bonus",(20000.0/(additionalstartmoney+StartMoney))/OverAllMultiplier);
					}
					else
					{
						TF2Attrib_SetByName(weap,"fire rate bonus",(0.05));
					}
				}
				
			}
			case TFClass_Soldier:
			{
				TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/130.5) *OverAllMultiplier);
				TF2Attrib_SetByName(client,"clip size bonus",((additionalstartmoney+StartMoney)/11000.0) *OverAllMultiplier);
				TF2Attrib_SetByName(client,"disguise on backstab",((additionalstartmoney+StartMoney)/6750.0) *OverAllMultiplier);
				if((additionalstartmoney+StartMoney) <= 480000/OverAllMultiplier)
				{
					TF2Attrib_SetByName(client,"damage bonus",1+(((additionalstartmoney+StartMoney)/160000.0)*OverAllMultiplier));
				}
				else
				{
					TF2Attrib_SetByName(client,"damage bonus", 4.0);
				}
				for(i=0;i<3;i++)
				{
					int weap = GetWeapon(client,i);
					if(i != 2)
					{
						if((additionalstartmoney+StartMoney) <= 750000 / OverAllMultiplier)
						{
							TF2Attrib_SetByName(weap,"Blast radius increased",1+(((additionalstartmoney+StartMoney)/250000.0) *OverAllMultiplier));
							TF2Attrib_SetByName(weap,"Projectile speed increased",1+(((additionalstartmoney+StartMoney)/300000.0) *OverAllMultiplier));
						}
						else
						{
							TF2Attrib_SetByName(weap,"Blast radius increased",(4.0));
							TF2Attrib_SetByName(weap,"Projectile speed increased",(3.5));
						}
					}
					if((additionalstartmoney+StartMoney) <= 1000000 / OverAllMultiplier)
					{
						TF2Attrib_SetByName(weap,"fire rate bonus",(25000.0/(additionalstartmoney+StartMoney)) / OverAllMultiplier);
					}
					else
					{
						TF2Attrib_SetByName(weap,"fire rate bonus",(0.025));
					}
				}
			}
			case TFClass_Pyro:
			{
				TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/152.25) *OverAllMultiplier);
				TF2Attrib_SetByName(client,"clip size bonus",((additionalstartmoney+StartMoney)/12500.0) *OverAllMultiplier);
				TF2Attrib_SetByName(client,"disguise on backstab",((additionalstartmoney+StartMoney)/7750.0) *OverAllMultiplier);
				TF2Attrib_SetByName(client,"weapon burn time increased", 6.0);
				TF2Attrib_SetByName(primary,"flame size bonus", 2.0);
				if((additionalstartmoney+StartMoney) <= 480000/OverAllMultiplier)
				{
					TF2Attrib_SetByName(client,"damage bonus",1+(((additionalstartmoney+StartMoney)/160000.0)*OverAllMultiplier));
				}
				else
				{
					TF2Attrib_SetByName(client,"damage bonus", 4.0);
				}
				if((additionalstartmoney+StartMoney) <= 750000 / OverAllMultiplier)
				{
					TF2Attrib_SetByName(secondary,"Blast radius increased",1+(((additionalstartmoney+StartMoney)/250000.0) *OverAllMultiplier));
					TF2Attrib_SetByName(secondary,"Projectile speed increased",1+(((additionalstartmoney+StartMoney)/300000.0) *OverAllMultiplier));
				}
				else
				{
					TF2Attrib_SetByName(secondary,"Blast radius increased",(4.0));
					TF2Attrib_SetByName(secondary,"Projectile speed increased",(3.5));
				}
				for(i=0;i<3;i++)
				{
					int weap = GetWeapon(client,i);
					if((additionalstartmoney+StartMoney) <= 1000000 / OverAllMultiplier)
					{
						TF2Attrib_SetByName(weap,"fire rate bonus",(25000.0/(additionalstartmoney+StartMoney)) / OverAllMultiplier);
					}
					else
					{
						TF2Attrib_SetByName(weap,"fire rate bonus",(0.025));
					}
				}
				if((additionalstartmoney+StartMoney) <= 1000000 / OverAllMultiplier)
				{
					TF2Attrib_SetByName(primary,"flame_speed",3500 + ((additionalstartmoney+StartMoney)/100.0) *OverAllMultiplier);
				}
				else
				{
					TF2Attrib_SetByName(primary,"flame_speed",(13500.0));
				}
				
			}
			case TFClass_DemoMan:
			{
				TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/152.25) *OverAllMultiplier);
				TF2Attrib_SetByName(client,"clip size bonus",((additionalstartmoney+StartMoney)/11000.0) *OverAllMultiplier);
				TF2Attrib_SetByName(client,"disguise on backstab",((additionalstartmoney+StartMoney)/7750.0) *OverAllMultiplier);
				if((additionalstartmoney+StartMoney) <= 480000/OverAllMultiplier)
				{
					TF2Attrib_SetByName(client,"damage bonus",1+(((additionalstartmoney+StartMoney)/160000.0)*OverAllMultiplier));
				}
				else
				{
					TF2Attrib_SetByName(client,"damage bonus", 4.0);
				}
				TF2Attrib_SetByName(secondary, "stickybomb charge rate", 0.005);
				TF2Attrib_SetByName(secondary, "sticky arm time bonus", -0.25);
				TF2Attrib_SetByName(primary,"Projectile speed increased",(2.5));
				TF2Attrib_SetByName(secondary,"Projectile speed increased",(3.5));
				for(i=0;i<3;i++)
				{
					int weap = GetWeapon(client,i);
					if(i != 2)
					{
						if((additionalstartmoney+StartMoney) <= 750000 / OverAllMultiplier)
						{
							TF2Attrib_SetByName(weap,"Blast radius increased",1+((additionalstartmoney+StartMoney)/250000.0) *OverAllMultiplier);
						}
						else
						{
							TF2Attrib_SetByName(weap,"Blast radius increased",(4.0));
						}
					}
					if((additionalstartmoney+StartMoney) <= 1000000 / OverAllMultiplier)
					{
						TF2Attrib_SetByName(weap,"fire rate bonus",(25000.0/(additionalstartmoney+StartMoney)) / OverAllMultiplier);
					}
					else
					{
						TF2Attrib_SetByName(weap,"fire rate bonus",(0.025));
					}
				}
			}
			case TFClass_Heavy:
			{
				TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/108.75) *OverAllMultiplier);
				TF2Attrib_SetByName(client,"disguise on backstab",((additionalstartmoney+StartMoney)/5000.0) *OverAllMultiplier);
				if((additionalstartmoney+StartMoney) <= 480000/OverAllMultiplier)
				{
					TF2Attrib_SetByName(client,"damage bonus",1+(((additionalstartmoney+StartMoney)/160000.0)*OverAllMultiplier));
				}
				else
				{
					TF2Attrib_SetByName(client,"damage bonus", 4.0);
				}
				for(i=0;i<3;i++)
				{
					int weap = GetWeapon(client,i);
					if((additionalstartmoney+StartMoney) > 90000)
					{
						if((additionalstartmoney+StartMoney) <= 1500000 / OverAllMultiplier)
						{
							TF2Attrib_SetByName(weap,"fire rate bonus",(90000/(additionalstartmoney+StartMoney)) / OverAllMultiplier);
						}
						else
						{
							TF2Attrib_SetByName(weap,"fire rate bonus", 0.06);
						}
					}
				}
			}
			case TFClass_Sniper:
			{
				TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/195.75) *OverAllMultiplier);
				TF2Attrib_SetByName(client,"disguise on backstab",((additionalstartmoney+StartMoney)/11000.0) *OverAllMultiplier);
				TF2Attrib_SetByName(client,"clip size bonus",((additionalstartmoney+StartMoney)/6000.0) *OverAllMultiplier);
				TF2Attrib_SetByName(primary,"headshot damage increase", 0.8);
				if((additionalstartmoney+StartMoney) <= 480000/OverAllMultiplier)
				{
					TF2Attrib_SetByName(client,"damage bonus",1+(((additionalstartmoney+StartMoney)/160000.0)*OverAllMultiplier));
				}
				else
				{
					TF2Attrib_SetByName(client,"damage bonus", 4.0);
				}
				for(i=0;i<3;i++)
				{
					int weap = GetWeapon(client,i);
					if((additionalstartmoney+StartMoney) <= 800000/OverAllMultiplier)
					{
						TF2Attrib_SetByName(weap,"fire rate bonus",(40000.0/(additionalstartmoney+StartMoney))/OverAllMultiplier);
					}
					else
					{
						TF2Attrib_SetByName(weap,"fire rate bonus",(0.05));
					}
				}
				TF2Attrib_SetByName(primary,"faster reload rate",(0.4));
				TF2Attrib_SetByName(secondary,"faster reload rate",(0.0));
			}
			case TFClass_Spy:
			{
				TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/348.0)*OverAllMultiplier);
				TF2Attrib_SetByName(client,"disguise on backstab",((additionalstartmoney+StartMoney)/6000.0)*OverAllMultiplier);
				TF2Attrib_SetByName(client,"mult decloak rate",(20000.0/(additionalstartmoney+StartMoney)) /OverAllMultiplier);
				TF2Attrib_SetByName(client,"mult cloak rate",((20000.0/(additionalstartmoney+StartMoney))-1) /OverAllMultiplier);
				TF2Attrib_SetByName(client,"clip size bonus",((additionalstartmoney+StartMoney)/11000.0)*OverAllMultiplier);
				TF2Attrib_RemoveByName(client,"damage penalty");
				TF2Attrib_RemoveByName(client,"dmg penalty vs players");		
				if((additionalstartmoney+StartMoney) <= 480000/OverAllMultiplier)
				{
					TF2Attrib_SetByName(client,"damage bonus",1+(((additionalstartmoney+StartMoney)/160000.0)*OverAllMultiplier));
				}
				else
				{
					TF2Attrib_SetByName(client,"damage bonus", 4.0);
				}
				if((additionalstartmoney+StartMoney) >= 1000000){
				TF2Attrib_SetByName(primary,"damage penalty",((additionalstartmoney+StartMoney)/17000.0)*OverAllMultiplier);
				TF2Attrib_SetByName(primary,"damage mult 1",((additionalstartmoney+StartMoney)/22000.0)*OverAllMultiplier);
				TF2Attrib_SetByName(melee,"damage penalty",((additionalstartmoney+StartMoney)/16000.0)*OverAllMultiplier);
				TF2Attrib_SetByName(melee,"damage mult 1",((additionalstartmoney+StartMoney)/20000.0)*OverAllMultiplier);
				}
				else
				{
					TF2Attrib_SetByName(primary,"damage penalty",((additionalstartmoney+StartMoney)/15000.0)*OverAllMultiplier);
					TF2Attrib_SetByName(primary,"damage mult 1",((additionalstartmoney+StartMoney)/18000.0)*OverAllMultiplier);
					TF2Attrib_SetByName(melee,"damage penalty",((additionalstartmoney+StartMoney)/14000.0)*OverAllMultiplier);
					TF2Attrib_SetByName(melee,"damage mult 1",((additionalstartmoney+StartMoney)/16000.0)*OverAllMultiplier);
				}
				if((additionalstartmoney+StartMoney) >= 60000/OverAllMultiplier)
				{
					TF2Attrib_SetByName(primary,"fire rate bonus",(60000.0/(additionalstartmoney+StartMoney))/OverAllMultiplier);
					TF2Attrib_SetByName(melee,"fire rate bonus",(60000.0/(additionalstartmoney+StartMoney))/OverAllMultiplier);
				}
			}
			case TFClass_Medic:
			{
				TF2Attrib_SetByName(client,"max health additive bonus",((additionalstartmoney+StartMoney)/174.0)*OverAllMultiplier);
				TF2Attrib_SetByName(client,"disguise on backstab",((additionalstartmoney+StartMoney)/6150.0)*OverAllMultiplier);
				TF2Attrib_SetByName(client,"heal rate bonus",((additionalstartmoney+StartMoney)/11000.0)*OverAllMultiplier);
				TF2Attrib_SetByName(client,"overheal bonus",1+(((additionalstartmoney+StartMoney)/120000.0)*OverAllMultiplier));
				if((additionalstartmoney+StartMoney) <= 480000/OverAllMultiplier)
				{
					TF2Attrib_SetByName(client,"damage bonus",1+(((additionalstartmoney+StartMoney)/160000.0)*OverAllMultiplier));
				}
				else
				{
					TF2Attrib_SetByName(client,"damage bonus", 4.0);
				}
				if((additionalstartmoney+StartMoney) >= 350000/OverAllMultiplier)
				{
					TF2Attrib_SetByName(primary,"override projectile type",(1.0));
				}
				if((additionalstartmoney+StartMoney) <= 800000/OverAllMultiplier)
				{
					TF2Attrib_SetByName(primary,"fire rate bonus",(20000.0/(additionalstartmoney+StartMoney))/OverAllMultiplier);
					TF2Attrib_SetByName(melee,"fire rate bonus",(20000.0/(additionalstartmoney+StartMoney))/OverAllMultiplier);
				}
				else
				{
					TF2Attrib_SetByName(primary,"fire rate bonus",(0.025));
					TF2Attrib_SetByName(melee,"fire rate bonus",(0.025));
				}
			}
		}
		RespawnEffect(client)
		refreshUpgrades(client,0);
		refreshUpgrades(client,1);
		refreshUpgrades(client,2);
		refreshUpgrades(client,4);
	}
}
ExplosiveArrow(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEntity(entity))
	{
		if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(IsValidClient(owner))
			{
				int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					Address ignitionChance = TF2Attrib_GetByName(CWeapon, "Wrench index");
					if(ignitionChance != Address_Null)
					{
						if(TF2Attrib_GetValue(ignitionChance) >= GetRandomFloat(0.0, 1.0))
						{
							SetEntProp(entity, Prop_Send, "m_bArrowAlight", 1);
							
							Address ignitionExplosion = TF2Attrib_GetByName(CWeapon, "damage applies to sappers");
							if(ignitionExplosion != Address_Null && TF2Attrib_GetValue(ignitionExplosion) > 0.0)
							{
								jarateWeapon[entity] = EntIndexToEntRef(CWeapon)
								SDKHook(entity, SDKHook_StartTouchPost, IgnitionArrowCollision);
							}
						}
					}
					if(fl_ArrowStormDuration[owner] > 0.0)
					{
						jarateWeapon[entity] = EntIndexToEntRef(CWeapon)
						SDKHook(entity, SDKHook_StartTouchPost, ExplosiveArrowCollision);
					}
				}
			}
		}
	}
}
disableWeapon(client)
{
	int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1.0);
}
StunShotFunc(client)
{
	int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.6);
	CreateTimer(0.5, removeBulletsPerShot, client);
}
AirblastPatch(client)
{
	if( !IsPlayerAlive(client) )
		return;
	
	if( TF2_GetPlayerClass(client) != TFClass_Pyro )
		return;

	int iNextTickTime = RoundToNearest(GetGameTime()/GetTickInterval())+ 5;
	SetEntProp( client, Prop_Data, "m_nNextThinkTick", iNextTickTime );
	
	if( GetEntProp( client, Prop_Data, "m_nWaterLevel" ) > 1 )
		return;
	
	if( (GetClientButtons(client) & IN_ATTACK2) != IN_ATTACK2 )
		return;

	int iWeapon = GetEntPropEnt( client, Prop_Send, "m_hActiveWeapon" );
	if( !IsValidEntity(iWeapon) )
		return;
	
	char strClassname[64];
	GetEntityClassname( iWeapon, strClassname, sizeof(strClassname) );
	if( !StrEqual( strClassname, "tf_weapon_flamethrower", false ) &&  !StrEqual( strClassname, "tf_weapon_rocketlauncher_fireball", false ) )
		return;

	if( ( GetEntPropFloat( iWeapon, Prop_Send, "m_flNextSecondaryAttack" ) - flNextSecondaryAttack[client] ) <= 0.0 )
		return;
		
	flNextSecondaryAttack[client] = GetEntPropFloat( iWeapon, Prop_Send, "m_flNextSecondaryAttack" );
	
	float SlowForce = 2.0,AirblastDamage = 80.0,TotalRange = 600.0,Duration = 1.25,ConeRadius = 40.0;
	Address SlowActive = TF2Attrib_GetByName(iWeapon, "airblast vertical pushback scale");
	Address DamageActive = TF2Attrib_GetByName(iWeapon, "airblast pushback scale");
	Address RangeActive = TF2Attrib_GetByName(iWeapon, "deflection size multiplier");
	Address DurationActive = TF2Attrib_GetByName(iWeapon, "melee range multiplier");
	Address RadiusActive = TF2Attrib_GetByName(iWeapon, "melee bounds multiplier");

	if(SlowActive != Address_Null){
		SlowForce *= TF2Attrib_GetValue(SlowActive)
	}
	if(DamageActive != Address_Null){
		AirblastDamage *= TF2Attrib_GetValue(DamageActive)
	}
	if(RangeActive != Address_Null){
		TotalRange *= TF2Attrib_GetValue(RangeActive)
	}
	if(DurationActive != Address_Null){
		Duration *= TF2Attrib_GetValue(DurationActive)
	}
	if(RadiusActive != Address_Null){
		ConeRadius *= TF2Attrib_GetValue(RadiusActive)
	}	
	AirblastDamage *= TF2_GetDamageModifiers(client, iWeapon);
	
	Address lameMult = TF2Attrib_GetByName(iWeapon, "dmg penalty vs players");
	if(lameMult != Address_Null)//lame. AP applies twice.
	{
		AirblastDamage /= TF2Attrib_GetValue(lameMult);
	}
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsValidClient3(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(IsTargetInSightRange(client, i, ConeRadius, TotalRange, true, false))
			{
				if(IsAbleToSee(client,i, false) == true)
				{
					if(GetClientTeam(i) != GetClientTeam(client))//Enemies debuffed
					{
						CurrentSlowTimer[i] = Duration;
						SDKHooks_TakeDamage(i,client,client,AirblastDamage,DMG_BLAST,iWeapon, NULL_VECTOR, NULL_VECTOR);
						
						bool immune = false;
						
						Address agilityPowerup = TF2Attrib_GetByName(client, "agility powerup");		
						if(agilityPowerup != Address_Null && TF2Attrib_GetValue(agilityPowerup) > 0.0)
						{
							immune = true;
						}
						if(TF2_IsPlayerInCondition(i,TFCond_MegaHeal))
						{
							immune = true;
						}
						if(!immune)
						{
							TF2Attrib_SetByName(i,"move speed penalty", 1/SlowForce);
							TF2Attrib_SetByName(i,"major increased jump height", Pow(1.2/SlowForce,0.3));
						}
						//PrintToChat(client, "%N was airblasted. Took %.2f base damage and was slowed for %.2f seconds.", i, AirblastDamage, Duration);
					}
					else//Teammates buffed.
					{
						TF2_AddCondition(i, TFCond_AfterburnImmune, 6.0);
						TF2_AddCondition(i, TFCond_SpeedBuffAlly, 6.0);
						TF2_AddCondition(i, TFCond_DodgeChance, 0.2);
					}
				}
			}
		}
	}
}
public BoomerangThink(entity) 
{ 
	if(IsValidEntity(entity) && GetGameTime() - entitySpawnTime[entity] > 0.3 && GetGameTime() - entitySpawnTime[entity] < 0.92)
	{
		float ProjAngle[3],ProjVelocity[3],vBuffer[3],speed;
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
		ProjAngle[1] += 5.5;
		ProjAngle[0] = 0.0;
		GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", ProjVelocity);
		speed = GetVectorLength(ProjVelocity)
		GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR)
		ProjVelocity[0] = vBuffer[0] * speed;
		ProjVelocity[1] = vBuffer[1] * speed;
		ProjVelocity[2] = vBuffer[2] * speed;
		TeleportEntity(entity, NULL_VECTOR, ProjAngle, ProjVelocity);
	}
}
checkRadiation(victim,attacker)
{
	if(RadiationBuildup[victim] >= RadiationMaximum[victim])
	{
		RadiationBuildup[victim] = 0.0;
		if(!IsFakeClient(victim))
		{
			float victimMaxArmor = 300.0;
			Address armorActive = TF2Attrib_GetByName(victim, "obsolete ammo penalty")
			if(armorActive != Address_Null)
			{
				float armorAmount = TF2Attrib_GetValue(armorActive);
				victimMaxArmor += armorAmount;
			}
			int armorLost = RoundToNearest(victimMaxArmor/2.0);
			DealFakeDamage(victim,attacker,-1, armorLost);
			TF2_AddCondition(victim, TFCond_NoTaunting_DEPRECATED, 5.0);
			
			float particleOffset[3] = {0.0,0.0,10.0};
			CreateParticle(victim, "utaunt_electricity_cloud_electricity_WY", true, "", 5.0, particleOffset);
			CreateParticle(victim, "utaunt_auroraglow_green_parent", true, "", 5.0);
			CreateParticle(victim, "merasmus_blood", true, "", 2.0);
		}
		else
		{
			miniCritStatusVictim[victim] = 7.5;
			TF2_AddCondition(victim, TFCond_Bleeding, 7.5);
			TF2_AddCondition(victim, TFCond_AirCurrent, 7.5);
			TF2_AddCondition(victim, TFCond_NoTaunting_DEPRECATED, 7.5);
			float particleOffset[3] = {0.0,0.0,10.0};
			CreateParticle(victim, "utaunt_electricity_cloud_electricity_WY", true, "", 7.5, particleOffset);
			CreateParticle(victim, "utaunt_auroraglow_green_parent", true, "", 7.5);
			CreateParticle(victim, "merasmus_blood", true, "", 7.5);
		}
	}
}
monoculusBonus(entity) 
{
	entity = EntRefToEntIndex(entity);
    if(IsValidEdict(entity)) 
    { 
		int monoculus = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidEntity(monoculus))
		{
			int client = EntRefToEntIndex(jarateWeapon[monoculus]);
			if(IsValidClient3(client))
			{
				float vAngles[3],vPosition[3],vBuffer[3],vVelocity[3],vel[3],projspd = 3.0;
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPosition);
				GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
				GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
				GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
				vVelocity[0] = vBuffer[0]*projspd*GetVectorLength(vel);
				vVelocity[1] = vBuffer[1]*projspd*GetVectorLength(vel);
				vVelocity[2] = vBuffer[2]*projspd*GetVectorLength(vel);
				TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
				
				int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					SetEntDataFloat(entity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 90.0 * TF2_GetDamageModifiers(client,CWeapon), true);  
				}
			}
		}
    } 
}
checkEnabledSentry(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEntity(entity))
	{
		if(HasEntProp(entity,Prop_Send,"m_hBuilder"))
		{
			int owner = GetEntPropEnt(entity,Prop_Send,"m_hBuilder" );
			if(IsValidClient3(owner))
			{
				int melee = (GetPlayerWeaponSlot(owner,2));
				if(IsValidEntity(melee))
				{
					int weaponIndex = GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex");
					if(weaponIndex == 589)
					{
						PrintToChat(owner, "Your sentry is disabled (Eureka Effect).");
						RemoveEntity(entity);
					}
				}
			}
		}
	}
}
public bool applyArcaneRestrictions(int client, int attuneSlot, float focusCost, float cooldown)
{
	focusCost /= ArcanePower[client];
	if(fl_CurrentFocus[client] < focusCost)
	{
		PrintHintText(client, "Not enough focus! Requires %.2f focus.",focusCost);
		EmitSoundToClient(client, SOUND_FAIL);
		return true;
	}
	if(SpellCooldowns[client][attuneSlot] > 0.0)
		return true;

	PrintHintText(client, "Used %s! -%.2f focus.",SpellList[RoundToNearest(AttunedSpells[client][attuneSlot])-1],focusCost);
	fl_CurrentFocus[client] -= focusCost;
	if(DisableCooldowns != 1)
		SpellCooldowns[client][attuneSlot] = cooldown;
	applyArcaneCooldownReduction(client, attuneSlot);

	return false;
}
randomizeTankSpecialty(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEntity(entity))//In case if the tank somehow instantly despawns.
	{
		int specialtyID = GetRandomInt(0,1);
		switch(specialtyID)
		{
			case 0:
			{
				int iEntity = CreateEntityByName("obj_sentrygun");
				if(IsValidEntity(iEntity))
				{
					float position[3];
					GetEntPropVector(entity, Prop_Data, "m_vecOrigin", position);
					
					int iLink = CreateLink(entity);
					
					SetVariantString("!activator");
					AcceptEntityInput(iEntity, "SetParent", iLink);  
					SetEntPropEnt(entity, Prop_Send, "m_hEffectEntity", iLink);
					position[2] += 200.0;
					
					TeleportEntity(iEntity, position, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(iEntity);
					SetEntProp(iEntity, Prop_Data, "m_spawnflags", 8);
					SetEntProp(iEntity, Prop_Data, "m_takedamage", 0);
					SetEntProp(iEntity, Prop_Send, "m_iUpgradeLevel", 3);
					SetEntProp(iEntity, Prop_Send, "m_iHighestUpgradeLevel", 3);
					SetEntProp(iEntity, Prop_Send, "m_nSkin", 1);
					SetEntProp(iEntity, Prop_Send, "m_bBuilding", 1);
					SetEntProp(iEntity, Prop_Send, "m_nSolidType", 2);
					SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0);
					SetEntProp(iEntity, Prop_Send, "m_hBuiltOnEntity", entity);
					SetVariantInt(3);
					AcceptEntityInput(iEntity, "SetTeam");
					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 3)
					if(IsValidEntity(logic))
					{
						int round = GetEntProp(logic, Prop_Send, "m_nMannVsMachineWaveCount");
						TankSentryDamageMod = Pow((waveToCurrency[round]/11000.0), DamageMod + (round * 0.03)) * 1.8 * OverallMod;
					}
				}
			}
			case 1:
			{
				if(!IsValidEntity(TankTeleporter))
				{
					int iEntity = CreateEntityByName("obj_teleporter");
					if(IsValidEntity(iEntity))
					{
						float position[3];
						GetEntPropVector(entity, Prop_Data, "m_vecOrigin", position);
						
						int iLink = CreateLink(entity);
						
						SetVariantString("!activator");
						AcceptEntityInput(iEntity, "SetParent", iLink);  
						SetEntPropEnt(entity, Prop_Send, "m_hEffectEntity", iLink);
						
						position[2] += 200.0;
						
						TeleportEntity(iEntity, position, NULL_VECTOR, NULL_VECTOR);
						DispatchSpawn(iEntity);
						SetEntProp(iEntity, Prop_Data, "m_spawnflags", 6);
						SetEntProp(iEntity, Prop_Data, "m_takedamage", 0);
						SetEntProp(iEntity, Prop_Send, "m_nSkin", 1);
						SetEntProp(iEntity, Prop_Send, "m_bBuilding", 1);
						SetVariantInt(3);
						AcceptEntityInput(iEntity, "SetTeam");
						SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 3)
						SetEntProp(iEntity, Prop_Data, "m_iTeleportType", TFObjectMode_Exit);
						SetEntProp(iEntity, Prop_Send, "m_iObjectMode", TFObjectMode_Exit);
						CreateTimer(10.0, SetTankTeleporter, EntIndexToEntRef(entity));
					}
				}
			}
		}
	}
}
ChangeProjModel(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEntity(entity))
	{
		int client;
		if(HasEntProp(entity, Prop_Data, "m_hThrower"))
		{
			client = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		}
		else if(HasEntProp(entity, Prop_Data, "m_hOwnerEntity"))
		{
			client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		}
		if(IsValidClient(client))
		{
			int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(CWeapon))
			{
				int iItemDefinitionIndex = GetEntProp(CWeapon, Prop_Send, "m_iItemDefinitionIndex");
				switch(iItemDefinitionIndex)
				{
					case 222:
					{
						SetEntityModel(entity, "models/weapons/c_models/c_madmilk/c_madmilk.mdl");
						SDKHook(entity, SDKHook_StartTouch, OnStartTouchJars);
						gravChanges[entity] = true;
						jarateType[entity] = 1;
						jarateWeapon[entity] = EntIndexToEntRef(CWeapon);
						SetEntityGravity(entity, 1.75);
					}
					case 1121:
					{
						SetEntityModel(entity, "models/weapons/c_models/c_breadmonster/c_breadmonster_milk.mdl");
						SDKHook(entity, SDKHook_StartTouch, OnStartTouchJars);
						gravChanges[entity] = true;
						jarateType[entity] = 1;
						jarateWeapon[entity] = EntIndexToEntRef(CWeapon);
						SetEntityGravity(entity, 1.75);
					}
					case 58,1149:
					{
						SetEntityModel(entity, "models/weapons/c_models/urinejar.mdl");
						SDKHook(entity, SDKHook_StartTouch, OnStartTouchJars);
						gravChanges[entity] = true;
						jarateType[entity] = 0;
						jarateWeapon[entity] = EntIndexToEntRef(CWeapon);
						SetEntityGravity(entity, 1.75);
					}
					case 1105:
					{
						SetEntityModel(entity, "models/weapons/c_models/c_breadmonster/c_breadmonster.mdl");
						SDKHook(entity, SDKHook_StartTouch, OnStartTouchJars);
						gravChanges[entity] = true;
						jarateType[entity] = 0;
						jarateWeapon[entity] = EntIndexToEntRef(CWeapon);
						SetEntityGravity(entity, 1.75);
					}
					case 812,833:
					{
						SetEntityModel(entity, "models/weapons/c_models/c_sd_cleaver/c_sd_cleaver.mdl");
					}
				}
			}
		}
	}
}
SentryDelay(entity) 
{
	entity = EntRefToEntIndex(entity);
    if(IsValidEdict(entity)) 
    {
		int building = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		//PrintToChatAll("1");
		if(!IsValidClient3(building) && IsValidEntity(building) && HasEntProp(building,Prop_Send,"m_hBuilder"))
		{
			//PrintToChatAll("2");
			int owner = GetEntPropEnt(building,Prop_Send,"m_hBuilder" );
			if(IsValidClient3(owner))
			{
				//PrintToChatAll("3");
				int melee = GetWeapon(owner,2);
				if(IsValidEntity(melee))
				{
					//PrintToChatAll("4");
					Address projspeed = TF2Attrib_GetByName(melee, "Projectile speed increased");
					Address projspeed1 = TF2Attrib_GetByName(melee, "Projectile speed decreased");
					if(projspeed != Address_Null || projspeed1 != Address_Null)
					{
						//PrintToChatAll("5");
						float vAngles[3],vPosition[3],vBuffer[3],vVelocity[3],vel[3],projspd = 1.0;
						GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPosition);
						GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
						GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", vel); 
						GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
						if(projspeed != Address_Null){
							projspd *= TF2Attrib_GetValue(projspeed)
						}
						if(projspeed1 != Address_Null){
							projspd *= TF2Attrib_GetValue(projspeed1)
						}
						vVelocity[0] = vBuffer[0]*projspd*GetVectorLength(vel);
						vVelocity[1] = vBuffer[1]*projspd*GetVectorLength(vel);
						vVelocity[2] = vBuffer[2]*projspd*GetVectorLength(vel);
						TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
						SetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", vVelocity); 
					}
				}
			}
		}
    } 
}
/*TeleportToNearestPlayer(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEntity(entity))
	{
		float EntityPos[3];
		float distance = 30000.0;
		float ClientPosition[3];
		int ClosestClient = -1;
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", EntityPos); 
		for( int client = 1; client <= MaxClients; client++ )
		{
			if(IsValidClient(client) && !IsClientObserver(client) && IsPlayerAlive(client))
			{ 
				GetClientAbsOrigin(client, ClientPosition);
				if(TF2_GetPlayerClass(client) == TFClass_Scout)
				{
					ClosestClient = client;
					break;
				}
				float CalcDistance = GetVectorDistance(EntityPos,ClientPosition); 
				if(distance > CalcDistance)
				{
					distance = CalcDistance;
					ClosestClient = client;
				}
			}
		}
		if(IsValidClient(ClosestClient))
		{
			TeleportEntity(entity, ClientPosition, NULL_VECTOR, NULL_VECTOR);
		}
	}
}*/
public int getClientParticleStatus(int array[33], int client){
	bool particleEnabler = false;
	if(AreClientCookiesCached(client)){
		char particleEnabled[64];
		GetClientCookie(client, particleToggle, particleEnabled, sizeof(particleEnabled));
		float menuValue = StringToFloat(particleEnabled);
		if(menuValue == 1.0){
			particleEnabler = true;
		}
	}
	int numClients;
	for(int i=1;i<MaxClients;i++){
		if(IsValidClient3(i) && (i != client || particleEnabler == true)){
			array[numClients++] = i;
		}
	}
	return numClients;
}
public void SetZeroGravity(ref)
{
	int entity = EntRefToEntIndex(ref); 
    if(IsValidEdict(entity)) 
    { 
		SetEntityGravity(entity, -0.003);
    }
}
public void OnHomingThink(entity) 
{ 
	if(IsValidEntity(entity))
	{
		int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient3(owner))
		{
			int Target = GetClosestTarget(entity, owner); 
			if(IsValidClient3(Target))
			{
				if(owner != Target)
				{
					float TargetPos[3];
					GetClientAbsOrigin(Target, TargetPos);
					TargetPos[2]+=40.0;
					float flRocketPos[3];
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", flRocketPos);
					float distance = GetVectorDistance( flRocketPos, TargetPos ); 
					
					if( distance <= projectileHomingDegree[entity] && GetGameTime() - entitySpawnTime[entity] < 3.0 )
					{
						float ProjVector[3],BaseSpeed,NewSpeed,ProjAngle[3],AimVector[3],InitialSpeed[3]; 
						
						GetEntPropVector( entity, Prop_Send, "m_vInitialVelocity", InitialSpeed ); 
						if ( GetVectorLength( InitialSpeed ) < 10.0 ) GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", InitialSpeed ); 
						BaseSpeed = GetVectorLength( InitialSpeed ) * 0.3; 
						
						GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", flRocketPos ); 
						GetClientAbsOrigin( Target, TargetPos ); 
						TargetPos[2] += 20.0;
						MakeVectorFromPoints( flRocketPos, TargetPos, AimVector ); 
						
						if(distance <= projectileHomingDegree[entity]*2.0 + 20.0)
						{
							SubtractVectors( TargetPos, flRocketPos, ProjVector ); //100% HOME
						}
						else
						{
							GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", ProjVector ); //50% HOME
						}
						AddVectors( ProjVector, AimVector, ProjVector ); 
						NormalizeVector( ProjVector, ProjVector );
						
						GetEntPropVector( entity, Prop_Data, "m_angRotation", ProjAngle ); 
						GetVectorAngles( ProjVector, ProjAngle ); 
						
						NewSpeed = ( BaseSpeed * 2.0 ) + 1.0 * BaseSpeed * 1.02; 
						ScaleVector( ProjVector, NewSpeed ); 
						
						TeleportEntity( entity, NULL_VECTOR, ProjAngle, ProjVector ); 
					}
				}
			}
		}
	}
}
public OnThinkPost(entity) 
{ 
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
							float flTargetPos[3];
							GetClientAbsOrigin(Target, flTargetPos);
							flTargetPos[2]+=40.0;
							float flRocketPos[3];
							GetEntPropVector(entity, Prop_Send, "m_vecOrigin", flRocketPos);
							float distance = GetVectorDistance( flRocketPos, flTargetPos ); 
							
							if( distance <= maxDistance )
							{
								float flVelocityChange[3];
								TeleportEntity(entity, flTargetPos, NULL_VECTOR, flVelocityChange);
							}
						}
					}
				}
			}
		}
	}
}
public getProjOrigin(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEntity(entity))
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entitySpawnPositions[entity]);
}
public OnFireballThink(entity)
{
	if(IsValidEntity(entity))
	{
		int owner = getOwner(entity);
		if(!IsValidClient3(owner))
			return;
		int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
		if(!IsValidWeapon(CWeapon))
			return;

		float distance = GetAttribute(CWeapon, "fireball distance", 500.0);
		float origin[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		if(GetVectorDistance(entitySpawnPositions[entity], origin) > distance)
			{RemoveEntity(entity);}
	}
}
public OnEntityHomingThink(entity) 
{ 
	if(!IsValidEntity(entity))
		return;

	if(!HasEntProp(entity,Prop_Send,"m_vInitialVelocity"))
		return;

	int owner = GetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity" ); 
	if(!IsValidClient3(owner) && IsValidEntity(owner) && HasEntProp(owner,Prop_Send,"m_hBuilder"))
	{
		owner = GetEntPropEnt(owner,Prop_Send,"m_hBuilder" );
	}

	if (!IsValidClient3(owner))
		return;

	int Target = GetClosestTarget(entity, owner); 
	if(!IsValidClient3(Target) || owner == Target)
		return;


	float EntityPos[3], TargetPos[3]; 
	GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityPos ); 
	GetClientAbsOrigin( Target, TargetPos ); 
	float distance = GetVectorDistance( EntityPos, TargetPos ); 

	if( distance > homingRadius[entity] )
		return;

	if(homingTicks[entity] & homingTickRate[entity] == 1 || homingTickRate[entity] == 0)
	{
		float ProjLocation[3], ProjVector[3], BaseSpeed, NewSpeed, ProjAngle[3], AimVector[3], InitialSpeed[3]; 
		
		GetEntPropVector( entity, Prop_Send, "m_vInitialVelocity", InitialSpeed ); 
		if ( GetVectorLength( InitialSpeed ) < 10.0 ) GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", InitialSpeed ); 
		BaseSpeed = GetVectorLength( InitialSpeed ) * 0.3; 
		
		GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", ProjLocation ); 
		GetClientAbsOrigin( Target, TargetPos ); 
		TargetPos[2] += 20.0;
		MakeVectorFromPoints( ProjLocation, TargetPos, AimVector ); 
		
		GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", ProjVector ); //50% HOME
		//SubtractVectors( TargetPos, ProjLocation, ProjVector ); //100% HOME
		AddVectors( ProjVector, AimVector, ProjVector ); 
		NormalizeVector( ProjVector, ProjVector ); 
		
		GetEntPropVector( entity, Prop_Data, "m_angRotation", ProjAngle ); 
		GetVectorAngles( ProjVector, ProjAngle ); 
		
		NewSpeed = ( BaseSpeed * 2.0 ) + 1.0 * BaseSpeed * 1.1; 
		ScaleVector( ProjVector, NewSpeed ); 
		
		TeleportEntity( entity, NULL_VECTOR, ProjAngle, ProjVector ); 
		SetEntityGravity(entity, 0.001);
	}
	homingTicks[entity]++;
}
TF2_Override_ChargeSpeed(client)
{
	int secondary = GetWeapon(client,1);
	if(IsValidWeapon(secondary))
	{
		float velocity = GetAttribute(secondary, "Charging Velocity", 750.0);
		velocity *= GetAttribute(client, "agility powerup") != 0.0 ? 1.8 : 1.0;
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
		SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", velocity);
		
	}
}
CheckGrenadeMines(ref)
{
	int entity = EntRefToEntIndex(ref); 
	if(IsValidEntity(entity) && HasEntProp(entity, Prop_Data, "m_hThrower") == true)
    {
        int client = GetEntPropEnt(entity, Prop_Data, "m_hThrower"); 
        if (IsValidClient(client) && IsPlayerAlive(client))
		{
			int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(CWeapon))
			{
				Address minesActive = TF2Attrib_GetByName(CWeapon, "enables aoe heal");
				if(minesActive != Address_Null && TF2Attrib_GetValue(minesActive) <= 0.01)
				{
					float damage = 90.0 * TF2_GetDamageModifiers(client,CWeapon);
					float radius = 100.8;
					CreateTimer(0.04,Timer_PlayerGrenadeMines,  EntIndexToEntRef(entity), TIMER_REPEAT);
					CreateTimer(TF2Attrib_GetValue(minesActive) * -3.0,SelfDestruct,  EntIndexToEntRef(entity));
					
					Address blastRadius1 = TF2Attrib_GetByName(CWeapon, "Blast radius increased");
					Address blastRadius2 = TF2Attrib_GetByName(CWeapon, "Blast radius decreased");
					if(blastRadius1 != Address_Null){
						radius *= TF2Attrib_GetValue(blastRadius1)
					}
					if(blastRadius2 != Address_Null){
						radius *= TF2Attrib_GetValue(blastRadius2)
					}
					SetEntPropFloat(entity, Prop_Send, "m_DmgRadius", radius);
					SetEntPropFloat(entity, Prop_Send, "m_flDamage", damage);
					if(TF2Attrib_GetValue(minesActive) > -4.0)
						SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
				}
			}
		}
	}
}
MultiShot(ref) 
{ 
    int entity = EntRefToEntIndex(ref);
    if(IsValidEdict(entity)) 
    {
		if(debugMode)
			PrintToChatAll("Multishot | ValidEntity");
		int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(HasEntProp(entity, Prop_Data, "m_hThrower"))
		{
			owner = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		}
		if(IsValidClient(owner))
		{
			if(debugMode)
				PrintToChatAll("Multishot | Has Owner");
			if(canShootAgain[owner] == true)
			{
				if(debugMode)
					PrintToChatAll("Multishot | Can Shoot");
				canShootAgain[owner] = false
				int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					Address projActive = TF2Attrib_GetByName(CWeapon, "deflection size multiplier");
					Address spread1 = TF2Attrib_GetByName(CWeapon, "projectile spread angle penalty");
					if(projActive != Address_Null)
					{
						float spread = 3.0;
						if(spread1 != Address_Null)
						{
							spread += TF2Attrib_GetValue(spread1)
						}
						float projShoot = TF2Attrib_GetValue(projActive)
						for (int v = 0; v < projShoot+1; v++)
						{
							if(RoundToCeil(projShoot+1)/2 != v)
							{
								char projName[32];
								GetEntityClassname(entity, projName, 32)
								if(debugMode)
									PrintToChatAll(projName);
								int iEntity = CreateEntityByName(projName);
								if (IsValidEdict(iEntity)) 
								{
									int iTeam = GetClientTeam(owner);
									float fAngles[3],fOrigin[3],vBuffer[3],fVelocity[3],fwd[3]
									SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);

									//SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
									//SetEntityRenderColor(iEntity, 0, 0, 0, 0);
						
									SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
									SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", owner);
									if(HasEntProp(entity, Prop_Send, "m_bCritical") && GetEntProp(entity, Prop_Send, "m_bCritical", 4) == 1){
									SetEntProp(iEntity, Prop_Send, "m_bCritical", 1);
									}
									GetClientEyePosition(owner, fOrigin);
									GetClientEyeAngles(owner, fAngles);
									fAngles[1] -= (spread * projShoot * 0.5);
									fAngles[1] += (v * spread);
									GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
									GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
									ScaleVector(fwd, 100.0);
									AddVectors(fOrigin, fwd, fOrigin);
									float Speed[3];
									bool movementType = false;
									if(HasEntProp(entity, Prop_Data, "m_vecAbsVelocity"))
									{
										GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", Speed);
										if(debugMode)
											PrintToChatAll("Multishot | %.2f speed", GetVectorLength(Speed))
										fVelocity[0] = vBuffer[0]*GetVectorLength(Speed);
										fVelocity[1] = vBuffer[1]*GetVectorLength(Speed);
										fVelocity[2] = vBuffer[2]*GetVectorLength(Speed);
										if(GetVectorLength(Speed) > 5.0)
										{
											movementType = true;
										}
									}
									if(movementType == false)
									{
										float velocity = 2000.0;
										Address projspeed = TF2Attrib_GetByName(CWeapon, "Projectile speed increased");
										Address projspeed1 = TF2Attrib_GetByName(CWeapon, "Projectile speed decreased");
										if(projspeed != Address_Null){
											velocity *= TF2Attrib_GetValue(projspeed)
										}
										if(projspeed1 != Address_Null){
											velocity *= TF2Attrib_GetValue(projspeed1)
										}
										float vecAngImpulse[3];
										GetCleaverAngularImpulse(vecAngImpulse);
										fVelocity[0] = vBuffer[0]*velocity;
										fVelocity[1] = vBuffer[1]*velocity;
										fVelocity[2] = vBuffer[2]*velocity;
										
										//float vecUnknown2[3];
										//vecUnknown2[1] = GetRandomFloat(0.0, 100.0);
										TeleportEntity(iEntity, fOrigin, fAngles, NULL_VECTOR); // fuck it, i'll do it later
										DispatchSpawn(iEntity);
										SDKCall(g_SDKCallInitGrenade, iEntity, fVelocity, vecAngImpulse, owner, 0, 5.0);
										SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
										if(HasEntProp(iEntity, Prop_Send, "m_hLauncher"))
										{
											SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
										}
										SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", owner);
										if(debugMode)
											PrintToChatAll("Multishot | %.2f speed", GetVectorLength(fVelocity))
										//PrintToChat(owner, "you suck!");
									}
									//Damage Systems.....
									if(StrEqual(projName, "tf_projectile_rocket", false) || StrEqual(projName, "tf_projectile_pipe", false))
									{
										float ProjectileDamage = 90.0;
										
										Address DamagePenalty = TF2Attrib_GetByName(CWeapon, "damage penalty");
										Address DamageBonus = TF2Attrib_GetByName(CWeapon, "damage bonus");
										Address DamageBonusHidden = TF2Attrib_GetByName(CWeapon, "damage bonus HIDDEN");
										
										if(DamagePenalty != Address_Null)
										{
											float dmgmult2 = TF2Attrib_GetValue(DamagePenalty);
											ProjectileDamage *= dmgmult2;
										}
										if(DamageBonus != Address_Null)
										{
											float dmgmult3 = TF2Attrib_GetValue(DamageBonus);
											ProjectileDamage *= dmgmult3;
										}
										if(DamageBonusHidden != Address_Null)
										{
											float dmgmult4 = TF2Attrib_GetValue(DamageBonusHidden);
											ProjectileDamage *= dmgmult4;
										}
										if(StrEqual(projName, "tf_projectile_rocket", false))
										{
											SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, ProjectileDamage, true);
										}
										if(StrEqual(projName, "tf_projectile_pipe", false))
										{
											float radiusMult = 1.0;
											Address blastRadius1 = TF2Attrib_GetByName(CWeapon, "Blast radius increased");
											Address blastRadius2 = TF2Attrib_GetByName(CWeapon, "Blast radius decreased");
											if(blastRadius1 != Address_Null){
												radiusMult *= TF2Attrib_GetValue(blastRadius1)
											}
											if(blastRadius2 != Address_Null){
												radiusMult *= TF2Attrib_GetValue(blastRadius2)
											}
											SetEntPropFloat(iEntity, Prop_Send, "m_DmgRadius", 144.0 * radiusMult);
											SetEntPropFloat(iEntity, Prop_Send, "m_flDamage", ProjectileDamage);
										} 
									}
									if(movementType == true)
									{
										SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
										TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
										DispatchSpawn(iEntity);
									}
									if(StrEqual(projName, "tf_projectile_arrow", false) || StrEqual(projName, "tf_projectile_healing_bolt", false))
									{
										SDKHook(iEntity, SDKHook_Touch, OnCollisionArrow);
										SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchDelete);
										
										if(StrEqual(projName, "tf_projectile_healing_bolt", false))
										{
											SetEntityModel(iEntity, "models/weapons/w_models/w_syringe_proj.mdl");
											SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 3.0);
										}
										if(StrEqual(projName, "tf_projectile_arrow", false))
										{
											if(iTeam == 2)
											{
												CreateSpriteTrail(iEntity, "1.0", "5.0", "1.0", "materials/effects/arrowtrail_red.vmt", "255 255 255");
											}
											else
											{
												CreateSpriteTrail(iEntity, "1.0", "5.0", "1.0", "materials/effects/arrowtrail_blu.vmt", "255 255 255");
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
    }
}
PrecisionHoming(entity) 
{
	entity = EntRefToEntIndex(entity);
    if(IsValidEdict(entity)) 
    { 
		int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient3(client))
		{
			Address precisionPowerup = TF2Attrib_GetByName(client, "precision powerup");
			if(precisionPowerup != Address_Null && TF2Attrib_GetValue(precisionPowerup) > 0.0)
			{
				projectileHomingDegree[entity] = 200.0;
			}
		}
    } 
}
ProjSpeedDelay(entity) 
{
	entity = EntRefToEntIndex(entity);
    if(IsValidEdict(entity)) 
    { 
		int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient(client))
		{
			int ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(ClientWeapon))
			{
				Address projspeed = TF2Attrib_GetByName(ClientWeapon, "Projectile speed increased");
				if(projspeed != Address_Null)
				{
					float vAngles[3],vPosition[3],vBuffer[3],vVelocity[3],vel[3];
					GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPosition);
					GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
					GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
					GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					float projspd = TF2Attrib_GetValue(projspeed);
					vVelocity[0] = vBuffer[0]*projspd*GetVectorLength(vel);
					vVelocity[1] = vBuffer[1]*projspd*GetVectorLength(vel);
					vVelocity[2] = vBuffer[2]*projspd*GetVectorLength(vel);
					TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
				}
			}
		}
    } 
}
projGravity(entity) 
{
	entity = EntRefToEntIndex(entity);
    if(IsValidEdict(entity)) 
    { 
	//PrintToChatAll("START | movetype = %i | gravity = %.2f", GetEntityMoveType(entity), GetEntityGravity(entity));
		//PrintToChatAll("0");
		int client;
		if(HasEntProp(entity, Prop_Data, "m_hThrower"))
		{
			client = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		}
		else if(HasEntProp(entity, Prop_Data, "m_hOwnerEntity"))
		{
			client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		}
		if(IsValidClient3(client))
		{
			//PrintToChatAll("1");
			int ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(ClientWeapon))
			{
				//PrintToChatAll("2");
				Address projgravity = TF2Attrib_GetByName(ClientWeapon, "cloak_consume_on_feign_death_activate");

				char strClassname[64];
				GetEntityClassname( entity, strClassname, sizeof(strClassname) );

				if(projgravity != Address_Null && TF2Attrib_GetValue(projgravity) != 0.0)
				{
					//PrintToChatAll("3");
					if(GetEntityMoveType(entity) != MOVETYPE_VPHYSICS)
					{
						SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
						SetEntityGravity(entity, TF2Attrib_GetValue(projgravity));
						RequestFrame(PrecisionHoming, EntIndexToEntRef(entity));
					}
					else
					{
						if(StrEqual(strClassname, "tf_projectile_pipe") || StrEqual(strClassname, "tf_projectile_pipe_remote"))
						{
							float flAng[3],fVelocity[3],vBuffer[3];
							float velocity = 3000.0;

							Address projspeed = TF2Attrib_GetByName(ClientWeapon, "Projectile speed increased");
							if(projspeed != Address_Null)
								velocity *= TF2Attrib_GetValue(projspeed);

							GetEntPropVector(entity, Prop_Data, "m_angRotation", flAng);
							GetAngleVectors(flAng, vBuffer, NULL_VECTOR, NULL_VECTOR);
							
							fVelocity[0] = vBuffer[0]*velocity;
							fVelocity[1] = vBuffer[1]*velocity;
							fVelocity[2] = vBuffer[2]*velocity;
							//SetEntPropVector(entity, Prop_Data, "m_vecVelocity", fVelocity);
							//TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, fVelocity);
							//SDKCall(g_SDKCallInitGrenade, entity, fVelocity, vecAngImpulse, client, 0, 5.0);
							Phys_SetVelocity(entity, fVelocity, NULL_VECTOR);
							SetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", fVelocity);
							//SetEntPropVector(entity, Prop_Data, "m_angRotation", flAng);
						}
						else if(StrEqual(strClassname, "tf_projectile_cleaver"))
						{
							float flAng[3],fVelocity[3],vBuffer[3];
							float vecAngImpulse[3];
							GetCleaverAngularImpulse(vecAngImpulse);
							float velocity = 3000.0;

							Address projspeed = TF2Attrib_GetByName(ClientWeapon, "Projectile speed increased");
							if(projspeed != Address_Null)
								velocity *= TF2Attrib_GetValue(projspeed);

							GetEntPropVector(entity, Prop_Data, "m_angRotation", flAng);
							flAng[0] -= 10.0;
							GetAngleVectors(flAng, vBuffer, NULL_VECTOR, NULL_VECTOR);
							fVelocity[0] = vBuffer[0]*velocity;
							fVelocity[1] = vBuffer[1]*velocity;
							fVelocity[2] = vBuffer[2]*velocity;
							SDKCall(g_SDKCallInitGrenade, entity, fVelocity, vecAngImpulse, client, 0, 5.0);
							SetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", fVelocity);
						}
						Phys_EnableGravity(entity, false);
						//Phys_EnableCollisions(entity, false);
					}
					//PrintToChatAll("END | movetype = %i | gravity = %.2f", GetEntityMoveType(entity), GetEntityGravity(entity));
				}
			}
		}
    } 
}
setProjGravity(entity, float gravity) 
{
    if(IsValidEntity(entity)) 
    {
		SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
		SetEntityGravity(entity, gravity);
    } 
}
instantProjectile(entity) 
{
    if(IsValidEdict(entity)) 
    { 
		int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient(client))
		{
			int ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(ClientWeapon))
			{
				Address projspeed = TF2Attrib_GetByName(ClientWeapon, "Projectile speed increased");
				if(projspeed != Address_Null && TF2Attrib_GetValue(projspeed) >= 100.0)
				{
					float vAngles[3],vPosition[3],vBuffer[3],vVelocity[3],vel[3];
					GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPosition);
					GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
					GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
					GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					float projspd = 500.0;
					vVelocity[0] = vBuffer[0]*projspd*GetVectorLength(vel);
					vVelocity[1] = vBuffer[1]*projspd*GetVectorLength(vel);
					vVelocity[2] = vBuffer[2]*projspd*GetVectorLength(vel);
					TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
				}
			}
		}
    } 
}
stock void ResizeHitbox(int entity, float fScale)
{
	float vecBossMin[3], vecBossMax[3];
	GetEntPropVector(entity, Prop_Send, "m_vecMins", vecBossMin);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecBossMax);
	
	float vecScaledBossMin[3], vecScaledBossMax[3];
	
	vecScaledBossMin = vecBossMin;
	vecScaledBossMax = vecBossMax;
	
	ScaleVector(vecScaledBossMin, fScale);
	ScaleVector(vecScaledBossMax, fScale);
	
	SetEntPropVector(entity, Prop_Send, "m_vecMins", vecScaledBossMin);
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecScaledBossMax);
}
stock ResizeProjectile(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEntity(entity))
	{
		int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient3(client))
		{
			int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(CWeapon))
			{
				Address sizeActive = TF2Attrib_GetByName(CWeapon, "SET BONUS: no death from headshots")
				if(sizeActive != Address_Null)
				{				
					ResizeHitbox(entity, TF2Attrib_GetValue(sizeActive));
				}
			}
		}
	}
}
stock SentryMultishot(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEntity(entity))
	{
		int inflictor = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		int client;
		if(!IsValidClient3(inflictor) && IsValidEntity(inflictor) && HasEntProp(inflictor,Prop_Send,"m_hBuilder"))
		{
			client = GetEntPropEnt(inflictor, Prop_Send, "m_hBuilder");
			if(IsValidClient3(client))
			{
				int melee = (GetPlayerWeaponSlot(client,2));
				if(IsValidEntity(melee))
				{
					Address doubleShotActive = TF2Attrib_GetByName(melee, "dmg penalty vs nonstunned");		
					if(doubleShotActive != Address_Null && TF2Attrib_GetValue(doubleShotActive) > 0.0)
					{
						Handle hPack = CreateDataPack();
						WritePackCell(hPack, EntIndexToEntRef(inflictor));
						WritePackCell(hPack, EntIndexToEntRef(client));
						WritePackCell(hPack, RoundToCeil(TF2Attrib_GetValue(doubleShotActive)));
						CreateTimer(0.1,ShootTwice,hPack);
					}
				}
			}
		}
	}
}

stock fixPiercingVelocity(entity)
{
	entity = EntRefToEntIndex(entity)
	if(IsValidEntity(entity))
	{
		float origin[3],ProjAngle[3],vBuffer[3],fVelocity[3],speed = 3000.0;
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
		GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR);
		if(HasEntProp(entity, Prop_Send, "m_vInitialVelocity"))
		{
			GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", fVelocity);
			speed = GetVectorLength(fVelocity);
		}
		fVelocity[0] = vBuffer[0]*speed;
		fVelocity[1] = vBuffer[1]*speed;
		fVelocity[2] = vBuffer[2]*speed;
		TeleportEntity(entity, origin,NULL_VECTOR,fVelocity);
	}
}
stock void ZeroVector(float vec[3])
{
    vec[0] = vec[1] = vec[2] = 0.0;
}
//Menu Functions
public Menu_BuyNewWeapon(client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		CreateBuyNewWeaponMenu(client);
	}
}
stock bool TraceEntityFilterPlayers(int entity, int contentsMask) {
    return entity > MaxClients;
} 
