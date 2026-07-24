import 'package:flutter_test/flutter_test.dart';
import 'package:sbg_profesores/utils/class_rules.dart';

void main() {
  group('reglas de modificación de clases', () {
    test('solo una clase activa puede modificarse', () {
      expect(classCanBeModified('activa'), isTrue);
      expect(classCanBeModified(' ACTIVA '), isTrue);
      expect(classCanBeModified('hecha'), isFalse);
      expect(classCanBeModified('cancelada'), isFalse);
      expect(classCanBeModified('no hecha'), isFalse);
      expect(classCanBeModified('reprogramada'), isFalse);
    });

    test('la eliminación exige el nombre exacto del curso', () {
      expect(
        classDeletionNameMatches(
          expectedName: 'Matemática',
          enteredName: 'Matemática',
        ),
        isTrue,
      );
      expect(
        classDeletionNameMatches(
          expectedName: 'Matemática',
          enteredName: 'matemática',
        ),
        isFalse,
      );
      expect(
        classDeletionNameMatches(
          expectedName: 'Matemática',
          enteredName: 'Matemática avanzada',
        ),
        isFalse,
      );
    });
  });

  group('duraciones de clase', () {
    test('incluye y convierte las nuevas duraciones', () {
      expect(classDurationOptions, containsAll(['165', '180', '210']));
      expect(parseClassDurationMinutes('165'), 165);
      expect(parseClassDurationMinutes('180'), 180);
      expect(parseClassDurationMinutes('210'), 210);
    });

    test('mantiene 60 minutos como valor seguro', () {
      expect(parseClassDurationMinutes('duración inválida'), 60);
    });
  });
}
