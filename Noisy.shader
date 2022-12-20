Shader "Custom/Noisy"
{
    Properties
    {
        _Factor ("Factor", range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "Queue"="Transparent+2000" }
        LOD 100
        Cull Front
        ZTest Always

        GrabPass {}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float rand2dTo1d(float2 value, float2 dotDir = float2(12.9898, 78.233))
            {
                float2 smallValue = sin(value);
                float random = dot(smallValue, dotDir);
                random = frac(sin(random) * 143758.5453);
                return random;
            }
            float3 HSVtoRGB(float3 hsv)
            {
                float3 rgb = clamp(abs(fmod(hsv.x * 6 + float3(0, 4, 2), 6) - 3) - 1, 0, 1);
                return hsv.z * lerp(float3(1, 1, 1), rgb, hsv.y);
            }
            float3 RGBtoHSV(float3 rgb)
            {
                float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                float4 p = lerp(float4(rgb.bg, K.wz), float4(rgb.gb, K.xy), step(rgb.b, rgb.g));
                float4 q = lerp(float4(p.xyw, rgb.r), float4(rgb.r, p.yzx), step(p.x, rgb.r));

                float d = q.x - min(q.w, q.y);
                float e = 0.0000000001;
                return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }
            float3 RGBtoHSVtoRGB(float3 rgb, float factor)
            {
                float3 col = RGBtoHSV(rgb);
                col = HSVtoRGB(float3(col.r, col.g*factor, col.b));
                return col;
            }

            struct appdata
            {
                float4 grabPos : TEXCOORD0;
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
            };

            float _Factor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            sampler2D _GrabTexture;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2Dproj(_GrabTexture, i.uv);
                col.rgb = RGBtoHSVtoRGB(col.rgb, 1 - _Factor);
                col = lerp(col, rand2dTo1d(i.uv + _Time.y), _Factor*0.8);
                return col;
            }
            ENDCG
        }
    }
}
