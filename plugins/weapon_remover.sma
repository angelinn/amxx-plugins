
#define PLUGIN_NAME "de_rats Weapon Remover"
#define PLUGIN_VERSION "1.0.1"
#define AUTHOR_NAME "thurinven"

#define TARGET_MAP "de_rats_1337"
#define PLUGIN_TAG "WeaponRemover"
#define TARGET_ENTITY "armoury_entity"

#include <amxmodx>
#include <engine>
#include <cstrike>

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, AUTHOR_NAME)
    register_cvar("weapon_remover", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_EXTDLL | FCVAR_UNLOGGED | FCVAR_SPONLY)
}

public plugin_cfg()
{    
    new map_name[64]
    get_map_name(map_name, sizeof(map_name))

    if (equali(map_name, TARGET_MAP))
    {
        server_print("[%s] Current map is %s, trying to remove awp...", PLUGIN_TAG, map_name)

        new entity_id = find_ent_by_class(-1, TARGET_ENTITY)
        if (entity_id)
        {
            new type = cs_get_armoury_type(entity_id)
            
            if (type == CSW_AWP && remove_entity(entity_id))
                server_print("[%s] Removed CSW_AWP with index: %i", PLUGIN_TAG, entity_id)
            else
                server_print("[%s] Entity not CSW_AWP or can't remove", PLUGIN_TAG, entity_id)
        }
        else
            server_print("[%s] Could not find awp entity", PLUGIN_TAG, entity_id)
    }
}
