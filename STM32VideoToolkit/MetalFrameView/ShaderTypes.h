//
//  ShaderTypes.h
//  STM32VideoToolkit
//
//  Created by Hayden McCabe on 7/25/23.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
typedef metal::int32_t EnumBackingType;
#else
#import <Foundation/Foundation.h>
typedef NSInteger EnumBackingType;
#endif

#include <simd/simd.h>

//typedef NS_ENUM(EnumBackingType, BufferIndex)
//{
//    BufferIndexMeshPositions = 0,
//    BufferIndexMeshGenerics  = 1,
//    BufferIndexUniforms      = 2
//};
//
//typedef NS_ENUM(EnumBackingType, VertexAttribute)
//{
//    VertexAttributePosition  = 0,
//    VertexAttributeTexcoord  = 1,
//    VertexAttributeNormal    = 2
//};
//
//typedef NS_ENUM(EnumBackingType, TextureIndex)
//{
//    TextureIndexColor    = 0,
//};

typedef struct
{
    int screenWidth;
    int screenHeight;
    int xOffset;
    int yOffset;
} ScreenDrawUniforms;



#endif /* ShaderTypes_h */
