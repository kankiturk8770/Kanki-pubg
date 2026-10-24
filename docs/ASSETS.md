# 🎮 راهنمای کامل ساخت فایل‌های بازی (از ۰ تا ۱۰۰)

این فایل همه‌چیزیه که باید بسازی یا دانلود کنی، **به ترتیب**.
برای هر مورد **پرامپت جدا** گذاشتم. هر کدوم رو جدا کپی کن، جدا بساز و جدا دانلود کن.

> 🎯 هدف: **فقط اندروید.** مشخصات طوری انتخاب شده که روی گوشی‌های معمولی روان اجرا بشه.
> ✅ هر فایلی رو که آپلود کردی، توی همین لیست تیکش رو بزن (یا به من بگو تا بزنم).

---

## فهرست

- مرحلهٔ ۰: آماده‌سازی
- مرحلهٔ ۱: سربازها (۶ تا)
- مرحلهٔ ۲: اسکلت‌گذاری در Mixamo
- مرحلهٔ ۳: انیمیشن‌ها (۱۸ تا)
- مرحلهٔ ۴: اسلحه‌ها (۲۴ تا)
- مرحلهٔ ۵: قطعات اسلحه (Attachment)
- مرحلهٔ ۶: نارنجک‌ها
- مرحلهٔ ۷: محیط جنگ (مپ)
- مرحلهٔ ۸: محیط لابی
- مرحلهٔ ۹: صداها
- مرحلهٔ ۱۰: لوگو، آیکون و ظاهر
- مرحلهٔ ۱۱: آپلود و تحویل
- کارهای من

---

## مرحلهٔ ۰ — آماده‌سازی

### وسیله
- **لپ‌تاپ یا کامپیوتر.** Mixamo روی گوشی درست کار نمی‌کنه. اگه نداری، گیم‌نت هم کافیه.
- اینترنت خوب (فایل‌ها بین ۵ تا ۳۰ مگابایتن)

### ساختن اکانت روی این سایت‌ها

> این اکانت‌ها **مال خود این سایت‌ها**ن، برای ساختن مدل‌ها. ربطی به ثبت‌نام **بازی خودمون** ندارن. اون رو خودم جدا می‌سازم (ته همین فایل توضیح دادم).

| ☐ | سایت | برای چی | هزینه |
|---|---|---|---|
| ☐ | [meshy.ai](https://www.meshy.ai) | ساخت سرباز، اسلحه و وسایل با هوش مصنوعی | رایگان (محدود) / Pro ماهانه |
| ☐ | [tripo3d.ai](https://www.tripo3d.ai) | جایگزین Meshy، اگه نتیجه خوب نبود | رایگان (محدود) |
| ☐ | [mixamo.com](https://www.mixamo.com) | اسکلت و انیمیشن سرباز | رایگان (اکانت Adobe) |
| ☐ | [ambientcg.com](https://ambientcg.com) | تکسچر (بتن، فلز، آسفالت) | رایگان، بدون ثبت‌نام |
| ☐ | [polyhaven.com](https://polyhaven.com) | آسمان (HDRI) | رایگان، بدون ثبت‌نام |
| ☐ | [freesound.org](https://freesound.org) | صداها | رایگان |
| ☐ | [game-icons.net](https://game-icons.net) | آیکون دکمه‌ها | رایگان، بدون ثبت‌نام |
| ☐ | [github.com](https://github.com) | آپلود فایل‌ها (اکانتش رو داری) | — |

### 💳 پیشنهاد خرید
**یک ماه Meshy Pro بگیر.** با نسخهٔ رایگان کل این لیست ساخته نمی‌شه. نسخهٔ Pro اعتبار خیلی بیشتری داره و مدل‌ها **مال خودت** می‌شن، پس مشکل لایسنس هم پیش نمیاد.
اول با نسخهٔ رایگان **یه سرباز** بساز. اگه کیفیتش رو پسندیدی، Pro بگیر.

### 📝 قانون‌های طلایی (همیشه رعایت کن)
1. **عکس یا اسم پابجی رو به هوش مصنوعی نده.** پرامپت‌های این فایل همه طرح خودمونن.
2. اسم اسلحه‌های واقعی (مثل AK یا M4) مشکلی نداره، چون اسلحهٔ واقعی‌ان. ولی همیشه بنویس `no logo, no text` تا لوگوی شرکتی روش نیاد.
3. اسم فایل رو **دقیقاً** همونی بذار که نوشتم، با حروف کوچیک انگلیسی.
4. منبع هر فایل رو توی `CREDITS.md` بنویس.

### ⚙️ تنظیمات Meshy (برای همهٔ مدل‌ها)

وقتی توی Meshy رفتی به **Text to 3D**:

| تنظیم | سرباز | اسلحه | وسایل مپ |
|---|---|---|---|
| Art Style | **Realistic** | **Realistic** | **Realistic** |
| Pose | **T-pose** | — | — |
| Target Polycount | **15,000** | **5,000** | **3,000** |
| Topology | Triangle | Triangle | Triangle |
| Texture | **PBR** روشن | **PBR** روشن | **PBR** روشن |
| Texture Resolution | 2048 | 1024 | 1024 |
| فرمت دانلود | **FBX** | **GLB** | **GLB** |

**Negative Prompt** (اگه این خونه بود، همیشه اینو بذار):
```
cartoon, anime, low poly, toy, blurry texture, extra limbs, extra fingers, deformed, text, logo, watermark
```

**روش کار با هر پرامپت:**
1. پرامپت رو کپی کن و **Generate** بزن.
2. از بین نتیجه‌ها، مدل رو **از همه طرف** بچرخون و بهترینش رو انتخاب کن.
3. **Texture** یا **Refine** رو بزن.
4. اگه بد بود، دوباره **Generate** بزن. اگه سه بار بد شد، توی **Tripo** امتحان کن.
5. **Download** با فرمتی که توی جدول بالا گفتم.

---

## مرحلهٔ ۱ — سربازها (۶ تا)

📁 **آپلود در:** `assets/characters/skins/`
📌 **مهم:** سرباز **نباید اسلحه دستش باشه**. اسلحه رو جدا می‌ذاریم. حتماً **T-pose** باشه (دست‌ها صاف به دو طرف).
📌 هر کدوم رو **جدا** بساز. اول فقط شمارهٔ ۱ رو بساز و بفرست تا کیفیتش رو تست کنیم.

### ✅ ۱. سرباز تیم آبی (پیش‌فرض) — `default_blue.glb`
> ✅ ساخته شد با API مال Meshy (اسکلت و انیمیشن هم با خود Meshy، نه Mixamo). فرمتش GLB شد چون Godot راحت‌تر می‌خونه.
>
> **روشی که طبیعی‌ترین نتیجه رو داد** (Text to 3D مستقیم، دست‌ها رو باز و پنجه‌ای می‌ساخت و چون اسکلت Meshy انگشت نداره، دست‌ها خشک می‌موند):
> 1. **Text to Image** (مدل `nano-banana-2`، `pose_mode: a-pose`) با پرامپت پایین → عکس واقعی از سرباز
> 2. **Image to 3D** از همون عکس (`enable_pbr`، ۳۰ هزار مثلث، `a-pose`)
> 3. **Rigging** و **Animation** خود Meshy، بعد `tools/meshy/merge_animations.py`
```
photorealistic full body photo of a male special forces soldier, 30 years old, realistic human face, natural skin, short dark military haircut, calm expression, standing straight in A-pose facing the camera, arms angled down at 45 degrees away from the body, both hands closed into relaxed fists with thumbs on the outside, palms facing the thighs, dark navy blue long sleeve combat uniform, black tactical plate carrier vest with magazine pouches, black tactical gloves, black combat boots, no weapon, no helmet, plain light grey studio background, even soft lighting, sharp focus, entire body visible from head to boots
```
> برای بقیهٔ سربازها فقط قسمت لباس و صورت رو عوض کن؛ «دست‌ها مشت، کف دست رو به ران، A-pose» رو نگه دار.

### ☐ ۲. سرباز تیم قرمز (پیش‌فرض) — `default_red.fbx`
```
realistic mercenary soldier, full body, standing in T-pose, arms straight out to the sides, dark red combat jacket, brown tactical chest rig with pouches, red bandana covering the face, black baseball cap, tactical gloves, brown combat boots, no weapon, empty hands, game character, highly detailed, PBR
```

### ☐ ۳. لباس «سایه» — `skin_shadow.fbx`
```
realistic stealth operator, full body, standing in T-pose, arms straight out to the sides, black hooded leather jacket, black tactical pants, white skull face mask, black fingerless gloves, black boots, no weapon, empty hands, game character, highly detailed, PBR
```

### ☐ ۴. لباس «صحرا» — `skin_desert.fbx`
```
realistic desert soldier, full body, standing in T-pose, arms straight out to the sides, tan desert camouflage uniform, khaki tactical vest, shemagh scarf around the neck, dark sunglasses, tan helmet, brown boots, no weapon, empty hands, game character, highly detailed, PBR
```

### ☐ ۵. لباس «شهری» — `skin_urban.fbx`
```
realistic urban fighter, full body, standing in T-pose, arms straight out to the sides, grey hoodie, dark blue jeans, black bulletproof vest, black gas mask, white sneakers, no weapon, empty hands, game character, highly detailed, PBR
```

### ☐ ۶. لباس «قطبی» — `skin_arctic.fbx`
```
realistic arctic soldier, full body, standing in T-pose, arms straight out to the sides, white and grey winter camouflage uniform, white padded jacket, white helmet, ski goggles, white gloves, white snow boots, no weapon, empty hands, game character, highly detailed, PBR
```

---

## مرحلهٔ ۲ — اسکلت‌گذاری در Mixamo

**برای هر ۶ سرباز این کار رو تکرار کن.**

1. برو به [mixamo.com](https://www.mixamo.com) و لاگین کن.
2. بالا سمت راست بزن **Upload Character** و فایل FBX سرباز رو بده.
3. صفحهٔ **Auto-Rigger** باز می‌شه. نقطه‌های رنگی رو بکش روی:
   - **Chin** (چونه)
   - **Wrists** (مچ هر دو دست)
   - **Elbows** (آرنج‌ها)
   - **Knees** (زانوها)
   - **Groin** (کشاله)
4. **Skeleton LOD** رو بذار روی **Standard Skeleton (65)**. بعد **Next** بزن و صبر کن.
5. وقتی سرباز تکون خورد، یعنی درست شده. **Next** بزن.
6. **بدون انتخاب انیمیشن**، بزن **Download**:
   - Format: **FBX Binary (.fbx)**
   - Skin: **With Skin**
   - Pose: **T-pose**
7. اسم فایل رو بذار مثل جدول مرحلهٔ ۱ (مثلاً `default_blue.fbx`). **این فایل جای فایل Meshy رو می‌گیره.**

> ❌ اگه Mixamo خطا داد (معمولاً به‌خاطر اینکه سرباز T-pose نبوده)، برگرد به Meshy و دوباره بساز.

---

## مرحلهٔ ۳ — انیمیشن‌ها (۱۸ تا)

📁 **آپلود در:** `assets/animations/`
📌 **فقط یه بار** و فقط با سرباز `default_blue` انجام بده. چون همهٔ سربازها از Mixamo اسکلت گرفتن، این انیمیشن‌ها روی **همه‌شون** کار می‌کنه.

**تنظیمات دانلود هر انیمیشن:**
- اگه گزینهٔ **In Place** بود، تیکش رو بزن ✅ (خیلی مهمه)
- Format: **FBX Binary (.fbx)**
- Skin: **Without Skin** ❗
- Frames per Second: **30**
- Keyframe Reduction: **none**

| ☐ | اسم فایل | توی Mixamo جستجو کن | کجا استفاده می‌شه |
|---|---|---|---|
| ☐ | `idle.fbx` | `Rifle Idle` | ایستادن |
| ☐ | `aim_idle.fbx` | `Rifle Aiming Idle` | ایستادن موقع اسکوپ |
| ☐ | `run.fbx` | `Rifle Run` | دویدن |
| ☐ | `sprint.fbx` | `Sprint` (با اسلحه) | دویدن سریع |
| ☐ | `walk_forward.fbx` | `Rifle Walk` (Forward) | راه رفتن به جلو |
| ☐ | `walk_back.fbx` | `Rifle Walk Backward` | عقب رفتن |
| ☐ | `strafe_left.fbx` | `Rifle Strafe Left` | رفتن به چپ |
| ☐ | `strafe_right.fbx` | `Rifle Strafe Right` | رفتن به راست |
| ☐ | `crouch_idle.fbx` | `Crouch Rifle Idle` یا `Crouching Idle` | نشسته |
| ☐ | `crouch_walk.fbx` | `Crouch Walk` (Rifle) | راه رفتن نشسته |
| ☐ | `prone_idle.fbx` | `Prone Idle` | درازکش (Prone) |
| ☐ | `prone_crawl.fbx` | `Prone Forward` یا `Crawl` | سینه‌خیز |
| ☐ | `jump.fbx` | `Rifle Jump` | پرش |
| ☐ | `fire.fbx` | `Firing Rifle` | شلیک |
| ☐ | `reload.fbx` | `Reloading` (Rifle) | خشاب عوض کردن |
| ☐ | `throw.fbx` | `Throw Grenade` | پرتاب نارنجک |
| ☐ | `hit.fbx` | `Hit Reaction` (Rifle) | تیر خوردن |
| ☐ | `death.fbx` | `Dying` یا `Death From Front Headshot` | مردن |

**انیمیشن‌های لابی** (این دو تا رو با **With Skin** نگیر، همون **Without Skin**):

| ☐ | اسم فایل | جستجو کن |
|---|---|---|
| ☐ | `lobby_idle.fbx` | `Standing Idle` یا `Looking Around` |
| ☐ | `lobby_pose.fbx` | `Salute` یا `Victory` یا `Pointing` |

> اگه اسم دقیق پیدا نشد، نزدیک‌ترینش رو بردار. فقط اسم فایل رو همونی بذار که توی جدوله.

---

## مرحلهٔ ۴ — اسلحه‌ها (۲۴ تا)

📁 **آپلود در:** `assets/weapons/`
📌 تنظیمات Meshy: **Realistic**، **5,000** مثلث، **PBR**، دانلود **GLB**.
📌 هر کدوم رو **جدا** بساز.
📌 اولویت با ⭐ هاست. اول اون‌ها رو بساز.

### 🔫 تفنگ‌های تهاجمی (Assault Rifle)

#### ☐ ⭐ M416 — `m416.glb`
```
realistic HK416 style assault rifle, black metal and polymer, picatinny rails, adjustable stock, no attachments, no scope, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ ⭐ AKM — `akm.glb`
```
realistic AKM assault rifle, wooden stock and handguard, black stamped steel receiver, curved magazine, no scope, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ ⭐ SCAR-L — `scar.glb`
```
realistic SCAR-L style assault rifle, tan color, folding stock, top rail, no scope, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ M16A4 — `m16.glb`
```
realistic M16A4 assault rifle, black, fixed stock, carry handle rail, no scope, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ Beryl M762 — `beryl.glb`
```
realistic Beryl M762 style assault rifle, black polymer, AK style curved magazine, side folding stock, no scope, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ AUG — `aug.glb`
```
realistic Steyr AUG style bullpup assault rifle, green polymer body, integrated grip, no scope, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

### 🔫 مسلسل دستی (SMG)

#### ☐ ⭐ UMP45 — `ump45.glb`
```
realistic UMP45 style submachine gun, black polymer, folding stock, straight magazine, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ ⭐ Vector — `vector.glb`
```
realistic KRISS Vector style submachine gun, black, futuristic angular body, folding stock, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ Uzi — `uzi.glb`
```
realistic Micro Uzi submachine gun, black metal, folding wire stock, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ MP5K — `mp5k.glb`
```
realistic MP5K compact submachine gun, black, front vertical grip, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ Tommy Gun — `tommy.glb`
```
realistic Thompson submachine gun, wooden stock and grips, drum magazine, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

### 🎯 تک‌تیرانداز (Sniper)

#### ☐ ⭐ Kar98k — `kar98k.glb`
```
realistic Karabiner 98k bolt action rifle, long wooden stock, bolt handle, iron sights, no scope, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ ⭐ AWM — `awm.glb`
```
realistic AWM style bolt action sniper rifle, olive green body, thumbhole stock, long barrel with muzzle brake, no scope, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ M24 — `m24.glb`
```
realistic M24 bolt action sniper rifle, dark green synthetic stock, long heavy barrel, no scope, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

### 🎯 نیمه‌خودکار دوربردی (DMR)

#### ☐ ⭐ SKS — `sks.glb`
```
realistic SKS semi-automatic rifle, wooden stock, folding bayonet, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ Mini-14 — `mini14.glb`
```
realistic Mini-14 semi-automatic rifle, black synthetic stock, short magazine, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ SLR — `slr.glb`
```
realistic FN FAL style battle rifle, black, wooden handguard, long barrel, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

### 💥 شاتگان (Shotgun)

#### ☐ ⭐ S12K — `s12k.glb`
```
realistic Saiga-12 style semi-automatic shotgun, black, AK style body, box magazine, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ S1897 — `s1897.glb`
```
realistic Winchester 1897 style pump action shotgun, wooden stock and pump, long barrel, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

### 🔥 مسلسل سنگین (LMG)

#### ☐ M249 — `m249.glb`
```
realistic M249 light machine gun, black, box ammo magazine, bipod folded, carry handle, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ DP-28 — `dp28.glb`
```
realistic DP-28 light machine gun, wooden stock, flat pan magazine on top, bipod, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

### 🔫 کلت (Pistol)

#### ☐ ⭐ P92 — `p92.glb`
```
realistic Beretta 92 style semi-automatic pistol, black, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ P1911 — `p1911.glb`
```
realistic M1911 style pistol, silver steel slide, black grips, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

#### ☐ Desert Eagle — `deagle.glb`
```
realistic Desert Eagle style large pistol, chrome silver, side view, isolated on white background, no logo, no text, game weapon asset, highly detailed, PBR
```

---

## مرحلهٔ ۵ — قطعات اسلحه (Attachment)

📁 **آپلود در:** `assets/weapons/attachments/`
📌 تنظیمات: **Realistic**، **2,000** مثلث، **PBR**، **GLB**.

### دوربین‌ها (Scope)

#### ☐ ⭐ ردات — `scope_reddot.glb`
```
realistic red dot sight for rifle, black metal, small, picatinny mount, isolated on white background, no logo, no text, game asset, PBR
```

#### ☐ ⭐ هولوگرافیک — `scope_holo.glb`
```
realistic holographic weapon sight, black, rectangular window, picatinny mount, isolated on white background, no logo, no text, game asset, PBR
```

#### ☐ ⭐ دوربین ۲ برابر — `scope_2x.glb`
```
realistic 2x magnification compact rifle scope, black, picatinny mount, isolated on white background, no logo, no text, game asset, PBR
```

#### ☐ ⭐ دوربین ۴ برابر — `scope_4x.glb`
```
realistic 4x ACOG style rifle scope, black, picatinny mount, isolated on white background, no logo, no text, game asset, PBR
```

#### ☐ دوربین ۶ برابر — `scope_6x.glb`
```
realistic 6x magnification tactical rifle scope, black, picatinny mount, isolated on white background, no logo, no text, game asset, PBR
```

#### ☐ ⭐ دوربین ۸ برابر — `scope_8x.glb`
```
realistic 8x long range sniper scope, black, large objective lens, picatinny mount, isolated on white background, no logo, no text, game asset, PBR
```

### سر لوله (Muzzle)

#### ☐ ⭐ صدا‌خفه‌کن — `suppressor.glb`
```
realistic rifle suppressor silencer, black metal cylinder, isolated on white background, no logo, no text, game asset, PBR
```

#### ☐ کامپنساتور — `compensator.glb`
```
realistic rifle muzzle compensator, black metal with side ports, isolated on white background, no logo, no text, game asset, PBR
```

#### ☐ فلش‌هایدر — `flash_hider.glb`
```
realistic rifle flash hider, black metal with slots, isolated on white background, no logo, no text, game asset, PBR
```

### دسته و خشاب

#### ☐ ⭐ دستهٔ عمودی — `grip_vertical.glb`
```
realistic vertical foregrip for rifle, black polymer, picatinny mount, isolated on white background, no logo, no text, game asset, PBR
```

#### ☐ دستهٔ زاویه‌دار — `grip_angled.glb`
```
realistic angled foregrip for rifle, black polymer, picatinny mount, isolated on white background, no logo, no text, game asset, PBR
```

#### ☐ ⭐ خشاب بزرگ — `mag_extended.glb`
```
realistic extended rifle magazine, black polymer, long curved, isolated on white background, no logo, no text, game asset, PBR
```

---

## مرحلهٔ ۶ — نارنجک‌ها

📁 **آپلود در:** `assets/weapons/throwables/`
📌 تنظیمات: **Realistic**، **1,500** مثلث، **PBR**، **GLB**.

#### ☐ ⭐ نارنجک انفجاری — `frag.glb`
```
realistic military frag hand grenade, olive green, metal pin and lever, isolated on white background, no logo, no text, game asset, PBR
```

#### ☐ ⭐ نارنجک دودزا — `smoke.glb`
```
realistic military smoke grenade, cylindrical, grey with green band, pin and lever, isolated on white background, no logo, no text, game asset, PBR
```

#### ☐ نارنجک فلش — `flash.glb`
```
realistic military flashbang stun grenade, black cylinder with holes, pin and lever, isolated on white background, no logo, no text, game asset, PBR
```

#### ☐ کوکتل مولوتف — `molotov.glb`
```
realistic molotov cocktail, glass bottle with cloth rag, isolated on white background, no logo, no text, game asset, PBR
```

---

## مرحلهٔ ۷ — محیط جنگ (مپ)

مپ رو **خودم** از تیکه‌هایی که تو میاری می‌سازم. اندازه‌اش **۵۶ × ۴۴ متره** و حالت بازی ۵ در برابر ۵ هست.

### الف) وسایل مپ

📁 **آپلود در:** `assets/maps/warehouse/props/`
📌 تنظیمات: **Realistic**، **3,000** مثلث، **PBR**، **GLB**.

#### ☐ ⭐ کانتینر — `container.glb`
```
realistic 20ft shipping container, corrugated steel walls, closed doors with locking bars, slightly rusty, blue paint, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ ⭐ صندوق چوبی — `crate_wood.glb`
```
realistic wooden shipping crate, nailed planks, cube shape, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ ⭐ صندوق فلزی نظامی — `crate_metal.glb`
```
realistic military metal ammo crate, olive green, latches and handles, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ ⭐ بشکه — `barrel.glb`
```
realistic rusty blue steel oil barrel, 200 liter drum, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ ⭐ مانع بتنی — `barrier.glb`
```
realistic concrete jersey barrier with yellow and black hazard stripes, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ ⭐ کیسه شن — `sandbags.glb`
```
realistic military sandbag wall, stacked burlap sandbags, low cover, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ پالت چوبی — `pallet_stack.glb`
```
realistic stack of wooden pallets, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ لیفتراک — `forklift.glb`
```
realistic yellow warehouse forklift, old and dirty, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ قفسهٔ انبار — `shelf.glb`
```
realistic industrial warehouse metal shelving rack with cardboard boxes, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ کامیون نظامی — `truck.glb`
```
realistic old military cargo truck, olive green, canvas cover, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ ستون فلزی — `pillar.glb`
```
realistic steel I-beam support pillar with concrete base, industrial, tall, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ پلهٔ فلزی — `stairs.glb`
```
realistic industrial metal staircase with railing, warehouse, isolated, no logo, no text, game environment asset, PBR
```

### ب) تکسچرها

📁 **آپلود در:** `assets/maps/warehouse/textures/<اسم پوشه>/`
📌 از [ambientcg.com](https://ambientcg.com) ← تکسچر رو جستجو کن ← دانلود **2K-JPG** ← zip رو باز کن ← **فقط این ۳ فایل** رو آپلود کن:
`..._Color.jpg` و `..._NormalGL.jpg` و `..._Roughness.jpg`

| ☐ | اسم پوشه | توی سایت جستجو کن | کجا |
|---|---|---|---|
| ☐ ⭐ | `concrete_floor` | `Concrete` (خاکستری تیره) | کف انبار |
| ☐ ⭐ | `concrete_wall` | `Concrete` (روشن) | دیوارها |
| ☐ ⭐ | `metal_corrugated` | `CorrugatedSteel` | دیوار فلزی |
| ☐ | `metal_rust` | `Rust` | زنگ‌زدگی |
| ☐ | `asphalt` | `Asphalt` | زمین بیرون |
| ☐ | `metal_painted` | `PaintedMetal` | در و پنجره |
| ☐ | `brick` | `Bricks` | دیوار آجری |

### ج) آسمان

📁 **آپلود در:** `assets/maps/warehouse/`
- ☐ ⭐ از [polyhaven.com/hdris](https://polyhaven.com/hdris) ← دسته **Outdoor** ← یه آسمان **روز آفتابی** ← دانلود **2K** ← فرمت **HDR** ← اسمش رو بذار `sky.hdr`

---

## مرحلهٔ ۸ — محیط لابی

📁 **آپلود در:** `assets/lobby/`
📌 لابی جاییه که سربازت وسط صفحه وایساده. **آشیانهٔ نظامی** (Hangar) پیشنهاد منه.
📌 تنظیمات: **Realistic**، **8,000** مثلث، **PBR**، **GLB**.

#### ☐ ⭐ هلی‌کوپتر — `helicopter.glb`
```
realistic military transport helicopter, parked, dark green, rotors stopped, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ ⭐ جیپ نظامی — `jeep.glb`
```
realistic military off-road jeep, dark green, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ ⭐ سکوی نمایش — `platform.glb`
```
round futuristic metal display platform with glowing blue light ring, sci-fi military style, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ تودهٔ صندوق — `crates_pile.glb`
```
realistic pile of military supply crates and ammo boxes with a camouflage net, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ موتور — `motorbike.glb`
```
realistic military dirt motorbike, olive green, isolated, no logo, no text, game environment asset, PBR
```

#### ☐ میز سلاح — `weapon_rack.glb`
```
realistic military weapon rack on the wall with empty slots, metal, isolated, no logo, no text, game environment asset, PBR
```

- ☐ ⭐ **آسمان لابی:** از [polyhaven.com/hdris](https://polyhaven.com/hdris) ← یه آسمان **غروب** یا **شب** ← **2K HDR** ← اسمش رو بذار `lobby_sky.hdr`

---

## مرحلهٔ ۹ — صداها

📁 **آپلود در:** `assets/sounds/`
📌 از [freesound.org](https://freesound.org) ← بعد از جستجو، فیلتر **License** رو بذار روی **Creative Commons 0** ← دانلود.
📌 فرمت **WAV** یا **OGG**، هر کدوم **کمتر از ۵ ثانیه** (به‌جز موسیقی).
📌 بستهٔ کامل‌تر: [sonniss.com/gameaudiogdc](https://sonniss.com/gameaudiogdc). صدای خیلی حرفه‌ای داره، رایگان و قانونی.

### صدای اسلحه‌ها

| ☐ | اسم فایل | جستجو کن |
|---|---|---|
| ☐ ⭐ | `shot_ar.wav` | `assault rifle shot` |
| ☐ ⭐ | `shot_ak.wav` | `ak47 shot` |
| ☐ ⭐ | `shot_smg.wav` | `smg shot` |
| ☐ ⭐ | `shot_sniper.wav` | `sniper rifle shot` |
| ☐ | `shot_shotgun.wav` | `shotgun shot` |
| ☐ | `shot_lmg.wav` | `machine gun shot` |
| ☐ ⭐ | `shot_pistol.wav` | `pistol shot` |
| ☐ ⭐ | `shot_suppressed.wav` | `silenced gun shot` |
| ☐ ⭐ | `reload_rifle.wav` | `rifle reload` |
| ☐ | `reload_pistol.wav` | `pistol reload` |
| ☐ | `bolt_action.wav` | `bolt action` |
| ☐ | `empty_click.wav` | `gun dry fire` |
| ☐ | `shell_drop.wav` | `bullet casing drop` |

### صدای بازی

| ☐ | اسم فایل | جستجو کن |
|---|---|---|
| ☐ ⭐ | `footstep_1.wav` | `footstep concrete` |
| ☐ ⭐ | `footstep_2.wav` | `footstep concrete` (یه صدای دیگه) |
| ☐ | `footstep_metal.wav` | `footstep metal` |
| ☐ ⭐ | `hit_body.wav` | `bullet impact flesh` |
| ☐ ⭐ | `hit_headshot.wav` | `helmet hit` / `headshot` |
| ☐ | `bullet_concrete.wav` | `bullet impact concrete` |
| ☐ | `bullet_metal.wav` | `bullet impact metal` |
| ☐ | `jump_land.wav` | `jump landing` |
| ☐ | `grenade_explosion.wav` | `grenade explosion` |
| ☐ | `grenade_pin.wav` | `grenade pin pull` |
| ☐ | `smoke_hiss.wav` | `smoke grenade hiss` |

### صدای منو و پیام‌ها

| ☐ | اسم فایل | جستجو کن |
|---|---|---|
| ☐ ⭐ | `kill.wav` | `kill confirm` / `ui success` |
| ☐ | `button_click.wav` | `ui click` |
| ☐ | `match_start.wav` | `match start` / `horn` |
| ☐ | `match_win.wav` | `victory fanfare` |
| ☐ | `match_lose.wav` | `defeat` |
| ☐ | `countdown.wav` | `countdown beep` |
| ☐ ⭐ | `lobby_music.ogg` | `epic military music` یا `action music loop` (۱ تا ۳ دقیقه) |
| ☐ | `match_music.ogg` | `tense action music loop` |

---

## مرحلهٔ ۱۰ — لوگو، آیکون و ظاهر

📁 **آپلود در:** `assets/ui/`

### لوگو و آیکون برنامه (با هوش مصنوعی عکس‌ساز)

با **ChatGPT** (ساخت عکس)، **Bing Image Creator** یا **Leonardo.ai** بساز:

#### ☐ ⭐ لوگوی بازی — `logo.png` (1024×1024، پس‌زمینهٔ شفاف)
```
esports style game logo with the text "KANKI", military theme, crosshair symbol, gold and black colors, sharp metallic letters, centered, transparent background, high quality vector style
```

#### ☐ ⭐ آیکون برنامه — `app_icon.png` (512×512، مربعی)
```
mobile game app icon, masked special forces soldier helmet with goggles, dark background, gold rim light, letter K, bold, high detail, square, no text other than K
```

#### ☐ عکس پس‌زمینهٔ بارگذاری — `loading.png` (1920×1080)
```
cinematic wide shot of special forces soldiers in a dark warehouse with shipping containers, dramatic light beams, dust, realistic, high detail, no text
```

### آیکون دکمه‌ها

از [game-icons.net](https://game-icons.net) ← آیکون رو جستجو کن ← رنگ پس‌زمینه رو **Transparent** و رنگ آیکون رو **سفید** بذار ← دانلود **PNG** با اندازهٔ **512**.

| ☐ | اسم فایل | جستجو کن |
|---|---|---|
| ☐ ⭐ | `icon_fire.png` | `bullets` |
| ☐ ⭐ | `icon_aim.png` | `crosshair` |
| ☐ ⭐ | `icon_jump.png` | `jump` |
| ☐ ⭐ | `icon_crouch.png` | `crouch` |
| ☐ | `icon_prone.png` | `crawl` |
| ☐ ⭐ | `icon_reload.png` | `reload` |
| ☐ | `icon_grenade.png` | `grenade` |
| ☐ | `icon_settings.png` | `cog` |
| ☐ | `icon_scoreboard.png` | `podium` |
| ☐ | `icon_kill.png` | `skull` |

---

## مرحلهٔ ۱۱ — آپلود و تحویل

### روش آپلود
1. برو به [github.com/kankiturk8770/Kanki-pubg](https://github.com/kankiturk8770/Kanki-pubg)
2. بزن **Add file ← Upload files**.
3. فایل‌ها رو بکش توی صفحه.
4. برای ساختن پوشه، اسم فایل رو این‌جوری بنویس: `assets/weapons/m416.glb`. GitHub خودش پوشه‌ها رو می‌سازه.
   **راه ساده‌تر:** همه رو یه جا آپلود کن و به من بگو. خودم می‌برمشون توی پوشهٔ درست.
5. پایین صفحه بزن **Commit changes**.

📌 هر فایل حداکثر **۲۵ مگابایت**. اگه بزرگ‌تر بود، به من بگو.

### ترتیب پیشنهادی تحویل

| بسته | چی | بعدش من چی کار می‌کنم |
|---|---|---|
| **بستهٔ ۱** | سرباز `default_blue` + انیمیشن‌های `idle`، `run`، `fire`، `death` | تست کیفیت توی بازی |
| **بستهٔ ۲** | بقیهٔ انیمیشن‌ها + `default_red` | هر دو تیم با انیمیشن کامل |
| **بستهٔ ۳** | اسلحه‌های ⭐ + صداهای ⭐ | چند اسلحه و انتخاب اسلحه |
| **بستهٔ ۴** | تکسچرها + آسمان + وسایل مپ ⭐ | مپ واقعی |
| **بستهٔ ۵** | لابی + لوگو + آیکون‌ها | لابی و ظاهر نهایی |
| **بستهٔ ۶** | بقیهٔ لباس‌ها، اسلحه‌ها، قطعات و نارنجک‌ها | فروشگاه لباس، Attachment، نارنجک |

---

## کارهای من (بعد از تحویل)

این‌ها کار منه. تو لازم نیست کاری بکنی:

- [ ] وصل کردن سربازها و انیمیشن‌ها به بازی
- [ ] **ثبت‌نام و ورود اختصاصی خود بازی** (نام کاربری + رمز). اطلاعات روی **سرور خودمون** ذخیره می‌شه، نه گوگل یا جای دیگه
- [ ] پروفایل بازیکن: آمار کیل، مرگ، برد و K/D
- [ ] انتخاب اسلحه قبل از بازی و اسلحهٔ دوم
- [ ] دوربین اسکوپ (۲x، ۴x، ۸x) و قطعات اسلحه
- [ ] نارنجک
- [ ] حالت درازکش (Prone)
- [ ] بخش لباس‌ها (Inventory) برای انتخاب Skin
- [ ] مپ جدید با وسایل و تکسچرهای واقعی
- [ ] لابی جدید با هلی‌کوپتر و جیپ
- [ ] صداهای واقعی و موسیقی
- [ ] لوگو و آیکون برنامه روی گوشی
