import typer
import os
from rich.console import Console
from rich.table import Table

app = typer.Typer(help="دستیار اختصاصی مدیریت پروژه BodyMod 🚀")
console = Console()

@app.command()
def push(msg: str = typer.Argument(..., help="پیام کامیت برای گیت‌هاب")):
    """
    ارسال امن و سریع کدها به گیت‌هاب با تاییدیه
    """
    console.print(f"\n[bold yellow]آیا مطمئنی که می‌خوای کدها رو با پیام زیر بفرستی روی گیت‌هاب؟[/bold yellow]")
    console.print(f"[bold cyan] Commit: '{msg}' [/bold cyan]\n")
    
    # همون سیستم تاییدیه‌ای که تو اسکرین‌شات دیتای هوش مصنوعی بود!
    if typer.confirm("تایید و ارسال؟ (y/n)", abort=False):
        console.print("[bold green]در حال همگام‌سازی... ⏳[/bold green]")
        os.system("git add .")
        os.system(f'git commit -m "{msg}"')
        os.system("git push origin main")
        console.print("[bold green]✅ کدها با موفقیت شلیک شدن رو سرور![/bold green] 🚀")
    else:
        console.print("[bold red]❌ عملیات لغو شد. هیچ آسیبی به کدها نرسید![/bold red]")

@app.command()
def status():
    """
    نمایش وضعیت فایل‌های تغییر یافته
    """
    os.system("git status -s")
    console.print("[bold magenta]برای ارسال کدها از دستور python bm.py push 'payam' استفاده کن.[/bold magenta]")

if __name__ == "__main__":
    app()
