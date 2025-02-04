﻿#ifndef BLUE_OCEAN_OCEAN_VERT_HELPERS_H
#define BLUE_OCEAN_OCEAN_VERT_HELPERS_H

// i_meshScaleAlpha is passed in as it is provided per tile and is set only for LOD0
float ComputeLodAlpha(float3 i_worldPos, float i_meshScaleAlpha, in const float3 i_oceanPosScale0)
{
	// taxicab distance from ocean center drives LOD transitions
	float2 offsetFromCenter = abs(float2(i_worldPos.x - _OceanCenterPosWorld.x, i_worldPos.z - _OceanCenterPosWorld.z));
	float taxicab_norm = max(offsetFromCenter.x, offsetFromCenter.y);

	// interpolation factor to next lod (lower density / higher sampling period)
	// TODO - pass this in, and then make a node to provide it automatically
	float lodAlpha = taxicab_norm / i_oceanPosScale0.z - 1.0;

	// LOD alpha is remapped to ensure patches weld together properly. Patches can vary significantly in shape (with
	// strips added and removed), and this variance depends on the base vertex density of the mesh, as this defines the 
	// strip width.
	lodAlpha = max((lodAlpha - _BlueOceanLodAlphaBlackPointFade) / _BlueOceanLodAlphaBlackPointWhitePointFade, 0.);

	// blend out lod0 when viewpoint gains altitude
	lodAlpha = min(lodAlpha + i_meshScaleAlpha, 1.);

#if _DEBUGDISABLESMOOTHLOD_ON
	lodAlpha = 0.;
#endif

	return lodAlpha;
}

void SnapAndTransitionVertLayout(in const float i_meshScaleAlpha, in const float3 i_oceanPosScale0, in const float i_geometryGridSize, inout float3 io_worldPos, out float o_lodAlpha)
{
	const float GRID_SIZE_2 = 2.0 * i_geometryGridSize, GRID_SIZE_4 = 4.0 * i_geometryGridSize;

	// snap the verts to the grid
	// The snap size should be twice the original size to keep the shape of the eight triangles (otherwise the edge layout changes).
	io_worldPos.xz -= frac(UNITY_MATRIX_M._m03_m23 / GRID_SIZE_2) * GRID_SIZE_2; // caution - sign of frac might change in non-hlsl shaders

	// compute lod transition alpha
	o_lodAlpha = ComputeLodAlpha(io_worldPos, i_meshScaleAlpha, i_oceanPosScale0);

	// now smoothly transition vert layouts between lod levels - move interior verts inwards towards center
	float2 m = frac(io_worldPos.xz / GRID_SIZE_4); // this always returns positive
	float2 offset = m - 0.5;
	// check if vert is within one square from the center point which the verts move towards
	const float minRadius = 0.26; //0.26 is 0.25 plus a small "epsilon" - should solve numerical issues
	if (abs(offset.x) < minRadius) io_worldPos.x += offset.x * o_lodAlpha * GRID_SIZE_4;
	if (abs(offset.y) < minRadius) io_worldPos.z += offset.y * o_lodAlpha * GRID_SIZE_4;
}

#endif // BLUE_OCEAN_OCEAN_VERT_HELPERS_H