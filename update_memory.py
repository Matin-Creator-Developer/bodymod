import sys
import re

file_path = 'app.html'

form_code = """
<!-- فرم یکپارچه حافظه هوش مصنوعی (وابسته به تم داخلی برنامه) -->
<style>
    .smart-ai-textarea {
        width: 100%; border-radius: 12px; padding: 12px; 
        font-weight: bold; font-size: 13px; resize: none; 
        overflow: hidden; min-height: 210px; line-height: 1.8;
        box-shadow: inset 0 1px 3px rgba(0,0,0,0.05);
        transition: background 0.3s, color 0.3s, border-color 0.3s;
        /* حالت پیش‌فرض (لایت) */
        background: #fdfdfd; color: #333; border: 1px solid #ced4da;
    }
    
    /* فقط زمانی که تم خود برنامه تاریک است تغییر رنگ بده */
    .dark .smart-ai-textarea,
    .theme-dark .smart-ai-textarea,
    [data-theme="dark"] .smart-ai-textarea {
        background: #1c1c1e !important; color: #ffffff !important; border: 1px solid #444 !important;
    }
</style>

<div id="ai-memory-section" style="margin: 15px 0;">
    <label style="color: #00a884; font-size: 14px; font-weight: bold; margin-bottom: 8px; display: block;">
        🧠 حافظه بلندمدت و نکات شخصی برای مربی هوش مصنوعی:
    </label>
    <textarea id="ai_memory_input" class="smart-ai-textarea"
              oninput="this.style.height = ''; this.style.height = this.scrollHeight + 'px'"
              placeholder="مثال:
۱. بیماری خاص یا زمینه‌ای داری؟ (دیابت، فشار خون...) داروی خاصی مصرف می‌کنی؟
۲. به چه خوراکی‌هایی حساسیت داری یا اصلاً دوست نداری؟
۳. وضعیت بودجه‌ات چطوره؟ (اقتصادی، متوسط، دست‌ودلباز)
۴. هر اطلاعات دیگه‌ای که برای شخصی‌سازی رژیم و تمرینت لازمه بنویس...

(خیالت راحت، این اطلاعات کاملاً امن هستن)"></textarea>
</div>
<!-- پایان فرم یکپارچه -->
"""

try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # پیدا کردن و جایگزینی دقیق با حذف مدیا کوئری‌های قبلی
    if 'حافظه بلندمدت و نکات شخصی برای مربی هوش مصنوعی' in content and 'smart-ai-textarea' not in content:
        content = re.sub(r'<style>.*?smart-ai-textarea.*?</style>', '', content, flags=re.DOTALL) # پاک کردن استایل قبلی اگر هست
        content = re.sub(r'<label[^>]*>.*?حافظه بلندمدت و نکات شخصی برای مربی هوش مصنوعی.*?</textarea>(?:\s*</div>)?', form_code, content, flags=re.DOTALL)
        print("✅ کادر قبلی پیدا شد و با نسخه هماهنگ با تم داخلی جایگزین شد!")
    # اگر قبلا کادر هوشمند گذاشته شده ولی میخوایم آپدیتش کنیم
    elif 'smart-ai-textarea' in content:
        content = re.sub(r'<!-- فرم یکپارچه حافظه هوش مصنوعی.*?<!-- پایان فرم یکپارچه -->', form_code, content, flags=re.DOTALL)
        print("✅ کادر هوشمند قبلی با استایل جدید (فقط تم داخلی) آپدیت شد!")
    elif 'قوانین' in content:
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if 'قوانین' in line:
                lines.insert(i - 1 if i > 0 else i, form_code)
                content = '\n'.join(lines)
                print("✅ کادر حافظه دقیقاً بالای قوانین قرار گرفت!")
                break
    else:
        content = content.replace('</body>', form_code + '\n</body>')
        print("✅ فرم به انتهای صفحه اضافه شد.")

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
except Exception as e:
    print(f"❌ خطا در اجرای اسکریپت: {e}")
    sys.exit(1)
