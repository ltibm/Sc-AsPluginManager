CTextMenu@ menu_Plugins;
CTextMenu@ menu_Actions;
class PluginItem
{
	bool IsAll;
	string Name;

}
class PluginAction{
	PluginItem Plugin;
	string Action;
	uint BasePage;
	bool OnMenu;
	PluginAction()
	{
	}
	PluginAction(string action, PluginItem plugin, uint basepage, bool onMenu)
	{
		this.Action = action;
		this.Plugin = plugin;
		this.BasePage = basepage;
		this.OnMenu = onMenu;
	}
}
uint GetPage(int cid, int perpageitems = 7)
{
	float msonuc = floor(float(cid) / float(perpageitems));
	return uint(msonuc);
}
void PluginInit()
{
	//Plugin manager
	g_Module.ScriptInfo.SetAuthor( "S!" );
	g_Module.ScriptInfo.SetContactInfo( "steam:ibmlt" );
	g_Hooks.RegisterHook(Hooks::Player::ClientSay, @ClientSay);
}

void PluginExit()
{
	if (@menu_Plugins !is null)
	{
		if(menu_Plugins.IsRegistered())
			menu_Plugins.Unregister();
		@menu_Plugins = null;
	}
	if (@menu_Actions !is null)
	{
		if(menu_Actions.IsRegistered())
			menu_Actions.Unregister();
		@menu_Actions = null;
	}
}

void ShowPluginMenu(CBasePlayer@ pPlayer, uint page = 0)
{	
	@menu_Plugins =  CTextMenu(@PluginMenuCallback);
	array<string>@ plugins = g_PluginManager.GetPluginList();
	menu_Plugins.SetTitle("Plugins Manager ");
	PluginItem allitem;
	allitem.Name = "*All";
	allitem.IsAll = true;
	menu_Plugins.AddItem("*All", any(allitem));
	for(uint i = 0; i < plugins.length();i++)
	{
		PluginItem item;
		item.Name = plugins[i];
		menu_Plugins.AddItem(plugins[i], any(item));
	}
	uint maxp = menu_Plugins.GetPageCount() - 1;
	if(page > maxp) page = maxp;
	menu_Plugins.Register();
	menu_Plugins.Open(0, page, @pPlayer);
}
void ShowPluginActionMenu(CBasePlayer@ pPlayer, PluginItem& item, uint page)
{
	@menu_Actions =  CTextMenu(@PluginActionMenuCallback);
	array<string>@ plugins = g_PluginManager.GetPluginList();
	menu_Actions.SetTitle(BuildPluginInfo(item));
	menu_Actions.AddItem("Reload", any(PluginAction("reload", item, page, true)));
	menu_Actions.AddItem("Unload", any(PluginAction("unload", item, page, true)));
	menu_Actions.Register();
	menu_Actions.Open(0, 0, @pPlayer);
}

string BuildPluginInfo(PluginItem& item)
{
	string s ="";  
	s += "Name: " + item.Name;
	return s;
}


void PluginActionMenuCallback(CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem)
{
	menu.Unregister();
	PluginAction action;
	if(pItem is null)
	{

		const CTextMenuItem@ item = menu.GetItem(0);
		item.m_pUserData.retrieve(action);
		ShowPluginMenu(pPlayer, action.BasePage);
		return;
	}
	pItem.m_pUserData.retrieve(action);
	ApplyPluginCommand(@pPlayer, action);
	if(action.OnMenu)
	{
		g_Scheduler.SetTimeout("ShowPluginMenu", 0.5f, @pPlayer, action.BasePage);
	}	
	//ShowPluginActionMenu(@pPlayer, action.Plugin, action.BasePage);

}
void ApplyPluginCommand(CBasePlayer@ pPlayer, PluginAction& action)
{
	string message = "";
	string servercmd = "";
	if(action.Action == "reload")
	{
		if(action.Plugin.IsAll)
			servercmd = "as_reloadplugins";
		else
			servercmd = "as_reloadplugin" + " \"" + action.Plugin.Name + "\"";
		message = "Reload command was sent to console";
	}
	else if(action.Action == "unload")
	{
		if(action.Plugin.IsAll)
			servercmd = "as_removeplugins";
		else
			servercmd = "as_removeplugin" + " \"" + action.Plugin.Name + "\"";
		message = "Remove command was sent to console";
	}
	else
		return;
	g_EngineFuncs.ServerCommand(servercmd + "\n");
	if(pPlayer !is null)
	{
		g_PlayerFuncs.ClientPrint(@pPlayer, HUD_PRINTTALK, "[PLUGIN]" + message);
	}
	else{
		g_EngineFuncs.ServerPrint("[PLUGIN]" + message + "\n");
	}
}

void PluginMenuCallback(CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem)
{ 
	if(pItem is null)
	{
		menu.Unregister();
		return;
	}
	uint page = GetPage(iSlot);
	PluginItem item;
	pItem.m_pUserData.retrieve(item);
	menu.Unregister();
	ShowPluginActionMenu(@pPlayer, item, page);

}
HookReturnCode ClientSay(SayParameters@ sayitem)
{
    CBasePlayer@ pPlayer = sayitem.GetPlayer();
    if (pPlayer is null || g_PlayerFuncs.AdminLevel(@pPlayer) != ADMIN_OWNER)
        return HOOK_CONTINUE;
	const CCommand@ args = sayitem.GetArguments();
	string arg = args[0];
    if (arg == "!plugins")
    {
		sayitem.ShouldHide = true;
		ShowPluginMenu(@pPlayer);
        return HOOK_HANDLED;
    }
	else if(arg == "!plugin_r")
	{
		sayitem.ShouldHide = true;
		if(args.ArgC() < 2)
		{
			g_PlayerFuncs.ClientPrint(@pPlayer, HUD_PRINTTALK, "[USAGE] !plugin_r pluginname");
		}
		else{
			string plName = "";
			for(uint i  = 1; i < args.ArgC(); i++)
				plName +=  " " + args[i];
			plName.Trim();
			PluginItem item;
			item.Name = plName;
			PluginAction act("reload", item, 0, false);
			ApplyPluginCommand(@pPlayer, act);
		}
		return HOOK_HANDLED;
	}
	
    return HOOK_CONTINUE;
}