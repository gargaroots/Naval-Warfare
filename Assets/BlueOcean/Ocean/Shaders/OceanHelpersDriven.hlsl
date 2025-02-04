﻿// Helpers that use 'driven' data - i.e. has backing C# to set shader parameters like the slice index and etc. An
// example of this setup code can be found in OceanChunkRenderer.OnWillRenderObject().

#ifndef BLUE_OCEAN_OCEAN_HELPERS_DRIVEN_H
#define BLUE_OCEAN_OCEAN_HELPERS_DRIVEN_H

// Used to get the world position of the ocean surface from the world position
half4 SampleOceanDataAtWorldPosition(in Texture2DArray i_oceanData, in const float3 i_positionWS)
{
	// Sample ocean data textures - always lerp between 2 scales, so sample two textures

	float lodAlpha = ComputeLodAlpha(i_positionWS, _InstanceData.x, _LD_Pos_Scale[0]);

	// Sample weights. params.z allows shape to be faded out (used on last lod to support pop-less scale transitions)
	float wt_smallerLod = (1.0 - lodAlpha) * _LD_Params[_LD_SliceIndex].z;
	float wt_biggerLod = (1.0 - wt_smallerLod) * _LD_Params[_LD_SliceIndex + 1].z;

	// Sample data textures
	half4 result = 0.0;
	if (wt_smallerLod > 0.001)
	{
		float3 uv_slice = WorldToUV(i_positionWS.xz, _LD_Pos_Scale[_LD_SliceIndex], _LD_Params[_LD_SliceIndex], _LD_SliceIndex);
		result += wt_smallerLod * i_oceanData.SampleLevel(LODData_linear_clamp_sampler, uv_slice, 0.0);
	}
	if (wt_biggerLod > 0.001)
	{
		float3 uv_slice = WorldToUV(i_positionWS.xz, _LD_Pos_Scale[_LD_SliceIndex + 1], _LD_Params[_LD_SliceIndex + 1], _LD_SliceIndex + 1);
		result += wt_biggerLod * i_oceanData.SampleLevel(LODData_linear_clamp_sampler, uv_slice, 0.0);
	}

	return result;
}

// Used to get the world position of the ocean surface from the world position by using fixed-point iteration
float3 SampleOceanDataDisplacedToWorldPosition(in const Texture2DArray i_oceanData, in const float3 i_positionWS, in const uint i_iterations)
{
	float3 undisplacedPosition = InvertDisplacement(i_oceanData, _LD_Pos_Scale[_LD_SliceIndex], _LD_Params[_LD_SliceIndex], _LD_SliceIndex, i_positionWS, i_iterations);
	return SampleOceanDataAtWorldPosition(i_oceanData, undisplacedPosition);
}

#endif // BLUE_OCEAN_OCEAN_HELPERS_H