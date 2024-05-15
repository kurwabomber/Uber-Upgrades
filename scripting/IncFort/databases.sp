SavePlayerData(client)
{
	if (!IsValidClient(client))
		return;

	char queryString[2048];
	char steamid[64];
	
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	
	DataPack pack = CreateDataPack();
	pack.Reset();
	if(!IsMvM())
	{
		for(int s = 0; s < NB_SLOTS_UED; s++)
		{
			for(int i = 0; i < MAX_ATTRIBUTES_ITEM; ++i)
			{
				pack.WriteCell(currentupgrades_idx[client][s][i]);
				pack.WriteFloat(currentupgrades_val[client][s][i]);
				pack.WriteFloat(currentupgrades_i[client][s][i]);
				pack.WriteCell(upgrades_ref_to_idx[client][s][currentupgrades_idx[client][s][i]]);
			}
			pack.WriteCell(currentupgrades_number[client][s]);
			pack.WriteFloat(client_spent_money[client][s]);
			pack.WriteFloat(client_tweak_highest_requirement[client][s]);
			pack.WriteCell(currentitem_idx[client][s]);
			pack.WriteCell(currentitem_level[client][s]);
			pack.WriteString(currentitem_classname[client][s]);
			
			for(int y = 0; y<5; y++)
			{
				pack.WriteCell(currentupgrades_restriction[client][s][y]);
			}
		}
	}
	else
	{
		for(int s = 0; s < NB_SLOTS_UED; s++)
		{
			for(int i = 0; i < MAX_ATTRIBUTES_ITEM; ++i)
			{
				pack.WriteCell(currentupgrades_idx_mvm_chkp[client][s][i]);
				pack.WriteFloat(currentupgrades_val_mvm_chkp[client][s][i]);
				pack.WriteFloat(currentupgrades_i[client][s][i]);
				pack.WriteCell(upgrades_ref_to_idx_mvm_chkp[client][s][currentupgrades_idx_mvm_chkp[client][s][i]]);
			}
			pack.WriteCell(currentupgrades_number_mvm_chkp[client][s]);
			pack.WriteFloat(client_spent_money_mvm_chkp[client][s]);
			pack.WriteFloat(client_tweak_highest_requirement[client][s]);
			pack.WriteCell(currentitem_idx[client][s]);
			pack.WriteCell(currentitem_level[client][s]);
			pack.WriteString(currentitem_classname[client][s]);
			for(int y = 0; y<5; y++)
			{
				pack.WriteCell(currentupgrades_restriction_mvm_chkp[client][s][y]);
			}
		}
	}

	pack.WriteCell(current_class[client]);
	if(IsMvM())
		pack.WriteCell(client_new_weapon_ent_id_mvm_chkp[client]);
	else
		pack.WriteCell(client_new_weapon_ent_id[client]);

	pack.WriteCell(upgrades_weapon_current[client]);
	Format(queryString, sizeof(queryString), "REPLACE INTO PlayerList (steamid, datapack) VALUES ('%s', '%i')", steamid, pack);
	Handle queryH = SQL_Query(DB, queryString);
	if(queryH)
		PrintToServer("IF : Successfully saved player upgrades.");
	else{
		SQL_GetError(DB, Error, sizeof(Error));
		PrintToServer("IF : Was unable to save player upgrades | SQLERROR : %s.", Error);
	}
	
	ResetClientUpgrades(client);
}

GivePlayerData(client)
{
	if(!IsValidClient(client))
		return;
	char steamid[64], queryDelete[256], queryString[2048];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid))

	Format(queryString, sizeof(queryString), "SELECT steamid, datapack FROM PlayerList WHERE steamid='%s'", steamid);
	Format(queryDelete, sizeof(queryDelete), "DELETE FROM PlayerList WHERE steamid='%s'", steamid);
	Handle queryH = SQL_Query(DB, queryString);

	if(!queryH){
		SQL_GetError(DB,Error,sizeof(Error));
		PrintToServer("IF : Was unable to give player upgrades | SQLERROR : %s.", Error);
		CurrencyOwned[client] = (StartMoney + additionalstartmoney);
		return;
	}
	if(!SQL_FetchRow(queryH))
	{
		CurrencyOwned[client] = (StartMoney + additionalstartmoney);
		return;
	}
	float CurrencyFormulated = (StartMoney + additionalstartmoney);
	DataPack pack = view_as<DataPack>(SQL_FetchInt(queryH, 1));
	if(IsValidHandle(pack))
	{
		pack.Reset();
		PrintToServer("IF : Successfully gave player upgrades to %N.", client);
		float spentMoney = 0.0;
		for(int s = 0; s < NB_SLOTS_UED; s++)
		{
			for(int i = 0; i < MAX_ATTRIBUTES_ITEM; ++i)
			{
				currentupgrades_idx[client][s][i] = pack.ReadCell();
				currentupgrades_val[client][s][i] = pack.ReadFloat();
				currentupgrades_i[client][s][i] = pack.ReadFloat();
				currentupgrades_idx_mvm_chkp[client][s][i] = currentupgrades_idx[client][s][i];
				currentupgrades_val_mvm_chkp[client][s][i] = currentupgrades_val[client][s][i];
				upgrades_ref_to_idx[client][s][currentupgrades_idx[client][s][i]] = pack.ReadCell();
				upgrades_ref_to_idx_mvm_chkp[client][s][currentupgrades_idx_mvm_chkp[client][s][i]] = upgrades_ref_to_idx[client][s][currentupgrades_idx[client][s][i]]
			}
			currentupgrades_number[client][s] = pack.ReadCell();
			client_spent_money[client][s] = pack.ReadFloat();
			client_tweak_highest_requirement[client][s] = pack.ReadFloat();
			currentitem_idx[client][s] = pack.ReadCell();
			currentitem_level[client][s] = pack.ReadCell();
			pack.ReadString(currentitem_classname[client][s], 128);
			
			for(int y = 0; y<5; y++)
			{
				currentupgrades_restriction[client][s][y] = pack.ReadCell();
				currentupgrades_restriction_mvm_chkp[client][s][y] = currentupgrades_restriction[client][s][y];
			}
			
			client_spent_money_mvm_chkp[client][s] = client_spent_money[client][s];
			spentMoney += client_spent_money[client][s];
			currentupgrades_number_mvm_chkp[client][s] = currentupgrades_number[client][s];
			
			CurrencyFormulated -= client_spent_money[client][s];
		}
		current_class[client] = pack.ReadCell();
		client_new_weapon_ent_id[client] = pack.ReadCell();
		client_new_weapon_ent_id_mvm_chkp[client] = client_new_weapon_ent_id[client]
		upgrades_weapon_current[client] = pack.ReadCell();
		previous_class[client] = current_class[client];
		CurrencyOwned[client] = CurrencyFormulated;
		
		
		if(CurrencyOwned[client] + spentMoney < (StartMoney + additionalstartmoney) * 0.6)
		{
			PrintToServer("Something went horribly wrong when handling %N's startmoney. %.0f was spent, %.0f is owned.", client, spentMoney, CurrencyOwned[client])
			CurrencyOwned[client] = StartMoney + additionalstartmoney;
		}
		
		CloseHandle(pack);
	}
	else
	{
		PrintToServer("IF : Was unable to load previous state for %N due to invalid pack handle.", client);
		CurrencyOwned[client] = (StartMoney + additionalstartmoney);
	}
	
	queryH = SQL_Query(DB, queryDelete);
	if(!queryH){
		SQL_GetError(DB,Error,sizeof(Error));
		PrintToServer("IF : Was unable to clear database IDs. | SQLERROR : %s.", Error);
	}
}
DeleteSavedPlayerData()
{
	char queryString[2048];
	Format(queryString, sizeof(queryString), "DELETE FROM PlayerList");
	Handle queryH = SQL_Query(DB, queryString);
	if(queryH)
	{
		PrintToServer("IF : Deleted all saved data.");
	}else{
		SQL_GetError(DB, Error, sizeof(Error));
		PrintToServer("IF : Couldn't delete data. | SQLERROR : %s.", Error);
	}
}
DeleteDatabase()
{
	char queryString[2048];
	Format(queryString, sizeof(queryString), "DROP TABLE PlayerList");
	Handle queryH = SQL_Query(DB, queryString);
	if(queryH)
	{
		PrintToServer("IF : Deleted database.");
	}else{
		SQL_GetError(DB, Error, sizeof(Error));
		PrintToServer("IF : Couldn't delete database. | SQLERROR : %s.", Error);
	}
}