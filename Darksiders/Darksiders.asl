/* Darksiders Load Remover & Autosplitter v1.0
 * by heny (Thanks to whatisaphone for finding a lot of pointers)
 * Tested only with the current version of the game's Steam releases
 *
 * Features:
 * - Pauses the timer upon saving and loading (for save games & trigger zones).
 * - Supports both the original version and the Warmastered Edition (only on Steam).
 * - Pauses the timer upon game exit/crash and resumes it after restarting the game.
 * - Automatically splits upon reaching certain points of the run (adjustable via settings).
 * 
 * Note:
 * Darksiders uses a rather complex loading system that combines regular loading of savegames, different in-game areas being loaded/unloaded by
 * activating certain trigger zones and some kind of dynamic streaming in the background. For the no loads functionality the following types are relevant:
 * - Regular Savegame Loading: Happens every time the player loads a savegame through the menu ("Data/Load Game"). To detect this kind of loading we use a
 *                             specific fixed value of the hashed string that identifies the current Scaleform HUD overlay window.
 * - Regular Savegame Saving: Happens when the player saves a savegame through the menu ("Data/Save Game"). To detect this kind of saving we use the pointer
 *                            "savingViaMenu". The actual saving process usually only takes a very short time. For the ease of handling it, the timer is paused
 *                            until "Saving Completed." appears on screen.
 * - Area Loading: Happens when the player moves into a specific trigger zone that loads a nearby area. This kind of loading is noticeable because it freezes
 *                 the game with an orange loading circle appearing on the left side of the screen. To detect this kind of loading we use the pointer
 *                 "loadingNewArea", which is 0 whenever this happens, combined with some other pointers (to prevent incorrect pausing in other occasions).
 * - Streaming: Happens dynamically in certain spots of the game but to our knowledge does not actually differ for players with different hardware or make a
 *              difference for the timing. An example is the variable-length blackscreen when entering Iron Canopy that can appear before the FMV cutscene.
 *              Combined with the actual time the FMV is being displayed on screen, the length always matches up.
 * - Fake Loading: In certain situtations, like when being teleported to a Serpent Path, the game displays blue rings in the middle of the screen that look as
 *                 if something was loading. Another example is the circle displayed when Vulgrim's shop menu appears. The duration of these "transitions" is
 *                 fixed, so they have no impact on the timing.
 * - Autosaving: Happens in certain spots of the game but does not freeze gameplay, so the timer is not paused.
 */

// Original Version - Steam, Current Version (v1.1)
state("DarksidersPC")
{
  // Contains a hashed string (HString) that identifies the current Scaleform overlay window  
  ulong scaleformHString : "DarksidersPC.exe", 0x0122F6A4, 0x34, 0x28; 

  // 0 if a game-freezing, loading zone is triggered (as well as in some other occasions), 1 during normal gameplay
  bool loadingNewArea : "DarksidersPC.exe", 0x122DD6C, 0x30;

  // 1 if the game is saving (and sometimes if a save is loaded) 
  bool savingViaMenu : "DarksidersPC.exe", 0x0122F650, 0x10;

  // 1 if the game is pausing or on the main menu
  bool pausing : "DarksidersPC.exe", 0x00005EEC, 0xE6; 

  // 1 if the game is playing an FMV cutscene
  bool playingFmvCutscene : "DarksidersPC.exe", 0x00005AD0, 0x5CA; 

  // Contains a hashed string that identifies the current FMV cutscene
  ulong fmvCutsceneHString : "DarksidersPC.exe", 0x122E4B0, 0x24, 0x40;

  // Contains a hashed string that identifies the current in-game cinematic
  ulong ingameCinematicHString : "DarksidersPC.exe", 0x0122DEA0, 0x0, 0x8, 0x74, 0x10;

  float playerX : "DarksidersPC.exe", 0x0122E594, 0x60;
  float playerY : "DarksidersPC.exe", 0x0122E594, 0x64;
  float playerZ : "DarksidersPC.exe", 0x0122E594, 0x68;
  float playerRotationX : "DarksidersPC.exe", 0x0122E594, 0x5BC;
  float playerRotationY : "DarksidersPC.exe", 0x0122E594, 0x5C0;
  ulong spawnRegion : "DarksidersPC.exe", 0x0122E594, 0x63C, 0x18;
}

// Warmastered Edition - Steam, Current Version
state("darksiders1")
{
  ulong scaleformHString : "darksiders1.exe", 0x1EDEB0C, 0x50, 0x28;

  // 0 if a game-freezing, in-game loading zone is triggered, 1 during normal gameplay
  bool loadingNewArea : "darksiders1.exe", 0x1EDEAFC, 0x3C;

  bool savingViaMenu : "darksiders1.exe", 0x01EDE694, 0x10;
  bool pausing : "darksiders1.exe", 0x02395FB4, 0xC0;
  bool playingFmvCutscene : "darksiders1.exe", 0x01EDE2CC, 0xC;
  ulong fmvCutsceneHString : "darksiders1.exe", 0x01EDEAFC, 0x1C, 0x24, 0x14, 0x8;
  ulong ingameCinematicHString : "darksiders1.exe", 0x01EDEAFC, 0x98, 0x8, 0x74, 0x10;
  float playerX : "darksiders1.exe", 0x01EDE468, 0x60;
  float playerY : "darksiders1.exe", 0x01EDE468, 0x64;
  float playerZ : "darksiders1.exe", 0x01EDE468, 0x68;
  float playerRotationX : "darksiders1.exe", 0x01EDE468, 0x5E0;
  float playerRotationY : "darksiders1.exe", 0x01EDE468, 0x5E4;
  ulong spawnRegion : "darksiders1.exe", 0x01EDEAFC, 0x1B8, 0x508;

  // Unknown purpose, probably useless
  //long queuedLoads : "darksiders1.exe", 0x1EE1228, 190;
}

startup
{
  // If this is set to false, none of the debug types listed below will be processed.
  vars.debug = false;

  vars.debugHStrings = true;
  vars.debugFloatDelta = false;
  vars.debugPlayerPosition = false;
  vars.debugDictChanges = true;

  // ==========================================================
  // Helper functions
  // ==========================================================

  vars.AddSettings = (Action) (() => {
    vars.settingsDict = new System.Collections.Specialized.OrderedDictionary();
    vars.settingsDict.Add("mayhem", "Mayhem");
    vars.settingsDict.Add("seraphimHotel", "Seraphim Hotel");
    vars.settingsDict.Add("samael", "Samael");
    vars.settingsDict.Add("theBrokenStair", "The Broken Stair");
    vars.settingsDict.Add("autoscroller", "Autoscroller");
    vars.settingsDict.Add("crossblade", "Crossblade");
    vars.settingsDict.Add("tiamat", "Tiamat");
    vars.settingsDict.Add("tremorGauntlet", "Tremor Gauntlet");
    vars.settingsDict.Add("theGriever", "The Griever");
    vars.settingsDict.Add("theAshlands", "The Ashlands");
    vars.settingsDict.Add("ruin", "Ruin");
    vars.settingsDict.Add("theStygian", "The Stygian");
    vars.settingsDict.Add("abyssalChain", "Abyssal Chain");
    vars.settingsDict.Add("silitha", "Silitha");
    vars.settingsDict.Add("stragaTwo", "Straga 2");
    vars.settingsDict.Add("armageddonBlade", "Armageddon Blade");
    vars.settingsDict.Add("theDestroyer", "The Destroyer");

    settings.Add("splits", true, "Splits");

    foreach (System.Collections.DictionaryEntry item in vars.settingsDict) {
      settings.Add(item.Key.ToString(), true, item.Value.ToString(), "splits");
    }

    settings.Add("options", false, "Options");
    settings.Add("ignoreSegmentCountWarning", false, "Ignore segment count warning permanently", "options");
    settings.Add("ignoreGameTimeWarning", false, "Ignore timing method warning permanently", "options");
  });

  vars.BuildSegmentDictionaries = (Action) (() => {

    // Create a list of FMV cutscenes and in-game cinematics to split for.
    // These HStrings are consistent across all game versions & patches on Steam.
    vars.allSplittableCutscenes = new Dictionary<ulong, Tuple<int, string, int, bool>>() {
      { (ulong)0xE92FB4FCE40C1764, vars.CreateCutsceneTuple(0, "mayhem", 0) },
      { (ulong)0xE767A830E42B171C, vars.CreateCutsceneTuple(1, "seraphimHotel", 0) },
      { (ulong)0xE2A1FD22FA3612B4, vars.CreateCutsceneTuple(2, "samael", 0) },
      { (ulong)0xE6C75F78FA2E9290, vars.CreateCutsceneTuple(3, "theBrokenStair", 0) },
      { (ulong)0xD8AD29EB134A5984, vars.CreateCutsceneTuple(6, "tiamat", 0) },
      { (ulong)0xFA55851AD8609CE0, vars.CreateCutsceneTuple(8, "theGriever", 0) },
      { (ulong)0xAE868F9596A0BB59, vars.CreateCutsceneTuple(9, "theAshlands", 0) },
      { (ulong)0xF8B67F38D86E1CF4, vars.CreateCutsceneTuple(10, "ruin", 0) },
      { (ulong)0xC5F569A69CEA8030, vars.CreateCutsceneTuple(14, "stragaTwo", 0) },
      { (ulong)0xB38AE01679355299, vars.CreateCutsceneTuple(15, "armageddonBlade", 0) },
      { (ulong)0xCD398C4482DB85F8, vars.CreateCutsceneTuple(16, "theDestroyer", 0) }
    };

    // Create a list of cutscenes to split for which are only detectable through player position/rotation.
    // These HStrings are consistent across all game versions & patches on Steam.
    vars.allSplittablePlayerPositions = new Dictionary<ulong, List<Tuple<int, string, int, bool, float[]>>>();
    vars.AddSplittablePlayerPosition((ulong)0x1FD50437D4102AE3, 4, "autoscroller", 0, 16247.88f, -26176.85f, 1622.47f, -48.64708f, -15.35381f, 7.0f);
    vars.AddSplittablePlayerPosition((ulong)0x5A83535B20615774, 5, "crossblade", 0, 29841.28f, -26407.39f, -630.1481f, -76.79177f, 8.623878f, 1.0f);
    vars.AddSplittablePlayerPosition((ulong)0x4B0A6F62DCB93232, 7, "tremorGauntlet", 0, -38980.24f, -42848.44f, -2155.23f, -179.3368f, 18.12865f, 1.0f);
    vars.AddSplittablePlayerPosition((ulong)0xB6ABD72087D448B2, 11, "theStygian", 0, 9613.245f, 51410.0f, -374.48f, -9.786468f, 12.17409f, 1.0f);
    vars.AddSplittablePlayerPosition((ulong)0x2000205131215855, 12, "abyssalChain", 0, -30940.53f, 20022.96f, 1332.317f, -1.459282f, 25.53297f, 1.00f);
    vars.AddSplittablePlayerPosition((ulong)0x2000205131215855, 13, "silitha", 0, -22391.2f, 17766.84f, 93.19632f, 95.54919f, -1.946976f, 7.5f);
  });

  // A tuple is used as a workaround because we can't create our own structs/data types with ASL.
  // Cutscene tuple structure: (segmentId, identifier, delayInMs, alreadySplit)
  // Player position tuple structure:
  // (segmentId, identifier, delayInMs, alreadySplit, [playerX, playerY, playerZ, playerRotationX, playerRotationY, floatComparisonDelta])
  vars.AddSplittablePlayerPosition = (Action<ulong, int, string, int, float, float, float, float, float, float>) 
    ((hString, segmentId, identifier, delayInMs, playerX, playerY, playerZ, playerRotationX, playerRotationY, delta) => {
      var tuple = Tuple.Create(segmentId, identifier, delayInMs, false, new float[] { playerX, playerY, playerZ, playerRotationX, playerRotationY, delta });

      if (!vars.allSplittablePlayerPositions.ContainsKey(hString)) {
        vars.allSplittablePlayerPositions.Add(hString, new List<Tuple<int, string, int, bool, float[]>>() { tuple });
      } else {
        var list = vars.allSplittablePlayerPositions[hString];
        list.Add(tuple);
      }
  });

  vars.CreateCutsceneTuple = (Func<int, string, int, Tuple<int, string, int, bool>>) ((segmentId, identifier, delayInMs) => {
    return Tuple.Create(segmentId, identifier, delayInMs, false);
  });

  // Regular Tuples are immutable so we unfortunately have to create a copy if the "alreadySplit" flag is supposed to be toggled.
  // ASL is based on C# 5.0 so we can't use other (mutable) tuple types.
  vars.ToggleCutsceneSegmentAndGetNewTupleCopy = (Func<Tuple<int, string, int, bool>, int, Tuple<int, string, int, bool>>) ((tuple, segmentId) => {
      return Tuple.Create(tuple.Item1, tuple.Item2, tuple.Item3, !tuple.Item4);
  });

  vars.TogglePlayerPositionSegmentAndGetNewListCopy = (Func<List<Tuple<int, string, int, bool, float[]>>, int, List<Tuple<int, string, int, bool, float[]>>>)
    ((list, segmentId) => {
      var splitTuple = list.FirstOrDefault(tuple => tuple.Item1 == segmentId);
      var toggledSplitTuple = Tuple.Create(splitTuple.Item1, splitTuple.Item2, splitTuple.Item3, !splitTuple.Item4, splitTuple.Item5);
      var toggledSplitTupleList = new List<Tuple<int, string, int, bool, float[]>>() { toggledSplitTuple };

      return toggledSplitTupleList.Union(list.Where(tuple => tuple.Item1 != segmentId)).ToList();
  });

  // Find the cutscene segment that is either the one with the highest segment ID of all already split for segments (split mode: UndoSplit)
  // or the one with the lowest segment ID of all unsplit segments (split mode: NextSplit).
  vars.GetBoundaryCutsceneSegmentForSplitMode = (Func<string, KeyValuePair<ulong, Tuple<int, string, int, bool>>>) ((splitMode) => {
    Dictionary<ulong, Tuple<int, string, int, bool>> cutsceneDict = vars.filteredSplittableCutscenes;

    var boundarySegment = new KeyValuePair<ulong, Tuple<int, string, int, bool>>(0, null);

    var groupedSegments = cutsceneDict.Where(keyValuePair => {
      bool alreadySplit = keyValuePair.Value.Item4;
      return splitMode == vars.UndoSplit ? alreadySplit : !alreadySplit;
    });

    if (groupedSegments.Count() > 0) {
      boundarySegment = groupedSegments.Aggregate((a, b) => {
        var segmentIdA = a.Value.Item1;
        var segmentIdB = b.Value.Item1;

        return (splitMode == vars.UndoSplit ? segmentIdA > segmentIdB : segmentIdA < segmentIdB) ? a : b;
      });
    }

    return boundarySegment;
  });

  // Find the player position segment that is either the one with the highest segment ID of all already split for segments (split mode: UndoSplit)
  // or the one with the lowest segment ID of all unsplit segments (split mode: NextSplit)
  vars.GetBoundaryPlayerPositionSegmentForSplitMode = (Func<string, Tuple<KeyValuePair<ulong, List<Tuple<int, string, int, bool, float[]>>>, int>>)
    ((splitMode) => {
      var boundarySegment = new KeyValuePair<ulong, List<Tuple<int, string, int, bool, float[]>>>(0, null);
      int boundarySegmentId = (splitMode == vars.UndoSplit ? -1 : Int32.MaxValue);;

      foreach (var dictEntry in vars.filteredSplittablePlayerPositions) {
        string hString = string.Format("0x{0:X}", dictEntry.Key);
        var segmentTuples = (List<Tuple<int, string, int, bool, float[]>>)dictEntry.Value;

        foreach (var segmentTuple in segmentTuples) {
          bool alreadySplit = segmentTuple.Item4;
          int segmentId = segmentTuple.Item1;

          if ((splitMode == vars.UndoSplit ? alreadySplit : !alreadySplit)
            && (splitMode == vars.UndoSplit ? segmentId > boundarySegmentId : segmentId < boundarySegmentId)) {
              boundarySegment = dictEntry;
              boundarySegmentId = segmentId;
          }
        }
      }

      return Tuple.Create(boundarySegment, boundarySegmentId);
  });

  // An adjustable delta is necessary because of LiveSplit's accuracy with respect to certain game situations.
  vars.compareFloats = (Func<float, float, float, bool>) ((a, b, delta) => {
    if (vars.debug) {
      float printDelta = Math.Abs(a - b);

      if (vars.debugFloatDelta) {
        print("Delta: " + printDelta.ToString() + "(" + a + ", " + b + ")");
      }

      return Math.Abs(a - b) < delta;
    }

    return false;
  });

  // ==========================================================
  // Event handlers
  // ==========================================================

  vars.OnReset = (LiveSplit.Model.Input.EventHandlerT<TimerPhase>)((s, e) => {
    vars.ResetVariables();
  });

  // Toggle the "alreadySplit" flag of the last split for segment.
  vars.OnUndoSplit = (EventHandler) ((s, e) => {
    var lastSplitCutsceneSegment = vars.GetBoundaryCutsceneSegmentForSplitMode(vars.UndoSplit);
    int lastSplitCutsceneSegmentId = lastSplitCutsceneSegment.Key == 0 ? -1 : lastSplitCutsceneSegment.Value.Item1;

    var lastSplitPPositionSegmentTuple = vars.GetBoundaryPlayerPositionSegmentForSplitMode(vars.UndoSplit);
    var lastSplitPPositionSegment = lastSplitPPositionSegmentTuple.Item1;
    int lastSplitPPositionSegmentId = lastSplitPPositionSegmentTuple.Item2;

    if (lastSplitCutsceneSegmentId > lastSplitPPositionSegmentId) {
      vars.filteredSplittableCutscenes[lastSplitCutsceneSegment.Key] =
        vars.ToggleCutsceneSegmentAndGetNewTupleCopy(lastSplitCutsceneSegment.Value, lastSplitCutsceneSegmentId);

      if (vars.debugDictChanges) {
        vars.PrintCutsceneDictDebug(vars.filteredSplittableCutscenes, "Event UndoSplit => filteredSplittableCutscenes");
      }
    } else if (lastSplitCutsceneSegmentId < lastSplitPPositionSegmentId) {
      vars.filteredSplittablePlayerPositions[lastSplitPPositionSegment.Key] =
        vars.TogglePlayerPositionSegmentAndGetNewListCopy(lastSplitPPositionSegment.Value, lastSplitPPositionSegmentId);

      if (vars.debugDictChanges) {
        vars.PrintPlayerPositionDictDebug(vars.filteredSplittablePlayerPositions, "Event UndoSplit => filteredSplittablePlayerPositions");
      }
    }
  });

  // Toggle the "alreadySplit" flag of the first unsplit segment
  vars.OnNextSplit = (EventHandler) ((s, e) => {
    var firstUnsplitCutsceneSegment = vars.GetBoundaryCutsceneSegmentForSplitMode(vars.NextSplit);
    int firstUnsplitCutsceneSegmentId = firstUnsplitCutsceneSegment.Key == 0 ? -1 : firstUnsplitCutsceneSegment.Value.Item1;

    var firstUnsplitPPositionSegmentTuple = vars.GetBoundaryPlayerPositionSegmentForSplitMode(vars.NextSplit);
    var firstUnsplitPPositionSegment = firstUnsplitPPositionSegmentTuple.Item1;
    int firstUnsplitPPositionSegmentId = firstUnsplitPPositionSegmentTuple.Item2;

    if (firstUnsplitCutsceneSegmentId < firstUnsplitPPositionSegmentId) {
      vars.filteredSplittableCutscenes[firstUnsplitCutsceneSegment.Key] =
        vars.ToggleCutsceneSegmentAndGetNewTupleCopy(firstUnsplitCutsceneSegment.Value, firstUnsplitCutsceneSegmentId);

      if (vars.debugDictChanges) {
        vars.PrintCutsceneDictDebug(vars.filteredSplittableCutscenes, "Event NextSplit => filteredSplittableCutscenes");
      }
    } else if (firstUnsplitCutsceneSegmentId > firstUnsplitPPositionSegmentId) {
      vars.filteredSplittablePlayerPositions[firstUnsplitPPositionSegment.Key] =
        vars.TogglePlayerPositionSegmentAndGetNewListCopy(firstUnsplitPPositionSegment.Value, firstUnsplitPPositionSegmentId);
        
      if (vars.debugDictChanges) {
        vars.PrintPlayerPositionDictDebug(vars.filteredSplittablePlayerPositions, "Event NextSplit => filteredSplittablePlayerPositions");
      }
    }
  });

  // ==========================================================
  // Constants
  // ==========================================================

  vars.UndoSplit = "UndoSplit";
  vars.NextSplit = "NextSplit";

  vars.SaveLoadingScaleformHString = (ulong)0x2C722AD7BB24C00F;
  vars.WmEInitialLoadingScaleformHString = (ulong)0x686EEBEFDA31BB3B;

  // Special safety net to not falsely pause the timer on certain menus and their transitions
  vars.LoadingNewAreaExceptions = new List<ulong>() {
    0x10538BC321CA13F0, 0x13823B0948E7C650, 0x59379FE6A631E252, 0x6165DFF17399A9B1, // Chronicle menu
    0xFB67FCF7ADBFB126, // Options menu
    0xF3F378D35692D404, // Saving + loading menu
    0x7BC95CF5CC8107E8 // Pause menu
  };

  vars.XboxLegalFmvCutsceneHString = (ulong)0xFDF14B51ED8D6511;
  vars.IntroPartTwoFmvCutsceneHString = (ulong)0xD5A60097BACB1FC0;

  // ==========================================================
  // Script startup
  // ==========================================================

  vars.stopwatch = new Stopwatch();
  vars.lastProcessName = "";

  vars.BuildSegmentDictionaries();
  vars.AddSettings();

  timer.OnReset += vars.OnReset;
  timer.OnUndoSplit += vars.OnUndoSplit;
  timer.OnSkipSplit += vars.OnNextSplit;
  timer.OnSplit += vars.OnNextSplit;
}

shutdown
{
  timer.OnReset -= vars.OnReset;
  timer.OnUndoSplit -= vars.OnUndoSplit;
  timer.OnSkipSplit -= vars.OnNextSplit;
  timer.OnSplit -= vars.OnNextSplit;
}

init
{
  // ==========================================================
  // Helper functions (that READ from the settings object)
  // ==========================================================

  vars.PrintCutsceneDictDebug = (Action<Dictionary<ulong, Tuple<int, string, int, bool>>, string>) ((dict, name) => {
    if (vars.debug) {
      print("===========================================================================================================================================");
      print("Cutscene Dictionary \"" + name + "\"");
      print("===========================================================================================================================================");
      print("#".PadRight(4, ' ') + "HString".PadRight(20, ' ') + "Identifier".PadRight(22, ' ') + "Delay".PadRight(7, ' ')
        + "Split?".PadRight(9, ' ') + "Enabled?");
      print("===========================================================================================================================================");

      foreach (KeyValuePair<ulong, Tuple<int, string, int, bool>> entry in dict) {
        var tuple = (Tuple<int, string, int, bool>)entry.Value;

        string hString = string.Format("0x{0:X}", entry.Key);
        int segmentId = tuple.Item1;
        string identifier = tuple.Item2;
        int delayInMs = tuple.Item3;
        bool alreadySplit = tuple.Item4;

        print(segmentId.ToString().PadRight(4, ' ') + hString.PadRight(20, ' ') + identifier.PadRight(22, ' ')
          + delayInMs.ToString().PadRight(7, ' ') + alreadySplit.ToString().PadRight(9, ' ') + (settings[identifier] ? "ON" : "OFF"));
      }

      print("===========================================================================================================================================");
    }
  });

  vars.PrintPlayerPositionDictDebug = (Action<Dictionary<ulong, List<Tuple<int, string, int, bool, float[]>>>, string>) ((dict, name) => {
    if (vars.debug) {
      print("===========================================================================================================================================");
      print("Player Position Dictionary \"" + name + "\"");
      print("===========================================================================================================================================");
      print("#".PadRight(4, ' ') + "HString".PadRight(20, ' ') + "Identifier".PadRight(22, ' ') + "Delay".PadRight(8, ' ')
        + "Player Position X/Y/Z".PadRight(35, ' ') + "Player Rotation X/Y".PadRight(25, ' ') + "Delta".PadRight(8, ' ')
        + "Split?".PadRight(9, ' ') + "Enabled?");
      print("===========================================================================================================================================");

      foreach (var entry in dict) {
        string hString = string.Format("0x{0:X}", entry.Key);

        var segments = (List<Tuple<int, string, int, bool, float[]>>)entry.Value;

        foreach (var segment in segments) {
          int segmentId = segment.Item1;
          string identifier = segment.Item2;
          int delayInMs = segment.Item3;
          bool alreadySplit = segment.Item4;

          var playerPositionArray = segment.Item5;
          string playerPosition = playerPositionArray[0] + ", " + playerPositionArray[1] + ", " + playerPositionArray[2];
          string playerRotation = playerPositionArray[3] + ", " + playerPositionArray[4];
          float delta = playerPositionArray[5];

          print(segmentId.ToString().PadRight(4, ' ') + hString.PadRight(20, ' ') + identifier.PadRight(22, ' ') + delayInMs.ToString().PadRight(8, ' ')
            + playerPosition.PadRight(35, ' ') + playerRotation.PadRight(25, ' ') + delta.ToString("0.00").PadRight(8, ' ') 
            + alreadySplit.ToString().PadRight(9, ' ') + (settings[identifier] ? "ON" : "OFF"));
        }
      }

      print("===========================================================================================================================================");
    }
  });

  // Returns a list of FMV cutscenes and in-game cinematics to split for that is synchronized with the ASL settings.
  vars.GetFilteredSplittableCutscenes = (Func<Dictionary<ulong, Tuple<int, string, int, bool>>>) (() => {
    var filteredDict = new Dictionary<ulong, Tuple<int, string, int, bool>>();

    foreach (var entry in vars.settingsDict) {
      var identifier = (string)entry.Key;

      if (settings[identifier]) {
        var segmentKeyValuePair =
          ((Dictionary<ulong, Tuple<int, string, int, bool>>)vars.allSplittableCutscenes).FirstOrDefault(kVP => kVP.Value.Item2.Equals(identifier));
        ulong hString = segmentKeyValuePair.Key;

        if (hString != 0) {
          var tuple = segmentKeyValuePair.Value;

          filteredDict.Add(hString, tuple);
        }
      }
    }

    return filteredDict;
  });

  // Returns a list of player positions to split for that is synchronized with the ASL settings.
  vars.GetFilteredSplittablePlayerPositions = (Func<Dictionary<ulong, List<Tuple<int, string, int, bool, float[]>>>>) (() => {
    var filteredDict = new Dictionary<ulong, List<Tuple<int, string, int, bool, float[]>>>();

    foreach (var splittablePlayerPosition in vars.allSplittablePlayerPositions) {
      ulong hString = splittablePlayerPosition.Key;
      var segments = ((List<Tuple<int, string, int, bool, float[]>>)splittablePlayerPosition.Value)
        .ConvertAll(tuple => Tuple.Create(tuple.Item1, tuple.Item2, tuple.Item3, tuple.Item4, tuple.Item5));

      segments.RemoveAll(tuple => !settings[tuple.Item2]);

      if (segments.Any()) {
        filteredDict.Add(hString, segments);
      }
    }

    return filteredDict;
  });

  vars.ResetVariables = (Action) (() => {
    vars.currentSplitDelay = 0;
    vars.filteredSplittableCutscenes = vars.GetFilteredSplittableCutscenes();
    vars.filteredSplittablePlayerPositions = vars.GetFilteredSplittablePlayerPositions();
    vars.gameExited = false;
    vars.pausedStopwatch = false;
    vars.secondIntroFmvCutscenePlayed = false;
    vars.stopwatch.Reset();
  });

  vars.GetEnabledAutosplitCount = (Func<int>) (() => {
    int count = 0;
    foreach (var entry in vars.settingsDict) {
      if (settings[(string)entry.Key]) {
        ++count;
      }
    }

    return count;
  });

  // ==========================================================
  // Game initialization
  // ==========================================================

  if (!game.ProcessName.Equals(vars.lastProcessName)) {
    vars.ResetVariables();
  }

  vars.lastProcessName = game.ProcessName;

  if (!vars.gameExited) {
    vars.filteredSplittableCutscenes = vars.GetFilteredSplittableCutscenes();
    vars.PrintCutsceneDictDebug(vars.allSplittableCutscenes, "allSplittableCutscenes");
    vars.PrintCutsceneDictDebug(vars.filteredSplittableCutscenes, "filteredSplittableCutscenes");

    vars.filteredSplittablePlayerPositions = vars.GetFilteredSplittablePlayerPositions();
    vars.PrintPlayerPositionDictDebug(vars.allSplittablePlayerPositions, "allSplittablePlayerPositions");
    vars.PrintPlayerPositionDictDebug(vars.filteredSplittablePlayerPositions, "filteredSplittablePlayerPositions");

    if (!settings["ignoreSegmentCountWarning"]) {
      int autosplitCount = vars.GetEnabledAutosplitCount();
      bool notEnoughActualSegments = autosplitCount > timer.Run.Count;

      if (timer.Run.Count != autosplitCount) {
        MessageBox.Show(
          timer.Form,
          "You have enabled " + autosplitCount + " autosplitter segments in the settings but have set up" + (notEnoughActualSegments ? " only " : " ") 
            + timer.Run.Count + " actual split segments.\n"
            + "For the autosplitter to work correctly make sure that the segment amounts match. If you wish to split manually, you can fully disable the "
            + "autosplitter in the settings. This warning can also be permanently disabled in the options.",
          "Darksiders Autosplitter - Differing Segment Count",
          MessageBoxButtons.OK,
          MessageBoxIcon.Warning
        );
      }
    }

    if (!settings["ignoreGameTimeWarning"] && timer.CurrentTimingMethod == TimingMethod.RealTime) {
      var dialogResult = MessageBox.Show(
        timer.Form,
        "This game uses \"RTA without loads\" (Game Time in LiveSplit) as the main timing method.\n"
        + "LiveSplit currently is set to show \"Real Time\". Would you like to change the timing method to \"Game Time\"?",
        "Darksiders Autosplitter - Timing Method",
        MessageBoxButtons.YesNo,
        MessageBoxIcon.Question
      );

      if (dialogResult == DialogResult.Yes) {
        timer.CurrentTimingMethod = TimingMethod.GameTime;
      }
    }
  }
}

start
{
  return vars.secondIntroFmvCutscenePlayed;
}

exit
{
  // Pause Game Time in case of a game crash/exit.
  if (timer.CurrentPhase == TimerPhase.Running) {
    vars.gameExited = true;
    timer.IsGameTimePaused = true;
  }
}

update
{
  if (vars.debug) {

    // Debug output to show the HStrings of FMV cutscenes & regular in-game cinematics.
    if (vars.debugHStrings) {
      if (current.fmvCutsceneHString != 0) {
        if (current.fmvCutsceneHString != old.fmvCutsceneHString) {
          print(DateTime.Now.ToString("HH:mm:ss") + " - FMV Cutscene: " + current.fmvCutsceneHString.ToString("X"));
        }
      }

      if (current.ingameCinematicHString != 0) {
        if (current.ingameCinematicHString != old.ingameCinematicHString) {
          print(DateTime.Now.ToString("HH:mm:ss") + " - In-game Cinematic: " + current.ingameCinematicHString.ToString("X"));
        }
      }
    }

    if (vars.debugPlayerPosition) {
      print("Player Position (X/Y/Z): " + current.playerX + "/" + current.playerY + "/" + current.playerZ + ", Player Rotation (X/Y): " + current.playerRotationX + "/" + current.playerRotationY);
    }
  }

  // Resume the timer once the main menu is shown after a restart of the game. As unfortunate as crashes may be, we have to add a time
  // penalty (in form of the main menu being counted) to avoid game exit abuse.
  if (vars.gameExited && timer.IsGameTimePaused && current.playingFmvCutscene && current.fmvCutsceneHString == vars.XboxLegalFmvCutsceneHString) {
    vars.gameExited = false;
    timer.IsGameTimePaused = false;
  }

  // Detect the end of the second intro cutscene.
  if (old.fmvCutsceneHString != current.fmvCutsceneHString && old.fmvCutsceneHString == vars.IntroPartTwoFmvCutsceneHString) {
    vars.secondIntroFmvCutscenePlayed = true;
  }

  // Pause/unpause stopwatch if the player pauses within a splittable cutscene.
  if (vars.stopwatch.IsRunning || vars.pausedStopwatch) {
    if (current.pausing) {
      vars.pausedStopwatch = true;
      vars.stopwatch.Stop();
    } else {
      vars.pausedStopwatch = false;
      vars.stopwatch.Start();
    }
  }
}

isLoading
{
  if (vars.gameExited) {
    return true;
  } else {
    bool loadingSave = (current.scaleformHString == vars.SaveLoadingScaleformHString || current.scaleformHString == vars.WmEInitialLoadingScaleformHString);

    bool loadingNewArea = false;
    if (vars.lastProcessName == "darksiders1") {
      loadingNewArea = !current.loadingNewArea && !current.pausing && !current.playingFmvCutscene
        && !vars.LoadingNewAreaExceptions.Contains(current.scaleformHString);
    } else {
      loadingNewArea = !current.loadingNewArea && !loadingSave && !current.pausing && !current.playingFmvCutscene
        && !vars.LoadingNewAreaExceptions.Contains(current.scaleformHString);
    }

    return current.savingViaMenu || loadingSave || loadingNewArea;
  }
}

split
{
  if (!vars.stopwatch.IsRunning && !vars.pausedStopwatch) {
    ulong hString = 0;
    if (current.fmvCutsceneHString != old.fmvCutsceneHString && vars.filteredSplittableCutscenes.ContainsKey(current.fmvCutsceneHString)) {
      hString = current.fmvCutsceneHString;
    } else if (current.ingameCinematicHString != old.ingameCinematicHString && vars.filteredSplittableCutscenes.ContainsKey(current.ingameCinematicHString)) {
      hString = current.ingameCinematicHString;
    }

    // Split for FMV cutscenes & regular in-game cinematics.
    if (hString != 0) {
      var tuple = vars.filteredSplittableCutscenes[hString];
      string identifier = tuple.Item2;
      int segmentId = tuple.Item1;

      if (settings[identifier] && timer.CurrentSplitIndex <= segmentId) {
        int delayInMs = tuple.Item3;
        vars.currentSplitDelay = delayInMs;

        vars.stopwatch.Start();
      }
    }

    // Split for special in-game cinematics that we can only detect through player position/rotation.
    List<Tuple<int, string, int, bool, float[]>> segments = null;
    if (vars.filteredSplittablePlayerPositions.TryGetValue(current.spawnRegion, out segments)) {
      foreach (var segment in segments) {
        int segmentId = segment.Item1;
        string identifier = segment.Item2;
        bool alreadySplit = segment.Item4;

        if (settings[identifier] && !alreadySplit && timer.CurrentSplitIndex <= segmentId) {
          var playerPosition = segment.Item5;
          float delta = playerPosition[5];

          if (vars.compareFloats(current.playerX, playerPosition[0], delta) && vars.compareFloats(current.playerY, playerPosition[1], delta)
            && vars.compareFloats(current.playerZ, playerPosition[2], delta) && vars.compareFloats(current.playerRotationX, playerPosition[3], delta)
            && vars.compareFloats(current.playerRotationY, playerPosition[4], delta)) {
              vars.currentSplitDelay = segment.Item3;

              vars.stopwatch.Start();
              break;
          }
        }
      }
    }
  }

  if (vars.stopwatch.IsRunning && vars.stopwatch.ElapsedMilliseconds >= vars.currentSplitDelay) {
    vars.stopwatch.Reset();

    return true;
  }
}
