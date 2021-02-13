state("PokeyPoke")
{
    int gemCount : 0x4B0958, 0x0, 0x158, 0xC, 0x40;
    int rareGemCount : 0x4B0958, 0x0, 0x168, 0xC, 0x40;
    int greenGemCount : 0x4B0958, 0x0, 0x178, 0xC, 0x40;
    int blackGemCount : 0x4B0958, 0x0, 0x170, 0xC, 0x40;
    byte room : 0x6C2DB8;
    int playerSprite : 0x4B0958, 0x0, 0x1F8, 0xC, 0x44, 0x8, 0x80;
    float playerImageIndex : 0x4B0958, 0x0, 0x1F8, 0xC, 0x44, 0x8, 0x84;
    int lanceCount : 0x4B0958, 0x0, 0x200, 0xC, 0x40;
}

startup
{
    settings.Add("StartAuto", true, "Start timer when moving after restarting the game");
    settings.Add("SplitLance", false, "Split when collecting the spear");
    settings.Add("SplitDiamond", true, "Split when collecting a blue diamond");
    settings.Add("SplitRareDiamond", true, "Split when collecting a red diamond");
    settings.Add("SplitGreenDiamond", true, "Split when collecting a green diamond");
    settings.Add("SplitBlackDiamond", true, "Split when collecting a black diamond");
    settings.Add("SplitArea", false, "Split when entering another area");

    vars.CollectingDiamond = false;
    vars.CollectedLance = false;

    Action<string> Debug = (text) => {
        print("[PokeyPoke Autosplitter] " + text);
    };
    vars.Debug = Debug;
    vars.Debug("Initialized!");
}

start
{
    if(settings["StartAuto"] && (
        (current.playerSprite == 86 && old.playerImageIndex == 0 && current.playerImageIndex > 0) ||
        (current.playerSprite == 67) ||
        (current.playerSprite == 71)
    ))
    {
        vars.Debug("Starting run");
        return true;
    }

    return false;
}

update
{
    if(vars.CollectedLance && timer.CurrentPhase == TimerPhase.NotRunning)
    {
        vars.CollectedLance = false;
    }

    if(old.gemCount != current.gemCount
    || old.rareGemCount != current.rareGemCount
    || old.greenGemCount != current.greenGemCount
    || old.blackGemCount != current.blackGemCount)
    {
        vars.Debug("Diamond removed");
        vars.CollectingDiamond = false;
    }

    return true;
}

split
{
    if(settings["SplitArea"] && old.room != current.room)
    {
        vars.Debug("Entered new area");
        return true;
    }

    if(settings["SplitLance"] && old.lanceCount == 0 && current.lanceCount == 1 && !vars.CollectedLance)
    {
        vars.Debug("Collected lance");
        vars.CollectedLance = true;
        return true;
    }
    
    if(settings["SplitRareDiamond"] && !vars.CollectingDiamond)
    {
        var diamond = new DeepPointer("PokeyPoke.exe", 0x4B0958, 0, 0x168, 0xC, 0x44).Deref<int>(game);
        while(diamond != 0)
        {
            if(new DeepPointer((IntPtr)(diamond + 0x8), 0x2C, 0x10, 0x168, 0x0).Deref<double>(game) == 1)
            {
                vars.Debug("Collected rare diamond");
                vars.CollectingDiamond = true;
                return true;
            }

            diamond = new DeepPointer((IntPtr)diamond).Deref<int>(game);
        }
    }

    if(settings["SplitDiamond"] && !vars.CollectingDiamond)
    {
        var diamond = new DeepPointer("PokeyPoke.exe", 0x4B0958, 0, 0x158, 0xC, 0x44).Deref<int>(game);
        while(diamond != 0)
        {
            if(new DeepPointer((IntPtr)(diamond + 0x8), 0x2C, 0x10, 0x168, 0x0).Deref<double>(game) == 1)
            {
                vars.Debug("Collected diamond");
                vars.CollectingDiamond = true;
                return true;
            }

            diamond = new DeepPointer((IntPtr)diamond).Deref<int>(game);
        }
    }
    
    if(settings["SplitGreenDiamond"] && !vars.CollectingDiamond)
    {
        var diamond = new DeepPointer("PokeyPoke.exe", 0x4B0958, 0, 0x178, 0xC, 0x44).Deref<int>(game);
        while(diamond != 0)
        {
            if(new DeepPointer((IntPtr)(diamond + 0x8), 0x2C, 0x10, 0x168, 0x0).Deref<double>(game) == 1)
            {
                vars.Debug("Collected black diamond");
                vars.CollectingDiamond = true;
                return true;
            }

            diamond = new DeepPointer((IntPtr)diamond).Deref<int>(game);
        }
    }
    
    if(settings["SplitBlackDiamond"] && !vars.CollectingDiamond)
    {
        var diamond = new DeepPointer("PokeyPoke.exe", 0x4B0958, 0, 0x170, 0xC, 0x44).Deref<int>(game);
        while(diamond != 0)
        {
            if(new DeepPointer((IntPtr)(diamond + 0x8), 0x2C, 0x10, 0x168, 0x0).Deref<double>(game) == 1)
            {
                vars.Debug("Collected black diamond");
                vars.CollectingDiamond = true;
                return true;
            }

            diamond = new DeepPointer((IntPtr)diamond).Deref<int>(game);
        }
    }

    return false;
}
