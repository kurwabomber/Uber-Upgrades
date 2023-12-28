//Added since 12/27/23
public Action TF2_OnTakeHealthGetMultiplier(int client, float &flMultiplier){
	float amt = GetPlayerHealingMultiplier(client);
	if(amt != 1.0){
		flMultiplier = amt;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

//Maybe some day I want additive healing or smth...
/*
public Action TF2_OnTakeHealthPre(int client, float &flAmount, int &flags){
	return Plugin_Continue;
}
*/