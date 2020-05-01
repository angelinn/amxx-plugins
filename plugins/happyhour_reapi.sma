#include <amxmodx>
#include <reapi>
#include <WPMGPrintChatColor>

#define VIP_FLAG ADMIN_LEVEL_A
#define SHOW_MESSAGE_TASK_ID 1234

#define REWARD_HE 1 
#define REWARD_FB 2
#define REWARD_DEAGLE 4
#define REWARD_ARMOR 8

new cvarTimeStart
new cvarTimeEnd
new cvarRewards
new cvarVip

new happyhourStart
new happyhourEnd

new hourStr[3]
new currentHour

new hudObject

new bool: isHappyHourStarted
new bool: hasBombSite

// happyhour_bonuses
// 1 - he_grenade
// 2 - flashbangs
// 4 - deagle
// 8 - armor

public plugin_init()
{
    register_plugin("Happy Hour ReAPI", "1.6", "thurinven")
    
    cvarTimeStart = register_cvar("happyhour_start", "18")
    cvarTimeEnd = register_cvar("happyhour_end", "23")
    cvarRewards = register_cvar("happyhour_rewards", "7")
    cvarVip = register_cvar("happyhour_include_vip", "1")

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
            
            set_task(1.0, "ShowMessage", SHOW_MESSAGE_TASK_ID, _, _, "b")
            PrintChatColor(0, PRINT_COLOR_PLAYERTEAM,"!g[HappyHour] !tHappy Hour !g%i:00 do !g%i:00 !tzapochna !!! Zabavlqvaite se ^1!", happyhourStart, happyhourEnd)
        }

        if (is_user_alive(id))
        {
            PrintChatColor(id, PRINT_COLOR_PLAYERTEAM,"!g[Kniajevo CS] !t+ happyhour bonuses")

            if (!get_pcvar_num(cvarVip) && get_user_flags(id) & VIP_FLAG)
                return

            new rewards = get_pcvar_num(cvarRewards)

            if (rewards & REWARD_DEAGLE)
            {
                rg_give_item(id, "weapon_deagle", GT_REPLACE)        
                rg_set_user_bpammo(id, CSW_DEAGLE, 35)
            }
            if (rewards & REWARD_FB)
            {
                rg_give_item(id, "weapon_flashbang", GT_REPLACE)
                rg_set_user_bpammo(id, CSW_FLASHBANG, 2)
            }
            if (rewards & REWARD_HE)
            {
                rg_give_item(id, "weapon_hegrenade")
            }
            if (rewards & REWARD_ARMOR)
            {
                rg_set_user_armor(id, 100, ARMOR_VESTHELM)
            }

            if (hasBombSite && get_member(id, m_iTeam) == TEAM_CT)
            {
                rg_give_defusekit(id)
            }
        }
    }
    else if (isHappyHourStarted)
    {
        remove_task(SHOW_MESSAGE_TASK_ID)
        isHappyHourStarted = false
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
    
    happyhourStart = get_pcvar_num(cvarTimeStart)
    happyhourEnd = get_pcvar_num(cvarTimeEnd)
    
    currentHour = str_to_num(hourStr)
    
    return (happyhourStart < happyhourEnd ? 
                (happyhourStart <= currentHour && currentHour < happyhourEnd) : 
                (happyhourStart <= currentHour || currentHour <= happyhourEnd))

}
