// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: Device.proto

// This CPP symbol can be defined to use imports that match up to the framework
// imports needed when using CocoaPods.
#if !defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS)
 #define GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

#if GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
 #import <protobuf/GPBProtocolBuffers_RuntimeSupport.h>
#else
 #import "GPBProtocolBuffers_RuntimeSupport.h"
#endif

#import "Device.pbobjc.h"
// @@protoc_insertion_point(imports)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#pragma mark - GPBGenDeviceRoot

@implementation GPBGenDeviceRoot

// No extensions in the file and no imports, so no need to generate
// +extensionRegistry.

@end

#pragma mark - GPBGenDeviceRoot_FileDescriptor

static GPBFileDescriptor *GPBGenDeviceRoot_FileDescriptor(void) {
  // This is called by +initialize so there is no need to worry
  // about thread safety of the singleton.
  static GPBFileDescriptor *descriptor = NULL;
  if (!descriptor) {
    GPB_DEBUG_CHECK_RUNTIME_VERSIONS();
    descriptor = [[GPBFileDescriptor alloc] initWithPackage:@"proto"
                                                 objcPrefix:@"GPBGen"
                                                     syntax:GPBFileSyntaxProto3];
  }
  return descriptor;
}

#pragma mark - GPBGenDevice

@implementation GPBGenDevice

@dynamic clientType;
@dynamic channel;
@dynamic channelVersion;
@dynamic platformName;
@dynamic platformVersion;

typedef struct GPBGenDevice__storage_ {
  uint32_t _has_storage_[1];
  NSString *clientType;
  NSString *channel;
  NSString *channelVersion;
  NSString *platformName;
  NSString *platformVersion;
} GPBGenDevice__storage_;

// This method is threadsafe because it is initially called
// in +initialize for each subclass.
+ (GPBDescriptor *)descriptor {
  static GPBDescriptor *descriptor = nil;
  if (!descriptor) {
    static GPBMessageFieldDescription fields[] = {
      {
        .name = "clientType",
        .dataTypeSpecific.className = NULL,
        .number = GPBGenDevice_FieldNumber_ClientType,
        .hasIndex = 0,
        .offset = (uint32_t)offsetof(GPBGenDevice__storage_, clientType),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeString,
      },
      {
        .name = "channel",
        .dataTypeSpecific.className = NULL,
        .number = GPBGenDevice_FieldNumber_Channel,
        .hasIndex = 1,
        .offset = (uint32_t)offsetof(GPBGenDevice__storage_, channel),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeString,
      },
      {
        .name = "channelVersion",
        .dataTypeSpecific.className = NULL,
        .number = GPBGenDevice_FieldNumber_ChannelVersion,
        .hasIndex = 2,
        .offset = (uint32_t)offsetof(GPBGenDevice__storage_, channelVersion),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeString,
      },
      {
        .name = "platformName",
        .dataTypeSpecific.className = NULL,
        .number = GPBGenDevice_FieldNumber_PlatformName,
        .hasIndex = 3,
        .offset = (uint32_t)offsetof(GPBGenDevice__storage_, platformName),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeString,
      },
      {
        .name = "platformVersion",
        .dataTypeSpecific.className = NULL,
        .number = GPBGenDevice_FieldNumber_PlatformVersion,
        .hasIndex = 4,
        .offset = (uint32_t)offsetof(GPBGenDevice__storage_, platformVersion),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeString,
      },
    };
    GPBDescriptor *localDescriptor =
        [GPBDescriptor allocDescriptorForClass:[GPBGenDevice class]
                                     rootClass:[GPBGenDeviceRoot class]
                                          file:GPBGenDeviceRoot_FileDescriptor()
                                        fields:fields
                                    fieldCount:(uint32_t)(sizeof(fields) / sizeof(GPBMessageFieldDescription))
                                   storageSize:sizeof(GPBGenDevice__storage_)
                                         flags:GPBDescriptorInitializationFlag_None];
    #if defined(DEBUG) && DEBUG
      NSAssert(descriptor == nil, @"Startup recursed!");
    #endif  // DEBUG
    descriptor = localDescriptor;
  }
  return descriptor;
}

@end


#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)
