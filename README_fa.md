# لیست سفید کردن آدرس‌های IP CDN در فایروال سرور شما

این پروژه به طور خودکار پیکربندی فایروال شما را به‌روز می‌کند تا دسترسی از شبکه‌های مختلف CDN را مجاز کند. شما می‌توانید اسکریپت را به صورت دستی اجرا کنید یا آن را برای به‌روزرسانی منظم قوانین زمان‌بندی کنید.

## نحوه استفاده

اسکریپت را اجرا کنید و CDN و فایروال خود را از لیست انتخاب کنید:

```bash
bash <(curl -sSkL https://github.com/arian24b/allowcdn/raw/main/src/whitelister.sh)
```

بعد از اجرای اسکریپت، پیغام‌هایی مشابه به موارد زیر را خواهید دید:

```bash
یک CDN برای اضافه کردن IP‌ها انتخاب کنید:
   1) cloudflare
   2) iranserver
   3) arvancloud
CDN: [انتخاب خود را وارد کنید]
```

```bash
یک فایروال برای اضافه کردن IP‌ها انتخاب کنید:
   1) UFW
   2) CSF
   3) firewalld
   4) iptables
   5) ipset+iptables
   6) nftables
Firewall: [انتخاب خود را وارد کنید]
```

شما همچنین می‌توانید نام CDN و فایروال را به طور مستقیم به عنوان آرگومان وارد کنید:

```bash
bash <(curl -sSkL https://github.com/arian24b/allowcdn/raw/main/src/whitelister.sh) cloudflare ufw
```

## تنظیمات به‌روزرسانی خودکار

برای به‌روزرسانی خودکار قوانین فایروال، می‌توانید یک cron job ایجاد کنید. به عنوان مثال:

- **به‌روزرسانی قوانین UFW هر 6 ساعت یک‌بار:**

```bash
0 */6 * * * bash <(curl -sSkL https://github.com/arian24b/allowcdn/raw/main/src/whitelister.sh) cloudflare ufw >/dev/null 2>&1
```

- **به‌روزرسانی قوانین CSF هر روز ساعت 1:00 صبح:**

```bash
0 1 * * * bash <(curl -sSkL https://github.com/arian24b/allowcdn/raw/main/src/whitelister.sh) arvancloud csf >/dev/null 2>&1
```

## CDNهای پشتیبانی شده

- cloudflare
- arvancloud
- iranserver

## فایروال‌های پشتیبانی شده

- UFW
- CSF
- firewalld
- iptables
- ipset+iptables
- nftables

## نیاز به کمک بیشتر؟

اگر فایروال شما در لیست نیست، می‌توانید یک issue باز کنید یا یک pull request ارسال کنید تا پشتیبانی اضافه شود.

## زبان‌های دیگر

برای نسخه اینگلیسی این مستند، لطفاً به [README.md](/home/arian/code/allowcdn/README.md) مراجعه کنید.
