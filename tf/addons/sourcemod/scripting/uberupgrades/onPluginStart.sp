public Action:Timer_WaitForTF2Econ(Handle:timer)
{
	new i = 0
	if (TF2II_IsValidAttribID(1))
	{
		for (i = 0; i < 3000; i++)
		{
			if (TF2II_IsValidAttribID(i))
			{
				TF2II_GetAttribName( i, upgradesWorkNames[i], 96 );
			}
		}
		for (i = 0; i < MAX_ATTRIBUTES; i++)
		{
			upgrades_ratio[i] = 0.0;
			upgrades_i_val[i] = 0.0;
			upgrades_costs[i] = 0;
			upgrades_costs_inc_ratio[i] = 0.20;
			upgrades_m_val[i] = 0.0;
			upgrades_restriction_category[i] = 0;
			upgrades_display_style[i] = 0;
			upgrades_description[i] = "";
		}
		for (i = 0; i < _NUMBER_DEFINELISTS; i++)
		{
			given_upgrd_classnames_tweak_idx[i] = -1
			given_upgrd_list_nb[i] = 0
		}
		_load_cfg_files()
		KillTimer(timer);
	}
	PrintToChatAll("UU Configs Reloaded");
}

public UberShopDefineUpgradeTabs()
{
	new i = 0
	while (i < MaxClients)
	{
		client_respawn_handled[i] = 0
		client_respawn_checkpoint[i] = 0
		up_menus[i] = INVALID_HANDLE
		new j = 0
		while (j < NB_SLOTS_UED)
		{
			currentupgrades_number[i][j] = 0
			currentitem_level[i][j] = 0
			currentitem_idx[i][j] = 20000
			client_spent_money[i][j] = 0.0
			client_tweak_highest_requirement[i][j] = 0.0;
			new k = 0
			while (k < MAX_ATTRIBUTES)
			{
				upgrades_ref_to_idx[i][j][k] = 20000
				k++
			}
			j++
		}	
		i++
	
	}
	
	current_slot_name[0] = "Primary Weapon"
	current_slot_name[1] = "Secondary Weapon"
	current_slot_name[2] = "Melee Weapon"
	current_slot_name[3] = "Bought Weapon"
	current_slot_name[4] = "Body"
	upgradesNames[0] = ""
	CreateTimer(0.3, Timer_WaitForTF2Econ, _);
}
public UberShopinitMenusHandlers()
{
	LoadTranslations("tf2items_uu.phrases.txt");
	LoadTranslations("common.phrases.txt");
	
	cvar_uu_version = CreateConVar("uberupgrades_version", UU_VERSION, "The Plugin Version. Don't change.", FCVAR_NOTIFY);
	cvar_MoneyBonusKill = CreateConVar("sm_uu_moneybonuskill", "600", "Sets the money bonus a client gets for killing: default 200");
	cvar_StartMoney = CreateConVar("sm_uu_startmoney", "50000", "Sets the starting money: default 50000");
	cvar_ServerMoneyMult = CreateConVar("sm_uu_moneymult", "1.0", "Sets the Cash Multiplier: default 1.0");
	cvar_BotMultiplier = CreateConVar("sm_uu_botmultiplier", "0.65", "Sets the bot stat multiplier.: default 0.5");
	cvar_DisableBotUpgrade = CreateConVar("sm_uu_disablebotupgrades","0","Disables bot upgrades if set to 1");
	cvar_DisableCooldowns = CreateConVar("sm_uu_disablecooldowns","0","Disables arcane cooldowns if set to 1");
	
	HookConVarChange(cvar_MoneyBonusKill, OnCvarChanged);
	HookConVarChange(cvar_StartMoney, OnCvarChanged);
	HookConVarChange(cvar_ServerMoneyMult, OnCvarChanged);
	HookConVarChange(cvar_BotMultiplier, OnCvarChanged);
	HookConVarChange(cvar_DisableBotUpgrade, OnCvarChanged);
	HookConVarChange(cvar_DisableCooldowns, OnCvarChanged);
	
	if(cvar_uu_version)
	{
	}
	MoneyForTeamRatio[RED]  = 1.0
	MoneyForTeamRatio[BLUE]  = 1.0
	
	MoneyBonusKill = GetConVarFloat(cvar_MoneyBonusKill)
	StartMoney = GetConVarFloat(cvar_StartMoney)
	ServerMoneyMult = GetConVarFloat(cvar_ServerMoneyMult)
	OverAllMultiplier = GetConVarFloat(cvar_BotMultiplier);
	DisableBotUpgrades = GetConVarInt(cvar_DisableBotUpgrade);
	DisableCooldowns = GetConVarInt(cvar_DisableCooldowns);
	
	RegAdminCmd("reload_cfg", ReloadCfgFiles, ADMFLAG_ROOT, "Reloads All CFG files for Uberupgrades");
	RegAdminCmd("sm_uuspentmoney", ShowSpentMoney, ADMFLAG_GENERIC, "Shows everyones upgrades");
	RegAdminCmd("sm_setcash", Command_SetCash, ADMFLAG_GENERIC, "Sets cash of selected target/targets.");
	RegAdminCmd("sm_addcash", Command_AddCash, ADMFLAG_GENERIC, "Adds cash of selected target/targets.");
	RegAdminCmd("sm_removecash", Command_RemoveCash, ADMFLAG_GENERIC, "Removes cash of selected target/targets.");
	RegAdminCmd("sm_resetallplayers", ResetPlayers, ADMFLAG_ROOT, "Remove Everyones Upgrades");
	RegAdminCmd("sm_setcurrency", GiveAllMoney, ADMFLAG_ROOT, "Sets Uberuprgades Cash");
	RegAdminCmd("sm_test", TestCommand, ADMFLAG_ROOT, "Filler Test");
	RegAdminCmd("sm_damage", Command_DealDamage, ADMFLAG_ROOT, "Deals damage to a player.")
	RegAdminCmd("sm_giveKills", Command_GiveKills, ADMFLAG_ROOT, "Feeds kills to a strange weapon.")
	
	RegConsoleCmd("sm_scoreboard", ShowStats, "Shows everyones statisics");
	RegConsoleCmd("scoreboard", ShowStats, "Shows everyones statisics");
	RegConsoleCmd("sm_inspect", Command_ShowStats, "Shows stats of weapon/client.");
	
	RegConsoleCmd("sm_qbuy", Menu_QuickBuyUpgrade, "Buy upgrades in a large quantity");
	RegConsoleCmd("qbuy", Menu_QuickBuyUpgrade, "Buy upgrades in a large quantity");
	RegConsoleCmd("qb", Menu_QuickBuyUpgrade, "Buy upgrades in a large quantity");
	
	RegConsoleCmd("buy", Menu_BuyUpgrade, "Buy Menu");
	RegConsoleCmd("sm_buy", Menu_BuyUpgrade, "Buy Menu");
	RegConsoleCmd("shop", Menu_BuyUpgrade, "Buy Menu");
	RegConsoleCmd("sm_shop", Menu_BuyUpgrade, "Buy Menu");
	RegConsoleCmd("byu", Menu_BuyUpgrade, "Buy Menu");
	RegConsoleCmd("BUY", Menu_BuyUpgrade, "Buy Menu");
	
	RegConsoleCmd("sm_stats", ShowMults, "Shows all your multipliers.");
	RegConsoleCmd("sm_arcane", Command_UseArcane, "Use specified arcane spell.");
	RegConsoleCmd("sm_showhelp", ShowHelp, "Displays all UU help.")
	
	HookEvent("player_hurt", Event_Playerhurt, EventHookMode_Pre)
	HookEvent("post_inventory_application", Event_PlayerreSpawn)
	HookEvent("player_death", Event_PlayerDeath)
	HookEvent("player_changeclass", Event_PlayerChangeClass)
	HookEvent("player_class", Event_PlayerChangeClass)
	HookEvent("player_team", Event_PlayerChangeTeam)
	HookEvent("player_healed", Event_PlayerHealed)
	HookEvent("player_spawn", Event_PlayerreSpawn)
	HookEvent("player_teleported", Event_Teleported)
	HookEvent("deploy_buff_banner",	Event_BuffDeployed);
	HookEvent("mvm_reset_stats", Event_ResetStats);
	HookEvent("mvm_pickup_currency", Event_PlayerCollectMoney)
	HookEvent("mvm_begin_wave",Event_mvm_wave_begin)
	HookEvent("mvm_wave_complete",Event_mvm_wave_complete);
	
	AddCommandListener(jointeam_callback, "jointeam");
	AddCommandListener(eurekaAttempt, "eureka_teleport");
}
public OnMapStart()
{
	if(IsMvM())
	{
		new String:mapName[64]
		GetCurrentMap(mapName, sizeof(mapName))
		StrCat(mapName, sizeof(mapName),"_UU");
		ServerCommand("tf_mvm_popfile %s", mapName)
	}
	GameRules_SetProp("m_bPlayingMedieval", 0)
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient3(i)){continue;}
		if(b_Hooked[i] == false)
		{
			b_Hooked[i] = true;
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
			fl_MaxArmor[i] = 300.0;
			fl_CurrentArmor[i] = 300.0;
			fl_MaxFocus[i] = 100.0;
			fl_CurrentFocus[i] = 100.0;
			for(new i1 = 0; i1 < Max_Attunement_Slots; i1++)
			{
				AttunedSpells[i][i1] = 0.0;
			}
		}
	}
	PrecacheSound(SOUND_THUNDER, true);
	PrecacheSound(SOUND_ZAP, true);
	PrecacheSound(SOUND_HEAL, true);
	PrecacheSound(SOUND_CALLBEYOND_CAST, true);
	PrecacheSound(SOUND_CALLBEYOND_ACTIVE, true);
	PrecacheSound(SOUND_FREEZE, true);
	PrecacheSound(SOUND_SHOCKWAVE, true);
	PrecacheSound(SOUND_ARCANESHOOT, true);
	PrecacheSound(SOUND_ARCANESHOOTREADY, true);
	PrecacheSound(SOUND_FAIL, true);
	PrecacheSound(SOUND_INFERNO, true);
	PrecacheSound(SOUND_SPEEDAURA, true);
	PrecacheSound(SOUND_SABOTAGE, true);
	PrecacheSound(SOUND_ARROW);
	PrecacheSound(ExplosionSound1);
	PrecacheSound(ExplosionSound2);
	PrecacheSound(ExplosionSound3);
	PrecacheSound(SmallExplosionSound1);
	PrecacheSound(SmallExplosionSound2);
	PrecacheSound(SmallExplosionSound3);
	PrecacheSound(DetonatorExplosionSound);
	PrecacheSound(SOUND_ADRENALINE);
	PrecacheSound(SOUND_REVENGE);
	PrecacheSound(SOUND_SUPERNOVA);
	PrecacheSound(SOUND_DASH);
	PrecacheSound(SOUND_JAR_EXPLOSION);
	PrecacheModel("models/weapons/c_models/c_madmilk/c_madmilk.mdl");
	PrecacheModel("models/weapons/c_models/urinejar.mdl");
	PrecacheModel("models/weapons/c_models/c_breadmonster/c_breadmonster.mdl");
	PrecacheModel("models/weapons/c_models/c_breadmonster/c_breadmonster_milk.mdl");
	PrecacheModel("models/weapons/c_models/c_sd_cleaver/c_sd_cleaver.mdl");
	PrecacheModel("models/weapons/w_models/w_syringe_proj.mdl");
	PrecacheModel("materials/effects/arrowtrail_red.vmt");
	PrecacheModel("materials/effects/arrowtrail_blu.vmt");
	PrecacheModel("models/weapons/c_models/c_croc_knife/c_croc_knife.mdl");
	PrecacheModel("models/weapons/w_models/w_rocket_airstrike/w_rocket_airstrike.mdl");
	g_SmokeSprite = PrecacheModel("sprites/steam1.vmt");
	g_LightningSprite = PrecacheModel("sprites/lgtning.vmt");
	spriteIndex = PrecacheModel("materials/sprites/halo01.vmt");
	Laser = PrecacheModel("materials/sprites/laserbeam.vmt");
	PrecacheModel("materials/effects/animatedsheen/animatedsheen0.vmt");
	PrecacheModel("models/weapons/w_models/w_stickybomb3.mdl");
	//AltLaser = PrecacheModel("materials/sprites/arrow.vmt");
	new entity = FindEntityByClassname(-1, "func_upgradestation");
	if (entity > -1)
	{
		RemoveEntity(entity);
	}
}

public void OnPluginStart()
{
	UberShopinitMenusHandlers()
	UberShopDefineUpgradeTabs()
	
	DB = SQL_Connect("default", true, Error, sizeof(Error));
	
	if(DB == INVALID_HANDLE)
	{
		PrintToServer("UU : Cannot connect to SQL server. : %s", Error);
		CloseHandle(DB);
	} else{
		PrintToServer("UU : Successfully connected to SQL server.");
	}
	
	hudSync = CreateHudSynchronizer();
	hudSpells = CreateHudSynchronizer();
	hudWatermark = CreateHudSynchronizer();
	hudStatus = CreateHudSynchronizer();
	hudAbility = CreateHudSynchronizer();
	
	CreateTimer(0.1, Timer_FixedVariables, _, TIMER_REPEAT);
	mvmadditional = 1.0;
	StartMoney = GetConVarFloat(cvar_StartMoney);
	OverAllMultiplier = GetConVarFloat(cvar_BotMultiplier);
	
	CreateTimer(1.0, Timer_Second, _, TIMER_REPEAT);
	CreateTimer(10.0, Timer_EveryTenSeconds, _, TIMER_REPEAT);
	CreateTimer(0.07, Timer_Every100MS, _, TIMER_REPEAT);
	
	OnPluginStart_RegisterWeaponData();
	
	logic = FindEntityByClassname(-1, "tf_objective_resource");
	cvar_debug = CreateConVar("sm_debugmode", "0", "toggles chat spam");
	debugMode = view_as<bool>(GetConVarInt(cvar_debug));

	//Offsets
	Handle hConf = LoadGameConfigFile("tf2.uurevamped");
	
	if (LookupOffset(g_iOffset, "CTFPlayer", "m_iSpawnCounter"))
	g_iOffset -= GameConfGetOffset(hConf, "m_flTauntAttackTime");
	
	//Grenade Call
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "CTFWeaponBaseGrenadeProj::InitGrenade(int float)");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	g_SDKCallInitGrenade = EndPrepSDKCall();
	if(g_SDKCallInitGrenade==INVALID_HANDLE)
	{
		PrintToServer("CustomAttrs | Grenade Creation offset not found.");
	}
	//fire rate?
	Handle g_DHookFireRateCall = DHookCreateFromConf(hConf, "CTFWeaponBase::ApplyFireDelay(float)");
	
	if(g_DHookFireRateCall == INVALID_HANDLE)
	{
		PrintToServer("CustomAttrs | Fire rate error");
	}
	DHookEnableDetour(g_DHookFireRateCall, true, OnFireRateCall);

	//Modify Rage
	Handle g_DHookOnModifyRage = DHookCreateFromConf(hConf, "CTFPlayerShared::ModifyRage()");
	
	if(g_DHookOnModifyRage == INVALID_HANDLE)
	{
		PrintToServer("CustomAttrs | Rage Modifier fucked up.");
	}
	DHookEnableDetour(g_DHookOnModifyRage, false, OnModifyRagePre);
	//Bot speed
	Handle g_DHookBotSpeed = DHookCreateFromConf(hConf, "CTFBotLocomotion::GetRunSpeed()");
	
	if(g_DHookBotSpeed == INVALID_HANDLE)
	{
		PrintToServer("CustomAttrs | Bot speed cap removal fucked up.");
	}
	else
	{
		PrintToServer("CustomAttrs | Bot speed cap removal applied.")
	}
	DHookEnableDetour(g_DHookBotSpeed, true, OnCalculateBotSpeedPost);
	
	//Is In world
	Handle g_DHookInWorld = DHookCreateFromConf(hConf, "CBaseEntity::IsInWorld()");
	
	if(g_DHookInWorld == INVALID_HANDLE)
	{
		PrintToServer("CustomAttrs | Grenade patch fucked up.");
	}
	else
	{
		PrintToServer("CustomAttrs | Grenade patch applied.")
	}
	DHookEnableDetour(g_DHookInWorld, true, IsInWorldCheck);

	//Recoil changes
	Handle g_DHookRecoil = DHookCreateFromConf(hConf, "CBasePlayer::SetPunchAngle()");
	
	if(g_DHookRecoil == INVALID_HANDLE)
	{
		PrintToServer("CustomAttrs | Recoil patch fucked up.");
	}
	else
	{
		PrintToServer("CustomAttrs | Recoil patch applied.")
	}
	DHookEnableDetour(g_DHookRecoil, false, OnRecoilApplied);

	//Weapon Fired
	g_offset_CTFPlayerShared_pOuter = view_as<Address>(GameConfGetOffset(hConf, "CTFPlayerShared::m_pOuter"));
	
	int offset = GameConfGetOffset(hConf, "CBasePlayer::OnMyWeaponFired");
	if (offset == -1)
		SetFailState("Missing offset for CBasePlayer::OnMyWeaponFired");
	
	Hook_OnMyWeaponFired = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, OnMyWeaponFired);
	DHookAddParam(Hook_OnMyWeaponFired, HookParamType_Int);
	
	delete hConf;
			
	//Cookies
	hArmorXPos = RegClientCookie("razor_armorxpos", "X Coordinate of armor bar.", CookieAccess_Protected);
	hArmorYPos = RegClientCookie("razor_armorypos", "Y Coordinate of armor bar.", CookieAccess_Protected);
	SAwaterMark = RegClientCookie("uu_watermark", "Toggles whether the watermark appears.", CookieAccess_Protected);
	respawnMenu = RegClientCookie("uu_respawnmenu", "Toggles if you get the respawn menu on spawn.", CookieAccess_Protected);
	EngineerTutorial = RegClientCookie("tutorial_engineer", "State of Tutorial", CookieAccess_Protected);
	ArmorTutorial = RegClientCookie("tutorial_armor", "State of Tutorial", CookieAccess_Protected);
	ArcaneTutorial = RegClientCookie("tutorial_arcane", "State of Tutorial", CookieAccess_Protected);
	WeaponTutorial = RegClientCookie("tutorial_weapons", "State of Tutorial", CookieAccess_Protected);
	particleToggle = RegClientCookie("particleToggle", "Toggles if you can see particles such as lightning enchantment on yourself.", CookieAccess_Protected);
	//Config
	SetConVarFloat(FindConVar("sv_maxvelocity"), 1000000000.0, true, false);
	SetConVarFloat(FindConVar("tf_scout_bat_launch_delay"), -0.1, true, false);
	//Database
	new String:queryString[512];
	Format(queryString, sizeof(queryString), "CREATE TABLE 'PlayerList' ('steamid' VARCHAR(64), 'datapack' INT)");
	new Handle:queryH = SQL_Query(DB, queryString);
	if(queryH != INVALID_HANDLE)
	{
		PrintToServer("UU : Successfully created a table.");
	}else{
		SQL_GetError(DB, Error, sizeof(Error));
		PrintToServer("UU : Was unable to create a table. | SQLERROR : %s.", Error);
	}
	//Refresh
	for (new client = 0; client < MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			fl_MaxArmor[client] = 300.0;
			fl_CurrentArmor[client] = 300.0;
			fl_MaxFocus[client] = 100.0;
			fl_CurrentFocus[client] = 100.0;
			client_no_d_team_upgrade[client] = 1
			current_class[client] = TF2_GetPlayerClass(client)
			if (!client_respawn_handled[client])
			{
				CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
			}
			CurrencyOwned[client] = (StartMoney + additionalstartmoney);
		}
		for(new i = 0; i < Max_Attunement_Slots; i++)
		{
			AttunedSpells[client][i] = 0.0;
		}
	}
	for (int i = 0 ; i <= MaxClients ; i++)
		if(IsValidClient3(i))
			OnClientPutInServer(i);
}
public OnAllPluginsLoaded()
{
	particleToggle = FindClientCookie("particleToggle");
}
public OnPluginEnd()
{
	PrintToServer("UU | Plugin stopped.")
	hudSync.Close();
	hudSpells.Close();
	hudWatermark.Close();
	hudAbility.Close();
	hudStatus.Close();
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient3(i)){continue;}
		fl_MaxArmor[i] = 300.0;
		fl_CurrentArmor[i] = 300.0;
		fl_MaxFocus[i] = 100.0;
		fl_CurrentFocus[i] = 100.0;
		//FakeClientCommand(i, "spectate");
		TF2Attrib_ClearCache(i);
		TF2Attrib_RemoveAll(i);
	}
	DeleteDatabase();
	for (int i = 1 ; i <= MaxClients ; i++)
		if(IsValidClient3(i))
			OnClientDisconnect(i);
}