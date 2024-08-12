Shader "Custom/ToonOutline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineThickness ("Outline Thickness", Range(0.001, 0.03)) = 0.005
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        // Base pass (main texture rendering)
        Pass
        {
            Name "BASE"
            Tags { "LightMode"="ForwardBase" }
            Cull Back

            CGPROGRAM
            #pragma vertex vertBase
            #pragma fragment fragBase
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

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

            v2f vertBase(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 fragBase(v2f i) : SV_Target
            {
                half4 texColor = tex2D(_MainTex, i.uv);
                return texColor;
            }
            ENDCG
        }

        // Outline pass (only affects the outline)
        Pass
        {
            Name "OUTLINE"
            Tags { "LightMode"="Always" }
            Cull Front
            ZWrite On
            ZTest LEqual
            ColorMask RGB

            CGPROGRAM
            #pragma vertex vertOutline
            #pragma fragment fragOutline
            #include "UnityCG.cginc"

            uniform float _OutlineThickness;
            uniform float4 _OutlineColor;

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

    FallBack "Diffuse"
}
