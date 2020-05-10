#include <amxmodx>
#include <cstrike>

#define MAX_REWARDS 10

new rewards[MAX_REWARDS] = { 0, 0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000 }
new roundsInARow
new pendingTeam

new cvarPluginOn

public plugin_init()
{
    register_plugin("Team Advantage", "1.0", "thurinven")

    cvarPluginOn = register_cvar("teamadvantage_on", "1")

    register_event("HLTV", "OnNewRound", "a", "1=0", "2=0")
    register_event("SendAudio", "OnRoundEnd", "a", "2=%!MRAD_terwin", "2=%!MRAD_ctwin", "2=%!MRAD_rounddraw")
}

public OnNewRound()
{
    new reward = roundsInARow >= MAX_REWARDS ? rewards[MAX_REWARDS - 1] : rewards[roundsInARow]
    if (reward < 0)
        return

    new players[MAX_PLAYERS]
    new playersCount

    get_players(players, playersCount, "e", pendingTeam == CS_TEAM_CT ? "CT" : "TERRORIST")
    for (new i = 0; i < playersCount; ++i)
    {
        cs_set_user_money(players[i], cs_get_user_money(players[i]) + reward)
    }
}

public OnRoundEnd()
{
    if (!get_pcvar_num(cvarPluginOn))
    {
        pendingTeam = -1
        roundsInARow = 0

        return
    }

    new parameters[32]
    read_data(2, parameters, charsmax(parameters))

    new advantageTeam = parameters[7] == 't' ? CS_TEAM_CT : CS_TEAM_T
    if (pendingTeam == advantageTeam)
        ++roundsInARow
    else
    {
        pendingTeam = advantageTeam
        roundsInARow = 1
    }

    new reward = roundsInARow >= MAX_REWARDS ? rewards[MAX_REWARDS - 1] : rewards[roundsInARow]
    if (reward > 0)
    {
        //             "^x04[Kniajevo CS] ^x01Igrachite ot otbora na ^x03%s ^x01shte poluchat po ^x04%d$ ^x01za ^x04%d ^x01zagubi podred",
        client_print_color(0, 0,
            "^x04[Kniajevo CS] ^x01Players from the ^x03%s ^x01team will receive ^x04%d$^x01 for losing ^x04%d ^x01times in a row",
            pendingTeam == CS_TEAM_CT ? "Counter-Terrorists" : "Terrorists", 
            reward,
            roundsInARow
        )
    }
}
