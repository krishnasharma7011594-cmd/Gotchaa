// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Gotchaa';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get close => 'Close';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get search => 'Search';

  @override
  String get clear => 'Clear';

  @override
  String get share => 'Share';

  @override
  String get report => 'Report';

  @override
  String get block => 'Block';

  @override
  String get unblock => 'Unblock';

  @override
  String get follow => 'Follow';

  @override
  String get unfollow => 'Unfollow';

  @override
  String get send => 'Send';

  @override
  String get receive => 'Receive';

  @override
  String get upload => 'Upload';

  @override
  String get download => 'Download';

  @override
  String get signUp => 'Sign Up';

  @override
  String get logIn => 'Log In';

  @override
  String get logOut => 'Log Out';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Enter your email address';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get displayName => 'Display Name';

  @override
  String get displayNameHint => 'What should we call you?';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordSent =>
      'Password reset email sent. Check your inbox.';

  @override
  String get alreadyHaveAccount => 'Already have an account? Log In';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign Up';

  @override
  String get termsAgreement =>
      'By signing up you agree to our Terms of Service and Privacy Policy';

  @override
  String get emailInvalid => 'Please enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get emailAlreadyInUse => 'This email is already registered';

  @override
  String get userNotFound => 'No account found with this email';

  @override
  String get wrongPassword => 'Incorrect password';

  @override
  String get networkError => 'Network error. Please check your connection';

  @override
  String get signUpSuccess => 'Welcome to Gotchaa! 🎉';

  @override
  String get logInSuccess => 'Welcome back! 👋';

  @override
  String get selectYourCountry => 'Select your country';

  @override
  String detectedCountry(String country) {
    return 'We detected you are from $country';
  }

  @override
  String get changeCountry => 'Change';

  @override
  String get countrySearch => 'Search countries...';

  @override
  String get countryNotFound => 'Country not found';

  @override
  String travellingBanner(String country) {
    return '✈️ Travelling in $country?';
  }

  @override
  String get home => 'Home';

  @override
  String get feed => 'Feed';

  @override
  String get noPostsYet => 'No posts yet. Be the first! 🚀';

  @override
  String get loadingFeed => 'Loading your feed...';

  @override
  String get refreshFeed => 'Pull to refresh';

  @override
  String get nearbyPosts => 'Nearby';

  @override
  String get countryPosts => 'My Country';

  @override
  String get worldwidePosts => 'Worldwide';

  @override
  String get createPost => 'Create Post';

  @override
  String get whatsOnYourMind => 'What\'s on your mind?';

  @override
  String get addLocation => 'Add location';

  @override
  String get removeLocation => 'Remove location';

  @override
  String locationTagged(String location) {
    return '📍 $location';
  }

  @override
  String get postPublished => 'Post published! 🎉';

  @override
  String get postDeleted => 'Post deleted';

  @override
  String get postReported => 'Post reported. Thank you.';

  @override
  String get likePost => 'Like';

  @override
  String get unlikePost => 'Unlike';

  @override
  String get commentOnPost => 'Comment';

  @override
  String get sharePost => 'Share';

  @override
  String get deletePost => 'Delete Post';

  @override
  String get confirmDeletePost => 'Are you sure you want to delete this post?';

  @override
  String likesCount(int count) {
    return '$count likes';
  }

  @override
  String commentsCount(int count) {
    return '$count comments';
  }

  @override
  String get camera => 'Camera';

  @override
  String get filters => 'Filters';

  @override
  String get noFilter => 'No Filter';

  @override
  String get filterIntensity => 'Intensity';

  @override
  String get capturePhoto => 'Take Photo';

  @override
  String get captureVideo => 'Record Video';

  @override
  String get switchCamera => 'Switch Camera';

  @override
  String get flashOn => 'Flash On';

  @override
  String get flashOff => 'Flash Off';

  @override
  String filterApplied(String filter) {
    return '$filter filter applied';
  }

  @override
  String get shakeTrigger => 'Shake for glitch effect! 📳';

  @override
  String get tiltForEffect => 'Tilt phone for effect 📱';

  @override
  String get messages => 'Messages';

  @override
  String get newMessage => 'New Message';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get messageSent => 'Sent';

  @override
  String get messageDelivered => 'Delivered';

  @override
  String get messageRead => 'Read';

  @override
  String get messageExpired => '💨 This message has disappeared';

  @override
  String get messagesDisappear => '🔥 Messages disappear after 24 hours';

  @override
  String get messagePolicy => 'Message Policy';

  @override
  String get messagePolicyTitle => 'Disappearing Messages';

  @override
  String get messagePolicyBody =>
      'Messages in Gotchaa automatically disappear after 24 hours. Reported content may be stored for up to 30 days.';

  @override
  String get gotIt => 'Got it ✓';

  @override
  String get screenshotDetected => '⚠️ Screenshot detected';

  @override
  String screenshotTaken(String name) {
    return '⚠️ $name took a screenshot';
  }

  @override
  String messageCountdown(String time) {
    return '🔥 $time left';
  }

  @override
  String messageExpiringHours(int hours, int minutes) {
    return '${hours}h ${minutes}m left';
  }

  @override
  String messageExpiringMinutes(int minutes, int seconds) {
    return '${minutes}m ${seconds}s left';
  }

  @override
  String messageExpiringSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get e2eeEnabled => '🔒 End-to-end encrypted';

  @override
  String get e2eeVerified => '✅ Encryption verified';

  @override
  String get e2eeWarning => '⚠️ Encryption not verified';

  @override
  String get verifyEncryption => 'Verify Encryption';

  @override
  String get safetyNumber => 'Safety Number';

  @override
  String get encryptionInfo =>
      'Messages are secured with end-to-end encryption. Only you and the recipient can read them.';

  @override
  String get randomChat => 'Random Chat';

  @override
  String get randomVideo => 'Random Video';

  @override
  String get findingMatch => 'Finding someone to talk to...';

  @override
  String searchingIn(String scope) {
    return '🔍 Searching in $scope';
  }

  @override
  String expandingSearch(String scope) {
    return '🔍 Expanding search to $scope...';
  }

  @override
  String get connected => 'Connected!';

  @override
  String connectedWith(String country, String flag) {
    return 'Connected with someone from $country $flag';
  }

  @override
  String get sessionEnded => 'Session ended';

  @override
  String get endSession => 'End Chat';

  @override
  String get nextPerson => 'Next';

  @override
  String get keepTalking => 'Keep Talking 💬';

  @override
  String get keepTalkingWaiting =>
      'Waiting to see if they want to keep talking... ⏳';

  @override
  String get keepTalkingPrompt => 'They want to keep talking with you! 💬';

  @override
  String get keepTalkingAccept => 'Keep Talking 💬';

  @override
  String get keepTalkingDecline => 'Maybe Later';

  @override
  String get mutualMatchTitle => 'You both want to keep talking! 🎉';

  @override
  String get mutualMatchSubtitle => 'Starting your conversation...';

  @override
  String get anonymous => 'Anonymous 👤';

  @override
  String get somewhereOnEarth => '🌍 Somewhere on Earth';

  @override
  String speaksLanguage(String language) {
    return '🗣️ $language speaker';
  }

  @override
  String bothSpeakLanguage(String language) {
    return '🗣️ You both speak $language';
  }

  @override
  String differentLanguages(String language) {
    return '🗣️ They speak $language • Use simple words';
  }

  @override
  String get enableTranslation => '🌐 Enable auto-translate?';

  @override
  String get sessionMonitored => 'This session may be monitored for safety';

  @override
  String get minimumSessionTime =>
      'Chat for a bit before connecting permanently';

  @override
  String get games => 'Games';

  @override
  String get playGame => 'Play a Game';

  @override
  String gameInvite(String name, String game) {
    return '$name wants to play $game!';
  }

  @override
  String get gameResult => 'Game Over!';

  @override
  String get youWon => 'You won! 🏆';

  @override
  String get youLost => 'Better luck next time! 💪';

  @override
  String get gameDraw => 'It\'s a draw! 🤝';

  @override
  String get rematch => 'Rematch';

  @override
  String get postGamePrompt => 'Great game! Want to keep talking? 💬';

  @override
  String metViaGame(String game) {
    return 'You both matched after a game of $game! 🎮🎉';
  }

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get displayNameLabel => 'Display Name';

  @override
  String get bioLabel => 'Bio';

  @override
  String get bioHint => 'Tell people about yourself...';

  @override
  String get profilePhoto => 'Profile Photo';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String memberSince(String date) {
    return 'Member since $date';
  }

  @override
  String connectionsCount(int count) {
    return '💬 $count connections made through Gotchaa';
  }

  @override
  String get metViaRandomChat => 'Met via random chat';

  @override
  String get metViaRandomVideo => 'Met via random video';

  @override
  String metViaRandomGame(String game) {
    return 'Met via a game of $game';
  }

  @override
  String metAgo(String time) {
    return '$time ago';
  }

  @override
  String travellingIn(String country) {
    return '✈️ Currently in $country';
  }

  @override
  String get newConnectionTitle => 'New Connection! 💬';

  @override
  String get newConnectionBody => 'You have a new connection waiting!';

  @override
  String get keepTalkingNotifTitle => 'Someone wants to keep talking! 💬';

  @override
  String get keepTalkingNotifBody =>
      'You have 30 seconds to respond before the moment passes';

  @override
  String get screenshotNotifTitle => 'Screenshot Alert ⚠️';

  @override
  String screenshotNotifBody(String name) {
    return '$name took a screenshot of your chat';
  }

  @override
  String get weeklyStatsTitle => 'Your Gotchaa week 🎉';

  @override
  String weeklyStatsBody(int count) {
    return 'This week you made $count new connections!';
  }

  @override
  String get reportTitle => 'Report';

  @override
  String get reportInappropriate => '🔞 Inappropriate sexual content';

  @override
  String get reportHarassment => '😡 Harassment or bullying';

  @override
  String get reportThreat => '🔪 Threats or violence';

  @override
  String get reportMinor => '👶 Suspected minor';

  @override
  String get reportBot => '🤖 Bot or spam';

  @override
  String get reportDrugs => '💊 Drugs or illegal content';

  @override
  String get reportImage => '📸 Unsolicited image';

  @override
  String get reportImpersonation => '🎭 Impersonation';

  @override
  String get reportSubmitted =>
      'Report submitted. Thank you for keeping Gotchaa safe.';

  @override
  String get reportedContentRetention =>
      'Reported content may be stored for up to 30 days';

  @override
  String get blocked => 'User blocked';

  @override
  String get userSuspended => 'Your account has been suspended';

  @override
  String get trustScoreLow =>
      'Your safety rating is too low to use this feature';

  @override
  String get safetyRatingTrusted => '🛡️ Trusted';

  @override
  String get safetyRatingGood => '⭐ Good';

  @override
  String get safetyRatingNew => '🌱 New';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String currentLanguage(String language) {
    return 'Current: $language';
  }

  @override
  String get privacy => 'Privacy';

  @override
  String get security => 'Security';

  @override
  String get notifications => 'Notifications';

  @override
  String get about => 'About';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get confirmDeleteAccount => 'Are you sure? This cannot be undone.';

  @override
  String get accountDeleted => 'Your account has been deleted';

  @override
  String get twoFactorAuth => 'Two-Factor Authentication';

  @override
  String get twoFactorEnabled => '2FA Enabled ✅';

  @override
  String get twoFactorDisabled => '2FA Disabled';

  @override
  String get showLocationOnPosts => 'Show location on posts';

  @override
  String get locationPrecision => 'Location precision';

  @override
  String get locationPrecisionExact => 'Exact location';

  @override
  String get locationPrecisionCity => 'City only';

  @override
  String get locationPrecisionCountry => 'Country only';

  @override
  String get clearLocationHistory => 'Clear Location History';

  @override
  String get locationHistoryCleared => 'Location history cleared';

  @override
  String get nationVisibility => 'Who can see my nation';

  @override
  String get nationVisibilityCountry => 'Show my country';

  @override
  String get nationVisibilityContinent => 'Show continent only';

  @override
  String get nationVisibilityPrivate => 'Keep private';

  @override
  String get stayAnonymous => 'Stay anonymous in connections';

  @override
  String get matchPreferences => 'Match Preferences';

  @override
  String get matchWorldwide => '🌍 Worldwide';

  @override
  String get matchSameContinent => '🌎 Same Continent';

  @override
  String get matchSameCountry => '🇮🇳 Same Country';

  @override
  String get matchPreferred => '⭐ Preferred Countries';

  @override
  String get preferredCountries => 'Preferred Countries';

  @override
  String get maxPreferredCountries => 'Maximum 5 countries';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get tryAgain => 'Try again';

  @override
  String get sessionExpired => 'Your session has expired. Please log in again.';

  @override
  String get featureUnavailable =>
      'This feature is not available on your device';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get cameraPermissionNeeded =>
      'Camera permission is required for this feature';

  @override
  String get locationPermissionNeeded =>
      'Location permission is required to tag your location';

  @override
  String get microphonePermissionNeeded =>
      'Microphone permission is required for voice chat';

  @override
  String get noConnectionsYet => 'No connections yet. Start chatting! 💬';

  @override
  String get noMessagesYet => 'No messages yet. Say hello! 👋';

  @override
  String get connectionNotFound => 'Connection not found';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String weeksAgo(int count) {
    return '${count}w ago';
  }

  @override
  String get systemMessageConnected =>
      '🎉 You two connected through Gotchaa random chat! Start your conversation below 👇';

  @override
  String get systemMessageConnectedVideo =>
      '🎉 You two connected through Gotchaa random video! Start your conversation below 👇';

  @override
  String systemMessageConnectedGame(String game) {
    return '🎉 You connected after a game of $game! Start your conversation below 👇';
  }

  @override
  String get onboardingTitle1 => 'Talk to the World 🌍';

  @override
  String get onboardingBody1 =>
      'Connect with real people from every country instantly';

  @override
  String get onboardingTitle2 => 'Safe and Private 🔒';

  @override
  String get onboardingBody2 =>
      'End-to-end encrypted. Messages disappear after 24 hours.';

  @override
  String get onboardingTitle3 => 'Keep the ones you like 💬';

  @override
  String get onboardingBody3 =>
      'Both enjoy the chat? Connect permanently with one tap.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get alreadyMember => 'Already a member? Log In';

  @override
  String get following => 'Following';

  @override
  String get forYou => 'For You';

  @override
  String get nearby => 'Nearby';

  @override
  String get notFollowingYet => 'You are not following anyone yet';

  @override
  String get discoverPeople => 'Discover People';

  @override
  String get suggestedForYou => 'Suggested for you';

  @override
  String postsFromCountry(String country, String flag) {
    return 'Posts from $country $flag';
  }

  @override
  String get vybzTitle => 'Vybz';

  @override
  String get trendingTitle => 'Trending';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get saveTo => 'Save to...';

  @override
  String get saved => 'Saved';

  @override
  String get inspiration => 'Inspiration';

  @override
  String get recipes => 'Recipes';

  @override
  String get travel => 'Travel';

  @override
  String get createNewCollection => 'Create new collection';

  @override
  String get collectionName => 'Collection name';

  @override
  String removeFromCollection(String collection) {
    return 'Remove from $collection?';
  }

  @override
  String get moveTo => 'Move to...';

  @override
  String get shareTo => 'Share to...';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get sendToConnection => 'Send to Gotchaa connection';

  @override
  String shareText(String link) {
    return 'Check out this post on Gotchaa! $link';
  }

  @override
  String sharesCount(int count) {
    return '$count shares';
  }

  @override
  String get reply => 'Reply';

  @override
  String viewAllComments(int count) {
    return 'View all $count comments';
  }

  @override
  String get commentRemoved => 'Comment removed';

  @override
  String replyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get peopleYouMayKnow => 'People you may know';

  @override
  String get all => 'All';

  @override
  String get art => 'Art';

  @override
  String get tech => 'Tech';

  @override
  String get lifestyle => 'Lifestyle';

  @override
  String get food => 'Food';

  @override
  String get music => 'Music';

  @override
  String get hashtags => 'Hashtags';

  @override
  String get posts => 'Posts';

  @override
  String get users => 'Users';

  @override
  String postsCount(int count) {
    return '$count posts';
  }

  @override
  String searchQuery(String query) {
    return 'Search \"$query\"';
  }

  @override
  String get noResultsFound => 'No results found';

  @override
  String get newPostsAvailable => 'New posts available';

  @override
  String get notInterested => 'Not interested';
}
