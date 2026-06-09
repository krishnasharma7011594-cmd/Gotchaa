import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Gotchaa'**
  String get appName;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollow;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get displayNameHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox.'**
  String get resetPasswordSent;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log In'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccount;

  /// No description provided for @termsAgreement.
  ///
  /// In en, this message translates to:
  /// **'By signing up you agree to our Terms of Service and Privacy Policy'**
  String get termsAgreement;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get emailAlreadyInUse;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email'**
  String get userNotFound;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get wrongPassword;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection'**
  String get networkError;

  /// No description provided for @signUpSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Gotchaa! 🎉'**
  String get signUpSuccess;

  /// No description provided for @logInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! 👋'**
  String get logInSuccess;

  /// No description provided for @selectYourCountry.
  ///
  /// In en, this message translates to:
  /// **'Select your country'**
  String get selectYourCountry;

  /// No description provided for @detectedCountry.
  ///
  /// In en, this message translates to:
  /// **'We detected you are from {country}'**
  String detectedCountry(String country);

  /// No description provided for @changeCountry.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeCountry;

  /// No description provided for @countrySearch.
  ///
  /// In en, this message translates to:
  /// **'Search countries...'**
  String get countrySearch;

  /// No description provided for @countryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Country not found'**
  String get countryNotFound;

  /// No description provided for @travellingBanner.
  ///
  /// In en, this message translates to:
  /// **'✈️ Travelling in {country}?'**
  String travellingBanner(String country);

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet. Be the first! 🚀'**
  String get noPostsYet;

  /// No description provided for @loadingFeed.
  ///
  /// In en, this message translates to:
  /// **'Loading your feed...'**
  String get loadingFeed;

  /// No description provided for @refreshFeed.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get refreshFeed;

  /// No description provided for @nearbyPosts.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearbyPosts;

  /// No description provided for @countryPosts.
  ///
  /// In en, this message translates to:
  /// **'My Country'**
  String get countryPosts;

  /// No description provided for @worldwidePosts.
  ///
  /// In en, this message translates to:
  /// **'Worldwide'**
  String get worldwidePosts;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @whatsOnYourMind.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get whatsOnYourMind;

  /// No description provided for @addLocation.
  ///
  /// In en, this message translates to:
  /// **'Add location'**
  String get addLocation;

  /// No description provided for @removeLocation.
  ///
  /// In en, this message translates to:
  /// **'Remove location'**
  String get removeLocation;

  /// No description provided for @locationTagged.
  ///
  /// In en, this message translates to:
  /// **'📍 {location}'**
  String locationTagged(String location);

  /// No description provided for @postPublished.
  ///
  /// In en, this message translates to:
  /// **'Post published! 🎉'**
  String get postPublished;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get postDeleted;

  /// No description provided for @postReported.
  ///
  /// In en, this message translates to:
  /// **'Post reported. Thank you.'**
  String get postReported;

  /// No description provided for @likePost.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get likePost;

  /// No description provided for @unlikePost.
  ///
  /// In en, this message translates to:
  /// **'Unlike'**
  String get unlikePost;

  /// No description provided for @commentOnPost.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentOnPost;

  /// No description provided for @sharePost.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get sharePost;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePost;

  /// No description provided for @confirmDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post?'**
  String get confirmDeletePost;

  /// No description provided for @likesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} likes'**
  String likesCount(int count);

  /// No description provided for @commentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} comments'**
  String commentsCount(int count);

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @noFilter.
  ///
  /// In en, this message translates to:
  /// **'No Filter'**
  String get noFilter;

  /// No description provided for @filterIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get filterIntensity;

  /// No description provided for @capturePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get capturePhoto;

  /// No description provided for @captureVideo.
  ///
  /// In en, this message translates to:
  /// **'Record Video'**
  String get captureVideo;

  /// No description provided for @switchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch Camera'**
  String get switchCamera;

  /// No description provided for @flashOn.
  ///
  /// In en, this message translates to:
  /// **'Flash On'**
  String get flashOn;

  /// No description provided for @flashOff.
  ///
  /// In en, this message translates to:
  /// **'Flash Off'**
  String get flashOff;

  /// No description provided for @filterApplied.
  ///
  /// In en, this message translates to:
  /// **'{filter} filter applied'**
  String filterApplied(String filter);

  /// No description provided for @shakeTrigger.
  ///
  /// In en, this message translates to:
  /// **'Shake for glitch effect! 📳'**
  String get shakeTrigger;

  /// No description provided for @tiltForEffect.
  ///
  /// In en, this message translates to:
  /// **'Tilt phone for effect 📱'**
  String get tiltForEffect;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get newMessage;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @messageSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get messageSent;

  /// No description provided for @messageDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get messageDelivered;

  /// No description provided for @messageRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get messageRead;

  /// No description provided for @messageExpired.
  ///
  /// In en, this message translates to:
  /// **'💨 This message has disappeared'**
  String get messageExpired;

  /// No description provided for @messagesDisappear.
  ///
  /// In en, this message translates to:
  /// **'🔥 Messages disappear after 24 hours'**
  String get messagesDisappear;

  /// No description provided for @messagePolicy.
  ///
  /// In en, this message translates to:
  /// **'Message Policy'**
  String get messagePolicy;

  /// No description provided for @messagePolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Disappearing Messages'**
  String get messagePolicyTitle;

  /// No description provided for @messagePolicyBody.
  ///
  /// In en, this message translates to:
  /// **'Messages in Gotchaa automatically disappear after 24 hours. Reported content may be stored for up to 30 days.'**
  String get messagePolicyBody;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it ✓'**
  String get gotIt;

  /// No description provided for @screenshotDetected.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Screenshot detected'**
  String get screenshotDetected;

  /// No description provided for @screenshotTaken.
  ///
  /// In en, this message translates to:
  /// **'⚠️ {name} took a screenshot'**
  String screenshotTaken(String name);

  /// No description provided for @messageCountdown.
  ///
  /// In en, this message translates to:
  /// **'🔥 {time} left'**
  String messageCountdown(String time);

  /// No description provided for @messageExpiringHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m left'**
  String messageExpiringHours(int hours, int minutes);

  /// No description provided for @messageExpiringMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s left'**
  String messageExpiringMinutes(int minutes, int seconds);

  /// No description provided for @messageExpiringSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String messageExpiringSeconds(int seconds);

  /// No description provided for @e2eeEnabled.
  ///
  /// In en, this message translates to:
  /// **'🔒 End-to-end encrypted'**
  String get e2eeEnabled;

  /// No description provided for @e2eeVerified.
  ///
  /// In en, this message translates to:
  /// **'✅ Encryption verified'**
  String get e2eeVerified;

  /// No description provided for @e2eeWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Encryption not verified'**
  String get e2eeWarning;

  /// No description provided for @verifyEncryption.
  ///
  /// In en, this message translates to:
  /// **'Verify Encryption'**
  String get verifyEncryption;

  /// No description provided for @safetyNumber.
  ///
  /// In en, this message translates to:
  /// **'Safety Number'**
  String get safetyNumber;

  /// No description provided for @encryptionInfo.
  ///
  /// In en, this message translates to:
  /// **'Messages are secured with end-to-end encryption. Only you and the recipient can read them.'**
  String get encryptionInfo;

  /// No description provided for @randomChat.
  ///
  /// In en, this message translates to:
  /// **'Random Chat'**
  String get randomChat;

  /// No description provided for @randomVideo.
  ///
  /// In en, this message translates to:
  /// **'Random Video'**
  String get randomVideo;

  /// No description provided for @findingMatch.
  ///
  /// In en, this message translates to:
  /// **'Finding someone to talk to...'**
  String get findingMatch;

  /// No description provided for @searchingIn.
  ///
  /// In en, this message translates to:
  /// **'🔍 Searching in {scope}'**
  String searchingIn(String scope);

  /// No description provided for @expandingSearch.
  ///
  /// In en, this message translates to:
  /// **'🔍 Expanding search to {scope}...'**
  String expandingSearch(String scope);

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected!'**
  String get connected;

  /// No description provided for @connectedWith.
  ///
  /// In en, this message translates to:
  /// **'Connected with someone from {country} {flag}'**
  String connectedWith(String country, String flag);

  /// No description provided for @sessionEnded.
  ///
  /// In en, this message translates to:
  /// **'Session ended'**
  String get sessionEnded;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End Chat'**
  String get endSession;

  /// No description provided for @nextPerson.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextPerson;

  /// No description provided for @keepTalking.
  ///
  /// In en, this message translates to:
  /// **'Keep Talking 💬'**
  String get keepTalking;

  /// No description provided for @keepTalkingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting to see if they want to keep talking... ⏳'**
  String get keepTalkingWaiting;

  /// No description provided for @keepTalkingPrompt.
  ///
  /// In en, this message translates to:
  /// **'They want to keep talking with you! 💬'**
  String get keepTalkingPrompt;

  /// No description provided for @keepTalkingAccept.
  ///
  /// In en, this message translates to:
  /// **'Keep Talking 💬'**
  String get keepTalkingAccept;

  /// No description provided for @keepTalkingDecline.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get keepTalkingDecline;

  /// No description provided for @mutualMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'You both want to keep talking! 🎉'**
  String get mutualMatchTitle;

  /// No description provided for @mutualMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Starting your conversation...'**
  String get mutualMatchSubtitle;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous 👤'**
  String get anonymous;

  /// No description provided for @somewhereOnEarth.
  ///
  /// In en, this message translates to:
  /// **'🌍 Somewhere on Earth'**
  String get somewhereOnEarth;

  /// No description provided for @speaksLanguage.
  ///
  /// In en, this message translates to:
  /// **'🗣️ {language} speaker'**
  String speaksLanguage(String language);

  /// No description provided for @bothSpeakLanguage.
  ///
  /// In en, this message translates to:
  /// **'🗣️ You both speak {language}'**
  String bothSpeakLanguage(String language);

  /// No description provided for @differentLanguages.
  ///
  /// In en, this message translates to:
  /// **'🗣️ They speak {language} • Use simple words'**
  String differentLanguages(String language);

  /// No description provided for @enableTranslation.
  ///
  /// In en, this message translates to:
  /// **'🌐 Enable auto-translate?'**
  String get enableTranslation;

  /// No description provided for @sessionMonitored.
  ///
  /// In en, this message translates to:
  /// **'This session may be monitored for safety'**
  String get sessionMonitored;

  /// No description provided for @minimumSessionTime.
  ///
  /// In en, this message translates to:
  /// **'Chat for a bit before connecting permanently'**
  String get minimumSessionTime;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @playGame.
  ///
  /// In en, this message translates to:
  /// **'Play a Game'**
  String get playGame;

  /// No description provided for @gameInvite.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to play {game}!'**
  String gameInvite(String name, String game);

  /// No description provided for @gameResult.
  ///
  /// In en, this message translates to:
  /// **'Game Over!'**
  String get gameResult;

  /// No description provided for @youWon.
  ///
  /// In en, this message translates to:
  /// **'You won! 🏆'**
  String get youWon;

  /// No description provided for @youLost.
  ///
  /// In en, this message translates to:
  /// **'Better luck next time! 💪'**
  String get youLost;

  /// No description provided for @gameDraw.
  ///
  /// In en, this message translates to:
  /// **'It\'s a draw! 🤝'**
  String get gameDraw;

  /// No description provided for @rematch.
  ///
  /// In en, this message translates to:
  /// **'Rematch'**
  String get rematch;

  /// No description provided for @postGamePrompt.
  ///
  /// In en, this message translates to:
  /// **'Great game! Want to keep talking? 💬'**
  String get postGamePrompt;

  /// No description provided for @metViaGame.
  ///
  /// In en, this message translates to:
  /// **'You both matched after a game of {game}! 🎮🎉'**
  String metViaGame(String game);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayNameLabel;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell people about yourself...'**
  String get bioHint;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// No description provided for @connectionsCount.
  ///
  /// In en, this message translates to:
  /// **'💬 {count} connections made through Gotchaa'**
  String connectionsCount(int count);

  /// No description provided for @metViaRandomChat.
  ///
  /// In en, this message translates to:
  /// **'Met via random chat'**
  String get metViaRandomChat;

  /// No description provided for @metViaRandomVideo.
  ///
  /// In en, this message translates to:
  /// **'Met via random video'**
  String get metViaRandomVideo;

  /// No description provided for @metViaRandomGame.
  ///
  /// In en, this message translates to:
  /// **'Met via a game of {game}'**
  String metViaRandomGame(String game);

  /// No description provided for @metAgo.
  ///
  /// In en, this message translates to:
  /// **'{time} ago'**
  String metAgo(String time);

  /// No description provided for @travellingIn.
  ///
  /// In en, this message translates to:
  /// **'✈️ Currently in {country}'**
  String travellingIn(String country);

  /// No description provided for @newConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'New Connection! 💬'**
  String get newConnectionTitle;

  /// No description provided for @newConnectionBody.
  ///
  /// In en, this message translates to:
  /// **'You have a new connection waiting!'**
  String get newConnectionBody;

  /// No description provided for @keepTalkingNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Someone wants to keep talking! 💬'**
  String get keepTalkingNotifTitle;

  /// No description provided for @keepTalkingNotifBody.
  ///
  /// In en, this message translates to:
  /// **'You have 30 seconds to respond before the moment passes'**
  String get keepTalkingNotifBody;

  /// No description provided for @screenshotNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Screenshot Alert ⚠️'**
  String get screenshotNotifTitle;

  /// No description provided for @screenshotNotifBody.
  ///
  /// In en, this message translates to:
  /// **'{name} took a screenshot of your chat'**
  String screenshotNotifBody(String name);

  /// No description provided for @weeklyStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Gotchaa week 🎉'**
  String get weeklyStatsTitle;

  /// No description provided for @weeklyStatsBody.
  ///
  /// In en, this message translates to:
  /// **'This week you made {count} new connections!'**
  String weeklyStatsBody(int count);

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportTitle;

  /// No description provided for @reportInappropriate.
  ///
  /// In en, this message translates to:
  /// **'🔞 Inappropriate sexual content'**
  String get reportInappropriate;

  /// No description provided for @reportHarassment.
  ///
  /// In en, this message translates to:
  /// **'😡 Harassment or bullying'**
  String get reportHarassment;

  /// No description provided for @reportThreat.
  ///
  /// In en, this message translates to:
  /// **'🔪 Threats or violence'**
  String get reportThreat;

  /// No description provided for @reportMinor.
  ///
  /// In en, this message translates to:
  /// **'👶 Suspected minor'**
  String get reportMinor;

  /// No description provided for @reportBot.
  ///
  /// In en, this message translates to:
  /// **'🤖 Bot or spam'**
  String get reportBot;

  /// No description provided for @reportDrugs.
  ///
  /// In en, this message translates to:
  /// **'💊 Drugs or illegal content'**
  String get reportDrugs;

  /// No description provided for @reportImage.
  ///
  /// In en, this message translates to:
  /// **'📸 Unsolicited image'**
  String get reportImage;

  /// No description provided for @reportImpersonation.
  ///
  /// In en, this message translates to:
  /// **'🎭 Impersonation'**
  String get reportImpersonation;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you for keeping Gotchaa safe.'**
  String get reportSubmitted;

  /// No description provided for @reportedContentRetention.
  ///
  /// In en, this message translates to:
  /// **'Reported content may be stored for up to 30 days'**
  String get reportedContentRetention;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked'**
  String get blocked;

  /// No description provided for @userSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended'**
  String get userSuspended;

  /// No description provided for @trustScoreLow.
  ///
  /// In en, this message translates to:
  /// **'Your safety rating is too low to use this feature'**
  String get trustScoreLow;

  /// No description provided for @safetyRatingTrusted.
  ///
  /// In en, this message translates to:
  /// **'🛡️ Trusted'**
  String get safetyRatingTrusted;

  /// No description provided for @safetyRatingGood.
  ///
  /// In en, this message translates to:
  /// **'⭐ Good'**
  String get safetyRatingGood;

  /// No description provided for @safetyRatingNew.
  ///
  /// In en, this message translates to:
  /// **'🌱 New'**
  String get safetyRatingNew;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @currentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Current: {language}'**
  String currentLanguage(String language);

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This cannot be undone.'**
  String get confirmDeleteAccount;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted'**
  String get accountDeleted;

  /// No description provided for @twoFactorAuth.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuth;

  /// No description provided for @twoFactorEnabled.
  ///
  /// In en, this message translates to:
  /// **'2FA Enabled ✅'**
  String get twoFactorEnabled;

  /// No description provided for @twoFactorDisabled.
  ///
  /// In en, this message translates to:
  /// **'2FA Disabled'**
  String get twoFactorDisabled;

  /// No description provided for @showLocationOnPosts.
  ///
  /// In en, this message translates to:
  /// **'Show location on posts'**
  String get showLocationOnPosts;

  /// No description provided for @locationPrecision.
  ///
  /// In en, this message translates to:
  /// **'Location precision'**
  String get locationPrecision;

  /// No description provided for @locationPrecisionExact.
  ///
  /// In en, this message translates to:
  /// **'Exact location'**
  String get locationPrecisionExact;

  /// No description provided for @locationPrecisionCity.
  ///
  /// In en, this message translates to:
  /// **'City only'**
  String get locationPrecisionCity;

  /// No description provided for @locationPrecisionCountry.
  ///
  /// In en, this message translates to:
  /// **'Country only'**
  String get locationPrecisionCountry;

  /// No description provided for @clearLocationHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear Location History'**
  String get clearLocationHistory;

  /// No description provided for @locationHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'Location history cleared'**
  String get locationHistoryCleared;

  /// No description provided for @nationVisibility.
  ///
  /// In en, this message translates to:
  /// **'Who can see my nation'**
  String get nationVisibility;

  /// No description provided for @nationVisibilityCountry.
  ///
  /// In en, this message translates to:
  /// **'Show my country'**
  String get nationVisibilityCountry;

  /// No description provided for @nationVisibilityContinent.
  ///
  /// In en, this message translates to:
  /// **'Show continent only'**
  String get nationVisibilityContinent;

  /// No description provided for @nationVisibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Keep private'**
  String get nationVisibilityPrivate;

  /// No description provided for @stayAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Stay anonymous in connections'**
  String get stayAnonymous;

  /// No description provided for @matchPreferences.
  ///
  /// In en, this message translates to:
  /// **'Match Preferences'**
  String get matchPreferences;

  /// No description provided for @matchWorldwide.
  ///
  /// In en, this message translates to:
  /// **'🌍 Worldwide'**
  String get matchWorldwide;

  /// No description provided for @matchSameContinent.
  ///
  /// In en, this message translates to:
  /// **'🌎 Same Continent'**
  String get matchSameContinent;

  /// No description provided for @matchSameCountry.
  ///
  /// In en, this message translates to:
  /// **'🇮🇳 Same Country'**
  String get matchSameCountry;

  /// No description provided for @matchPreferred.
  ///
  /// In en, this message translates to:
  /// **'⭐ Preferred Countries'**
  String get matchPreferred;

  /// No description provided for @preferredCountries.
  ///
  /// In en, this message translates to:
  /// **'Preferred Countries'**
  String get preferredCountries;

  /// No description provided for @maxPreferredCountries.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 countries'**
  String get maxPreferredCountries;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @featureUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This feature is not available on your device'**
  String get featureUnavailable;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @cameraPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required for this feature'**
  String get cameraPermissionNeeded;

  /// No description provided for @locationPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to tag your location'**
  String get locationPermissionNeeded;

  /// No description provided for @microphonePermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required for voice chat'**
  String get microphonePermissionNeeded;

  /// No description provided for @noConnectionsYet.
  ///
  /// In en, this message translates to:
  /// **'No connections yet. Start chatting! 💬'**
  String get noConnectionsYet;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hello! 👋'**
  String get noMessagesYet;

  /// No description provided for @connectionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Connection not found'**
  String get connectionNotFound;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String weeksAgo(int count);

  /// No description provided for @systemMessageConnected.
  ///
  /// In en, this message translates to:
  /// **'🎉 You two connected through Gotchaa random chat! Start your conversation below 👇'**
  String get systemMessageConnected;

  /// No description provided for @systemMessageConnectedVideo.
  ///
  /// In en, this message translates to:
  /// **'🎉 You two connected through Gotchaa random video! Start your conversation below 👇'**
  String get systemMessageConnectedVideo;

  /// No description provided for @systemMessageConnectedGame.
  ///
  /// In en, this message translates to:
  /// **'🎉 You connected after a game of {game}! Start your conversation below 👇'**
  String systemMessageConnectedGame(String game);

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Talk to the World 🌍'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Connect with real people from every country instantly'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Safe and Private 🔒'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted. Messages disappear after 24 hours.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Keep the ones you like 💬'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Both enjoy the chat? Connect permanently with one tap.'**
  String get onboardingBody3;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @alreadyMember.
  ///
  /// In en, this message translates to:
  /// **'Already a member? Log In'**
  String get alreadyMember;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @forYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYou;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @notFollowingYet.
  ///
  /// In en, this message translates to:
  /// **'You are not following anyone yet'**
  String get notFollowingYet;

  /// No description provided for @discoverPeople.
  ///
  /// In en, this message translates to:
  /// **'Discover People'**
  String get discoverPeople;

  /// No description provided for @suggestedForYou.
  ///
  /// In en, this message translates to:
  /// **'Suggested for you'**
  String get suggestedForYou;

  /// No description provided for @postsFromCountry.
  ///
  /// In en, this message translates to:
  /// **'Posts from {country} {flag}'**
  String postsFromCountry(String country, String flag);

  /// No description provided for @vybzTitle.
  ///
  /// In en, this message translates to:
  /// **'Vybz'**
  String get vybzTitle;

  /// No description provided for @trendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trendingTitle;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @saveTo.
  ///
  /// In en, this message translates to:
  /// **'Save to...'**
  String get saveTo;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @inspiration.
  ///
  /// In en, this message translates to:
  /// **'Inspiration'**
  String get inspiration;

  /// No description provided for @recipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipes;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// No description provided for @createNewCollection.
  ///
  /// In en, this message translates to:
  /// **'Create new collection'**
  String get createNewCollection;

  /// No description provided for @collectionName.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get collectionName;

  /// No description provided for @removeFromCollection.
  ///
  /// In en, this message translates to:
  /// **'Remove from {collection}?'**
  String removeFromCollection(String collection);

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to...'**
  String get moveTo;

  /// No description provided for @shareTo.
  ///
  /// In en, this message translates to:
  /// **'Share to...'**
  String get shareTo;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @sendToConnection.
  ///
  /// In en, this message translates to:
  /// **'Send to Gotchaa connection'**
  String get sendToConnection;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'Check out this post on Gotchaa! {link}'**
  String shareText(String link);

  /// No description provided for @sharesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} shares'**
  String sharesCount(int count);

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @viewAllComments.
  ///
  /// In en, this message translates to:
  /// **'View all {count} comments'**
  String viewAllComments(int count);

  /// No description provided for @commentRemoved.
  ///
  /// In en, this message translates to:
  /// **'Comment removed'**
  String get commentRemoved;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String replyingTo(String name);

  /// No description provided for @peopleYouMayKnow.
  ///
  /// In en, this message translates to:
  /// **'People you may know'**
  String get peopleYouMayKnow;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @art.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get art;

  /// No description provided for @tech.
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get tech;

  /// No description provided for @lifestyle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get lifestyle;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @hashtags.
  ///
  /// In en, this message translates to:
  /// **'Hashtags'**
  String get hashtags;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @postsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} posts'**
  String postsCount(int count);

  /// No description provided for @searchQuery.
  ///
  /// In en, this message translates to:
  /// **'Search \"{query}\"'**
  String searchQuery(String query);

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @newPostsAvailable.
  ///
  /// In en, this message translates to:
  /// **'New posts available'**
  String get newPostsAvailable;

  /// No description provided for @notInterested.
  ///
  /// In en, this message translates to:
  /// **'Not interested'**
  String get notInterested;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
