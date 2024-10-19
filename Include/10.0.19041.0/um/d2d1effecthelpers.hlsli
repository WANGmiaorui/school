//--------------------------------------------------------------------------- 
// Copyright (c) Microsoft Corporation.  All rights reserved. 
// 
// This file is automatically generated.  Please do not edit it directly.  
//  
//---------------------------------------------------------------------------  
 
// File contents: 
// - Helpers methods for authoring D2D Effect shader code.  
//   These are located at the end of the file (D2DGetInput, etc.). 
// - The top portion contains definitions and initialization required by the helpers. 
//   These elements are prefaced with "__D2D" and can be safely ignored. 
// 
// To use these helpers, the following values must be defined before inclusion: 
//   D2D_INPUT_COUNT - The number of texture inputs to the effect. 
//   D2D_INPUT[N]_SIMPLE or D2D_INPUT[N]_COMPLEX - How the effect will sample each input. (If unspecificed, defaults to _COMPLEX.) 
//   D2D_ENTRY - The name of the entry point being compiled. This will usually be defined on the command line at compilation time. 
// 
// The following values can be optionally defined: 
//   D2D_FUNCTION - Compile the entry point as an export function. This will usually be defined on the command line at compilation time. 
//   D2D_FULL_SHADER - Compile the entry point as a full shader. This will usually be defined on the command line at compilation time. 
//   D2D_FULL_SHADER_ONLY - Only compile the in-scope entry points to full shaders, never to export functions. 
// 
 
#define __D2D_DEFINE_PS_GLOBALS(inputIndex)     \
Texture2D<float4> InputTexture##inputIndex : register(t##inputIndex); \
SamplerState InputSampler##inputIndex : register(s##inputIndex); \

// Define a texture and sampler pair for each D2D effect input.
#if (D2D_INPUT_COUNT >= 1) 
__D2D_DEFINE_PS_GLOBALS(0)
#endif
#if (D2D_INPUT_COUNT >= 2)
__D2D_DEFINE_PS_GLOBALS(1)
#endif       
#if (D2D_INPUT_COUNT >= 3)
__D2D_DEFINE_PS_GLOBALS(2)
#endif        
#if (D2D_INPUT_COUNT >= 4)
__D2D_DEFINE_PS_GLOBALS(3)
#endif        
#if (D2D_INPUT_COUNT >= 5)
__D2D_DEFINE_PS_GLOBALS(4)
#endif        
#if (D2D_INPUT_COUNT >= 6)
__D2D_DEFINE_PS_GLOBALS(5)
#endif        
#if (D2D_INPUT_COUNT >= 7)
__D2D_DEFINE_PS_GLOBALS(6)
#endif        
#if (D2D_INPUT_COUNT >= 8)
__D2D_DEFINE_PS_GLOBALS(7)
#endif         

#define __D2D_MAXIMUM_INPUT_COUNT 8

// Validate that all required shader information has been defined. 
#ifndef D2D_INPUT_COUNT
#error D2D_INPUT_COUNT is undefined. 
#endif 

#if (D2D_INPUT_COUNT > __D2D_MAXIMUM_INPUT_COUNT)
#error D2D_INPUT_COUNT exceeds the maximum input count.
#endif

// Define global statics to hold the values needed by intrinsic methods.
// These values are initialized by the entry point wrapper before calling into the 
// effect's shader implementation. 
#if !defined(D2D_FUNCTION) || defined(D2D_REQUIRES_SCENE_POSITION)
static float4 __d2dstatic_scenePos = float4(0, 0, 0, 0);
#endif

#define __D2D_DEFINE_INPUT_STATICS(inputIndex)       \
static float4 __d2dstatic_input##inputIndex = float4(0, 0, 0, 0); \
static float4 __d2dstatic_uv##inputIndex = float4(0, 0, 0, 0);    \

#if (D2D_INPUT_COUNT >= 1)
__D2D_DEFINE_INPUT_STATICS(0)
#endif
#if (D2D_INPUT_COUNT >= 2)
__D2D_DEFINE_INPUT_STATICS(1)
#endif
#if (D2D_INPUT_COUNT >= 3)
__D2D_DEFINE_INPUT_STATICS(2)
#endif
#if (D2D_INPUT_COUNT >= 4)
__D2D_DEFINE_INPUT_STATICS(3)
#endif
#if (D2D_INPUT_COUNT >= 5)
__D2D_DEFINE_INPUT_STATICS(4)
#endif
#if (D2D_INPUT_COUNT >= 6)
__D2D_DEFINE_INPUT_STATICS(5)
#endif
#if (D2D_INPUT_COUNT >= 7)
__D2D_DEFINE_INPUT_STATICS(6)
#endif
#if (D2D_INPUT_COUNT >= 8)
__D2D_DEFINE_INPUT_STATICS(7)
#endif

// Define the scene position parameter according to whether the shader requires it,
// and whether it is the only parameter.
// The scene position input always needs to be defined for full shaders.
#if (!defined(D2D_FUNCTION) || defined(D2D_REQUIRES_SCENE_POSITION))
#if (D2D_INPUT_COUNT == 0)
#define __D2D_SCENE_POS                 float4 __d2dinput_scenePos : SCENE_POSITION
#define __D2D_INIT_STATIC_SCENE_POS     __d2dstatic_scenePos = __d2dinput_scenePos
#else
#define __D2D_SCENE_POS                 float4 __d2dinput_scenePos : SCENE_POSITION, 
#define __D2D_INIT_STATIC_SCENE_POS     __d2dstatic_scenePos = __d2dinput_scenePos;
    #endif
#else
    #define __D2D_SCENE_POS
    #define __D2D_INIT_STATIC_SCENE_POS
#endif

// When compiling a function version, simple and complex inputs have different definitions.
// When compiling a full shader, they have the same definition.
// Access to input parameters also differs between functions and full shaders.
#if defined(D2D_FUNCTION)
#define __D2D_SIMPLE_INPUT(index)           float4 __d2dinput_color##index : INPUT##index
#define __D2D_INIT_SIMPLE_STATIC(index)     __d2dstatic_input##index = __d2dinput_color##index
#else
#define __D2D_SIMPLE_INPUT(index)           float4 __d2dinput_uv##index : TEXCOORD##index
#define __D2D_INIT_SIMPLE_STATIC(index)     __d2dstatic_uv##index = __d2dinput_uv##index
#endif

#define __D2D_COMPLEX_INPUT(index)          float4 __d2dinput_uv##index : TEXCOORD##index
#define __D2D_INIT_COMPLEX_STATIC(index)    __d2dstatic_uv##index = __d2dinput_uv##index

#define __D2D_SAMPLE_INPUT(index)           InputTexture##index.Sample(InputSampler##index, __d2dstatic_uv##index.xy)

// Define each input as either simple or complex.
#if defined(D2D_INPUT0_SIMPLE)
#define __D2D_INPUT0 __D2D_SIMPLE_INPUT(0)
#define __D2D_INIT_STATIC0 __D2D_INIT_SIMPLE_STATIC(0)
#define __D2D_GET_INPUT0 __d2dstatic_input0 
#else 
#define __D2D_INPUT0 __D2D_COMPLEX_INPUT(0)
#define __D2D_INIT_STATIC0 __D2D_INIT_COMPLEX_STATIC(0)
#define __D2D_GET_INPUT0 __D2D_SAMPLE_INPUT(0)
#endif
#if defined(D2D_INPUT1_SIMPLE)
#define __D2D_INPUT1 __D2D_SIMPLE_INPUT(1)
#define __D2D_INIT_STATIC1 __D2D_INIT_SIMPLE_STATIC(1)
#define __D2D_GET_INPUT1 __d2dstatic_input1 
#else 
#define __D2D_INPUT1 __D2D_COMPLEX_INPUT(1)
#define __D2D_INIT_STATIC1 __D2D_INIT_COMPLEX_STATIC(1)
#define __D2D_GET_INPUT1 __D2D_SAMPLE_INPUT(1)
#endif
#if defined(D2D_INPUT2_SIMPLE)
#define __D2D_INPUT2 __D2D_SIMPLE_INPUT(2)
#define __D2D_INIT_STATIC2 __D2D_INIT_SIMPLE_STATIC(2)
#define __D2D_GET_INPUT2 __d2dstatic_input2 
#else 
#define __D2D_INPUT2 __D2D_COMPLEX_INPUT(2)
#define __D2D_INIT_STATIC2 __D2D_INIT_COMPLEX_STATIC(2)
#define __D2D_GET_INPUT2 __D2D_SAMPLE_INPUT(2)
#endif
#if defined(D2D_INPUT3_SIMPLE)
#define __D2D_INPUT3 __D2D_SIMPLE_INPUT(3)
#define __D2D_INIT_STATIC3 __D2D_INIT_SIMPLE_STATIC(3)
#define __D2D_GET_INPUT3 __d2dstatic_input3 
#else 
#define __D2D_INPUT3 __D2D_COMPLEX_INPUT(3)
#define __D2D_INIT_STATIC3 __D2D_INIT_COMPLEX_STATIC(3)
#define __D2D_GET_INPUT3 __D2D_SAMPLE_INPUT(3)
#endif
#if defined(D2D_INPUT4_SIMPLE)
#define __D2D_INPUT4 __D2D_SIMPLE_INPUT(4)
#define __D2D_INIT_STATIC4 __D2D_INIT_SIMPLE_STATIC(4)
#define __D2D_GET_INPUT4 __d2dstatic_input4 
#else 
#define __D2D_INPUT4 __D2D_COMPLEX_INPUT(4)
#define __D2D_INIT_STATIC4 __D2D_INIT_COMPLEX_STATIC(4)
#define __D2D_GET_INPUT4 __D2D_SAMPLE_INPUT(4)
#endif
#if defined(D2D_INPUT5_SIMPLE)
#define __D2D_INPUT5 __D2D_SIMPLE_INPUT(5)
#define __D2D_INIT_STATIC5 __D2D_INIT_SIMPLE_STATIC(5)
#define __D2D_GET_INPUT5 __d2dstatic_input5 
#else 
#define __D2D_INPUT5 __D2D_COMPLEX_INPUT(5)
#define __D2D_INIT_STATIC5 __D2D_INIT_COMPLEX_STATIC(5)
#define __D2D_GET_INPUT5 __D2D_SAMPLE_INPUT(5)
#endif
#if defined(D2D_INPUT6_SIMPLE)
#define __D2D_INPUT6 __D2D_SIMPLE_INPUT(6)
#define __D2D_INIT_STATIC6 __D2D_INIT_SIMPLE_STATIC(6)
#define __D2D_GET_INPUT6 __d2dstatic_input6 
#else 
#define __D2D_INPUT6 __D2D_COMPLEX_INPUT(6)
#define __D2D_INIT_STATIC6 __D2D_INIT_COMPLEX_STATIC(6)
#define __D2D_GET_INPUT6 __D2D_SAMPLE_INPUT(6)
#endif
#if defined(D2D_INPUT7_SIMPLE)
#define __D2D_INPUT7 __D2D_SIMPLE_INPUT(7)
#define __D2D_INIT_STATIC7 __D2D_INIT_SIMPLE_STATIC(7)
#define __D2D_GET_INPUT7 __d2dstatic_input7 
#else 
#define __D2D_INPUT7 __D2D_COMPLEX_INPUT(7)
#define __D2D_INIT_STATIC7 __D2D_INIT_COMPLEX_STATIC(7)
#define __D2D_GET_INPUT7 __D2D_SAMPLE_INPUT(7)
#endif
#if defined(D2D_INPUT8_SIMPLE)
#define __D2D_INPUT8 __D2D_SIMPLE_INPUT(8)
#define __D2D_INIT_STATIC8 __D2D_INIT_SIMPLE_STATIC(8)
#define __D2D_GET_INPUT8 __d2dstatic_input8
#else 
#define __D2D_INPUT8 __D2D_COMPLEX_INPUT(8)
#define __D2D_INIT_STATIC8 __D2D_INIT_COMPLEX_STATIC(8)
#define __D2D_GET_INPUT8 __D2D_SAMPLE_INPUT(8)
#endif

// Define the export function inputs based on the defined input count and types.
#if (D2D_INPUT_COUNT == 0)
#define __D2D_FUNCTION_INPUTS     __D2D_SCENE_POS
#define __D2D_INIT_STATICS        __D2D_INIT_STATIC_SCENE_POS
#elif (D2D_INPUT_COUNT == 1)
#define __D2D_FUNCTION_INPUTS     __D2D_SCENE_POS __D2D_INPUT0
#define __D2D_INIT_STATICS        __D2D_INIT_STATIC_SCENE_POS __D2D_INIT_STATIC0
#elif (D2D_INPUT_COUNT == 2)
#define __D2D_FUNCTION_INPUTS     __D2D_SCENE_POS __D2D_INPUT0, __D2D_INPUT1
#define __D2D_INIT_STATICS        __D2D_INIT_STATIC_SCENE_POS __D2D_INIT_STATIC0; __D2D_INIT_STATIC1
#elif (D2D_INPUT_COUNT == 3)
#define __D2D_FUNCTION_INPUTS     __D2D_SCENE_POS __D2D_INPUT0, __D2D_INPUT1, __D2D_INPUT2
#define __D2D_INIT_STATICS        __D2D_INIT_STATIC_SCENE_POS __D2D_INIT_STATIC0; __D2D_INIT_STATIC1; __D2D_INIT_STATIC2
#elif (D2D_INPUT_COUNT == 4)
#define __D2D_FUNCTION_INPUTS     __D2D_SCENE_POS __D2D_INPUT0, __D2D_INPUT1, __D2D_INPUT2, __D2D_INPUT3
#define __D2D_INIT_STATICS        __D2D_INIT_STATIC_SCENE_POS __D2D_INIT_STATIC0; __D2D_INIT_STATIC1; __D2D_INIT_STATIC2; __D2D_INIT_STATIC3
#elif (D2D_INPUT_COUNT == 5)
#define __D2D_FUNCTION_INPUTS     __D2D_SCENE_POS __D2D_INPUT0, __D2D_INPUT1, __D2D_INPUT2, __D2D_INPUT3, __D2D_INPUT4
#define __D2D_INIT_STATICS        __D2D_INIT_STATIC_SCENE_POS __D2D_INIT_STATIC0; __D2D_INIT_STATIC1; __D2D_INIT_STATIC2; __D2D_INIT_STATIC3; __D2D_INIT_STATIC4
#elif (D2D_INPUT_COUNT == 6)
#define __D2D_FUNCTION_INPUTS     __D2D_SCENE_POS __D2D_INPUT0, __D2D_INPUT1, __D2D_INPUT2, __D2D_INPUT3, __D2D_INPUT4, __D2D_INPUT5
#define __D2D_INIT_STATICS        __D2D_INIT_STATIC_SCENE_POS __D2D_INIT_STATIC0; __D2D_INIT_STATIC1; __D2D_INIT_STATIC2; __D2D_INIT_STATIC3; __D2D_INIT_STATIC4; __D2D_INIT_STATIC5
#elif (D2D_INPUT_COUNT == 7)
#define __D2D_FUNCTION_INPUTS     __D2D_SCENE_POS __D2D_INPUT0, __D2D_INPUT1, __D2D_INPUT2, __D2D_INPUT3, __D2D_INPUT4, __D2D_INPUT5, __D2D_INPUT6
#define __D2D_INIT_STATICS        __D2D_INIT_STATIC_SCENE_POS __D2D_INIT_STATIC0; __D2D_INIT_STATIC1; __D2D_INIT_STATIC2; __D2D_INIT_STATIC3; __D2D_INIT_STATIC4; __D2D_INIT_STATIC5; __D2D_INIT_STATIC6
#elif (D2D_INPUT_COUNT == 8)
#define __D2D_FUNCTION_INPUTS     __D2D_SCENE_POS __D2D_INPUT0, __D2D_INPUT1, __D2D_INPUT2, __D2D_INPUT3, __D2D_INPUT4, __D2D_INPUT5, __D2D_INPUT6, __D2D_INPUT7
#define __D2D_INIT_STATICS        __D2D_INIT_STATIC_SCENE_POS __D2D_INIT_STATIC0; __D2D_INIT_STATIC1; __D2D_INIT_STATIC2; __D2D_INIT_STATIC3; __D2D_INIT_STATIC4; __D2D_INIT_STATIC5; __D2D_INIT_STATIC6; __D2D_INIT_STATIC7
#endif

#if !defined(CONCAT)
#define CONCAT(str1, str2)      str1##str2
#endif 

// Rename the entry point target function so that the actual entry point can use the name.
// This expansion is the same for both full shaders and functions.
#define D2D_PS_ENTRY(name)      float4 CONCAT(name, _Impl)()

// If neither D2D_FUNCTION or D2D_FULL_SHADER is defined, behave as if D2D_FULL_SHADER is defined. 
#if defined(D2D_FUNCTION) && !defined(D2D_FULL_SHADER_ONLY)

    // Replaces simple samples with either static variable or an actual sample, 
    // depending on whether the input is declared as simple or complex.
    #define D2DGetInput(index)          __D2D_GET_INPUT##index

    #if !defined(D2D_CUSTOM_ENTRY)
        // Declare function prototype for the target function so that it can be referenced before definition.
        // D2D_ENTRY is a macro whose actual name resolves to the effect's target "entry point" function.
        float4 CONCAT(D2D_ENTRY, _Impl)();

        // This is the actual entry point definition, which forwards the call to the target function.   
        export float4 D2D_func_entry(__D2D_FUNCTION_INPUTS) 
        { 
            __D2D_INIT_STATICS; 
            return CONCAT(D2D_ENTRY, _Impl)(); 
        }

    #endif

#else // !defined(D2D_FUNCTION)

    // Replaces simple samples with actual samples.
    #define D2DGetInput(index)           __D2D_SAMPLE_INPUT(index)

    #if !defined(D2D_CUSTOM_ENTRY)
        // Declare function prototype for the target function so that it can be referenced before definition.
        // D2D_ENTRY is a macro whose actual name resolves to the effect's target "entry point" function.
        float4 CONCAT(D2D_ENTRY, _Impl)();

        // This is the actual entry point definition, which forwards the call to the target function.   
        float4 D2D_ENTRY (float4 pos : SV_POSITION, __D2D_FUNCTION_INPUTS) : SV_TARGET
        { 
            __D2D_INIT_STATICS; 
            return CONCAT(D2D_ENTRY, _Impl)(); 
        }

    #endif

#endif  // D2D_FUNCTION

//===============================================================
// Along with D2DGetInput defined above, the following macros and 
// methods define D2D intrinsics for use in effect shader code. 
//===============================================================

#if !defined(D2D_FUNCTION) || defined(D2D_REQUIRES_SCENE_POSITION)
inline float4 D2DGetScenePosition()
{
    return __d2dstatic_scenePos;
}
#endif

#define D2DGetInputCoordinate(index)                  __d2dstatic_uv##index   
        
#define D2DSampleInput(index, position)               InputTexture##index.Sample(InputSampler##index, position)

#define D2DSampleInputAtOffset(index, offset)         InputTexture##index.Sample(InputSampler##index, __d2dstatic_uv##index.xy + offset * __d2dstatic_uv##index.zw)

#define D2DSampleInputAtPosition(index, pos)          InputTexture##index.Sample(InputSampler##index, __d2dstatic_uv##index.xy + __d2dstatic_uv##index.zw * (pos - __d2dstatic_scenePos.xy))

