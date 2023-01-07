//Handles
Handle up_menus[MAXPLAYERS + 1]
Handle menuBuy
Handle cvar_MoneyBonusKill
Handle cvar_ServerMoneyMult
Handle cvar_StartMoney
Handle cvar_DisableBotUpgrade
Handle cvar_DisableCooldowns
Handle cvar_debug;
Handle _upg_names
Handle _weaponlist_names
Handle _spetweaks_names
Handle cvar_BotMultiplier
Handle DB = null;
Handle hArmorXPos;
Handle hArmorYPos;
Handle respawnMenu;
Handle particleToggle;
Handle g_SDKCallInitGrenade;
Handle g_SDKCallSmack;
Handle g_SDKCallJar;
Handle g_SDKCallSentryThink;
Handle Hook_OnMyWeaponFired;
Handle hudSync;
Handle hudSpells;
Handle hudAbility;
Handle hudStatus;
Address g_offset_CTFPlayerShared_pOuter;
//Tutorial
Handle EngineerTutorial;
Handle ArmorTutorial;
Handle ArcaneTutorial;
Handle WeaponTutorial;
//Integers
int DisableBotUpgrades
int DisableCooldowns
int gameStage;
int given_upgrd_list_nb[_NUMBER_DEFINELISTS]
int given_upgrd_subcat_nb[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT]
int given_upgrd_list[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT][_NUMBER_DEFINELISTS_CAT][128]
int upgrades_efficiency_list[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES]
int given_upgrd_classnames_tweak_idx[_NUMBER_DEFINELISTS]
int given_upgrd_classnames_tweak_nb[_NUMBER_DEFINELISTS]
int given_upgrd_subcat[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT]
int wcname_l_idx[WCNAMELISTSIZE]
int current_w_list_id[MAXPLAYERS + 1]
int current_w_c_list_id[MAXPLAYERS + 1]
int current_w_sc_list_id[MAXPLAYERS + 1]
int current_slot_used[MAXPLAYERS + 1]
int currentupgrades_idx[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES_ITEM]
int currentupgrades_number[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
int currentitem_level[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
int currentitem_idx[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
int currentitem_ent_idx[MAXPLAYERS + 1][NB_SLOTS_UED + 1] 
int currentitem_catidx[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
int upgrades_ref_to_idx[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES]
int _u_id;
int client_new_weapon_ent_id[MAXPLAYERS + 1]
int client_last_up_slot[MAXPLAYERS + 1]
int client_last_up_idx[MAXPLAYERS + 1]		
int client_respawn_handled[MAXPLAYERS + 1]
int client_respawn_checkpoint[MAXPLAYERS + 1]
int client_no_d_team_upgrade[MAXPLAYERS + 1]
int upgrades_to_a_id[MAX_ATTRIBUTES]
int upgrades_costs[MAX_ATTRIBUTES]
int upgrades_tweaks_nb_att[_NB_SP_TWEAKS]
int upgrades_tweaks_att_idx[_NB_SP_TWEAKS][NB_SLOTS_UED + 1]
int blankArray[MAXPLAYERS + 1][16]
int blankArray1[MAXPLAYERS + 1][16][MAX_ATTRIBUTES_ITEM]
int g_iOffset;
int MadmilkInflictor[MAXPLAYERS + 1];
int g_SmokeSprite;
int g_LightningSprite;
int spriteIndex
int Laser;
int isParachuteReOpenable[MAXPLAYERS+1];
int autoSentryID[MAXPLAYERS+1];
int upgrades_weapon_nb;
int upgrades_weapon_current[MAXPLAYERS+1];
int upgrades_weapon_lookingat[MAXPLAYERS+1];
int upgrades_weapon_nb_att[NB_WEAPONS];
int upgrades_weapon_index[NB_WEAPONS];
int upgrades_weapon_att_idx[NB_WEAPONS][NB_SLOTS_UED + 1];
int buyableIndexOffParam[MAXPLAYERS+1][NB_WEAPONS]
int upgrades_restriction_category[MAX_ATTRIBUTES];
int currentupgrades_restriction[MAXPLAYERS + 1][NB_SLOTS_UED + 1][5];//maximum of 5 restrictions
int globalButtons[MAXPLAYERS+1];
int singularBuysPerMinute[MAXPLAYERS+1];
int bossPhase[MAXPLAYERS+1];
int upgrades_display_style[MAX_ATTRIBUTES];
int fanOfKnivesCount[MAXPLAYERS+1];
int CaberUses[MAXPLAYERS+1];
int StrangeFarming[MAXPLAYERS+1][MAXPLAYERS+1];
int firestormCounter[MAXPLAYERS+1];
int lastFlag[MAXPLAYERS+1];
int ShotsLeft[MAXPLAYERS+1] = {20};
int logic;
int TankTeleporter = -1;
int jarateType[MAXENTITIES];
int jarateWeapon[MAXENTITIES];
int meleeLimiter[MAXPLAYERS+1];
int lightningCounter[MAXPLAYERS+1];
int plagueAttacker[MAXPLAYERS+1];
int g_nBounces[MAXENTITIES];

//Floats
float MoneyBonusKill
float StartMoney
float MoneyForTeamRatio[2]
float efficiencyCalculationTimer[MAXPLAYERS + 1]
float currentupgrades_i[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES_ITEM]
float currentupgrades_val[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES_ITEM]
float upgrades_efficiency[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES]
float client_spent_money[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
float client_tweak_highest_requirement[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
float upgrades_ratio[MAX_ATTRIBUTES]
float upgrades_i_val[MAX_ATTRIBUTES]
float upgrades_m_val[MAX_ATTRIBUTES]
float upgrades_requirement[MAX_ATTRIBUTES]
float upgrades_costs_inc_ratio[MAX_ATTRIBUTES]
float upgrades_tweaks_att_ratio[_NB_SP_TWEAKS][NB_SLOTS_UED + 1]
float upgrades_staged_max[MAX_ATTRIBUTES][MAX_STAGES];
float additionalstartmoney;
float CurrencyOwned[MAXPLAYERS + 1]
float ServerMoneyMult = 1.0
float OverAllMultiplier
float DamageDealt[MAXPLAYERS + 1]
float Kills[MAXPLAYERS + 1]
float Deaths[MAXPLAYERS + 1]
float dps[MAXPLAYERS + 1]
float Healed[MAXPLAYERS + 1]
float CurrencySaved[MAXPLAYERS + 1];
float StartMoneySaved;
float blankArray2[MAXPLAYERS + 1][16][MAX_ATTRIBUTES_ITEM]
float MenuTimer[MAXPLAYERS +1];
float ImpulseTimer[MAXPLAYERS +1];
float fl_MaxArmor[MAXPLAYERS+1];
float fl_CurrentArmor[MAXPLAYERS+1];
float fl_AdditionalArmor[MAXPLAYERS+1];
float fl_ArmorCap[MAXPLAYERS+1];
float fl_ArmorRes[MAXPLAYERS+1];
float fl_ArmorRegen[MAXPLAYERS+1];
float fl_ArmorRegenConstant[MAXPLAYERS+1];
float g_flLastAttackTime[MAXPLAYERS+1];
float MadmilkDuration[MAXPLAYERS+1];
float fl_MaxFocus[MAXPLAYERS+1];
float fl_CurrentFocus[MAXPLAYERS+1];
float fl_RegenFocus[MAXPLAYERS+1];
float AttunedSpells[MAXPLAYERS + 1][Max_Attunement_Slots];
float SpellCooldowns[MAXPLAYERS + 1][Max_Attunement_Slots];
float ArcanePower[MAXPLAYERS + 1];
float ArcaneDamage[MAXPLAYERS + 1];
float LightningEnchantment[MAXPLAYERS + 1];
float LightningEnchantmentDuration[MAXPLAYERS + 1];
float DarkmoonBlade[MAXPLAYERS + 1];
float DarkmoonBladeDuration[MAXPLAYERS + 1];
float RPS[MAXPLAYERS+1];
float lastMinesTime[MAXPLAYERS+1];
float DragonsFurySpeedValue[MAXPLAYERS+1];
float shieldVelocity[MAXPLAYERS+1];
float weaponTrailTimer[MAXPLAYERS+1];
float upgrades_tweaks_requirement[_NB_SP_TWEAKS]
float upgrades_tweaks_cost[_NB_SP_TWEAKS]
float fl_ArmorRegenBonusDuration[MAXPLAYERS+1]
float fl_ArmorRegenBonus[MAXPLAYERS+1]
float upgrades_weapon_cost[NB_WEAPONS];
float upgrades_weapon_att_amt[NB_WEAPONS][NB_SLOTS_UED + 1];
float weaponFireRate[MAXENTITIES+1];
float disableIFMiniHud[MAXPLAYERS+1];
float fl_GlobalCoolDown[MAXPLAYERS+1];
float weaponArtCooldown[MAXPLAYERS+1];
float weaponArtParticle[MAXPLAYERS+1];
float powerupParticle[MAXPLAYERS+1];
float fl_ArrowStormDuration[MAXPLAYERS+1];
float spellScaling[] = {0.0,2.45,2.55,2.65};
float BotTimer[MAXPLAYERS+1];
float LastCharge[MAXPLAYERS+1];
float lastDamageTaken[MAXPLAYERS+1];
float flNextSecondaryAttack[MAXPLAYERS+1];
float CurrentSlowTimer[MAXPLAYERS+1];
float fl_HighestFireDamage[MAXPLAYERS+1];
float fEyeAngles[MAXPLAYERS+1][3];
float trueVel[MAXPLAYERS+1][3];
float miniCritStatusVictim[MAXPLAYERS+1];
float miniCritStatusAttacker[MAXPLAYERS+1];
float corrosiveDOT[MAXPLAYERS+1][MAXPLAYERS+1][2]

//String
char given_upgrd_classnames[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT][128]
char given_upgrd_subclassnames[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT][_NUMBER_DEFINELISTS_CAT][128]
char wcnamelist[WCNAMELISTSIZE][128]
char current_slot_name[NB_SLOTS_UED + 1][MAXPLAYERS + 1]
char currentitem_classname[MAXPLAYERS + 1][NB_SLOTS_UED + 1][128]
char upgradesNames[MAX_ATTRIBUTES][128]
char upgradesWorkNames[MAX_ATTRIBUTES][96]
char upgrades_tweaks[_NB_SP_TWEAKS][128]
char Error[255];
char upgrades_weapon_class[NB_WEAPONS][128]
char upgrades_weapon_class_menu[NB_WEAPONS][128]
char upgrades_weapon_class_restrictions[NB_WEAPONS][128]
char upgrades_weapon_description[NB_WEAPONS][512]
char upgrades_weapon[NB_WEAPONS][128];
char upgrades_description[MAX_ATTRIBUTES][512];
char ArmorXPos[MAXPLAYERS + 1][64];
char ArmorYPos[MAXPLAYERS + 1][64];
char SpellList[][] = {"Zap","Lightning Strike","Projected Healing","A Call Beyond","Blacksky Eye","Sunlight Spear","Lightning Enchantment","Snap Freeze","Arcane Prison","darkmoon blade from dark souls","Speed Aura","Aerial Strike","Inferno","Mine Field","Shockwave","Auto-Sentry","Soothing Sunlight","Arcane Hunter","Sabotage"}

//Bools
bool inScore[MAXPLAYERS+1];
bool hardcapWarning = false;
bool isFailHooked = false;
bool isEntitySentry[MAXENTITIES+1];
bool sentryThought[MAXENTITIES+1];
bool b_Hooked[MAXPLAYERS+1];
bool canShootAgain[MAXPLAYERS+1] = {true};
bool isBuffActive[MAXPLAYERS+1];
bool gravChanges[MAXENTITIES];
bool debugMode = false;
bool eurekaActive[MAXPLAYERS+1];
bool StunShotBPS[MAXPLAYERS+1];
bool StunShotStun[MAXPLAYERS+1];
bool shouldAttack[MAXPLAYERS+1];
bool critStatus[MAXPLAYERS+1];
bool miniCritStatus[MAXPLAYERS+1];
bool RageActive[MAXPLAYERS+1];
bool canBypassRestriction[MAXPLAYERS+1];

//Other Datatypes
TFClassType current_class[MAXPLAYERS + 1]
TFClassType previous_class[MAXPLAYERS + 1]

//MvM
int currentupgrades_idx_mvm_chkp[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES_ITEM]
int currentupgrades_number_mvm_chkp[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
int upgrades_ref_to_idx_mvm_chkp[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES]
int client_new_weapon_ent_id_mvm_chkp[MAXPLAYERS + 1]
int currentupgrades_restriction_mvm_chkp[MAXPLAYERS + 1][NB_SLOTS_UED + 1][5];
float currentupgrades_val_mvm_chkp[MAXPLAYERS + 1][NB_SLOTS_UED + 1][MAX_ATTRIBUTES_ITEM]
float client_spent_money_mvm_chkp[MAXPLAYERS + 1][NB_SLOTS_UED + 1]
float waveToCurrency[] = {60000.0, 92000.0, 130400.0, 176480.0, 231776.0, 298131.2, 377757.4, 473308.9, 587970.7, 725564.0, 890677.8, 1088813.3, 1326576.0, 1611891.0, 1954269.0, 1954269.0, 2365123.0, 2858148.0}
float OverallMod = 1.0;
float DefenseMod = 1.75;
float DamageMod = 2.1;
float DefenseIncreasePerWaveMod = 0.03;
float TankSentryDamageMod = 1.0;

//Status Effects
float BleedBuildup[MAXPLAYERS+1];
float RadiationBuildup[MAXPLAYERS+1];
float RageBuildup[MAXPLAYERS+1];
float SupernovaBuildup[MAXPLAYERS+1];
float ConcussionBuildup[MAXPLAYERS+1];
float BleedMaximum[MAXPLAYERS+1];
float RadiationMaximum[MAXPLAYERS+1];

//Projectile Properties
bool isProjectileHoming[MAXENTITIES];
bool isProjectileBoomerang[MAXENTITIES];
float projectileHomingDegree[MAXENTITIES];
float entitySpawnTime[MAXENTITIES];
/*-- homing shit --*/
float homingRadius[MAXENTITIES];
float homingDelay[MAXENTITIES];
int homingTickRate[MAXENTITIES];
int homingTicks[MAXENTITIES];
