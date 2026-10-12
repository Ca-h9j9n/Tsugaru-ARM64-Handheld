#include "headless_connection.h"


////////////////////////////////////////////////////////////
// HeadlessConnection
////////////////////////////////////////////////////////////

void HeadlessConnection::Start(void)
{
}

void HeadlessConnection::Stop(void)
{
}

void HeadlessConnection::DevicePolling(class FMTownsCommon &towns)
{
	(void)towns;
}

bool HeadlessConnection::ImageNeedsFlip(void)
{
	return false;
}

void HeadlessConnection::SetKeyboardLayout(unsigned int layout)
{
	(void)layout;
}


////////////////////////////////////////////////////////////
// Window
////////////////////////////////////////////////////////////

void HeadlessConnection::HeadlessWindow::Start(void)
{
}

void HeadlessConnection::HeadlessWindow::Stop(void)
{
}

void HeadlessConnection::HeadlessWindow::Interval(void)
{
	// Consume pending frame data so the VM thread is not affected.
	BaseInterval();

	// Notify the main/window thread that the VM has terminated.
	{
		std::lock_guard<std::mutex> lock(deviceStateLock);
		winThr.VMClosed=shared.VMClosedFromVMThread;
	}
}

void HeadlessConnection::HeadlessWindow::Render(bool swapBuffers)
{
	(void)swapBuffers;

	// No display output.
	winThr.newImageRendered=false;
}

void HeadlessConnection::HeadlessWindow::UpdateImage(TownsRender::ImageCopy &img)
{
	(void)img;
}

void HeadlessConnection::HeadlessWindow::Communicate(Outside_World *outside_world)
{
	(void)outside_world;

	{
		std::lock_guard<std::mutex> lock(deviceStateLock);
		winThr.VMClosed=shared.VMClosedFromVMThread;
	}
}


Outside_World::WindowInterface *
HeadlessConnection::CreateWindowInterface(void) const
{
	return new HeadlessWindow;
}

void HeadlessConnection::DeleteWindowInterface(
    Outside_World::WindowInterface *ptr) const
{
	delete ptr;
}


////////////////////////////////////////////////////////////
// Sound
////////////////////////////////////////////////////////////

void HeadlessConnection::HeadlessSound::Start(void)
{
}

void HeadlessConnection::HeadlessSound::Stop(void)
{
}

void HeadlessConnection::HeadlessSound::Polling(void)
{
}

void HeadlessConnection::HeadlessSound::CDDAPlay(
    const DiscImage &discImg,
    DiscImage::MinSecFrm from,
    DiscImage::MinSecFrm to,
    bool repeat,
    unsigned int,
    unsigned int)
{
	(void)discImg;
	(void)from;
	(void)to;
	(void)repeat;
}

void HeadlessConnection::HeadlessSound::CDDASetVolume(
    float leftVol,float rightVol)
{
	(void)leftVol;
	(void)rightVol;
}

void HeadlessConnection::HeadlessSound::CDDAStop(void)
{
}

void HeadlessConnection::HeadlessSound::CDDAPause(void)
{
}

void HeadlessConnection::HeadlessSound::CDDAResume(void)
{
}

bool HeadlessConnection::HeadlessSound::CDDAIsPlaying(void)
{
	return false;
}

DiscImage::MinSecFrm
HeadlessConnection::HeadlessSound::CDDACurrentPosition(void)
{
	return {};
}

void HeadlessConnection::HeadlessSound::FMPCMPlay(
    std::vector<unsigned char> &wave)
{
	(void)wave;
}

void HeadlessConnection::HeadlessSound::FMPCMPlayStop(void)
{
}

bool HeadlessConnection::HeadlessSound::FMPCMChannelPlaying(void)
{
	return false;
}

void HeadlessConnection::HeadlessSound::BeepPlay(
    int samplingRate,
    std::vector<unsigned char> &wave)
{
	(void)samplingRate;
	(void)wave;
}

void HeadlessConnection::HeadlessSound::BeepPlayStop(void)
{
}

bool HeadlessConnection::HeadlessSound::BeepChannelPlaying(void) const
{
	return false;
}


Outside_World::Sound *
HeadlessConnection::CreateSound(void) const
{
	return new HeadlessSound;
}

void HeadlessConnection::DeleteSound(
    Outside_World::Sound *ptr) const
{
	delete ptr;
}
