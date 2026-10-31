#pragma once
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Storage.Streams.h>
#include <algorithm>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstring>
#include <memory>
#include <mutex>
#include <vector>

// Explicit diagnostic-only input, backed solely by bounded owned fixture bytes.
// No file discovery, network, queue policy, or platform-thread wait.
namespace owned_loading {
using namespace winrt;
using namespace Windows::Foundation;
using namespace Windows::Storage::Streams;

struct GateState {
  explicit GateState(std::vector<uint8_t> value)
      : bytes(std::move(value)), size(bytes.size()) {}
  std::mutex mutex;
  std::condition_variable changed;
  std::vector<uint8_t> bytes;
  const uint64_t size;
  bool allowed=false, cancelled=false, claimed=false, closed=false;
  bool sourceClosed=false, streamClosed=false;
  bool pcm=false;
  bool unknownDuration=false;
  uint64_t pcmPosition=0;
  int64_t readers=0, waiting=0, bytesRead=0, waitedMs=0;
  void Allow() {
    std::lock_guard lock(mutex);
    if(!cancelled) allowed=true;
    changed.notify_all();
  }
  void Cancel() {
    std::lock_guard lock(mutex);
    cancelled=true;
    changed.notify_all();
  }
  bool FinishClose() {
    std::lock_guard lock(mutex);
    if(readers!=0 || !sourceClosed || !streamClosed) return false;
    closed=true;
    std::vector<uint8_t>().swap(bytes);
    return true;
  }
};

struct ReadGuard {
  std::shared_ptr<GateState> gate;
  explicit ReadGuard(std::shared_ptr<GateState> state) : gate(std::move(state)) {
    std::lock_guard lock(gate->mutex);
    if(gate->cancelled) throw hresult_canceled();
    if(gate->readers>=16) throw hresult_error(E_BOUNDS);
    ++gate->readers;
  }
  ~ReadGuard() {
    std::lock_guard lock(gate->mutex);
    --gate->readers;
    gate->changed.notify_all();
  }
};

struct GateStream : implements<GateStream, IRandomAccessStream, IInputStream,
                               IOutputStream, IClosable> {
  explicit GateStream(std::shared_ptr<GateState> state, uint64_t position=0)
      : gate_(std::move(state)), position_(position) {}
  void Close() noexcept { closed_=true; gate_->changed.notify_all(); }
  ~GateStream() { Close(); }
  bool CanRead() const { return !closed_; }
  bool CanWrite() const { return false; }
  uint64_t Size() const { Check(); return gate_->size; }
  void Size(uint64_t) { throw hresult_access_denied(); }
  uint64_t Position() const {
    Check(); std::lock_guard lock(positionMutex_); return position_;
  }
  void Seek(uint64_t value) {
    Check();
    if(value>gate_->size) throw hresult_error(E_BOUNDS);
    std::lock_guard lock(positionMutex_); position_=value;
  }
  IRandomAccessStream CloneStream() {
    return make<GateStream>(gate_, Position());
  }
  IInputStream GetInputStreamAt(uint64_t position) {
    Check();
    if(position>gate_->size) throw hresult_error(E_BOUNDS);
    return make<GateStream>(gate_, position).as<IInputStream>();
  }
  IOutputStream GetOutputStreamAt(uint64_t) { throw hresult_access_denied(); }
  IAsyncOperationWithProgress<uint32_t,uint32_t> WriteAsync(IBuffer const&) {
    throw hresult_access_denied();
  }
  IAsyncOperation<bool> FlushAsync() { co_return true; }

  IAsyncOperationWithProgress<IBuffer,uint32_t> ReadAsync(
      IBuffer buffer, uint32_t count, InputStreamOptions) {
    [[maybe_unused]] auto lifetime=get_strong();
    Check();
    // Count BEFORE the first suspension: queued reads also delay release receipt.
    ReadGuard reading(gate_);
    auto cancel=co_await get_cancellation_token();
    const auto start=std::chrono::steady_clock::now();
    co_await resume_background();
    {
      std::unique_lock lock(gate_->mutex);
      ++gate_->waiting;
      try {
        while(!gate_->allowed && !gate_->cancelled && !closed_ && !cancel()) {
          if(std::chrono::steady_clock::now()-start>=std::chrono::seconds(15)) {
            gate_->cancelled=true;
            gate_->changed.notify_all();
            throw hresult_error(HRESULT_FROM_WIN32(ERROR_TIMEOUT));
          }
          gate_->changed.wait_for(lock,std::chrono::milliseconds(20));
        }
        --gate_->waiting;
      } catch(...) { --gate_->waiting; throw; }
      gate_->waitedMs+=std::chrono::duration_cast<std::chrono::milliseconds>(
          std::chrono::steady_clock::now()-start).count();
      if(gate_->cancelled || closed_ || cancel()) throw hresult_canceled();
      std::lock_guard positionLock(positionMutex_);
      const auto length=static_cast<uint32_t>(std::min<uint64_t>(
          std::min(count,buffer.Capacity()),gate_->size-position_));
      if(length>0) std::memcpy(buffer.data(),gate_->bytes.data()+position_,length);
      buffer.Length(length);
      position_+=length;
      gate_->bytesRead+=length;
    }
    co_return buffer;
  }
 private:
  void Check() const { if(closed_) throw hresult_error(RO_E_CLOSED); }
  std::shared_ptr<GateState> gate_;
  mutable std::mutex positionMutex_;
  uint64_t position_;
  std::atomic_bool closed_{false};
};
}
