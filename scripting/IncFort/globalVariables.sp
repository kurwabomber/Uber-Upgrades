//Handles
Handle up_menus[MAXPLAYERS+1]
Handle menuBuy
Handle cvar_MoneyBonusKill
Handle cvar_ServerMoneyMult
Handle cvar_StartMoney
Handle cvar_DisableBotUpgrade
Handle cvar_DisableCooldowns
Handle cvar_debug;
Handle cvar_InfiniteMoney;
Handle _upg_names;
Handle _weaponlist_names
Handle _spetweaks_names
Handle cvar_BotMultiplier
Handle DB = null;
Handle hArmorXPos;
Handle hArmorYPos;
Handle disableOptimizer;
Handle respawnMenu;
Handle particleToggle;
Handle knockbackToggle;
Handle g_SDKCallLaunchBall;
Handle g_SDKCallInitGrenade;
Handle g_SDKCallJar;
Handle g_SDKCallSentryThink;
Handle g_SDKFastBuild;

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
//enum structy style
enum struct Upgrade{
    float ratio;
    float i_val;
    float m_val;
    float cost_inc_ratio;
    float staged_max[MAX_STAGES];
    float requirement;
    int to_a_id;
    int cost;
    int restriction_category;
    int display_style;
    char name[64];
    char attr_name[64];
    char description[256];
}
enum struct Tweak{
    float cost;
    float requirement;
    float att_ratio[NB_SLOTS_UED+1];
    int restriction;
	int gamestage_requirement;
    int nb_att;
    int att_idx[NB_SLOTS_UED+1];
    char tweaks[64] //change name later
}
//96 different damagetypes should be enough?
enum struct extendedDamageTypes{
    int first;
    int second;
    int third;

    void clear(){
        this.first = 0;
        this.second = 0;
        this.third = 0;
    }
}
//Temp buffs for players
enum struct Buff{
	//All values start at 0
	char name[32];
	char description[64];
	int id; //For any custom effects, use a switch statement on logic.
	int priority;
	int inflictor; //UserID 
	float duration; //Measured in engine time (GetGameTime())
	float additiveDamageRaw;
	float additiveDamageMult;
	float multiplicativeDamage;
	float additiveAttackSpeedMult;
	float multiplicativeAttackSpeedMult;
	float additiveMoveSpeedMult;
	float additiveDamageTaken;
	float multiplicativeDamageTaken;
	float severity;

	void clear(){
		switch(this.id){
			case Buff_LifeLink:{
				for(int i=1;i<=MaxClients;++i){
					if(!IsValidClient3(i)) continue;
					if(!IsPlayerAlive(i)) continue;
					if(!IsOnDifferentTeams(this.inflictor,i))
						AddPlayerHealth(i, this.priority, 2.0, true, this.inflictor);
				}
			}
			case Buff_Frozen:{
				SetEntityRenderColor(this.priority, 255, 255, 255, 255);
				SetEntityMoveType(this.priority, MOVETYPE_WALK);
			}
		}

		this.name = "";
		this.description = "";
		this.id = 0;
		this.priority = 0;
		this.inflictor = 0;
		this.duration = 0.0;
		this.additiveDamageRaw = 0.0;
		this.additiveDamageMult = 0.0;
		this.multiplicativeDamage = 1.0;
		this.additiveAttackSpeedMult = 0.0;
		this.multiplicativeAttackSpeedMult = 1.0;
		this.additiveMoveSpeedMult = 0.0;
		this.additiveDamageTaken = 0.0;
		this.multiplicativeDamageTaken = 1.0;
		this.severity = 0.0;
	}
	void init(const char sName[32], const char sDescription[64], int iID, int iPriority, int iInflictor, float fDuration)
	{
		this.clear();
		this.name = sName;
		this.description = sDescription;
		this.id = iID;
		this.priority = iPriority;
		this.inflictor = iInflictor;
		this.duration = fDuration+GetGameTime();
	}
}
enum {
	Buff_Empty=0,
	Buff_Minicrits=1,
	Buff_MarkedForDeath=2,
	Buff_DefenseBoost=3,
	Buff_KingAura=4,
	Buff_LunchboxArmor=5,
	Buff_Haste=6,
	Buff_Speed=7,
	Buff_Jarated=8,
	Buff_Bruised=9,
	Buff_Stronghold=10,
	Buff_Leech=11,
	Buff_Decay=12,
	Buff_TagTeam=13,
	Buff_LifeLink=14,
	Buff_CritMarkedForDeath=15,
	Buff_Nullification=16,
	Buff_InfernalDOT=17,
	Buff_Enraged=18,
	Buff_DragonDance=19,
	Buff_Frozen=20,
	Buff_Radiation=21,
	Buff_PiercingBuff=22,
	Buff_BrokenArmor=23,
	Buff_LunchboxChange=24,
	Buff_Plunder=25,
	Buff_ImmolationBurn=26,
	Buff_InfernalLunge=27,
	Buff_PowerupBurning=28, 
	BuffAmt
};
bool isBonus[BuffAmt] = {
	false,
	true,
	false,
	true,
	true,
	true,
	true,
	true,
	false,
	false,
	true,
	false,
	false,
	true,
	false,
	false,
	false,
	true,
	false,
	false,
	false,
	true,
	false,
	true,
	true,
	false,
	true,
	false,
	false,
}
Buff playerBuffs[MAXPLAYERS+1][MAXBUFFS+1];
bool buffChange[MAXPLAYERS+1] = {false,...};
//oh boy
extendedDamageTypes currentDamageType[MAXENTITIES];
Upgrade upgrades[MAX_ATTRIBUTES];
Tweak tweaks[MAX_TWEAKS]

//Integers
int OwnerOffset;
int playerUpgradeMenus[MAXPLAYERS+1];
int playerUpgradeMenuPage[MAXPLAYERS+1];
int oldPlayerButtons[MAXPLAYERS+1];
int DisableBotUpgrades
int DisableCooldowns
int gameStage;
int given_upgrd_list_nb[LISTS]
int given_upgrd_subcat_nb[LISTS][LISTS_CATEGORIES]
int given_upgrd_list[LISTS][LISTS_CATEGORIES][LISTS_CATEGORIES][128]
int upgrades_efficiency_list[MAXPLAYERS+1][NB_SLOTS_UED+1][MAX_ATTRIBUTES]
int given_upgrd_classnames_tweak_idx[LISTS]
int given_upgrd_classnames_tweak_nb[LISTS]
int given_upgrd_subcat[LISTS][LISTS_CATEGORIES]
int wcname_l_idx[WCNAMELISTSIZE]
int current_w_list_id[MAXPLAYERS+1]
int current_w_c_list_id[MAXPLAYERS+1]
int current_w_sc_list_id[MAXPLAYERS+1]
int current_slot_used[MAXPLAYERS+1]
int currentupgrades_idx[MAXPLAYERS+1][NB_SLOTS_UED+1][MAX_ATTRIBUTES_ITEM]
int currentupgrades_number[MAXPLAYERS+1][NB_SLOTS_UED+1]
int currentitem_level[MAXPLAYERS+1][NB_SLOTS_UED+1]
int currentitem_idx[MAXPLAYERS+1][NB_SLOTS_UED+1]
int currentitem_ent_idx[MAXPLAYERS+1][NB_SLOTS_UED+1] 
int currentitem_catidx[MAXPLAYERS+1][NB_SLOTS_UED+1]
int upgrades_ref_to_idx[MAXPLAYERS+1][NB_SLOTS_UED+1][MAX_ATTRIBUTES]
int _u_id;
int client_new_weapon_ent_id[MAXPLAYERS+1]
int client_last_up_slot[MAXPLAYERS+1]
int client_last_up_idx[MAXPLAYERS+1]		
int client_respawn_handled[MAXPLAYERS+1]
int client_respawn_checkpoint[MAXPLAYERS+1]
int client_no_d_team_upgrade[MAXPLAYERS+1]
int blankArray[MAXPLAYERS+1][16]
int blankArray1[MAXPLAYERS+1][16][MAX_ATTRIBUTES_ITEM];
int MadmilkInflictor[MAXPLAYERS+1];
int g_SmokeSprite;
int g_LightningSprite;
int spriteIndex
int Laser;
int autoSentryID[MAXPLAYERS+1];
int upgrades_weapon_nb;
int upgrades_weapon_current[MAXPLAYERS+1];
int upgrades_weapon_lookingat[MAXPLAYERS+1];
int upgrades_weapon_nb_att[NB_WEAPONS];
int upgrades_weapon_index[NB_WEAPONS];
int upgrades_weapon_att_idx[NB_WEAPONS][MAX_ATTRIBUTES_ITEM+1];
int buyableIndexOffParam[MAXPLAYERS+1][NB_WEAPONS]
int currentupgrades_restriction[MAXPLAYERS+1][NB_SLOTS_UED+1][5];//maximum of 5 restrictions
int globalButtons[MAXPLAYERS+1];
int singularBuysPerMinute[MAXPLAYERS+1];
int bossPhase[MAXPLAYERS+1];
int fanOfKnivesCount[MAXPLAYERS+1];
int maelstromChargeCount[MAXPLAYERS+1];
int entityMaelstromChargeCount[MAXENTITIES];
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
int g_nBounces[MAXENTITIES];
int lastKBSource[MAXPLAYERS+1];
int knockbackFlags[MAXPLAYERS+1];
int relentlessTicks[MAXPLAYERS+1];
int Kills[MAXPLAYERS+1]
int Deaths[MAXPLAYERS+1];
int LightningEnchantmentLevel[MAXPLAYERS+1];
int DarkmoonBladeLevel[MAXPLAYERS+1];
int InfernalEnchantmentLevel[MAXPLAYERS+1];
int snowstormParticle[MAXPLAYERS+1];
int tagTeamTarget[MAXPLAYERS+1];
int enragedKills[MAXPLAYERS+1];
int stickiesDetonated[MAXPLAYERS+1];

//Floats
float currentGameTime
float MoneyBonusKill
float StartMoney
float efficiencyCalculationTimer[MAXPLAYERS+1]
float currentupgrades_i[MAXPLAYERS+1][NB_SLOTS_UED+1][MAX_ATTRIBUTES_ITEM]
float currentupgrades_val[MAXPLAYERS+1][NB_SLOTS_UED+1][MAX_ATTRIBUTES_ITEM]
float upgrades_efficiency[MAXPLAYERS+1][NB_SLOTS_UED+1][MAX_ATTRIBUTES]
float client_spent_money[MAXPLAYERS+1][NB_SLOTS_UED+1]
float client_tweak_highest_requirement[MAXPLAYERS+1][NB_SLOTS_UED+1]
float additionalstartmoney;
float CurrencyOwned[MAXPLAYERS+1]
float ServerMoneyMult = 1.0
float OverAllMultiplier
float DamageDealt[MAXPLAYERS+1]
float dps[MAXPLAYERS+1]
float Healed[MAXPLAYERS+1]
float CurrencySaved[MAXPLAYERS+1];
float StartMoneySaved;
float blankArray2[MAXPLAYERS+1][16][MAX_ATTRIBUTES_ITEM]
float MenuTimer[MAXPLAYERS +1];
float ImpulseTimer[MAXPLAYERS +1];
float fl_ArmorCap[MAXPLAYERS+1];
float g_flLastAttackTime[MAXPLAYERS+1];
float MadmilkDuration[MAXPLAYERS+1];
float fl_MaxFocus[MAXPLAYERS+1];
float fl_CurrentFocus[MAXPLAYERS+1];
float fl_RegenFocus[MAXPLAYERS+1];
float AttunedSpells[MAXPLAYERS+1][Max_Attunement_Slots];
float SpellCooldowns[MAXPLAYERS+1][Max_Attunement_Slots];
float ArcanePower[MAXPLAYERS+1];
float ArcaneDamage[MAXPLAYERS+1];
float LightningEnchantment[MAXPLAYERS+1];
float LightningEnchantmentDuration[MAXPLAYERS+1];
float DarkmoonBlade[MAXPLAYERS+1];
float DarkmoonBladeDuration[MAXPLAYERS+1];
float InfernalEnchantment[MAXPLAYERS+1];
float InfernalEnchantmentDuration[MAXPLAYERS+1];
float RPS[MAXPLAYERS+1];
float lastMinesTime[MAXPLAYERS+1];
float weaponTrailTimer[MAXPLAYERS+1];
float upgrades_weapon_cost[NB_WEAPONS];
float upgrades_weapon_att_amt[NB_WEAPONS][MAX_ATTRIBUTES_ITEM+1];
float weaponFireRate[MAXENTITIES+1];
float disableIFMiniHud[MAXPLAYERS+1];
float fl_GlobalCoolDown[MAXPLAYERS+1];
float weaponArtCooldown[MAXPLAYERS+1];
float weaponArtParticle[MAXPLAYERS+1];
float powerupParticle[MAXPLAYERS+1];
float hitParticle[MAXPLAYERS+1];
float spellScaling[] = {0.0,2.25,2.35,2.45};
float BotTimer[MAXPLAYERS+1];
float LastCharge[MAXPLAYERS+1];
//float lastDamageTaken[MAXPLAYERS+1];
float flNextSecondaryAttack[MAXPLAYERS+1];
float CurrentSlowTimer[MAXPLAYERS+1];
float fl_HighestFireDamage[MAXPLAYERS+1];
float fEyeAngles[MAXPLAYERS+1][3];
float trueVel[MAXPLAYERS+1][3];
float miniCritStatusVictim[MAXPLAYERS+1];
float miniCritStatusAttacker[MAXPLAYERS+1];
float corrosiveDOT[MAXPLAYERS+1][MAXPLAYERS+1][2]
float entitySpawnPositions[MAXENTITIES][3];
float baseDamage[MAXPLAYERS+1];
float remainderHealthRegeneration[MAXPLAYERS+1];
float karmicJusticeScaling[MAXPLAYERS+1];
float bloodAcolyteBloodPool[MAXPLAYERS+1];
float duplicationCooldown[MAXPLAYERS+1];
float warpCooldown[MAXPLAYERS+1];
float frayNextTime[MAXPLAYERS+1];
float quakerTime[MAXPLAYERS+1];
float bloodboundDamage[MAXPLAYERS+1];
float bloodboundHealing[MAXPLAYERS+1];
float pylonCharge[MAXPLAYERS+1];
float savedCharge[MAXPLAYERS+1];
float chainLightningAbilityCharge[MAXPLAYERS+1];
float sunstarDuration[MAXPLAYERS+1];

//String
char given_upgrd_classnames[LISTS][LISTS_CATEGORIES][128]
char given_upgrd_subclassnames[LISTS][LISTS_CATEGORIES][LISTS_CATEGORIES][128]
char wcnamelist[WCNAMELISTSIZE][128]
char current_slot_name[NB_SLOTS_UED+1][MAXPLAYERS+1]
char currentitem_classname[MAXPLAYERS+1][NB_SLOTS_UED+1][128]
char Error[255];
char upgrades_weapon_class[NB_WEAPONS][128]
char upgrades_weapon_class_menu[NB_WEAPONS][128]
char upgrades_weapon_class_restrictions[NB_WEAPONS][128]
char upgrades_weapon_description[NB_WEAPONS][512]
char upgrades_weapon[NB_WEAPONS][128];
char ArmorXPos[MAXPLAYERS+1][64];
char ArmorYPos[MAXPLAYERS+1][64];
char missionName[512];
char SpellList[][] = {"Zap","Lightning Strike","Projected Healing","A Call Beyond","Blacksky Eye","Sunlight Spear",
"Lightning Enchantment","Snap Freeze","Arcane Prison","Darkmoon Blade","Speed Aura","Aerial Strike","Inferno",
"Mine Field","Shockwave","Auto-Sentry","Soothing Sunlight","Arcane Hunter","Sabotage","Infernal Enchantment",
"Splitting Thunder", "Antiseptic Blast", "Karmic Justice", "Snowstorm"}

//Bools
bool inScore[MAXPLAYERS+1];
bool hardcapWarning = false;
bool isEntitySentry[MAXENTITIES+1];
bool sentryThought[MAXENTITIES+1];
bool b_Hooked[MAXPLAYERS+1];
bool canShootAgain[MAXPLAYERS+1] = {true,...};
bool isBuffActive[MAXPLAYERS+1];
bool gravChanges[MAXENTITIES];
bool debugMode = false;
bool infiniteMoney = false;
bool StunShotBPS[MAXPLAYERS+1];
bool StunShotStun[MAXPLAYERS+1];
bool shouldAttack[MAXPLAYERS+1];
bool critStatus[MAXPLAYERS+1];
bool miniCritStatus[MAXPLAYERS+1];
bool RageActive[MAXPLAYERS+1];
bool canBypassRestriction[MAXPLAYERS+1];
bool isTagged[MAXPLAYERS+1][MAXPLAYERS+1];
bool isPenetrated[MAXENTITIES+1];
bool canOverride[MAXPLAYERS+1];
bool isPrimed[MAXENTITIES+1];
bool snowstormActive[MAXPLAYERS+1];
bool failLock;
bool strongholdEnabled[MAXPLAYERS+1];
bool immolationActive[MAXPLAYERS+1];
bool isDeathTick[MAXPLAYERS+1];
bool replenishStatus;
bool disableMvMCash;
bool DOTStacked[MAXENTITIES][MAXENTITIES];
//Other Datatypes
TFClassType current_class[MAXPLAYERS+1]
TFClassType previous_class[MAXPLAYERS+1]

//MvM
int currentupgrades_idx_mvm_chkp[MAXPLAYERS+1][NB_SLOTS_UED+1][MAX_ATTRIBUTES_ITEM]
int currentupgrades_number_mvm_chkp[MAXPLAYERS+1][NB_SLOTS_UED+1]
int upgrades_ref_to_idx_mvm_chkp[MAXPLAYERS+1][NB_SLOTS_UED+1][MAX_ATTRIBUTES]
int client_new_weapon_ent_id_mvm_chkp[MAXPLAYERS+1]
int currentupgrades_restriction_mvm_chkp[MAXPLAYERS+1][NB_SLOTS_UED+1][5];
float currentupgrades_val_mvm_chkp[MAXPLAYERS+1][NB_SLOTS_UED+1][MAX_ATTRIBUTES_ITEM]
float client_spent_money_mvm_chkp[MAXPLAYERS+1][NB_SLOTS_UED+1]
float waveToCurrency[] = {60000.0, 60000.0, 92000.0, 130400.0, 176480.0, 231776.0, 298131.2, 377757.4, 473308.9, 587970.7, 725564.0, 890677.8, 1088813.3, 1326576.0, 1611891.0, 1954269.0, 1954269.0, 2365123.0, 2858148.0}
float OverallMod = 1.0;
float DefenseMod = 1.75;
float DamageMod = 2.1;
float DefenseIncreasePerWaveMod = 0.03;
float TankSentryDamageMod = 1.0;

//Status Effects
float BleedBuildup[MAXPLAYERS+1];
float RadiationBuildup[MAXPLAYERS+1];
float RageBuildup[MAXPLAYERS+1];
float TeamTacticsBuildup[MAXPLAYERS+1];
float SupernovaBuildup[MAXPLAYERS+1];
float ConcussionBuildup[MAXPLAYERS+1];
float BleedMaximum[MAXPLAYERS+1];
float RadiationMaximum[MAXPLAYERS+1];
float FreezeBuildup[MAXPLAYERS+1];

//Projectile Properties
bool isProjectileHoming[MAXENTITIES];
bool isProjectileBoomerang[MAXENTITIES];
bool isProjectileFireball[MAXENTITIES];
bool isAimlessProjectile[MAXENTITIES];
float projectileHomingDegree[MAXENTITIES];
float projectileDamage[MAXENTITIES];
float entitySpawnTime[MAXENTITIES];
/*-- homing shit --*/
float homingRadius[MAXENTITIES];
float homingDelay[MAXENTITIES];
int homingTickRate[MAXENTITIES];
int homingAimStyle[MAXENTITIES];
int homingTicks[MAXENTITIES];