
#define PLUGIN_NAME "de_rats Weapon Remover"
#define PLUGIN_VERSION "1.0.0"
#define AUTHOR_NAME "thurinven"

#define TARGET_MAP "de_rats_1337"
#define PLUGIN_TAG "WeaponRemover"
#define TARGET_ENTITY "armoury_entity"

#include <amxmodx>
#include <engine>

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, AUTHOR_NAME)
    register_cvar("weapon_remover", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_EXTDLL | FCVAR_UNLOGGED | FCVAR_SPONLY)
}

public plugin_cfg()
{    
    new mapName[64]
    get_mapname(mapName, sizeof(mapName))

    if (equali(mapName, TARGET_MAP))
    {
        server_print("[%s] Current map is %s, trying to remove awp...", PLUGIN_TAG, mapName)

        new awp_entity_id = find_ent_by_class(-1, TARGET_ENTITY)
        if (awp_entity_id)
        {
            if (remove_entity(awp_entity_id))
                server_print("[%s] Removed armoury_entity with index: %i", PLUGIN_TAG, awp_entity_id)
            else
                server_print("[%s] Could not remove armoury_entity with index: %i", PLUGIN_TAG, awp_entity_id)
        }
    }
}
