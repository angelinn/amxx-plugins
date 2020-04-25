#include <amxmodx>
#include <reapi>
#include <WPMGPrintChatColor>

new cvar_timestart
new cvar_timeend
new happyhourStart
new happyhourEnd
new hourStr[3]
new currentHour

new hudObject

const showMessageTaskID = 1234

new bool: isHappyHourStarted
new bool: hasBombSite

public plugin_init()
{
    register_plugin("Happy Hour ReAPI", "1.1", "thurinven")
    
    cvar_timestart = register_cvar("happyhour_start", "18")
    cvar_timeend = register_cvar("happyhour_end", "23")

    hudObject = CreateHudSyncObj()

    RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn", 1)
    if (rg_find_ent_by_class(-1, "func_bomb_target") > 0 || rg_find_ent_by_class(-1, "info_bomb_target") > 0)
        hasBombSite = true
}

public OnPlayerSpawn(id)
{
    if (IsHappyHour())
    {
        if (!isHappyHourStarted)
        {
            server_print("HappyHour - Starting happy hour from %d to %d", happyhourStart, happyhourEnd)
            
            isHappyHourStarted = true
            
            set_task(1.0, "ShowMessage", showMessageTaskID, _, _, "b")
            PrintChatColor(0, PRINT_COLOR_PLAYERTEAM,"!g[HappyHour] !tHappy Hour !g%i:00 do !g%i:00 !tzapochna !!! Zabavlqvaite se ^1!", happyhourStart, happyhourEnd)
        }
    }
    else
    {
        if (isHappyHourStarted)
            remove_task(showMessageTaskID)
            
        isHappyHourStarted = false
    }
    
    if (isHappyHourStarted && is_user_connected(id) && is_user_alive(id))
    {
        PrintChatColor(id, PRINT_COLOR_PLAYERTEAM,"!g[HappyHour] !tHappy hour e aktiven! Poluchavate bonus !gdeagle !ti !ggranati!")

        rg_give_item(id, "weapon_flashbang", GT_REPLACE)
        rg_set_user_bpammo(id, CSW_FLASHBANG, 2)
        rg_give_item(id, "weapon_hegrenade")
        rg_give_item(id, "weapon_deagle", GT_REPLACE)        
        rg_set_user_bpammo(id, CSW_DEAGLE, 35)

        if (hasBombSite && get_member(id, m_iTeam) == TEAM_CT)
		{
			rg_give_defusekit(id)
		}
    }     
}

public ShowMessage()
{
    set_hudmessage(255, 255, 255, 0.01, 0.21, 1, 2.0, 1.0, 0.5, 1.0, -1)
    ShowSyncHudMsg(0, hudObject, "Happy Hour: %d:00 do %d:00 ( ON )", happyhourStart, happyhourEnd)
}

IsHappyHour()
{
    get_time("%H", hourStr, 2)
    
    happyhourStart = get_pcvar_num(cvar_timestart)
    happyhourEnd = get_pcvar_num(cvar_timeend)
    
    currentHour = str_to_num(hourStr)
    
    return (happyhourStart < happyhourEnd ? 
                (happyhourStart <= currentHour && currentHour < happyhourEnd) : 
                (happyhourStart <= currentHour || currentHour <= happyhourEnd))

}
