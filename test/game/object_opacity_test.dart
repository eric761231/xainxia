import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/iso_map_data.dart';
import 'package:xianxia_game/game/map/iso_object_catalog.dart';
import 'package:xianxia_game/game/map/iso_object_component.dart';

void main() {
  test(
    'moving furniture and its independent shadow fade and restore together',
    () async {
      final root = Component();
      final object = IsoObjectComponent(
        def: ObjectDef.fromJson(1, {
          'image': 'test.png',
          'shadow': {'opacity': 0.3},
        }),
        tileX: 31,
        tileY: 31,
        zBias: 0,
        mapData: IsoMapData.generic(minCoord: 31, maxCoord: 40),
        graphic: null,
      );
      await root.add(object);
      await object.onLoad();
      final shadow = root.children
          .whereType<IsoFootprintShadowComponent>()
          .single;
      expect(shadow.opacity, 1);
      object.opacity = 0.4;
      expect(shadow.opacity, 0.4);
      object.opacity = 1;
      expect(shadow.opacity, 1);
      expect(
        shadow.def.shadow.opacity,
        0.3,
        reason: 'material shadow opacity must not be overwritten',
      );
    },
  );
}
