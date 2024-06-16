float GetResistance(int client, bool includeReduction = false, float increaseBase = 0.0, float increaseMult = 0.0, float increaseTotal = 0.0)
{
	float TotalResistance = 1.0;

	TotalResistance = increaseTotal+(increaseBase+GetAttribute(client, "tool escrow until date"))*(increaseMult+GetAttribute(client, "is throwable chargeable"));
	if(hasBuffIndex(client, Buff_BrokenArmor)){
		TotalResistance -= playerBuffs[client][getBuffInArray(client,Buff_BrokenArmor)].priority;
	}
	
	TotalResistance *= TotalResistance;
	if(includeReduction)
	{
		Address dmgReduction = TF2Attrib_GetByName(client, "sniper zoom penalty");
		if(dmgReduction != Address_Null)
		{
			TotalResistance /= TF2Attrib_GetValue(dmgReduction);
		}
		for(int i=0;i<=NB_SLOTS_UED;++i){
			int id = GetWeapon(client, i);
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

		Address DodgeBody = TF2Attrib_GetByName(client, "SET BONUS: chance of hunger decrease");
		if(DodgeBody != Address_Null)
			TotalResistance /= 1-TF2Attrib_GetValue(DodgeBody);

		float resPowerup = GetAttribute(client, "resistance powerup", 0.0);
		if(resPowerup == 1 || resPowerup == 3 || GetAttribute(client, "inverter powerup", 0.0) == 2)
			TotalResistance *= 2.0;
		
		if(GetAttribute(client, "revenge powerup", 0.0) == 1 || GetAttribute(client, "knockout powerup", 0.0) == 1 || GetAttribute(client, "king powerup", 0.0) == 1 || GetAttribute(client, "supernova powerup", 0.0) == 1 || GetAttribute(client, "inverter powerup", 0.0) == 1)
			TotalResistance *= 1.25;
		
		if(GetAttribute(client, "regeneration powerup", 0.0) == 1 || GetAttribute(client, "vampire powerup", 0.0) == 1 || 1 <= GetAttribute(client, "plague powerup", 0.0) <= 2)
			TotalResistance *= 1.333;
		
		if(GetAttribute(client, "knockout powerup", 0.0) == 2)
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
			currentDamageType[attacker].second |= DMG_IGNOREHOOK;
			SDKHooks_TakeDamage(victim,attacker,attacker,damage, damagetype,weapon,NULL_VECTOR,NULL_VECTOR,false);
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
stock int CreateParticle(iEntity, char[] strParticle, bool bAttach = false, char[] strAttachmentPoint="", float time = 2.0,float fOffset[3]={0.0, 0.0, 0.0}, bool parentAngle = false, attachType = 0, bool terminate = false)
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
void CreateParticleEx(iEntity, char[] strParticle, m_iAttachType = 0, m_iAttachmentPointIndex = 0, float fOffset[3]=NULL_VECTOR, float time = 0.0)
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
		if(IsNullVector(fOffset)){
			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fOffset);
		}
	}

	TE_WriteFloat("m_vecOrigin[0]", fOffset[0]);
	TE_WriteFloat("m_vecOrigin[1]", fOffset[1]);
	TE_WriteFloat("m_vecOrigin[2]", fOffset[2]);
	
	TE_SendToAllInRange(fOffset, RangeType_Visibility);
}
//Replaces any old buff with same details, else inserts a new one.
public void insertBuff(int client, Buff newBuff){
	int replacementID = getNextBuff(client);

	if(!isBonus[newBuff.id])
		newBuff.duration /= GetAttribute(client, "endurance bonus", 1.0);
		
	for(int i = 0;i < MAXBUFFS;++i){
		if(playerBuffs[client][i].id == newBuff.id && playerBuffs[client][i].priority <= newBuff.priority)
			{replacementID = i;break;}
	}
	buffChange[client] = true;
	playerBuffs[client][replacementID] = newBuff;
	//PrintToServer("added %s to %N for %.2fs. ID = %i, index = %i", newBuff.name, client, newBuff.duration -GetGameTime(), newBuff.id, replacementID);
}
public bool hasBuffIndex(int client, int index){
	if(isBonus[index]){
		for(int i = 0; i < MAXBUFFS; ++i){
			if(playerBuffs[client][i].id == Buff_Nullification)
				return false;
		}
	}

	for(int i = 0; i < MAXBUFFS; ++i){
		if(playerBuffs[client][i].id == index)
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
		playerBuffs[client][i].clear();
	}
}
public void giveDefenseBuff(int client, float duration){
	Buff defenseBuff;
	defenseBuff.init("Defense Bonus", "", Buff_DefenseBoost, 1, client, duration);
	defenseBuff.multiplicativeDamageTaken = 0.65;
	insertBuff(client, defenseBuff);
}
public int GetAmountOfDebuffs(int i){
	if(!IsValidClient3(i))
		return 0;
	
	int amount = 0;
	if(TF2_IsPlayerInCondition(i, TFCond_Slowed))
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_Dazed))
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_OnFire))
		++amount;
	if(miniCritStatusVictim[i]-currentGameTime > 0.0)
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_Bleeding))
		++amount;
	if(MadmilkDuration[i] > currentGameTime)
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_Sapped))
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_FreezeInput))
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_HealingDebuff))
		++amount;
	if(TF2_IsPlayerInCondition(i, TFCond_Gas))
		++amount;
		
	return amount;
}
public void ManagePlayerBuffs(int i){
	float additiveDamageRawBuff,additiveDamageMultBuff = 1.0,multiplicativeDamageBuff = 1.0,additiveAttackSpeedMultBuff = 1.0,multiplicativeAttackSpeedMultBuff = 1.0,additiveMoveSpeedMultBuff = 1.0,additiveDamageTakenBuff = 1.0,multiplicativeDamageTakenBuff = 1.0, additiveArmorPenetration = 0.0;

	char details[255] = "Statuses Active:"

	for(int buff = 0;buff < MAXBUFFS; buff++)
	{
		if(playerBuffs[i][buff].id == 0)
			continue;

		//Clear out any non-active buffs.
		if(playerBuffs[i][buff].duration != 0.0 && playerBuffs[i][buff].duration < currentGameTime){
			playerBuffs[i][buff].clear();
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
				playerBuffs[i][buffCheck].priority > playerBuffs[i][buff].priority)
				{flag = true;break;}
		}

		if(flag)
			continue;

		additiveDamageRawBuff += playerBuffs[i][buff].additiveDamageRaw;
		additiveDamageMultBuff += playerBuffs[i][buff].additiveDamageMult;
		multiplicativeDamageBuff *= playerBuffs[i][buff].multiplicativeDamage;
		additiveAttackSpeedMultBuff += playerBuffs[i][buff].additiveAttackSpeedMult;
		multiplicativeAttackSpeedMultBuff *= playerBuffs[i][buff].multiplicativeAttackSpeedMult;
		additiveMoveSpeedMultBuff += playerBuffs[i][buff].additiveMoveSpeedMult;
		additiveDamageTakenBuff += playerBuffs[i][buff].additiveDamageTaken;
		multiplicativeDamageTakenBuff *= playerBuffs[i][buff].multiplicativeDamageTaken;
		additiveArmorPenetration += playerBuffs[i][buff].additiveArmorPenetration;

		if(playerBuffs[i][buff].description[0] != '\0')
			Format(details, sizeof(details), "%s\n%s: - %.1fs\n  %s", details, playerBuffs[i][buff].name, playerBuffs[i][buff].duration - currentGameTime, playerBuffs[i][buff].description);
		else
			Format(details, sizeof(details), "%s\n%s - %.1fs", details, playerBuffs[i][buff].name, playerBuffs[i][buff].duration - currentGameTime);
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
			int sapper = GetWeapon(spy,5);
			if(IsValidWeapon(sapper)){
				multiplicativeDamageTakenBuff *= GetAttribute(sapper, "scattergun knockback mult");
			}
		}
	}


	for(int savior = 1;savior<=MaxClients;++savior){
		if(!IsValidClient3(savior))
			continue;
		if(!IsPlayerAlive(savior))
			continue;
		if(IsOnDifferentTeams(i,savior))
			continue;

		additiveDamageMultBuff += TeamTacticsBuildup[savior];
	}

	TF2Attrib_SetByName(i, "additive damage bonus", additiveDamageRawBuff);
	TF2Attrib_SetByName(i, "damage bonus", additiveDamageMultBuff*multiplicativeDamageBuff);
	TF2Attrib_SetByName(i, "firerate player buff", 1.0/(additiveAttackSpeedMultBuff*multiplicativeAttackSpeedMultBuff));
	TF2Attrib_SetByName(i, "recharge rate player buff", 1.0/(additiveAttackSpeedMultBuff*multiplicativeAttackSpeedMultBuff));
	TF2Attrib_SetByName(i, "Reload time decreased", 1.0/(additiveAttackSpeedMultBuff*multiplicativeAttackSpeedMultBuff));
	TF2Attrib_SetByName(i, "movespeed player buff", additiveMoveSpeedMultBuff);
	TF2Attrib_SetByName(i, "damage taken mult 4", additiveDamageTakenBuff*multiplicativeDamageTakenBuff);
	TF2Attrib_SetByName(i, "armor penetration buff", additiveArmorPenetration);
	TF2Attrib_ClearCache(i);

	if(miniCritStatusVictim[i]-currentGameTime > 0.0){
		Format(details, sizeof(details), "%s\n%s - %.1fs", details, "Marked-For-Death", miniCritStatusVictim[i]-currentGameTime);
		TF2_AddCondition(i, TFCond_MarkedForDeath, 0.2);
	}
	if(miniCritStatusAttacker[i]-currentGameTime > 0.0){
		Format(details, sizeof(details), "%s\n%s - %.1fs", details, "Minicrits", miniCritStatusAttacker[i]-currentGameTime);
		TF2_AddCondition(i, TFCond_Buffed, 0.2);
	}

	if(IsFakeClient(i) || disableIFMiniHud[i] > currentGameTime)
		return;

	if(LightningEnchantmentDuration[i] > currentGameTime){
		Format(details, sizeof(details), "%s\nLightning Enchantment | %.2fs | +%s DPS", details, LightningEnchantmentDuration[i] - currentGameTime,  GetAlphabetForm(LightningEnchantment[i]*20.0));
	}
	if(DarkmoonBladeDuration[i] > currentGameTime){
		Format(details, sizeof(details), "%s\nDarkmoon Blade | %.2fs | +%s Melee Damage", details, DarkmoonBladeDuration[i] - currentGameTime, GetAlphabetForm(DarkmoonBlade[i]));
	}
	if(InfernalEnchantmentDuration[i] > currentGameTime){
		Format(details, sizeof(details), "%s\nInfernal Enchantment | %.2fs | +%s Infernal DPS", details, InfernalEnchantmentDuration[i] - currentGameTime, GetAlphabetForm(InfernalEnchantment[i]));
	}
	if(karmicJusticeScaling[i]){
		Format(details, sizeof(details), "%s\nKarmic Justice | %.2f Scaling", details, karmicJusticeScaling[i]);
	}

	if(MadmilkDuration[i]-currentGameTime > 0.0){
		Format(details, sizeof(details), "%s\n%s - %.1fs", details, "Milked", MadmilkDuration[i]-currentGameTime);
	}

	if(TF2_IsPlayerInCondition(i, TFCond_AfterburnImmune))
		Format(details, sizeof(details), "%s\n%s - %.1fs", details, "Afterburn Immunity", TF2Util_GetPlayerConditionDuration(i, TFCond_AfterburnImmune));

	if(additiveDamageRawBuff != 0.0)
		Format(details, sizeof(details), "%s\n+%i Damage", details, RoundToNearest(additiveDamageRawBuff));
	
	if(additiveDamageMultBuff*multiplicativeDamageBuff != 1.0)
		Format(details, sizeof(details), "%s\n+%ipct Damage", details, RoundToNearest(((additiveDamageMultBuff*multiplicativeDamageBuff)-1.0)*100.0) );

	if(additiveAttackSpeedMultBuff*multiplicativeAttackSpeedMultBuff != 1.0)
		Format(details, sizeof(details), "%s\n+%ipct Fire Rate", details, RoundToNearest(((additiveAttackSpeedMultBuff*multiplicativeAttackSpeedMultBuff)-1.0)*100.0) );

	if(additiveMoveSpeedMultBuff > 1.0)
		Format(details, sizeof(details), "%s\n+%ipct Move Speed", details, RoundToNearest((additiveMoveSpeedMultBuff-1.0)*100.0) );
	else if(additiveMoveSpeedMultBuff < 1.0)
		Format(details, sizeof(details), "%s\n%ipct Move Speed", details, RoundToNearest((additiveMoveSpeedMultBuff-1.0)*100.0) );

	if(additiveDamageTakenBuff*multiplicativeDamageTakenBuff > 1.0)
		Format(details, sizeof(details), "%s\n+%ipct Damage Vulnerability", details, RoundToNearest(((additiveDamageTakenBuff*multiplicativeDamageTakenBuff)-1.0)*100.0) );
	else if (additiveDamageTakenBuff*multiplicativeDamageTakenBuff < 1.0)
		Format(details, sizeof(details), "%s\n-%ipct Damage Taken", details, RoundToNearest( (1.0-(additiveDamageTakenBuff*multiplicativeDamageTakenBuff)) *100.0) );

	float healingMult = GetPlayerHealingMultiplier(i);
	if(healingMult > 1.0)
		Format(details, sizeof(details), "%s\n+%ipct Healing Received", details, RoundToNearest( (healingMult - 1.0) * 100.0) );
	else if (healingMult < 1.0)
		Format(details, sizeof(details), "%s\n-%ipct Healing Received", details, RoundToNearest( (1.0-healingMult) * 100.0) );

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
stock EntityExplosion(owner, float damage, float radius, float pos[3], soundType = 0, bool visual = true, entity = -1, float soundLevel = SNDVOL_NORMAL,damagetype = DMG_BLAST, weapon = -1, float falloff = 0.0, soundPriority = SNDLEVEL_NORMAL, bool ignition = false, int firstBits = 0, int secondBits = 0, int thirdBits = 0, char[] particle = "ExplosionCore_MidAir", float knockback = 0.0, bool noMultihit = false)
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
					if(falloff != 0.0)
					{
						float ratio = (1.0-(distance/radius)*falloff);
						if(ratio < 0.5)
							ratio = 0.5;
						if(ratio >= 0.95)
							ratio = 1.0;
						damage *= ratio
					}
					if(isAimlessProjectile[entity]){
						if(distance <= 200){
							damage *= 1+3*((200-distance)/200);
						}
					}
					
					currentDamageType[owner].first = damagetype | firstBits;
					currentDamageType[owner].second = secondBits;
					currentDamageType[owner].third = thirdBits;

					if(IsValidEdict(weapon) && IsValidClient3(i))
					{
						currentDamageType[owner].second |= DMG_IGNOREHOOK;
						SDKHooks_TakeDamage(i,owner,owner,damage, damagetype,weapon,_,_,false)
						if(knockback > 0.0)
							PushEntity(i, owner, knockback, 200.0);
						if(ignition)
							TF2Util_IgnitePlayer(i, owner, 7.0, weapon);
					}
					else
					{
						currentDamageType[owner].second |= DMG_IGNOREHOOK;
						SDKHooks_TakeDamage(i,owner,owner,damage, damagetype,_,_,_, false);
					}
					if(noMultihit)
						ShouldNotHit[entity][i] = true;
				}
			}
		}
	}
	if(visual)
	{
		/*int particle = CreateEntityByName( "info_particle_system" );
		if ( IsValidEdict( particle ) )
		{
			TeleportEntity( particle, pos, NULL_VECTOR, NULL_VECTOR );
			DispatchKeyValue( particle, "effect_name", "ExplosionCore_MidAir" );
			DispatchSpawn( particle );
			ActivateEntity( particle );
			AcceptEntityInput( particle, "start" );
			SetVariantString( "OnUser1 !self:Kill::8:-1" );
			AcceptEntityInput( particle, "AddOutput" );
			AcceptEntityInput( particle, "FireUser1" );
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
stock char[] getDamageCategory(extendedDamageTypes damagetype, int attacker = -1)
{
	//int damagebits2;
	char damageCategory[64];

	if(IsValidClient3(attacker)){
		if(GetAttribute(attacker, "supernova powerup", 0.0) == 3)
			StrCat(damageCategory, sizeof(damageCategory), "electric");
	}

	if(damagetype.second & DMG_PIERCING)
	{
		StrCat(damageCategory, sizeof(damageCategory), "piercing");
	}
	else if(damagetype.first & DMG_BULLET || damagetype.first & DMG_SLASH || 
	damagetype.first & DMG_VEHICLE || damagetype.first & DMG_FALL || damagetype.first & DMG_CLUB || 
	damagetype.first & DMG_BUCKSHOT)
	{
		StrCat(damageCategory, sizeof(damageCategory), "direct");
	}
	else if(damagetype.first & DMG_BLAST || damagetype.first & DMG_BLAST_SURFACE)
	{
		StrCat(damageCategory, sizeof(damageCategory), "blast");
	}
	else if(damagetype.first & DMG_BURN || damagetype.first & DMG_SLOWBURN || damagetype.first & DMG_IGNITE)
	{
		StrCat(damageCategory, sizeof(damageCategory), "fire");
	}
	else if(damagetype.first & DMG_SHOCK || damagetype.first & DMG_ENERGYBEAM)
	{
		StrCat(damageCategory, sizeof(damageCategory), "electric");
	}
	else if(damagetype.second & DMG_ARCANE)
	{
		StrCat(damageCategory, sizeof(damageCategory), "arcane");
	}
	else
	{
		StrCat(damageCategory, sizeof(damageCategory), "generic");
	}
	return damageCategory;
}
CheckForAttunement(client)
{
	bool flag = false;
	for(int i = 0;i<Max_Attunement_Slots;++i)
	{
		if(AttunedSpells[client][i] != 0.0)
		{
			flag = true;
			break;
		}
	}
	return flag;
}
public bool GiveNewWeapon(client, slot)
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
	if (IsValidEdict(entity))
	{
		client_new_weapon_ent_id[client] = entity;
		currentitem_level[client][slot] = 242;
		GiveNewUpgradedWeapon_(client, slot)
		EquipPlayerWeapon(client, entity);
		return true;
	}
	return false
}
public GiveNewUpgradedWeapon_(client, slot)
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
		iEnt = client_new_weapon_ent_id[client];
	}
	if (IsValidEdict(iEnt) && HasEntProp(iEnt, Prop_Send, "m_AttributeList"))
	{
		TF2Attrib_RemoveByName(iEnt, "bullets per shot bonus");
		if( iNumAttributes > 0 )
		{
			for(int a = 0; a < iNumAttributes ; a++ )
			{
				int ifid = upgrades[currentupgrades_idx[client][slot][a]].to_a_id;
				if (upgrades[ifid].attr_name[0] == '\0')
					continue;
					
				TF2Attrib_SetByName(iEnt, upgrades[ifid].attr_name,currentupgrades_val[client][slot][a]);
			}
		}

		float bpsMult = GetAttribute(iEnt, "bullets per shot bonus", 1.0);
		bpsMult *= GetAttribute(iEnt, "bullets per shot mult", 1.0);
		bpsMult *= GetAttribute(iEnt, "bullets per shot mult 2", 1.0);
		if(bpsMult != 1.0)
			TF2Attrib_SetByName(iEnt, "bullets per shot bonus", bpsMult);
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
			if(inum == 20000)//havent upgraded
			{
				//PrintToChat(client, "E");
				for(int i = 1;i<5;++i)
				{
					if(currentupgrades_restriction[client][slot][i] == upgrades[upgrade_choice].restriction_category)
					{
						PrintToChat(client, "You already have something that fits this restriction category.");
						EmitSoundToClient(client, SOUND_FAIL);
						return 0;
					}
				}
				currentupgrades_restriction[client][slot][upgrades[upgrade_choice].restriction_category] = upgrades[upgrade_choice].restriction_category;
			}
			else if(currentupgrades_val[client][slot][inum] - upgrades[upgrade_choice].i_val == 0.0)
			{
				for(int i = 1;i<5;++i)
				{
					if(currentupgrades_restriction[client][slot][i] == upgrades[upgrade_choice].restriction_category)
					{
						PrintToChat(client, "You already have something that fits this restriction category.");
						EmitSoundToClient(client, SOUND_FAIL);
						return 0;
					}
				}
				currentupgrades_restriction[client][slot][upgrades[upgrade_choice].restriction_category] = upgrades[upgrade_choice].restriction_category;
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
	client_spent_money_mvm_chkp[client][slot] = 0.0
	currentupgrades_number[client][slot] = 0;
	currentupgrades_number_mvm_chkp[client][slot] = 0;
	client_tweak_highest_requirement[client][slot] = 0.0;
	
	for(int y = 0; y<5;y++)
	{
		currentupgrades_restriction[client][slot][y] = 0;
		currentupgrades_restriction_mvm_chkp[client][slot][y] = 0;
	}
	
	
	for (int i = 0; i < iNumAttributes; ++i)
	{
		currentupgrades_val_mvm_chkp[client][slot][i] = 0.0;
		currentupgrades_val[client][slot][i] = 0.0;
		currentupgrades_i[client][slot][i] = 0.0;
		currentupgrades_idx[client][slot][i] = 0;
		currentupgrades_idx_mvm_chkp[client][slot][i] = currentupgrades_idx[client][slot][i];
	}
	//I AM THE STORM THAT IS APPROACHING
	//Thank you retard MR L
	for(int i = 0; i < MAX_ATTRIBUTES; ++i)
	{
		upgrades_ref_to_idx[client][slot][i] = 20000;
		upgrades_ref_to_idx_mvm_chkp[client][slot][i] = 20000;
		upgrades_efficiency[client][slot][i] = 0.0;
		upgrades_efficiency_list[client][slot][i] = 0;
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
		client_new_weapon_ent_id[client] = 0;
		client_new_weapon_ent_id_mvm_chkp[client] = 0;
	}
	if (slot == 4)
	{
		currentitem_idx[client][slot] = 20000
		GiveNewUpgradedWeapon_(client, slot)
		for(int i = 0; i < Max_Attunement_Slots; ++i)
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
	if (itemidx >= 0 && itemidx != currentitem_idx[client][slot])
	{
		if(currentitem_level[client][slot] != 242)
			ResetClientUpgrade_slot(client, slot);

		int a, a2, i, a_i
	
		currentitem_idx[client][slot] = itemidx
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

		if(currentitem_level[client][slot] == 242){
			for( a = 0; a < upgrades_weapon_nb_att[upgrades_weapon_current[client]] && a < 42; a++ )
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
	char ChangeString[189];
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
			ChangeString = "The Sandman | Ball base damage increased to 40.";
		}
		case 648:
		{
			ChangeString = "The Wrap Assassin | Ball base damage increased to 40. Fires balls on primary fire.";
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
			ChangeString = "The Black Box | Applies afterburn to enemies. +1 rocket per shot but 2x slower fire rate.";
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
		case 730:
		{
			ChangeString = "The Beggar's Bazooka | 70% faster fire rate, but you deal 66% less damage.";
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
			ChangeString = "The Concheror | Gives a 15% lifesteal effect to teammates when active. Can overheal to 150%. Rage scales off of firerate of weapon.";
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
			ChangeString = "The Iron Bomber | Shoots grenades that explode when victims are within 70% of the blast radius. Has no splash fall-off.";
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
			ChangeString = "Ullapool Caber | Infinite explosive charges.";
		}
		//Heavy Primaries
		case 312:
		{
			ChangeString = "The Brass Beast | Shoots rockets that have 90 base damage and 200HU blast radius and can penetrate enemies. Cannot hit enemies multiple times. 3x slower fire rate.";
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
			ChangeString = "The Warrior's Spirit | Deals -40% damage. Shoots an additional 2 arrows per attack that deal 30 base damage.";
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
		//Engineer Secondary
		case 528:
		{
			ChangeString = "The Short Circuit | Shoots explosive bullets instead. Applies burn.";
		}
		//Engineer Melee
		case 329:
		{
			ChangeString = "The Jag | Will instantly build buildings at level 3, but will cost 100% of your metal.";
		}
		case 589:
		{
			ChangeString = "The Eureka Effect | Teleporting will deal 500 base DPS based on sentry upgrades, stun targets, and launch them into the air. Cannot build a sentry, but teleporters are instant-built.";
		}
		case 142:
		{
			ChangeString = "The Gunslinger | Throw out instant-built minisentries. Up to 5 sentries placed in total, and upon destroying, deal 70 base DPS.";
		}
		//Medic Primaries
		case 36:
		{
			ChangeString = "The Blutsauger | +10% life steal ability.";
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
			ChangeString = "The Cleaner's Carbine | Crikey now applies mark for death. Close ranged backattacks do minicrits. Converts fire rate to damage.";
		}
		case 58	:
		{
			ChangeString = "Jarate | Jarate effect now applies +10 damage (based on your scaling) to every hit taken.";
		}
		//Sniper Melees
		case 232:
		{
			ChangeString = "The Bushwacka | Launches projectile dealing 180 base damage and returns after 0.7s. Projectile pierces all targets forever and can hit multiple times. Fires 4x slower.";
		}
		//Spy Primaries
		case 61,1006:
		{
			ChangeString = "The Ambassador | Converts fire rate to damage. Can constantly headshot. 2x slower fire rate.";
		}
		case 460:
		{
			ChangeString = "The Enforcer | Takes 2 ammo per shot. 2x fire rate. 7x slower reload speed. Pierces resistance status effects (ie : vaccinator)";
		}
		case 525:
		{
			ChangeString = "The Diamondback | Converts fire rate to damage. Fires 3 round bursts and has a slight delay afterwards.";
		}
		//Spy Melees
		case 356:
		{
			ChangeString = "The Conniver's Kunai | Backstabs instead have a 50% lifesteal bonus.";
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
public UpgradeItem(client, upgrade_choice, int &inum, float ratio, slot)
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
		if(!canBypassRestriction[client])
		 check_apply_maxvalue(client, slot, inum, upgrade_choice)
	}
	client_last_up_idx[client] = upgrade_choice
	client_last_up_slot[client] = slot
}
public remove_attribute(client, inum)
{
	int slot = current_slot_used[client];
	if(currentupgrades_i[client][slot][inum] != 0.0 && upgrades[currentupgrades_idx[client][slot][inum]].cost > 1.0)
	{
		currentupgrades_val[client][slot][inum] = currentupgrades_i[client][slot][inum];
	}
	else
	{
		currentupgrades_val[client][slot][inum] = upgrades[currentupgrades_idx[client][slot][inum]].i_val;
	}
	int u = currentupgrades_idx[client][slot][inum]
	if (u != 20000)
	{
		if(upgrades[u].restriction_category != 0)
		{
			for(int i = 1;i<5;++i)
			{
				if(i == upgrades[u].restriction_category)
				{
					currentupgrades_restriction[client][slot][i] = 0;
				}
			}
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
	current_class[client] = TF2_GetPlayerClass(client)
	fl_CurrentFocus[client] = fl_MaxFocus[client];
	LightningEnchantmentDuration[client] = 0.0;
	DarkmoonBladeDuration[client] = 0.0;
	TF2Attrib_SetByName(client,"deploy time decreased", 0.0);
	TF2Attrib_SetByName(client,"airblast_pushback_no_stun", 1.0);
	TF2Attrib_SetByName(client,"airblast_destroy_projectile", 1.0);
	TF2Attrib_SetByName(client,"ignores other projectiles", 1.0);
	TF2Attrib_SetByName(client,"penetrate teammates", 1.0);
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
	CreateParticleEx(phys, "drg_cowmangler_trail_charged", 1, 0, origin, 2.0);
	CreateParticleEx(phys, "rockettrail_airstrike_line", 1, 0, origin);
	CreateParticleEx(phys, "rockettrail_fire_airstrike", 1, 0, origin);
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
	int wrench = GetWeapon(client,2);
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
		if ( !(strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectDispenser") == 0) ){
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

		if ( !(strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectDispenser") == 0) ){
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
	if(IsValidClient3(client) && IsPlayerAlive(client))
	{
		current_class[client] = TF2_GetPlayerClass(client);
		int slotItem;
		if(slot == 3 && IsValidEdict(client_new_weapon_ent_id[client]) && client_new_weapon_ent_id[client] > 0)
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
			for(int i = 0; i<Max_Attunement_Slots;++i)
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
				if(GetAttribute(client, "arcane infernal enchantment", 0.0) > 0.0 && !isUsed[20])
				{
					AttunedSpells[client][i] = 20.0;
					isUsed[20] = true
					continue;
				}
				if(GetAttribute(client, "arcane splitting thunder", 0.0) > 0.0 && !isUsed[21])
				{
					AttunedSpells[client][i] = 21.0;
					isUsed[21] = true
					continue;
				}
				if(GetAttribute(client, "arcane antiseptic blast", 0.0) > 0.0 && !isUsed[22])
				{
					AttunedSpells[client][i] = 22.0;
					isUsed[22] = true
					continue;
				}
				if(GetAttribute(client, "arcane karmic justice", 0.0) > 0.0 && !isUsed[23])
				{
					AttunedSpells[client][i] = 23.0;
					isUsed[23] = true
					continue;
				}
				if(GetAttribute(client, "arcane snowstorm", 0.0) > 0.0 && !isUsed[24])
				{
					AttunedSpells[client][i] = 24.0;
					isUsed[24] = true
					continue;
				}
			}
			Address healthActive = TF2Attrib_GetByName(client, "max health multiplier");
			if(healthActive != Address_Null)
			{
				TF2Attrib_SetByName(client,"add health bonus", float(RoundToCeil(GetClientBaseHP(client)*(TF2Attrib_GetValue(healthActive)-1.0))) );
				if(current_class[client] == TFClass_Engineer)
					TF2Attrib_SetByName(client,"engy building health bonus", TF2Attrib_GetValue(healthActive));
			}
			
			TF2Attrib_RemoveByName(client,"ubercharge rate bonus");
			TF2Attrib_RemoveByName(client,"heal rate bonus");
			TF2Attrib_RemoveByName(client, "health from healers reduced");
			TF2Attrib_RemoveByName(client,"weapon spread bonus");
			TF2Attrib_RemoveByName(client,"Projectile speed increased");
			TF2Attrib_RemoveByName(client,"Projectile range increased");
			TF2Attrib_RemoveByName(client,"sniper charge per sec");
			TF2Attrib_RemoveByName(client,"blast dmg to self increased");
			TF2Attrib_RemoveByName(client,"damage mult 1");
			TF2Attrib_RemoveByName(client,"fire rate penalty");
			TF2Attrib_RemoveByName(client,"major move speed bonus");
			TF2Attrib_RemoveByName(client,"self dmg push force increased");
			TF2Attrib_RemoveByName(client,"SET BONUS: chance of hunger decrease");
			TF2Attrib_RemoveByName(client,"has pipboy build interface");
			TF2Attrib_RemoveByName(client,"mult afterburn delay");

			if(current_class[client] == TFClass_DemoMan)
			{
				int secondary = GetWeapon(client,1);
				if(IsValidEdict(secondary))
				{
					TF2Attrib_RemoveByName(secondary,"sticky arm time penalty");
				}
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
				if(kingPowerupValue == 3)
					TF2Attrib_SetByName(client, "health from healers reduced", 0.2);
			}

			if(GetAttribute(client, "resistance powerup", 0.0) == 2.0){
				TF2Attrib_SetByName(client, "major move speed bonus", 1.2);
			}
			
			Address precisionPowerup = TF2Attrib_GetByName(client, "precision powerup");
			if(precisionPowerup != Address_Null)
			{
				float precisionPowerupValue = TF2Attrib_GetValue(precisionPowerup);
				if(precisionPowerupValue == 1){
					TF2Attrib_SetByName(client,"weapon spread bonus", 0.05);
					TF2Attrib_SetByName(client,"Projectile speed increased", 2.0);
					TF2Attrib_SetByName(client,"Projectile range increased", 1.35);
					TF2Attrib_SetByName(client,"sniper charge per sec", 1.75);
					TF2Attrib_SetByName(client,"blast dmg to self increased", 0.001);
					if(current_class[client] == TFClass_DemoMan)
					{
						int secondary = GetWeapon(client,1);
						if(IsValidEdict(secondary))
						{
							TF2Attrib_SetByName(secondary,"sticky arm time penalty", -2.0);
						}
					}
				}

				if(precisionPowerupValue == 3){
					TF2Attrib_SetByName(client,"damage mult 1", 4.0);
					TF2Attrib_SetByName(client,"fire rate penalty", 4.0);
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
					TF2Attrib_SetByName(client,"has pipboy build interface", 72.0);
				}

				TF2Attrib_SetByName(client,"major increased jump height", TF2Attrib_GetValue(agilityPowerup) == 1 ? 1.3 : (TF2Attrib_GetValue(agilityPowerup) == 2 ? 2.0 : 1.0));
			}

			Address supernovaPowerup = TF2Attrib_GetByName(client, "supernova powerup");
			if(supernovaPowerup != Address_Null)
			{
				if(TF2Attrib_GetValue(supernovaPowerup) == 2)
					TF2Attrib_SetByName(client,"mult afterburn delay", 1.55);
			}

		}
		if(slot != 4 && IsValidEdict(slotItem) && slotItem > 0 && HasEntProp(slotItem, Prop_Data, "m_iClip1"))
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
				TF2Attrib_SetByName(slotItem, "projectile spread angle penalty", Spread);

			Address reloadActive = TF2Attrib_GetByName(slotItem, "multiple sentries");
			if(reloadActive!=Address_Null)
				SetEntProp(slotItem, Prop_Data, "m_bReloadsSingly", TF2Attrib_GetValue(reloadActive) != 0 ? 0 : 1);

			Address explosiveBullets = TF2Attrib_GetByName(slotItem, "explosive bullets");
			if(explosiveBullets!=Address_Null)
				TF2Attrib_SetFromStringValue(slotItem, "explosion particle", "ExplosionCore_sapperdestroyed");

			Address firerateActive = TF2Attrib_GetByName(slotItem, "disguise speed penalty");
			Address heavyweaponActive = TF2Attrib_GetByName(slotItem, "Converts Firerate to Damage");//Implement "Heavy" Weapons
			if(heavyweaponActive != Address_Null && TF2Attrib_GetValue(heavyweaponActive) != 0.0)
			{
				Address firerateActive2 = TF2Attrib_GetByName(slotItem, "fire rate bonus HIDDEN");
				Address firerateActive3 = TF2Attrib_GetByName(slotItem, "fire rate penalty HIDDEN");
				Address firerateActive4 = TF2Attrib_GetByName(slotItem, "mult_item_meter_charge_rate");
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
				if(firerateActive4 != Address_Null)
				{
					damageModifier /= TF2Attrib_GetValue(firerateActive4);
					TF2Attrib_RemoveByName(slotItem, "mult_item_meter_charge_rate");
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
				TF2Attrib_SetByName(slotItem,"damage mult 15", damageModifier);
			}
			else if(firerateActive != Address_Null)
			{
				TF2Attrib_SetByName(slotItem,"fire rate bonus", 1.0/TF2Attrib_GetValue(firerateActive));
				if(TF2Util_IsEntityWeapon(slotItem) && TF2Util_GetWeaponSlot(slotItem) == TFWeaponSlot_Melee)
					TF2Attrib_SetByName(slotItem,"mult smack time", 1.0/TF2Attrib_GetValue(firerateActive));
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
			int weap = GetWeapon(client,i);
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
					int weap = GetWeapon(client,i);
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
					int weap = GetWeapon(client,i);
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
					int weap = GetWeapon(client,i);
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
					int weap = GetWeapon(client,i);
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
					int weap = GetWeapon(client,i);
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
					int weap = GetWeapon(client,i);
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

	int sapper = GetWeapon(inflictor,5);
	if(!IsValidWeapon(sapper))
		return;

	float magnitude = GetAttribute(sapper, "sapper pulls enemies", 0.0);
	if(magnitude){
		for(int i = 1; i <= MaxClients; ++i){
			if(!IsValidClient(i) || !IsPlayerAlive(i))
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
ApplyFullHoming(int entity){
	entity = EntRefToEntIndex(entity);
	if(!IsValidEdict(entity))
		return;
	int owner = getOwner(entity);
	if(!IsValidClient3(owner))
		return;
	int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
	if(!IsValidWeapon(CWeapon))
		return;
	float homingActive = GetAttribute(CWeapon, "crit from behind", 0.0);
	if(!homingActive)
		return;

	isProjectileHoming[entity] = true;
}
ApplyHomingCharacteristics(DataPack pack)//int,float,int,int
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(!IsValidEdict(entity))
		return;
	int owner = getOwner(entity);
	if(!IsValidClient3(owner))
		return;
	int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
	if(!IsValidWeapon(CWeapon))
		return;
	float homingActive = GetAttribute(CWeapon, "crit from behind", 0.0)
	+ GetAttribute(owner, "crit from behind", 0.0);
	if(!homingActive)
		return;
	
	homingRadius[entity] = homingActive;
	homingDelay[entity] = pack.ReadFloat();
	homingTickRate[entity] = pack.ReadCell();
	homingAimStyle[entity] = pack.ReadCell();
	delete pack;
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
	}

	if(GetAttribute(CWeapon, "apply look velocity on damage", 0.0) == 2)
	{
		jarateWeapon[entity] = EntIndexToEntRef(CWeapon)
		SDKHook(entity, SDKHook_StartTouchPost, ExplosiveArrowCollision);
	}
}
disableWeapon(client)
{
	int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", currentGameTime + 1.0);
}
StunShotFunc(client)
{
	int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetEntPropFloat(CWeapon, Prop_Send, "m_flNextPrimaryAttack", currentGameTime + 0.6);
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
	if(IsValidEntity(entity) && currentGameTime - entitySpawnTime[entity] > 0.4)
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

		currentDamageType[attacker].second |= DMG_PIERCING;
		currentDamageType[attacker].second |= DMG_IGNOREHOOK;
		SDKHooks_TakeDamage(victim, attacker, attacker, GetClientHealth(victim)*0.35, DMG_PREVENT_PHYSICS_FORCE);

		Buff radiation;
		radiation.init("Radiation", "", Buff_Radiation, 1, attacker, 8.0);
		radiation.multiplicativeDamageTaken = 2.0;
		radiation.multiplicativeAttackSpeedMult = 0.66;
		insertBuff(victim, radiation);
		
		float particleOffset[3] = {0.0,0.0,10.0};
		CreateParticle(victim, "utaunt_electricity_cloud_electricity_WY", true, _, 8.0, particleOffset);
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
		currentDamageType[attacker].second |= DMG_PIERCING;
		currentDamageType[attacker].second |= DMG_FROST;
		currentDamageType[attacker].second |= DMG_IGNOREHOOK;
		SDKHooks_TakeDamage(victim, attacker, attacker, GetClientHealth(victim)*0.2, DMG_PREVENT_PHYSICS_FORCE);
		SetEntityRenderColor(victim, 0, 128, 255, 80);
		SetEntityMoveType(victim, MOVETYPE_NONE);
	}
}
checkBleed(int victim,int attacker, int weapon = -1, float overrideDamage = 0.0){
	float bleedBonus = 1.0;
	Address vampirePowerupAttacker = TF2Attrib_GetByName(attacker, "unlimited quantity");
	if(vampirePowerupAttacker != Address_Null && TF2Attrib_GetValue(vampirePowerupAttacker) > 0.0)
	{
		bleedBonus += 0.25;
	}

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
		
		currentDamageType[attacker].second |= DMG_IGNOREHOOK;
		SDKHooks_TakeDamage(victim, attacker, attacker, damage, DMG_PREVENT_PHYSICS_FORCE,_,_,_,false);


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

	int melee = GetWeapon(owner,2);
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
					if(IsValidEdict(logic))
					{
						int round = GetEntProp(logic, Prop_Send, "m_nMannVsMachineWaveCount");
						TankSentryDamageMod = Pow((waveToCurrency[round]/11000.0), DamageMod + (round * 0.03)) * 1.8 * OverallMod;
					}
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
		if(IsValidClient3(client) && canOverride[client])
		{
			canOverride[client] = false;
			int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEdict(CWeapon))
			{
				int iItemDefinitionIndex = GetEntProp(CWeapon, Prop_Send, "m_iItemDefinitionIndex");
				switch(iItemDefinitionIndex)
				{
					case 222:
					{
						SetEntityModel(entity, "models/weapons/c_models/c_madmilk/c_madmilk.mdl");
						ApplyJarChanges(entity, CWeapon, 1);
					}
					case 1121:
					{
						SetEntityModel(entity, "models/weapons/c_models/c_breadmonster/c_breadmonster_milk.mdl");
						ApplyJarChanges(entity, CWeapon, 1);
					}
					case 58,1149:
					{
						SetEntityModel(entity, "models/weapons/c_models/urinejar.mdl");
						ApplyJarChanges(entity, CWeapon, 0);
					}
					case 1105:
					{
						SetEntityModel(entity, "models/weapons/c_models/c_breadmonster/c_breadmonster.mdl");
						ApplyJarChanges(entity, CWeapon, 0);
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
				int melee = GetWeapon(owner,2);
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
/*TeleportToNearestPlayer(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEdict(entity))
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
public int getClientParticleStatus(int array[MAXPLAYERS+1], int client){
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
public void OnHomingThink(entity) 
{ 
	if(!IsValidEntity(entity))
		return;

	int owner = getOwner(entity);
	if(!IsValidClient3(owner))
		return;

	int Target = GetClosestTarget(entity, owner); 
	if(!IsValidClient3(Target))
		return;

	int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
	if(!IsValidWeapon(CWeapon))
		return;

	float TargetPos[3];
	GetClientAbsOrigin(Target, TargetPos);
	TargetPos[2]+=40.0;
	float flRocketPos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", flRocketPos);
	float distance = GetVectorDistance(flRocketPos, TargetPos, true); 
	
	if( distance <= projectileHomingDegree[entity]*projectileHomingDegree[entity] && currentGameTime - entitySpawnTime[entity] < 3.0 )
	{
		float ProjVector[3],BaseSpeed,NewSpeed,ProjAngle[3],AimVector[3],InitialSpeed[3]; 
		
		GetEntPropVector( entity, Prop_Send, "m_vInitialVelocity", InitialSpeed ); 
		if ( GetVectorLength( InitialSpeed ) < 10.0 ) GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", InitialSpeed ); 
		BaseSpeed = GetVectorLength( InitialSpeed ) * 0.3; 
		
		GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", flRocketPos ); 
		GetClientAbsOrigin( Target, TargetPos ); 
		TargetPos[2] += 45.0;
		MakeVectorFromPoints( flRocketPos, TargetPos, AimVector ); 
		
		if(distance <= projectileHomingDegree[entity]*projectileHomingDegree[entity]*2.0 + 20.0)
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
		
		NewSpeed = ( BaseSpeed * 2.0 ) + 1.0 * BaseSpeed; 
		ScaleVector( ProjVector, NewSpeed ); 
		
		TeleportEntity( entity, NULL_VECTOR, ProjAngle, ProjVector ); 
	}
}
public OnAimlessThink(entity){
	if(!IsValidEdict(entity))
		return;
		
	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));

	float ProjAngle[3], ProjVector[3], ProjVelocity[3];
	GetEntPropVector( entity, Prop_Data, "m_angRotation", ProjAngle ); 
	ProjAngle[1] += GetRandomFloat(-5.0, 5.0);

	GetEntPropVector( entity, Prop_Send, "m_vInitialVelocity", ProjVelocity ); 
	if ( GetVectorLength( ProjVelocity ) < 10.0 )
		GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", ProjVelocity ); 

	GetAngleVectors(ProjAngle, ProjVector, NULL_VECTOR, NULL_VECTOR);

	ScaleVector(ProjVector, GetVectorLength(ProjVelocity));

	TeleportEntity( entity, NULL_VECTOR, ProjAngle, ProjVector ); 
}
public OnThinkPost(entity) 
{ 
	if(!IsValidEdict(entity))
		return;

	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(!IsValidClient3(owner))
		return;

	int Target = GetClosestTarget(entity, owner); 
	if(!IsValidClient3(Target))
		return;

	int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
	if(!IsValidWeapon(CWeapon))
		return;

	Address homingActive = TF2Attrib_GetByName(CWeapon, "crit from behind");
	if(homingActive == Address_Null)
		return;

	if(owner != Target)
	{
		float flTargetPos[3];
		GetClientAbsOrigin(Target, flTargetPos);
		flTargetPos[2]+=40.0;
		float flRocketPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", flRocketPos);
		float distance = GetVectorDistance(flRocketPos, flTargetPos, true); 
		
		if( distance <= TF2Attrib_GetValue(homingActive)*TF2Attrib_GetValue(homingActive) )
		{
			float flVelocityChange[3];
			TeleportEntity(entity, flTargetPos, NULL_VECTOR, flVelocityChange);
		}
	}
}
public SetWeaponOwner(entity){
	entity = EntRefToEntIndex(entity);
	if(!IsValidEdict(entity))
		return;
	int owner = getOwner(entity);
	if(!IsValidClient3(owner))
		return;
	int CWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
	if(!IsValidWeapon(CWeapon))
		return;
	jarateWeapon[entity] = CWeapon;
}
public getProjOrigin(entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEdict(entity))
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entitySpawnPositions[entity]);
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

	int owner = getOwner(entity);
	if(!IsValidClient3(owner) && IsValidEdict(owner) && HasEntProp(owner,Prop_Send,"m_hBuilder"))
		owner = GetEntPropEnt(owner,Prop_Send,"m_hBuilder" );

	if (!IsValidClient3(owner))
		return;

	int Target = GetClosestTarget(entity, owner); 
	if(!IsValidClient3(Target) || owner == Target)
		return;

	float EntityPos[3], TargetPos[3]; 
	GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityPos ); 
	GetClientAbsOrigin( Target, TargetPos ); 
	
	if( GetVectorDistance(EntityPos, TargetPos, true) > homingRadius[entity]*homingRadius[entity] )
		return;

	if(homingTickRate[entity] == 0 || homingTicks[entity] % homingTickRate[entity] == 0)
	{
		float ProjLocation[3], ProjVector[3], BaseSpeed, NewSpeed, ProjAngle[3], AimVector[3], InitialSpeed[3]; 
		
		GetEntPropVector( entity, Prop_Send, "m_vInitialVelocity", InitialSpeed ); 
		if ( GetVectorLength( InitialSpeed ) < 10.0 ) GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", InitialSpeed ); 
		BaseSpeed = GetVectorLength( InitialSpeed ) * 0.333; 
		
		GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", ProjLocation ); 
		switch(homingAimStyle[entity])
		{
			case 1:
			{
				GetClientEyePosition( Target, TargetPos ); 
			}
			default:
			{
				GetClientAbsOrigin( Target, TargetPos ); 
				TargetPos[2] += 20.0;
			}
		}
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
		SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", velocity);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 3.0);
	}
}
CheckGrenadeMines(ref)
{
	int entity = EntRefToEntIndex(ref); 
	if(IsValidEdict(entity) && HasEntProp(entity, Prop_Data, "m_hThrower"))
    {
        int client = GetEntPropEnt(entity, Prop_Data, "m_hThrower"); 
        if (IsValidClient3(client) && IsPlayerAlive(client))
		{
			int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEdict(CWeapon))
			{
				Address minesActive = TF2Attrib_GetByName(CWeapon, "enables aoe heal");
				if(minesActive != Address_Null && TF2Attrib_GetValue(minesActive) < 0)
				{
					float damage = 90.0 * TF2_GetDamageModifiers(client,CWeapon);
					float radius = 100.8;
					CreateTimer(0.04,Timer_PlayerGrenadeMines, ref, TIMER_REPEAT);
					CreateTimer(TF2Attrib_GetValue(minesActive) * -3.0,SelfDestruct, ref);
					
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
				if(IsValidEdict(CWeapon))
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
		int client = getOwner(entity);
		if(IsValidClient3(client))
		{
			Address precisionPowerup = TF2Attrib_GetByName(client, "precision powerup");
			if(precisionPowerup == Address_Null) return;

			if(TF2Attrib_GetValue(precisionPowerup) == 1)
				projectileHomingDegree[entity] = 200.0;
			else if(TF2Attrib_GetValue(precisionPowerup) == 2)
				if(!Phys_IsPhysicsObject(entity))
					isAimlessProjectile[entity] = true;
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
				GetEntityClassname( entity, strClassname, sizeof(strClassname) );

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
			CPrintToChat(client, "{community}Dexterity Powerup {default}| {lightcyan}As your firerate increases (up to 66/s), you deal up to 3x damage.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Bruised Powerup {default}| {lightcyan}Tagged enemies will be hit with a finisher that is a crit + deals 25%% maxHP. Hits above 40%% maxHP instantly kill for -5%% of your health.");
		}else{
			CPrintToChat(client, "{community}Strength Powerup {default}| {lightcyan}2x damage & consistent damage.");
		}
	}
	else if(StrEqual("resistance powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Fray Powerup {default}| {lightcyan}Every 3s, avoid one hit taken. Refreshed on kill. +20%% movement speed.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Stronghold Powerup {default}| {lightcyan}1/2x damage taken, middle click to enter stronghold, completely immobilizing you but giving crit and status immunities with 1.33x healing. Nearby teammates get stronghold bonus.");
		}else{
			CPrintToChat(client, "{community}Resistance Powerup {default}| {lightcyan}1/2x damage taken. Immunity to crit.");
		}
	}
	else if(StrEqual("vampire powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Leech Powerup {default}| {lightcyan}30%% lifesteal, drains healing of everyone (including teammates!) by 50%% if nearby. Also applies on hitting an enemy.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Bloodbound Powerup {default}| {lightcyan}-100%% lifesteal, 75%% damage taken -> piercing damage dealt. No fatal damage from self. If fatal damage, refill HP with bonus damage dealt.");
		}else{
			CPrintToChat(client, "{community}Vampire Powerup {default}| {lightcyan}80%% lifesteal, 1.25x bleed damage, and 0.75x damage taken.");
		}
	}
	else if(StrEqual("precision powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Aimless Powerup {default}| {lightcyan}Projectiles randomly sway and deal up to +300%% damage based on distance of landing. Note that only projectiles that sway deal extra damage.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Railgun Powerup {default}| {lightcyan}All weapons have 4x slower fire rate, but 4x damage.");
		}else{
			CPrintToChat(client, "{community}Precision Powerup {default}| {lightcyan}+100%% projectile speed, charge rate, and no spread. 1.35x damage and hitscan can headshot. Certain projectiles will home aggressively.");
		}
	}
	else if(StrEqual("regeneration powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Duplication Powerup {default}| {lightcyan}Shift middle click to double current HP (2x overheal max, 10s cd). All weapons have infinite clip.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Redistribution Powerup {default}| {lightcyan}-8%% maxHPR, but health drained goes into a health pool, which dealing damage gives back (can overheal & heals nearby teammates). 1.6x all healing.");
		}else{
			CPrintToChat(client, "{community}Regeneration Powerup {default}| {lightcyan}0.75x damage taken, +10%% max HPR. 100%% ammo regeneration.");
		}
	}
	else if(StrEqual("revenge powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Berserk Powerup {default}| {lightcyan}Revenge instead becomes passive that drains by -7%%/s. Up to 1.5x healing effectiveness when meter is at 100%%. Effects are scaled to %%.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Enraged Powerup {default}| {lightcyan}Every kill gives +6%% pctHP healing. Every 80 kills, you can turn enraged, which gives:\n+100%% fire rate, full crits, and 0.4x damage taken.");
		}else{
			CPrintToChat(client, "{community}Revenge Powerup {default}| {lightcyan}66%% of damage taken is filled to revenge meter. 0.8x damage taken. On activation: +50%% dmg and full crits.");
		}
	}
	else if(StrEqual("agility powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Quaker Powerup {default}| {lightcyan}Weighdown is automatically activated after jumping. Stomp damage is spread to 2 other targets. 2x jump height. Damage is increased by +0.1%% times downward velocity.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Warp Powerup {default}| {lightcyan}Replaces shift middle click with teleport to crosshair. Deals 1200 base damage to all enemies through path of teleport. Each use consumes 10%% focus. Applies +4 additive dmg taken on teleport hit.");
		}else{
			CPrintToChat(client, "{community}Agility Powerup {default}| {lightcyan}1.5x reload & fire rate. infinite jumps, speed boost, 1.4x speed, 1.3x jump height, 1.75x self push force, immunity to crowd control effects, and 35%% dodge chance.");
		}
	}
	else if(StrEqual("knockout powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Tainted Blade Powerup {default}| {lightcyan}Incoming damage is multiplied by 0.66x. Melee buildup debuffs are multiplied by 3x and DOTs deal 5x dmg. Secondary ailment effects are 3x effective.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Assassin Powerup {default}| {lightcyan}When enemy has not taken damage from you: Melee damage crits and is multiplied by 4x.");
		}else{
			CPrintToChat(client, "{community}Knockout Powerup {default}| {lightcyan}Melee damage is multiplied by 1.75x, and incoming damage by 0.8x. Damage causes concussion buildup. Victims with CC immunity take minicrits.");
		}
	}
	else if(StrEqual("king powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Tag-Team Powerup {default}| {lightcyan}Press RELOAD to link yourself to a teammate:\n Giving both of you 1.4x damage. Healing is shared between both of you and attacking an enemy makes the other linked person deal 1.75x vs that victim.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Martyr Powerup {default}| {lightcyan}-66%% healing from all sources. Sacrifice (15%% max health + dmg taken) to absorb fatal teammate damage and give uber for 0.5s.");
		}else{
			CPrintToChat(client, "{community}King Powerup {default}| {lightcyan}1.33x reload and fire rate, 1.5x uber and heal rate, and 1.2x dmg for teammates and you. 0.8x damage taken.");
		}
	}
	else if(StrEqual("plague powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Decay Powerup {default}| {lightcyan}Deals 100 + 2%% currentHP piercing DPS & slowly inflicts radiation to nearby enemies. Applies 0.25x healing to victims of decay. 0.75x damage taken.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Life Link Powerup {default}| {lightcyan}Hitting an enemy will proc life link: Instantly deals 30%% currentHP%% to you, but drains 35%% currentHP%% of enemy over time. At end of duration, your team is healed by damage dealt to yourself.");
		}else{
			CPrintToChat(client, "{community}Plague Powerup {default}| {lightcyan}Steals all healthpacks nearby, giving 25%% max health heal. Enemies nearby will be plagued for 12s, weakening damage dealt by them by 0.5x. 0.75x incoming damage taken.");
		}
	}
	else if(StrEqual("supernova powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Infernal Powerup {default}| {lightcyan}Fire damage spreads around 100 piercing DPS to nearby enemies. 1.8x fire damage. 1.5x afterburn tick rate. All attacks ignite.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Thunderstorm Powerup {default}| {lightcyan}All damage is converted into electric damage (hit enemies recieve splash to other hit enemies). For every enemy tagged: +8%% damage.");
		}else{
			CPrintToChat(client, "{community}Supernova Powerup {default}| {lightcyan}0.8x damage taken. If Splash Damage:\n1.8x damage.\nElse:\n1.35x damage dealt and splashes with falloff.\nDamage taken -> Supernova meter.\n On proc: Stuns nearby enemies for 6s & buildings for 10s.");
		}
	}
	else if(StrEqual("inverter powerup", name)){
		if(amount == 2){
			CPrintToChat(client, "{community}Conductor Powerup {default}| {lightcyan}0.5x incoming damage taken. Amplifies the effects of ailments (eg: jarate -> crit jarate). Attacks will apply the amplified ailment while active.");
		}else if(amount == 3){
			CPrintToChat(client, "{community}Insulator Powerup {default}| {lightcyan}Nullifies all ailments and buffs (You do not recieve any buffs or ailments, and cancel enemy buffs on hit).");
		}else{
			CPrintToChat(client, "{community}Inverter Powerup {default}| {lightcyan}0.8x incoming damage taken. Flips the effects of ailments (eg: jarate -> battalion's backup)");
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
instantProjectile(entity) 
{
    if(IsValidEdict(entity)) 
    { 
		int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient(client))
		{
			int ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEdict(ClientWeapon))
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
	if(IsValidEdict(entity))
	{
		int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient3(client))
		{
			int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEdict(CWeapon))
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
	if(IsValidEdict(entity))
	{
		int inflictor = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		int client;
		if(!IsValidClient3(inflictor) && IsValidEdict(inflictor) && HasEntProp(inflictor,Prop_Send,"m_hBuilder"))
		{
			client = GetEntPropEnt(inflictor, Prop_Send, "m_hBuilder");
			if(IsValidClient3(client))
			{
				int melee = (GetPlayerWeaponSlot(client,2));
				if(IsValidEdict(melee))
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
stock bool PenetrationCallTrace(int entity, int contentsMask, any data) {
	if(entity != 0 && IsValidEntity(entity) && IsValidForDamage(entity) && IsOnDifferentTeams(entity,data)){
		isPenetrated[entity] = true;
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
		currentGameTime = 0.0;
		efficiencyCalculationTimer[client] = 0.0;
		DamageDealt[client] = 0.0;
		dps[client] = 0.0;
		Healed[client] = 0.0;
		MenuTimer[client] = 0.0;
		ImpulseTimer[client] = 0.0;
		g_flLastAttackTime[client] = 0.0;
		RPS[client] = 0.0;
		lastMinesTime[client] = 0.0;
		weaponTrailTimer[client] = 0.0;
		disableIFMiniHud[client] = 0.0;
		fl_GlobalCoolDown[client] = 0.0;
		weaponArtCooldown[client] = 0.0;
		weaponArtParticle[client] = 0.0;
		powerupParticle[client] = 0.0;
		BotTimer[client] = 0.0;
		LastCharge[client] = 0.0;
		//lastDamageTaken[client] = 0.0;
		flNextSecondaryAttack[client] = 0.0;
		CurrentSlowTimer[client] = 0.0;
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
	}
	for(int entity = 0; entity<MAXENTITIES; entity++){
		currentDamageType[entity].clear();
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
			CPrintToChatAll("{valve}Incremental Fortress {white}| You have reached the 2nd stage! New upgrades unlocked.");
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
		if(IsValidClient3(entity) && IsPlayerAlive(entity) && IsOnDifferentTeams(entity, data)){
			float damageBoost = TF2_GetDamageModifiers(data, GetEntPropEnt(data, Prop_Send, "m_hActiveWeapon"), true, true, false);
			currentDamageType[data].second |= DMG_IGNOREHOOK;
			SDKHooks_TakeDamage(entity,data,data,damageBoost*1200.0,DMG_CLUB|DMG_CRUSH,GetEntPropEnt(data, Prop_Send, "m_hActiveWeapon"),_,_,false);

			Buff jarateDebuff; jarateDebuff.init("Jarated", "", Buff_Jarated, 4*RoundToNearest(damageBoost), data, 8.0);
			insertBuff(entity, jarateDebuff);
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
				weaponDPS = 170.0;
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
				weaponDPS = 70.0;
				
				Address corrosiveElement = TF2Attrib_GetByName(weapon, "building cost reduction");
				if(corrosiveElement != Address_Null)
				{
					weaponDPS += 14.5*TF2Attrib_GetValue(corrosiveElement);
				}
				Address jarFragsToggle = TF2Attrib_GetByName(weapon, "overheal decay penalty");
				if(jarFragsToggle != Address_Null)
				{
					weaponDPS += 10.0*TF2Attrib_GetValue(jarFragsToggle);
					
					Address fragmentExplosion = TF2Attrib_GetByName(weapon, "overheal decay bonus");
					if(fragmentExplosion != Address_Null && TF2Attrib_GetValue(fragmentExplosion) > 0.0)
					{
						weaponDPS += TF2Attrib_GetValue(fragmentExplosion)*0.5*TF2Attrib_GetValue(jarFragsToggle);
					}
				}
				
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
				if(StrEqual(Classname,"tf_weapon_scattergun",false) || StrEqual(Classname,"tf_weapon_soda_popper",false) || StrEqual(Classname,"tf_weapon_pep_brawler_blaster",false) || StrEqual(Classname,"tf_weapon_shotgun",false) || 
				StrEqual(Classname,"tf_weapon_shotgun_primary",false) || StrEqual(Classname,"tf_weapon_sentry_revenge",false) || StrEqual(Classname,"tf_weapon_shotgun_building_rescue",false))
					aps = 1.6;
				else if(StrEqual(Classname,"tf_weapon_handgun_scout_primary",false))
					aps = 2.857;
				else if(StrEqual(Classname,"tf_weapon_pistol",false) || StrEqual(Classname,"tf_weapon_handgun_scout_secondary",false))
					aps = 6.67;
				else if(StrEqual(Classname,"tf_weapon_cleaver",false))
					aps = 1.25;
				else if(StrEqual(Classname,"tf_weapon_rocketlauncher",false) || StrEqual(Classname,"tf_weapon_rocketlauncher_directhit",false) || StrEqual(Classname,"tf_weapon_particle_cannon",false) || StrEqual(Classname,"tf_weapon_rocketlauncher_airstrike",false))
					aps = 1.25;
				else if(StrEqual(Classname,"tf_weapon_raygun",false) || StrEqual(Classname,"tf_weapon_drg_pomson",false))
					aps = 1.25;
				else if(StrEqual(Classname,"tf_weapon_shovel",false) || StrEqual(Classname,"saxxy",false) || StrEqual(Classname,"tf_weapon_fireaxe",false) || StrEqual(Classname,"tf_weapon_slap",false) || StrEqual(Classname,"tf_weapon_sword",false) ||
				StrEqual(Classname,"tf_weapon_bottle",false) || StrEqual(Classname,"tf_weapon_stickbomb",false) || StrEqual(Classname,"tf_weapon_katana",false) || StrEqual(Classname,"tf_weapon_fists",false) || StrEqual(Classname,"tf_weapon_wrench",false) ||
				StrEqual(Classname,"tf_weapon_robot_arm",false) || StrEqual(Classname,"tf_weapon_bonesaw",false) || StrEqual(Classname,"tf_weapon_club",false) || StrEqual(Classname,"tf_weapon_breakable_sign",false))
					aps = 1.25;
				else if(StrEqual(Classname,"tf_weapon_bat",false) || StrEqual(Classname,"tf_weapon_bat_wood",false) || StrEqual(Classname,"tf_weapon_bat_fish",false) || StrEqual(Classname,"tf_weapon_bat_giftwrap",false))
					aps = 2.0;
				else if(StrEqual(Classname,"tf_weapon_flamethrower",false))
					aps = 25.0;
				else if(StrEqual(Classname,"tf_weapon_rocketlauncher_fireball",false))
					aps = 1.25;
				else if(StrEqual(Classname,"tf_weapon_jar_gas",false) || StrEqual(Classname,"tf_weapon_jar",false) || StrEqual(Classname,"tf_weapon_jar_milk",false))
					aps = 1.25;
				else if(StrEqual(Classname,"tf_weapon_flaregun",false) || StrEqual(Classname,"tf_weapon_flaregun_revenge",false))
					aps = 0.5;
				else if(StrEqual(Classname,"tf_weapon_grenadelauncher",false) || StrEqual(Classname,"tf_weapon_cannon",false))
					aps = 1.67;
				else if(StrEqual(Classname,"tf_weapon_pipebomblauncher",false))
					aps = 1.67;
				else if(StrEqual(Classname,"tf_weapon_minigun",false))
					aps = 10.0;
				else if(StrEqual(Classname,"tf_weapon_syringegun_medic",false) || StrEqual(Classname,"tf_weapon_syringegun",false))
					aps = 10.0;
				else if(StrEqual(Classname,"tf_weapon_compound_bow",false))
					aps = 0.5;
				else if(StrEqual(Classname,"tf_weapon_crossbow",false))
					aps = 4.35;
				else if(StrEqual(Classname,"tf_weapon_sniperrifle",false) || StrEqual(Classname,"tf_weapon_sniperrifle_decap",false) || StrEqual(Classname,"tf_weapon_sniperrifle_classic",false))
					aps = 0.67;
				else if(StrEqual(Classname,"tf_weapon_smg",false) || StrEqual(Classname,"tf_weapon_charged_smg",false))
					aps = 10.0;
				else if(StrEqual(Classname,"tf_weapon_revolver",false))
					aps = 2.0;
				else if(StrEqual(Classname,"tf_weapon_mechanical_arm",false))
					aps = 6.7;
				else
					aps = 1.0;
				
				aps /= TF2Attrib_HookValueFloat(1.0, "mult_postfiredelay", weapon);
				Address apsMult5 = TF2Attrib_GetByName(weapon, "halloween fire rate bonus");
				Address apsMult6 = TF2Attrib_GetByName(weapon, "mult_item_meter_charge_rate");
				Address apsMod = TF2Attrib_GetByName(weapon, "energy weapon penetration");
				//If their weapon doesn't have a clip, reload rate also affects fire rate.
				if(HasEntProp(weapon, Prop_Data, "m_iClip1") && GetEntProp(weapon,Prop_Data,"m_iClip1")  == -1)
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
				
				if(TF2_IsPlayerInCondition(client, TFCond_HalloweenSpeedBoost))
					aps *= 1.5 * efficiency;
				
				Address apsAdd = TF2Attrib_GetByName(weapon, "auto fires full clip all at once");
				if(apsAdd != Address_Null)
					aps = 22.0
				
				
				return aps;
			}
		}
	}
	return 1.0;
}
stock float TF2_GetSentryDamageModifiers(client, melee){
	float dmgBonus = 1.0;
	int CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidWeapon(CWeapon))
	{
		Address SentryDmgActive = TF2Attrib_GetByName(CWeapon, "ring of fire while aiming");
		if(SentryDmgActive != Address_Null)
		{
			dmgBonus *= TF2Attrib_GetValue(SentryDmgActive);
		}
	}
	Address SentryDmgActive1 = TF2Attrib_GetByName(melee, "throwable detonation time");
	if(SentryDmgActive1 != Address_Null)
		dmgBonus *= TF2Attrib_GetValue(SentryDmgActive1);
	
	Address SentryDmgActive2 = TF2Attrib_GetByName(melee, "throwable fire speed");
	if(SentryDmgActive2 != Address_Null)
		dmgBonus *= TF2Attrib_GetValue(SentryDmgActive2);
	
	Address damageActive = TF2Attrib_GetByName(melee, "ubercharge");
	if(damageActive != Address_Null)
		dmgBonus *= Pow(1.05,TF2Attrib_GetValue(damageActive));
	
	Address damageActive2 = TF2Attrib_GetByName(melee, "engy sentry damage bonus");
	if(damageActive2 != Address_Null)
		dmgBonus *= TF2Attrib_GetValue(damageActive2);

	Address damageActive3 = TF2Attrib_GetByName(melee, "sentry bullets per shot");
	if(damageActive3 != Address_Null)
		dmgBonus *= TF2Attrib_GetValue(damageActive3);
	
	return dmgBonus;
}
stock float TF2_GetSentryDPSModifiers(client, melee){
	float dmgBonus = TF2_GetSentryDamageModifiers(client,melee);
	Address fireRateActive = TF2Attrib_GetByName(melee, "engy sentry fire rate increased");
	if(fireRateActive != Address_Null)
		dmgBonus /= TF2Attrib_GetValue(fireRateActive);
	
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
	
	SentryDPS *= TF2_GetSentryDPSModifiers(client, melee);

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
			dpsMult /= GetAttribute(weapon, "halloween fire rate bonus");
			dpsMult /= GetAttribute(weapon, "mult_item_meter_charge_rate");
			//If their weapon doesn't have a clip, reload rate also affects fire rate.
			if(CountReloadModifiers)
			{
				if(HasEntProp(weapon, Prop_Data, "m_iClip1") && GetEntProp(weapon,Prop_Data,"m_iClip1")  == -1)
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
			if(TF2_IsPlayerInCondition(client, TFCond_HalloweenSpeedBoost))
			{
				dpsMult *= 1.5;
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
		if(IsValidEdict(weapon))
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

			dpsMult *= GetAttribute(weapon, "mult projectile count", 1.0);

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
					dpsMult *= 3.0;
				}
				else if(TF2_IsPlayerMinicritBuffed(client))
				{
					dpsMult *= 1.35;
				}
				if(TF2_IsPlayerInCondition( client, TFCond_RuneStrength ))
				{
					dpsMult *= 2.0;
				}
				if(TF2_IsPlayerInCondition( client, TFCond_RunePrecision ))
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