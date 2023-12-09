//
//  SynthViewShaders.metal
//  STM32VideoToolkit
//
//  Created by Hayden McCabe on 7/25/23.
//

#include <metal_stdlib>
#include "ShaderTypes.h"

using namespace metal;

kernel void fullScreenRender(constant uint8_t *tileMap [[buffer(0)]],
                             constant uint8_t *tileLibrary [[buffer(1)]],
                             constant float4 *color [[buffer(2)]],
                             texture2d<float, access::write> outTexture [[texture(0)]],
                             uint2 gid [[thread_position_in_grid]])
{
    // Grid positions are in an 800x600 grid, corresponding to the
    // pixels in the output texture.
    
    // Convert the position in the grid to its tile map position
    int tileMapRow = gid.y / 12;
    int tileMapCol = gid.x / 8;
    
    int tileMapIndex = (100 * tileMapRow) + tileMapCol;
    
    // Read the tile library ID from the tile map
    uint8_t tileLibraryId = tileMap[tileMapIndex];
    
    // Convert the grid position to its position in the library texture
    int tileRow = gid.y % 12;
    int tileCol = gid.x % 8;
    
    // Each tile occupies 12 bytes. Use the tile library ID and tile row
    // to find the corresponding offset in the tile library
    int tileLibraryIndex = (12 * tileLibraryId) + tileRow;
    uint8_t rowByte = tileLibrary[tileLibraryIndex];
    
    // Convert the bit at the given position into a float value
    // of either 0 or 1
    float activePixel = float( (rowByte >> (7 - tileCol)) & 0x1 );
    
    // Multiply the color by activePixel to set it to 0 if the pixel is inactive,
    // or the given color if active.
    float4 outputColor = float4((activePixel * color[0]).rgb, 1);
    outTexture.write(outputColor, gid);
}

// Draw the texture in buffer 0 to the screen in buffer 1.
// gid is the x,y position in the screen
kernel void drawScreen(texture2d<float, access::sample> inTexture [[texture(0)]],
                       texture2d<float, access::write> screenTexture [[texture(1)]],
                       constant ScreenDrawUniforms &uniforms [[buffer(0)]],
                       uint2 gid [[thread_position_in_grid]])
{
    // Create a sampler to read from the input texture
    constexpr sampler s(coord::normalized,
                        address::repeat,
                        filter::linear);
    
    // Find a normalized coordinate for the offset
    float xBegin = float(uniforms.xOffset) / float(800);
    float yBegin = float(uniforms.yOffset) / float(600);
    
    // Normalize this thread's position in the output image
    float xNormalized = float(gid.x) / float(uniforms.screenWidth);
    float yNormalized = float(gid.y) / float(uniforms.screenHeight);
    
    // Find the final lookup point
    float2 posNormalized = float2(xBegin + xNormalized/2, yBegin + yNormalized/2);
    
    float4 color = inTexture.sample(s, posNormalized);
    
    screenTexture.write(color, gid);
}
