// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: Settings.proto

// This CPP symbol can be defined to use imports that match up to the framework
// imports needed when using CocoaPods.
#if !defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS)
 #define GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

#if GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
 #import <protobuf/GPBProtocolBuffers.h>
#else
 #import "GPBProtocolBuffers.h"
#endif

#if GOOGLE_PROTOBUF_OBJC_VERSION < 30002
#error This file was generated by a newer version of protoc which is incompatible with your Protocol Buffer library sources.
#endif
#if 30002 < GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION
#error This file was generated by an older version of protoc which is incompatible with your Protocol Buffer library sources.
#endif

// @@protoc_insertion_point(imports)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

CF_EXTERN_C_BEGIN

NS_ASSUME_NONNULL_BEGIN

#pragma mark - GPBGenSettingsRoot

/**
 * Exposes the extension registry for this file.
 *
 * The base class provides:
 * @code
 *   + (GPBExtensionRegistry *)extensionRegistry;
 * @endcode
 * which is a @c GPBExtensionRegistry that includes all the extensions defined by
 * this file and all files that it depends on.
 **/
@interface GPBGenSettingsRoot : GPBRootObject
@end

#pragma mark - GPBGenSettings

typedef GPB_ENUM(GPBGenSettings_FieldNumber) {
  GPBGenSettings_FieldNumber_Dubbing = 1,
  GPBGenSettings_FieldNumber_Echo = 2,
  GPBGenSettings_FieldNumber_TtsEngine = 3,
  GPBGenSettings_FieldNumber_SttEngine = 4,
  GPBGenSettings_FieldNumber_SttAutoStop = 5,
};

@interface GPBGenSettings : GPBMessage

/** false = -1 | 0 - undefined | true = 1 // default:true */
@property(nonatomic, readwrite) int32_t echo;

/** false = -1 | 0 - undefined | true = 1 // default:true */
@property(nonatomic, readwrite) int32_t dubbing;

/** tts engine alias */
@property(nonatomic, readwrite, copy, null_resettable) NSString *ttsEngine;

/**  stt engine alias */
@property(nonatomic, readwrite, copy, null_resettable) NSString *sttEngine;

/** */
@property(nonatomic, readwrite) int32_t sttAutoStop;

@end

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END

#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)
