///*
// * Copyright (C) 2021 Alibaba Inc. All rights reserved.
// * Author: Kraken Team.
// */
//
//#ifndef BRIDGE_HTML_ALL_COLLECTION_H
//#define BRIDGE_HTML_ALL_COLLECTION_H
//
//#include "bindings/qjs/garbage_collected.h"
//
// namespace webf{
//
// class HTMLAllCollection : public HostObject {
// public:
//  AllCollection(ExecutionContext* context) : HostObject(context, "AllCollection"){};
//
//  static JSValue item(JSContext* ctx, JSValueConst this_val, int argc, JSValueConst* argv);
//  static JSValue add(JSContext* ctx, JSValueConst this_val, int argc, JSValueConst* argv);
//  static JSValue remove(JSContext* ctx, JSValueConst this_val, int argc, JSValueConst* argv);
//
//  DEFINE_READONLY_PROPERTY(length);
//
//  void internalAdd(NodeInstance* node, NodeInstance* before);
//
// private:
//  std::vector<NodeInstance*> m_nodes;
//};
//
//}  // namespace webf
//
//#endif  // BRIDGE_HTML_ALL_COLLECTION_H
