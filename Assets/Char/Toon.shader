Shader "Supyrb/Unlit/Texture"
{
    Properties
    {
        [HDR]_Color("Albedo", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
       
        [Header(Stencil)]
        _Stencil ("Stencil ID [0;255]", Float) = 0
        _ReadMask ("ReadMask [0;255]", Int) = 255
        _WriteMask ("WriteMask [0;255]", Int) = 255
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFail ("Stencil Fail", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail ("Stencil ZFail", Int) = 0
       
        [Header(Rendering)]
        _Offset("Offset", float) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Culling ("Cull Mode", Int) = 2
        [Enum(Off,0,On,1)] _ZWrite("ZWrite", Int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
        [Enum(None,0,Alpha,1,Red,8,Green,4,Blue,2,RGB,14,RGBA,15)] _ColorMask("Color Mask", Int) = 15

        // Outline properties
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineThickness ("Outline Thickness", Range(0.001, 0.03)) = 0.005
    }
   
    CGINCLUDE
    #include "UnityCG.cginc"
 
    half4 _Color;
    sampler2D _MainTex;
    float4 _MainTex_ST;

    // Outline properties
    float _OutlineThickness;
    float4 _OutlineColor;
   
    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };
 
    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };
 
    v2f vert (appdata v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        return o;
    }
   
    half4 frag (v2f i) : SV_Target
    {
        return tex2D(_MainTex, i.uv) * _Color;
    }
    struct v2fShadow {
        V2F_SHADOW_CASTER;
        UNITY_VERTEX_OUTPUT_STEREO
    };
 
    v2fShadow vertShadow( appdata_base v )
    {
        v2fShadow o;
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
        return o;
    }
 
    float4 fragShadow( v2fShadow i ) : SV_Target
    {
        SHADOW_CASTER_FRAGMENT(i)
    }
   
    ENDCG
       
    SubShader
    {
        Stencil
        {
            Ref [_Stencil]
            ReadMask [_ReadMask]
            WriteMask [_WriteMask]
            Comp [_StencilComp]
            Pass [_StencilOp]
            Fail [_StencilFail]
            ZFail [_StencilZFail]
        }
       
        Pass
        {
            Tags { "RenderType"="Opaque" "Queue" = "Geometry" }
            LOD 100
            Cull [_Culling]
            Offset [_Offset], [_Offset]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            ColorMask [_ColorMask]
           
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
       
        // Pass to render object as a shadow caster
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            LOD 80
            Cull [_Culling]
            Offset [_Offset], [_Offset]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
           
            CGPROGRAM
            #pragma vertex vertShadow
            #pragma fragment fragShadow
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            ENDCG
        }
    }

    // Outline SubShader
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Overlay" }
        Pass
        {
            Name "OUTLINE"
            Tags { "LightMode"="Always" }
            Cull Front
            ZWrite On
            ZTest LEqual

            CGPROGRAM
            #pragma vertex vertOutline
            #pragma fragment fragOutline
            #include "UnityCG.cginc"

            struct appdata_outline
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f_outline
            {
                float4 pos : POSITION;
                float4 color : COLOR;
            };

            v2f_outline vertOutline(appdata_outline v)
            {
                UNITY_SETUP_INSTANCE_ID(v);

                // Calculate the outline offset
                float3 norm = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                float3 offset = norm * _OutlineThickness;
                v2f_outline o;
                o.pos = UnityObjectToClipPos(v.vertex + float4(offset, 0));
                o.color = _OutlineColor;
                return o;
            }

            half4 fragOutline(v2f_outline i) : SV_Target
            {
                return i.color;
            }
            ENDCG
        }
    }
}
