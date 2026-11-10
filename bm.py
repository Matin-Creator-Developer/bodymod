import os
import sys
from rich.console import Console

console = Console()
SENSITIVE_FILES = [".cf_config", "worker.js", "cf.py", "clean.py", "patch_worker.py", "add_bodycoin.py", "fix_links.py", "fix_cordova_links.py", "worker.txt", "linter.py", "error_logs.txt"]

def enforce_security():
    ignore_list = []
    if os.path.exists(".gitignore"):
        with open(".gitignore", "r", encoding="utf-8") as f:
            ignore_list = [line.strip() for line in f.readlines()]
    added_new = False
    with open(".gitignore", "a", encoding="utf-8") as f:
        for sf in SENSITIVE_FILES:
            if sf not in ignore_list:
                f.write(f"\n{sf}")
                added_new = True
    if added_new:
        os.system("git add .gitignore")

def run_linter():
    console.print("[yellow]🔍 در حال بازرسی و اسکن کدها (Linter)...[/yellow]")
    os.system("python linter.py")
    if os.path.exists("error_logs.txt"):
        console.print("[bold red]⛔ ارسال متوقف شد! فایل error_logs.txt رو چک کن.[/bold red]")
        sys.exit(1)

def main():
    if len(sys.argv) < 3 or sys.argv[1] != "push":
        console.print("[bold red]❌ طرز استفاده: python bm.py push \"پیام شما\"[/bold red]")
        sys.exit(1)
        
    message = sys.argv[2]
    enforce_security()
    run_linter() # <--- بازرس وارد عمل می‌شود!
    
    console.print(f"[cyan]در حال همگام‌سازی امن با پیام '{message}'... ⏳[/cyan]")
    os.system("git add .")
    os.system(f'git commit -m "{message}"')
    res = os.system("git push")
    
    if res == 0:
        console.print("[bold green]✅ کدهای تمیز و امن با موفقیت شلیک شدن رو گیت‌هاب! 🚀[/bold green]")

if __name__ == "__main__":
    main()
