state("PokeyPoke", "Not supported")
{
	int gemCount : 0x0;
    int rubyCount : 0x0;
    int emeraldCount : 0x0;
    int blackGemCount : 0x0;
    int room : 0x0;
    int playerSprite : 0x0;
    float playerImageIndex : 0x0;
    int lanceCount : 0x0;
}

state("PokeyPoke", "Legacy Demo")
{
    int gemCount : 0x4b0958, 0x0, 0x158, 0xc, 0x40;
    int rubyCount : 0x4b0958, 0x0, 0x168, 0xc, 0x40;
    int emeraldCount : 0x4b0958, 0x0, 0x178, 0xc, 0x40;
    int blackGemCount : 0x4b0958, 0x0, 0x170, 0xc, 0x40;
    int room : 0x6c2db8;
    int playerSprite : 0x4b0958, 0x0, 0x1f8, 0xc, 0x44, 0x8, 0x80;
    float playerImageIndex : 0x4b0958, 0x0, 0x1f8, 0xc, 0x44, 0x8, 0x84;
    int lanceCount : 0x4b0958, 0x0, 0x200, 0xc, 0x40;
}

state("PokeyPoke", "Demo")
{
	int gemCount : 0xb4d4f8, 0x0, 0x2f0, 0x18, 0x60;
	int rubyCount : 0xb4d4f8, 0x0, 0x390, 0x18, 0x60;
	int emeraldCount : 0xb4d4f8, 0x0, 0x330, 0x18, 0x60;
	int blackGemCount : 0xb4d4f8, 0x0, 0x300, 0x18, 0x60;
	int room : 0xd6ff54;
	int playerSprite : 0xb4d4f8, 0x0, 0x520, 0x18, 0x50, 0x10, 0xc4;
	float playerImageIndex : 0xb4d4f8, 0x0, 0x520, 0x18, 0x50, 0x10, 0xd4;
	int lanceCount : 0xb4d4f8, 0x0, 0x400, 0x18, 0x60;
}

init
{
    int moduleSize = modules.First().ModuleMemorySize;
    vars.Debug("Module size: " + moduleSize);
    if (moduleSize == 123456789) { // idk what the module size is anymore
		version = "Legacy Demo";
		vars.eatSandSprite = 86;
		vars.jumpSprite = 67;
		vars.runSprite = 71;
		vars.gemList = new DeepPointer("PokeyPoke.exe", 0x4b0958, 0x0, 0x158, 0xc, 0x44);
		vars.rubyList = new DeepPointer("PokeyPoke.exe", 0x4b0958, 0x0, 0x168, 0xc, 0x44);
		vars.emeraldList = new DeepPointer("PokeyPoke.exe", 0x4b0958, 0x0, 0x178, 0xc, 0x44);
		vars.blackGemList = new DeepPointer("PokeyPoke.exe", 0x4b0958, 0x0, 0x170, 0xc, 0x44);
		Predicate<long> IsCollected = (gem) => {
			return new DeepPointer((IntPtr)(gem + 0x8), 0x2c, 0x10, 0x168, 0x0).Deref<double>(game) == 1;
		};
		vars.IsCollected = IsCollected;
	} else if (moduleSize == 14741504) {
		version = "Demo";
		vars.eatSandSprite = 320;
		vars.jumpSprite = 294;
		vars.runSprite = 302;
		vars.gemList = new DeepPointer("PokeyPoke.exe", 0xb4d4f8, 0x0, 0x2f0, 0x18, 0x50);
		vars.rubyList = new DeepPointer("PokeyPoke.exe", 0xb4d4f8, 0x0, 0x390, 0x18, 0x50);
		vars.emeraldList = new DeepPointer("PokeyPoke.exe", 0xb4d4f8, 0x0, 0x330, 0x18, 0x50);
		vars.blackGemList = new DeepPointer("PokeyPoke.exe", 0xb4d4f8, 0x0, 0x300, 0x18, 0x50);
		Predicate<long> IsCollected = (gem) => {
			return new DeepPointer((IntPtr)(gem + 0x10), 0x48, 0x10, 0x80, 0x0).Deref<double>(game) == 1;
		};
		vars.IsCollected = IsCollected;
	} else {
		version = "Not supported";
		vars.Debug("Unknown version!");
		
		vars.eatSandSprite = -1;
		vars.jumpSprite = -1;
		vars.runSprite = -1;
		vars.gemList = new DeepPointer("PokeyPoke.exe", 0x0);
		vars.rubyList = new DeepPointer("PokeyPoke.exe", 0x0);
		vars.emeraldList = new DeepPointer("PokeyPoke.exe", 0x0);
		vars.blackGemList = new DeepPointer("PokeyPoke.exe", 0x0);
		Predicate<long> IsCollected = (gem) => {
			return false;
		};
		vars.IsCollected = IsCollected;
		return;
	}
	vars.Debug("Version detected: " + version);
}

startup
{
    settings.Add("StartAuto", true, "Start timer when moving after restarting the game");
    settings.Add("SplitLance", false, "Split when collecting the spear");
    settings.Add("SplitGem", true, "Split when collecting a blue gem");
    settings.Add("SplitEmerald", true, "Split when collecting an emerald");
    settings.Add("SplitRuby", true, "Split when collecting a ruby");
    settings.Add("SplitBlackGem", true, "Split when collecting a black gem");
    settings.Add("SplitArea", false, "Split when entering another area");

    vars.CollectingGem = false;
    vars.CollectedLance = false;

    Action<string> Debug = (text) => {
        print("[PokeyPoke Autosplitter] " + text);
    };
    vars.Debug = Debug;
    vars.Debug("Initialized!");
}

start
{
    if(
		settings["StartAuto"] && (
			(
				current.playerSprite == vars.eatSandSprite &&
				old.playerImageIndex == 0 &&
				current.playerImageIndex > 0
			) ||
			(current.playerSprite == vars.jumpSprite) ||
			(current.playerSprite == vars.runSprite)
		)
	) {
        vars.Debug("Starting run");
        return true;
    }

    return false;
}

update
{
    if (vars.CollectedLance && timer.CurrentPhase == TimerPhase.NotRunning) {
        vars.CollectedLance = false;
    }

    if (
		old.gemCount != current.gemCount ||
		old.rubyCount != current.rubyCount ||
		old.emeraldCount != current.emeraldCount ||
		old.blackGemCount != current.blackGemCount
	) {
        vars.Debug("Gem removed");
        vars.CollectingGem = false;
    }

    return true;
}

split
{
    if (settings["SplitArea"] && old.room != current.room) {
        vars.Debug("Entered new area");
        return true;
    }

    if (settings["SplitLance"] && old.lanceCount == 0 && current.lanceCount == 1 && !vars.CollectedLance) {
        vars.Debug("Collected lance");
        vars.CollectedLance = true;
        return true;
    }
    
    if (settings["SplitRuby"] && !vars.CollectingGem) {
        var gem = vars.rubyList.Deref<int>(game);
        while (gem != 0) {
            if (vars.IsCollected(gem)) {
                vars.Debug("Collected ruby");
                vars.CollectingGem = true;
                return true;
            }

            gem = new DeepPointer((IntPtr)gem).Deref<int>(game);
        }
    }

    if (settings["SplitGem"] && !vars.CollectingGem) {
        var gem = vars.gemList.Deref<int>(game);
        while (gem != 0) {
            if (vars.IsCollected(gem)) {
                vars.Debug("Collected gem");
                vars.CollectingGem = true;
                return true;
            }

            gem = new DeepPointer((IntPtr)gem).Deref<int>(game);
        }
    }
    
    if (settings["SplitEmerald"] && !vars.CollectingGem) {
        var gem = vars.emeraldList.Deref<int>(game);
        while (gem != 0) {
            if (vars.IsCollected(gem)) {
                vars.Debug("Collected emerald");
                vars.CollectingGem = true;
                return true;
            }

            gem = new DeepPointer((IntPtr)gem).Deref<int>(game);
        }
    }
    
    if (settings["SplitBlackGem"] && !vars.CollectingGem) {
        var gem = vars.blackGemList.Deref<int>(game);
        while (gem != 0) {
            if (vars.IsCollected(gem)) {
                vars.Debug("Collected black gem");
                vars.CollectingGem = true;
                return true;
            }

            gem = new DeepPointer((IntPtr)gem).Deref<int>(game);
        }
    }

    return false;
}
