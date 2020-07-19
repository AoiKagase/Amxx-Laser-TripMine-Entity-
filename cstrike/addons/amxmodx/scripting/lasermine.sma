//=============================================
//	Plugin Writed by Visual Studio Code.
//=============================================
// Supported BIOHAZARD.
// #define BIOHAZARD_SUPPORT
// #define ZP_SUPPORT

//=====================================
//  INCLUDE AREA
//=====================================
#include <amxmodx>
#include <amxmisc>
#include <amxconst>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

//=====================================
//  VERSION CHECK
//=====================================
#if AMXX_VERSION_NUM < 182
	#assert "AMX Mod X v1.8.2 or greater library required!"
#endif

#pragma semicolon 1
#include <lasermine_util>

#if defined BIOHAZARD_SUPPORT || defined ZP_SUPPORT
	#include <lasermine_zombie>
#endif

#if !defined BIOHAZARD_SUPPORT && !defined ZP_SUPPORT
	#define PLUGIN 					"Laser/Tripmine Entity"
	#define CHAT_TAG 				"[Lasermine]"
	#define CVAR_TAG				"amx_ltm"
	#define CVAR_CFG				"ltm_cvars.cfg"
#endif

//=====================================
//  MACRO AREA
//=====================================
// AUTHOR NAME +ARUKARI- => SandStriker => Aoi.Kagase
#define AUTHOR 						"Aoi.Kagase"
#define VERSION 					"3.16"

//====================================================
//  GLOBAL VARIABLES
//====================================================
new int:gNowTime;
new gMsgBarTime;
new gSprites			[E_SPRITES];
new gCvar				[CVAR_SETTING];
new gEntMine;

new gDeployingMines		[MAX_PLAYERS];

#if AMXX_VERSION_NUM > 183
new Stack:gRecycleMine	[MAX_PLAYERS];
#endif



//====================================================
//  PLUGIN INITIALIZE
//====================================================
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	// Add your code here...
	register_concmd("lm_remove", 	"admin_remove_laser",ADMIN_ACCESSLEVEL, " - <num>"); 
	register_concmd("lm_give", 		"admin_give_laser",  ADMIN_ACCESSLEVEL, " - <num>"); 

	register_clcmd("+setlaser", 	"lm_progress_deploy");
	register_clcmd("+setlm", 		"lm_progress_deploy");
	register_clcmd("+dellaser", 	"lm_progress_remove");
	register_clcmd("+remlm", 		"lm_progress_remove");
   	register_clcmd("-setlaser", 	"lm_progress_stop");
   	register_clcmd("-setlm", 		"lm_progress_stop");
   	register_clcmd("-dellaser", 	"lm_progress_stop");
   	register_clcmd("-remlm", 		"lm_progress_stop");

	register_clcmd("say", 			"lm_say_lasermine");
#if !defined ZP_SUPPORT	
	register_clcmd("buy_lasermine", "lm_buy_lasermine");
#endif
	// CVar settings.
	// Common.
	gCvar[CVAR_ENABLE]	        = register_cvar(fmt("%s%s", CVAR_TAG, "_enable"),				"1"			);	// 0 = off, 1 = on.
	gCvar[CVAR_ACCESS_LEVEL]   	= register_cvar(fmt("%s%s", CVAR_TAG, "_access"),				"0"			);	// 0 = all, 1 = admin
	gCvar[CVAR_MODE]           	= register_cvar(fmt("%s%s", CVAR_TAG, "_mode"),   				"0"			);	// 0 = lasermine, 1 = tripmine, 2 = claymore wire trap
	gCvar[CVAR_START_DELAY]    	= register_cvar(fmt("%s%s", CVAR_TAG, "_round_delay"),			"5"			);	// Round start delay time.
	// Ammo.
	gCvar[CVAR_START_HAVE]	    = register_cvar(fmt("%s%s", CVAR_TAG, "_amount"),				"1"			);	// Round start have ammo count.
	gCvar[CVAR_MAX_HAVE]       	= register_cvar(fmt("%s%s", CVAR_TAG, "_max_amount"),   		"2"			);	// Max having ammo.
	gCvar[CVAR_TEAM_MAX]		= register_cvar(fmt("%s%s", CVAR_TAG, "_team_max"),				"10"		);	// Max deployed in team.

	// Buy system.
	gCvar[CVAR_BUY_MODE]	    = register_cvar(fmt("%s%s", CVAR_TAG, "_buy_mode"),				"1"			);	// 0 = off, 1 = on.
	gCvar[CVAR_CBT]    			= register_cvar(fmt("%s%s", CVAR_TAG, "_buy_team"),				"ALL"		);	// Can buy team. TR / CT / ALL. (BIOHAZARD: Z = Zombie)
	gCvar[CVAR_COST]           	= register_cvar(fmt("%s%s", CVAR_TAG, "_buy_price"),			"2500"		);	// Buy cost.
	gCvar[CVAR_BUY_ZONE]        = register_cvar(fmt("%s%s", CVAR_TAG, "_buy_zone"),				"1"			);	// Stay in buy zone can buy.
	gCvar[CVAR_FRAG_MONEY]     	= register_cvar(fmt("%s%s", CVAR_TAG, "_frag_money"),   		"300"		);	// Get money.

	// Laser design.
	gCvar[CVAR_LASER_VISIBLE]	= register_cvar(fmt("%s%s", CVAR_TAG, "_laser_visible"),		"1"			);	// Laser line visibility.
	gCvar[CVAR_LASER_COLOR]    	= register_cvar(fmt("%s%s", CVAR_TAG, "_laser_color_mode"),		"0"			);	// laser line color 0 = team color, 1 = green.
	// Leser beam color for team color mode.
	gCvar[CVAR_LASER_COLOR_TR] 	= register_cvar(fmt("%s%s", CVAR_TAG, "_laser_color_t"),		"255,0,0"	);	// Team-Color for Terrorist. default:red (R,G,B)
	gCvar[CVAR_LASER_COLOR_CT] 	= register_cvar(fmt("%s%s", CVAR_TAG, "_laser_color_ct"),		"0,0,255"	);	// Team-Color for Counter-Terrorist. default:blue (R,G,B)

	gCvar[CVAR_LASER_BRIGHT]   	= register_cvar(fmt("%s%s", CVAR_TAG, "_laser_brightness"),		"255"		);	// laser line brightness. 0 to 255
	gCvar[CVAR_LASER_WIDTH]   	= register_cvar(fmt("%s%s", CVAR_TAG, "_laser_width"),			"2"			);	// laser line width. 0 to 255
	gCvar[CVAR_LASER_DMG]      	= register_cvar(fmt("%s%s", CVAR_TAG, "_laser_damage"),			"60.0"		);	// laser hit dmg. Float Value!
	gCvar[CVAR_LASER_DMG_MODE]	= register_cvar(fmt("%s%s", CVAR_TAG, "_laser_damage_mode"),	"0"			);	// Laser line damage mode. 0 = frame dmg, 1 = once dmg, 2 = 1 second dmg.
	gCvar[CVAR_LASER_DMG_DPS]  	= register_cvar(fmt("%s%s", CVAR_TAG, "_laser_dps"),			"1"			);	// laser line damage mode 2 only, damage/seconds. default 1 (sec)
	gCvar[CVAR_LASER_RANGE]		= register_cvar(fmt("%s%s", CVAR_TAG, "_laser_range"),			"8192.0"	);	// Laser beam lange (float range.)

	// Mine design.
	gCvar[CVAR_MINE_HEALTH]    	= register_cvar(fmt("%s%s", CVAR_TAG, "_mine_health"),			"500"		);	// Tripmine Health. (Can break.)
	gCvar[CVAR_MINE_GLOW]      	= register_cvar(fmt("%s%s", CVAR_TAG, "_mine_glow"),			"1"			);	// Tripmine glowing. 0 = off, 1 = on.
	gCvar[CVAR_MINE_GLOW_MODE]  = register_cvar(fmt("%s%s", CVAR_TAG, "_mine_glow_color_mode"),	"0"			);	// Mine glow coloer 0 = team color, 1 = green, 2 = Health Indicator Glow(green to red).
	gCvar[CVAR_MINE_GLOW_TR]  	= register_cvar(fmt("%s%s", CVAR_TAG, "_mine_glow_color_t"),	"255,0,0"	);	// Team-Color for Terrorist. default:red (R,G,B)
	gCvar[CVAR_MINE_GLOW_CT]  	= register_cvar(fmt("%s%s", CVAR_TAG, "_mine_glow_color_ct"),	"0,0,255"	);	// Team-Color for Counter-Terrorist. default:blue (R,G,B)
	gCvar[CVAR_MINE_BROKEN]		= register_cvar(fmt("%s%s", CVAR_TAG, "_mine_broken"),			"0"			);	// Can broken Mines.(0 = mines, 1 = Team, 2 = Enemy)
	gCvar[CVAR_EXPLODE_RADIUS] 	= register_cvar(fmt("%s%s", CVAR_TAG, "_explode_radius"),		"320.0"		);	// Explosion radius.
	gCvar[CVAR_EXPLODE_DMG]		= register_cvar(fmt("%s%s", CVAR_TAG, "_explode_damage"),		"100"		);	// Explosion radius damage.

	// Misc Settings.
	gCvar[CVAR_DEATH_REMOVE]	= register_cvar(fmt("%s%s", CVAR_TAG, "_death_remove"),			"0"			);	// Dead Player remove lasermine. 0 = off, 1 = on.
	gCvar[CVAR_LASER_ACTIVATE]	= register_cvar(fmt("%s%s", CVAR_TAG, "_activate_time"),		"1"			);	// Waiting for put lasermine. (int:seconds. 0 = no progress bar.)
	gCvar[CVAR_ALLOW_PICKUP]	= register_cvar(fmt("%s%s", CVAR_TAG, "_allow_pickup"),			"1"			);	// allow pickup mine. (0 = disable, 1 = it's mine, 2 = allow friendly mine, 3 = allow enemy mine!)
	gCvar[CVAR_DIFENCE_SHIELD]	= register_cvar(fmt("%s%s", CVAR_TAG, "_shield_difence"),		"1"			);	// allow shiled difence.
	gCvar[CVAR_REALISTIC_DETAIL]= register_cvar(fmt("%s%s", CVAR_TAG, "_realistic_detail"), 	"0"			);	// Spark Effect.

	gCvar[CVAR_FRIENDLY_FIRE]  	= get_cvar_pointer("mp_friendlyfire");											// Friendly fire. 0 or 1
	gCvar[CVAR_VIOLENCE_HBLOOD]	= get_cvar_pointer("violence_hblood");
	
	// Register Hamsandwich
	RegisterHam(Ham_Spawn, 			"player", "NewRound", 		1);
	RegisterHam(Ham_Item_PreFrame,	"player", "KeepMaxSpeed", 	1);
	RegisterHam(Ham_TakeDamage, 	"player", "PlayerKilling", 	0);
	RegisterHam(Ham_Think,			ENT_CLASS_BREAKABLE, "LaserThink");
	RegisterHam(Ham_TakeDamage,		ENT_CLASS_BREAKABLE, "MinesTakeDamage");
	RegisterHam(Ham_TakeDamage,     ENT_CLASS_BREAKABLE, "MinesBreaked", 1);

	// Register Event
	register_event("DeathMsg", "DeathEvent",	"a");
	register_event("TeamInfo", "CheckSpectator","a");

	gMsgBarTime		= get_user_msgid("BarTime");

	// Register Forward.
	register_forward(FM_PlayerPostThink,"PlayerPostThink");
	register_forward(FM_TraceLine,		"MinesShowInfo", 1);

	// Multi Language Dictionary.
	register_dictionary("lasermine.txt");

	register_cvar("ltm_versions", VERSION, FCVAR_SERVER|FCVAR_SPONLY);

#if AMXX_VERSION_NUM > 183
	for(new i = 0; i < MAX_PLAYERS; i++)
		gRecycleMine[i] = CreateStack(1);
#endif

#if defined ZP_SUPPORT || defined BIOHAZARD_SUPPORT
	register_zombie();
#else
#if AMXX_VERSION_NUM > 183
	AutoExecConfig(true);
#endif
#endif

	// registered func_breakable
	gEntMine = engfunc(EngFunc_AllocString, ENT_CLASS_BREAKABLE);

	LoadDecals();

	return PLUGIN_CONTINUE;
}

#if AMXX_VERSION_NUM < 190
//====================================================
//  PLUGIN CONFIG
//====================================================
public plugin_cfg()
{
	new file[64];
	new len = charsmax(file);
	get_localinfo("amxx_configsdir", file, len);
	format(file, len, "%s/%s", file, CVAR_CFG);

	if(file_exists(file)) 
	{
		server_cmd("exec %s", file);
		server_exec();
	}
}
#endif
//====================================================
//  PLUGIN END
//====================================================
#if AMXX_VERSION_NUM > 183
public plugin_end()
{
	for(new i = 0; i < MAX_PLAYERS; i++)
		DestroyStack(gRecycleMine[i]);
}
#endif
//====================================================
//  PLUGIN PRECACHE
//====================================================
public plugin_precache() 
{
	for (new i = 0; i < sizeof(ENT_SOUNDS); i++)
		precache_sound(ENT_SOUNDS[i]);

	for (new i = 0; i < sizeof(ENT_SPRITES); i++)
		gSprites[i] = precache_model(ENT_SPRITES[i]);

	precache_model(ENT_MODELS);

	return PLUGIN_CONTINUE;
}

//====================================================
//  Bot Register Ham.
//====================================================
// new g_bots_registered = false;
// public client_authorized( id )
// {
//     if( !g_bots_registered && is_user_bot( id ) )
//     {
//         set_task( 0.1, "register_bots", id );
//     }
// }

// public register_bots( id )
// {
//     if( !g_bots_registered && is_user_connected( id ) )
//     {
//         RegisterHamFromEntity( Ham_TakeDamage, id, "PlayerKilling");
//         g_bots_registered = true;
//     }
// }

//====================================================
// Friendly Fire Method.
//====================================================
bool:is_valid_takedamage(iAttacker, iTarget)
{
	if (get_pcvar_num(gCvar[CVAR_FRIENDLY_FIRE]))
		return true;

	if (cs_get_user_team(iAttacker) != cs_get_user_team(iTarget))
		return true;

	return false;
}

//====================================================
// Round Start Initialize
//====================================================
public NewRound(id)
{
	// Check Plugin Enabled
	if (!get_pcvar_num(gCvar[CVAR_ENABLE]))
		return PLUGIN_CONTINUE;

	if (!is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	if (is_user_bot(id))
		return PLUGIN_CONTINUE;

	// alive?
	if (is_user_alive(id) && pev(id, pev_flags) & (FL_CLIENT)) 
	{
		// Delay time reset
		lm_set_user_delay_count(id, int:floatround(get_gametime()));

#if AMXX_VERSION_NUM > 183
		// Init Recycle Health.
		ClearStack(gRecycleMine[id]);
#endif
		// Task Delete.
		delete_task(id);

		// Removing already put lasermine.
		lm_remove_all_entity(id, ENT_CLASS_LASER);

		// Round start set ammo.
		set_start_ammo(id);

		// Refresh show ammo.
		show_ammo(id);
	}
	return PLUGIN_CONTINUE;
}

//====================================================
// Keep Max Speed.
//====================================================
public KeepMaxSpeed(id)
{
	if (is_user_alive(id))
	{
		new Float:now_speed = lm_get_user_max_speed(id);
		if (now_speed > 1.0 && now_speed < 300.0)
			lm_save_user_max_speed(id, lm_get_user_max_speed(id));
	}

	return PLUGIN_CONTINUE;
}

//====================================================
// Round Start Set Ammo.
// Native:_native_set_start_ammo(iPlugin, iParam);
//====================================================
set_start_ammo(id)
{
	// Get CVAR setting.
	new int:stammo = int:get_pcvar_num(gCvar[CVAR_START_HAVE]);

	// Zero check.
	if(stammo <= int:0) 
		return;

	// Getting have ammo.
	new int:haveammo = lm_get_user_have_mine(id);

	// Set largest.
	lm_set_user_have_mine(id, (haveammo <= stammo ? stammo : haveammo));

	return;
}

//====================================================
// Death Event / Delete Task.
//====================================================
public DeathEvent()
{
	// new kID = read_data(1); // killer
	new vID = read_data(2); // victim
	// new isHS = read_data(3); // is headshot
	// new wpnName = read_data(4); // wpnName

	// Check Plugin Enabled
	if (!get_pcvar_num(gCvar[CVAR_ENABLE]))
		return PLUGIN_CONTINUE;

	// Is Connected?
	if (is_user_connected(vID)) 
		delete_task(vID);

	// Dead Player remove lasermine.
	if (get_pcvar_num(gCvar[CVAR_DEATH_REMOVE]))
		lm_remove_all_entity(vID, ENT_CLASS_LASER);

	return PLUGIN_CONTINUE;
}

//====================================================
// Put LaserMine Start Progress A
//====================================================
public lm_progress_deploy(id)
{
	// Deploying Check.
	if (!check_for_deploy(id))
		return PLUGIN_HANDLED;

	new Float:wait = get_pcvar_float(gCvar[CVAR_LASER_ACTIVATE]);
	// Set Flag. start progress.
	lm_set_user_deploy_state(id, int:STATE_DEPLOYING);

	new iEnt = gDeployingMines[id] = engfunc(EngFunc_CreateNamedEntity, gEntMine);
	if (pev_valid(iEnt))
	{
		// set models.
		engfunc(EngFunc_SetModel, iEnt, ENT_MODELS);
		// set solid.
		set_pev(iEnt, pev_solid, 		SOLID_NOT);
		// set movetype.
		set_pev(iEnt, pev_movetype, 	MOVETYPE_FLY);

		set_pev(iEnt, pev_renderfx, 	kRenderFxHologram);
		set_pev(iEnt, pev_body, 		3);
		set_pev(iEnt, pev_sequence, 	TRIPMINE_WORLD);
		set_pev(iEnt, pev_rendermode,	kRenderTransAdd);
		set_pev(iEnt, pev_renderfx,	 	kRenderFxHologram);
		set_pev(iEnt, pev_renderamt,	255.0);
		set_pev(iEnt, pev_rendercolor,	{255.0,255.0,255.0});
	}

	if (wait > 0)
	{
		lm_show_progress(id, int:floatround(wait), gMsgBarTime);
	}

	// Start Task. Put Lasermine.
	set_task(wait, "SpawnMine", (TASK_PLANT + id));

	return PLUGIN_HANDLED;
}

//====================================================
// Removing target put lasermine.
//====================================================
public lm_progress_remove(id)
{
	// Removing Check.
	if (!check_for_remove(id))
		return PLUGIN_HANDLED;

	new Float:wait = get_pcvar_float(gCvar[CVAR_LASER_ACTIVATE]);
	if (wait > 0)
		lm_show_progress(id, int:floatround(wait), gMsgBarTime);

	// Set Flag. start progress.
	lm_set_user_deploy_state(id, int:STATE_PICKING);

	// Start Task. Remove Lasermine.
	set_task(wait, "RemoveMine", (TASK_RELEASE + id));

	return PLUGIN_HANDLED;
}

//====================================================
// Stopping Progress.
//====================================================
public lm_progress_stop(id)
{
	if (pev_valid(gDeployingMines[id]))
		lm_remove_entity(gDeployingMines[id]);
	gDeployingMines[id] = 0;

	lm_hide_progress(id, gMsgBarTime);
	delete_task(id);

	return PLUGIN_HANDLED;
}

//====================================================
// Task: Spawn Lasermine.
//====================================================
public SpawnMine(id)
{
	// Task Number to uID.
	new uID = id - TASK_PLANT;
	// is Valid?
	if(!gDeployingMines[uID])
	{
		cp_debug(uID);
		return PLUGIN_HANDLED_MAIN;
	}

	set_spawn_entity_setting(gDeployingMines[uID], uID, ENT_CLASS_LASER);

	return 1;
}

//====================================================
// Lasermine Settings.
//====================================================
stock set_spawn_entity_setting(iEnt, uID, classname[])
{
	// Entity Setting.
	// set class name.
	set_pev(iEnt, pev_classname, 		classname);
	// set models.
	engfunc(EngFunc_SetModel, iEnt, 	ENT_MODELS);
	// set solid.
	set_pev(iEnt, pev_solid, 			SOLID_NOT);
	// set movetype.
	set_pev(iEnt, pev_movetype, 		MOVETYPE_FLY);
	// set model animation.
	set_pev(iEnt, pev_frame,			0);
	set_pev(iEnt, pev_body, 			3);
	set_pev(iEnt, pev_sequence, 		TRIPMINE_WORLD);
	set_pev(iEnt, pev_framerate,		0);
	set_pev(iEnt, pev_rendermode,		kRenderNormal);
	set_pev(iEnt, pev_renderfx,	 		kRenderFxNone);
	// set take damage.
	set_pev(iEnt, pev_takedamage, 		DAMAGE_YES);
	set_pev(iEnt, pev_dmg, 				100.0);
	// set entity health.
	// if recycle health.
#if AMXX_VERSION_NUM > 183
	if (!IsStackEmpty(gRecycleMine[uID]))
	{
		new Float:health;
		PopStackCell(gRecycleMine[uID], health);
		lm_set_user_health(iEnt, 		health);
	}
	else
	{
		lm_set_user_health(iEnt, 		get_pcvar_float(gCvar[CVAR_MINE_HEALTH]));
	}
#else
	lm_set_user_health(iEnt, 			get_pcvar_float(gCvar[CVAR_MINE_HEALTH]));
#endif
	// set mine position
	set_mine_position(uID, iEnt);
	// Reset powoer on delay time.
	new Float:fCurrTime = get_gametime();

	// Save results to be used later.
	set_pev(iEnt, LASERMINE_OWNER, 		uID);
	set_pev(iEnt, LASERMINE_POWERUP,	fCurrTime + 2.5);
	set_pev(iEnt, LASERMINE_STEP, 		POWERUP_THINK);
	set_pev(iEnt, LASERMINE_COUNT,		fCurrTime);
	set_pev(iEnt, LASERMINE_BEAMTHINK,	fCurrTime);
	// think rate. hmmm....
	set_pev(iEnt, pev_nextthink, 		fCurrTime + 0.2 );
	// Power up sound.
	lm_play_sound(iEnt, 				SOUND_POWERUP);
	// Cound up. deployed.
	lm_set_user_mine_deployed(uID, 		lm_get_user_mine_deployed(uID) + int:1);
	// Cound down. have ammo.
	lm_set_user_have_mine(uID, 			lm_get_user_have_mine(uID) - int:1);
	// Set Flag. end progress.
	lm_set_user_deploy_state(uID, 		int:STATE_DEPLOYED);
	gDeployingMines[uID] = 0;

	// Refresh show ammo.
	show_ammo(uID);
}

//====================================================
// Set Lasermine Position.
//====================================================
set_mine_position(uID, iEnt)
{
	// Vector settings.
	new Float:vOrigin	[3],Float:vViewOfs	[3];
	new	Float:vNewOrigin[3],Float:vNormal	[3];
	new	Float:vTraceEnd	[3],Float:vEntAngles[3];
	new Float:vDecals	[3];

	// get user position.
	pev(uID, pev_origin, vOrigin);
	pev(uID, pev_view_ofs, vViewOfs);

	velocity_by_aim(uID, 128, vTraceEnd);

	xs_vec_add(vOrigin, vViewOfs, vOrigin);  	
	xs_vec_add(vTraceEnd, vOrigin, vTraceEnd);

    // create the trace handle.
	new trace = create_tr2();
	// get wall position to vNewOrigin.
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, IGNORE_MONSTERS, uID, trace);
	{
		new Float:fFraction;
		get_tr2( trace, TR_flFraction, fFraction );
			
		// -- We hit something!
		if ( fFraction < 1.0 )
		{
			// -- Save results to be used later.
			get_tr2( trace, TR_vecEndPos, vTraceEnd );
			get_tr2( trace, TR_vecPlaneNormal, vNormal );
		}
	}
    // free the trace handle.
	free_tr2(trace);

	xs_vec_add( vTraceEnd, vNormal, vDecals);
	xs_vec_mul_scalar( vNormal, 8.0, vNormal );
	xs_vec_add( vTraceEnd, vNormal, vNewOrigin );

	// set size.
	engfunc(EngFunc_SetSize, iEnt, Float:{ -4.0, -4.0, -4.0 }, Float:{ 4.0, 4.0, 4.0 } );
	// set entity position.
	engfunc(EngFunc_SetOrigin, iEnt, vNewOrigin );
	set_pev(iEnt, LASERMINE_DECALS, vDecals);

	// Rotate tripmine.
	vector_to_angle(vNormal, vEntAngles);
	// set angle.
	set_pev(iEnt, pev_angles, vEntAngles);
	// set laserbeam end point position.
	set_laserend_postiion(iEnt, vNormal, vNewOrigin);
}

//====================================================
// Set Laserbeam End Position.
//====================================================
set_laserend_postiion(iEnt, Float:vNormal[3], Float:vNewOrigin[3])
{
	// Calculate laser end origin.
	new Float:vBeamEnd[3];
	new Float:vTracedBeamEnd[3];
	new Float:vTemp[3];
	new Float:range = get_pcvar_float(gCvar[CVAR_LASER_RANGE]);

	new Float:fFraction = 0.0;
	new iIgnore;
	new className[MAX_NAME_LENGTH];
	new trace;	

	xs_vec_mul_scalar(vNormal, range, vNormal );
	xs_vec_add( vNewOrigin, vNormal, vBeamEnd );


	// create the trace handle.
	vTracedBeamEnd	= vBeamEnd;
	vTemp 			= vNewOrigin;
	iIgnore 		= -1;

	// Trace line
	while(fFraction < 1.0)
	{
 		trace = create_tr2();
		engfunc(EngFunc_TraceLine, vTemp, vBeamEnd, (IGNORE_MONSTERS | IGNORE_GLASS), iIgnore, trace);
		{
			get_tr2(trace, TR_flFraction, fFraction);
			get_tr2(trace, TR_vecEndPos, vTemp);
			iIgnore = get_tr2(trace, TR_pHit);

			if (get_pcvar_num(gCvar[CVAR_MODE]) == MODE_LASERMINE)
			{
				// is valid hit entity?
				if (pev_valid(iIgnore))
				{
					pev(iIgnore, pev_classname, className, charsmax(className));
					if (!equali(className, ENT_CLASS_BREAKABLE))
					{
						break;
					}
				} else {
					break;
				}
			}
			else
				break;
		}
		free_tr2(trace);
	}
	vTracedBeamEnd = vTemp;		
	// free the trace handle.
	free_tr2(trace);
	set_pev(iEnt, LASERMINE_BEAMENDPOINT1, vTracedBeamEnd);
}

//====================================================
// Task: Remove Lasermine.
//====================================================
public RemoveMine(id)
{
	new target, body;
	new Float:vOrigin[3];
	new Float:tOrigin[3];

	// Task Number to uID.
	new uID = id - TASK_RELEASE;

	// Get target entity.
	get_user_aiming(uID, target, body);

	// is valid target?
	if(!pev_valid(target))
		return 1;
	
	// Get Player Vector Origin.
	pev(uID, pev_origin, vOrigin);
	// Get Mine Vector Origin.
	pev(target, pev_origin, tOrigin);

	// Distance Check. far 70.0 (cm?)
	if(get_distance_f(vOrigin, tOrigin) > 70.0)
		return 1;
	
	new entityName[MAX_NAME_LENGTH];
	entityName = lm_get_entity_class_name(target);

	// Check. is Target Entity Lasermine?
	if(!equali(entityName, ENT_CLASS_LASER))
		return 1;

	new ownerID = pev(target, LASERMINE_OWNER);

	new PICKUP_MODE:pickup 	= PICKUP_MODE:get_pcvar_num(gCvar[CVAR_ALLOW_PICKUP]);
	switch(pickup)
	{
		case DISALLOW_PICKUP:
			return 1;
		case ONLY_ME:
		{
			// Check. is Owner you?
			if(ownerID != uID)
				return 1;
		}
		case ALLOW_FRIENDLY:
		{
			// Check. is friendly team?
			if(lm_get_laser_team(target) != cs_get_user_team(uID))
				return 1;
		}		
	}

	// Recycle Health.
#if AMXX_VERSION_NUM > 183
	new Float:health = lm_get_user_health(target);
	PushStackCell(gRecycleMine[uID], health);
#endif
	// Remove!
	lm_remove_entity(target);

	// Collect for this removed lasermine.
	lm_set_user_have_mine(uID, lm_get_user_have_mine(uID) + int:1);

	if (pev_valid(ownerID))
	{
		// Return to before deploy count.
		lm_set_user_mine_deployed(ownerID, lm_get_user_mine_deployed(ownerID) - int:1);
	}

	// Play sound.
	lm_play_sound(uID, SOUND_PICKUP);

	// Set Flag. end progress.
	lm_set_user_deploy_state(uID, int:STATE_DEPLOYED);

	// Refresh show ammo.
	show_ammo(uID);

	return 1;
}


//====================================================
// Check: Remove Lasermine.
//====================================================
bool:check_for_remove(id)
{
	new int:cvar_ammo		= int:get_pcvar_num(gCvar[CVAR_MAX_HAVE]);
	new ERROR:error 		= check_for_common(id);
	new PICKUP_MODE:pickup 	= PICKUP_MODE:get_pcvar_num(gCvar[CVAR_ALLOW_PICKUP]);
	// common check.
	if (error)
		return false;

	// have max ammo? (use buy system.)
	if (get_pcvar_num(gCvar[CVAR_BUY_MODE]) != 0)
	if (lm_get_user_have_mine(id) + int:1 > cvar_ammo) 
		return false;

	new target;
	new body;
	new Float:vOrigin[3];
	new Float:tOrigin[3];

	get_user_aiming(id, target, body);

	// is valid target entity?
	if(!pev_valid(target))
		return false;

	// get potision. player and target.
	pev(id, pev_origin, vOrigin);
	pev(target, pev_origin, tOrigin);

	// Distance Check. far 128.0 (cm?)
	if(get_distance_f(vOrigin, tOrigin) > 128.0)
		return false;
	
	new entityName[MAX_NAME_LENGTH];
	entityName = lm_get_entity_class_name(target);

	// is target lasermine?
	if(!equali(entityName, ENT_CLASS_LASER))
		return false;

	// Damaged?
	// new Float:health;
	// health = lm_get_user_health(target);
	// if (health < get_pcvar_float(gCvar[CVAR_MINE_HEALTH]))
	// {
	// 	cp_cant_pickup(id);
	// 	return false;
	// }

	switch(pickup)
	{
		case DISALLOW_PICKUP:
		{
			cp_cant_pickup(id);
			return false;
		}
		case ONLY_ME:
		{
			// is owner you?
			if(pev(target, LASERMINE_OWNER) != id)
				return false;
		}
		case ALLOW_FRIENDLY:
		{
			// is team friendly?
			if(lm_get_laser_team(target) != cs_get_user_team(id))
				return false;
		}
	}

	// Allow Enemy.
	return true;
}

//====================================================
// Lasermine Think Event.
//====================================================
public LaserThink(iEnt)
{
	// Check plugin enabled.
	if (!get_pcvar_num(gCvar[CVAR_ENABLE]))
		return HAM_IGNORED;

	// is valid this entity?
	if (!pev_valid(iEnt))
		return HAM_IGNORED;

	new entityName[MAX_NAME_LENGTH];
	entityName = lm_get_entity_class_name(iEnt);

	// is this lasermine? no.
	if (!equali(entityName, ENT_CLASS_LASER))
		return HAM_IGNORED;

	static Float:fCurrTime;
	static Float:vEnd[3];
	static TRIPMINE_THINK:step;

	fCurrTime = get_gametime();
	step = TRIPMINE_THINK:pev(iEnt, LASERMINE_STEP);

	// Get Laser line end potision.
	pev(iEnt, LASERMINE_BEAMENDPOINT1, vEnd);
	// Get owner id.
	new iOwner	= pev(iEnt, LASERMINE_OWNER);

	// lasermine state.
	switch(step)
	{
		// Power up.
		case POWERUP_THINK:
		{
			lm_step_powerup(iEnt, fCurrTime);
		}
		case BEAMUP_THINK:
		{
			lm_step_beamup(iEnt, vEnd, fCurrTime);
		}
		// Laser line activated.
		case BEAMBREAK_THINK:
		{
			lm_step_beambreak(iEnt, vEnd, fCurrTime);
		}
		case EXPLOSE_THINK:
		{
			// Stopping sound.
			lm_play_sound(iEnt, SOUND_STOP);
			// Effect Explosion.
			lm_step_explosion(iEnt, iOwner);
		}
	}

	return HAM_IGNORED;
}

lm_step_powerup(iEnt, Float:fCurrTime)
{
	new Float:fPowerupTime;
	pev(iEnt, LASERMINE_POWERUP, fPowerupTime);
	// over power up time.
		
	if (fCurrTime > fPowerupTime)
	{
		// next state.
		set_pev(iEnt, LASERMINE_STEP, BEAMUP_THINK);
		// activate sound.
		lm_play_sound(iEnt, SOUND_ACTIVATE);
	}

	mine_glowing(iEnt);

	// Think time.
	set_pev(iEnt, pev_nextthink, fCurrTime + 0.1);
}

lm_step_beamup(iEnt, Float:vEnd[3], Float:fCurrTime)
{
	// solid complete.
	set_pev(iEnt, pev_solid, SOLID_BBOX);
	// drawing laser line.
	if (get_pcvar_num(gCvar[CVAR_LASER_VISIBLE]))
	{
		draw_laserline(iEnt, vEnd);
		if(get_pcvar_num(gCvar[CVAR_REALISTIC_DETAIL]))
			lm_draw_spark_for_wall(vEnd);
	}

	// next state.
	set_pev(iEnt, LASERMINE_STEP, BEAMBREAK_THINK);
	// Think time.
	set_pev(iEnt, pev_nextthink, fCurrTime + 0.1);
}

lm_step_beambreak(iEnt, Float:vEnd[3], Float:fCurrTime)
{
	static Array:aTarget;
	static className[MAX_NAME_LENGTH];
	static hPlayer[HIT_PLAYER];
	static iOwner;
	static iTarget;
	static hitGroup;
	static trace;
	static Float:fFraction;
	static Float:vOrigin	[3];
	static Float:vHitPoint	[3];
	static Float:nextTime = 0.0;
	static Float:beamTime = 0.0;

	// Get this mine position.
	pev(iEnt, pev_origin, 			vOrigin);
	pev(iEnt, LASERMINE_COUNT, 		nextTime);
	pev(iEnt, LASERMINE_BEAMTHINK, 	beamTime);
	iOwner = pev(iEnt, LASERMINE_OWNER);

	if (fCurrTime > beamTime)
	{
		if (get_pcvar_num(gCvar[CVAR_LASER_VISIBLE]))
			draw_laserline(iEnt, vEnd);

		set_pev(iEnt, LASERMINE_BEAMTHINK, fCurrTime + random_float(0.1, 0.2));
	}

	if (get_pcvar_num(gCvar[CVAR_LASER_DMG_MODE]))
	{
		if (fCurrTime < nextTime)
		{
			// Think time.
			set_pev(iEnt, pev_nextthink, fCurrTime + 0.1);
			return false;
		}
	}

	aTarget = ArrayCreate(HIT_PLAYER);

	// create the trace handle.
	trace = create_tr2();

	fFraction	= 0.0;
	iTarget	= iEnt;
	ArrayClear(aTarget);
	vHitPoint = vOrigin;
	set_pev(iEnt, LASERMINE_COUNT, get_gametime());

	// Trace line
	while(fFraction < 1.0)
	{
		// Trace line
		engfunc(EngFunc_TraceLine, vHitPoint, vEnd, DONT_IGNORE_MONSTERS, iTarget, trace);
		{
			get_tr2(trace, TR_flFraction, fFraction);
			get_tr2(trace, TR_vecEndPos, vHitPoint);				
			iTarget		= get_tr2(trace, TR_pHit);
			hitGroup	= get_tr2(trace, TR_iHitgroup);
		}

		// Something has passed the laser.
		if (fFraction < 1.0)
		{
			// is valid hit entity?
			if (pev_valid(iTarget))
			{
				pev(iTarget, pev_classname, className, charsmax(className));
				if (equali(className, ENT_CLASS_BREAKABLE) || equali(className, ENT_CLASS_LASER))
				{
					hPlayer[I_TARGET] 	= iTarget;
					hPlayer[V_POSITION]	= _:vHitPoint;
					hPlayer[I_HIT_GROUP]= hitGroup;
					ArrayPushArray(aTarget, hPlayer);
					continue;
				}

				// is user?
				if (!(pev(iTarget, pev_flags) & (FL_CLIENT | FL_FAKECLIENT | FL_MONSTER)))
					continue;

				// is dead?
				if (!is_user_alive(iTarget))
					continue;

				// Hit friend and No FF.
				if (!is_valid_takedamage(iOwner, iTarget))
					continue;
				
				// is godmode?
				if (lm_is_user_godmode(iTarget))
					continue;

				hPlayer[I_TARGET] 	= iTarget;
				hPlayer[V_POSITION]	= _:vHitPoint;
				hPlayer[I_HIT_GROUP]= hitGroup;
				ArrayPushArray(aTarget, hPlayer);

				if (hitGroup == HIT_SHIELD && get_pcvar_num(gCvar[CVAR_DIFENCE_SHIELD]))
					break;

				// keep target id.
				set_pev(iEnt, pev_enemy, iTarget);
			}
			else
			{
				continue;
			}
		}
	}

	if (get_pcvar_num(gCvar[CVAR_MODE]) == MODE_TRIPMINE)
	{
		for (new n = 0; n < ArraySize(aTarget); n++)
		{
			ArrayGetArray(aTarget, n, hPlayer, sizeof(hPlayer));
			if (IsPlayer(hPlayer[I_TARGET]))
			{
				// State change. to Explosing step.
				set_pev(iEnt, LASERMINE_STEP, EXPLOSE_THINK);
				break;
			}
		}					
	}
	else
	{
		new Float:vEndPosition[3];
		for (new n = 0; n < ArraySize(aTarget); n++)
		{
			ArrayGetArray(aTarget, n, hPlayer, sizeof(hPlayer));
			xs_vec_copy(hPlayer[V_POSITION], vEndPosition);

			if(get_pcvar_num(gCvar[CVAR_REALISTIC_DETAIL])) 
				lm_draw_spark_for_wall(vEndPosition);

			// Laser line damage mode. Once or Second.
			create_laser_damage(iEnt, hPlayer[I_TARGET], hPlayer[I_HIT_GROUP], hPlayer[V_POSITION]);
		}					

		// Laser line damage mode. Once or Second.
		if (get_pcvar_num(gCvar[CVAR_LASER_DMG_MODE]) != 0)
		{
			if (ArraySize(aTarget) > 0)
				set_pev(iEnt, LASERMINE_COUNT, (nextTime + get_pcvar_float(gCvar[CVAR_LASER_DMG_DPS])));

			// if change target. keep target id.
			if (pev(iEnt, LASERMINE_HITING) != iTarget)
				set_pev(iEnt, LASERMINE_HITING, iTarget);
		}
	}

	// free the trace handle.
	free_tr2(trace);
	ArrayDestroy(aTarget);

	// Get mine health.
	static Float:iHealth;
	iHealth = lm_get_user_health(iEnt);

	// break?
	if (iHealth <= 0.0 || (pev(iEnt, pev_flags) & FL_KILLME))
		// next step explosion.
		set_pev(iEnt, LASERMINE_STEP, EXPLOSE_THINK);
				
	// Think time. random_float = laser line blinking.
	set_pev(iEnt, pev_nextthink, fCurrTime + 0.1);

	return true;

}

lm_step_explosion(iEnt, iOwner)
{
	// Stopping entity to think
	set_pev(iEnt, pev_nextthink, 0.0);

	// Count down. deployed lasermines.
	lm_set_user_mine_deployed(iOwner, lm_get_user_mine_deployed(iOwner) - int:1);

	// Stop laser line.
	lm_stop_laserline(iEnt);

	// effect explosion.
	static Float:fDamageMax;
	static Float:fDamageRadius;
	static Float:vOrigin[3];
	static Float:vDecals[3];

	fDamageMax 		= get_pcvar_float(gCvar[CVAR_EXPLODE_DMG]);
	fDamageRadius	= get_pcvar_float(gCvar[CVAR_EXPLODE_RADIUS]);
	pev(iEnt, pev_origin, vOrigin);
	pev(iEnt, LASERMINE_DECALS, vDecals);

	if(engfunc(EngFunc_PointContents, vOrigin) != CONTENTS_WATER) 
	{
		lm_create_explosion	(vOrigin, fDamageMax, fDamageRadius, gSprites[EXPLOSION_1], gSprites[EXPLOSION_2], gSprites[BLAST]);
		lm_create_smoke		(vOrigin, fDamageMax, fDamageRadius, gSprites[SMOKE]);
	}
	else 
	{
		lm_create_water_explosion(vOrigin, fDamageMax, fDamageRadius, gSprites[EXPLOSION_WATER]);
		lm_create_bubbles(vOrigin, fDamageMax * 1.0, fDamageRadius * 1.0, gSprites[BUBBLE]);
	}
	lm_create_explosion_decals(vDecals);

	// damage.
	lm_create_explosion_damage(iEnt, iOwner, fDamageMax, fDamageRadius);

	// remove this.
	lm_remove_entity(iEnt);
}

//====================================================
// Blocken Mines.
//====================================================
public MinesTakeDamage(victim, inflictor, attacker, Float:f_Damage, bit_Damage)
{
	new entityName[MAX_NAME_LENGTH];
	entityName = lm_get_entity_class_name(victim);

	// is this lasermine? no.
	if (!equali(entityName, ENT_CLASS_LASER))
		return HAM_IGNORED;

	// We get the ID of the player who put the mine.
	new iOwner = pev(victim, LASERMINE_OWNER);

	switch(get_pcvar_num(gCvar[CVAR_MINE_BROKEN]))
	{
		// 0 = mines.
		case 0:
		{
			// If the one who set the mine does not coincide with the one who attacked it, then we stop execution.
			if(iOwner != attacker)
				return HAM_SUPERCEDE;
		}
		// 1 = team.
		case 1:
		{
			// If the team of the one who put the mine and the one who attacked match.
			if(lm_get_laser_team(victim) != cs_get_user_team(attacker))
				return HAM_SUPERCEDE;
		}
		// 2 = Enemy.
		case 2:
		{
			return HAM_IGNORED;
		}
		// 3 = Enemy Only.
		case 3:
		{
			if(iOwner == attacker || lm_get_laser_team(victim) == cs_get_user_team(attacker))
				return HAM_SUPERCEDE;
		}
		default:
		{
			return HAM_IGNORED;
		}
	}
	return HAM_IGNORED;
}


//====================================================
// Drawing Laser line.
//====================================================
draw_laserline(iEnt, const Float:vEndOrigin[3])
{
	new tcolor	[3];
	new sRGB	[13];
	new sColor	[4];
	new sRGBLen 	= charsmax(sRGB);
	new sColorLen	= charsmax(sColor);
	new CsTeams:teamid = lm_get_laser_team(iEnt);
	new width 		= get_pcvar_num(gCvar[CVAR_LASER_WIDTH]);
	new i = 0, n = 0, iPos = 0;
	// Color mode. 0 = team color.
	if(get_pcvar_num(gCvar[CVAR_LASER_COLOR]) == 0)
	{
		switch(teamid)
		{
			case CS_TEAM_T:
				get_pcvar_string(gCvar[CVAR_LASER_COLOR_TR], sRGB, sRGBLen);
			case CS_TEAM_CT:
				get_pcvar_string(gCvar[CVAR_LASER_COLOR_CT], sRGB, sRGBLen);
			default:
#if !defined BIOHAZARD_SUPPORT
				formatex(sRGB, sRGBLen, "0,255,0");
#else
				formatex(sRGB, sRGBLen, "255,0,0");
#endif
		}

	}else
	{
		// Green.
		formatex(sRGB, sRGBLen, "0,255,0");
	}

	formatex(sRGB, sRGBLen, "%s%s", sRGB, ",");
	while(n < sizeof(tcolor))
	{
		i = split_string(sRGB[iPos += i], ",", sColor, sColorLen);
		tcolor[n++] = str_to_num(sColor);
	}
	/*
	stock lm_draw_laser(
		const iEnt,
		const Float:vEndOrigin[3], 
		const beam, 
		const framestart	= 0, 
		const framerate		= 0, 
		const life			= 1, 
		const width			= 1, 
		const wave			= 0, 
		const tcolor		[3],
		const bright		= 255,
		const speed			= 255
	)
	*/
	lm_draw_laser(iEnt, vEndOrigin, gSprites[LASER], 0, 0, 2, width, 0, tcolor, get_pcvar_num(gCvar[CVAR_LASER_BRIGHT]), 255);
}

//====================================================
// Laser damage
//====================================================
create_laser_damage(iEnt, iTarget, hitGroup, Float:hitPoint[])
{
	// Damage.
	new Float:dmg 	= get_pcvar_float(gCvar[CVAR_LASER_DMG]);

	new iAttacker = pev(iEnt,LASERMINE_OWNER);

	if (!is_user_alive(iTarget))
		return;

	if (get_pcvar_num(gCvar[CVAR_DIFENCE_SHIELD]) && hitGroup == HIT_SHIELD)
	{
		lm_play_sound(iTarget, SOUND_HIT_SHIELD);
		lm_draw_spark(hitPoint);
		lm_hit_shield(iTarget, dmg);
	}
	else
	{
		if (IsPlayer(iTarget))
		{
			lm_play_sound(iTarget, SOUND_HIT);
			lm_set_user_lasthit(iTarget, hitGroup);
			if (get_pcvar_num(gCvar[CVAR_VIOLENCE_HBLOOD]))
				lm_create_hblood(hitPoint, floatround(dmg), gSprites[BLOOD_SPRAY], gSprites[BLOOD_SPLASH]);
		}
		ExecuteHamB(Ham_TakeDamage, iTarget, iEnt, iAttacker, dmg, DMG_ENERGYBEAM);
	}
	set_pev(iEnt, LASERMINE_HITING, iTarget);
	return;
}

//====================================================
// Player killing (Set Money, Score)
//====================================================
public PlayerKilling(iVictim, inflictor, iAttacker, Float:damage, bits)
{
	static entityName[MAX_NAME_LENGTH];
	entityName = lm_get_entity_class_name(inflictor);
	//
	// Refresh Score info.
	//
	if (equali(entityName, ENT_CLASS_LASER) && is_user_alive(iVictim))
	{
		if (lm_get_user_health(iVictim) - damage > 0.0)
			return HAM_IGNORED;

		// Get Target Team.
		new CsTeams:aTeam = cs_get_user_team(iAttacker);
		new CsTeams:vTeam = cs_get_user_team(iVictim);

		new score  = (vTeam != aTeam) ? 1 : -1;

		// Attacker Frag.
		// Add Attacker Frag (Friendly fire is minus).
		// new aDeath	= cs_get_user_deaths(iAttacker);

		// cs_set_user_deaths(iAttacker, aDeath, false);
		// ExecuteHamB(Ham_AddPoints, iAttacker, score, true);

		new tDeath = cs_get_user_deaths(iVictim);

		cs_set_user_deaths(iVictim, tDeath, false);
		ExecuteHamB(Ham_AddPoints, iVictim, 0, true);

#if !defined ZP_SUPPORT && !defined BIOHAZARD_SUPPORT
		// Get Money attacker.
		new money  = get_pcvar_num(gCvar[CVAR_FRAG_MONEY]) * score;
		cs_set_user_money(iAttacker, cs_get_user_money(iAttacker) + money);
#endif

//		ExecuteHamB(Ham_Killed, iVictim, iAttacker, 0);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

#if !defined ZP_SUPPORT
//====================================================
// Buy Lasermine.
//====================================================
public lm_buy_lasermine(id)
{	
	new ERROR:error = check_for_buy(id);
	if( error )
	{
		show_error_message(id, error);
		return PLUGIN_CONTINUE;
	}

	new cost = get_pcvar_num(gCvar[CVAR_COST]);
	cs_set_user_money(id, cs_get_user_money(id) - cost);

	lm_set_user_have_mine(id, lm_get_user_have_mine(id) + int:1);

	cp_bought(id);

	lm_play_sound(id, SOUND_PICKUP);

	show_ammo(id);

	return PLUGIN_HANDLED;
}
#endif
//====================================================
// Show ammo.
//====================================================
show_ammo(id)
{ 
#if defined ZP_SUPPORT || defined BIOHAZARD_SUPPORT
	client_print(id, print_center, "[%i/%i]", lm_get_user_have_mine(id), get_pcvar_num(gCvar[CVAR_MAX_HAVE]));
#else
	if (get_pcvar_num(gCvar[CVAR_BUY_MODE]) != 0)
		client_print(id, print_center, "%L", id, LANG_KEY[STATE_AMMO], lm_get_user_have_mine(id), get_pcvar_num(gCvar[CVAR_MAX_HAVE]));
	else
		client_print(id, print_center, "%L", id, LANG_KEY[STATE_INF]);
#endif
} 

//====================================================
// Chat command.
//====================================================
public lm_say_lasermine(id)
{
	if(!get_pcvar_num(gCvar[CVAR_ENABLE]))
		return PLUGIN_CONTINUE;

	new said[32];
	read_argv(1, said, charsmax(said));
	
	if (equali(said,"/buy lasermine") || equali(said,"/lm"))
	{
#if defined ZP_SUPPORT
		zp_items_force_buy(id, gZpWeaponId);
#else
		lm_buy_lasermine(id);
#endif
	}

#if !defined ZP_SUPPORT
	else
	if (equali(said, "lasermine") || equali(said, "/lasermine"))
	{
		const SIZE = 1024;
		new msg[SIZE + 1], len = 0;
		len += formatex(msg[len], SIZE - len, "<html><head><style>body{background-color:gray;color:white;} table{border-color:black;}</style></head><body>");
		len += formatex(msg[len], SIZE - len, "<p><b>Laser/TripMine Entity v%s</b></p>", VERSION);
		len += formatex(msg[len], SIZE - len, "<p>You can be setting the mine on the wall.</p>");
		len += formatex(msg[len], SIZE - len, "<p>That laser will give what touched it damage.</p>");
		len += formatex(msg[len], SIZE - len, "<p><b>Commands</b></p>");
		len += formatex(msg[len], SIZE - len, "<table border='1' cellspacing='0' cellpadding='10'>");
		len += formatex(msg[len], SIZE - len, "<tr><td>say</td><td><b>/buy lasermine</b> or <b>/lm</td><td rowspan='2'>buying lasermine</td></tr>");
		len += formatex(msg[len], SIZE - len, "<tr><td>console</td><td><b>buy_lasermine</b></td></tr>");
		len += formatex(msg[len], SIZE - len, "<tr><tr><td rowspan='2'>bind</td><td><b>+setlaser</b></td><td>bind j +setlaser :using j set lasermine on wall.</td></tr>");
		len += formatex(msg[len], SIZE - len, "<tr><td><b>+dellaser</b></td><td>bind k +dellaser :using k remove lasermine.</td></tr>");
		len += formatex(msg[len], SIZE - len, "</table>");
		len += formatex(msg[len], SIZE - len, "</body></html>");
		show_motd(id, msg, "Lasermine Entity help");

		return PLUGIN_HANDLED;

	} else 
	if (containi(said, "laser") != -1) 
	{
		cp_refer(id);
		return PLUGIN_CONTINUE;
	}
#endif
	return PLUGIN_CONTINUE;
}

//====================================================
// Player post think event.
// Stop movement for mine deploying.
//====================================================
public PlayerPostThink(id) 
{
	if ((pev(id, pev_weapons) & (1 << CSW_C4)) && (pev(id, pev_oldbuttons) & IN_ATTACK))
		return FMRES_IGNORED;

	switch (lm_get_user_deploy_state(id))
	{
		case STATE_IDLE:
		{
			new bool:now_speed = (lm_get_user_max_speed(id) <= 1.0);
			if (now_speed)
				ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id);
		}
		case STATE_DEPLOYING:
		{
			if (pev_valid(gDeployingMines[id]))
			{
				// Vector settings.
				static	Float:vOrigin[3], Float:vViewOfs[3];
				static	Float:vNewOrigin[3],Float:vNormal[3],
						Float:vTraceEnd[3],Float:vEntAngles[3];

				// Get wall position.
				velocity_by_aim(id, 128, vTraceEnd);
				// get user position.
				pev(id, pev_origin, vOrigin);
				pev(id, pev_view_ofs, vViewOfs);
				xs_vec_add(vOrigin, vViewOfs, vOrigin);  	
				xs_vec_add(vTraceEnd, vOrigin, vTraceEnd);

			    // create the trace handle.
				static trace;
				trace = create_tr2();

				// get wall position to vNewOrigin.
				engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, IGNORE_MONSTERS, id, trace);
				{
					// -- We hit something!
					// -- Save results to be used later.
					get_tr2(trace, TR_vecEndPos, vTraceEnd);
					get_tr2(trace, TR_vecPlaneNormal, vNormal);

					if (xs_vec_distance(vOrigin, vTraceEnd) < 128.0)
					{
						xs_vec_mul_scalar(vNormal, 8.0, vNormal);
						xs_vec_add(vTraceEnd, vNormal, vNewOrigin);
						// set entity position.
						engfunc(EngFunc_SetOrigin, gDeployingMines[id], vNewOrigin);
						// Rotate tripmine.
						vector_to_angle(vNormal, vEntAngles);
						// set angle.
						set_pev(gDeployingMines[id], pev_angles, vEntAngles);
					}
					else
					{
						lm_progress_stop(id);
					}

				}
				// free the trace handle.
				free_tr2(trace);
			}			
			lm_set_user_max_speed(id, 1.0);
		}
		case STATE_PICKING:
		{
			lm_set_user_max_speed(id, 1.0);
		}
		case STATE_DEPLOYED:
		{
			ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id);
			lm_set_user_deploy_state(id, STATE_IDLE);
		}
	}

	return FMRES_IGNORED;
}

//====================================================
// Player connected.
//====================================================
public client_putinserver(id)
{
	// check plugin enabled.
	if(!get_pcvar_num(gCvar[CVAR_ENABLE]))
		return PLUGIN_CONTINUE;

	// reset deploy count.
	lm_set_user_mine_deployed(id, int:0);
	// reset hove mine.
	lm_set_user_have_mine(id, int:0);

#if AMXX_VERSION_NUM > 183
	// Init Recycle Health.
	ClearStack(gRecycleMine[id]);
#endif

	return PLUGIN_CONTINUE;
}

//====================================================
// Player Disconnect.
//====================================================
/*
	symbol "client_disconnect" is marked as deprecated: Use client_disconnected() instead.
*/
public client_disconnected(id)
{
	// check plugin enabled.
	if(!get_pcvar_num(gCvar[CVAR_ENABLE]))
		return PLUGIN_CONTINUE;

	// delete task.
	delete_task(id);
	// remove all lasermine.
	lm_remove_all_entity(id, ENT_CLASS_LASER);

#if AMXX_VERSION_NUM > 183
	// Init Recycle Health.
	ClearStack(gRecycleMine[id]);
#endif

	return PLUGIN_CONTINUE;
}


//====================================================
// Infected player Deploy stop. (BIOHAZARD)
//====================================================
#if defined BIOHAZARD_SUPPORT
public event_infect2(id)
{
	delete_task(id);
	return PLUGIN_CONTINUE;
}
#endif

//====================================================
// Delete Task.
//====================================================
delete_task(id)
{
	if (task_exists((TASK_PLANT + id)))
		remove_task((TASK_PLANT + id));

	if (task_exists((TASK_RELEASE + id)))
		remove_task((TASK_RELEASE + id));

	lm_set_user_deploy_state(id, STATE_IDLE);
	return;
}


//====================================================
// Check: common.
//====================================================
stock ERROR:check_for_common(id)
{
	new cvar_enable = get_pcvar_num(gCvar[CVAR_ENABLE]);
	new cvar_access = get_pcvar_num(gCvar[CVAR_ACCESS_LEVEL]);
	new user_flags	= get_user_flags(id) & ADMIN_ACCESSLEVEL;
	new is_alive	= is_user_alive(id);
	//new cvar_mode	= get_pcvar_num(gCvar[CVAR_MODE]);

	// Plugin Enabled
	if (!cvar_enable)
		return ERROR:NOT_ACTIVE;

	// Can Access.
	if (cvar_access != 0 && !user_flags) 
		return ERROR:NOT_ACCESS;

	// Is this player Alive?
	if (!is_alive) 
		return ERROR:NOT_ALIVE;

	// Can set Delay time?
	return ERROR:check_for_time(id);
}

//====================================================
// Check: Can use this time.
//====================================================
stock ERROR:check_for_time(id)
{
	new int:cvar_delay = int:get_pcvar_num(gCvar[CVAR_START_DELAY]);

	// gametime - playertime = delay count.
	gNowTime = int:floatround(get_gametime()) - lm_get_user_delay_count(id);

	// check.
	if(gNowTime >= cvar_delay)
		return ERROR:NONE;

	return ERROR:DELAY_TIME;
}

//====================================================
// Check: Can use this Team.
//====================================================
stock bool:check_for_team(id)
{
	new arg[4];
	new CsTeams:team;

	// Get Cvar
	get_pcvar_string(gCvar[CVAR_CBT], arg, charsmax(arg));

	// Terrorist
#if defined BIOHAZARD_SUPPORT
	if(equali(arg, "Z")  || equali(arg, "Zombie"))
#else
	if(equali(arg, "TR") || equali(arg, "T"))
#endif
		team = CS_TEAM_T;
	else
	// Counter-Terrorist
#if defined BIOHAZARD_SUPPORT
	if(equali(arg, "H") || equali(arg, "Human"))
#else
	if(equali(arg, "CT"))
#endif
		team = CS_TEAM_CT;
	else
	// All team.
#if defined BIOHAZARD_SUPPORT
	if(equali(arg, "ZH") || equali(arg, "HZ") || equali(arg, "ALL"))
#else
	if(equali(arg, "ALL"))
#endif
		team = CS_TEAM_UNASSIGNED;
	else
		team = CS_TEAM_UNASSIGNED;

	// Cvar setting equal your team? Not.
	if(team != CS_TEAM_UNASSIGNED && team != cs_get_user_team(id))
		return false;

	return true;
}

//====================================================
// Check: Can buy.
//====================================================
stock ERROR:check_for_buy(id)
{
	new int:cvar_buymode= int:get_pcvar_num(gCvar[CVAR_BUY_MODE]);
	new int:cvar_maxhave= int:get_pcvar_num(gCvar[CVAR_MAX_HAVE]);
	new cvar_cost		= 	  get_pcvar_num(gCvar[CVAR_COST]);
	new cvar_buyzone	=	  get_pcvar_num(gCvar[CVAR_BUY_ZONE]);

	// Buy mode ON?
	if (cvar_buymode)
	{
		// Can this team buying?
		if (!check_for_team(id))
#if defined ZP_SUPPORT || defined BIOHAZARD_SUPPORT
			return ERROR:CANT_BUY_TEAM_Z;
#else
			return ERROR:CANT_BUY_TEAM;
#endif
		// Have Max?
		if (lm_get_user_have_mine(id) >= cvar_maxhave)
			return ERROR:HAVE_MAX;

		// buyzone area?
		if (cvar_buyzone && !cs_get_user_buyzone(id))
			return ERROR:NOT_BUYZONE;

		// Have money?
		if (cs_get_user_money(id) < cvar_cost)
			return ERROR:NO_MONEY;


	} else {
		return ERROR:CANT_BUY;
	}

	return ERROR:NONE;
}

//====================================================
// Check: Max Deploy.
//====================================================
stock ERROR:check_for_max_deploy(id)
{
	new int:cvar_maxhave = int:get_pcvar_num(gCvar[CVAR_MAX_HAVE]);
	new int:cvar_teammax = int:get_pcvar_num(gCvar[CVAR_TEAM_MAX]);

	// Max deployed per player.
	if (lm_get_user_mine_deployed(id) >= cvar_maxhave)
		return ERROR:MAXIMUM_DEPLOYED;

	// Max deployed per team.
	new int:team_count = lm_get_team_deployed_count(id);

	if(team_count >= cvar_teammax || team_count >= int:(MAX_LASER_ENTITY / 2))
		return ERROR:MANY_PPL;

	return ERROR:NONE;
}

//====================================================
// Show Chat area Messages
//====================================================
stock show_error_message(id, ERROR:err_num)
{
	switch(ERROR:err_num)
	{
		case NOT_ACTIVE:		cp_not_active(id);
		case NOT_ACCESS:		cp_not_access(id);
		case DONT_HAVE:			cp_dont_have(id);
		case CANT_BUY_TEAM:		cp_cant_buy_team(id);
		case CANT_BUY_TEAM_Z:	cp_cant_buy_zombie(id);
		case CANT_BUY:			cp_cant_buy(id);
		case HAVE_MAX:			cp_have_max(id);
		case NO_MONEY:			cp_no_money(id);
		case MAXIMUM_DEPLOYED:	cp_maximum_deployed(id);
		case MANY_PPL:			cp_many_ppl(id);
		case DELAY_TIME:		cp_delay_time(id);
		case MUST_WALL:			cp_must_wall(id);
		case NOT_IMPLEMENT:		cp_sorry(id);
		case NOT_BUYZONE:		cp_buyzone(id);
		case NO_ROUND:			cp_noround(id);
	}
}

//====================================================
// Check: On the wall.
//====================================================
stock ERROR:check_for_onwall(id)
{
	new Float:vTraceEnd[3];
	new Float:vOrigin[3];

	// Get potision.
	pev(id, pev_origin, vOrigin);
	
	// Get wall position.
	velocity_by_aim(id, 128, vTraceEnd);
	xs_vec_add(vTraceEnd, vOrigin, vTraceEnd);

    // create the trace handle.
	new trace = create_tr2();
	new Float:fFraction = 0.0;
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, IGNORE_MONSTERS, id, trace);
	{
    	get_tr2( trace, TR_flFraction, fFraction );
    }
    // free the trace handle.
	free_tr2(trace);

	// We hit something!
	if ( fFraction < 1.0 )
		return ERROR:NONE;

	return ERROR:MUST_WALL;
}

//====================================================
// Check: Round Started
//====================================================
#if defined BIOHAZARD_SUPPORT
stock ERROR:check_round_started()
{
	if (get_pcvar_num(gCvar[CVAR_NOROUND]))
	{
		if(!game_started())
			return ERROR:NO_ROUND;
	}
	return ERROR:NONE;
}
#endif
//====================================================
// Check: Lasermine Deploy.
//====================================================
stock bool:check_for_deploy(id)
{
	// Check common.
	new ERROR:error = check_for_common(id);
	if (error)
	{
		show_error_message(id, error);
		return false;
	}

#if defined BIOHAZARD_SUPPORT
	// Check Started Round.
	error = check_round_started();
	if(error)
	{
		show_error_message(id, error);
		return false;
	}	
#endif
	// Have mine? (use buy system)
	if (get_pcvar_num(gCvar[CVAR_BUY_MODE]) != 0)
	if (lm_get_user_have_mine(id) <= int:0) 
	{
		show_error_message(id, ERROR:DONT_HAVE);
		return false;
	}

	// Max deployed?
	error = check_for_max_deploy(id);
	if (error) 
	{
		show_error_message(id, error);
		return false;
	}
	
	// On the wall?
	error = check_for_onwall(id);
	if (error) 
	{
		show_error_message(id, error);
		return false;
	}

	return true;
}

//====================================================
// Mine Glowing
//====================================================
stock mine_glowing(iEnt)
{
	new Float:tcolor[3];
	new sRGB	[13];
	new sColor	[4];
	new sRGBLen 	= charsmax(sRGB);
	new sColorLen	= charsmax(sColor);
	new CsTeams:teamid = lm_get_laser_team(iEnt);

	new i = 0, n = 0, iPos = 0;

	// Glow mode.
	if (get_pcvar_num(gCvar[CVAR_MINE_GLOW]) != 0)
	{
		// Color setting.
		if (get_pcvar_num(gCvar[CVAR_MINE_GLOW_MODE]) == 0)
		{
			// Team color.
			switch (teamid)
			{
				case CS_TEAM_T:
					get_pcvar_string(gCvar[CVAR_MINE_GLOW_TR], sRGB, sRGBLen);
				case CS_TEAM_CT:
					get_pcvar_string(gCvar[CVAR_MINE_GLOW_CT], sRGB, sRGBLen);
				default:
					formatex(sRGB, sRGBLen, "0,255,0");
			} 
		}
		else
		{
			formatex(sRGB, sRGBLen, "0,255,0");
		}

		formatex(sRGB, sRGBLen, "%s%s", sRGB, ",");
		while(n < sizeof(tcolor))
		{
			i = split_string(sRGB[iPos += i], ",", sColor, sColorLen);
			tcolor[n++] = float(str_to_num(sColor));
		}
		lm_set_glow_rendering(iEnt, kRenderFxGlowShell, tcolor, kRenderNormal, 5);
	}
}

//====================================================
// ShowInfo Hud Message
//====================================================
public MinesShowInfo(Float:vStart[3], Float:vEnd[3], Conditions, id, iTrace)
{ 
	static iHit, szName[MAX_NAME_LENGTH], iOwner, health;
	static hudMsg[64];
	iHit = get_tr2(iTrace, TR_pHit);

	if (pev_valid(iHit))
	{
		if (lm_is_user_alive(iHit))
		{
			szName = lm_get_entity_class_name(iHit);

			if (equali(szName, ENT_CLASS_LASER))
			{
				iOwner = pev(iHit, LASERMINE_OWNER);
				health = floatround(lm_get_user_health(iHit));

				get_user_name(iOwner, szName, charsmax(szName));
				formatex(hudMsg, charsmax(hudMsg), "%L", id, LANG_KEY[MINE_HUD], szName, health, get_pcvar_num(gCvar[CVAR_MINE_HEALTH]));

				// set_hudmessage(red = 200, green = 100, blue = 0, Float:x = -1.0, Float:y = 0.35, effects = 0, Float:fxtime = 6.0, Float:holdtime = 12.0, Float:fadeintime = 0.1, Float:fadeouttime = 0.2, channel = -1)
				set_hudmessage(50, 100, 150, -1.0, 0.60, 0, 6.0, 0.4, 0.0, 0.0, -1);
				show_hudmessage(id, hudMsg);
			}
		}
    }

	return FMRES_IGNORED;
}

public MinesBreaked(victim, inflictor, attacker, Float:f_Damage, bit_Damage)
{
	new entityName[MAX_NAME_LENGTH];
	entityName = lm_get_entity_class_name(victim);

    // is this lasermine? no.
	if (!equali(entityName, ENT_CLASS_LASER))
		return HAM_IGNORED;

	if (get_pcvar_num(gCvar[CVAR_MINE_GLOW_MODE]) == 2)
		IndicatorGlow(victim);

#if defined ZP_SUPPORT
	zp_mines_breaked(attacker, victim);
#endif
    return HAM_IGNORED;
}

//====================================================
// Admin: Remove Player Lasermine
//====================================================
public admin_remove_laser(id, level, cid) 
{ 
	if (!cmd_access(id, level, cid, 2)) 
		return PLUGIN_HANDLED;

	new arg[32];
	read_argv(1, arg, 31);
	
	new player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF);

	if (!player)
		return PLUGIN_HANDLED;

	delete_task(player); 
	lm_remove_all_entity(player, ENT_CLASS_LASER);

	new namea[MAX_NAME_LENGTH],namep[MAX_NAME_LENGTH]; 
	get_user_name(id, namea, charsmax(namea));
	get_user_name(player, namep, charsmax(namep));
	cp_all_remove(0, namea, namep);

	return PLUGIN_HANDLED; 
} 

//====================================================
// Admin: Give Player Lasermine
//====================================================
public admin_give_laser(id, level, cid) 
{ 
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	new arg[32];
	read_argv(1, arg, 31);
	
	new player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF);
	
	if (!player)
		return PLUGIN_HANDLED;

	delete_task(player);
	set_start_ammo(player);

	new namea[MAX_NAME_LENGTH], namep[MAX_NAME_LENGTH]; 
	get_user_name(id, namea, charsmax(namea)); 
	get_user_name(player, namep, charsmax(namep)); 
	cp_gave(0, namea, namep);
	return PLUGIN_HANDLED; 
} 

public CheckSpectator() 
{
	new id, szTeam[2];
	id = read_data(1);
	read_data(2, szTeam, charsmax(szTeam));

	if(lm_get_user_mine_deployed(id) > int:0) 
	{
		if (szTeam[0] == 'U' || szTeam[0] == 'S')
		{
			delete_task(id);
			lm_remove_all_entity(id, ENT_CLASS_LASER);
			new namep[MAX_NAME_LENGTH];
			get_user_name(id, namep, charsmax(namep));
			cp_remove_spec(0, namep);
		} 
     } 
}

//====================================================
// Play sound.
//====================================================
stock lm_play_sound(iEnt, iSoundType)
{
	switch (iSoundType)
	{
		case SOUND_POWERUP:
		{
			emit_sound(iEnt, CHAN_VOICE, ENT_SOUNDS[DEPLOY], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			emit_sound(iEnt, CHAN_BODY , ENT_SOUNDS[CHARGE], 0.2, ATTN_NORM, 0, PITCH_NORM);
		}
		case SOUND_ACTIVATE:
		{
			emit_sound(iEnt, CHAN_VOICE, ENT_SOUNDS[ACTIVATE], 0.5, ATTN_NORM, 1, 75);
		}
		case SOUND_STOP:
		{
			emit_sound(iEnt, CHAN_BODY , ENT_SOUNDS[CHARGE], 0.2, ATTN_NORM, SND_STOP, PITCH_NORM);
			emit_sound(iEnt, CHAN_VOICE, ENT_SOUNDS[ACTIVATE], 0.5, ATTN_NORM, SND_STOP, 75);
		}
		case SOUND_PICKUP:
		{
			emit_sound(iEnt, CHAN_ITEM, ENT_SOUNDS[PICKUP], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		case SOUND_HIT:
		{
			emit_sound(iEnt, CHAN_WEAPON, ENT_SOUNDS[LASER_HIT], 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		case SOUND_HIT_SHIELD:
		{
			emit_sound(iEnt, CHAN_VOICE, ENT_SOUNDS[SHIELD_HIT1 + random_num(0, 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}
}

stock ClearStack(Stack:handle)
{
	new Float:health;
	while (!IsStackEmpty(handle))
	{
		PopStackCell(handle, health);
	}
}

stock IndicatorGlow(iEnt)
{
	new Float:color[3]   = {0.0, 255.0, 0.0};
	new Float:max_health = get_pcvar_float(gCvar[CVAR_MINE_HEALTH]);
	new Float:cur_health = lm_get_user_health(iEnt);
	new Float:percent	 = cur_health / max_health;

	// Red
	if (percent <= 0.5)
		color[0] = 255.0;
	else
		color[0] = 255.0 * ((1.0 - percent) * 2.0);

	// Green
	if (percent >= 0.5)
		color[1] = 255.0;
	else
		color[1] = 255.0 * (percent * 2.0);

	lm_set_glow_rendering(iEnt, kRenderFxGlowShell, color, kRenderNormal, 5);
}

