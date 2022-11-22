// Includes
#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <sm_chaosmvm>
#include <tf2attributes>
#include <tf2_isPlayerInSpawn>
#include <vphysics>
#include <dhooks>
#include <weapondata>

// Plugin Info
public Plugin:myinfo =
{
	name = "UberUpgrades Bot AI",
	author = "Razor",
	description = "Plugin for handling bots.",
	version = "2.0",
	url = "n/a",
}

//==== [ VARIABLES ] ===============================================
new counter[MAXPLAYERS+1];
//Stocks
//==== [ OTHERS ] ==================================================
stock AnglesToVelocity( Float:fAngle[3], Float:fVelocity[3], Float:fSpeed = 1.0 )
{
    fVelocity[0] = Cosine( DegToRad( fAngle[1] ) ); 
    fVelocity[1] = Sine( DegToRad( fAngle[1] ) ); 
    fVelocity[2] = Sine( DegToRad( fAngle[0] ) ) * -1.0; 
    
    NormalizeVector( fVelocity, fVelocity ); 
    
    ScaleVector( fVelocity, fSpeed ); 
}

stock bool:IsValidClient( client, bool:replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( IsFakeClient( client ) ) return false; 
    if ( !IsClientConnected( client ) ) return false; 
    if ( GetEntProp( client, Prop_Send, "m_bIsCoaching" ) ) return false; 
    if ( replaycheck )
    {
        if ( IsClientSourceTV( client ) || IsClientReplay( client ) ) return false; 
    }
    return true; 
}
stock bool:IsValidClient3( client, bool:replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsClientConnected( client ) ) return false; 
    if ( GetEntProp( client, Prop_Send, "m_bIsCoaching" ) ) return false; 
    if ( replaycheck )
    {
        if ( IsClientSourceTV( client ) || IsClientReplay( client ) ) return false; 
    }
    return true; 
}
stock bool:IsTargetInSightRange(client, target, Float:angle=90.0, Float:distance=0.0, bool:heightcheck=true, bool:negativeangle=false)
{
	if(angle > 360.0 || angle < 0.0)
		ThrowError("Angle Max : 360 & Min : 0. %d isn't proper angle.", angle);
	if(!IsClientConnected(client) && IsPlayerAlive(client))
		ThrowError("Client is not Alive.");
	if(!IsClientConnected(target) && IsPlayerAlive(target))
		ThrowError("Target is not Alive.");
		
	decl Float:clientpos[3], Float:targetpos[3], Float:anglevector[3], Float:targetvector[3], Float:resultangle, Float:resultdistance;
	
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	if(negativeangle)
		NegateVector(anglevector);

	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(target, targetpos);
	if(heightcheck && distance > 0)
		resultdistance = GetVectorDistance(clientpos, targetpos);
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	if(resultangle <= angle/2)	
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
stock bool:ClientCanSeeClient(client, target, Float:distance = 0.0, Float:height = 50.0)
{

        new Float:vMonsterPosition[3], Float:vTargetPosition[3];
        
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", vMonsterPosition);
        vMonsterPosition[2] += height;
        
        GetClientEyePosition(target, vTargetPosition);
        
        if (distance == 0.0 || GetVectorDistance(vMonsterPosition, vTargetPosition, false) < distance)
        {
            new Handle:trace = TR_TraceRayFilterEx(vMonsterPosition, vTargetPosition, MASK_SOLID_BRUSHONLY, RayType_EndPoint, Base_TraceFilter);

            if(TR_DidHit(trace))
            {
                CloseHandle(trace);
                return (false);
            }
            
            CloseHandle(trace);

            return (true);
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
public bool:Base_TraceFilter(entity, contentsMask, any:data)
{
    if(entity != data)
        return (false);

    return (true);
}
stock void SnapEyeAngles(int client, float target_point[3], float cmdAngles[3], float offsets[3] = NULL_VECTOR)
{
	float eye_to_target[3];
	GetVectorAngles(target_point, eye_to_target);
	
	eye_to_target[0] = AngleNormalize(eye_to_target[0]);
	eye_to_target[1] = AngleNormalize(eye_to_target[1]);
	eye_to_target[2] = 0.0;
	
	AddVectors(eye_to_target, offsets, eye_to_target)
	
	cmdAngles = eye_to_target;
	
	TeleportEntity(client, NULL_VECTOR, eye_to_target, NULL_VECTOR);
}
stock float AngleNormalize(float angle)
{
	angle = angle - 360.0 * RoundToFloor(angle / 360.0);
	while (angle > 180.0)angle -= 360.0;
	while (angle < -180.0)angle += 360.0;
	return angle;
}
stock float[] GetEyePosition(int client)
{
	float v[3];
	GetClientEyePosition(client, v);
	return v;
}
stock autoAim(client, target, float vViewAngles[3], bool headshots = false, float offsets[3] = NULL_VECTOR)
{
	float target_point[3];
	float target_point_adjusted[3];
	GetClientEyePosition(target,target_point)
	if(headshots == false)
		target_point[2] -= 15.0;
	
	SetEntProp(client, Prop_Data, "m_bLagCompensation", false);
	SetEntProp(client, Prop_Data, "m_bPredictWeapons", false);

	SubtractVectors(target_point, GetEyePosition(client), target_point_adjusted);
	
	SnapEyeAngles(client, target_point_adjusted, vViewAngles, offsets);
}
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	new bool:changed = false;
	if(!IsMvM() && IsValidClient3(client) && IsFakeClient(client)) // Alright, we have a bot.
	{
		if(counter[client] >= 4)
		{
			new currentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			new primary = GetPlayerWeaponSlot(client,0)
			new secondary = GetPlayerWeaponSlot(client,1)
			new melee = GetPlayerWeaponSlot(client,2)
			new TFClassType:CurrentClass = TF2_GetPlayerClass(client)
			for(new i = 1; i < MaxClients; i++)
			{
				if(IsValidClient3(i) && GetClientTeam(client) != GetClientTeam(i) && GetClientTeam(i) != 1 && 
				!TF2_IsPlayerInCondition(i, TFCond_Cloaked) && !TF2_IsPlayerInCondition(i, TFCond_Disguised) && ClientCanSeeClient(client, i) && IsPlayerAlive(i))
				{
					if(currentWeapon == primary)
					{
						switch(CurrentClass)
						{
							case(TFClass_Pyro):{
								if(IsValidEntity(primary))
								{
									new Address:FlameActive = TF2Attrib_GetByName(primary, "flame_speed");
									if(FlameActive != Address_Null){
										if(IsTargetInSightRange(client, i, 10.0, TF2Attrib_GetValue(FlameActive)*0.2)){
											autoAim(client,i, angles);
											buttons |= IN_ATTACK;
											changed = true;
											break;
										}
									}
								}
							}
							case(TFClass_Heavy):{
								if(IsTargetInSightRange(client, i, 30.0, 2000.0)){
									autoAim(client,i, angles);
									buttons |= IN_ATTACK;
									changed = true;
									break;
								}
							}
							case(TFClass_Sniper):{
								if(IsValidEntity(melee) && currentWeapon != melee && IsTargetInSightRange(client, i, 40.0, 300.0)){
									SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", melee);
									buttons &= ~IN_ATTACK;
									buttons &= ~IN_ATTACK2;
									changed = true;
									break;
								}
								else if(IsTargetInSightRange(client, i, 5.0, 8000.0)){
									autoAim(client,i, angles, true);
									if(TF2_IsPlayerInCondition(i, TFCond_Zoomed))
									{
										buttons |= IN_ATTACK;
										changed = true;
									}
									break;
								}
							}
							case(TFClass_Scout):{
								if(IsTargetInSightRange(client, i, 40.0, 800.0)){
									float vVictim[3], vAttacker[3];
									GetClientAbsOrigin(i, vVictim);
									GetClientAbsOrigin(client, vAttacker);
									SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", secondary);
									changed = true;
									break;
								}
								else if(IsTargetInSightRange(client, i, 40.0, 1500.0)){
									autoAim(client,i, angles);
									break;
								}
							}
							case(TFClass_DemoMan):{
								if(IsTargetInSightRange(client, i, 40.0, 1300.0)){
									new Float:offset[3]		
									float vVictim[3], vAttacker[3], distance;
									GetClientAbsOrigin(i, vVictim);
									GetClientAbsOrigin(client, vAttacker);
									distance = GetVectorDistance(vVictim, vAttacker)
									offset[0] = -1.0*((distance-1200.0)/50.0)
									if(offset[0] > 0.0)
										offset[0] *= 0.1
									buttons |= IN_ATTACK;
									autoAim(client,i, angles,_,offset);
									changed = true;
									break;
								}
								if(IsTargetInSightRange(client, i, 40.0, 4000.0)){
									float vVictim[3], vAttacker[3];
									GetClientAbsOrigin(i, vVictim);
									GetClientAbsOrigin(client, vAttacker);
									SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", secondary);
									changed = true;
								}
							}
						}
					}
					else if(currentWeapon == secondary)
					{
						switch(CurrentClass)
						{
							case(TFClass_DemoMan):{
								if(IsTargetInSightRange(client, i, 40.0, 4000.0)){
									new Float:offset[3]		
									float vVictim[3], vAttacker[3], distance;
									GetClientAbsOrigin(i, vVictim);
									GetClientAbsOrigin(client, vAttacker);
									distance = GetVectorDistance(vVictim, vAttacker)
									offset[0] = -1.0*((distance-1200.0)/65.0)
									if(offset[0] > 0.0)
										offset[0] *= 0.1
									buttons |= IN_ATTACK;
									autoAim(client,i, angles,_,offset);
									break;
								}
								buttons |= IN_ATTACK2;
								changed = true;
								break;
							}
							default:{
								if(IsTargetInSightRange(client, i, 40.0, 2000.0)){
									buttons |= IN_ATTACK;
									autoAim(client,i, angles);
									changed = true;
									break;
								}
							}
						}
					}
					else if(currentWeapon == melee)
					{
						if(IsTargetInSightRange(client, i, 20.0, 800.0)){
							buttons |= IN_ATTACK;
							changed = true;
							break;
						}
					}
				}
			}
		}
		else
		{
			counter[client]++;
		}
	}
	if(changed)
		return Plugin_Changed;
	return Plugin_Continue;
}