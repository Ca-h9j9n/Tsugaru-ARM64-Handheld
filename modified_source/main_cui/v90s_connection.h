#ifndef V90S_CONNECTION_IS_INCLUDED
#define V90S_CONNECTION_IS_INCLUDED

#include "headless_connection.h"
#include "yssimplesound.h"
#include <chrono>
#include <linux/input.h>

class V90SConnection : public HeadlessConnection
{
public:
	int inputFd=-1;

	int padACode=BTN_SOUTH;
	int padBCode=BTN_EAST;
	int padStartCode=BTN_START;
	int padSelectCode=BTN_SELECT;

	int padXCode=ABS_HAT0X;
	int padYCode=ABS_HAT0Y;
	bool padDpadIsAbs=true;
	bool padXReverse=false;
	bool padYReverse=false;

	int padUpCode=KEY_UP;
	int padDownCode=KEY_DOWN;
	int padLeftCode=KEY_LEFT;
	int padRightCode=KEY_RIGHT;

	bool padA=false;
	bool padB=false;

	bool padLeft=false;
	bool padRight=false;
	bool padUp=false;
	bool padDown=false;

	bool padStart=false;
	bool padSelect=false;

	int mouseDX=0;
	int mouseDY=0;

	bool exitComboActive=false;
	std::chrono::steady_clock::time_point exitComboStart;

	virtual void DevicePolling(class FMTownsCommon &towns) override;

	class V90SWindow : public HeadlessConnection::HeadlessWindow
	{
	public:
		void *eglLib=nullptr;
		void *glesLib=nullptr;

		void *eglDisplay=nullptr;
		void *eglContext=nullptr;
		void *eglSurface=nullptr;

		unsigned int texture=0;
		unsigned int program=0;

		int attrPos=-1;
		int attrTex=-1;
		int uniformTex=-1;

		int surfaceWid=640;
		int surfaceHei=480;

		virtual void Start(void) override;
		virtual void Stop(void) override;
		virtual void Interval(void) override;
		virtual void Render(bool swapBuffers) override;
		virtual void UpdateImage(TownsRender::ImageCopy &img) override;
		virtual void Communicate(Outside_World *outside_world) override;
	};
	class V90SSound : public Outside_World::Sound
	{
	public:
		YsSoundPlayer soundPlayer;
		YsSoundPlayer::SoundData cddaChannel;
		unsigned long long cddaStartHSG=0;

		YsSoundPlayer::Stream FMPCMStream;
		YsSoundPlayer::SoundData BeepChannel;

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

		virtual void CDDASetVolume(
		    float leftVol,
		    float rightVol) override;

		virtual void CDDAStop(void) override;
		virtual void CDDAPause(void) override;
		virtual void CDDAResume(void) override;
		virtual bool CDDAIsPlaying(void) override;

		virtual DiscImage::MinSecFrm
		    CDDACurrentPosition(void) override;

		virtual void FMPCMPlay(
		    std::vector<unsigned char> &wave) override;

		virtual void FMPCMPlayStop(void) override;
		virtual bool FMPCMChannelPlaying(void) override;

		virtual void BeepPlay(
		    int samplingRate,
		    std::vector<unsigned char> &wave) override;

		virtual void BeepPlayStop(void) override;
		virtual bool BeepChannelPlaying(void) const override;
	};

	virtual Sound *CreateSound(void) const override;
	virtual void DeleteSound(Sound *ptr) const override;

	virtual WindowInterface *CreateWindowInterface(void) const override;
	virtual void DeleteWindowInterface(WindowInterface *ptr) const override;
};

#endif
