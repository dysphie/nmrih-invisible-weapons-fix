#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sdkhooks>

#define EF_BONEMERGE_FASTCULL 128

bool isWeapon[2049];
bool lateloaded;

public Plugin myinfo = 
{
	name        = "[NMRiH] Invisible Weapons Fix",
	author      = "Dysphie",
	description = "Fixes dropped weapons becoming invisible",
	version     = "1.0.0",
	url         = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	lateloaded = late;
	return APLRes_Success;
}

public void OnMapStart()
{
	if (lateloaded)
	{
		int maxEnts = GetMaxEntities();
		for (int i = MaxClients+1; i < maxEnts; i++)
			if (IsValidWeapon(i))
				isWeapon[i] = true;
	}

	CreateTimer(1.5, FixInvisibleWeapons, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (IsValidWeapon(entity))
		isWeapon[entity] = true;
}

public void OnEntityDestroyed(int entity)
{
	if (IsValidWeapon(entity))
		isWeapon[entity] = false;
}

public Action FixInvisibleWeapons(Handle timer)
{
	int effects;
	for (int e; e < sizeof(isWeapon); e++)
	{
		// m_iState 0 means the weapon isn't equipped
		if (isWeapon[e] && !GetEntProp(e, Prop_Data, "m_iState"))
		{
			// I don't know why, but flipping this flag 
			// causes the client to correct the rendering...
			effects = GetEntProp(e, Prop_Send, "m_fEffects");
			if (effects & EF_BONEMERGE_FASTCULL)
				SetEntProp(e, Prop_Send, "m_fEffects", effects & ~EF_BONEMERGE_FASTCULL);
			else
				SetEntProp(e, Prop_Send, "m_fEffects", effects | EF_BONEMERGE_FASTCULL);
		}
	}
}

bool IsValidWeapon(int entity)
{
	return IsValidEdict(entity) && HasEntProp(entity, Prop_Data, "m_bIsInIronsights");
}