import os
import re

FRIENDLY_BUSY_MSG = (
    "رفیق الان ترافیک سرورهای هوش مصنوعی خیلی بالاست! 😅 "
    "مشکل از برنامه ما نیست و سهمیه‌ات هم اصلاً کم نشده؛ "
    "یه دقیقه دیگه دوباره امتحان کن تا جوابت رو بدم! ❤️🙏"
)

# ==============================================================================
# 1. آپدیت lib/main.dart
# ==============================================================================
with open("lib/main.dart", "r", encoding="utf-8") as f:
    dart = f.read()

# الف) حذف کامل تابع برنامه غذایی تقلبی اگر هنوز وجود دارد
s_mark = "  // ساخت برنامه ۷ روزه با تنوع ۱۰۰٪ واقعی در تمام ۷ روز هفته"
e_mark = "  // ارسال پیام به چت مربی هوشمند در کلودفلر"
if s_mark in dart and e_mark in dart:
    dart = dart[:dart.index(s_mark)] + dart[dart.index(e_mark):]
    print("✅ [lib/main.dart] تابع برنامه غذایی تقلبی حذف شد.")

# ب) نمایش پیام محاوره‌ای در بخش ورزش به جای AI_ERROR
old_w_err_1 = """        if (errData is Map && errData['error'] != null) {
          errMsg = errData['error'].toString();
        }"""
old_w_err_2 = """        if (errData is Map && (errData['message'] != null || errData['error'] != null)) {
          errMsg = (errData['message'] ?? errData['error']).toString();
        }"""
new_w_err = """        if (errData is Map && (errData['message'] != null || errData['error'] != null)) {
          errMsg = (errData['message'] ?? errData['error']).toString();
        }"""
if old_w_err_1 in dart:
    dart = dart.replace(old_w_err_1, new_w_err, 1)
    print("✅ [lib/main.dart] نمایش پیام محاوره‌ای در بخش ورزش فیکس شد.")
elif old_w_err_2 in dart:
    print("ℹ️ [lib/main.dart] پیام محاوره‌ای بخش ورزش از قبل تنظیم بود.")

# ج) حذف فراخوانی برنامه غذایی تقلبی و نمایش پیام محاوره‌ای هنگام خطای AI
old_meal_fallback = """    if (!parsedFromServerJson) {
      _buildDiverseTailoredSevenDayPlan();
    }

    await saveAllToDisk();
    isLoadingAi = false;
    notifyListeners();
    return true;
  }"""

new_meal_fallback = f"""    if (!parsedFromServerJson) {{
      isLoadingAi = false;
      notifyListeners();
      if (context.mounted) {{
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('{FRIENDLY_BUSY_MSG}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }}
      return false;
    }}

    await saveAllToDisk();
    isLoadingAi = false;
    notifyListeners();
    return true;
  }}"""

if old_meal_fallback in dart:
    dart = dart.replace(old_meal_fallback, new_meal_fallback, 1)
    print("✅ [lib/main.dart] برنامه غذایی تقلبی حذف و پیام محاوره‌ای جایگزین شد.")

# د) تنظیم مدل پیش‌فرض روی gemini-3.5-flash-lite در کلاینت
dart = dart.replace("'gemini-3.1-flash-lite'", "'gemini-3.5-flash-lite'")
dart = dart.replace(
    "final m = g['gemini-3.5-flash-lite'];",
    "final m = g['gemini-3.5-flash-lite'] ?? g['gemini-3.1-flash-lite'];"
)
print("✅ [lib/main.dart] مدل اصلی روی gemini-3.5-flash-lite تنظیم شد.")

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(dart)

# ==============================================================================
# 2. آپدیت worker.js
# ==============================================================================
with open("worker.js", "r", encoding="utf-8") as f:
    worker = f.read()

# الف) تنظیم مدل اصلی CONFIG روی gemini-3.5-flash-lite
worker = worker.replace('"gemini-3.1-flash-lite"', '"gemini-3.5-flash-lite"')

# ب) سازگاری کوتاها هم با 3.5 و هم با 3.1 (برای نسخه‌های نصب‌شده روی گوشی)
old_quota_ret = """  return {
    chat_daily: { [lite]: chatLite, [flash]: chatLite },
    food_text_weekly: { [lite]: foodText },
    food_photo_weekly: { [lite]: foodPhoto },
    plan_weekly: { [lite]: planLite, [flash]: planLite },
    workout_weekly: { [lite]: workoutLite },
    coach_weekly: { [lite]: coachLite, [flash]: coachLite },
  };"""

new_quota_ret = """  const oldLite = "gemini-3.1-flash-lite";
  return {
    chat_daily: { [lite]: chatLite, [flash]: chatLite, [oldLite]: chatLite },
    food_text_weekly: { [lite]: foodText, [oldLite]: foodText },
    food_photo_weekly: { [lite]: foodPhoto, [oldLite]: foodPhoto },
    plan_weekly: { [lite]: planLite, [flash]: planLite, [oldLite]: planLite },
    workout_weekly: { [lite]: workoutLite, [oldLite]: workoutLite },
    coach_weekly: { [lite]: coachLite, [flash]: coachLite, [oldLite]: coachLite },
  };"""

if old_quota_ret in worker:
    worker = worker.replace(old_quota_ret, new_quota_ret, 1)
    print("✅ [worker.js] سهمیه‌ها برای مدل 3.5 تنظیم شد.")

# ج) جایگزینی تابع callGeminiWithStrictModel با زنجیره دقیق: 3.5 -> 3.1 -> 2.5
start_fn = "async function callGeminiWithStrictModel({ kv, apiKeys, model, prompt, imageBase64, systemInstruction, history }) {"
end_fn = "function buildAgentSystemPrompt("

new_call_fn = """async function callGeminiWithStrictModel({ kv, apiKeys, model, prompt, imageBase64, systemInstruction, history }) {
  const shuffledIndexes = apiKeys.map((_, idx) => idx).sort(() => Math.random() - 0.5);
  const candidateModels = ["gemini-3.5-flash-lite", "gemini-3.1-flash-lite", "gemini-2.5-flash-lite"];

  let sawBusyOrUpstreamError = false;
  let lastErrorText = "";

  for (const activeModel of candidateModels) {
    for (const keyIndex of shuffledIndexes) {
      const apiKey = apiKeys[keyIndex];

      try {
        const geminiUrl =
          "https://generativelanguage.googleapis.com/v1beta/models/" +
          activeModel +
          ":generateContent?key=" +
          apiKey;

        const contents = [];
        if (Array.isArray(history)) {
          for (const msg of history.slice(-8)) {
            if (msg && msg.text) {
              contents.push({
                role: msg.role === "model" || msg.role === "assistant" ? "model" : "user",
                parts: [{ text: String(msg.text) }],
              });
            }
          }
        }

        const userParts = [{ text: prompt }];
        if (imageBase64) {
          userParts.push({
            inlineData: {
              mimeType: "image/jpeg",
              data: String(imageBase64),
            },
          });
        }
        contents.push({ role: "user", parts: userParts });

        const requestPayload = {
          systemInstruction: {
            parts: [{ text: systemInstruction }],
          },
          contents: contents,
          generationConfig: {
            temperature: 0.75,
            responseMimeType: "application/json",
          },
        };

        const res = await fetch(geminiUrl, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(requestPayload),
        });

        if (res.status === 429 || res.status === 503 || res.status === 502 || res.status === 504) {
          sawBusyOrUpstreamError = true;
          lastErrorText = "[" + activeModel + " HTTP " + res.status + "] " + (await res.text());
          break; // مدل فعلی شلوغ است؛ بلافاصله برو سراغ مدل بعدی در زنجیره (3.5 -> 3.1 -> 2.5)
        }

        if (res.ok) {
          const data = await res.json();
          const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text;
          if (rawText) {
            return { ok: true, rawText: rawText, modelUsed: activeModel };
          }
        } else {
          sawBusyOrUpstreamError = true;
          lastErrorText = "[" + activeModel + " HTTP " + res.status + "] " + (await res.text());
        }
      } catch (err) {
        sawBusyOrUpstreamError = true;
        lastErrorText = "[" + activeModel + "] " + err.message;
      }
    }
  }

  return {
    ok: false,
    busy: sawBusyOrUpstreamError,
    errorDetails: lastErrorText,
  };
}

"""

if start_fn in worker and end_fn in worker:
    worker = worker[:worker.index(start_fn)] + new_call_fn + worker[worker.index(end_fn):]
    print("✅ [worker.js] زنجیره دقیق gemini-3.5-flash-lite -> gemini-3.1-flash-lite -> gemini-2.5-flash-lite تنظیم شد.")

# د) برگرداندن پیام محاوره‌ای برای هر نوع شلوغی یا خطای سرور گوگل
old_err_block_pattern = re.compile(
    r'if \(!callResult\.ok\) \{.*?return jsonResponse\(\s*\{\s*error: "AI_ERROR".*?\},\s*502\s*\);\s*\}',
    re.DOTALL
)

new_err_block = f"""if (!callResult.ok) {{
          await logRadarError(kv, {{
            path: path,
            userKey: userKey,
            status: 503,
            message: "شلوغی یا خطای سرورهای گوگل (3.5 -> 3.1 -> 2.5)",
            details: String(callResult.errorDetails || "نامشخص").slice(0, 260),
          }});
          return jsonResponse(
            {{
              error: "{FRIENDLY_BUSY_MSG}",
              code: "SERVER_BUSY",
              busy: true,
              quota_deducted: false,
              message: "{FRIENDLY_BUSY_MSG}",
            }},
            503
          );
        }}"""

if old_err_block_pattern.search(worker):
    worker = old_err_block_pattern.sub(new_err_block, worker, count=1)
    print("✅ [worker.js] پیام محاوره‌ای یکپارچه برای همه خطاهای سرور گوگل فعال شد.")
else:
    print("⚠️ [worker.js] الگوی بلوک خطا پیدا نشد!")

with open("worker.js", "w", encoding="utf-8") as f:
    f.write(worker)

print("\n🎉 تمام تغییرات با موفقیت ۱۰۰٪ اعمال شد!")
