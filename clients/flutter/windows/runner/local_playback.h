#pragma once
#include <flutter/binary_messenger.h>
#include <memory>
#include <windows.h>

class LocalPlayback {
 public:
  LocalPlayback(flutter::BinaryMessenger* messenger, HWND window);
  ~LocalPlayback();
 private:
  struct Impl;
  std::unique_ptr<Impl> impl_;
};
