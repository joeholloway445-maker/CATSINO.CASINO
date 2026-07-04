function createMorphology() {
  var root = DriveApp.getFoldersByName("Periliminal").next();
  var morph = root.createFolder("morphology");

  // Races
  var races = morph.createFolder("races");
  var raceFiles = [
    "lumenari.py","gutterkin.py","deepborne.py","ashen_choir.py","veilstriders.py",
    "chronarchs.py","nullborn.py","thorned.py","echoes.py","hollowed.py",
    "riftspawn.py","mirekin.py","sunspun.py","coldmarrow.py","pulseborn.py",
    "dreamflesh.py","crownless.py","rotweavers.py","glassborn.py","starfall.py"
  ];
  raceFiles.forEach(f => races.createFile(f,"# " + f + " placeholder\n"));

  // Frames
  var frames = morph.createFolder("frames");
  var frameFiles = [
    "skirmisher.py","strider.py","skybound.py","flicker.py","marshal.py",
    "bloom.py","rewind.py","conduit.py","shade.py","fabricator.py",
    "bastion.py","juggernaut.py","gravemind.py","riftbreaker.py","sovereign.py",
    "worldroot.py","epoch.py","overlord.py","obscura.py","architect.py"
  ];
  frameFiles.forEach(f => frames.createFile(f,"# " + f + " placeholder\n"));

  // Morphological Rigs
  var rigs = morph.createFolder("morphological_rigs");
  var rigFiles = [
    "heavy_siege.py","swiftburner.py","multi_limbed.py","towering.py","compact.py",
    "elastic.py","floating_core.py","split_form.py","inverted_spine.py","modular.py",
    "armored.py","lithe.py","tendril.py","rooted.py","hover_strider.py",
    "centroid.py","shardform.py","quadruped.py","serpentine.py","colossus.py"
  ];
  rigFiles.forEach(f => rigs.createFile(f,"# " + f + " placeholder\n"));

  Logger.log("Morphology folders and files created!");
}