void removeRecoup(int client){
	RecoupStack empty;
	for(int i = 0;i < MAX_RECOUP_STACKS; i++){
		playerRecoup[client][i] = empty;
	}
}
void insertRecoup(int client, RecoupStack newStack){
	int replacementID = getNextRecoupStack(client);
	playerRecoup[client][replacementID] = newStack;
}
int getNextRecoupStack(int client){
	for(int i = 0; i < MAX_RECOUP_STACKS; ++i){
		if(playerRecoup[client][i].expireTime < GetGameTime()){
			return i;
		}
	}
	return 0;
}

void insertAfterburn(int client, AfterburnStack newStack){
	int replacementID = getNextAfterburnStack(client);
	playerAfterburn[client][replacementID] = newStack;
}
int getNextAfterburnStack(int client){
	int lowest = 99999999;
	int id = 0;
	for(int i = 0; i < MAX_AFTERBURN_STACKS; ++i){
		if(playerAfterburn[client][i].remainingTicks < lowest){
			lowest = playerAfterburn[client][i].remainingTicks;
			id = i;
		}
	}
	return id;
}
void removeAfterburn(int client){
	AfterburnStack empty;
	for(int i = 0;i < MAX_AFTERBURN_STACKS; i++){
		playerAfterburn[client][i] = empty;
	}
}


float GetResistance(int client, bool includeReduction = false, float penetration = 0.0)
{
	float TotalResistance = TF2Attrib_HookValueFloat(0.0, "quadratic_damage_reduction", client);
	if(hasBuffIndex(client, Buff_BrokenArmor)){
		TotalResistance -= playerBuffs[client][getBuffInArray(client,Buff_BrokenArmor)].priority;
	}
	if(penetration > 0.0){
		TotalResistance -= penetration;
	}
	
	TotalResistance = TotalResistance*TotalResistance*TotalResistance;

	if(TotalResistance < 1){
		TotalResistance = 1.0;
	}
	else{
		TotalResistance += 1.0;
	}

	if(includeReduction)
	{
		Address dmgReduction = TF2Attrib_GetByName(client, "sniper zoom penalty");
		if(dmgReduction != Address_Null)
		{
			TotalResistance /= TF2Attrib_GetValue(dmgReduction);
		}
		for(int i=0;i<=NB_SLOTS_UED;++i){
			int id = TF2Util_GetPlayerLoadoutEntity(client, i);
			if(!IsValidWeapon(id))
				continue;
			
			if(GetAttribute(id, "provide on active", 0.0))
				if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") != id)
					continue;

			dmgReduction = TF2Attrib_GetByName(id, "dmg taken increased");
			if(dmgReduction != Address_Null)
				TotalResistance /= TF2Attrib_GetValue(dmgReduction);
		}
		TotalResistance /= TF2Attrib_HookValueFloat(1.0, "dmg_incoming_mult", client);
		TotalResistance *= TF2Attrib_HookValueFloat(1.0, "dmg_taken_divided", client);

		int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(IsValidWeapon(CWeapon)){
			TotalResistance /= TF2Attrib_HookValueFloat(1.0, "damage_taken_multiplier_when_active", CWeapon);
		}

		Address DodgeBody = TF2Attrib_GetByName(client, "SET BONUS: chance of hunger decrease");
		if(DodgeBody != Address_Null)
			TotalResistance /= 1-TF2Attrib_GetValue(DodgeBody);

		float resPowerup = TF2Attrib_HookValueFloat(0.0, "resistance_powerup", client);
		if(resPowerup == 1 || resPowerup == 3)
			TotalResistance *= 2.0;
		
		if(TF2Attrib_HookValueFloat(0.0, "revenge_powerup", client) == 1 || TF2Attrib_HookValueFloat(0.0, "knockout_powerup", client) == 1 || TF2Attrib_HookValueFloat(0.0, "king_powerup", client) == 1 || TF2Attrib_HookValueFloat(0.0, "supernova_powerup", client) == 1 || TF2Attrib_HookValueFloat(0.0, "inverter_powerup", client) == 1)
			TotalResistance *= 1.25;
		
		if(TF2Attrib_HookValueFloat(0.0, "regeneration_powerup", client) == 1 || TF2Attrib_HookValueFloat(0.0, "vampire_powerup", client) == 1 || TF2Attrib_HookValueFloat(0.0, "vampire_powerup", client) == 3 || 1 <= TF2Attrib_HookValueFloat(0.0, "plague_powerup", client) <= 2)
			TotalResistance *= 1.333;
		
		if(TF2Attrib_HookValueFloat(0.0, "knockout_powerup", client) == 2 || TF2Attrib_HookValueFloat(0.0, "inverter_powerup", client) == 2
		|| TF2Attrib_HookValueFloat(0.0, "king_powerup", client) == 3)
			TotalResistance *= 1.5;
	}

	return TotalResistance;
}
stock void DOTStock(int victim,int attacker,float damage,int weapon = -1,int damagetype = 0,int repeats = 1,float initialDelay = 0.0,float tickspeed = 1.0, bool stackable = false)
{
	if(IsValidForDamage(victim) && IsValidClient3(attacker))
	{
		if(DOTStacked[victim][attacker] == false || stackable == true)
		{
			Handle hPack = CreateDataPack();
			WritePackCell(hPack, EntIndexToEntRef(victim));
			WritePackCell(hPack, EntIndexToEntRef(attacker));
			WritePackFloat(hPack, damage);
			if(IsValidEdict(weapon))
			{
				WritePackCell(hPack, EntIndexToEntRef(weapon));
			}
			else
			{
				WritePackCell(hPack, weapon);
			}
			WritePackCell(hPack, damagetype);
			WritePackCell(hPack, repeats);
			WritePackCell(hPack, stackable);
			WritePackFloat(hPack, tickspeed);
			CreateTimer(initialDelay,DOTDamage,hPack);
			if(!stackable)
			{
				DOTStacked[victim][attacker] = true;
			}
		}
	}
}
stock Action DOTDamage(Handle timer,any:data)
{
	ResetPack(data);
	int victim = EntRefToEntIndex(ReadPackCell(data));
	int attacker = EntRefToEntIndex(ReadPackCell(data));
	float damage = ReadPackFloat(data);
	int weapon = EntRefToEntIndex(ReadPackCell(data));
	int damagetype = ReadPackCell(data);
	int repeats = ReadPackCell(data);
	bool stackable = view_as<bool>(ReadPackCell(data));
	float tickspeed = ReadPackFloat(data);
	if(repeats >= 1)
	{
		if(IsValidForDamage(victim) && IsValidClient3(attacker))
		{
			SDKHooks_TakeDamage(victim,attacker,attacker,damage,damagetype|DMG_IGNOREHOOK,weapon,NULL_VECTOR,NULL_VECTOR,false);
			repeats--;
			Handle hPack = CreateDataPack();
			WritePackCell(hPack, EntIndexToEntRef(victim));
			WritePackCell(hPack, EntIndexToEntRef(attacker));
			WritePackFloat(hPack, damage);
			if(IsValidEdict(weapon))
			{
				WritePackCell(hPack, EntIndexToEntRef(weapon));
			}
			else
			{
				WritePackCell(hPack, weapon);
			}
			WritePackCell(hPack, damagetype);
			WritePackCell(hPack, repeats);
			WritePackCell(hPack, stackable);
			WritePackFloat(hPack, tickspeed);
			CreateTimer(tickspeed,DOTDamage,hPack);
		}
	}
	else if(!stackable)
	{
		DOTStacked[victim][attacker] = false;
	}
	CloseHandle(data);
	return Plugin_Continue;
}

stock int CreateParticle(iEntity, char[] strParticle, bool bAttach = false, char[] strAttachmentPoint="", float time = 2.0,float fOffset[3]={0.0, 0.0, 0.0}, bool parentAngle = false, attachType = 0)
{
	if(attachType == 0)
	{
		int iParticle = CreateEntityByName("info_particle_system");
		if (IsValidEdict(iParticle))
		{
			float fPosition[3], fAngles[3];
			
			if(IsValidEdict(iEntity))
			{
				GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPosition);
			}
			if(parentAngle == true)
			{
				GetEntPropVector(iEntity, Prop_Data, "m_angRotation", fAngles); 
				TeleportEntity(iParticle, NULL_VECTOR, fAngles, NULL_VECTOR);
			}
			fPosition[0] += fOffset[0];
			fPosition[1] += fOffset[1];
			fPosition[2] += fOffset[2];
			
			TeleportEntity(iParticle, fPosition, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(iParticle, "effect_name", strParticle);
			
			if (bAttach == true)
			{
				SetVariantString("!activator");
				AcceptEntityInput(iParticle, "SetParent", iEntity, iParticle, 0);            
				
				if (strAttachmentPoint[0] != '\0')
				{
					SetVariantString(strAttachmentPoint);
					AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iEntity, iParticle, 0);                
				}
			}
			// Spawn and start
			DispatchSpawn(iParticle);
			ActivateEntity(iParticle);
			AcceptEntityInput(iParticle, "Start");
			
			if(time > 0.0){
				CreateTimer(time, Timer_KillParticle, EntIndexToEntRef(iParticle));
			}
		}
		return iParticle
	}
	else if (attachType == 1)
	{
		static int table = INVALID_STRING_TABLE;
		if (table == INVALID_STRING_TABLE)
			table = FindStringTable("ParticleEffectNames");
			
		TE_Start("TFParticleEffect");
		TE_WriteNum("entindex", iEntity);
		TE_WriteNum("m_iParticleSystemIndex", FindStringIndex(table, strParticle));
		TE_WriteNum("m_iAttachType", 1); // Create at absorigin, and update to follow the entity
		
		if(time > 0.0){
			CreateTimer(time, Timer_KillTEParticle, EntIndexToEntRef(iEntity))
		}
	}
	return true
}
void CreateParticleEx(iEntity, char[] strParticle, m_iAttachType = 0, m_iAttachmentPointIndex = 0, float fOffset[3]={0.0,0.0,0.0}, float time = 0.0)
{
	static int table = INVALID_STRING_TABLE;
	if (table == INVALID_STRING_TABLE){
		table = FindStringTable("ParticleEffectNames");
		PrintToServer("Particle Table Found | index = %i", table);
	}

	TE_Start("TFParticleEffect");
	TE_WriteNum("m_iParticleSystemIndex", FindStringIndex(table, strParticle));
	if(m_iAttachType != -1){
		TE_WriteNum("m_iAttachType", m_iAttachType);

		if(m_iAttachmentPointIndex != -1)
			TE_WriteNum("m_iAttachmentPointIndex", m_iAttachmentPointIndex);
	}else{
		TE_WriteNum("m_iAttachType", 2);
	}
	if(iEntity != -1 && IsValidEntity(iEntity)){
		TE_WriteNum("entindex", iEntity);
		if(time > 0.0){
			CreateTimer(time, Timer_KillTEParticle, EntIndexToEntRef(iEntity))
		}
		if(m_iAttachType < 1 && !GetVectorLength(fOffset)){
			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fOffset);
		}
	}
	TE_WriteFloat("m_vecOrigin[0]", fOffset[0]);
	TE_WriteFloat("m_vecOrigin[1]", fOffset[1]);
	TE_WriteFloat("m_vecOrigin[2]", fOffset[2]);
	
	TE_SendToAll();
}
void SpawnBulletTracer(float startPos[3], float endPos[3], char[] tracerName)
{
    static int effectTable = INVALID_STRING_TABLE;
    static int particleTable = INVALID_STRING_TABLE;

    if (effectTable == INVALID_STRING_TABLE)
        effectTable = FindStringTable("EffectDispatch");

    if (particleTable == INVALID_STRING_TABLE)
        particleTable = FindStringTable("ParticleEffectNames");

    int effectIndex = FindStringIndex(effectTable, "ParticleTracer");
    if (effectIndex == INVALID_STRING_INDEX)
    {
        bool save = LockStringTables(false);
		AddToStringTable(effectTable, "ParticleTracer");
        LockStringTables(save);
    }

    int particleIndex = FindStringIndex(particleTable, tracerName);

    TE_Start("EffectDispatch");
    TE_WriteFloat("m_vStart[0]", startPos[0]);
    TE_WriteFloat("m_vStart[1]", startPos[1]);
    TE_WriteFloat("m_vStart[2]", startPos[2]);
    TE_WriteFloat("m_vOrigin[0]", endPos[0]);
    TE_WriteFloat("m_vOrigin[1]", endPos[1]);
    TE_WriteFloat("m_vOrigin[2]", endPos[2]);
    TE_WriteFloat("m_flScale", 0.0);
    TE_WriteNum("m_fFlags", 1);
    TE_WriteNum("m_iEffectName", effectIndex);
    TE_WriteNum("m_nHitBox", particleIndex);
    TE_WriteNum("entindex", -1);
    TE_SendToAll();
}
//Replaces any old buff with same details, else inserts a new one.
public void insertBuff(int client, Buff newBuff){
	int replacementID = getNextBuff(client);
		
	for(int i = 0;i < MAXBUFFS;++i){
		if(playerBuffs[client][i].id == newBuff.id && playerBuffs[client][i].priority <= newBuff.priority)
			{replacementID = i;break;}
	}
	buffChange[client] = true;
	playerBuffs[client][replacementID] = OnStatusEffectApplied(client, newBuff);
	//PrintToServer("added %s to %N for %.2fs. ID = %i, index = %i", newBuff.name, client, newBuff.duration -GetGameTime(), newBuff.id, replacementID);
}
public bool hasBuffIndex(int client, int index){
	if(isBonus[index]){
		for(int i = 0; i < MAXBUFFS; ++i){
			if(playerBuffs[client][i].id == Buff_Nullification && playerBuffs[client][i].duration > GetGameTime())
				return false;
		}
	}

	for(int i = 0; i < MAXBUFFS; ++i){
		if(playerBuffs[client][i].id == index && playerBuffs[client][i].duration > GetGameTime())
			return true;
	}
	return false;
}
public int getBuffInArray(int client, int index){
	for(int i = 0; i < MAXBUFFS; ++i){
		if(playerBuffs[client][i].id == index)
			return i;
	}
	return -1;
}
public int getNextBuff(int client){
	for(int i = 0; i < MAXBUFFS; ++i){
		if(playerBuffs[client][i].id == 0)
			return i;
	}
	return 0;
}
public void clearAllBuffs(int client){
	for(int i = 0; i < MAXBUFFS; ++i){
		clearBuff(client, i);
	}
}
public void clearBuff(int client, int index){
	OnStatusEffectRemoved(client, playerBuffs[client][index]);
	playerBuffs[client][index].clear();
}
void removeDebuffs(int client){
	removeAfterburn(client);
	BleedBuildup[client] = 0.0;
	ConcussionBuildup[client] = 0.0;

	for(int i = 0; i < MAXBUFFS; i++){
		if(isBonus[playerBuffs[client][i].id])
			continue;
		clearBuff(client, i);
	}
}
public void giveDefenseBuff(int client, float duration){
	Buff defenseBuff;
	defenseBuff.init("Defense Bonus", "", Buff_DefenseBoost, 1, client, duration);
	defenseBuff.multiplicativeDamageTaken = 0.65;
	insertBuff(client, defenseBuff);
}
public int GetAmountOfDebuffs(int i){
	int amount = 0;
	if(TF2_IsPlayerInCondition(i, TFCond_Slowed))
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_Dazed))
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_OnFire))
		++amount;
	if(miniCritStatusVictim[i]-GetGameTime() > 0.0)
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_Bleeding))
		++amount;
	if(MadmilkDuration[i] > GetGameTime())
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_Sapped))
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_FreezeInput))
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_HealingDebuff))
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_Gas))
		++amount;

	for(int buff = 0;buff < MAXBUFFS; buff++)
	{
		if(playerBuffs[i][buff].id == 0)
			continue;
		if(!isBonus[playerBuffs[i][buff].id])
			amount++;
	}
		
	return amount;
}
public int GetAmountOfBuffs(int i){
	int amount = 0;
	if(TF2_IsPlayerInCondition(i, TFCond_Ubercharged))
		++amount;
	if(TF2_IsPlayerCritBuffed(i))
		++amount;
	if(miniCritStatusAttacker[i]-GetGameTime() > 0.0)
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_MegaHeal))
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_SpeedBuffAlly))
		++amount;
	for(int buff = 58; buff <= 63; ++buff)
	{
		if(TF2_IsPlayerInCondition(i, view_as<TFCond>(buff)))
			amount++;
	}

	for(int buff = 0;buff < MAXBUFFS; buff++)
	{
		if(playerBuffs[i][buff].id == 0)
			continue;
		if(isBonus[playerBuffs[i][buff].id])
			amount++;
	}
		
	return amount;
}

float applyMultSeverityMod(float val, float severity){
	/* 
	//	we want all buffs and debuffs to scale based off of their effectiveness
	//	so severity only applies to the buff/debuff portion of a value.
	// 	eg: 0.8x movespeed (1.25x slow) with 2x severity would be 0.66x movespeed (1.5x slow)
	//	eg: 1.25x damage with 2x severity would be 1.5x damage	
	*/
	if(val > 1.0 || val < 0.0) // why are we trying to flip values here :sob:
		return 1.0+(val-1.0)*severity;
	else if(val < 1.0)
		return 1.0/(1.0+(1.0/val-1.0)*severity);
	return 1.0;
}

public void ManagePlayerBuffs(int i){
	float additiveDamageRawBuff,additiveDamageMultBuff = 1.0,multiplicativeDamageBuff = 1.0,additiveAttackSpeedMultBuff = 1.0,multiplicativeAttackSpeedMultBuff = 1.0,additiveMoveSpeedMultBuff = 1.0,additiveDamageTakenBuff = 1.0,multiplicativeDamageTakenBuff = 1.0, additiveArmorPenetration = 0.0, multiplicativeMoveSpeedMult = 1.0, additiveCritBlock = 0.0;

	char details[255] = "Statuses Active:"

	if(!hasBuffIndex(i, Buff_Nullification)) {
		for(int buff = 0;buff < MAXBUFFS; buff++)
		{
			if(playerBuffs[i][buff].id == 0)
				continue;

			//Clear out any non-active buffs.
			if(playerBuffs[i][buff].duration != 0.0 && playerBuffs[i][buff].duration < GetGameTime()){
				clearBuff(i, buff);
				buffChange[i]=true;
				continue;
			}

			bool flag;
			
			for(int buffCheck = 0; buffCheck < MAXBUFFS; buffCheck++)
			{
				if(playerBuffs[i][buffCheck].duration == 0.0)
					continue;
				if(buffCheck == buff)
					continue;
				if(playerBuffs[i][buffCheck].id == playerBuffs[i][buff].id &&
					(playerBuffs[i][buffCheck].severity > playerBuffs[i][buff].severity || playerBuffs[i][buffCheck].priority > playerBuffs[i][buff].priority))
					{flag = true;break;}
			}

			if(flag)
				continue;

			additiveDamageRawBuff += playerBuffs[i][buff].additiveDamageRaw * playerBuffs[i][buff].severity;
			additiveDamageMultBuff += playerBuffs[i][buff].additiveDamageMult * playerBuffs[i][buff].severity;
			additiveAttackSpeedMultBuff += playerBuffs[i][buff].additiveAttackSpeedMult * playerBuffs[i][buff].severity;
			additiveMoveSpeedMultBuff += playerBuffs[i][buff].additiveMoveSpeedMult * playerBuffs[i][buff].severity;
			additiveDamageTakenBuff += playerBuffs[i][buff].additiveDamageTaken * playerBuffs[i][buff].severity;
			additiveArmorPenetration += playerBuffs[i][buff].additiveArmorPenetration * playerBuffs[i][buff].severity;
			additiveCritBlock += playerBuffs[i][buff].additiveCritBlock * playerBuffs[i][buff].severity;

			multiplicativeDamageBuff *= applyMultSeverityMod(playerBuffs[i][buff].multiplicativeDamage, playerBuffs[i][buff].severity);
			multiplicativeDamageTakenBuff *= applyMultSeverityMod(playerBuffs[i][buff].multiplicativeDamageTaken, playerBuffs[i][buff].severity);
			multiplicativeAttackSpeedMultBuff *= applyMultSeverityMod(playerBuffs[i][buff].multiplicativeAttackSpeedMult, playerBuffs[i][buff].severity);
			multiplicativeMoveSpeedMult *= applyMultSeverityMod(playerBuffs[i][buff].multiplicativeMoveSpeedMult, playerBuffs[i][buff].severity);

			if(playerBuffs[i][buff].description[0] != '\0')
				Format(details, sizeof(details), "%s\n%s: - %.1fs\n  %s", details, playerBuffs[i][buff].name, playerBuffs[i][buff].duration - GetGameTime(), playerBuffs[i][buff].description);
			else
				Format(details, sizeof(details), "%s\n%s - %.1fs", details, playerBuffs[i][buff].name, playerBuffs[i][buff].duration - GetGameTime());
		}
	}

	Address relentlessPowerup = TF2Attrib_GetByName(i, "relentless powerup");
	if(relentlessPowerup != Address_Null){
		buffChange[i] = true;
		if(TF2Attrib_GetValue(relentlessPowerup) > 0.0){
			Format(details, sizeof(details), "%s\n%s", details, "Relentless Powerup");
			additiveAttackSpeedMultBuff += (relentlessTicks[i] > 667 ? 667 : relentlessTicks[i])/(TICKRATE*5.0);
		}
		else
			TF2Attrib_RemoveByName(i, "relentless powerup");
	}

	if(GetAttribute(i, "supernova powerup", 0.0) == 3){
		float buff = 1.0;
		for(int victims = 1;victims<=MaxClients;victims++){
			if(isTagged[i][victims])
				buff += 0.08;
		}
		Format(details, sizeof(details), "%s\n%s %.2fx", details, "Thunderstorm Powerup",buff);
	}

	if(TF2_IsPlayerInCondition(i, TFCond_Sapped))
	{
		int spy = TF2Util_GetPlayerConditionProvider(i, TFCond_Sapped);
		if(IsValidClient3(spy)){
			int sapper = TF2Util_GetPlayerLoadoutEntity(spy,4);
			if(IsValidWeapon(sapper)){
				multiplicativeDamageTakenBuff *= TF2Attrib_HookValueFloat(1.0, "apply_vuln_on_sapped", sapper);
			}
		}
	}
	if(TF2Attrib_HookValueFloat(0.0, "agility_powerup", i) == 1.0){
		additiveAttackSpeedMultBuff += 0.5;
	}
	if(TF2Attrib_HookValueFloat(0.0, "king_powerup", i) == 1.0){
		additiveDamageMultBuff += 0.2;
	}
	
	float teamTacticsBonus = 0.0;
	for(int savior = 1;savior<=MaxClients;++savior){
		if(!IsValidClient3(savior))
			continue;
		if(!IsPlayerAlive(savior))
			continue;
		if(IsOnDifferentTeams(i,savior))
			continue;

		teamTacticsBonus += TeamTacticsBuildup[savior];
	}
	additiveDamageMultBuff += teamTacticsBonus;

	if(teamTacticsBonus > 0.0){
		Format(details, sizeof(details), "%s\n%s - %.1f٪", details, "Team Tactics", teamTacticsBonus*100);
	}

	float reactiveAirblastRes = 1.0;
	if(hasBuffIndex(i, Buff_Airblasted)){
		reactiveAirblastRes -= 0.25*(playerBuffs[i][getBuffInArray(i, Buff_Airblasted)].duration-GetGameTime());
	}

	TF2Attrib_SetByName(i, "additive damage bonus", additiveDamageRawBuff);
	TF2Attrib_SetByName(i, "damage mult 1", additiveDamageMultBuff*multiplicativeDamageBuff);
	TF2Attrib_SetByName(i, "firerate player buff", 1.0/(additiveAttackSpeedMultBuff*multiplicativeAttackSpeedMultBuff));
	TF2Attrib_SetByName(i, "firerate sentry buff", 1.0/(additiveAttackSpeedMultBuff*multiplicativeAttackSpeedMultBuff));
	TF2Attrib_SetByName(i, "recharge rate player buff", 1.0/(additiveAttackSpeedMultBuff*multiplicativeAttackSpeedMultBuff));
	TF2Attrib_SetByName(i, "Reload time decreased", 1.0/(additiveAttackSpeedMultBuff*multiplicativeAttackSpeedMultBuff));
	TF2Attrib_SetByName(i, "movespeed player buff", additiveMoveSpeedMultBuff*multiplicativeMoveSpeedMult);
	TF2Attrib_SetByName(i, "damage taken mult 4", additiveDamageTakenBuff*multiplicativeDamageTakenBuff);
	TF2Attrib_SetByName(i, "armor penetration buff", additiveArmorPenetration);
	TF2Attrib_SetByName(i, "airblast vulnerability multiplier hidden", reactiveAirblastRes);
	TF2Attrib_SetByName(i, "critical block rating buff", additiveCritBlock);
	TF2Attrib_ClearCache(i);
	int CWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
	if(IsValidWeapon(CWeapon)){
		TF2Attrib_ClearCache(CWeapon);
	}

	if(miniCritStatusVictim[i]-GetGameTime() > 0.0){
		Format(details, sizeof(details), "%s\n%s - %.1fs", details, "Marked-For-Death", miniCritStatusVictim[i]-GetGameTime());
		TF2_AddCondition(i, TFCond_MarkedForDeath, 0.2);
	}
	if(miniCritStatusAttacker[i]-GetGameTime() > 0.0){
		Format(details, sizeof(details), "%s\n%s - %.1fs", details, "Minicrits", miniCritStatusAttacker[i]-GetGameTime());
		TF2_AddCondition(i, TFCond_Buffed, 0.2);
	}

	if(IsFakeClient(i) || disableIFMiniHud[i] > GetGameTime())
		return;

	if(LightningEnchantmentDuration[i] > GetGameTime()){
		Format(details, sizeof(details), "%s\nLightning Enchantment | %.2fs | +%s DPS", details, LightningEnchantmentDuration[i] - GetGameTime(),  GetAlphabetForm(LightningEnchantment[i]));
	}
	if(DarkmoonBladeDuration[i] > GetGameTime()){
		Format(details, sizeof(details), "%s\nDarkmoon Blade | %.2fs | +%s Melee Damage", details, DarkmoonBladeDuration[i] - GetGameTime(), GetAlphabetForm(DarkmoonBlade[i]));
	}
	if(InfernalEnchantmentDuration[i] > GetGameTime()){
		Format(details, sizeof(details), "%s\nInfernal Enchantment | %.2fs | +%s Infernal DPS", details, InfernalEnchantmentDuration[i] - GetGameTime(), GetAlphabetForm(InfernalEnchantment[i]));
	}
	if(karmicJusticeScaling[i]){
		Format(details, sizeof(details), "%s\nKarmic Justice | %.2f Scaling", details, karmicJusticeScaling[i]);
	}

	if(MadmilkDuration[i]-GetGameTime() > 0.0){
		Format(details, sizeof(details), "%s\n%s - %.1fs", details, "Milked", MadmilkDuration[i]-GetGameTime());
	}

	if(TF2_IsPlayerInCondition(i, TFCond_AfterburnImmune)){
		Format(details, sizeof(details), "%s\n%s - %.1fs", details, "Afterburn Immunity", TF2Util_GetPlayerConditionDuration(i, TFCond_AfterburnImmune));
	}
	else{
		float totalAfterburn = 0.0;
		for(int stack=0; stack<MAX_AFTERBURN_STACKS;stack++){
			if(playerAfterburn[i][stack].remainingTicks <= 0)
				continue;
			
			totalAfterburn += playerAfterburn[i][stack].damage;
		}
		if(totalAfterburn > 0) {
			Format(details, sizeof(details), "%s\nAfterburn | %s Incoming DPS", details, GetAlphabetForm(totalAfterburn));
		}
	}

	if(additiveDamageRawBuff != 0.0)
		Format(details, sizeof(details), "%s\n+%i Damage", details, RoundToNearest(additiveDamageRawBuff));
	
	if(additiveDamageMultBuff*multiplicativeDamageBuff != 1.0)
		Format(details, sizeof(details), "%s\n+%i٪ Damage", details, RoundToNearest(((additiveDamageMultBuff*multiplicativeDamageBuff)-1.0)*100.0) );

	if(additiveAttackSpeedMultBuff*multiplicativeAttackSpeedMultBuff != 1.0)
		Format(details, sizeof(details), "%s\n+%i٪ Fire Rate", details, RoundToNearest(((additiveAttackSpeedMultBuff*multiplicativeAttackSpeedMultBuff)-1.0)*100.0) );

	if(additiveMoveSpeedMultBuff > 1.0)
		Format(details, sizeof(details), "%s\n+%i٪ Move Speed", details, RoundToNearest((additiveMoveSpeedMultBuff-1.0)*100.0) );
	else if(additiveMoveSpeedMultBuff < 1.0)
		Format(details, sizeof(details), "%s\n%i٪ Move Speed", details, RoundToNearest((additiveMoveSpeedMultBuff-1.0)*100.0) );

	if(additiveDamageTakenBuff*multiplicativeDamageTakenBuff > 1.0)
		Format(details, sizeof(details), "%s\n+%i٪ Damage Vulnerability", details, RoundToNearest(((additiveDamageTakenBuff*multiplicativeDamageTakenBuff)-1.0)*100.0) );
	else if (additiveDamageTakenBuff*multiplicativeDamageTakenBuff < 1.0)
		Format(details, sizeof(details), "%s\n-%i٪ Damage Taken", details, RoundToNearest((1.0-(additiveDamageTakenBuff*multiplicativeDamageTakenBuff)) *100.0) );

	float healingMult = GetPlayerHealingMultiplier(i);
	if(healingMult > 1.0)
		Format(details, sizeof(details), "%s\n+%i٪ Healing Received", details, RoundToNearest((healingMult - 1.0) * 100.0) );
	else if (healingMult < 1.0)
		Format(details, sizeof(details), "%s\n-%i٪ Healing Received", details, RoundToNearest((1.0-healingMult) * 100.0) );

	if(additiveCritBlock > 0.0)
		Format(details, sizeof(details), "%s\n+%.0f Critical Block Rating", details, additiveCritBlock);
	else if (additiveCritBlock < 0.0)
		Format(details, sizeof(details), "%s\n%.0f Critical Block Rating", details, additiveCritBlock);

	SendItemInfo(i, details);
}
public ApplyUberBuffs(int medic, int target, int medigun){
	/*
		Debug: Works perfectly!
		PrintToServer("Medic = %i | Target = %i | Medigun = %i", medic, target, medigun);
	*/

	bool applyToTarget = IsValidClient3(target) && IsPlayerAlive(target);
	int uberBits = TF2Attrib_HookValueInt(0, "additional_ubers", medigun);

	if(uberBits & UBER_INVULN){
		TF2_AddCondition(medic, TFCond_UberchargedCanteen, 0.2, medic);
		if(applyToTarget)
			TF2_AddCondition(target, TFCond_UberchargedCanteen, 0.2, medic);
	}
	if(uberBits & UBER_CRIT){
		TF2_AddCondition(medic, TFCond_CritCanteen, 0.2, medic);
		if(applyToTarget)
			TF2_AddCondition(target, TFCond_CritCanteen, 0.2, medic);
	}
	if(uberBits & UBER_MEGAHEAL){
		TF2_AddCondition(medic, TFCond_MegaHeal, 0.2, medic);
		if(applyToTarget)
			TF2_AddCondition(target, TFCond_MegaHeal, 0.2, medic);
	}
	if(uberBits & UBER_HASTE){
		Buff hasteBuff;
		hasteBuff.init("Minor Haste", "", Buff_Haste, 1, medic, 0.2);
		hasteBuff.additiveAttackSpeedMult = 0.5;
		insertBuff(medic, hasteBuff);

		if(applyToTarget)
			insertBuff(target, hasteBuff);
	}
	if(uberBits & UBER_DEFENSE){
		Buff defenseBuff;
		defenseBuff.init("Major Defense Bonus", "", Buff_DefenseBoost, 2, medic, 0.2);
		defenseBuff.multiplicativeDamageTaken = 0.5;
		insertBuff(medic, defenseBuff);

		if(applyToTarget)
			insertBuff(target, defenseBuff);
	}
	if(uberBits & UBER_SPEED){
		Buff speedBuff;
		speedBuff.init("Major Speed Bonus", "", Buff_Speed, 2, medic, 0.2);
		speedBuff.additiveMoveSpeedMult = 0.4;
		insertBuff(medic, speedBuff);

		if(applyToTarget)
			insertBuff(target, speedBuff);
	}
}
public GetUpgrade_CatList(char[] WCName)
{
	int i, wis, w_id
	
	wis = 0
	
	for (i = wis, w_id = -1; i < WCNAMELISTSIZE; ++i)
	{
		if (StrEqual(wcnamelist[i], WCName, false))
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
public float ParseShorthand(char[] input, int size){
	int thousands = ReplaceString(input, size, "k", "", false);
	int millions = ReplaceString(input, size, "m", "", false);

	float num = StringToFloat(input);
	if(thousands)
		num*=1000.0;
	if(millions)
		num*=1000000.0;

	return num;
}
stock EntityExplosion(owner, float damage, float radius, float pos[3], soundType = 0, bool visual = true, entity = -1, float soundLevel = SNDVOL_NORMAL,damagetype = DMG_BLAST, weapon = -1, float falloff = 0.0, soundPriority = SNDLEVEL_NORMAL, bool ignition = false, char[] particle = "ExplosionCore_MidAir", float knockback = 0.0, bool noMultihit = false)
{
	if(entity == -1 || !IsValidEdict(entity))
		entity = owner;
	int i = -1;

	while ((i = FindEntityByClassname(i, "*")) != -1)
	{
		if(IsValidForDamage(i) && !ShouldNotHit[entity][i] && IsOnDifferentTeams(owner,i) && i != entity)
		{
			float targetvec[3];
			float distance;
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", targetvec);
			distance = GetVectorDistance(pos, targetvec)
			if(distance <= radius)
			{
				if(IsPointVisible(pos,targetvec))
				{
					float baseExplosionDamage = damage;
					if(falloff != 0.0)
					{
						float ratio = (1.0-(distance/radius)*falloff);
						if(ratio < 0.5)
							ratio = 0.5;
						if(ratio >= 0.95)
							ratio = 1.0;
						baseExplosionDamage *= ratio
					}

					if(IsValidEdict(weapon) && IsValidClient3(i))
					{
						SDKHooks_TakeDamage(i,entity,owner,baseExplosionDamage,damagetype|DMG_IGNOREHOOK,weapon,_,_,false)
						if(knockback > 0.0)
							PushEntity(i, owner, knockback, 200.0);
						
						if(ignition)
							applyAfterburn(i, owner, weapon, damage);
					}
					else
					{
						SDKHooks_TakeDamage(i,entity,owner,baseExplosionDamage,damagetype|DMG_IGNOREHOOK,_,_,_, false);
					}
					if(noMultihit)
						ShouldNotHit[entity][i] = true;
				}
			}
		}
	}
	if(visual)
	{
		/*int particle = CreateEntityByName("info_particle_system" );
		if (IsValidEdict(particle ) )
		{
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR );
			DispatchKeyValue(particle, "effect_name", "ExplosionCore_MidAir" );
			DispatchSpawn(particle );
			ActivateEntity(particle );
			AcceptEntityInput(particle, "start" );
			SetVariantString("OnUser1 !self:Kill::8:-1" );
			AcceptEntityInput(particle, "AddOutput" );
			AcceptEntityInput(particle, "FireUser1" );
			CreateTimer(0.01, SelfDestruct, EntIndexToEntRef(particle));
		}*/
		CreateParticleEx(-1, particle, -1, -1, pos);
	}
	int random = GetRandomInt(1,3)
	switch(soundType)
	{
		case 1:
		{
			if(random == 1){
				EmitSoundToAll(ExplosionSound1, 0,_,soundPriority,_,soundLevel, _, _, pos);
				EmitSoundToAll(ExplosionSound1, 0,_,soundPriority,_,soundLevel, _, _, pos);
				EmitSoundToAll(ExplosionSound1, 0,_,soundPriority,_,soundLevel, _, _, pos);
			}else if(random == 2){
				EmitSoundToAll(ExplosionSound2, 0,_,soundPriority,_,soundLevel, _, _, pos);
				EmitSoundToAll(ExplosionSound2, 0,_,soundPriority,_,soundLevel, _, _, pos);
				EmitSoundToAll(ExplosionSound2, 0,_,soundPriority,_,soundLevel, _, _, pos);
			}else if(random == 3){
				EmitSoundToAll(ExplosionSound3, 0,_,soundPriority,_,soundLevel, _, _, pos);
				EmitSoundToAll(ExplosionSound3, 0,_,soundPriority,_,soundLevel, _, _, pos);
				EmitSoundToAll(ExplosionSound3, 0,_,soundPriority,_,soundLevel, _, _, pos);
			}
		}
		case 2:
		{
			EmitSoundToAll(DetonatorExplosionSound, 0, -1, soundPriority, 0, soundLevel, _, _, pos);
		}
		case 3:
		{
			EmitSoundToAll(OrnamentExplosionSound, 0, -1, soundPriority, 0, soundLevel, _, _, pos);
		}
		case 0:
		{
			if(random == 1){
				EmitSoundToAll(ExplosionSound1, 0,_,soundPriority,_,soundLevel, _, _, pos);
			}else if(random == 2){
				EmitSoundToAll(ExplosionSound2, 0,_,soundPriority,_,soundLevel, _, _, pos);
			}else if(random == 3){
				EmitSoundToAll(ExplosionSound3, 0,_,soundPriority,_,soundLevel, _, _, pos);
			}
		}
	}
}

CheckForAttunement(client)
{
	bool flag = false;
	for(int i = 0;i<Max_Attunement_Slots;++i)
	{
		if(AttunedSpells[client][i] != 0)
		{
			flag = true;
			break;
		}
	}
	return flag;
}
public bool GiveNewWeapon(client, slot)
{
	int oldWeapon = EntRefToEntIndex(UniqueWeaponRef[client]);
	if(IsValidEntity(oldWeapon)) {
		EquipPlayerWeapon(client, oldWeapon);
		return true;
	}
	
	Handle newItem = TF2Items_CreateItem(PRESERVE_ATTRIBUTES|FORCE_GENERATION);
	TF2Items_SetLevel(newItem, 242);
	TF2Items_SetItemIndex(newItem, currentitem_idx[client][slot]);
	TF2Items_SetClassname(newItem, currentitem_classname[client][slot]);
	
	int entity = TF2Items_GiveNamedItem(client, newItem);
	if (IsValidEdict(entity))
	{
		UniqueWeaponRef[client] = EntIndexToEntRef(entity);
		currentitem_level[client][slot] = 242;
		GiveNewUpgradedWeapon_(client, slot);
		EquipPlayerWeapon(client, entity);
		return true;
	}
	return false
}
void GiveNewUpgradedWeapon_(int client, int slot)
{
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
		iEnt = EntRefToEntIndex(UniqueWeaponRef[client]);
	}
	if (IsValidEdict(iEnt) && HasEntProp(iEnt, Prop_Send, "m_AttributeList"))
	{
		TF2Attrib_RemoveByName(iEnt, "bullets per shot bonus");
		if(iNumAttributes > 0 )
		{
			float multiplier = GetAttribute(iEnt, "upgrade effectiveness", 1.0);
			for(int a = 0; a < iNumAttributes ; a++ )
			{
				if (upgrades[currentupgrades_idx[client][slot][a]].attr_name[0] == '\0')
					continue;
					
				float value = currentupgrades_val[client][slot][a];
				if(multiplier != 1.0)
					if(currentupgrades_i[client][slot][a] == 0.0)
						if(value < upgrades[currentupgrades_idx[client][slot][a]].i_val)
							value = 1+(Pow(value,multiplier)-upgrades[currentupgrades_idx[client][slot][a]].i_val);
						else
							value = 1+multiplier*(value-upgrades[currentupgrades_idx[client][slot][a]].i_val);

				TF2Attrib_SetByName(iEnt, upgrades[currentupgrades_idx[client][slot][a]].attr_name, value);
			}
		}

		float bpsMult = GetAttribute(iEnt, "bullets per shot bonus", 1.0);
		bpsMult *= GetAttribute(iEnt, "bullets per shot mult", 1.0);
		bpsMult *= GetAttribute(iEnt, "bullets per shot mult 2", 1.0);
		if(bpsMult != 1.0)
			TF2Attrib_SetByName(iEnt, "bullets per shot bonus", bpsMult+0.01); // floating point number shenanigans :P
		else
			TF2Attrib_RemoveByName(iEnt, "bullets per shot bonus");

		refreshUpgrades(client, slot);
	}
}
stock is_client_got_req(client, upgrade_choice, slot, inum, float rate = 1.0)
{

	if (canBypassRestriction[client])
		return 1;

	float up_cost = float(upgrades[upgrade_choice].cost) * rate;
	int max_ups = currentupgrades_number[client][slot];
	if (slot == 1)
	{
		up_cost *= SecondaryCostReduction
	}
	if (inum != 20000 && upgrades[upgrade_choice].ratio)
	{
		if(currentupgrades_i[client][slot][inum] != 0.0)
		{
			up_cost += up_cost * ((currentupgrades_val[client][slot][inum] - currentupgrades_i[client][slot][inum])
			/ upgrades[upgrade_choice].ratio) * upgrades[upgrade_choice].cost_inc_ratio;
		}
		else
		{
			up_cost += up_cost * ((currentupgrades_val[client][slot][inum] - upgrades[upgrade_choice].i_val)
			/ upgrades[upgrade_choice].ratio) * upgrades[upgrade_choice].cost_inc_ratio;
		}
		if (up_cost < 0.0)
		{
			up_cost *= -1.0;
			if (up_cost < upgrades[upgrade_choice].cost)
			{
				up_cost = float(upgrades[upgrade_choice].cost);
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
		if(upgrades[upgrade_choice].restriction_category != 0)
		{
			if(inum == 20000 || currentupgrades_val[client][slot][inum] - upgrades[upgrade_choice].i_val == 0.0)
			{
				int cap = 1;
				if(gameStage >= 2 && slot == 4){
					cap++;
				}
				if(currentupgrades_restriction[client][slot][upgrades[upgrade_choice].restriction_category] >= cap){
					PrintToChat(client, "You already have something that fits this restriction category.");
					EmitSoundToClient(client, SOUND_FAIL);
					return 0;
				}
				currentupgrades_restriction[client][slot][upgrades[upgrade_choice].restriction_category]++;
			}
		}
		
		if (inum != 20000)
		{	
			if (currentupgrades_val[client][slot][inum] == upgrades[upgrade_choice].m_val)
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
	if ((upgrades[upgrade_choice].ratio > 0.0
		 && currentupgrades_val[client][slot][inum] > upgrades[upgrade_choice].m_val)
		|| (upgrades[upgrade_choice].ratio < 0.0 
			&& currentupgrades_val[client][slot][inum] < upgrades[upgrade_choice].m_val))
		{
			currentupgrades_val[client][slot][inum] = upgrades[upgrade_choice].m_val
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
	client_spent_money_mvm_checkpoint[client][slot] = 0.0
	currentupgrades_number[client][slot] = 0;
	currentupgrades_number_mvm_checkpoint[client][slot] = 0;
	client_tweak_highest_requirement[client][slot] = 0.0;
	
	for(int y = 0; y<5;y++)
	{
		currentupgrades_restriction[client][slot][y] = 0;
		currentupgrades_restriction_mvm_checkpoint[client][slot][y] = 0;
	}
	
	
	for (int i = 0; i < iNumAttributes; ++i)
	{
		currentupgrades_val_mvm_checkpoint[client][slot][i] = 0.0;
		currentupgrades_val[client][slot][i] = 0.0;
		currentupgrades_i[client][slot][i] = 0.0;
		currentupgrades_idx[client][slot][i] = 0;
		currentupgrades_idx_mvm_checkpoint[client][slot][i] = 0;
	}
	//I AM THE STORM THAT IS APPROACHING
	//Thank you retard MR L
	for(int i = 0; i < MAX_ATTRIBUTES; ++i)
	{
		upgrades_ref_to_idx[client][slot][i] = 20000;
		upgrades_ref_to_idx_mvm_checkpoint[client][slot][i] = 20000;
	}
	
	if (slot != 4 && currentitem_idx[client][slot] && !replenishStatus)
	{
		currentitem_idx[client][slot] = 20000
	}
	
	if (slot == 3)
	{
		currentitem_idx[client][slot] = 20000
		currentitem_ent_idx[client][slot] = -1
		upgrades_weapon_current[client] = -1;
		GiveNewUpgradedWeapon_(client, slot)
		UniqueWeaponRef[client] = -1;
		UniqueWeaponRef_mvm_checkpoint[client] = -1;
	}
	if (slot == 4)
	{
		currentitem_idx[client][slot] = 20000
		GiveNewUpgradedWeapon_(client, slot)
		for(int i = 0; i < Max_Attunement_Slots; ++i)
		{
			AttunedSpells[client][i] = 0;
		}
	}
}

public ResetClientUpgrades(client)
{
	for (int slot = 0; slot < NB_SLOTS_UED; slot++)
	{
		ResetClientUpgrade_slot(client, slot)
	}
}
public DefineAttributesTab(client, itemidx, slot, entity)
{
	if (itemidx >= 0 && itemidx != currentitem_idx[client][slot])
	{
		if(currentitem_level[client][slot] != 242)
			ResetClientUpgrade_slot(client, slot);

		int a, a2, i, a_i
	
		currentitem_idx[client][slot] = itemidx
		int attributeIndexes[21];
		int attributeCount = TF2Attrib_ListDefIndices(entity, attributeIndexes);
		Address attr;
		for(a = 0, a2 = 0; a < attributeCount && a < 21; a++ )
		{
			attr = TF2Attrib_GetByDefIndex(entity, attributeIndexes[a]);
			if(attr == Address_Null)
				continue;

			char Buf[64]
			a_i = attributeIndexes[a];
			TF2Econ_GetAttributeName(a_i, Buf, 64);
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
			TF2Econ_GetAttributeName(a_i, Buf, 64);
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

		if(currentitem_level[client][slot] == 242){
			for(a = 0; a < upgrades_weapon_nb_att[upgrades_weapon_current[client]] && a < 42; a++ )
			{
				currentupgrades_idx[client][slot][a2] = upgrades_weapon_att_idx[upgrades_weapon_current[client]][a]
				upgrades_ref_to_idx[client][slot][currentupgrades_idx[client][slot][a2]] = a2;
				currentupgrades_val[client][slot][a2] = upgrades_weapon_att_amt[upgrades_weapon_current[client]][a];
				currentupgrades_i[client][slot][a2] = currentupgrades_val[client][slot][a2]
				a2++
			}
		}
		currentupgrades_number[client][slot] = a2

		DisplayItemChange(client,itemidx);
	}
}
DisplayItemChange(client,itemidx)
{
	char ChangeString[189];
	switch(itemidx)
	{
		//scout primaries
		case 45, 1078:
		{
			ChangeString = "Force-A-Nature | Has 3x slower fire rate, but 3x bullets per shot. Converts fire rate into damage.";
		}
		case 220:
		{
			ChangeString = "Shortstop | You deal and take 25% more damage.";
		}
		case 448:
		{
			ChangeString = "The Soda Popper | While held, converts 25% of health to damage reduction. 0.5x fire rate, but 0.55x damage. Converts fire rate into damage bonus.";
		}
		//scout secondaries
		case 46:
		{
			ChangeString = "Bonk! Atomic Punch | You gain a speed boost and some healing when used instead of invulnerability.";
		}
		case 449:
		{
			ChangeString = "The Winger | Right click is a dash ability based on your maximum speed. 3x slower reload speed.";
		}
		//Scout Melee
		case 44:
		{
			ChangeString = "The Sandman | Ball base damage increased to 35.";
		}
		case 648:
		{
			ChangeString = "The Wrap Assassin | Ball base damage increased to 35. Fires balls on primary fire.";
		}
		case 349:
		{
			ChangeString = "Sun-on-a-Stick | Deals 3x afterburn, but initial melee hit deals half. Converts fire rate to damage."
		}
		//Soldier Primary
		case 127:
		{
			ChangeString = "The Direct Hit | 1.7x damage.";
		}
		case 228,1085:
		{
			ChangeString = "The Black Box | +1 rocket per shot but 2x slower fire rate.";
		}
		case 414:
		{
			ChangeString = "The Liberty Launcher | Fires clip all at once. 0.4x reload time. Shots have a large delay in-between.";
		}
		case 441:
		{
			ChangeString = "The Cow Mangler 5000 | Secondary fire shot scales with clip size.";
		}
		case 1104:
		{
			ChangeString = "The Air Strike | Deals 0.33x damage and shoots 0.3x faster while airborne. Conserves ammo for 50% of shots.";
		}
		case 730:
		{
			ChangeString = "The Beggar's Bazooka | 70% faster fire rate, but you deal 75% less damage. Comes with rocket specialist. Converts fire rate into damage bonus.";
		}
		//Soldier Secondary
		case 129,1001:
		{
			ChangeString = "The Buff Banner | Rage scales off of firerate of weapon.";
		}
		case 226:
		{
			ChangeString = "The Battalion's Backup | No longer gives crit immunity. Rage scales off of firerate of weapon.";
		}
		case 354:
		{
			ChangeString = "The Concheror | Gives a +25% lifesteal effect to teammates when active. Can overheal to 150%. Rage scales off of firerate of weapon.";
		}
		case 133:
		{
			ChangeString = "The Gunboats | Reduces blast damage taken by -20%.";
		}
		case 442:
		{
			ChangeString = "The Righteous Bison | Shoots tracer rounds that also deals (1.25x) damage to enemies in a cross pattern. Converts fire rate to damage. 4x faster fire rate.";
		}
		case 1101:
		{
			ChangeString = "The B.A.S.E Jumper | Increased gravity & heavily increased mobility when deployed.";
		}
		//Soldier Melee
		case 416:
		{
			ChangeString = "The Market Gardener | 3x slower fire rate, gains +0.05% damage bonus per downward velocity in hammer units/s, splashes in a 300HU radius on hit. Converts fire rate to damage bonus.";
		}
		//Pyro Primary
		case 40,1146:
		{
			ChangeString = "The Backburner | Airblast damage and slowdown is disabled and instead fires an arrow that deals 50 base damage.";
		}
		case 215:
		{
			ChangeString = "The Degreaser | You deal 20% less damage. Airblast has 25% more radius and 1.4x damage.";
		}
		case 594:
		{
			ChangeString = "The Phlogistinator | Rage gain is now based on hits dealt rather than damage dealt. Rage gives minicrits and agility rune instead of crits.";
		}
		case 1178:
		{
			ChangeString = "Dragon's Fury | No longer has recharge penalty on airblast. Fire rate bonus is converted into damage.";
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
			ChangeString = "Sharpened Volcano Fragment | Deals 3x afterburn, but initial melee hit deals half. Converts fire rate to damage."
		}
		case 1181:
		{
			ChangeString = "Hot Hand | Detonates 40 stacks of afterburn on hit. Converts fire rate to damage. Acts as a normal fire axe."
		}
		//Demo Primary
		case 308:
		{
			ChangeString = "The Loch-n-Load | Deals 20% more damage. Projectiles don't have gravity.";
		}
		case 996:
		{
			ChangeString = "The Loose Cannon | Fires clip all at once. 0.4x reload time. Shots have a large delay in-between.";
		}
		case 1151:
		{
			ChangeString = "The Iron Bomber | Converts fire rate into damage bonus.";
		}
		//Demo Secondaries
		case 131,1144:
		{
			ChangeString = "The Chargin' Targe | Gives +50 base health. When the charge ends, it deals an explosion that has 70 base DPS which scales on current weapon.";
		}
		case 406:
		{
			ChangeString = "The Splendid Screen | When the charge ends, it deals an explosion that has 120 base DPS which scales on current weapon.";
		}
		case 1099:
		{
			ChangeString = "The Tide Turner | 1.5x incoming damage. 1.35x move speed. When the charge ends, it deals an explosion that has 120 base DPS which scales on current weapon.";
		}
		case 130:
		{
			ChangeString = "The Scottish Resistance | +60 max stickies.";
		}
		case 1150:
		{
			ChangeString = "The Quickiebomb Launcher | Middle click is a fast dash that scales off movespeed multipliers. -25% damage dealt. Converts fire rate bonuses to damage.";
		}
		//Demo Melees
		case 307:
		{
			ChangeString = "Ullapool Caber | Infinite explosive charges & converts fire rate to damage.";
		}
		case 404:
		{
			ChangeString = "Persian Persuader | Converts fire rate to damage.";
		}
		//Heavy Primaries
		case 41:
		{
			ChangeString = "Natascha | Shoots only 1 bullet per shot at 2x slower fire rate, but deals 7x damage and has tracer rounds. -70% spread. Converts fire rate into damage.";
		}
		case 312:
		{
			ChangeString = "The Brass Beast | Shoots rockets that have 90 base damage and 200HU blast radius and can penetrate enemies. Cannot hit enemies multiple times. 4x slower fire rate.";
		}
		case 811,832:
		{
			ChangeString = "The Huo-Long Heater | Shoots flares. Converts fire rate into damage. Press mouse3 (middle click) to detonate the flares. Massively increased blast radius.";
		}
		//Heavy Secondaries
		case 311:
		{
			ChangeString = "Buffalo Steak Sandvich | No longer limits speed.";
		}
		//Heavy Melee
		case 310:
		{
			ChangeString = "The Warrior's Spirit | Deals -40% damage. Shoots an additional 2 arrows per attack that deal 25 base damage.";
		}
		case 43:
		{
			ChangeString = "The Killing Gloves of Boxing | Gives 2 seconds of minicrits on kill instead.";
		}
		case 426:
		{
			ChangeString = "The Eviction Notice | 0.5x damage, 0.5x fire rate, and converts firerate into damage."
		}
		//Engineer Primary
		case 588:
		{
			ChangeString = "The Pomson 6000 | Shoots tracer rounds that also deals (1.25x) damage to enemies in a cross pattern. Converts fire rate to damage. 4x faster fire rate.";
		}
		case 141,1004:
		{
			ChangeString = "The Frontier Justice | On crit: target recieves 1.3x damage for 5s.";
		}
		case 997:
		{
			ChangeString = "The Rescue Ranger | Bolts have no gravity.";
		}
		//Engineer Secondary
		case 528:
		{
			ChangeString = "The Short Circuit | Shoots explosive bullets instead. Applies afterburn.";
		}
		//Engineer Melee
		case 329:
		{
			ChangeString = "The Jag | Will instantly build buildings at level 3, but will cost 100% of your metal.";
		}
		case 589:
		{
			ChangeString = "The Eureka Effect | Teleporting will deal 500 base DPS based on sentry upgrades and apply +100 radiation. Cannot build a sentry, but teleporters are instant-built.";
		}
		case 142:
		{
			ChangeString = "The Gunslinger | Throw out instant-built minisentries. Up to 5 sentries placed in total, and upon destroying, deal 70 base DPS. All buildings have 0.5x max health.";
		}
		//Medic Primaries
		case 36:
		{
			ChangeString = "The Blutsauger | +15% lifesteal.";
		}
		//Medic Secondaries
		case 411:
		{
			ChangeString = "The Quick-Fix | Uber gives an additional 2x healing received.";
		}
		//Medic Melee
		case 37:
		{
			ChangeString = "The Ubersaw | Gives 3% uber per hit.";
		}
		//Sniper Primaries
		case 230:
		{
			ChangeString = "The Sydney Sleeper | Shoots a high-velocity dart that splits into 5 jarates. Converts Fire Rate Bonus into Damage Bonus. 1.5x slower fire rate.";
		}
		case 526,30665:
		{
			ChangeString = "The Machina | Fully charged shots bounce to 3 other targets at max within a 350HU radius.";
		}
		case 1098:
		{
			ChangeString = "The Classic | +15% conditional status pierce.";
		}
		case 752:
		{
			ChangeString = "The Hitman's Heatmaker | Shoots explosive rounds. Gain +1% focus on hit; Focus now gives 1.5x fire rate. 50% ammo conservation.";
		}
		case 56,1005:
		{
			ChangeString = "The Huntsman | Has no drawspeed, Arrows fly straight. Slows enemy by -40% for 1s on hit. Has 36 base ammo.";
		}
		case 1092:
		{
			ChangeString = "The Fortified Compound | Greatbow styled. Cannot move when drawn, & deals massively increased damage. Converts fire rate to damage. Arrows fly straight.";
		}
		//Sniper Secondaries
		case 751:
		{
			ChangeString = "The Cleaner's Carbine | Crikey now applies mark for death. Close ranged backattacks do minicrits. Converts fire rate to damage.";
		}
		case 58:
		{
			ChangeString = "Jarate | Jarate effect now applies +5 damage (based on your scaling) to every hit taken.";
		}
		case 231:
		{
			ChangeString = "Darwin's Danger Shield | Reduces afterburn duration by -1 tick of damage. Does not reduce incoming fire damage.";
		}
		//Sniper Melees
		case 232:
		{
			ChangeString = "The Bushwacka | Launches projectile dealing 180 base damage and returns after 0.7s. Projectile pierces all targets forever and can hit multiple times. Fires 4x slower.";
		}
		//Spy Primaries
		case 61,1006:
		{
			ChangeString = "The Ambassador | Converts fire rate to damage. Can headshot for 4x damage. 2x slower fire rate.";
		}
		case 460:
		{
			ChangeString = "The Enforcer | Rapidly fires a two round burst. +20% conditional status pierce. Converts fire rate into damage.";
		}
		case 525:
		{
			ChangeString = "The Diamondback | Converts fire rate to damage.";
		}
		//Spy Melees
		case 356:
		{
			ChangeString = "The Conniver's Kunai | +35% lifesteal.";
		}
		case 649:
		{
			ChangeString = "The Spy-cicle | Damage dealt contributes to enemy freeze buildup at 135%.";
		}
		//Spy Misc
		case 735,736,810,831,933,1080,1102:
		{
			ChangeString = "Sappers | Destroys buildings within 110 damage ticks (regardless of damage modifiers.)";
		}
	}
	if(ChangeString[0])
	{
		CPrintToChat(client, "{valve}Incremental Fortress {default}| {lightcyan}Weapon Changes | %s", ChangeString)
	}
}
UpgradeItem(client, upgrade_choice, int &inum, float ratio, slot, bool bypassMax = false)
{
	if (inum == 20000)
	{
		inum = currentupgrades_number[client][slot]
		upgrades_ref_to_idx[client][slot][upgrade_choice] = inum;
		currentupgrades_idx[client][slot][inum] = upgrade_choice 
		currentupgrades_val[client][slot][inum] = upgrades[upgrade_choice].i_val;
		currentupgrades_number[client][slot] = currentupgrades_number[client][slot] + 1
		
		currentupgrades_val[client][slot][inum] += (upgrades[upgrade_choice].ratio * ratio);
	}
	else
	{
		currentupgrades_val[client][slot][inum] += (upgrades[upgrade_choice].ratio * ratio);
		if(!canBypassRestriction[client] && !bypassMax)
			check_apply_maxvalue(client, slot, inum, upgrade_choice)
	}
	client_last_up_idx[client] = upgrade_choice
	client_last_up_slot[client] = slot
}
public remove_attribute(client, inum, slot)
{
	int u = currentupgrades_idx[client][slot][inum];
	if (u != 20000)
	{
		if(currentupgrades_i[client][slot][inum] != 0.0 && upgrades[u].cost > 1.0)
		{
			currentupgrades_val[client][slot][inum] = currentupgrades_i[client][slot][inum];
		}
		else
		{
			currentupgrades_val[client][slot][inum] = upgrades[u].i_val;
		}

		if(upgrades[u].restriction_category != 0)
		{
			currentupgrades_restriction[client][slot][upgrades[u].restriction_category]--;
		}
	}
	GiveNewUpgradedWeapon_(client, slot)
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

RespawnEffect(client)
{
	current_class[client] = TF2_GetPlayerClass(client)
	fl_CurrentFocus[client] = fl_MaxFocus[client];
	LightningEnchantmentDuration[client] = 0.0;
	DarkmoonBladeDuration[client] = 0.0;
	TF2Attrib_SetByName(client,"airblast_pushback_no_stun", 1.0);
	TF2Attrib_SetByName(client,"airblast_destroy_projectile", 1.0);
	TF2Attrib_SetByName(client,"ignores other projectiles", 1.0);
	TF2Attrib_SetByName(client,"penetrate teammates", 1.0);
	TF2Attrib_SetByName(client,"dmg pierces resists absorbs", 1.0);
	TF2Attrib_SetByName(client,"no damage view flinch", 1.0);
	CreateTimer(0.2,GiveMaxHealth,GetClientUserId(client));
	CreateTimer(0.2,GiveMaxAmmo,GetClientUserId(client));
}
UpdateMaxValuesStage(int stage)
{
	for(int i = 0;i<MAX_ATTRIBUTES;++i)
	{
		if(upgrades[i].staged_max[stage] != 0.0)
		{
			upgrades[i].m_val = upgrades[i].staged_max[stage];
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
	if(!IsPlayerInSpawn(client))
	{
		ForcePlayerSuicide(client);
	}
}
public void ThrowBuilding(any buildref) {
	int building = EntRefToEntIndex(buildref);
	if (building == INVALID_ENT_REFERENCE) return;
	int owner = GetEntPropEnt(building, Prop_Send, "m_hBuilder");
	if (owner < 1 || owner > MaxClients || !IsClientInGame(owner)) return;
	
	float eyes[3];
	float origin[3];
	float angles[3];
	float fwd[3];
	float velocity[3];
	GetClientEyePosition(owner, origin);
	eyes = origin;
	//set origin in front of player
	GetClientEyeAngles(owner, angles);
	angles[0]=angles[2]=0.0;
	GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fwd, 64.0);
	AddVectors(origin, fwd, origin);
	//get angles/velocity
	GetClientEyeAngles(owner, angles);
	GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fwd, 1200.0);
	fwd[2] += (1200.0/3.25);//bit more archy
	AddVectors(velocity, fwd, velocity);
	angles[0] = angles[2] = 0.0; //upright angle = 0.0 yaw 0.0
	
	//double up the CheckThrowPos trace, since we're a tick later
	TR_TraceRayFilter(eyes, origin, MASK_PLAYERSOLID, RayType_EndPoint, TEF_HitSelfFilterPassClients, owner);
	if (TR_DidHit()) {
		// the building is already going up, we need to either handle the refund or break the building
		SetVariantInt(RoundToCeil(TF2Util_GetEntityMaxHealth(building)*1.5));
		AcceptEntityInput(building, "RemoveHealth");
		return;
	}
	
	int phys = CreateEntityByName("tf_projectile_rocket");
	if (phys == INVALID_ENT_REFERENCE) return;
	
	char targetName[24];
	Format(targetName, sizeof(targetName), "physbuilding_%08X", EntIndexToEntRef(phys));
	char buffer[64] = "models/weapons/w_models/w_toolbox.mdl";
	DispatchKeyValue(phys, "targetname", targetName);
	DispatchKeyValueVector(phys, "origin", origin);
	DispatchKeyValueVector(phys, "angles", angles);
	Format(buffer, sizeof(buffer), "%i", GetEntProp(building, Prop_Send, "m_nSkin"));
	DispatchKeyValue(phys, "skin", buffer);
	if (GetEntProp(building, Prop_Send, "m_bDisposableBuilding")) buffer = "0.66";
	else if (GetEntProp(building, Prop_Send, "m_bMiniBuilding")) buffer = "0.75";
	else buffer = "1.0";
	DispatchKeyValue(phys, "modelscale", buffer);
	if (!DispatchSpawn(phys)) {
		PrintToChat(owner, "Failed to spawn physics prop");
		return;
	}
	ActivateEntity(phys);
	SetEntityRenderMode(phys, RENDER_NORMAL);

	SetEntProp(building, Prop_Send, "m_bCarried", 1);
	SetEntProp(building, Prop_Send, "m_bBuilding", 0);
	SetEntityHealth(building, TF2Util_GetEntityMaxHealth(building));
	
	SetEntProp(phys, Prop_Send, "m_usSolidFlags", 0x0008 | 0x0080); 
	SetEntProp(phys, Prop_Send, "m_CollisionGroup", 1);
	TeleportEntity(phys, NULL_VECTOR, NULL_VECTOR, velocity);
	SetEntityGravity(phys, 1.5);
	SetEntityMoveType(phys, MOVETYPE_FLYGRAVITY);
	SetEntityModel(phys, "models/weapons/w_models/w_toolbox.mdl");
	SetEntProp(building, Prop_Send, "m_usSolidFlags", 0x0004);
	SetEntityRenderMode(building, RENDER_NONE);
	TeleportEntity(building, origin, NULL_VECTOR, NULL_VECTOR);

	SetVariantString("!activator");
	AcceptEntityInput(building, "SetParent", phys);

	CreateTimer(0.1,Timer_ThrownSentryDeploy,  buildref, TIMER_REPEAT);
	SDKHook(phys, SDKHook_StartTouch, StartTouchThrownSentryDeploy);
	jarateWeapon[phys] = EntIndexToEntRef(building);
}
public void function_AllowBuilding(int client){
	int wrench = TF2Util_GetPlayerLoadoutEntity(client,2);
	if(!IsValidWeapon(wrench)) return;

	int DispenserLimit = RoundToNearest(GetAttribute(wrench, "dispenser amount"));
	int SentryLimit = RoundToNearest(GetAttribute(wrench, "sentry amount"));

	int DispenserCount = 0;
	int SentryCount = 0;

	for(int i=0;i<2048;++i){

		if(!IsValidEntity(i)){
			continue;
		}

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));
		if (!(strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectDispenser") == 0) ){
			continue;
		}

		if(GetEntDataEnt2(i, OwnerOffset)!=client){
			continue;
		}


		int type=view_as<int>(function_GetBuildingType(i));

		//Switching the dispenser to a sapper type
		if(type==view_as<int>(TFObject_Dispenser)){
			DispenserCount=DispenserCount+1;
			SetEntProp(i, Prop_Send, "m_iObjectType", TFObject_Sapper);
			if(DispenserCount>=DispenserLimit){
				//if the limit is reached, disallow building
				SetEntProp(i, Prop_Send, "m_iObjectType", type);

			}

		//not a dispenser,
		}else if(type==view_as<int>(TFObject_Sentry)){
			SentryCount++;
			SetEntProp(i, Prop_Send, "m_iObjectType", TFObject_Sapper);
			if(SentryCount>=SentryLimit){
				//if the limit is reached, disallow building
				SetEntProp(i, Prop_Send, "m_iObjectType", type);
			}
		}
	//every building is in the desired state


	}
}
public void function_AllowDestroying(int client){
	for(int i=1;i<2048;++i){

		if(!IsValidEntity(i)){
			continue;
		}

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));

		if (!(strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectDispenser") == 0) ){
			continue;
		}

		if(GetEntDataEnt2(i, OwnerOffset)!=client){
			continue;
		}

		SetEntProp(i, Prop_Send, "m_iObjectType", function_GetBuildingType(i));
	}

}

public TFObjectType function_GetBuildingType(int entIndex){
	//This function relies on Netclass rather than building type since building type
	//gets changed
	decl String:netclass[32];
	GetEntityNetClass(entIndex, netclass, sizeof(netclass));

	if(strcmp(netclass, "CObjectSentrygun") == 0){
		return TFObject_Sentry;
	}
	if(strcmp(netclass, "CObjectDispenser") == 0){
		return TFObject_Dispenser;
	}

	return TFObject_Sapper;


}
//PostUpgrade
refreshUpgrades(client, slot)
{
	if(IsValidClient3(client))
	{
		current_class[client] = TF2_GetPlayerClass(client);
		int slotItem;
		int uniqueWeaponID = EntRefToEntIndex(UniqueWeaponRef[client])
		if(slot == 3 && IsValidEntity(uniqueWeaponID))
		{
			slotItem = uniqueWeaponID;
		}
		else
		{
			slotItem = currentitem_ent_idx[client][slot];
		}

		if(slot == 4)
		{
			UpdatePlayerSpellSlots(client);
			
			TF2Attrib_RemoveByName(client,"ubercharge rate bonus");
			TF2Attrib_RemoveByName(client,"heal rate bonus");
			TF2Attrib_RemoveByName(client,"weapon spread bonus");
			TF2Attrib_RemoveByName(client,"Projectile speed increased");
			TF2Attrib_RemoveByName(client,"Projectile range increased");
			TF2Attrib_RemoveByName(client,"sniper charge per sec");
			TF2Attrib_RemoveByName(client,"blast dmg to self increased");
			TF2Attrib_RemoveByName(client,"damage mult 1");
			TF2Attrib_RemoveByName(client,"weapon fire rate");
			TF2Attrib_RemoveByName(client,"damage penetrates reductions");
			TF2Attrib_RemoveByName(client,"major move speed bonus");
			TF2Attrib_RemoveByName(client,"self dmg push force increased");
			TF2Attrib_RemoveByName(client,"SET BONUS: chance of hunger decrease");
			TF2Attrib_RemoveByName(client,"has pipboy build interface");
			TF2Attrib_RemoveByName(client,"critical rating");

			if(current_class[client] == TFClass_DemoMan)
			{
				int secondary = TF2Util_GetPlayerLoadoutEntity(client,1);
				if(IsValidEdict(secondary))
				{
					TF2Attrib_RemoveByName(secondary,"sticky arm time penalty");
				}
			}

			float strengthPowerup = GetAttribute(client, "strength powerup");
			if(strengthPowerup == 2){
				TF2Attrib_SetByName(client,"critical rating", 200.0);
				TF2Attrib_SetByName(client,"damage penetrates reductions", 0.5);
			}

			//Powerups
			Address kingPowerup = TF2Attrib_GetByName(client, "king powerup");
			if(kingPowerup != Address_Null)
			{
				float kingPowerupValue = TF2Attrib_GetValue(kingPowerup);
				if(kingPowerupValue == 1.0){
					TF2Attrib_SetByName(client,"ubercharge rate bonus", 1.5);
					TF2Attrib_SetByName(client,"heal rate bonus", 1.5);
				}
			}

			if(TF2Attrib_HookValueFloat(0.0, "resistance_powerup", client) == 2.0){
				TF2Attrib_SetByName(client, "major move speed bonus", 1.2);
			}
			
			Address precisionPowerup = TF2Attrib_GetByName(client, "precision powerup");
			if(precisionPowerup != Address_Null)
			{
				float precisionPowerupValue = TF2Attrib_GetValue(precisionPowerup);
				if(precisionPowerupValue == 1){
					TF2Attrib_SetByName(client,"weapon spread bonus", 0.05);
					TF2Attrib_SetByName(client,"sniper charge per sec", 2.0);
					TF2Attrib_SetByName(client,"blast dmg to self increased", 0.001);
					if(current_class[client] == TFClass_DemoMan)
					{
						int secondary = TF2Util_GetPlayerLoadoutEntity(client,1);
						if(IsValidEdict(secondary))
						{
							TF2Attrib_SetByName(secondary,"sticky arm time penalty", -2.0);
						}
					}
				}

				if(precisionPowerupValue == 3){
					TF2Attrib_SetByName(client,"weapon fire rate", 4.0);
					TF2Attrib_SetByName(client,"damage penetrates reductions", 0.5);
				}
			}
			
			Address agilityPowerup = TF2Attrib_GetByName(client, "agility powerup");		
			if(agilityPowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(agilityPowerup) == 1)
				{
					TF2Attrib_SetByName(client,"major move speed bonus", 1.4);
					TF2Attrib_SetByName(client,"self dmg push force increased", 1.75);
					TF2Attrib_SetByName(client,"SET BONUS: chance of hunger decrease", 0.35);
				}

				TF2Attrib_SetByName(client,"major increased jump height", TF2Attrib_GetValue(agilityPowerup) == 1 ? 1.3 : (TF2Attrib_GetValue(agilityPowerup) == 2 ? 2.0 : 1.0));
			}

			TF2Attrib_SetByName(client, "flame ammopersec decreased", TF2Attrib_HookValueFloat(1.0, "ammo_conservation", client));
		}
		else if(IsValidEntity(slotItem) && TF2Util_IsEntityWeapon(slotItem))
		{
			Address reloadActive = TF2Attrib_GetByName(slotItem, "multiple sentries");
			if(reloadActive!=Address_Null)
				SetEntProp(slotItem, Prop_Data, "m_bReloadsSingly", TF2Attrib_GetValue(reloadActive) != 0 ? 0 : 1);

			Address explosiveBullets = TF2Attrib_GetByName(slotItem, "explosive bullets");
			if(explosiveBullets!=Address_Null)
				TF2Attrib_SetFromStringValue(slotItem, "explosion particle", "ExplosionCore_sapperdestroyed");

			Address flameSize = TF2Attrib_GetByName(slotItem, "flame size bonus");
			if(flameSize!=Address_Null)
				TF2Attrib_SetByName(slotItem, "mult_end_flame_size", TF2Attrib_GetValue(flameSize));

			float fireRateMod = TF2Attrib_HookValueFloat(1.0, "attack_speed_upgrade", slotItem);
			float convFireRateToDamage = TF2Attrib_HookValueFloat(0.0, "convert_firerate_to_damage", slotItem);
			float damageModifier = 1.0;
			if(convFireRateToDamage != 0.0)
			{
				//Sadly yeah, this old fuckass way of dealing it seems to be the best way right now.
				Address firerateActive2 = TF2Attrib_GetByName(slotItem, "fire rate bonus HIDDEN");
				Address firerateActive3 = TF2Attrib_GetByName(slotItem, "fire rate penalty HIDDEN");
				Address firerateActive4 = TF2Attrib_GetByName(slotItem, "mult_item_meter_charge_rate");
				if(fireRateMod != 1.0)
				{
					damageModifier *= fireRateMod
					TF2Attrib_SetByName(slotItem, "fire rate bonus", 1.0);
				}
				if(firerateActive2 != Address_Null)
				{
					damageModifier /= TF2Attrib_GetValue(firerateActive2);
					TF2Attrib_SetByName(slotItem, "fire rate bonus HIDDEN", 1.0);
				}
				if(firerateActive3 != Address_Null)
				{
					damageModifier /= TF2Attrib_GetValue(firerateActive3);
					TF2Attrib_SetByName(slotItem, "fire rate penalty HIDDEN", 1.0);
				}
				if(firerateActive4 != Address_Null)
				{
					damageModifier /= TF2Attrib_GetValue(firerateActive4);
					TF2Attrib_SetByName(slotItem, "mult_item_meter_charge_rate", 1.0);
				}
				//If their weapon doesn't have a clip, reload rate also affects fire rate.
				if(TF2Util_GetWeaponMaxClip(slotItem) == -1)
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
			}
			else
			{
				TF2Attrib_SetByName(slotItem,"fire rate bonus", 1.0/fireRateMod);
				if(TF2Util_IsEntityWeapon(slotItem) && TF2Util_GetWeaponSlot(slotItem) == TFWeaponSlot_Melee)
					TF2Attrib_SetByName(slotItem,"mult smack time", 1.0/fireRateMod);
			}
			TF2Attrib_SetByName(slotItem,"damage mult 16", damageModifier);
		}

		for(int i = 0;i < NB_SLOTS_UED; i++) {
			int weapon = TF2Util_GetPlayerLoadoutEntity(client, i);
			if(i == 5 && IsValidEntity(EntRefToEntIndex(UniqueWeaponRef[client]))) {
				weapon = EntRefToEntIndex(UniqueWeaponRef[client]);
			}
			
			if(!IsValidWeapon(weapon))
				continue;

			float replaceMult = 1.0;

			TF2Attrib_RemoveByName(weapon, "spread penalty");
			// Aimless powerup reverses spread bonus
			if(TF2Attrib_HookValueFloat(0.0, "precision_powerup", weapon) == 2){
				float spreadBonus = GetAttribute(weapon, "weapon spread bonus", 1.0);
				TF2Attrib_SetByName(weapon,"spread penalty", 1/(spreadBonus*spreadBonus));
				replaceMult *= 1+3.0*(1-spreadBonus);
			}

			TF2Attrib_SetByName(weapon, "projectile spread multiplier", TF2Attrib_HookValueFloat(1.0, "mult_spread_scale", weapon));
			TF2Attrib_SetByName(weapon,"damage mult 15", replaceMult);
		}

		if(IsValidEntity(uniqueWeaponID)) {
			TF2Attrib_SetByName(uniqueWeaponID, "projectile spread multiplier", TF2Attrib_HookValueFloat(1.0, "mult_spread_scale", uniqueWeaponID));
		}
		UpdatePlayerMaxHealth(client);
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
}

public Action:GiveBotUpgrades(Handle timer, any:userid) 
{
	int client = GetClientOfUserId(userid);
	if(DisableBotUpgrades != 1 && IsValidClient3(client) && IsPlayerAlive(client))
	{
		int primary = TF2Util_GetPlayerLoadoutEntity(client,0);
		int secondary = TF2Util_GetPlayerLoadoutEntity(client,1);
		int melee = TF2Util_GetPlayerLoadoutEntity(client,2);
		if(TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			melee = GetPlayerWeaponSlot(client,2);
		}
		
		if(!IsValidEdict(primary))
			primary = GetPlayerWeaponSlot(client,0);
		if(!IsValidEdict(secondary))
			secondary = GetPlayerWeaponSlot(client,1);
		if(!IsValidEdict(melee))
			melee = GetPlayerWeaponSlot(client,2);
		
		if(!IsValidEdict(primary) || !IsValidEdict(secondary) || !IsValidEdict(melee))
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
		float drMulti = 1.0;
		//TF2Attrib_SetByName(client,"rage giving scale",(500.0/(additionalstartmoney+StartMoney)) / OverAllMultiplier);
		if((additionalstartmoney+StartMoney) >= 500000)
		{
			TF2Attrib_SetByName(client,"damage bonus HIDDEN",(2.0));
			drMulti = 2.0;
		}
		if((additionalstartmoney+StartMoney) >= 1500000)
		{
			TF2Attrib_SetByName(client,"damage bonus HIDDEN",(3.0));
			drMulti = 3.0;
		}
		if((additionalstartmoney+StartMoney) <= 750000)
		{
			TF2Attrib_SetByName(client,"dmg taken divided",Pow((additionalstartmoney+StartMoney) / 7600.0 * OverAllMultiplier, 1.6) * drMulti);
			TF2Attrib_SetByName(client,"damage force increase",1/(additionalstartmoney+StartMoney)/9000.0);
		}
		if((additionalstartmoney+StartMoney) > 750000)
		{
			TF2Attrib_SetByName(client,"dmg taken divided",Pow((additionalstartmoney+StartMoney) / 7400.0 * OverAllMultiplier, 1.78) * drMulti);
			TF2Attrib_SetByName(client,"damage force increase",1/(additionalstartmoney+StartMoney)/6000.0);
		}
		if((additionalstartmoney+StartMoney) >= 1000000){
			TF2Attrib_SetByName(client,"damage mult 2",1+((additionalstartmoney+StartMoney)/16000.0)*OverAllMultiplier);
			TF2Attrib_SetByName(client,"damage mult 1",1+((additionalstartmoney+StartMoney)/20000.0)*OverAllMultiplier);
		}
		else{
			TF2Attrib_SetByName(client,"damage mult 2",1+((additionalstartmoney+StartMoney)/15000.0)*OverAllMultiplier);
			TF2Attrib_SetByName(client,"damage mult 1",1+((additionalstartmoney+StartMoney)/18000.0)*OverAllMultiplier);
		}
		for(i=0;i<2;++i)
		{
			int weap = TF2Util_GetPlayerLoadoutEntity(client,i);
			if(!IsValidWeapon(weap))
				continue;

			if (current_class[client] != TFClass_Heavy && current_class[client] != TFClass_Pyro && current_class[client] != TFClass_Sniper )
			{
				TF2Attrib_SetByName(weap,"faster reload rate",(9000.0/(additionalstartmoney+StartMoney)));
			}
		}
		
		TF2Attrib_SetByName(client,"maxammo primary increased",1+((additionalstartmoney+StartMoney)/5000.0)*OverAllMultiplier);
		TF2Attrib_SetByName(client,"maxammo secondary increased",1+((additionalstartmoney+StartMoney)/5000.0)*OverAllMultiplier);
		TF2Attrib_SetByName(client,"ammo regen", 1.0);
		TF2Attrib_SetByName(client,"increased air control", 3.0);
		TF2Attrib_SetByName(melee,"melee range multiplier", 50.0);
		TF2Attrib_SetByName(melee,"fire rate penalty HIDDEN", 0.75);
		TF2Attrib_SetByName(client,"move speed bonus", 1.5);

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
				for(i=0;i<3;++i)
				{
					int weap = TF2Util_GetPlayerLoadoutEntity(client,i);
					if(!IsValidWeapon(weap))
						continue;
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
				for(i=0;i<3;++i)
				{
					int weap = TF2Util_GetPlayerLoadoutEntity(client,i);
					if(!IsValidWeapon(weap))
						continue;

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
				for(i=0;i<3;++i)
				{
					int weap = TF2Util_GetPlayerLoadoutEntity(client,i);
					if(!IsValidWeapon(weap))
						continue;
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
				for(i=0;i<3;++i)
				{
					int weap = TF2Util_GetPlayerLoadoutEntity(client,i);
					if(!IsValidWeapon(weap))
						continue;
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
				for(i=0;i<3;++i)
				{
					int weap = TF2Util_GetPlayerLoadoutEntity(client,i);
					if(!IsValidWeapon(weap))
						continue;
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
				for(i=0;i<3;++i)
				{
					int weap = TF2Util_GetPlayerLoadoutEntity(client,i);
					if(!IsValidWeapon(weap))
						continue;
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
				TF2Attrib_SetByName(client,"clip size bonus",((additionalstartmoney+StartMoney)/11000.0)*OverAllMultiplier);
				if((additionalstartmoney+StartMoney) <= 480000/OverAllMultiplier)
				{
					TF2Attrib_SetByName(client,"damage bonus",1+(((additionalstartmoney+StartMoney)/160000.0)*OverAllMultiplier));
				}
				else
				{
					TF2Attrib_SetByName(client,"damage bonus", 4.0);
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
void DoSapperEffects(int client){
	float victimPos[3];
	GetClientAbsOrigin(client, victimPos);

	int inflictor = TF2Util_GetPlayerConditionProvider(client, TFCond_Sapped);
	if(!IsValidClient(inflictor))
		return;

	int sapper = TF2Util_GetPlayerLoadoutEntity(inflictor,4);
	if(!IsValidWeapon(sapper))
		return;

	float magnitude = GetAttribute(sapper, "sapper pulls enemies", 0.0);
	if(magnitude){
		for(int i = 1; i <= MaxClients; ++i){
			if(!IsValidClient3(i) || !IsPlayerAlive(i))
				continue;

			if(IsOnDifferentTeams(client,i))
				continue;

			float teammatePos[3];
			GetClientAbsOrigin(i, teammatePos);
			if(GetVectorDistance(teammatePos, victimPos, true) > magnitude*magnitude*2.0)
				continue;
			
			PushEntity(i, client, -1.0 * magnitude);
		}
	}
}
ExplosiveArrow(entity)
{
	entity = EntRefToEntIndex(entity);

	if(!IsValidEdict(entity))
		return;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return;

	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient(owner))
		return;

	int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
	if(!IsValidWeapon(CWeapon))
		return;

	if(!HasEntProp(entity, Prop_Send, "m_bArrowAlight"))
		return;

	Address ignitionChance = TF2Attrib_GetByName(CWeapon, "Wrench index");
	if(ignitionChance != Address_Null)
		if(TF2Attrib_GetValue(ignitionChance) >= GetRandomFloat(0.0, 1.0))
			SetEntProp(entity,Prop_Send, "m_bArrowAlight", 1);

	if(GetEntProp(entity, Prop_Send, "m_bArrowAlight") == 1)
	{
		Address ignitionExplosion = TF2Attrib_GetByName(CWeapon, "damage applies to sappers");
		if(ignitionExplosion != Address_Null && TF2Attrib_GetValue(ignitionExplosion) > 0.0)
		{
			jarateWeapon[entity] = EntIndexToEntRef(CWeapon)
			SDKHook(entity, SDKHook_StartTouchPost, IgnitionArrowCollision);
		}

		if(GetAttribute(CWeapon, "weapon ability id", 0.0) == 2)
		{
			jarateWeapon[entity] = EntIndexToEntRef(CWeapon)
			SDKHook(entity, SDKHook_StartTouchPost, ExplosiveArrowCollision);
		}
	}
}

StunShotFunc(client)
{
	int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.6);
	CreateTimer(0.5, removeBulletsPerShot, client);
}
meteorCollisionCheck(int entity){
	entity = EntRefToEntIndex(entity);

	if(!IsValidEdict(entity))
		return;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	if(!IsValidClient(owner))
		return;

	int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
	if(!IsValidWeapon(CWeapon))
		return;

	int iItemDefinitionIndex = GetEntProp(CWeapon, Prop_Send, "m_iItemDefinitionIndex");
	if(iItemDefinitionIndex == 595){
		SDKHook(entity, SDKHook_StartTouchPost, meteorCollision);
		jarateWeapon[entity] = CWeapon;
	}
	
}
public BoomerangThink(entity) 
{ 
	if(IsValidEntity(entity) && GetGameTime() - entitySpawnTime[entity] > 0.4)
	{
		float ProjAngle[3],ProjVelocity[3],vBuffer[3],impulse[3],speed;
		GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", ProjVelocity);
		speed = GetVectorLength(ProjVelocity)
		GetVectorAngles(ProjVelocity, ProjAngle);
		ProjAngle[0] -= 180.0;
		GetAngleVectors(ProjAngle, vBuffer, NULL_VECTOR, NULL_VECTOR)
		ProjVelocity[0] = vBuffer[0] * speed;
		ProjVelocity[1] = vBuffer[1] * speed;
		ProjVelocity[2] = vBuffer[2] * speed;

		GetCleaverAngularImpulse(impulse);
		Phys_SetVelocity(entity, ProjVelocity, impulse, true);

		SetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", ProjVelocity);

		isProjectileBoomerang[entity] = false;
	}
}
checkRadiation(victim,attacker)
{
	if(RadiationBuildup[victim] >= RadiationMaximum[victim])
	{
		RadiationBuildup[victim] = 0.0;
		Buff radiation;
		radiation.init("Radiation", "", Buff_Radiation, 1, attacker, 12.0);
		Buff critMark;
		critMark.init("Marked for Crits", "All hits taken are critical", Buff_CritMarkedForDeath, 1, attacker, 12.0);
		radiation.multiplicativeDamageTaken = 1.5;
		insertBuff(victim, radiation);
		insertBuff(victim, critMark);
		
		float particleOffset[3] = {0.0,0.0,10.0};
		CreateParticle(victim, "utaunt_electricity_cloud_electricity_WY", true, _, 12.0, particleOffset);
		CreateParticle(victim, "merasmus_blood", true, _, 4.0, particleOffset);
	}
}
checkFreeze(int victim,int attacker)
{
	float clientpos[3];
	GetClientAbsOrigin(victim, clientpos);
	while (FreezeBuildup[victim] >= 100.0)
	{
		FreezeBuildup[victim] -= 100.0;
		EmitSoundToAll(SOUND_FREEZE, _, victim, SNDLEVEL_RAIDSIREN, _, 1.0, _,_,clientpos);

		Buff frozen;
		frozen.init("Frozen", "", Buff_Frozen, victim, attacker, 6.0);
		insertBuff(victim, frozen);

		TF2_AddCondition(victim, TFCond_FreezeInput, 6.0, attacker);
		SDKHooks_TakeDamage(victim, attacker, attacker, GetClientHealth(victim)*0.2, DMG_PREVENT_PHYSICS_FORCE|DMG_IGNOREHOOK|DMG_PIERCING);
		SetEntityRenderColor(victim, 0, 128, 255, 80);
		SetEntityMoveType(victim, MOVETYPE_NONE);
	}
}
checkBleed(int victim,int attacker, int weapon = -1, float overrideDamage = 0.0){
	float bleedBonus = 1.0;
	if(TF2Attrib_HookValueFloat(0.0, "vampire_powerup", attacker) == 1)
		bleedBonus += 0.6;

	float damage = 100.0*bleedBonus;
	if(overrideDamage != 0.0){
		damage = overrideDamage;
	}
	if(IsValidEntity(weapon) && TF2Util_IsEntityWeapon(weapon)){
		damage *= TF2_GetDamageModifiers(attacker, weapon);
	}
	float damagePosition[3];
	GetEntPropVector(victim, Prop_Data, "m_vecOrigin", damagePosition);
	damagePosition[2] += 30.0;

	while(BleedBuildup[victim] >= BleedMaximum[victim])
	{
		BleedBuildup[victim] -= BleedMaximum[victim];
		SDKHooks_TakeDamage(victim, attacker, attacker, damage, DMG_PREVENT_PHYSICS_FORCE|DMG_IGNOREHOOK,_,_,_,false);
		CreateParticleEx(victim, "env_sawblood", 1, 0, damagePosition, 2.0);
	}
}
monoculusBonus(entity) 
{
	entity = EntRefToEntIndex(entity);
    if(IsValidEdict(entity)) 
    { 
		int monoculus = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidEdict(monoculus))
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
				if(IsValidEdict(CWeapon))
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
	if(IsValidEdict(entity))
	{
		if(HasEntProp(entity,Prop_Send,"m_hBuilder"))
		{
			int owner = GetEntPropEnt(entity,Prop_Send,"m_hBuilder" );
			if(IsValidClient3(owner))
			{
				int melee = (GetPlayerWeaponSlot(owner,2));
				if(IsValidEdict(melee))
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
wrenchBonus(DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	int obj = pack.ReadCell();

	if(!IsValidEdict(entity))
		{delete pack;return;}
	
	if(!HasEntProp(entity,Prop_Send,"m_hBuilder"))
		{delete pack; return;}

	int owner = GetEntPropEnt(entity,Prop_Send,"m_hBuilder" );
	if(!IsValidClient3(owner))
		{delete pack; return;}

	int melee = TF2Util_GetPlayerLoadoutEntity(owner,2);
	if(IsValidEdict(melee))
	{
		int weaponIndex = GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex");
		switch(weaponIndex)
		{
			case 329:{
				SDKCall(g_SDKFastBuild, entity, true);
				RequestFrame(setNoMetal, owner);
			}
			case 142:{
				if(obj == 2){//Sentry
					ThrowBuilding(EntIndexToEntRef(entity));
				}
			}
			case 589:{
				if(obj == 1){//Teleporter
					SDKCall(g_SDKFastBuild, entity, true);
				}
			}
		}
	}
	delete pack;
}
setNoMetal(int client){
	SetEntProp(client, Prop_Data, "m_iAmmo", 0, 4, 3);
}
public bool applyArcaneRestrictions(int client, int attuneSlot)
{
	float focusCost = arcaneMap[AttunedSpells[client][attuneSlot]-1].baseCost / ArcanePower[client];
	float cooldown = arcaneMap[AttunedSpells[client][attuneSlot]-1].cooldown * TF2Attrib_HookValueFloat(1.0, "arcane_cooldown_rate", client) / SquareRoot(ArcanePower[client]);

	if(SpellCooldowns[client][AttunedSpells[client][attuneSlot]-1] > GetGameTime())
		return true;

	if(fl_CurrentFocus[client] < focusCost)
	{
		SpellCooldowns[client][AttunedSpells[client][attuneSlot]-1] = GetGameTime()+0.2;
		PrintHintText(client, "Not enough focus! Requires %.2f focus.",focusCost);
		EmitSoundToClient(client, SOUND_FAIL);
		return true;
	}

	PrintHintText(client, "Used %s! -%.2f focus.",arcaneMap[AttunedSpells[client][attuneSlot]-1].name,focusCost);
	fl_CurrentFocus[client] -= focusCost;

	if(DisableCooldowns != 1)
		SpellCooldowns[client][AttunedSpells[client][attuneSlot]-1] = cooldown+GetGameTime();

	return false;
}
randomizeTankSpecialty(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEdict(entity))//In case if the tank somehow instantly despawns.
	{
		int specialtyID = GetRandomInt(0,1);
		switch(specialtyID)
		{
			case 0:
			{
				int iEntity = CreateEntityByName("obj_sentrygun");
				if(IsValidEdict(iEntity))
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
					/*if(IsValidEdict(logic))
					{
						int round = GetEntProp(logic, Prop_Send, "m_nMannVsMachineWaveCount");
						TankSentryDamageMod = Pow((waveToCurrency[round]/11000.0), DamageMod + (round * 0.03)) * 1.8 * OverallMod;
					}*/
				}
			}
			case 1:
			{
				if(!IsValidEdict(TankTeleporter))
				{
					int iEntity = CreateEntityByName("obj_teleporter");
					if(IsValidEdict(iEntity))
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
	if(IsValidEdict(entity))
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
		if(IsValidClient3(client))
		{
			int launcher = GetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher");
			if(!IsValidWeapon(launcher))
				return;

			int iItemDefinitionIndex = GetEntProp(launcher, Prop_Send, "m_iItemDefinitionIndex");
			switch(iItemDefinitionIndex)
			{
				case 222:
				{
					SetEntityModel(entity, "models/weapons/c_models/c_madmilk/c_madmilk.mdl");
					ApplyJarChanges(entity, launcher, 1);
				}
				case 1121:
				{
					SetEntityModel(entity, "models/weapons/c_models/c_breadmonster/c_breadmonster_milk.mdl");
					ApplyJarChanges(entity, launcher, 1);
				}
				case 58,1149:
				{
					SetEntityModel(entity, "models/weapons/c_models/urinejar.mdl");
					ApplyJarChanges(entity, launcher, 0);
				}
				case 1105:
				{
					SetEntityModel(entity, "models/weapons/c_models/c_breadmonster/c_breadmonster.mdl");
					ApplyJarChanges(entity, launcher, 0);
				}
				case 812,833:
				{
					SetEntityModel(entity, "models/weapons/c_models/c_sd_cleaver/c_sd_cleaver.mdl");
				}
				case 307:
				{
					SetEntityModel(entity, "models/weapons/c_models/c_caber/c_caber.mdl");
				}
			}
		}
	}
}
ApplyJarChanges(entity, CWeapon, type){
	SDKHook(entity, SDKHook_StartTouch, OnStartTouchJars);
	gravChanges[entity] = true;
	jarateType[entity] = type;
	jarateWeapon[entity] = EntIndexToEntRef(CWeapon);
	SetEntityGravity(entity, 1.0);

	float vel[3];
	GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", vel);
	ScaleVector(vel, 1.3);
	ScaleVector(vel, TF2Attrib_HookValueFloat(1.0, "mult_projectile_speed", CWeapon));
	vel[2] += 100.0;
	TeleportEntity(entity, _, _, vel);
}
SentryDelay(entity) 
{
	entity = EntRefToEntIndex(entity);
    if(IsValidEdict(entity)) 
    {
		int building = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		//PrintToChatAll("1");
		if(!IsValidClient3(building) && IsValidEdict(building) && HasEntProp(building,Prop_Send,"m_hBuilder"))
		{
			//PrintToChatAll("2");
			int owner = GetEntPropEnt(building,Prop_Send,"m_hBuilder" );
			if(IsValidClient3(owner))
			{
				//PrintToChatAll("3");
				int melee = TF2Util_GetPlayerLoadoutEntity(owner,2);
				if(IsValidEdict(melee))
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

public int getClientParticleStatus(int array[MAXPLAYERS+1], int client){
	bool particleEnabler = false;
	if(AreClientCookiesCached(client)){
		char particleEnabled[32];
		Cookie thirdperson = FindClientCookie("tp_cookie");
		if (thirdperson != null) {
			GetClientCookie(client, thirdperson, particleEnabled, sizeof(particleEnabled));
			float menuValue = StringToFloat(particleEnabled);
			if(menuValue != 0){
				particleEnabler = true;
			}
		}
	}
	int numClients;
	for(int i=1;i<=MaxClients;++i){
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
public OnAimlessThink(entity){
	if(!IsValidEdict(entity))
		return;
		
	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));

	float ProjAngle[3], ProjVector[3], ProjVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle ); 
	ProjAngle[1] += GetRandomFloat(-5.0, 5.0);

	GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", ProjVelocity ); 
	if (GetVectorLength(ProjVelocity ) < 10.0 )
		GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVelocity ); 

	GetAngleVectors(ProjAngle, ProjVector, NULL_VECTOR, NULL_VECTOR);

	ScaleVector(ProjVector, GetVectorLength(ProjVelocity));

	TeleportEntity(entity, NULL_VECTOR, ProjAngle, ProjVector ); 
}

public onProjectileSpawned(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEdict(entity)){
		if(GetEntityMoveType(entity) != MOVETYPE_VPHYSICS){
			SetEntityCollisionGroup(entity, 27);
		}
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entitySpawnPositions[entity]);

		int owner = getOwner(entity);
		if(!IsValidClient3(owner))
			return;

		int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
		if(!IsValidWeapon(CWeapon))
			return;

		int launcher = GetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher");
		if(!IsValidWeapon(launcher))
			return;

		if(TF2Attrib_HookValueInt(0, "sunburst_projectile", CWeapon)){
			CreateParticle(entity, "raygun_projectile_red_crit", true, _, 10.0, _, true);
			CreateParticle(entity, "raygun_projectile_red", true, _, 10.0, _, true);
		}
		if(TF2Attrib_HookValueInt(0, "highlight_projectile", CWeapon)){
			CreateParticle(entity, "raygun_projectile_blue_crit", true, _, 10.0, _, true);
			CreateParticle(entity, "raygun_projectile_blue", true, _, 10.0, _, true);
		}
		
		projectileMaxBounces[entity] = TF2Attrib_HookValueInt(0, "projectile_bounce_count", CWeapon);
		projectileExplosionBounceDamage[entity] = TF2_GetDamageModifiers(owner, CWeapon)*TF2Attrib_HookValueFloat(0.0, "projectile_bounce_explosion", CWeapon);
		projectileExplosionBounceRadius[entity] = 120.0*TF2Attrib_HookValueFloat(1.0, "mult_explosion_radius", CWeapon);

		float constantTime = TF2Attrib_HookValueFloat(0.0, "constant_time_projectile", CWeapon);
		if(constantTime){
			float vAngles[3],vPosition[3],vBuffer[3],vDest[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPosition);
			GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);

			Handle trace = TR_TraceRayFilterEx(vPosition, vAngles, MASK_SHOT, RayType_Infinite, TraceWorldOnly, entity);

			if(!TR_DidHit(trace)){
				delete trace;
				return;
			}

			TR_GetEndPosition(vDest, trace);

			GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
			float ratio = 1.0/constantTime*GetVectorDistance(vPosition,vDest);
			ScaleVector(vBuffer, ratio);

			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vBuffer);
			delete trace;
		}

		float splitDistance = TF2Attrib_HookValueFloat(0.0, "rockets_split_while_travelling", launcher);
		if(splitDistance && rocketSplitCount[entity] == 0){
			float currentVelocity[3];
			GetEntPropVector(entity, Prop_Data, "m_vecVelocity", currentVelocity);
			CreateTimer(splitDistance/GetVectorLength(currentVelocity), Timer_RocketSplit, EntIndexToEntRef(entity));
		}

		float crit_after_time = TF2Attrib_HookValueFloat(0.0, "projectile_critical_after_lifetime", launcher);
		if(crit_after_time > 0.0){
			CreateTimer(crit_after_time, Timer_ProjectileCrit, EntIndexToEntRef(entity));
		}
	}
}

void ProjParenting(int ref){
	int entity = EntRefToEntIndex(ref);
	if(IsValidEntity(entity)){
		int client = getOwner(entity);
		if(!IsValidClient3(client))
			return;

		int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!IsValidWeapon(CWeapon))
			return;

		if(!isProjectileParented[entity]){
			if(TF2Attrib_HookValueInt(0, "electric_orb_child", CWeapon)){
				int iEntity = CreateEntityByName("tf_projectile_mechanicalarmorb");
				if (IsValidEdict(iEntity)) 
				{
					float fwd[3], fOrigin[3], fAngles[3];
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
					GetClientEyePosition(client, fOrigin);
					GetClientEyeAngles(client, fAngles);
					GetAngleVectors(fAngles, fwd, NULL_VECTOR, NULL_VECTOR);
					ScaleVector(fwd, 30.0);
					AddVectors(fOrigin, fwd, fOrigin);
					DispatchSpawn(iEntity);
					TeleportEntity(iEntity, fOrigin, fAngles);
					SetVariantString("!activator");
					AcceptEntityInput(iEntity, "SetParent", entity);
					SetEntityMoveType(iEntity, MOVETYPE_NOCLIP)
					
					SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0004);
					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", CWeapon);
					SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", client);
					CreateTimer(0.1, ElectricBallThink, EntIndexToEntRef(iEntity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					EmitSoundToAll(SOUND_COWMANGLER_SHOT, 0, client, SNDLEVEL_NORMAL, _, 1.0, _, _, fOrigin);
					isProjectileParented[iEntity] = true;
				}
			}
		}
	}
}

public OnFireballThink(entity)
{
	if(IsValidEdict(entity))
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
		if(GetVectorDistance(entitySpawnPositions[entity], origin, true) > distance*distance)
			{RemoveEntity(entity);}
	}
}
public OnEntityHomingThink(entity) 
{ 
	if(!IsValidEdict(entity))
		return;

	if(!HasEntProp(entity,Prop_Send,"m_vInitialVelocity"))
		return;

	if(GetEntityMoveType(entity) == MOVETYPE_NONE)
		return;

	if(HasEntProp(entity,Prop_Send,"m_bTouched") && GetEntProp(entity,Prop_Send,"m_bTouched"))
		return;

	int owner = getOwner(entity);
	if(!IsValidClient3(owner) && IsValidEdict(owner) && HasEntProp(owner,Prop_Send,"m_hBuilder"))
		owner = GetEntPropEnt(owner,Prop_Send,"m_hBuilder" );

	if (!IsValidClient3(owner))
		return;

	float distance = 9999999.0;
	int Target = GetClosestTarget(entity, owner, _, distance);

	if(!IsValidClient3(Target) || distance > homingRadius[entity]*homingRadius[entity])
		return;

	if(homingTickRate[entity] == 0 || homingTicks[entity] % homingTickRate[entity] == 0)
	{
		float ProjLocation[3], ProjVector[3], NewSpeed, ProjAngle[3], AimVector[3], InitialSpeed[3], TargetPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", InitialSpeed ); 
		if (GetVectorLength(InitialSpeed ) < 10.0 ) 
			GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", InitialSpeed ); 
		NewSpeed = GetVectorLength(InitialSpeed );
		
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", ProjLocation ); 
		switch(homingAimStyle[entity])
		{
			case HomingStyle_Headshot:
			{
				GetClientEyePosition(Target, TargetPos ); 
			}
			default:
			{
				GetClientAbsOrigin(Target, TargetPos ); 
				TargetPos[2] += 35.0;
			}
		}
		MakeVectorFromPoints(ProjLocation, TargetPos, AimVector ); 
		
		switch(homingAimStyle[entity])
		{
			case HomingStyle_Fast:
			{
				SubtractVectors(TargetPos, ProjLocation, ProjVector ); //100% HOME
				if(NewSpeed > 1000)
					NewSpeed = 1000.0;
			}
			default:
			{
				GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector ); //50% HOME
			}
		}
		AddVectors(ProjVector, AimVector, ProjVector ); 
		NormalizeVector(ProjVector, ProjVector ); 
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle ); 
		GetVectorAngles(ProjVector, ProjAngle ); 
		ScaleVector(ProjVector, NewSpeed );
		TeleportEntity(entity, NULL_VECTOR, ProjAngle, ProjVector );
	}
	homingTicks[entity]++;
}

PrecisionHoming(entity) 
{
	entity = EntRefToEntIndex(entity);
    if(IsValidEdict(entity)) 
    {
		int client = getOwner(entity);
		if(!IsValidClient3(client) && IsValidEntity(client) && HasEntProp(client,Prop_Send,"m_hBuilder")){
			client = GetEntPropEnt(client, Prop_Send, "m_hBuilder");
		}
		if(IsValidClient3(client))
		{
			float addedRadius = 0.0;
			int launcher = GetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher");
			if(IsValidWeapon(launcher)) {
				addedRadius += GetAttribute(launcher, "projectile homing radius", 0.0);
			}
			float precision = TF2Attrib_HookValueFloat(0.0, "precision_powerup", client);

			if(addedRadius > 0){
				homingRadius[entity] = addedRadius;
				homingAimStyle[entity] = HomingStyle_Fast;
			}
			if(precision == 1){
				homingRadius[entity] += 200.0;
				homingAimStyle[entity] = HomingStyle_Fast;
			}
			else if(precision == 2)
				if(!Phys_IsPhysicsObject(entity))
					isAimlessProjectile[entity] = true;
		}
    } 
}
FragmentProperties(entity) 
{
	entity = EntRefToEntIndex(entity);
    if(IsValidEdict(entity)) 
    { 
		int client = getOwner(entity);
		if(IsValidClient3(client))
		{
			int launcher = GetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher");
			if(IsValidWeapon(launcher)) {
				projectileFragCount[entity] = RoundToNearest(TF2Attrib_HookValueFloat(0.0, "explosive_frag_count", launcher));
				projectileUniformFrag[entity] = (TF2Attrib_HookValueFloat(0.0, "explosive_fragment_is_uniform", launcher)) != 0;
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
			if(IsValidEdict(ClientWeapon))
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
			if(IsValidEdict(ClientWeapon))
			{
				//PrintToChatAll("2");
				float projgravity = GetAttribute(ClientWeapon, "cloak_consume_on_feign_death_activate", 0.0)
				+ GetAttribute(client, "cloak_consume_on_feign_death_activate", 0.0);

				char strClassname[64];
				GetEntityClassname(entity, strClassname, sizeof(strClassname) );

				if(projgravity)
				{
					//PrintToChatAll("3");
					if(GetEntityMoveType(entity) != MOVETYPE_VPHYSICS)
					{
						SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
						SetEntityGravity(entity, projgravity);
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
GivePowerupDescription(int client, char[] name, int amount){
	if(StrEqual("strength powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Dexterity Powerup {default}| {lightcyan}Grants +50%% chance to crit, +100%% crit damage, and increases conditional damage reduction penetration by +50%%.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Bruised Powerup {default}| {lightcyan}Tagged enemies will be finished off if they are below 25%% maxHP. Any single hit above 40%% victim's maxHP instantly kills.");
		}else{
			CPrintToChat(client, "{community}Strength Powerup {default}| {lightcyan}You deal 2x damage.");
		}
	}
	else if(StrEqual("resistance powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Fray Powerup {default}| {lightcyan}Every 1s or after a kill, avoid the next hit taken & grant +3s of defense and speed boost to you and nearby teammates. 1.2x movement speed.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Stronghold Powerup {default}| {lightcyan}0.5x incoming damage, middle click to enter stronghold, immobilizing you but giving crit and status immunities with 1.33x healing. Nearby teammates get the immobilizing bonus.");
		}else{
			CPrintToChat(client, "{community}Resistance Powerup {default}| {lightcyan}0.5x incoming damage. 1.5x critical block rating.");
		}
	}
	else if(StrEqual("vampire powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Leech Powerup {default}| {lightcyan}+25%% incoming healing, drains healing of enemies by 50%% if nearby. Also applies on hitting an enemy.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Bloodbound Powerup {default}| {lightcyan}+50%% lifesteal, lifesteal at maximum health instead fills Overleech, consumed to heal at 1.5x effectiveness while below 100%% HP. 0.75x incoming damage.");
		}else{
			CPrintToChat(client, "{community}Vampire Powerup {default}| {lightcyan}+85%% lifesteal, 1.6x bleed buildup damage, and 0.75x incoming damage.");
		}
	}
	else if(StrEqual("precision powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Aimless Powerup {default}| {lightcyan}Projectiles randomly sway and deal up to +300%% damage based on their distance of landing. Only projectiles that sway deal extra damage.");
			CPrintToChat(client, "{lightcyan}\"Weapon Spread Bonus\" upgrade now instead increases spread, and boosts damage by 300%% of value.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Railgun Powerup {default}| {lightcyan}All weapons have 4x slower fire rate, but 4x outgoing damage. Grants +50%% conditional damage reduction pierce.");
		}else{
			CPrintToChat(client, "{community}Precision Powerup {default}| {lightcyan}+100%% charge rate, and no spread. 1.35x outgoing damage and hitscan can headshot. Certain projectiles will home aggressively.");
		}
	}
	else if(StrEqual("regeneration powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Duplication Powerup {default}| {lightcyan}Shift middle click to double current HP (2x overheal max, 10s cd). All weapons have infinite clip.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Redistribution Powerup {default}| {lightcyan}-8%% maxHPR, but health drained goes into a health pool. Dealing damage heals you and nearby teammates using the health pool. 1.6x all healing.");
		}else{
			CPrintToChat(client, "{community}Regeneration Powerup {default}| {lightcyan}0.75x incoming damage, +10%% max HPR. 100%% ammo regeneration.");
		}
	}
	else if(StrEqual("revenge powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Berserk Powerup {default}| {lightcyan}Revenge instead becomes passive that drains by -7%%/s. Up to 1.5x healing effectiveness when meter is at 100%%. Effects are scaled to %%.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Ruthless Powerup {default}| {lightcyan}While constantly firing, your Berserk meter increases gradually and drains up to -25%%/s max health based on meter.");
		}else{
			CPrintToChat(client, "{community}Revenge Powerup {default}| {lightcyan}66%% of damage taken is filled to revenge meter. 0.8x incoming damage. On activation: 1.5x damage dealt, 100%% crits, +33%% fire rate, and 35%% defense buff.");
		}
	}
	else if(StrEqual("agility powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Quaker Powerup {default}| {lightcyan}Weighdown is automatically activated after jumping. Stomp damage is splashed to 2 other targets. 2x jump height. All damage dealt is increased by +0.1%% times downward velocity.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Warp Powerup {default}| {lightcyan}Shift middle-click will teleport you to crosshair, consuming 10%% focus. Deals 600 base DPS to all enemies through path of teleport. After a teleport, you are given 2s of speed boost, 35%% damage reduction, and minicrits.");
		}else{
			CPrintToChat(client, "{community}Agility Powerup {default}| {lightcyan}+50%% reload & fire rate. double jumps, speed boost, 1.4x speed, 1.3x jump height, 1.75x self push force, immunity to crowd control effects, and 35%% dodge chance.");
		}
	}
	else if(StrEqual("knockout powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Tainted Blade Powerup {default}| {lightcyan}Incoming damage is multiplied by 0.66x. Melee applies amplified debuffs: 3x buildup rate, DoTs deal 5x dmg.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Assassin Powerup {default}| {lightcyan}When a victim has not taken damage from you, melee damage crits and deals 4x damage.");
		}else{
			CPrintToChat(client, "{community}Knockout Powerup {default}| {lightcyan}1.75x outgoing melee damage. 0.8x incoming damage. Melee damage causes concussion buildup, which stuns and marks for death after 57%% of their health has been damaged.");
		}
	}
	else if(StrEqual("king powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Tag-Team Powerup {default}| {lightcyan}Crouch+Mouse3 to link yourself to a teammate:\n Giving both of you 1.2x damage. Your healing is shared to your patient and attacking an enemy makes the patient deal 1.75x vs that victim.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Champion Powerup {default}| {lightcyan}Hitting enemies makes them deal 0.66x damage against targets that aren't you, and take an additional +20 base DPS.\n0.66x incoming damage.");
		}else{
			CPrintToChat(client, "{community}King Powerup {default}| {lightcyan}+33%% reload and fire rate for nearby teammates and you. 0.8x incoming damage. 1.5x uber and heal rate. +20%% damage dealt.");
		}
	}
	else if(StrEqual("plague powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Decay Powerup {default}| {lightcyan}Deals 100 + 8%% victim's currentHP piercing DPS to nearby enemies. Applies 0.25x healing to victims of decay. 0.75x damage taken.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Life Link Powerup {default}| {lightcyan}Hitting an enemy will proc Life Link: Deals 30%% currentHP%% to you, but drains 35%% currentHP%% of enemy over time. At end of duration, your team is healed by damage dealt to yourself.");
		}else{
			CPrintToChat(client, "{community}Plague Powerup {default}| {lightcyan}Steals all healthpacks nearby, healing for +25%% maxHP. Enemies nearby will be plagued for 10s, weakening damage dealt by them by 0.5x. 0.75x damage taken.");
		}
	}
	else if(StrEqual("supernova powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Infernal Powerup {default}| {lightcyan}1.5x fire damage. 2.0x afterburn stack damage. All attacks ignite. Crouch+Middle-Click to detonate all of your afterburn stacks, 10s cd.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Thunderstorm Powerup {default}| {lightcyan}All damage is converted into electric damage (hit enemies recieve splash to other hit enemies). For every enemy tagged: +8%% damage.");
		}else{
			CPrintToChat(client, "{community}Supernova Powerup {default}| {lightcyan}0.8x incoming damage. If Splash Damage:\n1.8x damage.\nElse:\n1.35x damage dealt and splashes with falloff.\nDamage taken -> Supernova meter.\n On proc: Stuns nearby enemies for 6s & buildings for 10s.");
		}
	}
	else if(StrEqual("inverter powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Conductor Powerup {default}| {lightcyan}0.66x incoming damage taken. Amplifies the effects of incoming ailments (eg: jarate -> crit jarate). Attacks will apply active ailments from you to victims.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Insulator Powerup {default}| {lightcyan}Nullifies all ailments and buffs (You do not recieve any buffs or ailments, and cancel enemy buffs on hit).");
		}else{
			CPrintToChat(client, "{community}Inverter Powerup {default}| {lightcyan}0.8x incoming damage taken. Flips the effects of incoming ailments (eg: jarate -> battalion's backup)");
		}
	}
	else if(StrEqual("juggernaut powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Vitality Powerup {default}| {lightcyan}+150 base health. +100%% incoming healing.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Undying Powerup {default}| {lightcyan}Every time you are hit, heal back 12%% of your missing health over 5s. This healing is multiplied by +5%% per 10%% health the hit deals.");
		}else{
			CPrintToChat(client, "{community}Juggernaut Powerup {default}| {lightcyan}50%% of damage taken in healed back over 5s. Gain immunity against all crowd control effects. All incoming hits above 50%% of your current health are reduced by 0.66x.");
		}
	}
}
setProjGravity(entity, float gravity) 
{
    if(IsValidEdict(entity)) 
    {
		SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
		SetEntityGravity(entity, gravity);
    } 
}

stock SentryMultishot(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEdict(entity))
	{
		int inflictor = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		int client;
		if(!IsValidClient3(inflictor) && IsValidEdict(inflictor) && HasEntProp(inflictor,Prop_Send,"m_hBuilder"))
		{
			client = GetEntPropEnt(inflictor, Prop_Send, "m_hBuilder");
			if(IsValidClient3(client))
			{
				int pda = TF2Util_GetPlayerLoadoutEntity(client,5);
				if(IsValidEdict(pda))
				{
					int projCount = RoundToNearest(TF2Attrib_HookValueFloat(0.0, "sentry_rocket_proj_add", pda));
					if(projCount > 0)
					{
						Handle hPack = CreateDataPack();
						WritePackCell(hPack, EntIndexToEntRef(inflictor));
						WritePackCell(hPack, EntIndexToEntRef(client));
						WritePackCell(hPack, projCount);
						CreateTimer(0.1,ShootTwice,hPack);
					}
				}
			}
		}
	}
}
stock bool PenetrationCallTrace(int entity, int contentsMask, any data) {
	if(entity != 0 && IsValidEntity(entity) && IsValidForDamage(entity)){
		if(IsOnDifferentTeams(entity,data)){
			if(penetrationCount[entity] < 0)
				penetrationCount[entity] = 0;

			penetrationCount[entity]++;
			return false;
		}
		return false;
	}
    return true;
}
stock delayedResetVelocity(entity, float vel[3]){
	DataPack pack = new DataPack();
	pack.WriteCell(entity);
	pack.WriteFloat(vel[0]);
	pack.WriteFloat(vel[1]);
	pack.WriteFloat(vel[2]);
	RequestFrame(resetVelocity, pack);
}
stock resetVelocity(DataPack pack){
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(IsValidEntity(entity)){
		float vel[3];
		vel[0] = pack.ReadFloat();
		vel[1] = pack.ReadFloat();
		vel[2] = pack.ReadFloat();

		float impulse[3];
		GetCleaverAngularImpulse(impulse);
		Phys_SetVelocity(entity, vel, impulse, true);
	}
	delete pack;
}
stock fixPiercingVelocity(entity)
{
	entity = EntRefToEntIndex(entity)
	if(IsValidEdict(entity))
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
ResetVariables(){
	additionalstartmoney = 0.0;
	StartMoneySaved = 0.0;
	gameStage = 0;
	UpdateMaxValuesStage(gameStage)
	disableMvMCash = false;
	for(int client = 1;client<=MaxClients;client++){
		buffChange[client] = false;
		playerUpgradeMenus[client] = 0;
		playerUpgradeMenuPage[client] = 0;
		playerTweakMenus[client] = 0;
		playerTweakMenuPage[client] = 0;
		oldPlayerButtons[client] = 0;
		MadmilkInflictor[client] = 0;
		autoSentryID[client] = 0;
		globalButtons[client] = 0;
		singularBuysPerMinute[client] = 0;
		bossPhase[client] = 0;
		fanOfKnivesCount[client] = 0;
		firestormCounter[client] = 0;
		lastFlag[client] = 0;
		ShotsLeft[client] = 0;
		meleeLimiter[client] = 0;
		lightningCounter[client] = 0;
		lastKBSource[client] = 0;
		knockbackFlags[client] = 0;
		relentlessTicks[client] = 0;
		Kills[client] = 0;
		Deaths[client] = 0;
		DamageDealt[client] = 0.0;
		Healed[client] = 0.0;
		MenuTimer[client] = 0.0;
		ImpulseTimer[client] = 0.0;
		g_flLastAttackTime[client] = 0.0;
		lastMinesTime[client] = 0.0;
		weaponTrailTimer[client] = 0.0;
		disableIFMiniHud[client] = 0.0;
		fl_GlobalCoolDown[client] = 0.0;
		weaponArtCooldown[client] = 0.0;
		weaponArtParticle[client] = 0.0;
		powerupParticle[client] = 0.0;
		BotTimer[client] = 8;
		LastCharge[client] = 0.0;
		//lastDamageTaken[client] = 0.0;
		flNextSecondaryAttack[client] = 0.0;
		fl_HighestFireDamage[client] = 0.0;
		miniCritStatusVictim[client] = 0.0;
		miniCritStatusAttacker[client] = 0.0;
		baseDamage[client] = 0.0;
		remainderHealthRegeneration[client] = 0.0;
		InfernalEnchantmentDuration[client] = 0.0;
		karmicJusticeScaling[client] = 0.0;
		snowstormActive[client] = false;
		for(int buffID = 0; buffID<MAXBUFFS; buffID++){
			playerBuffs[client][buffID].clear();
		}
		for(int spellID = 0; spellID < MAX_ARCANESPELLS; spellID++) {
			SpellCooldowns[client][spellID] = 0.0;
		}
	}
}
public void CheckForGamestage(){
	bool success = true;
	while(success){
		success = false;
		if(gameStage == 0 && (StartMoney + additionalstartmoney) >= STAGEONE){
			CPrintToChatAll("{valve}Incremental Fortress {white}| You have reached the 1st stage! New powerups, upgrades, and tweaks unlocked.");
			gameStage = 1; UpdateMaxValuesStage(gameStage); success = true;
		}
		else if(gameStage == 1 && (StartMoney + additionalstartmoney) >= STAGETWO){
			CPrintToChatAll("{valve}Incremental Fortress {white}| You have reached the 2nd stage! You can now use two powerups.");
			gameStage = 2; UpdateMaxValuesStage(gameStage); success = true;
		}
		else if(gameStage == 2 && (StartMoney + additionalstartmoney) >= STAGETHREE){
			CPrintToChatAll("{valve}Incremental Fortress {white}| You have reached the 3rd stage! Nothing added (so far)");
			gameStage = 3; UpdateMaxValuesStage(gameStage); success = true;
		}
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
public bool TraceEntityFilterPlayers(int entity, int contentsMask) {
    if (0 < entity <= MaxClients)
        return false;
    return true;
}
public bool TEF_HitSelfFilterPassClients(int entity, int contentsMask, any data) {
	return entity > MaxClients && entity != data;
}
public bool TraceWorldOnly(int entity, int contentsMask) {
	return entity == 0;
}
public bool TraceEntityWarp(int entity, int contentsMask, any data) {
    if (0 < entity <= MaxClients){
		if(IsClientInGame(entity) && IsPlayerAlive(entity) && IsOnDifferentTeams(entity, data)){
			isWarpFlagged[entity] = true;
		}
		return false;
	}
    return true;
}
public bool IsPlayerInSpawn(int client){
	float pos[3]; GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos); 
	return TF2Util_IsPointInRespawnRoom(pos, client, true);
}
stock float TF2_GetWeaponclassDPS(client, weapon)
{
	if(IsValidClient3(client))
    {
		if(IsValidEdict(weapon))
		{
			float weaponDPS;
			char Classname[64];
			TF2Econ_GetItemClassName(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), Classname, sizeof(Classname));
			if(StrEqual(Classname,"tf_weapon_scattergun",false) || StrEqual(Classname,"tf_weapon_soda_popper",false) || StrEqual(Classname,"tf_weapon_pep_brawler_blaster",false) || StrEqual(Classname,"tf_weapon_shotgun",false) || 
			StrEqual(Classname,"tf_weapon_shotgun_primary",false) || StrEqual(Classname,"tf_weapon_sentry_revenge",false) || StrEqual(Classname,"tf_weapon_shotgun_building_rescue",false))
			{
				weaponDPS = 96.0;
			}
			else if(StrEqual(Classname,"tf_weapon_handgun_scout_primary",false))
			{
				weaponDPS = 133.3;
			}
			else if(StrEqual(Classname,"tf_weapon_pistol",false) || StrEqual(Classname,"tf_weapon_handgun_scout_secondary",false))
			{
				weaponDPS = 100.0;
			}
			else if(StrEqual(Classname,"tf_weapon_cleaver",false))
			{
				weaponDPS = 65.0;
			}
			else if(StrEqual(Classname,"tf_weapon_rocketlauncher",false) || StrEqual(Classname,"tf_weapon_rocketlauncher_directhit",false)
			|| StrEqual(Classname,"tf_weapon_rocketlauncher_airstrike",false) || StrEqual(Classname,"tf_weapon_particle_cannon",false))
			{
				weaponDPS = 112.5;
			}
			else if(StrEqual(Classname,"tf_weapon_raygun",false) || StrEqual(Classname,"tf_weapon_drg_pomson",false))
			{
				weaponDPS = 120.0;
			}
			else if(StrEqual(Classname,"tf_weapon_shovel",false) || StrEqual(Classname,"saxxy",false) || StrEqual(Classname,"tf_weapon_fireaxe",false) || StrEqual(Classname,"tf_weapon_slap",false) || StrEqual(Classname,"tf_weapon_sword",false) ||
			StrEqual(Classname,"tf_weapon_bottle",false) || StrEqual(Classname,"tf_weapon_stickbomb",false) || StrEqual(Classname,"tf_weapon_katana",false) || StrEqual(Classname,"tf_weapon_fists",false) || StrEqual(Classname,"tf_weapon_wrench",false) ||
			StrEqual(Classname,"tf_weapon_robot_arm",false) || StrEqual(Classname,"tf_weapon_bonesaw",false) || StrEqual(Classname,"tf_weapon_club",false) || StrEqual(Classname,"tf_weapon_breakable_sign",false))
			{
				weaponDPS = 81.0;
			}
			else if(StrEqual(Classname,"tf_weapon_bat",false) || StrEqual(Classname,"tf_weapon_bat_wood",false) || StrEqual(Classname,"tf_weapon_bat_fish",false) || StrEqual(Classname,"tf_weapon_bat_giftwrap",false))
			{
				weaponDPS = 70.0;
			}
			else if(StrEqual(Classname,"tf_weapon_knife",false))
			{
				weaponDPS = 50.0;
			}
			else if(StrEqual(Classname,"tf_weapon_flamethrower",false))
			{
				weaponDPS = 90.0;
			}
			else if(StrEqual(Classname,"tf_weapon_rocketlauncher_fireball",false))
			{
				weaponDPS = 125.0;
			}
			else if(StrEqual(Classname,"tf_weapon_jar_gas",false))
			{
				weaponDPS = 6.0;
			}
			else if(StrEqual(Classname,"tf_weapon_jar",false) || StrEqual(Classname,"tf_weapon_jar_milk",false))
			{
				weaponDPS = 37.5;
			}
			else if(StrEqual(Classname,"tf_weapon_flaregun",false) || StrEqual(Classname,"tf_weapon_flaregun_revenge",false))
			{
				weaponDPS = 15.0;
			}
			else if(StrEqual(Classname,"tf_weapon_grenadelauncher",false) || StrEqual(Classname,"tf_weapon_cannon",false))
			{
				weaponDPS = 166.6;
			}
			else if(StrEqual(Classname,"tf_weapon_pipebomblauncher",false))
			{
				weaponDPS = 200.0;
			}
			else if(StrEqual(Classname,"tf_weapon_minigun",false))
			{
				weaponDPS = 360.0;
			}
			else if(StrEqual(Classname,"tf_weapon_syringegun_medic",false) || StrEqual(Classname,"tf_weapon_syringegun",false))
			{
				weaponDPS = 100.0;
			}
			else if(StrEqual(Classname,"tf_weapon_compound_bow",false))
			{
				weaponDPS = 150.0;
			}
			else if(StrEqual(Classname,"tf_weapon_crossbow",false))
			{
				weaponDPS = 47.0;
			}
			else if(StrEqual(Classname,"tf_weapon_sniperrifle",false) || StrEqual(Classname,"tf_weapon_sniperrifle_decap",false) || StrEqual(Classname,"tf_weapon_sniperrifle_classic",false))
			{
				weaponDPS = 33.3;
			}
			else if(StrEqual(Classname,"tf_weapon_smg",false) || StrEqual(Classname,"tf_weapon_charged_smg",false))
			{
				weaponDPS = 80.0;
			}
			else if(StrEqual(Classname,"tf_weapon_revolver",false))
			{
				weaponDPS = 80.0;
			}
			else if(StrEqual(Classname,"tf_weapon_mechanical_arm",false))
			{
				weaponDPS = 58.33;
			}
			else
			{
				weaponDPS = 0.0;
			}
			switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")){
				case 232:{
					weaponDPS = 448.0;
				}
				case 312:{
					weaponDPS = 700.0;
				}
			}
			return weaponDPS;
		}
	}
	return 1.0;
}
stock float TF2_GetFireRate(client, weapon, float efficiency = 1.0)
{
	if(IsValidClient3(client))
    {
		if(IsValidEdict(weapon))
		{
			if(HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
			{
				float aps;
				char Classname[64];
				TF2Econ_GetItemClassName(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), Classname, sizeof(Classname));
				bool success = weaponFireRateMap.GetValue(Classname, aps);
				if(!success)
					aps = 1.0;
				
				if(StrEqual(Classname, "tf_weapon_pda_engineer_build")){
					aps /= TF2Attrib_HookValueFloat(1.0, "mult_sentry_firerate", weapon);
				}
				else{
					aps /= TF2Attrib_HookValueFloat(1.0, "mult_postfiredelay", weapon);
				}
				Address apsMult5 = TF2Attrib_GetByName(weapon, "halloween fire rate bonus");
				Address apsMult6 = TF2Attrib_GetByName(weapon, "mult_item_meter_charge_rate");
				Address apsMod = TF2Attrib_GetByName(weapon, "energy weapon penetration");
				//If their weapon doesn't have a clip, reload rate also affects fire rate.
				if(TF2Util_GetWeaponMaxClip(weapon) == -1)
				{
					Address ModClip = TF2Attrib_GetByName(weapon, "mod max primary clip override");
					if(ModClip == Address_Null)
					{
						Address apsMult12 = TF2Attrib_GetByName(weapon, "faster reload rate");
						Address apsMult13 = TF2Attrib_GetByName(weapon, "Reload time increased");
						Address apsMult14 = TF2Attrib_GetByName(weapon, "Reload time decreased");
						Address apsMult15 = TF2Attrib_GetByName(weapon, "reload time increased hidden");
						
						if(apsMult12 != Address_Null) 
							aps /= TF2Attrib_GetValue(apsMult12) / efficiency;
						
						if(apsMult13 != Address_Null) 
							aps /= TF2Attrib_GetValue(apsMult13) / efficiency;
						
						if(apsMult14 != Address_Null) 
							aps /= TF2Attrib_GetValue(apsMult14) / efficiency;
						
						if(apsMult15 != Address_Null) 
							aps /= TF2Attrib_GetValue(apsMult15) / efficiency;

					}
				}
				
				if(apsMult5 != Address_Null)
					aps /= TF2Attrib_GetValue(apsMult5) / efficiency;
				
				if(apsMult6 != Address_Null) 
					aps /= TF2Attrib_GetValue(apsMult6) / efficiency;
				
				if(apsMod != Address_Null) 
					aps *= 33.0;
				
				if(TF2_IsPlayerInCondition(client, TFCond_RuneHaste))
					aps *= 2.0 * efficiency;
				
				Address apsAdd = TF2Attrib_GetByName(weapon, "auto fires full clip all at once");
				if(apsAdd != Address_Null)
					aps = 22.0
				
				
				return aps;
			}
		}
	}
	return 1.0;
}
stock float TF2_GetSentryDamageModifiers(client){
	float dmgBonus = 1.0;
	int pda = TF2Util_GetPlayerLoadoutEntity(client, 5);
	if(IsValidWeapon(pda))
	{
		dmgBonus *= TF2Attrib_HookValueFloat(1.0, "dmg_outgoing_mult", pda);
	}
	int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidWeapon(CWeapon))
	{
		Address SentryDmgActive = TF2Attrib_GetByName(CWeapon, "ring of fire while aiming");
		if(SentryDmgActive != Address_Null)
		{
			dmgBonus *= TF2Attrib_GetValue(SentryDmgActive);
		}
	}

	dmgBonus *= TF2Attrib_HookValueFloat(1.0, "mult_engy_sentry_damage", client);
	dmgBonus *= TF2Attrib_HookValueFloat(1.0, "sentry_bullets_per_shot", client);
	
	return dmgBonus;
}
stock float TF2_GetSentryDPSModifiers(client){
	float dmgBonus = TF2_GetSentryDamageModifiers(client);
	dmgBonus /= TF2Attrib_HookValueFloat(1.0, "mult_sentry_firerate", client);
	return dmgBonus;
}
stock float TF2_GetSentryDPS(client, melee){
	float SentryDPS = 180.0;
	
	Address miniSentryActive = TF2Attrib_GetByName(melee, "mod wrench builds minisentry");
	if(miniSentryActive != Address_Null && TF2Attrib_GetValue(miniSentryActive) > 0.0)
	{
		SentryDPS = 32.0;
	}
	else
	{
		Address sentryRocketMult = TF2Attrib_GetByName(melee, "dmg penalty vs nonstunned");
		if(sentryRocketMult != Address_Null)
		{
			SentryDPS += 40.0*TF2Attrib_GetValue(sentryRocketMult);
		}
	}
	float override = GetAttribute(melee, "override projectile type", 0.0);
	switch(override){
		case 33.0:{
			SentryDPS *= 1.25;
		}
	}
	
	SentryDPS *= TF2_GetSentryDPSModifiers(client);

	return SentryDPS;
}
stock float TF2_GetDPSModifiers(client,weapon, bool CountReloadModifiers = true, bool critMod = true, bool onlyModifiers = false)
{
	if(IsValidClient3(client))
    {
		if(IsValidEdict(weapon))
		{
			float dpsMult = onlyModifiers ? 1.0 : TF2_GetDamageModifiers(client,weapon,critMod);
			dpsMult /= TF2Attrib_HookValueFloat(1.0, "mult_postfiredelay", weapon);
			dpsMult /= TF2Attrib_HookValueFloat(1.0, "mult_item_meter_charge_rate", weapon);
			dpsMult /= GetAttribute(weapon, "halloween fire rate bonus");
			dpsMult *= GetAttribute(weapon, "mult projectile count");
			//If their weapon doesn't have a clip, reload rate also affects fire rate.
			if(CountReloadModifiers)
			{
				if(TF2Util_GetWeaponMaxClip(weapon) == -1)
				{
					Address ModClip = TF2Attrib_GetByName(weapon, "mod max primary clip override");
					if(ModClip == Address_Null)
					{
						dpsMult /= GetAttribute(weapon, "faster reload rate");
						dpsMult /= GetAttribute(weapon, "Reload time increased");
						dpsMult /= GetAttribute(weapon, "Reload time decreased");
						dpsMult /= GetAttribute(weapon, "reload time increased hidden");
					}
				}
			}

			//Body Firerate Attributes
			dpsMult /= GetAttribute(client, "fire rate bonus HIDDEN");
			dpsMult /= GetAttribute(client, "fire rate penalty HIDDEN");
			dpsMult /= GetAttribute(client, "fire rate bonus");
			dpsMult /= GetAttribute(client, "fire rate penalty");

			if(TF2_IsPlayerInCondition(client, TFCond_RuneHaste))
			{
				dpsMult *= 2.0;
			}
			return dpsMult;
		}
    }
	return 1.0;
}
stock float TF2_GetDamageModifiers(client,weapon,bool status=true, bool bullets_per_shot = true, bool heavy_weapon_allowed = true)
{
	if(IsValidClient3(client))
    {
		if(IsValidWeapon(weapon))
		{
			//Normal Attributes
			float dpsMult = 1.0;
			Address DPSMult1 = TF2Attrib_GetByName(weapon, "mod rage damage boost");
			Address DPSMult2 = TF2Attrib_GetByName(weapon, "damage bonus");
			Address DPSMult3 = TF2Attrib_GetByName(weapon, "damage penalty");
			Address DPSMult4 = TF2Attrib_GetByName(weapon, "accuracy scales damage");
			Address DPSMult5 = TF2Attrib_GetByName(weapon, "damage bonus HIDDEN");
			Address DPSMult6 = TF2Attrib_GetByName(weapon, "dmg penalty vs players");
			Address DPSMult7 = TF2Attrib_GetByName(weapon, "throwable healing");
			Address DPSMult8 = TF2Attrib_GetByName(weapon, "bullets per shot bonus");
			Address DPSMult9 = TF2Attrib_GetByName(weapon, "taunt is highfive");
			Address DPSMult10 = TF2Attrib_GetByName(weapon, "throwable damage");
			Address projtype = TF2Attrib_GetByName(weapon, "override projectile type");
			
			if(DPSMult1 != Address_Null) {
			dpsMult *= TF2Attrib_GetValue(DPSMult1)
			}
			if(DPSMult2 != Address_Null) {
			dpsMult *= TF2Attrib_GetValue(DPSMult2)
			}
			if(DPSMult3 != Address_Null) {
			dpsMult *= TF2Attrib_GetValue(DPSMult3);
			}
			if(DPSMult4 != Address_Null) {
			dpsMult *= TF2Attrib_GetValue(DPSMult4);
			}
			if(projtype == Address_Null || (projtype != Address_Null && TF2Attrib_GetValue(projtype) != 3.0 && TF2Attrib_GetValue(projtype) != 2.0))
			{
				if(DPSMult5 != Address_Null) {
				dpsMult *= TF2Attrib_GetValue(DPSMult5);
				}
			}
			else if(projtype != Address_Null && TF2Attrib_GetValue(projtype) == 3.0)
			{
				dpsMult *= 2.0;
			}
			if(DPSMult6 != Address_Null) {
			dpsMult *= TF2Attrib_GetValue(DPSMult6);
			}
			if(DPSMult7 != Address_Null) {
			dpsMult *= TF2Attrib_GetValue(DPSMult7);
			}
			if(bullets_per_shot && DPSMult8 != Address_Null){
				dpsMult *= TF2Attrib_GetValue(DPSMult8);
			}
			if(DPSMult9 != Address_Null) {
			dpsMult *= TF2Attrib_GetValue(DPSMult9);
			}
			if(DPSMult10 != Address_Null) {
			dpsMult *= TF2Attrib_GetValue(DPSMult10);
			}

			float damageBonus = TF2Attrib_HookValueFloat(1.0, "dmg_outgoing_mult", weapon);
			dpsMult *= damageBonus;

			if(!heavy_weapon_allowed)
				dpsMult /= GetAttribute(weapon, "damage mult 15", 1.0);

			//Body Stats
			Address BodyDPSMult1 = TF2Attrib_GetByName(client, "mod rage damage boost");
			Address BodyDPSMult2 = TF2Attrib_GetByName(client, "damage bonus");
			Address BodyDPSMult3 = TF2Attrib_GetByName(client, "damage penalty");
			Address BodyDPSMult4 = TF2Attrib_GetByName(client, "accuracy scales damage");
			Address BodyDPSMult5 = TF2Attrib_GetByName(client, "damage bonus HIDDEN");
			Address BodyDPSMult6 = TF2Attrib_GetByName(client, "bullets per shot bonus");

			if(BodyDPSMult1 != Address_Null) {
			dpsMult *= TF2Attrib_GetValue(BodyDPSMult1)
			}
			if(BodyDPSMult2 != Address_Null) {
			dpsMult *= TF2Attrib_GetValue(BodyDPSMult2)
			}
			if(BodyDPSMult3 != Address_Null) {
			dpsMult *= TF2Attrib_GetValue(BodyDPSMult3);
			}
			if(BodyDPSMult4 != Address_Null) {
			dpsMult *= TF2Attrib_GetValue(BodyDPSMult4);
			}
			if(BodyDPSMult5 != Address_Null) {
			dpsMult *= TF2Attrib_GetValue(BodyDPSMult5);
			}
			if(bullets_per_shot && BodyDPSMult6 != Address_Null){
				dpsMult *= TF2Attrib_GetValue(BodyDPSMult6);
			}
			//Custom Attributes
			Address averagedDamage = TF2Attrib_GetByName(weapon, "unique craft index");
			if(averagedDamage != Address_Null)
			{	
				dpsMult = (dpsMult/(1-TF2Attrib_GetValue(averagedDamage)/100.0));
			}
			Address CleaverdamageActive = TF2Attrib_GetByName(weapon, "disguise damage reduction");
			if(CleaverdamageActive != Address_Null){
				dpsMult *= TF2Attrib_GetValue(CleaverdamageActive)
			}
			Address expodamageActive = TF2Attrib_GetByName(weapon, "taunt turn speed");
			if(expodamageActive != Address_Null){
				dpsMult *= Pow(TF2Attrib_GetValue(expodamageActive), 6.0);
			}
			Address damageActive = TF2Attrib_GetByName(weapon, "ubercharge");
			if(damageActive != Address_Null)
			{
				dpsMult *= Pow(1.05,TF2Attrib_GetValue(damageActive));
			}
			//Buffs
			if(status)
			{
				float medicDMGBonus = 1.0;
				int healers = GetEntProp(client, Prop_Send, "m_nNumHealers");
				if(healers > 0)
				{
					for (int i = 1; i <= MaxClients; ++i)
					{
						if (IsValidClient(i))
						{
							int healerweapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
							if(IsValidEdict(healerweapon))
							{
								char classname[128]; 
								GetEdictClassname(healerweapon, classname, sizeof(classname)); 
								if(StrContains(classname, "medigun") != -1)
								{
									if(GetEntPropEnt(healerweapon, Prop_Send, "m_hHealingTarget") == client)
									{
										if(IsValidEdict(healerweapon))
										{
											Address dmgActive = TF2Attrib_GetByName(healerweapon, "hidden secondary max ammo penalty");
											if(dmgActive != Address_Null)
											{
												medicDMGBonus += TF2Attrib_GetValue(dmgActive);
											}
										}
									}
								}
							}
						}
					}
				}
				dpsMult *= medicDMGBonus;
				if(TF2_IsPlayerCritBuffed(client))
				{
					dpsMult *= 2.0;
				}
				else if(TF2_IsPlayerMinicritBuffed(client))
				{
					dpsMult *= 1.35;
				}
				if(TF2_IsPlayerInCondition(client, TFCond_RuneStrength ))
				{
					dpsMult *= 2.0;
				}
				if(TF2_IsPlayerInCondition(client, TFCond_RunePrecision ))
				{
					dpsMult *= 2.0;
				}
			}
			return dpsMult;
		}
    }
	return 1.0;
}

public void RespawnPlayer(int ref){
	int client = EntRefToEntIndex(ref);
	if(IsValidClient3(client))
		TF2_RespawnPlayer(client);
}

float ConsumePierce(float res, float& pierce){
	if(pierce > 1-res){
		pierce -= 1-res;
		res = 1.0;
	}else{
		res += pierce;
		pierce = 0.0;
	}
	return res;
}

void UpdatePlayerSpellSlots(int client){
	if(!IsValidClient3(client))
		return;

	int arcaneSlot = 0;

	//Clear out attuned spells
	for(int i = 0; i<Max_Attunement_Slots;++i)
	{
		AttunedSpells[client][i] = 0;
	}

	for(int i = 0; i<MAX_ARCANESPELLS;i++){
		if(arcaneSlot >= Max_Attunement_Slots)
			break;
		
		if(TF2Attrib_HookValueInt(0, arcaneMap[i].attribute, client)){
			AttunedSpells[client][arcaneSlot] = i+1;
			arcaneSlot++;
		}
	}
}

void UpdatePlayerMaxHealth(int client){
	if(!IsValidClient3(client))
		return;
		
	//thanks sourcepawn :3
	float percentageHealth = float(GetClientHealth(client))/float(TF2Util_GetEntityMaxHealth(client));

	float flatHP = 0.0;
	float mult = TF2Attrib_HookValueFloat(1.0, "max_health_multiplier", client);

	//DR conversion attribute
	float drConversion = TF2Attrib_HookValueFloat(0.0, "health_to_damage_reduction", client);
	if(drConversion > 0 && mult > 1){
		float dr = 1.0/(1-drConversion);
		TF2Attrib_SetByName(client, "dmg taken divided converted", dr);
		mult *= 1-drConversion;
	}else{
		TF2Attrib_SetByName(client, "dmg taken divided converted", 1.0);
	}
	//Sources of flat
	if(TF2Attrib_HookValueFloat(0.0, "juggernaut_powerup", client) == 2.0){
		flatHP += 150.0;
	}
	
	TF2Attrib_SetByName(client,"add health bonus", flatHP + float(RoundToCeil((GetClientBaseHP(client) + flatHP) * (mult-1)) ) );
	if(current_class[client] == TFClass_Engineer)
		TF2Attrib_SetByName(client,"building health mult", mult);

	SetEntityHealth(client, RoundToCeil(percentageHealth*TF2Util_GetEntityMaxHealth(client)));
}

void applyAfterburn(int victim, int attacker, int weapon, float damage){
	if(TF2_IsPlayerInCondition(victim, TFCond_Ubercharged)
	||TF2_IsPlayerInCondition(victim, TFCond_UberchargedHidden)
	||TF2_IsPlayerInCondition(victim, TFCond_UberchargedCanteen)
	||TF2_IsPlayerInCondition(victim, TFCond_AfterburnImmune))
		return;

	float burndmgMult = 0.1
	float burnTime = 6.0;
	if(IsValidWeapon(weapon)){
		burndmgMult *= TF2Attrib_HookValueFloat(1.0, "mult_wpn_burndmg", weapon)*TF2Attrib_HookValueFloat(1.0, "debuff_magnitude_mult", weapon);
		burnTime += TF2Attrib_HookValueFloat(0.0, "afterburn_rating", weapon);
		burnTime *= TF2Attrib_HookValueFloat(1.0, "mult_wpn_burntime", weapon);
		if(TF2Attrib_HookValueFloat(0.0, "knockout_powerup", attacker) == 2 && TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee){
			burndmgMult *= 5;
		}
	}
	if(TF2Attrib_HookValueFloat(0.0, "supernova_powerup", attacker) == 2) {
		burndmgMult *= 2.0;
	}
	
	float afterburnResistance = TF2Attrib_HookValueFloat(0.0, "afterburn_immunity", victim);
	if(afterburnResistance){
		burnTime -= afterburnResistance;
	}
	
	AfterburnStack stack;
	stack.owner = attacker;
	stack.damage = damage*burndmgMult;
	stack.remainingTicks = RoundToNearest(burnTime);

	insertAfterburn(victim, stack);
	TF2_AddCondition(victim, TFCond_BurningPyro, burnTime);
	TF2Util_IgnitePlayer(victim, victim, burnTime);
}

void CreateSmokeBombEffect(float position[3], float duration, int team){
	CreateSmoke(position, 8.0, 255, 255, 255, "300", "20");
	DataPack pack = new DataPack();
	pack.Reset();
	pack.WriteFloat(position[0]);
	pack.WriteFloat(position[1]);
	pack.WriteFloat(position[2]);
	pack.WriteFloat(duration+GetGameTime());
	pack.WriteCell(team);

	CreateTimer(0.1, Timer_SmokeBomb, pack, TIMER_REPEAT);
}

void SendUpgradeDescription(int client, int upgrade_choice, float value){
	disableIFMiniHud[client] = GetGameTime()+8.0;

	char formula[64];
	char result[64];
	char ValueAsString[32];
	char textCopy[256];
	strcopy(textCopy, sizeof(textCopy), upgrades[upgrade_choice].description);
	// Specific values that are not covered by {VALUE} scripts and such
	float resistance = GetResistance(client);
	ReplaceString(textCopy, sizeof(textCopy), "'DR'", GetAlphabetForm(resistance));

	// Iterate through the description and do expression parsing.
	FloatToString(value, ValueAsString, sizeof(ValueAsString));
	int FormulaStartLocation = FindCharInString(textCopy, '[');
	while(FormulaStartLocation != -1){
		strcopy(formula, FindCharInString(textCopy[FormulaStartLocation+1], ']')+1, textCopy[FormulaStartLocation+1]); 
		strcopy(result, sizeof(result), formula);
		ReplaceString(result, sizeof(result), "{VALUE}", ValueAsString);
		Format(result, sizeof(result), "return %s;", result);
		HSCRIPT script = VScript_CompileScript(result);
		
		VScriptExecute execute = new VScriptExecute(script);
		execute.Execute();
		Format(result, sizeof(result), "%.1f",execute.ReturnValue);
		ReplaceStringEx(textCopy, 256, "[", "");
		ReplaceStringEx(textCopy, 256, "]", "");
		ReplaceStringEx(textCopy, 256, formula, result);
		FormulaStartLocation = FindCharInString(textCopy, '[');
	}
	SendItemInfo(client, textCopy);
}

cleanSlateClient(int client){
	if(client <= 0 || client > MaxClients)
		return;
	
	bossPhase[client] = 0;
	Overleech[client] = 0.0;
	BleedBuildup[client] = 0.0;
	RadiationBuildup[client] = 0.0;
	RageActive[client] = false;
	SupernovaBuildup[client] = 0.0;
	ConcussionBuildup[client] = 0.0;
	FreezeBuildup[client] = 0.0;
	fl_HighestFireDamage[client] = 0.0;
	miniCritStatusAttacker[client] = 0.0;
	miniCritStatusVictim[client] = 0.0;
	canShootAgain[client] = true;
	meleeLimiter[client] = 0;
	critStatus[client] = false;
	bloodAcolyteBloodPool[client] = 0.0;
	duplicationCooldown[client] = 0.0;
	warpCooldown[client] = 0.0;
	frayNextTime[client] = 0.0;
	strongholdEnabled[client] = false;
	pylonCharge[client] = 0.0;
	tagTeamTarget[client] = -1;
	immolationActive[client] = false;
	sunstarDuration[client] = 0.0;
	MadmilkDuration[client] = 0.0;
	RageBuildup[client] = 0.0;
	fanOfKnivesCount[client] = 0;
	maelstromChargeCount[client] = 0;
	TeamTacticsBuildup[client] = 0.0;
	karmicJusticeScaling[client] = 0.0;
	pylonCooldown[client] = 0.0;
	infernalDetonationCooldown[client] = 0.0;
	LSPool[client] = 0.0;
	detonateParticleCooldown[client] = 0.0;
	arrowExpulsionCooldown[client] = 0.0;
	clearAllBuffs(client);
	removeAfterburn(client);
	removeRecoup(client);

	for(int i=1;i<=MaxClients;++i)
	{
		corrosiveDOT[client][i][0] = 0.0;
		corrosiveDOT[client][i][1] = 0.0;
		arrowNovaCount[client][i] = 0;
		isTagged[i][client] = false;
		if(client == tagTeamTarget[i])
			tagTeamTarget[i] = -1;
	}

	if(snowstormActive[client]){
		int particleEffect = EntRefToEntIndex(snowstormParticle[client]);
		if(IsValidEntity(particleEffect)){
			SetVariantString("ParticleEffectStop");
			AcceptEntityInput(particleEffect, "DispatchEffect");
			RemoveEntity(particleEffect);
		}
		snowstormActive[client] = false;
	}

	if(!IsClientInGame(client))
		return;

	SetEntityRenderColor(client, 255, 255, 255, 255);
	TF2_RemoveCondition(client,TFCond_Plague);
}

/*public void theBoxness(int client, int melee, const float pos[3], const float angle[3]){
	float fwd[3], endVec[3], mins[3], maxs[3];
	GetAngleVectors(angle, fwd, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fwd, TF2Attrib_HookValueFloat(80.0, "melee_range_multiplier", melee));
	AddVectors(pos, fwd, endVec);

	mins = {-6.0,-6.0,-6.0};
	maxs = {6.0, 6.0, 6.0};

	ScaleVector(mins, TF2Attrib_HookValueFloat(1.0, "melee_bounds_multiplier", melee));
	ScaleVector(maxs, TF2Attrib_HookValueFloat(1.0, "melee_bounds_multiplier", melee));
	Handle trace = TR_TraceHullFilterEx(pos, endVec, mins, maxs, MASK_SHOT, TraceEntityFilterMelee, client);
	delete trace;

	for(int i = 1;i<MAXENTITIES;++i){
		if(isHitForMelee[client][i]){

			SDKHooks_TakeDamage(i, client, client, 65.0, DMG_CLUB + DMG_FALL, melee, _, _, false);
			isHitForMelee[client][i] = false;
		}
	}
}
public bool TraceEntityFilterMelee(int entity, int contentsMask, int client) {
    if (IsValidForDamage(entity) && IsOnDifferentTeams(client, entity)){
		isHitForMelee[client][entity] = true;
	}
    return false;
}*/

ExplosionHookEffects(entity){
	if(!IsValidEntity(entity))
		return;

	int owner = getOwner(entity);
	if(!IsValidClient3(owner))
		return;

	++stickiesDetonated[owner];

	int weapon = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");
	if(!IsValidWeapon(weapon))
		return;
	
	float position[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", position);
	position[2] += 15.0;

	float chance = GetAttribute(weapon, "sticky recursive explosion chance", 0.0)
	if(chance >= GetRandomFloat(0.0,1.0)){
		DataPack hPack = CreateDataPack();
		hPack.Reset();
		WritePackCell(hPack, EntIndexToEntRef(owner));
		WritePackCell(hPack, EntIndexToEntRef(weapon));
		WritePackCell(hPack, entity);
		WritePackFloat(hPack, position[0]);
		WritePackFloat(hPack, position[1]);
		WritePackFloat(hPack, position[2]);
		WritePackFloat(hPack, 90.0 * TF2_GetDamageModifiers(owner, weapon));
		WritePackFloat(hPack, 120.0 * TF2Attrib_HookValueFloat(1.0, "mult_explosion_radius", weapon));
		CreateTimer(0.2, RecursiveExplosions, hPack, TIMER_REPEAT);
	}

	float waspsCount = GetAttribute(weapon, "explosion wasps", 0.0)
	if(waspsCount > 0){
		int targetsList[MAXPLAYERS+1];
		float victimPosition[3];
		int index;
		float damage = 40.0 * TF2_GetDamageModifiers(owner, weapon);
		for(int i=1;i<=MaxClients;++i){
			if(!IsValidClient3(i))
				continue;
			if(!IsPlayerAlive(i))
				continue;
			if(!IsOnDifferentTeams(owner, i))
				continue;
			
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", victimPosition);
			if(GetVectorDistance(position, victimPosition, true) < 250000){
				targetsList[index] = i;
				index++;
			}
		}
		for(int i=0;i<waspsCount;++i){
			int target = targetsList[GetRandomInt(0,index-1)];
			if(!IsValidClient3(target))
				continue;

			SDKHooks_TakeDamage(target, owner, owner, damage,DMG_IGNOREHOOK,_,_,_,false);
			SDKHooks_TakeDamage(target, owner, owner, 3.0, DMG_RADIATION|DMG_DISSOLVE|DMG_IGNOREHOOK,_,_,_,false);

			if(hitParticle[target]+0.2 <= GetGameTime()){
				GetEntPropVector(target, Prop_Data, "m_vecOrigin", victimPosition);
				victimPosition[2] += 30.0;
				TE_SetupBeamPoints(position,victimPosition,Laser,Laser,0,5,1.0,1.0,1.0,5,1.0,{247, 136, 0, 150},10);
				TE_SendToAll();
				hitParticle[target] = GetGameTime();
			}
		}
	}

	if(projectileFragCount[entity] > 0){
		float fAngles[3];

		if(projectileUniformFrag[entity]){
			fAngles[0] = -30.0;
		}
		int fragType = RoundToCeil(TF2Attrib_HookValueFloat(0.0, "explosive_fragment_type", weapon));
		for(int i = 0;i<projectileFragCount[entity];++i)
		{
			int iEntity = CreateEntityByName("tf_projectile_syringe");
			if (!IsValidEdict(iEntity)) 
				continue;

			int iTeam = GetClientTeam(owner);
			float fOrigin[3], vBuffer[3], fVelocity[3], fwd[3];
			AddVectors(fOrigin, position, fOrigin);
			
			SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", owner);
			SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam);
			if(projectileUniformFrag[entity]){
				fAngles[1] += 360.0/projectileFragCount[entity];
			}
			else{
				fAngles[0] = GetRandomFloat(0.0,-60.0);
				fAngles[1] = GetRandomFloat(-179.0,179.0);
			}
			GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(fwd, 30.0);
			AddVectors(fOrigin, fwd, fOrigin);
			GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);

			float velocity = 1500.0*TF2Attrib_HookValueFloat(1.0, "frag_velocity_mult", weapon);
			fVelocity[0] = vBuffer[0]*velocity;
			fVelocity[1] = vBuffer[1]*velocity;
			fVelocity[2] = vBuffer[2]*velocity;
			
			TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
			DispatchSpawn(iEntity);
			setProjGravity(iEntity, 9.0);
			if(fragType == 1){
				jarateType[iEntity] = 0;
				SDKHook(iEntity, SDKHook_StartTouch, OnStartTouchJars);
			}else{
				SDKHook(iEntity, SDKHook_Touch, OnCollisionExplosiveFrag);
			}
			jarateWeapon[iEntity] = EntIndexToEntRef(weapon);
			CreateTimer(1.0,SelfDestruct,EntIndexToEntRef(iEntity));
			SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0x0008);
			SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
			SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 13);
		}
	}

	int bulletCount = RoundToCeil(TF2Attrib_HookValueFloat(0.0, "fan_of_bullets_count", weapon));
	if(bulletCount > 0){
		float endPos[3], fAngles[3], direction[3];
		TracePlayerAim(owner, endPos);
		SubtractVectors(endPos, position, direction);
		GetVectorAngles(direction, fAngles);

		const float spread = 8.0;
		fAngles[1] -= spread + spread/bulletCount;

		for(int j = 0; j < bulletCount; ++j){
			fAngles[1] += (spread*2)/bulletCount;
			float tracepos[3];

			Handle traceray = TR_TraceRayFilterEx(position, fAngles, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite, PenetrationCallTrace, owner);
			if (TR_DidHit(traceray)) {
				TR_GetEndPosition(tracepos, traceray);
			}
			delete traceray;
			
			SpawnBulletTracer(position, tracepos, "bullet_pistol_tracer01_red");
		}
		for(int i = 1; i< MAXENTITIES; ++i){
			if(penetrationCount[i] > 0){
				SDKHooks_TakeDamage(i,owner,owner,15.0*penetrationCount[i],DMG_BULLET,weapon,_,_,false);
				penetrationCount[i] = 0;
			}
		}
	}
}

PopulateFireRateMap(){
	weaponFireRateMap.SetValue("tf_weapon_scattergun", 1.6);
	weaponFireRateMap.SetValue("tf_weapon_soda_popper", 1.6);
	weaponFireRateMap.SetValue("tf_weapon_pep_brawler_blaster", 1.6);
	weaponFireRateMap.SetValue("tf_weapon_shotgun", 1.6);
	weaponFireRateMap.SetValue("tf_weapon_shotgun_primary", 1.6);
	weaponFireRateMap.SetValue("tf_weapon_sentry_revenge", 1.6);
	weaponFireRateMap.SetValue("tf_weapon_shotgun_building_rescue", 1.6);
	weaponFireRateMap.SetValue("tf_weapon_handgun_scout_primary", 2.857);
	weaponFireRateMap.SetValue("tf_weapon_pistol", 6.67);
	weaponFireRateMap.SetValue("tf_weapon_handgun_scout_secondary", 6.67);
	weaponFireRateMap.SetValue("tf_weapon_cleaver", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_rocketlauncher", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_rocketlauncher_directhit", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_particle_cannon", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_rocketlauncher_airstrike", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_raygun", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_drg_pomson", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_shovel", 1.25);
	weaponFireRateMap.SetValue("saxxy", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_fireaxe", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_slap", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_sword", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_bottle", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_stickbomb", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_katana", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_fists", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_wrench", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_robot_arm", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_bonesaw", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_club", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_breakable_sign", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_bat", 2.0);
	weaponFireRateMap.SetValue("tf_weapon_bat_wood", 2.0);
	weaponFireRateMap.SetValue("tf_weapon_bat_fish", 2.0);
	weaponFireRateMap.SetValue("tf_weapon_bat_giftwrap", 2.0);
	weaponFireRateMap.SetValue("tf_weapon_flamethrower", 50.0);
	weaponFireRateMap.SetValue("tf_weapon_rocketlauncher_fireball", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_jar", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_jar_gas", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_jar_milk", 1.25);
	weaponFireRateMap.SetValue("tf_weapon_flaregun", 0.5);
	weaponFireRateMap.SetValue("tf_weapon_flaregun_revenge", 0.5);
	weaponFireRateMap.SetValue("tf_weapon_grenadelauncher", 1.67);
	weaponFireRateMap.SetValue("tf_weapon_cannon", 1.67);
	weaponFireRateMap.SetValue("tf_weapon_pipebomblauncher", 1.67);
	weaponFireRateMap.SetValue("tf_weapon_minigun", 10.0);
	weaponFireRateMap.SetValue("tf_weapon_syringegun_medic", 10.0);
	weaponFireRateMap.SetValue("tf_weapon_syringegun", 10.0);
	weaponFireRateMap.SetValue("tf_weapon_compound_bow", 0.5);
	weaponFireRateMap.SetValue("tf_weapon_crossbow", 4.35);
	weaponFireRateMap.SetValue("tf_weapon_sniperrifle", 0.67);
	weaponFireRateMap.SetValue("tf_weapon_sniperrifle_decap", 0.67);
	weaponFireRateMap.SetValue("tf_weapon_sniperrifle_classic", 0.67);
	weaponFireRateMap.SetValue("tf_weapon_smg", 10.0);
	weaponFireRateMap.SetValue("tf_weapon_charged_smg", 10.0);
	weaponFireRateMap.SetValue("tf_weapon_revolver", 2.0);
	weaponFireRateMap.SetValue("tf_weapon_mechanical_arm", 6.7);
	weaponFireRateMap.SetValue("tf_weapon_pda_engineer_build", 10.0);
	weaponFireRateMap.SetValue("tf_weapon_medigun", TICKRATE);
}

PopulateArcaneMap(){
	CreateArcaneSpell("Zap", "arcane zap", 5.0, 35.0, 0.5, CastZap);
	CreateArcaneSpell("Lightning Strike", "arcane lightning strike", 50.0, 200.0, 6.0, CastLightning);
	CreateArcaneSpell("Projected Healing", "arcane projected healing", 65.0, 0.2, 15.0, CastHealing);
	CreateArcaneSpell("A Call Beyond", "arcane a call beyond", 50.0, 90.0, 25.0, CastACallBeyond);
	CreateArcaneSpell("Blacksky Eye", "arcane blacksky eye", 8.0, 15.0, 0.5, CastBlackskyEye);
	CreateArcaneSpell("Sunlight Spear", "arcane sunlight spear", 50.0, 100.0, 0.5, CastSunlightSpear);
	CreateArcaneSpell("Lightning Enchantment", "arcane lightning enchantment", 150.0, 80.0, 30.0, CastLightningEnchantment);
	CreateArcaneSpell("Snap Freeze", "arcane snap freeze", 70.0, 100.0, 18.0, CastSnapFreeze);
	CreateArcaneSpell("Arcane Prison", "arcane prison", 85.0, 10.0, 75.0, CastArcanePrison);
	CreateArcaneSpell("Darkmoon Blade", "arcane darkmoon blade", 120.0, 15.0, 25.0, CastDarkmoonBlade);
	CreateArcaneSpell("Speed Aura", "arcane speed aura", 40.0, 0.0, 40.0, CastSpeedAura);
	CreateArcaneSpell("Aerial Strike", "arcane aerial strike", 95.0, 60.0, 25.0, CastAerialStrike);
	CreateArcaneSpell("Inferno", "arcane inferno", 95.0, 15.0, 10.0, CastInferno);
	CreateArcaneSpell("Mine Field", "arcane mine field", 70.0, 10.0, 50.0, CastMineField);
	CreateArcaneSpell("Shockwave", "arcane shockwave", 50.0, 100.0, 20.0, CastShockwave);
	CreateArcaneSpell("Auto-Sentry", "arcane autosentry", 150.0, 0.0, 80.0, CastAutoSentry);
	CreateArcaneSpell("Soothing Sunlight", "arcane soothing sunlight", 150.0, 1.0, 90.0, CastSoothingSunlight);
	CreateArcaneSpell("Arcane Hunter", "arcane hunter", 200.0, 100.0, 15.0, CastArcaneHunter);
	CreateArcaneSpell("Sabotage", "arcane mark for death", 50.0, 0.0, 25.0, CastMarkForDeath);
	CreateArcaneSpell("Infernal Enchantment", "arcane infernal enchantment", 250.0, 80.0, 60.0, CastInfernalEnchantment);
	CreateArcaneSpell("Splitting Thunder", "arcane splitting thunder", 250.0, 135.0, 25.0, CastSplittingThunder);
	CreateArcaneSpell("Antiseptic Blast", "arcane antiseptic blast", 200.0, 300.0, 50.0, CastAntisepticBlast);
	CreateArcaneSpell("Karmic Justice", "arcane karmic justice", 60.0, 8.0, 15.0, CastKarmicJustice);
	CreateArcaneSpell("Snowstorm", "arcane snowstorm", 0.0, 90.0, 3.0, CastSnowstorm);
	CreateArcaneSpell("Stun Shot", "arcane stun shot", 15.0, 0.0, 15.0, CastStunShot);
	CreateArcaneSpell("Fireball Volley", "arcane fireball volley", 15.0, 0.0, 5.0, CastFireballVolley);
	CreateArcaneSpell("Transient Moonlight", "arcane transient moonlight", 15.0, 150.0, 5.0, CastTransientMoonlight);
	CreateArcaneSpell("Corpse Piler", "arcane corpse piler", 0.0, 10.0, 30.0, CastCorpsePiler);
	CreateArcaneSpell("Homing Flares", "arcane homing flares", 0.0, 25.0, 7.0, CastHomingFlares);
	CreateArcaneSpell("Arc", "arcane arc", 15.0, 65.0, 3.0, CastArc);
}

CreateArcaneSpell(const char[] name, const char[] attribute, const float cost, const float damage, const float cooldown, Function callback){
	ArcaneSpell tempSpell;
	tempSpell.init(name, attribute, cost, damage, cooldown, callback);
	arcaneMap[arcaneSpellCount] = tempSpell;
	arcaneSpellCount++;
}

PopulateProjectilePropertyMap(){
	projectilePropertyMap.SetValue("tf_projectile_rocket", PROJ_FRAGMENT|PROJ_BOUNCE|PROJ_GRAVITY|PROJ_HOMING|PROJ_PARENTING);
	projectilePropertyMap.SetValue("tf_projectile_arrow", PROJ_BOUNCE|PROJ_NOGRAVITY|PROJ_HOMING|PROJ_SPEEDUPGRADE|PROJ_JAR);
	projectilePropertyMap.SetValue("tf_projectile_healing_bolt", PROJ_BOUNCE|PROJ_NOGRAVITY|PROJ_HOMING|PROJ_SPEEDUPGRADE);
	projectilePropertyMap.SetValue("tf_projectile_mechanicalarmorb", PROJ_HOMING|PROJ_SPEEDUPGRADE);
	projectilePropertyMap.SetValue("tf_projectile_energy_ball", PROJ_HOMING|PROJ_SPEEDUPGRADE);
	projectilePropertyMap.SetValue("tf_projectile_energy_ring", PROJ_HOMING|PROJ_SPEEDUPGRADE);
	projectilePropertyMap.SetValue("tf_projectile_balloffire", PROJ_HOMING|PROJ_SPEEDUPGRADE|PROJ_PARENTING);
	projectilePropertyMap.SetValue("tf_projectile_flare", PROJ_BOUNCE|PROJ_FRAGMENT|PROJ_GRAVITY);
	projectilePropertyMap.SetValue("tf_projectile_sentryrocket", PROJ_BOUNCE|PROJ_FRAGMENT|PROJ_HOMING);
	projectilePropertyMap.SetValue("tf_projectile_syringe", PROJ_HOMING);
	projectilePropertyMap.SetValue("tf_projectile_stun_ball", PROJ_HOMING|PROJ_GRAVITY);
	projectilePropertyMap.SetValue("tf_projectile_ball_ornament", PROJ_HOMING|PROJ_GRAVITY);
	projectilePropertyMap.SetValue("tf_projectile_cleaver", PROJ_HOMING|PROJ_GRAVITY);
	projectilePropertyMap.SetValue("tf_projectile_pipe", PROJ_HOMING|PROJ_GRAVITY|PROJ_FRAGMENT);
	projectilePropertyMap.SetValue("tf_projectile_pipe_remote", PROJ_GRAVITY|PROJ_FRAGMENT);
}

PopulateProjectileLifespanMap(){
	projectileLifespanMap.SetValue("tf_projectile_arrow", 8.0);
	projectileLifespanMap.SetValue("tf_projectile_healing_bolt", 8.0);
	projectileLifespanMap.SetValue("tf_projectile_sentryrocket", 5.0);
	projectileLifespanMap.SetValue("tf_projectile_stun_ball", 2.0);
	projectileLifespanMap.SetValue("tf_projectile_ball_ornament", 2.0);
}

ApplyTauntAttackSpeed(int ref){
	int client = EntRefToEntIndex(ref);
	if(!IsValidClient3(client))
		return;

	int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(!IsValidWeapon(CWeapon))
		return;

	if(!TF2_IsPlayerInCondition(client, TFCond_Taunting)){
		TF2Attrib_RemoveByName(CWeapon, "gesture speed increase");
		return;
	}

	float attackRate = TF2Attrib_HookValueFloat(1.0, "mult_gesture_time", CWeapon);
	if(attackRate != 1.0) {
		float newTime = (GetEntDataFloat(client, TauntAttackTimeOffset)-GetGameTime())/attackRate;
		SetEntDataFloat(client, TauntAttackTimeOffset, GetGameTime() + newTime, true);
		CreateTimer(newTime, Timer_TauntAttackSpeed, ref);
	}
}