#include <amxmodx>
#include <reapi>

public plugin_init()
{
	register_plugin("Steam Bonus", "1.1", "thurinven")

	RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn", 1)
}

public CBasePlayer_Spawn(id)
{
	if (is_user_alive(id) && is_user_steam(id))
	{
		rg_give_item(id, "weapon_flashbang", GT_REPLACE)
        rg_set_user_bpammo(id, CSW_FLASHBANG, 2)
		rg_give_item(id, "weapon_hegrenade")
		rg_set_user_armor(id, 100, ARMOR_VESTHELM)
		
		if (get_member(id, m_iTeam) == TEAM_CT)
		{
			rg_give_defusekit(id)
		}

        client_print_color(id, print_team_default, "^x04(Kniajevo CS) ^x03+ steam bonuses")
	}
}
