/*
 * Copyright (C) 2019 Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */
#ifndef KRAKENBRIDGE_BLOB_H
#define KRAKENBRIDGE_BLOB_H

#include "bindings/jsc/host_class.h"
#include "bindings/jsc/js_context.h"
#include <memory>
#include <unordered_map>
#include <utility>
#include <vector>

#define JSBlobName "Blob"

namespace kraken::binding::jsc {

void bindBlob(std::unique_ptr<JSContext> &context);

class JSBlob;
class BlobBuilder;

class JSBlob : public HostClass {
public:
  static JSBlob *instance(JSContext *context);

  JSObjectRef instanceConstructor(JSContextRef ctx, JSObjectRef constructor, size_t argumentCount,
                                  const JSValueRef *arguments, JSValueRef *exception) override;

  class BlobInstance : public Instance {
  public:
    enum BlobProperty {
      kArrayBuffer,
      kSlice,
      kText,
      // TODO: not supported
      kStream,
      kType,
      kSize
    };

    static std::vector<JSStringRef> &getBlobPropertyNames();
    static std::unordered_map<std::string, BlobProperty> &getBlobPropertyMap();

    static JSValueRef slice(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount,
                            const JSValueRef arguments[], JSValueRef *exception);
    static JSValueRef text(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount,
                           const JSValueRef arguments[], JSValueRef *exception);
    static JSValueRef arrayBuffer(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount,
                                  const JSValueRef arguments[], JSValueRef *exception);

    BlobInstance() = delete;
    explicit BlobInstance(JSBlob *jsBlob) : _size(0), Instance(jsBlob){};
    explicit BlobInstance(JSBlob *jsBlob, std::vector<uint8_t> &&data)
      : _size(data.size()), _data(std::move(data)), Instance(jsBlob){};
    explicit BlobInstance(JSBlob *jsBlob, std::vector<uint8_t> &&data, std::string &mime)
      : mimeType(mime), _size(data.size()), _data(std::move(data)), Instance(jsBlob){};

    ~BlobInstance() override;

    JSValueRef getProperty(std::string &name, JSValueRef *exception) override;
    void getPropertyNames(JSPropertyNameAccumulatorRef accumulator) override;

    /// get an pointer of bytes data from JSBlob
    uint8_t *bytes();

    /// get bytes data's length
    int32_t size();

  private:
    JSObjectRef _arrayBuffer{nullptr};
    JSObjectRef _slice{nullptr};
    JSObjectRef _text{nullptr};

    size_t _size;
    std::string mimeType{""};
    std::vector<uint8_t> _data;
    friend BlobBuilder;
  };
  struct BlobPromiseContext {
    BlobInstance *blobInstance;
  };

protected:
  JSBlob() = delete;
  explicit JSBlob(JSContext *context) : HostClass(context, "Blob"){};
};

class BlobBuilder {
public:
  void append(JSContext &context, const JSValueRef value, JSValueRef *exception);
  void append(JSContext &context, JSBlob::BlobInstance *blob);
  void append(JSContext &context, JSStringRef text);

  std::vector<uint8_t> finalize();

private:
  friend JSBlob;
  std::vector<uint8_t> _data;
};

} // namespace kraken::binding::jsc

#endif // KRAKENBRIDGE_BLOB_H
