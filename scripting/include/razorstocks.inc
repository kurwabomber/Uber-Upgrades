/*
Yeah.
 */
#include <tf2wearables>
#include <sdkhooks>
#include <tf2attributes>
#include <tf2itemsinfo>
#include <tf_econ_data>
#pragma tabsize 0
#define ExplosionSound1 "weapons/explode1.wav"
#define ExplosionSound2 "weapons/explode2.wav"
#define ExplosionSound3 "weapons/explode3.wav"
#define SmallExplosionSound1 "weapons/airstrike_small_explosion_01.wav"
#define SmallExplosionSound2 "weapons/airstrike_small_explosion_02.wav"
#define SmallExplosionSound3 "weapons/airstrike_small_explosion_03.wav"
#define DetonatorExplosionSound "weapons/flare_detonator_explode.wav"
#define MAXENTITIES 2049
#define PI 3.142

new bool:DOTStacked[MAXENTITIES][MAXENTITIES];
new bool:ShouldNotHome[MAXENTITIES][MAXPLAYERS+1];
stock bool:IsValidClient(client)
{
    if ( client <= 0 || client > MaxClients ) return false; 
	if ( !IsClientInGame(client) ) return false;
    if ( IsFakeClient( client ) ) return false; 
	
    return true; 
}
stock bool:IsValidClient3(client)
{
    if ( client <= 0 || client > MaxClients ) return false; 
	if ( !IsClientInGame(client) ) return false;
    return true; 
}
stock bool:IsValidForDamage(entity)
{
    if (!IsValidEntity(entity)) return false; 
	if(IsValidClient3(entity) && (!IsPlayerAlive(entity) || IsClientObserver(entity))) return false;	
	if(HasEntProp(entity, Prop_Data, "m_hActiveWeapon")) return true;
	if(GetEntProp(entity, Prop_Data, "m_takedamage") == 0) return false;
    return false; 
}
stock int IntAbs(int val)
{
   return (val < 0) ? -val : val;
} 
stock bool:IsOnDifferentTeams(entity1,entity2)
{
	new iTeam = -10;
	if(HasEntProp(entity1, Prop_Send, "m_iTeamNum"))
	{
		iTeam = GetEntProp(entity1, Prop_Send, "m_iTeamNum");
	}
	new team = -10;
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
stock char[] getDamageCategory(int damagetype)
{
	char damageCategory[64];
	if(damagetype & DMG_BULLET || damagetype & DMG_SLASH || damagetype & DMG_VEHICLE || damagetype & DMG_FALL || damagetype & DMG_CLUB || damagetype & DMG_BUCKSHOT)
	{
		damageCategory = "direct"
	}
	else if(damagetype & DMG_BLAST || damagetype & DMG_BLAST_SURFACE)
	{
		damageCategory = "blast"
	}
	else if(damagetype & DMG_BURN || damagetype & DMG_SLOWBURN || damagetype & DMG_IGNITE)
	{
		damageCategory = "fire"
	}
	else if(damagetype & DMG_SHOCK || damagetype & DMG_ENERGYBEAM)
	{
		damageCategory = "electric"
	}
	else if(damagetype & 1073741824)
	{
		damageCategory = "arcane"
	}
	else
	{
		damageCategory = "generic"
	}
	return damageCategory;
}
stock bool IsValidWeapon(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && HasEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"));
}
stock int getOwner(int entity)
{
	return HasEntProp(entity, Prop_Data, "m_hOwnerEntity") ? GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") : -1;
}
stock int getWeaponSlot(int client, int entity)
{
	return _:TF2II_GetListedItemSlot(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"),TF2_GetPlayerClass(client));
}
void GetCleaverAngularImpulse(float vecAngImpulse[3]) {
	vecAngImpulse[0] = 0.0;
	vecAngImpulse[1] = 1000.0;
	vecAngImpulse[2] = 0.0;
}
stock int CreateLink(int iClient, bool:attach=false)
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
    if(IsValidEntity(entity))
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
stock Entity_Create(const String:className[], ForceEdictIndex=-1)
{
	if (ForceEdictIndex != -1 && Entity_IsValid(ForceEdictIndex)) {
		return INVALID_ENT_REFERENCE;
	}

	return CreateEntityByName(className, ForceEdictIndex);
}
stock Entity_PointHurtAtTarget(entity, target, const String:name[]="")
{
	decl String:targetName[128];
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
stock Entity_SetClassName(entity, const String:className[])
{
	return DispatchKeyValue(entity, "classname", className);
}
stock Entity_GetTargetName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_target", buffer, size);
}
stock Entity_IsValid(entity)
{
	return IsValidEntity(entity);
}
stock Entity_SetName(entity, const String:name[], any:...)
{
	decl String:format[128];
	VFormat(format, sizeof(format), name, 3);

	return DispatchKeyValue(entity, "targetname", format);
}
stock refreshAllWeapons(client)
{
	TF2Attrib_ClearCache(client);
	for(new i=0;i<5;i++)
	{
		new weapon = GetWeapon(client,i);
		if(IsValidEntity(weapon))
		{
			TF2Attrib_ClearCache(weapon);
		}
	}
}
stock EntityExplosion(owner, Float:damage, Float:radius, Float:pos[3], soundType = 0, bool:visual = true, entity = -1, Float:soundLevel = 0.65,damagetype = DMG_BLAST, weapon = -1, Float:falloff = 0.0, soundPriority = 100, bool:ignition = false)
{
	if(entity == -1 || !IsValidEntity(entity))
		entity = owner;
	for(new i = 1; i < MAXENTITIES; i++)
	{
		if(IsValidForDamage(i) && IsOnDifferentTeams(owner,i) && i != entity)
		{
			new Float:targetvec[3];
			new Float:distance;
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", targetvec);
			distance = GetVectorDistance(pos, targetvec, false)
			if(distance <= radius)
			{
				if(IsPointVisible(pos,targetvec))
				{
					if(falloff != 0.0)
					{
						new Float:ratio = (1.0-(distance/radius)*falloff);
						if(ratio < 0.5)
							ratio = 0.5;
						if(ratio >= 0.95)
							ratio = 1.0;
						damage *= ratio
					}
					
					if(IsValidEntity(weapon) && IsValidClient3(i))
					{
						SDKHooks_TakeDamage(i,owner,owner,damage, damagetype,weapon,NULL_VECTOR,NULL_VECTOR)
						if(ignition)
							TF2_IgnitePlayer(i, owner, 7.0);
					}
					else
					{
						SDKHooks_TakeDamage(i,owner,owner,damage, damagetype,-1,NULL_VECTOR,NULL_VECTOR, false);
					}
				}
			}
		}
	}
	if(visual)
	{
		/*new particle = CreateEntityByName( "info_particle_system" );
		if ( IsValidEntity( particle ) )
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
		CreateParticle(-1, "ExplosionCore_MidAir", false, "", 0.1, pos);
	}
	new random = GetRandomInt(1,3)
	switch(soundType)
	{
		case 1:
		{
			if(random == 1){
				EmitSoundToAll(ExplosionSound1, entity,_,soundPriority,_,soundLevel);
				EmitSoundToAll(ExplosionSound1, entity,_,soundPriority,_,soundLevel);
				EmitSoundToAll(ExplosionSound1, entity,_,soundPriority,_,soundLevel);
			}else if(random == 2){
				EmitSoundToAll(ExplosionSound2, entity,_,soundPriority,_,soundLevel);
				EmitSoundToAll(ExplosionSound2, entity,_,soundPriority,_,soundLevel);
				EmitSoundToAll(ExplosionSound2, entity,_,soundPriority,_,soundLevel);
			}else if(random == 3){
				EmitSoundToAll(ExplosionSound3, entity,_,soundPriority,_,soundLevel);
				EmitSoundToAll(ExplosionSound3, entity,_,soundPriority,_,soundLevel);
				EmitSoundToAll(ExplosionSound3, entity,_,soundPriority,_,soundLevel);
			}
		}
		case 2:
		{
			EmitSoundToAll(DetonatorExplosionSound, entity, -1, soundPriority-20, 0, soundLevel-0.15);
		}
		default:
		{
			if(random == 1){
				EmitSoundToAll(ExplosionSound1, entity,_,soundPriority,_,soundLevel);
			}else if(random == 2){
				EmitSoundToAll(ExplosionSound2, entity,_,soundPriority,_,soundLevel);
			}else if(random == 3){
				EmitSoundToAll(ExplosionSound3, entity,_,soundPriority,_,soundLevel);
			}
		}
	}
}
public bool:TraceEntityFilterPlayer(entity, contentsMask){
     return entity > MaxClients || !entity;
}
stock Circle(Float:vecLocation[3], Float:radius, BeamSpriteCircle,HaloSpriteCircle,segments=20,Float:delayBetween=0.0,Float:lifetime=0.3, red=255,green=255,blue=255,alpha=255)
{
    new Float:angle=0.0, Float:x, Float:y,i;
    
    new Float:pos1[3];
    new Float:pos2[3];
	
	new color[4];
	color[0] = red
	color[1] = green
	color[2] = blue
	color[3] = alpha
    //Create the start position for the first part of the beam
    pos2[0] = vecLocation[0];
    pos2[1] = vecLocation[1] + radius;
    pos2[2] = vecLocation[2];
    
    while (angle <= 2 * PI + (PI/segments))
    {
        x = radius * Cosine(angle);
        y = radius * Sine(angle);
        
        pos1[0] = vecLocation[0];
        pos1[1] = vecLocation[1] + x;
        pos1[2] = vecLocation[2] + y;
		
		if(delayBetween != 0.0)
		{
			new Handle:hPack = CreateDataPack();
			WritePackFloat(hPack, pos1[0]);
			WritePackFloat(hPack, pos1[1]);
			WritePackFloat(hPack, pos1[2]);
			
			WritePackFloat(hPack, pos2[0]);
			WritePackFloat(hPack, pos2[1]);
			WritePackFloat(hPack, pos2[2]);
			
			WritePackCell(hPack, BeamSpriteCircle);
			WritePackCell(hPack, HaloSpriteCircle);
			
			WritePackFloat(hPack, lifetime);
			
			WritePackCell(hPack, red);
			WritePackCell(hPack, green);
			WritePackCell(hPack, blue);
			WritePackCell(hPack, alpha);
			
			CreateTimer(i*delayBetween,delayBeamPoint,hPack);
		}
		else
		{
			TE_SetupBeamPoints(pos1, pos2, BeamSpriteCircle, HaloSpriteCircle, 0, 30, lifetime, Float:5.0, Float:5.0, 0, 0.0, color, 10);
			TE_SendToAll();
        }
        pos2[0] = pos1[0];
        pos2[1] = pos1[1];
        pos2[2] = pos1[2];
        
        angle += PI/segments;
		i++
    }
}
public Action:delayBeamPoint(Handle:timer, any:hPack) 
{ 
    new Float:pos1[3],Float:pos2[3],Float:lifetime;
	new color[4],BeamSpriteCircle,HaloSpriteCircle;
	ResetPack(hPack);
	pos1[0] = ReadPackFloat(hPack);
	pos1[1] = ReadPackFloat(hPack);
	pos1[2] = ReadPackFloat(hPack);
	
	pos2[0] = ReadPackFloat(hPack);
	pos2[1] = ReadPackFloat(hPack);
	pos2[2] = ReadPackFloat(hPack);
	
	BeamSpriteCircle = ReadPackCell(hPack);
	HaloSpriteCircle = ReadPackCell(hPack);
	
	lifetime = ReadPackFloat(hPack);
	
	color[0] = ReadPackCell(hPack);
	color[1] = ReadPackCell(hPack);
	color[2] = ReadPackCell(hPack);
	color[3] = ReadPackCell(hPack);
			
	TE_SetupBeamPoints(pos1, pos2, BeamSpriteCircle, HaloSpriteCircle, 0, 30, lifetime, Float:5.0, Float:5.0, 0, 0.0, color, 10);
	TE_SendToAll();
	CloseHandle(hPack);
}
stock float GetResistance(int client, bool includeReduction = false, float increaseBase = 0.0, float increaseMult = 0.0)
{
	if(IsValidClient3(client))
	{
		new Address:capActive = TF2Attrib_GetByName(client, "tool escrow until date")
		new Address:Defense = TF2Attrib_GetByName(client, "is throwable chargeable");
		new Float:TotalResistance = 1.0;
		new Float:DefenseMult = 1.0;
		new Float:ArmorMult = 1.0;
		
		if(capActive != Address_Null)
			ArmorMult = TF2Attrib_GetValue(capActive);
		if(Defense != Address_Null)
			DefenseMult = TF2Attrib_GetValue(Defense);
		/*if(TF2_IsPlayerInCondition(client, TFCond_NoTaunting_DEPRECATED))
		{
			ArmorMult -= 1.0;
			if(ArmorMult <= 0.0)
			{
				ArmorMult = 0.01;
			}
		}*/
		
		ArmorMult += increaseBase;
		DefenseMult += increaseMult;
		
		TotalResistance = Pow(ArmorMult*DefenseMult, 2.35);
		if(includeReduction)
		{
			new Address:dmgReduction = TF2Attrib_GetByName(client, "sniper zoom penalty");
			if(dmgReduction != Address_Null)
			{
				TotalResistance /= TF2Attrib_GetValue(dmgReduction);
			}
		}
		return TotalResistance;
	}
	return 1.00;
}
stock Float:GetPlayerDistance(client1,client2)
{
	static Float:vec1[3];
	static Float:vec2[3];
	GetClientAbsOrigin(client1,vec1);
	GetClientAbsOrigin(client2,vec2);
	return GetVectorDistance(vec1,vec2);
}
stock MoveForward(const Float:vPos[3], const Float:vAng[3], Float:vReturn[3], Float:fDistance)
{
    decl Float:vDir[3];
    GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
    vReturn = vPos;
    vReturn[0] += vDir[0] * fDistance;
    vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}
stock GetClosestTarget(entity, owner, bool:isFriendly = false, bool:pierceWalls = false)
{
	new Float:TargetDistance = 0.0;
	new ClosestTarget = 0;
	for(new i = 1; i <= MaxClients; i++) 
	{
		if(ShouldNotHome[entity][i] || !IsValidClient3(i) || !IsValidClient3(owner) || i == owner || (!isFriendly && GetClientTeam(owner) == GetClientTeam(i)) || (isFriendly && GetClientTeam(owner) != GetClientTeam(i)) || !IsValidForHoming( i, owner, entity) || !IsAbleToSee(owner, i)) continue;
		new Float:EntityLocation[3], Float:TargetLocation[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", EntityLocation);
		GetClientAbsOrigin(i, TargetLocation);
		if(pierceWalls == false)
		{
			new Handle:hTrace = TR_TraceRayFilterEx( TargetLocation, EntityLocation, MASK_SOLID, RayType_EndPoint, TraceFilterIgnoreSelf, entity ); 
			if( hTrace != INVALID_HANDLE )
			{
				if( TR_DidHit( hTrace ) )
				{
					CloseHandle( hTrace ); 
					continue; 
				}
				
				CloseHandle( hTrace ); 
				new Float:distance = GetVectorDistance(EntityLocation, TargetLocation);
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
			new Float:distance = GetVectorDistance(EntityLocation, TargetLocation);
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
	for(new i=0;i<times;i++)
	{
		new Float:EndPos[3];
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
stock CreateSmoke(float location[3],float time,int red,int green, int blue,String:SmokeTransparency[],String:SmokeDensity[])
{
	new SmokeEnt = CreateEntityByName("env_smokestack");

	new String:originData[64];
	Format(originData, sizeof(originData), "%f %f %f", location[0], location[1], location[2]);
	
	new String:SmokeColor[128];
	
	Format(SmokeColor, sizeof(SmokeColor), "%i %i %i", red, green, blue);
	
	new Float:timeTaken = time;
	
	if(SmokeEnt)
	{
		// Create the Smoke
		new String:SName[128];
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

		new Handle:pack
		CreateDataTimer(timeTaken, Timer_KillSmoke, pack)
		WritePackCell(pack, SmokeEnt);
		
		//Start timer to remove smoke
		new Float:longerdelay = 5.0 + timeTaken;
		new Handle:pack2
		CreateDataTimer(longerdelay, Timer_StopSmoke, pack2)
		WritePackCell(pack2, SmokeEnt);
	}
}

public Action:Timer_KillSmoke(Handle:timer, Handle:pack)
{	
	ResetPack(pack)
	new SmokeEnt = ReadPackCell(pack)
	
	StopSmokeEnt(SmokeEnt);
}

StopSmokeEnt(target)
{

	if (IsValidEntity(target))
	{
		AcceptEntityInput(target, "TurnOff");
	}
}

public Action:Timer_StopSmoke(Handle:timer, Handle:pack)
{	
	ResetPack(pack)
	new SmokeEnt = ReadPackCell(pack)
	
	RemoveSmokeEnt(SmokeEnt);
}

RemoveSmokeEnt(target)
{
	if (IsValidEntity(target))
	{
		AcceptEntityInput(target, "Kill");
	}
}
public bool:TraceFilterIgnoreSelf( entity, contentsMask, any:hiok )
{
    if ( entity == hiok || entity > 0 && entity <= MaxClients ) return false; 
    return true; 
}
stock bool:IsValidForHoming( client, owner, entity)
{
    if ( IsValidClient3( owner ) && IsValidClient3( client ) && IsValidEntity( entity ) )
    {
        new Float:OwnerPos[3], Float:TargetPos[3]; 
        GetClientAbsOrigin( owner, OwnerPos ); 
        GetClientAbsOrigin( client, TargetPos ); 
        new Float:distance_d = GetVectorDistance( OwnerPos, TargetPos ); 
        if ( distance_d <= 146.0 ) return false; 
    
        new team = GetEntProp( entity, Prop_Send, "m_iTeamNum" ); 
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
public Action:InitialWaitHomingSentryRocketThink(Handle:timer, any:ref)
{
	CreateTimer(0.03, HomingSentryRocketThink, ref, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public Action:HomingFlareThink(Handle:timer, any:ref) 
{
	new entity = EntRefToEntIndex(ref); 
	new bool:flag = false;
	if(IsValidEntity(entity))
    {
		if(!HasEntProp(entity,Prop_Send,"m_vInitialVelocity"))
		{
			flag = true;
		}
		new owner = GetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity" ); 
		if(!IsValidClient3(owner) && IsValidEntity(owner) && HasEntProp(owner,Prop_Send,"m_hBuilder"))
		{
			owner = GetEntPropEnt(owner,Prop_Send,"m_hBuilder" );
		}
		if (IsValidClient3(owner))
		{
			new Target = GetClosestTarget(entity, owner, false, true); 
			if(IsValidClient3(Target))
			{
				if(owner != Target)
				{
					new Float:EntityPos[3], Float:TargetPos[3]; 
					GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityPos ); 
					GetClientAbsOrigin( Target, TargetPos ); 
					new Float:distance = GetVectorDistance( EntityPos, TargetPos ); 
					if( distance <= 800.0 )
					{
						new Float:ProjLocation[3], Float:ProjVector[3], Float:BaseSpeed, Float:NewSpeed, Float:ProjAngle[3], Float:AimVector[3], Float:InitialSpeed[3]; 
						
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
}
public Action:HomingSentryRocketThink(Handle:timer, any:ref) 
{
	new entity = EntRefToEntIndex(ref); 
	new bool:flag = false;
	if(IsValidEntity(entity))
    {
		if(!HasEntProp(entity,Prop_Send,"m_vInitialVelocity"))
		{
			flag = true;
		}
		new owner = GetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity" ); 
		if(!IsValidClient3(owner) && IsValidEntity(owner) && HasEntProp(owner,Prop_Send,"m_hBuilder"))
		{
			owner = GetEntPropEnt(owner,Prop_Send,"m_hBuilder" );
		}
		if (IsValidClient3(owner))
		{
			new Target = GetClosestTarget(entity, owner); 
			if(IsValidClient3(Target))
			{
				if(owner != Target)
				{
					new Float:EntityPos[3], Float:TargetPos[3]; 
					GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityPos ); 
					GetClientAbsOrigin( Target, TargetPos ); 
					new Float:distance = GetVectorDistance( EntityPos, TargetPos ); 
					if( distance <= 1400.0 )
					{
						new Float:ProjLocation[3], Float:ProjVector[3], Float:BaseSpeed, Float:NewSpeed, Float:ProjAngle[3], Float:AimVector[3], Float:InitialSpeed[3]; 
						
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
}
public Action:HomingThink(Handle:timer, any:ref) 
{ 
	new entity = EntRefToEntIndex(ref); 
	new bool:flag = false;
	if(IsValidEntity(entity))
    {
		new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient3(owner))
		{
			new Target = GetClosestTarget(entity, owner); 
			if(IsValidClient3(Target))
			{
				new hClientWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(hClientWeapon))
				{
					new Address:homingActive = TF2Attrib_GetByName(hClientWeapon, "crit from behind");
					if(homingActive != Address_Null)
					{
						new Float:maxDistance = TF2Attrib_GetValue(homingActive)
						if(owner != Target)
						{
							new Float:EntityPos[3], Float:TargetPos[3];
							GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", EntityPos);
							GetClientAbsOrigin( Target, TargetPos ); 
							new Float:distance = GetVectorDistance( EntityPos, TargetPos ); 
							
							if( distance <= maxDistance )
							{
								new Float:ProjLocation[3], Float:ProjVector[3], Float:BaseSpeed, Float:NewSpeed, Float:ProjAngle[3], Float:AimVector[3], Float:InitialSpeed[3]; 
								
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
}
public Action:HeavyFriendlyHoming(Handle:timer, any:ref) 
{ 
	new entity = EntRefToEntIndex(ref); 
	new bool:flag = false;
	if(IsValidEntity(entity))
    {
		new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient3(owner))
		{
			new Target = GetClosestTarget(entity, owner, true); 
			if(IsValidClient3(Target))
			{
				if(owner != Target)
				{
					new Float:EntityPos[3], Float:TargetPos[3]; 
					GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityPos ); 
					GetClientAbsOrigin( Target, TargetPos ); 
					new Float:distance = GetVectorDistance( EntityPos, TargetPos ); 
					
					if( distance <= 800.0 )
					{
						new Float:ProjLocation[3], Float:ProjVector[3], Float:BaseSpeed, Float:NewSpeed, Float:ProjAngle[3], Float:AimVector[3], Float:InitialSpeed[3]; 
						
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
stock float getLowestPosition(float vec[3]) {
	float vecangles[3];
	float zAxis;
	vecangles[0] = 89.0;
	vecangles[1] = 0.0;
	vecangles[2] = 0.0;
    Handle traceray = TR_TraceRayFilterEx(vec, vecangles, MASK_SHOT_HULL, RayType_Infinite, TraceEntityFilterPlayer);
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
    Handle traceray = TR_TraceRayFilterEx(vec, vecangles, MASK_SHOT_HULL, RayType_Infinite, TraceEntityFilterPlayer);
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
public bool:TEF_ExcludeEntity(entity, contentsMask, any:data)
{
	return (entity != data);
}
stock int GetWeapon(int client, int slot)
{
	new itemID;
	if(IsValidClient3(client))
	{
		switch(slot)
		{
			case 0:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Primary);
			}
			case 1:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Secondary);
			}
			case 2:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Melee);
			}
			case 3:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Utility);
			}
			case 4:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Unknown1);
			}
			case 5:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Building);
			}
			case 6:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Unknown2);
			}
			case 7:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_PDA2);
			}
			case 8:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Misc1);
			}
			case 9:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Misc2);
			}
			case 10:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Action);
			}
			case 11:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Misc3);
			}
			case 12:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Taunt1);
			}
			case 13:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Taunt2);
			}
			case 14:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Taunt3);
			}
			case 15:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Taunt4);
			}
			case 16:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Taunt5);
			}
			case 17:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Taunt6);
			}
			case 18:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Taunt7);
			}
			case 19:
			{
				itemID = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Taunt8);
			}
			default:
			{
				return -1;
			}
		}
	}
	return itemID;
}
stock int GetHealingTarget(const int client)
{
    int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
    if (!IsValidEdict(medigun) || !IsValidEntity(medigun))
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
bool:IsAbleToSee(entity, client, bool:forWeapon = true)
{
    // Skip all traces if the player isn't within the field of view.
    // - Temporarily disabled until eye angle prediction is added.
    // if (IsInFieldOfView(g_vEyePos[client], g_vEyeAngles[client], g_vAbsCentre[entity]))
    
    decl Float:vecOrigin[3], Float:vecEyePos[3];
    GetClientAbsOrigin(entity, vecOrigin);
    GetClientEyePosition(client, vecEyePos);
    
    // Check if centre is visible.
    if (IsPointVisible(vecEyePos, vecOrigin))
    {
        return true;
    }
    
	if(forWeapon)
	{
		decl Float:vecEyePos_ent[3], Float:vecEyeAng[3];
		GetClientEyeAngles(entity, vecEyeAng);
		GetClientEyePosition(entity, vecEyePos_ent);
		// Check if weapon tip is visible.
		if (IsFwdVecVisible(vecEyePos, vecEyeAng, vecEyePos_ent))
		{
			return true;
		}
	}
    
    decl Float:mins[3], Float:maxs[3];
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
stock bool:IsInFieldOfView(client, const Float:start[3], const Float:angles[3], Float:fov = 90.0)
{
    decl Float:normal[3], Float:plane[3];
    
    decl Float:end[3];
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
bool:IsPointVisible(const Float:start[3], const Float:end[3])
{
    TR_TraceRayFilter(start, end, MASK_SOLID, RayType_EndPoint, Filter_WorldOnly);

    return TR_GetFraction() == 1.0;
}

bool:IsFwdVecVisible(const Float:start[3], const Float:angles[3], const Float:end[3])
{
    decl Float:fwd[3];
    
    GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(fwd, 50.0);
    AddVectors(end, fwd, fwd);

    return IsPointVisible(start, fwd);
}

bool:IsRectangleVisible(const Float:start[3], const Float:end[3], const Float:mins[3], const Float:maxs[3], Float:scale=1.0)
{
    new Float:ZpozOffset = maxs[2];
    new Float:ZnegOffset = mins[2];
    new Float:WideOffset = ((maxs[0] - mins[0]) + (maxs[1] - mins[1])) / 4.0;

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
    decl Float:angles[3], Float:fwd[3], Float:right[3];

    SubtractVectors(start, end, fwd);
    NormalizeVector(fwd, fwd);

    GetVectorAngles(fwd, angles);
    GetAngleVectors(angles, fwd, right, NULL_VECTOR);

    decl Float:vRectangle[4][3], Float:vTemp[3];

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
    for (new i = 0; i < 4; i++)
    {
        if (IsPointVisible(start, vRectangle[i]))
        {
            return true;
        }
    }

    return false;
}
stock bool:IsMvM(bool:forceRecalc = false)
{
	static bool:found = false;
	static bool:ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{
		new i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}
stock AddPlayerHealth(client, iAdd, Float:flOverheal = 1.5, bool:bEvent = false, healer = -1)
{
    new iHealth = GetClientHealth(client);
    new iNewHealth = iHealth + iAdd;
    new iMax = RoundFloat(float(TF2_GetMaxHealth(client)) * flOverheal)
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
    new iUserId = GetClientUserId(iPatient);
    new Handle:hEvent = CreateEvent("player_healed", true);
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
    new maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
    return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(client, Prop_Data, "m_iMaxHealth") : maxhealth);
}
//==== [ OTHERS ] ==================================================
stock AnglesToVelocity( Float:fAngle[3], Float:fVelocity[3], Float:fSpeed = 1.0 )
{
    fVelocity[0] = Cosine( DegToRad( fAngle[1] ) ); 
    fVelocity[1] = Sine( DegToRad( fAngle[1] ) ); 
    fVelocity[2] = Sine( DegToRad( fAngle[0] ) ) * -1.0; 
    
    NormalizeVector( fVelocity, fVelocity ); 
    
    ScaleVector( fVelocity, fSpeed ); 
}
stock bool:IsSlotWeapon(client, iSlot, iWeapon)
{
    return iWeapon == GetPlayerWeaponSlot(client, iSlot);
}
stock float GetAngleBetweenVector(const float vec1[3], const float vec2[3])
{
    return RadToDeg(ArcCosine(GetVectorDotProduct(vec1, vec2) / (GetVectorLength(vec1) * GetVectorLength(vec2))));
} 
stock bool:IsTargetInSightRange(client, target, Float:angle=90.0, Float:distance=0.0, bool:heightcheck=false, bool:negativeangle=false)
{
	if(angle > 360.0 || angle < 0.0)
		ThrowError("Angle Max : 360 & Min : 0. %d isn't proper angle.", angle);
	if(!IsClientConnected(client) && IsPlayerAlive(client))
		ThrowError("Client is not Alive.");
	if(!IsClientConnected(target) && IsPlayerAlive(target))
		ThrowError("Target is not Alive.");
		
	decl Float:clientpos[3], Float:targetpos[3], Float:anglevector[3], Float:targetvector[3], Float:resultangle, Float:resultdistance;
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
		resultdistance = GetVectorDistance(clientpos, targetpos);
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
				resultdistance = GetVectorDistance(clientpos, targetpos);
			if(distance >= resultdistance)
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
		if(IsValidEntity(weapon))
		{
			new Float:dps;
			decl String:Classname[64];
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
				
				new Address:corrosiveElement = TF2Attrib_GetByName(weapon, "building cost reduction");
				if(corrosiveElement != Address_Null)
				{
					dps += 14.5*TF2Attrib_GetValue(corrosiveElement);
				}
				new Address:jarFragsToggle = TF2Attrib_GetByName(weapon, "overheal decay penalty");
				if(jarFragsToggle != Address_Null)
				{
					dps += 10.0*TF2Attrib_GetValue(jarFragsToggle);
					
					new Address:fragmentExplosion = TF2Attrib_GetByName(weapon, "overheal decay bonus");
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
		if(IsValidEntity(weapon))
		{
			if(HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
			{
				new Float:aps;
				decl String:Classname[64];
				TF2Econ_GetItemClassName(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), Classname, sizeof(Classname));
				if(StrEqual(Classname,"tf_weapon_scattergun",false) || StrEqual(Classname,"tf_weapon_soda_popper",false) || StrEqual(Classname,"tf_weapon_pep_brawler_blaster",false) || StrEqual(Classname,"tf_weapon_shotgun",false) || 
				StrEqual(Classname,"tf_weapon_shotgun_primary",false) || StrEqual(Classname,"tf_weapon_sentry_revenge",false) || StrEqual(Classname,"tf_weapon_shotgun_building_rescue",false))
				{
					aps = 1.6;
				}
				else if(StrEqual(Classname,"tf_weapon_handgun_scout_primary",false))
				{
					aps = 2.857;
				}
				else if(StrEqual(Classname,"tf_weapon_pistol",false) || StrEqual(Classname,"tf_weapon_handgun_scout_secondary",false))
				{
					aps = 6.67;
				}
				else if(StrEqual(Classname,"tf_weapon_cleaver",false))
				{
					aps = 1.25;
				}
				else if(StrEqual(Classname,"tf_weapon_rocketlauncher",false) || StrEqual(Classname,"tf_weapon_rocketlauncher_directhit",false) || StrEqual(Classname,"tf_weapon_particle_cannon",false) || StrEqual(Classname,"tf_weapon_rocketlauncher_airstrike",false))
				{
					aps = 1.25;
				}
				else if(StrEqual(Classname,"tf_weapon_raygun",false) || StrEqual(Classname,"tf_weapon_drg_pomson",false))
				{
					aps = 1.25;
				}
				else if(StrEqual(Classname,"tf_weapon_shovel",false) || StrEqual(Classname,"saxxy",false) || StrEqual(Classname,"tf_weapon_fireaxe",false) || StrEqual(Classname,"tf_weapon_slap",false) || StrEqual(Classname,"tf_weapon_sword",false) ||
				StrEqual(Classname,"tf_weapon_bottle",false) || StrEqual(Classname,"tf_weapon_stickbomb",false) || StrEqual(Classname,"tf_weapon_katana",false) || StrEqual(Classname,"tf_weapon_fists",false) || StrEqual(Classname,"tf_weapon_wrench",false) ||
				StrEqual(Classname,"tf_weapon_robot_arm",false) || StrEqual(Classname,"tf_weapon_bonesaw",false) || StrEqual(Classname,"tf_weapon_club",false) || StrEqual(Classname,"tf_weapon_breakable_sign",false))
				{
					aps = 1.25;
				}
				else if(StrEqual(Classname,"tf_weapon_bat",false) || StrEqual(Classname,"tf_weapon_bat_wood",false) || StrEqual(Classname,"tf_weapon_bat_fish",false) || StrEqual(Classname,"tf_weapon_bat_giftwrap",false))
				{
					aps = 2.0;
				}
				else if(StrEqual(Classname,"tf_weapon_flamethrower",false))
				{
					aps = 25.0;
				}
				else if(StrEqual(Classname,"tf_weapon_rocketlauncher_fireball",false))
				{
					aps = 1.25;
				}
				else if(StrEqual(Classname,"tf_weapon_jar_gas",false) || StrEqual(Classname,"tf_weapon_jar",false) || StrEqual(Classname,"tf_weapon_jar_milk",false))
				{
					aps = 1.25;
				}
				else if(StrEqual(Classname,"tf_weapon_flaregun",false) || StrEqual(Classname,"tf_weapon_flaregun_revenge",false))
				{
					aps = 0.5;
				}
				else if(StrEqual(Classname,"tf_weapon_grenadelauncher",false) || StrEqual(Classname,"tf_weapon_cannon",false))
				{
					aps = 1.67;
				}
				else if(StrEqual(Classname,"tf_weapon_pipebomblauncher",false))
				{
					aps = 1.67;
				}
				else if(StrEqual(Classname,"tf_weapon_minigun",false))
				{
					aps = 10.0;
				}
				else if(StrEqual(Classname,"tf_weapon_syringegun_medic",false) || StrEqual(Classname,"tf_weapon_syringegun",false))
				{
					aps = 10.0;
				}
				else if(StrEqual(Classname,"tf_weapon_compound_bow",false))
				{
					aps = 1.25;
				}
				else if(StrEqual(Classname,"tf_weapon_crossbow",false))
				{
					aps = 4.35;
				}
				else if(StrEqual(Classname,"tf_weapon_sniperrifle",false) || StrEqual(Classname,"tf_weapon_sniperrifle_decap",false) || StrEqual(Classname,"tf_weapon_sniperrifle_classic",false))
				{
					aps = 0.67;
				}
				else if(StrEqual(Classname,"tf_weapon_smg",false) || StrEqual(Classname,"tf_weapon_charged_smg",false))
				{
					aps = 10.0;
				}
				else if(StrEqual(Classname,"tf_weapon_revolver",false))
				{
					aps = 2.0;
				}
				else if(StrEqual(Classname,"tf_weapon_mechanical_arm",false))
				{
					aps = 6.7;
				}
				else
				{
					aps = 1.0;
				}
				new Address:apsMult1 = TF2Attrib_GetByName(weapon, "fire rate bonus HIDDEN");
				new Address:apsMult2 = TF2Attrib_GetByName(weapon, "fire rate penalty HIDDEN");
				new Address:apsMult3 = TF2Attrib_GetByName(weapon, "fire rate bonus");
				new Address:apsMult4 = TF2Attrib_GetByName(weapon, "fire rate penalty");
				new Address:apsMult5 = TF2Attrib_GetByName(weapon, "halloween fire rate bonus");
				new Address:apsMult6 = TF2Attrib_GetByName(weapon, "mult_item_meter_charge_rate");
				new Address:apsMod = TF2Attrib_GetByName(weapon, "energy weapon penetration");
				//If their weapon doesn't have a clip, reload rate also affects fire rate.
				if(HasEntProp(weapon, Prop_Data, "m_iClip1") && GetEntProp(weapon,Prop_Data,"m_iClip1")  == -1)
				{
					new Address:ModClip = TF2Attrib_GetByName(weapon, "mod max primary clip override");
					if(ModClip == Address_Null)
					{
						new Address:apsMult12 = TF2Attrib_GetByName(weapon, "faster reload rate");
						new Address:apsMult13 = TF2Attrib_GetByName(weapon, "Reload time increased");
						new Address:apsMult14 = TF2Attrib_GetByName(weapon, "Reload time decreased");
						new Address:apsMult15 = TF2Attrib_GetByName(weapon, "reload time increased hidden");
						
						if(apsMult12 != Address_Null) {
						aps /= TF2Attrib_GetValue(apsMult12) / efficiency;
						}
						if(apsMult13 != Address_Null) {
						aps /= TF2Attrib_GetValue(apsMult13) / efficiency;
						}
						if(apsMult14 != Address_Null) {
						aps /= TF2Attrib_GetValue(apsMult14) / efficiency;
						}
						if(apsMult15 != Address_Null) {
						aps /= TF2Attrib_GetValue(apsMult15) / efficiency;
						}
					}
				}
				//Normal Firerate Attributes
				if(apsMult1 != Address_Null) {
				aps /= TF2Attrib_GetValue(apsMult1) / efficiency;
				}
				if(apsMult2 != Address_Null) {
				aps /= TF2Attrib_GetValue(apsMult2) / efficiency;
				}
				if(apsMult3 != Address_Null) {
				aps /= TF2Attrib_GetValue(apsMult3) / efficiency;
				}
				if(apsMult4 != Address_Null) {
				aps /= TF2Attrib_GetValue(apsMult4) / efficiency;
				}
				if(apsMult5 != Address_Null) {
				aps /= TF2Attrib_GetValue(apsMult5) / efficiency;
				}
				if(apsMult6 != Address_Null) {
				aps /= TF2Attrib_GetValue(apsMult6) / efficiency;
				}
				if(apsMod != Address_Null) {
				aps *= 33.0;
				}
				//if(apsMult7 != Address_Null) {
				//aps *= TF2Attrib_GetValue(apsMult7) * efficiency;
				//}
				//Body Firerate Attributes
				new Address:BodyapsMult6 = TF2Attrib_GetByName(client, "fire rate bonus HIDDEN");
				new Address:BodyapsMult7 = TF2Attrib_GetByName(client, "fire rate penalty HIDDEN");
				new Address:BodyapsMult8 = TF2Attrib_GetByName(client, "fire rate bonus");
				new Address:BodyapsMult9 = TF2Attrib_GetByName(client, "fire rate penalty");

				if(BodyapsMult6 != Address_Null) {
				aps /= TF2Attrib_GetValue(BodyapsMult6) / efficiency
				}
				if(BodyapsMult7 != Address_Null) {
				aps /= TF2Attrib_GetValue(BodyapsMult7) / efficiency
				}
				if(BodyapsMult8 != Address_Null) {
				aps /= TF2Attrib_GetValue(BodyapsMult8) / efficiency
				}
				if(BodyapsMult9 != Address_Null) {
				aps /= TF2Attrib_GetValue(BodyapsMult9) / efficiency
				}
				if(TF2_IsPlayerInCondition(client, TFCond_RuneHaste))
				{
					aps *= 2.0 * efficiency;
				}
				if(TF2_IsPlayerInCondition(client, TFCond_HalloweenSpeedBoost))
				{
					aps *= 1.5 * efficiency;
				}
				new Address:apsAdd = TF2Attrib_GetByName(weapon, "auto fires full clip all at once");
				if(apsAdd != Address_Null)
				{
					aps = 22.0
				}
				
				return aps;
			}
		}
	}
	return 1.0;
}
stock float TF2_GetDPSModifiers(client,weapon, bool CountReloadModifiers = true, bool critMod = true)
{
	if(IsValidClient3(client))
    {
		if(IsValidEntity(weapon))
		{
			new Float:dpsMult = TF2_GetDamageModifiers(client,weapon);
			new Address:DPSMult1 = TF2Attrib_GetByName(weapon, "fire rate bonus HIDDEN");
			new Address:DPSMult2 = TF2Attrib_GetByName(weapon, "fire rate penalty HIDDEN");
			new Address:DPSMult3 = TF2Attrib_GetByName(weapon, "fire rate bonus");
			new Address:DPSMult4 = TF2Attrib_GetByName(weapon, "fire rate penalty");
			new Address:DPSMult5 = TF2Attrib_GetByName(weapon, "halloween fire rate bonus");
			new Address:DPSMult6 = TF2Attrib_GetByName(weapon, "mult_item_meter_charge_rate");
			//If their weapon doesn't have a clip, reload rate also affects fire rate.
			if(CountReloadModifiers)
			{
				if(HasEntProp(weapon, Prop_Data, "m_iClip1") && GetEntProp(weapon,Prop_Data,"m_iClip1")  == -1)
				{
					new Address:ModClip = TF2Attrib_GetByName(weapon, "mod max primary clip override");
					if(ModClip == Address_Null)
					{
						new Address:DPSMult12 = TF2Attrib_GetByName(weapon, "faster reload rate");
						new Address:DPSMult13 = TF2Attrib_GetByName(weapon, "Reload time increased");
						new Address:DPSMult14 = TF2Attrib_GetByName(weapon, "Reload time decreased");
						new Address:DPSMult15 = TF2Attrib_GetByName(weapon, "reload time increased hidden");
						
						if(DPSMult12 != Address_Null) {
						dpsMult /= TF2Attrib_GetValue(DPSMult12);
						}
						if(DPSMult13 != Address_Null) {
						dpsMult /= TF2Attrib_GetValue(DPSMult13);
						}
						if(DPSMult14 != Address_Null) {
						dpsMult /= TF2Attrib_GetValue(DPSMult14);
						}
						if(DPSMult15 != Address_Null) {
						dpsMult /= TF2Attrib_GetValue(DPSMult15);
						}
						if(TF2_IsPlayerInCondition( client, TFCond_RuneHaste ))//Really valve?
						{
							dpsMult *= 2.0;
						}
					}
				}
			}
			//Normal Firerate Attributes
			if(DPSMult1 != Address_Null) {
			dpsMult /= TF2Attrib_GetValue(DPSMult1);
			}
			if(DPSMult2 != Address_Null) {
			dpsMult /= TF2Attrib_GetValue(DPSMult2);
			}
			if(DPSMult3 != Address_Null) {
			dpsMult /= TF2Attrib_GetValue(DPSMult3);
			}
			if(DPSMult4 != Address_Null) {
			dpsMult /= TF2Attrib_GetValue(DPSMult4);
			}
			if(DPSMult5 != Address_Null) {
			dpsMult /= TF2Attrib_GetValue(DPSMult5);
			}
			if(DPSMult6 != Address_Null) {
			dpsMult /= TF2Attrib_GetValue(DPSMult6);
			}
			//Body Firerate Attributes
			new Address:BodyDPSMult6 = TF2Attrib_GetByName(client, "fire rate bonus HIDDEN");
			new Address:BodyDPSMult7 = TF2Attrib_GetByName(client, "fire rate penalty HIDDEN");
			new Address:BodyDPSMult8 = TF2Attrib_GetByName(client, "fire rate bonus");
			new Address:BodyDPSMult9 = TF2Attrib_GetByName(client, "fire rate penalty");

			if(BodyDPSMult6 != Address_Null) {
			dpsMult /= TF2Attrib_GetValue(BodyDPSMult6)
			}
			if(BodyDPSMult7 != Address_Null) {
			dpsMult /= TF2Attrib_GetValue(BodyDPSMult7)
			}
			if(BodyDPSMult8 != Address_Null) {
			dpsMult /= TF2Attrib_GetValue(BodyDPSMult8)
			}
			if(BodyDPSMult9 != Address_Null) {
			dpsMult /= TF2Attrib_GetValue(BodyDPSMult9)
			}
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
stock float TF2_GetDamageModifiers(client,weapon,status=true)
{
	if(IsValidClient3(client))
    {
		if(IsValidEntity(weapon))
		{
			//Normal Attributes
			new Float:dpsMult = 1.0;
			new Address:DPSMult1 = TF2Attrib_GetByName(weapon, "mod rage damage boost");
			new Address:DPSMult2 = TF2Attrib_GetByName(weapon, "damage bonus");
			new Address:DPSMult3 = TF2Attrib_GetByName(weapon, "damage penalty");
			new Address:DPSMult4 = TF2Attrib_GetByName(weapon, "accuracy scales damage");
			new Address:DPSMult5 = TF2Attrib_GetByName(weapon, "damage bonus HIDDEN");
			new Address:DPSMult6 = TF2Attrib_GetByName(weapon, "dmg penalty vs players");
			new Address:DPSMult7 = TF2Attrib_GetByName(weapon, "throwable healing");
			new Address:DPSMult8 = TF2Attrib_GetByName(weapon, "bullets per shot bonus");
			new Address:DPSMult9 = TF2Attrib_GetByName(weapon, "taunt is highfive");
			new Address:DPSMult10 = TF2Attrib_GetByName(weapon, "throwable damage");
			new Address:projtype = TF2Attrib_GetByName(weapon, "override projectile type");
			
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
			if(DPSMult8 != Address_Null){
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

			//Body Stats
			new Address:BodyDPSMult1 = TF2Attrib_GetByName(client, "mod rage damage boost");
			new Address:BodyDPSMult2 = TF2Attrib_GetByName(client, "damage bonus");
			new Address:BodyDPSMult3 = TF2Attrib_GetByName(client, "damage penalty");
			new Address:BodyDPSMult4 = TF2Attrib_GetByName(client, "accuracy scales damage");
			new Address:BodyDPSMult5 = TF2Attrib_GetByName(client, "damage bonus HIDDEN");
			new Address:BodyDPSMult6 = TF2Attrib_GetByName(client, "bullets per shot bonus");

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
			if(BodyDPSMult6 != Address_Null){
				dpsMult *= TF2Attrib_GetValue(BodyDPSMult6);
			}
			//Custom Attributes
			new Address:averagedDamage = TF2Attrib_GetByName(weapon, "unique craft index");
			if(averagedDamage != Address_Null)
			{	
				dpsMult = (dpsMult/(1-TF2Attrib_GetValue(averagedDamage)/100.0));
			}
			new Address:CleaverdamageActive = TF2Attrib_GetByName(weapon, "disguise damage reduction");
			if(CleaverdamageActive != Address_Null){
				dpsMult *= TF2Attrib_GetValue(CleaverdamageActive)
			}
			new Address:expodamageActive = TF2Attrib_GetByName(weapon, "taunt turn speed");
			if(expodamageActive != Address_Null){
				dpsMult *= Pow(TF2Attrib_GetValue(expodamageActive), 6.0);
			}
			new Address:damageActive = TF2Attrib_GetByName(weapon, "ubercharge");
			if(damageActive != Address_Null)
			{
				dpsMult *= Pow(1.05,TF2Attrib_GetValue(damageActive));
			}
			new Address:supernovaPowerup = TF2Attrib_GetByName(client, "spawn with physics toy");
			if(supernovaPowerup != Address_Null)
			{
				new Float:supernovaPowerupValue = TF2Attrib_GetValue(supernovaPowerup);
				if(supernovaPowerupValue > 1.0){
					dpsMult *= Pow(supernovaPowerupValue,3.0)
				}
			}
			//Buffs
			if(status)
			{
				new Float:medicDMGBonus = 1.0;
				new healers = GetEntProp(client, Prop_Send, "m_nNumHealers");
				if(healers > 0)
				{
					for (new i = 1; i < MaxClients; i++)
					{
						if (IsValidClient(i))
						{
							new healerweapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
							if(IsValidEntity(healerweapon))
							{
								new String:classname[128]; 
								GetEdictClassname(healerweapon, classname, sizeof(classname)); 
								if(StrContains(classname, "medigun") != -1)
								{
									if(GetEntPropEnt(healerweapon, Prop_Send, "m_hHealingTarget") == client)
									{
										if(IsValidEntity(healerweapon))
										{
											new Address:dmgActive = TF2Attrib_GetByName(healerweapon, "hidden secondary max ammo penalty");
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
stock bool:LookPoint(client, Float:dest[3])
{
    decl Float:ang[3];
    decl Float:pos[3];
    
    GetClientEyePosition(client, pos);
    GetClientEyeAngles(client, ang);
    
    new Handle:trace = TR_TraceRayFilterEx(pos, ang, MASK_SHOT, RayType_Infinite, FilterPlayer, client);

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

public bool:FilterPlayer(entity, contentsMask, any:data)
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
stock bool:PlayerRazorbackIsActive(client)
{
    return GetEntPropFloat(client, Prop_Send, "m_flItemChargeMeter", TFWeaponSlot_Secondary) >= 100.0; 
} 

stock GetIndexOfWeaponSlot(client, slot)
{
	new weapon=GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}
stock int TF2_GetPlayerMaxHealth(int client) {
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}
stock AttachTrail(ent, client)
{
	decl Float:m_fOrigin[3], Float:m_fAngle[3];
	new Float:m_fTemp[3] = {0.0, 90.0, 0.0};
	GetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fAngle);
	SetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fTemp);
	decl Float:m_fPosition[3];
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
stock CreateSpriteTrail(int iEntity, String:lifetime[], String:startwidth[], String:endwidth[], String:spritename[], String:rendercolor[])
{
	new spriteTrail = CreateEntityByName("env_spritetrail");
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
stock CreateSprite(iClient, String:sprite[], Float:offset)
{
	new String:szTemp[64]; 
	Format(szTemp, sizeof(szTemp), "client%i", iClient);
	DispatchKeyValue(iClient, "targetname", szTemp);

	new Float:vOrigin[3];
	GetClientAbsOrigin(iClient, vOrigin);
	vOrigin[2] += offset;
	new ent = CreateEntityByName("env_sprite_oriented");
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
//Math
stock float FloatMod(float num, float denom)
{
    return num - denom * RoundToFloor(num / denom);
}

stock float operator%(float oper1, float oper2)
{
    return FloatMod(oper1, oper2);
}
stock char[] GetAlphabetForm(float number)
{
	new String:output[64];
	if(number <= 0.0)//Prevent logmarithm from undefining.
	{
		IntToString(RoundToNearest(number), output, sizeof(output));
		return output;
	}
	new digits = RoundToFloor(Logarithm(number))+1;
	
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
	}
	return output;
}
//Attributes
stock bool:TF2_AttribListAttributesBySlot(client, iSlot = -1) 
{ 
    new iAttribList[128]; 
    new Float:flAttribValues[128]; 
    new Address:aAttr; 
    decl iEntity; 

    switch (iSlot) 
    { 
        case -1: 
        { 
            iEntity = client;
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

    new iCount = TF2Attrib_ListDefIndices(iEntity, iAttribList); 
    if (iCount > 0) 
    { 
        for (new i = 0; i < iCount; i++) 
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
	//new weapon = GetWeapon(client,iSlot);
	//PrintToChatAll("%i weapon",weapon);
    return true; 
}
//Ammo
stock SetCarriedAmmo( client, slot, newAmmo )
{
    if ( IsValidClient3( client ) )
    {
        new weapon = GetPlayerWeaponSlot( client, slot ); 
        if ( IsValidEntity( weapon ) )
        {
            new type = GetEntProp( weapon, Prop_Send, "m_iPrimaryAmmoType" ); 
            if ( type > 0 || type < 31 ) SetEntProp( client, Prop_Send, "m_iAmmo", newAmmo, _, type ); 
        }
    }
}
stock GetCarriedAmmo( client, slot )
{
    if ( IsValidClient3( client ) )
    {
        new weapon = GetPlayerWeaponSlot( client, slot ); 
        if ( IsValidEntity( weapon ) )
        {
            new type = GetEntProp( weapon, Prop_Send, "m_iPrimaryAmmoType" ); 
            if ( type > 0 || type < 31 )
                return GetEntProp( client, Prop_Send, "m_iAmmo", _, type ); 
        }
    }
    return 0; 
}
stock SetClipAmmo( client, slot, ammo )
{
    if ( IsValidClient3( client ) )
    {
        new weapon = GetPlayerWeaponSlot( client, slot ); 
        if ( IsValidEntity( weapon ) )
            SetEntProp( weapon, Prop_Send, "m_iClip1", ammo ); 
    }
}
stock GetClipAmmo( client, slot )
{
    if ( IsValidClient3( client ) )
    {
        new weapon = GetPlayerWeaponSlot( client, slot ); 
        if ( IsValidEntity( weapon ) )
            return GetEntProp( weapon, Prop_Data, "m_iClip1" ); 
    }
    return 0; 
}
stock SetLoadedAmmo( client, slot, ammo = -1, ammo2 = -1 )
{
    if ( IsValidClient3( client ) )
    {
        new weapon = GetPlayerWeaponSlot( client, slot ); 
        if( IsValidEntity( weapon ) )
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
        new weapon = GetPlayerWeaponSlot( client, slot ); 
        if ( IsValidEntity( weapon ) )
        {
            new iOffset = GetEntProp( weapon, Prop_Send, "m_iPrimaryAmmoType", 1 )*4; 
            new iAmmoTable = FindSendPropInfo( "CTFPlayer", "m_iAmmo" ); 
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
stock GetClientBaseHP(client){
	new HP;
	if(TF2_GetPlayerClass(client) == TFClass_Scout || TF2_GetPlayerClass(client) == TFClass_Engineer || TF2_GetPlayerClass(client) == TFClass_Spy || TF2_GetPlayerClass(client) == TFClass_Sniper){
		HP = 125;
	}
	if(TF2_GetPlayerClass(client) == TFClass_Medic){
		HP = 150;
	}
	if(TF2_GetPlayerClass(client) == TFClass_Pyro || TF2_GetPlayerClass(client) == TFClass_DemoMan){
		HP = 175;
	}
	if(TF2_GetPlayerClass(client) == TFClass_Soldier){
		HP = 200;
	}
	if(TF2_GetPlayerClass(client) == TFClass_Heavy){
		HP = 300;
	}
	
	new Address:vampirePowerup = TF2Attrib_GetByName(client, "unlimited quantity");//Vampire Powerup
	if(vampirePowerup != Address_Null)
	{
		new Float:vampirePowerupValue = TF2Attrib_GetValue(vampirePowerup);
		if(vampirePowerupValue > 1.0)
		{
			HP += 80;
		}
	}
	new Address:knockoutPowerup = TF2Attrib_GetByName(client, "taunt is press and hold");//Vampire Powerup
	if(knockoutPowerup != Address_Null)
	{
		new Float:knockoutPowerupValue = TF2Attrib_GetValue(knockoutPowerup);
		if(knockoutPowerupValue > 1.0)
		{
			HP += 100;
		}
	}
	new Address:kingPowerup = TF2Attrib_GetByName(client, "attack projectiles");
	if(kingPowerup != Address_Null && TF2Attrib_GetValue(kingPowerup) > 1.0)
	{
		new Float:kingPowerupValue = TF2Attrib_GetValue(kingPowerup);
		if(kingPowerupValue > 1.0)
		{
			HP += 100;
		}
	}
	
	new weap = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Primary)
	if(IsValidEntity(weap))
	{
		new Address:HPActive1 = TF2Attrib_GetByName(weap, "max health additive bonus");
		new Address:HPActive2 = TF2Attrib_GetByName(weap, "max health additive penalty");
		
		if(HPActive1 != Address_Null){
			HP += RoundToCeil(TF2Attrib_GetValue(HPActive1));
		}
		if(HPActive2 != Address_Null){
			HP += RoundToCeil(TF2Attrib_GetValue(HPActive2));
		}		
	}
	weap = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Secondary)
	if(IsValidEntity(weap))
	{
		new Address:HPActive1 = TF2Attrib_GetByName(weap, "max health additive bonus");
		new Address:HPActive2 = TF2Attrib_GetByName(weap, "max health additive penalty");
		
		if(HPActive1 != Address_Null){
			HP += RoundToCeil(TF2Attrib_GetValue(HPActive1));
		}
		if(HPActive2 != Address_Null){
			HP += RoundToCeil(TF2Attrib_GetValue(HPActive2));
		}		
	}
	weap = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Melee)
	if(IsValidEntity(weap))
	{
		new Address:HPActive1 = TF2Attrib_GetByName(weap, "max health additive bonus");
		new Address:HPActive2 = TF2Attrib_GetByName(weap, "max health additive penalty");
		
		if(HPActive1 != Address_Null){
			HP += RoundToCeil(TF2Attrib_GetValue(HPActive1));
		}
		if(HPActive2 != Address_Null){
			HP += RoundToCeil(TF2Attrib_GetValue(HPActive2));
		}		
	}
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
public Action SetTransmit(int entity, int client) 
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
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack, EntIndexToEntRef(victim));
			WritePackCell(hPack, EntIndexToEntRef(attacker));
			WritePackFloat(hPack, damage);
			if(IsValidEntity(weapon))
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
public Action:DOTDamage(Handle:timer,any:data)
{
	ResetPack(data);
	new victim = EntRefToEntIndex(ReadPackCell(data));
	new attacker = EntRefToEntIndex(ReadPackCell(data));
	new Float:damage = ReadPackFloat(data);
	new weapon = EntRefToEntIndex(ReadPackCell(data));
	new damagetype = ReadPackCell(data);
	new repeats = ReadPackCell(data);
	new bool:stackable = view_as<bool>(ReadPackCell(data));
	new Float:tickspeed = ReadPackFloat(data);
	if(repeats >= 1)
	{
		if(IsValidForDamage(victim) && IsValidClient3(attacker))
		{
			SDKHooks_TakeDamage(victim,attacker,attacker,damage, damagetype,weapon,NULL_VECTOR,NULL_VECTOR,!IsValidClient3(victim));
			repeats--;
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack, EntIndexToEntRef(victim));
			WritePackCell(hPack, EntIndexToEntRef(attacker));
			WritePackFloat(hPack, damage);
			if(IsValidEntity(weapon))
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
}
public Action:ReEnableBuilding(Handle:timer, int entity)
{
	entity = EntRefToEntIndex(entity);
	if(IsValidEntity(entity))
	{
		SetEntProp(entity, Prop_Send, "m_bDisabled", 0);
	}
}
//Thanks to Patka.
stock CreateParticle(iEntity, String:strParticle[], bool:bAttach = false, String:strAttachmentPoint[]="", Float:time = 2.0,Float:fOffset[3]={0.0, 0.0, 0.0}, bool:parentAngle = false, attachType = 0)
{
	if(attachType == 0)
	{
		new iParticle = CreateEntityByName("info_particle_system");
		if (IsValidEdict(iParticle))
		{
			decl Float:fPosition[3], Float:fAngles[3];
			
			if(IsValidEntity(iEntity))
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
				
				if (StrEqual(strAttachmentPoint, "") == false)
				{
					SetVariantString(strAttachmentPoint);
					AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iEntity, iParticle, 0);                
				}
			}
			// Spawn and start
			DispatchSpawn(iParticle);
			ActivateEntity(iParticle);
			AcceptEntityInput(iParticle, "Start");
			
			if(IsValidEdict(iParticle) && time > 0.0)
			{
				new Handle:pack;
				CreateDataTimer(time, Timer_KillParticle, pack);
				WritePackCell(pack, EntIndexToEntRef(iParticle));
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
		
		new Handle:pack;
		CreateDataTimer(time, Timer_KillTEParticle, pack);
		WritePackCell(pack, EntIndexToEntRef(iEntity));
	}
	return true
}
public Action:Timer_MoveParticle(Handle:timer, Handle:pack)
{
	ResetPack(pack);	
	new entity = EntRefToEntIndex(ReadPackCell(pack));
	
	if (IsValidEdict(entity))
	{
		new Float:newVector[3] = {9999.0,9999.0,9999.0};
		TeleportEntity(entity, newVector, NULL_VECTOR, NULL_VECTOR);
	}
	
	return Plugin_Stop;
}
public Action:Timer_KillParticle(Handle:timer, Handle:pack)
{
	ResetPack(pack);	
	new entity = EntRefToEntIndex(ReadPackCell(pack));
	
	if (IsValidEdict(entity))
	{
		SetVariantString("ParticleEffectStop");
		AcceptEntityInput(entity, "DispatchEffect");
		RemoveEdict(entity);
	}
	
	return Plugin_Stop;
}
public Action:Timer_KillTEParticle(Handle:timer, Handle:pack)
{
	ResetPack(pack);	
	new entity = EntRefToEntIndex(ReadPackCell(pack));
	
	if (IsValidEdict(entity))
	{
		SetVariantString("ParticleEffectStop");
		AcceptEntityInput(entity, "DispatchEffect");
	}
	
	return Plugin_Stop;
}
stock SetAmmo_Weapon(weapon, newAmmo)
{
	new owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (owner == -1) return;
	new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
	new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	SetEntData(owner, iAmmoTable+iOffset, newAmmo, 4, true);
}
stock DelayedTeleportEntity(Handle:pack)
{
	ResetPack(pack);	
	new entity = EntRefToEntIndex(ReadPackCell(pack));
	new Float:origin[3]
	new Float:angles[3] 
	new Float:velocity[3]
	for(new i=0;i<3;i++)
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
stock bool:IsStringBlank(const String:input[])
{
	new len = strlen(input);
	for (new i=0; i<len; i++)
	{
		if (!IsCharSpace(input[i]))
		{
			return false;
		}
	}
	return true;
}