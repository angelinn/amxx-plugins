#include <amxmodx>
#include <reapi>

new playersTurn[33]
new bool: hasBombSite

public plugin_init()
{
	register_plugin("Steam Bonus", "1.6", "thurinven")

	RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn", 1)
    if (rg_find_ent_by_class(-1, "func_bomb_target") > 0 || rg_find_ent_by_class(-1, "info_bomb_target") > 0)
        hasBombSite = true
}

public CBasePlayer_Spawn(id)
{
	if (is_user_alive(id) && is_user_steam(id))
	{
        if (playersTurn[id] == 0)
        {
            rg_give_item(id, "weapon_flashbang", GT_REPLACE)
            rg_set_user_bpammo(id, CSW_FLASHBANG, 2)
            rg_give_item(id, "weapon_hegrenade")

            ++playersTurn[id]
            
            client_print_color(id, print_team_default, "^x04[Kniajevo CS] ^x03+ steam bonuses - grenades")
        }
        else if (playersTurn[id] == 1)
        {
            rg_set_user_armor(id, 100, ARMOR_VESTHELM)
            ++playersTurn[id]
            
            client_print_color(id, print_team_default, "^x04[Kniajevo CS] ^x03+ steam bonuses - armor")
        }
        else if (playersTurn[id] == 2)
        {
            rg_add_account(id, 1000)
            playersTurn[id] = 0

            client_print_color(id, print_team_default, "^x04[Kniajevo CS] ^x03+ steam bonuses - 1000$")
        }

		if (hasBombSite && get_member(id, m_iTeam) == TEAM_CT)
		{
			rg_give_defusekit(id)
		}
	}
}
