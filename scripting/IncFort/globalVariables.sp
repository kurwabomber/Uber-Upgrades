//Handles
new Handle:up_menus[MAXPLAYERS + 1]
new Handle:menuBuy
new Handle:cvar_MoneyBonusKill
new Handle:cvar_ServerMoneyMult
new Handle:cvar_StartMoney
new Handle:cvar_DisableBotUpgrade
new Handle:cvar_DisableCooldowns
new Handle:_upg_names
new Handle:_weaponlist_names
new Handle:_spetweaks_names
new Handle:cvar_BotMultiplier
new Handle:DB = INVALID_HANDLE;
new Handle:hArmorXPos;
new Handle:hArmorYPos;
new Handle:respawnMenu;
new Handle:particleToggle;
new Handle:g_SDKCallInitGrenade;
new Handle:g_SDKCallSmack;
new Handle:g_SDKCallJar;
new Handle:g_SDKCallSentryThink;
new Handle:Hook_OnMyWeaponFired;
new Handle:hudSync;
new Handle:hudSpells;
//Tutorial
new Handle:EngineerTutorial;
new Handle:ArmorTutorial;
new Handle:ArcaneTutorial;
new Handle:WeaponTutorial;
//Integers
new DisableBotUpgrades
new DisableCooldowns
new gameStage;
new given_upgrd_list_nb[_NUMBER_DEFINELISTS]
new given_upgrd_subcat_nb[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT]
new given_upgrd_list[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT][_NUMBER_DEFINELISTS_CAT][128]
new upgrades_efficiency_list[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES]
new given_upgrd_classnames_tweak_idx[_NUMBER_DEFINELISTS]
new given_upgrd_classnames_tweak_nb[_NUMBER_DEFINELISTS]
new given_upgrd_subcat[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT]
new wcname_l_idx[WCNAMELISTSIZE]
new current_w_list_id[MAXPLAYERS + 1]
new current_w_c_list_id[MAXPLAYERS + 1]
new current_w_sc_list_id[MAXPLAYERS + 1]
new TFClassType:current_class[MAXPLAYERS + 1]
new TFClassType:previous_class[MAXPLAYERS + 1]
new current_slot_used[MAXPLAYERS + 1]
new currentupgrades_idx[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES_ITEM]
new currentupgrades_number[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
new currentitem_level[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
new currentitem_idx[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
new currentitem_ent_idx[MAXPLAYERS + 1][NB_SLOTS_UED + 1] 
new currentitem_catidx[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
new upgrades_ref_to_idx[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES]
new _u_id;
new client_new_weapon_ent_id[MAXPLAYERS + 1]
new client_last_up_slot[MAXPLAYERS + 1]
new client_last_up_idx[MAXPLAYERS + 1]		
new client_respawn_handled[MAXPLAYERS + 1]
new client_respawn_checkpoint[MAXPLAYERS + 1]
new client_no_d_team_upgrade[MAXPLAYERS + 1]
new upgrades_to_a_id[MAX_ATTRIBUTES]
new upgrades_costs[MAX_ATTRIBUTES]
new upgrades_tweaks_nb_att[_NB_SP_TWEAKS]
new upgrades_tweaks_att_idx[_NB_SP_TWEAKS][NB_SLOTS_UED + 1]
new blankArray[MAXPLAYERS + 1][16]
new blankArray1[MAXPLAYERS + 1][16][MAX_ATTRIBUTES_ITEM]
new g_iOffset;
new MadmilkInflictor[MAXPLAYERS + 1];
new g_SmokeSprite;
new g_LightningSprite;
new spriteIndex
new Laser;
new isParachuteReOpenable[MAXPLAYERS+1];
new autoSentryID[MAXPLAYERS+1];
new upgrades_weapon_nb;
new upgrades_weapon_current[MAXPLAYERS+1];
new upgrades_weapon_lookingat[MAXPLAYERS+1];
new upgrades_weapon_nb_att[NB_WEAPONS];
new upgrades_weapon_index[NB_WEAPONS];
new upgrades_weapon_att_idx[NB_WEAPONS][NB_SLOTS_UED + 1];
new buyableIndexOffParam[MAXPLAYERS+1][NB_WEAPONS]
new upgrades_restriction_category[MAX_ATTRIBUTES];
new currentupgrades_restriction[MAXPLAYERS + 1][NB_SLOTS_UED + 1][5];//maximum of 5 restrictions
new globalButtons[MAXPLAYERS+1];
new singularBuysPerMinute[MAXPLAYERS+1];
new bossPhase[MAXPLAYERS+1];
new upgrades_display_style[MAX_ATTRIBUTES];
new fanOfKnivesCount[MAXPLAYERS+1];
//Floats
new Float:MoneyBonusKill
new Float:StartMoney
new Float:MoneyForTeamRatio[2]
new Float:efficiencyCalculationTimer[MAXPLAYERS + 1]
new Float:currentupgrades_i[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES_ITEM]
new Float:currentupgrades_val[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES_ITEM]
new Float:upgrades_efficiency[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES]
new Float:client_spent_money[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
new Float:client_tweak_highest_requirement[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
new Float:upgrades_ratio[MAX_ATTRIBUTES]
new Float:upgrades_i_val[MAX_ATTRIBUTES]
new Float:upgrades_m_val[MAX_ATTRIBUTES]
new Float:upgrades_requirement[MAX_ATTRIBUTES]
new Float:upgrades_costs_inc_ratio[MAX_ATTRIBUTES]
new Float:upgrades_tweaks_att_ratio[_NB_SP_TWEAKS][NB_SLOTS_UED + 1]
new Float:upgrades_staged_max[MAX_ATTRIBUTES][MAX_STAGES];
new Float:additionalstartmoney;
new Float:CurrencyOwned[MAXPLAYERS + 1]
new Float:ServerMoneyMult = 1.0
new Float:OverAllMultiplier
new Float:DamageDealt[MAXPLAYERS + 1]
new Float:Kills[MAXPLAYERS + 1]
new Float:Deaths[MAXPLAYERS + 1]
new Float:dps[MAXPLAYERS + 1]
new Float:Healed[MAXPLAYERS + 1]
new Float:CurrencySaved[MAXPLAYERS + 1];
new Float:StartMoneySaved;
new Float:blankArray2[MAXPLAYERS + 1][16][MAX_ATTRIBUTES_ITEM]
new Float:MenuTimer[MAXPLAYERS +1];
new Float:ImpulseTimer[MAXPLAYERS +1];
new Float:fl_MaxArmor[MAXPLAYERS+1];
new Float:fl_CurrentArmor[MAXPLAYERS+1];
new Float:fl_AdditionalArmor[MAXPLAYERS+1];
new Float:fl_ArmorCap[MAXPLAYERS+1];
new Float:fl_ArmorRes[MAXPLAYERS+1];
new Float:fl_ArmorRegen[MAXPLAYERS+1];
new Float:fl_ArmorRegenConstant[MAXPLAYERS+1];
new Float:g_flLastAttackTime[MAXPLAYERS+1];
new Float:MadmilkDuration[MAXPLAYERS+1];
new Float:fl_MaxFocus[MAXPLAYERS+1];
new Float:fl_CurrentFocus[MAXPLAYERS+1];
new Float:fl_RegenFocus[MAXPLAYERS+1];
new Float:AttunedSpells[MAXPLAYERS + 1][Max_Attunement_Slots];
new Float:SpellCooldowns[MAXPLAYERS + 1][Max_Attunement_Slots];
new Float:ArcanePower[MAXPLAYERS + 1];
new Float:ArcaneDamage[MAXPLAYERS + 1];
new Float:LightningEnchantment[MAXPLAYERS + 1];
new Float:LightningEnchantmentDuration[MAXPLAYERS + 1];
new Float:DarkmoonBlade[MAXPLAYERS + 1];
new Float:DarkmoonBladeDuration[MAXPLAYERS + 1];
new Float:RPS[MAXPLAYERS+1];
new Float:lastMinesTime[MAXPLAYERS+1];
new Float:DragonsFurySpeedValue[MAXPLAYERS+1];
new Float:shieldVelocity[MAXPLAYERS+1];
new Float:weaponTrailTimer[MAXPLAYERS+1];
new Float:upgrades_tweaks_requirement[_NB_SP_TWEAKS]
new Float:upgrades_tweaks_cost[_NB_SP_TWEAKS]
new Float:fl_ArmorRegenBonusDuration[MAXPLAYERS+1]
new Float:fl_ArmorRegenBonus[MAXPLAYERS+1]
new Float:upgrades_weapon_cost[NB_WEAPONS];
new Float:upgrades_weapon_att_amt[NB_WEAPONS][NB_SLOTS_UED + 1];
new Float:weaponFireRate[MAXENTITIES+1];
new Float:disableIFMiniHud[MAXPLAYERS+1];

//String
new String:given_upgrd_classnames[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT][128]
new String:given_upgrd_subclassnames[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT][_NUMBER_DEFINELISTS_CAT][128]
new String:wcnamelist[WCNAMELISTSIZE][128]
new String:current_slot_name[NB_SLOTS_UED + 1][MAXPLAYERS + 1]
new String:currentitem_classname[MAXPLAYERS + 1][NB_SLOTS_UED + 1][128]
new String:upgradesNames[MAX_ATTRIBUTES][128]
new String:upgradesWorkNames[MAX_ATTRIBUTES][96]
new String:upgrades_tweaks[_NB_SP_TWEAKS][128]
new String:Error[255];
new String:upgrades_weapon_class[NB_WEAPONS][128]
new String:upgrades_weapon_class_menu[NB_WEAPONS][128]
new String:upgrades_weapon_class_restrictions[NB_WEAPONS][128]
new String:upgrades_weapon_description[NB_WEAPONS][512]
new String:upgrades_weapon[NB_WEAPONS][128];
new String:upgrades_description[MAX_ATTRIBUTES][512];
char ArmorXPos[MAXPLAYERS + 1][64];
char ArmorYPos[MAXPLAYERS + 1][64];
new String:SpellList[][] = {"Zap","Lightning Strike","Projected Healing","A Call Beyond","Blacksky Eye","Sunlight Spear","Lightning Enchantment","Snap Freeze","Arcane Prison","darkmoon blade from dark souls","Speed Aura","Aerial Strike","Inferno","Mine Field","Shockwave","Auto-Sentry","Soothing Sunlight","Arcane Hunter","Sabotage"}

//Bools
new bool:inScore[MAXPLAYERS+1];
new bool:hardcapWarning = false;
new bool:isFailHooked = false;
new bool:isEntitySentry[MAXENTITIES+1];
new bool:sentryThought[MAXENTITIES+1];
//MvM Checkpoints

new currentupgrades_idx_mvm_chkp[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES_ITEM]
new currentupgrades_number_mvm_chkp[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
new upgrades_ref_to_idx_mvm_chkp[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES]
new client_new_weapon_ent_id_mvm_chkp[MAXPLAYERS + 1]
new currentupgrades_restriction_mvm_chkp[MAXPLAYERS + 1][NB_SLOTS_UED + 1][5];
new Float:currentupgrades_val_mvm_chkp[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES_ITEM]
new Float:client_spent_money_mvm_chkp[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
new Float:waveToCurrency[] = {60000.0, 92000.0, 130400.0, 176480.0, 231776.0, 298131.2, 377757.4, 473308.9, 587970.7, 725564.0, 890677.8, 1088813.3, 1326576.0, 1611891.0, 1954269.0, 1954269.0, 2365123.0, 2858148.0}
new Float:spellScaling[] = {0.0,2.45,2.55,2.65};
//Custom Attributes
new Float:fl_GlobalCoolDown[MAXPLAYERS+1];
new Float:weaponArtCooldown[MAXPLAYERS+1];
new Float:weaponArtParticle[MAXPLAYERS+1];
new Float:powerupParticle[MAXPLAYERS+1];
new Float:fl_ArrowStormDuration[MAXPLAYERS+1];
//new ChatPerSecond[MAXPLAYERS+1];
new Float:BotTimer[MAXPLAYERS+1];
new Float:LastCharge[MAXPLAYERS+1];
//new Float:PlayerLevel[MAXPLAYERS+1];
new CaberUses[MAXPLAYERS+1];
new Float:OverallMod = 1.0;
new Float:DefenseMod = 1.75;
new Float:DamageMod = 2.1;
new Float:DefenseIncreasePerWaveMod = 0.03;

new Float:TankSentryDamageMod = 1.0;
//Status Effects
new Float:BleedBuildup[MAXPLAYERS+1];
new Float:RadiationBuildup[MAXPLAYERS+1];
new Float:RageBuildup[MAXPLAYERS+1];
new Float:SupernovaBuildup[MAXPLAYERS+1];
new Float:ConcussionBuildup[MAXPLAYERS+1];
new Float:BleedMaximum[MAXPLAYERS+1];
new Float:RadiationMaximum[MAXPLAYERS+1];
//Statistics
new Float:lastDamageTaken[MAXPLAYERS+1];
new StrangeFarming[MAXPLAYERS+1][MAXPLAYERS+1];
new firestormCounter[MAXPLAYERS+1];
new lastFlag[MAXPLAYERS+1];
new Handle:cvar_debug;
new bool:debugMode = false;
//Projectiles
new ShotsLeft[MAXPLAYERS+1] = {20};
//Airblast Patch
new Float:flNextSecondaryAttack[MAXPLAYERS+1];
new Float:CurrentSlowTimer[MAXPLAYERS+1];
//Afterburn
new Float:fl_HighestFireDamage[MAXPLAYERS+1];
new logic;
new TankTeleporter = -1;
new bool:b_Hooked[MAXPLAYERS+1];
new bool:canShootAgain[MAXPLAYERS+1] = {true};
new bool:isBuffActive[MAXPLAYERS+1];
new bool:gravChanges[MAXENTITIES];
new jarateType[MAXENTITIES];
new jarateWeapon[MAXENTITIES];
new meleeLimiter[MAXPLAYERS+1];
new lightningCounter[MAXPLAYERS+1];
new plagueAttacker[MAXPLAYERS+1];
//Eye Angles
float fEyeAngles[MAXPLAYERS+1][3];
float trueVel[MAXPLAYERS+1][3];
new g_nBounces[MAXENTITIES];
new bool:isProjectileHoming[MAXENTITIES];
new bool:isProjectileBoomerang[MAXENTITIES];
new Float:projectileHomingDegree[MAXENTITIES];
//new Float:isProjectileSlash[MAXENTITIES][2];
new bool:eurekaActive[MAXPLAYERS+1];
new Float:entitySpawnTime[MAXENTITIES]
new bool:StunShotBPS[MAXPLAYERS+1];
new bool:StunShotStun[MAXPLAYERS+1];
new bool:shouldAttack[MAXPLAYERS+1];
new bool:critStatus[MAXPLAYERS+1];
new bool:miniCritStatus[MAXPLAYERS+1];
new bool:RageActive[MAXPLAYERS+1];
new bool:canBypassRestriction[MAXPLAYERS+1];
new Float:miniCritStatusVictim[MAXPLAYERS+1];
new Float:miniCritStatusAttacker[MAXPLAYERS+1];
new Float:corrosiveDOT[MAXPLAYERS+1][MAXPLAYERS+1][2]
//Handles
new Handle:hudAbility;
new Handle:hudStatus;
new Address:g_offset_CTFPlayerShared_pOuter;
//homing shit
new Float:homingRadius[MAXENTITIES];
new Float:homingDelay[MAXENTITIES];
new homingTickRate[MAXENTITIES];
new homingTicks[MAXENTITIES];
