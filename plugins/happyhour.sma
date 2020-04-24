#include <amxmodx>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <fakemeta>
#include <WPMGPrintChatColor>

new cvar_timestart
new cvar_timeend
new happyhourStart
new happyhourEnd
new hourStr[3]
new currentHour

new hudObject

new const m_rgpPlayerItems_CBasePlayer[6] = {367,368,...}
const m_pActiveItem = 373
const showMessageTaskID = 1234

new bool: isHappyHourStarted
new bool: hasBombSite

public plugin_init()
{
    register_plugin("Happy Hour", "1.1", "thurinven")
    
    cvar_timestart = register_cvar("happyhour_start", "18")
    cvar_timeend = register_cvar("happyhour_end", "23")

    hudObject = CreateHudSyncObj()

    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", true)
    if (cs_find_ent_by_class(-1, "func_bomb_target") > 0 || cs_find_ent_by_class(-1, "info_bomb_target") > 0)
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

        new weapons = pev(id, pev_weapons);
        if (~weapons & CSW_FLASHBANG)
        {
            give_item(id, "weapon_flashbang")
        }
        cs_set_user_bpammo(id, CSW_FLASHBANG, 2)

        if (~weapons & CSW_HEGRENADE)
        {
            give_item(id, "weapon_hegrenade")
        }

        new gun = get_pdata_cbase(id, m_rgpPlayerItems_CBasePlayer[2]);
        
        if (gun > 0)
        {
            new iId = cs_get_weapon_id(gun);
            if (iId == CSW_DEAGLE)
            {
                cs_set_weapon_ammo(gun, 7);
            }
            else
            {
                ham_strip_user_weaponent(id, gun, iId, true);
                give_item(id, "weapon_deagle");
            }
        }
        
        cs_set_user_bpammo(id, CSW_DEAGLE, 35)

        if (hasBombSite && cs_get_user_team(id) == CS_TEAM_CT)
        {
            cs_set_user_defuse(id, 1)
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
                (happyhourStart <= currentHour && currentHour <= happyhourEnd) : 
                (happyhourStart <= currentHour || currentHour <= happyhourEnd))

}


ham_strip_user_weaponent(id, weaponEnt, iId=0, bool:bSwitchIfActive = true)
{
    // new d = get_pdata_cbase(id, m_pActiveItem)

    // if (bSwitchIfActive && d == weaponEnt)
    // {
    //     ExecuteHamB(Ham_Weapon_RetireWeapon, weaponEnt);
    // }

    if (ExecuteHamB(Ham_RemovePlayerItem, id, weaponEnt))
    {
        if (!iId)
        {
            iId = cs_get_weapon_id(weaponEnt);
        }
        user_has_weapon(id, iId, 0);
        ExecuteHamB(Ham_Item_Kill, weaponEnt);
        return 1;
    }
    return 0;
} 
