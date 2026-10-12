#ifndef HEADLESS_CONNECTION_IS_INCLUDED
#define HEADLESS_CONNECTION_IS_INCLUDED

#include "outside_world.h"

class HeadlessConnection : public Outside_World
{
public:
	class HeadlessWindow : public Outside_World::WindowInterface
	{
	public:
		virtual void Start(void) override;
		virtual void Stop(void) override;
		virtual void Interval(void) override;
		virtual void Render(bool swapBuffers) override;
		virtual void UpdateImage(TownsRender::ImageCopy &img) override;
		virtual void Communicate(Outside_World *outside_world) override;
	};

	class HeadlessSound : public Outside_World::Sound
	{
	public:
		virtual void Start(void) override;
		virtual void Stop(void) override;
		virtual void Polling(void) override;

		virtual void CDDAPlay(
		    const DiscImage &discImg,
		    DiscImage::MinSecFrm from,
		    DiscImage::MinSecFrm to,
		    bool repeat,
		    unsigned int,
		    unsigned int) override;

		virtual void CDDASetVolume(float leftVol,float rightVol) override;
		virtual void CDDAStop(void) override;
		virtual void CDDAPause(void) override;
		virtual void CDDAResume(void) override;
		virtual bool CDDAIsPlaying(void) override;
		virtual DiscImage::MinSecFrm CDDACurrentPosition(void) override;

		virtual void FMPCMPlay(std::vector <unsigned char> &wave) override;
		virtual void FMPCMPlayStop(void) override;
		virtual bool FMPCMChannelPlaying(void) override;

		virtual void BeepPlay(int samplingRate,std::vector<unsigned char> &wave) override;
		virtual void BeepPlayStop(void) override;
		virtual bool BeepChannelPlaying(void) const override;
	};

	virtual void Start(void) override;
	virtual void Stop(void) override;
	virtual void DevicePolling(class FMTownsCommon &towns) override;

	virtual bool ImageNeedsFlip(void) override;
	virtual void SetKeyboardLayout(unsigned int layout) override;

	virtual WindowInterface *CreateWindowInterface(void) const override;
	virtual void DeleteWindowInterface(WindowInterface *ptr) const override;

	virtual Sound *CreateSound(void) const override;
	virtual void DeleteSound(Sound *ptr) const override;
};

#endif
