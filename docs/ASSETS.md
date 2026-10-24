# 📋 لیست کامل فایل‌هایی که باید بسازی یا دانلود کنی

این فایل نقشهٔ کامل کار توئه: **چی بسازی، کجا، با چه مشخصاتی، و کجای ریپازیتوری آپلود کنی.**
هر فایلی که آپلود کردی، تیکش رو بزن و به من خبر بده تا وصلش کنم به بازی.

> 🎯 هدف فعلی: **فقط اندروید**. همهٔ مشخصات زیر برای اینه که روی گوشی‌های معمولی هم روان اجرا بشه.

---

## ⚠️ قبل از شروع، این‌ها رو بخون

1. **VPN:** بیشتر این سایت‌ها (Meshy، Tripo، Mixamo) ایران رو بستن. با VPN وارد شو.
2. **کپی‌رایت:** هیچ‌وقت عکس یا اسم پابجی رو به هوش مصنوعی نده. فقط با **متن خودت** توضیح بده. Promptهای پایین همه طرح خودمونه.
3. **لایسنس:** نسخهٔ رایگان این سایت‌ها معمولاً لایسنس **CC BY 4.0** داره، یعنی باید اسم سایت رو توی بازی بیاریم (Credits). تا وقتی بازی بین خودمون و دوستامونه مشکلی نیست. اگه خواستیم بازی رو بفروشیم، باید اشتراک پولی بگیریم. لایسنس هر سایت رو موقع دانلود چک کن.
4. **ثبت منبع:** برای هر فایلی که آپلود می‌کنی، یه خط توی فایل `CREDITS.md` بنویس: اسم فایل، از کدوم سایت، و لایسنسش.
5. **آپلود:** توی GitHub برو توی پوشهٔ مورد نظر، بعد **Add file ← Upload files**. هر فایل حداکثر **۲۵ مگابایت**. اگه بیشتر بود، به من بگو.

---

## 🧰 سایت‌ها و ابزارها

| کار | سایت | توضیح |
|---|---|---|
| ساخت مدل سه‌بعدی با هوش مصنوعی | **[meshy.ai](https://www.meshy.ai)** | متن یا عکس → مدل سه‌بعدی با تکسچر. **پیشنهاد اول من** |
| ساخت مدل سه‌بعدی با هوش مصنوعی | **[tripo3d.ai](https://www.tripo3d.ai)** | مثل Meshy. اگه نتیجهٔ Meshy خوب نبود، اینو امتحان کن |
| ساخت مدل سه‌بعدی با هوش مصنوعی | **[hyper3d.ai](https://hyper3d.ai)** (Rodin) | کیفیت خیلی بالا، ولی اعتبار رایگانش کمه |
| اسکلت + انیمیشن کاراکتر | **[mixamo.com](https://www.mixamo.com)** | رایگان (با اکانت Adobe). اسکلت می‌ذاره و صدها انیمیشن آماده داره |
| تکسچر (بتن، فلز، آسفالت، زنگ‌زدگی) | **[ambientcg.com](https://ambientcg.com)** | رایگان، لایسنس CC0 (بدون نیاز به ذکر منبع) |
| تکسچر + آسمان (HDRI) | **[polyhaven.com](https://polyhaven.com)** | رایگان، CC0. آسمان واقعی و تکسچرهای عالی |
| مدل‌های آماده (اختیاری) | **[sketchfab.com](https://sketchfab.com)** | فیلتر **Downloadable** رو بزن. فقط لایسنس CC0 یا CC BY بردار |
| صدا | **[freesound.org](https://freesound.org)** | رایگان. فیلتر لایسنس رو بذار روی **Creative Commons 0** |
| صدای حرفه‌ای (بسته‌ٔ بزرگ) | **[sonniss.com/gameaudiogdc](https://sonniss.com/gameaudiogdc)** | چند گیگ صدای رایگان و قانونی برای بازی |
| آیکون دکمه‌ها | **[game-icons.net](https://game-icons.net)** | آیکون‌های بازی، لایسنس CC BY |
| فونت فارسی | **[Vazirmatn](https://github.com/rastikerdar/vazirmatn)** | اگه خواستیم منو فارسی بشه |

---

## 1️⃣ کاراکترها و لباس‌ها (Skins)

### روش کار (برای هر کاراکتر)

```
Meshy / Tripo  ──►  FBX در حالت T-pose  ──►  Mixamo (اسکلت خودکار)  ──►  دانلود FBX  ──►  آپلود
```

1. توی **Meshy** برو به **Text to 3D**. Prompt رو بنویس (پایین‌تر هست).
2. قبل از ساختن، این تنظیمات رو بذار:
   - **Pose:** `T-pose` (یا `A-pose`). خیلی مهمه، بدون این اسکلت درست نمی‌شینه
   - **Polycount / Target:** حدود **15,000** (بین 10k تا 20k)
   - **Texture:** `PBR` روشن
3. از بین ۴ نتیجه، بهترین رو انتخاب کن و **Texture** رو بزن.
4. **Download** با فرمت **FBX**. اگه FBX نداشت، **OBJ** هم قبوله.
5. برو به **Mixamo** ← **Upload Character** ← فایل رو بده.
6. Mixamo ازت می‌خواد نقطه‌ها رو بذاری: **چونه، مچ دست‌ها، آرنج‌ها، زانوها، کشاله**. بذار و **Next** بزن.
7. وقتی کاراکتر آماده شد، بدون انتخاب انیمیشن **Download** بزن:
   - Format: **FBX Binary (.fbx)**
   - Skin: **With Skin**
   - Pose: **T-pose**

### مشخصات فنی

| مورد | مقدار |
|---|---|
| فرمت | FBX (از Mixamo) |
| تعداد مثلث | ۱۰ تا ۲۰ هزار |
| تکسچر | 1024×1024 (حداکثر 2048×2048) |
| ژست | T-pose، رو به جلو |
| قد | مهم نیست، خودم درستش می‌کنم |
| تعداد | هر کدوم **یه فایل کامل** (سر تا پا با لباس) |

> 💡 **چرا هر لباس یه کاراکتر کامل؟** عوض کردن تیکه‌تیکه‌ٔ لباس (کلاه جدا، شلوار جدا) خیلی پیچیده‌ست. فعلاً هر Skin یه آدم کامله. چون همه از Mixamo اسکلت می‌گیرن، **همهٔ انیمیشن‌ها روی همه‌شون کار می‌کنه**.

### لیست کاراکترها ← آپلود در `assets/characters/skins/`

| ☐ | اسم فایل | Prompt (کپی کن) |
|---|---|---|
| ☐ | `default_blue.fbx` | `realistic special forces soldier, full body, T-pose, dark navy combat uniform, black tactical plate carrier vest, blue shoulder patch, black helmet, black face mask, tactical gloves, combat boots, game character, PBR` |
| ☐ | `default_red.fbx` | `realistic mercenary soldier, full body, T-pose, dark red combat jacket, brown tactical vest, red bandana face mask, black cap, tactical gloves, combat boots, game character, PBR` |
| ☐ | `skin_shadow.fbx` | `realistic stealth operator, full body, T-pose, black hooded jacket, black tactical pants, white skull face mask, black gloves, game character, PBR` |
| ☐ | `skin_desert.fbx` | `realistic desert soldier, full body, T-pose, tan desert camouflage uniform, shemagh scarf around neck, sunglasses, tan helmet, game character, PBR` |
| ☐ | `skin_urban.fbx` | `realistic urban fighter, full body, T-pose, grey hoodie, dark jeans, black bulletproof vest, gas mask, sneakers, game character, PBR` |
| ☐ | `skin_arctic.fbx` | `realistic arctic soldier, full body, T-pose, white winter camouflage uniform, white helmet, goggles, white gloves, game character, PBR` |

**اولویت:** اول فقط `default_blue.fbx` رو بساز و بفرست تا ببینیم نتیجه خوبه. بعد بقیه رو بساز.

---

## 2️⃣ انیمیشن‌ها ← آپلود در `assets/animations/`

توی **Mixamo**، وقتی `default_blue` رو آپلود کردی، از تب **Animations** این‌ها رو **جستجو** کن. برای هر کدوم:

- تیک **In Place** رو بزن (اگه بود). خیلی مهمه
- **Download** ← Format: **FBX Binary** ← Skin: **Without Skin** ← Frames per second: **30**

| ☐ | اسم فایل | چی جستجو کنی | کجا استفاده می‌شه |
|---|---|---|---|
| ☐ | `idle.fbx` | `rifle idle` | ایستادن |
| ☐ | `aim_idle.fbx` | `rifle aiming idle` | ایستادن موقع نشونه‌گیری |
| ☐ | `run.fbx` | `rifle run` | دویدن رو به جلو |
| ☐ | `walk_forward.fbx` | `rifle walk forward` | راه رفتن |
| ☐ | `walk_back.fbx` | `rifle walk backward` | عقب رفتن |
| ☐ | `strafe_left.fbx` | `rifle strafe left` | رفتن به چپ |
| ☐ | `strafe_right.fbx` | `rifle strafe right` | رفتن به راست |
| ☐ | `crouch_idle.fbx` | `crouch rifle idle` | نشسته |
| ☐ | `crouch_walk.fbx` | `crouch walk rifle` | راه رفتن نشسته |
| ☐ | `jump.fbx` | `rifle jump` | پرش |
| ☐ | `fire.fbx` | `firing rifle` | شلیک |
| ☐ | `reload.fbx` | `reloading` | خشاب عوض کردن |
| ☐ | `hit.fbx` | `hit reaction` | تیر خوردن |
| ☐ | `death.fbx` | `dying` یا `death from front` | مردن |
| ☐ | `lobby_pose_1.fbx` | `standing idle` یا `looking around` | ژست توی لابی |
| ☐ | `lobby_pose_2.fbx` | `salute` یا `victory` | ژست توی لابی |

> اگه اسم دقیق پیدا نشد، نزدیک‌ترینش رو بردار. اسم فایل رو همونی بذار که توی جدوله.

---

## 3️⃣ اسلحه‌ها ← آپلود در `assets/weapons/`

با **Meshy** یا **Tripo** بساز ← دانلود **GLB**.

| مورد | مقدار |
|---|---|
| فرمت | GLB |
| تعداد مثلث | حداکثر ۵ هزار |
| تکسچر | 1024×1024 |
| جهت | از پهلو، لوله رو به جلو |

| ☐ | اسم فایل | Prompt |
|---|---|---|
| ☐ | `rifle.glb` | `realistic modern assault rifle, black metal and polymer, red dot sight, vertical foregrip, game weapon asset, side view, PBR` |
| ☐ | `smg.glb` | `realistic compact submachine gun, black, folding stock, game weapon asset, PBR` |
| ☐ | `sniper.glb` | `realistic bolt action sniper rifle, olive green, long scope, bipod, game weapon asset, PBR` |
| ☐ | `shotgun.glb` | `realistic pump action tactical shotgun, black, game weapon asset, PBR` |
| ☐ | `pistol.glb` | `realistic semi-automatic pistol, black, game weapon asset, PBR` |

---

## 4️⃣ محیط جنگ (مپ «انبار» / Warehouse)

مپ رو **خودم** با تیکه‌هایی که تو میاری می‌سازم. اندازه‌ٔ مپ **۵۶ × ۴۴ متره** و ۵ نفر در برابر ۵ نفر توش بازی می‌کنن. تو فقط تیکه‌ها و تکسچرها رو بیار.

### الف) وسایل (Props) ← آپلود در `assets/maps/warehouse/props/`

با **Meshy/Tripo** بساز ← **GLB** ← حداکثر **۳ هزار مثلث** ← تکسچر **1024**.

| ☐ | اسم فایل | Prompt | اندازهٔ واقعی |
|---|---|---|---|
| ☐ | `container.glb` | `realistic 20ft shipping container, corrugated steel, closed doors, rusty, game asset, PBR` | ۶ × ۲.۶ × ۲.۴ متر |
| ☐ | `crate_wood.glb` | `realistic wooden shipping crate, planks, game asset, PBR` | ۱.۲ متر |
| ☐ | `crate_metal.glb` | `realistic military metal ammo crate, olive green, game asset, PBR` | ۱ × ۰.۶ × ۰.۵ |
| ☐ | `barrel.glb` | `realistic rusty blue oil barrel, game asset, PBR` | ۰.۹ متر |
| ☐ | `barrier.glb` | `realistic concrete jersey barrier with yellow stripes, game asset, PBR` | ۲ × ۰.۸ متر |
| ☐ | `sandbags.glb` | `realistic sandbag wall, military, game asset, PBR` | ۲ × ۱ متر |
| ☐ | `pallet_stack.glb` | `realistic stack of wooden pallets, game asset, PBR` | ۱.۲ × ۱ متر |
| ☐ | `forklift.glb` | `realistic yellow warehouse forklift, game asset, PBR` | ۳ متر |
| ☐ | `shelf.glb` | `realistic industrial warehouse metal shelving rack with boxes, game asset, PBR` | ۴ × ۳ متر |
| ☐ | `truck.glb` | `realistic old military cargo truck, olive green, game asset, PBR` | ۷ متر |

### ب) تکسچرها ← آپلود در `assets/maps/warehouse/textures/`

از **ambientcg.com** دانلود کن ← اندازهٔ **1K-JPG** یا **2K-JPG** ← از داخل zip فقط این ۳ فایل رو بردار:
`..._Color.jpg` و `..._NormalGL.jpg` و `..._Roughness.jpg`

هر تکسچر رو توی یه پوشهٔ جدا بذار. مثلاً: `textures/concrete_floor/Color.jpg`

| ☐ | پوشه | توی سایت جستجو کن |
|---|---|---|
| ☐ | `concrete_floor` | `Concrete` (یه بتن خاکستری کف) |
| ☐ | `concrete_wall` | `Concrete` (یه بتن روشن‌تر) |
| ☐ | `metal_wall` | `CorrugatedSteel` |
| ☐ | `metal_rust` | `Rust` |
| ☐ | `asphalt` | `Asphalt` |
| ☐ | `painted_metal` | `PaintedMetal` |

### ج) آسمان ← آپلود در `assets/maps/warehouse/`

از **polyhaven.com/hdris** یه آسمان روز آفتابی دانلود کن ← اندازهٔ **1K** ← فرمت **HDR** ← اسمش رو بذار `sky.hdr`

---

## 5️⃣ محیط لابی ← آپلود در `assets/lobby/`

لابی جاییه که سربازت وسط صفحه وایساده. یکی از این دو تا رو انتخاب کن:

**گزینهٔ الف: آشیانهٔ هواپیما (Hangar)**

| ☐ | اسم فایل | Prompt |
|---|---|---|
| ☐ | `helicopter.glb` | `realistic military transport helicopter, parked, game asset, PBR` |
| ☐ | `jeep.glb` | `realistic military off-road jeep, game asset, PBR` |
| ☐ | `crates_lobby.glb` | `realistic pile of military supply crates and ammo boxes, game asset, PBR` |
| ☐ | `platform.glb` | `round futuristic metal display platform with lights, game asset, PBR` |

**گزینهٔ ب: پشت‌بوم شهر**

| ☐ | اسم فایل | Prompt |
|---|---|---|
| ☐ | `rooftop.glb` | `realistic city rooftop with AC units, antenna and railing, game environment, PBR` |
| ☐ | `motorbike.glb` | `realistic dirt motorbike, game asset, PBR` |

**هر دو گزینه:** از **polyhaven.com/hdris** یه آسمان غروب یا شب بردار ← **1K HDR** ← اسمش رو بذار `lobby_sky.hdr`

---

## 6️⃣ صداها ← آپلود در `assets/sounds/`

از **freesound.org** (فیلتر **CC0**) یا **Sonniss**. فرمت **WAV** یا **OGG**، هر کدوم کمتر از ۵ ثانیه.

| ☐ | اسم فایل | جستجو کن |
|---|---|---|
| ☐ | `rifle_shot.wav` | `rifle shot` / `assault rifle single` |
| ☐ | `smg_shot.wav` | `smg shot` |
| ☐ | `sniper_shot.wav` | `sniper rifle shot` |
| ☐ | `reload.wav` | `rifle reload` |
| ☐ | `empty_click.wav` | `gun dry fire` |
| ☐ | `footstep_concrete_1.wav` | `footstep concrete` |
| ☐ | `footstep_concrete_2.wav` | (یه قدم دیگه، فرق داشته باشه) |
| ☐ | `hit_body.wav` | `bullet impact flesh` |
| ☐ | `hit_headshot.wav` | `headshot` / `helmet hit` |
| ☐ | `bullet_wall.wav` | `bullet impact concrete` |
| ☐ | `jump_land.wav` | `jump land` |
| ☐ | `kill_confirm.wav` | `kill confirm` / `ui success` |
| ☐ | `button_click.wav` | `ui click` |
| ☐ | `lobby_music.ogg` | `epic military music` (حدود ۱ تا ۲ دقیقه، قابل تکرار) |
| ☐ | `match_win.wav` | `victory fanfare` |
| ☐ | `match_lose.wav` | `defeat` |

---

## 7️⃣ ظاهر بازی (UI) ← آپلود در `assets/ui/`

| ☐ | اسم فایل | چی | از کجا |
|---|---|---|---|
| ☐ | `logo.png` | لوگوی بازی، پس‌زمینهٔ شفاف، 1024×1024 | خودت طراحی کن، یا با هوش مصنوعی عکس‌ساز. مثلاً: `game logo, letter K, crosshair, military, gold and black, transparent background` |
| ☐ | `app_icon.png` | آیکون برنامه روی گوشی، 512×512 | مثل لوگو، ولی مربعی |
| ☐ | `icon_fire.png` و `icon_aim.png` و `icon_jump.png` و `icon_crouch.png` و `icon_reload.png` | آیکون دکمه‌ها، سفید، پس‌زمینهٔ شفاف | [game-icons.net](https://game-icons.net). رنگ رو سفید بذار و PNG دانلود کن |

---

## 8️⃣ ساختار نهایی پوشه‌ها

```
assets/
├── characters/skins/     ← کاراکترها و لباس‌ها (FBX از Mixamo)
├── animations/           ← انیمیشن‌ها (FBX بدون Skin)
├── weapons/              ← اسلحه‌ها (GLB)
├── maps/warehouse/
│   ├── props/            ← وسایل مپ (GLB)
│   ├── textures/         ← تکسچرها (هر کدوم یه پوشه)
│   └── sky.hdr
├── lobby/                ← وسایل و آسمان لابی
├── sounds/               ← صداها
└── ui/                   ← لوگو، آیکون برنامه، آیکون دکمه‌ها
```

---

## ✅ ترتیب پیشنهادی

1. `default_blue.fbx` + انیمیشن‌های `idle`، `run`، `fire`، `death` ← **برای تست کیفیت**
2. بقیهٔ انیمیشن‌ها
3. `rifle.glb` + صداهای شلیک
4. تکسچرهای مپ + `sky.hdr`
5. وسایل مپ
6. لابی
7. بقیهٔ Skinها و اسلحه‌ها
8. لوگو و آیکون‌ها

بعد از هر مرحله که آپلود کردی، به من بگو تا وصلش کنم به بازی و نسخهٔ جدید APK ساخته بشه.
