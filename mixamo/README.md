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
