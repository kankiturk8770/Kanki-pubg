# ادامهٔ کار: چک‌لیست ارتقا (حرکت، دوربین، گان‌پلی، گرافیک، ۹۰ FPS)

این فایل برای ادامهٔ کار توی گفتگوی بعدیه.
- **شاخهٔ اصلی:** `ccr-f21f8758-ce75sk` (شاخهٔ پیش‌فرض ریپو هم همینه).
- **ساخت APK:** با هر push، GitHub Actions خودش APK و سرور رو می‌سازه. از تب **Actions** ← آخرین اجرا ← **Artifacts** دانلود کن.

> **موتور بازی Godot 4.3 است، نه Unity یا Unreal.** هر مورد زیر با معادلش توی Godot نوشته شده.
> رندرر فعلی: `gl_compatibility`، چون روی گوشی‌های قدیمی هم اجرا می‌شه.

## ۱. حرکت (Movement & Locomotion)

| خواسته | الان | کار باقی‌مونده |
|---|---|---|
| شتاب و توقف آنی | `ACCEL = 22`، `DECEL = 30` در `scripts/player.gd` | به حدود ۶۰ و ۸۰ برسه تا تغییر جهت آنی بشه (jiggle-peek) |
| Blend tree دوبعدی (idle / راه رفتن / دوی سریع) | `AnimationPlayer` با کلیپ‌های جدا (`_animate` در player.gd) | `AnimationTree` با `BlendSpace2D` برای idle، walk (`rifle_low`)، run، strafe و back |
| زمان transition کمتر از ۰.۱ ثانیه | `anim.play(want, 0.2)` | به `0.08` برسه |
| حرکت با کد، Root Motion فقط برای کارهای خاص | ✅ حرکت با کده و کلیپ‌ها In Place هستن | Vault و Roll و Climb اصلاً وجود ندارن: انیمیشن‌هاشون از Mixamo + `AnimationTree` با root motion |

## ۲. دوربین سوم‌شخص (Camera)

| خواسته | الان | کار باقی‌مونده |
|---|---|---|
| Spring Arm با تأخیر نرم (۱۰ تا ۱۵) | SpringArm3D هست؛ `_update_view` در player.gd دوربین رو بدون تأخیر می‌ذاره | دنبال کردن نرم موقعیت دوربین با `1-exp(-12*dt)` (فقط در حالت سوم‌شخص، نه موقع نشونه‌گیری) |
| FOV پایه ۶۵ تا ۷۰ و موقع دوی سریع ۷۵ تا ۸۰ | `HIP_FOV = 80` ثابت | پایه ۶۸، موقع اسپرینت با tween به ۷۸ |
| دوربین کمی سمت راست کاراکتر | ✅ `SHOULDER = 0.5` | — |

> نکته: نشونه‌گیری (ADS) توی بازی ما **دید اول‌شخص از پشت ردات** است. PUBG موقع ADS، FOV رو **کمتر** می‌کنه (زوم). پس «زیاد شدن FOV موقع ADS» فقط برای اسپرینت اعمال بشه.

## ۳. گان‌پلی، ADS و پیک

| خواسته | الان | کار باقی‌مونده |
|---|---|---|
| ADS سریع (۱۵۰ تا ۲۵۰ میلی‌ثانیه) | ✅ `ADS_TIME = 0.16` و دید از پشت ردات (`weapon_holder.gd`) | — |
| پیک: کج شدن بدن + جابه‌جا شدن دوربین | ✅ بدن (`aim_mod.lean`) و دوربین (`PEEK_SHIFT`، `PEEK_TILT`) | کپسول برخورد کج یا جابه‌جا نمی‌شه: hitbox سر و بالاتنه همراه پیک حرکت کنه (`CollisionShape3D` جدا برای سر) |
| لگد اسلحه (recoil) لایه‌ای | لگد دوربین (pitch) + کلیپ `fire` روی بالاتنه | لگد procedural فقط روی خود اسلحه موقع ADS (عقب رفتن و بالا پریدن کوچیک در `WeaponHolder.gun_transform`) + الگوی recoil برای هر اسلحه |

## ۴. گرافیک و ۹۰ FPS

| خواسته (Unity) | معادل در Godot | وضعیت |
|---|---|---|
| URP | رندرر **Mobile** (Vulkan) یا `gl_compatibility` فعلی | تصمیم لازمه: Mobile گرافیک بهتری داره ولی بعضی گوشی‌های قدیمی Vulkan ندارن |
| Color Grading پرانرژی | `Environment.adjustment_*` (saturation حدود ۱.۲ و contrast حدود ۱.۱) + tonemap ACES | انجام نشده (در `map_builder.gd`) |
| Bloom ملایم | `Environment.glow` | انجام نشده |
| SSAO | فقط در Forward+ هست، در Mobile و Compatibility **نیست** | به جاش lightmap پخته‌شده با AO (`LightmapGI`)، که فقط در رندرر Mobile کار می‌کنه |
| Sharpen | در Godot 4.3 فیلتر sharpen آماده نیست | یه shader پست‌پراسس کوچیک |
| قفل ۹۰ FPS | `Settings.fps_limit` (گزینهٔ ۹۰ توی تنظیمات هست) + `physics_ticks_per_second` | پیش‌فرض روی ۹۰ (برای گوشی‌های ۹۰Hz) و تست روی گوشی واقعی |
| سایه‌ها و نور پخته‌شده | سایهٔ آفتاب real-time | `LightmapGI` برای مپ ثابت (نیاز به رندرر Mobile) و سایهٔ کم‌فاصله |
| فشرده‌سازی ASTC/ETC2 | تنظیمات import تکسچرها (VRAM Compressed) + export preset اندروید | بررسی import همهٔ تکسچرها |

## ابزارهایی که الان هست
- `tools/fit_grips.gd`: جا انداختن انگشت‌ها روی اسلحه. بعد از عوض کردن کاراکتر یا اسلحه باید دوباره اجرا بشه.
- `tools/record_demo.gd`: ضبط ویدیوی گیم‌پلی با ربات‌ها.
- `--bots=N` و دکمهٔ **VS BOTS** در لابی: بازی تنهایی با ربات‌ها.
- `--touch`: نمایش کنترل‌های لمسی روی کامپیوتر.
