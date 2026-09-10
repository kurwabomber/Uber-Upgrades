public Action TF2_OnTakeHealthGetMultiplier(int client, float &flMultiplier){
	float amt = GetPlayerHealingMultiplier(client);
	if(amt != 1.0){
		flMultiplier = amt;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

float GetPlayerHealingMultiplier(client){
	float debuffMagnitude = 1.0;
	float buffMagnitude = 0.0;
	float playerOrigin[3];

	GetClientAbsOrigin(client, playerOrigin);

	if(TF2_IsPlayerInCondition(client, TFCond_Bleeding)){
		if(TF2Attrib_HookValueFloat(0.0, "inverter_powerup", client) == 1.0){
			buffMagnitude += 1.0;
		}
		else{
			int inflictor = TF2Util_GetPlayerConditionProvider(client, TFCond_Bleeding);
			if(IsValidClient3(inflictor)){
				if(TF2Attrib_HookValueFloat(0.0, "knockout_powerup", client) == 2)
					debuffMagnitude /= 1+5*TF2Attrib_HookValueFloat(1.0, "debuff_magnitude_mult", inflictor);
				else
					debuffMagnitude /= 1+1*TF2Attrib_HookValueFloat(1.0, "debuff_magnitude_mult", inflictor);
			}
			else{
				debuffMagnitude *= 0.5;
			}
		}
	}
	if(TF2_IsPlayerInCondition(client, TFCond_MegaHeal)){
		float effectMult = 1.0;
		
		int healers = GetEntProp(client, Prop_Send, "m_nNumHealers");
		for(int i = 0;i<healers;++i){
			int healer = TF2Util_GetPlayerHealer(client,i);
			if(!IsValidClient3(healer))
				continue;

			int healingWeapon = GetEntPropEnt(healer, Prop_Send, "m_hActiveWeapon");
			if(!IsValidWeapon(healingWeapon))
				continue;

			effectMult += GetAttribute(healingWeapon, "ubercharge effectiveness", 1.0)-1.0;
		}
		int inflictor = TF2Util_GetPlayerConditionProvider(client, TFCond_MegaHeal);
		if(IsValidClient3(inflictor)) {
			effectMult += TF2Attrib_HookValueFloat(1.0, "buff_magnitude_mult", inflictor)-1.0;
		}
		buffMagnitude += effectMult;
	}

	int healers = GetEntProp(client, Prop_Send, "m_nNumHealers");
	for(int i = 0;i<healers;++i){
		int healer = TF2Util_GetPlayerHealer(client,i);
		if(!IsValidClient3(healer))
			continue;

		int healingWeapon = GetEntPropEnt(healer, Prop_Send, "m_hActiveWeapon");
		if(!IsValidWeapon(healingWeapon))
			continue;

		if(TF2Util_GetEntityMaxHealth(client) > GetClientHealth(client)){
			float bonusPerHealthMissing = (TF2Attrib_HookValueFloat(1.0, "low_health_heal_mult", healingWeapon)-1)/TF2Util_GetEntityMaxHealth(client);
			buffMagnitude += bonusPerHealthMissing * (TF2Util_GetEntityMaxHealth(client) - GetClientHealth(client));
		}
	}
	
	if(TF2Attrib_HookValueFloat(0.0, "regeneration_powerup", client) == 3.0){
		buffMagnitude += 0.6;
	}
	if(TF2Attrib_HookValueFloat(0.0, "vampire_powerup", client) == 2.0){
		buffMagnitude += 0.25;
	}
	if(TF2Attrib_HookValueFloat(0.0, "juggernaut_powerup", client) == 2.0){
		buffMagnitude += 1.0;
	}
	
	if(hasBuffIndex(client, Buff_HealingBuff)){
		buffMagnitude += playerBuffs[client][getBuffInArray(client, Buff_HealingBuff)].severity - 1.0;
	}
	if(hasBuffIndex(client, Buff_Stronghold)){
		buffMagnitude += 0.33 * playerBuffs[client][getBuffInArray(client, Buff_Stronghold)].severity;
	}
	if(hasBuffIndex(client, Buff_Leech)){
		debuffMagnitude /= 1 + playerBuffs[client][getBuffInArray(client, Buff_Leech)].severity;
	}
	if(hasBuffIndex(client, Buff_Decay)){
		debuffMagnitude /= 1 + 3.0*playerBuffs[client][getBuffInArray(client, Buff_Decay)].severity;
	}
	for(int i = 0; i<MAXBUFFS;i++){
		if(playerBuffs[client][i].duration < GetGameTime())
			continue;
			
		buffMagnitude += playerBuffs[client][i].additiveIncomingHeal * playerBuffs[client][i].severity;
	}
	if(TF2Attrib_HookValueFloat(0.0, "revenge_powerup", client) == 2.0 || TF2Attrib_HookValueFloat(0.0, "revenge_powerup", client) == 3.0)
		buffMagnitude += RageBuildup[client]*0.5;
	
	float healingBoostPerSecond = TF2Attrib_HookValueFloat(0.0, "incoming_healing_boost_over_time", client);
	if(healingBoostPerSecond > 0.0){
		float healingBoostPerSecondCap = TF2Attrib_HookValueFloat(0.0, "incoming_healing_boost_over_time_cap", client);
		float totalBonus = healingBoostPerSecond * (GetGameTime()-lastDamageTime[client]);
		if(totalBonus > healingBoostPerSecondCap){
			totalBonus = healingBoostPerSecondCap;
		}
		buffMagnitude += totalBonus;
	}

	return debuffMagnitude * (1+buffMagnitude);
}
void AddPlayerHealth(client, iAdd, float flOverheal = 1.5, bool bEvent = false, healer = -1)
{
	if(!bEvent && hasBuffIndex(client, Buff_Leech)){
		Buff leechInfo; leechInfo = playerBuffs[client][getBuffInArray(client, Buff_Leech)];
		//You cant leech off yourself! dumb idiot infinite loop
		if(client != leechInfo.inflictor){
			AddPlayerHealth(leechInfo.inflictor, RoundToCeil(iAdd*0.5));
		}
	}
	if(flOverheal > 1)
		flOverheal += TF2Attrib_HookValueFloat(1.0, "mult_patient_overheal_penalty", client)-1.0;
		
	iAdd = RoundToCeil(iAdd * GetPlayerHealingMultiplier(client));
    int iHealth = GetClientHealth(client);
    int iNewHealth = iHealth + iAdd;
    int iMax = RoundFloat(float(TF2_GetMaxHealth(client)) * flOverheal)
	if(iNewHealth > iMax && iHealth < iMax)
	{
		iNewHealth = iMax;
	}
    if (iNewHealth <= iMax && iHealth != iMax)
    {
        if (bEvent)
        {
            ShowHealthGain(client, iNewHealth-iHealth, healer);
        }
        SetEntityHealth(client, iNewHealth);
    }
}
void AddBuildingHealth(building, heal, healer = -1){
	int missingHealth = TF2Util_GetEntityMaxHealth(building) - GetEntProp(building, Prop_Send, "m_iHealth");
	if(missingHealth == 0)
		return;

	if(heal > missingHealth){
		heal = missingHealth;
	}

	if(IsValidClient3(healer)){
		Handle hEvent = CreateEvent("building_healed", true);
		SetEventInt(hEvent, "building", building);
		SetEventInt(hEvent, "healer", healer);
		SetEventInt(hEvent, "amount", heal);
		FireEvent(hEvent);
	}
	AddEntHealth(building, heal);
}