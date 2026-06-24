class MaterialItem {
  final String name;
  final double price;
  final List<String> relatedProblems;

  MaterialItem({required this.name, required this.price, this.relatedProblems = const []});
}

class MaterialDatabase {
  static Map<String, List<MaterialItem>> categoryMaterials = {
    'Fan': [
      MaterialItem(name: 'Capacitor (2.5 mfd)', price: 150, relatedProblems: ['Fan slow', 'Fan not working']),
      MaterialItem(name: 'Fan Bearing (Set)', price: 350, relatedProblems: ['Noise issue', 'Fan slow']),
      MaterialItem(name: 'Stator Rewinding', price: 850, relatedProblems: ['Fan not working', 'Burning smell']),
      MaterialItem(name: 'Regulator (Modular)', price: 250, relatedProblems: ['Speed control issue']),
      MaterialItem(name: 'Fan Blade Set', price: 450, relatedProblems: ['Broken blade']),
      MaterialItem(name: 'Downrod (1 ft)', price: 180),
      MaterialItem(name: 'Shackle Kit', price: 80),
    ],
    'AC': [
      MaterialItem(name: 'Gas Charging (R32)', price: 2500, relatedProblems: ['Not cooling']),
      MaterialItem(name: 'Gas Charging (R410)', price: 2800, relatedProblems: ['Not cooling']),
      MaterialItem(name: 'Capacitor (45 mfd)', price: 550, relatedProblems: ['Compressor not starting']),
      MaterialItem(name: 'Indoor Fan Motor', price: 1800, relatedProblems: ['Noise issue', 'No air flow']),
      MaterialItem(name: 'PCB Repair', price: 1200, relatedProblems: ['Not turning on', 'Error code']),
      MaterialItem(name: 'Remote Control', price: 450),
      MaterialItem(name: 'Drain Pipe (meter)', price: 120, relatedProblems: ['Water leakage']),
    ],
    'Washing Machine': [
      MaterialItem(name: 'Inlet Valve', price: 450, relatedProblems: ['Water not filling']),
      MaterialItem(name: 'Drain Pump', price: 850, relatedProblems: ['Water not draining']),
      MaterialItem(name: 'Washing Machine Belt', price: 350, relatedProblems: ['Drum not rotating']),
      MaterialItem(name: 'Door Lock Switch', price: 650, relatedProblems: ['Door error']),
      MaterialItem(name: 'Pulsator', price: 1200, relatedProblems: ['Not washing properly']),
      MaterialItem(name: 'Capacitor (10+5 mfd)', price: 450),
    ],
    'Refrigerator': [
      MaterialItem(name: 'Relay & Overload Protector', price: 450, relatedProblems: ['Compressor not starting']),
      MaterialItem(name: 'Thermostat', price: 550, relatedProblems: ['Too much cooling', 'Not cooling']),
      MaterialItem(name: 'Gas Charging', price: 1800, relatedProblems: ['Not cooling']),
      MaterialItem(name: 'Door Gasket', price: 850, relatedProblems: ['Door not closing']),
      MaterialItem(name: 'Internal LED Bulb', price: 150),
    ],
    'Plumbing': [
      MaterialItem(name: 'Tap Spindle', price: 150, relatedProblems: ['Tap leaking']),
      MaterialItem(name: 'Wall Mixer Kit', price: 850, relatedProblems: ['Mixer issue']),
      MaterialItem(name: 'Flush Tank Kit', price: 750, relatedProblems: ['Flush not working']),
      MaterialItem(name: 'Connection Pipe', price: 180),
      MaterialItem(name: 'PVC Solvent (Small)', price: 50),
    ],
    'Electrical': [
      MaterialItem(name: 'Modular Switch (6A)', price: 45, relatedProblems: ['Switch broken']),
      MaterialItem(name: 'Modular Socket (6/16A)', price: 85, relatedProblems: ['Socket sparking']),
      MaterialItem(name: 'MCB (Single Pole)', price: 250, relatedProblems: ['MCB tripping']),
      MaterialItem(name: 'Bulb Holder', price: 60),
      MaterialItem(name: 'Copper Wire (per meter)', price: 45),
    ],
    'Painting': [
      MaterialItem(name: 'Emulsion Paint (1L)', price: 450),
      MaterialItem(name: 'Wall Putty (5kg)', price: 250),
      MaterialItem(name: 'Primer (1L)', price: 220),
      MaterialItem(name: 'Paint Brush/Roller', price: 150),
      MaterialItem(name: 'Sandpaper (Set)', price: 50),
    ],
    'Cleaning': [
      MaterialItem(name: 'Cleaning Chemical (Pro)', price: 350),
      MaterialItem(name: 'Glass Cleaner', price: 120),
      MaterialItem(name: 'Kitchen Cleaner', price: 250),
      MaterialItem(name: 'Microfiber Cloth Set', price: 180),
    ],
  };

  static List<MaterialItem> getSuggestedMaterials(String category, List<String> problems) {
    String normalized = category.toLowerCase();
    String key = 'General';
    
    if (normalized.contains('fan')) key = 'Fan';
    else if (normalized.contains('ac')) key = 'AC';
    else if (normalized.contains('washing')) key = 'Washing Machine';
    else if (normalized.contains('fridge') || normalized.contains('refrigerator')) key = 'Refrigerator';
    else if (normalized.contains('plumb') || normalized.contains('tap')) key = 'Plumbing';
    else if (normalized.contains('electric') || normalized.contains('wire') || normalized.contains('switch')) key = 'Electrical';
    else if (normalized.contains('paint')) key = 'Painting';
    else if (normalized.contains('clean')) key = 'Cleaning';

    List<MaterialItem> categoryList = categoryMaterials[key] ?? [];
    if (problems.isEmpty) return categoryList;

    // Sort so that items related to problems come first
    List<MaterialItem> suggested = [];
    List<MaterialItem> others = [];

    for (var item in categoryList) {
      bool isRelated = item.relatedProblems.any((p) => problems.any((cp) => cp.toLowerCase().contains(p.toLowerCase()) || p.toLowerCase().contains(cp.toLowerCase())));
      if (isRelated) {
        suggested.add(item);
      } else {
        others.add(item);
      }
    }

    return [...suggested, ...others];
  }
}
