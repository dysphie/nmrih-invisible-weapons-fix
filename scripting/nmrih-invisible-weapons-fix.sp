#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#define EF_BONEMERGE_FASTCULL 128
#define MAX_WEAPON_CLASSNAME  21
#define WEAPON_NOT_CARRIED    0

bool g_IsWeapon[2049];
bool g_LateLoaded;

public Plugin myinfo =
{
	name        = "[NMRiH] Invisible Weapons Fix",
	author      = "Dysphie",
	description = "Fixes dropped weapons becoming invisible",
	version     = "1.1.0",
	url         = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_LateLoaded = late;
	return APLRes_Success;
}

public void OnMapStart()
{
	CreateTimer(2.5, FixInvisibleWeapons, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	if (!g_LateLoaded) {
		return;
	}

	int  maxEnts = GetMaxEntities();
	char classname[MAX_WEAPON_CLASSNAME];
	for (int entity = MaxClients + 1; entity < maxEnts; entity++)
	{
		if (entity > 0) 
		{
			GetEntityClassname(entity, classname, sizeof(classname));
			g_IsWeapon[entity] = IsValidWeapon(classname);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity > 0 && IsValidWeapon(classname)) {
		g_IsWeapon[entity] = true;
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity > 0) {
		g_IsWeapon[entity] = false;
	}
}

Action FixInvisibleWeapons(Handle timer)
{
	int effects;

	for (int entity; entity < sizeof(g_IsWeapon); entity++)
	{
		if (g_IsWeapon[entity] && GetEntProp(entity, Prop_Data, "m_iState") == WEAPON_NOT_CARRIED)
		{
			// Flipping this flag forces a client-side re-render which corrects the perceived weapon origin
			effects = GetEntProp(entity, Prop_Send, "m_fEffects");
			if (effects & EF_BONEMERGE_FASTCULL)
			{
				SetEntProp(entity, Prop_Send, "m_fEffects", effects & ~EF_BONEMERGE_FASTCULL);
			}
			else
			{
				SetEntProp(entity, Prop_Send, "m_fEffects", effects | EF_BONEMERGE_FASTCULL);
			}
		}
	}

	return Plugin_Continue;
}

// This looks gross but it's actually faster than HasEntProp and StringMap!
bool IsValidWeapon(const char[] classname)
{
	// All entities with these prefixes are weapons
	static const char PREFIX_FIREARM[] = "fa_";
	static const char PREFIX_MELEE[]   = "me_";
	static const char PREFIX_BOW[]     = "bow_";
	static const char PREFIX_NADE[]    = "exp_";
	static const char PREFIX_TOOL[]    = "tool_";

	if (!strncmp(classname, PREFIX_FIREARM, sizeof(PREFIX_FIREARM) - 1) || 
		!strncmp(classname, PREFIX_MELEE, sizeof(PREFIX_MELEE) - 1) || 
		!strncmp(classname, PREFIX_BOW, sizeof(PREFIX_BOW) - 1) || 
		!strncmp(classname, PREFIX_NADE, sizeof(PREFIX_NADE) - 1) || 
		!strncmp(classname, PREFIX_TOOL, sizeof(PREFIX_TOOL) - 1))
	{
		return true;
	}

	// But not all "item_" entities are weapons
	return StrEqual(classname, "item_maglite") || StrEqual(classname, "item_walkietalkie") || 
		StrEqual(classname, "item_pills") || StrEqual(classname, "item_first_aid") || 
		StrEqual(classname, "item_gene_therapy") || StrEqual(classname, "item_bandages");
}