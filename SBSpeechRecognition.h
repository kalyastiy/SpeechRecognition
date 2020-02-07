//
//  SBSpeechRecognition.h
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 07.11.2019.
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import "mfp6-Swift.h"
#import <Cordova/CDV.h>
#import <Speech/Speech.h>
#import "RecivedVPSDelegate.h"


@interface SBSpeechRecognition : CDVPlugin <RecivedVPSDelegate>

@property (nonatomic, strong) NSString *finishMessage;
@property (nonatomic, strong) CDVInvokedUrlCommand *cdCommand;
@property (nonatomic, strong) TestChatSendRequest *testChatSendRequest;

- (void) startSpeechRecognition:(CDVInvokedUrlCommand *)command;
- (void) startTextRecognition:(CDVInvokedUrlCommand *)command;

- (void)isRecognitionAvailable:(CDVInvokedUrlCommand*)command;
- (void)hasPermission:(CDVInvokedUrlCommand*)command;
- (void)requestPermission:(CDVInvokedUrlCommand*)command;


@end
