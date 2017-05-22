#pragma semicolon 1
#pragma newdecls required

#include <cstrike>
#include <clientprefs>
#include <sdktools>
#include <lvl_ranks>

#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHOR "RoadSide Romeo"

int		g_iRank[MAXPLAYERS+1],
		g_iSkinsCT_Count,
		g_iSkinsCT_Level[128],
		g_iSkinsCT_Choose[MAXPLAYERS+1],
		g_iSkinsT_Count,
		g_iSkinsT_Level[128],
		g_iSkinsT_Choose[MAXPLAYERS+1];
char		g_sSkinsCT_Name[128][32],
		g_sSkinsCT_Model[128][192],
		g_sSkinsT_Name[128][32],
		g_sSkinsT_Model[128][192];
Handle	g_hSkinsCookie = null;

public Plugin myinfo = {name = "[LR] Module - Skins", author = PLUGIN_AUTHOR, version = PLUGIN_VERSION}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch(GetEngineVersion())
	{
		case Engine_CSGO, Engine_CSS: LogMessage("[%s Skins] Запущен успешно", PLUGIN_NAME);
		default: SetFailState("[%s Skins] Плагин работает только на CS:GO и CS:S", PLUGIN_NAME);
	}
}

public void OnPluginStart()
{
	LR_ModuleCount();
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
	g_hSkinsCookie = RegClientCookie("LR_Skins", "LR_Skins", CookieAccess_Private);
	LoadTranslations("levels_ranks_skins.phrases");
	
	for(int iClient = 1; iClient <= MaxClients; iClient++)
    {
		if(IsClientInGame(iClient))
		{
			if(AreClientCookiesCached(iClient))
			{
				OnClientCookiesCached(iClient);
			}
		}
	}	
}

public void OnMapStart() 
{
	char sPath[PLATFORM_MAX_PATH];
	Handle hBuffer = OpenFile("addons/sourcemod/configs/levels_ranks/downloadsskins.ini", "r");
	
	if(hBuffer == null)
    {
        SetFailState("Не удалось загрузить addons/sourcemod/configs/levels_ranks/downloadsskins.ini");
    }
	
	while(!IsEndOfFile(hBuffer) && ReadFileLine(hBuffer, sPath, 192))
    { 
        TrimString(sPath);
        if(IsCharAlpha(sPath[0]))
		{
			AddFileToDownloadsTable(sPath);
		}
    }

	delete hBuffer;

	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/skins.ini");
	KeyValues hLR_Skins = new KeyValues("LR_Skins");

	if(!hLR_Skins.ImportFromFile(sPath) || !hLR_Skins.GotoFirstSubKey())
	{
		SetFailState("[%s Skins] : фатальная ошибка - файл не найден (%s)", PLUGIN_NAME, sPath);
	}

	hLR_Skins.Rewind();

	if(hLR_Skins.JumpToKey("Skins_CT"))
	{
		g_iSkinsCT_Count = 0;
		hLR_Skins.GotoFirstSubKey();

		do
		{
			hLR_Skins.GetSectionName(g_sSkinsCT_Name[g_iSkinsCT_Count], sizeof(g_sSkinsCT_Name[]));
			hLR_Skins.GetString("skin", g_sSkinsCT_Model[g_iSkinsCT_Count], sizeof(g_sSkinsCT_Model[]));
			PrecacheModel(g_sSkinsCT_Model[g_iSkinsCT_Count], true);
			g_iSkinsCT_Level[g_iSkinsCT_Count] = hLR_Skins.GetNum("rank", 0);
			g_iSkinsCT_Count++;
		}
		while(hLR_Skins.GotoNextKey());
	}
	else SetFailState("[%s Skins] : фатальная ошибка - секция Skins_CT не найдена (%s)", PLUGIN_NAME, sPath);
	
	hLR_Skins.Rewind();

	if(hLR_Skins.JumpToKey("Skins_T"))
	{
		g_iSkinsT_Count = 0;
		hLR_Skins.GotoFirstSubKey();

		do
		{
			hLR_Skins.GetSectionName(g_sSkinsT_Name[g_iSkinsT_Count], sizeof(g_sSkinsT_Name[]));
			hLR_Skins.GetString("skin", g_sSkinsT_Model[g_iSkinsT_Count], sizeof(g_sSkinsT_Model[]));
			PrecacheModel(g_sSkinsT_Model[g_iSkinsT_Count], true);
			g_iSkinsT_Level[g_iSkinsT_Count] = hLR_Skins.GetNum("rank", 0);
			g_iSkinsT_Count++;
		}
		while(hLR_Skins.GotoNextKey());
	}
	else SetFailState("[%s Skins] : фатальная ошибка - секция Skins_T не найдена (%s)", PLUGIN_NAME, sPath);
	delete hLR_Skins;
}

public void PlayerSpawn(Handle hEvent, char[] sEvName, bool bDontBroadcast)
{	
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(IsValidClient(iClient) && CheckCompliance(iClient))
	{
		switch(GetClientTeam(iClient))
		{
			case CS_TEAM_CT:
			{
				if(-1 < g_iSkinsCT_Choose[iClient] < g_iSkinsCT_Count)
				{
					SetEntityModel(iClient, g_sSkinsCT_Model[g_iSkinsCT_Choose[iClient]]);
				}
			}
			
			case CS_TEAM_T:
			{
				if(-1 < g_iSkinsT_Choose[iClient] < g_iSkinsT_Count)
				{
					SetEntityModel(iClient, g_sSkinsT_Model[g_iSkinsT_Choose[iClient]]);
				}
			}
		}
	}
}

bool CheckCompliance(int iClient)
{
	g_iRank[iClient] = LR_GetClientRank(iClient);

	switch(GetClientTeam(iClient))
	{
		case CS_TEAM_CT:
		{
			for(int i = 0; i < g_iSkinsCT_Count; i++)
			{
				if(g_iSkinsCT_Choose[iClient] == i)
				{	
					if(g_iRank[iClient] < g_iSkinsCT_Level[i])
					{
						g_iSkinsCT_Choose[iClient] = -1;
					}
				}
			}
		}
		
		case CS_TEAM_T:
		{
			for(int i = 0; i < g_iSkinsT_Count; i++)
			{
				if(g_iSkinsT_Choose[iClient] == i)
				{	
					if(g_iRank[iClient] < g_iSkinsT_Level[i])
					{
						g_iSkinsT_Choose[iClient] = -1;
					}
				}
			}
		}
	}
	
	return true;
}

public void LR_OnMenuCreated(int iClient, int iRank, Menu& hMenu)
{
	if(iRank == 0)
	{
		char sText[64];
		SetGlobalTransTarget(iClient);
		switch(GetClientTeam(iClient))
		{
			case CS_TEAM_CT: FormatEx(sText, sizeof(sText), "%t (%i)", "Skins", g_iSkinsCT_Count);
			case CS_TEAM_T: FormatEx(sText, sizeof(sText), "%t (%i)", "Skins", g_iSkinsT_Count);
		}

		hMenu.AddItem("Skins", sText);
	}
}

public void LR_OnMenuItemSelected(int iClient, int iRank, const char[] sInfo)
{
	if(iRank == 0)
	{
		if(strcmp(sInfo, "Skins") == 0)
		{
			SkinsMenu(iClient);
		}
	}
}

public void SkinsMenu(int iClient)
{
	char sBuffer[16], sText[192];
	SetGlobalTransTarget(iClient);
	g_iRank[iClient] = LR_GetClientRank(iClient);
	Menu Mmenu = new Menu(SkinsMenuHandler);

	FormatEx(sText, sizeof(sText), "%t", "Skins");
	Mmenu.SetTitle("%s | %s\n ", PLUGIN_NAME, sText);
	
	switch(GetClientTeam(iClient))
	{
		case CS_TEAM_CT:
		{
			FormatEx(sBuffer, sizeof(sBuffer), "-1;%i", CS_TEAM_CT);
			FormatEx(sText, sizeof(sText), "%t", "SkinsUsual");
			Mmenu.AddItem(sBuffer, sText);

			for(int i = 0; i < g_iSkinsCT_Count; i++)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "%i;%i", i, CS_TEAM_CT);
				
				if(g_iRank[iClient] >= g_iSkinsCT_Level[i])
				{
					FormatEx(sText, sizeof(sText), "%s", g_sSkinsCT_Name[i]);
					Mmenu.AddItem(sBuffer, sText);
				}
				else
				{
					FormatEx(sText, sizeof(sText), "%s", g_sSkinsCT_Name[i]);		
					Mmenu.AddItem(sBuffer, sText, ITEMDRAW_DISABLED);
				}
			}
		}

		case CS_TEAM_T:
		{
			FormatEx(sBuffer, sizeof(sBuffer), "-1;%i", CS_TEAM_T);
			FormatEx(sText, sizeof(sText), "%t", "SkinsUsual");
			Mmenu.AddItem(sBuffer, sText);

			for(int i = 0; i < g_iSkinsT_Count; i++)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "%i;%i", i, CS_TEAM_T);

				if(g_iRank[iClient] >= g_iSkinsT_Level[i])
				{
					FormatEx(sText, sizeof(sText), "%s", g_sSkinsT_Name[i]);
					Mmenu.AddItem(sBuffer, sText);
				}
				else
				{
					FormatEx(sText, sizeof(sText), "%s", g_sSkinsT_Name[i]);		
					Mmenu.AddItem(sBuffer, sText, ITEMDRAW_DISABLED);
				}
			}
		}
	}

	Mmenu.ExitButton = true;
	Mmenu.Display(iClient, MENU_TIME_FOREVER);
}

public int SkinsMenuHandler(Menu Mmenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_End: delete Mmenu;
		case MenuAction_Select:
		{
			char sBuffer[16], sBufferAfter[2][4];
			Mmenu.GetItem(iSlot, sBuffer, sizeof(sBuffer));
			ExplodeString(sBuffer, ";", sBufferAfter, 2, 4);
			int iTeam = StringToInt(sBufferAfter[1]);
			
			if(iTeam == GetClientTeam(iClient))
			{
				switch(iTeam)
				{
					case CS_TEAM_CT:
					{
						g_iSkinsCT_Choose[iClient] = StringToInt(sBufferAfter[0]);

						if(IsPlayerAlive(iClient))
						{
							if(-1 < g_iSkinsCT_Choose[iClient] < g_iSkinsCT_Count)
							{
								SetEntityModel(iClient, g_sSkinsCT_Model[g_iSkinsCT_Choose[iClient]]);
							}
						}
					}
					
					case CS_TEAM_T:
					{
						g_iSkinsT_Choose[iClient] = StringToInt(sBufferAfter[0]);

						if(IsPlayerAlive(iClient))
						{
							if(-1 < g_iSkinsT_Choose[iClient] < g_iSkinsT_Count)
							{
								SetEntityModel(iClient, g_sSkinsT_Model[g_iSkinsT_Choose[iClient]]);
							}
						}
					}
				}
			}
			else
			{
				LR_PrintToChat(iClient, "%t", "AnotherTeam");
			}
		}
	}
}

public void OnClientCookiesCached(int iClient)
{
	char sBuffer[16], sBufferAfter[2][4];
	
	GetClientCookie(iClient, g_hSkinsCookie, sBuffer, sizeof(sBuffer));
	ExplodeString(sBuffer, ";", sBufferAfter, 2, 4);
	g_iSkinsCT_Choose[iClient] = StringToInt(sBufferAfter[0]);
	g_iSkinsT_Choose[iClient] = StringToInt(sBufferAfter[1]);
} 

public void OnClientDisconnect(int iClient)
{
	if(AreClientCookiesCached(iClient))
	{
		char sBuffer[16];
		
		FormatEx(sBuffer, sizeof(sBuffer), "%i;%i", g_iSkinsCT_Choose[iClient], g_iSkinsT_Choose[iClient]);
		SetClientCookie(iClient, g_hSkinsCookie, sBuffer);
	}
}

public void OnPluginEnd()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			OnClientDisconnect(iClient);
		}
	}
}