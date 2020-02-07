// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: Device.proto

// This CPP symbol can be defined to use imports that match up to the framework
// imports needed when using CocoaPods.
#if !defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS)
 #define GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

#if GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
// #import <protobuf/GPBProtocolBuffers.h>
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

#pragma mark - GPBGenDeviceRoot

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
@interface GPBGenDeviceRoot : GPBRootObject
@end

#pragma mark - GPBGenDevice

typedef GPB_ENUM(GPBGenDevice_FieldNumber) {
  GPBGenDevice_FieldNumber_ClientType = 1,
  GPBGenDevice_FieldNumber_Channel = 2,
  GPBGenDevice_FieldNumber_ChannelVersion = 3,
  GPBGenDevice_FieldNumber_PlatformName = 4,
  GPBGenDevice_FieldNumber_PlatformVersion = 5,
};

@interface GPBGenDevice : GPBMessage

@property(nonatomic, readwrite, copy, null_resettable) NSString *clientType;

@property(nonatomic, readwrite, copy, null_resettable) NSString *channel;

@property(nonatomic, readwrite, copy, null_resettable) NSString *channelVersion;

@property(nonatomic, readwrite, copy, null_resettable) NSString *platformName;

@property(nonatomic, readwrite, copy, null_resettable) NSString *platformVersion;

@end

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END

#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)