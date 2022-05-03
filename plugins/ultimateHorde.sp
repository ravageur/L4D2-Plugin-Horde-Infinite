#include <clients>
#include <sourcemod>
#include <sdktools_functions>
#include <basecomm>

ConVar uh_delayBetweenHorde = null;
ConVar uh_resetConvars = null;
Handle uh_timer = null;

int delayActualNextHorde = -1;

/**
 * Declare this as a struct in your plugin to expose its information.
 */
public Plugin myinfo = 
{
    name = "Ultimate horde",
    description = "This plugin will make spawn the ultimate horde !!!",
    author = "ravageur",
    version = "1.01",
    url = "https://github.com/ravageur/L4D2-Plugin-Horde-Infinite"
};

/**
 * This is the start of the execution this plugin.
 */
public void OnPluginStart()
{
    PrintToServer("Plugin ultimate horde ready to save you !");
    RegisterEvents();
    RegisterCvars();
    RegisterCommands();

    LoadTranslations("common.phrases");

    BypassRequirementCheat("director_panic_wave_pause_min", "1");
    BypassRequirementCheat("director_panic_wave_pause_max", "2");
    BypassRequirementCheat("director_relax_min_interval", "1");
    BypassRequirementCheat("director_relax_max_interval", "2");
    BypassRequirementCheat("director_relax_max_flow_travel", "1");
    BypassRequirementCheat("z_common_limit", "200");
}

/**
 * Allow to register some events.
 */
void RegisterEvents()
{
    HookEvent("round_start_pre_entity", Event_Round_Start);
    HookEvent("round_end", Event_Round_End);
}

/**
 * Allow to register all cvars related to this plugin.
 */
void RegisterCvars()
{
    uh_delayBetweenHorde = CreateConVar("uh_delayBetweenHorde", "60", "Default delay before to call the next horde. (If value below 1 then it's a horde infinite).", ADMFLAG_ROOT);
    uh_resetConvars = CreateConVar("uh_resetConvars", "1", "This convar is used to reset by default all the convars modified by this plugin.", ADMFLAG_ROOT);
}

void RegisterCommands()
{
    RegAdminCmd("uh_setNbCommonZombieLimit", ChangeNbCommonZombie, ADMFLAG_ROOT, "Allow to change the number of common zombies that can spawn in the game.");
}

/**
 * This is the end of the execution this plugin.
 */
public void OnPluginEnd()
{
    ResetConvarsBase();
    PrintToServer("Plugin ultimate horde disabled !");
}

/**
 * This method represent the command of "uh_setNbCommonZombieLimit".
 * 
 * @param client
 * @param args
 *
 * @return Action
 */
Action ChangeNbCommonZombie(int client = 0, int args)
{
    char nbZombieMax[255];
    
    GetCmdArgString(nbZombieMax, sizeof(nbZombieMax));

    if(args == 1 && !StrEqual(nbZombieMax, "0"))
    {
        BypassRequirementCheat("z_common_limit", nbZombieMax);
    }

    return Plugin_Handled;
}

/**
 * This timer is used to make spawn a horde every x time.
 * 
 * @param timer
 *
 * @return Action
 */
public Action Timer_SpawnHorde(Handle timer)
{
    if(delayActualNextHorde == 0)
    {
        BypassRequirementCheat("director_force_panic_event", "");
        delayActualNextHorde = uh_delayBetweenHorde.IntValue;
    }

    delayActualNextHorde--;

    return Plugin_Continue;
}

/**
 * This event is used to detect when the round start.
 * 
 * @param event
 * @param name
 * @param dontBroadcast
 */
public void Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
    if(uh_timer == null)
    {
        delayActualNextHorde = uh_delayBetweenHorde.IntValue;
        uh_timer = CreateTimer(1.0, Timer_SpawnHorde, INVALID_HANDLE, TIMER_REPEAT);
    }
}

/**
 * This event is used to stop this plugin when the round is finish.
 * 
 * @param event
 * @param name
 * @param dontBroadcast
 */
public void Event_Round_End(Event event, const char[] name, bool dontBroadcast)
{
    if(uh_timer != null)
    {
        CloseHandle(uh_timer);
        uh_timer = null;
        ResetConvarsBase();
    }
}

/**
 * This method is used to reset the options modified in game so that the players will not have to modify later if the player want to uninstall this plugin.
 */
void ResetConvarsBase()
{
    if(uh_resetConvars.IntValue == 1)
    {
        BypassRequirementCheat("director_panic_forever", "0");
        BypassRequirementCheat("director_panic_wave_pause_min", "5");
        BypassRequirementCheat("director_panic_wave_pause_max", "7");
        BypassRequirementCheat("director_relax_min_interval", "30");
        BypassRequirementCheat("director_relax_max_interval", "45");
        BypassRequirementCheat("director_relax_max_flow_travel", "3000");
        BypassRequirementCheat("z_common_limit", "30");
    }
}

/**
 * This method allow to do some things normal because sourcemod is not able to make admins or plugins to bypass the sv_cheats.
 * 
 * @param command
 * @param arguments
 */
void BypassRequirementCheat(char[] command, char[] arguments)
{
    if(!StrEqual(arguments, ""))
    {
        ConVar convarTest = FindConVar(command);
        new flags = GetConVarFlags(convarTest);
        flags &= ~FCVAR_CHEAT;

        SetConVarFlags(convarTest, flags);

        SetConVarString(convarTest, arguments);

        flags = GetConVarFlags(convarTest);
        flags |= FCVAR_CHEAT;
        SetConVarFlags(convarTest, flags); 
    }
    else
    {
        int idFakeClient = CreateFakeClient("I want to die.");
        new admindata = GetUserFlagBits(idFakeClient);
        SetUserFlagBits(idFakeClient, ADMFLAG_ROOT);
        new flags = GetCommandFlags(command);
        SetCommandFlags(command, flags & ~FCVAR_CHEAT);
        FakeClientCommand(idFakeClient, "%s", command);
        SetCommandFlags(command, flags);
        SetUserFlagBits(idFakeClient, admindata);
        KickClient(idFakeClient);
    }
}