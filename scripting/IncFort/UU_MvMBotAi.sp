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
	name = "UberUpgrades MvM Bot AI",
	author = "Razor",
	description = "Plugin for handling MvM bots.",
	version = "2.0",
	url = "n/a",
}

new BotTimer[MAXPLAYERS];
new AttackTicks[MAXPLAYERS];
new SecondaryTicks[MAXPLAYERS];
new JumpTicks[MAXPLAYERS];
new CrouchTicks[MAXPLAYERS];
new LeftTicks[MAXPLAYERS];
new RightTicks[MAXPLAYERS];
new Float:PreviousAngles[MAXPLAYERS][3];

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath)
}
public OnClientDisconnect(client)
{
	AttackTicks[client] = 0
	SecondaryTicks[client] = 0
	JumpTicks[client] = 0
	CrouchTicks[client] = 0
	PreviousAngles[client] = NULL_VECTOR
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	AttackTicks[client] = 0
	SecondaryTicks[client] = 0
	JumpTicks[client] = 0
	CrouchTicks[client] = 0
	PreviousAngles[client] = NULL_VECTOR
}
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	new bool:changed = false;
	if(IsMvM() && IsValidClient3(client) && IsFakeClient(client)) // Alright, we have a bot.
	{
		if(BotTimer[client] < 0)
		{
			new currentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			new primary = GetPlayerWeaponSlot(client,0)
			new secondary = GetPlayerWeaponSlot(client,1)
			new melee = GetPlayerWeaponSlot(client,2)
			new TFClassType:CurrentClass = TF2_GetPlayerClass(client)

			BotTimer[client] = 3;
		}
		else
		{
			BotTimer[client] -= 1;
		}
		if(AttackTicks[client] > 0){
		AttackTicks[client]--;buttons |= IN_ATTACK;changed=true}
		if(SecondaryTicks[client] > 0){
		SecondaryTicks[client]--;buttons |= IN_ATTACK2;changed=true}
		if(CrouchTicks[client] > 0){
		CrouchTicks[client]--;buttons |= IN_DUCK;changed=true}
		if(JumpTicks[client] > 0){
		JumpTicks[client]--;buttons |= IN_JUMP;changed=true}
		if(LeftTicks[client] > 0){
		LeftTicks[client]--;buttons |= IN_MOVELEFT;changed=true}
		if(RightTicks[client] > 0){
		RightTicks[client]--;buttons |= IN_MOVERIGHT;changed=true}
	}
	if(changed)
		return Plugin_Changed;
	return Plugin_Continue;
}

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