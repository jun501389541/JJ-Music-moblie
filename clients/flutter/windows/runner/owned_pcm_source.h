#pragma once
#include "owned_gate_stream.h"
#include <winrt/Windows.Media.Core.h>
#include <winrt/Windows.Media.MediaProperties.h>

// Diagnostic PCM delivery only. The fixture format is deliberately fixed;
// ordinary files still use the existing MediaPlayer URI path.
namespace owned_loading {
using namespace Windows::Media::Core;
using namespace Windows::Media::MediaProperties;

inline void ValidatePcm(std::vector<uint8_t> const& bytes) {
  const uint8_t canonical[] = {1,0,1,0,128,62,0,0,0,125,0,0,2,0,16,0};
  if(bytes.size()!=384044 || std::memcmp(bytes.data()+12,"fmt ",4)!=0 ||
     bytes[16]!=16 || bytes[17]!=0 || bytes[18]!=0 || bytes[19]!=0 ||
     std::memcmp(bytes.data()+20,canonical,sizeof(canonical))!=0 ||
     std::memcmp(bytes.data()+36,"data",4)!=0 ||
     bytes[40]!=0 || bytes[41]!=220 || bytes[42]!=5 || bytes[43]!=0)
    throw hresult_invalid_argument();
}

inline fire_and_forget DeliverPcm(std::shared_ptr<GateState> gate,
                                  MediaStreamSource source,
                                  MediaStreamSourceSampleRequest request) {
  // Obtain/count before suspension so Close cannot acknowledge queued work.
  MediaStreamSourceSampleRequestDeferral deferral{nullptr};
  std::unique_ptr<ReadGuard> reading;
  try {
    deferral=request.GetDeferral();
    reading=std::make_unique<ReadGuard>(gate);
    co_await resume_background();
    const auto start=std::chrono::steady_clock::now();
    IBuffer buffer{nullptr};
    uint64_t position=0;
    bool cancelled=false, timedOut=false;
    {
      std::unique_lock lock(gate->mutex);
      if(gate->pcmPosition>=64000 && !gate->allowed && !gate->cancelled) {
        ++gate->waiting;
        while(!gate->allowed && !gate->cancelled) {
          if(std::chrono::steady_clock::now()-start>=std::chrono::seconds(15)) {
            timedOut=true; break;
          }
          gate->changed.wait_for(lock,std::chrono::milliseconds(100));
          lock.unlock();
          try {request.ReportSampleProgress(0);} catch(...) {}
          lock.lock();
        }
        --gate->waiting;
      }
      gate->waitedMs+=std::chrono::duration_cast<std::chrono::milliseconds>(
          std::chrono::steady_clock::now()-start).count();
      cancelled=gate->cancelled;
      position=gate->pcmPosition;
      if(!cancelled && !timedOut && position<384000) {
        buffer=Buffer(3200);
        std::memcpy(buffer.data(),gate->bytes.data()+44+position,3200);
        buffer.Length(3200);
        gate->pcmPosition+=3200;
        gate->bytesRead+=3200;
      }
    }
    if(timedOut) source.NotifyError(MediaStreamSourceErrorStatus::Other);
    else if(!cancelled) {
      if(buffer) {
        auto sample=MediaStreamSample::CreateFromBuffer(buffer,TimeSpan{static_cast<int64_t>(position*10000000/32000)});
        sample.Duration(TimeSpan{1000000});
        request.Sample(sample);
      } else request.Sample(nullptr);
    }
  } catch(...) {
    bool cancelled;
    {std::lock_guard lock(gate->mutex); cancelled=gate->cancelled;}
    if(!cancelled) {try {source.NotifyError(MediaStreamSourceErrorStatus::Other);} catch(...) {}}
  }
  // Deferral completion is part of pending work, even on cancellation/error.
  if(deferral) {try {deferral.Complete();} catch(...) {}}
  reading.reset();
}

struct PcmSource {
  MediaStreamSource source{nullptr};
  event_token requested{}, starting{};
  explicit PcmSource(std::shared_ptr<GateState> gate) {
    source=MediaStreamSource(AudioStreamDescriptor(AudioEncodingProperties::CreatePcm(16000,1,16)));
    // Unspecified duration is an explicit diagnostic source profile. The
    // payload still ends normally; never replace PlaybackSession observations.
    if(!gate->unknownDuration) source.Duration(TimeSpan{120000000});
    source.CanSeek(false);
    source.BufferTime(TimeSpan{2500000});
    starting=source.Starting([](auto const&, auto const& args) {
      args.Request().SetActualStartPosition(TimeSpan{0});
    });
    requested=source.SampleRequested([gate](auto const& sender, auto const& args) {
      DeliverPcm(gate,sender,args.Request());
    });
  }
  void Detach() {
    if(source) {
      source.SampleRequested(requested);
      source.Starting(starting);
      source=nullptr;
    }
  }
};
}
