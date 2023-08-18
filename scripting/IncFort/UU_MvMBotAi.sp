// Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2utils>
#include <tf2attributes>
#include <razorstocks>

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
	if(IsMvM() && IsValidClient3(client) && IsFakeClient(client))
	{
		if(BotTimer[client] < 0)
		{
			int currentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			int melee = GetPlayerWeaponSlot(client,2)
			if(currentWeapon == melee && IsValidWeapon(melee)){
				float totalRange = TF2Attrib_HookValueFloat(90.0, "melee range multiplier", melee);
				for(int i = 1;i<=MaxClients;++i){
					if(!IsValidClient3(i))
						continue;
					if(!IsPlayerAlive(i))
						continue;
					if(!IsOnDifferentTeams(client, i))
						continue;
					
					if(IsTargetInSightRange(client, i, 10.0, totalRange) && ClientCanSeeClient(client, i)){
						autoAim(client, i, angles);
						AttackTicks[client] = 6;
					}
				}
			}
			BotTimer[client] = 3;
		}
		else
		{
			BotTimer[client] -= 1;
		}
		if(AttackTicks[client] > 0){
		AttackTicks[client]--;buttons |= IN_ATTACK;changed=true;}
		if(SecondaryTicks[client] > 0){
		SecondaryTicks[client]--;buttons |= IN_ATTACK2;changed=true;}
		if(CrouchTicks[client] > 0){
		CrouchTicks[client]--;buttons |= IN_DUCK;changed=true;}
		if(JumpTicks[client] > 0){
		JumpTicks[client]--;buttons |= IN_JUMP;changed=true;}
		if(LeftTicks[client] > 0){
		LeftTicks[client]--;buttons |= IN_MOVELEFT;changed=true;}
		if(RightTicks[client] > 0){
		RightTicks[client]--;buttons |= IN_MOVERIGHT;changed=true;}
	}
	if(changed)
		return Plugin_Changed;
	return Plugin_Continue;
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