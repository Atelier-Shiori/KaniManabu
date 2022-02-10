//
//  SpeechSynthesis.m
//  KaniManabu
//
//  Created by 千代田桃 on 2/10/22.
//

#import "SpeechSynthesis.h"
#import <AVFoundation/AVFoundation.h>
#import "MicrosoftSpeechConstants.h"
#import <MicrosoftCognitiveServicesSpeech/SPXSpeechApi.h>

@interface SpeechSynthesis ()
@property (strong) AVSpeechSynthesizer *synthesizer;
@property (strong, nonatomic) dispatch_queue_t privateQueue;
@property (strong) SPXSpeechConfiguration *configuration;
@property (strong) AVAudioPlayer *player;
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
        _configuration = [[SPXSpeechConfiguration alloc] initWithSubscription:subscriptionKey region:@"eastus"];
        _configuration.speechSynthesisLanguage = @"ja-JP";
        _privateQueue = dispatch_queue_create("moe.ateliershiori.KaniManabu.speechsynthesis", DISPATCH_QUEUE_CONCURRENT);
        return self;
    }
    return nil;
}

- (void)sayText:(NSString *)text {
    if ([NSUserDefaults.standardUserDefaults integerForKey:@"ttsvoice"] == 2) {
        dispatch_async(self.privateQueue, ^{
            // Use Microsoft Speech Synthesis. Get the audio synthesis from Microsoft Speech Services and then save it to Core Data for later use.
            NSData *speechData = [self getStoredAudio:text];
            if (!speechData) {
                // Get Speech Synthesis Audio and store it in the AudioContainer Core Data for later use
                speechData = [self getSpeechDataFromText:text];
                if (speechData) {
                    [self saveAudioWithWord:text withAudioData:speechData];
                }
                else {
                    return;
                }
            }
            [self playAudioWithData:speechData];
        });
    }
    else {
        // Use macOS Speech Synthesis
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
        utterance.voice = [AVSpeechSynthesisVoice voiceWithIdentifier: [NSUserDefaults.standardUserDefaults integerForKey:@"ttsvoice"] == 0 ? @"com.apple.speech.synthesis.voice.kyoko.premium" : @"com.apple.speech.synthesis.voice.otoya.premium"];
        [_synthesizer speakUtterance:utterance];
    }
}

- (NSData *)getStoredAudio:(NSString *)text {
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Speech" inManagedObjectContext:_moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"word == %@",text];
    fetchRequest.predicate = predicate;
    NSError *error = nil;
    NSArray *results = [_moc executeFetchRequest:fetchRequest error:&error];
    if (results.count > 0) {
        return [(NSManagedObject *)results[0] valueForKey:@"audio"];
    }
    return nil;
}

- (NSData *)getSpeechDataFromText:(NSString *)text {
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = @"/KaniManabu/pullStream.wav";
    NSString *fileAtPath = [filePath stringByAppendingString:fileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileAtPath]) {
        [[NSFileManager defaultManager] createFileAtPath:fileAtPath contents:nil attributes:nil];
    }
    SPXAudioConfiguration *audioConfig = [[SPXAudioConfiguration alloc] initWithWavFileOutput:fileAtPath];
    
    SPXSpeechSynthesizer *synthesizer = [[SPXSpeechSynthesizer alloc] initWithSpeechConfiguration:_configuration audioConfiguration:audioConfig];
    
    if (!synthesizer) {
        NSLog(@"Could not create speech synthesizer");
        return nil;
    }
    SPXSpeechSynthesisResult *speechResult = [synthesizer speakText:text];

    // Checks result.
    if (SPXResultReason_Canceled == speechResult.reason) {
        SPXSpeechSynthesisCancellationDetails *details = [[SPXSpeechSynthesisCancellationDetails alloc] initFromCanceledSynthesisResult:speechResult];
        NSLog(@"Speech synthesis was canceled: %@. Did you pass the correct key/region combination?", details.errorDetails);
        return nil;
    } else if (SPXResultReason_SynthesizingAudioCompleted == speechResult.reason) {
        NSLog(@"Speech synthesis was completed");
    } else {
        NSLog(@"There was an error.");
        return nil;
    }
    NSData *fileData = [NSData dataWithContentsOfURL:[[NSURL alloc] initFileURLWithPath:fileAtPath]];
    [NSFileManager.defaultManager removeItemAtPath:fileAtPath error:nil];
    return fileData;
}

- (void)saveAudioWithWord:(NSString *)word withAudioData:(NSData *)data {
    NSManagedObject *newAudio = [NSEntityDescription insertNewObjectForEntityForName:@"Speech" inManagedObjectContext:_moc];
    [newAudio setValue:word forKey:@"word"];
    [newAudio setValue:data forKey:@"audio"];
    [_moc performBlockAndWait:^{
            [_moc save:nil];
    }];
}

- (void)playAudioWithData:(NSData *)data {
    NSError *error = nil;
    _player = [[AVAudioPlayer alloc] initWithData:data error:&error];
    if (!error) {
        [_player play];
    }
    else {
        NSLog(@"%@", error.localizedDescription);
    }
}
@end
