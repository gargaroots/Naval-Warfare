﻿



using UnityEngine;

namespace Ocean
{
    /// <summary>
    /// Registers a custom input to the foam simulation. Attach this GameObjects that you want to influence the foam simulation, such as depositing foam on the surface.
    /// </summary>
    [ExecuteAlways]
    public class RegisterFoamInput : RegisterLodDataInput<LodDataMgrFoam>
    {
        public override bool Enabled => true;

        public override float Wavelength => 0f;

        public override int BatchIdx => 0;

        protected override Color GizmoColor => new Color(1f, 1f, 1f, 0.5f);

        protected override string ShaderPrefix => "BlueOcean/Inputs/Foam";
    }
}
