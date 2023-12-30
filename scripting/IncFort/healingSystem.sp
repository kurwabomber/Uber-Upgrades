//Added since 12/27/23
public Action TF2_OnTakeHealthGetMultiplier(int client, float &flMultiplier){
	float amt = GetPlayerHealingMultiplier(client);
	if(amt != 1.0){
		flMultiplier = amt;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
public Action TF2_OnTakeHealthPre(int client, float &flAmount, int &flags){
	if(hasBuffIndex(client, Buff_Leech)){
		AddPlayerHealth(client, RoundToCeil(flAmount*0.334));
	}
	return Plugin_Continue;
}

float GetPlayerHealingMultiplier(client){
	float multiplier = 1.0;
	float playerOrigin[3];

	GetClientAbsOrigin(client, playerOrigin);

	if(TF2_IsPlayerInCondition(client, TFCond_Bleeding)){
		if(GetAttribute(client, "inverter powerup", 0.0) == 1.0){
			multiplier *= 2.0;
		}
		else
			multiplier *= 0.5;
	}
	if(GetAttribute(client, "regeneration powerup", 0.0) == 3.0)
		multiplier *= 1.6;
	if(hasBuffIndex(client, Buff_Stronghold))
		multiplier *= 1.33;
	if(hasBuffIndex(client, Buff_Leech))
		multiplier *= 0.667;

	return multiplier;
}
void AddPlayerHealth(client, iAdd, float flOverheal = 1.5, bool bEvent = false, healer = -1)
{
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

	if(hasBuffIndex(client, Buff_Leech)){
		AddPlayerHealth(client, RoundToCeil(iAdd*0.5));
	}
}