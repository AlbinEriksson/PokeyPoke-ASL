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
    if (moduleSize == 14741504) {
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
        Func<long, int> InstanceId = (instance) => {
            return new DeepPointer((IntPtr)(instance + 0x10), 0xbc).Deref<int>(game);
        };
        vars.InstanceId = InstanceId;
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
        Func<long, int> InstanceId = (instance) => {
            return 0;
        };
        vars.InstanceId = InstanceId;
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

    vars.CollectedLance = false;

    // The tuples store the old and current value of whether a gem is collected
    vars.rubies = new Dictionary<int, Tuple<bool, bool>>();
    vars.gems = new Dictionary<int, Tuple<bool, bool>>();
    vars.emeralds = new Dictionary<int, Tuple<bool, bool>>();
    vars.blackGems = new Dictionary<int, Tuple<bool, bool>>();
    Action<Dictionary<int, Tuple<bool, bool>>, DeepPointer, Process> CheckGems = (gems, gemList, _game) => {
        var gem = gemList.Deref<int>(_game);
        var existingIds = new List<int>();
        while (gem != 0) {
            var id = vars.InstanceId(gem);
            existingIds.Add(id);
            bool currValue = gems.ContainsKey(id) && gems[id].Item2;
            gems[id] = new Tuple<bool, bool>(currValue, vars.IsCollected(gem));
            gem = new DeepPointer((IntPtr)gem).Deref<int>(_game);
        }
        var nonExistingIds = gems.Keys.Except(existingIds).ToList();
        foreach (var id in nonExistingIds) {
            gems.Remove(id);
        }
    };
    vars.CheckGems = CheckGems;

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

    if (vars.rubyList != null) vars.CheckGems(vars.rubies, vars.rubyList, game);
    if (vars.gemList != null) vars.CheckGems(vars.gems, vars.gemList, game);
    if (vars.emeraldList != null) vars.CheckGems(vars.emeralds, vars.emeraldList, game);
    if (vars.blackGemList != null) vars.CheckGems(vars.blackGems, vars.blackGemList, game);

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
    
    if (settings["SplitRuby"]) {
        foreach (var ruby in vars.rubies.Values) {
            if (!ruby.Item1 && ruby.Item2) {
                vars.Debug("Collected ruby");
                return true;
            }
        }
    }

    if (settings["SplitGem"]) {
        foreach (var gem in vars.gems.Values) {
            if (!gem.Item1 && gem.Item2) {
                vars.Debug("Collected gem");
                return true;
            }
        }
    }
    
    if (settings["SplitEmerald"]) {
        foreach (var emerald in vars.emeralds.Values) {
            if (!emerald.Item1 && emerald.Item2) {
                vars.Debug("Collected emerald");
                return true;
            }
        }
    }
    
    if (settings["SplitBlackGem"]) {
        foreach (var blackGem in vars.blackGems.Values) {
            if (!blackGem.Item1 && blackGem.Item2) {
                vars.Debug("Collected black gem");
                return true;
            }
        }
    }

    return false;
}
