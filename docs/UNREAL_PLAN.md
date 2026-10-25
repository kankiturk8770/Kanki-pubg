# Kanki TDM: ساخت دوباره با Unreal Engine 5 (سند کامل برای گفتگوی بعدی)

> **برای گفتگوی بعدی:** این سند رو کامل بخون و از «مرحلهٔ M0» شروع کن.
>
> - **ریپوی فعلی:** `kankiturk8770/Kanki-pubg`، شاخهٔ `ccr-f21f8758-ce75sk`. این نسخهٔ Godot است و فقط به‌عنوان مرجع می‌مونه (اعداد گیم‌پلی، asset‌ها، طرح مپ و رابط کاربری).
> - **تصمیم صاحب پروژه:** موتور از Godot به **Unreal Engine 5** عوض می‌شه. هدف، گیم‌پلی در سطح PUBG Mobile با ۹۰ FPS پایدار روی موبایله.
> - **بخش ۱** پرامپت اصلی صاحب پروژه است، عیناً. بقیهٔ سند جزئیات فنی، چیزهایی که پرامپت جا انداخته بود، و نقشهٔ مرحله‌به‌مرحله است.

---

## ۰. پیش‌نیاز (خیلی مهم، قبل از هر کاری)

ساخت بازی با Unreal **فقط با گوشی ممکن نیست**:
- ادیتور Unreal روی ویندوز یا لینوکس با کارت گرافیک اجرا می‌شه.
- Blueprint، AnimBP، BlendSpace و مپ‌ها فایل‌های باینری `.uasset` و `.umap` هستن و فقط ادیتور اون‌ها رو می‌سازه.
- APK اندروید رو هم ادیتور با Android SDK/NDK می‌سازه.

دستیار هوش مصنوعی (Claude Code) این‌ها رو **می‌تونه** بنویسه:
- کد C++ (کلاس‌های اصلی)
- فایل‌های تنظیمات `.ini`
- اسکریپت‌های Python ادیتور (import خودکار FBX، ساخت BlendSpace، تنظیم asset‌ها)
- workflowهای CI

ولی **اجرای ادیتور و ساخت خروجی** به یه کامپیوتر نیاز داره. یکی از این‌ها لازمه:

1. **کامپیوتر ویندوزی:**
   - کارت گرافیک: RTX 2060 یا بهتر
   - رم: ۳۲ گیگ
   - SSD: ۲۰۰ گیگ خالی
2. **کامپیوتر ابری که از گوشی بهش وصل می‌شی** (Remote Desktop):
   - مثلاً AWS `g4dn.xlarge` یا `g5`، Paperspace، Shadow PC
   - Unreal و Android Studio روش نصب می‌شه

نرم‌افزارهای لازم:
- Epic Games Launcher + **UE 5.5** (یا آخرین نسخهٔ پایدار)
- Visual Studio 2022 (workload «Game development with C++»)
- Android Studio + SDK و NDK (نسخه‌ای که مستندات Unreal برای همون نسخهٔ موتور گفته)
- JDK 17
- Git + **Git LFS**

برای **سرور اختصاصی (Dedicated Server)** باید Unreal رو **از سورس** بسازی:
- اول اکانت Epic رو به GitHub لینک کن تا به ریپوی `EpicGames/UnrealEngine` دسترسی پیدا کنی.
- نسخهٔ Launcher هدف Server نمی‌سازه.


### راه بدون کامپیوتر: ساخت خودکار با GitHub (پیشنهادی)

صاحب پروژه لپتاپ نداره. برای همین مسیر اصلی کار این‌جوریه:

1. **دستیار** (Claude Code) کد C++، فایل‌های ini و اسکریپت‌های Python رو می‌نویسه و push می‌کنه. مپ هم با اسکریپت ساخته می‌شه، مثل `map_builder` نسخهٔ Godot.
2. **GitHub Actions** خودش build و cook و package می‌کنه و **APK** می‌سازه:
   - از ایمیج رسمی Docker خود Epic استفاده می‌کنه: `ghcr.io/epicgames/unreal-engine` (نسخهٔ dev).
   - دستور ساخت: `RunUAT BuildCookRun -platform=Android`
   - بدون ادیتور گرافیکی (headless).
3. **صاحب پروژه** APK رو روی گوشی نصب و تست می‌کنه و ایرادها رو می‌گه.

پیش‌نیازهای این مسیر (کارهای صاحب پروژه):
- **وصل کردن اکانت Epic Games به GitHub** (رایگان، با گوشی هم می‌شه):
  - epicgames.com ← Account ← Apps and Accounts ← GitHub
  - بعد دعوت‌نامهٔ سازمان `EpicGames` در GitHub رو قبول کن.
  - بدون این، ایمیج Unreal در دسترس نیست.
- **یه ماشین ساخت قوی:** runnerهای رایگان GitHub برای Unreal کوچیکن (هم فضا هم زمان). یکی از این دو:
  - **runner بزرگ پولی GitHub:** Linux، ۱۶ هسته به بالا، ۶۰۰ گیگ دیسک.
  - **یه سرور اجاره‌ای به‌عنوان self-hosted runner:**
    - کارت گرافیک لازم نیست
    - مشخصات: ۸ تا ۱۶ هسته، ۳۲ تا ۶۴ گیگ رم، ۲۵۰ گیگ دیسک
    - مثلاً Hetzner
- **Android SDK/NDK:** داخل همون CI نصب می‌شه.

**کارهایی که بدون ادیتور سخت‌ترن** (ولی با اسکریپت شدنی):
- **چیدمان مپ:** با Python ادیتور.
- **گراف AnimBP:**
  - تا جای ممکن منطق در `KankiAnimInstance` با C++ نوشته بشه.
  - یا از AnimBP آمادهٔ Lyra استفاده بشه.
- **bake نور:** با commandlet.
- تنظیم ظاهری با دیدن نتیجه کندتره: هر بار یه build و تست روی گوشی.

---

## ۱. پرامپت اصلی صاحب پروژه (عیناً)

```
Act as a Senior Unreal Engine 5 Gameplay Architect, Technical Artist, and Mobile Optimization Specialist. Your task is to build a high-performance, ultra-smooth Third-Person Tactical Shooter (TDM mode, PUBG Mobile standard) achieving stable 90 FPS on mobile devices.

Implement the following Unreal Engine-specific systems, Blueprints, and configurations:

1. CHARACTER MOVEMENT & LOCOMOTION (Blueprint / Character Movement Component):
- Instant Jiggle & Acceleration: Modify the Character Movement Component parameters. Set max acceleration, braking deceleration, and ground friction to extremely high values to eliminate heavy inertia and enable instant direction-switching (crucial for fluid jiggle-peeking).
- Motion Warping & Root Motion: Use Root Motion strictly for specialized actions (vaulting, tactical rolls, climbing) while utilizing CapsuleComponent velocity-driven movement for responsive ground locomotion and joystick handling.
- AnimBP Blend Spaces: Implement 2D Directional Blend Spaces for smooth transitions between idle, tactical walk, and sprint. Keep all transition durations under 0.1 seconds to completely eliminate input lag.

2. CAMERA & TPP VIEWPORT DYNAMICS (SpringArmComponent & Camera):
- Cinematic SpringArm Lag: Configure the SpringArmComponent with Camera Lag enabled (lag speed between 10-15) to achieve the smooth, fluid trailing effect seen in modern mobile battle royales.
- Dynamic FOV Interp: Set baseline FOV to 65-70. When the character sprints, smoothly interpolate FOV up (75-80) to enhance the sense of speed. When entering Aim Down Sights (ADS), smoothly interpolate FOV down (zoom in) to narrow focus and improve accuracy.
- Over-the-Shoulder Viewport Offset: Offset the camera node slightly to the right of the character model to ensure optimal tactical visibility and screen space control.

3. GUNPLAY, ADS & PEEK MECHANICS (Gameplay Ability System / Custom Weapon Actor):
- Snappy ADS Transition: Make the transition from hip-fire to ADS view extremely fast (target 150-250ms via Timeline or InterpTo).
- Lean & Peek Mechanics (Left/Right): Implement body-tilting and camera offset adjustment simultaneously so players can check corners without exposing their entire hitbox.
- Procedural Recoil & Camera Shake: Apply localized procedural rotation/position offsets to the weapon mesh and viewmodel during firing, combined with subtle camera shakes to give genuine weight to firearms without making the screen uncontrollable.

4. MOBILE GRAPHICS PIPELINE & 90 FPS STABILITY (Unreal Mobile Renderer):
- Mobile Renderer & Feature Level: Target the ES3.1 / Vulkan mobile rendering pipeline, avoiding heavy desktop features (like Lumen/Nanite) that hurt mobile thermals.
- Lighting & Baking: Rely heavily on Lightmass / Baked Lighting for static indoor/warehouse environments instead of expensive real-time AO and dynamic shadow cascades.
- Post-Processing & Color Grading: Set up a PostProcessVolume with a vibrant Color Grading profile (increased saturation, clean contrast to avoid a grey/dull look), gentle Bloom, and mobile-friendly texture compression formats (ASTC).
- Performance Locking: Lock Project Settings physics and application target frame rate strictly to 90 FPS to maintain absolute stability without thermal throttling.
```

خواستهٔ صاحب پروژه به فارسی: «همه چیز صفر تا صد مثل PUBG Mobile باشه، مخصوصاً حرکت، کنترل‌ها، پیک چپ و راست، نشونه‌گیری، دوربین‌ها و دکمه‌ها. هیچ کمبودی نداشته باشیم. بهترین گیم‌پلی ممکن.»

---

## ۲. بازی چیه (قوانین و اعداد، از نسخهٔ Godot)

| مورد | مقدار |
|---|---|
| حالت بازی | Team Deathmatch، ۵ در برابر ۵، دوربین سوم‌شخص (TPP) |
| برد | اولین تیمی که به **۴۰ کشته** برسه، یا بیشترین کشته بعد از **۱۰ دقیقه** |
| زنده شدن | **۳ ثانیه** بعد از مرگ، در محل شروع تیم. ۲ ثانیه هم آسیب‌ناپذیر (اضافه‌شده) |
| مسابقهٔ بعدی | **۱۰ ثانیه** بعد از پایان |
| جون | ۱۰۰. آسیب به سر، بدن و دست‌وپا جدا حساب می‌شه |
| خشاب | ۳۰ تیر. ریلود ۲.۱ ثانیه. برد تیر ۱۵۰ متر (hitscan) |
| کاراکترها | مرد و زن. موقع ثبت‌نام و توی لابی انتخاب می‌شن. تیم فقط رنگ لباس رو عوض می‌کنه (آبی / قرمز) |
| مپ | «Warehouse»، ۵۶×۴۴ متر: کانتینر، صندوق، بشکه، مانع بتنی، ستون. محل شروع تیم‌ها: z = ±۱۷.۵ |

**اسلحه‌ها** (اعداد فعلی؛ در UE داخل `DataAsset` قرار می‌گیرن):

| اسلحه | آسیب بدن | آسیب سر | فاصلهٔ شلیک | RPM |
|---|---|---|---|---|
| M416 | 22 | 48 | 0.086 s | ~698 |
| AKM | 26 | 56 | 0.100 s | 600 |
| UMP45 | 19 | 40 | 0.092 s | ~652 |

پیشنهاد اضافه: ضریب آسیب برای دست‌وپا ۰.۹ و برای گردن ۱.۵.

**سرعت‌ها** (Godot بر حسب متر بر ثانیه؛ UE بر حسب سانتی‌متر بر ثانیه):

| حالت | سرعت (cm/s) |
|---|---|
| راه رفتن | 220 |
| دویدن | 500 |
| دوی سریع | 640 |
| ADS | 300 |
| خمیده | 240 |
| درازکش (جدید) | 110 |

پرش: ۴۶۰ cm/s

---

## ۳. ساختار پروژه در UE5 (اول C++، بعد Blueprint)

اصل کار: **منطق اصلی بازی با C++ نوشته بشه.**
- این‌جوری دستیار می‌تونه بنویسدش و تغییرش بده.
- برای شبکه و موبایل هم سریع‌تره.
- Blueprint فقط لایهٔ تنظیمات و نمایشه: AnimBP، ویجت‌ها و Data Asset‌ها، که از کلاس‌های C++ ارث می‌برن.

- **پروژه:**
  - قالب «Third Person (C++)»، Target: Mobile، Quality: Scalable.
  - **بدون** Lumen، Nanite و Virtual Shadow Maps.
- **ریپو:** پیشنهاد، یه ریپوی **جدید** مثل `kanki-tdm-ue5`.
  - همون اول **Git LFS** برای `*.uasset *.umap *.fbx *.png *.jpg *.wav` فعال بشه.
  - `.gitignore` استاندارد Unreal: `Binaries/ Intermediate/ Saved/ DerivedDataCache/`.
- **پلاگین‌ها:**
  - Enhanced Input
  - Motion Warping
  - Common UI (اختیاری)
  - StateTree (برای ربات‌ها)
  - Animation Budget Allocator
  - glTF Importer / Interchange (برای مدل‌های فعلی `.glb`)
  - Online Subsystem (پیش‌فرض) + Replication Graph (بعداً، اگه بازیکن‌ها بیشتر شدن)

```
Source/KankiTDM/
  Core/        KankiGameInstance, KankiGameMode (TDM rules), KankiGameState (score/time),
               KankiPlayerState (team/kills/deaths), KankiPlayerController (input, HUD, settings)
  Character/   KankiCharacter, KankiMovementComponent (sprint/crouch/prone/lean/vault, replicated),
               KankiCameraManager (FOV, ADS blend, camera shake), KankiHealthComponent
  Animation/   KankiAnimInstance (C++ values for the AnimBP), hand IK / grip poses
  Weapons/     KankiWeapon (Actor), KankiWeaponData (DataAsset), KankiWeaponComponent
               (inventory/equip/fire/reload), KankiRecoil (procedural), KankiProjectileFx (tracer/impact)
  AI/          KankiBotController (AIController), StateTree tasks: find target, move, strafe, burst fire
  UI/          KankiHUDWidget, KankiTouchControls (floating joystick + buttons + layout editor),
               KankiScoreboard, KankiKillFeed, KankiMinimap, menu widgets (Splash/Login/Lobby/Settings)
  Online/      KankiAccounts (HTTP to backend), matchmaking (later)
Config/        DefaultEngine.ini, DefaultGame.ini, DefaultInput.ini, DefaultDeviceProfiles.ini,
               DefaultScalability.ini, Android/AndroidEngine.ini
Content/Python/  editor scripts: import characters, animations, weapons and props; make BlendSpaces
```

**درباره GAS:** برای این بازی یه سیستم سلاح سفارشی (`KankiWeaponComponent`) سبک‌تر و سریع‌تره، و کار با شبکه رو هم ساده‌تر می‌کنه. GAS فقط اگه بعداً قابلیت یا perk اضافه شد.

---

## ۴. حرکت (پرامپت بخش ۱) + چیزهایی که جا افتاده بود

### Character Movement Component (`KankiMovementComponent`)

| تنظیم | مقدار |
|---|---|
| `MaxAcceleration` | 8000 |
| `BrakingDecelerationWalking` | 8000 |
| `GroundFriction` | 12 |
| `bUseSeparateBrakingFriction` | true |
| `BrakingFriction` | 12 |
| `BrakingFrictionFactor` | 1 |
| `MaxWalkSpeed` | از جدول سرعت‌ها، با حالت عوض می‌شه |
| `bOrientRotationToMovement` | **true** موقع حرکت عادی (کاراکتر به سمت جوی‌استیک می‌چرخه، مثل PUBG) |
| `RotationRate` | (0, 900, 0) |
| `bUseControllerDesiredRotation` | **true** موقع ADS، شلیک (۰.۸ ثانیه بعد از آخرین تیر) و پیک. بدن رو به دوربین، با انیمیشن strafe |
| `AirControl` | 0.35 |
| `JumpZVelocity` | 460 |
| `NavAgent` | برای ربات‌ها |

بقیهٔ قواعد حرکت:
- **جوی‌استیک آنالوگ:**
  - کمتر از ۶۰٪ فشار = راه رفتن
  - بیشتر از ۶۰٪ = دویدن
  - بالاتر بردن از حلقهٔ جوی‌استیک = **قفل دوی سریع** (sprint lock، مثل PUBG)
- **حالت‌ها:** Stand، Crouch، **Prone** (جدید؛ PUBG داره)، با کپسول درست برای هر حالت.
  - درازکش: کپسول افقی، یا کوتاه با offset.
- همهٔ حالت‌ها و پیک **replicate** بشن:
  - `CompressedFlags` / `FSavedMove` سفارشی برای sprint، crouch و lean
  - تا client prediction بدون لرزش کار کنه
- **Root Motion فقط برای کارهای خاص:**
  - Vault (۵۰ تا ۱۲۰ سانت) و Climb (۱۲۰ تا ۲۲۰ سانت)
    - trace جلو برای ارتفاع مانع
    - montage با root motion + **Motion Warping** (warp target لبهٔ مانع)
  - Tactical Roll (اختیاری)
- **Jiggle peek:** شتاب و توقف آنی (بالا) + پیک فوری.

### انیمیشن (`KankiAnimInstance` + AnimBP)

- **State Machine:** Locomotion، InAir (Jump Start/Loop/Land)، Death، و Vault/Climb با montage.
- **Locomotion:** برای هر حالت (ایستاده، خمیده، درازکش) یه **BlendSpace 2D**:
  - محور X: جهت (-180..180)
  - محور Y: سرعت (0..640)
  - شامل: Idle، Walk ۸ جهت، Run، Sprint
- **همهٔ transition‌ها ≤ 0.08 s.**
- **Turn in place:** وقتی بدن بیش از ۹۰ درجه با دوربین فاصله داره.
- **بالاتنهٔ لایه‌ای** (Layered blend per bone از `spine_01`):
  - **AimOffset 2D** (yaw ±90، pitch ±90)
  - حالت ADS
  - slot montage برای Fire، Reload، Equip و Hit react
- **IK:**
  - دست چپ با Two Bone IK روی سوکت `LeftHandGrip` اسلحه
  - انگشت‌ها با **Pose Asset برای هر اسلحه** (درس نسخهٔ Godot: انگشت‌های انیمیشن Mixamo کج بودن)
  - Foot IK روی شیب (Control Rig، فقط کیفیت High)
- **منبع انیمیشن، از بهترین:**
  1. **Lyra Starter Game** (رایگان، Epic): انیمیشن‌های حرفه‌ای رایفل (locomotion، ADS، reload، jump، crouch). با **IK Retargeter** به اسکلت کاراکترهای ما منتقل بشه.
  2. **Game Animation Sample Project** (رایگان، Epic، UE 5.4+): locomotion با کیفیت خیلی بالا.
  3. انیمیشن‌های Mixamo فعلی (`mixamo/anims`، ۲۷ تا) به‌عنوان پشتیبان.
- **کارایی موبایل:**
  - Animation Budget Allocator
  - URO برای بازیکن‌های دور
  - `VisibilityBasedAnimTickOption = OnlyTickPoseWhenRendered` برای بقیه

---

## ۵. دوربین (پرامپت بخش ۲)

**SpringArm:**

| تنظیم | مقدار |
|---|---|
| `TargetArmLength` | 230 |
| `SocketOffset` | (0, 55, 65): کمی راست و بالای شونه |
| `bEnableCameraLag` | true |
| `CameraLagSpeed` | 12 |
| `CameraLagMaxDistance` | 30 |
| `bEnableCameraRotationLag` | **false** (لگ چرخش، نشونه‌گیری رو خراب می‌کنه) |
| `ProbeSize` | 12 |
| `bDoCollisionTest` | true |

**FOV** (در `KankiCameraManager`، با `FInterpTo`، سرعت ۱۰):

| حالت | FOV |
|---|---|
| پایه | 68 |
| دوی سریع | 78 |
| ADS ردات | 55 |
| دوربین 2x | 40 |
| دوربین 4x | 20 |
| دوربین 6x | 13 |

**ADS مثل PUBG:** دید **اول‌شخص از پشت دوربین اسلحه**.
- دوربین در ~۰.۱۸ ثانیه به سوکت `Sight` اسلحه blend می‌شه.
- اسلحه طوری می‌چرخه که نقطهٔ ردات دقیقاً جای خوردن تیر باشه.
- سر و شونهٔ خود بازیکن نزدیک لنز با dither محو می‌شه.
- (نسخهٔ Godot همین کار رو کرده: `scripts/weapon_holder.gd`، `scripts/player.gd` → `_update_view`.)

**پیک:**
- دوربین ۵۰ سانت به سمت پیک جابه‌جا می‌شه.
- roll حدود ۶ درجه.
- با `FInterpTo`، سرعت ۱۵.

**حساسیت جدا برای هر دوربین** (TPP، ردات، 2x، 4x، 6x، 8x)، مثل PUBG، به‌اضافهٔ **ژیروسکوپ**:
- حالت‌ها: همیشه / فقط اسکوپ / خاموش
- حساسیت جدا برای هر دوربین
- invert محور X و Y

---

## ۶. گان‌پلی (پرامپت بخش ۳)

- **ADS:** ۱۶۰ تا ۲۰۰ میلی‌ثانیه. Timeline یا InterpTo روی alpha.
- **پیک:**
  - حالت replicate‌شده (-1/0/1)
  - بالاتنه ~۲۰ درجه کج می‌شه (در AnimBP، چرخش `spine` و `spine_03`)
- **Hitbox:**
  - برخورد تیر با **Physics Asset** مش (استخوان‌ها)، نه کپسول. پس hitbox خودش با پیک جابه‌جا می‌شه و بدن کامل بیرون نمی‌زنه.
  - ضریب آسیب برای هر استخوان (سر، گردن، بدن، دست‌وپا).
- **شلیک:**
  - Hitscan و **Server-authoritative**.
  - کلاینت فقط افکت رو فوری نشون می‌ده.
  - سرور تیر رو با **Lag Compensation** بررسی می‌کنه:
    - تاریخچهٔ موقعیت hitbox‌ها تا ۲۰۰ میلی‌ثانیه نگه داشته می‌شه
    - موقع بررسی، hitbox‌ها به لحظهٔ شلیک کلاینت برگردونده می‌شن
  - اعتبارسنجی: سرعت شلیک، فاصله، دید (ضدتقلب پایه).
- **Recoil لایه‌ای:**
  1. **الگوی recoil هر اسلحه:** curve عمودی و افقی برای هر تیر، اعمال روی Control Rotation، با recovery بعد از رها کردن ماشه.
  2. **لگد procedural روی مش اسلحه و viewmodel:** عقب رفتن ۱ تا ۲ سانت و چرخش کوچیک، با فنر (spring/damper) برمی‌گرده.
  3. **Camera Shake ملایم** (`UCameraShakeBase`، دامنهٔ کم).
  4. **Spread:** hip، ADS، حرکت، هوا، خمیده و درازکش. نشونه‌گر (crosshair) پویا باهاش تغییر می‌کنه.
- **افکت‌ها:**
  - Niagara سبک برای موبایل: muzzle flash (موقع ADS کوچیک بشه)، tracer، جرقه و دود برخورد، decal گلوله
  - همه **pool** بشن
- **بازخورد:** hit marker (سفید / قرمز برای سر)، صدای hit، نشانگر جهت آسیب، kill feed، «You killed …».
- **اسلحه‌ها و اتچمنت:**
  - M416، AKM و UMP45 با ردات پیش‌فرض.
  - بعداً: 2x، 4x، صداخفه‌کن، grip، خشاب بزرگ.
  - **تعویض اسلحه** (دو اسلات، مثل PUBG) و **نارنجک** (اضافه‌شده).

---

## ۷. کنترل‌های لمسی و رابط کاربری (PUBG Mobile)

**دکمه‌ها:** دایرهٔ تیرهٔ نیمه‌شفاف با آیکون سفید (آیکون‌های SVG فعلی در `assets/ui/icons`، تبدیل به PNG).

| دکمه | جای پیش‌فرض |
|---|---|
| شلیک بزرگ (آیکون گلوله) | بالا راست |
| شلیک دوم | چپ |
| ADS | راست وسط |
| پرش | راست |
| خمیده، درازکش، ریلود | پایین راست |
| پیک چپ و راست | چپ بالا |
| تعویض اسلحه و نارنجک | پایین وسط |

- **جوی‌استیک شناور:** همون‌جایی که انگشت گذاشته بشه ظاهر می‌شه، با قفل دوی سریع.
- **کشیدن انگشت** روی سمت راست صفحه (یا از روی دکمه‌ها) = چرخش دوربین.
- **ویرایشگر چیدمان:** جابه‌جایی، اندازه و شفافیت، با ذخیره روی دستگاه.
- **HUD:**
  - بالا وسط: امتیاز تیم‌ها و تایمر
  - چپ بالا: kill feed
  - راست بالا: **مینی‌مپ** (اضافه‌شده)
  - پایین وسط: جون، و اسلات اسلحه + مهمات
  - تابلوی امتیاز
  - صفحهٔ «ELIMINATED / Respawning in 3» (بعد از زنده شدن پاک بشه)
  - پایان مسابقه
- **منوها** (UMG + CommonUI):
  1. Splash (لوگوی KANKI)
  2. ورود و ثبت‌نام (با انتخاب کاراکتر مرد/زن)
  3. لابی شیشه‌ای مشکی AMOLED:
     - کاراکتر سه‌بعدی چرخ‌پذیر
     - انتخاب کاراکتر و اسلحه
     - START و **VS BOTS**
  4. تنظیمات: حساسیت، ژیروسکوپ، گرافیک و FPS (۳۰ / ۶۰ / ۹۰ / ۱۲۰)، چیدمان دکمه‌ها
- نمونهٔ ظاهر مورد قبول در Godot: `scripts/main_menu.gd`، `scripts/login.gd`، `scripts/hud/`.

---

## ۸. شبکه، سرور، ربات و اکانت (اضافه‌شده؛ پرامپت نداشت ولی لازمه)

- **معماری:** Dedicated Server لینوکسی روی VPS فعلی (`server/install-server.sh` رو برای باینری UE به‌روز کن). کلاینت اندروید.
  - **هشدار:** به Unreal ساخته‌شده از سورس نیاز داره.
- **GameMode و GameState:**
  - تیم‌بندی متعادل
  - امتیاز، تایمر ۶۰۰ ثانیه و هدف ۴۰
  - respawn با محافظت
  - پایان و شروع دوبارهٔ خودکار
- **Replication:**
  - حرکت با CMC، که prediction داخلی داره
  - شلیک و آسیب با RPC به سرور
  - **Replication Graph** فقط اگه بعداً تعداد بازیکن بیشتر شد
- **ربات‌ها** (`KankiBotController` + StateTree):
  - پیدا کردن دشمن، مسیر با NavMesh
  - دید با trace
  - **زمان واکنش ~۰.۵۵ ثانیه** و خطای نشونه‌گیری که کم‌کم درست می‌شه
  - شلیک رگباری، جاخالی به چپ و راست، پناه گرفتن پشت کاور
  - پر کردن تیم‌ها وقتی بازیکن کمه، و **حالت VS BOTS** آفلاین
- **اکانت:**
  - سرور UDP ساده و فعلی رو با **Nakama** (متن‌باز، روی همون VPS) یا PlayFab عوض کن
  - ثبت‌نام و ورود، ذخیرهٔ کاراکتر، اسلحه و تنظیمات
  - بعداً matchmaking
- **امنیت:** سرور فقط به داده‌های خودش اعتماد کنه. رمز هرگز داخل کد نوشته نشه.

---

## ۹. گرافیک موبایل و ۹۰ FPS (پرامپت بخش ۴)

### رندرر

- **Mobile Renderer**، Forward Shading، **Vulkan** (SM5 موبایل) با فالبک **OpenGL ES 3.1**.
- MSAA ×4، که روی GPUهای tile ارزونه.
- خاموش: Lumen، Nanite، VSM، SSR، Ray tracing، Distance Field AO.

### نور

- **مپ کاملاً Static با Lightmass:**
  - کیفیت Production
  - lightmap density یکنواخت
  - Lightmass Importance Volume دور مپ
- **خورشید:** Stationary Directional Light.
  - سایهٔ **دینامیک فقط برای کاراکترها و اسلحه‌ها:** Mobile CSM، فاصلهٔ ~۳۰ متر، ۱ تا ۲ cascade
  - سایهٔ محیط پخته‌شده
- **Sky Light Static.**
- **Reflection Capture** چند تا.
- **AO:** از lightmap. Mobile AO فقط برای پروفایل Ultra، اختیاری.

### Post Process (یه PostProcessVolume Unbound)

| تنظیم | مقدار |
|---|---|
| Saturation | 1.15 |
| Contrast | 1.08 |
| Bloom intensity | 0.4 (mobile bloom) |
| Exposure | ثابت (Manual) برای پایداری |
| Vignette | ملایم |
| Tonemapper | Filmic |

- Sharpen: `r.Tonemapper.Sharpen 0.5`.
- رنگ‌ها مثل PUBG Mobile: روشن و پرانرژی، نه خاکستری.

### تکسچر و مش

- **ASTC:**
  - کاراکترها و اسلحه‌ها: 6x6
  - محیط: 8x8
- Texture Group‌ها با حداکثر اندازه:
  - کاراکتر: 2048
  - اسلحه: 1024
  - prop: 1024
- **LOD برای همهٔ مش‌ها:**
  - کاراکتر ۳ سطح، با Skeletal Mesh LOD و حذف استخوان انگشت در LOD2
  - HLOD برای مپ
  - Precomputed Visibility یا Software Occlusion برای مپ ثابت
- **بودجهٔ هر فریم:**
  - کمتر از ~۲۰۰ draw call
  - کمتر از ~۳۰۰ هزار مثلث
  - instancing برای prop‌های تکراری (ISM/HISM)

### ۹۰ FPS

- `t.MaxFPS=90`.
- تنظیمات Android:
  - درخواست نرخ ۹۰ یا ۱۲۰ هرتز از نمایشگر
  - **Swappy frame pacing** (`r.Vulkan.UseSwappy=1` / `a.UseFramePacer`)
- **مهم:** **Fixed Frame Rate روشن نشه**، چون زمان بازی رو کند می‌کنه.
- فیزیک: substepping خاموش، `MaxPhysicsDeltaTime=1/30`.
- **Device Profiles** (`DefaultDeviceProfiles.ini`):
  - Low (30 FPS)، Medium (60)، High (90)، Ultra (90/120)
  - هر کدوم با `r.MobileContentScaleFactor`، کیفیت سایه، فاصلهٔ دید، MSAA و bloom
  - انتخاب خودکار بر اساس GPU و انتخاب دستی در تنظیمات
- **Thermal:**
  - تست ۲۰ دقیقه‌ای روی گوشی واقعی (Snapdragon 8 Gen 1 به بالا، صفحهٔ 90/120Hz)
  - Unreal Insights + `stat unit`، `stat gpu`، `stat scenerendering`
  - ADPF / Android Performance Tuner در صورت نیاز
- **حجم APK:** خروجی AAB برای Play Store، و Pak chunking.

---

## ۱۰. Asset‌های قابل استفاده از ریپوی فعلی

| Asset | مسیر | در UE |
|---|---|---|
| کاراکتر مرد و زن (با اسکلت Mixamo ۶۵ استخوان و انگشت) | `mixamo/male_upload.fbx`، `mixamo/female_upload.fbx` | Import FBX → IK Rig → IK Retargeter به Manny / Lyra |
| تکسچر لباس قرمز تیم | `assets/characters/team_colors/` | Material Instance با پارامتر رنگ یا تکسچر تیم |
| انیمیشن‌ها (۲۷ تا) | `mixamo/anims/*.fbx` | پشتیبان. اصلی: Lyra |
| اسلحه‌ها | `assets/weapons/m416.glb`، `akm.glb`، `ump45.glb` | Interchange / glTF. سوکت‌ها: `Muzzle`، `Sight`، `LeftHandGrip`، `RightHandGrip` |
| propهای مپ | `assets/props/*.glb` (container، crate، barrel، barrier، pillar) | Static Mesh + LOD + lightmap UV |
| UI | `assets/ui/` (lobby_bg، portraits، weapon icons، `icons/*.svg`)، فونت‌ها در `assets/fonts/` | PNG (SVG → PNG) |
| مدل‌های Meshy (منبع) | `docs/ASSETS.md`، `tools/meshy/` | برای ساخت asset جدید (اعتبار Meshy Pro) |

**درس‌هایی که از نسخهٔ Godot گرفتیم:**
- انگشت‌های Mixamo روی این اسکلت کج می‌شن، پس برای هر اسلحه **grip pose** درست کن.
- مدل‌های Meshy کف دست ضخیم دارن.
- شست باید از نزدیک مچ شروع بشه (`tools/mixamo/make_mixamo_rig.py` درستش کرده).

---

## ۱۱. مراحل کار (هر مرحله: کار، و شرط «تمومه وقتی…»)

| مرحله | کار | تمومه وقتی… |
|---|---|---|
| **M0** | ریپوی جدید + LFS، پروژهٔ C++ موبایل، تنظیمات ini بخش ۹، CI (build روی self-hosted runner ویندوزی) | پروژهٔ خالی روی گوشی با ۹۰ FPS اجرا بشه |
| **M1** | Character + Movement (بخش ۴) + دوربین (بخش ۵) + کنترل لمسی پایه | راه رفتن، دویدن، اسپرینت، پرش و خمیده با تغییر جهت آنی روی گوشی |
| **M2** | Import کاراکترها و retarget انیمیشن‌های Lyra، AnimBP کامل (BlendSpace، AimOffset، IK، transition کمتر از ۰.۱ ثانیه) | بدون سُر خوردن پا، با چرخش درجا، انگشت‌ها دور اسلحه |
| **M3** | اسلحه‌ها، ADS از پشت ردات، recoil لایه‌ای، پیک، Vault و Climb، درازکش | جیگل‌پیک روون، ADS در ۱۸۰ میلی‌ثانیه، ردات = جای تیر |
| **M4** | HUD و کنترل‌های کامل (بخش ۷) + تنظیمات حساسیت و ژیروسکوپ | همهٔ دکمه‌های PUBG کار کنن، چیدمان ذخیره بشه |
| **M5** | شبکه: Dedicated server، TDM، lag compensation، ربات‌ها، VS BOTS | مسابقهٔ ۵ در برابر ۵ (ترکیب آدم و ربات) بدون لرزش روی سرور |
| **M6** | مپ Warehouse با lightmap، post process، صدا | مپ کامل، رنگی و روشن، با سایه‌های پخته |
| **M7** | منوها، اکانت (Nakama)، لابی | ثبت‌نام، ورود، انتخاب کاراکتر و اسلحه، START |
| **M8** | بهینه‌سازی: Device profiles، LOD، تست thermal | ۹۰ FPS پایدار ۲۰ دقیقه روی گوشی هدف |
| **M9** | انتشار: AAB، امضا، Play Store | نسخهٔ تست داخلی روی Play Console |

**قاعده برای دستیار در هر مرحله:**
- کد C++ و ini رو کامل بنویس.
- اسکریپت Python ادیتور برای کارهای تکراری بنویس (import، ساخت BlendSpace، تنظیم سوکت‌ها).
- برای کارهایی که فقط در ادیتور ممکنه (گراف AnimBP، چیدمان مپ، bake نور) **دستور قدم‌به‌قدم ساده به فارسی** برای صاحب پروژه بنویس.
