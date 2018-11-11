
newoption
{
	trigger = "game31st",
	description = "Enable The31st sample game"
}

newoption
{
	trigger = "mygame",
	description = "Enable Mygame"
}

newoption
{
	trigger = "simpleball",
	description = "Enable SimpleBall"
}

newoption
{
	trigger = "simplechar",
	description = "Enable SimpleChar"
}

newoption
{
	trigger = "monolith",
	description = "No Plugins"
}


if not os.is("windows") then
	newoption
	{
		trigger = "clang",
		description = "Use clang instead of gcc by default"
	}
	
	newoption
	{
		trigger = "asan",
		description = "Use GCC (4.8+) or clang (3.3+) Address Sanitizer for memory debugging"
	}
	
end

if _OPTIONS["asan"] then
	print("#### Using Address Sanitizer ####")
	print("  For the game to actually start you need to suppress some errors by setting evironment variables")
	print("  like: ASAN_OPTIONS=detect_odr_violation=1:alloc_dealloc_mismatch=0 ./Tombstone")
	print("  to make it abort (=> break into debugger) on error, append ':abort_on_error=1' to other options")
	print("  See https://github.com/google/sanitizers/wiki/AddressSanitizer for more info")
end


-- helper functions..
function appendToList(l1, l2)
	-- appends elements of l2 to l1
	for i=1, #l2 do
		table.insert(l1, l2[i])
	end
end

function concatLists(...)
	-- returns a list that is a concatenation of all given lists
	-- (ony works for arrays/lists, not generic tables!)
	ret = {}
	for i = 1, select('#', ...) do
		appendToList(ret, select(i, ...))
	end
	
	return ret
end

--
-- Common compiler flags for all projects
--

--[[
NOTE:
If you want to just use a list of flags in e.g.  buildoptions, call buildoptions
as a function in normal syntax, e.g. buildoptions(COMMON_CFLAGS)
If you need the contents from more than one list (or want to add items manually)
Use the concatLists function, like this:
  buildoptions( concatLists(COMMON_CFLAGS, {"-custom-flag1", "-custom-flag2"}) )
--]]

if os.is("windows") then -- MSVC flags
COMMON_CFLAGS = {
	-- TODO: common MSVC flags
}

COMMON_CXXFLAGS = {
	-- TODO: C++ MSVC flags (if any)
}
else -- GCC/Clang flags for both OSX and Linux
COMMON_CFLAGS = {
	"-pthread",
	"-ffast-math",
	"-fno-strict-aliasing",
	
	-- warnings
	"-Wall",
	"-Wuninitialized",
	--"-Wmaybe-uninitialized",
	
	-- warnings we don't want
	"-Wno-maybe-uninitialized",
	"-Wno-switch",
	"-Wno-multichar",
	"-Wno-char-subscripts", -- TODO: sometimes run build without this to be sure
	"-Wno-sign-compare",
	"-Wno-extra", -- for some fucking reason some versions of premake4 add -Wextra which is super noisy
}

-- flags specific to C++ (addition to CFLAGS)
COMMON_CXXFLAGS = {
	"-std=c++11",
	--"-fno-exceptions",
	--"-fno-rtti",
	--"-Wno-non-virtual-dtor",
	"-Wno-invalid-offsetof",
	"-Wno-reorder",
}
end -- else case of os.is("windows")

---
--- Some compiler-specific hacks
---

if _OPTIONS["clang"] then

--clang = "clang-4.0"
--clangxx = "clang++-4.0"
clang = "clang"
clangxx = "clang++"

-- hack to use clang instead of gcc by default
premake.gcc.platforms.x32.cc = clang
premake.gcc.platforms.x32.cxx = clangxx
premake.gcc.platforms.x64.cc = clang
premake.gcc.platforms.x64.cxx = clangxx
premake.gcc.platforms.Native.cc = clang
premake.gcc.platforms.Native.cxx = clangxx
premake.gcc.platforms.Universal32.cc = clang
premake.gcc.platforms.Universal32.cxx = clangxx
premake.gcc.platforms.Universal64.cc = clang
premake.gcc.platforms.Universal64.cxx = clangxx

CLANG_CFLAGS = {
	"-Wno-deprecated-register",
	"-Wno-unknown-warning-option",
}

CLANG_CXXFLAGS = {
	"-Wno-inline-new-delete",
	-- there seem to be missing tons of "override"s at methods, let's ignore that
	"-Wno-inconsistent-missing-override",
	"-Wno-return-type-c-linkage",
	"-Wno-unused-local-typedef",
	"-Wno-undefined-var-template"
}

appendToList(COMMON_CFLAGS, CLANG_CFLAGS)
appendToList(COMMON_CXXFLAGS, CLANG_CXXFLAGS)

end -- _OPTIONS["clang"]

--
-- Main solution
--
solution "Tombstone"
	configurations { "Debug", "Profile", "Release", "Retail" }
	platforms { "x64" }
	
	--
	-- Debug/Release Configurations
	--
	configuration "Debug"
		defines
		{
			"TERATHON_DEBUG",
            "_DEBUG"
		}
		symbols "On"
		vectorextensions "SSE"
		warnings "Extra"
		
	configuration "Profile"
		defines
		{
			"NDEBUG",
		}
		symbols "On"
		vectorextensions "SSE"
		optimize "Speed"
		warnings "Extra"
			
		if not os.is("windows") then
			staticruntime "On"
		end

	configuration "Release"
		defines
		{
			"NDEBUG"
		}
		symbols "Off"
		vectorextensions "SSE"
		optimize "Speed"
		warnings "Extra"

	configuration "Retail"
		defines
		{
			"NDEBUG",
			"TOMBSTONE_RETAIL"
		}
		symbols "Off"
		vectorextensions "SSE"
		optimize "Speed"
		warnings "Extra"
	
	configuration { "vs*" }
		targetdir ".."
		flags
		{
			"NoManifest",
			"NoMinimalRebuild",
			"No64BitChecks",
		}
		exceptionhandling "Off"
		editandcontinue "Off"
		buildoptions
		{
			-- multi processor support
			"/MP",
			
			-- warnings to ignore:
			-- "/wd4711", -- smells like old people
			
			-- warnings to force
			
			-- An accessor overrides, with or without the virtual keyword, a base class accessor function,
			-- but the override or new specifier was not part of the overriding function signature.
			"/we4485",
		}
		defines
		{
			"TOMBSTONE_WINDOWS",
			"TERATHON_NO_SYSTEM"
		}
		
	
	configuration { "vs*", "Debug" }
		buildoptions
		{
			-- turn off Smaller Type Check
			--"/RTC-",
		
			-- turn off Basic Runtime Checks
			--"/RTC1-",
		}
			
	configuration { "vs*", "Profile" }
		buildoptions
		{
			-- Produces a program database (PDB) that contains type information and symbolic debugging information for use with the debugger
			-- /Zi does imply /debug
			"/Zi",
			
			-- turn off Whole Program Optimization
			--"/GL-",
			
			-- Inline Function Expansion: Any Suitable (/Ob2)
			--"/Ob2",
			
			-- enable Intrinsic Functions
			"/Oi",
			
			-- Favor fast code
			"/Ot",
			
			-- Omit Frame Pointers - FIXME: maybe not for profile builds?
			"/Oy",
		}
		linkoptions
		{
			-- turn off Whole Program Optimization
			-- "/LTCG-",
			
			-- create .pdb file
			"/DEBUG",
		}
		
	configuration { "vs*", "Release" }
		buildoptions
		{
			-- turn off Whole Program Optimization
			--"/GL-",
			
			-- Inline Function Expansion: Any Suitable (/Ob2)
			"/Ob2",
			
			-- Favor fast code
			"/Ot",
			
			-- enable Intrinsic Functions
			"/Oi",
			
			-- Omit Frame Pointers
			"/Oy",
		}
		
	configuration { "vs*", "Retail" }
		buildoptions
		{
			-- turn off Whole Program Optimization
			--"/GL-",
			
			-- Inline Function Expansion: Any Suitable (/Ob2)
			"/Ob2",
			
			-- enable Intrinsic Functions
			"/Oi",
			
			-- Omit Frame Pointers
			"/Oy",
		}
		
	configuration { "vs*", "x32" }
		defines
		{
			"_CRT_SECURE_NO_DEPRECATE",
			"_CRT_NONSTDC_NO_DEPRECATE",
			--"_CRT_SECURE_NO_WARNINGS",
		}
			
	configuration { "linux" }
		targetdir ".."
		targetprefix ""
		buildoptions (COMMON_CFLAGS)
		linkoptions
		{
			--"-fno-exceptions",
			--"-fno-rtti",
			"-pthread",
			"-ldl",
			"-fuse-ld=gold"
		}
		defines
		{
			"TOMBSTONE_LINUX",
			--"TOMBSTONE_SDL"
		}
		if _OPTIONS["asan"] then
			linkoptions { "-fsanitize=address" }
			buildoptions { "-fsanitize=address", "-fno-omit-frame-pointer" }
			defines { "TOMBSTONE_EXTERNAL_MEM_DEBUG" }
		end



project "TombstoneApp"
	targetname "Tombstone"
	language "C++"
	kind "WindowedApp"
	files
	{
		"../TerathonCode/**.h", "../TerathonCode/**.cpp",
		"../EngineCode/**.h", "../EngineCode/**.cpp",
	}
	excludes
	{
		"../TerathonCode/TSFontBuilder.h", "../TerathonCode/TSFontBuilder.cpp",
	}
	defines
	{
		"TERATHON_EXPORT",
		"TOMBSTONE_ENGINE_MODULE",
	}
	includedirs
	{
		"../TerathonCode",
		"../EngineCode",
	}
	
	if _OPTIONS["monolith"] then
		configuration "linux"
			defines
			{
				"MONOLITH",
			}
			files
			{
				"../GameCode/**.h", "../GameCode/**.cpp",
			}
			includedirs
			{
				"../GameCode",
			}
			if not _OPTIONS["game31st"] then
				defines
				{
					"MYGAME",
				}
			end
	end

	configuration "vs*"
		flags 
		{
			"WinMain",
		}
		files
		{
			"../EngineCode/TSRsrcWindows.rc",
		}
		includedirs
		{
			"$(DXSDK_DIR)/include",
		}
		
	configuration { "vs*", "x64" }
		libdirs
		{
			"$(DXSDK_DIR)/lib/x64",
		}
		linkoptions
		{
			"/DEF:../EngineCode/TSModule64.def",
		}
		links
		{
			"advapi32",
			"gdi32",
			"kernel32",
			"ole32",
			"opengl32",
			"user32",
			"ws2_32",
			"winmm",
			"dinput8",
			"dsound",
			"dxguid",
			"Xinput9_1_0"
		}
			
	configuration { "linux" }
		defines
		{
			"PNG_NO_ASSEMBLER_CODE",
			"_REENTRANT" -- for SDL
		}
		excludes
		{
			"../EngineCode/TSWintab.cpp",
		}
		buildoptions( concatLists(COMMON_CXXFLAGS, { "`sdl2-config --cflags`"}) )
		linkoptions
		{
			-- for loading plugins
			"-rdynamic",
			"`sdl2-config --libs`",
			-- so libs (.so) that lie next to the executable can be found for dynamic linking
			"-Wl,-rpath,'$$ORIGIN'"
		}
		links
		{
			"GL",
			"X11",
			"Xrandr",
		}

		-- no more link options for pulse/alsa, they're loaded with dlopen()		
		--buildoptions
		--{
		--	"`pkg-config --cflags libpulse-simple`",
		--}

	

if _OPTIONS["mygame"] then
	project "MyGame"
		targetname "MyGame"
		language "C++"
		kind "SharedLib"
		files
		{
			"../MyGameCode/**.h", "../MyGameCode/**.cpp",
		}
		includedirs
		{
			"../TerathonCode",
			"../EngineCode",
			"../Plugins",
		}
		defines
		{
			"TERATHON_IMPORT",
			"MYGAME",
		}
		
		configuration "vs*"
			includedirs
			{
				"$(DXSDK_DIR)/include",
			}
			
		configuration { "vs*", "x64" }
			libdirs
			{
				"..",
				"../Plugins",
			}
			links
			{
				"TombstoneApp",
				"Tombstone",
			}
		
		configuration { "linux" }
			buildoptions(COMMON_CXXFLAGS)
		
			linkoptions
			{
				"-Wl,-whole-archive"
			}
			
end

	
if _OPTIONS["game31st"] then
	project "The31st"
		targetname "The31st"
		language "C++"
		kind "SharedLib"
		files
		{
			"../GameCode/**.h", "../GameCode/**.cpp",
		}
		includedirs
		{
			"../TerathonCode",
			"../EngineCode",
			"../Plugins",
		}
		defines
		{
			"TERATHON_IMPORT"
		}
	
		configuration "vs*"
			includedirs
			{
				"$(DXSDK_DIR)/include",
			}
			
		configuration { "vs*", "x64" }
			libdirs
			{
				"..",
				"../Plugins",
			}
			links
			{
				"TombstoneApp",
				"Tombstone",
			}
				
		configuration { "linux" }
			buildoptions(COMMON_CXXFLAGS)
			links
			{
				--"TombstoneLib",
			}
				

end -- if not _OPTIONS["game31st"] then
		
			
if _OPTIONS["simpleball"] then
	project "SimpleBall"
		targetname "SimpleBall"
		language "C++"
		kind "SharedLib"
		files
		{
			"../SimpleCode/SimpleBall.h", "../SimpleCode/SimpleBall.cpp",
		}
		includedirs
		{
			"../TerathonCode",
			"../EngineCode",
			--"../Plugins",
		}
		defines
		{
			"TERATHON_IMPORT",
		}
		
		configuration "vs*"
			includedirs
			{
				"$(DXSDK_DIR)/include",
			}
			
		configuration { "vs*", "x64" }
			libdirs
			{
				"..",
				--"../Plugins",
			}
			links
			{
				"TombstoneApp",
				"Tombstone",
			}
		
		configuration { "linux" }
			buildoptions(COMMON_CXXFLAGS)
		
			linkoptions
			{
				"-Wl,-whole-archive"
			}
			
end

if _OPTIONS["simplechar"] then
	project "SimpleChar"
		targetname "SimpleChar"
		language "C++"
		kind "SharedLib"
		files
		{
			"../SimpleCode/SimpleChar.h", "../SimpleCode/SimpleChar.cpp",
		}
		includedirs
		{
			"../TerathonCode",
			"../EngineCode",
			--"../Plugins",
		}
		defines
		{
			"TERATHON_IMPORT",
		}
		
		configuration "vs*"
			includedirs
			{
				"$(DXSDK_DIR)/include",
			}
			
		configuration { "vs*", "x64" }
			libdirs
			{
				"..",
				--"../Plugins",
			}
			links
			{
				"TombstoneApp",
				"Tombstone",
			}
		
		configuration { "linux" }
			buildoptions(COMMON_CXXFLAGS)
		
			linkoptions
			{
				"-Wl,-whole-archive"
			}
			
end


project "WorldEditor"
	--targetname "WorldEditor"
	targetdir "../Plugins/Tools"
	language "C++"
	kind "SharedLib"
	files
	{
		"../PluginCode/TSCameraDirectors.cpp",
		"../PluginCode/TSCameraDirectors.h",
		--"../PluginCode/TSColladaImporter.cpp",
		--"../PluginCode/TSColladaImporter.h",
		"../PluginCode/TSEditorBase.cpp",
		"../PluginCode/TSEditorBase.h",
		"../PluginCode/TSEditorBrush.cpp",
		"../PluginCode/TSEditorBrush.h",
		"../PluginCode/TSEditorCommands.cpp",
		"../PluginCode/TSEditorCommands.h",
		"../PluginCode/TSEditorConnectors.cpp",
		"../PluginCode/TSEditorConnectors.h",
		"../PluginCode/TSEditorGizmo.cpp",
		"../PluginCode/TSEditorGizmo.h",
		"../PluginCode/TSEditorDirectors.cpp",
		"../PluginCode/TSEditorDirectors.h",
		"../PluginCode/TSEditorOperations.cpp",
		"../PluginCode/TSEditorOperations.h",
		"../PluginCode/TSEditorPages.cpp",
		"../PluginCode/TSEditorPages.h",
		"../PluginCode/TSEditorPlugins.cpp",
		"../PluginCode/TSEditorPlugins.h",
		"../PluginCode/TSEditorSupplement.cpp",
		"../PluginCode/TSEditorSupplement.h",
		"../PluginCode/TSEditorTools.cpp",
		"../PluginCode/TSEditorTools.h",
		"../PluginCode/TSEditorViewports.cpp",
		"../PluginCode/TSEditorViewports.h",
		"../PluginCode/TSEffectDirectors.cpp",
		"../PluginCode/TSEffectDirectors.h",
		"../PluginCode/TSEmitterDirectors.cpp",
		"../PluginCode/TSEmitterDirectors.h",
		"../PluginCode/TSGeometryDirectors.cpp",
		"../PluginCode/TSGeometryDirectors.h",
		"../PluginCode/TSInstanceDirectors.cpp",
		"../PluginCode/TSInstanceDirectors.h",
		"../PluginCode/TSLandscaping.cpp",
		"../PluginCode/TSLandscaping.h",
		"../PluginCode/TSLightDirectors.cpp",
		"../PluginCode/TSLightDirectors.h",
		"../PluginCode/TSMarkerDirectors.cpp",
		"../PluginCode/TSMarkerDirectors.h",
		"../PluginCode/TSMaterialEditor.cpp",
		"../PluginCode/TSMaterialEditor.h",
		"../PluginCode/TSModelDirectors.cpp",
		"../PluginCode/TSModelDirectors.h",
		"../PluginCode/TSModelViewer.cpp",
		"../PluginCode/TSModelViewer.h",
		--"../PluginCode/TSMoviePlayer.cpp",
		--"../PluginCode/TSMoviePlayer.h",
		"../PluginCode/TSNodeInfo.cpp",
		"../PluginCode/TSNodeInfo.h",
		"../PluginCode/TSPanelEditor.cpp",
		"../PluginCode/TSPanelEditor.h",
		"../PluginCode/TSPhysicsDirectors.cpp",
		"../PluginCode/TSPhysicsDirectors.h",
		"../PluginCode/TSPortalDirectors.cpp",
		"../PluginCode/TSPortalDirectors.h",
		--"../PluginCode/TSResourcePacker.cpp",
		--"../PluginCode/TSResourcePacker.h",
		"../PluginCode/TSScriptEditor.cpp",
		"../PluginCode/TSScriptEditor.h",
		"../PluginCode/TSShaderEditor.cpp",
		"../PluginCode/TSShaderEditor.h",
		--"../PluginCode/TSSoundPlayer.cpp",
		--"../PluginCode/TSSoundPlayer.h",
		"../PluginCode/TSSourceDirectors.cpp",
		"../PluginCode/TSSourceDirectors.h",
		"../PluginCode/TSSpaceDirectors.cpp",
		"../PluginCode/TSSpaceDirectors.h",
		--"../PluginCode/TSStringImporter.cpp",
		--"../PluginCode/TSStringImporter.h",
		"../PluginCode/TSTerrainBuilders.cpp",
		"../PluginCode/TSTerrainBuilders.h",
		--"../PluginCode/TSTerrainPalette.cpp",
		--"../PluginCode/TSTerrainPalette.h",
		"../PluginCode/TSTerrainTools.cpp",
		"../PluginCode/TSTerrainTools.h",
		--"../PluginCode/TSTextureGenerator.cpp",
		--"../PluginCode/TSTextureGenerator.h",
		--"../PluginCode/TSTextureImporter.cpp",
		--"../PluginCode/TSTextureImporter.h",
		--"../PluginCode/TSTextureTool.cpp",
		--"../PluginCode/TSTextureTool.h",
		--"../PluginCode/TSTextureViewer.cpp",
		--"../PluginCode/TSTextureViewer.h",
		"../PluginCode/TSTriggerDirectors.cpp",
		"../PluginCode/TSTriggerDirectors.h",
		"../PluginCode/TSVolumeDirectors.cpp",
		"../PluginCode/TSVolumeDirectors.h",
		"../PluginCode/TSWaterTools.cpp",
		"../PluginCode/TSWaterTools.h",
		"../PluginCode/TSWorldEditor.cpp",
		"../PluginCode/TSWorldEditor.h",
		"../PluginCode/TSZoneDirectors.cpp",
		"../PluginCode/TSZoneDirectors.h",
	}
	defines
	{
		"TERATHON_IMPORT",
		"TOMBSTONE_EDITOR",
	}
	includedirs
	{
		"../TerathonCode",
		"../EngineCode",
	}

	configuration "vs*"
		includedirs
		{
			"$(DXSDK_DIR)/include",
		}
		buildoptions
		{
			-- warnings to ignore - most of them for openexr:
			"/wd4018", -- signed/unsigned missmatch
			"/wd4100", -- unused function parameter
			"/wd4127", -- cond expression is constant
			"/wd4131", -- old-style function declaration
			"/wd4244", -- possible loss of data (int->char, double->float etc)
			"/wd4305", -- initialization double->const float, poss. loss of data
			"/wd4512", -- assignment operators could not be generated
			
				-- something about except handling and /EHsc not set:
			"/wd4530", -- FIXME: do we really want to suppress this?
			
			"/wd4702", -- unreachable code
			"/wd4800", -- forcing int value to bool (performance warning)
			"/wd4996", -- "unsafe" functions aka advertisement for *_s bullshit
		}
		
	configuration { "vs*", "x64" }
		libdirs
		{
			"..",
		}
		links
		{
			"TombstoneApp",
			"Tombstone"
		}
			
	configuration { "linux" }
		buildoptions(COMMON_CXXFLAGS)

		
		
project "TextureTool"
	--targetname "TextureTool"
	targetdir "../Plugins/Tools"
	language "C++"
	kind "SharedLib"
	files
	{
		"../PluginCode/TSTerrainPalette.cpp",
		"../PluginCode/TSTerrainPalette.h",
		"../PluginCode/TSTextureGenerator.cpp",
		"../PluginCode/TSTextureGenerator.h",
		"../PluginCode/TSTextureImporter.cpp",
		"../PluginCode/TSTextureImporter.h",
		"../PluginCode/TSTextureTool.cpp",
		"../PluginCode/TSTextureTool.h",
		"../PluginCode/TSTextureViewer.cpp",
		"../PluginCode/TSTextureViewer.h",
	}
	defines
	{
		"TERATHON_IMPORT",
		"TOMBSTONE_TEXTURE",
	}
	includedirs
	{
		"../TerathonCode",
		"../EngineCode",
	}

	configuration "vs*"
		defines
		{
			"_CRT_SECURE_NO_DEPRECATE",
			"_CRT_NONSTDC_NO_DEPRECATE",
			--"_CRT_SECURE_NO_WARNINGS",
		}
		includedirs
		{
			"$(DXSDK_DIR)/include",
		}
		
	configuration { "vs*", "x64" }
		libdirs
		{
			"..",
		}
		links
		{
			"TombstoneApp",
			"Tombstone",
		}
			
	configuration { "linux" }
		buildoptions(COMMON_CXXFLAGS)
		

		
project "ColladaImporter"
	--targetname "ColladaImporter"
	targetdir "../Plugins/Tools/Editor"
	language "C++"
	kind "SharedLib"
	files
	{
		"../PluginCode/TSColladaImporter.cpp",
		"../PluginCode/TSColladaImporter.h",
	}
	defines
	{
		"TERATHON_IMPORT",
	}
	includedirs
	{
		"../TerathonCode",
		"../EngineCode",
	}

	configuration "vs*"
		includedirs
		{
			"$(DXSDK_DIR)/include",
		}
		
	configuration { "vs*", "x64" }
		libdirs
		{
			"..",
		}
		links
		{
			"TombstoneApp",
			"Tombstone",
			--"Tool_WorldEditor",
			"WorldEditor",
			--"Tool_TextureTool",
			"TextureTool",
		}
		
	configuration { "linux" }
		buildoptions(COMMON_CXXFLAGS)
	
	
project "OpenGexImporter"
	--targetname "OpenGexImporter"
	targetdir "../Plugins/Tools/Editor"
	language "C++"
	kind "SharedLib"
	files
	{
		"../PluginCode/TSOpenGexImporter.cpp",
		"../PluginCode/TSOpenGexImporter.h",
	}
	defines
	{
		"TERATHON_IMPORT",
	}
	includedirs
	{
		"../TerathonCode",
		"../EngineCode",
	}

	configuration "vs*"
		includedirs
		{
			"$(DXSDK_DIR)/include",
		}
		
	configuration { "vs*", "x64" }
		libdirs
		{
			"..",
		}
		links
		{
			"TombstoneApp",
			"Tombstone",
			--"Tool_WorldEditor",
			"WorldEditor",
			--"Tool_TextureTool",
			"TextureTool",
		}
		
	configuration { "linux" }
		buildoptions(COMMON_CXXFLAGS)

		
project "FontImporter"
	--targetname "FontGenerator"
	targetdir "../Plugins/Tools"
	language "C++"
	kind "SharedLib"
	files
	{
		"../PluginCode/TSCharNames.cpp",
		"../PluginCode/TSFontImporter.cpp",
		"../PluginCode/TSFontImporter.h",
		"../TerathonCode/TSFontBuilder.h", "../TerathonCode/TSFontBuilder.cpp",
	}
	defines
	{
		"TERATHON_IMPORT",
	}
	includedirs
	{
		"../TerathonCode",
		"../EngineCode",
	}

	configuration "vs*"
		includedirs
		{
			"$(DXSDK_DIR)/include",
		}
		
	configuration { "vs*", "x64" }
		libdirs
		{
			"..",
		}
		links
		{
			"TombstoneApp",
			"Tombstone",
			--"Tool_TextureTool",
			"TextureTool",
		}
		
	configuration { "linux" }
		buildoptions(COMMON_CXXFLAGS)


project "MovieTool"
	--targetname "MovieTool"
	targetdir "../Plugins/Tools/Movies"
	language "C++"
	kind "SharedLib"
	files
	{
		"../PluginCode/TSMovieImporter.cpp",
		"../PluginCode/TSMovieImporter.h",
		"../PluginCode/TSMoviePlayer.cpp",
		"../PluginCode/TSMoviePlayer.h",
		"../PluginCode/TSMovieTool.cpp",
		"../PluginCode/TSMovieTool.h",
	}
	defines
	{
		"TERATHON_IMPORT",
	}
	includedirs
	{
		"../TerathonCode",
		"../EngineCode",
		"../Plugins",
	}

	configuration "vs*"
		includedirs
		{
			"$(DXSDK_DIR)/include",
		}
		
	configuration { "vs*", "x64" }
		libdirs
		{
			"..",
		}
		links
		{
			"TombstoneApp",
			"Tombstone",
			"SoundTool"
		}
		
	configuration { "linux" }
		buildoptions(COMMON_CXXFLAGS)


project "ResourcePacker"
	--targetname "ResourcePacker"
	targetdir "../Plugins/Tools"
	language "C++"
	kind "SharedLib"
	files
	{
		"../PluginCode/TSResourcePacker.cpp",
		"../PluginCode/TSResourcePacker.h",
	}
	defines
	{
		"TERATHON_IMPORT",
	}
	includedirs
	{
		"../TerathonCode",
		"../EngineCode",
	}

	configuration "vs*"
		includedirs
		{
			"$(DXSDK_DIR)/include",
		}
		
	configuration { "vs*", "x64" }
		
		libdirs
		{
			"..",
		}
		links
		{
			"TombstoneApp",
			"Tombstone",
		}
			
	configuration { "linux" }
		buildoptions(COMMON_CXXFLAGS)
		
		
project "SoundTool"
	--targetname "SoundTool"
	targetdir "../Plugins/Tools"
	language "C++"
	kind "SharedLib"
	files
	{
		"../PluginCode/TSSoundImporter.cpp",
		"../PluginCode/TSSoundImporter.h",
		"../PluginCode/TSSoundPlayer.cpp",
		"../PluginCode/TSSoundPlayer.h",
		"../PluginCode/TSSoundTool.cpp",
		"../PluginCode/TSSoundTool.h",
	}
	defines
	{
		"TERATHON_IMPORT",
		"TOMBSTONE_SOUND",
	}
	includedirs
	{
		"../TerathonCode",
		"../EngineCode"
	}

	configuration "vs*"
		includedirs
		{
			"$(DXSDK_DIR)/include",
		}
		
	configuration { "vs*", "x64" }
		libdirs
		{
			"..",
		}
		links
		{
			"TombstoneApp",
			"Tombstone",
		}
		
	configuration { "linux" }
		buildoptions(COMMON_CXXFLAGS)
		
		

project "StringImporter"
	--targetname "StringImporter"
	targetdir "../Plugins/Tools"
	language "C++"
	kind "SharedLib"
	files
	{
		"../PluginCode/TSStringImporter.cpp",
		"../PluginCode/TSStringImporter.h",
	}
	defines
	{
		"TERATHON_IMPORT",
	}
	includedirs
	{
		"../TerathonCode",
		"../EngineCode",
	}

	configuration "vs*"
		includedirs
		{
			"$(DXSDK_DIR)/include",
		}
		
	configuration { "vs*", "x64" }
		libdirs
		{
			"..",
		}
		links
		{
			"TombstoneApp",
			"Tombstone",
		}

	configuration { "linux" }
		buildoptions(COMMON_CXXFLAGS)



