import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/features/ai/domain/models/bro_tool_call.dart';
import 'package:gotchaa/features/ai/domain/tools/bro_tool_registry.dart';

void main() {
  group('ScreenRegistry & AppRegistry Tests', () {
    test('ScreenRegistry matches exact ID and aliases', () {
      final homeMatch = ScreenRegistry.match('home');
      expect(homeMatch?.id, 'home');

      final walletMatch = ScreenRegistry.match('my wallet');
      expect(walletMatch?.id, 'wallet');

      final noneMatch = ScreenRegistry.match('non_existent_screen');
      expect(noneMatch, isNull);
    });

    test('AppRegistry matches exact ID and aliases', () {
      final spotifyMatch = AppRegistry.match('spotify');
      expect(spotifyMatch?.id, 'spotify');
      expect(spotifyMatch?.deepLinkUrl, 'spotify://');

      final cabMatch = AppRegistry.match('cab');
      expect(cabMatch?.id, 'uber');

      final noneMatch = AppRegistry.match('banana_app');
      expect(noneMatch, isNull);
    });
  });

  group('FastRuleEngine Deterministic Matching Tests', () {
    test('Matches direct commands like wallet or uber', () {
      final walletCall = FastRuleEngine.evaluate('wallet');
      expect(walletCall, isA<BroNavigateCall>());
      expect((walletCall as BroNavigateCall).screen, 'wallet');
      expect(walletCall.confidence, 1.0);

      final uberCall = FastRuleEngine.evaluate('uber');
      expect(uberCall, isA<BroDeepLinkCall>());
      expect((uberCall as BroDeepLinkCall).app, 'Uber');
      expect(uberCall.url, 'uber://');
    });

    test('Matches prefix commands with filler words removed', () {
      final openWalletCall = FastRuleEngine.evaluate('open my wallet');
      expect(openWalletCall, isA<BroNavigateCall>());
      expect((openWalletCall as BroNavigateCall).screen, 'wallet');

      final goChatCall = FastRuleEngine.evaluate('go to chat');
      expect(goChatCall, isA<BroNavigateCall>());
      expect((goChatCall as BroNavigateCall).screen, 'chat');

      final launchSpotifyCall = FastRuleEngine.evaluate('launch Spotify');
      expect(launchSpotifyCall, isA<BroDeepLinkCall>());
      expect((launchSpotifyCall as BroDeepLinkCall).app, 'Spotify');
    });

    test('Returns null for conversational or ambiguous queries', () {
      final greeting = FastRuleEngine.evaluate('hello bro');
      expect(greeting, isNull);

      final question = FastRuleEngine.evaluate('what is the meaning of life?');
      expect(question, isNull);
    });
  });

  group('NavigationHistory Tracker Tests', () {
    test('Records navigation history events correctly', () {
      NavigationHistory.record('home');
      NavigationHistory.record('chat');
      NavigationHistory.record('wallet');

      final history = NavigationHistory.history;
      expect(history.length, greaterThanOrEqualTo(3));
      expect(history.last, 'wallet');
    });
  });
}
