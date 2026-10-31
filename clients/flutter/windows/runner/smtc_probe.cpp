// Test controller: queries only our explicit app ID/title marker, no other metadata.
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Media.Control.h>
#include <iostream>
#include <string>
int main(int argc,char** argv) {
  if(argc!=3) return 2;
  winrt::init_apartment(winrt::apartment_type::multi_threaded);
  const auto marker=winrt::to_hstring(std::string("pid-")+argv[1]);
  const std::string command=argv[2];
  try {
    auto manager=winrt::Windows::Media::Control::GlobalSystemMediaTransportControlsSessionManager::RequestAsync().get();
    for(auto const& session:manager.GetSessions()) {
      const auto source=std::wstring(session.SourceAppUserModelId());
      if(source!=L"JJMusic.OwnedDiagnostic" && source.find(L"jj_music_mobile")==std::wstring::npos) continue;
      const auto title=std::wstring(session.TryGetMediaPropertiesAsync().get().Title());
      if(title.find(marker.c_str())==std::wstring::npos) continue;
      bool ok=false;
      if(command=="pause") ok=session.TryPauseAsync().get();
      if(command=="play") ok=session.TryPlayAsync().get();
      if(command=="next") ok=session.TrySkipNextAsync().get();
      if(command=="seek") ok=session.TryChangePlaybackPositionAsync(3000*10000LL).get();
      const auto timeline=session.GetTimelineProperties();
      std::cout<<"{\"found\":true,\"accepted\":"<<(ok?"true":"false")
        <<",\"positionTicks\":"<<timeline.Position().count()<<",\"endTicks\":"<<timeline.EndTime().count()<<"}"<<std::endl;
      return ok?0:3;
    }
    std::cout<<"{\"found\":false}"<<std::endl;
  }catch(winrt::hresult_error const&){std::cout<<"{\"error\":true}"<<std::endl;}
  return 1;
}
