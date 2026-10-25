# Mixamo (با گوشی)

این پوشه برای فایل‌هاییه که بین ما و Mixamo رد و بدل می‌شن (Godot این پوشه رو نادیده می‌گیره).

`male_upload.fbx` و `female_upload.fbx` **از قبل اسکلت Mixamo دارن** (۶۵ استخوان، با انگشت‌ها)،
پس صفحهٔ دایره‌ها (Auto-Rigger) **نمیاد**. ساخته‌شده با `tools/mixamo/make_mixamo_rig.py`.

## ۱. آپلود (برای هر دو فایل)

1. کروم ← `mixamo.com` ← منوی سه‌نقطه ← **Desktop site** ← گوشی **افقی**.
2. **UPLOAD CHARACTER** ← فایل `male_upload.fbx` رو بده.
3. باید مستقیم سرباز رو نشون بده (بدون دایره‌ها) ← **NEXT** / **CLOSE**.

## ۲. دانلود انیمیشن‌ها

هر انیمیشن: توی جستجو اسمش رو بزن ← روش بزن ← اگه **In Place** بود تیکش رو بزن ← **DOWNLOAD**:
- Format: **FBX Binary (.fbx)** · Skin: **Without Skin** · Frames per second: **30** · Keyframe Reduction: **none**

| اسم فایل | جستجو کن |
|---|---|
| `rifle_idle.fbx` | Rifle Idle |
| `rifle_aim.fbx` | Rifle Aiming Idle |
| `rifle_run.fbx` | Rifle Run |
| `rifle_sprint.fbx` | Sprint (rifle) |
| `rifle_walk_back.fbx` | Rifle Walk Backward |
| `rifle_strafe_left.fbx` | Rifle Strafe Left |
| `rifle_strafe_right.fbx` | Rifle Strafe Right |
| `rifle_crouch_idle.fbx` | Crouch Rifle Idle |
| `rifle_crouch_walk.fbx` | Crouch Walk (rifle) |
| `rifle_jump.fbx` | Rifle Jump |
| `rifle_fire.fbx` | Firing Rifle |
| `rifle_reload.fbx` | Reloading |
| `rifle_hit.fbx` | Hit Reaction (rifle) |
| `rifle_death.fbx` | Dying |
| `lobby_idle.fbx` | Standing Idle |

> انیمیشن‌ها رو **فقط با یکی** (مثلاً مرد) بگیر. چون اسکلت هر دو یکیه، روی زن هم کار می‌کنه.
> اسم فایل مهم نیست؛ اگه نتونستی عوضش کنی، فقط بگو کدوم فایل کدوم انیمیشنه.

## ۳. فرستادن

فایل‌های دانلودشده رو همین‌جا توی چت بفرست (یا توی همین پوشه آپلود کن).

## ساختن کاراکترهای بازی از این فایل‌ها (کار من)

- `anims/` = انیمیشن‌هایی که از Mixamo دانلود شده (برای مرد؛ روی زن هم اعمال می‌شه).
- کدوم فایل اسمش توی بازی چیه: `tools/mixamo/clips.txt`
- ساختن (با Blender پایتونی، `pip install bpy`):
```
python tools/mixamo/build_character.py mixamo/male_upload.fbx mixamo/anims male.glb $(cat tools/mixamo/clips.txt)
python3 tools/meshy/prepare_model.py --keep-normal-map --max-texture=2048 male.glb assets/characters/skins/male.glb
python3 tools/meshy/make_team_texture.py assets/characters/skins/male.glb assets/characters/team_colors/male_red.jpg
```
(برای زن همین‌ها با `female`.)

بعدش (و هر بار که کاراکتر یا اسلحه عوض شد) دست‌ها رو روی اسلحه‌ها جا بنداز:
```
godot --headless --path . --script tools/fit_grips.gd
```
این `scripts/grip_data.gd` رو می‌سازه: جای قبضه توی کف دست راست، جای دست چپ زیر روکش لوله،
و اینکه هر بند انگشت چقدر خم بشه تا روی بدنهٔ واقعی اسلحه بشینه (نه توش بره، نه توی هوا بمونه).
انگشت‌های انیمیشن‌های Mixamo استفاده نمی‌شن؛ `scripts/hand_grip.gd` توی بازی خودش انگشت‌ها رو می‌بنده.

## انیمیشن‌هایی که هنوز لازمه (دفعهٔ بعد)

✅ گرفته شد: Rifle Idle، Rifle Aiming Idle، Firing Rifle، Death From The Front، Rifle Turn، Throw Grenade (درازکش).

| جستجو کن | برای |
|---|---|
| Rifle Run | دویدن با اسلحه (الان پاهای دویدن معمولی + دست‌های اسلحه) |
| Rifle Jump | پرش |
| Toss Grenade | پرتاب نارنجک ایستاده |

## دانلود خودکار با گوشی (بوکمارک)

`bookmarklet.txt` = نسخهٔ کوچیک‌شدهٔ `tools/mixamo/mixamo_download.js`
(بر پایهٔ اسکریپت DownloadMixamo از Jake Cattrall). فقط انیمیشن‌های لیست `WANTED`
توی همون فایل رو دانلود می‌کنه، بسته‌ها و بقیه رو رد می‌کنه، و پیشرفت رو توی یه کادر زرد بالای صفحه نشون می‌ده.

1. محتوای `bookmarklet.txt` رو کامل کپی کن (Select all ← Copy).
2. کروم: یه صفحه رو بوکمارک کن (⋮ ← ☆). بعد ⋮ ← Bookmarks ← روی همون بوکمارک انگشت نگه دار ← **Edit**:
   - Name: `kanki` · URL: متن کپی‌شده رو جایگزین کن ← ذخیره.
3. `mixamo.com` (Desktop site) ← تب **Animations** ← بالای صفحه باید **MALE_UPLOAD** باشه ← جستجو خالی.
4. روی نوار آدرس بزن، بنویس `kanki` و **پیشنهادی که ستاره (بوکمارک) داره** رو بزن.
5. کادر زرد میاد. اگه کروم پرسید «چند فایل دانلود بشه؟» ← **Allow**. صفحه رو روشن نگه دار تا تموم بشه (STOP برای توقف).
6. فایل‌های دانلودشده رو بفرست.

### اگه کادر زرد نیومد

- **تست:** یه بوکمارک دیگه با URL `javascript:alert('Kanki OK')` (فایل `test_bookmark.txt`) بساز و روی Mixamo همون‌طوری اجراش کن.
  اگه پیغام نیومد، کروم روی این سایت بوکمارک‌های اسکریپتی رو اجرا نمی‌کنه.
- **راه مطمئن‌تر: Firefox + Violentmonkey** (روی اندروید کار می‌کنه):
  1. Firefox رو از Play Store نصب کن ← ⋮ ← **Extensions** ← **Violentmonkey** رو اضافه کن.
  2. توی Firefox فایل `mixamo/kanki_mixamo.user.js` رو از GitHub باز کن و دکمهٔ **Raw** رو بزن ← Violentmonkey صفحهٔ نصب رو باز می‌کنه ← **Install**.
  3. `mixamo.com` (Desktop site) ← تب Animations ← MALE_UPLOAD ← پایین-راست دکمهٔ زرد **▶ KANKI** رو بزن.
