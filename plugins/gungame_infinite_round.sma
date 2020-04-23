
#define PLUGIN_NAME "GunGame Infinite Round"
#define PLUGIN_VERSION "1.1.0"
#define AUTHOR_NAME "thurinven"

#define PLUGIN_TAG "GunGameInfiniteRound"

#include <amxmodx>
#include <amxmisc>
#include <reapi>

new bool:isRestarting = false

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, AUTHOR_NAME)
    register_event("TextMsg", "OnTextMsgRestart", "a", "2&#Game_C", "2&#Game_w")
    register_event("HLTV", "OnHLTVNewRound", "a", "1=0", "2=0")

    if (!is_regamedll())
    {
        server_print("[%s] ReGameDLL is not available. It is required for the plugin to function.")
    }
}

public OnTextMsgRestart()
{
    isRestarting = true
} 

public OnHLTVNewRound() 
{
    if (isRestarting)
    {
        new isRoundInfinite = get_cvar_num("mp_round_infinite")
        if (!isRoundInfinite)
        {
            set_cvar_num("mp_round_infinite", 1)
            server_print("[%s] Setting mp_round_infinite to 1", PLUGIN_TAG)
        }

        isRestarting = false
    }
}
