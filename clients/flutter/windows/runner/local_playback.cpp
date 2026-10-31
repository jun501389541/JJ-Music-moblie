#include "local_playback.h"
#include "owned_gate_stream.h"
#include "owned_pcm_source.h"
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Media.h>
#include <winrt/Windows.Media.Core.h>
#include <winrt/Windows.Media.Playback.h>
#include <winrt/Windows.Media.Control.h>
#include <systemmediatransportcontrolsinterop.h>
#include <atomic>
#include <map>
#include <mutex>
#include <vector>
#include <future>

using flutter::EncodableValue;
using flutter::EncodableMap;
using flutter::EncodableList;
using namespace winrt;
using namespace Windows::Media;
using namespace Windows::Media::Playback;
using namespace Windows::Media::Core;
using namespace Windows::Foundation;
namespace {
std::string Text(const EncodableMap& m, const char* key) {
  const auto it = m.find(EncodableValue(key));
  return it == m.end() ? "" : std::get<std::string>(it->second);
}
int64_t Number(const EncodableMap& m, const char* key) {
  const auto& v = m.at(EncodableValue(key));
  if (std::holds_alternative<int32_t>(v)) return std::get<int32_t>(v);
  return std::get<int64_t>(v);
}
struct Track {
  MediaPlayer player{nullptr};
  std::shared_ptr<owned_loading::GateState> gate;
  std::unique_ptr<owned_loading::PcmSource> pcm;
  Windows::Storage::Streams::IRandomAccessStream stream{nullptr};
  MediaSource source{nullptr};
  std::atomic_bool opened{false}, ended{false}, failed{false};
  event_token openedToken{}, endedToken{}, failedToken{};
  bool intended = false;
  bool closed = false;
  bool closeRequested = false;
  bool playerClosed = false, sourceClosed = false, streamClosed = false;
  bool hooksRegistered = false;
  bool failSourceCloseOnce = false;
  void Close() {
    if(closed) return;
    closeRequested=true;
    if(gate) gate->Cancel();
    std::exception_ptr failure;
    auto attempt=[&](auto operation) {
      try { operation(); } catch(...) { if(!failure) failure=std::current_exception(); }
    };
    if(pcm) attempt([&] {pcm->Detach();});
    if(player && !playerClosed) {
      if(hooksRegistered) {
        attempt([&] {player.MediaOpened(openedToken);});
        attempt([&] {player.MediaEnded(endedToken);});
        attempt([&] {player.MediaFailed(failedToken);});
      }
      attempt([&] {player.Close(); playerClosed=true;});
    } else if(!player) playerClosed=true;
    if(!sourceClosed) {
      attempt([&] {
        if(failSourceCloseOnce) {failSourceCloseOnce=false; throw hresult_error(E_FAIL,L"owned-injected-source-close");}
        if(source) source.Close();
        sourceClosed=true;
        if(gate) {std::lock_guard lock(gate->mutex); gate->sourceClosed=true;}
      });
    }
    if(!streamClosed) {
      attempt([&] {
        if(stream) stream.Close();
        streamClosed=true;
        if(gate) {std::lock_guard lock(gate->mutex); gate->streamClosed=true;}
      });
    }
    closed=playerClosed && sourceClosed && streamClosed;
    if(failure) std::rethrow_exception(failure);
  }
  ~Track() noexcept { try {Close();} catch(...) {} }
};
struct Commands {
  std::mutex mutex;
  EncodableList pending;
  void Push(const std::string& command, int64_t position = 0) {
    std::lock_guard<std::mutex> lock(mutex);
    if (pending.size() < 32) pending.emplace_back(EncodableMap{
      {EncodableValue("command"), EncodableValue(command)},
      {EncodableValue("position"), EncodableValue(position)}});
  }
};
}
struct LocalPlayback::Impl {
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel;
  std::map<std::string, std::shared_ptr<Track>> tracks;
  std::shared_ptr<Commands> commands = std::make_shared<Commands>();
  SystemMediaTransportControls smtc{nullptr};
  event_token buttonToken{}, seekToken{};
  std::future<EncodableMap> probe;
  EncodableMap probeResult;
  std::string lastTitle;
  std::string lastError, mirrorStage;
  std::string mirroredStatus;
  int64_t mirroredDuration=0;
  bool failNextPlay=false;
  std::map<std::string,std::shared_ptr<owned_loading::GateState>> registeredGates, streamGates;
  std::map<std::string,std::vector<std::unique_ptr<flutter::MethodResult<EncodableValue>>>> closing;
  uint64_t nextGate=0;
  UINT_PTR closeTimer=0;
  static auto& Timers() {
    static std::map<UINT_PTR,Impl*> values;
    return values;
  }
  static void CALLBACK TimerProc(HWND,UINT,UINT_PTR id,DWORD) {
    // Registry lookup makes an already-queued timer harmless after teardown.
    const auto it=Timers().find(id);
    if(it!=Timers().end()) it->second->FinishClosures();
  }
  void StartCloseTimer() {
    if(closeTimer) return;
    closeTimer=::SetTimer(nullptr,0,10,TimerProc);
    if(!closeTimer) throw hresult_error(HRESULT_FROM_WIN32(GetLastError()));
    Timers().emplace(closeTimer,this);
  }
  void StopCloseTimer() {
    Timers().erase(closeTimer);
    if(closeTimer) ::KillTimer(nullptr,closeTimer);
    closeTimer=0;
  }
  void FinishClosures() {
    for(auto it=closing.begin();it!=closing.end();) {
      auto t=tracks.at(it->first);
      if(t->gate && !t->gate->FinishClose()) { ++it; continue; }
      auto results=std::move(it->second);
      tracks.erase(it->first);
      it=closing.erase(it);
      for(auto& result:results) result->Success();
    }
    if(closing.empty()) StopCloseTimer();
  }
  explicit Impl(flutter::BinaryMessenger* messenger, HWND window) {
    auto interop = get_activation_factory<SystemMediaTransportControls,
      ISystemMediaTransportControlsInterop>();
    check_hresult(interop->GetForWindow(window, guid_of<SystemMediaTransportControls>(),
      put_abi(smtc)));
    smtc.IsEnabled(true);
    smtc.IsPlayEnabled(true); smtc.IsPauseEnabled(true);
    smtc.IsStopEnabled(true); smtc.IsNextEnabled(true); smtc.IsPreviousEnabled(true);
    auto weak = std::weak_ptr<Commands>(commands);
    buttonToken = smtc.ButtonPressed([weak](auto const&, auto const& args) {
      auto q = weak.lock(); if (!q) return;
      switch (args.Button()) {
        case SystemMediaTransportControlsButton::Play: q->Push("play"); break;
        case SystemMediaTransportControlsButton::Pause: q->Push("pause"); break;
        case SystemMediaTransportControlsButton::Stop: q->Push("stop"); break;
        case SystemMediaTransportControlsButton::Next: q->Push("next"); break;
        case SystemMediaTransportControlsButton::Previous: q->Push("previous"); break;
        default: break;
      }
    });
    seekToken = smtc.PlaybackPositionChangeRequested([weak](auto const&, auto const& args) {
      if (auto q = weak.lock()) q->Push("seek", args.RequestedPlaybackPosition().count()/10000);
    });
    channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "jj_music/local", &flutter::StandardMethodCodec::GetInstance());
    channel->SetMethodCallHandler([this](auto const& call, auto result) {
      try {
        EncodableMap empty;
        const auto* args = std::get_if<EncodableMap>(call.arguments());
        const auto& m = args ? *args : empty;
        const auto& method = call.method_name();
        if(method=="registerOwnedGate" || method=="registerOwnedPcm") {
          const auto* bytes=std::get_if<std::vector<uint8_t>>(&m.at(EncodableValue("bytes")));
          if(!bytes || bytes->size()<44 || bytes->size()>2*1024*1024 ||
             std::memcmp(bytes->data(),"RIFF",4)!=0 || std::memcmp(bytes->data()+8,"WAVE",4)!=0)
            throw hresult_invalid_argument();
          if(method=="registerOwnedPcm") owned_loading::ValidatePcm(*bytes);
          if(registeredGates.size()>=8) {
            auto old=std::find_if(registeredGates.begin(),registeredGates.end(),[](auto const& entry) {
              std::lock_guard lock(entry.second->mutex);
              return !entry.second->claimed || (entry.second->cancelled && entry.second->readers==0);
            });
            if(old==registeredGates.end()) throw hresult_invalid_argument();
            registeredGates.erase(old);
          }
          const auto token="owned-gate:"+std::to_string(++nextGate);
          auto gate=std::make_shared<owned_loading::GateState>(*bytes);
          gate->pcm=method=="registerOwnedPcm";
          registeredGates.emplace(token,gate);
          result->Success(EncodableValue(token)); return;
        } else if(method=="failOwnedClose") {
          auto t=tracks.at(Text(m,"id"));
          if(!t->gate) throw hresult_invalid_argument();
          t->failSourceCloseOnce=true;
        } else if(method=="allowOwnedRead") {
          const auto it=streamGates.find(Text(m,"id"));
          if(it!=streamGates.end()) it->second->Allow();
        } else if (method == "prepare") {
          if (tracks.size() >= 2) throw hresult_invalid_argument();
          const auto id = Text(m,"id"), path = Text(m,"path");
          if (id.empty() || tracks.contains(id)) throw hresult_invalid_argument();
          // Only explicit local file URI generated by the fixture-only Dart resolver.
          const auto gated=registeredGates.find(path);
          if (path.rfind("file:",0) != 0 && gated==registeredGates.end()) throw hresult_invalid_argument();
          auto t = std::make_shared<Track>(); t->player = MediaPlayer();
          if(gated!=registeredGates.end()) {
            {
              std::lock_guard lock(gated->second->mutex);
              if(gated->second->claimed) throw hresult_invalid_argument();
              gated->second->claimed=true;
            }
            t->gate=gated->second;
            if(t->gate->pcm) t->pcm=std::make_unique<owned_loading::PcmSource>(t->gate);
            else t->stream=make<owned_loading::GateStream>(t->gate);
            if(streamGates.size()>=8 && !streamGates.contains(id)) {
              auto old=std::find_if(streamGates.begin(),streamGates.end(),[this](auto const& entry) {return !tracks.contains(entry.first);});
              if(old==streamGates.end()) throw hresult_invalid_argument();
              streamGates.erase(old);
            }
            streamGates[id]=t->gate;
          } else streamGates.erase(id);
          t->player.AutoPlay(false);
          t->player.CommandManager().IsEnabled(false);
          t->player.SystemMediaTransportControls().IsEnabled(false);
          std::weak_ptr<Track> weak = t;
          t->openedToken = t->player.MediaOpened([weak](auto const&, auto const&) {
            if (auto v=weak.lock()) v->opened=true;
          });
          t->endedToken = t->player.MediaEnded([weak](auto const&, auto const&) {
            if (auto v=weak.lock()) v->ended=true;
          });
          t->failedToken = t->player.MediaFailed([weak](auto const&, auto const&) {
            if (auto v=weak.lock()) v->failed=true;
          });
          t->hooksRegistered=true;
          tracks.emplace(id,t);
          if(t->gate) {
            t->source=t->pcm ? MediaSource::CreateFromMediaStreamSource(t->pcm->source) :
              MediaSource::CreateFromStream(t->stream,L"audio/wav");
            t->player.Source(t->source);
          } else t->player.Source(MediaSource::CreateFromUri(Uri(to_hstring(path))));
        } else if (method == "play") {
          for (auto const& entry: tracks) {
            if (entry.first != Text(m,"id")) { entry.second->intended=false; entry.second->player.Pause(); }
          }
          if(failNextPlay) {failNextPlay=false; throw hresult_error(E_FAIL,L"owned-injected-play-failure");}
          auto t=tracks.at(Text(m,"id")); t->intended=true; t->player.Play();
        } else if (method == "pause" || method == "stop") {
          for (auto const& entry: tracks) { entry.second->intended=false; entry.second->player.Pause(); }
        } else if (method == "seek") {
          tracks.at(Text(m,"id"))->player.PlaybackSession().Position(
            TimeSpan{Number(m,"position")*10000});
        } else if (method == "release") {
          // Destruction revokes callbacks and Close finishes before returning receipt.
          const auto id=Text(m,"id");
          if(auto it=tracks.find(id);it!=tracks.end()) {
            if(it->second->gate) StartCloseTimer();
            it->second->Close();
            if(it->second->gate) {
              closing[id].push_back(std::move(result));
              // WM_TIMER completes replies only on this platform thread, after
              // all async reads drain. No dependence on a Dart polling timer.
              FinishClosures(); return;
            }
            tracks.erase(it);
          }
        } else if (method == "mirror") {
          mirrorStage="enabled";
          smtc.IsEnabled(true);
          const auto title=Text(m,"title"), status=Text(m,"status");
          smtc.PlaybackStatus(status=="playing" ? MediaPlaybackStatus::Playing :
            status=="paused" ? MediaPlaybackStatus::Paused : MediaPlaybackStatus::Stopped);
          if(lastTitle!=title) {
            auto updater=smtc.DisplayUpdater(); updater.ClearAll();
            updater.Type(MediaPlaybackType::Music);
            updater.MusicProperties().Title(to_hstring(title)); updater.Update();
            lastTitle=title;
          }
          SystemMediaTransportControlsTimelineProperties timeline;
          mirrorStage="timeline-values";
          timeline.StartTime(TimeSpan{0}); timeline.MinSeekTime(TimeSpan{0});
          timeline.EndTime(TimeSpan{Number(m,"duration")*10000});
          timeline.MaxSeekTime(timeline.EndTime());
          timeline.Position(TimeSpan{Number(m,"position")*10000});
          smtc.UpdateTimelineProperties(timeline);
          mirroredStatus=status; mirroredDuration=Number(m,"duration");
          mirrorStage="complete";
        } else if (method == "osCommand") {
          if (probe.valid()) throw hresult_invalid_argument();
          auto command = Text(m,"command");
          const auto marker = std::wstring(L"pid-")+std::to_wstring(GetCurrentProcessId());
          probe = std::async(std::launch::async, [command,marker]() -> EncodableMap {
            init_apartment(apartment_type::multi_threaded);
            bool found=false, accepted=false;
            try {
              auto manager = Windows::Media::Control::GlobalSystemMediaTransportControlsSessionManager::RequestAsync().get();
              for (auto const& session: manager.GetSessions()) {
                // Never query another app's media metadata.
                const auto source = std::wstring(session.SourceAppUserModelId());
                if (source!=L"JJMusic.OwnedDiagnostic" && source.find(L"jj_music_mobile") == std::wstring::npos) continue;
                const auto title=std::wstring(session.TryGetMediaPropertiesAsync().get().Title());
                if(title.rfind(L"JJ owned ",0)!=0) continue;
                if(title.find(marker)==std::wstring::npos) continue;
                found=true;
                if(command=="pause") accepted=session.TryPauseAsync().get();
                else if(command=="play") accepted=session.TryPlayAsync().get();
                else if(command=="next") accepted=session.TrySkipNextAsync().get();
                else if(command=="seek") accepted=session.TryChangePlaybackPositionAsync(3000*10000LL).get();
                break;
              }
            } catch(hresult_error const&) {}
            return {{EncodableValue("found"),EncodableValue(found)},
              {EncodableValue("accepted"),EncodableValue(accepted)},
              {EncodableValue("command"),EncodableValue(command)}};
          });
        } else if (method == "failNextPlay") {
          failNextPlay=true;
        } else if (method == "poll") {
          if(probe.valid() && probe.wait_for(std::chrono::milliseconds(0))==std::future_status::ready) {
            probeResult=probe.get();
          }
          EncodableList samples;
          for (auto const& entry: tracks) {
            if(entry.second->closeRequested) continue;
            auto t=entry.second; auto s=t->player.PlaybackSession();
            auto state=s.PlaybackState();
            samples.emplace_back(EncodableMap{
              {EncodableValue("id"),EncodableValue(entry.first)},
              {EncodableValue("platform"),EncodableValue("windows")},
              {EncodableValue("nativeState"),EncodableValue(static_cast<int32_t>(state))},
              {EncodableValue("state"),EncodableValue(state==MediaPlaybackState::Playing ? 3 : state==MediaPlaybackState::Buffering ? 2 : 1)},
              {EncodableValue("ready"),EncodableValue(t->opened.load())},
              {EncodableValue("nativePlaying"),EncodableValue(state==MediaPlaybackState::Playing)},
              {EncodableValue("playWhenReady"),EncodableValue(t->intended)},
              {EncodableValue("position"),EncodableValue(s.Position().count()/10000)},
              {EncodableValue("duration"),EncodableValue(s.NaturalDuration().count()/10000)},
              {EncodableValue("ended"),EncodableValue(t->ended.load())},
              {EncodableValue("error"),EncodableValue(t->failed.load())}});
          }
          EncodableList actions;
          EncodableMap gates;
          for(auto const& entry:streamGates) {
            const auto& g=entry.second; std::lock_guard lock(g->mutex);
            gates.emplace(EncodableValue(entry.first),EncodableMap{
              {EncodableValue("inputKind"),EncodableValue(g->pcm ? "pcm-sample-request" : "random-access-read")},
              {EncodableValue("blocked"),EncodableValue(g->waiting>0)},
              {EncodableValue("readers"),EncodableValue(g->readers)},
              {EncodableValue("bytesRead"),EncodableValue(g->bytesRead)},
              {EncodableValue("waitedMs"),EncodableValue(g->waitedMs)},
              {EncodableValue("closed"),EncodableValue(g->closed)},
              {EncodableValue("sourceClosed"),EncodableValue(g->sourceClosed)},
              {EncodableValue("streamClosed"),EncodableValue(g->streamClosed)},
              {EncodableValue("cancelled"),EncodableValue(g->cancelled)}});
          }
          { std::lock_guard<std::mutex> lock(commands->mutex); actions.swap(commands->pending); }
          result->Success(EncodableMap{{EncodableValue("samples"),EncodableValue(samples)},
            {EncodableValue("streamGates"),EncodableValue(gates)},
            {EncodableValue("osResult"),EncodableValue(probeResult)},
            {EncodableValue("smtcEnabled"),EncodableValue(smtc.IsEnabled())},
            {EncodableValue("mirrorStage"),EncodableValue(mirrorStage)},
            {EncodableValue("lastNativeError"),EncodableValue(lastError)},
            {EncodableValue("mirroredStatus"),EncodableValue(mirroredStatus)},
            {EncodableValue("mirroredDuration"),EncodableValue(mirroredDuration)},
            {EncodableValue("commands"),EncodableValue(actions)}}); return;
        } else { result->NotImplemented(); return; }
        result->Success();
      } catch (hresult_error const& error) {
        lastError=to_string(error.message());
        result->Error("winrt",to_string(error.message()));
      } catch (std::exception const& error) { lastError=error.what(); result->Error("native","invalid-native-operation"); }
    });
  }
  ~Impl() {
    StopCloseTimer();
    channel->SetMethodCallHandler(nullptr);
    smtc.ButtonPressed(buttonToken); smtc.PlaybackPositionChangeRequested(seekToken);
    smtc.IsEnabled(false); smtc.DisplayUpdater().ClearAll();
    for(auto const& entry:tracks) entry.second->Close();
    tracks.clear(); commands.reset();
  }
};
LocalPlayback::LocalPlayback(flutter::BinaryMessenger* messenger, HWND window)
  : impl_(std::make_unique<Impl>(messenger,window)) {}
LocalPlayback::~LocalPlayback() = default;
