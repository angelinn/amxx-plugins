#include <amxmodx> 
#include <regex> 
#include <cstrike> 
#include <amxmisc>

#define PATTERN "270[0-9][0-9]"

new changed[32]

public plugin_init() 
{
    register_plugin("No IP in name", "1.0", "thurinven")
} 

public client_infochanged(id) 
{ 
    if (changed[id] == 1)
        return
 
    changed[id] = 1
    new name[33]
    get_user_info(id, "name", name, charsmax(name))

    new pars[33]
    pars[0] = id
    copy(pars[1], 32, name)
    
    set_task(10.0, "rename_if_ip", _, pars, sizeof(pars))
}

public client_disconnected(id) 
{
    changed[id] = 0
} 

public kick_if_spectator(pars[], task_id) 
{
    new id = pars[0]
    if (!is_user_connected(id))
        return 

    new name[33]
    copy(name, 32, pars[1])

    new CsTeams:team = cs_get_user_team(id)
    if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
    {
        server_cmd("kick ^"%s^" Your name contains illegal characters. Please rename.", name)
        server_exec() 
    } 
}

public rename_if_ip(pars[], task_id) 
{ 
    new id = pars[0]
    new name[33]
    copy(name, 32, pars[1])

    new returnValue, error[64]
    new Regex:handle = regex_match(name, PATTERN, returnValue, error, charsmax(error)) 

    if (handle >= 0)
        regex_free(handle)

    if (returnValue == REGEX_OK)
    { 
        server_cmd("amx_nick ^"%s^" Player", name)
        client_print_color(id, print_team_default, "^x04[Kniajevo CS] ^x03Imeto vi beshe vremenno smeneno, zashtoto sudurja IP adres. Molia smeneto go ot nastroiki. EN: Please change your name.")

        server_print("[No IP in name] %s got name changed.", name) 

        new ip[64]
        get_user_ip(id, ip, 64)
        log_amx("%s - %s got name changed.", name, ip)
 
        set_task(10.0, "kick_if_spectator", _, pars, 33 + 1)
    } 
    else if (returnValue == REGEX_PATTERN_FAIL || returnValue == REGEX_MATCH_FAIL)
    {
        server_print("[No IP in name Regex match %d, %s ", returnValue, error)
    }
} 
