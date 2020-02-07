//
//  SBSpeechRecognition.m
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 07.11.2019.
//

#import "SBSpeechRecognition.h"

#define DEFAULT_LANGUAGE @"en-US"
#define DEFAULT_MATCHES 5

#define MESSAGE_MISSING_PERMISSION @"Missing permission"
#define MESSAGE_ACCESS_DENIED @"User denied access to speech recognition"
#define MESSAGE_RESTRICTED @"Speech recognition restricted on this device"
#define MESSAGE_NOT_DETERMINED @"Speech recognition not determined on this device"
#define MESSAGE_ACCESS_DENIED_MICROPHONE @"User denied access to microphone"
#define MESSAGE_ONGOING @"Ongoing speech recognition"


@interface SBSpeechRecognition ()

@property (nonatomic, strong, nullable) TestChatSendRequest *request;

@end

@implementation SBSpeechRecognition

- (TestChatSendRequest *)createRequestIfNeeded:(CDVInvokedUrlCommand *)command {
    if (!self.request)
    {
        self.request = [AssistantSceneAssembly instantiateWithConfig:command.arguments];
        [self.testChatSendRequest setDelegate:self];
    }
    return self.request;
}

- (void) startSpeechRecognition:(CDVInvokedUrlCommand *)command {

    TestChatSendRequest *request = [self createRequestIfNeeded:command];
    self.cdCommand = command;
    [request startVoiceRecogizer];

}

- (void) startTextRecognition:(CDVInvokedUrlCommand *)command {
    
    TestChatSendRequest *request = [self createRequestIfNeeded:command];
    self.cdCommand = command;
    NSLog(@"%@", command.arguments[5]);
    [request sendMessageWithText:command.arguments[5]];

}


//возращаю строку от tts и чанками от stt сохраняю в строку а finish вызывается при last и итоговая строка stt
-(void)reciveMessage:(NSString*) message {
    _finishMessage = message;
}

- (void)finish {
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:_finishMessage];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_cdCommand.callbackId];

}

- (void)recognitionSessionDidFinishedRecivedVoice:(BOOL) last voice:(NSData*) voice {
    
//    NSLog(@"FINISH!!! voice%@", voice);
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:_finishMessage];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_cdCommand.callbackId];

}

- (void)failError:(NSString*)error {
    
    NSLog(@"error %@", error);
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_cdCommand.callbackId];

}


- (void)isRecognitionAvailable:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *pluginResult = nil;

    if ([SFSpeechRecognizer class]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:NO];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void)hasPermission:(CDVInvokedUrlCommand*)command {
    /*SFSpeechRecognizerAuthorizationStatus status = [SFSpeechRecognizer authorizationStatus];
    BOOL speechAuthGranted = (status == SFSpeechRecognizerAuthorizationStatusAuthorized);

    if (!speechAuthGranted) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:NO];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }*/

    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted){
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:granted];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)requestPermission:(CDVInvokedUrlCommand*)command {
    /*[SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status){
        dispatch_async(dispatch_get_main_queue(), ^{
            CDVPluginResult *pluginResult = nil;
            BOOL speechAuthGranted = NO;

            switch (status) {
                case SFSpeechRecognizerAuthorizationStatusAuthorized:
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                    speechAuthGranted = YES;
                    break;
                case SFSpeechRecognizerAuthorizationStatusDenied:
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:MESSAGE_ACCESS_DENIED];
                    break;
                case SFSpeechRecognizerAuthorizationStatusRestricted:
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:MESSAGE_RESTRICTED];
                    break;
                case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:MESSAGE_NOT_DETERMINED];
                    break;
            }

            if (!speechAuthGranted) {
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                return;
            }*/

            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted){
                CDVPluginResult *pluginResult = nil;

                if (granted) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:MESSAGE_ACCESS_DENIED_MICROPHONE];
                }

                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }];
    //    });
    //}];
}




@end
