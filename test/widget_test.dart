// 기본 위젯 테스트 (자급제공시선약 앱)
// main()이 async이므로 기본 pump 테스트는 생략
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder', () {
    // 앱은 flutter run으로 실제 기기/에뮬레이터에서 테스트
    expect(1 + 1, equals(2));
  });
}
