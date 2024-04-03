/*
Yeah.
 */
#include <sdkhooks>
#include <tf2attributes>
#include <tf_econ_data>
#include <tf2utils>
#pragma tabsize 0
#define ExplosionSound1 "weapons/explode1.wav"
#define ExplosionSound2 "weapons/explode2.wav"
#define ExplosionSound3 "weapons/explode3.wav"
#define SmallExplosionSound1 "weapons/airstrike_small_explosion_01.wav"
#define SmallExplosionSound2 "weapons/airstrike_small_explosion_02.wav"
#define SmallExplosionSound3 "weapons/airstrike_small_explosion_03.wav"
#define DetonatorExplosionSound "weapons/flare_detonator_explode.wav"
#define OrnamentExplosionSound "weapons/ball_buster_break_01.wav"
#define MAXENTITIES 2049
#define PI 3.142

//First
#define DMG_ACTUALIGNITE 1 << 30

//Second
#define DMG_PIERCING 1 << 1
#define DMG_ARCANE 1 << 2
#define DMG_MINICRIT 1 << 3
#define DMG_ACTUALCRIT 1 << 4
#define DMG_FROST 1 << 5

//Uber Stuff
#define UBER_INVULN 1 << 0
#define UBER_CRIT 1 << 1
#define UBER_MEGAHEAL 1 << 2
#define UBER_HASTE 1 << 3
#define UBER_DEFENSE 1 << 4
#define UBER_SPEED 1 << 5

#define GetWeapon TF2Util_GetPlayerLoadoutEntity

bool DOTStacked[MAXENTITIES][MAXENTITIES];
bool ShouldNotHome[MAXENTITIES][MAXPLAYERS+1];
bool ShouldNotHit[MAXENTITIES][MAXENTITIES];

stock bool IsValidClient(client)
{
    if ( client <= 0 || client > MaxClients ) return false; 
	if ( !IsClientInGame(client) ) return false;
    if ( IsFakeClient( client ) ) return false; 
	
    return true; 
}
stock bool IsValidClient3(client)
{
    if ( client <= 0 || client > MaxClients ) return false; 
	if ( !IsClientInGame(client) ) return false;
    return true; 
}
stock bool IsValidForDamage(entity)
{
    if (!IsValidEdict(entity)) return false; 
	if(IsValidClient3(entity) && (!IsPlayerAlive(entity) || IsClientObserver(entity))) return false;	
	if(HasEntProp(entity, Prop_Data, "m_hActiveWeapon")) return true;
	if(GetEntProp(entity, Prop_Data, "m_takedamage") == 0) return false;
    return false; 
}
stock int IntAbs(int val)
{
   return (val < 0) ? -val : val;
} 
stock bool IsOnDifferentTeams(entity1,entity2)
{
	int iTeam = -10;
	if(HasEntProp(entity1, Prop_Send, "m_iTeamNum"))
	{
		iTeam = GetEntProp(entity1, Prop_Send, "m_iTeamNum");
	}
	int team = -10;
	if(HasEntProp(entity2, Prop_Send, "m_iTeamNum"))
	{
		team = GetEntProp(entity2, Prop_Send, "m_iTeamNum");
	}
	if(team != -10)
	{
		if(!(team == 2 || team == 3))//They have a valid team, but it's not on red or blue.
		{
			if(IsValidClient3(entity2) && IsClientObserver(entity2))
			{
				return false;
			}
			return true;
		}
	}
	if(team != iTeam)
	{
		return true;
	}
	
    return false; 
}
stock float GetAttribute(int entity, const char[] attrName, float value = 1.0)
{
	Address attribute_address = TF2Attrib_GetByName(entity, attrName);
	if(attribute_address != Address_Null)
		value = TF2Attrib_GetValue(attribute_address);

	return value;
}
stock float GetAttributeAccumulateAdditive(int client, const char[] attrName, float value = 1.0)
{
	Address attribute_address = TF2Attrib_GetByName(client, attrName);
	if(attribute_address != Address_Null)
		value += TF2Attrib_GetValue(attribute_address);

	int weapon;
	for(int i=0;i<3;++i)
	{
		weapon = GetWeapon(client,i);
		if(!IsValidWeapon(weapon))
			continue;

		char sClass[32];
		GetEntityClassname(weapon, sClass, sizeof(sClass));

		if(StrContains(sClass,"tf_wearable") == -1
		&& StrContains(sClass,"tf_weapon_parachute") == -1)
			continue;

		Address temp_attribute_address = TF2Attrib_GetByName(weapon, attrName);
		if(temp_attribute_address != Address_Null)
			value += TF2Attrib_GetValue(temp_attribute_address);
		
	}
	weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidWeapon(weapon))
	{
		Address temp_attribute_address = TF2Attrib_GetByName(weapon, attrName);
		if(temp_attribute_address != Address_Null)
			value *= TF2Attrib_GetValue(temp_attribute_address);
	}
	return value;
}
stock float GetAttributeAccumulateMultiplicative(int client, const char[] attrName, float value = 1.0)
{
	Address attribute_address = TF2Attrib_GetByName(client, attrName);
	if(attribute_address != Address_Null)
		value *= TF2Attrib_GetValue(attribute_address);

	int weapon;

	for(int i=0;i<3;++i)
	{
		weapon = GetWeapon(client,i);
		if(!IsValidWeapon(weapon))
			continue;

		char sClass[32];
		GetEntityClassname(weapon, sClass, sizeof(sClass));

		if(StrContains(sClass,"tf_wearable") == -1
		&& StrContains(sClass,"tf_weapon_parachute") == -1)
			continue;

		Address temp_attribute_address = TF2Attrib_GetByName(weapon, attrName);
		if(temp_attribute_address != Address_Null)
			value *= TF2Attrib_GetValue(temp_attribute_address);

	}
	weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidWeapon(weapon))
	{
		Address temp_attribute_address = TF2Attrib_GetByName(weapon, attrName);
		if(temp_attribute_address != Address_Null)
			value *= TF2Attrib_GetValue(temp_attribute_address);
	}
	return value;
}
stock bool IsValidWeapon(int entity)
{
	return (entity > 0 && IsValidEdict(entity) && HasEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"));
}
stock int getOwner(int entity)
{
	if(HasEntProp(entity, Prop_Data, "m_hThrower"))
		return GetEntPropEnt(entity, Prop_Data, "m_hThrower");
	else if(HasEntProp(entity, Prop_Data, "m_hOwnerEntity"))
	 	return GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	return -1;
}

stock int getWeaponSlot(int client, int entity)
{
	return TF2Econ_GetItemLoadoutSlot(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"),TF2_GetPlayerClass(client));
}
stock void GetCleaverAngularImpulse(float vecAngImpulse[3]) {
	vecAngImpulse[0] = 0.0;
	vecAngImpulse[1] = 1000.0;
	vecAngImpulse[2] = 0.0;
}
stock int CreateLink(int iClient, bool attach=false)
{
	int iLink = CreateEntityByName("tf_taunt_prop");
	DispatchKeyValue(iLink, "targetname", "TankLink");
	DispatchSpawn(iLink); 
	
	char strModel[PLATFORM_MAX_PATH];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", strModel, PLATFORM_MAX_PATH);
	
	SetEntityModel(iLink, strModel);
	
	SetEntProp(iLink, Prop_Send, "m_fEffects", 16|64);
	
	SetVariantString("!activator"); 
	AcceptEntityInput(iLink, "SetParent", iClient); 
	
	if(attach)
	{
		SetVariantString("head");
		AcceptEntityInput(iLink, "SetParentAttachment", iClient);
	}
	
	SetEntProp(iLink, Prop_Send, "m_nSolidType", 0);
	SetEntProp(iLink, Prop_Send, "m_usSolidFlags", 0x0004);
	
	return iLink;
}
stock PushEntity(int entity, int client, float strength=10.0, float heightOverride=0.0)
{
    if(IsValidEdict(entity))
    {
        // get positions of both entity and client 
        float pos1[3], pos2[3];
        GetClientAbsOrigin(client, pos1);
        GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos2);
		pos2[2]+=heightOverride;	
		
        // create push velocity
        float vPush[3];
        MakeVectorFromPoints(pos1, pos2, vPush);
        NormalizeVector(vPush, vPush);
        ScaleVector(vPush, strength);

        // push entity
        TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vPush);
    }
} 
stock Entity_Create(const char[] className, ForceEdictIndex=-1)
{
	if (ForceEdictIndex != -1 && Entity_IsValid(ForceEdictIndex)) {
		return INVALID_ENT_REFERENCE;
	}

	return CreateEntityByName(className, ForceEdictIndex);
}
stock Entity_PointHurtAtTarget(entity, target, const char[] name="")
{
	char targetName[128];
	Entity_GetTargetName(entity, targetName, sizeof(targetName));

	if (name[0] == '\0') {

		if (targetName[0] == '\0') {
			// Let's generate our own name
			Format(
				targetName,
				sizeof(targetName),
				"_smlib_Entity_PointHurtAtTarget:%d",
				target
			);
		}
	}
	else {
		strcopy(targetName, sizeof(targetName), name);
	}

	DispatchKeyValue(entity, "DamageTarget", targetName);
	Entity_SetName(target, targetName);
}
stock Entity_SetClassName(entity, const char[] className)
{
	return DispatchKeyValue(entity, "classname", className);
}
stock Entity_GetTargetName(entity, char[] buffer, size)
{
	return GetEntPropString(entity, Prop_Data, "m_target", buffer, size);
}
stock Entity_IsValid(entity)
{
	return IsValidEdict(entity);
}
stock Entity_SetName(entity, const char[] name, any:...)
{
	char format[128];
	VFormat(format, sizeof(format), name, 3);

	return DispatchKeyValue(entity, "targetname", format);
}
stock refreshAllWeapons(client)
{
	TF2Attrib_ClearCache(client);
	for(int i=0;i<5;++i)
	{
		int weapon = GetWeapon(client,i);
		if(IsValidEdict(weapon))
		{
			TF2Attrib_ClearCache(weapon);
		}
	}
}
public bool TraceEntityFilterPlayer(entity, contentsMask){
    return entity > MaxClients || !entity;
}
public bool TraceEntityFilterOnlyWorld(entity, contentsMask){
    return entity == 0;
}

stock void SetPawnTimer(Function func, float thinktime = 0.1, any[] variables, int size)
{
	DataPack thinkpack = new DataPack();
	thinkpack.WriteFunction(func);
	thinkpack.WriteCell(size);
	for(int i = 0; i<size; ++i){
		thinkpack.WriteCell(variables[i]);
	}
	CreateTimer(thinktime, DoThinkTimed, thinkpack, TIMER_DATA_HNDL_CLOSE);
}
stock Action  DoThinkTimed(Handle t, DataPack pack)
{
	pack.Reset();
	Function fn = pack.ReadFunction();
	Call_StartFunction(null, fn);

	int size = pack.ReadCell();
	for(int i = 0; i<size; ++i){
		any param = pack.ReadCell();
		Call_PushCell(param);
	}

	Call_Finish();
	return Plugin_Continue;
}

stock void RequestFramePawn(Function func, any[] variables, int size)
{
	DataPack thinkpack = new DataPack();
	thinkpack.WriteFunction(func);
	thinkpack.WriteCell(size);
	for(int i = 0; i<size; ++i){
		thinkpack.WriteCell(variables[i]);
	}
	RequestFrame(DoThink, thinkpack);
}
void DoThink(DataPack pack)
{
	pack.Reset();
	Function fn = pack.ReadFunction();
	Call_StartFunction(null, fn);

	int size = pack.ReadCell();
	for(int i = 0; i<size; ++i){
		any param = pack.ReadCell();
		Call_PushCell(param);
	}

	Call_Finish();
}
stock void AddUbercharge(int weapon, float add){
	float uber = GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel");
	if(uber + add > 100)
		SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 100.0);
	else
		SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", uber + add);
}
stock MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
    float vDir[3];
    GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
    vReturn = vPos;
    vReturn[0] += vDir[0] * fDistance;
    vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}
stock GetClosestTarget(entity, owner, bool isFriendly = false, bool pierceWalls = false)
{
	float TargetDistance = 0.0;
	int ClosestTarget = 0;
	for(int i = 1; i <= MaxClients; ++i) 
	{
		if(ShouldNotHome[entity][i] || !IsValidClient3(i) || !IsValidClient3(owner) || i == owner || (!isFriendly && GetClientTeam(owner) == GetClientTeam(i)) || (isFriendly && GetClientTeam(owner) != GetClientTeam(i)) || !IsValidForHoming( i, owner, entity) || !IsAbleToSee(owner, i)) continue;
		float EntityLocation[3], TargetLocation[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", EntityLocation);
		GetClientAbsOrigin(i, TargetLocation);
		if(pierceWalls == false)
		{
			Handle hTrace = TR_TraceRayFilterEx( TargetLocation, EntityLocation, MASK_SOLID, RayType_EndPoint, TraceFilterIgnoreSelf, entity ); 
			if( hTrace != INVALID_HANDLE )
			{
				if( TR_DidHit( hTrace ) )
				{
					CloseHandle( hTrace ); 
					continue; 
				}
				
				CloseHandle( hTrace ); 
				float distance = GetVectorDistance(EntityLocation, TargetLocation, true);
				if(TargetDistance)
				{
					if(distance < TargetDistance) 
					{
						ClosestTarget = i;
						TargetDistance = distance;			
					}
				}
				else
				{
					ClosestTarget = i;
					TargetDistance = distance;
				}
			}
		}
		else
		{
			float distance = GetVectorDistance(EntityLocation, TargetLocation, true);
			if(TargetDistance)
			{
				if(distance < TargetDistance) 
				{
					ClosestTarget = i;
					TargetDistance = distance;			
				}
			}
			else
			{
				ClosestTarget = i;
				TargetDistance = distance;
			}
		}
	}
	return ClosestTarget;
}
stock CreateLaser(float StartPos[3],int times,float length,int BeamSprite,int HaloSprite, int color[4])
{
	for(int i=0;i<times;++i)
	{
		float EndPos[3];
		EndPos[0] = StartPos[0];
		EndPos[1] = StartPos[1];
		EndPos[2] = StartPos[2];
		
		EndPos[0] += GetRandomFloat( -1.0 * length, length );
		EndPos[1] += GetRandomFloat( -1.0 * length, length );
		EndPos[2] += GetRandomFloat( -1.0 * length, length );

		TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 1.0, 10.0, 2.0, 1, 0.0, color, 1 );
		TE_SendToAll();
	}
}
stock CreateSmoke(float location[3],float time,int red,int green, int blue,char[] SmokeTransparency,char[] SmokeDensity)
{
	int SmokeEnt = CreateEntityByName("env_smokestack");

	char originData[64];
	Format(originData, sizeof(originData), "%f %f %f", location[0], location[1], location[2]);
	
	char SmokeColor[128];
	
	Format(SmokeColor, sizeof(SmokeColor), "%i %i %i", red, green, blue);
	
	float timeTaken = time;
	
	if(SmokeEnt)
	{
		// Create the Smoke
		char SName[128];
		Format(SName, sizeof(SName), "Smoke");
		DispatchKeyValue(SmokeEnt,"targetname", SName);
		DispatchKeyValue(SmokeEnt,"Origin", originData);
		DispatchKeyValue(SmokeEnt,"BaseSpread", "100");
		DispatchKeyValue(SmokeEnt,"SpreadSpeed", "70");
		DispatchKeyValue(SmokeEnt,"Speed", "80");
		DispatchKeyValue(SmokeEnt,"StartSize", "200");
		DispatchKeyValue(SmokeEnt,"EndSize", "2");
		DispatchKeyValue(SmokeEnt,"Rate", SmokeDensity);
		DispatchKeyValue(SmokeEnt,"JetLength", "400");
		DispatchKeyValue(SmokeEnt,"Twist", "20"); 
		DispatchKeyValue(SmokeEnt,"RenderColor", SmokeColor); //red green blue
		DispatchKeyValue(SmokeEnt,"RenderAmt", SmokeTransparency);
		DispatchKeyValue(SmokeEnt,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
		
		DispatchSpawn(SmokeEnt);
		AcceptEntityInput(SmokeEnt, "TurnOn");

		CreateTimer(timeTaken, Timer_KillSmoke, SmokeEnt);
		
		//Start timer to remove smoke
		CreateTimer(timeTaken+5.0, Timer_StopSmoke, SmokeEnt)
	}
}

stock Action Timer_KillSmoke(Handle timer, any SmokeEnt)
{	
	StopSmokeEnt(SmokeEnt);
	return Plugin_Stop;
}

StopSmokeEnt(target)
{
	if (IsValidEdict(target))
	{
		AcceptEntityInput(target, "TurnOff");
	}
}

stock Action Timer_StopSmoke(Handle timer, any SmokeEnt)
{
	RemoveSmokeEnt(SmokeEnt);
	return Plugin_Stop;
}

RemoveSmokeEnt(target)
{
	if (IsValidEdict(target))
	{
		AcceptEntityInput(target, "Kill");
	}
}
public bool TraceFilterIgnoreSelf( entity, contentsMask, any:hiok )
{
    if ( entity == hiok || entity > 0 && entity <= MaxClients ) return false; 
    return true; 
}
stock bool IsValidForHoming( client, owner, entity)
{
    if ( IsValidClient3( owner ) && IsValidClient3( client ) && IsValidEdict( entity ) )
    {
        float OwnerPos[3], TargetPos[3]; 
        GetClientAbsOrigin( owner, OwnerPos ); 
        GetClientAbsOrigin( client, TargetPos );
        if ( GetVectorDistance(OwnerPos, TargetPos, true) <= 21316.0 ) return false; 
    
        int team = GetEntProp( entity, Prop_Send, "m_iTeamNum" ); 
        if (IsPlayerAlive( client ) && client != owner)
        {
            if ( !TF2_IsPlayerInCondition( client, TFCond_Cloaked ) && !TF2_IsPlayerInCondition( client, TFCond_Ubercharged )
			&& !TF2_IsPlayerInCondition( client, TFCond_Bonked ) && !TF2_IsPlayerInCondition( client, TFCond_Stealthed )
			&& !TF2_IsPlayerInCondition( client, TFCond_BlastImmune ) && !TF2_IsPlayerInCondition( client, TFCond_HalloweenGhostMode )
			&& !TF2_IsPlayerInCondition( client, TFCond_Disguised ) && GetEntProp( client, Prop_Send, "m_nDisguiseTeam" ) != team )
            {
               return true;
            }
        }
    }
    return false; 
}
stock Action HomingFlareThink(Handle timer, any:ref) 
{
	int entity = EntRefToEntIndex(ref); 
	bool flag = false;
	if(IsValidEdict(entity))
    {
		if(!HasEntProp(entity,Prop_Send,"m_vInitialVelocity"))
		{
			flag = true;
		}
		int owner = GetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity" ); 
		if(!IsValidClient3(owner) && IsValidEdict(owner) && HasEntProp(owner,Prop_Send,"m_hBuilder"))
		{
			owner = GetEntPropEnt(owner,Prop_Send,"m_hBuilder" );
		}
		if (IsValidClient3(owner))
		{
			int Target = GetClosestTarget(entity, owner, false, true); 
			if(IsValidClient3(Target))
			{
				if(owner != Target)
				{
					float EntityPos[3], TargetPos[3]; 
					GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityPos ); 
					GetClientAbsOrigin( Target, TargetPos ); 
					float distance = GetVectorDistance(EntityPos, TargetPos, true); 
					if( distance <= 640000.0 )
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
				}
			}
		}
		else{
		flag = true;
		}
    }
	else{
		flag = true;
	}
	if(flag == true){
		KillTimer(timer);
	}
	return Plugin_Continue;
}

stock Action HomingThink(Handle timer, any:ref) 
{ 
	int entity = EntRefToEntIndex(ref); 
	bool flag = false;
	if(IsValidEdict(entity))
    {
		int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient3(owner))
		{
			int Target = GetClosestTarget(entity, owner); 
			if(IsValidClient3(Target))
			{
				int hClientWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEdict(hClientWeapon))
				{
					Address homingActive = TF2Attrib_GetByName(hClientWeapon, "crit from behind");
					if(homingActive != Address_Null)
					{
						float maxDistance = TF2Attrib_GetValue(homingActive)
						if(owner != Target)
						{
							float EntityPos[3], TargetPos[3];
							GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", EntityPos);
							GetClientAbsOrigin( Target, TargetPos ); 
							float distance = GetVectorDistance(EntityPos, TargetPos, true); 
							
							if( distance <= maxDistance*maxDistance )
							{
								float ProjLocation[3], ProjVector[3], BaseSpeed, NewSpeed, ProjAngle[3], AimVector[3], InitialSpeed[3]; 
								
								GetEntPropVector( entity, Prop_Send, "m_vInitialVelocity", InitialSpeed ); 
								if ( GetVectorLength( InitialSpeed ) < 10.0 ) GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", InitialSpeed ); 
								BaseSpeed = GetVectorLength( InitialSpeed ) * 0.3; 
								
								GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", ProjLocation ); 
								GetClientAbsOrigin( Target, TargetPos ); 
								TargetPos[2] += 40.0; 
								
								MakeVectorFromPoints( ProjLocation, TargetPos, AimVector ); 
								
								//GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", ProjVector ); //50% HOME
								SubtractVectors( TargetPos, ProjLocation, ProjVector ); //100% HOME
								AddVectors( ProjVector, AimVector, ProjVector ); 
								NormalizeVector( ProjVector, ProjVector ); 
								
								GetEntPropVector( entity, Prop_Data, "m_angRotation", ProjAngle ); 
								GetVectorAngles( ProjVector, ProjAngle ); 
								
								NewSpeed = ( BaseSpeed * 2.0 ) + 1.0 * BaseSpeed * 1.1; 
								ScaleVector( ProjVector, NewSpeed ); 
								
								TeleportEntity( entity, NULL_VECTOR, ProjAngle, ProjVector ); 
								SetEntityGravity(entity, 0.001);
							}
						}
					}
					else
					{
						flag = true;
					}
				}
			}
		}
		else{
		flag = true;
		}
    }
	else{
		flag = true;
	}
	if(flag == true){
		KillTimer(timer);
	}
	return Plugin_Continue;
}
stock Action HeavyFriendlyHoming(Handle timer, any:ref) 
{ 
	int entity = EntRefToEntIndex(ref); 
	bool flag = false;
	if(IsValidEdict(entity))
    {
		int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient3(owner))
		{
			int Target = GetClosestTarget(entity, owner, true); 
			if(IsValidClient3(Target))
			{
				if(owner != Target)
				{
					float EntityPos[3], TargetPos[3]; 
					GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityPos ); 
					GetClientAbsOrigin( Target, TargetPos ); 
					float distance = GetVectorDistance(EntityPos, TargetPos, true); 
					
					if( distance <= 640000.0 )
					{
						float ProjLocation[3], ProjVector[3], BaseSpeed, NewSpeed, ProjAngle[3], AimVector[3], InitialSpeed[3]; 
						
						GetEntPropVector( entity, Prop_Send, "m_vInitialVelocity", InitialSpeed ); 
						if ( GetVectorLength( InitialSpeed ) < 10.0 ) GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", InitialSpeed ); 
						BaseSpeed = GetVectorLength( InitialSpeed ) * 0.3; 
						
						GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", ProjLocation ); 
						GetClientAbsOrigin( Target, TargetPos ); 
						TargetPos[2] += 40.0; 
						
						MakeVectorFromPoints( ProjLocation, TargetPos, AimVector ); 
						
						//GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", ProjVector ); //50% HOME
						SubtractVectors( TargetPos, ProjLocation, ProjVector ); //100% HOME
						AddVectors( ProjVector, AimVector, ProjVector ); 
						NormalizeVector( ProjVector, ProjVector ); 
						
						GetEntPropVector( entity, Prop_Data, "m_angRotation", ProjAngle ); 
						GetVectorAngles( ProjVector, ProjAngle ); 
						
						NewSpeed = ( BaseSpeed * 2.0 ) + 1.0 * BaseSpeed * 1.1; 
						ScaleVector( ProjVector, NewSpeed ); 
						
						TeleportEntity( entity, NULL_VECTOR, ProjAngle, ProjVector ); 
						SetEntityGravity(entity, 0.001);
					}
				}
			}
		}
		else{
		flag = true;
		}
    }
	else{
		flag = true;
	}
	if(flag == true){
		KillTimer(timer);
	}
	return Plugin_Continue;
}
stock bool TracePlayerAim(int client, float vec[3]) {
    if (!IsClientInGame(client))
        return false;

    float vecangles[3], vecorigin[3], fwd[3];
    GetClientEyeAngles(client, vecangles);
    GetClientEyePosition(client, vecorigin);
	GetAngleVectors(vecangles,fwd, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fwd, 30.0);
	
	AddVectors(vecorigin, fwd, vecorigin);

    Handle traceray = TR_TraceRayFilterEx(vecorigin, vecangles, MASK_SHOT_HULL, RayType_Infinite,TEF_ExcludeEntity, client);
    if (TR_DidHit(traceray)) {
        TR_GetEndPosition(vec, traceray);
        delete traceray;

        return true;
    }
    delete traceray;
    return false;
}
stock bool TracePlayerAimRanged(int client, float dist, float vec[3]) {
    if (!IsClientInGame(client))
        return false;

    float vecangles[3], vecorigin[3], fwd[3], vecEnd[3];
    GetClientEyeAngles(client, vecangles);
    GetClientEyePosition(client, vecorigin);
	GetAngleVectors(vecangles,fwd, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fwd, 30.0);
	AddVectors(vecorigin, fwd, vecorigin);
	ScaleVector(fwd, dist/30.0);
	AddVectors(vecorigin, fwd, vecEnd);

    Handle traceray = TR_TraceRayFilterEx(vecorigin, vecEnd, MASK_SHOT_HULL, RayType_EndPoint,TEF_ExcludeEntity, client);
	TR_GetEndPosition(vec, traceray);
    if (TR_DidHit(traceray)) {
        delete traceray;
        return true;
    }
    delete traceray;
    return false;
}
stock float getLowestPosition(float vec[3], int entity = -1) {
	float vecangles[3];
	float zAxis;
	vecangles[0] = 89.0;
	vecangles[1] = 0.0;
	vecangles[2] = 0.0;
    Handle traceray = TR_TraceRayFilterEx(vec, vecangles, MASK_SHOT_HULL, RayType_Infinite, TraceEntityFilterOnlyWorld, entity);
    if (TR_DidHit(traceray)) {
		float lastVec[3];
        TR_GetEndPosition(lastVec, traceray);
        delete traceray;
		zAxis = lastVec[2];
        return zAxis;
    }
    delete traceray;
    return 0.0;
}
stock float getHighestPosition(float vec[3]) {
	float vecangles[3];
	float zAxis;
	vecangles[0] = -89.0;
	vecangles[1] = 0.0;
	vecangles[2] = 0.0;
    Handle traceray = TR_TraceRayFilterEx(vec, vecangles, MASK_SHOT_HULL, RayType_Infinite, TraceEntityFilterOnlyWorld);
    if (TR_DidHit(traceray)) {
		float lastVec[3];
        TR_GetEndPosition(lastVec, traceray);
        delete traceray;
		zAxis = lastVec[2];
        return zAxis;
    }
    delete traceray;
    return 0.0;
}
public bool TEF_ExcludeEntity(entity, contentsMask, any:data)
{
	return (entity != data);
}

stock int GetHealingTarget(const int client)
{
    int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
    if (!IsValidEdict(medigun))
        return -1;

    char s[32]; GetEdictClassname(medigun, s, sizeof(s));
    if ( !strcmp(s, "tf_weapon_medigun", false) ) {
        if ( GetEntProp(medigun, Prop_Send, "m_bHealing") )
            return GetEntPropEnt( medigun, Prop_Send, "m_hHealingTarget" );
    }
    return -1;
}
stock bool IsNearSpencer(const int client)
{
    int medics = 0;
    for ( int i=MaxClients ; i ; --i ) {
        if (!IsClientInGame(i))
            continue;
        if ( GetHealingTarget(i) == client )
            medics++;
    }
    return (GetEntProp(client, Prop_Send, "m_nNumHealers") > medics);
}
bool IsAbleToSee(entity, client, bool forWeapon = true)
{
    // Skip all traces if the player isn't within the field of view.
    // - Temporarily disabled until eye angle prediction is added.
    // if (IsInFieldOfView(g_vEyePos[client], g_vEyeAngles[client], g_vAbsCentre[entity]))
    
    float vecOrigin[3], vecEyePos[3];
    GetClientAbsOrigin(entity, vecOrigin);
    GetClientEyePosition(client, vecEyePos);
    
    // Check if centre is visible.
    if (IsPointVisible(vecEyePos, vecOrigin))
    {
        return true;
    }
    
	if(forWeapon)
	{
		float vecEyePos_ent[3], vecEyeAng[3];
		GetClientEyeAngles(entity, vecEyeAng);
		GetClientEyePosition(entity, vecEyePos_ent);
		// Check if weapon tip is visible.
		if (IsFwdVecVisible(vecEyePos, vecEyeAng, vecEyePos_ent))
		{
			return true;
		}
	}
    
    float mins[3], maxs[3];
    GetClientMins(client, mins);
    GetClientMaxs(client, maxs);
    // Check outer 4 corners of player.
    if (IsRectangleVisible(vecEyePos, vecOrigin, mins, maxs, 1.1))
    {
        return true;
    }

    // Check inner 4 corners of player.
    if (IsRectangleVisible(vecEyePos, vecOrigin, mins, maxs, 0.9))
    {
        return true;
    }
    
    return false;
}
stock void insertionSort(any[] arr, int arrSize){
	int i, key, j;
    for (i = 1; i < arrSize; ++i)
    {
        key = arr[i];
        j = i - 1;

        while (j >= 0 && arr[j] > key)
        {
            arr[j + 1] = arr[j];
            j = j - 1;
        }
        arr[j + 1] = key;
    }
}
stock void swap(any[] arr , int pos1, int pos2){
	int temp;
	temp = arr[pos1];
	arr[pos1] = arr[pos2];
	arr[pos2] = temp;
}

stock int partition(any[] arr, int low, int high, int pivot){
	int i = low;
	int j = low;
	while( i <= high){
		if(arr[i] > pivot){
			++i;
		}
		else{
			swap(arr,i,j);
			++i;
			j++;
		}
	}
	return j-1;
}

stock void quickSort(any[] arr, int low, int high){
	if(low < high){
		int pivot = arr[high];
		int pos = partition(arr, low, high, pivot);
		quickSort(arr, low, pos-1);
		quickSort(arr, pos+1, high);
	}
}

stock sortArray(any[] arr, int arrSize){
	if(arrSize > 32){
		quickSort(arr, 0, arrSize);
	}else{
		insertionSort(arr, arrSize);
	}
}

stock bool IsInFieldOfView(client, const float start[3], const float angles[3], float fov = 90.0)
{
    float normal[3], plane[3];
    
    float end[3];
    GetClientAbsOrigin(client, end);
    
    GetAngleVectors(angles, normal, NULL_VECTOR, NULL_VECTOR);
    SubtractVectors(end, start, plane);
    NormalizeVector(plane, plane);
    
    return GetVectorDotProduct(plane, normal) > Cosine(DegToRad(fov/2.0));
}
public bool Filter_WorldOnly(int entity,int mask)
{
    return false;
}
bool IsPointVisible(const float start[3], const float end[3])
{
    TR_TraceRayFilter(start, end, MASK_SOLID, RayType_EndPoint, Filter_WorldOnly);

    return TR_GetFraction() == 1.0;
}

bool IsFwdVecVisible(const float start[3], const float angles[3], const float end[3])
{
    float fwd[3];
    
    GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(fwd, 50.0);
    AddVectors(end, fwd, fwd);

    return IsPointVisible(start, fwd);
}

bool IsRectangleVisible(const float start[3], const float end[3], const float mins[3], const float maxs[3], float scale=1.0)
{
    float ZpozOffset = maxs[2];
    float ZnegOffset = mins[2];
    float WideOffset = ((maxs[0] - mins[0]) + (maxs[1] - mins[1])) / 4.0;

    // This rectangle is just a point!
    if (ZpozOffset == 0.0 && ZnegOffset == 0.0 && WideOffset == 0.0)
    {
        return IsPointVisible(start, end);
    }

    // Adjust to scale.
    ZpozOffset *= scale;
    ZnegOffset *= scale;
    WideOffset *= scale;
    
    // Prepare rotation matrix.
    float angles[3], fwd[3], right[3];

    SubtractVectors(start, end, fwd);
    NormalizeVector(fwd, fwd);

    GetVectorAngles(fwd, angles);
    GetAngleVectors(angles, fwd, right, NULL_VECTOR);

    float vRectangle[4][3], vTemp[3];

    // If the player is on the same level as us, we can optimize by only rotating on the z-axis.
    if (FloatAbs(fwd[2]) <= 0.7071)
    {
        ScaleVector(right, WideOffset);
        
        // Corner 1, 2
        vTemp = end;
        vTemp[2] += ZpozOffset;
        AddVectors(vTemp, right, vRectangle[0]);
        SubtractVectors(vTemp, right, vRectangle[1]);
        
        // Corner 3, 4
        vTemp = end;
        vTemp[2] += ZnegOffset;
        AddVectors(vTemp, right, vRectangle[2]);
        SubtractVectors(vTemp, right, vRectangle[3]);
        
    }
    else if (fwd[2] > 0.0) // Player is below us.
    {
        fwd[2] = 0.0;
        NormalizeVector(fwd, fwd);
        
        ScaleVector(fwd, scale);
        ScaleVector(fwd, WideOffset);
        ScaleVector(right, WideOffset);
        
        // Corner 1
        vTemp = end;
        vTemp[2] += ZpozOffset;
        AddVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[0]);
        
        // Corner 2
        vTemp = end;
        vTemp[2] += ZpozOffset;
        SubtractVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[1]);
        
        // Corner 3
        vTemp = end;
        vTemp[2] += ZnegOffset;
        AddVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[2]);
        
        // Corner 4
        vTemp = end;
        vTemp[2] += ZnegOffset;
        SubtractVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[3]);
    }
    else // Player is above us.
    {
        fwd[2] = 0.0;
        NormalizeVector(fwd, fwd);
        
        ScaleVector(fwd, scale);
        ScaleVector(fwd, WideOffset);
        ScaleVector(right, WideOffset);

        // Corner 1
        vTemp = end;
        vTemp[2] += ZpozOffset;
        AddVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[0]);
        
        // Corner 2
        vTemp = end;
        vTemp[2] += ZpozOffset;
        SubtractVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[1]);
        
        // Corner 3
        vTemp = end;
        vTemp[2] += ZnegOffset;
        AddVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[2]);
        
        // Corner 4
        vTemp = end;
        vTemp[2] += ZnegOffset;
        SubtractVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[3]);
    }

    // Run traces on all corners.
    for (int i = 0; i < 4; ++i)
    {
        if (IsPointVisible(start, vRectangle[i]))
        {
            return true;
        }
    }

    return false;
}
stock bool IsMvM(bool forceRecalc = false)
{
	static bool found = false;
	static bool ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{
		int i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEdict(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}
stock VisualHealing(patient, healer, amount)
{
    Event event = CreateEvent("player_healed");
    if (event == null)
    {
        return;
    }
    event.SetInt("patient", GetClientUserId(patient));
    event.SetInt("healer", GetClientUserId(healer));
    event.SetInt("amount", amount);
    event.Fire();
}
stock ShowHealthGain(iPatient, iHealth, iHealer = -1)
{
    int iUserId = GetClientUserId(iPatient);
    Handle hEvent = CreateEvent("player_healed", true);
    SetEventBool(hEvent, "sourcemod", true);
    SetEventInt(hEvent, "patient", iUserId);
    SetEventInt(hEvent, "healer", IsValidClient3(iHealer) ? GetClientUserId(iHealer) : iUserId);
    SetEventInt(hEvent, "amount", iHealth);
    FireEvent(hEvent);

    hEvent = CreateEvent("player_healonhit", true);
    SetEventBool(hEvent, "sourcemod", true);
    SetEventInt(hEvent, "amount", iHealth);
    SetEventInt(hEvent, "entindex", iPatient);
    FireEvent(hEvent);
}
stock TF2_GetMaxHealth(client)
{
    int maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
    return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(client, Prop_Data, "m_iMaxHealth") : maxhealth);
}
//==== [ OTHERS ] ==================================================
stock AnglesToVelocity( float fAngle[3], float fVelocity[3], float fSpeed = 1.0 )
{
    fVelocity[0] = Cosine( DegToRad( fAngle[1] ) ); 
    fVelocity[1] = Sine( DegToRad( fAngle[1] ) ); 
    fVelocity[2] = Sine( DegToRad( fAngle[0] ) ) * -1.0; 
    
    NormalizeVector( fVelocity, fVelocity ); 
    
    ScaleVector( fVelocity, fSpeed ); 
}
stock bool IsSlotWeapon(client, iSlot, iWeapon)
{
    return iWeapon == GetPlayerWeaponSlot(client, iSlot);
}
stock float GetAngleBetweenVector(const float vec1[3], const float vec2[3])
{
    return RadToDeg(ArcCosine(GetVectorDotProduct(vec1, vec2) / (GetVectorLength(vec1) * GetVectorLength(vec2))));
} 
stock bool IsTargetInSightRange(client, target, float angle=90.0, float distance=0.0, bool heightcheck=false, bool negativeangle=false)
{
	if(angle > 360.0 || angle < 0.0)
		ThrowError("Angle Max : 360 & Min : 0. %d isn't proper angle.", angle);
	if(!IsClientConnected(client) && IsPlayerAlive(client))
		ThrowError("Client is not Alive.");
	if(!IsClientConnected(target) && IsPlayerAlive(target))
		ThrowError("Target is not Alive.");
		
	float clientpos[3], targetpos[3], anglevector[3], targetvector[3], resultangle, resultdistance;
	GetClientEyeAngles(client,anglevector);
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	if(heightcheck == false)
		anglevector[2] = 0.0;
	if(negativeangle){
		NegateVector(anglevector);
	}
	GetClientAbsOrigin(client, clientpos)
	GetClientAbsOrigin(target, targetpos);
	if(heightcheck && distance > 0){
		targetpos[2] -= 40.0;
		resultdistance = GetVectorDistance(clientpos, targetpos, true);
	}
	if(heightcheck == false){
		clientpos[2] = targetpos[2] = 0.0;
	}
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	if(heightcheck == false){
		targetvector[2] = 0.0;
	}
	NormalizeVector(targetvector, targetvector);
	resultangle = GetAngleBetweenVector(targetvector, anglevector);
	
	if(resultangle <= angle)
	{
		if(distance > 0)
		{
			if(!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos, true);
			if(distance*distance >= resultdistance)
				return true;
			else
				return false;
		}
		else
			return true;
	}
	else
		return false;
}
stock float TF2_GetWeaponclassDPS(client, weapon)
{
	if(IsValidClient3(client))
    {
		if(IsValidEdict(weapon))
		{
			float dps;
			char Classname[64];
			TF2Econ_GetItemClassName(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), Classname, sizeof(Classname));
			if(StrEqual(Classname,"tf_weapon_scattergun",false) || StrEqual(Classname,"tf_weapon_soda_popper",false) || StrEqual(Classname,"tf_weapon_pep_brawler_blaster",false) || StrEqual(Classname,"tf_weapon_shotgun",false) || 
			StrEqual(Classname,"tf_weapon_shotgun_primary",false) || StrEqual(Classname,"tf_weapon_sentry_revenge",false) || StrEqual(Classname,"tf_weapon_shotgun_building_rescue",false))
			{
				dps = 96.0;
			}
			else if(StrEqual(Classname,"tf_weapon_handgun_scout_primary",false))
			{
				dps = 133.3;
			}
			else if(StrEqual(Classname,"tf_weapon_pistol",false) || StrEqual(Classname,"tf_weapon_handgun_scout_secondary",false))
			{
				dps = 100.0;
			}
			else if(StrEqual(Classname,"tf_weapon_cleaver",false))
			{
				dps = 65.0;
			}
			else if(StrEqual(Classname,"tf_weapon_rocketlauncher",false) || StrEqual(Classname,"tf_weapon_rocketlauncher_directhit",false)
			|| StrEqual(Classname,"tf_weapon_rocketlauncher_airstrike",false) || StrEqual(Classname,"tf_weapon_particle_cannon",false))
			{
				dps = 112.5;
			}
			else if(StrEqual(Classname,"tf_weapon_raygun",false) || StrEqual(Classname,"tf_weapon_drg_pomson",false))
			{
				dps = 160.0;
			}
			else if(StrEqual(Classname,"tf_weapon_shovel",false) || StrEqual(Classname,"saxxy",false) || StrEqual(Classname,"tf_weapon_fireaxe",false) || StrEqual(Classname,"tf_weapon_slap",false) || StrEqual(Classname,"tf_weapon_sword",false) ||
			StrEqual(Classname,"tf_weapon_bottle",false) || StrEqual(Classname,"tf_weapon_stickbomb",false) || StrEqual(Classname,"tf_weapon_katana",false) || StrEqual(Classname,"tf_weapon_fists",false) || StrEqual(Classname,"tf_weapon_wrench",false) ||
			StrEqual(Classname,"tf_weapon_robot_arm",false) || StrEqual(Classname,"tf_weapon_bonesaw",false) || StrEqual(Classname,"tf_weapon_club",false) || StrEqual(Classname,"tf_weapon_breakable_sign",false))
			{
				dps = 81.0;
			}
			else if(StrEqual(Classname,"tf_weapon_bat",false) || StrEqual(Classname,"tf_weapon_bat_wood",false) || StrEqual(Classname,"tf_weapon_bat_fish",false) || StrEqual(Classname,"tf_weapon_bat_giftwrap",false))
			{
				dps = 70.0;
			}
			else if(StrEqual(Classname,"tf_weapon_knife",false))
			{
				dps = 50.0;
			}
			else if(StrEqual(Classname,"tf_weapon_flamethrower",false))
			{
				dps = 170.0;
			}
			else if(StrEqual(Classname,"tf_weapon_rocketlauncher_fireball",false))
			{
				dps = 125.0;
			}
			else if(StrEqual(Classname,"tf_weapon_jar_gas",false))
			{
				dps = 6.0;
			}
			else if(StrEqual(Classname,"tf_weapon_jar",false) || StrEqual(Classname,"tf_weapon_jar_milk",false))
			{
				dps = 70.0;
				
				Address corrosiveElement = TF2Attrib_GetByName(weapon, "building cost reduction");
				if(corrosiveElement != Address_Null)
				{
					dps += 14.5*TF2Attrib_GetValue(corrosiveElement);
				}
				Address jarFragsToggle = TF2Attrib_GetByName(weapon, "overheal decay penalty");
				if(jarFragsToggle != Address_Null)
				{
					dps += 10.0*TF2Attrib_GetValue(jarFragsToggle);
					
					Address fragmentExplosion = TF2Attrib_GetByName(weapon, "overheal decay bonus");
					if(fragmentExplosion != Address_Null && TF2Attrib_GetValue(fragmentExplosion) > 0.0)
					{
						dps += TF2Attrib_GetValue(fragmentExplosion)*0.5*TF2Attrib_GetValue(jarFragsToggle);
					}
				}
				
			}
			else if(StrEqual(Classname,"tf_weapon_flaregun",false) || StrEqual(Classname,"tf_weapon_flaregun_revenge",false))
			{
				dps = 15.0;
			}
			else if(StrEqual(Classname,"tf_weapon_grenadelauncher",false) || StrEqual(Classname,"tf_weapon_cannon",false))
			{
				dps = 166.6;
			}
			else if(StrEqual(Classname,"tf_weapon_pipebomblauncher",false))
			{
				dps = 200.0;
			}
			else if(StrEqual(Classname,"tf_weapon_minigun",false))
			{
				dps = 360.0;
			}
			else if(StrEqual(Classname,"tf_weapon_syringegun_medic",false) || StrEqual(Classname,"tf_weapon_syringegun",false))
			{
				dps = 100.0;
			}
			else if(StrEqual(Classname,"tf_weapon_compound_bow",false))
			{
				dps = 150.0;
			}
			else if(StrEqual(Classname,"tf_weapon_crossbow",false))
			{
				dps = 47.0;
			}
			else if(StrEqual(Classname,"tf_weapon_sniperrifle",false) || StrEqual(Classname,"tf_weapon_sniperrifle_decap",false) || StrEqual(Classname,"tf_weapon_sniperrifle_classic",false))
			{
				dps = 33.3;
			}
			else if(StrEqual(Classname,"tf_weapon_smg",false) || StrEqual(Classname,"tf_weapon_charged_smg",false))
			{
				dps = 80.0;
			}
			else if(StrEqual(Classname,"tf_weapon_revolver",false))
			{
				dps = 80.0;
			}
			else if(StrEqual(Classname,"tf_weapon_mechanical_arm",false))
			{
				dps = 58.33;
			}
			else
			{
				dps = 0.0;
			}
			return dps;
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
					aps = 1.25;
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
				
				Address apsMult1 = TF2Attrib_GetByName(weapon, "fire rate bonus HIDDEN");
				Address apsMult2 = TF2Attrib_GetByName(weapon, "fire rate penalty HIDDEN");
				Address apsMult3 = TF2Attrib_GetByName(weapon, "fire rate bonus");
				Address apsMult4 = TF2Attrib_GetByName(weapon, "fire rate penalty");
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
				//Normal Firerate Attributes
				if(apsMult1 != Address_Null)
					aps /= TF2Attrib_GetValue(apsMult1) / efficiency;
				
				if(apsMult2 != Address_Null)
					aps /= TF2Attrib_GetValue(apsMult2) / efficiency;
				
				if(apsMult3 != Address_Null)
					aps /= TF2Attrib_GetValue(apsMult3) / efficiency;
				
				if(apsMult4 != Address_Null)
					aps /= TF2Attrib_GetValue(apsMult4) / efficiency;
				
				if(apsMult5 != Address_Null)
					aps /= TF2Attrib_GetValue(apsMult5) / efficiency;
				
				if(apsMult6 != Address_Null) 
					aps /= TF2Attrib_GetValue(apsMult6) / efficiency;
				
				if(apsMod != Address_Null) 
					aps *= 33.0;
				
				//if(apsMult7 != Address_Null) {
				//aps *= TF2Attrib_GetValue(apsMult7) * efficiency;
				//}
				//Body Firerate Attributes
				Address BodyapsMult6 = TF2Attrib_GetByName(client, "fire rate bonus HIDDEN");
				Address BodyapsMult7 = TF2Attrib_GetByName(client, "fire rate penalty HIDDEN");
				Address BodyapsMult8 = TF2Attrib_GetByName(client, "fire rate bonus");
				Address BodyapsMult9 = TF2Attrib_GetByName(client, "fire rate penalty");

				if(BodyapsMult6 != Address_Null) 
					aps /= TF2Attrib_GetValue(BodyapsMult6) / efficiency
				
				if(BodyapsMult7 != Address_Null) 
					aps /= TF2Attrib_GetValue(BodyapsMult7) / efficiency
				
				if(BodyapsMult8 != Address_Null) 
					aps /= TF2Attrib_GetValue(BodyapsMult8) / efficiency
				
				if(BodyapsMult9 != Address_Null) 
					aps /= TF2Attrib_GetValue(BodyapsMult9) / efficiency
				
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
stock float TF2_GetSentryDPSModifiers(client, melee){
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
	
	Address fireRateActive = TF2Attrib_GetByName(melee, "engy sentry fire rate increased");
	if(fireRateActive != Address_Null)
		dmgBonus /= TF2Attrib_GetValue(fireRateActive);
	
	return dmgBonus;
}
stock float TF2_GetDPSModifiers(client,weapon, bool CountReloadModifiers = true, bool critMod = true, bool onlyModifiers = false)
{
	if(IsValidClient3(client))
    {
		if(IsValidEdict(weapon))
		{
			float dpsMult = onlyModifiers ? 1.0 : TF2_GetDamageModifiers(client,weapon);
			dpsMult /= GetAttribute(weapon, "fire rate bonus HIDDEN");
			dpsMult /= GetAttribute(weapon, "fire rate penalty HIDDEN");
			dpsMult /= GetAttribute(weapon, "fire rate bonus");
			dpsMult /= GetAttribute(weapon, "fire rate penalty");
			dpsMult /= GetAttribute(weapon, "halloween fire rate bonus");
			dpsMult /= GetAttribute(weapon, "mult_item_meter_charge_rate");
			dpsMult /= GetAttribute(weapon, "weapon fire rate");
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

			if(critMod)
			{
				if(TF2_IsPlayerCritBuffed(client))
				{
					dpsMult *= 3.0;
				}
				else if(TF2_IsPlayerMinicritBuffed(client))
				{
					dpsMult *= 1.35;
				}
			}
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
			Address supernovaPowerup = TF2Attrib_GetByName(client, "spawn with physics toy");
			if(supernovaPowerup != Address_Null)
			{
				float supernovaPowerupValue = TF2Attrib_GetValue(supernovaPowerup);
				if(supernovaPowerupValue > 1.0){
					dpsMult *= Pow(supernovaPowerupValue,3.0)
				}
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
stock bool LookPoint(client, float dest[3])
{
    float ang[3];
    float pos[3];
    
    GetClientEyePosition(client, pos);
    GetClientEyeAngles(client, ang);
    
    Handle trace = TR_TraceRayFilterEx(pos, ang, MASK_SHOT, RayType_Infinite, FilterPlayer, client);

    if(TR_DidHit(trace))
    {        
        TR_GetEndPosition(dest, trace);
    }
    else
    {
        CloseHandle(trace);
        return false;
    }
    
    CloseHandle(trace);
    return true;
}

public bool FilterPlayer(entity, contentsMask, any:data)
{
    return entity != data;
}
stock TF2_IsPlayerCritBuffed(client)
{
   if ( TF2_IsPlayerInCondition( client, TFCond_Kritzkrieged ) || TF2_IsPlayerInCondition( client, TFCond_HalloweenCritCandy )
        || TF2_IsPlayerInCondition( client, TFCond_CritCanteen ) || TF2_IsPlayerInCondition( client, TFCond_CritOnFirstBlood ) 
		|| TF2_IsPlayerInCondition( client, TFCond_CritOnWin )
        || TF2_IsPlayerInCondition( client, TFCond_CritOnFlagCapture ) || TF2_IsPlayerInCondition( client, TFCond_CritOnKill )
        || TF2_IsPlayerInCondition( client, TFCond_CritMmmph ) || TF2_IsPlayerInCondition( client, TFCond_CritOnDamage )
        || TF2_IsPlayerInCondition( client, TFCond_CritRuneTemp ) )
    {
        return true; 
    }
    return false; 
}
stock TF2_IsPlayerMinicritBuffed(client)
{
   if ( TF2_IsPlayerInCondition( client, TFCond_Buffed ) || TF2_IsPlayerInCondition( client, TFCond_CritCola )
		|| TF2_IsPlayerInCondition( client, TFCond_NoHealingDamageBuff ) || TF2_IsPlayerInCondition( client, TFCond_MiniCritOnKill ))
    {
        return true; 
    }
    return false; 
}
stock TF2_IsPlayerMinicritDebuffed(client)
{
   if ( TF2_IsPlayerInCondition( client, TFCond_MarkedForDeath ) || TF2_IsPlayerInCondition( client, TFCond_MarkedForDeathSilent )
		|| TF2_IsPlayerInCondition( client, TFCond_PasstimePenaltyDebuff ) || TF2_IsPlayerInCondition( client, TFCond_Jarated ))
    {
        return true; 
    }
    return false; 
}
stock TF2_IsPlayerCritImmune(client)
{
   if ( TF2_IsPlayerInCondition( client, TFCond_UberBulletResist ) || TF2_IsPlayerInCondition( client, TFCond_UberBlastResist )
		|| TF2_IsPlayerInCondition( client, TFCond_UberFireResist ) || TF2_IsPlayerInCondition( client, TFCond_DefenseBuffed ))
    {
        return true; 
    }
    return false; 
}
stock bool PlayerRazorbackIsActive(client)
{
    return GetEntPropFloat(client, Prop_Send, "m_flItemChargeMeter", TFWeaponSlot_Secondary) >= 100.0; 
} 

stock GetIndexOfWeaponSlot(client, slot)
{
	int weapon=GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEdict(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}
stock AttachTrail(ent, client)
{
	float m_fOrigin[3], m_fAngle[3];
	float m_fTemp[3] = {0.0, 90.0, 0.0};
	GetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fAngle);
	SetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fTemp);
	float m_fPosition[3];
	m_fPosition[0] = 0.0;
	m_fPosition[1] = 0.0;
	m_fPosition[2]= 0.0;
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", m_fOrigin);
	AddVectors(m_fOrigin, m_fPosition, m_fOrigin);
	TeleportEntity(ent, m_fOrigin, m_fTemp, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent);
	SetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fAngle);
}
stock CreateSpriteTrail(int iEntity, char[] lifetime, char[] startwidth, char[] endwidth, char[] spritename, char[] rendercolor)
{
	int spriteTrail = CreateEntityByName("env_spritetrail");
	if (IsValidEdict(spriteTrail))
	{
		SetEntPropFloat(spriteTrail, Prop_Send, "m_flTextureRes", 0.05);
		DispatchKeyValue(spriteTrail, "lifetime", lifetime );
		DispatchKeyValue(spriteTrail, "startwidth", startwidth );
		DispatchKeyValue(spriteTrail, "endwidth", endwidth );
		DispatchKeyValue(spriteTrail, "spritename", spritename);
		DispatchKeyValue(spriteTrail, "renderamt", "255" );
		DispatchKeyValue(spriteTrail, "rendercolor", rendercolor);
		DispatchKeyValue(spriteTrail, "rendermode", "5");
		DispatchSpawn(spriteTrail);
		AttachTrail(spriteTrail, iEntity);
	}
	return spriteTrail;
}
stock CreateSprite(iClient, char[] sprite, float offset)
{
	char szTemp[64]; 
	Format(szTemp, sizeof(szTemp), "client%i", iClient);
	DispatchKeyValue(iClient, "targetname", szTemp);

	float vOrigin[3];
	GetClientAbsOrigin(iClient, vOrigin);
	vOrigin[2] += offset;
	int ent = CreateEntityByName("env_sprite_oriented");
	if (ent)
	{
		DispatchKeyValue(ent, "model", sprite);
		DispatchKeyValue(ent, "classname", "env_sprite_oriented");
		DispatchKeyValue(ent, "spawnflags", "1");
		DispatchKeyValue(ent, "scale", "0.1");
		DispatchKeyValue(ent, "rendermode", "1");
		DispatchKeyValue(ent, "rendercolor", "255 255 255");
		DispatchKeyValue(ent, "targetname", "donator_spr");
		DispatchKeyValue(ent, "parentname", szTemp);
		DispatchSpawn(ent);
		
		TeleportEntity(ent, vOrigin, NULL_VECTOR, NULL_VECTOR);
	}
	return ent;
}

stock char[] GetAlphabetForm(float number)
{
	char output[64];
	if(number <= 0.0)//Prevent logmarithm from undefining.
	{
		IntToString(RoundToNearest(number), output, sizeof(output));
		return output;
	}
	int digits = RoundToFloor(Logarithm(number))+1;
	
	switch(digits)
	{
		case 0://Decimals
		{
			FloatToString(number, output, sizeof(output));
			Format(output, sizeof(output), "%.4s", output);
		}
		case 1://Singles
		{
			FloatToString(number, output, sizeof(output));
			Format(output, sizeof(output), "%.4s", output);
		}
		case 2:
		{
			FloatToString(number, output, sizeof(output));
			Format(output, sizeof(output), "%.5s", output);
		}
		case 3:
		{
			FloatToString(number, output, sizeof(output));
			Format(output, sizeof(output), "%.6s", output);
		}
		case 4://Thousands
		{
			FloatToString(RoundToFloor(number/10.0)/100.0, output, sizeof(output));
			Format(output, sizeof(output), "%.4s", output);
			StrCat(output, sizeof(output), "K");
		}
		case 5:
		{
			FloatToString(RoundToFloor(number/10.0)/100.0, output, sizeof(output));
			Format(output, sizeof(output), "%.5s", output);
			StrCat(output, sizeof(output), "K");
		}
		case 6:
		{
			FloatToString(RoundToFloor(number/10.0)/100.0, output, sizeof(output));
			Format(output, sizeof(output), "%.6s", output);
			StrCat(output, sizeof(output), "K");
		}
		case 7://Millions
		{
			FloatToString(RoundToFloor(number/10000.0)/100.0, output, sizeof(output));
			Format(output, sizeof(output), "%.4s", output);
			StrCat(output, sizeof(output), "M");
		}
		case 8:
		{
			FloatToString(RoundToFloor(number/10000.0)/100.0, output, sizeof(output));
			Format(output, sizeof(output), "%.5s", output);
			StrCat(output, sizeof(output), "M");
		}
		case 9:
		{
			FloatToString(RoundToFloor(number/10000.0)/100.0, output, sizeof(output));
			Format(output, sizeof(output), "%.6s", output);
			StrCat(output, sizeof(output), "M");
		}
		case 10://Billions
		{
			FloatToString(RoundToFloor(number/10000000.0)/100.0, output, sizeof(output));
			Format(output, sizeof(output), "%.4s", output);
			StrCat(output, sizeof(output), "B");
		}
		case 11:
		{
			FloatToString(RoundToFloor(number/10000000.0)/100.0, output, sizeof(output));
			Format(output, sizeof(output), "%.5s", output);
			StrCat(output, sizeof(output), "B");
		}
		case 12:
		{
			FloatToString(RoundToFloor(number/10000000.0)/100.0, output, sizeof(output));
			Format(output, sizeof(output), "%.6s", output);
			StrCat(output, sizeof(output), "B");
		}
		case 13://Trillions
		{
			FloatToString(RoundToFloor(number/10000000000.0)/100.0, output, sizeof(output));
			Format(output, sizeof(output), "%.4s", output);
			StrCat(output, sizeof(output), "T");
		}
		case 14:
		{
			FloatToString(RoundToFloor(number/10000000000.0)/100.0, output, sizeof(output));
			Format(output, sizeof(output), "%.5s", output);
			StrCat(output, sizeof(output), "T");
		}
		case 15:
		{
			FloatToString(RoundToFloor(number/10000000000.0)/100.0, output, sizeof(output));
			Format(output, sizeof(output), "%.6s", output);
			StrCat(output, sizeof(output), "T");
		}
		default:
		{
			FloatToString(number/Pow(10.0,float(digits-1)), output, sizeof(output));
			Format(output, sizeof(output), "%.4se%i", output,digits-1);
		}
	}
	return output;
}
//Attributes
stock bool TF2_AttribListAttributesBySlot(client, iSlot = -1) 
{ 
    int iAttribList[128]; 
    float flAttribValues[128]; 
    Address aAttr; 
    decl iEntity; 

    switch (iSlot) 
    { 
        case -1: 
        { 
            iEntity = client;
        }
		case 5:
		{
			iEntity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		}
        default: 
        { 
            iEntity = GetWeapon(client, iSlot); 
            if (!IsValidEdict(iEntity)) 
            { 
                PrintToChat(client, "----- No weapon found for (%N) in slot (%i) -----", client, iSlot); 
                return false; 
            } 
        } 
    } 

    PrintToChat(client, "----- Listing attributes for (%N) in slot (%i) -----", client, iSlot); 

    int iCount = TF2Attrib_ListDefIndices(iEntity, iAttribList); 
    if (iCount > 0) 
    { 
        for (int i = 0; i < iCount; ++i) 
        {
            aAttr = TF2Attrib_GetByDefIndex(iEntity, iAttribList[i]); 
            flAttribValues[i] = TF2Attrib_GetValue(aAttr); 
            PrintToChat(client, "Attrib %i: %i ; %0.4f", i+1, iAttribList[i], flAttribValues[i]); 
        } 
    } 
    else 
    { 
        PrintToChat(client, "----- No attributes found for (%N) in slot (%i) -----", client, iSlot); 
    }
	//int weapon = GetWeapon(client,iSlot);
	//PrintToChatAll("%i weapon",weapon);
    return true; 
}
stock int EHandleToEntIndex(int ehandle) {
	return EntRefToEntIndex(ehandle | (1 << 31));
}
//Ammo
stock SetCarriedAmmo( client, slot, newAmmo )
{
    if ( IsValidClient3( client ) )
    {
        int weapon = GetPlayerWeaponSlot( client, slot ); 
        if ( IsValidEdict( weapon ) )
        {
            int type = GetEntProp( weapon, Prop_Send, "m_iPrimaryAmmoType" ); 
            if ( type > 0 || type < 31 ) SetEntProp( client, Prop_Send, "m_iAmmo", newAmmo, _, type ); 
        }
    }
}
stock GetCarriedAmmo( client, slot )
{
    if ( IsValidClient3( client ) )
    {
        int weapon = GetPlayerWeaponSlot( client, slot ); 
        if ( IsValidEdict( weapon ) )
        {
            int type = GetEntProp( weapon, Prop_Send, "m_iPrimaryAmmoType" ); 
            if ( type > 0 && type < 31 )
                return GetEntProp( client, Prop_Send, "m_iAmmo", _, type ); 
        }
    }
    return 0; 
}
stock SetClipAmmo( client, slot, ammo )
{
    if ( IsValidClient3( client ) )
    {
        int weapon = GetPlayerWeaponSlot( client, slot ); 
        if ( IsValidEdict( weapon ) )
            SetEntProp( weapon, Prop_Send, "m_iClip1", ammo ); 
    }
}
stock GetClipAmmo( client, slot )
{
    if ( IsValidClient3( client ) )
    {
        int weapon = GetPlayerWeaponSlot( client, slot ); 
        if ( IsValidEdict( weapon ) )
            return GetEntProp( weapon, Prop_Data, "m_iClip1" ); 
    }
    return 0; 
}
stock SetLoadedAmmo( client, slot, ammo = -1, ammo2 = -1 )
{
    if ( IsValidClient3( client ) )
    {
        int weapon = GetPlayerWeaponSlot( client, slot ); 
        if( IsValidEdict( weapon ) )
        {
            if ( ammo >= 0 ) SetEntData( client, FindSendPropInfo( "CTFPlayer", "m_iAmmo" )+4, ammo ); 
            if ( ammo >= 0 ) SetEntData( client, FindSendPropInfo( "CTFPlayer", "m_iAmmo" )+8, ammo ); 
            if ( ammo2 >= 0 ) SetEntData( weapon, FindSendPropInfo( "CBaseCombatWeapon", "m_iClip1" ), ammo2, 4 ); 
        }
    }
}
stock GetLoadedAmmo( client, slot )
{
    if ( IsValidClient3( client ) )
    {
        int weapon = GetPlayerWeaponSlot( client, slot ); 
        if ( IsValidEdict( weapon ) )
        {
            int iOffset = GetEntProp( weapon, Prop_Send, "m_iPrimaryAmmoType", 1 )*4; 
            int iAmmoTable = FindSendPropInfo( "CTFPlayer", "m_iAmmo" ); 
            return GetEntData( client, iAmmoTable+iOffset ); 
        }
    }
    return 0; 
}
stock void SendItemInfo(int client, const char[] text)
{
	Handle hBuffer = StartMessageOne("KeyHintText", client);
	BfWriteByte(hBuffer, 1);
	BfWriteString(hBuffer, text);
	EndMessage();
}
stock int GetClientBaseHP(client){
	int HP;
	switch(TF2_GetPlayerClass(client)){
		case TFClass_Scout, TFClass_Engineer, TFClass_Spy, TFClass_Sniper: {HP=125;}
		case TFClass_Medic: {HP=150;}
		case TFClass_Pyro, TFClass_DemoMan: {HP=175;}
		case TFClass_Soldier: {HP=200;}
		case TFClass_Heavy: {HP=300;}
	}
	
	for(int i = 0; i<5; ++i){
		int weap = TF2Util_GetPlayerLoadoutEntity(client, i);
		if(!IsValidWeapon(weap))
			continue;

		HP += RoundToCeil(GetAttribute(weap, "max health additive bonus", 0.0));
		HP += RoundToCeil(GetAttribute(weap, "max health additive penalty", 0.0));
	}

	HP += RoundToCeil(GetAttribute(client, "max health additive bonus", 0.0));
	HP += RoundToCeil(GetAttribute(client, "max health additive penalty", 0.0));

	return HP;
}
stock DealFakeDamage(victim, attacker, weapon = -1, damage = 0, custom = 0)
{
    Event event = CreateEvent("player_hurt");
    if (event == null)
    {
        return;
    }
    event.SetInt("userid", GetClientUserId(victim)); //Victim
    event.SetInt("attacker", GetClientUserId(attacker)); //Attacker
    event.SetInt("weaponid", weapon); //Weapon
	event.SetInt("damageamount", damage); //Weapon
	event.SetInt("custom", custom);
    event.Fire();
}
stock Action  SetTransmit(int entity, int client) 
{ 
	SetFlags(entity);
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(client == owner) return Plugin_Continue;	// draw
	else return Plugin_Stop; // not draw
} 
public void SetFlags(int entity) 
{ 
	if (GetEdictFlags(entity) & FL_EDICT_ALWAYS) 
	{ 
		SetEdictFlags(entity, (GetEdictFlags(entity) ^ FL_EDICT_ALWAYS)); 
	} 
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
			SDKHooks_TakeDamage(victim,attacker,attacker,damage, damagetype,weapon,NULL_VECTOR,NULL_VECTOR,!IsValidClient3(victim));
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
stock Action ReEnableBuilding(Handle timer, int entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEdict(entity))
	{
		SetEntProp(entity, Prop_Send, "m_bDisabled", 0);
	}
	return Plugin_Continue;
}
stock Action Timer_TerminateParticle(Handle timer, any data)
{
	int entity = EntRefToEntIndex(data);
	if (IsValidEdict(entity)){
		AcceptEntityInput(entity, "DestroyImmediately");
	}
	
	return Plugin_Stop;
}
stock Action Timer_MoveParticle(Handle timer, any data)
{
	int entity = EntRefToEntIndex(data);
	if (IsValidEdict(entity))
		TeleportEntity(entity, {9999.0,9999.0,9999.0}, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Stop;
}
stock Action Timer_RemoveEntity(Handle timer, any data)
{	
	int entity = EntRefToEntIndex(data);
	if (IsValidEdict(entity))
		RemoveEntity(entity);
	
	return Plugin_Stop;
}
stock Action Timer_KillParticle(Handle timer, any data)
{	
	int entity = EntRefToEntIndex(data);
	if (IsValidEdict(entity))
	{
		AcceptEntityInput(entity, "Stop");
		CreateTimer(2.0, Timer_RemoveEntity, data);
	}
	return Plugin_Stop;
}
stock Action Timer_KillTEParticle(Handle timer, Handle pack)
{
	ResetPack(pack);	
	int entity = EntRefToEntIndex(ReadPackCell(pack));
	
	if (IsValidEdict(entity))
	{
		SetVariantString("ParticleEffectStop");
		AcceptEntityInput(entity, "DispatchEffect");
	}
	
	return Plugin_Stop;
}
stock SetAmmo_Weapon(weapon, newAmmo)
{
	int owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (owner == -1) return;
	int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
	int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	SetEntData(owner, iAmmoTable+iOffset, newAmmo, 4, true);
}
stock DelayedTeleportEntity(Handle pack)
{
	ResetPack(pack);	
	int entity = EntRefToEntIndex(ReadPackCell(pack));
	float origin[3]
	float angles[3] 
	float velocity[3]
	for(int i=0;i<3;++i)
	{
		origin[i] = ReadPackFloat(pack);
		angles[i] = ReadPackFloat(pack);
		velocity[i] = ReadPackFloat(pack);
	}
	if (IsValidEdict(entity))
	{
		if(GetVectorLength(origin) == 0.0)
		{
			TeleportEntity(entity, NULL_VECTOR, angles, velocity);
		}
		else if (GetVectorLength(origin) == 0.0 && GetVectorLength(angles) == 0.0)
		{
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, velocity);
		}
		else if (GetVectorLength(angles) == 0.0)
		{
			TeleportEntity(entity, origin, NULL_VECTOR, velocity);
		}
	}
	delete pack
}
stock TE_SetupKillPlayerAttachments(client) {
  TE_Start("KillPlayerAttachments");
  TE_WriteNum("m_nPlayer", client);
}
stock bool IsStringBlank(const char[] input)
{
	int len = strlen(input);
	for (int i=0; i<len; ++i)
	{
		if (!IsCharSpace(input[i]))
		{
			return false;
		}
	}
	return true;
}