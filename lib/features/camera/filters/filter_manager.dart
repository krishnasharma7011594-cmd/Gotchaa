import 'package:flutter/foundation.dart';

enum FilterCategory { colorGrade, faceAR, particle, background, motion, viral }

class FilterDefinition {

  FilterDefinition({
    required this.id, required this.name, required this.iconAsset, required this.category,
    this.shaderPath, this.particleType, this.bgImageAsset, this.stickerAsset, this.previewAsset
  });
  final String id;
  final String name;
  final String iconAsset;
  final FilterCategory category;
  
  // Custom properties
  final String? shaderPath;
  final String? particleType; 
  final String? bgImageAsset;
  final String? stickerAsset;
  final String? previewAsset;
}

class FilterManager extends ChangeNotifier {
  factory FilterManager() => _instance;
  FilterManager._();
  static final FilterManager _instance = FilterManager._();

  FilterCategory selectedCategory = FilterCategory.viral;

  void setCategory(FilterCategory cat) {
    selectedCategory = cat;
    notifyListeners();
  }

  List<FilterDefinition> get filteredFilters => allFilters.where((f) => f.category == selectedCategory).toList();

  // The 50 Premium Filters
  final List<FilterDefinition> allFilters = [
      // --- COLOR GRADE (10) ---
      FilterDefinition(id: 'c_noir', name: 'Noir', iconAsset: 'assets/icons/f_noir.png', category: FilterCategory.colorGrade, shaderPath: 'assets/shaders/noir.frag', previewAsset: 'assets/filter_previews/noir.png'),
      FilterDefinition(id: 'c_golden', name: 'Golden Hour', iconAsset: 'assets/icons/f_golden.png', category: FilterCategory.colorGrade, shaderPath: 'assets/shaders/golden_hour.frag', previewAsset: 'assets/filter_previews/golden.png'),
      FilterDefinition(id: 'c_arctic', name: 'Arctic', iconAsset: 'assets/icons/f_arctic.png', category: FilterCategory.colorGrade, shaderPath: 'assets/shaders/arctic.frag', previewAsset: 'assets/filter_previews/arctic.png'),
      FilterDefinition(id: 'c_faded', name: 'Faded', iconAsset: 'assets/icons/f_faded.png', category: FilterCategory.colorGrade, shaderPath: 'assets/shaders/faded.frag', previewAsset: 'assets/filter_previews/faded.png'),
      FilterDefinition(id: 'c_vivid', name: 'Vivid', iconAsset: 'assets/icons/f_vivid.png', category: FilterCategory.colorGrade, shaderPath: 'assets/shaders/vivid.frag', previewAsset: 'assets/filter_previews/vivid.png'),
      FilterDefinition(id: 'c_retro', name: 'Retro', iconAsset: 'assets/icons/f_retro.png', category: FilterCategory.colorGrade, shaderPath: 'assets/shaders/retro.frag', previewAsset: 'assets/filter_previews/retro.png'),
      FilterDefinition(id: 'c_film', name: 'Film', iconAsset: 'assets/icons/f_film.png', category: FilterCategory.colorGrade, shaderPath: 'assets/shaders/film.frag', previewAsset: 'assets/filter_previews/film.png'),
      FilterDefinition(id: 'c_pastel', name: 'Pastel', iconAsset: 'assets/icons/f_pastel.png', category: FilterCategory.colorGrade, shaderPath: 'assets/shaders/pastel.frag', previewAsset: 'assets/filter_previews/pastel.png'),
      FilterDefinition(id: 'c_sunset', name: 'Sunset', iconAsset: 'assets/icons/f_sunset.png', category: FilterCategory.colorGrade, shaderPath: 'assets/shaders/sunset.frag', previewAsset: 'assets/filter_previews/sunset.png'),
      FilterDefinition(id: 'c_moody', name: 'Moody', iconAsset: 'assets/icons/f_moody.png', category: FilterCategory.colorGrade, shaderPath: 'assets/shaders/moody.frag', previewAsset: 'assets/filter_previews/moody.png'),

      // --- FACE AR & BEAUTY (10) ---
      FilterDefinition(id: 'f_cyber', name: 'Cyber Glow', iconAsset: 'assets/icons/f_cyber.png', category: FilterCategory.faceAR, previewAsset: 'assets/filter_previews/cyber.png'),
      FilterDefinition(id: 'f_aura', name: 'Mood Aura', iconAsset: 'assets/icons/f_aura.png', category: FilterCategory.faceAR, previewAsset: 'assets/filter_previews/aura.png'),
      FilterDefinition(id: 'f_drip', name: 'Drip Crown', iconAsset: 'assets/icons/f_drip.png', category: FilterCategory.faceAR, stickerAsset: 'assets/stickers/drip_crown.png', previewAsset: 'assets/filter_previews/drip.png'),
      FilterDefinition(id: 'f_eye', name: 'Eye Ember', iconAsset: 'assets/icons/f_eye.png', category: FilterCategory.faceAR, previewAsset: 'assets/filter_previews/eye.png'),
      FilterDefinition(id: 'f_soft', name: 'Soft Focus', iconAsset: 'assets/icons/f_soft.png', category: FilterCategory.faceAR, previewAsset: 'assets/filter_previews/beauty.png'),
      FilterDefinition(id: 'f_butterfly', name: 'Butterfly', iconAsset: 'assets/icons/f_butterfly.png', category: FilterCategory.faceAR, stickerAsset: 'assets/stickers/butterfly.png', previewAsset: 'assets/filter_previews/butterfly.png'),
      FilterDefinition(id: 'f_halo', name: 'Halo', iconAsset: 'assets/icons/f_halo.png', category: FilterCategory.faceAR, stickerAsset: 'assets/stickers/halo.png', previewAsset: 'assets/filter_previews/halo.png'),
      FilterDefinition(id: 'f_glam', name: 'Glamour', iconAsset: 'assets/icons/f_glam.png', category: FilterCategory.faceAR, previewAsset: 'assets/filter_previews/glamour.png'),
      FilterDefinition(id: 'f_anime', name: 'Anime', iconAsset: 'assets/icons/f_anime.png', category: FilterCategory.faceAR, previewAsset: 'assets/filter_previews/anime.png'),
      FilterDefinition(id: 'f_element', name: 'Element', iconAsset: 'assets/icons/f_element.png', category: FilterCategory.faceAR, previewAsset: 'assets/filter_previews/element.png'),

      // --- PARTICLE & ANIMATED (10) ---
      FilterDefinition(id: 'p_sakura', name: 'Sakura', iconAsset: 'assets/icons/sakura.png', category: FilterCategory.particle, particleType: 'sakura', previewAsset: 'assets/filter_previews/particle.png'),
      FilterDefinition(id: 'p_snow', name: 'Snow Globe', iconAsset: 'assets/icons/snow.png', category: FilterCategory.particle, particleType: 'snow', previewAsset: 'assets/filter_previews/particle.png'),
      FilterDefinition(id: 'p_confetti', name: 'Confetti Burst', iconAsset: 'assets/icons/confetti.png', category: FilterCategory.particle, particleType: 'confetti', previewAsset: 'assets/filter_previews/particle.png'),
      FilterDefinition(id: 'p_hearts', name: 'Floating Hearts', iconAsset: 'assets/icons/hearts.png', category: FilterCategory.particle, particleType: 'hearts', previewAsset: 'assets/filter_previews/particle.png'),
      FilterDefinition(id: 'p_lightning', name: 'Lightning Aura', iconAsset: 'assets/icons/lightning.png', category: FilterCategory.particle, particleType: 'lightning', previewAsset: 'assets/filter_previews/particle.png'),
      FilterDefinition(id: 'p_galaxy', name: 'Galaxy Portal', iconAsset: 'assets/icons/galaxy.png', category: FilterCategory.particle, particleType: 'galaxy', previewAsset: 'assets/filter_previews/particle.png'),
      FilterDefinition(id: 'p_fire', name: 'Fire Aura', iconAsset: 'assets/icons/fire.png', category: FilterCategory.particle, particleType: 'fire', previewAsset: 'assets/filter_previews/particle.png'),
      FilterDefinition(id: 'p_bubbles', name: 'Bubble Wrap', iconAsset: 'assets/icons/bubbles.png', category: FilterCategory.particle, particleType: 'bubbles', previewAsset: 'assets/filter_previews/particle.png'),
      FilterDefinition(id: 'p_matrix', name: 'Matrix Rain', iconAsset: 'assets/icons/matrix.png', category: FilterCategory.particle, particleType: 'matrix', previewAsset: 'assets/filter_previews/particle.png'),
      FilterDefinition(id: 'p_stardust', name: 'Stardust Trail', iconAsset: 'assets/icons/stardust.png', category: FilterCategory.particle, particleType: 'stardust', previewAsset: 'assets/filter_previews/particle.png'),

      // --- BACKGROUNDS (10) ---
      FilterDefinition(id: 'bg_blur', name: 'Blur BG', iconAsset: 'assets/icons/blur.png', category: FilterCategory.background, previewAsset: 'assets/filter_previews/bg.png'),
      FilterDefinition(id: 'bg_beach', name: 'Beach', iconAsset: 'assets/icons/beach.png', category: FilterCategory.background, bgImageAsset: 'assets/bgs/beach.jpg', previewAsset: 'assets/filter_previews/bg.png'),
      FilterDefinition(id: 'bg_space', name: 'Space', iconAsset: 'assets/icons/space.png', category: FilterCategory.background, bgImageAsset: 'assets/bgs/space.jpg', previewAsset: 'assets/filter_previews/bg.png'),
      FilterDefinition(id: 'bg_neon', name: 'Neon City', iconAsset: 'assets/icons/neon.png', category: FilterCategory.background, bgImageAsset: 'assets/bgs/neon.jpg', previewAsset: 'assets/filter_previews/bg.png'),
      FilterDefinition(id: 'bg_forest', name: 'Forest', iconAsset: 'assets/icons/forest.png', category: FilterCategory.background, bgImageAsset: 'assets/bgs/forest.jpg', previewAsset: 'assets/filter_previews/bg.png'),
      FilterDefinition(id: 'bg_studio', name: 'Studio Light', iconAsset: 'assets/icons/studio.png', category: FilterCategory.background, bgImageAsset: 'assets/bgs/studio.jpg', previewAsset: 'assets/filter_previews/bg.png'),
      FilterDefinition(id: 'bg_cartoon', name: 'Cartoon World', iconAsset: 'assets/icons/cartoon_bg.png', category: FilterCategory.background, shaderPath: 'assets/shaders/cartoon_bg.frag', previewAsset: 'assets/filter_previews/bg.png'),
      FilterDefinition(id: 'bg_underwater', name: 'Underwater', iconAsset: 'assets/icons/underwater.png', category: FilterCategory.background, shaderPath: 'assets/shaders/underwater.frag', previewAsset: 'assets/filter_previews/bg.png'),
      FilterDefinition(id: 'bg_lofi', name: 'Lo-Fi Room', iconAsset: 'assets/icons/lofi.png', category: FilterCategory.background, bgImageAsset: 'assets/bgs/lofi.jpg', previewAsset: 'assets/filter_previews/bg.png'),
      FilterDefinition(id: 'bg_colorpop', name: 'Color Pop', iconAsset: 'assets/icons/colorpop.png', category: FilterCategory.background, shaderPath: 'assets/shaders/desaturate_bg.frag', previewAsset: 'assets/filter_previews/bg.png'),

      // --- MOTION-RESPONSIVE & VIRAL (10) ---
      FilterDefinition(id: 'm_tilt', name: 'Tilt Drift', iconAsset: 'assets/icons/m_tilt.png', category: FilterCategory.motion, shaderPath: 'assets/shaders/tilt_drift.frag', previewAsset: 'assets/filter_previews/motion.png'),
      FilterDefinition(id: 'm_shake', name: 'Shake Glitch', iconAsset: 'assets/icons/m_shake.png', category: FilterCategory.motion, shaderPath: 'assets/shaders/shake_glitch.frag', previewAsset: 'assets/filter_previews/motion.png'),
      FilterDefinition(id: 'm_warp', name: 'Time Warp', iconAsset: 'assets/icons/m_warp.png', category: FilterCategory.motion, shaderPath: 'assets/shaders/time_warp.frag', previewAsset: 'assets/filter_previews/motion.png'),
      FilterDefinition(id: 'm_edge', name: 'Edge Glow', iconAsset: 'assets/icons/m_edge.png', category: FilterCategory.motion, shaderPath: 'assets/shaders/edge_glow.frag', previewAsset: 'assets/filter_previews/motion.png'),
      FilterDefinition(id: 'm_zoom', name: 'Zoom Pulse', iconAsset: 'assets/icons/m_zoom.png', category: FilterCategory.motion, shaderPath: 'assets/shaders/zoom_pulse.frag', previewAsset: 'assets/filter_previews/motion.png'),
      FilterDefinition(id: 'v_cartoon', name: 'AI Cartoon', iconAsset: 'assets/icons/cartoon.png', category: FilterCategory.viral, previewAsset: 'assets/filter_previews/viral.png'),
      FilterDefinition(id: 'v_aged', name: 'Aged 40 Yrs', iconAsset: 'assets/icons/aged.png', category: FilterCategory.viral, previewAsset: 'assets/filter_previews/viral.png'),
      FilterDefinition(id: 'v_baby', name: 'Baby Face', iconAsset: 'assets/icons/baby.png', category: FilterCategory.viral, previewAsset: 'assets/filter_previews/viral.png'),
      FilterDefinition(id: 'v_vogue', name: 'Vogue Cover', iconAsset: 'assets/icons/vogue.png', category: FilterCategory.viral, previewAsset: 'assets/filter_previews/viral.png'),
      FilterDefinition(id: 'v_vhs', name: 'Retro VHS', iconAsset: 'assets/icons/vhs.png', category: FilterCategory.viral, shaderPath: 'assets/shaders/vhs_retro.frag', previewAsset: 'assets/filter_previews/vhs.png'),
      FilterDefinition(id: 'v_magnify', name: 'Magnify', iconAsset: 'assets/icons/v_magnify.png', category: FilterCategory.viral, shaderPath: 'assets/shaders/magnify.frag', previewAsset: 'assets/filter_previews/viral.png'),
      FilterDefinition(id: 'v_glitch', name: 'Databending', iconAsset: 'assets/icons/v_glitch.png', category: FilterCategory.viral, previewAsset: 'assets/filter_previews/viral.png'),
      FilterDefinition(id: 'v_dreamy', name: 'Dreamy', iconAsset: 'assets/icons/v_dreamy.png', category: FilterCategory.viral, previewAsset: 'assets/filter_previews/viral.png'),
      FilterDefinition(id: 'v_pixel', name: 'Pixel Art', iconAsset: 'assets/icons/v_pixel.png', category: FilterCategory.viral, previewAsset: 'assets/filter_previews/viral.png'),
      FilterDefinition(id: 'v_neon', name: 'Neon Outlines', iconAsset: 'assets/icons/v_neon.png', category: FilterCategory.viral, previewAsset: 'assets/filter_previews/viral.png'),
  ];

  // ACTIVE STACKED FILTERS
  FilterDefinition? activeColorGrade;
  FilterDefinition? activeFaceFilter;
  FilterDefinition? activeParticle;
  FilterDefinition? activeBackground;
  FilterDefinition? activeMotion;
  FilterDefinition? activeViral;

  // Global Intensity Layer (0.0 to 1.0)
  double globalIntensity = 1;

  void applyFilter(FilterDefinition filter) {
    if (filter.id == 'none') {
        clearAll();
        return;
    }
    
    switch (filter.category) {
      case FilterCategory.colorGrade: activeColorGrade = filter; break;
      case FilterCategory.faceAR: activeFaceFilter = filter; break;
      case FilterCategory.particle: activeParticle = filter; break;
      case FilterCategory.background: activeBackground = filter; break;
      case FilterCategory.motion: activeMotion = filter; break;
      case FilterCategory.viral: activeViral = filter; break;
    }
    notifyListeners();
  }

  void clearAll() {
      activeColorGrade = null;
      activeFaceFilter = null;
      activeParticle = null;
      activeBackground = null;
      activeMotion = null;
      activeViral = null;
      notifyListeners();
  }

  void clearCategory(FilterCategory cat) {
    switch (cat) {
      case FilterCategory.colorGrade: activeColorGrade = null; break;
      case FilterCategory.faceAR: activeFaceFilter = null; break;
      case FilterCategory.particle: activeParticle = null; break;
      case FilterCategory.background: activeBackground = null; break;
      case FilterCategory.motion: activeMotion = null; break;
      case FilterCategory.viral: activeViral = null; break;
    }
    notifyListeners();
  }

  void setIntensity(double val) {
    globalIntensity = val.clamp(0.0, 1.0);
    notifyListeners();
  }
}
