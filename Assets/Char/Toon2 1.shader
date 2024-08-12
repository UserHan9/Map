Shader "Custom/ToonDissolve" {
    Properties {
        _MainTex("Texture", 2D) = "white" {}
        _DissolveThreshold("Dissolve Threshold", Range(0, 1)) = 0
        _EdgeColor("Edge Color", Color) = (0, 0, 0, 0)
        _Ramp("Ramp Texture", 2D) = "white" {}
        _OutlineColor("Outline Color", Color) = (0,0,0,1)
        _OutlineThickness("Outline Thickness", Range(0.0, 0.03)) = 0.005
    }

    SubShader {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 100

        // Outline Pass
        Pass {
            Name "OUTLINE"
            Tags { "LightMode" = "Always" }
            Cull Front
            ZWrite On
            ZTest LEqual
            ColorMask RGB
            Blend SrcAlpha OneMinusSrcAlpha

            Offset 0, 1

            CGPROGRAM
            #pragma vertex vert_outline
            #pragma fragment frag_outline
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : POSITION;
                float4 color : COLOR;
            };

            uniform float _OutlineThickness;
            uniform float4 _OutlineColor;

            v2f vert_outline(appdata v) {
                // just make a copy of incoming vertex data but scaled according to normal direction
                v2f o;
                float3 norm = mul((float3x3)unity_ObjectToWorld, v.normal);
                o.pos = UnityObjectToClipPos(v.vertex + norm * _OutlineThickness);
                o.color = _OutlineColor;
                return o;
            }

            fixed4 frag_outline(v2f i) : SV_Target {
                return i.color;
            }
            ENDCG
        }

        // Main Pass
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                UNITY_FOG_COORDS(3)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _Ramp;
            float _DissolveThreshold;
            float4 _EdgeColor;

            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldNormal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                // Toon Shading
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 normal = normalize(i.worldNormal);
                float ndotl = max(0, dot(normal, lightDir));

                // Sample ramp texture
                fixed toonShade = tex2D(_Ramp, float2(ndotl, ndotl)).r;

                float noiseScale = 1.0;
                fixed noise = frac(sin(dot(i.uv * noiseScale ,float2(12.9898,78.233))) * 43758.5453);
                noise = noise * 0.5 + 0.5; // Remap the noise

                fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb *= toonShade; // Apply toon shading
                fixed4 edgeCol = _EdgeColor;
                edgeCol.a = col.a;

                if (noise < _DissolveThreshold) {
                    clip(-1);
                }
                else if (noise < _DissolveThreshold + 0.1) {
                    return edgeCol;
                }

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }

    FallBack "Diffuse"
}
