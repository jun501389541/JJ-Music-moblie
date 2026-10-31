// Test controller: queries only our explicit app ID/title marker, no other metadata.
#include <windows.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Media.Control.h>
#include <iostream>
#include <string>
#include <thread>
#include <chrono>
int main(int argc,char** argv) {
  if(argc!=3) return 2;
  winrt::init_apartment(winrt::apartment_type::multi_threaded);
  const auto marker=winrt::to_hstring(std::string("pid-")+argv[1]);
  const std::string command=argv[2];
  const char* stage="request-manager";
  try {
    auto manager=winrt::Windows::Media::Control::GlobalSystemMediaTransportControlsSessionManager::RequestAsync().get();
    stage="enumerate";
    unsigned notReady=0;
    // Sessions can outlive their media properties briefly. Retry discovery,
    // never an issued transport command (next is not idempotent).
    for(unsigned attempt=0;attempt<20;++attempt) {
    stage="enumerate";
    for(auto const& session:manager.GetSessions()) {
      stage="source-id";
      const auto source=std::wstring(session.SourceAppUserModelId());
      if(source!=L"JJMusic.OwnedDiagnostic" && source.find(L"jj_music_mobile")==std::wstring::npos) continue;
      stage="owned-properties";
      std::wstring title;
      try {title=std::wstring(session.TryGetMediaPropertiesAsync().get().Title());}
      catch(winrt::hresult_error const& error) {
        if(error.code().value!=HRESULT_FROM_WIN32(ERROR_NOT_READY)) throw;
        ++notReady; continue;
      }
      if(title.find(marker.c_str())==std::wstring::npos) continue;
      bool ok=false;
      stage="owned-command";
      if(command=="pause") ok=session.TryPauseAsync().get();
      if(command=="play") ok=session.TryPlayAsync().get();
      if(command=="next") ok=session.TrySkipNextAsync().get();
      if(command=="seek") ok=session.TryChangePlaybackPositionAsync(3000*10000LL).get();
      stage="owned-timeline";
      const auto timeline=session.GetTimelineProperties();
      std::cout<<"{\"found\":true,\"accepted\":"<<(ok?"true":"false")
        <<",\"skippedNotReady\":"<<notReady
        <<",\"positionTicks\":"<<timeline.Position().count()<<",\"endTicks\":"<<timeline.EndTime().count()<<"}"<<std::endl;
      return ok?0:3;
    }
    if(attempt+1<20) std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    std::cout<<"{\"found\":false,\"skippedNotReady\":"<<notReady<<"}"<<std::endl;
  }catch(winrt::hresult_error const& error){std::cout<<"{\"error\":true,\"stage\":\""<<stage<<"\",\"hresult\":\"0x"<<std::hex<<static_cast<uint32_t>(error.code().value)<<"\"}"<<std::endl;}
  return 1;
}
