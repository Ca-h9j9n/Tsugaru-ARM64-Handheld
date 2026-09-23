#include "v90s_connection.h"
#include "towns.h"

#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <algorithm>
#include <cstring>
#include <dlfcn.h>

#include <linux/input.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

////////////////////////////////////////////////////////////
// Minimal EGL definitions
////////////////////////////////////////////////////////////

typedef void *EGLDisplay;
typedef void *EGLConfig;
typedef void *EGLContext;
typedef void *EGLSurface;
typedef void *EGLNativeDisplayType;
typedef void *EGLNativeWindowType;

typedef int EGLint;
typedef unsigned int EGLBoolean;
typedef unsigned int EGLenum;

#define EGL_FALSE 0
#define EGL_TRUE  1

#define EGL_DEFAULT_DISPLAY ((EGLNativeDisplayType)0)

#define EGL_NO_DISPLAY ((EGLDisplay)0)
#define EGL_NO_CONTEXT ((EGLContext)0)
#define EGL_NO_SURFACE ((EGLSurface)0)

#define EGL_NONE                    0x3038
#define EGL_SURFACE_TYPE            0x3033
#define EGL_WINDOW_BIT              0x0004
#define EGL_RENDERABLE_TYPE         0x3040
#define EGL_OPENGL_ES2_BIT          0x0004
#define EGL_RED_SIZE                0x3024
#define EGL_GREEN_SIZE              0x3023
#define EGL_BLUE_SIZE               0x3022
#define EGL_CONTEXT_CLIENT_VERSION  0x3098
#define EGL_OPENGL_ES_API           0x30A0
#define EGL_WIDTH                   0x3057
#define EGL_HEIGHT                  0x3056


////////////////////////////////////////////////////////////
// Minimal GLES2 definitions
////////////////////////////////////////////////////////////

typedef unsigned int GLuint;
typedef int GLint;
typedef int GLsizei;
typedef unsigned int GLenum;
typedef unsigned char GLboolean;
typedef float GLfloat;
typedef char GLchar;

#define GL_FALSE               0
#define GL_TRUE                1

#define GL_COLOR_BUFFER_BIT    0x00004000

#define GL_TEXTURE_2D          0x0DE1
#define GL_TEXTURE0            0x84C0

#define GL_TEXTURE_MIN_FILTER  0x2801
#define GL_TEXTURE_MAG_FILTER  0x2800
#define GL_TEXTURE_WRAP_S      0x2802
#define GL_TEXTURE_WRAP_T      0x2803

#define GL_NEAREST             0x2600
#define GL_CLAMP_TO_EDGE       0x812F

#define GL_RGBA                0x1908
#define GL_UNSIGNED_BYTE       0x1401

#define GL_FLOAT               0x1406
#define GL_TRIANGLE_STRIP      0x0005

#define GL_VERTEX_SHADER       0x8B31
#define GL_FRAGMENT_SHADER     0x8B30

#define GL_COMPILE_STATUS      0x8B81
#define GL_LINK_STATUS         0x8B82


////////////////////////////////////////////////////////////
// EGL function types
////////////////////////////////////////////////////////////

typedef EGLDisplay (*PFNEGLGETDISPLAY)(EGLNativeDisplayType);
typedef EGLBoolean (*PFNEGLINITIALIZE)(EGLDisplay,EGLint *,EGLint *);
typedef EGLBoolean (*PFNEGLCHOOSECONFIG)(
    EGLDisplay,const EGLint *,EGLConfig *,EGLint,EGLint *);
typedef EGLBoolean (*PFNEGLBINDAPI)(EGLenum);
typedef EGLContext (*PFNEGLCREATECONTEXT)(
    EGLDisplay,EGLConfig,EGLContext,const EGLint *);
typedef EGLSurface (*PFNEGLCREATEWINDOWSURFACE)(
    EGLDisplay,EGLConfig,EGLNativeWindowType,const EGLint *);
typedef EGLBoolean (*PFNEGLMAKECURRENT)(
    EGLDisplay,EGLSurface,EGLSurface,EGLContext);
typedef EGLBoolean (*PFNEGLSWAPBUFFERS)(EGLDisplay,EGLSurface);
typedef EGLBoolean (*PFNEGLDESTROYCONTEXT)(EGLDisplay,EGLContext);
typedef EGLBoolean (*PFNEGLDESTROYSURFACE)(EGLDisplay,EGLSurface);
typedef EGLBoolean (*PFNEGLTERMINATE)(EGLDisplay);
typedef EGLBoolean (*PFNEGLQUERYSURFACE)(
    EGLDisplay,EGLSurface,EGLint,EGLint *);
typedef EGLint (*PFNEGLGETERROR)(void);


////////////////////////////////////////////////////////////
// GLES2 function types
////////////////////////////////////////////////////////////

typedef void (*PFNGLCLEARCOLOR)(GLfloat,GLfloat,GLfloat,GLfloat);
typedef void (*PFNGLCLEAR)(GLenum);
typedef void (*PFNGLVIEWPORT)(GLint,GLint,GLsizei,GLsizei);

typedef void (*PFNGLGENTEXTURES)(GLsizei,GLuint *);
typedef void (*PFNGLDELETETEXTURES)(GLsizei,const GLuint *);
typedef void (*PFNGLBINDTEXTURE)(GLenum,GLuint);
typedef void (*PFNGLTEXPARAMETERI)(GLenum,GLenum,GLint);
typedef void (*PFNGLTEXIMAGE2D)(
    GLenum,GLint,GLint,GLsizei,GLsizei,
    GLint,GLenum,GLenum,const void *);
typedef void (*PFNGLACTIVETEXTURE)(GLenum);

typedef GLuint (*PFNGLCREATESHADER)(GLenum);
typedef void (*PFNGLSHADERSOURCE)(
    GLuint,GLsizei,const GLchar *const *,const GLint *);
typedef void (*PFNGLCOMPILESHADER)(GLuint);
typedef void (*PFNGLGETSHADERIV)(GLuint,GLenum,GLint *);
typedef void (*PFNGLGETSHADERINFOLOG)(
    GLuint,GLsizei,GLsizei *,GLchar *);
typedef void (*PFNGLDELETESHADER)(GLuint);

typedef GLuint (*PFNGLCREATEPROGRAM)(void);
typedef void (*PFNGLATTACHSHADER)(GLuint,GLuint);
typedef void (*PFNGLLINKPROGRAM)(GLuint);
typedef void (*PFNGLGETPROGRAMIV)(GLuint,GLenum,GLint *);
typedef void (*PFNGLGETPROGRAMINFOLOG)(
    GLuint,GLsizei,GLsizei *,GLchar *);
typedef void (*PFNGLDELETEPROGRAM)(GLuint);
typedef void (*PFNGLUSEPROGRAM)(GLuint);

typedef GLint (*PFNGLGETATTRIBLOCATION)(GLuint,const GLchar *);
typedef GLint (*PFNGLGETUNIFORMLOCATION)(GLuint,const GLchar *);
typedef void (*PFNGLUNIFORM1I)(GLint,GLint);

typedef void (*PFNGLENABLEVERTEXATTRIBARRAY)(GLuint);
typedef void (*PFNGLDISABLEVERTEXATTRIBARRAY)(GLuint);
typedef void (*PFNGLVERTEXATTRIBPOINTER)(
    GLuint,GLint,GLenum,GLboolean,GLsizei,const void *);

typedef void (*PFNGLDRAWARRAYS)(GLenum,GLint,GLsizei);


////////////////////////////////////////////////////////////
// Function pointers
////////////////////////////////////////////////////////////

static PFNEGLGETDISPLAY eglGetDisplay=nullptr;
static PFNEGLINITIALIZE eglInitialize=nullptr;
static PFNEGLCHOOSECONFIG eglChooseConfig=nullptr;
static PFNEGLBINDAPI eglBindAPI=nullptr;
static PFNEGLCREATECONTEXT eglCreateContext=nullptr;
static PFNEGLCREATEWINDOWSURFACE eglCreateWindowSurface=nullptr;
static PFNEGLMAKECURRENT eglMakeCurrent=nullptr;
static PFNEGLSWAPBUFFERS eglSwapBuffers=nullptr;
static PFNEGLDESTROYCONTEXT eglDestroyContext=nullptr;
static PFNEGLDESTROYSURFACE eglDestroySurface=nullptr;
static PFNEGLTERMINATE eglTerminate=nullptr;
static PFNEGLQUERYSURFACE eglQuerySurface=nullptr;
static PFNEGLGETERROR eglGetError=nullptr;

static PFNGLCLEARCOLOR glClearColor=nullptr;
static PFNGLCLEAR glClear=nullptr;
static PFNGLVIEWPORT glViewport=nullptr;

static PFNGLGENTEXTURES glGenTextures=nullptr;
static PFNGLDELETETEXTURES glDeleteTextures=nullptr;
static PFNGLBINDTEXTURE glBindTexture=nullptr;
static PFNGLTEXPARAMETERI glTexParameteri=nullptr;
static PFNGLTEXIMAGE2D glTexImage2D=nullptr;
static PFNGLACTIVETEXTURE glActiveTexture=nullptr;

static PFNGLCREATESHADER glCreateShader=nullptr;
static PFNGLSHADERSOURCE glShaderSource=nullptr;
static PFNGLCOMPILESHADER glCompileShader=nullptr;
static PFNGLGETSHADERIV glGetShaderiv=nullptr;
static PFNGLGETSHADERINFOLOG glGetShaderInfoLog=nullptr;
static PFNGLDELETESHADER glDeleteShader=nullptr;

static PFNGLCREATEPROGRAM glCreateProgram=nullptr;
static PFNGLATTACHSHADER glAttachShader=nullptr;
static PFNGLLINKPROGRAM glLinkProgram=nullptr;
static PFNGLGETPROGRAMIV glGetProgramiv=nullptr;
static PFNGLGETPROGRAMINFOLOG glGetProgramInfoLog=nullptr;
static PFNGLDELETEPROGRAM glDeleteProgram=nullptr;
static PFNGLUSEPROGRAM glUseProgram=nullptr;

static PFNGLGETATTRIBLOCATION glGetAttribLocation=nullptr;
static PFNGLGETUNIFORMLOCATION glGetUniformLocation=nullptr;
static PFNGLUNIFORM1I glUniform1i=nullptr;

static PFNGLENABLEVERTEXATTRIBARRAY glEnableVertexAttribArray=nullptr;
static PFNGLDISABLEVERTEXATTRIBARRAY glDisableVertexAttribArray=nullptr;
static PFNGLVERTEXATTRIBPOINTER glVertexAttribPointer=nullptr;
static PFNGLDRAWARRAYS glDrawArrays=nullptr;


template <class T>
static bool LoadProc(T &dst,void *lib,const char *name)
{
	dst=reinterpret_cast<T>(dlsym(lib,name));

	if(nullptr==dst)
	{
		std::printf("Missing symbol: %s\n",name);
		return false;
	}

	return true;
}


static GLuint CompileShader(GLenum type,const char *source)
{
	GLuint shader=glCreateShader(type);

	glShaderSource(shader,1,&source,nullptr);
	glCompileShader(shader);

	GLint status=0;
	glGetShaderiv(shader,GL_COMPILE_STATUS,&status);

	if(GL_TRUE!=status)
	{
		char log[2048];
		GLsizei len=0;

		glGetShaderInfoLog(shader,sizeof(log),&len,log);

		std::printf("Shader compile failed:\n%s\n",log);

		glDeleteShader(shader);
		return 0;
	}

	return shader;
}


////////////////////////////////////////////////////////////
// Start
////////////////////////////////////////////////////////////

void V90SConnection::V90SWindow::Start(void)
{
	std::printf("V90S EGL/GLES2 Start\n");

	eglLib=dlopen("libEGL.so.1",RTLD_NOW|RTLD_GLOBAL);
	glesLib=dlopen("libGLESv2.so.2",RTLD_NOW|RTLD_GLOBAL);

	if(nullptr==eglLib || nullptr==glesLib)
	{
		std::printf("Cannot load EGL/GLES2 libraries.\n");
		return;
	}


#define LOAD_EGL(fn) if(!LoadProc(fn,eglLib,#fn)) return
#define LOAD_GL(fn)  if(!LoadProc(fn,glesLib,#fn)) return

	LOAD_EGL(eglGetDisplay);
	LOAD_EGL(eglInitialize);
	LOAD_EGL(eglChooseConfig);
	LOAD_EGL(eglBindAPI);
	LOAD_EGL(eglCreateContext);
	LOAD_EGL(eglCreateWindowSurface);
	LOAD_EGL(eglMakeCurrent);
	LOAD_EGL(eglSwapBuffers);
	LOAD_EGL(eglDestroyContext);
	LOAD_EGL(eglDestroySurface);
	LOAD_EGL(eglTerminate);
	LOAD_EGL(eglQuerySurface);
	LOAD_EGL(eglGetError);

	LOAD_GL(glClearColor);
	LOAD_GL(glClear);
	LOAD_GL(glViewport);

	LOAD_GL(glGenTextures);
	LOAD_GL(glDeleteTextures);
	LOAD_GL(glBindTexture);
	LOAD_GL(glTexParameteri);
	LOAD_GL(glTexImage2D);
	LOAD_GL(glActiveTexture);

	LOAD_GL(glCreateShader);
	LOAD_GL(glShaderSource);
	LOAD_GL(glCompileShader);
	LOAD_GL(glGetShaderiv);
	LOAD_GL(glGetShaderInfoLog);
	LOAD_GL(glDeleteShader);

	LOAD_GL(glCreateProgram);
	LOAD_GL(glAttachShader);
	LOAD_GL(glLinkProgram);
	LOAD_GL(glGetProgramiv);
	LOAD_GL(glGetProgramInfoLog);
	LOAD_GL(glDeleteProgram);
	LOAD_GL(glUseProgram);

	LOAD_GL(glGetAttribLocation);
	LOAD_GL(glGetUniformLocation);
	LOAD_GL(glUniform1i);

	LOAD_GL(glEnableVertexAttribArray);
	LOAD_GL(glDisableVertexAttribArray);
	LOAD_GL(glVertexAttribPointer);
	LOAD_GL(glDrawArrays);

#undef LOAD_EGL
#undef LOAD_GL


	EGLDisplay display=eglGetDisplay(EGL_DEFAULT_DISPLAY);

	if(EGL_NO_DISPLAY==display)
	{
		std::printf("eglGetDisplay failed.\n");
		return;
	}

	EGLint major=0,minor=0;

	if(EGL_TRUE!=eglInitialize(display,&major,&minor))
	{
		std::printf(
		    "eglInitialize failed: %04X\n",
		    eglGetError());
		return;
	}

	std::printf("EGL %d.%d\n",major,minor);


	EGLint cfgAttr[]=
	{
		EGL_SURFACE_TYPE,EGL_WINDOW_BIT,
		EGL_RENDERABLE_TYPE,EGL_OPENGL_ES2_BIT,
		EGL_RED_SIZE,8,
		EGL_GREEN_SIZE,8,
		EGL_BLUE_SIZE,8,
		EGL_NONE
	};

	EGLConfig config=nullptr;
	EGLint configCount=0;

	if(EGL_TRUE!=eglChooseConfig(
	    display,
	    cfgAttr,
	    &config,
	    1,
	    &configCount) ||
	   configCount<1)
	{
		std::printf("eglChooseConfig failed.\n");
		return;
	}


	eglBindAPI(EGL_OPENGL_ES_API);

	EGLint ctxAttr[]=
	{
		EGL_CONTEXT_CLIENT_VERSION,2,
		EGL_NONE
	};

	EGLContext context=
	    eglCreateContext(
	        display,
	        config,
	        EGL_NO_CONTEXT,
	        ctxAttr);

	if(EGL_NO_CONTEXT==context)
	{
		std::printf("eglCreateContext failed.\n");
		return;
	}


	EGLSurface surface=
	    eglCreateWindowSurface(
	        display,
	        config,
	        nullptr,
	        nullptr);

	if(EGL_NO_SURFACE==surface)
	{
		std::printf(
		    "eglCreateWindowSurface failed: %04X\n",
		    eglGetError());
		return;
	}


	if(EGL_TRUE!=eglMakeCurrent(
	    display,
	    surface,
	    surface,
	    context))
	{
		std::printf("eglMakeCurrent failed.\n");
		return;
	}


	eglDisplay=display;
	eglContext=context;
	eglSurface=surface;

	eglQuerySurface(
	    display,
	    surface,
	    EGL_WIDTH,
	    &surfaceWid);

	eglQuerySurface(
	    display,
	    surface,
	    EGL_HEIGHT,
	    &surfaceHei);

	std::printf(
	    "V90S Surface: %d x %d\n",
	    surfaceWid,
	    surfaceHei);


	const char *vertexShaderSource=
	    "attribute vec2 aPos;\n"
	    "attribute vec2 aTex;\n"
	    "varying vec2 vTex;\n"
	    "void main()\n"
	    "{\n"
	    "    gl_Position=vec4(aPos,0.0,1.0);\n"
	    "    vTex=aTex;\n"
	    "}\n";

	const char *fragmentShaderSource=
	    "precision mediump float;\n"
	    "varying vec2 vTex;\n"
	    "uniform sampler2D uTex;\n"
	    "void main()\n"
	    "{\n"
	    "    gl_FragColor=texture2D(uTex,vTex);\n"
	    "}\n";


	GLuint vs=
	    CompileShader(
	        GL_VERTEX_SHADER,
	        vertexShaderSource);

	GLuint fs=
	    CompileShader(
	        GL_FRAGMENT_SHADER,
	        fragmentShaderSource);

	if(0==vs || 0==fs)
	{
		return;
	}


	program=glCreateProgram();

	glAttachShader(program,vs);
	glAttachShader(program,fs);
	glLinkProgram(program);

	GLint linked=0;

	glGetProgramiv(
	    program,
	    GL_LINK_STATUS,
	    &linked);

	if(GL_TRUE!=linked)
	{
		char log[2048];
		GLsizei len=0;

		glGetProgramInfoLog(
		    program,
		    sizeof(log),
		    &len,
		    log);

		std::printf(
		    "Program link failed:\n%s\n",
		    log);

		return;
	}


	glDeleteShader(vs);
	glDeleteShader(fs);


	attrPos=
	    glGetAttribLocation(
	        program,
	        "aPos");

	attrTex=
	    glGetAttribLocation(
	        program,
	        "aTex");

	uniformTex=
	    glGetUniformLocation(
	        program,
	        "uTex");


	glGenTextures(1,&texture);
	glBindTexture(GL_TEXTURE_2D,texture);

	glTexParameteri(
	    GL_TEXTURE_2D,
	    GL_TEXTURE_MIN_FILTER,
	    GL_NEAREST);

	glTexParameteri(
	    GL_TEXTURE_2D,
	    GL_TEXTURE_MAG_FILTER,
	    GL_NEAREST);

	glTexParameteri(
	    GL_TEXTURE_2D,
	    GL_TEXTURE_WRAP_S,
	    GL_CLAMP_TO_EDGE);

	glTexParameteri(
	    GL_TEXTURE_2D,
	    GL_TEXTURE_WRAP_T,
	    GL_CLAMP_TO_EDGE);


	glClearColor(0,0,0,1);
	glClear(GL_COLOR_BUFFER_BIT);
	eglSwapBuffers(display,surface);

	std::printf("V90S renderer ready.\n");
}


////////////////////////////////////////////////////////////
// Stop
////////////////////////////////////////////////////////////

void V90SConnection::V90SWindow::Stop(void)
{
	EGLDisplay display=
	    reinterpret_cast<EGLDisplay>(
	        eglDisplay);

	EGLContext context=
	    reinterpret_cast<EGLContext>(
	        eglContext);

	EGLSurface surface=
	    reinterpret_cast<EGLSurface>(
	        eglSurface);


	if(nullptr!=eglDisplay)
	{
		if(0!=texture)
		{
			glDeleteTextures(1,&texture);
			texture=0;
		}

		if(0!=program)
		{
			glDeleteProgram(program);
			program=0;
		}


		eglMakeCurrent(
		    display,
		    EGL_NO_SURFACE,
		    EGL_NO_SURFACE,
		    EGL_NO_CONTEXT);

		if(EGL_NO_SURFACE!=surface)
		{
			eglDestroySurface(
			    display,
			    surface);
		}

		if(EGL_NO_CONTEXT!=context)
		{
			eglDestroyContext(
			    display,
			    context);
		}

		eglTerminate(display);
	}


	eglDisplay=nullptr;
	eglContext=nullptr;
	eglSurface=nullptr;


	if(nullptr!=glesLib)
	{
		dlclose(glesLib);
		glesLib=nullptr;
	}

	if(nullptr!=eglLib)
	{
		dlclose(eglLib);
		eglLib=nullptr;
	}
}


////////////////////////////////////////////////////////////
// Interval
////////////////////////////////////////////////////////////

void V90SConnection::V90SWindow::Interval(void)
{
	BaseInterval();

	{
		std::lock_guard<std::mutex> lock(deviceStateLock);
		winThr.VMClosed=shared.VMClosedFromVMThread;
	}
}


////////////////////////////////////////////////////////////
// Render
////////////////////////////////////////////////////////////

void V90SConnection::V90SWindow::Render(bool swapBuffers)
{

	if(nullptr==eglDisplay ||
	   nullptr==eglSurface ||
	   0==program ||
	   0==texture)
	{
		return;
	}

	auto &img=winThr.mostRecentImage;

	if(0==img.wid ||
	   0==img.hei ||
	   img.rgba.empty())
	{

		// BLACK = Waiting for the first Tsugaru image.
		glViewport(0,0,surfaceWid,surfaceHei);
		glClearColor(0.0f,0.0f,0.0f,1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		if(true==swapBuffers)
		{
			eglSwapBuffers(
			    reinterpret_cast<EGLDisplay>(eglDisplay),
			    reinterpret_cast<EGLSurface>(eglSurface));
		}

		return;
	}

	glViewport(
	    0,
	    0,
	    surfaceWid,
	    surfaceHei);

	glClearColor(
	    0.0f,
	    0.0f,
	    0.0f,
	    1.0f);

	glClear(GL_COLOR_BUFFER_BIT);

	/*
	    Maintain aspect ratio.
	*/
	float screenAspect=
	    float(surfaceWid)/
	    float(surfaceHei);

	float imageAspect=
	    float(img.wid)/
	    float(img.hei);

	float sx=1.0f;
	float sy=1.0f;

	if(imageAspect>screenAspect)
	{
		sy=
		    screenAspect/
		    imageAspect;
	}
	else
	{
		sx=
		    imageAspect/
		    screenAspect;
	}


	/*
	    Texture row 0 is the top of the Tsugaru image.
	    Match the existing FsSimpleWindow orientation.
	*/
	const GLfloat vertices[]=
	{
	    -sx, +sy,  0.0f,0.0f,
	    +sx, +sy,  1.0f,0.0f,
	    -sx, -sy,  0.0f,1.0f,
	    +sx, -sy,  1.0f,1.0f
	};


	glActiveTexture(GL_TEXTURE0);

	glBindTexture(
	    GL_TEXTURE_2D,
	    texture);

	glTexImage2D(
	    GL_TEXTURE_2D,
	    0,
	    GL_RGBA,
	    img.wid,
	    img.hei,
	    0,
	    GL_RGBA,
	    GL_UNSIGNED_BYTE,
	    img.rgba.data());


	glUseProgram(program);

	glUniform1i(
	    uniformTex,
	    0);


	glEnableVertexAttribArray(attrPos);

	glVertexAttribPointer(
	    attrPos,
	    2,
	    GL_FLOAT,
	    GL_FALSE,
	    4*sizeof(GLfloat),
	    vertices);


	glEnableVertexAttribArray(attrTex);

	glVertexAttribPointer(
	    attrTex,
	    2,
	    GL_FLOAT,
	    GL_FALSE,
	    4*sizeof(GLfloat),
	    vertices+2);


	glDrawArrays(
	    GL_TRIANGLE_STRIP,
	    0,
	    4);


	glDisableVertexAttribArray(attrPos);
	glDisableVertexAttribArray(attrTex);


	if(true==swapBuffers)
	{
		eglSwapBuffers(
		    reinterpret_cast<EGLDisplay>(
		        eglDisplay),
		    reinterpret_cast<EGLSurface>(
		        eglSurface));
	}
}


void V90SConnection::V90SWindow::UpdateImage(
    TownsRender::ImageCopy &img)
{
	(void)img;
}


void V90SConnection::V90SWindow::Communicate(
    Outside_World *outside_world)
{
	(void)outside_world;

	{
		std::lock_guard<std::mutex> lock(deviceStateLock);

		winThr.VMClosed=
		    shared.VMClosedFromVMThread;
	}
}

////////////////////////////////////////////////////////////
// Input
////////////////////////////////////////////////////////////

void V90SConnection::DevicePolling(class FMTownsCommon &towns)
{
	if(inputFd<0)
	{
		char inputDevice[256]=
		    "/dev/input/by-path/platform-adc_joystick-event-joystick";

		FILE *fp=std::fopen(
		    "/userdata/system/tsugaru/input.cfg",
		    "r");

		if(nullptr!=fp)
		{
			char str[512];

			while(nullptr!=std::fgets(str,sizeof(str),fp))
			{
				if(0==std::strncmp(str,"EVENT=",6))
				{
					char *value=str+6;

					while(' '==*value || '\t'==*value)
					{
						++value;
					}

					if('"'==*value)
					{
						++value;
						char *end=std::strchr(value,'"');

						if(nullptr!=end)
						{
							*end=0;
						}
					}
					else
					{
						char *end=value;

						while(0!=*end &&
						      '\r'!=*end &&
						      '\n'!=*end &&
						      ' '!=*end &&
						      '\t'!=*end)
						{
							++end;
						}

						*end=0;
					}

					if(0!=value[0])
					{
						std::strncpy(
						    inputDevice,
						    value,
						    sizeof(inputDevice)-1);

						inputDevice[
						    sizeof(inputDevice)-1]=0;
					}

					break;
				}
			}

			rewind(fp);

			while(nullptr!=std::fgets(str,sizeof(str),fp))
			{
				if(0==std::strncmp(str,"A_CODE=",7))
				{
					padACode=std::atoi(str+7);
				}
				else if(0==std::strncmp(str,"B_CODE=",7))
				{
					padBCode=std::atoi(str+7);
				}
				else if(0==std::strncmp(str,"START_CODE=",11))
				{
					padStartCode=std::atoi(str+11);
				}
				else if(0==std::strncmp(str,"SELECT_CODE=",12))
				{
					padSelectCode=std::atoi(str+12);
				}
				else if(0==std::strncmp(str,"DPAD_X_CODE=",12))
				{
					padXCode=std::atoi(str+12);
				}
				else if(0==std::strncmp(str,"DPAD_Y_CODE=",12))
				{
					padYCode=std::atoi(str+12);
				}
				else if(0==std::strncmp(str,"DPAD_TYPE=",10))
				{
					if(0==std::strncmp(str+10,"ABS",3))
					{
						padDpadIsAbs=true;
					}
					else if(0==std::strncmp(str+10,"KEY",3))
					{
						padDpadIsAbs=false;
					}
				}
				else if(0==std::strncmp(str,"DPAD_UP_CODE=",13))
				{
					padUpCode=std::atoi(str+13);
				}
				else if(0==std::strncmp(str,"DPAD_DOWN_CODE=",15))
				{
					padDownCode=std::atoi(str+15);
				}
				else if(0==std::strncmp(str,"DPAD_LEFT_CODE=",15))
				{
					padLeftCode=std::atoi(str+15);
				}
				else if(0==std::strncmp(str,"DPAD_RIGHT_CODE=",16))
				{
					padRightCode=std::atoi(str+16);
				}
				else if(0==std::strncmp(str,"DPAD_X_REVERSE=",15))
				{
					padXReverse=(0!=std::atoi(str+15));
				}
				else if(0==std::strncmp(str,"DPAD_Y_REVERSE=",15))
				{
					padYReverse=(0!=std::atoi(str+15));
				}
			}

			std::fclose(fp);
		}

		std::printf(
		    "V90S INPUT: A=%d B=%d START=%d SELECT=%d\n",
		    padACode,
		    padBCode,
		    padStartCode,
		    padSelectCode);

		std::printf(
		    "V90S INPUT: DPAD TYPE=%s X=%d Y=%d XREV=%d YREV=%d\n",
		    (true==padDpadIsAbs ? "ABS" : "KEY"),
		    padXCode,
		    padYCode,
		    (true==padXReverse ? 1 : 0),
		    (true==padYReverse ? 1 : 0));

		if(false==padDpadIsAbs)
		{
			std::printf(
			    "V90S INPUT: DPAD KEY UP=%d DOWN=%d LEFT=%d RIGHT=%d\n",
			    padUpCode,
			    padDownCode,
			    padLeftCode,
			    padRightCode);
		}

		std::printf(
		    "V90S INPUT: Opening %s\n",
		    inputDevice);
		std::fflush(stdout);

		inputFd=
		    open(
		        inputDevice,
		        O_RDONLY|O_NONBLOCK);

		if(inputFd<0)
		{
			std::printf(
			    "V90S INPUT: Cannot open gamepad device errno=%d\n",
			    errno);
			std::fflush(stdout);
			return;
		}
	}

	struct input_event ev;

	while(sizeof(ev)==read(inputFd,&ev,sizeof(ev)))
	{
		if(EV_ABS==ev.type && true==padDpadIsAbs)
		{
			if(ev.code==padXCode)
			{
				if(false==padXReverse)
				{
					padLeft =(ev.value<0);
					padRight=(0<ev.value);
				}
				else
				{
					padLeft =(0<ev.value);
					padRight=(ev.value<0);
				}

				if(0==ev.value)
				{
					mouseDX=0;
				}
				else if((ev.value<0) != padXReverse)
				{
					mouseDX=4;
				}
				else
				{
					mouseDX=-4;
				}
			}
			else if(ev.code==padYCode)
			{
				if(false==padYReverse)
				{
					padUp  =(ev.value<0);
					padDown=(0<ev.value);
				}
				else
				{
					padUp  =(0<ev.value);
					padDown=(ev.value<0);
				}

				if(0==ev.value)
				{
					mouseDY=0;
				}
				else if((ev.value<0) != padYReverse)
				{
					mouseDY=4;
				}
				else
				{
					mouseDY=-4;
				}
			}
		}
		else if(EV_KEY==ev.type)
		{
			const bool pressed=(0!=ev.value);

			if(ev.code==padACode)
			{
				padA=pressed;
			}
			else if(ev.code==padBCode)
			{
				padB=pressed;
			}
			else if(ev.code==padStartCode)
			{
				padStart=pressed;
			}
			else if(ev.code==padSelectCode)
			{
				padSelect=pressed;
			}
			else if(false==padDpadIsAbs && ev.code==padUpCode)
			{
				padUp=pressed;
			}
			else if(false==padDpadIsAbs && ev.code==padDownCode)
			{
				padDown=pressed;
			}
			else if(false==padDpadIsAbs && ev.code==padLeftCode)
			{
				padLeft=pressed;
			}
			else if(false==padDpadIsAbs && ev.code==padRightCode)
			{
				padRight=pressed;
			}
		}
	}

	towns.SetGamePadState(
	    0,
	    padA,
	    padB,
	    padLeft,
	    padRight,
	    padUp,
	    padDown,
	    padStart,
	    padSelect);
	towns.SetMouseMotion(
	    1,
	    mouseDX,
	    mouseDY);

	towns.SetMouseButtonState(
	    padA,
	    padB);
	if(true==padStart && true==padSelect)
	{
		if(true!=exitComboActive)
		{
			exitComboActive=true;
			exitComboStart=std::chrono::steady_clock::now();
		}
		else
		{
			auto held=
			    std::chrono::duration_cast<std::chrono::milliseconds>(
			        std::chrono::steady_clock::now()-exitComboStart).count();

			if(2000<=held)
			{
				std::printf(
				    "V90S: START+SELECT held for 2 seconds. Requesting shutdown.\n");
				std::fflush(stdout);

				towns.var.powerOff=true;
                exitComboActive=false;
			}
		}
	}
	else
	{
		exitComboActive=false;
	}
}

////////////////////////////////////////////////////////////
// Sound
////////////////////////////////////////////////////////////

Outside_World::Sound *
V90SConnection::CreateSound(void) const
{
	return new V90SSound;
}

void V90SConnection::DeleteSound(
    Outside_World::Sound *ptr) const
{
	auto sound=
	    dynamic_cast<V90SSound *>(ptr);

	if(nullptr!=sound)
	{
		delete sound;
	}
}

void V90SConnection::V90SSound::Start(void)
{
	std::printf("V90S SOUND: Starting ALSA sound.\n");
	std::fflush(stdout);

	soundPlayer.Start();
	cddaStartHSG=0;

	YsSoundPlayer::StreamingOption streamOpt;
	streamOpt.ringBufferLengthMillisec=
	    TownsSound::FM_PCM_MILLISEC_PER_WAVE*2+
	    TownsSound::WAVE_STREAMING_SAFETY_BUFFER;

	soundPlayer.StartStreaming(
	    FMPCMStream,
	    streamOpt);
}

void V90SConnection::V90SSound::Stop(void)
{
	soundPlayer.End();
}

void V90SConnection::V90SSound::Polling(void)
{
	soundPlayer.KeepPlaying();
}

void V90SConnection::V90SSound::CDDAPlay(
    const DiscImage &discImg,
    DiscImage::MinSecFrm from,
    DiscImage::MinSecFrm to,
    bool repeat,
    unsigned int,
    unsigned int)
{
	auto wave=discImg.GetWave(from,to);

	cddaChannel.CreateFromSigned16bitStereo(
	    44100,
	    wave);

	if(true==repeat)
	{
		soundPlayer.PlayBackground(
		    cddaChannel);
	}
	else
	{
		soundPlayer.PlayOneShot(
		    cddaChannel);
	}

	cddaStartHSG=from.ToHSG();
}

void V90SConnection::V90SSound::CDDASetVolume(
    float leftVol,
    float rightVol)
{
	soundPlayer.SetVolumeLR(
	    cddaChannel,
	    leftVol,
	    rightVol);
}

void V90SConnection::V90SSound::CDDAStop(void)
{
	soundPlayer.Stop(
	    cddaChannel);
}

void V90SConnection::V90SSound::CDDAPause(void)
{
	soundPlayer.Pause(
	    cddaChannel);
}

void V90SConnection::V90SSound::CDDAResume(void)
{
	soundPlayer.Resume(
	    cddaChannel);
}

bool V90SConnection::V90SSound::CDDAIsPlaying(void)
{
	return
	    YSTRUE==
	    soundPlayer.IsPlaying(
	        cddaChannel);
}

DiscImage::MinSecFrm
V90SConnection::V90SSound::CDDACurrentPosition(void)
{
	double sec=
	    soundPlayer.GetCurrentPosition(
	        cddaChannel);

	unsigned long long secHSG=
	    (unsigned long long)(sec*75.0);

	unsigned long long posInDisc=
	    secHSG+cddaStartHSG;

	DiscImage::MinSecFrm msf;
	msf.FromHSG(posInDisc);

	return msf;
}

void V90SConnection::V90SSound::FMPCMPlay(
    std::vector<unsigned char> &wave)
{
	YsSoundPlayer::SoundData nextWave;

	nextWave.CreateFromSigned16bitStereo(
	    YM2612::WAVE_SAMPLING_RATE,
	    wave);

	soundPlayer.AddNextStreamingSegment(
	    FMPCMStream,
	    nextWave);
}

void V90SConnection::V90SSound::FMPCMPlayStop(void)
{
}

bool V90SConnection::V90SSound::FMPCMChannelPlaying(void)
{
	unsigned int numSamples=
	    (TownsSound::FM_PCM_MILLISEC_PER_WAVE*
	     YM2612::WAVE_SAMPLING_RATE+999)/1000;

	return
	    YSTRUE!=
	    soundPlayer.StreamPlayerReadyToAcceptNextNumSample(
	        FMPCMStream,
	        numSamples);
}

void V90SConnection::V90SSound::BeepPlay(
    int samplingRate,
    std::vector<unsigned char> &wave)
{
	BeepChannel.CreateFromSigned16bitStereo(
	    samplingRate,
	    wave);

	soundPlayer.PlayOneShot(
	    BeepChannel);
}

void V90SConnection::V90SSound::BeepPlayStop(void)
{
	soundPlayer.Stop(
	    BeepChannel);
}

bool V90SConnection::V90SSound::BeepChannelPlaying(void) const
{
	return
	    YSTRUE==
	    soundPlayer.IsPlaying(
	        BeepChannel);
}

////////////////////////////////////////////////////////////
// Create / Delete
////////////////////////////////////////////////////////////

Outside_World::WindowInterface *
V90SConnection::CreateWindowInterface(void) const
{
	return new V90SWindow;
}


void V90SConnection::DeleteWindowInterface(
    Outside_World::WindowInterface *ptr) const
{
	delete ptr;
}
