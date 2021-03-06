//
//  SpeechSynthesis.m
//  KaniManabu
//
//  Created by 千代田桃 on 2/10/22.
//

#import "SpeechSynthesis.h"
#import "MicrosoftSpeechConstants.h"
#import <AVFoundation/AVFoundation.h>
#import <MicrosoftCognitiveServicesSpeech/SPXSpeechApi.h>
#import <SAMKeychain/SAMKeychain.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AFNetworking/AFNetworking.h>
#import "IBMSpeechConstants.h"

@interface SpeechSynthesis ()
@property (strong) AFHTTPSessionManager *ibmmanager;
@property (strong) AVSpeechSynthesizer *synthesizer;
@property (strong, nonatomic) dispatch_queue_t privateQueue;
@property (strong) AVAudioPlayer *player;
@property bool playing;
@end

@implementation SpeechSynthesis
+ (instancetype)sharedInstance {
    static SpeechSynthesis *sharedManager = nil;
    static dispatch_once_t speechtoken;
    dispatch_once(&speechtoken, ^{
        sharedManager = [SpeechSynthesis new];
    });
    return sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        _synthesizer = [AVSpeechSynthesizer new];
        _privateQueue = dispatch_queue_create("moe.ateliershiori.KaniManabu.speechsynthesis", DISPATCH_QUEUE_CONCURRENT);
        self.ibmmanager = [AFHTTPSessionManager manager];
        self.ibmmanager.requestSerializer = [AFJSONRequestSerializer serializer];
        self.ibmmanager.responseSerializer = [AFHTTPResponseSerializer serializer];
        return self;
    }
    return nil;
}

- (void)sayText:(NSString *)text {
    if (!_playing) {
        _playing = YES;
        if ([NSUserDefaults.standardUserDefaults integerForKey:@"ttsvoice"] == 2) {
            dispatch_async(self.privateQueue, ^{
                // Use Microsoft Speech Synthesis. Get the audio synthesis from Microsoft Speech Services and then save it to Core Data for later use.
                NSData *speechData = [self getStoredAudio:text withService:TTSMicrosoft];
                if (!speechData) {
                    // Get the speech audio and save it
                    [self getMSSpeechDataFromText:text completionHandler:^(bool success, NSData *audiodata) {
                        if (success) {
                            [self saveAudioWithWord:text withAudioData:audiodata withService:TTSMicrosoft];
                            self.playing = NO;
                        }
                        else {
                            // Fallback to TTS
                            [self macOSSayText:text];
                            self.playing = NO;
                        }
                    }];
                }
                else {
                    // Play back stored audio
                    [self playAudioWithData:speechData];
                    self.playing = NO;
                }
            });
        }
        else if ([NSUserDefaults.standardUserDefaults integerForKey:@"ttsvoice"] == 3) {
            dispatch_async(self.privateQueue, ^{
                
                NSData *speechData = [self getStoredAudio:text withService:TTSIBM];
                if (!speechData) {
                    // Get the speech audio and save it
                    [self getIBMSpeechDataFromText:text completionHandler:^(bool success, NSData *audiodata) {
                        if (success) {
                            [self saveAudioWithWord:text withAudioData:audiodata withService:TTSIBM];
                            self.playing = NO;
                        }
                        else {
                            // Fallback to TTS
                            [self macOSSayText:text];
                            self.playing = NO;
                        }
                    }];
                }
                else {
                    // Play back stored audio
                    [self playAudioWithData:speechData];
                    self.playing = NO;
                }
            });
        }
        else {
            // Use MacOS Speech Synthesizer
            [self macOSSayText:text];
            _playing = NO;
        }
    }
}

- (void)macOSSayText:(NSString *)text {
    // Use macOS Speech Synthesis
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithIdentifier:[NSUserDefaults.standardUserDefaults integerForKey:@"ttsvoice"] != 1 ? @"com.apple.speech.synthesis.voice.kyoko.premium" : @"com.apple.speech.synthesis.voice.otoya.premium"];
    [_synthesizer speakUtterance:utterance];
}

- (NSData *)getStoredAudio:(NSString *)text withService:(TTSService)service {
    // Gets the stored audio for the word from the AudioContainer Core Data container
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Speech" inManagedObjectContext:_moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"word == %@ AND serviceid == %i",text, service];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    NSArray *results = [_moc executeFetchRequest:fetchRequest error:&error];
    if (results.count > 0) {
        return [(NSManagedObject *)results[0] valueForKey:@"audio"];
    }
    return nil;
}

- (void)storeSubscriptionKey:(NSString *)key {
    [SAMKeychain setPassword:key forService:@"KaniManabu" account:@"Azure Subscription Key"];
}

- (NSString *)getSubscriptionKey {
    return [SAMKeychain passwordForService:@"KaniManabu" account:@"Azure Subscription Key"];
}

- (void)removeSubscriptionKey {
    [SAMKeychain deletePasswordForService:@"KaniManabu" account:@"Azure Subscription Key"];
}

- (void)storeIBMAPIKey:(NSDictionary *)data {
    NSData *myData = [NSKeyedArchiver archivedDataWithRootObject:data];
    [SAMKeychain setPasswordData:myData forService:@"KaniManabu" account:@"IBM API Key" error:nil];
}

- (NSDictionary *)getIBMAPIKey {
    NSData *myData = [SAMKeychain passwordDataForService:@"KaniManabu" account:@"IBM API Key"];
    if (myData) {
        return (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:myData];
    }
    return nil;
}

- (void)removeIBMAPIKey {
    [SAMKeychain deletePasswordForService:@"KaniManabu" account:@"IBM API Key"];
}

- (void)getIBMSpeechDataFromText:(NSString *)text completionHandler:(void (^)(bool success, NSData *audiodata)) completionHandler {
    NSDictionary *parameters = @{@"text" : text};
    NSDictionary *apicred = [self getIBMAPIKey];
    NSString *APIKey = @"";
    if (apicred) {
        APIKey = apicred[@"apikey"];
    }
    else {
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"donated"]) {
            APIKey = IBMAPIKey;
        }
        else {
            completionHandler(false, nil);
            return;
        }
    }
    [self.ibmmanager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"apikey" password:APIKey];
    NSString *url = [NSString stringWithFormat:@"%@/v1/synthesize?voice=ja-JP_EmiV3Voice", apicred ? apicred[@"url"] : IBMInstanceURL];
    [_ibmmanager POST:url parameters:parameters headers:@{@"Accept" : @"audio/wav"} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *fileName = @"/KaniManabu/pullStream.wav";
        NSString *fileAtPath = [filePath stringByAppendingString:fileName];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fileAtPath]) {
            [[NSFileManager defaultManager] createFileAtPath:fileAtPath contents:nil attributes:nil];
        }
        NSData *dataresponseObject = responseObject;
        [dataresponseObject writeToFile:fileAtPath atomically:YES];
        // Play audio while conversion is in progress
        [self playAudioWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:fileAtPath]]];
        //Convert to AAC
        [self convertWithFileName:fileAtPath completionHandler:^(NSData *audiodata) {
            if (audiodata) {
                [NSFileManager.defaultManager removeItemAtPath:fileAtPath error:nil];
                [NSFileManager.defaultManager removeItemAtPath:[fileAtPath stringByReplacingOccurrencesOfString:@".wav" withString:@".m4a"] error:nil];
                completionHandler(true, audiodata);
            }
            else {
                completionHandler(false, nil);
            }
        }];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"IBM Speech Errpr: %@", error.localizedDescription);
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",errResponse);
        completionHandler(false, nil);
    }];
}

- (void)getMSSpeechDataFromText:(NSString *)text completionHandler:(void (^)(bool success, NSData *audiodata)) completionHandler {
    NSString *skey = [self getSubscriptionKey];
    if (!skey) {
        if ([NSUserDefaults.standardUserDefaults boolForKey:@"donated"]) {
            // User has a subscription, use built in subscription key
            skey = subscriptionKey;
        }
        else {
            // No Subscription Key
            completionHandler(false, nil);
            return;
        }
    }
    // Configure the speech synthesizer and output location
    SPXSpeechConfiguration *configuration = [[SPXSpeechConfiguration alloc] initWithSubscription:skey region:@"eastus"];
    configuration.speechSynthesisLanguage = @"ja-JP";
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = @"/KaniManabu/pullStream.wav";
    NSString *fileAtPath = [filePath stringByAppendingString:fileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileAtPath]) {
        [[NSFileManager defaultManager] createFileAtPath:fileAtPath contents:nil attributes:nil];
    }
    SPXAudioConfiguration *audioConfig = [[SPXAudioConfiguration alloc] initWithWavFileOutput:fileAtPath];
    
    SPXSpeechSynthesizer *synthesizer = [[SPXSpeechSynthesizer alloc] initWithSpeechConfiguration:configuration audioConfiguration:audioConfig];
    
    if (!synthesizer) {
        NSLog(@"Could not create speech synthesizer");
        completionHandler(false, nil);
        return;
    }
    SPXSpeechSynthesisResult *speechResult = [synthesizer speakText:text];

    // Checks result.
    if (SPXResultReason_Canceled == speechResult.reason) {
        SPXSpeechSynthesisCancellationDetails *details = [[SPXSpeechSynthesisCancellationDetails alloc] initFromCanceledSynthesisResult:speechResult];
        NSLog(@"Speech synthesis was canceled: %@. Did you pass the correct key/region combination?", details.errorDetails);
        completionHandler(false, nil);
        return;
    } else if (SPXResultReason_SynthesizingAudioCompleted == speechResult.reason) {
        NSLog(@"Speech synthesis was completed");
    } else {
        NSLog(@"There was an error.");
        completionHandler(false, nil);
        return;
    }
    // Play audio while conversion is in progress
    [self playAudioWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:fileAtPath]]];
    //Convert to AAC
    [self convertWithFileName:fileAtPath completionHandler:^(NSData *audiodata) {
        if (audiodata) {
            [NSFileManager.defaultManager removeItemAtPath:fileAtPath error:nil];
            [NSFileManager.defaultManager removeItemAtPath:[fileAtPath stringByReplacingOccurrencesOfString:@".wav" withString:@".m4a"] error:nil];
            completionHandler(true, audiodata);
        }
        else {
            completionHandler(false, nil);
        }
    }];
}

- (void)saveAudioWithWord:(NSString *)word withAudioData:(NSData *)data withService:(TTSService)service {
    // Stores the audio file with the kana word for later use
    NSManagedObject *newAudio = [NSEntityDescription insertNewObjectForEntityForName:@"Speech" inManagedObjectContext:_moc];
    [newAudio setValue:word forKey:@"word"];
    [newAudio setValue:data forKey:@"audio"];
    [newAudio setValue:@(service) forKey:@"serviceid"];
    [_moc performBlockAndWait:^{
            [_moc save:nil];
    }];
}

- (void)playAudioWithData:(NSData *)data {
    // Plays the audio data
    NSError *error = nil;
    _player = [[AVAudioPlayer alloc] initWithData:data error:&error];
    if (!error) {
        [_player play];
    }
    else {
        NSLog(@"%@", error.localizedDescription);
    }
}

- (void)convertWithFileName:(NSString *)filenamepath completionHandler:(void (^)(NSData *audiodata)) completionHandler {
    // Convert the TTS WAV file to an AAC one to use less space
    AVURLAsset *source = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:filenamepath] options:nil];
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:source presetName:AVAssetExportPresetAppleM4A];
    exporter.outputFileType = AVFileTypeAppleM4A;
    exporter.outputURL = [NSURL fileURLWithPath:[filenamepath stringByReplacingOccurrencesOfString:@".wav" withString:@".m4a"]];
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        if (exporter.status == AVAssetExportSessionStatusFailed) {
            completionHandler(nil);
        }
        else {
            NSData *audiodata = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:[filenamepath stringByReplacingOccurrencesOfString:@".wav" withString:@".m4a"]]];
            completionHandler(audiodata);
        }
    }];
}

- (void)playSample {
    switch ([NSUserDefaults.standardUserDefaults integerForKey:@"ttsvoice"]) {
        case 0:
        case 1:
            [self macOSSayText:@"これで勝ったと思うなよ"];
            break;
        case 2:
            [self playAudioWithData:[[NSDataAsset alloc] initWithName:@"mssample"].data];
            break;
        case 3:
            [self playAudioWithData:[[NSDataAsset alloc] initWithName:@"ibmsample"].data];
            break;
        default:
            break;
    }
}
@end
