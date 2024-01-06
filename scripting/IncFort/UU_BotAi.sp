// Includes
#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2_isPlayerInSpawn>
#include <vphysics>
#include <dhooks>
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
new Float:attackInput[MAXPLAYERS+1];
new Float:forwardInput[MAXPLAYERS+1];
new Float:backInput[MAXPLAYERS+1];
new Float:leftInput[MAXPLAYERS+1];
new Float:rightInput[MAXPLAYERS+1];
new Float:cannotJump[MAXPLAYERS+1];
//ay lmao
public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "trigger_capture_area"))
	{
		SDKHook(entity, SDKHook_StartTouch, StartTouchPoint);
		SDKHook(entity, SDKHook_EndTouch, EndTouchPoint);
	}
}
public Action:StartTouchPoint(entity, client)
{
	if(IsValidClient3(client))
	{
		cannotJump[client] = 8.0;
	}
}
public Action:EndTouchPoint(entity, client)
{
	if(IsValidClient3(client))
	{
		cannotJump[client] = 2.0;
	}
}
public void TF2_OnConditionAdded(client, TFCond:cond)
{
	if(IsValidClient3(client))
	{
		switch(cond)
		{
			case TFCond_Taunting:
			{
				cannotJump[client] = 2.5;
			}
			case TFCond_Teleporting:
			{
				cannotJump[client] = 1.0;
			}
		}
	}
}
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(!IsFakeClient(client))
		return Plugin_Continue;
	if(IsMvM())
		return Plugin_Continue;

	new bool:changed = false;
	new Float:tickRate = GetTickInterval();

	if(attackInput[client] > 0.0)
	{
		buttons |= IN_ATTACK;
		attackInput[client] -= tickRate;
	}
	if(forwardInput[client] > 0.0)
	{
		buttons |= IN_FORWARD;
		forwardInput[client] -= tickRate;
	}
	if(backInput[client] > 0.0)
	{
		buttons |= IN_BACK;
		backInput[client] -= tickRate;
	}
	if(leftInput[client] > 0.0)
	{
		buttons |= IN_MOVELEFT;
		leftInput[client] -= tickRate;
	}
	if(rightInput[client] > 0.0)
	{
		buttons |= IN_MOVERIGHT;
		rightInput[client] -= tickRate;
	}
	if(cannotJump[client] > 0.0) {cannotJump[client] -= tickRate;}

	if(counter[client] & 4 == 0)
	{
		if(IsValidClient3(client) && !TF2Spawn_IsClientInSpawn(client))
		{
			new currentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			new primary = GetPlayerWeaponSlot(client,0)
			new secondary = GetPlayerWeaponSlot(client,1)
			new melee = GetPlayerWeaponSlot(client,2)
			new TFClassType:CurrentClass = TF2_GetPlayerClass(client)
			new flags = GetEntityFlags(client)
			char primaryClassname[32]; char secondaryClassname[32]; char meleeClassname[32]; char currentClassname[32];

			if(IsValidEntity(primary))
				GetEntityClassname(primary, primaryClassname, sizeof(primaryClassname));
			if(IsValidEntity(secondary))
				GetEntityClassname(secondary, secondaryClassname, sizeof(secondaryClassname));
			if(IsValidEntity(melee))
				GetEntityClassname(melee, meleeClassname, sizeof(meleeClassname));
			if(IsValidEntity(currentWeapon))
				GetEntityClassname(currentWeapon, currentClassname, sizeof(currentClassname));

			if(cannotJump[client] <= 0.0 && !TF2_IsPlayerInCondition(client, TFCond_Zoomed) && flags & FL_ONGROUND && attackInput[client] <= 0.0)
			{
				new Float:scalarMovement[3];
				scalarMovement[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
				scalarMovement[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
				scalarMovement[2] = 0.0;

				if(GetVectorLength(scalarMovement) < 10.0)
				{
					buttons |= IN_JUMP;
					changed = true;
				}
			}


			for(new i = 1; i <= MaxClients; ++i)//Aimbot 
			{
				if(!IsValidClient3(i))
					continue;
				if(!IsPlayerAlive(i))
					continue;
				if(GetClientTeam(client) == GetClientTeam(i))
					continue;
				if(IsClientObserver(i))
					continue;
				if(TF2_IsPlayerInCondition(i, TFCond_Cloaked))
					continue;
				if(TF2_IsPlayerInCondition(i, TFCond_Disguised))
					continue;
				if(!ClientCanSeeClient(client, i))
					continue;
				
				
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
										attackInput[client] = 0.8;
										break;
									}
								}
							}
						}
						case(TFClass_Heavy):{
							if(IsTargetInSightRange(client, i, 30.0, 2000.0)){
								autoAim(client,i, angles);
								attackInput[client] = 0.4;
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
								attackInput[client] = 0.1;
								break;
							}
						}
						case(TFClass_Scout):{

							if(IsTargetInSightRange(client, i, 40.0, 800.0)){
								autoAim(client,i, angles);
								attackInput[client] = 0.5;
								break;
							}
							else if(IsTargetInSightRange(client, i, 40.0, 1500.0)){
								float vVictim[3], vAttacker[3];
								GetClientAbsOrigin(i, vVictim);
								GetClientAbsOrigin(client, vAttacker);
								SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", secondary);
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
								attackInput[client] = 0.4;
								autoAim(client,i, angles,_,offset);
								break;
							}
							else if(IsTargetInSightRange(client, i, 40.0, 4000.0)){
								float vVictim[3], vAttacker[3];
								GetClientAbsOrigin(i, vVictim);
								GetClientAbsOrigin(client, vAttacker);
								SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", secondary);
								break;
							}
						}
					}
				}
				else if(currentWeapon == secondary && StrContains(secondaryClassname, "lunchbox") == -1 && StrContains(secondaryClassname, "wearable") == -1)
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
								attackInput[client] = 0.15;
								autoAim(client,i, angles,_,offset);
								break;
							}
							buttons |= IN_ATTACK2;
							changed = true;
							break;
						}
						default:{
							if(IsTargetInSightRange(client, i, 40.0, 2000.0)){
								attackInput[client] = 0.3;
								autoAim(client,i, angles);
								break;
							}
						}
					}
				}
				else if(currentWeapon == melee)
				{
					if(IsTargetInSightRange(client, i, 20.0, 800.0)){
						attackInput[client] = 0.4;
						changed = true;
						break;
					}
				}
			}
		}
	}
	counter[client]++;

	if(changed)
		return Plugin_Changed;
	return Plugin_Continue;
}


//lol
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