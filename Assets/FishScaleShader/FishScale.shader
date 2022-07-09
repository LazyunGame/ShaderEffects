Shader "Unlit/FishScale"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "black" {}
        _Count ("Count",Range(1,20)) = 8
        _Border ("Border",Range(.01,.2)) = .1

        _Hue_A ("Hue A",Range(0,1)) = .1
        _Hue_B ("Hue B",Range(0,1)) = .1

        _Saturation ("Saturation",Range(0,1)) = .1
        _Brightness ("Brightness",Range(0,1)) = .1
        [KeywordEnum(Off, DISTANCE_A, DISTANCE_B, DISTANCE_AB, RANGE_A, RANGE_B, RANGE_AB, SCALE_A, SCALE_B,COLORAB)] _Debug ("Debug mode", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _DEBUG_OFF _DEBUG_DISTANCE_A _DEBUG_DISTANCE_B _DEBUG_DISTANCE_AB _DEBUG_RANGE_A _DEBUG_RANGE_B _DEBUG_RANGE_AB _DEBUG_SCALE_A _DEBUG_SCALE_B _DEBUG_COLORAB

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            int _Count;
            float _Border;
            uniform float _Hue_A;
            uniform float _Hue_B;

            uniform float _Saturation;
            uniform float _Brightness;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float3 rgb2hsv(float3 c)
            {
                float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
                float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

                float d = q.x - min(q.w, q.y);
                float e = 1.0e-10;
                return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }

            float3 hsv2rgb(float3 c)
            {
                c = float3(c.x, clamp(c.yz, 0.0, 1.0));
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }

            real4 frag(v2f i) : SV_Target
            {
                real4 col = tex2D(_MainTex, i.uv);
                float r = 0.5 - _Border;
                float2 uv_a = i.uv * _Count;
                float2 uv_b = uv_a + float2(.5, .5);

                float distance_a = distance(uv_a, floor(uv_a) + 0.5);

                #if defined(_DEBUG_DISTANCE_A)
                return distance_a;
                #endif

                float distance_b = distance(uv_b, floor(uv_b) + 0.5);

                #if defined(_DEBUG_DISTANCE_B)
                return distance_b;
                #endif

                #if defined(_DEBUG_DISTANCE_AB)
                return distance_a + distance_b;
                #endif

                float range_a = smoothstep(r + _Border, r - _Border, distance_a);

                #if defined(_DEBUG_RANGE_A)
                return range_a;
                #endif

                float range_b = smoothstep(r + _Border, r - _Border, distance_b);

                #if defined(_DEBUG_RANGE_B)
                return range_b;
                #endif

                #if defined(_DEBUG_RANGE_AB)
                return range_a + range_b;
                #endif

                float scale_a = clamp(range_b * (step(frac(uv_a.y + r), r)) + range_b * (1 - range_a), 0, 1);

                #if defined(_DEBUG_SCALE_A)
                return scale_a;
                #endif

                float scale_b = range_a * (1 - scale_a);

                #if defined(_DEBUG_SCALE_B)
                return scale_b ;
                #endif

                half3 color_a = hsv2rgb(float3(_Hue_A + i.uv.y * 0.12, _Saturation,
                                               _Brightness));
                half3 color_b = hsv2rgb(
                    float3(_Hue_B + i.uv.y * 0.12, _Saturation, _Brightness));

                float3 c = scale_a * color_a + scale_b * color_b;

                #if defined(_DEBUG_COLORAB)
                return float4(c,1);
                #endif
                c += (1 - scale_a - scale_b) * lerp(color_a, color_b, .5);
                col.rgb = lerp(col, c, 1);
                return col;
            }
            ENDHLSL
        }
    }
}